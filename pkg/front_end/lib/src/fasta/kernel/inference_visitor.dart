// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "kernel_shadow_ast.dart";

class InferenceVisitor
    implements
        ExpressionVisitor1<ExpressionInferenceResult, DartType>,
        StatementVisitor<StatementInferenceResult>,
        InitializerVisitor<void> {
  final TypeInferrerImpl inferrer;

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
    return new ExpressionInferenceResult(const InvalidType(), node);
  }

  @override
  ExpressionInferenceResult defaultExpression(
      Expression node, DartType typeContext) {
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

  StatementInferenceResult _unhandledStatement(Statement node) {
    return unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        inferrer.helper.uri);
  }

  @override
  StatementInferenceResult defaultStatement(Statement node) {
    return _unhandledStatement(node);
  }

  @override
  StatementInferenceResult visitAssertBlock(AssertBlock node) {
    return _unhandledStatement(node);
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
    return new ExpressionInferenceResult(const DynamicType(), node);
  }

  @override
  ExpressionInferenceResult visitIntLiteral(
      IntLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.intRawType(inferrer.library.nonNullable), node);
  }

  @override
  ExpressionInferenceResult visitAsExpression(
      AsExpression node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
    node.operand = operandResult.expression..parent = node;
    inferrer.flowAnalysis.asExpression_end(node.operand, node.type);
    return new ExpressionInferenceResult(node.type, node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    StatementInferenceResult result = inferrer.inferStatement(node.statement);
    if (result.hasChanged) {
      node.statement = result.statement..parent = node;
    }
  }

  @override
  StatementInferenceResult visitAssertStatement(AssertStatement node) {
    inferrer.flowAnalysis.assert_begin();
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult conditionResult = inferrer.inferExpression(
        node.condition, expectedType, !inferrer.isTopLevel,
        isVoidAllowed: true);

    Expression condition =
        inferrer.ensureAssignableResult(expectedType, conditionResult);
    node.condition = condition..parent = node;
    inferrer.flowAnalysis.assert_afterCondition(node.condition);
    if (node.message != null) {
      ExpressionInferenceResult messageResult = inferrer.inferExpression(
          node.message, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
      node.message = messageResult.expression..parent = node;
    }
    inferrer.flowAnalysis.assert_end();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitAwaitExpression(
      AwaitExpression node, DartType typeContext) {
    if (!inferrer.typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = inferrer.wrapFutureOrType(typeContext);
    }
    ExpressionInferenceResult operandResult = inferrer
        .inferExpression(node.operand, typeContext, true, isVoidAllowed: true);
    DartType inferredType =
        inferrer.typeSchemaEnvironment.unfutureType(operandResult.inferredType);
    node.operand = operandResult.expression..parent = node;
    return new ExpressionInferenceResult(inferredType, node);
  }

  List<Statement> _visitStatements<T extends Statement>(List<T> statements) {
    List<Statement> result;
    for (int index = 0; index < statements.length; index++) {
      T statement = statements[index];
      StatementInferenceResult statementResult =
          inferrer.inferStatement(statement);
      if (statementResult.hasChanged) {
        if (result == null) {
          result = <T>[];
          result.addAll(statements.sublist(0, index));
        }
        if (statementResult.statementCount == 1) {
          result.add(statementResult.statement);
        } else {
          result.addAll(statementResult.statements);
        }
      } else if (result != null) {
        result.add(statement);
      }
    }
    return result;
  }

  @override
  StatementInferenceResult visitBlock(Block node) {
    inferrer.registerIfUnreachableForTesting(node);
    List<Statement> result = _visitStatements<Statement>(node.statements);
    return result != null
        ? new StatementInferenceResult.single(
            new Block(result)..fileOffset = node.fileOffset)
        : const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitBoolLiteral(
      BoolLiteral node, DartType typeContext) {
    inferrer.flowAnalysis.booleanLiteral(node, node.value);
    return new ExpressionInferenceResult(
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable), node);
  }

  @override
  StatementInferenceResult visitBreakStatement(BreakStatement node) {
    // TODO(johnniwinther): Refactor break/continue encoding.
    inferrer.flowAnalysis.handleBreak(node.target);
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.variable.initializer, typeContext, true,
        isVoidAllowed: false);
    node.variable.initializer = result.expression..parent = node.variable;
    node.variable.type = result.inferredType;
    List<ExpressionInferenceResult> expressionResults =
        <ExpressionInferenceResult>[];
    for (Expression expression in node.expressions) {
      expressionResults.add(inferrer.inferExpression(
          expression, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true));
    }
    Expression replacement = createVariableGet(node.variable);
    for (int index = expressionResults.length - 1; index >= 0; index--) {
      replacement = createLet(
          createVariable(expressionResults[index].expression, const VoidType()),
          replacement);
    }

    if (node.isNullAware) {
      Member equalsMember = inferrer
          .findInterfaceMember(result.inferredType, equalsName, node.fileOffset)
          .member;
      NullAwareGuard nullAwareGuard = new NullAwareGuard(
          node.variable, node.variable.fileOffset, equalsMember);
      replacement =
          nullAwareGuard.createExpression(result.inferredType, replacement);
    } else {
      replacement = new Let(node.variable, replacement)
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitConditionalExpression(
      ConditionalExpression node, DartType typeContext) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult conditionResult = inferrer.inferExpression(
        node.condition, expectedType, !inferrer.isTopLevel,
        isVoidAllowed: true);
    Expression condition =
        inferrer.ensureAssignableResult(expectedType, conditionResult);
    node.condition = condition..parent = node;
    inferrer.flowAnalysis.conditional_thenBegin(node.condition);
    bool isThenReachable = inferrer.flowAnalysis.isReachable;
    ExpressionInferenceResult thenResult = inferrer
        .inferExpression(node.then, typeContext, true, isVoidAllowed: true);
    node.then = thenResult.expression..parent = node;
    inferrer.registerIfUnreachableForTesting(node.then,
        isReachable: isThenReachable);
    inferrer.flowAnalysis.conditional_elseBegin(node.then);
    bool isOtherwiseReachable = inferrer.flowAnalysis.isReachable;
    ExpressionInferenceResult otherwiseResult = inferrer.inferExpression(
        node.otherwise, typeContext, true,
        isVoidAllowed: true);
    node.otherwise = otherwiseResult.expression..parent = node;
    inferrer.registerIfUnreachableForTesting(node.otherwise,
        isReachable: isOtherwiseReachable);
    inferrer.flowAnalysis.conditional_end(node.condition, node.otherwise);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(
            thenResult.inferredType, otherwiseResult.inferredType);
    node.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType, node);
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
        returnType:
            computeConstructorReturnType(node.target, inferrer.coreTypes),
        isConst: node.isConst);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (!hasExplicitTypeArguments) {
        library.checkBoundsInConstructorInvocation(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  StatementInferenceResult visitContinueSwitchStatement(
      ContinueSwitchStatement node) {
    // No inference needs to be done.
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitExtensionTearOff(
      ExtensionTearOff node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.functionType
        : new FunctionType([], const DynamicType(), Nullability.legacy);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    DartType inferredType = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments);
    Expression replacement = new StaticInvocation(node.target, node.arguments);
    if (!inferrer.isTopLevel && node.target != null) {
      inferrer.library.checkBoundsInStaticInvocation(
          replacement,
          inferrer.typeSchemaEnvironment,
          inferrer.helper.uri,
          typeArgumentsInfo);
    }
    return inferrer.instantiateTearOff(inferredType, typeContext, replacement);
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

    Expression receiver =
        inferrer.ensureAssignableResult(receiverType, receiverResult);

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.target, null, ProcedureKind.Setter, extensionTypeArguments);

    DartType valueType =
        inferrer.getSetterType(target, receiverResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer.inferExpression(
        node.value, const UnknownType(), true,
        isVoidAllowed: false);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    VariableDeclaration valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    VariableDeclaration receiverVariable;
    if (node.forEffect || node.readOnlyReceiver) {
      // No need for receiver variable.
    } else {
      receiverVariable = createVariable(receiver, receiverResult.inferredType);
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
    return new ExpressionInferenceResult(valueResult.inferredType, replacement);
  }

  ExpressionInferenceResult visitCompoundExtensionSet(
      CompoundExtensionSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments =
        inferrer.computeExtensionTypeArgument(node.extension,
            node.explicitTypeArguments, receiverResult.inferredType);

    DartType receiverType = inferrer.getExtensionReceiverType(
        node.extension, extensionTypeArguments);

    Expression receiver =
        inferrer.ensureAssignableResult(receiverType, receiverResult);

    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (node.readOnlyReceiver && identical(receiver, node.receiver)) {
      readReceiver = receiver;
      writeReceiver = receiver.accept<TreeNode>(new CloneVisitor());
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = node.getter == null
        ? const ObjectAccessTarget.missing()
        : new ExtensionAccessTarget(
            node.getter, null, ProcedureKind.Getter, extensionTypeArguments);

    DartType readType = inferrer.getGetterType(readTarget, receiverType);

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.createMissingPropertyGet(
          node.readOffset, readReceiver, readType, node.propertyName);
    } else {
      assert(readTarget.isExtensionMember);
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            readReceiver,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    }

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset, read, readType, node.binaryName, node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    ObjectAccessTarget writeTarget = node.setter == null
        ? const ObjectAccessTarget.missing()
        : new ExtensionAccessTarget(
            node.setter, null, ProcedureKind.Setter, extensionTypeArguments);

    DartType valueType = inferrer.getSetterType(writeTarget, receiverType);

    Expression value = inferrer.ensureAssignable(valueType, binaryType, binary,
        isVoidAllowed: true);

    VariableDeclaration valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueType);
      value = createVariableGet(valueVariable);
    }

    Expression write;
    if (writeTarget.isMissing) {
      write = inferrer.createMissingPropertySet(
          node.writeOffset, writeReceiver, readType, node.propertyName, value);
    } else {
      assert(writeTarget.isExtensionMember);
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[
            writeReceiver,
            value,
          ], types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.writeOffset)
        ..fileOffset = node.writeOffset;
    }

    Expression replacement;
    if (node.forEffect) {
      assert(valueVariable == null);
      replacement = write;
    } else {
      assert(valueVariable != null);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      replacement = createLet(valueVariable,
          createLet(writeVariable, createVariableGet(valueVariable)));
    }
    if (receiverVariable != null) {
      replacement = createLet(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(valueType, replacement);
  }

  ExpressionInferenceResult visitDeferredCheck(
      DeferredCheck node, DartType typeContext) {
    // Since the variable is not used in the body we don't need to type infer
    // it.  We can just type infer the body.
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.expression, typeContext, true,
        isVoidAllowed: true);

    Expression replacement = new Let(node.variable, result.expression)
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  StatementInferenceResult visitDoStatement(DoStatement node) {
    inferrer.flowAnalysis.doStatement_bodyBegin(node);
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    inferrer.flowAnalysis.doStatement_conditionBegin();
    InterfaceType boolType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult conditionResult = inferrer.inferExpression(
        node.condition, boolType, !inferrer.isTopLevel,
        isVoidAllowed: true);
    Expression condition =
        inferrer.ensureAssignableResult(boolType, conditionResult);
    node.condition = condition..parent = node;
    inferrer.flowAnalysis.doStatement_end(condition);
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitDoubleLiteral(
      DoubleLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable), node);
  }

  @override
  StatementInferenceResult visitEmptyStatement(EmptyStatement node) {
    // No inference needs to be done.
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitExpressionStatement(ExpressionStatement node) {
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
    node.expression = result.expression..parent = node;
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitFactoryConstructorInvocationJudgment(
      FactoryConstructorInvocationJudgment node, DartType typeContext) {
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    DartType inferredType = inferrer.inferInvocation(typeContext,
        node.fileOffset, node.target.function.thisFunctionType, node.arguments,
        returnType:
            computeConstructorReturnType(node.target, inferrer.coreTypes),
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
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    ExpressionInferenceResult initializerResult =
        inferrer.inferExpression(node.value, node.field.type, true);
    Expression initializer = inferrer.ensureAssignableResult(
        node.field.type, initializerResult,
        fileOffset: node.fileOffset);
    node.value = initializer..parent = node;
  }

  ForInResult handleForInDeclaringVariable(
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

    ExpressionInferenceResult iterableResult = inferForInIterable(
        iterable, elementType, typeNeeded || typeChecksNeeded,
        isAsync: isAsync);
    DartType inferredType = iterableResult.inferredType;
    if (typeNeeded) {
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          variable.fileOffset,
          'type',
          new InstrumentationValueForType(inferredType));
      variable.type = inferredType;
    }

    if (body != null) {
      inferrer.flowAnalysis
          .forEach_bodyBegin(body?.parent, variable, variable.type);
      StatementInferenceResult bodyResult = inferrer.inferStatement(body);
      if (bodyResult.hasChanged) {
        body = bodyResult.statement;
      }
      inferrer.flowAnalysis.forEach_end();
    }

    VariableDeclaration tempVariable =
        new VariableDeclaration(null, type: inferredType, isFinal: true);
    VariableGet variableGet = new VariableGet(tempVariable)
      ..fileOffset = variable.fileOffset;
    TreeNode parent = variable.parent;
    Expression implicitDowncast = inferrer.ensureAssignable(
        variable.type, inferredType, variableGet,
        fileOffset: parent.fileOffset,
        template: templateForInLoopElementTypeNotAssignable);
    if (!identical(implicitDowncast, variableGet)) {
      variable.initializer = implicitDowncast..parent = variable;
      if (body == null) {
        assert(
            parent is ForInElement || parent is ForInMapEntry,
            "Unexpected missing for-in body for "
            "$parent (${parent.runtimeType}).");
        body = variable;
      } else {
        body = combineStatements(variable, body);
      }
      variable = tempVariable;
    }
    return new ForInResult(variable, iterableResult.expression, body);
  }

  ExpressionInferenceResult inferForInIterable(
      Expression iterable, DartType elementType, bool typeNeeded,
      {bool isAsync: false}) {
    Class iterableClass = isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context = inferrer.wrapType(elementType, iterableClass);
    ExpressionInferenceResult iterableResult = inferrer
        .inferExpression(iterable, context, typeNeeded, isVoidAllowed: false);
    DartType iterableType = iterableResult.inferredType;
    iterable = iterableResult.expression;
    DartType inferredExpressionType =
        inferrer.resolveTypeParameter(iterableType);
    iterable = inferrer.ensureAssignable(
        inferrer.wrapType(const DynamicType(), iterableClass),
        inferredExpressionType,
        iterable,
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
    return new ExpressionInferenceResult(inferredType, iterable);
  }

  ForInResult handleForInWithoutVariable(
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
    // TODO(johnniwinther): Refactor handling of synthetic assignment to avoid
    // case handling here.
    Expression syntheticAssignment = statementExpression;
    VariableSet syntheticVariableSet;
    PropertySet syntheticPropertySet;
    SuperPropertySet syntheticSuperPropertySet;
    StaticSet syntheticStaticSet;
    if (syntheticAssignment is VariableSet) {
      syntheticVariableSet = syntheticAssignment;
      syntheticWriteType = elementType = syntheticVariableSet.variable.type;
      rhs = syntheticVariableSet.value;
      // This expression is fully handled in this method so we should not
      // visit the synthetic statement.
      skipStatement = true;
    } else if (syntheticAssignment is PropertySet) {
      syntheticPropertySet = syntheticAssignment;
      ExpressionInferenceResult receiverResult = inferrer.inferExpression(
          syntheticPropertySet.receiver, const UnknownType(), true);
      syntheticPropertySet.receiver = receiverResult.expression
        ..parent = syntheticPropertySet;
      DartType receiverType = receiverResult.inferredType;
      ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
          receiverType,
          syntheticPropertySet.name,
          syntheticPropertySet.fileOffset,
          setter: true,
          instrumented: true,
          includeExtensionMethods: true);
      syntheticWriteType =
          elementType = inferrer.getSetterType(writeTarget, receiverType);
      Expression error = inferrer.reportMissingInterfaceMember(
          writeTarget,
          receiverType,
          syntheticPropertySet.name,
          syntheticPropertySet.fileOffset,
          templateUndefinedSetter);
      if (error != null) {
        rhs = error;
      } else {
        if (writeTarget.isInstanceMember) {
          if (inferrer.instrumentation != null &&
              receiverType == const DynamicType()) {
            inferrer.instrumentation.record(
                inferrer.uriForInstrumentation,
                syntheticPropertySet.fileOffset,
                'target',
                new InstrumentationValueForMember(writeTarget.member));
          }
          syntheticPropertySet.interfaceTarget = writeTarget.member;
        }
        rhs = syntheticPropertySet.value;
      }
    } else if (syntheticAssignment is SuperPropertySet) {
      syntheticSuperPropertySet = syntheticAssignment;
      DartType receiverType = inferrer.thisType;
      ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
          receiverType,
          syntheticSuperPropertySet.name,
          syntheticSuperPropertySet.fileOffset,
          setter: true,
          instrumented: true);
      if (writeTarget.isInstanceMember) {
        syntheticSuperPropertySet.interfaceTarget = writeTarget.member;
      }
      syntheticWriteType =
          elementType = inferrer.getSetterType(writeTarget, receiverType);
      rhs = syntheticSuperPropertySet.value;
    } else if (syntheticAssignment is StaticSet) {
      syntheticStaticSet = syntheticAssignment;
      syntheticWriteType = elementType = syntheticStaticSet.target.setterType;
      rhs = syntheticStaticSet.value;
    } else if (syntheticAssignment is InvalidExpression) {
      elementType = const UnknownType();
    } else {
      unhandled(
          "${syntheticAssignment.runtimeType}",
          "handleForInStatementWithoutVariable",
          syntheticAssignment.fileOffset,
          inferrer.helper.uri);
    }

    ExpressionInferenceResult iterableResult = inferForInIterable(
        iterable, elementType, typeChecksNeeded,
        isAsync: isAsync);
    DartType inferredType = iterableResult.inferredType;
    if (typeChecksNeeded) {
      variable.type = inferredType;
    }

    inferrer.flowAnalysis
        .forEach_bodyBegin(body.parent, variable, variable.type);
    if (body is Block) {
      Block block = body;
      List<Statement> result;
      for (int index = 0; index < block.statements.length; index++) {
        Statement statement = block.statements[index];
        if (!skipStatement || statement != syntheticStatement) {
          StatementInferenceResult statementResult =
              inferrer.inferStatement(statement);
          if (statementResult.hasChanged) {
            if (result == null) {
              result = <Statement>[];
              result.addAll(block.statements.sublist(0, index));
            }
            if (statementResult.statementCount == 1) {
              result.add(statementResult.statement);
            } else {
              result.addAll(statementResult.statements);
            }
          }
        } else if (result != null) {
          result.add(statement);
        }
      }
      if (result != null) {
        body = new Block(result)..fileOffset = body.fileOffset;
      }
    } else {
      if (!skipStatement) {
        StatementInferenceResult bodyResult = inferrer.inferStatement(body);
        if (bodyResult.hasChanged) {
          body = bodyResult.statement;
        }
      }
    }
    inferrer.flowAnalysis.forEach_end();

    if (syntheticWriteType != null) {
      rhs = inferrer.ensureAssignable(
          greatestClosure(inferrer.coreTypes, syntheticWriteType),
          variable.type,
          rhs,
          template: templateForInLoopElementTypeNotAssignable,
          isVoidAllowed: true);
      if (syntheticVariableSet != null) {
        syntheticVariableSet.value = rhs..parent = syntheticVariableSet;
      } else if (syntheticPropertySet != null) {
        syntheticPropertySet.value = rhs..parent = syntheticPropertySet;
      } else if (syntheticSuperPropertySet != null) {
        syntheticSuperPropertySet.value = rhs
          ..parent = syntheticSuperPropertySet;
      } else if (syntheticStaticSet != null) {
        syntheticStaticSet.value = rhs..parent = syntheticStaticSet;
      }
    }
    return new ForInResult(variable, iterableResult.expression, body);
  }

  @override
  StatementInferenceResult visitForInStatement(ForInStatement node) {
    ForInResult result;
    if (node.variable.name == null) {
      result = handleForInWithoutVariable(
          node.variable, node.iterable, node.body,
          isAsync: node.isAsync);
    } else {
      result = handleForInDeclaringVariable(
          node.variable, node.iterable, node.body,
          isAsync: node.isAsync);
    }
    node.variable = result.variable..parent = node;
    node.iterable = result.iterable..parent = node;
    node.body = result.body..parent = node;
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitForStatement(ForStatement node) {
    List<VariableDeclaration> variables;
    for (int index = 0; index < node.variables.length; index++) {
      VariableDeclaration variable = node.variables[index];
      if (variable.name == null) {
        if (variable.initializer != null) {
          ExpressionInferenceResult result = inferrer.inferExpression(
              variable.initializer, const UnknownType(), true,
              isVoidAllowed: true);
          variable.initializer = result.expression..parent = variable;
          variable.type = result.inferredType;
        }
      } else {
        StatementInferenceResult variableResult =
            inferrer.inferStatement(variable);
        if (variableResult.hasChanged) {
          if (variables == null) {
            variables = <VariableDeclaration>[];
            variables.addAll(node.variables.sublist(0, index));
          }
          if (variableResult.statementCount == 1) {
            variables.add(variableResult.statement);
          } else {
            for (VariableDeclaration variable in variableResult.statements) {
              variables.add(variable);
            }
          }
        } else if (variables != null) {
          variables.add(variable);
        }
      }
    }
    if (variables != null) {
      node.variables.clear();
      node.variables.addAll(variables);
      setParents(variables, node);
    }
    inferrer.flowAnalysis.for_conditionBegin(node);
    if (node.condition != null) {
      InterfaceType expectedType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          node.condition, expectedType, !inferrer.isTopLevel,
          isVoidAllowed: true);
      Expression condition =
          inferrer.ensureAssignableResult(expectedType, conditionResult);
      node.condition = condition..parent = node;
    }

    inferrer.flowAnalysis.for_bodyBegin(node.body, node.condition);
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    inferrer.flowAnalysis.for_updaterBegin();
    for (int index = 0; index < node.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferrer.inferExpression(
          node.updates[index], const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true);
      node.updates[index] = updateResult.expression..parent = node;
    }
    inferrer.flowAnalysis.for_end();
    return const StatementInferenceResult();
  }

  DartType visitFunctionNode(FunctionNode node, DartType typeContext,
      DartType returnContext, int returnTypeInstrumentationOffset) {
    return inferrer.inferLocalFunction(
        node, typeContext, returnTypeInstrumentationOffset, returnContext);
  }

  @override
  StatementInferenceResult visitFunctionDeclaration(
      covariant FunctionDeclarationImpl node) {
    inferrer.flowAnalysis.functionExpression_begin(node);
    inferrer.inferMetadataKeepingHelper(
        node.variable, node.variable.annotations);
    DartType returnContext =
        node._hasImplicitReturnType ? null : node.function.returnType;
    DartType inferredType =
        visitFunctionNode(node.function, null, returnContext, node.fileOffset);
    node.variable.type = inferredType;
    inferrer.flowAnalysis.functionExpression_end();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitFunctionExpression(
      FunctionExpression node, DartType typeContext) {
    inferrer.flowAnalysis.functionExpression_begin(node);
    DartType inferredType =
        visitFunctionNode(node.function, typeContext, null, node.fileOffset);
    inferrer.flowAnalysis.functionExpression_end();
    return new ExpressionInferenceResult(inferredType, node);
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

  ExpressionInferenceResult visitIfNullExpression(
      IfNullExpression node, DartType typeContext) {
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    ExpressionInferenceResult lhsResult = inferrer
        .inferExpression(node.left, typeContext, true, isVoidAllowed: false);

    Member equalsMember = inferrer
        .findInterfaceMember(
            lhsResult.inferredType, equalsName, node.fileOffset)
        .member;

    inferrer.flowAnalysis.ifNullExpression_rightBegin(node.left);
    // - Let J = T0 if K is `?` else K.
    // - Infer e1 in context J to get T1
    ExpressionInferenceResult rhsResult;
    if (typeContext is UnknownType) {
      rhsResult = inferrer.inferExpression(
          node.right, lhsResult.inferredType, true,
          isVoidAllowed: true);
    } else {
      rhsResult = inferrer.inferExpression(node.right, typeContext, true,
          isVoidAllowed: true);
    }
    inferrer.flowAnalysis.ifNullExpression_end();

    // - Let T = greatest closure of K with respect to `?` if K is not `_`, else
    //   UP(t0, t1)
    // - Then the inferred type is T.
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(lhsResult.inferredType, rhsResult.inferredType);
    VariableDeclaration variable =
        createVariable(lhsResult.expression, lhsResult.inferredType);
    MethodInvocation equalsNull = createEqualsNull(
        lhsResult.expression.fileOffset,
        createVariableGet(variable),
        equalsMember);
    ConditionalExpression conditional = new ConditionalExpression(equalsNull,
        rhsResult.expression, createVariableGet(variable), inferredType);
    Expression replacement = new Let(variable, conditional)
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  StatementInferenceResult visitIfStatement(IfStatement node) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult conditionResult = inferrer.inferExpression(
        node.condition, expectedType, !inferrer.isTopLevel,
        isVoidAllowed: true);
    Expression condition =
        inferrer.ensureAssignableResult(expectedType, conditionResult);
    node.condition = condition..parent = node;
    inferrer.flowAnalysis.ifStatement_thenBegin(condition);
    StatementInferenceResult thenResult = inferrer.inferStatement(node.then);
    if (thenResult.hasChanged) {
      node.then = thenResult.statement..parent = node;
    }
    if (node.otherwise != null) {
      inferrer.flowAnalysis.ifStatement_elseBegin();
      StatementInferenceResult otherwiseResult =
          inferrer.inferStatement(node.otherwise);
      if (otherwiseResult.hasChanged) {
        node.otherwise = otherwiseResult.statement..parent = node;
      }
    }
    inferrer.flowAnalysis.ifStatement_end(node.otherwise != null);
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitIntJudgment(
      IntJudgment node, DartType typeContext) {
    if (inferrer.isDoubleContext(typeContext)) {
      double doubleValue = node.asDouble();
      if (doubleValue != null) {
        Expression replacement = new DoubleLiteral(doubleValue)
          ..fileOffset = node.fileOffset;
        DartType inferredType =
            inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }
    Expression error = checkWebIntLiteralsErrorIfUnexact(
        inferrer, node.value, node.literal, node.fileOffset);
    if (error != null) {
      return new ExpressionInferenceResult(const DynamicType(), error);
    }
    DartType inferredType =
        inferrer.coreTypes.intRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitShadowLargeIntLiteral(
      ShadowLargeIntLiteral node, DartType typeContext) {
    if (inferrer.isDoubleContext(typeContext)) {
      double doubleValue = node.asDouble();
      if (doubleValue != null) {
        Expression replacement = new DoubleLiteral(doubleValue)
          ..fileOffset = node.fileOffset;
        DartType inferredType =
            inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }

    int intValue = node.asInt64();
    if (intValue == null) {
      Expression replacement = inferrer.helper.buildProblem(
          templateIntegerLiteralIsOutOfRange.withArguments(node.literal),
          node.fileOffset,
          node.literal.length);
      return new ExpressionInferenceResult(const DynamicType(), replacement);
    }
    Expression error = checkWebIntLiteralsErrorIfUnexact(
        inferrer, intValue, node.literal, node.fileOffset);
    if (error != null) {
      return new ExpressionInferenceResult(const DynamicType(), error);
    }
    Expression replacement = new IntLiteral(intValue);
    DartType inferredType =
        inferrer.coreTypes.intRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  void visitShadowInvalidInitializer(ShadowInvalidInitializer node) {
    inferrer.inferExpression(
        node.variable.initializer, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: false);
  }

  void visitShadowInvalidFieldInitializer(ShadowInvalidFieldInitializer node) {
    ExpressionInferenceResult initializerResult = inferrer.inferExpression(
        node.value, node.field.type, !inferrer.isTopLevel,
        isVoidAllowed: false);
    node.value = initializerResult.expression..parent = node;
  }

  @override
  ExpressionInferenceResult visitIsExpression(
      IsExpression node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferrer.inferExpression(
        node.operand, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: false);
    node.operand = operandResult.expression..parent = node;
    inferrer.flowAnalysis
        .isExpression_end(node, node.operand, /*isNot:*/ false, node.type);
    return new ExpressionInferenceResult(
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable), node);
  }

  @override
  StatementInferenceResult visitLabeledStatement(LabeledStatement node) {
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    return const StatementInferenceResult();
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

  ExpressionInferenceResult inferElement(
      Expression element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes,
      bool inferenceNeeded,
      bool typeChecksNeeded) {
    if (element is SpreadElement) {
      ExpressionInferenceResult spreadResult = inferrer.inferExpression(
          element.expression,
          new InterfaceType(inferrer.coreTypes.iterableClass,
              Nullability.legacy, <DartType>[inferredTypeArgument]),
          inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      element.expression = spreadResult.expression..parent = element;
      DartType spreadType = spreadResult.inferredType;
      inferredSpreadTypes[element.expression] = spreadType;
      Expression replacement = element;
      if (typeChecksNeeded) {
        DartType spreadElementType =
            getSpreadElementType(spreadType, element.isNullAware);
        if (spreadElementType == null) {
          if (spreadType is InterfaceType &&
              spreadType.classNode == inferrer.coreTypes.nullClass &&
              !element.isNullAware) {
            replacement = inferrer.helper.buildProblem(
                messageNonNullAwareSpreadIsNull,
                element.expression.fileOffset,
                1);
          } else {
            replacement = inferrer.helper.buildProblem(
                templateSpreadTypeMismatch.withArguments(spreadType),
                element.expression.fileOffset,
                1);
          }
        } else if (spreadType is InterfaceType) {
          if (!inferrer.isAssignable(inferredTypeArgument, spreadElementType)) {
            replacement = inferrer.helper.buildProblem(
                templateSpreadElementTypeMismatch.withArguments(
                    spreadElementType, inferredTypeArgument),
                element.expression.fileOffset,
                1);
          }
        }
      }
      // Use 'dynamic' for error recovery.
      element.elementType =
          getSpreadElementType(spreadType, element.isNullAware) ??
              const DynamicType();
      return new ExpressionInferenceResult(element.elementType, replacement);
    } else if (element is IfElement) {
      DartType boolType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          element.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      Expression condition =
          inferrer.ensureAssignableResult(boolType, conditionResult);
      element.condition = condition..parent = element;
      ExpressionInferenceResult thenResult = inferElement(
          element.then,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      element.then = thenResult.expression..parent = element;
      ExpressionInferenceResult otherwiseResult;
      if (element.otherwise != null) {
        otherwiseResult = inferElement(
            element.otherwise,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        element.otherwise = otherwiseResult.expression..parent = element;
      }
      return new ExpressionInferenceResult(
          otherwiseResult == null
              ? thenResult.inferredType
              : inferrer.typeSchemaEnvironment.getStandardUpperBound(
                  thenResult.inferredType, otherwiseResult.inferredType),
          element);
    } else if (element is ForElement) {
      // TODO(johnniwinther): Use _visitStatements instead.
      List<VariableDeclaration> variables;
      for (int index = 0; index < element.variables.length; index++) {
        VariableDeclaration variable = element.variables[index];
        if (variable.name == null) {
          if (variable.initializer != null) {
            ExpressionInferenceResult initializerResult =
                inferrer.inferExpression(variable.initializer, variable.type,
                    inferenceNeeded || typeChecksNeeded,
                    isVoidAllowed: true);
            variable.initializer = initializerResult.expression
              ..parent = variable;
            variable.type = initializerResult.inferredType;
          }
        } else {
          StatementInferenceResult variableResult =
              inferrer.inferStatement(variable);
          if (variableResult.hasChanged) {
            if (variables == null) {
              variables = <VariableDeclaration>[];
              variables.addAll(element.variables.sublist(0, index));
            }
            if (variableResult.statementCount == 1) {
              variables.add(variableResult.statement);
            } else {
              for (VariableDeclaration variable in variableResult.statements) {
                variables.add(variable);
              }
            }
          } else if (variables != null) {
            variables.add(variable);
          }
        }
      }
      if (variables != null) {
        element.variables.clear();
        element.variables.addAll(variables);
        setParents(variables, element);
      }
      inferrer.flowAnalysis.for_conditionBegin(element);
      if (element.condition != null) {
        ExpressionInferenceResult conditionResult = inferrer.inferExpression(
            element.condition,
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: false);
        element.condition = conditionResult.expression..parent = element;
        inferredConditionTypes[element.condition] =
            conditionResult.inferredType;
      }
      inferrer.flowAnalysis.for_bodyBegin(null, element.condition);
      ExpressionInferenceResult bodyResult = inferElement(
          element.body,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      element.body = bodyResult.expression..parent = element;
      inferrer.flowAnalysis.for_updaterBegin();
      for (int index = 0; index < element.updates.length; index++) {
        ExpressionInferenceResult updateResult = inferrer.inferExpression(
            element.updates[index],
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        element.updates[index] = updateResult.expression..parent = element;
      }
      inferrer.flowAnalysis.for_end();
      return new ExpressionInferenceResult(bodyResult.inferredType, element);
    } else if (element is ForInElement) {
      ForInResult result;
      if (element.variable.name == null) {
        result = handleForInWithoutVariable(
            element.variable, element.iterable, element.prologue,
            isAsync: element.isAsync);
      } else {
        result = handleForInDeclaringVariable(
            element.variable, element.iterable, element.prologue,
            isAsync: element.isAsync);
      }
      element.variable = result.variable..parent = element;
      element.iterable = result.iterable..parent = element;
      // TODO(johnniwinther): Use ?.. here instead.
      element.prologue = result.body;
      result.body?.parent = element;
      if (element.problem != null) {
        ExpressionInferenceResult problemResult = inferrer.inferExpression(
            element.problem,
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        element.problem = problemResult.expression..parent = element;
      }
      inferrer.flowAnalysis
          .forEach_bodyBegin(element, element.variable, element.variable.type);
      ExpressionInferenceResult bodyResult = inferElement(
          element.body,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      element.body = bodyResult.expression..parent = element;
      inferrer.flowAnalysis.forEach_end();
      return new ExpressionInferenceResult(bodyResult.inferredType, element);
    } else {
      ExpressionInferenceResult result = inferrer.inferExpression(
          element, inferredTypeArgument, inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      Expression replacement;
      if (inferredTypeArgument is! UnknownType) {
        replacement = inferrer.ensureAssignableResult(
            inferredTypeArgument, result,
            isVoidAllowed: inferredTypeArgument is VoidType);
      } else {
        replacement = result.expression;
      }
      return new ExpressionInferenceResult(result.inferredType, replacement);
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
        Expression expression = inferrer.ensureAssignable(
            inferrer.coreTypes.iterableRawType(
                inferrer.library.nullableIfTrue(item.isNullAware)),
            spreadType,
            item.expression);
        item.expression = expression..parent = item;
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
        Expression condition = inferrer.ensureAssignable(
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            conditionType,
            item.condition);
        item.condition = condition..parent = item;
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
    InterfaceType listType = inferrer.coreTypes
        .thisInterfaceType(listClass, inferrer.library.nonNullable);
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
      for (int index = 0; index < node.expressions.length; ++index) {
        ExpressionInferenceResult result = inferElement(
            node.expressions[index],
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        node.expressions[index] = result.expression..parent = node;
        actualTypes.add(result.inferredType);
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
          inferrer.uriForInstrumentation,
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
    DartType inferredType = new InterfaceType(
        listClass, Nullability.legacy, [inferredTypeArgument]);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (inferenceNeeded) {
        library.checkBoundsInListLiteral(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }

    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitLogicalExpression(
      LogicalExpression node, DartType typeContext) {
    InterfaceType boolType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult leftResult = inferrer.inferExpression(
        node.left, boolType, !inferrer.isTopLevel,
        isVoidAllowed: false);
    Expression left = inferrer.ensureAssignableResult(boolType, leftResult);
    node.left = left..parent = node;
    inferrer.flowAnalysis
        .logicalBinaryOp_rightBegin(node.left, isAnd: node.operator == '&&');
    ExpressionInferenceResult rightResult = inferrer.inferExpression(
        node.right, boolType, !inferrer.isTopLevel,
        isVoidAllowed: false);
    Expression right = inferrer.ensureAssignableResult(boolType, rightResult);
    node.right = right..parent = node;
    inferrer.flowAnalysis
        .logicalBinaryOp_end(node, node.right, isAnd: node.operator == '&&');
    return new ExpressionInferenceResult(boolType, node);
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
  MapEntry inferMapEntry(
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
      entry.expression = spreadResult.expression..parent = entry;
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

      MapEntry replacement = entry;
      if (typeChecksNeeded) {
        if (actualKeyType == null) {
          if (spreadType is InterfaceType &&
              spreadType.classNode == inferrer.coreTypes.nullClass &&
              !entry.isNullAware) {
            replacement = new MapEntry(
                inferrer.helper.buildProblem(messageNonNullAwareSpreadIsNull,
                    entry.expression.fileOffset, 1),
                new NullLiteral())
              ..fileOffset = entry.fileOffset;
          } else if (actualElementType != null) {
            // Don't report the error here, it might be an ambiguous Set.  The
            // error is reported in checkMapEntry if it's disambiguated as map.
            iterableSpreadType = spreadType;
          } else {
            replacement = new MapEntry(
                inferrer.helper.buildProblem(
                    templateSpreadMapEntryTypeMismatch
                        .withArguments(spreadType),
                    entry.expression.fileOffset,
                    1),
                new NullLiteral())
              ..fileOffset = entry.fileOffset;
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
            replacement = new MapEntry(keyError, valueError)
              ..fileOffset = entry.fileOffset;
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
      entry.entryType = new InterfaceType(mapEntryClass, Nullability.legacy,
          <DartType>[actualKeyType, actualValueType]);

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

      return replacement;
    } else if (entry is IfMapEntry) {
      DartType boolType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          entry.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      Expression condition =
          inferrer.ensureAssignableResult(boolType, conditionResult);
      entry.condition = condition..parent = entry;
      // Note that this recursive invocation of inferMapEntry will add two types
      // to actualTypes; they are the actual types of the current invocation if
      // the 'else' branch is empty.
      MapEntry then = inferMapEntry(
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
      entry.then = then..parent = entry;
      MapEntry otherwise;
      if (entry.otherwise != null) {
        // We need to modify the actual types added in the recursive call to
        // inferMapEntry.
        DartType actualValueType = actualTypes.removeLast();
        DartType actualKeyType = actualTypes.removeLast();
        DartType actualTypeForSet = actualTypesForSet.removeLast();
        otherwise = inferMapEntry(
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
        entry.otherwise = otherwise..parent = entry;
      }
      return entry;
    } else if (entry is ForMapEntry) {
      // TODO(johnniwinther): Use _visitStatements instead.
      List<VariableDeclaration> variables;
      for (int index = 0; index < entry.variables.length; index++) {
        VariableDeclaration variable = entry.variables[index];
        if (variable.name == null) {
          if (variable.initializer != null) {
            ExpressionInferenceResult result = inferrer.inferExpression(
                variable.initializer,
                variable.type,
                inferenceNeeded || typeChecksNeeded,
                isVoidAllowed: true);
            variable.initializer = result.expression..parent = variable;
            variable.type = result.inferredType;
          }
        } else {
          StatementInferenceResult variableResult =
              inferrer.inferStatement(variable);
          if (variableResult.hasChanged) {
            if (variables == null) {
              variables = <VariableDeclaration>[];
              variables.addAll(entry.variables.sublist(0, index));
            }
            if (variableResult.statementCount == 1) {
              variables.add(variableResult.statement);
            } else {
              for (VariableDeclaration variable in variableResult.statements) {
                variables.add(variable);
              }
            }
          } else if (variables != null) {
            variables.add(variable);
          }
        }
      }
      if (variables != null) {
        entry.variables.clear();
        entry.variables.addAll(variables);
        setParents(variables, entry);
      }
      inferrer.flowAnalysis.for_conditionBegin(entry);
      if (entry.condition != null) {
        ExpressionInferenceResult conditionResult = inferrer.inferExpression(
            entry.condition,
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: false);
        entry.condition = conditionResult.expression..parent = entry;
        // TODO(johnniwinther): Ensure assignability of condition?
        inferredConditionTypes[entry.condition] = conditionResult.inferredType;
      }
      inferrer.flowAnalysis.for_bodyBegin(null, entry.condition);
      // Actual types are added by the recursive call.
      MapEntry body = inferMapEntry(
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
      entry.body = body..parent = entry;
      inferrer.flowAnalysis.for_updaterBegin();
      for (int index = 0; index < entry.updates.length; index++) {
        ExpressionInferenceResult updateResult = inferrer.inferExpression(
            entry.updates[index],
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        entry.updates[index] = updateResult.expression..parent = entry;
      }
      inferrer.flowAnalysis.for_end();
      return entry;
    } else if (entry is ForInMapEntry) {
      ForInResult result;
      if (entry.variable.name == null) {
        result = handleForInWithoutVariable(
            entry.variable, entry.iterable, entry.prologue,
            isAsync: entry.isAsync);
      } else {
        result = handleForInDeclaringVariable(
            entry.variable, entry.iterable, entry.prologue,
            isAsync: entry.isAsync);
      }
      entry.variable = result.variable..parent = entry;
      entry.iterable = result.iterable..parent = entry;
      // TODO(johnniwinther): Use ?.. here instead.
      entry.prologue = result.body;
      result.body?.parent = entry;
      if (entry.problem != null) {
        ExpressionInferenceResult problemResult = inferrer.inferExpression(
            entry.problem,
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        entry.problem = problemResult.expression..parent = entry;
      }
      inferrer.flowAnalysis
          .forEach_bodyBegin(entry, entry.variable, entry.variable.type);
      // Actual types are added by the recursive call.
      MapEntry body = inferMapEntry(
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
      entry.body = body..parent = entry;
      inferrer.flowAnalysis.forEach_end();
      return entry;
    } else {
      ExpressionInferenceResult keyResult = inferrer.inferExpression(
          entry.key, inferredKeyType, true,
          isVoidAllowed: true);
      Expression key = inferrer.ensureAssignableResult(
          inferredKeyType, keyResult,
          isVoidAllowed: inferredKeyType is VoidType);
      entry.key = key..parent = entry;
      ExpressionInferenceResult valueResult = inferrer.inferExpression(
          entry.value, inferredValueType, true,
          isVoidAllowed: true);
      Expression value = inferrer.ensureAssignableResult(
          inferredValueType, valueResult,
          isVoidAllowed: inferredValueType is VoidType);
      entry.value = value..parent = entry;
      actualTypes.add(keyResult.inferredType);
      actualTypes.add(valueResult.inferredType);
      // Use 'dynamic' for error recovery.
      actualTypesForSet.add(const DynamicType());
      mapEntryOffset = entry.fileOffset;
      return entry;
    }
  }

  MapEntry checkMapEntry(
      MapEntry entry,
      DartType keyType,
      DartType valueType,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    // It's disambiguated as a map literal.
    MapEntry replacement = entry;
    if (iterableSpreadOffset != null) {
      replacement = new MapEntry(
          inferrer.helper.buildProblem(
              templateSpreadMapEntryTypeMismatch
                  .withArguments(iterableSpreadType),
              iterableSpreadOffset,
              1),
          new NullLiteral());
    }
    if (entry is SpreadMapEntry) {
      DartType spreadType = inferredSpreadTypes[entry.expression];
      if (spreadType is DynamicType) {
        Expression expression = inferrer.ensureAssignable(
            inferrer.coreTypes
                .mapRawType(inferrer.library.nullableIfTrue(entry.isNullAware)),
            spreadType,
            entry.expression);
        entry.expression = expression..parent = entry;
      }
    } else if (entry is IfMapEntry) {
      MapEntry then = checkMapEntry(entry.then, keyType, valueType,
          inferredSpreadTypes, inferredConditionTypes);
      entry.then = then..parent = entry;
      if (entry.otherwise != null) {
        MapEntry otherwise = checkMapEntry(entry.otherwise, keyType, valueType,
            inferredSpreadTypes, inferredConditionTypes);
        entry.otherwise = otherwise..parent = entry;
      }
    } else if (entry is ForMapEntry) {
      if (entry.condition != null) {
        DartType conditionType = inferredConditionTypes[entry.condition];
        Expression condition = inferrer.ensureAssignable(
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            conditionType,
            entry.condition);
        entry.condition = condition..parent = entry;
      }
      MapEntry body = checkMapEntry(entry.body, keyType, valueType,
          inferredSpreadTypes, inferredConditionTypes);
      entry.body = body..parent = entry;
    } else if (entry is ForInMapEntry) {
      MapEntry body = checkMapEntry(entry.body, keyType, valueType,
          inferredSpreadTypes, inferredConditionTypes);
      entry.body = body..parent = entry;
    } else {
      // Do nothing.  Assignability checks are done during type inference.
    }
    return replacement;
  }

  @override
  ExpressionInferenceResult visitMapLiteral(
      MapLiteral node, DartType typeContext) {
    Class mapClass = inferrer.coreTypes.mapClass;
    InterfaceType mapType = inferrer.coreTypes
        .thisInterfaceType(mapClass, inferrer.library.nonNullable);
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
          return visitSetLiteral(setLiteral, typeContext);
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
            Nullability.legacy, <DartType>[inferredKeyType, inferredValueType]);
      }
      for (int index = 0; index < node.entries.length; ++index) {
        MapEntry entry = node.entries[index];
        entry = inferMapEntry(
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
        node.entries[index] = entry..parent = node;
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
        InterfaceType setType = inferrer.coreTypes.thisInterfaceType(
            inferrer.coreTypes.setClass, inferrer.library.nonNullable);
        for (int i = 0; i < node.entries.length; ++i) {
          setElements.add(convertToElement(node.entries[i], inferrer.helper,
              inferrer.assignedVariables.reassignInfo));
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
            inferrer.coreTypes.thisInterfaceType(
                inferrer.coreTypes.setClass, inferrer.library.nonNullable),
            inferrer.coreTypes.setClass.typeParameters,
            formalTypesForSet,
            actualTypesForSet,
            typeContext,
            inferredTypesForSet);
        DartType inferredTypeArgument = inferredTypesForSet[0];
        inferrer.instrumentation?.record(
            inferrer.uriForInstrumentation,
            node.fileOffset,
            'typeArgs',
            new InstrumentationValueForTypeArgs([inferredTypeArgument]));

        SetLiteral setLiteral = new SetLiteral(setElements,
            typeArgument: inferredTypeArgument, isConst: node.isConst)
          ..fileOffset = node.fileOffset;
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

        DartType inferredType = new InterfaceType(inferrer.coreTypes.setClass,
            Nullability.legacy, inferredTypesForSet);
        return new ExpressionInferenceResult(inferredType, setLiteral);
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        Expression error = inferrer.helper.buildProblem(
            messageCantDisambiguateNotEnoughInformation, node.fileOffset, 1);
        return new ExpressionInferenceResult(const BottomType(), error);
      }
      if (!canBeSet && !canBeMap) {
        Expression replacement = node;
        if (!inferrer.isTopLevel) {
          replacement = inferrer.helper.buildProblem(
              messageCantDisambiguateAmbiguousInformation, node.fileOffset, 1);
        }
        return new ExpressionInferenceResult(const BottomType(), replacement);
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
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs(
              [inferredKeyType, inferredValueType]));
      node.keyType = inferredKeyType;
      node.valueType = inferredValueType;
    }
    if (typeChecksNeeded) {
      for (int index = 0; index < node.entries.length; ++index) {
        MapEntry entry = checkMapEntry(node.entries[index], node.keyType,
            node.valueType, inferredSpreadTypes, inferredConditionTypes);
        node.entries[index] = entry..parent = node;
      }
    }
    DartType inferredType = new InterfaceType(
        mapClass, Nullability.legacy, [inferredKeyType, inferredValueType]);
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
    return new ExpressionInferenceResult(inferredType, node);
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
            Expression replacement = new DoubleLiteral(doubleValue)
              ..fileOffset = node.fileOffset;
            DartType inferredType =
                inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
            return new ExpressionInferenceResult(inferredType, replacement);
          }
        }
        Expression error = checkWebIntLiteralsErrorIfUnexact(
            inferrer, receiver.value, receiver.literal, receiver.fileOffset);
        if (error != null) {
          return new ExpressionInferenceResult(const DynamicType(), error);
        }
      } else if (node.receiver is ShadowLargeIntLiteral) {
        ShadowLargeIntLiteral receiver = node.receiver;
        if (!receiver.isParenthesized) {
          if (inferrer.isDoubleContext(typeContext)) {
            double doubleValue = receiver.asDouble(negated: true);
            if (doubleValue != null) {
              Expression replacement = new DoubleLiteral(doubleValue)
                ..fileOffset = node.fileOffset;
              DartType inferredType = inferrer.coreTypes
                  .doubleRawType(inferrer.library.nonNullable);
              return new ExpressionInferenceResult(inferredType, replacement);
            }
          }
          int intValue = receiver.asInt64(negated: true);
          if (intValue == null) {
            Expression error = inferrer.helper.buildProblem(
                templateIntegerLiteralIsOutOfRange
                    .withArguments(receiver.literal),
                receiver.fileOffset,
                receiver.literal.length);
            return new ExpressionInferenceResult(const DynamicType(), error);
          }
          if (intValue != null) {
            Expression error = checkWebIntLiteralsErrorIfUnexact(
                inferrer, intValue, receiver.literal, receiver.fileOffset);
            if (error != null) {
              return new ExpressionInferenceResult(const DynamicType(), error);
            }
            node.receiver = new IntLiteral(-intValue)
              ..fileOffset = node.receiver.fileOffset
              ..parent = node;
          }
        }
      }
    }
    return inferrer.inferMethodInvocation(node, typeContext);
  }

  ExpressionInferenceResult visitNamedFunctionExpressionJudgment(
      NamedFunctionExpressionJudgment node, DartType typeContext) {
    ExpressionInferenceResult initializerResult =
        inferrer.inferExpression(node.variable.initializer, typeContext, true);
    node.variable.initializer = initializerResult.expression
      ..parent = node.variable;
    node.variable.type = initializerResult.inferredType;
    return new ExpressionInferenceResult(initializerResult.inferredType, node);
  }

  @override
  ExpressionInferenceResult visitNot(Not node, DartType typeContext) {
    InterfaceType boolType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult operandResult =
        inferrer.inferExpression(node.operand, boolType, !inferrer.isTopLevel);
    Expression operand = inferrer.ensureAssignableResult(
        boolType, operandResult,
        fileOffset: node.fileOffset);
    node.operand = operand..parent = node;
    inferrer.flowAnalysis.logicalNot_end(node, node.operand);
    return new ExpressionInferenceResult(boolType, node);
  }

  @override
  ExpressionInferenceResult visitNullCheck(
      NullCheck node, DartType typeContext) {
    // TODO(johnniwinther): Should the typeContext for the operand be
    //  `Nullable(typeContext)`?
    ExpressionInferenceResult operandResult = inferrer.inferExpression(
        node.operand, typeContext, !inferrer.isTopLevel);
    node.operand = operandResult.expression..parent = node;
    // TODO(johnniwinther): Check that the inferred type is potentially
    //  nullable.
    inferrer.flowAnalysis.nonNullAssert_end(node.operand);
    // TODO(johnniwinther): Return `NonNull(inferredType)`.
    return new ExpressionInferenceResult(operandResult.inferredType, node);
  }

  ExpressionInferenceResult visitNullAwareMethodInvocation(
      NullAwareMethodInvocation node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.variable);
    ExpressionInferenceResult invocationResult = inferrer.inferExpression(
        node.invocation, typeContext, true,
        isVoidAllowed: true);
    Member equalsMember = inferrer
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
        .member;
    return new ExpressionInferenceResult.nullAware(
        invocationResult.inferredType,
        invocationResult.expression,
        new NullAwareGuard(node.variable, node.fileOffset, equalsMember));
  }

  ExpressionInferenceResult visitNullAwarePropertyGet(
      NullAwarePropertyGet node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.variable);
    ExpressionInferenceResult readResult =
        inferrer.inferExpression(node.read, const UnknownType(), true);
    Member equalsMember = inferrer
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
        .member;
    return new ExpressionInferenceResult.nullAware(
        readResult.inferredType,
        readResult.expression,
        new NullAwareGuard(node.variable, node.fileOffset, equalsMember));
  }

  ExpressionInferenceResult visitNullAwarePropertySet(
      NullAwarePropertySet node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.variable);
    ExpressionInferenceResult writeResult =
        inferrer.inferExpression(node.write, typeContext, true);
    Member equalsMember = inferrer
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
        .member;
    return new ExpressionInferenceResult.nullAware(
        writeResult.inferredType,
        writeResult.expression,
        new NullAwareGuard(node.variable, node.fileOffset, equalsMember));
  }

  ExpressionInferenceResult visitNullAwareExtension(
      NullAwareExtension node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.variable);
    ExpressionInferenceResult expressionResult =
        inferrer.inferExpression(node.expression, const UnknownType(), true);
    Member equalsMember = inferrer
        .findInterfaceMember(node.variable.type, equalsName, node.fileOffset)
        .member;
    return new ExpressionInferenceResult.nullAware(
        expressionResult.inferredType,
        expressionResult.expression,
        new NullAwareGuard(node.variable, node.fileOffset, equalsMember));
  }

  ExpressionInferenceResult visitStaticPostIncDec(
      StaticPostIncDec node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.read);
    inferrer.inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;

    Expression replacement =
        new Let(node.read, createLet(node.write, createVariableGet(node.read)))
          ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitSuperPostIncDec(
      SuperPostIncDec node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.read);
    inferrer.inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;

    Expression replacement =
        new Let(node.read, createLet(node.write, createVariableGet(node.read)))
          ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitLocalPostIncDec(
      LocalPostIncDec node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.read);
    inferrer.inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;
    Expression replacement =
        new Let(node.read, createLet(node.write, createVariableGet(node.read)))
          ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitPropertyPostIncDec(
      PropertyPostIncDec node, DartType typeContext) {
    if (node.variable != null) {
      inferrer.inferSyntheticVariable(node.variable);
    }
    inferrer.inferSyntheticVariable(node.read);
    inferrer.inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;

    Expression replacement;
    if (node.variable != null) {
      replacement = new Let(
          node.variable,
          createLet(
              node.read, createLet(node.write, createVariableGet(node.read))))
        ..fileOffset = node.fileOffset;
    } else {
      replacement = new Let(
          node.read, createLet(node.write, createVariableGet(node.read)))
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitCompoundPropertySet(
      CompoundPropertySet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    NullAwareGuard nullAwareGuard;
    Expression receiver;
    if (inferrer.isNonNullableByDefault) {
      nullAwareGuard = receiverResult.nullAwareGuard;
      receiver = receiverResult.nullAwareAction;
    } else {
      receiver = receiverResult.expression;
    }
    DartType receiverType = receiverResult.inferredType;

    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (node.readOnlyReceiver && identical(receiver, node.receiver)) {
      readReceiver = receiver;
      writeReceiver = receiver.accept<TreeNode>(new CloneVisitor());
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          receiverVariable.fileOffset,
          'type',
          new InstrumentationValueForType(receiverType));
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
        readReceiver, receiverType, node.propertyName, const UnknownType(),
        isThisReceiver: node.receiver is ThisExpression);

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset, read, readType, node.binaryName, node.rhs);
    DartType binaryType = binaryResult.inferredType;

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.propertyName, node.writeOffset,
        setter: true, instrumented: true, includeExtensionMethods: true);
    DartType writeType = inferrer.getSetterType(writeTarget, receiverType);
    Expression binary =
        inferrer.ensureAssignableResult(writeType, binaryResult);

    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        receiverType, node.propertyName, writeTarget, binary,
        valueType: binaryType, forEffect: node.forEffect);

    Expression replacement = write;
    if (receiverVariable != null) {
      replacement = createLet(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult.nullAware(
        binaryType, replacement, nullAwareGuard);
  }

  ExpressionInferenceResult visitIfNullPropertySet(
      IfNullPropertySet node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.variable);
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
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, readResult.expression, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull,
          writeResult.expression,
          new NullLiteral()..fileOffset = node.fileOffset,
          inferredType)
        ..fileOffset = node.fileOffset;
      replacement =
          new Let(node.variable, conditional..fileOffset = node.fileOffset);
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      VariableDeclaration readVariable =
          createVariable(readResult.expression, readResult.inferredType);
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          writeResult.expression, createVariableGet(readVariable), inferredType)
        ..fileOffset = node.fileOffset;
      replacement = new Let(node.variable, createLet(readVariable, conditional))
        ..fileOffset = node.fileOffset;
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
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, readResult.expression, equalsMember);
      replacement = new ConditionalExpression(
          equalsNull,
          writeResult.expression,
          new NullLiteral()..fileOffset = node.fileOffset,
          inferredType)
        ..fileOffset = node.fileOffset;
    } else {
      // Encode `a ??= b` as:
      //
      //      let v1 = a in v1 == null ? a = b : v1
      //
      VariableDeclaration readVariable =
          createVariable(readResult.expression, readResult.inferredType);
      MethodInvocation equalsNull = createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          writeResult.expression, createVariableGet(readVariable), inferredType)
        ..fileOffset = node.fileOffset;
      replacement = new Let(readVariable, conditional)
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIndexSet(IndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    Expression receiver;
    NullAwareGuard nullAwareGuard;
    if (inferrer.isNonNullableByDefault) {
      nullAwareGuard = receiverResult.nullAwareGuard;
      receiver = receiverResult.nullAwareAction;
    } else {
      receiver = receiverResult.expression;
    }
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable;
    if (!node.forEffect && !node.readOnlyReceiver) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget indexSetTarget = inferrer.findInterfaceMember(
        receiverType, indexSetName, node.fileOffset,
        includeExtensionMethods: true);

    DartType indexType = inferrer.getIndexKeyType(indexSetTarget, receiverType);
    DartType valueType =
        inferrer.getIndexSetValueType(indexSetTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index = inferrer.ensureAssignableResult(indexType, indexResult);

    VariableDeclaration indexVariable;
    if (!node.forEffect) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    VariableDeclaration valueVariable;
    if (!node.forEffect) {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment = _computeIndexSet(
        node.fileOffset, receiver, receiverType, indexSetTarget, index, value);

    Expression replacement;
    if (node.forEffect) {
      replacement = assignment;
    } else {
      assert(indexVariable != null);
      assert(valueVariable != null);
      VariableDeclaration assignmentVariable =
          createVariable(assignment, const VoidType());
      replacement = createLet(
          indexVariable,
          createLet(valueVariable,
              createLet(assignmentVariable, createVariableGet(valueVariable))));
      if (receiverVariable != null) {
        replacement = createLet(receiverVariable, replacement);
      }
    }
    replacement..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult.nullAware(
        inferredType, replacement, nullAwareGuard);
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

    Expression index = inferrer.ensureAssignableResult(indexType, indexResult);

    VariableDeclaration indexVariable =
        createVariable(index, indexResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);
    VariableDeclaration valueVariable =
        createVariable(value, valueResult.inferredType);

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment;
    if (indexSetTarget.isMissing) {
      assignment = inferrer.createMissingSuperIndexSet(node.fileOffset,
          createVariableGet(indexVariable), createVariableGet(valueVariable));
    } else {
      assert(indexSetTarget.isInstanceMember);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'target',
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
    Expression replacement = new Let(
        indexVariable,
        createLet(valueVariable,
            createLet(assignmentVariable, createVariableGet(valueVariable))))
      ..fileOffset = node.fileOffset;
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

    Expression receiver =
        inferrer.ensureAssignableResult(receiverType, receiverResult);

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.setter, null, ProcedureKind.Operator, extensionTypeArguments);

    DartType indexType = inferrer.getIndexKeyType(target, receiverType);
    DartType valueType = inferrer.getIndexSetValueType(target, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index = inferrer.ensureAssignableResult(indexType, indexResult);

    VariableDeclaration indexVariable =
        createVariable(index, indexResult.inferredType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);
    VariableDeclaration valueVariable =
        createVariable(value, valueResult.inferredType);

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment = _computeIndexSet(
        node.fileOffset,
        createVariableGet(receiverVariable),
        receiverType,
        target,
        createVariableGet(indexVariable),
        createVariableGet(valueVariable));

    VariableDeclaration assignmentVariable =
        createVariable(assignment, const VoidType());
    Expression replacement = new Let(
        receiverVariable,
        createLet(
            indexVariable,
            createLet(
                valueVariable,
                createLet(
                    assignmentVariable, createVariableGet(valueVariable)))))
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullIndexSet(
      IfNullIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);

    Expression receiver;
    NullAwareGuard nullAwareGuard;
    if (inferrer.isNonNullableByDefault) {
      nullAwareGuard = receiverResult.nullAwareGuard;
      receiver = receiverResult.nullAwareAction;
    } else {
      receiver = receiverResult.expression;
    }
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (node.readOnlyReceiver) {
      writeReceiver = readReceiver.accept<TreeNode>(new CloneVisitor());
    } else {
      receiverVariable = createVariable(readReceiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, indexGetName, node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind checkKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
        includeExtensionMethods: true);

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, receiverType);
    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable = createVariableForResult(indexResult);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(node.readOffset,
        readReceiver, receiverType, readTarget, readIndex, checkKind);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    VariableDeclaration valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(node.writeOffset, writeReceiver,
        receiverType, writeTarget, writeIndex, value);

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
      replacement = new Let(receiverVariable, inner)
        ..fileOffset = node.fileOffset;
    } else {
      replacement = inner;
    }
    return new ExpressionInferenceResult.nullAware(
        inferredType, replacement, nullAwareGuard);
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

    VariableDeclaration indexVariable = createVariableForResult(indexResult);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    Expression read;

    if (readTarget.isMissing) {
      read = inferrer.createMissingSuperIndexGet(node.readOffset, readIndex);
    } else {
      assert(readTarget.isInstanceMember);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.readOffset,
          'target',
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
    if (node.forEffect) {
      // No need for a value variable.
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    Expression write;

    if (writeTarget.isMissing) {
      write = inferrer.createMissingSuperIndexSet(
          node.writeOffset, writeIndex, value);
    } else {
      assert(writeTarget.isInstanceMember);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.writeOffset,
          'target',
          new InstrumentationValueForMember(node.setter));
      write = new SuperMethodInvocation(
          indexSetName,
          new Arguments(<Expression>[writeIndex, value])
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

    Expression receiver =
        inferrer.ensureAssignableResult(receiverType, receiverResult);

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);

    ObjectAccessTarget readTarget = node.getter != null
        ? new ExtensionAccessTarget(
            node.getter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

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

    VariableDeclaration indexVariable = createVariableForResult(indexResult);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(
        node.readOffset,
        createVariableGet(receiverVariable),
        receiverType,
        readTarget,
        readIndex,
        MethodContravarianceCheckKind.none);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(readType, valueResult.inferredType);

    VariableDeclaration valueVariable;
    if (node.forEffect) {
      // No need for a value variable.
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
        node.writeOffset,
        createVariableGet(receiverVariable),
        receiverType,
        writeTarget,
        writeIndex,
        value);

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
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  /// Creates an equals expression of using [left] and [right] as operands.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [leftType] is
  /// the already inferred type of the [left] expression. The inferred type of
  /// [right] is computed by this method. If [isNot] is `true` the result is
  /// negated to perform a != operation.
  ExpressionInferenceResult _computeEqualsExpression(
      int fileOffset, Expression left, DartType leftType, Expression right,
      {bool isNot}) {
    assert(isNot != null);
    inferrer.flowAnalysis.equalityOp_rightBegin(left);
    ObjectAccessTarget equalsTarget = inferrer.findInterfaceMember(
        leftType, equalsName, fileOffset,
        includeExtensionMethods: true);

    bool typeNeeded = !inferrer.isTopLevel;
    ExpressionInferenceResult rightResult = inferrer.inferExpression(
        right, const UnknownType(), typeNeeded,
        isVoidAllowed: false);
    right = rightResult.expression;

    assert(equalsTarget.isInstanceMember);
    if (inferrer.instrumentation != null && leftType == const DynamicType()) {
      inferrer.instrumentation.record(
          inferrer.uriForInstrumentation,
          fileOffset,
          'target',
          new InstrumentationValueForMember(equalsTarget.member));
    }

    Expression equals = new MethodInvocation(
        left,
        equalsName,
        new Arguments(<Expression>[
          right,
        ])
          ..fileOffset = fileOffset,
        equalsTarget.member)
      ..fileOffset = fileOffset;
    if (isNot) {
      equals = new Not(equals)..fileOffset = fileOffset;
    }
    inferrer.flowAnalysis.equalityOp_end(equals, right, notEqual: isNot);
    return new ExpressionInferenceResult(
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable), equals);
  }

  /// Creates a binary expression of the binary operator with [binaryName] using
  /// [left] and [right] as operands.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [leftType] is
  /// the already inferred type of the [left] expression. The inferred type of
  /// [right] is computed by this method.
  ExpressionInferenceResult _computeBinaryExpression(int fileOffset,
      Expression left, DartType leftType, Name binaryName, Expression right) {
    assert(binaryName != equalsName);

    ObjectAccessTarget binaryTarget = inferrer.findInterfaceMember(
        leftType, binaryName, fileOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind binaryCheckKind =
        inferrer.preCheckInvocationContravariance(leftType, binaryTarget,
            isThisReceiver: false);

    DartType binaryType = inferrer.getReturnType(binaryTarget, leftType);
    DartType rightType =
        inferrer.getPositionalParameterTypeForTarget(binaryTarget, leftType, 0);

    bool isOverloadedArithmeticOperatorAndType =
        inferrer.isOverloadedArithmeticOperatorAndType(binaryTarget, leftType);

    bool typeNeeded =
        !inferrer.isTopLevel || isOverloadedArithmeticOperatorAndType;
    ExpressionInferenceResult rightResult = inferrer
        .inferExpression(right, rightType, typeNeeded, isVoidAllowed: true);
    if (rightResult.inferredType == null) {
      assert(!typeNeeded,
          "Missing right type for overloaded arithmetic operator.");
      return new ExpressionInferenceResult(
          binaryType,
          inferrer.engine.forest
              .createBinary(fileOffset, left, binaryName, right));
    }

    right = inferrer.ensureAssignableResult(rightType, rightResult);

    if (isOverloadedArithmeticOperatorAndType) {
      binaryType = inferrer.typeSchemaEnvironment
          .getTypeOfOverloadedArithmetic(leftType, rightResult.inferredType);
    }

    Expression binary;
    if (binaryTarget.isMissing) {
      binary = inferrer.createMissingBinary(
          fileOffset, left, leftType, binaryName, right);
    } else if (binaryTarget.isExtensionMember) {
      assert(binaryTarget.extensionMethodKind != ProcedureKind.Setter);
      binary = new StaticInvocation(
          binaryTarget.member,
          new Arguments(<Expression>[
            left,
            right,
          ], types: binaryTarget.inferredExtensionTypeArguments)
            ..fileOffset = fileOffset)
        ..fileOffset = fileOffset;
    } else {
      if (binaryTarget.isInstanceMember &&
          inferrer.instrumentation != null &&
          leftType == const DynamicType()) {
        inferrer.instrumentation.record(
            inferrer.uriForInstrumentation,
            fileOffset,
            'target',
            new InstrumentationValueForMember(binaryTarget.member));
      }

      binary = new MethodInvocation(
          left,
          binaryName,
          new Arguments(<Expression>[
            right,
          ])
            ..fileOffset = fileOffset,
          binaryTarget.member)
        ..fileOffset = fileOffset;

      if (binaryCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'checkReturn',
              new InstrumentationValueForType(binaryType));
        }
        binary = new AsExpression(binary, binaryType)
          ..isTypeError = true
          ..fileOffset = fileOffset;
      }
    }
    return new ExpressionInferenceResult(binaryType, binary);
  }

  /// Creates a unary expression of the unary operator with [unaryName] using
  /// [expression] as the operand.
  ///
  /// [fileOffset] is used as the file offset for created nodes.
  /// [expressionType] is the already inferred type of the [expression].
  ExpressionInferenceResult _computeUnaryExpression(int fileOffset,
      Expression expression, DartType expressionType, Name unaryName) {
    ObjectAccessTarget unaryTarget = inferrer.findInterfaceMember(
        expressionType, unaryName, fileOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind unaryCheckKind =
        inferrer.preCheckInvocationContravariance(expressionType, unaryTarget,
            isThisReceiver: false);

    DartType unaryType = inferrer.getReturnType(unaryTarget, expressionType);

    Expression unary;
    if (unaryTarget.isMissing) {
      unary = inferrer.createMissingUnary(
          fileOffset, expression, expressionType, unaryName);
    } else if (unaryTarget.isExtensionMember) {
      assert(unaryTarget.extensionMethodKind != ProcedureKind.Setter);
      unary = new StaticInvocation(
          unaryTarget.member,
          new Arguments(<Expression>[
            expression,
          ], types: unaryTarget.inferredExtensionTypeArguments)
            ..fileOffset = fileOffset)
        ..fileOffset = fileOffset;
    } else {
      if (unaryTarget.isInstanceMember &&
          inferrer.instrumentation != null &&
          expressionType == const DynamicType()) {
        inferrer.instrumentation.record(
            inferrer.uriForInstrumentation,
            fileOffset,
            'target',
            new InstrumentationValueForMember(unaryTarget.member));
      }

      unary = new MethodInvocation(
          expression,
          unaryName,
          new Arguments(<Expression>[])..fileOffset = fileOffset,
          unaryTarget.member)
        ..fileOffset = fileOffset;

      if (unaryCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'checkReturn',
              new InstrumentationValueForType(expressionType));
        }
        unary = new AsExpression(unary, unaryType)
          ..isTypeError = true
          ..fileOffset = fileOffset;
      }
    }
    return new ExpressionInferenceResult(unaryType, unary);
  }

  /// Creates an index operation of [readTarget] on [receiver] using [index] as
  /// the argument.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [receiverType]
  /// is the already inferred type of the [receiver] expression. The inferred
  /// type of [index] must already have been computed.
  ExpressionInferenceResult _computeIndexGet(
      int fileOffset,
      Expression readReceiver,
      DartType receiverType,
      ObjectAccessTarget readTarget,
      Expression readIndex,
      MethodContravarianceCheckKind readCheckKind) {
    Expression read;
    DartType readType = inferrer.getReturnType(readTarget, receiverType);
    if (readTarget.isMissing) {
      read = inferrer.createMissingIndexGet(
          fileOffset, readReceiver, receiverType, readIndex);
    } else if (readTarget.isExtensionMember) {
      read = new StaticInvocation(
          readTarget.member,
          new Arguments(<Expression>[
            readReceiver,
            readIndex,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = fileOffset)
        ..fileOffset = fileOffset;
    } else {
      read = new MethodInvocation(
          readReceiver,
          indexGetName,
          new Arguments(<Expression>[
            readIndex,
          ])
            ..fileOffset = fileOffset,
          readTarget.member)
        ..fileOffset = fileOffset;
      if (readCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'checkReturn',
              new InstrumentationValueForType(readType));
        }
        read = new AsExpression(read, readType)
          ..isTypeError = true
          ..fileOffset = fileOffset;
      }
    }
    return new ExpressionInferenceResult(readType, read);
  }

  /// Creates an index set operation of [writeTarget] on [receiver] using
  /// [index] and [value] as the arguments.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [receiverType]
  /// is the already inferred type of the [receiver] expression. The inferred
  /// type of [index] and [value] must already have been computed.
  Expression _computeIndexSet(
      int fileOffset,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget writeTarget,
      Expression index,
      Expression value) {
    Expression write;
    if (writeTarget.isMissing) {
      write = inferrer.createMissingIndexSet(
          fileOffset, receiver, receiverType, index, value);
    } else if (writeTarget.isExtensionMember) {
      assert(writeTarget.extensionMethodKind != ProcedureKind.Setter);
      write = new StaticInvocation(
          writeTarget.member,
          new Arguments(<Expression>[receiver, index, value],
              types: writeTarget.inferredExtensionTypeArguments)
            ..fileOffset = fileOffset)
        ..fileOffset = fileOffset;
    } else {
      write = new MethodInvocation(
          receiver,
          indexSetName,
          new Arguments(<Expression>[index, value])..fileOffset = fileOffset,
          writeTarget.member)
        ..fileOffset = fileOffset;
    }
    return write;
  }

  /// Creates a property get of [propertyName] on [receiver] of type
  /// [receiverType].
  ///
  /// [fileOffset] is used as the file offset for created nodes. [receiverType]
  /// is the already inferred type of the [receiver] expression. The
  /// [typeContext] is used to create implicit generic tearoff instantiation
  /// if necessary. [isThisReceiver] must be set to `true` if the receiver is a
  /// `this` expression.
  ExpressionInferenceResult _computePropertyGet(
      int fileOffset,
      Expression receiver,
      DartType receiverType,
      Name propertyName,
      DartType typeContext,
      {bool isThisReceiver}) {
    assert(isThisReceiver != null);

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, propertyName, fileOffset,
        includeExtensionMethods: true);

    DartType readType = inferrer.getGetterType(readTarget, receiverType);

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.createMissingPropertyGet(
          fileOffset, receiver, receiverType, propertyName);
    } else if (readTarget.isExtensionMember) {
      switch (readTarget.extensionMethodKind) {
        case ProcedureKind.Getter:
          read = new StaticInvocation(
              readTarget.member,
              new Arguments(<Expression>[
                receiver,
              ], types: readTarget.inferredExtensionTypeArguments)
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
          break;
        case ProcedureKind.Method:
          read = new StaticInvocation(
              readTarget.tearoffTarget,
              new Arguments(<Expression>[
                receiver,
              ], types: readTarget.inferredExtensionTypeArguments)
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
          return inferrer.instantiateTearOff(readType, typeContext, read);
        case ProcedureKind.Setter:
        case ProcedureKind.Factory:
        case ProcedureKind.Operator:
          unhandled('$readTarget', "inferPropertyGet", null, null);
          break;
      }
    } else {
      if (readTarget.isInstanceMember &&
          inferrer.instrumentation != null &&
          receiverType == const DynamicType()) {
        inferrer.instrumentation.record(
            inferrer.uriForInstrumentation,
            fileOffset,
            'target',
            new InstrumentationValueForMember(readTarget.member));
      }
      read = new PropertyGet(receiver, propertyName, readTarget.member)
        ..fileOffset = fileOffset;
      bool checkReturn = false;
      if (readTarget.isInstanceMember && !isThisReceiver) {
        Member interfaceMember = readTarget.member;
        if (interfaceMember is Procedure) {
          checkReturn =
              TypeInferrerImpl.returnedTypeParametersOccurNonCovariantly(
                  interfaceMember.enclosingClass,
                  interfaceMember.function.returnType);
        } else if (interfaceMember is Field) {
          checkReturn =
              TypeInferrerImpl.returnedTypeParametersOccurNonCovariantly(
                  interfaceMember.enclosingClass, interfaceMember.type);
        }
      }
      if (checkReturn) {
        if (inferrer.instrumentation != null) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'checkReturn',
              new InstrumentationValueForType(readType));
        }
        read = new AsExpression(read, readType)
          ..isTypeError = true
          ..fileOffset = fileOffset;
      }
      Member member = readTarget.member;
      if (member is Procedure && member.kind == ProcedureKind.Method) {
        return inferrer.instantiateTearOff(readType, typeContext, read);
      }
    }
    return new ExpressionInferenceResult(readType, read);
  }

  /// Creates a property set operation of [writeTarget] on [receiver] using
  /// [value] as the right-hand side.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [propertyName]
  /// is used for error reporting. [receiverType] is the already inferred type
  /// of the [receiver] expression. The inferred type of [value] must already
  /// have been computed.
  ///
  /// If [forEffect] the resulting expression is ensured to return the [value]
  /// of static type [valueType]. This is needed for extension setters which are
  /// encoded as static method calls that do not implicitly return the value.
  Expression _computePropertySet(
      int fileOffset,
      Expression receiver,
      DartType receiverType,
      Name propertyName,
      ObjectAccessTarget writeTarget,
      Expression value,
      {DartType valueType,
      bool forEffect}) {
    assert(forEffect != null);
    assert(forEffect || valueType != null,
        "No value type provided for property set needed for value.");
    Expression write;
    if (writeTarget.isMissing) {
      write = inferrer.createMissingPropertySet(
          fileOffset, receiver, receiverType, propertyName, value,
          forEffect: forEffect);
    } else if (writeTarget.isExtensionMember) {
      if (forEffect) {
        write = new StaticInvocation(
            writeTarget.member,
            new Arguments(<Expression>[receiver, value],
                types: writeTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
      } else {
        VariableDeclaration valueVariable = createVariable(value, valueType);
        VariableDeclaration assignmentVariable = createVariable(
            new StaticInvocation(
                writeTarget.member,
                new Arguments(
                    <Expression>[receiver, createVariableGet(valueVariable)],
                    types: writeTarget.inferredExtensionTypeArguments)
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset,
            const VoidType());
        write = createLet(valueVariable,
            createLet(assignmentVariable, createVariableGet(valueVariable)))
          ..fileOffset = fileOffset;
      }
    } else {
      write = new PropertySet(receiver, propertyName, value, writeTarget.member)
        ..fileOffset = fileOffset;
    }
    return write;
  }

  ExpressionInferenceResult visitCompoundIndexSet(
      CompoundIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    Expression receiver;
    NullAwareGuard nullAwareGuard;
    if (inferrer.isNonNullableByDefault) {
      nullAwareGuard = receiverResult.nullAwareGuard;
      receiver = receiverResult.nullAwareAction;
    } else {
      receiver = receiverResult.expression;
    }
    VariableDeclaration receiverVariable;
    DartType receiverType = receiverResult.inferredType;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (node.readOnlyReceiver) {
      writeReceiver = readReceiver.accept<TreeNode>(new CloneVisitor());
    } else {
      receiverVariable = createVariable(readReceiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = inferrer.findInterfaceMember(
        receiverType, indexGetName, node.readOffset,
        includeExtensionMethods: true);

    MethodContravarianceCheckKind readCheckKind =
        inferrer.preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readIndexType = inferrer.getPositionalParameterTypeForTarget(
        readTarget, receiverType, 0);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);
    VariableDeclaration indexVariable = createVariableForResult(indexResult);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(node.readOffset,
        readReceiver, receiverType, readTarget, readIndex, readCheckKind);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

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

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset, left, readType, node.binaryName, node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
        includeExtensionMethods: true);

    DartType writeIndexType = inferrer.getPositionalParameterTypeForTarget(
        writeTarget, receiverType, 0);
    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, receiverType);
    binary = inferrer.ensureAssignable(valueType, binaryType, binary,
        fileOffset: node.fileOffset);

    VariableDeclaration valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = createVariable(binary, binaryType);
      valueExpression = createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(node.writeOffset, writeReceiver,
        receiverType, writeTarget, writeIndex, valueExpression);

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
      replacement = new Let(receiverVariable, inner)
        ..fileOffset = node.fileOffset;
    } else {
      replacement = inner;
    }
    return new ExpressionInferenceResult.nullAware(
        node.forPostIncDec ? readType : binaryType,
        replacement,
        nullAwareGuard);
  }

  ExpressionInferenceResult visitNullAwareCompoundSet(
      NullAwareCompoundSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        createVariableForResult(receiverResult);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);

    Member equalsMember = inferrer
        .findInterfaceMember(receiverType, equalsName, node.receiver.fileOffset)
        .member;

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
        readReceiver, receiverType, node.propertyName, const UnknownType(),
        isThisReceiver: node.receiver is ThisExpression);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

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

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset, left, readType, node.binaryName, node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.propertyName, node.writeOffset,
        setter: true, includeExtensionMethods: true);

    DartType valueType = inferrer.getSetterType(writeTarget, receiverType);
    binary = inferrer.ensureAssignable(valueType, binaryType, binary,
        fileOffset: node.fileOffset);

    VariableDeclaration valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = createVariable(binary, binaryType);
      valueExpression = createVariableGet(valueVariable);
    }

    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        receiverType, node.propertyName, writeTarget, valueExpression,
        forEffect: true);

    DartType resultType = node.forPostIncDec ? readType : binaryType;

    Expression action;
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

      action = write;
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
      action = createLet(leftVariable,
          createLet(writeVariable, createVariableGet(leftVariable)));
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
      action = createLet(valueVariable,
          createLet(writeVariable, createVariableGet(valueVariable)));
    }

    return new ExpressionInferenceResult.nullAware(resultType, action,
        new NullAwareGuard(receiverVariable, node.fileOffset, equalsMember));
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
    VariableDeclaration indexVariable = createVariableForResult(indexResult);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.createMissingSuperIndexGet(node.readOffset, readIndex);
    } else {
      assert(readTarget.isInstanceMember);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.readOffset,
          'target',
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

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset, left, readType, node.binaryName, node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = inferrer.getPositionalParameterTypeForTarget(
        writeTarget, inferrer.thisType, 0);
    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);
    Expression binaryReplacement = inferrer.ensureAssignable(
        valueType, binaryType, binary,
        fileOffset: node.fileOffset);
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
      write = inferrer.createMissingSuperIndexSet(
          node.writeOffset, writeIndex, valueExpression);
    } else {
      assert(writeTarget.isInstanceMember);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.writeOffset,
          'target',
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

    Expression receiver =
        inferrer.ensureAssignableResult(receiverType, receiverResult);

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);

    DartType readIndexType = inferrer.getPositionalParameterTypeForTarget(
        readTarget, receiverType, 0);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);
    VariableDeclaration indexVariable = createVariableForResult(indexResult);

    Expression readIndex = createVariableGet(indexVariable);
    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(
        node.readOffset,
        createVariableGet(receiverVariable),
        receiverType,
        readTarget,
        readIndex,
        MethodContravarianceCheckKind.none);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

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

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset, left, readType, node.binaryName, node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ExtensionAccessTarget(
            node.setter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = inferrer.getPositionalParameterTypeForTarget(
        writeTarget, receiverType, 0);
    Expression writeIndex = createVariableGet(indexVariable);
    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);
    binary = inferrer.ensureAssignable(valueType, binaryType, binary,
        fileOffset: node.fileOffset);

    VariableDeclaration valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = createVariable(binary, binaryType);
      valueExpression = createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
        node.writeOffset,
        createVariableGet(receiverVariable),
        receiverType,
        writeTarget,
        writeIndex,
        valueExpression);

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
    return new ExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType, replacement);
  }

  @override
  ExpressionInferenceResult visitNullLiteral(
      NullLiteral node, DartType typeContext) {
    inferrer.flowAnalysis.nullLiteral(node);
    return new ExpressionInferenceResult(inferrer.coreTypes.nullType, node);
  }

  @override
  ExpressionInferenceResult visitLet(Let node, DartType typeContext) {
    DartType variableType = node.variable.type;
    ExpressionInferenceResult initializerResult = inferrer.inferExpression(
        node.variable.initializer, variableType, true,
        isVoidAllowed: true);
    node.variable.initializer = initializerResult.expression
      ..parent = node.variable;
    ExpressionInferenceResult bodyResult = inferrer
        .inferExpression(node.body, typeContext, true, isVoidAllowed: true);
    node.body = bodyResult.expression..parent = node;
    DartType inferredType = bodyResult.inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitPropertySet(
      covariant PropertySetImpl node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);
    DartType receiverType = receiverResult.inferredType;
    Expression receiver;
    NullAwareGuard nullAwareGuard;
    if (inferrer.isNonNullableByDefault) {
      nullAwareGuard = receiverResult.nullAwareGuard;
      receiver = receiverResult.nullAwareAction;
    } else {
      receiver = receiverResult.expression;
    }
    ObjectAccessTarget target = inferrer.findInterfaceMember(
        receiverType, node.name, node.fileOffset,
        setter: true, instrumented: true, includeExtensionMethods: true);
    if (target.isInstanceMember) {
      if (inferrer.instrumentation != null &&
          receiverType == const DynamicType()) {
        inferrer.instrumentation.record(
            inferrer.uriForInstrumentation,
            node.fileOffset,
            'target',
            new InstrumentationValueForMember(target.member));
      }
      node.interfaceTarget = target.member;
    }
    DartType writeContext = inferrer.getSetterType(target, receiverType);
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(
        node.value, writeContext ?? const UnknownType(), true,
        isVoidAllowed: true);
    DartType rhsType = rhsResult.inferredType;
    Expression rhs = inferrer.ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);

    Expression replacement = _computePropertySet(
        node.fileOffset, receiver, receiverType, node.name, target, rhs,
        valueType: rhsType, forEffect: node.forEffect);

    return new ExpressionInferenceResult.nullAware(
        rhsType, replacement, nullAwareGuard);
  }

  ExpressionInferenceResult visitNullAwareIfNullSet(
      NullAwareIfNullSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);
    DartType receiverType = receiverResult.inferredType;
    VariableDeclaration receiverVariable =
        createVariableForResult(receiverResult);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);

    Member receiverEqualsMember = inferrer
        .findInterfaceMember(receiverType, equalsName, node.receiver.fileOffset)
        .member;

    ExpressionInferenceResult readResult = _computePropertyGet(
        node.readOffset, readReceiver, receiverType, node.name, typeContext,
        isThisReceiver: node.receiver is ThisExpression);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    Member readEqualsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

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
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        receiverType, node.name, writeTarget, value,
        valueType: valueResult.inferredType, forEffect: node.forEffect);

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

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitPropertyGet(
      PropertyGet node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferrer.inferExpression(node.receiver, const UnknownType(), true);
    NullAwareGuard nullAwareGuard;
    Expression receiver;
    if (inferrer.isNonNullableByDefault) {
      nullAwareGuard = result.nullAwareGuard;
      receiver = result.nullAwareAction;
    } else {
      receiver = result.expression;
    }
    node.receiver = receiver..parent = node;
    DartType receiverType = result.inferredType;
    ExpressionInferenceResult readResult = _computePropertyGet(
        node.fileOffset, receiver, receiverType, node.name, typeContext,
        isThisReceiver: node.receiver is ThisExpression);
    return new ExpressionInferenceResult.nullAware(
        readResult.inferredType, readResult.expression, nullAwareGuard);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    List<DartType> typeArguments =
        new List<DartType>(classTypeParameters.length);
    for (int i = 0; i < typeArguments.length; i++) {
      typeArguments[i] = new TypeParameterType.withDefaultNullabilityForLibrary(
          classTypeParameters[i], inferrer.library.library);
    }
    ArgumentsImpl.setNonInferrableArgumentTypes(node.arguments, typeArguments);
    inferrer.inferInvocation(null, node.fileOffset,
        node.target.function.thisFunctionType, node.arguments,
        returnType: inferrer.coreTypes.thisInterfaceType(
            node.target.enclosingClass, inferrer.library.nonNullable),
        skipTypeArgumentInference: true);
    ArgumentsImpl.removeNonInferrableArgumentTypes(node.arguments);
  }

  @override
  ExpressionInferenceResult visitRethrow(Rethrow node, DartType typeContext) {
    inferrer.flowAnalysis.handleExit();
    return new ExpressionInferenceResult(const BottomType(), node);
  }

  @override
  StatementInferenceResult visitReturnStatement(
      covariant ReturnStatementImpl node) {
    ClosureContext closureContext = inferrer.closureContext;
    DartType typeContext = !closureContext.isGenerator
        ? closureContext.returnOrYieldContext
        : const UnknownType();
    DartType inferredType;
    if (node.expression != null) {
      ExpressionInferenceResult expressionResult = inferrer.inferExpression(
          node.expression, typeContext, true,
          isVoidAllowed: true);
      node.expression = expressionResult.expression..parent = node;
      inferredType = expressionResult.inferredType;
    } else {
      inferredType = inferrer.coreTypes.nullType;
    }
    closureContext.handleReturn(inferrer, node, inferredType, node.isArrow);
    inferrer.flowAnalysis.handleExit();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitSetLiteral(
      SetLiteral node, DartType typeContext) {
    Class setClass = inferrer.coreTypes.setClass;
    InterfaceType setType = inferrer.coreTypes
        .thisInterfaceType(setClass, inferrer.library.nonNullable);
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
      for (int index = 0; index < node.expressions.length; ++index) {
        ExpressionInferenceResult result = inferElement(
            node.expressions[index],
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        node.expressions[index] = result.expression..parent = node;
        actualTypes.add(result.inferredType);
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
          inferrer.uriForInstrumentation,
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
        new InterfaceType(setClass, Nullability.legacy, [inferredTypeArgument]);
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
    return new ExpressionInferenceResult(inferredType, node);
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
    Expression rhs = inferrer.ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    node.value = rhs..parent = node;
    DartType rhsType = rhsResult.inferredType;
    return new ExpressionInferenceResult(rhsType, node);
  }

  @override
  ExpressionInferenceResult visitStaticGet(
      StaticGet node, DartType typeContext) {
    Member target = node.target;
    TypeInferenceEngine.resolveInferenceNode(target);
    DartType type = target.getterType;
    if (target is Procedure && target.kind == ProcedureKind.Method) {
      return inferrer.instantiateTearOff(type, typeContext, node);
    } else {
      return new ExpressionInferenceResult(type, node);
    }
  }

  @override
  ExpressionInferenceResult visitStaticInvocation(
      StaticInvocation node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.functionType
        : new FunctionType([], const DynamicType(), Nullability.legacy);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    DartType inferredType = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments);
    if (!inferrer.isTopLevel && node.target != null) {
      inferrer.library.checkBoundsInStaticInvocation(
          node,
          inferrer.typeSchemaEnvironment,
          inferrer.helper.uri,
          typeArgumentsInfo);
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitStringConcatenation(
      StringConcatenation node, DartType typeContext) {
    if (!inferrer.isTopLevel) {
      for (int index = 0; index < node.expressions.length; index++) {
        ExpressionInferenceResult result = inferrer.inferExpression(
            node.expressions[index], const UnknownType(), !inferrer.isTopLevel,
            isVoidAllowed: false);
        node.expressions[index] = result.expression..parent = node;
      }
    }
    return new ExpressionInferenceResult(
        inferrer.coreTypes.stringRawType(inferrer.library.nonNullable), node);
  }

  @override
  ExpressionInferenceResult visitStringLiteral(
      StringLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        inferrer.coreTypes.stringRawType(inferrer.library.nonNullable), node);
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
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'target',
          new InstrumentationValueForMember(node.interfaceTarget));
    }
    return inferrer.inferSuperMethodInvocation(
        node,
        typeContext,
        node.interfaceTarget != null
            ? new ObjectAccessTarget.interfaceMember(node.interfaceTarget)
            : const ObjectAccessTarget.unresolved());
  }

  @override
  ExpressionInferenceResult visitSuperPropertyGet(
      SuperPropertyGet node, DartType typeContext) {
    if (node.interfaceTarget != null) {
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'target',
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
    Expression rhs = inferrer.ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    node.value = rhs..parent = node;
    return new ExpressionInferenceResult(rhsResult.inferredType, node);
  }

  @override
  StatementInferenceResult visitSwitchStatement(SwitchStatement node) {
    ExpressionInferenceResult expressionResult = inferrer.inferExpression(
        node.expression, const UnknownType(), true,
        isVoidAllowed: false);
    node.expression = expressionResult.expression..parent = node;
    DartType expressionType = expressionResult.inferredType;
    inferrer.flowAnalysis.switchStatement_expressionEnd(node);

    bool hasDefault = false;
    for (SwitchCase switchCase in node.cases) {
      hasDefault = hasDefault || switchCase.isDefault;
      // TODO(dmitryas): Pass in the actual value for the first parameter.
      inferrer.flowAnalysis.switchStatement_beginCase(false, node);
      for (int index = 0; index < switchCase.expressions.length; index++) {
        ExpressionInferenceResult caseExpressionResult =
            inferrer.inferExpression(
                switchCase.expressions[index], expressionType, true,
                isVoidAllowed: false);
        Expression caseExpression = caseExpressionResult.expression;
        switchCase.expressions[index] = caseExpression..parent = switchCase;
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
                    inferrer.uriForInstrumentation,
                    node.expression.fileOffset,
                    noLength)
              ]);
        }
      }
      StatementInferenceResult bodyResult =
          inferrer.inferStatement(switchCase.body);
      if (bodyResult.hasChanged) {
        switchCase.body = bodyResult.statement..parent = switchCase;
      }
    }
    inferrer.flowAnalysis.switchStatement_end(hasDefault);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitSymbolLiteral(
      SymbolLiteral node, DartType typeContext) {
    DartType inferredType =
        inferrer.coreTypes.symbolRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitThisExpression(
      ThisExpression node, DartType typeContext) {
    return new ExpressionInferenceResult(inferrer.thisType, node);
  }

  @override
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    ExpressionInferenceResult expressionResult = inferrer.inferExpression(
        node.expression, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: false);
    node.expression = expressionResult.expression..parent = node;
    inferrer.flowAnalysis.handleExit();
    return new ExpressionInferenceResult(const BottomType(), node);
  }

  void visitCatch(Catch node) {
    if (node.exception != null) {
      inferrer.flowAnalysis.initialize(node.exception);
    }
    if (node.stackTrace != null) {
      inferrer.flowAnalysis.initialize(node.stackTrace);
    }
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
  }

  @override
  StatementInferenceResult visitTryCatch(TryCatch node) {
    inferrer.flowAnalysis.tryCatchStatement_bodyBegin();
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    inferrer.flowAnalysis.tryCatchStatement_bodyEnd(node.body);
    for (Catch catch_ in node.catches) {
      inferrer.flowAnalysis
          .tryCatchStatement_catchBegin(catch_.exception, catch_.stackTrace);
      inferrer.flowAnalysis.initialize(catch_.exception);
      inferrer.flowAnalysis.initialize(catch_.stackTrace);
      visitCatch(catch_);
      inferrer.flowAnalysis.tryCatchStatement_catchEnd();
    }
    inferrer.flowAnalysis.tryCatchStatement_end();
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitTryFinally(TryFinally node) {
    inferrer.flowAnalysis.tryFinallyStatement_bodyBegin();
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    inferrer.flowAnalysis.tryFinallyStatement_finallyBegin(node.finalizer);
    StatementInferenceResult finalizerResult =
        inferrer.inferStatement(node.finalizer);
    if (finalizerResult.hasChanged) {
      node.finalizer = finalizerResult.statement..parent = node;
    }
    inferrer.flowAnalysis.tryFinallyStatement_end(node.finalizer);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitTypeLiteral(
      TypeLiteral node, DartType typeContext) {
    DartType inferredType =
        inferrer.coreTypes.typeRawType(inferrer.library.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitVariableSet(
      VariableSet node, DartType typeContext) {
    DartType writeContext = node.variable.type;
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(
        node.value, writeContext ?? const UnknownType(), true,
        isVoidAllowed: true);
    Expression rhs = inferrer.ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    node.value = rhs..parent = node;
    inferrer.flowAnalysis.write(node.variable, rhsResult.inferredType);
    return new ExpressionInferenceResult(rhsResult.inferredType, node);
  }

  @override
  StatementInferenceResult visitVariableDeclaration(
      covariant VariableDeclarationImpl node) {
    DartType declaredType =
        node.implicitlyTyped ? const UnknownType() : node.type;
    DartType inferredType;
    ExpressionInferenceResult initializerResult;
    if (node.initializer != null) {
      initializerResult = inferrer.inferExpression(node.initializer,
          declaredType, !inferrer.isTopLevel || node.implicitlyTyped,
          isVoidAllowed: true);
      inferredType =
          inferrer.inferDeclarationType(initializerResult.inferredType);
      inferrer.flowAnalysis.initialize(node);
    } else {
      inferredType = const DynamicType();
    }
    if (node.implicitlyTyped) {
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'type',
          new InstrumentationValueForType(inferredType));
      node.type = inferredType;
    }
    if (initializerResult != null) {
      Expression initializer = inferrer.ensureAssignableResult(
          node.type, initializerResult,
          fileOffset: node.fileOffset, isVoidAllowed: node.type is VoidType);
      node.initializer = initializer..parent = node;
    }
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (node.implicitlyTyped) {
        library.checkBoundsInVariableDeclaration(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitVariableGet(
      covariant VariableGetImpl node, DartType typeContext) {
    VariableDeclarationImpl variable = node.variable;
    bool isUnassigned = !inferrer.flowAnalysis.isAssigned(variable);
    if (isUnassigned) {
      inferrer.dataForTesting?.flowAnalysisResult?.unassignedNodes?.add(node);
    }

    DartType promotedType;
    DartType declaredOrInferredType = variable.type;
    if (inferrer.isNonNullableByDefault) {
      promotedType = inferrer.flowAnalysis.variableRead(node, variable);
    } else {
      bool mutatedInClosure = variable._mutatedInClosure;
      promotedType = inferrer.typePromoter
          .computePromotedType(node._fact, node._scope, mutatedInClosure);
    }
    if (promotedType != null) {
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'promotedType',
          new InstrumentationValueForType(promotedType));
    }
    node.promotedType = promotedType;
    DartType type = promotedType ?? declaredOrInferredType;
    if (variable._isLocalFunction) {
      return inferrer.instantiateTearOff(type, typeContext, node);
    } else {
      return new ExpressionInferenceResult(type, node);
    }
  }

  @override
  StatementInferenceResult visitWhileStatement(WhileStatement node) {
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult conditionResult = inferrer.inferExpression(
        node.condition, expectedType, !inferrer.isTopLevel,
        isVoidAllowed: false);
    Expression condition =
        inferrer.ensureAssignableResult(expectedType, conditionResult);
    node.condition = condition..parent = node;
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitYieldStatement(YieldStatement node) {
    ClosureContext closureContext = inferrer.closureContext;
    ExpressionInferenceResult expressionResult;
    if (closureContext.isGenerator) {
      DartType typeContext = closureContext.returnOrYieldContext;
      if (node.isYieldStar && typeContext != null) {
        typeContext = inferrer.wrapType(
            typeContext,
            closureContext.isAsync
                ? inferrer.coreTypes.streamClass
                : inferrer.coreTypes.iterableClass);
      }
      expressionResult = inferrer.inferExpression(
          node.expression, typeContext, true,
          isVoidAllowed: true);
    } else {
      expressionResult = inferrer.inferExpression(
          node.expression, const UnknownType(), true,
          isVoidAllowed: true);
    }
    closureContext.handleYield(inferrer, node, expressionResult);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitLoadLibrary(
      covariant LoadLibraryImpl node, DartType typeContext) {
    DartType inferredType = inferrer.typeSchemaEnvironment
        .futureType(const DynamicType(), Nullability.legacy);
    if (node.arguments != null) {
      FunctionType calleeType =
          new FunctionType([], inferredType, Nullability.legacy);
      inferrer.inferInvocation(
          typeContext, node.fileOffset, calleeType, node.arguments);
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitLoadLibraryTearOff(
      LoadLibraryTearOff node, DartType typeContext) {
    DartType inferredType = new FunctionType(
        [],
        inferrer.typeSchemaEnvironment
            .futureType(const DynamicType(), Nullability.legacy),
        Nullability.legacy);
    Expression replacement = new StaticGet(node.target)
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, DartType typeContext) {
    // TODO(dmitryas): Figure out the suitable nullability for that.
    return new ExpressionInferenceResult(
        inferrer.coreTypes.objectRawType(inferrer.library.nullable), node);
  }

  ExpressionInferenceResult visitEquals(
      EqualsExpression node, DartType typeContext) {
    ExpressionInferenceResult leftResult =
        inferrer.inferExpression(node.left, const UnknownType(), true);
    return _computeEqualsExpression(node.fileOffset, leftResult.expression,
        leftResult.inferredType, node.right,
        isNot: node.isNot);
  }

  ExpressionInferenceResult visitBinary(
      BinaryExpression node, DartType typeContext) {
    ExpressionInferenceResult leftResult =
        inferrer.inferExpression(node.left, const UnknownType(), true);
    return _computeBinaryExpression(node.fileOffset, leftResult.expression,
        leftResult.inferredType, node.binaryName, node.right);
  }

  ExpressionInferenceResult visitUnary(
      UnaryExpression node, DartType typeContext) {
    ExpressionInferenceResult expressionResult;
    if (node.unaryName.name == 'unary-') {
      // Replace integer literals in a double context with the corresponding
      // double literal if it's exact.  For double literals, the negation is
      // folded away.  In any non-double context, or if there is no exact
      // double value, then the corresponding integer literal is left.  The
      // negation is not folded away so that platforms with web literals can
      // distinguish between (non-negated) 0x8000000000000000 represented as
      // integer literal -9223372036854775808 which should be a positive number,
      // and negated 9223372036854775808 represented as
      // -9223372036854775808.unary-() which should be a negative number.
      if (node.expression is IntJudgment) {
        IntJudgment receiver = node.expression;
        if (inferrer.isDoubleContext(typeContext)) {
          double doubleValue = receiver.asDouble(negated: true);
          if (doubleValue != null) {
            Expression replacement = new DoubleLiteral(doubleValue)
              ..fileOffset = node.fileOffset;
            DartType inferredType =
                inferrer.coreTypes.doubleRawType(inferrer.library.nonNullable);
            return new ExpressionInferenceResult(inferredType, replacement);
          }
        }
        Expression error = checkWebIntLiteralsErrorIfUnexact(
            inferrer, receiver.value, receiver.literal, receiver.fileOffset);
        if (error != null) {
          return new ExpressionInferenceResult(const DynamicType(), error);
        }
      } else if (node.expression is ShadowLargeIntLiteral) {
        ShadowLargeIntLiteral receiver = node.expression;
        if (!receiver.isParenthesized) {
          if (inferrer.isDoubleContext(typeContext)) {
            double doubleValue = receiver.asDouble(negated: true);
            if (doubleValue != null) {
              Expression replacement = new DoubleLiteral(doubleValue)
                ..fileOffset = node.fileOffset;
              DartType inferredType = inferrer.coreTypes
                  .doubleRawType(inferrer.library.nonNullable);
              return new ExpressionInferenceResult(inferredType, replacement);
            }
          }
          int intValue = receiver.asInt64(negated: true);
          if (intValue == null) {
            Expression error = inferrer.helper.buildProblem(
                templateIntegerLiteralIsOutOfRange
                    .withArguments(receiver.literal),
                receiver.fileOffset,
                receiver.literal.length);
            return new ExpressionInferenceResult(const DynamicType(), error);
          }
          if (intValue != null) {
            Expression error = checkWebIntLiteralsErrorIfUnexact(
                inferrer, intValue, receiver.literal, receiver.fileOffset);
            if (error != null) {
              return new ExpressionInferenceResult(const DynamicType(), error);
            }
            expressionResult = new ExpressionInferenceResult(
                inferrer.coreTypes.intRawType(inferrer.library.nonNullable),
                new IntLiteral(-intValue)
                  ..fileOffset = node.expression.fileOffset);
          }
        }
      }
    }
    if (expressionResult == null) {
      expressionResult =
          inferrer.inferExpression(node.expression, const UnknownType(), true);
    }
    return _computeUnaryExpression(node.fileOffset, expressionResult.expression,
        expressionResult.inferredType, node.unaryName);
  }

  ExpressionInferenceResult visitParenthesized(
      ParenthesizedExpression node, DartType typeContext) {
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.expression, typeContext, true,
        isVoidAllowed: true);
    return new ExpressionInferenceResult(
        result.inferredType, result.expression);
  }
}

class ForInResult {
  final VariableDeclaration variable;
  final Expression iterable;
  final Statement body;

  ForInResult(this.variable, this.iterable, this.body);

  String toString() => 'ForInResult($variable,$iterable,$body)';
}
