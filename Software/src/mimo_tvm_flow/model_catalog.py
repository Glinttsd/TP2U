from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Sequence, Tuple


@dataclass(frozen=True)
class ProblemModelSpec:
    category: str
    name: str
    irreps_in1: str
    irreps_in2: str
    irreps_out: str


E3NN_TETRIS_POLY_DICT: Dict[str, List[str]] = {
    "tetris-poly-1": ["1x0e + 1x1o + 1x2e + 1x3o", "1x0e + 1x1o + 1x2e + 1x3o", "64x0e + 24x1e + 24x1o + 16x2e + 16x2o"],
    "tetris-poly-2": ["64x0e + 24x1e + 24x1o + 16x2e + 16x2o", "1x0e + 1x1o + 1x2e", "1x0o + 6x0e"],
}

DIFFDOCK_DICT: Dict[str, List[str]] = {
    "DiffDock-L=1": ["10x1o + 10x1e + 48x0e + 48x0o", "1x0e + 1x1o", "10x1o + 10x1e + 48x0e + 48x0o"],
    "DiffDock-L=2": ["10x1o + 10x1e + 48x0e + 48x0o", "1x0e + 1x1o + 1x2e", "10x1o + 10x1e + 48x0e + 48x0o"],
}

MACE_DICT: Dict[str, List[str]] = {
    "mace-large": ["128x0e+128x1o+128x2e", "1x0e+1x1o+1x2e+1x3o", "128x0e+128x1o+128x2e+128x3o"],
    "mace-medium": ["128x0e+128x1o", "1x0e+1x1o+1x2e+1x3o", "128x0e+128x1o+128x2e"],
}

NEQUIP_DICT: Dict[str, List[str]] = {
    "nequip-lips": ["32x0o + 32x0e + 32x1o + 32x1e + 32x2o + 32x2e", "1x0e + 1x1o + 1x2e", "32x0o + 32x0e + 32x1o + 32x1e + 32x2o + 32x2e"],
    "nequip-revmd17-aspirin": ["64x0o + 64x0e + 64x1o + 64x1e", "1x0e + 1x1o", "64x0o + 64x0e + 64x1o + 64x1e"],
    "nequip-revmd17-toluene": ["64x0o + 64x0e + 64x1o + 64x1e + 64x2o + 64x2e", "1x0e + 1x1o + 1x2e", "64x0o + 64x0e + 64x1o + 64x1e + 64x2o + 64x2e"],
    "nequip-revmd17-benzene": [
        "64x0o + 64x0e + 64x1o + 64x1e + 64x2o + 64x2e + 64x3o + 64x3e",
        "1x0e + 1x1o + 1x2e + 1x3o",
        "64x0o + 64x0e + 64x1o + 64x1e + 64x2o + 64x2e + 64x3o + 64x3e",
    ],
    "nequip-water": ["32x0o + 32x0e + 32x1o + 32x1e", "1x0e + 1x1o", "32x0o + 32x0e + 32x1o + 32x1e"],
}

MODEL_CATEGORIES: List[Tuple[str, Dict[str, List[str]]]] = [
    ("diffdock", DIFFDOCK_DICT),
    ("mace", MACE_DICT),
    ("nequip", NEQUIP_DICT),
    ("tetris", E3NN_TETRIS_POLY_DICT),
]

MODEL_SPECS: List[ProblemModelSpec] = [
    ProblemModelSpec(category=category, name=name, irreps_in1=values[0], irreps_in2=values[1], irreps_out=values[2])
    for category, model_dict in MODEL_CATEGORIES
    for name, values in model_dict.items()
]

MODEL_BY_NAME = {spec.name: spec for spec in MODEL_SPECS}


def iter_problem_model_specs(model_name: str = "all") -> Sequence[ProblemModelSpec]:
    if model_name == "all":
        return tuple(MODEL_SPECS)
    try:
        return (MODEL_BY_NAME[model_name],)
    except KeyError as exc:
        available = ", ".join(spec.name for spec in MODEL_SPECS)
        raise ValueError(f"unknown built-in problem model {model_name!r}; available: all, {available}") from exc


def get_problem_model_spec(model_name: str) -> ProblemModelSpec:
    return iter_problem_model_specs(model_name)[0]
