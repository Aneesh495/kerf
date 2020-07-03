# Unit tests for toolpath representations, seam placement, and TSP travel optimization

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Point2D = require '../src/geometry2d/point2d'
Polygon2D = require '../src/geometry2d/polygon2d'
{ ToolpathType, ToolpathSegment } = require '../src/toolpath/toolpath_segment'
{ SeamPlacement, SeamPlanner } = require '../src/toolpath/seam_planner'
TravelOptimizer = require '../src/toolpath/travel_optimizer'
CombRouter = require '../src/toolpath/comb_router'
{ IslandNode } = require '../src/slicing/topology_tree'

describe "Toolpath Segments", ->
  test-case "correctly initializes toolpath segment and computes duration", ->
    p1 = new Point2D 0, 0
    p2 = new Point2D 30, 40 # Length = 50 mm
    seg = new ToolpathSegment p1, p2, ToolpathType.PERIMETER_OUTER, { feedrate: 3000.0 }
    assert.strictEqual seg.length!, 50.0
    # 3000 mm/min = 50 mm/sec -> 50 mm takes 1.0 sec
    assert-approx seg.duration-sec!, 1.0, 1e-4
    assert.ok seg.is-extrusion!

describe "Smart Seam Placement", ->
  test-case "locates sharpest convex corner to hide seam artifacts", ->
    # Diamond with sharp corners at (0, 10), (10, 0), (0, -10), (-10, 0)
    diamond = new Polygon2D [
      new Point2D 0, 10
      new Point2D 10, 0
      new Point2D 0, -10
      new Point2D -10, 0
    ]
    seam-idx = SeamPlanner.find-best-seam-index diamond, SeamPlacement.CONVEX_CORNER
    assert.ok seam-idx >= 0 and seam-idx < 4

    reordered = SeamPlanner.reorder-polygon-at-seam diamond, SeamPlacement.CONVEX_CORNER
    assert.strictEqual reordered.vertex-count!, 4

describe "Traveling Salesperson 2-Opt Optimizer", ->
  test-case "orders disjoint loops to minimize travel distance", ->
    # 3 separate loops at X = 10, 50, 30
    loop1 = new Polygon2D [new Point2D(10, 0), new Point2D(12, 0), new Point2D(10, 2)]
    loop2 = new Polygon2D [new Point2D(50, 0), new Point2D(52, 0), new Point2D(50, 2)]
    loop3 = new Polygon2D [new Point2D(30, 0), new Point2D(32, 0), new Point2D(30, 2)]

    # Input in zigzag order: 10 -> 50 -> 30 (travel = 40 + 20 = 60)
    shuffled = [loop1, loop2, loop3]
    optimized = TravelOptimizer.optimize-loop-order shuffled, new Point2D(0, 0)

    # Optimal order starting at (0, 0) is 10 -> 30 -> 50 (travel = 10 + 20 + 20 = 50)
    assert.strictEqual optimized[0].points[0].x, 10
    assert.strictEqual optimized[1].points[0].x, 30
    assert.strictEqual optimized[2].points[0].x, 50

describe "Comb Router Internal Travel", ->
  test-case "avoids crossing boundary and routes through safe interior", ->
    # U-shaped or convex square island
    square = new Polygon2D [
      new Point2D 0, 0
      new Point2D 20, 0
      new Point2D 20, 20
      new Point2D 0, 20
    ]
    island = new IslandNode square

    # Travel inside square: direct path
    route = CombRouter.route-travel (new Point2D 2, 2), (new Point2D 18, 18), island
    assert.strictEqual route.length, 1
