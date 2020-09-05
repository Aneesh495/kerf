# End-to-end integration test suite for the unified KerfEngine pipeline

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
{ KerfEngine, MeshPrimitives } = require '../src/index'

describe "KerfEngine Pipeline Integration", ->
  test-case "executes full pipeline on calibration cube with gyroid infill", ->
    cube = MeshPrimitives.create-box 10.0, 10.0, 5.0 # 5mm height
    engine = new KerfEngine {
      layer-height: 0.5
      first-layer-height: 0.5
      infill-density: 0.20
      infill-pattern: 'gyroid'
      perimeters: 2
    }

    result = engine.slice-mesh cube
    assert.strictEqual result.layer-count, 9
    assert.ok result.gcode.length > 500
    assert.ok result.gcode.includes "M140 S60"
    assert.ok result.gcode.includes "; LAYER:0"
    assert.ok result.metrics.total-filament-mm > 0
    assert.ok result.metrics.total-time-sec > 0

  test-case "executes pipeline on mechanical gear with honeycomb infill", ->
    gear = MeshPrimitives.create-gear 8, 10.0, 2.0, 3.0
    engine = new KerfEngine {
      layer-height: 0.5
      infill-density: 0.20
      infill-pattern: 'honeycomb'
      perimeters: 2
    }

    result = engine.slice-mesh gear
    assert.ok result.layer-count > 0
    assert.ok result.gcode.includes "; End of Print Procedure"
    assert.ok result.metrics.total-time-sec > 0

  test-case "executes adaptive layer height slicing on procedural sphere", ->
    sphere = MeshPrimitives.create-sphere 8.0, 12, 12
    engine = new KerfEngine {
      adaptive: true
      min-layer-height: 0.1
      max-layer-height: 0.4
      infill-density: 0.15
      infill-pattern: 'rectilinear'
    }

    result = engine.slice-mesh sphere
    assert.ok result.layer-count > 0
    assert.ok result.metrics.total-time-sec > 0
