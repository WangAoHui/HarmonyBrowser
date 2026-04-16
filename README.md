# HarmonyOS Browser

基于鸿蒙 ArkWeb 内核构建的轻量级浏览器应用。

## 功能特性

- 网页浏览：基于 ArkWeb 内核，支持 JavaScript、DOM Storage、缓存等
- 地址栏：自动识别 URL / 搜索关键词，支持 HTTPS 安全标识
- 导航控制：前进、后退、刷新、停止加载、回到主页
- 加载进度条：实时显示页面加载进度

### 书签管理
- 一键收藏/取消收藏当前页面
- 书签列表展示（标题、URL、收藏时间）
- 书签搜索
- 单条删除书签
- 点击书签直接跳转访问

### 历史记录
- 自动记录所有访问页面
- 按日期分组（今天、昨天、具体日期）
- 显示访问次数
- 历史记录搜索
- 单条删除 / 一键清空
- 最多保留 500 条记录

### 隐私与数据管理
- 清除浏览数据（全部数据一键清除）
- 清除网页缓存
- 清除所有 Cookie
- 清除历史记录
- 清除所有书签
- 所有操作均有确认弹窗，防止误操作

## 项目结构

```
HarmonyBrowser/
├── AppScope/
│   ├── app.json5                          # 应用全局配置
│   └── resources/base/element/string.json # 应用级字符串资源
├── entry/
│   ├── build-profile.json5                # 模块构建配置
│   ├── oh-package.json5                   # 模块包配置
│   ├── hvigorfile.ts                      # 构建脚本
│   └── src/main/
│       ├── module.json5                   # 模块配置（权限、Ability、页面路由）
│       ├── ets/
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets       # 应用入口 Ability
│       │   ├── model/
│       │   │   └── BrowserData.ets        # 数据模型（BookmarkItem, HistoryItem）
│       │   ├── common/
│       │   │   ├── DataManager.ets        # 数据持久化管理器（Preferences）
│       │   │   └── CookieManager.ets      # Cookie 管理器 + Web 数据清除工具
│       │   └── pages/
│       │       ├── Index.ets              # 主浏览器页面（ArkWeb + 地址栏 + 工具栏）
│       │       ├── BookmarkPage.ets       # 书签管理页面
│       │       ├── HistoryPage.ets        # 历史记录页面
│       │       └── SettingsPage.ets       # 设置页面（数据清除）
│       └── resources/base/
│           ├── element/
│           │   ├── string.json            # 字符串资源
│           │   └── color.json             # 颜色资源
│           └── profile/
│               └── main_pages.json        # 页面路由配置
├── build-profile.json5                    # 项目构建配置
└── hvigorfile.ts                          # 项目构建脚本
```

## 技术栈

| 技术 | 用途 |
|------|------|
| ArkTS | 开发语言（TypeScript 扩展） |
| ArkWeb | Web 浏览引擎 |
| Preferences | 轻量级键值对数据持久化 |
| WebCookieManager | Cookie 管理 |
| WebviewController | Web 组件控制器 |

## 开发环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK API 12+
- 支持设备：Phone / Tablet

## 构建与运行

1. 使用 DevEco Studio 打开项目
2. 连接 HarmonyOS 设备或启动模拟器
3. 点击 Run 运行项目

## 权限说明

- `ohos.permission.INTERNET` — 网络访问权限（加载网页必需）

## License

MIT
