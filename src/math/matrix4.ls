# 4x4 Affine Transformation Matrix in column-major order
# Provides linear algebra routines for mesh orientation and toolhead transforms

Vector3 = require './vector3'

class Matrix4
  (elements = null) ->
    if elements? and elements.length == 16
      @elements = new Float64Array elements
    else
      @elements = new Float64Array 16
      @identity!

  identity: ->
    e = @elements
    e[0] = 1; e[4] = 0; e[8]  = 0; e[12] = 0
    e[1] = 0; e[5] = 1; e[9]  = 0; e[13] = 0
    e[2] = 0; e[6] = 0; e[10] = 1; e[14] = 0
    e[3] = 0; e[7] = 0; e[11] = 0; e[15] = 1
    @

  clone: ->
    new Matrix4 @elements

  copy: (other) ->
    for i from 0 til 16
      @elements[i] = other.elements[i]
    @

  multiply: (other) ->
    a = @elements
    b = other.elements
    res = new Float64Array 16

    for row from 0 til 4
      for col from 0 til 4
        sum = 0.0
        for k from 0 til 4
          sum += a[row + k * 4] * b[k + col * 4]
        res[row + col * 4] = sum

    @elements = res
    @

  premultiply: (other) ->
    cp = other.clone!
    cp.multiply @
    @elements = cp.elements
    @

  make-translation: (x, y, z) ->
    @identity!
    @elements[12] = +x
    @elements[13] = +y
    @elements[14] = +z
    @

  make-scale: (x, y, z) ->
    @identity!
    @elements[0]  = +x
    @elements[5]  = +y
    @elements[10] = +z
    @

  make-rotation-x: (theta) ->
    @identity!
    c = Math.cos theta
    s = Math.sin theta
    @elements[5]  = c
    @elements[6]  = s
    @elements[9]  = -s
    @elements[10] = c
    @

  make-rotation-y: (theta) ->
    @identity!
    c = Math.cos theta
    s = Math.sin theta
    @elements[0]  = c
    @elements[2]  = -s
    @elements[8]  = s
    @elements[10] = c
    @

  make-rotation-z: (theta) ->
    @identity!
    c = Math.cos theta
    s = Math.sin theta
    @elements[0] = c
    @elements[1] = s
    @elements[4] = -s
    @elements[5] = c
    @

  make-rotation-axis: (axis, angle) ->
    c = Math.cos angle
    s = Math.sin angle
    t = 1.0 - c
    norm = axis.normalize!
    x = norm.x; y = norm.y; z = norm.z

    e = @elements
    e[0]  = 1 + t * (x * x - 1)
    e[1]  = z * s + t * x * y
    e[2]  = -y * s + t * x * z
    e[3]  = 0

    e[4]  = -z * s + t * x * y
    e[5]  = 1 + t * (y * y - 1)
    e[6]  = x * s + t * y * z
    e[7]  = 0

    e[8]  = y * s + t * x * z
    e[9]  = -x * s + t * y * z
    e[10] = 1 + t * (z * z - 1)
    e[11] = 0

    e[12] = 0; e[13] = 0; e[14] = 0; e[15] = 1
    @

  determinant: ->
    e = @elements
    n11 = e[0];  n12 = e[4];  n13 = e[8];   n14 = e[12]
    n21 = e[1];  n22 = e[5];  n23 = e[9];   n24 = e[13]
    n31 = e[2];  n32 = e[6];  n33 = e[10];  n34 = e[14]
    n41 = e[3];  n42 = e[7];  n43 = e[11];  n44 = e[15]

    term1 = n41 * (n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34)
    term2 = n42 * (n11 * n23 * n34 - n11 * n24 * n33 + n14 * n21 * n33 - n13 * n21 * n34 + n13 * n24 * n31 - n14 * n23 * n31)
    term3 = n43 * (n11 * n24 * n32 - n11 * n22 * n34 - n14 * n21 * n32 + n12 * n21 * n34 + n14 * n22 * n31 - n12 * n24 * n31)
    term4 = n44 * (-n13 * n22 * n31 - n11 * n23 * n32 + n11 * n22 * n33 + n13 * n21 * n32 - n12 * n21 * n33 + n12 * n23 * n31)

    term1 + term2 + term3 + term4

  invert: ->
    det = @determinant!
    if Math.abs(det) < 1e-15
      throw new Error "Matrix4 cannot be inverted: singular matrix (det = 0)"

    inv-det = 1.0 / det
    e = @elements
    t = new Float64Array 16

    t[0]  = (e[5] * (e[10] * e[15] - e[11] * e[14]) - e[9] * (e[6] * e[15] - e[7] * e[14]) + e[13] * (e[6] * e[11] - e[7] * e[10])) * inv-det
    t[1]  = -(e[1] * (e[10] * e[15] - e[11] * e[14]) - e[9] * (e[2] * e[15] - e[3] * e[14]) + e[13] * (e[2] * e[11] - e[3] * e[10])) * inv-det
    t[2]  = (e[1] * (e[6] * e[15] - e[7] * e[14]) - e[5] * (e[2] * e[15] - e[3] * e[14]) + e[13] * (e[2] * e[7] - e[3] * e[6])) * inv-det
    t[3]  = -(e[1] * (e[6] * e[11] - e[7] * e[10]) - e[5] * (e[2] * e[11] - e[3] * e[10]) + e[9] * (e[2] * e[7] - e[3] * e[6])) * inv-det

    t[4]  = -(e[4] * (e[10] * e[15] - e[11] * e[14]) - e[8] * (e[6] * e[15] - e[7] * e[14]) + e[12] * (e[6] * e[11] - e[7] * e[10])) * inv-det
    t[5]  = (e[0] * (e[10] * e[15] - e[11] * e[14]) - e[8] * (e[2] * e[15] - e[3] * e[14]) + e[12] * (e[2] * e[11] - e[3] * e[10])) * inv-det
    t[6]  = -(e[0] * (e[6] * e[15] - e[7] * e[14]) - e[4] * (e[2] * e[15] - e[3] * e[14]) + e[12] * (e[2] * e[7] - e[3] * e[6])) * inv-det
    t[7]  = (e[0] * (e[6] * e[11] - e[7] * e[10]) - e[4] * (e[2] * e[11] - e[3] * e[10]) + e[8] * (e[2] * e[7] - e[3] * e[6])) * inv-det

    t[8]  = (e[4] * (e[9] * e[15] - e[11] * e[13]) - e[8] * (e[5] * e[15] - e[7] * e[13]) + e[12] * (e[5] * e[11] - e[7] * e[9])) * inv-det
    t[9]  = -(e[0] * (e[9] * e[15] - e[11] * e[13]) - e[8] * (e[1] * e[15] - e[3] * e[13]) + e[12] * (e[1] * e[11] - e[3] * e[9])) * inv-det
    t[10] = (e[0] * (e[5] * e[15] - e[7] * e[13]) - e[4] * (e[1] * e[15] - e[3] * e[13]) + e[12] * (e[1] * e[7] - e[3] * e[5])) * inv-det
    t[11] = -(e[0] * (e[5] * e[11] - e[7] * e[9]) - e[4] * (e[1] * e[11] - e[3] * e[9]) + e[8] * (e[1] * e[7] - e[3] * e[5])) * inv-det

    t[12] = -(e[4] * (e[9] * e[14] - e[10] * e[13]) - e[8] * (e[5] * e[14] - e[6] * e[13]) + e[12] * (e[5] * e[10] - e[6] * e[9])) * inv-det
    t[13] = (e[0] * (e[9] * e[14] - e[10] * e[13]) - e[8] * (e[1] * e[14] - e[2] * e[13]) + e[12] * (e[1] * e[10] - e[2] * e[9])) * inv-det
    t[14] = -(e[0] * (e[5] * e[14] - e[6] * e[13]) - e[4] * (e[1] * e[14] - e[2] * e[13]) + e[12] * (e[1] * e[6] - e[2] * e[5])) * inv-det
    t[15] = (e[0] * (e[5] * e[10] - e[6] * e[9]) - e[4] * (e[1] * e[10] - e[2] * e[9]) + e[8] * (e[1] * e[6] - e[2] * e[5])) * inv-det

    @elements = t
    @

  transpose: ->
    e = @elements
    t = new Float64Array 16
    for r from 0 til 4
      for c from 0 til 4
        t[r + c * 4] = e[c + r * 4]
    @elements = t
    @

module.exports = Matrix4
