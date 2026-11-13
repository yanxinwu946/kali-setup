# WebShell 绕过指南 

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
