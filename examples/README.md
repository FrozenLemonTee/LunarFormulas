# Examples

Runnable, self-checking examples for LunarFormulas. Each example is a `test` in
[`examples.mbt`](examples.mbt), so `moon test` verifies them with the rest of
the project.

Covered:

Evaluating predefined formulas:

- Evaluating Newton's second law directly with `force_formula.eval`.
- Rejecting an input with the wrong dimension.
- Evaluating kinetic energy from mass and velocity.
- Showing torque (`N*m/rad`) and energy (`N*m`) are distinct.
- Evaluating rotational work as `torque * angle`.
- Parsing user-facing quantity strings with LunarUnits and passing them into a
  formula environment.

Composing your own formulas:

- Combining the vocabulary with operators into a new formula (`force * velocity`
  for power), with the dimension inferred and evaluated directly.
- Building a formula from `input` variables, with inputs collected and the
  output dimension inferred automatically — no construction step.
- Composing `constant` and `.pow(n)` so the definition reads like the equation.
- Using a unit-bearing `quantity` factor (torque as energy per radian).
- Reusing the same quantity several times with `.renamed(...)`.
- Watching an inconsistent input dimension surface at evaluation.

Run them with:

```bash
moon test examples
```
