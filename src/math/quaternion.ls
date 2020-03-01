# Unit Quaternion representation for 3D rotations and orientation interpolation
# Prevents gimbal lock during toolhead and multi-axis transformations

Vector3 = require './vector3'

class Quaternion
  (x = 0.0, y = 0.0, z = 0.0, w = 1.0) ->
    @x = +x
    @y = +y
    @z = +z
    @w = +w

  clone: ->
    new Quaternion @x, @y, @z, @w

  copy: (other) ->
    @x = +other.x
    @y = +other.y
    @z = +other.z
    @w = +other.w
    @

  identity: ->
    @x = 0.0; @y = 0.0; @z = 0.0; @w = 1.0
    @

  set-from-axis-angle: (axis, angle) ->
    half = angle * 0.5
    s = Math.sin half
    norm = axis.normalize!
    @x = norm.x * s
    @y = norm.y * s
    @z = norm.z * s
    @w = Math.cos half
    @

  multiply: (other) ->
    ax = @x; ay = @y; az = @z; aw = @w
    bx = other.x; by = other.y; bz = other.z; bw = other.w

    @x = ax * bw + aw * bx + ay * bz - az * by
    @y = ay * bw + aw * by + az * bx - ax * bz
    @z = az * bw + aw * bz + ax * by - ay * bx
    @w = aw * bw - ax * bx - ay * by - az * bz
    @

  length-sq: ->
    @x * @x + @y * @y + @z * @z + @w * @w

  length: ->
    Math.sqrt @length-sq!

  normalize: ->
    len = @length!
    if len > 1e-12
      inv = 1.0 / len
      @x *= inv
      @y *= inv
      @z *= inv
      @w *= inv
    else
      @identity!
    @

  conjugate: ->
    new Quaternion (-@x), (-@y), (-@z), @w

  inverse: ->
    @conjugate!.normalize!

  rotate-vector3: (v) ->
    # q * v * q^-1
    u = new Vector3 @x, @y, @z
    s = @w

    uv = u.cross v
    uuv = u.cross uv
    uv-scaled = uv.multiply-scalar (2.0 * s)
    uuv-scaled = uuv.multiply-scalar 2.0

    v.add(uv-scaled).add(uuv-scaled)

  slerp: (other, t) ->
    cos-half-theta = @x * other.x + @y * other.y + @z * other.z + @w * other.w
    bx = other.x; by = other.y; bz = other.z; bw = other.w

    if cos-half-theta < 0.0
      bw = -bw; bx = -bx; by = -by; bz = -bz
      cos-half-theta = -cos-half-theta

    if Math.abs(cos-half-theta) >= 1.0
      return @clone!

    half-theta = Math.acos cos-half-theta
    sin-half-theta = Math.sqrt(1.0 - cos-half-theta * cos-half-theta)

    if Math.abs(sin-half-theta) < 1e-6
      return new Quaternion (
        @x * 0.5 + bx * 0.5
      ), (
        @y * 0.5 + by * 0.5
      ), (
        @z * 0.5 + bz * 0.5
      ), (
        @w * 0.5 + bw * 0.5
      )

    ratio-a = Math.sin((1.0 - t) * half-theta) / sin-half-theta
    ratio-b = Math.sin(t * half-theta) / sin-half-theta

    new Quaternion (
      @x * ratio-a + bx * ratio-b
    ), (
      @y * ratio-a + by * ratio-b
    ), (
      @z * ratio-a + bz * ratio-b
    ), (
      @w * ratio-a + bw * ratio-b
    )

module.exports = Quaternion
