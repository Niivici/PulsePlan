# PulsePlan Java 后端

需要 JDK 17、Maven 和 PostgreSQL。服务默认监听 8080，首次连接时由 Flyway 创建数据库表。先在 PostgreSQL 中创建数据库和拥有该库权限的应用账号，再给服务进程配置环境变量。

| 变量 | 用途 |
| --- | --- |
| `PULSEPLAN_DB_URL` | JDBC 地址，默认 `jdbc:postgresql://localhost:5432/pulseplan`。 |
| `PULSEPLAN_DB_USERNAME` | 数据库账号，默认 `pulseplan`。 |
| `PULSEPLAN_DB_PASSWORD` | 数据库密码。 |
| `PULSEPLAN_ADMIN_USERNAME`、`PULSEPLAN_ADMIN_PASSWORD` | 首次启动时初始化唯一管理员。留空时可以启动并注册普通账号。 |
| `DEEPSEEK_API_KEY` | 模型调用密钥，从服务端环境读取。 |
| `PULSEPLAN_AI_DAILY_ACCOUNT_LIMIT` | 每个账号的每日 AI 生成次数，默认 10。 |
| `PULSEPLAN_AI_DAILY_GLOBAL_LIMIT` | 全站每日 AI 生成次数，默认 100。 |
| `PULSEPLAN_AI_MODEL` | 模型 ID，默认 `deepseek-v4-pro`。 |
| `PULSEPLAN_AI_URL` | Chat Completions 完整地址，默认 `https://api.deepseek.com/chat/completions`。 |

从仓库根目录运行：

```powershell
mvn -f server/pom.xml test
mvn -f server/pom.xml spring-boot:run
Invoke-RestMethod http://localhost:8080/api/v1/health
```

默认测试使用 H2 的 PostgreSQL 兼容模式和本地模拟 DeepSeek 服务。设置 `PULSEPLAN_TEST_DB_URL`、`PULSEPLAN_TEST_DB_USERNAME` 和 `PULSEPLAN_TEST_DB_PASSWORD` 可让 `AccountEndpointTest` 使用专用 PostgreSQL 测试库。测试会向该库写入测试账号和日程。

AI 配额按 UTC 自然日计算。请求向模型发出前扣减配额，模型失败或超时的请求也计入。确认已有草案不会消耗配额。

## HarmonyOS 联调

1. 在 DevEco Studio 打开仓库根目录，使用 HarmonyOS SDK 6.0.0（API 20）运行 `entry` 模块。
2. 在登录页填入手机或模拟器可访问的后端地址。局域网真机可填开发电脑的局域网地址，例如 `http://192.168.1.10:8080`。正式环境使用 HTTPS。
3. 注册并登录，新增一个日程，拖动并修改时长，添加提醒，然后标记完成。在成就页检查完成统计，在个人中心保存显示名称和时区。退出后重新登录，确认数据可读取。
4. 配置模型密钥并重启后端。在 AI 页输入目标，检查预览中的日期和时间。确认后切换到日程页，核对保存结果。
5. 使用另一账号登录，确认上一个账号的日程不可见。

联调版提醒会保存并显示在日程页，系统通知待接入。客户端使用 HarmonyOS Asset Store 保存有效登录会话，退出时清除。紧急排程使用 AI 建议寻找空闲时段，原型中的自动顺排保留在本地演示模式。

[API 规格与验收项](../docs/backend-v1-spec.md)
