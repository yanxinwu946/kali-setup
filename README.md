# kali-setup

个人渗透测试环境快速部署工具箱，用于在新环境中快速恢复常用工具、配置与脚本。

## 核心目标

- **快速恢复环境**：新装系统后，一条命令完成基础依赖、工具与配置初始化。
- **配置即代码**：`dotfiles/` 按 `$HOME` 路径组织，新增配置只需放到对应位置。
- **不夹带第三方体积**：`tools/bin` 二进制、`third_party` 源码仓库、
  Sysinternals/SharpCollection 以及 ghr 管理的后渗透二进制不随仓保留；
  上游地址见 `tools/README.md`、`dicts/README.md`、`payloads/REFERENCES.md`。

## 快速开始

```bash
cd ~
# 仓库名为 kali-setup；脚本默认路径是 ~/pentest，克隆时指定目录
git clone https://github.com/yanxinwu946/kali-setup ~/pentest
cd ~/pentest
sudo ./install.sh
```

安装完成后执行：

```bash
source ~/.zshrc
```

## 运行环境（root）

本仓库按 **root 单用户环境** 设计：

- 以 root 执行 `install.sh`（脚本会检查 `EUID`），建议直接登录 root 或 `sudo ./install.sh`
- 默认 `HOME=/root`，`dotfiles/` 下发到 `/root`
- 会写入 `/usr/local/bin`、`/usr/local/share/zsh/site-functions`、`/etc/apt`、`/etc/ssh` 等系统位置
- ghr / fnm / uv 工具安装在 `/root/.local/bin`、`/root/.local/share`
- 非 root 用户需自行调整路径与权限，不保证开箱即用

## 目录结构

```text
.
├── install.sh      # 一键部署入口
├── dotfiles/       # 按 $HOME 路径组织的配置
├── scripts/        # install.sh 使用的安装/配置脚本
├── legacy/         # 不参与安装的低频脚本
├── tools/          # 自研/整理的 Python、Shell、JAR 工具
├── dicts/          # 随仓小字典与第三方地址
└── payloads/       # 载荷、隧道工具与来源说明
```

`third_party/`、`tools/src/`、`tools/bin/` 等本地第三方副本不参与仓库管理。

## install.sh 做了什么

`install.sh` 默认会执行以下流程（需 root）：

1. 切换 Kali apt 镜像源（默认清华 TUNA，可 `--skip mirror` 跳过）
2. 安装系统依赖与常用 CLI（htop/btop/rustscan/ncdu/zoxide/yq/shellcheck/lazygit/httpie 等，只装缺失项）
3. 通过 **ghr** 安装 GitHub 工具：`gh`、`yazi`、`zellij`、ProjectDiscovery 全家桶（清单见 `scripts/ghr-tools.txt`）
4. 通过 **ghr** 下载后渗透载荷：chisel/gost/ligolo/stowaway/socat/winPEAS（清单见 `scripts/ghr-payloads.txt`）
5. 将系统语言切换为简体中文；终端输出由 `.zshenv` 固定为英文
6. 遍历 `dotfiles/`，按 `$HOME` 相对路径下发配置
7. 依次执行 `scripts/` 下初始化脚本（OMZ / zellij / gdb）
8. 将 pentest 环境注入 `~/.zshrc`（必须在 oh-my-zsh 之后，否则会被覆盖）
9. 安装 **fnm** 并设置 Node.js LTS（下载走 npmmirror）
10. 通过 `uv` 安装常用 Python 工具
11. 安装 **JetBrains Maple Mono Nerd Font**（已安装则跳过）
12. 开启 root SSH 登录（写入 `sshd_config.d` drop-in，自动校验/回滚）
13. 整理脚本执行权限

> **终端语言**：系统与图形界面保持简体中文；`~/.zshenv` 将
> `LANG/LANGUAGE/LC_ALL` 固定为 `en_US.UTF-8`，对所有 zsh 调用生效
> （交互式、非交互式、ssh 远程命令）。恢复中文终端可注释 `dotfiles/.zshenv` 中三行。

> **终端工具**：btop 与 yazi 统一使用 Catppuccin Mocha 主题（与 kitty 一致）。
> 在终端执行 `y` 启动 yazi，退出后自动回到它所在目录。

### 安装选项

```bash
./install.sh --skip gh-tools,payloads,fonts # 快速恢复：跳过下载类步骤
./install.sh --skip mirror,locale         # 保留官方源和英文环境
./install.sh --skip node                  # 不安装 fnm / Node.js
./install.sh --only fonts,ssh             # 只补装字体、开启 root SSH
./install.sh --force-fonts                # 强制重新安装字体
./install.sh --ssh-root prohibit-password # 仅允许 root 密钥登录
./install.sh --help                       # 查看全部步骤与参数
```

步骤名：`mirror,deps,gh-tools,payloads,locale,dotfiles,init,zshrc,node,uv,fonts,ssh,perms`。

> **安全提示**：`--ssh-root yes`（默认）允许 root 密码登录，仅建议在授权测试环境或内网使用。
> 暴露公网的主机建议使用 `--ssh-root prohibit-password`，并提前配置 root 的
> `~/.ssh/authorized_keys`。

## 语言环境

不使用跨语言的 shim/版本管理器，避免 GUI 应用和 SSH 会话里 PATH 失效：

| 语言 | 方案 |
| --- | --- |
| C/C++ | 系统 apt 工具链 |
| Go | 官方工具链自带 `go`，无需版本管理器 |
| Rust | rustup/自带工具链 |
| Python | `uv`（项目与工具） |
| Java | IDEA 管理 JDK；系统安装一个常用 JDK 即可 |
| Node.js | `fnm`（`--use-on-cd` 按 `.node-version` / `.nvmrc` / `package.json` 自动切换） |
| Ruby | 系统版本（Metasploit 依赖） |

