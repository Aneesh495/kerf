# Topological Island and Hole Nesting Hierarchy
# Resolves Jordan curve nesting trees to separate solid boundaries from hollow voids

Polygon2D = require '../geometry2d/polygon2d'

class IslandNode
  (contour) ->
    @contour = contour.clone!
    @contour.ensure-ccw!
    @holes = []
    @children = []

  add-hole: (hole-poly) ->
    h = hole-poly.clone!
    h.ensure-cw!
    @holes.push h
    @

  add-child: (child-island) ->
    @children.push child-island
    @

  area: ->
    net-area = @contour.area!
    for h in @holes
      net-area -= h.area!
    for c in @children
      net-area += c.area!
    net-area

class TopologyTree
  @build = (polygons) ->
    if polygons.length == 0
      return []

    # Sort polygons descending by area (outermost contours have larger area)
    sorted = [p.clone! for p in polygons]
    sorted.sort (a, b) -> b.area! - a.area!

    # Determine containment matrix: contains[i][j] = true if sorted[i] contains sorted[j]
    n = sorted.length
    contains = new Array n
    for i from 0 til n
      contains[i] = new Array n
      for j from 0 til n
        if i == j
          contains[i][j] = false
        else if sorted[i].area! <= sorted[j].area!
          contains[i][j] = false
        else
          # Test if a representative vertex of polygon j is inside polygon i
          test-pt = sorted[j].points[0]
          contains[i][j] = sorted[i].contains-point test-pt

    # Count how many parents each polygon has
    parent-counts = new Array n
    for j from 0 til n
      cnt = 0
      for i from 0 til n
        if contains[i][j]
          cnt += 1
      parent-counts[j] = cnt

    # Even number of parents = solid island (depth 0, 2, 4...)
    # Odd number of parents = hole (depth 1, 3, 5...)
    nodes = new Map!
    root-islands = []

    # First pass: create all IslandNodes for even depth
    for i from 0 til n
      if (parent-counts[i] % 2) == 0
        node = new IslandNode sorted[i]
        nodes.set i, node
        if parent-counts[i] == 0
          root-islands.push node

    # Second pass: assign holes to their immediate enclosing island
    for j from 0 til n
      if (parent-counts[j] % 2) == 1
        # Find immediate parent island: smallest enclosing island
        best-parent = -1
        min-parent-area = Infinity
        for i from 0 til n
          if contains[i][j] and (parent-counts[i] % 2) == 0
            if sorted[i].area! < min-parent-area
              min-parent-area = sorted[i].area!
              best-parent = i
        if best-parent != -1 and nodes.has best-parent
          nodes.get(best-parent).add-hole sorted[j]

    # Third pass: assign nested child islands (depth >= 2) to their enclosing hole/island
    for j from 0 til n
      if parent-counts[j] >= 2 and (parent-counts[j] % 2) == 0
        # Find immediate enclosing island
        best-parent = -1
        min-parent-area = Infinity
        for i from 0 til n
          if contains[i][j] and parent-counts[i] < parent-counts[j] and (parent-counts[i] % 2) == 0
            if sorted[i].area! < min-parent-area
              min-parent-area = sorted[i].area!
              best-parent = i
        if best-parent != -1 and nodes.has best-parent and nodes.has j
          nodes.get(best-parent).add-child nodes.get(j)

    root-islands

module.exports = {
  IslandNode
  TopologyTree
}
