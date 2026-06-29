# AGENTS.md

## Project

Flutter monorepo — 智能设备能力库平台（眼镜/手表/耳机等多 App）。  
Dart SDK `^3.12.2`，Dart workspaces（无 Melos），~30 个 App。  
**当前阶段：规范先行。** 4 个 core 包已建成，首个 feature 待建。

---

## 0. 收到任务的第一步：建立候选池

**不要扫描整个 repo。** 先读 project_map，建立候选空间，再自主决定加载范围。

```
harness/map/project_map.json   ← 候选池来源（signals 语义标签 + 依赖图）
harness/map/flow_index.json    ← 跨包流程索引（流程不清时读）
harness/map/api_index.json     ← 公开接口速查（需要确认签名时读）
```

**三步上下文策略：**

**Step 1 — 语义匹配候选包**  
用任务描述的关键词匹配各包的 `signals` 字段，得到候选包列表（已按相关性排序）。  
或直接运行：`dart run harness/runtime/context_loader.dart "<task>"`

**Step 2 — 自主决定加载范围**  
根据任务复杂度选择加载深度，只读 barrel 文件（`lib/<package>.dart`），不读 `src/`：
- 小改动 / 单包 bug → 加载 1 个候选包
- 跨包流程 / 接口变更 → 加载候选包 + 其 `depends_on`（最多 2 层）
- 错误无法被候选包解释时 → 允许扩展，见下方扩展规则

**Step 3 — 受约束的扩展（仅在必要时）**  
以下情况允许加载 project_map 候选范围之外的文件：
- 错误栈指向候选包之外的文件
- 测试失败明确涉及跨包边界问题
- 候选上下文不足以理解错误原因

扩展时：加载最少必要文件，不做全库扫描，不加载与错误无关的包。

---

## 1. Repo layout

```
apps/<name>/           ← App 壳层：品牌 + 路由 + 首页拼装 + App 专属逻辑
packages/feature/      ← 业务能力：data → logic → UI 闭环
packages/common/       ← 共享 UI + 模型（≥2 feature 重复后提取）
packages/core/         ← 基础类型 + 平台能力封装（Provider 注入 + 默认实现）
specs/capabilities/    ← 平台能力接口规范（规范先于代码，权威来源）
specs/cross-cutting/   ← 权限 / 主题 / 多语言规范
app_configs/           ← 每个 App 的 yaml 配置
harness/               ← Agent 执行系统（本文件所在位置）
```

**依赖方向（严格单向）：** `apps` → `feature/common/core`，`feature` → `common/core`。  
Package 不可反向依赖 App，Feature 不 import 其他 Feature 的 `src/`。

---

## 2. Common commands

```bash
flutter pub get                                           # 解析 workspace 依赖
tool/scaffold.sh <name> core|common|feature [--template] # 新建包
dart analyze .                                           # 严格 lint + 类型检查
flutter test packages/<layer>/<name>/                    # 单包测试
cd apps/<name> && flutter run                            # 运行单个 App
dart run harness/runtime/context_loader.dart <task>      # 加载最小上下文
```

---

## 3. Decision tree — 任务路由

```
任务涉及…
├── 新平台能力（BLE / 网络 / 存储 / 权限…）
│     → 先写 specs/capabilities/<name>.md（接口契约）
│       再建 packages/core/<name>/（实现）
│       参考：specs/ 现有规范格式
│       ⚠️ 有原生代码 → plugin 类型；纯 Dart → package 类型
│
├── 新业务能力（feature）
│     → 直接建 packages/feature/<name>/
│       不预建 core 抽象；第二个 consumer 出现时再提取到 core
│       跨包状态共享 → 经 Core Provider，禁止 Feature 直接 import Feature
│
├── 新 App
│     → 写 app_configs/<name>.yaml
│       → flutter create apps/<name>
│       → 手写 pubspec 依赖（generate_app.dart 未完成，暂不使用）
│       → 写壳层 apps/<name>/lib/app_shell/
│
├── 原生封装（BLE / 经典蓝牙 / 厂商 SDK / HTTP）
│     → 读 harness/skills/native-to-flutter-bridge/SKILL.md
│       按通信类型加载对应 references/
│
├── 共享 UI / 模型
│     → 确认 ≥2 feature 已重复使用 → 提取到 packages/common/
│       单 feature 使用 → 留在该 feature 内
│
└── 修改现有包
      → 先读 project_map.json 确认影响范围
        再读 specs/ 对应规范，代码改动不得违反接口契约
        改动最小化：只修改必要行，不做无关重构
```

