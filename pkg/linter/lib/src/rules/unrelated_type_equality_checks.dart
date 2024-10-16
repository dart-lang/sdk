// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Equality operator `==` invocation with references of unrelated types.';

class UnrelatedTypeEqualityChecks extends LintRule {
  UnrelatedTypeEqualityChecks()
      : super(
          name: LintNames.unrelated_type_equality_checks,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.unrelated_type_equality_checks_in_expression,
        LinterLintCode.unrelated_type_equality_checks_in_pattern
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeSystem);
    registry.addBinaryExpression(this, visitor);
    registry.addRelationalPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;

  _Visitor(this.rule, this.typeSystem);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var isDartCoreBoolean = node.staticType?.isDartCoreBool ?? false;
    if (!isDartCoreBoolean || !node.operator.isEqualityTest) {
      return;
    }

    var leftOperand = node.leftOperand;
    if (leftOperand is NullLiteral) return;
    var rightOperand = node.rightOperand;
    if (rightOperand is NullLiteral) return;
    var leftType = leftOperand.staticType;
    if (leftType == null) return;
    var rightType = rightOperand.staticType;
    if (rightType == null) return;

    if (_nonComparable(leftType, rightType)) {
      rule.reportLintForToken(
        node.operator,
        errorCode: LinterLintCode.unrelated_type_equality_checks_in_expression,
        arguments: [
          rightType.getDisplayString(),
          leftType.getDisplayString(),
        ],
      );
    }
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    var valueType = node.matchedValueType;
    if (valueType == null) return;
    if (!node.operator.isEqualityTest) return;
    var operandType = node.operand.staticType;
    if (operandType == null) return;
    if (_nonComparable(valueType, operandType)) {
      rule.reportLint(
        node,
        errorCode: LinterLintCode.unrelated_type_equality_checks_in_pattern,
        arguments: [
          operandType.getDisplayString(),
          valueType.getDisplayString(),
        ],
      );
    }
  }

  bool _nonComparable(DartType leftType, DartType rightType) =>
      typesAreUnrelated(typeSystem, leftType, rightType) &&
      !(leftType.isFixnumIntX && rightType.isCoreInt);
}

extension on DartType? {
  bool get isCoreInt => this != null && this!.isDartCoreInt;

  bool get isFixnumIntX {
    var self = this;
    // TODO(pq): add tests that ensure this predicate works with fixnum >= 1.1.0-dev
    // See: https://github.com/dart-lang/linter/issues/3868
    if (self is! InterfaceType) return false;
    var element = self.element3;
    if (element.name != 'Int32' && element.name != 'Int64') return false;
    var uri = element.library2.firstFragment.source.uri;
    if (!uri.isScheme('package')) return false;
    return uri.pathSegments.firstOrNull == 'fixnum';
  }
}

extension on Token {
  bool get isEqualityTest =>
      type == TokenType.EQ_EQ || type == TokenType.BANG_EQ;
}
