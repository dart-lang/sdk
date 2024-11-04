// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r'Missing deprecated annotation.';

class DeprecatedConsistency extends LintRule {
  DeprecatedConsistency()
      : super(
          name: LintNames.deprecated_consistency,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.deprecated_consistency_constructor,
        LinterLintCode.deprecated_consistency_field,
        LinterLintCode.deprecated_consistency_parameter
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var constructorElement = node.declaredFragment?.element;
    if (constructorElement != null &&
        constructorElement.enclosingElement2.hasDeprecated &&
        !constructorElement.hasDeprecated) {
      var nodeToAnnotate = node.name ?? node.returnType;
      rule.reportLintForOffset(nodeToAnnotate.offset, nodeToAnnotate.length,
          errorCode: LinterLintCode.deprecated_consistency_constructor);
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is! FieldFormalParameterElement2) return;

    var field = declaredElement.field2;
    if (field == null) return;

    if (field.hasDeprecated && !declaredElement.hasDeprecated) {
      rule.reportLint(node,
          errorCode: LinterLintCode.deprecated_consistency_field);
    }
    if (!field.hasDeprecated && declaredElement.hasDeprecated) {
      var fieldFragment = field.firstFragment;
      var nameOffset = fieldFragment.nameOffset2;
      if (nameOffset == null) return;
      var nameLength = fieldFragment.name2?.length;
      if (nameLength == null) return;
      rule.reportLintForOffset(nameOffset, nameLength,
          errorCode: LinterLintCode.deprecated_consistency_parameter);
    }
  }
}

extension on Annotatable {
  bool get hasDeprecated => metadata2.hasDeprecated;
}
