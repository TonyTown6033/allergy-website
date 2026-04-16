# 文档导航

这个目录按 `new-api` 的思路做了分类整理，避免设计稿继续散落在仓库根目录。

## 读取顺序

建议按以下顺序阅读：

1. [README.md](../README.md)
2. [claude.md](../claude.md)
3. [TODO.md](../TODO.md)
4. 本文档
5. 再进入具体分类文档

## 分类目录

### Architecture

| 文档 | 说明 |
|---|---|
| [architecture/integration-design.md](./architecture/integration-design.md) | 第一阶段整体集成设计与系统边界 |
| [architecture/data-model-draft.md](./architecture/data-model-draft.md) | 第一阶段核心数据模型草案 |

### API

| 文档 | 说明 |
|---|---|
| [api/allergy-api-draft.md](./api/allergy-api-draft.md) | 第一阶段前后端业务 API 草案 |

### Catalog

| 文档 | 说明 |
|---|---|
| [catalog/service-catalog-design.md](./catalog/service-catalog-design.md) | 检测项目目录、上架与价格管理设计 |
| [catalog/service-catalog-api-contract.md](./catalog/service-catalog-api-contract.md) | 检测项目目录接口契约 |
| [catalog/service-catalog-migration.md](./catalog/service-catalog-migration.md) | 检测项目目录建表与默认数据迁移方案 |
| [catalog/service-catalog-test-plan.md](./catalog/service-catalog-test-plan.md) | 检测项目目录测试计划 |

### Auth

| 文档 | 说明 |
|---|---|
| [auth/README.md](./auth/README.md) | 账号域文档导航与命名约定 |
| [auth/member-auth-design.md](./auth/member-auth-design.md) | 当前会员账号体系改造总设计 |
| [auth/member-auth-api-contract.md](./auth/member-auth-api-contract.md) | 会员认证接口契约 |
| [auth/member-auth-migration-cleanup.md](./auth/member-auth-migration-cleanup.md) | 旧会员清理与切流方案 |
| [auth/member-auth-test-plan.md](./auth/member-auth-test-plan.md) | 会员账号体系测试计划 |

### Deploy

| 文档 | 说明 |
|---|---|
| [deploy/README.md](./deploy/README.md) | 部署与发布域文档导航 |
| [deploy/cicd-design.md](./deploy/cicd-design.md) | CI/CD 与发布治理目标设计 |
| [deploy/cicd-runbook.md](./deploy/cicd-runbook.md) | CI/CD 改造后的目标运维手册 |

### Fulfillment

| 文档 | 说明 |
|---|---|
| [fulfillment/README.md](./fulfillment/README.md) | 履约域文档导航与命名约定 |
| [fulfillment/notes-and-audit-design.md](./fulfillment/notes-and-audit-design.md) | 订单备注区与操作日志区草案 |
| [fulfillment/notes-and-audit-api-contract.md](./fulfillment/notes-and-audit-api-contract.md) | 备注区与操作日志接口草案 |
| [fulfillment/notes-and-audit-test-plan.md](./fulfillment/notes-and-audit-test-plan.md) | 备注区与操作日志测试计划 |
| [fulfillment/shipping-sop-outline.md](./fulfillment/shipping-sop-outline.md) | 发货 SOP 文档骨架 |

### Payment

| 文档 | 说明 |
|---|---|
| [payment/README.md](./payment/README.md) | 支付域文档导航与命名约定 |
| [payment/refund-design.md](./payment/refund-design.md) | 退款流程草案 |
| [payment/refund-api-contract.md](./payment/refund-api-contract.md) | 退款接口草案 |
| [payment/refund-test-plan.md](./payment/refund-test-plan.md) | 退款测试计划 |

### Reconciliation

| 文档 | 说明 |
|---|---|
| [reconciliation/README.md](./reconciliation/README.md) | 对账域文档导航与命名约定 |
| [reconciliation/reconciliation-design.md](./reconciliation/reconciliation-design.md) | 支付对账与导出草案 |
| [reconciliation/reconciliation-api-contract.md](./reconciliation/reconciliation-api-contract.md) | 支付对账接口草案 |
| [reconciliation/reconciliation-test-plan.md](./reconciliation/reconciliation-test-plan.md) | 支付对账测试计划 |

## 口径说明

- `auth/` 目录是当前账号体系的最新口径
- `architecture/` 和 `api/` 目录里的登录相关章节保留了早期“邮箱验证码登录”的兼容接入思路
- 如果认证方案出现冲突，以 `auth/` 目录为准
- 新功能优先按领域沉到：
  - `docs/auth/`
  - `docs/deploy/`
  - `docs/fulfillment/`
  - `docs/payment/`
  - `docs/reconciliation/`
- 每个领域目录都放了一个 `_feature-template.md`，新功能优先从模板复制

## 根目录入口文档

- [README.md](../README.md)
- [claude.md](../claude.md)
- [TODO.md](../TODO.md)
- [DEPLOY.md](../DEPLOY.md)
