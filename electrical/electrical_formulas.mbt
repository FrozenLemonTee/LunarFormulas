// Electrical vocabulary: anonymous, composable formula values built on
// LunarUnits electrical dimensions and units.

///|
/// Input variable: electric potential / voltage.
///
/// ```mbt check
/// test {
///   assert_true(voltage.dimension().is_same(@electrical_units.volt.dimension()))
/// }
/// ```
pub let voltage : @common.Formula = @common.input(
  "voltage",
  @electrical_units.volt.dimension(),
)

///|
/// Input variable: electric current.
///
/// ```mbt check
/// test {
///   assert_true(
///     current.dimension().is_same(@dimension.Dimension::electric_current()),
///   )
/// }
/// ```
pub let current : @common.Formula = @common.input(
  "current",
  @dimension.Dimension::electric_current(),
)

///|
/// Input variable: electric resistance.
///
/// ```mbt check
/// test {
///   assert_true(resistance.dimension().is_same(@electrical_units.ohm.dimension()))
/// }
/// ```
pub let resistance : @common.Formula = @common.input(
  "resistance",
  @electrical_units.ohm.dimension(),
)

///|
/// Input variable: electric charge.
///
/// ```mbt check
/// test {
///   assert_true(charge.dimension().is_same(@electrical_units.coulomb.dimension()))
/// }
/// ```
pub let charge : @common.Formula = @common.input(
  "charge",
  @electrical_units.coulomb.dimension(),
)

///|
/// Input variable: electric or mechanical power.
///
/// ```mbt check
/// test {
///   assert_true(power.dimension().is_same(@mechanical_units.watt.dimension()))
/// }
/// ```
pub let power : @common.Formula = @common.input(
  "power",
  @mechanical_units.watt.dimension(),
)

///|
/// Input variable: elapsed time.
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
/// Ohm's law solved for voltage, `V = I * R`.
///
/// This formula follows the elementary circuit relation between voltage,
/// current and resistance.
///
/// ```mbt check
/// test {
///   assert_true(
///     ohm_voltage.dimension().is_same(@electrical_units.volt.dimension()),
///   )
/// }
/// ```
pub let ohm_voltage : @common.Formula = current * resistance

///|
/// Electric power from voltage and current, `P = V * I`.
///
/// ```mbt check
/// test {
///   assert_true(
///     electric_power.dimension().is_same(@mechanical_units.watt.dimension()),
///   )
/// }
/// ```
pub let electric_power : @common.Formula = voltage * current

///|
/// Joule-heating power, `P = I^2 * R`.
///
/// ```mbt check
/// test {
///   assert_true(
///     joule_heating_power.dimension().is_same(@mechanical_units.watt.dimension()),
///   )
/// }
/// ```
pub let joule_heating_power : @common.Formula = current.pow(2) * resistance

///|
/// Electric charge from current over time, `Q = I * t`.
///
/// ```mbt check
/// test {
///   assert_true(
///     electric_charge.dimension().is_same(@electrical_units.coulomb.dimension()),
///   )
/// }
/// ```
pub let electric_charge : @common.Formula = current * time

///|
/// Electric energy from power over time, `E = P * t`.
///
/// ```mbt check
/// test {
///   assert_true(
///     electric_energy.dimension().is_same(@mechanical_units.joule.dimension()),
///   )
/// }
/// ```
pub let electric_energy : @common.Formula = power * time

///|
/// Enumerates the predefined electrical formulas.
pub fn formulas() -> Array[@common.Formula] {
  [
    ohm_voltage, electric_power, joule_heating_power, electric_charge, electric_energy,
  ]
}
