# High-Fidelity SVG Vector Graphic Layer Exporter
# Generates publication-quality scalable vector graphics with move-type color coding

fs = require 'fs'

class SVGExporter
  @export-layer-to-svg = (layer, opts = {}) ->
    width = opts.width or 800
    height = opts.height or 800
    margin = opts.margin or 40

    # Calculate layer bounding box
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
    scale = Math.min (width - 2 * margin) / span-x, (height - 2 * margin) / span-y

    tx = margin - min-x * scale
    ty = height - margin + min-y * scale # Invert Y

    # Map world (x, y) to SVG screen coordinates
    sx = (x) -> (tx + x * scale).toFixed 2
    sy = (y) -> (ty - y * scale).toFixed 2

    lines = [
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + width + ' ' + height + '" width="' + width + '" height="' + height + '" style="background:#121316; font-family: monospace;">',
      '  <defs>',
      '    <filter id="glow"><feGaussianBlur stdDeviation="1.5" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
      '  </defs>',
      '  <text x="30" y="40" fill="#e0e0e0" font-size="16" font-weight="bold">Kerf Slicing Engine - Layer ' + layer.layer-index + ' (Z = ' + layer.z.toFixed(3) + ' mm)</text>',
      '  <g id="rapid-travels" stroke="#333842" stroke-width="0.8" stroke-dasharray="2,3">'
    ]

    for seg in layer.travel-moves
      lines.push '    <line x1="' + sx(seg.p1.x) + '" y1="' + sy(seg.p1.y) + '" x2="' + sx(seg.p2.x) + '" y2="' + sy(seg.p2.y) + '"/>'
    lines.push '  </g>'

    # Infill paths
    lines.push '  <g id="infill" stroke="#ff9100" stroke-width="1.2" opacity="0.85">'
    for seg in layer.infill-paths
      lines.push '    <line x1="' + sx(seg.p1.x) + '" y1="' + sy(seg.p1.y) + '" x2="' + sx(seg.p2.x) + '" y2="' + sy(seg.p2.y) + '"/>'
    lines.push '  </g>'

    # Inner perimeters
    lines.push '  <g id="inner-perimeters" stroke="#2979ff" stroke-width="1.5" fill="none">'
    for poly in layer.perimeters
      pts = poly.points
      if pts.length >= 2
        d-str = "M " + sx(pts[0].x) + " " + sy(pts[0].y) + " " + [ "L " + sx(p.x) + " " + sy(p.y) for p in pts.slice(1) ].join(" ") + " Z"
        lines.push '    <path d="' + d-str + '"/>'
    lines.push '  </g>'

    # Outer boundaries
    lines.push '  <g id="outer-boundaries" stroke="#00e5ff" stroke-width="2.2" fill="none" filter="url(#glow)">'
    for island in layer.islands
      pts = island.contour.points
      if pts.length >= 2
        d-str = "M " + sx(pts[0].x) + " " + sy(pts[0].y) + " " + [ "L " + sx(p.x) + " " + sy(p.y) for p in pts.slice(1) ].join(" ") + " Z"
        lines.push '    <path d="' + d-str + '"/>'
    lines.push '  </g>'

    # Holes
    lines.push '  <g id="holes" stroke="#d500f9" stroke-width="1.8" fill="none">'
    for island in layer.islands
      for hole in island.holes
        pts = hole.points
        if pts.length >= 2
          d-str = "M " + sx(pts[0].x) + " " + sy(pts[0].y) + " " + [ "L " + sx(p.x) + " " + sy(p.y) for p in pts.slice(1) ].join(" ") + " Z"
          lines.push '    <path d="' + d-str + '"/>'
    lines.push '  </g>'

    lines.push '</svg>'
    lines.join "\n"

  @write-file = (layer, filepath, opts = {}) ->
    content = @export-layer-to-svg layer, opts
    fs.write-file-sync filepath, content, 'utf8'

module.exports = SVGExporter
