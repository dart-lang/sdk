// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:kernel/ast.dart';

/// Type inference listener that records inferred types and file offsets for
/// later use by [ValidatingResolutionApplier].
class InstrumentedResolutionStorer extends ResolutionStorer {
  final List<int> _typeOffsets;

  InstrumentedResolutionStorer(List<DartType> types, this._typeOffsets)
      : super(types);

  @override
  void genericExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {
    assert(_types.length == _typeOffsets.length);
    this._typeOffsets.add(expression.fileOffset);
    super.genericExpressionExit(expressionType, expression, inferredType);
  }
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer extends TypeInferenceListener {
  final List<DartType> _types;

  ResolutionStorer(this._types);

  @override
  bool genericExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {
    super.genericExpressionEnter(expressionType, expression, typeContext);
    return true;
  }

  @override
  void genericExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {
    _types.add(inferredType);
    super.genericExpressionExit(expressionType, expression, inferredType);
  }
}
