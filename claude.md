# Claude Execution Brief — `new-api` + `Allergy` Integration

日期：2026-04-13

## 1. 使用方式

在这个工作区执行任务前，先读这 4 个文件：

1. `./claude.md`
2. `./new-api-allergy-integration-design.md`
3. `./new-api-allergy-data-model-draft.md`
4. `./new-api-allergy-api-draft.md`

如果要修改 `new-api/` 内部代码，还必须遵守：

- `./new-api/CLAUDE.md`

注意：

- 当前文件系统大小写不敏感，`claude.md` 和 `CLAUDE.md` 视为同一个文件

## 2. 开发方法

### 2.1 必须采用 TDD

本工作区的实现默认采用 TDD，除非用户明确要求跳过。

执行顺序必须尽量遵循：

1. 先写测试
2. 先看到测试失败
3. 再写最小实现让测试通过
4. 最后再做必要重构

要求：

- 不要先写大段业务代码再补测试
- 每完成一个小功能点，都应有对应测试或可重复验证
- 优先写小而明确的测试，不要一开始就堆超大集成测试

### 2.2 测试优先级

优先保证这些部分有测试：

- 用户名 / 邮箱 + 密码登录流程
- 注册时邮箱验证流程
- 找回密码与重置密码流程
- 订单创建与支付状态流转
- 支付回调后的订单状态更新
- 报告权限校验
- PDF 预览 / 下载权限
- 报告补发邮件的约束与审计
- 时间线事件写入

### 2.3 测试策略

后端：

- 优先为 `new-api` 的 controller / service / model 改动补 Go 测试
- 涉及状态流转时，优先测试业务规则，不要只测 HTTP 200

前端：

- 如果只是小型页面接线，优先补组件逻辑测试或 API 层测试
- 如果当前前端缺少测试基础设施，可以先补最小可用测试能力，再继续实现

### 2.4 完成一个步骤时必须做的事

每做完一个子任务，至少完成：

- 相关测试通过
- 没有破坏已有测试
- 记录本次改动影响的接口或状态流转

## 3. 工具与技能

### 3.1 开工前先检查工具

在开始实现前，先检查当前环境是否具备完成任务所需的工具。

至少要确认：

- 代码搜索和编辑工具可用
- Go 测试工具可用
- 前端包管理和构建工具可用
- 需要的浏览器或页面验证工具可用
- 需要的 MCP skills 可用

### 3.2 必要时先安装工具，不要硬写代码

如果某一步明确依赖工具，而工具不存在，不要跳过，也不要假装已经验证过。

应该先安装或启用必要工具，再继续实现。

### 3.3 明确提到的工具

如果任务需要，优先检查并使用这些工具：

- `everything-claude-code`
- 与当前任务相关的 MCP skills

这里的原则是：

- 如果工具存在，优先利用它提升搜索、验证和执行效率
- 如果工具缺失，而任务明显依赖它，就先安装
- 如果安装失败或环境不支持，要明确说明缺少什么，不要无依据继续

### 3.4 当前工作区推荐使用的技能

根据任务类型，优先考虑这些能力：

- `frontend-skill`
  - 用于 `Allergy` 前端页面或体验调整
- `playwright`
  - 用于支付页、订单页、报告页流程验证
- `screenshot`
  - 用于需要留存 UI 证据或人工比对时

如果任务明显需要这些技能，而环境里已经可用，就应实际使用，不要只在文档里提到。

### 3.5 工具验证优先于口头判断

对于以下事情，优先用工具验证，而不是口头假设：

- 支付回调是否成功
- 页面跳转是否正确
- 报告预览 / 下载是否正常
- 邮件补发接口是否符合预期
- 时间线是否真实写入

## 4. 当前任务目标

这不是两个独立项目的并行维护任务，而是一个集成任务：

- `Allergy/` 作为面向用户的前端站点
- `new-api/` 作为后端底座

目标是实现“过敏原检测服务”业务闭环：

1. 用户浏览站点
2. 用户购买单次检测服务
3. 用户线上支付
4. 后台人工寄送采样盒
5. 用户回寄样本
6. 检测机构出具 PDF 报告
7. 后台上传 PDF 报告
8. 后台可手工补发 PDF 到用户邮箱
9. 用户查看检测进度时间线
10. 用户预览和下载 PDF 报告

## 5. 已锁定的方案

这些已经定了，不要再重新设计。

### 5.1 账号与登录

- 会员直接挂在 `new-api` 的 `user` 主表
- 公共站主登录方式改为 `用户名/邮箱 + 密码`
- 公共站注册必须做邮箱验证
- 邮箱验证码主要用于：
  - 注册验证
  - 找回密码
  - 必要时的高风险二次确认
