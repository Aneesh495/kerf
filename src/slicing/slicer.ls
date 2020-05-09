# Core 3D Mesh Slicing Engine
# Slices triangles via plane intersection, stitches contours, and builds layer topologies

Vector3 = require '../math/vector3'
Plane3D = require '../math/plane3d'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'
BVH3D = require '../spatial/bvh3d'
ContourStitcher = require './contour_stitcher'
{ TopologyTree } = require './topology_tree'
SliceLayer = require './slice_layer'

class Slicer
  (mesh, opts = {}) ->
    @mesh = mesh
    @layer-height = opts.layer-height or 0.2
    @first-layer-height = opts.first-layer-height or @layer-height
    @stitch-tolerance = opts.stitch-tolerance or 1e-4

    # Build BVH acceleration structure
    @bvh = new BVH3D!
    @bvh.build @mesh.triangles

  generate-layer-heights: ->
    bounds = @mesh.get-bounds!
    min-z = bounds.min.z
    max-z = bounds.max.z

    if max-z <= min-z
      return []

    heights = []
    current-z = min-z + @first-layer-height
    # In 3D printing, slicing planes are placed at the middle or top of each layer
    # Placing slice plane at current-z - 0.5 * thickness
    idx = 0
    while current-z < max-z
      heights.push {
        index: idx
        z: current-z
        thickness: (if idx == 0 then @first-layer-height else @layer-height)
      }
      current-z += @layer-height
      idx += 1

    heights

  slice-at-z: (z, thickness = 0.2, index = 0) ->
    plane = new Plane3D Vector3.UNIT_Z, (-z)
    candidate-triangles = @bvh.query-plane-z z

    raw-segments = []
    for tri in candidate-triangles
      seg = plane.intersect-triangle tri.v0, tri.v1, tri.v2
      if seg?
        # Project 3D segment to 2D
        p1-xy = new Point2D seg[0].x, seg[0].y
        p2-xy = new Point2D seg[1].x, seg[1].y
        if p1-xy.distance-to-sq(p2-xy) > 1e-10
          raw-segments.push new Segment2D p1-xy, p2-xy

    # Stitch segments into closed 2D loops
    loops = ContourStitcher.stitch raw-segments, @stitch-tolerance

    # Build topological hierarchy (islands and holes)
    islands = TopologyTree.build loops

    layer = new SliceLayer index, z, thickness
    for island in islands
      layer.add-island island

    layer

  slice-all: ->
    layer-specs = @generate-layer-heights!
    layers = []
    for spec in layer-specs
      layers.push @slice-at-z spec.z, spec.thickness, spec.index
    layers

module.exports = Slicer
