---
description: Professional Shoe CAD Modeling for Production & Visualization
tools: [FreeCAD]
---

Professional footwear CAD modeling prioritizes high-fidelity NURBS (Non-Uniform Rational B-Splines) surfaces, precise manufacturing tolerances, and highly structured material grouping. Unlike polygonal modeling, this workflow ensures mathematically perfect curves that translate seamlessly into injection molding software and photorealistic renderers like Figurement.

## Phase 1: The Last (Anatomical Foundation)
The "last" is the 3D anatomical mold of the foot. Professional models are always built over a highly accurate last to ensure the shoe is wearable and proportional.
1. **Importing the Last:** Import a high-resolution 3D scan of a physical last or a pre-engineered 3D last model (usually a `.step` or `.iges` file).
2. **Surface Rebuilding:** If the imported last is a dense mesh, use surface retopology tools to convert it into clean, continuous NURBS surfaces. This clean base is essential for the upper to conform correctly.
3. **Reference Projection:** Import 2D vector sketches (from Adobe Illustrator) or high-res concept art. Project these orthographic views onto the 3D last to serve as exact boundaries for seams and panels.

## Phase 2: Upper Construction (Surface Trimming & Thickening)
Professionals do not loft the upper from scratch; they build it by extracting geometry directly from the last.
1. **Curve Projection:** Draw 3D spline curves directly on the surface of the last, following the projected 2D design. These curves represent the panel boundaries, collar, tongue, and toe box.
2. **Surface Splitting & Trimming:** Use the projected curves to split the master surface into individual pieces representing the leather, mesh, or synthetic panels.
3. **Offsetting for Thickness:** Offset each trimmed surface outward by specific manufacturing tolerances (e.g., 1.5mm for leather, 0.8mm for synthetic linings) to create solid panels. 
4. **Edge Filleting:** Apply micro-fillets (0.2mm - 0.5mm) to the raw edges of the solid panels. In reality, cut materials are rarely razor-sharp. These fillets catch light beautifully in Figurement.

## Phase 3: The Tooling (Midsole & Outsole Engineering)
The sole requires exact solid modeling, as it is typically manufactured via injection molding or compression molding.
1. **Footprint & Profile:** Create the base perimeter and extrude it. Use sweep and loft operations to create the sidewall profiles of the midsole, ensuring they encapsulate the bottom of the last.
2. **Draft Angles:** Apply a draft angle (usually 2 to 5 degrees) to all vertical faces of the sole tooling. This allows the physical sole to be ejected from the steel manufacturing mold.
3. **Tread Patterns & Booleans:** Model a single tread lug as a solid body. Use array tools along a curved path to populate the outsole. Use Boolean Union to merge them, or Boolean Difference to cut flex grooves into the forefoot.
4. **Cushioning Elements:** Model visible air units or gel pods as separate bodies with their own wall thicknesses, ensuring they can be assigned distinct transparent/refractive materials in Figurement.

## Phase 4: Micro-Details (Stitching, Perforations, Hardware)
Render realism relies heavily on the smallest physical details. 
1. **Modeled Stitches:** Instead of relying purely on bump maps, professionals model stitches for close-up renders. 
   - Extract the edge curve of a panel and offset it slightly inward.
   - Create a single 3D stitch (a swept arc).
   - Array the stitch along the offset curve.
2. **Perforations:** Draw a 2D pattern of circles. Project them onto the toe box surface and use a Boolean Cut to punch actual holes through the solid material thickness.
3. **Laces and Hardware:** Model eyelets, lace aglets (the plastic tips), and D-rings as independent solid bodies. Model the laces using 3D sweeps along complex spatial splines, ensuring they realistically compress and deform where they pass through the eyelets.

## Phase 5: Rendering Preparation & Export
Figurement reads materials based on the structure and naming conventions of the imported CAD file.
1. **Material Grouping:** Separate every component by its intended material, not just its location. Group all "White Matte Leather" panels together, and separate them from "Glossy TPU Plastics" or "Nylon Webbing."
2. **Color Coding:** Assign distinct, high-contrast display colors to each group within your CAD software. Figurement will use these colors to separate parts, allowing you to drag-and-drop Figurement materials instantly onto the correct components.
3. **NURBS Export (STEP/IGES):** Export the final model as a `.step` (Standard for the Exchange of Product model data) or `.iges` file. Unlike `.obj` or `.stl` which break curves into flat triangles, `.step` files retain perfect mathematical curves. Figurement can render NURBS directly, resulting in flawless, faceting-free silhouettes and reflections.
