// LunarFormulas worked examples. Every block is a runnable test, matching the
// cookbook style used by LunarUnits. Formulas are anonymous, composable values:
// you reference vocabulary, combine it with operators, and evaluate — just like
// composing units in LunarUnits.

///|
/// Newton's second law as an anonymous formula value. The caller supplies
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
/// are distinct: torque is energy per angle (`N*m/rad`), while energy is `N*m`.
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
/// The vocabulary composes with operators into formulas the catalog never named.
/// Mechanical power is just force times velocity — the dimension (watt) is
/// inferred and the formula evaluates directly, with no construction step.
test "compose a new formula from the vocabulary" {
  let power = @formula_mechanics.force * @formula_mechanics.velocity
  assert_true(power.dimension().is_same(@mechanical_units.watt.dimension()))
  let env = @common.FormulaEnv::new()
    .with_input("force", @qmechanics.newtons(10.0))
    .with_input("velocity", @qmechanics.meters_per_second(3.0))
  assert_eq(power.eval(env).to(@mechanical_units.watt).value(), 30.0)
}

///|
/// Defining your own variables reads like writing the equation. `input` names a
/// variable and its dimension; combining with `*` builds the expression,
/// collects the inputs and synthesises the output dimension — no `inputs` array
/// and no restated output dimension. The result is evaluated directly.
test "define and evaluate a formula with the DSL" {
  let mass = @common.input("mass", @dimension.Dimension::mass())
  let velocity = @common.input(
    "velocity",
    @mechanical_units.meter_per_second.dimension(),
  )
  let momentum = mass * velocity
  assert_eq(momentum.inputs().length(), 2)
  assert_true(
    momentum
    .dimension()
    .is_same(
      @dimension.Dimension::mass().mul(
        @mechanical_units.meter_per_second.dimension(),
      ),
    ),
  )
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
  let mass = @common.input("mass", @dimension.Dimension::mass())
  let velocity = @common.input(
    "velocity",
    @mechanical_units.meter_per_second.dimension(),
  )
  let kinetic_energy = @common.constant(0.5) * mass * velocity.pow(2)
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
  let force = @common.input("force", @mechanical_units.newton.dimension())
  let lever_arm = @common.input("lever_arm", @dimension.Dimension::length())
  let torque = force * lever_arm / @common.quantity(1.0, @angle.radian)
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
/// `renamed` derives distinct variables from one predefined variable, so the
/// same physical quantity can appear several times. Here two masses are summed.
test "reuse a variable several times with renamed" {
  let mass = @common.input("mass", @dimension.Dimension::mass())
  let total_mass = mass.renamed("m1").add(mass.renamed("m2"))
  let env = @common.FormulaEnv::new()
    .with_input("m1", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input("m2", @quantity.Quantity::new(3.0, @si.kilogram))
  assert_eq(total_mass.eval(env).value(), 5.0)
}

///|
/// Composition is total even when an input name is used with two different
/// dimensions; the conflict surfaces at evaluation, where a single bound value
/// can only match one of the declared dimensions.
test "an inconsistent input surfaces at evaluation" {
  let as_length = @common.input("x", @dimension.Dimension::length())
  let as_time = @common.input("x", @dimension.Dimension::time())
  let bad = as_length * as_time
  let env = @common.FormulaEnv::new().with_input("x", @qgeometry.meters(2.0))
  assert_true(bad.checked_eval(env) is None)
}
