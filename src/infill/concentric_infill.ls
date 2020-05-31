# Concentric Recursive Inset Infill Generator
# Generates concentric nested perimeter offsets for rotational and pipe structures

InfillBase = require './infill_base'
PolygonOffset = require '../geometry2d/polygon_offset'
Segment2D = require '../geometry2d/segment2d'

class ConcentricInfill extends InfillBase
  (opts = {}) ->
    super opts

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    segments = []
    curr = island.contour.clone!
    step = @line-spacing

    max-iterations = 500
    iter = 0

    while iter < max-iterations
      iter += 1
      inner = PolygonOffset.inset curr, step
      if not inner? or inner.area! < 1e-4
        break

      # Convert inner polygon edges into segments
      pts = inner.points
      n = pts.length
      for i from 0 til n
        j = (i + 1) % n
        segments.push new Segment2D pts[i], pts[j]

      curr = inner

    @clip-to-island segments, island

module.exports = ConcentricInfill
