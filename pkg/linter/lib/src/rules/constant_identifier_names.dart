// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../utils.dart';

const _desc = r'Prefer using lowerCamelCase for constant names.';

class ConstantIdentifierNames extends LintRule {
  ConstantIdentifierNames()
      : super(
          name: LintNames.constant_identifier_names,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.constant_identifier_names;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addEnumConstantDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkIdentifier(Token id) {
    var name = id.lexeme;
    if (!isLowerCamelCase(name)) {
      rule.reportLintForToken(id, arguments: [name]);
    }
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.parent.isFieldNameShortcut) return;
    checkIdentifier(node.name);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (node.isAugmentation) return;

    checkIdentifier(node.name);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.isAugmentation) return;

    visitVariableDeclarationList(node.variables);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.parent?.isAugmentation ?? false) return;

    for (var v in node.variables) {
      if (v.isConst) {
        checkIdentifier(v.name);
      }
    }
  }
}
