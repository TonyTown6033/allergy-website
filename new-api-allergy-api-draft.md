# `new-api` + `Allergy` API 草案

日期：2026-04-13

关联文档：

- [new-api-allergy-integration-design.md](/Users/town/Projects/allergy_website/new-api-allergy-integration-design.md:1)
- [new-api-allergy-data-model-draft.md](/Users/town/Projects/allergy_website/new-api-allergy-data-model-draft.md:1)

## 1. 范围

这份文档定义两类 API：

1. 为保留 `Allergy` 前端而准备的兼容接口
2. 为检测订单、报告和后台操作准备的新业务接口

目标是：

- 前台低改动接入 `new-api`
- 后台能跑通“订单 -> 采样盒 -> 报告 -> 邮件补发”闭环

---

## 2. 统一约定

### 2.1 接口域名

建议统一走：

- `https://api.allergy.xxx`

### 2.2 鉴权方式

会员接口使用：

- `Authorization: Bearer <session_token>`

这里的 `session_token` 只代表会员登录态，不代表：

- API key
- AI 配额
- 任何商品额度

### 2.3 返回风格

为了兼容当前前端，建议分两种风格：

#### A. 兼容接口

保留当前 `Allergy` 前端习惯，尽量返回原始结构。

例如：

- `/api/hero` 直接返回对象
- `/api/testimonials` 直接返回数组

#### B. 新业务接口

统一返回：

```json
{
  "success": true,
  "message": "",
  "data": {}
}
```

### 2.4 时间字段

统一使用 ISO 8601 字符串。

例如：

- `2026-04-13T20:30:00+08:00`

---

## 3. 兼容接口

### 3.1 站点内容接口

### `GET /api/hero`

用途：

- 获取首页主图

响应：

```json
{
  "image": "https://cdn.example.com/allergy/hero-1.jpg"
}
```

### `GET /api/testimonials`

用途：

- 获取用户故事列表

响应：

```json
[
  {
    "id": "1",
    "name": "李妈妈",
    "role": "3岁过敏儿妈妈",
    "quote": "......",
    "image": "https://cdn.example.com/allergy/story-1.jpg"
  }
]
```

### `GET /api/articles`

用途：

- 获取文章卡片列表

响应：

```json
[
  {
    "id": "1",
    "category": "过敏科普",
    "title": "为什么现在的孩子过敏越来越多？",
    "summary": "......",
    "image": "https://cdn.example.com/allergy/article-1.jpg"
  }
]
```

### `GET /api/products`

用途：

- 获取检测服务卡片

响应：

```json
[
  {
    "id": "allergy-test-basic",
    "title": "埃勒吉居家过敏原检测服务",
    "description": "......",
    "image": "https://cdn.example.com/allergy/product-1.jpg",
    "ctaText": "立即购买",
    "tag": "推荐"
  }
]
```

说明：

- 第一阶段这些接口的数据源仍然来自 `Option JSON`

### 3.2 登录接口

### `POST /api/auth/send-code`

用途：

- 发送邮箱验证码

请求：

```json
{
  "email": "user@example.com"
}
```

响应：

```json
{
  "success": true,
  "message": "验证码已发送"
}
```

失败响应：

```json
{
  "success": false,
  "message": "请输入正确的邮箱地址"
}
```

### `POST /api/auth/login`

用途：

- 使用邮箱验证码登录

请求：

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

响应：

```json
{
  "success": true,
  "token": "session_token_here",
  "email": "user@example.com",
  "user": {
    "id": 1001,
    "email": "user@example.com"
  }
}
```

说明：

- `token` 是会员登录态
- 前端可继续使用本地存储方式保存它

### `GET /api/auth/me`

用途：

- 获取当前登录会员信息

请求头：

```text
Authorization: Bearer <session_token>
```

响应：

