# Codex Workflow Profile

这是一个跨电脑使用的个人 Codex 工作流仓库，只保存与具体工程无关的长期习惯。

## 包含内容

- `AGENTS.md`：始终生效的个人协作规则。
- `plugins/personal-workflow`：可安装的通用工作流插件。
- `evidence-first-local-debugging`：从真实本地证据开始诊断，并严格尊重只读边界。
- `minimal-scope-repo-change`：按现有所有权做最小改动，并使用项目真实路径验证。
- `design-first-project-planning`：用户要求先讨论时，保持设计先行并维护活需求文档。
- `windows-gui-dev-workflow`：Visual Studio、Fork、P4V、Docker Desktop 等 GUI 工具优先给出具体界面路径。

不包含任何特定项目路径、构建参数和资源配置。项目规则应保存在对应项目自己的 `AGENTS.md` 或 `.agents/skills` 中。

## 新电脑安装

克隆仓库后，在 PowerShell 中运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

脚本会：

1. 备份新电脑上已有的 `%USERPROFILE%\.codex\AGENTS.md`。
2. 安装仓库中的全局 `AGENTS.md`。
3. 注册 `codex-workflow-profile` marketplace。
4. 安装 `personal-workflow` 插件。

完成后重启 Codex 或开启一个新对话。

## 更新

```powershell
git pull
.\install.ps1 -RefreshPlugin
```

`-RefreshPlugin` 会重新安装插件缓存。脚本仍会先刷新 marketplace，并备份已有全局规则。

## 安全边界

不要把整个 `%USERPROFILE%\.codex` 目录加入版本控制。该目录可能包含认证信息、会话数据库、日志、缓存和机器相关配置。本仓库只管理经过筛选的规则、skills 和安装元数据。
