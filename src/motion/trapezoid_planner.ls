# Forward-Backward Lookahead Trapezoidal Motion Planner
# Computes entry, cruise, and exit velocities satisfying acceleration limits

class MotionBlock
  (segment, nominal-speed, max-accel) ->
    @segment = segment
    @nominal-speed = +nominal-speed # mm/sec
    @max-accel = +max-accel         # mm/sec^2
    @length = segment.length!
    @entry-speed = 0.0
    @exit-speed = 0.0
    @cruise-speed = 0.0
    @accel-dist = 0.0
    @cruise-dist = 0.0
    @decel-dist = 0.0
    @duration = 0.0

class TrapezoidPlanner
  @plan-blocks = (segments, limits) ->
    if segments.length == 0
      return []

    accel = limits.max-acceleration
    blocks = []

    for seg in segments
      # Convert feedrate mm/min to mm/sec
      nom-speed = Math.min limits.max-velocity, (seg.feedrate / 60.0)
      blocks.push new MotionBlock seg, nom-speed, accel

    n = blocks.length
    if n == 0
      return []

    # First pass: calculate allowable corner speeds between consecutive blocks
    corner-speeds = new Float64Array(n + 1)
    corner-speeds[0] = 0.0     # Machine starts from stop
    corner-speeds[n] = 0.0     # Machine finishes at stop

    JunctionDeviation = require './junction_deviation'
    for i from 1 til n
      prev-dir = blocks[i - 1].segment.p2.sub(blocks[i - 1].segment.p1).normalize!
      curr-dir = blocks[i].segment.p2.sub(blocks[i].segment.p1).normalize!
      corner-v = JunctionDeviation.calculate-corner-speed prev-dir, curr-dir, accel, limits.junction-dev
      # Cannot exceed nominal speeds of either adjacent block
      corner-speeds[i] = Math.min blocks[i - 1].nominal-speed, blocks[i].nominal-speed, corner-v

    # Backward Pass: limit entry speeds based on deceleration capability
    # v_entry <= sqrt(v_exit^2 + 2 * a * d)
    for i from (n - 1) to 0 by -1
      d = blocks[i].length
      exit-v = corner-speeds[i + 1]
      max-entry-v = Math.sqrt(exit-v * exit-v + 2.0 * accel * d)
      corner-speeds[i] = Math.min corner-speeds[i], max-entry-v, blocks[i].nominal-speed

    # Forward Pass: limit exit speeds based on acceleration capability
    # v_exit <= sqrt(v_entry^2 + 2 * a * d)
    for i from 0 til n
      d = blocks[i].length
      entry-v = corner-speeds[i]
      max-exit-v = Math.sqrt(entry-v * entry-v + 2.0 * accel * d)
      corner-speeds[i + 1] = Math.min corner-speeds[i + 1], max-exit-v, blocks[i].nominal-speed

    # Final Pass: solve trapezoidal phases for each block
    for i from 0 til n
      block = blocks[i]
      d = block.length
      v-entry = corner-speeds[i]
      v-exit = corner-speeds[i + 1]
      v-nom = block.nominal-speed

      block.entry-speed = v-entry
      block.exit-speed = v-exit

      if d < 1e-6
        block.duration = 0.0
        continue

      # Maximum speed reachable in this block:
      # v_peak^2 = (2 * a * d + v_entry^2 + v_exit^2) / 2
      v-peak-sq = (2.0 * accel * d + v-entry * v-entry + v-exit * v-exit) * 0.5
      v-peak = Math.sqrt(Math.max 0.0, v-peak-sq)

      if v-peak <= v-nom
        # Triangular profile: no cruise phase
        block.cruise-speed = v-peak
        block.accel-dist = (v-peak * v-peak - v-entry * v-entry) / (2.0 * accel)
        block.decel-dist = (v-peak * v-peak - v-exit * v-exit) / (2.0 * accel)
        block.cruise-dist = 0.0

        t-acc = (v-peak - v-entry) / accel
        t-dec = (v-peak - v-exit) / accel
        block.duration = t-acc + t-dec
      else
        # Trapezoidal profile: acceleration, cruise, deceleration
        block.cruise-speed = v-nom
        block.accel-dist = (v-nom * v-nom - v-entry * v-entry) / (2.0 * accel)
        block.decel-dist = (v-nom * v-nom - v-exit * v-exit) / (2.0 * accel)
        block.cruise-dist = d - block.accel-dist - block.decel-dist

        t-acc = (v-nom - v-entry) / accel
        t-dec = (v-nom - v-exit) / accel
        t-cruise = block.cruise-dist / v-nom
        block.duration = t-acc + t-cruise + t-dec

    blocks

module.exports = {
  MotionBlock
  TrapezoidPlanner
}
