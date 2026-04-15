# 支付对账与导出设计草案

日期：2026-04-15

状态：

- draft

## 1. 范围

这份文档定义第一版支付对账页与导出能力。

不包含：

- 自动对接外部财务系统
- 自动记账
- 多币种处理

## 2. 当前问题

- 目前没有支付对账视图
- 运营无法按支付时间、支付渠道、订单号导出
- 异常支付无法统一盘点

## 3. 第一版建议目标

- 后台提供对账列表页
- 支持按支付时间筛选
- 支持按支付渠道筛选
- 支持按订单号筛选
- 支持导出当前筛选结果

## 4. 依赖数据

- `payment_status`
- `payment_method`
- `payment_ref`
- `payment_provider_order_no`
- `payment_callback_payload_json`
- `paid_at`

## 5. 建议后续拆分文档

- `reconciliation-api-contract.md`
- `reconciliation-test-plan.md`

## 6. 最低验收标准

- 管理员可查看支付对账列表
- 可按支付时间筛选
- 可按支付渠道筛选
- 可按订单号筛选
- 可导出筛选结果
- 导出字段包含系统支付单号与第三方支付单号
