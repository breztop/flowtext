# FlowText (TextFlow)

**FlowText** 是一个基于 Godot 4.6 (兼容 4.x) 的高性能跨平台文本特效引擎。它旨在提供流畅、低延迟且易于使用的文本动效解决方案，适用于游戏 UI、直播弹幕、演示文稿等场景。

## 核心目标

*   **跨平台展示**: 完美适配桌面与移动端 UI，自动缩放。
*   **丰富的字符效果**: 支持逐字符独立控制颜色渐变、发光、加粗、跳动等。
*   **多样化运动效果**: 实现水平/垂直滚动、整体/局部跳动、缩放、淡入淡出。
*   **高性能低延迟**: 优化渲染逻辑，避免每帧遍历所有字符，适合移动端。
*   **极致易用**: 提供 `Inspector` 面板直接配置效果，无需编写代码。

## 目录结构

```plaintext
TextFlow/
├── main.tscn               # 主演示场景
├── project.godot           # Godot 项目配置
├── src/                    # 核心逻辑源码
│   ├── text_flow_manager.gd  # 文本流动管理器 (核心控制器)
│   ├── text_character.gd     # 单个字符节点 (效果单元)
│   ├── effect.gd             # 效果基类 (可扩展)
│   └── editor_ui.gd          # 编辑器 UI 逻辑 (文本分段与配置)
├── fonts/                  # 字体资源 (建议放入 SourceHanSans.ttf 等中文字体)
├── effects/                # Shader 与特效预设
│   ├── glow.shader           # 发光 Shader
│   └── scroll.shader         # 滚动 Shader
└── export/                 # 导出配置与预设
```

## 快速开始

1.  **安装**: 克隆本项目到本地，使用 Godot 4.x 导入 `project.godot`。
2.  **配置字体**: 将你的字体文件（如 `.ttf`）放入 `fonts/` 目录。
3.  **运行**: 打开 `main.tscn` 运行场景，即可看到示例文本效果。

## 架构设计

### 1. TextFlowManager (核心管理器)
负责整个文本流的生命周期管理、全局效果调度和跨平台适配。
*   **功能**:
    *   接收 `editor_ui` 的输入，实例化 `TextCharacter`。
    *   统一管理 `AnimationPlayer`，避免大量节点各自 update 带来的性能损耗。
    *   处理窗口大小变化，适配移动端分辨率。

### 2. TextCharacter (字符单元)
每个字符都是一个独立的节点（继承自 `Label` 或 `Control`），拥有独立的状态。
*   **属性**:
    *   `text`: 字符内容
    *   `color` / `outline_color`: 基础与轮廓颜色
    *   `jump_intensity`: 跳动幅度
    *   `scroll_speed`: 滚动速度

### 3. EditorUI (配置界面)
允许用户在运行时或编辑器中输入文本，并对文本段落应用不同的效果预设。

## 扩展性

*   **Shader 效果**: 在 `effects/` 目录下编写新的 `.shader` 文件即可扩展视觉效果。
*   **3D 支持**: 架构预留了 `MeshInstance3D` 接口，未来可扩展至 3D 场景。
*   **音频联动**: 预留音频频谱分析接口，可实现文字随音乐跳动。

## 贡献

欢迎提交 PR 或 Issue！

---
