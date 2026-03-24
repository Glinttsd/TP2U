from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Tuple

import tvm
from tvm import relay

from .spec import GraphSpec, NodeSpec


def _make_node_expr(left, right, node: NodeSpec):
    weight = relay.var(f"{node.id}_w", shape=(max(node.weight_dim, 1),), dtype="float32")
    scalar = relay.add(relay.sum(left), relay.add(relay.sum(right), relay.sum(weight)))
    out = relay.broadcast_to(relay.reshape(scalar, (1,)), (max(node.out_dim, 1),))
    if node.connection_mode != "uvw":
        out = relay.nn.relu(out)
    return out, weight


def build_relay_module(graph: GraphSpec) -> Tuple[tvm.IRModule, Dict[str, object]]:
    env = {}
    fn_params = []
    summary = {
        "graph_name": graph.name,
        "input_count": len(graph.inputs),
        "node_count": len(graph.nodes),
        "output_count": len(graph.outputs),
        "weight_var_count": 0,
        "nodes": [],
    }

    for inp in graph.inputs:
        var = relay.var(inp.id, shape=(inp.dim,), dtype="float32")
        env[inp.id] = var
        fn_params.append(var)

    for node in graph.nodes:
        left = env[node.input_a]
        right = env[node.input_b]
        expr, weight = _make_node_expr(left, right, node)
        env[node.output] = expr
        fn_params.append(weight)
        summary["weight_var_count"] += 1
        summary["nodes"].append(
            {
                "id": node.id,
                "kind": node.kind,
                "connection_mode": node.connection_mode,
                "multiplicity": node.multiplicity,
                "x1_dim": node.x1_dim,
                "x2_dim": node.x2_dim,
                "out_dim": node.out_dim,
                "weight_dim": node.weight_dim,
            }
        )

    outputs = [env[name] for name in graph.outputs]
    body = outputs[0] if len(outputs) == 1 else relay.Tuple(outputs)
    main = relay.Function(fn_params, body)
    mod = tvm.IRModule({"main": main})
    mod = relay.transform.InferType()(mod)
    return mod, summary


def dump_relay_artifacts(mod: tvm.IRModule, summary: Dict[str, object], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "03_relay_module.txt").write_text(mod.astext(show_meta_data=False), encoding="utf-8")
    (output_dir / "03_relay_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
