# Spatial Hash Grid for O(1) amortized geometric proximity queries
# Enables nanometer coordinate snapping and contour endpoint connection

class SpatialHash2D
  (cell-size = 0.1) ->
    @cell-size = +cell-size
    @inv-cell-size = 1.0 / @cell-size
    @table = new Map!

  _key: (x, y) ->
    gx = Math.floor x * @inv-cell-size
    gy = Math.floor y * @inv-cell-size
    "#gx:#gy"

  insert: (item, x, y) ->
    key = @_key x, y
    bucket = @table.get key
    if not bucket?
      bucket = []
      @table.set key, bucket
    bucket.push { item, x: +x, y: +y }
    @

  find-nearest: (x, y, max-radius = null) ->
    max-r = if max-radius? then +max-radius else @cell-size
    max-r-sq = max-r * max-r

    min-gx = Math.floor (x - max-r) * @inv-cell-size
    max-gx = Math.floor (x + max-r) * @inv-cell-size
    min-gy = Math.floor (y - max-r) * @inv-cell-size
    max-gy = Math.floor (y + max-r) * @inv-cell-size

    closest = null
    min-dist-sq = Infinity

    for gx from min-gx to max-gx
      for gy from min-gy to max-gy
        key = "#gx:#gy"
        bucket = @table.get key
        if bucket?
          for entry in bucket
            dx = entry.x - x
            dy = entry.y - y
            d-sq = dx * dx + dy * dy
            if d-sq <= max-r-sq and d-sq < min-dist-sq
              min-dist-sq = d-sq
              closest = entry.item

    closest

  clear: ->
    @table.clear!

class SpatialHash3D
  (cell-size = 1.0) ->
    @cell-size = +cell-size
    @inv-cell-size = 1.0 / @cell-size
    @table = new Map!

  _key: (x, y, z) ->
    gx = Math.floor x * @inv-cell-size
    gy = Math.floor y * @inv-cell-size
    gz = Math.floor z * @inv-cell-size
    "#gx:#gy:#gz"

  insert: (item, x, y, z) ->
    key = @_key x, y, z
    bucket = @table.get key
    if not bucket?
      bucket = []
      @table.set key, bucket
    bucket.push { item, x: +x, y: +y, z: +z }
    @

  find-nearest: (x, y, z, max-radius = null) ->
    max-r = if max-radius? then +max-radius else @cell-size
    max-r-sq = max-r * max-r

    min-gx = Math.floor (x - max-r) * @inv-cell-size
    max-gx = Math.floor (x + max-r) * @inv-cell-size
    min-gy = Math.floor (y - max-r) * @inv-cell-size
    max-gy = Math.floor (y + max-r) * @inv-cell-size
    min-gz = Math.floor (z - max-r) * @inv-cell-size
    max-gz = Math.floor (z + max-r) * @inv-cell-size

    closest = null
    min-dist-sq = Infinity

    for gx from min-gx to max-gx
      for gy from min-gy to max-gy
        for gz from min-gz to max-gz
          key = "#gx:#gy:#gz"
          bucket = @table.get key
          if bucket?
            for entry in bucket
              dx = entry.x - x
              dy = entry.y - y
              dz = entry.z - z
              d-sq = dx * dx + dy * dy + dz * dz
              if d-sq <= max-r-sq and d-sq < min-dist-sq
                min-dist-sq = d-sq
                closest = entry.item

    closest

  clear: ->
    @table.clear!

module.exports = {
  SpatialHash2D
  SpatialHash3D
}