```json
{
  "success": true,
  "email": "user@example.com",
  "user": {
    "id": 1001,
    "email": "user@example.com",
    "nickname": "Town",
    "phone": "13800000000"
  }
}
```

### `POST /api/auth/logout`

用途：

- 使当前登录态失效

响应：

```json
{
  "success": true,
  "message": "已退出登录"
}
```

---

## 4. 用户侧业务接口

### 4.1 订单接口

### `POST /api/orders`

用途：

- 创建单次检测服务订单

请求：

```json
{
  "service_code": "allergy-test-basic",
  "recipient_name": "张三",
  "recipient_phone": "13800000000",
  "recipient_email": "user@example.com",
  "shipping_address": {
    "province": "上海市",
    "city": "上海市",
    "district": "浦东新区",
    "address_line": "世纪大道 xxx 号"
  }
}
```

响应：

```json
{
  "success": true,
  "message": "",
  "data": {
    "order_id": 2001,
    "order_no": "AO202604130001",
    "payment_status": "pending",
    "order_status": "pending_payment"
  }
}
```

说明：

- 订单创建不代表已经支付
- 支付成功前不能进入实际履约

### `POST /api/orders/:id/pay`

用途：

- 为指定检测订单拉起在线支付

请求：

```json
{
  "payment_method": "epay",
  "success_url": "https://www.allergy.xxx/orders/2001",
  "cancel_url": "https://www.allergy.xxx/orders/2001"
}
```

响应示例一：

```json
{
  "success": true,
  "message": "",
  "data": {
    "payment_method": "epay",
    "trade_no": "AO_PAY_20260413_001",
    "redirect_url": "https://pay.example.com/...",
    "payment_status": "pending"
  }
}
```

响应示例二：

```json
{
  "success": true,
  "message": "",
  "data": {
    "payment_method": "epay",
    "trade_no": "AO_PAY_20260413_001",
    "form_data": {
      "pid": "xxx",
      "out_trade_no": "AO_PAY_20260413_001"
    },
    "payment_status": "pending"
  }
}
```

行为建议：

- 首发必须支持 `epay`
- 复用 `new-api` 现有支付接入代码
- 但支付单要绑定到 `allergy_order`
- 不得走 `Recharge` 给用户加 quota

### `GET /api/orders/:id/pay-status`

用途：

- 查询订单支付状态

响应：

```json
{
  "success": true,
  "message": "",
  "data": {
    "order_id": 2001,
    "payment_status": "paid",
    "order_status": "paid",
    "paid_at": "2026-04-13T20:40:00+08:00"
  }
}
```

### `GET /api/orders`

用途：

- 获取当前用户订单列表

响应：

```json
{
  "success": true,
  "message": "",
  "data": [
    {
      "order_id": 2001,
      "order_no": "AO202604130001",
      "service_name": "埃勒吉居家过敏原检测服务",
      "payment_status": "paid",
      "order_status": "report_ready",
      "created_at": "2026-04-13T20:30:00+08:00",
      "report_ready_at": "2026-04-20T15:00:00+08:00"
    }
  ]
}
```

### `GET /api/orders/:id`

用途：

- 获取订单详情

响应：

```json
{
  "success": true,
  "message": "",
  "data": {
    "order_id": 2001,
    "order_no": "AO202604130001",
    "service_name": "埃勒吉居家过敏原检测服务",
    "payment_status": "paid",
    "order_status": "report_ready",
    "recipient_name": "张三",
    "recipient_phone": "13800000000",
    "recipient_email": "user@example.com",
    "shipping_address": {
      "province": "上海市",
      "city": "上海市",
      "district": "浦东新区",
      "address_line": "世纪大道 xxx 号"
    },
    "sample_kit": {
      "kit_code": "KIT-20260413-001",
      "kit_status": "sample_received",
      "outbound_tracking_no": "SF1234567890"
    }
  }
}
```

### `GET /api/orders/:id/timeline`

用途：

- 获取用户检测进度时间线

响应：

