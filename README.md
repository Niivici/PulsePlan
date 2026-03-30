# PulsePlan

HarmonyOS / ArkTS 原生高保真单页原型，聚焦 AI 个性化日程编排、课程表式周视图拖拽排程、情景模式直达与成就反馈。

## 当前已实现

- 五段悬浮导航：概览、日程、AI、成就、我的
- 日 / 周 / 月三种时间视图，共用同一份日程数据源
- 周视图课程表式时间轴与日程块拖拽、拉伸调整时长
- 自然语言输入后的一键 AI 拆解编排 Demo
- 应急插队后自动顺排同日冲突事项
- 执行直达、情景模式启动、完成反馈与提醒预览
- `Pproject` 交付目录中的 UI 设计稿与原型说明

## 工程结构

- `AppScope/`: 应用级配置与资源
- `entry/src/main/ets/prototype/PulsePlanHome.ets`: 单页原型状态容器
- `entry/src/main/ets/components/`: 组件化内容区与基础组件
- `entry/src/main/ets/common/`: 主题、模型、日期与排程工具
- `entry/src/main/ets/data/`: 原型假数据与 AI 编排逻辑
- `entry/src/main/ets/pages/Index.ets`: 入口包装页
- `Pproject/UI设计稿/`: 可展示设计稿
- `Pproject/原型说明/`: 交付说明文档

## 运行方式

1. 使用 DevEco Studio 打开当前目录 `D:\Work\Pproject_arkTS_codex`
2. 等待 HarmonyOS SDK / hvigor 依赖同步完成
3. 选择手机模拟器或真机运行 `entry` 模块

## MVP 说明

- 手机为主运行端，手表协同、情景模式、语音录入当前为原型级模拟
- 真正上线还需要接入：系统级情景 API、分布式任务迁移、语音识别、云端用户画像与模型服务
- 当前版本重点证明：单页导航、周视图拖拽、AI 编排和成就反馈可以在 ArkTS 中落成可继续开发的原型

## 已知限制

- 当前环境缺少可直接调用的 `hvigor` / `ohpm` 命令，因此未能在命令行内完成最终编译校验
- 已完成导入路径静态校验，新增 ArkTS 文件引用链完整

## 后续建议

- 将 `PulsePlanHome` 的状态继续下沉到 store 或 view model
- 为周视图拖拽增加冲突检测、自动吸附和持久化存储
- 接入手表运动睡眠数据，驱动 AI 习惯学习
- 抽象 AI 编排服务接口，便于后续连接真实模型
