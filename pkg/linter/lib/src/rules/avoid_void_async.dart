// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid `async` functions that return `void`.';

class AvoidVoidAsync extends AnalysisRule {
  AvoidVoidAsync()
    : super(name: LintNames.avoid_void_async, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.avoidVoidAsync;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == 'main' && node.parent is CompilationUnit) return;
    _check(fragment: node.declaredFragment, errorNode: node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(fragment: node.declaredFragment, errorNode: node.name);
  }

  void _check({
    required ExecutableFragment? fragment,
    required Token errorNode,
  }) {
    if (fragment == null) return;
    if (fragment.isGenerator) return;
    if (!fragment.isAsynchronous) return;
    if (fragment.element.returnType is VoidType) {
      rule.reportAtToken(errorNode);
    }
  }
}
