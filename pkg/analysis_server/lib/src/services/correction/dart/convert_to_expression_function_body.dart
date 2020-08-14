// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToExpressionFunctionBody extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_EXPRESSION_BODY;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_INTO_EXPRESSION_BODY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare current body
    var body = getEnclosingFunctionBody();
    if (body is! BlockFunctionBody || body.isGenerator) {
      return;
    }
    // prepare return statement
    List<Statement> statements = (body as BlockFunctionBody).block.statements;
    if (statements.length != 1) {
      return;
    }
    var onlyStatement = statements.first;
    // prepare returned expression
    Expression returnExpression;
    if (onlyStatement is ReturnStatement) {
      returnExpression = onlyStatement.expression;
    } else if (onlyStatement is ExpressionStatement) {
      returnExpression = onlyStatement.expression;
    }
    if (returnExpression == null) {
      return;
    }

    // Return expressions can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnExpression.offset) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(body), (builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('=> ');
        builder.write(utils.getNodeText(returnExpression));
        if (body.parent is! FunctionExpression ||
            body.parent.parent is FunctionDeclaration) {
          builder.write(';');
        }
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToExpressionFunctionBody newInstance() =>
      ConvertToExpressionFunctionBody();
}
