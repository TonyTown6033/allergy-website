# 支付对账与导出 API 草案

日期：2026-04-15

状态：

- draft

关联文档：

- [reconciliation-design.md](./reconciliation-design.md)

## 1. 范围

这份文档定义第一版支付对账列表与导出接口草案。

## 2. 建议接口

- `GET /api/admin/reconciliation/orders`
- `GET /api/admin/reconciliation/orders/export`

## 3. 建议筛选参数

- `paid_at_from`
- `paid_at_to`
- `payment_method`
- `order_no`
- `user_email`
- `payment_status`

## 4. 返回字段建议

- 订单号
- 用户邮箱
- 支付状态
- 支付渠道
- 系统支付单号
- 第三方支付单号
- 支付时间

## 5. 待确认事项

- 导出格式是否只做 CSV
- 是否支持大数据量异步导出
