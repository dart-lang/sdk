// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't explicitly catch `Error` or types that implement it.";

class AvoidCatchingErrors extends MultiAnalysisRule {
  AvoidCatchingErrors()
    : super(name: LintNames.avoid_catching_errors, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.avoid_catching_errors_class,
    LinterLintCode.avoid_catching_errors_subclass,
  ];

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    var exceptionType = node.exceptionType?.type;
    if (exceptionType.implementsInterface('Error', 'dart.core')) {
      if (exceptionType.isSameAs('Error', 'dart.core')) {
        rule.reportAtNode(
          node,
          diagnosticCode: LinterLintCode.avoid_catching_errors_class,
        );
      } else {
        rule.reportAtNode(
          node,
          diagnosticCode: LinterLintCode.avoid_catching_errors_subclass,
          arguments: [exceptionType!.getDisplayString()],
        );
      }
    }
  }
}
