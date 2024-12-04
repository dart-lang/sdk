// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Use interpolation to compose strings and values.';

class PreferInterpolationToComposeStrings extends LintRule {
  PreferInterpolationToComposeStrings()
      : super(
          name: LintNames.prefer_interpolation_to_compose_strings,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.prefer_interpolation_to_compose_strings;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final skippedNodes = <AstNode>{};

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type != TokenType.PLUS) return;

    var chainedOperands = node.chainedAdditions;

    for (var i = 0; i < chainedOperands.length - 1; i++) {
      var leftOperand = chainedOperands[i];
      var rightOperand = chainedOperands[i + 1];

      // OK(#735): `str1 + str2`.
      if (leftOperand is! StringLiteral && rightOperand is! StringLiteral) {
        continue;
      }
      // OK(#2490): `str1 + r''`.
      if (leftOperand is SimpleStringLiteral && leftOperand.isRaw ||
          rightOperand is SimpleStringLiteral && rightOperand.isRaw) {
        continue;
      }

      // OK: `'foo' + 'bar'`.
      if (leftOperand is StringLiteral && rightOperand is StringLiteral) {
        continue;
      }
      // OK(https://github.com/dart-lang/sdk/issues/52610):
      // `a.toString(x: 0) + 'foo'`
      // `'foo' + a.toString(x: 0)`
      if (leftOperand.isToStringInvocationWithArguments ||
          rightOperand.isToStringInvocationWithArguments) {
        continue;
      }

      if (leftOperand.staticType?.isDartCoreString ?? false) {
        rule.reportLintForOffset(
            leftOperand.offset, rightOperand.end - leftOperand.offset);
        // We've just reported `rightNode`; skip over it.
        i++;
      }
    }
  }
}

extension on Expression {
  // The flattened list of all consecutive `+` operations.
  List<Expression> get chainedAdditions {
    var self = this;
    if (self is! BinaryExpression) return [self];
    if (self.operator.type != TokenType.PLUS) return const [];
    return [
      ...self.leftOperand.chainedAdditions,
      self.rightOperand,
    ];
  }
}
