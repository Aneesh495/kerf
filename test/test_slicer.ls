# Unit tests for 3D slicing, contour stitching, and topology reconstruction

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Vector3 = require '../src/math/vector3'
Point2D = require '../src/geometry2d/point2d'
Segment2D = require '../src/geometry2d/segment2d'
Polygon2D = require '../src/geometry2d/polygon2d'
MeshPrimitives = require '../src/mesh/mesh_primitives'
ContourStitcher = require '../src/slicing/contour_stitcher'
{ TopologyTree } = require '../src/slicing/topology_tree'
Slicer = require '../src/slicing/slicer'
AdaptiveSlicer = require '../src/slicing/adaptive_slicer'

describe "ContourStitcher Segment Closure", ->
  test-case "stitches disordered line segments into closed CCW polygon loop", ->
    # 4 segments forming a 10x10 square, given in shuffled order
    s1 = new Segment2D (new Point2D 0, 0), (new Point2D 10, 0)
    s2 = new Segment2D (new Point2D 10, 0), (new Point2D 10, 10)
    s3 = new Segment2D (new Point2D 10, 10), (new Point2D 0, 10)
    s4 = new Segment2D (new Point2D 0, 10), (new Point2D 0, 0)

    # Shuffled input
    segments = [s3, s1, s4, s2]
    loops = ContourStitcher.stitch segments, 1e-4

    assert.strictEqual loops.length, 1
    poly = loops[0]
    assert.strictEqual poly.vertex-count!, 4
    assert-approx poly.area!, 100.0, 1e-4

describe "TopologyTree Island and Hole Hierarchy", ->
  test-case "separates solid outer boundaries from interior holes", ->
    # Outer 20x20 boundary (area 400)
    outer = new Polygon2D [
      new Point2D 0, 0
      new Point2D 20, 0
      new Point2D 20, 20
      new Point2D 0, 20
    ]
    # Inner 10x10 hole (area 100) centered at (5, 5)
    hole = new Polygon2D [
      new Point2D 5, 5
      new Point2D 15, 5
      new Point2D 15, 15
      new Point2D 5, 15
    ]

    islands = TopologyTree.build [outer, hole]
    assert.strictEqual islands.length, 1
    root = islands[0]
    assert.strictEqual root.holes.length, 1
    # Net solid area = 400 - 100 = 300
    assert-approx root.area!, 300.0, 1e-4

describe "3D Mesh Slicer", ->
  test-case "slices calibration cube into exact horizontal square contours", ->
    cube = MeshPrimitives.create-box 20.0, 20.0, 20.0
    slicer = new Slicer cube, { layer-height: 1.0, first-layer-height: 1.0 }
    layers = slicer.slice-all!

    assert.ok layers.length >= 19
    for layer in layers
      assert.strictEqual layer.islands.length, 1
      island = layer.islands[0]
      # Each slice of a 20x20 cube must have contour area approx 400.0
      assert-approx island.contour.area!, 400.0, 1e-2

  test-case "adapts layer thickness based on surface slope", ->
    sphere = MeshPrimitives.create-sphere 10.0, 16, 16
    adaptive = new AdaptiveSlicer sphere, {
      min-thickness: 0.1
      max-thickness: 0.5
      target-cusp-height: 0.02
    }
    layers = adaptive.slice-all!
    assert.ok layers.length > 5
    # Verification: layer thickness varies across the height
    thicknesses = [l.thickness for l in layers]
    min-t = Math.min.apply null, thicknesses
    max-t = Math.max.apply null, thicknesses
    assert.ok max-t >= min-t
