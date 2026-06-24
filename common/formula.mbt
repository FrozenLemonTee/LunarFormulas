///|
/// A named formula input with an expected physical dimension.
///
/// Like a LunarUnits `Un`, which carries only a symbol and a dimension, a
/// formula input carries only the name used to bind it at evaluation time and
/// the dimension it is expected to have. It deliberately holds no human-facing
/// description: a `Formula` is an anonymous, composable value, not a documented
/// metadata object.
///
/// # Example
///
/// ```mbt check
/// test {
///   let input = FormulaInput::new("mass", @dimension.Dimension::mass())
///   assert_eq(input.name(), "mass")
///   assert_true(input.dimension().is_same(@dimension.Dimension::mass()))
/// }
/// ```
pub struct FormulaInput {
  name : String
  dimension : @dimension.Dimension
} derive(Eq, Debug)

///|
/// Creates a formula input descriptor.
///
/// ```mbt check
/// test {
///   assert_eq(
///     FormulaInput::new("mass", @dimension.Dimension::mass()).name(),
///     "mass",
///   )
/// }
/// ```
pub fn FormulaInput::new(
  name : String,
  dimension : @dimension.Dimension,
) -> FormulaInput {
  { name, dimension }
}

///|
/// Returns the input name.
///
/// ```mbt check
/// test {
///   assert_eq(FormulaInput::new("t", @dimension.Dimension::time()).name(), "t")
/// }
/// ```
pub fn FormulaInput::name(self : FormulaInput) -> String {
  self.name
}

///|
/// Returns the expected input dimension.
///
/// ```mbt check
/// test {
///   let i = FormulaInput::new("t", @dimension.Dimension::time())
///   assert_true(i.dimension().is_same(@dimension.Dimension::time()))
/// }
/// ```
pub fn FormulaInput::dimension(self : FormulaInput) -> @dimension.Dimension {
  self.dimension
}

///|
/// An anonymous, composable, quantity-valued formula.
///
/// `Formula` is the LunarFormulas counterpart of a LunarUnits `Un`: just as
/// `meter / second.pow(2)` is an anonymous unit value you can use directly, a
/// `Formula` such as `mass * acceleration` is an anonymous value you can
/// compose with `*`, `/`, `add`, `sub` and `.pow(n)` and then evaluate. It
/// carries no name, display string or description — only the data needed to
/// evaluate and to keep dimensions consistent:
///
/// - `expr`: the evaluation AST;
/// - `inputs`: the free variables it reads, each with an expected dimension;
/// - `dimension`: the dimension of the value it computes, synthesised as the
///   formula is composed (exactly as LunarUnits propagates dimensions through
///   `Un` and `Quantity`).
///
/// # Example
///
/// ```mbt check
/// test {
///   let mass = input("mass", @dimension.Dimension::mass())
///   let acc = input(
///     "acceleration",
///     @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
///   )
///   let force = mass * acc
///   assert_eq(force.inputs().length(), 2)
/// }
/// ```
pub struct Formula {
  expr : FormulaExpr
  inputs : Array[FormulaInput]
  dimension : @dimension.Dimension
}

///|
/// Creates a variable formula carrying its own input metadata.
///
/// This is the DSL counterpart of `FormulaExpr::variable`: besides building a
/// `Var` node it records the input name and expected dimension so the metadata
/// is collected automatically when formulas are combined. It is the one place
/// where an input name is written down, mirroring `Un::base("m", …)`.
///
/// ```mbt check
/// test {
///   let mass = input("mass", @dimension.Dimension::mass())
///   assert_eq(mass.inputs().length(), 1)
///   assert_true(mass.dimension().is_same(@dimension.Dimension::mass()))
/// }
/// ```
pub fn input(name : String, dimension : @dimension.Dimension) -> Formula {
  {
    expr: FormulaExpr::variable(name),
    inputs: [FormulaInput::new(name, dimension)],
    dimension,
  }
}

///|
/// Creates a dimensionless constant formula. Constants contribute no input.
///
/// ```mbt check
/// test {
///   let half = constant(0.5)
///   assert_eq(half.inputs().length(), 0)
///   assert_true(half.dimension().is_dimensionless())
/// }
/// ```
pub fn constant(value : Double) -> Formula {
  {
    expr: FormulaExpr::constant(value),
    inputs: [],
    dimension: @dimension.Dimension::dimensionless(),
  }
}

