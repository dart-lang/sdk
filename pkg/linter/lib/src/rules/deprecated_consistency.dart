// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Missing deprecated annotation.';

class DeprecatedConsistency extends MultiAnalysisRule {
  DeprecatedConsistency()
    : super(name: LintNames.deprecated_consistency, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.deprecatedConsistencyConstructor,
    diag.deprecatedConsistencyField,
    diag.deprecatedConsistencyParameter,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldFormalParameter(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkConstructor(node.declaredFragment!.element, node.errorRange);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkParameter(node);
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    _checkConstructor(node.declaredFragment!.element, node.errorRange);
  }

  void _checkConstructor(ConstructorElement element, SourceRange sourceRange) {
    if (element.enclosingElement.metadata.hasDeprecated &&
        !element.metadata.hasDeprecated) {
      rule.reportAtOffset(
        sourceRange.offset,
        sourceRange.length,
        diagnosticCode: diag.deprecatedConsistencyConstructor,
      );
    }
  }

  void _checkParameter(FormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is! FieldFormalParameterElement) return;

    var field = declaredElement.field;
    if (field == null) return;

    if (field.metadata.hasDeprecated &&
        !declaredElement.metadata.hasDeprecated) {
      rule.reportAtNode(node, diagnosticCode: diag.deprecatedConsistencyField);
    }
    if (!field.metadata.hasDeprecated &&
        declaredElement.metadata.hasDeprecated) {
      var fieldFragment = field.firstFragment;
      var nameOffset = fieldFragment.nameOffset;
      if (nameOffset == null) return;
      var nameLength = fieldFragment.name?.length;
      if (nameLength == null) return;
      rule.reportAtOffset(
        nameOffset,
        nameLength,
        diagnosticCode: diag.deprecatedConsistencyParameter,
      );
    }
  }
}
