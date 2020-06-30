# Euclidean Traveling Salesperson Problem (TSP) 2-Opt Local Search Optimizer
# Minimizes non-extrusion travel distance between disjoint loops and infill clusters

Point2D = require '../geometry2d/point2d'

class TravelOptimizer
  @optimize-loop-order = (loops, start-pos = new Point2D(0, 0), max-iterations = 50) ->
    # loops: Array of Polygon2D or objects with start/end points
    if loops.length <= 1
      return loops

    n = loops.length
    # Step 1: Greedy Nearest-Neighbor Initialization
    unvisited = [i for i from 0 til n]
    ordered-indices = []
    curr-pos = start-pos.clone!

    while unvisited.length > 0
      best-idx = -1
      best-dist-sq = Infinity
      best-unvisited-pos = -1

      for idx, u-pos in unvisited
        first-pt = loops[idx].points[0]
        d-sq = curr-pos.distance-to-sq first-pt
        if d-sq < best-dist-sq
          best-dist-sq = d-sq
          best-idx = idx
          best-unvisited-pos = u-pos

      ordered-indices.push best-idx
      curr-pos = loops[best-idx].points[0]
      unvisited.splice best-unvisited-pos, 1

    # Step 2: 2-Opt Local Search Heuristic
    # Computes total travel path length between consecutive loop starts
    calculate-total-travel = (order) ->
      dist = 0.0
      p = start-pos
      for idx in order
        next-p = loops[idx].points[0]
        dist += p.distance-to next-p
        p = loops[idx].points[loops[idx].points.length - 1]
      dist

    improved = true
    iteration = 0
    best-order = ordered-indices.slice!
    best-dist = calculate-total-travel best-order

    while improved and iteration < max-iterations
      improved = false
      iteration += 1

      for i from 0 til (n - 1)
        for k from (i + 1) til n
          # Reverse the sub-sequence from i to k
          new-order = best-order.slice!
          sub = new-order.slice(i, k + 1).reverse!
          new-order.splice.apply new-order, [i, sub.length].concat(sub)

          new-dist = calculate-total-travel new-order
          if new-dist < (best-dist - 1e-4)
            best-dist = new-dist
            best-order = new-order
            improved = true
            break
        if improved
          break

    [loops[idx] for idx in best-order]

module.exports = TravelOptimizer
