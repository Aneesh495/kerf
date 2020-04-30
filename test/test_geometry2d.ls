# Unit tests for 2D computational geometry, polygon offsetting, and clipping

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Point2D = require '../src/geometry2d/point2d'
Segment2D = require '../src/geometry2d/segment2d'
Polygon2D = require '../src/geometry2d/polygon2d'
PolygonOffset = require '../src/geometry2d/polygon_offset'
PolygonClipper = require '../src/geometry2d/polygon_clipper'

describe "Point2D and Segment2D Operations", ->
  test-case "calculates distance, normal rotation, and cross product", ->
    p1 = new Point2D 0, 0
    p2 = new Point2D 3, 4
    assert.strictEqual p1.distance-to(p2), 5.0
    dir = p2.normalize!
    assert-approx dir.x, 0.6
    assert-approx dir.y, 0.8

    left-norm = dir.normal-left!
    assert-approx left-norm.x, -0.8
    assert-approx left-norm.y, 0.6

  test-case "detects segment intersections accurately", ->
    s1 = new Segment2D (new Point2D 0, 0), (new Point2D 10, 10)
    s2 = new Segment2D (new Point2D 0, 10), (new Point2D 10, 0)
    inter = s1.intersect-segment s2
    assert.ok inter != null
    assert-approx inter.x, 5.0
    assert-approx inter.y, 5.0

    # Non-intersecting parallel segments
    s3 = new Segment2D (new Point2D 0, 0), (new Point2D 10, 0)
    s4 = new Segment2D (new Point2D 0, 5), (new Point2D 10, 5)
    assert.strictEqual s3.intersect-segment(s4), null

describe "Polygon2D Analysis", ->
  test-case "computes Shoelace area, centroid, and winding order", ->
    # 10x10 CCW square
    square = new Polygon2D [
      new Point2D 0, 0
      new Point2D 10, 0
      new Point2D 10, 10
      new Point2D 0, 10
    ]
    assert.strictEqual square.signed-area!, 100.0
    assert.strictEqual square.area!, 100.0
    assert.ok square.is-ccw!
    assert.strictEqual square.perimeter!, 40.0

    c = square.centroid!
    assert-approx c.x, 5.0
    assert-approx c.y, 5.0

    assert.ok square.contains-point new Point2D 5, 5
    assert.ok not square.contains-point new Point2D 15, 5
    assert.ok not square.contains-point new Point2D -2, 5

describe "Polygon Offsetting", ->
  test-case "insets square polygon to create concentric inner wall", ->
    square = new Polygon2D [
      new Point2D 0, 0
      new Point2D 20, 0
      new Point2D 20, 20
      new Point2D 0, 20
    ]
    # Inset by 2.0 mm (should yield 16x16 square = area 256)
    inner = PolygonOffset.inset square, 2.0
    assert.ok inner != null
    assert-approx inner.area!, 256.0, 1e-3

    # Generate 2 concentric perimeters
    shells = PolygonOffset.generate-concentric-perimeters square, 0.5, 2
    assert.strictEqual shells.length, 2
    assert.ok shells[0].area! < square.area!
    assert.ok shells[1].area! < shells[0].area!

describe "Polygon Clipping and Infill Scanlines", ->
  test-case "clips long scanline to polygon boundary", ->
    square = new Polygon2D [
      new Point2D 0, 0
      new Point2D 10, 0
      new Point2D 10, 10
      new Point2D 0, 10
    ]
    # Horizontal line from (-10, 5) to (20, 5) crossing the square
    scanline = new Segment2D (new Point2D -10, 5), (new Point2D 20, 5)
    clipped = PolygonClipper.clip-segment-to-polygon scanline, square
    assert.strictEqual clipped.length, 1
    assert-approx clipped[0].p1.x, 0.0
    assert-approx clipped[0].p1.y, 5.0
    assert-approx clipped[0].p2.x, 10.0
    assert-approx clipped[0].p2.y, 5.0
