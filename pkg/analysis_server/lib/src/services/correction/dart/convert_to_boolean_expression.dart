// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// This correction producer can act on a variety of code, and various edits
/// might be applied.
typedef _ParametersFixData =
    ({
      SourceRange parensRange,
      List<SourceRange> deleteRanges,
      bool negated,
      bool needsParens,
      (SourceRange, String)? replace,
      bool bangBeforeParens,
    });

class ConvertToBooleanExpression extends ResolvedCorrectionProducer {
  ConvertToBooleanExpression({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_BOOL_EXPRESSION;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_BOOL_EXPRESSION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = this.node;
    if (node is BooleanLiteral) node = node.parent;
    _ParametersFixData parameters;

    if (node case BinaryExpression(
      :var rightOperand,
      :var leftOperand,
      operator: Token(type: var operator),
    )) {
      if (rightOperand is BooleanLiteral) {
        parameters = _processBinaryExp(
          node,
          operator,
          rightOperand,
          leftOperand,
          currentIsLeft: false,
        );
      } else if (leftOperand is BooleanLiteral) {
        parameters = _processBinaryExp(
          node,
          operator,
          leftOperand,
          rightOperand,
          currentIsLeft: true,
        );
      } else {
        return;
      }
    } else if (node
        case ConditionalExpression(
              :var condition,
              :var thenExpression,
              :var elseExpression,
            ) &&
            var conditionalExp) {
      _ParametersFixData? result = (switch ((thenExpression, elseExpression)) {
        (BooleanLiteral then, BooleanLiteral elseExp) => () {
          var equalValues = then.value == elseExp.value;
          var rangeStart =
              equalValues
                  // keep `then`
                  ? range.startStart(condition, then)
                  // keep `condition`
                  : range.endEnd(condition, then);
          // remove ` : elseExp`
          var rangeEnd = range.endEnd(then, elseExp);
          return (
            parensRange: range.node(equalValues ? then : condition),
            deleteRanges: [rangeStart, rangeEnd],
            negated: !then.value && elseExp.value,
            replace: null,
            needsParens: !equalValues && condition.needsParens,
            bangBeforeParens: false,
          );
        }(),
        (BooleanLiteral then, Expression elseExp) => () {
          var replaceRange = range.endStart(condition, elseExp);
          var operator = then.ifBarElseAmpersand;
          return (
            parensRange: range.node(conditionalExp),
            deleteRanges: const <SourceRange>[],
            negated: !then.value,
            replace: (replaceRange, ' ${operator.lexeme} '),
            // conditional expressions always need parens so there will
            // be no need to add them
            needsParens: false,
            bangBeforeParens: false,
          );
        }(),
        (Expression then, BooleanLiteral elseExp) => () {
          var rangeStart = range.endStart(condition, then);
          var rangeEnd = range.endEnd(then, elseExp);
          var operator = elseExp.ifBarElseAmpersand;
          return (
            parensRange: range.node(conditionalExp),
            deleteRanges: [rangeEnd],
            negated: elseExp.value,
            replace: (rangeStart, ' ${operator.lexeme} '),
            // conditional expressions always need parens so there will
            // be no need to add them
            needsParens: false,
            bangBeforeParens: false,
          );
        }(),
        (_, _) => null,
      });
      if (result == null) {
        return;
      }
      parameters = result;
    } else {
      return;
    }
    await _addEdit(builder, parameters);
  }

  Future<void> _addEdit(
    ChangeBuilder builder,
    _ParametersFixData parameters,
  ) async {
    var (
      :parensRange,
      :deleteRanges,
      :negated,
      :replace,
      :needsParens,
      :bangBeforeParens,
    ) = parameters;
    await builder.addDartFileEdit(file, (builder) {
      if (bangBeforeParens) {
        if (negated) {
          builder.addSimpleInsertion(parensRange.offset, TokenType.BANG.lexeme);
          if (needsParens) {
            builder.addSimpleInsertion(parensRange.offset, '(');
            builder.addSimpleInsertion(parensRange.end, ')');
          }
        }
      } else {
        if (needsParens) {
          builder.addSimpleInsertion(parensRange.offset, '(');
        }
        if (negated) {
          builder.addSimpleInsertion(parensRange.offset, TokenType.BANG.lexeme);
        }
        if (needsParens) {
          builder.addSimpleInsertion(parensRange.end, ')');
        }
      }
      if (replace != null) {
        builder.addSimpleReplacement(replace.$1, replace.$2);
      }
      for (var range in deleteRanges) {
        builder.addDeletion(range);
      }
    });
  }

  _ParametersFixData _processBinaryExp(
    BinaryExpression binaryExp,
    TokenType operator,
    BooleanLiteral current,
    Expression other, {
    required bool currentIsLeft,
  }) {
    List<SourceRange> deleteRanges;
    SourceRange parensRange;
    bool needsParens;
    switch (operator) {
      case TokenType.BAR || TokenType.BAR_BAR when current.value:
      case TokenType.AMPERSAND || TokenType.AMPERSAND_AMPERSAND
          when !current.value:
        deleteRanges = [
          currentIsLeft
              ? range.endEnd(current, other)
              : range.startStart(other, current),
        ];
        parensRange = range.node(current);
        needsParens = current.needsParens;
      default:
        deleteRanges = [
          currentIsLeft
              ? range.startStart(current, other)
              : range.endEnd(other, current),
        ];
        parensRange = range.node(other);
        needsParens = other.needsParens;
    }
    return (
      negated: !isPositiveCase(binaryExp, current),
      parensRange: parensRange,
      deleteRanges: deleteRanges,
      needsParens: needsParens,
      replace: null,
      bangBeforeParens: true,
    );
  }

  static bool isPositiveCase(
    BinaryExpression expression,
    BooleanLiteral literal,
  ) {
    return switch (expression.operator.type) {
      TokenType.BAR ||
      TokenType.BAR_BAR ||
      TokenType.AMPERSAND ||
      TokenType.AMPERSAND_AMPERSAND => true,
      TokenType.EQ_EQ => literal.value,
      TokenType.BANG_EQ || TokenType.CARET => !literal.value,
      _ => throw StateError('Unexpected operator ${expression.operator.type}'),
    };
  }
}

extension on BooleanLiteral {
  TokenType get ifBarElseAmpersand =>
      value ? TokenType.BAR_BAR : TokenType.AMPERSAND_AMPERSAND;
}

extension on Expression {
  bool get needsParens => precedence <= Precedence.prefix;
}
