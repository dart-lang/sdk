// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/unused_futures.dart';

const _desc =
    'There should be no `Future`-returning calls in synchronous functions unless they '
    'are assigned or returned.';

class DiscardedFutures extends AnalysisRule {
  DiscardedFutures()
    : super(name: LintNames.discarded_futures, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.discardedFutures;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = UnusedFuturesVisitor(
      rule: this,
      isInteresting: (node) {
        var type = node.staticType;
        // This rule does concern itself with `FutureOr`.
        if (type == null || !type.isOrImplementsFutureOrFutureOr) {
          return false;
        }
        // This rule is only concerned with code in sync functions.
        return node.thisOrAncestorOfType<FunctionBody>()?.isSynchronous ??
            false;
      },
    );
    registry.addExpressionStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
    registry.addInterpolationExpression(this, visitor);
  }
}
