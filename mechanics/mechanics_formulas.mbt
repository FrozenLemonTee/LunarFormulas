///|
/// The acceleration dimension, length / time^2.
fn acceleration_dimension() -> @dimension.Dimension {
  @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2))
}

///|
/// The force dimension, mass * length / time^2.
fn force_dimension() -> @dimension.Dimension {
  @mechanical_units.newton.dimension()
}

///|
/// The energy dimension, mass * length^2 / time^2.
fn energy_dimension() -> @dimension.Dimension {
  @mechanical_units.joule.dimension()
}

///|
/// The power dimension, energy / time.
fn power_dimension() -> @dimension.Dimension {
  @mechanical_units.watt.dimension()
}

///|
/// The torque dimension used by LunarUnits: energy / angle.
fn torque_dimension() -> @dimension.Dimension {
  @mechanical_units.joule.dimension().div(@angle.radian.dimension())
}

///|
/// Newton's second law, `F = m * a`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let env = @common.FormulaEnv::new()
///     .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
///     .with_input(
///       "acceleration",
///       @quantity.Quantity::new(3.0, @si.meter / @si.second.pow(2)),
///     )
///   let force = force_formula.eval(env)
///   assert_eq(force.value(), 6.0)
///   assert_true(force.unit().is_compatible(@mechanical_units.newton))
/// }
/// ```
pub let force_formula : @common.Formula = {
  let mass = @common.input("mass", @dimension.Dimension::mass(), "Mass")
  let acceleration = @common.input(
    "acceleration",
    acceleration_dimension(),
    "Acceleration",
  )
  @common.Formula::from_term(
    "force",
    mass * acceleration,
    force_dimension(),
    "F = m * a",
    "Computes force from mass and acceleration.",
  )
}

///|
/// Linear work, `W = F * d`.
pub let work_formula : @common.Formula = {
  let force = @common.input("force", force_dimension(), "Force")
  let distance = @common.input(
    "distance",
    @dimension.Dimension::length(),
    "Distance",
  )
  @common.Formula::from_term(
    "work",
    force * distance,
    energy_dimension(),
    "W = F * d",
    "Computes work from force and displacement.",
  )
}

///|
/// Power from work over elapsed time, `P = W / t`.
pub let power_formula : @common.Formula = {
  let work = @common.input("work", energy_dimension(), "Work or energy")
  let time = @common.input("time", @dimension.Dimension::time(), "Elapsed time")
  @common.Formula::from_term(
    "power",
    work / time,
    power_dimension(),
    "P = W / t",
    "Computes average power from work and elapsed time.",
  )
}

///|
/// Kinetic energy, `E_k = 1/2 * m * v^2`.
pub let kinetic_energy_formula : @common.Formula = {
  let mass = @common.input("mass", @dimension.Dimension::mass(), "Mass")
  let velocity = @common.input(
    "velocity",
    @mechanical_units.meter_per_second.dimension(),
    "Velocity",
  )
  @common.Formula::from_term(
    "kinetic_energy",
    @common.constant(0.5) * mass * velocity.pow(2),
    energy_dimension(),
    "E_k = 1/2 * m * v^2",
    "Computes translational kinetic energy.",
  )
}

///|
/// Torque from force and lever arm, `tau = F * r / theta_unit`.
///
/// LunarUnits keeps angle as an extension dimension, so torque is modeled as
/// energy per angle (`N*m/rad`) rather than plain energy.
pub let torque_formula : @common.Formula = {
  let force = @common.input("force", force_dimension(), "Force")
  let lever_arm = @common.input(
    "lever_arm",
    @dimension.Dimension::length(),
    "Lever arm",
  )
  @common.Formula::from_term(
    "torque",
    force * lever_arm / @common.quantity(1.0, @angle.radian),
    torque_dimension(),
    "tau = F * r / rad",
    "Computes torque as energy per plane angle.",
  )
}

///|
/// Rotational work, `W = tau * theta`.
///
/// This is the first mechanics showcase for LunarUnits' angle dimension:
/// torque has dimension `energy / angle`, while the result is energy.
pub let rotational_work_formula : @common.Formula = {
  let torque = @common.input("torque", torque_dimension(), "Torque")
  let angle = @common.input(
    "angle",
    @angle.radian.dimension(),
    "Rotation angle",
  )
  @common.Formula::from_term(
    "rotational_work",
    torque * angle,
    energy_dimension(),
    "W = tau * theta",
    "Computes rotational work from torque and angle.",
  )
}

///|
/// Returns the mechanics formula catalog for enumeration by applications.
pub fn formulas() -> Array[@common.Formula] {
  [
    force_formula, work_formula, power_formula, kinetic_energy_formula, torque_formula,
    rotational_work_formula,
  ]
}
