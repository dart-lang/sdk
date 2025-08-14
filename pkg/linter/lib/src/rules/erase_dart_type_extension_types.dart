// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

// TODO(nshahan): update description as scope increases.
const _desc = r"Don't do 'is' checks on DartTypes.";

class EraseDartTypeExtensionTypes extends LintRule {
  EraseDartTypeExtensionTypes()
    : super(
        name: LintNames.erase_dart_type_extension_types,
        description: _desc,
        state: const RuleState.internal(),
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.eraseDartTypeExtensionTypes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addIsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  visitIsExpression(IsExpression node) {
    var type = node.type.type;
    if (type != null && type.implementsInterface('DartType', 'kernel.ast')) {
      rule.reportAtNode(node);
    }
  }
}
