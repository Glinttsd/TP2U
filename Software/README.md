# MIMO TVM Flow

`MIMO TVM Flow` is a lightweight open-source workflow for converting a generic MIMO description into:

1. a TVM-importable JSON format,
2. TVM Relay IR,
3. expanded SISO units,
4. demo `packet_data.bin` and `instruction_stream.bin` artifacts.

The repository is designed for understanding and prototyping the full path from high-level graph construction to IR lowering, SISO decomposition, and binary packing.

![pipeline overview](docs/assets/pipeline_overview.svg)

## Requirements

- Python 3.8+
- `apache-tvm==0.11.1`
- `numpy`

Optional:

- `torch` for the PyTorch frontend example
- `torch` and `e3nn` for the built-in `--problem-model` catalog

## Installation

Minimal install:

```bash
pip install -e .
```

Install with optional frontends:

```bash
pip install -e ".[problem-model,pytorch]"
```

## Quick Start

### 1. Generic JSON input

```bash
python -m mimo_tvm_flow \
  --input-json examples/sample_generic_mimo.json \
  --output-dir outputs/sample_generic
```

### 2. Built-in problem-model input

```bash
python -m mimo_tvm_flow \
  --problem-model DiffDock-L=1 \
  --batch-size 3000 \
  --output-dir outputs/diffdock_l1
```

Built-in model definitions are included in:

- `src/mimo_tvm_flow/model_catalog.py`
- `examples/builtin_problem_models.json`

### 3. PyTorch frontend example

```bash
python -m mimo_tvm_flow \
  --pytorch-example tiny_dual_input \
  --output-dir outputs/pytorch_demo
```

## Main Outputs

Each run generates staged artifacts under the chosen output directory, including:

- input graph JSON and SVG
- TVM-importable JSON
- Relay IR text
- SISO units and grouped signatures
- demo `packet_data.bin`
- demo `instruction_stream.bin`
- a final Markdown report

## Notes

- This project is a workflow skeleton, not a production TVM backend.
- The demo bin format is illustrative and does not claim compatibility with any specific FPGA runtime.
- The built-in `--problem-model` path is meant for structure-level adaptation and experimentation.
