// Mechanics vocabulary: anonymous, composable formula values built on
// LunarUnits dimensions and units. Mirroring how `units/mechanics` exports both
// base and derived `Un` values, this package exports both the input variables
// (mass, acceleration, …) and the formulas composed from them (force, work, …),
// all as anonymous `@common.Formula` `let` bindings whose MoonBit identifier is
// their only name — exactly as `@mechanics.newton` names a unit.

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
/// The torque dimension used by LunarUnits: energy / angle.
fn torque_dimension() -> @dimension.Dimension {
  @mechanical_units.joule.dimension().div(@angle.radian.dimension())
}

///|
/// Input variable: a mass.
///
/// ```mbt check
/// test {
///   assert_true(mass.dimension().is_same(@dimension.Dimension::mass()))
/// }
/// ```
pub let mass : @common.Formula = @common.input(
  "mass",
  @dimension.Dimension::mass(),
)

///|
/// Input variable: an acceleration (length / time^2).
///
/// ```mbt check
/// test {
///   assert_true(
///     acceleration
///     .dimension()
///     .is_same(
///       @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
///     ),
///   )
/// }
/// ```
pub let acceleration : @common.Formula = @common.input(
  "acceleration",
  acceleration_dimension(),
)

///|
/// Input variable: a velocity (length / time).
///
/// ```mbt check
/// test {
///   assert_true(
///     velocity.dimension().is_same(@mechanical_units.meter_per_second.dimension()),
///   )
/// }
/// ```
pub let velocity : @common.Formula = @common.input(
  "velocity",
  @mechanical_units.meter_per_second.dimension(),
)

///|
/// Input variable: a force.
///
/// ```mbt check
/// test {
///   assert_true(force.dimension().is_same(@mechanical_units.newton.dimension()))
/// }
/// ```
pub let force : @common.Formula = @common.input("force", force_dimension())

///|
/// Input variable: a distance / displacement.
///
/// ```mbt check
/// test {
///   assert_true(distance.dimension().is_same(@dimension.Dimension::length()))
/// }
/// ```
pub let distance : @common.Formula = @common.input(
  "distance",
  @dimension.Dimension::length(),
)

///|
/// Input variable: a lever arm length.
///
/// ```mbt check
/// test {
///   assert_true(lever_arm.dimension().is_same(@dimension.Dimension::length()))
/// }
/// ```
pub let lever_arm : @common.Formula = @common.input(
  "lever_arm",
  @dimension.Dimension::length(),
)

///|
/// Input variable: an elapsed time.
///
/// ```mbt check
/// test {
///   assert_true(time.dimension().is_same(@dimension.Dimension::time()))
/// }
/// ```
pub let time : @common.Formula = @common.input(
  "time",
  @dimension.Dimension::time(),
)

///|
/// Input variable: a work or energy quantity.
///
/// ```mbt check
/// test {
///   assert_true(work.dimension().is_same(@mechanical_units.joule.dimension()))
/// }
/// ```
pub let work : @common.Formula = @common.input("work", energy_dimension())

///|
/// Input variable: a torque (energy / angle).
///
/// ```mbt check
/// test {
///   assert_true(
///     torque
///     .dimension()
///     .is_same(@mechanical_units.joule.dimension().div(@angle.radian.dimension())),
///   )
/// }
/// ```
pub let torque : @common.Formula = @common.input("torque", torque_dimension())

///|
/// Input variable: a rotation angle.
///
/// ```mbt check
/// test {
///   assert_true(angle.dimension().is_same(@angle.radian.dimension()))
/// }
/// ```
pub let angle : @common.Formula = @common.input(
  "angle",
  @angle.radian.dimension(),
)

///|
/// Newton's second law, `F = m * a`. The output dimension (force) is inferred
/// from `mass * acceleration`.
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
pub let force_formula : @common.Formula = mass * acceleration

///|
/// Linear work, `W = F * d`.
///
/// ```mbt check
/// test {
///   assert_true(
///     work_formula.dimension().is_same(@mechanical_units.joule.dimension()),
///   )
/// }
/// ```
pub let work_formula : @common.Formula = force * distance

///|
/// Power from work over elapsed time, `P = W / t`.
///
/// ```mbt check
/// test {
///   assert_true(
///     power_formula.dimension().is_same(@mechanical_units.watt.dimension()),
///   )
/// }
/// ```
pub let power_formula : @common.Formula = work / time

///|
/// Translational kinetic energy, `E_k = 1/2 * m * v^2`.
///
/// ```mbt check
/// test {
///   assert_true(
///     kinetic_energy_formula
///     .dimension()
///     .is_same(@mechanical_units.joule.dimension()),
///   )
/// }
/// ```
pub let kinetic_energy_formula : @common.Formula = @common.constant(0.5) *
  mass *
  velocity.pow(2)

///|
/// Torque from force and lever arm, `tau = F * r / rad`.
///
/// LunarUnits keeps angle as an extension dimension, so torque is modeled as
/// energy per angle (`N*m/rad`) rather than plain energy.
///
/// ```mbt check
/// test {
///   assert_true(
///     torque_formula
///     .dimension()
///     .is_same(@mechanical_units.joule.dimension().div(@angle.radian.dimension())),
///   )
/// }
/// ```
pub let torque_formula : @common.Formula = force *
  lever_arm /
  @common.quantity(1.0, @angle.radian)

///|
/// Rotational work, `W = tau * theta`.
///
/// This is the first mechanics showcase for LunarUnits' angle dimension: torque
/// has dimension `energy / angle`, while the result is energy.
///
/// ```mbt check
/// test {
///   assert_true(
///     rotational_work_formula
///     .dimension()
///     .is_same(@mechanical_units.joule.dimension()),
///   )
/// }
/// ```
pub let rotational_work_formula : @common.Formula = torque * angle
