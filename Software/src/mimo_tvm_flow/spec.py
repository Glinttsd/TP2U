from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Sequence


@dataclass(frozen=True)
class InputSpec:
    id: str
    dim: int


@dataclass(frozen=True)
class NodeSpec:
    id: str
    kind: str
    connection_mode: str
    input_a: str
    input_b: str
    output: str
    x1_dim: int
    x2_dim: int
    out_dim: int
    weight_dim: int
    multiplicity: int = 1
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class GraphSpec:
    name: str
    inputs: List[InputSpec]
    nodes: List[NodeSpec]
    outputs: List[str]
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "inputs": [asdict(inp) for inp in self.inputs],
            "nodes": [asdict(node) for node in self.nodes],
            "outputs": list(self.outputs),
            "metadata": dict(self.metadata),
        }


def _require_positive(name: str, value: int) -> int:
    if value <= 0:
        raise ValueError(f"{name} must be greater than zero, got {value}")
    return value


def graph_from_dict(data: Dict[str, Any]) -> GraphSpec:
    inputs = [InputSpec(id=item["id"], dim=_require_positive("input.dim", int(item["dim"]))) for item in data["inputs"]]
    nodes = [
        NodeSpec(
            id=item["id"],
            kind=item.get("kind", "generic_mimo"),
            connection_mode=item["connection_mode"],
            input_a=item["input_a"],
            input_b=item["input_b"],
            output=item["output"],
            x1_dim=_require_positive("x1_dim", int(item["x1_dim"])),
            x2_dim=_require_positive("x2_dim", int(item["x2_dim"])),
            out_dim=_require_positive("out_dim", int(item["out_dim"])),
            weight_dim=_require_positive("weight_dim", int(item["weight_dim"])),
            multiplicity=_require_positive("multiplicity", int(item.get("multiplicity", 1))),
            metadata=dict(item.get("metadata", {})),
        )
        for item in data["nodes"]
    ]
    return GraphSpec(
        name=data["name"],
        inputs=inputs,
        nodes=nodes,
        outputs=list(data.get("outputs", [])),
        metadata=dict(data.get("metadata", {})),
    )


def load_graph_spec(path: Path) -> GraphSpec:
    return graph_from_dict(json.loads(path.read_text(encoding="utf-8")))


def dump_graph_spec(graph: GraphSpec, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(graph.to_dict(), ensure_ascii=False, indent=2), encoding="utf-8")
