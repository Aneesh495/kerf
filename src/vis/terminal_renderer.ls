# High-Resolution ANSI 256-Color Terminal Slice Preview
# Visualizes perimeters, continuous infill, and rapid travels directly in stdout

class TerminalRenderer
  @render-layer = (layer, width = 60, height = 28) ->
    if layer.islands.length == 0
      return "  [Empty Layer Z = #{layer.z.toFixed 3}]"

    # Compute bounding box of layer
    min-x = Infinity; max-x = -Infinity
    min-y = Infinity; max-y = -Infinity

    for island in layer.islands
      b = island.contour.get-bounds!
      if b.min-x < min-x then min-x = b.min-x
      if b.max-x > max-x then max-x = b.max-x
      if b.min-y < min-y then min-y = b.min-y
      if b.max-y > max-y then max-y = b.max-y

    span-x = Math.max 1.0, (max-x - min-x)
    span-y = Math.max 1.0, (max-y - min-y)

    # 2D character buffer
    grid = []
    for r from 0 til height
      row = []
      for c from 0 til width
        row.push " "
      grid.push row

    # World to screen coordinates mapping (Y inverted for display)
    world-to-col = (x) ->
      norm = (x - min-x) / span-x
      Math.max 0, Math.min (width - 1), Math.floor(norm * (width - 1))

    world-to-row = (y) ->
      norm = (y - min-y) / span-y
      Math.max 0, Math.min (height - 1), Math.floor((1.0 - norm) * (height - 1))

    # Draw solid infill regions inside islands
    Point2D = require '../geometry2d/point2d'
    for r from 0 til height
      world-y = max-y - (r / (height - 1)) * span-y
      for c from 0 til width
        world-x = min-x + (c / (width - 1)) * span-x
        pt = new Point2D world-x, world-y
        for island in layer.islands
          if island.contour.contains-point pt
            # Check if inside hole
            in-hole = false
            for hole in island.holes
              if hole.contains-point pt
                in-hole = true
                break
            if not in-hole
              # Interior infill character
              grid[r][c] = "\x1b[33m.\x1b[0m" # Yellow/amber infill

    # Draw infill line segments with asterisks
    for seg in layer.infill-paths
      c1 = world-to-col seg.p1.x
      r1 = world-to-row seg.p1.y
      c2 = world-to-col seg.p2.x
      r2 = world-to-row seg.p2.y

      # Bresenham-style line rasterization
      dc = Math.abs(c2 - c1)
      dr = Math.abs(r2 - r1)
      sc = if c1 < c2 then 1 else -1
      sr = if r1 < r2 then 1 else -1
      err = dc - dr

      curr-c = c1
      curr-r = r1
      for step from 0 to (dc + dr)
        if curr-r >= 0 and curr-r < height and curr-c >= 0 and curr-c < width
          grid[curr-r][curr-c] = "\x1b[38;5;208m#\x1b[0m" # Orange infill line
        if curr-c == c2 and curr-r == r2
          break
        e2 = 2 * err
        if e2 > -dr
          err -= dr
          curr-c += sc
        if e2 < dc
          err += dc
          curr-r += sr

    # Draw perimeter boundaries
    draw-contour = (poly, color-code) ->
      pts = poly.points
      n = pts.length
      for i from 0 til n
        j = (i + 1) % n
        pA = pts[i]
        pB = pts[j]
        c1 = world-to-col pA.x
        r1 = world-to-row pA.y
        c2 = world-to-col pB.x
        r2 = world-to-row pB.y

        dc = Math.abs(c2 - c1)
        dr = Math.abs(r2 - r1)
        sc = if c1 < c2 then 1 else -1
        sr = if r1 < r2 then 1 else -1
        err = dc - dr

        curr-c = c1
        curr-r = r1
        for step from 0 to (dc + dr)
          if curr-r >= 0 and curr-r < height and curr-c >= 0 and curr-c < width
            grid[curr-r][curr-c] = "#{color-code}█\x1b[0m"
          if curr-c == c2 and curr-r == r2
            break
          e2 = 2 * err
          if e2 > -dr
            err -= dr
            curr-c += sc
          if e2 < dc
            err += dc
            curr-r += sr

    for island in layer.islands
      # Outer boundary in bold Cyan
      draw-contour island.contour, "\x1b[36;1m"
      # Holes in Magenta
      for hole in island.holes
        draw-contour hole, "\x1b[35m"

    # Assemble lines with border
    border = "+#{'-'.repeat width}+"
    out-lines = [
      "  Layer #{layer.layer-index} Preview (Z = #{layer.z.toFixed 3} mm)",
      "  #border"
    ]
    for row in grid
      out-lines.push "  |" + row.join('') + "|"
    out-lines.push "  #border"
    out-lines.push "  Legend: \x1b[36;1m█\x1b[0m Outer Wall  \x1b[35m█\x1b[0m Hole  \x1b[38;5;208m#\x1b[0m Infill Line  \x1b[33m.\x1b[0m Infill Core"
    out-lines.join "\n"

module.exports = TerminalRenderer
