# Unit tests for G-code serialization, parsing, and virtual machine simulation

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Point2D = require '../src/geometry2d/point2d'
Polygon2D = require '../src/geometry2d/polygon2d'
Segment2D = require '../src/geometry2d/segment2d'
SliceLayer = require '../src/slicing/slice_layer'
{ GcodeFlavor, GcodeEmitter } = require '../src/gcode/gcode_emitter'
{ GcodeParser } = require '../src/gcode/gcode_parser'
GcodeInterpreter = require '../src/gcode/gcode_interpreter'

describe "G-code Emitter", ->
  test-case "emits compliant RS274 G-code with headers and perimeter extrusion", ->
    emitter = new GcodeEmitter { flavor: GcodeFlavor.MARLIN, bed-temp: 60, hotend-temp: 215 }

    # Create dummy layer
    layer = new SliceLayer 0, 0.2, 0.2
    square = new Polygon2D [
      new Point2D 10, 10
      new Point2D 30, 10
      new Point2D 30, 30
      new Point2D 10, 30
    ]
    layer.perimeters.push square
    layer.infill-paths.push new Segment2D(new Point2D(12, 12), new Point2D(28, 28))

    gcode-text = emitter.generate-gcode [layer]
    assert.ok gcode-text.includes "M140 S60"
    assert.ok gcode-text.includes "M104 S215"
    assert.ok gcode-text.includes "G1 Z0.200"
    assert.ok gcode-text.includes "G1 X30.000 Y10.000 E"
    assert.ok gcode-text.includes "M104 S0" # Cool down footer

describe "G-code Parser and Tokenizer", ->
  test-case "parses modal commands, parameters, and comments accurately", ->
    line1 = "G1 X12.500 Y34.800 E0.0452 F3000 ; Perimeter wall"
    cmd1 = GcodeParser.parse-line line1
    assert.strictEqual cmd1.cmd, "G1"
    assert-approx cmd1.get('X'), 12.5
    assert-approx cmd1.get('Y'), 34.8
    assert-approx cmd1.get('E'), 0.0452
    assert-approx cmd1.get('F'), 3000.0
    assert.strictEqual cmd1.comment, "Perimeter wall"

describe "G-code Virtual Machine Simulation", ->
  test-case "tracks nozzle position, filament consumption, and print execution time", ->
    vm = new GcodeInterpreter!
    script = [
      "G90"
      "M83"
      "G1 X0 Y0 Z0.2 F3000"
      "G1 X100 Y0 E10.0 F6000" # 100mm move, 10mm filament, feedrate 100mm/s -> takes 1.0s
      "G1 X100 Y100 E10.0 F6000" # 100mm move, 10mm filament, takes 1.0s
    ].join "\n"

    metrics = vm.interpret-text script
    assert-approx metrics.total-filament-mm, 20.0, 1e-4
    assert.ok metrics.filament-mass-grams > 0.0
    assert-approx metrics.total-time-sec, 2.0, 1e-2
    assert.strictEqual vm.pos.x, 100.0
    assert.strictEqual vm.pos.y, 100.0
    assert.strictEqual vm.pos.z, 0.2
