// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid setters without getters.';

class AvoidSettersWithoutGetters extends LintRule {
  AvoidSettersWithoutGetters()
    : super(name: LintNames.avoid_setters_without_getters, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoid_setters_without_getters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
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
      if (!member.isSetter) continue;

      var element = member.declaredFragment?.element;
      var interface = element?.enclosingElement;
      if (interface is! InterfaceElement) continue;

      var name = Name.forElement(element!);
      if (name == null) continue;

      // If we're overriding a setter, don't report here.
      var overridden = interface.getOverridden(name);
      if (overridden != null && overridden.isNotEmpty) continue;

      var getterName = element.name;
      if (getterName == null) continue;

      var getter =
          // Check for a declared (static) getter.
          interface.getGetter(getterName) ??
          // Then look for an inherited one.
          interface.getInheritedConcreteMember(name.forGetter);

      if (getter == null) {
        rule.reportAtToken(member.name);
      }
    }
  }
}
