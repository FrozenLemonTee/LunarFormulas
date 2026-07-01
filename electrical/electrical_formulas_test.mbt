///|
/// Electrical formula dimensions are inferred from composition.
test "electrical formula dimensions are inferred correctly" {
  assert_true(
    ohm_voltage.dimension().is_same(@electrical_units.volt.dimension()),
  )
  assert_true(
    electric_power.dimension().is_same(@mechanical_units.watt.dimension()),
  )
  assert_true(
    joule_heating_power.dimension().is_same(@mechanical_units.watt.dimension()),
  )
  assert_true(
    electric_charge.dimension().is_same(@electrical_units.coulomb.dimension()),
  )
  assert_true(
    electric_energy.dimension().is_same(@mechanical_units.joule.dimension()),
  )
}

///|
/// Ohm's law evaluates current times resistance.
test "ohm voltage evaluates current times resistance" {
  let env = @common.FormulaEnv::new()
    .with_input("current", @quantity.Quantity::new(2.0, @si.ampere))
    .with_input("resistance", @qelectromagnetism.ohms(5.0))
  let result = ohm_voltage.eval(env).to(@electrical_units.volt)
  assert_eq(result.value(), 10.0)
}

///|
/// Electric power evaluates voltage times current.
test "electric power evaluates voltage times current" {
  let env = @common.FormulaEnv::new()
    .with_input("voltage", @qelectromagnetism.volts(12.0))
    .with_input("current", @quantity.Quantity::new(2.0, @si.ampere))
  let result = electric_power.eval(env).to(@mechanical_units.watt)
  assert_eq(result.value(), 24.0)
}

///|
/// Joule heating evaluates I squared times resistance.
test "joule heating power evaluates current squared times resistance" {
  let env = @common.FormulaEnv::new()
    .with_input("current", @quantity.Quantity::new(3.0, @si.ampere))
    .with_input("resistance", @qelectromagnetism.ohms(4.0))
  let result = joule_heating_power.eval(env).to(@mechanical_units.watt)
  assert_eq(result.value(), 36.0)
}

///|
/// Charge evaluates current over elapsed time.
test "electric charge evaluates current times time" {
  let env = @common.FormulaEnv::new()
    .with_input("current", @quantity.Quantity::new(2.0, @si.ampere))
    .with_input("time", @quantity.Quantity::new(30.0, @si.second))
  let result = electric_charge.eval(env).to(@electrical_units.coulomb)
  assert_eq(result.value(), 60.0)
}

///|
/// Electric energy evaluates power over elapsed time.
test "electric energy evaluates power times time" {
  let env = @common.FormulaEnv::new()
    .with_input("power", @quantity.Quantity::new(100.0, @mechanical_units.watt))
    .with_input("time", @quantity.Quantity::new(3.0, @si.second))
  let result = electric_energy.eval(env).to(@mechanical_units.joule)
  assert_eq(result.value(), 300.0)
}

///|
/// Formula inputs are checked by dimension before evaluation.
test "electric power rejects current where voltage is expected" {
  let env = @common.FormulaEnv::new()
    .with_input("voltage", @quantity.Quantity::new(12.0, @si.ampere))
    .with_input("current", @quantity.Quantity::new(2.0, @si.ampere))
  assert_true(electric_power.checked_eval(env) is None)
}

///|
/// Missing inputs are reported through the formula error path.
test "ohm voltage rejects missing resistance" {
  let env = @common.FormulaEnv::new().with_input(
    "current",
    @quantity.Quantity::new(2.0, @si.ampere),
  )
  assert_true(ohm_voltage.checked_eval(env) is None)
}
