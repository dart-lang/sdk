// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary `.new` constructor name.';

class UnnecessaryConstructorName extends LintRule {
  UnnecessaryConstructorName()
      : super(
          name: LintNames.unnecessary_constructor_name,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_constructor_name;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addRepresentationConstructorName(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var parent = node.parent;
    if (parent is ExtensionTypeDeclaration &&
        parent.representation.constructorName == null) {
      return;
    }

    _check(node.name);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.constructorName.name?.token);
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    _check(node.name);
  }

  void _check(Token? name) {
    if (name?.lexeme == 'new') {
      rule.reportLintForToken(name);
    }
  }
}
