# STL (Stereolithography) Format Serializer
# Exports meshes to standard Binary and ASCII STL files

fs = require 'fs'

class STLWriter
  @to-binary-buffer = (mesh) ->
    tri-count = mesh.triangle-count!
    total-size = 84 + tri-count * 50
    buf = Buffer.alloc total-size

    # 80-byte header
    header-text = "Kerf 3D Slicing Engine - Binary STL Export"
    buf.write header-text, 0, 'utf8'

    # Triangle count at offset 80
    buf.write-uint32-LE tri-count, 80

    offset = 84
    for tri in mesh.triangles
      n = tri.normal
      buf.write-float-LE n.x, offset
      buf.write-float-LE n.y, (offset + 4)
      buf.write-float-LE n.z, (offset + 8)

      v0 = tri.v0
      buf.write-float-LE v0.x, (offset + 12)
      buf.write-float-LE v0.y, (offset + 16)
      buf.write-float-LE v0.z, (offset + 20)

      v1 = tri.v1
      buf.write-float-LE v1.x, (offset + 24)
      buf.write-float-LE v1.y, (offset + 28)
      buf.write-float-LE v1.z, (offset + 32)

      v2 = tri.v2
      buf.write-float-LE v2.x, (offset + 36)
      buf.write-float-LE v2.y, (offset + 40)
      buf.write-float-LE v2.z, (offset + 44)

      # Attribute byte count (uint16 = 0)
      buf.write-uint16-LE 0, (offset + 48)
      offset += 50

    buf

  @to-ascii = (mesh, solid-name = "kerf_model") ->
    lines = ["solid #solid-name"]
    for tri in mesh.triangles
      n = tri.normal
      lines.push "  facet normal #{n.x.to-exponential 6} #{n.y.to-exponential 6} #{n.z.to-exponential 6}"
      lines.push "    outer loop"
      lines.push "      vertex #{tri.v0.x.to-exponential 6} #{tri.v0.y.to-exponential 6} #{tri.v0.z.to-exponential 6}"
      lines.push "      vertex #{tri.v1.x.to-exponential 6} #{tri.v1.y.to-exponential 6} #{tri.v1.z.to-exponential 6}"
      lines.push "      vertex #{tri.v2.x.to-exponential 6} #{tri.v2.y.to-exponential 6} #{tri.v2.z.to-exponential 6}"
      lines.push "    endloop"
      lines.push "  endfacet"
    lines.push "endsolid #solid-name"
    lines.join "\n"

  @write-file = (mesh, filepath, binary = true) ->
    if binary
      buf = @to-binary-buffer mesh
      fs.write-file-sync filepath, buf
    else
      text = @to-ascii mesh
      fs.write-file-sync filepath, text, 'utf8'

module.exports = STLWriter
