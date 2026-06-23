# LunarFormulas

[English](README.md) | **简体中文**

LunarFormulas 是基于
[`FrozenLemonTee/LunarUnits`](https://github.com/FrozenLemonTee/LunarUnits)
的工程/科学公式库。它把原本只能写在文档里的“参数应该是什么量纲”变成可检查、可测试、可枚举的公式对象。

本项目独立于 LunarUnits。LunarUnits 继续作为运行时量纲检查、单位换算和数量模型；LunarFormulas 只消费 LunarUnits，并在其上提供可复用的领域公式对象。

## 功能

- `Formula`：带名称、输入、输出、表达式和说明的可求值公式对象。
- `FormulaInput`：记录输入名称、说明和期望量纲。
- `FormulaExpr`：数量表达式树，支持常量、变量、加减、乘除和整数幂。
- `FormulaTerm`：DSL 层，让公式的构建与组合像书写数学公式一样直观（`mass * acc`、`constant(0.5) * mass * velocity.pow(2)`），并自动收集输入元数据。
- `FormulaEnv`：公式求值环境，按名称绑定 LunarUnits `Quantity`。
- `FormulaError` / `FormulaBuildError`：分别区分求值错误（缺少输入、量纲不匹配）和构建错误（同名输入量纲冲突）。
- `mechanics` 力学公式：力、功、功率、动能、扭矩、旋转做功。
- 可运行示例和测试。

## 安装

```bash
moon add FrozenLemonTee/LunarFormulas
```

常用导入：

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

本地开发时，本仓库的 `moon.work` 指向 sibling 项目 `../LunarUnits`，用于直接使用当前本地 LunarUnits。

## 快速开始

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

错误量纲会被拦截：

```moonbit
let bad = @common.FormulaEnv::new()
  .with_input("mass", @quantity.Quantity::new(2.0, @si.kilogram))
  .with_input("acceleration", @quantity.Quantity::new(3.0, @si.meter))

let result = @formula_mechanics.force_formula.checked_eval(bad)
// result is None
```

## 定义公式

公式用 DSL 定义，写法贴近数学公式本身。`input` 记录每个变量的元数据，组合各项时会自动收集 `inputs` 数组：

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

组合方式与 LunarUnits 保持一致：用 `*` / `/` 组合各项，用 `.pow(n)` 取整数幂（不用 `^`），用 `constant` / `quantity` 构造常量因子。`Formula::from_term` 是全函数（不会失败），适合顶层 `let` 定义；`Formula::checked_from_term` 则在同名输入出现两种不同量纲时抛出 `FormulaBuildError`。

## 为什么做成公式对象

普通函数只能求值；公式对象还可以被 CLI、GUI、文档站和测试读取：

- 公式名称和展示式；
- 输入名称、说明和量纲；
- 输出量纲；
- 可检查求值；
- 后续自动生成命令行参数、表单或文档。

## 重点示例：扭矩 vs 能量

LunarUnits 把 angle 建模为扩展维度，因此：

- 能量：`N*m`
- 扭矩：`N*m/rad`
- 旋转做功：`work = torque * angle`

这让“把能量误传给扭矩参数”这类错误可以直接被公式对象拦截。

## 开发

```bash
moon info
moon fmt
moon test
```

## 许可证

Apache-2.0。见 [LICENSE](LICENSE)。
