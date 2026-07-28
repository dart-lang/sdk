// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jensj): Probably all `_createVariableGet(result)` needs their offset
// "nulled out".

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/null_shorting.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    hide MapPatternEntry;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:_fe_analyzer_shared/src/util/null_value.dart';
import 'package:_fe_analyzer_shared/src/util/stack_checker.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/src/non_null.dart';
import 'package:kernel/type_algebra.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/messages.dart';
import '../base/problems.dart'
    as problems
    show internalProblem, unhandled, unimplemented, unsupported;
import '../builder/library_builder.dart';
import '../codes/diagnostic.dart' as diag;
import '../dill/dill_library_builder.dart';
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/hierarchy/class_member.dart';
import '../kernel/inferred_collections.dart';
import '../kernel/internal_ast.dart';
import '../kernel/internal_ast_helper.dart' as intern;
import '../kernel/late_lowering.dart' as late_lowering;
import '../source/check_helper.dart';
import '../util/expression_evaluation_helpers.dart';
import '../util/helpers.dart';
import '../util/local_stack.dart';
import 'body_inference_context.dart';
import 'collection_encoding.dart';
import 'context_allocation_strategy.dart';
import 'element_inference.dart';
import 'inference_results.dart';
import 'inference_visitor_base.dart';
import 'object_access_target.dart';
import 'shared_type_analyzer.dart';
import 'stack_values.dart';
import 'type_constraint_gatherer.dart';
import 'type_inference_engine.dart';
import 'type_inferrer.dart';
import 'type_schema.dart' show UnknownType, isKnown;

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
    InternalExpression expression,
    DartType typeContext, {
    bool isVoidAllowed = false,
    bool forEffect = false,
  });

  /// Performs type inference on the given [statement].
  ///
  /// If [bodyContext] is not null, the [statement] is inferred using
  /// [bodyContext] as the current context.
  StatementInferenceResult inferStatement(
    InternalStatement statement, [
    BodyInferenceContext? bodyContext,
  ]);

  /// Performs type inference on the given [initializer].
  InitializerInferenceResult inferInitializer(InternalInitializer initializer);
}

abstract class ReturnContext {}

class StandardReturnContext implements ReturnContext {
  const new();
}

class AnonymousMethodReturnContext extends ReturnContext {
  final Variable resultVariable;
  final InternalLabeledStatement internalLabel;
  final LabeledStatement label;
  final List<DartType> returnTypes = [];
  final DartType typeContext;

  new({
    required this.resultVariable,
    required this.internalLabel,
    required this.label,
    required this.typeContext,
  });
}

class InferenceVisitorImpl extends InferenceVisitorBase
    with
        TypeAnalyzer<
          InternalNode,
          InternalStatement,
          InternalExpression,
          InternalVariable,
          InternalPattern,
          InvalidExpression,
          TypeDeclarationType,
          TypeDeclaration
        >,
        NullShortingMixin<NullAwareGuard, InternalExpression, InternalVariable>,
        StackChecker
    implements InferenceVisitor {
  /// Debug-only: if `true`, manipulations of [_rewriteStack] performed by
  /// [popRewrite] and [pushRewrite] will be printed.
  static const bool _debugRewriteStack = false;

  Class? mapEntryClass;

  @override
  final OperationsCfe operations;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  BodyInferenceContext? _bodyContext;

  /// Stack for return contexts.
  final LocalStack<ReturnContext> _returnContexts = new LocalStack([]);

  ReturnContext? get returnContext => _returnContexts.currentOrNull;

  /// If a switch statement is being visited and the type being switched on is a
  /// (possibly nullable) enumerated type, the set of enum values for which no
  /// case head has been seen yet; otherwise `null`.
  ///
  /// Enum values are represented by the [Field] object they are desugared into.
  /// If the type being switched on is nullable, then this set also includes a
  /// value of `null` if no case head has been seen yet that handles `null`.
  Set<Field?>? _enumFields;

  /// Stack for obtaining rewritten expressions and statements.  After
  /// [dispatchExpression] or [dispatchStatement] visits a node for type
  /// inference, the visited node (which may have been changed by the inference
  /// process) is pushed onto this stack.  Later, during the processing of the
  /// enclosing node, the visited node is popped off the stack again, and the
  /// enclosing node is updated to point to the new, rewritten node.
  ///
  /// The stack sometimes contains `null`s.  These account for situations where
  /// it's necessary to push a value onto the stack to balance a later pop, but
  /// there is no suitable expression or statement to push.
  final List<Object> _rewriteStack = [];

  @override
  final TypeAnalyzerOptions typeAnalyzerOptions;

  final ConstructorContext? _constructorContext;

  @override
  late final SharedTypeAnalyzerErrors errors = new SharedTypeAnalyzerErrors(
    visitor: this,
    problemReporting: problemReporting,
    compilerContext: compilerContext,
    uri: fileUri,
    coreTypes: coreTypes,
  );

  /// The innermost cascade whose expressions are currently being visited, or
  /// `null` if no cascade's expressions are currently being visited.
  Cascade? _enclosingCascade;

  /// Set to `true` when we are inside a try-statement or a local function.
  ///
  /// This is used to optimize the encoding of [AssignedVariablePattern]. When
  /// a pattern assignment occurs in a try block or a local function, a
  /// partially matched pattern is observable, since exceptions occurring during
  /// the matching can be caught.
  // TODO(johnniwinther): This can be improved by detecting whether the assigned
  // variable was declared outside the try statement or local function.
  bool _inTryOrLocalFunction = false;

  ContextAllocationStrategy _contextAllocationStrategy;

  new(
    super.inferrer,
    super.fileUri,
    this._constructorContext,
    this.operations,
    this.typeAnalyzerOptions,
    super.expressionEvaluationHelper, {
    required ContextAllocationStrategy contextAllocationStrategy,
  }) : _contextAllocationStrategy = contextAllocationStrategy;

  @override
  ThisVariable get internalThisVariable =>
      _contextAllocationStrategy.thisVariable;

  @override
  int get stackHeight => _rewriteStack.length;

  @override
  Object? lookupStack(int index) =>
      _rewriteStack[_rewriteStack.length - index - 1];

  /// Used to report an internal error encountered in the stack listener.
  @override
  // Coverage-ignore(suite): Not run.
  Never internalProblem(Message message, int charOffset, Uri uri) {
    return problems.internalProblem(message, charOffset, uri);
  }

  /// Checks that [base] is a valid base stack height for a call to
  /// [checkStack].
  ///
  /// This can be used to initialize a stack base for subsequent calls to
  /// [checkStack]. For instance:
  ///
  ///      int? stackBase;
  ///      // Set up the current stack height as the stack base.
  ///      assert(checkStackBase(node, stackBase = stackHeight));
  ///      ...
  ///      // Check that the stack is empty, relative to the stack base.
  ///      assert(checkStack(node, []));
  ///
  /// or
  ///
  ///      int? stackBase;
  ///      // Assert that the current stack height is at least 4 and set
  ///      // the stack height - 4 up as the stack base.
  ///      assert(checkStackBase(node, stackBase = stackHeight - 4));
  ///      ...
  ///      // Check that the stack contains a single `Expression` element,
  ///      // relative to the stack base.
  ///      assert(checkStack(node, [ValuesKind.Expression]));
  ///
  bool checkStackBase(InternalNode? node, int base) {
    return checkStackBaseStateForAssert(fileUri, node?.fileOffset, base);
  }

  /// Checks the top of the current stack against [kinds]. If a mismatch is
  /// found, a top of the current stack is print along with the expected [kinds]
  /// marking the frames that don't match, and throws an exception.
  ///
  /// [base] it is used as the reference stack base height at which the [kinds]
  /// are expected to occur, which allows for checking that the stack is empty
  /// wrt. the stack base height.
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkState(node,
  ///        [ValueKind.Expression, ValueKind.StatementOrNull],
  ///        base: stackBase));
  ///
  /// to document the expected stack and get earlier errors on unexpected stack
  /// content.
  bool checkStack(InternalNode? node, int? base, List<ValueKind> kinds) {
    return checkStackStateForAssert(
      fileUri,
      node?.fileOffset,
      kinds,
      base: base,
    );
  }

  @override
  BodyInferenceContext get bodyContext => _bodyContext!;

  @override
  ExpressionTypeAnalysisResult finishNullShorting(
    int targetDepth,
    ExpressionTypeAnalysisResult innerResult, {
    required InternalExpression wholeExpression,
  }) {
    ExpressionTypeAnalysisResult analysisResult = super.finishNullShorting(
      targetDepth,
      innerResult,
      wholeExpression: wholeExpression,
    );
    // If any expression info or expression reference was stored for the
    // null-aware expression, it was only valid in the case where the target
    // expression was not null. So it needs to be cleared now.
    // TODO(paulberry): The [wholeExpression] is an internal expression, but
    // we store expression info on external expressions, so this wouldn't have
    // cleared anything.
    //storeExpressionInfo(wholeExpression, null);
    return analysisResult;
  }

  /// Helper that creates a variable, a variable get, and a null aware guard
  /// for a null aware access on [receiver] with static type [receiverType] and
  /// non-null type [nonNullReceiverType].
  ///
  /// Returns the [VariableGet] expression to be used as the receiver in the
  /// null aware access.
  Expression _createNonNullReceiver(
    Expression receiver,
    DartType receiverType,
    DartType nonNullReceiverType,
  ) {
    if (_isThisExpression(receiver)) {
      // Null-aware access is not needed on `this`.
      return receiver;
    }
    SyntheticVariable receiverVariable = extern.createVariable(
      receiver,
      receiverType,
    );
    createNullAwareGuard(receiverVariable);
    Expression variableGet = extern.createVariableGet(
      receiverVariable,
      promotedType: nonNullReceiverType,
    );

    storeExpressionInfo(variableGet, getExpressionInfo(receiver));
    return variableGet;
  }

  void createNullAwareGuard(
    SyntheticVariable variable, {
    Expression? nullableExpression,
  }) {
    storeExpressionInfo(
      variable.initializer!,
      startNullShorting(
        new NullAwareGuard(
          variable,
          variable.fileOffset,
          nullableExpression: nullableExpression,
        ),
        getExpressionInfo(variable.initializer!),
        new SharedTypeView(variable.type),
      ),
    );
  }

  @override
  ExpressionTypeAnalysisResult handleNullShortingStep(
    ExpressionTypeAnalysisResult innerResult,
    NullAwareGuard guard,
    SharedTypeView inferredType,
  ) {
    pushRewrite(
      guard.createExpression(
        inferredType.unwrapTypeView(),
        popRewrite() as Expression,
      ),
    );
    return new ExpressionTypeAnalysisResult(type: inferredType);
  }

  @override
  StatementInferenceResult inferStatement(
    InternalStatement statement, [
    BodyInferenceContext? bodyContext,
  ]) {
    BodyInferenceContext? oldBodyContext = _bodyContext;
    if (bodyContext != null) {
      _bodyContext = bodyContext;
    }
    registerIfUnreachableForTesting(statement);

    // For full (non-top level) inference, we need access to the
    // ExpressionGeneratorHelper so that we can perform error recovery.
    StatementInferenceResult result = statement.acceptInference(this);
    _bodyContext = oldBodyContext;
    return result;
  }

  ExpressionInferenceResult _inferExpression(
    InternalExpression expression,
    DartType typeContext, {
    bool isVoidAllowed = false,
    bool forEffect = false,
  }) {
    registerIfUnreachableForTesting(expression);

    ExpressionInferenceResult result = expression.acceptInference(
      this,
      typeContext,
    );

    DartType inferredType = result.inferredType;
    if (inferredType is VoidType && !isVoidAllowed) {
      problemReporting.addProblem(
        diag.voidExpression,
        expression.fileOffset,
        noLength,
        fileUri,
      );
    }
    if (coreTypes.isBottom(result.inferredType)) {
      flowAnalysis.handleExit();
    }
    return result;
  }

  @override
  ExpressionInferenceResult inferExpression(
    InternalExpression expression,
    DartType typeContext, {
    bool isVoidAllowed = false,
    bool forEffect = false,
    bool continueNullShorting = false,
  }) {
    int? nullShortingTargetDepth;
    if (!continueNullShorting) nullShortingTargetDepth = nullShortingDepth;
    ExpressionInferenceResult result = _inferExpression(
      expression,
      typeContext,
      isVoidAllowed: isVoidAllowed,
      forEffect: forEffect,
    );
    if (nullShortingTargetDepth != null &&
        nullShortingDepth > nullShortingTargetDepth) {
      pushRewrite(result.expression);
      ExpressionInfo? flowAnalysisInfo = getExpressionInfo(result.expression);
      DartType inferredType = finishNullShorting(
        nullShortingTargetDepth,
        new ExpressionTypeAnalysisResult(
          type: new SharedTypeView(result.inferredType),
          flowAnalysisInfo: flowAnalysisInfo,
        ),
        wholeExpression: expression,
      ).type.unwrapTypeView();
      return new ExpressionInferenceResult(
        inferredType,
        popRewrite() as Expression,
      );
    } else {
      return result;
    }
  }

  @override
  InitializerInferenceResult inferInitializer(InternalInitializer initializer) {
    return initializer.acceptInference(this);
  }

  ExpressionInferenceResult visitInternalBlockExpression(
    InternalBlockExpression node,
    DartType typeContext,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      // Coverage-ignore-block(suite): Not run.
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.BlockExpression,
      );
    }
    // This is only used for error cases. The spec doesn't use this and
    // therefore doesn't specify the type context for the subterms.
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Block body = bodyResult.statement as Block;

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      const UnknownType(),
      isVoidAllowed: true,
    );
    Expression value = valueResult.expression;
    Scope? scope;
    if (scopeProviderInfo != null) {
      // Coverage-ignore-block(suite): Not run.
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      scope = scopeProviderInfo.scope;
    }
    return new ExpressionInferenceResult(
      valueResult.inferredType,
      extern.createBlockExpression(
        body,
        value,
        scope: scope,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ExpressionInferenceResult visitInternalStaticTearOff(
    InternalStaticTearOff node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    DartType type = node.target.function.computeFunctionType(
      Nullability.nonNullable,
    );
    return instantiateTearOff(
      type,
      typeContext,
      extern.createStaticTearOff(node.target, fileOffset: node.fileOffset),
      tearOffNode: node,
    );
  }

  ExpressionInferenceResult visitInternalFileUriExpression(
    InternalFileUriExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      typeContext,
    );
    Expression replacement = extern.createFileUriExpression(
      expression: result.expression,
      fileUri: node.fileUri,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  ExpressionInferenceResult visitInternalConstructorTearOff(
    InternalConstructorTearOff node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    DartType type = node.target.function!.computeFunctionType(
      Nullability.nonNullable,
    );
    Expression replacement = extern.createConstructorTearOff(
      node.target,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return instantiateTearOff(
      type,
      typeContext,
      replacement,
      tearOffNode: node,
    );
  }

  ExpressionInferenceResult visitInternalRedirectingFactoryTearOff(
    InternalRedirectingFactoryTearOff node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    DartType type = node.target.function.computeFunctionType(
      Nullability.nonNullable,
    );
    Expression replacement = extern.createRedirectingFactoryTearOff(
      node.target,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return instantiateTearOff(
      type,
      typeContext,
      replacement,
      tearOffNode: node,
    );
  }

  ExpressionInferenceResult visitInternalTypedefTearOff(
    InternalTypedefTearOff node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult expressionResult = inferExpression(
      node.expression,
      const UnknownType(),
      isVoidAllowed: true,
    );
    Expression expression = expressionResult.expression;
    assert(
      expressionResult.inferredType is FunctionType,
      "Expected a FunctionType from tearing off a constructor from "
      "a typedef, but got '${expressionResult.inferredType.runtimeType}'.",
    );
    FunctionType expressionType = expressionResult.inferredType as FunctionType;

    assert(expressionType.typeParameters.length == node.typeArguments.length);
    FunctionType resultType = FunctionTypeInstantiator.instantiate(
      expressionType,
      node.typeArguments,
    );
    FreshStructuralParameters freshStructuralParameters =
        getFreshStructuralParameters(node.structuralParameters);
    resultType =
        freshStructuralParameters.substitute(resultType) as FunctionType;
    resultType = new FunctionType(
      resultType.positionalParameters,
      resultType.returnType,
      resultType.declaredNullability,
      namedParameters: resultType.namedParameters,
      typeParameters: freshStructuralParameters.freshTypeParameters,
      requiredParameterCount: resultType.requiredParameterCount,
    );
    Expression replacement = extern.createTypedefTearOff(
      structuralParameters: node.structuralParameters,
      expression: expression,
      typeArguments: node.typeArguments,
      fileOffset: node.fileOffset,
    );
    ExpressionInferenceResult inferredResult = instantiateTearOff(
      resultType,
      typeContext,
      replacement,
      tearOffNode: node,
    );
    return ensureAssignableResult(
      typeContext,
      inferredResult,
      assignedNode: node.expression,
    );
  }

  InitializerInferenceResult visitInternalInvalidInitializer(
    InternalInvalidInitializer node,
  ) {
    return new SuccessfulInitializerInferenceResult(
      extern.createInvalidInitializerFromMessage(
        node.message,
        fileOffset: node.fileOffset,
        isRedirectingInitializer: node.isRedirectingInitializer,
        isSuperInitializer: node.isSuperInitializer,
      ),
    );
  }

  ExpressionInferenceResult visitInternalInvalidExpression(
    InternalInvalidExpression node,
    DartType typeContext,
  ) {
    Expression? expression;
    if (node.expression != null) {
      ExpressionInferenceResult result = inferExpression(
        node.expression!,
        typeContext,
        isVoidAllowed: true,
      );
      expression = result.expression;
    }
    Expression replacement = extern.createInvalidExpression(
      node.message,
      expression: expression,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(const InvalidType(), replacement);
  }

  ExpressionInferenceResult visitInternalInstantiation(
    InternalInstantiation node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.expression,
      const UnknownType(),
      isVoidAllowed: true,
    );
    if (operandResult.expression is InvalidExpression) return operandResult;
    Expression operand = operandResult.expression;
    DartType operandType = operandResult.inferredType;
    if (operandType is! FunctionType) {
      ObjectAccessTarget callMember = findInterfaceMember(
        operandType,
        callName,
        operand.fileOffset,
        isSetter: false,
        includeExtensionMethods: true,
      );
      switch (callMember.kind) {
        case ObjectAccessTargetKind.instanceMember:
          Member? target = callMember.classMember;
          if (target is Procedure && target.kind == ProcedureKind.Method) {
            operandType = callMember.getGetterType(this);
            operand = new InstanceTearOff(
              InstanceAccessKind.Instance,
              operand,
              callName,
              interfaceTarget: target,
              resultType: operandType,
            )..fileOffset = operand.fileOffset;
          }
          break;
        case ObjectAccessTargetKind.extensionMember:
        case ObjectAccessTargetKind.extensionTypeMember:
          if (callMember.tearoffTarget != null &&
              callMember.declarationMethodKind == ClassMemberKind.Method) {
            operandType = callMember.getGetterType(this);
            operand = new StaticInvocation(
              callMember.tearoffTarget as Procedure,
              new Arguments(
                <Expression>[operand],
                types: callMember.receiverTypeArguments,
              )..fileOffset = operand.fileOffset,
            )..fileOffset = operand.fileOffset;
          }
          break;
        case ObjectAccessTargetKind.nullableInstanceMember:
        case ObjectAccessTargetKind.superMember:
        case ObjectAccessTargetKind.objectMember:
        case ObjectAccessTargetKind.nullableCallFunction:
        case ObjectAccessTargetKind.nullableExtensionMember:
        case ObjectAccessTargetKind.dynamic:
        case ObjectAccessTargetKind.never:
        case ObjectAccessTargetKind.invalid:
        case ObjectAccessTargetKind.missing:
        case ObjectAccessTargetKind.ambiguous:
        case ObjectAccessTargetKind.callFunction:
        case ObjectAccessTargetKind.recordIndexed:
        case ObjectAccessTargetKind.nullableRecordIndexed:
        case ObjectAccessTargetKind.nullableRecordNamed:
        case ObjectAccessTargetKind.recordNamed:
        case ObjectAccessTargetKind.nullableExtensionTypeMember:
        case ObjectAccessTargetKind.extensionTypeRepresentation:
        // Coverage-ignore(suite): Not run.
        case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        // Coverage-ignore(suite): Not run.
        case ObjectAccessTargetKind.expressionEvaluationParameter:
          break;
      }
    }
    Expression result = extern.createInstantiation(
      operand,
      node.typeArguments,
      fileOffset: node.fileOffset,
    );
    DartType resultType = const InvalidType();
    if (operandType is FunctionType) {
      if (operandType.typeParameters.length == node.typeArguments.length) {
        checkBoundsInInstantiation(
          operandType,
          node.typeArguments,
          node.fileOffset,
          inferred: false,
        );
        if (operandType.isPotentiallyNullable) {
          result = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.instantiationNullableGenericFunctionType
                  .withArguments(operandType: operandType),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: noLength,
            ),
          );
        } else {
          resultType = FunctionTypeInstantiator.instantiate(
            operandType,
            node.typeArguments,
          );
        }
      } else {
        if (operandType.typeParameters.isEmpty) {
          result = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.instantiationNonGenericFunctionType.withArguments(
                operandType: operandType,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: noLength,
            ),
          );
        } else if (operandType.typeParameters.length >
            node.typeArguments.length) {
          result = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.instantiationTooFewArguments.withArguments(
                expectedCount: operandType.typeParameters.length,
                actualCount: node.typeArguments.length,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: noLength,
            ),
          );
        } else if (operandType.typeParameters.length <
            node.typeArguments.length) {
          result = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.instantiationTooManyArguments.withArguments(
                expectedCount: operandType.typeParameters.length,
                actualCount: node.typeArguments.length,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: noLength,
            ),
          );
        }
      }
    } else if (operandType is! InvalidType) {
      result = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.instantiationNonGenericFunctionType.withArguments(
            operandType: operandType,
          ),
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: noLength,
        ),
      );
    }
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result);
    return new ExpressionInferenceResult(resultType, result);
  }

  ExpressionInferenceResult visitInternalAsExpression(
    InternalAsExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      const UnknownType(),
      isVoidAllowed: true,
    );
    Expression operand = operandResult.expression;
    flowAnalysis.asExpression_end(
      getExpressionInfo(operand),
      subExpressionType: new SharedTypeView(operandResult.inferredType),
      castType: new SharedTypeView(node.type),
    );
    Expression replacement = extern.createAsExpression(
      operand,
      node.type,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(node.type, replacement);
  }

  InitializerInferenceResult visitInternalAssertInitializer(
    InternalAssertInitializer node,
  ) {
    InternalAssertStatement statement = node.statement;
    StatementInferenceResult result = inferStatement(statement);
    return new SuccessfulInitializerInferenceResult(
      extern.createAssertInitializer(
        result.statement as AssertStatement,
        fileOffset: node.fileOffset,
      ),
    );
  }

  StatementInferenceResult visitInternalAssertStatement(
    InternalAssertStatement node,
  ) {
    flowAnalysis.assert_begin();
    InterfaceType expectedType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      expectedType,
      isVoidAllowed: true,
    );

    Expression condition = ensureAssignableResult(
      expectedType,
      conditionResult,
      assignedNode: node.condition,
    ).expression;
    flowAnalysis.assert_afterCondition(getExpressionInfo(condition));
    Expression? message;
    if (node.message != null) {
      ExpressionInferenceResult codeResult = inferExpression(
        node.message!,
        const UnknownType(),
        isVoidAllowed: true,
      );
      message = codeResult.expression;
    }
    flowAnalysis.assert_end();
    return new StatementInferenceResult.single(
      extern.createAssertStatement(
        condition,
        message: message,
        conditionStartOffset: node.conditionStartOffset,
        conditionEndOffset: node.conditionEndOffset,
        fileOffset: node.fileOffset,
      ),
    );
  }

  bool _isIncompatibleWithAwait(DartType type) {
    if (isNullableTypeConstructorApplication(type)) {
      return _isIncompatibleWithAwait(
        computeTypeWithoutNullabilityMarker(type),
      );
    } else {
      switch (type) {
        case ExtensionType():
          return typeSchemaEnvironment.hierarchy
                  .getExtensionTypeAsInstanceOfClass(
                    type,
                    coreTypes.futureClass,
                  ) ==
              null;
        case TypeParameterType():
          return _isIncompatibleWithAwait(type.parameter.bound);
        case StructuralParameterType():
          // Coverage-ignore(suite): Not run.
          return _isIncompatibleWithAwait(type.parameter.bound);
        case IntersectionType():
          return _isIncompatibleWithAwait(type.right);
        case FunctionTypeParameterType():
          // Coverage-ignore(suite): Not run.
          return problems.unimplemented(
            "_isIncompatibleWithAwait(FunctionTypeParameterType)",
            -1,
            fileUri,
          );
        case ClassTypeParameterType():
          // Coverage-ignore(suite): Not run.
          return problems.unimplemented(
            "_isIncompatibleWithAwait(ClassTypeParameterType)",
            -1,
            fileUri,
          );
        case DynamicType():
        case VoidType():
        case FutureOrType():
        case InterfaceType():
        case TypedefType():
        case FunctionType():
        case RecordType():
        case NullType():
        case NeverType():
        case AuxiliaryType():
        case InvalidType():
          return false;
      }
    }
  }

  ExpressionInferenceResult visitInternalAwaitExpression(
    InternalAwaitExpression node,
    DartType typeContext,
  ) {
    if (typeContext is DynamicType) {
      typeContext = const UnknownType();
    }
    AwaitExpressionResult analysisResult = analyzeAwaitExpression(
      node,
      node.operand,
      typeContext.wrapSharedTypeSchemaView(),
    );
    Expression operandRewrite = popRewrite() as Expression;
    DartType operandType = analysisResult.operandType.unwrapTypeView();
    DartType flattenType = analysisResult.type.unwrapTypeView();
    if (_isIncompatibleWithAwait(operandType)) {
      Expression wrapped = operandRewrite;
      operandRewrite = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.awaitOfExtensionTypeNotFuture,
          fileUri: fileUri,
          fileOffset: wrapped.fileOffset,
          length: 1,
        ),
        expression: wrapped,
      );
      wrapped.parent = operandRewrite;
    }
    Expression operand = operandRewrite;
    DartType runtimeCheckType = new InterfaceType(
      coreTypes.futureClass,
      Nullability.nonNullable,
      [flattenType],
    );
    bool includeRuntimeCheckType = false;
    if (!typeSchemaEnvironment.isSubtypeOf(operandType, runtimeCheckType)) {
      includeRuntimeCheckType = true;
    }
    Expression replacement = extern.createAwaitExpression(
      operand,
      runtimeCheckType: includeRuntimeCheckType ? runtimeCheckType : null,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(flattenType, replacement);
  }

  List<Statement> _visitStatements(List<InternalStatement> statements) {
    List<Statement> result = [];
    for (int index = 0; index < statements.length; index++) {
      InternalStatement statement = statements[index];
      StatementInferenceResult statementResult = inferStatement(statement);
      if (statementResult.statementCount == 1) {
        result.add(statementResult.statement);
      } else {
        result.addAll(statementResult.statements);
      }
    }
    return result;
  }

  StatementInferenceResult visitInternalBlock(InternalBlock node) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Block,
      );
    }
    registerIfUnreachableForTesting(node);
    List<Statement> result = _visitStatements(node.statements);
    Block replacement = extern.createBlock(
      result,
      fileOffset: node.fileOffset,
      fileEndOffset: node.fileEndOffset,
    );

    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);

    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      replacement.scope = scopeProviderInfo.scope;
    }
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitInternalBoolLiteral(
    InternalBoolLiteral node,
    DartType typeContext,
  ) {
    Expression replacement = extern.createBoolLiteral(
      node.value,
      fileOffset: node.fileOffset,
    );
    storeExpressionInfo(replacement, flowAnalysis.booleanLiteral(node.value));
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(
      coreTypes.boolRawType(Nullability.nonNullable),
      replacement,
    );
  }

  StatementInferenceResult visitInternalBreakStatement(
    InternalBreakStatement node,
  ) {
    if (node.error != null) {
      // Coverage-ignore-block(suite): Not run.
      return new StatementInferenceResult.single(
        extern.createExpressionStatement(
          extern.createInvalidExpression(
            node.error!.message,
            fileOffset: node.error!.fileOffset,
          ),
        ),
      );
    }
    flowAnalysis.handleBreak(node.targetStatement);
    BreakStatement replacement = extern.createBreakStatement(
      dummyLabeledStatement,
      fileOffset: node.fileOffset,
    );
    node.targetStatement.breakStatements.add(replacement);
    return new StatementInferenceResult.single(replacement);
  }

  StatementInferenceResult visitInternalContinueStatement(
    InternalContinueStatement node,
  ) {
    if (node.error != null) {
      // Coverage-ignore-block(suite): Not run.
      return new StatementInferenceResult.single(
        extern.createExpressionStatement(
          extern.createInvalidExpression(
            node.error!.message,
            fileOffset: node.error!.fileOffset,
          ),
        ),
      );
    }
    flowAnalysis.handleContinue(node.targetStatement);
    BreakStatement replacement = extern.createBreakStatement(
      dummyLabeledStatement,
      fileOffset: node.fileOffset,
    );
    node.targetStatement.continueStatements.add(replacement);
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result = inferExpression(
      node.receiver,
      typeContext,
      isVoidAllowed: false,
    );

    Expression receiver = result.expression;
    node.variable.type = result.inferredType;
    NullAwareGuard? nullAwareGuard;
    if (node.isNullAware) {
      nullAwareGuard = new NullAwareGuard(
        node.variable.astVariable,
        node.variable.fileOffset,
        nullableExpression: receiver,
      );
    }
    flowAnalysis.cascadeExpression_afterTarget(
      getExpressionInfo(result.expression),
      new SharedTypeView(result.inferredType),
      isNullAware: node.isNullAware,
      guardVariable: node.variable,
    );

    Cascade? previousEnclosingCascade = _enclosingCascade;
    _enclosingCascade = node;
    List<ExpressionInferenceResult> expressionResults =
        <ExpressionInferenceResult>[];
    for (InternalExpression expression in node.expressions) {
      expressionResults.add(
        inferExpression(
          expression,
          const UnknownType(),
          isVoidAllowed: true,
          forEffect: true,
        ),
      );
    }
    List<Statement> body = [];
    for (int index = 0; index < expressionResults.length; index++) {
      body.add(_createExpressionStatement(expressionResults[index].expression));
    }
    _enclosingCascade = previousEnclosingCascade;

    Expression replacement = _createBlockExpression(
      node.variable.fileOffset,
      _createBlock(body),
      extern.createVariableGet(node.variable.astVariable),
    );

    if (nullAwareGuard != null) {
      pushRewrite(replacement);
      SharedTypeView inferredType = new SharedTypeView(result.inferredType);
      // End non-nullable promotion of the null-aware variable.
      flow.nullAwareAccess_end();
      handleNullShortingStep(
        new ExpressionTypeAnalysisResult(type: inferredType),
        nullAwareGuard,
        inferredType,
      );
      replacement = popRewrite() as Expression;
    } else {
      replacement = extern.createLet(
        variable: node.variable.astVariable,
        value: receiver,
        body: replacement,
        fileOffset: node.fileOffset,
      );
    }
    storeExpressionInfo(replacement, flowAnalysis.cascadeExpression_end());
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  PropertyTarget<InternalExpression> computePropertyTarget(Expression target) {
    if (_enclosingCascade case Cascade(:var variable)
        when target is VariableGet && target.variable == variable.astVariable) {
      // `target` is an implicit reference to the target of a cascade
      // expression; flow analysis uses `CascadePropertyTarget` to represent
      // this situation.
      return CascadePropertyTarget.singleton;
    } else {
      // `target` is an ordinary expression.
      return new ExpressionPropertyTarget(getExpressionInfo(target));
    }
  }

  Block _createBlock(List<Statement> statements) {
    return new Block(statements);
  }

  BlockExpression _createBlockExpression(
    int fileOffset,
    Block body,
    Expression value,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new BlockExpression(body, value)..fileOffset = fileOffset;
  }

  ExpressionStatement _createExpressionStatement(Expression expression) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return new ExpressionStatement(expression)
      ..fileOffset = expression.fileOffset;
  }

  ExpressionInferenceResult visitInternalConditionalExpression(
    InternalConditionalExpression node,
    DartType typeContext,
  ) {
    flowAnalysis.conditional_conditionBegin();
    InterfaceType expectedType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      expectedType,
      isVoidAllowed: true,
    );
    Expression condition = ensureAssignableResult(
      expectedType,
      conditionResult,
      assignedNode: node.condition,
    ).expression;
    flowAnalysis.conditional_thenBegin(getExpressionInfo(condition), node);
    bool isThenReachable = flowAnalysis.isReachable;

    // A conditional expression `E` of the form `b ? e1 : e2` with context
    // type `K` is analyzed as follows:
    //
    // - Let `T1` be the type of `e1` inferred with context type `K`
    ExpressionInferenceResult thenResult = inferExpression(
      node.then,
      typeContext,
      isVoidAllowed: true,
    );
    Expression then = thenResult.expression;
    registerIfUnreachableForTesting(node.then, isReachable: isThenReachable);
    DartType t1 = thenResult.inferredType;

    // - Let `T2` be the type of `e2` inferred with context type `K`
    flowAnalysis.conditional_elseBegin(
      getExpressionInfo(then),
      new SharedTypeView(thenResult.inferredType),
    );
    bool isOtherwiseReachable = flowAnalysis.isReachable;
    ExpressionInferenceResult otherwiseResult = inferExpression(
      node.otherwise,
      typeContext,
      isVoidAllowed: true,
    );
    Expression otherwise = otherwiseResult.expression;
    registerIfUnreachableForTesting(
      node.otherwise,
      isReachable: isOtherwiseReachable,
    );
    DartType t2 = otherwiseResult.inferredType;

    // - Let `T` be  `UP(T1, T2)`
    DartType t = typeSchemaEnvironment.getStandardUpperBound(t1, t2);

    // - Let `S` be the greatest closure of `K`
    DartType s = computeGreatestClosure(typeContext);

    DartType inferredType;
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled) {
      inferredType = t;
    } else
    // - If `T <: S` then the type of `E` is `T`
    if (typeSchemaEnvironment.isSubtypeOf(t, s)) {
      inferredType = t;
    } else
    // - Otherwise, if `T1 <: S` and `T2 <: S`, then the type of `E` is `S`
    if (typeSchemaEnvironment.isSubtypeOf(t1, s) &&
        typeSchemaEnvironment.isSubtypeOf(t2, s)) {
      inferredType = s;
    } else
    // - Otherwise, the type of `E` is `T`
    {
      inferredType = t;
    }

    Expression replacement = extern.createConditionalExpression(
      condition,
      then,
      otherwise,
      staticType: inferredType,
      fileOffset: node.fileOffset,
    );
    storeExpressionInfo(
      replacement,
      flowAnalysis.conditional_end(
        new SharedTypeView(inferredType),
        getExpressionInfo(otherwise),
        new SharedTypeView(otherwiseResult.inferredType),
      ),
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitInternalConstructorInvocation(
    InternalConstructorInvocation node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    TypeArguments? typeArguments = node.typeArguments;
    ActualArguments arguments = node.arguments;
    bool hasInferredTypeArguments = typeArguments == null;
    FunctionType functionType = node.target.function.computeThisFunctionType(
      Nullability.nonNullable,
    );
    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      new InvocationTargetFunctionType(functionType),
      typeArguments,
      arguments,
      isConst: node.isConst,
      staticTarget: node.target,
    );
    if (hasInferredTypeArguments) {
      problemReporting.checkBoundsInConstructorInvocation(
        libraryFeatures: libraryFeatures,
        constructor: node.target,
        explicitOrInferredTypeArguments: result.typeArguments,
        typeEnvironment: typeSchemaEnvironment,
        fileUri: fileUri,
        fileOffset: node.fileOffset,
        hasInferredTypeArguments: true,
      );
    }
    Expression replacement = extern.createConstructorInvocation(
      node.target,
      createArgumentsFromInternalNode(
        result.typeArguments,
        result.positional,
        result.named,
        arguments,
      ),
      fileOffset: node.fileOffset,
      isConst: node.isConst,
    );
    return new ExpressionInferenceResult(
      result.inferredType,
      result.applyResult(replacement),
    );
  }

  StatementInferenceResult visitInternalContinueSwitchStatement(
    InternalContinueSwitchStatement node,
  ) {
    if (node.error != null) {
      return new StatementInferenceResult.single(
        extern.createExpressionStatement(
          extern.createInvalidExpression(
            node.error!.message,
            fileOffset: node.error!.fileOffset,
          ),
        ),
      );
    }
    flowAnalysis.handleContinue(node.target.body);
    ContinueSwitchStatement replacement = extern.createContinueSwitchStatement(
      fileOffset: node.fileOffset,
    );
    node.target.registerContinueSwitchStatement(replacement);
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitExtensionTearOff(
    ExtensionTearOff node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      node.tearOff,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    StaticInvocation replacement = extern.createStaticInvocation(
      node.tearOff,
      new Arguments([receiver], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    return instantiateTearOff(
      target.getReturnType(this),
      typeContext,
      replacement,
      tearOffNode: node,
    );
  }

  ExpressionInferenceResult visitExtensionGet(
    ExtensionGet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      node.getter,
      null,
      ClassMemberKind.Getter,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    DartType resultType = target.getGetterType(this);

    StaticInvocation replacement = extern.createStaticInvocation(
      node.getter,
      new Arguments([receiver], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    return new ExpressionInferenceResult(resultType, replacement);
  }

  ExpressionInferenceResult visitExtensionSet(
    ExtensionSet node,
    DartType typeContext,
  ) {
    ExtensionSetData data = computeExtensionSetData(
      extension: node.extension,
      knownTypeArguments: node.knownTypeArguments,
      receiver: node.receiver,
      extensionTypeArgumentOffset: node.extensionTypeArgumentOffset,
      setter: node.setter,
      isNullAware: node.isNullAware,
      fileOffset: node.fileOffset,
      internalNodeForTesting: node,
      valueNode: node.value,
    );
    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      data.valueType,
      isVoidAllowed: false,
    );
    return inferExtensionSet(
      data: data,
      valueResult: valueResult,
      forEffect: node.forEffect,
      fileOffset: node.fileOffset,
    );
  }

  @override
  ExtensionSetData computeExtensionSetData({
    required Extension extension,
    required List<DartType>? knownTypeArguments,
    required InternalExpression receiver,
    required int? extensionTypeArgumentOffset,
    required Procedure setter,
    required bool isNullAware,
    required int fileOffset,
    required InternalNode valueNode,
    InternalNode? internalNodeForTesting,
  }) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      extension,
      knownTypeArguments,
    );
    ExpressionInferenceResult receiverResult = inferExpression(
      receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression inferredReceiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      inferredReceiver = _createNonNullReceiver(
        inferredReceiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      extension,
      knownTypeArguments,
      receiverType,
      internalNodeForTesting: internalNodeForTesting,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: extensionTypeArgumentOffset ?? fileOffset,
      hasInferredTypeArguments: knownTypeArguments == null,
      typeParameters: extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      setter,
      null,
      ClassMemberKind.Setter,
      extensionTypeArguments,
    );

    inferredReceiver = ensureAssignable(
      extensionOnType,
      receiverType,
      inferredReceiver,
      assignedNode: receiver,
    );
    receiverType = extensionOnType;

    DartType valueType = target.getSetterType(this);
    return new ExtensionSetData(
      receiver: inferredReceiver,
      inferredReceiverType: receiverResult.inferredType,
      valueType: valueType,
      valueNode: valueNode,
      extensionTypeArguments: extensionTypeArguments,
      setter: setter,
    );
  }

  @override
  ExpressionInferenceResult inferExtensionSet({
    required ExtensionSetData data,
    required ExpressionInferenceResult valueResult,
    required bool forEffect,
    required int fileOffset,
  }) {
    Expression receiver = data.receiver;

    DartType valueType = data.valueType;
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: data.valueNode,
    );
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
    if (forEffect) {
      // No need for value variable.
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
    }

    SyntheticVariable? receiverVariable;
    if (forEffect || extern.isPureExpression(receiver)) {
      // No need for receiver variable.
    } else {
      receiverVariable = extern.createVariable(
        receiver,
        data.inferredReceiverType,
      );
      receiver = extern.createVariableGet(receiverVariable);
    }

    StaticInvocation assignment = extern.createStaticInvocation(
      data.setter,
      new Arguments([receiver, value], types: data.extensionTypeArguments)
        ..fileOffset = fileOffset,
      fileOffset: fileOffset,
    );

    Expression replacement;
    if (forEffect) {
      assert(receiverVariable == null);
      assert(valueVariable == null);
      replacement = assignment;
    } else {
      assert(valueVariable != null);
      SyntheticVariable assignmentVariable = extern.createVariable(
        assignment,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable!,
        body: extern.createLet(
          variable: assignmentVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
      if (receiverVariable != null) {
        replacement = extern.createLet(
          variable: receiverVariable,
          body: replacement,
        );
      }
    }
    replacement.fileOffset = fileOffset;
    return new ExpressionInferenceResult(valueResult.inferredType, replacement);
  }

  ExpressionInferenceResult visitExtensionPostIncDec(
    ExtensionIncDec node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (extern.isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
      readReceiver = extern.createVariableGet(receiverVariable);
      writeReceiver = extern.createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = new ExtensionAccessTarget(
      extensionOnType,
      node.getter,
      null,
      ClassMemberKind.Getter,
      extensionTypeArguments,
    );
    ObjectAccessTarget writeTarget = new ExtensionAccessTarget(
      extensionOnType,
      node.setter,
      null,
      ClassMemberKind.Setter,
      extensionTypeArguments,
    );

    StaticInvocation read = extern.createStaticInvocation(
      node.getter,
      new Arguments([readReceiver], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    Expression value = read;

    DartType readType = readTarget.getGetterType(this);
    DartType valueType = writeTarget.getSetterType(this);

    SyntheticVariable? valueVariable;
    if (!node.forEffect && node.isPost) {
      // For postfix expressions like `a = E(o).b++` that are not for effect we
      // need to store the read value as the result after assignment.
      valueVariable = extern.createVariable(value, valueType);
      value = extern.createVariableGet(valueVariable);
    }

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.fileOffset,
      contextType: valueType,
      left: value,
      leftType: readType,
      binaryName: node.isInc ? plusName : minusName,
      right: intern.createIntLiteral(value: 1, fileOffset: node.fileOffset),
      whyNotPromoted: null,
      invocationNode: node,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      isVoidAllowed: true,
      assignedNode: node,
    );
    DartType binaryType = binaryResult.inferredType;
    Expression binary = binaryResult.expression;

    SyntheticVariable? binaryVariable;
    if (!node.forEffect && !node.isPost) {
      // For prefix expressions like `a = ++E(o).b` we need to store the binary
      // result as the result after assignment.
      binaryVariable = extern.createVariable(binary, binaryType);
      binary = extern.createVariableGet(binaryVariable);
    }

    StaticInvocation write = extern.createStaticInvocation(
      node.setter,
      new Arguments([writeReceiver, binary], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    Expression replacement;
    if (valueVariable != null) {
      assert(binaryVariable == null);
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    } else if (binaryVariable != null) {
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: binaryVariable,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(binaryVariable),
        ),
      );
    } else {
      replacement = write;
    }
    if (receiverVariable != null) {
      replacement = extern.createLet(
        variable: receiverVariable,
        body: replacement,
      );
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(
      // For postfix expressions the expression type is the type of the read
      // value. For prefix expressions the expression type is the type of the
      // assignment value.
      node.isPost ? readType : binaryType,
      replacement,
    );
  }

  ExpressionInferenceResult visitExtensionGetterInvocation(
    ExtensionGetterInvocation node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      node.getter,
      null,
      ClassMemberKind.Getter,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    DartType getterType = target.getGetterType(this);

    StaticInvocation getterAccess = extern.createStaticInvocation(
      node.getter,
      new Arguments([receiver], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    return inferMethodInvocation(
      this,
      node.fileOffset,
      getterAccess,
      getterType,
      callName,
      node.typeArguments,
      node.arguments,
      typeContext,
      isExpressionInvocation: true,
      isImplicitCall: true,
      invocationNode: node,
    );
  }

  ExpressionInferenceResult visitExtensionMethodInvocation(
    ExtensionMethodInvocation node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      node.method,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    InvocationTargetType invocationTargetType = target.getFunctionType(this);
    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      invocationTargetType,
      node.typeArguments,
      node.arguments,
      staticTarget: node.method,
      receiverType: receiverType,
    );

    String targetName = node.name.text;
    if (!node.extension.isUnnamedExtension) {
      targetName = '${node.extension.name}.${targetName}';
    }
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: targetName,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.fileOffset,
      hasInferredTypeArguments: node.typeArguments == null,
      typeParameters: target.getTypeParameters(),
      explicitOrInferredTypeArguments: result.typeArguments,
    );

    StaticInvocation replacement = createExtensionInvocation(
      invocationOffset: node.fileOffset,
      argumentsOffset: node.arguments.fileOffset,
      target: target,
      receiver: receiver,
      explicitOrInferredTypeArguments: result.typeArguments,
      positionalArguments: result.positional,
      namedArguments: result.named,
    );

    return new ExpressionInferenceResult(
      result.inferredType,
      result.applyResult(replacement, extensionReceiverType: receiverType),
    );
  }

  ExpressionInferenceResult visitExtensionIfNullSet(
    ExtensionIfNullSet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    SyntheticVariable? receiverVariable;
    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiverVariable = extern.createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = nonNullReceiverType;
    } else if (!extern.isPureExpression(receiver)) {
      receiverVariable = extern.createVariable(receiver, receiverType);
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    Expression readReceiver;
    Expression writeReceiver;
    if (receiverVariable != null) {
      readReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    } else {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    }

    ExpressionInferenceResult readResult = _computePropertyGet(
      fileOffset: node.readOffset,
      receiver: readReceiver,
      receiverType: receiverType,
      propertyName: node.propertyName,
      typeContext: const UnknownType(),
      isThisReceiver: _isInternalThisExpression(node.receiver),
      accessNode: node,
    ).expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(read),
      new SharedTypeView(readType),
    );

    ObjectAccessTarget writeTarget = findInterfaceMember(
      receiverType,
      node.propertyName,
      receiver.fileOffset,
      isSetter: true,
      instrumented: true,
      includeExtensionMethods: true,
    );
    DartType writeContext = writeTarget.getSetterType(this);
    ExpressionInferenceResult rhsResult = inferExpression(
      node.rhs,
      writeContext,
      isVoidAllowed: true,
    );
    flowAnalysis.ifNullExpression_end();

    ExpressionInferenceResult writeResult = inferPropertySet(
      fileOffset: node.writeOffset,
      receiver: writeReceiver,
      receiverType: receiverType,
      propertyName: node.propertyName,
      writeTarget: writeTarget,
      writeContext: writeContext,
      valueResult: rhsResult,
      forEffect: node.forEffect,
      valueNode: node.rhs,
    );
    Expression write = writeResult.expression;
    DartType writeType = writeResult.inferredType;

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
      nonNullableReadType: nonNullableReadType,
      rhsType: writeType,
      typeContext: typeContext,
    );

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.a = b : null
      //
      Expression equalsNull = extern.createEqualsNull(
        read,
        fileOffset: node.fileOffset,
      );
      replacement = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        write,
        extern.createNullLiteral(fileOffset: node.fileOffset),
        computeNullable(inferredType),
      );
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      SyntheticVariable readVariable = extern.createVariable(read, readType);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(readVariable),
        fileOffset: node.fileOffset,
      );
      VariableGet variableGet = extern.createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        write,
        variableGet,
        inferredType,
      );
      replacement = extern.createLet(variable: readVariable, body: conditional);
    }
    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = extern.createLet(
          variable: receiverVariable,
          body: replacement,
        );
      }
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitExtensionCompoundSet(
    ExtensionCompoundSet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (extern.isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
      readReceiver = extern.createVariableGet(receiverVariable);
      writeReceiver = extern.createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = new ExtensionAccessTarget(
      receiverType,
      node.getter,
      null,
      ClassMemberKind.Getter,
      extensionTypeArguments,
    );

    DartType readType = readTarget.getGetterType(this);

    Expression read = new StaticInvocation(
      readTarget.member as Procedure,
      new Arguments(<Expression>[
        readReceiver,
      ], types: readTarget.receiverTypeArguments)..fileOffset = node.readOffset,
    )..fileOffset = node.readOffset;

    ObjectAccessTarget writeTarget = new ExtensionAccessTarget(
      receiverType,
      node.setter,
      null,
      ClassMemberKind.Setter,
      extensionTypeArguments,
    );

    DartType valueType = writeTarget.getSetterType(this);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.binaryOffset,
      contextType: valueType,
      left: read,
      leftType: readType,
      binaryName: node.binaryName,
      right: node.rhs,
      whyNotPromoted: null,
      invocationNode: node,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      isVoidAllowed: true,
      assignedNode: node,
    );
    Expression value = binaryResult.expression;

    SyntheticVariable? valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = extern.createVariable(value, valueType);
      value = extern.createVariableGet(valueVariable);
    }

    Expression write = new StaticInvocation(
      writeTarget.member as Procedure,
      new Arguments(
        <Expression>[writeReceiver, value],
        types: writeTarget.receiverTypeArguments,
      )..fileOffset = node.writeOffset,
    )..fileOffset = node.writeOffset;

    Expression replacement;
    if (node.forEffect) {
      assert(valueVariable == null);
      replacement = write;
    } else {
      assert(valueVariable != null);
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    if (receiverVariable != null) {
      replacement = extern.createLet(
        variable: receiverVariable,
        body: replacement,
      );
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(valueType, replacement);
  }

  ExpressionInferenceResult visitDeferredCheck(
    DeferredCheck node,
    DartType typeContext,
  ) {
    // Since the variable is not used in the body we don't need to type infer
    // it.  We can just type infer the body.
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      typeContext,
      isVoidAllowed: true,
    );

    Expression replacement = extern.createLet(
      variable: extern.createUninitializedVariable(
        type: const DynamicType(),
        isFinal: true,
        fileOffset: node.fileOffset,
      ),
      value: extern.createCheckLibraryIsLoaded(
        dependency: node.dependency,
        fileOffset: node.fileOffset,
      ),
      body: result.expression,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  /// If [continuableStatement] has any continue statements targeting it, the
  /// [body] of the [continuableStatement] is wrapped in a [LabeledStatement]
  /// and the [BreakStatement]s used to lower the continue statements are set to
  /// target the labeled statement.
  ///
  /// Returns [body] or the labeled statement wrapping [body] when necessary.
  Statement _handleContinues(
    InternalContinuableStatement continuableStatement,
    Statement body,
  ) {
    if (continuableStatement.continueStatements.isNotEmpty) {
      LabeledStatement continueLabel = extern.createLabeledStatement(
        body,
        fileOffset: continuableStatement.fileOffset,
      );
      for (BreakStatement continueStatement
          in continuableStatement.continueStatements) {
        continueStatement.target = continueLabel;
      }
      body = continueLabel;
    }
    return body;
  }

  /// If [breakableStatement] has any break statements targeting it, the
  /// [replacement] of the [breakableStatement] is wrapped in a
  /// [LabeledStatement] and the [BreakStatement]s used to lower the break
  /// statements are set to target the labeled statement.
  ///
  /// Returns [replacement] or the labeled statement wrapping [replacement] when
  /// necessary.
  Statement _handleBreaks(
    InternalBreakableStatement breakableStatement,
    Statement replacement,
  ) {
    if (breakableStatement.breakStatements.isNotEmpty) {
      LabeledStatement breakLabel = extern.createLabeledStatement(
        replacement,
        fileOffset: breakableStatement.fileOffset,
      );
      for (BreakStatement breakStatement
          in breakableStatement.breakStatements) {
        breakStatement.target = breakLabel;
      }
      replacement = breakLabel;
    }
    return replacement;
  }

  StatementInferenceResult visitInternalDoStatement(InternalDoStatement node) {
    flowAnalysis.doStatement_bodyBegin(node);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;

    body = _handleContinues(node, body);

    flowAnalysis.doStatement_conditionBegin();
    InterfaceType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      boolType,
      isVoidAllowed: true,
    );
    Expression condition = ensureAssignableResult(
      boolType,
      conditionResult,
      assignedNode: node.condition,
    ).expression;
    flowAnalysis.doStatement_end(getExpressionInfo(condition));
    Statement replacement = extern.createDoStatement(
      body,
      condition,
      fileOffset: node.fileOffset,
    );

    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);

    replacement = _handleBreaks(node, replacement);

    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitInternalDoubleLiteral(
    InternalDoubleLiteral node,
    DartType typeContext,
  ) {
    Expression replacement = extern.createDoubleLiteral(
      node.value,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(
      coreTypes.doubleRawType(Nullability.nonNullable),
      replacement,
    );
  }

  StatementInferenceResult visitInternalEmptyStatement(
    InternalEmptyStatement node,
  ) {
    Statement replacement = extern.createEmptyStatement(
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  StatementInferenceResult visitInternalExpressionStatement(
    InternalExpressionStatement node,
  ) {
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      const UnknownType(),
      isVoidAllowed: true,
      forEffect: true,
    );
    Statement replacement = extern.createExpressionStatement(
      result.expression,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitFactoryConstructorInvocation(
    FactoryConstructorInvocation node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);

    bool hasInferredTypeArguments = node.typeArguments == null;

    FunctionType functionType = node.target.function.computeThisFunctionType(
      Nullability.nonNullable,
    );

    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      new InvocationTargetFunctionType(functionType),
      node.typeArguments,
      node.arguments,
      isConst: node.isConst,
      staticTarget: node.target,
    );
    if (hasInferredTypeArguments) {
      problemReporting.checkBoundsInFactoryInvocation(
        libraryFeatures: libraryFeatures,
        factory: node.target,
        explicitOrInferredTypeArguments: result.typeArguments,
        typeEnvironment: typeSchemaEnvironment,
        fileUri: fileUri,
        fileOffset: node.fileOffset,
        hasInferredTypeArguments: true,
      );
    }
    Expression resolvedExpression = _resolveRedirectingFactoryTarget(
      target: node.target,
      explicitOrInferredTypeArguments: result.typeArguments,
      positional: result.positional,
      named: result.named,
      arguments: node.arguments,
      fileOffset: node.fileOffset,
      isConst: node.isConst,
      hasInferredTypeArguments: hasInferredTypeArguments,
    )!;
    Expression resultExpression = result.applyResult(resolvedExpression);

    return new ExpressionInferenceResult(result.inferredType, resultExpression);
  }

  /// Return an [Expression] resolving the argument invocation.
  ///
  /// The arguments specify the [StaticInvocation] whose `.target` is
  /// [target], `.arguments` is [arguments], `.fileOffset` is [fileOffset],
  /// and `.isConst` is [isConst].
  /// Returns null if the invocation can't be resolved.
  Expression? _resolveRedirectingFactoryTarget({
    required Procedure target,
    required List<DartType> explicitOrInferredTypeArguments,
    required List<Expression> positional,
    required List<NamedExpression> named,
    required ActualArguments arguments,
    required int fileOffset,
    required bool isConst,
    required bool hasInferredTypeArguments,
  }) {
    Expression replacementNode;

    _RedirectionTarget redirectionTarget = _getRedirectionTarget(target);
    Member resolvedTarget = redirectionTarget.target;
    if (redirectionTarget.typeArguments.any((type) => type is UnknownType)) {
      return null;
    }

    RedirectingFactoryTarget? redirectingFactoryTarget =
        resolvedTarget.function?.redirectingFactoryTarget;
    if (redirectingFactoryTarget != null) {
      // If the redirection target is itself a redirecting factory, it means
      // that it is unresolved.
      assert(redirectingFactoryTarget.isError);
      String errorMessage = redirectingFactoryTarget.errorMessage!;
      replacementNode = new InvalidExpression(errorMessage)
        ..fileOffset = fileOffset;
    } else {
      Substitution substitution = Substitution.fromPairs(
        target.function.typeParameters,
        explicitOrInferredTypeArguments,
      );
      List<DartType> typeArguments = [];
      for (int i = 0; i < redirectionTarget.typeArguments.length; i++) {
        DartType typeArgument = substitution.substituteType(
          redirectionTarget.typeArguments[i],
        );
        typeArguments.add(typeArgument);
      }

      replacementNode = _buildRedirectingFactoryTargetInvocation(
        redirectingFactoryTarget: target.reference != resolvedTarget.reference
            ? target
            : null,
        effectiveTarget: resolvedTarget,
        explicitOrInferredTypeArguments: typeArguments,
        positional: positional,
        named: named,
        arguments: arguments,
        isConst: isConst,
        fileOffset: fileOffset,
        hasInferredTypeArguments: hasInferredTypeArguments,
      );
    }
    return replacementNode;
  }

  Expression _buildRedirectingFactoryTargetInvocation({
    required Procedure? redirectingFactoryTarget,
    required Member effectiveTarget,
    required List<DartType> explicitOrInferredTypeArguments,
    required List<Expression> positional,
    required List<NamedExpression> named,
    required ActualArguments arguments,
    required bool isConst,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    ErrorText? errorText = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: effectiveTarget,
      explicitTypeArguments: null,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: fileUri,
    );
    if (errorText != null) {
      // Coverage-ignore-block(suite): Not run.
      return extern.createInvalidExpressionFromErrorText(errorText);
    }
    if (effectiveTarget is Constructor) {
      if (isConst && !effectiveTarget.isConst) {
        // Coverage-ignore-block(suite): Not run.
        return extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonConstConstructor,
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: noLength,
          ),
        );
      }
      problemReporting.checkBoundsInConstructorInvocation(
        libraryFeatures: libraryFeatures,
        constructor: effectiveTarget,
        explicitOrInferredTypeArguments: explicitOrInferredTypeArguments,
        typeEnvironment: typeSchemaEnvironment,
        fileUri: fileUri,
        fileOffset: fileOffset,
        hasInferredTypeArguments: hasInferredTypeArguments,
      );
      ConstructorInvocation constructorInvocation = new ConstructorInvocation(
        effectiveTarget,
        createArgumentsFromInternalNode(
          explicitOrInferredTypeArguments,
          positional,
          named,
          arguments,
        ),
        isConst: isConst,
      )..fileOffset = fileOffset;
      if (redirectingFactoryTarget != null) {
        return new RedirectingFactoryInvocation(
          redirectingFactoryTarget,
          constructorInvocation,
        )..fileOffset = fileOffset;
      } else {
        return constructorInvocation;
      }
    } else {
      Procedure procedure = effectiveTarget as Procedure;
      if (isConst && !procedure.isConst) {
        // Coverage-ignore-block(suite): Not run.
        if (procedure.isExtensionTypeMember) {
          // Both generative constructors and factory constructors from
          // extension type declarations are encoded as procedures so we use
          // the message for non-const constructors here.
          return extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nonConstConstructor,
              fileUri: fileUri,
              fileOffset: fileOffset,
              length: noLength,
            ),
          );
        } else {
          return extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nonConstFactory,
              fileUri: fileUri,
              fileOffset: fileOffset,
              length: noLength,
            ),
          );
        }
      }
      problemReporting.checkBoundsInFactoryInvocation(
        libraryFeatures: libraryFeatures,
        factory: effectiveTarget,
        explicitOrInferredTypeArguments: explicitOrInferredTypeArguments,
        typeEnvironment: typeSchemaEnvironment,
        fileUri: fileUri,
        fileOffset: fileOffset,
        hasInferredTypeArguments: hasInferredTypeArguments,
      );
      StaticInvocation factoryInvocation = new StaticInvocation(
        effectiveTarget,
        createArgumentsFromInternalNode(
          explicitOrInferredTypeArguments,
          positional,
          named,
          arguments,
        ),
        isConst: isConst,
      )..fileOffset = fileOffset;
      if (redirectingFactoryTarget != null) {
        return new RedirectingFactoryInvocation(
          redirectingFactoryTarget,
          factoryInvocation,
        )..fileOffset = fileOffset;
      } else {
        return factoryInvocation;
      }
    }
  }

  /// Ensure that the containing library of the [member] has been loaded.
  ///
  /// This is for instance important for lazy dill library builders where this
  /// method has to be called to ensure that
  /// a) The library has been fully loaded (and for instance any internal
  ///    transformation needed has been performed); and
  /// b) The library is correctly marked as being used to allow for proper
  ///    'dependency pruning'.
  void _ensureLoaded(Member? member) {
    if (member == null) return;
    Library ensureLibraryLoaded = member.enclosingLibrary;
    LibraryBuilder? builder =
        libraryBuilder.loader.lookupLoadedLibraryBuilder(
          ensureLibraryLoaded.importUri,
        ) ??
        // Coverage-ignore(suite): Not run.
        libraryBuilder.loader.target.dillTarget.loader.lookupLibraryBuilder(
          ensureLibraryLoaded.importUri,
        );
    if (builder is DillLibraryBuilder) {
      builder.ensureLoaded();
    }
  }

  _RedirectionTarget _getRedirectionTarget(Procedure factory) {
    List<DartType> typeArguments = new List<DartType>.generate(
      factory.function.typeParameters.length,
      (int i) {
        return new TypeParameterType.withDefaultNullability(
          factory.function.typeParameters[i],
        );
      },
      growable: true,
    );

    // Cyclic factories are detected earlier, so we're guaranteed to
    // reach either a non-redirecting factory or an error eventually.
    Member target = factory;
    for (;;) {
      RedirectingFactoryTarget? redirectingFactoryTarget =
          target.function?.redirectingFactoryTarget;
      if (redirectingFactoryTarget == null ||
          redirectingFactoryTarget.isError) {
        return new _RedirectionTarget(target, typeArguments);
      }
      Member nextMember = redirectingFactoryTarget.target!;
      _ensureLoaded(nextMember);
      List<DartType>? nextTypeArguments =
          redirectingFactoryTarget.typeArguments;
      if (nextTypeArguments != null) {
        Substitution sub = Substitution.fromPairs(
          target.function!.typeParameters,
          typeArguments,
        );
        typeArguments = new List<DartType>.generate(nextTypeArguments.length, (
          int i,
        ) {
          return sub.substituteType(nextTypeArguments[i]);
        }, growable: true);
      } else {
        // Coverage-ignore-block(suite): Not run.
        typeArguments = <DartType>[];
      }
      target = nextMember;
    }
  }

  /// Returns the function type of [constructor] when called through [typedef].
  FunctionType _computeAliasedConstructorFunctionType(
    Constructor constructor,
    Typedef typedef,
  ) {
    ensureMemberType(constructor);
    FunctionNode function = constructor.function;
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> classTypeParametersCopy = new List.of(
      constructor.enclosingClass.typeParameters,
    );
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typedef.typeParameters);
    List<StructuralParameter> typedefTypeParametersCopy =
        freshTypeParameters.freshTypeParameters;
    List<DartType> asTypeArguments = freshTypeParameters.freshTypeArguments;
    final TypedefType typedefType = new TypedefType(
      typedef,
      libraryBuilder.library.nonNullable,
      asTypeArguments,
    );
    DartType unaliasedTypedef = typedefType.unalias;
    assert(
      unaliasedTypedef is InterfaceType,
      "[typedef] is assumed to resolve to an interface type",
    );
    InterfaceType targetType = unaliasedTypedef as InterfaceType;
    Substitution substitution = Substitution.fromPairs(
      classTypeParametersCopy,
      targetType.typeArguments,
    );
    List<DartType> positional = function.positionalParameters
        .map(
          (PositionalParameter decl) => substitution.substituteType(decl.type),
        )
        .toList(growable: false);
    List<NamedType> named = function.namedParameters
        .map(
          (NamedParameter decl) => new NamedType(
            decl.parameterName,
            substitution.substituteType(decl.type),
            isRequired: decl.isRequired,
          ),
        )
        .toList(growable: false);
    named.sort();
    return new FunctionType(
      positional,
      unaliasedTypedef,
      libraryBuilder.library.nonNullable,
      namedParameters: named,
      typeParameters: typedefTypeParametersCopy,
      requiredParameterCount: function.requiredParameterCount,
    );
  }

  ExpressionInferenceResult visitTypeAliasedConstructorInvocation(
    TypeAliasedConstructorInvocation node,
    DartType typeContext,
  ) {
    assert(node.typeArguments == null);
    ensureMemberType(node.target);

    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType = _computeAliasedConstructorFunctionType(
      node.target,
      typedef,
    );
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      new InvocationTargetFunctionType(calleeType),
      node.typeArguments,
      node.arguments,
      isConst: node.isConst,
      staticTarget: node.target,
    );

    Expression resolvedExpression =
        _unaliasSingleTypeAliasedConstructorInvocation(
          node,
          result.typeArguments,
          result.positional,
          result.named,
        );
    Expression resultingExpression = result.applyResult(resolvedExpression);

    return new ExpressionInferenceResult(
      result.inferredType,
      resultingExpression,
    );
  }

  Expression _unaliasSingleTypeAliasedConstructorInvocation(
    TypeAliasedConstructorInvocation node,
    List<DartType> explicitOrInferredTypeArguments,
    List<Expression> positional,
    List<NamedExpression> named,
  ) {
    DartType aliasedType = new TypedefType(
      node.typeAliasBuilder.typedef,
      Nullability.nonNullable,
      explicitOrInferredTypeArguments,
    );
    problemReporting.checkBoundsInType(
      libraryFeatures: libraryFeatures,
      type: aliasedType,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.fileOffset,
      allowSuperBounded: false,
      hasInferredTypeArguments: node.typeArguments == null,
    );
    DartType unaliasedType = aliasedType.unalias;
    List<DartType>? invocationTypeArguments = null;
    if (unaliasedType is InterfaceType) {
      invocationTypeArguments = unaliasedType.typeArguments.toList();
    }
    Arguments invocationArguments = new Arguments(
      positional,
      types: invocationTypeArguments,
      named: named,
    )..fileOffset = node.arguments.fileOffset;
    return new ConstructorInvocation(
      node.target,
      invocationArguments,
      isConst: node.isConst,
    );
  }

  /// Returns the function type of [factory] when called through [typedef].
  FunctionType _computeAliasedFactoryFunctionType(
    Procedure factory,
    Typedef typedef,
  ) {
    assert(
      factory.isFactory || factory.isExtensionTypeMember,
      "Only run this method on a factory: $factory",
    );
    ensureMemberType(factory);
    FunctionNode function = factory.function;
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> classTypeParametersCopy = new List.of(
      function.typeParameters,
    );
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typedef.typeParameters);
    List<StructuralParameter> typedefTypeParametersCopy =
        freshTypeParameters.freshTypeParameters;
    List<DartType> asTypeArguments = freshTypeParameters.freshTypeArguments;
    final TypedefType typedefType = new TypedefType(
      typedef,
      libraryBuilder.library.nonNullable,
      asTypeArguments,
    );
    DartType unaliasedTypedef = typedefType.unalias;
    assert(
      unaliasedTypedef is TypeDeclarationType,
      "[typedef] is assumed to resolve to a type declaration type",
    );
    TypeDeclarationType targetType = unaliasedTypedef as TypeDeclarationType;
    Substitution substitution = Substitution.fromPairs(
      classTypeParametersCopy,
      targetType.typeArguments,
    );
    List<DartType> positional = function.positionalParameters
        .map(
          (PositionalParameter decl) => substitution.substituteType(decl.type),
        )
        .toList(growable: false);
    List<NamedType> named = function.namedParameters
        .map(
          // Coverage-ignore(suite): Not run.
          (NamedParameter decl) => new NamedType(
            decl.parameterName,
            substitution.substituteType(decl.type),
            isRequired: decl.isRequired,
          ),
        )
        .toList(growable: false);
    named.sort();
    return new FunctionType(
      positional,
      unaliasedTypedef,
      libraryBuilder.library.nonNullable,
      namedParameters: named,
      typeParameters: typedefTypeParametersCopy,
      requiredParameterCount: function.requiredParameterCount,
    );
  }

  ExpressionInferenceResult visitTypeAliasedFactoryInvocation(
    TypeAliasedFactoryInvocation node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    assert(node.typeArguments == null);

    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType = _computeAliasedFactoryFunctionType(
      node.target,
      typedef,
    );
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      new InvocationTargetFunctionType(calleeType),
      node.typeArguments,
      node.arguments,
      isConst: node.isConst,
      staticTarget: node.target,
    );

    Expression resolvedExpression = _unaliasSingleTypeAliasedFactoryInvocation(
      node,
      result.typeArguments,
      result.positional,
      result.named,
    )!;
    Expression resultExpression = result.applyResult(resolvedExpression);

    return new ExpressionInferenceResult(result.inferredType, resultExpression);
  }

  Expression? _unaliasSingleTypeAliasedFactoryInvocation(
    TypeAliasedFactoryInvocation node,
    List<DartType> explicitOrInferredTypeArguments,
    List<Expression> positional,
    List<NamedExpression> named,
  ) {
    bool hasInferredTypeArguments = node.typeArguments == null;
    DartType aliasedType = new TypedefType(
      node.typeAliasBuilder.typedef,
      Nullability.nonNullable,
      explicitOrInferredTypeArguments,
    );
    problemReporting.checkBoundsInType(
      libraryFeatures: libraryFeatures,
      type: aliasedType,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.fileOffset,
      allowSuperBounded: false,
      hasInferredTypeArguments: hasInferredTypeArguments,
    );
    DartType unaliasedType = aliasedType.unalias;
    List<DartType>? invocationTypeArguments = null;
    if (unaliasedType is TypeDeclarationType) {
      invocationTypeArguments = unaliasedType.typeArguments.toList();
    }
    return _resolveRedirectingFactoryTarget(
      target: node.target,
      explicitOrInferredTypeArguments:
          invocationTypeArguments ?? // Coverage-ignore(suite): Not run.
          [],
      positional: positional,
      named: named,
      arguments: node.arguments,
      fileOffset: node.fileOffset,
      isConst: node.isConst,
      hasInferredTypeArguments: hasInferredTypeArguments,
    );
  }

  InitializerInferenceResult visitInternalFieldInitializer(
    InternalFieldInitializer node,
  ) {
    DartType fieldType = node.field.type;
    fieldType = _constructorContext!.substituteFieldType(fieldType);
    ExpressionInferenceResult initializerResult = inferExpression(
      node.value,
      fieldType,
      isVoidAllowed: true,
    );
    Expression initializer = ensureAssignableResult(
      fieldType,
      initializerResult,
      fileOffset: node.fileOffset,
      isVoidAllowed: true,
      assignedNode: node.value,
    ).expression;
    return new SuccessfulInitializerInferenceResult(
      extern.createFieldInitializer(
        node.field,
        initializer,
        fileOffset: node.fileOffset,
        isSynthetic: node.isSynthetic,
      ),
    );
  }

  @override
  ExpressionInferenceResult inferForInIterable(
    InternalExpression iterable,
    DartType elementType, {
    required bool isAsync,
  }) {
    Class iterableClass = isAsync
        ? coreTypes.streamClass
        : coreTypes.iterableClass;
    DartType context = wrapType(
      elementType,
      iterableClass,
      Nullability.nonNullable,
    );
    ExpressionInferenceResult iterableResult = inferExpression(
      iterable,
      context,
      isVoidAllowed: false,
    );
    DartType iterableType = iterableResult.inferredType;
    Expression inferredIterable = iterableResult.expression;
    DartType inferredExpressionType = iterableType.nonTypeParameterBound;
    inferredIterable = ensureAssignable(
      wrapType(const DynamicType(), iterableClass, Nullability.nonNullable),
      inferredExpressionType,
      inferredIterable,
      errorTemplate: diag.forInLoopTypeNotIterable,
      assignedNode: iterable,
    );
    DartType inferredType = const DynamicType();
    if (inferredExpressionType is TypeDeclarationType) {
      // TODO(johnniwinther): Should we use the type of
      //  `iterable.iterator.current` instead?
      List<DartType>? supertypeArguments = hierarchyBuilder
          .getTypeArgumentsAsInstanceOf(inferredExpressionType, iterableClass);
      if (supertypeArguments != null) {
        inferredType = supertypeArguments[0];
      }
    }
    return new ExpressionInferenceResult(inferredType, inferredIterable);
  }

  @override
  PatternForInData inferPatternForInHeader({
    required InternalNode node,
    required InternalPattern pattern,
    required InternalExpression iterable,
    required bool isAsync,
    required int inOffset,
  }) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternForInResult<InvalidExpression> result = analyzePatternForIn(
      node: node,
      hasAwait: isAsync,
      pattern: pattern,
      expression: iterable,
      dispatchBody: () {},
    );
    DartType matchedValueType = result.elementType.unwrapTypeView();
    if (result.patternForInExpressionIsNotIterableError != null) {
      assert(
        libraryBuilder.loader.assertProblemReportedElsewhere(
          "InferenceVisitorImpl._handlePatternForIn: "
          "can't infer expression in a for-in pattern.",
          expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding,
        ),
      );
    }

    assert(
      checkStack(node, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]),
    );

    Pattern outputPattern = popRewrite() as Pattern;

    Expression inferredIterable = popRewrite() as Expression;

    DartType elementType = result.elementType.unwrapTypeView();
    inferredIterable = ensureAssignable(
      wrapType(
        const DynamicType(),
        isAsync ? coreTypes.streamClass : coreTypes.iterableClass,
        Nullability.nonNullable,
      ),
      result.expressionType.unwrapTypeView(),
      inferredIterable,
      errorTemplate: diag.forInLoopTypeNotIterable,
      assignedNode: iterable,
    );

    DeclaredVariable loopVariable = extern.createUninitializedVariable(
      type: elementType,
      fileOffset: node.fileOffset,
      isFinal: true,
    );

    return new PatternForInData(
      loopVariable: loopVariable,
      iterable: inferredIterable,
      computePatternVariableDeclaration: () =>
          extern.createPatternVariableDeclaration(
            pattern: outputPattern,
            initializer: extern.createVariableGet(
              loopVariable,
              fileOffset: inOffset,
            ),
            isFinal: false,
            fileOffset: inOffset,
            matchedValueType: matchedValueType,
          ),
    );
  }

  StatementInferenceResult visitInternalForInStatement(
    InternalForInStatement node,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
    }

    ForInHeaderResult headerResult = node.element.inferForInHeader(
      this,
      node: node,
      iterable: node.iterable,
      isAsync: node.isAsync,
      forOffset: node.fileOffset,
    );
    DeclaredVariable variable = headerResult.loopVariable;
    Expression iterable = headerResult.iterable;

    flowAnalysis.forEach_bodyBegin(node);

    InternalVariable? declaredVariable = headerResult.declaredVariable;
    if (declaredVariable != null) {
      flowAnalysis.declare(
        declaredVariable,
        new SharedTypeView(declaredVariable.type),
        initialized: true,
      );

      if (isClosureContextLoweringEnabled) {
        _contextAllocationStrategy.handleDeclarationOfVariable(
          declaredVariable.astVariable,
          captureKind: captureKindForVariable(declaredVariable),
        );
      }
    }
    if (isClosureContextLoweringEnabled) {
      if (declaredVariable?.astVariable != variable) {
        // [variable] is synthesized.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          variable,
          captureKind: CaptureKind.notCaptured,
        );
      }
    }

    ForInEncoding encoding = headerResult.computeEncoding();

    StatementInferenceResult bodyResult = inferStatement(node.body);

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();

    Statement body = bodyResult.statement;

    body = _handleContinues(node, body);

    Statement? bodyPrologue = encoding.bodyPrologue;
    if (bodyPrologue != null) {
      body = extern.combineStatements(bodyPrologue, body);
    }
    ForInStatement forInStatement =
        new ForInStatement(variable, iterable, body, isAsync: node.isAsync)
          ..fileOffset = node.fileOffset
          ..bodyOffset = node.bodyOffset;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      forInStatement.scope = scopeProviderInfo.scope;
    }
    Statement result = forInStatement;

    result = _handleBreaks(node, result);

    InvalidExpression? preLoopError = encoding.preLoopError;
    if (preLoopError != null) {
      result = extern.createBlock([
        extern.createExpressionStatement(preLoopError),
        result,
      ], fileOffset: node.fileOffset);
    }
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, forInStatement);
    return new StatementInferenceResult.single(result);
  }

  StatementInferenceResult visitInternalForStatement(
    InternalForStatement node,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
    }
    List<VariableDeclaration> variables = new List.filled(
      node.variables.length,
      dummyVariableDeclaration,
      growable: true,
    );
    for (int index = 0; index < node.variables.length; index++) {
      InternalVariableDeclaration variableDeclaration = node.variables[index];
      InternalDeclaredVariable variable = variableDeclaration.variable;
      if (variable.cosmeticName == null) {
        Expression? initializer;
        if (variableDeclaration.initializer != null) {
          ExpressionInferenceResult result = inferExpression(
            variableDeclaration.initializer!,
            const UnknownType(),
            isVoidAllowed: true,
          );
          initializer = result.expression;
          variable.type = result.inferredType;
        }
        variables[index] = extern.createVariableDeclaration(
          variable.astVariable,
          initializer: initializer,
          fileOffset: variableDeclaration.fileOffset,
        );
      } else {
        VariableDeclarationInferenceResult variableResult =
            inferVariableDeclaration(
              variableDeclaration,
              forLoopVariable: true,
            );
        switch (variableResult) {
          case DirectVariableDeclarationInferenceResult():
            variables[index] = variableResult.declaration;
          // Coverage-ignore(suite): Not run.
          case EffectVariableDeclarationInferenceResult():
          case LateVariableDeclarationInferenceResult():
            throw new UnsupportedError(
              "Unexpected variable declaration change.",
            );
        }
      }
    }
    flowAnalysis.for_conditionBegin(node);
    Expression? condition;
    if (node.condition != null) {
      InterfaceType expectedType = coreTypes.boolRawType(
        Nullability.nonNullable,
      );
      ExpressionInferenceResult conditionResult = inferExpression(
        node.condition!,
        expectedType,
        isVoidAllowed: true,
      );
      condition = ensureAssignableResult(
        expectedType,
        conditionResult,
        assignedNode: node.condition!,
      ).expression;
    }

    flowAnalysis.for_bodyBegin(node, switch (condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => getExpressionInfo(condition),
    });
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;

    body = _handleContinues(node, body);

    flowAnalysis.for_updaterBegin();

    List<Expression> updates = new List.filled(
      node.updates.length,
      dummyExpression,
      growable: true,
    );
    for (int index = 0; index < node.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
        node.updates[index],
        const UnknownType(),
        isVoidAllowed: true,
      );
      updates[index] = updateResult.expression;
    }
    flowAnalysis.for_end();
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      scope = scopeProviderInfo.scope;
    }
    Statement replacement = extern.createForStatement(
      variables: variables,
      condition: condition,
      updates: updates,
      body: body,
      scope: scope,
      fileOffset: node.fileOffset,
    );

    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);

    replacement = _handleBreaks(node, replacement);

    return new StatementInferenceResult.single(replacement);
  }

  LocalFunctionResult _visitInternalFunctionNode(
    InternalFunctionNode node, {
    required DartType? typeContext,
    required DartType? returnType,
    required int implicitReturnOffset,
  }) {
    return inferLocalFunction(
      this,
      node,
      typeContext: typeContext,
      implicitReturnOffset: implicitReturnOffset,
      returnType: returnType,
    );
  }

  StatementInferenceResult visitInternalFunctionDeclaration(
    InternalFunctionDeclaration node,
  ) {
    InternalFunctionNode function = node.function;
    ScopeProviderInfo? scopeProviderInfo;
    List<VariableContext>? capturedContexts;
    if (isClosureContextLoweringEnabled) {
      _contextAllocationStrategy.handleDeclarationOfVariable(
        node.variable.astVariable,
        captureKind: captureKindForVariable(node.variable),
      );
      capturedContexts = _contextAllocationStrategy
          .computeCapturedVariableContexts(_capturedVariablesForNode(node));
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
      _contextAllocationStrategy.handleDeclarationsOfParameters([
        for (InternalPositionalParameter positionalParameter
            in node.function.positionalParameters)
          // Coverage-ignore(suite): Not run.
          new VariableWithCaptureKind(
            positionalParameter.astVariable,
            captureKindForVariable(positionalParameter),
          ),
        for (InternalNamedParameter namedParameter
            in node.function.namedParameters)
          // Coverage-ignore(suite): Not run.
          new VariableWithCaptureKind(
            namedParameter.astVariable,
            captureKindForVariable(namedParameter),
          ),
      ]);
    }

    bool oldInTryOrLocalFunction = _inTryOrLocalFunction;
    _inTryOrLocalFunction = true;
    InternalLocalFunctionVariable variable = node.variable;
    flowAnalysis.functionExpression_begin(node);
    _returnContexts.push(const StandardReturnContext());
    LocalFunctionResult localFunctionResult = _visitInternalFunctionNode(
      function,
      typeContext: null,
      returnType: function.returnType,
      implicitReturnOffset: node.fileOffset,
    );
    FunctionType inferredType = localFunctionResult.computeInferredType(
      function,
    );
    if (dataForTesting != null &&
        // Coverage-ignore(suite): Not run.
        node.hasImplicitReturnType) {
      // Coverage-ignore-block(suite): Not run.
      dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
          inferredType.returnType;
    }
    variable.type = inferredType;
    flowAnalysis.declare(
      variable,
      new SharedTypeView(variable.type),
      initialized: true,
    );
    flowAnalysis.functionExpression_end();
    _returnContexts.pop();
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      scope = scopeProviderInfo.scope;
    }
    FunctionDeclaration replacement = extern.createFunctionDeclaration(
      variable: variable.astVariable,
      function: localFunctionResult.computeFunctionNode(
        function: function,
        scope: scope,
        capturedContexts: capturedContexts,
      ),
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(variable, variable.astVariable);
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitInternalFunctionExpression(
    InternalFunctionExpression node,
    DartType typeContext,
  ) {
    InternalFunctionNode function = node.function;
    ScopeProviderInfo? scopeProviderInfo;
    List<VariableContext>? capturedContexts;
    if (isClosureContextLoweringEnabled) {
      capturedContexts = _contextAllocationStrategy
          .computeCapturedVariableContexts(_capturedVariablesForNode(node));
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
      _contextAllocationStrategy.handleDeclarationsOfParameters([
        for (InternalPositionalParameter positionalParameter
            in function.positionalParameters)
          new VariableWithCaptureKind(
            positionalParameter.astVariable,
            captureKindForVariable(positionalParameter),
          ),
        for (InternalNamedParameter namedParameter in function.namedParameters)
          new VariableWithCaptureKind(
            namedParameter.astVariable,
            captureKindForVariable(namedParameter),
          ),
      ]);
    }

    bool oldInTryOrLocalFunction = _inTryOrLocalFunction;
    _inTryOrLocalFunction = true;
    flowAnalysis.functionExpression_begin(node);
    _returnContexts.push(const StandardReturnContext());
    LocalFunctionResult localFunctionResult = _visitInternalFunctionNode(
      function,
      typeContext: typeContext,
      returnType: function.returnType,
      implicitReturnOffset: node.fileOffset,
    );
    FunctionType inferredType = localFunctionResult.computeInferredType(
      function,
    );
    if (dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
          inferredType.returnType;
    }
    flowAnalysis.functionExpression_end();
    _returnContexts.pop();
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      scope = scopeProviderInfo.scope;
    }

    Expression replacement = extern.createFunctionExpression(
      localFunctionResult.computeFunctionNode(
        function: function,
        scope: scope,
        capturedContexts: capturedContexts,
      ),
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullExpression(
    IfNullExpression node,
    DartType typeContext,
  ) {
    // An if-null expression `E` of the form `e1 ?? e2` with context type `K` is
    // analyzed as follows:
    //
    // - Let `T1` be the type of `e1` inferred with context type `K?`.
    ExpressionInferenceResult lhsResult = inferExpression(
      node.left,
      computeNullable(typeContext),
      isVoidAllowed: false,
    );
    DartType t1 = lhsResult.inferredType;

    // This ends any shorting in `node.left`.
    Expression left = lhsResult.expression;

    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(left),
      new SharedTypeView(t1),
    );

    // - Let `T2` be the type of `e2` inferred with context type `J`, where:
    //   - If `K` is `_` or `dynamic`, `J = T1`.
    DartType j;
    if (typeContext is UnknownType || typeContext is DynamicType) {
      j = t1;
    } else
    //   - Otherwise, `J = K`.
    {
      j = typeContext;
    }
    ExpressionInferenceResult rhsResult = inferExpression(
      node.right,
      j,
      isVoidAllowed: true,
    );
    DartType t2 = rhsResult.inferredType;
    flowAnalysis.ifNullExpression_end();

    // - Let `T` be `UP(NonNull(T1), T2)`.
    DartType nonNullT1 = t1.toNonNull();
    DartType t = typeSchemaEnvironment.getStandardUpperBound(nonNullT1, t2);

    // - Let `S` be the greatest closure of `K`.
    DartType s = computeGreatestClosure(typeContext);

    DartType inferredType;
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled) {
      inferredType = t;
    } else
    // - If `T <: S`, then the type of `E` is `T`.
    if (typeSchemaEnvironment.isSubtypeOf(t, s)) {
      inferredType = t;
    } else
    // - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of `E` is
    //   `S`.
    if (typeSchemaEnvironment.isSubtypeOf(nonNullT1, s) &&
        typeSchemaEnvironment.isSubtypeOf(t2, s)) {
      inferredType = s;
    } else
    // - Otherwise, the type of `E` is `T`.
    {
      inferredType = t;
    }

    Expression replacement;
    if (_isInternalThisExpression(node.left)) {
      replacement = left;
    } else {
      SyntheticVariable variable = extern.createVariable(left, t1);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(variable),
        fileOffset: lhsResult.expression.fileOffset,
      );
      VariableGet variableGet = extern.createVariableGet(variable);
      if (!identical(nonNullT1, t1)) {
        variableGet.promotedType = nonNullT1;
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        rhsResult.expression,
        variableGet,
        inferredType,
      );
      replacement = extern.createLet(
        variable: variable,
        body: conditional,
        fileOffset: node.fileOffset,
      );
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  StatementInferenceResult visitInternalIfStatement(InternalIfStatement node) {
    flowAnalysis.ifStatement_conditionBegin();
    InterfaceType expectedType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      expectedType,
      isVoidAllowed: true,
    );
    Expression condition = ensureAssignableResult(
      expectedType,
      conditionResult,
      assignedNode: node.condition,
    ).expression;
    flowAnalysis.ifStatement_thenBegin(getExpressionInfo(condition), node);
    StatementInferenceResult thenResult = inferStatement(node.then);
    Statement then = thenResult.statement;
    Statement? otherwise;
    if (node.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      StatementInferenceResult otherwiseResult = inferStatement(
        node.otherwise!,
      );
      otherwise = otherwiseResult.statement;
    }
    flowAnalysis.ifStatement_end(node.otherwise != null);
    Statement replacement = extern.createIfStatement(
      condition,
      then,
      otherwise: otherwise,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  StatementInferenceResult visitInternalIfCaseStatement(
    InternalIfCaseStatement node,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    IfCaseStatementResult<InvalidExpression> analysisResult =
        analyzeIfCaseStatement(
          node,
          node.expression,
          node.patternGuard.pattern,
          node.patternGuard.guard,
          node.then,
          node.otherwise,
          {
            for (InternalVariable variable
                in node.patternGuard.pattern.declaredVariables)
              variable.cosmeticName!: variable,
          },
        );

    DartType matchedValueType = analysisResult.matchedExpressionType
        .unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* ifFalse = */ ValueKinds.StatementOrNull,
        /* ifTrue = */ ValueKinds.Statement,
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern = */ ValueKinds.Pattern,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    Statement? otherwise = popRewrite(NullValues.Statement) as Statement?;

    Statement then = popRewrite() as Statement;
    Expression? guard = popRewrite(NullValues.Expression) as Expression?;
    InvalidExpression? guardError = analysisResult.nonBooleanGuardError;
    if (guardError != null) {
      guard = guardError;
    } else if (guard != null) {
      if (analysisResult.guardType is DynamicType) {
        guard = _createImplicitAs(
          guard.fileOffset,
          guard,
          coreTypes.boolNonNullableRawType,
        );
      }
    }
    Pattern pattern = popRewrite() as Pattern;
    Expression expression = popRewrite() as Expression;

    assert(checkStack(node, stackBase, [/*empty*/]));

    return new StatementInferenceResult.single(
      extern.createIfCaseStatement(
        expression: expression,
        patternGuard: extern.createPatternGuard(
          pattern: pattern,
          guard: guard,
          fileOffset: node.patternGuard.fileOffset,
        ),
        then: then,
        otherwise: otherwise,
        matchedValueType: matchedValueType,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ExpressionInferenceResult visitInternalIntLiteral(
    InternalIntLiteral node,
    DartType typeContext,
  ) {
    if (isDoubleContext(typeContext)) {
      double? doubleValue = node.asDouble();
      if (doubleValue != null) {
        Expression replacement = new DoubleLiteral(doubleValue)
          ..fileOffset = node.fileOffset;
        DartType inferredType = coreTypes.doubleRawType(
          Nullability.nonNullable,
        );
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }
    Expression? error = checkWebIntLiteralsErrorIfUnexact(
      node.value,
      node.literal,
      node.fileOffset,
    );
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      return new ExpressionInferenceResult(const DynamicType(), error);
    }
    DartType inferredType = coreTypes.intRawType(Nullability.nonNullable);
    Expression result = extern.createIntLiteral(
      coreTypes,
      node.value,
      fileOffset: node.fileOffset,
      encodeForWeb: false,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result);
    return new ExpressionInferenceResult(inferredType, result);
  }

  ExpressionInferenceResult visitLargeIntLiteral(
    LargeIntLiteral node,
    DartType typeContext,
  ) {
    if (isDoubleContext(typeContext)) {
      double? doubleValue = node.asDouble();
      if (doubleValue != null) {
        Expression replacement = new DoubleLiteral(doubleValue)
          ..fileOffset = node.fileOffset;
        DartType inferredType = coreTypes.doubleRawType(
          Nullability.nonNullable,
        );
        libraryBuilder.loader.dataForTesting
        // Coverage-ignore(suite): Not run.
        ?.registerExternalNode(node, replacement);
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }

    int? intValue = node.asInt64();
    if (intValue == null) {
      Expression replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.integerLiteralIsOutOfRange.withArguments(
            literal: node.literal,
          ),
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: node.literal.length,
        ),
      );
      return new ExpressionInferenceResult(const DynamicType(), replacement);
    }
    Expression? error = checkWebIntLiteralsErrorIfUnexact(
      intValue,
      node.literal,
      node.fileOffset,
    );
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      return new ExpressionInferenceResult(const DynamicType(), error);
    }
    Expression replacement = extern.createIntLiteral(
      coreTypes,
      intValue,
      fileOffset: node.fileOffset,
      encodeForWeb: false,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    DartType inferredType = coreTypes.intRawType(Nullability.nonNullable);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitInternalIsExpression(
    InternalIsExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      const UnknownType(),
      isVoidAllowed: false,
    );
    Expression operand = operandResult.expression;
    Expression replacement = extern.createIsExpression(
      operand,
      node.type,
      fileOffset: node.fileOffset,
    );
    if (node.isNot) {
      replacement = extern.createNot(
        replacement,
        fileOffset: node.notFileOffset!,
      );
    }
    storeExpressionInfo(
      replacement,
      flowAnalysis.isExpression_end(
        getExpressionInfo(operand),
        /*isNot:*/ node.isNot,
        subExpressionType: new SharedTypeView(operandResult.inferredType),
        checkedType: new SharedTypeView(node.type),
      ),
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(
      coreTypes.boolRawType(Nullability.nonNullable),
      replacement,
    );
  }

  StatementInferenceResult visitInternalLabeledStatement(
    InternalLabeledStatement node,
  ) {
    flowAnalysis.labeledStatement_begin(node);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    flowAnalysis.labeledStatement_end();
    Statement body = bodyResult.statement;
    Statement replacement = _handleBreaks(node, body);
    return new StatementInferenceResult.single(replacement);
  }

  /// Performs checking of [element] after it has been determined whether the
  /// enclosing literal is a map literal.
  ///
  /// If [isMap] is `true`, the literal was determined to be a map literal.
  /// Otherwise it is a list or set literal.
  ///
  /// If [element] is (or contains) erroneous parts, an [InferredInvalidElement]
  /// is returned which replaces [element] in the lowered output. Otherwise
  /// `null` is returned.
  InferredElement? _checkElement({
    required InferredElement element,
    required bool isMap,
  }) {
    switch (element) {
      case InferredSpreadElement():
        DartType spreadType = element.expressionType;
        if (spreadType is DynamicType) {
          Expression expression;
          if (isMap) {
            expression = ensureAssignable(
              coreTypes.mapRawType(
                element.isNullAware
                    ? Nullability.nullable
                    : Nullability.nonNullable,
              ),
              spreadType,
              element.expression,
              assignedNode: element.expressionNode,
            );
          } else {
            expression = ensureAssignable(
              coreTypes.iterableRawType(
                element.isNullAware
                    ? Nullability.nullable
                    : Nullability.nonNullable,
              ),
              spreadType,
              element.expression,
              assignedNode: element.expressionNode,
            );
          }
          return new InferredSpreadElement(
            expression: expression,
            expressionNode: element.expressionNode,
            expressionType: element.expressionType,
            isNullAware: element.isNullAware,
            elementType: element.elementType,
            nodeForTesting: element.nodeForTesting,
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredIfElement():
        InferredElement? then = _checkElement(
          element: element.then,
          isMap: isMap,
        );
        InferredElement? otherwise;
        if (element.otherwise != null) {
          otherwise = _checkElement(element: element.otherwise!, isMap: isMap);
        }
        if (then != null || otherwise != null) {
          return new InferredIfElement(
            condition: element.condition,
            then: then ?? element.then,
            otherwise: otherwise ?? element.otherwise,
            nodeForTesting: element.nodeForTesting,
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredIfCaseElement():
        InferredElement? then = _checkElement(
          element: element.then,
          isMap: isMap,
        );
        InferredElement? otherwise;
        if (element.otherwise != null) {
          otherwise = _checkElement(element: element.otherwise!, isMap: isMap);
        }
        if (then != null || otherwise != null) {
          return new InferredIfCaseElement(
            expression: element.expression,
            patternGuard: element.patternGuard,
            matchedValueType: element.matchedValueType,
            then: then ?? element.then,
            otherwise: otherwise ?? element.otherwise,
            nodeForTesting: element.nodeForTesting,
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredForElement():
        InferredElement? body = _checkElement(
          element: element.body,
          isMap: isMap,
        );
        if (body != null) {
          return new InferredForElement(
            variables: element.variables,
            condition: element.condition,
            updates: element.updates,
            body: body,
            nodeForTesting: element.nodeForTesting,
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredPatternForElement():
        InferredElement? body = _checkElement(
          element: element.body,
          isMap: isMap,
        );
        if (body != null) {
          return new InferredPatternForElement(
            patternVariableDeclaration: element.patternVariableDeclaration,
            intermediateVariables: element.intermediateVariables,
            variables: element.variables,
            condition: element.condition,
            updates: element.updates,
            body: body,
            nodeForTesting: element.nodeForTesting,
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredForInElement():
        InferredElement? body = _checkElement(
          element: element.body,
          isMap: isMap,
        );
        if (body != null) {
          return new InferredForInElement(
            encoding: element.encoding,
            variable: element.variable,
            iterable: element.iterable,
            body: body,
            isAsync: element.isAsync,
            scope: element.scope,
            nodeForTesting: element.nodeForTesting,
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredMapEntryElement():
      case InferredNullAwareMapEntryElement():
        if (!isMap) {
          return new InferredInvalidElement(
            expression: extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                // TODO(johnniwinther): We should emit a better error here.
                message: diag.expectedButGot.withArguments(expected: ','),
                fileUri: fileUri,
                fileOffset: element.fileOffset,
                length: noLength,
              ),
            ),
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredExpressionElement():
      case InferredNullAwareElement():
        if (isMap) {
          return new InferredInvalidElement(
            expression: extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                // TODO(johnniwinther): We should emit a better error here.
                message: diag.expectedAfterButGot.withArguments(expected: ':'),
                fileUri: fileUri,
                fileOffset: element.fileOffset,
                length: noLength,
              ),
            ),
            fileOffset: element.fileOffset,
          );
        }
        return null;
      case InferredInvalidElement():
        // Do nothing.  Assignability checks are done during type inference.
        return null;
    }
  }

  ExpressionInferenceResult visitInternalListLiteral(
    InternalListLiteral node,
    DartType typeContext,
  ) {
    Class listClass = coreTypes.listClass;
    ElementInferenceContext context;
    DartType? typeArgument = node.typeArgument;
    if (typeArgument != null) {
      context = new ListSetElementInferenceContext(
        elementTypeContext: new IterableElementType(typeArgument),
        spreadContext: new IterableSpreadContext(typeArgument: typeArgument),
      );
    } else {
      context = new InferredListElementInferenceContext(
        visitor: this,
        typeContext: typeContext,
        forConst: node.isConst,
        node: node,
      );
    }
    List<InferredElement> elements = new List.filled(
      node.elements.length,
      dummyInferredElement,
    );
    for (int index = 0; index < node.elements.length; ++index) {
      ElementInferenceResult result = inferElement(
        node.elements[index],
        context,
      );
      elements[index] = result.element;
      context.registerElementType(result.inferredType);
    }
    ElementInferenceKind kind = context.determineElementKind();
    assert(!kind.canBeMap, "Unexpected element kind: $kind");
    assert(kind.canBeIterable, "Unexpected element kind: $kind");
    ElementType inferredElementType = context.inferElementType(asMap: false);
    typeArgument = inferredElementType.expressionType;
    for (int i = 0; i < elements.length; i++) {
      elements[i] =
          _checkElement(element: elements[i], isMap: false) ?? elements[i];
    }
    DartType inferredType = new InterfaceType(
      listClass,
      Nullability.nonNullable,
      [typeArgument],
    );

    Expression result = new ListLiteralBuilder(
      engine,
      libraryBuilder,
      elementType: typeArgument,
      isConst: node.isConst,
    ).translate(elements: elements, fileOffset: node.fileOffset);

    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result);
    return new ExpressionInferenceResult(inferredType, result);
  }

  ExpressionInferenceResult visitInternalLogicalExpression(
    InternalLogicalExpression node,
    DartType typeContext,
  ) {
    InterfaceType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    flowAnalysis.logicalBinaryOp_begin();
    ExpressionInferenceResult leftResult = inferExpression(
      node.left,
      boolType,
      isVoidAllowed: false,
    );
    Expression left = ensureAssignableResult(
      boolType,
      leftResult,
      assignedNode: node.left,
    ).expression;
    flowAnalysis.logicalBinaryOp_rightBegin(
      getExpressionInfo(left),
      node,
      isAnd: node.operator == LogicalExpressionOperator.AND,
    );
    ExpressionInferenceResult rightResult = inferExpression(
      node.right,
      boolType,
      isVoidAllowed: false,
    );
    Expression right = ensureAssignableResult(
      boolType,
      rightResult,
      assignedNode: node.right,
    ).expression;
    Expression replacement = extern.createLogicalExpression(
      left: left,
      operator: node.operator,
      right: right,
      fileOffset: node.fileOffset,
    );
    storeExpressionInfo(
      replacement,
      flowAnalysis.logicalBinaryOp_end(
        getExpressionInfo(right),
        isAnd: node.operator == LogicalExpressionOperator.AND,
      ),
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(boolType, replacement);
  }

  SyntheticVariable _createVariable(Expression expression, DartType type) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return extern.createVariableCache(expression, type);
  }

  VariableGet _createVariableGet(Variable variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    return new VariableGet(variable)..fileOffset = variable.fileOffset;
  }

  AsExpression _createImplicitAs(
    int fileOffset,
    Expression expression,
    DartType type,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new AsExpression(expression, type)
      ..isTypeError = true
      ..fileOffset = fileOffset;
  }

  ConditionalExpression _createConditionalExpression(
    int fileOffset,
    Expression condition,
    Expression then,
    Expression otherwise,
    DartType type,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new ConditionalExpression(condition, then, otherwise, type)
      ..fileOffset = fileOffset;
  }

  ElementInferenceResult inferElement(
    InternalElement element,
    ElementInferenceContext context,
  ) {
    return element.acceptInference(this, context);
  }

  ElementInferenceResult visitExpressionElement(
    ExpressionElement node,
    ElementInferenceContext context,
  ) {
    context.registerExpression(fileOffset: node.fileOffset);

    DartType typeContext = context.elementTypeContext.expressionType;
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      typeContext,
      isVoidAllowed: true,
    );
    if (typeContext is! UnknownType) {
      result = ensureAssignableResult(
        typeContext,
        result,
        isVoidAllowed: typeContext is VoidType,
        assignedNode: node.expression,
      );
    }
    Expression replacement = result.expression;
    return new ElementInferenceResult(
      inferredType: new IterableElementType(result.inferredType),
      element: replacement is InvalidExpression
          ? new InferredInvalidElement(
              expression: replacement,
              fileOffset: node.fileOffset,
            )
          : new InferredExpressionElement(
              expression: result.expression,
              fileOffset: node.fileOffset,
            ),
    );
  }

  ElementInferenceResult visitNullAwareElement(
    NullAwareElement node,
    ElementInferenceContext context,
  ) {
    context.registerExpression(fileOffset: node.fileOffset);

    DartType nullableInferredTypeArgument = context
        .elementTypeContext
        .expressionType
        .withDeclaredNullability(Nullability.nullable);
    ExpressionInferenceResult expressionResult = inferExpression(
      node.expression,
      nullableInferredTypeArgument,
      isVoidAllowed: true,
    );
    if (nullableInferredTypeArgument is! UnknownType) {
      expressionResult = ensureAssignableResult(
        nullableInferredTypeArgument,
        expressionResult,
        isVoidAllowed: nullableInferredTypeArgument is VoidType,
        assignedNode: node.expression,
      );
    }
    InferredElement inferredElement = new InferredNullAwareElement(
      expression: expressionResult.expression,
      fileOffset: node.fileOffset,
    );
    return new ElementInferenceResult(
      inferredType: new IterableElementType(
        computeNonNull(expressionResult.inferredType),
      ),
      element: inferredElement,
    );
  }

  ElementInferenceResult visitSpreadElement(
    SpreadElement node,
    ElementInferenceContext context,
  ) {
    SpreadContext spreadContext = context.spreadContext;
    DartType spreadContextType = spreadContext.getSpreadTypeContext(coreTypes);
    if (node.isNullAware) {
      spreadContextType = computeNullable(spreadContextType);
    }
    ExpressionInferenceResult spreadResult = inferExpression(
      node.expression,
      spreadContextType,
      isVoidAllowed: true,
    );
    InvalidExpression? error;
    Expression expression = spreadResult.expression;
    final DartType spreadType = spreadResult.inferredType;
    DartType spreadTypeBound = spreadType.nonTypeParameterBound;

    bool isNull = coreTypes.isNull(spreadTypeBound);
    bool isDynamic = spreadType is DynamicType;
    bool isNever = coreTypes.isBottom(spreadType);
    List<DartType>? iterableTypeArguments;
    List<DartType>? mapTypeArguments;
    if (spreadTypeBound is TypeDeclarationType) {
      iterableTypeArguments = typeSchemaEnvironment
          .getTypeArgumentsAsInstanceOf(
            spreadTypeBound,
            coreTypes.iterableClass,
          );
      mapTypeArguments = typeSchemaEnvironment.getTypeArgumentsAsInstanceOf(
        spreadTypeBound,
        coreTypes.mapClass,
      );
    }
    bool isMap = mapTypeArguments != null;
    bool isIterable = iterableTypeArguments != null;

    ElementType spreadElementType;
    if (isNull) {
      // The expression has type `Null`. This is only valid if the spread is
      // null-aware.
      if (!node.isNullAware) {
        error = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonNullAwareSpreadIsNull.withArguments(
              spreadType: spreadType,
            ),
            fileUri: fileUri,
            fileOffset: node.expression.fileOffset,
            length: 1,
          ),
        );
        spreadElementType = const InvalidElementType();
      } else {
        spreadElementType = const NeverElementType();
      }
    } else if (isDynamic) {
      // The expression has type `dynamic`. This is always valid but requires
      // a type cast at runtime.
      spreadElementType = const DynamicElementType();
    } else if (isNever) {
      // The expression has type `Never`. This is always valid.
      spreadElementType = const NeverElementType();
    } else if (mapTypeArguments != null) {
      // The expression has a map type.
      DartType keyType = mapTypeArguments[0];
      DartType valueType = mapTypeArguments[1];
      switch (spreadContext) {
        case MapSpreadContext():
          // We expect a map type, so we check for assignability of the
          // key/value types.
          if (!isAssignable(spreadContext.keyType, keyType)) {
            error = extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.spreadMapEntryElementKeyTypeMismatch
                    .withArguments(
                      spreadKeyType: keyType,
                      mapKeyType: spreadContext.keyType,
                    ),
                fileUri: fileUri,
                fileOffset: node.expression.fileOffset,
                length: 1,
              ),
            );
          }
          if (!isAssignable(spreadContext.valueType, valueType)) {
            error = extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.spreadMapEntryElementValueTypeMismatch
                    .withArguments(
                      spreadValueType: valueType,
                      mapValueType: spreadContext.valueType,
                    ),
                fileUri: fileUri,
                fileOffset: node.expression.fileOffset,
                length: 1,
              ),
            );
          }
        case IterableSpreadContext():
          // We expect an iterable type, so this is an error.
          error = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.spreadTypeMismatch.withArguments(
                spreadType: spreadType,
              ),
              fileUri: fileUri,
              fileOffset: expression.fileOffset,
              length: 1,
            ),
          );
        case UnknownSpreadContext():
        // The context is ambiguous so nothing can be checked.
      }
      spreadElementType = new MapElementType(
        keyType: keyType,
        valueType: valueType,
      );
    } else if (iterableTypeArguments != null) {
      // The expression has an iterable type.
      DartType typeArgument = iterableTypeArguments[0];
      switch (spreadContext) {
        case IterableSpreadContext():
          // We expect an iterable type, so we check for assignability of the
          // element types.
          if (!isAssignable(spreadContext.typeArgument, typeArgument)) {
            error = extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.spreadElementTypeMismatch.withArguments(
                  spreadElementType: typeArgument,
                  collectionElementType: spreadContext.typeArgument,
                ),
                fileUri: fileUri,
                fileOffset: expression.fileOffset,
                length: 1,
              ),
            );
          }
        case MapSpreadContext():
          // We expect a map type, so this is an error.
          error = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.spreadMapEntryTypeMismatch.withArguments(
                spreadType: spreadType,
              ),
              fileUri: fileUri,
              fileOffset: expression.fileOffset,
              length: 1,
            ),
          );
        case UnknownSpreadContext():
        // The context is ambiguous so nothing can be checked.
      }
      spreadElementType = new IterableElementType(typeArgument);
    } else {
      switch (spreadContext) {
        case IterableSpreadContext():
          // We expect an iterable type, so we report that we expected
          // `dynamic` or `Iterable`.
          error = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.spreadTypeMismatch.withArguments(
                spreadType: spreadType,
              ),
              fileUri: fileUri,
              fileOffset: expression.fileOffset,
              length: 1,
            ),
          );
        case MapSpreadContext():
          // We expect an map type, so we report that we expected
          // `dynamic` or `Map`.
          error = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.spreadMapEntryTypeMismatch.withArguments(
                spreadType: spreadType,
              ),
              fileUri: fileUri,
              fileOffset: expression.fileOffset,
              length: 1,
            ),
          );
        case UnknownSpreadContext():
          // The context is ambiguous so we report that we expected `dynamic`,
          // `Iterable` or `Map`.
          error = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.spreadEntryOrElementTypeMismatch.withArguments(
                spreadType: spreadType,
              ),
              fileUri: fileUri,
              fileOffset: expression.fileOffset,
              length: 1,
            ),
          );
      }
      spreadElementType = new InvalidElementType();
    }

    if (!isDynamic &&
        !isNull &&
        spreadType.isPotentiallyNullable &&
        !node.isNullAware) {
      Expression receiver = expression;
      error = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nullableSpreadError,
          fileUri: fileUri,
          fileOffset: receiver.fileOffset,
          length: 1,
          context: getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(getExpressionInfo(receiver))(),
            node,
            // Coverage-ignore(suite): Not run.
            (type) => !type.isPotentiallyNullable,
          ),
        ),
      );
      libraryBuilder.loader.dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.registerExternalNode(node, error);
    }

    if (isMap && !isIterable) {
      context.registerMapSpread(fileOffset: node.fileOffset);
    }
    if (!isMap && isIterable) {
      context.registerIterableSpread(
        type: spreadType,
        fileOffset: node.fileOffset,
      );
    }

    InferredElement inferredElement = error != null
        ? new InferredInvalidElement(
            expression: error,
            fileOffset: error.fileOffset,
          )
        : new InferredSpreadElement(
            expression: expression,
            expressionNode: node.expression,
            isNullAware: node.isNullAware,
            expressionType: spreadType,
            elementType: spreadElementType,
            nodeForTesting: node,
            fileOffset: node.fileOffset,
          );
    return new ElementInferenceResult(
      inferredType: spreadElementType,
      element: inferredElement,
    );
  }

  ElementInferenceResult visitIfElement(
    IfElement node,
    ElementInferenceContext context,
  ) {
    flowAnalysis.ifStatement_conditionBegin();
    DartType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      boolType,
      isVoidAllowed: false,
    );
    Expression condition = ensureAssignableResult(
      boolType,
      conditionResult,
      assignedNode: node.condition,
    ).expression;
    flowAnalysis.ifStatement_thenBegin(getExpressionInfo(condition), node);
    ElementInferenceResult thenResult = inferElement(node.then, context);
    ElementInferenceResult? otherwiseResult;
    if (node.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      otherwiseResult = inferElement(node.otherwise!, context);
    }
    flowAnalysis.ifStatement_end(node.otherwise != null);
    InferredElement inferredElement = new InferredIfElement(
      condition: condition,
      then: thenResult.element,
      otherwise: otherwiseResult?.element,
      nodeForTesting: node,
      fileOffset: node.fileOffset,
    );
    return new ElementInferenceResult(
      inferredType: otherwiseResult == null
          ? thenResult.inferredType
          : thenResult.inferredType.getStandardUpperBound(
              typeSchemaEnvironment,
              otherwiseResult.inferredType,
            ),
      element: inferredElement,
    );
  }

  ElementInferenceResult visitIfCaseElement(
    IfCaseElement node,
    ElementInferenceContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    IfCaseStatementResult<InvalidExpression> analysisResult =
        analyzeIfCaseElement(
          node: node,
          expression: node.expression,
          pattern: node.patternGuard.pattern,
          variables: {
            for (InternalVariable variable
                in node.patternGuard.pattern.declaredVariables)
              variable.cosmeticName!: variable,
          },
          guard: node.patternGuard.guard,
          ifTrue: node.then,
          ifFalse: node.otherwise,
          context: context,
        );

    DartType matchedValueType = analysisResult.matchedExpressionType
        .unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* ifFalse = */ ValueKinds.ElementInferenceResultOrNull,
        /* ifTrue = */ ValueKinds.ElementInferenceResult,
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern = */ ValueKinds.Pattern,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    ElementInferenceResult? otherwiseResult =
        popRewrite(NullValues.Expression) as ElementInferenceResult?;
    ElementInferenceResult thenResult = popRewrite() as ElementInferenceResult;

    Expression? guard = popRewrite(NullValues.Expression) as Expression?;
    InvalidExpression? guardError = analysisResult.nonBooleanGuardError;
    if (guardError != null) {
      guard = guardError;
    } else if (guard != null) {
      if (analysisResult.guardType is DynamicType) {
        guard = _createImplicitAs(
          guard.fileOffset,
          guard,
          coreTypes.boolNonNullableRawType,
        );
      }
    }

    Pattern pattern = popRewrite() as Pattern;
    Expression expression = popRewrite() as Expression;

    PatternGuard patternGuard = extern.createPatternGuard(
      pattern: pattern,
      guard: guard,
      fileOffset: node.patternGuard.fileOffset,
    );

    ElementType thenType = thenResult.inferredType;
    ElementType? otherwiseType = otherwiseResult?.inferredType;
    InferredElement inferredElement = new InferredIfCaseElement(
      expression: expression,
      patternGuard: patternGuard,
      then: thenResult.element,
      otherwise: otherwiseResult?.element,
      matchedValueType: matchedValueType,
      nodeForTesting: node,
      fileOffset: node.fileOffset,
    );
    return new ElementInferenceResult(
      inferredType: otherwiseType == null
          ? thenType
          : thenType.getStandardUpperBound(
              typeSchemaEnvironment,
              otherwiseType,
            ),
      element: inferredElement,
    );
  }

  ForElementBaseResult _inferForElementBase2(
    ForElementBase node,
    ElementInferenceContext context,
  ) {
    List<VariableDeclaration> variables = new List.filled(
      node.variables.length,
      dummyVariableDeclaration,
      growable: true,
    );
    for (int index = 0; index < node.variables.length; index++) {
      InternalVariableDeclaration variableDeclaration = node.variables[index];
      InternalDeclaredVariable variable = variableDeclaration.variable;
      if (variable.cosmeticName == null) {
        Expression? initializer;
        if (variableDeclaration.initializer != null) {
          ExpressionInferenceResult initializerResult = inferExpression(
            variableDeclaration.initializer!,
            variable.type,
            isVoidAllowed: true,
          );
          initializer = initializerResult.expression;
          variable.type = initializerResult.inferredType;
        }
        variables[index] = extern.createVariableDeclaration(
          variable.astVariable,
          initializer: initializer,
          fileOffset: variableDeclaration.fileOffset,
        );
      } else {
        VariableDeclarationInferenceResult variableResult =
            inferVariableDeclaration(
              variableDeclaration,
              forLoopVariable: true,
            );
        switch (variableResult) {
          case DirectVariableDeclarationInferenceResult():
            variables[index] = variableResult.declaration;
          // Coverage-ignore(suite): Not run.
          case EffectVariableDeclarationInferenceResult():
          case LateVariableDeclarationInferenceResult():
            throw new UnsupportedError(
              "Unexpected variable declaration change.",
            );
        }
      }
    }

    flowAnalysis.for_conditionBegin(node);
    Expression? condition;
    if (node.condition != null) {
      ExpressionInferenceResult conditionResult = inferExpression(
        node.condition!,
        coreTypes.boolRawType(Nullability.nonNullable),
        isVoidAllowed: false,
      );
      Expression assignableCondition = ensureAssignable(
        coreTypes.boolRawType(Nullability.nonNullable),
        conditionResult.inferredType,
        conditionResult.expression,
        assignedNode: node.condition!,
      );
      condition = assignableCondition;
    }
    flowAnalysis.for_bodyBegin(null, switch (condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => getExpressionInfo(condition),
    });
    ElementInferenceResult bodyResult = inferElement(node.body, context);
    InferredElement body = bodyResult.element;
    flowAnalysis.for_updaterBegin();
    List<Expression> updates = new List.filled(
      node.updates.length,
      dummyExpression,
    );
    for (int index = 0; index < node.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
        node.updates[index],
        const UnknownType(),
        isVoidAllowed: true,
      );
      updates[index] = updateResult.expression;
    }
    flowAnalysis.for_end();
    return new ForElementBaseResult(
      variables: variables,
      condition: condition,
      body: body,
      updates: updates,
      inferredType: bodyResult.inferredType,
    );
  }

  ElementInferenceResult visitForElement(
    ForElement node,
    ElementInferenceContext context,
  ) {
    ForElementBaseResult result = _inferForElementBase2(node, context);
    return new ElementInferenceResult(
      inferredType: result.inferredType,
      element: new InferredForElement(
        variables: result.variables,
        condition: result.condition,
        updates: result.updates,
        body: result.body,
        nodeForTesting: node,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ElementInferenceResult visitPatternForElement(
    PatternForElement node,
    ElementInferenceContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    InternalPatternVariableDeclaration internalPatternVariableDeclaration =
        node.patternVariableDeclaration;
    PatternVariableDeclarationAnalysisResult analysisResult =
        analyzePatternVariableDeclaration(
          internalPatternVariableDeclaration,
          internalPatternVariableDeclaration.pattern,
          internalPatternVariableDeclaration.initializer,
          isFinal: internalPatternVariableDeclaration.isFinal,
        );
    DartType matchedValueType = analysisResult.initializerType.unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]),
    );

    Pattern pattern = popRewrite() as Pattern;
    Expression initializer = popRewrite() as Expression;
    PatternVariableDeclaration patternVariableDeclaration = extern
        .createPatternVariableDeclaration(
          pattern: pattern,
          initializer: initializer,
          isFinal: internalPatternVariableDeclaration.isFinal,
          matchedValueType: matchedValueType,
          fileOffset: internalPatternVariableDeclaration.fileOffset,
        );

    List<Variable> declaredVariables = pattern.declaredVariables;
    assert(declaredVariables.length == node.intermediateVariables.length);
    assert(declaredVariables.length == node.variables.length);
    List<VariableDeclaration> intermediateVariables = new List.filled(
      node.intermediateVariables.length,
      dummyVariableDeclaration,
    );
    for (int i = 0; i < declaredVariables.length; i++) {
      DartType type = declaredVariables[i].type;

      InternalVariableDeclaration intermediateVariableDeclaration =
          node.intermediateVariables[i];
      InternalDeclaredVariable intermediateVariable =
          intermediateVariableDeclaration.variable;
      Expression initializer = inferExpression(
        intermediateVariableDeclaration.initializer!,
        type,
        isVoidAllowed: true,
      ).expression;
      intermediateVariable.type = type;

      intermediateVariables[i] = extern.createVariableDeclaration(
        intermediateVariable.astVariable,
        initializer: initializer,
        fileOffset: intermediateVariableDeclaration.fileOffset,
      );

      node.variables[i].variable.type = type;
    }

    ForElementBaseResult result = _inferForElementBase2(node, context);
    return new ElementInferenceResult(
      inferredType: result.inferredType,
      element: new InferredPatternForElement(
        patternVariableDeclaration: patternVariableDeclaration,
        intermediateVariables: intermediateVariables,
        variables: result.variables,
        condition: result.condition,
        updates: result.updates,
        body: result.body,
        nodeForTesting: node,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ElementInferenceResult visitForInElement(
    ForInElement node,
    ElementInferenceContext context,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      // [ForInElement] will be desugared later into a [ForStatement], which
      // will be responsible for the scope. Therefore, the supplied
      // [ScopeProviderInfoKind] to [enterScopeProvider] is
      // [ScopeProviderInfoKind.ForInStatement].
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
    }
    ForInHeaderResult result = node.element.inferForInHeader(
      this,
      node: node,
      iterable: node.iterable,
      isAsync: node.isAsync,
      forOffset: node.forOffset,
    );

    DeclaredVariable variable = result.loopVariable;
    Expression iterable = result.iterable;

    flowAnalysis.forEach_bodyBegin(node);

    InternalVariable? declaredVariable = result.declaredVariable;
    if (declaredVariable != null) {
      flowAnalysis.declare(
        declaredVariable,
        new SharedTypeView(declaredVariable.type),
        initialized: true,
      );
      if (isClosureContextLoweringEnabled) {
        _contextAllocationStrategy.handleDeclarationOfVariable(
          declaredVariable.astVariable,
          captureKind: captureKindForVariable(declaredVariable),
        );
      }
    }
    if (isClosureContextLoweringEnabled) {
      if (declaredVariable?.astVariable != variable) {
        // Coverage-ignore-block(suite): Not run.
        // [variable] is synthesized.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          variable,
          captureKind: CaptureKind.notCaptured,
        );
      }
    }

    ForInEncoding encoding = result.computeEncoding();

    ElementInferenceResult bodyResult = inferElement(node.body, context);
    InferredElement body = bodyResult.element;

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      // The scope will later be passed to the [ForInStatement] the [element]
      // is desugared into.
      scope = scopeProviderInfo.scope;
    }
    return new ElementInferenceResult(
      inferredType: bodyResult.inferredType,
      element: new InferredForInElement(
        encoding: encoding,
        variable: variable,
        iterable: iterable,
        body: body,
        isAsync: node.isAsync,
        scope: scope,
        nodeForTesting: node,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ElementInferenceResult visitMapEntryElement(
    MapEntryElement node,
    ElementInferenceContext context,
  ) {
    context.registerMapEntry(fileOffset: node.fileOffset);

    DartType inferredKeyType = context.elementTypeContext.keyType;
    DartType adjustedInferredKeyType = node.isKeyNullAware
        ? inferredKeyType.withDeclaredNullability(Nullability.nullable)
        : inferredKeyType;
    ExpressionInferenceResult keyInferenceResult = inferExpression(
      node.key,
      adjustedInferredKeyType,
      isVoidAllowed: !node.isKeyNullAware,
    );
    if (inferredKeyType is! UnknownType) {
      keyInferenceResult = ensureAssignableResult(
        adjustedInferredKeyType,
        keyInferenceResult,
        isVoidAllowed: inferredKeyType is VoidType,
        assignedNode: node.key,
      );
    }
    Expression key = keyInferenceResult.expression;

    flowAnalysis.nullAwareMapEntry_valueBegin(
      getExpressionInfo(key),
      new SharedTypeView(keyInferenceResult.inferredType),
      isKeyNullAware: node.isKeyNullAware,
    );

    DartType inferredValueType = context.elementTypeContext.valueType;
    DartType adjustedInferredValueType = node.isValueNullAware
        ? inferredValueType.withDeclaredNullability(Nullability.nullable)
        : inferredValueType;
    ExpressionInferenceResult valueInferenceResult = inferExpression(
      node.value,
      adjustedInferredValueType,
      isVoidAllowed: !node.isValueNullAware,
    );
    if (inferredValueType is! UnknownType) {
      valueInferenceResult = ensureAssignableResult(
        adjustedInferredValueType,
        valueInferenceResult,
        isVoidAllowed: inferredValueType is VoidType,
        assignedNode: node.value,
      );
    }
    Expression value = valueInferenceResult.expression;

    DartType keyType = node.isKeyNullAware
        ? computeNonNull(keyInferenceResult.inferredType)
        : keyInferenceResult.inferredType;
    DartType valueType = node.isValueNullAware
        ? computeNonNull(valueInferenceResult.inferredType)
        : valueInferenceResult.inferredType;
    context.registerMapEntry(fileOffset: node.fileOffset);

    flowAnalysis.nullAwareMapEntry_end(isKeyNullAware: node.isKeyNullAware);
    return new ElementInferenceResult(
      inferredType: new MapElementType(keyType: keyType, valueType: valueType),
      element: node.isKeyNullAware || node.isValueNullAware
          ? new InferredNullAwareMapEntryElement(
              isKeyNullAware: node.isKeyNullAware,
              key: key,
              isValueNullAware: node.isValueNullAware,
              value: value,
              fileOffset: node.fileOffset,
            )
          : new InferredMapEntryElement(
              key: key,
              value: value,
              fileOffset: node.fileOffset,
            ),
    );
  }

  ExpressionInferenceResult visitMapOrSetLiteral(
    MapOrSetLiteral node,
    DartType typeContext,
  ) {
    List<DartType>? typeArguments = node.typeArguments;
    ElementInferenceContext context;
    if (typeArguments != null) {
      if (typeArguments.length == 1) {
        DartType typeArgument = typeArguments.single;
        context = new ListSetElementInferenceContext(
          elementTypeContext: new IterableElementType(typeArgument),
          spreadContext: new IterableSpreadContext(typeArgument: typeArgument),
        );
      } else {
        assert(
          typeArguments.length == 2,
          "Unexpected type argument count ${typeArguments}",
        );
        DartType keyType = typeArguments[0];
        DartType valueType = typeArguments[1];
        context = new MapElementInferenceContext(
          elementTypeContext: new MapElementType(
            keyType: keyType,
            valueType: valueType,
          ),
          spreadContext: new MapSpreadContext(
            keyType: keyType,
            valueType: valueType,
          ),
        );
      }
    } else {
      context = new InferredMapOrSetElementInferenceContext(
        visitor: this,
        typeContext: typeContext,
        forConst: node.isConst,
        node: node,
      );
    }

    List<InferredElement> elements = new List.filled(
      node.elements.length,
      dummyInferredElement,
    );
    for (int index = 0; index < node.elements.length; ++index) {
      ElementInferenceResult result = inferElement(
        node.elements[index],
        context,
      );
      elements[index] = result.element;
      context.registerElementType(result.inferredType);
    }
    ElementInferenceKind kind = context.determineElementKind();
    bool inferAsMap;
    if (kind.canBeIterable && !kind.canBeMap) {
      inferAsMap = false;
    } else if (kind.canBeIterable && kind.canBeMap && elements.isNotEmpty) {
      Expression replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.cantDisambiguateNotEnoughInformation,
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: 1,
        ),
      );
      return new ExpressionInferenceResult(
        NeverType.fromNullability(Nullability.nonNullable),
        replacement,
      );
    } else if (!kind.canBeIterable && !kind.canBeMap) {
      Expression replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.cantDisambiguateAmbiguousInformation,
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: 1,
        ),
      );
      return new ExpressionInferenceResult(
        NeverType.fromNullability(Nullability.nonNullable),
        replacement,
      );
    } else {
      inferAsMap = true;
    }
    ElementType inferredElementType = context.inferElementType(
      asMap: inferAsMap,
    );

    for (int i = 0; i < elements.length; i++) {
      elements[i] =
          _checkElement(element: elements[i], isMap: inferAsMap) ?? elements[i];
    }

    Expression result;
    DartType inferredType;
    if (inferAsMap) {
      DartType keyType = inferredElementType.keyType;
      DartType valueType = inferredElementType.valueType;
      inferredType = new InterfaceType(
        coreTypes.mapClass,
        Nullability.nonNullable,
        [keyType, valueType],
      );
      result = new MapLiteralBuilder(
        engine,
        libraryBuilder,
        keyType: keyType,
        valueType: valueType,
        isConst: node.isConst,
      ).translate(entries: elements, fileOffset: node.fileOffset);
    } else {
      DartType typeArgument = inferredElementType.expressionType;

      inferredType = new InterfaceType(
        coreTypes.setClass,
        Nullability.nonNullable,
        [typeArgument],
      );
      result = new SetLiteralBuilder(
        engine,
        libraryBuilder,
        elementType: typeArgument,
        isConst: node.isConst,
      ).translate(elements: elements, fileOffset: node.fileOffset);
    }
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result);
    return new ExpressionInferenceResult(inferredType, result);
  }

  ExpressionInferenceResult visitMethodInvocation(
    MethodInvocation node,
    DartType typeContext,
  ) {
    assert(node.name != unaryMinusName);
    ExpressionInferenceResult result = inferExpression(
      node.receiver,
      const UnknownType(),
      continueNullShorting: true,
    );
    Expression receiver = result.expression;
    DartType receiverType = result.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    return inferMethodInvocation(
      this,
      node.fileOffset,
      receiver,
      receiverType,
      node.name,
      node.typeArguments,
      node.arguments,
      typeContext,
      isExpressionInvocation: false,
      isImplicitCall: false,
      isImplicitThis: node.isImplicitThis,
      invocationNode: node,
    );
  }

  ExpressionInferenceResult visitExpressionInvocation(
    ExpressionInvocation node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      const UnknownType(),
      continueNullShorting: true,
    );
    Expression receiver = result.expression;
    DartType receiverType = result.inferredType;
    return inferMethodInvocation(
      this,
      node.fileOffset,
      receiver,
      receiverType,
      callName,
      node.typeArguments,
      node.arguments,
      typeContext,
      isExpressionInvocation: true,
      isImplicitCall: true,
      invocationNode: node,
    );
  }

  ExpressionInferenceResult visitInternalNot(
    InternalNot node,
    DartType typeContext,
  ) {
    InterfaceType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      boolType,
    );
    Expression operand = ensureAssignableResult(
      boolType,
      operandResult,
      fileOffset: node.fileOffset,
      assignedNode: node.operand,
    ).expression;
    Expression replacement = extern.createNot(
      operand,
      fileOffset: node.fileOffset,
    );
    storeExpressionInfo(
      replacement,
      flowAnalysis.logicalNot_end(getExpressionInfo(operand)),
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(boolType, replacement);
  }

  ExpressionInferenceResult visitInternalNullCheck(
    InternalNullCheck node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      computeNullable(typeContext),
      continueNullShorting: true,
    );

    Expression operand = operandResult.expression;
    DartType operandType = operandResult.inferredType;

    flowAnalysis.nonNullAssert_end(getExpressionInfo(operand));
    DartType nonNullableResultType = operations
        .promoteToNonNull(new SharedTypeView(operandType))
        .unwrapTypeView();
    Expression replacement = extern.createNullCheck(
      operand,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(nonNullableResultType, replacement);
  }

  ExpressionInferenceResult visitStaticIncDec(
    StaticIncDec node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult readResult = inferStaticGet(
      member: node.getter,
      typeContext: typeContext,
      nameOffset: node.nameOffset,
      accessNode: node,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    SyntheticVariable? valueVariable;
    if (!node.forEffect && node.isPost) {
      // For postfix expressions like `a = o.b++` that are not for effect we
      // need to store the read value as the result after assignment.
      valueVariable = _createVariable(read, readType);
      read = _createVariableGet(valueVariable);
    }

    DartType writeContext = computeStaticSetWriteContext(node.setter);
    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.operatorOffset,
      contextType: writeContext,
      left: read,
      leftType: readType,
      binaryName: node.isInc ? plusName : minusName,
      right: intern.createIntLiteral(value: 1, fileOffset: node.operatorOffset),
      whyNotPromoted: null,
      invocationNode: node,
    );
    DartType binaryType = binaryResult.inferredType;

    ExpressionInferenceResult writeResult = inferStaticSet(
      member: node.setter,
      rhsResult: binaryResult,
      writeContext: writeContext,
      assignOffset: node.operatorOffset,
      nameOffset: node.nameOffset,
      valueNode: node,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    return new ExpressionInferenceResult(
      // For postfix expressions the expression type is the type of the read
      // value. For prefix expressions the expression type is the type of the
      // assignment value.
      node.isPost ? readType : binaryType,
      replacement,
    );
  }

  Expression _createThisExpression(InternalThisExpression node) {
    if (isClosureContextLoweringEnabled) {
      return extern.createVariableGet(
        _contextAllocationStrategy.thisVariable,
        fileOffset: node.fileOffset,
      );
    } else {
      return extern.createThisExpression(fileOffset: node.fileOffset);
    }
  }

  ExpressionInferenceResult visitSuperIncDec(
    SuperIncDec node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult readResult = inferSuperPropertyGet(
      receiver: _createThisExpression(node.receiver),
      name: node.name,
      typeContext: const UnknownType(),
      member: node.getter,
      nameOffset: node.nameOffset,
      accessNode: node,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    SyntheticVariable? valueVariable;
    if (!node.forEffect && node.isPost) {
      // For postfix expressions like `a = o.b++` that are not for effect we
      // need to store the read value as the result after assignment.
      valueVariable = _createVariable(read, readType);
      read = _createVariableGet(valueVariable);
    }

    DartType writeType = computeSuperPropertySetWriteContext(node.setter);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.operatorOffset,
      contextType: writeType,
      left: read,
      leftType: readType,
      binaryName: node.isInc ? plusName : minusName,
      right: intern.createIntLiteral(value: 1, fileOffset: node.operatorOffset),
      whyNotPromoted: null,
      invocationNode: node,
    );
    DartType binaryType = binaryResult.inferredType;

    ExpressionInferenceResult writeResult = inferSuperPropertySet(
      receiver: _createThisExpression(node.receiver),
      name: node.name,
      member: node.setter,
      rhsResult: binaryResult,
      writeContext: writeType,
      assignOffset: node.operatorOffset,
      nameOffset: node.nameOffset,
      valueNode: node,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    return new ExpressionInferenceResult(
      // For postfix expressions the expression type is the type of the read
      // value. For prefix expressions the expression type is the type of the
      // assignment value.
      node.isPost ? readType : binaryType,
      replacement,
    );
  }

  ExpressionInferenceResult visitLocalIncDec(
    LocalIncDec node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult readResult = inferVariableGet(
      variable: node.variable,
      typeContext: typeContext,
      nameOffset: node.nameOffset,
      accessNode: node,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    SyntheticVariable? valueVariable;
    if (!node.forEffect && node.isPost) {
      // For postfix expressions like `a = o.b++` that are not for effect we
      // need to store the read value as the result after assignment.
      valueVariable = _createVariable(read, readType);
      read = _createVariableGet(valueVariable);
    }

    var (DartType variableType, DartType writeContext) =
        computeVariableSetTypeAndWriteContext(node.variable);
    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.operatorOffset,
      contextType: writeContext,
      left: read,
      leftType: readType,
      binaryName: node.isInc ? plusName : minusName,
      right: intern.createIntLiteral(value: 1, fileOffset: node.operatorOffset),
      whyNotPromoted: null,
      invocationNode: node,
    );
    DartType binaryType = binaryResult.inferredType;

    ExpressionInferenceResult writeResult = inferVariableSet(
      node: node,
      variable: node.variable,
      rhsResult: binaryResult,
      variableType: variableType,
      assignOffset: node.operatorOffset,
      nameOffset: node.nameOffset,
      valueNode: node,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    return new ExpressionInferenceResult(
      // For postfix expressions the expression type is the type of the read
      // value. For prefix expressions the expression type is the type of the
      // assignment value.
      node.isPost ? readType : binaryType,
      replacement,
    );
  }

  ExpressionInferenceResult visitPropertyIncDec(
    PropertyIncDec node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: false,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    SyntheticVariable? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (node.isNullAware) {
      receiverVariable = extern.createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = receiverType.toNonNull();
      readReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    } else if (extern.isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
      readReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    }

    ExpressionInferenceResult readResult = _computePropertyGet(
      fileOffset: node.nameOffset,
      receiver: readReceiver,
      receiverType: receiverType,
      propertyName: node.name,
      typeContext: const UnknownType(),
      isThisReceiver: _isInternalThisExpression(node.receiver),
      isImplicitThis: node.isImplicitThis,
      accessNode: node,
    ).expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    SyntheticVariable? valueVariable;
    if (!node.forEffect && node.isPost) {
      // For postfix expressions like `a = o.b++` that are not for effect we
      // need to store the read value as the result after assignment.
      valueVariable = _createVariable(read, readType);
      read = _createVariableGet(valueVariable);
    }

    ObjectAccessTarget writeTarget = findInterfaceMember(
      receiverType,
      node.name,
      node.nameOffset,
      isSetter: true,
      instrumented: true,
      includeExtensionMethods: true,
    );
    DartType writeType = writeTarget.getSetterType(this);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.operatorOffset,
      contextType: writeType,
      left: read,
      leftType: readType,
      binaryName: node.isInc ? plusName : minusName,
      right: intern.createIntLiteral(value: 1, fileOffset: node.fileOffset),
      whyNotPromoted: null,
      invocationNode: node,
    );

    ExpressionInferenceResult writeResult = inferPropertySet(
      fileOffset: node.nameOffset,
      receiver: writeReceiver,
      receiverType: receiverType,
      propertyName: node.name,
      writeTarget: writeTarget,
      writeContext: writeType,
      valueResult: binaryResult,
      // For prefix expressions like `a = ++o.b` we need the result of the
      // assignment as the result of the expression.
      forEffect: node.isPost || node.forEffect,
      isImplicitThis: node.isImplicitThis,
      valueNode: node,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }

    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = extern.createLet(
          variable: receiverVariable,
          body: replacement,
        );
      }
    }
    return new ExpressionInferenceResult(
      // For postfix expressions the expression type is the type of the read
      // value. For prefix expressions the expression type is the type of the
      // assignment value.
      node.isPost ? readType : writeResult.inferredType,
      replacement,
    );
  }

  ExpressionInferenceResult visitCompoundPropertySet(
    CompoundPropertySet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: false,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    SyntheticVariable? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (node.isNullAware) {
      receiverVariable = extern.createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = receiverType.toNonNull();
      readReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    } else if (extern.isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
      readReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = extern.createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    }

    ExpressionInferenceResult readResult = _computePropertyGet(
      fileOffset: node.readOffset,
      receiver: readReceiver,
      receiverType: receiverType,
      propertyName: node.propertyName,
      typeContext: const UnknownType(),
      isThisReceiver: _isInternalThisExpression(node.receiver),
      accessNode: node,
    ).expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    ObjectAccessTarget writeTarget = findInterfaceMember(
      receiverType,
      node.propertyName,
      node.writeOffset,
      isSetter: true,
      instrumented: true,
      includeExtensionMethods: true,
    );
    DartType writeType = writeTarget.getSetterType(this);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.binaryOffset,
      contextType: writeType,
      left: read,
      leftType: readType,
      binaryName: node.binaryName,
      right: node.value,
      whyNotPromoted: null,
      invocationNode: node,
    );

    ExpressionInferenceResult writeResult = inferPropertySet(
      fileOffset: node.writeOffset,
      receiver: writeReceiver,
      receiverType: receiverType,
      propertyName: node.propertyName,
      writeTarget: writeTarget,
      valueResult: binaryResult,
      writeContext: writeType,
      forEffect: node.forEffect,
      valueNode: node.value,
    );
    Expression write = writeResult.expression;

    Expression replacement = write;
    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = extern.createLet(
          variable: receiverVariable,
          body: replacement,
        );
      }
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(writeResult.inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullPropertySet(
    IfNullPropertySet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: false,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    SyntheticVariable receiverVariable;
    if (node.isNullAware) {
      receiverVariable = extern.createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = receiverType.toNonNull();
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
    }

    Expression readReceiver = extern.createVariableGet(
      receiverVariable,
      promotedType: receiverType,
    );
    Expression writeReceiver = extern.createVariableGet(
      receiverVariable,
      promotedType: receiverType,
    );

    ExpressionInferenceResult readResult = _computePropertyGet(
      fileOffset: node.readOffset,
      receiver: readReceiver,
      receiverType: receiverType,
      propertyName: node.propertyName,
      typeContext: const UnknownType(),
      isThisReceiver: _isInternalThisExpression(node.receiver),
      accessNode: node,
    ).expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(read),
      new SharedTypeView(readType),
    );

    ObjectAccessTarget writeTarget = findInterfaceMember(
      receiverType,
      node.propertyName,
      receiver.fileOffset,
      isSetter: true,
      instrumented: true,
      includeExtensionMethods: true,
    );
    DartType writeContext = writeTarget.getSetterType(this);
    ExpressionInferenceResult rhsResult = inferExpression(
      node.rhs,
      writeContext,
      isVoidAllowed: true,
    );
    flowAnalysis.ifNullExpression_end();

    ExpressionInferenceResult writeResult = inferPropertySet(
      fileOffset: node.writeOffset,
      receiver: writeReceiver,
      receiverType: receiverType,
      propertyName: node.propertyName,
      writeTarget: writeTarget,
      writeContext: writeContext,
      valueResult: rhsResult,
      forEffect: node.forEffect,
      valueNode: node.rhs,
    );
    Expression write = writeResult.expression;
    DartType writeType = writeResult.inferredType;

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
      nonNullableReadType: nonNullableReadType,
      rhsType: writeType,
      typeContext: typeContext,
    );

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.a = b : null
      //
      Expression equalsNull = extern.createEqualsNull(
        read,
        fileOffset: node.fileOffset,
      );
      replacement = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        write,
        extern.createNullLiteral(fileOffset: node.fileOffset),
        computeNullable(inferredType),
      );
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      SyntheticVariable readVariable = extern.createVariable(read, readType);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(readVariable),
        fileOffset: node.fileOffset,
      );
      VariableGet variableGet = extern.createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        write,
        variableGet,
        inferredType,
      );
      replacement = extern.createLet(variable: readVariable, body: conditional);
    }
    if (!node.isNullAware) {
      // When the node is null-aware, the receiver variable is used as a
      // null-aware guard and is automatically inserted by the shorting system.
      // Otherwise, we have to manually insert the receiver variable here.
      replacement = extern.createLet(
        variable: receiverVariable,
        body: replacement,
      );
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  DartType _analyzeIfNullTypes({
    required DartType nonNullableReadType,
    required DartType rhsType,
    required DartType typeContext,
  }) {
    // - An if-null assignment `E` of the form `lvalue ??= e` with context type
    //   `K` is analyzed as follows:
    //
    //   - Let `T1` be the read type the lvalue.
    //   - Let `T2` be the type of `e` inferred with context type `T1`.
    DartType t2 = rhsType;
    //   - Let `T` be `UP(NonNull(T1), T2)`.
    DartType nonNullT1 = nonNullableReadType;
    DartType t = typeSchemaEnvironment.getStandardUpperBound(nonNullT1, t2);
    //   - Let `S` be the greatest closure of `K`.
    DartType s = computeGreatestClosure(typeContext);
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled) {
      return t;
    } else
    //   - If `T <: S`, then the type of `E` is `T`.
    if (typeSchemaEnvironment.isSubtypeOf(t, s)) {
      return t;
    }
    //   - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of
    //     `E` is `S`.
    if (typeSchemaEnvironment.isSubtypeOf(nonNullT1, s) &&
        typeSchemaEnvironment.isSubtypeOf(t2, s)) {
      return s;
    }
    //   - Otherwise, the type of `E` is `T`.
    return t;
  }

  ExpressionInferenceResult visitIfNullSet(
    IfNullSet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult readResult = inferExpression(
      node.read,
      const UnknownType(),
      continueNullShorting: true,
    );

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(read),
      new SharedTypeView(readType),
    );
    ExpressionInferenceResult writeResult = inferExpression(
      node.write,
      typeContext,
      isVoidAllowed: true,
    );
    flowAnalysis.ifNullExpression_end();

    DartType originalReadType = readType;
    DartType nonNullableReadType = originalReadType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
      nonNullableReadType: nonNullableReadType,
      rhsType: writeResult.inferredType,
      typeContext: typeContext,
    );

    Expression replacement;
    if (node.forEffect) {
      // Encode `a ??= b` as:
      //
      //     a == null ? a = b : null
      //
      Expression equalsNull = extern.createEqualsNull(
        read,
        fileOffset: node.fileOffset,
      );
      replacement = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        writeResult.expression,
        extern.createNullLiteral(fileOffset: node.fileOffset),
        computeNullable(inferredType),
      );
    } else {
      // Encode `a ??= b` as:
      //
      //      let v1 = a in v1 == null ? a = b : v1
      //
      SyntheticVariable readVariable = extern.createVariable(read, readType);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(readVariable),
        fileOffset: node.fileOffset,
      );
      VariableGet variableGet = extern.createVariableGet(readVariable);
      if (!identical(nonNullableReadType, originalReadType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        writeResult.expression,
        variableGet,
        inferredType,
      );
      replacement = extern.createLet(
        variable: readVariable,
        body: conditional,
        fileOffset: node.fileOffset,
      );
    }

    // Forward the expression in cases where flow analysis needs to use the
    // expression information. For example, for keeping the promotion in the
    // following if statement in `if ((x ??= 2) == null) { ... }`.
    storeExpressionInfo(replacement, getExpressionInfo(writeResult.expression));

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  bool _isThisExpression(Expression expression) {
    return expression is ThisExpression ||
        expression is VariableGet && expression.variable is ThisVariable;
  }

  bool _isInternalThisExpression(InternalExpression expression) {
    return expression is InternalThisExpression;
  }

  ExpressionInferenceResult visitIndexGet(IndexGet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: true,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
      receiverType,
      indexGetName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    DartType indexType = indexGetTarget.getIndexKeyType(this);

    MethodContravarianceCheckKind readCheckKind =
        preCheckInvocationContravariance(
          receiverType,
          indexGetTarget,
          isThisReceiver: _isInternalThisExpression(node.receiver),
        );

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      indexType,
      isVoidAllowed: true,
    );

    Expression index = ensureAssignableResult(
      indexType,
      indexResult,
      assignedNode: node.index,
    ).expression;

    ExpressionInferenceResult replacement = _computeIndexGet(
      node.fileOffset,
      receiver,
      receiverType,
      indexGetTarget,
      index,
      indexType,
      readCheckKind,
    );
    return new ExpressionInferenceResult(
      replacement.inferredType,
      replacement.expression,
    );
  }

  ExpressionInferenceResult visitIndexSet(IndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: true,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    SyntheticVariable? receiverVariable;
    if (!node.forEffect && !extern.isPureExpression(receiver)) {
      receiverVariable = extern.createVariable(receiver, receiverType);
      receiver = extern.createVariableGet(receiverVariable);
    }

    ObjectAccessTarget indexSetTarget = findInterfaceMember(
      receiverType,
      indexSetName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    DartType indexType = indexSetTarget.getIndexKeyType(this);
    DartType valueType = indexSetTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      indexType,
      isVoidAllowed: true,
    );

    Expression index = ensureAssignableResult(
      indexType,
      indexResult,
      assignedNode: node.index,
    ).expression;

    SyntheticVariable? indexVariable;
    if (!node.forEffect && !extern.isPureExpression(index)) {
      indexVariable = extern.createVariable(index, indexResult.inferredType);
      index = extern.createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: node.value,
    );
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
    } else if (extern.isPureExpression(value)) {
      returnedValue = extern.clonePureExpression(value);
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
      returnedValue = extern.createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    Expression assignment = _computeIndexSet(
      node.fileOffset,
      receiver,
      receiverType,
      indexSetTarget,
      index,
      indexType,
      value,
      valueType,
    );

    Expression replacement;
    if (node.forEffect) {
      replacement = assignment;
    } else {
      SyntheticVariable assignmentVariable = extern.createVariable(
        assignment,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: assignmentVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        replacement = extern.createLet(
          variable: valueVariable,
          body: replacement,
        );
      }
      if (indexVariable != null) {
        replacement = extern.createLet(
          variable: indexVariable,
          body: replacement,
        );
      }
      if (receiverVariable != null) {
        replacement = extern.createLet(
          variable: receiverVariable,
          body: replacement,
        );
      }
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitSuperIndexSet(
    SuperIndexSet node,
    DartType typeContext,
  ) {
    ObjectAccessTarget indexSetTarget = thisType!.classNode.isMixinDeclaration
        ?
          // Coverage-ignore(suite): Not run.
          new ObjectAccessTarget.interfaceMember(
            thisType!,
            node.setter,
            hasNonObjectMemberAccess: true,
          )
        : new ObjectAccessTarget.superMember(thisType!, node.setter);

    DartType indexType = indexSetTarget.getIndexKeyType(this);
    DartType valueType = indexSetTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      indexType,
      isVoidAllowed: true,
    );

    Expression index = ensureAssignableResult(
      indexType,
      indexResult,
      assignedNode: node.index,
    ).expression;

    SyntheticVariable? indexVariable;
    if (!extern.isPureExpression(index)) {
      indexVariable = extern.createVariable(index, indexResult.inferredType);
      index = extern.createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: node.value,
    );
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
    Expression returnedValue;
    if (extern.isPureExpression(value)) {
      returnedValue = extern.clonePureExpression(value);
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
      returnedValue = extern.createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    assert(
      indexSetTarget.isInstanceMember || indexSetTarget.isSuperMember,
      'Unexpected index set target $indexSetTarget.',
    );
    Expression assignment = new SuperMethodInvocation(
      new ThisExpression(),
      indexSetName,
      new Arguments(<Expression>[index, value])..fileOffset = node.fileOffset,
      indexSetTarget.classMember as Procedure,
    )..fileOffset = node.fileOffset;

    SyntheticVariable assignmentVariable = extern.createVariable(
      assignment,
      const VoidType(),
    );
    Expression replacement = extern.createLet(
      variable: assignmentVariable,
      body: returnedValue,
    );
    if (valueVariable != null) {
      replacement = extern.createLet(
        variable: valueVariable,
        body: replacement,
      );
    }
    if (indexVariable != null) {
      replacement = extern.createLet(
        variable: indexVariable,
        body: replacement,
      );
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitExtensionIndexGet(
    ExtensionIndexGet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.explicitTypeArguments?.types,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.explicitTypeArguments?.types,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.explicitTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      node.getter,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    DartType indexType = target.getIndexKeyType(this);
    DartType resultType = target.getReturnType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      indexType,
      isVoidAllowed: true,
    );

    Expression index = ensureAssignableResult(
      indexType,
      indexResult,
      assignedNode: node.index,
    ).expression;

    StaticInvocation replacement = extern.createStaticInvocation(
      node.getter,
      new Arguments(<Expression>[
        receiver,
        index,
      ], types: extensionTypeArguments)..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    return new ExpressionInferenceResult(resultType, replacement);
  }

  ExpressionInferenceResult visitExtensionIndexSet(
    ExtensionIndexSet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.explicitTypeArguments?.types,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.explicitTypeArguments?.types,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.explicitTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );
    ObjectAccessTarget target = new ExtensionAccessTarget(
      extensionOnType,
      node.setter,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
    if (!node.forEffect && !extern.isPureExpression(receiver)) {
      receiverVariable = extern.createVariable(receiver, receiverType);
      receiver = extern.createVariableGet(receiverVariable);
    }

    DartType indexType = target.getIndexKeyType(this);
    DartType valueType = target.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      indexType,
      isVoidAllowed: true,
    );

    Expression index = ensureAssignableResult(
      indexType,
      indexResult,
      assignedNode: node.index,
    ).expression;

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: node.value,
    );
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
      // Returned value is not needed.
    } else if (extern.isPureExpression(value)) {
      returnedValue = extern.clonePureExpression(value);
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
      returnedValue = extern.createVariableGet(valueVariable);
    }

    // The inferred type is that inferred type of the value expression and not
    // the type of the value parameter.
    DartType inferredType = valueResult.inferredType;

    StaticInvocation assignment = extern.createStaticInvocation(
      node.setter,
      new Arguments(<Expression>[
        receiver,
        index,
        value,
      ], types: extensionTypeArguments)..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    Expression replacement = assignment;
    if (returnedValue != null) {
      assert(!node.forEffect);
      SyntheticVariable assignmentVariable = extern.createVariable(
        assignment,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: assignmentVariable,
        body: returnedValue,
      );
    }
    if (valueVariable != null) {
      replacement = extern.createLet(
        variable: valueVariable,
        body: replacement,
      );
    }
    if (receiverVariable != null) {
      replacement = extern.createLet(
        variable: receiverVariable,
        body: replacement,
      );
    }
    replacement.fileOffset = node.fileOffset;

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullIndexSet(
    IfNullIndexSet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: true,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    SyntheticVariable? receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (extern.isPureExpression(readReceiver)) {
      writeReceiver = extern.clonePureExpression(readReceiver);
    } else {
      receiverVariable = extern.createVariable(readReceiver, receiverType);
      readReceiver = extern.createVariableGet(receiverVariable);
      writeReceiver = extern.createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = findInterfaceMember(
      receiverType,
      indexGetName,
      node.readOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    MethodContravarianceCheckKind checkKind = preCheckInvocationContravariance(
      receiverType,
      readTarget,
      isThisReceiver: _isInternalThisExpression(node.receiver),
    );

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ObjectAccessTarget writeTarget = findInterfaceMember(
      receiverType,
      indexSetName,
      node.writeOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    DartType writeIndexType = writeTarget.getIndexKeyType(this);
    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      readIndexType,
      isVoidAllowed: true,
    );

    SyntheticVariable? indexVariable;
    Expression readIndex = indexResult.expression;
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromotedIndex =
        flowAnalysis.whyNotPromoted(getExpressionInfo(readIndex));
    Expression writeIndex;
    if (extern.isPureExpression(readIndex)) {
      writeIndex = extern.clonePureExpression(readIndex);
    } else {
      indexVariable = extern.createVariable(
        readIndex,
        indexResult.inferredType,
      );
      readIndex = extern.createVariableGet(indexVariable);
      writeIndex = extern.createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      whyNotPromoted: whyNotPromotedIndex,
      assignedNode: node.index,
    );

    ExpressionInferenceResult readResult = _computeIndexGet(
      node.readOffset,
      readReceiver,
      receiverType,
      readTarget,
      readIndex,
      readIndexType,
      checkKind,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(read),
      new SharedTypeView(readType),
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      whyNotPromoted: whyNotPromotedIndex,
      assignedNode: node.index,
    );

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: node.value,
    );
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
      nonNullableReadType: nonNullableReadType,
      rhsType: valueResult.inferredType,
      typeContext: typeContext,
    );

    SyntheticVariable? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
      // No need for value variable.
    } else if (extern.isPureExpression(value)) {
      returnedValue = extern.clonePureExpression(value);
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
      returnedValue = extern.createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
      node.writeOffset,
      writeReceiver,
      receiverType,
      writeTarget,
      writeIndex,
      writeIndexType,
      value,
      valueType,
    );

    Expression inner;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let indexVariable = a in
      //         o[indexVariable] == null ? o.[]=(indexVariable, b) : null
      //
      Expression equalsNull = extern.createEqualsNull(
        read,
        fileOffset: node.testOffset,
      );
      ConditionalExpression conditional = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        write,
        extern.createNullLiteral(fileOffset: node.testOffset),
        computeNullable(inferredType),
      );
      inner = conditional;
    } else {
      // Encode `o[a] ??= b` as:
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
      SyntheticVariable readVariable = extern.createVariable(read, readType);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(readVariable),
        fileOffset: node.testOffset,
      );
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      VariableGet variableGet = extern.createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      Expression result = extern.createLet(
        variable: writeVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        result = extern.createLet(variable: valueVariable, body: result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        result,
        variableGet,
        inferredType,
      );
      inner = extern.createLet(variable: readVariable, body: conditional);
    }
    if (indexVariable != null) {
      inner = extern.createLet(variable: indexVariable, body: inner);
    }

    Expression replacement;
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, inner)
        ..fileOffset = receiverVariable.fileOffset;
    } else {
      replacement = inner;
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitIfNullSuperIndexSet(
    IfNullSuperIndexSet node,
    DartType typeContext,
  ) {
    ObjectAccessTarget readTarget = node.getter != null
        ? (thisType!.classNode.isMixinDeclaration
              ? new ObjectAccessTarget.interfaceMember(
                  thisType!,
                  node.getter!,
                  hasNonObjectMemberAccess: true,
                )
              : new ObjectAccessTarget.superMember(thisType!, node.getter!))
        : const ObjectAccessTarget.missing();

    DartType readType = readTarget.getReturnType(this);
    DartType readIndexType = readTarget.getIndexKeyType(this);

    ObjectAccessTarget writeTarget = node.setter != null
        ? (thisType!.classNode.isMixinDeclaration
              ? new ObjectAccessTarget.interfaceMember(
                  thisType!,
                  node.setter!,
                  hasNonObjectMemberAccess: true,
                )
              : new ObjectAccessTarget.superMember(thisType!, node.setter!))
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = writeTarget.getIndexKeyType(this);
    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      readIndexType,
      isVoidAllowed: true,
    );

    SyntheticVariable? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (extern.isPureExpression(readIndex)) {
      writeIndex = extern.clonePureExpression(readIndex);
    } else {
      indexVariable = extern.createVariable(
        readIndex,
        indexResult.inferredType,
      );
      readIndex = extern.createVariableGet(indexVariable);
      writeIndex = extern.createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      assignedNode: node.index,
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      assignedNode: node.index,
    );

    assert(readTarget.isInstanceMember || readTarget.isSuperMember);
    Expression read = new SuperMethodInvocation(
      new ThisExpression(),
      indexGetName,
      new Arguments(<Expression>[readIndex])..fileOffset = node.readOffset,
      readTarget.classMember as Procedure,
    )..fileOffset = node.readOffset;

    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(read),
      new SharedTypeView(readType),
    );
    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: node.value,
    );
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
      nonNullableReadType: nonNullableReadType,
      rhsType: valueResult.inferredType,
      typeContext: typeContext,
    );

    SyntheticVariable? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
      // No need for a value variable.
    } else if (extern.isPureExpression(value)) {
      returnedValue = extern.clonePureExpression(value);
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
      returnedValue = extern.createVariableGet(valueVariable);
    }

    assert(writeTarget.isInstanceMember || writeTarget.isSuperMember);
    Expression write = new SuperMethodInvocation(
      new ThisExpression(),
      indexSetName,
      new Arguments(<Expression>[writeIndex, value])
        ..fileOffset = node.writeOffset,
      writeTarget.classMember as Procedure,
    )..fileOffset = node.writeOffset;

    Expression replacement;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = a in
      //        super[v1] == null ? super.[]=(v1, b) : null
      //
      assert(valueVariable == null);
      Expression equalsNull = extern.createEqualsNull(
        read,
        fileOffset: node.testOffset,
      );
      replacement = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        write,
        extern.createNullLiteral(fileOffset: node.testOffset),
        computeNullable(inferredType),
      );
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

      SyntheticVariable readVariable = extern.createVariable(read, readType);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(readVariable),
        fileOffset: node.testOffset,
      );
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      VariableGet readVariableGet = extern.createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = extern.createLet(
        variable: writeVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        result = extern.createLet(variable: valueVariable, body: result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        result,
        readVariableGet,
        inferredType,
      );
      replacement = extern.createLet(variable: readVariable, body: conditional);
    }
    if (indexVariable != null) {
      replacement = extern.createLet(
        variable: indexVariable,
        body: replacement,
      );
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitExtensionIfNullIndexSet(
    ExtensionIfNullIndexSet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.knownTypeArguments,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverResult.inferredType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.knownTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (extern.isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
      readReceiver = extern.createVariableGet(receiverVariable);
      writeReceiver = extern.createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = new ExtensionAccessTarget(
      receiverType,
      node.getter,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ObjectAccessTarget writeTarget = new ExtensionAccessTarget(
      receiverType,
      node.setter,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    DartType writeIndexType = writeTarget.getIndexKeyType(this);
    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      readIndexType,
      isVoidAllowed: true,
    );

    SyntheticVariable? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (extern.isPureExpression(readIndex)) {
      writeIndex = extern.clonePureExpression(readIndex);
    } else {
      indexVariable = extern.createVariable(
        readIndex,
        indexResult.inferredType,
      );
      readIndex = extern.createVariableGet(indexVariable);
      writeIndex = extern.createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      assignedNode: node.index,
    );

    ExpressionInferenceResult readResult = _computeIndexGet(
      node.readOffset,
      readReceiver,
      receiverType,
      readTarget,
      readIndex,
      readIndexType,
      MethodContravarianceCheckKind.none,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    flowAnalysis.ifNullExpression_rightBegin(
      getExpressionInfo(read),
      new SharedTypeView(readType),
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      assignedNode: node.index,
    );

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(
      valueType,
      valueResult,
      assignedNode: node.value,
    );
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
      nonNullableReadType: nonNullableReadType,
      rhsType: valueResult.inferredType,
      typeContext: typeContext,
    );

    SyntheticVariable? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
      // No need for a value variable.
    } else if (extern.isPureExpression(value)) {
      returnedValue = extern.clonePureExpression(value);
    } else {
      valueVariable = extern.createVariable(value, valueResult.inferredType);
      value = extern.createVariableGet(valueVariable);
      returnedValue = extern.createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
      node.writeOffset,
      writeReceiver,
      receiverType,
      writeTarget,
      writeIndex,
      writeIndexType,
      value,
      valueType,
    );

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
      Expression equalsNull = extern.createEqualsNull(
        read,
        fileOffset: node.testOffset,
      );
      replacement = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        write,
        extern.createNullLiteral(fileOffset: node.testOffset),
        computeNullable(inferredType),
      );
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
      SyntheticVariable readVariable = extern.createVariable(read, readType);
      Expression equalsNull = extern.createEqualsNull(
        extern.createVariableGet(readVariable),
        fileOffset: node.testOffset,
      );
      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      VariableGet readVariableGet = extern.createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = extern.createLet(
        variable: writeVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        result = extern.createLet(variable: valueVariable, body: result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        result,
        readVariableGet,
        inferredType,
      );
      replacement = extern.createLet(variable: readVariable, body: conditional);
    }
    if (indexVariable != null) {
      replacement = extern.createLet(
        variable: indexVariable,
        body: replacement,
      );
    }
    if (receiverVariable != null) {
      replacement = extern.createLet(
        variable: receiverVariable,
        body: replacement,
      );
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  bool _isNull(Expression node) {
    return node is InternalNullLiteral ||
        node is NullLiteral ||
        node is ConstantExpression &&
            // Coverage-ignore(suite): Not run.
            node.constant is NullConstant;
  }

  /// Creates an equals expression of using [left] and [right] as operands.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [leftType] is
  /// the already inferred type of the [left] expression. The inferred type of
  /// [right] is computed by this method. If [isNot] is `true` the result is
  /// negated to perform a != operation.
  ExpressionInferenceResult _computeEqualsExpression(
    int fileOffset,
    Expression left,
    DartType leftType,
    InternalExpression right, {
    required bool isNot,
  }) {
    ExpressionInfo? equalityInfo = getExpressionInfo(left);

    // When evaluating exactly a dot shorthand in the RHS, we use the LHS type
    // to provide the context type for the shorthand.
    DartType rightTypeContext = right is DotShorthand
        ? leftType
        : const UnknownType();
    ExpressionInferenceResult rightResult = inferExpression(
      right,
      rightTypeContext,
      isVoidAllowed: false,
    );

    Expression inferredRight = rightResult.expression;
    Expression? equals;
    if (_isNull(inferredRight)) {
      equals = new EqualsNull(left)..fileOffset = fileOffset;
    } else if (_isNull(left)) {
      equals = new EqualsNull(inferredRight)..fileOffset = fileOffset;
    }
    if (equals != null) {
      if (isNot) {
        equals = new Not(equals)..fileOffset = fileOffset;
      }
      storeExpressionInfo(
        equals,
        flowAnalysis.equalityOperation_end(
          equalityInfo,
          new SharedTypeView(leftType),
          getExpressionInfo(inferredRight),
          new SharedTypeView(rightResult.inferredType),
          notEqual: isNot,
        ),
      );
      return new ExpressionInferenceResult(
        coreTypes.boolRawType(Nullability.nonNullable),
        equals,
      );
    }

    ObjectAccessTarget equalsTarget = findInterfaceMember(
      leftType,
      equalsName,
      fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    assert(
      equalsTarget.isInstanceMember ||
          equalsTarget.isObjectMember ||
          equalsTarget.isNever,
      "Unexpected equals target $equalsTarget for "
      "$left ($leftType) == $right.",
    );
    DartType rightType = operations.makeNullableInternal(
      equalsTarget.getBinaryOperandType(this),
    );
    DartType contextType = rightType.withDeclaredNullability(
      Nullability.nullable,
    );
    rightResult = ensureAssignableResult(
      contextType,
      rightResult,
      errorTemplate: diag.argumentTypeNotAssignable,
      assignedNode: right,
    );
    inferredRight = rightResult.expression;

    FunctionType functionType = equalsTarget
        .getFunctionType(this)
        .equalsFunctionType;
    equals = new EqualsCall(
      left,
      inferredRight,
      functionType: functionType,
      interfaceTarget: equalsTarget.classMember as Procedure,
    )..fileOffset = fileOffset;
    if (isNot) {
      equals = new Not(equals)..fileOffset = fileOffset;
    }

    storeExpressionInfo(
      equals,
      flowAnalysis.equalityOperation_end(
        equalityInfo,
        new SharedTypeView(leftType),
        getExpressionInfo(inferredRight),
        new SharedTypeView(rightResult.inferredType),
        notEqual: isNot,
      ),
    );
    return new ExpressionInferenceResult(
      equalsTarget.isNever
          ? const NeverType.nonNullable()
          : coreTypes.boolRawType(Nullability.nonNullable),
      equals,
    );
  }

  /// Creates a binary expression of the binary operator with [binaryName] using
  /// [left] and [right] as operands.
  ///
  /// [fileOffset] is used as the file offset for created nodes. [leftType] is
  /// the already inferred type of the [left] expression. The inferred type of
  /// [right] is computed by this method.
  ///
  /// [invocationNode] is the internal node for the invocation of the binary
  /// operator.
  ExpressionInferenceResult _computeBinaryExpression({
    required int fileOffset,
    required DartType contextType,
    required Expression left,
    required DartType leftType,
    required Name binaryName,
    required InternalExpression right,
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
    required InternalNode invocationNode,
  }) {
    assert(binaryName != equalsName);

    ObjectAccessTarget binaryTarget = findInterfaceMember(
      leftType,
      binaryName,
      fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      OverwrittenInterfaceMember? overWritten = expressionEvaluationHelper
          ?.overwriteFindInterfaceMember(
            target: binaryTarget,
            name: binaryName,
            receiverType: leftType,
            setter: false,
          );
      if (overWritten != null) {
        binaryTarget = overWritten.target;
      }
    }

    MethodContravarianceCheckKind binaryCheckKind =
        preCheckInvocationContravariance(
          leftType,
          binaryTarget,
          isThisReceiver: false,
        );

    DartType binaryType = binaryTarget.getReturnType(this);
    DartType rightType = binaryTarget.getBinaryOperandType(this);

    bool isSpecialCasedBinaryOperator = binaryTarget
        .isSpecialCasedBinaryOperator(this);

    DartType rightContextType = rightType;
    if (isSpecialCasedBinaryOperator) {
      rightContextType = typeSchemaEnvironment
          .getContextTypeOfSpecialCasedBinaryOperator(
            contextType,
            leftType,
            rightType,
          );
    }

    ExpressionInferenceResult rightResult = inferExpression(
      right,
      rightContextType,
      isVoidAllowed: true,
    );

    rightResult = ensureAssignableResult(
      rightType,
      rightResult,
      assignedNode: right,
    );
    Expression inferredRight = rightResult.expression;

    if (isSpecialCasedBinaryOperator) {
      binaryType = typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
        leftType,
        rightResult.inferredType,
      );
    }

    Expression binary;
    switch (binaryTarget.kind) {
      case ObjectAccessTargetKind.missing:
        binary = createMissingBinary(
          fileOffset,
          left,
          leftType,
          binaryName,
          inferredRight,
        );
        break;
      case ObjectAccessTargetKind.ambiguous:
        binary = createMissingBinary(
          fileOffset,
          left,
          leftType,
          binaryName,
          inferredRight,
          extensionAccessCandidates: binaryTarget.candidates,
        );
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        assert(binaryTarget.declarationMethodKind != ClassMemberKind.Setter);
        binary = new StaticInvocation(
          binaryTarget.member as Procedure,
          new Arguments(
            <Expression>[left, inferredRight],
            types: binaryTarget.receiverTypeArguments,
          )..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        binary = new DynamicInvocation(
          DynamicAccessKind.Invalid,
          left,
          binaryName,
          new Arguments(<Expression>[inferredRight])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        binary = new DynamicInvocation(
          DynamicAccessKind.Dynamic,
          left,
          binaryName,
          new Arguments(<Expression>[inferredRight])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        binary = new DynamicInvocation(
          DynamicAccessKind.Never,
          left,
          binaryName,
          new Arguments(<Expression>[inferredRight])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.superMember:
        InstanceInvocation instanceInvocation = binary = new InstanceInvocation(
          InstanceAccessKind.Instance,
          left,
          binaryName,
          new Arguments(<Expression>[inferredRight])..fileOffset = fileOffset,
          functionType: new FunctionType(
            [rightType],
            binaryType,
            Nullability.nonNullable,
          ),
          interfaceTarget: binaryTarget.classMember as Procedure,
        )..fileOffset = fileOffset;

        if (binaryCheckKind ==
            MethodContravarianceCheckKind.checkMethodReturn) {
          instanceInvocation.resultType = coreTypes.objectNullableRawType;
          binary = new AsExpression(binary, binaryType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..fileOffset = fileOffset;
        }
        break;
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
      case ObjectAccessTargetKind.expressionEvaluationParameter:
        throw new UnsupportedError('Unexpected binary target ${binaryTarget}');
    }

    if (binaryTarget.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        whyNotPromoted?.call(),
        invocationNode,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      Expression replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nullableOperatorCallError.withArguments(
            operator: binaryName.text,
            receiverType: leftType,
          ),
          fileUri: fileUri,
          fileOffset: binary.fileOffset,
          length: binaryName.text.length,
          context: context,
        ),
        expression: binary,
      );
      libraryBuilder.loader.dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.registerExternalNode(invocationNode, replacement);
      return new ExpressionInferenceResult(binaryType, replacement);
    }
    return new ExpressionInferenceResult(binaryType, binary);
  }

  /// Creates a unary expression of the unary operator with [unaryName] using
  /// [expression] as the operand.
  ///
  /// [fileOffset] is used as the file offset for created nodes.
  /// [expressionType] is the already inferred type of the [expression].
  ///
  /// [invocationNode] is the internal node for the invocation of the unary
  /// operator.
  ExpressionInferenceResult _computeUnaryExpression({
    required int fileOffset,
    required Expression expression,
    required DartType expressionType,
    required Name unaryName,
    required Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted,
    required InternalNode invocationNode,
  }) {
    ObjectAccessTarget unaryTarget = findInterfaceMember(
      expressionType,
      unaryName,
      fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      OverwrittenInterfaceMember? overWritten = expressionEvaluationHelper
          ?.overwriteFindInterfaceMember(
            target: unaryTarget,
            name: unaryName,
            receiverType: expressionType,
            setter: false,
          );
      if (overWritten != null) {
        unaryTarget = overWritten.target;
      }
    }

    MethodContravarianceCheckKind unaryCheckKind =
        preCheckInvocationContravariance(
          expressionType,
          unaryTarget,
          isThisReceiver: false,
        );

    DartType unaryType = unaryTarget.getReturnType(this);

    Expression unary;
    switch (unaryTarget.kind) {
      case ObjectAccessTargetKind.missing:
        unary = createMissingUnary(
          fileOffset,
          expression,
          expressionType,
          unaryName,
        );
        break;
      case ObjectAccessTargetKind.ambiguous:
        unary = createMissingUnary(
          fileOffset,
          expression,
          expressionType,
          unaryName,
          extensionAccessCandidates: unaryTarget.candidates,
        );
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        assert(unaryTarget.declarationMethodKind != ClassMemberKind.Setter);
        unary = new StaticInvocation(
          unaryTarget.member as Procedure,
          new Arguments(<Expression>[
            expression,
          ], types: unaryTarget.receiverTypeArguments)..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        unary = new DynamicInvocation(
          DynamicAccessKind.Invalid,
          expression,
          unaryName,
          new Arguments(<Expression>[])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        unary = new DynamicInvocation(
          DynamicAccessKind.Never,
          expression,
          unaryName,
          new Arguments(<Expression>[])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        unary = new DynamicInvocation(
          DynamicAccessKind.Dynamic,
          expression,
          unaryName,
          new Arguments(<Expression>[])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.superMember:
        InstanceInvocation instanceInvocation = unary = new InstanceInvocation(
          InstanceAccessKind.Instance,
          expression,
          unaryName,
          new Arguments(<Expression>[])..fileOffset = fileOffset,
          functionType: new FunctionType(
            <DartType>[],
            unaryType,
            Nullability.nonNullable,
          ),
          interfaceTarget: unaryTarget.classMember as Procedure,
        )..fileOffset = fileOffset;

        if (unaryCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
          // Coverage-ignore-block(suite): Not run.
          instanceInvocation.resultType = coreTypes.objectNullableRawType;
          unary = new AsExpression(unary, unaryType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..fileOffset = fileOffset;
        }
        break;
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
      case ObjectAccessTargetKind.expressionEvaluationParameter:
        throw new UnsupportedError('Unexpected unary target ${unaryTarget}');
    }

    if (unaryTarget.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        whyNotPromoted(),
        invocationNode,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      // TODO(johnniwinther): Special case 'unary-' in messages. It should
      // probably be referred to as "Unary operator '-' ...".
      Expression replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nullableOperatorCallError.withArguments(
            operator: unaryName.text,
            receiverType: expressionType,
          ),
          fileUri: fileUri,
          fileOffset: unary.fileOffset,
          length: unaryName == unaryMinusName
              ? 1
              :
                // Coverage-ignore(suite): Not run.
                unaryName.text.length,
          context: context,
        ),
        expression: unary,
      );
      libraryBuilder.loader.dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.registerExternalNode(invocationNode, replacement);
      return new ExpressionInferenceResult(unaryType, replacement);
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
    MethodContravarianceCheckKind readCheckKind,
  ) {
    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      OverwrittenInterfaceMember? overWritten = expressionEvaluationHelper
          ?.overwriteFindInterfaceMember(
            target: readTarget,
            name: indexGetName,
            receiverType: receiverType,
            setter: false,
          );
      if (overWritten != null) {
        readTarget = overWritten.target;
      }
    }
    Expression read;
    DartType readType = readTarget.getReturnType(this);
    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = createMissingIndexGet(
          fileOffset,
          readReceiver,
          receiverType,
          readIndex,
        );
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = createMissingIndexGet(
          fileOffset,
          readReceiver,
          receiverType,
          readIndex,
          extensionAccessCandidates: readTarget.candidates,
        );
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        read = new StaticInvocation(
          readTarget.member as Procedure,
          new Arguments(<Expression>[
            readReceiver,
            readIndex,
          ], types: readTarget.receiverTypeArguments)..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        read = new DynamicInvocation(
          DynamicAccessKind.Invalid,
          readReceiver,
          indexGetName,
          new Arguments(<Expression>[readIndex])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        read = new DynamicInvocation(
          DynamicAccessKind.Never,
          readReceiver,
          indexGetName,
          new Arguments(<Expression>[readIndex])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        read = new DynamicInvocation(
          DynamicAccessKind.Dynamic,
          readReceiver,
          indexGetName,
          new Arguments(<Expression>[readIndex])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.superMember:
        InstanceAccessKind kind;
        switch (readTarget.kind) {
          case ObjectAccessTargetKind.instanceMember:
            kind = InstanceAccessKind.Instance;
            break;
          case ObjectAccessTargetKind.nullableInstanceMember:
            kind = InstanceAccessKind.Nullable;
            break;
          // Coverage-ignore(suite): Not run.
          case ObjectAccessTargetKind.objectMember:
            kind = InstanceAccessKind.Object;
            break;
          // Coverage-ignore(suite): Not run.
          default:
            throw new UnsupportedError('Unexpected target kind $readTarget');
        }
        InstanceInvocation instanceInvocation = read = new InstanceInvocation(
          kind,
          readReceiver,
          indexGetName,
          new Arguments(<Expression>[readIndex])..fileOffset = fileOffset,
          functionType: new FunctionType(
            [indexType],
            readType,
            Nullability.nonNullable,
          ),
          interfaceTarget: readTarget.classMember as Procedure,
        )..fileOffset = fileOffset;
        if (readCheckKind == MethodContravarianceCheckKind.checkMethodReturn) {
          instanceInvocation.resultType = coreTypes.objectNullableRawType;
          read = new AsExpression(read, readType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..fileOffset = fileOffset;
        }
        break;
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
      case ObjectAccessTargetKind.expressionEvaluationParameter:
        throw new UnsupportedError('Unexpected index get target ${readTarget}');
    }

    if (readTarget.isNullable) {
      return new ExpressionInferenceResult(
        readType,
        extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nullableOperatorCallError.withArguments(
              operator: indexGetName.text,
              receiverType: receiverType,
            ),
            fileUri: fileUri,
            fileOffset: read.fileOffset,
            length: noLength,
          ),
          expression: read,
        ),
      );
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
    DartType valueType,
  ) {
    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      OverwrittenInterfaceMember? overWritten = expressionEvaluationHelper
          ?.overwriteFindInterfaceMember(
            target: writeTarget,
            name: indexSetName,
            receiverType: receiverType,
            setter: true,
          );
      if (overWritten != null) {
        writeTarget = overWritten.target;
      }
    }
    Expression write;
    switch (writeTarget.kind) {
      case ObjectAccessTargetKind.missing:
        write = createMissingIndexSet(
          fileOffset,
          receiver,
          receiverType,
          index,
          value,
          forEffect: true,
        );
        break;
      case ObjectAccessTargetKind.ambiguous:
        write = createMissingIndexSet(
          fileOffset,
          receiver,
          receiverType,
          index,
          value,
          forEffect: true,
          extensionAccessCandidates: writeTarget.candidates,
        );
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        assert(writeTarget.declarationMethodKind != ClassMemberKind.Setter);
        write = new StaticInvocation(
          writeTarget.member as Procedure,
          new Arguments(<Expression>[
            receiver,
            index,
            value,
          ], types: writeTarget.receiverTypeArguments)..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        write = new DynamicInvocation(
          DynamicAccessKind.Invalid,
          receiver,
          indexSetName,
          new Arguments(<Expression>[index, value])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        write = new DynamicInvocation(
          DynamicAccessKind.Never,
          receiver,
          indexSetName,
          new Arguments(<Expression>[index, value])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        write = new DynamicInvocation(
          DynamicAccessKind.Dynamic,
          receiver,
          indexSetName,
          new Arguments(<Expression>[index, value])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.superMember:
        InstanceAccessKind kind;
        switch (writeTarget.kind) {
          case ObjectAccessTargetKind.instanceMember:
            kind = InstanceAccessKind.Instance;
            break;
          case ObjectAccessTargetKind.nullableInstanceMember:
            kind = InstanceAccessKind.Nullable;
            break;
          // Coverage-ignore(suite): Not run.
          case ObjectAccessTargetKind.objectMember:
            kind = InstanceAccessKind.Object;
            break;
          // Coverage-ignore(suite): Not run.
          default:
            throw new UnsupportedError('Unexpected target kind $writeTarget');
        }
        write = new InstanceInvocation(
          kind,
          receiver,
          indexSetName,
          new Arguments(<Expression>[index, value])..fileOffset = fileOffset,
          functionType: new FunctionType(
            [indexType, valueType],
            const VoidType(),
            Nullability.nonNullable,
          ),
          interfaceTarget: writeTarget.classMember as Procedure,
        )..fileOffset = fileOffset;
        break;
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
      case ObjectAccessTargetKind.expressionEvaluationParameter:
        throw new UnsupportedError(
          'Unexpected index set target ${writeTarget}',
        );
    }
    if (writeTarget.isNullable) {
      return extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nullableOperatorCallError.withArguments(
            operator: indexSetName.text,
            receiverType: receiverType,
          ),
          fileUri: fileUri,
          fileOffset: write.fileOffset,
          length: noLength,
        ),
        expression: write,
      );
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
  ///
  /// [accessNode] is the internal node for the access to [propertyName].
  PropertyGetInferenceResult _computePropertyGet({
    required int fileOffset,
    required Expression receiver,
    required DartType receiverType,
    required Name propertyName,
    required DartType typeContext,
    required bool isThisReceiver,
    ObjectAccessTarget? readTarget,
    bool? isImplicitThis,
    required InternalNode accessNode,
  }) {
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(getExpressionInfo(receiver));

    readTarget ??= findInterfaceMember(
      receiverType,
      propertyName,
      fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    DartType readType = readTarget.getGetterType(this);
    var (
      SharedTypeView? wrappedPromotedReadType,
      ExpressionInfo? expressionInfo,
    ) = flowAnalysis.propertyGet(
      computePropertyTarget(receiver),
      propertyName.text,
      readTarget is ExtensionTypeRepresentationAccessTarget
          ? readTarget.representationField
          : readTarget.member,
      new SharedTypeView(readType),
    );
    DartType? promotedReadType = wrappedPromotedReadType?.unwrapTypeView();
    PropertyGetInferenceResult result = createPropertyGet(
      fileOffset: fileOffset,
      receiver: receiver,
      receiverType: receiverType,
      propertyName: propertyName,
      typeContext: typeContext,
      readTarget: readTarget,
      readType: readType,
      promotedReadType: promotedReadType,
      isThisReceiver: isThisReceiver,
      whyNotPromoted: whyNotPromoted,
      isImplicitThis: isImplicitThis,
      expressionInfo: expressionInfo,
      accessNode: accessNode,
    );
    storeExpressionInfo(
      result.expressionInferenceResult.expression,
      expressionInfo,
    );
    return result;
  }

  ExpressionInferenceResult visitCompoundIndexSet(
    CompoundIndexSet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      isVoidAllowed: true,
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    SyntheticVariable? receiverVariable;
    Expression readReceiver = receiver;
    Expression writeReceiver;
    if (extern.isPureExpression(readReceiver)) {
      writeReceiver = extern.clonePureExpression(readReceiver);
    } else {
      receiverVariable = extern.createVariable(readReceiver, receiverType);
      readReceiver = extern.createVariableGet(receiverVariable);
      writeReceiver = extern.createVariableGet(receiverVariable);
    }

    ObjectAccessTarget readTarget = findInterfaceMember(
      receiverType,
      indexGetName,
      node.readOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    MethodContravarianceCheckKind readCheckKind =
        preCheckInvocationContravariance(
          receiverType,
          readTarget,
          isThisReceiver: _isInternalThisExpression(node.receiver),
        );

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      readIndexType,
      isVoidAllowed: true,
    );

    SyntheticVariable? indexVariable;
    Expression readIndex = indexResult.expression;
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromotedIndex =
        flowAnalysis.whyNotPromoted(getExpressionInfo(readIndex));
    Expression writeIndex;
    if (extern.isPureExpression(readIndex)) {
      writeIndex = extern.clonePureExpression(readIndex);
    } else {
      indexVariable = extern.createVariable(
        readIndex,
        indexResult.inferredType,
      );
      readIndex = extern.createVariableGet(indexVariable);
      writeIndex = extern.createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      whyNotPromoted: whyNotPromotedIndex,
      assignedNode: node.index,
    );

    ExpressionInferenceResult readResult = _computeIndexGet(
      node.readOffset,
      readReceiver,
      receiverType,
      readTarget,
      readIndex,
      readIndexType,
      readCheckKind,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    SyntheticVariable? leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = extern.createVariable(read, readType);
      left = extern.createVariableGet(leftVariable);
    } else {
      left = read;
    }

    ObjectAccessTarget writeTarget = findInterfaceMember(
      receiverType,
      indexSetName,
      node.writeOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    DartType writeIndexType = writeTarget.getIndexKeyType(this);

    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.binaryOffset,
      contextType: valueType,
      left: left,
      leftType: readType,
      binaryName: node.binaryName,
      right: node.value,
      whyNotPromoted: null,
      invocationNode: node,
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      whyNotPromoted: whyNotPromotedIndex,
      assignedNode: node.index,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      fileOffset: node.fileOffset,
      assignedNode: node,
    );
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    SyntheticVariable? valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = extern.createVariable(binary, binaryType);
      valueExpression = extern.createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
      node.writeOffset,
      writeReceiver,
      receiverType,
      writeTarget,
      writeIndex,
      writeIndexType,
      valueExpression,
      valueType,
    );

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

      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      inner = extern.createLet(
        variable: leftVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(leftVariable),
        ),
      );
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

      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      inner = extern.createLet(
        variable: valueVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    if (indexVariable != null) {
      inner = extern.createLet(variable: indexVariable, body: inner);
    }

    Expression replacement;
    if (receiverVariable != null) {
      replacement = extern.createLet(
        variable: receiverVariable,
        body: inner,
        fileOffset: node.fileOffset,
      );
    } else {
      replacement = inner;
    }
    return new ExpressionInferenceResult(
      node.forPostIncDec ? readType : binaryType,
      replacement,
    );
  }

  ExpressionInferenceResult visitCompoundSuperIndexSet(
    CompoundSuperIndexSet node,
    DartType typeContext,
  ) {
    ObjectAccessTarget readTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(
            thisType!,
            node.getter,
            hasNonObjectMemberAccess: true,
          )
        : new ObjectAccessTarget.superMember(thisType!, node.getter);

    DartType readType = readTarget.getReturnType(this);
    DartType readIndexType = readTarget.getIndexKeyType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      readIndexType,
      isVoidAllowed: true,
    );

    SyntheticVariable? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (extern.isPureExpression(readIndex)) {
      writeIndex = extern.clonePureExpression(readIndex);
    } else {
      indexVariable = extern.createVariable(
        readIndex,
        indexResult.inferredType,
      );
      readIndex = extern.createVariableGet(indexVariable);
      writeIndex = extern.createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      assignedNode: node.index,
    );

    assert(readTarget.isInstanceMember || readTarget.isSuperMember);
    Expression read = new SuperMethodInvocation(
      new ThisExpression(),
      indexGetName,
      new Arguments(<Expression>[readIndex])..fileOffset = node.readOffset,
      readTarget.classMember as Procedure,
    )..fileOffset = node.readOffset;

    SyntheticVariable? leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = extern.createVariable(read, readType);
      left = extern.createVariableGet(leftVariable);
    } else {
      left = read;
    }
    ObjectAccessTarget writeTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(
            thisType!,
            node.setter,
            hasNonObjectMemberAccess: true,
          )
        : new ObjectAccessTarget.superMember(thisType!, node.setter);

    DartType writeIndexType = writeTarget.getIndexKeyType(this);

    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.binaryOffset,
      contextType: valueType,
      left: left,
      leftType: readType,
      binaryName: node.binaryName,
      right: node.value,
      whyNotPromoted: null,
      invocationNode: node,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      fileOffset: node.fileOffset,
      assignedNode: node,
    );
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      assignedNode: node.index,
    );

    SyntheticVariable? valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = extern.createVariable(binary, binaryType);
      valueExpression = extern.createVariableGet(valueVariable);
    }

    assert(writeTarget.isInstanceMember || writeTarget.isSuperMember);
    Expression write = new SuperMethodInvocation(
      new ThisExpression(),
      indexSetName,
      new Arguments(<Expression>[writeIndex, valueExpression])
        ..fileOffset = node.writeOffset,
      writeTarget.classMember as Procedure,
    )..fileOffset = node.writeOffset;

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

      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: leftVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(leftVariable),
        ),
      );
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

      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    if (indexVariable != null) {
      replacement = extern.createLet(
        variable: indexVariable,
        body: replacement,
      );
    }
    return new ExpressionInferenceResult(
      node.forPostIncDec ? readType : binaryType,
      replacement,
    );
  }

  ExpressionInferenceResult visitExtensionCompoundIndexSet(
    ExtensionCompoundIndexSet node,
    DartType typeContext,
  ) {
    DartType receiverContextType = computeExplicitExtensionReceiverContextType(
      node.extension,
      node.explicitTypeArguments?.types,
    );

    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      receiverContextType,
      isVoidAllowed: false,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.explicitTypeArguments?.types,
      receiverType,
      internalNodeForTesting: node,
    );
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: node.extension.name,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.extensionTypeArgumentOffset ?? node.fileOffset,
      hasInferredTypeArguments: node.explicitTypeArguments == null,
      typeParameters: node.extension.typeParameters,
      explicitOrInferredTypeArguments: extensionTypeArguments,
    );

    DartType extensionOnType = getExtensionReceiverType(
      node.extension,
      extensionTypeArguments,
    );

    receiver = ensureAssignable(
      extensionOnType,
      receiverType,
      receiver,
      assignedNode: node.receiver,
    );
    receiverType = extensionOnType;

    ObjectAccessTarget readTarget = new ExtensionAccessTarget(
      receiverType,
      node.getter,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    SyntheticVariable? receiverVariable;
    Expression readReceiver;
    Expression writeReceiver;
    if (extern.isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = extern.clonePureExpression(receiver);
    } else {
      receiverVariable = extern.createVariable(receiver, receiverType);
      readReceiver = extern.createVariableGet(receiverVariable);
      writeReceiver = extern.createVariableGet(receiverVariable);
    }

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      readIndexType,
      isVoidAllowed: true,
    );

    SyntheticVariable? indexVariable;
    Expression readIndex = indexResult.expression;
    Expression writeIndex;
    if (extern.isPureExpression(readIndex)) {
      writeIndex = extern.clonePureExpression(readIndex);
    } else {
      indexVariable = extern.createVariable(
        readIndex,
        indexResult.inferredType,
      );
      readIndex = extern.createVariableGet(indexVariable);
      writeIndex = extern.createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      assignedNode: node.index,
    );

    ExpressionInferenceResult readResult = _computeIndexGet(
      node.readOffset,
      readReceiver,
      receiverType,
      readTarget,
      readIndex,
      readIndexType,
      MethodContravarianceCheckKind.none,
    );
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    SyntheticVariable? leftVariable;
    Expression left;
    if (node.forEffect) {
      left = read;
    } else if (node.forPostIncDec) {
      leftVariable = extern.createVariable(read, readType);
      left = extern.createVariableGet(leftVariable);
    } else {
      left = read;
    }

    ObjectAccessTarget writeTarget = new ExtensionAccessTarget(
      receiverType,
      node.setter,
      null,
      ClassMemberKind.Method,
      extensionTypeArguments,
    );

    DartType writeIndexType = writeTarget.getIndexKeyType(this);

    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      fileOffset: node.binaryOffset,
      contextType: valueType,
      left: left,
      leftType: readType,
      binaryName: node.binaryName,
      right: node.rhs,
      whyNotPromoted: null,
      invocationNode: node,
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      assignedNode: node.index,
    );
    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      fileOffset: node.fileOffset,
      assignedNode: node,
    );
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    SyntheticVariable? valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = extern.createVariable(binary, binaryType);
      valueExpression = extern.createVariableGet(valueVariable);
    }

    Expression write = _computeIndexSet(
      node.writeOffset,
      writeReceiver,
      receiverType,
      writeTarget,
      writeIndex,
      writeIndexType,
      valueExpression,
      valueType,
    );

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

      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: leftVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(leftVariable),
        ),
      );
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

      SyntheticVariable writeVariable = extern.createVariable(
        write,
        const VoidType(),
      );
      replacement = extern.createLet(
        variable: valueVariable!,
        body: extern.createLet(
          variable: writeVariable,
          body: extern.createVariableGet(valueVariable),
        ),
      );
    }
    if (indexVariable != null) {
      replacement = extern.createLet(
        variable: indexVariable,
        body: replacement,
      );
    }
    if (receiverVariable != null) {
      replacement = extern.createLet(
        variable: receiverVariable,
        body: replacement,
      );
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(
      node.forPostIncDec ? readType : binaryType,
      replacement,
    );
  }

  ExpressionInferenceResult visitInternalNullLiteral(
    InternalNullLiteral node,
    DartType typeContext,
  ) {
    const NullType nullType = const NullType();
    Expression replacement = extern.createNullLiteral(
      fileOffset: node.fileOffset,
    );
    storeExpressionInfo(
      replacement,
      flowAnalysis.nullLiteral(new SharedTypeView(nullType)),
    );
    return new ExpressionInferenceResult(nullType, replacement);
  }

  ExpressionInferenceResult visitInternalLet(
    InternalLet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      node.valueType,
      isVoidAllowed: true,
    );
    Expression value = valueResult.expression;
    ExpressionInferenceResult bodyResult = inferExpression(
      node.body,
      typeContext,
      isVoidAllowed: true,
    );
    Expression body = bodyResult.expression;
    DartType inferredType = bodyResult.inferredType;
    return new ExpressionInferenceResult(
      inferredType,
      extern.createLet(
        variable: extern.createUninitializedVariable(
          type: node.valueType,
          fileOffset: value.fileOffset,
          isFinal: true,
        ),
        value: value,
        body: body,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ExpressionInferenceResult visitAnonymousMethodExpression(
    AnonymousMethodExpression node,
    DartType typeContext,
  ) {
    DartType variableType = node.variable.type;
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (receiverType is VoidType) {
      receiver = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.voidExpression,
          fileUri: fileUri,
          fileOffset: receiver.fileOffset,
          length: noLength,
        ),
        expression: receiver,
      );
    }

    if (node.isImplicitlyTyped) {
      node.variable.type = node.isNullAware
          ? receiverType.toNonNull()
          : receiverType;
    } else {
      DartType checkedType = node.isNullAware
          ? receiverType.toNonNull()
          : receiverType;
      if (!isAssignable(variableType, checkedType)) {
        receiver = wrapUnassignableExpression(
          expression: receiver,
          expressionType: checkedType,
          contextType: variableType,
          message: diag.anonymousMethodWrongParameterTypeCfe.withArguments(
            receiverType: checkedType,
            parameterType: variableType,
          ),
          fileOffset: node.typeOffset,
          internalNode: node.receiver,
        );
      }
    }

    flowAnalysis.declare(
      node.variable,
      new SharedTypeView(node.variable.type),
      initialized: false,
    );
    flowAnalysis.initialize(
      node.variable,
      new SharedTypeView(node.variable.type),
      getExpressionInfo(receiver),
      isFinal: false,
      isLate: false,
      isImplicitlyTyped: node.isImplicitlyTyped,
      inheritPromotableProperties: node.isParameterless,
    );
    if (node.isNullAware) {
      flow.nullAwareAccess_rightBegin(
        getExpressionInfo(receiver),
        new SharedTypeView(receiverType),
        guardVariable: node.variable,
      );
    }

    if (node.isParameterless) {
      flow.thisBinding_begin(getExpressionInfo(receiver));
    }
    ExpressionInferenceResult bodyResult = inferExpression(
      node.body,
      typeContext,
      isVoidAllowed: true,
    );
    if (node.isParameterless) {
      flow.thisBinding_end();
    }

    if (node.isNullAware) {
      flow.nullAwareAccess_end();
    }

    DartType inferredType;
    Expression body;

    if (node.isCascade) {
      inferredType = receiverType;

      SyntheticVariable tempVar = extern.createVariable(
        bodyResult.expression,
        const DynamicType(),
        isFinal: false,
      )..fileOffset = node.fileOffset;

      body = extern.createLet(
        variable: tempVar,
        body: new VariableGet(node.variable.astVariable),
        fileOffset: node.fileOffset,
      );
    } else {
      inferredType = bodyResult.inferredType;
      body = bodyResult.expression;
    }

    Expression createLetOrBlock() {
      if (!libraryBuilder
          .loader
          .target
          .backendTarget
          .supportsLetVariableCapture) {
        DeclaredVariable resultVar = extern.createUninitializedVariable(
          type: inferredType,
          fileOffset: node.fileOffset,
        );
        return new BlockExpression(
          new Block([
            extern.createVariableStatement(
              extern.createVariableDeclaration(
                node.variable.astVariable,
                initializer: receiver,
              ),
            ),
            extern.createVariableStatement(
              extern.createVariableDeclaration(resultVar),
            ),
            new ExpressionStatement(new VariableSet(resultVar, body))
              ..fileOffset = node.fileOffset,
          ]),
          new VariableGet(resultVar),
        )..fileOffset = node.fileOffset;
      } else {
        return extern.createLet(
          variable: node.variable.astVariable,
          value: receiver,
          body: body,
          fileOffset: node.fileOffset,
        );
      }
    }

    Expression replacement;
    if (node.isNullAware) {
      SyntheticVariable tempVar = extern.createVariable(
        receiver,
        receiverType,
        cosmeticName: "anonymous#receiver",
        isFinal: false,
        fileOffset: node.fileOffset,
      );

      Expression condition = new EqualsNull(new VariableGet(tempVar));
      Expression thenExpression = extern.createNullLiteral(
        fileOffset: TreeNode.noOffset,
      );

      receiver = new AsExpression(new VariableGet(tempVar), node.variable.type)
        ..fileOffset = node.fileOffset;

      Expression elseExpression = createLetOrBlock();

      replacement = extern.createLet(
        variable: tempVar,
        body: new ConditionalExpression(
          condition,
          thenExpression,
          elseExpression,
          inferredType.withDeclaredNullability(Nullability.nullable),
        ),
        fileOffset: node.fileOffset,
      );

      inferredType = inferredType.withDeclaredNullability(Nullability.nullable);
    } else {
      replacement = createLetOrBlock();
    }

    if (node.isParameterless) {
      storeExpressionInfo(replacement, getExpressionInfo(body));
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitAnonymousMethodBlock(
    AnonymousMethodBlock node,
    DartType typeContext,
  ) {
    DeclaredVariable resultVar = extern.createUninitializedVariable(
      type: const DynamicType(),
      fileOffset: node.fileOffset,
    );
    // TODO(johnniwinther): Avoid the need for this.
    InternalLabeledStatement internalLabel = new InternalLabeledStatement(
      dummyInternalStatement,
      fileOffset: node.fileOffset,
    );
    LabeledStatement label = extern.createLabeledStatement(
      dummyStatement,
      fileOffset: node.fileOffset,
    );

    AnonymousMethodReturnContext context = new AnonymousMethodReturnContext(
      resultVariable: resultVar,
      internalLabel: internalLabel,
      label: label,
      typeContext: typeContext,
    );
    _returnContexts.push(context);

    DartType variableType = node.variable.type;
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;
    ExpressionInfo? receiverInfo = getExpressionInfo(receiver);

    if (receiverType is VoidType) {
      receiver = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.voidExpression,
          fileUri: fileUri,
          fileOffset: receiver.fileOffset,
          length: noLength,
        ),
        expression: receiver,
      );
    }

    if (node.isImplicitlyTyped) {
      node.variable.type = node.isNullAware
          ? receiverType.toNonNull()
          : receiverType;
    } else {
      DartType checkedType = node.isNullAware
          ? receiverType.toNonNull()
          : receiverType;
      if (!isAssignable(variableType, checkedType)) {
        receiver = wrapUnassignableExpression(
          expression: receiver,
          expressionType: checkedType,
          contextType: variableType,
          message: diag.anonymousMethodWrongParameterTypeCfe.withArguments(
            receiverType: checkedType,
            parameterType: variableType,
          ),
          fileOffset: node.typeOffset,
          internalNode: node.receiver,
        );
      }
    }

    flowAnalysis.declare(
      node.variable,
      new SharedTypeView(node.variable.type),
      initialized: false,
    );
    flowAnalysis.initialize(
      node.variable,
      new SharedTypeView(node.variable.type),
      receiverInfo,
      isFinal: false,
      isLate: false,
      isImplicitlyTyped: node.isImplicitlyTyped,
      inheritPromotableProperties: node.isParameterless,
    );
    bool isNullAwareAccess = node.isNullAware && _enclosingCascade == null;
    if (node.isNullAware) {
      SyntheticVariable? tempVar;

      if (isNullAwareAccess) {
        tempVar = extern.createVariable(
          receiver,
          receiverType,
          isFinal: false,
          fileOffset: node.fileOffset,
        );
        receiver = new VariableGet(tempVar);
      }

      receiver = new AsExpression(receiver, node.variable.type)
        ..fileOffset = node.fileOffset;

      if (isNullAwareAccess) {
        startNullShorting(
          new NullAwareGuard(tempVar!, node.variable.fileOffset),
          getExpressionInfo(tempVar.initializer!),
          new SharedTypeView(tempVar.type),
        );
      }
    }

    if (node.isParameterless) {
      flow.thisBinding_begin(receiverInfo);
    }

    flowAnalysis.labeledStatement_begin(internalLabel);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    bool isReachable = flowAnalysis.isReachable;
    flowAnalysis.labeledStatement_end();

    if (node.isParameterless) {
      flow.thisBinding_end();
    }

    _returnContexts.pop();

    Statement body = bodyResult.statement;
    label.body = body..parent = label;

    DartType inferredType = isReachable
        ? const NullType()
        : const NeverType.nonNullable();
    for (DartType returnType in context.returnTypes) {
      inferredType = typeSchemaEnvironment.getStandardUpperBound(
        inferredType,
        returnType,
      );
    }
    resultVar.type = inferredType;

    if (node.isCascade) {
      inferredType = receiverType;
    }

    Block block = new Block([
      extern.createVariableStatement(
        extern.createVariableDeclaration(
          node.variable.astVariable,
          initializer: receiver,
        ),
      ),
      extern.createVariableStatement(
        extern.createVariableDeclaration(resultVar),
      ),
      label,
    ])..fileOffset = node.fileOffset;

    Expression replacement = new BlockExpression(
      block,
      node.isCascade
          ? extern.createVariableGet(node.variable.astVariable)
          : new VariableGet(resultVar),
    )..fileOffset = node.fileOffset;

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitPropertySet(
    PropertySet node,
    DartType typeContext,
  ) {
    PropertySetData data = computePropertySetData(
      receiver: node.receiver,
      name: node.name,
      isNullAware: node.isNullAware,
      fileOffset: node.fileOffset,
    );
    DartType writeContext = data.writeContext;
    Expression receiver = data.receiver;
    DartType receiverType = data.receiverType;
    ObjectAccessTarget target = data.target;

    ExpressionInferenceResult rhsResult = inferExpression(
      node.value,
      writeContext,
      isVoidAllowed: true,
    );

    ExpressionInferenceResult replacementResult = inferPropertySet(
      fileOffset: node.fileOffset,
      receiver: receiver,
      receiverType: receiverType,
      propertyName: node.name,
      writeTarget: target,
      writeContext: writeContext,
      valueResult: rhsResult,
      forEffect: node.forEffect,
      isImplicitThis: node.isImplicitThis,
      valueNode: node.value,
    );
    Expression replacement = replacementResult.expression;
    DartType replacementType = replacementResult.inferredType;

    return new ExpressionInferenceResult(replacementType, replacement);
  }

  @override
  PropertySetData computePropertySetData({
    required InternalExpression receiver,
    required Name name,
    required bool isNullAware,
    required int fileOffset,
  }) {
    ExpressionInferenceResult receiverResult = inferExpression(
      receiver,
      const UnknownType(),
      isVoidAllowed: false,
      continueNullShorting: true,
    );

    Expression inferredReceiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      inferredReceiver = _createNonNullReceiver(
        inferredReceiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    ObjectAccessTarget target = findInterfaceMember(
      receiverType,
      name,
      fileOffset,
      isSetter: true,
      instrumented: true,
      includeExtensionMethods: true,
    );
    DartType writeContext = target.getSetterType(this);
    return new PropertySetData(
      receiver: inferredReceiver,
      receiverType: receiverType,
      writeContext: writeContext,
      target: target,
    );
  }

  ExpressionInferenceResult visitPropertyGet(
    PropertyGet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult receiverResult = inferExpression(
      node.receiver,
      const UnknownType(),
      continueNullShorting: true,
    );

    Expression receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (node.isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    PropertyGetInferenceResult propertyGetInferenceResult = _computePropertyGet(
      fileOffset: node.fileOffset,
      receiver: receiver,
      receiverType: receiverType,
      propertyName: node.name,
      typeContext: typeContext,
      isThisReceiver: _isInternalThisExpression(node.receiver),
      isImplicitThis: node.isImplicitThis,
      accessNode: node,
    );
    return propertyGetInferenceResult.expressionInferenceResult;
  }

  InitializerInferenceResult visitInternalRedirectingInitializer(
    InternalRedirectingInitializer node,
  ) {
    ensureMemberType(node.target);
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    ActualArguments arguments = node.arguments;
    // The redirecting initializer syntax doesn't include type arguments passed
    // to the target constructor so we synthesize them for calling
    // [inferInvocation].
    TypeArguments typeArguments = new TypeArguments(
      new List<DartType>.generate(
        classTypeParameters.length,
        (int i) => new TypeParameterType.withDefaultNullability(
          classTypeParameters[i],
        ),
        growable: false,
      ),
    );
    FunctionType functionType = replaceReturnType(
      node.target.function.computeThisFunctionType(Nullability.nonNullable),
      coreTypes.thisInterfaceType(
        node.target.enclosingClass,
        Nullability.nonNullable,
      ),
    );
    InvocationInferenceResult inferenceResult = inferInvocation(
      this,
      const UnknownType(),
      node.fileOffset,
      new InvocationTargetFunctionType(functionType),
      typeArguments,
      arguments,
      skipTypeArgumentInference: true,
      staticTarget: node.target,
    );
    LocatedMessage? message = problemReporting.checkArgumentsForFunction(
      function: node.target.function,
      explicitTypeArguments: null,
      arguments: node.arguments,
      fileOffset: node.arguments.fileOffset,
      fileUri: fileUri,
      typeParameters: <TypeParameter>[],
    );
    Initializer? result;
    if (message != null) {
      result = extern.createInvalidInitializerFromErrorText(
        problemReporting.buildProblemFromLocatedMessage(
          compilerContext: compilerContext,
          message: message,
        ),
        isRedirectingInitializer: true,
      );
    }
    return new InitializerInferenceResult.fromInvocationInferenceResult(
      result ??
          (new RedirectingInitializer(
            node.target,
            createArgumentsFromInternalNode(
              [],
              inferenceResult.positional,
              inferenceResult.named,
              arguments,
            ),
          )..fileOffset = node.fileOffset),
      inferenceResult,
    );
  }

  InitializerInferenceResult visitExtensionTypeRedirectingInitializer(
    ExtensionTypeRedirectingInitializer node,
  ) {
    ensureMemberType(node.target);
    List<TypeParameter> constructorTypeParameters =
        _constructorContext!.signature.typeParameters;
    // The redirecting initializer syntax doesn't include type arguments passed
    // to the target constructor so we synthesize them for calling
    // [inferInvocation].
    TypeArguments typeArguments = new TypeArguments(
      new List<DartType>.generate(
        constructorTypeParameters.length,
        (int i) => new TypeParameterType.withDefaultNullability(
          constructorTypeParameters[i],
        ),
        growable: false,
      ),
    );

    FunctionType functionType = node.target.function.computeThisFunctionType(
      Nullability.nonNullable,
    );
    InvocationInferenceResult inferenceResult = inferInvocation(
      this,
      const UnknownType(),
      node.fileOffset,
      new InvocationTargetFunctionType(functionType),
      typeArguments,
      node.arguments,
      skipTypeArgumentInference: true,
      staticTarget: node.target,
    );
    Arguments arguments = createArgumentsFromInternalNode(
      inferenceResult.typeArguments,
      inferenceResult.positional,
      inferenceResult.named,
      node.arguments,
    );

    LocatedMessage? message = problemReporting.checkArgumentsForFunction(
      function: node.target.function,
      explicitTypeArguments: null,
      arguments: node.arguments,
      fileOffset: node.arguments.fileOffset,
      fileUri: fileUri,
      typeParameters: node.target.function.typeParameters,
    );
    Initializer? result;
    if (message != null) {
      result = extern.createInvalidInitializerFromErrorText(
        problemReporting.buildProblemFromLocatedMessage(
          compilerContext: compilerContext,
          message: message,
        ),
        isRedirectingInitializer: true,
      );
    }
    return new InitializerInferenceResult.fromInvocationInferenceResult(
      result ??
          new ExternalExtensionTypeRedirectingInitializer(
            node.target,
            arguments,
            fileOffset: node.fileOffset,
          ),
      inferenceResult,
    );
  }

  InitializerInferenceResult visitExtensionTypeRepresentationFieldInitializer(
    ExtensionTypeRepresentationFieldInitializer node,
  ) {
    DartType fieldType = node.field.getterType;
    fieldType = _constructorContext!.substituteFieldType(fieldType);
    ExpressionInferenceResult initializerResult = inferExpression(
      node.value,
      fieldType,
      isVoidAllowed: true,
    );
    Expression initializer = ensureAssignableResult(
      fieldType,
      initializerResult,
      fileOffset: node.fileOffset,
      isVoidAllowed: true,
      assignedNode: node.value,
    ).expression;
    Initializer replacement =
        new ExternalExtensionTypeRepresentationFieldInitializer(
          node.field,
          initializer,
          fileOffset: node.fileOffset,
        );
    return new SuccessfulInitializerInferenceResult(replacement);
  }

  ExpressionInferenceResult visitInternalRethrow(
    InternalRethrow node,
    DartType typeContext,
  ) {
    flowAnalysis.handleExit();
    Expression replacement = extern.createRethrow(fileOffset: node.fileOffset);
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(
      const NeverType.nonNullable(),
      replacement,
    );
  }

  StatementInferenceResult visitInternalReturnStatement(
    InternalReturnStatement node,
  ) {
    ReturnContext? context = returnContext;
    if (context is AnonymousMethodReturnContext) {
      Expression expression;
      if (node.expression != null) {
        ExpressionInferenceResult expressionResult = inferExpression(
          node.expression!,
          context.typeContext,
          isVoidAllowed: true,
        );
        context.returnTypes.add(expressionResult.inferredType);
        expression = expressionResult.expression;
      } else {
        expression = extern.createNullLiteral(fileOffset: node.fileOffset);
        context.returnTypes.add(const NullType());
      }

      VariableSet assignment = new VariableSet(
        context.resultVariable,
        expression,
      )..fileOffset = node.fileOffset;
      BreakStatement breakStmt = new BreakStatement(context.label)
        ..fileOffset = node.fileOffset;

      flowAnalysis.handleBreak(context.internalLabel);

      Statement replacement = new Block([
        new ExpressionStatement(assignment)..fileOffset = node.fileOffset,
        breakStmt,
      ])..fileOffset = node.fileOffset;

      return new StatementInferenceResult.single(replacement);
    }

    DartType typeContext = bodyContext.returnContext;
    DartType inferredType;
    Variable? thisVariable = _constructorContext?.thisVariable;

    Expression? expression;
    if (bodyContext.isRoot && thisVariable != null) {
      // The constructor is lowered with an explicit variable for `this`. This
      // means that `return;` should be encoded as `return #this;` where `#this`
      // is the [thisVariable].
      expression = extern.createVariableGet(
        thisVariable,
        fileOffset: node.fileOffset,
      );
      inferredType = thisVariable.type;
    } else if (node.expression != null) {
      ExpressionInferenceResult expressionResult = inferExpression(
        node.expression!,
        typeContext,
        isVoidAllowed: true,
      );
      expression = expressionResult.expression;
      inferredType = expressionResult.inferredType;
    } else {
      inferredType = const NullType();
    }
    ReturnStatement replacement = extern.createReturnStatement(
      expression,
      fileOffset: node.fileOffset,
    );
    bodyContext.handleReturn(
      replacement,
      inferredType,
      node.isArrow,
      expressionNode: node.expression ?? node,
    );
    flowAnalysis.handleReturn();
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitInternalStaticSet(
    InternalStaticSet node,
    DartType typeContext,
  ) {
    DartType writeContext = computeStaticSetWriteContext(node.target);
    ExpressionInferenceResult rhsResult = inferExpression(
      node.value,
      writeContext,
      isVoidAllowed: true,
    );
    ExpressionInferenceResult result = inferStaticSet(
      member: node.target,
      rhsResult: rhsResult,
      writeContext: writeContext,
      assignOffset: node.fileOffset,
      nameOffset: node.fileOffset,
      valueNode: node.value,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result.expression);
    return result;
  }

  ExpressionInferenceResult visitInternalStaticGet(
    InternalStaticGet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult result = inferStaticGet(
      member: node.target,
      typeContext: typeContext,
      nameOffset: node.fileOffset,
      accessNode: node,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result.expression);
    return result;
  }

  ExpressionInferenceResult visitInternalStaticInvocation(
    InternalStaticInvocation node,
    DartType typeContext,
  ) {
    FunctionType calleeType = node.target.function.computeFunctionType(
      Nullability.nonNullable,
    );
    ActualArguments arguments = node.arguments;
    bool isIdenticalCall =
        node.target == typeSchemaEnvironment.coreTypes.identicalProcedure &&
        arguments.positionalCount == 2;
    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      new InvocationTargetFunctionType(calleeType),
      node.typeArguments,
      arguments,
      staticTarget: node.target,
      isIdenticalCall: isIdenticalCall,
    );
    String targetName = node.name.text;
    if (node.target.enclosingClass != null) {
      targetName = '${node.target.enclosingClass!.name}.$targetName';
    }
    problemReporting.checkBoundsInStaticInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      targetName: targetName,
      typeEnvironment: typeSchemaEnvironment,
      fileUri: fileUri,
      fileOffset: node.fileOffset,
      hasInferredTypeArguments: node.typeArguments == null,
      typeParameters: node.target.typeParameters,
      explicitOrInferredTypeArguments: result.typeArguments,
    );
    Expression replacement = extern.createStaticInvocation(
      node.target,
      createArgumentsFromInternalNode(
        result.typeArguments,
        result.positional,
        result.named,
        arguments,
      ),
      fileOffset: node.fileOffset,
    );
    storeExpressionInfo(replacement, result.expressionInfo);
    return new ExpressionInferenceResult(
      result.inferredType,
      result.applyResult(replacement),
    );
  }

  ExpressionInferenceResult visitInternalStringConcatenation(
    InternalStringConcatenation node,
    DartType typeContext,
  ) {
    List<Expression> expressions = new List.filled(
      node.expressions.length,
      dummyExpression,
    );
    for (int index = 0; index < node.expressions.length; index++) {
      ExpressionInferenceResult result = inferExpression(
        node.expressions[index],
        const UnknownType(),
        isVoidAllowed: false,
      );
      expressions[index] = result.expression;
    }
    Expression replacement = extern.createStringConcatenation(
      expressions,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(
      coreTypes.stringRawType(Nullability.nonNullable),
      replacement,
    );
  }

  ExpressionInferenceResult visitInternalStringLiteral(
    InternalStringLiteral node,
    DartType typeContext,
  ) {
    Expression replacement = extern.createStringLiteral(
      node.value,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(
      coreTypes.stringRawType(Nullability.nonNullable),
      replacement,
    );
  }

  InitializerInferenceResult visitInternalSuperInitializer(
    InternalSuperInitializer node,
  ) {
    ensureMemberType(node.target);

    Supertype asSuperClass = hierarchyBuilder.getClassAsInstanceOf(
      thisType!.classNode,
      node.target.enclosingClass,
    )!;

    FunctionType targetType = node.target.function.computeThisFunctionType(
      Nullability.nonNullable,
    );

    FunctionType instantiatedTargetType = FunctionTypeInstantiator.instantiate(
      targetType,
      asSuperClass.typeArguments,
    );

    FunctionType functionType = replaceReturnType(
      instantiatedTargetType,
      thisType!,
    );

    InvocationInferenceResult inferenceResult = inferInvocation(
      this,
      const UnknownType(),
      node.fileOffset,
      new InvocationTargetFunctionType(functionType),
      null,
      node.arguments,
      skipTypeArgumentInference: true,
      staticTarget: node.target,
    );
    LocatedMessage? message = problemReporting.checkArgumentsForFunction(
      function: node.target.function,
      explicitTypeArguments: null,
      arguments: node.arguments,
      fileOffset: node.arguments.fileOffset,
      fileUri: fileUri,
      typeParameters: <TypeParameter>[],
    );
    Initializer? result;
    if (message != null) {
      result = extern.createInvalidInitializerFromErrorText(
        problemReporting.buildProblemFromLocatedMessage(
          compilerContext: compilerContext,
          message: message,
        ),
        isSuperInitializer: true,
      );
    }
    return new InitializerInferenceResult.fromInvocationInferenceResult(
      result ??
          (new SuperInitializer(
              node.target,
              createArgumentsFromInternalNode(
                [],
                inferenceResult.positional,
                inferenceResult.named,
                node.arguments,
              ),
            )
            ..fileOffset = node.fileOffset
            ..isSynthetic = node.isSynthetic),
      inferenceResult,
    );
  }

  ExpressionInferenceResult visitInternalSuperMethodInvocation(
    InternalSuperMethodInvocation node,
    DartType typeContext,
  ) {
    return inferSuperMethodInvocation(
      this,
      name: node.name,
      typeArguments: node.typeArguments,
      arguments: node.arguments,
      typeContext: typeContext,
      procedure: node.target,
      fileOffset: node.fileOffset,
    );
  }

  ExpressionInferenceResult visitInternalSuperPropertyGet(
    InternalSuperPropertyGet node,
    DartType typeContext,
  ) {
    return inferSuperPropertyGet(
      receiver: _createThisExpression(node.receiver),
      name: node.name,
      typeContext: typeContext,
      member: node.interfaceTarget,
      nameOffset: node.fileOffset,
      accessNode: node,
    );
  }

  ExpressionInferenceResult visitInternalSuperPropertySet(
    InternalSuperPropertySet node,
    DartType typeContext,
  ) {
    DartType writeContext = computeSuperPropertySetWriteContext(
      node.interfaceTarget,
    );
    ExpressionInferenceResult rhsResult = inferExpression(
      node.value,
      writeContext,
      isVoidAllowed: true,
    );

    Expression receiver;
    if (isClosureContextLoweringEnabled) {
      receiver = extern.createVariableGet(
        internalThisVariable,
        fileOffset: node.receiver.fileOffset,
      );
    } else {
      receiver = extern.createThisExpression(
        fileOffset: node.receiver.fileOffset,
      );
    }
    return inferSuperPropertySet(
      receiver: receiver,
      name: node.name,
      member: node.interfaceTarget,
      rhsResult: rhsResult,
      writeContext: writeContext,
      assignOffset: node.fileOffset,
      nameOffset: node.fileOffset,
      valueNode: node.value,
    );
  }

  ExpressionInferenceResult visitInternalSwitchExpression(
    InternalSwitchExpression node,
    DartType typeContext,
  ) {
    Set<Field?>? previousEnumFields = _enumFields;

    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    SwitchExpressionResult<InvalidExpression> analysisResult =
        analyzeSwitchExpression(
          node,
          node.expression,
          node.cases.length,
          new SharedTypeSchemaView(typeContext),
        );
    DartType valueType = analysisResult.type.unwrapTypeView();
    DartType staticType = valueType;

    assert(
      checkStack(node, stackBase, [
        /* cases */ ...repeatedKind(
          ValueKinds.SwitchExpressionCase,
          node.cases.length,
        ),
        /* scrutineeType = */ ValueKinds.DartType,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    List<SwitchExpressionCase> cases = new List.filled(
      node.cases.length,
      dummySwitchExpressionCase,
      growable: true,
    );
    for (int i = node.cases.length - 1; i >= 0; i--) {
      cases[i] = popRewrite() as SwitchExpressionCase;
    }

    assert(
      checkStack(node, stackBase, [
        /* scrutineeType = */ ValueKinds.DartType,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    DartType scrutineeType = popRewrite() as DartType;
    DartType expressionType = scrutineeType;

    assert(
      checkStack(node, stackBase, [/* scrutinee = */ ValueKinds.Expression]),
    );

    Expression expression = popRewrite() as Expression;

    for (int caseIndex = 0; caseIndex < node.cases.length; caseIndex++) {
      SwitchExpressionCase switchCase = cases[caseIndex];
      PatternGuard patternGuard = switchCase.patternGuard;

      InvalidExpression? guardError =
          analysisResult.nonBooleanGuardErrors?[caseIndex];
      if (guardError != null) {
        patternGuard.guard = guardError;
      } else if (patternGuard.guard != null) {
        if (analysisResult.guardTypes![caseIndex] is DynamicType) {
          patternGuard.guard = _createImplicitAs(
            patternGuard.guard!.fileOffset,
            patternGuard.guard!,
            coreTypes.boolNonNullableRawType,
          )..parent = patternGuard;
        }
      }
    }

    _enumFields = previousEnumFields;

    assert(checkStack(node, stackBase, [/*empty*/]));

    Expression result = extern.createSwitchExpression(
      expression: expression,
      cases: cases,
      expressionType: expressionType,
      staticType: staticType,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result);
    return new ExpressionInferenceResult(valueType, result);
  }

  StatementInferenceResult visitInternalRegularSwitchStatement(
    InternalRegularSwitchStatement node,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    Set<Field?>? previousEnumFields = _enumFields;
    SwitchStatementTypeAnalysisResult<InvalidExpression> analysisResult =
        analyzeSwitchStatement(node, node.expression, node.cases.length);

    DartType expressionType = analysisResult.scrutineeType.unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* cases = */ ...repeatedKind(ValueKinds.SwitchCase, node.cases.length),
        /* scrutinee type = */ ValueKinds.DartType,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    List<SwitchCase> cases = new List.filled(
      node.cases.length,
      dummySwitchCase,
      growable: true,
    );
    for (int i = node.cases.length - 1; i >= 0; i--) {
      cases[i] = popRewrite() as SwitchCase;
    }

    // Note that a switch statement with a `default` clause is always considered
    // exhaustive, but the kernel format also keeps track of whether the switch
    // statement is "explicitly exhaustive", meaning that it has a `case` clause
    // for every possible enum value.  It is only necessary to set this flag if
    // the switch doesn't have a `default` clause.
    bool isExplicitlyExhaustive = false;
    if (!analysisResult.hasDefault) {
      isExplicitlyExhaustive = analysisResult.isExhaustive;
    }
    _enumFields = previousEnumFields;

    assert(
      checkStack(node, stackBase, [
        /* scrutineeType = */ ValueKinds.DartType,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    popRewrite(); // Scrutinee type.

    assert(
      checkStack(node, stackBase, [/* scrutinee = */ ValueKinds.Expression]),
    );

    Expression expression = popRewrite() as Expression;

    Statement replacement = extern.createSwitchStatement(
      expression: expression,
      cases: cases,
      isExplicitlyExhaustive: isExplicitlyExhaustive,
      expressionType: expressionType,
      fileOffset: node.fileOffset,
    );

    assert(checkStack(node, stackBase, [/*empty*/]));

    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);

    replacement = _handleBreaks(node, replacement);

    return new StatementInferenceResult.single(replacement);
  }

  StatementInferenceResult visitInternalPatternSwitchStatement(
    InternalPatternSwitchStatement node,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    SwitchStatementTypeAnalysisResult<InvalidExpression> analysisResult =
        analyzeSwitchStatement(node, node.expression, node.cases.length);

    bool lastCaseTerminates = analysisResult.lastCaseTerminates;

    assert(
      checkStack(node, stackBase, [
        /* cases = */ ...repeatedKind(ValueKinds.SwitchCase, node.cases.length),
        /* scrutinee type = */ ValueKinds.DartType,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    DartType expressionType = analysisResult.scrutineeType.unwrapTypeView();
    List<PatternSwitchCase> cases = new List.filled(
      node.cases.length,
      dummyPatternSwitchCase,
      growable: true,
    );
    for (int i = node.cases.length - 1; i >= 0; i--) {
      cases[i] = popRewrite() as PatternSwitchCase;
    }

    assert(
      checkStack(node, stackBase, [
        /* scrutinee type = */ ValueKinds.DartType,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    popRewrite(); // Scrutinee type.

    assert(
      checkStack(node, stackBase, [/* scrutinee = */ ValueKinds.Expression]),
    );

    Expression expression = popRewrite() as Expression;

    for (int caseIndex = 0; caseIndex < cases.length; caseIndex++) {
      PatternSwitchCase switchCase = cases[caseIndex];
      List<Variable> jointVariablesNotInAll = [];
      for (
        int headIndex = 0;
        headIndex < switchCase.patternGuards.length;
        headIndex++
      ) {
        PatternGuard patternGuard = switchCase.patternGuards[headIndex];
        Pattern pattern = patternGuard.pattern;

        InvalidExpression? guardError =
            analysisResult.nonBooleanGuardErrors?[caseIndex]?[headIndex];
        if (guardError != null) {
          patternGuard.guard = guardError..parent = patternGuard;
        } else if (patternGuard.guard != null) {
          if (analysisResult.guardTypes![caseIndex]![headIndex]
              is DynamicType) {
            patternGuard.guard = _createImplicitAs(
              patternGuard.guard!.fileOffset,
              patternGuard.guard!,
              coreTypes.boolNonNullableRawType,
            )..parent = patternGuard;
          }
        }

        Map<String, DartType> inferredVariableTypes = {
          for (Variable variable in pattern.declaredVariables)
            variable.cosmeticName!: variable.type,
        };
        if (headIndex == 0) {
          for (Variable jointVariable in switchCase.jointVariables) {
            DartType? inferredType =
                inferredVariableTypes[jointVariable.cosmeticName!];
            if (inferredType != null) {
              jointVariable.type = inferredType;
            } else {
              jointVariable.type = const InvalidType();
              jointVariablesNotInAll.add(jointVariable);
            }
          }
        } else {
          for (int i = 0; i < switchCase.jointVariables.length; ++i) {
            Variable jointVariable = switchCase.jointVariables[i];
            // The error on joint variables not present in all case heads is
            // reported in BodyBuilder.
            DartType? inferredType =
                inferredVariableTypes[jointVariable.cosmeticName!];
            if (!jointVariablesNotInAll.contains(jointVariable) &&
                inferredType != null &&
                jointVariable.type != inferredType) {
              jointVariable.initializer =
                  extern.createInvalidExpressionFromErrorText(
                    problemReporting.buildProblem(
                      compilerContext: compilerContext,
                      message: diag.jointPatternVariablesMismatch.withArguments(
                        variableName: jointVariable.cosmeticName!,
                      ),
                      fileUri: fileUri,
                      fileOffset:
                          switchCase.jointVariableFirstUseOffsets?[i] ??
                          // Coverage-ignore(suite): Not run.
                          jointVariable.fileOffset,
                      length: noLength,
                    ),
                  )..parent = jointVariable;
            }
          }
        }
      }
    }

    Statement replacement = extern.createPatternSwitchStatement(
      expression: expression,
      cases: cases,
      expressionType: expressionType,
      lastCaseTerminates: lastCaseTerminates,
      fileOffset: node.fileOffset,
    );

    replacement = _handleBreaks(node, replacement);

    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitInternalSymbolLiteral(
    InternalSymbolLiteral node,
    DartType typeContext,
  ) {
    DartType inferredType = coreTypes.symbolRawType(Nullability.nonNullable);
    Expression replacement = extern.createSymbolLiteral(
      value: node.value,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitInternalThisExpression(
    InternalThisExpression node,
    DartType typeContext,
  ) {
    DartType? promotedTypeOfThis =
        flowAnalysis.promotedTypeOfThis
                // Coverage-ignore(suite): Not run.
                ?.unwrapTypeView()
            as DartType?;
    DartType thisType = promotedTypeOfThis ?? this.thisType!;
    Expression loweredExpression;
    if (isClosureContextLoweringEnabled) {
      loweredExpression =
          new VariableGet(_contextAllocationStrategy.thisVariable)
            ..fileOffset = node.fileOffset
            ..promotedType = promotedTypeOfThis;
    } else if (promotedTypeOfThis != null) {
      // Coverage-ignore-block(suite): Not run.
      loweredExpression =
          new AsExpression(
              extern.createThisExpression(fileOffset: node.fileOffset),
              promotedTypeOfThis,
            )
            ..fileOffset = node.fileOffset
            ..isUnchecked = true;
    } else {
      loweredExpression = extern.createThisExpression(
        fileOffset: node.fileOffset,
      );
    }
    storeExpressionInfo(
      loweredExpression,
      flowAnalysis.thisOrSuper(new SharedTypeView(thisType), isSuper: false),
    );
    return new ExpressionInferenceResult(thisType, loweredExpression);
  }

  ExpressionInferenceResult visitInternalThrow(
    InternalThrow node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult expressionResult = inferExpression(
      node.expression,
      coreTypes.objectNonNullableRawType,
      isVoidAllowed: false,
    );
    Expression expression = expressionResult.expression;
    flowAnalysis.handleExit();
    if (!isAssignable(
      typeSchemaEnvironment.objectNonNullableRawType,
      expressionResult.inferredType,
    )) {
      return new ExpressionInferenceResult(
        const DynamicType(),
        extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.throwingNotAssignableToObjectError.withArguments(
              thrownType: expressionResult.inferredType,
            ),
            fileUri: fileUri,
            fileOffset: expression.fileOffset,
            length: noLength,
          ),
        ),
      );
    }
    if (expressionResult.inferredType.isPotentiallyNullable) {
      expression =
          new AsExpression(expression, coreTypes.objectNonNullableRawType)
            ..isTypeError = true
            ..fileOffset = expression.fileOffset;
    }
    // Return BottomType in legacy mode for compatibility.
    Expression replacement = extern.createThrow(
      expression,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(
      const NeverType.nonNullable(),
      replacement,
    );
  }

  Catch visitCatch(InternalCatch node) {
    ScopeProviderInfo? scopeProviderInfo;
    InternalCatchVariable? exception = node.exception;
    InternalCatchVariable? stackTrace = node.stackTrace;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Catch,
      );
      if (exception != null) {
        // TODO(62401): Remove the casts when the flow analysis uses
        // [InternalExpressionVariable]s.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          exception.astVariable,
          captureKind: captureKindForVariable(exception),
        );
      }
      if (stackTrace != null) {
        // TODO(62401): Remove the casts when the flow analysis uses
        // [InternalExpressionVariable]s.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          stackTrace.astVariable,
          captureKind: captureKindForVariable(stackTrace),
        );
      }
    }
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      scope = scopeProviderInfo.scope;
    }
    return extern.createCatch(
      guard: node.guard,
      exception: exception?.astVariable,
      stackTrace: stackTrace?.astVariable,
      body: body,
      scope: scope,
      fileOffset: node.fileOffset,
    );
  }

  StatementInferenceResult visitTryStatement(TryStatement node) {
    bool oldInTryOrLocalFunction = _inTryOrLocalFunction;
    _inTryOrLocalFunction = true;
    if (node.finallyBlock != null) {
      flowAnalysis.tryFinallyStatement_bodyBegin();
    }
    InternalStatement tryBodyWithAssignedInfo = node.tryBlock;
    if (node.catchBlocks.isNotEmpty) {
      flowAnalysis.tryCatchStatement_bodyBegin();
    }

    StatementInferenceResult tryBlockResult = inferStatement(node.tryBlock);

    List<Catch>? catchBlocks;
    if (node.catchBlocks.isNotEmpty) {
      catchBlocks = [];
      flowAnalysis.tryCatchStatement_bodyEnd(tryBodyWithAssignedInfo);
      for (InternalCatch catchBlock in node.catchBlocks) {
        // TODO(62401): Remove the casts when the flow analysis uses
        // [InternalExpressionVariable]s.
        flowAnalysis.tryCatchStatement_catchBegin(
          catchBlock.exception,
          catchBlock.stackTrace,
        );
        catchBlocks.add(visitCatch(catchBlock));
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
        node.catchBlocks.isNotEmpty ? node : tryBodyWithAssignedInfo,
      );
      finalizerResult = inferStatement(node.finallyBlock!);
      flowAnalysis.tryFinallyStatement_end();
    }
    Statement result = tryBlockResult.statement;
    if (catchBlocks != null) {
      result = new TryCatch(result, catchBlocks)..fileOffset = node.fileOffset;
    }
    if (node.finallyBlock != null) {
      result = new TryFinally(result, finalizerResult!.statement)
        ..fileOffset = node.fileOffset;
    }
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result);
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    return new StatementInferenceResult.single(result);
  }

  ExpressionInferenceResult visitInternalTypeLiteral(
    InternalTypeLiteral node,
    DartType typeContext,
  ) {
    DartType inferredType = coreTypes.typeRawType(Nullability.nonNullable);
    Expression replacement = extern.createTypeLiteral(
      node.type,
      fileOffset: node.fileOffset,
    );
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitInternalVariableSet(
    InternalVariableSet node,
    DartType typeContext,
  ) {
    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      ExpressionInferenceResult? result = expressionEvaluationHelper
          ?.visitInternalVariableSet(
            node,
            typeContext,
            problemReporting,
            compilerContext,
            fileUri,
          );
      if (result != null) {
        return result;
      }
    }
    InternalVariable variable = node.variable;
    var (DartType variableType, DartType writeContext) =
        computeVariableSetTypeAndWriteContext(variable);
    ExpressionInferenceResult rhsResult = inferExpression(
      node.value,
      writeContext,
      isVoidAllowed: true,
    );
    ExpressionInferenceResult result = inferVariableSet(
      node: node,
      variable: variable,
      variableType: variableType,
      rhsResult: rhsResult,
      assignOffset: node.fileOffset,
      nameOffset: node.fileOffset,
      valueNode: node.value,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result.expression);
    return result;
  }

  VariableDeclarationInferenceResult inferVariableDeclaration(
    InternalVariableDeclaration node, {
    required bool forLoopVariable,
  }) {
    VariableDeclarationInferenceResult variableDeclarationInferenceResult =
        _inferInternalVariableDeclaration(
          node,
          forLoopVariable: forLoopVariable,
        );
    if (isClosureContextLoweringEnabled) {
      _contextAllocationStrategy.handleDeclarationOfVariable(
        node.variable.astVariable,
        captureKind: captureKindForVariable(node.variable),
      );
    }
    return variableDeclarationInferenceResult;
  }

  StatementInferenceResult visitInternalVariableStatement(
    InternalVariableStatement node,
  ) {
    return inferVariableDeclaration(
      node.declaration,
      forLoopVariable: false,
    ).toStatementInferenceResult(fileOffset: node.fileOffset);
  }

  StatementInferenceResult visitInternalPatternVariableDeclaration(
    InternalPatternVariableDeclaration node,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternVariableDeclarationAnalysisResult analysisResult =
        analyzePatternVariableDeclaration(
          node,
          node.pattern,
          node.initializer,
          isFinal: node.isFinal,
        );
    DartType matchedValueType = analysisResult.initializerType.unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]),
    );

    Pattern pattern = popRewrite() as Pattern;

    assert(
      checkStack(node, stackBase, [/* initializer = */ ValueKinds.Expression]),
    );

    Expression initializer = popRewrite() as Expression;

    return new StatementInferenceResult.single(
      extern.createPatternVariableDeclaration(
        pattern: pattern,
        initializer: initializer,
        isFinal: node.isFinal,
        matchedValueType: matchedValueType,
        fileOffset: node.fileOffset,
      ),
    );
  }

  ExpressionInferenceResult visitInternalVariableGet(
    InternalVariableGet node,
    DartType typeContext,
  ) {
    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      ExpressionInferenceResult? result = expressionEvaluationHelper
          ?.visitInternalVariableGet(
            node,
            typeContext,
            problemReporting,
            compilerContext,
            fileUri,
          );
      if (result != null) {
        return result;
      }
    }
    ExpressionInferenceResult result = inferVariableGet(
      variable: node.variable,
      typeContext: typeContext,
      nameOffset: node.fileOffset,
      accessNode: node,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, result.expression);
    return result;
  }

  StatementInferenceResult visitInternalWhileStatement(
    InternalWhileStatement node,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
    }
    flowAnalysis.whileStatement_conditionBegin(node);
    InterfaceType expectedType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      expectedType,
      isVoidAllowed: false,
    );
    Expression condition = ensureAssignableResult(
      expectedType,
      conditionResult,
      assignedNode: node.condition,
    ).expression;
    flowAnalysis.whileStatement_bodyBegin(node, getExpressionInfo(condition));
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;

    body = _handleContinues(node, body);

    flowAnalysis.whileStatement_end();
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      scope = scopeProviderInfo.scope;
    }
    Statement replacement = extern.createWhileStatement(
      condition,
      body,
      scope: scope,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);

    replacement = _handleBreaks(node, replacement);

    return new StatementInferenceResult.single(replacement);
  }

  StatementInferenceResult visitInternalYieldStatement(
    InternalYieldStatement node,
  ) {
    YieldStatementResult analysisResult = analyzeYieldStatement(
      node,
      node.expression,
      isYieldStar: node.isYieldStar,
    );
    ExpressionInferenceResult expressionResult = new ExpressionInferenceResult(
      analysisResult.operandType.unwrapTypeView(),
      popRewrite() as Expression,
    );
    YieldStatement replacement = extern.createYieldStatement(
      expressionResult.expression,
      isYieldStar: node.isYieldStar,
      fileOffset: node.fileOffset,
    );
    bodyContext.handleYield(
      replacement,
      expressionResult,
      expressionNode: node.expression,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  ExpressionInferenceResult visitInternalLoadLibrary(
    InternalLoadLibrary node,
    DartType typeContext,
  ) {
    DartType inferredType = typeSchemaEnvironment.futureType(
      const DynamicType(),
      Nullability.nonNullable,
    );
    if (node.arguments != null) {
      FunctionType calleeType = new FunctionType(
        [],
        inferredType,
        Nullability.nonNullable,
      );
      inferInvocation(
        this,
        typeContext,
        node.fileOffset,
        new InvocationTargetFunctionType(calleeType),
        null,
        node.arguments!,
      );
    }
    Expression replacement = extern.createLoadLibrary(
      node.import,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(node, replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitLoadLibraryTearOff(
    LoadLibraryTearOff node,
    DartType typeContext,
  ) {
    DartType inferredType = new FunctionType(
      [],
      typeSchemaEnvironment.futureType(
        const DynamicType(),
        Nullability.nonNullable,
      ),
      Nullability.nonNullable,
    );
    Expression replacement = new StaticTearOff(node.target)
      ..fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitEquals(
    EqualsExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult leftResult = inferExpression(
      node.left,
      const UnknownType(),
    );
    return _computeEqualsExpression(
      node.fileOffset,
      leftResult.expression,
      leftResult.inferredType,
      node.right,
      isNot: node.isNot,
    );
  }

  ExpressionInferenceResult visitBinary(
    BinaryExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult leftResult = inferExpression(
      node.left,
      const UnknownType(),
    );
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(getExpressionInfo(leftResult.expression));
    return _computeBinaryExpression(
      fileOffset: node.fileOffset,
      contextType: typeContext,
      left: leftResult.expression,
      leftType: leftResult.inferredType,
      binaryName: node.binaryName,
      right: node.right,
      whyNotPromoted: whyNotPromoted,
      invocationNode: node,
    );
  }

  ExpressionInferenceResult visitUnary(
    UnaryExpression node,
    DartType typeContext,
  ) {
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
      if (node.expression case InternalIntLiteral receiver) {
        if (isDoubleContext(typeContext)) {
          double? doubleValue = receiver.asDouble(negated: true);
          if (doubleValue != null) {
            Expression replacement = new DoubleLiteral(doubleValue)
              ..fileOffset = node.fileOffset;
            DartType inferredType = coreTypes.doubleRawType(
              Nullability.nonNullable,
            );
            return new ExpressionInferenceResult(inferredType, replacement);
          }
        }
        Expression? error = checkWebIntLiteralsErrorIfUnexact(
          receiver.value,
          receiver.literal,
          receiver.fileOffset,
        );
        if (error != null) {
          // Coverage-ignore-block(suite): Not run.
          return new ExpressionInferenceResult(const DynamicType(), error);
        }
      } else if (node.expression case LargeIntLiteral receiver) {
        if (!receiver.isParenthesized) {
          if (isDoubleContext(typeContext)) {
            double? doubleValue = receiver.asDouble(negated: true);
            if (doubleValue != null) {
              Expression replacement = new DoubleLiteral(doubleValue)
                ..fileOffset = node.fileOffset;
              DartType inferredType = coreTypes.doubleRawType(
                Nullability.nonNullable,
              );
              return new ExpressionInferenceResult(inferredType, replacement);
            }
          }
          int? intValue = receiver.asInt64(negated: true);
          if (intValue == null) {
            Expression error = extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.integerLiteralIsOutOfRange.withArguments(
                  literal: receiver.literal,
                ),
                fileUri: fileUri,
                fileOffset: receiver.fileOffset,
                length: receiver.literal.length,
              ),
            );
            return new ExpressionInferenceResult(const DynamicType(), error);
          }
          Expression? error = checkWebIntLiteralsErrorIfUnexact(
            intValue,
            receiver.literal,
            receiver.fileOffset,
          );
          if (error != null) {
            // Coverage-ignore-block(suite): Not run.
            return new ExpressionInferenceResult(const DynamicType(), error);
          }
          expressionResult = new ExpressionInferenceResult(
            coreTypes.intRawType(Nullability.nonNullable),
            new IntLiteral(-intValue)..fileOffset = node.expression.fileOffset,
          );
        }
      }
    }
    if (expressionResult == null) {
      expressionResult = inferExpression(node.expression, const UnknownType());
    }
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(
          getExpressionInfo(expressionResult.expression),
        );
    return _computeUnaryExpression(
      fileOffset: node.fileOffset,
      expression: expressionResult.expression,
      expressionType: expressionResult.inferredType,
      unaryName: node.unaryName,
      whyNotPromoted: whyNotPromoted,
      invocationNode: node,
    );
  }

  ExpressionInferenceResult visitParenthesized(
    ParenthesizedExpression node,
    DartType typeContext,
  ) {
    return inferExpression(node.expression, typeContext, isVoidAllowed: true);
  }

  ExpressionInferenceResult visitInternalRecordLiteral(
    InternalRecordLiteral node,
    DartType typeContext,
  ) {
    List<RecordField> fields = node.fields;
    Map<String, NamedRecordField>? namedFields = node.namedFields;
    int namedFieldCount = namedFields?.length ?? 0;
    int positionalFieldCount = fields.length - namedFieldCount;

    List<DartType>? positionalTypeContexts;
    Map<String, DartType>? namedTypeContexts;
    if (typeContext is RecordType &&
        typeContext.positional.length == positionalFieldCount &&
        typeContext.named.length == namedFieldCount) {
      namedTypeContexts = <String, DartType>{};
      for (NamedType namedType in typeContext.named) {
        namedTypeContexts[namedType.name] = namedType.type;
      }

      bool sameNames = true;
      if (namedFields != null) {
        for (String name in namedFields.keys) {
          if (!namedTypeContexts.containsKey(name)) {
            sameNames = false;
          }
        }
      }

      if (sameNames) {
        positionalTypeContexts = typeContext.positional;
      } else {
        namedTypeContexts = null;
      }
    }

    int positionalIndex = 0;
    List<Expression> positional = [];
    List<NamedExpression>? named;

    List<SyntheticVariable>? hoistedExpressions;

    Map<String, NamedRecordResult> namedResults = {};

    List<DartType> positionalTypes = [];
    List<NamedType> namedTypes = [];

    for (RecordField field in fields) {
      switch (field) {
        case PositionalRecordField():
          InternalExpression expression = field.value;
          DartType contextType =
              positionalTypeContexts?[positionalIndex] ?? const UnknownType();
          ExpressionInferenceResult expressionResult = inferExpression(
            expression,
            contextType,
          );
          if (contextType is! UnknownType) {
            expressionResult =
                coerceExpressionForAssignment(
                  contextType,
                  expressionResult,
                  internalNodeForTesting: node,
                ) ??
                expressionResult;
          }

          positionalTypes.add(
            expressionResult.postCoercionType ?? expressionResult.inferredType,
          );
          positional.add(expressionResult.expression);
          positionalIndex++;
        case NamedRecordField():
          DartType contextType =
              namedTypeContexts?[field.name] ?? const UnknownType();
          ExpressionInferenceResult expressionResult = inferExpression(
            field.value,
            contextType,
          );
          if (contextType is! UnknownType) {
            expressionResult =
                coerceExpressionForAssignment(
                  contextType,
                  expressionResult,
                  internalNodeForTesting: node,
                ) ??
                expressionResult;
          }
          Expression expression = expressionResult.expression;
          DartType type =
              expressionResult.postCoercionType ??
              expressionResult.inferredType;
          namedResults[field.name] = new NamedRecordResult(
            expression: extern.createNamedExpression(
              field.name,
              expression,
              fileOffset: field.fileOffset,
            ),
            type: type,
          );
      }
    }

    if (namedFields != null) {
      List<String> sortedNames = namedFields.keys.toList()..sort();

      // Index into [sortedNames] of the named element we expected to find
      // next, for the named elements to be sorted. This also used to detect
      // when all named elements have been seen, even when they are not sorted.
      int nameIndex = sortedNames.length - 1;

      // For const literals we don't hoist to avoid using let variables in
      // inside constants. Since the elements of the literal must be constant
      // themselves, we know that there is no side effects of performing
      // constant evaluation out of order.
      final bool enableHoisting = !node.isConst;

      // Set to `true` if we need to hoist all preceding elements.
      bool needsHoisting = false;

      // Set to `true` if named elements need to be sorted. This implies that
      // we will need to hoist preceding elements.
      bool namedNeedsSorting = false;

      // We run through the elements in reverse order to determine which
      // expressions we need to hoist. When we observe an element out of order,
      // either positional after named or unsorted named, all preceding
      // elements must be hoisted to retain the original evaluation order.
      positionalIndex--;
      for (int index = fields.length - 1; index >= 0; index--) {
        RecordField element = fields[index];
        switch (element) {
          case NamedRecordField():
            NamedRecordResult namedResult = namedResults[element.name]!;
            NamedExpression namedExpression = namedResult.expression;
            Expression expression = namedExpression.value;
            DartType type = namedResult.type;
            // TODO(johnniwinther): Should we use [isPureExpression] as is, make
            // it include (simple) literals, or add a new predicate?
            if (needsHoisting && !extern.isPureExpression(expression)) {
              // We hoist the value of the [NamedExpression] into a synthesized
              // variable, and replace the value with a read of the variable.
              SyntheticVariable variable = extern.createVariable(
                expression,
                type,
              );
              hoistedExpressions ??= [];
              hoistedExpressions.add(variable);
              namedExpression.value = extern.createVariableGet(variable)
                ..parent = namedExpression;
            }
            if (!namedNeedsSorting && element.name != sortedNames[nameIndex]) {
              // Named elements are not sorted, so we need to hoist and sort
              // them.
              namedNeedsSorting = true;
              needsHoisting = enableHoisting;
            }
            nameIndex--;
          case PositionalRecordField():
            Expression expression = positional[positionalIndex];
            DartType type = positionalTypes[positionalIndex];
            // TODO(johnniwinther): Should we use [isPureExpression] as is, make
            // it include (simple) literals, or add a new predicate?
            if (needsHoisting && !extern.isPureExpression(expression)) {
              // We hoist the positional element into a synthesized variable,
              // and replace the element in [positional] with a read of the
              // variable.
              SyntheticVariable variable = extern.createVariable(
                expression,
                type,
              );
              hoistedExpressions ??= [];
              hoistedExpressions.add(variable);
              positional[positionalIndex] = extern.createVariableGet(variable);
            } else if (nameIndex >= 0) {
              // We have not seen all named elements yet, so we must hoist the
              // remaining named elements and the preceding positional elements.
              needsHoisting = enableHoisting;
            }
            positionalIndex--;
        }
      }
      namedTypes = new List<NamedType>.generate(sortedNames.length, (
        int index,
      ) {
        String name = sortedNames[index];
        return new NamedType(name, namedResults[name]!.type);
      });
      named = new List<NamedExpression>.generate(sortedNames.length, (
        int index,
      ) {
        String name = sortedNames[index];
        return namedResults[name]!.expression;
      });
    }

    DartType type;
    Expression result;
    if (!libraryBuilder.libraryFeatures.records.isEnabled) {
      // TODO(johnniwinther): Remove this when backends can handle record
      // literals and types without crashing.
      type = const InvalidType();
      result = new InvalidExpression(
        diag.experimentNotEnabledOffByDefault
            .withArguments(featureName: ExperimentalFlag.records.name)
            .withoutLocation()
            .problemMessage,
      );
    } else {
      result = new RecordLiteral(
        positional,
        named ?? [],
        type = new RecordType(
          positionalTypes,
          namedTypes,
          Nullability.nonNullable,
        ),
        isConst: node.isConst,
      )..fileOffset = node.fileOffset;
    }
    if (hoistedExpressions != null) {
      for (SyntheticVariable variable in hoistedExpressions) {
        result = extern.createLet(variable: variable, body: result);
      }
    }
    return new ExpressionInferenceResult(type, result);
  }

  /// Pops the top entry off of [_rewriteStack].
  Object? popRewrite([NullValue? nullValue]) {
    Object entry = _rewriteStack.removeLast();
    if (_debugRewriteStack) {
      // Coverage-ignore-block(suite): Not run.
      assert(_debugPrint('POP ${entry.runtimeType} $entry'));
    }
    if (entry is! NullValue) {
      return entry;
    }
    assert(
      nullValue == entry,
      "Unexpected null value. Expected ${nullValue}, actual $entry",
    );
    return null;
  }

  /// Pushes an entry onto [_rewriteStack].
  void pushRewrite(Object node) {
    if (_debugRewriteStack) {
      // Coverage-ignore-block(suite): Not run.
      assert(_debugPrint('PUSH ${node.runtimeType} $node'));
    }
    _rewriteStack.add(node);
  }

  // Coverage-ignore(suite): Not run.
  /// Helper function used to print information to the console in debug mode.
  /// This method returns `true` so that it can be conveniently called inside of
  /// an `assert` statement.
  bool _debugPrint(String s) {
    print(s);
    return true;
  }

  @override
  ExpressionTypeAnalysisResult dispatchExpression(
    InternalExpression node,
    SharedTypeSchemaView context, {
    bool isVoidAllowed = false,
    bool needsCoercion = false,
  }) {
    ExpressionInferenceResult expressionResult = inferExpression(
      node,
      context.unwrapTypeSchemaView(),
      isVoidAllowed: isVoidAllowed,
    );

    if (needsCoercion) {
      expressionResult =
          coerceExpressionForAssignment(
            context.unwrapTypeSchemaView(),
            expressionResult,
            internalNodeForTesting: node,
          ) ??
          expressionResult;
    }

    pushRewrite(expressionResult.expression);

    return new ExpressionTypeAnalysisResult(
      type: new SharedTypeView(expressionResult.inferredType),
      flowAnalysisInfo: getExpressionInfo(expressionResult.expression),
    );
  }

  @override
  PatternResult dispatchPattern(SharedMatchContext context, InternalNode node) {
    if (node is InternalPattern) {
      return node.acceptInference(this, context);
    } else {
      return analyzeConstantPattern(context, null, node as InternalExpression);
    }
  }

  @override
  SharedTypeSchemaView dispatchPatternSchema(InternalNode node) {
    if (node is InternalPattern) {
      switch (node) {
        case InternalAndPattern():
          return analyzeLogicalAndPatternSchema(node.left, node.right);
        case InternalAssignedVariablePattern():
          return analyzeAssignedVariablePatternSchema(node.variable);
        case InternalCastPattern():
          return analyzeCastPatternSchema();
        case InternalConstantPattern():
          return analyzeConstantPatternSchema();
        case InternalListPattern():
          return analyzeListPatternSchema(
            elementType: node.typeArgument?.wrapSharedTypeView(),
            elements: node.patterns,
          );
        case InternalMapPattern():
          return analyzeMapPatternSchema(
            typeArguments:
                node.keyType != null &&
                    // Coverage-ignore(suite): Not run.
                    node.valueType != null
                ?
                  // Coverage-ignore(suite): Not run.
                  (
                    keyType: new SharedTypeView(node.keyType!),
                    valueType: new SharedTypeView(node.valueType!),
                  )
                : null,
            elements: node.entries,
          );
        case InternalNamedPattern():
          // Coverage-ignore(suite): Not run.
          return dispatchPatternSchema(node.pattern);
        case InternalNullAssertPattern():
          return analyzeNullCheckOrAssertPatternSchema(
            node.pattern,
            isAssert: true,
          );
        case InternalNullCheckPattern():
          return analyzeNullCheckOrAssertPatternSchema(
            node.pattern,
            isAssert: false,
          );
        case InternalObjectPattern():
          return analyzeObjectPatternSchema(
            new SharedTypeView(node.requiredType),
          );
        case InternalOrPattern():
          // Coverage-ignore(suite): Not run.
          return analyzeLogicalOrPatternSchema(node.left, node.right);
        case InternalRecordPattern():
          return analyzeRecordPatternSchema(
            fields: <RecordPatternField<InternalNode, InternalPattern>>[
              for (InternalPattern element in node.patterns)
                if (element is InternalNamedPattern)
                  new RecordPatternField<InternalNode, InternalPattern>(
                    node: element,
                    name: element.name,
                    pattern: element.pattern,
                  )
                else
                  new RecordPatternField<InternalNode, InternalPattern>(
                    node: element,
                    name: null,
                    pattern: element,
                  ),
            ],
          );
        case InternalRelationalPattern():
          // Coverage-ignore(suite): Not run.
          return analyzeRelationalPatternSchema();
        case InternalRestPattern():
          // Coverage-ignore(suite): Not run.
          // This pattern can't appear on it's own.
          return new SharedTypeSchemaView(const InvalidType());
        case InternalVariablePattern():
          return analyzeDeclaredVariablePatternSchema(
            node.type?.wrapSharedTypeView(),
          );
        case InternalWildcardPattern():
          return analyzeDeclaredVariablePatternSchema(
            node.type?.wrapSharedTypeView(),
          );
        case InternalInvalidPattern():
          return new SharedTypeSchemaView(const InvalidType());
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      return problems.unhandled(
        "${node.runtimeType}",
        "dispatchPatternSchema",
        node.fileOffset,
        fileUri,
      );
    }
  }

  @override
  void dispatchStatement(InternalStatement statement) {
    StatementInferenceResult result = inferStatement(statement);
    pushRewrite(result.statement);
  }

  @override
  void finishExpressionCase(
    covariant InternalSwitchExpression node,
    int caseIndex,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight - 2));

    assert(
      checkStack(node, stackBase, [
        ValueKinds.Expression,
        ValueKinds.PatternGuard,
      ]),
    );

    Expression expression = popRewrite() as Expression;
    PatternGuard patternGuard = popRewrite() as PatternGuard;
    pushRewrite(
      extern.createSwitchExpressionCase(
        patternGuard: patternGuard,
        expression: expression,
        fileOffset: node.cases[caseIndex].fileOffset,
      ),
    );

    assert(checkStack(node, stackBase, [ValueKinds.SwitchExpressionCase]));
  }

  Statement _handleImplicitBreak(InternalSwitchStatement node, Statement body) {
    BreakStatement breakStatement = extern.createBreakStatement(
      dummyLabeledStatement,
      fileOffset: TreeNode.noOffset,
    );
    node.breakStatements.add(breakStatement);
    if (body is Block) {
      body.addStatement(breakStatement);
    } else {
      // Coverage-ignore-block(suite): Not run.
      body = new Block([body, breakStatement])..fileOffset = body.fileOffset;
    }
    return body;
  }

  @override
  void handleMergedStatementCase(
    covariant InternalSwitchStatement node, {
    required int caseIndex,
    required bool isTerminating,
  }) {
    switch (node) {
      case InternalRegularSwitchStatement():
        InternalSwitchStatementCase case_ = node.cases[caseIndex];

        int? stackBase;
        assert(
          checkStackBase(
            node,
            stackBase = stackHeight - (1 + case_.caseHeadCount),
          ),
        );

        assert(
          checkStack(node, stackBase, [
            /* body = */ ValueKinds.Statement,
            /* expressions = */ ...repeatedKind(
              ValueKinds.Expression,
              case_.caseHeadCount,
            ),
          ]),
        );

        Statement body = popRewrite() as Statement;

        assert(
          checkStack(node, stackBase, [
            /* expressions = */ ...repeatedKind(
              ValueKinds.Expression,
              case_.caseHeadCount,
            ),
          ]),
        );

        // When patterns are enable, if this is not the last case and it is not
        // terminating, we insert a synthetic break.
        if (libraryBuilder.libraryFeatures.patterns.isEnabled &&
            !isTerminating &&
            // Coverage-ignore(suite): Not run.
            caseIndex < node.cases.length - 1) {
          // Coverage-ignore-block(suite): Not run.
          body = _handleImplicitBreak(node, body);
        }

        assert(
          checkStack(node, stackBase, [
            /* expressions = */ ...repeatedKind(
              ValueKinds.Expression,
              case_.expressions.length,
            ),
          ]),
        );

        List<Expression> expressions = new List.filled(
          case_.expressions.length,
          dummyExpression,
          growable: true,
        );
        for (int i = case_.expressions.length - 1; i >= 0; i--) {
          expressions[i] = popRewrite() as Expression; // CaseHead
        }

        assert(checkStack(node, stackBase, [/*empty*/]));

        SwitchCase replacement = extern.createSwitchCase(
          expressions: expressions,
          expressionOffsets: case_.expressionOffsets,
          body: body,
          isDefault: case_.isDefault,
          fileOffset: case_.fileOffset,
        );
        case_.registerSwitchCase(replacement);
        pushRewrite(replacement);

        assert(
          checkStack(node, stackBase, [/* case = */ ValueKinds.SwitchCase]),
        );
      case InternalPatternSwitchStatement():
        InternalPatternSwitchCase case_ = node.cases[caseIndex];

        int? stackBase;
        assert(
          checkStackBase(
            node,
            stackBase = stackHeight - (1 + case_.caseHeadCount),
          ),
        );

        assert(
          checkStack(node, stackBase, [
            /* body = */ ValueKinds.Statement,
            /* pattern guards = */ ...repeatedKind(
              ValueKinds.PatternGuard,
              case_.caseHeadCount,
            ),
          ]),
        );

        Statement body = popRewrite() as Statement;

        assert(
          checkStack(node, stackBase, [
            /* pattern guards = */ ...repeatedKind(
              ValueKinds.PatternGuard,
              case_.caseHeadCount,
            ),
          ]),
        );

        // When patterns are enable, if this is not the last case and it is not
        // terminating, we insert a synthetic break.
        if (libraryBuilder.libraryFeatures.patterns.isEnabled &&
            !isTerminating &&
            caseIndex < node.cases.length - 1) {
          body = _handleImplicitBreak(node, body);
        }

        assert(
          checkStack(node, stackBase, [
            /* case heads = */ ...repeatedKind(
              ValueKinds.PatternGuard,
              case_.patternGuards.length,
            ),
          ]),
        );

        List<PatternGuard> patternGuards = new List.filled(
          case_.patternGuards.length,
          dummyPatternGuard,
          growable: true,
        );
        for (int i = case_.patternGuards.length - 1; i >= 0; i--) {
          patternGuards[i] = popRewrite() as PatternGuard;
        }

        assert(checkStack(node, stackBase, [/*empty*/]));

        PatternSwitchCase replacement = extern.createPatternSwitchCase(
          caseOffsets: case_.caseOffsets,
          patternGuards: patternGuards,
          body: body,
          isDefault: case_.isDefault,
          hasLabel: case_.hasLabel,
          jointVariables: [
            for (InternalDeclaredVariable variable in case_.jointVariables)
              variable.astVariable,
          ],
          jointVariableFirstUseOffsets: case_.jointVariableFirstUseOffsets,
          fileOffset: case_.fileOffset,
        );
        case_.registerSwitchCase(replacement);
        pushRewrite(replacement);

        assert(
          checkStack(node, stackBase, [
            /* case = */ ValueKinds.PatternSwitchCase,
          ]),
        );
    }
  }

  @override
  FlowAnalysis<
    InternalNode,
    InternalStatement,
    InternalExpression,
    InternalVariable
  >
  get flow => flowAnalysis;

  @override
  SwitchExpressionMemberInfo<InternalNode, InternalExpression, InternalVariable>
  getSwitchExpressionMemberInfo(InternalExpression node, int index) {
    InternalSwitchExpressionCase switchExpressionCase =
        (node as InternalSwitchExpression).cases[index];
    InternalPattern pattern = switchExpressionCase.patternGuard.pattern;
    Map<String, InternalVariable> variables = {
      for (InternalVariable declaredVariable in pattern.declaredVariables)
        declaredVariable.cosmeticName!: declaredVariable,
    };
    return new SwitchExpressionMemberInfo(
      head: new CaseHeadInfo(
        pattern: pattern,
        guard: switchExpressionCase.patternGuard.guard,
        variables: variables,
      ),
      expression: switchExpressionCase.expression,
    );
  }

  @override
  SwitchStatementMemberInfo<
    InternalNode,
    InternalStatement,
    InternalExpression,
    InternalVariable
  >
  getSwitchStatementMemberInfo(
    covariant InternalSwitchStatement node,
    int caseIndex,
  ) {
    switch (node) {
      case InternalRegularSwitchStatement():
        InternalSwitchStatementCase case_ = node.cases[caseIndex];
        return new SwitchStatementMemberInfo(
          heads: [
            for (InternalExpression expression in case_.expressions)
              new CaseHeadInfo(pattern: expression, variables: {}),
            if (case_.isDefault) new CaseDefaultInfo(),
          ],
          body: [case_.body],
          variables: {},
          hasLabels: case_.hasLabel,
        );
      case InternalPatternSwitchStatement():
        InternalPatternSwitchCase case_ = node.cases[caseIndex];
        return new SwitchStatementMemberInfo(
          heads: [
            for (InternalPatternGuard patternGuard in case_.patternGuards)
              new CaseHeadInfo(
                pattern: patternGuard.pattern,
                guard: patternGuard.guard,
                variables: {
                  for (InternalVariable variable
                      in patternGuard.pattern.declaredVariables)
                    variable.cosmeticName!: variable,
                },
              ),
            if (case_.isDefault) new CaseDefaultInfo(),
          ],
          body: [case_.body],
          variables: {
            for (InternalVariable jointVariable in case_.jointVariables)
              jointVariable.cosmeticName!: jointVariable,
          },
          hasLabels: case_.hasLabel,
        );
    }
  }

  @override
  void handleCaseHead(
    covariant InternalSwitch node, {
    required int caseIndex,
    required int subIndex,
  }) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight - 2));

    void handleConstantPattern(Expression expression) {
      Set<Field?>? enumFields = _enumFields;
      if (enumFields != null) {
        if (expression is StaticGet) {
          enumFields.remove(expression.target);
        } else if (expression is NullLiteral) {
          enumFields.remove(null);
        }
      }
    }

    switch (node) {
      case InternalRegularSwitchStatement():
        assert(
          checkStack(node, stackBase, [
            /* guard = */ ValueKinds.ExpressionOrNull,
            /* expression = */ ValueKinds.Expression,
          ]),
        );

        Object? guard = popRewrite(NullValues.Expression);
        assert(guard == null, "Unexpected guard in switch statement $guard.");

        assert(
          checkStack(node, stackBase, [
            /* expression = */
            ValueKinds.Expression,
          ]),
        );

        Expression expression = popRewrite() as Expression;

        assert(checkStack(node, stackBase, [/*empty*/]));

        handleConstantPattern(expression);

        pushRewrite(expression);
      case InternalPatternSwitchStatement():
        assert(
          checkStack(node, stackBase, [
            /* guard = */ ValueKinds.ExpressionOrNull,
            /* pattern  = */ ValueKinds.Pattern,
          ]),
        );

        Expression? guard = popRewrite(NullValues.Expression) as Expression?;

        assert(
          checkStack(node, stackBase, [
            /* pattern or expression = */ unionOfKinds([
              ValueKinds.Pattern,
              ValueKinds.Expression,
            ]),
          ]),
        );

        InternalPatternSwitchCase case_ = node.cases[caseIndex];
        Pattern pattern = popRewrite() as Pattern;
        if (guard == null && pattern is ConstantPattern) {
          handleConstantPattern(pattern.expression);
        }

        pushRewrite(
          extern.createPatternGuard(
            pattern: pattern,
            guard: guard,
            fileOffset: case_.patternGuards[subIndex].fileOffset,
          ),
        );
      case InternalSwitchExpression():
        InternalSwitchExpressionCase case_ = node.cases[caseIndex];

        assert(
          checkStack(node, stackBase, [
            /* guard = */ ValueKinds.ExpressionOrNull,
            /* pattern = */ ValueKinds.Pattern,
          ]),
        );

        Expression? guard = popRewrite(NullValues.Expression) as Expression?;

        assert(
          checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]),
        );

        Pattern pattern = popRewrite() as Pattern;

        assert(checkStack(node, stackBase, [/*empty*/]));

        if (guard == null && pattern is ConstantPattern) {
          handleConstantPattern(pattern.expression);
        }
        pushRewrite(
          extern.createPatternGuard(
            pattern: pattern,
            guard: guard,
            fileOffset: case_.patternGuard.fileOffset,
          ),
        );
    }
  }

  @override
  void handleCase_afterCaseHeads(
    InternalStatement node,
    int caseIndex,
    Iterable<InternalVariable> variables,
  ) {}

  @override
  void handleDefault(
    InternalNode node, {
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleNoStatement(InternalStatement node) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    pushRewrite(NullValues.Statement);

    assert(
      checkStack(node, stackBase, [
        /* statement = */ ValueKinds.StatementOrNull,
      ]),
    );
  }

  @override
  void handleNoGuard(InternalNode node, int caseIndex) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    pushRewrite(NullValues.Expression);

    assert(
      checkStack(node, stackBase, [
        /* expression = */ ValueKinds.ExpressionOrNull,
      ]),
    );
  }

  @override
  void handleSwitchBeforeAlternative(
    InternalNode node, {
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleSwitchScrutinee(SharedTypeView type) {
    DartType unwrapped = type.unwrapTypeView();
    if ((!typeAnalyzerOptions.patternsEnabled) &&
        unwrapped is InterfaceType &&
        unwrapped.classNode.isEnum) {
      _enumFields = <Field?>{
        ...unwrapped.classNode.fields.where(
          (Field field) => field.isEnumElement,
        ),
        if (type.unwrapTypeView<DartType>().isPotentiallyNullable) null,
      };
    } else {
      _enumFields = null;
    }

    pushRewrite(type);
  }

  @override
  bool isLegacySwitchExhaustive(
    InternalNode node,
    SharedTypeView expressionType,
  ) {
    Set<Field?>? enumFields = _enumFields;
    return enumFields != null && enumFields.isEmpty;
  }

  @override
  bool isVariablePattern(InternalNode node) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void setVariableType(InternalVariable variable, SharedTypeView type) {
    variable.type = type.unwrapTypeView();
  }

  @override
  SharedTypeView variableTypeFromInitializerType(SharedTypeView type) {
    // TODO(paulberry): make a test verifying that we don't need to pass
    // `forSyntheticVariable: true` (and possibly a language issue)
    return new SharedTypeView(
      inferDeclarationType(
        type.unwrapTypeView(),
        inferenceDefaultType: InferenceDefaultType.Dynamic,
      ),
    );
  }

  @override
  void checkCleanState() {
    assert(_rewriteStack.isEmpty);
  }

  PatternResult visitInternalVariablePattern(
    InternalVariablePattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DeclaredVariablePatternResult<InvalidExpression> analysisResult =
        analyzeDeclaredVariablePattern(
          context,
          node,
          node.variable,
          node.variableName,
          node.type?.wrapSharedTypeView(),
        );

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    DartType inferredType = analysisResult.staticType.unwrapTypeView();
    if (node.type == null) {
      node.variable.type = inferredType;
    }

    pushRewrite(
      replacement ??
          extern.createVariablePattern(
            type: node.type,
            variable: node.variable.astVariable,
            matchedValueType: matchedValueType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalWildcardPattern(
    InternalWildcardPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    WildcardPatternResult<InvalidExpression> analysisResult =
        analyzeWildcardPattern(
          context: context,
          node: node,
          declaredType: node.type?.wrapSharedTypeView(),
        );

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    pushRewrite(
      replacement ??
          extern.createWildcardPattern(
            type: node.type,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalConstantPattern(
    InternalConstantPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    ConstantPatternResult<InvalidExpression> analysisResult =
        analyzeConstantPattern(context, node, node.expression);

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError;
    if (error != null) {
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    DartType expressionType = analysisResult.expressionType.unwrapTypeView();

    ObjectAccessTarget equalsInvokeTarget = findInterfaceMember(
      expressionType,
      equalsName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    assert(
      equalsInvokeTarget.isInstanceMember ||
          equalsInvokeTarget.isObjectMember ||
          equalsInvokeTarget.isNever,
    );

    Procedure equalsTarget = equalsInvokeTarget.classMember as Procedure;
    FunctionType equalsType = equalsInvokeTarget
        .getFunctionType(this)
        .equalsFunctionType;

    assert(
      checkStack(node, stackBase, [/* expression = */ ValueKinds.Expression]),
    );

    Expression expression = popRewrite() as Expression;

    pushRewrite(
      replacement ??
          extern.createConstantPattern(
            expression: expression,
            expressionType: expressionType,
            equalsTarget: equalsTarget,
            equalsType: equalsType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalAndPattern(
    InternalAndPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternResult analysisResult = analyzeLogicalAndPattern(
      context,
      node,
      node.left,
      node.right,
    );

    assert(
      checkStack(node, stackBase, [
        /* right = */ ValueKinds.Pattern,
        /* left = */ ValueKinds.Pattern,
      ]),
    );

    Pattern right = popRewrite() as Pattern;
    Pattern left = popRewrite() as Pattern;

    pushRewrite(
      extern.createAndPattern(
        left: left,
        right: right,
        fileOffset: node.fileOffset,
      ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalOrPattern(
    InternalOrPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    LogicalOrPatternResult<InvalidExpression> analysisResult =
        analyzeLogicalOrPattern(context, node, node.left, node.right);

    assert(
      checkStack(node, stackBase, [
        /* right = */ ValueKinds.Pattern,
        /* left = */ ValueKinds.Pattern,
      ]),
    );

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError;
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    Pattern right = popRewrite() as Pattern;
    Pattern left = popRewrite() as Pattern;

    Map<String, DeclaredVariable> leftDeclaredVariablesByName = {
      for (InternalDeclaredVariable variable in node.left.declaredVariables)
        variable.cosmeticName!: variable.astVariable,
    };
    Map<String, DeclaredVariable> jointVariableNames = {
      for (InternalDeclaredVariable variable in node.orPatternJointVariables)
        variable.cosmeticName!: variable.astVariable,
    };
    for (InternalDeclaredVariable rightVariable
        in node.right.declaredVariables) {
      String rightVariableName = rightVariable.cosmeticName!;
      DeclaredVariable? leftVariable =
          leftDeclaredVariablesByName[rightVariableName];
      DeclaredVariable? jointVariable = jointVariableNames[rightVariableName];
      if (leftVariable != null && jointVariable != null) {
        if (leftVariable.type != rightVariable.type ||
            leftVariable.isFinal != rightVariable.isFinal) {
          problemReporting.addProblem(
            diag.jointPatternVariablesMismatch.withArguments(
              variableName: rightVariableName,
            ),
            leftVariable.fileOffset,
            rightVariableName.length,
            fileUri,
          );
        } else {
          jointVariable.isFinal = rightVariable.isFinal;
          jointVariable.type = rightVariable.type;
        }
      }
    }

    replacement ??= extern.createOrPattern(
      left: left,
      right: right,
      orPatternJointVariables: jointVariableNames.values.toList(),
      fileOffset: node.fileOffset,
    );

    pushRewrite(replacement);

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalCastPattern(
    InternalCastPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternResult analysisResult = analyzeCastPattern(
      context: context,
      pattern: node,
      innerPattern: node.pattern,
      requiredType: new SharedTypeView(node.type),
    );

    assert(
      checkStack(node, stackBase, [/* subpattern = */ ValueKinds.Pattern]),
    );

    Pattern pattern = popRewrite() as Pattern;

    pushRewrite(
      extern.createCastPattern(
        pattern: pattern,
        type: node.type,
        fileOffset: node.fileOffset,
      ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalNullAssertPattern(
    InternalNullAssertPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    NullCheckOrAssertPatternResult<InvalidExpression> analysisResult =
        analyzeNullCheckOrAssertPattern(
          context,
          node,
          node.pattern,
          isAssert: true,
        );

    assert(
      checkStack(node, stackBase, [/* subpattern = */ ValueKinds.Pattern]),
    );

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError;
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    Pattern pattern = popRewrite() as Pattern;

    pushRewrite(
      replacement ??
          extern.createNullAssertPattern(
            pattern: pattern,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalNullCheckPattern(
    InternalNullCheckPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    NullCheckOrAssertPatternResult<InvalidExpression> analysisResult =
        analyzeNullCheckOrAssertPattern(
          context,
          node,
          node.pattern,
          isAssert: false,
        );

    assert(
      checkStack(node, stackBase, [/* subpattern = */ ValueKinds.Pattern]),
    );

    Pattern pattern = popRewrite() as Pattern;

    pushRewrite(
      extern.createNullCheckPattern(
        pattern: pattern,
        fileOffset: node.fileOffset,
      ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalListPattern(
    InternalListPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    ListPatternResult<InvalidExpression> analysisResult = analyzeListPattern(
      context,
      node,
      elements: node.patterns,
      elementType: node.typeArgument?.wrapSharedTypeView(),
    );

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* subpatterns = */ ...repeatedKind(
          ValueKinds.Pattern,
          node.patterns.length,
        ),
      ]),
    );

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    List<Pattern> patterns = new List.filled(
      node.patterns.length,
      dummyPattern,
      growable: true,
    );
    for (int i = node.patterns.length - 1; i >= 0; i--) {
      Object? rewrite = popRewrite();
      InvalidExpression? error = analysisResult.duplicateRestPatternErrors?[i];
      if (error != null) {
        patterns[i] = extern.createInvalidPattern(
          error: error,
          declaredVariables: node.patterns[i].declaredVariables,
        );
      } else {
        patterns[i] = rewrite as Pattern;
      }
    }

    // TODO(johnniwinther): The required type computed by the type analyzer
    // isn't trivially `List<dynamic>` in all cases. Does that matter for the
    // lowering?
    DartType requiredType = analysisResult.requiredType.unwrapTypeView();

    bool needsCheck = _needsCheck(
      matchedType: matchedValueType,
      requiredType: requiredType,
    );

    DartType lookupType;
    if (needsCheck) {
      lookupType = requiredType;
    } else {
      lookupType = matchedValueType;
    }

    ObjectAccessTarget lengthTarget = findInterfaceMember(
      requiredType,
      lengthName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    assert(lengthTarget.isInstanceMember);

    DartType lengthType = lengthTarget.getGetterType(this);
    Member lengthMember = lengthTarget.classMember!;

    ObjectAccessTarget sublistInvokeTarget = findInterfaceMember(
      requiredType,
      sublistName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    assert(sublistInvokeTarget.isInstanceMember);

    Procedure sublistTarget = sublistInvokeTarget.classMember as Procedure;
    FunctionType sublistType = sublistInvokeTarget
        .getFunctionType(this)
        .sublistFunctionType;

    ObjectAccessTarget minusTarget = findInterfaceMember(
      lengthType,
      minusName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    assert(minusTarget.isInstanceMember);
    assert(minusTarget.isSpecialCasedBinaryOperator(this));

    Procedure minusProcedure = minusTarget.classMember as Procedure;
    FunctionType minusType = replaceReturnType(
      minusTarget.getFunctionType(this).minusFunctionType,
      typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
        lengthType,
        coreTypes.intNonNullableRawType,
      ),
    );

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
      requiredType,
      indexGetName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    assert(indexGetTarget.isInstanceMember);

    Procedure indexGet = indexGetTarget.classMember as Procedure;
    FunctionType indexGetType = indexGetTarget
        .getFunctionType(this)
        .indexGetFunctionType;

    bool hasRestPattern = false;
    for (Pattern pattern in patterns) {
      if (pattern is RestPattern) {
        hasRestPattern = true;
        break;
      }
    }

    Procedure lengthCheckTarget;
    FunctionType lengthCheckType;
    if (hasRestPattern) {
      ObjectAccessTarget greaterThanOrEqualTarget = findInterfaceMember(
        lengthType,
        greaterThanOrEqualsName,
        node.fileOffset,
        includeExtensionMethods: true,
        isSetter: false,
      );
      assert(greaterThanOrEqualTarget.isInstanceMember);

      lengthCheckTarget = greaterThanOrEqualTarget.classMember as Procedure;
      lengthCheckType = greaterThanOrEqualTarget
          .getFunctionType(this)
          .greaterThanOrEqualsFunctionType;
    } else if (node.patterns.isEmpty) {
      ObjectAccessTarget lessThanOrEqualsInvokeTarget = findInterfaceMember(
        lengthType,
        lessThanOrEqualsName,
        node.fileOffset,
        includeExtensionMethods: true,
        isSetter: false,
      );
      assert(lessThanOrEqualsInvokeTarget.isInstanceMember);

      lengthCheckTarget = lessThanOrEqualsInvokeTarget.classMember as Procedure;
      lengthCheckType = lessThanOrEqualsInvokeTarget
          .getFunctionType(this)
          .lessThanOrEqualsFunctionType;
    } else {
      ObjectAccessTarget equalsInvokeTarget = findInterfaceMember(
        lengthType,
        equalsName,
        node.fileOffset,
        includeExtensionMethods: true,
        isSetter: false,
      );
      assert(equalsInvokeTarget.isInstanceMember);

      lengthCheckTarget = equalsInvokeTarget.classMember as Procedure;
      lengthCheckType = equalsInvokeTarget
          .getFunctionType(this)
          .equalsFunctionType;
    }

    pushRewrite(
      replacement ??
          extern.createListPattern(
            typeArgument: node.typeArgument,
            patterns: patterns,
            requiredType: requiredType,
            matchedValueType: matchedValueType,
            needsCheck: needsCheck,
            lookupType: lookupType,
            hasRestPattern: hasRestPattern,
            lengthTarget: lengthMember,
            lengthType: lengthType,
            lengthCheckTarget: lengthCheckTarget,
            lengthCheckType: lengthCheckType,
            sublistTarget: sublistTarget,
            sublistType: sublistType,
            minusTarget: minusProcedure,
            minusType: minusType,
            indexGetTarget: indexGet,
            indexGetType: indexGetType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  bool _needsCast({
    required DartType matchedType,
    required DartType requiredType,
  }) {
    return !typeSchemaEnvironment.isSubtypeOf(matchedType, requiredType);
  }

  bool _needsCheck({
    required DartType matchedType,
    required DartType requiredType,
  }) {
    // TODO(johnniwinther): Should we use `isSubtypeOf` here instead?
    return !isAssignable(requiredType, matchedType) ||
        matchedType is InvalidType ||
        matchedType is DynamicType;
  }

  PatternResult visitInternalObjectPattern(
    InternalObjectPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    ObjectPatternResult<InvalidExpression> analysisResult =
        analyzeObjectPattern(
          context,
          node,
          fields: <RecordPatternField<InternalNode, InternalPattern>>[
            for (InternalNamedPattern field in node.fields)
              new RecordPatternField(
                node: field,
                name: field.name,
                pattern: field.pattern,
              ),
          ],
        );

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* subpatterns = */ ...repeatedKind(
          ValueKinds.Pattern,
          node.fields.length,
        ),
      ]),
    );

    node.requiredType = analysisResult.requiredType.unwrapTypeView();

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    List<NamedPattern> fields = new List.filled(
      node.fields.length,
      dummyNamedPattern,
      growable: true,
    );
    for (int i = node.fields.length - 1; i >= 0; i--) {
      InternalNamedPattern field = node.fields[i];
      Object? rewrite = popRewrite();
      InvalidExpression? error =
          analysisResult.duplicateRecordPatternFieldErrors?[i];
      if (error != null) {
        fields[i] = extern.createNamedPattern(
          name: field.name,
          fieldName: new Name(field.name, libraryBuilder.library),
          pattern: extern.createInvalidPattern(
            error: error,
            declaredVariables: field.pattern.declaredVariables,
          ),
          fileOffset: field.fileOffset,
        );
      } else {
        fields[i] = extern.createNamedPattern(
          name: field.name,
          fieldName: new Name(field.name, libraryBuilder.library),
          pattern: rewrite as Pattern,
          fileOffset: field.fileOffset,
        );
      }
    }

    bool needsCheck = _needsCheck(
      matchedType: matchedValueType,
      requiredType: node.requiredType,
    );

    DartType lookupType;
    if (needsCheck) {
      lookupType = node.requiredType;
    } else {
      lookupType = matchedValueType;
    }

    for (NamedPattern field in fields) {
      ObjectAccessTarget fieldTarget = findInterfaceMember(
        node.requiredType,
        field.fieldName,
        field.fileOffset,
        includeExtensionMethods: true,
        isSetter: false,
      );

      switch (fieldTarget.kind) {
        case ObjectAccessTargetKind.instanceMember:
          field.target = fieldTarget.classMember!;
          field.resultType = fieldTarget.getGetterType(this);
          field.accessKind = ObjectAccessKind.Instance;
          break;
        case ObjectAccessTargetKind.objectMember:
          field.target = fieldTarget.classMember!;
          field.resultType = fieldTarget.getGetterType(this);
          field.accessKind = ObjectAccessKind.Object;
          break;
        case ObjectAccessTargetKind.recordNamed:
          field.recordType =
              node.requiredType.nonTypeParameterBound as RecordType;
          field.accessKind = ObjectAccessKind.RecordNamed;
          break;
        case ObjectAccessTargetKind.recordIndexed:
          field.recordType =
              node.requiredType.nonTypeParameterBound as RecordType;
          field.accessKind = ObjectAccessKind.RecordIndexed;
          field.recordFieldIndex = fieldTarget.recordFieldIndex!;
          break;
        case ObjectAccessTargetKind.nullableInstanceMember:
        case ObjectAccessTargetKind.nullableExtensionMember:
        case ObjectAccessTargetKind.nullableExtensionTypeMember:
        case ObjectAccessTargetKind.nullableRecordIndexed:
        case ObjectAccessTargetKind.nullableRecordNamed:
        case ObjectAccessTargetKind.nullableCallFunction:
        case ObjectAccessTargetKind.missing:
        case ObjectAccessTargetKind.ambiguous:
        case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        case ObjectAccessTargetKind.expressionEvaluationParameter:
          field.pattern =
              new InvalidPattern(
                  createMissingPropertyGet(
                    field.fileOffset,
                    node.requiredType,
                    field.fieldName,
                  ),
                  declaredVariables: field.pattern.declaredVariables,
                )
                ..fileOffset = field.fileOffset
                ..parent = field;
          field.accessKind = ObjectAccessKind.Error;
          break;
        case ObjectAccessTargetKind.invalid:
          field.accessKind = ObjectAccessKind.Invalid;
          break;
        case ObjectAccessTargetKind.callFunction:
          field.accessKind = ObjectAccessKind.FunctionTearOff;
          break;
        case ObjectAccessTargetKind.extensionTypeRepresentation:
          field.accessKind = ObjectAccessKind.Direct;
          field.resultType = fieldTarget.getGetterType(this);
        case ObjectAccessTargetKind.superMember:
          // Coverage-ignore(suite): Not run.
          problems.unsupported(
            'Object field target $fieldTarget',
            node.fileOffset,
            fileUri,
          );
        case ObjectAccessTargetKind.extensionMember:
          field.accessKind = ObjectAccessKind.Extension;
          field.resultType = fieldTarget.getGetterType(this);
          field.typeArguments = fieldTarget.receiverTypeArguments;
          field.target = fieldTarget.tearoffTarget;
          break;
        case ObjectAccessTargetKind.extensionTypeMember:
          field.accessKind = ObjectAccessKind.ExtensionType;
          field.resultType = fieldTarget.getGetterType(this);
          field.typeArguments = fieldTarget.receiverTypeArguments;
          // TODO(johnniwinther): Extension type getters currently have no
          // explicitly set tear-off target. Maybe they should.
          field.target = fieldTarget.tearoffTarget ?? fieldTarget.member;
          break;
        case ObjectAccessTargetKind.dynamic:
          field.accessKind = ObjectAccessKind.Dynamic;
          break;
        case ObjectAccessTargetKind.never:
          field.accessKind = ObjectAccessKind.Never;
          break;
      }
      if (fieldTarget.isInstanceMember || fieldTarget.isObjectMember) {
        // TODO(johnniwinther): Use [fieldTarget] to compute the checked type.
        Member interfaceMember = fieldTarget.classMember!;
        if (interfaceMember is Procedure) {
          DartType typeToCheck = interfaceMember.function.computeFunctionType(
            Nullability.nonNullable,
          );
          field.checkReturn =
              InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                interfaceMember.enclosingTypeDeclaration!,
                typeToCheck,
              );
        } else if (interfaceMember is Field) {
          field.checkReturn =
              InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                interfaceMember.enclosingTypeDeclaration!,
                interfaceMember.type,
              );
        }
      }
    }

    pushRewrite(
      replacement ??
          extern.createObjectPattern(
            requiredType: node.requiredType,
            fields: fields,
            matchedValueType: matchedValueType,
            needsCheck: needsCheck,
            lookupType: lookupType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalInvalidPattern(
    InternalInvalidPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    pushRewrite(
      extern.createInvalidPattern(
        error: extern.createInvalidExpression(
          node.invalidExpression.message,
          fileOffset: node.invalidExpression.fileOffset,
        ),
        declaredVariables: node.declaredVariables,
      ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));

    return new PatternResult(
      matchedValueType: new SharedTypeView(const InvalidType()),
    );
  }

  PatternResult visitInternalRelationalPattern(
    InternalRelationalPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    RelationalPatternResult<InvalidExpression> analysisResult =
        analyzeRelationalPattern(context, node, node.expression);

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();

    assert(
      checkStack(node, stackBase, [/* expression = */ ValueKinds.Expression]),
    );

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError ??
        analysisResult.operatorReturnTypeNotAssignableToBoolError ??
        analysisResult.argumentTypeNotAssignableError;
    if (error != null) {
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    Expression expression = popRewrite() as Expression;

    DartType expressionType = analysisResult.operandType.unwrapTypeView();

    Name name;
    switch (node.kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        name = equalsName;
        break;
      case RelationalPatternKind.lessThan:
        name = lessThanName;
        break;
      case RelationalPatternKind.lessThanEqual:
        name = lessThanOrEqualsName;
        break;
      case RelationalPatternKind.greaterThan:
        name = greaterThanName;
        break;
      case RelationalPatternKind.greaterThanEqual:
        name = greaterThanOrEqualsName;
        break;
    }
    ObjectAccessTarget invokeTarget = findInterfaceMember(
      matchedValueType,
      name,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    FunctionType? functionType;
    RelationalAccessKind? accessKind;
    Procedure? target;
    List<DartType>? typeArguments;
    switch (node.kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        assert(
          invokeTarget.isInstanceMember ||
              invokeTarget.isObjectMember ||
              invokeTarget.isNever,
        );

        functionType = invokeTarget.getFunctionType(this).equalsFunctionType;
        accessKind = RelationalAccessKind.Instance;
        target = invokeTarget.classMember as Procedure;
        break;
      case RelationalPatternKind.lessThan:
      case RelationalPatternKind.lessThanEqual:
      case RelationalPatternKind.greaterThan:
      case RelationalPatternKind.greaterThanEqual:
        switch (invokeTarget.kind) {
          case ObjectAccessTargetKind.instanceMember:
            functionType = invokeTarget
                .getFunctionType(this)
                .lessThanOrEqualsFunctionType;
            target = invokeTarget.classMember as Procedure;
            accessKind = RelationalAccessKind.Instance;
            break;
          case ObjectAccessTargetKind.nullableInstanceMember:
          case ObjectAccessTargetKind.nullableExtensionMember:
          case ObjectAccessTargetKind.nullableExtensionTypeMember:
          case ObjectAccessTargetKind.missing:
          case ObjectAccessTargetKind.ambiguous:
            accessKind = RelationalAccessKind.Invalid;
            replacement ??= extern.createInvalidPattern(
              error: createMissingMethodInvocation(
                node.fileOffset,
                matchedValueType,
                name,
                isExpressionInvocation: false,
              ),
              declaredVariables: node.declaredVariables,
            );
            break;
          case ObjectAccessTargetKind.objectMember:
          case ObjectAccessTargetKind.superMember:
          case ObjectAccessTargetKind.callFunction:
          case ObjectAccessTargetKind.nullableCallFunction:
          case ObjectAccessTargetKind.recordIndexed:
          case ObjectAccessTargetKind.recordNamed:
          case ObjectAccessTargetKind.nullableRecordIndexed:
          case ObjectAccessTargetKind.nullableRecordNamed:
          case ObjectAccessTargetKind.extensionTypeRepresentation:
          case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
          case ObjectAccessTargetKind.expressionEvaluationParameter:
            // Coverage-ignore(suite): Not run.
            problems.unsupported(
              'Relational pattern target $invokeTarget',
              node.fileOffset,
              fileUri,
            );
          case ObjectAccessTargetKind.extensionMember:
          case ObjectAccessTargetKind.extensionTypeMember:
            functionType = invokeTarget
                .getFunctionType(this)
                .relationalFunctionType;
            typeArguments = invokeTarget.receiverTypeArguments;
            target = invokeTarget.member as Procedure;
            accessKind = RelationalAccessKind.Static;
            break;
          case ObjectAccessTargetKind.dynamic:
            accessKind = RelationalAccessKind.Dynamic;
            break;
          case ObjectAccessTargetKind.never:
            accessKind = RelationalAccessKind.Never;
            break;
          case ObjectAccessTargetKind.invalid:
            accessKind = RelationalAccessKind.Invalid;
            break;
        }
        break;
    }

    pushRewrite(
      replacement ??
          extern.createRelationalPattern(
            kind: node.kind,
            expression: expression,
            expressionType: expressionType,
            matchedValueType: matchedValueType,
            accessKind: accessKind,
            name: name,
            target: target,
            typeArguments: typeArguments,
            functionType: functionType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalMapPattern(
    InternalMapPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    ({SharedTypeView keyType, SharedTypeView valueType})? typeArguments =
        node.keyType == null && node.valueType == null
        ? null
        : (
            keyType: new SharedTypeView(node.keyType ?? const DynamicType()),
            valueType: new SharedTypeView(
              node.valueType ?? const DynamicType(),
            ),
          );
    MapPatternResult<InvalidExpression> analysisResult = analyzeMapPattern(
      context,
      node,
      typeArguments: typeArguments,
      elements: node.entries,
    );

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    error = analysisResult.emptyMapPatternError;
    if (error != null) {
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    // TODO(johnniwinther): The required type computed by the type analyzer
    // isn't trivially `Map<dynamic, dynamic>` in all cases. Does that matter
    // for the lowering?
    DartType requiredType = analysisResult.requiredType.unwrapTypeView();

    bool needsCheck = _needsCheck(
      matchedType: matchedValueType,
      requiredType: requiredType,
    );

    DartType lookupType;
    if (needsCheck) {
      lookupType = requiredType;
    } else {
      lookupType = matchedValueType;
    }

    ObjectAccessTarget containsKeyTarget = findInterfaceMember(
      requiredType,
      containsKeyName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    assert(containsKeyTarget.isInstanceMember);

    Procedure containsKeyProcedure = containsKeyTarget.classMember as Procedure;
    FunctionType containsKeyType = containsKeyTarget
        .getFunctionType(this)
        .containsKeyFunctionType;

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
      requiredType,
      indexGetName,
      node.fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );
    assert(indexGetTarget.isInstanceMember);

    Procedure indexGetProcedure = indexGetTarget.classMember as Procedure;
    FunctionType indexGetType = indexGetTarget
        .getFunctionType(this)
        .indexGetFunctionType;

    assert(
      checkStack(node, stackBase, [
        /* entries = */ ...repeatedKind(
          ValueKinds.MapPatternEntry,
          node.entries.length,
        ),
      ]),
    );

    List<MapPatternEntry> entries = new List.filled(
      node.entries.length,
      dummyMapPatternEntry,
      growable: true,
    );
    for (int i = node.entries.length - 1; i >= 0; i--) {
      entries[i] = popRewrite() as MapPatternEntry;
    }

    Map<int, InvalidExpression>? restPatternErrors =
        analysisResult.restPatternErrors;
    if (restPatternErrors != null) {
      InvalidExpression? firstError;
      int insertionIndex = 0;
      for (int readIndex = 0; readIndex < entries.length; readIndex++) {
        InvalidExpression? error = restPatternErrors[readIndex];
        if (error != null) {
          firstError ??= error;
        } else {
          entries[insertionIndex++] = entries[readIndex];
        }
      }
      entries.length = insertionIndex;
      if (insertionIndex == 0) {
        replacement ??= extern.createInvalidPattern(
          error: firstError!,
          declaredVariables: node.declaredVariables,
          fileOffset: node.fileOffset,
        );
      }
    }

    pushRewrite(
      replacement ??
          extern.createMapPattern(
            keyType: node.keyType,
            valueType: node.valueType,
            entries: entries,
            requiredType: requiredType,
            matchedValueType: matchedValueType,
            needsCheck: needsCheck,
            lookupType: lookupType,
            containsKeyTarget: containsKeyProcedure,
            containsKeyType: containsKeyType,
            indexGetTarget: indexGetProcedure,
            indexGetType: indexGetType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  PatternResult visitInternalRecordPattern(
    InternalRecordPattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    List<RecordPatternField<InternalNode, InternalPattern>> fields = [
      for (InternalPattern fieldPattern in node.patterns)
        new RecordPatternField(
          node: fieldPattern,
          pattern: fieldPattern is InternalNamedPattern
              ? fieldPattern.pattern
              : fieldPattern,
          name: fieldPattern is InternalNamedPattern ? fieldPattern.name : null,
        ),
    ];
    RecordPatternResult<InvalidExpression> analysisResult =
        analyzeRecordPattern(context, node, fields: fields);

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* fields = */ ...repeatedKind(
          ValueKinds.Pattern,
          node.patterns.length,
        ),
      ]),
    );

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError ??
        analysisResult.duplicateRecordPatternFieldErrors?.values.first;
    if (error != null) {
      replacement = extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    RecordType requiredType = analysisResult.requiredType as RecordType;

    // TODO(johnniwinther): How does `recordType` relate to `node.recordType`?
    bool needsCheck = _needsCheck(
      matchedType: matchedValueType,
      requiredType: requiredType,
    );
    RecordType lookupType;
    if (needsCheck) {
      lookupType = requiredType;
    } else {
      DartType resolvedType = matchedValueType.nonTypeParameterBound;
      if (resolvedType is RecordType) {
        lookupType = resolvedType;
      } else {
        // In case of the matched type being an invalid type we use the
        // required type instead.
        lookupType = requiredType;
      }
    }

    List<Pattern> patterns = new List.filled(
      node.patterns.length,
      dummyPattern,
      growable: true,
    );
    for (int i = node.patterns.length - 1; i >= 0; i--) {
      InternalPattern subPattern = node.patterns[i];
      Object? rewrite = popRewrite();
      if (subPattern is InternalNamedPattern) {
        patterns[i] = extern.createNamedPattern(
          name: subPattern.name,
          pattern: rewrite as Pattern,
          fileOffset: subPattern.fileOffset,
        );
      } else {
        patterns[i] = rewrite as Pattern;
      }
    }

    pushRewrite(
      replacement ??
          extern.createRecordPattern(
            patterns: patterns,
            requiredType: requiredType,
            matchedValueType: matchedValueType,
            needsCheck: needsCheck,
            lookupType: lookupType,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  ExpressionInferenceResult visitInternalPatternAssignment(
    InternalPatternAssignment node,
    DartType typeContext,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternAssignmentAnalysisResult analysisResult = analyzePatternAssignment(
      node,
      node.pattern,
      node.expression,
    );
    DartType matchedValueType = analysisResult.type.unwrapTypeView();

    assert(
      checkStack(node, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* expression = */ ValueKinds.Expression,
      ]),
    );

    Pattern pattern = popRewrite() as Pattern;

    assert(
      checkStack(node, stackBase, [/* expression = */ ValueKinds.Expression]),
    );

    Expression expression = popRewrite() as Expression;

    assert(checkStack(node, stackBase, [/*empty*/]));

    return new ExpressionInferenceResult(
      analysisResult.type.unwrapTypeView(),
      extern.createPatternAssignment(
        pattern: pattern,
        expression: expression,
        matchedValueType: matchedValueType,
        fileOffset: node.fileOffset,
      ),
    );
  }

  PatternResult visitInternalAssignedVariablePattern(
    InternalAssignedVariablePattern node,
    SharedMatchContext context,
  ) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    // TODO(johnniwinther): Share this through the type analyzer.
    Pattern? replacement;
    InternalVariable variable = node.variable;
    bool isDefinitelyAssigned = flowAnalysis.isAssigned(variable);
    bool isDefinitelyUnassigned = flowAnalysis.isUnassigned(variable);
    if ((variable.isLate && variable.isFinal) ||
        variable.isLateFinalWithoutInitializer) {
      if (isDefinitelyAssigned) {
        replacement = extern.createInvalidPattern(
          error: extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.lateDefinitelyAssignedError.withArguments(
                variableName: node.variableName,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: node.variableName.length,
            ),
          ),
          declaredVariables: node.declaredVariables,
        );
      }
    } else if (variable.isStaticLate) {
      if (!isDefinitelyUnassigned) {
        replacement = extern.createInvalidPattern(
          error: extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.finalPossiblyAssignedError.withArguments(
                variableName: node.variableName,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: node.variableName.length,
            ),
          ),
          declaredVariables: node.declaredVariables,
        );
      }
    } else if (variable.isFinal &&
        // Coverage-ignore(suite): Not run.
        variable.hasDeclaredInitializer) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.cannotAssignToFinalVariable.withArguments(
              variableName: node.variableName,
            ),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: node.variableName.length,
          ),
        ),
        declaredVariables: node.declaredVariables,
      );
    }

    AssignedVariablePatternResult<InvalidExpression> analysisResult =
        analyzeAssignedVariablePattern(context, node, node.variable);

    DartType matchedValueType = analysisResult.matchedValueType
        .unwrapTypeView();
    bool needsCast = _needsCast(
      matchedType: matchedValueType,
      requiredType: node.variable.type,
    );
    bool hasObservableEffect = _inTryOrLocalFunction;

    InvalidExpression? error =
        analysisResult.duplicateAssignmentPatternVariableError ??
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement ??= extern.createInvalidPattern(
        error: error,
        declaredVariables: node.declaredVariables,
      );
    }

    pushRewrite(
      replacement ??
          extern.createAssignedVariablePattern(
            variable: node.variable.astVariable,
            setter: node.variable.lateSetter,
            matchedValueType: matchedValueType,
            needsCast: needsCast,
            hasObservableEffect: hasObservableEffect,
            fileOffset: node.fileOffset,
          ),
    );

    assert(checkStack(node, stackBase, [/* pattern = */ ValueKinds.Pattern]));
    return analysisResult;
  }

  /// Infers type arguments corresponding to [typeParameters] so that, when
  /// substituted into [declaredType], the resulting type matches [contextType].
  List<DartType> _inferTypeArguments({
    required List<TypeParameter> typeParameters,
    required DartType declaredType,
    required DartType contextType,
    required InternalNode? internalNodeForTesting,
  }) {
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typeParameters);
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    declaredType = freshTypeParameters.substitute(declaredType);
    TypeConstraintGatherer gatherer = typeSchemaEnvironment
        .setupGenericTypeInference(
          declaredType,
          typeParametersToInfer,
          contextType,
          inferenceUsingBoundsIsEnabled:
              libraryFeatures.inferenceUsingBounds.isEnabled,
          typeOperations: operations,
          inferenceResultForTesting: dataForTesting
              // Coverage-ignore(suite): Not run.
              ?.typeInferenceResult,
          internalNodeForTesting: internalNodeForTesting,
        );
    return typeSchemaEnvironment.chooseFinalTypes(
      gatherer.computeConstraints(),
      typeParametersToInfer,
      null,
      inferenceUsingBoundsIsEnabled:
          libraryFeatures.inferenceUsingBounds.isEnabled,
      dataForTesting: dataForTesting,
      internalNodeForTesting: internalNodeForTesting,
      typeOperations: operations,
    );
  }

  @override
  SharedTypeView downwardInferObjectPatternRequiredType({
    required SharedTypeView matchedType,
    required covariant InternalObjectPattern pattern,
  }) {
    DartType requiredType = pattern.requiredType;
    if (!pattern.hasExplicitTypeArguments) {
      Typedef? typedef = pattern.typedef;
      if (typedef != null) {
        List<TypeParameter> typedefTypeParameters = typedef.typeParameters;
        if (typedefTypeParameters.isNotEmpty) {
          List<DartType> asTypeArguments = getAsTypeArguments(
            typedefTypeParameters,
            libraryBuilder.library,
          );
          TypedefType typedefType = new TypedefType(
            typedef,
            libraryBuilder.library.nonNullable,
            asTypeArguments,
          );
          DartType unaliasedTypedef = typedefType.unalias;
          List<DartType> inferredTypeArguments = _inferTypeArguments(
            typeParameters: typedefTypeParameters,
            declaredType: unaliasedTypedef,
            contextType: matchedType.unwrapTypeView(),
            internalNodeForTesting: pattern,
          );
          requiredType = new TypedefType(
            typedef,
            libraryBuilder.library.nonNullable,
            inferredTypeArguments,
          ).unalias;
        }
      } else if (requiredType is InterfaceType) {
        List<TypeParameter> typeParameters =
            requiredType.classNode.typeParameters;
        if (typeParameters.isNotEmpty) {
          // It's possible that one of the callee type parameters might match a
          // type that already exists as part of inference.  This might happen,
          // for instance, in the case where a method in a generic class
          // contains an object pattern naming the enclosing class.  To avoid
          // creating invalid inference results, we need to create fresh type
          // parameters.
          FreshTypeParameters fresh = getFreshTypeParameters(typeParameters);
          InterfaceType declaredType = new InterfaceType(
            requiredType.classNode,
            requiredType.declaredNullability,
            fresh.freshTypeArguments,
          );
          typeParameters = fresh.freshTypeParameters;

          List<DartType> inferredTypeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            declaredType: declaredType,
            contextType: matchedType.unwrapTypeView(),
            internalNodeForTesting: pattern,
          );
          requiredType = new InterfaceType(
            requiredType.classNode,
            requiredType.declaredNullability,
            inferredTypeArguments,
          );
        }
      } else if (requiredType is ExtensionType) {
        List<TypeParameter> typeParameters =
            requiredType.extensionTypeDeclaration.typeParameters;
        if (typeParameters.isNotEmpty) {
          // It's possible that one of the callee type parameters might match a
          // type that already exists as part of inference.  This might happen,
          // for instance, in the case where a method in a generic class
          // contains an object pattern naming the enclosing class.  To avoid
          // creating invalid inference results, we need to create fresh type
          // parameters.
          FreshTypeParameters fresh = getFreshTypeParameters(typeParameters);
          ExtensionType declaredType = new ExtensionType(
            requiredType.extensionTypeDeclaration,
            requiredType.declaredNullability,
            fresh.freshTypeArguments,
          );
          typeParameters = fresh.freshTypeParameters;

          List<DartType> inferredTypeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            declaredType: declaredType,
            contextType: matchedType.unwrapTypeView(),
            internalNodeForTesting: pattern,
          );
          requiredType = new ExtensionType(
            requiredType.extensionTypeDeclaration,
            requiredType.declaredNullability,
            inferredTypeArguments,
          );
        }
      }
    }
    return new SharedTypeView(requiredType);
  }

  @override
  void dispatchCollectionElement(InternalNode element, Object? context) {
    context as ElementInferenceContext;
    element as InternalElement;
    pushRewrite(inferElement(element, context));
  }

  @override
  (Member?, SharedTypeView) resolveObjectPatternPropertyGet({
    required InternalPattern objectPattern,
    required SharedTypeView receiverType,
    required shared.RecordPatternField<InternalNode, InternalPattern> field,
  }) {
    String fieldName = field.name!;
    ObjectAccessTarget fieldAccessTarget = findInterfaceMember(
      receiverType.unwrapTypeView(),
      new Name(fieldName, libraryBuilder.library),
      field.pattern.fileOffset,
      isSetter: false,
      includeExtensionMethods: true,
    );
    // TODO(johnniwinther): Should we use the `fieldAccessTarget.classMember`
    //  here?
    return (
      fieldAccessTarget.member,
      new SharedTypeView(fieldAccessTarget.getGetterType(this)),
    );
  }

  @override
  void handleNoCollectionElement(InternalNode element) {
    pushRewrite(NullValues.Expression);
  }

  @override
  void finishJoinedPatternVariable(
    InternalVariable variable, {
    required JoinedPatternVariableLocation location,
    required JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required SharedTypeView type,
  }) {
    variable
      ..isFinal = isFinal
      ..type = type.unwrapTypeView();
  }

  @override
  bool isRestPatternElement(InternalNode node) {
    return node is InternalRestPattern || node is InternalMapPatternRestEntry;
  }

  @override
  InternalPattern? getRestPatternElementPattern(InternalNode node) {
    if (node is InternalMapPatternRestEntry) {
      return null;
    } else {
      return (node as InternalRestPattern).subPattern;
    }
  }

  @override
  void handleListPatternRestElement(
    InternalPattern container,
    InternalNode restElement,
  ) {
    InternalRestPattern restPattern = restElement as InternalRestPattern;
    int? stackBase;
    Pattern? subPattern;
    if (restPattern.subPattern != null) {
      assert(checkStackBase(restPattern, stackBase = stackHeight - 1));

      assert(
        checkStack(restPattern, stackBase, [
          /* subpattern = */ ValueKinds.Pattern,
        ]),
      );

      subPattern = popRewrite() as Pattern;
    } else {
      assert(checkStackBase(restPattern, stackBase = stackHeight));
    }

    assert(checkStack(restPattern, stackBase, [/*empty*/]));

    pushRewrite(
      extern.createRestPattern(
        subPattern: subPattern,
        fileOffset: restPattern.fileOffset,
      ),
    );

    assert(
      checkStack(restPattern, stackBase, [
        /* rest pattern = */ ValueKinds.Pattern,
      ]),
    );
  }

  @override
  void handleMapPatternRestElement(
    InternalPattern container,
    InternalNode restElement,
  ) {
    pushRewrite(
      extern.createMapPatternRestEntry(fileOffset: container.fileOffset),
    );
  }

  @override
  shared.MapPatternEntry<InternalExpression, InternalPattern>?
  getMapPatternEntry(InternalNode element) {
    element as InternalMapPatternEntry;
    if (element is InternalMapPatternRestEntry) {
      return null;
    } else {
      return new shared.MapPatternEntry<InternalExpression, InternalPattern>(
        key: element.key,
        value: element.value,
      );
    }
  }

  @override
  void handleMapPatternEntry(
    InternalPattern container,
    covariant InternalMapPatternEntry entryElement,
    SharedTypeView keyType,
  ) {
    Pattern value = popRewrite() as Pattern;
    Expression key = popRewrite() as Expression;

    pushRewrite(
      extern.createMapPatternEntry(
        key: key,
        keyType: keyType.unwrapTypeView(),
        value: value,
        fileOffset: entryElement.fileOffset,
      ),
    );
  }

  @override
  RelationalOperatorResolution? resolveRelationalPatternOperator(
    covariant InternalRelationalPattern node,
    SharedTypeView matchedValueType,
  ) {
    // TODO(johnniwinther): Reuse computed values between here and
    // visitInternalRelationalPattern.
    Name operatorName;
    RelationalOperatorKind kind = RelationalOperatorKind.other;
    switch (node.kind) {
      case RelationalPatternKind.equals:
        operatorName = equalsName;
        kind = RelationalOperatorKind.equals;
        break;
      case RelationalPatternKind.notEquals:
        operatorName = equalsName;
        kind = RelationalOperatorKind.notEquals;
        break;
      case RelationalPatternKind.lessThan:
        operatorName = lessThanName;
        break;
      case RelationalPatternKind.lessThanEqual:
        operatorName = lessThanOrEqualsName;
        break;
      case RelationalPatternKind.greaterThan:
        operatorName = greaterThanName;
        break;
      case RelationalPatternKind.greaterThanEqual:
        operatorName = greaterThanOrEqualsName;
        break;
    }
    ObjectAccessTarget binaryTarget = findInterfaceMember(
      matchedValueType.unwrapTypeView(),
      operatorName,
      node.fileOffset,
      isSetter: false,
    );

    DartType returnType = binaryTarget.getReturnType(this);
    DartType parameterType = binaryTarget.getBinaryOperandType(this);

    assert(!binaryTarget.isSpecialCasedBinaryOperator(this));

    return new RelationalOperatorResolution(
      kind: kind,
      parameterType: new SharedTypeView(parameterType),
      returnType: new SharedTypeView(returnType),
    );
  }

  bool _isPrivateFromAnotherLibrary(TypeDeclaration typeDeclaration) {
    return switch (typeDeclaration) {
      Class(:var enclosingLibrary) ||
      ExtensionTypeDeclaration(:var enclosingLibrary) =>
        typeDeclaration.name.startsWith('_') &&
            enclosingLibrary != libraryBuilder.library,
    };
  }

  ExpressionInferenceResult visitDotShorthand(
    DotShorthand node,
    DartType typeContext,
  ) {
    DartType rewrittenType = analyzeDotShorthand(
      node.innerExpression,
      new SharedTypeSchemaView(typeContext),
    ).unwrapTypeView();
    Expression rewrittenExpr = popRewrite() as Expression;
    return new ExpressionInferenceResult(rewrittenType, rewrittenExpr);
  }

  ExpressionInferenceResult visitDotShorthandInvocation(
    DotShorthandInvocation node,
    DartType typeContext,
  ) {
    // Use the previously cached context type to determine the declaration
    // member that we're trying to find.
    DartType cachedContext = getDotShorthandContext().unwrapTypeSchemaView();

    // The static namespace denoted by `S` is also the namespace denoted by
    // `FutureOr<S>`.
    while (cachedContext is FutureOrType) {
      cachedContext = cachedContext.typeArgument;
    }

    // If the context type declaration is private and is in a different library,
    // we can't access it with a dot shorthand. This is a compile-time
    // error.
    if (cachedContext is TypeDeclarationType &&
        _isPrivateFromAnotherLibrary(cachedContext.typeDeclaration)) {
      return new ExpressionInferenceResult(
        const DynamicType(),
        extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.dotShorthandsInvalidContext.withArguments(
              dotShorthandName: node.name.text,
            ),
            fileUri: fileUri,
            fileOffset: node.nameOffset,
            length: node.name.text.length,
          ),
        ),
      );
    }

    Member? member = findStaticMember(
      cachedContext,
      node.name,
      node.fileOffset,
    );

    Expression? expr;
    if (member is Procedure && member.kind == ProcedureKind.Method) {
      // The shorthand expression is inferred in the empty context and then type
      // inference infers the type arguments.
      ensureMemberType(member);
      FunctionType functionType = member.function.computeThisFunctionType(
        Nullability.nonNullable,
      );
      InvocationInferenceResult result = inferInvocation(
        this,
        typeContext,
        node.fileOffset,
        new InvocationTargetFunctionType(functionType),
        node.typeArguments,
        node.arguments,
        isConst: node.isConst,
        staticTarget: member,
      );
      expr = new StaticInvocation(
        member,
        createArgumentsFromInternalNode(
          result.typeArguments,
          result.positional,
          result.named,
          node.arguments,
        ),
      )..fileOffset = node.fileOffset;
      return new ExpressionInferenceResult(
        result.inferredType,
        result.applyResult(expr),
      );
    } else if (member == null && cachedContext is TypeDeclarationType) {
      // Couldn't find a static method in the declaration so we'll try and find
      // a constructor of that name instead.
      Member? constructor = findConstructor(
        cachedContext,
        node.name,
        node.fileOffset,
      );

      // Dot shorthand constructor invocations with type parameters
      // `.id<type>()` are not allowed.
      if (constructor != null && node.typeArguments != null) {
        return new ExpressionInferenceResult(
          const DynamicType(),
          extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.dotShorthandsConstructorInvocationWithTypeArguments,
              fileUri: fileUri,
              fileOffset: node.nameOffset,
              length: node.name.text.length,
            ),
          ),
        );
      }

      if (constructor is Constructor) {
        if (!constructor.isConst && node.isConst) {
          return new ExpressionInferenceResult(
            const DynamicType(),
            extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.nonConstConstructor,
                fileUri: fileUri,
                fileOffset: node.nameOffset,
                length: node.name.text.length,
              ),
            ),
          );
        }

        TypeDeclaration typeDeclaration = cachedContext.typeDeclaration;
        if (typeDeclaration is Class && typeDeclaration.isAbstract) {
          return new ExpressionInferenceResult(
            const DynamicType(),
            extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.abstractClassInstantiation.withArguments(
                  name: typeDeclaration.name,
                ),
                fileUri: fileUri,
                fileOffset: node.nameOffset,
                length: node.name.text.length,
              ),
            ),
          );
        }

        // The shorthand expression is inferred in the empty context and then
        // type inference infers the type arguments.
        ensureMemberType(constructor);
        FunctionType functionType = constructor.function
            .computeThisFunctionType(Nullability.nonNullable);
        InvocationInferenceResult result = inferInvocation(
          this,
          typeContext,
          node.fileOffset,
          new InvocationTargetFunctionType(functionType),
          node.typeArguments,
          node.arguments,
          isConst: node.isConst,
          staticTarget: constructor,
        );
        expr = new ConstructorInvocation(
          constructor,
          createArgumentsFromInternalNode(
            result.typeArguments,
            result.positional,
            result.named,
            node.arguments,
          ),
          isConst: node.isConst,
        )..fileOffset = node.fileOffset;
        return new ExpressionInferenceResult(
          result.inferredType,
          result.applyResult(expr),
        );
      } else if (constructor is Procedure) {
        // [constructor] can be a [Procedure] if we have an extension type
        // constructor or a redirecting factory constructor.
        if (!constructor.isConst && node.isConst) {
          // Coverage-ignore-block(suite): Not run.
          return new ExpressionInferenceResult(
            const DynamicType(),
            extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.nonConstConstructor,
                fileUri: fileUri,
                fileOffset: node.nameOffset,
                length: node.name.text.length,
              ),
            ),
          );
        }

        // The shorthand expression is inferred in the empty context and then
        // type inference infers the type arguments.
        ensureMemberType(constructor);
        FunctionType functionType = constructor.function
            .computeThisFunctionType(Nullability.nonNullable);
        InvocationInferenceResult result = inferInvocation(
          this,
          typeContext,
          node.fileOffset,
          new InvocationTargetFunctionType(functionType),
          node.typeArguments,
          node.arguments,
          isConst: node.isConst,
          staticTarget: constructor,
        );
        if (constructor.isRedirectingFactory) {
          expr = _resolveRedirectingFactoryTarget(
            target: constructor,
            explicitOrInferredTypeArguments: result.typeArguments,
            positional: result.positional,
            named: result.named,
            arguments: node.arguments,
            fileOffset: node.fileOffset,
            isConst: node.isConst,
            hasInferredTypeArguments: node.typeArguments == null,
          )!;
        } else {
          expr = new StaticInvocation(
            constructor,
            createArgumentsFromInternalNode(
              result.typeArguments,
              result.positional,
              result.named,
              node.arguments,
            ),
            isConst: node.isConst,
          )..fileOffset = node.fileOffset;
        }
        return new ExpressionInferenceResult(
          result.inferredType,
          result.applyResult(expr),
        );
      }
    }

    if (member != null &&
        (member is Field || (member is Procedure && member.isGetter))) {
      // Try to find a `.call()`.
      DartType receiverType = member.getterType;
      Expression receiver = extern.createStaticGet(
        member,
        fileOffset: node.fileOffset,
      );
      return inferMethodInvocation(
        this,
        node.fileOffset,
        receiver,
        receiverType,
        callName,
        node.typeArguments,
        node.arguments,
        typeContext,
        isExpressionInvocation: true,
        isImplicitCall: true,
        invocationNode: node,
      );
    }

    // Error handling. At this point, we've exhausted all possible valid
    // invocations.
    Expression replacement;
    if (isKnown(cachedContext)) {
      // Error when we can't find the static member or constructor named
      // [node.name] in the declaration of [cachedContext].
      replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.dotShorthandsUndefinedInvocation.withArguments(
            memberName: node.name.text,
            contextType: cachedContext,
          ),
          fileUri: fileUri,
          fileOffset: node.nameOffset,
          length: node.name.text.length,
        ),
      );
    } else {
      // Error when no context type or an invalid context type is given to
      // resolve the dot shorthand.
      //
      // e.g. `var x = .one;`
      replacement = extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.dotShorthandsInvalidContext.withArguments(
            dotShorthandName: node.name.text,
          ),
          fileUri: fileUri,
          fileOffset: node.nameOffset,
          length: node.name.text.length,
        ),
      );
    }
    return new ExpressionInferenceResult(const DynamicType(), replacement);
  }

  ExpressionInferenceResult visitDotShorthandPropertyGet(
    DotShorthandPropertyGet node,
    DartType typeContext,
  ) {
    // Use the previously cached context type to determine the declaration
    // member that we're trying to find.
    DartType cachedContext = getDotShorthandContext().unwrapTypeSchemaView();

    // The static namespace denoted by `S` is also the namespace denoted by
    // `FutureOr<S>`.
    while (cachedContext is FutureOrType) {
      cachedContext = cachedContext.typeArgument;
    }

    // If the context type declaration is private and is in a different library,
    // we can't access it with a dot shorthand. This is a compile-time
    // error.
    if (cachedContext is TypeDeclarationType &&
        _isPrivateFromAnotherLibrary(cachedContext.typeDeclaration)) {
      return new ExpressionInferenceResult(
        const DynamicType(),
        extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.dotShorthandsInvalidContext.withArguments(
              dotShorthandName: node.name.text,
            ),
            fileUri: fileUri,
            fileOffset: node.nameOffset,
            length: node.name.text.length,
          ),
        ),
      );
    }

    Member? member = findStaticMember(
      cachedContext,
      node.name,
      node.fileOffset,
    );
    ExpressionInferenceResult expressionInferenceResult;
    switch (member) {
      case Field():
        expressionInferenceResult = inferStaticGet(
          member: member,
          typeContext: cachedContext,
          nameOffset: node.fileOffset,
          accessNode: node,
        );
      case Procedure():
        if (member.isGetter) {
          expressionInferenceResult = inferStaticGet(
            member: member,
            typeContext: cachedContext,
            nameOffset: node.fileOffset,
            accessNode: node,
          );
        } else {
          // Method tearoffs.
          DartType type = member.function.computeFunctionType(
            Nullability.nonNullable,
          );
          Expression tearOff = extern.createStaticTearOff(
            member,
            fileOffset: node.fileOffset,
          );
          return instantiateTearOff(
            type,
            typeContext,
            tearOff,
            tearOffNode: node,
          );
        }
      case Constructor():
      case null:
        // Handle constructor tearoffs.
        if (cachedContext is TypeDeclarationType) {
          Member? constructor = findConstructor(
            cachedContext,
            node.name,
            node.fileOffset,
            isTearoff: true,
          );
          // Dot shorthand constructor invocations with type parameters
          // `.id<type>()` are not allowed.
          if (constructor != null && node.hasTypeParameters) {
            return new ExpressionInferenceResult(
              const DynamicType(),
              extern.createInvalidExpressionFromErrorText(
                problemReporting.buildProblem(
                  compilerContext: compilerContext,
                  message:
                      diag.dotShorthandsConstructorInvocationWithTypeArguments,
                  fileUri: fileUri,
                  fileOffset: node.nameOffset,
                  length: node.name.text.length,
                ),
              ),
            );
          }
          if (constructor is Constructor) {
            TypeDeclaration typeDeclaration = cachedContext.typeDeclaration;
            if (typeDeclaration is Class && typeDeclaration.isAbstract) {
              return new ExpressionInferenceResult(
                const DynamicType(),
                extern.createInvalidExpressionFromErrorText(
                  problemReporting.buildProblem(
                    compilerContext: compilerContext,
                    message: diag.abstractClassConstructorTearOff,
                    fileUri: fileUri,
                    fileOffset: node.nameOffset,
                    length: node.name.text.length,
                  ),
                ),
              );
            }

            DartType type = constructor.function.computeFunctionType(
              Nullability.nonNullable,
            );
            Expression tearOff = new ConstructorTearOff(constructor)
              ..fileOffset = node.fileOffset;
            return instantiateTearOff(
              type,
              typeContext,
              tearOff,
              tearOffNode: node,
            );
          } else if (constructor is Procedure) {
            DartType type = constructor.function.computeFunctionType(
              Nullability.nonNullable,
            );
            Expression tearOff = new StaticTearOff(constructor)
              ..fileOffset = node.fileOffset;
            return instantiateTearOff(
              type,
              typeContext,
              tearOff,
              tearOffNode: node,
            );
          }
        }

        if (isKnown(cachedContext)) {
          // Error when we can't find the static getter or field [node.name] in
          // the declaration of [cachedContext].
          expressionInferenceResult = new ExpressionInferenceResult(
            const DynamicType(),
            extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.dotShorthandsUndefinedGetter.withArguments(
                  getterName: node.name.text,
                  contextType: cachedContext,
                ),
                fileUri: fileUri,
                fileOffset: node.nameOffset,
                length: node.name.text.length,
              ),
            ),
          );
        } else {
          // Error when no context type or an invalid context type is given to
          // resolve the dot shorthand.
          //
          // e.g. `var x = .one;`
          expressionInferenceResult = new ExpressionInferenceResult(
            const DynamicType(),
            extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.dotShorthandsInvalidContext.withArguments(
                  dotShorthandName: node.name.text,
                ),
                fileUri: fileUri,
                fileOffset: node.nameOffset,
                length: node.name.text.length,
              ),
            ),
          );
        }
    }

    return expressionInferenceResult;
  }

  @override
  bool isDotShorthand(InternalExpression node) {
    return node is DotShorthand;
  }

  List<VariableBase> _capturedVariablesForNode(InternalNode node) {
    List<VariableBase> capturedVariables = [];
    AssignedVariablesNodeInfo nodeInfo = assignedVariables.getInfoForNode(node);
    for (int variableKey in nodeInfo.read) {
      capturedVariables.add(
        assignedVariables.promotionKeyStore
            .variableForKey(variableKey)!
            .astVariable,
      );
    }
    for (int variableKey in nodeInfo.written) {
      capturedVariables.add(
        assignedVariables.promotionKeyStore
            .variableForKey(variableKey)!
            .astVariable,
      );
    }
    return capturedVariables;
  }

  VariableDeclarationInferenceResult _inferInternalVariableDeclaration(
    InternalVariableDeclaration variableDeclaration, {
    required bool forLoopVariable,
  }) {
    InternalDeclaredVariable internalVariable = variableDeclaration.variable;
    DartType declaredType = internalVariable.isImplicitlyTyped
        ? const UnknownType()
        : internalVariable.type;
    DartType inferredType;
    ExpressionInferenceResult? initializerResult;

    // Wildcard variable declarations can be removed, except for the ones in
    // for loops, const variables, and late variables. This logic turns them
    // into `ExpressionStatement`s or `EmptyStatement`s so the backends don't
    // need to allocate space for them.
    if (internalVariable.isWildcard &&
        !internalVariable.isConst &&
        !forLoopVariable) {
      if (variableDeclaration.initializer case var initializer?
          when !internalVariable.isLate) {
        return new VariableDeclarationInferenceResult.effect(
          inferExpression(
            initializer,
            declaredType,
            isVoidAllowed: true,
          ).expression,
        );
      } else {
        return new VariableDeclarationInferenceResult.effect();
      }
    }
    List<VariableContext>? capturedContexts;
    if (variableDeclaration.initializer != null) {
      if (internalVariable.isLate && internalVariable.hasDeclaredInitializer) {
        // TODO(62401): Remove the cast when the flow analysis uses
        // [InternalExpressionVariable]s.
        if (isClosureContextLoweringEnabled) {
          capturedContexts = _contextAllocationStrategy
              .computeCapturedVariableContexts(
                _capturedVariablesForNode(internalVariable),
              );
        }
        flowAnalysis.lateInitializer_begin(internalVariable);
      }
      initializerResult = inferExpression(
        variableDeclaration.initializer!,
        declaredType,
        isVoidAllowed: true,
      );
      if (internalVariable.isLate && internalVariable.hasDeclaredInitializer) {
        flowAnalysis.lateInitializer_end();
      }
      inferredType = inferDeclarationType(
        initializerResult.inferredType,
        forSyntheticVariable: internalVariable.cosmeticName == null,
        inferenceDefaultType: InferenceDefaultType.Dynamic,
      );
    } else {
      inferredType = const DynamicType();
    }
    if (internalVariable.isImplicitlyTyped) {
      if (dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        dataForTesting!
                .typeInferenceResult
                .inferredVariableTypes[internalVariable] =
            inferredType;
      }
      internalVariable.type = inferredType;
    }
    flowAnalysis.declare(
      internalVariable,
      new SharedTypeView(internalVariable.type),
      initialized: internalVariable.hasDeclaredInitializer,
    );
    Expression? initializer;
    if (initializerResult != null) {
      DartType initializerType = initializerResult.inferredType;
      flowAnalysis.initialize(
        internalVariable,
        new SharedTypeView(initializerType),
        getExpressionInfo(initializerResult.expression),
        isFinal: internalVariable.isFinal,
        isLate: internalVariable.isLate,
        isImplicitlyTyped: internalVariable.isImplicitlyTyped,
      );
      initializerResult = ensureAssignableResult(
        internalVariable.type,
        initializerResult,
        fileOffset: internalVariable.fileOffset,
        isVoidAllowed: internalVariable.type is VoidType,
        assignedNode: variableDeclaration.initializer!,
      );
      initializer = initializerResult.expression;
    }
    if (internalVariable.isLate &&
        libraryBuilder.loader.target.backendTarget.isLateLocalLoweringEnabled(
          hasInitializer: internalVariable.hasDeclaredInitializer,
          isFinal: internalVariable.isFinal,
          isPotentiallyNullable: internalVariable.type.isPotentiallyNullable,
        )) {
      return _computeLateLocalLowering(
        internalVariable: internalVariable,
        initializer: initializer,
        capturedContexts: capturedContexts,
        variableDeclarationFileOffset: variableDeclaration.fileOffset,
      );
    } else {
      libraryBuilder.loader.dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.registerExternalNode(internalVariable, internalVariable.astVariable);
      return new VariableDeclarationInferenceResult.direct(
        extern.createVariableDeclaration(
          internalVariable.astVariable,
          initializer: initializer,
          capturedContexts: capturedContexts,
          fileOffset: variableDeclaration.fileOffset,
        ),
      );
    }
  }

  VariableDeclarationInferenceResult _computeLateLocalLowering({
    required InternalDeclaredVariable internalVariable,
    required Expression? initializer,
    required List<VariableContext>? capturedContexts,
    required int variableDeclarationFileOffset,
  }) {
    int fileOffset = internalVariable.fileOffset;

    List<VariableDeclaration> variableDeclarations = [];
    List<FunctionDeclaration> functionDeclarations = [];

    late_lowering.IsSetEncoding isSetEncoding = late_lowering
        .computeIsSetEncoding(
          internalVariable.type,
          late_lowering.computeIsSetStrategy(libraryBuilder),
        );

    Expression? initialValue;
    if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
      initialValue = extern.createStaticInvocation(
        coreTypes.createSentinelMethod,
        extern.createArguments(
          [],
          types: [internalVariable.type],
          fileOffset: fileOffset,
        ),
        fileOffset: fileOffset,
      );
    }

    variableDeclarations.add(
      extern.createVariableDeclaration(
        internalVariable.astVariable,
        initializer: initialValue,
        fileOffset: variableDeclarationFileOffset,
      ),
    );

    DeclaredVariable? isSetVariable;
    if (isSetEncoding == late_lowering.IsSetEncoding.useIsSetField) {
      isSetVariable = extern.createVariable(
        new BoolLiteral(false)..fileOffset = fileOffset,
        coreTypes.boolRawType(Nullability.nonNullable),
        cosmeticName: late_lowering.computeLateLocalIsSetName(
          internalVariable.cosmeticName!,
        ),
        isLowered: true,
        isFinal: false,
        isSynthesized: false,
      );
      variableDeclarations.add(extern.createVariableDeclaration(isSetVariable));
    }

    Expression createVariableRead({bool needsPromotion = false}) {
      if (needsPromotion) {
        return new VariableGet(
          internalVariable.astVariable,
          internalVariable.type,
        )..fileOffset = fileOffset;
      } else {
        return new VariableGet(internalVariable.astVariable)
          ..fileOffset = fileOffset;
      }
    }

    Expression createIsSetRead() =>
        new VariableGet(isSetVariable!)..fileOffset = fileOffset;
    Expression createVariableWrite(Expression value) =>
        new VariableSet(internalVariable.astVariable, value);
    Expression createIsSetWrite(Expression value) =>
        new VariableSet(isSetVariable!, value);

    LocalFunctionVariable getVariable = extern.createLocalFunctionVariable(
      name: late_lowering.computeLateLocalGetterName(
        internalVariable.cosmeticName!,
      ),
      type: const DynamicType(),
      isLowered: true,
      fileOffset: fileOffset,
    );
    FunctionDeclaration getter = new FunctionDeclaration(
      getVariable,
      new FunctionNode(
        initializer == null
            ? late_lowering.createGetterBodyWithoutInitializer(
                coreTypes,
                fileOffset,
                internalVariable.cosmeticName!,
                internalVariable.type,
                createVariableRead: createVariableRead,
                createIsSetRead: createIsSetRead,
                isSetEncoding: isSetEncoding,
                forField: false,
              )
            : (internalVariable.isFinal
                  ? late_lowering.createGetterWithInitializerWithRecheck(
                      coreTypes,
                      fileOffset,
                      internalVariable.cosmeticName!,
                      internalVariable.type,
                      initializer,
                      createVariableRead: createVariableRead,
                      createVariableWrite: createVariableWrite,
                      createIsSetRead: createIsSetRead,
                      createIsSetWrite: createIsSetWrite,
                      isSetEncoding: isSetEncoding,
                      forField: false,
                    )
                  : late_lowering.createGetterWithInitializer(
                      coreTypes,
                      fileOffset,
                      internalVariable.cosmeticName!,
                      internalVariable.type,
                      initializer,
                      createVariableRead: createVariableRead,
                      createVariableWrite: createVariableWrite,
                      createIsSetRead: createIsSetRead,
                      createIsSetWrite: createIsSetWrite,
                      isSetEncoding: isSetEncoding,
                    )),
        returnType: internalVariable.type,
      )..capturedContexts = capturedContexts,
    )..fileOffset = fileOffset;
    getVariable.type = getter.function.computeFunctionType(
      Nullability.nonNullable,
    );
    internalVariable.lateGetter = getVariable;
    functionDeclarations.add(getter);

    bool needsSetter = !internalVariable.isFinal || initializer == null;
    if (needsSetter) {
      internalVariable.isLateFinalWithoutInitializer =
          internalVariable.isFinal && initializer == null;
      LocalFunctionVariable setVariable = extern.createLocalFunctionVariable(
        name: late_lowering.computeLateLocalSetterName(
          internalVariable.cosmeticName!,
        ),
        type: const DynamicType(),
        isLowered: true,
        fileOffset: fileOffset,
      );
      PositionalParameter setterParameter = extern.createPositionalParameter(
        cosmeticName: "${internalVariable.cosmeticName}#param",
        type: internalVariable.type,
        isSynthesized: false,
        fileOffset: fileOffset,
      );
      FunctionDeclaration setter = new FunctionDeclaration(
        setVariable,
        new FunctionNode(
          internalVariable.isFinal
                ? late_lowering.createSetterBodyFinal(
                    coreTypes,
                    fileOffset,
                    internalVariable.cosmeticName!,
                    setterParameter,
                    internalVariable.type,
                    shouldReturnValue: true,
                    createVariableRead: createVariableRead,
                    createVariableWrite: createVariableWrite,
                    createIsSetRead: createIsSetRead,
                    createIsSetWrite: createIsSetWrite,
                    isSetEncoding: isSetEncoding,
                    forField: false,
                  )
                : late_lowering.createSetterBody(
                    coreTypes,
                    fileOffset,
                    internalVariable.cosmeticName!,
                    setterParameter,
                    internalVariable.type,
                    shouldReturnValue: true,
                    createVariableWrite: createVariableWrite,
                    createIsSetWrite: createIsSetWrite,
                    isSetEncoding: isSetEncoding,
                  )
            ..fileOffset = fileOffset,
          positionalParameters: [setterParameter],
        ),
      )
      // TODO(johnniwinther): Reinsert the file offset when the vm doesn't
      //  use it for function declaration identity.
      /*..fileOffset = fileOffset*/;
      setVariable.type = setter.function.computeFunctionType(
        Nullability.nonNullable,
      );
      internalVariable.lateSetter = setVariable;
      functionDeclarations.add(setter);
    }
    internalVariable.isLate = false;
    internalVariable.lateType = internalVariable.type;
    internalVariable.type = computeNullable(internalVariable.type);
    internalVariable.lateName = internalVariable.cosmeticName;
    internalVariable.isLowered = true;
    internalVariable.cosmeticName = late_lowering.computeLateLocalName(
      internalVariable.cosmeticName!,
    );

    return new VariableDeclarationInferenceResult.late(
      variableDeclarations,
      functionDeclarations,
      fileOffset: internalVariable.fileOffset,
    );
  }

  @override
  ScopeProviderInfo beginFieldInference({
    required InternalThisVariable? internalThisVariable,
  }) {
    ScopeProviderInfo scopeProviderInfo = _contextAllocationStrategy
        .enterScopeProvider(
          scopeProviderInfoKind: internalThisVariable == null
              ? ScopeProviderInfoKind.StaticField
              : ScopeProviderInfoKind.InstanceField,
        );
    if (internalThisVariable != null) {
      scopeProviderInfo.thisVariable = internalThisVariable.astVariable;
      _contextAllocationStrategy.handleDeclarationOfVariable(
        internalThisVariable.astVariable,
        captureKind: captureKindForVariable(internalThisVariable),
      );
    }
    return scopeProviderInfo;
  }

  @override
  void endFieldInference(ScopeProviderInfo scopeProviderInfo) {
    _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
  }
}

class _RedirectionTarget {
  final Member target;
  final List<DartType> typeArguments;

  new(this.target, this.typeArguments);
}

class NamedRecordResult({
  required final NamedExpression expression,
  required final DartType type,
});

class ForElementBaseResult({
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final InferredElement body,
  required final List<Expression> updates,
  required final ElementType inferredType,
});
