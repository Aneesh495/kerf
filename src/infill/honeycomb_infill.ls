# Hexagonal Honeycomb Infill Generator
# Generates continuous hexagonal cell tessellations with optimal strength-to-weight ratio

InfillBase = require './infill_base'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'

class HoneycombInfill extends InfillBase
  (opts = {}) ->
    super opts

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    bounds = island.contour.get-bounds!
    cell-radius = @line-spacing * 1.2
    dx = cell-radius * 1.5
    dy = cell-radius * Math.sqrt(3.0)

    raw-segments = []
    added-edge-keys = new Set!

    add-unique-segment = (p1, p2) ->
      k1 = "#{p1.x.toFixed 3},#{p1.y.toFixed 3}"
      k2 = "#{p2.x.toFixed 3},#{p2.y.toFixed 3}"
      key = if k1 < k2 then "#k1|#k2" else "#k2|#k1"
      if not added-edge-keys.has key
        added-edge-keys.add key
        raw-segments.push new Segment2D p1, p2

    min-x = bounds.min-x - cell-radius
    max-x = bounds.max-x + cell-radius
    min-y = bounds.min-y - cell-radius
    max-y = bounds.max-y + cell-radius

    col = 0
    x = min-x
    while x <= max-x
      y-offset = if (col % 2) == 1 then (dy * 0.5) else 0.0
      y = min-y + y-offset
      while y <= max-y
        # Generate 6 vertices of hexagon centered at (x, y)
        hex-pts = []
        for i from 0 til 6
          theta = (i / 6.0) * Math.PI * 2.0
          px = x + Math.cos(theta) * cell-radius
          py = y + Math.sin(theta) * cell-radius
          hex-pts.push new Point2D px, py

        for i from 0 til 6
          j = (i + 1) % 6
          add-unique-segment hex-pts[i], hex-pts[j]

        y += dy
      x += dx
      col += 1

    @clip-to-island raw-segments, island

module.exports = HoneycombInfill
