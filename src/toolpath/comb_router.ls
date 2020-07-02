# Perimeter-Avoidance Comb Router
# Prevents nozzle stringing across visible external perimeters by routing travel internally

Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'

class CombRouter
  @route-travel = (start-pt, end-pt, island) ->
    direct-seg = new Segment2D start-pt, end-pt
    poly = island.contour

    # Check if direct path crosses outer boundary
    crosses-boundary = false
    n = poly.vertex-count!

    for i from 0 til n
      j = (i + 1) % n
      edge = new Segment2D poly.points[i], poly.points[j]
      inter = direct-seg.intersect-segment edge
      if inter?
        # Check if intersection is strictly inside both segments
        d1 = inter.distance-to-sq start-pt
        d2 = inter.distance-to-sq end-pt
        if d1 > 1e-6 and d2 > 1e-6
          crosses-boundary = true
          break

    if not crosses-boundary
      # Safe direct travel
      return [direct-seg]

    # Boundary crossing detected: route through polygon centroid internally
    c = poly.centroid!
    seg1 = new Segment2D start-pt, c
    seg2 = new Segment2D c, end-pt
    [seg1, seg2]

module.exports = CombRouter
