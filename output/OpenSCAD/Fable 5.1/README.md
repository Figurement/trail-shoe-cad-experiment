# Trail shoe — OpenSCAD CAD model

Reference-based model of the trail running shoe in `input/left-view.jpg` and
`input/three-angles.jpg` (right shoe, lateral side carries the large cage).

| File | Purpose |
|---|---|
| `trail_shoe.scad` | **Editable master document** (all driving dimensions live here) |
| `lib/shoe_lib.scad` | Construction helpers: spline-interpolated station tables, hull-chained lofts, 2D band strokes, tubes, projections |
| `render_views.sh` | Scripted PNG export (`./render_views.sh <tag> [part]`) → `progress/<tag>_<view>.png` |
| `compare_views.py` | Reference vs CAD side-by-side sheets (no stretching) → `compare/<tag>_<view>.png` |
| `export_parts.sh` | Per-part CGAL mesh export (one isolated process per part) → `export/<part>.stl` + log |
| `stl_to_step.py` | FreeCAD (headless) mesh → named solids → `export/trail_shoe.step`, then re-opens and verifies → `export/trail_shoe.validation.json` |

Nothing here touches an open OpenSCAD/FreeCAD GUI session; every export is a
separate command-line process bound to `trail_shoe.scad`.

## Coordinates and units

mm. `+X` heel→toe (midsole heel end at x = 0, toe tip at 300), `+Z` up (lug
tips on z = 0), `−Y` lateral / `+Y` medial.

All station tables and traced outlines are written in the **reference frame**
of `input/left-view.jpg` (scaled to 4.405 px/mm, heel at px 345, ground line at
px 875). In that frame the lug tips sit at z = `REF_GROUND` (8 mm: the shoe
stands on its lugs, so the photographed ground line is ~8 mm below the midsole
bottom). The final `translate([0,0,-REF_GROUND]) select(part)` drops the whole
model so lug tips rest on z = 0 — edit tables in reference numbers, never
subtract the offset yourself.

## How the model is built (feature tree)

1. **Sole** — `MS` station table (`x, z_bottom, z_top, hw_lateral, hw_medial`)
   drives a convex cross-section per station (hull of 6 circles: bottom edge,
   sidewall bulge, tucked top edge). Stations are hull-chained into ONE
   continuous midsole body; the sidewall groove is subtracted from it.
   `MS_TUCK` sets how far the top edge tucks in (heel flare; at the toe it
   narrows the nose top to a ridge so the bumper/toe box read as one dome).
   Heel and toe half-widths follow plan ellipses (25 × 42 mm heel; toe apex
   biased medially, lateral side tapering earlier). `stations()` blends
   uniform and cosine spacing so both rounded ends get ~half the station
   spacing of the midfoot.
   Lugs come from `LUG_ROWS` (x, count, colour group) placed on the bottom
   curve and tilted to the local rocker slope. `toe_cap()` is a 1.4 mm layer
   over the midsole nose.
2. **Upper** — `UP` table (`x, z_top, hw_top, r_top, bulge`). The base width is
   **linked** to the midsole join line (`ms_hw_top`) so the upper always sits
   in the midsole cup, minus `heel_tuck(x)` (`HEEL_TUCK`) which rounds the heel
   counter in plan behind x = 30 so the back is a curved counter rather than a
   flat end cap (observed in the heel view). The shell is outer loft − inner loft (`UPPER_T`), with
   the collar/throat cut by the top-view outline `OPENING`. `collar()` is a
   tube swept along the rim; `TONGUE` heights are **linked** to the rim
   (`rise` column = how far the tongue stands above the eyestay).
3. **Panels** — overlays are a `PANEL_T` layer on the upper trimmed by 2D
   outlines drawn in reference side-view coordinates (`LAT_*`, `MED_*`),
   stroked as bands (`side_band`) or convex patches (`side_patch`), so they
   always conform to the upper surface. Side projection stops at `WRAP_X`
   (21 mm) where the counter turns to face backwards; from there the **heel
   wrap** (`heel_wrap()`, rear-view coordinates `HEEL_*`) takes over: the
   central orange strip, a black wing on each side running from the strip
   edge round the corner and down to the midsole, the cage's upper/lower
   arms wrapping round and ending as chevron tips beside the strip, and the
   neon stripe on the corner. The medial arms sit 6 mm lower to meet the
   medial chevron. Eyestay plates and lace loops are seated on the rim
   (`loop_pos`).