- 站点使用自己的 `session token`
- 不复用 `new-api` 的 `access_token` 语义
- 公共站会员登录入口和后台管理员入口必须分开
- 公共站登录只允许存在有效 `member_profile` 的账号
- 不再采用“首次登录自动创建账号”的模式
- 注册完成时创建会员账号和 `member_profile`
- 后台管理员账号如果没有 `member_profile`，不得走公共站登录
- 是否保留邮箱验证码快捷登录，只能作为备用或灰度方案，不能继续作为主登录方案

### 5.2 商品与履约

- 商品第一版按“单次购买检测服务”建模
- 不是 subscription 业务
- 不是 topup/quota 业务
- 支付成功后走人工履约
- 人工履约包括：
  - 采样盒寄送
  - 物流登记
  - 回寄登记
  - 报告上传
  - 手工补发邮件

### 5.3 支付

- 首版采用线上支付
- 首发支付渠道必须包含 `epay`
- 可以复用 `new-api` 现有支付接入层和 webhook 验签能力
- 不能复用 `TopUp` / `Recharge` / quota 增减语义
- 支付成功后的业务语义必须是：
  - `allergy_order.payment_status = paid`
  - `allergy_order.order_status = paid`
  - 写入时间线事件 `payment_completed`
- 支付成功后不能给用户加 quota

### 5.4 报告

- 第一版报告只支持 PDF
- 用户端支持 PDF 预览和下载
- 后台支持手工补发 PDF 到用户邮箱
- 用户端要有检测进度时间线
- PDF 预览和下载不走公开 URL，前端必须带会员登录态拉取 PDF `Blob`
- 报告补发只允许：
  - `order_email`
  - `account_email`
- 不允许后台输入任意邮箱地址
- 一个订单可以有多个报告版本，但只允许一份当前有效报告

### 5.5 内容

- 第一阶段公共站内容继续使用 `Option JSON`
- 第一阶段不要做完整 CMS
- 图片第一阶段先用固定 URL 或静态资源
- 第一阶段不要强上复杂图片系统

### 5.6 AI

- `Allergy.AI` 不是当前主线
- 现在不要优先开发 AI 功能
- 先把订单、支付、采样、报告闭环跑通

## 6. 实现护栏

### 6.1 不要把检测业务做成充值业务

禁止把 Allergy 业务直接建模成：

- `TopUp`
- `Recharge`
- quota 增减
- token 额度

支付接入可以复用，但订单支付语义不能错。

### 6.2 不要让公共站直接依赖平台原始语义

不要让前端直接依赖这些平台概念：

- topup
- quota
- relay
- channel
- token
- model pricing

公共站应通过面向 Allergy 的业务 API 工作。

### 6.3 报告属于敏感资料

实现时必须满足：

- PDF 必须放在持久化路径
- `lab_report` 只保存文件引用，不保存 PDF 二进制
- 报告补发默认只能发到：
  - 用户账号已验证邮箱
  - 或订单通知邮箱
- 不要默认允许后台把报告发到任意邮箱
- 每次补发都要写发送日志
- 预览和下载接口必须是受保护接口，不要暴露公开直链

### 6.4 共用 `user` 主表，但角色必须隔离

- 公共会员和后台管理员共用 `user` 表
- 但登录入口、权限检查、接口访问边界必须分开
- 不要让后台管理员账号混入公共会员登录流程

## 7. 目标数据模型

以这些表或等价结构为目标：

- `user` 复用
- `member_profile`
- `email_login_code_store`
- `member_session`
- `allergy_order`
- `sample_kit`
- `lab_submission`
- `lab_report`
- `report_delivery_log`
- `order_timeline_event`

关键原则：

- 一个订单是一个真实检测服务订单
- 一个订单默认对应一个采样盒
- 一个订单未来可以有多个报告版本，但同一时间只能有一份当前有效报告
- 时间线不能只靠状态字段推导，关键动作要落事件表
- 用户回寄样本第一版由后台登记，时间线要能体现 `sample_sent_back`
- 账号体系需要支持独立注册、登录、找回密码与邮箱验证状态

## 8. 目标接口

### 8.1 兼容接口

- `GET /api/hero`
- `GET /api/testimonials`
- `GET /api/articles`
- `GET /api/products`
- `POST /api/auth/register`
- `POST /api/auth/verify-email`
- `POST /api/auth/login`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `GET /api/auth/me`
- `POST /api/auth/logout`

说明：

- 不再把 `POST /api/auth/send-code` 视为主登录接口
- 如果保留该接口，也只应用于注册验证、找回密码或灰度备用流程

### 8.2 用户侧业务接口

- `POST /api/orders`
- `GET /api/orders`
- `GET /api/orders/:id`
- `POST /api/orders/:id/pay`
- `GET /api/orders/:id/pay-status`
- `GET /api/orders/:id/timeline`
- `GET /api/orders/:id/report`
- `GET /api/reports/:id/preview`
- `GET /api/reports/:id/download`

### 8.3 后台业务接口

