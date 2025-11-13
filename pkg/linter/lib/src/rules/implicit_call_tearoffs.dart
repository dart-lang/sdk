// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    r'Explicitly tear-off `call` methods when using an object as a Function.';

class ImplicitCallTearoffs extends AnalysisRule {
  ImplicitCallTearoffs()
    : super(name: LintNames.implicit_call_tearoffs, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.implicitCallTearoffs;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addImplicitCallReference(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    rule.reportAtNode(node);
  }
}