---

## 4. Hard rules（违反即拒绝执行）

| # | 规则 |
|---|------|
| R1 | 依赖方向单向：App → Feature/Common/Core。Feature 不 import Feature `src/` |
| R2 | 规范先于代码：新平台能力必须先有 `specs/capabilities/<name>.md` |
| R3 | 每个包只导出一个 barrel：`lib/<package_name>.dart` |
| R4 | 跨包边界用 `Result<T>`（来自 `core_base`），不抛原始异常 |
| R5 | 全局可替换服务用 Riverpod Provider 注入，禁止静态单例 |
| R5a | 跨 Feature 共享状态必须经过 Core 层 Provider，Feature 不持有其他 Feature 的状态 |
| R6 | Feature / Common 包不硬编码颜色/字号，用 `Theme.of(context)` |
| R7 | 禁止相对 import（`always_use_package_imports: true`） |
| R8 | 接口不泄露平台类型：Core 层接口参数/返回值只用自定义 Dart 类型 |
| R9 | 改动最小化：只修改任务必要的文件，不做无关重构或格式化 |

---

## 5. Before you write code — checklist

- [ ] 已读 `project_map.json` 确认涉及包和依赖范围？
- [ ] 依赖方向合法？（查 Decision tree）
- [ ] 涉及平台能力？→ `specs/` 对应规范已存在或已起草？
- [ ] 新包符合准入？core 包有明确 consumer；feature 包是完整用户场景
- [ ] 跨包错误处理用 `Result<T>` 而非 throw？
- [ ] 新包通过 scaffold 创建（不手写 pubspec 模板）？
- [ ] 原生封装任务？→ 已读 native-to-flutter-bridge SKILL.md？

---

## 6. After you write code — eval gate

**必须全部通过，否则不提交：**

```bash
dart analyze .                          # 0 error，0 warning
flutter test packages/<layer>/<name>/   # 当前包测试全绿
```

**涉及原生代码的包额外执行：**

```bash
cd packages/core/<name>/example && flutter build apk --debug   # Android 编译验证
cd packages/core/<name>/example && flutter build ios --no-codesign # iOS 编译验证
```

**失败处理：**
1. 读取错误输出，分类错误类型
2. 查 `harness/evolution/rules.json` 是否有已知修复方案
3. 无匹配规则 → 记录到 `harness/evolution/failure_log.jsonl`，上报人工处理
4. 不要在没有理解错误原因的情况下反复重试

---

## 7. Further reading（按需，不要全读）

| 文档 | 何时读 |
|------|--------|
| [harness/map/project_map.json](harness/map/project_map.json) | 每次任务开始时，定位涉及包 |
| [harness/map/flow_index.json](harness/map/flow_index.json) | 流程不清晰时 |
| [harness/skills/native-to-flutter-bridge/SKILL.md](harness/skills/native-to-flutter-bridge/SKILL.md) | 原生封装任务 |
| [specs/](specs/) | 修改/新建平台能力时 |
| [docs/架构设计.md](docs/架构设计.md) | 分层规则、装配模型完整说明 |
| [docs/实现状态.md](docs/实现状态.md) | 已建成 vs 待建，避免重复建设 |
| [harness/evolution/rules.json](harness/evolution/rules.json) | eval 失败时查已知修复方案 |
