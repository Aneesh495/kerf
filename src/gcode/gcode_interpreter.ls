# G-code Virtual Machine Kinematics Interpreter
# Simulates 5-axis toolhead movement, filament consumption, and print execution time

{ GcodeParser } = require './gcode_parser'
Vector3 = require '../math/vector3'

class GcodeInterpreter
  (opts = {}) ->
    @pos = new Vector3 0, 0, 0
    @feedrate = 3000.0   # mm/min
    @e-pos = 0.0         # mm filament
    @relative-xyz = false
    @relative-e = true
    @total-filament-mm = 0.0
    @total-time-sec = 0.0
    @layer-count = 0
    @max-z = 0.0
    @filament-density = opts.filament-density or 1.24 # g/cm^3 (standard PLA)
    @filament-dia = opts.filament-dia or 1.75         # mm

    r = @filament-dia * 0.5
    @filament-area = Math.PI * r * r

  reset: ->
    @pos.set 0, 0, 0
    @feedrate = 3000.0
    @e-pos = 0.0
    @relative-xyz = false
    @relative-e = true
    @total-filament-mm = 0.0
    @total-time-sec = 0.0
    @layer-count = 0
    @max-z = 0.0
    @

  run-command: (cmd) ->
    if not cmd.cmd?
      return

    switch cmd.cmd
    case 'G0', 'G1'
      # Linear coordinated move
      if cmd.has 'F'
        @feedrate = cmd.get 'F'

      target-x = @pos.x
      target-y = @pos.y
      target-z = @pos.z

      if cmd.has 'X'
        target-x = if @relative-xyz then (@pos.x + cmd.get('X')) else cmd.get('X')
      if cmd.has 'Y'
        target-y = if @relative-xyz then (@pos.y + cmd.get('Y')) else cmd.get('Y')
      if cmd.has 'Z'
        target-z = if @relative-xyz then (@pos.z + cmd.get('Z')) else cmd.get('Z')
        if target-z > @max-z
          @max-z = target-z
          @layer-count += 1

      dx = target-x - @pos.x
      dy = target-y - @pos.y
      dz = target-z - @pos.z
      dist = Math.sqrt(dx * dx + dy * dy + dz * dz)

      # Extrusion tracking
      if cmd.has 'E'
        e-val = cmd.get 'E'
        delta-e = if @relative-e
          e-val
        else
          de = e-val - @e-pos
          @e-pos = e-val
          de

        if delta-e > 0
          @total-filament-mm += delta-e

      # Time calculation based on feedrate
      speed-mm-s = Math.max 1.0, (@feedrate / 60.0)
      move-duration = dist / speed-mm-s
      @total-time-sec += move-duration

      @pos.set target-x, target-y, target-z

    case 'G90'
      @relative-xyz = false
    case 'G91'
      @relative-xyz = true
    case 'M82'
      @relative-e = false
    case 'M83'
      @relative-e = true
    case 'G92'
      if cmd.has 'E'
        @e-pos = cmd.get 'E'
      if cmd.has 'X'
        @pos.x = cmd.get 'X'
      if cmd.has 'Y'
        @pos.y = cmd.get 'Y'
      if cmd.has 'Z'
        @pos.z = cmd.get 'Z'

  interpret-text: (gcode-text) ->
    commands = GcodeParser.parse-text gcode-text
    for cmd in commands
      @run-command cmd
    @get-metrics!

  get-metrics: ->
    # Volume mm^3 = total_filament_mm * filament_area
    vol-mm3 = @total-filament-mm * @filament-area
    vol-cm3 = vol-mm3 * 0.001
    mass-grams = vol-cm3 * @filament-density

    minutes = Math.floor(@total-time-sec / 60.0)
    seconds = Math.round(@total-time-sec % 60.0)

    {
      total-time-sec: @total-time-sec
      formatted-time: "#{minutes}m #{seconds}s"
      total-filament-mm: @total-filament-mm
      filament-mass-grams: mass-grams
      max-z: @max-z
      layer-count: @layer-count
    }

module.exports = GcodeInterpreter
