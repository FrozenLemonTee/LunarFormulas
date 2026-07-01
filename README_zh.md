# LunarFormulas

[English](README.md) | **简体中文**

LunarFormulas 是基于
[`FrozenLemonTee/LunarUnits`](https://github.com/FrozenLemonTee/LunarUnits)
的工程/科学公式库。它把原本只能写在文档里的“参数应该是什么量纲”变成匿名、可组合、带量纲校验的公式值。

本项目独立于 LunarUnits。LunarUnits 继续作为运行时量纲检查、单位换算和数量模型；LunarFormulas 只消费 LunarUnits，并在其上提供可复用的领域公式值。

`Formula` 之于 LunarFormulas，正如 `Un` 之于 LunarUnits：`meter / second.pow(2)` 是一个可直接组合使用的匿名单位，而 `mass * acceleration` 是一个用运算符组合、可直接求值的匿名公式值。量纲随运算自动传播，无需手写复述。

## 功能

- `Formula`：匿名、可组合、可求值的公式值。用 `*`、`/`、`add`、`sub`、`.pow(n)` 组合公式，自动收集输入、自动合成量纲，`eval` 返回 LunarUnits `Quantity`。
- `FormulaInput`：一个自由变量的名称与期望量纲。
- `FormulaExpr`：数量表达式树，支持常量、变量、加减、乘除和整数幂。
- `FormulaEnv`：公式求值环境，按名称绑定 LunarUnits `Quantity`。
- `FormulaError`：结构化求值错误（缺少输入、输入量纲不匹配、表达式量纲不匹配）。
- `mechanics`：预置输入变量（mass、acceleration、force…）与由它们组合出的公式（力、功、功率、动能、扭矩、旋转做功）。
- `electrical`：欧姆定律、电功率、焦耳热功率、电荷和电能公式。
- `thermal`：显热、一维导热换热率和对流换热率公式，输入使用线性温差 `Quantity`。
- `catalog`：带 `FormulaEntry` 元数据的可发现公式目录，提供 mechanics / electrical / thermal / all 预置目录。
- 可运行示例和测试。

## 安装

```bash
moon add FrozenLemonTee/LunarFormulas
```

常用导入：

```moonbit
import {
  "FrozenLemonTee/LunarFormulas/common",
  "FrozenLemonTee/LunarFormulas/catalog" @formula_catalog,
  "FrozenLemonTee/LunarFormulas/mechanics" @formula_mechanics,
  "FrozenLemonTee/LunarFormulas/electrical" @formula_electrical,
  "FrozenLemonTee/LunarFormulas/thermal" @formula_thermal,
  "FrozenLemonTee/LunarUnits/core/dimension",
  "FrozenLemonTee/LunarUnits/core/quantity",
  "FrozenLemonTee/LunarUnits/units/si",
  "FrozenLemonTee/LunarUnits/units/mechanics" @mechanical_units,
  "FrozenLemonTee/LunarUnits/units/electromagnetism" @electrical_units,
  "FrozenLemonTee/LunarUnits/quantities/qelectromagnetism",
}
```

本地开发时，本仓库的 `moon.work` 指向 sibling 项目 `../LunarUnits`，用于直接使用当前本地 LunarUnits。

## 快速开始

按名称绑定输入，然后直接对公式求值：

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

公式像单位一样可组合。把 `force` 和 `velocity` 两个变量相乘就得到机械功率——一个目录里没有命名、量纲自动推断的匿名公式：

```moonbit
let power = @formula_mechanics.force * @formula_mechanics.velocity
// power.dimension().is_same(@mechanical_units.watt.dimension())
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

`input` 命名一个变量及其期望量纲——这是唯一需要写下名字的地方，正如 LunarUnits 里的 `Un::base("m", …)`。用运算符组合变量即可构建公式，自动收集输入、自动合成输出量纲。结果是一个可直接求值的匿名值，没有构造步骤，也不复述输出量纲：

```moonbit
let mass = @common.input("mass", @dimension.Dimension::mass())
let acc = @common.input("acceleration", acceleration_dimension())

// `force` 是一个 Formula；量纲由 `mass * acc` 推断而来。
pub let force : @common.Formula = mass * acc
```

组合方式与 LunarUnits 保持一致：用 `*` / `/` 组合公式，用 `.pow(n)` 取整数幂（不用 `^`），用 `constant` / `quantity` 构造无量纲与带单位的常量因子。当同一物理量需要出现多次（两个质量 `m1`、`m2`），用 `.renamed("m1")` 从一个变量派生出多个不同名变量。

预置变量名字固定，因此「同名不同量纲」不是构建错误：组合保持全函数，冲突在求值时暴露——绑定到该名字的单个值只能匹配一种量纲。

## 为什么做成公式值

普通函数 `force(m, a)` 只能求值，无法作为「值」被检查、组合或量纲校验。LunarFormulas 把公式建模为一个携带自由变量与量纲的匿名值，于是应用可以得到：

- 量纲安全的组合——量纲随 `*` / `/` / `.pow(n)` 传播，不匹配被捕获；
- 可复用的构建块——一套领域变量与公式词汇，可组合出新公式；
- 在真实 LunarUnits 数量上求值，求值前校验输入量纲；
- 与 LunarUnits 一致的使用风格——组合出的单位、数量本身都是一等值。

应用层如果需要枚举公式、生成 CLI `list/show` 或 Web 动态表单，可以使用 `catalog` 包。它把匿名公式包装为带稳定名称、领域、展示字符串和说明的 `FormulaEntry`，但不把这些元数据塞回核心 `Formula`。

```moonbit
let entry = @formula_catalog.all().lookup("ohm-voltage").unwrap()
// entry.display() == "V = I * R"
```

## 领域与目录示例

电学公式可以直接求值。例如 `ohm-voltage` 对应 `V = I * R`，把电流绑定到 `voltage` 这类错误输入会在求值前被量纲检查拦截。

热学公式明确要求温差是普通 kelvin `Quantity`，不是 `affine/` 的绝对温度点。如果输入是两个温度点，应先用 `Point::difference` 得到温差再绑定到 `temperature_difference`。

## 重点示例：扭矩 vs 能量

LunarUnits 把 angle 建模为扩展维度，因此：

- 能量：`N*m`
- 扭矩：`N*m/rad`
- 旋转做功：`work = torque * angle`

这让“把能量误传给扭矩参数”这类错误可以在求值时被直接拦截。

## 开发

```bash
moon info
moon fmt
moon test
```

## 许可证

Apache-2.0。见 [LICENSE](LICENSE)。
