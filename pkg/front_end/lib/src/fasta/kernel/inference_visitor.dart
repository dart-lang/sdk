// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "kernel_shadow_ast.dart";

class InferenceVisitor
    implements
        ExpressionVisitor1<ExpressionInferenceResult, DartType>,
        StatementVisitor<void>,
        InitializerVisitor<void> {
  final ShadowTypeInferrer inferrer;

  Class mapEntryClass;

  // Stores the offset of the map entry found by inferMapEntry.
  int mapEntryOffset = null;

  // Stores the offset of the map spread found by inferMapEntry.
  int mapSpreadOffset = null;

  // Stores the offset of the iterable spread found by inferMapEntry.
  int iterableSpreadOffset = null;

  // Stores the type of the iterable spread found by inferMapEntry.
  DartType iterableSpreadType = null;

  InferenceVisitor(this.inferrer);

  ExpressionInferenceResult _unhandledExpression(
      Expression node, DartType typeContext) {
    unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        inferrer.helper.uri);
    return const ExpressionInferenceResult(const InvalidType());
  }

  @override
  ExpressionInferenceResult defaultExpression(
      Expression node, DartType typeContext) {
    if (node is InternalExpression) {
      switch (node.kind) {
        case InternalExpressionKind.Cascade:
          return visitCascade(node, typeContext);
        case InternalExpressionKind.CompoundIndexSet:
          return visitCompoundIndexSet(node, typeContext);
        case InternalExpressionKind.CompoundPropertySet:
          return visitCompoundPropertySet(node, typeContext);
        case InternalExpressionKind.DeferredCheck:
          return visitDeferredCheck(node, typeContext);
        case InternalExpressionKind.IfNullIndexSet:
          return visitIfNullIndexSet(node, typeContext);
        case InternalExpressionKind.IfNullPropertySet:
          return visitIfNullPropertySet(node, typeContext);
        case InternalExpressionKind.IndexSet:
          return visitIndexSet(node, typeContext);
        case InternalExpressionKind.LoadLibraryTearOff:
          return visitLoadLibraryTearOff(node, typeContext);
        case InternalExpressionKind.LocalPostIncDec:
          return visitLocalPostIncDec(node, typeContext);
        case InternalExpressionKind.NullAwareMethodInvocation:
          return visitNullAwareMethodInvocation(node, typeContext);
        case InternalExpressionKind.NullAwarePropertyGet:
          return visitNullAwarePropertyGet(node, typeContext);
        case InternalExpressionKind.NullAwarePropertySet:
          return visitNullAwarePropertySet(node, typeContext);
        case InternalExpressionKind.PropertyPostIncDec:
          return visitPropertyPostIncDec(node, typeContext);
        case InternalExpressionKind.StaticPostIncDec:
          return visitStaticPostIncDec(node, typeContext);
      }
    }
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult defaultBasicLiteral(
      BasicLiteral node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitBlockExpression(
      BlockExpression node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitConstantExpression(
      ConstantExpression node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitDirectMethodInvocation(
      DirectMethodInvocation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitDirectPropertyGet(
      DirectPropertyGet node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitDirectPropertySet(
      DirectPropertySet node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitFileUriExpression(
      FileUriExpression node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitInstanceCreation(
      InstanceCreation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitInstantiation(
      Instantiation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitListConcatenation(
      ListConcatenation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitMapConcatenation(
      MapConcatenation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitSetConcatenation(
      SetConcatenation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  void _unhandledStatement(Statement node) {
    unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        inferrer.helper.uri);
  }

  @override
  void defaultStatement(Statement node) {
    _unhandledStatement(node);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    _unhandledStatement(node);
  }

  void _unhandledInitializer(Initializer node) {
    unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        node.location.file);
  }

  @override
  void defaultInitializer(Initializer node) {
    _unhandledInitializer(node);
  }

  @override
  void visitInvalidInitializer(Initializer node) {
    _unhandledInitializer(node);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    _unhandledInitializer(node);
  }

  @override
  ExpressionInferenceResult visitInvalidExpression(
      InvalidExpression node, DartType typeContext) {
    return const ExpressionInferenceResult(const BottomType());
  }

  @override
  ExpressionInferenceResult visitIntLiteral(
      IntLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.intRawType(inferrer.library.nonNullable));
  }

  @override
  ExpressionInferenceResult visitAsExpression(
      AsExpression node, DartType typeContext) {
    inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
    return new ExpressionInferenceResult(node.type);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    inferrer.inferStatement(node.statement);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType conditionType = inferrer
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        expectedType, conditionType, node.condition, node.condition.fileOffset);
    if (node.message != null) {
      inferrer.inferExpression(
          node.message, const UnknownType(), !inferrer.isTopLevel);
    }
  }

  @override
  ExpressionInferenceResult visitAwaitExpression(
      AwaitExpression node, DartType typeContext) {
    if (!inferrer.typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = inferrer.wrapFutureOrType(typeContext);
    }
    DartType operandType = inferrer
        .inferExpression(node.operand, typeContext, true, isVoidAllowed: true)
        .inferredType;
    DartType inferredType =
        inferrer.typeSchemaEnvironment.unfutureType(operandType);
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      inferrer.inferStatement(statement);
    }
  }

  @override
  ExpressionInferenceResult visitBoolLiteral(
      BoolLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable));
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    // No inference needs to be done.
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferrer.inferExpression(node.expression, typeContext, true);
    node.variable.type = result.inferredType;
    for (Expression judgment in node.cascades) {
      inferrer.inferExpression(
          judgment, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
    }
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitConditionalExpression(
      ConditionalExpression node, DartType typeContext) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType conditionType = inferrer
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        expectedType, conditionType, node.condition, node.condition.fileOffset);
    DartType thenType = inferrer
        .inferExpression(node.then, typeContext, true, isVoidAllowed: true)
        .inferredType;
    DartType otherwiseType = inferrer
        .inferExpression(node.otherwise, typeContext, true, isVoidAllowed: true)
        .inferredType;
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(thenType, otherwiseType);
    node.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitConstructorInvocation(
      ConstructorInvocation node, DartType typeContext) {
    LibraryBuilder library = inferrer.engine.beingInferred[node.target];
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
      for (VariableDeclaration declaration
          in node.target.function.positionalParameters) {
        declaration.type ??= const InvalidType();
      }
      for (VariableDeclaration declaration
          in node.target.function.namedParameters) {
        declaration.type ??= const InvalidType();
      }
    } else if ((library = inferrer.engine.toBeInferred[node.target]) != null) {
      inferrer.engine.toBeInferred.remove(node.target);
      inferrer.engine.beingInferred[node.target] = library;
      for (VariableDeclaration declaration
          in node.target.function.positionalParameters) {
        inferrer.engine.inferInitializingFormal(declaration, node.target);
      }
      for (VariableDeclaration declaration
          in node.target.function.namedParameters) {
        inferrer.engine.inferInitializingFormal(declaration, node.target);
      }
      inferrer.engine.beingInferred.remove(node.target);
    }
    bool hasExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    DartType inferredType = inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        node.target.function.thisFunctionType,
        computeConstructorReturnType(node.target),
        node.arguments,
        isConst: node.isConst);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (!hasExplicitTypeArguments) {
        library.checkBoundsInConstructorInvocation(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    // No inference needs to be done.
  }

  ExpressionInferenceResult visitDeferredCheck(
      DeferredCheck node, DartType typeContext) {
    // Since the variable is not used in the body we don't need to type infer
    // it.  We can just type infer the body.
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.expression, typeContext, true,
        isVoidAllowed: true);
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  void visitDoStatement(DoStatement node) {
    inferrer.inferStatement(node.body);
    InterfaceType boolType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType conditionType = inferrer
        .inferExpression(node.condition, boolType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        boolType, conditionType, node.condition, node.condition.fileOffset);
  }

  ExpressionInferenceResult visitDoubleLiteral(
      DoubleLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable));
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    // No inference needs to be done.
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
  }

  ExpressionInferenceResult visitFactoryConstructorInvocationJudgment(
      FactoryConstructorInvocationJudgment node, DartType typeContext) {
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    DartType inferredType = inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        node.target.function.thisFunctionType,
        computeConstructorReturnType(node.target),
        node.arguments,
        isConst: node.isConst);
    node.hasBeenInferred = true;
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (!hadExplicitTypeArguments) {
        library.checkBoundsInFactoryInvocation(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    ExpressionInferenceResult initializerResult =
        inferrer.inferExpression(node.value, node.field.type, true);
    DartType initializerType = initializerResult.inferredType;
    inferrer.ensureAssignable(
        node.field.type, initializerType, node.value, node.fileOffset);
  }

  void handleForInDeclaringVariable(
      VariableDeclaration variable, Expression iterable, Statement body,
      {bool isAsync: false}) {
    DartType elementType;
    bool typeNeeded = false;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (VariableDeclarationImpl.isImplicitlyTyped(variable)) {
      typeNeeded = true;
      elementType = const UnknownType();
    } else {
      elementType = variable.type;
    }

    DartType inferredType = inferForInIterable(
        iterable, elementType, typeNeeded || typeChecksNeeded,
        isAsync: isAsync);
    if (typeNeeded) {
      inferrer.instrumentation?.record(inferrer.uri, variable.fileOffset,
          'type', new InstrumentationValueForType(inferredType));
      variable.type = inferredType;
    }

    if (body != null) inferrer.inferStatement(body);

    VariableDeclaration tempVar =
        new VariableDeclaration(null, type: inferredType, isFinal: true);
    VariableGet variableGet = new VariableGet(tempVar)
      ..fileOffset = variable.fileOffset;
    TreeNode parent = variable.parent;
    Expression implicitDowncast = inferrer.ensureAssignable(
        variable.type, inferredType, variableGet, parent.fileOffset,
        template: templateForInLoopElementTypeNotAssignable);
    if (implicitDowncast != null) {
      parent.replaceChild(variable, tempVar);
      variable.initializer = implicitDowncast..parent = variable;
      if (body == null) {
        if (parent is ForInElement) {
          parent.prologue = variable;
        } else if (parent is ForInMapEntry) {
          parent.prologue = variable;
        } else {
          unhandled("${parent.runtimeType}", "handleForInDeclaringVariable",
              variable.fileOffset, variable.location.file);
        }
      } else {
        parent.replaceChild(body, combineStatements(variable, body));
      }
    }
  }

  DartType inferForInIterable(
      Expression iterable, DartType elementType, bool typeNeeded,
      {bool isAsync: false}) {
    Class iterableClass = isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context = inferrer.wrapType(elementType, iterableClass);
    ExpressionInferenceResult iterableResult =
        inferrer.inferExpression(iterable, context, typeNeeded);
    DartType iterableType = iterableResult.inferredType;
    if (iterableResult.replacement != null) {
      iterable = iterableResult.replacement;
    }
    DartType inferredExpressionType =
        inferrer.resolveTypeParameter(iterableType);
    inferrer.ensureAssignable(
        inferrer.wrapType(const DynamicType(), iterableClass),
        inferredExpressionType,
        iterable,
        iterable.fileOffset,
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

  void handleForInWithoutVariable(
      VariableDeclaration variable, Expression iterable, Statement body,
      {bool isAsync: false}) {
    DartType elementType;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    DartType syntheticWriteType;
    Expression syntheticAssignment;
    Expression rhs;
    // If `true`, the synthetic statement should not be visited.
    bool skipStatement = false;
    ExpressionStatement syntheticStatement =
        body is Block ? body.statements.first : body;
    Expression statementExpression = syntheticStatement.expression;
    if (statementExpression is SyntheticExpressionJudgment) {
      syntheticAssignment = statementExpression.desugared;
    } else {
      syntheticAssignment = statementExpression;
    }
    if (syntheticAssignment is VariableSet) {
      syntheticWriteType = elementType = syntheticAssignment.variable.type;
      rhs = syntheticAssignment.value;
      // This expression is fully handled in this method so we should not
      // visit the synthetic statement.
      skipStatement = true;
    } else if (syntheticAssignment is PropertySet ||
        syntheticAssignment is SuperPropertySet) {
      DartType receiverType = inferrer.thisType;
      ObjectAccessTarget writeTarget =
          inferrer.findPropertySetMember(receiverType, syntheticAssignment);
      syntheticWriteType =
          elementType = inferrer.getSetterType(writeTarget, receiverType);
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

    DartType inferredType = inferForInIterable(
        iterable, elementType, typeChecksNeeded,
        isAsync: isAsync);
    if (typeChecksNeeded) {
      variable.type = inferredType;
    }

    if (body is Block) {
      for (Statement statement in body.statements) {
        if (!skipStatement || statement != syntheticStatement) {
          inferrer.inferStatement(statement);
        }
      }
    } else {
      if (!skipStatement) {
        inferrer.inferStatement(body);
      }
    }

    if (syntheticWriteType != null) {
      inferrer.ensureAssignable(
          greatestClosure(inferrer.coreTypes, syntheticWriteType),
          variable.type,
          rhs,
          rhs.fileOffset,
          template: templateForInLoopElementTypeNotAssignable,
          isVoidAllowed: true);
    }
  }

  @override
  void visitForInStatement(ForInStatement node) {
    if (node.variable.name == null) {
      handleForInWithoutVariable(node.variable, node.iterable, node.body,
          isAsync: node.isAsync);
    } else {
      handleForInDeclaringVariable(node.variable, node.iterable, node.body,
          isAsync: node.isAsync);
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    for (VariableDeclaration variable in node.variables) {
      if (variable.name == null) {
        if (variable.initializer != null) {
          ExpressionInferenceResult result = inferrer.inferExpression(
              variable.initializer, const UnknownType(), true,
              isVoidAllowed: true);
          variable.type = result.inferredType;
        }
      } else {
        inferrer.inferStatement(variable);
      }
    }
    if (node.condition != null) {
      InterfaceType expectedType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      DartType conditionType = inferrer
          .inferExpression(node.condition, expectedType, !inferrer.isTopLevel)
          .inferredType;
      inferrer.ensureAssignable(expectedType, conditionType, node.condition,
          node.condition.fileOffset);
    }
    for (Expression update in node.updates) {
      inferrer.inferExpression(
          update, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
    }
    inferrer.inferStatement(node.body);
  }

  DartType visitFunctionNode(FunctionNode node, DartType typeContext,
      DartType returnContext, int returnTypeInstrumentationOffset) {
    return inferrer.inferLocalFunction(
        node, typeContext, returnTypeInstrumentationOffset, returnContext);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    inferrer.inferMetadataKeepingHelper(node.variable.annotations);
    DartType returnContext =
        node._hasImplicitReturnType ? null : node.function.returnType;
    DartType inferredType =
        visitFunctionNode(node.function, null, returnContext, node.fileOffset);
    node.variable.type = inferredType;
  }

  @override
  ExpressionInferenceResult visitFunctionExpression(
      FunctionExpression node, DartType typeContext) {
    DartType inferredType =
        visitFunctionNode(node.function, typeContext, null, node.fileOffset);
    return new ExpressionInferenceResult(inferredType);
  }

  void visitInvalidSuperInitializerJudgment(
      InvalidSuperInitializerJudgment node) {
    Substitution substitution = Substitution.fromSupertype(
        inferrer.classHierarchy.getClassAsInstanceOf(
            inferrer.thisType.classNode, node.target.enclosingClass));
    inferrer.inferInvocation(
        null,
        node.fileOffset,
        substitution.substituteType(
            node.target.function.thisFunctionType.withoutTypeParameters),
        inferrer.thisType,
        node.argumentsJudgment,
        skipTypeArgumentInference: true);
  }

  ExpressionInferenceResult visitIfNullJudgment(
      IfNullJudgment node, DartType typeContext) {
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    DartType lhsType =
        inferrer.inferExpression(node.left, typeContext, true).inferredType;
    node.variable.type = lhsType;
    // - Let J = T0 if K is `?` else K.
    // - Infer e1 in context J to get T1
    DartType rhsType;
    if (typeContext is UnknownType) {
      rhsType = inferrer
          .inferExpression(node.right, lhsType, true, isVoidAllowed: true)
          .inferredType;
    } else {
      rhsType = inferrer
          .inferExpression(node.right, typeContext, true, isVoidAllowed: true)
          .inferredType;
    }
    // - Let T = greatest closure of K with respect to `?` if K is not `_`, else
    //   UP(t0, t1)
    // - Then the inferred type is T.
    DartType inferredType =
        inferrer.typeSchemaEnvironment.getStandardUpperBound(lhsType, rhsType);
    node.body.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  void visitIfStatement(IfStatement node) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType conditionType = inferrer
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        expectedType, conditionType, node.condition, node.condition.fileOffset);
    inferrer.inferStatement(node.then);
    if (node.otherwise != null) {
      inferrer.inferStatement(node.otherwise);
    }
  }

  ExpressionInferenceResult visitIllegalAssignmentJudgment(
      IllegalAssignmentJudgment node, DartType typeContext) {
    if (node.write != null) {
      inferrer.inferExpression(
          node.write, const UnknownType(), !inferrer.isTopLevel);
    }
    inferrer.inferExpression(
        node.rhs, const UnknownType(), !inferrer.isTopLevel);
    node._replaceWithDesugared();
    return const ExpressionInferenceResult(const DynamicType());
  }

  ExpressionInferenceResult visitIndexAssignmentJudgment(
      IndexAssignmentJudgment node, DartType typeContext) {
    DartType receiverType = node._inferReceiver(inferrer);
    ObjectAccessTarget writeTarget =
        inferrer.findMethodInvocationMember(receiverType, node.write);
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member
    // when doing compound assignment?
    DartType indexContext = const UnknownType();
    DartType expectedIndexTypeForWrite =
        inferrer.getIndexKeyType(writeTarget, receiverType);
    DartType writeContext =
        inferrer.getIndexSetValueType(writeTarget, receiverType);
    ExpressionInferenceResult indexResult =
        inferrer.inferExpression(node.index, indexContext, true);
    DartType indexType = indexResult.inferredType;
    node._storeLetType(inferrer, node.index, indexType);
    if (indexResult.replacement != null) {
      node.index = indexResult.replacement;
    }
    Expression writeIndexExpression =
        node._getInvocationArguments(inferrer, node.write).positional[0];
    if (writeTarget.isExtensionMember) {
      MethodInvocation write = node.write;
      Expression replacement = inferrer.transformExtensionMethodInvocation(
          writeTarget, write, write.receiver, write.arguments);
      node.write = replacement;
    }
    if (writeContext is! UnknownType) {
      inferrer.ensureAssignable(expectedIndexTypeForWrite, indexType,
          writeIndexExpression, node.write.fileOffset);
    }

    InvocationExpression read = node.read;
    DartType readType;
    if (read != null) {
      ObjectAccessTarget readMember = inferrer
          .findMethodInvocationMember(receiverType, read, instrumented: false);
      FunctionType calleeFunctionType =
          inferrer.getFunctionType(readMember, receiverType, false);
      inferrer.ensureAssignable(
          getPositionalParameterType(calleeFunctionType, 0),
          indexType,
          node._getInvocationArguments(inferrer, read).positional[0],
          read.fileOffset);
      readType = calleeFunctionType.returnType;
      MethodInvocation desugaredInvocation =
          read is MethodInvocation ? read : null;
      MethodContravarianceCheckKind checkKind =
          inferrer.preCheckInvocationContravariance(receiverType, readMember,
              isThisReceiver: node.receiver is ThisExpression);
      Expression replacedRead = inferrer.handleInvocationContravariance(
          checkKind,
          desugaredInvocation,
          read.arguments,
          read,
          readType,
          calleeFunctionType,
          read.fileOffset);
      node._storeLetType(inferrer, replacedRead, readType);
    }
    DartType inferredType =
        node._inferRhs(inferrer, readType, writeContext).inferredType;
    node._replaceWithDesugared();
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitIntJudgment(
      IntJudgment node, DartType typeContext) {
    if (inferrer.isDoubleContext(typeContext)) {
      double doubleValue = node.asDouble();
      if (doubleValue != null) {
        node.parent.replaceChild(
            node, new DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
        DartType inferredType =
            inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
        return new ExpressionInferenceResult(inferredType);
      }
    }
    Expression error = checkWebIntLiteralsErrorIfUnexact(
        inferrer, node.value, node.literal, node.fileOffset);

    if (error != null) {
      node.parent.replaceChild(node, error);
      return const ExpressionInferenceResult(const BottomType());
    }
    DartType inferredType =
        inferrer.coreTypes.intRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitShadowLargeIntLiteral(
      ShadowLargeIntLiteral node, DartType typeContext) {
    if (inferrer.isDoubleContext(typeContext)) {
      double doubleValue = node.asDouble();
      if (doubleValue != null) {
        node.parent.replaceChild(
            node, new DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
        DartType inferredType =
            inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
        return new ExpressionInferenceResult(inferredType);
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
      return const ExpressionInferenceResult(const BottomType());
    }
    Expression error = checkWebIntLiteralsErrorIfUnexact(
        inferrer, intValue, node.literal, node.fileOffset);
    if (error != null) {
      node.parent.replaceChild(node, error);
      return const ExpressionInferenceResult(const BottomType());
    }
    node.parent.replaceChild(
        node, new IntLiteral(intValue)..fileOffset = node.fileOffset);
    DartType inferredType =
        inferrer.coreTypes.intRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType);
  }

  void visitShadowInvalidInitializer(ShadowInvalidInitializer node) {
    inferrer.inferExpression(
        node.variable.initializer, const UnknownType(), !inferrer.isTopLevel);
  }

  void visitShadowInvalidFieldInitializer(ShadowInvalidFieldInitializer node) {
    inferrer.inferExpression(node.value, node.field.type, !inferrer.isTopLevel);
  }

  @override
  ExpressionInferenceResult visitIsExpression(
      IsExpression node, DartType typeContext) {
    inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel);
    return new ExpressionInferenceResult(
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable));
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
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

  DartType inferElement(
      Expression element,
      TreeNode parent,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes,
      bool inferenceNeeded,
      bool typeChecksNeeded) {
    if (element is SpreadElement) {
      ExpressionInferenceResult spreadResult = inferrer.inferExpression(
          element.expression,
          new InterfaceType(inferrer.coreTypes.iterableClass,
              <DartType>[inferredTypeArgument]),
          inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      DartType spreadType = spreadResult.inferredType;
      inferredSpreadTypes[element.expression] = spreadType;
      if (typeChecksNeeded) {
        DartType spreadElementType =
            getSpreadElementType(spreadType, element.isNullAware);
        if (spreadElementType == null) {
          if (spreadType is InterfaceType &&
              spreadType.classNode == inferrer.coreTypes.nullClass &&
              !element.isNullAware) {
            parent.replaceChild(
                element,
                inferrer.helper.desugarSyntheticExpression(inferrer.helper
                    .buildProblem(messageNonNullAwareSpreadIsNull,
                        element.expression.fileOffset, 1)));
          } else {
            parent.replaceChild(
                element,
                inferrer.helper.desugarSyntheticExpression(inferrer.helper
                    .buildProblem(
                        templateSpreadTypeMismatch.withArguments(spreadType),
                        element.expression.fileOffset,
                        1)));
          }
        } else if (spreadType is InterfaceType) {
          if (!inferrer.isAssignable(inferredTypeArgument, spreadElementType)) {
            parent.replaceChild(
                element,
                inferrer.helper.desugarSyntheticExpression(inferrer.helper
                    .buildProblem(
                        templateSpreadElementTypeMismatch.withArguments(
                            spreadElementType, inferredTypeArgument),
                        element.expression.fileOffset,
                        1)));
          }
        }
      }
      // Use 'dynamic' for error recovery.
      return element.elementType =
          getSpreadElementType(spreadType, element.isNullAware) ??
              const DynamicType();
    } else if (element is IfElement) {
      DartType boolType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          element.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      DartType conditionType = conditionResult.inferredType;
      inferrer.ensureAssignable(boolType, conditionType, element.condition,
          element.condition.fileOffset);
      DartType thenType = inferElement(
          element.then,
          element,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      DartType otherwiseType;
      if (element.otherwise != null) {
        otherwiseType = inferElement(
            element.otherwise,
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
      }
      return otherwiseType == null
          ? thenType
          : inferrer.typeSchemaEnvironment
              .getStandardUpperBound(thenType, otherwiseType);
    } else if (element is ForElement) {
      for (VariableDeclaration declaration in element.variables) {
        if (declaration.name == null) {
          if (declaration.initializer != null) {
            ExpressionInferenceResult initializerResult =
                inferrer.inferExpression(declaration.initializer,
                    declaration.type, inferenceNeeded || typeChecksNeeded,
                    isVoidAllowed: true);
            declaration.type = initializerResult.inferredType;
          }
        } else {
          inferrer.inferStatement(declaration);
        }
      }
      if (element.condition != null) {
        inferredConditionTypes[element.condition] = inferrer
            .inferExpression(
                element.condition,
                inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
                inferenceNeeded || typeChecksNeeded,
                isVoidAllowed: false)
            .inferredType;
      }
      for (Expression expression in element.updates) {
        inferrer.inferExpression(expression, const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
      }
      return inferElement(
          element.body,
          element,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
    } else if (element is ForInElement) {
      if (element.variable.name == null) {
        handleForInWithoutVariable(
            element.variable, element.iterable, element.prologue,
            isAsync: element.isAsync);
      } else {
        handleForInDeclaringVariable(
            element.variable, element.iterable, element.prologue,
            isAsync: element.isAsync);
      }
      if (element.problem != null) {
        inferrer.inferExpression(element.problem, const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
      }
      return inferElement(
          element.body,
          element,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
    } else {
      ExpressionInferenceResult result = inferrer.inferExpression(
          element, inferredTypeArgument, inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      if (result.replacement != null) {
        element = result.replacement;
      }
      DartType inferredType = result.inferredType;
      if (inferredTypeArgument is! UnknownType) {
        inferrer.ensureAssignable(
            inferredTypeArgument, inferredType, element, element.fileOffset,
            isVoidAllowed: inferredTypeArgument is VoidType);
      }
      return inferredType;
    }
  }

  void checkElement(
      Expression item,
      Expression parent,
      DartType typeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    if (item is SpreadElement) {
      DartType spreadType = inferredSpreadTypes[item.expression];
      if (spreadType is DynamicType) {
        inferrer.ensureAssignable(
            inferrer.coreTypes.iterableRawType(
                inferrer.library.nullableIfTrue(item.isNullAware)),
            spreadType,
            item.expression,
            item.expression.fileOffset);
      }
    } else if (item is IfElement) {
      checkElement(item.then, item, typeArgument, inferredSpreadTypes,
          inferredConditionTypes);
      if (item.otherwise != null) {
        checkElement(item.otherwise, item, typeArgument, inferredSpreadTypes,
            inferredConditionTypes);
      }
    } else if (item is ForElement) {
      if (item.condition != null) {
        DartType conditionType = inferredConditionTypes[item.condition];
        inferrer.ensureAssignable(
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            conditionType,
            item.condition,
            item.condition.fileOffset);
      }
      checkElement(item.body, item, typeArgument, inferredSpreadTypes,
          inferredConditionTypes);
    } else if (item is ForInElement) {
      checkElement(item.body, item, typeArgument, inferredSpreadTypes,
          inferredConditionTypes);
    } else {
      // Do nothing.  Assignability checks are done during type inference.
    }
  }

  @override
  ExpressionInferenceResult visitListLiteral(
      ListLiteral node, DartType typeContext) {
    Class listClass = inferrer.coreTypes.listClass;
    InterfaceType listType = listClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    Map<TreeNode, DartType> inferredSpreadTypes;
    Map<Expression, DartType> inferredConditionTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
      inferredSpreadTypes = new Map<TreeNode, DartType>.identity();
      inferredConditionTypes = new Map<Expression, DartType>.identity();
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
    if (inferenceNeeded || typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; ++i) {
        DartType type = inferElement(
            node.expressions[i],
            node,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        actualTypes.add(type);
        if (inferenceNeeded) {
          formalTypes.add(listType.typeArguments[0]);
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
        checkElement(node.expressions[i], node, node.typeArgument,
            inferredSpreadTypes, inferredConditionTypes);
      }
    }
    DartType inferredType =
        new InterfaceType(listClass, [inferredTypeArgument]);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (inferenceNeeded) {
        library.checkBoundsInListLiteral(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }

    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitLogicalExpression(
      LogicalExpression node, DartType typeContext) {
    InterfaceType boolType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType leftType = inferrer
        .inferExpression(node.left, boolType, !inferrer.isTopLevel)
        .inferredType;
    DartType rightType = inferrer
        .inferExpression(node.right, boolType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        boolType, leftType, node.left, node.left.fileOffset);
    inferrer.ensureAssignable(
        boolType, rightType, node.right, node.right.fileOffset);
    return new ExpressionInferenceResult(boolType);
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

  // Note that inferMapEntry adds exactly two elements to actualTypes -- the
  // actual types of the key and the value.  The same technique is used for
  // actualTypesForSet, only inferMapEntry adds exactly one element to that
  // list: the actual type of the iterable spread elements in case the map
  // literal will be disambiguated as a set literal later.
  void inferMapEntry(
      MapEntry entry,
      TreeNode parent,
      DartType inferredKeyType,
      DartType inferredValueType,
      DartType spreadContext,
      List<DartType> actualTypes,
      List<DartType> actualTypesForSet,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes,
      bool inferenceNeeded,
      bool typeChecksNeeded) {
    if (entry is SpreadMapEntry) {
      ExpressionInferenceResult spreadResult = inferrer.inferExpression(
          entry.expression, spreadContext, inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      DartType spreadType = spreadResult.inferredType;
      inferredSpreadTypes[entry.expression] = spreadType;
      int length = actualTypes.length;
      actualTypes.add(null);
      actualTypes.add(null);
      storeSpreadMapEntryElementTypes(
          spreadType, entry.isNullAware, actualTypes, length);
      DartType actualKeyType = actualTypes[length];
      DartType actualValueType = actualTypes[length + 1];
      DartType actualElementType =
          getSpreadElementType(spreadType, entry.isNullAware);

      if (typeChecksNeeded) {
        if (actualKeyType == null) {
          if (spreadType is InterfaceType &&
              spreadType.classNode == inferrer.coreTypes.nullClass &&
              !entry.isNullAware) {
            parent.replaceChild(
                entry,
                new MapEntry(
                    inferrer.helper.desugarSyntheticExpression(inferrer.helper
                        .buildProblem(messageNonNullAwareSpreadIsNull,
                            entry.expression.fileOffset, 1)),
                    new NullLiteral())
                  ..fileOffset = entry.fileOffset);
          } else if (actualElementType != null) {
            // Don't report the error here, it might be an ambiguous Set.  The
            // error is reported in checkMapEntry if it's disambiguated as map.
            iterableSpreadType = spreadType;
          } else {
            parent.replaceChild(
                entry,
                new MapEntry(
                    inferrer.helper.desugarSyntheticExpression(inferrer.helper
                        .buildProblem(
                            templateSpreadMapEntryTypeMismatch
                                .withArguments(spreadType),
                            entry.expression.fileOffset,
                            1)),
                    new NullLiteral())
                  ..fileOffset = entry.fileOffset);
          }
        } else if (spreadType is InterfaceType) {
          Expression keyError;
          Expression valueError;
          if (!inferrer.isAssignable(inferredKeyType, actualKeyType)) {
            keyError = inferrer.helper.desugarSyntheticExpression(
                inferrer.helper.buildProblem(
                    templateSpreadMapEntryElementKeyTypeMismatch.withArguments(
                        actualKeyType, inferredKeyType),
                    entry.expression.fileOffset,
                    1));
          }
          if (!inferrer.isAssignable(inferredValueType, actualValueType)) {
            valueError = inferrer.helper.desugarSyntheticExpression(
                inferrer.helper.buildProblem(
                    templateSpreadMapEntryElementValueTypeMismatch
                        .withArguments(actualValueType, inferredValueType),
                    entry.expression.fileOffset,
                    1));
          }
          if (keyError != null || valueError != null) {
            keyError ??= new NullLiteral();
            valueError ??= new NullLiteral();
            parent.replaceChild(
                entry,
                new MapEntry(keyError, valueError)
                  ..fileOffset = entry.fileOffset);
          }
        }
      }

      // Use 'dynamic' for error recovery.
      if (actualKeyType == null) {
        actualKeyType = actualTypes[length] = const DynamicType();
        actualValueType = actualTypes[length + 1] = const DynamicType();
      }
      // Store the type in case of an ambiguous Set.  Use 'dynamic' for error
      // recovery.
      actualTypesForSet.add(actualElementType ?? const DynamicType());

      mapEntryClass ??=
          inferrer.coreTypes.index.getClass('dart:core', 'MapEntry');
      // TODO(dmitryas):  Handle the case of an ambiguous Set.
      entry.entryType = new InterfaceType(
          mapEntryClass, <DartType>[actualKeyType, actualValueType]);

      bool isMap = inferrer.typeSchemaEnvironment.isSubtypeOf(
          spreadType, inferrer.coreTypes.mapRawType(inferrer.library.nullable));
      bool isIterable = inferrer.typeSchemaEnvironment.isSubtypeOf(spreadType,
          inferrer.coreTypes.iterableRawType(inferrer.library.nullable));
      if (isMap && !isIterable) {
        mapSpreadOffset = entry.fileOffset;
      }
      if (!isMap && isIterable) {
        iterableSpreadOffset = entry.expression.fileOffset;
      }

      return;
    } else if (entry is IfMapEntry) {
      DartType boolType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          entry.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      DartType conditionType = conditionResult.inferredType;
      inferrer.ensureAssignable(
          boolType, conditionType, entry.condition, entry.condition.fileOffset);
      // Note that this recursive invocation of inferMapEntry will add two types
      // to actualTypes; they are the actual types of the current invocation if
      // the 'else' branch is empty.
      inferMapEntry(
          entry.then,
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      if (entry.otherwise != null) {
        // We need to modify the actual types added in the recursive call to
        // inferMapEntry.
        DartType actualValueType = actualTypes.removeLast();
        DartType actualKeyType = actualTypes.removeLast();
        DartType actualTypeForSet = actualTypesForSet.removeLast();
        inferMapEntry(
            entry.otherwise,
            entry,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        int length = actualTypes.length;
        actualTypes[length - 2] = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(actualKeyType, actualTypes[length - 2]);
        actualTypes[length - 1] = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(actualValueType, actualTypes[length - 1]);
        int lengthForSet = actualTypesForSet.length;
        actualTypesForSet[lengthForSet - 1] = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(
                actualTypeForSet, actualTypesForSet[lengthForSet - 1]);
      }
      return;
    } else if (entry is ForMapEntry) {
      for (VariableDeclaration declaration in entry.variables) {
        if (declaration.name == null) {
          if (declaration.initializer != null) {
            ExpressionInferenceResult result = inferrer.inferExpression(
                declaration.initializer,
                declaration.type,
                inferenceNeeded || typeChecksNeeded,
                isVoidAllowed: true);
            declaration.type = result.inferredType;
          }
        } else {
          inferrer.inferStatement(declaration);
        }
      }
      if (entry.condition != null) {
        inferredConditionTypes[entry.condition] = inferrer
            .inferExpression(
                entry.condition,
                inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
                inferenceNeeded || typeChecksNeeded,
                isVoidAllowed: false)
            .inferredType;
      }
      for (Expression expression in entry.updates) {
        inferrer.inferExpression(expression, const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
      }
      // Actual types are added by the recursive call.
      return inferMapEntry(
          entry.body,
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
    } else if (entry is ForInMapEntry) {
      if (entry.variable.name == null) {
        handleForInWithoutVariable(
            entry.variable, entry.iterable, entry.prologue,
            isAsync: entry.isAsync);
      } else {
        handleForInDeclaringVariable(
            entry.variable, entry.iterable, entry.prologue,
            isAsync: entry.isAsync);
      }
      if (entry.problem != null) {
        inferrer.inferExpression(entry.problem, const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
      }
      // Actual types are added by the recursive call.
      inferMapEntry(
          entry.body,
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
    } else {
      ExpressionInferenceResult keyResult = inferrer.inferExpression(
          entry.key, inferredKeyType, true,
          isVoidAllowed: true);
      DartType keyType = keyResult.inferredType;
      ExpressionInferenceResult valueResult = inferrer.inferExpression(
          entry.value, inferredValueType, true,
          isVoidAllowed: true);
      DartType valueType = valueResult.inferredType;
      inferrer.ensureAssignable(
          inferredKeyType, keyType, entry.key, entry.key.fileOffset,
          isVoidAllowed: inferredKeyType is VoidType);
      inferrer.ensureAssignable(
          inferredValueType, valueType, entry.value, entry.value.fileOffset,
          isVoidAllowed: inferredValueType is VoidType);
      actualTypes.add(keyType);
      actualTypes.add(valueType);
      // Use 'dynamic' for error recovery.
      actualTypesForSet.add(const DynamicType());
      mapEntryOffset = entry.fileOffset;
      return;
    }
  }

  void checkMapEntry(
      MapEntry entry,
      TreeNode parent,
      Expression cachedKey,
      Expression cachedValue,
      DartType keyType,
      DartType valueType,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    // It's disambiguated as a map literal.
    if (iterableSpreadOffset != null) {
      parent.replaceChild(
          entry,
          new MapEntry(
              inferrer.helper.desugarSyntheticExpression(inferrer.helper
                  .buildProblem(
                      templateSpreadMapEntryTypeMismatch
                          .withArguments(iterableSpreadType),
                      iterableSpreadOffset,
                      1)),
              new NullLiteral()));
    }
    if (entry is SpreadMapEntry) {
      DartType spreadType = inferredSpreadTypes[entry.expression];
      if (spreadType is DynamicType) {
        inferrer.ensureAssignable(
            inferrer.coreTypes
                .mapRawType(inferrer.library.nullableIfTrue(entry.isNullAware)),
            spreadType,
            entry.expression,
            entry.expression.fileOffset);
      }
    } else if (entry is IfMapEntry) {
      checkMapEntry(entry.then, entry, cachedKey, cachedValue, keyType,
          valueType, inferredSpreadTypes, inferredConditionTypes);
      if (entry.otherwise != null) {
        checkMapEntry(entry.otherwise, entry, cachedKey, cachedValue, keyType,
            valueType, inferredSpreadTypes, inferredConditionTypes);
      }
    } else if (entry is ForMapEntry) {
      if (entry.condition != null) {
        DartType conditionType = inferredConditionTypes[entry.condition];
        inferrer.ensureAssignable(
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            conditionType,
            entry.condition,
            entry.condition.fileOffset);
      }
      checkMapEntry(entry.body, entry, cachedKey, cachedValue, keyType,
          valueType, inferredSpreadTypes, inferredConditionTypes);
    } else if (entry is ForInMapEntry) {
      checkMapEntry(entry.body, entry, cachedKey, cachedValue, keyType,
          valueType, inferredSpreadTypes, inferredConditionTypes);
    } else {
      // Do nothing.  Assignability checks are done during type inference.
    }
  }

  @override
  ExpressionInferenceResult visitMapLiteral(
      MapLiteral node, DartType typeContext) {
    Class mapClass = inferrer.coreTypes.mapClass;
    InterfaceType mapType = mapClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredKeyType;
    DartType inferredValueType;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    List<DartType> actualTypesForSet;
    assert((node.keyType is ImplicitTypeArgument) ==
        (node.valueType is ImplicitTypeArgument));
    bool inferenceNeeded = node.keyType is ImplicitTypeArgument;
    bool typeContextIsMap = node.keyType is! ImplicitTypeArgument;
    bool typeContextIsIterable = false;
    if (!inferrer.isTopLevel && inferenceNeeded) {
      // Ambiguous set/map literal
      DartType context =
          inferrer.typeSchemaEnvironment.unfutureType(typeContext);
      if (context is InterfaceType) {
        typeContextIsMap = typeContextIsMap ||
            inferrer.classHierarchy
                .isSubtypeOf(context.classNode, inferrer.coreTypes.mapClass);
        typeContextIsIterable = typeContextIsIterable ||
            inferrer.classHierarchy.isSubtypeOf(
                context.classNode, inferrer.coreTypes.iterableClass);
        if (node.entries.isEmpty &&
            typeContextIsIterable &&
            !typeContextIsMap) {
          // Set literal
          SetLiteral setLiteral = new SetLiteral([],
              typeArgument: const ImplicitTypeArgument(), isConst: node.isConst)
            ..fileOffset = node.fileOffset;
          node.parent.replaceChild(node, setLiteral);
          ExpressionInferenceResult setLiteralResult =
              visitSetLiteral(setLiteral, typeContext);
          DartType inferredType = setLiteralResult.inferredType;
          return new ExpressionInferenceResult(inferredType);
        }
      }
    }
    bool typeChecksNeeded = !inferrer.isTopLevel;
    Map<TreeNode, DartType> inferredSpreadTypes;
    Map<Expression, DartType> inferredConditionTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
      actualTypesForSet = [];
      inferredSpreadTypes = new Map<TreeNode, DartType>.identity();
      inferredConditionTypes = new Map<Expression, DartType>.identity();
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
    for (int i = 0; i < node.entries.length; i++) {
      MapEntry entry = node.entries[i];
      if (entry is! ControlFlowMapEntry) {
        cachedKeys[i] = node.entries[i].key;
        cachedValues[i] = node.entries[i].value;
      }
    }
    bool hasMapEntry = false;
    bool hasMapSpread = false;
    bool hasIterableSpread = false;
    if (inferenceNeeded || typeChecksNeeded) {
      mapEntryOffset = null;
      mapSpreadOffset = null;
      iterableSpreadOffset = null;
      iterableSpreadType = null;
      DartType spreadTypeContext = const UnknownType();
      if (typeContextIsIterable && !typeContextIsMap) {
        spreadTypeContext = inferrer.typeSchemaEnvironment
            .getTypeAsInstanceOf(typeContext, inferrer.coreTypes.iterableClass);
      } else if (!typeContextIsIterable && typeContextIsMap) {
        spreadTypeContext = new InterfaceType(inferrer.coreTypes.mapClass,
            <DartType>[inferredKeyType, inferredValueType]);
      }
      for (int i = 0; i < node.entries.length; ++i) {
        MapEntry entry = node.entries[i];
        inferMapEntry(
            entry,
            node,
            inferredKeyType,
            inferredValueType,
            spreadTypeContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        if (inferenceNeeded) {
          formalTypes.add(mapType.typeArguments[0]);
          formalTypes.add(mapType.typeArguments[1]);
        }
      }
      hasMapEntry = mapEntryOffset != null;
      hasMapSpread = mapSpreadOffset != null;
      hasIterableSpread = iterableSpreadOffset != null;
    }
    if (inferenceNeeded) {
      bool canBeSet = !hasMapSpread && !hasMapEntry && !typeContextIsMap;
      bool canBeMap = !hasIterableSpread && !typeContextIsIterable;
      if (canBeSet && !canBeMap) {
        List<Expression> setElements = <Expression>[];
        List<DartType> formalTypesForSet = <DartType>[];
        InterfaceType setType = inferrer.coreTypes.setClass.thisType;
        for (int i = 0; i < node.entries.length; ++i) {
          setElements.add(convertToElement(node.entries[i], inferrer.helper));
          formalTypesForSet.add(setType.typeArguments[0]);
        }

        List<DartType> inferredTypesForSet = <DartType>[const UnknownType()];
        inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
            setType,
            inferrer.coreTypes.setClass.typeParameters,
            null,
            null,
            typeContext,
            inferredTypesForSet,
            isConst: node.isConst);
        inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
            inferrer.coreTypes.setClass.thisType,
            inferrer.coreTypes.setClass.typeParameters,
            formalTypesForSet,
            actualTypesForSet,
            typeContext,
            inferredTypesForSet);
        DartType inferredTypeArgument = inferredTypesForSet[0];
        inferrer.instrumentation?.record(
            inferrer.uri,
            node.fileOffset,
            'typeArgs',
            new InstrumentationValueForTypeArgs([inferredTypeArgument]));

        SetLiteral setLiteral = new SetLiteral(setElements,
            typeArgument: inferredTypeArgument, isConst: node.isConst)
          ..fileOffset = node.fileOffset;
        node.parent.replaceChild(node, setLiteral);
        if (typeChecksNeeded) {
          for (int i = 0; i < setLiteral.expressions.length; i++) {
            checkElement(
                setLiteral.expressions[i],
                setLiteral,
                setLiteral.typeArgument,
                inferredSpreadTypes,
                inferredConditionTypes);
          }
        }

        DartType inferredType =
            new InterfaceType(inferrer.coreTypes.setClass, inferredTypesForSet);
        return new ExpressionInferenceResult(inferredType);
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        node.parent.replaceChild(
            node,
            inferrer.helper.desugarSyntheticExpression(inferrer.helper
                .buildProblem(messageCantDisambiguateNotEnoughInformation,
                    node.fileOffset, 1)));
        return const ExpressionInferenceResult(const BottomType());
      }
      if (!canBeSet && !canBeMap) {
        if (!inferrer.isTopLevel) {
          node.parent.replaceChild(
              node,
              inferrer.helper.desugarSyntheticExpression(inferrer.helper
                  .buildProblem(messageCantDisambiguateAmbiguousInformation,
                      node.fileOffset, 1)));
        }
        return const ExpressionInferenceResult(const BottomType());
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
        checkMapEntry(
            node.entries[i],
            node,
            cachedKeys[i],
            cachedValues[i],
            node.keyType,
            node.valueType,
            inferredSpreadTypes,
            inferredConditionTypes);
      }
    }
    DartType inferredType =
        new InterfaceType(mapClass, [inferredKeyType, inferredValueType]);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      // Either both [_declaredKeyType] and [_declaredValueType] are omitted or
      // none of them, so we may just check one.
      if (inferenceNeeded) {
        library.checkBoundsInMapLiteral(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitMethodInvocation(
      covariant MethodInvocationImpl node, DartType typeContext) {
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
            node.parent.replaceChild(node,
                new DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
            DartType inferredType =
                inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
            return new ExpressionInferenceResult(inferredType);
          }
        }
        Expression error = checkWebIntLiteralsErrorIfUnexact(
            inferrer, receiver.value, receiver.literal, receiver.fileOffset);
        if (error != null) {
          node.parent.replaceChild(node, error);
          return const ExpressionInferenceResult(const BottomType());
        }
      } else if (node.receiver is ShadowLargeIntLiteral) {
        ShadowLargeIntLiteral receiver = node.receiver;
        if (!receiver.isParenthesized) {
          if (inferrer.isDoubleContext(typeContext)) {
            double doubleValue = receiver.asDouble(negated: true);
            if (doubleValue != null) {
              node.parent.replaceChild(node,
                  new DoubleLiteral(doubleValue)..fileOffset = node.fileOffset);
              DartType inferredType = inferrer.coreTypes
                  .doubleRawType(inferrer.library.nonNullable);
              return new ExpressionInferenceResult(inferredType);
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
            return const ExpressionInferenceResult(const BottomType());
          }
          if (intValue != null) {
            Expression error = checkWebIntLiteralsErrorIfUnexact(
                inferrer, intValue, receiver.literal, receiver.fileOffset);
            if (error != null) {
              node.parent.replaceChild(node, error);
              return const ExpressionInferenceResult(const BottomType());
            }
            node.receiver = new IntLiteral(-intValue)
              ..fileOffset = node.receiver.fileOffset
              ..parent = node;
          }
        }
      }
    }
    ExpressionInferenceResult result =
        inferrer.inferMethodInvocation(node, typeContext);
    return new ExpressionInferenceResult(
        result.inferredType, result.replacement);
  }

  ExpressionInferenceResult visitNamedFunctionExpressionJudgment(
      NamedFunctionExpressionJudgment node, DartType typeContext) {
    DartType inferredType = inferrer
        .inferExpression(node.variable.initializer, typeContext, true)
        .inferredType;
    node.variable.type = inferredType;
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitNot(Not node, DartType typeContext) {
    InterfaceType boolType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType inferredType = inferrer
        .inferExpression(node.operand, boolType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        boolType, inferredType, node.operand, node.fileOffset);
    return new ExpressionInferenceResult(boolType);
  }

  ExpressionInferenceResult visitNullAwareMethodInvocation(
      NullAwareMethodInvocation node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult readResult = inferrer.inferExpression(
        node.invocation, typeContext, true,
        isVoidAllowed: true);
    Member equalsMember = inferrer
        .findInterfaceMember(
            node.variable.type, new Name('=='), node.fileOffset)
        .member;

    DartType inferredType = readResult.inferredType;

    Expression replacement;
    MethodInvocation equalsNull = createEqualsNull(
        node.fileOffset,
        new VariableGet(node.variable)..fileOffset = node.fileOffset,
        equalsMember);
    ConditionalExpression condition = new ConditionalExpression(
        equalsNull,
        new NullLiteral()..fileOffset = node.fileOffset,
        node.invocation,
        inferredType);
    node.replaceWith(replacement = new Let(node.variable, condition)
      ..fileOffset = node.fileOffset);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitNullAwarePropertyGet(
      NullAwarePropertyGet node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult readResult =
        inferrer.inferExpression(node.read, const UnknownType(), true);
    Member equalsMember = inferrer
        .findInterfaceMember(
            node.variable.type, new Name('=='), node.fileOffset)
        .member;

    DartType inferredType = readResult.inferredType;

    Expression replacement;
    MethodInvocation equalsNull = createEqualsNull(
        node.fileOffset,
        new VariableGet(node.variable)..fileOffset = node.fileOffset,
        equalsMember);
    ConditionalExpression condition = new ConditionalExpression(
        equalsNull,
        new NullLiteral()..fileOffset = node.fileOffset,
        node.read,
        inferredType);
    node.replaceWith(replacement = new Let(node.variable, condition)
      ..fileOffset = node.fileOffset);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitNullAwarePropertySet(
      NullAwarePropertySet node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult writeResult =
        inferrer.inferExpression(node.write, typeContext, true);
    Member equalsMember = inferrer
        .findInterfaceMember(
            node.variable.type, new Name('=='), node.fileOffset)
        .member;

    DartType inferredType = writeResult.inferredType;

    Expression replacement;
    MethodInvocation equalsNull = createEqualsNull(
        node.fileOffset,
        new VariableGet(node.variable)..fileOffset = node.fileOffset,
        equalsMember);
    ConditionalExpression condition = new ConditionalExpression(
        equalsNull,
        new NullLiteral()..fileOffset = node.fileOffset,
        node.write,
        inferredType);
    node.replaceWith(replacement = new Let(node.variable, condition)
      ..fileOffset = node.fileOffset);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitStaticPostIncDec(
      StaticPostIncDec node, DartType typeContext) {
    inferrer.inferStatement(node.read);
    inferrer.inferStatement(node.write);
    DartType inferredType = node.read.type;
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitLocalPostIncDec(
      LocalPostIncDec node, DartType typeContext) {
    inferrer.inferStatement(node.read);
    inferrer.inferStatement(node.write);
    DartType inferredType = node.read.type;
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitPropertyPostIncDec(
      PropertyPostIncDec node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    inferrer.inferStatement(node.read);
    inferrer.inferStatement(node.write);
    DartType inferredType = node.read.type;
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitCompoundPropertySet(
      CompoundPropertySet node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult writeResult =
        inferrer.inferExpression(node.write, const UnknownType(), true);
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(writeResult.inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullPropertySet(
      IfNullPropertySet node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult readResult =
        inferrer.inferExpression(node.read, const UnknownType(), true);
    ExpressionInferenceResult writeResult =
        inferrer.inferExpression(node.write, const UnknownType(), true);
    Member equalsMember = inferrer
        .findInterfaceMember(
            readResult.inferredType, new Name('=='), node.fileOffset)
        .member;

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(
            readResult.inferredType, writeResult.inferredType);

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.b : null
      //
      MethodInvocation equalsNull =
          createEqualsNull(node.fileOffset, node.read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull,
          node.write,
          new NullLiteral()..fileOffset = node.fileOffset,
          inferredType)
        ..fileOffset = node.fileOffset;
      node.replaceWith(replacement =
          new Let(node.variable, conditional..fileOffset = node.fileOffset));
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.b : v2
      //
      VariableDeclaration readVariable = new VariableDeclaration.forValue(
          node.read,
          type: readResult.inferredType)
        ..fileOffset = node.fileOffset;
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset,
          new VariableGet(readVariable)..fileOffset = node.fileOffset,
          equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, node.write, new VariableGet(readVariable), inferredType)
        ..fileOffset = node.fileOffset;
      node.replaceWith(replacement = new Let(node.variable,
          new Let(readVariable, conditional)..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset);
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIndexSet(IndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        new VariableDeclaration.forValue(node.receiver, type: receiverType)
          ..fileOffset = node.receiver.fileOffset;

    ObjectAccessTarget indexSetTarget = inferrer.findInterfaceMember(
        receiverType, new Name('[]='), node.fileOffset,
        includeExtensionMethods: true);

    DartType indexType = inferrer.getIndexKeyType(indexSetTarget, receiverType);
    DartType valueType =
        inferrer.getIndexSetValueType(indexSetTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    inferrer.ensureAssignable(
        indexType, indexResult.inferredType, node.index, node.index.fileOffset);

    VariableDeclaration indexVariable = new VariableDeclaration.forValue(
        node.index,
        type: indexResult.inferredType)
      ..fileOffset = node.index.fileOffset;

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);
    VariableDeclaration valueVariable = new VariableDeclaration.forValue(
        node.value,
        type: valueResult.inferredType)
      ..fileOffset = node.value.fileOffset;

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression replacement;
    Expression assignment;
    if (indexSetTarget.isMissing) {
      assignment = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments('[]=', receiverType),
          node.fileOffset,
          '[]='.length,
          wrapInSyntheticExpression: false);
    } else if (indexSetTarget.isExtensionMember) {
      assignment = new StaticInvocation(
          indexSetTarget.member,
          new Arguments(<Expression>[
            new VariableGet(receiverVariable)
              ..fileOffset = node.receiver.fileOffset,
            new VariableGet(indexVariable)..fileOffset = node.index.fileOffset,
            new VariableGet(valueVariable)
              ..fileOffset = node.receiver.fileOffset
          ], types: indexSetTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset;
    } else {
      assignment = new MethodInvocation(
          new VariableGet(receiverVariable)
            ..fileOffset = node.receiver.fileOffset,
          new Name('[]='),
          new Arguments(<Expression>[
            new VariableGet(indexVariable)..fileOffset = node.index.fileOffset,
            new VariableGet(valueVariable)
              ..fileOffset = node.receiver.fileOffset
          ])
            ..fileOffset = node.fileOffset,
          indexSetTarget.member)
        ..fileOffset = node.fileOffset;
    }
    VariableDeclaration assignmentVariable =
        new VariableDeclaration.forValue(assignment, type: const VoidType())
          ..fileOffset = assignment.fileOffset;
    node.replaceWith(replacement = new Let(
        receiverVariable,
        new Let(
            indexVariable,
            new Let(
                valueVariable,
                new Let(
                    assignmentVariable,
                    new VariableGet(valueVariable)
                      ..fileOffset = node.fileOffset)
                  ..fileOffset = assignment.fileOffset)
              ..fileOffset = node.index.fileOffset)
          ..fileOffset = node.receiver.fileOffset));
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullIndexSet(
      IfNullIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, new Name('[]'), node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind checkKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readType = inferrer.getReturnType(readTarget, receiverType);
    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, new Name('=='), node.fileOffset)
        .member;

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, new Name('[]='), node.fileOffset,
        includeExtensionMethods: true);

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, receiverType);
    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(readIndexType,
            indexResult.inferredType, readIndex, readIndex.fileOffset) ??
        readIndex;

    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(writeIndexType,
            indexResult.inferredType, writeIndex, writeIndex.fileOffset) ??
        writeIndex;

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    Expression read;

    if (readTarget.isMissing) {
      read = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments('[]', receiverType),
          node.readOffset,
          '[]'.length,
          wrapInSyntheticExpression: false);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    } else {
      read = new MethodInvocation(
          createVariableGet(receiverVariable),
          new Name('[]'),
          new Arguments(<Expression>[
            readIndex,
          ])
            ..fileOffset = node.readOffset,
          readTarget.member)
        ..fileOffset = node.readOffset;

      if (checkKind == MethodContravarianceCheckKind.checkMethodReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(inferrer.uri, node.readOffset,
              'checkReturn', new InstrumentationValueForType(readType));
        }
        read = new AsExpression(read, readType)
          ..isTypeError = true
          ..fileOffset = node.readOffset;
      }
    }

    VariableDeclaration valueVariable;
    Expression valueExpression;
    if (node.forEffect) {
      valueExpression = node.value;
    } else {
      valueVariable = createVariable(node.value, valueResult.inferredType);
      valueExpression = createVariableGet(valueVariable);
    }

    Expression write;

    if (writeTarget.isMissing) {
      write = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments('[]=', receiverType),
          node.fileOffset,
          '[]='.length,
          wrapInSyntheticExpression: false);
    } else if (writeTarget.isExtensionMember) {
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            writeIndex,
            valueExpression
          ], types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset;
    } else {
      write = new MethodInvocation(
          createVariableGet(receiverVariable),
          new Name('[]='),
          new Arguments(<Expression>[writeIndex, valueExpression])
            ..fileOffset = node.fileOffset,
          writeTarget.member)
        ..fileOffset = node.fileOffset;
    }

    Expression replacement;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = o in
      //     let v2 = a in
      //     let v3 = v1[v2] in
      //        v3 == null ? v1.[]=(v2, b) : null
      //
      MethodInvocation equalsNull =
          createEqualsNull(node.fileOffset, read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          write, new NullLiteral()..fileOffset = node.fileOffset, inferredType)
        ..fileOffset = node.fileOffset;
      node.replaceWith(replacement =
          new Let(receiverVariable, createLet(indexVariable, conditional))
            ..fileOffset = node.fileOffset);
    } else {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = o in
      //     let v2 = a in
      //     let v3 = v1[v2] in
      //       v3 == null
      //        ? (let v4 = b in
      //           let _ = v1.[]=(v2, v4) in
      //           v4)
      //        : v3
      //
      assert(valueVariable != null);

      VariableDeclaration readVariable = createVariable(read, readType);
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))),
          createVariableGet(readVariable),
          inferredType)
        ..fileOffset = node.fileOffset;
      node.replaceWith(replacement = new Let(receiverVariable,
          createLet(indexVariable, createLet(readVariable, conditional)))
        ..fileOffset = node.fileOffset);
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitCompoundIndexSet(
      CompoundIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, new Name('[]'), node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind readCheckKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readType = inferrer.getReturnType(readTarget, receiverType);
    DartType readIndexType = inferrer.getPositionalParameterTypeForTarget(
        readTarget, receiverType, 0);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);
    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    Expression readIndex = createVariableGet(indexVariable);
    Expression readIndexReplacement = inferrer.ensureAssignable(readIndexType,
        indexResult.inferredType, readIndex, readIndex.fileOffset);
    if (readIndexReplacement != null) {
      readIndex = readIndexReplacement;
    }

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments('[]', receiverType),
          node.readOffset,
          '[]'.length,
          wrapInSyntheticExpression: false);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    } else {
      read = new MethodInvocation(
          createVariableGet(receiverVariable),
          new Name('[]'),
          new Arguments(<Expression>[
            readIndex,
          ])
            ..fileOffset = node.readOffset,
          readTarget.member)
        ..fileOffset = node.readOffset;
      if (readCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(inferrer.uri, node.readOffset,
              'checkReturn', new InstrumentationValueForType(readType));
        }
        read = new AsExpression(read, readType)
          ..isTypeError = true
          ..fileOffset = node.readOffset;
      }
    }

    VariableDeclaration leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
    } else {
      left = read;
    }

    ObjectAccessTarget binaryTarget = inferrer.findInterfaceMember(
        readType, node.binaryName, node.binaryOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind binaryCheckKind =
        inferrer.preCheckInvocationContravariance(readType, binaryTarget,
            isThisReceiver: false);

    DartType binaryType = inferrer.getReturnType(binaryTarget, readType);
    DartType rhsType =
        inferrer.getPositionalParameterTypeForTarget(binaryTarget, readType, 0);

    ExpressionInferenceResult rhsResult =
        inferrer.inferExpression(node.rhs, rhsType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        rhsType, rhsResult.inferredType, node.rhs, node.rhs.fileOffset);

    if (inferrer.isOverloadedArithmeticOperatorAndType(
        binaryTarget, readType)) {
      binaryType = inferrer.typeSchemaEnvironment
          .getTypeOfOverloadedArithmetic(readType, rhsResult.inferredType);
    }

    Expression binary;
    if (binaryTarget.isMissing) {
      binary = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments(
              node.binaryName.name, receiverType),
          node.binaryOffset,
          node.binaryName.name.length,
          wrapInSyntheticExpression: false);
    } else if (binaryTarget.isExtensionMember) {
      binary = new StaticInvocation(
          binaryTarget.member,
          new Arguments(<Expression>[
            left,
            node.rhs,
          ], types: binaryTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.binaryOffset)
        ..fileOffset = node.binaryOffset;
    } else {
      binary = new MethodInvocation(
          left,
          node.binaryName,
          new Arguments(<Expression>[
            node.rhs,
          ])
            ..fileOffset = node.binaryOffset,
          binaryTarget.member)
        ..fileOffset = node.binaryOffset;

      if (binaryCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(inferrer.uri, node.binaryOffset,
              'checkReturn', new InstrumentationValueForType(readType));
        }
        binary = new AsExpression(binary, binaryType)
          ..isTypeError = true
          ..fileOffset = node.binaryOffset;
      }
    }

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, new Name('[]='), node.writeOffset,
        includeExtensionMethods: true);

    DartType writeIndexType = inferrer.getPositionalParameterTypeForTarget(
        writeTarget, receiverType, 0);
    Expression writeIndex = createVariableGet(indexVariable);
    Expression writeIndexReplacement = inferrer.ensureAssignable(writeIndexType,
        indexResult.inferredType, writeIndex, writeIndex.fileOffset);
    if (writeIndexReplacement != null) {
      writeIndex = writeIndexReplacement;
    }

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, receiverType);
    Expression binaryReplacement = inferrer.ensureAssignable(
        valueType, binaryType, binary, node.fileOffset);
    if (binaryReplacement != null) {
      binary = binaryReplacement;
    }

    Expression replacement;

    VariableDeclaration valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = createVariable(binary, binaryType);
      valueExpression = createVariableGet(valueVariable);
    }

    Expression write;

    if (writeTarget.isMissing) {
      write = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments('[]=', receiverType),
          node.writeOffset,
          '[]='.length,
          wrapInSyntheticExpression: false);
    } else if (writeTarget.isExtensionMember) {
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            writeIndex,
            valueExpression
          ], types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    } else {
      write = new MethodInvocation(
          createVariableGet(receiverVariable),
          new Name('[]='),
          new Arguments(<Expression>[writeIndex, valueExpression])
            ..fileOffset = node.writeOffset,
          writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `o[a] += b` as:
      //
      //     let v1 = o in let v2 = a in v1.[]=(v2, v1.[](v2) + b)
      //
      node.replaceWith(replacement =
          new Let(receiverVariable, createLet(indexVariable, write))
            ..fileOffset = node.fileOffset);
    } else if (node.forPostIncDec) {
      // Encode `o[a]++` as:
      //
      //     let v1 = o in
      //     let v2 = a in
      //     let v3 = v1.[](v2)
      //     let v4 = v1.[]=(v2, c3 + b) in v3
      //
      assert(leftVariable != null);
      assert(valueVariable == null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      node.replaceWith(replacement = new Let(
          receiverVariable,
          createLet(
              indexVariable,
              createLet(leftVariable,
                  createLet(writeVariable, createVariableGet(leftVariable)))))
        ..fileOffset = node.fileOffset);
    } else {
      // Encode `o[a] += b` as:
      //
      //     let v1 = o in
      //     let v2 = a in
      //     let v3 = v1.[](v2) + b
      //     let v4 = v1.[]=(v2, c3) in v3
      //
      assert(leftVariable == null);
      assert(valueVariable != null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      node.replaceWith(replacement = new Let(
          receiverVariable,
          createLet(
              indexVariable,
              createLet(valueVariable,
                  createLet(writeVariable, createVariableGet(valueVariable)))))
        ..fileOffset = node.fileOffset);
    }
    return new ExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType, replacement);
  }

  @override
  ExpressionInferenceResult visitNullLiteral(
      NullLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(inferrer.coreTypes.nullType);
  }

  @override
  ExpressionInferenceResult visitLet(Let node, DartType typeContext) {
    DartType variableType = node.variable.type;
    if (variableType == const DynamicType()) {
      return defaultExpression(node, typeContext);
    }
    inferrer.inferExpression(node.variable.initializer, variableType, true,
        isVoidAllowed: true);
    ExpressionInferenceResult result = inferrer
        .inferExpression(node.body, typeContext, true, isVoidAllowed: true);
    DartType inferredType = result.inferredType;
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitPropertySet(
      PropertySet node, DartType typeContext) {
    DartType receiverType;
    if (node.receiver != null) {
      receiverType = inferrer
          .inferExpression(node.receiver, const UnknownType(), true)
          .inferredType;
    } else {
      receiverType = inferrer.thisType;
    }
    ObjectAccessTarget target =
        inferrer.findPropertySetMember(receiverType, node);
    DartType writeContext = inferrer.getSetterType(target, receiverType);
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(
        node.value, writeContext ?? const UnknownType(), true,
        isVoidAllowed: true);
    DartType rhsType = rhsResult.inferredType;
    inferrer.ensureAssignable(
        writeContext, rhsType, node.value, node.fileOffset,
        isVoidAllowed: writeContext is VoidType);
    Expression replacement;
    if (target.isExtensionMember) {
      node.parent.replaceChild(
          node,
          replacement = inferrer.helper.forest.createStaticInvocation(
              node.fileOffset,
              target.member,
              inferrer.helper.forest.createArgumentsForExtensionMethod(
                  node.fileOffset,
                  target.inferredExtensionTypeArguments.length,
                  0,
                  node.receiver,
                  extensionTypeArguments: target.inferredExtensionTypeArguments,
                  positionalArguments: [node.value])));
    }
    return new ExpressionInferenceResult(rhsType, replacement);
  }

  ExpressionInferenceResult visitPropertyAssignmentJudgment(
      PropertyAssignmentJudgment node, DartType typeContext) {
    DartType receiverType = node._inferReceiver(inferrer);

    DartType readType;
    if (node.read != null) {
      ObjectAccessTarget readTarget = inferrer
          .findPropertyGetMember(receiverType, node.read, instrumented: false);
      readType = inferrer.getGetterType(readTarget, receiverType);
      inferrer.handlePropertyGetContravariance(
          node.receiver,
          readTarget,
          node.read is PropertyGet ? node.read : null,
          node.read,
          readType,
          node.read.fileOffset);
      node._storeLetType(inferrer, node.read, readType);
    }
    ObjectAccessTarget writeTarget;
    if (node.write != null) {
      writeTarget = node._handleWriteContravariance(inferrer, receiverType);
    }
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member when
    // doing compound assignment?
    DartType writeContext = inferrer.getSetterType(writeTarget, receiverType);
    DartType inferredType =
        node._inferRhs(inferrer, readType, writeContext).inferredType;
    node.nullAwareGuard?.staticType = inferredType;
    Expression replacement;
    if (writeTarget.isExtensionMember) {
      node.parent.replaceChild(
          node,
          replacement = inferrer.helper.forest.createStaticInvocation(
              node.fileOffset,
              writeTarget.member,
              inferrer.helper.forest.createArgumentsForExtensionMethod(
                  node.fileOffset,
                  writeTarget.inferredExtensionTypeArguments.length,
                  0,
                  node.receiver,
                  extensionTypeArguments:
                      writeTarget.inferredExtensionTypeArguments,
                  positionalArguments: [node.rhs])));
    } else {
      node._replaceWithDesugared();
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitPropertyGet(
      PropertyGet node, DartType typeContext) {
    return inferrer.inferPropertyGet(
        node, node.receiver, node.fileOffset, typeContext, node);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    List<DartType> typeArguments =
        new List<DartType>(classTypeParameters.length);
    for (int i = 0; i < typeArguments.length; i++) {
      typeArguments[i] = new TypeParameterType(classTypeParameters[i]);
    }
    ArgumentsImpl.setNonInferrableArgumentTypes(node.arguments, typeArguments);
    inferrer.inferInvocation(
        null,
        node.fileOffset,
        node.target.function.thisFunctionType,
        node.target.enclosingClass.thisType,
        node.arguments,
        skipTypeArgumentInference: true);
    ArgumentsImpl.removeNonInferrableArgumentTypes(node.arguments);
  }

  @override
  ExpressionInferenceResult visitRethrow(Rethrow node, DartType typeContext) {
    return const ExpressionInferenceResult(const BottomType());
  }

  @override
  void visitReturnStatement(covariant ReturnStatementImpl node) {
    ClosureContext closureContext = inferrer.closureContext;
    DartType typeContext = !closureContext.isGenerator
        ? closureContext.returnOrYieldContext
        : const UnknownType();
    DartType inferredType;
    if (node.expression != null) {
      inferredType = inferrer
          .inferExpression(node.expression, typeContext, true,
              isVoidAllowed: true)
          .inferredType;
    } else {
      inferredType = inferrer.coreTypes.nullType;
    }
    closureContext.handleReturn(inferrer, node, inferredType, node.isArrow);
  }

  @override
  ExpressionInferenceResult visitSetLiteral(
      SetLiteral node, DartType typeContext) {
    Class setClass = inferrer.coreTypes.setClass;
    InterfaceType setType = setClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    Map<TreeNode, DartType> inferredSpreadTypes;
    Map<Expression, DartType> inferredConditionTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
      inferredSpreadTypes = new Map<TreeNode, DartType>.identity();
      inferredConditionTypes = new Map<Expression, DartType>.identity();
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
    if (inferenceNeeded || typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; ++i) {
        DartType type = inferElement(
            node.expressions[i],
            node,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        actualTypes.add(type);
        if (inferenceNeeded) {
          formalTypes.add(setType.typeArguments[0]);
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
        checkElement(node.expressions[i], node, node.typeArgument,
            inferredSpreadTypes, inferredConditionTypes);
      }
    }
    DartType inferredType = new InterfaceType(setClass, [inferredTypeArgument]);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (inferenceNeeded) {
        library.checkBoundsInSetLiteral(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }

      if (!library.loader.target.backendTarget.supportsSetLiterals) {
        inferrer.helper.transformSetLiterals = true;
      }
    }
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitStaticSet(
      StaticSet node, DartType typeContext) {
    Member writeMember = node.target;
    DartType writeContext = writeMember.setterType;
    TypeInferenceEngine.resolveInferenceNode(writeMember);
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(
        node.value, writeContext ?? const UnknownType(), true,
        isVoidAllowed: true);
    DartType rhsType = rhsResult.inferredType;
    inferrer.ensureAssignable(
        writeContext, rhsType, node.value, node.fileOffset,
        isVoidAllowed: writeContext is VoidType);
    return new ExpressionInferenceResult(rhsType);
  }

  ExpressionInferenceResult visitStaticAssignmentJudgment(
      StaticAssignmentJudgment node, DartType typeContext) {
    DartType readType = const DynamicType(); // Only used in error recovery
    Expression read = node.read;
    if (read is StaticGet) {
      readType = read.target.getterType;
      node._storeLetType(inferrer, read, readType);
    }
    Member writeMember;
    DartType writeContext = const UnknownType();
    Expression write = node.write;
    if (write is StaticSet) {
      writeContext = write.target.setterType;
      writeMember = write.target;
      TypeInferenceEngine.resolveInferenceNode(writeMember);
    }
    DartType inferredType =
        node._inferRhs(inferrer, readType, writeContext).inferredType;
    node._replaceWithDesugared();
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitStaticGet(
      StaticGet node, DartType typeContext) {
    Member target = node.target;
    TypeInferenceEngine.resolveInferenceNode(target);
    DartType type = target.getterType;
    if (target is Procedure && target.kind == ProcedureKind.Method) {
      type = inferrer.instantiateTearOff(type, typeContext, node);
    }
    return new ExpressionInferenceResult(type);
  }

  @override
  ExpressionInferenceResult visitStaticInvocation(
      StaticInvocation node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.functionType
        : new FunctionType([], const DynamicType());
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    DartType inferredType = inferrer.inferInvocation(typeContext,
        node.fileOffset, calleeType, calleeType.returnType, node.arguments);
    if (!inferrer.isTopLevel &&
        !hadExplicitTypeArguments &&
        node.target != null) {
      inferrer.library.checkBoundsInStaticInvocation(
          node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
          inferred: true);
    }
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitStringConcatenation(
      StringConcatenation node, DartType typeContext) {
    if (!inferrer.isTopLevel) {
      for (Expression expression in node.expressions) {
        inferrer.inferExpression(
            expression, const UnknownType(), !inferrer.isTopLevel);
      }
    }
    return new ExpressionInferenceResult(
        inferrer.coreTypes.stringRawType(inferrer.library.nonNullable));
  }

  @override
  ExpressionInferenceResult visitStringLiteral(
      StringLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.stringRawType(inferrer.library.nonNullable));
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    Substitution substitution = Substitution.fromSupertype(
        inferrer.classHierarchy.getClassAsInstanceOf(
            inferrer.thisType.classNode, node.target.enclosingClass));
    inferrer.inferInvocation(
        null,
        node.fileOffset,
        substitution.substituteType(
            node.target.function.thisFunctionType.withoutTypeParameters),
        inferrer.thisType,
        node.arguments,
        skipTypeArgumentInference: true);
  }

  @override
  ExpressionInferenceResult visitSuperMethodInvocation(
      SuperMethodInvocation node, DartType typeContext) {
    if (node.interfaceTarget != null) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset, 'target',
          new InstrumentationValueForMember(node.interfaceTarget));
    }
    ExpressionInferenceResult result = inferrer.inferSuperMethodInvocation(
        node,
        typeContext,
        node.interfaceTarget != null
            ? new ObjectAccessTarget.interfaceMember(node.interfaceTarget)
            : const ObjectAccessTarget.unresolved());
    return new ExpressionInferenceResult(result.inferredType);
  }

  @override
  ExpressionInferenceResult visitSuperPropertyGet(
      SuperPropertyGet node, DartType typeContext) {
    if (node.interfaceTarget != null) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset, 'target',
          new InstrumentationValueForMember(node.interfaceTarget));
    }
    return inferrer.inferSuperPropertyGet(
        node,
        typeContext,
        node.interfaceTarget != null
            ? new ObjectAccessTarget.interfaceMember(node.interfaceTarget)
            : const ObjectAccessTarget.unresolved());
  }

  @override
  ExpressionInferenceResult visitSuperPropertySet(
      SuperPropertySet node, DartType typeContext) {
    DartType receiverType = inferrer.classHierarchy.getTypeAsInstanceOf(
        inferrer.thisType, inferrer.thisType.classNode.supertype.classNode);

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.name, node.fileOffset,
        setter: true, instrumented: true);
    if (writeTarget.isInstanceMember) {
      node.interfaceTarget = writeTarget.member;
    }
    DartType writeContext = inferrer.getSetterType(writeTarget, receiverType);
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(
        node.value, writeContext ?? const UnknownType(), true,
        isVoidAllowed: true);
    DartType rhsType = rhsResult.inferredType;
    inferrer.ensureAssignable(
        writeContext, rhsType, node.value, node.fileOffset,
        isVoidAllowed: writeContext is VoidType);

    return new ExpressionInferenceResult(rhsType);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    DartType expressionType = inferrer
        .inferExpression(node.expression, const UnknownType(), true)
        .inferredType;

    for (SwitchCase switchCase in node.cases) {
      for (Expression caseExpression in switchCase.expressions) {
        ExpressionInferenceResult caseExpressionResult =
            inferrer.inferExpression(caseExpression, expressionType, true);
        if (caseExpressionResult.replacement != null) {
          caseExpression = caseExpressionResult.replacement;
        }
        DartType caseExpressionType = caseExpressionResult.inferredType;

        // Check whether the expression type is assignable to the case
        // expression type.
        if (!inferrer.isAssignable(expressionType, caseExpressionType)) {
          inferrer.helper.addProblem(
              templateSwitchExpressionNotAssignable.withArguments(
                  expressionType, caseExpressionType),
              caseExpression.fileOffset,
              noLength,
              context: [
                messageSwitchExpressionNotAssignableCause.withLocation(
                    inferrer.uri, node.expression.fileOffset, noLength)
              ]);
        }
      }
      inferrer.inferStatement(switchCase.body);
    }
  }

  @override
  ExpressionInferenceResult visitSymbolLiteral(
      SymbolLiteral node, DartType typeContext) {
    DartType inferredType =
        inferrer.coreTypes.symbolRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitInvalidConstructorInvocationJudgment(
      InvalidConstructorInvocationJudgment node, DartType typeContext) {
    FunctionType calleeType;
    DartType returnType;
    if (node.constructor != null) {
      calleeType = node.constructor.function.thisFunctionType;
      returnType = computeConstructorReturnType(node.constructor);
    } else {
      calleeType = new FunctionType([], const DynamicType());
      returnType = const DynamicType();
    }
    DartType inferredType = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, returnType, node.arguments);
    node._replaceWithDesugared();
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitInvalidWriteJudgment(
      InvalidWriteJudgment node, DartType typeContext) {
    // When a compound assignment, the expression is already wrapping in
    // VariableDeclaration in _makeRead(). Otherwise, temporary associate
    // the expression with this node.
    node.expression.parent ??= node;

    inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel);
    return visitSyntheticExpressionJudgment(node, typeContext);
  }

  ExpressionInferenceResult visitSyntheticExpressionJudgment(
      SyntheticExpressionJudgment node, DartType typeContext) {
    node._replaceWithDesugared();
    return const ExpressionInferenceResult(const DynamicType());
  }

  ExpressionInferenceResult visitThisExpression(
      ThisExpression node, DartType typeContext) {
    return new ExpressionInferenceResult(inferrer.thisType);
  }

  @override
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel);
    return const ExpressionInferenceResult(const BottomType());
  }

  void visitCatch(Catch node) {
    inferrer.inferStatement(node.body);
  }

  @override
  void visitTryCatch(TryCatch node) {
    inferrer.inferStatement(node.body);
    for (Catch catch_ in node.catches) {
      visitCatch(catch_);
    }
  }

  @override
  void visitTryFinally(TryFinally node) {
    inferrer.inferStatement(node.body);
    inferrer.inferStatement(node.finalizer);
  }

  @override
  ExpressionInferenceResult visitTypeLiteral(
      TypeLiteral node, DartType typeContext) {
    DartType inferredType =
        inferrer.coreTypes.typeRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitVariableSet(
      VariableSet node, DartType typeContext) {
    DartType writeContext = node.variable.type;
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(
        node.value, writeContext ?? const UnknownType(), true,
        isVoidAllowed: true);
    DartType rhsType = rhsResult.inferredType;
    inferrer.ensureAssignable(
        writeContext, rhsType, node.value, node.fileOffset,
        isVoidAllowed: writeContext is VoidType);
    return new ExpressionInferenceResult(rhsType);
  }

  ExpressionInferenceResult visitVariableAssignmentJudgment(
      VariableAssignmentJudgment node, DartType typeContext) {
    DartType readType;
    Expression read = node.read;
    if (read is VariableGet) {
      readType = read.promotedType ?? read.variable.type;
    }
    DartType writeContext = const UnknownType();
    Expression write = node.write;
    if (write is VariableSet) {
      writeContext = write.variable.type;
      if (read != null) {
        node._storeLetType(inferrer, read, writeContext);
      }
    }
    DartType inferredType =
        node._inferRhs(inferrer, readType, writeContext).inferredType;
    node._replaceWithDesugared();
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    DartType declaredType =
        node._implicitlyTyped ? const UnknownType() : node.type;
    DartType inferredType;
    DartType initializerType;
    if (node.initializer != null) {
      ExpressionInferenceResult initializerResult = inferrer.inferExpression(
          node.initializer,
          declaredType,
          !inferrer.isTopLevel || node._implicitlyTyped,
          isVoidAllowed: true);
      initializerType = initializerResult.inferredType;
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
      Expression replacedInitializer = inferrer.ensureAssignable(
          node.type, initializerType, node.initializer, node.fileOffset,
          isVoidAllowed: node.type is VoidType);
      if (replacedInitializer != null) {
        node.initializer = replacedInitializer;
      }
    }
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (node._implicitlyTyped) {
        library.checkBoundsInVariableDeclaration(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
  }

  ExpressionInferenceResult visitUnresolvedTargetInvocationJudgment(
      UnresolvedTargetInvocationJudgment node, DartType typeContext) {
    ExpressionInferenceResult result =
        visitSyntheticExpressionJudgment(node, typeContext);
    inferrer.inferInvocation(
        typeContext,
        node.fileOffset,
        TypeInferrerImpl.unknownFunction,
        const DynamicType(),
        node.argumentsJudgment);
    return result;
  }

  ExpressionInferenceResult visitUnresolvedVariableAssignmentJudgment(
      UnresolvedVariableAssignmentJudgment node, DartType typeContext) {
    DartType rhsType = inferrer
        .inferExpression(node.rhs, const UnknownType(), true)
        .inferredType;
    DartType inferredType = node.isCompound ? const DynamicType() : rhsType;
    node._replaceWithDesugared();
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitVariableGet(
      covariant VariableGetImpl node, DartType typeContext) {
    VariableDeclarationImpl variable = node.variable;
    bool mutatedInClosure = variable._mutatedInClosure;
    DartType declaredOrInferredType = variable.type;

    DartType promotedType = inferrer.typePromoter
        .computePromotedType(node._fact, node._scope, mutatedInClosure);
    if (promotedType != null) {
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset,
          'promotedType', new InstrumentationValueForType(promotedType));
    }
    node.promotedType = promotedType;
    DartType type = promotedType ?? declaredOrInferredType;
    if (variable._isLocalFunction) {
      type = inferrer.instantiateTearOff(type, typeContext, node);
    }
    return new ExpressionInferenceResult(type);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType conditionType = inferrer
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel)
        .inferredType;
    inferrer.ensureAssignable(
        expectedType, conditionType, node.condition, node.condition.fileOffset);
    inferrer.inferStatement(node.body);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    ClosureContext closureContext = inferrer.closureContext;
    DartType inferredType;
    if (closureContext.isGenerator) {
      DartType typeContext = closureContext.returnOrYieldContext;
      if (node.isYieldStar && typeContext != null) {
        typeContext = inferrer.wrapType(
            typeContext,
            closureContext.isAsync
                ? inferrer.coreTypes.streamClass
                : inferrer.coreTypes.iterableClass);
      }
      inferredType = inferrer
          .inferExpression(node.expression, typeContext, true)
          .inferredType;
    } else {
      inferredType = inferrer
          .inferExpression(node.expression, const UnknownType(), true)
          .inferredType;
    }
    closureContext.handleYield(inferrer, node.isYieldStar, inferredType,
        node.expression, node.fileOffset);
  }

  @override
  ExpressionInferenceResult visitLoadLibrary(
      covariant LoadLibraryImpl node, DartType typeContext) {
    DartType inferredType =
        inferrer.typeSchemaEnvironment.futureType(const DynamicType());
    if (node.arguments != null) {
      FunctionType calleeType = new FunctionType([], inferredType);
      inferrer.inferInvocation(typeContext, node.fileOffset, calleeType,
          calleeType.returnType, node.arguments);
    }
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitLoadLibraryTearOff(
      LoadLibraryTearOff node, DartType typeContext) {
    DartType inferredType = new FunctionType(
        [], inferrer.typeSchemaEnvironment.futureType(const DynamicType()));
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, DartType typeContext) {
    // TODO(dmitryas): Figure out the suitable nullability for that.
    return new ExpressionInferenceResult(
        inferrer.coreTypes.objectRawType(inferrer.library.nullable));
  }
}