///|
/// Creates a unit-bearing constant formula, useful for fixed factors such as
/// expressing torque as energy per radian. Constants contribute no input.
///
/// ```mbt check
/// test {
///   let rad = @unit.Un::base("rad", @dimension.Dimension::custom("angle"))
///   assert_true(quantity(1.0, rad).dimension().is_same(rad.dimension()))
/// }
/// ```
pub fn quantity(value : Double, unit : @unit.Un) -> Formula {
  {
    expr: FormulaExpr::quantity(value, unit),
    inputs: [],
    dimension: unit.dimension(),
  }
}

///|
/// Returns the underlying evaluation AST.
///
/// ```mbt check
/// test {
///   let x = input("x", @dimension.Dimension::length())
///   assert_true(x.expr() == FormulaExpr::variable("x"))
/// }
/// ```
pub fn Formula::expr(self : Formula) -> FormulaExpr {
  self.expr
}

///|
/// Returns the collected input metadata.
///
/// ```mbt check
/// test {
///   let f = input("a", @dimension.Dimension::mass()) *
///     input("b", @dimension.Dimension::time())
///   assert_eq(f.inputs().length(), 2)
/// }
/// ```
pub fn Formula::inputs(self : Formula) -> Array[FormulaInput] {
  self.inputs
}

///|
/// Returns the dimension of the value this formula computes.
///
/// The dimension is synthesised as formulas are combined, the same way
/// LunarUnits propagates dimensions through `Un` and `Quantity`.
///
/// ```mbt check
/// test {
///   let mass = input("mass", @dimension.Dimension::mass())
///   assert_true(mass.dimension().is_same(@dimension.Dimension::mass()))
/// }
/// ```
pub fn Formula::dimension(self : Formula) -> @dimension.Dimension {
  self.dimension
}

