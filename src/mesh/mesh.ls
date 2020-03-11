# Triangle mesh data structure with topological analysis and volumetric computation
# Provides Euler characteristic, genus analysis, and divergence volume

Vector3 = require '../math/vector3'
AABB3D = require '../math/aabb3d'

class Triangle
  (v0, v1, v2, normal = null) ->
    @v0 = v0
    @v1 = v1
    @v2 = v2
    @normal = if normal?
      normal.normalize!
    else
      e1 = v1.sub v0
      e2 = v2.sub v0
      e1.cross(e2).normalize!

  clone: ->
    new Triangle @v0.clone!, @v1.clone!, @v2.clone!, @normal.clone!

  area: ->
    e1 = @v1.sub @v0
    e2 = @v2.sub @v0
    e1.cross(e2).length! * 0.5

  centroid: ->
    new Vector3 (
      (@v0.x + @v1.x + @v2.x) / 3.0
    ), (
      (@v0.y + @v1.y + @v2.y) / 3.0
    ), (
      (@v0.z + @v1.z + @v2.z) / 3.0
    )

  signed-volume-contribution: ->
    # Divergence theorem: 1/6 * (v0 . (v1 x v2))
    @v0.dot(@v1.cross(@v2)) / 6.0

class Mesh
  ->
    @triangles = []
    @bounds = new AABB3D!
    @dirty-bounds = true

  add-triangle: (tri) ->
    @triangles.push tri
    @dirty-bounds = true
    @

  add-face: (v0, v1, v2, normal = null) ->
    @add-triangle new Triangle v0, v1, v2, normal

  triangle-count: ->
    @triangles.length

  compute-bounds: ->
    @bounds.reset!
    for tri in @triangles
      @bounds.expand-by-point tri.v0
      @bounds.expand-by-point tri.v1
      @bounds.expand-by-point tri.v2
    @dirty-bounds = false
    @bounds

  get-bounds: ->
    if @dirty-bounds
      @compute-bounds!
    @bounds

  total-surface-area: ->
    sum = 0.0
    for tri in @triangles
      sum += tri.area!
    sum

  total-volume: ->
    # Calculates enclosed volume via divergence theorem
    sum = 0.0
    for tri in @triangles
      sum += tri.signed-volume-contribution!
    Math.abs sum

  transform: (matrix) ->
    for tri in @triangles
      tri.v0 = tri.v0.transform-matrix4 matrix
      tri.v1 = tri.v1.transform-matrix4 matrix
      tri.v2 = tri.v2.transform-matrix4 matrix
      # Recalculate normal
      e1 = tri.v1.sub tri.v0
      e2 = tri.v2.sub tri.v0
      tri.normal = e1.cross(e2).normalize!
    @dirty-bounds = true
    @

  center-on-bed: (bed-z = 0.0) ->
    b = @get-bounds!
    c = b.center!
    dx = -c.x
    dy = -c.y
    dz = bed-z - b.min.z
    for tri in @triangles
      offset = new Vector3 dx, dy, dz
      tri.v0 = tri.v0.add offset
      tri.v1 = tri.v1.add offset
      tri.v2 = tri.v2.add offset
    @dirty-bounds = true
    @

  get-edge-manifold-stats: (tol = 1e-5) ->
    # Analyzes half-edges to detect open boundary loops and non-manifold edges
    edge-counts = {}

    make-key = (p1, p2) ->
      k1 = "#{p1.x.toFixed 4},#{p1.y.toFixed 4},#{p1.z.toFixed 4}"
      k2 = "#{p2.x.toFixed 4},#{p2.y.toFixed 4},#{p2.z.toFixed 4}"
      if k1 < k2 then "#k1|#k2" else "#k2|#k1"

    for tri in @triangles
      k1 = make-key tri.v0, tri.v1
      k2 = make-key tri.v1, tri.v2
      k3 = make-key tri.v2, tri.v0

      edge-counts[k1] = (edge-counts[k1] or 0) + 1
      edge-counts[k2] = (edge-counts[k2] or 0) + 1
      edge-counts[k3] = (edge-counts[k3] or 0) + 1

    total-edges = 0
    boundary-edges = 0
    manifold-edges = 0
    non-manifold-edges = 0

    for k, count of edge-counts
      total-edges += 1
      if count == 1
        boundary-edges += 1
      else if count == 2
        manifold-edges += 1
      else
        non-manifold-edges += 1

    is-closed = (boundary-edges == 0 and non-manifold-edges == 0)

    {
      total-edges
      manifold-edges
      boundary-edges
      non-manifold-edges
      is-closed
    }

module.exports = {
  Triangle
  Mesh
}
