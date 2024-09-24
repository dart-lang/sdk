// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r"Don't implement classes that override `==`.";

class AvoidImplementingValueTypes extends LintRule {
  AvoidImplementingValueTypes()
      : super(
          name: 'avoid_implementing_value_types',
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_implementing_value_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var implementsClause = node.implementsClause;
    if (implementsClause == null) {
      return;
    }
    for (var interface in implementsClause.interfaces) {
      var interfaceType = interface.type;
      if (interfaceType is InterfaceType &&
          _overridesEquals(interfaceType.element)) {
        rule.reportLint(interface);
      }
    }
  }

  static bool _overridesEquals(InterfaceElement element) {
    var method = element.lookUpConcreteMethod('==', element.library);
    var enclosing = method?.enclosingElement3;
    return enclosing is ClassElement && !enclosing.isDartCoreObject;
  }
}
