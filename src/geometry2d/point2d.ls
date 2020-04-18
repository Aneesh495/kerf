# 2D Point and Cartesian Vector in millimeter and quantized nanometer space
# Provides precise planar arithmetic for slice polygons and toolpaths

Units = require '../math/units'

class Point2D
  (x = 0.0, y = 0.0) ->
    @x = +x
    @y = +y

  clone: ->
    new Point2D @x, @y

  copy: (other) ->
    @x = +other.x
    @y = +other.y
    @

  set: (x, y) ->
    @x = +x
    @y = +y
    @

  add: (other) ->
    new Point2D (@x + other.x), (@y + other.y)

  sub: (other) ->
    new Point2D (@x - other.x), (@y - other.y)

  multiply-scalar: (s) ->
    new Point2D (@x * s), (@y * s)

  divide-scalar: (s) ->
    if s == 0
      throw new Error "Division by zero in Point2D.divide-scalar"
    inv = 1.0 / s
    new Point2D (@x * inv), (@y * inv)

  dot: (other) ->
    @x * other.x + @y * other.y

  cross: (other) ->
    # 2D cross product scalar (perpendicular dot product)
    @x * other.y - @y * other.x

  length-sq: ->
    @x * @x + @y * @y

  length: ->
    Math.sqrt @length-sq!

  distance-to-sq: (other) ->
    dx = @x - other.x
    dy = @y - other.y
    dx * dx + dy * dy

  distance-to: (other) ->
    Math.sqrt @distance-to-sq(other)

  normalize: ->
    len = @length!
    if len > 1e-12
      inv = 1.0 / len
      new Point2D (@x * inv), (@y * inv)
    else
      new Point2D 0.0, 0.0

  normal-left: ->
    # Rotates 90 degrees counter-clockwise: (-y, x)
    new Point2D (-@y), @x

  normal-right: ->
    # Rotates 90 degrees clockwise: (y, -x)
    new Point2D @y, (-@x)

  lerp: (other, t) ->
    new Point2D (
      @x + (other.x - @x) * t
    ), (
      @y + (other.y - @y) * t
    )

  to-nanometers: ->
    {
      x: Units.mm-to-nm @x
      y: Units.mm-to-nm @y
    }

  equals-approx: (other, eps = 1e-6) ->
    Math.abs(@x - other.x) <= eps and Math.abs(@y - other.y) <= eps

Point2D.from-nanometers = (nm-x, nm-y) ->
  new Point2D (Units.nm-to-mm nm-x), (Units.nm-to-mm nm-y)

module.exports = Point2D
