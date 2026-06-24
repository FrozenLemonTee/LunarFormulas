///|
/// A velocity dimension, length / time.
fn velocity_dimension() -> @dimension.Dimension {
  @dimension.Dimension::length().div(@dimension.Dimension::time())
}

///|
/// An acceleration dimension, length / time^2.
fn acceleration_dimension() -> @dimension.Dimension {
  @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2))
}

///|
/// Formula expressions evaluate over quantities and preserve dimensions.
test "formula expr evaluates quantity expressions" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let env = FormulaEnv::new()
    .with_input("a", @quantity.Quantity::new(2.0, meter))
    .with_input("b", @quantity.Quantity::new(3.0, meter))
  let expr = FormulaExpr::variable("a").add(FormulaExpr::variable("b"))
  let result = expr.eval(env)
  assert_eq(result.value(), 5.0)
  assert_true(result.dimension().is_same(@dimension.Dimension::length()))
}

///|
/// Missing variables are reported as FormulaError.
test "missing input raises formula error" {
  let mut caught = false
  try FormulaExpr::variable("missing").eval(FormulaEnv::new()) |> ignore catch {
    MissingInput(name) => {
      caught = true
      assert_eq(name, "missing")
    }
    _ => ()
  }
  assert_true(caught)
}

///|
/// Addition rejects incompatible dimensions inside the expression.
test "expression dimension mismatch is reported" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let second = @unit.Un::base("s", @dimension.Dimension::time())
  let env = FormulaEnv::new()
    .with_input("distance", @quantity.Quantity::new(2.0, meter))
    .with_input("time", @quantity.Quantity::new(3.0, second))
  let expr = FormulaExpr::variable("distance").add(
    FormulaExpr::variable("time"),
  )
  let mut caught = false
  try expr.eval(env) |> ignore catch {
    ExpressionDimensionMismatch((expected, actual)) => {
      caught = true
      assert_true(expected.is_same(@dimension.Dimension::length()))
      assert_true(actual.is_same(@dimension.Dimension::time()))
    }
    _ => ()
  }
  assert_true(caught)
}

///|
/// An input descriptor carries only a name and a dimension.
test "formula input carries a name and a dimension" {
  let descriptor = FormulaInput::new("mass", @dimension.Dimension::mass())
  assert_eq(descriptor.name(), "mass")
  assert_true(descriptor.dimension().is_same(@dimension.Dimension::mass()))
}

///|
/// Combining variable formulas builds the matching AST, collects every input
/// and synthesises the dimension of the result.
test "multiplication builds Mul, gathers inputs and infers the dimension" {
  let mass = input("mass", @dimension.Dimension::mass())
  let acc = input("acceleration", acceleration_dimension())
  let force = mass * acc
  let expected = FormulaExpr::variable("mass").mul(
    FormulaExpr::variable("acceleration"),
  )
  assert_true(force.expr() == expected)
  assert_eq(force.inputs().length(), 2)
  assert_true(
    force
    .dimension()
    .is_same(
      @dimension.Dimension::mass()
      .mul(@dimension.Dimension::length())
      .div(@dimension.Dimension::time().pow(2)),
    ),
  )
}

///|
/// A composed formula is evaluated directly, with no construction step.
test "a composed formula evaluates directly" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let second = @unit.Un::base("s", @dimension.Dimension::time())
  let kilogram = @unit.Un::base("kg", @dimension.Dimension::mass())
  let mass = input("mass", @dimension.Dimension::mass())
  let acc = input("acceleration", acceleration_dimension())
  let force = mass * acc
  let env = FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, kilogram))
    .with_input(
      "acceleration",
      @quantity.Quantity::new(3.0, meter.div(second.pow(2))),
    )
  assert_eq(force.eval(env).value(), 6.0)
}

///|
/// Re-using the same input keeps a single input entry.
test "repeated input is deduplicated" {
  let velocity = input("velocity", velocity_dimension())
  let speed_squared = velocity * velocity
  assert_eq(speed_squared.inputs().length(), 1)
  assert_true(speed_squared.dimension().is_same(velocity_dimension().pow(2)))
}

