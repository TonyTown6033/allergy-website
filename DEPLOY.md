# Docker Compose 部署

这个目录下的 `docker-compose.yml` 用来同时启动：

- 过敏检测前端站点 `Allergy`
- `new-api` 后端

## 0. 拉取代码

根仓库使用 Git submodule 管理前端和后端代码，拉取时要带上子模块：

```bash
git clone --recurse-submodules https://github.com/TonyTown6033/allergy-website.git
cd allergy-website
```

如果已经 clone 过根仓库，再执行一次：

```bash
git submodule update --init --recursive
```

## 1. 准备环境变量

```bash
cp .env.example .env
```

至少要把下面这个值改掉：

```text
SESSION_SECRET=替换成随机长字符串
```

可选项：

- `BACKEND_PORT`：后端对外端口，默认 `24300`
- `FRONTEND_PORT`：前端对外端口，默认 `24880`
- `FRONTEND_API_URL`：默认 `same-origin`，表示前端通过同域 `/api` 反代访问后端
- `CRYPTO_SECRET`：不填时后端会回退为 `SESSION_SECRET`

## 2. 启动

```bash
docker compose up -d --build
```

## 3. 访问地址

- 前台站点：`http://<服务器IP>:24880`
- 后台管理：`http://<服务器IP>:24300/login`
- 后台设置页：`http://<服务器IP>:24300/console`

## 4. 数据目录

后端 SQLite 数据、上传内容和日志会落在：

```text
./docker-data/new-api
```

这意味着重建容器不会清空业务数据。

## 5. 支付回调注意事项

如果要接真实支付：

- `CustomCallbackAddress` 要填公网可访问的后端地址
- 例如：`http://your-domain-or-ip:24300`
- 不能填 `localhost`

## 6. 常用命令

查看日志：

```bash
docker compose logs -f
```

停止服务：

```bash
docker compose down
```

仅重启前端：

```bash
docker compose up -d --build allergy-web
```
