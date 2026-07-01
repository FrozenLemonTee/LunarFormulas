///|
/// A discoverable formula entry for application layers.
///
/// `Formula` remains anonymous and composable. `FormulaEntry` is the adapter
/// that gives an application a stable name, domain and display text without
/// adding metadata fields to the core formula value.
pub struct FormulaEntry {
  name : String
  domain : String
  display : String
  description : String
  formula : @common.Formula
}

///|
/// Creates a formula catalog entry.
pub fn FormulaEntry::new(
  name : String,
  domain : String,
  display : String,
  description : String,
  formula : @common.Formula,
) -> FormulaEntry {
  { name, domain, display, description, formula }
}

///|
/// The stable kebab-case formula name used by CLIs, URLs and JSON APIs.
pub fn FormulaEntry::name(self : FormulaEntry) -> String {
  self.name
}

///|
/// The formula domain, such as `mechanics`, `electrical` or `thermal`.
pub fn FormulaEntry::domain(self : FormulaEntry) -> String {
  self.domain
}

///|
/// A compact equation display string.
pub fn FormulaEntry::display(self : FormulaEntry) -> String {
  self.display
}

///|
/// A one-sentence description for list/show UIs.
pub fn FormulaEntry::description(self : FormulaEntry) -> String {
  self.description
}

///|
/// The wrapped anonymous formula value.
pub fn FormulaEntry::formula(self : FormulaEntry) -> @common.Formula {
  self.formula
}

///|
/// Delegates to the wrapped formula's inputs.
pub fn FormulaEntry::inputs(self : FormulaEntry) -> Array[@common.FormulaInput] {
  self.formula.inputs()
}

///|
/// Delegates to the wrapped formula's output dimension.
pub fn FormulaEntry::output_dimension(
  self : FormulaEntry,
) -> @dimension.Dimension {
  self.formula.dimension()
}

///|
/// Evaluates the wrapped formula.
pub fn FormulaEntry::eval(
  self : FormulaEntry,
  env : @common.FormulaEnv,
) -> @quantity.Quantity raise @common.FormulaError {
  self.formula.eval(env)
}

///|
/// Non-raising entry evaluation.
pub fn FormulaEntry::checked_eval(
  self : FormulaEntry,
  env : @common.FormulaEnv,
) -> @quantity.Quantity? {
  self.formula.checked_eval(env)
}

///|
/// A name-indexed collection of formula entries.
pub struct Catalog {
  entries : Map[String, FormulaEntry]
}

///|
/// Creates an empty formula catalog.
pub fn Catalog::new() -> Catalog {
  { entries: Map([]) }
}

///|
/// Copies the catalog entries into a fresh map.
fn Catalog::copy_entries(self : Catalog) -> Map[String, FormulaEntry] {
  let entries : Map[String, FormulaEntry] = Map([])
  self.entries.each(fn(name, entry) { entries[name] = entry })
  entries
}

///|
/// Returns a new catalog with `entry` bound by its name. Later entries win.
pub fn Catalog::with_entry(self : Catalog, entry : FormulaEntry) -> Catalog {
  let entries = self.copy_entries()
  entries[entry.name()] = entry
  { entries, }
}

///|
/// Merges two catalogs. Entries from `other` win on name conflicts.
pub fn Catalog::merge(self : Catalog, other : Catalog) -> Catalog {
  let entries = self.copy_entries()
  other.entries.each(fn(name, entry) { entries[name] = entry })
  { entries, }
}

///|
/// Looks up a formula entry by stable name.
pub fn Catalog::lookup(self : Catalog, name : String) -> FormulaEntry? {
  self.entries.get(name)
}

///|
/// Returns all stable formula names.
pub fn Catalog::names(self : Catalog) -> Array[String] {
  let names : Array[String] = []
  self.entries.each(fn(name, _entry) { names.push(name) })
  names
}

///|
/// Returns all formula entries.
pub fn Catalog::entries(self : Catalog) -> Array[FormulaEntry] {
  let entries : Array[FormulaEntry] = []
  self.entries.each(fn(_name, entry) { entries.push(entry) })
  entries
}

///|
/// Predefined mechanics formula catalog.
pub fn mechanics() -> Catalog {
  Catalog::new()
  .with_entry(
    FormulaEntry::new(
      "force", "mechanics", "F = m * a", "Newton's second law solved for force.",
      @formula_mechanics.force_formula,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "work", "mechanics", "W = F * d", "Linear work from force over distance.",
      @formula_mechanics.work_formula,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "power", "mechanics", "P = W / t", "Mechanical power from work over elapsed time.",
      @formula_mechanics.power_formula,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "kinetic-energy", "mechanics", "E_k = 1/2 * m * v^2", "Translational kinetic energy.",
      @formula_mechanics.kinetic_energy_formula,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "torque", "mechanics", "tau = F * r / rad", "Torque as energy per angle.",
      @formula_mechanics.torque_formula,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "rotational-work", "mechanics", "W = tau * theta", "Rotational work from torque and angle.",
      @formula_mechanics.rotational_work_formula,
    ),
  )
}

///|
/// Predefined electrical formula catalog.
pub fn electrical() -> Catalog {
  Catalog::new()
  .with_entry(
    FormulaEntry::new(
      "ohm-voltage", "electrical", "V = I * R", "Ohm's law solved for voltage.",
      @formula_electrical.ohm_voltage,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "electric-power", "electrical", "P = V * I", "Electric power from voltage and current.",
      @formula_electrical.electric_power,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "joule-heating-power", "electrical", "P = I^2 * R", "Joule-heating power from current and resistance.",
      @formula_electrical.joule_heating_power,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "electric-charge", "electrical", "Q = I * t", "Electric charge from current over elapsed time.",
      @formula_electrical.electric_charge,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "electric-energy", "electrical", "E = P * t", "Electric energy from power over elapsed time.",
      @formula_electrical.electric_energy,
    ),
  )
}

///|
/// Predefined thermal formula catalog.
pub fn thermal() -> Catalog {
  Catalog::new()
  .with_entry(
    FormulaEntry::new(
      "sensible-heat", "thermal", "Q = m * c * dT", "Sensible heat from mass, specific heat and temperature interval.",
      @formula_thermal.sensible_heat,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "conduction-heat-rate", "thermal", "q = k * A * dT / L", "One-dimensional conductive heat-transfer rate.",
      @formula_thermal.conduction_heat_rate,
    ),
  )
  .with_entry(
    FormulaEntry::new(
      "convection-heat-rate", "thermal", "q = h * A * dT", "Convective heat-transfer rate.",
      @formula_thermal.convection_heat_rate,
    ),
  )
}

///|
/// Predefined catalog containing all shipped formula entries.
pub fn all() -> Catalog {
  mechanics().merge(electrical()).merge(thermal())
}
