# LunarFormulas Architecture

This document records the package structure and the design boundaries that
should remain stable as the formula ecosystem grows.

## Core Direction

LunarFormulas is an upstream library built on LunarUnits, not part of the
LunarUnits core. The dependency direction is one-way:

```text
LunarUnits core quantities/units
  -> LunarFormulas common formula model
    -> LunarFormulas domain formula packages
      -> CLI / GUI / documentation demos
```

The formula library must not change LunarUnits' `Dimension`, `Un` or `Quantity`
semantics. It consumes those APIs and turns domain equations into anonymous,
composable, dimension-checked formula values.

A `Formula` is the formula counterpart of a LunarUnits `Un`: an anonymous value
that is composed with operators and evaluated, never a named metadata object.
Discoverability is intentionally out of scope; if an application needs to
enumerate formulas, a metadata catalog can be layered on top (mirroring
LunarUnits' catalog) without changing the anonymous core.

## Common Package

`common/` contains the reusable formula model:

- `FormulaInput`: a free variable's name and expected dimension.
- `FormulaExpr`: quantity-valued expression tree.
- `FormulaEnv`: immutable map from input names to `Quantity` values.
- `Formula`: an anonymous, composable, evaluable formula value.
- `FormulaError`: structured evaluation errors.

`Formula::eval` first checks that every input exists in the environment with the
expected dimension, then evaluates the expression. There is no declared output
dimension to verify: the result dimension simply is `Formula::dimension()`,
synthesised while the formula was composed.

`Formula::checked_eval` returns `None` for any formula error and is intended for
applications, CLIs and data validation flows that should avoid exceptions.

## Formula composition

`FormulaExpr` is the evaluation AST, but defining formulas directly on it reads
like assembling syntax trees. `Formula` wraps it so construction and composition
read like writing the maths, and so a formula is a value you use directly:

```moonbit
let mass = input("mass", @dimension.Dimension::mass())
let acc = input("acceleration", acceleration_dimension())
let force = mass * acc        // anonymous Formula; evaluate with force.eval(env)
```

`Formula` carries the `FormulaExpr` AST, the input metadata *and* the dimension
of the value it computes. The design intentionally mirrors LunarUnits
conventions:

- composition uses `*` / `/` (the `Mul` / `Div` traits) and `add` / `sub`;
- integer powers use `.pow(n)`, never `^`, matching LunarUnits quantity algebra;
- composition is total — combining formulas only merges AST nodes and inputs,
  deferring dimension rejection to evaluation, exactly as LunarUnits keeps
  quantity multiplication total.

`input` records a variable's name and dimension, so combining formulas collects
the `inputs` array without hand-maintaining it. `constant` and `quantity` build
dimensionless and unit-bearing constant factors and contribute no inputs.

Just as LunarUnits propagates dimensions through `Un` and `Quantity`, each
`Formula` synthesises its own dimension as it is composed (`mul`/`div`/`pow`
combine dimensions; `add`/`sub` keep the left dimension and defer any mismatch
to evaluation). `Formula::dimension()` therefore reports the output dimension
without it ever being restated by hand.

Predefined variables carry a fixed name. `Formula::renamed(name)` derives a
distinct variable (same dimension, new name) from a bare variable, so the same
physical quantity can appear several times in one formula (`m1`, `m2`). A
same-name-different-dimension conflict is not a build error: composition stays
total and the conflict surfaces at evaluation, where the environment binds a
single value per name and only one dimension can match.

## Expression Boundary

`FormulaExpr` deliberately evaluates only over LunarUnits `Quantity` values.
It supports:

- dimensionless constants;
- unit-bearing quantity constants;
- variables;
- addition and subtraction, using LunarUnits dimension checks;
- multiplication, division and integer powers.

Affine points (`Point`) and logarithmic `Level`/`Gain` values do not enter the
generic expression tree. They have torsor-like algebra rather than ordinary
quantity algebra. Domain packages that need them should adapt at the boundary,
for example by converting two temperature points into a temperature-difference
`Quantity` before entering the generic formula model.

## Mechanics Package

`mechanics/` is the first domain package. Mirroring how `units/mechanics`
exports both base and derived units, it exports both the input variables and the
formulas composed from them, all as anonymous `@common.Formula` `let` bindings:

- input variables: `mass`, `acceleration`, `velocity`, `force`, `distance`,
  `lever_arm`, `time`, `work`, `torque`, `angle`
- formulas: `force_formula` (`F = m * a`), `work_formula` (`W = F * d`),
  `power_formula` (`P = W / t`), `kinetic_energy_formula` (`E_k = 1/2 m v^2`),
  `torque_formula` (`tau = F * r / rad`), `rotational_work_formula`
  (`W = tau * theta`)

Consumers can also combine the exported variables into formulas the package
never named, such as `force * velocity` for mechanical power.

The torque formulas intentionally rely on LunarUnits' angle extension dimension.
Torque is modeled as energy per angle (`N*m/rad`), so it is distinct from energy
(`N*m`). Rotational work multiplies torque by angle and returns energy.

## Error Boundary

Formula errors are local to LunarFormulas:

- `MissingInput(name)`
- `InputDimensionMismatch(name, expected, actual)`
- `ExpressionDimensionMismatch(expected, actual)`

Lower-level LunarUnits errors are caught where necessary and re-raised as
formula-level errors so application code can handle formula evaluation through
one error type.

## Package Layout

```text
common/
  formula_expr.mbt
  formula.mbt
  formula_test.mbt
mechanics/
  mechanics_formulas.mbt
  mechanics_formulas_test.mbt
examples/
  examples.mbt
docs/
  architecture.md
```

Future domain packages should depend on `common/` and the specific LunarUnits
unit/quantity packages they need. They should stay small, stable and testable.
