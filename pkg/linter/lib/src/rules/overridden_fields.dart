// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't override fields.";

class OverriddenFields extends LintRule {
  OverriddenFields()
      : super(
          name: LintNames.overridden_fields,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.overridden_fields;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.inheritanceManager);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final InheritanceManager3 inheritanceManager;

  _Visitor(this.rule, this.inheritanceManager);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isAugmentation) return;
    if (node.isStatic) return;

    for (var variable in node.fields.variables) {
      var parent = variable.declaredFragment?.element.enclosingElement2;
      if (parent is InterfaceElement2) {
        var overriddenMember = inheritanceManager.getMember4(
            parent, Name(parent.library2.uri, variable.name.lexeme),
            forSuper: true);
        if (overriddenMember is GetterElement && overriddenMember.isSynthetic) {
          var definingInterface = overriddenMember.enclosingElement2;
          if (definingInterface != null) {
            rule.reportLintForToken(variable.name,
                arguments: [definingInterface.displayName]);
          }
        }
      }
    }
  }
}
