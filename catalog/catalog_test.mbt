///|
/// Catalog presets expose all shipped formula entries.
test "catalog presets contain shipped formulas" {
  assert_eq(mechanics().entries().length(), 6)
  assert_eq(electrical().entries().length(), 5)
  assert_eq(thermal().entries().length(), 3)
  assert_eq(all().entries().length(), 14)
}

///|
/// Lookup returns entries by stable kebab-case name.
test "catalog lookup returns formula metadata" {
  let entry = all().lookup("ohm-voltage").unwrap()
  assert_eq(entry.name(), "ohm-voltage")
  assert_eq(entry.domain(), "electrical")
  assert_eq(entry.display(), "V = I * R")
  assert_true(
    entry.output_dimension().is_same(@electrical_units.volt.dimension()),
  )
}

///|
/// Unknown formula names return None.
test "catalog lookup misses unknown formulas" {
  assert_true(all().lookup("missing-formula") is None)
}

///|
/// FormulaEntry delegates evaluation to its anonymous formula.
test "catalog entry eval matches direct formula eval" {
  let env = @common.FormulaEnv::new()
    .with_input("current", @quantity.Quantity::new(2.0, @si.ampere))
    .with_input("resistance", @qelectromagnetism.ohms(5.0))
  let via_entry = all().lookup("ohm-voltage").unwrap().eval(env)
  let direct = @formula_electrical.ohm_voltage.eval(env)
  assert_eq(
    via_entry.to(@electrical_units.volt).value(),
    direct.to(@electrical_units.volt).value(),
  )
}

///|
/// Entry inputs can drive an application-style binding flow.
test "catalog entry inputs support application binding" {
  let entry = all().lookup("force").unwrap()
  let inputs = entry.inputs()
  assert_eq(inputs.length(), 2)
  let env = @common.FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
    .with_input(
      "acceleration",
      @quantity.Quantity::new(3.0, @si.meter / @si.second.pow(2)),
    )
  let result = entry.eval(env).to(@mechanical_units.newton)
  assert_eq(result.value(), 6.0)
}

///|
/// `with_entry` uses last-write-wins, and `merge` lets later catalogs override.
test "catalog with entry and merge are immutable" {
  let first = FormulaEntry::new(
    "x", "test", "x = 1", "first", @formula_mechanics.force_formula,
  )
  let second = FormulaEntry::new(
    "x", "test", "x = 2", "second", @formula_mechanics.work_formula,
  )
  let base = Catalog::new().with_entry(first)
  let replaced = base.merge(Catalog::new().with_entry(second))
  assert_eq(base.lookup("x").unwrap().description(), "first")
  assert_eq(replaced.lookup("x").unwrap().description(), "second")
}
