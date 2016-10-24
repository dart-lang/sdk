// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.error.lint_codes;

import 'package:analyzer/error/error.dart';

/**
 * Defines style and best practice recommendations.
 *
 * Unlike [HintCode]s, which are akin to traditional static warnings from a
 * compiler, lint recommendations focus on matters of style and practices that
 * might aggregated to define a project's style guide.
 */
class LintCode extends ErrorCode {
  const LintCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.LINT;
}
