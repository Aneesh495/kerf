# Hilbert Space-Filling Curve Infill Generator
# Generates continuous recursive fractal paths for isotropic in-plane strength

InfillBase = require './infill_base'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'

class HilbertInfill extends InfillBase
  (opts = {}) ->
    super opts

  _hilbert-points: (order) ->
    # Generates 2D Hilbert curve points in [0, 1] x [0, 1] unit square
    pts = []

    rot = (n, x, y, rx, ry) ->
      if ry == 0
        if rx == 1
          x = n - 1 - x
          y = n - 1 - y
        return [y, x]
      [x, y]

    n = Math.pow 2, order
    total-pts = n * n

    for d from 0 til total-pts
      t = d
      x = 0
      y = 0
      s = 1
      while s < n
        rx = 1 .&. Math.floor(t / 2)
        ry = 1 .&. (t .^. rx)
        r-xy = rot(s, x, y, rx, ry)
        x = r-xy[0]
        y = r-xy[1]
        x += s * rx
        y += s * ry
        t = Math.floor(t / 4)
        s = s * 2
      # Normalize to [0, 1]
      pts.push new Point2D (x / (n - 1)), (y / (n - 1))

    pts

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    bounds = island.contour.get-bounds!
    width = bounds.max-x - bounds.min-x
    height = bounds.max-y - bounds.min-y
    span = Math.max width, height

    # Choose Hilbert order based on line spacing
    # order 3 = 8x8, order 4 = 16x16, order 5 = 32x32
    raw-order = Math.round(Math.log2(span / @line-spacing))
    order = Math.max 2, Math.min 6, raw-order

    unit-pts = @_hilbert-points order
    raw-segments = []

    for i from 0 til (unit-pts.length - 1)
      pA = unit-pts[i]
      pB = unit-pts[i + 1]

      scaled-pA = new Point2D (bounds.min-x + pA.x * span), (bounds.min-y + pA.y * span)
      scaled-pB = new Point2D (bounds.min-x + pB.x * span), (bounds.min-y + pB.y * span)

      raw-segments.push new Segment2D scaled-pA, scaled-pB

    @clip-to-island raw-segments, island

module.exports = HilbertInfill
