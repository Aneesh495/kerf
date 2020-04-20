# 2D Line Segment representation and geometric intersection tests
# Used for infill scanlines, perimeter toolpaths, and polygon edges

Point2D = require './point2d'

class Segment2D
  (p1, p2) ->
    @p1 = p1.clone!
    @p2 = p2.clone!

  clone: ->
    new Segment2D @p1, @p2

  length-sq: ->
    @p1.distance-to-sq @p2

  length: ->
    @p1.distance-to @p2

  direction: ->
    @p2.sub(@p1).normalize!

  normal: ->
    @direction!.normal-left!

  distance-to-point: (p) ->
    v = @p2.sub @p1
    w = p.sub @p1
    c1 = w.dot v
    if c1 <= 0
      return p.distance-to @p1
    c2 = v.dot v
    if c2 <= c1
      return p.distance-to @p2
    b = c1 / c2
    pb = @p1.add v.multiply-scalar(b)
    p.distance-to pb

  intersect-segment: (other, eps = 1e-9) ->
    # Determines if two segments intersect and calculates intersection point
    p = @p1
    r = @p2.sub @p1
    q = other.p1
    s = other.p2.sub other.p1

    r-cross-s = r.cross s
    q-sub-p = q.sub p
    q-sub-p-cross-r = q-sub-p.cross r

    # Collinear or parallel
    if Math.abs(r-cross-s) < eps
      return null

    t = (q-sub-p.cross s) / r-cross-s
    u = q-sub-p-cross-r / r-cross-s

    if t >= -eps and t <= (1.0 + eps) and u >= -eps and u <= (1.0 + eps)
      # Clamp t to [0, 1]
      clamped-t = Math.max 0.0, Math.min 1.0, t
      return p.add r.multiply-scalar(clamped-t)

    null

module.exports = Segment2D
