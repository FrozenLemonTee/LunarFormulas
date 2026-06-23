///|
/// What went wrong while building a formula object from a `FormulaTerm`.
///
/// Construction of a `FormulaTerm` itself never fails: combining terms only
/// merges expression nodes and input metadata. Conflicts are surfaced at the
/// `Formula::from_term` boundary, mirroring the way LunarUnits keeps quantity
/// algebra total and defers dimension rejection to a checked operation.
pub suberror FormulaBuildError {
  InputDimensionConflict((String, @dimension.Dimension, @dimension.Dimension))
} derive(Eq, Debug)

///|
/// Human-readable formula build errors.
pub impl Show for FormulaBuildError with fn output(self, logger) {
  let message = match self {
    InputDimensionConflict((name, _first, _second)) =>
      "input \"\{name}\" appears with conflicting dimensions in the formula term"
  }
  logger.write_string(message)
}

///|
/// A DSL wrapper that lets formula expressions be written like ordinary math.
///
/// `FormulaTerm` carries both the underlying `FormulaExpr` AST and the input
/// metadata gathered from the variables used to build it. Combining terms with
/// `*`, `/`, `add`, `sub` and `pow` composes the AST and merges the inputs, so
/// the final `Formula::from_term` no longer needs a hand-written `inputs`
/// array.
///
/// # Example
///
/// ```mbt check
/// test {
///   let mass = input("mass", @dimension.Dimension::mass(), "Mass")
///   let acc = input(
///     "acceleration",
///     @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
///     "Acceleration",
///   )
///   let force = mass * acc
///   assert_eq(force.inputs().length(), 2)
/// }
/// ```
pub struct FormulaTerm {
  expr : FormulaExpr
  inputs : Array[FormulaInput]
}

///|
/// Creates a variable term carrying its own input metadata.
///
/// This is the DSL counterpart of `FormulaExpr::variable`: besides building a
/// `Var` node it records the input name, expected dimension and description so
/// the metadata is collected automatically when terms are combined.
pub fn input(
  name : String,
  dimension : @dimension.Dimension,
  description : String,
) -> FormulaTerm {
  {
    expr: FormulaExpr::variable(name),
    inputs: [FormulaInput::new(name, dimension, description)],
  }
}

///|
/// Creates a dimensionless constant term. Constants contribute no input
/// metadata.
pub fn constant(value : Double) -> FormulaTerm {
  { expr: FormulaExpr::constant(value), inputs: [] }
}

///|
/// Creates a unit-bearing constant term, useful for fixed factors such as
/// expressing torque as energy per radian. Constants contribute no input
/// metadata.
pub fn quantity(value : Double, unit : @unit.Un) -> FormulaTerm {
  { expr: FormulaExpr::quantity(value, unit), inputs: [] }
}

///|
/// Returns the underlying evaluation AST.
pub fn FormulaTerm::expr(self : FormulaTerm) -> FormulaExpr {
  self.expr
}

///|
/// Returns the collected input metadata.
pub fn FormulaTerm::inputs(self : FormulaTerm) -> Array[FormulaInput] {
  self.inputs
}

///|
/// Merges two input lists, keeping the first entry for each
/// `(name, dimension)` pair. Entries that share a name but differ in dimension
/// are both retained so `Formula::from_term` can report the conflict.
fn merge_inputs(
  base : Array[FormulaInput],
  extra : Array[FormulaInput],
) -> Array[FormulaInput] {
  let result : Array[FormulaInput] = []
  for descriptor in base {
    result.push(descriptor)
  }
  for descriptor in extra {
    let mut seen = false
    for existing in result {
      if existing.name() == descriptor.name() &&
        existing.dimension().is_same(descriptor.dimension()) {
        seen = true
        break
      }
    }
    if !seen {
      result.push(descriptor)
    }
  }
  result
}

///|
/// Keeps the first input for each name, dropping later duplicates regardless of
/// dimension. Combined terms are normally already merged, so this only matters
/// for the lenient `from_term` path.
fn dedup_inputs(inputs : Array[FormulaInput]) -> Array[FormulaInput] {
  let result : Array[FormulaInput] = []
  for descriptor in inputs {
    let mut seen = false
    for existing in result {
      if existing.name() == descriptor.name() {
        seen = true
        break
      }
    }
    if !seen {
      result.push(descriptor)
    }
  }
  result
}

