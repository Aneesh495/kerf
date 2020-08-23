# Unit tests for visualization subsystem: TerminalRenderer and SVGExporter

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Point2D = require '../src/geometry2d/point2d'
Polygon2D = require '../src/geometry2d/polygon2d'
Segment2D = require '../src/geometry2d/segment2d'
SliceLayer = require '../src/slicing/slice_layer'
{ IslandNode } = require '../src/slicing/topology_tree'
AsciiArt = require '../src/vis/ascii_art'
TerminalRenderer = require '../src/vis/terminal_renderer'
SVGExporter = require '../src/vis/svg_exporter'

describe "ASCII Art and Terminal Formatting", ->
  test-case "formats banners and structured statistical tables", ->
    assert.ok AsciiArt.BANNER.length > 20
    assert.ok AsciiArt.TAGLINE.includes("slicing")

    table = AsciiArt.format-table [
      ["Metric A", "100.0"]
      ["Long Metric Name", "Success"]
    ]
    assert.ok table.includes("Metric A")
    assert.ok table.includes("Long Metric Name")

describe "Terminal Slice Preview", ->
  test-case "renders ANSI 256-color layer slice to string buffer", ->
    layer = new SliceLayer 0, 0.2, 0.2
    square = new Polygon2D [
      new Point2D 0, 0
      new Point2D 10, 0
      new Point2D 10, 10
      new Point2D 0, 10
    ]
    island = new IslandNode square
    layer.add-island island
    layer.infill-paths.push new Segment2D(new Point2D(2, 2), new Point2D(8, 8))

    preview = TerminalRenderer.render-layer layer, 40, 20
    assert.ok preview.includes("Layer 0 Preview")
    assert.ok preview.includes("|") # Border characters

describe "SVG Vector Export", ->
  test-case "generates valid SVG XML string with perimeters and infill groups", ->
    layer = new SliceLayer 5, 1.0, 0.2
    square = new Polygon2D [
      new Point2D 0, 0
      new Point2D 20, 0
      new Point2D 20, 20
      new Point2D 0, 20
    ]
    island = new IslandNode square
    layer.add-island island
    layer.infill-paths.push new Segment2D(new Point2D(5, 5), new Point2D(15, 15))

    svg-text = SVGExporter.export-layer-to-svg layer
    assert.ok svg-text.starts-with("<svg")
    assert.ok svg-text.endsWith("</svg>")
    assert.ok svg-text.includes("id=\"outer-boundaries\"")
    assert.ok svg-text.includes("id=\"infill\"")
