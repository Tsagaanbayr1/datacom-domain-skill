#!/usr/bin/env bash
# Runs each skill's bash blocks the way Claude Code does: `$ARGUMENTS` is replaced
# by the raw argument text before the commands are run. `curl` is a local stub, so
# nothing is sent to datacom.mn.
#
#   bash tests/skill-args.sh
#   SKILL_SHELL=zsh bash tests/skill-args.sh     # run the skill commands under zsh instead
#
# Checks that hostile arguments (quotes, `$(...)`, backticks) are never executed by
# the shell, that invalid names never reach curl, and that valid names still do.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"

cat > "$WORK/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$CURL_LOG"
printf '0:["$@1",["x",null]]\n1:[]\n'
STUB
chmod +x "$WORK/bin/curl"

fail=0
pass=0

# Print the skill's ```bash blocks with $ARGUMENTS replaced literally by $2.
render() {
  PAYLOAD="$2" awk '
    /^```bash[[:space:]]*$/ { inblock = 1; next }
    /^```[[:space:]]*$/     { inblock = 0; next }
    inblock {
      line = $0; out = ""; p = ENVIRON["PAYLOAD"]
      while ((i = index(line, "$ARGUMENTS")) > 0) {
        out = out substr(line, 1, i - 1) p
        line = substr(line, i + length("$ARGUMENTS"))
      }
      print out line
    }' "$1"
}

# run <skill> <argument>: runs the rendered blocks; sets CANARY_HIT and CURL_CALLS.
run() {
  local skill="$ROOT/skills/$1/SKILL.md"
  CANARY="$WORK/pwned"
  rm -f "$CANARY" "$WORK/curl.log"
  : > "$WORK/curl.log"
  local arg="${2//CANARY/$CANARY}"
  render "$skill" "$arg" > "$WORK/script.sh"
  (cd "$WORK" && CURL_LOG="$WORK/curl.log" PATH="$WORK/bin:$PATH" "${SKILL_SHELL:-bash}" "$WORK/script.sh" >/dev/null 2>&1)
  CANARY_HIT=0; [ -e "$CANARY" ] && CANARY_HIT=1
  CURL_CALLS=$(grep -c '^-X$' "$WORK/curl.log" || true)
}

check() { # check <description> <condition-result 0|1>
  if [ "$2" = 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1"; fi
}

PAYLOADS=(
  "x'; touch CANARY; echo '"
  "\$(touch CANARY)"
  "\`touch CANARY\`"
  "x\"; touch CANARY; echo \""
  "example.mn; touch CANARY"
  "a b'\$(touch CANARY)'"
)

for skill in search-domain whois; do
  for p in "${PAYLOADS[@]}"; do
    run "$skill" "$p"
    check "$skill: argument [$p] ran a command" "$CANARY_HIT"
    check "$skill: invalid argument [$p] reached curl" "$([ "$CURL_CALLS" = 0 ] && echo 0 || echo 1)"
  done
done

run search-domain "Example.MN"
check "search-domain: valid name did not reach curl" "$([ "$CURL_CALLS" = 1 ] && echo 0 || echo 1)"
check "search-domain: request body is not the cleaned name" \
  "$(grep -qF '[["example.mn","example.ub.mn","example.org.mn","example.io","example.biz","example.info","example.name","example.mobi","example.tv","example.cc","example.asia"]]' "$WORK/curl.log" && echo 0 || echo 1)"

run search-domain "my-shop.ub.mn"
check "search-domain: .ub.mn suffix not stripped" "$(grep -qF '"my-shop.mn"' "$WORK/curl.log" && echo 0 || echo 1)"

run search-domain "  Example.MN  "
check "search-domain: surrounding spaces were not trimmed" "$(grep -qF '"example.mn"' "$WORK/curl.log" && echo 0 || echo 1)"

for arg in "exa mple" "exa	mple.mn" "$(printf 'example\nother')"; do
  run search-domain "$arg"
  check "search-domain: name with inner whitespace [$arg] reached curl" "$([ "$CURL_CALLS" = 0 ] && echo 0 || echo 1)"
  run whois "$arg"
  check "whois: domain with inner whitespace [$arg] reached curl" "$([ "$CURL_CALLS" = 0 ] && echo 0 || echo 1)"
done

run search-domain "ab"
check "search-domain: 2-character name reached curl" "$([ "$CURL_CALLS" = 0 ] && echo 0 || echo 1)"

run whois "Datacom.MN"
check "whois: valid domain did not reach curl" "$([ "$CURL_CALLS" = 1 ] && echo 0 || echo 1)"
check "whois: request body is not the domain" "$(grep -qxF '["datacom.mn"]' "$WORK/curl.log" && echo 0 || echo 1)"

run whois "google"
check "whois: domain without a TLD reached curl" "$([ "$CURL_CALLS" = 0 ] && echo 0 || echo 1)"

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
