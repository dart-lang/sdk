// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

/// Defines style and best practice recommendations.
///
/// Unlike [HintCode]s, which are akin to traditional static warnings from a
/// compiler, lint recommendations focus on matters of style and practices that
/// might aggregated to define a project's style guide.
class LintCode extends ErrorCode {
  const LintCode(String name, String message, {String correction})
      : super.temporary(name, message, correction: correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  int get hashCode => uniqueName.hashCode;

  @override
  ErrorType get type => ErrorType.LINT;

  /// Overridden so that [LintCode] and its subclasses share the same uniqueName
  /// pattern (we know how to identify a lint even if we don't know the specific
  /// subclass the lint's code is defined in.
  @override
  String get uniqueName => "LintCode.$name";

  @override
  String get url => 'https://dart-lang.github.io/linter/lints/$name.html';

  @override
  bool operator ==(other) => uniqueName == other.uniqueName;
}

class LintCodeWithUniqueName extends LintCode {
  @override
  final String uniqueName;

  const LintCodeWithUniqueName(String name, this.uniqueName, String message,
      {String correction})
      : super(name, message, correction: correction);
}

/// Defines security-related best practice recommendations.
///
/// The primary difference from [LintCode]s is that these codes cannot be
/// suppressed with `// ignore:` or `// ignore_for_file:` comments.
class SecurityLintCode extends LintCode {
  const SecurityLintCode(String name, String message, {String correction})
      : super(name, message, correction: correction);

  @override
  bool get isIgnorable => false;
}

class SecurityLintCodeWithUniqueName extends SecurityLintCode {
  @override
  final String uniqueName;

  const SecurityLintCodeWithUniqueName(
      String name, this.uniqueName, String message,
      {String correction})
      : super(name, message, correction: correction);
}
