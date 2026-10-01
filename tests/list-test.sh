#!/usr/bin/env bash
# bin/list.sh 자체 검사. 프론트매터를 읽어 표를 만드는지, 인박스 미처리 줄을 세는지.
L="$(cd "$(dirname "$0")/../bin" && pwd)/list.sh"
fail=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
mkdir -p docs/adr
d(){ printf -- '---\nid: %s\ntitle: %s\nstatus: %s\nlinks: []\nupdated: 2026-10-01\n---\n' "$1" "$3" "$2" > "docs/adr/$1-x.md"; }
t(){ printf '  %-36s ' "$1"
  if printf '%s' "$3" | grep -q "$2"; then echo OK; else echo "FAIL (없음: $2)"; fail=1; fi; }

d ADR-0002 done  둘째
d ADR-0001 draft 첫째
out=$(bash "$L" adr)
t "ID 순으로 정렬" 'ADR-0001.*첫째' "$(printf '%s' "$out" | sed -n '2p')"
t "status 를 읽는다"  'done' "$(printf '%s' "$out" | grep ADR-0002)"
t "title 을 읽는다"   '둘째' "$(printf '%s' "$out" | grep ADR-0002)"
t "status 별 집계"    'draft:1' "$out"
t "총 개수"           '2개' "$out"

printf '## 미처리\n- 2026-10-01 뭔가 (맥락: x)\n- 2026-10-02 또 (맥락: y)\n' > docs/IDEA-INBOX.md
t "인박스 미처리 줄 수" '미처리 2줄' "$(bash "$L" idea)"

t "문서 없는 종류" '문서가 없다' "$(bash "$L" req)"
bash "$L" nope >/dev/null 2>&1; [ $? = 2 ] \
  && printf '  %-36s OK\n' "잘못된 인자는 exit 2" \
  || { printf '  %-36s FAIL\n' "잘못된 인자는 exit 2"; fail=1; }
exit "$fail"
