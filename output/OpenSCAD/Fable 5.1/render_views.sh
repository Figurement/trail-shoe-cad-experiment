#!/usr/bin/env bash
# Scripted image export for output/trail_shoe.scad (does not touch any GUI session).
#   ./render_views.sh [tag] [part]      e.g. ./render_views.sh s1 silhouette
# Writes output/progress/<tag>_<view>.png
set -euo pipefail
cd "$(dirname "$0")"
TAG="${1:-latest}"
PART="${2:-all}"
SCAD="trail_shoe.scad"
OUT="progress"
SIZE="${IMGSIZE:-1600,900}"
mkdir -p "$OUT"

render() { # name  eye(x,y,z)  center(x,y,z)  projection
  local name=$1 cam=$2 proj=${3:-p}
  openscad -o "$OUT/${TAG}_${name}.png" --imgsize="$SIZE" --projection="$proj" \
    --camera="$cam" --colorscheme=Tomorrow -D "part=\"$PART\"" "$SCAD" 2>&1 \
    | grep -v -E "^(Compiling|Parsing|Saving|Geometries|Compile and|Total rendering|Top level)" || true
  echo "  wrote $OUT/${TAG}_${name}.png"
}

VIEWS="${VIEWS:-lateral medial front heel top outsole hero}"
for v in $VIEWS; do
  case $v in
    lateral) render lateral  "150,-760,165,150,0,72" ;;
    medial)  render medial   "150,760,165,150,0,72" ;;
    front)   render front    "1100,0,330,150,0,75" ;;
    heel)    render heel     "-800,0,220,140,0,75" ;;
    top)     render top      "150,-0.5,900,150,0,60" o ;;
    outsole) render outsole  "150,-0.5,-900,150,0,20" o ;;
    hero)    render hero     "560,-620,260,150,0,65" ;;
    toe_detail)  render toe_detail  "700,-300,120,270,0,55" ;;
    heel_detail) render heel_detail "-300,-500,170,30,0,80" ;;
    cage_detail) render cage_detail "90,-450,150,90,0,80" ;;
    throat_detail) render throat_detail "500,-350,400,150,0,100" ;;
  esac
done
