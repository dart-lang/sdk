// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Helper for resolving [NullAssertionExpression]s.
class NullAssertionExpressionResolver {
  final TypeAnalyzer _typeAnalyzer;

  NullAssertionExpressionResolver(this._typeAnalyzer);

  TypeSystemImpl get _typeSystem => _typeAnalyzer.typeSystem;

  void resolve(
    NullAssertionExpressionImpl node, {
    required TypeImpl contextType,
  }) {
    var operand = node.operand;

    if (operand is InvalidSuperExpressionImpl) {
      _typeAnalyzer.diagnosticReporter.report(
        diag.missingAssignableSelector.at(node),
      );
    }

    _typeAnalyzer.analyzeExpression(
      operand,
      SharedTypeSchemaView(_typeSystem.makeNullable(contextType)),
      continueNullShorting: true,
    );
    operand = _typeAnalyzer.popRewrite()!;

    if (operand is InvalidSuperExpressionImpl) {
      operand.superReference.legacyStaticType = DynamicTypeImpl.instance;
    }

    var operandType = operand.typeOrThrow;
    var type = _typeSystem.promoteToNonNull(operandType);
    node.recordStaticType(type, typeAnalyzer: _typeAnalyzer);

    _typeAnalyzer.flowAnalysis.flow?.nonNullAssert_end(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(operand),
      offset: node.operator.offset,
    );
  }
}
