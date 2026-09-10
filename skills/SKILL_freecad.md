---
description: High-Fidelity NURBS and Tolerances in FreeCAD
tools: [FreeCAD]
---

Professional CAD modeling for footwear requires mathematically perfect curves, precise manufacturing tolerances, and structured material application. FreeCAD achieves this through its OpenCASCADE geometry kernel and a combination of specialized workbenches. 

## Phase 1: High-Fidelity NURBS (OpenCASCADE & Surface Workbench)
Unlike polygonal modeling, FreeCAD provides native support for Non-Uniform Rational B-Splines (NURBS) via its underlying geometry engine.
1. **The OpenCASCADE Kernel:** FreeCAD features a complete Open CASCADE Technology-based geometry kernel allowing complex 3D operations on complex shape types, with native support for Boundary Representation (BREP) and NURBS curves and surfaces.
2. **Surface Workbench:** This workbench provides dedicated tools to create and modify NURBS surfaces.
   - Use the **Fill Boundary Curves** tool to create a surface from two, three, or four boundary edges.
   - Ensure G1/G2 continuity by using tools that allow the **Alignment of the curvature** from neighboring faces.
3. **Parametric Foundation:** All FreeCAD objects are natively parametric. This means your NURBS surfaces can be constrained to sketches or datum planes, allowing you to tweak the underlying last or panel curves without destroying the final model.

## Phase 2: Manufacturing Tolerances (Part & PartDesign)
When transitioning from a conceptual surface upper to a physical, moldable sole (injection molding), precise tolerances dictate how operations behave.
1. **Boolean Operations and Tolerance:** In FreeCAD, tolerances affect subsequent OpenCASCADE (OCCT) functions such as boolean operations (unions, cuts for treads). 
2. **Part ToleranceSet Tool:** Use the `Part ToleranceSet` command to create a parametric copy of selected objects with all contained tolerances set to at least a certain minimum value. This ensures robust booleans when assembling complex, overlapping shoe parts.
3. **Drafts and Shrinkage:** When padding the midsole out of a 2D sketch, incorporate specific drafting angles and scale the model by exact manufacturing tolerances to account for material shrinkage (e.g., EVA foam cooling). 

## Phase 3: Structured Material Grouping (Material Workbench & Std Group)
Proper organization ensures a seamless export to photorealistic renderers (like Figurement) and accurate physical simulations (FEM).
1. **The Material Workbench:** Introduced in FreeCAD 1.0, this handles the material system. FreeCAD materials distinguish between two property sets:
   - *Physical Properties:* Density, Youngs Modulus, etc. (essential for simulating sole flexibility).
   - *Appearance Properties:* Diffuse Color, Shininess, Transparency (essential for rendering).
2. **DataShape Material Link:** When a material is assigned via the Material Selector, the `DataShape Material` property is added to the Document Object. This links the exact physical and appearance data to that shoe panel or sole component.
3. **Std Grouping for Export:** 
   - Use `Std Group` (App::DocumentObjectGroup), a general-purpose container, to organize objects in the Tree View regardless of data type.
   - Group all pieces of the shoe by their intended material (e.g., "Leather_Panels", "Rubber_Midsole"). 
   - When exporting to a `.step` file, this folder structure and the attached material properties ensure the rendering software immediately recognizes individual components and their material separations.
