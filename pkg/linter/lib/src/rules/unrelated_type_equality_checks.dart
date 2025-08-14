// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Equality operator `==` invocation with references of unrelated types.';

class UnrelatedTypeEqualityChecks extends MultiAnalysisRule {
  UnrelatedTypeEqualityChecks()
    : super(name: LintNames.unrelated_type_equality_checks, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.unrelatedTypeEqualityChecksInExpression,
    LinterLintCode.unrelatedTypeEqualityChecksInPattern,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context.typeSystem);
    registry.addBinaryExpression(this, visitor);
    registry.addRelationalPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;
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
    if (_comparable(leftType, rightType)) return;

    rule.reportAtToken(
      node.operator,
      diagnosticCode: LinterLintCode.unrelatedTypeEqualityChecksInExpression,
      arguments: [rightType.getDisplayString(), leftType.getDisplayString()],
    );
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    var valueType = node.matchedValueType;
    if (valueType == null) return;
    if (!node.operator.isEqualityTest) return;
    var operandType = node.operand.staticType;
    if (operandType == null) return;
    if (_comparable(valueType, operandType)) return;

    rule.reportAtNode(
      node,
      diagnosticCode: LinterLintCode.unrelatedTypeEqualityChecksInPattern,
      arguments: [operandType.getDisplayString(), valueType.getDisplayString()],
    );
  }

  /// Whether [leftType] and [rightType] are comparable.
  bool _comparable(DartType leftType, DartType rightType) =>
      (leftType.isFixnumIntX && rightType.isDartCoreInt) ||
      !typesAreUnrelated(typeSystem, leftType, rightType);
}

extension on DartType {
  bool get isFixnumIntX {
    var self = this;
    // TODO(pq): add tests that ensure this predicate works with fixnum >= 1.1.0-dev
    // See: https://github.com/dart-lang/linter/issues/3868
    if (self is! InterfaceType) return false;
    var element = self.element;
    if (element.name != 'Int32' && element.name != 'Int64') return false;
    var uri = element.library.uri;
    if (!uri.isScheme('package')) return false;
    return uri.pathSegments.firstOrNull == 'fixnum';
  }
}

extension on Token {
  bool get isEqualityTest =>
      type == TokenType.EQ_EQ || type == TokenType.BANG_EQ;
}
