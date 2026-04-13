# TP2U: Accelerating Equivariant Neural Networks with Tensor Product Processing Unit on FPGA

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform: FPGA](https://img.shields.io/badge/Platform-AMD%20VCU128-orange.svg)](https://www.xilinx.com/products/boards-and-kits/vcu128.html)

**TP²U** is a software-hardware co-design framework developed to accelerate the Clebsch-Gordan tensor product (CGTP)]. CGTP is the primary computational bottleneck in Equivariant Neural Networks (ENNs), which are widely used for modeling 3D geometric data in physical and biological systems.

---

## 📸 Algorithm & Architecture Overview

<p align="center">
  <img src="assets/challenges.png" alt="challenges and solutions" width="600"/>
</p>
<p align="center">
  <em>Challenges and solutions for accelerating ENNs on FPGA <sup></sup>.</em>
</p>

### Key Innovations
* **Sparse-Bypass Strategy (SBS):** Exploits the inherent structural sparsity of CG coefficients (>80%). It uses a novel CG data format to pack overlapping non-zeros, bypassing redundant data accesses and computations.
* **Merged-Shift Quantization (MSQ):** Enables full Int8 representation for irreps, weights, and CG coefficients. It replaces complex operations with hardware-friendly, shift-only dequantization.
* **Equicore Unit:** A cascaded processing unit that tightly couples FPGA logic with RAM and DSP resources. It simplifies logic data paths to achieve a high operating frequency of **500 MHz**.

---

## 🏗️ Hardware Architecture

The $TP^{2}U$ system consists of a host CPU, high-bandwidth memory (HBM), and the FPGA hardware accelerator.

<p align="center">
  <img src="assets/architecture.png" alt="Illustration of the Clebsch-Gordan tensor product (CGTP) computation flow" width="300"/>
</p>
<p align="center">
  <em>Figure 9: Illustrates the interaction between the CPU, HBM, instruction cache, and the parallel Equicore tiles</sup>.</em>
</p>

### Resource Utilization (AMD Virtex VCU128)
As reported after synthesis and implementation in Vivado 2024.1:

| Resource | Used | Available | Utilization |
| :--- | :--- | :--- | :--- |
| **LUT** | 918,138 | 1,303,680 | 70.43% |
| **FF** | 1,043,328 | 2,607,360 | 40.01% |
| **BRAM** | 1,896.0 | 2,016 | 94.05% |
| **URAM** | 864.0 | 960 | 90.0% |
| **DSP** | 5,888 | 9,024 | 65.25% |

---

## 🚀 Software Compilation & ISA

The host CPU partitions MIMO tasks into independent SISO tasks and generates 32-bit customized instructions to orchestrate the hardware.

> **[Insert Figure 13: Customized instructions for executing CGTP operations]** > *(Description: Details the ISA including CFG, SETL, SETN, LOAD, MOVE, EXEC, and HALT instructions.)*

### Workflow
1. **Offline Quantization:** The host performs MSQ on irreps, weights, and CG coefficients.
2. **Instruction Generation:** The compiler generates a specific instruction stream for each SISO task.
3. **Deployment:** Instructions are loaded into the FPGA DDR, and data is transferred to HBM via PCIe.

---

## 📊 Experimental Results

### Performance & Efficiency
Compared to state-of-the-art GPU libraries (e3nn, OpenEquivariance), $TP^{2}U$ delivers:
* **Speedup:** Up to **10.5x** over e3nn and **5.3x** over OpenEquivariance.
* **Energy Efficiency:** Up to **17.4x** improvement over e3nn.

<p align="center">
  <img src="assets/latency_and_power_efficiency_comparison_Journal_V1.png" alt="Speedup and energy efficiency comparison of Equicore with GPU-based works" width="600"/>
</p>
<p align="center">
  <em>Figure 15: Speedup and energy efficiency comparison of Equicore with GPU-based works</sup>.</em>
</p>

### Accuracy Evaluation (Aspirin Dataset)
| Method | Force MAE (meV/Å) | Energy MAE (meV) | Hardware Friendly |
| :--- | :--- | :--- | :--- |
| Full Precision (fp32) | 0.038 | 0.274 | Low  |
| **TP²U (Ours - Int8)** | **0.309** | **9.18** | **High**  |
*(Note: While absolute error increases, the relative energy error remains extremely small (<<1%).)*

---

## 📄 License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.

## ✍️ Citation

If you use this work in your research, please cite our paper:

```bibtex
@article{tang2026tp2u,
  title={TP2U: Accelerating Equivariant Neural Networks with Tensor Product Processing Unit on FPGA},
  author={Tang, Shidi and Zhang, Chuanzhao and Chen, Ruiqi and Lv, Yuxuan and Silva, Bruno da and Ling, Ming},
  journal={IEEE},
  year={2026}
}