# 2D Polygon Offsetting Engine (Inward Inset and Outward Buffer)
# Computes parallel toolpath offsets for perimeter shells, brims, and infill boundaries

Point2D = require './point2d'
Polygon2D = require './polygon2d'
Segment2D = require './segment2d'

class PolygonOffset
  @offset-polygon = (poly, distance, miter-limit = 2.0) ->
    n = poly.vertex-count!
    if n < 3
      return null

    # Ensure consistent CCW orientation
    is-originally-ccw = poly.is-ccw!
    working-poly = poly.clone!
    working-poly.ensure-ccw!
    pts = working-poly.points

    # Precalculate edge vectors and normals
    # For a CCW polygon, outward normal points to the right of forward direction: normal-right
    normals = []
    edges = []

    for i from 0 til n
      j = (i + 1) % n
      v = pts[j].sub pts[i]
      len = v.length!
      if len < 1e-9
        # Skip zero-length edges
        continue
      dir = v.divide-scalar len
      outward-n = dir.normal-right!
      normals.push outward-n
      edges.push { p1: pts[i], p2: pts[j], dir, norm: outward-n }

    num-edges = edges.length
    if num-edges < 3
      return null

    new-vertices = []

    for i from 0 til num-edges
      prev-i = (i + num-edges - 1) % num-edges
      e-prev = edges[prev-i]
      e-curr = edges[i]

      # Shift edges by distance along outward normal
      # Positive distance = expand (outset); negative distance = shrink (inset)
      p-prev-shifted = e-prev.p2.add e-prev.norm.multiply-scalar(distance)
      p-curr-shifted = e-curr.p1.add e-curr.norm.multiply-scalar(distance)

      # Intersection between line (p-prev-shifted + t * e-prev.dir)
      # and line (p-curr-shifted + u * e-curr.dir)
      cross = e-prev.dir.cross e-curr.dir

      if Math.abs(cross) < 1e-6
        # Parallel or nearly collinear edges: shift point directly
        mid-norm = e-prev.norm.add(e-curr.norm).normalize!
        new-vertices.push pts[i].add mid-norm.multiply-scalar(distance)
      else
        # Find intersection point of the two shifted edge lines
        diff = p-curr-shifted.sub p-prev-shifted
        t = (diff.cross e-curr.dir) / cross
        inter = p-prev-shifted.add e-prev.dir.multiply-scalar(t)

        # Miter distance check
        dist-from-vertex = inter.distance-to pts[i]
        if Math.abs(distance) > 1e-9 and (dist-from-vertex / Math.abs(distance)) > miter-limit
          # Bevel joint: insert two bevel points instead of sharp spike
          new-vertices.push p-prev-shifted
          new-vertices.push p-curr-shifted
        else
          new-vertices.push inter

    if new-vertices.length < 3
      return null

    res = new Polygon2D new-vertices

    # Verification: For an inset (negative distance), the area must decrease
    # If polygon inverted/collapsed, area sign flips or area becomes near-zero
    new-area = res.signed-area!
    if distance < 0
      if new-area <= 0 or new-area >= poly.area!
        # Polygon collapsed or inverted
        return null
    else if distance > 0
      if new-area <= 0
        return null

    if not is-originally-ccw
      res.ensure-cw!
    else
      res.ensure-ccw!

    res

  @inset = (poly, distance, miter-limit = 2.0) ->
    @offset-polygon poly, (-Math.abs(distance)), miter-limit

  @outset = (poly, distance, miter-limit = 2.0) ->
    @offset-polygon poly, Math.abs(distance), miter-limit

  @generate-concentric-perimeters = (poly, tool-radius, num-perimeters = 2) ->
    # Generates outer wall and recursive inner wall contours
    shells = []
    curr = poly.clone!
    step = tool-radius * 2.0

    # First perimeter is inset by half nozzle width (tool radius)
    first-shell = @inset curr, tool-radius
    if first-shell?
      shells.push first-shell
      curr = first-shell

      # Subsequent perimeters inset by full extrusion width (2 * tool-radius)
      for p from 1 til num-perimeters
        next-shell = @inset curr, step
        if next-shell?
          shells.push next-shell
          curr = next-shell
        else
          break

    shells

module.exports = PolygonOffset
