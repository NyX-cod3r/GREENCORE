# GreenCore Explained in Simple Words

This document explains the GreenCore controller for readers who are new to data centers, Verilog, and hardware simulation.

## What problem does GreenCore solve?

A data center contains many servers. Servers use electricity and create heat. If one server uses too much power or becomes too hot, the system needs to react quickly.

GreenCore is a rule-based controller that watches three servers: S1, S2, and S3. It checks their expected power and temperature, decides what action is needed, and checks whether that action is safe.

The controller can add power values, identify dangerous conditions, choose a healthy receiver, move a limited amount of requested load, request reserve power or cooling, reduce power in an emergency, and report whether the final decision passed the safety rules.

## Is this machine learning?

The Verilog controller is **not** machine learning. It uses fixed rules and limits. The same inputs always produce the same decisions.

The project also contains a separate Python forecasting notebook. That notebook uses XGBoost models to predict future power measurements from historical data. Those predictions can be studied alongside the hardware-style controller, but the notebook does not automatically rewrite the Verilog testbench input file.

## How one decision works

For every server, the controller follows this flow:

1. **Analyze power.** Add IT, cooling, HVAC, and pump power.
2. **Check health.** Look at temperature, cooling behavior, and maintenance risk.
3. **Find a receiver.** Choose a healthy server with enough spare capacity.
4. **Balance power.** Move a limited amount from the overloaded server when possible.
5. **Use reserve capacity.** Provide backup power or cooling when requested.
6. **Limit the action.** Use ramp steps and maximum limits so changes are not too sudden or too large.
7. **Validate safety.** Return `final_valid=1` only when the safety checks pass.

## The controller modules

### 1. `load_analyzer`

This first module adds four predicted values:

```text
total power = IT power + cooling power + HVAC power + pump power
```

It then puts the total into a power zone:

- **Emergency:** below 300 W.
- **Buffer:** 300 to below 400 W.
- **Low:** 400 to below 550 W.
- **Medium:** 550 to below 750 W.
- **High:** 750 to below 850 W.
- **Critical:** 850 W or more.

It also reports whether reserve power or extra cooling should be requested.

### 2. `health_maintenance`

This module asks whether a server is healthy enough to keep its work or receive more work. It checks predicted temperature, cooling and HVAC power, reserve cooling, and maintenance risk.

Temperature states are:

- **Safe:** below 70 C.
- **Warning:** 70 C to below 85 C.
- **Critical:** 85 C or higher.

A server is not eligible when it is critically hot, has a serious maintenance risk, or appears to have insufficient cooling.

### 3. `priority_eligibility`

This module finds possible receiver servers. A receiver must be healthy, cool enough, and below its allowed power level.

The `mode_select` input chooses whether to prefer the server with the most spare capacity, the coolest eligible server, or a fixed priority order.

### 4. `redistribution_manager`

This module decides whether work should move. It chooses the most serious source server, chooses the receiver selected by the priority module, and calculates a transfer amount. The transfer cannot push the receiver above its target or reduce the source below its safety floor.

If no safe receiver exists, the controller requests emergency power restriction instead of making an unsafe transfer.

### 5. `reserve_power_supply`

This module manages backup capacity. It can provide small, controlled reserve injections to a server or to cooling. It reduces the reserve charge when capacity is used and keeps the charge within its maximum of 10,000 W.

### 6. `power_allocation_engine`

This module applies the decision over time. It uses a 15 W ramp step so an allocation does not jump suddenly. It limits a server allocation to 1,000 W and calculates extra cooling when needed.

### 7. `safety_check`

This final check verifies that each allocation is at or below 1,000 W, reserve charge is within its limit, reserve injections match their triggers, redistribution has different source and receiver servers, and emergency restriction includes full cooling.

The output `final_valid` is the overall result. A value of `1` means these checks passed. A value of `0` means at least one check failed.

### 8. `green_core_controller`

This is the top-level module. It connects the other modules in this order:

```text
load analysis -> health check -> receiver choice -> redistribution -> reserve power -> allocation -> safety check
```

## What is Verilog?

Verilog is a language for describing digital hardware. Normal software usually runs one instruction after another. Verilog describes signals, hardware blocks, and clocked changes.

In this project, `wire` values carry calculated signals, `reg` values hold clocked values, `always @(*)` describes logic that reacts to inputs, and `always @(posedge clk ...)` describes clocked behavior.

Icarus Verilog compiles and runs this design on a normal computer. This is a simulation; it is not the same as programming a physical FPGA.

## What the current simulation shows

The testbench runs three example frames:

- **Frame 0:** normal, low-power conditions.
- **Frame 1:** S1 is critical, so 120 W is transferred from S1 to S2 and extra cooling is requested.
- **Frame 2:** S1 is critically hot, so the controller does not make the unsafe transfer and requests cooling support.

The current checked-in simulation produces three safety-valid frames. The dashboard reads `simulation/output/system_results.csv` and lets a user inspect each frame.

## What the forecasting notebook does

The notebook reads one file per server with these columns: `ts`, `cooling_kw`, `hvac_kw`, `it_power_kw`, and `pump_kw`.

It aligns all three files to one-minute timestamps, creates time and history features, trains twelve forecasting models, compares them with simple baselines, forecasts ten days, and checks the output format.

The sample data can be regenerated with:

```powershell
python data\generate_sample_data.py
```

The forecast output is written to `predictions.txt` and `predictions_with_timestamps.csv`. These sample inputs are synthetic, so real data should be used for any operational conclusion.

## Short summary

GreenCore is a deterministic, hardware-style controller for three data-center servers. It analyzes predicted power, checks temperature and maintenance health, balances load when safe, uses backup capacity when necessary, and reports whether the final action passed its safety checks. A separate Python notebook provides future power forecasts that can be used as an input source after the project's current manual conversion step.