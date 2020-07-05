# Centrifugal Junction Deviation Cornering Velocity Engine
# Computes maximum safe velocity across directional transitions

class JunctionDeviation
  @calculate-corner-speed = (v1-dir, v2-dir, acceleration, junction-dev) ->
    # v1-dir, v2-dir: normalized Vector3 or Point2D
    # Dot product of normalized direction vectors
    unit-dot = v1-dir.dot v2-dir
    # Clamp dot product to [-1, 1]
    clamped-dot = Math.max -1.0, Math.min 1.0, unit-dot

    # Straight line: 0 degrees angle
    if clamped-dot >= 0.9999
      return Infinity

    # Complete reversal: 180 degrees turn
    if clamped-dot <= -0.9999
      return 0.0

    # sin(theta / 2) = sqrt((1 - cos(theta)) / 2)
    sin-half-theta = Math.sqrt((1.0 - clamped-dot) * 0.5)

    if (1.0 - sin-half-theta) < 1e-6
      return 0.0

    # Effective corner radius R = (delta * sin(theta/2)) / (1 - sin(theta/2))
    r-corner = (junction-dev * sin-half-theta) / (1.0 - sin-half-theta)

    # Maximum corner velocity = sqrt(a * R)
    Math.sqrt(acceleration * r-corner)

module.exports = JunctionDeviation
