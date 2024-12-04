// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid setters without getters.';

class AvoidSettersWithoutGetters extends LintRule {
  AvoidSettersWithoutGetters()
      : super(
          name: LintNames.avoid_setters_without_getters,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_setters_without_getters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    // TODO(pq): consider visiting mixin declarations
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    visitMembers(node.members);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    visitMembers(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    visitMembers(node.members);
  }

  void visitMembers(NodeList<ClassMember> members) {
    for (var member in members.whereType<MethodDeclaration>()) {
      if (member.isSetter &&
          member.lookUpInheritedConcreteSetter() == null &&
          member.lookUpGetter() == null) {
        rule.reportLintForToken(member.name);
      }
    }
  }
}
