#!/usr/bin/env bash
# bin/next-id.sh 자체 검사. origin/main 과 로컬 브랜치의 최대값을 모두 보는지 확인.
N="$(cd "$(dirname "$0")/../bin" && pwd)/next-id.sh"
fail=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 원격 역할을 하는 bare 저장소 + 작업 저장소
git init -q --bare "$tmp/remote.git"
git init -q "$tmp/w"; cd "$tmp/w"
git remote add origin "$tmp/remote.git"
mk(){ mkdir -p "$(dirname "$1")"; printf -- '---\nid: %s\ntitle: t\nstatus: done\nlinks: []\nupdated: 2026-10-01\n---\n' "$2" > "$1"; }
q(){ git add -A >/dev/null 2>&1; git -c user.email=t@t -c user.name=t -c core.autocrlf=false commit -qm "$1"; }

t(){ out=$(bash "$N" "$2" 2>/dev/null)
  if [ "$out" = "$3" ]; then printf '  %-40s OK\n' "$1"
  else printf '  %-40s FAIL (%s, 기대 %s)\n' "$1" "$out" "$3"; fail=1; fi; }

mk docs/adr/ADR-0001-a.md ADR-0001; q init
git push -q origin main 2>/dev/null || { git branch -M main; git push -q -u origin main; }
t "origin/main 에 0001 만 있음" adr ADR-0002

# 원격에 0002, 0003 을 올린 뒤 로컬은 그걸 모르는 상태로 되돌린다
mk docs/adr/ADR-0002-b.md ADR-0002; mk docs/adr/ADR-0003-c.md ADR-0003; q more
git push -q origin main
git reset -q --hard HEAD~1          # 로컬만 0001 로 되돌림
git update-ref -d refs/remotes/origin/main 2>/dev/null || true
t "로컬이 낡아도 origin 최대값을 본다" adr ADR-0004

# 로컬 브랜치에만 있는 번호도 센다
git switch -q -c docs/new
mk docs/adr/ADR-0004-d.md ADR-0004; q local-only
t "로컬 브랜치 번호도 포함" adr ADR-0005

# 다른 종류는 독립
t "종류별 독립 번호" req REQ-0001
exit "$fail"
