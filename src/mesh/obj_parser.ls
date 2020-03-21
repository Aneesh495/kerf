# Wavefront OBJ Parser with N-gon triangulation
# Supports 3D vertices, vertex normals, texture coordinates, and face indexing

fs = require 'fs'
Vector3 = require '../math/vector3'
{ Mesh, Triangle } = require './mesh'

class OBJParser
  @parse-text = (text) ->
    mesh = new Mesh!
    vertices = []
    normals = []

    lines = text.split /\r?\n/
    for line in lines
      trimmed = line.trim!
      if trimmed.length == 0 or trimmed.starts-with '#'
        continue

      parts = trimmed.split /\s+/
      type = parts[0]

      if type == 'v'
        # 3D Vertex: v x y z
        x = parse-float parts[1]
        y = parse-float parts[2]
        z = parse-float parts[3]
        vertices.push new Vector3 x, y, z

      else if type == 'vn'
        # Vertex normal: vn x y z
        nx = parse-float parts[1]
        ny = parse-float parts[2]
        nz = parse-float parts[3]
        normals.push new Vector3 nx, ny, nz

      else if type == 'f'
        # Face: f v1/vt1/vn1 v2/vt2/vn2 ...
        face-vert-indices = []
        for i from 1 til parts.length
          token = parts[i]
          sub-parts = token.split '/'
          v-idx = parse-int(sub-parts[0], 10)
          # OBJ 1-based indexing (and negative relative indexing)
          if v-idx < 0
            v-idx = vertices.length + v-idx
          else
            v-idx = v-idx - 1
          face-vert-indices.push v-idx

        # Triangulate polygons using triangle fan
        if face-vert-indices.length >= 3
          v0 = vertices[face-vert-indices[0]]
          for j from 1 til (face-vert-indices.length - 1)
            v1 = vertices[face-vert-indices[j]]
            v2 = vertices[face-vert-indices[j + 1]]
            if v0? and v1? and v2?
              mesh.add-face v0, v1, v2

    mesh

  @parse-file = (filepath) ->
    text = fs.read-file-sync filepath, 'utf8'
    @parse-text text

module.exports = OBJParser