///|
/// `constant`, `*` and `pow` combine into an evaluable kinetic-energy formula.
test "constants and powers compose like ordinary maths" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let second = @unit.Un::base("s", @dimension.Dimension::time())
  let kilogram = @unit.Un::base("kg", @dimension.Dimension::mass())
  let mass = input("mass", @dimension.Dimension::mass())
  let velocity = input("velocity", velocity_dimension())
  let kinetic_energy = constant(0.5) * mass * velocity.pow(2)
  let env = FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, kilogram))
    .with_input("velocity", @quantity.Quantity::new(3.0, meter.div(second)))
  assert_eq(kinetic_energy.eval(env).value(), 9.0)
}

///|
/// `quantity` builds a unit-bearing constant formula with no inputs.
test "quantity builds a unit-bearing constant" {
  let radian = @unit.Un::base("rad", @dimension.Dimension::custom("angle"))
  let term = quantity(1.0, radian)
  assert_true(term.expr() == FormulaExpr::quantity(1.0, radian))
  assert_eq(term.inputs().length(), 0)
  assert_true(term.dimension().is_same(radian.dimension()))
}

///|
/// Inputs are dimension checked at evaluation: a length supplied where time is
/// expected is rejected.
test "eval rejects a wrong input dimension" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let time = input("time", @dimension.Dimension::time())
  let env = FormulaEnv::new().with_input(
    "time",
    @quantity.Quantity::new(3.0, meter),
  )
  assert_true(time.checked_eval(env) is None)
  let mut caught = false
  try time.eval(env) |> ignore catch {
    InputDimensionMismatch((name, expected, actual)) => {
      caught = true
      assert_eq(name, "time")
      assert_true(expected.is_same(@dimension.Dimension::time()))
      assert_true(actual.is_same(@dimension.Dimension::length()))
    }
    _ => ()
  }
  assert_true(caught)
}

///|
/// Using one input name with two different dimensions is not a construction
/// error: composition stays total. The conflict surfaces at evaluation, where a
/// single bound value can only match one of the two declared dimensions.
test "a conflicting input name surfaces at eval, not at build" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let as_length = input("x", @dimension.Dimension::length())
  let as_time = input("x", @dimension.Dimension::time())
  // Building keeps both descriptors; no error is raised here.
  let bad = as_length * as_time
  assert_eq(bad.inputs().length(), 2)
  // Whatever value we bind to "x", one of the two checks fails.
  let env = FormulaEnv::new().with_input(
    "x",
    @quantity.Quantity::new(1.0, meter),
  )
  assert_true(bad.checked_eval(env) is None)
}

///|
/// Addition keeps the left dimension at construction time and stays total even
/// when the two sides differ; the real mismatch only surfaces during eval.
test "add keeps the left dimension and defers mismatch to eval" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let second = @unit.Un::base("s", @dimension.Dimension::time())
  let a = input("a", @dimension.Dimension::length())
  let b = input("b", @dimension.Dimension::time())
  let mixed_sum = a.add(b)
  assert_true(mixed_sum.dimension().is_same(@dimension.Dimension::length()))
  let env = FormulaEnv::new()
    .with_input("a", @quantity.Quantity::new(1.0, meter))
    .with_input("b", @quantity.Quantity::new(1.0, second))
  assert_true(mixed_sum.checked_eval(env) is None)
}

///|
/// `renamed` derives distinct variables from one predefined variable, so the
/// same physical quantity can appear twice in a formula.
test "renamed derives distinct variables for multi-instance use" {
  let kilogram = @unit.Un::base("kg", @dimension.Dimension::mass())
  let mass = input("mass", @dimension.Dimension::mass())
  let total = mass.renamed("m1").add(mass.renamed("m2"))
  assert_eq(total.inputs().length(), 2)
  let env = FormulaEnv::new()
    .with_input("m1", @quantity.Quantity::new(2.0, kilogram))
    .with_input("m2", @quantity.Quantity::new(3.0, kilogram))
  assert_eq(total.eval(env).value(), 5.0)
  // Renaming a composed formula (not a bare variable) is a no-op.
  let composed = mass * mass.renamed("m2")
  assert_true(composed.renamed("whatever").expr() == composed.expr())
}
