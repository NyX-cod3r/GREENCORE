# Power Optimization Model Explanation

## 1. What this project is doing

This notebook builds a rule-based digital control system for power and thermal management across three servers: S1, S2, and S3. It does not use a trained machine learning model. Instead, it uses fixed logic written in Verilog to estimate power, detect overloads, choose where to shift workload, trigger cooling, and check whether the overall system is safe.

The system is designed to:

- predict total power usage for each server,
- classify whether a server is in a safe, warning, or critical state,
- decide whether one server should receive load from another,
- trigger reserve cooling or reserve power if needed,
- validate that the final decision is safe.

---

## 2. Why this is called a “model”

In this notebook, the word “model” is being used in a hardware/control-system sense, not a machine learning sense.

This is a model of the control logic for a power management system. It simulates how the system would behave under different power and temperature conditions.

It is not a statistical model trained on data. Instead, it is a logic model with thresholds and conditions.

---

## 3. Main idea of the system

Each server receives predicted values for:

- IT power
- cooling power
- HVAC power
- pump power
- temperature
- maintenance risk

The system then combines these values and takes decisions such as:

- which server is overloaded,
- which server is safe enough to receive extra workload,
- whether to increase cooling,
- whether to enforce emergency power restriction,
- whether the final allocation is valid.

---

## 4. Module-by-module explanation

### 4.1 load_analyzer

This module computes:

- total predicted power = IT + cooling + HVAC + pump
- power zone for each server
- whether the server is in a high-power state
- whether reserve trigger should happen
- whether cooling boost should happen

The total power is then classified into these zones:

- emergency: < 300
- buffer: < 400
- low: < 550
- medium: < 750
- high: < 850
- critical: >= 850

Example logic:

- if power is above 750, the server is considered medium/high
- if it reaches critical state, special action is triggered

The outputs include:

- `predicted_power_total`
- `predicted_zone`
- `predicted_high_power`
- `reserve_trigger`
- `cooling_boost`

This acts like the first layer of diagnosis.

---

### 4.2 health_maintenance

This module checks thermal health and maintenance health.

It considers:

- predicted temperature
- current cooling capacity
- reserve cooling boost
- maintenance risk

It calculates:

- effective temperature after reserve cooling
- thermal status (safe / warning / critical)
- if a server is thermally safe
- if thermal redistribution is needed
- if cooling is malfunctioning
- if maintenance is okay
- if the server is eligible to remain healthy

A server is marked unsafe if:

- temperature is too high,
- maintenance is severe,
- cooling is predicted to malfunction.

This is a safety gate before power redistribution is allowed.

---

### 4.3 reserve_power_supply

This module manages reserve energy and cooling backup.

It keeps a reserve charge level and decides how much to inject into servers or cooling support.

Key logic:

- if a server triggers reserve mode, it may receive a ramped injection,
- if cooling is required, reserve cooling also gets assigned,
- reserve charge is limited by a maximum value,
- emergency restrictions can reduce charging if needed.

This is important because the system must not overuse reserve capacity.

---

### 4.4 priority_eligibility

This decides which server is the best target to receive redistributed load.

A server becomes eligible only if:

- its predicted power is below a limit,
- its temperature is below a threshold,
- it is health-eligible.

Then, depending on `mode_select`, it chooses the best receiver according to different policies:

- maximum headroom
- coolest eligible server
- fixed priority order

So the system can choose the most suitable server for balancing power.

---

### 4.5 redistribution_manager

This module decides:

- which server is the source of overloaded power,
- which server is the receiver,
- whether redistribution should happen,
- how much power should be moved,
- when emergency restriction is needed,
- whether cooling boost is required.

It looks at several signals:

- predicted power,
- predicted temperature,
- `pred_high` state,
- thermal redistribution trigger,
- chosen receiver.

The logic is designed so that:

- overloaded servers are reduced,
- underloaded but healthy servers gain load,
- power is not shifted if the receiver is unsafe,
- emergency restriction occurs when there is no safe receiver.

---

