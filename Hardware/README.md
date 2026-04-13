## 📁 Directory Overview

### `TOP/`
Top-level integration of the entire design.  
Responsible for connecting all submodules and forming the complete dataflow pipeline.

### `DCE_TOP/`
Top-level modules for the DCE computation backend.  
Handles the main data processing pipeline and coordinates data movement between front-end and compute units.

### `LDCE/`
Implements the left-side DCE processing pipeline.  
Includes processing elements (PEs), control logic, packing modules, and local memory structures.

### `RDCE/`
Implements the right-side DCE processing pipeline.  
Mainly responsible for weight handling, accumulation, and output-side computation.

### `LOW/`
Contains low-level functional modules shared across the design.  
Includes parsing logic and data reordering components.

### `MYIP/`
Custom IP modules and reusable hardware components.  
Includes FIFO, memory wrappers, and infrastructure-level modules.

---

## 📄 File Description

### 🔝 TOP

- `EquiCore.v`  
  Top-level module of the system.  
  Integrates memory interface, data parsing, channel processing, clock-domain crossing, and DCE backend.

---

### ⚙️ DCE_TOP

- `DCE_TOP.v`  
  Top-level module of the DCE engine.  
  Coordinates computation flow and connects LDCE and RDCE pipelines.

- `DCE_CDC.v`  
  Clock-domain crossing module.  
  Transfers data between different clock domains using FIFO-based buffering.

---

### 🧠 LDCE

#### Top-Level

- `LDCE.v`  
  Top-level module of the LDCE pipeline.

- `LDCE_CTRL.v`  
  Control module for LDCE.  
  Generates control signals for scheduling and data movement.

- `DCE_PE.v`  
  Processing element wrapper used in LDCE.

---

#### PE Channel

- `PE_Channel.v`  
  Defines a processing channel composed of multiple PEs.

- `LPE.v`  
  Left processing element.

- `RPE.v`  
  Right processing element within the channel.

- `LPE_CTRL.v`  
  Control logic for LPE.

- `RPE_CTRL.v`  
  Control logic for RPE.

- `OP_CTRL.v`  
  Operation controller for managing execution flow.

- `OP_CTRL_FSM.v`  
  FSM implementation for operation control.

---

#### Packing & Compute

- `Packing.v`  
  Data packing module for computation.

- `Correction.v`  
  Applies correction or adjustment to data.

- `DSP_Top.v`  
  Top-level DSP-based computation module.

- `DSP48_Macro.v`  
  Wrapper around DSP48 primitives.

- `DSP_TOP_SIM.v`  
  Simulation version of DSP module.

---

#### BRAM Tile

- `BRAM_TILE.v`  
  Local memory tile structure.

- `BRAM_CTRL.v`  
  Control logic for BRAM tile.

- `BRAM_SIM.v`  
  Simulation model of BRAM.

---

### 🔧 RDCE

- `RDCE.v`  
  Top-level module of RDCE pipeline.

- `RDCE_CTRL.v`  
  Control logic for RDCE.

- `RDCE_PE.v`  
  Processing element used in RDCE.

- `SUM4.v`  
  Partial sum accumulation module.

- `W_CH.v`  
  Weight channel module.

- `W_CH_CTRL.v`  
  Control logic for weight channel.

---

### 🔌 LOW

- `CG_parse.v`  
  Parses CG data and generates structured control signals.

- `Channel_rc.v`  
  Handles channel read and data reordering.

---

### 🧩 MYIP

- `dist_mem_1r1w.v`  
  Distributed memory module with one read and one write port.

- `async_fifo_32to16_lut.v`  
  Asynchronous FIFO with width conversion (32 → 16).

- `async_fifo_syncread_lut.v`  
  Asynchronous FIFO with synchronous read interface.

---
