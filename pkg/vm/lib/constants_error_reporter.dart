// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines [ForwardConstantEvaluationErrors], an implementation of
/// [constants.ErrorReporter] which uses package:front_end to report errors.
library vm.constants_error_reporter;

import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    as constants;

import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerContext, LocatedMessage, Severity;

import 'package:kernel/ast.dart' show InvalidExpression;

class ForwardConstantEvaluationErrors implements constants.ErrorReporter {
  // This will get the currently active [CompilerContext] from a zone variable.
  // If there is no active context, this will throw.
  final CompilerContext compilerContext = CompilerContext.current;

  @override
  void report(LocatedMessage message, List<LocatedMessage> context) {
    compilerContext.options.report(message, Severity.error, context: context);
  }

  @override
  void reportInvalidExpression(InvalidExpression node) {
    // Assumed to be already reported.
  }
}
