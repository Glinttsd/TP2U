from __future__ import annotations

import torch


class ToyMIMOBlock(torch.nn.Module):
    def __init__(self, x1_dim: int, x2_dim: int, out_dim: int):
        super().__init__()
        self.x1_dim = x1_dim
        self.x2_dim = x2_dim
        self.out_dim = out_dim
        self.proj_a = torch.nn.Linear(x1_dim, out_dim)
        self.proj_b = torch.nn.Linear(x2_dim, out_dim)

    def forward(self, x1, x2):
        return torch.relu(self.proj_a(x1) + self.proj_b(x2))


class TinyDualInputMIMO(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.block0 = ToyMIMOBlock(16, 8, 12)
        self.block1 = ToyMIMOBlock(12, 8, 6)

    def forward(self, x1, x2):
        hidden = self.block0(x1, x2)
        return self.block1(hidden, x2)


def build_demo_model(name: str = "tiny_dual_input") -> torch.nn.Module:
    if name != "tiny_dual_input":
        raise ValueError(f"unknown PyTorch example: {name}")
    return TinyDualInputMIMO()


if __name__ == "__main__":
    model = build_demo_model()
    x1 = torch.randn(1, 16)
    x2 = torch.randn(1, 8)
    y = model(x1, x2)
    print(model)
    print("output shape:", tuple(y.shape))
