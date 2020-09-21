# Kinodynamics & Motion Planning Specification

## 1. System Overview

Digital fabrication machines cannot alter toolhead velocity instantaneously. Stepper motors operate under torque constraints, belts exhibit elasticity, and heavy gantry assemblies possess mechanical inertia. Abrupt changes in velocity introduce severe positional error, lost steps, frame shudder, and optical ringing artifacts on finished surfaces.

Kerf implements a multi-stage kinodynamic motion planner to convert geometric toolpath segments into physically realizable acceleration-limited trajectories.

---

## 2. Centrifugal Junction Deviation

When transitioning between two consecutive linear toolpath blocks with unit direction vectors $\hat{\mathbf{u}}_1$ and $\hat{\mathbf{u}}_2$, the toolhead undergoes an angular deflection $\theta$:

$$\cos(\theta) = \hat{\mathbf{u}}_1 \cdot \hat{\mathbf{u}}_2$$

Rather than decelerating to a complete standstill at every corner, modern controllers allow a controlled corner rounding error within a small tolerance envelope $\delta$ (typically 0.04 mm). This transition is modeled as an equivalent virtual arc of radius $R_{\text{corner}}$:

$$\sin\left(\frac{\theta}{2}\right) = \sqrt{\frac{1 - \cos(\theta)}{2}}$$

$$R_{\text{corner}} = \frac{\delta \cdot \sin(\theta/2)}{1 - \sin(\theta/2)}$$

The maximum safe cornering velocity $v_{\text{corner}}$ governed by centripetal acceleration $a_{\max}$ is:

$$v_{\text{corner}} = \sqrt{a_{\max} \cdot R_{\text{corner}}}$$

### Boundary Conditions
- Collinear moves ($\theta = 0$): $\cos(\theta) = 1 \implies v_{\text{corner}} = \infty$. Toolhead maintains nominal cruise velocity without decelerating.
- Full 180-degree reversal ($\theta = \pi$): $\cos(\theta) = -1 \implies v_{\text{corner}} = 0$. Toolhead comes to a complete halt to reverse inertia.

---

## 3. Forward-Backward Lookahead Trapezoid Planner

For an ordered sequence of $N$ movement blocks, each block $i$ possesses length $d_i$ and nominal requested feedrate $v_{\text{nom}, i}$.

### 3.1 Initial Corner Speeds
Between each adjacent pair of blocks, junction deviation calculates the allowable transition velocity:

$$v_{\text{corner}, i} = \min\left(v_{\text{nom}, i-1}, v_{\text{nom}, i}, v_{\text{junction}}\right)$$

At the start and conclusion of the move sequence, boundary speeds are set to zero:

$$v_{\text{corner}, 0} = 0, \quad v_{\text{corner}, N} = 0$$

### 3.2 Backward Pass (Deceleration Limiting)
Beginning at the final block and proceeding backward to the start ($i = N-1 \dots 0$):

$$v_{\text{entry}, i} \le \sqrt{v_{\text{exit}, i}^2 + 2 \cdot a_{\max} \cdot d_i}$$

$$v_{\text{corner}, i} = \min\left(v_{\text{corner}, i}, v_{\text{entry}, i}\right)$$

This pass guarantees that the toolhead never enters a block at a speed greater than its ability to decelerate to the required exit speed within distance $d_i$.

### 3.3 Forward Pass (Acceleration Limiting)
Beginning at the first block and proceeding forward to the end ($i = 0 \dots N-1$):

$$v_{\text{exit}, i} \le \sqrt{v_{\text{entry}, i}^2 + 2 \cdot a_{\max} \cdot d_i}$$

$$v_{\text{corner}, i+1} = \min\left(v_{\text{corner}, i+1}, v_{\text{exit}, i}\right)$$

This pass guarantees that the toolhead never attempts to accelerate faster than physical motor torque permits.

### 3.4 Phase Solution
For each block, the maximum reachable cruise speed $v_{\text{peak}}$ is computed:

$$v_{\text{peak}} = \sqrt{\frac{2 \cdot a_{\max} \cdot d_i + v_{\text{entry}}^2 + v_{\text{exit}}^2}{2}}$$

- Triangular Profile ($v_{\text{peak}} \le v_{\text{nom}}$): The block consists purely of an acceleration phase and deceleration phase without a constant-velocity cruise segment.
- Trapezoidal Profile ($v_{\text{peak}} > v_{\text{nom}}$): The block cruises at nominal velocity $v_{\text{nom}}$ for distance $d_{\text{cruise}} = d_i - d_{\text{acc}} - d_{\text{dec}}$.

---

## 4. 7-Segment S-Curve Jerk Profiling

In trapezoidal profiling, acceleration changes discontinuously between $0$ and $a_{\max}$ at phase transitions, resulting in infinite jerk ($j = \frac{da}{dt} \to \infty$). This step change excites high-frequency mechanical resonance modes in the machine chassis.

Kerf implements a 7-segment S-curve profile with bounded maximum jerk $j_{\max}$ (e.g. 50,000 mm/s^3):
1. Phase 1: Linear increase in acceleration from 0 to $+a_{\max}$ ($j = +j_{\max}$).
2. Phase 2: Constant acceleration at $+a_{\max}$ ($j = 0$).
3. Phase 3: Linear decrease in acceleration from $+a_{\max}$ to 0 ($j = -j_{\max}$).
4. Phase 4: Constant velocity cruise ($a = 0, j = 0$).
5. Phase 5: Linear increase in deceleration from 0 to $-a_{\max}$ ($j = -j_{\max}$).
6. Phase 6: Constant deceleration at $-a_{\max}$ ($j = 0$).
7. Phase 7: Linear decrease in deceleration from $-a_{\max}$ to 0 ($j = +j_{\max}$).

The ramp duration $t_j = \frac{a_{\max}}{j_{\max}}$ provides smooth velocity transitions with zero shock load.

---

## 5. Viscoelastic Pressure Advance Compensation

In a hotend melt zone, semi-molten filament behaves as a non-Newtonian viscoelastic fluid with spring-like compliance:
- When the toolhead accelerates, volumetric extrusion lags behind motor motion, resulting in under-extrusion at line starts.
- When the toolhead decelerates into a corner, residual fluid pressure continues pushing material out of the nozzle orifice, resulting in bulging corners (elephant footing).

Kerf models this pressure hysteresis using linear advance dynamics:

$$\Delta E = k_{\text{pa}} \cdot \frac{dv}{dt}$$

During acceleration, additional filament volume is fed ahead of motion. During deceleration, filament is retracted prior to the corner to bleed off hotend barrel pressure, yielding uniform line widths throughout the layer.
