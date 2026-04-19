# 会员待支付订单取消 API 契约

日期：2026-04-19

状态：

- draft

关联文档：

- [order-cancellation-design.md](./order-cancellation-design.md)

## 1. 范围

这份文档定义会员端“取消待支付订单”接口，以及订单详情页需要依赖的页面语义。

本次不改动退款接口，也不改动支付回调接口。

## 2. `POST /api/orders/:id/cancel`

### 2.1 请求

无需请求体。

### 2.2 成功响应

```json
{
  "order_id": 12,
  "payment_status": "cancelled",
  "order_status": "cancelled",
  "cancelled_at": "2026-04-19T12:34:56+08:00"
}
```

### 2.3 业务约束

- 只能取消当前登录会员自己的订单
- 只有以下组合允许取消：
  - `payment_status = pending`
  - `order_status = pending_payment`
- 成功后必须写入用户可见时间线事件：
  - `event_type = cancelled`
  - `title = 订单已取消`

### 2.4 失败语义

典型失败场景：

- 订单不存在或不属于当前用户
- 订单已支付
- 订单已进入履约阶段
- 订单已取消

失败时返回现有 API 错误格式，`message` 应明确表达“订单当前状态不可取消”。

## 3. `GET /api/orders/:id`

本次不强制新增字段。

前端以既有字段判断取消按钮展示：

- `payment_status`
- `order_status`

## 4. 页面交互约定

- 支付页回跳参数 `payment_result=cancelled` 仅表示本次支付未完成
- 订单真正关闭以 `POST /api/orders/:id/cancel` 成功为准
- 取消成功后，订单详情页应刷新读侧数据，并停止展示继续支付能力
