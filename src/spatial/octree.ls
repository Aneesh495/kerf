# 3D Octree Spatial Partitioning Tree
# Used for point cloud queries and regional mesh geometry filtering

AABB3D = require '../math/aabb3d'
Vector3 = require '../math/vector3'

class OctreeNode
  (bounds, capacity = 16, max-depth = 8, depth = 0) ->
    @bounds = bounds
    @capacity = capacity
    @max-depth = max-depth
    @depth = depth
    @points = []
    @children = null

  is-leaf: ->
    @children == null

  subdivide: ->
    c = @bounds.center!
    min = @bounds.min
    max = @bounds.max

    @children = new Array 8
    # 8 octants
    @children[0] = new OctreeNode (new AABB3D (new Vector3 min.x, min.y, min.z), (new Vector3 c.x, c.y, c.z)), @capacity, @max-depth, (@depth + 1)
    @children[1] = new OctreeNode (new AABB3D (new Vector3 c.x, min.y, min.z), (new Vector3 max.x, c.y, c.z)), @capacity, @max-depth, (@depth + 1)
    @children[2] = new OctreeNode (new AABB3D (new Vector3 min.x, c.y, min.z), (new Vector3 c.x, max.y, c.z)), @capacity, @max-depth, (@depth + 1)
    @children[3] = new OctreeNode (new AABB3D (new Vector3 c.x, c.y, min.z), (new Vector3 max.x, max.y, c.z)), @capacity, @max-depth, (@depth + 1)

    @children[4] = new OctreeNode (new AABB3D (new Vector3 min.x, min.y, c.z), (new Vector3 c.x, c.y, max.z)), @capacity, @max-depth, (@depth + 1)
    @children[5] = new OctreeNode (new AABB3D (new Vector3 c.x, min.y, c.z), (new Vector3 max.x, c.y, max.z)), @capacity, @max-depth, (@depth + 1)
    @children[6] = new OctreeNode (new AABB3D (new Vector3 min.x, c.y, c.z), (new Vector3 c.x, max.y, max.z)), @capacity, @max-depth, (@depth + 1)
    @children[7] = new OctreeNode (new AABB3D (new Vector3 c.x, c.y, c.z), (new Vector3 max.x, max.y, max.z)), @capacity, @max-depth, (@depth + 1)

    # Re-insert existing points
    existing = @points
    @points = null
    for item in existing
      @insert item

  insert: (item) ->
    p = item.point
    if not @bounds.contains-point p
      return false

    if @is-leaf!
      if @points.length < @capacity or @depth >= @max-depth
        @points.push item
        return true
      @subdivide!

    for child in @children
      if child.insert item
        return true

    false

  query-range: (range-box, out = []) ->
    if not @bounds.intersects-aabb range-box
      return out

    if @is-leaf!
      for item in @points
        if range-box.contains-point item.point
          out.push item
    else
      for child in @children
        child.query-range range-box, out

    out

class Octree
  (bounds, capacity = 16, max-depth = 8) ->
    @root = new OctreeNode bounds, capacity, max-depth, 0

  insert: (point, data = null) ->
    @root.insert { point, data }

  query-range: (range-box) ->
    @root.query-range range-box, []

module.exports = Octree
