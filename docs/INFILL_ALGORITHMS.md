# Infill Algorithms Specification

## 1. Mathematical Overview

In digital fabrication and additive manufacturing, infill patterns provide interior structural integrity while conserving material and minimizing fabrication time. Kerf implements six distinct infill algorithms, ranging from standard geometric crosshatching to continuous space-filling fractal curves and triply periodic minimal surfaces.

---

## 2. 3D Triply Periodic Minimal Surface (TPMS) Gyroid Infill

The Gyroid is an infinitely connected, non-self-intersecting periodic surface discovered by NASA mathematician Alan Schoen in 1970. It belongs to the family of Triply Periodic Minimal Surfaces (TPMS) with zero mean curvature at every point ($H = 0$).

### 2.1 Implicit Equation
The gyroid surface is approximated by the nodal implicit level-set function:

$$F(x, y, z) = \sin(k x) \cos(k y) + \sin(k y) \cos(k z) + \sin(k z) \cos(k x) = 0$$

where the spatial frequency $k$ is determined by the unit cell length $L$:

$$k = \frac{2\pi}{L}$$

### 2.2 Slicing via 2D Marching Squares
At any discrete fabrication layer height $z = z_0$, the 3D scalar field simplifies to a 2D scalar field across the $XY$ build plane:

$$G(x, y) = \sin(k x) \cos(k y) + \sin(k y) \cos(k z_0) + \sin(k z_0) \cos(k x)$$

Kerf evaluates $G(x, y)$ on a regular 2D grid covering the island bounding box. For each grid cell, the signs of the four corner vertices define a 4-bit index in $\{0, \dots, 15\}$. Zero-crossing edge intersection points are computed via linear interpolation:

$$t = \frac{-G(A)}{G(B) - G(A)} \in [0, 1]$$

$$\mathbf{p}_{\text{edge}} = \mathbf{p}_A + t (\mathbf{p}_B - \mathbf{p}_A)$$

The extracted isoline segments are subsequently clipped to the solid island interior.

### 2.3 Mechanical Characteristics
- Isotropic strength: Yields identical compressive and shear strength in all three principal axes ($X, Y, Z$).
- Continuous permeability: Both internal labyrinths are open, facilitating fluid flow, resin draining, and heat dissipation.
- Absence of sharp corners: Toolhead velocity remains high throughout extrusion because all curves are smooth and continuous.

---

## 3. Hilbert Space-Filling Curve Infill

The Hilbert curve is a continuous, self-similar fractal space-filling curve first described by David Hilbert in 1891. It maps the one-dimensional unit interval $[0, 1]$ onto the two-dimensional unit square $[0, 1] \times [0, 1]$.

### 3.1 Recursive Generation
For an order-$N$ Hilbert curve, the unit square is partitioned into $2^{2N}$ discrete points. The position of point $d \in \{0, \dots, 2^{2N} - 1\}$ is computed by bitwise coordinate extraction and quadrant rotation:

$$\mathbf{p}(d) = \sum_{i=0}^{N-1} \mathbf{R}_i(d_i)$$

where $d_i$ represents the base-4 digits of $d$, and $\mathbf{R}_i$ applies 90-degree quadrant reflections.

### 3.2 Mechanical Characteristics
- Isotropic planar tensile strength: Eliminates the preferential weak cleavage planes present in unidirectional rectilinear infills.
- Continuous single toolpath: The entire infill across a layer can be extruded in a continuous unbroken motion without intermediate retractions.

---

## 4. Hexagonal Honeycomb Infill

The honeycomb infill mimics the natural hexagonal prism structure of bee hives, which represents the optimal planar tessellation minimizing total boundary perimeter for a given enclosed area.

### 4.1 Tessellation Geometry
Hexagonal cells of radius $R$ are arranged in an alternating staggered grid:

$$\Delta X = 1.5 \cdot R$$
$$\Delta Y = \sqrt{3} \cdot R$$

For odd column indices, the $Y$ coordinate is offset by $\frac{\Delta Y}{2}$. Edges shared between neighboring cells are deduplicated using a spatial hash table to prevent redundant double-extrusion.

---

## 5. Rectilinear & Monotonic Infill

Rectilinear infill extrudes parallel scanlines across the component interior at alternating angles (e.g. 45 degrees on even layers, 135 degrees on odd layers).

To minimize non-extrusion rapid travels, Kerf implements monotonic path chaining:
- Consecutive parallel scanlines are joined at their perimeter endpoints.
- Line direction alternates between consecutive passes ($\mathbf{p}_1 \to \mathbf{p}_2$, then $\mathbf{p}_2 \to \mathbf{p}_1$).
- Travel moves along perimeter boundaries maintain active hotend flow without requiring retraction.

---

## 6. Concentric Infill

Concentric infill recursively offsets the outer perimeter contour inward by the user-defined line spacing $\Delta d = \frac{w_{\text{extrusion}}}{\text{density}}$:

$$C_{k+1} = \operatorname{Inset}(C_k, \Delta d)$$

This process repeats until the remaining polygon area collapses below $10^{-4} \text{ mm}^2$. Concentric infill is well-suited for cylindrical pressure vessels, pipes, and aerodynamic components subject to hoop stress.
