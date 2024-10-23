// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show PrefixExpression, PrefixedIdentifier, PropertyAccess, SimpleIdentifier;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Use `isNotEmpty` for `Iterable`s and `Map`s.';

class PreferIsNotEmpty extends LintRule {
  PreferIsNotEmpty()
      : super(
          name: LintNames.prefer_is_not_empty,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_is_not_empty;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
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
    if (propertyElement == null || 'isEmpty' != propertyElement.name3) {
      return;
    }

    // Element should also support "isNotEmpty".
    var propertyTarget = propertyElement.enclosingElement2;
    if (propertyTarget == null ||
        getChildren2(propertyTarget, 'isNotEmpty').isEmpty) {
      return;
    }

    rule.reportLint(node);
  }
}