///|
/// Merges two input lists, keeping the first entry for each `(name, dimension)`
/// pair. Entries that share a name but differ in dimension are both retained;
/// the conflict then surfaces naturally at evaluation, where the environment can
/// bind a single value per name and only one dimension can match.
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
/// Allows `lhs * rhs` to compose formulas, mirroring LunarUnits quantity
/// multiplication. The AST nodes are multiplied, the inputs merged and the
/// dimensions combined.
///
/// ```mbt check
/// test {
///   let area = input("w", @dimension.Dimension::length()) *
///     input("h", @dimension.Dimension::length())
///   assert_true(area.dimension().is_same(@dimension.Dimension::length().pow(2)))
/// }
/// ```
pub impl Mul for Formula with fn mul(self : Formula, other : Formula) -> Formula {
  {
    expr: self.expr.mul(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
    dimension: self.dimension.mul(other.dimension),
  }
}

///|
/// Allows `lhs / rhs` to compose formulas, mirroring LunarUnits quantity
/// division.
///
/// ```mbt check
/// test {
///   let speed = input("d", @dimension.Dimension::length()) /
///     input("t", @dimension.Dimension::time())
///   assert_true(
///     speed
///     .dimension()
///     .is_same(@dimension.Dimension::length().div(@dimension.Dimension::time())),
///   )
/// }
/// ```
pub impl Div for Formula with fn div(self : Formula, other : Formula) -> Formula {
  {
    expr: self.expr.div(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
    dimension: self.dimension.div(other.dimension),
  }
}

///|
/// Composes an addition. Like LunarUnits, building the AST is total; a real
/// left/right dimension mismatch stays total here and is surfaced at evaluation
/// time. The synthesised dimension is the left one.
///
/// ```mbt check
/// test {
///   let len = input("a", @dimension.Dimension::length())
///   assert_true(len.add(len).dimension().is_same(@dimension.Dimension::length()))
/// }
/// ```
pub fn Formula::add(self : Formula, other : Formula) -> Formula {
  {
    expr: self.expr.add(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
    dimension: self.dimension,
  }
}

///|
/// Composes a subtraction. Like `add`, building the AST is total and the
/// synthesised dimension is the left one, deferring any mismatch to evaluation.
///
/// ```mbt check
/// test {
///   let len = input("a", @dimension.Dimension::length())
///   assert_true(len.sub(len).dimension().is_same(@dimension.Dimension::length()))
/// }
/// ```
pub fn Formula::sub(self : Formula, other : Formula) -> Formula {
  {
    expr: self.expr.sub(other.expr),
    inputs: merge_inputs(self.inputs, other.inputs),
    dimension: self.dimension,
  }
}

///|
/// Composes an integer power. LunarUnits uses `.pow(n)` rather than `^` for
/// physical powers, and the DSL follows the same convention.
///
/// ```mbt check
/// test {
///   let len = input("s", @dimension.Dimension::length())
///   assert_true(
///     len.pow(3).dimension().is_same(@dimension.Dimension::length().pow(3)),
///   )
/// }
/// ```
pub fn Formula::pow(self : Formula, exponent : Int) -> Formula {
  {
    expr: self.expr.pow(exponent),
    inputs: merge_inputs([], self.inputs),
    dimension: self.dimension.pow(exponent),
  }
}

///|
/// Returns a copy of a single-variable formula with its input renamed.
///
/// Predefined variables carry a fixed name, so building a formula that uses the
/// same physical quantity twice (for example two masses `m1` and `m2`) needs a
/// way to derive distinct, renamed variables. This is that operation: it keeps
/// the dimension and produces a fresh variable bound to `name`.
///
/// It is only meaningful for a bare variable formula. Applied to a composed
/// formula it returns the receiver unchanged, since renaming a whole expression
/// has no single input to rename.
///
/// # Example
///
/// ```mbt check
/// test {
///   let mass = input("mass", @dimension.Dimension::mass())
///   let m1 = mass.renamed("m1")
///   let m2 = mass.renamed("m2")
///   let total = m1.add(m2)
///   assert_eq(total.inputs().length(), 2)
/// }
/// ```
pub fn Formula::renamed(self : Formula, name : String) -> Formula {
  match self.expr {
    Var(_) => input(name, self.dimension)
    _ => self
  }
}

///|
/// Checks that every input exists in the environment with the expected
/// dimension.
fn Formula::check_inputs(
  self : Formula,
  env : FormulaEnv,
) -> Unit raise FormulaError {
  for descriptor in self.inputs {
    match env.get(descriptor.name()) {
      None => raise MissingInput(descriptor.name())
      Some(value) =>
        if !value.dimension().is_same(descriptor.dimension()) {
          raise InputDimensionMismatch(
            (descriptor.name(), descriptor.dimension(), value.dimension()),
          )
        }
    }
  }
}

///|
/// Evaluates the formula against an environment.
///
/// Inputs are checked by dimension before evaluation, and the expression is
/// evaluated over LunarUnits quantities. There is no declared output dimension
/// to verify: the result dimension simply is `self.dimension()`, synthesised
/// while the formula was composed.
///
/// # Example
///
/// ```mbt check
/// test {
///   let meter = @unit.Un::base("m", @dimension.Dimension::length())
///   let second = @unit.Un::base("s", @dimension.Dimension::time())
///   let kilogram = @unit.Un::base("kg", @dimension.Dimension::mass())
///   let mass = input("mass", @dimension.Dimension::mass())
///   let acc = input(
///     "acceleration",
///     @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
///   )
///   let force = mass * acc
///   let env = FormulaEnv::new()
///     .with_input("mass", @quantity.Quantity::new(2.0, kilogram))
///     .with_input(
///       "acceleration",
///       @quantity.Quantity::new(3.0, meter.div(second.pow(2))),
///     )
///   assert_eq(force.eval(env).value(), 6.0)
/// }
/// ```
pub fn Formula::eval(
  self : Formula,
  env : FormulaEnv,
) -> @quantity.Quantity raise FormulaError {
  self.check_inputs(env)
  self.expr.eval(env)
}

///|
/// Non-raising formula evaluation. Returns `None` for any formula error.
///
/// ```mbt check
/// test {
///   let x = input("x", @dimension.Dimension::length())
///   // No binding for "x", so evaluation fails and returns None.
///   assert_true(x.checked_eval(FormulaEnv::new()) is None)
/// }
/// ```
pub fn Formula::checked_eval(
  self : Formula,
  env : FormulaEnv,
) -> @quantity.Quantity? {
  Some(self.eval(env)) catch {
    _ => None
  }
}
