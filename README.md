# Reference-Based Shoe CAD Modeling

Use OpenSCAD for modeling. Read the relevant skills and inspect all supplied
reference images before starting.

Prioritize accurate geometry and proportions over the number of details or
objects. "Detailed" means accurately shaped and joined geometry, not simply
more components. The goal is a reference-faithful CAD model ready for product
rendering and understandable, natural final adjustments by humans.

## Human-editable construction

Build a human-editable OpenSCAD document from the beginning, using real sketches,
sections, lofts, sweeps, and linked features rather than merely named static
solids. Organize the feature tree clearly and use actual driving dimensions
where appropriate. Clearly identify any fixed reference surfaces or features
that are not parametrically linked.

Refine the existing feature tree incrementally. Preserve working versions and
human adjustments rather than regenerating the entire model for every local
change. Scripting is appropriate when it creates and updates meaningful,
editable OpenSCAD features; it must not substitute for an understandable model.

## Modeling order

Work in these stages, resolving visible discrepancies before proceeding:

1. Overall proportions and silhouette.
2. Sole shape and its relationship to the upper.
3. Panel boundaries, material transitions, and joins.
4. Hardware and small details supported by the references.

Do not invent details that are not supported by the reference images. Explicitly
distinguish observed features from inferred dimensions and hidden geometry.
Do not present inferred geometry as measured or manufacturing-validated.

## Reference comparison loop

Establish a closed loop of modeling, scripted image export, visual inspection,
and correction. After each major stage, compare every supplied reference view
with a corresponding CAD view. Match viewing angles as closely as possible and
use side-by-side comparisons without distorting image proportions.

Turn the shoe around and inspect it from multiple angles, including the front,
heel, lateral and medial sides, top, and outsole. Inspect close-ups of important
boundaries and joins. Fix visible discrepancies before adding further detail.
Successful recomputation or geometric validity alone does not establish visual
accuracy.

Let the human follow along: provide the path of the OpenSCAD file being created
and keep progress images available. Use OpenSCAD scripting to write images for
inspection instead of capturing desktop screenshots. Bind image exports to the
shoe document, not whichever document happens to be active. Avoid interfering
with the human's OpenSCAD session so they can continue working on the same machine.

## Panel lines and material joins

Treat panel lines and material transitions as primary geometry. Match their
endpoints, curvature, widths, overlaps, and junctions, not merely the overall
design language. Represent how adjacent materials meet and are joined, while
clearly identifying construction details inferred from the images.

Do not substitute approximate constant-width ribbons or rounded outlines where
the references show specific variable-width contours or sharper transitions.

## Sole geometry

Match the sole's organic profile, heel flare, recessed waist, and toe rocker.
Keep the midsole continuous rather than dividing it for appearance effects.
Inspect the toe and heel explicitly for unintended splits, pinching, gaps,
projections, and interference. Check that rubber inserts and traction details
fit their supporting surfaces and that the sole joins coherently to the upper.

## Geometry versus visualization

Use simple placeholder colors only. Focus on geometry and proportions, not
detailed colors, materials, or gradients; the visualization team will add those.

Do not model a color gradient as separate surfaces or solids. Apply it later
as a rendering material.

Do not model knit texture, fabric perforations, loosely knit fabric holes, or
lace tracer yarns. Keep textile surfaces continuous and let the visualization
team supply these appearances through materials. This does not prohibit real
construction openings or hardware bores supported by the references.

## Reliable exports and crash handling

Keep scripted image generation separate from STEP export so an export failure
does not interrupt the visual comparison loop.

After a crash, inspect the crash report and relevant logs before retrying.
Diagnose export failures in an isolated process rather than repeatedly
relaunching the GUI. Preserve the editable native document and use temporary
exchange copies when export-specific conversion is required.

Reopen exported STEP files and confirm that component names, solid counts,
closed geometry, and geometry correspondence are preserved. Do not claim an
export is complete merely because a file was written.

Use the two images as reference as you model:
input/left-view.jpg
input/three-angles.jpg
