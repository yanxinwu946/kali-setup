# 参考：已清理的 GitHub 现成批量工具

以下工具因体积大且 GitHub 直接可获取，不再保留二进制文件。

> 隧道 / 后渗透二进制（chisel、gost、ligolo、stowaway、socat、winPEAS）现由
> `scripts/ghr-payloads.txt` 定义，执行 `./scripts/install-payloads.sh` 通过 ghr 下载。

## Linux — staticBins（已清理，85MB）

静态编译工具箱（binutils / nmap / python / tcpdump / strace / ag 等），
全部可从 GitHub 直接下载，按需获取。

| 工具 | 说明 | 仓库 |
|------|------|------|
| 静态 binutils (arm/x64) | ld, objcopy, nm, strings, objdump, readelf… | https://github.com/nickczj/static-binutils |
| 静态 nmap / nping | 端口扫描 | https://github.com/andrew-d/static-binaries |
| 静态 Python | Python 解释器 | https://github.com/niess/python-build-standalone |
| 静态 tcpdump / strace | 网络抓包 / 系统调用跟踪 | https://github.com/andrew-d/static-binaries |
| ag (The Silver Searcher) | 代码搜索 | https://github.com/ggreer/the_silver_searcher |

## Windows — 已清理的批量工具

| 工具 | 说明 | 来源 |
|------|------|------|
| Sysinternals Suite | 全套 Windows 系统工具（118MB） | https://learn.microsoft.com/sysinternals/downloads/sysinternals-suite |
| SharpCollection | C# 攻防工具集（4.4MB） | https://github.com/Flangvik/SharpCollection |

## Linux — ll-privesc-kit

| 工具 | 说明 | 仓库 |
|------|------|------|
| ll-privesc-kit | Linux 提权工具集（原 `payloads/linux` 子模块） | https://github.com/yanxinwu946/ll-privesc-kit |

```bash
git clone --depth 1 https://github.com/yanxinwu946/ll-privesc-kit payloads/linux/ll-privesc-kit
```
