// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

/// Implements the semantics of `await e`.
///
/// If an expression `e` has a static type of `S`, then `await e` must first
/// check if the runtime type of `e` is `Future<flatten(S)>`. If it is, `e` can
/// be `await`ed directly. Otherwise, we must `await Future.value(e)` (but note
/// that `_Future.value` suffices).
class AwaitLowering {
  final CoreTypes _coreTypes;

  AwaitLowering(this._coreTypes);

  AwaitExpression transformAwaitExpression(AwaitExpression node) {
    final runtimeCheckType = node.runtimeCheckType;
    if (runtimeCheckType == null) return node;
    // [runtimeCheckType] is guaranteed to be `Future<flatten(S)>`.
    final flattenType =
        (runtimeCheckType as InterfaceType).typeArguments.single;
    final operand = node.operand;
    final fileOffset = node.fileOffset;
    final helper = _coreTypes.wrapAwaitedExpression;
    final arguments = Arguments([operand], types: [flattenType])
      ..fileOffset = fileOffset;
    final wrappedOperand = StaticInvocation(helper, arguments)
      ..fileOffset = fileOffset;
    return AwaitExpression(wrappedOperand)..fileOffset = fileOffset;
  }
}
