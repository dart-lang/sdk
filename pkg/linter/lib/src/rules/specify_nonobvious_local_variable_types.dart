// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/obvious_types.dart';

const _desc = r'Specify non-obvious type annotations for local variables.';

class SpecifyNonObviousLocalVariableTypes extends LintRule {
  SpecifyNonObviousLocalVariableTypes()
      : super(
          name: LintNames.specify_nonobvious_local_variable_types,
          description: _desc,
          state: State.experimental(),
        );

  @override
  List<String> get incompatibleRules =>
      const [LintNames.omit_local_variable_types];

  @override
  LintCode get lintCode =>
      LinterLintCode.specify_nonobvious_local_variable_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addPatternVariableDeclarationStatement(this, visitor);
    registry.addSwitchStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _PatternVisitor extends GeneralizingAstVisitor<void> {
  final LintRule rule;

  _PatternVisitor(this.rule);

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var staticType = node.type?.type;
    if (staticType != null &&
        staticType is! DynamicType &&
        !staticType.isDartCoreNull) {
      return;
    }
    rule.reportLint(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

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
      rule.reportLint(loopParts.loopVariable, ignoreSyntheticNodes: false);
    }
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    if (node.declaration.expression.hasObviousType) return;
    _PatternVisitor(rule).visitDartPattern(node.declaration.pattern);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {}

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
        rule.reportLint(node);
      } else {
        // Multiple variables, report each of them separately. No fix.
        variablesThatNeedAType.forEach(rule.reportLint);
      }
    }
  }
}
