from __future__ import annotations

from collections import Counter
from typing import Dict, Tuple

from .model_catalog import get_problem_model_spec
from .spec import GraphSpec, InputSpec, NodeSpec


def _load_o3():
    try:
        from e3nn import o3  # type: ignore
    except Exception as exc:  # pragma: no cover
        raise SystemExit(f"Built-in problem-model adapter requires e3nn. import failed: {exc}")
    return o3


def _build_irreps_layout(irreps) -> list[dict]:
    layout = []
    vec_start = 0
    mul_start = 0
    for idx, (mul, ir) in enumerate(irreps):
        dim_single = 2 * ir.l + 1
        total_dim = mul * dim_single
        layout.append(
            {
                "idx": idx,
                "label": f"{mul}x{ir}",
                "mul": int(mul),
                "l": int(ir.l),
                "start": int(vec_start),
                "end": int(vec_start + total_dim),
                "mul_start": int(mul_start),
                "mul_end": int(mul_start + mul),
            }
        )
        vec_start += total_dim
        mul_start += mul
    return layout


def graph_from_problem_model(model_name: str, batch_size: int = 3000) -> GraphSpec:
    o3 = _load_o3()
    spec = get_problem_model_spec(model_name)
    irreps_in1 = o3.Irreps(spec.irreps_in1)
    irreps_in2 = o3.Irreps(spec.irreps_in2)
    irreps_out = o3.Irreps(spec.irreps_out)
    tp = o3.FullyConnectedTensorProduct(
        irreps_in1,
        irreps_in2,
        irreps_out,
        irrep_normalization="none",
        path_normalization="none",
    )
    instructions = tp.instructions
    weight_views = list(tp.weight_views())
    in1_layout = _build_irreps_layout(irreps_in1)
    in2_layout = _build_irreps_layout(irreps_in2)
    out_layout = _build_irreps_layout(irreps_out)

    signature_counter: Counter[Tuple] = Counter()
    signature_meta: Dict[Tuple, Dict[str, int]] = {}

    for ins_idx, ins in enumerate(instructions):
        weight_view = weight_views[ins_idx]
        info1 = in1_layout[ins.i_in1]
        info2 = in2_layout[ins.i_in2]
        info3 = out_layout[ins.i_out]
        signature = (
            str(ins.connection_mode),
            int(info1["l"]),
            int(info1["mul"]),
            int(info2["l"]),
            int(info2["mul"]),
            int(info3["l"]),
            int(info3["mul"]),
        )
        signature_counter[signature] += 1
        signature_meta[signature] = {
            "x1_dim": int(info1["end"] - info1["start"]),
            "x2_dim": int(info2["end"] - info2["start"]),
            "out_dim": int(info3["end"] - info3["start"]),
            "weight_dim": int(weight_view.numel()),
        }

    nodes = []
    for idx, (signature, multiplicity) in enumerate(signature_counter.items()):
        connection_mode, l1, mul1, l2, mul2, l3, mul3 = signature
        dims = signature_meta[signature]
        nodes.append(
            NodeSpec(
                id=f"group_{idx}",
                kind="problem_adapted_mimo",
                connection_mode=connection_mode,
                input_a="x1",
                input_b="x2",
                output=f"y{idx}",
                x1_dim=dims["x1_dim"],
                x2_dim=dims["x2_dim"],
                out_dim=dims["out_dim"],
                weight_dim=dims["weight_dim"],
                multiplicity=multiplicity,
                metadata={
                    "problem_model": model_name,
                    "problem_category": spec.category,
                    "instruction_count": int(len(instructions)),
                    "l1": l1,
                    "mul1": mul1,
                    "l2": l2,
                    "mul2": mul2,
                    "l3": l3,
                    "mul3": mul3,
                    "source_batch_size": batch_size,
                },
            )
        )

    return GraphSpec(
        name=f"problem_{model_name}",
        inputs=[InputSpec(id="x1", dim=max(node.x1_dim for node in nodes)), InputSpec(id="x2", dim=max(node.x2_dim for node in nodes))],
        nodes=nodes,
        outputs=[node.output for node in nodes],
        metadata={
            "source": "builtin_problem_catalog",
            "problem_model": model_name,
            "problem_category": spec.category,
            "notes": "This is a structure-level adapted MIMO graph derived from a built-in e3nn tensor-product model catalog.",
        },
    )
