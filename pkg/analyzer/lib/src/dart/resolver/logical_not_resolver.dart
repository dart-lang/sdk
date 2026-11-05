// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [LogicalNot]s.
class LogicalNotResolver {
  final ResolverVisitor _resolver;

  LogicalNotResolver(this._resolver);

  void resolve(LogicalNotImpl node) {
    var operand = node.operand;

    _resolver.analyzeExpression(
      operand,
      SharedTypeSchemaView(_resolver.typeProvider.boolType),
    );
    operand = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(operand),
    );

    _resolver.boolExpressionVerifier.checkForNonBoolNegationExpression(
      operand,
      whyNotPromoted: whyNotPromoted,
    );

    node.recordStaticType(_resolver.typeProvider.boolType, resolver: _resolver);

    if (_resolver.flowAnalysis.flow case var flow?) {
      _resolver.flowAnalysis.storeExpressionInfo(
        node,
        flow.logicalNot_end(_resolver.flowAnalysis.getExpressionInfo(operand)),
      );
    }
  }
}
