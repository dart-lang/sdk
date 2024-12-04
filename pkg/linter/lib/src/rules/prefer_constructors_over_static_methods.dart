// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer defining constructors instead of static methods to create '
    'instances.';

bool _hasNewInvocation(DartType returnType, FunctionBody body) =>
    _BodyVisitor(returnType).containsInstanceCreation(body);

class PreferConstructorsOverStaticMethods extends LintRule {
  PreferConstructorsOverStaticMethods()
      : super(
          name: LintNames.prefer_constructors_over_static_methods,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.prefer_constructors_over_static_methods;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  final DartType returnType;
  _BodyVisitor(this.returnType);

  bool containsInstanceCreation(FunctionBody body) {
    body.accept(this);
    return found;
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    // TODO(srawlins): This assignment overrides existing `found` values.
    // For example, given `() { C(); D(); }`, if `C` was the return type being
    // sought, then the `found` value is overridden when we visit `D()`.
    found = node.staticType == returnType;
    if (!found) {
      super.visitInstanceCreationExpression(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic) return;
    if (node.typeParameters != null) return;
    var returnType = node.returnType?.type;
    if (returnType is! InterfaceType) return;

    var interfaceType = node.parent.typeToCheckOrNull();
    if (interfaceType != returnType) return;

    if (_hasNewInvocation(returnType, node.body)) {
      rule.reportLintForToken(node.name);
    }
  }
}

extension on AstNode? {
  InterfaceType? typeToCheckOrNull() => switch (this) {
        ExtensionTypeDeclaration e => e.typeParameters == null
            ? e.declaredFragment?.element.thisType
            : null,
        ClassDeclaration c => c.typeParameters == null
            ? c.declaredFragment?.element.thisType
            : null,
        _ => null
      };
}
