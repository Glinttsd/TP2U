from __future__ import annotations

import json
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

from .spec import GraphSpec


@dataclass(frozen=True)
class SISOUnit:
    source_node: str
    connection_mode: str
    replica_index: int
    x1_dim: int
    x2_dim: int
    out_dim: int
    weight_dim: int
    signature: Tuple[str, int, int, int]


def split_graph_to_siso(graph: GraphSpec) -> List[SISOUnit]:
    units: List[SISOUnit] = []
    for node in graph.nodes:
        signature = (node.connection_mode, node.x1_dim, node.x2_dim, node.out_dim)
        for replica in range(node.multiplicity):
            units.append(
                SISOUnit(
                    source_node=node.id,
                    connection_mode=node.connection_mode,
                    replica_index=replica,
                    x1_dim=node.x1_dim,
                    x2_dim=node.x2_dim,
                    out_dim=node.out_dim,
                    weight_dim=node.weight_dim,
                    signature=signature,
                )
            )
    return units


def group_siso_units(units: Sequence[SISOUnit]) -> Dict[str, List[dict]]:
    grouped: Dict[str, List[dict]] = defaultdict(list)
    for unit in units:
        key = f"{unit.connection_mode}|{unit.x1_dim}|{unit.x2_dim}|{unit.out_dim}"
        grouped[key].append(asdict(unit))
    return dict(grouped)


def dump_siso_artifacts(units: Sequence[SISOUnit], grouped: Dict[str, List[dict]], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "04_siso_units.json").write_text(
        json.dumps([asdict(unit) for unit in units], ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (output_dir / "04_siso_groups.json").write_text(json.dumps(grouped, ensure_ascii=False, indent=2), encoding="utf-8")
