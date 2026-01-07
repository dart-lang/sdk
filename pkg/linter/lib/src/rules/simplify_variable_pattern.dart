// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = 'Avoid unnecessary member names in variable patterns.';

class SimplifyVariablePattern extends AnalysisRule {
  SimplifyVariablePattern()
    : super(name: LintNames.simplify_variable_pattern, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.simplifyVariablePattern;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.patterns)) return;
    var visitor = _Visitor(this, context);
    registry.addPatternField(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitPatternField(PatternField node) {
    var pattern = node.pattern;
    if (pattern is! DeclaredVariablePattern) return;
    if (node.name?.name case Token(:var isSynthetic, :var lexeme) && var name
        when !isSynthetic && pattern.name.lexeme == lexeme) {
      // Make sure the name exists
      if (node.parent case RecordPattern(:var matchedValueType)) {
        if (matchedValueType is! RecordType) {
          return;
        }
        if (!matchedValueType.namedFields
            .map((field) => field.name)
            .contains(lexeme)) {
          return;
        }
      } else if (node.parent case ObjectPattern(
        type: NamedType(:var element?),
      )) {
        if (element is! InstanceElement) {
          return;
        }
        var methods = element.methods.map((e) => e.name).toList();
        if (element.isDartCoreFunction) {
          methods.add(MethodElement.CALL_METHOD_NAME);
        }
        if (!element.getters.map((e) => e.name).contains(lexeme) &&
            !methods.contains(lexeme)) {
          return;
        }
      } else {
        return;
      }
      rule.reportAtToken(name, arguments: [lexeme, _accessor(node)]);
    }
    super.visitPatternField(node);
  }

  String _accessor(PatternField field) => switch (field.parent) {
    ObjectPattern() when field.element is MethodElement => 'method',
    ObjectPattern() when field.element is GetterElement => 'getter',
    _ => 'field',
  };
}

extension on InstanceElement {
  bool get isDartCoreFunction => library.isDartCore && name == 'Function';
}
