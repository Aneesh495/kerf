# Viscoelastic Pressure Advance Extruder Dynamics Compensator
# Neutralizes nozzle pressure hysteresis during acceleration and deceleration

class PressureAdvance
  (k-factor = 0.04) ->
    # k-factor in seconds (typical range 0.02 - 0.08 s for direct drive extruders)
    @k-factor = +k-factor

  calculate-advance-volume: (velocity-mm-s, accel-mm-s2) ->
    # Delta E = k_factor * dv / dt
    # Advance volume added or subtracted during acceleration/deceleration
    @k-factor * velocity-mm-s

  apply-to-block: (block) ->
    # Modifies filament extrusion according to acceleration/deceleration states
    if not block.segment.is-extrusion!
      return block

    v-entry = block.entry-speed
    v-cruise = block.cruise-speed
    v-exit = block.exit-speed

    # Advance needed at acceleration onset
    advance-acc = @k-factor * (v-cruise - v-entry)
    # Retraction needed before corner deceleration
    advance-dec = @k-factor * (v-cruise - v-exit)

    block.pressure-advance-acc = Math.max 0.0, advance-acc
    block.pressure-advance-dec = Math.max 0.0, advance-dec
    block

module.exports = PressureAdvance
