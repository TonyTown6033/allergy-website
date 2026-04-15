# `new-api` + `Allergy` 数据模型草案

日期：2026-04-13

> 状态说明
> - 这份文档保留第一阶段数据建模思路
> - 其中认证相关字段说明基于早期验证码登录方案
> - 当前会员账号体系请以 [../auth/member-auth-design.md](../auth/member-auth-design.md) 为准

关联文档：

- [integration-design.md](./integration-design.md)

## 1. 范围

这份文档只定义第一阶段到第二阶段最需要的数据模型，目标是支撑以下业务闭环：

1. 用户用邮箱验证码登录
2. 用户购买单次过敏原检测服务
3. 运营寄送采样盒
4. 用户寄回样本
5. 检测机构出具 PDF 报告
6. 后台上传 PDF
7. 后台可手工补发 PDF 到用户邮箱
8. 用户可查看检测进度时间线
9. 用户可预览和下载 PDF 报告

当前已确认的前提：

- 会员直接挂在 `new-api` 的 `user` 主表
- 不引入额外的业务会员主键
- 第一阶段内容仍使用 `Option JSON`
- 报告第一版只上传 PDF

---

## 2. 建模原则

### 2.1 复用 `new-api user`，不重复造会员主表

会员主身份直接使用 `user.id`。

业务侧只新增 `member_profile` 作为补充档案表，不再新建独立的 `member_id`。

### 2.2 订单和报告是核心，AI 不是核心

本项目的核心业务实体是：

- 用户
- 订单
- 采样盒
- 送检
- 报告
- 时间线

不是：

- token quota
- model quota
- API key

### 2.3 地址信息优先保存在订单快照里

订单履约需要保留“当时的收货信息”，所以订单表必须保存收件人和地址快照。

会员资料里的地址只是默认值，不能替代订单快照。

### 2.4 PDF 作为第一版报告主载体

第一版不做复杂结构化报告解析。

报告中心只保证：

- 保存 PDF 元信息
- 支持后台上传
- 支持后台手工补发邮件
- 支持前台预览和下载

### 2.5 支付复用接入层，不复用充值语义

第一版采用线上支付，但支付成功后的业务含义必须是：

- 检测订单已支付

不是：

- 用户获得 quota
- 用户完成 topup
- 用户购买了平台 token

因此建议：

- 复用 `new-api` 的支付渠道接入与 webhook 处理思路
- 不直接把 `TopUp` 表当 Allergy 订单主表使用

---

## 3. 表关系总览

建议的最小关系如下：

- `user` 1:1 `member_profile`
- `user` 1:N `member_session`
- `user` 1:N `allergy_order`
- `allergy_order` 1:1 `sample_kit`
- `allergy_order` 1:1 `lab_submission`
- `allergy_order` 1:N `lab_report`
- `allergy_order` 1:N `order_timeline_event`
- `lab_report` 1:N `report_delivery_log`

说明：

- `lab_report` 设计成 1:N，是为了给将来的“重新出报告 / 新版本报告”留空间
- 第一版实际业务上可以默认每个订单只有一份有效报告

---

## 4. 复用表

### 4.1 `user`

直接复用 `new-api` 现有 `user` 表。

本项目对 `user` 的使用约束建议如下：

| 字段 | 用途 | 备注 |
|---|---|---|
| `id` | 会员主键 | 直接作为业务会员 ID |
| `email` | 登录邮箱 | 建议在 Allergy 业务上线前确保唯一性 |
| `username` | 内部用户名 | 不作为业务主标识展示给用户 |
| `status` | 用户状态 | 可用于禁用会员 |
| `role` | 权限角色 | 普通会员与后台管理员共用体系 |
| `setting` | 扩展配置 | 可保留给后续用户偏好 |

强烈建议：

- 在 Allergy 会员登录范围内，对 `email` 做唯一约束
- 公共站会员以 `member_profile` 存在且 `status = active` 作为准入标记
- 后台管理员账号如果没有可用 `member_profile`，不能走公共站邮箱验证码登录
- 管理员如需体验前台流程，使用独立会员邮箱，不与后台邮箱共用

