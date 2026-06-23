# LunarFormulas

**English** | [简体中文](README_zh.md)

LunarFormulas is a small engineering and scientific formula library built on
[`FrozenLemonTee/LunarUnits`](https://github.com/FrozenLemonTee/LunarUnits).
It turns formula requirements that are often written only in prose into
first-class, unit-checked objects.

The project is intentionally separate from LunarUnits. LunarUnits remains the
runtime dimension-checked quantity and unit system; LunarFormulas consumes that
core and provides reusable formula objects for applications, CLIs, demos and
documentation.

## Features

- `Formula` — a named, inspectable and evaluable formula object.
- `FormulaInput` — input metadata with an expected LunarUnits dimension.
- `FormulaExpr` — a small quantity-valued expression tree supporting constants,
  variables, addition, subtraction, multiplication, division and integer powers.
- `FormulaTerm` — a DSL layer that lets you build and compose formulas like
  ordinary maths (`mass * acc`, `constant(0.5) * mass * velocity.pow(2)`), with
  input metadata collected automatically.
- `FormulaEnv` — immutable named input bindings for formula evaluation.
- `FormulaError` / `FormulaBuildError` — structured errors for evaluation
  (missing inputs, dimension mismatches) and construction (conflicting inputs).
- `mechanics` formulas for force, work, power, kinetic energy, torque and
  rotational work.
- Runnable examples and tests showing dimension-safe formula evaluation.

## Installation

```bash
moon add FrozenLemonTee/LunarFormulas
```

LunarFormulas depends on LunarUnits:

```moonbit
import {
  "FrozenLemonTee/LunarFormulas/common",
  "FrozenLemonTee/LunarFormulas/mechanics" @formula_mechanics,
  "FrozenLemonTee/LunarUnits/core/dimension",
  "FrozenLemonTee/LunarUnits/core/quantity",
  "FrozenLemonTee/LunarUnits/units/si",
  "FrozenLemonTee/LunarUnits/units/mechanics" @mechanical_units,
}
```

For local development next to the LunarUnits repository, this repo includes a
`moon.work` workspace that points to `../LunarUnits`.

## Quick Start

```moonbit
let env = @common.FormulaEnv::new()
  .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
  .with_input(
    "acceleration",
    @quantity.Quantity::new(3.0, @si.meter / @si.second.pow(2)),
  )

let force = @formula_mechanics.force_formula.eval(env)
// force.value() == 6.0
// force.unit().is_compatible(@mechanical_units.newton)
```

Formula objects can also be inspected:

```moonbit
let formula = @formula_mechanics.force_formula
let name = formula.name() // "force"
let display = formula.display() // "F = m * a"
let inputs = formula.inputs()
```

Invalid input dimensions are rejected before a result is returned:

```moonbit
let bad = @common.FormulaEnv::new()
  .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
  .with_input(
    "acceleration",
    @quantity.Quantity::new(3.0, @si.meter),
  )

let result = @formula_mechanics.force_formula.checked_eval(bad)
// result is None
```

## Defining a Formula

Formulas are built with the DSL so the definition reads like the maths itself.
`input` records each variable's metadata, and combining terms collects the
`inputs` array automatically:

```moonbit
let mass = @common.input("mass", @dimension.Dimension::mass(), "Mass")
let acc = @common.input("acceleration", acceleration_dimension(), "Acceleration")

pub let force_formula : @common.Formula = @common.Formula::from_term(
  "force",
  mass * acc,
  @mechanical_units.newton.dimension(),
  "F = m * a",
  "Computes force from mass and acceleration.",
)
```

Composition mirrors LunarUnits conventions: `*` / `/` compose terms, `.pow(n)`
takes integer powers (never `^`), and `constant` / `quantity` build constant
factors. `Formula::from_term` is total and fits top-level `let` definitions;
`Formula::checked_from_term` instead raises `FormulaBuildError` when one input
name is used with two different dimensions.

## Why Formula Objects?

A plain function such as `force(m, a)` can compute a result, but it does not
carry enough metadata for a CLI, GUI or documentation site to discover the
formula, render input fields, show an equation or explain expected dimensions.

LunarFormulas models formulas as data plus evaluation. That gives applications
one reusable source of truth for:

- formula names and display equations;
- input names, descriptions and dimensions;
- output dimensions;
- checked evaluation;
- future CLI/UI/documentation generation.

## Design Boundary

`FormulaExpr` evaluates only over LunarUnits `Quantity` values. Affine points
and logarithmic levels/gains are deliberately not part of this expression tree;
those types have different algebra and should be adapted at domain boundaries.

Torque is the first showcase for this boundary. LunarUnits models angle as an
extension dimension, so torque is energy per angle (`N*m/rad`) while energy is
plain `N*m`. Rotational work is then a normal checked formula:

```text
work = torque * angle
```

Passing energy where torque is expected is rejected.

## Package Layout

```text
common/
  formula_expr.mbt    FormulaEnv, FormulaExpr, FormulaError
  formula.mbt         FormulaInput and Formula
  formula_term.mbt    FormulaTerm DSL, input/constant/quantity, from_term
mechanics/
  mechanics_formulas.mbt
examples/
  examples.mbt        runnable cookbook examples
docs/
  architecture.md     design boundaries and package structure
```

## Development

Run the usual MoonBit workflow from this repository:

```bash
moon info
moon fmt
moon test
```

The workspace includes `../LunarUnits` for local development. The module
dependency still records `FrozenLemonTee/LunarUnits@0.1.6` for publishing.

## License

Apache-2.0. See [LICENSE](LICENSE).
