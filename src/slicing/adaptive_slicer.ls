# Adaptive Layer Height Slicing Engine
# Computes local surface curvature to vary slice thickness between Z_min and Z_max

Slicer = require './slicer'

class AdaptiveSlicer extends Slicer
  (mesh, opts = {}) ->
    super mesh, opts
    @min-thickness = opts.min-thickness or 0.08
    @max-thickness = opts.max-thickness or 0.28
    @target-cusp-height = opts.target-cusp-height or 0.02 # Maximum allowable staircase error (mm)

  compute-optimal-thickness-at-z: (z) ->
    # Queries triangles intersecting this elevation and evaluates their normal inclination
    triangles = @bvh.query-plane-z z
    if triangles.length == 0
      return @max-thickness

    # Find the most shallow surface slope (maximum |n_z| < 1.0)
    max-tilt-cos = 0.0
    for tri in triangles
      nz = Math.abs tri.normal.z
      # Ignore purely horizontal planes (nz = 1.0) which are flat caps
      if nz < 0.999 and nz > max-tilt-cos
        max-tilt-cos = nz

    if max-tilt-cos < 1e-4
      # Nearly vertical wall: can use maximum layer thickness
      return @max-thickness

    # Surface inclination angle with vertical: tan(theta) = sqrt(1 - nz^2) / nz
    # Cusp error h = thickness * cos(theta) = thickness * nz
    # Optimal thickness = target_cusp_height / nz
    optimal = @target-cusp-height / max-tilt-cos
    Math.max @min-thickness, Math.min @max-thickness, optimal

  generate-layer-heights: ->
    bounds = @mesh.get-bounds!
    min-z = bounds.min.z
    max-z = bounds.max.z

    if max-z <= min-z
      return []

    heights = []
    current-z = min-z
    idx = 0

    while current-z < max-z
      thick = if idx == 0
        @first-layer-height
      else
        @compute-optimal-thickness-at-z current-z

      current-z += thick
      if current-z > max-z
        break

      heights.push {
        index: idx
        z: current-z
        thickness: thick
      }
      idx += 1

    heights

module.exports = AdaptiveSlicer
