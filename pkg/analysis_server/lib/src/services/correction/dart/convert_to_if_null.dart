// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfNull extends ResolvedCorrectionProducer {
  /// Identifies the case to be fixed.
  final _FixCase _fixCase;

  ConvertToIfNull.preferIfNull({required super.context})
    : _fixCase = _FixCase.preferIfNull;

  ConvertToIfNull.useToConvertNullsToBools({required super.context})
    : _fixCase = _FixCase.useToConvertNullsToBools;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.convertToIfNull;

  @override
  FixKind get multiFixKind => DartFixKind.convertToIfNullMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    switch (_fixCase) {
      case _FixCase.preferIfNull:
        await _preferIfNull(builder);
      case _FixCase.useToConvertNullsToBools:
        await _useToConvertNullsToBools(builder);
    }
  }

  bool _outerParenthesesNeeded(AstNode node) {
    if (node.parent case Expression expression
        when expression is! ParenthesizedExpression) {
      return expression.precedence >
          Precedence.forTokenType(TokenType.QUESTION_QUESTION);
    } else {
      return false;
    }
  }

  Future<void> _preferIfNull(ChangeBuilder builder) async {
    var node = this.node;
    if (node is ConditionalExpression &&
        node.offset == diagnosticOffset &&
        node.length == diagnosticLength) {
      var condition = node.condition as BinaryExpression;
      Expression nullableExpression;
      Expression defaultExpression;
      if (condition.operator.type == TokenType.EQ_EQ) {
        nullableExpression = node.elseExpression;
        defaultExpression = node.thenExpression;
      } else {
        nullableExpression = node.thenExpression;
        defaultExpression = node.elseExpression;
      }

      if (defaultExpression is SimpleIdentifier &&
          defaultExpression.isSynthetic) {
        return;
      }

      var innerParentheses =
          defaultExpression.precedence <
          Precedence.forTokenType(TokenType.QUESTION_QUESTION);

      // Should not be needed because the precedence for ConditionalExpression
      // is higher than for '??'. We still do it for consistency.
      var outerParentheses = _outerParenthesesNeeded(node);

      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(node), (builder) {
          if (outerParentheses) {
            builder.write('(');
          }
          builder.write(utils.getNodeText(nullableExpression));

          if (defaultExpression is NullLiteral) return;
          builder.write(' ?? ');
          if (innerParentheses) {
            builder.write('(');
          }
          builder.write(utils.getNodeText(defaultExpression));
          if (innerParentheses) {
            builder.write(')');
          }
          if (outerParentheses) {
            builder.write(')');
          }
        });
      });
    }
  }

  Future<void> _useToConvertNullsToBools(ChangeBuilder builder) async {
    var node = this.node;
    if (node is BinaryExpression &&
        node.offset == diagnosticOffset &&
        node.length == diagnosticLength &&
        (node.operator.type == TokenType.EQ_EQ ||
            node.operator.type == TokenType.BANG_EQ)) {
      var left = node.leftOperand;
      var right = node.rightOperand;
      Expression nullableExpression;
      if (left is! BooleanLiteral) {
        nullableExpression = left;
      } else if (right is! BooleanLiteral) {
        nullableExpression = right;
      } else {
        return;
      }
      var outerParentheses = _outerParenthesesNeeded(node);
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(node), (builder) {
          if (outerParentheses) {
            builder.write('(');
          }
          builder.write(utils.getNodeText(nullableExpression));
          builder.write(' ${TokenType.QUESTION_QUESTION.lexeme} ');
          if (node.operator.type == TokenType.EQ_EQ) {
            builder.write('false');
          } else {
            builder.write('true');
          }
          if (outerParentheses) {
            builder.write(')');
          }
        });
      });
    }
  }
}

enum _FixCase { preferIfNull, useToConvertNullsToBools }
