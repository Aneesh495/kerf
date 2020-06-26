# Seam Placement Planner and Cosmetic Optimization Engine
# Rotates closed perimeter start vertices to sharp convex corners or aligned axes

Point2D = require '../geometry2d/point2d'
Polygon2D = require '../geometry2d/polygon2d'

class SeamPlacement
  @ALIGNED       = 'Aligned'
  @NEAREST       = 'Nearest'
  @RANDOM        = 'Random'
  @CONVEX_CORNER = 'ConvexCorner'

class SeamPlanner
  @find-best-seam-index = (poly, strategy = SeamPlacement.CONVEX_CORNER, opts = {}) ->
    n = poly.vertex-count!
    if n <= 2
      return 0

    pts = poly.points

    switch strategy
    case SeamPlacement.NEAREST
      ref-pos = opts.current-pos or new Point2D 0, 0
      best-idx = 0
      min-d-sq = Infinity
      for i from 0 til n
        d-sq = pts[i].distance-to-sq ref-pos
        if d-sq < min-d-sq
          min-d-sq = d-sq
          best-idx = i
      best-idx

    case SeamPlacement.ALIGNED
      # Align to rear-most point (+Y axis)
      best-idx = 0
      max-y = -Infinity
      for i from 0 til n
        if pts[i].y > max-y
          max-y = pts[i].y
          best-idx = i
      best-idx

    case SeamPlacement.RANDOM
      Math.floor(Math.random! * n)

    case SeamPlacement.CONVEX_CORNER
      # Evaluate interior angle at each vertex: sharpest convex corner
      # For CCW polygon, cross product of incoming edge and outgoing edge is positive for convex corner
      best-idx = 0
      max-convexity = -Infinity

      for i from 0 til n
        prev-i = (i + n - 1) % n
        next-i = (i + 1) % n

        v-in = pts[i].sub pts[prev-i]
        v-out = pts[next-i].sub pts[i]

        len-in = v-in.length!
        len-out = v-out.length!

        if len-in > 1e-6 and len-out > 1e-6
          # 2D cross product: v_in.x * v_out.y - v_in.y * v_out.x
          cross = v-in.cross v-out
          dot = v-in.dot v-out
          # Convex corner when cross > 0 in CCW polygon
          # Acute corner when dot is small or negative
          convexity = cross / (len-in * len-out)
          if convexity > max-convexity
            max-convexity = convexity
            best-idx = i

      best-idx

    default
      0

  @reorder-polygon-at-seam = (poly, strategy = SeamPlacement.CONVEX_CORNER, opts = {}) ->
    idx = @find-best-seam-index poly, strategy, opts
    if idx == 0
      return poly.clone!

    pts = poly.points
    reordered = pts.slice(idx).concat pts.slice(0, idx)
    new Polygon2D reordered

module.exports = {
  SeamPlacement
  SeamPlanner
}
