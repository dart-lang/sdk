// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';

import '../diagnostic.dart' as diag;
import '../util/obvious_types.dart';

const _desc =
    r'Omit obvious type annotations for top-level and static variables.';

class OmitObviousPropertyTypes extends AnalysisRule {
  OmitObviousPropertyTypes()
    : super(
        name: 'omit_obvious_property_types',
        description: _desc,
        state: RuleState.stable(since: Version(3, 11, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.omitObviousPropertyTypes;

  @override
  List<String> get incompatibleRules => const [
    'always_specify_types',
    'type_annotate_public_apis',
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) =>
      _visitVariableDeclarationList(node.fields);

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      _visitVariableDeclarationList(node.variables);

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
