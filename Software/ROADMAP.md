# Roadmap

## 当前阶段：v0.1

项目已经具备：

- 通用 JSON 前端
- 内置 problem-model 目录适配入口
- TVM Relay IR 导出
- SISO 拆分与分组
- 通用示例 bin 打包
- 阶段化 JSON / SVG / Markdown / bin 产物
- 可运行 README 和基础 CI smoke

## v0.2 目标

### 前端

- 增加 PyTorch 前端示例
- 增加 ONNX 前端示例
- 统一前端元数据输出

### 可视化

- 增加更清晰的图布局
- 增加 HTML 报告
- 增加每阶段统计摘要图

### TVM

- 增加更明确的 Relay pass 摘要
- 记录前后图节点数量与类型变化
- 增加结构签名统计

## v0.3 目标

### SISO / Grouping

- 增加 grouped SISO 设计导出
- 区分：
  - 结构可分组
  - 当前格式可直接去重
  - 需要 ISA 修改后才能落地的分组

### Packing

- 增加更接近现有 FPGA 路径的 instruction 风格
- 增加 grouped metadata 原型
- 增加 pack manifest 校验脚本

## v0.4 目标

### 硬件协同

- 增加到外部真实 packet/instruction 路径的桥接器
- 支持把内置 problem-model 输出映射到外部实验工程
- 增加与 HBM 传输测试结果的对接

## 长期目标

- 从“流程骨架”演进为：
  - 前端导入
  - TVM IR
  - SISO 拆分
  - grouped ISA 原型
  - bin 导出
  - 报告生成
  的完整研究与工程桥接平台

## 当前明确不做的事情

- 不把当前示例 bin 宣称为 production kernel 可直接执行的真实格式
- 不假设所有 TVM 结构分组都能直接变成真实 packet 去重
- 不在没有验证的前提下承诺硬件性能收益
