///|
/// A named formula input with an expected physical dimension.
///
/// # Example
///
/// ```mbt check
/// test {
///   let input = FormulaInput::new(
///     "mass",
///     @dimension.Dimension::mass(),
///     "Body mass",
///   )
///   assert_eq(input.name(), "mass")
///   assert_true(input.dimension().is_same(@dimension.Dimension::mass()))
/// }
/// ```
pub struct FormulaInput {
  name : String
  dimension : @dimension.Dimension
  description : String
} derive(Eq, Debug)

///|
/// Creates a formula input descriptor.
pub fn FormulaInput::new(
  name : String,
  dimension : @dimension.Dimension,
  description : String,
) -> FormulaInput {
  { name, dimension, description }
}

///|
/// Returns the input name.
pub fn FormulaInput::name(self : FormulaInput) -> String {
  self.name
}

///|
/// Returns the expected input dimension.
pub fn FormulaInput::dimension(self : FormulaInput) -> @dimension.Dimension {
  self.dimension
}

///|
/// Returns a short user-facing input description.
pub fn FormulaInput::description(self : FormulaInput) -> String {
  self.description
}

///|
/// A first-class, quantity-valued formula.
///
/// Formula objects carry enough metadata for tests, documentation, CLIs and
/// UIs to inspect their inputs and declared output. Evaluation consumes a
/// `FormulaEnv` and rejects missing or dimensionally incompatible values.
pub struct Formula {
  name : String
  inputs : Array[FormulaInput]
  output : @dimension.Dimension
  expr : FormulaExpr
  display : String
  description : String
} derive(Eq, Debug)

///|
/// Creates a formula object.
pub fn Formula::new(
  name : String,
  inputs : Array[FormulaInput],
  output : @dimension.Dimension,
  expr : FormulaExpr,
  display : String,
  description : String,
) -> Formula {
  { name, inputs, output, expr, display, description }
}

///|
/// Returns the formula name.
pub fn Formula::name(self : Formula) -> String {
  self.name
}

///|
/// Returns the input descriptors.
pub fn Formula::inputs(self : Formula) -> Array[FormulaInput] {
  self.inputs
}

///|
/// Returns the declared output dimension.
pub fn Formula::output(self : Formula) -> @dimension.Dimension {
  self.output
}

///|
/// Returns the expression tree used for evaluation.
pub fn Formula::expr(self : Formula) -> FormulaExpr {
  self.expr
}

///|
/// Returns a compact display equation, such as `F = m * a`.
pub fn Formula::display(self : Formula) -> String {
  self.display
}

///|
/// Returns the formula description.
pub fn Formula::description(self : Formula) -> String {
  self.description
}

///|
/// Checks that every declared input exists and has the expected dimension.
fn Formula::check_inputs(
  self : Formula,
  env : FormulaEnv,
) -> Unit raise FormulaError {
  for input in self.inputs {
    match env.get(input.name()) {
      None => raise MissingInput(input.name())
      Some(value) =>
        if !value.dimension().is_same(input.dimension()) {
          raise InputDimensionMismatch(
            (input.name(), input.dimension(), value.dimension()),
          )
        }
    }
  }
}

///|
/// Evaluates the formula against an environment.
///
/// # Example
///
/// ```mbt check
/// test {
///   let meter = @unit.Un::base("m", @dimension.Dimension::length())
///   let formula = Formula::new(
///     "double_distance",
///     [FormulaInput::new("distance", @dimension.Dimension::length(), "Distance")],
///     @dimension.Dimension::length(),
///     FormulaExpr::constant(2.0).mul(FormulaExpr::variable("distance")),
///     "d2 = 2 * d",
///     "Doubles a distance.",
///   )
///   let env = FormulaEnv::new().with_input(
///     "distance",
///     @quantity.Quantity::new(3.0, meter),
///   )
///   assert_eq(formula.eval(env).value(), 6.0)
/// }
/// ```
pub fn Formula::eval(
  self : Formula,
  env : FormulaEnv,
) -> @quantity.Quantity raise FormulaError {
  self.check_inputs(env)
  let result = self.expr.eval(env)
  if !result.dimension().is_same(self.output) {
    raise OutputDimensionMismatch((self.output, result.dimension()))
  }
  result
}

///|
/// Non-raising formula evaluation. Returns `None` for any formula error.
pub fn Formula::checked_eval(
  self : Formula,
  env : FormulaEnv,
) -> @quantity.Quantity? {
  Some(self.eval(env)) catch {
    _ => None
  }
}
