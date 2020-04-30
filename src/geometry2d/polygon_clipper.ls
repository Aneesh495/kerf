# 2D Polygon Boolean Clipping and Line-Polygon Intersection Engine
# Implements Sutherland-Hodgman clipping and segment-interior extraction

Point2D = require './point2d'
Segment2D = require './segment2d'
Polygon2D = require './polygon2d'

class PolygonClipper
  @clip-segment-to-polygon = (seg, poly, eps = 1e-9) ->
    # Slices a line segment by all polygon boundary edges
    # Returns all sub-segments that lie strictly inside the polygon
    p1 = seg.p1
    p2 = seg.p2
    dir = p2.sub p1
    total-len = dir.length!

    if total-len < eps
      return []

    # Collect parametric intersection parameters t in [0, 1]
    ts = [0.0, 1.0]

    n = poly.vertex-count!
    for i from 0 til n
      j = (i + 1) % n
      edge = new Segment2D poly.points[i], poly.points[j]
      inter = seg.intersect-segment edge, eps
      if inter?
        # Calculate parametric position t
        t = (inter.sub p1).dot(dir) / (total-len * total-len)
        if t > eps and t < (1.0 - eps)
          ts.push t

    # Sort parameter values ascendingly and remove duplicates
    ts.sort (a, b) -> a - b

    unique-ts = [ts[0]]
    for i from 1 til ts.length
      if Math.abs(ts[i] - unique-ts[unique-ts.length - 1]) > eps
        unique-ts.push ts[i]

    # For each sub-interval [t_k, t_{k+1}], test if its midpoint is inside the polygon
    valid-segments = []
    for k from 0 til (unique-ts.length - 1)
      t-start = unique-ts[k]
      t-end = unique-ts[k + 1]
      t-mid = (t-start + t-end) * 0.5

      mid-pt = p1.add dir.multiply-scalar(t-mid)
      if poly.contains-point mid-pt, eps
        sub-p1 = p1.add dir.multiply-scalar(t-start)
        sub-p2 = p1.add dir.multiply-scalar(t-end)
        if sub-p1.distance-to(sub-p2) > eps
          valid-segments.push new Segment2D sub-p1, sub-p2

    valid-segments

  @clip-polygon-sutherland-hodgman = (subject-poly, clip-poly) ->
    # Sutherland-Hodgman polygon clipping against a convex clipping polygon
    output-list = [p.clone! for p in subject-poly.points]
    clip-len = clip-poly.vertex-count!

    for c-idx from 0 til clip-len
      next-c = (c-idx + 1) % clip-len
      cp1 = clip-poly.points[c-idx]
      cp2 = clip-poly.points[next-c]
      clip-edge-vec = cp2.sub cp1

      input-list = output-list
      output-list = []

      if input-list.length == 0
        break

      s = input-list[input-list.length - 1]

      is-inside = (pt) ->
        # Point is inside if it lies to the left of directed edge cp1 -> cp2 (CCW clip)
        clip-edge-vec.cross(pt.sub cp1) >= -1e-9

      compute-intersection = (pA, pB) ->
        seg-a = new Segment2D cp1, cp2
        seg-b = new Segment2D pA, pB
        inter = seg-a.intersect-segment seg-b
        if inter? then inter else pA.lerp(pB, 0.5)

      for e in input-list
        if is-inside e
          if is-inside s
            output-list.push e
          else
            output-list.push compute-intersection(s, e)
            output-list.push e
        else if is-inside s
          output-list.push compute-intersection(s, e)
        s = e

    if output-list.length >= 3
      new Polygon2D output-list
    else
      null

module.exports = PolygonClipper
