// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart';

import '../../base/instrumentation.dart'
    show
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;
import '../fasta_codes.dart';
import '../names.dart';
import '../problems.dart' show unhandled;
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart' show UnknownType;
import 'body_builder.dart' show combineStatements;
import 'collections.dart'
    show
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement,
        SpreadMapEntry,
        convertToElement;
import 'implicit_type_argument.dart' show ImplicitTypeArgument;
import 'internal_ast.dart';
import 'late_lowering.dart' as late_lowering;

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

  @override
  StatementInferenceResult visitTryCatch(TryCatch node) {
    return _unhandledStatement(node);
  }

  @override
  StatementInferenceResult visitTryFinally(TryFinally node) {
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
    ExpressionInferenceResult operandResult = inferrer.inferExpression(
        node.operand, typeContext, true,
        isVoidAllowed: !inferrer.isNonNullableByDefault);
    DartType inferredType =
        inferrer.typeSchemaEnvironment.flatten(operandResult.inferredType);
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
    if (result != null) {
      Block block = new Block(result)..fileOffset = node.fileOffset;
      inferrer.library.loader.dataForTesting?.registerAlias(node, block);
      return new StatementInferenceResult.single(block);
    } else {
      return const StatementInferenceResult();
    }
  }

  @override
  ExpressionInferenceResult visitBoolLiteral(
      BoolLiteral node, DartType typeContext) {
    inferrer.flowAnalysis.booleanLiteral(node, node.value);
    return new ExpressionInferenceResult(
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable), node);
  }

  @override
  StatementInferenceResult visitBreakStatement(
      covariant BreakStatementImpl node) {
    // TODO(johnniwinther): Refactor break/continue encoding.
    assert(node.targetStatement != null);
    if (node.isContinue) {
      inferrer.flowAnalysis.handleContinue(node.targetStatement);
    } else {
      inferrer.flowAnalysis.handleBreak(node.targetStatement);
    }
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result = inferrer.inferExpression(
        node.variable.initializer, typeContext, true,
        isVoidAllowed: false);
    if (node.isNullAware) {
      reportNonNullableInNullAwareWarningIfNeeded(
          result.inferredType, "?..", node.fileOffset);
    }

    node.variable.initializer = result.expression..parent = node.variable;
    node.variable.type = result.inferredType;
    NullAwareGuard nullAwareGuard;
    if (node.isNullAware) {
      nullAwareGuard = inferrer.createNullAwareGuard(node.variable);
    }

    List<ExpressionInferenceResult> expressionResults =
        <ExpressionInferenceResult>[];
    for (Expression expression in node.expressions) {
      expressionResults.add(inferrer.inferExpression(
          expression, const UnknownType(), !inferrer.isTopLevel,
          isVoidAllowed: true, forEffect: true));
    }
    List<Statement> body = [];
    for (int index = 0; index < expressionResults.length; index++) {
      body.add(_createExpressionStatement(expressionResults[index].expression));
    }

    Expression replacement = _createBlockExpression(node.variable.fileOffset,
        _createBlock(body), createVariableGet(node.variable));

    if (node.isNullAware) {
      replacement =
          nullAwareGuard.createExpression(result.inferredType, replacement);
    } else {
      replacement = new Let(node.variable, replacement)
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  Block _createBlock(List<Statement> statements) {
    return new Block(statements);
  }

  BlockExpression _createBlockExpression(
      int fileOffset, Block body, Expression value) {
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new BlockExpression(body, value)..fileOffset = fileOffset;
  }

  ExpressionStatement _createExpressionStatement(Expression expression) {
    assert(expression != null);
    assert(expression.fileOffset != TreeNode.noOffset);
    return new ExpressionStatement(expression)
      ..fileOffset = expression.fileOffset;
  }

  @override
  ExpressionInferenceResult visitConditionalExpression(
      ConditionalExpression node, DartType typeContext) {
    inferrer.flowAnalysis.conditional_conditionBegin();
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
    inferrer.flowAnalysis.conditional_end(node, node.otherwise);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(thenResult.inferredType,
            otherwiseResult.inferredType, inferrer.library.library);
    node.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitConstructorInvocation(
      ConstructorInvocation node, DartType typeContext) {
    inferrer.inferConstructorParameterTypes(node.target);
    bool hasExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;
    FunctionType functionType = replaceReturnType(
        node.target.function
            .computeThisFunctionType(inferrer.library.nonNullable),
        computeConstructorReturnType(node.target, inferrer.coreTypes));
    InvocationInferenceResult result = inferrer.inferInvocation(
        typeContext, node.fileOffset, functionType, node.arguments,
        isConst: node.isConst, staticTarget: node.target);
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (!hasExplicitTypeArguments) {
        library.checkBoundsInConstructorInvocation(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(node));
  }

  @override
  StatementInferenceResult visitContinueSwitchStatement(
      ContinueSwitchStatement node) {
    inferrer.flowAnalysis.handleContinue(node.target.body);
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitExtensionTearOff(
      ExtensionTearOff node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.computeFunctionType(inferrer.library.nonNullable)
        : new FunctionType(
            [], const DynamicType(), inferrer.library.nonNullable);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    InvocationInferenceResult result = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments,
        staticTarget: node.target);
    Expression replacement = new StaticInvocation(node.target, node.arguments);
    if (!inferrer.isTopLevel && node.target != null) {
      inferrer.library.checkBoundsInStaticInvocation(
          replacement,
          inferrer.typeSchemaEnvironment,
          inferrer.helper.uri,
          typeArgumentsInfo);
    }
    return inferrer.instantiateTearOff(
        result.inferredType, typeContext, result.applyResult(replacement));
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
    if (node.forEffect || isPureExpression(receiver)) {
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
    if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
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

    ObjectAccessTarget writeTarget = node.setter == null
        ? const ObjectAccessTarget.missing()
        : new ExtensionAccessTarget(
            node.setter, null, ProcedureKind.Setter, extensionTypeArguments);

    DartType valueType = inferrer.getSetterType(writeTarget, receiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        read,
        readType,
        node.binaryName,
        node.rhs);

    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

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
          node.writeOffset, writeReceiver, readType, node.propertyName, value,
          forEffect: node.forEffect);
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
        isVoidAllowed: true, forEffect: true);
    node.expression = result.expression..parent = node;
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitFactoryConstructorInvocationJudgment(
      FactoryConstructorInvocationJudgment node, DartType typeContext) {
    bool hadExplicitTypeArguments =
        getExplicitTypeArguments(node.arguments) != null;

    FunctionType functionType = replaceReturnType(
        node.target.function
            .computeThisFunctionType(inferrer.library.nonNullable),
        computeConstructorReturnType(node.target, inferrer.coreTypes));

    InvocationInferenceResult result = inferrer.inferInvocation(
        typeContext, node.fileOffset, functionType, node.arguments,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (!hadExplicitTypeArguments) {
        library.checkBoundsInFactoryInvocation(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
      if (inferrer.isNonNullableByDefault) {
        if (node.target == inferrer.coreTypes.listDefaultConstructor) {
          resultNode = inferrer.helper.wrapInProblem(node,
              messageDefaultListConstructorError, node.fileOffset, noLength);
        }
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  ExpressionInferenceResult visitTypeAliasedConstructorInvocationJudgment(
      TypeAliasedConstructorInvocationJudgment node, DartType typeContext) {
    assert(getExplicitTypeArguments(node.arguments) == null);
    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType = node.target.function
        .computeAliasedConstructorFunctionType(
            typedef, inferrer.library.library);
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      library.checkBoundsInType(result.inferredType,
          inferrer.typeSchemaEnvironment, inferrer.helper.uri, node.fileOffset,
          inferred: true);
      if (inferrer.isNonNullableByDefault) {
        if (node.target == inferrer.coreTypes.listDefaultConstructor) {
          resultNode = inferrer.helper.wrapInProblem(node,
              messageDefaultListConstructorError, node.fileOffset, noLength);
        }
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  ExpressionInferenceResult visitTypeAliasedFactoryInvocationJudgment(
      TypeAliasedFactoryInvocationJudgment node, DartType typeContext) {
    assert(getExplicitTypeArguments(node.arguments) == null);
    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType = node.target.function
        .computeAliasedFactoryFunctionType(typedef, inferrer.library.library);
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      library.checkBoundsInType(result.inferredType,
          inferrer.typeSchemaEnvironment, inferrer.helper.uri, node.fileOffset,
          inferred: true);
      if (inferrer.isNonNullableByDefault) {
        if (node.target == inferrer.coreTypes.listDefaultConstructor) {
          resultNode = inferrer.helper.wrapInProblem(node,
              messageDefaultListConstructorError, node.fileOffset, noLength);
        }
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
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
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Statement expressionEffects,
      {bool isAsync: false}) {
    DartType elementType;
    bool typeNeeded = false;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (variable is VariableDeclarationImpl && variable.isImplicitlyTyped) {
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

    // This is matched by the call to [forEach_end] in
    // [inferElement], [inferMapEntry] or [inferForInStatement].
    inferrer.flowAnalysis.declare(variable, true);
    inferrer.flowAnalysis.forEach_bodyBegin(node, variable, variable.type);

    VariableDeclaration tempVariable =
        new VariableDeclaration(null, type: inferredType, isFinal: true);
    VariableGet variableGet = new VariableGet(tempVariable)
      ..fileOffset = variable.fileOffset;
    TreeNode parent = variable.parent;
    Expression implicitDowncast = inferrer.ensureAssignable(
        variable.type, inferredType, variableGet,
        fileOffset: parent.fileOffset,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability);
    Statement expressionEffect;
    if (!identical(implicitDowncast, variableGet)) {
      variable.initializer = implicitDowncast..parent = variable;
      expressionEffect = variable;
      variable = tempVariable;
    }
    if (expressionEffects != null) {
      StatementInferenceResult bodyResult =
          inferrer.inferStatement(expressionEffects);
      if (bodyResult.hasChanged) {
        expressionEffects = bodyResult.statement;
      }
      if (expressionEffect != null) {
        expressionEffects =
            combineStatements(expressionEffect, expressionEffects);
      }
    } else {
      expressionEffects = expressionEffect;
    }
    return new ForInResult(
        variable, iterableResult.expression, null, expressionEffects);
  }

  ExpressionInferenceResult inferForInIterable(
      Expression iterable, DartType elementType, bool typeNeeded,
      {bool isAsync: false}) {
    Class iterableClass = isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context = inferrer.wrapType(
        elementType, iterableClass, inferrer.library.nonNullable);
    ExpressionInferenceResult iterableResult = inferrer
        .inferExpression(iterable, context, typeNeeded, isVoidAllowed: false);
    DartType iterableType = iterableResult.inferredType;
    iterable = iterableResult.expression;
    DartType inferredExpressionType =
        inferrer.resolveTypeParameter(iterableType);
    iterable = inferrer.ensureAssignable(
        inferrer.wrapType(
            const DynamicType(), iterableClass, inferrer.library.nonNullable),
        inferredExpressionType,
        iterable,
        errorTemplate: templateForInLoopTypeNotIterable,
        nullabilityErrorTemplate: templateForInLoopTypeNotIterableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopTypeNotIterablePartNullability);
    DartType inferredType;
    if (typeNeeded) {
      inferredType = const DynamicType();
      if (inferredExpressionType is InterfaceType) {
        // TODO(johnniwinther): Should we use the type of
        //  `iterable.iterator.current` instead?
        List<DartType> supertypeArguments = inferrer.classHierarchy
            .getTypeArgumentsAsInstanceOf(
                inferredExpressionType, iterableClass);
        if (supertypeArguments != null) {
          inferredType = supertypeArguments[0];
        }
      }
    }
    return new ExpressionInferenceResult(inferredType, iterable);
  }

  ForInVariable computeForInVariable(
      Expression syntheticAssignment, bool hasProblem) {
    if (syntheticAssignment is VariableSet) {
      return new LocalForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is PropertySet) {
      return new PropertyForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is SuperPropertySet) {
      return new SuperPropertyForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is StaticSet) {
      return new StaticForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is InvalidExpression || hasProblem) {
      return new InvalidForInVariable(syntheticAssignment);
    } else {
      return unhandled(
          "${syntheticAssignment.runtimeType}",
          "handleForInStatementWithoutVariable",
          syntheticAssignment.fileOffset,
          inferrer.helper.uri);
    }
  }

  ForInResult handleForInWithoutVariable(
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Expression syntheticAssignment,
      Statement expressionEffects,
      {bool isAsync: false,
      bool hasProblem}) {
    assert(hasProblem != null);
    bool typeChecksNeeded = !inferrer.isTopLevel;
    ForInVariable forInVariable =
        computeForInVariable(syntheticAssignment, hasProblem);
    DartType elementType = forInVariable.computeElementType(inferrer);
    ExpressionInferenceResult iterableResult = inferForInIterable(
        iterable, elementType, typeChecksNeeded,
        isAsync: isAsync);
    DartType inferredType = iterableResult.inferredType;
    if (typeChecksNeeded) {
      variable.type = inferredType;
    }
    // This is matched by the call to [forEach_end] in
    // [inferElement], [inferMapEntry] or [inferForInStatement].
    inferrer.flowAnalysis.forEach_bodyBegin(node, variable, inferredType);
    syntheticAssignment = forInVariable.inferAssignment(inferrer, inferredType);
    if (expressionEffects != null) {
      StatementInferenceResult result =
          inferrer.inferStatement(expressionEffects);
      expressionEffects =
          result.hasChanged ? result.statement : expressionEffects;
    }
    return new ForInResult(variable, iterableResult.expression,
        syntheticAssignment, expressionEffects);
  }

  @override
  StatementInferenceResult visitForInStatement(ForInStatement node) {
    assert(node.variable.name != null);
    ForInResult result = handleForInDeclaringVariable(
        node, node.variable, node.iterable, null,
        isAsync: node.isAsync);

    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    inferrer.flowAnalysis.forEach_end();

    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
    if (result.expressionSideEffects != null) {
      body = combineStatements(result.expressionSideEffects, body);
    }
    if (result.syntheticAssignment != null) {
      body = combineStatements(
          createExpressionStatement(result.syntheticAssignment), body);
    }
    node.variable = result.variable..parent = node;
    node.iterable = result.iterable..parent = node;
    node.body = body..parent = node;
    return const StatementInferenceResult();
  }

  StatementInferenceResult visitForInStatementWithSynthesizedVariable(
      ForInStatementWithSynthesizedVariable node) {
    assert(node.variable.name == null);
    ForInResult result = handleForInWithoutVariable(node, node.variable,
        node.iterable, node.syntheticAssignment, node.expressionEffects,
        isAsync: node.isAsync, hasProblem: node.hasProblem);

    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    inferrer.flowAnalysis.forEach_end();

    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
    if (result.expressionSideEffects != null) {
      body = combineStatements(result.expressionSideEffects, body);
    }
    if (result.syntheticAssignment != null) {
      body = combineStatements(
          createExpressionStatement(result.syntheticAssignment), body);
    }
    Statement replacement = new ForInStatement(
        result.variable, result.iterable, body,
        isAsync: node.isAsync)
      ..fileOffset = node.fileOffset
      ..bodyOffset = node.bodyOffset;
    inferrer.library.loader.dataForTesting?.registerAlias(node, replacement);
    return new StatementInferenceResult.single(replacement);
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

    inferrer.flowAnalysis.for_bodyBegin(node, node.condition);
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
    inferrer.flowAnalysis.declare(node.variable, true);
    inferrer.flowAnalysis.functionExpression_begin(node);
    inferrer.inferMetadataKeepingHelper(
        node.variable, node.variable.annotations);
    DartType returnContext =
        node.hasImplicitReturnType ? null : node.function.returnType;
    DartType inferredType =
        visitFunctionNode(node.function, null, returnContext, node.fileOffset);
    inferrer.library.checkBoundsInFunctionNode(node.function,
        inferrer.typeSchemaEnvironment, inferrer.library.fileUri);
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
    // In anonymous functions the return type isn't declared, so
    // it shouldn't be checked.
    inferrer.library.checkBoundsInFunctionNode(
        node.function, inferrer.typeSchemaEnvironment, inferrer.library.fileUri,
        skipReturnType: true);
    inferrer.flowAnalysis.functionExpression_end();
    return new ExpressionInferenceResult(inferredType, node);
  }

  void visitInvalidSuperInitializerJudgment(
      InvalidSuperInitializerJudgment node) {
    Substitution substitution = Substitution.fromSupertype(
        inferrer.classHierarchy.getClassAsInstanceOf(
            inferrer.thisType.classNode, node.target.enclosingClass));
    FunctionType functionType = replaceReturnType(
        substitution.substituteType(node.target.function
            .computeThisFunctionType(inferrer.library.nonNullable)
            .withoutTypeParameters),
        inferrer.thisType);
    inferrer.inferInvocation(
        null, node.fileOffset, functionType, node.argumentsJudgment,
        skipTypeArgumentInference: true);
  }

  ExpressionInferenceResult visitIfNullExpression(
      IfNullExpression node, DartType typeContext) {
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    ExpressionInferenceResult lhsResult = inferrer.inferExpression(
        node.left, inferrer.computeNullable(typeContext), true,
        isVoidAllowed: false);
    reportNonNullableInNullAwareWarningIfNeeded(
        lhsResult.inferredType, "??", node.left.fileOffset);

    Member equalsMember = inferrer
        .findInterfaceMember(
            lhsResult.inferredType, equalsName, node.fileOffset)
        .member;

    // This ends any shorting in `node.left`.
    Expression left = lhsResult.expression;

    inferrer.flowAnalysis
        .ifNullExpression_rightBegin(node.left, lhsResult.inferredType);

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
    DartType originalLhsType = lhsResult.inferredType;
    DartType nonNullableLhsType = inferrer.computeNonNullable(originalLhsType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(nonNullableLhsType, rhsResult.inferredType,
            inferrer.library.library);
    Expression replacement;
    if (left is ThisExpression) {
      replacement = left;
    } else {
      VariableDeclaration variable =
          createVariable(left, lhsResult.inferredType);
      Expression equalsNull = inferrer.createEqualsNull(
          lhsResult.expression.fileOffset,
          createVariableGet(variable),
          equalsMember);
      VariableGet variableGet = createVariableGet(variable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableLhsType, originalLhsType)) {
        variableGet.promotedType = nonNullableLhsType;
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, rhsResult.expression, variableGet, inferredType);
      replacement = new Let(variable, conditional)
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  StatementInferenceResult visitIfStatement(IfStatement node) {
    inferrer.flowAnalysis.ifStatement_conditionBegin();
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
    bool isSimpleBody = node.body is Block ||
        node.body is IfStatement ||
        node.body is TryStatement;
    if (isSimpleBody) {
      inferrer.flowAnalysis.labeledStatement_begin(node);
    }

    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);

    if (isSimpleBody) {
      inferrer.flowAnalysis.labeledStatement_end();
    }

    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    return const StatementInferenceResult();
  }

  DartType getSpreadElementType(
      DartType spreadType, DartType spreadTypeBound, bool isNullAware) {
    if (inferrer.coreTypes.isNull(spreadTypeBound)) {
      if (inferrer.isNonNullableByDefault) {
        return isNullAware ? const NeverType(Nullability.nonNullable) : null;
      } else {
        return isNullAware ? const NullType() : null;
      }
    }
    if (spreadTypeBound is InterfaceType) {
      List<DartType> supertypeArguments = inferrer.typeSchemaEnvironment
          .getTypeArgumentsAsInstanceOf(
              spreadTypeBound, inferrer.coreTypes.iterableClass);
      if (supertypeArguments == null) {
        return null;
      }
      return supertypeArguments.single;
    } else if (spreadType is DynamicType) {
      return const DynamicType();
    } else if (inferrer.coreTypes.isBottom(spreadType)) {
      return const NeverType(Nullability.nonNullable);
    }
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
          new InterfaceType(
              inferrer.coreTypes.iterableClass,
              inferrer.library.nullableIfTrue(element.isNullAware),
              <DartType>[inferredTypeArgument]),
          inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      if (element.isNullAware) {
        reportNonNullableInNullAwareWarningIfNeeded(
            spreadResult.inferredType, "...?", element.expression.fileOffset);
      }
      element.expression = spreadResult.expression..parent = element;
      DartType spreadType = spreadResult.inferredType;
      inferredSpreadTypes[element.expression] = spreadType;
      Expression replacement = element;
      DartType spreadTypeBound = inferrer.resolveTypeParameter(spreadType);
      DartType spreadElementType = getSpreadElementType(
          spreadType, spreadTypeBound, element.isNullAware);
      if (typeChecksNeeded) {
        if (spreadElementType == null) {
          if (inferrer.coreTypes.isNull(spreadTypeBound) &&
              !element.isNullAware) {
            replacement = inferrer.helper.buildProblem(
                templateNonNullAwareSpreadIsNull.withArguments(
                    spreadType, inferrer.isNonNullableByDefault),
                element.expression.fileOffset,
                1);
          } else {
            if (inferrer.isNonNullableByDefault &&
                spreadType.isPotentiallyNullable &&
                spreadType is! DynamicType &&
                spreadType is! NullType &&
                !element.isNullAware) {
              replacement = inferrer.helper.buildProblem(
                  messageNullableSpreadError, element.expression.fileOffset, 1);
            }

            replacement = inferrer.helper.buildProblem(
                templateSpreadTypeMismatch.withArguments(
                    spreadType, inferrer.isNonNullableByDefault),
                element.expression.fileOffset,
                1);
          }
        } else if (spreadTypeBound is InterfaceType) {
          if (!inferrer.isAssignable(inferredTypeArgument, spreadElementType)) {
            if (inferrer.isNonNullableByDefault) {
              IsSubtypeOf subtypeCheckResult = inferrer.typeSchemaEnvironment
                  .performNullabilityAwareSubtypeCheck(
                      spreadElementType, inferredTypeArgument);
              if (subtypeCheckResult.isSubtypeWhenIgnoringNullabilities()) {
                if (spreadElementType == subtypeCheckResult.subtype &&
                    inferredTypeArgument == subtypeCheckResult.supertype) {
                  replacement = inferrer.helper.buildProblem(
                      templateSpreadElementTypeMismatchNullability
                          .withArguments(
                              spreadElementType,
                              inferredTypeArgument,
                              inferrer.isNonNullableByDefault),
                      element.expression.fileOffset,
                      1);
                } else {
                  replacement = inferrer.helper.buildProblem(
                      templateSpreadElementTypeMismatchPartNullability
                          .withArguments(
                              spreadElementType,
                              inferredTypeArgument,
                              subtypeCheckResult.subtype,
                              subtypeCheckResult.supertype,
                              inferrer.isNonNullableByDefault),
                      element.expression.fileOffset,
                      1);
                }
              } else {
                replacement = inferrer.helper.buildProblem(
                    templateSpreadElementTypeMismatch.withArguments(
                        spreadElementType,
                        inferredTypeArgument,
                        inferrer.isNonNullableByDefault),
                    element.expression.fileOffset,
                    1);
              }
            } else {
              replacement = inferrer.helper.buildProblem(
                  templateSpreadElementTypeMismatch.withArguments(
                      spreadElementType,
                      inferredTypeArgument,
                      inferrer.isNonNullableByDefault),
                  element.expression.fileOffset,
                  1);
            }
          }
          if (inferrer.isNonNullableByDefault &&
              spreadType.isPotentiallyNullable &&
              spreadType is! DynamicType &&
              spreadType is! NullType &&
              !element.isNullAware) {
            replacement = inferrer.helper.buildProblem(
                messageNullableSpreadError, element.expression.fileOffset, 1);
          }
        }
      }
      // Use 'dynamic' for error recovery.
      element.elementType = spreadElementType ?? const DynamicType();
      return new ExpressionInferenceResult(element.elementType, replacement);
    } else if (element is IfElement) {
      inferrer.flowAnalysis.ifStatement_conditionBegin();
      DartType boolType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          element.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      Expression condition =
          inferrer.ensureAssignableResult(boolType, conditionResult);
      element.condition = condition..parent = element;
      inferrer.flowAnalysis.ifStatement_thenBegin(condition);
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
        inferrer.flowAnalysis.ifStatement_elseBegin();
        otherwiseResult = inferElement(
            element.otherwise,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        element.otherwise = otherwiseResult.expression..parent = element;
      }
      inferrer.flowAnalysis.ifStatement_end(element.otherwise != null);
      return new ExpressionInferenceResult(
          otherwiseResult == null
              ? thenResult.inferredType
              : inferrer.typeSchemaEnvironment.getStandardUpperBound(
                  thenResult.inferredType,
                  otherwiseResult.inferredType,
                  inferrer.library.library),
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
            element,
            element.variable,
            element.iterable,
            element.syntheticAssignment,
            element.expressionEffects,
            isAsync: element.isAsync,
            hasProblem: element.problem != null);
      } else {
        result = handleForInDeclaringVariable(element, element.variable,
            element.iterable, element.expressionEffects,
            isAsync: element.isAsync);
      }
      element.variable = result.variable..parent = element;
      element.iterable = result.iterable..parent = element;
      // TODO(johnniwinther): Use ?.. here instead.
      element.syntheticAssignment = result.syntheticAssignment;
      result.syntheticAssignment?.parent = element;
      // TODO(johnniwinther): Use ?.. here instead.
      element.expressionEffects = result.expressionSideEffects;
      result.expressionSideEffects?.parent = element;

      if (element.problem != null) {
        ExpressionInferenceResult problemResult = inferrer.inferExpression(
            element.problem,
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        element.problem = problemResult.expression..parent = element;
      }
      ExpressionInferenceResult bodyResult = inferElement(
          element.body,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      element.body = bodyResult.expression..parent = element;
      // This is matched by the call to [forEach_bodyBegin] in
      // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
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
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          listType,
          listClass.typeParameters,
          null,
          null,
          typeContext,
          inferredTypes,
          inferrer.library.library,
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
          inferredTypes,
          inferrer.library.library);
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
        listClass, inferrer.library.nonNullable, [inferredTypeArgument]);
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
    inferrer.flowAnalysis.logicalBinaryOp_begin();
    ExpressionInferenceResult leftResult = inferrer.inferExpression(
        node.left, boolType, !inferrer.isTopLevel,
        isVoidAllowed: false);
    Expression left = inferrer.ensureAssignableResult(boolType, leftResult);
    node.left = left..parent = node;
    inferrer.flowAnalysis.logicalBinaryOp_rightBegin(node.left,
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND);
    ExpressionInferenceResult rightResult = inferrer.inferExpression(
        node.right, boolType, !inferrer.isTopLevel,
        isVoidAllowed: false);
    Expression right = inferrer.ensureAssignableResult(boolType, rightResult);
    node.right = right..parent = node;
    inferrer.flowAnalysis.logicalBinaryOp_end(node, node.right,
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND);
    return new ExpressionInferenceResult(boolType, node);
  }

  // Calculates the key and the value type of a spread map entry of type
  // spreadMapEntryType and stores them in output in positions offset and offset
  // + 1.  If the types can't be calculated, for example, if spreadMapEntryType
  // is a function type, the original values in output are preserved.
  void storeSpreadMapEntryElementTypes(DartType spreadMapEntryType,
      bool isNullAware, List<DartType> output, int offset) {
    DartType typeBound = inferrer.resolveTypeParameter(spreadMapEntryType);
    if (inferrer.coreTypes.isNull(typeBound)) {
      if (isNullAware) {
        if (inferrer.isNonNullableByDefault) {
          output[offset] =
              output[offset + 1] = const NeverType(Nullability.nonNullable);
        } else {
          output[offset] = output[offset + 1] = const NullType();
        }
      }
    } else if (typeBound is InterfaceType) {
      List<DartType> supertypeArguments = inferrer.typeSchemaEnvironment
          .getTypeArgumentsAsInstanceOf(typeBound, inferrer.coreTypes.mapClass);
      if (supertypeArguments != null) {
        output[offset] = supertypeArguments[0];
        output[offset + 1] = supertypeArguments[1];
      }
    } else if (spreadMapEntryType is DynamicType) {
      output[offset] = output[offset + 1] = const DynamicType();
    } else if (inferrer.coreTypes.isBottom(spreadMapEntryType)) {
      output[offset] =
          output[offset + 1] = const NeverType(Nullability.nonNullable);
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
      if (entry.isNullAware) {
        reportNonNullableInNullAwareWarningIfNeeded(
            spreadResult.inferredType, "...?", entry.expression.fileOffset);
      }
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
      DartType spreadTypeBound = inferrer.resolveTypeParameter(spreadType);
      DartType actualElementType =
          getSpreadElementType(spreadType, spreadTypeBound, entry.isNullAware);

      MapEntry replacement = entry;
      if (typeChecksNeeded) {
        if (actualKeyType == null) {
          if (inferrer.coreTypes.isNull(spreadTypeBound) &&
              !entry.isNullAware) {
            replacement = new MapEntry(
                inferrer.helper.buildProblem(
                    templateNonNullAwareSpreadIsNull.withArguments(
                        spreadType, inferrer.isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1),
                new NullLiteral())
              ..fileOffset = entry.fileOffset;
          } else if (actualElementType != null) {
            if (inferrer.isNonNullableByDefault &&
                spreadType.isPotentiallyNullable &&
                spreadType is! DynamicType &&
                spreadType is! NullType &&
                !entry.isNullAware) {
              replacement = new SpreadMapEntry(
                  inferrer.helper.buildProblem(messageNullableSpreadError,
                      entry.expression.fileOffset, 1),
                  false)
                ..fileOffset = entry.fileOffset;
            }

            // Don't report the error here, it might be an ambiguous Set.  The
            // error is reported in checkMapEntry if it's disambiguated as map.
            iterableSpreadType = spreadType;
          } else {
            replacement = new MapEntry(
                inferrer.helper.buildProblem(
                    templateSpreadMapEntryTypeMismatch.withArguments(
                        spreadType, inferrer.isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1),
                new NullLiteral())
              ..fileOffset = entry.fileOffset;
          }
        } else if (spreadTypeBound is InterfaceType) {
          Expression keyError;
          Expression valueError;
          if (!inferrer.isAssignable(inferredKeyType, actualKeyType)) {
            if (inferrer.isNonNullableByDefault) {
              IsSubtypeOf subtypeCheckResult = inferrer.typeSchemaEnvironment
                  .performNullabilityAwareSubtypeCheck(
                      actualKeyType, inferredKeyType);
              if (subtypeCheckResult.isSubtypeWhenIgnoringNullabilities()) {
                if (actualKeyType == subtypeCheckResult.subtype &&
                    inferredKeyType == subtypeCheckResult.supertype) {
                  keyError = inferrer.helper.buildProblem(
                      templateSpreadMapEntryElementKeyTypeMismatchNullability
                          .withArguments(actualKeyType, inferredKeyType,
                              inferrer.isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                } else {
                  keyError = inferrer.helper.buildProblem(
                      // ignore: lines_longer_than_80_chars
                      templateSpreadMapEntryElementKeyTypeMismatchPartNullability
                          .withArguments(
                              actualKeyType,
                              inferredKeyType,
                              subtypeCheckResult.subtype,
                              subtypeCheckResult.supertype,
                              inferrer.isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                }
              } else {
                keyError = inferrer.helper.buildProblem(
                    templateSpreadMapEntryElementKeyTypeMismatch.withArguments(
                        actualKeyType,
                        inferredKeyType,
                        inferrer.isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1);
              }
            } else {
              keyError = inferrer.helper.buildProblem(
                  templateSpreadMapEntryElementKeyTypeMismatch.withArguments(
                      actualKeyType,
                      inferredKeyType,
                      inferrer.isNonNullableByDefault),
                  entry.expression.fileOffset,
                  1);
            }
          }
          if (!inferrer.isAssignable(inferredValueType, actualValueType)) {
            if (inferrer.isNonNullableByDefault) {
              IsSubtypeOf subtypeCheckResult = inferrer.typeSchemaEnvironment
                  .performNullabilityAwareSubtypeCheck(
                      actualValueType, inferredValueType);
              if (subtypeCheckResult.isSubtypeWhenIgnoringNullabilities()) {
                if (actualValueType == subtypeCheckResult.subtype &&
                    inferredValueType == subtypeCheckResult.supertype) {
                  valueError = inferrer.helper.buildProblem(
                      templateSpreadMapEntryElementValueTypeMismatchNullability
                          .withArguments(actualValueType, inferredValueType,
                              inferrer.isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                } else {
                  valueError = inferrer.helper.buildProblem(
                      // ignore: lines_longer_than_80_chars
                      templateSpreadMapEntryElementValueTypeMismatchPartNullability
                          .withArguments(
                              actualValueType,
                              inferredValueType,
                              subtypeCheckResult.subtype,
                              subtypeCheckResult.supertype,
                              inferrer.isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                }
              } else {
                valueError = inferrer.helper.buildProblem(
                    templateSpreadMapEntryElementValueTypeMismatch
                        .withArguments(actualValueType, inferredValueType,
                            inferrer.isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1);
              }
            } else {
              valueError = inferrer.helper.buildProblem(
                  templateSpreadMapEntryElementValueTypeMismatch.withArguments(
                      actualValueType,
                      inferredValueType,
                      inferrer.isNonNullableByDefault),
                  entry.expression.fileOffset,
                  1);
            }
          }
          if (inferrer.isNonNullableByDefault &&
              spreadType.isPotentiallyNullable &&
              spreadType is! DynamicType &&
              spreadType is! NullType &&
              !entry.isNullAware) {
            keyError = inferrer.helper.buildProblem(
                messageNullableSpreadError, entry.expression.fileOffset, 1);
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
      entry.entryType = new InterfaceType(
          mapEntryClass,
          inferrer.library.nonNullable,
          <DartType>[actualKeyType, actualValueType]);

      bool isMap = inferrer.typeSchemaEnvironment.isSubtypeOf(
          spreadType,
          inferrer.coreTypes.mapRawType(inferrer.library.nullable),
          SubtypeCheckMode.withNullabilities);
      bool isIterable = inferrer.typeSchemaEnvironment.isSubtypeOf(
          spreadType,
          inferrer.coreTypes.iterableRawType(inferrer.library.nullable),
          SubtypeCheckMode.withNullabilities);
      if (isMap && !isIterable) {
        mapSpreadOffset = entry.fileOffset;
      }
      if (!isMap && isIterable) {
        iterableSpreadOffset = entry.expression.fileOffset;
      }

      return replacement;
    } else if (entry is IfMapEntry) {
      inferrer.flowAnalysis.ifStatement_conditionBegin();
      DartType boolType =
          inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
      ExpressionInferenceResult conditionResult = inferrer.inferExpression(
          entry.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      Expression condition =
          inferrer.ensureAssignableResult(boolType, conditionResult);
      entry.condition = condition..parent = entry;
      inferrer.flowAnalysis.ifStatement_thenBegin(condition);
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
        inferrer.flowAnalysis.ifStatement_elseBegin();
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
            .getStandardUpperBound(actualKeyType, actualTypes[length - 2],
                inferrer.library.library);
        actualTypes[length - 1] = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(actualValueType, actualTypes[length - 1],
                inferrer.library.library);
        int lengthForSet = actualTypesForSet.length;
        actualTypesForSet[lengthForSet - 1] = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(actualTypeForSet,
                actualTypesForSet[lengthForSet - 1], inferrer.library.library);
        entry.otherwise = otherwise..parent = entry;
      }
      inferrer.flowAnalysis.ifStatement_end(entry.otherwise != null);
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
        result = handleForInWithoutVariable(entry, entry.variable,
            entry.iterable, entry.syntheticAssignment, entry.expressionEffects,
            isAsync: entry.isAsync, hasProblem: entry.problem != null);
      } else {
        result = handleForInDeclaringVariable(
            entry, entry.variable, entry.iterable, entry.expressionEffects,
            isAsync: entry.isAsync);
      }
      entry.variable = result.variable..parent = entry;
      entry.iterable = result.iterable..parent = entry;
      // TODO(johnniwinther): Use ?.. here instead.
      entry.syntheticAssignment = result.syntheticAssignment;
      result.syntheticAssignment?.parent = entry;
      // TODO(johnniwinther): Use ?.. here instead.
      entry.expressionEffects = result.expressionSideEffects;
      result.expressionSideEffects?.parent = entry;
      if (entry.problem != null) {
        ExpressionInferenceResult problemResult = inferrer.inferExpression(
            entry.problem,
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        entry.problem = problemResult.expression..parent = entry;
      }
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
      // This is matched by the call to [forEach_bodyBegin] in
      // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
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
              templateSpreadMapEntryTypeMismatch.withArguments(
                  iterableSpreadType, inferrer.isNonNullableByDefault),
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
    DartType unfuturedTypeContext =
        inferrer.typeSchemaEnvironment.flatten(typeContext);
    if (!inferrer.isTopLevel && inferenceNeeded) {
      // Ambiguous set/map literal
      if (unfuturedTypeContext is InterfaceType) {
        typeContextIsMap = typeContextIsMap ||
            inferrer.classHierarchy.isSubtypeOf(
                unfuturedTypeContext.classNode, inferrer.coreTypes.mapClass);
        typeContextIsIterable = typeContextIsIterable ||
            inferrer.classHierarchy.isSubtypeOf(unfuturedTypeContext.classNode,
                inferrer.coreTypes.iterableClass);
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
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          mapType,
          mapClass.typeParameters,
          null,
          null,
          typeContext,
          inferredTypes,
          inferrer.library.library,
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
        spreadTypeContext = inferrer.typeSchemaEnvironment.getTypeAsInstanceOf(
            unfuturedTypeContext,
            inferrer.coreTypes.iterableClass,
            inferrer.library.library,
            inferrer.coreTypes);
      } else if (!typeContextIsIterable && typeContextIsMap) {
        spreadTypeContext = new InterfaceType(
            inferrer.coreTypes.mapClass,
            inferrer.library.nonNullable,
            <DartType>[inferredKeyType, inferredValueType]);
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
            inferrer.library.library,
            isConst: node.isConst);
        inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
            inferrer.coreTypes.thisInterfaceType(
                inferrer.coreTypes.setClass, inferrer.library.nonNullable),
            inferrer.coreTypes.setClass.typeParameters,
            formalTypesForSet,
            actualTypesForSet,
            typeContext,
            inferredTypesForSet,
            inferrer.library.library);
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
            inferrer.library.nonNullable, inferredTypesForSet);
        return new ExpressionInferenceResult(inferredType, setLiteral);
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        Expression replacement = node;
        if (!inferrer.isTopLevel) {
          replacement = inferrer.helper.buildProblem(
              messageCantDisambiguateNotEnoughInformation, node.fileOffset, 1);
        }
        return new ExpressionInferenceResult(const BottomType(), replacement);
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
          inferredTypes,
          inferrer.library.library);
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
    DartType inferredType = new InterfaceType(mapClass,
        inferrer.library.nonNullable, [inferredKeyType, inferredValueType]);
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
      MethodInvocation node, DartType typeContext) {
    assert(node.name != unaryMinusName);
    ExpressionInferenceResult result = inferrer.inferNullAwareExpression(
        node.receiver, const UnknownType(), true);
    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;
    return inferrer.inferMethodInvocation(node.fileOffset, nullAwareGuards,
        receiver, receiverType, node.name, node.arguments, typeContext,
        isExpressionInvocation: false, isImplicitCall: false);
  }

  ExpressionInferenceResult visitExpressionInvocation(
      ExpressionInvocation node, DartType typeContext) {
    ExpressionInferenceResult result = inferrer.inferNullAwareExpression(
        node.expression, const UnknownType(), true);
    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;
    return inferrer.inferMethodInvocation(node.fileOffset, nullAwareGuards,
        receiver, receiverType, callName, node.arguments, typeContext,
        isExpressionInvocation: true, isImplicitCall: true);
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
    ExpressionInferenceResult operandResult = inferrer.inferNullAwareExpression(
        node.operand, inferrer.computeNullable(typeContext), true);

    Link<NullAwareGuard> nullAwareGuards = operandResult.nullAwareGuards;
    Expression operand = operandResult.nullAwareAction;
    DartType operandType = operandResult.nullAwareActionType;

    node.operand = operand..parent = node;
    reportNonNullableInNullAwareWarningIfNeeded(
        operandType, "!", node.operand.fileOffset);
    inferrer.flowAnalysis.nonNullAssert_end(node.operand);
    DartType nonNullableResultType = inferrer.computeNonNullable(operandType);
    return inferrer.createNullAwareExpressionInferenceResult(
        nonNullableResultType, node, nullAwareGuards);
  }

  ExpressionInferenceResult visitNullAwareMethodInvocation(
      NullAwareMethodInvocation node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferrer.inferSyntheticVariableNullAware(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard =
        inferrer.createNullAwareGuard(node.variable);
    ExpressionInferenceResult invocationResult = inferrer.inferExpression(
        node.invocation, typeContext, true,
        isVoidAllowed: true);
    return inferrer.createNullAwareExpressionInferenceResult(
        invocationResult.inferredType,
        invocationResult.expression,
        nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwarePropertyGet(
      NullAwarePropertyGet node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferrer.inferSyntheticVariableNullAware(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard =
        inferrer.createNullAwareGuard(node.variable);
    ExpressionInferenceResult readResult =
        inferrer.inferExpression(node.read, typeContext, true);
    return inferrer.createNullAwareExpressionInferenceResult(
        readResult.inferredType,
        readResult.expression,
        nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwarePropertySet(
      NullAwarePropertySet node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferrer.inferSyntheticVariableNullAware(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard =
        inferrer.createNullAwareGuard(node.variable);
    ExpressionInferenceResult writeResult =
        inferrer.inferExpression(node.write, typeContext, true);
    return inferrer.createNullAwareExpressionInferenceResult(
        writeResult.inferredType,
        writeResult.expression,
        nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwareExtension(
      NullAwareExtension node, DartType typeContext) {
    inferrer.inferSyntheticVariable(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard =
        inferrer.createNullAwareGuard(node.variable);
    ExpressionInferenceResult expressionResult =
        inferrer.inferExpression(node.expression, const UnknownType(), true);
    return inferrer.createNullAwareExpressionInferenceResult(
        expressionResult.inferredType,
        expressionResult.expression,
        const Link<NullAwareGuard>().prepend(nullAwareGuard));
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
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
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

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.propertyName, node.writeOffset,
        setter: true, instrumented: true, includeExtensionMethods: true);
    DartType writeType = inferrer.getSetterType(writeTarget, receiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        writeType,
        read,
        readType,
        node.binaryName,
        node.rhs);
    DartType binaryType = binaryResult.inferredType;

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
    return inferrer.createNullAwareExpressionInferenceResult(
        binaryType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIfNullPropertySet(
      IfNullPropertySet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);
    inferrer.instrumentation?.record(
        inferrer.uriForInstrumentation,
        receiverVariable.fileOffset,
        'type',
        new InstrumentationValueForType(receiverType));
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
        readReceiver, receiverType, node.propertyName, const UnknownType(),
        isThisReceiver: node.receiver is ThisExpression);

    reportNonNullableInNullAwareWarningIfNeeded(
        readResult.inferredType, "??=", node.readOffset);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.propertyName, receiver.fileOffset,
        setter: true, instrumented: true, includeExtensionMethods: true);
    DartType writeContext = inferrer.getSetterType(writeTarget, receiverType);

    inferrer.flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult rhsResult = inferrer
        .inferExpression(node.rhs, writeContext, true, isVoidAllowed: true);
    inferrer.flowAnalysis.ifNullExpression_end();

    Expression rhs = inferrer.ensureAssignableResult(writeContext, rhsResult);

    DartType writeType = rhsResult.inferredType;
    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        receiverType, node.propertyName, writeTarget, rhs,
        forEffect: node.forEffect, valueType: writeType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.fileOffset)
        .member;

    DartType nonNullableReadType = inferrer.computeNonNullable(readType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(
            nonNullableReadType, writeType, inferrer.library.library);

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.a = b : null
      //
      Expression equalsNull =
          inferrer.createEqualsNull(node.fileOffset, read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          write, new NullLiteral()..fileOffset = node.fileOffset, inferredType)
        ..fileOffset = node.fileOffset;
      replacement =
          new Let(receiverVariable, conditional..fileOffset = node.fileOffset)
            ..fileOffset = node.fileOffset;
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      VariableDeclaration readVariable = createVariable(read, readType);
      Expression equalsNull = inferrer.createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      VariableGet variableGet = createVariableGet(readVariable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, write, variableGet, inferredType)
        ..fileOffset = node.fileOffset;
      replacement =
          new Let(receiverVariable, createLet(readVariable, conditional))
            ..fileOffset = node.fileOffset;
    }

    return inferrer.createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIfNullSet(
      IfNullSet node, DartType typeContext) {
    ExpressionInferenceResult readResult =
        inferrer.inferNullAwareExpression(node.read, const UnknownType(), true);
    reportNonNullableInNullAwareWarningIfNeeded(
        readResult.inferredType, "??=", node.read.fileOffset);

    Link<NullAwareGuard> nullAwareGuards = readResult.nullAwareGuards;
    Expression read = readResult.nullAwareAction;
    DartType readType = readResult.nullAwareActionType;

    inferrer.flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult writeResult = inferrer
        .inferExpression(node.write, typeContext, true, isVoidAllowed: true);
    inferrer.flowAnalysis.ifNullExpression_end();

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.fileOffset)
        .member;

    DartType originalReadType = readType;
    DartType nonNullableReadType =
        inferrer.computeNonNullable(originalReadType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(nonNullableReadType, writeResult.inferredType,
            inferrer.library.library);

    Expression replacement;
    if (node.forEffect) {
      // Encode `a ??= b` as:
      //
      //     a == null ? a = b : null
      //
      Expression equalsNull =
          inferrer.createEqualsNull(node.fileOffset, read, equalsMember);
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
      VariableDeclaration readVariable = createVariable(read, readType);
      Expression equalsNull = inferrer.createEqualsNull(
          node.fileOffset, createVariableGet(readVariable), equalsMember);
      VariableGet variableGet = createVariableGet(readVariable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableReadType, originalReadType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, writeResult.expression, variableGet, inferredType)
        ..fileOffset = node.fileOffset;
      replacement = new Let(readVariable, conditional)
        ..fileOffset = node.fileOffset;
    }
    return inferrer.createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIndexGet(IndexGet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    ObjectAccessTarget indexGetTarget = inferrer.findInterfaceMember(
        receiverType, indexGetName, node.fileOffset,
        includeExtensionMethods: true);

    DartType indexType = inferrer.getIndexKeyType(indexGetTarget, receiverType);

    MethodContravarianceCheckKind readCheckKind =
        inferrer.preCheckInvocationContravariance(receiverType, indexGetTarget,
            isThisReceiver: node.receiver is ThisExpression);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index = inferrer.ensureAssignableResult(indexType, indexResult);

    ExpressionInferenceResult replacement = _computeIndexGet(
        node.fileOffset,
        receiver,
        receiverType,
        indexGetTarget,
        index,
        indexType,
        readCheckKind);
    return inferrer.createNullAwareExpressionInferenceResult(
        replacement.inferredType, replacement.expression, nullAwareGuards);
  }

  ExpressionInferenceResult visitIndexSet(IndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable;
    if (!node.forEffect && !isPureExpression(receiver)) {
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
    if (!node.forEffect && !isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    VariableDeclaration valueVariable;
    Expression returnedValue;
    if (node.forEffect) {
    } else if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment = _computeIndexSet(node.fileOffset, receiver,
        receiverType, indexSetTarget, index, indexType, value, valueType);

    Expression replacement;
    if (node.forEffect) {
      replacement = assignment;
    } else {
      VariableDeclaration assignmentVariable =
          createVariable(assignment, const VoidType());
      replacement = createLet(assignmentVariable, returnedValue);
      if (valueVariable != null) {
        replacement = createLet(valueVariable, replacement);
      }
      if (indexVariable != null) {
        replacement = createLet(indexVariable, replacement);
      }
      if (receiverVariable != null) {
        replacement = createLet(receiverVariable, replacement);
      }
    }
    replacement.fileOffset = node.fileOffset;
    return inferrer.createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitSuperIndexSet(
      SuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget indexSetTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType indexType =
        inferrer.getIndexKeyType(indexSetTarget, inferrer.thisType);
    DartType valueType =
        inferrer.getIndexSetValueType(indexSetTarget, inferrer.thisType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index = inferrer.ensureAssignableResult(indexType, indexResult);

    VariableDeclaration indexVariable;
    if (!isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    VariableDeclaration valueVariable;
    Expression returnedValue;
    if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment;
    if (indexSetTarget.isMissing) {
      assignment =
          inferrer.createMissingSuperIndexSet(node.fileOffset, index, value);
    } else {
      assert(indexSetTarget.isInstanceMember || indexSetTarget.isObjectMember);
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'target',
          new InstrumentationValueForMember(node.setter));
      assignment = new SuperMethodInvocation(
          indexSetName,
          new Arguments(<Expression>[index, value])
            ..fileOffset = node.fileOffset,
          indexSetTarget.member)
        ..fileOffset = node.fileOffset;
    }
    VariableDeclaration assignmentVariable =
        createVariable(assignment, const VoidType());
    Expression replacement = createLet(assignmentVariable, returnedValue);
    if (valueVariable != null) {
      replacement = createLet(valueVariable, replacement);
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
    }
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

    VariableDeclaration receiverVariable;
    if (!isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.setter, null, ProcedureKind.Operator, extensionTypeArguments);

    DartType indexType = inferrer.getIndexKeyType(target, receiverType);
    DartType valueType = inferrer.getIndexSetValueType(target, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index = inferrer.ensureAssignableResult(indexType, indexResult);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    VariableDeclaration valueVariable;
    Expression returnedValue;
    if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment = _computeIndexSet(node.fileOffset, receiver,
        receiverType, target, index, indexType, value, valueType);

    VariableDeclaration assignmentVariable =
        createVariable(assignment, const VoidType());
    Expression replacement = createLet(assignmentVariable, returnedValue);
    if (valueVariable != null) {
      replacement = createLet(valueVariable, replacement);
    }
    if (receiverVariable != null) {
      replacement = createLet(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullIndexSet(
      IfNullIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (isPureExpression(readReceiver)) {
      writeReceiver = clonePureExpression(readReceiver);
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

    VariableDeclaration indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(
        node.readOffset,
        readReceiver,
        receiverType,
        readTarget,
        readIndex,
        readIndexType,
        checkKind);
    reportNonNullableInNullAwareWarningIfNeeded(
        readResult.inferredType, "??=", node.readOffset);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    inferrer.flowAnalysis.ifNullExpression_rightBegin(read, readType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);
    inferrer.flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = inferrer.computeNonNullable(readType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(nonNullableReadType, valueResult.inferredType,
            inferrer.library.library);

    VariableDeclaration valueVariable;
    Expression returnedValue;
    if (node.forEffect) {
      // No need for value variable.
    } else if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
        node.writeOffset,
        writeReceiver,
        receiverType,
        writeTarget,
        writeIndex,
        writeIndexType,
        value,
        valueType);

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
      Expression equalsNull =
          inferrer.createEqualsNull(node.testOffset, read, equalsMember);
      ConditionalExpression conditional = new ConditionalExpression(equalsNull,
          write, new NullLiteral()..fileOffset = node.testOffset, inferredType)
        ..fileOffset = node.testOffset;
      inner = conditional;
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
      VariableDeclaration readVariable = createVariable(read, readType);
      Expression equalsNull = inferrer.createEqualsNull(
          node.testOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet variableGet = createVariableGet(readVariable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue);
      if (valueVariable != null) {
        result = createLet(valueVariable, result);
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, result, variableGet, inferredType)
        ..fileOffset = node.fileOffset;
      inner = createLet(readVariable, conditional);
    }
    if (indexVariable != null) {
      inner = createLet(indexVariable, inner);
    }

    Expression replacement;
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, inner)
        ..fileOffset = node.fileOffset;
    } else {
      replacement = inner;
    }
    return inferrer.createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIfNullSuperIndexSet(
      IfNullSuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget readTarget = node.getter != null
        ? new ObjectAccessTarget.interfaceMember(node.getter,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType readType = inferrer.getReturnType(readTarget, inferrer.thisType);
    reportNonNullableInNullAwareWarningIfNeeded(
        readType, "??=", node.readOffset);
    DartType readIndexType =
        inferrer.getIndexKeyType(readTarget, inferrer.thisType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, inferrer.thisType);
    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    Expression read;

    if (readTarget.isMissing) {
      read = inferrer.createMissingSuperIndexGet(node.readOffset, readIndex);
    } else {
      assert(readTarget.isInstanceMember || readTarget.isObjectMember);
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

    inferrer.flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);
    inferrer.flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = inferrer.computeNonNullable(readType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(nonNullableReadType, valueResult.inferredType,
            inferrer.library.library);

    VariableDeclaration valueVariable;
    Expression returnedValue;
    if (node.forEffect) {
      // No need for a value variable.
    } else if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    Expression write;

    if (writeTarget.isMissing) {
      write = inferrer.createMissingSuperIndexSet(
          node.writeOffset, writeIndex, value);
    } else {
      assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
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
      assert(valueVariable == null);
      Expression equalsNull =
          inferrer.createEqualsNull(node.testOffset, read, equalsMember);
      replacement = new ConditionalExpression(equalsNull, write,
          new NullLiteral()..fileOffset = node.testOffset, inferredType)
        ..fileOffset = node.testOffset;
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

      VariableDeclaration readVariable = createVariable(read, readType);
      Expression equalsNull = inferrer.createEqualsNull(
          node.testOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue);
      if (valueVariable != null) {
        result = createLet(valueVariable, result);
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, result, readVariableGet, inferredType)
        ..fileOffset = node.fileOffset;
      replacement = createLet(readVariable, conditional);
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
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

    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

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

    VariableDeclaration indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(
        node.readOffset,
        readReceiver,
        receiverType,
        readTarget,
        readIndex,
        readIndexType,
        MethodContravarianceCheckKind.none);
    reportNonNullableInNullAwareWarningIfNeeded(
        readResult.inferredType, "??=", node.readOffset);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    inferrer.flowAnalysis.ifNullExpression_rightBegin(read, readType);

    Member equalsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);
    inferrer.flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = inferrer.computeNonNullable(readType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(nonNullableReadType, valueResult.inferredType,
            inferrer.library.library);

    VariableDeclaration valueVariable;
    Expression returnedValue;
    if (node.forEffect) {
      // No need for a value variable.
    } else if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
        node.writeOffset,
        writeReceiver,
        receiverType,
        writeTarget,
        writeIndex,
        writeIndexType,
        value,
        valueType);

    Expression replacement;
    if (node.forEffect) {
      // Encode `Extension(o)[a] ??= b` as:
      //
      //     let receiverVariable = o;
      //     let indexVariable = a in
      //        receiverVariable[indexVariable] == null
      //          ? receiverVariable.[]=(indexVariable, b) : null
      //
      assert(valueVariable == null);
      Expression equalsNull =
          inferrer.createEqualsNull(node.testOffset, read, equalsMember);
      replacement = new ConditionalExpression(equalsNull, write,
          new NullLiteral()..fileOffset = node.testOffset, inferredType)
        ..fileOffset = node.testOffset;
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
      VariableDeclaration readVariable = createVariable(read, readType);
      Expression equalsNull = inferrer.createEqualsNull(
          node.testOffset, createVariableGet(readVariable), equalsMember);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue);
      if (valueVariable != null) {
        result = createLet(valueVariable, result);
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, result, readVariableGet, inferredType)
        ..fileOffset = node.fileOffset;
      replacement = createLet(readVariable, conditional);
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
    }
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  bool _isNull(Expression node) {
    return node is NullLiteral ||
        node is ConstantExpression && node.constant is NullConstant;
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
    inferrer.flowAnalysis.equalityOp_rightBegin(left, leftType);
    bool typeNeeded = !inferrer.isTopLevel;

    Expression equals;
    ExpressionInferenceResult rightResult = inferrer.inferExpression(
        right, const UnknownType(), typeNeeded,
        isVoidAllowed: false);

    if (inferrer.useNewMethodInvocationEncoding) {
      if (_isNull(right)) {
        equals = new EqualsNull(left, isNot: isNot)..fileOffset = fileOffset;
      } else if (_isNull(left)) {
        equals = new EqualsNull(rightResult.expression, isNot: isNot)
          ..fileOffset = fileOffset;
      }
      if (equals != null) {
        inferrer.flowAnalysis.equalityOp_end(
            equals, rightResult.expression, rightResult.inferredType,
            notEqual: isNot);
        return new ExpressionInferenceResult(
            inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            equals);
      }
    }

    ObjectAccessTarget equalsTarget = inferrer.findInterfaceMember(
        leftType, equalsName, fileOffset,
        includeExtensionMethods: true);

    assert(
        equalsTarget.isInstanceMember ||
            equalsTarget.isObjectMember ||
            equalsTarget.isNever,
        "Unexpected equals target $equalsTarget for "
        "$left ($leftType) == $right.");
    if (inferrer.instrumentation != null && leftType == const DynamicType()) {
      inferrer.instrumentation.record(
          inferrer.uriForInstrumentation,
          fileOffset,
          'target',
          new InstrumentationValueForMember(equalsTarget.member));
    }
    DartType rightType =
        inferrer.getPositionalParameterTypeForTarget(equalsTarget, leftType, 0);
    right = inferrer.ensureAssignableResult(
        rightType.withDeclaredNullability(inferrer.library.nullable),
        rightResult,
        errorTemplate: templateArgumentTypeNotAssignable,
        nullabilityErrorTemplate: templateArgumentTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateArgumentTypeNotAssignablePartNullability,
        nullabilityNullErrorTemplate:
            templateArgumentTypeNotAssignableNullabilityNull,
        nullabilityNullTypeErrorTemplate:
            templateArgumentTypeNotAssignableNullabilityNullType);

    if (inferrer.useNewMethodInvocationEncoding) {
      if (equalsTarget.isInstanceMember || equalsTarget.isObjectMember) {
        FunctionType functionType =
            inferrer.getFunctionType(equalsTarget, leftType);
        equals = new EqualsCall(left, right,
            isNot: isNot,
            functionType: functionType,
            interfaceTarget: equalsTarget.member)
          ..fileOffset = fileOffset;
      } else {
        assert(equalsTarget.isNever);
        FunctionType functionType = new FunctionType(
            [const DynamicType()],
            const NeverType(Nullability.nonNullable),
            inferrer.library.nonNullable);
        // Ensure operator == member even for `Never`.
        Member target = inferrer
            .findInterfaceMember(const DynamicType(), equalsName, -1,
                instrumented: false)
            .member;
        equals = new EqualsCall(left, right,
            isNot: isNot, functionType: functionType, interfaceTarget: target)
          ..fileOffset = fileOffset;
      }
    } else {
      equals = new MethodInvocation(
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
    }
    inferrer.flowAnalysis.equalityOp_end(
        equals, right, rightResult.inferredType,
        notEqual: isNot);
    return new ExpressionInferenceResult(
        equalsTarget.isNever
            ? const NeverType(Nullability.nonNullable)
            : inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
        equals);
  }

  /// Creates a binary expression of the binary operator with [binaryName] using
  /// [left] and [right] as operands.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [leftType] is
  /// the already inferred type of the [left] expression. The inferred type of
  /// [right] is computed by this method.
  ExpressionInferenceResult _computeBinaryExpression(
      int fileOffset,
      DartType contextType,
      Expression left,
      DartType leftType,
      Name binaryName,
      Expression right) {
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

    bool isSpecialCasedBinaryOperator = inferrer
        .isSpecialCasedBinaryOperatorForReceiverType(binaryTarget, leftType);

    bool typeNeeded = !inferrer.isTopLevel || isSpecialCasedBinaryOperator;

    DartType rightContextType = rightType;
    if (isSpecialCasedBinaryOperator) {
      rightContextType = inferrer.typeSchemaEnvironment
          .getContextTypeOfSpecialCasedBinaryOperator(
              contextType, leftType, rightType,
              isNonNullableByDefault: inferrer.isNonNullableByDefault);
    }

    ExpressionInferenceResult rightResult = inferrer.inferExpression(
        right, rightContextType, typeNeeded,
        isVoidAllowed: true);
    if (rightResult.inferredType == null) {
      assert(!typeNeeded,
          "Missing right type for overloaded arithmetic operator.");
      return new ExpressionInferenceResult(
          binaryType,
          inferrer.engine.forest
              .createBinary(fileOffset, left, binaryName, right));
    }

    right = inferrer.ensureAssignableResult(rightType, rightResult);

    if (isSpecialCasedBinaryOperator) {
      binaryType = inferrer.typeSchemaEnvironment
          .getTypeOfSpecialCasedBinaryOperator(
              leftType, rightResult.inferredType,
              isNonNullableByDefault: inferrer.isNonNullableByDefault);
    }

    if (!inferrer.isNonNullableByDefault) {
      binaryType = legacyErasure(binaryType);
    }

    Expression binary;
    switch (binaryTarget.kind) {
      case ObjectAccessTargetKind.missing:
        binary = inferrer.createMissingBinary(
            fileOffset, left, leftType, binaryName, right);
        break;
      case ObjectAccessTargetKind.ambiguous:
        binary = inferrer.createMissingBinary(
            fileOffset, left, leftType, binaryName, right,
            extensionAccessCandidates: binaryTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        assert(binaryTarget.extensionMethodKind != ProcedureKind.Setter);
        binary = new StaticInvocation(
            binaryTarget.member,
            new Arguments(<Expression>[
              left,
              right,
            ], types: binaryTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        if (inferrer.useNewMethodInvocationEncoding) {
          binary = new DynamicInvocation(
              DynamicAccessKind.Invalid,
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          binary = new MethodInvocation(
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset,
              binaryTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        if (inferrer.useNewMethodInvocationEncoding) {
          binary = new DynamicInvocation(
              DynamicAccessKind.Dynamic,
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          binary = new MethodInvocation(
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset,
              binaryTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.never:
        if (inferrer.useNewMethodInvocationEncoding) {
          binary = new DynamicInvocation(
              DynamicAccessKind.Never,
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          binary = new MethodInvocation(
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset,
              binaryTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if ((binaryTarget.isInstanceMember || binaryTarget.isObjectMember) &&
            inferrer.instrumentation != null &&
            leftType == const DynamicType()) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'target',
              new InstrumentationValueForMember(binaryTarget.member));
        }

        if (inferrer.useNewMethodInvocationEncoding) {
          binary = new InstanceInvocation(
              InstanceAccessKind.Instance,
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset,
              functionType: new FunctionType(
                  [rightType], binaryType, inferrer.library.nonNullable),
              interfaceTarget: binaryTarget.member)
            ..fileOffset = fileOffset;
        } else {
          binary = new MethodInvocation(
              left,
              binaryName,
              new Arguments(<Expression>[
                right,
              ])
                ..fileOffset = fileOffset,
              binaryTarget.member)
            ..fileOffset = fileOffset;
        }

        if (binaryCheckKind ==
            MethodContravarianceCheckKind.checkMethodReturn) {
          if (inferrer.instrumentation != null) {
            inferrer.instrumentation.record(
                inferrer.uriForInstrumentation,
                fileOffset,
                'checkReturn',
                new InstrumentationValueForType(binaryType));
          }
          binary = new AsExpression(binary, binaryType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = inferrer.isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        break;
    }

    if (!inferrer.isTopLevel && binaryTarget.isNullable) {
      return new ExpressionInferenceResult(
          binaryType,
          inferrer.helper.wrapInProblem(
              binary,
              templateNullableOperatorCallError.withArguments(
                  binaryName.text, leftType, inferrer.isNonNullableByDefault),
              binary.fileOffset,
              binaryName.text.length));
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
    switch (unaryTarget.kind) {
      case ObjectAccessTargetKind.missing:
        unary = inferrer.createMissingUnary(
            fileOffset, expression, expressionType, unaryName);
        break;
      case ObjectAccessTargetKind.ambiguous:
        unary = inferrer.createMissingUnary(
            fileOffset, expression, expressionType, unaryName,
            extensionAccessCandidates: unaryTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        assert(unaryTarget.extensionMethodKind != ProcedureKind.Setter);
        unary = new StaticInvocation(
            unaryTarget.member,
            new Arguments(<Expression>[
              expression,
            ], types: unaryTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        if (inferrer.useNewMethodInvocationEncoding) {
          unary = new DynamicInvocation(DynamicAccessKind.Invalid, expression,
              unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          unary = new MethodInvocation(
              expression,
              unaryName,
              new Arguments(<Expression>[])..fileOffset = fileOffset,
              unaryTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.never:
        if (inferrer.useNewMethodInvocationEncoding) {
          unary = new DynamicInvocation(DynamicAccessKind.Never, expression,
              unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          unary = new MethodInvocation(
              expression,
              unaryName,
              new Arguments(<Expression>[])..fileOffset = fileOffset,
              unaryTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        if (inferrer.useNewMethodInvocationEncoding) {
          unary = new DynamicInvocation(DynamicAccessKind.Dynamic, expression,
              unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          unary = new MethodInvocation(
              expression,
              unaryName,
              new Arguments(<Expression>[])..fileOffset = fileOffset,
              unaryTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if ((unaryTarget.isInstanceMember || unaryTarget.isObjectMember) &&
            inferrer.instrumentation != null &&
            expressionType == const DynamicType()) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'target',
              new InstrumentationValueForMember(unaryTarget.member));
        }

        if (inferrer.useNewMethodInvocationEncoding) {
          unary = new InstanceInvocation(
              InstanceAccessKind.Instance,
              expression,
              unaryName,
              new Arguments(<Expression>[])..fileOffset = fileOffset,
              functionType: new FunctionType(
                  <DartType>[], unaryType, inferrer.library.nonNullable),
              interfaceTarget: unaryTarget.member)
            ..fileOffset = fileOffset;
        } else {
          unary = new MethodInvocation(
              expression,
              unaryName,
              new Arguments(<Expression>[])..fileOffset = fileOffset,
              unaryTarget.member)
            ..fileOffset = fileOffset;
        }

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
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = inferrer.isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        break;
    }

    if (!inferrer.isNonNullableByDefault) {
      unaryType = legacyErasure(unaryType);
    }

    if (!inferrer.isTopLevel && unaryTarget.isNullable) {
      // TODO(johnniwinther): Special case 'unary-' in messages. It should
      // probably be referred to as "Unary operator '-' ...".
      return new ExpressionInferenceResult(
          unaryType,
          inferrer.helper.wrapInProblem(
              unary,
              templateNullableOperatorCallError.withArguments(unaryName.text,
                  expressionType, inferrer.isNonNullableByDefault),
              unary.fileOffset,
              unaryName == unaryMinusName ? 1 : unaryName.text.length));
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
      DartType indexType,
      MethodContravarianceCheckKind readCheckKind) {
    Expression read;
    DartType readType = inferrer.getReturnType(readTarget, receiverType);
    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = inferrer.createMissingIndexGet(
            fileOffset, readReceiver, receiverType, readIndex);
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = inferrer.createMissingIndexGet(
            fileOffset, readReceiver, receiverType, readIndex,
            extensionAccessCandidates: readTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        read = new StaticInvocation(
            readTarget.member,
            new Arguments(<Expression>[
              readReceiver,
              readIndex,
            ], types: readTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        if (inferrer.useNewMethodInvocationEncoding) {
          read = new DynamicInvocation(
              DynamicAccessKind.Invalid,
              readReceiver,
              indexGetName,
              new Arguments(<Expression>[
                readIndex,
              ])
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
        }
        break;
      case ObjectAccessTargetKind.never:
        if (inferrer.useNewMethodInvocationEncoding) {
          read = new DynamicInvocation(
              DynamicAccessKind.Never,
              readReceiver,
              indexGetName,
              new Arguments(<Expression>[
                readIndex,
              ])
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
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        if (inferrer.useNewMethodInvocationEncoding) {
          read = new DynamicInvocation(
              DynamicAccessKind.Dynamic,
              readReceiver,
              indexGetName,
              new Arguments(<Expression>[
                readIndex,
              ])
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
        }
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if (inferrer.useNewMethodInvocationEncoding) {
          InstanceAccessKind kind;
          switch (readTarget.kind) {
            case ObjectAccessTargetKind.instanceMember:
              kind = InstanceAccessKind.Instance;
              break;
            case ObjectAccessTargetKind.nullableInstanceMember:
              kind = InstanceAccessKind.Nullable;
              break;
            case ObjectAccessTargetKind.objectMember:
              kind = InstanceAccessKind.Object;
              break;
            default:
              throw new UnsupportedError('Unexpected target kind $readTarget');
          }
          read = new InstanceInvocation(
              kind,
              readReceiver,
              indexGetName,
              new Arguments(<Expression>[
                readIndex,
              ])
                ..fileOffset = fileOffset,
              functionType: new FunctionType(
                  [indexType], readType, inferrer.library.nonNullable),
              interfaceTarget: readTarget.member)
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
        }
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
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = inferrer.isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        break;
    }

    if (!inferrer.isNonNullableByDefault) {
      readType = legacyErasure(readType);
    }

    if (!inferrer.isTopLevel && readTarget.isNullable) {
      return new ExpressionInferenceResult(
          readType,
          inferrer.helper.wrapInProblem(
              read,
              templateNullableOperatorCallError.withArguments(indexGetName.text,
                  receiverType, inferrer.isNonNullableByDefault),
              read.fileOffset,
              noLength));
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
      DartType indexType,
      Expression value,
      DartType valueType) {
    Expression write;
    switch (writeTarget.kind) {
      case ObjectAccessTargetKind.missing:
        write = inferrer.createMissingIndexSet(
            fileOffset, receiver, receiverType, index, value,
            forEffect: true);
        break;
      case ObjectAccessTargetKind.ambiguous:
        write = inferrer.createMissingIndexSet(
            fileOffset, receiver, receiverType, index, value,
            forEffect: true, extensionAccessCandidates: writeTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        assert(writeTarget.extensionMethodKind != ProcedureKind.Setter);
        write = new StaticInvocation(
            writeTarget.member,
            new Arguments(<Expression>[receiver, index, value],
                types: writeTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        if (inferrer.useNewMethodInvocationEncoding) {
          write = new DynamicInvocation(
              DynamicAccessKind.Invalid,
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          write = new MethodInvocation(
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset,
              writeTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.never:
        if (inferrer.useNewMethodInvocationEncoding) {
          write = new DynamicInvocation(
              DynamicAccessKind.Never,
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          write = new MethodInvocation(
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset,
              writeTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        if (inferrer.useNewMethodInvocationEncoding) {
          write = new DynamicInvocation(
              DynamicAccessKind.Dynamic,
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
          break;
        } else {
          write = new MethodInvocation(
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset,
              writeTarget.member)
            ..fileOffset = fileOffset;
          break;
        }
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if (inferrer.useNewMethodInvocationEncoding) {
          InstanceAccessKind kind;
          switch (writeTarget.kind) {
            case ObjectAccessTargetKind.instanceMember:
              kind = InstanceAccessKind.Instance;
              break;
            case ObjectAccessTargetKind.nullableInstanceMember:
              kind = InstanceAccessKind.Nullable;
              break;
            case ObjectAccessTargetKind.objectMember:
              kind = InstanceAccessKind.Object;
              break;
            default:
              throw new UnsupportedError('Unexpected target kind $writeTarget');
          }
          write = new InstanceInvocation(
              kind,
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset,
              functionType: new FunctionType([indexType, valueType],
                  const VoidType(), inferrer.library.nonNullable),
              interfaceTarget: writeTarget.member)
            ..fileOffset = fileOffset;
        } else {
          write = new MethodInvocation(
              receiver,
              indexSetName,
              new Arguments(<Expression>[index, value])
                ..fileOffset = fileOffset,
              writeTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
    }
    if (!inferrer.isTopLevel && writeTarget.isNullable) {
      return inferrer.helper.wrapInProblem(
          write,
          templateNullableOperatorCallError.withArguments(
              indexSetName.text, receiverType, inferrer.isNonNullableByDefault),
          write.fileOffset,
          noLength);
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
    ExpressionInferenceResult readResult;
    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = inferrer.createMissingPropertyGet(
            fileOffset, receiver, receiverType, propertyName);
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = inferrer.createMissingPropertyGet(
            fileOffset, receiver, receiverType, propertyName,
            extensionAccessCandidates: readTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
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
            readResult =
                inferrer.instantiateTearOff(readType, typeContext, read);
            break;
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
          case ProcedureKind.Operator:
            unhandled('$readTarget', "inferPropertyGet", null, null);
            break;
        }
        break;
      case ObjectAccessTargetKind.never:
        if (inferrer.useNewMethodInvocationEncoding) {
          read = new DynamicGet(DynamicAccessKind.Never, receiver, propertyName)
            ..fileOffset = fileOffset;
        } else {
          read = new PropertyGet(receiver, propertyName, readTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.dynamic:
        if (inferrer.useNewMethodInvocationEncoding) {
          read =
              new DynamicGet(DynamicAccessKind.Dynamic, receiver, propertyName)
                ..fileOffset = fileOffset;
        } else {
          read = new PropertyGet(receiver, propertyName, readTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.invalid:
        if (inferrer.useNewMethodInvocationEncoding) {
          read =
              new DynamicGet(DynamicAccessKind.Invalid, receiver, propertyName)
                ..fileOffset = fileOffset;
        } else {
          read = new PropertyGet(receiver, propertyName, readTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        if (inferrer.useNewMethodInvocationEncoding) {
          read = new FunctionTearOff(receiver)..fileOffset = fileOffset;
        } else {
          read = new PropertyGet(receiver, propertyName, readTarget.member)
            ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        Member member = readTarget.member;
        if ((readTarget.isInstanceMember || readTarget.isObjectMember) &&
            inferrer.instrumentation != null &&
            receiverType == const DynamicType()) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              fileOffset,
              'target',
              new InstrumentationValueForMember(readTarget.member));
        }
        if (inferrer.useNewMethodInvocationEncoding) {
          InstanceAccessKind kind;
          switch (readTarget.kind) {
            case ObjectAccessTargetKind.instanceMember:
              kind = InstanceAccessKind.Instance;
              break;
            case ObjectAccessTargetKind.nullableInstanceMember:
              kind = InstanceAccessKind.Nullable;
              break;
            case ObjectAccessTargetKind.objectMember:
              kind = InstanceAccessKind.Object;
              break;
            default:
              throw new UnsupportedError('Unexpected target kind $readTarget');
          }
          if (member is Procedure && member.kind == ProcedureKind.Method) {
            read = new InstanceTearOff(kind, receiver, propertyName,
                interfaceTarget: readTarget.member, resultType: readType)
              ..fileOffset = fileOffset;
          } else {
            read = new InstanceGet(kind, receiver, propertyName,
                interfaceTarget: readTarget.member, resultType: readType)
              ..fileOffset = fileOffset;
          }
        } else {
          read = new PropertyGet(receiver, propertyName, readTarget.member)
            ..fileOffset = fileOffset;
        }
        bool checkReturn = false;
        if ((readTarget.isInstanceMember || readTarget.isObjectMember) &&
            !isThisReceiver) {
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
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = inferrer.isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        if (member is Procedure && member.kind == ProcedureKind.Method) {
          readResult = inferrer.instantiateTearOff(readType, typeContext, read);
        }
        break;
    }

    if (!inferrer.isNonNullableByDefault) {
      readType = legacyErasure(readType);
    }

    readResult ??= new ExpressionInferenceResult(readType, read);
    if (!inferrer.isTopLevel && readTarget.isNullable) {
      readResult = inferrer.wrapExpressionInferenceResultInProblem(
          readResult,
          templateNullablePropertyAccessError.withArguments(
              propertyName.text, receiverType, inferrer.isNonNullableByDefault),
          read.fileOffset,
          propertyName.text.length);
    }
    return readResult;
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
    switch (writeTarget.kind) {
      case ObjectAccessTargetKind.missing:
        write = inferrer.createMissingPropertySet(
            fileOffset, receiver, receiverType, propertyName, value,
            forEffect: forEffect);
        break;
      case ObjectAccessTargetKind.ambiguous:
        write = inferrer.createMissingPropertySet(
            fileOffset, receiver, receiverType, propertyName, value,
            forEffect: forEffect,
            extensionAccessCandidates: writeTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
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
        break;
      case ObjectAccessTargetKind.invalid:
        if (inferrer.useNewMethodInvocationEncoding) {
          write = new DynamicSet(
              DynamicAccessKind.Invalid, receiver, propertyName, value)
            ..fileOffset = fileOffset;
        } else {
          write =
              new PropertySet(receiver, propertyName, value, writeTarget.member)
                ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.never:
        if (inferrer.useNewMethodInvocationEncoding) {
          write = new DynamicSet(
              DynamicAccessKind.Never, receiver, propertyName, value)
            ..fileOffset = fileOffset;
        } else {
          write =
              new PropertySet(receiver, propertyName, value, writeTarget.member)
                ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        if (inferrer.useNewMethodInvocationEncoding) {
          write = new DynamicSet(
              DynamicAccessKind.Dynamic, receiver, propertyName, value)
            ..fileOffset = fileOffset;
        } else {
          write =
              new PropertySet(receiver, propertyName, value, writeTarget.member)
                ..fileOffset = fileOffset;
        }
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if (inferrer.useNewMethodInvocationEncoding) {
          InstanceAccessKind kind;
          switch (writeTarget.kind) {
            case ObjectAccessTargetKind.instanceMember:
              kind = InstanceAccessKind.Instance;
              break;
            case ObjectAccessTargetKind.nullableInstanceMember:
              kind = InstanceAccessKind.Nullable;
              break;
            case ObjectAccessTargetKind.objectMember:
              kind = InstanceAccessKind.Object;
              break;
            default:
              throw new UnsupportedError('Unexpected target kind $writeTarget');
          }
          write = new InstanceSet(kind, receiver, propertyName, value,
              interfaceTarget: writeTarget.member)
            ..fileOffset = fileOffset;
        } else {
          write =
              new PropertySet(receiver, propertyName, value, writeTarget.member)
                ..fileOffset = fileOffset;
        }
        break;
    }
    if (!inferrer.isTopLevel && writeTarget.isNullable) {
      return inferrer.helper.wrapInProblem(
          write,
          templateNullablePropertyAccessError.withArguments(
              propertyName.text, receiverType, inferrer.isNonNullableByDefault),
          write.fileOffset,
          propertyName.text.length);
    }

    return write;
  }

  ExpressionInferenceResult visitCompoundIndexSet(
      CompoundIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (isPureExpression(readReceiver)) {
      writeReceiver = clonePureExpression(readReceiver);
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

    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(
        node.readOffset,
        readReceiver,
        receiverType,
        readTarget,
        readIndex,
        readIndexType,
        readCheckKind);
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

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
        includeExtensionMethods: true);

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, receiverType);

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

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
        writeReceiver,
        receiverType,
        writeTarget,
        writeIndex,
        writeIndexType,
        valueExpression,
        valueType);

    Expression inner;
    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `o[a] += b` as:
      //
      //     let v1 = o in let v2 = a in v1.[]=(v2, v1.[](v2) + b)
      //
      inner = write;
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
      inner = createLet(leftVariable,
          createLet(writeVariable, createVariableGet(leftVariable)));
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
      inner = createLet(valueVariable,
          createLet(writeVariable, createVariableGet(valueVariable)));
    }
    if (indexVariable != null) {
      inner = createLet(indexVariable, inner);
    }

    Expression replacement;
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, inner)
        ..fileOffset = node.fileOffset;
    } else {
      replacement = inner;
    }
    return inferrer.createNullAwareExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType,
        replacement,
        nullAwareGuards);
  }

  ExpressionInferenceResult visitNullAwareCompoundSet(
      NullAwareCompoundSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: true);
    reportNonNullableInNullAwareWarningIfNeeded(
        receiverResult.inferredType, "?.", node.receiver.fileOffset);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);
    NullAwareGuard nullAwareGuard =
        inferrer.createNullAwareGuard(receiverVariable);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);
    DartType nonNullReceiverType = inferrer.computeNonNullable(receiverType);

    ExpressionInferenceResult readResult = _computePropertyGet(
        node.readOffset,
        readReceiver,
        nonNullReceiverType,
        node.propertyName,
        const UnknownType(),
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

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        nonNullReceiverType, node.propertyName, node.writeOffset,
        setter: true, includeExtensionMethods: true);

    DartType valueType =
        inferrer.getSetterType(writeTarget, nonNullReceiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

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
        nonNullReceiverType, node.propertyName, writeTarget, valueExpression,
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

    return inferrer.createNullAwareExpressionInferenceResult(
        resultType, action, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitCompoundSuperIndexSet(
      CompoundSuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget readTarget = node.getter != null
        ? new ObjectAccessTarget.interfaceMember(node.getter,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType readType = inferrer.getReturnType(readTarget, inferrer.thisType);
    DartType readIndexType =
        inferrer.getIndexKeyType(readTarget, inferrer.thisType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    Expression read;
    if (readTarget.isMissing) {
      read = inferrer.createMissingSuperIndexGet(node.readOffset, readIndex);
    } else {
      assert(readTarget.isInstanceMember || readTarget.isObjectMember);
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
    ObjectAccessTarget writeTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, inferrer.thisType);

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);

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
      assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
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
      replacement = write;
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
      replacement = createLet(leftVariable,
          createLet(writeVariable, createVariableGet(leftVariable)));
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
      replacement = createLet(valueVariable,
          createLet(writeVariable, createVariableGet(valueVariable)));
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
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

    DartType receiverType = inferrer.getExtensionReceiverType(
        node.extension, extensionTypeArguments);

    Expression receiver =
        inferrer.ensureAssignableResult(receiverType, receiverResult);

    VariableDeclaration receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    DartType readIndexType = inferrer.getIndexKeyType(readTarget, receiverType);

    ExpressionInferenceResult indexResult = inferrer
        .inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = inferrer.ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex);

    ExpressionInferenceResult readResult = _computeIndexGet(
        node.readOffset,
        readReceiver,
        receiverType,
        readTarget,
        readIndex,
        readIndexType,
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

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ExtensionAccessTarget(
            node.setter, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType =
        inferrer.getIndexKeyType(writeTarget, receiverType);

    DartType valueType =
        inferrer.getIndexSetValueType(writeTarget, inferrer.thisType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs);

    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    writeIndex = inferrer.ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex);
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
        writeReceiver,
        receiverType,
        writeTarget,
        writeIndex,
        writeIndexType,
        valueExpression,
        valueType);

    Expression replacement;
    if (node.forEffect) {
      assert(leftVariable == null);
      assert(valueVariable == null);
      // Encode `Extension(o)[a] += b` as:
      //
      //     let receiverVariable = o in
      //     let indexVariable = a in
      //         receiverVariable.[]=(receiverVariable, o.[](indexVariable) + b)
      //
      replacement = write;
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
      replacement = createLet(leftVariable,
          createLet(writeVariable, createVariableGet(leftVariable)));
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
      replacement = createLet(valueVariable,
          createLet(writeVariable, createVariableGet(valueVariable)));
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
    }
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType, replacement);
  }

  @override
  ExpressionInferenceResult visitNullLiteral(
      NullLiteral node, DartType typeContext) {
    inferrer.flowAnalysis.nullLiteral(node);
    return new ExpressionInferenceResult(const NullType(), node);
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
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    ObjectAccessTarget target = inferrer.findInterfaceMember(
        receiverType, node.name, node.fileOffset,
        setter: true, instrumented: true, includeExtensionMethods: true);
    if (target.isInstanceMember || target.isObjectMember) {
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

    return inferrer.createNullAwareExpressionInferenceResult(
        rhsType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitNullAwareIfNullSet(
      NullAwareIfNullSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferrer
        .inferNullAwareExpression(node.receiver, const UnknownType(), true,
            isVoidAllowed: false);
    reportNonNullableInNullAwareWarningIfNeeded(
        receiverResult.inferredType, "?.", node.receiver.fileOffset);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);
    NullAwareGuard nullAwareGuard =
        inferrer.createNullAwareGuard(receiverVariable);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);
    DartType nonNullReceiverType = inferrer.computeNonNullable(receiverType);

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
        readReceiver, nonNullReceiverType, node.name, typeContext,
        isThisReceiver: node.receiver is ThisExpression);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    inferrer.flowAnalysis.ifNullExpression_rightBegin(read, readType);

    Member readEqualsMember = inferrer
        .findInterfaceMember(readType, equalsName, node.testOffset)
        .member;

    VariableDeclaration readVariable;
    if (!node.forEffect) {
      readVariable = createVariable(read, readType);
      read = createVariableGet(readVariable);
    }

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        nonNullReceiverType, node.name, node.writeOffset,
        setter: true, includeExtensionMethods: true);

    DartType valueType =
        inferrer.getSetterType(writeTarget, nonNullReceiverType);

    ExpressionInferenceResult valueResult = inferrer
        .inferExpression(node.value, valueType, true, isVoidAllowed: true);
    Expression value = inferrer.ensureAssignableResult(valueType, valueResult);

    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        nonNullReceiverType, node.name, writeTarget, value,
        valueType: valueResult.inferredType, forEffect: node.forEffect);

    inferrer.flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = inferrer.computeNonNullable(readType);
    DartType inferredType = inferrer.typeSchemaEnvironment
        .getStandardUpperBound(nonNullableReadType, valueResult.inferredType,
            inferrer.library.library);

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

      Expression readEqualsNull =
          inferrer.createEqualsNull(node.readOffset, read, readEqualsMember);
      replacement = new ConditionalExpression(readEqualsNull, write,
          new NullLiteral()..fileOffset = node.writeOffset, inferredType);
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

      Expression readEqualsNull = inferrer.createEqualsNull(
          receiverVariable.fileOffset, read, readEqualsMember);
      VariableGet variableGet = createVariableGet(readVariable);
      if (inferrer.library.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression condition = new ConditionalExpression(
          readEqualsNull, write, variableGet, inferredType);
      replacement = createLet(readVariable, condition);
    }

    return inferrer.createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards.prepend(nullAwareGuard));
  }

  @override
  ExpressionInferenceResult visitPropertyGet(
      PropertyGet node, DartType typeContext) {
    ExpressionInferenceResult result = inferrer.inferNullAwareExpression(
        node.receiver, const UnknownType(), true);

    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;

    node.receiver = receiver..parent = node;
    ExpressionInferenceResult readResult = _computePropertyGet(
        node.fileOffset, receiver, receiverType, node.name, typeContext,
        isThisReceiver: node.receiver is ThisExpression);
    return inferrer.createNullAwareExpressionInferenceResult(
        readResult.inferredType, readResult.expression, nullAwareGuards);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    inferrer.inferConstructorParameterTypes(node.target);
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    List<DartType> typeArguments =
        new List<DartType>.filled(classTypeParameters.length, null);
    for (int i = 0; i < typeArguments.length; i++) {
      typeArguments[i] = new TypeParameterType.withDefaultNullabilityForLibrary(
          classTypeParameters[i], inferrer.library.library);
    }
    ArgumentsImpl.setNonInferrableArgumentTypes(node.arguments, typeArguments);
    FunctionType functionType = replaceReturnType(
        node.target.function
            .computeThisFunctionType(inferrer.library.nonNullable),
        inferrer.coreTypes.thisInterfaceType(
            node.target.enclosingClass, inferrer.library.nonNullable));
    inferrer.inferInvocation(
        null, node.fileOffset, functionType, node.arguments,
        skipTypeArgumentInference: true, staticTarget: node.target);
    ArgumentsImpl.removeNonInferrableArgumentTypes(node.arguments);
  }

  @override
  ExpressionInferenceResult visitRethrow(Rethrow node, DartType typeContext) {
    inferrer.flowAnalysis.handleExit();
    return new ExpressionInferenceResult(
        inferrer.isNonNullableByDefault
            ? const NeverType(Nullability.nonNullable)
            : const BottomType(),
        node);
  }

  @override
  StatementInferenceResult visitReturnStatement(
      covariant ReturnStatementImpl node) {
    ClosureContext closureContext = inferrer.closureContext;
    DartType typeContext = closureContext.returnContext;
    DartType inferredType;
    if (node.expression != null) {
      ExpressionInferenceResult expressionResult = inferrer.inferExpression(
          node.expression, typeContext, true,
          isVoidAllowed: true);
      node.expression = expressionResult.expression..parent = node;
      inferredType = expressionResult.inferredType;
    } else {
      inferredType = const NullType();
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
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          setType,
          setClass.typeParameters,
          null,
          null,
          typeContext,
          inferredTypes,
          inferrer.library.library,
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
          inferredTypes,
          inferrer.library.library);
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
        setClass, inferrer.library.nonNullable, [inferredTypeArgument]);
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

    if (!inferrer.isNonNullableByDefault) {
      type = legacyErasure(type);
    }

    if (target is Procedure && target.kind == ProcedureKind.Method) {
      Expression tearOff = node;
      if (inferrer.useNewMethodInvocationEncoding) {
        tearOff = new StaticTearOff(node.target)..fileOffset = node.fileOffset;
      }
      return inferrer.instantiateTearOff(type, typeContext, tearOff);
    } else {
      return new ExpressionInferenceResult(type, node);
    }
  }

  @override
  ExpressionInferenceResult visitStaticInvocation(
      StaticInvocation node, DartType typeContext) {
    FunctionType calleeType = node.target != null
        ? node.target.function.computeFunctionType(inferrer.library.nonNullable)
        : new FunctionType(
            [], const DynamicType(), inferrer.library.nonNullable);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    InvocationInferenceResult result = inferrer.inferInvocation(
        typeContext, node.fileOffset, calleeType, node.arguments,
        staticTarget: node.target);
    if (!inferrer.isTopLevel && node.target != null) {
      inferrer.library.checkBoundsInStaticInvocation(
          node,
          inferrer.typeSchemaEnvironment,
          inferrer.helper.uri,
          typeArgumentsInfo);
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(node));
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
    inferrer.inferConstructorParameterTypes(node.target);
    Substitution substitution = Substitution.fromSupertype(
        inferrer.classHierarchy.getClassAsInstanceOf(
            inferrer.thisType.classNode, node.target.enclosingClass));
    FunctionType functionType = replaceReturnType(
        substitution.substituteType(node.target.function
            .computeThisFunctionType(inferrer.library.nonNullable)
            .withoutTypeParameters),
        inferrer.thisType);
    inferrer.inferInvocation(
        null, node.fileOffset, functionType, node.arguments,
        skipTypeArgumentInference: true, staticTarget: node.target);
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
    assert(node.interfaceTarget == null || node.interfaceTarget is Procedure);
    return inferrer.inferSuperMethodInvocation(
        node,
        typeContext,
        node.interfaceTarget != null
            ? new ObjectAccessTarget.interfaceMember(node.interfaceTarget,
                isPotentiallyNullable: false)
            : const ObjectAccessTarget.missing());
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
            ? new ObjectAccessTarget.interfaceMember(node.interfaceTarget,
                isPotentiallyNullable: false)
            : const ObjectAccessTarget.missing());
  }

  @override
  ExpressionInferenceResult visitSuperPropertySet(
      SuperPropertySet node, DartType typeContext) {
    DartType receiverType = inferrer.classHierarchy.getTypeAsInstanceOf(
        inferrer.thisType,
        inferrer.thisType.classNode.supertype.classNode,
        inferrer.library.library);

    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, node.name, node.fileOffset,
        setter: true, instrumented: true);
    if (writeTarget.isInstanceMember || writeTarget.isObjectMember) {
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

    Set<Field> enumFields;
    if (expressionType is InterfaceType && expressionType.classNode.isEnum) {
      enumFields = expressionType.classNode.fields
          .where((Field field) => field.isConst && field.type == expressionType)
          .toSet();
      if (expressionType.isPotentiallyNullable) {
        enumFields.add(null);
      }
    }

    inferrer.flowAnalysis.switchStatement_expressionEnd(node);

    bool hasDefault = false;
    bool lastCaseTerminates = true;
    for (int caseIndex = 0; caseIndex < node.cases.length; ++caseIndex) {
      SwitchCaseImpl switchCase = node.cases[caseIndex];
      hasDefault = hasDefault || switchCase.isDefault;
      inferrer.flowAnalysis
          .switchStatement_beginCase(switchCase.hasLabel, node);
      for (int index = 0; index < switchCase.expressions.length; index++) {
        ExpressionInferenceResult caseExpressionResult =
            inferrer.inferExpression(
                switchCase.expressions[index], expressionType, true,
                isVoidAllowed: false);
        Expression caseExpression = caseExpressionResult.expression;
        switchCase.expressions[index] = caseExpression..parent = switchCase;
        DartType caseExpressionType = caseExpressionResult.inferredType;
        if (enumFields != null) {
          if (caseExpression is StaticGet) {
            enumFields.remove(caseExpression.target);
          } else if (caseExpression is NullLiteral) {
            enumFields.remove(null);
          }
        }

        if (!inferrer.isTopLevel) {
          if (inferrer.library.isNonNullableByDefault) {
            if (!inferrer.typeSchemaEnvironment.isSubtypeOf(caseExpressionType,
                expressionType, SubtypeCheckMode.withNullabilities)) {
              inferrer.helper.addProblem(
                  templateSwitchExpressionNotSubtype.withArguments(
                      caseExpressionType,
                      expressionType,
                      inferrer.isNonNullableByDefault),
                  caseExpression.fileOffset,
                  noLength,
                  context: [
                    messageSwitchExpressionNotAssignableCause.withLocation(
                        inferrer.uriForInstrumentation,
                        node.expression.fileOffset,
                        noLength)
                  ]);
            }
          } else {
            // Check whether the expression type is assignable to the case
            // expression type.
            if (!inferrer.isAssignable(expressionType, caseExpressionType)) {
              inferrer.helper.addProblem(
                  templateSwitchExpressionNotAssignable.withArguments(
                      expressionType,
                      caseExpressionType,
                      inferrer.isNonNullableByDefault),
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
        }
      }
      StatementInferenceResult bodyResult =
          inferrer.inferStatement(switchCase.body);
      if (bodyResult.hasChanged) {
        switchCase.body = bodyResult.statement..parent = switchCase;
      }

      if (inferrer.isNonNullableByDefault) {
        lastCaseTerminates = !inferrer.flowAnalysis.isReachable;
        if (!inferrer.isTopLevel) {
          // The last case block is allowed to complete normally.
          if (caseIndex < node.cases.length - 1 &&
              inferrer.flowAnalysis.isReachable) {
            inferrer.library.addProblem(messageSwitchCaseFallThrough,
                switchCase.fileOffset, noLength, inferrer.helper.uri);
          }
        }
      }
    }
    bool isExhaustive =
        hasDefault || (enumFields != null && enumFields.isEmpty);
    inferrer.flowAnalysis.switchStatement_end(isExhaustive);
    Statement replacement;
    if (isExhaustive &&
        !hasDefault &&
        inferrer.shouldThrowUnsoundnessException) {
      if (!lastCaseTerminates) {
        LabeledStatement breakTarget;
        if (node.parent is LabeledStatement) {
          breakTarget = node.parent;
        } else {
          replacement = breakTarget = new LabeledStatement(node);
        }

        SwitchCase lastCase = node.cases.last;
        Statement body = lastCase.body;
        if (body is Block) {
          body.statements.add(new BreakStatementImpl(isContinue: false)
            ..target = breakTarget
            ..targetStatement = node
            ..fileOffset = node.fileOffset);
        }
      }
      node.cases.add(new SwitchCase(
          [],
          [],
          _createExpressionStatement(inferrer.createReachabilityError(
              node.fileOffset,
              messageNeverReachableSwitchDefaultError,
              messageNeverReachableSwitchDefaultWarning)),
          isDefault: true)
        ..fileOffset = node.fileOffset
        ..parent = node);
    }
    return replacement != null
        ? new StatementInferenceResult.single(replacement)
        : const StatementInferenceResult();
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
    if (!inferrer.isTopLevel && inferrer.isNonNullableByDefault) {
      if (!inferrer.isAssignable(
          inferrer.typeSchemaEnvironment.objectNonNullableRawType,
          expressionResult.inferredType)) {
        return new ExpressionInferenceResult(
            const DynamicType(),
            inferrer.helper.buildProblem(
                templateThrowingNotAssignableToObjectError.withArguments(
                    expressionResult.inferredType, true),
                node.expression.fileOffset,
                noLength));
      }
    }
    // Return BottomType in legacy mode for compatibility.
    return new ExpressionInferenceResult(
        inferrer.isNonNullableByDefault
            ? const NeverType(Nullability.nonNullable)
            : const BottomType(),
        node);
  }

  void visitCatch(Catch node) {
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
  }

  StatementInferenceResult visitTryStatement(TryStatement node) {
    if (node.finallyBlock != null) {
      inferrer.flowAnalysis.tryFinallyStatement_bodyBegin();
    }
    Statement tryBodyWithAssignedInfo = node.tryBlock;
    if (node.catchBlocks.isNotEmpty) {
      inferrer.flowAnalysis.tryCatchStatement_bodyBegin();
    }

    StatementInferenceResult tryBlockResult =
        inferrer.inferStatement(node.tryBlock);

    if (node.catchBlocks.isNotEmpty) {
      inferrer.flowAnalysis.tryCatchStatement_bodyEnd(tryBodyWithAssignedInfo);
      for (Catch catchBlock in node.catchBlocks) {
        inferrer.flowAnalysis.tryCatchStatement_catchBegin(
            catchBlock.exception, catchBlock.stackTrace);
        visitCatch(catchBlock);
        inferrer.flowAnalysis.tryCatchStatement_catchEnd();
      }
      inferrer.flowAnalysis.tryCatchStatement_end();
    }

    StatementInferenceResult finalizerResult;
    if (node.finallyBlock != null) {
      // If a try statement has no catch blocks, the finally block uses the
      // assigned variables from the try block in [tryBodyWithAssignedInfo],
      // otherwise it uses the assigned variables for the
      inferrer.flowAnalysis.tryFinallyStatement_finallyBegin(
          node.catchBlocks.isNotEmpty ? node : tryBodyWithAssignedInfo);
      finalizerResult = inferrer.inferStatement(node.finallyBlock);
      inferrer.flowAnalysis.tryFinallyStatement_end(node.finallyBlock);
    }
    Statement result =
        tryBlockResult.hasChanged ? tryBlockResult.statement : node.tryBlock;
    if (node.catchBlocks.isNotEmpty) {
      result = new TryCatch(result, node.catchBlocks)
        ..fileOffset = node.fileOffset;
    }
    if (node.finallyBlock != null) {
      result = new TryFinally(
          result,
          finalizerResult.hasChanged
              ? finalizerResult.statement
              : node.finallyBlock)
        ..fileOffset = node.fileOffset;
    }
    inferrer.library.loader.dataForTesting?.registerAlias(node, result);
    return new StatementInferenceResult.single(result);
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
    VariableDeclarationImpl variable = node.variable;
    bool isDefinitelyAssigned = false;
    bool isDefinitelyUnassigned = false;
    if (inferrer.isNonNullableByDefault) {
      isDefinitelyAssigned = inferrer.flowAnalysis.isAssigned(variable);
      isDefinitelyUnassigned = inferrer.flowAnalysis.isUnassigned(variable);
    }
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    DartType promotedType;
    if (inferrer.isNonNullableByDefault) {
      promotedType = inferrer.flowAnalysis.promotedType(variable);
    }
    ExpressionInferenceResult rhsResult = inferrer.inferExpression(node.value,
        promotedType ?? declaredOrInferredType ?? const UnknownType(), true,
        isVoidAllowed: true);
    Expression rhs = inferrer.ensureAssignableResult(
        declaredOrInferredType, rhsResult,
        fileOffset: node.fileOffset,
        isVoidAllowed: declaredOrInferredType is VoidType);
    inferrer.flowAnalysis
        .write(variable, rhsResult.inferredType, rhsResult.expression);
    DartType resultType = rhsResult.inferredType;
    Expression resultExpression;
    if (variable.lateSetter != null) {
      if (inferrer.useNewMethodInvocationEncoding) {
        resultExpression = new LocalFunctionInvocation(variable.lateSetter,
            new Arguments(<Expression>[rhs])..fileOffset = node.fileOffset,
            functionType: variable.lateSetter.type)
          ..fileOffset = node.fileOffset;
      } else {
        resultExpression = new MethodInvocation(
            new VariableGet(variable.lateSetter)..fileOffset = node.fileOffset,
            callName,
            new Arguments(<Expression>[rhs])..fileOffset = node.fileOffset)
          ..fileOffset = node.fileOffset;
      }
      // Future calls to flow analysis will be using `resultExpression` to refer
      // to the variable set, so instruct flow analysis to forward the
      // expression information.
      inferrer.flowAnalysis.forwardExpression(resultExpression, node);
    } else {
      node.value = rhs..parent = node;
      resultExpression = node;
    }
    if (!inferrer.isTopLevel && inferrer.isNonNullableByDefault) {
      // Synthetic variables, local functions, and variables with
      // invalid types aren't checked.
      if (variable.name != null &&
          !variable.isLocalFunction &&
          declaredOrInferredType is! InvalidType) {
        if ((variable.isLate && variable.isFinal) ||
            variable.isLateFinalWithoutInitializer) {
          if (isDefinitelyAssigned) {
            return new ExpressionInferenceResult(
                resultType,
                inferrer.helper.wrapInProblem(
                    resultExpression,
                    templateLateDefinitelyAssignedError
                        .withArguments(node.variable.name),
                    node.fileOffset,
                    node.variable.name.length));
          }
        } else if (variable.isStaticLate) {
          if (!isDefinitelyUnassigned) {
            return new ExpressionInferenceResult(
                resultType,
                inferrer.helper.wrapInProblem(
                    resultExpression,
                    templateFinalPossiblyAssignedError
                        .withArguments(node.variable.name),
                    node.fileOffset,
                    node.variable.name.length));
          }
        }
      }
    }
    return new ExpressionInferenceResult(resultType, resultExpression);
  }

  @override
  StatementInferenceResult visitVariableDeclaration(
      covariant VariableDeclarationImpl node) {
    DartType declaredType =
        node.isImplicitlyTyped ? const UnknownType() : node.type;
    DartType inferredType;
    ExpressionInferenceResult initializerResult;
    inferrer.flowAnalysis.declare(node, node.hasDeclaredInitializer);
    if (node.initializer != null) {
      if (node.isLate && node.hasDeclaredInitializer) {
        inferrer.flowAnalysis.lateInitializer_begin(node);
      }
      initializerResult = inferrer.inferExpression(node.initializer,
          declaredType, !inferrer.isTopLevel || node.isImplicitlyTyped,
          isVoidAllowed: true);
      if (node.isLate && node.hasDeclaredInitializer) {
        inferrer.flowAnalysis.lateInitializer_end();
      }
      inferredType = inferrer.inferDeclarationType(
          initializerResult.inferredType,
          forSyntheticVariable: node.name == null);
    } else {
      inferredType = const DynamicType();
    }
    if (node.isImplicitlyTyped) {
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'type',
          new InstrumentationValueForType(inferredType));
      node.type = inferredType;
    }
    if (initializerResult != null) {
      DartType initializerType = initializerResult.inferredType;
      if (node.isImplicitlyTyped) {
        if (initializerType is TypeParameterType) {
          inferrer.flowAnalysis.promote(node, initializerType);
        }
      } else {
        // TODO(paulberry): `initializerType` is sometimes `null` during top
        // level inference.  Figure out how to prevent this.
        if (initializerType != null) {
          inferrer.flowAnalysis.initialize(
              node, initializerType, initializerResult.expression,
              isFinal: node.isFinal, isLate: node.isLate);
        }
      }
      Expression initializer = inferrer.ensureAssignableResult(
          node.type, initializerResult,
          fileOffset: node.fileOffset, isVoidAllowed: node.type is VoidType);
      node.initializer = initializer..parent = node;
    }
    if (!inferrer.isTopLevel) {
      SourceLibraryBuilder library = inferrer.library;
      if (node.isImplicitlyTyped) {
        library.checkBoundsInVariableDeclaration(
            node, inferrer.typeSchemaEnvironment, inferrer.helper.uri,
            inferred: true);
      }
    }
    if (node.isLate &&
        inferrer.library.loader.target.backendTarget.isLateLocalLoweringEnabled(
            hasInitializer: node.hasDeclaredInitializer,
            isFinal: node.isFinal,
            isPotentiallyNullable: node.type.isPotentiallyNullable)) {
      int fileOffset = node.fileOffset;

      List<Statement> result = <Statement>[];
      result.add(node);

      late_lowering.IsSetEncoding isSetEncoding =
          late_lowering.computeIsSetEncoding(
              node.type, late_lowering.computeIsSetStrategy(inferrer.library));
      VariableDeclaration isSetVariable;
      if (isSetEncoding == late_lowering.IsSetEncoding.useIsSetField) {
        isSetVariable = new VariableDeclaration(
            late_lowering.computeLateLocalIsSetName(node.name),
            initializer: new BoolLiteral(false)..fileOffset = fileOffset,
            type: inferrer.coreTypes.boolRawType(inferrer.library.nonNullable),
            isLowered: true)
          ..fileOffset = fileOffset;
        result.add(isSetVariable);
      }

      Expression createVariableRead({bool needsPromotion: false}) {
        if (needsPromotion) {
          return new VariableGet(node, node.type)..fileOffset = fileOffset;
        } else {
          return new VariableGet(node)..fileOffset = fileOffset;
        }
      }

      Expression createIsSetRead() =>
          new VariableGet(isSetVariable)..fileOffset = fileOffset;
      Expression createVariableWrite(Expression value) =>
          new VariableSet(node, value);
      Expression createIsSetWrite(Expression value) =>
          new VariableSet(isSetVariable, value);

      VariableDeclaration getVariable = new VariableDeclaration(
          late_lowering.computeLateLocalGetterName(node.name),
          isLowered: true)
        ..fileOffset = fileOffset;
      FunctionDeclaration getter = new FunctionDeclaration(
          getVariable,
          new FunctionNode(
              node.initializer == null
                  ? late_lowering.createGetterBodyWithoutInitializer(
                      inferrer.coreTypes,
                      fileOffset,
                      node.name,
                      node.type,
                      inferrer.useNewMethodInvocationEncoding,
                      createVariableRead: createVariableRead,
                      createIsSetRead: createIsSetRead,
                      isSetEncoding: isSetEncoding,
                      forField: false)
                  : (node.isFinal
                      ? late_lowering.createGetterWithInitializerWithRecheck(
                          inferrer.coreTypes,
                          fileOffset,
                          node.name,
                          node.type,
                          node.initializer,
                          inferrer.useNewMethodInvocationEncoding,
                          createVariableRead: createVariableRead,
                          createVariableWrite: createVariableWrite,
                          createIsSetRead: createIsSetRead,
                          createIsSetWrite: createIsSetWrite,
                          isSetEncoding: isSetEncoding,
                          forField: false)
                      : late_lowering.createGetterWithInitializer(
                          inferrer.coreTypes,
                          fileOffset,
                          node.name,
                          node.type,
                          node.initializer,
                          inferrer.useNewMethodInvocationEncoding,
                          createVariableRead: createVariableRead,
                          createVariableWrite: createVariableWrite,
                          createIsSetRead: createIsSetRead,
                          createIsSetWrite: createIsSetWrite,
                          isSetEncoding: isSetEncoding)),
              returnType: node.type))
        ..fileOffset = fileOffset;
      getVariable.type =
          getter.function.computeFunctionType(inferrer.library.nonNullable);
      node.lateGetter = getVariable;
      result.add(getter);

      if (!node.isFinal || node.initializer == null) {
        node.isLateFinalWithoutInitializer =
            node.isFinal && node.initializer == null;
        VariableDeclaration setVariable = new VariableDeclaration(
            late_lowering.computeLateLocalSetterName(node.name),
            isLowered: true)
          ..fileOffset = fileOffset;
        VariableDeclaration setterParameter =
            new VariableDeclaration(null, type: node.type)
              ..fileOffset = fileOffset;
        FunctionDeclaration setter = new FunctionDeclaration(
                setVariable,
                new FunctionNode(
                    node.isFinal
                        ? late_lowering.createSetterBodyFinal(
                            inferrer.coreTypes,
                            fileOffset,
                            node.name,
                            setterParameter,
                            node.type,
                            inferrer.useNewMethodInvocationEncoding,
                            shouldReturnValue: true,
                            createVariableRead: createVariableRead,
                            createVariableWrite: createVariableWrite,
                            createIsSetRead: createIsSetRead,
                            createIsSetWrite: createIsSetWrite,
                            isSetEncoding: isSetEncoding,
                            forField: false)
                        : late_lowering.createSetterBody(inferrer.coreTypes,
                            fileOffset, node.name, setterParameter, node.type,
                            shouldReturnValue: true,
                            createVariableWrite: createVariableWrite,
                            createIsSetWrite: createIsSetWrite,
                            isSetEncoding: isSetEncoding)
                      ..fileOffset = fileOffset,
                    positionalParameters: <VariableDeclaration>[
                      setterParameter
                    ]))
            // TODO(johnniwinther): Reinsert the file offset when the vm doesn't
            //  use it for function declaration identity.
            /*..fileOffset = fileOffset*/;
        setVariable.type =
            setter.function.computeFunctionType(inferrer.library.nonNullable);
        node.lateSetter = setVariable;
        result.add(setter);
      }
      node.isLate = false;
      node.lateType = node.type;
      if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
        node.initializer = new StaticInvocation(
            inferrer.coreTypes.createSentinelMethod,
            new Arguments([], types: [node.type])..fileOffset = fileOffset)
          ..parent = node;
      } else {
        node.initializer = null;
      }
      node.type = inferrer.computeNullable(node.type);
      node.lateName = node.name;
      node.isLowered = true;
      node.name = late_lowering.computeLateLocalName(node.name);

      return new StatementInferenceResult.multiple(node.fileOffset, result);
    }
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitVariableGet(
      covariant VariableGetImpl node, DartType typeContext) {
    VariableDeclarationImpl variable = node.variable;
    DartType promotedType;
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    if (inferrer.isNonNullableByDefault) {
      if (node.forNullGuardedAccess) {
        DartType nonNullableType = inferrer.computeNonNullable(variable.type);
        if (nonNullableType != variable.type) {
          promotedType = nonNullableType;
        }
      } else if (!variable.isLocalFunction) {
        // Don't promote local functions.
        promotedType = inferrer.flowAnalysis.variableRead(node, variable);
      }
    } else {
      bool mutatedInClosure = variable.mutatedInClosure;
      promotedType = inferrer.typePromoter
          .computePromotedType(node.fact, node.scope, mutatedInClosure);
    }
    if (promotedType != null) {
      inferrer.instrumentation?.record(
          inferrer.uriForInstrumentation,
          node.fileOffset,
          'promotedType',
          new InstrumentationValueForType(promotedType));
    }
    node.promotedType = promotedType;
    DartType resultType = promotedType ?? declaredOrInferredType;
    Expression resultExpression;
    if (variable.isLocalFunction) {
      return inferrer.instantiateTearOff(resultType, typeContext, node);
    } else if (variable.lateGetter != null) {
      if (inferrer.useNewMethodInvocationEncoding) {
        resultExpression = new LocalFunctionInvocation(variable.lateGetter,
            new Arguments(<Expression>[])..fileOffset = node.fileOffset,
            functionType: variable.lateGetter.type)
          ..fileOffset = node.fileOffset;
      } else {
        resultExpression = new MethodInvocation(
            new VariableGet(variable.lateGetter)..fileOffset = node.fileOffset,
            callName,
            new Arguments(<Expression>[])..fileOffset = node.fileOffset)
          ..fileOffset = node.fileOffset;
      }
      // Future calls to flow analysis will be using `resultExpression` to refer
      // to the variable get, so instruct flow analysis to forward the
      // expression information.
      inferrer.flowAnalysis.forwardExpression(resultExpression, node);
    } else {
      resultExpression = node;
    }
    if (!inferrer.isTopLevel) {
      bool isUnassigned = !inferrer.flowAnalysis.isAssigned(variable);
      if (isUnassigned) {
        inferrer.dataForTesting?.flowAnalysisResult?.potentiallyUnassignedNodes
            ?.add(node);
      }
      bool isDefinitelyUnassigned =
          inferrer.flowAnalysis.isUnassigned(variable);
      if (isDefinitelyUnassigned) {
        inferrer.dataForTesting?.flowAnalysisResult?.definitelyUnassignedNodes
            ?.add(node);
      }
      if (inferrer.isNonNullableByDefault) {
        // Synthetic variables, local functions, and variables with
        // invalid types aren't checked.
        if (variable.name != null &&
            !variable.isLocalFunction &&
            declaredOrInferredType is! InvalidType) {
          if (variable.isLate || variable.lateGetter != null) {
            if (isDefinitelyUnassigned) {
              String name = variable.lateName ?? variable.name;
              return new ExpressionInferenceResult(
                  resultType,
                  inferrer.helper.wrapInProblem(
                      resultExpression,
                      templateLateDefinitelyUnassignedError.withArguments(name),
                      node.fileOffset,
                      name.length));
            }
          } else {
            if (isUnassigned) {
              if (variable.isFinal) {
                return new ExpressionInferenceResult(
                    resultType,
                    inferrer.helper.wrapInProblem(
                        resultExpression,
                        templateFinalNotAssignedError
                            .withArguments(node.variable.name),
                        node.fileOffset,
                        node.variable.name.length));
              } else if (declaredOrInferredType.isPotentiallyNonNullable) {
                return new ExpressionInferenceResult(
                    resultType,
                    inferrer.helper.wrapInProblem(
                        resultExpression,
                        templateNonNullableNotAssignedError
                            .withArguments(node.variable.name),
                        node.fileOffset,
                        node.variable.name.length));
              }
            }
          }
        }
      }
    }
    return new ExpressionInferenceResult(resultType, resultExpression);
  }

  @override
  StatementInferenceResult visitWhileStatement(WhileStatement node) {
    inferrer.flowAnalysis.whileStatement_conditionBegin(node);
    InterfaceType expectedType =
        inferrer.coreTypes.boolRawType(inferrer.library.nonNullable);
    ExpressionInferenceResult conditionResult = inferrer.inferExpression(
        node.condition, expectedType, !inferrer.isTopLevel,
        isVoidAllowed: false);
    Expression condition =
        inferrer.ensureAssignableResult(expectedType, conditionResult);
    node.condition = condition..parent = node;
    inferrer.flowAnalysis.whileStatement_bodyBegin(node, node.condition);
    StatementInferenceResult bodyResult = inferrer.inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    inferrer.flowAnalysis.whileStatement_end();
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitYieldStatement(YieldStatement node) {
    ClosureContext closureContext = inferrer.closureContext;
    ExpressionInferenceResult expressionResult;
    DartType typeContext = closureContext.yieldContext;
    if (node.isYieldStar && typeContext is! UnknownType) {
      typeContext = inferrer.wrapType(
          typeContext,
          closureContext.isAsync
              ? inferrer.coreTypes.streamClass
              : inferrer.coreTypes.iterableClass,
          inferrer.library.nonNullable);
    }
    expressionResult = inferrer.inferExpression(
        node.expression, typeContext, true,
        isVoidAllowed: true);
    closureContext.handleYield(inferrer, node, expressionResult);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitLoadLibrary(
      covariant LoadLibraryImpl node, DartType typeContext) {
    DartType inferredType = inferrer.typeSchemaEnvironment
        .futureType(const DynamicType(), inferrer.library.nonNullable);
    if (node.arguments != null) {
      FunctionType calleeType =
          new FunctionType([], inferredType, inferrer.library.nonNullable);
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
            .futureType(const DynamicType(), inferrer.library.nonNullable),
        inferrer.library.nonNullable);
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
    return _computeBinaryExpression(
        node.fileOffset,
        typeContext,
        leftResult.expression,
        leftResult.inferredType,
        node.binaryName,
        node.right);
  }

  ExpressionInferenceResult visitUnary(
      UnaryExpression node, DartType typeContext) {
    ExpressionInferenceResult expressionResult;
    if (node.unaryName == unaryMinusName) {
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

  void reportNonNullableInNullAwareWarningIfNeeded(
      DartType operandType, String operationName, int offset) {
    if (!inferrer.isTopLevel && inferrer.isNonNullableByDefault) {
      if (operandType is! InvalidType &&
          operandType.nullability == Nullability.nonNullable) {
        inferrer.library.addProblem(
            templateNonNullableInNullAware.withArguments(
                operationName, operandType, inferrer.isNonNullableByDefault),
            offset,
            noLength,
            inferrer.helper.uri);
      }
    }
  }

  @override
  ExpressionInferenceResult visitDynamicGet(
      DynamicGet node, DartType typeContext) {
    // TODO: implement visitDynamicGet
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitInstanceGet(
      InstanceGet node, DartType typeContext) {
    // TODO: implement visitInstanceGet
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitInstanceTearOff(
      InstanceTearOff node, DartType typeContext) {
    // TODO: implement visitInstanceTearOff
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitDynamicInvocation(
      DynamicInvocation node, DartType typeContext) {
    // TODO: implement visitDynamicInvocation
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitDynamicSet(
      DynamicSet node, DartType typeContext) {
    // TODO: implement visitDynamicSet
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitEqualsCall(
      EqualsCall node, DartType typeContext) {
    // TODO: implement visitEqualsCall
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitEqualsNull(
      EqualsNull node, DartType typeContext) {
    // TODO: implement visitEqualsNull
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitFunctionInvocation(
      FunctionInvocation node, DartType typeContext) {
    // TODO: implement visitFunctionInvocation
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitInstanceInvocation(
      InstanceInvocation node, DartType typeContext) {
    // TODO: implement visitInstanceInvocation
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitInstanceSet(
      InstanceSet node, DartType typeContext) {
    // TODO: implement visitInstanceSet
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitLocalFunctionInvocation(
      LocalFunctionInvocation node, DartType typeContext) {
    // TODO: implement visitLocalFunctionInvocation
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitStaticTearOff(
      StaticTearOff node, DartType typeContext) {
    // TODO: implement visitStaticTearOff
    throw new UnimplementedError();
  }

  @override
  ExpressionInferenceResult visitFunctionTearOff(
      FunctionTearOff node, DartType arg) {
    // TODO: implement visitFunctionTearOff
    throw new UnimplementedError();
  }
}

class ForInResult {
  final VariableDeclaration variable;
  final Expression iterable;
  final Expression syntheticAssignment;
  final Statement expressionSideEffects;

  ForInResult(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionSideEffects);

  String toString() => 'ForInResult($variable,$iterable,'
      '$syntheticAssignment,$expressionSideEffects)';
}

abstract class ForInVariable {
  /// Computes the type of the elements expected for this for-in variable.
  DartType computeElementType(TypeInferrerImpl inferrer);

  /// Infers the assignment to this for-in variable with a value of type
  /// [rhsType]. The resulting expression is returned.
  Expression inferAssignment(TypeInferrerImpl inferrer, DartType rhsType);
}

class LocalForInVariable implements ForInVariable {
  VariableSet variableSet;

  LocalForInVariable(this.variableSet);

  DartType computeElementType(TypeInferrerImpl inferrer) {
    VariableDeclaration variable = variableSet.variable;
    DartType promotedType;
    if (inferrer.isNonNullableByDefault) {
      promotedType = inferrer.flowAnalysis.promotedType(variable);
    }
    return promotedType ?? variable.type;
  }

  Expression inferAssignment(TypeInferrerImpl inferrer, DartType rhsType) {
    DartType variableType =
        inferrer.computeGreatestClosure(variableSet.variable.type);
    Expression rhs = inferrer.ensureAssignable(
        variableType, rhsType, variableSet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    variableSet.value = rhs..parent = variableSet;
    inferrer.flowAnalysis.write(variableSet.variable, rhsType, null);
    return variableSet;
  }
}

class PropertyForInVariable implements ForInVariable {
  final PropertySet propertySet;

  DartType _writeType;

  Expression _rhs;

  PropertyForInVariable(this.propertySet);

  @override
  DartType computeElementType(TypeInferrerImpl inferrer) {
    ExpressionInferenceResult receiverResult = inferrer.inferExpression(
        propertySet.receiver, const UnknownType(), true);
    propertySet.receiver = receiverResult.expression..parent = propertySet;
    DartType receiverType = receiverResult.inferredType;
    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, propertySet.name, propertySet.fileOffset,
        setter: true, instrumented: true, includeExtensionMethods: true);
    DartType elementType =
        _writeType = inferrer.getSetterType(writeTarget, receiverType);
    Expression error = inferrer.reportMissingInterfaceMember(
        writeTarget,
        receiverType,
        propertySet.name,
        propertySet.fileOffset,
        templateUndefinedSetter);
    if (error != null) {
      _rhs = error;
    } else {
      if (writeTarget.isInstanceMember || writeTarget.isObjectMember) {
        if (inferrer.instrumentation != null &&
            receiverType == const DynamicType()) {
          inferrer.instrumentation.record(
              inferrer.uriForInstrumentation,
              propertySet.fileOffset,
              'target',
              new InstrumentationValueForMember(writeTarget.member));
        }
        propertySet.interfaceTarget = writeTarget.member;
      }
      _rhs = propertySet.value;
    }
    return elementType;
  }

  @override
  Expression inferAssignment(TypeInferrerImpl inferrer, DartType rhsType) {
    Expression rhs = inferrer.ensureAssignable(
        inferrer.computeGreatestClosure(_writeType), rhsType, _rhs,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    propertySet.value = rhs..parent = propertySet;
    ExpressionInferenceResult result = inferrer.inferExpression(
        propertySet, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class SuperPropertyForInVariable implements ForInVariable {
  final SuperPropertySet superPropertySet;

  DartType _writeType;

  SuperPropertyForInVariable(this.superPropertySet);

  @override
  DartType computeElementType(TypeInferrerImpl inferrer) {
    DartType receiverType = inferrer.thisType;
    ObjectAccessTarget writeTarget = inferrer.findInterfaceMember(
        receiverType, superPropertySet.name, superPropertySet.fileOffset,
        setter: true, instrumented: true);
    if (writeTarget.isInstanceMember || writeTarget.isObjectMember) {
      superPropertySet.interfaceTarget = writeTarget.member;
    }
    return _writeType = inferrer.getSetterType(writeTarget, receiverType);
  }

  @override
  Expression inferAssignment(TypeInferrerImpl inferrer, DartType rhsType) {
    Expression rhs = inferrer.ensureAssignable(
        inferrer.computeGreatestClosure(_writeType),
        rhsType,
        superPropertySet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);
    superPropertySet.value = rhs..parent = superPropertySet;
    ExpressionInferenceResult result = inferrer.inferExpression(
        superPropertySet, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class StaticForInVariable implements ForInVariable {
  final StaticSet staticSet;

  StaticForInVariable(this.staticSet);

  @override
  DartType computeElementType(TypeInferrerImpl inferrer) =>
      staticSet.target.setterType;

  @override
  Expression inferAssignment(TypeInferrerImpl inferrer, DartType rhsType) {
    DartType setterType =
        inferrer.computeGreatestClosure(staticSet.target.setterType);
    Expression rhs = inferrer.ensureAssignable(
        setterType, rhsType, staticSet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    staticSet.value = rhs..parent = staticSet;
    ExpressionInferenceResult result = inferrer.inferExpression(
        staticSet, const UnknownType(), !inferrer.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class InvalidForInVariable implements ForInVariable {
  final Expression expression;

  InvalidForInVariable(this.expression);

  @override
  DartType computeElementType(TypeInferrerImpl inferrer) => const UnknownType();

  @override
  Expression inferAssignment(TypeInferrerImpl inferrer, DartType rhsType) =>
      expression;
}
