// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't explicitly initialize variables to `null`.";

class AvoidInitToNull extends LintRule {
  AvoidInitToNull()
      : super(
          name: LintNames.avoid_init_to_null,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_init_to_null;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addVariableDeclaration(this, visitor);
    registry.addDefaultFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  bool isNullable(DartType type) => context.typeSystem.isNullable(type);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var declaredElement = node.declaredElement;
    if (declaredElement == null) return;

    if (declaredElement is SuperFormalParameterElement) {
      var superConstructorParameter = declaredElement.superConstructorParameter;
      if (superConstructorParameter is! ParameterElement) return;
      var defaultValue = superConstructorParameter.defaultValueCode ?? 'null';
      if (defaultValue != 'null') return;
    }

    if (node.defaultValue.isNullLiteral && isNullable(declaredElement.type)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement != null &&
        !node.isConst &&
        !node.isFinal &&
        node.initializer.isNullLiteral &&
        isNullable(declaredElement.type)) {
      rule.reportLint(node);
    }
  }
}
