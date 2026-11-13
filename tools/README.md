# tools

自研/整理脚本与工具来源清单。仓库不再随带第三方二进制，需要时按下面的上游地址获取。

```text
tools/
├── python/   # Python 脚本（含自研与整理的第三方小工具）
├── shell/    # Shell / Perl 脚本
└── jar/      # 保留的小型 JAR 工具
```

GitHub Release 工具优先通过 [ghr](https://github.com/cataggar/ghr) 安装，
清单在 `scripts/ghr-tools.txt`（`./scripts/install-gh-tools.sh`）。

本地临时下载的二进制可放在 `tools/bin/`（已被 `.gitignore` 忽略），或直接安装到
`/usr/local/bin`。

## 优先使用 Kali apt

新版 Kali 已打包以下工具，优先 `apt install`，避免重复携带二进制：

```bash
apt install rustscan feroxbuster ffuf gobuster ttyd chisel miniserve
```

ProjectDiscovery（nuclei / subfinder / httpx / naabu）也由 ghr 统一管理，
见 `scripts/ghr-tools.txt`；Kali apt 中同样打包了其中多数工具。

## 已移除的第三方二进制

| 工具 | 上游仓库 |
| --- | --- |
| bkcrack | https://github.com/kimci86/bkcrack |
| fscan | https://github.com/shadow1ng/fscan |
| gogo | https://github.com/chainreactors/gogo |
| gost | https://github.com/go-gost/gost |
| hostCollision | https://github.com/alwaystest18/hostCollision |
| kerbrute | https://github.com/ropnop/kerbrute |
| mdxfind | https://github.com/Cynosureprime/mdxfind |
| miniserve | https://github.com/svenstaro/miniserve |
| morefind | https://github.com/mstxq17/MoreFind |
| netspy | https://github.com/shmilylty/netspy |
| nomore403 | https://github.com/devploit/nomore403 |
| redis_rce | https://github.com/zyylhn/redis_rce |
| Rogue-MySql-Server | https://github.com/Gifts/Rogue-MySql-Server |
| RustHound-CE | https://github.com/g0h4n/RustHound-CE |
| RustScan | https://github.com/RustScan/RustScan |
| spray | https://github.com/chainreactors/spray |
| Stowaway | https://github.com/ph4ntonn/Stowaway |
| ttyd | https://github.com/tsl0922/ttyd |
| URLFinder | https://github.com/pingc0y/URLFinder |
| Venom | https://github.com/Dliv3/Venom |
| websocat | https://github.com/vi/websocat |
| zombie | https://chainreactors.github.io/wiki/zombie |
| zsteg | https://github.com/zed-0xff/zsteg |
| ripgrep-all（rga / rga-fzf / rga-preproc） | https://github.com/phiresky/ripgrep-all |
| JNDI-Injection-Exploit | https://github.com/welk1n/JNDI-Injection-Exploit |
| ysoserial | https://github.com/frohoff/ysoserial |
| revshell | 作者 Gh0stX（上游仓库未收录） |

## 第三方源码（原 tools/src）

按需浅克隆，不再作为子模块：

```bash
mkdir -p tools/src
git clone --depth 1 https://github.com/fortra/impacket tools/src/impacket
```

| 项目 | 上游仓库 |
| --- | --- |
| impacket | https://github.com/fortra/impacket |
| jwt_tool | https://github.com/ticarpi/jwt_tool |
| phpggc | https://github.com/ambionics/phpggc |
| SSTImap | https://github.com/vladko312/SSTImap |
| keepass2john | https://github.com/ivanmrsulja/keepass2john |
| gr33n37-ip-changer | https://github.com/gr33n37/gr33n37-ip-changer |

## 脚本来源

`tools/python` / `tools/shell` 中整理了部分第三方小脚本，主要来源：

| 脚本 | 上游 |
| --- | --- |
| abspath、csv2sql、lsbin 等小工具 | https://github.com/nil0x42/scripts |
| gtfobins-cli.py | https://github.com/t0thkr1s/gtfobins-cli |
| hashgrab.py | https://github.com/xct/hashgrab |
| SSRF2gopher.py | https://github.com/eMVee-NL/SSRF2gopher |
| finger-user-enum.pl | https://github.com/pentestmonkey/finger-user-enum |
| firefox_decrypt.py | https://github.com/unode/firefox_decrypt |
| gMSADumper.py | https://github.com/micahvandeusen/gMSADumper |
| php_filter_chain_generator.py | https://github.com/synacktiv/php_filter_chain_generator |
| spose.py | https://github.com/aancw/spose |
| ADGenerator.py | https://github.com/dievus/ADGenerator |