如果短期内不改数据库唯一索引，也至少要在应用层强校验“一个邮箱只能对应一个有效会员账号”。

---

## 5. 新增表草案

### 5.1 `member_profile`

用途：

- 存会员补充资料
- 不替代 `user`

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `user_id` | bigint unique | 对应 `user.id` |
| `phone` | varchar(32) null | 联系电话，可为空 |
| `nickname` | varchar(64) null | 昵称 |
| `avatar_url` | varchar(512) null | 头像 |
| `real_name` | varchar(64) null | 真实姓名，可选 |
| `default_recipient_name` | varchar(64) null | 默认收件人 |
| `default_recipient_phone` | varchar(32) null | 默认收件电话 |
| `default_address_json` | json/text null | 默认地址，先用 JSON |
| `status` | varchar(32) | `active` / `disabled` |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

说明：

- 第一版默认地址放 JSON，先追求简单
- 如果后续需要省市区检索，再拆结构化地址表
- 公共站邮箱验证码登录只允许 `status = active` 的会员资料

### 5.2 `email_login_code_store`

用途：

- 存邮箱验证码
- 支撑邮箱验证码登录

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `email` | varchar(255) index | 登录邮箱 |
| `purpose` | varchar(32) | 例如 `login` |
| `code_hash` | varchar(255) | 验证码哈希，不存明文 |
| `expires_at` | datetime | 过期时间 |
| `used_at` | datetime null | 使用时间 |
| `send_ip` | varchar(64) null | 发送 IP |
| `attempt_count` | int default 0 | 校验次数 |
| `created_at` | datetime | 创建时间 |

说明：

- 验证码建议只存哈希值
- 可定时清理过期记录

### 5.3 `member_session`

用途：

- 存站点登录态
- 不复用 `new-api` 的平台 token 语义

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `user_id` | bigint index | 对应 `user.id` |
| `token_hash` | varchar(255) unique | 登录态 token 哈希 |
| `client_type` | varchar(32) | 例如 `web` |
| `user_agent` | varchar(1024) null | 客户端 UA |
| `login_ip` | varchar(64) null | 登录 IP |
| `expires_at` | datetime | 过期时间 |
| `last_seen_at` | datetime null | 最近活跃时间 |
| `revoked_at` | datetime null | 注销时间 |
| `created_at` | datetime | 创建时间 |

说明：

- 返回给前端的 token 建议只在创建时明文出现一次
- 数据库只保存哈希值

### 5.4 `allergy_order`

用途：

- 检测服务订单主表
- 保存支付、履约和地址快照

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `order_no` | varchar(64) unique | 业务订单号 |
| `user_id` | bigint index | 下单会员 |
| `service_code` | varchar(64) | 服务编码，例如 `allergy-test-basic` |
| `service_name_snapshot` | varchar(255) | 下单时服务名称快照 |
| `service_price_cents` | int | 下单金额，单位分 |
| `currency` | varchar(16) | 默认 `CNY` |
| `payment_status` | varchar(32) | 见状态字典 |
| `order_status` | varchar(32) | 见状态字典 |
| `recipient_name` | varchar(64) | 收件人 |
| `recipient_phone` | varchar(32) | 收件电话 |
| `recipient_email` | varchar(255) | 收件/通知邮箱 |
| `shipping_address_json` | json/text | 收货地址快照 |
| `payment_method` | varchar(32) null | 支付方式 |
| `payment_ref` | varchar(128) null | 支付流水引用 |
| `payment_provider_order_no` | varchar(128) null | 第三方支付订单号 |
| `payment_callback_payload_json` | json/text null | 支付回调原始载荷 |
| `paid_at` | datetime null | 支付时间 |
| `report_ready_at` | datetime null | 报告可查看时间 |
| `completed_at` | datetime null | 完成时间 |
| `cancelled_at` | datetime null | 取消时间 |
| `admin_remark` | text null | 后台备注 |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

