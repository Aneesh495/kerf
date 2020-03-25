# Wavefront OBJ Serializer
# Exports meshes to clean OBJ format with deduplicated vertices and index tables

fs = require 'fs'

class OBJWriter
  @to-string = (mesh, name = "kerf_mesh") ->
    lines = [
      "# Wavefront OBJ exported by Kerf 3D Slicing Engine",
      "o #name"
    ]

    vert-map = {}
    unique-verts = []
    tri-indices = []

    get-vert-id = (p) ->
      key = "#{p.x.toFixed 6},#{p.y.toFixed 6},#{p.z.toFixed 6}"
      if vert-map[key]?
        vert-map[key]
      else
        idx = unique-verts.length
        vert-map[key] = idx
        unique-verts.push p
        idx

    for tri in mesh.triangles
      i0 = get-vert-id(tri.v0) + 1
      i1 = get-vert-id(tri.v1) + 1
      i2 = get-vert-id(tri.v2) + 1
      tri-indices.push [i0, i1, i2]

    # Write vertex coordinates
    for v in unique-verts
      lines.push "v #{v.x.toFixed 6} #{v.y.toFixed 6} #{v.z.toFixed 6}"

    # Write triangular faces
    for idxs in tri-indices
      lines.push "f #{idxs[0]} #{idxs[1]} #{idxs[2]}"

    lines.join "\n"

  @write-file = (mesh, filepath, name = "kerf_mesh") ->
    content = @to-string mesh, name
    fs.write-file-sync filepath, content, 'utf8'

module.exports = OBJWriter
