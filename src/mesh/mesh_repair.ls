# Mesh Manifold Repair and Geometric Healing
# Eliminates degenerate triangles, welds micro-gap vertices, and unifies face orientations

Vector3 = require '../math/vector3'
{ Mesh, Triangle } = require './mesh'

class MeshRepair
  @prune-degenerate-triangles = (mesh, min-area = 1e-8) ->
    repaired = new Mesh!
    pruned-count = 0
    for tri in mesh.triangles
      if tri.area! >= min-area
        repaired.add-triangle tri
      else
        pruned-count += 1
    { mesh: repaired, pruned-count }

  @weld-vertices = (mesh, tolerance = 1e-4) ->
    # Clusters vertices within spatial tolerance cells to close micro-gaps
    repaired = new Mesh!
    inv-tol = 1.0 / tolerance
    vert-lookup = {}

    get-welded-vertex = (v) ->
      gx = Math.round v.x * inv-tol
      gy = Math.round v.y * inv-tol
      gz = Math.round v.z * inv-tol
      key = "#gx,#gy,#gz"

      if vert-lookup[key]?
        vert-lookup[key]
      else
        vert-lookup[key] = v.clone!
        vert-lookup[key]

    welded-count = 0
    for tri in mesh.triangles
      w0 = get-welded-vertex tri.v0
      w1 = get-welded-vertex tri.v1
      w2 = get-welded-vertex tri.v2

      # Check if triangle collapsed to a point or line
      if w0.distance-to-sq(w1) > 1e-12 and
         w1.distance-to-sq(w2) > 1e-12 and
         w2.distance-to-sq(w0) > 1e-12
        repaired.add-face w0, w1, w2
      else
        welded-count += 1

    { mesh: repaired, collapsed-count: welded-count }

  @fix-face-orientations = (mesh) ->
    # Ensures normal vectors point consistently outward from enclosed volume
    # Computes signed volume via divergence theorem
    vol = 0.0
    for tri in mesh.triangles
      vol += tri.signed-volume-contribution!

    # If volume is negative, mesh winding is globally inverted
    if vol < 0
      repaired = new Mesh!
      for tri in mesh.triangles
        # Swap v1 and v2 to reverse winding
        repaired.add-face tri.v0, tri.v2, tri.v1
      return { mesh: repaired, reversed: true }

    { mesh, reversed: false }

  @repair-pipeline = (mesh, opts = {}) ->
    tol = opts.tolerance or 1e-4
    min-area = opts.min-area or 1e-8

    step1 = @prune-degenerate-triangles mesh, min-area
    step2 = @weld-vertices step1.mesh, tol
    step3 = @fix-face-orientations step2.mesh

    {
      mesh: step3.mesh
      pruned-degenerate: step1.pruned-count
      collapsed-edges: step2.collapsed-count
      reversed-orientation: step3.reversed
      stats: step3.mesh.get-edge-manifold-stats!
    }

module.exports = MeshRepair
