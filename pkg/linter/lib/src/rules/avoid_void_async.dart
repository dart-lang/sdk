// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid `async` functions that return `void`.';

class AvoidVoidAsync extends LintRule {
  AvoidVoidAsync()
      : super(
          name: LintNames.avoid_void_async,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_void_async;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == 'main' && node.parent is CompilationUnit) return;
    _check(
      fragment: node.declaredFragment,
      errorNode: node.name,
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(
      fragment: node.declaredFragment,
      errorNode: node.name,
    );
  }

  void _check({
    required ExecutableFragment? fragment,
    required Token errorNode,
  }) {
    if (fragment == null) return;
    if (fragment.isGenerator) return;
    if (!fragment.isAsynchronous) return;
    if (fragment.element.returnType is VoidType) {
      rule.reportLintForToken(errorNode);
    }
  }
}
