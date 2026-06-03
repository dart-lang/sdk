# Common Obsolete Rationales for Analysis Server

When evaluating open GitHub issues for the Analysis Server, Analyzer, or Linter components in the `dart-lang/sdk` repository, use this rationale matrix to determine eligibility for closure. For each rationale, you must perform the specified verification check before confirming.

---

## Rationale Evaluation Matrix

### 1. Superseded by New Analysis Server Features
*   **Criteria**: The request asks for a feature (e.g., a new command-line option, specialized diagnostic view, custom server capability, or specific formatting/plugin behavior) that is now natively supported by the modern Analysis Server or standard LSP protocol capabilities.
*   **Verification**: Search the Analysis Server codebase or command-line configuration options (`lib/src/analysis_server.dart`, `lib/src/lsp/`, or server CLI options) to verify if the requested functionality is now natively supported or configurable.
*   **Agent Comment Template**: "This feature request is now natively supported by modern Analysis Server capabilities (such as [Insert modern server option or capability]). Since the requested behavior is fulfilled by existing features, we are closing this. Thanks!"

### 2. Superseded by Modern Dart Language Features
*   **Criteria**: The issue requests an analysis fix or shorthand syntax that has since been natively solved by major Dart language upgrades (e.g., Extension Methods, Records, Patterns, Null Safety, Dot Shorthands, Primary Constructors, Private Named Parameters).
*   **Verification**: Cross-reference the request with Dart language specifications added in Dart 2.x and 3.x. Note that the Analysis Server currently supports all Dart language versions down to Dart 2.12, meaning features like NNBD (Null Safety) are assumed.
*   **Agent Comment Template**: "This request has been superseded by newer Dart language features (such as [insert feature, e.g., Records/Patterns]), which provide a robust, native solution to this pattern without requiring additional analyzer implementations. Thanks!"

### 3. Stale Feature Requests
*   **Criteria**: The issue is labeled `type-enhancement` or `type-feature`, is **greater than 3 years old**, and has **zero** community upvotes (thumbs up) or comments within the last 2 years.
*   **Verification**: Calculate: `Current_Year - Issue_Creation_Year > 3` AND `Upvotes == 0` and `Comments in last 2 years == 0`.
*   **Agent Comment Template**: "This feature request has seen no activity or community interest for several years. Because the Analysis Server priorities and architecture have evolved significantly since this was filed, we are closing this as stale. Thanks!"

### 4. Untestable / Legacy SDK Version Bugs
*   **Criteria**: The issue reports a bug or crash occurring exclusively on a highly outdated SDK version (compare against the baseline version found in `tools/VERSION`).
*   **Verification**: The reported version must be **older than the last 4 stable minor releases**.
*   **Agent Comment Template**: "This issue was reported on an outdated version of the Dart SDK and Analysis Server. Due to massive changes in the codebase, it is likely already resolved or no longer reproducible in the current stable release. Are you still experiencing this on the latest stable Dart SDK? If so, please reopen with updated reproduction steps. Thanks!"

### 5. Insufficient Information (Dead End)
*   **Criteria**: The issue lacks reproduction steps, code snippets, or logs, AND a maintainer requested info **greater than 90 days ago** with no response from the author.
*   **Verification**: Check for a `needs-info` label or maintainer question followed by author silence exceeding 90 days.
*   **Agent Comment Template**: "Without a minimal reproducible example or diagnostic logs, we are unable to investigate or debug this behavior further. As there has been no follow-up to our request for information, we are closing this issue. Please feel free to reopen if you can provide repro steps. Thanks!"

### 6. Legacy JSON Protocol Specifics
*   **Criteria**: The issue requests features or reports bugs specific to the legacy Analysis Server JSON protocol or legacy IDE integrations that do not apply to LSP.
*   **Verification**: Verify the issue is tied to the old protocol and that the feature is natively handled or bypassed by the Language Server Protocol (LSP).
*   **Safety Rule**: Do NOT blanket-close legacy protocol issues without evaluating their severity. While most editor clients have transitioned to LSP, critical or highly severe bugs on the legacy protocol must remain open and be addressed. Only propose closure if the behavior is resolved/handled standardly in LSP and the legacy issue is non-critical.
*   **Agent Comment Template**: "This issue is specific to the legacy analysis server protocol which has been superseded by the Language Server Protocol (LSP). Modern editor clients have transitioned to LSP, where this behavior is standard or natively resolved. Thanks!"

### 7. Deprecated or Removed Lint Rules / Diagnostics
*   **Criteria**: The issue relates to a lint rule or analyzer diagnostic code that has been deprecated, retired, or merged into another rule.
*   **Verification**: Search the repository's `pkg/linter` or `pkg/analyzer` directories to confirm the rule (`lint_name`) no longer exists or is explicitly marked deprecated.
*   **Agent Comment Template**: "The lint rule or diagnostic referenced in this issue (`{lint_name}`) has been deprecated or completely removed from newer versions of the Dart SDK, rendering this request obsolete. Thanks!"

### 8. Resolved Upstream / Outside SDK Repository
*   **Criteria**: The root cause of the bug belongs to an IDE extension client wrapper (e.g., VS Code Dart/Flutter extension, IntelliJ Dart plugin) rather than the core SDK Analysis Server.
*   **Verification**: Check if the issue description is entirely UI-dependent on a specific editor interface.
*   **Agent Comment Template**: "This issue relates to the specific IDE client integration rather than the core underlying Analysis Server. Upstream updates in the [VS Code / IntelliJ] Dart extension have altered or resolved this behavior. Thanks!"

### 9. Refactored Code Paths (Silent Fixes)
*   **Criteria**: The bug targets a subsystem that underwent a complete architectural rewrite.
*   **Verification**: Verify that the file paths or engine components mentioned in the original issue no longer exist in the current branch.
*   **Agent Comment Template**: "Due to major internal refactorings and updates to the analyzer's core implementation since this issue was filed, the affected code paths have been completely replaced. The historical bug is no longer reproducible or applicable. Thanks!"
