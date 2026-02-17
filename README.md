# QuickSearch-AHK 🚀

**QuickSearch-AHK** 是基于 **AutoHotkey v2.0** 的多引擎搜索增强工具。通过“复制连击”触发批量检索，将跨平台查询压缩为一次动作，适合高频检索与 AI 协作场景。

---


<img width="403" height="719" alt="image" src="https://github.com/user-attachments/assets/e8c3f7d3-0549-4b31-8d3b-7f49e8ad2c0c" />


## ✨ 核心特性（v1.0）

* **双击触发 (`Double Ctrl+C`)**
  选中文本后双击 `Ctrl+C`，静默执行当前勾选的全部引擎。

* **可勾选式引擎控制面板 (`Ctrl+Alt+S`)**
  通过复选框自由组合搜索平台，支持批量执行。

* **Claude 支持新增**
  新增对 Claude 的自动化适配。

* **AI 自动投递机制**
  对 DeepSeek、ChatGPT、Gemini、Claude 自动粘贴并回车，直达对话输入。

* **长文本智能过滤**
  当文本长度超过 30 字符时，自动跳过 Baidu 与 Bilibili，避免无效检索。

* **纯内存配置模型**
  移除持久化设置。所有状态仅在当前运行周期内有效，结构更简洁。

* **统一搜索流程架构**
  所有触发路径共享同一执行管线，逻辑更清晰，可维护性更强。

---

## ⌨️ 快捷键说明

| 快捷键                  | 功能            |
| :------------------- | :------------ |
| **`Ctrl + C`（双击）**   | 静默执行当前勾选的全部引擎 |
| **`Ctrl + Alt + S`** | 打开控制面板        |
| **`Enter`**          | 执行当前勾选引擎      |
| **`Esc`**            | 关闭面板 / 搜索中断任务 |

---

## 🛠️ 支持的引擎

* **综合搜索**：Baidu
* **人工智能**：DeepSeek、ChatGPT、Gemini、Claude
* **内容搜索**：Bilibili

所有引擎均可独立勾选，自由组合执行。

---

## 🚀 安装与使用

### 前置要求

* Windows 10 / 11
* 已安装 AutoHotkey v2.0+

### 运行方式

1. 下载 `QuickSearch.ahk`
2. 双击运行
3. 选中文本，双击 `Ctrl+C` 即可触发多引擎检索

---

## ⚙️ 架构说明（v1.0 变化）

* 移除 INI 持久化机制
* 移除“自动闪回原窗口”功能
* 改为复选框批量执行模式
* 执行逻辑统一为单一 SearchFlow
* GUI 宽度与输入框高度优化

---

## 📄 License

MIT License