建议的 `payment_status`：

- `pending`
- `paid`
- `refunded`
- `cancelled`

建议的 `order_status`：

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

说明：

- `payment_status` 和 `order_status` 分开，避免支付和履约状态互相污染
- 首发建议 `payment_method` 固定先支持 `epay`

### 5.5 `sample_kit`

用途：

- 管理采样盒编码和物流状态

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `order_id` | bigint unique | 对应订单 |
| `kit_code` | varchar(64) unique | 采样盒编码 |
| `kit_status` | varchar(32) | 见状态字典 |
| `outbound_carrier` | varchar(64) null | 寄出物流公司 |
| `outbound_tracking_no` | varchar(128) null | 寄出运单号 |
| `outbound_shipped_at` | datetime null | 寄出时间 |
| `delivered_at` | datetime null | 用户签收时间 |
| `return_carrier` | varchar(64) null | 用户回寄物流公司 |
| `return_tracking_no` | varchar(128) null | 用户回寄运单号，可空 |
| `sample_sent_back_at` | datetime null | 用户回寄时间 |
| `sample_received_at` | datetime null | 样本收到时间 |
| `remark` | text null | 备注 |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

建议的 `kit_status`：

- `not_created`
- `prepared`
- `shipped`
- `delivered`
- `sample_sent_back`
- `sample_received`

### 5.6 `lab_submission`

用途：

- 记录送检机构接收和检测状态

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `order_id` | bigint unique | 对应订单 |
| `sample_kit_id` | bigint null | 对应采样盒 |
| `lab_name` | varchar(128) | 检测机构名称 |
| `submission_no` | varchar(128) null | 机构受理号 |
| `status` | varchar(32) | 见状态字典 |
| `received_at` | datetime null | 机构签收时间 |
| `testing_started_at` | datetime null | 开始检测时间 |
| `completed_at` | datetime null | 检测完成时间 |
| `raw_payload_json` | json/text null | 外部回传原始数据，可空 |
| `remark` | text null | 备注 |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

建议的 `status`：

- `pending`
- `received`
- `testing`
- `completed`

### 5.7 `lab_report`

用途：

- 保存报告主记录
- 以 PDF 为第一版主载体

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `order_id` | bigint index | 对应订单 |
| `sample_kit_id` | bigint null | 对应采样盒 |
| `lab_submission_id` | bigint null | 对应送检记录 |
| `report_no` | varchar(128) null | 报告编号 |
| `report_title` | varchar(255) | 报告标题 |
| `version_no` | int | 同一订单内的报告版本号，从 1 递增 |
| `report_status` | varchar(32) | 见状态字典 |
| `is_current` | bool | 是否当前有效版本 |
| `replaces_report_id` | bigint null | 当前版本替代的旧报告 |
| `pdf_storage_type` | varchar(32) | 例如 `local` / `oss` |
| `pdf_file_path` | varchar(1024) | 文件路径或 URL |
| `pdf_file_name` | varchar(255) | 文件名 |
| `pdf_file_size` | bigint null | 文件大小 |
| `generated_at` | datetime null | 报告生成时间 |
| `published_at` | datetime null | 对用户可见时间 |
| `last_email_sent_at` | datetime null | 最近一次发邮件时间 |
| `email_sent_count` | int default 0 | 发送次数 |
| `last_sent_by_admin_user_id` | bigint null | 最近一次补发管理员 |
| `summary_json` | json/text null | 预留给未来结构化摘要 |
| `remark` | text null | 备注 |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

建议的 `report_status`：

- `draft`
- `uploaded`
- `published`
- `revoked`

说明：

- 第一版只要求 `pdf_file_path` 可用
- `summary_json` 先留空
- 同一订单同一时间只能有一份 `is_current = true` 的报告
- `GET /api/orders/:id/report` 只返回 `report_status = published` 且 `is_current = true` 的那一份
- 发布新版本时，旧的当前报告应改为 `is_current = false`

### 5.8 `report_delivery_log`

用途：

