///|
/// Thermal formula dimensions are inferred from composition.
test "thermal formula dimensions are inferred correctly" {
  assert_true(
    sensible_heat.dimension().is_same(@mechanical_units.joule.dimension()),
  )
  assert_true(
    conduction_heat_rate.dimension().is_same(@mechanical_units.watt.dimension()),
  )
  assert_true(
    convection_heat_rate.dimension().is_same(@mechanical_units.watt.dimension()),
  )
}

///|
/// Sensible heat evaluates m c dT.
test "sensible heat evaluates mass specific heat and temperature difference" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @qmass.kilograms(2.0))
    .with_input("specific_heat", @qthermal.joules_per_kilogram_kelvin(4186.0))
    .with_input(
      "temperature_difference",
      @quantity.Quantity::new(10.0, @si.kelvin),
    )
  let heat = sensible_heat.eval(env).to(@mechanical_units.joule)
  assert_eq(heat.value(), 83720.0)
}

///|
/// Conductive heat transfer evaluates k A dT / L.
test "conduction heat rate evaluates fourier one dimensional rate" {
  let env = @common.FormulaEnv::new()
    .with_input("thermal_conductivity", @qthermal.watts_per_meter_kelvin(200.0))
    .with_input("area", @qgeometry.square_meters(0.5))
    .with_input(
      "temperature_difference",
      @quantity.Quantity::new(10.0, @si.kelvin),
    )
    .with_input("thickness", @qgeometry.meters(0.1))
  let rate = conduction_heat_rate.eval(env).to(@mechanical_units.watt)
  assert_eq(rate.value(), 10000.0)
}

///|
/// Convective heat transfer evaluates h A dT.
test "convection heat rate evaluates newton cooling rate" {
  let env = @common.FormulaEnv::new()
    .with_input(
      "heat_transfer_coefficient",
      @qthermal.watts_per_square_meter_kelvin(25.0),
    )
    .with_input("area", @qgeometry.square_meters(2.0))
    .with_input(
      "temperature_difference",
      @quantity.Quantity::new(10.0, @si.kelvin),
    )
  let rate = convection_heat_rate.eval(env).to(@mechanical_units.watt)
  assert_eq(rate.value(), 500.0)
}

///|
/// Thermal formulas reject absolute-temperature-shaped mistakes at the boundary:
/// the formula input is a kelvin interval quantity, not a length or point.
test "sensible heat rejects non temperature difference input" {
  let env = @common.FormulaEnv::new()
    .with_input("mass", @qmass.kilograms(2.0))
    .with_input("specific_heat", @qthermal.joules_per_kilogram_kelvin(4186.0))
    .with_input("temperature_difference", @qgeometry.meters(10.0))
  assert_true(sensible_heat.checked_eval(env) is None)
}

///|
/// Absolute affine temperature points are adapted at the boundary by taking a
/// difference, which yields the linear kelvin interval that the formula expects.
test "affine temperature points produce interval before entering formula" {
  let hot = @affine.Point::new(80.0, @affine.celsius)
  let cold = @affine.Point::new(20.0, @affine.celsius)
  let delta = hot.difference(cold)
  let env = @common.FormulaEnv::new()
    .with_input("mass", @qmass.kilograms(1.0))
    .with_input("specific_heat", @qthermal.joules_per_kilogram_kelvin(1000.0))
    .with_input("temperature_difference", delta)
  let heat = sensible_heat.eval(env).to(@mechanical_units.joule)
  assert_eq(heat.value(), 60000.0)
}

///|
test "sensible heat normalizes compatible mass units" {
  let heat = sensible_heat.eval(
    @common.FormulaEnv::new()
    .with_input("mass", @qmass.grams(2.0))
    .with_input("specific_heat", @qthermal.joules_per_kilogram_kelvin(4186.0))
    .with_input(
      "temperature_difference",
      @quantity.Quantity::new(10.0, @si.kelvin),
    ),
  )
  assert_eq(heat.value(), 83.72)
  assert_true(heat.unit().is_compatible(@mechanical_units.joule))
}
