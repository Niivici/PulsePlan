# PulsePlan ArkTS 原型说明

## 1. 原型定位
本次交付基于鸿蒙 ArkTS 单页原型重构，目标是把“AI 个性化日程规划 + 生活记录”从概念快速落到可演示、可继续开发的手机产品骨架。

## 2. 当前完成范围
- 五段悬浮导航：概览、日程、AI、成就、我的。
- 日程模块支持日 / 周 / 月三视图切换，默认周视图。
- 周视图采用课程表式排布，保留日程块拖拽与拉伸时长微调。
- 事件块、日程块、提醒三层数据结构已独立建模。
- AI 一键编排、应急插入、执行直达、场景模式、成就反馈均已做 Demo 级交互。
- 所有主要中文文案已按 UTF-8 写入。

## 3. 代码结构
### ArkTS 主体
- `entry/src/main/ets/prototype/PulsePlanHome.ets`：单页原型状态容器。
- `entry/src/main/ets/components/navigation/FloatingNavBar.ets`：悬浮导航。
- `entry/src/main/ets/components/schedule/*`：日程区组件，包括周视图、月历、日程块卡片。
- `entry/src/main/ets/components/overview/*`：概览区组件。
- `entry/src/main/ets/components/ai/AISection.ets`：AI 能力展示区。
- `entry/src/main/ets/components/achievement/AchievementSection.ets`：成就反馈区。
- `entry/src/main/ets/components/profile/ProfileSection.ets`：个人中心区。
- `entry/src/main/ets/common/*`：主题、常量、模型、日期工具。
- `entry/src/main/ets/data/PulsePlanSeed.ets`：原型假数据与 AI 拆分逻辑。

### 交付目录
- `Pproject/UI设计稿/pulseplan_ui_board.html`：可展示 UI 设计稿。
- `Pproject/原型说明/ArkTS_原型说明.md`：原型说明与后续开发建议。

## 4. 真实开发时仍需补齐
- 系统级情景模式能力接入。
- 语音识别、用户画像服务、提醒服务、云同步服务。
- 分布式软总线与手机 / 手表数据协同。
- 真实埋点、账号体系、数据持久化。

## 5. 推荐后续开发顺序
1. 先把 `PulsePlanHome` 中的状态继续下沉到 store 或 view model。
2. 为周视图拖拽补充冲突检测与自动吸附策略。
3. 接入本地持久化，先保存事件块与视图偏好。
4. 把 AI 编排逻辑替换为服务端接口或端侧模型能力。
5. 最后补齐手表提醒、场景模式和数据分析。
