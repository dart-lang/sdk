// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "kernel_shadow_ast.dart";

DartType getInferredType(Expression expression, InferenceHelper helper) {
  if (expression is ExpressionJudgment) {
    return expression.inferredType;
  } else {
    return expression.accept1(const InferredTypeVisitor(), helper);
  }
}

class InferredTypeVisitor
    extends ExpressionVisitor1<DartType, InferenceHelper> {
  const InferredTypeVisitor();

  @override
  DartType defaultExpression(Expression node, InferenceHelper helper) {
    unhandled(
        "${node.runtimeType}", "getInferredType", node.fileOffset, helper.uri);
    return const InvalidType();
  }

  @override
  DartType visitIntLiteral(IntLiteral node, InferenceHelper helper) {
    return helper.coreTypes.intClass.rawType;
  }

  @override
  DartType visitDoubleLiteral(DoubleLiteral node, InferenceHelper helper) {
    return helper.coreTypes.doubleClass.rawType;
  }

  @override
  DartType visitInvalidExpression(
      InvalidExpression node, InferenceHelper helper) {
    return const BottomType();
  }
}
