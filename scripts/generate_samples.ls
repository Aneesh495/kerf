# Sample model generator for testbed validation and digital fabrication runs

fs = require 'fs'
path = require 'path'
{ MeshPrimitives, STLWriter, OBJWriter } = require '../src/index'

samples-dir = path.join __dirname, '..', 'samples'
if not fs.exists-sync samples-dir
  fs.mkdir-sync samples-dir, { recursive: true }

console.log "Generating digital fabrication sample assets in #samples-dir..."

# 1. Standard 20mm Calibration Cube (Binary STL)
cube = MeshPrimitives.create-box 20.0, 20.0, 20.0
cube-path = path.join samples-dir, 'calibration_cube.stl'
STLWriter.write-file cube, cube-path, true
console.log "  ✓ Created #cube-path (Binary STL)"

# 2. Precision Mechanical Involute Gear (Binary STL)
gear = MeshPrimitives.create-gear 12, 15.0, 3.0, 5.0
gear-path = path.join samples-dir, 'mechanical_gear.stl'
STLWriter.write-file gear, gear-path, true
console.log "  ✓ Created #gear-path (Binary STL)"

# 3. Precision Machining Cylinder (Wavefront OBJ)
cyl = MeshPrimitives.create-cylinder 8.0, 25.0, 24
cyl-path = path.join samples-dir, 'bearing_cylinder.obj'
OBJWriter.write-file cyl, cyl-path, 'bearing_cylinder'
console.log "  ✓ Created #cyl-path (Wavefront OBJ)"

# 4. Curvature Benchmark Dome Sphere (Wavefront OBJ)
sphere = MeshPrimitives.create-sphere 12.0, 20, 20
sphere-path = path.join samples-dir, 'curvature_sphere.obj'
OBJWriter.write-file sphere, sphere-path, 'curvature_sphere'
console.log "  ✓ Created #sphere-path (Wavefront OBJ)"

console.log "All sample assets generated successfully."
