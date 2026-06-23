# Examples

Runnable, self-checking examples for LunarFormulas. Each example is a `test` in
[`examples.mbt`](examples.mbt), so `moon test` verifies them with the rest of
the project.

Covered:

Evaluating existing formulas:

- Inspecting the mechanics formula catalog.
- Evaluating Newton's second law through a `Formula` object.
- Rejecting an input with the wrong dimension.
- Evaluating kinetic energy from mass and velocity.
- Showing torque (`N*m/rad`) and energy (`N*m`) are distinct.
- Evaluating rotational work as `torque * angle`.
- Parsing user-facing quantity strings with LunarUnits and passing them into a
  formula environment.

Defining formulas with the DSL (the human-friendly API):

- Building a formula with `input` + `*`, with inputs collected automatically.
- Composing `constant` and `.pow(n)` so the definition reads like the equation.
- Using a unit-bearing `quantity` factor (torque as energy per radian).
- Deduplicating a reused input by name.
- Catching an inconsistent input dimension with `checked_from_term`.

Run them with:

```bash
moon test examples
```
