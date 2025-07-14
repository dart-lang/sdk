// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Missing deprecated annotation.';

class DeprecatedConsistency extends MultiAnalysisRule {
  DeprecatedConsistency()
    : super(name: LintNames.deprecated_consistency, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.deprecated_consistency_constructor,
    LinterLintCode.deprecated_consistency_field,
    LinterLintCode.deprecated_consistency_parameter,
  ];

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var constructorElement = node.declaredFragment?.element;
    if (constructorElement != null &&
        constructorElement.enclosingElement.hasDeprecated &&
        !constructorElement.hasDeprecated) {
      var nodeToAnnotate = node.name ?? node.returnType;
      rule.reportAtOffset(
        nodeToAnnotate.offset,
        nodeToAnnotate.length,
        diagnosticCode: LinterLintCode.deprecated_consistency_constructor,
      );
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is! FieldFormalParameterElement) return;

    var field = declaredElement.field;
    if (field == null) return;

    if (field.hasDeprecated && !declaredElement.hasDeprecated) {
      rule.reportAtNode(
        node,
        diagnosticCode: LinterLintCode.deprecated_consistency_field,
      );
    }
    if (!field.hasDeprecated && declaredElement.hasDeprecated) {
      var fieldFragment = field.firstFragment;
      var nameOffset = fieldFragment.nameOffset;
      if (nameOffset == null) return;
      var nameLength = fieldFragment.name?.length;
      if (nameLength == null) return;
      rule.reportAtOffset(
        nameOffset,
        nameLength,
        diagnosticCode: LinterLintCode.deprecated_consistency_parameter,
      );
    }
  }
}

extension on Annotatable {
  bool get hasDeprecated => metadata.hasDeprecated;
}
