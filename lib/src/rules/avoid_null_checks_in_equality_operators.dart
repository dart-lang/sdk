// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't check for null in custom == operators.";

const _details = r'''
**DON'T** check for null in custom == operators.

As null is a special value, no instance of any class (other than `Null`) can be
equivalent to it.  Thus, it is redundant to check whether the other instance is
null.

**BAD:**
```dart
class Person {
  final String? name;

  @override
  operator ==(Object? other) =>
      other != null && other is Person && name == other.name;
}
```

**GOOD:**
```dart
class Person {
  final String? name;

  @override
  operator ==(Object? other) => other is Person && name == other.name;
}
```

''';

bool _isComparingEquality(TokenType tokenType) =>
    tokenType == TokenType.BANG_EQ || tokenType == TokenType.EQ_EQ;

bool _isComparingParameterWithNull(BinaryExpression node, Element? parameter) =>
    _isComparingEquality(node.operator.type) &&
    ((node.leftOperand.isNullLiteral &&
            _isParameter(node.rightOperand, parameter)) ||
        (node.rightOperand.isNullLiteral &&
            _isParameter(node.leftOperand, parameter)));

bool _isParameter(Expression expression, Element? parameter) =>
    expression.canonicalElement == parameter;

bool _isParameterWithQuestionQuestion(
        BinaryExpression node, Element? parameter) =>
    node.operator.type == TokenType.QUESTION_QUESTION &&
    _isParameter(node.leftOperand, parameter);

class AvoidNullChecksInEqualityOperators extends LintRule {
  static const LintCode code = LintCode(
      'avoid_null_checks_in_equality_operators',
      "Unnecessary null comparison in implementation of '=='.",
      correctionMessage: 'Try removing the comparison.');

  AvoidNullChecksInEqualityOperators()
      : super(
            name: 'avoid_null_checks_in_equality_operators',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor =
        _Visitor(this, nnbdEnabled: context.isEnabled(Feature.non_nullable));
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor {
  final Element? parameter;
  final LintRule rule;
  _BodyVisitor(this.parameter, this.rule);

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (_isParameterWithQuestionQuestion(node, parameter) ||
        _isComparingParameterWithNull(node, parameter)) {
      rule.reportLint(node);
    }
    super.visitBinaryExpression(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.operator?.type == TokenType.QUESTION_PERIOD &&
        node.target.canonicalElement == parameter) {
      rule.reportLint(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.operator.type == TokenType.QUESTION_PERIOD &&
        node.target.canonicalElement == parameter) {
      rule.reportLint(node);
    }
    super.visitPropertyAccess(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final bool nnbdEnabled;

  _Visitor(this.rule, {required this.nnbdEnabled});

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var parameters = node.parameters?.parameters;
    if (parameters == null) {
      return;
    }

    if (node.name.type != TokenType.EQ_EQ || parameters.length != 1) {
      return;
    }

    var parameter = parameters.first.declaredElement?.canonicalElement;

    // Analyzer will produce UNNECESSARY_NULL_COMPARISON_FALSE|TRUE
    // See: https://github.com/dart-lang/linter/issues/2864
    if (nnbdEnabled &&
        parameter is VariableElement &&
        parameter.type.nullabilitySuffix != NullabilitySuffix.question) {
      return;
    }

    node.body.accept(_BodyVisitor(parameter, rule));
  }
}
