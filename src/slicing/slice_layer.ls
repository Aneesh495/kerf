# Sliced Layer Representation and Multi-Toolpath Registry
# Stores islands, holes, perimeter walls, infill paths, and kinematic metrics

class SliceLayer
  (layer-index = 0, z = 0.0, thickness = 0.2) ->
    @layer-index = layer-index
    @z = +z
    @thickness = +thickness
    @islands = []          # Array of IslandNode
    @perimeters = []       # Array of Polygon2D perimeter toolpaths
    @infill-paths = []     # Array of Segment2D infill extrusion paths
    @support-paths = []    # Array of Segment2D support extrusion paths
    @travel-moves = []     # Array of Segment2D non-extrusion rapid travels
    @print-time-sec = 0.0
    @filament-mm = 0.0

  add-island: (island-node) ->
    @islands.push island-node
    @

  total-extrusion-length: ->
    len = 0.0
    for p in @perimeters
      len += p.perimeter!
    for s in @infill-paths
      len += s.length!
    for s in @support-paths
      len += s.length!
    len

  total-travel-length: ->
    len = 0.0
    for s in @travel-moves
      len += s.length!
    len

module.exports = SliceLayer
