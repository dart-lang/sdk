// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Put required named parameters first.';

class AlwaysPutRequiredNamedParametersFirst extends LintRule {
  AlwaysPutRequiredNamedParametersFirst()
    : super(
        name: LintNames.always_put_required_named_parameters_first,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.alwaysPutRequiredNamedParametersFirst;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFormalParameterList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    var nonRequiredSeen = false;
    for (var param in node.parameters.where((p) => p.isNamed)) {
      var element = param.declaredFragment?.element;
      if (element != null &&
          (element.metadata.hasRequired || element.isRequiredNamed)) {
        if (nonRequiredSeen) {
          var name = param.name;
          if (name != null) {
            rule.reportAtToken(name);
          }
        }
      } else {
        nonRequiredSeen = true;
      }
    }
  }
}
