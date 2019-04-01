// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart' as ir;

import '../kernel/dart2js_target.dart';

typedef ReportErrorFunction = void Function(
    ir.LocatedMessage message, List<ir.LocatedMessage> context);

class Dart2jsConstantEvaluator extends ir.ConstantEvaluator {
  final bool _supportReevaluationForTesting;

  bool requiresConstant;

  Dart2jsConstantEvaluator(
      ir.TypeEnvironment typeEnvironment, ReportErrorFunction reportError,
      {bool enableAsserts,
      Map<String, String> environment: const {},
      bool supportReevaluationForTesting: false})
      : _supportReevaluationForTesting = supportReevaluationForTesting,
        super(const Dart2jsConstantsBackend(), environment, typeEnvironment,
            enableAsserts, new ErrorReporter(reportError));

  @override
  ErrorReporter get errorReporter => super.errorReporter;

  @override
  ir.Constant evaluate(ir.Expression node, {bool requireConstant: true}) {
    errorReporter.requiresConstant = requireConstant;
    if (node is ir.ConstantExpression) {
      ir.Constant constant = node.constant;
      if (constant is ir.UnevaluatedConstant) {
        ir.Constant result = super.evaluate(constant.expression);
        if (!_supportReevaluationForTesting) {
          node.constant = result;
        }
        return result;
      }
      return constant;
    }
    if (requireConstant) {
      // TODO(johnniwinther): Handle reporting of compile-time constant
      // evaluation errors.
      return super.evaluate(node);
    } else {
      try {
        return super.evaluate(node);
      } catch (e) {
        return null;
      }
    }
  }
}

class ErrorReporter implements ir.ErrorReporter {
  final ReportErrorFunction _reportError;
  bool requiresConstant;

  ErrorReporter(this._reportError);

  @override
  void reportInvalidExpression(ir.InvalidExpression node) {
    // Ignore.
  }

  @override
  void report(ir.LocatedMessage message, List<ir.LocatedMessage> context) {
    if (requiresConstant) {
      _reportError(message, context);
    }
  }
}
