<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/omniinfer-logo-dark.svg">
    <img src="assets/omniinfer-logo-light.svg" alt="OmniInfer logo" width="520">
  </picture>
</p>

# OmniInfer

<p align="center"><a href="../README.md">English</a> | <strong>简体中文</strong></p>

<p align="center">在每一台设备上轻松、快速、私密地运行 LLM 与 VLM 推理。</p>

<p align="center">
  <a href="https://github.com/omnimind-ai/OmniInfer/actions/workflows/main-platform-ci.yml"><img alt="Main Platform CI" src="https://github.com/omnimind-ai/OmniInfer/actions/workflows/main-platform-ci.yml/badge.svg"></a>
  <a href="https://github.com/omnimind-ai/OmniInfer/releases/latest"><img alt="Latest Release" src="https://img.shields.io/github/v/release/omnimind-ai/OmniInfer?display_name=tag&amp;sort=semver"></a>
  <a href="../LICENSE"><img alt="License" src="https://img.shields.io/github/license/omnimind-ai/OmniInfer"></a>
</p>

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> ·
  <a href="#文档"><strong>文档</strong></a> ·
  <a href="https://github.com/omnimind-ai/OmniInfer/releases"><strong>版本发布</strong></a>
</p>

## 快速开始

### 安装 OmniInfer

<table>
  <thead>
    <tr>
      <th>Linux x64</th>
      <th>macOS arm64</th>
      <th>Windows x64 PowerShell</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>curl -fsSL https://raw.githubusercontent.com/omnimind-ai/OmniInfer/main/scripts/install.sh | bash</code></td>
      <td><code>curl -fsSL https://raw.githubusercontent.com/omnimind-ai/OmniInfer/main/scripts/install.sh | bash</code></td>
      <td><code>irm https://raw.githubusercontent.com/omnimind-ai/OmniInfer/main/scripts/install.ps1 | iex</code></td>
    </tr>
  </tbody>
</table>

安装脚本会下载最新的 GitHub Release 版 CLI（仅含命令行工具），校验其 SHA-256，并为当前用户完成安装。如需固定版本、自定义路径、手动安装、源码安装或卸载，请参阅[安装指南](installation.md)。

### 三步上手

1. 在终端运行 `omniinfer`。
2. 选择一个兼容的后端。TUI 可以为你安装可用的预编译运行时。
3. 选择一个本地模型，开始对话。

如需运行本地 OpenAI / Anthropic 兼容服务，请执行 `omniinfer serve`，并参考 [CLI 指南](CLI.md)或 [API 参考](API.md)。

## 新闻

- **2026-08-28** — **支持 Qwen3.8-Flash-Next。** OmniInfer 现已跟进 llama.cpp `b10665`，可直接加载分片 GGUF 模型目录。在 OmniInfer 发布对应的预编译运行时之前，请使用源码构建的 llama.cpp 后端。
- **2026-08-14** — 🚀 **首日支持 Qwen3.8-27B。** OmniInfer 从发布首日起即可运行 Qwen 最新的 27B 视觉语言模型。

## 演示

### 终端界面 — 选择后端、加载模型、本地对话

运行 `omniinfer` 会打开终端界面：推荐兼容的后端、加载本地模型，并启动完全本地的对话。

<p align="center">
  <img src="assets/demo/tui-chat.webp" width="720" alt="终端界面选择后端、加载模型并进行本地对话">
</p>
<p align="center"><sub>静态预览：<a href="assets/demo/tui-chat-poster.webp">终端界面截图</a></sub></p>

### 浏览器 VLA 演示 — 在 LIBERO 上运行 SmolVLA

可选的 [vla-libero 示例](../examples/vla-libero/README.md)通过受管理的 vla.cpp 运行时，在 LIBERO 仿真环境中运行 SmolVLA 策略，并在浏览器面板中实时展示相机画面、预测动作和延迟。

<p align="center">
  <img src="assets/demo/vla-libero.webp" width="720" alt="SmolVLA LIBERO 浏览器面板，展示相机画面、预测动作、延迟和一次成功的执行">
