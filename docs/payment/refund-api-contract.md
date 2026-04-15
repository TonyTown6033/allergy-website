# 退款流程 API 草案

日期：2026-04-15

状态：

- draft

关联文档：

- [refund-design.md](./refund-design.md)

## 1. 范围

这份文档定义第一版后台人工退款接口草案。

## 2. 建议接口

- `POST /api/admin/orders/:id/refund`
- `GET /api/admin/orders/:id/refunds`

## 3. 退款请求建议字段

- `reason`
- `remark`
- `amount`

## 4. 核心约束

- 已支付未发货订单允许进入退款流程
- 已发货订单不允许走同一条快捷退款路径
- 每次退款动作必须记录操作人和时间

## 5. 待确认事项

- 是否支持部分退款
- 是否同步写支付回调原文摘要
- 是否需要退款状态枚举
