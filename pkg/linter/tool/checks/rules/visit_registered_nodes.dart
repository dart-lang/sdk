// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:linter/src/analyzer.dart';

class VisitRegisteredNodes extends LintRule {
  static const DiagnosticCode code = LinterLintCode.visitRegisteredNodes;

  VisitRegisteredNodes()
    : super(
        name: 'visit_registered_nodes',
        description: "Declare 'visit' methods for all registered node types.",
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  final LintRule rule;
  _BodyVisitor(this.rule);

  bool implements(ClassElement visitor, String methodName) {
    var member = visitor.lookUpConcreteMethod(methodName, visitor.library);
    // In general lint visitors should only inherit from [SimpleAstVisitor]s
    // (and the method implementations inherited from there are only stubs).
    // (We might consider enforcing this since it's harder to ensure that
    // Unifying and Generalizing visitors are doing the right thing.)
    // For now we flag methods inherited from SimpleAstVisitor since they
    // surely don't do anything.
    return member?.enclosingElement?.name != 'SimpleAstVisitor';
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var targetType = node.target?.staticType;
    if (targetType is! InterfaceType) return;
    if (targetType.element.name != 'RuleVisitorRegistry') return;
    var methodName = node.methodName.name;
    if (!methodName.startsWith('add')) return;
    var nodeType = methodName.substring(3);
    var args = node.argumentList.arguments;
    var argType = args[1].staticType;
    if (argType is! InterfaceType) return;
    var visitor = argType.element;
    if (visitor is! ClassElement) return;
    if (implements(visitor, 'visit$nodeType')) return;

    rule.reportAtNode(node.methodName);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'registerNodeProcessors') {
      node.body.accept(_BodyVisitor(rule));
    }
  }
}
