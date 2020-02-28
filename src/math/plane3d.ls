# 3D Plane in Hessian Normal Form (A*x + B*y + C*z + D = 0)
# Foundation for triangle slicing and cross-section generation

Vector3 = require './vector3'

class Plane3D
  (normal = Vector3.UNIT_Z, constant = 0.0) ->
    @normal = normal.normalize!
    @constant = +constant

  clone: ->
    new Plane3D @normal.clone!, @constant

  copy: (other) ->
    @normal = other.normal.clone!
    @constant = +other.constant
    @

  set-from-normal-and-coplanar-point: (normal, point) ->
    @normal = normal.normalize!
    @constant = -point.dot @normal
    @

  set-from-coplanar-points: (a, b, c) ->
    edge1 = b.sub a
    edge2 = c.sub a
    normal = edge1.cross(edge2).normalize!
    @set-from-normal-and-coplanar-point normal, a
    @

  distance-to-point: (point) ->
    @normal.dot(point) + @constant

  project-point: (point) ->
    d = @distance-to-point point
    point.sub @normal.multiply-scalar(d)

  intersect-segment: (p1, p2, eps = 1e-9) ->
    d1 = @distance-to-point p1
    d2 = @distance-to-point p2

    # If both points are on the same side of the plane
    if (d1 > eps and d2 > eps) or (d1 < -eps and d2 < -eps)
      return null

    # If both points lie on the plane
    if Math.abs(d1) <= eps and Math.abs(d2) <= eps
      return p1.clone!

    # Linear interpolation factor t in [0, 1]
    denom = d1 - d2
    if Math.abs(denom) < 1e-15
      return null

    t = d1 / denom
    t = Math.max 0.0, Math.min 1.0, t
    p1.lerp p2, t

  intersect-triangle: (v0, v1, v2, eps = 1e-9) ->
    # Computes line segment from slicing triangle with this plane
    d0 = @distance-to-point v0
    d1 = @distance-to-point v1
    d2 = @distance-to-point v2

    # Snap tiny values to zero
    if Math.abs(d0) < eps then d0 = 0.0
    if Math.abs(d1) < eps then d1 = 0.0
    if Math.abs(d2) < eps then d2 = 0.0

    # All vertices on one side: no intersection
    if (d0 > 0 and d1 > 0 and d2 > 0) or (d0 < 0 and d1 < 0 and d2 < 0)
      return null

    # Vertices all lie on the plane: coplanar face
    if d0 == 0 and d1 == 0 and d2 == 0
      return null

    pts = []

    check-edge = (pA, pB, dA, dB) ~>
      if (dA > 0 and dB < 0) or (dA < 0 and dB > 0)
        t = dA / (dA - dB)
        inter = pA.lerp pB, t
        pts.push inter
      else if dA == 0
        # Vertex pA is on the plane
        # Only add if not duplicate of last added point
        already = false
        for p in pts
          if p.distance-to-sq(pA) < 1e-12
            already := true
            break
        if not already
          pts.push pA.clone!

    check-edge v0, v1, d0, d1
    check-edge v1, v2, d1, d2
    check-edge v2, v0, d2, d0

    if pts.length == 2
      # Return oriented 3D segment
      [pts[0], pts[1]]
    else if pts.length > 2
      # Keep the two points with greatest mutual distance
      max-d = -1.0
      p-pair = null
      for i from 0 til pts.length
        for j from (i + 1) til pts.length
          dist = pts[i].distance-to-sq pts[j]
          if dist > max-d
            max-d = dist
            p-pair = [pts[i], pts[j]]
      if max-d > 1e-10
        p-pair
      else
        null
    else
      null

module.exports = Plane3D
