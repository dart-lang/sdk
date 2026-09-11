// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
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
    'There should be no `Future`-returning calls in synchronous functions unless they '
    'are assigned or returned.';

class DiscardedFutures extends MultiAnalysisRule {
  new() : super(name: LintNames.discarded_futures, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.discardedFutures,
    diag.discardedFutureOr,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var typeProvider = context.typeProvider;
    var visitor = UnusedFuturesVisitor(
      reportAt: (node, type) =>
          reportAtNode(node, diagnosticCode: _diagnosticFromType(type)),
      typeProvider: typeProvider,
      isInteresting: (node) =>
          // This rule is only concerned with code in sync functions.
          node.thisOrAncestorOfType<FunctionBody>()?.isSynchronous ?? false,
    );
    registry.addExpressionStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
    registry.addInterpolationExpression(this, visitor);
  }

  DiagnosticCode _diagnosticFromType(DartType type) =>
      type.isDartAsyncFutureOr ? diag.discardedFutureOr : diag.discardedFutures;
}
