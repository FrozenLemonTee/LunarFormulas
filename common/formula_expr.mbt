///|
/// What went wrong while evaluating a formula.
///
/// The payloads are structured so callers can distinguish missing inputs,
/// rejected input dimensions and expression-level dimension errors.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = input("x", @dimension.Dimension::length())
///   try x.eval(FormulaEnv::new()) |> ignore catch {
///     MissingInput(name) => assert_eq(name, "x")
///     _ => assert_true(false)
///   }
/// }
/// ```
pub suberror FormulaError {
  MissingInput(String)
  InputDimensionMismatch((String, @dimension.Dimension, @dimension.Dimension))
  ExpressionDimensionMismatch((@dimension.Dimension, @dimension.Dimension))
} derive(Eq, Debug)

///|
/// Human-readable formula evaluation errors.
pub impl Show for FormulaError with fn output(self, logger) {
  let message = match self {
    MissingInput(name) => "missing formula input \"\{name}\""
    InputDimensionMismatch((name, _expected, _actual)) =>
      "input \"\{name}\" has an incompatible dimension"
    ExpressionDimensionMismatch((_expected, _actual)) =>
      "formula expression has incompatible dimensions"
  }
  logger.write_string(message)
}

///|
/// A formula evaluation environment: named quantities supplied to variables.
///
/// Environments are immutable. `with_input` returns a fresh environment with
/// the new binding, leaving the receiver unchanged.
///
/// # Example
///
/// ```mbt check
/// test {
///   let env = FormulaEnv::new().with_input(
///     "distance",
///     @quantity.Quantity::new(
///       3.0,
///       @unit.Un::base("m", @dimension.Dimension::length()),
///     ),
///   )
///   assert_true(env.get("distance") is Some(_))
/// }
/// ```
pub struct FormulaEnv {
  values : Map[String, @quantity.Quantity]
}

///|
/// Copies the environment bindings into a fresh map.
fn FormulaEnv::copy_values(
  self : FormulaEnv,
) -> Map[String, @quantity.Quantity] {
  let values : Map[String, @quantity.Quantity] = Map([])
  self.values.each(fn(name, value) { values[name] = value })
  values
}

///|
/// Creates an empty formula environment.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_true(FormulaEnv::new().get("x") is None)
/// }
/// ```
pub fn FormulaEnv::new() -> FormulaEnv {
  { values: Map([]) }
}

///|
/// Returns a new environment with `name` bound to `value`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let meter = @unit.Un::base("m", @dimension.Dimension::length())
///   let env = FormulaEnv::new().with_input(
///     "d",
///     @quantity.Quantity::new(3.0, meter),
///   )
///   assert_true(env.get("d") is Some(_))
/// }
/// ```
pub fn FormulaEnv::with_input(
  self : FormulaEnv,
  name : String,
  value : @quantity.Quantity,
) -> FormulaEnv {
  let values = self.copy_values()
  values[name] = value
  { values, }
}

///|
/// Looks up an input quantity.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_true(FormulaEnv::new().get("missing") is None)
/// }
/// ```
pub fn FormulaEnv::get(self : FormulaEnv, name : String) -> @quantity.Quantity? {
  self.values.get(name)
}

///|
/// A quantity-valued formula expression.
///
/// `FormulaExpr` intentionally evaluates only over `Quantity`. Affine points,
/// logarithmic levels and gains should be converted at the package boundary,
/// not placed into this multiplicative expression tree.
///
/// # Example
///
/// ```mbt check
/// test {
///   let expr = FormulaExpr::variable("x").mul(FormulaExpr::constant(2.0))
///   assert_true(expr is Mul(_, _))
/// }
/// ```
pub(all) enum FormulaExpr {
  Const(Double)
  QuantityConst(Double, @unit.Un)
  Var(String)
  Add(FormulaExpr, FormulaExpr)
  Sub(FormulaExpr, FormulaExpr)
  Mul(FormulaExpr, FormulaExpr)
  Div(FormulaExpr, FormulaExpr)
  Pow(FormulaExpr, Int)
} derive(Eq, Debug)

///|
/// Creates a dimensionless constant expression.
///
/// ```mbt check
/// test {
///   assert_true(FormulaExpr::constant(0.5) is Const(_))
/// }
/// ```
pub fn FormulaExpr::constant(value : Double) -> FormulaExpr {
  Const(value)
}

