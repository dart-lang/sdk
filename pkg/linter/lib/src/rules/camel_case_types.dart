// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../utils.dart';

const _desc = r'Name types using UpperCamelCase.';

class CamelCaseTypes extends AnalysisRule {
  CamelCaseTypes()
    : super(name: LintNames.camel_case_types, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.camelCaseTypes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addGenericTypeAlias(this, visitor);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  void check(Token name) {
    var lexeme = name.lexeme;
    if (!isCamelCase(lexeme)) {
      rule.reportAtToken(name, arguments: [lexeme]);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    check(node.name);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    check(node.name);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    check(node.name);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }
}
