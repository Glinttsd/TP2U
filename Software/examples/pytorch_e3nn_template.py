from __future__ import annotations

import torch


class UserDefinedMIMOLayer(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.x1_dim = 16
        self.x2_dim = 8
        self.out_dim = 12
        self.linear_a = torch.nn.Linear(self.x1_dim, self.out_dim)
        self.linear_b = torch.nn.Linear(self.x2_dim, self.out_dim)

    def forward(self, x1, x2):
        return torch.relu(self.linear_a(x1) + self.linear_b(x2))


def build_model_bundle():
    model = UserDefinedMIMOLayer().eval()
    x1 = torch.randn(1, model.x1_dim)
    x2 = torch.randn(1, model.x2_dim)
    return {
        "graph_name": "user_e3nn_like_layer",
        "model": model,
        "sample_inputs": {"x1": x1, "x2": x2},
        "nodes": [
            {
                "id": "layer0",
                "kind": "user_pytorch_e3nn_layer",
                "connection_mode": "uvw",
                "input_a": "x1",
                "input_b": "x2",
                "output": "y0",
                "x1_dim": model.x1_dim,
                "x2_dim": model.x2_dim,
                "out_dim": model.out_dim,
                "weight_dim": model.linear_a.weight.numel() + model.linear_b.weight.numel(),
                "multiplicity": 1,
                "metadata": {
                    "note": "Replace this layer with your own e3nn/PyTorch module and update the dimensions accordingly."
                },
            }
        ],
        "outputs": ["y0"],
    }
