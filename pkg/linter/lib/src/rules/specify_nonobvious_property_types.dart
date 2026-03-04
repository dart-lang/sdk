// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/obvious_types.dart';

const _desc =
    r'Specify non-obvious type annotations for top-level and static variables.';

class SpecifyNonObviousPropertyTypes extends AnalysisRule {
  SpecifyNonObviousPropertyTypes()
    : super(
        name: LintNames.specify_nonobvious_property_types,
        description: _desc,
        state: RuleState.stable(since: Version(3, 11, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.specifyNonobviousPropertyTypes;

  @override
  List<String> get incompatibleRules => const [];

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
      _visitVariableDeclarationList(
        node.fields,
        isInstanceVariable: !node.isStatic,
      );

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      _visitVariableDeclarationList(node.variables, isInstanceVariable: false);

  void _visitVariableDeclarationList(
    VariableDeclarationList node, {
    required bool isInstanceVariable,
  }) {
    var staticType = node.type?.type;
    if (staticType != null && !staticType.isDartCoreNull) {
      return;
    }
    bool aDeclaredTypeIsNeeded = false;
    var variablesThatNeedAType = <VariableDeclaration>[];
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (isInstanceVariable) {
        // Ignore this variable if the type comes from override inference.
        bool ignoreThisVariable = false;
        AstNode? owningDeclaration = node;
        while (owningDeclaration != null) {
          InterfaceElement? owningElement = switch (owningDeclaration) {
            ClassDeclaration(:var declaredFragment?) =>
              declaredFragment.element,
            MixinDeclaration(:var declaredFragment?) =>
              declaredFragment.element,
            EnumDeclaration(:var declaredFragment?) => declaredFragment.element,
            ExtensionTypeDeclaration(:var declaredFragment?) =>
              declaredFragment.element,
            _ => null,
          };
          if (owningElement != null) {
            var variableName = child.name.lexeme;
            for (var superInterface in owningElement.allSupertypes) {
              if (superInterface.getGetter(variableName) != null) {
                ignoreThisVariable = true;
              }
              if (superInterface.getSetter(variableName) != null) {
                ignoreThisVariable = true;
              }
            }
          }
          owningDeclaration = owningDeclaration.parent;
        }
        if (ignoreThisVariable) continue;
      }
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
