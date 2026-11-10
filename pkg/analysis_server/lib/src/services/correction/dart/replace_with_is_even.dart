// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
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

/// Replaces `x % 2 == 0` with `x.isEven` and `x % 2 == 1` with `x.isOdd`.
class ReplaceWithIsEven extends ResolvedCorrectionProducer {
  @override
  final FixKind fixKind;

  @override
  final FixKind multiFixKind;

  /// The `==` comparison reported by `use_is_even_rather_than_modulo`.
  final BinaryExpression? _comparison;

  factory({required CorrectionProducerContext context}) {
    var comparison = context is StubCorrectionProducerContext
        ? null
        : _validComparison(context.node);
    var odd = _isOdd(comparison);
    return ReplaceWithIsEven._(
      context: context,
      fixKind: odd
          ? DartFixKind.replaceWithIsOdd
          : DartFixKind.replaceWithIsEven,
      multiFixKind: DartFixKind.replaceWithIsEvenOrOddMulti,
      comparison: comparison,
    );
  }

  new _({
    required super.context,
    required this.fixKind,
    required this.multiFixKind,
    required this._comparison,
  });

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comparison = _comparison;
    if (comparison == null) {
      return;
    }
    var modulo = comparison.leftOperand as BinaryExpression;
    var receiver = modulo.leftOperand;
    var text = utils.getNodeText(receiver);
    if (_needsParentheses(receiver)) {
      text = '($text)';
    }

    // Keep a comment that sits between the receiver and `%`. Drop a
    // whitespace-only gap so `x % 2` becomes `x.isEven`, not `x .isEven`.
    var between = utils.getRangeText(
      SourceRange(receiver.end, modulo.operator.offset - receiver.end),
    );
    if (between.trim().isEmpty) {
      between = '';
    } else {
      between = between.trimRight();
    }

    var remainder = comparison.rightOperand as IntegerLiteral;
    var getter = remainder.value == 0 ? 'isEven' : 'isOdd';
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(comparison),
        '$text$between.$getter',
      );
    });
  }

  static bool _isOdd(BinaryExpression? comparison) {
    var remainder = comparison?.rightOperand;
    return remainder is IntegerLiteral && remainder.value == 1;
  }

  /// `isEven` is a selector, so a receiver that binds looser than postfix
  /// needs parentheses. Postfix `++` and `--` do too: `x++.isEven` does not
  /// parse. Postfix `!` can be followed by a selector.
  static bool _needsParentheses(Expression receiver) {
    if (receiver is PostfixExpression &&
        receiver.operator.type != TokenType.BANG) {
      return true;
    }
    return receiver.precedence < Precedence.postfix;
  }

  /// The comparison the lint reports, or `null` when [node] is not that form.
  ///
  /// Constant contexts are skipped. `isEven` and `isOdd` are not constant.
  static BinaryExpression? _validComparison(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is! BinaryExpression) continue;
      if (current.operator.type != TokenType.EQ_EQ) continue;

      var modulo = current.leftOperand;
      if (modulo is! BinaryExpression) continue;
      if (modulo.operator.type != TokenType.PERCENT) continue;
      var divisor = modulo.rightOperand;
      if (divisor is! IntegerLiteral || divisor.value != 2) continue;

      var remainder = current.rightOperand;
      if (remainder is! IntegerLiteral) continue;
      var value = remainder.value;
      if (value != 0 && value != 1) continue;
      if (modulo.leftOperand.staticType?.isDartCoreInt != true) continue;

      // `isEven` / `isOdd` are not constant expressions.
      if (current.inConstantContext) return null;
      var assertInitializer = current.thisOrAncestorOfType<AssertInitializer>();
      if (assertInitializer?.parent case ConstructorDeclaration constructor
          when constructor.constKeyword != null) {
        return null;
      }
      return current;
    }
    return null;
  }
}
