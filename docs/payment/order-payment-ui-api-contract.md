# 会员订单支付页体验补齐 API 契约

日期：2026-04-19

状态：

- draft

关联文档：

- [order-payment-ui-design.md](./order-payment-ui-design.md)

## 1. 范围

这份文档只定义会员端订单详情页支付区为补齐体验所需的读侧字段变化。

不新增新的支付业务接口。

## 2. `GET /api/orders/:id`

### 2.1 新增返回字段

- `service_price_cents: number`
- `currency: string`
- `available_payment_methods: Array<{ code: string; label: string }>`

### 2.2 返回示例

```json
{
  "order_id": 12,
  "order_no": "AO202604190001",
  "service_name": "居家过敏原检测包",
  "service_price_cents": 19900,
  "currency": "CNY",
  "payment_status": "pending",
  "order_status": "pending_payment",
  "recipient_name": "张三",
  "recipient_phone": "13800000000",
  "recipient_email": "demo@example.com",
  "shipping_address": {
    "province": "上海市",
    "city": "上海市",
    "district": "浦东新区",
    "address_line": "世纪大道 100 号"
  },
  "available_payment_methods": [
    {
      "code": "alipay",
      "label": "支付宝"
    },
    {
      "code": "wxpay",
      "label": "微信"
    }
  ],
  "sample_kit": null
}
```

### 2.3 字段约束

- `service_price_cents`
  - 来源于订单价格快照
  - 单位为分
- `currency`
  - 订单币种，当前默认 `CNY`
- `available_payment_methods`
  - 来源于后台当前支付方式配置
  - 只返回当前允许用于 `POST /api/orders/:id/pay` 的方式
  - 每个元素必须同时包含：
    - `code`：支付提交值
    - `label`：前端展示名称

## 3. `POST /api/orders/:id/pay`

接口路径、请求体和返回结构保持不变。

前端仍提交：

```json
{
  "payment_method": "alipay",
  "success_url": "https://example.com/orders/12?payment_result=success",
  "cancel_url": "https://example.com/orders/12?payment_result=cancelled"
}
```

## 4. 前端页面路由约定

订单详情页回跳参数增加：

- `payment_result=success`
- `payment_result=cancelled`

页面仅将其作为提示来源，不直接视为支付完成事实。

最终支付状态仍需以后端订单读接口和支付状态接口为准。
