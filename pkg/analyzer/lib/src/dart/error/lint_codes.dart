// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/codes.dart';
library;

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/base/errors.dart';

export 'package:_fe_analyzer_shared/src/base/errors.dart'
    show
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

  const LintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
    this.severity = DiagnosticSeverity.INFO,
  }) : super(
         problemMessage: problemMessage,
         name: name,
         uniqueName: uniqueName ?? 'LintCode.$name',
       );

  @override
  int get hashCode => uniqueName.hashCode;

  @override
  DiagnosticType get type => DiagnosticType.LINT;

  @override
  String? get url => null;

  @override
  bool operator ==(Object other) =>
      other is LintCode && uniqueName == other.uniqueName;
}

/// Private subtype of [LintCode] that supports runtime checking of parameter
/// types.
class LintCodeWithExpectedTypes extends DiagnosticCodeWithExpectedTypes
    implements LintCode {
  @override
  final DiagnosticSeverity severity;

  const LintCodeWithExpectedTypes(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
    this.severity = DiagnosticSeverity.INFO,
    required super.expectedTypes,
  }) : super(
         problemMessage: problemMessage,
         name: name,
         uniqueName: uniqueName ?? 'LintCode.$name',
       );

  @override
  int get hashCode => uniqueName.hashCode;

  @override
  DiagnosticType get type => DiagnosticType.LINT;

  @override
  String? get url => null;

  @override
  bool operator ==(Object other) =>
      other is LintCode && uniqueName == other.uniqueName;
}

/// Defines security-related best practice recommendations.
///
/// The primary difference from [LintCode]s is that these codes cannot be
/// suppressed with `// ignore:` or `// ignore_for_file:` comments.
class SecurityLintCode extends LintCode {
  const SecurityLintCode(
    super.name,
    super.problemMessage, {
    String? uniqueName,
    super.correctionMessage,
  }) : super(uniqueName: uniqueName ?? 'LintCode.$name');

  @override
  bool get isIgnorable => false;
}
