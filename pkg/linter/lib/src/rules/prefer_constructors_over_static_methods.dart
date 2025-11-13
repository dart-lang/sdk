// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    r'Prefer defining constructors instead of static methods to create '
    'instances.';

bool _hasNewInvocation(DartType returnType, FunctionBody body) =>
    _BodyVisitor(returnType).containsInstanceCreation(body);

class PreferConstructorsOverStaticMethods extends AnalysisRule {
  PreferConstructorsOverStaticMethods()
    : super(
        name: LintNames.prefer_constructors_over_static_methods,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.preferConstructorsOverStaticMethods;

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
  final AnalysisRule rule;

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
      rule.reportAtToken(node.name);
    }
  }
}

extension on AstNode? {
  InterfaceType? typeToCheckOrNull() => switch (this) {
    ExtensionTypeDeclaration e =>
      e.typeParameters == null ? e.declaredFragment?.element.thisType : null,
    ClassDeclaration c =>
      c.typeParameters == null ? c.declaredFragment?.element.thisType : null,
    _ => null,
  };
}
