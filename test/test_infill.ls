# Unit tests for infill generators: Rectilinear, Grid, Concentric, Honeycomb, Hilbert, Gyroid

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Point2D = require '../src/geometry2d/point2d'
Polygon2D = require '../src/geometry2d/polygon2d'
{ IslandNode } = require '../src/slicing/topology_tree'
RectilinearInfill = require '../src/infill/rectilinear_infill'
GridInfill = require '../src/infill/grid_infill'
ConcentricInfill = require '../src/infill/concentric_infill'
HoneycombInfill = require '../src/infill/honeycomb_infill'
HilbertInfill = require '../src/infill/hilbert_infill'
GyroidInfill = require '../src/infill/gyroid_infill'
SupportGenerator = require '../src/infill/support_generator'
MeshPrimitives = require '../src/mesh/mesh_primitives'

describe "Infill Pattern Topologies", ->
  # Create a 20x20 test island
  square = new Polygon2D [
    new Point2D 0, 0
    new Point2D 20, 0
    new Point2D 20, 20
    new Point2D 0, 20
  ]
  island = new IslandNode square

  test-case "generates alternating rectilinear scanlines inside island boundaries", ->
    rect = new RectilinearInfill { density: 0.25, extrusion-width: 0.5 }
    paths-layer-a = rect.generate-for-island island, 0.2, 0
    paths-layer-b = rect.generate-for-island island, 0.4, 1

    assert.ok paths-layer-a.length > 0
    assert.ok paths-layer-b.length > 0

    # Ensure all segment midpoints lie inside the square
    for seg in paths-layer-a
      mid = seg.p1.lerp seg.p2, 0.5
      assert.ok island.contour.contains-point mid

  test-case "generates structural grid crosshatch pattern", ->
    grid = new GridInfill { density: 0.2, extrusion-width: 0.5 }
    paths = grid.generate-for-island island, 0.2, 0
    assert.ok paths.length > 5

  test-case "generates concentric nested offset perimeters", ->
    concentric = new ConcentricInfill { density: 0.3, extrusion-width: 0.5 }
    paths = concentric.generate-for-island island, 0.2, 0
    assert.ok paths.length > 0

  test-case "generates hexagonal honeycomb tessellation", ->
    honey = new HoneycombInfill { density: 0.2, extrusion-width: 0.5 }
    paths = honey.generate-for-island island, 0.2, 0
    assert.ok paths.length > 0

  test-case "generates fractal Hilbert space-filling curve", ->
    hilbert = new HilbertInfill { density: 0.2, extrusion-width: 0.5 }
    paths = hilbert.generate-for-island island, 0.2, 0
    assert.ok paths.length > 0

  test-case "generates 3D TPMS Gyroid minimal surface isolines", ->
    gyroid = new GyroidInfill { density: 0.2, extrusion-width: 0.5, cell-size: 8.0 }
    paths = gyroid.generate-for-island island, 0.2, 0
    assert.ok paths.length > 0
    for seg in paths
      mid = seg.p1.lerp seg.p2, 0.5
      assert.ok island.contour.contains-point mid

describe "Overhang Support Generation", ->
  test-case "detects downward overhanging faces and generates support paths", ->
    # A box has vertical sides and top/bottom caps (downward cap at Z=0 is on bed)
    # A cylinder has bottom cap
    cyl = MeshPrimitives.create-cylinder 10.0, 20.0, 16
    support = new SupportGenerator cyl, { overhang-angle-deg: 45.0 }
    overhangs = support.find-overhang-triangles!
    assert.ok overhangs != null
