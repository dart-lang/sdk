// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show PrefixExpression, PrefixedIdentifier, PropertyAccess, SimpleIdentifier;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Use `isNotEmpty` for `Iterable`s and `Map`s.';

class PreferIsNotEmpty extends LintRule {
  PreferIsNotEmpty()
    : super(name: LintNames.prefer_is_not_empty, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferIsNotEmpty;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addPrefixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitPrefixExpression(PrefixExpression node) {
    // Should be prefixed w/ a "!".
    var prefix = node.operator;
    if (prefix.type != TokenType.BANG) {
      return;
    }

    var expression = node.operand.unParenthesized;

    // Should be a property access or prefixed identifier.
    SimpleIdentifier? isEmptyIdentifier;
    if (expression is PropertyAccess) {
      isEmptyIdentifier = expression.propertyName;
    } else if (expression is PrefixedIdentifier) {
      isEmptyIdentifier = expression.identifier;
    }
    if (isEmptyIdentifier == null) {
      return;
    }

    // Element identifier should be "isEmpty".
    var propertyElement = isEmptyIdentifier.element;
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      return;
    }

    // Element should also support "isNotEmpty".
    var propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
      return;
    }

    rule.reportAtNode(node);
  }
}
