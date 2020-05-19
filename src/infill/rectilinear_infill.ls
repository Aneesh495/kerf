# Rectilinear and Monotonic Scanline Infill Generator
# Generates alternating angle parallel infill lines with boundary turnaround chaining

InfillBase = require './infill_base'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'

class RectilinearInfill extends InfillBase
  (opts = {}) ->
    super opts
    @alternate-angle = if opts.alternate-angle? then opts.alternate-angle else true

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    bounds = island.contour.get-bounds!
    diag = Math.sqrt(
      (bounds.max-x - bounds.min-x) * (bounds.max-x - bounds.min-x) +
      (bounds.max-y - bounds.min-y) * (bounds.max-y - bounds.min-y)
    )

    c = island.contour.centroid!
    theta = @angle
    if @alternate-angle and (layer-index % 2) == 1
      theta += (Math.PI * 0.5)

    cos-t = Math.cos theta
    sin-t = Math.sin theta

    # Scanline direction unit vector and perpendicular normal
    dir = new Point2D cos-t, sin-t
    norm = new Point2D (-sin-t), cos-t

    raw-lines = []
    half-span = diag * 0.6
    step = @line-spacing

    d = -half-span
    while d <= half-span
      # Center of scanline
      center-pt = c.add norm.multiply-scalar(d)
      p1 = center-pt.sub dir.multiply-scalar(half-span)
      p2 = center-pt.add dir.multiply-scalar(half-span)
      raw-lines.push new Segment2D p1, p2
      d += step

    clipped = @clip-to-island raw-lines, island

    # Chain adjacent lines monotonically: alternate direction of consecutive segments
    chained = []
    for seg, idx in clipped
      if (idx % 2) == 1
        chained.push new Segment2D seg.p2, seg.p1
      else
        chained.push seg

    chained

module.exports = RectilinearInfill
