# 2D Polygon representation with Shoelace area and winding order determination
# Core data model for layer contours, holes, and infill bounding regions

Point2D = require './point2d'
Segment2D = require './segment2d'

class Polygon2D
  (points = []) ->
    @points = [p.clone! for p in points]

  add-point: (p) ->
    @points.push p.clone!
    @

  clone: ->
    new Polygon2D @points

  vertex-count: ->
    @points.length

  signed-area: ->
    # Green's theorem / Shoelace formula: 0.5 * sum(x_i * y_{i+1} - x_{i+1} * y_i)
    n = @points.length
    if n < 3
      return 0.0

    sum = 0.0
    for i from 0 til n
      j = (i + 1) % n
      sum += (@points[i].x * @points[j].y - @points[j].x * @points[i].y)
    sum * 0.5

  area: ->
    Math.abs @signed-area!

  is-ccw: ->
    @signed-area! > 0

  ensure-ccw: ->
    if not @is-ccw!
      @points.reverse!
    @

  ensure-cw: ->
    if @is-ccw!
      @points.reverse!
    @

  reverse: ->
    @points.reverse!
    @

  perimeter: ->
    n = @points.length
    if n < 2
      return 0.0
    total = 0.0
    for i from 0 til n
      j = (i + 1) % n
      total += @points[i].distance-to @points[j]
    total

  centroid: ->
    n = @points.length
    if n == 0
      return new Point2D 0, 0
    if n < 3
      return @points[0].clone!

    signed-a = @signed-area!
    if Math.abs(signed-a) < 1e-12
      return @points[0].clone!

    cx = 0.0
    cy = 0.0
    for i from 0 til n
      j = (i + 1) % n
      cross = @points[i].x * @points[j].y - @points[j].x * @points[i].y
      cx += (@points[i].x + @points[j].x) * cross
      cy += (@points[i].y + @points[j].y) * cross

    factor = 1.0 / (6.0 * signed-a)
    new Point2D (cx * factor), (cy * factor)

  get-bounds: ->
    if @points.length == 0
      return { min-x: 0, min-y: 0, max-x: 0, max-y: 0 }
    min-x = Infinity; min-y = Infinity
    max-x = -Infinity; max-y = -Infinity
    for p in @points
      if p.x < min-x then min-x = p.x
      if p.x > max-x then max-x = p.x
      if p.y < min-y then min-y = p.y
      if p.y > max-y then max-y = p.y
    { min-x, min-y, max-x, max-y }

  contains-point: (p, eps = 1e-9) ->
    # Jordan curve theorem crossing number test
    n = @points.length
    if n < 3
      return false

    bounds = @get-bounds!
    if p.x < bounds.min-x or p.x > bounds.max-x or p.y < bounds.min-y or p.y > bounds.max-y
      return false

    inside = false
    j = n - 1
    for i from 0 til n
      pi = @points[i]
      pj = @points[j]

      # Check if point lies on segment
      seg = new Segment2D pi, pj
      if seg.distance-to-point(p) < eps
        return true

      intersect = ((pi.y > p.y) != (pj.y > p.y)) and
        (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)

      if intersect
        inside = not inside
      j = i

    inside

  winding-number: (p) ->
    # Winding number calculation for self-overlapping or non-simple contours
    n = @points.length
    if n < 3
      return 0

    wn = 0
    for i from 0 til n
      j = (i + 1) % n
      pi = @points[i]
      pj = @points[j]

      if pi.y <= p.y
        if pj.y > p.y
          # Upward crossing
          is-left = (pj.x - pi.x) * (p.y - pi.y) - (p.x - pi.x) * (pj.y - pi.y)
          if is-left > 0
            wn += 1
      else
        if pj.y <= p.y
          # Downward crossing
          is-left = (pj.x - pi.x) * (p.y - pi.y) - (p.x - pi.x) * (pj.y - pi.y)
          if is-left < 0
            wn -= 1
    wn

  simplify: (epsilon = 0.05) ->
    # Ramer-Douglas-Peucker polygon simplification
    if @points.length <= 3
      return @clone!

    dmax = 0.0
    index = 0
    end = @points.length - 1

    for i from 1 til end
      seg = new Segment2D @points[0], @points[end]
      d = seg.distance-to-point @points[i]
      if d > dmax
        index = i
        dmax = d

    if dmax > epsilon
      rec1 = new Polygon2D @points.slice(0, index + 1)
      rec2 = new Polygon2D @points.slice(index)
      s1 = rec1.simplify epsilon
      s2 = rec2.simplify epsilon
      res-pts = s1.points.slice(0, -1).concat s2.points
      new Polygon2D res-pts
    else
      new Polygon2D [@points[0], @points[end]]

module.exports = Polygon2D
