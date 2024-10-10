// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = "Don't type annotate initializing formals.";

class TypeInitFormals extends LintRule {
  TypeInitFormals()
      : super(
          name: LintNames.type_init_formals,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.type_init_formals;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldFormalParameter(this, visitor);
    registry.addSuperFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var nodeType = node.type;
    if (nodeType == null) return;

    var paramElement = node.declaredElement;
    if (paramElement is! FieldFormalParameterElement) return;

    var field = paramElement.field;
    // If no such field exists, the code is invalid; do not report lint.
    if (field != null && nodeType.type == field.type) {
      rule.reportLint(nodeType);
    }
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    var nodeType = node.type;
    if (nodeType == null) return;

    var paramElement = node.declaredElement;
    if (paramElement is! SuperFormalParameterElement) return;

    var superConstructorParameter = paramElement.superConstructorParameter;
    if (superConstructorParameter == null) return;

    if (superConstructorParameter.type == nodeType.type) {
      rule.reportLint(nodeType);
    }
  }
}
