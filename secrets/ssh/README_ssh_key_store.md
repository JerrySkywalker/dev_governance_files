# SSH 私钥保管区治理规则

## 1. 定位

SSH 私钥属于高敏感、低变更、强权限约束的本机凭据。

本仓库只管理 SSH 私钥的目录规则、权限脚本、配置模板和操作流程，不保存任何真实私钥。

推荐本机路径：


C:\Dev\secrets\ssh

推荐 OpenSSH 配置入口：

%USERPROFILE%\.ssh\config
2. 目录职责
C:\Dev\secrets\ssh

用于保存本机实际使用的 SSH 明文私钥，例如：

C:\Dev\secrets\ssh\beijing.pem
C:\Dev\secrets\ssh\github_id_ed25519

要求：

使用 NTFS。
禁止继承宽权限。
禁止 BUILTIN\Users、Everyone、Authenticated Users 访问。
默认仅当前用户、SYSTEM、Administrators 可访问。
不放入 OneDrive、Git 仓库或公共同步目录。
%USERPROFILE%\.ssh

用于保存 OpenSSH 标准配置入口，例如：

%USERPROFILE%\.ssh\config
%USERPROFILE%\.ssh\known_hosts

config 中通过 IdentityFile 指向 C:\Dev\secrets\ssh 中的私钥。

3. 不建议放在 OneDrive 的原因

不建议将明文私钥放入：

C:\Users\<user>\OneDrive\Documents\ssh_key

原因：

云同步扩大暴露面。
OneDrive 可能产生历史版本、冲突副本和回收站残留。
Documents / OneDrive 的 ACL 与同步客户端行为更复杂。
Windows OpenSSH 会拒绝权限过宽的私钥。

OneDrive 只适合保存：

SSH 使用说明。
公钥。
加密后的私钥备份。
服务器清单。
4. 初始化

在本仓库根目录执行：

pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1

迁移已有私钥：

pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1 -SourceKey "C:\Dev\ssh_key\beijing.pem"
5. SSH config 示例

编辑：

notepad "$env:USERPROFILE\.ssh\config"

写入：

Host beijing
    HostName example.com
    User root
    IdentityFile C:/Dev/secrets/ssh/beijing.pem
    IdentitiesOnly yes

连接：

ssh beijing

检查 OpenSSH 是否读取到配置：

ssh -G beijing | Select-String "hostname|user|identityfile|identitiesonly"
6. 权限检查

检查私钥权限：

icacls "C:\Dev\secrets\ssh\beijing.pem"

不应出现：

BUILTIN\Users
Everyone
Authenticated Users

可接受：

当前用户
SYSTEM
Administrators
7. 绝对禁止

禁止提交以下内容到 Git：

*.pem
*.key
id_rsa
id_dsa
id_ecdsa
id_ed25519

本仓库 .gitignore 应持续覆盖上述模式。
