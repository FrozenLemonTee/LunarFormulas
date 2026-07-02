// Thermal vocabulary: anonymous, composable formula values built on LunarUnits
// linear temperature intervals and thermal units.

///|
/// Input variable: mass.
///
/// ```mbt check
/// test {
///   assert_true(mass.dimension().is_same(@si.kilogram.dimension()))
/// }
/// ```
pub let mass : @common.Formula = @common.input_unit("mass", @si.kilogram)

///|
/// Input variable: specific heat capacity, J/(kg*K).
///
/// ```mbt check
/// test {
///   assert_true(
///     specific_heat
///     .dimension()
///     .is_same(@thermal_units.joule_per_kilogram_kelvin.dimension()),
///   )
/// }
/// ```
pub let specific_heat : @common.Formula = @common.input_unit(
  "specific_heat", @thermal_units.joule_per_kilogram_kelvin,
)

///|
/// Input variable: a temperature difference.
///
/// This is a linear `Quantity` in kelvin, not an affine temperature point. If a
/// caller has two absolute temperatures, it should take their `Point::difference`
/// first and bind that interval here.
///
/// ```mbt check
/// test {
///   assert_true(
///     temperature_difference.dimension().is_same(@si.kelvin.dimension()),
///   )
/// }
/// ```
pub let temperature_difference : @common.Formula = @common.input_unit(
  "temperature_difference", @si.kelvin,
)

///|
/// Input variable: thermal conductivity, W/(m*K).
///
/// ```mbt check
/// test {
///   assert_true(
///     thermal_conductivity
///     .dimension()
///     .is_same(@thermal_units.watt_per_meter_kelvin.dimension()),
///   )
/// }
/// ```
pub let thermal_conductivity : @common.Formula = @common.input_unit(
  "thermal_conductivity", @thermal_units.watt_per_meter_kelvin,
)

///|
/// Input variable: heat-transfer coefficient, W/(m^2*K).
///
/// ```mbt check
/// test {
///   assert_true(
///     heat_transfer_coefficient
///     .dimension()
///     .is_same(@thermal_units.watt_per_square_meter_kelvin.dimension()),
///   )
/// }
/// ```
pub let heat_transfer_coefficient : @common.Formula = @common.input_unit(
  "heat_transfer_coefficient", @thermal_units.watt_per_square_meter_kelvin,
)

///|
/// Input variable: area.
///
/// ```mbt check
/// test {
///   assert_true(area.dimension().is_same(@si.meter.pow(2).dimension()))
/// }
/// ```
pub let area : @common.Formula = @common.input_unit("area", @si.meter.pow(2))

///|
/// Input variable: thickness / conduction path length.
///
/// ```mbt check
/// test {
///   assert_true(thickness.dimension().is_same(@si.meter.dimension()))
/// }
/// ```
pub let thickness : @common.Formula = @common.input_unit("thickness", @si.meter)

///|
/// Sensible heat, `Q = m * c * dT`.
///
/// This is the standard constant-specific-heat relation. The input `dT` is a
/// temperature interval, not an absolute temperature point.
///
/// ```mbt check
/// test {
///   assert_true(
///     sensible_heat.dimension().is_same(@mechanical_units.joule.dimension()),
///   )
/// }
/// ```
pub let sensible_heat : @common.Formula = mass *
  specific_heat *
  temperature_difference

///|
/// One-dimensional conductive heat-transfer rate, `q = k * A * dT / L`.
///
/// ```mbt check
/// test {
///   assert_true(
///     conduction_heat_rate.dimension().is_same(@mechanical_units.watt.dimension()),
///   )
/// }
/// ```
pub let conduction_heat_rate : @common.Formula = thermal_conductivity *
  area *
  temperature_difference /
  thickness

///|
/// Convective heat-transfer rate, `q = h * A * dT`.
///
/// ```mbt check
/// test {
///   assert_true(
///     convection_heat_rate.dimension().is_same(@mechanical_units.watt.dimension()),
///   )
/// }
/// ```
pub let convection_heat_rate : @common.Formula = heat_transfer_coefficient *
  area *
  temperature_difference

///|
/// Enumerates the predefined thermal formulas.
pub fn formulas() -> Array[@common.Formula] {
  [sensible_heat, conduction_heat_rate, convection_heat_rate]
}
