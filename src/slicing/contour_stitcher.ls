# Robust 2D Segment Stitcher and Contour Loop Closure Engine
# Snaps endpoints, bridges micro-gaps, and reconstructs closed polygon loops

Point2D = require '../geometry2d/point2d'
Polygon2D = require '../geometry2d/polygon2d'
Segment2D = require '../geometry2d/segment2d'

class ContourStitcher
  @stitch = (segments, tolerance = 1e-4) ->
    if segments.length == 0
      return []

    # Map endpoint coordinates to buckets for fast proximity snapping
    inv-tol = 1.0 / tolerance
    make-key = (p) ->
      gx = Math.round p.x * inv-tol
      gy = Math.round p.y * inv-tol
      "#gx:#gy"

    # Pool of unvisited directed segments
    unvisited = [s.clone! for s in segments]
    closed-loops = []

    # Bucket index of segments by starting point
    start-map = new Map!
    for seg, idx in unvisited
      k = make-key seg.p1
      if not start-map.has k
        start-map.set k, []
      start-map.get(k).push idx

    used-indices = new Set!

    find-next-segment = (curr-pt) ->
      # Check exact bucket and adjacent buckets
      gx = Math.round curr-pt.x * inv-tol
      gy = Math.round curr-pt.y * inv-tol

      best-idx = -1
      best-dist-sq = Infinity
      best-reversed = false

      for dx from -1 to 1
        for dy from -1 to 1
          k = "#{gx + dx}:#{gy + dy}"
          candidates = start-map.get k
          if candidates?
            for idx in candidates
              if not used-indices.has idx
                cand-seg = unvisited[idx]
                d-start = curr-pt.distance-to-sq cand-seg.p1
                if d-start < (tolerance * tolerance) and d-start < best-dist-sq
                  best-dist-sq = d-start
                  best-idx = idx
                  best-reversed = false

      # Fallback: check candidate ending points (reverse orientation)
      if best-idx == -1
        for idx from 0 til unvisited.length
          if not used-indices.has idx
            cand-seg = unvisited[idx]
            d-end = curr-pt.distance-to-sq cand-seg.p2
            if d-end < (tolerance * tolerance) and d-end < best-dist-sq
              best-dist-sq = d-end
              best-idx = idx
              best-reversed = true

      if best-idx != -1
        { idx: best-idx, reversed: best-reversed }
      else
        null

    for start-idx from 0 til unvisited.length
      if used-indices.has start-idx
        continue

      used-indices.add start-idx
      first-seg = unvisited[start-idx]
      loop-points = [first-seg.p1.clone!, first-seg.p2.clone!]
      curr-pt = first-seg.p2

      max-steps = unvisited.length * 2
      steps = 0

      while steps < max-steps
        steps += 1
        # Check if current point connects back to start of loop
        if curr-pt.distance-to(loop-points[0]) < tolerance and loop-points.length >= 3
          # Loop is closed
          break

        nxt = find-next-segment curr-pt
        if not nxt?
          break

        used-indices.add nxt.idx
        next-seg = unvisited[nxt.idx]
        if nxt.reversed
          curr-pt = next-seg.p1.clone!
          loop-points.push curr-pt
        else
          curr-pt = next-seg.p2.clone!
          loop-points.push curr-pt

      # Only keep closed or near-closed polygons with at least 3 vertices
      if loop-points.length >= 3
        # Remove trailing vertex if identical to first
        last-pt = loop-points[loop-points.length - 1]
        if last-pt.distance-to(loop-points[0]) < tolerance
          loop-points.pop!

        if loop-points.length >= 3
          poly = new Polygon2D loop-points
          if poly.area! > 1e-6
            closed-loops.push poly

    closed-loops

module.exports = ContourStitcher
