# TODO.md — 过敏原订单支付与履约

关联文档：

- [README.md](./README.md)
- [claude.md](./claude.md)
- [docs/README.md](./docs/README.md)

## 目标

为过敏原检测订单补齐可运营的后台流程，覆盖以下场景：

- 管理员查看支付信息和用户收件信息
- 管理员为已支付订单发货并维护物流状态
- 管理员登记样本回收、检测进度、报告发布和邮件发送
- 后续支持退款、售后和对账

## 当前任务与文档挂接

以后新增功能默认按“`TODO.md` 挂任务 + `docs/<domain>/` 落专项文档”的方式推进。

| 任务 | 当前状态 | 文档入口 |
|---|---|---|
| 会员账号体系改造 | 已实现，待执行线上清理与联调 | [design](./docs/auth/member-auth-design.md)<br>[api-contract](./docs/auth/member-auth-api-contract.md)<br>[migration](./docs/auth/member-auth-migration-cleanup.md)<br>[test-plan](./docs/auth/member-auth-test-plan.md) |
| 检测项目目录与上架管理 | 已实现，待线上联调 | [design](./docs/catalog/service-catalog-design.md)<br>[api-contract](./docs/catalog/service-catalog-api-contract.md)<br>[migration](./docs/catalog/service-catalog-migration.md)<br>[test-plan](./docs/catalog/service-catalog-test-plan.md) |
| 履约备注区与操作日志 | 已建草案，待细化 | [design](./docs/fulfillment/notes-and-audit-design.md)<br>[api-contract](./docs/fulfillment/notes-and-audit-api-contract.md)<br>[test-plan](./docs/fulfillment/notes-and-audit-test-plan.md) |
| 发货 SOP 文档 | 已建骨架，待补内容 | [docs/fulfillment/shipping-sop-outline.md](./docs/fulfillment/shipping-sop-outline.md) |
| 退款流程 | 已建草案，待锁定规则 | [design](./docs/payment/refund-design.md)<br>[api-contract](./docs/payment/refund-api-contract.md)<br>[test-plan](./docs/payment/refund-test-plan.md) |
| 支付对账与导出 | 已建草案，待补接口 | [design](./docs/reconciliation/reconciliation-design.md)<br>[api-contract](./docs/reconciliation/reconciliation-api-contract.md)<br>[test-plan](./docs/reconciliation/reconciliation-test-plan.md) |
| CI/CD 与发布治理改造 | 已建草案，待实施 | [design](./docs/deploy/cicd-design.md)<br>[runbook](./docs/deploy/cicd-runbook.md) |

## 当前实现状态

### 已有能力

- [x] 用户可创建订单并发起支付
- [x] 支付成功后自动更新订单为 `paid`
- [x] 支付回调原文、第三方支付单号、支付时间已写入数据库
- [x] 管理端已有过敏原订单相关 API
- [x] 管理控制台已有过敏原订单列表页和详情页
- [x] 可通过 API 更新采样盒状态、录入物流单号
- [x] 可通过 API 标记样本回寄、开始检测、完成订单
- [x] 可通过 API 标记样本已签收
- [x] 可通过 API 上传 PDF 报告、发布报告、补发邮件
- [x] 管理员详情接口已返回完整支付字段、报告列表、时间线
- [x] 用户端可查看订单时间线、支付状态、报告入口
- [x] 后台可新增、编辑、上架、下架检测项目，并定义价格与商品详情
- [x] 前台商品展示与下单服务已统一到已上架检测项目目录
- [x] 下单时保存检测项目名称和价格快照，后续改价或下架不影响既有订单履约

### 当前缺口

- [ ] 没有退款/售后处理接口
- [ ] 没有面向运营的发货 SOP 文档
- [ ] 没有支付对账视图
- [ ] 没有订单异常告警和人工备注流转机制
- [ ] 订单列表页还没有“创建时间”筛选，也没有列表级快捷履约动作
- [ ] 管理备注目前只支持随动作写入 `admin_remark`，还没有独立备注管理区
- [ ] 线上旧会员清理脚本仍需在切流前 `dry-run` 并人工确认执行
- [ ] 根仓库镜像构建仍使用浮动 submodule 头部，发布产物不可严格复现
- [ ] 生产部署目前仍直接消费 `latest + watchtower`，缺少固定版本与人工发布闸门

## 账号体系规划

### 当前状态

