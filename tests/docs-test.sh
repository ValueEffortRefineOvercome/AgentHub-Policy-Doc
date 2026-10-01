#!/usr/bin/env bash
# checks/docs.sh 자체 검사. 임시 저장소에 픽스처를 깔고 기대 결과를 확인한다.
LINT="$(cd "$(dirname "$0")/../checks" && pwd)/docs.sh"
fail=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q

mk(){ mkdir -p "$tmp/$(dirname "$1")"; cat > "$tmp/$1"; }
run(){ ( cd "$tmp" && git add -A >/dev/null 2>&1; cd "$tmp" && bash "$LINT" 2>&1 ); }
t(){ # t <기대exit> <설명> <기대문구|"">
  out=$(run); c=$?
  if [ "$c" != "$1" ]; then printf '  %-44s FAIL (exit %s, 기대 %s)\n' "$2" "$c" "$1"; fail=1; return; fi
  if [ -n "$3" ] && ! printf '%s' "$out" | grep -q "$3"; then
    printf '  %-44s FAIL (문구 없음: %s)\n' "$2" "$3"; fail=1; return
  fi
  printf '  %-44s OK\n' "$2"
}

# 정상 문서 2개 — REQ 와 그것을 가리키는 ADR
mk docs/req/REQ-0001-store-policy.md <<'EOF'
---
id: REQ-0001
title: 정책을 한 곳에서 관리한다
status: done
links: []
updated: 2026-10-01
---
본문
EOF
mk docs/adr/ADR-0001-submodule.md <<'EOF'
---
id: ADR-0001
title: skill 단위 서브모듈로 쪼갠다
status: done
links: [REQ-0001]
updated: 2026-10-01
---
본문
EOF
t 0 "정상 문서 2개" "문서 2개 정합"

mk docs/adr/ADR-0002-bad-name.MD <<'EOF'
x
EOF
t 1 "파일명 패턴 위반" "파일명이"
rm "$tmp/docs/adr/ADR-0002-bad-name.MD"

mk docs/adr/ADR-0003-id-mismatch.md <<'EOF'
---
id: ADR-0009
title: t
status: done
links: []
updated: 2026-10-01
---
EOF
t 1 "id 가 파일명과 불일치" "와 다르다"
rm "$tmp/docs/adr/ADR-0003-id-mismatch.md"

mk docs/adr/ADR-0004-missing-key.md <<'EOF'
---
id: ADR-0004
title: t
links: []
updated: 2026-10-01
---
EOF
t 1 "필수 키 누락 (status)" "'status' 없음"
rm "$tmp/docs/adr/ADR-0004-missing-key.md"

mk docs/adr/ADR-0005-bad-status.md <<'EOF'
---
id: ADR-0005
title: t
status: 진행중
links: []
updated: 2026-10-01
---
EOF
t 1 "status 허용값 아님" "허용값이 아니다"
rm "$tmp/docs/adr/ADR-0005-bad-status.md"

mk docs/adr/ADR-0006-bad-date.md <<'EOF'
---
id: ADR-0006
title: t
status: done
links: []
updated: 2026/10/01
---
EOF
t 1 "updated 형식 위반" "YYYY-MM-DD"
rm "$tmp/docs/adr/ADR-0006-bad-date.md"

mk docs/adr/ADR-0007-dead-link.md <<'EOF'
---
id: ADR-0007
title: t
status: done
links: [REQ-9999]
updated: 2026-10-01
---
EOF
t 1 "links 가 없는 ID 를 가리킴" "존재하지 않는다"
rm "$tmp/docs/adr/ADR-0007-dead-link.md"

mk docs/adr/ADR-0001-duplicate.md <<'EOF'
---
id: ADR-0001
title: t
status: done
links: []
updated: 2026-10-01
---
EOF
t 1 "ID 중복" "ID 중복"
rm "$tmp/docs/adr/ADR-0001-duplicate.md"

t 0 "정리 후 다시 통과" "문서 2개 정합"
exit "$fail"
