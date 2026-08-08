# Trigin6Quote · 每日六语录

> 每天六句精选语录，激励你不断前行。
> macOS 菜单栏常驻 · 主窗口沉浸阅读 · 内嵌公共聊天室

![macOS 14+](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.1--beta-yellow)

---

## ✨ 功能特性

- **每日六条精选语录** — 基于日期种子确定性生成，同一天内容稳定，次日自动刷新
- **多分类语录库** — 古典、现代、哲思、励志等多分类，支持分类筛选与全文搜索
- **收藏管理** — 一键收藏/取消，收藏数据持久化于 UserDefaults
- **菜单栏常驻** — `MenuBarExtra` 实现，点击图标即可预览今日语录、快速操作
- **内嵌聊天室** — 基于 WKWebView 内嵌公共聊天室（由 [Chatango](https://chatango.com) 提供），无需开浏览器即可交流
- **主窗口沉浸阅读** — `NavigationSplitView` 三栏布局：侧边栏 / 语录正文 / 详情
- **外观自适应** — 跟随系统深浅色，也可在设置中强制指定
- **字号调节** — 小 / 中 / 大 三档，实时生效
- **开机自启动** — 基于 `SMAppService.mainApp`（macOS 13+ 官方 API，沙盒兼容）
- **键盘快捷键** — `⌘R` 下一条 / `⌘L` 上一条 / `⌘F` 收藏 / `⌘⇧C` 复制 / `⌘0` 显示主窗口

## 📸 截图

浅色模式<img width="878" height="593" alt="截屏2026-08-08 14 01 59" src="https://github.com/user-attachments/assets/98dd2800-4dc9-4edf-b23d-7b1269733122" />

深色模式<img width="912" height="626" alt="截屏2026-08-08 14 02 06" src="https://github.com/user-attachments/assets/9bc86ec0-724c-4893-9fb8-3065550f8c8d" />

菜单栏窗口<img width="366" height="490" alt="截屏2026-08-08 14 02 12" src="https://github.com/user-attachments/assets/9788586f-d377-4cf8-8eb6-1b3ca558eddf" />

## 🚀 构建

### 方式一：SwiftPM 命令行（调试用）

```bash
git clone https://github.com/<your-username>/Trigin6Quote.git
cd Trigin6Quote
swift build
```

产物：`.build/debug/Trigin6Quote`（裸可执行文件，**非 `.app` 包**）。

### 方式二：生成 `.app` 包（推荐分发用）

```bash
swift build -c release
# 生成 .app 包结构
mkdir -p Trigin6Quote.app/Contents/MacOS
cp .build/release/Trigin6Quote Trigin6Quote.app/Contents/MacOS/
# 补 Info.plist 与图标（见下方模板）
```

最小 `Info.plist` 模板：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Trigin6Quote</string>
    <key>CFBundleIdentifier</key>
    <string>com.trigin.trigin6quote</string>
    <key>CFBundleVersion</key>
    <string>1.0.1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
```

### 方式三：Xcode（推荐开发用）

```bash
open Package.swift
```

Xcode 会识别 `Package.swift` 自动创建项目，`⌘R` 直接运行调试。

## 📁 项目结构

```
Trigin6Quote/
├── Package.swift                  # SwiftPM 清单
├── README.md
├── LICENSE
└── Trigin6Quote/
    ├── Trigin6QuoteApp.swift      # App 入口、Scene、AppDelegate
    ├── QuoteData.swift            # 语录数据库（内置数百条）
    ├── Models/
    │   └── Quote.swift            # 数据模型
    ├── Stores/
    │   └── QuoteStore.swift       # 状态管理（每日生成、收藏、字号缓存）
    ├── Support/
    │   ├── AppTheme.swift         # 主题配色（深浅色自适应）
    │   ├── ChatWebView.swift      # WKWebView 聊天室封装
    │   └── Date+Extensions.swift  # 日期工具（缓存 DateFormatter）
    └── Views/
        ├── ContentView.swift      # 主窗口根视图
        ├── SidebarView.swift      # 侧边栏
        ├── FavoritesView.swift    # 收藏 / 全部语录
        ├── MenuBarView.swift      # 菜单栏视图（语录预览 + 聊天室）
        ├── SettingsView.swift     # 设置面板
        └── Chat/
            └── ChatMainView.swift # 主窗口内聊天室视图
```

## 🎨 设计理念

- **米黄 + 冷白 / 深炭** 的克制配色，避免纯黑纯白的廉价感
- 衬线字体承载语录正文，无衬线字体承载 UI 文案，形成阅读层次
- `MenuBarExtra` 让应用常驻而不打扰，需要时一点即开

## ⚠️ 关于聊天室

本应用内嵌的聊天室由第三方服务 **Chatango** 提供，聊天室内容、稳定性、 moderation 均由 Chatango 平台负责，本项目不维护聊天室后端。请在聊天室内遵守相关法律法规，文明交流。

## 📝 版本

- **v1.0.1-beta** — 当前版本，功能完整但无测试覆盖，欢迎试用与反馈
- v1.0.0（计划）— 补充单元测试后发布稳定版

## 📜 版权

```
©️Trigin 2026
MIT License
```

本项目采用 [MIT License](./LICENSE) 开源。代码中的 `©️Trigin` 版权声明用于标识原作者，不影响 MIT 协议授予的使用、修改、分发权利。
