// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/unused_futures.dart';

const _desc =
    r'`Future` results in `async` function bodies must be '
    '`await`ed or marked `unawaited` using `dart:async`.';

class UnawaitedFutures extends MultiAnalysisRule {
  new() : super(name: LintNames.unawaited_futures, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.unawaitedFutures,
    diag.unawaitedFutureOr,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = UnusedFuturesVisitor(
      reportAt: (node, type) =>
          reportAtNode(node, diagnosticCode: _diagnosticFromType(type)),
      typeProvider: context.typeProvider,
      isInteresting: (node) =>
          // This rule is only concerned with code in async functions.
          node.thisOrAncestorOfType<FunctionBody>()?.isAsynchronous ?? false,
    );
    registry.addExpressionStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
    registry.addInterpolationExpression(this, visitor);
  }

  DiagnosticCode _diagnosticFromType(DartType type) =>
      type.isDartAsyncFutureOr ? diag.unawaitedFutureOr : diag.unawaitedFutures;
}
