// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [NullAssertionExpression]s.
class NullAssertionExpressionResolver {
  final ResolverVisitor _resolver;

  NullAssertionExpressionResolver(this._resolver);

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(
    NullAssertionExpressionImpl node, {
    required TypeImpl contextType,
  }) {
    var operand = node.operand;

    if (operand is SuperExpression) {
      _resolver.diagnosticReporter.report(
        diag.missingAssignableSelector.at(node),
      );
      operand.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      node.recordStaticType(DynamicTypeImpl.instance, resolver: _resolver);
      return;
    }

    _resolver.analyzeExpression(
      operand,
      SharedTypeSchemaView(_typeSystem.makeNullable(contextType)),
      continueNullShorting: true,
    );
    operand = _resolver.popRewrite()!;

    var operandType = operand.typeOrThrow;
    var type = _typeSystem.promoteToNonNull(operandType);
    node.recordStaticType(type, resolver: _resolver);

    _resolver.flowAnalysis.flow?.nonNullAssert_end(
      _resolver.flowAnalysis.getExpressionInfo(operand),
    );
  }
}
