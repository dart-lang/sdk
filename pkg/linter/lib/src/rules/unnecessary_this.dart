// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../util/scope.dart';

const _desc = r"Don't access members with `this` unless avoiding shadowing.";

class UnnecessaryThis extends LintRule {
  UnnecessaryThis()
      : super(
          name: LintNames.unnecessary_this,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_this;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstructorFieldInitializer(this, visitor);
    registry.addThisExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.thisKeyword != null) {
      rule.reportLintForToken(node.thisKeyword);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    var parent = node.parent;

    Element2? element;
    if (parent is PropertyAccess && !parent.isNullAware) {
      element = getWriteOrReadElement2(parent.propertyName);
    } else if (parent is MethodInvocation && !parent.isNullAware) {
      element = parent.methodName.element;
    } else {
      return;
    }

    if (_canReferenceElementWithoutThisPrefix(element, node)) {
      rule.reportLintForToken(node.thisKeyword);
    }
  }

  bool _canReferenceElementWithoutThisPrefix(Element2? element, AstNode node) {
    if (element == null) return false;

    var id = element.displayName;
    var result = resolveNameInScope(id, node,
        shouldResolveSetter: element is SetterElement);

    // No result, definitely no shadowing.
    // The requested element is inherited, or from an extension.
    if (result.isNone) return true;

    var resultElement = result.element;

    // The result has the matching name, might be shadowing.
    // Check that the element is the same.
    if (result.isRequestedName) {
      return resultElement == element;
    }

    // The result has the same basename, but not the same name.
    // Must be an instance member, so that:
    //  - not shadowed by a local declaration;
    //  - prevents us from going up to the library scope;
    //  - the requested element must be inherited, or from an extension.
    if (result.isDifferentName) {
      var enclosing = resultElement?.enclosingElement2;
      return enclosing is ClassElement2;
    }

    // Should not happen.
    return false;
  }
}
