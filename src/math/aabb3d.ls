# 3D Axis-Aligned Bounding Box (AABB)
# Supports fast spatial pruning, BVH hierarchy node bounds, and expansion

Vector3 = require './vector3'

class AABB3D
  (min = null, max = null) ->
    if min? and max?
      @min = min.clone!
      @max = max.clone!
    else
      @min = new Vector3 Infinity, Infinity, Infinity
      @max = new Vector3 -Infinity, -Infinity, -Infinity

  clone: ->
    new AABB3D @min, @max

  copy: (other) ->
    @min.copy other.min
    @max.copy other.max
    @

  is-empty: ->
    @max.x < @min.x or @max.y < @min.y or @max.z < @min.z

  reset: ->
    @min.set Infinity, Infinity, Infinity
    @max.set -Infinity, -Infinity, -Infinity
    @

  expand-by-point: (p) ->
    @min.x = Math.min @min.x, p.x
    @min.y = Math.min @min.y, p.y
    @min.z = Math.min @min.z, p.z

    @max.x = Math.max @max.x, p.x
    @max.y = Math.max @max.y, p.y
    @max.z = Math.max @max.z, p.z
    @

  expand-by-aabb: (box) ->
    if box.is-empty!
      return @
    @min.x = Math.min @min.x, box.min.x
    @min.y = Math.min @min.y, box.min.y
    @min.z = Math.min @min.z, box.min.z

    @max.x = Math.max @max.x, box.max.x
    @max.y = Math.max @max.y, box.max.y
    @max.z = Math.max @max.z, box.max.z
    @

  contains-point: (p) ->
    p.x >= @min.x and p.x <= @max.x and
    p.y >= @min.y and p.y <= @max.y and
    p.z >= @min.z and p.z <= @max.z

  intersects-aabb: (box) ->
    not (
      box.max.x < @min.x or box.min.x > @max.x or
      box.max.y < @min.y or box.min.y > @max.y or
      box.max.z < @min.z or box.min.z > @max.z
    )

  intersects-plane-z: (z) ->
    z >= @min.z and z <= @max.z

  center: ->
    new Vector3 (
      (@min.x + @max.x) * 0.5
    ), (
      (@min.y + @max.y) * 0.5
    ), (
      (@min.z + @max.z) * 0.5
    )

  size: ->
    if @is-empty!
      new Vector3 0, 0, 0
    else
      @max.sub @min

  surface-area: ->
    if @is-empty!
      return 0.0
    d = @size!
    2.0 * (d.x * d.y + d.y * d.z + d.z * d.x)

  volume: ->
    if @is-empty!
      return 0.0
    d = @size!
    d.x * d.y * d.z

AABB3D.from-points = (points) ->
  box = new AABB3D!
  for p in points
    box.expand-by-point p
  box

module.exports = AABB3D
