#!/usr/bin/env bash
# 문서 목록을 한눈에 본다.  사용: bin/list.sh adr   (종류 생략 시 전부)
# 손으로 돌리는 도우미다. check.sh 가 실행하지 않는다.
set -u
TYPES='idea req arch adr task test issue'
t=${1:-all}
case "$t" in
  all) sel="$TYPES" ;;
  idea|req|arch|adr|task|test|issue) sel="$t" ;;
  *) echo "사용: $(basename "$0") [idea|req|arch|adr|task|test|issue]" >&2; exit 2 ;;
esac

f1(){ sed -n "s/^$1:[[:space:]]*//p" "$2" | head -1; }

for ty in $sel; do
  files=$(ls "docs/$ty"/*.md 2>/dev/null | sort || true)
  [ -n "$files" ] || { [ "$t" = all ] && continue; echo "docs/$ty/ 에 문서가 없다"; continue; }
  echo "docs/$ty/"
  for f in $files; do
    printf '  %-12s %-8s %s\n' "$(f1 id "$f")" "$(f1 status "$f")" "$(f1 title "$f")"
  done
  printf '  — %s개  ' "$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
  for s in draft open done dropped; do
    c=$(grep -lE "^status:[[:space:]]*$s$" $files 2>/dev/null | wc -l | tr -d ' ')
    [ "$c" = 0 ] || printf '%s:%s ' "$s" "$c"
  done
  echo
done

# 아이디어는 인박스에 미처리 줄이 남아 있을 수 있다
if [ "$t" = all ] || [ "$t" = idea ]; then
  if [ -f docs/IDEA-INBOX.md ]; then
    n=$(sed -n '/^## 미처리$/,$p' docs/IDEA-INBOX.md | grep -cE '^- [0-9]{4}-[0-9]{2}-[0-9]{2} ' || true)
    echo "docs/IDEA-INBOX.md — 미처리 ${n}줄"
  fi
fi
