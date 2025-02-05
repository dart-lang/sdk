// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

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
    var visitor = _Visitor(this, context.inheritanceManager);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    // TODO(pq): consider visiting mixin declarations
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final InheritanceManager3 inheritanceManager;

  _Visitor(this.rule, this.inheritanceManager);

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
      if (!member.isSetter) continue;

      var element = member.declaredFragment?.element;
      var interface = element?.enclosingElement2;
      if (interface is! InterfaceElement2) continue;

      var name = Name.forElement(element!);
      if (name == null) continue;

      // If we're overriding a setter, don't report here.
      var overridden = inheritanceManager.getOverridden4(interface, name);
      if (overridden != null && overridden.isNotEmpty) continue;

      var getterName = element.name3;
      if (getterName == null) continue;

      // Check for a declared (static) getter.
      ExecutableElement2? getter = interface.getGetter2(getterName);
      // Then look up for an inherited one.
      getter ??= inheritanceManager.getMember4(interface, name.forGetter,
          concrete: true);

      if (getter == null) {
        rule.reportLintForToken(member.name);
      }
    }
  }
}
