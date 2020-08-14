// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithTearOff extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_TEAR_OFF;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var ancestor = node.thisOrAncestorOfType<FunctionExpression>();
    if (ancestor == null) {
      return;
    }
    Future<void> addFixOfExpression(InvocationExpression expression) async {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(ancestor), (builder) {
          if (expression is MethodInvocation && expression.target != null) {
            builder.write(utils.getNodeText(expression.target));
            builder.write('.');
          }
          builder.write(utils.getNodeText(expression.function));
        });
      });
    }

    final body = ancestor.body;
    if (body is ExpressionFunctionBody) {
      final expression = body.expression;
      await addFixOfExpression(expression.unParenthesized);
    } else if (body is BlockFunctionBody) {
      final statement = body.block.statements.first;
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        await addFixOfExpression(expression.unParenthesized);
      } else if (statement is ReturnStatement) {
        final expression = statement.expression;
        await addFixOfExpression(expression.unParenthesized);
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithTearOff newInstance() => ReplaceWithTearOff();
}