```bash
./scripts/install-fnm.sh    # 安装 fnm + 最新 Node LTS
fnm list                    # 已安装版本
fnm default lts-latest      # 设置全局默认
fnm use 22                  # 当前 shell 临时切换
```

Node 下载默认走 npmmirror（`FNM_NODE_DIST_MIRROR`）。Python 工具仍由
`./scripts/install-uv-tools.sh` 管理；系统 `python3` 保持 apt 版本，避免遮蔽
pwntools、bloodyad 等依赖。

## 配置约定

- `dotfiles/` 直接镜像 `$HOME`：`dotfiles/.zshenv` → `~/.zshenv`，
  `dotfiles/.config/kitty/kitty.conf` → `~/.config/kitty/kitty.conf`。
  新增配置只需按家目录路径放置，无需修改安装脚本。
- `scripts/` 平铺所有 active 脚本，命名约定：
  `setup-*` 系统/环境配置、`install-*` 安装软件、`_common.sh` 共享日志函数。
- `legacy/` 放不参与安装的一次性/低频脚本。
- 脚本只在自身目录内解析 `_common.sh`，`PENTEST_DIR` 默认取仓库根目录。

## GitHub 工具（ghr）

GitHub Release 工具统一由 [ghr](https://github.com/cataggar/ghr) 安装和校验，
清单在 `scripts/ghr-tools.txt`：

```text
cli/cli                          # GitHub CLI
Schniz/fnm                       # Node.js 版本管理器
sxyazi/yazi                      # 文件管理器（yazi + ya）
zellij-org/zellij                # 终端复用器
projectdiscovery/nuclei
projectdiscovery/subfinder
projectdiscovery/httpx
projectdiscovery/naabu
```

```bash
./scripts/install-gh-tools.sh            # 只装缺失项
./scripts/install-gh-tools.sh --force    # 更新 ghr 和全部工具
ghr list --full                          # 查看已安装工具
```

- ghr 与工具安装在 `~/.local/bin`，无需 root（`~/.local/bin` 已在 PATH 中）
- 添加工具：在 `scripts/ghr-tools.txt` 增加一行 `owner/repo[@tag]`
- yazi 的 zsh 补全会自动从 ghr 工具目录补装到 `/usr/local/share/zsh/site-functions`

## 后渗透载荷（ghr）

隧道/后渗透二进制同样由 ghr 下载，清单在 `scripts/ghr-payloads.txt`：

```text
chisel / gost / ligolo-ng / stowaway / socat   # linux + windows
winPEASx64                                      # windows 提权
```

```bash
./scripts/install-payloads.sh            # 只下载缺失项
./scripts/install-payloads.sh --force    # 重新下载/更新全部
```

下载到 `payloads/tunnel/<工具>/` 与 `payloads/windows/privesc/`，这些二进制不入库。
其余自研/小型载荷（revshell、windows 脚本等）仍随仓库保留。

## 工具与第三方内容

仓库不再同步或随带 `third_party/` 内容：

- `scripts/ghr-tools.txt`：GitHub 工具清单（ghr 统一管理）
- `scripts/ghr-payloads.txt`：后渗透载荷清单（ghr 统一下载）
- `tools/README.md`：已移除二进制的上游仓库、Kali apt 替代安装方式
- `dicts/README.md`：第三方字典仓库地址
- `payloads/REFERENCES.md`：已清理的 Sysinternals、SharpCollection、ll-privesc-kit 等来源
- 本地已存在的 `third_party/` 不会被删除，但已被 `.gitignore` 忽略

新版 Kali 已打包 `rustscan`、`feroxbuster`、`ffuf`、`gobuster`、`ttyd`、`chisel`、
`miniserve` 等系统工具，优先使用 apt；GitHub Release 工具统一交给 ghr 管理。

## 常用维护命令

```bash
cd ~/pentest
./scripts/setup-kali-mirror.sh        # 切换 Kali apt 镜像（--mirror tuna|ustc|aliyun|huawei|official）
./scripts/setup-locale-zh.sh          # 系统语言改为简体中文并安装 Noto CJK 字体
./scripts/install-gh-tools.sh         # 通过 ghr 安装/更新 GitHub 工具（--force 更新全部）
./scripts/install-payloads.sh         # 通过 ghr 下载后渗透载荷（--force 更新全部）
./scripts/install-fnm.sh              # 安装 fnm 并设置 Node.js LTS
./scripts/install-uv-tools.sh         # 单独安装/更新 uv Python 工具
./scripts/install-fonts.sh            # 安装字体并写入 qterminal 字体（--force 强制重装）
./scripts/setup-ssh.sh                # 单独配置 root SSH（--root-login yes|prohibit-password|no）
./tools/shell/pe [-i IP] [-p PORT]    # payloads/ 目录起 HTTP 服务器 + fzf 选文件传靶机
```

低频脚本放在 `legacy/`，不参与 `install.sh`：

```bash
./legacy/lintools.sh                  # 下载/编译 Linux 提权工具并打包成 lintools.tar.gz
./legacy/wintools.py                  # 下载 Windows 提权工具（winPEAS/Sysinternals/Potato 等）
./legacy/clean-space.sh               # 清理系统空间（谨慎执行）
```

## 免责声明

本仓库仅用于**授权范围内**的安全测试与学习研究。使用者需对自身行为负责，
因滥用造成的任何后果与作者无关。
