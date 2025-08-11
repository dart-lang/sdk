// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/unused_futures.dart';

const _desc =
    r'`Future` results in `async` function bodies must be '
    '`await`ed or marked `unawaited` using `dart:async`.';

class UnawaitedFutures extends LintRule {
  UnawaitedFutures()
    : super(name: LintNames.unawaited_futures, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unawaited_futures;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = UnusedFuturesVisitor(
      rule: this,
      isInteresting: (node) {
        var type = node.staticType;
        // This rule is not currently concerned with `FutureOr`.
        if (type == null || !type.isOrImplementsFuture) {
          return false;
        }
        // This rule is only concerned with code in async functions.
        return node.thisOrAncestorOfType<FunctionBody>()?.isAsynchronous ??
            false;
      },
    );
    registry.addExpressionStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
    registry.addInterpolationExpression(this, visitor);
  }
}

extension on DartType {
  /// Whether this type is `Future` from dart:async, or is a subtype thereof.
  bool get isOrImplementsFuture {
    var typeElement = element;
    if (typeElement is! InterfaceElement) return false;
    return isDartAsyncFuture ||
        typeElement.allSupertypes.any((t) => t.isDartAsyncFuture);
  }
}