</p>
<p align="center"><sub>静态预览：<a href="assets/demo/vla-libero-poster.webp">SmolVLA LIBERO 面板截图</a></sub></p>

## 关于

OmniInfer 是一款高性能、跨平台的推理引擎，用于在本地运行大语言模型（LLM）和视觉语言模型（VLM）。它屏蔽了模型编译、硬件适配和部署的复杂性，只需极少配置即可实现高效的本地推理。

> OmniInfer 为统一模型编排平台 [Omni Studio](https://omnimind.com.cn/omnistudio) 提供推理层能力。

OmniInfer 足够快：

- 优化的 token 生成速度与极小的内存占用
- 多种后端引擎，包括 llama.cpp、stable-diffusion.cpp、ik_llama.cpp、MNN、MLX、TurboQuant、LiteRT-LM、ExecuTorch QNN，以及在支持的平台上可用的 OmniInfer Native
- 硬件感知的适配与优化

OmniInfer 灵活易用：

- 无缝切换多种后端，在每台设备上使用最合适的可用引擎
- 兼容 OpenAI 与 Anthropic 的本地 API 端点
- 支持文本与视觉语言任务
- 可精细控制上下文长度、GPU offload、KV cache 以及后端原生启动参数

OmniInfer 随处可运行：

- Linux、macOS、Windows — 桌面与服务器
- Android 与 iOS — 移动与边缘设备
- 一套代码覆盖 CLI、HTTP 网关和移动端模块

## 平台支持

| 平台        | 分发方式           | 代表性运行时                                                 |
| ----------- | ------------------ | ------------------------------------------------------------ |
| Linux x64   | Release CLI 与源码 | llama.cpp、stable-diffusion.cpp、ik_llama.cpp、vLLM、vla.cpp |
| macOS arm64 | Release CLI 与源码 | llama.cpp、MLX、TurboQuant                                   |
| Windows x64 | Release CLI 与源码 | llama.cpp、stable-diffusion.cpp、基于 WSL2 的 vLLM           |
| Android     | Gradle 模块        | llama.cpp、MNN、LiteRT-LM、ExecuTorch QNN                    |
| iOS         | Swift Package      | 内嵌原生推理服务                                             |

运行时是否可用取决于设备和加速器。使用 `omniinfer backend list` 查看当前机器的情况；[后端名称](backend-names.md)说明了 selector 与旧名称兼容，完整平台矩阵见[构建指南](build.md)。

## 文档

### 从这里开始

- [安装指南](installation.md)：Release 安装脚本、版本固定、源码安装、手动安装与卸载
- [CLI 指南](CLI.md)：后端安装、模型加载、对话、服务与桌面应用集成
- [API 参考](API.md)：本地 OpenAI / Anthropic 兼容 HTTP API

### 运维与集成

- [模型加载](model-load.md)：模型发现、参数与各后端的特定行为
- [远程访问](remote-access.md)：局域网访问、Cloudflare Quick Tunnel、反向代理与安全
- [Benchmark 结果](benchmark.md)：生成并归档可提交的 benchmark JSON

### 构建与嵌入

- [构建指南](build.md)：源码检出、后端构建与平台打包
- [Android 集成](android/integration.md)：在 Android 应用中嵌入 OmniInfer
- [Android 后端参考](android/backends.md)：Android 运行时选择与要求
- [Android 冒烟测试](android/smoke-tests.md)与[故障排查](android/troubleshooting.md)

## 架构

![OmniInfer 架构：入口层、Rust 控制面、平台抽象层、推理引擎层与支持的模型](assets/architecture-zh-CN.svg)

## 参与贡献

欢迎贡献代码与合作。参与方式请参阅 [Contributing to OmniInfer](../CONTRIBUTING.md)。

## 引用

如果你在研究中使用了 OmniInfer，请引用本仓库。GitHub 可根据 [CITATION.cff](../CITATION.cff) 生成其他引用格式。

```bibtex
@software{omniinfer,
  author = {{Omnimind AI}},
  title = {OmniInfer},
  url = {https://github.com/omnimind-ai/OmniInfer}
}
```

## 许可证

OmniInfer 基于 Apache License 2.0 许可证发布，详见 [LICENSE](../LICENSE)。
