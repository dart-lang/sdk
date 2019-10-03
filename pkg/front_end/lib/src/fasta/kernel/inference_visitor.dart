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
        case InternalExpressionKind.CompoundExtensionIndexSet:
          return visitCompoundExtensionIndexSet(node, typeContext);
        case InternalExpressionKind.CompoundIndexSet:
          return visitCompoundIndexSet(node, typeContext);
        case InternalExpressionKind.CompoundPropertySet:
          return visitCompoundPropertySet(node, typeContext);
        case InternalExpressionKind.CompoundSuperIndexSet:
          return visitCompoundSuperIndexSet(node, typeContext);
        case InternalExpressionKind.DeferredCheck:
          return visitDeferredCheck(node, typeContext);
        case InternalExpressionKind.ExtensionIndexSet:
          return visitExtensionIndexSet(node, typeContext);
        case InternalExpressionKind.ExtensionTearOff:
          return visitExtensionTearOff(node, typeContext);
        case InternalExpressionKind.ExtensionSet:
          return visitExtensionSet(node, typeContext);
        case InternalExpressionKind.IfNull:
          return visitIfNull(node, typeContext);
        case InternalExpressionKind.IfNullExtensionIndexSet:
          return visitIfNullExtensionIndexSet(node, typeContext);
        case InternalExpressionKind.IfNullIndexSet:
          return visitIfNullIndexSet(node, typeContext);
        case InternalExpressionKind.IfNullPropertySet:
          return visitIfNullPropertySet(node, typeContext);
        case InternalExpressionKind.IfNullSet:
          return visitIfNullSet(node, typeContext);
        case InternalExpressionKind.IfNullSuperIndexSet:
          return visitIfNullSuperIndexSet(node, typeContext);
        case InternalExpressionKind.IndexSet:
          return visitIndexSet(node, typeContext);
        case InternalExpressionKind.LoadLibraryTearOff:
          return visitLoadLibraryTearOff(node, typeContext);
        case InternalExpressionKind.LocalPostIncDec:
          return visitLocalPostIncDec(node, typeContext);
        case InternalExpressionKind.NullAwareCompoundSet:
          return visitNullAwareCompoundSet(node, typeContext);
        case InternalExpressionKind.NullAwareExtension:
          return visitNullAwareExtension(node, typeContext);
        case InternalExpressionKind.NullAwareIfNullSet:
          return visitNullAwareIfNullSet(node, typeContext);
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
        case InternalExpressionKind.SuperIndexSet:
          return visitSuperIndexSet(node, typeContext);
        case InternalExpressionKind.SuperPostIncDec:
          return visitSuperPostIncDec(node, typeContext);
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
    // TODO(johnniwinther): The inferred type should be an InvalidType. Using
    // BottomType leads to cascading errors so we use DynamicType for now.
    return const ExpressionInferenceResult(const DynamicType());
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
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel,
            isVoidAllowed: true)
        .inferredType;
    inferrer.ensureAssignable(
        expectedType, conditionType, node.condition, node.condition.fileOffset);
    if (node.message != null) {
      inferrer.inferExpression(
          node.message, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
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
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.expression, typeContext, true,
        isVoidAllowed: false);
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
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel,
            isVoidAllowed: true)
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
    DartType inferredType = inferrer.inferInvocation(typeContext,
        node.fileOffset, node.target.function.thisFunctionType, node.arguments,
        returnType: computeConstructorReturnType(node.target),
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

  ExpressionInferenceResult visitExtensionTearOff(
      ExtensionTearOff node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.functionType
        : new FunctionType([], const DynamicType());
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    DartType inferredType = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments);
    Expression replacement = new StaticInvocation(node.target, node.arguments);
    if (!inferrer.isTopLevel &&
        !hadExplicitTypeArguments &&
        node.target != null) {
      inferrer.library.checkBoundsInStaticInvocation(
          replacement, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
          inferred: true);
    }
    node.replaceWith(replacement);
    inferredType =
        inferrer.instantiateTearOff(inferredType, typeContext, replacement);
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitExtensionSet(
      ExtensionSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments =
        inferrer.computeExtensionTypeArgument(node.extension,
            node.explicitTypeArguments, receiverResult.inferredType);

    DartType receiverType = inferrer.getExtensionReceiverType(
        node.extension, extensionTypeArguments);

    inferrer.ensureAssignable(receiverType, receiverResult.inferredType,
        node.receiver, node.receiver.fileOffset);

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.target, null, ProcedureKind.Setter, extensionTypeArguments);

    DartType valueType =
        inferrer.getSetterType(target, receiverResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer.inferExpression(
        node.value, const UnknownType(), true,
        isVoidAllowed: false);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);

    Expression value;
    VariableDeclaration valueVariable;
    if (node.forEffect) {
      value = node.value;
    } else {
      valueVariable = createVariable(node.value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    VariableDeclaration receiverVariable;
    Expression receiver;
    if (node.forEffect || node.readOnlyReceiver) {
      receiver = node.receiver;
    } else {
      receiverVariable =
          createVariable(node.receiver, receiverResult.inferredType);
      receiver = createVariableGet(receiverVariable);
    }
    Expression assignment = new StaticInvocation(
        node.target,
        new Arguments(<Expression>[receiver, value],
            types: extensionTypeArguments)
          ..fileOffset = node.fileOffset)
      ..fileOffset = node.fileOffset;

    Expression replacement;
    if (node.forEffect) {
      assert(receiverVariable == null);
      assert(valueVariable == null);
      replacement = assignment;
    } else {
      assert(valueVariable != null);
      VariableDeclaration assignmentVariable =
          createVariable(assignment, const VoidType());
      replacement = createLet(valueVariable,
          createLet(assignmentVariable, createVariableGet(valueVariable)));
      if (receiverVariable != null) {
        replacement = createLet(receiverVariable, replacement);
      }
    }
    replacement.fileOffset = node.fileOffset;
    node.replaceWith(replacement);
    return new ExpressionInferenceResult(valueResult.inferredType, replacement);
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
        .inferExpression(node.condition, boolType, !inferrer.isTopLevel,
            isVoidAllowed: true)
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
    DartType inferredType = inferrer.inferInvocation(typeContext,
        node.fileOffset, node.target.function.thisFunctionType, node.arguments,
        returnType: computeConstructorReturnType(node.target),
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
    ExpressionInferenceResult iterableResult = inferrer
        .inferExpression(iterable, context, typeNeeded, isVoidAllowed: false);
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
    Expression rhs;
    // If `true`, the synthetic statement should not be visited.
    bool skipStatement = false;
    ExpressionStatement syntheticStatement =
        body is Block ? body.statements.first : body;
    Expression statementExpression = syntheticStatement.expression;
    Expression syntheticAssignment = statementExpression;
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
          .inferExpression(node.condition, expectedType, !inferrer.isTopLevel,
              isVoidAllowed: true)
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
        node.argumentsJudgment,
        returnType: inferrer.thisType,
        skipTypeArgumentInference: true);
  }

  ExpressionInferenceResult visitIfNull(
      IfNullExpression node, DartType typeContext) {
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    DartType lhsType = inferrer
        .inferExpression(node.left, typeContext, true, isVoidAllowed: false)
        .inferredType;

    Member equalsMember = inferrer
        .findInterfaceMember(lhsType, equalsName, node.fileOffset)
        .member;

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
    VariableDeclaration variable = createVariable(node.left, lhsType);
    MethodInvocation equalsNull = createEqualsNull(
        node.left.fileOffset, createVariableGet(variable), equalsMember);
    ConditionalExpression conditional = new ConditionalExpression(
        equalsNull, node.right, createVariableGet(variable), inferredType);
    Expression replacement = new Let(variable, conditional)
      ..fileOffset = node.fileOffset;
    node.replaceWith(replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  void visitIfStatement(IfStatement node) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    DartType conditionType = inferrer
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel,
            isVoidAllowed: true)
        .inferredType;
    inferrer.ensureAssignable(
        expectedType, conditionType, node.condition, node.condition.fileOffset);
    inferrer.inferStatement(node.then);
    if (node.otherwise != null) {
      inferrer.inferStatement(node.otherwise);
    }
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
      Expression replacement = inferrer.helper.buildProblem(
          templateIntegerLiteralIsOutOfRange.withArguments(node.literal),
          node.fileOffset,
          node.literal.length);
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
        node.variable.initializer, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: false);
  }

  void visitShadowInvalidFieldInitializer(ShadowInvalidFieldInitializer node) {
    inferrer.inferExpression(node.value, node.field.type, !inferrer.isTopLevel,
        isVoidAllowed: false);
  }

  @override
  ExpressionInferenceResult visitIsExpression(
      IsExpression node, DartType typeContext) {
    inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: false);
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
                inferrer.helper.buildProblem(messageNonNullAwareSpreadIsNull,
                    element.expression.fileOffset, 1));
          } else {
            parent.replaceChild(
                element,
                inferrer.helper.buildProblem(
                    templateSpreadTypeMismatch.withArguments(spreadType),
                    element.expression.fileOffset,
                    1));
          }
        } else if (spreadType is InterfaceType) {
          if (!inferrer.isAssignable(inferredTypeArgument, spreadElementType)) {
            parent.replaceChild(
                element,
                inferrer.helper.buildProblem(
                    templateSpreadElementTypeMismatch.withArguments(
                        spreadElementType, inferredTypeArgument),
                    element.expression.fileOffset,
                    1));
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
        .inferExpression(node.left, boolType, !inferrer.isTopLevel,
            isVoidAllowed: false)
        .inferredType;
    DartType rightType = inferrer
        .inferExpression(node.right, boolType, !inferrer.isTopLevel,
            isVoidAllowed: false)
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
                    inferrer.helper.buildProblem(
                        messageNonNullAwareSpreadIsNull,
                        entry.expression.fileOffset,
                        1),
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
                    inferrer.helper.buildProblem(
                        templateSpreadMapEntryTypeMismatch
                            .withArguments(spreadType),
                        entry.expression.fileOffset,
                        1),
                    new NullLiteral())
                  ..fileOffset = entry.fileOffset);
          }
        } else if (spreadType is InterfaceType) {
          Expression keyError;
          Expression valueError;
          if (!inferrer.isAssignable(inferredKeyType, actualKeyType)) {
            keyError = inferrer.helper.buildProblem(
                templateSpreadMapEntryElementKeyTypeMismatch.withArguments(
                    actualKeyType, inferredKeyType),
                entry.expression.fileOffset,
                1);
          }
          if (!inferrer.isAssignable(inferredValueType, actualValueType)) {
            valueError = inferrer.helper.buildProblem(
                templateSpreadMapEntryElementValueTypeMismatch.withArguments(
                    actualValueType, inferredValueType),
                entry.expression.fileOffset,
                1);
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
          spreadType,
          inferrer.coreTypes.mapRawType(inferrer.library.nullable),
          SubtypeCheckMode.ignoringNullabilities);
      bool isIterable = inferrer.typeSchemaEnvironment.isSubtypeOf(
          spreadType,
          inferrer.coreTypes.iterableRawType(inferrer.library.nullable),
          SubtypeCheckMode.ignoringNullabilities);
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
              inferrer.helper.buildProblem(
                  templateSpreadMapEntryTypeMismatch
                      .withArguments(iterableSpreadType),
                  iterableSpreadOffset,
                  1),
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
            inferrer.helper.buildProblem(
                messageCantDisambiguateNotEnoughInformation,
                node.fileOffset,
                1));
        return const ExpressionInferenceResult(const BottomType());
      }
      if (!canBeSet && !canBeMap) {
        if (!inferrer.isTopLevel) {
          node.parent.replaceChild(
              node,
              inferrer.helper.buildProblem(
                  messageCantDisambiguateAmbiguousInformation,
                  node.fileOffset,
                  1));
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
            Expression error = inferrer.helper.buildProblem(
                templateIntegerLiteralIsOutOfRange
                    .withArguments(receiver.literal),
                receiver.fileOffset,
                receiver.literal.length);
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

  @override
  ExpressionInferenceResult visitNullCheck(
      NullCheck node, DartType typeContext) {
    // TODO(johnniwinther): Should the typeContext for the operand be
    //  `Nullable(typeContext)`?
    DartType inferredType = inferrer
        .inferExpression(node.operand, typeContext, !inferrer.isTopLevel)
        .inferredType;
    // TODO(johnniwinther): Check that the inferred type is potentially
    //  nullable.
    // TODO(johnniwinther): Return `NonNull(inferredType)`.
    return new ExpressionInferenceResult(inferredType);
  }

  ExpressionInferenceResult visitNullAwareMethodInvocation(
      NullAwareMethodInvocation node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult readResult = inferrer.inferExpression(
        node.invocation, typeContext, true,
        isVoidAllowed: true);
    Member equalsMember = inferrer
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
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
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
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
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
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

  ExpressionInferenceResult visitNullAwareExtension(
      NullAwareExtension node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult expressionResult =
        inferrer.inferExpression(node.expression, const UnknownType(), true);
    Member equalsMember = inferrer
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
        .member;

    DartType inferredType = expressionResult.inferredType;

    Expression replacement;
    MethodInvocation equalsNull = createEqualsNull(
        node.fileOffset,
        new VariableGet(node.variable)..fileOffset = node.fileOffset,
        equalsMember);
    ConditionalExpression condition = new ConditionalExpression(
        equalsNull,
        new NullLiteral()..fileOffset = node.fileOffset,
        node.expression,
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

  ExpressionInferenceResult visitSuperPostIncDec(
      SuperPostIncDec node, DartType typeContext) {
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
    ExpressionInferenceResult writeResult = inferrer
        .inferExpression(node.write, typeContext, true, isVoidAllowed: true);
    Expression replacement = node.replace();
    return new ExpressionInferenceResult(writeResult.inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullPropertySet(
      IfNullPropertySet node, DartType typeContext) {
    inferrer.inferStatement(node.variable);
    ExpressionInferenceResult readResult = inferrer.inferExpression(
        node.read, const UnknownType(), true,
        isVoidAllowed: true);
    ExpressionInferenceResult writeResult = inferrer
        .inferExpression(node.write, typeContext, true, isVoidAllowed: true);
    Member equalsMember = inferrer
        .findInterfaceMember(
            readResult.inferredType, equalsName, node.fileOffset)
        .member;

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(
            readResult.inferredType, writeResult.inferredType);

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.a = b : null
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
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      VariableDeclaration readVariable =
          createVariable(node.read, readResult.inferredType);
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, node.write, createVariableGet(readVariable), inferredType)
        ..fileOffset = node.fileOffset;
      node.replaceWith(replacement =
          new Let(node.variable, createLet(readVariable, conditional))
            ..fileOffset = node.fileOffset);
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullSet(
      IfNullSet node, DartType typeContext) {
    ExpressionInferenceResult readResult =
        inferrer.inferExpression(node.read, const UnknownType(), true);
    ExpressionInferenceResult writeResult = inferrer
        .inferExpression(node.write, typeContext, true, isVoidAllowed: true);
    Member equalsMember = inferrer
        .findInterfaceMember(
            readResult.inferredType, equalsName, node.fileOffset)
        .member;

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(
            readResult.inferredType, writeResult.inferredType);

    Expression replacement;
    if (node.forEffect) {
      // Encode `a ??= b` as:
      //
      //     a == null ? a = b : null
      //
      MethodInvocation equalsNull =
          createEqualsNull(node.fileOffset, node.read, equalsMember);
      node.replaceWith(replacement = new ConditionalExpression(
          equalsNull,
          node.write,
          new NullLiteral()..fileOffset = node.fileOffset,
          inferredType)
        ..fileOffset = node.fileOffset);
    } else {
      // Encode `a ??= b` as:
      //
      //      let v1 = a in v1 == null ? a = b : v1
      //
      VariableDeclaration readVariable =
          createVariable(node.read, readResult.inferredType);
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, node.write, createVariableGet(readVariable), inferredType)
        ..fileOffset = node.fileOffset;
      node.replaceWith(replacement = new Let(readVariable, conditional)
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
        createVariable(node.receiver, receiverType);

    ObjectAccessTarget indexSetTarget = inferrer.findInterfaceMember(
        receiverType, indexSetName, node.fileOffset,
        includeExtensionMethods: true);

    DartType indexType = inferrer.getIndexKeyType(indexSetTarget, receiverType);
    DartType valueType =
        inferrer.getIndexSetValueType(indexSetTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    inferrer.ensureAssignable(
        indexType, indexResult.inferredType, node.index, node.index.fileOffset);

    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);
    VariableDeclaration valueVariable =
        createVariable(node.value, valueResult.inferredType);

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression replacement;
    Expression assignment;
    if (indexSetTarget.isMissing) {
      assignment = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments('[]=', receiverType),
          node.fileOffset,
          '[]='.length);
    } else if (indexSetTarget.isExtensionMember) {
      assert(indexSetTarget.extensionMethodKind != ProcedureKind.Setter);
      assignment = new StaticInvocation(
          indexSetTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            createVariableGet(indexVariable),
            createVariableGet(valueVariable)
          ], types: indexSetTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset;
    } else {
      assignment = new MethodInvocation(
          createVariableGet(receiverVariable),
          indexSetName,
          new Arguments(<Expression>[
            createVariableGet(indexVariable),
            createVariableGet(valueVariable)
          ])
            ..fileOffset = node.fileOffset,
          indexSetTarget.member)
        ..fileOffset = node.fileOffset;
    }
    VariableDeclaration assignmentVariable =
        createVariable(assignment, const VoidType());
    node.replaceWith(replacement = new Let(
        receiverVariable,
        createLet(
            indexVariable,
            createLet(
                valueVariable,
                createLet(
                    assignmentVariable, createVariableGet(valueVariable))))
          ..fileOffset = node.fileOffset));
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitSuperIndexSet(
      SuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget indexSetTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter)
        : const ObjectAccessTarget.missing();

    DartType indexType =
        inferrer.getIndexKeyType(indexSetTarget, inferrer.thisType);
    DartType valueType =
        inferrer.getIndexSetValueType(indexSetTarget, inferrer.thisType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    inferrer.ensureAssignable(
        indexType, indexResult.inferredType, node.index, node.index.fileOffset);

    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);
    VariableDeclaration valueVariable =
        createVariable(node.value, valueResult.inferredType);

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression replacement;
    Expression assignment;
    if (indexSetTarget.isMissing) {
      assignment = inferrer.helper.buildProblem(
          templateSuperclassHasNoMethod.withArguments(indexSetName.name),
          node.fileOffset,
          noLength);
    } else {
      assert(indexSetTarget.isInstanceMember);
      inferrer.instrumentation?.record(inferrer.uri, node.fileOffset, 'target',
          new InstrumentationValueForMember(node.setter));
      assignment = new SuperMethodInvocation(
          indexSetName,
          new Arguments(<Expression>[
            createVariableGet(indexVariable),
            createVariableGet(valueVariable)
          ])
            ..fileOffset = node.fileOffset,
          indexSetTarget.member)
        ..fileOffset = node.fileOffset;
    }
    VariableDeclaration assignmentVariable =
        createVariable(assignment, const VoidType());
    node.replaceWith(replacement = new Let(
        indexVariable,
        createLet(valueVariable,
            createLet(assignmentVariable, createVariableGet(valueVariable))))
      ..fileOffset = node.fileOffset);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitExtensionIndexSet(
      ExtensionIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments =
        inferrer.computeExtensionTypeArgument(node.extension,
            node.explicitTypeArguments, receiverResult.inferredType);

    DartType receiverType = inferrer.getExtensionReceiverType(
        node.extension, extensionTypeArguments);

    inferrer.ensureAssignable(receiverType, receiverResult.inferredType,
        node.receiver, node.receiver.fileOffset);

    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.setter, null, ProcedureKind.Operator, extensionTypeArguments);

    DartType indexType = inferrer.getIndexKeyType(target, receiverType);
    DartType valueType = inferrer.getIndexSetValueType(target, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    inferrer.ensureAssignable(
        indexType, indexResult.inferredType, node.index, node.index.fileOffset);

    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);
    VariableDeclaration valueVariable =
        createVariable(node.value, valueResult.inferredType);

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression replacement;
    Expression assignment;
    if (target.isMissing) {
      assignment = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments(
              indexSetName.name, receiverType),
          node.fileOffset,
          noLength);
    } else {
      assert(target.isExtensionMember);
      assignment = new StaticInvocation(
          target.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            createVariableGet(indexVariable),
            createVariableGet(valueVariable)
          ], types: target.inferredExtensionTypeArguments)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset;
    }
    VariableDeclaration assignmentVariable =
        createVariable(assignment, const VoidType());
    node.replaceWith(replacement = new Let(
        receiverVariable,
        createLet(
            indexVariable,
            createLet(
                valueVariable,
                createLet(
                    assignmentVariable, createVariableGet(valueVariable)))))
      ..fileOffset = node.fileOffset);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullIndexSet(
      IfNullIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (node.readOnlyReceiver) {
      readReceiver = node.receiver;
      writeReceiver = readReceiver.accept<TreeNode>(new CloneVisitor());
    } else {
      receiverVariable = createVariable(node.receiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, indexGetName, node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind checkKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readType = inferrer.getReturnType(readTarget, receiverType);
    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
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
          '[]'.length);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            readReceiver,
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    } else {
      read = new MethodInvocation(
          readReceiver,
          indexGetName,
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
          node.writeOffset,
          '[]='.length);
    } else if (writeTarget.isExtensionMember) {
      assert(writeTarget.extensionMethodKind != ProcedureKind.Setter);
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(
              <Expression>[writeReceiver, writeIndex, valueExpression],
              types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    } else {
      write = new MethodInvocation(
          writeReceiver,
          indexSetName,
          new Arguments(<Expression>[writeIndex, valueExpression])
            ..fileOffset = node.writeOffset,
          writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    Expression inner;
    if (node.forEffect) {
      // Encode `Extension(o)[a] ??= b`, if `node.readOnlyReceiver` is false,
      // as:
      //
      //     let receiverVariable = o in
      //     let indexVariable = a in
      //        receiverVariable[indexVariable]  == null
      //          ? receiverVariable.[]=(indexVariable, b) : null
      //
      // and if `node.readOnlyReceiver` is true as:
      //
      //     let indexVariable = a in
      //         o[indexVariable] == null ? o.[]=(indexVariable, b) : null
      //
      MethodInvocation equalsNull =
          createEqualsNull(node.testOffset, read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          write, new NullLiteral()..fileOffset = node.testOffset, inferredType)
        ..fileOffset = node.testOffset;
      inner = createLet(indexVariable, conditional);
    } else {
      // Encode `Extension(o)[a] ??= b` as, if `node.readOnlyReceiver` is false,
      // as:
      //
      //     let receiverVariable = o in
      //     let indexVariable = a in
      //     let readVariable = receiverVariable[indexVariable] in
      //       readVariable == null
      //        ? (let valueVariable = b in
      //           let writeVariable =
      //             receiverVariable.[]=(indexVariable, valueVariable) in
      //               valueVariable)
      //        : readVariable
      //
      // and if `node.readOnlyReceiver` is true as:
      //
      //     let indexVariable = a in
      //     let readVariable = o[indexVariable] in
      //       readVariable == null
      //        ? (let valueVariable = b in
      //           let writeVariable = o.[]=(indexVariable, valueVariable) in
      //               valueVariable)
      //        : readVariable
      //
      //
      assert(valueVariable != null);

      VariableDeclaration readVariable = createVariable(read, readType);
      MethodInvocation equalsNull = createEqualsNull(
          node.testOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))),
          createVariableGet(readVariable),
          inferredType)
        ..fileOffset = node.fileOffset;
      inner = createLet(indexVariable, createLet(readVariable, conditional));
    }

    Expression replacement;
    if (receiverVariable != null) {
      node.replaceWith(replacement = new Let(receiverVariable, inner)
        ..fileOffset = node.fileOffset);
    } else {
      node.replaceWith(replacement = inner);
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullSuperIndexSet(
      IfNullSuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget readTarget = node.getter != null
        ? new ObjectAccessTarget.interfaceMember(node.getter)
        : const ObjectAccessTarget.missing();

    DartType readType = inferrer.getReturnType(readTarget, inferrer.thisType);
    DartType readIndexType =
        inferrer.getIndexKeyType(readTarget, inferrer.thisType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, inferrer.thisType);
    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    VariableGet readIndex = createVariableGet(indexVariable);
    inferrer.ensureAssignable(readIndexType, indexResult.inferredType,
        readIndex, readIndex.fileOffset);

    VariableGet writeIndex = createVariableGet(indexVariable);
    inferrer.ensureAssignable(writeIndexType, indexResult.inferredType,
        writeIndex, writeIndex.fileOffset);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    Expression read;

    if (readTarget.isMissing) {
      read = inferrer.helper.buildProblem(
          templateSuperclassHasNoMethod.withArguments('[]'),
          node.readOffset,
          '[]'.length);
    } else {
      assert(readTarget.isInstanceMember);
      inferrer.instrumentation?.record(inferrer.uri, node.readOffset, 'target',
          new InstrumentationValueForMember(node.getter));
      read = new SuperMethodInvocation(
          indexGetName,
          new Arguments(<Expression>[
            readIndex,
          ])
            ..fileOffset = node.readOffset,
          readTarget.member)
        ..fileOffset = node.readOffset;
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
          templateSuperclassHasNoMethod.withArguments('[]='),
          node.writeOffset,
          '[]='.length);
    } else {
      assert(writeTarget.isInstanceMember);
      inferrer.instrumentation?.record(inferrer.uri, node.writeOffset, 'target',
          new InstrumentationValueForMember(node.setter));
      write = new SuperMethodInvocation(
          indexSetName,
          new Arguments(
              <Expression>[createVariableGet(indexVariable), valueExpression])
            ..fileOffset = node.writeOffset,
          writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    Expression replacement;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = a in
      //        super[v1] == null ? super.[]=(v1, b) : null
      //
      MethodInvocation equalsNull =
          createEqualsNull(node.testOffset, read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          write, new NullLiteral()..fileOffset = node.testOffset, inferredType)
        ..fileOffset = node.testOffset;
      replacement = createLet(indexVariable, conditional);
    } else {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = a in
      //     let v2 = super[v1] in
      //       v2 == null
      //        ? (let v3 = b in
      //           let _ = super.[]=(v1, v3) in
      //           v3)
      //        : v2
      //
      assert(valueVariable != null);

      VariableDeclaration readVariable = createVariable(read, readType);
      MethodInvocation equalsNull = createEqualsNull(
          node.testOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))),
          createVariableGet(readVariable),
          inferredType)
        ..fileOffset = node.fileOffset;
      replacement =
          createLet(indexVariable, createLet(readVariable, conditional));
    }

    node.replaceWith(replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullExtensionIndexSet(
      IfNullExtensionIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments =
        inferrer.computeExtensionTypeArgument(node.extension,
            node.explicitTypeArguments, receiverResult.inferredType);

    DartType receiverType = inferrer.getExtensionReceiverType(
        node.extension, extensionTypeArguments);

    inferrer.ensureAssignable(receiverType, receiverResult.inferredType,
        node.receiver, node.receiver.fileOffset);

    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);

    ObjectAccessTarget readTarget = node.getter != null
        ? new ExtensionAccessTarget(
            node.getter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType readType = inferrer.getReturnType(readTarget, receiverType);
    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ExtensionAccessTarget(
            node.setter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, receiverType);
    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable =
        createVariable(node.index, indexResult.inferredType);

    VariableGet readIndex = createVariableGet(indexVariable);
    inferrer.ensureAssignable(readIndexType, indexResult.inferredType,
        readIndex, readIndex.fileOffset);

    VariableGet writeIndex = createVariableGet(indexVariable);
    inferrer.ensureAssignable(writeIndexType, indexResult.inferredType,
        writeIndex, writeIndex.fileOffset);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    Expression read;

    if (readTarget.isMissing) {
      read = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments(
              indexGetName.name, receiverType),
          node.readOffset,
          noLength);
    } else {
      assert(readTarget.isExtensionMember);
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
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
          templateUndefinedMethod.withArguments(
              indexSetName.name, receiverType),
          node.writeOffset,
          noLength);
    } else {
      assert(writeTarget.isExtensionMember);
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            writeIndex,
            valueExpression
          ], types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    }

    Expression inner;
    if (node.forEffect) {
      // Encode `Extension(o)[a] ??= b` as:
      //
      //     let receiverVariable = o;
      //     let indexVariable = a in
      //        receiverVariable[indexVariable] == null
      //          ? receiverVariable.[]=(indexVariable, b) : null
      //
      MethodInvocation equalsNull =
          createEqualsNull(node.testOffset, read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          write, new NullLiteral()..fileOffset = node.testOffset, inferredType)
        ..fileOffset = node.testOffset;
      inner = createLet(indexVariable, conditional);
    } else {
      // Encode `Extension(o)[a] ??= b` as:
      //
      //     let receiverVariable = o;
      //     let indexVariable = a in
      //     let readVariable = receiverVariable[indexVariable] in
      //       readVariable == null
      //        ? (let valueVariable = b in
      //           let writeVariable =
      //               receiverVariable.[]=(indexVariable, valueVariable) in
      //           valueVariable)
      //        : readVariable
      //
      assert(valueVariable != null);

      VariableDeclaration readVariable = createVariable(read, readType);
      MethodInvocation equalsNull = createEqualsNull(
          node.testOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))),
          createVariableGet(readVariable),
          inferredType)
        ..fileOffset = node.fileOffset;
      inner = createLet(indexVariable, createLet(readVariable, conditional));
    }

    Expression replacement = new Let(receiverVariable, inner)
      ..fileOffset = node.fileOffset;

    node.replaceWith(replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitCompoundIndexSet(
      CompoundIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (node.readOnlyReceiver) {
      readReceiver = node.receiver;
      writeReceiver = readReceiver.accept<TreeNode>(new CloneVisitor());
    } else {
      receiverVariable = createVariable(node.receiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, indexGetName, node.readOffset,
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
          '[]'.length);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            readReceiver,
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    } else {
      read = new MethodInvocation(
          readReceiver,
          indexGetName,
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
          templateUndefinedMethod.withArguments(node.binaryName.name, readType),
          node.binaryOffset,
          node.binaryName.name.length);
    } else if (binaryTarget.isExtensionMember) {
      assert(binaryTarget.extensionMethodKind != ProcedureKind.Setter);
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
        receiverType, indexSetName, node.writeOffset,
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
          '[]='.length);
    } else if (writeTarget.isExtensionMember) {
      assert(writeTarget.extensionMethodKind != ProcedureKind.Setter);
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(
              <Expression>[writeReceiver, writeIndex, valueExpression],
              types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    } else {
      write = new MethodInvocation(
          writeReceiver,
          indexSetName,
          new Arguments(<Expression>[writeIndex, valueExpression])
            ..fileOffset = node.writeOffset,
          writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    Expression inner;
    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `o[a] += b` as:
      //
      //     let v1 = o in let v2 = a in v1.[]=(v2, v1.[](v2) + b)
      //
      inner = createLet(indexVariable, write);
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
      inner = createLet(
          indexVariable,
          createLet(leftVariable,
              createLet(writeVariable, createVariableGet(leftVariable))));
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
      inner = createLet(
          indexVariable,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))));
    }

    Expression replacement;
    if (receiverVariable != null) {
      node.replaceWith(replacement = new Let(receiverVariable, inner)
        ..fileOffset = node.fileOffset);
    } else {
      node.replaceWith(replacement = inner);
    }
    return new ExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType, replacement);
  }

  ExpressionInferenceResult visitNullAwareCompoundSet(
      NullAwareCompoundSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);

    Member equalsMember = inferrer
        .findInterfaceMember(receiverType, equalsName, node.receiver.fileOffset)
        .member;

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, node.propertyName, node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind readCheckKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readType = inferrer.getGetterType(readTarget, receiverType);

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments(
              node.propertyName.name, receiverType),
          node.readOffset,
          node.propertyName.name.length);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            readReceiver,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    } else {
      read = new PropertyGet(readReceiver, node.propertyName, readTarget.member)
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
          templateUndefinedMethod.withArguments(node.binaryName.name, readType),
          node.binaryOffset,
          node.binaryName.name.length);
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
        receiverType, node.propertyName, node.writeOffset,
        setter: true, includeExtensionMethods: true);

    DartType valueType = inferrer.getSetterType(writeTarget, receiverType);
    Expression binaryReplacement = inferrer.ensureAssignable(
        valueType, binaryType, binary, node.fileOffset);
    if (binaryReplacement != null) {
      binary = binaryReplacement;
    }

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
          templateUndefinedMethod.withArguments(
              node.propertyName.name, receiverType),
          node.writeOffset,
          node.propertyName.name.length);
    } else if (writeTarget.isExtensionMember) {
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[writeReceiver, valueExpression],
              types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    } else {
      write = new PropertySet(
          writeReceiver, node.propertyName, valueExpression, writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    DartType resultType = node.forPostIncDec ? readType : binaryType;

    Expression replacement;
    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `receiver?.propertyName binaryName= rhs` as:
      //
      //     let receiverVariable = receiver in
      //       receiverVariable == null ? null :
      //         receiverVariable.propertyName =
      //             receiverVariable.propertyName + rhs
      //

      MethodInvocation equalsNull = createEqualsNull(
          receiverVariable.fileOffset,
          createVariableGet(receiverVariable),
          equalsMember);
      ConditionalExpression condition = new ConditionalExpression(equalsNull,
          new NullLiteral()..fileOffset = node.readOffset, write, resultType);
      replacement = createLet(receiverVariable, condition);
    } else if (node.forPostIncDec) {
      // Encode `receiver?.propertyName binaryName= rhs` from a postfix
      // expression like `o?.a++` as:
      //
      //     let receiverVariable = receiver in
      //       receiverVariable == null ? null :
      //         let leftVariable = receiverVariable.propertyName in
      //           let writeVariable =
      //               receiverVariable.propertyName =
      //                   leftVariable binaryName rhs in
      //             leftVariable
      //
      assert(leftVariable != null);
      assert(valueVariable == null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      MethodInvocation equalsNull = createEqualsNull(
          receiverVariable.fileOffset,
          createVariableGet(receiverVariable),
          equalsMember);
      ConditionalExpression condition = new ConditionalExpression(
          equalsNull,
          new NullLiteral()..fileOffset = node.readOffset,
          createLet(leftVariable,
              createLet(writeVariable, createVariableGet(leftVariable))),
          resultType);
      replacement = createLet(receiverVariable, condition);
    } else {
      // Encode `receiver?.propertyName binaryName= rhs` as:
      //
      //     let receiverVariable = receiver in
      //       receiverVariable == null ? null :
      //         let leftVariable = receiverVariable.propertyName in
      //           let valueVariable = leftVariable binaryName rhs in
      //             let writeVariable =
      //                 receiverVariable.propertyName = valueVariable in
      //               valueVariable
      //
      // TODO(johnniwinther): Do we need the `leftVariable` in this case?
      assert(leftVariable == null);
      assert(valueVariable != null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      MethodInvocation equalsNull = createEqualsNull(
          receiverVariable.fileOffset,
          createVariableGet(receiverVariable),
          equalsMember);
      ConditionalExpression condition = new ConditionalExpression(
          equalsNull,
          new NullLiteral()..fileOffset = node.readOffset,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))),
          resultType);
      replacement = createLet(receiverVariable, condition);
    }

    node.replaceWith(replacement);
    return new ExpressionInferenceResult(resultType, replacement);
  }

  ExpressionInferenceResult visitCompoundSuperIndexSet(
      CompoundSuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget readTarget = node.getter != null
        ? new ObjectAccessTarget.interfaceMember(node.getter)
        : const ObjectAccessTarget.missing();

    DartType readType = inferrer.getReturnType(readTarget, inferrer.thisType);
    DartType readIndexType = inferrer.getPositionalParameterTypeForTarget(
        readTarget, inferrer.thisType, 0);

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
          templateSuperclassHasNoMethod.withArguments('[]'),
          node.readOffset,
          '[]'.length);
    } else {
      assert(readTarget.isInstanceMember);
      inferrer.instrumentation?.record(inferrer.uri, node.readOffset, 'target',
          new InstrumentationValueForMember(node.getter));
      read = new SuperMethodInvocation(
          indexGetName,
          new Arguments(<Expression>[
            readIndex,
          ])
            ..fileOffset = node.readOffset,
          readTarget.member)
        ..fileOffset = node.readOffset;
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
          templateUndefinedMethod.withArguments(node.binaryName.name, readType),
          node.binaryOffset,
          node.binaryName.name.length);
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

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = inferrer.getPositionalParameterTypeForTarget(
        writeTarget, inferrer.thisType, 0);
    Expression writeIndex = createVariableGet(indexVariable);
    Expression writeIndexReplacement = inferrer.ensureAssignable(writeIndexType,
        indexResult.inferredType, writeIndex, writeIndex.fileOffset);
    if (writeIndexReplacement != null) {
      writeIndex = writeIndexReplacement;
    }

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);
    Expression binaryReplacement = inferrer.ensureAssignable(
        valueType, binaryType, binary, node.fileOffset);
    if (binaryReplacement != null) {
      binary = binaryReplacement;
    }

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
          templateSuperclassHasNoMethod.withArguments('[]='),
          node.writeOffset,
          '[]='.length);
    } else {
      assert(writeTarget.isInstanceMember);
      inferrer.instrumentation?.record(inferrer.uri, node.writeOffset, 'target',
          new InstrumentationValueForMember(node.setter));
      write = new SuperMethodInvocation(
          indexSetName,
          new Arguments(<Expression>[writeIndex, valueExpression])
            ..fileOffset = node.writeOffset,
          writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    Expression replacement;
    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `super[a] += b` as:
      //
      //     let v1 = a in super.[]=(v1, super.[](v1) + b)
      //
      replacement = createLet(indexVariable, write);
    } else if (node.forPostIncDec) {
      // Encode `super[a]++` as:
      //
      //     let v2 = a in
      //     let v3 = v1.[](v2)
      //     let v4 = v1.[]=(v2, v3 + 1) in v3
      //
      assert(leftVariable != null);
      assert(valueVariable == null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      replacement = createLet(
          indexVariable,
          createLet(leftVariable,
              createLet(writeVariable, createVariableGet(leftVariable))));
    } else {
      // Encode `super[a] += b` as:
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
      replacement = createLet(
          indexVariable,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))));
    }

    node.replaceWith(replacement);
    return new ExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType, replacement);
  }

  ExpressionInferenceResult visitCompoundExtensionIndexSet(
      CompoundExtensionIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments =
        inferrer.computeExtensionTypeArgument(node.extension,
            node.explicitTypeArguments, receiverResult.inferredType);

    ObjectAccessTarget readTarget = node.getter != null
        ? new ExtensionAccessTarget(
            node.getter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType receiverType = inferrer.getPositionalParameterTypeForTarget(
        readTarget, receiverResult.inferredType, 0);

    inferrer.ensureAssignable(receiverType, receiverResult.inferredType,
        node.receiver, node.receiver.fileOffset);

    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);

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
          templateUndefinedMethod.withArguments(
              indexGetName.name, receiverType),
          node.readOffset,
          noLength);
    } else {
      assert(readTarget.isExtensionMember);
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
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
          templateUndefinedMethod.withArguments(node.binaryName.name, readType),
          node.binaryOffset,
          node.binaryName.name.length);
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

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ExtensionAccessTarget(
            node.setter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = inferrer.getPositionalParameterTypeForTarget(
        writeTarget, receiverType, 0);
    Expression writeIndex = createVariableGet(indexVariable);
    Expression writeIndexReplacement = inferrer.ensureAssignable(writeIndexType,
        indexResult.inferredType, writeIndex, writeIndex.fileOffset);
    if (writeIndexReplacement != null) {
      writeIndex = writeIndexReplacement;
    }

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);
    Expression binaryReplacement = inferrer.ensureAssignable(
        valueType, binaryType, binary, node.fileOffset);
    if (binaryReplacement != null) {
      binary = binaryReplacement;
    }

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
          templateUndefinedMethod.withArguments(
              indexSetName.name, receiverType),
          node.writeOffset,
          noLength);
    } else {
      assert(writeTarget.isExtensionMember);
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[
            createVariableGet(receiverVariable),
            writeIndex,
            valueExpression
          ], types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    }

    Expression inner;
    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `Extension(o)[a] += b` as:
      //
      //     let receiverVariable = o in
      //     let indexVariable = a in
      //         receiverVariable.[]=(receiverVariable, o.[](indexVariable) + b)
      //
      inner = createLet(indexVariable, write);
    } else if (node.forPostIncDec) {
      // Encode `Extension(o)[a]++` as:
      //
      //     let receiverVariable = o in
      //     let indexVariable = a in
      //     let leftVariable = receiverVariable.[](indexVariable)
      //     let writeVariable =
      //       receiverVariable.[]=(indexVariable, leftVariable + 1) in
      //         leftVariable
      //
      assert(leftVariable != null);
      assert(valueVariable == null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      inner = createLet(
          indexVariable,
          createLet(leftVariable,
              createLet(writeVariable, createVariableGet(leftVariable))));
    } else {
      // Encode `Extension(o)[a] += b` as:
      //
      //     let receiverVariable = o in
      //     let indexVariable = a in
      //     let valueVariable = receiverVariable.[](indexVariable) + b
      //     let writeVariable =
      //       receiverVariable.[]=(indexVariable, valueVariable) in
      //         valueVariable
      //
      assert(leftVariable == null);
      assert(valueVariable != null);

      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      inner = createLet(
          indexVariable,
          createLet(valueVariable,
              createLet(writeVariable, createVariableGet(valueVariable))));
    }

    Expression replacement = new Let(receiverVariable, inner)
      ..fileOffset = node.fileOffset;

    node.replaceWith(replacement);
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
    inferrer.inferExpression(node.variable.initializer, variableType, true,
        isVoidAllowed: true);
    ExpressionInferenceResult result = inferrer
        .inferExpression(node.body, typeContext, true, isVoidAllowed: true);
    DartType inferredType = result.inferredType;
    return new ExpressionInferenceResult(inferredType);
  }

  @override
  ExpressionInferenceResult visitPropertySet(
      covariant PropertySetImpl node, DartType typeContext) {
    DartType receiverType = inferrer
        .inferExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: false)
        .inferredType;
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
      if (node.forEffect) {
        replacement = new StaticInvocation(
            target.member,
            new Arguments(<Expression>[node.receiver, node.value],
                types: target.inferredExtensionTypeArguments)
              ..fileOffset = node.fileOffset)
          ..fileOffset = node.fileOffset;
      } else {
        Expression receiver;
        VariableDeclaration receiverVariable;
        if (node.readOnlyReceiver) {
          receiver = node.receiver;
        } else {
          receiverVariable = createVariable(node.receiver, receiverType);
          receiver = createVariableGet(receiverVariable);
        }
        VariableDeclaration valueVariable = createVariable(node.value, rhsType);
        VariableDeclaration assignmentVariable = createVariable(
            new StaticInvocation(
                target.member,
                new Arguments(
                    <Expression>[receiver, createVariableGet(valueVariable)],
                    types: target.inferredExtensionTypeArguments)
                  ..fileOffset = node.fileOffset)
              ..fileOffset = node.fileOffset,
            const VoidType());
        replacement = createLet(valueVariable,
            createLet(assignmentVariable, createVariableGet(valueVariable)));
        if (receiverVariable != null) {
          replacement = createLet(receiverVariable, replacement);
        }
        replacement..fileOffset = node.fileOffset;
      }
      node.replaceWith(replacement);
    }
    return new ExpressionInferenceResult(rhsType, replacement);
  }

  ExpressionInferenceResult visitNullAwareIfNullSet(
      NullAwareIfNullSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        createVariable(node.receiver, receiverType);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);

    Member receiverEqualsMember = inferrer
        .findInterfaceMember(receiverType, equalsName, node.receiver.fileOffset)
        .member;

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, node.name, node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind readCheckKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readType = inferrer.getGetterType(readTarget, receiverType);

    Member readEqualsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments(node.name.name, receiverType),
          node.readOffset,
          node.name.name.length);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            readReceiver,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    } else {
      read = new PropertyGet(readReceiver, node.name, readTarget.member)
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

    VariableDeclaration readVariable;
    if (!node.forEffect) {
      readVariable = createVariable(read, readType);
      read = createVariableGet(readVariable);
    }

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.name, node.writeOffset,
        setter: true, includeExtensionMethods: true);

    DartType valueType = inferrer.getSetterType(writeTarget, receiverType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    inferrer.ensureAssignable(
        valueType, valueResult.inferredType, node.value, node.value.fileOffset);

    Expression write;

    if (writeTarget.isMissing) {
      write = inferrer.helper.buildProblem(
          templateUndefinedMethod.withArguments(node.name.name, receiverType),
          node.writeOffset,
          node.name.name.length);
    } else if (writeTarget.isExtensionMember) {
      if (node.forEffect) {
        write = new StaticInvocation(
            writeTarget.member,
            new Arguments(<Expression>[writeReceiver, node.value],
                types: writeTarget.inferredExtensionTypeArguments)
              ..fileOffset = node.writeOffset)
          ..fileOffset = node.writeOffset;
      } else {
        VariableDeclaration valueVariable =
            createVariable(node.value, valueResult.inferredType);
        VariableDeclaration assignmentVariable = createVariable(
            new StaticInvocation(
                writeTarget.member,
                new Arguments(<Expression>[
                  writeReceiver,
                  createVariableGet(valueVariable)
                ], types: writeTarget.inferredExtensionTypeArguments)
                  ..fileOffset = node.writeOffset)
              ..fileOffset = node.writeOffset,
            const VoidType());
        write = createLet(valueVariable,
            createLet(assignmentVariable, createVariableGet(valueVariable)))
          ..fileOffset = node.writeOffset;
      }
    } else {
      write = new PropertySet(
          writeReceiver, node.name, node.value, writeTarget.member)
        ..fileOffset = node.writeOffset;
    }

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    Expression replacement;
    if (node.forEffect) {
      assert(readVariable == null);
      // Encode `receiver?.name ??= value` as:
      //
      //     let receiverVariable = receiver in
      //       receiverVariable == null ? null :
      //         (receiverVariable.name == null ?
      //           receiverVariable.name = value : null)
      //

      MethodInvocation receiverEqualsNull = createEqualsNull(
          receiverVariable.fileOffset,
          createVariableGet(receiverVariable),
          receiverEqualsMember);
      MethodInvocation readEqualsNull =
          createEqualsNull(node.readOffset, read, readEqualsMember);
      ConditionalExpression innerCondition = new ConditionalExpression(
          readEqualsNull,
          write,
          new NullLiteral()..fileOffset = node.writeOffset,
          inferredType);
      ConditionalExpression outerCondition = new ConditionalExpression(
          receiverEqualsNull,
          new NullLiteral()..fileOffset = node.readOffset,
          innerCondition,
          inferredType);
      replacement = createLet(receiverVariable, outerCondition);
    } else {
      // Encode `receiver?.name ??= value` as:
      //
      //     let receiverVariable = receiver in
      //       receiverVariable == null ? null :
      //         (let readVariable = receiverVariable.name in
      //           readVariable == null ?
      //             receiverVariable.name = value : readVariable)
      //
      assert(readVariable != null);

      MethodInvocation receiverEqualsNull = createEqualsNull(
          receiverVariable.fileOffset,
          createVariableGet(receiverVariable),
          receiverEqualsMember);
      MethodInvocation readEqualsNull =
          createEqualsNull(receiverVariable.fileOffset, read, readEqualsMember);
      ConditionalExpression innerCondition = new ConditionalExpression(
          readEqualsNull, write, createVariableGet(readVariable), inferredType);
      ConditionalExpression outerCondition = new ConditionalExpression(
          receiverEqualsNull,
          new NullLiteral()..fileOffset = node.readOffset,
          createLet(readVariable, innerCondition),
          inferredType);
      replacement = createLet(receiverVariable, outerCondition);
    }

    node.replaceWith(replacement);
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
    inferrer.inferInvocation(null, node.fileOffset,
        node.target.function.thisFunctionType, node.arguments,
        returnType: node.target.enclosingClass.thisType,
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
    DartType inferredType = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments);
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
            expression, const UnknownType(), !inferrer.isTopLevel,
            isVoidAllowed: false);
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
        node.arguments,
        returnType: inferrer.thisType,
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
        .inferExpression(node.expression, const UnknownType(), true,
            isVoidAllowed: false)
        .inferredType;

    for (SwitchCase switchCase in node.cases) {
      for (Expression caseExpression in switchCase.expressions) {
        ExpressionInferenceResult caseExpressionResult =
            inferrer.inferExpression(caseExpression, expressionType, true,
                isVoidAllowed: false);
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

  ExpressionInferenceResult visitThisExpression(
      ThisExpression node, DartType typeContext) {
    return new ExpressionInferenceResult(inferrer.thisType);
  }

  @override
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: false);
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
        .inferExpression(node.condition, expectedType, !inferrer.isTopLevel,
            isVoidAllowed: false)
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
          .inferExpression(node.expression, typeContext, true,
              isVoidAllowed: true)
          .inferredType;
    } else {
      inferredType = inferrer
          .inferExpression(node.expression, const UnknownType(), true,
              isVoidAllowed: true)
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
      inferrer.inferInvocation(
          typeContext, node.fileOffset, calleeType, node.arguments);
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
