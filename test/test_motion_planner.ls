# Unit tests for motion planning: junction deviation, trapezoidal profiler, S-curve, and pressure advance

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Point2D = require '../src/geometry2d/point2d'
{ ToolpathType, ToolpathSegment } = require '../src/toolpath/toolpath_segment'
KinematicsLimits = require '../src/motion/kinematics_limits'
JunctionDeviation = require '../src/motion/junction_deviation'
{ TrapezoidPlanner } = require '../src/motion/trapezoid_planner'
SCurvePlanner = require '../src/motion/scurve_planner'
PressureAdvance = require '../src/motion/pressure_advance'

describe "Kinematics Limits and Feedrate Limiting", ->
  test-case "calculates maximum linear feedrate based on volumetric hotend limit", ->
    limits = new KinematicsLimits {
      max-velocity: 300.0
      max-acceleration: 3000.0
      max-volumetric: 15.0 # 15 mm^3/sec
    }
    # Layer height 0.2 mm, extrusion width 0.5 mm -> cross section = 0.1 mm^2
    # Max speed = 15.0 / 0.1 = 150.0 mm/sec
    max-speed = limits.calculate-max-linear-feedrate 0.2, 0.5
    assert-approx max-speed, 150.0, 1e-4

describe "Junction Deviation Cornering Velocity", ->
  test-case "decelerates on sharp turns and maintains speed on collinear paths", ->
    limits = new KinematicsLimits!
    v-collinear = JunctionDeviation.calculate-corner-speed (new Point2D 1, 0), (new Point2D 1, 0), 3000.0, 0.04
    assert.strictEqual v-collinear, Infinity

    v-reversal = JunctionDeviation.calculate-corner-speed (new Point2D 1, 0), (new Point2D -1, 0), 3000.0, 0.04
    assert.strictEqual v-reversal, 0.0

    v-right-angle = JunctionDeviation.calculate-corner-speed (new Point2D 1, 0), (new Point2D 0, 1), 3000.0, 0.04
    assert.ok v-right-angle > 0 and v-right-angle < 300.0

describe "Trapezoidal Motion Planner", ->
  test-case "executes forward-backward pass and computes realistic motion duration", ->
    limits = new KinematicsLimits {
      max-velocity: 100.0
      max-acceleration: 2000.0
      junction-dev: 0.04
    }

    # 3 collinear segments forming a 100mm straight move (feedrate 6000 mm/min = 100 mm/s)
    s1 = new ToolpathSegment (new Point2D 0, 0), (new Point2D 30, 0), ToolpathType.INFILL, { feedrate: 6000.0 }
    s2 = new ToolpathSegment (new Point2D 30, 0), (new Point2D 70, 0), ToolpathType.INFILL, { feedrate: 6000.0 }
    s3 = new ToolpathSegment (new Point2D 70, 0), (new Point2D 100, 0), ToolpathType.INFILL, { feedrate: 6000.0 }

    blocks = TrapezoidPlanner.plan-blocks [s1, s2, s3], limits
    assert.strictEqual blocks.length, 3
    # Starts from stop
    assert.strictEqual blocks[0].entry-speed, 0.0
    # Finishes at stop
    assert-approx blocks[2].exit-speed, 0.0, 1e-4

    total-time = 0.0
    for b in blocks
      total-time += b.duration
    assert.ok total-time > 0.0

describe "S-Curve Jerk Profiler and Pressure Advance", ->
  test-case "computes 7-segment S-curve profile duration", ->
    res = SCurvePlanner.compute-profile 50.0, 0.0, 0.0, 100.0, 2000.0, 40000.0
    assert.ok res.total-time > 0.0

  test-case "calculates viscoelastic pressure advance filament volume", ->
    pa = new PressureAdvance 0.04
    adv = pa.calculate-advance-volume 100.0, 2000.0
    assert-approx adv, 4.0, 1e-4