- 记录报告邮件发送历史
- 支撑后台手工补发审计

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `report_id` | bigint index | 对应报告 |
| `delivery_channel` | varchar(32) | 第一版固定 `email` |
| `target_source` | varchar(32) | `order_email` / `account_email` |
| `target` | varchar(255) | 目标邮箱 |
| `status` | varchar(32) | `pending` / `sent` / `failed` |
| `triggered_by_admin_user_id` | bigint null | 触发补发的管理员 |
| `error_message` | text null | 失败原因 |
| `sent_at` | datetime null | 发送时间 |
| `created_at` | datetime | 创建时间 |

### 5.9 `order_timeline_event`

用途：

- 生成用户侧“检测进度时间线”
- 同时保留后台操作审计线索

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `order_id` | bigint index | 对应订单 |
| `event_type` | varchar(64) | 事件类型 |
| `event_title` | varchar(128) | 用户看到的标题 |
| `event_desc` | text null | 说明 |
| `visible_to_user` | bool | 是否前台可见 |
| `operator_user_id` | bigint null | 操作人 |
| `occurred_at` | datetime | 事件发生时间 |
| `metadata_json` | json/text null | 扩展元数据 |
| `created_at` | datetime | 创建时间 |

建议的 `event_type`：

- `order_created`
- `payment_completed`
- `kit_preparing`
- `kit_shipped`
- `sample_sent_back`
- `sample_received`
- `lab_received`
- `testing_started`
- `report_uploaded`
- `report_published`
- `report_email_sent`

---

## 6. Phase 1 不新增的内容表

由于第一阶段内容仍走 `Option JSON`，以下内容暂时不单独建表：

- 首页 Hero
- Testimonials
- 文章列表
- 产品卡片

建议继续使用以下配置项：

- `allergy.hero`
- `allergy.testimonials`
- `allergy.articles`
- `allergy.products`

等后台内容管理需求稳定后，再考虑迁移到专用表。

---

## 7. 最小索引建议

建议至少加这些索引：

| 表 | 索引 |
|---|---|
| `user` | `email` 唯一或业务唯一约束 |
| `member_profile` | `user_id` unique |
| `email_login_code_store` | `email`, `expires_at` |
| `member_session` | `user_id`, `token_hash` unique, `expires_at` |
| `allergy_order` | `order_no` unique, `user_id`, `payment_status`, `order_status` |
| `sample_kit` | `order_id` unique, `kit_code` unique |
| `lab_submission` | `order_id` unique, `submission_no` |
| `lab_report` | `order_id`, `report_status`, `is_current`, `version_no` |
| `report_delivery_log` | `report_id`, `status`, `created_at` |
| `order_timeline_event` | `order_id`, `occurred_at` |

---

## 8. 当前最小可行版本建议

如果目标是尽快把第一版做起来，我建议数据库最少先实现这 8 张表或等价结构：

1. `member_profile`
2. `email_login_code_store`
3. `member_session`
4. `allergy_order`
5. `sample_kit`
6. `lab_report`
7. `report_delivery_log`
8. `order_timeline_event`

`lab_submission` 建议尽早有，但如果要极限压缩第一版，它可以稍后补齐。

---

## 9. 实施备注

### 9.1 文件存储

第一版 PDF 可以先用本地文件路径或固定对象路径，不强制要求对象存储。

但无论用哪种存储，`lab_report` 都只保存“文件引用”，不要把 PDF 二进制直接塞数据库。

如果使用本地文件路径，这个路径必须位于持久化存储中，不能依赖容器临时目录。

### 9.2 邮件发送

由于当前需求是“后台手工补发”，所以第一版不用做复杂消息队列。

最小做法是：

- 管理员点击补发
- 只能选择 `order_email` 或 `account_email` 作为收件目标
- 后端读取 PDF
- 发送邮件
- 写 `report_delivery_log`

### 9.3 时间线生成

建议所有关键业务动作都写入 `order_timeline_event`，不要只改状态字段。

这样前台展示和后台审计都更稳。
