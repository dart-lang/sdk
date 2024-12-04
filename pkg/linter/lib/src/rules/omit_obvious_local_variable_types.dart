// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/obvious_types.dart';

const _desc = r'Omit obvious type annotations for local variables.';

class OmitObviousLocalVariableTypes extends LintRule {
  OmitObviousLocalVariableTypes()
      : super(
          name: LintNames.omit_obvious_local_variable_types,
          description: _desc,
          state: State.experimental(),
        );

  @override
  List<String> get incompatibleRules => const [LintNames.always_specify_types];

  @override
  LintCode get lintCode => LinterLintCode.omit_obvious_local_variable_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
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
      if (staticType == null || staticType is DynamicType) {
        return;
      }
      var iterable = loopParts.iterable;
      if (!iterable.hasObviousType) {
        return;
      }
      var iterableType = iterable.staticType;
      if (iterableType.elementTypeOfIterable == staticType) {
        rule.reportLint(loopVariableType);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType == null || staticType.isDartCoreNull) {
      return;
    }
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer != null && !initializer.hasObviousType) {
        return;
      }
      if (initializer?.staticType != staticType) {
        return;
      }
    }
    rule.reportLint(node.type);
  }
}
