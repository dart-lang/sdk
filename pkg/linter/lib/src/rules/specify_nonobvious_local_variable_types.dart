// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/obvious_types.dart';

const _desc = r'Specify non-obvious type annotations for local variables.';

class SpecifyNonObviousLocalVariableTypes extends AnalysisRule {
  SpecifyNonObviousLocalVariableTypes()
    : super(
        name: LintNames.specify_nonobvious_local_variable_types,
        description: _desc,
        state: RuleState.stable(since: Version(3, 11, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.specifyNonobviousLocalVariableTypes;

  @override
  List<String> get incompatibleRules => const [
    LintNames.omit_local_variable_types,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addPatternVariableDeclarationStatement(this, visitor);
    registry.addSwitchExpression(this, visitor);
    registry.addSwitchStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _PatternVisitor extends GeneralizingAstVisitor<void> {
  final AnalysisRule rule;

  _PatternVisitor(this.rule);

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var staticType = node.type?.type;
    if (staticType != null &&
        staticType is! DynamicType &&
        !staticType.isDartCoreNull) {
      return;
    }
    rule.reportAtNode(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithDeclarations) {
      _visitVariableDeclarationList(loopParts.variables);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      var loopVariableType = loopParts.loopVariable.type;
      var staticType = loopVariableType?.type;
      if (staticType != null && staticType is! DynamicType) {
        return;
      }
      var iterable = loopParts.iterable;
      if (iterable.hasObviousType) {
        return;
      }
      rule.reportAtNode(loopParts.loopVariable);
    }
  }

  @override
  void visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    if (node.declaration.expression.hasObviousType) return;
    _PatternVisitor(rule).visitDartPattern(node.declaration.pattern);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    if (node.expression.hasObviousType) return;
    node.cases.forEach(_PatternVisitor(rule).visitSwitchExpressionCase);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (node.expression.hasObviousType) return;
    for (SwitchMember member in node.members) {
      if (member is SwitchPatternCase) {
        _PatternVisitor(rule).visitSwitchPatternCase(member);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType != null && !staticType.isDartCoreNull) {
      return;
    }
    bool aDeclaredTypeIsNeeded = false;
    var variablesThatNeedAType = <VariableDeclaration>[];
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer == null) {
        aDeclaredTypeIsNeeded = true;
        variablesThatNeedAType.add(child);
      } else {
        if (!initializer.hasObviousType) {
          aDeclaredTypeIsNeeded = true;
          variablesThatNeedAType.add(child);
        }
      }
    }
    if (aDeclaredTypeIsNeeded) {
      if (node.variables.length == 1) {
        rule.reportAtNode(node);
      } else {
        // Multiple variables, report each of them separately. No fix.
        variablesThatNeedAType.forEach(rule.reportAtNode);
      }
    }
  }
}
