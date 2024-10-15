// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r"Declare 'visit' methods for all registered node types.";

class VisitRegisteredNodes extends LintRule {
  static const LintCode code = LintCode('visit_registered_nodes', _desc,
      correctionMessage:
          "Try declaring a 'visit' method for all registered node types.",
      hasPublishedDocs: true);

  VisitRegisteredNodes()
      : super(
          name: 'visit_registered_nodes',
          description: _desc,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.inheritanceManager);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  final LintRule rule;
  final InheritanceManager3 inheritanceManager;
  _BodyVisitor(this.rule, this.inheritanceManager);

  bool implements(ClassElement2 visitor, String methodName) {
    var member = inheritanceManager.getMember4(visitor, Name(null, methodName),
        concrete: true);
    // In general lint visitors should only inherit from SimpleAstVisitors
    // (and the method implementations inherited from there are only stubs).
    // (We might consider enforcing this since it's harder to ensure that
    // Unifying and Generalizing visitors are doing the right thing.)
    // For now we flag methods inherited from SimpleAstVisitor since they
    // surely don't do anything.
    return member?.enclosingElement2?.name != 'SimpleAstVisitor';
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var targetType = node.target?.staticType;
    if (targetType is! InterfaceType) return;
    if (targetType.element3.name != 'NodeLintRegistry') return;
    var methodName = node.methodName.name;
    if (!methodName.startsWith('add')) return;
    var nodeType = methodName.substring(3);
    var args = node.argumentList.arguments;
    var argType = args[1].staticType;
    if (argType is! InterfaceType) return;
    var visitor = argType.element3;
    if (visitor is! ClassElement2) return;
    if (implements(visitor, 'visit$nodeType')) return;

    rule.reportLint(node.methodName);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final InheritanceManager3 inheritanceManager;

  _Visitor(this.rule, this.inheritanceManager);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'registerNodeProcessors') {
      node.body.accept(_BodyVisitor(rule, inheritanceManager));
    }
  }
}
