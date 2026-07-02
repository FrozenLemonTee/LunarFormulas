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
pub let voltage : @common.Formula = @common.input_unit(
  "voltage", @electrical_units.volt,
)

///|
/// Input variable: electric current.
///
/// ```mbt check
/// test {
///   assert_true(current.dimension().is_same(@si.ampere.dimension()))
/// }
/// ```
pub let current : @common.Formula = @common.input_unit("current", @si.ampere)

///|
/// Input variable: electric resistance.
///
/// ```mbt check
/// test {
///   assert_true(resistance.dimension().is_same(@electrical_units.ohm.dimension()))
/// }
/// ```
pub let resistance : @common.Formula = @common.input_unit(
  "resistance", @electrical_units.ohm,
)

///|
/// Input variable: electric charge.
///
/// ```mbt check
/// test {
///   assert_true(charge.dimension().is_same(@electrical_units.coulomb.dimension()))
/// }
/// ```
pub let charge : @common.Formula = @common.input_unit(
  "charge", @electrical_units.coulomb,
)

///|
/// Input variable: electric or mechanical power.
///
/// ```mbt check
/// test {
///   assert_true(power.dimension().is_same(@mechanical_units.watt.dimension()))
/// }
/// ```
pub let power : @common.Formula = @common.input_unit(
  "power", @mechanical_units.watt,
)

///|
/// Input variable: elapsed time.
///
/// ```mbt check
/// test {
///   assert_true(time.dimension().is_same(@si.second.dimension()))
/// }
/// ```
pub let time : @common.Formula = @common.input_unit("time", @si.second)

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
