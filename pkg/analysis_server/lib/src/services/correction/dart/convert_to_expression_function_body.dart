// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToExpressionFunctionBody extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertIntoExpressionBody;

  @override
  FixKind get fixKind => DartFixKind.convertIntoExpressionBody;

  @override
  FixKind get multiFixKind => DartFixKind.convertIntoExpressionBodyMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare current body
    var body = getEnclosingFunctionBody();
    if (body is! BlockFunctionBody || body.isGenerator) {
      return;
    }
    if (body.block.rightBracket.precedingComments != null) {
      // TODO(srawlins): Include comments in fixed output.
      // https://github.com/dart-lang/sdk/issues/29313
      return;
    }
    var parent = body.parent;
    if (parent is ConstructorDeclaration && parent.factoryKeyword == null) {
      return;
    }
    if (parent is PrimaryConstructorBody) {
      return;
    }
    // prepare return statement
    List<Statement> statements = body.block.statements;
    if (statements.length != 1) {
      return;
    }
    var onlyStatement = statements.single;
    // Prepare the returned expression.
    Expression returnExpression;
    if (onlyStatement case ReturnStatement(:var expression?)) {
      returnExpression = expression;
    } else if (onlyStatement is ExpressionStatement) {
      returnExpression = onlyStatement.expression;
    } else {
      return;
    }

    // Return expressions can be quite large, e.g. Flutter `build()` methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnExpression.offset) {
      return;
    }

    var expressionRange = range.node(returnExpression);
    if (returnExpression.beginToken.precedingComments case var comment?) {
      expressionRange = range.startEnd(comment, returnExpression);
    }

    // Preserve comments before `return`; the keyword itself is removed.
    var leadingCommentText = '';
    if (onlyStatement case ReturnStatement(:var returnKeyword)) {
      if (returnKeyword.precedingComments case var comment?) {
        leadingCommentText = utils.getRangeText(
          range.startStart(comment, returnKeyword),
        );
      }
    }

    // Preserve comments between the expression and the removed semicolon.
    var trailingCommentText = '';
    var semicolon = onlyStatement.endToken;
    if (semicolon.precedingComments != null) {
      trailingCommentText = utils.getRangeText(
        range.endStart(returnExpression, semicolon),
      );
    }

    // Preserve comments between `async` and the replaced `{`.
    var asyncCommentText = '';
    if (body.isAsynchronous) {
      if (body.block.leftBracket.precedingComments case var comment?) {
        asyncCommentText = utils.getRangeText(
          range.startStart(comment, body.block.leftBracket),
        );
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(body), (builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
          builder.write(asyncCommentText);
        }
        builder.write('=> ');
        builder.write(leadingCommentText);
        builder.write(utils.getRangeText(expressionRange));
        builder.write(trailingCommentText);
        var parent = body.parent;
        if (parent is! FunctionExpression ||
            parent.parent is FunctionDeclaration) {
          builder.write(';');
        }
      });
    });
  }
}
