// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';

/// Helper for resolving [LogicalNot]s.
class LogicalNotResolver {
  final TypeAnalyzer _typeAnalyzer;

  LogicalNotResolver(this._typeAnalyzer);

  void resolve(LogicalNotImpl node) {
    var operand = node.operand;

    _typeAnalyzer.analyzeExpression(
      operand,
      SharedTypeSchemaView(_typeAnalyzer.typeProvider.boolType),
    );
    operand = _typeAnalyzer.popRewrite()!;
    var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(operand),
    );

    _typeAnalyzer.boolExpressionVerifier.checkForNonBoolNegationExpression(
      operand,
      whyNotPromoted: whyNotPromoted,
    );

    node.recordStaticType(
      _typeAnalyzer.typeProvider.boolType,
      typeAnalyzer: _typeAnalyzer,
    );

    if (_typeAnalyzer.flowAnalysis.flow case var flow?) {
      _typeAnalyzer.flowAnalysis.storeExpressionInfo(
        node,
        flow.logicalNot_end(
          _typeAnalyzer.flowAnalysis.getExpressionInfo(operand),
        ),
      );
    }
  }
}
