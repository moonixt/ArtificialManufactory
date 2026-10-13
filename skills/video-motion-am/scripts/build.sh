#!/usr/bin/env bash
# Gera o vídeo final a partir de uma página HTML com render(t).
# uso: build.sh <pagina.html> <saida.mp4> [--music arquivo.mp3] [--music-start seg] [--preview t1,t2,...]
#   --preview: só renderiza esses tempos e monta <saida>-preview.png (nada de MP4)
# Saídas: <saida.mp4>, <saida>-capa.jpg (quadro de 1s), <saida>-strip.png (1 quadro a cada 2s)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PAGE="$(realpath "$1")"; OUT="$(realpath -m "$2")"; shift 2
MUSIC=""; MSTART=0; PREVIEW=""
while [ $# -gt 0 ]; do case "$1" in
  --music) MUSIC="$(realpath "$2")"; shift 2;;
  --music-start) MSTART="$2"; shift 2;;
  --preview) PREVIEW="$2"; shift 2;;
  *) echo "opção desconhecida: $1" >&2; exit 1;;
esac; done
BASE="${OUT%.mp4}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

if [ -n "$PREVIEW" ]; then
  node "$HERE/render.mjs" "$PAGE" "$TMP" 30 "$PREVIEW" | tail -1
  FILES=(); IFS=, read -ra TS <<< "$PREVIEW"; for t in "${TS[@]}"; do FILES+=("$TMP/t$t.png"); done
  magick montage "${FILES[@]}" -geometry 432x+6+6 -tile "${#FILES[@]}x" -background '#888' "$BASE-preview.png"
  echo "prévia: $BASE-preview.png"; exit 0
fi

node "$HERE/render.mjs" "$PAGE" "$TMP/fr" 30 | tail -1
N=$(ls "$TMP/fr" | wc -l); DUR=$(python3 -c "print(round($N/30,3))")
if [ -n "$MUSIC" ]; then
  FO=$(python3 -c "print(max(0,$DUR-2.5))")
  AUDIO=(-ss "$MSTART" -i "$MUSIC")
  AF="atrim=0:$DUR,afade=t=in:d=0.3,afade=t=out:st=$FO:d=2.5,loudnorm=I=-16:TP=-1.5:LRA=11"
else
  AUDIO=(-f lavfi -t "$DUR" -i anullsrc=r=48000:cl=stereo); AF="anull"
fi
ffmpeg -y -loglevel error -framerate 30 -i "$TMP/fr/f%05d.png" "${AUDIO[@]}" \
  -map 0:v -map 1:a -af "$AF" -ar 48000 \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high -level 4.1 \
  -c:a aac -b:a 192k -t "$DUR" -movflags +faststart "$OUT"
magick "$TMP/fr/f00030.png" -quality 90 "$BASE-capa.jpg"
ffmpeg -loglevel error -y -i "$OUT" -vf "fps=1/2,scale=150:-1,tile=$(( (${DUR%.*} + 1) / 2 + 1 ))x1" -frames:v 1 "$BASE-strip.png"
ffprobe -v error -show_entries format=duration,size -of compact "$OUT"
echo "capa: $BASE-capa.jpg | tira: $BASE-strip.png"
