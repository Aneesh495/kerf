# Slicing Geometry Specification

## 1. Mathematical Formulation

Slicing is the process of computing 2D cross sections of a 3D manifold mesh along a sequence of horizontal planes:

$$P(z) = \{ (x, y, z) \in \mathbb{R}^3 \mid z = z_k \}$$

For each triangle $T = \{ \mathbf{v}_0, \mathbf{v}_1, \mathbf{v}_2 \}$, we compute the signed distance of each vertex to the plane $z = z_k$:

$$d_i = \mathbf{v}_i \cdot \hat{\mathbf{n}} + D = v_{i, z} - z_k \quad \text{for } i \in \{0, 1, 2\}$$

### 1.1 Triangle-Plane Intersection Cases

1. No Intersection: If all three distances share the same sign ($\min(d_0, d_1, d_2) > 0$ or $\max(d_0, d_1, d_2) < 0$), the triangle does not intersect the slicing plane.
2. Coplanar Face: If $d_0 = d_1 = d_2 = 0$, the face lies entirely within the slicing plane. Coplanar triangles are omitted from vertical contour slicing to prevent zero-thickness degenerate boundaries.
3. Transversal Intersection: Two vertices lie on one side of the plane and one vertex lies on the opposing side. The plane intersects two edges of the triangle at parametric coordinates:

$$t = \frac{d_A}{d_A - d_B} \in [0, 1]$$

$$\mathbf{p}_{\text{inter}} = \mathbf{v}_A + t (\mathbf{v}_B - \mathbf{v}_A)$$

The pair of intersection points defines an oriented directed segment:

$$\mathbf{s} = [ \mathbf{p}_1, \mathbf{p}_2 ] \in \mathbb{R}^2$$

---

## 2. Nanometer Quantization Model

Floating-point precision errors (such as $0.1 + 0.2 \neq 0.3$) can introduce micro-gaps, spurious T-junctions, and inverted loops during contour reconstruction. Kerf quantizes all 2D planar coordinates into exact 64-bit nanometer integers:

$$X_{\text{nm}} = \operatorname{round}(X_{\text{mm}} \times 10^6)$$
$$Y_{\text{nm}} = \operatorname{round}(Y_{\text{mm}} \times 10^6)$$

This yields a coordinate space where 1 millimeter corresponds to exactly 1,000,000 discrete integer units, providing zero drift and consistent topological snapping.

---

## 3. Contour Stitching Algorithm

Raw triangle-plane intersections produce an unordered soup of directed line segments. The `ContourStitcher` links these segments into closed counter-clockwise (CCW) polygons:

1. Spatial Endpoint Indexing: Each segment start point $\mathbf{p}_1$ and end point $\mathbf{p}_2$ is hashed into a spatial grid with cell size equal to the snapping tolerance $\epsilon = 10^{-4}$ mm.
2. Directed Graph Traversal: Starting from an unvisited segment $s_0$, the stitcher queries the spatial hash for adjacent candidate segments whose start point matches the current segment end point within distance $\epsilon$.
3. Direction Fallback: If no start point matches, candidate end points are inspected. If an end point matches, the candidate segment orientation is flipped.
4. Loop Closure: Traversal continues until the current endpoint connects back to the starting point of the loop, or no unvisited candidate remains.
5. Degeneracy Filtering: Loops with fewer than 3 vertices or with Shoelace area smaller than $10^{-6} \text{ mm}^2$ are pruned.

---

## 4. Jordan Curve Topological Nesting Hierarchy

A sliced layer may contain multiple disjoint solid bodies (islands) and multiple hollow internal cavities (holes). Kerf organizes these contours using the Jordan curve theorem and ray-casting containment tests:

1. Area Sorting: All reconstructed closed loops are sorted descending by their Shoelace area.
2. Containment Matrix: For each pair of loops $(L_i, L_j)$ with $\operatorname{Area}(L_i) > \operatorname{Area}(L_j)$, a ray-casting point-in-polygon test determines whether $L_i$ encloses $L_j$.
3. Parent Depth Evaluation:
   - Contours with an even number of enclosing parent loops (depth 0, 2, 4...) represent exterior solid boundaries (Islands).
   - Contours with an odd number of enclosing parent loops (depth 1, 3, 5...) represent hollow interior cavities (Holes).
4. Immediate Hierarchy Assignment: Each hole is assigned to its smallest enclosing island. Nested islands inside holes (depth >= 2) are recursively linked as children of the enclosing island.

---

## 5. Curvature-Driven Adaptive Layer Slicing

Uniform layer heights represent a compromise between print duration and vertical surface fidelity. On shallow, gently sloping surfaces, coarse layer heights create noticeable staircase artifacts. On steep vertical walls, coarse layer heights produce near-perfect surface quality.

Kerf evaluates the surface normal $\hat{\mathbf{n}} = (n_x, n_y, n_z)$ of triangles intersecting each elevation $z$. For a surface tilted at angle $\theta$ relative to the horizontal plane, the normal component is:

$$\cos(\theta) = |n_z|$$

The geometric staircase cusp error $h$ produced by a layer of thickness $\Delta z$ is:

$$h = \Delta z \cdot |n_z|$$

Given a maximum acceptable cusp height $h_{\text{target}}$ (e.g. 0.02 mm), the optimal layer thickness at elevation $z$ is:

$$\Delta z_{\text{optimal}} = \frac{h_{\text{target}}}{\max_{\text{triangles}} |n_z|}$$

This value is clamped between user-configured physical boundaries:

$$\Delta z = \max\left(Z_{\min}, \min\left(Z_{\max}, \Delta z_{\text{optimal}}\right)\right)$$

On vertical walls ($|n_z| \approx 0$), $\Delta z = Z_{\max}$ (e.g. 0.28 mm). On shallow curved domes ($|n_z| \to 1$), $\Delta z = Z_{\min}$ (e.g. 0.08 mm). This dynamic scaling reduces total print time by up to 45% while preserving optical fidelity on curved features.
