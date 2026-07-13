// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/async_return_visitor.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Return with no await.';

class AsyncReturnWithNoAwait extends AnalysisRule {
  new()
    : super(
        name: LintNames.async_return_with_no_await,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.asyncReturnWithNoAwait;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _AsyncReturnVisitorAdapter(
      AsyncReturnVisitor(
        reportAtToken: reportAtToken,
        typeProvider: context.typeProvider,
        typeSystem: context.typeSystem,
      ),
    );
    registry.addReturnStatement(this, visitor);
    registry.addExpressionFunctionBody(this, visitor);
  }
}

class _AsyncReturnVisitorAdapter extends SimpleAstVisitor<void> {
  final AsyncReturnVisitor delegate;

  new(this.delegate);

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    // ignore: experimental_member_use
    node.accept2(delegate);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    // ignore: experimental_member_use
    node.accept2(delegate);
  }
}
