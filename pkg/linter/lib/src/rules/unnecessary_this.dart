// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../diagnostic.dart' as diag;
import '../util/scope.dart';

const _desc = r"Don't access members with `this` unless avoiding shadowing.";

class UnnecessaryThis extends AnalysisRule {
  UnnecessaryThis()
    : super(name: LintNames.unnecessary_this, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryThis;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConstructorFieldInitializer(this, visitor);
    registry.addThisExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var thisKeyword = node.thisKeyword;
    if (thisKeyword != null) {
      rule.reportAtToken(thisKeyword);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    var parent = node.parent;

    Element? element;
    if (parent is PropertyAccess && !parent.isNullAware) {
      element = getWriteOrReadElement(parent.propertyName);
    } else if (parent is MethodInvocation && !parent.isNullAware) {
      element = parent.methodName.element;
    } else {
      return;
    }

    element = element?.baseElement;
    if (_canReferenceElementWithoutThisPrefix(element, node)) {
      rule.reportAtToken(node.thisKeyword);
    }
  }

  bool _canReferenceElementWithoutThisPrefix(Element? element, AstNode node) {
    if (element == null) return false;

    var id = element.displayName;
    var result = resolveNameInScope(
      id,
      node,
      shouldResolveSetter: element is SetterElement,
    );

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
      var enclosing = resultElement?.enclosingElement;
      return enclosing is ClassElement;
    }

    // Should not happen.
    return false;
  }
}
