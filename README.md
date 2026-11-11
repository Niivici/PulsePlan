# PulsePlan · 日程助手

PulsePlan 是一款面向 HarmonyOS 手机的日程助手。你可以查看当天的重点和提醒，在日历上调整时间安排，也可以用一句话描述目标，体验任务拆解和排程建议。

这里是 PulsePlan 的产品源码仓库。仓库包含 HarmonyOS 客户端和 Java 后端，支持账号、日程、提醒配置和 AI 排程的接口联调。

## 当前可以体验

| 功能 | 体验内容 |
| --- | --- |
| 今日概览 | 查看当天重点、日程和提醒。 |
| 日历排程 | 切换日、周、月视图，在周时间轴拖动日程块调整时间，或拉伸日程块修改时长。 |
| AI 排程 | 输入自然语言目标，预览 DeepSeek 生成的排程建议，确认后写入个人日历。 |
| 成就与个人中心 | 查看个人完成统计，保存显示名称与时区。 |

登录服务后，账号与日程数据由 PostgreSQL 保存。也可以从登录页打开本地演示。真实 AI 排程需要在后端配置 DeepSeek 密钥。

[查看 UI 设计稿](Pproject/UI设计稿/pulseplan_ui_board.html) · [查看原型说明](Pproject/原型说明/ArkTS_原型说明.md)

## 本地运行

需要 DevEco Studio 6.x 和 HarmonyOS SDK 6.0.0（API 20）。

1. 克隆仓库。

   ```bash
   git clone https://github.com/Niivici/PulsePlan.git
   ```

2. 用 DevEco Studio 打开克隆得到的 `PulsePlan` 根目录，等待工程同步。Windows 上请使用纯英文路径，例如 `D:\Projects\PulsePlan`，避免 Hvigor 拒绝包含中文的父目录。
3. 选择 HarmonyOS 手机模拟器或已连接的真机，运行 `entry` 模块。使用真机时，按 DevEco Studio 的提示完成签名配置。

[启动 Java 后端与联调](server/README.md)

## 源码导航

| 位置 | 内容 |
| --- | --- |
| [AppScope](AppScope/) | 应用级配置与资源。 |
| [entry](entry/) | HarmonyOS 客户端模块，使用 ArkTS 和 ArkUI。 |
| [PulsePlanHome.ets](entry/src/main/ets/prototype/PulsePlanHome.ets) | 主界面、导航和页面状态。 |
| [业务组件](entry/src/main/ets/components/) | 概览、日程、AI 排程演示、成就和个人中心。 |
| [PulsePlanSeed.ets](entry/src/main/ets/data/PulsePlanSeed.ets) | 示例数据和排程演示逻辑。 |
| [server](server/) | Java 后端、数据库迁移和 HTTP 集成测试。 |
| [Pproject](Pproject/) | UI 设计稿、原型说明和上线前评估。 |

## 许可证

仓库尚未声明项目源码的开源许可证。
