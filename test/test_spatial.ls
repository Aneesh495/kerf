# Unit tests for spatial acceleration structures: BVH, SpatialHash, Octree

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Vector3 = require '../src/math/vector3'
AABB3D = require '../src/math/aabb3d'
MeshPrimitives = require '../src/mesh/mesh_primitives'
BVH3D = require '../src/spatial/bvh3d'
{ SpatialHash2D, SpatialHash3D } = require '../src/spatial/spatial_hash'
Octree = require '../src/spatial/octree'

describe "BVH3D Spatial Hierarchy", ->
  test-case "builds tree and filters plane-Z intersection queries with zero false negatives", ->
    cube = MeshPrimitives.create-box 20.0, 20.0, 20.0
    bvh = new BVH3D 2
    bvh.build cube.triangles

    # Slicing at Z = 10.0 (middle of cube)
    intersecting-triangles = bvh.query-plane-z 10.0
    # Calibration cube has 4 vertical side walls, each made of 2 triangles = 8 triangles crossing Z=10
    assert.ok intersecting-triangles.length >= 8

    # Slicing far outside at Z = 50.0 should return zero triangles
    outside-triangles = bvh.query-plane-z 50.0
    assert.strictEqual outside-triangles.length, 0

describe "SpatialHash Proximity Query", ->
  test-case "locates nearest 2D and 3D neighbor in O(1) time", ->
    hash2d = new SpatialHash2D 1.0
    hash2d.insert "target_A", 5.0, 5.0
    hash2d.insert "target_B", 20.0, 20.0

    nearest = hash2d.find-nearest 5.05, 5.02, 0.5
    assert.strictEqual nearest, "target_A"

    far = hash2d.find-nearest 10.0, 10.0, 0.5
    assert.strictEqual far, null

    hash3d = new SpatialHash3D 2.0
    hash3d.insert "node_1", 10.0, 10.0, 10.0
    nearest3d = hash3d.find-nearest 10.1, 9.9, 10.05, 1.0
    assert.strictEqual nearest3d, "node_1"

describe "Octree Partitioning", ->
  test-case "inserts points and retrieves range queries correctly", ->
    bounds = new AABB3D (new Vector3 0, 0, 0), (new Vector3 100, 100, 100)
    oct = new Octree bounds, 4, 4

    for i from 0 til 50
      oct.insert new Vector3 (i * 2), (i * 2), (i * 2), "pt_#i"

    query-box = new AABB3D (new Vector3 10, 10, 10), (new Vector3 30, 30, 30)
    results = oct.query-range query-box
    assert.ok results.length > 0
    for r in results
      assert.ok query-box.contains-point r.point
