// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/codes.g.dart';
library;

import 'package:analyzer/error/error.dart';

/// Defines style and best practice recommendations.
///
/// Unlike [WarningCode]s, which are akin to traditional static warnings from a
/// compiler, lint recommendations focus on matters of avoiding errors,
/// unintended code, maintainability, style and other best practices that might
/// be aggregated to define a project's style guide.
class LintCode extends ErrorCode {
  const LintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
  }) : super(
          problemMessage: problemMessage,
          name: name,
          uniqueName: uniqueName ?? 'LintCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  int get hashCode => uniqueName.hashCode;

  @override
  ErrorType get type => ErrorType.LINT;

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
  const SecurityLintCode(super.name, super.problemMessage,
      {String? uniqueName, super.correctionMessage})
      : super(uniqueName: uniqueName ?? 'LintCode.$name');

  @override
  bool get isIgnorable => false;
}
