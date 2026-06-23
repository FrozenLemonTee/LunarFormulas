// LunarFormulas worked examples. Every block is a runnable test, matching the
// cookbook style used by LunarUnits.

///|
/// Formula objects are inspectable. Applications can enumerate mechanics
/// formulas and read display text, inputs and output dimensions.
test "inspect the mechanics formula catalog" {
  let formulas = @formula_mechanics.formulas()
  assert_eq(formulas.length(), 6)
  assert_eq(formulas[0].name(), "force")
  assert_eq(formulas[0].display(), "F = m * a")
  assert_true(
    formulas[0].output().is_same(@mechanical_units.newton.dimension()),
  )
}

///|
/// Newton's second law as a first-class formula object. The caller supplies
/// quantities in a named environment, and the formula returns a quantity.
test "evaluate force from mass and acceleration" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input(
      "acceleration",
      @quantity.Quantity::new(3.0, @si.meter / @si.second.pow(2)),
    )
  let force = @formula_mechanics.force_formula.eval(env)
  assert_eq(force.value(), 6.0)
  assert_true(force.unit().is_compatible(@mechanical_units.newton))
}

///|
/// Formula inputs are checked by dimension, not by comments or naming
/// convention. Passing a length where acceleration is expected is rejected.
test "reject wrong input dimension" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input("acceleration", @qgeometry.meters(3.0))
  assert_true(@formula_mechanics.force_formula.checked_eval(env) is None)
}

///|
/// Kinetic energy is computed from mass and velocity, and the result converts
/// to joules like any LunarUnits quantity.
test "evaluate kinetic energy" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(4.0, @si.kilogram))
    .with_input("velocity", @qmechanics.meters_per_second(3.0))
  let energy = @formula_mechanics.kinetic_energy_formula.eval(env)
  assert_eq(energy.to(@mechanical_units.joule).value(), 18.0)
}

///|
/// Because LunarUnits models angle as an extension dimension, torque and energy
/// are distinct: torque is energy per angle (`N*m/rad`), while energy is
/// `N*m`.
test "torque and energy are distinct" {
  let torque = @quantity.Quantity::new(
    10.0,
    @mechanical_units.joule / @angle.radian,
  )
  let energy = @qmechanics.joules(10.0)
  assert_true(torque.checked_add(energy) is None)
}

///|
/// Rotational work is torque times angle. A 10 N*m/rad torque applied through
/// 90 degrees produces about 15.708 J.
test "evaluate rotational work" {
  let env = @common.FormulaEnv::new()
    .with_input(
      "torque",
      @quantity.Quantity::new(10.0, @mechanical_units.joule / @angle.radian),
    )
    .with_input("angle", @qangle.degrees(90.0))
  let work = @formula_mechanics.rotational_work_formula.eval(env)
  assert_eq(work.to(@mechanical_units.joule).value(), 15.707963267948966)
}

///|
/// Applications can combine LunarUnits' parser with LunarFormulas. User-facing
/// strings become checked quantities before entering the formula environment.
test "parse inputs and evaluate a formula" {
  let catalog = @preset.all()
  let env = @common.FormulaEnv::new()
    .with_input("force", @parser.parse_quantity(catalog, "20 N"))
    .with_input("distance", @parser.parse_quantity(catalog, "3 m"))
  let work = @formula_mechanics.work_formula.eval(env)
  assert_eq(work.to(@mechanical_units.joule).value(), 60.0)
}

///|
/// Defining a formula reads like writing the equation. `input` names a variable
/// and its dimension; combining terms with `*` builds the expression and
/// collects the input metadata automatically — no hand-written `inputs` array.
test "define a formula with the DSL" {
  let mass = @common.input("mass", @dimension.Dimension::mass(), "Mass")
  let velocity = @common.input(
    "velocity",
    @mechanical_units.meter_per_second.dimension(),
    "Velocity",
  )
  let momentum = @common.Formula::from_term(
    "momentum",
    mass * velocity,
    @dimension.Dimension::mass().mul(
      @mechanical_units.meter_per_second.dimension(),
    ),
    "p = m * v",
    "Linear momentum from mass and velocity.",
  )
  // Both inputs were gathered from the term automatically.
  assert_eq(momentum.inputs().length(), 2)
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input("velocity", @qmechanics.meters_per_second(3.0))
  assert_eq(momentum.eval(env).value(), 6.0)
}

