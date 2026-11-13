# legacy

不参与 `install.sh` 的一次性/低频脚本，保留备查。

| 脚本 | 用途 |
| --- | --- |
| `lintools.sh` | 下载/编译 Linux 提权工具并打包为 `lintools.tar.gz` |
| `wintools.py` | 下载 Windows 提权工具（winPEAS/Sysinternals/Potato 等） |
| `clean-space.sh` | 一次性 Kali 空间清理（会删除内核/缓存/日志，谨慎执行） |

这些脚本按 **root 环境** 编写，直接在目标目录执行即可；使用前请确认路径与影响。
