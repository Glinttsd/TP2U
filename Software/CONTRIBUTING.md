# Contributing

感谢你愿意参与 `MIMO TVM Flow`。

这个项目目前处于“开源流程骨架”阶段，因此我们更看重：

- 可读性
- 可复现性
- 阶段产物是否清晰
- 设计文档和代码是否一致

本文件的组织方式参考了当前主流开源项目常见做法，例如：

- Apache TVM 的 contributor guide
- Hugging Face Transformers 这类文档完备、示例丰富的仓库结构

这里不会完全复制它们的流程，但会借鉴它们在以下方面的习惯：

- 先写清楚贡献边界
- 先做最小可运行示例
- 让文档、示例和 CI 一起演进

## 我们欢迎什么类型的贡献

- 新的前端导入器
  - 例如 ONNX、PyTorch、Relay、MLIR
- 更好的 TVM IR 展示
- 更清晰的 SISO 拆分逻辑
- 更贴近真实硬件的打包格式
- 更完善的 README、教程、图示和示例
- 测试和 CI 改进

## 推荐的工作方式

### 1. 先提一个小范围变更

优先从这些方向开始：

- 增加一个新的输入样例
- 增加一个新的阶段化产物
- 增加一个新的前端适配器
- 修复 README 与实际命令不一致的问题

### 2. 保持阶段产物可检查

如果你修改了流程，请尽量保证每个阶段至少还有一种可以人工检查的输出，例如：

- JSON
- Markdown
- 文本 IR
- SVG 图

### 3. 对“研究原型”和“真实硬件路径”明确区分

本仓库有意保留这条边界：

- `opensource_flow/` 更偏开源教学与流程展示
- 外部实验工程或硬件验证路径更偏真实实验与平台联调

如果某个改动只适合研究原型，请明确写在文档里，不要让用户误以为它已经是 production path。

## 代码风格

- 使用 Python 3.8+ 兼容语法
- 优先写小函数，避免超长脚本
- 让模块边界清楚：
  - `spec`
  - `frontend/adapter`
  - `tvm lowering`
  - `siso split`
  - `packing`
  - `visualization`
- 当逻辑不是显然易见时，写简短注释

## 提交前建议检查

### 最小检查

```bash
python -m py_compile src/mimo_tvm_flow/*.py
python -m mimo_tvm_flow --input-json examples/sample_generic_mimo.json --output-dir outputs/local_smoke
```

### 如果你改了 PyTorch 前端

```bash
python -m mimo_tvm_flow --pytorch-example tiny_dual_input --output-dir outputs/pytorch_smoke
```

### 如果你改了内置 problem-model 入口

```bash
python -m mimo_tvm_flow --problem-model DiffDock-L=1 --batch-size 3000 --output-dir outputs/problem_smoke
```

如果你改的是内置模型目录，请同时检查：

- `src/mimo_tvm_flow/model_catalog.py`
- `README.md` 中关于 `--problem-model` 的说明

## 提交信息建议

推荐提交信息风格：

- `frontend: add pytorch fx demo adapter`
- `docs: expand README quickstart and outputs`
- `packing: align demo packet manifest with instruction stream`

## 设计变更建议

如果你要做下面这些较大改动，建议先在 issue 或设计文档里说明：

- 改输入规范
- 改阶段产物文件名
- 改 instruction/bin 格式
- 改 grouped ISA 的表达方式
- 引入新的核心依赖

## 文档优先级

如果你的改动影响用户用法，请同时更新：

- `README.md`
- 相关 `examples/`
- 如有必要，补一个新的输出样例

## 行为准则

默认使用：

- 尊重他人的实验结论
- 区分事实、假设和路线图
- 对暂未实现的能力明确标注
