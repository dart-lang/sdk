// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../base/instrumentation.dart'
    show
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;
import '../fasta_codes.dart';
import '../kernel/body_builder.dart' show combineStatements;
import '../kernel/collections.dart'
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
import '../kernel/implicit_type_argument.dart' show ImplicitTypeArgument;
import '../kernel/internal_ast.dart';
import '../kernel/late_lowering.dart' as late_lowering;
import '../names.dart';
import '../problems.dart' show unhandled;
import '../source/source_library_builder.dart';
import 'inference_helper.dart';
import 'type_constraint_gatherer.dart';
import 'type_inference_engine.dart';
import 'type_inferrer.dart';
import 'type_schema.dart' show UnknownType;

abstract class InferenceVisitor {
  /// Performs type inference on the given [expression].
  ///
  /// [typeContext] is the expected type of the expression, based on surrounding
  /// code.  [typeNeeded] indicates whether it is necessary to compute the
  /// actual type of the expression.  If [typeNeeded] is `true`,
  /// [ExpressionInferenceResult.inferredType] is the actual type of the
  /// expression; otherwise the [UnknownType].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the expression type and calls the appropriate specialized "infer" method.
  ExpressionInferenceResult inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false, bool forEffect: false});

  /// Performs type inference on the given [statement].
  ///
  /// If [closureContext] is not null, the [statement] is inferred using
  /// [closureContext] as the current context.
  StatementInferenceResult inferStatement(Statement statement,
      [ClosureContext? closureContext]);

  /// Performs type inference on the given [initializer].
  InitializerInferenceResult inferInitializer(Initializer initializer);
}

