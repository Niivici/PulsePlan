# PulsePlan

PulsePlan 是一个基于 HarmonyOS NEXT / ArkTS 构建的原生高保真日程管理原型项目，面向“AI 个性化时间规划”场景，重点演示任务总览、课程表式周视图排程、自然语言 AI 编排、成就反馈与个人中心等核心体验。

项目当前以手机端单模块应用的形式实现，适合用于以下场景：

- HarmonyOS 原型演示与课程作业答辩
- AI 日程类产品的交互验证
- ArkTS 单页复杂状态界面开发参考
- 后续接入真实 AI 服务、系统情景能力和云端同步能力的基础工程

## 项目概览

- 应用名称：PulsePlan
- Bundle Name：`com.yangyx.pulseplan`
- Vendor：`yangyx`
- 版本号：`1.0.0`
- Version Code：`1000000`
- 目标平台：HarmonyOS
- 目标设备：`phone`
- 模块名称：`entry`
- SDK：`6.0.0(20)`

## 核心能力

### 1. 单页多分区信息架构

应用通过底部悬浮导航组织五个主分区：

- 概览：聚合当天重点、提醒与状态摘要
- 日程：支持日 / 周 / 月视图切换与时间安排
- AI：通过自然语言输入生成建议性排程
- 成就：展示完成反馈、激励信息与连续行为记录
- 我的：展示个人画像、模式快捷入口与设置区域

### 2. 课程表式周视图排程

项目内实现了较完整的可视化时间轴交互，用于模拟真实日程管理产品中的拖拽排程体验：

- 周视图时间轴布局
- 日程块展示与定位
- 拖拽调整任务时间位置
- 拉伸任务块以修改时长
- 冲突插队后的顺排演示

### 3. AI 编排演示流

AI 区域当前为原型级模拟流程，重点在交互表达而非真实模型接入：

- 接收自然语言目标输入
- 生成任务拆解与编排建议
- 在界面中回显建议流程和分配结果
- 支持进一步展示 AI 详情内容

### 4. 成就反馈与行为激励

项目提供了完成反馈、阶段成就和用户状态展示，用于模拟日程类产品中的轻激励机制，增强原型完整度。

## 界面与交互特点

- 原生 ArkTS 组件化实现，非 WebView 包壳
- 单页原型结构，状态集中、切换流畅
- 大量高保真业务组件已拆分为独立分区
- 适合继续演进为可维护的正式应用工程

## 技术栈

- HarmonyOS NEXT
- ArkTS
- DevEco Studio / hvigor 构建体系
- Hypium（已配置测试依赖）

## 目录结构

```text
PulsePlan/
├─ AppScope/                        # 应用级配置与全局资源
├─ entry/                           # 主业务模块
│  └─ src/main/ets/
│     ├─ common/                    # 通用常量、主题、工具方法
│     ├─ components/                # 业务组件
│     │  ├─ achievement/            # 成就模块
│     │  ├─ ai/                     # AI 编排与详情模块
│     │  ├─ base/                   # 通用基础组件
│     │  ├─ navigation/             # 底部悬浮导航
│     │  ├─ overview/               # 概览模块
│     │  ├─ profile/                # 个人中心模块
│     │  └─ schedule/               # 日程与时间轴模块
│     ├─ data/                      # 原型假数据与演示逻辑
│     ├─ entryability/              # 应用入口 Ability
│     ├─ entrybackupability/        # 备份扩展能力
│     ├─ models/                    # 数据模型定义
│     ├─ pages/                     # 页面入口包装
│     └─ prototype/                 # 原型主容器与页面编排
├─ Pproject/                        # 交付补充资料
│  ├─ UI设计稿/                      # 界面设计稿
│  ├─ 原型说明/                      # 原型说明文档
│  └─ 上线前评估与建设文档.md         # 上线前建设建议
├─ build-profile.json5             # 构建产品配置
├─ hvigorfile.ts                   # hvigor 构建入口
└─ oh-package.json5                # 工程包配置
```

## 关键代码入口

- 应用入口：`entry/src/main/ets/entryability/EntryAbility.ets`
- 页面入口：`entry/src/main/ets/pages/Index.ets`
- 原型主容器：`entry/src/main/ets/prototype/PulsePlanHome.ets`
- AI 主模块：`entry/src/main/ets/components/ai/AISection.ets`
- AI 详情模块：`entry/src/main/ets/components/ai/AIDetailSection.ets`
- 日程主模块：`entry/src/main/ets/components/schedule/ScheduleSection.ets`
- 周视图时间轴：`entry/src/main/ets/components/schedule/TimelineBoard.ets`

## 快速开始

### 环境要求

- DevEco Studio 6.x
- HarmonyOS SDK `6.0.0(20)`
- JBR / Java 环境（通常由 DevEco Studio 自带）

### 使用 DevEco Studio 运行

1. 使用 DevEco Studio 打开项目根目录 `D:\Work\Pproject_arkTS_codex`
2. 等待工程索引和 SDK 同步完成
3. 选择模拟器或真机设备
4. 运行 `entry` 模块

### 命令行构建

如果你已经在本机正确配置 DevEco Studio SDK、JBR 和 hvigor 环境，可以通过 DevEco Studio 安装目录中的 hvigor 启动脚本执行 HAP 构建，例如：

```powershell
<DevEco Studio 安装目录>\tools\hvigor\bin\hvigorw.bat assembleHap --no-daemon
```

更推荐的方式仍然是直接使用 DevEco Studio 打开并运行工程，这样可以避免本地环境变量差异带来的问题。

## 当前验证状态

已完成一次命令行构建验证，`assembleHap --no-daemon` 构建成功。

当前仍存在少量非阻塞告警，例如：

- 部分 `animateTo` API 已被标记为 deprecated
- `TimelineBoard.ets` 中存在 `Function.bind` 的 ArkTS 兼容性告警
- 个别 `onScroll` API 已被标记为 deprecated

这些问题不会阻止当前原型运行，但如果项目继续产品化，建议尽快替换为新版 API。

## 项目定位与边界

这是一个“高保真原型 + 工程化基础”项目，不是已经接入完整后端和系统能力的正式商用版本。当前版本更适合用于验证以下问题：

- 信息架构是否合理
- 时间轴交互是否可用
- AI 编排入口是否具备吸引力
- 成就体系是否能形成产品闭环

暂未完整接入的能力包括：

- 真实大模型服务
- 云端账户与多端同步
- 系统级情景模式能力
- 语音识别与语义理解
- 持久化排程数据存储

## 后续演进建议

- 将页面级状态进一步下沉到独立 store 或 view model
- 为周视图增加更稳定的冲突检测、吸附和落点校正
- 抽象 AI 编排服务接口，便于替换成本地 mock 或远程模型
- 为日程、概览、成就模块补充统一的数据流与状态管理
- 增加自动化测试与关键交互回归测试
- 补充应用截图、演示 GIF 和版本发布记录

## 适合继续补充的 README 内容

如果你后续准备把这个仓库作为公开展示项目，建议继续增加：

- 实际运行截图
- 功能演示视频
- 产品背景与目标用户说明
- 设计稿预览图
- Roadmap 与版本计划
- License 信息

## License

当前仓库未声明正式开源许可证。如需公开开源，建议补充 `LICENSE` 文件并在 README 中明确授权方式。
