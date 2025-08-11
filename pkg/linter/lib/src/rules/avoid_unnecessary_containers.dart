// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Avoid unnecessary containers.';

class AvoidUnnecessaryContainers extends LintRule {
  AvoidUnnecessaryContainers()
    : super(name: LintNames.avoid_unnecessary_containers, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoid_unnecessary_containers;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);

    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isWidgetType(node.staticType)) {
      return;
    }
    var parent = node.parent;
    if (parent is NamedExpression && parent.name.label.name == 'child') {
      var args = parent.thisOrAncestorOfType<ArgumentList>();
      if (args?.arguments.length == 1) {
        var parentCreation =
            parent.thisOrAncestorOfType<InstanceCreationExpression>();
        if (parentCreation != null) {
          if (isExactWidgetTypeContainer(parentCreation.staticType)) {
            rule.reportAtNode(parentCreation.constructorName);
          }
        }
      }
    }
  }
}
