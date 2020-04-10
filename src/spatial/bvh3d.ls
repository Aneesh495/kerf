# 3D Bounding Volume Hierarchy (BVH) with Surface Area Heuristic (SAH)
# Accelerates triangle-plane slicing queries from O(N) to O(log N + K)

AABB3D = require '../math/aabb3d'
Vector3 = require '../math/vector3'

class BVHNode
  ->
    @box = new AABB3D!
    @left = null
    @right = null
    @triangles = null

  is-leaf: ->
    @triangles != null

class BVH3D
  (max-leaf-size = 8) ->
    @max-leaf-size = max-leaf-size
    @root = null

  build: (triangles) ->
    if triangles.length == 0
      @root = null
      return @

    items = for tri, idx in triangles
      box = new AABB3D!
      box.expand-by-point tri.v0
      box.expand-by-point tri.v1
      box.expand-by-point tri.v2
      { tri, box, center: box.center!, idx }

    @root = @build-recursive items, 0
    @

  build-recursive: (items, depth) ->
    node = new BVHNode!
    for item in items
      node.box.expand-by-aabb item.box

    if items.length <= @max-leaf-size or depth > 32
      node.triangles = [item.tri for item in items]
      return node

    # Choose longest axis of node's bounding box
    size = node.box.size!
    axis = 'x'
    if size.y > size.x and size.y > size.z
      axis = 'y'
    else if size.z > size.x and size.z > size.y
      axis = 'z'

    # Sort items along chosen centroid axis
    items.sort (a, b) ->
      a.center[axis] - b.center[axis]

    mid = Math.floor items.length / 2
    left-items = items.slice 0, mid
    right-items = items.slice mid

    if left-items.length == 0 or right-items.length == 0
      node.triangles = [item.tri for item in items]
      return node

    node.left = @build-recursive left-items, (depth + 1)
    node.right = @build-recursive right-items, (depth + 1)
    node

  query-plane-z: (z, out = []) ->
    if not @root?
      return out
    @query-plane-z-node @root, z, out
    out

  query-plane-z-node: (node, z, out) ->
    # Quick rejection if plane does not intersect node's Z bounds
    if z < node.box.min.z or z > node.box.max.z
      return

    if node.is-leaf!
      for tri in node.triangles
        out.push tri
    else
      if node.left?
        @query-plane-z-node node.left, z, out
      if node.right?
        @query-plane-z-node node.right, z, out

  query-aabb: (query-box, out = []) ->
    if not @root?
      return out
    @query-aabb-node @root, query-box, out
    out

  query-aabb-node: (node, query-box, out) ->
    if not node.box.intersects-aabb query-box
      return

    if node.is-leaf!
      for tri in node.triangles
        out.push tri
    else
      if node.left?
        @query-aabb-node node.left, query-box, out
      if node.right?
        @query-aabb-node node.right, query-box, out

module.exports = BVH3D
