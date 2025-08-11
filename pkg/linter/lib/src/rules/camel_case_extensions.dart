// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Name extensions using UpperCamelCase.';

class CamelCaseExtensions extends LintRule {
  CamelCaseExtensions()
    : super(name: LintNames.camel_case_extensions, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.camel_case_extensions;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addExtensionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // Don't lint augmentations.
    if (node.augmentKeyword != null) return;

    var name = node.name;
    if (name != null && !isCamelCase(name.lexeme)) {
      rule.reportAtToken(name, arguments: [name.lexeme]);
    }
  }
}
