# STL (Stereolithography) Format Parser
# Supports both Little-Endian Binary STL and ASCII STL with format auto-detection

fs = require 'fs'
Vector3 = require '../math/vector3'
{ Mesh, Triangle } = require './mesh'

class STLParser
  @parse-buffer = (buffer) ->
    if @is-binary buffer
      @parse-binary buffer
    else
      @parse-ascii buffer.to-string('utf8')

  @parse-file = (filepath) ->
    buf = fs.read-file-sync filepath
    @parse-buffer buf

  @is-binary = (buffer) ->
    if buffer.length < 84
      return false

    # Check if header contains "solid"
    header-str = buffer.to-string('utf8', 0, Math.min(80, buffer.length))
    if not header-str.starts-with 'solid'
      return true

    # Header starts with solid, but many CAD packages put solid in binary header.
    # Check expected size against file length.
    expected-count = buffer.read-uint32-LE 80
    expected-size = 84 + expected-count * 50
    if buffer.length == expected-size
      return true

    # Check for null bytes in first 512 bytes
    limit = Math.min buffer.length, 512
    for i from 0 til limit
      if buffer[i] == 0
        return true

    false

  @parse-binary = (buffer) ->
    mesh = new Mesh!
    tri-count = buffer.read-uint32-LE 80
    offset = 84

    for i from 0 til tri-count
      if offset + 50 > buffer.length
        break

      # Read face normal (float32 x 3)
      nx = buffer.read-float-LE offset
      ny = buffer.read-float-LE (offset + 4)
      nz = buffer.read-float-LE (offset + 8)
      normal = new Vector3 nx, ny, nz

      # Read vertex 0
      v0x = buffer.read-float-LE (offset + 12)
      v0y = buffer.read-float-LE (offset + 16)
      v0z = buffer.read-float-LE (offset + 20)
      v0 = new Vector3 v0x, v0y, v0z

      # Read vertex 1
      v1x = buffer.read-float-LE (offset + 24)
      v1y = buffer.read-float-LE (offset + 28)
      v1z = buffer.read-float-LE (offset + 32)
      v1 = new Vector3 v1x, v1y, v1z

      # Read vertex 2
      v2x = buffer.read-float-LE (offset + 36)
      v2y = buffer.read-float-LE (offset + 40)
      v2z = buffer.read-float-LE (offset + 44)
      v2 = new Vector3 v2x, v2y, v2z

      # Attribute byte count (uint16 at offset + 48) ignored
      mesh.add-face v0, v1, v2, normal
      offset += 50

    mesh

  @parse-ascii = (text) ->
    mesh = new Mesh!
    lines = text.split /\r?\n/
    current-normal = null
    current-verts = []

    for line in lines
      trimmed = line.trim!
      if trimmed.length == 0
        continue

      parts = trimmed.split /\s+/
      keyword = parts[0].to-lower-case!

      if keyword == 'facet' and parts[1]? and parts[1].to-lower-case! == 'normal'
        current-normal = new Vector3(
          parse-float(parts[2]),
          parse-float(parts[3]),
          parse-float(parts[4])
        )
      else if keyword == 'vertex'
        current-verts.push new Vector3(
          parse-float(parts[1]),
          parse-float(parts[2]),
          parse-float(parts[3])
        )
        if current-verts.length == 3
          mesh.add-face current-verts[0], current-verts[1], current-verts[2], current-normal
          current-verts = []
      else if keyword == 'endfacet'
        current-verts = []
        current-normal = null

    mesh

module.exports = STLParser