- [x] 已切换为 `用户名/邮箱 + 密码` 登录
- [x] 已上线独立 `/login`、`/register`、`/forgot-password` 页面
- [x] 注册改为“邮箱验证码验证后建号”
- [x] 已提供旧会员清理脚本入口：`go run ./bin/allergy_member_cleanup.go`
- [ ] 正式环境仍需先执行清理脚本 `dry-run`，再安排切流

### 本轮 Review 后续修正

- [ ] 将会员邮箱唯一性从应用层检查提升为数据库硬约束，避免并发注册产生重复邮箱账号
- [ ] 调整登录标识规则，避免“用户名命中他人邮箱”导致 `identifier` 查询歧义
- [ ] 收敛找回密码对外错误语义，避免通过公开接口枚举管理员账号、非会员账号和禁用状态
- [ ] 补齐顶部导航登录跳转对查询参数的保留，避免从带 `search` 的页面登录后回跳信息丢失

### 目标方案

- [x] 支持传统登录方式：`用户名/邮箱 + 密码`
- [x] 支持独立注册流程，不再依赖“首次登录自动建号”
- [x] 邮箱验证码仅用于以下场景：
  - 注册时验证邮箱归属
  - 找回密码
  - 高风险安全操作时二次确认
- [x] 日常登录默认不再要求邮箱验证码
- [ ] 保留后续接入短信、2FA、Passkey 的扩展空间

对应文档：

- [docs/auth/member-auth-design.md](./docs/auth/member-auth-design.md)
- [docs/auth/member-auth-api-contract.md](./docs/auth/member-auth-api-contract.md)
- [docs/auth/member-auth-migration-cleanup.md](./docs/auth/member-auth-migration-cleanup.md)

### 注册与登录流程 TODO

- [ ] 新增注册页
- [ ] 注册时填写：
  - 用户名
  - 邮箱
  - 密码
  - 确认密码
- [ ] 注册时发送邮箱验证码
- [ ] 邮箱验证通过后才允许完成注册
- [ ] 新增登录页，支持输入用户名或邮箱登录
- [ ] 登录成功后进入用户订单中心
- [ ] 新增忘记密码页
- [ ] 忘记密码通过邮箱验证码重置密码
- [ ] 后台增加账号状态和邮箱验证状态字段
- [ ] 评估是否兼容保留现有“邮箱验证码快捷登录”作为灰度或备用入口

## 数据与状态

### 支付相关字段

当前订单表 `allergy_order` 已保存以下支付信息：

- `payment_status`
- `payment_method`
- `payment_ref`
- `payment_provider_order_no`
- `payment_callback_payload_json`
- `paid_at`

### 履约相关状态

订单状态：

- `pending_payment`
- `paid`
- `kit_preparing`
- `kit_shipped`
- `sample_returning`
- `sample_received`
- `in_testing`
- `report_ready`
- `completed`
- `cancelled`

采样盒状态：

- `prepared`
- `shipped`
- `delivered`
- `sample_sent_back`
- `sample_received`

## 运营流程规划

### 1. 支付后进入待履约

- [x] 管理员能筛选 `payment_status=paid` 的订单
- [x] 管理员能查看订单详情：
  - 收件人姓名
  - 手机号
  - 收货地址
  - 支付方式
  - 系统支付单号
  - 第三方支付单号
  - 支付时间
  - 回调原文
- [ ] 管理员能填写内部备注，例如特殊发货要求、客服备注、补寄说明
  当前仅支持在状态动作中附带备注并写入 `admin_remark`，还没有独立备注流转

### 2. 发货采样盒

- [x] 提供后台发货动作
- [x] 发货时录入：
  - `kit_code`
  - `outbound_carrier`
  - `outbound_tracking_no`
  - `outbound_shipped_at`
- [x] 发货后自动把订单置为 `kit_shipped`
- [x] 发货后给用户时间线增加“采样盒已寄出”
- [x] 订单详情页展示物流公司和物流单号

### 3. 样本回收与检测

- [x] 提供后台“样本已签收”动作
- [x] 标记样本签收后自动更新：
  - 采样盒状态
  - `lab_submission`
  - 订单状态为 `sample_received`
- [x] 预留“检测中”状态入口
- [x] 支持人工备注实验室接收情况、异常样本说明
  通过样本签收、开始检测等动作上的 `remark` 字段实现

### 4. 报告交付

- [x] 后台支持上传 PDF 报告
- [x] 后台支持发布报告
- [x] 发布后用户端可预览/下载
- [x] 后台支持补发报告邮件
- [x] 后台查看邮件投递日志

### 5. 售后与财务

