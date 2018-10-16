// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "kernel_shadow_ast.dart";

DartType getInferredType(Expression expression, TypeInferrerImpl inferrer) {
  if (expression is ExpressionJudgment) {
    return expression.inferredType;
  } else {
    return expression.accept1(const InferredTypeVisitor(), inferrer);
  }
}

DartType invalidToBottom(DartType type) {
  // TODO(ahe): This should really return [BottomType], but that requires more
  // work to the Kernel type system and implementation.
  return (type == null || type is InvalidType) ? const DynamicType() : type;
}

DartType invalidToTop(DartType type) {
  return (type == null || type is InvalidType) ? const DynamicType() : type;
}

class InferredTypeVisitor
    extends ExpressionVisitor1<DartType, TypeInferrerImpl> {
  const InferredTypeVisitor();

  @override
  DartType defaultExpression(Expression node, TypeInferrerImpl inferrer) {
    unhandled("${node.runtimeType}", "getInferredType", node.fileOffset,
        inferrer.uri);
    return const InvalidType();
  }

  @override
  DartType visitIntLiteral(IntLiteral node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.intClass.rawType;
  }

  @override
  DartType visitDoubleLiteral(DoubleLiteral node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.doubleClass.rawType;
  }

  @override
  DartType visitInvalidExpression(
      InvalidExpression node, TypeInferrerImpl inferrer) {
    return const BottomType();
  }

  @override
  DartType visitAsExpression(AsExpression node, TypeInferrerImpl inferrer) {
    return invalidToBottom(node.type);
  }

  @override
  DartType visitAwaitExpression(
      AwaitExpression node, TypeInferrerImpl inferrer) {
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitThisExpression(ThisExpression node, TypeInferrerImpl inferrer) {
    return invalidToBottom(inferrer.thisType);
  }

  @override
  DartType visitBoolLiteral(BoolLiteral node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.boolClass.rawType;
  }

  @override
  DartType visitConditionalExpression(
      ConditionalExpression node, TypeInferrerImpl inferrer) {
    return inferrer.strongMode ? node.staticType : const DynamicType();
  }

  @override
  DartType visitConstructorInvocation(
      ConstructorInvocation node, TypeInferrerImpl inferrer) {
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitIsExpression(IsExpression node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.boolClass.rawType;
  }
}
