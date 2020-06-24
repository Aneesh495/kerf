# Toolpath Segment Representation and Motion Classification
# Encapsulates kinematics feedrate, extrusion volumetric flow, and move taxonomy

class ToolpathType
  @PERIMETER_OUTER = 'PerimeterOuter'
  @PERIMETER_INNER = 'PerimeterInner'
  @INFILL          = 'Infill'
  @SUPPORT         = 'Support'
  @RAPID_TRAVEL    = 'RapidTravel'
  @RETRACT         = 'Retract'
  @PRIME           = 'Prime'
  @WIPE            = 'Wipe'

class ToolpathSegment
  (p1, p2, type = ToolpathType.INFILL, opts = {}) ->
    @p1 = p1.clone!
    @p2 = p2.clone!
    @type = type
    @feedrate = opts.feedrate or (if type == ToolpathType.RAPID_TRAVEL then 7200.0 else 3000.0) # mm/min
    @extrusion-volume = opts.extrusion-volume or 0.0 # mm^3
    @fan-speed = opts.fan-speed or 255               # 0-255 PWM
    @z = opts.z or 0.0

  is-extrusion: ->
    @type != ToolpathType.RAPID_TRAVEL and
    @type != ToolpathType.RETRACT and
    @type != ToolpathType.WIPE

  length: ->
    @p1.distance-to @p2

  duration-sec: ->
    # feedrate in mm/min -> mm/sec = feedrate / 60
    speed-mm-s = @feedrate / 60.0
    if speed-mm-s > 1e-6
      @length! / speed-mm-s
    else
      0.0

module.exports = {
  ToolpathType
  ToolpathSegment
}
