#!/usr/bin/env bash
# doc-policy 검사 — docs/<종류>/ 문서의 이름·프론트매터·상호 참조.
# 저장소 루트에서 실행한다. 의존성 없음 (git + grep + sed).
# 추적 파일만 본다 — 새 문서는 git add 뒤에 보인다.
# bash 3.2 호환을 위해 연관 배열을 쓰지 않는다.

TYPES='idea req arch adr task test issue'
STATUS='draft open done dropped'
fail=0
ids=''      # "ID<tab>파일" 줄 모음
refs=''    # "ID<tab>파일" 모음 (links 에서 수집)

err(){ echo "    $1"; fail=1; }

# 프론트매터 첫 블록만 뽑는다
fm(){ awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$1"; }
val(){ printf '%s\n' "$2" | sed -n "s/^$1:[[:space:]]*//p" | head -1; }

list=$(git ls-files 2>/dev/null | grep -E "^docs/($(echo $TYPES | tr ' ' '|'))/" || true)
n=0

while IFS= read -r f; do
  [ -n "$f" ] || continue
  n=$((n+1))
  dir=${f#docs/}; dir=${dir%%/*}
  base=$(basename "$f")
  up=$(echo "$dir" | tr 'a-z' 'A-Z')

  # 1) 파일명 패턴
  if ! printf '%s' "$base" | grep -qE "^${up}-[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$"; then
    err "$f: 파일명이 <$up>-NNNN-슬러그.md 가 아니다"; continue
  fi
  fid="${base%%-*}-$(printf '%s' "$base" | sed -n "s/^${up}-\([0-9]\{4\}\)-.*/\1/p")"

  b=$(fm "$f")
  [ -n "$b" ] || { err "$f: 프론트매터가 없다"; continue; }

  # 2) 필수 키
  for k in id title status links updated; do
    printf '%s\n' "$b" | grep -qE "^$k:" || err "$f: 프론트매터에 '$k' 없음"
  done

  # 3) id 가 파일명과 일치
  did=$(val id "$b")
  [ "$did" = "$fid" ] || err "$f: id '$did' 가 파일명의 '$fid' 와 다르다"

  # 4) status 허용값
  st=$(val status "$b")
  echo " $STATUS " | grep -q " $st " || err "$f: status '$st' 는 허용값이 아니다 ($STATUS)"

  # 5) updated 형식
  printf '%s' "$(val updated "$b")" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
    || err "$f: updated 가 YYYY-MM-DD 가 아니다"

  # 6) links 수집 (유효성은 전체 수집 후)
  lk=$(val links "$b")
  if ! printf '%s' "$lk" | grep -qE '^\[.*\]$'; then
    err "$f: links 가 [] 또는 [ID, ID] 형태가 아니다"
  else
    for r in $(printf '%s' "$lk" | tr -d '[]' | tr ',' ' '); do
      refs="$refs$r	$f
"
    done
  fi

  ids="$ids$did	$f
"
done <<EOF
$list
EOF

# 7) ID 중복
dup=$(printf '%s' "$ids" | cut -f1 | sort | uniq -d)
[ -z "$dup" ] || for d in $dup; do err "ID 중복: $d"; done

# 8) links 가 가리키는 ID 가 실제로 있나
while IFS=$'\t' read -r r src; do
  [ -n "$r" ] || continue
  printf '%s' "$ids" | cut -f1 | grep -qx "$r" || err "$src: links 의 '$r' 가 존재하지 않는다"
done <<EOF
$refs
EOF

[ "$fail" -eq 0 ] && echo "OK  문서 ${n}개 정합"
exit "$fail"
