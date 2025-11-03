// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't implement classes that override `==`.";

class AvoidImplementingValueTypes extends AnalysisRule {
  AvoidImplementingValueTypes()
    : super(name: LintNames.avoid_implementing_value_types, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidImplementingValueTypes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static var equalsName = Name(null, '==');

  final AnalysisRule rule;

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
        rule.reportAtNode(interface);
      }
    }
  }

  bool _overridesEquals(InterfaceElement element) {
    var member = element.getInterfaceMember(equalsName);
    var definingLibrary = member?.enclosingElement?.library;
    return definingLibrary != null && !definingLibrary.isDartCore;
  }
}