///|
/// Constants and integer powers compose just like the maths. Following
/// LunarUnits, powers use `.pow(n)` rather than `^`, and `constant` adds a
/// dimensionless factor that contributes no input.
test "compose constants and powers like ordinary maths" {
  let mass = @common.input("mass", @dimension.Dimension::mass(), "Mass")
  let velocity = @common.input(
    "velocity",
    @mechanical_units.meter_per_second.dimension(),
    "Velocity",
  )
  let kinetic_energy = @common.Formula::from_term(
    "kinetic_energy",
    @common.constant(0.5) * mass * velocity.pow(2),
    @mechanical_units.joule.dimension(),
    "E_k = 1/2 * m * v^2",
    "Translational kinetic energy.",
  )
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(4.0, @si.kilogram))
    .with_input("velocity", @qmechanics.meters_per_second(3.0))
  assert_eq(kinetic_energy.eval(env).to(@mechanical_units.joule).value(), 18.0)
}

///|
/// A unit-bearing constant enters the expression with `quantity`. Torque is
/// energy per plane angle, so dividing by `1 rad` keeps the angle dimension
/// explicit while the formula still reads like `tau = F * r / rad`.
test "build a formula with a unit-bearing constant" {
  let force = @common.input(
    "force",
    @mechanical_units.newton.dimension(),
    "Force",
  )
  let lever_arm = @common.input(
    "lever_arm",
    @dimension.Dimension::length(),
    "Lever arm",
  )
  let torque = @common.Formula::from_term(
    "torque",
    force * lever_arm / @common.quantity(1.0, @angle.radian),
    @mechanical_units.joule.dimension().div(@angle.radian.dimension()),
    "tau = F * r / rad",
    "Torque as energy per plane angle.",
  )
  let env = @common.FormulaEnv::new()
    .with_input(
      "force",
      @quantity.Quantity::new(10.0, @mechanical_units.newton),
    )
    .with_input("lever_arm", @qgeometry.meters(2.0))
  let result = torque.eval(env)
  assert_eq(result.to(@mechanical_units.joule / @angle.radian).value(), 20.0)
}

///|
/// Reusing the same input is fine: the DSL deduplicates by name, so the formula
/// keeps a single descriptor for it.
test "reusing an input is deduplicated" {
  let velocity = @common.input(
    "velocity",
    @mechanical_units.meter_per_second.dimension(),
    "Velocity",
  )
  let speed_squared = @common.Formula::from_term(
    "speed_squared",
    velocity * velocity,
    @mechanical_units.meter_per_second.dimension().pow(2),
    "s = v * v",
    "Squared speed.",
  )
  assert_eq(speed_squared.inputs().length(), 1)
}

///|
/// When formulas are assembled dynamically, `checked_from_term` guards against
/// using one input name with two different dimensions.
test "checked_from_term reports an inconsistent input" {
  let as_length = @common.input(
    "x",
    @dimension.Dimension::length(),
    "X as length",
  )
  let as_time = @common.input("x", @dimension.Dimension::time(), "X as time")
  let mut caught = false
  try
    @common.Formula::checked_from_term(
      "inconsistent",
      as_length * as_time,
      @dimension.Dimension::length().mul(@dimension.Dimension::time()),
      "bad = x * x",
      "Same name, two dimensions.",
    )
    |> ignore
  catch {
    @common.InputDimensionConflict((name, _first, _second)) => {
      caught = true
      assert_eq(name, "x")
    }
  }
  assert_true(caught)
}
