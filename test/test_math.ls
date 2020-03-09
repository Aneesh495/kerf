# Unit test suite for kerf mathematical foundations

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Vector3 = require '../src/math/vector3'
Matrix4 = require '../src/math/matrix4'
Plane3D = require '../src/math/plane3d'
AABB3D = require '../src/math/aabb3d'
Quaternion = require '../src/math/quaternion'
Units = require '../src/math/units'

describe "Vector3 Operations", ->
  test-case "initializes correctly with defaults and parameters", ->
    v0 = new Vector3!
    assert.strictEqual v0.x, 0.0
    assert.strictEqual v0.y, 0.0
    assert.strictEqual v0.z, 0.0

    v1 = new Vector3 1.5, -2.5, 3.5
    assert.strictEqual v1.x, 1.5
    assert.strictEqual v1.y, -2.5
    assert.strictEqual v1.z, 3.5

  test-case "computes addition, subtraction, and scalar multiplication", ->
    a = new Vector3 1, 2, 3
    b = new Vector3 4, 5, 6
    sum = a.add b
    assert.strictEqual sum.x, 5
    assert.strictEqual sum.y, 7
    assert.strictEqual sum.z, 9

    diff = b.sub a
    assert.strictEqual diff.x, 3
    assert.strictEqual diff.y, 3
    assert.strictEqual diff.z, 3

    scaled = a.multiply-scalar 2.5
    assert.strictEqual scaled.x, 2.5
    assert.strictEqual scaled.y, 5.0
    assert.strictEqual scaled.z, 7.5

  test-case "computes dot product and cross product accurately", ->
    x = new Vector3 1, 0, 0
    y = new Vector3 0, 1, 0
    dot = x.dot y
    assert.strictEqual dot, 0.0

    z = x.cross y
    assert.strictEqual z.x, 0
    assert.strictEqual z.y, 0
    assert.strictEqual z.z, 1

  test-case "normalizes non-zero vectors and handles zero vectors safely", ->
    v = new Vector3 0, 3, 4
    assert.strictEqual v.length!, 5.0
    n = v.normalize!
    assert-approx n.length!, 1.0
    assert.strictEqual n.x, 0
    assert-approx n.y, 0.6, 1e-6
    assert-approx n.z, 0.8, 1e-6

    zero = new Vector3 0, 0, 0
    n-zero = zero.normalize!
    assert.strictEqual n-zero.x, 0
    assert.strictEqual n-zero.y, 0
    assert.strictEqual n-zero.z, 0

describe "Matrix4 Transformations", ->
  test-case "creates identity and handles translation", ->
    m = new Matrix4!
    v = new Vector3 10, 20, 30
    transformed = v.transform-matrix4 m
    assert.strictEqual transformed.x, 10
    assert.strictEqual transformed.y, 20
    assert.strictEqual transformed.z, 30

    m.make-translation 5, -10, 15
    trans = v.transform-matrix4 m
    assert.strictEqual trans.x, 15
    assert.strictEqual trans.y, 10
    assert.strictEqual trans.z, 45

  test-case "inverts affine transformations properly", ->
    m = new Matrix4!
    m.make-rotation-z Math.PI * 0.5
    m.elements[12] = 100
    m.elements[13] = 200

    inv = m.clone!.invert!
    mult = m.clone!.multiply inv
    identity = new Matrix4!
    for i from 0 til 16
      assert-approx mult.elements[i], identity.elements[i], 1e-6

describe "Plane3D Slicing and Distance", ->
  test-case "calculates signed distance to points", ->
    plane = new Plane3D Vector3.UNIT_Z, -10.0 # Plane Z = 10
    p-above = new Vector3 0, 0, 15
    p-below = new Vector3 0, 0, 5
    p-on = new Vector3 5, 5, 10

    assert-approx plane.distance-to-point(p-above), 5.0
    assert-approx plane.distance-to-point(p-below), -5.0
    assert-approx plane.distance-to-point(p-on), 0.0

  test-case "slices triangle into line segment", ->
    plane = new Plane3D Vector3.UNIT_Z, -5.0 # Z = 5 plane
    v0 = new Vector3 0, 0, 0
    v1 = new Vector3 10, 0, 10
    v2 = new Vector3 0, 10, 10

    seg = plane.intersect-triangle v0, v1, v2
    assert.ok seg != null
    assert.strictEqual seg.length, 2
    # At Z = 5, intersection points should be (5, 0, 5) and (0, 5, 5)
    p0 = seg[0]
    p1 = seg[1]
    assert-approx p0.z, 5.0
    assert-approx p1.z, 5.0
    d = p0.distance-to p1
    assert-approx d, Math.sqrt(50), 1e-4

describe "AABB3D Bounds & Units", ->
  test-case "correctly expands bounding boxes and checks intersection", ->
    box = new AABB3D!
    assert.ok box.is-empty!
    box.expand-by-point new Vector3 0, 0, 0
    box.expand-by-point new Vector3 10, 20, 30
    assert.ok not box.is-empty!
    assert.strictEqual box.volume!, 6000.0
    assert.ok box.contains-point new Vector3 5, 10, 15
    assert.ok not box.contains-point new Vector3 15, 10, 15

  test-case "converts units to nanometers and back accurately", ->
    nm = Units.mm-to-nm 12.345678
    assert.strictEqual nm, 12345678
    mm = Units.nm-to-mm nm
    assert-approx mm, 12.345678, 1e-6
