// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "kernel_shadow_ast.dart";

DartType getInferredType(Expression expression, TypeInferrer inferrer) {
  if (expression is ExpressionJudgment) {
    return expression.inferredType;
  } else {
    return expression.accept1(const InferredTypeVisitor(), inferrer);
  }
}

class InferredTypeVisitor extends ExpressionVisitor1<DartType, TypeInferrer> {
  const InferredTypeVisitor();

  @override
  DartType defaultExpression(Expression node, TypeInferrer inferrer) {
    unhandled("${node.runtimeType}", "getInferredType", node.fileOffset,
        inferrer.uri);
    return const InvalidType();
  }

  @override
  DartType visitIntLiteral(IntLiteral node, TypeInferrer inferrer) {
    return inferrer.coreTypes.intClass.rawType;
  }

  @override
  DartType visitDoubleLiteral(DoubleLiteral node, TypeInferrer inferrer) {
    return inferrer.coreTypes.doubleClass.rawType;
  }

  @override
  DartType visitInvalidExpression(
      InvalidExpression node, TypeInferrer inferrer) {
    return const BottomType();
  }

  @override
  DartType visitAsExpression(AsExpression node, TypeInferrer inferrer) {
    return node.type;
  }

  @override
  DartType visitAwaitExpression(AwaitExpression node, TypeInferrer inferrer) {
    return inferrer.readInferredType(node);
  }
}