///|
/// Creates a quantity constant with an explicit unit.
///
/// This is useful for formulas that need a fixed unit-bearing factor, such as
/// expressing torque as energy per radian.
///
/// ```mbt check
/// test {
///   let rad = @unit.Un::base("rad", @dimension.Dimension::custom("angle"))
///   assert_true(FormulaExpr::quantity(1.0, rad) is QuantityConst(_, _))
/// }
/// ```
pub fn FormulaExpr::quantity(value : Double, unit : @unit.Un) -> FormulaExpr {
  QuantityConst(value, unit)
}

///|
/// Creates a variable expression.
///
/// ```mbt check
/// test {
///   assert_true(FormulaExpr::variable("x") is Var(_))
/// }
/// ```
pub fn FormulaExpr::variable(name : String) -> FormulaExpr {
  Var(name)
}

///|
/// Creates an addition expression.
///
/// ```mbt check
/// test {
///   assert_true(
///     FormulaExpr::variable("a").add(FormulaExpr::variable("b")) is Add(_, _),
///   )
/// }
/// ```
pub fn FormulaExpr::add(self : FormulaExpr, other : FormulaExpr) -> FormulaExpr {
  Add(self, other)
}

///|
/// Creates a subtraction expression.
///
/// ```mbt check
/// test {
///   assert_true(
///     FormulaExpr::variable("a").sub(FormulaExpr::variable("b")) is Sub(_, _),
///   )
/// }
/// ```
pub fn FormulaExpr::sub(self : FormulaExpr, other : FormulaExpr) -> FormulaExpr {
  Sub(self, other)
}

///|
/// Creates a multiplication expression.
///
/// ```mbt check
/// test {
///   assert_true(
///     FormulaExpr::variable("a").mul(FormulaExpr::variable("b")) is Mul(_, _),
///   )
/// }
/// ```
pub fn FormulaExpr::mul(self : FormulaExpr, other : FormulaExpr) -> FormulaExpr {
  Mul(self, other)
}

///|
/// Creates a division expression.
///
/// ```mbt check
/// test {
///   assert_true(
///     FormulaExpr::variable("a").div(FormulaExpr::variable("b")) is Div(_, _),
///   )
/// }
/// ```
pub fn FormulaExpr::div(self : FormulaExpr, other : FormulaExpr) -> FormulaExpr {
  Div(self, other)
}

///|
/// Creates an integer-power expression.
///
/// ```mbt check
/// test {
///   assert_true(FormulaExpr::variable("x").pow(2) is Pow(_, _))
/// }
/// ```
pub fn FormulaExpr::pow(self : FormulaExpr, exponent : Int) -> FormulaExpr {
  Pow(self, exponent)
}

///|
/// A scale-1 dimensionless unit used for constants.
fn dimensionless_unit() -> @unit.Un {
  @unit.Un::base("1", @dimension.Dimension::dimensionless()).pow(0)
}

///|
/// Evaluates the expression in `env`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let meter = @unit.Un::base("m", @dimension.Dimension::length())
///   let env = FormulaEnv::new().with_input(
///     "x",
///     @quantity.Quantity::new(2.0, meter),
///   )
///   let expr = FormulaExpr::variable("x").mul(FormulaExpr::constant(3.0))
///   let result = expr.eval(env)
///   assert_eq(result.value(), 6.0)
///   assert_true(result.dimension().is_same(@dimension.Dimension::length()))
/// }
/// ```
pub fn FormulaExpr::eval(
  self : FormulaExpr,
  env : FormulaEnv,
) -> @quantity.Quantity raise FormulaError {
  match self {
    Const(value) => @quantity.Quantity::new(value, dimensionless_unit())
    QuantityConst(value, unit) => @quantity.Quantity::new(value, unit)
    Var(name) =>
      match env.get(name) {
        Some(value) => value
        None => raise MissingInput(name)
      }
    Add(lhs, rhs) => {
      let left = lhs.eval(env)
      let right = rhs.eval(env)
      left.add(right) catch {
        @quantity.DimensionMismatch(payload) =>
          raise ExpressionDimensionMismatch(payload)
      }
    }
    Sub(lhs, rhs) => {
      let left = lhs.eval(env)
      let right = rhs.eval(env)
      left.sub(right) catch {
        @quantity.DimensionMismatch(payload) =>
          raise ExpressionDimensionMismatch(payload)
      }
    }
    Mul(lhs, rhs) => lhs.eval(env).mul(rhs.eval(env))
    Div(lhs, rhs) => lhs.eval(env).div(rhs.eval(env))
    Pow(expr, exponent) => expr.eval(env).pow(exponent)
  }
}
