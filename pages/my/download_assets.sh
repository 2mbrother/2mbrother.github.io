#!/usr/bin/env bash
#
# 바른손 청첩장 리소스 다운로드 + 경로 상대화 스크립트
# 인터넷이 되는 본인 PC에서 실행하세요:  bash download_assets.sh
#
# 결과: index_local.html  (모든 경로가 상대경로) + mcard/ res/ static/ 폴더
#
set -uo pipefail
cd "$(dirname "$0")"

SRC="index.html"
OUT="index_local.html"

if [ ! -f "$SRC" ]; then
  echo "오류: $SRC 가 같은 폴더에 없습니다."; exit 1
fi

cp "$SRC" "$OUT"

echo "== 바른손 리소스 URL 추출 중 =="
# style="background:url(...)" 안의 주소까지 포함해서 추출, 구분자에서 끊음
grep -oE 'https://(mcard|mcard-resources|static)\.barunsoncard\.com[^"'"'"' )(>]+' "$SRC" \
  | sort -u > .asset_urls.txt

count=$(wc -l < .asset_urls.txt | tr -d ' ')
echo "   $count 개 발견. 다운로드 시작..."

while IFS= read -r url; do
  [ -z "$url" ] && continue
  clean="${url%%\?*}"                       # 쿼리스트링(?v=...) 제거

  case "$clean" in
    https://mcard-resources.barunsoncard.com/*) dir="res";    rel="${clean#https://mcard-resources.barunsoncard.com/}";;
    https://mcard.barunsoncard.com/*)           dir="mcard";  rel="${clean#https://mcard.barunsoncard.com/}";;
    https://static.barunsoncard.com/*)          dir="static"; rel="${clean#https://static.barunsoncard.com/}";;
    *) continue;;
  esac

  dest="$dir/$rel"
  mkdir -p "$(dirname "$dest")"
  if curl -fsSL "$clean" -o "$dest"; then
    echo "  ↓ $dest"
  else
    echo "  ✗ 실패: $clean"
  fi
done < .asset_urls.txt

rm -f .asset_urls.txt

echo "== 경로를 상대경로로 변환 중 =="
# 순서 중요: mcard-resources 를 mcard 보다 먼저 치환
sed -i.bak \
  -e 's#https://mcard-resources\.barunsoncard\.com#./res#g' \
  -e 's#https://mcard\.barunsoncard\.com#./mcard#g' \
  -e 's#https://static\.barunsoncard\.com#./static#g' \
  "$OUT"
rm -f "$OUT.bak"

echo ""
echo "완료! 아래를 통째로 업로드하세요:"
echo "  - $OUT"
echo "  - mcard/  res/  static/  폴더"
echo ""
echo "참고: 폰트/제이쿼리/카카오SDK는 구글·카카오 등 공용 CDN을 그대로 사용합니다(안정적)."
