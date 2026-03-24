from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

from .spec import GraphSpec, InputSpec, NodeSpec


def _load_torch():
    try:
        import torch  # type: ignore
        import torch.fx  # type: ignore
    except Exception as exc:  # pragma: no cover
        raise SystemExit(f"PyTorch frontend requires torch. import failed: {exc}")
    return torch


def _load_demo_builder():
    project_root = Path(__file__).resolve().parents[2]
    import sys

    examples_dir = project_root / "examples"
    if str(examples_dir) not in sys.path:
        sys.path.insert(0, str(examples_dir))
    from pytorch_demo import ToyMIMOBlock, build_demo_model  # type: ignore

    return ToyMIMOBlock, build_demo_model


def _load_builder_from_script(script_path: Path, entry_name: str):
    if not script_path.is_file():
        raise FileNotFoundError(f"PyTorch script not found: {script_path}")
    module_name = f"mimo_tvm_user_{script_path.stem}"
    spec = importlib.util.spec_from_file_location(module_name, script_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to import PyTorch script: {script_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    try:
        return getattr(module, entry_name)
    except AttributeError as exc:
        raise AttributeError(f"Builder function {entry_name!r} not found in {script_path}") from exc


def _graph_from_bundle(bundle: Dict[str, object], source_name: str) -> Tuple[GraphSpec, Dict[str, object]]:
    torch = _load_torch()
    model = bundle["model"]
    if not isinstance(model, torch.nn.Module):
        raise TypeError("bundle['model'] must be a torch.nn.Module")
    model.eval()
    traced = torch.fx.symbolic_trace(model)

    sample_inputs = bundle["sample_inputs"]
    if isinstance(sample_inputs, dict):
        input_specs = [InputSpec(id=str(name), dim=int(tensor.shape[-1])) for name, tensor in sample_inputs.items()]
    elif isinstance(sample_inputs, (tuple, list)):
        input_specs = [InputSpec(id=f"x{idx+1}", dim=int(tensor.shape[-1])) for idx, tensor in enumerate(sample_inputs)]
    else:
        raise TypeError("bundle['sample_inputs'] must be a dict, tuple, or list of tensors")

    raw_nodes: Sequence[Dict[str, object]] = bundle["nodes"]  # type: ignore[assignment]
    nodes: List[NodeSpec] = []
    for raw_node in raw_nodes:
        nodes.append(
            NodeSpec(
                id=str(raw_node["id"]),
                kind=str(raw_node.get("kind", "pytorch_mimo_block")),
                connection_mode=str(raw_node["connection_mode"]),
                input_a=str(raw_node["input_a"]),
                input_b=str(raw_node["input_b"]),
                output=str(raw_node["output"]),
                x1_dim=int(raw_node["x1_dim"]),
                x2_dim=int(raw_node["x2_dim"]),
                out_dim=int(raw_node["out_dim"]),
                weight_dim=int(raw_node["weight_dim"]),
                multiplicity=int(raw_node.get("multiplicity", 1)),
                metadata=dict(raw_node.get("metadata", {})),
            )
        )

    outputs = bundle.get("outputs")
    graph = GraphSpec(
        name=str(bundle.get("graph_name", source_name)),
        inputs=input_specs,
        nodes=nodes,
        outputs=list(outputs) if outputs is not None else ([nodes[-1].output] if nodes else []),
        metadata={"source": source_name, "frontend": "torch.fx"},
    )
    summary = {
        "source_name": source_name,
        "model_repr": repr(model),
        "fx_graph": str(traced.graph),
        "node_count": len(nodes),
        "input_dims": {inp.id: inp.dim for inp in input_specs},
    }
    return graph, summary


def build_graph_from_pytorch_example(example_name: str) -> Tuple[GraphSpec, Dict[str, object]]:
    torch = _load_torch()
    ToyMIMOBlock, build_demo_model = _load_demo_builder()

    model = build_demo_model(example_name)
    model.eval()

    sample_inputs = {
        "tiny_dual_input": (
            torch.randn(1, 16),
            torch.randn(1, 8),
        )
    }
    if example_name not in sample_inputs:
        raise ValueError(f"unknown PyTorch example: {example_name}")

    traced = torch.fx.symbolic_trace(model)
    x1_sample, x2_sample = sample_inputs[example_name]

    nodes: List[NodeSpec] = []
    placeholder_dims = {"x1": int(x1_sample.shape[-1]), "x2": int(x2_sample.shape[-1])}

    block_modules = [(name, module) for name, module in model.named_modules() if isinstance(module, ToyMIMOBlock)]
    for idx, (name, module) in enumerate(block_modules):
        input_a = "x1" if idx == 0 else block_modules[idx - 1][0]
        input_b = "x2"
        nodes.append(
            NodeSpec(
                id=name,
                kind="pytorch_mimo_block",
                connection_mode="uvw",
                input_a=input_a,
                input_b=input_b,
                output=name,
                x1_dim=int(module.x1_dim),
                x2_dim=int(module.x2_dim),
                out_dim=int(module.out_dim),
                weight_dim=int(module.proj_a.weight.numel() + module.proj_b.weight.numel()),
                multiplicity=1,
                metadata={"module_path": name, "frontend": "torch.fx"},
            )
        )

    bundle = {
        "graph_name": f"pytorch_{example_name}",
        "model": model,
        "sample_inputs": {"x1": x1_sample, "x2": x2_sample},
        "nodes": [
            {
                "id": node.id,
                "kind": node.kind,
                "connection_mode": node.connection_mode,
                "input_a": node.input_a,
                "input_b": node.input_b,
                "output": node.output,
                "x1_dim": node.x1_dim,
                "x2_dim": node.x2_dim,
                "out_dim": node.out_dim,
                "weight_dim": node.weight_dim,
                "multiplicity": node.multiplicity,
                "metadata": node.metadata,
            }
            for node in nodes
        ],
        "outputs": [nodes[-1].output] if nodes else [],
    }
    graph, summary = _graph_from_bundle(bundle, source_name="pytorch_demo")
    summary["example_name"] = example_name
    summary["input_dims"] = placeholder_dims
    return graph, summary


def build_graph_from_pytorch_script(script_path: Path, entry_name: str = "build_model_bundle") -> Tuple[GraphSpec, Dict[str, object]]:
    builder = _load_builder_from_script(script_path, entry_name)
    bundle = builder()
    if not isinstance(bundle, dict):
        raise TypeError(f"{entry_name}() must return a dict bundle")
    graph, summary = _graph_from_bundle(bundle, source_name=script_path.stem)
    summary["script_path"] = str(script_path)
    summary["entry_name"] = entry_name
    return graph, summary


def dump_pytorch_frontend_artifacts(summary: Dict[str, object], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "00_pytorch_model.txt").write_text(str(summary["model_repr"]), encoding="utf-8")
    (output_dir / "00_pytorch_fx_graph.txt").write_text(str(summary["fx_graph"]), encoding="utf-8")
    (output_dir / "00_pytorch_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pytorch_fx_svg(summary: Dict[str, object], output_dir: Path) -> None:
    graph_lines = str(summary["fx_graph"]).splitlines()
    width = 200 + 220 * max(len(graph_lines) - 2, 1)
    height = 220
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#fbfbf8"/>',
        '<text x="24" y="32" font-size="24" font-family="Arial, sans-serif" fill="#152238">PyTorch FX Graph</text>',
    ]
    idx = 0
    for line in graph_lines:
        line = line.strip()
        if not line or line == "graph():" or line == "return block1":
            continue
        x = 30 + idx * 180
        parts.append(f'<rect x="{x}" y="90" width="150" height="60" rx="10" fill="#e3eefc" stroke="#3a5f8a"/>')
        parts.append(f'<text x="{x+10}" y="118" font-size="11" font-family="Arial" fill="#26466d">{line}</text>')
        idx += 1
    parts.append("</svg>")
    (output_dir / "00_pytorch_fx_graph.svg").write_text("\n".join(parts), encoding="utf-8")
