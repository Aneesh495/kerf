# 7-Segment S-Curve Jerk-Limited Motion Profiler
# Smooths acceleration transitions to eliminate structural vibration and resonance ringing

class SCurvePlanner
  @compute-profile = (distance, v0, v1, vmax, amax, jmax) ->
    # Calculates 7-segment S-curve trajectory:
    # Segment 1: Jerk ramp-up (+jmax)
    # Segment 2: Constant acceleration (+amax)
    # Segment 3: Jerk ramp-down (-jmax)
    # Segment 4: Constant cruise speed (vmax)
    # Segment 5: Jerk ramp-up decel (-jmax)
    # Segment 6: Constant deceleration (-amax)
    # Segment 7: Jerk ramp-down decel (+jmax)

    if distance < 1e-6
      return { total-time: 0.0, reachable-v: v0 }

    # Time to ramp acceleration from 0 to amax: tj = amax / jmax
    tj = amax / jmax
    # Speed change during jerk phase: dv_j = 0.5 * amax * tj
    dv-j = 0.5 * amax * tj

    # If speed change to cruise is smaller than 2 * dv_j, acceleration doesn't reach amax
    dv-acc = Math.max 0.0, (vmax - v0)
    if dv-acc < (2.0 * dv-j)
      # Triangular jerk profile
      tj = Math.sqrt(dv-acc / jmax)
      ta = 0.0
    else
      ta = (dv-acc - 2.0 * dv-j) / amax

    t-accel-total = 2.0 * tj + ta
    d-accel = v0 * t-accel-total + 0.5 * amax * (t-accel-total * t-accel-total)

    dv-dec = Math.max 0.0, (vmax - v1)
    if dv-dec < (2.0 * dv-j)
      tj-dec = Math.sqrt(dv-dec / jmax)
      td = 0.0
    else
      td = (dv-dec - 2.0 * dv-j) / amax

    t-decel-total = 2.0 * tj + td
    d-decel = vmax * t-decel-total - 0.5 * amax * (t-decel-total * t-decel-total)

    # Cruise distance
    d-cruise = distance - d-accel - d-decel
    if d-cruise > 0
      t-cruise = d-cruise / vmax
      total-time = t-accel-total + t-cruise + t-decel-total
      { total-time, cruise-speed: vmax }
    else
      # Does not reach full vmax
      scaled-t = Math.sqrt(distance / (0.5 * amax))
      { total-time: scaled-t, cruise-speed: Math.min(vmax, Math.sqrt(2.0 * amax * distance)) }

module.exports = SCurvePlanner
