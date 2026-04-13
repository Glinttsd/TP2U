from __future__ import annotations

from pathlib import Path
from typing import Dict, Sequence

from .siso import SISOUnit
from .spec import GraphSpec


def _svg_header(width: int, height: int) -> str:
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'


def write_graph_svg(graph: GraphSpec, path: Path, title: str) -> None:
    width = 320 + 220 * max(len(graph.nodes), 1)
    height = 220
    parts = [_svg_header(width, height), '<rect width="100%" height="100%" fill="#fbfbf8"/>']
    parts.append(f'<text x="24" y="32" font-size="24" font-family="Arial, sans-serif" fill="#152238">{title}</text>')

    input_x = 40
    for idx, inp in enumerate(graph.inputs):
        y = 70 + idx * 60
        parts.append(f'<rect x="{input_x}" y="{y}" width="120" height="38" rx="10" fill="#dce8f7" stroke="#31587a"/>')
        parts.append(f'<text x="{input_x+14}" y="{y+24}" font-size="14" font-family="Arial" fill="#24476b">{inp.id} ({inp.dim})</text>')

    node_x = 220
    for idx, node in enumerate(graph.nodes):
        x = node_x + idx * 180
        parts.append(f'<rect x="{x}" y="74" width="140" height="70" rx="12" fill="#f7e9d7" stroke="#8a5d1f"/>')
        parts.append(f'<text x="{x+14}" y="100" font-size="14" font-family="Arial" fill="#6d4714">{node.id}</text>')
        parts.append(f'<text x="{x+14}" y="120" font-size="12" font-family="Arial" fill="#7c5a28">{node.connection_mode}, x{node.multiplicity}</text>')
        parts.append(f'<text x="{x+14}" y="138" font-size="11" font-family="Arial" fill="#7c5a28">{node.x1_dim}/{node.x2_dim}->{node.out_dim}</text>')

    output_x = node_x + 180 * max(len(graph.nodes), 1)
    for idx, out in enumerate(graph.outputs):
        y = 84 + idx * 50
        parts.append(f'<rect x="{output_x}" y="{y}" width="120" height="36" rx="10" fill="#d8f0de" stroke="#27633c"/>')
        parts.append(f'<text x="{output_x+14}" y="{y+23}" font-size="14" font-family="Arial" fill="#1f5130">{out}</text>')

    parts.append("</svg>")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(parts), encoding="utf-8")


def write_siso_svg(units: Sequence[SISOUnit], path: Path, title: str) -> None:
    width = 360 + 120 * max(len(units), 1)
    height = 240
    parts = [_svg_header(width, height), '<rect width="100%" height="100%" fill="#fbfbf8"/>']
    parts.append(f'<text x="24" y="32" font-size="24" font-family="Arial, sans-serif" fill="#152238">{title}</text>')
    for idx, unit in enumerate(units):
        x = 30 + idx * 110
        parts.append(f'<rect x="{x}" y="90" width="90" height="90" rx="10" fill="#e7e3f7" stroke="#54408d"/>')
        parts.append(f'<text x="{x+10}" y="116" font-size="12" font-family="Arial" fill="#44336f">{unit.source_node}</text>')
        parts.append(f'<text x="{x+10}" y="136" font-size="11" font-family="Arial" fill="#5c4b8e">replica {unit.replica_index}</text>')
        parts.append(f'<text x="{x+10}" y="154" font-size="10" font-family="Arial" fill="#5c4b8e">{unit.x1_dim}/{unit.x2_dim}</text>')
        parts.append(f'<text x="{x+10}" y="170" font-size="10" font-family="Arial" fill="#5c4b8e">out {unit.out_dim}</text>')
    parts.append("</svg>")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(parts), encoding="utf-8")


def write_input_summary(graph: GraphSpec, path: Path) -> None:
    lines = [
        "# Input Graph Summary",
        "",
        f"- name: `{graph.name}`",
        f"- inputs: {len(graph.inputs)}",
        f"- nodes: {len(graph.nodes)}",
        f"- outputs: {len(graph.outputs)}",
        "",
        "| node_id | connection_mode | x1_dim | x2_dim | out_dim | weight_dim | multiplicity |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for node in graph.nodes:
        lines.append(
            f"| {node.id} | {node.connection_mode} | {node.x1_dim} | {node.x2_dim} | {node.out_dim} | {node.weight_dim} | {node.multiplicity} |"
        )
    path.write_text("\n".join(lines), encoding="utf-8")


def write_pipeline_report(
    graph: GraphSpec,
    grouped: Dict[str, list],
    packet_summary: Dict[str, int],
    output_dir: Path,
) -> None:
    report = output_dir / "06_pipeline_report.md"
    total_siso = sum(len(items) for items in grouped.values())
    lines = [
        "# Pipeline Report",
        "",
        "## Summary",
        "",
        f"- graph: `{graph.name}`",
        f"- input nodes: {len(graph.nodes)}",
        f"- expanded SISO units: {total_siso}",
        f"- grouped signatures: {len(grouped)}",
        f"- packet_count: {packet_summary['packet_count']}",
        f"- packet_data_bytes: {packet_summary['packet_data_bytes']}",
        f"- instruction_stream_bytes: {packet_summary['instruction_stream_bytes']}",
        "",
        "## Output Files",
        "",
        "- `01_input_graph.json`",
        "- `01_input_graph.svg`",
        "- `02_tvm_importable.json`",
        "- `03_relay_module.txt`",
        "- `04_siso_units.json`",
        "- `04_siso_groups.json`",
        "- `04_siso_graph.svg`",
        "- `05_packet_data.bin`",
        "- `05_instruction_stream.bin`",
        "- `05_pack_summary.json`",
        "",
        "## Notes",
        "",
        "- This flow is designed for explanation, inspection, and open-source onboarding.",
        "- The generated bin format is a generic demonstration format rather than a drop-in replacement for the existing FPGA kernel path.",
    ]
    report.write_text("\n".join(lines), encoding="utf-8")
