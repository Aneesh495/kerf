# G-code Specification & Virtual Machine

## 1. NIST RS274/NGC Compliance

Kerf emits numerical control programs adhering to the NIST RS274/NGC standard for computer-controlled machine tools, tailored for Cartesian, CoreXY, and multi-axis additive manufacturing systems.

### Supported Modal Codes
- `G0`: Rapid Non-Extrusion Traverse (Maximum travel speed, typically 7200 to 12000 mm/min).
- `G1`: Coordinated Linear Feed Move (Controlled toolpath extrusion).
- `G21`: Programming in Millimeter Units.
- `G28`: Machine Origin Homing (Axes X, Y, and Z).
- `G90`: Absolute Positioning Mode.
- `G91`: Relative Positioning Mode.
- `G92`: Coordinate Offset Set / Reset Position Register.
- `M82`: Absolute Extruder Positioning.
- `M83`: Relative Extruder Positioning (Default: eliminates cumulative float rounding errors).
- `M104`: Set Hotend Temperature (Non-blocking).
- `M109`: Set Hotend Temperature and Wait for Stabilization.
- `M140`: Set Heated Bed Temperature (Non-blocking).
- `M190`: Set Heated Bed Temperature and Wait for Stabilization.
- `M106`: Enable Part Cooling Fan (PWM 0 to 255).
- `M107`: Disable Part Cooling Fan.
- `M84`: Disable Stepper Motor Drivers.

---

## 2. Multi-Firmware Dialect Profiles

Kerf provides configuration presets for modern fabrication firmwares:
- Marlin Firmware: Standard RS274 modal commands, absolute or relative E, junction deviation comments.
- Klipper Firmware: Optimized for high-throughput single-line kinematics lookahead, SET_PRESSURE_ADVANCE hooks, and microsecond-level motion planning.
- RepRapFirmware: Support for multi-tool offsets, volumetric flow rate comments, and dynamic chamber heater control.
- LinuxCNC: Pure ISO 6983 G-code dialect with strict coordinate modal continuity for milling and subtractive operations.

---

## 3. Extrusion Volume Mathematics

Filament consumption is governed by mass conservation between the solid input filament cylinder and the flattened extruded bead geometry.

Given:
- Bead width: $w$ (typically $1.125 \times \text{nozzle\_diameter}$, e.g. 0.45 mm)
- Layer thickness: $h$ (e.g. 0.20 mm)
- Toolpath segment length: $L$ (mm)
- Filament diameter: $D_{\text{filament}} = 1.75$ mm

The cross-sectional area of the extruded track is approximated by a rectangle with semi-circular rounded edges:

$$A_{\text{bead}} = (w - h) \cdot h + \pi \cdot \left(\frac{h}{2}\right)^2$$

The total volume of plastic required for a segment of length $L$ is:

$$V_{\text{plastic}} = A_{\text{bead}} \cdot L$$

The filament cross-sectional area in the extruder barrel is:

$$A_{\text{filament}} = \pi \cdot \left(\frac{D_{\text{filament}}}{2}\right)^2 \approx 2.4053 \text{ mm}^2$$

The linear extrusion length $E$ commanded in G-code is:

$$E = \frac{V_{\text{plastic}}}{A_{\text{filament}}} = \frac{A_{\text{bead}} \cdot L}{A_{\text{filament}}}$$

---

## 4. Virtual Machine Kinematics Simulator

Kerf contains an integrated virtual machine (`GcodeInterpreter`) that parses emitted G-code and validates print feasibility prior to machine execution:
1. Coordinate Register Tracking: Maintains internal state vectors for $(X, Y, Z, E, F)$ under absolute (`G90`) and relative (`G91`) modes.
2. Filament Mass Calculation: Integrates total extruded filament length:

$$M_{\text{filament}} = V_{\text{total}} \cdot \rho_{\text{plastic}}$$

where $\rho = 1.24 \text{ g/cm}^3$ for standard PolyLactic Acid (PLA) and $1.27 \text{ g/cm}^3$ for Polyethylene Terephthalate Glycol (PETG).
3. Sub-Second Build Time Estimation: Evaluates each individual toolpath block through the acceleration planner, summing acceleration duration, constant cruise duration, and deceleration duration to compute overall print time.
4. Anomaly Detection: Checks for cold extrusion attempts, feedrate violations, and bed dimension exceedance.
