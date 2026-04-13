from __future__ import annotations

import json
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Sequence

import numpy as np

from .siso import SISOUnit


OPCODE_CFG = 0x1
OPCODE_SETL = 0x2
OPCODE_SETN = 0x3
OPCODE_LOAD = 0x4
OPCODE_MOVE = 0x5
OPCODE_EXEC = 0x6
OPCODE_HALT = 0x7

MODE_MAP = {"uvw": 0, "uvu": 1, "uvv": 2, "uuw": 3}


@dataclass(frozen=True)
class PackSummary:
    packet_count: int
    packet_data_bytes: int
    instruction_stream_bytes: int
    total_bytes: int


def _u8(value: int) -> int:
    return int(value) & 0xFF


def _u24(value: int) -> int:
    return int(value) & 0xFFFFFF


def align_up(value: int, alignment: int) -> int:
    return ((value + alignment - 1) // alignment) * alignment


def _make_i32_payload(length: int, seed: int) -> bytes:
    rng = np.random.default_rng(seed)
    arr = rng.integers(-8, 8, size=max(length, 1), dtype=np.int32)
    return arr.tobytes()


def _packet_payload(unit: SISOUnit, packet_index: int, align_bytes: int = 64) -> bytes:
    parts = [
        _make_i32_payload(unit.x1_dim, 1000 + packet_index),
        _make_i32_payload(unit.x2_dim, 2000 + packet_index),
        _make_i32_payload(unit.weight_dim, 3000 + packet_index),
        struct.pack("<4i", unit.x1_dim, unit.x2_dim, unit.out_dim, unit.replica_index),
    ]
    buf = bytearray()
    for raw in parts:
        pad = (-len(raw)) % align_bytes
        buf.extend(raw)
        if pad:
            buf.extend(b"\x00" * pad)
    return bytes(buf)


def _packet_instruction_words(unit: SISOUnit, src_addr_imm: int) -> List[int]:
    tp_mode = _u8(MODE_MAP.get(unit.connection_mode, 7))
    l1 = _u8(unit.x1_dim)
    l2 = _u8(unit.x2_dim)
    l3 = _u8(unit.out_dim)
    n1 = _u8(unit.x1_dim)
    n2 = _u8(unit.x2_dim)
    n3 = _u8(unit.out_dim)
    src = _u24(src_addr_imm)
    return [
        (OPCODE_CFG << 28) | (tp_mode << 20),
        (OPCODE_SETL << 28) | (l1 << 20) | (l2 << 12) | (l3 << 4),
        (OPCODE_SETN << 28) | (n1 << 20) | (n2 << 12) | (n3 << 4),
        (OPCODE_LOAD << 28) | (src << 4),
        (OPCODE_MOVE << 28),
        (OPCODE_EXEC << 28),
        (OPCODE_HALT << 28),
    ]


def pack_siso_units(units: Sequence[SISOUnit], output_dir: Path) -> PackSummary:
    output_dir.mkdir(parents=True, exist_ok=True)
    packet_path = output_dir / "05_packet_data.bin"
    instr_path = output_dir / "05_instruction_stream.bin"
    summary_path = output_dir / "05_pack_summary.json"

    packet_buf = bytearray()
    instr_buf = bytearray()
    manifest = []

    for idx, unit in enumerate(units):
        if len(packet_buf) % 16 != 0:
            raise ValueError("packet payload start must be 16-byte aligned")
        src_addr_imm = len(packet_buf) // 16
        payload = _packet_payload(unit, idx)
        packet_buf.extend(payload)
        for word in _packet_instruction_words(unit, src_addr_imm):
            instr_buf.extend(struct.pack("<I", word & 0xFFFFFFFF))
        manifest.append(
            {
                "packet_index": idx,
                "source_node": unit.source_node,
                "replica_index": unit.replica_index,
                "src_addr_imm": src_addr_imm,
                "payload_bytes": len(payload),
            }
        )

    packet_path.write_bytes(bytes(packet_buf))
    instr_path.write_bytes(bytes(instr_buf))

    summary = PackSummary(
        packet_count=len(units),
        packet_data_bytes=len(packet_buf),
        instruction_stream_bytes=len(instr_buf),
        total_bytes=len(packet_buf) + len(instr_buf),
    )
    summary_path.write_text(
        json.dumps(
            {
                "packet_count": summary.packet_count,
                "packet_data_bytes": summary.packet_data_bytes,
                "instruction_stream_bytes": summary.instruction_stream_bytes,
                "total_bytes": summary.total_bytes,
                "manifest": manifest,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    return summary