4. **Hardware** — laces are flat woven ribbon (`LACE_W` × `LACE_T`, 7 × 1.5 mm)
   built with `ribbon()`: taut straight runs between alternate loop stations
   that follow the tongue surface (`lace_z`), plus a tied bow (knot, two flat
   loops, two free ends) below the tongue tab.

Editing tips: the last/first rows of `MS`/`UP` define the tip and heel
rounding — keep them small but non-zero; change a number in a station table and re-run
`./render_views.sh check`; keep rows sorted by x; the Catmull-Rom
interpolation means a single row edit moves the surface smoothly around it.

### Fixed (non-parametric) references
The traced 2D outlines in section 4 of the .scad (`LAT_UPPER_ARM`,
`LAT_LOWER_ARM`, `LAT_BRIDGE`, `LAT_BLACK_*`, `LOGO_*`, `MED_*`, `HEEL_NEON`, the
eyestay plate quad, the toe-cap side polygon) are literal reference
coordinates. They conform to the surface automatically but do not move when
the `UP`/`MS` tables change and must be re-traced after large silhouette edits.

## Observed vs inferred

**Observed (traced from the images, reference scaled to a 300 mm outsole,
≈ ±3 mm):** side silhouette (verified in the accuracy pass with a registered
orthographic overlay — CAD top line within ±3 mm of the reference at every
10 mm station from x = 30 to 280; heel x = 10–20 within ±4 mm), stack heights
(heel ≈ 60 mm midsole top / 20 mm bottom → ~40 mm foam, midfoot ≈ 30 mm,
forefoot ≈ 25 mm, plus 8 mm lugs), toe spring and heel flare,
collar/heel-tab/tongue heights, eyestay line and 5 loop stations, heel-view layout of strip / wings /
chevron tips / neon (`HEEL_*`, ±4 mm — perspective heel photo), lateral cage / medial chevron /
heel strip / neon stripe outlines, cougar logo outline (`LOGO_*`, lateral), lug colour zones (orange heel & toe, grey
midfoot), toe cap.

**Inferred (not measured):** all widths (from perspective front/heel views
and typical proportions), wall thicknesses, panel stand-off, opening outline,
tongue thickness, lace width/thickness, bow loop shape (position and
heelward droop of the loops are observed), lug shape/spacing and the whole outsole layout (no bottom
reference exists), interior. None of this is manufacturing-validated.

Not modelled on purpose (visualisation material work): knit texture,
perforations, text, colour gradient of the midsole, lace
texture.

## Accuracy pass (registered overlay)

Perspective side-by-sides are not enough to judge line placement, so a second
check was made with orthographic CAD renders registered onto the reference
(`--projection=o --camera=150,-500,60,150,0,60 --imgsize=2400,1200` → 6.03
px/mm, x = 0 at px 295.5, reference-frame z = 0 at px 1010). Silhouette top /
bottom were sampled every 10 mm on both images and compared numerically.
Reproduce with
`openscad -o /tmp/ortho_lat.png --projection=o --camera=150,-500,60,150,0,60 --imgsize=2400,1200 trail_shoe.scad`
then `python3 overlay_registered.py ../input/left-view.jpg /tmp/ortho_lat.png compare/final_lateral_registered 4.405 345 875 6.03 295.5 1010`
(outputs `*_blend.png` and `*_edges.png` with a 10 mm grid).
Deviations found and corrected: midsole bottom was 10 mm low (whole shoe was
sitting with its lugs *in* the ground line), midsole top line 3–6 mm low,
collar/upper top line 5–20 mm low along the whole throat, tongue not standing
proud of the eyestay, heel counter rising too early, lugs 6.5 → 8 mm, bow
floating above the tongue instead of drooping heelward over its peak.

## Workflow used

```
./render_views.sh final           # all views  (VIEWS="lateral heel" to limit)
python3 compare_views.py final     # reference vs CAD sheets in compare/
./export_parts.sh                 # CGAL meshes per part in export/
/Applications/FreeCAD.app/Contents/Resources/bin/freecadcmd stl_to_step.py
```

## Export notes / limitations

OpenSCAD 2021.01 has no B-rep kernel, so the STEP is produced by converting
the per-part meshes to solids in FreeCAD: it is a **faceted STEP** (planar
faces, exact to the OpenSCAD geometry) with one named body per component
grouped by material, not NURBS. `trail_shoe.scad` stays the editable master;
`export/trail_shoe.FCStd` is only an exchange copy. `stl_to_step.py` re-opens
the STEP and checks names, solid counts, closedness and volumes — see
`export/trail_shoe.validation.json` before relying on the file.
