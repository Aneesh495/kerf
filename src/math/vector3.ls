# 3D Cartesian Vector representation and geometric operations
# Supports immutable transformations and precision calculations

class Vector3
  (x = 0.0, y = 0.0, z = 0.0) ->
    @x = +x
    @y = +y
    @z = +z

  clone: ->
    new Vector3 @x, @y, @z

  copy: (other) ->
    @x = +other.x
    @y = +other.y
    @z = +other.z
    @

  set: (x, y, z) ->
    @x = +x
    @y = +y
    @z = +z
    @

  add: (other) ->
    new Vector3 (@x + other.x), (@y + other.y), (@z + other.z)

  add-scaled: (other, s) ->
    new Vector3 (@x + other.x * s), (@y + other.y * s), (@z + other.z * s)

  sub: (other) ->
    new Vector3 (@x - other.x), (@y - other.y), (@z - other.z)

  multiply-scalar: (s) ->
    new Vector3 (@x * s), (@y * s), (@z * s)

  divide-scalar: (s) ->
    if s == 0
      throw new Error "Division by zero in Vector3.divide-scalar"
    inv = 1.0 / s
    new Vector3 (@x * inv), (@y * inv), (@z * inv)

  negate: ->
    new Vector3 (-@x), (-@y), (-@z)

  dot: (other) ->
    @x * other.x + @y * other.y + @z * other.z

  cross: (other) ->
    cx = @y * other.z - @z * other.y
    cy = @z * other.x - @x * other.z
    cz = @x * other.y - @y * other.x
    new Vector3 cx, cy, cz

  length-sq: ->
    @x * @x + @y * @y + @z * @z

  length: ->
    Math.sqrt @length-sq!

  distance-to-sq: (other) ->
    dx = @x - other.x
    dy = @y - other.y
    dz = @z - other.z
    dx * dx + dy * dy + dz * dz

  distance-to: (other) ->
    Math.sqrt @distance-to-sq(other)

  normalize: ->
    len = @length!
    if len > 1e-12
      inv = 1.0 / len
      new Vector3 (@x * inv), (@y * inv), (@z * inv)
    else
      new Vector3 0.0, 0.0, 0.0

  lerp: (other, alpha) ->
    new Vector3 (
      @x + (other.x - @x) * alpha
    ), (
      @y + (other.y - @y) * alpha
    ), (
      @z + (other.z - @z) * alpha
    )

  angle-to: (other) ->
    denom = Math.sqrt(@length-sq! * other.length-sq!)
    if denom < 1e-12
      return 0.0
    val = @dot(other) / denom
    clamped = Math.max -1.0, Math.min 1.0, val
    Math.acos clamped

  reflect: (normal) ->
    # v - 2 * (v . n) * n
    n = normal.normalize!
    d = @dot n
    @sub n.multiply-scalar(2.0 * d)

  transform-matrix4: (m) ->
    e = m.elements
    x = @x; y = @y; z = @z
    w = 1.0 / (e[3] * x + e[7] * y + e[11] * z + e[15])
    nx = (e[0] * x + e[4] * y + e[8]  * z + e[12]) * w
    ny = (e[1] * x + e[5] * y + e[9]  * z + e[13]) * w
    nz = (e[2] * x + e[6] * y + e[10] * z + e[14]) * w
    new Vector3 nx, ny, nz

  equals-approx: (other, eps = 1e-6) ->
    (Math.abs(@x - other.x) <= eps) and
    (Math.abs(@y - other.y) <= eps) and
    (Math.abs(@z - other.z) <= eps)

  to-array: ->
    [@x, @y, @z]

  to-string: ->
    "(#{@x.toFixed 4}, #{@y.toFixed 4}, #{@z.toFixed 4})"

Vector3.ZERO = new Vector3 0, 0, 0
Vector3.UNIT_X = new Vector3 1, 0, 0
Vector3.UNIT_Y = new Vector3 0, 1, 0
Vector3.UNIT_Z = new Vector3 0, 0, 1

module.exports = Vector3
