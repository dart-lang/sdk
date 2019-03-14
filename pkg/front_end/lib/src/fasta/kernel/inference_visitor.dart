// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "kernel_shadow_ast.dart";

class InferenceVisitor extends BodyVisitor1<void, DartType> {
  final ShadowTypeInferrer inferrer;

  InferenceVisitor(this.inferrer);

  @override
  void defaultExpression(Expression node, DartType typeContext) {
    if (node is IfElement) {
      visitIfElement(node, typeContext);
      return;
    }
    unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        inferrer.helper.uri);
  }

  @override
  void defaultStatement(Statement node, _) {
    unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        inferrer.helper.uri);
  }

  visitIfElement(IfElement node, DartType typeContext) {
    node.parent.replaceChild(node,
        new InvalidExpression('unhandled if element in collection literal'));
  }

  @override
  void visitInvalidExpression(InvalidExpression node, DartType typeContext) {}

  @override
  void visitIntLiteral(IntLiteral node, DartType typeContext) {}

  @override
  void visitDoubleLiteral(DoubleLiteral node, DartType typeContext) {}

  @override
  void visitAsExpression(AsExpression node, DartType typeContext) {
    inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
  }

  void visitAssertInitializerJudgment(AssertInitializerJudgment node) {
    inferrer.inferStatement(node.judgment);
  }

  void visitAssertStatementJudgment(AssertStatementJudgment node) {
    var conditionJudgment = node.conditionJudgment;
    var messageJudgment = node.messageJudgment;
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(
        conditionJudgment, expectedType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(
        expectedType,
        getInferredType(conditionJudgment, inferrer),
        conditionJudgment,
        conditionJudgment.fileOffset);
    if (messageJudgment != null) {
      inferrer.inferExpression(
          messageJudgment, const UnknownType(), !inferrer.isTopLevel);
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node, DartType typeContext) {
    if (!inferrer.typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = inferrer.wrapFutureOrType(typeContext);
    }
    var operand = node.operand;
    inferrer.inferExpression(operand, typeContext, true, isVoidAllowed: true);
    inferrer.storeInferredType(
        node,
        inferrer.typeSchemaEnvironment
            .unfutureType(getInferredType(operand, inferrer)));
  }

  void visitBlockJudgment(BlockJudgment node) {
    for (var judgment in node.judgments) {
      inferrer.inferStatement(judgment);
    }
  }

  @override
  void visitBoolLiteral(BoolLiteral node, DartType typeContext) {}

  @override
  void visitBreakStatement(BreakStatement node, _) {
    // No inference needs to be done.
  }

  void visitCascadeJudgment(CascadeJudgment node, DartType typeContext) {
    node.inferredType =
        inferrer.inferExpression(node.targetJudgment, typeContext, true);
    node.variable.type = getInferredType(node, inferrer);
    for (var judgment in node.cascadeJudgments) {
      inferrer.inferExpression(
          judgment, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
    }
    return null;
  }

  @override
  void visitConditionalExpression(
      ConditionalExpression node, DartType typeContext) {
    var condition = node.condition;
    var then = node.then;
    var otherwise = node.otherwise;
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(condition, expectedType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(
        expectedType,
        getInferredType(condition, inferrer),
        node.condition,
        node.condition.fileOffset);
    inferrer.inferExpression(then, typeContext, true, isVoidAllowed: true);
    inferrer.inferExpression(otherwise, typeContext, true, isVoidAllowed: true);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(getInferredType(then, inferrer),
            getInferredType(otherwise, inferrer));
    node.staticType = inferredType;
  }

  @override
  void visitConstructorInvocation(
      ConstructorInvocation node, DartType typeContext) {
    var library = inferrer.engine.beingInferred[node.target];
    if (library != null) {
      // There is a cyclic dependency where inferring the types of the
      // initializing formals of a constructor required us to infer the
      // corresponding field type which required us to know the type of the
      // constructor.
      String name = node.target.enclosingClass.name;
      if (node.target.name.name.isNotEmpty) {
        // TODO(ahe): Use `inferrer.helper.constructorNameForDiagnostics`
        // instead. However, `inferrer.helper` may be null.
        name += ".${node.target.name.name}";
      }
      library.addProblem(
          templateCantInferTypeDueToCircularity.withArguments(name),
          node.target.fileOffset,
          name.length,
          node.target.fileUri);
      for (var declaration in node.target.function.positionalParameters) {
        declaration.type ??= const DynamicType();
      }
      for (var declaration in node.target.function.namedParameters) {
        declaration.type ??= const DynamicType();
      }
    } else if ((library = inferrer.engine.toBeInferred[node.target]) != null) {
      inferrer.engine.toBeInferred.remove(node.target);
      inferrer.engine.beingInferred[node.target] = library;
      for (var declaration in node.target.function.positionalParameters) {
        inferrer.engine.inferInitializingFormal(declaration, node.target);
      }
      for (var declaration in node.target.function.namedParameters) {
        inferrer.engine.inferInitializingFormal(declaration, node.target);
      }
      inferrer.engine.beingInferred.remove(node.target);
    }
    bool hasExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    var inferenceResult = inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        node.target.function.functionType,
        computeConstructorReturnType(node.target),
        node.arguments,
        isConst: node.isConst);
    inferrer.storeInferredType(node, inferenceResult.type);
    if (!inferrer.isTopLevel) {
      KernelLibraryBuilder library = inferrer.library;
      if (!hasExplicitTypeArguments) {
        library.checkBoundsInConstructorInvocation(
            node, inferrer.typeSchemaEnvironment,
            inferred: true);
      }
    }
  }

  void visitContinueSwitchJudgment(ContinueSwitchJudgment node) {
    // No inference needs to be done.
  }
  void visitDeferredCheckJudgment(
      DeferredCheckJudgment node, DartType typeContext) {
    // Since the variable is not used in the body we don't need to type infer
    // it.  We can just type infer the body.
    var judgment = node.judgment;
    inferrer.inferExpression(judgment, typeContext, true, isVoidAllowed: true);
    node.inferredType = getInferredType(judgment, inferrer);
    return null;
  }

  void visitDoJudgment(DoJudgment node) {
    var conditionJudgment = node.conditionJudgment;
    inferrer.inferStatement(node.body);
    var boolType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(conditionJudgment, boolType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(
        boolType,
        getInferredType(conditionJudgment, inferrer),
        node.condition,
        node.condition.fileOffset);
  }

  void visitDoubleJudgment(DoubleJudgment node, DartType typeContext) {
    node.inferredType = inferrer.coreTypes.doubleClass.rawType;
    return null;
  }

  void visitEmptyStatementJudgment(EmptyStatementJudgment node) {
    // No inference needs to be done.
  }
  void visitExpressionStatementJudgment(ExpressionStatementJudgment node) {
    inferrer.inferExpression(
        node.judgment, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
  }

  void visitFactoryConstructorInvocationJudgment(
      FactoryConstructorInvocationJudgment node, DartType typeContext) {
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    var inferenceResult = inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        node.target.function.functionType,
        computeConstructorReturnType(node.target),
        node.argumentJudgments,
        isConst: node.isConst);
    node.inferredType = inferenceResult.type;
    if (!inferrer.isTopLevel) {
      KernelLibraryBuilder library = inferrer.library;
      if (!hadExplicitTypeArguments) {
        library.checkBoundsInFactoryInvocation(
            node, inferrer.typeSchemaEnvironment,
            inferred: true);
      }
    }
    return null;
  }

  void visitShadowFieldInitializer(ShadowFieldInitializer node) {
    var initializerType =
        inferrer.inferExpression(node.value, node.field.type, true);
    inferrer.ensureAssignable(
        node.field.type, initializerType, node.value, node.fileOffset);
  }

  void handleForInStatementDeclaringVariable(ForInStatement node) {
    DartType elementType;
    bool typeNeeded = false;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    final VariableDeclaration variable = node.variable;
    if (VariableDeclarationJudgment.isImplicitlyTyped(variable)) {
      typeNeeded = true;
      elementType = const UnknownType();
    } else {
      elementType = variable.type;
    }

    DartType inferredType =
        inferForInIterable(node, elementType, typeNeeded || typeChecksNeeded);
    if (typeNeeded) {
      inferrer.instrumentation?.record(inferrer.uri, variable.fileOffset,
          'type', new InstrumentationValueForType(inferredType));
      variable.type = inferredType;
    }

    inferrer.inferStatement(node.body);

    VariableDeclaration tempVar =
        new VariableDeclaration(null, type: inferredType, isFinal: true);
    VariableGet variableGet = new VariableGet(tempVar)
      ..fileOffset = variable.fileOffset;
    Expression implicitDowncast = inferrer.ensureAssignable(
        variable.type, inferredType, variableGet, node.fileOffset,
        template: templateForInLoopElementTypeNotAssignable);
    if (implicitDowncast != null) {
      node.variable = tempVar..parent = node;
      variable.initializer = implicitDowncast..parent = variable;
      node.body = combineStatements(variable, node.body)..parent = node;
    }
  }

  DartType inferForInIterable(
      ForInStatement node, DartType elementType, bool typeNeeded) {
    Class iterableClass = node.isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context = inferrer.wrapType(elementType, iterableClass);
    Expression iterable = node.iterable;
    inferrer.inferExpression(iterable, context, typeNeeded);
    DartType inferredExpressionType =
        inferrer.resolveTypeParameter(getInferredType(iterable, inferrer));
    inferrer.ensureAssignable(
        inferrer.wrapType(const DynamicType(), iterableClass),
        inferredExpressionType,
        node.iterable,
        node.iterable.fileOffset,
        template: templateForInLoopTypeNotIterable);
    DartType inferredType;
    if (typeNeeded) {
      inferredType = const DynamicType();
      if (inferredExpressionType is InterfaceType) {
        InterfaceType supertype = inferrer.classHierarchy
            .getTypeAsInstanceOf(inferredExpressionType, iterableClass);
        if (supertype != null) {
          inferredType = supertype.typeArguments[0];
        }
      }
    }
    return inferredType;
  }

  void handleForInStatementWithoutVariable(ForInStatement node) {
    DartType elementType;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    DartType syntheticWriteType;
    Expression syntheticAssignment;
    Block block = node.body;
    ExpressionStatement statement = block.statements[0];
    SyntheticExpressionJudgment judgment = statement.expression;
    Expression rhs;
    syntheticAssignment = judgment.desugared;
    if (syntheticAssignment is VariableSet) {
      syntheticWriteType = elementType = syntheticAssignment.variable.type;
      rhs = syntheticAssignment.value;
    } else if (syntheticAssignment is PropertySet ||
        syntheticAssignment is SuperPropertySet) {
      DartType receiverType = inferrer.thisType;
      Object writeMember =
          inferrer.findPropertySetMember(receiverType, syntheticAssignment);
      syntheticWriteType =
          elementType = inferrer.getSetterType(writeMember, receiverType);
      if (syntheticAssignment is PropertySet) {
        rhs = syntheticAssignment.value;
      } else if (syntheticAssignment is SuperPropertySet) {
        rhs = syntheticAssignment.value;
      }
    } else if (syntheticAssignment is StaticSet) {
      syntheticWriteType = elementType = syntheticAssignment.target.setterType;
      rhs = syntheticAssignment.value;
    } else if (syntheticAssignment is InvalidExpression) {
      elementType = const UnknownType();
    } else {
      unhandled(
          "${syntheticAssignment.runtimeType}",
          "handleForInStatementWithoutVariable",
          syntheticAssignment.fileOffset,
          inferrer.helper.uri);
    }

    DartType inferredType =
        inferForInIterable(node, elementType, typeChecksNeeded);
    if (typeChecksNeeded) {
      node.variable.type = inferredType;
    }

    inferrer.inferStatement(node.body);

    if (syntheticWriteType != null) {
      inferrer.ensureAssignable(
          greatestClosure(inferrer.coreTypes, syntheticWriteType),
          node.variable.type,
          rhs,
          rhs.fileOffset,
          template: templateForInLoopElementTypeNotAssignable,
          isVoidAllowed: true);
    }
  }

  @override
  void visitForInStatement(ForInStatement node, _) {
    if (node.variable.name == null) {
      handleForInStatementWithoutVariable(node);
    } else {
      handleForInStatementDeclaringVariable(node);
    }
  }

  void visitForJudgment(ForJudgment node) {
    var conditionJudgment = node.conditionJudgment;
    for (VariableDeclaration variable in node.variables) {
      if (variable.name == null) {
        Expression initializer = variable.initializer;
        if (initializer != null) {
          variable.type = inferrer.inferExpression(
              initializer, const UnknownType(), true,
              isVoidAllowed: true);
        }
      } else {
        inferrer.inferStatement(variable);
      }
    }
    if (conditionJudgment != null) {
      var expectedType = inferrer.coreTypes.boolClass.rawType;
      inferrer.inferExpression(
          conditionJudgment, expectedType, !inferrer.isTopLevel);
      inferrer.ensureAssignable(
          expectedType,
          getInferredType(conditionJudgment, inferrer),
          node.condition,
          node.condition.fileOffset);
    }
    for (var update in node.updateJudgments) {
      inferrer.inferExpression(
          update, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
    }
    inferrer.inferStatement(node.body);
  }

  ExpressionInferenceResult visitFunctionNodeJudgment(
      FunctionNodeJudgment node,
      DartType typeContext,
      DartType returnContext,
      int returnTypeInstrumentationOffset) {
    return inferrer.inferLocalFunction(
        node, typeContext, returnTypeInstrumentationOffset, returnContext);
  }

  void visitFunctionDeclarationJudgment(FunctionDeclarationJudgment node) {
    inferrer.inferMetadataKeepingHelper(node.variable.annotations);
    DartType returnContext =
        node._hasImplicitReturnType ? null : node.function.returnType;
    var inferenceResult = visitFunctionNodeJudgment(
        node.functionJudgment, null, returnContext, node.fileOffset);
    node.variable.type = inferenceResult.type;
  }

  @override
  void visitFunctionExpression(FunctionExpression node, DartType typeContext) {
    var inferenceResult = visitFunctionNodeJudgment(
        node.function, typeContext, null, node.fileOffset);
    inferrer.storeInferredType(node, inferenceResult.type);
  }

  void visitInvalidSuperInitializerJudgment(
      InvalidSuperInitializerJudgment node) {
    var substitution = Substitution.fromSupertype(inferrer.classHierarchy
        .getClassAsInstanceOf(
            inferrer.thisType.classNode, node.target.enclosingClass));
    inferrer.inferInvocation(
        null,
        node.fileOffset,
        substitution.substituteType(
            node.target.function.functionType.withoutTypeParameters),
        inferrer.thisType,
        node.argumentsJudgment,
        skipTypeArgumentInference: true);
  }

  void visitIfNullJudgment(IfNullJudgment node, DartType typeContext) {
    var leftJudgment = node.leftJudgment;
    var rightJudgment = node.rightJudgment;
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    inferrer.inferExpression(leftJudgment, typeContext, true);
    var lhsType = getInferredType(leftJudgment, inferrer);
    node.variable.type = lhsType;
    // - Let J = T0 if K is `?` else K.
    // - Infer e1 in context J to get T1
    if (typeContext is UnknownType) {
      inferrer.inferExpression(rightJudgment, lhsType, true,
          isVoidAllowed: true);
    } else {
      inferrer.inferExpression(rightJudgment, typeContext, true,
          isVoidAllowed: true);
    }
    var rhsType = getInferredType(rightJudgment, inferrer);
    // - Let T = greatest closure of K with respect to `?` if K is not `_`, else
    //   UP(t0, t1)
    // - Then the inferred type is T.
    node.inferredType =
        inferrer.typeSchemaEnvironment.getStandardUpperBound(lhsType, rhsType);
    node.body.staticType = getInferredType(node, inferrer);
    return null;
  }

  void visitIfJudgment(IfJudgment node) {
    var conditionJudgment = node.conditionJudgment;
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(
        conditionJudgment, expectedType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(
        expectedType,
        getInferredType(conditionJudgment, inferrer),
        node.condition,
        node.condition.fileOffset);
    inferrer.inferStatement(node.then);
    if (node.otherwise != null) {
      inferrer.inferStatement(node.otherwise);
    }
  }

  void visitIllegalAssignmentJudgment(
      IllegalAssignmentJudgment node, DartType typeContext) {
    if (node.write != null) {
      inferrer.inferExpression(
          node.write, const UnknownType(), !inferrer.isTopLevel);
    }
    inferrer.inferExpression(
        node.rhs, const UnknownType(), !inferrer.isTopLevel);
    node._replaceWithDesugared();
    node.inferredType = const DynamicType();
    return null;
  }

  void visitIndexAssignmentJudgment(
      IndexAssignmentJudgment node, DartType typeContext) {
    var receiverType = node._inferReceiver(inferrer);
    var writeMember =
        inferrer.findMethodInvocationMember(receiverType, node.write);
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member
    // when doing compound assignment?
    var calleeType = inferrer.getCalleeFunctionType(
        inferrer.getCalleeType(writeMember, receiverType), false);
    DartType expectedIndexTypeForWrite;
    DartType indexContext = const UnknownType();
    DartType writeContext = const UnknownType();
    if (calleeType.positionalParameters.length >= 2) {
      // TODO(paulberry): we ought to get a context for the index expression
      // from the index formal parameter, but analyzer doesn't so for now we
      // replicate its behavior.
      expectedIndexTypeForWrite = calleeType.positionalParameters[0];
      writeContext = calleeType.positionalParameters[1];
    }
    inferrer.inferExpression(node.index, indexContext, true);
    var indexType = getInferredType(node.index, inferrer);
    node._storeLetType(inferrer, node.index, indexType);
    if (writeContext is! UnknownType) {
      inferrer.ensureAssignable(
          expectedIndexTypeForWrite,
          indexType,
          node._getInvocationArguments(inferrer, node.write).positional[0],
          node.write.fileOffset);
    }
    InvocationExpression read = node.read;
    DartType readType;
    if (read != null) {
      var readMember = inferrer.findMethodInvocationMember(receiverType, read,
          instrumented: false);
      var calleeFunctionType = inferrer.getCalleeFunctionType(
          inferrer.getCalleeType(readMember, receiverType), false);
      inferrer.ensureAssignable(
          getPositionalParameterType(calleeFunctionType, 0),
          indexType,
          node._getInvocationArguments(inferrer, read).positional[0],
          read.fileOffset);
      readType = calleeFunctionType.returnType;
      var desugaredInvocation = read is MethodInvocation ? read : null;
      var checkKind = inferrer.preCheckInvocationContravariance(node.receiver,
          receiverType, readMember, desugaredInvocation, read.arguments, read);
      var replacedRead = inferrer.handleInvocationContravariance(
          checkKind,
          desugaredInvocation,
          read.arguments,
          read,
          readType,
          calleeFunctionType,
          read.fileOffset);
      node._storeLetType(inferrer, replacedRead, readType);
    }
    node._inferRhs(inferrer, readType, writeContext);
    node._replaceWithDesugared();
    return null;
  }

  void visitIntJudgment(IntJudgment node, DartType typeContext) {
    if (inferrer.isDoubleContext(typeContext)) {
      double doubleValue = node.asDouble();
      if (doubleValue != null) {
        node.parent.replaceChild(
            node, DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
        node.inferredType = inferrer.coreTypes.doubleClass.rawType;
        return null;
      }
    }
    Expression error = checkWebIntLiteralsErrorIfUnexact(
        inferrer, node.value, node.literal, node.fileOffset);
    if (error != null) {
      node.parent.replaceChild(node, error);
      node.inferredType = const BottomType();
      return null;
    }
    node.inferredType = inferrer.coreTypes.intClass.rawType;
    return null;
  }

  void visitShadowLargeIntLiteral(
      ShadowLargeIntLiteral node, DartType typeContext) {
    if (inferrer.isDoubleContext(typeContext)) {
      double doubleValue = node.asDouble();
      if (doubleValue != null) {
        node.parent.replaceChild(
            node, DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
        node.inferredType = inferrer.coreTypes.doubleClass.rawType;
        return null;
      }
    }

    int intValue = node.asInt64();
    if (intValue == null) {
      Expression replacement = inferrer.helper.desugarSyntheticExpression(
          inferrer.helper.buildProblem(
              templateIntegerLiteralIsOutOfRange.withArguments(node.literal),
              node.fileOffset,
              node.literal.length));
      node.parent.replaceChild(node, replacement);
      node.inferredType = const BottomType();
      return null;
    }
    Expression error = checkWebIntLiteralsErrorIfUnexact(
        inferrer, intValue, node.literal, node.fileOffset);
    if (error != null) {
      node.parent.replaceChild(node, error);
      node.inferredType = const BottomType();
      return null;
    }
    node.parent
        .replaceChild(node, IntLiteral(intValue)..fileOffset = node.fileOffset);
    node.inferredType = inferrer.coreTypes.intClass.rawType;
    return null;
  }

  void visitShadowInvalidInitializer(ShadowInvalidInitializer node) {
    inferrer.inferExpression(
        node.variable.initializer, const UnknownType(), !inferrer.isTopLevel);
  }

  void visitShadowInvalidFieldInitializer(ShadowInvalidFieldInitializer node) {
    inferrer.inferExpression(node.value, node.field.type, !inferrer.isTopLevel);
  }

  @override
  void visitIsExpression(IsExpression node, DartType typeContext) {
    inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel);
  }

  @override
  void visitLabeledStatement(LabeledStatement node, _) {
    inferrer.inferStatement(node.body);
  }

  DartType getSpreadElementType(DartType spreadType, bool isNullAware) {
    if (spreadType is InterfaceType) {
      InterfaceType supertype = inferrer.typeSchemaEnvironment
          .getTypeAsInstanceOf(spreadType, inferrer.coreTypes.iterableClass);
      if (supertype != null) return supertype.typeArguments[0];
      if (spreadType.classNode == inferrer.coreTypes.nullClass && isNullAware) {
        return spreadType;
      }
      return null;
    }
    if (spreadType is DynamicType) return const DynamicType();
    return null;
  }

  void visitListLiteralJudgment(
      ListLiteralJudgment node, DartType typeContext) {
    var listClass = inferrer.coreTypes.listClass;
    var listType = listClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(listType,
          listClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: node.isConst);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    List<DartType> spreadTypes =
        typeChecksNeeded ? new List<DartType>(node.expressions.length) : null;
    if (inferenceNeeded || typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; ++i) {
        Expression judgment = node.expressions[i];
        if (judgment is SpreadElement) {
          DartType spreadType = inferrer.inferExpression(
              judgment.expression,
              new InterfaceType(inferrer.coreTypes.iterableClass,
                  <DartType>[inferredTypeArgument]),
              inferenceNeeded || typeChecksNeeded,
              isVoidAllowed: true);
          if (inferenceNeeded) {
            formalTypes.add(listType.typeArguments[0]);
          }
          if (typeChecksNeeded) {
            spreadTypes[i] = spreadType;
          }
          // Use 'dynamic' for error recovery.
          actualTypes.add(
              getSpreadElementType(spreadType, judgment.isNullAware) ??
                  const DynamicType());
        } else {
          inferrer.inferExpression(judgment, inferredTypeArgument,
              inferenceNeeded || typeChecksNeeded,
              isVoidAllowed: true);
          if (inferenceNeeded) {
            formalTypes.add(listType.typeArguments[0]);
          }
          actualTypes.add(getInferredType(judgment, inferrer));
        }
      }
    }
    if (inferenceNeeded) {
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          listType,
          listClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      inferredTypeArgument = inferredTypes[0];
      inferrer.instrumentation?.record(
          inferrer.uri,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      node.typeArgument = inferredTypeArgument;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; i++) {
        Expression item = node.expressions[i];
        if (item is SpreadElement) {
          DartType spreadType = spreadTypes[i];
          DartType spreadElementType =
              getSpreadElementType(spreadType, item.isNullAware);
          if (spreadElementType == null) {
            if (spreadType is InterfaceType &&
                spreadType.classNode == inferrer.coreTypes.nullClass &&
                !item.isNullAware) {
              node.replaceChild(
                  node.expressions[i],
                  inferrer.helper.desugarSyntheticExpression(inferrer.helper
                      .buildProblem(messageNonNullAwareSpreadIsNull,
                          item.expression.fileOffset, 1)));
            } else {
              node.replaceChild(
                  node.expressions[i],
                  inferrer.helper.desugarSyntheticExpression(inferrer.helper
                      .buildProblem(
                          templateSpreadTypeMismatch.withArguments(spreadType),
                          item.expression.fileOffset,
                          1)));
            }
          } else if (spreadType is DynamicType) {
            inferrer.ensureAssignable(inferrer.coreTypes.iterableClass.rawType,
                spreadType, item.expression, item.expression.fileOffset);
          } else if (spreadType is InterfaceType) {
            if (!inferrer.isAssignable(node.typeArgument, spreadElementType)) {
              node.replaceChild(
                  node.expressions[i],
                  inferrer.helper.desugarSyntheticExpression(inferrer.helper
                      .buildProblem(
                          templateSpreadElementTypeMismatch.withArguments(
                              spreadElementType, node.typeArgument),
                          item.expression.fileOffset,
                          1)));
            }
          }
        } else {
          inferrer.ensureAssignable(
              node.typeArgument, actualTypes[i], item, item.fileOffset,
              isVoidAllowed: node.typeArgument is VoidType);
        }
      }
    }
    node.inferredType = new InterfaceType(listClass, [inferredTypeArgument]);
    if (!inferrer.isTopLevel) {
      KernelLibraryBuilder library = inferrer.library;
      if (inferenceNeeded) {
        library.checkBoundsInListLiteral(node, inferrer.typeSchemaEnvironment,
            inferred: true);
      }
    }

    return null;
  }

  @override
  void visitLogicalExpression(LogicalExpression node, DartType typeContext) {
    var boolType = inferrer.coreTypes.boolClass.rawType;
    var left = node.left;
    var right = node.right;
    inferrer.inferExpression(left, boolType, !inferrer.isTopLevel);
    inferrer.inferExpression(right, boolType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(boolType, getInferredType(left, inferrer),
        node.left, node.left.fileOffset);
    inferrer.ensureAssignable(boolType, getInferredType(right, inferrer),
        node.right, node.right.fileOffset);
    return null;
  }

  // Calculates the key and the value type of a spread map entry of type
  // spreadMapEntryType and stores them in output in positions offset and offset
  // + 1.  If the types can't be calculated, for example, if spreadMapEntryType
  // is a function type, the original values in output are preserved.
  void storeSpreadMapEntryElementTypes(DartType spreadMapEntryType,
      bool isNullAware, List<DartType> output, int offset) {
    if (spreadMapEntryType is InterfaceType) {
      InterfaceType supertype = inferrer.typeSchemaEnvironment
          .getTypeAsInstanceOf(spreadMapEntryType, inferrer.coreTypes.mapClass);
      if (supertype != null) {
        output[offset] = supertype.typeArguments[0];
        output[offset + 1] = supertype.typeArguments[1];
      } else if (spreadMapEntryType.classNode == inferrer.coreTypes.nullClass &&
          isNullAware) {
        output[offset] = output[offset + 1] = spreadMapEntryType;
      }
    }
    if (spreadMapEntryType is DynamicType) {
      output[offset] = output[offset + 1] = const DynamicType();
    }
  }

  void visitMapLiteralJudgment(MapLiteralJudgment node, DartType typeContext) {
    var mapClass = inferrer.coreTypes.mapClass;
    var mapType = mapClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredKeyType;
    DartType inferredValueType;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    assert((node.keyType is ImplicitTypeArgument) ==
        (node.valueType is ImplicitTypeArgument));
    bool inferenceNeeded = node.keyType is ImplicitTypeArgument;
    KernelLibraryBuilder library = inferrer.library;
    bool typeContextIsMap = false;
    bool typeContextIsIterable = false;
    if (!inferrer.isTopLevel) {
      if (library.loader.target.enableSetLiterals && inferenceNeeded) {
        // Ambiguous set/map literal
        DartType context =
            inferrer.typeSchemaEnvironment.unfutureType(typeContext);
        if (context is InterfaceType) {
          typeContextIsMap = inferrer.classHierarchy
              .isSubtypeOf(context.classNode, inferrer.coreTypes.mapClass);
          typeContextIsIterable = inferrer.classHierarchy
              .isSubtypeOf(context.classNode, inferrer.coreTypes.iterableClass);
          if (node.entries.isEmpty &&
              typeContextIsIterable &&
              !typeContextIsMap) {
            // Set literal
            SetLiteralJudgment setLiteral = new SetLiteralJudgment([],
                typeArgument: const ImplicitTypeArgument(),
                isConst: node.isConst)
              ..fileOffset = node.fileOffset;
            node.parent.replaceChild(node, setLiteral);
            visitSetLiteralJudgment(setLiteral, typeContext);
            node.inferredType = setLiteral.inferredType;
            return;
          }
        }
      }
    }
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType(), const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(mapType,
          mapClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: node.isConst);
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
    } else {
      inferredKeyType = node.keyType;
      inferredValueType = node.valueType;
    }
    List<Expression> cachedKeys = new List(node.entries.length);
    List<Expression> cachedValues = new List(node.entries.length);
    List<DartType> spreadMapEntryTypes =
        typeChecksNeeded ? new List<DartType>(node.entries.length) : null;
    for (int i = 0; i < node.entries.length; i++) {
      MapEntry entry = node.entries[i];
      if (entry is! SpreadMapEntry && entry is! IfMapEntry) {
        cachedKeys[i] = node.entries[i].key;
        cachedValues[i] = node.entries[i].value;
      }
    }
    int iterableSpreadOffset = -1;
    int mapSpreadOffset = -1;
    int mapEntryOffset = -1;
    if (inferenceNeeded || typeChecksNeeded) {
      DartType spreadTypeContext = const UnknownType();
      if (typeContextIsIterable && !typeContextIsMap) {
        spreadTypeContext = inferrer.typeSchemaEnvironment
            .getTypeAsInstanceOf(typeContext, inferrer.coreTypes.iterableClass);
      } else if (!typeContextIsIterable && typeContextIsMap) {
        spreadTypeContext =
            new InterfaceType(inferrer.coreTypes.mapClass, inferredTypes);
      }
      for (int i = 0; i < node.entries.length; ++i) {
        MapEntry entry = node.entries[i];
        if (entry is SpreadMapEntry) {
          DartType spreadMapEntryType = inferrer.inferExpression(
              entry.expression,
              spreadTypeContext,
              inferenceNeeded || typeChecksNeeded,
              isVoidAllowed: true);
          if (inferenceNeeded) {
            formalTypes.add(mapType.typeArguments[0]);
            formalTypes.add(mapType.typeArguments[1]);
          }
          if (typeChecksNeeded) {
            spreadMapEntryTypes[i] = spreadMapEntryType;
          }

          bool isMap = inferrer.typeSchemaEnvironment.isSubtypeOf(
              spreadMapEntryType, inferrer.coreTypes.mapClass.rawType);
          bool isSet = inferrer.typeSchemaEnvironment.isSubtypeOf(
              spreadMapEntryType, inferrer.coreTypes.iterableClass.rawType);

          if (isMap && !isSet) {
            mapSpreadOffset = entry.expression.fileOffset;
          }
          if (!isMap && isSet) {
            iterableSpreadOffset = entry.expression.fileOffset;
          }

          // Use 'dynamic' for error recovery.
          int length = actualTypes.length;
          actualTypes.add(const DynamicType());
          actualTypes.add(const DynamicType());
          storeSpreadMapEntryElementTypes(
              spreadMapEntryType, entry.isNullAware, actualTypes, length);
        } else if (entry is IfMapEntry) {
          node.entries[i] = new MapEntry(
              new InvalidExpression('unimplemented spread entry')
                ..fileOffset = node.fileOffset,
              new NullLiteral());
          actualTypes.add(const DynamicType());
          actualTypes.add(const DynamicType());
        } else {
          Expression key = entry.key;
          inferrer.inferExpression(key, inferredKeyType, true,
              isVoidAllowed: true);
          actualTypes.add(getInferredType(key, inferrer));
          Expression value = entry.value;
          inferrer.inferExpression(value, inferredValueType, true,
              isVoidAllowed: true);
          actualTypes.add(getInferredType(value, inferrer));
          if (inferenceNeeded) {
            formalTypes.addAll(mapType.typeArguments);
          }

          mapEntryOffset = entry.fileOffset;
        }
      }
    }
    if (inferenceNeeded) {
      bool canBeSet =
          mapSpreadOffset == -1 && mapEntryOffset == -1 && !typeContextIsMap;
      bool canBeMap = iterableSpreadOffset == -1 && !typeContextIsIterable;
      if (canBeSet && !canBeMap) {
        List<Expression> setElements = <Expression>[];
        for (int i = 0; i < node.entries.length; ++i) {
          SpreadMapEntry entry = node.entries[i];
          setElements
              .add(new SpreadElement(entry.expression, entry.isNullAware));
        }
        SetLiteralJudgment setLiteral = new SetLiteralJudgment(setElements,
            typeArgument: const ImplicitTypeArgument(), isConst: node.isConst)
          ..fileOffset = node.fileOffset;
        node.parent.replaceChild(node, setLiteral);
        visitSetLiteralJudgment(setLiteral, typeContext);
        node.inferredType = setLiteral.inferredType;
        return;
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        node.parent.replaceChild(
            node,
            inferrer.helper.desugarSyntheticExpression(inferrer.helper
                .buildProblem(messageCantDisambiguateNotEnoughInformation,
                    node.fileOffset, 1)));
        node.inferredType = const BottomType();
        return;
      }
      if (!canBeSet && !canBeMap) {
        if (!inferrer.isTopLevel) {
          LocatedMessage iterableContextMessage = messageSpreadElement
              .withLocation(library.uri, iterableSpreadOffset, 1);
          LocatedMessage mapContextMessage = messageSpreadMapElement
              .withLocation(library.uri, mapSpreadOffset, 1);
          List<LocatedMessage> context = <LocatedMessage>[];
          if (iterableSpreadOffset < mapSpreadOffset) {
            context.add(iterableContextMessage);
            context.add(mapContextMessage);
          } else {
            context.add(mapContextMessage);
            context.add(iterableContextMessage);
          }
          node.parent.replaceChild(
              node,
              inferrer.helper.desugarSyntheticExpression(inferrer.helper
                  .buildProblem(messageCantDisambiguateAmbiguousInformation,
                      node.fileOffset, 1,
                      context: context)));
        }
        node.inferredType = const BottomType();
        return;
      }
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          mapType,
          mapClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
      inferrer.instrumentation?.record(
          inferrer.uri,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs(
              [inferredKeyType, inferredValueType]));
      node.keyType = inferredKeyType;
      node.valueType = inferredValueType;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < node.entries.length; ++i) {
        MapEntry entry = node.entries[i];
        List<DartType> spreadMapEntryElementTypes = new List<DartType>(2);
        if (entry is SpreadMapEntry) {
          DartType spreadMapEntryType = spreadMapEntryTypes[i];
          spreadMapEntryElementTypes[0] = spreadMapEntryElementTypes[1] = null;
          storeSpreadMapEntryElementTypes(spreadMapEntryType, entry.isNullAware,
              spreadMapEntryElementTypes, 0);
          if (spreadMapEntryElementTypes[0] == null) {
            if (spreadMapEntryType is InterfaceType &&
                spreadMapEntryType.classNode == inferrer.coreTypes.nullClass &&
                !entry.isNullAware) {
              node.replaceChild(
                  node.entries[i],
                  new MapEntry(
                      inferrer.helper.desugarSyntheticExpression(inferrer.helper
                          .buildProblem(messageNonNullAwareSpreadIsNull,
                              entry.expression.fileOffset, 1)),
                      new NullLiteral()));
            } else {
              node.replaceChild(
                  node.entries[i],
                  new MapEntry(
                      inferrer.helper.desugarSyntheticExpression(inferrer.helper
                          .buildProblem(
                              templateSpreadMapEntryTypeMismatch
                                  .withArguments(spreadMapEntryType),
                              entry.expression.fileOffset,
                              1)),
                      new NullLiteral()));
            }
          } else if (spreadMapEntryType is DynamicType) {
            inferrer.ensureAssignable(
                inferrer.coreTypes.mapClass.rawType,
                spreadMapEntryType,
                entry.expression,
                entry.expression.fileOffset);
          } else if (spreadMapEntryType is InterfaceType) {
            Expression keyError;
            Expression valueError;
            if (!inferrer.isAssignable(
                node.keyType, spreadMapEntryElementTypes[0])) {
              keyError = inferrer.helper.desugarSyntheticExpression(
                  inferrer.helper.buildProblem(
                      templateSpreadMapEntryElementKeyTypeMismatch
                          .withArguments(
                              spreadMapEntryElementTypes[0], node.keyType),
                      entry.expression.fileOffset,
                      1));
            }
            if (!inferrer.isAssignable(
                node.valueType, spreadMapEntryElementTypes[1])) {
              valueError = inferrer.helper.desugarSyntheticExpression(
                  inferrer.helper.buildProblem(
                      templateSpreadMapEntryElementValueTypeMismatch
                          .withArguments(
                              spreadMapEntryElementTypes[1], node.valueType),
                      entry.expression.fileOffset,
                      1));
            }
            if (keyError != null || valueError != null) {
              keyError ??= new NullLiteral();
              valueError ??= new NullLiteral();
              node.replaceChild(
                  node.entries[i], new MapEntry(keyError, valueError));
            }
          }
        } else {
          Expression keyJudgment = cachedKeys[i];
          if (keyJudgment != null) {
            inferrer.ensureAssignable(node.keyType, actualTypes[2 * i],
                keyJudgment, keyJudgment.fileOffset,
                isVoidAllowed: node.keyType is VoidType);

            Expression valueJudgment = cachedValues[i];
            inferrer.ensureAssignable(node.valueType, actualTypes[2 * i + 1],
                valueJudgment, valueJudgment.fileOffset,
                isVoidAllowed: node.valueType is VoidType);
          }
        }
      }
    }
    node.inferredType =
        new InterfaceType(mapClass, [inferredKeyType, inferredValueType]);
    if (!inferrer.isTopLevel) {
      KernelLibraryBuilder library = inferrer.library;
      // Either both [_declaredKeyType] and [_declaredValueType] are omitted or
      // none of them, so we may just check one.
      if (inferenceNeeded) {
        library.checkBoundsInMapLiteral(node, inferrer.typeSchemaEnvironment,
            inferred: true);
      }
    }
  }

  void visitMethodInvocationJudgment(
      MethodInvocationJudgment node, DartType typeContext) {
    if (node.name.name == 'unary-' &&
        node.arguments.types.isEmpty &&
        node.arguments.positional.isEmpty &&
        node.arguments.named.isEmpty) {
      // Replace integer literals in a double context with the corresponding
      // double literal if it's exact.  For double literals, the negation is
      // folded away.  In any non-double context, or if there is no exact
      // double value, then the corresponding integer literal is left.  The
      // negation is not folded away so that platforms with web literals can
      // distinguish between (non-negated) 0x8000000000000000 represented as
      // integer literal -9223372036854775808 which should be a positive number,
      // and negated 9223372036854775808 represented as
      // -9223372036854775808.unary-() which should be a negative number.
      if (node.receiver is IntJudgment) {
        IntJudgment receiver = node.receiver;
        if (inferrer.isDoubleContext(typeContext)) {
          double doubleValue = receiver.asDouble(negated: true);
          if (doubleValue != null) {
            node.parent.replaceChild(
                node, DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
            node.inferredType = inferrer.coreTypes.doubleClass.rawType;
            return null;
          }
        }
        Expression error = checkWebIntLiteralsErrorIfUnexact(
            inferrer, receiver.value, receiver.literal, receiver.fileOffset);
        if (error != null) {
          node.parent.replaceChild(node, error);
          node.inferredType = const BottomType();
          return null;
        }
      } else if (node.receiver is ShadowLargeIntLiteral) {
        ShadowLargeIntLiteral receiver = node.receiver;
        if (!receiver.isParenthesized) {
          if (inferrer.isDoubleContext(typeContext)) {
            double doubleValue = receiver.asDouble(negated: true);
            if (doubleValue != null) {
              node.parent.replaceChild(node,
                  DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
              node.inferredType = inferrer.coreTypes.doubleClass.rawType;
              return null;
            }
          }
          int intValue = receiver.asInt64(negated: true);
          if (intValue == null) {
            Expression error = inferrer.helper.desugarSyntheticExpression(
                inferrer.helper.buildProblem(
                    templateIntegerLiteralIsOutOfRange
                        .withArguments(receiver.literal),
                    receiver.fileOffset,
                    receiver.literal.length));
            node.parent.replaceChild(node, error);
            node.inferredType = const BottomType();
            return null;
          }
          if (intValue != null) {
            Expression error = checkWebIntLiteralsErrorIfUnexact(
                inferrer, intValue, receiver.literal, receiver.fileOffset);
            if (error != null) {
              node.parent.replaceChild(node, error);
              node.inferredType = const BottomType();
              return null;
            }
            node.receiver = IntLiteral(-intValue)
              ..fileOffset = node.receiver.fileOffset
              ..parent = node;
          }
        }
      }
    }
    var inferenceResult = inferrer.inferMethodInvocation(
        node, node.receiver, node.fileOffset, node._isImplicitCall, typeContext,
        desugaredInvocation: node);
    node.inferredType = inferenceResult.type;
  }

  void visitNamedFunctionExpressionJudgment(
      NamedFunctionExpressionJudgment node, DartType typeContext) {
    Expression initializer = node.variableJudgment.initializer;
    inferrer.inferExpression(initializer, typeContext, true);
    node.inferredType = getInferredType(initializer, inferrer);
    node.variable.type = node.inferredType;
    return null;
  }

  @override
  void visitNot(Not node, DartType typeContext) {
    var operand = node.operand;
    var boolType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(operand, boolType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(boolType, getInferredType(operand, inferrer),
        node.operand, node.fileOffset);
  }

  void visitNullAwareMethodInvocationJudgment(
      NullAwareMethodInvocationJudgment node, DartType typeContext) {
    var inferenceResult = inferrer.inferMethodInvocation(
        node, node.variable.initializer, node.fileOffset, false, typeContext,
        receiverVariable: node.variable,
        desugaredInvocation: node._desugaredInvocation);
    node.inferredType = inferenceResult.type;
    node.body.staticType = node.inferredType;
    return null;
  }

  void visitNullAwarePropertyGetJudgment(
      NullAwarePropertyGetJudgment node, DartType typeContext) {
    inferrer.inferPropertyGet(
        node, node.receiverJudgment, node.fileOffset, typeContext,
        receiverVariable: node.variable, desugaredGet: node._desugaredGet);
    node.body.staticType = node.inferredType;
    return null;
  }

  @override
  void visitNullLiteral(NullLiteral node, DartType typeContext) {}

  @override
  void visitLet(Let node, DartType typeContext) {
    DartType variableType = node.variable.type;
    if (variableType == const DynamicType()) {
      return defaultExpression(node, typeContext);
    }
    Expression initializer = node.variable.initializer;
    inferrer.inferExpression(initializer, variableType, true,
        isVoidAllowed: true);
    Expression body = node.body;
    inferrer.inferExpression(body, typeContext, true, isVoidAllowed: true);
    // TODO(ahe): This shouldn't be needed. See InferredTypeVisitor.visitLet.
    inferrer.storeInferredType(node, getInferredType(body, inferrer));
  }

  void visitPropertyAssignmentJudgment(
      PropertyAssignmentJudgment node, DartType typeContext) {
    var receiverType = node._inferReceiver(inferrer);

    DartType readType;
    if (node.read != null) {
      var readMember = inferrer.findPropertyGetMember(receiverType, node.read,
          instrumented: false);
      readType = inferrer.getCalleeType(readMember, receiverType);
      inferrer.handlePropertyGetContravariance(
          node.receiver,
          readMember,
          node.read is PropertyGet ? node.read : null,
          node.read,
          readType,
          node.read.fileOffset);
      node._storeLetType(inferrer, node.read, readType);
    }
    Member writeMember;
    if (node.write != null) {
      writeMember = node._handleWriteContravariance(inferrer, receiverType);
    }
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member when
    // doing compound assignment?
    var writeContext = inferrer.getSetterType(writeMember, receiverType);
    node._inferRhs(inferrer, readType, writeContext);
    node.nullAwareGuard?.staticType = node.inferredType;
    node._replaceWithDesugared();
    return null;
  }

  @override
  void visitPropertyGet(PropertyGet node, DartType typeContext) {
    inferrer.inferPropertyGet(node, node.receiver, node.fileOffset, typeContext,
        desugaredGet: node);
  }

  void visitRedirectingInitializerJudgment(
      RedirectingInitializerJudgment node) {
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    List<DartType> typeArguments =
        new List<DartType>(classTypeParameters.length);
    for (int i = 0; i < typeArguments.length; i++) {
      typeArguments[i] = new TypeParameterType(classTypeParameters[i]);
    }
    ArgumentsJudgment.setNonInferrableArgumentTypes(
        node.arguments, typeArguments);
    inferrer.inferInvocation(
        null,
        node.fileOffset,
        node.target.function.functionType,
        node.target.enclosingClass.thisType,
        node.argumentJudgments,
        skipTypeArgumentInference: true);
    ArgumentsJudgment.removeNonInferrableArgumentTypes(node.arguments);
  }

  @override
  void visitRethrow(Rethrow node, DartType typeContext) {}

  void visitReturnJudgment(ReturnJudgment node) {
    var judgment = node.judgment;
    var closureContext = inferrer.closureContext;
    DartType typeContext = !closureContext.isGenerator
        ? closureContext.returnOrYieldContext
        : const UnknownType();
    DartType inferredType;
    if (node.expression != null) {
      inferrer.inferExpression(judgment, typeContext, true,
          isVoidAllowed: true);
      inferredType = getInferredType(judgment, inferrer);
    } else {
      inferredType = inferrer.coreTypes.nullClass.rawType;
    }
    closureContext.handleReturn(inferrer, node, inferredType,
        !identical(node.returnKeywordLexeme, "return"));
  }

  void visitSetLiteralJudgment(SetLiteralJudgment node, DartType typeContext) {
    var setClass = inferrer.coreTypes.setClass;
    var setType = setClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(setType,
          setClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: node.isConst);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    List<DartType> spreadTypes =
        typeChecksNeeded ? new List<DartType>(node.expressions.length) : null;
    if (inferenceNeeded || typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; ++i) {
        Expression judgment = node.expressions[i];
        if (judgment is SpreadElement) {
          DartType spreadType = inferrer.inferExpression(
              judgment.expression,
              new InterfaceType(inferrer.coreTypes.iterableClass,
                  <DartType>[inferredTypeArgument]),
              inferenceNeeded || typeChecksNeeded,
              isVoidAllowed: true);
          if (inferenceNeeded) {
            formalTypes.add(setType.typeArguments[0]);
          }
          if (typeChecksNeeded) {
            spreadTypes[i] = spreadType;
          }
          // Use 'dynamic' for error recovery.
          actualTypes.add(
              getSpreadElementType(spreadType, judgment.isNullAware) ??
                  const DynamicType());
        } else {
          inferrer.inferExpression(judgment, inferredTypeArgument,
              inferenceNeeded || typeChecksNeeded,
              isVoidAllowed: true);
          if (inferenceNeeded) {
            formalTypes.add(setType.typeArguments[0]);
          }
          actualTypes.add(getInferredType(judgment, inferrer));
        }
      }
    }
    if (inferenceNeeded) {
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          setType,
          setClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      inferredTypeArgument = inferredTypes[0];
      inferrer.instrumentation?.record(
          inferrer.uri,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      node.typeArgument = inferredTypeArgument;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; i++) {
        Expression item = node.expressions[i];
        if (item is SpreadElement) {
          DartType spreadType = spreadTypes[i];
          DartType spreadElementType =
              getSpreadElementType(spreadType, item.isNullAware);
          if (spreadElementType == null) {
            if (spreadType is InterfaceType &&
                spreadType.classNode == inferrer.coreTypes.nullClass &&
                !item.isNullAware) {
              node.replaceChild(
                  node.expressions[i],
                  inferrer.helper.desugarSyntheticExpression(inferrer.helper
                      .buildProblem(messageNonNullAwareSpreadIsNull,
                          item.expression.fileOffset, 1)));
            } else {
              node.replaceChild(
                  node.expressions[i],
                  inferrer.helper.desugarSyntheticExpression(inferrer.helper
                      .buildProblem(
                          templateSpreadTypeMismatch.withArguments(spreadType),
                          item.expression.fileOffset,
                          1)));
            }
          } else if (spreadType is DynamicType) {
            inferrer.ensureAssignable(inferrer.coreTypes.iterableClass.rawType,
                spreadType, item.expression, item.expression.fileOffset);
          } else if (spreadType is InterfaceType) {
            if (!inferrer.isAssignable(node.typeArgument, spreadElementType)) {
              node.replaceChild(
                  node.expressions[i],
                  inferrer.helper.desugarSyntheticExpression(inferrer.helper
                      .buildProblem(
                          templateSpreadElementTypeMismatch.withArguments(
                              spreadElementType, node.typeArgument),
                          item.expression.fileOffset,
                          1)));
            }
          }
        } else {
          inferrer.ensureAssignable(node.typeArgument, actualTypes[i],
              node.expressions[i], node.expressions[i].fileOffset,
              isVoidAllowed: node.typeArgument is VoidType);
        }
      }
    }
    node.inferredType = new InterfaceType(setClass, [inferredTypeArgument]);
    if (!inferrer.isTopLevel) {
      KernelLibraryBuilder library = inferrer.library;
      if (inferenceNeeded) {
        library.checkBoundsInSetLiteral(node, inferrer.typeSchemaEnvironment,
            inferred: true);
      }

      if (!library.loader.target.backendTarget.supportsSetLiterals) {
        inferrer.helper.transformSetLiterals = true;
      }
    }
  }

  void visitStaticAssignmentJudgment(
      StaticAssignmentJudgment node, DartType typeContext) {
    DartType readType = const DynamicType(); // Only used in error recovery
    var read = node.read;
    if (read is StaticGet) {
      readType = read.target.getterType;
      node._storeLetType(inferrer, read, readType);
    }
    Member writeMember;
    DartType writeContext = const UnknownType();
    var write = node.write;
    if (write is StaticSet) {
      writeContext = write.target.setterType;
      writeMember = write.target;
      TypeInferenceEngine.resolveInferenceNode(writeMember);
    }
    node._inferRhs(inferrer, readType, writeContext);
    node._replaceWithDesugared();
    return null;
  }

  @override
  void visitStaticGet(StaticGet node, DartType typeContext) {
    var target = node.target;
    TypeInferenceEngine.resolveInferenceNode(target);
    var type = target.getterType;
    if (target is Procedure && target.kind == ProcedureKind.Method) {
      type = inferrer.instantiateTearOff(type, typeContext, node);
    }
    inferrer.storeInferredType(node, type);
  }

  @override
  void visitStaticInvocation(StaticInvocation node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.functionType
        : new FunctionType([], const DynamicType());
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    var inferenceResult = inferrer.inferInvocation(typeContext, node.fileOffset,
        calleeType, calleeType.returnType, node.arguments);
    inferrer.storeInferredType(node, inferenceResult.type);
    if (!hadExplicitTypeArguments && node.target != null) {
      inferrer.library?.checkBoundsInStaticInvocation(
          node, inferrer.typeSchemaEnvironment,
          inferred: true);
    }
  }

  @override
  void visitStringConcatenation(
      StringConcatenation node, DartType typeContext) {
    if (!inferrer.isTopLevel) {
      for (var expression in node.expressions) {
        inferrer.inferExpression(
            expression, const UnknownType(), !inferrer.isTopLevel);
      }
    }
  }

  @override
  void visitStringLiteral(StringLiteral node, DartType typeContext) {}

  void visitSuperInitializerJudgment(SuperInitializerJudgment node) {
    var substitution = Substitution.fromSupertype(inferrer.classHierarchy
        .getClassAsInstanceOf(
            inferrer.thisType.classNode, node.target.enclosingClass));
    inferrer.inferInvocation(
        null,
        node.fileOffset,
        substitution.substituteType(
            node.target.function.functionType.withoutTypeParameters),
        inferrer.thisType,
        node.argumentJudgments,
        skipTypeArgumentInference: true);
  }

  void visitSuperMethodInvocationJudgment(
      SuperMethodInvocationJudgment node, DartType typeContext) {
    if (node.interfaceTarget != null) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset, 'target',
          new InstrumentationValueForMember(node.interfaceTarget));
    }
    var inferenceResult = inferrer.inferMethodInvocation(
        node, null, node.fileOffset, false, typeContext,
        interfaceMember: node.interfaceTarget,
        methodName: node.name,
        arguments: node.arguments);
    node.inferredType = inferenceResult.type;
  }

  void visitSuperPropertyGetJudgment(
      SuperPropertyGetJudgment node, DartType typeContext) {
    if (node.interfaceTarget != null) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset, 'target',
          new InstrumentationValueForMember(node.interfaceTarget));
    }
    inferrer.inferPropertyGet(node, null, node.fileOffset, typeContext,
        interfaceMember: node.interfaceTarget, propertyName: node.name);
  }

  void visitSwitchStatementJudgment(SwitchStatementJudgment node) {
    var expressionJudgment = node.expressionJudgment;
    inferrer.inferExpression(expressionJudgment, const UnknownType(), true);
    var expressionType = getInferredType(expressionJudgment, inferrer);

    for (var switchCase in node.caseJudgments) {
      for (var caseExpression in switchCase.expressionJudgments) {
        DartType caseExpressionType =
            inferrer.inferExpression(caseExpression, expressionType, true);

        // Check whether the expression type is assignable to the case expression type.
        if (!inferrer.isAssignable(expressionType, caseExpressionType)) {
          inferrer.helper.addProblem(
              templateSwitchExpressionNotAssignable.withArguments(
                  expressionType, caseExpressionType),
              caseExpression.fileOffset,
              noLength,
              context: [
                messageSwitchExpressionNotAssignableCause.withLocation(
                    inferrer.uri, expressionJudgment.fileOffset, noLength)
              ]);
        }
      }
      inferrer.inferStatement(switchCase.body);
    }
  }

  void visitSymbolLiteralJudgment(
      SymbolLiteralJudgment node, DartType typeContext) {
    node.inferredType = inferrer.coreTypes.symbolClass.rawType;
    return null;
  }

  void visitInvalidConstructorInvocationJudgment(
      InvalidConstructorInvocationJudgment node, DartType typeContext) {
    FunctionType calleeType;
    DartType returnType;
    if (node.constructor != null) {
      calleeType = node.constructor.function.functionType;
      returnType = computeConstructorReturnType(node.constructor);
    } else {
      calleeType = new FunctionType([], const DynamicType());
      returnType = const DynamicType();
    }
    ExpressionInferenceResult inferenceResult = inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        calleeType,
        returnType,
        node.argumentJudgments);
    node.inferredType = inferenceResult.type;
    return visitSyntheticExpressionJudgment(node, typeContext);
  }

  void visitInvalidWriteJudgment(
      InvalidWriteJudgment node, DartType typeContext) {
    // When a compound assignment, the expression is already wrapping in
    // VariableDeclaration in _makeRead(). Otherwise, temporary associate
    // the expression with this node.
    node.expression.parent ??= node;

    inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel);
    return visitSyntheticExpressionJudgment(node, typeContext);
  }

  void visitSyntheticExpressionJudgment(
      SyntheticExpressionJudgment node, DartType typeContext) {
    node._replaceWithDesugared();
    node.inferredType = const DynamicType();
    return null;
  }

  void visitThisExpression(ThisExpression node, DartType typeContext) {}

  @override
  void visitThrow(Throw node, DartType typeContext) {
    inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel);
  }

  void visitCatchJudgment(CatchJudgment node) {
    inferrer.inferStatement(node.body);
  }

  void visitTryCatchJudgment(TryCatchJudgment node) {
    inferrer.inferStatement(node.body);
    for (var catch_ in node.catchJudgments) {
      visitCatchJudgment(catch_);
    }
  }

  void visitTryFinallyJudgment(TryFinallyJudgment node) {
    inferrer.inferStatement(node.body);
    inferrer.inferStatement(node.finalizer);
  }

  void visitTypeLiteralJudgment(
      TypeLiteralJudgment node, DartType typeContext) {
    node.inferredType = inferrer.coreTypes.typeClass.rawType;
    return null;
  }

  void visitVariableAssignmentJudgment(
      VariableAssignmentJudgment node, DartType typeContext) {
    DartType readType;
    var read = node.read;
    if (read is VariableGet) {
      readType = read.promotedType ?? read.variable.type;
    }
    DartType writeContext = const UnknownType();
    var write = node.write;
    if (write is VariableSet) {
      writeContext = write.variable.type;
      if (read != null) {
        node._storeLetType(inferrer, read, writeContext);
      }
    }
    node._inferRhs(inferrer, readType, writeContext);
    node._replaceWithDesugared();
    return null;
  }

  void visitVariableDeclarationJudgment(VariableDeclarationJudgment node) {
    var initializerJudgment = node.initializerJudgment;
    var declaredType = node._implicitlyTyped ? const UnknownType() : node.type;
    DartType inferredType;
    DartType initializerType;
    if (initializerJudgment != null) {
      inferrer.inferExpression(initializerJudgment, declaredType,
          !inferrer.isTopLevel || node._implicitlyTyped,
          isVoidAllowed: true);
      initializerType = getInferredType(initializerJudgment, inferrer);
      inferredType = inferrer.inferDeclarationType(initializerType);
    } else {
      inferredType = const DynamicType();
    }
    if (node._implicitlyTyped) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset, 'type',
          new InstrumentationValueForType(inferredType));
      node.type = inferredType;
    }
    if (node.initializer != null) {
      var replacedInitializer = inferrer.ensureAssignable(
          node.type, initializerType, node.initializer, node.fileOffset,
          isVoidAllowed: node.type is VoidType);
      if (replacedInitializer != null) {
        node.initializer = replacedInitializer;
      }
    }
    if (!inferrer.isTopLevel) {
      KernelLibraryBuilder library = inferrer.library;
      if (node._implicitlyTyped) {
        library.checkBoundsInVariableDeclaration(
            node, inferrer.typeSchemaEnvironment,
            inferred: true);
      }
    }
  }

  void visitUnresolvedTargetInvocationJudgment(
      UnresolvedTargetInvocationJudgment node, DartType typeContext) {
    var result = visitSyntheticExpressionJudgment(node, typeContext);
    inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        TypeInferrerImpl.unknownFunction,
        const DynamicType(),
        node.argumentsJudgment);
    return result;
  }

  void visitUnresolvedVariableAssignmentJudgment(
      UnresolvedVariableAssignmentJudgment node, DartType typeContext) {
    inferrer.inferExpression(node.rhs, const UnknownType(), true);
    node.inferredType = node.isCompound
        ? const DynamicType()
        : getInferredType(node.rhs, inferrer);
    return visitSyntheticExpressionJudgment(node, typeContext);
  }

  void visitVariableGetJudgment(
      VariableGetJudgment node, DartType typeContext) {
    VariableDeclarationJudgment variable = node.variable;
    bool mutatedInClosure = variable._mutatedInClosure;
    DartType declaredOrInferredType = variable.type;

    DartType promotedType = inferrer.typePromoter
        .computePromotedType(node._fact, node._scope, mutatedInClosure);
    if (promotedType != null) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset,
          'promotedType', new InstrumentationValueForType(promotedType));
    }
    node.promotedType = promotedType;
    var type = promotedType ?? declaredOrInferredType;
    if (variable._isLocalFunction) {
      type = inferrer.instantiateTearOff(type, typeContext, node);
    }
    node.inferredType = type;
    return null;
  }

  void visitWhileJudgment(WhileJudgment node) {
    var conditionJudgment = node.conditionJudgment;
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(
        conditionJudgment, expectedType, !inferrer.isTopLevel);
    inferrer.ensureAssignable(
        expectedType,
        getInferredType(conditionJudgment, inferrer),
        node.condition,
        node.condition.fileOffset);
    inferrer.inferStatement(node.body);
  }

  void visitYieldJudgment(YieldJudgment node) {
    var judgment = node.judgment;
    var closureContext = inferrer.closureContext;
    if (closureContext.isGenerator) {
      var typeContext = closureContext.returnOrYieldContext;
      if (node.isYieldStar && typeContext != null) {
        typeContext = inferrer.wrapType(
            typeContext,
            closureContext.isAsync
                ? inferrer.coreTypes.streamClass
                : inferrer.coreTypes.iterableClass);
      }
      inferrer.inferExpression(judgment, typeContext, true);
    } else {
      inferrer.inferExpression(judgment, const UnknownType(), true);
    }
    closureContext.handleYield(inferrer, node.isYieldStar,
        getInferredType(judgment, inferrer), node.expression, node.fileOffset);
  }

  void visitLoadLibraryJudgment(
      LoadLibraryJudgment node, DartType typeContext) {
    node.inferredType =
        inferrer.typeSchemaEnvironment.futureType(const DynamicType());
    if (node.arguments != null) {
      var calleeType = new FunctionType([], node.inferredType);
      inferrer.inferInvocation(typeContext, node.fileOffset, calleeType,
          calleeType.returnType, node.argumentJudgments);
    }
    return null;
  }

  void visitLoadLibraryTearOffJudgment(
      LoadLibraryTearOffJudgment node, DartType typeContext) {
    node.inferredType = new FunctionType(
        [], inferrer.typeSchemaEnvironment.futureType(const DynamicType()));
    return null;
  }

  @override
  void visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, DartType typeContext) {}
}
