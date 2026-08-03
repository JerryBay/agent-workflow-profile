# Codex Workflow Profile

这是一个跨电脑使用的个人 Codex 与 Pi 工作流仓库，只保存与具体工程无关的长期习惯。

## 包含内容

- `AGENTS.md`：Codex 与 Pi 共用的长期个人协作规则。
- `plugins/personal-workflow`：Codex 插件与 Pi package 共用的 skills 唯一来源。
- `package.json`：把同一组 skills 注册为本地 Pi package。
- `evidence-first-local-debugging`：从真实本地证据开始诊断，并严格尊重只读边界。
- `local-repo-orientation`：在新电脑或陌生 checkout 中重新确认入口、当前基线、未验证项和下一步。
- `minimal-scope-repo-change`：按现有所有权做最小改动，并明确实际达到的验收层级。
- `architecture-aware-development`：在开发和重构中平衡高内聚低耦合、数据结构、性能风险与适度设计。
- `design-first-project-planning`：用户要求先讨论时，维护决策记录和验收标准，再进入实现。
- `windows-gui-dev-workflow`：Visual Studio、Fork、P4V、Docker Desktop 等 GUI 工具优先给出具体界面路径。

不包含任何特定项目路径、构建参数和资源配置。`local-repo-orientation` 只提供空白入口卡模板；每台电脑发现的机器值应保存在项目认可的本地文件或忽略规则中。需要团队共享的项目规则仍应保存在对应项目自己的 `AGENTS.md` 或 `.agents/skills` 中。

## 校验

只校验仓库内容，不安装或修改当前用户配置：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1 -ValidateOnly
.\install-pi.ps1 -ValidateOnly
```

校验会检查 marketplace/plugin/Pi package JSON、skill frontmatter、`agents/openai.yaml`、目录命名，以及通用内容中意外写入的 Windows 绝对工程路径。两个正常安装脚本都会先执行同一套校验。

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

## Pi Agent 安装

先确保 `pi` 命令可用，然后在 PowerShell 中运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install-pi.ps1
```

脚本会：

1. 校验仓库及共享 skills。
2. 把当前仓库注册为本地 Pi package，不复制第二份 skills。
3. 备份已有的 Pi 全局 `AGENTS.md`，再安装仓库中的版本。

Pi 默认配置目录是 `%USERPROFILE%\.pi\agent`；脚本也尊重 `PI_CODING_AGENT_DIR`。如果 `pi` 不在 `PATH` 中，可以通过 `-PiCommand` 传入可执行文件路径。完成后开启新的 Pi 会话。

## 更新

```powershell
git pull
.\install.ps1 -RefreshPlugin
.\install-pi.ps1
```

`-RefreshPlugin` 会从已注册的本地 marketplace 重新安装 Codex 插件缓存。Pi package 直接引用当前 checkout 中的共享 skills；重新运行 Pi 安装脚本会同步全局 `AGENTS.md` 并确保 package 仍已注册。

## 安全边界

不要把整个 `%USERPROFILE%\.codex` 或 `%USERPROFILE%\.pi` 目录加入版本控制。这些目录可能包含认证信息、会话数据库、日志、缓存和机器相关配置。本仓库只管理经过筛选的规则、skills 和安装元数据。Pi 安装脚本只安装工作流，不会增加沙箱或命令审批机制。
