#!/usr/bin/env bash
# Scripted image export for the Cougar Trail shoe.scad model.
# Renders a fixed set of views into output/ so progress can be compared
# side-by-side against the two reference photos in input/. Uses OpenCSG
# preview (not --render) so material colors are shown; camera angles are
# kept slightly oblique to avoid edge-on z-fighting artifacts.
#
# Usage: ./render_views.sh
set -euo pipefail
cd "$(dirname "$0")"

SCAD=shoe.scad
OUT=output
SIZE=1400,1000

render() {
  name="$1"; shift
  openscad -o "$OUT/$name.png" --imgsize=$SIZE --autocenter --viewall --projection=p "$@" "$SCAD"
  echo "wrote $OUT/$name.png"
}

# lateral (medial-side-out) hero shot, framed like input/left-view.jpg
render 01_lateral_hero      --camera=0,0,0,58,0,235,0
# straight-ish lateral profile
render 02_lateral_profile   --camera=0,0,0,80,0,270,0
# medial side hero shot (opposite side of 01)
render 03_medial_hero       --camera=0,0,0,58,0,55,0
# top-down
render 04_top               --camera=0,0,0,6,0,270,0
# outsole / bottom view
render 05_outsole           --camera=0,0,0,186,0,270,0
# heel / rear three-quarter
render 06_heel              --camera=0,0,0,58,0,15,0
# front / toe three-quarter, framed like the front pane of three-angles.jpg
render 07_front              --camera=0,0,0,58,0,170,0
# oblique hero, framed like the isometric pane of three-angles.jpg
render 08_geometry_hero      --camera=0,0,0,58,0,235,0

echo "Done. Compare output/*.png against input/left-view.jpg and input/three-angles.jpg"