- `GET /api/admin/orders`
- `GET /api/admin/orders/:id`
- `PATCH /api/admin/orders/:id/status`
- `POST /api/admin/orders/:id/kit`
- `POST /api/admin/orders/:id/sample-sent-back`
- `POST /api/admin/orders/:id/sample-received`
- `POST /api/admin/orders/:id/report`
- `POST /api/admin/reports/:id/publish`
- `POST /api/admin/reports/:id/send-email`
- `GET /api/admin/reports/:id/delivery-logs`

### 8.4 履约后台 UI 目标

首版履约不能只停留在后端接口，必须有最小可用的后台操作界面。

至少应包含这些页面或等价交互：

- 订单列表页
- 订单详情页
- 报告管理区

订单列表页至少要支持：

- 按订单号筛选
- 按用户邮箱筛选
- 按支付状态筛选
- 按订单状态筛选
- 按创建时间查看
- 展示字段：
  - 订单号
  - 用户邮箱
  - 收件人
  - 支付状态
  - 订单状态
  - 支付时间
  - 创建时间
- 提供快捷动作：
  - 查看详情
  - 发货
  - 标记样本签收
  - 上传报告

订单详情页至少要展示：

- 基础订单信息
- 支付信息：
  - 支付方式
  - 系统支付单号
  - 第三方支付单号
  - 支付时间
  - 回调原文或可查看入口
- 收件人与收货地址
- 采样盒与物流信息
- 检测进度时间线
- 报告信息
- 内部备注

履约动作区至少要支持：

- 发货录入：
  - `kit_code`
  - `outbound_carrier`
  - `outbound_tracking_no`
  - `outbound_shipped_at`
- 样本签收
- 上传报告
- 发布报告
- 补发报告邮件
- 查看邮件投递日志

用户侧订单详情页至少要能看到：

- 当前支付状态
- 当前履约状态
- 物流单号
- 时间线事件
- 报告预览与下载入口

## 9. 推荐实施顺序

除非用户明确要求改顺序，否则按下面顺序推进。

### Step 1

完成数据表和最小模型：

- `member_profile`
- `email_login_code_store`
- `member_session`
- `allergy_order`
- `sample_kit`
- `lab_report`
- `report_delivery_log`
- `order_timeline_event`

如实现成本可控，再补：

- `lab_submission`

### Step 2

完成公共站兼容接口：

- 内容接口
- 注册 / 登录 / 找回密码
- 会员登录态校验

### Step 3

完成订单与支付：

- 创建订单
- 拉起 `epay`
- 支付回调
- 更新 `allergy_order.payment_status`
- 写时间线 `payment_completed`

### Step 4

完成用户侧查询能力：

- 订单列表
- 订单详情
- 时间线
- 报告元信息
- PDF 预览/下载

### Step 5

完成后台履约能力：

- 订单状态管理
- 采样盒登记
- 样本回寄登记
- 样本签收
- PDF 上传
- 报告发布
- 手工补发邮件

### Step 6

只在主线稳定后，再考虑：

- 内容后台化
- 更多支付渠道
- 结构化报告摘要
- `Allergy.AI`

## 10. `new-api` 仓库级规则

修改 `new-api/` 内部代码时，必须遵守 `./new-api/CLAUDE.md`，尤其是：

- JSON 读写用 `common/json.go`
- 数据库代码必须兼容 SQLite / MySQL / PostgreSQL
- 不得改动受保护的项目名称与身份信息

## 11. 前端改动要求

- 默认尽量少改前端，但允许为主线业务补齐必要页面
- `Allergy` 前端主要承担：
  - 注册 / 登录 / 找回密码
  - 下单
  - 支付
  - 订单详情
  - 报告预览与下载
- `new-api/web` 需要承担后台履约 UI：
  - 订单列表
  - 订单详情
  - 发货录入
  - 样本签收
  - 报告上传 / 发布 / 补发
- 不要把 `new-api` 的平台概念暴露到用户页面上
- 报告页的预览和下载都按“带鉴权获取 PDF `Blob`”实现

## 12. 不要做的事

- 不要把检测订单直接映射成 `TopUp`
- 不要支付成功后给用户加 quota
- 不要把 PDF 存在临时目录
- 不要允许后台无约束地把报告发到任意邮箱
- 不要优先开发 AI 功能
- 不要为了首版把内容系统做复杂

## 13. 完成标准

当以下内容可用时，说明首版主线完成：

1. 用户能完成注册、邮箱验证，并通过用户名或邮箱加密码登录
2. 用户能创建检测订单
3. 用户能使用 `epay` 在线支付
4. 支付成功后订单状态能正确更新
5. 后台有最小可用的履约界面，不是只有 API
6. 后台能登记采样盒和履约状态
7. 后台能上传 PDF 报告并发布
8. 用户能看到检测进度时间线
9. 用户能预览和下载 PDF 报告
10. 后台能手工补发 PDF 到用户邮箱
11. 报告补发不允许发送到任意邮箱
