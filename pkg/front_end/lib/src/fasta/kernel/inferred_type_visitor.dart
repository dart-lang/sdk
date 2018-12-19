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
    return node.staticType;
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

  @override
  DartType visitFunctionExpression(
      FunctionExpression node, TypeInferrerImpl inferrer) {
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitLogicalExpression(
      LogicalExpression node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.boolClass.rawType;
  }

  @override
  DartType visitNot(Not node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.boolClass.rawType;
  }

  @override
  DartType visitNullLiteral(NullLiteral node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.nullClass.rawType;
  }

  @override
  DartType visitPropertyGet(PropertyGet node, TypeInferrerImpl inferrer) {
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitRethrow(Rethrow node, TypeInferrerImpl inferrer) {
    return const BottomType();
  }

  @override
  DartType visitStringConcatenation(
      StringConcatenation node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.stringClass.rawType;
  }

  @override
  DartType visitStringLiteral(StringLiteral node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.stringClass.rawType;
  }

  @override
  DartType visitLet(Let node, TypeInferrerImpl inferrer) {
    // TODO(ahe): We should be able to return the inferred type of
    // node.body. However, that type may be lost, for example, in
    // VariableAssignmentJudgment._replaceWithDesugared.
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitStaticGet(StaticGet node, TypeInferrerImpl inferrer) {
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitStaticInvocation(
      StaticInvocation node, TypeInferrerImpl inferrer) {
    return inferrer.readInferredType(node);
  }

  @override
  DartType visitThrow(Throw node, TypeInferrerImpl inferrer) {
    return const BottomType();
  }

  @override
  DartType visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, TypeInferrerImpl inferrer) {
    return inferrer.coreTypes.objectClass.rawType;
  }
}