class InferenceVisitorImpl extends InferenceVisitorBase
    implements
        ExpressionVisitor1<ExpressionInferenceResult, DartType>,
        StatementVisitor<StatementInferenceResult>,
        InitializerVisitor<InitializerInferenceResult>,
        InferenceVisitor {
  Class? mapEntryClass;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  ClosureContext? _closureContext;

  InferenceVisitorImpl(TypeInferrerImpl inferrer, InferenceHelper? helper)
      : super(inferrer, helper);

  ClosureContext get closureContext => _closureContext!;

  @override
  StatementInferenceResult inferStatement(Statement statement,
      [ClosureContext? closureContext]) {
    ClosureContext? oldClosureContext = _closureContext;
    if (closureContext != null) {
      _closureContext = closureContext;
    }
    registerIfUnreachableForTesting(statement);

    // For full (non-top level) inference, we need access to the
    // ExpressionGeneratorHelper so that we can perform error recovery.
    StatementInferenceResult result;
    if (statement is InternalStatement) {
      result = statement.acceptInference(this);
    } else {
      result = statement.accept(this);
    }
    _closureContext = oldClosureContext;
    return result;
  }

  ExpressionInferenceResult _inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false, bool forEffect: false}) {
    registerIfUnreachableForTesting(expression);

    // `null` should never be used as the type context.  An instance of
    // `UnknownType` should be used instead.
    // ignore: unnecessary_null_comparison
    assert(typeContext != null);

    // When doing top level inference, we skip subexpressions whose type isn't
    // needed so that we don't induce bogus dependencies on fields mentioned in
    // those subexpressions.
    if (!typeNeeded) {
      return new ExpressionInferenceResult(const UnknownType(), expression);
    }

    ExpressionInferenceResult result;
    if (expression is ExpressionJudgment) {
      result = expression.acceptInference(this, typeContext);
    } else if (expression is InternalExpression) {
      result = expression.acceptInference(this, typeContext);
    } else {
      result = expression.accept1(this, typeContext);
    }
    DartType inferredType = result.inferredType;
    // ignore: unnecessary_null_comparison
    assert(inferredType != null,
        "No type inferred for $expression (${expression.runtimeType}).");
    if (inferredType is VoidType && !isVoidAllowed) {
      if (expression.parent is! ArgumentsImpl && !isTopLevel) {
        helper.addProblem(
            messageVoidExpression, expression.fileOffset, noLength);
      }
    }
    if (coreTypes.isBottom(result.inferredType)) {
      flowAnalysis.handleExit();
      if (shouldThrowUnsoundnessException &&
          // Don't throw on expressions that inherently return the bottom type.
          !(result.nullAwareAction is Throw ||
              result.nullAwareAction is Rethrow ||
              result.nullAwareAction is InvalidExpression)) {
        Expression replacement = createLet(
            createVariable(result.expression, result.inferredType),
            createReachabilityError(expression.fileOffset,
                messageNeverValueError, messageNeverValueWarning));
        flowAnalysis.forwardExpression(replacement, result.expression);
        result =
            new ExpressionInferenceResult(result.inferredType, replacement);
      }
    }
    return result;
  }

  @override
  ExpressionInferenceResult inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false, bool forEffect: false}) {
    ExpressionInferenceResult result = _inferExpression(
        expression, typeContext, typeNeeded,
        isVoidAllowed: isVoidAllowed, forEffect: forEffect);
    return result.stopShorting();
  }

  @override
  InitializerInferenceResult inferInitializer(Initializer initializer) {
    InitializerInferenceResult inferenceResult;
    if (initializer is InitializerJudgment) {
      inferenceResult = initializer.acceptInference(this);
    } else {
      inferenceResult = initializer.accept(this);
    }
    return inferenceResult;
  }

  ExpressionInferenceResult inferNullAwareExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false, bool forEffect: false}) {
    ExpressionInferenceResult result = _inferExpression(
        expression, typeContext, typeNeeded,
        isVoidAllowed: isVoidAllowed, forEffect: forEffect);
    if (isNonNullableByDefault) {
      return result;
    } else {
      return result.stopShorting();
    }
  }

  void inferSyntheticVariable(VariableDeclarationImpl variable) {
    assert(variable.isImplicitlyTyped);
    assert(variable.initializer != null);
    ExpressionInferenceResult result = inferExpression(
        variable.initializer!, const UnknownType(), true,
        isVoidAllowed: true);
    variable.initializer = result.expression..parent = variable;
    DartType inferredType =
        inferDeclarationType(result.inferredType, forSyntheticVariable: true);
    instrumentation?.record(uriForInstrumentation, variable.fileOffset, 'type',
        new InstrumentationValueForType(inferredType));
    variable.type = inferredType;
  }

  Link<NullAwareGuard> inferSyntheticVariableNullAware(
      VariableDeclarationImpl variable) {
    assert(variable.isImplicitlyTyped);
    assert(variable.initializer != null);
    ExpressionInferenceResult result = inferNullAwareExpression(
        variable.initializer!, const UnknownType(), true,
        isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    variable.initializer = result.nullAwareAction..parent = variable;

    DartType inferredType =
        inferDeclarationType(result.inferredType, forSyntheticVariable: true);
    instrumentation?.record(uriForInstrumentation, variable.fileOffset, 'type',
        new InstrumentationValueForType(inferredType));
    variable.type = inferredType;
    return nullAwareGuards;
  }

  /// Computes uri and offset for [node] for internal errors in a way that is
  /// safe for both top-level and full inference.
  _UriOffset _computeUriOffset(TreeNode node) {
    Uri uri;
    int fileOffset;
    if (!isTopLevel) {
      // In local inference we have access to the current file uri.
      uri = helper.uri;
      fileOffset = node.fileOffset;
    } else {
      Location? location = node.location;
      if (location != null) {
        // Use the location file uri, if available.
        uri = location.file;
        fileOffset = node.fileOffset;
      } else {
        // Otherwise use the library file uri with no offset.
        uri = libraryBuilder.fileUri;
        fileOffset = TreeNode.noOffset;
      }
    }
    return new _UriOffset(uri, fileOffset);
  }

  ExpressionInferenceResult _unhandledExpression(
      Expression node, DartType typeContext) {
    _UriOffset uriOffset = _computeUriOffset(node);
    unhandled("${node.runtimeType}", "InferenceVisitor", uriOffset.fileOffset,
        uriOffset.uri);
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
    // This is only used for error cases. The spec doesn't use this and
    // therefore doesn't specify the type context for the subterms.
    if (!isTopLevel) {
      StatementInferenceResult bodyResult = inferStatement(node.body);
      if (bodyResult.hasChanged) {
        node.body = (bodyResult.statement as Block)..parent = node;
      }
    }
    ExpressionInferenceResult valueResult = inferExpression(
        node.value, const UnknownType(), true,
        isVoidAllowed: true);
    node.value = valueResult.expression..parent = node;
    return new ExpressionInferenceResult(valueResult.inferredType, node);
  }

  @override
  ExpressionInferenceResult visitConstantExpression(
      ConstantExpression node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitDynamicGet(
      DynamicGet node, DartType typeContext) {
    // The node has already been inferred, for instance as part of a for-in
    // loop, so just compute the result type.
    DartType resultType;
    switch (node.kind) {
      case DynamicAccessKind.Dynamic:
        resultType = const DynamicType();
        break;
      case DynamicAccessKind.Never:
        resultType = NeverType.fromNullability(libraryBuilder.nonNullable);
        break;
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        resultType = const InvalidType();
        break;
    }
    return new ExpressionInferenceResult(resultType, node);
  }

  @override
  ExpressionInferenceResult visitInstanceGet(
      InstanceGet node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitInstanceTearOff(
      InstanceTearOff node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitDynamicInvocation(
      DynamicInvocation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitDynamicSet(
      DynamicSet node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitEqualsCall(
      EqualsCall node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitEqualsNull(
      EqualsNull node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitFunctionInvocation(
      FunctionInvocation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitInstanceInvocation(
      InstanceInvocation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitInstanceGetterInvocation(
      InstanceGetterInvocation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitInstanceSet(
      InstanceSet node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitLocalFunctionInvocation(
      LocalFunctionInvocation node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitStaticTearOff(
      StaticTearOff node, DartType typeContext) {
    ensureMemberType(node.target);
    DartType type =
        node.target.function.computeFunctionType(libraryBuilder.nonNullable);
    return instantiateTearOff(type, typeContext, node);
  }

  @override
  ExpressionInferenceResult visitFunctionTearOff(
      FunctionTearOff node, DartType typeContext) {
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
  ExpressionInferenceResult visitConstructorTearOff(
      ConstructorTearOff node, DartType typeContext) {
    ensureMemberType(node.target);
    DartType type =
        node.target.function!.computeFunctionType(libraryBuilder.nonNullable);
    return instantiateTearOff(type, typeContext, node);
  }

  @override
  ExpressionInferenceResult visitRedirectingFactoryTearOff(
      RedirectingFactoryTearOff node, DartType typeContext) {
    DartType type =
        node.target.function.computeFunctionType(libraryBuilder.nonNullable);
    return instantiateTearOff(type, typeContext, node);
  }

  @override
  ExpressionInferenceResult visitTypedefTearOff(
      TypedefTearOff node, DartType typeContext) {
    ExpressionInferenceResult expressionResult = inferExpression(
        node.expression, const UnknownType(), true,
        isVoidAllowed: true);
    node.expression = expressionResult.expression..parent = node;
    assert(
        expressionResult.inferredType is FunctionType,
        "Expected a FunctionType from tearing off a constructor from "
        "a typedef, but got '${expressionResult.inferredType.runtimeType}'.");
    FunctionType expressionType = expressionResult.inferredType as FunctionType;

    assert(expressionType.typeParameters.length == node.typeArguments.length);
    Substitution substitution = Substitution.fromPairs(
        expressionType.typeParameters, node.typeArguments);
    FunctionType resultType = substitution
        .substituteType(expressionType.withoutTypeParameters) as FunctionType;
    FreshTypeParameters freshTypeParameters =
        getFreshTypeParameters(node.typeParameters);
    resultType = freshTypeParameters.substitute(resultType) as FunctionType;
    resultType = new FunctionType(resultType.positionalParameters,
        resultType.returnType, resultType.declaredNullability,
        namedParameters: resultType.namedParameters,
        typeParameters: freshTypeParameters.freshTypeParameters,
        requiredParameterCount: resultType.requiredParameterCount);
    ExpressionInferenceResult inferredResult =
        instantiateTearOff(resultType, typeContext, node);
    return ensureAssignableResult(typeContext, inferredResult);
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
    _UriOffset uriOffset = _computeUriOffset(node);
    return unhandled("${node.runtimeType}", "InferenceVisitor",
        uriOffset.fileOffset, uriOffset.uri);
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

  Never _unhandledInitializer(Initializer node) {
    unhandled("${node.runtimeType}", "InferenceVisitor", node.fileOffset,
        node.location!.file);
  }

  @override
  InitializerInferenceResult defaultInitializer(Initializer node) {
    _unhandledInitializer(node);
  }

  @override
  InitializerInferenceResult visitInvalidInitializer(InvalidInitializer node) {
    _unhandledInitializer(node);
  }

  @override
  InitializerInferenceResult visitLocalInitializer(LocalInitializer node) {
    _unhandledInitializer(node);
  }

  @override
  ExpressionInferenceResult visitInvalidExpression(
      InvalidExpression node, DartType typeContext) {
    if (node.expression != null) {
      ExpressionInferenceResult result = inferExpression(
          node.expression!, typeContext, !isTopLevel,
          isVoidAllowed: true);
      node.expression = result.expression..parent = node;
    }
    return new ExpressionInferenceResult(const InvalidType(), node);
  }

  @override
  ExpressionInferenceResult visitInstantiation(
      Instantiation node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferExpression(
        node.expression, const UnknownType(), true,
        isVoidAllowed: true);
    Expression operand = operandResult.expression;
    DartType operandType = operandResult.inferredType;
    if (operandType is! FunctionType) {
      ObjectAccessTarget callMember = findInterfaceMember(
          operandType, callName, operand.fileOffset,
          callSiteAccessKind: CallSiteAccessKind.getterInvocation,
          includeExtensionMethods: true);
      switch (callMember.kind) {
        case ObjectAccessTargetKind.instanceMember:
          Member? target = callMember.member;
          if (target is Procedure && target.kind == ProcedureKind.Method) {
            operandType = getGetterType(callMember, operandType);
            operand = new InstanceTearOff(
                InstanceAccessKind.Instance, operand, callName,
                interfaceTarget: target, resultType: operandType)
              ..fileOffset = operand.fileOffset;
          }
          break;
        case ObjectAccessTargetKind.extensionMember:
          if (callMember.tearoffTarget != null &&
              callMember.extensionMethodKind == ProcedureKind.Method) {
            operandType = getGetterType(callMember, operandType);
            operand = new StaticInvocation(
                callMember.tearoffTarget as Procedure,
                new Arguments(<Expression>[operand],
                    types: callMember.inferredExtensionTypeArguments)
                  ..fileOffset = operand.fileOffset)
              ..fileOffset = operand.fileOffset;
          }
          break;
        case ObjectAccessTargetKind.nullableInstanceMember:
        case ObjectAccessTargetKind.objectMember:
        case ObjectAccessTargetKind.nullableCallFunction:
        case ObjectAccessTargetKind.nullableExtensionMember:
        case ObjectAccessTargetKind.dynamic:
        case ObjectAccessTargetKind.never:
        case ObjectAccessTargetKind.invalid:
        case ObjectAccessTargetKind.missing:
        case ObjectAccessTargetKind.ambiguous:
        case ObjectAccessTargetKind.callFunction:
          break;
      }
    }
    node.expression = operand..parent = node;
    Expression result = node;
    DartType resultType = const InvalidType();
    if (operandType is FunctionType) {
      if (operandType.typeParameters.length == node.typeArguments.length) {
        if (!isTopLevel) {
          checkBoundsInInstantiation(
              operandType, node.typeArguments, node.fileOffset,
              inferred: false);
        }
        if (operandType.isPotentiallyNullable) {
          if (!isTopLevel) {
            result = helper.buildProblem(
                templateInstantiationNullableGenericFunctionType.withArguments(
                    operandType, isNonNullableByDefault),
                node.fileOffset,
                noLength);
          }
        } else {
          resultType = Substitution.fromPairs(
                  operandType.typeParameters, node.typeArguments)
              .substituteType(operandType.withoutTypeParameters);
        }
      } else {
        if (!isTopLevel) {
          if (operandType.typeParameters.isEmpty) {
            result = helper.buildProblem(
                templateInstantiationNonGenericFunctionType.withArguments(
                    operandType, isNonNullableByDefault),
                node.fileOffset,
                noLength);
          } else if (operandType.typeParameters.length >
              node.typeArguments.length) {
            result = helper.buildProblem(
                templateInstantiationTooFewArguments.withArguments(
                    operandType.typeParameters.length,
                    node.typeArguments.length),
                node.fileOffset,
                noLength);
          } else if (operandType.typeParameters.length <
              node.typeArguments.length) {
            result = helper.buildProblem(
                templateInstantiationTooManyArguments.withArguments(
                    operandType.typeParameters.length,
                    node.typeArguments.length),
                node.fileOffset,
                noLength);
          }
        }
      }
    } else if (operandType is! InvalidType) {
      if (!isTopLevel) {
        result = helper.buildProblem(
            templateInstantiationNonGenericFunctionType.withArguments(
                operandType, isNonNullableByDefault),
            node.fileOffset,
            noLength);
      }
    }
    return new ExpressionInferenceResult(resultType, result);
  }

  @override
  ExpressionInferenceResult visitIntLiteral(
      IntLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        coreTypes.intRawType(libraryBuilder.nonNullable), node);
  }

  @override
  ExpressionInferenceResult visitAsExpression(
      AsExpression node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferExpression(
        node.operand, const UnknownType(), !isTopLevel,
        isVoidAllowed: true);
    node.operand = operandResult.expression..parent = node;
    flowAnalysis.asExpression_end(node.operand, node.type);
    return new ExpressionInferenceResult(node.type, node);
  }

  @override
  InitializerInferenceResult visitAssertInitializer(AssertInitializer node) {
    StatementInferenceResult result = inferStatement(node.statement);
    if (result.hasChanged) {
      node.statement = (result.statement as AssertStatement)..parent = node;
    }
    return const SuccessfulInitializerInferenceResult();
  }

  @override
  StatementInferenceResult visitAssertStatement(AssertStatement node) {
    flowAnalysis.assert_begin();
    InterfaceType expectedType =
        coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
        node.condition, expectedType, !isTopLevel,
        isVoidAllowed: true);

    Expression condition =
        ensureAssignableResult(expectedType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.assert_afterCondition(node.condition);
    if (node.message != null) {
      ExpressionInferenceResult messageResult = inferExpression(
          node.message!, const UnknownType(), !isTopLevel,
          isVoidAllowed: true);
      node.message = messageResult.expression..parent = node;
    }
    flowAnalysis.assert_end();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitAwaitExpression(
      AwaitExpression node, DartType typeContext) {
    if (!typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = wrapFutureOrType(typeContext);
    }
    ExpressionInferenceResult operandResult = inferExpression(
        node.operand, typeContext, true,
        isVoidAllowed: !isNonNullableByDefault);
    DartType inferredType =
        typeSchemaEnvironment.flatten(operandResult.inferredType);
    node.operand = operandResult.expression..parent = node;
    return new ExpressionInferenceResult(inferredType, node);
  }

  List<Statement>? _visitStatements<T extends Statement>(List<T> statements) {
    List<Statement>? result;
    for (int index = 0; index < statements.length; index++) {
      T statement = statements[index];
      StatementInferenceResult statementResult = inferStatement(statement);
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
    registerIfUnreachableForTesting(node);
    List<Statement>? result = _visitStatements<Statement>(node.statements);
    if (result != null) {
      Block block = new Block(result)..fileOffset = node.fileOffset;
      libraryBuilder.loader.dataForTesting?.registerAlias(node, block);
      return new StatementInferenceResult.single(block);
    } else {
      return const StatementInferenceResult();
    }
  }

  @override
  ExpressionInferenceResult visitBoolLiteral(
      BoolLiteral node, DartType typeContext) {
    flowAnalysis.booleanLiteral(node, node.value);
    return new ExpressionInferenceResult(
        coreTypes.boolRawType(libraryBuilder.nonNullable), node);
  }

  @override
  StatementInferenceResult visitBreakStatement(
      covariant BreakStatementImpl node) {
    // TODO(johnniwinther): Refactor break/continue encoding.
    assert(node.targetStatement != null);
    if (node.isContinue) {
      flowAnalysis.handleContinue(node.targetStatement!);
    } else {
      flowAnalysis.handleBreak(node.targetStatement!);
    }
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result = inferExpression(
        node.variable.initializer!, typeContext, true,
        isVoidAllowed: false);
    if (node.isNullAware) {
      reportNonNullableInNullAwareWarningIfNeeded(
          result.inferredType, "?..", node.fileOffset);
    }

    node.variable.initializer = result.expression..parent = node.variable;
    node.variable.type = result.inferredType;
    NullAwareGuard? nullAwareGuard;
    if (node.isNullAware) {
      nullAwareGuard = createNullAwareGuard(node.variable);
    }

    List<ExpressionInferenceResult> expressionResults =
        <ExpressionInferenceResult>[];
    for (Expression expression in node.expressions) {
      expressionResults.add(inferExpression(
          expression, const UnknownType(), !isTopLevel,
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
          nullAwareGuard!.createExpression(result.inferredType, replacement);
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
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    // ignore: unnecessary_null_comparison
    assert(fileOffset != TreeNode.noOffset);
    return new BlockExpression(body, value)..fileOffset = fileOffset;
  }

  ExpressionStatement _createExpressionStatement(Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(expression != null);
    assert(expression.fileOffset != TreeNode.noOffset);
    return new ExpressionStatement(expression)
      ..fileOffset = expression.fileOffset;
  }

  @override
  ExpressionInferenceResult visitConditionalExpression(
      ConditionalExpression node, DartType typeContext) {
    flowAnalysis.conditional_conditionBegin();
    InterfaceType expectedType =
        coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
        node.condition, expectedType, !isTopLevel,
        isVoidAllowed: true);
    Expression condition =
        ensureAssignableResult(expectedType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.conditional_thenBegin(node.condition, node);
    bool isThenReachable = flowAnalysis.isReachable;
    ExpressionInferenceResult thenResult =
        inferExpression(node.then, typeContext, true, isVoidAllowed: true);
    node.then = thenResult.expression..parent = node;
    registerIfUnreachableForTesting(node.then, isReachable: isThenReachable);
    flowAnalysis.conditional_elseBegin(node.then);
    bool isOtherwiseReachable = flowAnalysis.isReachable;
    ExpressionInferenceResult otherwiseResult =
        inferExpression(node.otherwise, typeContext, true, isVoidAllowed: true);
    node.otherwise = otherwiseResult.expression..parent = node;
    registerIfUnreachableForTesting(node.otherwise,
        isReachable: isOtherwiseReachable);
    flowAnalysis.conditional_end(node, node.otherwise);
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        thenResult.inferredType,
        otherwiseResult.inferredType,
        libraryBuilder.library);
    node.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitConstructorInvocation(
      ConstructorInvocation node, DartType typeContext) {
    inferConstructorParameterTypes(node.target);
    bool hadExplicitTypeArguments = hasExplicitTypeArguments(node.arguments);
    FunctionType functionType = node.target.function
        .computeThisFunctionType(libraryBuilder.nonNullable);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, functionType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    if (!isTopLevel) {
      SourceLibraryBuilder library = libraryBuilder;
      if (!hadExplicitTypeArguments) {
        library.checkBoundsInConstructorInvocation(
            node, typeSchemaEnvironment, helper.uri,
            inferred: true);
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(node));
  }

  @override
  StatementInferenceResult visitContinueSwitchStatement(
      ContinueSwitchStatement node) {
    flowAnalysis.handleContinue(node.target.body);
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitExtensionTearOff(
      ExtensionTearOff node, DartType typeContext) {
    // ignore: unnecessary_null_comparison
    FunctionType calleeType = node.target != null
        ? node.target.function.computeFunctionType(libraryBuilder.nonNullable)
        : new FunctionType([], const DynamicType(), libraryBuilder.nonNullable);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        staticTarget: node.target);
    StaticInvocation replacement =
        new StaticInvocation(node.target, node.arguments);
    // ignore: unnecessary_null_comparison
    if (!isTopLevel && node.target != null) {
      libraryBuilder.checkBoundsInStaticInvocation(
          replacement, typeSchemaEnvironment, helper.uri, typeArgumentsInfo);
    }
    return instantiateTearOff(
        result.inferredType, typeContext, result.applyResult(replacement));
  }

  ExpressionInferenceResult visitExtensionSet(
      ExtensionSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension,
        node.explicitTypeArguments,
        receiverResult.inferredType);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.target, null, ProcedureKind.Setter, extensionTypeArguments);

    DartType valueType = getSetterType(target, receiverResult.inferredType);

    ExpressionInferenceResult valueResult = inferExpression(
        node.value, const UnknownType(), true,
        isVoidAllowed: false);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    VariableDeclaration? valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    VariableDeclaration? receiverVariable;
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
      replacement = createLet(valueVariable!,
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
    ExpressionInferenceResult receiverResult = inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension,
        node.explicitTypeArguments,
        receiverResult.inferredType);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    VariableDeclaration? receiverVariable;
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
            node.getter!, null, ProcedureKind.Getter, extensionTypeArguments);

    DartType readType = getGetterType(readTarget, receiverType);

    Expression read;
    if (readTarget.isMissing) {
      read = createMissingPropertyGet(
          node.readOffset, readReceiver, readType, node.propertyName);
    } else {
      assert(readTarget.isExtensionMember);
      read = new StaticInvocation(
          readTarget.member as Procedure,
          new Arguments(<Expression>[
            readReceiver,
          ], types: readTarget.inferredExtensionTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    }

    ObjectAccessTarget writeTarget = node.setter == null
        ? const ObjectAccessTarget.missing()
        : new ExtensionAccessTarget(
            node.setter!, null, ProcedureKind.Setter, extensionTypeArguments);

    DartType valueType = getSetterType(writeTarget, receiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        read,
        readType,
        node.binaryName,
        node.rhs,
        null);

    binaryResult =
        ensureAssignableResult(valueType, binaryResult, isVoidAllowed: true);
    Expression value = binaryResult.expression;

    VariableDeclaration? valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueType);
      value = createVariableGet(valueVariable);
    }

    Expression write;
    if (writeTarget.isMissing) {
      write = createMissingPropertySet(
          node.writeOffset, writeReceiver, readType, node.propertyName, value,
          forEffect: node.forEffect);
    } else {
      assert(writeTarget.isExtensionMember);
      write = new StaticInvocation(
          writeTarget.member as Procedure,
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
      replacement = createLet(valueVariable!,
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
    ExpressionInferenceResult result = inferExpression(
        node.expression, typeContext, true,
        isVoidAllowed: true);

    Expression replacement = new Let(node.variable, result.expression)
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  StatementInferenceResult visitDoStatement(DoStatement node) {
    flowAnalysis.doStatement_bodyBegin(node);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    flowAnalysis.doStatement_conditionBegin();
    InterfaceType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
        node.condition, boolType, !isTopLevel,
        isVoidAllowed: true);
    Expression condition =
        ensureAssignableResult(boolType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.doStatement_end(condition);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitDoubleLiteral(
      DoubleLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        coreTypes.doubleRawType(libraryBuilder.nonNullable), node);
  }

  @override
  StatementInferenceResult visitEmptyStatement(EmptyStatement node) {
    // No inference needs to be done.
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitExpressionStatement(ExpressionStatement node) {
    ExpressionInferenceResult result = inferExpression(
        node.expression, const UnknownType(), !isTopLevel,
        isVoidAllowed: true, forEffect: true);
    node.expression = result.expression..parent = node;
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitFactoryConstructorInvocation(
      FactoryConstructorInvocation node, DartType typeContext) {
    bool hadExplicitTypeArguments = hasExplicitTypeArguments(node.arguments);

    FunctionType functionType = node.target.function
        .computeThisFunctionType(libraryBuilder.nonNullable);

    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, functionType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    if (!isTopLevel) {
      SourceLibraryBuilder library = libraryBuilder;
      if (!hadExplicitTypeArguments) {
        library.checkBoundsInFactoryInvocation(
            node, typeSchemaEnvironment, helper.uri,
            inferred: true);
      }
      if (isNonNullableByDefault) {
        if (node.target == coreTypes.listDefaultConstructor) {
          resultNode = helper.wrapInProblem(node,
              messageDefaultListConstructorError, node.fileOffset, noLength);
        }
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  ExpressionInferenceResult visitTypeAliasedConstructorInvocation(
      TypeAliasedConstructorInvocation node, DartType typeContext) {
    assert(getExplicitTypeArguments(node.arguments) == null);
    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType = node.target.function
        .computeAliasedConstructorFunctionType(typedef, libraryBuilder.library);
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    if (!isTopLevel) {
      if (isNonNullableByDefault) {
        if (node.target == coreTypes.listDefaultConstructor) {
          resultNode = helper.wrapInProblem(node,
              messageDefaultListConstructorError, node.fileOffset, noLength);
        }
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  ExpressionInferenceResult visitTypeAliasedFactoryInvocation(
      TypeAliasedFactoryInvocation node, DartType typeContext) {
    assert(getExplicitTypeArguments(node.arguments) == null);
    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType = node.target.function
        .computeAliasedFactoryFunctionType(typedef, libraryBuilder.library);
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    if (!isTopLevel) {
      if (isNonNullableByDefault) {
        if (node.target == coreTypes.listDefaultConstructor) {
          resultNode = helper.wrapInProblem(node,
              messageDefaultListConstructorError, node.fileOffset, noLength);
        }
      }
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  @override
  InitializerInferenceResult visitFieldInitializer(FieldInitializer node) {
    ExpressionInferenceResult initializerResult =
        inferExpression(node.value, node.field.type, true);
    Expression initializer = ensureAssignableResult(
            node.field.type, initializerResult,
            fileOffset: node.fileOffset)
        .expression;
    node.value = initializer..parent = node;
    return const SuccessfulInitializerInferenceResult();
  }

  ForInResult handleForInDeclaringVariable(
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Statement? expressionEffects,
      {bool isAsync: false}) {
    DartType elementType;
    bool typeNeeded = false;
    bool typeChecksNeeded = !isTopLevel;
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
      instrumentation?.record(uriForInstrumentation, variable.fileOffset,
          'type', new InstrumentationValueForType(inferredType));
      variable.type = inferredType;
    }

    // This is matched by the call to [forEach_end] in
    // [inferElement], [inferMapEntry] or [inferForInStatement].
    flowAnalysis.declare(variable, true);
    flowAnalysis.forEach_bodyBegin(node);

    VariableDeclaration tempVariable =
        new VariableDeclaration(null, type: inferredType, isFinal: true);
    VariableGet variableGet = new VariableGet(tempVariable)
      ..fileOffset = variable.fileOffset;
    TreeNode parent = variable.parent!;
    Expression implicitDowncast = ensureAssignable(
        variable.type, inferredType, variableGet,
        isVoidAllowed: true,
        fileOffset: parent.fileOffset,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability);
    Statement? expressionEffect;
    if (!identical(implicitDowncast, variableGet)) {
      variable.initializer = implicitDowncast..parent = variable;
      expressionEffect = variable;
      variable = tempVariable;
    }
    if (expressionEffects != null) {
      StatementInferenceResult bodyResult = inferStatement(expressionEffects);
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
    Class iterableClass =
        isAsync ? coreTypes.streamClass : coreTypes.iterableClass;
    DartType context =
        wrapType(elementType, iterableClass, libraryBuilder.nonNullable);
    ExpressionInferenceResult iterableResult =
        inferExpression(iterable, context, typeNeeded, isVoidAllowed: false);
    DartType iterableType = iterableResult.inferredType;
    iterable = iterableResult.expression;
    DartType inferredExpressionType = resolveTypeParameter(iterableType);
    iterable = ensureAssignable(
        wrapType(
            const DynamicType(), iterableClass, libraryBuilder.nonNullable),
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
        List<DartType>? supertypeArguments =
            classHierarchy.getTypeArgumentsAsInstanceOf(
                inferredExpressionType, iterableClass);
        if (supertypeArguments != null) {
          inferredType = supertypeArguments[0];
        }
      }
    } else {
      inferredType = noInferredType;
    }
    return new ExpressionInferenceResult(inferredType, iterable);
  }

  ForInVariable computeForInVariable(
      Expression? syntheticAssignment, bool hasProblem) {
    if (syntheticAssignment is VariableSet) {
      return new LocalForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is PropertySet) {
      return new PropertyForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is AbstractSuperPropertySet) {
      return new AbstractSuperPropertyForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is SuperPropertySet) {
      return new SuperPropertyForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is StaticSet) {
      return new StaticForInVariable(syntheticAssignment);
    } else if (syntheticAssignment is InvalidExpression || hasProblem) {
      return new InvalidForInVariable(syntheticAssignment);
    } else {
      _UriOffset uriOffset = _computeUriOffset(syntheticAssignment!);
      return unhandled(
          "${syntheticAssignment.runtimeType}",
          "handleForInStatementWithoutVariable",
          uriOffset.fileOffset,
          uriOffset.uri);
    }
  }

  ForInResult handleForInWithoutVariable(
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Expression? syntheticAssignment,
      Statement? expressionEffects,
      {bool isAsync: false,
      required bool hasProblem}) {
    // ignore: unnecessary_null_comparison
    assert(hasProblem != null);
    bool typeChecksNeeded = !isTopLevel;
    ForInVariable forInVariable =
        computeForInVariable(syntheticAssignment, hasProblem);
    DartType elementType = forInVariable.computeElementType(this);
    ExpressionInferenceResult iterableResult = inferForInIterable(
        iterable, elementType, typeChecksNeeded,
        isAsync: isAsync);
    DartType inferredType = iterableResult.inferredType;
    if (typeChecksNeeded) {
      variable.type = inferredType;
    }
    // This is matched by the call to [forEach_end] in
    // [inferElement], [inferMapEntry] or [inferForInStatement].
    flowAnalysis.forEach_bodyBegin(node);
    syntheticAssignment = forInVariable.inferAssignment(this, inferredType);
    if (syntheticAssignment is VariableSet) {
      flowAnalysis.write(node, variable, inferredType, null);
    }
    if (expressionEffects != null) {
      StatementInferenceResult result = inferStatement(expressionEffects);
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

    StatementInferenceResult bodyResult = inferStatement(node.body);

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();

    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
    if (result.expressionSideEffects != null) {
      body = combineStatements(result.expressionSideEffects!, body);
    }
    if (result.syntheticAssignment != null) {
      body = combineStatements(
          createExpressionStatement(result.syntheticAssignment!), body);
    }
    node.variable = result.variable..parent = node;
    node.iterable = result.iterable..parent = node;
    node.body = body..parent = node;
    return const StatementInferenceResult();
  }

  StatementInferenceResult visitForInStatementWithSynthesizedVariable(
      ForInStatementWithSynthesizedVariable node) {
    assert(node.variable!.name == null);
    ForInResult result = handleForInWithoutVariable(node, node.variable!,
        node.iterable, node.syntheticAssignment, node.expressionEffects,
        isAsync: node.isAsync, hasProblem: node.hasProblem);

    StatementInferenceResult bodyResult = inferStatement(node.body);

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();

    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
    if (result.expressionSideEffects != null) {
      body = combineStatements(result.expressionSideEffects!, body);
    }
    if (result.syntheticAssignment != null) {
      body = combineStatements(
          createExpressionStatement(result.syntheticAssignment!), body);
    }
    Statement replacement = new ForInStatement(
        result.variable, result.iterable, body,
        isAsync: node.isAsync)
      ..fileOffset = node.fileOffset
      ..bodyOffset = node.bodyOffset;
    libraryBuilder.loader.dataForTesting?.registerAlias(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  @override
  StatementInferenceResult visitForStatement(ForStatement node) {
    List<VariableDeclaration>? variables;
    for (int index = 0; index < node.variables.length; index++) {
      VariableDeclaration variable = node.variables[index];
      if (variable.name == null) {
        if (variable.initializer != null) {
          ExpressionInferenceResult result = inferExpression(
              variable.initializer!, const UnknownType(), true,
              isVoidAllowed: true);
          variable.initializer = result.expression..parent = variable;
          variable.type = result.inferredType;
        }
      } else {
        StatementInferenceResult variableResult = inferStatement(variable);
        if (variableResult.hasChanged) {
          if (variables == null) {
            variables = <VariableDeclaration>[];
            variables.addAll(node.variables.sublist(0, index));
          }
          if (variableResult.statementCount == 1) {
            variables.add(variableResult.statement as VariableDeclaration);
          } else {
            for (Statement variable in variableResult.statements) {
              variables.add(variable as VariableDeclaration);
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
    flowAnalysis.for_conditionBegin(node);
    if (node.condition != null) {
      InterfaceType expectedType =
          coreTypes.boolRawType(libraryBuilder.nonNullable);
      ExpressionInferenceResult conditionResult = inferExpression(
          node.condition!, expectedType, !isTopLevel,
          isVoidAllowed: true);
      Expression condition =
          ensureAssignableResult(expectedType, conditionResult).expression;
      node.condition = condition..parent = node;
    }

    flowAnalysis.for_bodyBegin(node, node.condition);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    flowAnalysis.for_updaterBegin();
    for (int index = 0; index < node.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
          node.updates[index], const UnknownType(), !isTopLevel,
          isVoidAllowed: true);
      node.updates[index] = updateResult.expression..parent = node;
    }
    flowAnalysis.for_end();
    return const StatementInferenceResult();
  }

  FunctionType visitFunctionNode(FunctionNode node, DartType? typeContext,
      DartType? returnContext, int returnTypeInstrumentationOffset) {
    return inferLocalFunction(this, node, typeContext,
        returnTypeInstrumentationOffset, returnContext);
  }

  @override
  StatementInferenceResult visitFunctionDeclaration(
      covariant FunctionDeclarationImpl node) {
    flowAnalysis.declare(node.variable, true);
    flowAnalysis.functionExpression_begin(node);
    inferMetadata(this, node.variable, node.variable.annotations);
    DartType? returnContext =
        node.hasImplicitReturnType ? null : node.function.returnType;
    FunctionType inferredType =
        visitFunctionNode(node.function, null, returnContext, node.fileOffset);
    if (dataForTesting != null && node.hasImplicitReturnType) {
      dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
          inferredType.returnType;
    }
    node.variable.type = inferredType;
    flowAnalysis.functionExpression_end();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitFunctionExpression(
      FunctionExpression node, DartType typeContext) {
    flowAnalysis.functionExpression_begin(node);
    FunctionType inferredType =
        visitFunctionNode(node.function, typeContext, null, node.fileOffset);
    if (dataForTesting != null) {
      dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
          inferredType.returnType;
    }
    flowAnalysis.functionExpression_end();
    return new ExpressionInferenceResult(inferredType, node);
  }

  InitializerInferenceResult visitInvalidSuperInitializerJudgment(
      InvalidSuperInitializerJudgment node) {
    Substitution substitution = Substitution.fromSupertype(
        classHierarchy.getClassAsInstanceOf(
            thisType!.classNode, node.target.enclosingClass)!);
    FunctionType functionType = replaceReturnType(
        substitution.substituteType(node.target.function
            .computeThisFunctionType(libraryBuilder.nonNullable)
            .withoutTypeParameters) as FunctionType,
        thisType!);
    InvocationInferenceResult invocationInferenceResult = inferInvocation(
        this,
        const UnknownType(),
        node.fileOffset,
        functionType,
        node.argumentsJudgment,
        skipTypeArgumentInference: true);
    return new InitializerInferenceResult.fromInvocationInferenceResult(
        invocationInferenceResult);
  }

  ExpressionInferenceResult visitIfNullExpression(
      IfNullExpression node, DartType typeContext) {
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    ExpressionInferenceResult lhsResult = inferExpression(
        node.left, computeNullable(typeContext), true,
        isVoidAllowed: false);
    reportNonNullableInNullAwareWarningIfNeeded(
        lhsResult.inferredType, "??", lhsResult.expression.fileOffset);

    // This ends any shorting in `node.left`.
    Expression left = lhsResult.expression;

    flowAnalysis.ifNullExpression_rightBegin(node.left, lhsResult.inferredType);

    // - Let J = T0 if K is `?` else K.
    // - Infer e1 in context J to get T1
    ExpressionInferenceResult rhsResult;
    if (typeContext is UnknownType) {
      rhsResult = inferExpression(node.right, lhsResult.inferredType, true,
          isVoidAllowed: true);
    } else {
      rhsResult =
          inferExpression(node.right, typeContext, true, isVoidAllowed: true);
    }
    flowAnalysis.ifNullExpression_end();

    // - Let T = greatest closure of K with respect to `?` if K is not `_`, else
    //   UP(t0, t1)
    // - Then the inferred type is T.
    DartType originalLhsType = lhsResult.inferredType;
    DartType nonNullableLhsType = originalLhsType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableLhsType, rhsResult.inferredType, libraryBuilder.library);
    Expression replacement;
    if (left is ThisExpression) {
      replacement = left;
    } else {
      VariableDeclaration variable =
          createVariable(left, lhsResult.inferredType);
      Expression equalsNull = createEqualsNull(
          lhsResult.expression.fileOffset, createVariableGet(variable));
      VariableGet variableGet = createVariableGet(variable);
      if (libraryBuilder.isNonNullableByDefault &&
          !identical(nonNullableLhsType, originalLhsType)) {
        variableGet.promotedType = nonNullableLhsType;
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, rhsResult.expression, variableGet, inferredType)
        ..fileOffset = node.fileOffset;
      replacement = new Let(variable, conditional)
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  StatementInferenceResult visitIfStatement(IfStatement node) {
    flowAnalysis.ifStatement_conditionBegin();
    InterfaceType expectedType =
        coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
        node.condition, expectedType, !isTopLevel,
        isVoidAllowed: true);
    Expression condition =
        ensureAssignableResult(expectedType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.ifStatement_thenBegin(condition, node);
    StatementInferenceResult thenResult = inferStatement(node.then);
    if (thenResult.hasChanged) {
      node.then = thenResult.statement..parent = node;
    }
    if (node.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      StatementInferenceResult otherwiseResult =
          inferStatement(node.otherwise!);
      if (otherwiseResult.hasChanged) {
        node.otherwise = otherwiseResult.statement..parent = node;
      }
    }
    flowAnalysis.ifStatement_end(node.otherwise != null);
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitIntJudgment(
      IntJudgment node, DartType typeContext) {
    if (isDoubleContext(typeContext)) {
      double? doubleValue = node.asDouble();
      if (doubleValue != null) {
        Expression replacement = new DoubleLiteral(doubleValue)
          ..fileOffset = node.fileOffset;
        DartType inferredType =
            coreTypes.doubleRawType(libraryBuilder.nonNullable);
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }
    Expression? error = checkWebIntLiteralsErrorIfUnexact(
        node.value, node.literal, node.fileOffset);
    if (error != null) {
      return new ExpressionInferenceResult(const DynamicType(), error);
    }
    DartType inferredType = coreTypes.intRawType(libraryBuilder.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitShadowLargeIntLiteral(
      ShadowLargeIntLiteral node, DartType typeContext) {
    if (isDoubleContext(typeContext)) {
      double? doubleValue = node.asDouble();
      if (doubleValue != null) {
        Expression replacement = new DoubleLiteral(doubleValue)
          ..fileOffset = node.fileOffset;
        DartType inferredType =
            coreTypes.doubleRawType(libraryBuilder.nonNullable);
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }

    int? intValue = node.asInt64();
    if (intValue == null) {
      Expression replacement = helper.buildProblem(
          templateIntegerLiteralIsOutOfRange.withArguments(node.literal),
          node.fileOffset,
          node.literal.length);
      return new ExpressionInferenceResult(const DynamicType(), replacement);
    }
    Expression? error = checkWebIntLiteralsErrorIfUnexact(
        intValue, node.literal, node.fileOffset);
    if (error != null) {
      return new ExpressionInferenceResult(const DynamicType(), error);
    }
    Expression replacement = new IntLiteral(intValue);
    DartType inferredType = coreTypes.intRawType(libraryBuilder.nonNullable);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  InitializerInferenceResult visitShadowInvalidInitializer(
      ShadowInvalidInitializer node) {
    ExpressionInferenceResult initializerResult = inferExpression(
        node.variable.initializer!, const UnknownType(), !isTopLevel,
        isVoidAllowed: false);
    node.variable.initializer = initializerResult.expression
      ..parent = node.variable;
    return const SuccessfulInitializerInferenceResult();
  }

  InitializerInferenceResult visitShadowInvalidFieldInitializer(
      ShadowInvalidFieldInitializer node) {
    ExpressionInferenceResult initializerResult = inferExpression(
        node.value, node.field.type, !isTopLevel,
        isVoidAllowed: false);
    node.value = initializerResult.expression..parent = node;
    return const SuccessfulInitializerInferenceResult();
  }

  @override
  ExpressionInferenceResult visitIsExpression(
      IsExpression node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferExpression(
        node.operand, const UnknownType(), !isTopLevel,
        isVoidAllowed: false);
    node.operand = operandResult.expression..parent = node;
    flowAnalysis.isExpression_end(
        node, node.operand, /*isNot:*/ false, node.type);
    return new ExpressionInferenceResult(
        coreTypes.boolRawType(libraryBuilder.nonNullable), node);
  }

  @override
  StatementInferenceResult visitLabeledStatement(LabeledStatement node) {
    bool isSimpleBody = node.body is Block ||
        node.body is IfStatement ||
        node.body is TryStatement;
    if (isSimpleBody) {
      flowAnalysis.labeledStatement_begin(node);
    }

    StatementInferenceResult bodyResult = inferStatement(node.body);

    if (isSimpleBody) {
      flowAnalysis.labeledStatement_end();
    }

    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    return const StatementInferenceResult();
  }

  DartType? getSpreadElementType(
      DartType spreadType, DartType spreadTypeBound, bool isNullAware) {
    if (coreTypes.isNull(spreadTypeBound)) {
      if (isNonNullableByDefault) {
        return isNullAware ? const NeverType.nonNullable() : null;
      } else {
        return isNullAware ? const NullType() : null;
      }
    }
    if (spreadTypeBound is InterfaceType) {
      List<DartType>? supertypeArguments =
          typeSchemaEnvironment.getTypeArgumentsAsInstanceOf(
              spreadTypeBound, coreTypes.iterableClass);
      if (supertypeArguments == null) {
        return null;
      }
      return supertypeArguments.single;
    } else if (spreadType is DynamicType) {
      return const DynamicType();
    } else if (coreTypes.isBottom(spreadType)) {
      return const NeverType.nonNullable();
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
      ExpressionInferenceResult spreadResult = inferExpression(
          element.expression,
          new InterfaceType(
              coreTypes.iterableClass,
              libraryBuilder.nullableIfTrue(element.isNullAware),
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
      DartType spreadTypeBound = resolveTypeParameter(spreadType);
      DartType? spreadElementType = getSpreadElementType(
          spreadType, spreadTypeBound, element.isNullAware);
      if (typeChecksNeeded) {
        if (spreadElementType == null) {
          if (coreTypes.isNull(spreadTypeBound) && !element.isNullAware) {
            replacement = helper.buildProblem(
                templateNonNullAwareSpreadIsNull.withArguments(
                    spreadType, isNonNullableByDefault),
                element.expression.fileOffset,
                1);
          } else {
            if (isNonNullableByDefault &&
                spreadType.isPotentiallyNullable &&
                spreadType is! DynamicType &&
                spreadType is! NullType &&
                !element.isNullAware) {
              Expression receiver = element.expression;
              replacement = helper.buildProblem(
                  messageNullableSpreadError, receiver.fileOffset, 1,
                  context: getWhyNotPromotedContext(
                      flowAnalysis.whyNotPromoted(receiver)(),
                      element,
                      (type) => !type.isPotentiallyNullable));
            }

            replacement = helper.buildProblem(
                templateSpreadTypeMismatch.withArguments(
                    spreadType, isNonNullableByDefault),
                element.expression.fileOffset,
                1);
            _copyNonPromotionReasonToReplacement(element, replacement);
          }
        } else if (spreadTypeBound is InterfaceType) {
          if (!isAssignable(inferredTypeArgument, spreadElementType)) {
            if (isNonNullableByDefault) {
              IsSubtypeOf subtypeCheckResult =
                  typeSchemaEnvironment.performNullabilityAwareSubtypeCheck(
                      spreadElementType, inferredTypeArgument);
              if (subtypeCheckResult.isSubtypeWhenIgnoringNullabilities()) {
                if (spreadElementType == subtypeCheckResult.subtype &&
                    inferredTypeArgument == subtypeCheckResult.supertype) {
                  replacement = helper.buildProblem(
                      templateSpreadElementTypeMismatchNullability
                          .withArguments(spreadElementType,
                              inferredTypeArgument, isNonNullableByDefault),
                      element.expression.fileOffset,
                      1);
                } else {
                  replacement = helper.buildProblem(
                      templateSpreadElementTypeMismatchPartNullability
                          .withArguments(
                              spreadElementType,
                              inferredTypeArgument,
                              subtypeCheckResult.subtype!,
                              subtypeCheckResult.supertype!,
                              isNonNullableByDefault),
                      element.expression.fileOffset,
                      1);
                }
              } else {
                replacement = helper.buildProblem(
                    templateSpreadElementTypeMismatch.withArguments(
                        spreadElementType,
                        inferredTypeArgument,
                        isNonNullableByDefault),
                    element.expression.fileOffset,
                    1);
              }
            } else {
              replacement = helper.buildProblem(
                  templateSpreadElementTypeMismatch.withArguments(
                      spreadElementType,
                      inferredTypeArgument,
                      isNonNullableByDefault),
                  element.expression.fileOffset,
                  1);
            }
          }
          if (isNonNullableByDefault &&
              spreadType.isPotentiallyNullable &&
              spreadType is! DynamicType &&
              spreadType is! NullType &&
              !element.isNullAware) {
            Expression receiver = element.expression;
            replacement = helper.buildProblem(
                messageNullableSpreadError, receiver.fileOffset, 1,
                context: getWhyNotPromotedContext(
                    flowAnalysis.whyNotPromoted(receiver)(),
                    element,
                    (type) => !type.isPotentiallyNullable));
            _copyNonPromotionReasonToReplacement(element, replacement);
          }
        }
      }
      // Use 'dynamic' for error recovery.
      element.elementType = spreadElementType ?? const DynamicType();
      return new ExpressionInferenceResult(element.elementType!, replacement);
    } else if (element is IfElement) {
      flowAnalysis.ifStatement_conditionBegin();
      DartType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
      ExpressionInferenceResult conditionResult = inferExpression(
          element.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      Expression condition =
          ensureAssignableResult(boolType, conditionResult).expression;
      element.condition = condition..parent = element;
      flowAnalysis.ifStatement_thenBegin(condition, element);
      ExpressionInferenceResult thenResult = inferElement(
          element.then,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      element.then = thenResult.expression..parent = element;
      ExpressionInferenceResult? otherwiseResult;
      if (element.otherwise != null) {
        flowAnalysis.ifStatement_elseBegin();
        otherwiseResult = inferElement(
            element.otherwise!,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded);
        element.otherwise = otherwiseResult.expression..parent = element;
      }
      flowAnalysis.ifStatement_end(element.otherwise != null);
      return new ExpressionInferenceResult(
          otherwiseResult == null
              ? thenResult.inferredType
              : typeSchemaEnvironment.getStandardUpperBound(
                  thenResult.inferredType,
                  otherwiseResult.inferredType,
                  libraryBuilder.library),
          element);
    } else if (element is ForElement) {
      // TODO(johnniwinther): Use _visitStatements instead.
      List<VariableDeclaration>? variables;
      for (int index = 0; index < element.variables.length; index++) {
        VariableDeclaration variable = element.variables[index];
        if (variable.name == null) {
          if (variable.initializer != null) {
            ExpressionInferenceResult initializerResult = inferExpression(
                variable.initializer!,
                variable.type,
                inferenceNeeded || typeChecksNeeded,
                isVoidAllowed: true);
            variable.initializer = initializerResult.expression
              ..parent = variable;
            variable.type = initializerResult.inferredType;
          }
        } else {
          StatementInferenceResult variableResult = inferStatement(variable);
          if (variableResult.hasChanged) {
            if (variables == null) {
              variables = <VariableDeclaration>[];
              variables.addAll(element.variables.sublist(0, index));
            }
            if (variableResult.statementCount == 1) {
              variables.add(variableResult.statement as VariableDeclaration);
            } else {
              for (Statement variable in variableResult.statements) {
                variables.add(variable as VariableDeclaration);
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
      flowAnalysis.for_conditionBegin(element);
      if (element.condition != null) {
        ExpressionInferenceResult conditionResult = inferExpression(
            element.condition!,
            coreTypes.boolRawType(libraryBuilder.nonNullable),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: false);
        element.condition = conditionResult.expression..parent = element;
        inferredConditionTypes[element.condition!] =
            conditionResult.inferredType;
      }
      flowAnalysis.for_bodyBegin(null, element.condition);
      ExpressionInferenceResult bodyResult = inferElement(
          element.body,
          inferredTypeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
          inferenceNeeded,
          typeChecksNeeded);
      element.body = bodyResult.expression..parent = element;
      flowAnalysis.for_updaterBegin();
      for (int index = 0; index < element.updates.length; index++) {
        ExpressionInferenceResult updateResult = inferExpression(
            element.updates[index],
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        element.updates[index] = updateResult.expression..parent = element;
      }
      flowAnalysis.for_end();
      return new ExpressionInferenceResult(bodyResult.inferredType, element);
    } else if (element is ForInElement) {
      ForInResult result;
      if (element.variable.name == null) {
        result = handleForInWithoutVariable(
            element,
            element.variable,
            element.iterable,
            element.syntheticAssignment!,
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
        ExpressionInferenceResult problemResult = inferExpression(
            element.problem!,
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
      flowAnalysis.forEach_end();
      return new ExpressionInferenceResult(bodyResult.inferredType, element);
    } else {
      ExpressionInferenceResult result = inferExpression(
          element, inferredTypeArgument, inferenceNeeded || typeChecksNeeded,
          isVoidAllowed: true);
      if (inferredTypeArgument is! UnknownType) {
        result = ensureAssignableResult(inferredTypeArgument, result,
            isVoidAllowed: inferredTypeArgument is VoidType);
      }
      return result;
    }
  }

  void _copyNonPromotionReasonToReplacement(
      TreeNode oldNode, TreeNode replacement) {
    if (!identical(oldNode, replacement) &&
        dataForTesting?.flowAnalysisResult != null) {
      dataForTesting!.flowAnalysisResult.nonPromotionReasons[replacement] =
          dataForTesting!.flowAnalysisResult.nonPromotionReasons[oldNode]!;
    }
  }

  void checkElement(
      Expression item,
      Expression parent,
      DartType typeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    if (item is SpreadElement) {
      DartType? spreadType = inferredSpreadTypes[item.expression];
      if (spreadType is DynamicType) {
        Expression expression = ensureAssignable(
            coreTypes.iterableRawType(
                libraryBuilder.nullableIfTrue(item.isNullAware)),
            spreadType,
            item.expression);
        item.expression = expression..parent = item;
      }
    } else if (item is IfElement) {
      checkElement(item.then, item, typeArgument, inferredSpreadTypes,
          inferredConditionTypes);
      if (item.otherwise != null) {
        checkElement(item.otherwise!, item, typeArgument, inferredSpreadTypes,
            inferredConditionTypes);
      }
    } else if (item is ForElement) {
      if (item.condition != null) {
        DartType conditionType = inferredConditionTypes[item.condition]!;
        Expression condition = ensureAssignable(
            coreTypes.boolRawType(libraryBuilder.nonNullable),
            conditionType,
            item.condition!);
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
    Class listClass = coreTypes.listClass;
    InterfaceType listType =
        coreTypes.thisInterfaceType(listClass, libraryBuilder.nonNullable);
    List<DartType>? inferredTypes;
    DartType inferredTypeArgument;
    List<DartType>? formalTypes;
    List<DartType>? actualTypes;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    bool typeChecksNeeded = !isTopLevel;
    Map<TreeNode, DartType>? inferredSpreadTypes;
    Map<Expression, DartType>? inferredConditionTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
      inferredSpreadTypes = new Map<TreeNode, DartType>.identity();
      inferredConditionTypes = new Map<Expression, DartType>.identity();
    }
    TypeConstraintGatherer? gatherer;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(listType,
          listClass.typeParameters, typeContext, libraryBuilder.library,
          isConst: node.isConst);
      inferredTypes = typeSchemaEnvironment.partialInfer(
          gatherer, listClass.typeParameters, null, libraryBuilder.library);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    if (inferenceNeeded || typeChecksNeeded) {
      for (int index = 0; index < node.expressions.length; ++index) {
        ExpressionInferenceResult result = inferElement(
            node.expressions[index],
            inferredTypeArgument,
            inferredSpreadTypes!,
            inferredConditionTypes!,
            inferenceNeeded,
            typeChecksNeeded);
        node.expressions[index] = result.expression..parent = node;
        actualTypes!.add(result.inferredType);
        if (inferenceNeeded) {
          formalTypes!.add(listType.typeArguments[0]);
        }
      }
    }
    if (inferenceNeeded) {
      gatherer!.constrainArguments(formalTypes!, actualTypes!);
      inferredTypes = typeSchemaEnvironment.upwardsInfer(gatherer,
          listClass.typeParameters, inferredTypes!, libraryBuilder.library);
      if (dataForTesting != null) {
        dataForTesting!.typeInferenceResult.inferredTypeArguments[node] =
            inferredTypes;
      }
      inferredTypeArgument = inferredTypes[0];
      instrumentation?.record(
          uriForInstrumentation,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      node.typeArgument = inferredTypeArgument;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; i++) {
        checkElement(node.expressions[i], node, node.typeArgument,
            inferredSpreadTypes!, inferredConditionTypes!);
      }
    }
    DartType inferredType = new InterfaceType(
        listClass, libraryBuilder.nonNullable, [inferredTypeArgument]);
    if (!isTopLevel) {
      SourceLibraryBuilder library = libraryBuilder;
      if (inferenceNeeded) {
        if (!library.libraryFeatures.genericMetadata.isEnabled) {
          checkGenericFunctionTypeArgument(node.typeArgument, node.fileOffset);
        }
      }
    }

    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitLogicalExpression(
      LogicalExpression node, DartType typeContext) {
    InterfaceType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    flowAnalysis.logicalBinaryOp_begin();
    ExpressionInferenceResult leftResult =
        inferExpression(node.left, boolType, !isTopLevel, isVoidAllowed: false);
    Expression left = ensureAssignableResult(boolType, leftResult).expression;
    node.left = left..parent = node;
    flowAnalysis.logicalBinaryOp_rightBegin(node.left, node,
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND);
    ExpressionInferenceResult rightResult = inferExpression(
        node.right, boolType, !isTopLevel,
        isVoidAllowed: false);
    Expression right = ensureAssignableResult(boolType, rightResult).expression;
    node.right = right..parent = node;
    flowAnalysis.logicalBinaryOp_end(node, node.right,
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND);
    return new ExpressionInferenceResult(boolType, node);
  }

  // Calculates the key and the value type of a spread map entry of type
  // spreadMapEntryType and stores them in output in positions offset and offset
  // + 1.  If the types can't be calculated, for example, if spreadMapEntryType
  // is a function type, the original values in output are preserved.
  void storeSpreadMapEntryElementTypes(DartType spreadMapEntryType,
      bool isNullAware, List<DartType?> output, int offset) {
    DartType typeBound = resolveTypeParameter(spreadMapEntryType);
    if (coreTypes.isNull(typeBound)) {
      if (isNullAware) {
        if (isNonNullableByDefault) {
          output[offset] = output[offset + 1] = const NeverType.nonNullable();
        } else {
          output[offset] = output[offset + 1] = const NullType();
        }
      }
    } else if (typeBound is InterfaceType) {
      List<DartType>? supertypeArguments = typeSchemaEnvironment
          .getTypeArgumentsAsInstanceOf(typeBound, coreTypes.mapClass);
      if (supertypeArguments != null) {
        output[offset] = supertypeArguments[0];
        output[offset + 1] = supertypeArguments[1];
      }
    } else if (spreadMapEntryType is DynamicType) {
      output[offset] = output[offset + 1] = const DynamicType();
    } else if (coreTypes.isBottom(spreadMapEntryType)) {
      output[offset] = output[offset + 1] = const NeverType.nonNullable();
    }
  }

  // Note that inferMapEntry adds exactly two elements to actualTypes -- the
  // actual types of the key and the value.  The same technique is used for
  // actualTypesForSet, only inferMapEntry adds exactly one element to that
  // list: the actual type of the iterable spread elements in case the map
  // literal will be disambiguated as a set literal later.
  MapLiteralEntry inferMapEntry(
      MapLiteralEntry entry,
      TreeNode parent,
      DartType inferredKeyType,
      DartType inferredValueType,
      DartType spreadContext,
      List<DartType> actualTypes,
      List<DartType> actualTypesForSet,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes,
      bool inferenceNeeded,
      bool typeChecksNeeded,
      _MapLiteralEntryOffsets offsets) {
    if (entry is SpreadMapEntry) {
      ExpressionInferenceResult spreadResult = inferExpression(
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
      actualTypes.add(noInferredType);
      actualTypes.add(noInferredType);
      storeSpreadMapEntryElementTypes(
          spreadType, entry.isNullAware, actualTypes, length);
      DartType? actualKeyType = actualTypes[length];
      DartType? actualValueType = actualTypes[length + 1];
      DartType spreadTypeBound = resolveTypeParameter(spreadType);
      DartType? actualElementType =
          getSpreadElementType(spreadType, spreadTypeBound, entry.isNullAware);

      MapLiteralEntry replacement = entry;
      if (typeChecksNeeded) {
        if (actualKeyType == noInferredType) {
          if (coreTypes.isNull(spreadTypeBound) && !entry.isNullAware) {
            replacement = new MapLiteralEntry(
                helper.buildProblem(
                    templateNonNullAwareSpreadIsNull.withArguments(
                        spreadType, isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1),
                new NullLiteral())
              ..fileOffset = entry.fileOffset;
          } else if (actualElementType != null) {
            if (isNonNullableByDefault &&
                spreadType.isPotentiallyNullable &&
                spreadType is! DynamicType &&
                spreadType is! NullType &&
                !entry.isNullAware) {
              Expression receiver = entry.expression;
              Expression problem = helper.buildProblem(
                  messageNullableSpreadError, receiver.fileOffset, 1,
                  context: getWhyNotPromotedContext(
                      flowAnalysis.whyNotPromoted(receiver)(),
                      entry,
                      (type) => !type.isPotentiallyNullable));
              _copyNonPromotionReasonToReplacement(entry, problem);
              replacement = new SpreadMapEntry(problem, isNullAware: false)
                ..fileOffset = entry.fileOffset;
            }

            // Don't report the error here, it might be an ambiguous Set.  The
            // error is reported in checkMapEntry if it's disambiguated as map.
            offsets.iterableSpreadType = spreadType;
          } else {
            Expression receiver = entry.expression;
            Expression problem = helper.buildProblem(
                templateSpreadMapEntryTypeMismatch.withArguments(
                    spreadType, isNonNullableByDefault),
                receiver.fileOffset,
                1,
                context: getWhyNotPromotedContext(
                    flowAnalysis.whyNotPromoted(receiver)(),
                    entry,
                    (type) => !type.isPotentiallyNullable));
            _copyNonPromotionReasonToReplacement(entry, problem);
            replacement = new MapLiteralEntry(problem, new NullLiteral())
              ..fileOffset = entry.fileOffset;
          }
        } else if (spreadTypeBound is InterfaceType) {
          Expression? keyError;
          Expression? valueError;
          if (!isAssignable(inferredKeyType, actualKeyType)) {
            if (isNonNullableByDefault) {
              IsSubtypeOf subtypeCheckResult =
                  typeSchemaEnvironment.performNullabilityAwareSubtypeCheck(
                      actualKeyType, inferredKeyType);
              if (subtypeCheckResult.isSubtypeWhenIgnoringNullabilities()) {
                if (actualKeyType == subtypeCheckResult.subtype &&
                    inferredKeyType == subtypeCheckResult.supertype) {
                  keyError = helper.buildProblem(
                      templateSpreadMapEntryElementKeyTypeMismatchNullability
                          .withArguments(actualKeyType, inferredKeyType,
                              isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                } else {
                  keyError = helper.buildProblem(
                      // ignore: lines_longer_than_80_chars
                      templateSpreadMapEntryElementKeyTypeMismatchPartNullability
                          .withArguments(
                              actualKeyType,
                              inferredKeyType,
                              subtypeCheckResult.subtype!,
                              subtypeCheckResult.supertype!,
                              isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                }
              } else {
                keyError = helper.buildProblem(
                    templateSpreadMapEntryElementKeyTypeMismatch.withArguments(
                        actualKeyType, inferredKeyType, isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1);
              }
            } else {
              keyError = helper.buildProblem(
                  templateSpreadMapEntryElementKeyTypeMismatch.withArguments(
                      actualKeyType, inferredKeyType, isNonNullableByDefault),
                  entry.expression.fileOffset,
                  1);
            }
          }
          if (!isAssignable(inferredValueType, actualValueType)) {
            if (isNonNullableByDefault) {
              IsSubtypeOf subtypeCheckResult =
                  typeSchemaEnvironment.performNullabilityAwareSubtypeCheck(
                      actualValueType, inferredValueType);
              if (subtypeCheckResult.isSubtypeWhenIgnoringNullabilities()) {
                if (actualValueType == subtypeCheckResult.subtype &&
                    inferredValueType == subtypeCheckResult.supertype) {
                  valueError = helper.buildProblem(
                      templateSpreadMapEntryElementValueTypeMismatchNullability
                          .withArguments(actualValueType, inferredValueType,
                              isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                } else {
                  valueError = helper.buildProblem(
                      // ignore: lines_longer_than_80_chars
                      templateSpreadMapEntryElementValueTypeMismatchPartNullability
                          .withArguments(
                              actualValueType,
                              inferredValueType,
                              subtypeCheckResult.subtype!,
                              subtypeCheckResult.supertype!,
                              isNonNullableByDefault),
                      entry.expression.fileOffset,
                      1);
                }
              } else {
                valueError = helper.buildProblem(
                    templateSpreadMapEntryElementValueTypeMismatch
                        .withArguments(actualValueType, inferredValueType,
                            isNonNullableByDefault),
                    entry.expression.fileOffset,
                    1);
              }
            } else {
              valueError = helper.buildProblem(
                  templateSpreadMapEntryElementValueTypeMismatch.withArguments(
                      actualValueType,
                      inferredValueType,
                      isNonNullableByDefault),
                  entry.expression.fileOffset,
                  1);
            }
          }
          if (isNonNullableByDefault &&
              spreadType.isPotentiallyNullable &&
              spreadType is! DynamicType &&
              spreadType is! NullType &&
              !entry.isNullAware) {
            Expression receiver = entry.expression;
            keyError = helper.buildProblem(
                messageNullableSpreadError, receiver.fileOffset, 1,
                context: getWhyNotPromotedContext(
                    flowAnalysis.whyNotPromoted(receiver)(),
                    entry,
                    (type) => !type.isPotentiallyNullable));
            _copyNonPromotionReasonToReplacement(entry, keyError);
          }
          if (keyError != null || valueError != null) {
            keyError ??= new NullLiteral();
            valueError ??= new NullLiteral();
            replacement = new MapLiteralEntry(keyError, valueError)
              ..fileOffset = entry.fileOffset;
          }
        }
      }

      // Use 'dynamic' for error recovery.
      if (actualKeyType == noInferredType) {
        actualKeyType = actualTypes[length] = const DynamicType();
        actualValueType = actualTypes[length + 1] = const DynamicType();
      }
      // Store the type in case of an ambiguous Set.  Use 'dynamic' for error
      // recovery.
      actualTypesForSet.add(actualElementType ?? const DynamicType());

      mapEntryClass ??= coreTypes.index.getClass('dart:core', 'MapEntry');
      // TODO(cstefantsova):  Handle the case of an ambiguous Set.
      entry.entryType = new InterfaceType(
          mapEntryClass!,
          libraryBuilder.nonNullable,
          <DartType>[actualKeyType, actualValueType]);

      bool isMap = typeSchemaEnvironment.isSubtypeOf(
          spreadType,
          coreTypes.mapRawType(libraryBuilder.nullable),
          SubtypeCheckMode.withNullabilities);
      bool isIterable = typeSchemaEnvironment.isSubtypeOf(
          spreadType,
          coreTypes.iterableRawType(libraryBuilder.nullable),
          SubtypeCheckMode.withNullabilities);
      if (isMap && !isIterable) {
        offsets.mapSpreadOffset = entry.fileOffset;
      }
      if (!isMap && isIterable) {
        offsets.iterableSpreadOffset = entry.expression.fileOffset;
      }

      return replacement;
    } else if (entry is IfMapEntry) {
      flowAnalysis.ifStatement_conditionBegin();
      DartType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
      ExpressionInferenceResult conditionResult = inferExpression(
          entry.condition, boolType, typeChecksNeeded,
          isVoidAllowed: false);
      Expression condition =
          ensureAssignableResult(boolType, conditionResult).expression;
      entry.condition = condition..parent = entry;
      flowAnalysis.ifStatement_thenBegin(condition, entry);
      // Note that this recursive invocation of inferMapEntry will add two types
      // to actualTypes; they are the actual types of the current invocation if
      // the 'else' branch is empty.
      MapLiteralEntry then = inferMapEntry(
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
          typeChecksNeeded,
          offsets);
      entry.then = then..parent = entry;
      if (entry.otherwise != null) {
        flowAnalysis.ifStatement_elseBegin();
        // We need to modify the actual types added in the recursive call to
        // inferMapEntry.
        DartType? actualValueType = actualTypes.removeLast();
        DartType? actualKeyType = actualTypes.removeLast();
        DartType actualTypeForSet = actualTypesForSet.removeLast();
        MapLiteralEntry otherwise = inferMapEntry(
            entry.otherwise!,
            entry,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            inferenceNeeded,
            typeChecksNeeded,
            offsets);
        int length = actualTypes.length;
        actualTypes[length - 2] = typeSchemaEnvironment.getStandardUpperBound(
            actualKeyType, actualTypes[length - 2], libraryBuilder.library);
        actualTypes[length - 1] = typeSchemaEnvironment.getStandardUpperBound(
            actualValueType, actualTypes[length - 1], libraryBuilder.library);
        int lengthForSet = actualTypesForSet.length;
        actualTypesForSet[lengthForSet - 1] =
            typeSchemaEnvironment.getStandardUpperBound(actualTypeForSet,
                actualTypesForSet[lengthForSet - 1], libraryBuilder.library);
        entry.otherwise = otherwise..parent = entry;
      }
      flowAnalysis.ifStatement_end(entry.otherwise != null);
      return entry;
    } else if (entry is ForMapEntry) {
      // TODO(johnniwinther): Use _visitStatements instead.
      List<VariableDeclaration>? variables;
      for (int index = 0; index < entry.variables.length; index++) {
        VariableDeclaration variable = entry.variables[index];
        if (variable.name == null) {
          if (variable.initializer != null) {
            ExpressionInferenceResult result = inferExpression(
                variable.initializer!,
                variable.type,
                inferenceNeeded || typeChecksNeeded,
                isVoidAllowed: true);
            variable.initializer = result.expression..parent = variable;
            variable.type = result.inferredType;
          }
        } else {
          StatementInferenceResult variableResult = inferStatement(variable);
          if (variableResult.hasChanged) {
            if (variables == null) {
              variables = <VariableDeclaration>[];
              variables.addAll(entry.variables.sublist(0, index));
            }
            if (variableResult.statementCount == 1) {
              variables.add(variableResult.statement as VariableDeclaration);
            } else {
              for (Statement variable in variableResult.statements) {
                variables.add(variable as VariableDeclaration);
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
      flowAnalysis.for_conditionBegin(entry);
      if (entry.condition != null) {
        ExpressionInferenceResult conditionResult = inferExpression(
            entry.condition!,
            coreTypes.boolRawType(libraryBuilder.nonNullable),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: false);
        entry.condition = conditionResult.expression..parent = entry;
        // TODO(johnniwinther): Ensure assignability of condition?
        inferredConditionTypes[entry.condition!] = conditionResult.inferredType;
      }
      flowAnalysis.for_bodyBegin(null, entry.condition);
      // Actual types are added by the recursive call.
      MapLiteralEntry body = inferMapEntry(
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
          typeChecksNeeded,
          offsets);
      entry.body = body..parent = entry;
      flowAnalysis.for_updaterBegin();
      for (int index = 0; index < entry.updates.length; index++) {
        ExpressionInferenceResult updateResult = inferExpression(
            entry.updates[index],
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        entry.updates[index] = updateResult.expression..parent = entry;
      }
      flowAnalysis.for_end();
      return entry;
    } else if (entry is ForInMapEntry) {
      ForInResult result;
      if (entry.variable.name == null) {
        result = handleForInWithoutVariable(entry, entry.variable,
            entry.iterable, entry.syntheticAssignment!, entry.expressionEffects,
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
        ExpressionInferenceResult problemResult = inferExpression(
            entry.problem!,
            const UnknownType(),
            inferenceNeeded || typeChecksNeeded,
            isVoidAllowed: true);
        entry.problem = problemResult.expression..parent = entry;
      }
      // Actual types are added by the recursive call.
      MapLiteralEntry body = inferMapEntry(
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
          typeChecksNeeded,
          offsets);
      entry.body = body..parent = entry;
      // This is matched by the call to [forEach_bodyBegin] in
      // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
      flowAnalysis.forEach_end();
      return entry;
    } else {
      ExpressionInferenceResult keyResult = inferExpression(
          entry.key, inferredKeyType, true,
          isVoidAllowed: true);
      Expression key = ensureAssignableResult(inferredKeyType, keyResult,
              isVoidAllowed: inferredKeyType is VoidType)
          .expression;
      entry.key = key..parent = entry;
      ExpressionInferenceResult valueResult = inferExpression(
          entry.value, inferredValueType, true,
          isVoidAllowed: true);
      Expression value = ensureAssignableResult(inferredValueType, valueResult,
              isVoidAllowed: inferredValueType is VoidType)
          .expression;
      entry.value = value..parent = entry;
      actualTypes.add(keyResult.inferredType);
      actualTypes.add(valueResult.inferredType);
      // Use 'dynamic' for error recovery.
      actualTypesForSet.add(const DynamicType());
      offsets.mapEntryOffset = entry.fileOffset;
      return entry;
    }
  }

  MapLiteralEntry checkMapEntry(
      MapLiteralEntry entry,
      DartType keyType,
      DartType valueType,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes,
      _MapLiteralEntryOffsets offsets) {
    // It's disambiguated as a map literal.
    MapLiteralEntry replacement = entry;
    if (offsets.iterableSpreadOffset != null) {
      replacement = new MapLiteralEntry(
          helper.buildProblem(
              templateSpreadMapEntryTypeMismatch.withArguments(
                  offsets.iterableSpreadType!, isNonNullableByDefault),
              offsets.iterableSpreadOffset!,
              1),
          new NullLiteral())
        ..fileOffset = offsets.iterableSpreadOffset!;
    }
    if (entry is SpreadMapEntry) {
      DartType? spreadType = inferredSpreadTypes[entry.expression];
      if (spreadType is DynamicType) {
        Expression expression = ensureAssignable(
            coreTypes
                .mapRawType(libraryBuilder.nullableIfTrue(entry.isNullAware)),
            spreadType,
            entry.expression);
        entry.expression = expression..parent = entry;
      }
    } else if (entry is IfMapEntry) {
      MapLiteralEntry then = checkMapEntry(entry.then, keyType, valueType,
          inferredSpreadTypes, inferredConditionTypes, offsets);
      entry.then = then..parent = entry;
      if (entry.otherwise != null) {
        MapLiteralEntry otherwise = checkMapEntry(entry.otherwise!, keyType,
            valueType, inferredSpreadTypes, inferredConditionTypes, offsets);
        entry.otherwise = otherwise..parent = entry;
      }
    } else if (entry is ForMapEntry) {
      if (entry.condition != null) {
        DartType conditionType = inferredConditionTypes[entry.condition]!;
        Expression condition = ensureAssignable(
            coreTypes.boolRawType(libraryBuilder.nonNullable),
            conditionType,
            entry.condition!);
        entry.condition = condition..parent = entry;
      }
      MapLiteralEntry body = checkMapEntry(entry.body, keyType, valueType,
          inferredSpreadTypes, inferredConditionTypes, offsets);
      entry.body = body..parent = entry;
    } else if (entry is ForInMapEntry) {
      MapLiteralEntry body = checkMapEntry(entry.body, keyType, valueType,
          inferredSpreadTypes, inferredConditionTypes, offsets);
      entry.body = body..parent = entry;
    } else {
      // Do nothing.  Assignability checks are done during type inference.
    }
    return replacement;
  }

  @override
  ExpressionInferenceResult visitMapLiteral(
      MapLiteral node, DartType typeContext) {
    Class mapClass = coreTypes.mapClass;
    InterfaceType mapType =
        coreTypes.thisInterfaceType(mapClass, libraryBuilder.nonNullable);
    List<DartType>? inferredTypes;
    DartType inferredKeyType;
    DartType inferredValueType;
    List<DartType>? formalTypes;
    List<DartType>? actualTypes;
    List<DartType>? actualTypesForSet;
    assert((node.keyType is ImplicitTypeArgument) ==
        (node.valueType is ImplicitTypeArgument));
    bool inferenceNeeded = node.keyType is ImplicitTypeArgument;
    bool typeContextIsMap = node.keyType is! ImplicitTypeArgument;
    bool typeContextIsIterable = false;
    DartType? unfuturedTypeContext = typeSchemaEnvironment.flatten(typeContext);
    if (!isTopLevel && inferenceNeeded) {
      // Ambiguous set/map literal
      if (unfuturedTypeContext is InterfaceType) {
        typeContextIsMap = typeContextIsMap ||
            classHierarchy.isSubtypeOf(
                unfuturedTypeContext.classNode, coreTypes.mapClass);
        typeContextIsIterable = typeContextIsIterable ||
            classHierarchy.isSubtypeOf(
                unfuturedTypeContext.classNode, coreTypes.iterableClass);
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
    bool typeChecksNeeded = !isTopLevel;
    Map<TreeNode, DartType>? inferredSpreadTypes;
    Map<Expression, DartType>? inferredConditionTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
      actualTypesForSet = [];
      inferredSpreadTypes = new Map<TreeNode, DartType>.identity();
      inferredConditionTypes = new Map<Expression, DartType>.identity();
    }
    TypeConstraintGatherer? gatherer;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
          mapType, mapClass.typeParameters, typeContext, libraryBuilder.library,
          isConst: node.isConst);
      inferredTypes = typeSchemaEnvironment.partialInfer(
          gatherer, mapClass.typeParameters, null, libraryBuilder.library);
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
    } else {
      inferredKeyType = node.keyType;
      inferredValueType = node.valueType;
    }
    bool hasMapEntry = false;
    bool hasMapSpread = false;
    bool hasIterableSpread = false;
    _MapLiteralEntryOffsets offsets = new _MapLiteralEntryOffsets();
    if (inferenceNeeded || typeChecksNeeded) {
      DartType spreadTypeContext = const UnknownType();
      if (typeContextIsIterable && !typeContextIsMap) {
        spreadTypeContext = typeSchemaEnvironment.getTypeAsInstanceOf(
            unfuturedTypeContext as InterfaceType,
            coreTypes.iterableClass,
            libraryBuilder.library,
            coreTypes)!;
      } else if (!typeContextIsIterable && typeContextIsMap) {
        spreadTypeContext = new InterfaceType(
            coreTypes.mapClass,
            libraryBuilder.nonNullable,
            <DartType>[inferredKeyType, inferredValueType]);
      }
      for (int index = 0; index < node.entries.length; ++index) {
        MapLiteralEntry entry = inferMapEntry(
            node.entries[index],
            node,
            inferredKeyType,
            inferredValueType,
            spreadTypeContext,
            actualTypes!,
            actualTypesForSet!,
            inferredSpreadTypes!,
            inferredConditionTypes!,
            inferenceNeeded,
            typeChecksNeeded,
            offsets);
        node.entries[index] = entry..parent = node;
        if (inferenceNeeded) {
          formalTypes!.add(mapType.typeArguments[0]);
          formalTypes.add(mapType.typeArguments[1]);
        }
      }
      hasMapEntry = offsets.mapEntryOffset != null;
      hasMapSpread = offsets.mapSpreadOffset != null;
      hasIterableSpread = offsets.iterableSpreadOffset != null;
    }
    if (inferenceNeeded) {
      bool canBeSet = !hasMapSpread && !hasMapEntry && !typeContextIsMap;
      bool canBeMap = !hasIterableSpread && !typeContextIsIterable;
      if (canBeSet && !canBeMap) {
        List<Expression> setElements = <Expression>[];
        List<DartType> formalTypesForSet = <DartType>[];
        InterfaceType setType = coreTypes.thisInterfaceType(
            coreTypes.setClass, libraryBuilder.nonNullable);
        for (int i = 0; i < node.entries.length; ++i) {
          setElements.add(convertToElement(
            node.entries[i],
            isTopLevel ? null : helper,
            assignedVariables.reassignInfo,
            actualType: actualTypesForSet![i],
          ));
          formalTypesForSet.add(setType.typeArguments[0]);
        }

        // Note: we don't use the previously created gatherer because it was set
        // up presuming that the literal would be a map; we now know that it
        // needs to be a set.
        TypeConstraintGatherer gatherer =
            typeSchemaEnvironment.setupGenericTypeInference(
                setType,
                coreTypes.setClass.typeParameters,
                typeContext,
                libraryBuilder.library,
                isConst: node.isConst);
        List<DartType> inferredTypesForSet = typeSchemaEnvironment.partialInfer(
            gatherer,
            coreTypes.setClass.typeParameters,
            null,
            libraryBuilder.library);
        gatherer.constrainArguments(formalTypesForSet, actualTypesForSet!);
        inferredTypesForSet = typeSchemaEnvironment.upwardsInfer(
            gatherer,
            coreTypes.setClass.typeParameters,
            inferredTypesForSet,
            libraryBuilder.library);
        DartType inferredTypeArgument = inferredTypesForSet[0];
        instrumentation?.record(
            uriForInstrumentation,
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
                inferredSpreadTypes!,
                inferredConditionTypes!);
          }
        }

        DartType inferredType = new InterfaceType(coreTypes.setClass,
            libraryBuilder.nonNullable, inferredTypesForSet);
        return new ExpressionInferenceResult(inferredType, setLiteral);
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        Expression replacement = node;
        if (!isTopLevel) {
          replacement = helper.buildProblem(
              messageCantDisambiguateNotEnoughInformation, node.fileOffset, 1);
        }
        return new ExpressionInferenceResult(
            NeverType.fromNullability(libraryBuilder.nonNullable), replacement);
      }
      if (!canBeSet && !canBeMap) {
        Expression replacement = node;
        if (!isTopLevel) {
          replacement = helper.buildProblem(
              messageCantDisambiguateAmbiguousInformation, node.fileOffset, 1);
        }
        return new ExpressionInferenceResult(
            NeverType.fromNullability(libraryBuilder.nonNullable), replacement);
      }
      gatherer!.constrainArguments(formalTypes!, actualTypes!);
      inferredTypes = typeSchemaEnvironment.upwardsInfer(gatherer,
          mapClass.typeParameters, inferredTypes!, libraryBuilder.library);
      if (dataForTesting != null) {
        dataForTesting!.typeInferenceResult.inferredTypeArguments[node] =
            inferredTypes;
      }
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
      instrumentation?.record(
          uriForInstrumentation,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs(
              [inferredKeyType, inferredValueType]));
      node.keyType = inferredKeyType;
      node.valueType = inferredValueType;
    }
    if (typeChecksNeeded) {
      for (int index = 0; index < node.entries.length; ++index) {
        MapLiteralEntry entry = checkMapEntry(
            node.entries[index],
            node.keyType,
            node.valueType,
            inferredSpreadTypes!,
            inferredConditionTypes!,
            offsets);
        node.entries[index] = entry..parent = node;
      }
    }
    DartType inferredType = new InterfaceType(mapClass,
        libraryBuilder.nonNullable, [inferredKeyType, inferredValueType]);
    if (!isTopLevel) {
      SourceLibraryBuilder library = libraryBuilder;
      // Either both [_declaredKeyType] and [_declaredValueType] are omitted or
      // none of them, so we may just check one.
      if (inferenceNeeded) {
        if (!library.libraryFeatures.genericMetadata.isEnabled) {
          checkGenericFunctionTypeArgument(node.keyType, node.fileOffset);
          checkGenericFunctionTypeArgument(node.valueType, node.fileOffset);
        }
      }
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitMethodInvocation(
      MethodInvocation node, DartType typeContext) {
    assert(node.name != unaryMinusName);
    ExpressionInferenceResult result =
        inferNullAwareExpression(node.receiver, const UnknownType(), true);
    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;
    return inferMethodInvocation(
        this,
        node.fileOffset,
        nullAwareGuards,
        receiver,
        receiverType,
        node.name,
        node.arguments as ArgumentsImpl,
        typeContext,
        isExpressionInvocation: false,
        isImplicitCall: false);
  }

  ExpressionInferenceResult visitAugmentSuperInvocation(
      AugmentSuperInvocation node, DartType typeContext) {
    Member member = node.target;
    if (member.isInstanceMember) {
      ObjectAccessTarget target = new ObjectAccessTarget.interfaceMember(member,
          isPotentiallyNullable: false);
      Link<NullAwareGuard> nullAwareGuards = const Link<NullAwareGuard>();
      Expression receiver = new ThisExpression()..fileOffset = node.fileOffset;
      DartType receiverType = thisType!;
      return inferMethodInvocation(
          this,
          node.fileOffset,
          nullAwareGuards,
          receiver,
          receiverType,
          member.name,
          node.arguments as ArgumentsImpl,
          typeContext,
          isExpressionInvocation: false,
          isImplicitCall: false,
          target: target);
    } else if (member is Procedure) {
      FunctionType calleeType =
          member.function.computeFunctionType(libraryBuilder.nonNullable);
      TypeArgumentsInfo typeArgumentsInfo =
          getTypeArgumentsInfo(node.arguments);
      InvocationInferenceResult result = inferInvocation(this, typeContext,
          node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
          staticTarget: node.target);
      StaticInvocation invocation =
          new StaticInvocation(member, node.arguments);
      if (!isTopLevel) {
        libraryBuilder.checkBoundsInStaticInvocation(
            invocation, typeSchemaEnvironment, helper.uri, typeArgumentsInfo);
      }
      return new ExpressionInferenceResult(
          result.inferredType, result.applyResult(invocation));
    } else {
      // TODO(johnniwinther): Handle augmentation of field with inferred types.
      TypeInferenceEngine.resolveInferenceNode(member, classHierarchy);
      Link<NullAwareGuard> nullAwareGuards = const Link<NullAwareGuard>();
      DartType receiverType = member.getterType;
      Expression receiver = new StaticGet(member)..fileOffset = node.fileOffset;
      return inferMethodInvocation(
          this,
          node.fileOffset,
          nullAwareGuards,
          receiver,
          receiverType,
          callName,
          node.arguments as ArgumentsImpl,
          typeContext,
          isExpressionInvocation: true,
          isImplicitCall: true);
    }
  }

  ExpressionInferenceResult visitExpressionInvocation(
      ExpressionInvocation node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferNullAwareExpression(node.expression, const UnknownType(), true);
    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;
    return inferMethodInvocation(
        this,
        node.fileOffset,
        nullAwareGuards,
        receiver,
        receiverType,
        callName,
        node.arguments as ArgumentsImpl,
        typeContext,
        isExpressionInvocation: true,
        isImplicitCall: true);
  }

  @override
  ExpressionInferenceResult visitNot(Not node, DartType typeContext) {
    InterfaceType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult operandResult =
        inferExpression(node.operand, boolType, !isTopLevel);
    Expression operand = ensureAssignableResult(boolType, operandResult,
            fileOffset: node.fileOffset)
        .expression;
    node.operand = operand..parent = node;
    flowAnalysis.logicalNot_end(node, node.operand);
    return new ExpressionInferenceResult(boolType, node);
  }

  @override
  ExpressionInferenceResult visitNullCheck(
      NullCheck node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferNullAwareExpression(
        node.operand, computeNullable(typeContext), true);

    Link<NullAwareGuard> nullAwareGuards = operandResult.nullAwareGuards;
    Expression operand = operandResult.nullAwareAction;
    DartType operandType = operandResult.nullAwareActionType;

    node.operand = operand..parent = node;
    reportNonNullableInNullAwareWarningIfNeeded(
        operandType, "!", node.operand.fileOffset);
    flowAnalysis.nonNullAssert_end(node.operand);
    DartType nonNullableResultType = operandType.toNonNull();
    return createNullAwareExpressionInferenceResult(
        nonNullableResultType, node, nullAwareGuards);
  }

  ExpressionInferenceResult visitNullAwareMethodInvocation(
      NullAwareMethodInvocation node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferSyntheticVariableNullAware(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult invocationResult = inferExpression(
        node.invocation, typeContext, true,
        isVoidAllowed: true);
    return createNullAwareExpressionInferenceResult(
        invocationResult.inferredType,
        invocationResult.expression,
        nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwarePropertyGet(
      NullAwarePropertyGet node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferSyntheticVariableNullAware(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult readResult =
        inferExpression(node.read, typeContext, true);
    return createNullAwareExpressionInferenceResult(readResult.inferredType,
        readResult.expression, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwarePropertySet(
      NullAwarePropertySet node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferSyntheticVariableNullAware(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult writeResult =
        inferExpression(node.write, typeContext, true);
    return createNullAwareExpressionInferenceResult(writeResult.inferredType,
        writeResult.expression, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwareExtension(
      NullAwareExtension node, DartType typeContext) {
    inferSyntheticVariable(node.variable);
    reportNonNullableInNullAwareWarningIfNeeded(
        node.variable.type, "?.", node.variable.fileOffset);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult expressionResult =
        inferExpression(node.expression, const UnknownType(), true);
    return createNullAwareExpressionInferenceResult(
        expressionResult.inferredType,
        expressionResult.expression,
        const Link<NullAwareGuard>().prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitStaticPostIncDec(
      StaticPostIncDec node, DartType typeContext) {
    inferSyntheticVariable(node.read);
    inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;

    Expression replacement =
        new Let(node.read, createLet(node.write, createVariableGet(node.read)))
          ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitSuperPostIncDec(
      SuperPostIncDec node, DartType typeContext) {
    inferSyntheticVariable(node.read);
    inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;

    Expression replacement =
        new Let(node.read, createLet(node.write, createVariableGet(node.read)))
          ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitLocalPostIncDec(
      LocalPostIncDec node, DartType typeContext) {
    inferSyntheticVariable(node.read);
    inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;
    Expression replacement =
        new Let(node.read, createLet(node.write, createVariableGet(node.read)))
          ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitPropertyPostIncDec(
      PropertyPostIncDec node, DartType typeContext) {
    if (node.variable != null) {
      inferSyntheticVariable(node.variable!);
    }
    inferSyntheticVariable(node.read);
    inferSyntheticVariable(node.write);
    DartType inferredType = node.read.type;

    Expression replacement;
    if (node.variable != null) {
      replacement = new Let(
          node.variable!,
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
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      instrumentation?.record(
          uriForInstrumentation,
          receiverVariable.fileOffset,
          'type',
          new InstrumentationValueForType(receiverType));
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
            readReceiver, receiverType, node.propertyName, const UnknownType(),
            isThisReceiver: node.receiver is ThisExpression)
        .expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    ObjectAccessTarget writeTarget = findInterfaceMember(
        receiverType, node.propertyName, node.writeOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        instrumented: true,
        includeExtensionMethods: true);
    DartType writeType = getSetterType(writeTarget, receiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        writeType,
        read,
        readType,
        node.binaryName,
        node.rhs,
        null);

    binaryResult = ensureAssignableResult(writeType, binaryResult);
    DartType binaryType = binaryResult.inferredType;
    Expression binary = binaryResult.expression;

    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        receiverType, node.propertyName, writeTarget, binary,
        valueType: binaryType, forEffect: node.forEffect);

    Expression replacement = write;
    if (receiverVariable != null) {
      replacement = createLet(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return createNullAwareExpressionInferenceResult(
        binaryType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIfNullPropertySet(
      IfNullPropertySet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);
    instrumentation?.record(uriForInstrumentation, receiverVariable.fileOffset,
        'type', new InstrumentationValueForType(receiverType));
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
            readReceiver, receiverType, node.propertyName, const UnknownType(),
            isThisReceiver: node.receiver is ThisExpression)
        .expressionInferenceResult;

    reportNonNullableInNullAwareWarningIfNeeded(
        readResult.inferredType, "??=", node.readOffset);
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    ObjectAccessTarget writeTarget = findInterfaceMember(
        receiverType, node.propertyName, receiver.fileOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        instrumented: true,
        includeExtensionMethods: true);
    DartType writeContext = getSetterType(writeTarget, receiverType);

    flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.rhs, writeContext, true, isVoidAllowed: true);
    flowAnalysis.ifNullExpression_end();

    rhsResult = ensureAssignableResult(writeContext, rhsResult);
    Expression rhs = rhsResult.expression;

    DartType writeType = rhsResult.inferredType;
    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        receiverType, node.propertyName, writeTarget, rhs,
        forEffect: node.forEffect, valueType: writeType);

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableReadType, writeType, libraryBuilder.library);

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.a = b : null
      //
      Expression equalsNull = createEqualsNull(node.fileOffset, read);
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
      Expression equalsNull =
          createEqualsNull(node.fileOffset, createVariableGet(readVariable));
      VariableGet variableGet = createVariableGet(readVariable);
      if (libraryBuilder.isNonNullableByDefault &&
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

    return createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIfNullSet(
      IfNullSet node, DartType typeContext) {
    ExpressionInferenceResult readResult =
        inferNullAwareExpression(node.read, const UnknownType(), true);
    reportNonNullableInNullAwareWarningIfNeeded(
        readResult.inferredType, "??=", node.read.fileOffset);

    Link<NullAwareGuard> nullAwareGuards = readResult.nullAwareGuards;
    Expression read = readResult.nullAwareAction;
    DartType readType = readResult.nullAwareActionType;

    flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult writeResult =
        inferExpression(node.write, typeContext, true, isVoidAllowed: true);
    flowAnalysis.ifNullExpression_end();

    DartType originalReadType = readType;
    DartType nonNullableReadType = originalReadType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableReadType, writeResult.inferredType, libraryBuilder.library);

    Expression replacement;
    if (node.forEffect) {
      // Encode `a ??= b` as:
      //
      //     a == null ? a = b : null
      //
      Expression equalsNull = createEqualsNull(node.fileOffset, read);
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
      Expression equalsNull =
          createEqualsNull(node.fileOffset, createVariableGet(readVariable));
      VariableGet variableGet = createVariableGet(readVariable);
      if (libraryBuilder.isNonNullableByDefault &&
          !identical(nonNullableReadType, originalReadType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression conditional = new ConditionalExpression(
          equalsNull, writeResult.expression, variableGet, inferredType)
        ..fileOffset = node.fileOffset;
      replacement = new Let(readVariable, conditional)
        ..fileOffset = node.fileOffset;
    }
    return createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIndexGet(IndexGet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
        receiverType, indexGetName, node.fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    DartType indexType = getIndexKeyType(indexGetTarget, receiverType);

    MethodContravarianceCheckKind readCheckKind =
        preCheckInvocationContravariance(receiverType, indexGetTarget,
            isThisReceiver: node.receiver is ThisExpression);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    ExpressionInferenceResult replacement = _computeIndexGet(
        node.fileOffset,
        receiver,
        receiverType,
        indexGetTarget,
        index,
        indexType,
        readCheckKind);
    return createNullAwareExpressionInferenceResult(
        replacement.inferredType, replacement.expression, nullAwareGuards);
  }

  ExpressionInferenceResult visitIndexSet(IndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration? receiverVariable;
    if (!node.forEffect && !isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget indexSetTarget = findInterfaceMember(
        receiverType, indexSetName, node.fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    DartType indexType = getIndexKeyType(indexSetTarget, receiverType);
    DartType valueType = getIndexSetValueType(indexSetTarget, receiverType);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    VariableDeclaration? indexVariable;
    if (!node.forEffect && !isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    VariableDeclaration? valueVariable;
    Expression? returnedValue;
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
      replacement = createLet(assignmentVariable, returnedValue!);
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
    return createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitSuperIndexSet(
      SuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget indexSetTarget = new ObjectAccessTarget.interfaceMember(
        node.setter,
        isPotentiallyNullable: false);

    DartType indexType = getIndexKeyType(indexSetTarget, thisType!);
    DartType valueType = getIndexSetValueType(indexSetTarget, thisType!);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    VariableDeclaration? indexVariable;
    if (!isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    VariableDeclaration? valueVariable;
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

    assert(indexSetTarget.isInstanceMember || indexSetTarget.isObjectMember,
        'Unexpected index set target $indexSetTarget.');
    instrumentation?.record(uriForInstrumentation, node.fileOffset, 'target',
        new InstrumentationValueForMember(node.setter));
    Expression assignment = new SuperMethodInvocation(
        indexSetName,
        new Arguments(<Expression>[index, value])..fileOffset = node.fileOffset,
        indexSetTarget.member as Procedure)
      ..fileOffset = node.fileOffset;

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
    ExpressionInferenceResult receiverResult = inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension,
        node.explicitTypeArguments,
        receiverResult.inferredType);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    VariableDeclaration? receiverVariable;
    if (!isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget target = new ExtensionAccessTarget(
        node.setter, null, ProcedureKind.Operator, extensionTypeArguments);

    DartType indexType = getIndexKeyType(target, receiverType);
    DartType valueType = getIndexSetValueType(target, receiverType);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, true, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    VariableDeclaration? valueVariable;
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
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration? receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (isPureExpression(readReceiver)) {
      writeReceiver = clonePureExpression(readReceiver);
    } else {
      receiverVariable = createVariable(readReceiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = findInterfaceMember(
        receiverType, indexGetName, node.readOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    MethodContravarianceCheckKind checkKind = preCheckInvocationContravariance(
        receiverType, readTarget,
        isThisReceiver: node.receiver is ThisExpression);

    DartType readIndexType = getIndexKeyType(readTarget, receiverType);

    ObjectAccessTarget writeTarget = findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    DartType writeIndexType = getIndexKeyType(writeTarget, receiverType);
    DartType valueType = getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration? indexVariable;
    Expression readIndex = indexResult.expression;
    Map<DartType, NonPromotionReason> Function() whyNotPromotedIndex =
        flowAnalysis.whyNotPromoted(readIndex);
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex,
        whyNotPromoted: whyNotPromotedIndex);

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
    flowAnalysis.ifNullExpression_rightBegin(read, readType);

    writeIndex = ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex,
        whyNotPromoted: whyNotPromotedIndex);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableReadType, valueResult.inferredType, libraryBuilder.library);

    VariableDeclaration? valueVariable;
    Expression? returnedValue;
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
      Expression equalsNull = createEqualsNull(node.testOffset, read);
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
      Expression equalsNull =
          createEqualsNull(node.testOffset, createVariableGet(readVariable));
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet variableGet = createVariableGet(readVariable);
      if (libraryBuilder.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue!);
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
    return createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitIfNullSuperIndexSet(
      IfNullSuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget readTarget = node.getter != null
        ? new ObjectAccessTarget.interfaceMember(node.getter!,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType readType = getReturnType(readTarget, thisType!);
    reportNonNullableInNullAwareWarningIfNeeded(
        readType, "??=", node.readOffset);
    DartType readIndexType = getIndexKeyType(readTarget, thisType!);

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ObjectAccessTarget.interfaceMember(node.setter!,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = getIndexKeyType(writeTarget, thisType!);
    DartType valueType = getIndexSetValueType(writeTarget, thisType!);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex =
        ensureAssignable(readIndexType, indexResult.inferredType, readIndex);

    writeIndex =
        ensureAssignable(writeIndexType, indexResult.inferredType, writeIndex);

    assert(readTarget.isInstanceMember || readTarget.isObjectMember);
    instrumentation?.record(uriForInstrumentation, node.readOffset, 'target',
        new InstrumentationValueForMember(node.getter!));
    Expression read = new SuperMethodInvocation(
        indexGetName,
        new Arguments(<Expression>[
          readIndex,
        ])
          ..fileOffset = node.readOffset,
        readTarget.member as Procedure)
      ..fileOffset = node.readOffset;

    flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableReadType, valueResult.inferredType, libraryBuilder.library);

    VariableDeclaration? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
      // No need for a value variable.
    } else if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
    }

    assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
    instrumentation?.record(uriForInstrumentation, node.writeOffset, 'target',
        new InstrumentationValueForMember(node.setter!));
    Expression write = new SuperMethodInvocation(
        indexSetName,
        new Arguments(<Expression>[writeIndex, value])
          ..fileOffset = node.writeOffset,
        writeTarget.member as Procedure)
      ..fileOffset = node.writeOffset;

    Expression replacement;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = a in
      //        super[v1] == null ? super.[]=(v1, b) : null
      //
      assert(valueVariable == null);
      Expression equalsNull = createEqualsNull(node.testOffset, read);
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
      Expression equalsNull =
          createEqualsNull(node.testOffset, createVariableGet(readVariable));
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (libraryBuilder.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue!);
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
    ExpressionInferenceResult receiverResult = inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension,
        node.explicitTypeArguments,
        receiverResult.inferredType);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    VariableDeclaration? receiverVariable;
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
            node.getter!, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType readIndexType = getIndexKeyType(readTarget, receiverType);

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ExtensionAccessTarget(
            node.setter!, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = getIndexKeyType(writeTarget, receiverType);
    DartType valueType = getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex =
        ensureAssignable(readIndexType, indexResult.inferredType, readIndex);

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
    flowAnalysis.ifNullExpression_rightBegin(read, readType);

    writeIndex =
        ensureAssignable(writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableReadType, valueResult.inferredType, libraryBuilder.library);

    VariableDeclaration? valueVariable;
    Expression? returnedValue;
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
      Expression equalsNull = createEqualsNull(node.testOffset, read);
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
      Expression equalsNull =
          createEqualsNull(node.testOffset, createVariableGet(readVariable));
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (libraryBuilder.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue!);
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
      {required bool isNot}) {
    // ignore: unnecessary_null_comparison
    assert(isNot != null);
    EqualityInfo<VariableDeclaration, DartType>? equalityInfo =
        flowAnalysis.equalityOperand_end(left, leftType);
    bool typeNeeded = !isTopLevel;

    Expression? equals;
    ExpressionInferenceResult rightResult = inferExpression(
        right, const UnknownType(), typeNeeded,
        isVoidAllowed: false);

    if (_isNull(right)) {
      equals = new EqualsNull(left)..fileOffset = fileOffset;
    } else if (_isNull(left)) {
      equals = new EqualsNull(rightResult.expression)..fileOffset = fileOffset;
    }
    if (equals != null) {
      if (isNot) {
        equals = new Not(equals)..fileOffset = fileOffset;
      }
      flowAnalysis.equalityOperation_end(
          equals,
          equalityInfo,
          flowAnalysis.equalityOperand_end(
              rightResult.expression, rightResult.inferredType),
          notEqual: isNot);
      return new ExpressionInferenceResult(
          coreTypes.boolRawType(libraryBuilder.nonNullable), equals);
    }

    ObjectAccessTarget equalsTarget = findInterfaceMember(
        leftType, equalsName, fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    assert(
        equalsTarget.isInstanceMember ||
            equalsTarget.isObjectMember ||
            equalsTarget.isNever,
        "Unexpected equals target $equalsTarget for "
        "$left ($leftType) == $right.");
    if (instrumentation != null && leftType == const DynamicType()) {
      instrumentation!.record(uriForInstrumentation, fileOffset, 'target',
          new InstrumentationValueForMember(equalsTarget.member!));
    }
    DartType rightType =
        getPositionalParameterTypeForTarget(equalsTarget, leftType, 0);
    rightResult = ensureAssignableResult(
        rightType.withDeclaredNullability(libraryBuilder.nullable), rightResult,
        errorTemplate: templateArgumentTypeNotAssignable,
        nullabilityErrorTemplate: templateArgumentTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateArgumentTypeNotAssignablePartNullability,
        nullabilityNullErrorTemplate:
            templateArgumentTypeNotAssignableNullabilityNull,
        nullabilityNullTypeErrorTemplate:
            templateArgumentTypeNotAssignableNullabilityNullType);
    right = rightResult.expression;

    if (equalsTarget.isInstanceMember || equalsTarget.isObjectMember) {
      FunctionType functionType = getFunctionType(equalsTarget, leftType);
      equals = new EqualsCall(left, right,
          functionType: functionType,
          interfaceTarget: equalsTarget.member as Procedure)
        ..fileOffset = fileOffset;
      if (isNot) {
        equals = new Not(equals)..fileOffset = fileOffset;
      }
    } else {
      assert(equalsTarget.isNever);
      FunctionType functionType = new FunctionType([const DynamicType()],
          const NeverType.nonNullable(), libraryBuilder.nonNullable);
      // Ensure operator == member even for `Never`.
      Member target = findInterfaceMember(const DynamicType(), equalsName, -1,
              instrumented: false,
              callSiteAccessKind: CallSiteAccessKind.operatorInvocation)
          .member!;
      equals = new EqualsCall(left, right,
          functionType: functionType, interfaceTarget: target as Procedure)
        ..fileOffset = fileOffset;
      if (isNot) {
        equals = new Not(equals)..fileOffset = fileOffset;
      }
    }

    flowAnalysis.equalityOperation_end(equals, equalityInfo,
        flowAnalysis.equalityOperand_end(right, rightResult.inferredType),
        notEqual: isNot);
    return new ExpressionInferenceResult(
        equalsTarget.isNever
            ? const NeverType.nonNullable()
            : coreTypes.boolRawType(libraryBuilder.nonNullable),
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
      Expression right,
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted) {
    assert(binaryName != equalsName);

    ObjectAccessTarget binaryTarget = findInterfaceMember(
        leftType, binaryName, fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    MethodContravarianceCheckKind binaryCheckKind =
        preCheckInvocationContravariance(leftType, binaryTarget,
            isThisReceiver: false);

    DartType binaryType = getReturnType(binaryTarget, leftType);
    DartType rightType =
        getPositionalParameterTypeForTarget(binaryTarget, leftType, 0);

    bool isSpecialCasedBinaryOperator =
        isSpecialCasedBinaryOperatorForReceiverType(binaryTarget, leftType);

    bool typeNeeded = !isTopLevel || isSpecialCasedBinaryOperator;

    DartType rightContextType = rightType;
    if (isSpecialCasedBinaryOperator) {
      rightContextType =
          typeSchemaEnvironment.getContextTypeOfSpecialCasedBinaryOperator(
              contextType, leftType, rightType,
              isNonNullableByDefault: isNonNullableByDefault);
    }

    ExpressionInferenceResult rightResult = inferExpression(
        right, rightContextType, typeNeeded,
        isVoidAllowed: true);
    if (identical(rightResult.inferredType, noInferredType)) {
      assert(!typeNeeded,
          "Missing right type for overloaded arithmetic operator.");
      return new ExpressionInferenceResult(binaryType,
          engine.forest.createBinary(fileOffset, left, binaryName, right));
    }

    rightResult = ensureAssignableResult(rightType, rightResult);
    right = rightResult.expression;

    if (isSpecialCasedBinaryOperator) {
      binaryType = typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
          leftType, rightResult.inferredType,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    if (!isNonNullableByDefault) {
      binaryType = legacyErasure(binaryType);
    }

    Expression binary;
    switch (binaryTarget.kind) {
      case ObjectAccessTargetKind.missing:
        binary =
            createMissingBinary(fileOffset, left, leftType, binaryName, right);
        break;
      case ObjectAccessTargetKind.ambiguous:
        binary = createMissingBinary(
            fileOffset, left, leftType, binaryName, right,
            extensionAccessCandidates: binaryTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        assert(binaryTarget.extensionMethodKind != ProcedureKind.Setter);
        binary = new StaticInvocation(
            binaryTarget.member as Procedure,
            new Arguments(<Expression>[
              left,
              right,
            ], types: binaryTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        binary = new DynamicInvocation(
            DynamicAccessKind.Invalid,
            left,
            binaryName,
            new Arguments(<Expression>[
              right,
            ])
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        binary = new DynamicInvocation(
            DynamicAccessKind.Dynamic,
            left,
            binaryName,
            new Arguments(<Expression>[
              right,
            ])
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        binary = new DynamicInvocation(
            DynamicAccessKind.Never,
            left,
            binaryName,
            new Arguments(<Expression>[
              right,
            ])
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if ((binaryTarget.isInstanceMember || binaryTarget.isObjectMember) &&
            instrumentation != null &&
            leftType == const DynamicType()) {
          instrumentation!.record(uriForInstrumentation, fileOffset, 'target',
              new InstrumentationValueForMember(binaryTarget.member!));
        }

        binary = new InstanceInvocation(
            InstanceAccessKind.Instance,
            left,
            binaryName,
            new Arguments(<Expression>[
              right,
            ])
              ..fileOffset = fileOffset,
            functionType: new FunctionType(
                [rightType], binaryType, libraryBuilder.nonNullable),
            interfaceTarget: binaryTarget.member as Procedure)
          ..fileOffset = fileOffset;

        if (binaryCheckKind ==
            MethodContravarianceCheckKind.checkMethodReturn) {
          if (instrumentation != null) {
            instrumentation!.record(uriForInstrumentation, fileOffset,
                'checkReturn', new InstrumentationValueForType(binaryType));
          }
          binary = new AsExpression(binary, binaryType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        break;
    }

    if (!isTopLevel && binaryTarget.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
          whyNotPromoted?.call(),
          binary,
          (type) => !type.isPotentiallyNullable);
      return new ExpressionInferenceResult(
          binaryType,
          helper.wrapInProblem(
              binary,
              templateNullableOperatorCallError.withArguments(
                  binaryName.text, leftType, isNonNullableByDefault),
              binary.fileOffset,
              binaryName.text.length,
              context: context));
    }
    return new ExpressionInferenceResult(binaryType, binary);
  }

  /// Creates a unary expression of the unary operator with [unaryName] using
  /// [expression] as the operand.
  ///
  /// [fileOffset] is used as the file offset for created nodes.
  /// [expressionType] is the already inferred type of the [expression].
  ExpressionInferenceResult _computeUnaryExpression(
      int fileOffset,
      Expression expression,
      DartType expressionType,
      Name unaryName,
      Map<DartType, NonPromotionReason> Function() whyNotPromoted) {
    ObjectAccessTarget unaryTarget = findInterfaceMember(
        expressionType, unaryName, fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    MethodContravarianceCheckKind unaryCheckKind =
        preCheckInvocationContravariance(expressionType, unaryTarget,
            isThisReceiver: false);

    DartType unaryType = getReturnType(unaryTarget, expressionType);

    Expression unary;
    switch (unaryTarget.kind) {
      case ObjectAccessTargetKind.missing:
        unary = createMissingUnary(
            fileOffset, expression, expressionType, unaryName);
        break;
      case ObjectAccessTargetKind.ambiguous:
        unary = createMissingUnary(
            fileOffset, expression, expressionType, unaryName,
            extensionAccessCandidates: unaryTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        assert(unaryTarget.extensionMethodKind != ProcedureKind.Setter);
        unary = new StaticInvocation(
            unaryTarget.member as Procedure,
            new Arguments(<Expression>[
              expression,
            ], types: unaryTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        unary = new DynamicInvocation(DynamicAccessKind.Invalid, expression,
            unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        unary = new DynamicInvocation(DynamicAccessKind.Never, expression,
            unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        unary = new DynamicInvocation(DynamicAccessKind.Dynamic, expression,
            unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        if ((unaryTarget.isInstanceMember || unaryTarget.isObjectMember) &&
            instrumentation != null &&
            expressionType == const DynamicType()) {
          instrumentation!.record(uriForInstrumentation, fileOffset, 'target',
              new InstrumentationValueForMember(unaryTarget.member!));
        }

        unary = new InstanceInvocation(InstanceAccessKind.Instance, expression,
            unaryName, new Arguments(<Expression>[])..fileOffset = fileOffset,
            functionType: new FunctionType(
                <DartType>[], unaryType, libraryBuilder.nonNullable),
            interfaceTarget: unaryTarget.member as Procedure)
          ..fileOffset = fileOffset;

        if (unaryCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
          if (instrumentation != null) {
            instrumentation!.record(uriForInstrumentation, fileOffset,
                'checkReturn', new InstrumentationValueForType(expressionType));
          }
          unary = new AsExpression(unary, unaryType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        break;
    }

    if (!isNonNullableByDefault) {
      unaryType = legacyErasure(unaryType);
    }

    if (!isTopLevel && unaryTarget.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
          whyNotPromoted(), unary, (type) => !type.isPotentiallyNullable);
      // TODO(johnniwinther): Special case 'unary-' in messages. It should
      // probably be referred to as "Unary operator '-' ...".
      return new ExpressionInferenceResult(
          unaryType,
          helper.wrapInProblem(
              unary,
              templateNullableOperatorCallError.withArguments(
                  unaryName.text, expressionType, isNonNullableByDefault),
              unary.fileOffset,
              unaryName == unaryMinusName ? 1 : unaryName.text.length,
              context: context));
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
    DartType readType = getReturnType(readTarget, receiverType);
    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = createMissingIndexGet(
            fileOffset, readReceiver, receiverType, readIndex);
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = createMissingIndexGet(
            fileOffset, readReceiver, receiverType, readIndex,
            extensionAccessCandidates: readTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        read = new StaticInvocation(
            readTarget.member as Procedure,
            new Arguments(<Expression>[
              readReceiver,
              readIndex,
            ], types: readTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        read = new DynamicInvocation(
            DynamicAccessKind.Invalid,
            readReceiver,
            indexGetName,
            new Arguments(<Expression>[
              readIndex,
            ])
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        read = new DynamicInvocation(
            DynamicAccessKind.Never,
            readReceiver,
            indexGetName,
            new Arguments(<Expression>[
              readIndex,
            ])
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        read = new DynamicInvocation(
            DynamicAccessKind.Dynamic,
            readReceiver,
            indexGetName,
            new Arguments(<Expression>[
              readIndex,
            ])
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
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
                [indexType], readType, libraryBuilder.nonNullable),
            interfaceTarget: readTarget.member as Procedure)
          ..fileOffset = fileOffset;
        if (readCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
          if (instrumentation != null) {
            instrumentation!.record(uriForInstrumentation, fileOffset,
                'checkReturn', new InstrumentationValueForType(readType));
          }
          read = new AsExpression(read, readType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        break;
    }

    if (!isNonNullableByDefault) {
      readType = legacyErasure(readType);
    }

    if (!isTopLevel && readTarget.isNullable) {
      return new ExpressionInferenceResult(
          readType,
          helper.wrapInProblem(
              read,
              templateNullableOperatorCallError.withArguments(
                  indexGetName.text, receiverType, isNonNullableByDefault),
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
        write = createMissingIndexSet(
            fileOffset, receiver, receiverType, index, value,
            forEffect: true);
        break;
      case ObjectAccessTargetKind.ambiguous:
        write = createMissingIndexSet(
            fileOffset, receiver, receiverType, index, value,
            forEffect: true, extensionAccessCandidates: writeTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        assert(writeTarget.extensionMethodKind != ProcedureKind.Setter);
        write = new StaticInvocation(
            writeTarget.member as Procedure,
            new Arguments(<Expression>[receiver, index, value],
                types: writeTarget.inferredExtensionTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        write = new DynamicInvocation(
            DynamicAccessKind.Invalid,
            receiver,
            indexSetName,
            new Arguments(<Expression>[index, value])..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        write = new DynamicInvocation(
            DynamicAccessKind.Never,
            receiver,
            indexSetName,
            new Arguments(<Expression>[index, value])..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        write = new DynamicInvocation(
            DynamicAccessKind.Dynamic,
            receiver,
            indexSetName,
            new Arguments(<Expression>[index, value])..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
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
        write = new InstanceInvocation(kind, receiver, indexSetName,
            new Arguments(<Expression>[index, value])..fileOffset = fileOffset,
            functionType: new FunctionType([indexType, valueType],
                const VoidType(), libraryBuilder.nonNullable),
            interfaceTarget: writeTarget.member as Procedure)
          ..fileOffset = fileOffset;
        break;
    }
    if (!isTopLevel && writeTarget.isNullable) {
      return helper.wrapInProblem(
          write,
          templateNullableOperatorCallError.withArguments(
              indexSetName.text, receiverType, isNonNullableByDefault),
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
  PropertyGetInferenceResult _computePropertyGet(
      int fileOffset,
      Expression receiver,
      DartType receiverType,
      Name propertyName,
      DartType typeContext,
      {required bool isThisReceiver,
      ObjectAccessTarget? readTarget}) {
    // ignore: unnecessary_null_comparison
    assert(isThisReceiver != null);

    readTarget ??= findInterfaceMember(receiverType, propertyName, fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.getterInvocation);

    DartType readType = getGetterType(readTarget, receiverType);

    Expression read;
    ExpressionInferenceResult? readResult;
    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = createMissingPropertyGet(
            fileOffset, receiver, receiverType, propertyName);
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = createMissingPropertyGet(
            fileOffset, receiver, receiverType, propertyName,
            extensionAccessCandidates: readTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (readTarget.extensionMethodKind) {
          case ProcedureKind.Getter:
            read = new StaticInvocation(
                readTarget.member as Procedure,
                new Arguments(<Expression>[
                  receiver,
                ], types: readTarget.inferredExtensionTypeArguments)
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset;
            break;
          case ProcedureKind.Method:
            read = new StaticInvocation(
                readTarget.tearoffTarget as Procedure,
                new Arguments(<Expression>[
                  receiver,
                ], types: readTarget.inferredExtensionTypeArguments)
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset;
            readResult = instantiateTearOff(readType, typeContext, read);
            break;
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
          case ProcedureKind.Operator:
            unhandled('$readTarget', "inferPropertyGet", -1, null);
        }
        break;
      case ObjectAccessTargetKind.never:
        read = new DynamicGet(DynamicAccessKind.Never, receiver, propertyName)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.dynamic:
        read = new DynamicGet(DynamicAccessKind.Dynamic, receiver, propertyName)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        read = new DynamicGet(DynamicAccessKind.Invalid, receiver, propertyName)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        read = new FunctionTearOff(receiver)..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        Member member = readTarget.member!;
        if ((readTarget.isInstanceMember || readTarget.isObjectMember) &&
            instrumentation != null &&
            receiverType == const DynamicType()) {
          instrumentation!.record(uriForInstrumentation, fileOffset, 'target',
              new InstrumentationValueForMember(member));
        }

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
              interfaceTarget: member, resultType: readType)
            ..fileOffset = fileOffset;
        } else {
          read = new InstanceGet(kind, receiver, propertyName,
              interfaceTarget: member, resultType: readType)
            ..fileOffset = fileOffset;
        }
        bool checkReturn = false;
        if ((readTarget.isInstanceMember || readTarget.isObjectMember) &&
            !isThisReceiver) {
          Member interfaceMember = readTarget.member!;
          if (interfaceMember is Procedure) {
            DartType typeToCheck = isNonNullableByDefault
                ? interfaceMember.function
                    .computeFunctionType(libraryBuilder.nonNullable)
                : interfaceMember.function.returnType;
            checkReturn =
                InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                    interfaceMember.enclosingClass!, typeToCheck);
          } else if (interfaceMember is Field) {
            checkReturn =
                InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                    interfaceMember.enclosingClass!, interfaceMember.type);
          }
        }
        if (checkReturn) {
          if (instrumentation != null) {
            instrumentation!.record(uriForInstrumentation, fileOffset,
                'checkReturn', new InstrumentationValueForType(readType));
          }
          read = new AsExpression(read, readType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..isForNonNullableByDefault = isNonNullableByDefault
            ..fileOffset = fileOffset;
        }
        if (member is Procedure && member.kind == ProcedureKind.Method) {
          readResult = instantiateTearOff(readType, typeContext, read);
        }
        break;
    }

    if (!isNonNullableByDefault) {
      readType = legacyErasure(readType);
    }

    readResult ??= new ExpressionInferenceResult(readType, read);
    if (!isTopLevel && readTarget.isNullable) {
      readResult = wrapExpressionInferenceResultInProblem(
          readResult,
          templateNullablePropertyAccessError.withArguments(
              propertyName.text, receiverType, isNonNullableByDefault),
          read.fileOffset,
          propertyName.text.length,
          context: getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(receiver)(),
              read,
              (type) => !type.isPotentiallyNullable));
    }
    return new PropertyGetInferenceResult(readResult, readTarget.member);
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
      {DartType? valueType,
      required bool forEffect}) {
    // ignore: unnecessary_null_comparison
    assert(forEffect != null);
    assert(forEffect || valueType != null,
        "No value type provided for property set needed for value.");
    Expression write;
    switch (writeTarget.kind) {
      case ObjectAccessTargetKind.missing:
        write = createMissingPropertySet(
            fileOffset, receiver, receiverType, propertyName, value,
            forEffect: forEffect);
        break;
      case ObjectAccessTargetKind.ambiguous:
        write = createMissingPropertySet(
            fileOffset, receiver, receiverType, propertyName, value,
            forEffect: forEffect,
            extensionAccessCandidates: writeTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        if (forEffect) {
          write = new StaticInvocation(
              writeTarget.member as Procedure,
              new Arguments(<Expression>[receiver, value],
                  types: writeTarget.inferredExtensionTypeArguments)
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
        } else {
          VariableDeclaration valueVariable = createVariable(value, valueType!);
          VariableDeclaration assignmentVariable = createVariable(
              new StaticInvocation(
                  writeTarget.member as Procedure,
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
        write = new DynamicSet(
            DynamicAccessKind.Invalid, receiver, propertyName, value)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        write = new DynamicSet(
            DynamicAccessKind.Never, receiver, propertyName, value)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        write = new DynamicSet(
            DynamicAccessKind.Dynamic, receiver, propertyName, value)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
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
            interfaceTarget: writeTarget.member!)
          ..fileOffset = fileOffset;
        break;
    }
    if (!isTopLevel && writeTarget.isNullable) {
      return helper.wrapInProblem(
          write,
          templateNullablePropertyAccessError.withArguments(
              propertyName.text, receiverType, isNonNullableByDefault),
          write.fileOffset,
          propertyName.text.length);
    }

    return write;
  }

  ExpressionInferenceResult visitCompoundIndexSet(
      CompoundIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration? receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (isPureExpression(readReceiver)) {
      writeReceiver = clonePureExpression(readReceiver);
    } else {
      receiverVariable = createVariable(readReceiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = findInterfaceMember(
        receiverType, indexGetName, node.readOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    MethodContravarianceCheckKind readCheckKind =
        preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readIndexType = getIndexKeyType(readTarget, receiverType);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration? indexVariable;
    Expression readIndex = indexResult.expression;
    Map<DartType, NonPromotionReason> Function() whyNotPromotedIndex =
        flowAnalysis.whyNotPromoted(readIndex);
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
        readIndexType, indexResult.inferredType, readIndex,
        whyNotPromoted: whyNotPromotedIndex);

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

    VariableDeclaration? leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
    } else {
      left = read;
    }

    ObjectAccessTarget writeTarget = findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

    DartType writeIndexType = getIndexKeyType(writeTarget, receiverType);

    DartType valueType = getIndexSetValueType(writeTarget, receiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs,
        null);

    writeIndex = ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex,
        whyNotPromoted: whyNotPromotedIndex);

    binaryResult = ensureAssignableResult(valueType, binaryResult,
        fileOffset: node.fileOffset);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    VariableDeclaration? valueVariable;
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
      inner = createLet(leftVariable!,
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
      inner = createLet(valueVariable!,
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
    return createNullAwareExpressionInferenceResult(
        node.forPostIncDec ? readType : binaryType,
        replacement,
        nullAwareGuards);
  }

  ExpressionInferenceResult visitNullAwareCompoundSet(
      NullAwareCompoundSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: true);
    reportNonNullableInNullAwareWarningIfNeeded(
        receiverResult.inferredType, "?.", node.receiver.fileOffset);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration? receiverVariable =
        createVariable(receiver, receiverType);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(receiverVariable);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);
    DartType nonNullReceiverType = receiverType.toNonNull();

    ExpressionInferenceResult readResult = _computePropertyGet(
            node.readOffset,
            readReceiver,
            nonNullReceiverType,
            node.propertyName,
            const UnknownType(),
            isThisReceiver: node.receiver is ThisExpression)
        .expressionInferenceResult;
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    VariableDeclaration? leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
    } else {
      left = read;
    }

    ObjectAccessTarget writeTarget = findInterfaceMember(
        nonNullReceiverType, node.propertyName, node.writeOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        includeExtensionMethods: true);

    DartType valueType = getSetterType(writeTarget, nonNullReceiverType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs,
        null);

    binaryResult = ensureAssignableResult(valueType, binaryResult,
        fileOffset: node.fileOffset);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    VariableDeclaration? valueVariable;
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
      action = createLet(leftVariable!,
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
      action = createLet(valueVariable!,
          createLet(writeVariable, createVariableGet(valueVariable)));
    }

    return createNullAwareExpressionInferenceResult(
        resultType, action, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitCompoundSuperIndexSet(
      CompoundSuperIndexSet node, DartType typeContext) {
    ObjectAccessTarget readTarget = new ObjectAccessTarget.interfaceMember(
        node.getter,
        isPotentiallyNullable: false);

    DartType readType = getReturnType(readTarget, thisType!);
    DartType readIndexType = getIndexKeyType(readTarget, thisType!);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex =
        ensureAssignable(readIndexType, indexResult.inferredType, readIndex);

    assert(readTarget.isInstanceMember || readTarget.isObjectMember);
    instrumentation?.record(uriForInstrumentation, node.readOffset, 'target',
        new InstrumentationValueForMember(node.getter));
    Expression read = new SuperMethodInvocation(
        indexGetName,
        new Arguments(<Expression>[
          readIndex,
        ])
          ..fileOffset = node.readOffset,
        readTarget.member as Procedure)
      ..fileOffset = node.readOffset;

    VariableDeclaration? leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
    } else {
      left = read;
    }
    ObjectAccessTarget writeTarget = new ObjectAccessTarget.interfaceMember(
        node.setter,
        isPotentiallyNullable: false);

    DartType writeIndexType = getIndexKeyType(writeTarget, thisType!);

    DartType valueType = getIndexSetValueType(writeTarget, thisType!);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs,
        null);

    binaryResult = ensureAssignableResult(valueType, binaryResult,
        fileOffset: node.fileOffset);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    writeIndex =
        ensureAssignable(writeIndexType, indexResult.inferredType, writeIndex);

    VariableDeclaration? valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = createVariable(binary, binaryType);
      valueExpression = createVariableGet(valueVariable);
    }

    assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
    instrumentation?.record(uriForInstrumentation, node.writeOffset, 'target',
        new InstrumentationValueForMember(node.setter));
    Expression write = new SuperMethodInvocation(
        indexSetName,
        new Arguments(<Expression>[writeIndex, valueExpression])
          ..fileOffset = node.writeOffset,
        writeTarget.member as Procedure)
      ..fileOffset = node.writeOffset;

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
      replacement = createLet(leftVariable!,
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
      replacement = createLet(valueVariable!,
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
    ExpressionInferenceResult receiverResult = inferExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension,
        node.explicitTypeArguments,
        receiverResult.inferredType);

    ObjectAccessTarget readTarget = node.getter != null
        ? new ExtensionAccessTarget(
            node.getter!, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    VariableDeclaration? receiverVariable;
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

    DartType readIndexType = getIndexKeyType(readTarget, receiverType);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, true, isVoidAllowed: true);

    VariableDeclaration? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex =
        ensureAssignable(readIndexType, indexResult.inferredType, readIndex);

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

    VariableDeclaration? leftVariable;
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
            node.setter!, null, ProcedureKind.Operator, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = getIndexKeyType(writeTarget, receiverType);

    DartType valueType = getIndexSetValueType(writeTarget, thisType);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
        node.binaryOffset,
        valueType,
        left,
        readType,
        node.binaryName,
        node.rhs,
        null);

    writeIndex =
        ensureAssignable(writeIndexType, indexResult.inferredType, writeIndex);
    binaryResult = ensureAssignableResult(valueType, binaryResult,
        fileOffset: node.fileOffset);
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    VariableDeclaration? valueVariable;
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
      replacement = createLet(leftVariable!,
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
      replacement = createLet(valueVariable!,
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
    flowAnalysis.nullLiteral(node);
    return new ExpressionInferenceResult(const NullType(), node);
  }

  @override
  ExpressionInferenceResult visitLet(Let node, DartType typeContext) {
    DartType variableType = node.variable.type;
    ExpressionInferenceResult initializerResult = inferExpression(
        node.variable.initializer!, variableType, true,
        isVoidAllowed: true);
    node.variable.initializer = initializerResult.expression
      ..parent = node.variable;
    ExpressionInferenceResult bodyResult =
        inferExpression(node.body, typeContext, true, isVoidAllowed: true);
    node.body = bodyResult.expression..parent = node;
    DartType inferredType = bodyResult.inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitPropertySet(
      PropertySet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    ObjectAccessTarget target = findInterfaceMember(
        receiverType, node.name, node.fileOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        instrumented: true,
        includeExtensionMethods: true);
    if (target.isInstanceMember || target.isObjectMember) {
      if (instrumentation != null && receiverType == const DynamicType()) {
        instrumentation!.record(uriForInstrumentation, node.fileOffset,
            'target', new InstrumentationValueForMember(target.member!));
      }
    }
    DartType writeContext = getSetterType(target, receiverType);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, true, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    DartType rhsType = rhsResult.inferredType;

    Expression replacement = _computePropertySet(
        node.fileOffset, receiver, receiverType, node.name, target, rhs,
        valueType: rhsType, forEffect: node.forEffect);

    return createNullAwareExpressionInferenceResult(
        rhsType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitAugmentSuperSet(
      AugmentSuperSet node, DartType typeContext) {
    Member member = node.target;
    if (member.isInstanceMember) {
      Expression receiver = new ThisExpression()..fileOffset = node.fileOffset;
      DartType receiverType = thisType!;

      ObjectAccessTarget target = new ObjectAccessTarget.interfaceMember(member,
          isPotentiallyNullable: false);
      if (target.isInstanceMember || target.isObjectMember) {
        if (instrumentation != null && receiverType == const DynamicType()) {
          instrumentation!.record(uriForInstrumentation, node.fileOffset,
              'target', new InstrumentationValueForMember(target.member!));
        }
      }
      DartType writeContext = getSetterType(target, receiverType);
      ExpressionInferenceResult rhsResult =
          inferExpression(node.value, writeContext, true, isVoidAllowed: true);
      rhsResult = ensureAssignableResult(writeContext, rhsResult,
          fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
      Expression rhs = rhsResult.expression;
      DartType rhsType = rhsResult.inferredType;

      Expression replacement = _computePropertySet(
          node.fileOffset, receiver, receiverType, member.name, target, rhs,
          valueType: rhsType, forEffect: node.forEffect);

      return new ExpressionInferenceResult(rhsType, replacement);
    } else {
      // TODO(johnniwinther): Handle augmentation of field with inferred types.
      TypeInferenceEngine.resolveInferenceNode(member, classHierarchy);
      DartType writeContext = member.setterType;
      ExpressionInferenceResult rhsResult =
          inferExpression(node.value, writeContext, true, isVoidAllowed: true);
      rhsResult = ensureAssignableResult(writeContext, rhsResult,
          fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
      Expression rhs = rhsResult.expression;
      StaticSet result = new StaticSet(member, rhs)
        ..fileOffset = node.fileOffset;
      DartType rhsType = rhsResult.inferredType;
      return new ExpressionInferenceResult(rhsType, result);
    }
  }

  ExpressionInferenceResult visitNullAwareIfNullSet(
      NullAwareIfNullSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(), true,
        isVoidAllowed: false);
    reportNonNullableInNullAwareWarningIfNeeded(
        receiverResult.inferredType, "?.", node.receiver.fileOffset);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    VariableDeclaration receiverVariable =
        createVariable(receiver, receiverType);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(receiverVariable);
    Expression readReceiver = createVariableGet(receiverVariable);
    Expression writeReceiver = createVariableGet(receiverVariable);
    DartType nonNullReceiverType = receiverType.toNonNull();

    ExpressionInferenceResult readResult = _computePropertyGet(node.readOffset,
            readReceiver, nonNullReceiverType, node.name, typeContext,
            isThisReceiver: node.receiver is ThisExpression)
        .expressionInferenceResult;
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    flowAnalysis.ifNullExpression_rightBegin(read, readType);

    VariableDeclaration? readVariable;
    if (!node.forEffect) {
      readVariable = createVariable(read, readType);
      read = createVariableGet(readVariable);
    }

    ObjectAccessTarget writeTarget = findInterfaceMember(
        nonNullReceiverType, node.name, node.writeOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        includeExtensionMethods: true);

    DartType valueType = getSetterType(writeTarget, nonNullReceiverType);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, true, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    Expression write = _computePropertySet(node.writeOffset, writeReceiver,
        nonNullReceiverType, node.name, writeTarget, value,
        valueType: valueResult.inferredType, forEffect: node.forEffect);

    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = typeSchemaEnvironment.getStandardUpperBound(
        nonNullableReadType, valueResult.inferredType, libraryBuilder.library);

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

      Expression readEqualsNull = createEqualsNull(node.readOffset, read);
      replacement = new ConditionalExpression(readEqualsNull, write,
          new NullLiteral()..fileOffset = node.writeOffset, inferredType)
        ..fileOffset = node.writeOffset;
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

      Expression readEqualsNull =
          createEqualsNull(receiverVariable.fileOffset, read);
      VariableGet variableGet = createVariableGet(readVariable!);
      if (libraryBuilder.isNonNullableByDefault &&
          !identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression condition = new ConditionalExpression(
          readEqualsNull, write, variableGet, inferredType)
        ..fileOffset = receiverVariable.fileOffset;
      replacement = createLet(readVariable, condition);
    }

    return createNullAwareExpressionInferenceResult(
        inferredType, replacement, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitPropertyGet(
      PropertyGet node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferNullAwareExpression(node.receiver, const UnknownType(), true);

    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;

    node.receiver = receiver..parent = node;
    PropertyGetInferenceResult propertyGetInferenceResult = _computePropertyGet(
        node.fileOffset, receiver, receiverType, node.name, typeContext,
        isThisReceiver: node.receiver is ThisExpression);
    ExpressionInferenceResult readResult =
        propertyGetInferenceResult.expressionInferenceResult;
    flowAnalysis.propertyGet(node, node.receiver, node.name.text,
        propertyGetInferenceResult.member, readResult.inferredType);
    ExpressionInferenceResult expressionInferenceResult =
        createNullAwareExpressionInferenceResult(
            readResult.inferredType, readResult.expression, nullAwareGuards);
    flowAnalysis.forwardExpression(
        expressionInferenceResult.nullAwareAction, node);
    return expressionInferenceResult;
  }

  ExpressionInferenceResult visitAugmentSuperGet(
      AugmentSuperGet node, DartType typeContext) {
    Member member = node.target;
    if (member.isInstanceMember) {
      ObjectAccessTarget target = new ObjectAccessTarget.interfaceMember(member,
          isPotentiallyNullable: false);
      Expression receiver = new ThisExpression()..fileOffset = node.fileOffset;
      DartType receiverType = thisType!;

      PropertyGetInferenceResult propertyGetInferenceResult =
          _computePropertyGet(
              node.fileOffset, receiver, receiverType, member.name, typeContext,
              isThisReceiver: true, readTarget: target);
      ExpressionInferenceResult readResult =
          propertyGetInferenceResult.expressionInferenceResult;
      return new ExpressionInferenceResult(
          readResult.inferredType, readResult.expression);
    } else {
      // TODO(johnniwinther): Handle augmentation of field with inferred types.
      TypeInferenceEngine.resolveInferenceNode(member, classHierarchy);
      DartType type = member.getterType;

      if (member is Procedure && member.kind == ProcedureKind.Method) {
        Expression tearOff = new StaticTearOff(node.target as Procedure)
          ..fileOffset = node.fileOffset;
        return instantiateTearOff(type, typeContext, tearOff);
      } else {
        return new ExpressionInferenceResult(
            type, new StaticGet(member)..fileOffset = node.fileOffset);
      }
    }
  }

  @override
  InitializerInferenceResult visitRedirectingInitializer(
      RedirectingInitializer node) {
    inferConstructorParameterTypes(node.target);
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    List<DartType> typeArguments = new List<DartType>.generate(
        classTypeParameters.length,
        (int i) => new TypeParameterType.withDefaultNullabilityForLibrary(
            classTypeParameters[i], libraryBuilder.library),
        growable: false);
    ArgumentsImpl.setNonInferrableArgumentTypes(
        node.arguments as ArgumentsImpl, typeArguments);
    FunctionType functionType = replaceReturnType(
        node.target.function
            .computeThisFunctionType(libraryBuilder.nonNullable),
        coreTypes.thisInterfaceType(
            node.target.enclosingClass, libraryBuilder.nonNullable));
    InvocationInferenceResult inferenceResult = inferInvocation(
        this,
        const UnknownType(),
        node.fileOffset,
        functionType,
        node.arguments as ArgumentsImpl,
        skipTypeArgumentInference: true,
        staticTarget: node.target);
    ArgumentsImpl.removeNonInferrableArgumentTypes(
        node.arguments as ArgumentsImpl);
    return new InitializerInferenceResult.fromInvocationInferenceResult(
        inferenceResult);
  }

  @override
  ExpressionInferenceResult visitRethrow(Rethrow node, DartType typeContext) {
    flowAnalysis.handleExit();
    return new ExpressionInferenceResult(
        isNonNullableByDefault
            ? const NeverType.nonNullable()
            : const NeverType.legacy(),
        node);
  }

  @override
  StatementInferenceResult visitReturnStatement(
      covariant ReturnStatementImpl node) {
    DartType typeContext = closureContext.returnContext;
    DartType inferredType;
    if (node.expression != null) {
      ExpressionInferenceResult expressionResult = inferExpression(
          node.expression!, typeContext, true,
          isVoidAllowed: true);
      node.expression = expressionResult.expression..parent = node;
      inferredType = expressionResult.inferredType;
    } else {
      inferredType = const NullType();
    }
    closureContext.handleReturn(node, inferredType, node.isArrow);
    flowAnalysis.handleExit();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitSetLiteral(
      SetLiteral node, DartType typeContext) {
    Class setClass = coreTypes.setClass;
    InterfaceType setType =
        coreTypes.thisInterfaceType(setClass, libraryBuilder.nonNullable);
    List<DartType>? inferredTypes;
    DartType inferredTypeArgument;
    List<DartType>? formalTypes;
    List<DartType>? actualTypes;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    bool typeChecksNeeded = !isTopLevel;
    Map<TreeNode, DartType>? inferredSpreadTypes;
    Map<Expression, DartType>? inferredConditionTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
      inferredSpreadTypes = new Map<TreeNode, DartType>.identity();
      inferredConditionTypes = new Map<Expression, DartType>.identity();
    }
    TypeConstraintGatherer? gatherer;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
          setType, setClass.typeParameters, typeContext, libraryBuilder.library,
          isConst: node.isConst);
      inferredTypes = typeSchemaEnvironment.partialInfer(
          gatherer, setClass.typeParameters, null, libraryBuilder.library);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    if (inferenceNeeded || typeChecksNeeded) {
      for (int index = 0; index < node.expressions.length; ++index) {
        ExpressionInferenceResult result = inferElement(
            node.expressions[index],
            inferredTypeArgument,
            inferredSpreadTypes!,
            inferredConditionTypes!,
            inferenceNeeded,
            typeChecksNeeded);
        node.expressions[index] = result.expression..parent = node;
        actualTypes!.add(result.inferredType);
        if (inferenceNeeded) {
          formalTypes!.add(setType.typeArguments[0]);
        }
      }
    }
    if (inferenceNeeded) {
      gatherer!.constrainArguments(formalTypes!, actualTypes!);
      inferredTypes = typeSchemaEnvironment.upwardsInfer(gatherer,
          setClass.typeParameters, inferredTypes!, libraryBuilder.library);
      if (dataForTesting != null) {
        dataForTesting!.typeInferenceResult.inferredTypeArguments[node] =
            inferredTypes;
      }
      inferredTypeArgument = inferredTypes[0];
      instrumentation?.record(
          uriForInstrumentation,
          node.fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      node.typeArgument = inferredTypeArgument;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < node.expressions.length; i++) {
        checkElement(node.expressions[i], node, node.typeArgument,
            inferredSpreadTypes!, inferredConditionTypes!);
      }
    }
    DartType inferredType = new InterfaceType(
        setClass, libraryBuilder.nonNullable, [inferredTypeArgument]);
    if (!isTopLevel) {
      SourceLibraryBuilder library = libraryBuilder;
      if (inferenceNeeded) {
        if (!library.libraryFeatures.genericMetadata.isEnabled) {
          checkGenericFunctionTypeArgument(node.typeArgument, node.fileOffset);
        }
      }

      if (!library.loader.target.backendTarget.supportsSetLiterals) {
        helper.transformSetLiterals = true;
      }
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitStaticSet(
      StaticSet node, DartType typeContext) {
    Member writeMember = node.target;
    DartType writeContext = writeMember.setterType;
    TypeInferenceEngine.resolveInferenceNode(writeMember, classHierarchy);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, true, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    node.value = rhs..parent = node;
    DartType rhsType = rhsResult.inferredType;
    return new ExpressionInferenceResult(rhsType, node);
  }

  @override
  ExpressionInferenceResult visitStaticGet(
      StaticGet node, DartType typeContext) {
    Member target = node.target;
    TypeInferenceEngine.resolveInferenceNode(target, classHierarchy);
    DartType type = target.getterType;

    if (!isNonNullableByDefault) {
      type = legacyErasure(type);
    }

    if (target is Procedure && target.kind == ProcedureKind.Method) {
      Expression tearOff = new StaticTearOff(node.target as Procedure)
        ..fileOffset = node.fileOffset;
      return instantiateTearOff(type, typeContext, tearOff);
    } else {
      return new ExpressionInferenceResult(type, node);
    }
  }

  @override
  ExpressionInferenceResult visitStaticInvocation(
      StaticInvocation node, DartType typeContext) {
    // ignore: unnecessary_null_comparison
    FunctionType calleeType = node.target != null
        ? node.target.function.computeFunctionType(libraryBuilder.nonNullable)
        : new FunctionType([], const DynamicType(), libraryBuilder.nonNullable);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        staticTarget: node.target);
    // ignore: unnecessary_null_comparison
    if (!isTopLevel && node.target != null) {
      libraryBuilder.checkBoundsInStaticInvocation(
          node, typeSchemaEnvironment, helper.uri, typeArgumentsInfo);
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(node));
  }

  @override
  ExpressionInferenceResult visitStringConcatenation(
      StringConcatenation node, DartType typeContext) {
    if (!isTopLevel) {
      for (int index = 0; index < node.expressions.length; index++) {
        ExpressionInferenceResult result = inferExpression(
            node.expressions[index], const UnknownType(), !isTopLevel,
            isVoidAllowed: false);
        node.expressions[index] = result.expression..parent = node;
      }
    }
    return new ExpressionInferenceResult(
        coreTypes.stringRawType(libraryBuilder.nonNullable), node);
  }

  @override
  ExpressionInferenceResult visitStringLiteral(
      StringLiteral node, DartType typeContext) {
    return new ExpressionInferenceResult(
        coreTypes.stringRawType(libraryBuilder.nonNullable), node);
  }

  @override
  InitializerInferenceResult visitSuperInitializer(SuperInitializer node) {
    inferConstructorParameterTypes(node.target);
    Substitution substitution = Substitution.fromSupertype(
        classHierarchy.getClassAsInstanceOf(
            thisType!.classNode, node.target.enclosingClass)!);
    FunctionType functionType = replaceReturnType(
        substitution.substituteType(node.target.function
            .computeThisFunctionType(libraryBuilder.nonNullable)
            .withoutTypeParameters) as FunctionType,
        thisType!);
    InvocationInferenceResult inferenceResult = inferInvocation(
        this,
        const UnknownType(),
        node.fileOffset,
        functionType,
        node.arguments as ArgumentsImpl,
        skipTypeArgumentInference: true,
        staticTarget: node.target);
    return new InitializerInferenceResult.fromInvocationInferenceResult(
        inferenceResult);
  }

  @override
  ExpressionInferenceResult visitAbstractSuperMethodInvocation(
      AbstractSuperMethodInvocation node, DartType typeContext) {
    instrumentation?.record(uriForInstrumentation, node.fileOffset, 'target',
        new InstrumentationValueForMember(node.interfaceTarget));
    return inferSuperMethodInvocation(this, node, node.name,
        node.arguments as ArgumentsImpl, typeContext, node.interfaceTarget);
  }

  @override
  ExpressionInferenceResult visitSuperMethodInvocation(
      SuperMethodInvocation node, DartType typeContext) {
    instrumentation?.record(uriForInstrumentation, node.fileOffset, 'target',
        new InstrumentationValueForMember(node.interfaceTarget));
    return inferSuperMethodInvocation(this, node, node.name,
        node.arguments as ArgumentsImpl, typeContext, node.interfaceTarget);
  }

  @override
  ExpressionInferenceResult visitAbstractSuperPropertyGet(
      AbstractSuperPropertyGet node, DartType typeContext) {
    instrumentation?.record(uriForInstrumentation, node.fileOffset, 'target',
        new InstrumentationValueForMember(node.interfaceTarget));
    return inferSuperPropertyGet(
        node, node.name, typeContext, node.interfaceTarget);
  }

  @override
  ExpressionInferenceResult visitSuperPropertyGet(
      SuperPropertyGet node, DartType typeContext) {
    instrumentation?.record(uriForInstrumentation, node.fileOffset, 'target',
        new InstrumentationValueForMember(node.interfaceTarget));
    return inferSuperPropertyGet(
        node, node.name, typeContext, node.interfaceTarget);
  }

  @override
  ExpressionInferenceResult visitAbstractSuperPropertySet(
      AbstractSuperPropertySet node, DartType typeContext) {
    DartType receiverType = classHierarchy.getTypeAsInstanceOf(thisType!,
        thisType!.classNode.supertype!.classNode, libraryBuilder.library)!;

    ObjectAccessTarget writeTarget = new ObjectAccessTarget.interfaceMember(
        node.interfaceTarget,
        isPotentiallyNullable: false);
    DartType writeContext = getSetterType(writeTarget, receiverType);
    writeContext = computeTypeFromSuperClass(
        node.interfaceTarget.enclosingClass!, writeContext);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, true, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    node.value = rhs..parent = node;
    return new ExpressionInferenceResult(rhsResult.inferredType, node);
  }

  @override
  ExpressionInferenceResult visitSuperPropertySet(
      SuperPropertySet node, DartType typeContext) {
    DartType receiverType = classHierarchy.getTypeAsInstanceOf(thisType!,
        thisType!.classNode.supertype!.classNode, libraryBuilder.library)!;

    ObjectAccessTarget writeTarget = new ObjectAccessTarget.interfaceMember(
        node.interfaceTarget,
        isPotentiallyNullable: false);
    DartType writeContext = getSetterType(writeTarget, receiverType);
    writeContext = computeTypeFromSuperClass(
        node.interfaceTarget.enclosingClass!, writeContext);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, true, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    node.value = rhs..parent = node;
    return new ExpressionInferenceResult(rhsResult.inferredType, node);
  }

  @override
  StatementInferenceResult visitSwitchStatement(SwitchStatement node) {
    ExpressionInferenceResult expressionResult = inferExpression(
        node.expression, const UnknownType(), true,
        isVoidAllowed: false);
    node.expression = expressionResult.expression..parent = node;
    DartType expressionType = expressionResult.inferredType;

    Set<Field?>? enumFields;
    if (expressionType is InterfaceType && expressionType.classNode.isEnum) {
      enumFields = <Field?>{
        ...expressionType.classNode.fields.where(
            (Field field) => field.isConst && field.type == expressionType)
      };
      if (expressionType.isPotentiallyNullable) {
        enumFields.add(null);
      }
    }

    flowAnalysis.switchStatement_expressionEnd(node);

    bool hasDefault = false;
    bool lastCaseTerminates = true;
    for (int caseIndex = 0; caseIndex < node.cases.length; ++caseIndex) {
      SwitchCaseImpl switchCase = node.cases[caseIndex] as SwitchCaseImpl;
      hasDefault = hasDefault || switchCase.isDefault;
      flowAnalysis.switchStatement_beginCase(switchCase.hasLabel, node);
      for (int index = 0; index < switchCase.expressions.length; index++) {
        ExpressionInferenceResult caseExpressionResult = inferExpression(
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

        if (!isTopLevel) {
          if (libraryBuilder.isNonNullableByDefault) {
            if (!typeSchemaEnvironment.isSubtypeOf(caseExpressionType,
                expressionType, SubtypeCheckMode.withNullabilities)) {
              helper.addProblem(
                  templateSwitchExpressionNotSubtype.withArguments(
                      caseExpressionType,
                      expressionType,
                      isNonNullableByDefault),
                  caseExpression.fileOffset,
                  noLength,
                  context: [
                    messageSwitchExpressionNotAssignableCause.withLocation(
                        uriForInstrumentation,
                        node.expression.fileOffset,
                        noLength)
                  ]);
            }
          } else {
            // Check whether the expression type is assignable to the case
            // expression type.
            if (!isAssignable(expressionType, caseExpressionType)) {
              helper.addProblem(
                  templateSwitchExpressionNotAssignable.withArguments(
                      expressionType,
                      caseExpressionType,
                      isNonNullableByDefault),
                  caseExpression.fileOffset,
                  noLength,
                  context: [
                    messageSwitchExpressionNotAssignableCause.withLocation(
                        uriForInstrumentation,
                        node.expression.fileOffset,
                        noLength)
                  ]);
            }
          }
        }
      }
      StatementInferenceResult bodyResult = inferStatement(switchCase.body);
      if (bodyResult.hasChanged) {
        switchCase.body = bodyResult.statement..parent = switchCase;
      }

      if (isNonNullableByDefault) {
        lastCaseTerminates = !flowAnalysis.isReachable;
        if (!isTopLevel) {
          // The last case block is allowed to complete normally.
          if (caseIndex < node.cases.length - 1 && flowAnalysis.isReachable) {
            libraryBuilder.addProblem(messageSwitchCaseFallThrough,
                switchCase.fileOffset, noLength, helper.uri);
          }
        }
      }
    }
    node.isExplicitlyExhaustive = enumFields != null && enumFields.isEmpty;
    bool isExhaustive = node.isExplicitlyExhaustive || hasDefault;
    flowAnalysis.switchStatement_end(isExhaustive);
    Statement? replacement;
    if (isExhaustive && !hasDefault && shouldThrowUnsoundnessException) {
      if (!lastCaseTerminates) {
        LabeledStatement breakTarget;
        if (node.parent is LabeledStatement) {
          breakTarget = node.parent as LabeledStatement;
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
          _createExpressionStatement(createReachabilityError(
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
    DartType inferredType = coreTypes.symbolRawType(libraryBuilder.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitThisExpression(
      ThisExpression node, DartType typeContext) {
    flowAnalysis.thisOrSuper(node, thisType!);
    return new ExpressionInferenceResult(thisType!, node);
  }

  @override
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    ExpressionInferenceResult expressionResult = inferExpression(
        node.expression, const UnknownType(), !isTopLevel,
        isVoidAllowed: false);
    node.expression = expressionResult.expression..parent = node;
    flowAnalysis.handleExit();
    if (!isTopLevel && isNonNullableByDefault) {
      if (!isAssignable(typeSchemaEnvironment.objectNonNullableRawType,
          expressionResult.inferredType)) {
        return new ExpressionInferenceResult(
            const DynamicType(),
            helper.buildProblem(
                templateThrowingNotAssignableToObjectError.withArguments(
                    expressionResult.inferredType, true),
                node.expression.fileOffset,
                noLength));
      }
    }
    // Return BottomType in legacy mode for compatibility.
    return new ExpressionInferenceResult(
        isNonNullableByDefault
            ? const NeverType.nonNullable()
            : const NullType(),
        node);
  }

  void visitCatch(Catch node) {
    StatementInferenceResult bodyResult = inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
  }

  StatementInferenceResult visitTryStatement(TryStatement node) {
    if (node.finallyBlock != null) {
      flowAnalysis.tryFinallyStatement_bodyBegin();
    }
    Statement tryBodyWithAssignedInfo = node.tryBlock;
    if (node.catchBlocks.isNotEmpty) {
      flowAnalysis.tryCatchStatement_bodyBegin();
    }

    StatementInferenceResult tryBlockResult = inferStatement(node.tryBlock);

    if (node.catchBlocks.isNotEmpty) {
      flowAnalysis.tryCatchStatement_bodyEnd(tryBodyWithAssignedInfo);
      for (Catch catchBlock in node.catchBlocks) {
        flowAnalysis.tryCatchStatement_catchBegin(
            catchBlock.exception, catchBlock.stackTrace);
        visitCatch(catchBlock);
        flowAnalysis.tryCatchStatement_catchEnd();
      }
      flowAnalysis.tryCatchStatement_end();
    }

    StatementInferenceResult? finalizerResult;
    if (node.finallyBlock != null) {
      // If a try statement has no catch blocks, the finally block uses the
      // assigned variables from the try block in [tryBodyWithAssignedInfo],
      // otherwise it uses the assigned variables for the
      flowAnalysis.tryFinallyStatement_finallyBegin(
          node.catchBlocks.isNotEmpty ? node : tryBodyWithAssignedInfo);
      finalizerResult = inferStatement(node.finallyBlock!);
      flowAnalysis.tryFinallyStatement_end();
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
          finalizerResult!.hasChanged
              ? finalizerResult.statement
              : node.finallyBlock!)
        ..fileOffset = node.fileOffset;
    }
    libraryBuilder.loader.dataForTesting?.registerAlias(node, result);
    return new StatementInferenceResult.single(result);
  }

  @override
  ExpressionInferenceResult visitTypeLiteral(
      TypeLiteral node, DartType typeContext) {
    DartType inferredType = coreTypes.typeRawType(libraryBuilder.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitVariableSet(
      VariableSet node, DartType typeContext) {
    VariableDeclarationImpl variable = node.variable as VariableDeclarationImpl;
    bool isDefinitelyAssigned = false;
    bool isDefinitelyUnassigned = false;
    if (isNonNullableByDefault) {
      isDefinitelyAssigned = flowAnalysis.isAssigned(variable);
      isDefinitelyUnassigned = flowAnalysis.isUnassigned(variable);
    }
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    DartType? promotedType;
    if (isNonNullableByDefault) {
      promotedType = flowAnalysis.promotedType(variable);
    }
    ExpressionInferenceResult rhsResult = inferExpression(
        node.value, promotedType ?? declaredOrInferredType, true,
        isVoidAllowed: true);
    rhsResult = ensureAssignableResult(declaredOrInferredType, rhsResult,
        fileOffset: node.fileOffset,
        isVoidAllowed: declaredOrInferredType is VoidType);
    Expression rhs = rhsResult.expression;
    flowAnalysis.write(
        node, variable, rhsResult.inferredType, rhsResult.expression);
    DartType resultType = rhsResult.inferredType;
    Expression resultExpression;
    if (variable.lateSetter != null) {
      resultExpression = new LocalFunctionInvocation(variable.lateSetter!,
          new Arguments(<Expression>[rhs])..fileOffset = node.fileOffset,
          functionType: variable.lateSetter!.type as FunctionType)
        ..fileOffset = node.fileOffset;
      // Future calls to flow analysis will be using `resultExpression` to refer
      // to the variable set, so instruct flow analysis to forward the
      // expression information.
      flowAnalysis.forwardExpression(resultExpression, node);
    } else {
      node.value = rhs..parent = node;
      resultExpression = node;
    }
    if (!isTopLevel && isNonNullableByDefault) {
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
                helper.wrapInProblem(
                    resultExpression,
                    templateLateDefinitelyAssignedError
                        .withArguments(node.variable.name!),
                    node.fileOffset,
                    node.variable.name!.length));
          }
        } else if (variable.isStaticLate) {
          if (!isDefinitelyUnassigned) {
            return new ExpressionInferenceResult(
                resultType,
                helper.wrapInProblem(
                    resultExpression,
                    templateFinalPossiblyAssignedError
                        .withArguments(node.variable.name!),
                    node.fileOffset,
                    node.variable.name!.length));
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
    ExpressionInferenceResult? initializerResult;
    flowAnalysis.declare(node, node.hasDeclaredInitializer);
    if (node.initializer != null) {
      if (node.isLate && node.hasDeclaredInitializer) {
        flowAnalysis.lateInitializer_begin(node);
      }
      initializerResult = inferExpression(node.initializer!, declaredType,
          !isTopLevel || node.isImplicitlyTyped,
          isVoidAllowed: true);
      if (node.isLate && node.hasDeclaredInitializer) {
        flowAnalysis.lateInitializer_end();
      }
      inferredType = inferDeclarationType(initializerResult.inferredType,
          forSyntheticVariable: node.name == null);
    } else {
      inferredType = const DynamicType();
    }
    if (node.isImplicitlyTyped) {
      instrumentation?.record(uriForInstrumentation, node.fileOffset, 'type',
          new InstrumentationValueForType(inferredType));
      if (dataForTesting != null) {
        dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
            inferredType;
      }
      node.type = inferredType;
    }
    if (initializerResult != null) {
      DartType initializerType = initializerResult.inferredType;
      // TODO(paulberry): `initializerType` is sometimes `null` during top
      // level inference.  Figure out how to prevent this.
      // ignore: unnecessary_null_comparison
      if (initializerType != null) {
        flowAnalysis.initialize(
            node, initializerType, initializerResult.expression,
            isFinal: node.isFinal,
            isLate: node.isLate,
            isImplicitlyTyped: node.isImplicitlyTyped);
      }
      initializerResult = ensureAssignableResult(node.type, initializerResult,
          fileOffset: node.fileOffset, isVoidAllowed: node.type is VoidType);
      Expression initializer = initializerResult.expression;
      node.initializer = initializer..parent = node;
    }
    if (node.isLate &&
        libraryBuilder.loader.target.backendTarget.isLateLocalLoweringEnabled(
            hasInitializer: node.hasDeclaredInitializer,
            isFinal: node.isFinal,
            isPotentiallyNullable: node.type.isPotentiallyNullable)) {
      int fileOffset = node.fileOffset;

      List<Statement> result = <Statement>[];
      result.add(node);

      late_lowering.IsSetEncoding isSetEncoding =
          late_lowering.computeIsSetEncoding(
              node.type, late_lowering.computeIsSetStrategy(libraryBuilder));
      VariableDeclaration? isSetVariable;
      if (isSetEncoding == late_lowering.IsSetEncoding.useIsSetField) {
        isSetVariable = new VariableDeclaration(
            late_lowering.computeLateLocalIsSetName(node.name!),
            initializer: new BoolLiteral(false)..fileOffset = fileOffset,
            type: coreTypes.boolRawType(libraryBuilder.nonNullable),
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
          new VariableGet(isSetVariable!)..fileOffset = fileOffset;
      Expression createVariableWrite(Expression value) =>
          new VariableSet(node, value);
      Expression createIsSetWrite(Expression value) =>
          new VariableSet(isSetVariable!, value);

      VariableDeclaration getVariable = new VariableDeclaration(
          late_lowering.computeLateLocalGetterName(node.name!),
          isLowered: true)
        ..fileOffset = fileOffset;
      FunctionDeclaration getter = new FunctionDeclaration(
          getVariable,
          new FunctionNode(
              node.initializer == null
                  ? late_lowering.createGetterBodyWithoutInitializer(
                      coreTypes, fileOffset, node.name!, node.type,
                      createVariableRead: createVariableRead,
                      createIsSetRead: createIsSetRead,
                      isSetEncoding: isSetEncoding,
                      forField: false)
                  : (node.isFinal
                      ? late_lowering.createGetterWithInitializerWithRecheck(
                          coreTypes,
                          fileOffset,
                          node.name!,
                          node.type,
                          node.initializer!,
                          createVariableRead: createVariableRead,
                          createVariableWrite: createVariableWrite,
                          createIsSetRead: createIsSetRead,
                          createIsSetWrite: createIsSetWrite,
                          isSetEncoding: isSetEncoding,
                          forField: false)
                      : late_lowering.createGetterWithInitializer(coreTypes,
                          fileOffset, node.name!, node.type, node.initializer!,
                          createVariableRead: createVariableRead,
                          createVariableWrite: createVariableWrite,
                          createIsSetRead: createIsSetRead,
                          createIsSetWrite: createIsSetWrite,
                          isSetEncoding: isSetEncoding)),
              returnType: node.type))
        ..fileOffset = fileOffset;
      getVariable.type =
          getter.function.computeFunctionType(libraryBuilder.nonNullable);
      node.lateGetter = getVariable;
      result.add(getter);

      if (!node.isFinal || node.initializer == null) {
        node.isLateFinalWithoutInitializer =
            node.isFinal && node.initializer == null;
        VariableDeclaration setVariable = new VariableDeclaration(
            late_lowering.computeLateLocalSetterName(node.name!),
            isLowered: true)
          ..fileOffset = fileOffset;
        VariableDeclaration setterParameter =
            new VariableDeclaration("${node.name}#param", type: node.type)
              ..fileOffset = fileOffset;
        FunctionDeclaration setter = new FunctionDeclaration(
                setVariable,
                new FunctionNode(
                    node.isFinal
                        ? late_lowering.createSetterBodyFinal(coreTypes,
                            fileOffset, node.name!, setterParameter, node.type,
                            shouldReturnValue: true,
                            createVariableRead: createVariableRead,
                            createVariableWrite: createVariableWrite,
                            createIsSetRead: createIsSetRead,
                            createIsSetWrite: createIsSetWrite,
                            isSetEncoding: isSetEncoding,
                            forField: false)
                        : late_lowering.createSetterBody(coreTypes, fileOffset,
                            node.name!, setterParameter, node.type,
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
            setter.function.computeFunctionType(libraryBuilder.nonNullable);
        node.lateSetter = setVariable;
        result.add(setter);
      }
      node.isLate = false;
      node.lateType = node.type;
      if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
        node.initializer = new StaticInvocation(coreTypes.createSentinelMethod,
            new Arguments([], types: [node.type])..fileOffset = fileOffset)
          ..fileOffset = fileOffset
          ..parent = node;
      } else {
        node.initializer = null;
      }
      node.type = computeNullable(node.type);
      node.lateName = node.name;
      node.isLowered = true;
      node.name = late_lowering.computeLateLocalName(node.name!);

      return new StatementInferenceResult.multiple(node.fileOffset, result);
    }
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitVariableGet(
      covariant VariableGetImpl node, DartType typeContext) {
    VariableDeclarationImpl variable = node.variable as VariableDeclarationImpl;
    DartType? promotedType;
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    if (isExtensionThis(variable)) {
      flowAnalysis.thisOrSuper(node, variable.type);
    } else if (isNonNullableByDefault && node.forNullGuardedAccess) {
      DartType nonNullableType = variable.type.toNonNull();
      if (nonNullableType != variable.type) {
        promotedType = nonNullableType;
      }
    } else if (!variable.isLocalFunction) {
      // Don't promote local functions.
      promotedType = flowAnalysis.variableRead(node, variable);
    }
    if (promotedType != null) {
      instrumentation?.record(uriForInstrumentation, node.fileOffset,
          'promotedType', new InstrumentationValueForType(promotedType));
    }
    node.promotedType = promotedType;
    DartType resultType = promotedType ?? declaredOrInferredType;
    Expression resultExpression;
    if (variable.isLocalFunction) {
      return instantiateTearOff(resultType, typeContext, node);
    } else if (variable.lateGetter != null) {
      resultExpression = new LocalFunctionInvocation(variable.lateGetter!,
          new Arguments(<Expression>[])..fileOffset = node.fileOffset,
          functionType: variable.lateGetter!.type as FunctionType)
        ..fileOffset = node.fileOffset;
      // Future calls to flow analysis will be using `resultExpression` to refer
      // to the variable get, so instruct flow analysis to forward the
      // expression information.
      flowAnalysis.forwardExpression(resultExpression, node);
    } else {
      resultExpression = node;
    }
    if (!isTopLevel) {
      bool isUnassigned = !flowAnalysis.isAssigned(variable);
      if (isUnassigned) {
        dataForTesting?.flowAnalysisResult.potentiallyUnassignedNodes.add(node);
      }
      bool isDefinitelyUnassigned = flowAnalysis.isUnassigned(variable);
      if (isDefinitelyUnassigned) {
        dataForTesting?.flowAnalysisResult.definitelyUnassignedNodes.add(node);
      }
      if (isNonNullableByDefault) {
        // Synthetic variables, local functions, and variables with
        // invalid types aren't checked.
        if (variable.name != null &&
            !variable.isLocalFunction &&
            declaredOrInferredType is! InvalidType) {
          if (variable.isLate || variable.lateGetter != null) {
            if (isDefinitelyUnassigned) {
              String name = variable.lateName ?? variable.name!;
              return new ExpressionInferenceResult(
                  resultType,
                  helper.wrapInProblem(
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
                    helper.wrapInProblem(
                        resultExpression,
                        templateFinalNotAssignedError
                            .withArguments(node.variable.name!),
                        node.fileOffset,
                        node.variable.name!.length));
              } else if (declaredOrInferredType.isPotentiallyNonNullable) {
                return new ExpressionInferenceResult(
                    resultType,
                    helper.wrapInProblem(
                        resultExpression,
                        templateNonNullableNotAssignedError
                            .withArguments(node.variable.name!),
                        node.fileOffset,
                        node.variable.name!.length));
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
    flowAnalysis.whileStatement_conditionBegin(node);
    InterfaceType expectedType =
        coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
        node.condition, expectedType, !isTopLevel,
        isVoidAllowed: false);
    Expression condition =
        ensureAssignableResult(expectedType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.whileStatement_bodyBegin(node, node.condition);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    flowAnalysis.whileStatement_end();
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitYieldStatement(YieldStatement node) {
    ExpressionInferenceResult expressionResult;
    DartType typeContext = closureContext.yieldContext;
    if (node.isYieldStar && typeContext is! UnknownType) {
      typeContext = wrapType(
          typeContext,
          closureContext.isAsync
              ? coreTypes.streamClass
              : coreTypes.iterableClass,
          libraryBuilder.nonNullable);
    }
    expressionResult = inferExpression(node.expression, typeContext, true,
        isVoidAllowed: true);
    closureContext.handleYield(node, expressionResult);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitLoadLibrary(
      covariant LoadLibraryImpl node, DartType typeContext) {
    DartType inferredType = typeSchemaEnvironment.futureType(
        const DynamicType(), libraryBuilder.nonNullable);
    if (node.arguments != null) {
      FunctionType calleeType =
          new FunctionType([], inferredType, libraryBuilder.nonNullable);
      inferInvocation(this, typeContext, node.fileOffset, calleeType,
          node.arguments! as ArgumentsImpl);
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitLoadLibraryTearOff(
      LoadLibraryTearOff node, DartType typeContext) {
    DartType inferredType = new FunctionType(
        [],
        typeSchemaEnvironment.futureType(
            const DynamicType(), libraryBuilder.nonNullable),
        libraryBuilder.nonNullable);
    Expression replacement = new StaticTearOff(node.target)
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, DartType typeContext) {
    // TODO(cstefantsova): Figure out the suitable nullability for that.
    return new ExpressionInferenceResult(
        coreTypes.objectRawType(libraryBuilder.nullable), node);
  }

  ExpressionInferenceResult visitEquals(
      EqualsExpression node, DartType typeContext) {
    ExpressionInferenceResult leftResult =
        inferExpression(node.left, const UnknownType(), true);
    return _computeEqualsExpression(node.fileOffset, leftResult.expression,
        leftResult.inferredType, node.right,
        isNot: node.isNot);
  }

  ExpressionInferenceResult visitBinary(
      BinaryExpression node, DartType typeContext) {
    ExpressionInferenceResult leftResult =
        inferExpression(node.left, const UnknownType(), true);
    Map<DartType, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(leftResult.expression);
    return _computeBinaryExpression(
        node.fileOffset,
        typeContext,
        leftResult.expression,
        leftResult.inferredType,
        node.binaryName,
        node.right,
        whyNotPromoted);
  }

  ExpressionInferenceResult visitUnary(
      UnaryExpression node, DartType typeContext) {
    ExpressionInferenceResult? expressionResult;
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
        IntJudgment receiver = node.expression as IntJudgment;
        if (isDoubleContext(typeContext)) {
          double? doubleValue = receiver.asDouble(negated: true);
          if (doubleValue != null) {
            Expression replacement = new DoubleLiteral(doubleValue)
              ..fileOffset = node.fileOffset;
            DartType inferredType =
                coreTypes.doubleRawType(libraryBuilder.nonNullable);
            return new ExpressionInferenceResult(inferredType, replacement);
          }
        }
        Expression? error = checkWebIntLiteralsErrorIfUnexact(
            receiver.value, receiver.literal, receiver.fileOffset);
        if (error != null) {
          return new ExpressionInferenceResult(const DynamicType(), error);
        }
      } else if (node.expression is ShadowLargeIntLiteral) {
        ShadowLargeIntLiteral receiver =
            node.expression as ShadowLargeIntLiteral;
        if (!receiver.isParenthesized) {
          if (isDoubleContext(typeContext)) {
            double? doubleValue = receiver.asDouble(negated: true);
            if (doubleValue != null) {
              Expression replacement = new DoubleLiteral(doubleValue)
                ..fileOffset = node.fileOffset;
              DartType inferredType =
                  coreTypes.doubleRawType(libraryBuilder.nonNullable);
              return new ExpressionInferenceResult(inferredType, replacement);
            }
          }
          int? intValue = receiver.asInt64(negated: true);
          if (intValue == null) {
            Expression error = helper.buildProblem(
                templateIntegerLiteralIsOutOfRange
                    .withArguments(receiver.literal),
                receiver.fileOffset,
                receiver.literal.length);
            return new ExpressionInferenceResult(const DynamicType(), error);
          }
          // ignore: unnecessary_null_comparison
          if (intValue != null) {
            Expression? error = checkWebIntLiteralsErrorIfUnexact(
                intValue, receiver.literal, receiver.fileOffset);
            if (error != null) {
              return new ExpressionInferenceResult(const DynamicType(), error);
            }
            expressionResult = new ExpressionInferenceResult(
                coreTypes.intRawType(libraryBuilder.nonNullable),
                new IntLiteral(-intValue)
                  ..fileOffset = node.expression.fileOffset);
          }
        }
      }
    }
    if (expressionResult == null) {
      expressionResult =
          inferExpression(node.expression, const UnknownType(), true);
    }
    Map<DartType, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(expressionResult.expression);
    return _computeUnaryExpression(node.fileOffset, expressionResult.expression,
        expressionResult.inferredType, node.unaryName, whyNotPromoted);
  }

  ExpressionInferenceResult visitParenthesized(
      ParenthesizedExpression node, DartType typeContext) {
    return inferExpression(node.expression, typeContext, true,
        isVoidAllowed: true);
  }

  void reportNonNullableInNullAwareWarningIfNeeded(
      DartType operandType, String operationName, int offset) {
    if (!isTopLevel && isNonNullableByDefault) {
      if (operandType is! InvalidType &&
          operandType.nullability == Nullability.nonNullable) {
        libraryBuilder.addProblem(
            templateNonNullableInNullAware.withArguments(
                operationName, operandType, isNonNullableByDefault),
            offset,
            noLength,
            helper.uri);
      }
    }
  }
}

class ForInResult {
  final VariableDeclaration variable;
  final Expression iterable;
  final Expression? syntheticAssignment;
  final Statement? expressionSideEffects;

  ForInResult(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionSideEffects);

  @override
  String toString() => 'ForInResult($variable,$iterable,'
      '$syntheticAssignment,$expressionSideEffects)';
}

abstract class ForInVariable {
  /// Computes the type of the elements expected for this for-in variable.
  DartType computeElementType(InferenceVisitorBase visitor);

  /// Infers the assignment to this for-in variable with a value of type
  /// [rhsType]. The resulting expression is returned.
  Expression? inferAssignment(InferenceVisitorBase visitor, DartType rhsType);
}

class LocalForInVariable implements ForInVariable {
  VariableSet variableSet;

  LocalForInVariable(this.variableSet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    VariableDeclaration variable = variableSet.variable;
    DartType? promotedType;
    if (visitor.isNonNullableByDefault) {
      promotedType = visitor.flowAnalysis.promotedType(variable);
    }
    return promotedType ?? variable.type;
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    DartType variableType =
        visitor.computeGreatestClosure(variableSet.variable.type);
    Expression rhs = visitor.ensureAssignable(
        variableType, rhsType, variableSet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    variableSet.value = rhs..parent = variableSet;
    visitor.flowAnalysis
        .write(variableSet, variableSet.variable, rhsType, null);
    return variableSet;
  }
}

class PropertyForInVariable implements ForInVariable {
  final PropertySet propertySet;

  DartType? _writeType;

  Expression? _rhs;

  PropertyForInVariable(this.propertySet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    ExpressionInferenceResult receiverResult = visitor.inferExpression(
        propertySet.receiver, const UnknownType(), true);
    propertySet.receiver = receiverResult.expression..parent = propertySet;
    DartType receiverType = receiverResult.inferredType;
    ObjectAccessTarget writeTarget = visitor.findInterfaceMember(
        receiverType, propertySet.name, propertySet.fileOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        instrumented: true,
        includeExtensionMethods: true);
    DartType elementType =
        _writeType = visitor.getSetterType(writeTarget, receiverType);
    Expression? error = visitor.reportMissingInterfaceMember(
        writeTarget,
        receiverType,
        propertySet.name,
        propertySet.fileOffset,
        templateUndefinedSetter);
    if (error != null) {
      _rhs = error;
    } else {
      if (writeTarget.isInstanceMember || writeTarget.isObjectMember) {
        if (visitor.instrumentation != null &&
            receiverType == const DynamicType()) {
          visitor.instrumentation!.record(
              visitor.uriForInstrumentation,
              propertySet.fileOffset,
              'target',
              new InstrumentationValueForMember(writeTarget.member!));
        }
      }
      _rhs = propertySet.value;
    }
    return elementType;
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    Expression rhs = visitor.ensureAssignable(
        visitor.computeGreatestClosure(_writeType!), rhsType, _rhs!,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    propertySet.value = rhs..parent = propertySet;
    ExpressionInferenceResult result = visitor.inferExpression(
        propertySet, const UnknownType(), !visitor.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class AbstractSuperPropertyForInVariable implements ForInVariable {
  final AbstractSuperPropertySet superPropertySet;

  DartType? _writeType;

  AbstractSuperPropertyForInVariable(this.superPropertySet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    DartType receiverType = visitor.thisType!;
    ObjectAccessTarget writeTarget = visitor.findInterfaceMember(
        receiverType, superPropertySet.name, superPropertySet.fileOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        instrumented: true);
    assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
    return _writeType = visitor.getSetterType(writeTarget, receiverType);
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    Expression rhs = visitor.ensureAssignable(
        visitor.computeGreatestClosure(_writeType!),
        rhsType,
        superPropertySet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);
    superPropertySet.value = rhs..parent = superPropertySet;
    ExpressionInferenceResult result = visitor.inferExpression(
        superPropertySet, const UnknownType(), !visitor.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class SuperPropertyForInVariable implements ForInVariable {
  final SuperPropertySet superPropertySet;

  DartType? _writeType;

  SuperPropertyForInVariable(this.superPropertySet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    DartType receiverType = visitor.thisType!;
    ObjectAccessTarget writeTarget = visitor.findInterfaceMember(
        receiverType, superPropertySet.name, superPropertySet.fileOffset,
        callSiteAccessKind: CallSiteAccessKind.setterInvocation,
        instrumented: true);
    assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
    return _writeType = visitor.getSetterType(writeTarget, receiverType);
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    Expression rhs = visitor.ensureAssignable(
        visitor.computeGreatestClosure(_writeType!),
        rhsType,
        superPropertySet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);
    superPropertySet.value = rhs..parent = superPropertySet;
    ExpressionInferenceResult result = visitor.inferExpression(
        superPropertySet, const UnknownType(), !visitor.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class StaticForInVariable implements ForInVariable {
  final StaticSet staticSet;

  StaticForInVariable(this.staticSet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) =>
      staticSet.target.setterType;

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    DartType setterType =
        visitor.computeGreatestClosure(staticSet.target.setterType);
    Expression rhs = visitor.ensureAssignable(
        setterType, rhsType, staticSet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    staticSet.value = rhs..parent = staticSet;
    ExpressionInferenceResult result = visitor.inferExpression(
        staticSet, const UnknownType(), !visitor.isTopLevel,
        isVoidAllowed: true);
    return result.expression;
  }
}

class InvalidForInVariable implements ForInVariable {
  final Expression? expression;

  InvalidForInVariable(this.expression);

  @override
  DartType computeElementType(InferenceVisitor visitor) => const UnknownType();

  @override
  Expression? inferAssignment(InferenceVisitor visitor, DartType rhsType) =>
      expression;
}

class _UriOffset {
  final Uri uri;
  final int fileOffset;

  _UriOffset(this.uri, this.fileOffset);
}

/// Offset and type information collection in [InferenceVisitor.inferMapEntry].
class _MapLiteralEntryOffsets {
  // Stores the offset of the map entry found by inferMapEntry.
  int? mapEntryOffset;

  // Stores the offset of the map spread found by inferMapEntry.
  int? mapSpreadOffset;

  // Stores the offset of the iterable spread found by inferMapEntry.
  int? iterableSpreadOffset;

  // Stores the type of the iterable spread found by inferMapEntry.
  DartType? iterableSpreadType;
}
