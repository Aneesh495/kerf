# 3D Triply Periodic Minimal Surface (TPMS) Gyroid Infill Generator
# Evaluates sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0 via 2D Marching Squares

InfillBase = require './infill_base'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'

class GyroidInfill extends InfillBase
  (opts = {}) ->
    super opts
    @cell-size = opts.cell-size or (@line-spacing * 2.5)

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    bounds = island.contour.get-bounds!
    k = (Math.PI * 2.0) / @cell-size
    kz = k * z
    sin-kz = Math.sin kz
    cos-kz = Math.cos kz

    # 2D scalar field evaluation: F(x, y) = sin(k*x)*cos(k*y) + sin(k*y)*cos(k*z) + sin(k*z)*cos(k*x)
    eval-field = (x, y) ->
      kx = k * x
      ky = k * y
      Math.sin(kx) * Math.cos(ky) + Math.sin(ky) * cos-kz + sin-kz * Math.cos(kx)

    # Marching squares grid spacing
    grid-step = @cell-size / 12.0
    min-x = bounds.min-x - grid-step
    max-x = bounds.max-x + grid-step
    min-y = bounds.min-y - grid-step
    max-y = bounds.max-y + grid-step

    cols = Math.ceil((max-x - min-x) / grid-step) + 1
    rows = Math.ceil((max-y - min-y) / grid-step) + 1

    # Pre-evaluate grid values
    field = new Float64Array(cols * rows)
    for r from 0 til rows
      gy = min-y + r * grid-step
      for c from 0 til cols
        gx = min-x + c * grid-step
        field[r * cols + c] = eval-field gx, gy

    raw-segments = []

    # Linear interpolation along cell edge
    lerp-pt = (pA, pB, valA, valB) ->
      diff = valB - valA
      t = if Math.abs(diff) < 1e-12 then 0.5 else -valA / diff
      t = Math.max 0.0, Math.min 1.0, t
      pA.lerp pB, t

    # Marching squares cell iteration
    for r from 0 til (rows - 1)
      y0 = min-y + r * grid-step
      y1 = y0 + grid-step

      for c from 0 til (cols - 1)
        x0 = min-x + c * grid-step
        x1 = x0 + grid-step

        # 4 corners: bottom-left, bottom-right, top-right, top-left
        v00 = field[r * cols + c]
        v10 = field[r * cols + (c + 1)]
        v11 = field[(r + 1) * cols + (c + 1)]
        v01 = field[(r + 1) * cols + c]

        # Bitmask of corners > 0
        mask = 0
        if v00 > 0 then mask = mask .|. 1
        if v10 > 0 then mask = mask .|. 2
        if v11 > 0 then mask = mask .|. 4
        if v01 > 0 then mask = mask .|. 8

        # If all positive or all negative, no contour passes through cell
        if mask == 0 or mask == 15
          continue

        p00 = new Point2D x0, y0
        p10 = new Point2D x1, y0
        p11 = new Point2D x1, y1
        p01 = new Point2D x0, y1

        # Interpolated edge points: bottom, right, top, left
        p-bot = lerp-pt p00, p10, v00, v10
        p-right = lerp-pt p10, p11, v10, v11
        p-top = lerp-pt p01, p11, v01, v11
        p-left = lerp-pt p00, p01, v00, v01

        # Standard 16-case Marching Squares lookup
        switch mask
        case 1, 14
          raw-segments.push new Segment2D p-left, p-bot
        case 2, 13
          raw-segments.push new Segment2D p-bot, p-right
        case 3, 12
          raw-segments.push new Segment2D p-left, p-right
        case 4, 11
          raw-segments.push new Segment2D p-right, p-top
        case 5
          # Saddle point
          raw-segments.push new Segment2D p-left, p-top
          raw-segments.push new Segment2D p-bot, p-right
        case 6, 9
          raw-segments.push new Segment2D p-bot, p-top
        case 7, 8
          raw-segments.push new Segment2D p-left, p-top
        case 10
          # Saddle point
          raw-segments.push new Segment2D p-left, p-bot
          raw-segments.push new Segment2D p-top, p-right

    @clip-to-island raw-segments, island

module.exports = GyroidInfill
