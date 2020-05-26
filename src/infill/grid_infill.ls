# Orthogonal Two-Pass Grid Infill Generator
# Generates structural cross-hatching grids for high compressive loading

InfillBase = require './infill_base'
Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'

class GridInfill extends InfillBase
  (opts = {}) ->
    super opts

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    bounds = island.contour.get-bounds!
    diag = Math.sqrt(
      (bounds.max-x - bounds.min-x) * (bounds.max-x - bounds.min-x) +
      (bounds.max-y - bounds.min-y) * (bounds.max-y - bounds.min-y)
    )

    c = island.contour.centroid!
    half-span = diag * 0.6
    step = @line-spacing * 2.0 # Double spacing since grid prints both directions

    raw-lines = []

    # First pass: angle theta
    theta1 = @angle
    dir1 = new Point2D (Math.cos theta1), (Math.sin theta1)
    norm1 = new Point2D (-Math.sin theta1), (Math.cos theta1)

    d = -half-span
    while d <= half-span
      center-pt = c.add norm1.multiply-scalar(d)
      p1 = center-pt.sub dir1.multiply-scalar(half-span)
      p2 = center-pt.add dir1.multiply-scalar(half-span)
      raw-lines.push new Segment2D p1, p2
      d += step

    # Second pass: orthogonal angle (theta + 90 deg)
    theta2 = @angle + Math.PI * 0.5
    dir2 = new Point2D (Math.cos theta2), (Math.sin theta2)
    norm2 = new Point2D (-Math.sin theta2), (Math.cos theta2)

    d := -half-span
    while d <= half-span
      center-pt = c.add norm2.multiply-scalar(d)
      p1 = center-pt.sub dir2.multiply-scalar(half-span)
      p2 = center-pt.add dir2.multiply-scalar(half-span)
      raw-lines.push new Segment2D p1, p2
      d += step

    @clip-to-island raw-lines, island

module.exports = GridInfill
