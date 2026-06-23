///|
/// Helper: a quantity with the torque unit N*m/rad.
fn newton_meters_per_radian(value : Double) -> @quantity.Quantity {
  @quantity.Quantity::new(value, @mechanical_units.joule / @angle.radian)
}

///|
/// Formula metadata is available for discovery and UI generation.
test "formula catalog exposes mechanics metadata" {
  let fs = formulas()
  assert_eq(fs.length(), 6)
  assert_eq(force_formula.name(), "force")
  assert_eq(force_formula.display(), "F = m * a")
  assert_eq(force_formula.inputs().length(), 2)
  assert_true(
    force_formula.output().is_same(@mechanical_units.newton.dimension()),
  )
}

///|
/// Force evaluates through the formula object.
test "force formula evaluates mass times acceleration" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input(
      "acceleration",
      @quantity.Quantity::new(3.0, @si.meter / @si.second.pow(2)),
    )
  let force = force_formula.eval(env)
  assert_eq(force.value(), 6.0)
  assert_true(force.unit().is_compatible(@mechanical_units.newton))
}

///|
/// Formula inputs are dimension checked before evaluation.
test "force formula rejects velocity as acceleration" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input("acceleration", @qmechanics.meters_per_second(3.0))
  assert_true(force_formula.checked_eval(env) is None)
}

///|
/// Work evaluates to energy and accepts any force/length compatible units.
test "work formula evaluates force times distance" {
  let env = @common.FormulaEnv::new()
    .with_input("force", @qmechanics.kilonewtons(2.0))
    .with_input("distance", @qgeometry.meters(3.0))
  let work = work_formula.eval(env).to(@mechanical_units.joule)
  assert_eq(work.value(), 6000.0)
}

///|
/// Power evaluates energy over time.
test "power formula evaluates work over time" {
  let env = @common.FormulaEnv::new()
    .with_input("work", @qmechanics.joules(120.0))
    .with_input("time", @quantity.Quantity::new(4.0, @si.second))
  let power = power_formula.eval(env).to(@mechanical_units.watt)
  assert_eq(power.value(), 30.0)
}

///|
/// Kinetic energy evaluates 1/2 m v^2.
test "kinetic energy formula evaluates one half m v squared" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(4.0, @si.kilogram))
    .with_input("velocity", @qmechanics.meters_per_second(3.0))
  let energy = kinetic_energy_formula.eval(env).to(@mechanical_units.joule)
  assert_eq(energy.value(), 18.0)
}

///|
/// Kinetic energy rejects an input with the wrong dimension.
test "kinetic energy rejects distance as velocity" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(4.0, @si.kilogram))
    .with_input("velocity", @qgeometry.meters(3.0))
  assert_true(kinetic_energy_formula.checked_eval(env) is None)
}

///|
/// Rotational work proves torque and energy are not the same dimension.
test "rotational work converts torque times angle to energy" {
  let env = @common.FormulaEnv::new()
    .with_input("torque", newton_meters_per_radian(10.0))
    .with_input("angle", @qangle.degrees(90.0))
  let work = rotational_work_formula.eval(env).to(@mechanical_units.joule)
  assert_eq(work.value(), 15.707963267948966)
}

///|
/// Torque is energy per angle, so it cannot be added directly to energy.
test "torque and energy are dimensionally distinct" {
  let torque = newton_meters_per_radian(10.0)
  let energy = @qmechanics.joules(10.0)
  assert_true(torque.checked_add(energy) is None)
}

///|
/// Rotational work rejects plain energy when torque is expected.
test "rotational work rejects energy as torque" {
  let env = @common.FormulaEnv::new()
    .with_input("torque", @qmechanics.joules(10.0))
    .with_input("angle", @qangle.radians(2.0))
  assert_true(rotational_work_formula.checked_eval(env) is None)
}

///|
/// A missing input is a formula evaluation error.
test "mechanics formulas reject missing inputs" {
  let env = @common.FormulaEnv::new().with_input(
    "force",
    @qmechanics.newtons(10.0),
  )
  assert_true(work_formula.checked_eval(env) is None)
}
