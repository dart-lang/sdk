// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart' as ir;

import '../kernel/dart2js_target.dart';

class Dart2jsConstantEvaluator extends ir.ConstantEvaluator {
  Dart2jsConstantEvaluator(ir.TypeEnvironment typeEnvironment,
      {bool enableAsserts, Map<String, String> environment: const {}})
      : super(const Dart2jsConstantsBackend(), environment, typeEnvironment,
            enableAsserts, const DevNullErrorReporter());

  @override
  ir.Constant evaluate(ir.Expression node, {bool requireConstant: true}) {
    if (node is ir.ConstantExpression) {
      ir.Constant constant = node.constant;
      if (constant is ir.UnevaluatedConstant) {
        return node.constant = super.evaluate(constant.expression);
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

class DevNullErrorReporter implements ir.ErrorReporter {
  const DevNullErrorReporter();

  @override
  void reportInvalidExpression(ir.InvalidExpression node) {
    // Ignore.
  }

  @override
  void report(ir.LocatedMessage message, List<ir.LocatedMessage> context) {
    // TODO(johnniwinther): Handle reporting of compile-time constant
    // evaluation errors.
  }
}