### 4.6 power_allocation_engine

This is the actuation stage.

It updates each server’s allocated power and cooling.

It applies:

- source reduction from the overloaded server,
- receiver increase for the underloaded server,
- a ramp step to avoid abrupt jumps,
- maximum clamp at 1000 W,
- extra cooling calculation when needed.

This makes the controller smoother and more stable.

---

### 4.7 safety_check

This is the final validation layer.

It checks whether:

- each server allocation is under the maximum,
- reserve charge is within safe bounds,
- reserve injections are consistent with triggers,
- redistribution is valid,
- emergency restrictions are consistent.

The final output `final_valid` tells whether the proposed operation is safe.

---

### 4.8 green_core_controller

This is the top-level controller that connects all modules together.

It orchestrates:

- prediction,
- thermal health evaluation,
- priority selection,
- redistribution,
- reserve power,
- allocation,
- safety validation.

This is the central brain of the system.

---

## 5. What the whole system is trying to optimize

The controller is trying to maintain three main goals:

1. Keep each server below its safe power limit.
2. Keep temperatures from becoming dangerous.
3. Avoid failure from overload, cooling issues, or maintenance problems.

It does this by balancing power across servers and reserve resources.

---

## 6. Simple real-world analogy

Think of this system like a smart data-center power manager:

- Some servers are too hot or overloaded.
- Some other servers are cooler and healthy.
- The system shifts jobs or power from the hot server to the cool one.
- If things get too serious, it triggers emergency limits and cooling support.
- It always checks whether the action is safe before doing it.

That is exactly what the logic is modeling.

---

## 7. What is Verilog?

Verilog is a Hardware Description Language (HDL). It is used to model and design digital circuits.

Instead of writing normal software logic, Verilog describes how signals and hardware blocks behave over time.

It is commonly used for:

- digital system design,
- FPGA development,
- ASIC design,
- embedded hardware simulation,
- hardware verification.

### What Verilog does

Verilog lets you describe:

- inputs and outputs,
- registers and wires,
- combinational logic,
- sequential logic,
- state machines,
- timing behavior,
- testbench simulation.

In this project, Verilog is used to model a digital control system that reacts to values like predicted power and temperature.

### Why it is useful here

This notebook simulates the control logic at the hardware level. That means the system can be checked as a digital controller, not only as pseudocode or Python logic.

It is especially helpful when designing:

- FPGA implementations,
- hardware safety logic,
- embedded power management solutions,
- real-time systems with strict constraints.

---

## 8. Summary

This notebook is a hardware-style power optimization and thermal safety controller for three servers.

It contains:

- power prediction,
- thermal assessment,
- maintenance assessment,
- selection of source and receiver servers,
- redistribution logic,
- reserve power logic,
- final safety validation.

It is not a machine learning model but a deterministic expert controller implemented in Verilog.

---

## 9. One-line summary

This project models a smart power-balancing and safety system for a multi-server environment, using fixed logic rules in Verilog to predict load, redistribute power, trigger cooling, and maintain safe operation.

---

## 10. Project structure

- `SIH_model_for_power_optimization.ipynb` - Builds the Verilog source files, installs the Python dependency, compiles the design, and runs the simulation.
- `rtl/` - Verilog design modules for load analysis, health maintenance, allocation, redistribution, reserve power, safety checks, and the top-level controller.
- `simulation/system_frame_tb.v` - Testbench that reads input frames, drives the controller, and writes simulation output.
- `simulation/system_frames.txt` - Input test frames containing current values, predicted values, temperatures, maintenance levels, and selection modes.
- `simulation/output/system_results.csv` - Machine-readable results produced by the simulation for analysis or plotting.
- `simulation/output/system_run.vcd` - Waveform dump produced by the simulation for viewing signal changes over time.
- `simulation/output/sih_model.vvp` - Compiled Icarus Verilog simulation executable.
- `DASHBOARD/dashboard.html` - Local dashboard that visualizes the generated CSV results.
- `DASHBOARD/background.jpg` - Dashboard background image.
