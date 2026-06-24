# LunarFormulas

**English** | [简体中文](README_zh.md)

LunarFormulas is a small engineering and scientific formula library built on
[`FrozenLemonTee/LunarUnits`](https://github.com/FrozenLemonTee/LunarUnits).
It turns formula requirements that are often written only in prose into
anonymous, composable, unit-checked values.

The project is intentionally separate from LunarUnits. LunarUnits remains the
runtime dimension-checked quantity and unit system; LunarFormulas consumes that
core and provides reusable formula values for applications, CLIs, demos and
documentation.

A `Formula` is to LunarFormulas what a `Un` is to LunarUnits: just as
`meter / second.pow(2)` is an anonymous unit you compose and use directly, a
formula such as `mass * acceleration` is an anonymous value you compose with
operators and then evaluate. Dimensions propagate automatically; nothing is
restated by hand.

## Features

- `Formula` — an anonymous, composable, evaluable formula value. Combine
  formulas with `*`, `/`, `add`, `sub` and `.pow(n)`; the inputs are collected
  and the dimension is synthesised automatically, then `eval` returns a
  LunarUnits `Quantity`.
- `FormulaInput` — a free variable's name and expected LunarUnits dimension.
- `FormulaExpr` — a small quantity-valued expression tree supporting constants,
  variables, addition, subtraction, multiplication, division and integer powers.
- `FormulaEnv` — immutable named input bindings for formula evaluation.
- `FormulaError` — structured evaluation errors (missing input, input dimension
  mismatch, expression dimension mismatch).
- `mechanics` — predefined input variables (mass, acceleration, force, …) and
  the formulas composed from them (force, work, power, kinetic energy, torque,
  rotational work).
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

Bind inputs by name, then evaluate a formula directly:

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

Formulas compose like units. Multiplying the `force` and `velocity` variables
gives mechanical power — an anonymous formula the catalog never named, with its
dimension inferred:

```moonbit
let power = @formula_mechanics.force * @formula_mechanics.velocity
// power.dimension().is_same(@mechanical_units.watt.dimension())
```

Invalid input dimensions are rejected before a result is returned:

```moonbit
let bad = @common.FormulaEnv::new()
  .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
  .with_input("acceleration", @quantity.Quantity::new(3.0, @si.meter))

let result = @formula_mechanics.force_formula.checked_eval(bad)
// result is None
```

## Defining a Formula

`input` names a variable and its expected dimension — the one place a name is
written down, exactly like `Un::base("m", …)` in LunarUnits. Combining variables
with operators builds the formula, collects the inputs and synthesises the
output dimension automatically. The result is an anonymous value you evaluate
directly; there is no construction step and no restated output dimension:

```moonbit
let mass = @common.input("mass", @dimension.Dimension::mass())
let acc = @common.input("acceleration", acceleration_dimension())

// `force` is a Formula; its dimension is inferred from `mass * acc`.
pub let force : @common.Formula = mass * acc
```

Composition mirrors LunarUnits conventions: `*` / `/` compose formulas,
`.pow(n)` takes integer powers (never `^`), and `constant` / `quantity` build
dimensionless and unit-bearing constant factors. When the same physical quantity
must appear more than once (two masses `m1` and `m2`), derive distinct variables
from one with `.renamed("m1")`.

A predefined variable's name is fixed, so a same-name-different-dimension
conflict is not a build error: composition stays total and the conflict surfaces
at evaluation, where a single bound value can only match one dimension.

## Why Formula Values?

A plain function such as `force(m, a)` computes a result but cannot be inspected,
composed or dimension-checked as a value. LunarFormulas models a formula as an
anonymous value that carries its free variables and its dimension, so
applications get:

- unit-checked composition — dimensions propagate through `*` / `/` / `.pow(n)`,
  and mismatches are caught;
- reusable building blocks — a domain vocabulary of variables and formulas you
  combine into new formulas;
- evaluation over real LunarUnits quantities, with input dimensions checked
  before a result is returned;
- a usage style consistent with LunarUnits, where composed units and quantities
  are themselves first-class values.

## Design Boundary

`FormulaExpr` evaluates only over LunarUnits `Quantity` values. Affine points
and logarithmic levels/gains are deliberately not part of this expression tree;
those types have different algebra and should be adapted at domain boundaries.

Torque is the first showcase for this boundary. LunarUnits models angle as an
extension dimension, so torque is energy per angle (`N*m/rad`) while energy is
plain `N*m`. Rotational work is then a normal dimension-checked formula:

```text
work = torque * angle
```

Passing energy where torque is expected is rejected.

## Package Layout

```text
common/
  formula_expr.mbt    FormulaExpr, FormulaEnv, FormulaError
  formula.mbt         FormulaInput and the Formula value, input/constant/quantity
mechanics/
  mechanics_formulas.mbt   input variables and the formulas composed from them
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
dependency records `FrozenLemonTee/LunarUnits@0.1.6` for publishing.

## License

Apache-2.0. See [LICENSE](LICENSE).