```json
{
  "success": true,
  "message": "",
  "data": [
    {
      "event_type": "payment_completed",
      "title": "订单已支付",
      "description": "我们已开始准备采样盒",
      "occurred_at": "2026-04-13T20:35:00+08:00"
    },
    {
      "event_type": "kit_shipped",
      "title": "采样盒已寄出",
      "description": "顺丰快递 SF1234567890",
      "occurred_at": "2026-04-14T09:00:00+08:00"
    }
  ]
}
```

### 4.2 报告接口

### `GET /api/orders/:id/report`

用途：

- 获取订单对应的当前有效报告信息

响应：

```json
{
  "success": true,
  "message": "",
  "data": {
    "report_id": 3001,
    "report_title": "过敏原检测报告",
    "report_status": "published",
    "published_at": "2026-04-20T15:00:00+08:00",
    "preview_url": "/api/reports/3001/preview",
    "download_url": "/api/reports/3001/download"
  }
}
```

### `GET /api/reports/:id/preview`

用途：

- 在线预览 PDF 报告

行为建议：

- 返回 `application/pdf`
- `Content-Disposition: inline`

权限要求：

- 只有该报告所属用户本人可访问

### `GET /api/reports/:id/download`

用途：

- 下载 PDF 报告

行为建议：

- 返回 `application/pdf`
- `Content-Disposition: attachment`

权限要求：

- 只有该报告所属用户本人可访问

---

## 5. 后台业务接口

这些接口可以是纯 API，也可以对应到 `new-api` 控制台中的后台操作。

### 5.1 订单管理

### `GET /api/admin/orders`

用途：

- 分页查询订单

建议支持筛选：

- `order_no`
- `email`
- `payment_status`
- `order_status`

### `GET /api/admin/orders/:id`

用途：

- 获取后台订单详情

### `PATCH /api/admin/orders/:id/status`

用途：

- 修改订单状态

请求：

```json
{
  "order_status": "kit_preparing",
  "remark": "已通知仓库备货"
}
```

### 5.2 采样盒操作

### `POST /api/admin/orders/:id/kit`

用途：

- 创建或更新采样盒信息

请求：

```json
{
  "kit_code": "KIT-20260413-001",
  "kit_status": "shipped",
  "outbound_carrier": "顺丰",
  "outbound_tracking_no": "SF1234567890",
  "outbound_shipped_at": "2026-04-14T09:00:00+08:00"
}
```

行为建议：

- 自动写入时间线事件 `kit_shipped`

### `POST /api/admin/orders/:id/sample-received`

用途：

- 标记样本已收到

请求：

```json
{
  "received_at": "2026-04-16T11:30:00+08:00",
  "remark": "检测机构已签收"
}
```

行为建议：

- 自动更新订单状态到 `sample_received` 或 `in_testing`
- 自动写入时间线

### 5.3 报告管理

### `POST /api/admin/orders/:id/report`

用途：

- 上传订单报告 PDF

请求：

- `multipart/form-data`
- 包含 PDF 文件
- 可附带 `report_title`

响应：

```json
{
  "success": true,
  "message": "",
  "data": {
    "report_id": 3001,
    "report_status": "uploaded"
  }
}
```

行为建议：

- 上传成功后自动写入时间线 `report_uploaded`

### `POST /api/admin/reports/:id/publish`

用途：

- 将报告设为用户可见

行为建议：

- 写入 `published_at`
- 更新订单状态为 `report_ready`
- 写入时间线 `report_published`

### `POST /api/admin/reports/:id/send-email`

用途：

- 后台手工补发 PDF 报告到用户邮箱

请求：

```json
{
  "target_email": "user@example.com"
}
```

响应：

```json
{
  "success": true,
  "message": "报告已发送",
  "data": {
    "report_id": 3001,
    "target_email": "user@example.com",
    "delivery_status": "sent"
  }
}
```

行为建议：

