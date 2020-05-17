# Abstract Base Infill Generator
# Handles density calculations, scanline clipping to boundary islands, and hole exclusion

Point2D = require '../geometry2d/point2d'
Segment2D = require '../geometry2d/segment2d'
PolygonClipper = require '../geometry2d/polygon_clipper'

class InfillBase
  (opts = {}) ->
    @density = if opts.density? then Math.max 0.01, Math.min 1.0, +opts.density else 0.2
    @extrusion-width = opts.extrusion-width or 0.45
    @angle = opts.angle or (Math.PI / 4.0) # Default 45 degrees
    @line-spacing = @extrusion-width / @density

  clip-to-island: (raw-segments, island) ->
    # Clips segments so they lie strictly inside island contour and outside any holes
    if raw-segments.length == 0
      return []

    # Step 1: Clip segments to outer boundary contour
    outer-clipped = []
    for seg in raw-segments
      sub-segs = PolygonClipper.clip-segment-to-polygon seg, island.contour
      for s in sub-segs
        outer-clipped.push s

    if island.holes.length == 0
      return outer-clipped

    # Step 2: Carve out holes
    # A segment is kept if its midpoint does not fall inside any hole
    final-segments = []
    for seg in outer-clipped
      # Break segment against all hole boundaries
      broken = [seg]
      for hole in island.holes
        next-broken = []
        for piece in broken
          # Clip piece against hole
          hole-sub = PolygonClipper.clip-segment-to-polygon piece, hole
          if hole-sub.length == 0
            # Piece does not cross hole, check if piece is inside hole
            mid = piece.p1.lerp piece.p2, 0.5
            if not hole.contains-point mid
              next-broken.push piece
          else
            # Piece intersects hole: subtract hole intervals
            # Collect intersection points
            pts = [piece.p1]
            for hs in hole-sub
              pts.push hs.p1
              pts.push hs.p2
            pts.push piece.p2

            # Sort along piece direction
            dir = piece.p2.sub piece.p1
            pts.sort (a, b) ->
              (a.sub piece.p1).dot(dir) - (b.sub piece.p1).dot(dir)

            for idx from 0 til (pts.length - 1)
              sub-p1 = pts[idx]
              sub-p2 = pts[idx + 1]
              if sub-p1.distance-to(sub-p2) > 1e-6
                sub-mid = sub-p1.lerp sub-p2, 0.5
                if not hole.contains-point sub-mid
                  next-broken.push new Segment2D sub-p1, sub-p2
        broken = next-broken

      for valid-piece in broken
        final-segments.push valid-piece

    final-segments

  generate-for-island: (island, z = 0.0, layer-index = 0) ->
    throw new Error "generate-for-island must be implemented by subclass"

module.exports = InfillBase
