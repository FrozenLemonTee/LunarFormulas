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
/// Formula objects check declared input dimensions before returning a result.
test "formula rejects wrong input dimension" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let formula = Formula::new(
    "identity_time",
    [FormulaInput::new("time", @dimension.Dimension::time(), "Elapsed time")],
    @dimension.Dimension::time(),
    FormulaExpr::variable("time"),
    "t = t",
    "Identity over time.",
  )
  let env = FormulaEnv::new().with_input(
    "time",
    @quantity.Quantity::new(3.0, meter),
  )
  assert_true(formula.checked_eval(env) is None)
  let mut caught = false
  try formula.eval(env) |> ignore catch {
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
/// Formula objects also verify the declared output dimension.
test "formula rejects mismatched declared output" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let formula = Formula::new(
    "bad_output",
    [FormulaInput::new("distance", @dimension.Dimension::length(), "Distance")],
    @dimension.Dimension::time(),
    FormulaExpr::variable("distance"),
    "t = d",
    "Deliberately wrong metadata.",
  )
  let env = FormulaEnv::new().with_input(
    "distance",
    @quantity.Quantity::new(3.0, meter),
  )
  let mut caught = false
  try formula.eval(env) |> ignore catch {
    OutputDimensionMismatch((expected, actual)) => {
      caught = true
      assert_true(expected.is_same(@dimension.Dimension::time()))
      assert_true(actual.is_same(@dimension.Dimension::length()))
    }
    _ => ()
  }
  assert_true(caught)
}
