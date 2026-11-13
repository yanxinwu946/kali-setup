# Tunnel Tools

隧道/代理工具集。二进制由 ghr 按需下载，不随仓库保留。

## 工具一览

| 工具 | 架构 | 说明 | 双端 |
|------|------|------|------|
| **chisel** | 单文件双端合一 | HTTP 隧道，支持反向/正向，自带 SOCKS5 | linux + windows |
| **gost** | 单文件双端合一 | 多协议隧道（TCP/UDP/WS/mTLS…） | linux + windows |
| **ligolo-ng** | proxy=server, agent=client | Layer 3 网络隧道，直接路由整段内网 | proxy(linux) + agent(linux/windows) |
| **stowaway** | admin=server, agent=client | 多级代理，支持 shell/socks5/端口映射 | linux + windows |
| **socat** | 单文件 | 端口转发/反弹 Shell | linux + windows |
| **nc** | 单文件 | 网络调试/文件传输 | windows（随仓库保留） |

## 下载 / 更新

清单在 `scripts/ghr-payloads.txt`，由 ghr 下载并校验：

```bash
./scripts/install-payloads.sh            # 只下载缺失项
./scripts/install-payloads.sh --force    # 重新下载/更新全部
```

下载后的文件：

```text
chisel/     chisel_linux  chisel.exe
gost/       gost_linux    gost.exe
ligolo/     proxy_linux   agent_linux  agent.exe
stowaway/   stowaway_admin  stowaway_agent_linux
            stowaway_admin.exe  stowaway_agent.exe
socat/      socat_linux   socat.exe
nc/         nc.exe
```

## 快速使用

```bash
ls payloads/tunnel/*/
payloads/tunnel/chisel/chisel_linux --help
payloads/tunnel/gost/gost_linux -h
payloads/tunnel/ligolo/proxy_linux --help
```

## 文件传输

在 `payloads/` 目录启动 HTTP 服务后，目标机可直接下载：

```bash
payloads/serve.sh        # 或使用 pe（fzf 选择文件）
```

## 注意

- ligolo-ng 需要先 `ip tuntap add` 创建虚拟网卡，见 `tools/shell/ligo` 脚本
