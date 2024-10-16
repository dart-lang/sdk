// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r'Property getter recursively returns itself.';

class RecursiveGetters extends LintRule {
  RecursiveGetters()
      : super(
          name: LintNames.recursive_getters,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.recursive_getters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  final LintRule rule;
  final ExecutableElement2 element;
  _BodyVisitor(this.element, this.rule);

  bool isSelfReference(SimpleIdentifier node) {
    if (node.element != element) return false;
    var parent = node.parent;
    if (parent is PrefixedIdentifier) return false;
    if (parent is PropertyAccess && parent.target is! ThisExpression) {
      return false;
    }
    return true;
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.isConst) return;
    return super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isConst) return;
    return super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (isSelfReference(node)) {
      rule.reportLint(node, arguments: [node.name]);
    }

    // No need to call super visit (SimpleIdentifiers have no children).
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.functionExpression.parameters != null) return;

    _verifyElement(node.functionExpression, node.declaredFragment?.element);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.parameters != null) return;

    _verifyElement(node.body, node.declaredFragment?.element);
  }

  void _verifyElement(AstNode node, ExecutableElement2? element) {
    if (element == null) return;
    node.accept(_BodyVisitor(element, rule));
  }
}