///|
/// Reports the first input that appears with conflicting dimensions.
fn check_input_conflicts(
  inputs : Array[FormulaInput],
) -> Unit raise FormulaBuildError {
  for i = 0; i < inputs.length(); i = i + 1 {
    for j = i + 1; j < inputs.length(); j = j + 1 {
      let first = inputs[i]
      let second = inputs[j]
      if first.name() == second.name() &&
        !first.dimension().is_same(second.dimension()) {
        raise InputDimensionConflict(
          (first.name(), first.dimension(), second.dimension()),
        )
      }
    }
  }
}

///|
/// Allows `lhs * rhs` to compose terms, mirroring LunarUnits quantity
/// multiplication. The AST nodes are multiplied and the input metadata merged.
pub impl Mul for FormulaTerm with fn mul(
  self : FormulaTerm,
  other : FormulaTerm,
) -> FormulaTerm {
  {
    expr: self.expr.mul(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
  }
}

///|
/// Allows `lhs / rhs` to compose terms, mirroring LunarUnits quantity division.
pub impl Div for FormulaTerm with fn div(
  self : FormulaTerm,
  other : FormulaTerm,
) -> FormulaTerm {
  {
    expr: self.expr.div(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
  }
}

///|
/// Composes an addition term. Like LunarUnits, building the AST is total; a
/// dimension mismatch only surfaces at evaluation time.
pub fn FormulaTerm::add(self : FormulaTerm, other : FormulaTerm) -> FormulaTerm {
  {
    expr: self.expr.add(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
  }
}

///|
/// Composes a subtraction term. Building the AST is total; a dimension mismatch
/// only surfaces at evaluation time.
pub fn FormulaTerm::sub(self : FormulaTerm, other : FormulaTerm) -> FormulaTerm {
  {
    expr: self.expr.sub(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
  }
}

///|
/// Composes an integer-power term. LunarUnits uses `.pow(n)` rather than `^`
/// for physical powers, and the DSL follows the same convention.
pub fn FormulaTerm::pow(self : FormulaTerm, exponent : Int) -> FormulaTerm {
  { expr: self.expr.pow(exponent), inputs: merge_inputs([], self.inputs) }
}

///|
/// Builds a formula object from a DSL term, collecting input metadata
/// automatically.
///
/// Inputs are deduplicated by name, keeping the first occurrence. This lenient
/// constructor never fails, so it can be used directly in top-level `let`
/// formula definitions. Use `Formula::checked_from_term` when you want a
/// conflicting input dimension to be reported instead of silently ignored.
///
/// # Example
///
/// ```mbt check
/// test {
///   let mass = input("mass", @dimension.Dimension::mass(), "Mass")
///   let acc = input(
///     "acceleration",
///     @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
///     "Acceleration",
///   )
///   let force = Formula::from_term(
///     "force",
///     mass * acc,
///     @dimension.Dimension::mass()
///     .mul(@dimension.Dimension::length())
///     .div(@dimension.Dimension::time().pow(2)),
///     "F = m * a",
///     "Computes force from mass and acceleration.",
///   )
///   assert_eq(force.inputs().length(), 2)
/// }
/// ```
pub fn Formula::from_term(
  name : String,
  term : FormulaTerm,
  output : @dimension.Dimension,
  display : String,
  description : String,
) -> Formula {
  Formula::new(
    name,
    dedup_inputs(term.inputs),
    output,
    term.expr,
    display,
    description,
  )
}

///|
/// Strict `Formula::from_term`: validates that no input name appears with two
/// different dimensions before building the formula.
///
/// Mirrors the `eval` / `checked_eval` pairing in this package — the bare
/// constructor is total, while this one performs the dimension-consistency
/// check and raises `InputDimensionConflict` on failure. Because it can raise,
/// call it inside a function body rather than a top-level `let`.
pub fn Formula::checked_from_term(
  name : String,
  term : FormulaTerm,
  output : @dimension.Dimension,
  display : String,
  description : String,
) -> Formula raise FormulaBuildError {
  check_input_conflicts(term.inputs)
  Formula::new(
    name,
    dedup_inputs(term.inputs),
    output,
    term.expr,
    display,
    description,
  )
}
