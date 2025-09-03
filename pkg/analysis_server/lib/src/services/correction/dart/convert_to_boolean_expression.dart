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

    if (node case BinaryExpression(
      :var rightOperand,
      :var leftOperand,
      operator: Token(type: var operator),
    )) {
      if (rightOperand is BooleanLiteral) {
        return await _processBinaryExp(
          builder,
          node,
          operator,
          rightOperand,
          leftOperand,
          currentIsLeft: false,
        );
      }
      if (leftOperand is BooleanLiteral) {
        return await _processBinaryExp(
          builder,
          node,
          operator,
          leftOperand,
          rightOperand,
          currentIsLeft: true,
        );
      }
    } else if (node
        case ConditionalExpression(
              :var condition,
              :var thenExpression,
              :var elseExpression,
            ) &&
            var conditionalExp) {
      await (switch ((thenExpression, elseExpression)) {
        (BooleanLiteral then, BooleanLiteral elseExp) => () async {
          var equalValues = then.value == elseExp.value;
          var rangeStart = equalValues
              // keep `then`
              ? range.startStart(condition, then)
              // keep `condition`
              : range.endEnd(condition, then);
          // remove ` : elseExp`
          var rangeEnd = range.endEnd(then, elseExp);
          await _addEdit(
            builder,
            parensRange: range.node(equalValues ? then : condition),
            deleteRanges: [rangeStart, rangeEnd],
            negated: !then.value && elseExp.value,
            needsParens: !equalValues && condition.needsParens(),
            bangBeforeParens: false,
          );
        }(),
        (BooleanLiteral then, Expression elseExp) => () async {
          var replaceRange = range.endStart(condition, elseExp);
          var operator = then.ifBarElseAmpersand;
          await _addEdit(
            builder,
            parensRange: range.node(conditionalExp.condition),
            deleteRanges: const <SourceRange>[],
            negated: !then.value,
            replace: (replaceRange, ' ${operator.lexeme} '),
            needsParens: conditionalExp.condition.needsParens(
              then.value ? operator : null,
            ),
            bangBeforeParens: true,
            parensRange2: elseExp.needsParens(operator)
                ? range.node(elseExp)
                : null,
          );
        }(),
        (Expression then, BooleanLiteral elseExp) => () async {
          var rangeStart = range.endStart(condition, then);
          var rangeEnd = range.endEnd(then, elseExp);
          var operator = elseExp.ifBarElseAmpersand;
          await _addEdit(
            builder,
            parensRange: range.node(conditionalExp.condition),
            deleteRanges: [rangeEnd],
            negated: elseExp.value,
            replace: (rangeStart, ' ${operator.lexeme} '),
            needsParens: conditionalExp.condition.needsParens(
              elseExp.value ? null : operator,
            ),
            bangBeforeParens: true,
            parensRange2: then.needsParens(operator) ? range.node(then) : null,
          );
        }(),
        (_, _) => null,
      });
    }
  }

  /// This correction producer can act on a variety of code, and various edits
  /// might be applied.
  ///
  /// The [deleteRanges] are ranges that should be deleted from the code.
  ///
  /// The [replace] will be normally used to replace part of the expression
  /// with a new operator.
  ///
  /// The [parensRange] is related to [needsParens] and [bangBeforeParens]. The
  /// `bang` is added only if [negated] is true. It was meant for adding the
  /// parens when the `bang` or the new operator given by [replace] makes the
  /// precedence of the expression different than the original one.
  ///
  /// The [parensRange2] is meant to be used when converting conditional
  /// expressions and should be non-`null` if the second expression needs
  /// parentheses considering the new operator added by the given [replace].
  Future<void> _addEdit(
    ChangeBuilder builder, {
    required SourceRange parensRange,
    required bool needsParens,
    required List<SourceRange> deleteRanges,
    required bool negated,
    required bool bangBeforeParens,
    (SourceRange, String)? replace,
    SourceRange? parensRange2,
  }) async {
    await builder.addDartFileEdit(file, (builder) {
      if (bangBeforeParens) {
        if (negated) {
          builder.addSimpleInsertion(parensRange.offset, TokenType.BANG.lexeme);
        }
        if (needsParens) {
          builder.addSimpleInsertion(parensRange.offset, '(');
          builder.addSimpleInsertion(parensRange.end, ')');
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
      if (parensRange2 != null) {
        builder.addSimpleInsertion(parensRange2.offset, '(');
        builder.addSimpleInsertion(parensRange2.end, ')');
      }
      for (var range in deleteRanges) {
        builder.addDeletion(range);
      }
    });
  }

  Future<void> _processBinaryExp(
    ChangeBuilder builder,
    BinaryExpression binaryExp,
    TokenType operator,
    BooleanLiteral current,
    Expression other, {
    required bool currentIsLeft,
  }) async {
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
        needsParens = current.needsParens();
      default:
        deleteRanges = [
          currentIsLeft
              ? range.startStart(current, other)
              : range.endEnd(other, current),
        ];
        parensRange = range.node(other);
        needsParens = other.needsParens();
    }
    await _addEdit(
      builder,
      negated: !isPositiveCase(binaryExp, current),
      parensRange: parensRange,
      deleteRanges: deleteRanges,
      needsParens: needsParens,
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
  bool needsParens([TokenType? tokenType]) =>
      precedence <=
      (tokenType != null
          ? Precedence.forTokenType(tokenType)
          : Precedence.prefix);
}
