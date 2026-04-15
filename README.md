# allergy_website

`Allergy` + `new-api` 的集成工作区，用于实现“过敏原检测服务”的前台下单、支付、后台履约与报告交付闭环。

## 项目结构

| 路径 | 作用 |
|---|---|
| `Allergy/` | 面向用户的前端站点 |
| `new-api/` | 后端底座与后台控制台 |
| `claude.md` | 当前工作区执行约束与实施口径 |
| `TODO.md` | 当前业务缺口、优先级与实施待办 |
| `DEPLOY.md` | 根仓库 Docker Compose 部署说明 |
| `docs/README.md` | 设计文档导航与文档优先级说明 |

## 快速导航

- 开工前先看：[claude.md](./claude.md)
- 当前待办与优先级：[TODO.md](./TODO.md)
- 设计文档导航：[docs/README.md](./docs/README.md)
- Docker Compose 部署：[DEPLOY.md](./DEPLOY.md)
- `new-api` 仓库级规则：[new-api/CLAUDE.md](./new-api/CLAUDE.md)

## 文档优先级

当文档之间出现冲突时，按以下优先级理解：

1. `claude.md`
2. `TODO.md`
3. `docs/auth/*`
4. `docs/architecture/*` 与 `docs/api/*`
5. 子仓库自身文档，例如 `new-api/CLAUDE.md`

说明：

- `docs/auth/*` 是当前会员账号体系的最新方案
- `docs/architecture/*` 和 `docs/api/*` 保留了第一阶段兼容接入设计，认证章节若与 `docs/auth/*` 冲突，以 `docs/auth/*` 为准

## 当前文档组织

```text
.
├── README.md
├── claude.md
├── TODO.md
├── DEPLOY.md
├── docs/
│   ├── README.md
│   ├── architecture/
│   ├── api/
│   ├── auth/
│   ├── fulfillment/
│   ├── payment/
│   └── reconciliation/
├── Allergy/
└── new-api/
```
