# Permanent Regression Test Suite for Bugs Discovered During Development
# Guarantees that identified syntax, parser, and mathematical bugs never reoccur

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Vector3 = require '../src/math/vector3'
Matrix4 = require '../src/math/matrix4'
SVGExporter = require '../src/vis/svg_exporter'
SliceLayer = require '../src/slicing/slice_layer'
{ TrapezoidPlanner } = require '../src/motion/trapezoid_planner'
KinematicsLimits = require '../src/motion/kinematics_limits'
ToolpathSegment = require '../src/toolpath/toolpath_segment'
Point2D = require '../src/geometry2d/point2d'

describe "Bug Regression 1: Matrix4 Multi-Line Determinant Arithmetic", ->
  test-case "evaluates exact non-zero determinant for rotated matrices", ->
    m = new Matrix4!
    m.make-rotation-z Math.PI * 0.25 # 45 degree rotation
    det = m.determinant!
    # Rotation matrix determinant must strictly equal 1.0
    assert-approx det, 1.0, 1e-6
    # Matrix must invert cleanly without throwing singular error
    inv = m.invert!
    assert.ok inv != null

describe "Bug Regression 2: SVG Exporter Hex Color String Interpolation", ->
  test-case "emits literal CSS hex colors without triggering variable interpolation", ->
    layer = new SliceLayer 1, 0.2, 0.2
    svg = SVGExporter.export-layer-to-svg layer
    assert.ok svg.includes('#121316')
    assert.ok svg.includes('#e0e0e0')
    assert.ok svg.includes('#00e5ff')
    assert.ok svg.includes('#ff9100')

describe "Bug Regression 3: Backward Pass Reverse Range Syntax", ->
  test-case "executes backward loop to index 0 without callee syntax error", ->
    limits = new KinematicsLimits!
    s1 = new ToolpathSegment.ToolpathSegment (new Point2D 0, 0), (new Point2D 10, 0), 'Infill', { feedrate: 3000.0 }
    s2 = new ToolpathSegment.ToolpathSegment (new Point2D 10, 0), (new Point2D 20, 0), 'Infill', { feedrate: 3000.0 }
    blocks = TrapezoidPlanner.plan-blocks [s1, s2], limits
    assert.strictEqual blocks.length, 2
    assert-approx blocks[0].entry-speed, 0.0, 1e-4
    assert-approx blocks[1].exit-speed, 0.0, 1e-4

describe "Bug Regression 4: LiveScript Native Bitwise Operators", ->
  test-case "evaluates native bitwise and, or, and xor operators correctly", ->
    a = 5
    b = 3
    bitwise-and = a .&. b
    bitwise-or = a .|. b
    bitwise-xor = a .^. b
    assert.strictEqual bitwise-and, 1
    assert.strictEqual bitwise-or, 7
    assert.strictEqual bitwise-xor, 6
