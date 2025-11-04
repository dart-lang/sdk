// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/extensions.dart'; //ignore: implementation_imports

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r"Don't use wildcard parameters or variables.";

class NoWildcardVariableUses extends AnalysisRule {
  NoWildcardVariableUses()
    : super(name: LintNames.no_wildcard_variable_uses, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.noWildcardVariableUses;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.libraryElement.hasWildcardVariablesFeatureEnabled) return;

    var visitor = _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is! LocalVariableElement &&
        element is! FormalParameterElement) {
      return;
    }

    if (node.name.isJustUnderscores) {
      rule.reportAtNode(node);
    }
  }
}
