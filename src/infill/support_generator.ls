# Overhang Detection and Sacrificial Support Toolpath Generator
# Identifies steep downward faces and generates breakaway support grids

Vector3 = require '../math/vector3'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'
Polygon2D = require '../geometry2d/polygon2d'

class SupportGenerator
  (mesh, opts = {}) ->
    @mesh = mesh
    @overhang-angle-deg = opts.overhang-angle-deg or 45.0
    @support-spacing = opts.support-spacing or 2.5
    @z-gap = opts.z-gap or 0.2 # Vertical breakaway clearance

    # Critical normal Z threshold: overhang if nz < -sin(90 - angle)
    rad = @overhang-angle-deg * (Math.PI / 180.0)
    @critical-cos = Math.cos(Math.PI * 0.5 - rad)

  find-overhang-triangles: ->
    overhangs = []
    for tri in @mesh.triangles
      # Triangle faces downwards: normal.z < 0
      if tri.normal.z < -1e-4
        tilt = -tri.normal.z
        if tilt < @critical-cos
          overhangs.push tri
    overhangs

  generate-support-for-layer: (z) ->
    # Generates support toolpaths at height z if any overhang triangle is directly above z + z_gap
    overhangs = @find-overhang-triangles!
    if overhangs.length == 0
      return []

    target-z = z + @z-gap
    support-segments = []

    for tri in overhangs
      # If overhang triangle extends above target-z
      max-tri-z = Math.max tri.v0.z, tri.v1.z, tri.v2.z
      min-tri-z = Math.min tri.v0.z, tri.v1.z, tri.v2.z

      if target-z >= min-tri-z and target-z <= max-tri-z
        # Generate 2D projection footprint of triangle
        p0 = new Point2D tri.v0.x, tri.v0.y
        p1 = new Point2D tri.v1.x, tri.v1.y
        p2 = new Point2D tri.v2.x, tri.v2.y
        support-segments.push new Segment2D p0, p1
        support-segments.push new Segment2D p1, p2
        support-segments.push new Segment2D p2, p0

    support-segments

module.exports = SupportGenerator