- 发送后写入 `report_delivery_log`
- 同时写入时间线 `report_email_sent`

### `GET /api/admin/reports/:id/delivery-logs`

用途：

- 查看某份报告的邮件发送历史

---

## 6. 与支付的衔接建议

当前支付路线已经明确。

### 已确认的支付方案

- 首版就是线上售卖
- 支付成功后进入人工履约
- 复用 `new-api` 的支付渠道接入层
- 不复用 `TopUp/Recharge` 的充值语义
- 首发支付渠道必须包含 `epay`

### 支付状态流转建议

1. 用户创建 `allergy_order`
2. 用户调用 `POST /api/orders/:id/pay`
3. 后端拉起易支付
4. 支付平台回调业务 webhook
5. 后端校验回调并更新：
   - `payment_status = paid`
   - `order_status = paid`
   - `paid_at`
6. 同时写入时间线事件 `payment_completed`
7. 后台开始人工履约：
   - 采样盒备货
   - 物流登记
   - 样本签收
   - 报告上传

### 不建议的做法

- 支付成功后写入 `TopUp` 并给用户加 quota
- 把检测服务订单直接当成充值订单
- 前台直接调用 `new-api` 原有 `/api/user/pay` 作为最终业务接口

---

## 7. 最小接口集合建议

如果只做第一版，我建议至少实现这 14 个接口：

1. `GET /api/hero`
2. `GET /api/testimonials`
3. `GET /api/articles`
4. `GET /api/products`
5. `POST /api/auth/send-code`
6. `POST /api/auth/login`
7. `GET /api/auth/me`
8. `GET /api/orders`
9. `GET /api/orders/:id`
10. `POST /api/orders/:id/pay`
11. `GET /api/orders/:id/pay-status`
12. `GET /api/orders/:id/timeline`
13. `GET /api/orders/:id/report`
14. `GET /api/reports/:id/download`

如果要把“报告预览”和“后台上传补发”也纳入首版，建议追加这 4 个：

1. `GET /api/reports/:id/preview`
2. `POST /api/admin/orders/:id/report`
3. `POST /api/admin/reports/:id/publish`
4. `POST /api/admin/reports/:id/send-email`

---

## 8. 推荐的用户侧页面映射

建议接口和页面关系如下：

| 页面 | 主要接口 |
|---|---|
| 首页 | `/api/hero`, `/api/testimonials`, `/api/articles`, `/api/products` |
| 登录弹窗 | `/api/auth/send-code`, `/api/auth/login` |
| 个人中心 | `/api/auth/me`, `/api/orders` |
| 订单支付页 | `/api/orders/:id/pay`, `/api/orders/:id/pay-status` |
| 订单详情 | `/api/orders/:id`, `/api/orders/:id/timeline` |
| 报告详情 | `/api/orders/:id/report`, `/api/reports/:id/preview`, `/api/reports/:id/download` |

---

## 9. 推荐的后台页面映射

| 后台页面 | 主要接口 |
|---|---|
| 订单列表 | `/api/admin/orders` |
| 订单详情 | `/api/admin/orders/:id`, `/api/admin/orders/:id/kit` |
| 样本处理 | `/api/admin/orders/:id/sample-received` |
| 报告上传 | `/api/admin/orders/:id/report` |
| 报告发布 | `/api/admin/reports/:id/publish` |
| 报告补发 | `/api/admin/reports/:id/send-email`, `/api/admin/reports/:id/delivery-logs` |

---

## 10. 实施建议

为了降低改造风险，建议接口落地顺序如下：

### 第一步

- 先把内容接口和邮箱登录接口接到 `new-api`

### 第二步

- 增加订单创建、拉起支付、查询支付状态

### 第三步

- 增加订单详情、时间线、报告下载

### 第四步

- 增加后台上传 PDF、发布报告、手工补发邮件

### 第五步

- 再考虑更多支付渠道和 AI 增值能力
