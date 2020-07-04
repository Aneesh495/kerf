# Physical Machine Kinematics Limits and Constraints
# Defines velocity, acceleration, jerk, and volumetric extrusion flow boundaries

class KinematicsLimits
  (opts = {}) ->
    @max-velocity     = opts.max-velocity or 300.0       # mm/sec
    @max-acceleration = opts.max-acceleration or 3000.0   # mm/sec^2
    @max-jerk         = opts.max-jerk or 50000.0         # mm/sec^3
    @junction-dev     = opts.junction-dev or 0.04        # mm corner deviation
    @max-volumetric   = opts.max-volumetric or 15.0      # mm^3/sec maximum melt rate
    @filament-dia     = opts.filament-dia or 1.75        # mm
    @nozzle-dia       = opts.nozzle-dia or 0.40          # mm

  filament-area: ->
    r = @filament-dia * 0.5
    Math.PI * r * r

  calculate-max-linear-feedrate: (layer-height, extrusion-width) ->
    # Volume per mm travel = layer_height * extrusion_width
    cross-section-area = layer-height * extrusion-width
    if cross-section-area > 1e-6
      # Max linear speed mm/s = max_volumetric / cross_section_area
      max-speed-mm-s = @max-volumetric / cross-section-area
      Math.min @max-velocity, max-speed-mm-s
    else
      @max-velocity

module.exports = KinematicsLimits
