// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
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
    CommentToken? beforeExpressionComments;
    Expression returnExpression;
    CommentToken? beforeReturnComments;
    CommentToken? beforeSemicolonComments;
    if (onlyStatement case ReturnStatement(:var expression?)) {
      returnExpression = expression;
      beforeReturnComments = onlyStatement.returnKeyword.precedingComments;

      beforeExpressionComments =
          onlyStatement.returnKeyword.next?.precedingComments;

      beforeSemicolonComments = onlyStatement.semicolon.precedingComments;
    } else if (onlyStatement is ExpressionStatement) {
      returnExpression = onlyStatement.expression;

      beforeExpressionComments = body.block.leftBracket.next?.precedingComments;

      beforeSemicolonComments = onlyStatement.semicolon?.precedingComments;
    } else {
      return;
    }

    // Return expressions can be quite large, e.g. Flutter `build()` methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnExpression.offset) {
      return;
    }

    var prefix = utils.getNodePrefix(body.parent!);
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(body), (builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        if (body.keyword != null) {
          builder.writeComment(
            body.block.leftBracket.precedingComments,
            prefix: prefix,
            after: AfterCommentWrite.space,
          );
        }
        builder.write('=> ');
        builder.writeComment(
          beforeReturnComments,
          prefix: prefix,
          after: AfterCommentWrite.space,
        );
        builder.writeComment(
          beforeExpressionComments,
          prefix: prefix,
          after: AfterCommentWrite.space,
        );
        builder.write(utils.getNodeText(returnExpression));
        var lastComments = body.block.rightBracket.precedingComments;
        builder.writeComment(
          beforeSemicolonComments,
          prefix: prefix,
          before: BeforeCommentWrite.space,
          after: lastComments == null
              ? AfterCommentWrite.nothing
              : AfterCommentWrite.space,
        );
        builder.writeComment(
          lastComments,
          prefix: prefix,
          before: beforeSemicolonComments == null
              ? BeforeCommentWrite.space
              : BeforeCommentWrite.nothing,
        );
        var parent = body.parent;
        if (parent is! FunctionExpression ||
            parent.parent is FunctionDeclaration) {
          builder.write(';');
        }
      });
    });
  }
}
