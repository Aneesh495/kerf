# Unit tests for mesh data structures, STL/OBJ serialization, and manifold repair

{ describe, test-case, assert, assert-approx } = require './test_runner_utils'
Vector3 = require '../src/math/vector3'
{ Mesh, Triangle } = require '../src/mesh/mesh'
MeshPrimitives = require '../src/mesh/mesh_primitives'
STLParser = require '../src/mesh/stl_parser'
STLWriter = require '../src/mesh/stl_writer'
OBJParser = require '../src/mesh/obj_parser'
OBJWriter = require '../src/mesh/obj_writer'
MeshRepair = require '../src/mesh/mesh_repair'

describe "Mesh Primitives and Topology", ->
  test-case "creates 3D calibration cube with exact volume and closed manifold", ->
    cube = MeshPrimitives.create-box 10.0, 10.0, 10.0
    assert.strictEqual cube.triangle-count!, 12
    bounds = cube.get-bounds!
    assert.strictEqual bounds.min.x, -5.0
    assert.strictEqual bounds.max.x, 5.0
    assert.strictEqual bounds.min.z, 0.0
    assert.strictEqual bounds.max.z, 10.0

    # Volume of 10x10x10 cube must equal 1000.0
    assert-approx cube.total-volume!, 1000.0, 1e-4
    # Surface area of 6 faces of 10x10 must equal 600.0
    assert-approx cube.total-surface-area!, 600.0, 1e-4

    stats = cube.get-edge-manifold-stats!
    assert.strictEqual stats.boundary-edges, 0
    assert.strictEqual stats.non-manifold-edges, 0
    assert.ok stats.is-closed

  test-case "creates cylinder and gear with manifold watertight hulls", ->
    cyl = MeshPrimitives.create-cylinder 5.0, 20.0, 16
    assert.ok cyl.triangle-count! > 0
    stats = cyl.get-edge-manifold-stats!
    assert.strictEqual stats.boundary-edges, 0
    assert.ok stats.is-closed

    gear = MeshPrimitives.create-gear 8, 10.0, 2.0, 4.0
    assert.ok gear.triangle-count! > 0
    gear-stats = gear.get-edge-manifold-stats!
    assert.strictEqual gear-stats.boundary-edges, 0
    assert.ok gear-stats.is-closed

describe "STL and OBJ Serialization Round-Trip", ->
  test-case "round-trips binary STL without geometry distortion", ->
    cube = MeshPrimitives.create-box 20.0, 20.0, 20.0
    buf = STLWriter.to-binary-buffer cube
    assert.ok buf.length >= 84 + 12 * 50

    loaded = STLParser.parse-buffer buf
    assert.strictEqual loaded.triangle-count!, 12
    assert-approx loaded.total-volume!, cube.total-volume!, 1e-3

  test-case "round-trips ASCII STL format accurately", ->
    cyl = MeshPrimitives.create-cylinder 5.0, 10.0, 12
    ascii-text = STLWriter.to-ascii cyl, "test_cylinder"
    assert.ok ascii-text.starts-with "solid test_cylinder"

    loaded = STLParser.parse-ascii ascii-text
    assert.strictEqual loaded.triangle-count!, cyl.triangle-count!
    assert-approx loaded.total-volume!, cyl.total-volume!, 1e-3

  test-case "round-trips Wavefront OBJ format accurately", ->
    cube = MeshPrimitives.create-box 15.0, 15.0, 15.0
    obj-text = OBJWriter.to-string cube, "cube_obj"
    assert.ok obj-text.includes "v "
    assert.ok obj-text.includes "f "

    loaded = OBJParser.parse-text obj-text
    assert.strictEqual loaded.triangle-count!, 12
    assert-approx loaded.total-volume!, cube.total-volume!, 1e-3

describe "Mesh Manifold Repair", ->
  test-case "prunes degenerate zero-area triangles", ->
    mesh = new Mesh!
    # Valid triangle
    mesh.add-face (new Vector3 0, 0, 0), (new Vector3 10, 0, 0), (new Vector3 0, 10, 0)
    # Degenerate triangle (collinear vertices)
    mesh.add-face (new Vector3 0, 0, 0), (new Vector3 5, 0, 0), (new Vector3 10, 0, 0)

    res = MeshRepair.prune-degenerate-triangles mesh
    assert.strictEqual res.pruned-count, 1
    assert.strictEqual res.mesh.triangle-count!, 1

  test-case "welds micro-gap separated vertices", ->
    mesh = new Mesh!
    # Two adjacent triangles with 0.00001 mm micro-gap
    mesh.add-face (new Vector3 0, 0, 0), (new Vector3 10, 0, 0), (new Vector3 10, 10, 0)
    mesh.add-face (new Vector3 0, 0.00001, 0), (new Vector3 10, 10.00001, 0), (new Vector3 0, 10, 0)

    res = MeshRepair.weld-vertices mesh, 1e-3
    assert.strictEqual res.mesh.triangle-count!, 2
