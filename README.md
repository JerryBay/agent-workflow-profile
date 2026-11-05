# Agent Workflow Profile

这是一个跨电脑使用的个人 Codex、Pi 与 DeepSeek Harness 工作流仓库，只保存与具体工程无关的长期习惯。

## 包含内容

- `AGENTS.md`：三个工具共用的长期个人协作规则。
- `plugins/personal-workflow`：Codex 插件、Pi package 与 DeepSeek Harness 共用的 skills 唯一来源。
- `package.json`：把同一组 skills 注册为本地 Pi package。
- `evidence-first-local-debugging`：从真实本地证据开始诊断，并严格尊重只读边界。
- `local-repo-orientation`：在新电脑或陌生 checkout 中重新确认入口、当前基线、未验证项和下一步。
- `minimal-scope-repo-change`：按现有所有权做最小改动，并明确实际达到的验收层级。
- `architecture-aware-development`：在开发和重构中平衡高内聚低耦合、数据结构、性能风险与适度设计。
- `design-first-project-planning`：复杂功能或重要技术选择先提交方案，集中确认实现方式、边界条件和验收标准；也用于用户明确要求先讨论的任务。
- `project-memory-maintenance`：仅在明确要求时初始化工程记忆，并在已接入项目中按实质影响维护、审计或显式升级长期项目事实。
- `windows-gui-dev-workflow`：桌面的 GUI 工具使用优先给出具体界面路径。

不包含任何特定项目路径、构建参数和资源配置。`local-repo-orientation` 只提供空白入口卡模板；每台电脑发现的机器值应保存在项目认可的本地文件或忽略规则中。需要团队共享的项目规则仍应保存在对应项目自己的 `AGENTS.md` 或 `.agents/skills` 中。

复杂功能即使直接提出“实现”，也会先检查现有代码，再提交模块归属、执行流程、数据与生命周期、重要边界和兼容行为、方案取舍及验证方式，等待技术方案确认。未确认点集中列出，支持 annotation；已确认的决定不重复询问。实施中发现新的重要选择时，只暂停依赖该选择的部分。

小型、明确、可逆且不涉及上述实质影响的修改继续走快速通道，无需计划文档或额外审批。判断依据是行为和风险，不是代码行数；例如局部文案修改可直接做，而一行兼容条件变更仍可能需要先确认。

## 校验

只校验仓库内容，不安装或修改当前用户配置：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1 -ValidateOnly
.\install-pi.ps1 -ValidateOnly
.\install-dsh.ps1 -ValidateOnly
```

校验会检查 marketplace/plugin/Pi package JSON、skill frontmatter、`agents/openai.yaml`、目录命名，以及通用内容中意外写入的 Windows 绝对工程路径。三个正常安装脚本都会先执行同一套校验。

## 新电脑安装

克隆仓库后，在 PowerShell 中运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

脚本会：

1. 备份新电脑上已有的 `%USERPROFILE%\.codex\AGENTS.md`。
2. 安装仓库中的全局 `AGENTS.md`。
3. 注册 `agent-workflow-profile` marketplace。
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

## DeepSeek Harness 安装

克隆仓库后，在仓库目录执行以下命令即可安装个人规则和 skills：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-dsh.ps1
```

脚本使用复制方式，无需管理员权限或 Windows 链接，也不依赖 Codex marketplace：

1. 校验共享规则与全部 skills 的 `SKILL.md`、`name`、`description`。
2. 备份并同步全局 `AGENTS.md` 到 `%USERPROFILE%\.dsh\AGENTS.md`。
3. 将共享 skills 按名称复制到 `%USERPROFILE%\.dsh\skills\`，包括 references、scripts、assets 等配套文件，并逐文件核对 SHA-256。
4. 内容相同时跳过；已有同名 skill 内容不同时，普通安装会在写入前停止，使用 `-Refresh` 才会备份并替换。

安装目录优先级为 `-DshHome` 参数、`DSH_HOME` 环境变量、`%USERPROFILE%\.dsh`。显式指定目录只决定本次复制位置；DSH 本身也需要使用相同的 `DSH_HOME`。脚本拒绝替换链接路径，也不允许把目标设为本仓库根目录或共享 skills 源目录内部。`-SkipAgents` 或 `-SkipSkills` 可只同步其中一部分，`-ValidateOnly` 仅校验仓库，不创建目标目录。

```powershell
# 同步仓库更新，或恢复被修改的同名 skills
.\install-dsh.ps1 -Refresh

# 指定目标，例如隔离配置目录
.\install-dsh.ps1 -DshHome "$env:USERPROFILE\.dsh-work"
```

旧文件保存在目标目录的 `workflow-profile-backups\<时间戳与唯一编号>\` 中，保留原相对路径。刷新会完整替换本仓库当前包含的同名 skill 目录，包括移除其旧配套文件；同名平铺 `<skill-name>.md` 冲突需先处理。其他 skills、配置、账号和会话不变；仓库已删除或改名的旧 skill 不会自动清理。

完成后开启新的 DSH 会话以加载全局规则。默认发现路径依据官方 [agent-instructions](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/context/agent-instructions/README.md) 和 [skill-filesystem](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/skill/skill-filesystem/README.md) 文档；自定义预设必须启用对应插件。文件安装和 hash 校验成功，不代表已确认某次会话实际加载了规则或触发了 skill。

此入口只安装工作流，不安装 DSH 本体、不配置模型或密钥、不更改权限或 Agent 预设。隔离安装测试可运行：

```powershell
.\tests\test-dsh-installation.ps1
```

## 更新

```powershell
git pull
.\install.ps1 -RefreshPlugin
.\install-pi.ps1
.\install-dsh.ps1 -Refresh
```

`-RefreshPlugin` 会从已注册的本地 marketplace 重新安装 Codex 插件缓存。Pi package 直接引用当前 checkout 中的共享 skills；重新运行 Pi 安装脚本会同步全局 `AGENTS.md` 并确保 package 仍已注册。

按实际使用的工具选择安装入口即可。DeepSeek Harness 使用独立副本，拉取更新后运行 `install-dsh.ps1 -Refresh` 同步。

## 安全边界

不要把整个 `%USERPROFILE%\.codex`、`%USERPROFILE%\.pi` 或 `%USERPROFILE%\.dsh` 目录加入版本控制。这些目录可能包含认证信息、会话数据库、日志、缓存和机器相关配置。本仓库只管理经过筛选的规则、skills 和安装元数据。Pi 和 DeepSeek Harness 安装脚本只安装工作流，不会增加沙箱或命令审批机制。