- [ ] 设计退款流程
- [ ] 增加退款状态和退款时间
- [ ] 区分“支付成功但未发货”和“已发货不可直接退款”
- [ ] 增加支付对账页
- [ ] 支持按支付时间、支付渠道、订单号导出

对应文档：

- [docs/payment/refund-design.md](./docs/payment/refund-design.md)
- [docs/reconciliation/reconciliation-design.md](./docs/reconciliation/reconciliation-design.md)

## 后台页面规划

### A. 订单列表页

- [x] 筛选项：
  - 订单号
  - 用户邮箱
  - 支付状态
  - 订单状态
- [ ] 筛选项：
  - 创建时间
- [x] 列表字段：
  - 订单号
  - 用户邮箱
  - 收件人
  - 支付状态
  - 订单状态
  - 支付时间
  - 创建时间
- [x] 快捷动作：
  - 查看详情
- [ ] 快捷动作：
  - 发货
  - 标记样本签收
  - 上传报告

### B. 订单详情页

- [x] 基础信息区
- [x] 支付信息区
- [x] 收件与地址区
- [x] 物流与采样盒区
- [x] 时间线区
- [x] 报告区
- [ ] 管理备注区

对应文档：

- [docs/fulfillment/notes-and-audit-design.md](./docs/fulfillment/notes-and-audit-design.md)

### C. 报告管理区

- [x] 上传新报告
- [x] 发布当前版本
- [x] 查看历史版本
- [x] 手动补发邮件
- [x] 查看投递日志

### D. 检测项目管理区

- [x] 列表展示检测项目、价格、状态和排序
- [x] 新增检测项目
- [x] 编辑项目标题、详情、图片、标签、CTA、价格和排序
- [x] 上架检测项目
- [x] 下架检测项目
- [x] 前台仅展示已上架检测项目

## API 整理

### 已有管理员 API

- [x] `GET /api/admin/orders`
- [x] `GET /api/admin/orders/:id`
- [x] `PATCH /api/admin/orders/:id/status`
- [x] `POST /api/admin/orders/:id/kit`
- [x] `POST /api/admin/orders/:id/sample-sent-back`
- [x] `POST /api/admin/orders/:id/sample-received`
- [x] `POST /api/admin/orders/:id/testing-started`
- [x] `POST /api/admin/orders/:id/report`
- [x] `POST /api/admin/orders/:id/complete`
- [x] `GET /api/admin/reports/:id/preview`
- [x] `GET /api/admin/reports/:id/download`
- [x] `POST /api/admin/reports/:id/publish`
- [x] `POST /api/admin/reports/:id/send-email`
- [x] `GET /api/admin/reports/:id/delivery-logs`
- [x] `GET /api/admin/service-products`
- [x] `GET /api/admin/service-products/:id`
- [x] `POST /api/admin/service-products`
- [x] `PATCH /api/admin/service-products/:id`
- [x] `POST /api/admin/service-products/:id/publish`
- [x] `POST /api/admin/service-products/:id/archive`

### 需要补充或增强的 API

- [x] 管理员订单详情返回完整支付字段
- [ ] 退款接口
- [ ] 发货物流更新历史
- [ ] 订单操作审计日志
- [ ] 运营导出接口

## 实施优先级

### 第一阶段：先可运营

- [x] 补齐管理员订单详情返回字段
- [x] 新增管理后台订单列表页
- [x] 新增订单详情页
- [x] 接入发货、样本签收、上传报告、发布报告按钮
- [x] 新增后台检测项目目录与上架管理
- [x] 前台商品和下单服务使用同一检测项目目录

### 第二阶段：补齐财务与售后

- [ ] 退款流程
- [ ] 支付对账
- [ ] 导出能力
- [ ] 异常订单处理

### 第三阶段：增强自动化

- [ ] 发货短信或邮件通知
- [ ] 样本签收通知
- [ ] 报告发布通知
- [ ] 超时未发货提醒
- [ ] 对账异常提醒

## 运营临时 SOP

在后台页面完成前，先按下面方式人工处理：

1. 查询 `payment_status=paid` 的订单
2. 查看订单详情，确认收件人、手机号、地址
3. 人工发出采样盒
4. 调用发货接口写入物流公司和物流单号
5. 实验室收到样本后，调用样本签收接口
6. 报告生成后上传 PDF 并发布
7. 如用户没收到邮件，手动补发报告

## 备注

- 当前代码已具备检测项目目录、订单支付、履约、报告交付的主流程能力
- 后续优先补齐退款售后、支付对账、运营备注和异常告警
