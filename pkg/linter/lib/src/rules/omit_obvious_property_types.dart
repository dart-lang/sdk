// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/obvious_types.dart';

const _desc =
    r'Omit obvious type annotations for top-level and static variables.';

class OmitObviousPropertyTypes extends LintRule {
  OmitObviousPropertyTypes()
      : super(
          name: 'omit_obvious_property_types',
          description: _desc,
          state: State.experimental(),
        );

  @override
  List<String> get incompatibleRules => const ['always_specify_types'];

  @override
  LintCode get lintCode => LinterLintCode.omit_obvious_property_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

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
    rule.reportLint(node.type);
  }
}
