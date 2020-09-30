# KERF

```
   ██╗  ██╗███████╗██████╗ ███████╗
   ██║ ██╔╝██╔════╝██╔══██╗██╔════╝
   █████╔╝ █████╗  ██████╔╝█████╗  
   ██╔═██╗ ██╔══╝  ██╔══██╗██╔══╝  
   ██║  ██╗███████╗██║  ██║██║     
   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     
```

A 3D slicing, toolpath generation, and kinodynamic motion planning engine written in LiveScript.

[![Language](https://img.shields.io/badge/language-LiveScript%201.6-blue.svg)](https://livescript.net/)
[![Platform](https://img.shields.io/badge/runtime-Node.js%20LTS-green.svg)](https://nodejs.org/)
[![Tests](https://img.shields.io/badge/tests-58%20passing-brightgreen.svg)](https://github.com/Aneesh495/kerf/blob/main/docs/VERIFICATION_PASS.md)
[![Standard](https://img.shields.io/badge/standard-NIST%20RS274%20Valid-orange.svg)](https://github.com/Aneesh495/kerf/blob/main/docs/GCODE_SPECIFICATION.md)
[![Kinematics](https://img.shields.io/badge/kinematics-S--Curve%20Profiled-blueviolet.svg)](https://github.com/Aneesh495/kerf/blob/main/docs/MOTION_PLANNING.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Aneesh495/kerf/blob/main/LICENSE)

---

## Overview

Kerf is a digital fabrication and additive manufacturing engine that transforms 3D meshes (STL, OBJ, and procedural solid geometries) into continuous, kinodynamically optimized machine toolpaths and production-ready G-code.

Under the hood, Kerf pairs 64-bit continuous floating-point transformations with nanometer integer coordinate quantization. Triangle-plane cross sections are accelerated via a 3D Surface Area Heuristic (SAH) Bounding Volume Hierarchy (BVH), stitched into closed 2D loops via spatial endpoint snapping, and organized into topological nesting trees according to the Jordan curve theorem. Interior solids are buffered using polygon offsetting algorithms and filled with continuous infill patterns, including 3D Triply Periodic Minimal Surface (TPMS) gyroids and Hilbert space-filling curves. Rapid travel moves are routed through interior obstacle-avoidance corridors and ordered using Euclidean Traveling Salesperson (TSP) 2-opt search. Finally, all moves pass through a forward-backward lookahead acceleration profiler and viscoelastic pressure advance compensator before emission to disk.

---

## Architectural Highlights

- **Dual-Precision Coordinate Model**: Combines continuous 64-bit float 3D vector transforms with 64-bit nanometer integer coordinate quantization ($1\text{ mm} = 10^6\text{ nm}$), eliminating floating-point rounding drift and micro-gap degeneracies during 2D Boolean clipping.
- **Topological Slicing & SAH BVH**: Accelerates triangle-plane slicing queries from $O(N)$ to $O(\log N + K)$ using a 3D Bounding Volume Hierarchy built with the Surface Area Heuristic.
- **Jordan Curve Nesting Hierarchy**: Uses ray-casting containment tests to organize unordered slice loops into hierarchical trees of solid exterior boundaries (Islands) and internal cavities (Holes).
- **Curvature-Driven Adaptive Layering**: Dynamically computes local surface normal inclination ($\cos \theta = |n_z|$) to vary slice thickness between $Z_{\min}$ (0.08 mm) and $Z_{\max}$ (0.28 mm), reducing print time while minimizing staircase cusp error.
- **3D Triply Periodic Minimal Surface (TPMS) Gyroid Infill**: Evaluates the implicit gyroid nodal field $\sin(kx)\cos(ky) + \sin(ky)\cos(kz) + \sin(kz)\cos(kx) = 0$ at each layer elevation and extracts smooth, self-supporting isolines via 2D Marching Squares.
- **Hilbert Space-Filling Fractal Infill**: Generates continuous recursive fractal paths providing isotropic in-plane mechanical properties and continuous extrusion without retractions.
- **Smart Convex-Corner Seam Concealment**: Analyzes interior vertex angles across closed loops and automatically hides layer start/stop seams on the sharpest convex corners.
- **Euclidean TSP 2-Opt Travel Optimization**: Solves the Traveling Salesperson Problem on disconnected loops and infill clusters using nearest-neighbor initialization and iterative 2-opt edge-swap local search.
- **Perimeter-Avoidance Comb Routing**: Constrains non-extrusion rapid traverse moves inside previously deposited solid cores, preventing nozzle stringing across visual outer perimeters.
- **Forward-Backward Lookahead Trapezoid Profiler**: Calculates allowable corner speeds via centrifugal junction deviation and applies a two-pass acceleration and deceleration filter to guarantee smooth kinematics.
- **Viscoelastic Pressure Advance**: Compensates for molten filament elasticity in the hotend melt zone, eliminating under-extruded line starts and corner bulging.
- **Virtual Machine Kinematics Simulator**: Simulates full 5-axis toolhead kinematics directly from emitted G-code, tracking filament consumption in meters and grams, and predicting build duration with sub-second precision.
- **ANSI 256-Color Terminal Preview**: Renders high-contrast ASCII/ANSI slice previews directly in the console with distinct color coding for outer perimeters, holes, and infill cores.

---

## Pipeline Architecture

```
   +--------------------------------------------------------------+
   |                     Input 3D Mesh                            |
   |              (Binary STL / Wavefront OBJ)                    |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |               Manifold Repair & Vertex Welding               |
   |     (Prunes Zero-Area Triangles, Unifies Outward Normals)    |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                 3D BVH Acceleration Index                    |
   |             (Surface Area Heuristic SAH Splits)              |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                 Adaptive Curvature Slicer                    |
   |         (Triangle-Plane Cross Section at Z Planes)           |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                 Nanometer Contour Stitcher                   |
   |          (Endpoint Graph Snapping & Loop Assembly)           |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                 Topological Hierarchy Tree                   |
   |         (Jordan Curve Nesting: Islands and Holes)            |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |               Polygon Offsetting & Smart Seams               |
   |      (Concentric Inner Perimeters, Convex Corner Seams)      |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                 Continuous Infill Generator                  |
   |         (3D Gyroid TPMS, Hilbert, Honeycomb, Grid)           |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                 Toolpath TSP & Comb Router                   |
   |         (2-Opt Travel Optimization, Perimeter Avoidance)     |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |             Kinodynamics & Acceleration Profiler             |
   |       (Centrifugal Junction Deviation, Forward-Backward)     |
   +--------------------------------------------------------------+
                                  |
                                  v
   +--------------------------------------------------------------+
   |                   G-code Emitter & VM                        |
   |        (NIST RS274 Emission, Kinematics Verification)        |
   +--------------------------------------------------------------+
```

---

## Directory Structure

```
kerf/
├── bin/
│   └── kerf                        # Command-line interface executable
├── src/
│   ├── index.ls                    # Unified pipeline API facade (KerfEngine)
│   ├── math/
│   │   ├── vector3.ls              # 3D Cartesian vector linear algebra
│   │   ├── matrix4.ls              # 4x4 affine transforms & matrix inversion
│   │   ├── plane3d.ls              # Hessian normal form plane & triangle slicing
│   │   ├── aabb3d.ls               # 3D axis-aligned bounding box
│   │   ├── quaternion.ls           # Unit quaternions & spherical interpolation
│   │   └── units.ls                # Nanometer integer coordinate quantization
│   ├── mesh/
│   │   ├── mesh.ls                 # Half-edge mesh & divergence volume
│   │   ├── stl_parser.ls           # Binary & ASCII STL parser
│   │   ├── stl_writer.ls           # Binary & ASCII STL serializer
│   │   ├── obj_parser.ls           # Wavefront OBJ parser with triangulation
│   │   ├── obj_writer.ls           # Wavefront OBJ serializer
│   │   ├── mesh_repair.ls          # Manifold healing & vertex welding
│   │   └── mesh_primitives.ls      # Procedural cubes, gears, cylinders, spheres
│   ├── spatial/
│   │   ├── bvh3d.ls                # 3D Bounding Volume Hierarchy with SAH
│   │   ├── spatial_hash.ls         # O(1) 2D/3D spatial hash grids
│   │   └── octree.ls               # 3D octree spatial partitioning
│   ├── slicing/
│   │   ├── slicer.ls               # BVH-accelerated cross-section slicer
│   │   ├── adaptive_slicer.ls      # Curvature-driven adaptive layer heights
│   │   ├── contour_stitcher.ls     # Nanometer segment loop closure
│   │   ├── topology_tree.ls        # Jordan curve island/hole nesting tree
│   │   └── slice_layer.ls          # Layer data model & toolpath registry
│   ├── geometry2d/
│   │   ├── point2d.ls              # 2D planar point & vector arithmetic
│   │   ├── segment2d.ls            # 2D line segment intersection & projection
│   │   ├── polygon2d.ls            # Shoelace signed area & winding checks
│   │   ├── polygon_offset.ls       # Concentric buffering & perimeter insets
│   │   └── polygon_clipper.ls      # Sutherland-Hodgman polygon clipping
│   ├── infill/
│   │   ├── infill_base.ls          # Base class with island/hole clipping
│   │   ├── rectilinear_infill.ls   # Alternating scanlines with turnarounds
│   │   ├── grid_infill.ls          # Orthogonal two-pass structural grid
│   │   ├── concentric_infill.ls    # Recursive inward contour nesting
│   │   ├── honeycomb_infill.ls     # Hexagonal continuous cell tessellation
│   │   ├── hilbert_infill.ls       # Recursive fractal space-filling curves
│   │   ├── gyroid_infill.ls        # 3D TPMS Marching Squares isoline infill
│   │   └── support_generator.ls    # Overhang detection & breakaway interfaces
│   ├── toolpath/
│   │   ├── toolpath_segment.ls     # Feedrate & move categorization
│   │   ├── seam_planner.ls         # Smart convex-corner seam placement
│   │   ├── travel_optimizer.ls     # Euclidean TSP 2-opt local search
│   │   └── comb_router.ls          # Perimeter-avoidance internal travel
│   ├── motion/
│   │   ├── kinematics_limits.ls    # Machine boundaries & volumetric flow
│   │   ├── junction_deviation.ls   # Centrifugal cornering velocity
│   │   ├── trapezoid_planner.ls    # Forward-backward lookahead acceleration
│   │   ├── scurve_planner.ls       # 7-segment jerk-limited motion profiler
│   │   └── pressure_advance.ls     # Viscoelastic nozzle hysteresis compensation
│   ├── gcode/
│   │   ├── gcode_emitter.ls        # Multi-flavor NIST RS274 G-code generator
│   │   ├── gcode_parser.ls         # Modal command & parameter tokenizer
│   │   └── gcode_interpreter.ls    # Virtual machine kinematics simulator
│   └── vis/
│       ├── ascii_art.ls            # High-contrast ASCII banners & tables
│       ├── terminal_renderer.ls    # ANSI 256-color terminal slice visualizer
│       └── svg_exporter.ls         # Interactive vector graphic layer exporter
├── test/
│   ├── run_tests.js                # Test suite execution harness
│   ├── run_benchmarks.js           # Performance benchmark suite
│   ├── test_runner_utils.ls        # Assertions & test suite utilities
│   ├── test_math.ls                # Math subsystem tests
│   ├── test_mesh.ls                # Mesh format & repair tests
│   ├── test_spatial.ls             # BVH & spatial hashing tests
│   ├── test_geometry2d.ls          # 2D geometry & offset tests
│   ├── test_slicer.ls              # Slicing & topology tests
│   ├── test_infill.ls              # All 6 infill pattern tests
│   ├── test_toolpath_opt.ls        # Seams & TSP 2-opt tests
│   ├── test_motion_planner.ls      # Junction deviation & trapezoid tests
│   ├── test_gcode.ls               # G-code emission & VM interpreter tests
│   ├── test_vis.ls                 # Terminal rendering & SVG export tests
│   ├── test_bug_fixes.ls           # Permanent regression suite for bug fixes
│   └── test_pipeline.ls            # End-to-end KerfEngine integration tests
├── docs/
│   ├── ARCHITECTURE.md             # System architecture & module specifications
│   ├── SLICING_GEOMETRY.md         # Slicing mathematics & topology proofs
│   ├── INFILL_ALGORITHMS.md        # TPMS gyroid, Hilbert, and honeycomb specs
│   ├── MOTION_PLANNING.md          # Kinodynamics & forward-backward lookahead
│   ├── GCODE_SPECIFICATION.md      # RS274 modal state machine & VM specs
│   ├── BUG_LOG.md                  # Detailed defect root-cause analysis registry
│   └── VERIFICATION_PASS.md        # Complete test and benchmark audit matrix
├── samples/                        # Sample 3D fabrication models
│   ├── calibration_cube.stl        # 20mm calibration cube (Binary STL)
│   ├── mechanical_gear.stl         # Precision mechanical gear (Binary STL)
│   ├── bearing_cylinder.obj        # Watertight cylinder (Wavefront OBJ)
│   └── curvature_sphere.obj        # Curvature benchmark dome (Wavefront OBJ)
└── scripts/
    ├── verify_no_em_dashes.py      # Automated typography compliance verifier
    └── generate_samples.ls         # Sample procedural asset generator
```

---

## Quickstart & CLI Reference

### 1. Installation
Clone repository and install dependencies:

```bash
git clone https://github.com/Aneesh495/kerf.git
cd kerf
npm install
```

### 2. Run Interactive Demo
Execute an end-to-end demonstration slicing a precision mechanical gear with gyroid infill:

```bash
npm run demo
```

### 3. Inspect a 3D Mesh
Inspect triangle count, enclosed volume, surface area, bounding dimensions, and watertight manifold status:

```bash
./bin/kerf info samples/mechanical_gear.stl
```

### 4. Slice to G-code with Terminal Preview
Slice a model, render an ANSI 256-color preview of the middle layer, and write production G-code:

```bash
./bin/kerf slice samples/mechanical_gear.stl \
  --layer-height 0.20 \
  --infill 0.25 \
  --pattern gyroid \
  --perimeters 2 \
  --preview \
  --out output.gcode
```

### 5. Export SVG Vector Graphics
Export an interactive vector visualization of slice layer 12:

```bash
./bin/kerf slice samples/mechanical_gear.stl \
  --layer 12 \
  --svg layer_12.svg
```

---

## Programmatic LiveScript API

```livescript
{ KerfEngine, MeshPrimitives, STLParser } = require 'kerf'

# 1. Create or load a 3D mesh
gear = MeshPrimitives.create-gear 12, 15.0, 3.0, 5.0

# 2. Configure the fabrication engine
engine = new KerfEngine {
  layer-height: 0.20
  infill-density: 0.25
  infill-pattern: 'gyroid'
  perimeters: 2
  flavor: 'Marlin'
  adaptive: false
}

# 3. Execute slicing and kinodynamic profiling
result = engine.slice-mesh gear

console.log "Total Layers Sliced: #{result.layer-count}"
console.log "Estimated Print Time: #{result.metrics.formatted-time}"
console.log "Filament Consumed: #{result.metrics.filament-mass-grams.toFixed 2} grams"

# 4. Save emitted G-code
fs = require 'fs'
fs.write-file-sync 'gear_output.gcode', result.gcode, 'utf8'
```

---

## Test Coverage Matrix

Run the comprehensive test suite:

```bash
npm test
```

| Test Suite | Module | Test Cases | Pass Rate | Focus |
|---|---|---|---|---|
| `test_math.ls` | `src/math/*` | 10 | 100% | Vectors, 4x4 matrix inversion, planes, AABB bounds, nanometer units |
| `test_mesh.ls` | `src/mesh/*` | 7 | 100% | STL binary/ASCII roundtrip, OBJ parsing, divergence volume, healing |
| `test_spatial.ls` | `src/spatial/*` | 3 | 100% | BVH Surface Area Heuristic, spatial hashing, octree range search |
| `test_geometry2d.ls` | `src/geometry2d/*` | 5 | 100% | Shoelace area, Jordan curve, concentric offsetting, segment clipping |
| `test_slicer.ls` | `src/slicing/*` | 4 | 100% | Contour stitching, topology trees, adaptive curvature layer heights |
| `test_infill.ls` | `src/infill/*` | 7 | 100% | Rectilinear, grid, concentric, honeycomb, Hilbert, 3D gyroid, supports |
| `test_toolpath_opt.ls` | `src/toolpath/*` | 4 | 100% | Toolpath segments, convex corner seams, TSP 2-opt search, comb routing |
| `test_motion_planner.ls`| `src/motion/*` | 5 | 100% | Junction deviation, forward-backward lookahead, S-curves, pressure advance |
| `test_gcode.ls` | `src/gcode/*` | 3 | 100% | RS274 emitter, modal command tokenizer, virtual machine interpreter |
| `test_vis.ls` | `src/vis/*` | 3 | 100% | ASCII banners, ANSI 256-color terminal renderer, SVG vector graphics |
| `test_bug_fixes.ls` | `test/*` | 4 | 100% | Permanent regression suite for discovered compiler & arithmetic edge cases |
| `test_pipeline.ls` | `src/index.ls` | 3 | 100% | End-to-end integration tests on calibration cubes, gears, and spheres |
| **Total** | | **58** | **100%** | **Zero defects, zero regressions** |

---

## Performance Benchmarks

Run the benchmark suite:

```bash
npm run benchmark
```

Representative benchmarks on an Apple Silicon workstation:

- **Vector3 Transform Matrix4**: 805,936,853 ops/second ($0.00 \ \mu\text{s/op}$)
- **Binary STL Parser Throughput**: 732,328 ops/second ($1.37 \ \mu\text{s/op}$)
- **BVH Plane-Z Slicing Query**: 423,501 ops/second ($2.36 \ \mu\text{s/op}$)
- **Polygon Inward Offsetting**: 2,577,162 ops/second ($0.39 \ \mu\text{s/op}$)
- **3D TPMS Gyroid Layer Infill**: 720 layers/second ($1.38 \ \text{ms/layer}$)
- **Trapezoid Lookahead Motion Profiler**: 439,240 blocks/second ($2.28 \ \mu\text{s/block}$)
- **End-to-End Gear Slicing Engine**: 93 full models/second ($10.80 \ \text{ms/model}$)

---

## Typography Standards

This codebase enforces strict typography standards. As verified by `scripts/verify_no_em_dashes.py`, the entire codebase, documentation, comments, and commit history contain zero em dashes (Unicode U+2014) and zero en dashes (Unicode U+2013).

```bash
python3 scripts/verify_no_em_dashes.py
```

---

## License

This project is licensed under the MIT License. See [LICENSE](https://github.com/Aneesh495/kerf/blob/main/LICENSE) for details.
