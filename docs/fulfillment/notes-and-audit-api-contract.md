# 履约备注区与操作日志 API 草案

日期：2026-04-15

状态：

- draft

关联文档：

- [notes-and-audit-design.md](./notes-and-audit-design.md)

## 1. 范围

这份文档定义订单详情页备注区与操作日志区的后台接口草案。

## 2. 建议接口

- `GET /api/admin/orders/:id/notes`
- `POST /api/admin/orders/:id/notes`
- `GET /api/admin/orders/:id/audit-logs`

## 3. 备注接口要求

- 返回备注内容、创建时间、创建人
- 支持管理员新增备注
- 不允许通过备注接口直接修改订单状态

## 4. 操作日志接口要求

- 只读
- 自动记录关键履约动作
- 返回动作名、操作人、时间、摘要信息

## 5. 待确认事项

- 备注是否允许编辑
- 备注是否允许删除
- 日志是否需要分页
