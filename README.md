# 🎬 uosc MediaInfo 视频技术标签模块

<!-- 第一行：社交互动核心指标 -->
[![GitHub stars](https://img.shields.io/github/stars/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/forks)
[![GitHub watchers](https://img.shields.io/github/watchers/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/watchers)

<!-- 第二行：项目数据徽章 -->
[![GitHub Repo stars](https://img.shields.io/github/stars/yosh-wang/uosc-mediainfo?style=flat-square)](https://github.com/yosh-wang/uosc-mediainfo/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/yosh-wang/uosc-mediainfo?style=flat-square)](https://github.com/yosh-wang/uosc-mediainfo/forks)
[![GitHub issues](https://img.shields.io/github/issues/yosh-wang/uosc-mediainfo?style=flat-square)](https://github.com/yosh-wang/uosc-mediainfo/issues)
[![GitHub watchers](https://img.shields.io/github/watchers/yosh-wang/uosc-mediainfo?style=flat-square)](https://github.com/yosh-wang/uosc-mediainfo/watchers)
[![GitHub contributors](https://img.shields.io/github/contributors/yosh-wang/uosc-mediainfo?style=flat-square)](https://github.com/yosh-wang/uosc-mediainfo/graphs/contributors)
[![GitHub license](https://img.shields.io/github/license/yosh-wang/uosc-mediainfo?style=flat-square)](https://github.com/yosh-wang/uosc-mediainfo/blob/main/LICENSE)

<!-- 第三行：版本发布与下载统计 -->
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/releases/latest)
[![GitHub tag](https://img.shields.io/github/v/tag/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/tags)
[![GitHub release date](https://img.shields.io/github/release-date/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/releases)
[![GitHub downloads (latest)](https://img.shields.io/github/downloads/yosh-wang/uosc-mediainfo/latest/total)](https://github.com/yosh-wang/uosc-mediainfo/releases/latest)
[![GitHub downloads](https://img.shields.io/github/downloads/yosh-wang/uosc-mediainfo/total)](https://github.com/yosh-wang/uosc-mediainfo/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/yosh-wang/uosc-mediainfo/blob/main/LICENSE)

<!-- 第四行：提交活动与贡献者 -->
[![GitHub last commit](https://img.shields.io/github/last-commit/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/commits/main)
[![GitHub commit activity (monthly)](https://img.shields.io/github/commit-activity/m/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/commits/main)
[![GitHub commit activity (weekly)](https://img.shields.io/github/commit-activity/w/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/commits/main)
[![GitHub commit activity (yearly)](https://img.shields.io/github/commit-activity/y/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/commits/main)
[![GitHub contributors](https://img.shields.io/github/contributors/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/graphs/contributors)
[![GitHub contributors (anon)](https://img.shields.io/github/contributors-anon/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo/graphs/contributors)

<!-- 第五行：代码信息与技术栈 -->
[![GitHub top language](https://img.shields.io/github/languages/top/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo)
[![GitHub language count](https://img.shields.io/github/languages/count/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo)
[![GitHub repo size](https://img.shields.io/github/repo-size/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo)
[![GitHub code size](https://img.shields.io/github/languages/code-size/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo)
[![GitHub file count](https://img.shields.io/github/directory-file-count/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo)
[![Lines of Code](https://img.shields.io/tokei/lines/github/yosh-wang/uosc-mediainfo)](https://github.com/yosh-wang/uosc-mediainfo)

<!-- 第六行：自定义静态徽章 -->
![Status](https://img.shields.io/badge/Status-Stable-brightgreen)
![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen)
![MPV](https://img.shields.io/badge/MPV-Player-blue)
![Language](https://img.shields.io/badge/Language-Lua-red)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![Translation](https://img.shields.io/badge/Translation-100%25-brightgreen)
![Chinese](https://img.shields.io/badge/语言-中文-red)

🎬 **为 [uosc](https://github.com/tomasklaen/uosc) 播放器界面添加视频/音频技术参数标签**

在播放器左下角（控制栏上方）实时显示当前媒体的编码、分辨率、HDR、音频等信息。

**完全独立模块 · 不修改 uosc 核心代码 · 更新 uosc 时只需复制模块代码**

---

## 📖 项目简介

| 项目 | 信息 |
|------|------|
| 适用脚本 | uosc |
| 当前版本 | v1.0.0 |
| 兼容 uosc 版本 | 5.12.0+ |
| 配置文件 | `script-opts/mediainfo.conf` |
| 语言 | 中文 (简/繁) / 英文 |

---

## ✨ 功能特性

### 1. 完整的技术参数覆盖

模块自动从当前播放的媒体文件中提取并显示以下技术参数：

| 类别 | 显示内容 | 示例 |
|------|----------|------|
| 🎬 **解码方式** | 硬解 / 软解 | `硬解` |
| 🌈 **HDR 类型** | SDR / HDR10 / HDR10+ / HLG / Dolby Vision (P5/P7/P8) / HDR Vivid | `HDR10+` |
| 📹 **视频编码** | AVC / HEVC / AV1 / VP9 | `HEVC` |
| 📺 **分辨率等级** | 8K UHD / 4K UHD / 2K QHD / 1080P / 720P | `4K UHD` |
| ⚡ **帧率** | 整数 FPS | `60FPS` |
| 🔊 **音频声道** | 7.1 环绕声 / 5.1 环绕声 / 2.0 立体声 / 1.0 单声道 | `5.1 环绕声` |
| 🎵 **音频编码** | AAC / FLAC / DTS / DTS-HD / TrueHD / E-AC3 / Dolby Digital / Opus / MP3 / PCM / Audio Vivid | `DTS-HD` |

---

### 2. 智能识别国产影音标准

#### 🎬 HDR Vivid（菁彩影像）自动识别

- 通过 `ffprobe` 深度检测视频帧的 `side_data` 是否包含 Vivid 标记
- 支持格式：`.mp4` / `.mkv` / `.ts` / `.webm` / `.hevc`
- 自动显示为 **`HDR Vivid (菁彩影像)`**

#### 🎵 Audio Vivid（菁彩音频）自动识别

- 检测音轨标题或编码名称中的 `AV3A` / `Audio Vivid` 关键词
- 自动显示为 **`Audio Vivid 菁彩音频`**

---

### 3. 智能高亮渐变背景

以下标签会自动显示**渐变彩色背景**，视觉上突出重点信息：

- 🔥 **HDR 类**：Dolby Vision / HDR Vivid / HDR10+
- 📺 **高分辨率**：4K UHD / 8K UHD
- 🎵 **高品质音频**：TrueHD / DTS-HD

**内置 17 种渐变主题可选**，也支持手动调色自定义。

---

### 4. 非侵入式设计，易于同步更新

- **不修改 uosc 核心代码** — 纯追加模块，零侵入
- **更新 uosc 时只需复制模块代码** — 从旧版 `main.lua` 末尾复制模块代码，粘贴到新版末尾即可
- **独立配置体系** — 使用 `script-opts/mediainfo.conf` 单独管理，不依赖 uosc 的 `opt.read_options()`

---

### 5. 性能优化

- **标签数据缓存 5 秒** — 避免频繁读取 mpv 属性，降低性能开销
- **自适应缩放** — 随窗口大小自动调整标签尺寸，在高 DPI 显示下依然清晰
- **响应式显隐** — 随控制栏一同显示/隐藏，自然融入 uosc 交互逻辑
- **零额外资源占用** — 仅在视频播放时工作，空闲时自动停止

---

### 6. 跨平台支持

- ✅ **Windows** (mpv.exe)
- ✅ **macOS**
- ✅ **Linux**

`ffprobe` 自动查找路径：
1. 环境变量 `FFPROBE_PATH`
2. mpv 配置目录
3. mpv 可执行文件目录 (Windows)
4. 脚本目录
5. 系统 PATH

---

## ⚙️ 可选设置与用户体验特性

### 1. 视频开始时自动显示标签

播放视频时，标签会自动显示并停留一段时间，帮助用户快速了解当前视频的技术参数。

- **默认显示 5 秒**后自动淡出
- **可自定义显示时长**（`mediainfo_initial_display`）
- **平滑淡出动画**，不突兀

```ini
# 视频开始时自动显示 5 秒，0 为关闭此功能
mediainfo_initial_display=5
```

---

### 2. 随控制栏联动显隐

标签**锚定在控制栏上方**，与控制栏联动显示/隐藏：

- 控制栏出现 → 标签自动出现
- 控制栏隐藏 → 标签自动隐藏
- 鼠标移入/移出控制栏区域 → 标签平滑淡入/淡出
- 支持 uosc 的 `toggle-ui` 快捷键（默认 `t` 键）一键切换

**自然融入 uosc 交互逻辑，无需额外学习成本。**

---

### 3. 自适应缩放

标签尺寸**随窗口大小自动调整**，在不同分辨率下都能清晰显示：

- 窗口模式 / 全屏模式自动适配
- 支持高 DPI 屏幕
- 可调节缩放强度（`mediainfo_scale_intensity`）

```ini
# 缩放强度 (0.0=不缩放, 0.5=半缩放, 1.0=完全跟随窗口)
mediainfo_scale_intensity=0.30
```

---

### 4. 完全可定制的显示样式

所有外观参数均可通过 `mediainfo.conf` 独立配置，无需修改 `main.lua`：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `mediainfo_font_size` | 字体大小 | 12 |
| `mediainfo_y_offset` | 距离控制栏的偏移量 | 23 |
| `mediainfo_gap` | 标签之间的间距 | 5 |
| `mediainfo_x_padding` | 标签左右内边距 | 6 |
| `mediainfo_y_padding` | 标签上下内边距 | 3 |
| `mediainfo_theme` | 渐变主题（17 种可选） | bbblurry |
| `mediainfo_scale_intensity` | 缩放强度 | 0.30 |

---

### 5. 一键开关

可通过 uosc 的 `disable-elements` 配置或脚本消息随时启用/禁用标签：

```lua
-- 通过脚本消息禁用
mp.commandv('script-message-to', 'uosc', 'disable-elements', 'mediainfo', 'mediainfo')

-- 通过脚本消息启用 (传空字符串)
mp.commandv('script-message-to', 'uosc', 'disable-elements', 'mediainfo', '')
```

---

### 6. 智能缓存，性能友好

- **标签数据缓存 5 秒**，避免频繁读取 mpv 属性
- 切换音轨时**自动刷新缓存**，确保显示最新数据
- 文件切换时**自动重置缓存**，避免显示旧文件信息
- **不影响播放性能**，即使在 8K 高码率视频下也流畅运行

---

### 7. 多语言支持

- 标签文本为**中文显示**，清晰易懂
- 内置技术术语专业翻译（HDR Vivid / Audio Vivid / 环绕声等）
- 兼容 uosc 的 `languages` 配置

---

### 8. 零配置开箱即用

- 安装后**默认即显示**（`mediainfo_enabled=yes`）
- 无需额外依赖（ffprobe 为可选，仅用于 HDR Vivid 识别）
- 与 uosc 其他功能**无冲突**

---

## 📸 预览效果

```
[硬解] [SDR] [AVC] [4K UHD] [25FPS] [2.0 立体声] [AAC]
```

- 普通标签：简洁的深色半透明背景
- **高亮标签**：渐变彩色背景，视觉突出

---

## 💬 适用场景

| 场景 | 说明 |
|------|------|
| **影音发烧友** | 快速确认当前播放视频的画质和音质规格 |
| **HDR 内容鉴赏** | 一目了然识别 HDR 类型（HDR10/HDR10+/Dolby Vision/HDR Vivid） |
| **多音轨切换** | 直观看到当前音轨的编码格式和声道数 |
| **硬件解码验证** | 确认硬解是否生效，排查播放卡顿问题 |
| **视频质量评估** | 快速了解分辨率、帧率、编码等核心参数 |

---

## 📥 安装

### 文件结构

```
portable_config/
├── scripts/
│   └── uosc/
│       └── main.lua          ← 添加 MediaInfo 模块代码
├── script-opts/
│   └── mediainfo.conf        ← 配置文件
└── mpv.conf
```

### 安装步骤

1. **下载 `mediainfo.conf`** 放到 `portable_config/script-opts/` 目录
2. **将 MediaInfo 模块代码** 粘贴到 `scripts/uosc/main.lua` 末尾
3. **（可选）确保 ffprobe 可用** — 模块会自动查找以下位置：
   - 环境变量 `FFPROBE_PATH`
   - mpv 配置目录
   - mpv 可执行文件目录 (Windows)
   - 脚本目录
   - 系统 PATH

### 更新 uosc 时保留此模块

1. 下载新版 uosc，覆盖 `main.lua`
2. 打开旧版 `main.lua`，复制末尾的 MediaInfo 模块代码
3. 粘贴到新版 `main.lua` 末尾
4. 保存，完成

> **模块代码从 `-- ============================================================` 开始到文件结尾。**

---

## ⚙️ 配置项完整清单

```ini
# ==========================================
# 全局开关
# ==========================================
mediainfo_enabled=yes                    # 启用/禁用标签
mediainfo_initial_display=5              # 视频开始时自动显示秒数 (0=关闭)

# ==========================================
# 尺寸配置
# ==========================================
mediainfo_font_size=12                   # 字体大小
mediainfo_y_offset=23                    # 距离控制栏偏移 (越大越靠上)
mediainfo_gap=5                          # 标签间距
mediainfo_x_padding=6                    # 左右内边距
mediainfo_y_padding=3                    # 上下内边距

# ==========================================
# 缩放配置
# ==========================================
mediainfo_scale_intensity=0.30           # 缩放强度 (0.0~1.0)

# ==========================================
# 渐变主题 (高亮标签背景)
# ==========================================
# 可选主题:
# bbblurry / lavender / amethyst / sapphire / midnight
# crimson / magenta / amber / gold / bubblegum
# blush / coral / plasma / electric / autumn / rust / aurora
# custom (手动调色)
mediainfo_theme=bbblurry

# ==========================================
# 手动调色 (仅当 theme=custom 时生效)
# ==========================================
mediainfo_gradient_base=090916           # 底色
mediainfo_gradient_c1=6419a9             # 椭圆1
mediainfo_gradient_c2=710a44             # 椭圆2
mediainfo_gradient_c3=693bb5             # 椭圆3
mediainfo_gradient_c4=4ea3d5             # 椭圆4

# ==========================================
# 普通标签背景色
# ==========================================
mediainfo_color_hwdec=000000             # 解码方式
mediainfo_color_codec=000000             # 视频编码
mediainfo_color_res=000000               # 分辨率
mediainfo_color_fps=000000               # 帧率
mediainfo_color_audio_layout=000000      # 音频声道
mediainfo_color_audio_codec=000000       # 音频编码
```

---

## 🔧 技术特点

| 特点 | 说明 |
|------|------|
| **完全独立模块** | 代码位于 `main.lua` 末尾，与 uosc 核心隔离 |
| **独立配置体系** | 使用 `script-opts/mediainfo.conf` 单独管理，不依赖 `opt.read_options()` |
| **性能优化** | 标签数据缓存 5 秒，避免频繁读取属性 |
| **自适应缩放** | 随窗口大小自动调整标签尺寸 |
| **响应式显隐** | 随控制栏一同显示/隐藏，自然融入 uosc 交互逻辑 |

---

## 📜 许可证

本项目基于 **MIT License** 开源协议发布。

详见 [LICENSE](LICENSE) 文件。

---

## 🙏 致谢

- [uosc](https://github.com/tomasklaen/uosc) — 优秀的 mpv 界面脚本
- [dyphire](https://github.com/dyphire) — 配置参考
- 所有使用和反馈本模块的朋友们

---

**由 [yosh-wang](https://github.com/yosh-wang) 用 ❤️ 制作**

⭐ 如果这个项目对您有帮助，请给一个 Star 支持一下！
