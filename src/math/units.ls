# Physical units and nanometer coordinate quantization
# Guarantees numerical stability and eliminates floating-point drift in 2D geometry

NM_PER_MM = 1_000_000
MM_PER_NM = 1.0 / 1_000_000

class Units
  @NM_PER_MM = NM_PER_MM
  @MM_PER_NM = MM_PER_NM

  @mm-to-nm = (mm) ->
    Math.round mm * NM_PER_MM

  @nm-to-mm = (nm) ->
    nm * MM_PER_NM

  @microns-to-mm = (um) ->
    um * 0.001

  @mm-to-microns = (mm) ->
    mm * 1000.0

  @inches-to-mm = (inches) ->
    inches * 25.4

  @mm-to-inches = (mm) ->
    mm / 25.4

  @deg-to-rad = (deg) ->
    deg * (Math.PI / 180.0)

  @rad-to-deg = (rad) ->
    rad * (180.0 / Math.PI)

  @quantize = (val, resolution = 1e-6) ->
    Math.round(val / resolution) * resolution

module.exports = Units
