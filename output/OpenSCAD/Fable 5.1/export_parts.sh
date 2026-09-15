#!/usr/bin/env bash
# Export every component of output/trail_shoe.scad as a separate mesh (STL) via
# a full CGAL evaluation. Each part runs in its own isolated OpenSCAD process so
# one failure cannot stop the others, and the GUI session is never touched.
#   ./export_parts.sh [part ...]
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p export
PARTS=("$@")
[ ${#PARTS[@]} -eq 0 ] && PARTS=(midsole lugs toe_cap upper collar tongue lateral_cage medial_chevron heel_strip eyestay laces logo)

for p in "${PARTS[@]}"; do
  echo "== $p"
  start=$(date +%s)
  if openscad -o "export/$p.stl" -D "part=\"$p\"" trail_shoe.scad > "export/$p.log" 2>&1; then
    echo "   ok  ($(( $(date +%s) - start )) s, $(du -h "export/$p.stl" | cut -f1))"
    grep -E "Simple:|Volumes:|WARNING|ERROR" "export/$p.log" | sed 's/^/   /'
  else
    echo "   FAILED — see export/$p.log"
  fi
done
