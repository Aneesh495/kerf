# Kerf - Unified 3D Digital Fabrication & Slicing Engine API
# High-level pipeline facade and subsystem module exports

# Math
Vector3 = require './math/vector3'
Matrix4 = require './math/matrix4'
Plane3D = require './math/plane3d'
AABB3D = require './math/aabb3d'
Quaternion = require './math/quaternion'
Units = require './math/units'

# Mesh
{ Mesh, Triangle } = require './mesh/mesh'
STLParser = require './mesh/stl_parser'
STLWriter = require './mesh/stl_writer'
OBJParser = require './mesh/obj_parser'
OBJWriter = require './mesh/obj_writer'
MeshRepair = require './mesh/mesh_repair'
MeshPrimitives = require './mesh/mesh_primitives'

# Spatial
BVH3D = require './spatial/bvh3d'
{ SpatialHash2D, SpatialHash3D } = require './spatial/spatial_hash'
Octree = require './spatial/octree'

# Slicing
Slicer = require './slicing/slicer'
AdaptiveSlicer = require './slicing/adaptive_slicer'
ContourStitcher = require './slicing/contour_stitcher'
{ TopologyTree, IslandNode } = require './slicing/topology_tree'
SliceLayer = require './slicing/slice_layer'

# 2D Geometry
Point2D = require './geometry2d/point2d'
Segment2D = require './geometry2d/segment2d'
Polygon2D = require './geometry2d/polygon2d'
PolygonOffset = require './geometry2d/polygon_offset'
PolygonClipper = require './geometry2d/polygon_clipper'

# Infill
RectilinearInfill = require './infill/rectilinear_infill'
GridInfill = require './infill/grid_infill'
ConcentricInfill = require './infill/concentric_infill'
HoneycombInfill = require './infill/honeycomb_infill'
HilbertInfill = require './infill/hilbert_infill'
GyroidInfill = require './infill/gyroid_infill'
SupportGenerator = require './infill/support_generator'

# Toolpath
{ ToolpathType, ToolpathSegment } = require './toolpath/toolpath_segment'
{ SeamPlacement, SeamPlanner } = require './toolpath/seam_planner'
TravelOptimizer = require './toolpath/travel_optimizer'
CombRouter = require './toolpath/comb_router'

# Motion
KinematicsLimits = require './motion/kinematics_limits'
JunctionDeviation = require './motion/junction_deviation'
{ TrapezoidPlanner, MotionBlock } = require './motion/trapezoid_planner'
SCurvePlanner = require './motion/scurve_planner'
PressureAdvance = require './motion/pressure_advance'

# G-code
{ GcodeFlavor, GcodeEmitter } = require './gcode/gcode_emitter'
{ GcodeParser, GcodeCommand } = require './gcode/gcode_parser'
GcodeInterpreter = require './gcode/gcode_interpreter'

# Visualization
AsciiArt = require './vis/ascii_art'
TerminalRenderer = require './vis/terminal_renderer'
SVGExporter = require './vis/svg_exporter'

class KerfEngine
  (opts = {}) ->
    @opts = opts
    @layer-height = opts.layer-height or 0.2
    @first-layer-height = opts.first-layer-height or @layer-height
    @perimeters-count = opts.perimeters or 2
    @infill-density = if opts.infill-density? then opts.infill-density else 0.20
    @infill-pattern = opts.infill-pattern or 'rectilinear'
    @extrusion-width = opts.extrusion-width or 0.45
    @seam-strategy = opts.seam or SeamPlacement.CONVEX_CORNER
    @flavor = opts.flavor or GcodeFlavor.MARLIN
    @adaptive = if opts.adaptive? then opts.adaptive else false

    @limits = new KinematicsLimits opts.limits or {}
    @emitter = new GcodeEmitter {
      flavor: @flavor
      bed-temp: opts.bed-temp or 60
      hotend-temp: opts.hotend-temp or 210
    }
    @interpreter = new GcodeInterpreter!

  _create-infill-generator: ->
    cfg = {
      density: @infill-density
      extrusion-width: @extrusion-width
    }
    switch @infill-pattern.to-lower-case!
    case 'gyroid'
      new GyroidInfill cfg
    case 'grid'
      new GridInfill cfg
    case 'concentric'
      new ConcentricInfill cfg
    case 'honeycomb'
      new HoneycombInfill cfg
    case 'hilbert'
      new HilbertInfill cfg
    default
      new RectilinearInfill cfg

  slice-mesh: (mesh) ->
    # Step 1: Repair mesh manifold defects
    repair-report = MeshRepair.repair-pipeline mesh
    working-mesh = repair-report.mesh

    # Step 2: Slice mesh into layers
    slicer = if @adaptive
      new AdaptiveSlicer working-mesh, {
        min-thickness: @opts.min-layer-height or 0.08
        max-thickness: @opts.max-layer-height or 0.28
        target-cusp-height: @opts.target-cusp-height or 0.02
      }
    else
      new Slicer working-mesh, {
        layer-height: @layer-height
        first-layer-height: @first-layer-height
      }

    layers = slicer.slice-all!
    infill-gen = @_create-infill-generator!

    # Step 3: Process perimeters, infill, and seam optimization per layer
    tool-radius = @extrusion-width * 0.5
    for layer in layers
      for island in layer.islands
        # A: Generate concentric perimeters
        shells = PolygonOffset.generate-concentric-perimeters island.contour, tool-radius, @perimeters-count
        for shell in shells
          # Reorder perimeter start to smart seam corner
          reordered-shell = SeamPlanner.reorder-polygon-at-seam shell, @seam-strategy
          layer.perimeters.push reordered-shell

        # B: Generate infill paths within solid island core
        if @infill-density > 0
          infill-paths = infill-gen.generate-for-island island, layer.z, layer.layer-index
          for p in infill-paths
            layer.infill-paths.push p

    # Step 4: Emit optimized G-code
    gcode-text = @emitter.generate-gcode layers

    # Step 5: Virtual machine kinematic verification
    simulation-metrics = @interpreter.reset!.interpret-text gcode-text

    {
      layers
      layer-count: layers.length
      gcode: gcode-text
      metrics: simulation-metrics
      repair: repair-report
    }

module.exports = {
  # Core facade
  KerfEngine

  # Math
  Vector3
  Matrix4
  Plane3D
  AABB3D
  Quaternion
  Units

  # Mesh
  Mesh
  Triangle
  STLParser
  STLWriter
  OBJParser
  OBJWriter
  MeshRepair
  MeshPrimitives

  # Spatial
  BVH3D
  SpatialHash2D
  SpatialHash3D
  Octree

  # Slicing
  Slicer
  AdaptiveSlicer
  ContourStitcher
  TopologyTree
  IslandNode
  SliceLayer

  # 2D Geometry
  Point2D
  Segment2D
  Polygon2D
  PolygonOffset
  PolygonClipper

  # Infill
  RectilinearInfill
  GridInfill
  ConcentricInfill
  HoneycombInfill
  HilbertInfill
  GyroidInfill
  SupportGenerator

  # Toolpath
  ToolpathType
  ToolpathSegment
  SeamPlacement
  SeamPlanner
  TravelOptimizer
  CombRouter

  # Motion
  KinematicsLimits
  JunctionDeviation
  TrapezoidPlanner
  MotionBlock
  SCurvePlanner
  PressureAdvance

  # G-code
  GcodeFlavor
  GcodeEmitter
  GcodeParser
  GcodeCommand
  GcodeInterpreter

  # Visualization
  AsciiArt
  TerminalRenderer
  SVGExporter
}
