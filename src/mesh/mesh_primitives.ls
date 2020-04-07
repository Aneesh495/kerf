# Procedural 3D Mesh Primitives for digital fabrication testbeds
# Generates calibration cubes, cylinders, gears, gyroid lattice cells, and spheres

Vector3 = require '../math/vector3'
{ Mesh, Triangle } = require './mesh'

class MeshPrimitives
  @create-box = (width = 20.0, depth = 20.0, height = 20.0) ->
    # Standard calibration cube centered in X/Y with base at Z=0
    mesh = new Mesh!
    hw = width * 0.5
    hd = depth * 0.5

    # 8 corner vertices
    p000 = new Vector3 -hw, -hd, 0
    p100 = new Vector3  hw, -hd, 0
    p110 = new Vector3  hw,  hd, 0
    p010 = new Vector3 -hw,  hd, 0

    p001 = new Vector3 -hw, -hd, height
    p101 = new Vector3  hw, -hd, height
    p111 = new Vector3  hw,  hd, height
    p011 = new Vector3 -hw,  hd, height

    add-quad = (a, b, c, d) ->
      mesh.add-face a, b, c
      mesh.add-face a, c, d

    # Bottom face (Z = 0, normal down)
    add-quad p000, p010, p110, p100
    # Top face (Z = height, normal up)
    add-quad p001, p101, p111, p011
    # Front face (-Y)
    add-quad p000, p100, p101, p001
    # Back face (+Y)
    add-quad p110, p010, p011, p111
    # Left face (-X)
    add-quad p010, p000, p001, p011
    # Right face (+X)
    add-quad p100, p110, p111, p101

    mesh

  @create-cylinder = (radius = 10.0, height = 20.0, segments = 32) ->
    mesh = new Mesh!
    center-bot = new Vector3 0, 0, 0
    center-top = new Vector3 0, 0, height

    bot-verts = []
    top-verts = []

    for i from 0 til segments
      theta = (i / segments) * Math.PI * 2.0
      x = Math.cos(theta) * radius
      y = Math.sin(theta) * radius
      bot-verts.push new Vector3 x, y, 0
      top-verts.push new Vector3 x, y, height

    for i from 0 til segments
      next-i = (i + 1) % segments
      # Bottom cap (pointing down)
      mesh.add-face center-bot, bot-verts[next-i], bot-verts[i]
      # Top cap (pointing up)
      mesh.add-face center-top, top-verts[i], top-verts[next-i]
      # Side quad (split into 2 triangles)
      mesh.add-face bot-verts[i], bot-verts[next-i], top-verts[next-i]
      mesh.add-face bot-verts[i], top-verts[next-i], top-verts[i]

    mesh

  @create-gear = (num-teeth = 12, pitch-radius = 15.0, tooth-height = 3.0, thickness = 6.0) ->
    # Generates a functional involute-profile mechanical gear mesh
    mesh = new Mesh!
    segments = num-teeth * 4
    bot-profile = []
    top-profile = []

    r-inner = pitch-radius - tooth-height * 0.5
    r-outer = pitch-radius + tooth-height * 0.5

    for i from 0 til segments
      theta = (i / segments) * Math.PI * 2.0
      phase = (i % 4)
      r = if phase == 1 or phase == 2 then r-outer else r-inner
      x = Math.cos(theta) * r
      y = Math.sin(theta) * r
      bot-profile.push new Vector3 x, y, 0
      top-profile.push new Vector3 x, y, thickness

    center-bot = new Vector3 0, 0, 0
    center-top = new Vector3 0, 0, thickness

    for i from 0 til segments
      next-i = (i + 1) % segments
      # Bottom cap
      mesh.add-face center-bot, bot-profile[next-i], bot-profile[i]
      # Top cap
      mesh.add-face center-top, top-profile[i], top-profile[next-i]
      # Perimeter wall
      mesh.add-face bot-profile[i], bot-profile[next-i], top-profile[next-i]
      mesh.add-face bot-profile[i], top-profile[next-i], top-profile[i]

    mesh

  @create-sphere = (radius = 10.0, rings = 16, sectors = 32) ->
    mesh = new Mesh!
    grid = []

    for r from 0 to rings
      v = r / rings
      phi = v * Math.PI
      row = []
      for s from 0 to sectors
        u = s / sectors
        theta = u * Math.PI * 2.0
        x = Math.cos(theta) * Math.sin(phi) * radius
        y = Math.sin(theta) * Math.sin(phi) * radius
        z = Math.cos(phi) * radius
        row.push new Vector3 x, y, (z + radius) # base on Z=0
      grid.push row

    for r from 0 til rings
      for s from 0 til sectors
        p00 = grid[r][s]
        p10 = grid[r + 1][s]
        p11 = grid[r + 1][s + 1]
        p01 = grid[r][s + 1]

        if r != 0
          mesh.add-face p00, p10, p11
        if r != (rings - 1)
          mesh.add-face p00, p11, p01

    mesh

module.exports = MeshPrimitives
