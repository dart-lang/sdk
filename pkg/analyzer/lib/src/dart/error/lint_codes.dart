// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/codes.dart';
/// @docImport 'package:analyzer/analysis_rule/analysis_rule.dart';
library;

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/base/errors.dart';

export 'package:_fe_analyzer_shared/src/base/errors.dart'
    show
        DiagnosticWithArguments,
        DiagnosticWithoutArguments,
        ExpectedType,
        LocatableDiagnostic,
        LocatableDiagnosticImpl;

/// Diagnostic codes which are not reported by default.
///
/// Lint codes are only reported when a lint rule (either a first-party lint
/// rule, or one declared in an analyzer plugin) is enabled.
@AnalyzerPublicApi(message: 'exported by lib/error/error.dart')
class LintCode extends DiagnosticCode {
  @override
  final DiagnosticSeverity severity;

  /// Initializes a lint code.
  ///
  /// The [name] is a "snake_case" name for the reported diagnostic.
  ///
  /// The [problemMessage] is a concise, human-readable message indicating
  /// the problematic behavior.
  ///
  /// The [correctionMessage], if given, is a concise, human-readable message
  /// indicating one or two possible corrections.
  ///
  /// The [problemMessage] and [correctionMessage] text is printed with a
  /// reported diagnostics. For example, `dart analyze` and `flutter analyze`
  /// will print the [problemMessage] with each diagnostic. The [problemMessage]
  /// and [correctionMessage] area each printed in an IDE's "problems" panel
  /// with each diagnostic.
  ///
  /// The [problemMessage] and [correctionMessage] text can contain
  /// interpolation placeholders, in the form of `{0}`, `{1}`, etc. When a
  /// diagnostic for this LintCode is produced (for example with
  /// [AnalysisRule.reportAtNode]) with arguments, they are interpolated into
  /// the [problemMessage] and [correctionMessage]. If present, the first
  /// argument (at position 0) replaces each instance of `{0}`, the second
  /// argument (at position 1) replaces each instance of `{1}`, etc.
  // TODO(srawlins): Add a 'url' parameter for plugin authors.
  // TODO(srawlins): Document `uniqueName` and `severity`.
  const LintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    @Deprecated('To be removed without replacement') super.hasPublishedDocs,
    String? uniqueName,
    this.severity = DiagnosticSeverity.INFO,
  }) : super(
         problemMessage: problemMessage,
         name: name,
         uniqueName: uniqueName ?? 'LintCode.$name',
       );

  @override
  int get hashCode => lowerCaseUniqueName.hashCode;

  @override
  DiagnosticType get type => DiagnosticType.LINT;

  @override
  String? get url => null;

  @override
  bool operator ==(Object other) =>
      other is LintCode && lowerCaseUniqueName == other.lowerCaseUniqueName;
}

/// Private subtype of [LintCode] that supports runtime checking of parameter
/// types.
abstract class LintCodeWithExpectedTypes extends DiagnosticCodeWithExpectedTypes
    implements LintCode {
  const LintCodeWithExpectedTypes({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs,
    required super.uniqueName,
    required super.expectedTypes,
  }) : super(type: DiagnosticType.LINT);

  @override
  int get hashCode => lowerCaseUniqueName.hashCode;

  @override
  String? get url => null;

  @override
  bool operator ==(Object other) =>
      other is LintCode && lowerCaseUniqueName == other.lowerCaseUniqueName;
}

/// Defines security-related best practice recommendations.
///
/// The primary difference from [LintCode]s is that these codes cannot be
/// suppressed with `// ignore:` or `// ignore_for_file:` comments.
class SecurityLintCode extends DiagnosticCodeImpl implements LintCode {
  const SecurityLintCode(
    String name,
    String problemMessage, {
    String? uniqueName,
    super.correctionMessage,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         type: DiagnosticType.LINT,
         uniqueName: uniqueName ?? 'LintCode.$name',
       );

  @override
  bool get isIgnorable => false;
}
