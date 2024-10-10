// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Sort constructor declarations before other members.';

class SortConstructorsFirst extends LintRule {
  SortConstructorsFirst()
      : super(
          name: LintNames.sort_constructors_first,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.sort_constructors_first;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(NodeList<ClassMember> members) {
    var other = false;
    // Members are sorted by source position in the AST.
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        if (other) {
          rule.reportLint(member.returnType);
        }
      } else {
        other = true;
      }
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    check(node.members);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    check(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    check(node.members);
  }
}
