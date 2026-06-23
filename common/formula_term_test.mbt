///|
/// A velocity dimension, length / time.
fn velocity_dimension() -> @dimension.Dimension {
  @dimension.Dimension::length().div(@dimension.Dimension::time())
}

///|
/// Combining input terms builds the matching AST and collects every input.
test "term multiplication builds Mul(Var, Var) and gathers inputs" {
  let mass = input("mass", @dimension.Dimension::mass(), "Mass")
  let acc = input(
    "acceleration",
    @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
    "Acceleration",
  )
  let term = mass * acc
  let expected = FormulaExpr::variable("mass").mul(
    FormulaExpr::variable("acceleration"),
  )
  assert_true(term.expr() == expected)
  assert_eq(term.inputs().length(), 2)
}

///|
/// `Formula::from_term` carries the collected inputs onto the formula object.
test "from_term collects formula inputs automatically" {
  let mass = input("mass", @dimension.Dimension::mass(), "Mass")
  let acc = input(
    "acceleration",
    @dimension.Dimension::length().div(@dimension.Dimension::time().pow(2)),
    "Acceleration",
  )
  let formula = Formula::from_term(
    "force",
    mass * acc,
    @dimension.Dimension::mass()
    .mul(@dimension.Dimension::length())
    .div(@dimension.Dimension::time().pow(2)),
    "F = m * a",
    "Computes force from mass and acceleration.",
  )
  assert_eq(formula.inputs().length(), 2)
}

///|
/// Re-using the same input keeps a single metadata entry.
test "repeated input is deduplicated" {
  let velocity = input("velocity", velocity_dimension(), "Velocity")
  let term = velocity * velocity
  let formula = Formula::from_term(
    "speed_squared",
    term,
    velocity_dimension().pow(2),
    "s = v * v",
    "Squares a velocity.",
  )
  assert_eq(formula.inputs().length(), 1)
}

///|
/// `constant`, `*` and `pow` combine into an evaluable kinetic-energy formula.
test "kinetic energy term evaluates" {
  let meter = @unit.Un::base("m", @dimension.Dimension::length())
  let second = @unit.Un::base("s", @dimension.Dimension::time())
  let kilogram = @unit.Un::base("kg", @dimension.Dimension::mass())
  let mass = input("mass", @dimension.Dimension::mass(), "Mass")
  let velocity = input("velocity", velocity_dimension(), "Velocity")
  let formula = Formula::from_term(
    "kinetic_energy",
    constant(0.5) * mass * velocity.pow(2),
    @dimension.Dimension::mass().mul(velocity_dimension().pow(2)),
    "E_k = 1/2 * m * v^2",
    "Computes translational kinetic energy.",
  )
  let env = FormulaEnv::new()
    .with_input("mass", @quantity.Quantity::new(2.0, kilogram))
    .with_input("velocity", @quantity.Quantity::new(3.0, meter.div(second)))
  let result = formula.eval(env)
  assert_eq(result.value(), 9.0)
}

///|
/// `quantity` builds a unit-bearing constant term.
test "quantity builds a unit-bearing constant term" {
  let radian = @unit.Un::base("rad", @dimension.Dimension::custom("angle"))
  let term = quantity(1.0, radian)
  let expected = FormulaExpr::quantity(1.0, radian)
  assert_true(term.expr() == expected)
  assert_eq(term.inputs().length(), 0)
}

///|
/// The lenient `from_term` keeps the first input when names collide.
test "from_term keeps the first input on a name collision" {
  let length_x = input("x", @dimension.Dimension::length(), "X as length")
  let time_x = input("x", @dimension.Dimension::time(), "X as time")
  let formula = Formula::from_term(
    "lenient",
    length_x * time_x,
    @dimension.Dimension::length().mul(@dimension.Dimension::time()),
    "lenient = x * x",
    "Keeps the first input on collision.",
  )
  assert_eq(formula.inputs().length(), 1)
  assert_true(
    formula.inputs()[0].dimension().is_same(@dimension.Dimension::length()),
  )
}

///|
/// `checked_from_term` reports a same-name input used with two dimensions.
test "checked_from_term raises on conflicting input dimensions" {
  let length_x = input("x", @dimension.Dimension::length(), "X as length")
  let time_x = input("x", @dimension.Dimension::time(), "X as time")
  let term = length_x * time_x
  let mut caught = false
  try
    Formula::checked_from_term(
      "bad",
      term,
      @dimension.Dimension::length().mul(@dimension.Dimension::time()),
      "bad = x * x",
      "Deliberately conflicting inputs.",
    )
    |> ignore
  catch {
    InputDimensionConflict((name, _first, _second)) => {
      caught = true
      assert_eq(name, "x")
    }
  }
  assert_true(caught)
}
