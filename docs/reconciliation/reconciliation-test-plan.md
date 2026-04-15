# 支付对账与导出测试计划

日期：2026-04-15

状态：

- draft

关联文档：

- [reconciliation-design.md](./reconciliation-design.md)
- [reconciliation-api-contract.md](./reconciliation-api-contract.md)

## 1. 验收范围

- 管理员查看对账列表
- 筛选条件生效
- 导出结果与筛选条件一致

## 2. 后端测试

- 支持按支付时间筛选
- 支持按支付渠道筛选
- 支持按订单号筛选
- 导出字段包含系统支付单号与第三方支付单号

## 3. 前端联调

- 列表页展示核心支付字段
- 筛选表单与结果联动正常
- 导出按钮可用并带出当前筛选条件

## 4. 回归重点

- 不影响现有订单列表查询
- 不影响支付成功订单详情展示
