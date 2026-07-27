# Codex Workflow Profile

这是一个跨电脑使用的个人 Codex 工作流仓库，只保存与具体工程无关的长期习惯。

## 包含内容

- `AGENTS.md`：始终生效的个人协作规则。
- `plugins/personal-workflow`：可安装的通用工作流插件。
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
```

校验会检查 marketplace/plugin JSON、skill frontmatter、`agents/openai.yaml`、目录命名，以及通用内容中意外写入的 Windows 绝对工程路径。正常安装也会先执行同一套校验。

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

`-RefreshPlugin` 会从已注册的本地 marketplace 重新安装插件缓存，并备份已有全局规则。

## 安全边界

不要把整个 `%USERPROFILE%\.codex` 目录加入版本控制。该目录可能包含认证信息、会话数据库、日志、缓存和机器相关配置。本仓库只管理经过筛选的规则、skills 和安装元数据。
