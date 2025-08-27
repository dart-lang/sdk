## 0.2.3-dev

- Require version `8.2.0` of the `analyzer` package.
- Add support for automatic re-analysis of files changed on-disk (as opposed to
  file contents changed in the IDE, which is already supported).

## 0.2.2

- Require version `8.1.1` of the `analyzer` package.

## 0.2.1

- Require version `^8.1.0` of the `analyzer` package.

## 0.2.0

- Require version `^8.0.0` of the `analyzer` package.
- Require Dart SDK version `^3.5.0`.
- Plugins can now register assists. See the [documentation][writing assists]
  for details.
- With the initial release of the new `analyzer_testing` package, there is now
  a framework for testing analysis rules. See the
  [documentation][testing_rules] for details.
- Added documentation for several features:
  - [writing fixes][]
  - [writing assists][]
  - [enabling lint rules][]
- Require that CorrectionProducers registered as fixes have a non-`null`
  `fixKind`, and that CorrectionProducers registered as assists have a
  non-`null` `assistKind`.
- Various performance improvements are included.
- Breaking change: The `DartFixContext.librariesWithExtensions` method now
  accepts a `Name` instead of a `String`, and only yields library elements that
  actually export an extension with a member of the given name.
- `CorrectionProducer.errorLength` is renamed
  `CorrectionProducer.diagnosticLength`.
- `CorrectionProducer.errorOffset` is renamed
  `CorrectionProducer.diagnosticOffset`.
- `FixContext.error` is renamed `FixContext.diagnostic`.
- The new minimum analyzer version contains a number of API changes that should
  be noted for use in this package:
  - `ErrorCode` is renamed `DiagnosticCode`.
  - `AnalysisError` is renamed `Diagnostic`. This class's `errorCode` field is
    now named `diagnosticCode`.
  - `ErrorListener` is renamed `DiagnosticListener`.
  - `ErrorReporter` is renamed `DiagnosticReporter`.
  - `LintRule` is split into two classses: `AnalysisRule`, for rules which
    report exactly one code, and `MultiAnalysisRule`, for rules which report
    multiple codes. These classes are public API. Classes that used to extend
    `LintRule` and either implemented the `lintCode` getter or the `lintCodes`
    getter now must implement `diagnosticCode` (for `AnalysisRule`) or
    `diagnosticCodes` (for `MultiAnalysisRule`).
  - `NodeLintRegistry` is renamed `RuleVisitorRegistry`. It is now public API.
  - A `LintCode`'s severity can now be specified when in the constructor call.
  - `LinterContext` is renamed `RuleContext`. It is now public API.
  - `LinterContextWithParsedResults` is renamed `RuleContextWithParsedResults`.
  - `LinterContextWithResolvedResults` is renamed
    `RuleContextWithResolvedResults`.
  - `LintRuleUnitContext` is renamed `RuleUnitContext`. It is now public API.
  - `CorrectionProducer.inheritanceManager` is deprecated, in favor of the
    methods found on `InterfaceElement`.

[testing_rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md
[writing fixes]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_fixes.md
[writing assists]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md
[enabling lint rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md#enabling-a-lint-rule

## 0.1.0-dev.1

- Initial release
