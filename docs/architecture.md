# LunarFormulas Architecture

This document records the first milestone package structure and the design
boundaries that should remain stable as the formula ecosystem grows.

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
semantics. It consumes those APIs and turns domain equations into checked,
inspectable formula objects.

## Common Package

`common/` contains the reusable formula model:

- `FormulaInput`: input name, expected dimension and description.
- `FormulaExpr`: quantity-valued expression tree.
- `FormulaEnv`: immutable map from input names to `Quantity` values.
- `Formula`: formula metadata plus checked evaluation.
- `FormulaError`: structured evaluation errors.
- `FormulaTerm`: DSL wrapper for building expressions like ordinary math.
- `FormulaBuildError`: structured build-time errors.

`Formula::eval` first checks that every declared input exists and has the
expected dimension. It then evaluates the expression and verifies that the
result dimension matches the formula's declared output dimension.

`Formula::checked_eval` returns `None` for any formula error and is intended for
applications, CLIs and data validation flows that should avoid exceptions.

## Formula DSL

`FormulaExpr` is the evaluation AST, but defining formulas directly on it reads
like assembling syntax trees. `FormulaTerm` adds a thin DSL layer so formula
construction and composition read like writing the maths:

```moonbit
let mass = input("mass", @dimension.Dimension::mass(), "Mass")
let acc = input("acceleration", acceleration_dimension(), "Acceleration")
let force = Formula::from_term("force", mass * acc, ..., "F = m * a", ...)
```

`FormulaTerm` carries both the `FormulaExpr` AST and the input metadata. The
design intentionally mirrors LunarUnits conventions:

- composition uses `*` / `/` (the `Mul` / `Div` traits) and `add` / `sub`;
- integer powers use `.pow(n)`, never `^`, matching LunarUnits quantity algebra;
- term composition is total — combining terms only merges AST nodes and input
  metadata, deferring dimension rejection to evaluation, exactly as LunarUnits
  keeps quantity multiplication total.

`input` records input metadata automatically, so combining terms collects the
`inputs` array without hand-maintaining it. `constant` and `quantity` build
dimensionless and unit-bearing constant terms and contribute no inputs.

Two construction entry points follow the `eval` / `checked_eval` pairing:

- `Formula::from_term` is total. It deduplicates inputs by name (keeping the
  first) and never fails, so it can be used directly in top-level `let` formula
  definitions.
- `Formula::checked_from_term` additionally verifies that no input name appears
  with two different dimensions, raising `FormulaBuildError` on conflict. Use it
  when formulas are assembled dynamically rather than as static constants.

`FormulaExpr` and `Formula::new` remain available, so existing code keeps
working while domain packages migrate to the DSL.

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

`mechanics/` is the first domain package. It exports:

- `force_formula`: `F = m * a`
- `work_formula`: `W = F * d`
- `power_formula`: `P = W / t`
- `kinetic_energy_formula`: `E_k = 1/2 * m * v^2`
- `torque_formula`: `tau = F * r / rad`
- `rotational_work_formula`: `W = tau * theta`
- `formulas()`: formula catalog for enumeration

The torque formulas intentionally rely on LunarUnits' angle extension
dimension. Torque is modeled as energy per angle (`N*m/rad`), so it is distinct
from energy (`N*m`). Rotational work multiplies torque by angle and returns
energy.

## Error Boundary

Formula errors are local to LunarFormulas:

- `MissingInput(name)`
- `InputDimensionMismatch(name, expected, actual)`
- `ExpressionDimensionMismatch(expected, actual)`
- `OutputDimensionMismatch(expected, actual)`

Lower-level LunarUnits errors are caught where necessary and re-raised as
formula-level errors so application code can handle formula evaluation through
one error type.

Build-time conflicts surface separately through `FormulaBuildError`:

- `InputDimensionConflict(name, first, second)`

## Package Layout

```text
common/
  formula_expr.mbt
  formula.mbt
  formula_term.mbt
  formula_test.mbt
  formula_term_test.mbt
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
