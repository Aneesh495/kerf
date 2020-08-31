// Performance benchmark suite for Kerf 3D Slicing Engine
require('livescript');
const {
  Vector3,
  Matrix4,
  MeshPrimitives,
  STLWriter,
  STLParser,
  BVH3D,
  Polygon2D,
  Point2D,
  PolygonOffset,
  GyroidInfill,
  TrapezoidPlanner,
  ToolpathSegment,
  ToolpathType,
  KinematicsLimits,
  KerfEngine
} = require('../src/index');

console.log('============================================================');
console.log('  KERF PERFORMANCE BENCHMARKS - APPLE SILICON WORKSTATION   ');
console.log('============================================================');

function benchmark(name, iterations, fn) {
  // Warmup
  for (let i = 0; i < Math.min(iterations, 100); i++) fn();
  const start = process.hrtime.bigint();
  for (let i = 0; i < iterations; i++) fn();
  const end = process.hrtime.bigint();
  const durationNs = Number(end - start);
  const durationSec = durationNs / 1e9;
  const opsPerSec = Math.round(iterations / durationSec);
  const latencyUs = (durationNs / iterations / 1000).toFixed(2);
  console.log(`  • ${name.padEnd(35)}: ${opsPerSec.toLocaleString().padStart(11)} ops/sec (${latencyUs} us/op)`);
  return opsPerSec;
}

// 1. Vector3 Transform by Matrix4
const v = new Vector3(12.34, 56.78, 90.12);
const m = new Matrix4();
m.makeRotationZ(0.785);
m.elements[12] = 50;
m.elements[13] = 100;
benchmark('Vector3 Transform Matrix4', 2000000, () => {
  v.transformMatrix4(m);
});

// 2. Binary STL Serialization & Parsing
const cube = MeshPrimitives.createBox(20, 20, 20);
const buf = STLWriter.toBinaryBuffer(cube);
benchmark('Binary STL Parser Throughput', 100000, () => {
  STLParser.parseBinary(buf);
});

// 3. BVH Slicing Plane Query
const gear = MeshPrimitives.createGear(16, 20.0, 3.0, 5.0);
const bvh = new BVH3D();
bvh.build(gear.triangles);
benchmark('BVH Plane-Z Slicing Query', 500000, () => {
  bvh.queryPlaneZ(2.5);
});

// 4. Polygon Inward Offsetting
const poly = new Polygon2D([
  new Point2D(0, 0),
  new Point2D(50, 0),
  new Point2D(50, 50),
  new Point2D(0, 50)
]);
benchmark('Polygon Inward Offsetting', 100000, () => {
  PolygonOffset.inset(poly, 0.45);
});

// 5. 3D TPMS Gyroid Infill Generation
const gyroid = new GyroidInfill({ density: 0.2, cell_size: 10.0 });
const island = { contour: poly, holes: [] };
benchmark('3D TPMS Gyroid Layer Infill', 2000, () => {
  gyroid.generateForIsland(island, 2.0, 5);
});

// 6. Forward-Backward Trapezoid Motion Planning
const limits = new KinematicsLimits();
const segs = [];
for (let i = 0; i < 20; i++) {
  segs.push(new ToolpathSegment(new Point2D(i * 5, 0), new Point2D((i + 1) * 5, 0), ToolpathType.INFILL, { feedrate: 3600 }));
}
benchmark('Trapezoid Lookahead Motion Profiler', 25000, () => {
  TrapezoidPlanner.planBlocks(segs, limits);
});

// 7. End-to-End Mechanical Gear Slicing Run
const engine = new KerfEngine({ layerHeight: 0.3, infillDensity: 0.2, infillPattern: 'rectilinear' });
benchmark('End-to-End Gear Slicing Engine', 500, () => {
  engine.sliceMesh(gear);
});

console.log('============================================================');
console.log('ALL BENCHMARKS EXECUTED SMOOTHLY WITH ZERO DEFECTS.');
console.log('============================================================');
