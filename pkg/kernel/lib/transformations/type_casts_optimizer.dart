// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, SubtypeCheckMode, TypeEnvironment;

// Removes redundant type casts and reduces casts to null checks.
//
// Handles the following patterns:
// If S <: T (this includes S <: T? in weak mode)
//
//    S x; x as T => x
//
// If S <: T? in strong mode
//
//    S x; x as T => (x == null) ? x as T : x
//
TreeNode transformAsExpression(
    AsExpression node, StaticTypeContext staticTypeContext, bool nullSafety) {
  final DartType operandType = node.operand.getStaticType(staticTypeContext);
  final env = staticTypeContext.typeEnvironment;

  if (isRedundantTypeCast(node, operandType, env, nullSafety)) {
    return node.operand;
  }

  if (canBeReducedToNullCheckAndCast(node, operandType, env, nullSafety)) {
    // Transform 'x as T' to 'Let tmp = x in (tmp == null) ? tmp as T : tmp'.
    final tmp =
        VariableDeclaration(null, initializer: node.operand, type: operandType);
    final dstType = node.type;
    return Let(
        tmp,
        ConditionalExpression(
            MethodInvocation(
                VariableGet(tmp), Name('=='), Arguments([NullLiteral()])),
            AsExpression(VariableGet(tmp), dstType)
              ..flags = node.flags
              ..fileOffset = node.fileOffset,
            VariableGet(tmp, dstType),
            dstType));
  }

  return node;
}

// Returns true if type cast [node] which has operand of the given
// [operandStaticType] is redundant and can be removed (replaced with its
// operand).
bool isRedundantTypeCast(AsExpression node, DartType operandStaticType,
    TypeEnvironment env, bool nullSafety) {
  if (!_canBeTransformed(node)) {
    return false;
  }

  return env.isSubtypeOf(
      operandStaticType,
      node.type,
      nullSafety
          ? SubtypeCheckMode.withNullabilities
          : SubtypeCheckMode.ignoringNullabilities);
}

// Returns true if type cast [node] which has operand of the given
// [operandStaticType] can be reduced to the null-check-and-cast pattern
// 'Let tmp = [node.operand] in (tmp == null) ? tmp as T : tmp'.
bool canBeReducedToNullCheckAndCast(AsExpression node,
    DartType operandStaticType, TypeEnvironment env, bool nullSafety) {
  if (!_canBeTransformed(node)) {
    return false;
  }

  final DartType dst = node.type;

  if (nullSafety && dst.nullability != Nullability.nullable) {
    final nullableDst = dst.withDeclaredNullability(Nullability.nullable);
    return env.isSubtypeOf(
        operandStaticType, nullableDst, SubtypeCheckMode.withNullabilities);
  }

  return false;
}

bool _canBeTransformed(AsExpression node) {
  if (node.isCovarianceCheck) {
    // Keep casts inserted by the front-end to ensure soundness of
    // covariant types.
    return false;
  }

  final DartType dst = node.type;
  if (dst is DynamicType || dst is InvalidType) {
    // Keep casts to dynamic as they have zero overhead but change
    // the semantics of calls. Also keep invalid types.
    return false;
  }

  return true;
}
