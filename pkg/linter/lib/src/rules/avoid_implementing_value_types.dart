// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't implement classes that override `==`.";

class AvoidImplementingValueTypes extends LintRule {
  AvoidImplementingValueTypes()
      : super(
          name: LintNames.avoid_implementing_value_types,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_implementing_value_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.inheritanceManager);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static var equalsName = Name(null, '==');

  final LintRule rule;
  final InheritanceManager3 inheritanceManager;

  _Visitor(this.rule, this.inheritanceManager);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var implementsClause = node.implementsClause;
    if (implementsClause == null) {
      return;
    }

    for (var interface in implementsClause.interfaces) {
      var interfaceType = interface.type;
      if (interfaceType is InterfaceType &&
          _overridesEquals(interfaceType.element3)) {
        rule.reportLint(interface);
      }
    }
  }

  bool _overridesEquals(InterfaceElement2 element) {
    var member =
        inheritanceManager.getMember4(element, equalsName, concrete: true);
    var definingLibrary = member?.enclosingElement2?.library2;
    return definingLibrary != null && !definingLibrary.isDartCore;
  }
}
