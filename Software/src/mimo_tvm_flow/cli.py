from __future__ import annotations

import argparse
from pathlib import Path

from .adapters import graph_from_problem_model
from .packing import pack_siso_units
from .pytorch_frontend import build_graph_from_pytorch_example, dump_pytorch_frontend_artifacts, write_pytorch_fx_svg
from .siso import dump_siso_artifacts, group_siso_units, split_graph_to_siso
from .spec import dump_graph_spec, load_graph_spec
from .tvm_lowering import build_relay_module, dump_relay_artifacts
from .visualize import write_graph_svg, write_input_summary, write_pipeline_report, write_siso_svg


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert generic MIMO into TVM IR, split to SISO, and pack demo bin artifacts")
    parser.add_argument("--input-json", default=None, help="path to a generic MIMO JSON spec")
    parser.add_argument("--problem-model", default=None, help="adapt a model from the built-in problem-model catalog, e.g. DiffDock-L=1")
    parser.add_argument("--pytorch-example", default=None, help="run a built-in PyTorch frontend example, e.g. tiny_dual_input")
    parser.add_argument("--batch-size", type=int, default=3000, help="batch size metadata used by the problem adapter")
    parser.add_argument("--output-dir", required=True, help="output directory for all stage artifacts")
    args = parser.parse_args()
    mode_count = int(bool(args.input_json)) + int(bool(args.problem_model)) + int(bool(args.pytorch_example))
    if mode_count != 1:
        raise SystemExit("exactly one of --input-json, --problem-model, or --pytorch-example must be provided")
    return args


def main() -> int:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.input_json:
        graph = load_graph_spec(Path(args.input_json))
    elif args.pytorch_example:
        graph, frontend_summary = build_graph_from_pytorch_example(args.pytorch_example)
        dump_pytorch_frontend_artifacts(frontend_summary, output_dir)
        write_pytorch_fx_svg(frontend_summary, output_dir)
    else:
        graph = graph_from_problem_model(args.problem_model, batch_size=args.batch_size)

    dump_graph_spec(graph, output_dir / "01_input_graph.json")
    write_graph_svg(graph, output_dir / "01_input_graph.svg", "Input MIMO Graph")
    write_input_summary(graph, output_dir / "01_input_summary.md")

    dump_graph_spec(graph, output_dir / "02_tvm_importable.json")

    relay_mod, relay_summary = build_relay_module(graph)
    dump_relay_artifacts(relay_mod, relay_summary, output_dir)

    siso_units = split_graph_to_siso(graph)
    grouped = group_siso_units(siso_units)
    dump_siso_artifacts(siso_units, grouped, output_dir)
    write_siso_svg(siso_units, output_dir / "04_siso_graph.svg", "Expanded SISO Units")

    pack_summary = pack_siso_units(siso_units, output_dir)
    write_pipeline_report(
        graph,
        grouped,
        {
            "packet_count": pack_summary.packet_count,
            "packet_data_bytes": pack_summary.packet_data_bytes,
            "instruction_stream_bytes": pack_summary.instruction_stream_bytes,
        },
        output_dir,
    )
    print(output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
