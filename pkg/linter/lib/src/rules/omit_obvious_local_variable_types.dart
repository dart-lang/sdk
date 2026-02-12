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

const _desc = r'Omit obvious type annotations for local variables.';

class OmitObviousLocalVariableTypes extends AnalysisRule {
  OmitObviousLocalVariableTypes()
    : super(
        name: LintNames.omit_obvious_local_variable_types,
        description: _desc,
        state: RuleState.stable(since: Version(3, 11, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.omitObviousLocalVariableTypes;

  @override
  List<String> get incompatibleRules => const [LintNames.always_specify_types];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
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
      if (staticType == null || staticType is DynamicType) {
        return;
      }
      var iterable = loopParts.iterable;
      if (!iterable.hasObviousType) {
        return;
      }
      var iterableType = iterable.staticType;
      if (iterableType.elementTypeOfIterable == staticType) {
        rule.reportAtNode(loopVariableType);
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
    rule.reportAtNode(node.type);
  }
}
