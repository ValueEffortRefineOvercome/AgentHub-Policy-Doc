#!/usr/bin/env bash
# 다음 문서 번호를 출력한다.  사용: bin/next-id.sh adr
#
# origin/main 과 작업 트리 양쪽의 최대 번호에서 +1 한다 — 번호 충돌의 대부분은
# "로컬 main 이 낡은 상태에서 다음 번호를 눈으로 셌다" 에서 나온다.
# 손으로 돌리는 도우미다. check.sh 가 실행하지 않는다.
set -u
t=${1:-}
case "$t" in
  idea|req|arch|adr|task|test|issue) ;;
  *) echo "사용: $(basename "$0") <idea|req|arch|adr|task|test|issue>" >&2; exit 2 ;;
esac
up=$(echo "$t" | tr 'a-z' 'A-Z')

nums(){ sed -n "s|^.*/\{0,1\}${up}-\([0-9]\{4\}\)-.*\.md$|\1|p"; }

# origin/main — 없거나 못 가져오면 그 사실을 알리고 로컬만 본다
remote=''
if git remote get-url origin >/dev/null 2>&1; then
  git fetch -q origin 2>/dev/null || echo "경고: origin fetch 실패 — 로컬만 보고 센다" >&2
  remote=$(git ls-tree --name-only -r origin/main -- "docs/$t/" 2>/dev/null | nums)
else
  echo "경고: origin 이 없다 — 로컬만 보고 센다" >&2
fi
local_=$(git ls-files -- "docs/$t/" 2>/dev/null | nums)

max=$(printf '%s\n%s\n0000\n' "$remote" "$local_" | grep -E '^[0-9]{4}$' | sort -n | tail -1)
printf '%s-%04d\n' "$up" "$((10#$max + 1))"
