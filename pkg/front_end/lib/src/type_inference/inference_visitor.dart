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
import 'package:front_end/src/util/local_stack.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/src/non_null.dart';
import 'package:kernel/type_algebra.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/compiler_context.dart';
import '../base/messages.dart';
import '../base/problems.dart'
    as problems
    show internalProblem, unhandled, unimplemented, unsupported;
import '../base/uri_offset.dart';
import '../builder/library_builder.dart';
import '../codes/diagnostic.dart' as diag;
import '../dill/dill_library_builder.dart';
import '../kernel/collections.dart'
    show
        ControlFlowElement,
        ControlFlowMapEntry,
        ForElement,
        ForElementBase,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        ForMapEntryBase,
        IfCaseElement,
        IfCaseMapEntry,
        IfElement,
        IfMapEntry,
        NullAwareElement,
        NullAwareMapEntry,
        PatternForElement,
        PatternForMapEntry,
        SpreadElement,
        SpreadMapEntry;
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/external_ast_helper.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/implicit_type_argument.dart' show ImplicitTypeArgument;
import '../kernel/internal_ast.dart';
import '../kernel/late_lowering.dart' as late_lowering;
import '../source/check_helper.dart';
import '../source/source_library_builder.dart';
import '../util/helpers.dart';
import 'body_inference_context.dart';
import 'context_allocation_strategy.dart';
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
    Expression expression,
    DartType typeContext, {
    bool isVoidAllowed = false,
    bool forEffect = false,
  });

  /// Performs type inference on the given [statement].
  ///
  /// If [bodyContext] is not null, the [statement] is inferred using
  /// [bodyContext] as the current context.
  StatementInferenceResult inferStatement(
    Statement statement, [
    BodyInferenceContext? bodyContext,
  ]);

  /// Performs type inference on the given [initializer].
  InitializerInferenceResult inferInitializer(Initializer initializer);
}

abstract class ReturnContext {}

class StandardReturnContext implements ReturnContext {
  const new();
}

class AnonymousMethodReturnContext extends ReturnContext {
  final Variable resultVariable;
  final LabeledStatement label;
  final List<DartType> returnTypes = [];
  final DartType typeContext;

  new({
    required this.resultVariable,
    required this.label,
    required this.typeContext,
  });
}

class InferenceVisitorImpl extends InferenceVisitorBase
    with
        TypeAnalyzer<
          TreeNode,
          Statement,
          Expression,
          InternalVariable,
          InternalPattern,
          InvalidExpression,
          TypeDeclarationType,
          TypeDeclaration
        >,
        NullShortingMixin<NullAwareGuard, Expression, InternalVariable>,
        StackChecker,
        ExpressionVisitor1ExperimentExclusionMixin<
          ExpressionInferenceResult,
          DartType
        >
    implements
        ExpressionVisitor1<ExpressionInferenceResult, DartType>,
        StatementVisitor<StatementInferenceResult>,
        InitializerVisitor<InitializerInferenceResult>,
        InferenceVisitor {
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
  bool checkStackBase(TreeNode? node, int base) {
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
  bool checkStack(TreeNode? node, int? base, List<ValueKind> kinds) {
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
    required Expression wholeExpression,
  }) {
    ExpressionTypeAnalysisResult analysisResult = super.finishNullShorting(
      targetDepth,
      innerResult,
      wholeExpression: wholeExpression,
    );
    // If any expression info or expression reference was stored for the
    // null-aware expression, it was only valid in the case where the target
    // expression was not null. So it needs to be cleared now.
    flow.storeExpressionInfo(wholeExpression, null);
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
    if (isThisExpression(receiver)) {
      // Null-aware access is not needed on `this`.
      return receiver;
    }
    SyntheticVariable receiverVariable = createVariable(receiver, receiverType);
    createNullAwareGuard(receiverVariable);
    Expression variableGet = createVariableGet(
      receiverVariable,
      promotedType: nonNullReceiverType,
    );

    flowAnalysis.storeExpressionInfo(
      variableGet,
      flowAnalysis.getExpressionInfo(receiver),
    );
    return variableGet;
  }

  void createNullAwareGuard(SyntheticVariable variable) {
    flowAnalysis.storeExpressionInfo(
      variable.initializer!,
      startNullShorting(
        new NullAwareGuard(variable, variable.fileOffset, this),
        flowAnalysis.getExpressionInfo(variable.initializer!),
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
    Statement statement, [
    BodyInferenceContext? bodyContext,
  ]) {
    BodyInferenceContext? oldBodyContext = _bodyContext;
    if (bodyContext != null) {
      _bodyContext = bodyContext;
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
    _bodyContext = oldBodyContext;
    return result;
  }

  ExpressionInferenceResult _inferExpression(
    Expression expression,
    DartType typeContext, {
    bool isVoidAllowed = false,
    bool forEffect = false,
  }) {
    registerIfUnreachableForTesting(expression);

    ExpressionInferenceResult result;
    if (expression is InternalExpression) {
      result = expression.acceptInference(this, typeContext);
    } else {
      result = expression.accept1(this, typeContext);
    }
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
      if (shouldThrowUnsoundnessException &&
          // Coverage-ignore(suite): Not run.
          // Don't throw on expressions that inherently return the bottom type.
          !(result.expression is Throw ||
              result.expression is Rethrow ||
              result.expression is InvalidExpression)) {
        // Coverage-ignore-block(suite): Not run.
        Expression replacement = createLet(
          createVariable(result.expression, result.inferredType),
          createReachabilityError(expression.fileOffset, diag.neverValueError),
        );
        flowAnalysis.storeExpressionInfo(
          replacement,
          flowAnalysis.getExpressionInfo(result.expression),
        );
        result = new ExpressionInferenceResult(
          result.inferredType,
          replacement,
        );
      }
    }
    return result;
  }

  @override
  ExpressionInferenceResult inferExpression(
    Expression expression,
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
      ExpressionInfo? flowAnalysisInfo = flowAnalysis.getExpressionInfo(
        result.expression,
      );
      assert(() {
        // When the AST is rewritten, the front end's convention is to associate
        // flow analysis expression info with the replacement expression, not
        // the original. (Note, however, that it's ok to associate the same info
        // with both expressions.)
        ExpressionInfo? originalFlowAnalysisInfo = flowAnalysis
            .getExpressionInfo(expression);
        assert(
          originalFlowAnalysisInfo == null ||
              identical(flowAnalysisInfo, originalFlowAnalysisInfo),
        );
        return true;
      }());
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
  InitializerInferenceResult inferInitializer(Initializer initializer) {
    InitializerInferenceResult inferenceResult;
    if (initializer is InternalInitializer) {
      inferenceResult = initializer.acceptInference(this);
    } else {
      inferenceResult = initializer.accept(this);
    }
    return inferenceResult;
  }

  // Coverage-ignore(suite): Not run.
  /// Computes uri and offset for [node] for internal errors in a way that is
  /// safe for both top-level and full inference.
  UriOffset _computeUriOffset(TreeNode node) {
    Uri uri = fileUri;
    int fileOffset = node.fileOffset;
    return new UriOffset(uri, fileOffset);
  }

  // Coverage-ignore(suite): Not run.
  Never _unhandledExpression(Expression node, DartType typeContext) {
    UriOffset uriOffset = _computeUriOffset(node);
    problems.unhandled(
      "$node (${node.runtimeType})",
      "InferenceVisitor",
      uriOffset.fileOffset,
      uriOffset.fileUri,
    );
  }

  @override
  ExpressionInferenceResult visitBlockExpression(
    BlockExpression node,
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
    if (bodyResult.hasChanged) {
      node.body = (bodyResult.statement as Block)..parent = node;
    }
    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      const UnknownType(),
      isVoidAllowed: true,
    );
    node.value = valueResult.expression..parent = node;
    if (scopeProviderInfo != null) {
      // Coverage-ignore-block(suite): Not run.
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      node.scope = scopeProviderInfo.scope;
    }
    return new ExpressionInferenceResult(valueResult.inferredType, node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitConstantExpression(
    ConstantExpression node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitDynamicGet(
    DynamicGet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstanceGet(
    InstanceGet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstanceTearOff(
    InstanceTearOff node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitDynamicInvocation(
    DynamicInvocation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitDynamicSet(
    DynamicSet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitEqualsCall(
    EqualsCall node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitEqualsNull(
    EqualsNull node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitFunctionInvocation(
    FunctionInvocation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstanceInvocation(
    InstanceInvocation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstanceGetterInvocation(
    InstanceGetterInvocation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstanceSet(
    InstanceSet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitLocalFunctionInvocation(
    LocalFunctionInvocation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitStaticTearOff(
    StaticTearOff node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    DartType type = node.target.function.computeFunctionType(
      Nullability.nonNullable,
    );
    return instantiateTearOff(type, typeContext, node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitFunctionTearOff(
    FunctionTearOff node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitFileUriExpression(
    FileUriExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      typeContext,
    );
    node.expression = result.expression..parent = node;
    return new ExpressionInferenceResult(result.inferredType, node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstanceCreation(
    InstanceCreation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitConstructorTearOff(
    ConstructorTearOff node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    DartType type = node.target.function!.computeFunctionType(
      Nullability.nonNullable,
    );
    return instantiateTearOff(type, typeContext, node);
  }

  @override
  ExpressionInferenceResult visitRedirectingFactoryTearOff(
    RedirectingFactoryTearOff node,
    DartType typeContext,
  ) {
    ensureMemberType(node.target);
    DartType type = node.target.function.computeFunctionType(
      Nullability.nonNullable,
    );
    return instantiateTearOff(type, typeContext, node);
  }

  @override
  ExpressionInferenceResult visitTypedefTearOff(
    TypedefTearOff node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult expressionResult = inferExpression(
      node.expression,
      const UnknownType(),
      isVoidAllowed: true,
    );
    node.expression = expressionResult.expression..parent = node;
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
    ExpressionInferenceResult inferredResult = instantiateTearOff(
      resultType,
      typeContext,
      node,
    );
    return ensureAssignableResult(typeContext, inferredResult);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRedirectingFactoryInvocation(
    RedirectingFactoryInvocation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitListConcatenation(
    ListConcatenation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitMapConcatenation(
    MapConcatenation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSetConcatenation(
    SetConcatenation node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  // Coverage-ignore(suite): Not run.
  Never _unhandledStatement(Statement node) {
    UriOffset uriOffset = _computeUriOffset(node);
    problems.unhandled(
      "${node.runtimeType}",
      "InferenceVisitor",
      uriOffset.fileOffset,
      uriOffset.fileUri,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitAssertBlock(AssertBlock node) {
    return _unhandledStatement(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitTryCatch(TryCatch node) {
    return _unhandledStatement(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitTryFinally(TryFinally node) {
    return _unhandledStatement(node);
  }

  // Coverage-ignore(suite): Not run.
  Never _unhandledInitializer(Initializer node) {
    problems.unhandled(
      "${node.runtimeType}",
      "InferenceVisitor",
      node.fileOffset,
      fileUri,
    );
  }

  @override
  InitializerInferenceResult visitInvalidInitializer(InvalidInitializer node) {
    return new SuccessfulInitializerInferenceResult(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InitializerInferenceResult visitLocalInitializer(LocalInitializer node) {
    _unhandledInitializer(node);
  }

  @override
  ExpressionInferenceResult visitInvalidExpression(
    InvalidExpression node,
    DartType typeContext,
  ) {
    if (node.expression != null) {
      ExpressionInferenceResult result = inferExpression(
        node.expression!,
        typeContext,
        isVoidAllowed: true,
      );
      node.expression = result.expression..parent = node;
    }
    return new ExpressionInferenceResult(const InvalidType(), node);
  }

  @override
  ExpressionInferenceResult visitInstantiation(
    Instantiation node,
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
          break;
      }
    }
    node.expression = operand..parent = node;
    Expression result = node;
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
          result = problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.instantiationNullableGenericFunctionType
                .withArguments(operandType: operandType),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: noLength,
          );
        } else {
          resultType = FunctionTypeInstantiator.instantiate(
            operandType,
            node.typeArguments,
          );
        }
      } else {
        if (operandType.typeParameters.isEmpty) {
          result = problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.instantiationNonGenericFunctionType.withArguments(
              operandType: operandType,
            ),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: noLength,
          );
        } else if (operandType.typeParameters.length >
            node.typeArguments.length) {
          result = problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.instantiationTooFewArguments.withArguments(
              expectedCount: operandType.typeParameters.length,
              actualCount: node.typeArguments.length,
            ),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: noLength,
          );
        } else if (operandType.typeParameters.length <
            node.typeArguments.length) {
          result = problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.instantiationTooManyArguments.withArguments(
              expectedCount: operandType.typeParameters.length,
              actualCount: node.typeArguments.length,
            ),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: noLength,
          );
        }
      }
    } else if (operandType is! InvalidType) {
      result = problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.instantiationNonGenericFunctionType.withArguments(
          operandType: operandType,
        ),
        fileUri: fileUri,
        fileOffset: node.fileOffset,
        length: noLength,
      );
    }
    return new ExpressionInferenceResult(resultType, result);
  }

  @override
  ExpressionInferenceResult visitIntLiteral(
    IntLiteral node,
    DartType typeContext,
  ) {
    return new ExpressionInferenceResult(
      coreTypes.intRawType(Nullability.nonNullable),
      node,
    );
  }

  @override
  ExpressionInferenceResult visitAsExpression(
    AsExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      const UnknownType(),
      isVoidAllowed: true,
    );
    node.operand = operandResult.expression..parent = node;
    flowAnalysis.asExpression_end(
      flowAnalysis.getExpressionInfo(node.operand),
      subExpressionType: new SharedTypeView(operandResult.inferredType),
      castType: new SharedTypeView(node.type),
    );
    return new ExpressionInferenceResult(node.type, node);
  }

  @override
  InitializerInferenceResult visitAssertInitializer(AssertInitializer node) {
    StatementInferenceResult result = inferStatement(node.statement);
    if (result.hasChanged) {
      // Coverage-ignore-block(suite): Not run.
      node.statement = (result.statement as AssertStatement)..parent = node;
    }
    return new SuccessfulInitializerInferenceResult(node);
  }

  @override
  StatementInferenceResult visitAssertStatement(AssertStatement node) {
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
    ).expression;
    node.condition = condition..parent = node;
    flowAnalysis.assert_afterCondition(
      flowAnalysis.getExpressionInfo(node.condition),
    );
    if (node.message != null) {
      ExpressionInferenceResult codeResult = inferExpression(
        node.message!,
        const UnknownType(),
        isVoidAllowed: true,
      );
      node.message = codeResult.expression..parent = node;
    }
    flowAnalysis.assert_end();
    return const StatementInferenceResult();
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

  @override
  ExpressionInferenceResult visitAwaitExpression(
    AwaitExpression node,
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
      operandRewrite = problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: wrapped,
        message: diag.awaitOfExtensionTypeNotFuture,
        fileUri: fileUri,
        fileOffset: wrapped.fileOffset,
        length: 1,
      );
      wrapped.parent = operandRewrite;
    }
    node.operand = operandRewrite..parent = node;
    DartType runtimeCheckType = new InterfaceType(
      coreTypes.futureClass,
      Nullability.nonNullable,
      [flattenType],
    );
    if (!typeSchemaEnvironment.isSubtypeOf(operandType, runtimeCheckType)) {
      node.runtimeCheckType = runtimeCheckType;
    }
    return new ExpressionInferenceResult(flattenType, node);
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
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Block,
      );
    }
    registerIfUnreachableForTesting(node);
    List<Statement>? result = _visitStatements<Statement>(node.statements);
    StatementInferenceResult statementInferenceResult;
    Block replacement = node;
    if (result != null) {
      Block block = replacement = extern.createBlock(
        result,
        fileOffset: node.fileOffset,
        fileEndOffset: node.fileEndOffset,
      );
      libraryBuilder.loader.dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.registerAlias(node, block);
      statementInferenceResult = new StatementInferenceResult.single(block);
    } else {
      statementInferenceResult = const StatementInferenceResult();
    }
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      replacement.scope = scopeProviderInfo.scope;
    }
    return statementInferenceResult;
  }

  @override
  ExpressionInferenceResult visitBoolLiteral(
    BoolLiteral node,
    DartType typeContext,
  ) {
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.booleanLiteral(node.value),
    );
    return new ExpressionInferenceResult(
      coreTypes.boolRawType(Nullability.nonNullable),
      node,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitBreakStatement(BreakStatement node) {
    _unhandledStatement(node);
  }

  StatementInferenceResult visitInternalBreakStatement(
    InternalBreakStatement node,
  ) {
    flowAnalysis.handleBreak(node.targetStatement);
    return new StatementInferenceResult.single(
      extern.createBreakStatement(node.target, fileOffset: node.fileOffset),
    );
  }

  StatementInferenceResult visitInternalContinueStatement(
    InternalContinueStatement node,
  ) {
    flowAnalysis.handleContinue(node.targetStatement);
    return new StatementInferenceResult.single(
      extern.createBreakStatement(node.target, fileOffset: node.fileOffset),
    );
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result = inferExpression(
      node.variable.astVariable.initializer!,
      typeContext,
      isVoidAllowed: false,
    );

    node.variable.astVariable.initializer = result.expression
      ..parent = node.variable.astVariable;
    node.variable.type = result.inferredType;
    NullAwareGuard? nullAwareGuard;
    if (node.isNullAware) {
      nullAwareGuard = new NullAwareGuard(
        node.variable.astVariable,
        node.variable.fileOffset,
        this,
      );
    }
    flowAnalysis.cascadeExpression_afterTarget(
      flowAnalysis.getExpressionInfo(result.expression),
      new SharedTypeView(result.inferredType),
      isNullAware: node.isNullAware,
      guardVariable: node.variable,
    );

    Cascade? previousEnclosingCascade = _enclosingCascade;
    _enclosingCascade = node;
    List<ExpressionInferenceResult> expressionResults =
        <ExpressionInferenceResult>[];
    for (Expression expression in node.expressions) {
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
      createVariableGet(node.variable.astVariable),
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
      replacement = new Let(node.variable.astVariable, replacement)
        ..fileOffset = node.fileOffset;
    }
    flowAnalysis.storeExpressionInfo(
      replacement,
      flowAnalysis.cascadeExpression_end(),
    );
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  PropertyTarget<Expression> computePropertyTarget(Expression target) {
    if (_enclosingCascade case Cascade(:var variable)
        when target is VariableGet && target.variable == variable.astVariable) {
      // `target` is an implicit reference to the target of a cascade
      // expression; flow analysis uses `CascadePropertyTarget` to represent
      // this situation.
      return CascadePropertyTarget.singleton;
    } else {
      // `target` is an ordinary expression.
      return new ExpressionPropertyTarget(flow.getExpressionInfo(target));
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

  @override
  ExpressionInferenceResult visitConditionalExpression(
    ConditionalExpression node,
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
    ).expression;
    node.condition = condition..parent = node;
    flowAnalysis.conditional_thenBegin(
      flowAnalysis.getExpressionInfo(node.condition),
      node,
    );
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
    node.then = thenResult.expression..parent = node;
    registerIfUnreachableForTesting(node.then, isReachable: isThenReachable);
    DartType t1 = thenResult.inferredType;

    // - Let `T2` be the type of `e2` inferred with context type `K`
    flowAnalysis.conditional_elseBegin(
      flowAnalysis.getExpressionInfo(node.then),
      new SharedTypeView(thenResult.inferredType),
    );
    bool isOtherwiseReachable = flowAnalysis.isReachable;
    ExpressionInferenceResult otherwiseResult = inferExpression(
      node.otherwise,
      typeContext,
      isVoidAllowed: true,
    );
    node.otherwise = otherwiseResult.expression..parent = node;
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

    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.conditional_end(
        new SharedTypeView(inferredType),
        flowAnalysis.getExpressionInfo(node.otherwise),
        new SharedTypeView(otherwiseResult.inferredType),
      ),
    );
    node.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitConstructorInvocation(
    ConstructorInvocation node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    Expression replacement = createConstructorInvocation(
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

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitContinueSwitchStatement(
    ContinueSwitchStatement node,
  ) {
    _unhandledStatement(node);
  }

  StatementInferenceResult visitInternalContinueSwitchStatement(
    InternalContinueSwitchStatement node,
  ) {
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    StaticInvocation replacement = createStaticInvocation(
      node.tearOff,
      new Arguments([receiver], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    return instantiateTearOff(
      target.getReturnType(this),
      typeContext,
      replacement,
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    DartType resultType = target.getGetterType(this);

    StaticInvocation replacement = createStaticInvocation(
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
      nodeForTesting: node,
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
    required Expression receiver,
    required int? extensionTypeArgumentOffset,
    required Procedure setter,
    required bool isNullAware,
    required int fileOffset,
    TreeNode? nodeForTesting,
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

    receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
        receiverType,
        nonNullReceiverType,
      );
      receiverType = nonNullReceiverType;
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      extension,
      knownTypeArguments,
      receiverType,
      treeNodeForTesting: nodeForTesting,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    DartType valueType = target.getSetterType(this);
    return new ExtensionSetData(
      receiver: receiver,
      inferredReceiverType: receiverResult.inferredType,
      valueType: valueType,
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
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
    if (forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
    }

    SyntheticVariable? receiverVariable;
    if (forEffect || isPureExpression(receiver)) {
      // No need for receiver variable.
    } else {
      receiverVariable = createVariable(receiver, data.inferredReceiverType);
      receiver = createVariableGet(receiverVariable);
    }

    StaticInvocation assignment = createStaticInvocation(
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
      SyntheticVariable assignmentVariable = createVariable(
        assignment,
        const VoidType(),
      );
      replacement = createLet(
        valueVariable!,
        createLet(assignmentVariable, createVariableGet(valueVariable)),
      );
      if (receiverVariable != null) {
        replacement = createLet(receiverVariable, replacement);
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
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

    StaticInvocation read = createStaticInvocation(
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
      valueVariable = createVariable(value, valueType);
      value = createVariableGet(valueVariable);
    }

    ExpressionInferenceResult binaryResult = _computeBinaryExpression(
      node.fileOffset,
      valueType,
      value,
      readType,
      node.isInc ? plusName : minusName,
      createIntLiteral(coreTypes, 1, fileOffset: node.fileOffset),
      null,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      isVoidAllowed: true,
    );
    DartType binaryType = binaryResult.inferredType;
    Expression binary = binaryResult.expression;

    SyntheticVariable? binaryVariable;
    if (!node.forEffect && !node.isPost) {
      // For prefix expressions like `a = ++E(o).b` we need to store the binary
      // result as the result after assignment.
      binaryVariable = createVariable(binary, binaryType);
      binary = createVariableGet(binaryVariable);
    }

    StaticInvocation write = createStaticInvocation(
      node.setter,
      new Arguments([writeReceiver, binary], types: extensionTypeArguments)
        ..fileOffset = node.fileOffset,
      fileOffset: node.fileOffset,
    );

    Expression replacement;
    if (valueVariable != null) {
      assert(binaryVariable == null);
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable,
        createLet(writeVariable, createVariableGet(valueVariable)),
      );
    } else if (binaryVariable != null) {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        binaryVariable,
        createLet(writeVariable, createVariableGet(binaryVariable)),
      );
    } else {
      replacement = write;
    }
    if (receiverVariable != null) {
      replacement = createLet(receiverVariable, replacement);
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    DartType getterType = target.getGetterType(this);

    StaticInvocation getterAccess = createStaticInvocation(
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
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
      receiverVariable = createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = nonNullReceiverType;
    } else if (!isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
    }

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
      node.extension,
      node.knownTypeArguments,
      receiverType,
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    Expression readReceiver;
    Expression writeReceiver;
    if (receiverVariable != null) {
      readReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    } else {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    }

    ExpressionInferenceResult readResult = _computePropertyGet(
      node.readOffset,
      readReceiver,
      receiverType,
      node.propertyName,
      const UnknownType(),
      isThisReceiver: isThisExpression(node.receiver),
    ).expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    flowAnalysis.ifNullExpression_rightBegin(
      flowAnalysis.getExpressionInfo(read),
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
      Expression equalsNull = createEqualsNull(
        read,
        fileOffset: node.fileOffset,
      );
      replacement = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        write,
        new NullLiteral()..fileOffset = node.fileOffset,
        computeNullable(inferredType),
      );
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      SyntheticVariable readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(
        createVariableGet(readVariable),
        fileOffset: node.fileOffset,
      );
      VariableGet variableGet = createVariableGet(readVariable);
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
      replacement = createLet(readVariable, conditional);
    }
    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = createLet(receiverVariable, replacement);
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
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
      node.binaryOffset,
      valueType,
      read,
      readType,
      node.binaryName,
      node.rhs,
      null,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      isVoidAllowed: true,
    );
    Expression value = binaryResult.expression;

    SyntheticVariable? valueVariable;
    if (node.forEffect) {
      // No need for value variable.
    } else {
      valueVariable = createVariable(value, valueType);
      value = createVariableGet(valueVariable);
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
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable!,
        createLet(writeVariable, createVariableGet(valueVariable)),
      );
    }
    if (receiverVariable != null) {
      replacement = createLet(receiverVariable, replacement);
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

    Expression replacement = new Let(
      node.variable.astVariable,
      result.expression,
    )..fileOffset = node.fileOffset;
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
    InterfaceType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      node.condition,
      boolType,
      isVoidAllowed: true,
    );
    Expression condition = ensureAssignableResult(
      boolType,
      conditionResult,
    ).expression;
    node.condition = condition..parent = node;
    flowAnalysis.doStatement_end(flowAnalysis.getExpressionInfo(condition));
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitDoubleLiteral(
    DoubleLiteral node,
    DartType typeContext,
  ) {
    return new ExpressionInferenceResult(
      coreTypes.doubleRawType(Nullability.nonNullable),
      node,
    );
  }

  @override
  StatementInferenceResult visitEmptyStatement(EmptyStatement node) {
    // No inference needs to be done.
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitExpressionStatement(ExpressionStatement node) {
    ExpressionInferenceResult result = inferExpression(
      node.expression,
      const UnknownType(),
      isVoidAllowed: true,
      forEffect: true,
    );
    node.expression = result.expression..parent = node;
    return const StatementInferenceResult();
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
    node.hasBeenInferred = true;
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
    Expression? result = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: effectiveTarget,
      explicitTypeArguments: null,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: fileUri,
    );
    if (result != null) {
      return result;
    }
    if (effectiveTarget is Constructor) {
      if (isConst && !effectiveTarget.isConst) {
        // Coverage-ignore-block(suite): Not run.
        return problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nonConstConstructor,
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: noLength,
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
          return problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonConstConstructor,
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: noLength,
          );
        } else {
          return problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonConstFactory,
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: noLength,
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
    node.hasBeenInferred = true;

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

    node.hasBeenInferred = true;
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

  @override
  InitializerInferenceResult visitFieldInitializer(FieldInitializer node) {
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
    ).expression;
    node.value = initializer..parent = node;
    return new SuccessfulInitializerInferenceResult(node);
  }

  @override
  ExpressionInferenceResult inferForInIterable(
    Expression iterable,
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
    iterable = iterableResult.expression;
    DartType inferredExpressionType = iterableType.nonTypeParameterBound;
    iterable = ensureAssignable(
      wrapType(const DynamicType(), iterableClass, Nullability.nonNullable),
      inferredExpressionType,
      iterable,
      errorTemplate: diag.forInLoopTypeNotIterable,
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
    return new ExpressionInferenceResult(inferredType, iterable);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitForInStatement(ForInStatement node) {
    return _unhandledStatement(node);
  }

  @override
  PatternForInData inferPatternForInHeader({
    required TreeNode node,
    required InternalPattern pattern,
    required Expression iterable,
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

    Object? rewrite = popRewrite();
    if (!identical(rewrite, iterable)) {
      iterable = rewrite as Expression;
    }

    DartType elementType = result.elementType.unwrapTypeView();
    iterable = ensureAssignable(
      wrapType(
        const DynamicType(),
        isAsync ? coreTypes.streamClass : coreTypes.iterableClass,
        Nullability.nonNullable,
      ),
      result.expressionType.unwrapTypeView(),
      iterable,
      errorTemplate: diag.forInLoopTypeNotIterable,
    );

    Variable loopVariable = extern.createUninitializedVariable(
      type: elementType,
      fileOffset: node.fileOffset,
      isFinal: true,
    );

    return new PatternForInData(
      loopVariable: loopVariable,
      iterable: iterable,
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
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
    Variable variable = headerResult.loopVariable;
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
          captureKind: _captureKindForVariable(declaredVariable),
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

    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
    Statement? bodyPrologue = encoding.bodyPrologue;
    if (bodyPrologue != null) {
      body = combineStatements(bodyPrologue, body);
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
    InvalidExpression? preLoopError = encoding.preLoopError;
    if (preLoopError != null) {
      result = createBlock([
        createExpressionStatement(preLoopError),
        forInStatement,
      ], fileOffset: node.fileOffset);
    }
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, forInStatement);
    return new StatementInferenceResult.single(result);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitForStatement(ForStatement node) {
    _unhandledStatement(node);
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
      InternalVariable variable = variableDeclaration.variable;
      if (variable.cosmeticName == null) {
        if (variable.astVariable.initializer != null) {
          ExpressionInferenceResult result = inferExpression(
            variable.astVariable.initializer!,
            const UnknownType(),
            isVoidAllowed: true,
          );
          variable.astVariable.initializer = result.expression
            ..parent = variable;
          variable.type = result.inferredType;
        }
        variables[index] = extern.createVariableDeclaration(
          variable.astVariable,
          fileOffset: variableDeclaration.fileOffset,
        );
      } else {
        VariableDeclarationInferenceResult variableResult =
            inferVariableDeclaration(variableDeclaration);
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
      ).expression;
    }

    flowAnalysis.for_bodyBegin(node, switch (condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => flowAnalysis.getExpressionInfo(condition),
    });
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
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
    ?.registerAlias(node, replacement);
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

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitFunctionDeclaration(FunctionDeclaration node) {
    return _unhandledStatement(node);
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
        captureKind: _captureKindForVariable(node.variable),
      );
      capturedContexts = _contextAllocationStrategy
          .computeCapturedVariableContexts(_capturedVariablesForNode(node));
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
      _handleDeclarationsOfParameters([
        ...node.function.positionalParameters,
        ...node.function.namedParameters,
      ]);
    }

    bool oldInTryOrLocalFunction = _inTryOrLocalFunction;
    _inTryOrLocalFunction = true;
    InternalVariable variable = node.variable;
    flowAnalysis.functionExpression_begin(node);
    _returnContexts.push(const StandardReturnContext());
    inferMetadata(this, variable.astVariable);
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
    ?.registerAlias(variable, variable.astVariable);
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  @override
  ScopeProviderInfo beginClosureContextAllocation(
    List<InternalVariable> parameters, {
    required InternalThisVariable? internalThisVariable,
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    scopeProviderInfo ??= _contextAllocationStrategy.enterScopeProvider(
      scopeProviderInfoKind: internalThisVariable == null
          ? ScopeProviderInfoKind.FunctionNode
          : ScopeProviderInfoKind.FunctionNodeWithThis,
    )..thisVariable = internalThisVariable?.astVariable;
    if (internalThisVariable != null) {
      _contextAllocationStrategy.handleDeclarationOfVariable(
        internalThisVariable.astVariable,
        captureKind: _captureKindForVariable(internalThisVariable),
      );
    }
    _handleDeclarationsOfParameters(parameters);
    return scopeProviderInfo;
  }

  @override
  void endClosureContextAllocation(ScopeProviderInfo scopeProviderInfo) {
    _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
  }

  void _handleDeclarationsOfParameters(List<InternalVariable> parameters) {
    for (InternalVariable parameter in parameters) {
      _contextAllocationStrategy.handleDeclarationOfVariable(
        parameter.astVariable,
        captureKind: _captureKindForVariable(parameter),
      );
    }
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
      _handleDeclarationsOfParameters([
        ...function.positionalParameters,
        ...function.namedParameters,
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
    ?.registerAlias(node, replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitFunctionExpression(
    FunctionExpression node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
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
      flowAnalysis.getExpressionInfo(left),
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
    if (isThisExpression(left)) {
      replacement = left;
    } else {
      SyntheticVariable variable = createVariable(left, t1);
      Expression equalsNull = createEqualsNull(
        createVariableGet(variable),
        fileOffset: lhsResult.expression.fileOffset,
      );
      VariableGet variableGet = createVariableGet(variable);
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
      replacement = new Let(variable, conditional)
        ..fileOffset = node.fileOffset;
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  StatementInferenceResult visitIfStatement(IfStatement node) {
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
    ).expression;
    node.condition = condition..parent = node;
    flowAnalysis.ifStatement_thenBegin(
      flowAnalysis.getExpressionInfo(condition),
      node,
    );
    StatementInferenceResult thenResult = inferStatement(node.then);
    if (thenResult.hasChanged) {
      node.then = thenResult.statement..parent = node;
    }
    if (node.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      StatementInferenceResult otherwiseResult = inferStatement(
        node.otherwise!,
      );
      if (otherwiseResult.hasChanged) {
        node.otherwise = otherwiseResult.statement..parent = node;
      }
    }
    flowAnalysis.ifStatement_end(node.otherwise != null);
    return const StatementInferenceResult();
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitIfCaseStatement(IfCaseStatement node) {
    _unhandledStatement(node);
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

    Statement? otherwise = node.otherwise;
    Object? rewrite = popRewrite(NullValues.Statement);
    if (!identical(node.otherwise, rewrite)) {
      otherwise = rewrite as Statement;
    }
    Statement then = node.then;
    rewrite = popRewrite();
    if (!identical(node.then, rewrite)) {
      then = rewrite as Statement;
    }
    Expression? guard = rewrite =
        popRewrite(NullValues.Expression) as Expression?;
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
        patternGuard: createPatternGuard(
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
    ?.registerAlias(node, result);
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
        ?.registerAlias(node, replacement);
        return new ExpressionInferenceResult(inferredType, replacement);
      }
    }

    int? intValue = node.asInt64();
    if (intValue == null) {
      Expression replacement = problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.integerLiteralIsOutOfRange.withArguments(
          literal: node.literal,
        ),
        fileUri: fileUri,
        fileOffset: node.fileOffset,
        length: node.literal.length,
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
    ?.registerAlias(node, replacement);
    DartType inferredType = coreTypes.intRawType(Nullability.nonNullable);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  ExpressionInferenceResult visitIsExpression(
    IsExpression node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      const UnknownType(),
      isVoidAllowed: false,
    );
    node.operand = operandResult.expression..parent = node;
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.isExpression_end(
        flowAnalysis.getExpressionInfo(node.operand),
        /*isNot:*/ false,
        subExpressionType: new SharedTypeView(operandResult.inferredType),
        checkedType: new SharedTypeView(node.type),
      ),
    );
    return new ExpressionInferenceResult(
      coreTypes.boolRawType(Nullability.nonNullable),
      node,
    );
  }

  @override
  StatementInferenceResult visitLabeledStatement(LabeledStatement node) {
    flowAnalysis.labeledStatement_begin(node);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    flowAnalysis.labeledStatement_end();
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    return const StatementInferenceResult();
  }

  DartType? getSpreadElementType(
    DartType spreadType,
    DartType spreadTypeBound,
    bool isNullAware,
  ) {
    if (coreTypes.isNull(spreadTypeBound)) {
      return isNullAware ? const NeverType.nonNullable() : null;
    }
    if (spreadTypeBound is TypeDeclarationType) {
      List<DartType>? supertypeArguments = typeSchemaEnvironment
          .getTypeArgumentsAsInstanceOf(
            spreadTypeBound,
            coreTypes.iterableClass,
          );
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

  ExpressionInferenceResult _inferSpreadElement(
    SpreadElement element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    ExpressionInferenceResult spreadResult = inferExpression(
      element.expression,
      new InterfaceType(
        coreTypes.iterableClass,
        element.isNullAware ? Nullability.nullable : Nullability.nonNullable,
        <DartType>[inferredTypeArgument],
      ),
      isVoidAllowed: true,
    );
    element.expression = spreadResult.expression..parent = element;
    DartType spreadType = spreadResult.inferredType;
    inferredSpreadTypes[element.expression] = spreadType;
    Expression replacement = element;
    DartType spreadTypeBound = spreadType.nonTypeParameterBound;
    DartType? spreadElementType = getSpreadElementType(
      spreadType,
      spreadTypeBound,
      element.isNullAware,
    );
    if (spreadElementType == null) {
      if (coreTypes.isNull(spreadTypeBound) && !element.isNullAware) {
        replacement = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nonNullAwareSpreadIsNull.withArguments(
            spreadType: spreadType,
          ),
          fileUri: fileUri,
          fileOffset: element.expression.fileOffset,
          length: 1,
        );
      } else {
        if (spreadType.isPotentiallyNullable &&
            spreadType is! DynamicType &&
            spreadType is! NullType &&
            !element.isNullAware) {
          Expression receiver = element.expression;
          replacement = problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nullableSpreadError,
            fileUri: fileUri,
            fileOffset: receiver.fileOffset,
            length: 1,
            context: getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(
                flowAnalysis.getExpressionInfo(receiver),
              )(),
              element,
              // Coverage-ignore(suite): Not run.
              (type) => !type.isPotentiallyNullable,
            ),
          );
        }

        replacement = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.spreadTypeMismatch.withArguments(
            spreadType: spreadType,
          ),
          fileUri: fileUri,
          fileOffset: element.expression.fileOffset,
          length: 1,
        );
        _copyNonPromotionReasonToReplacement(element, replacement);
      }
    } else if (spreadTypeBound is InterfaceType) {
      if (!isAssignable(inferredTypeArgument, spreadElementType)) {
        replacement = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.spreadElementTypeMismatch.withArguments(
            spreadElementType: spreadElementType,
            collectionElementType: inferredTypeArgument,
          ),
          fileUri: fileUri,
          fileOffset: element.expression.fileOffset,
          length: 1,
        );
      }
      if (spreadType.isPotentiallyNullable &&
          spreadType is! DynamicType &&
          spreadType is! NullType &&
          !element.isNullAware) {
        Expression receiver = element.expression;
        replacement = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nullableSpreadError,
          fileUri: fileUri,
          fileOffset: receiver.fileOffset,
          length: 1,
          context: getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(
              flowAnalysis.getExpressionInfo(receiver),
            )(),
            element,
            // Coverage-ignore(suite): Not run.
            (type) => !type.isPotentiallyNullable,
          ),
        );
        _copyNonPromotionReasonToReplacement(element, replacement);
      }
    }

    // Use 'dynamic' for error recovery.
    element.elementType = spreadElementType ?? const DynamicType();
    return new ExpressionInferenceResult(element.elementType!, replacement);
  }

  ExpressionInferenceResult _inferNullAwareElement(
    NullAwareElement element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    ExpressionInferenceResult expressionResult = inferElement(
      element.expression,
      inferredTypeArgument.withDeclaredNullability(Nullability.nullable),
      inferredSpreadTypes,
      inferredConditionTypes,
    );
    element.expression = expressionResult.expression..parent = element;

    return new ExpressionInferenceResult(
      computeNonNull(expressionResult.inferredType),
      element,
    );
  }

  ExpressionInferenceResult _inferIfElement(
    IfElement element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    flowAnalysis.ifStatement_conditionBegin();
    DartType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      element.condition,
      boolType,
      isVoidAllowed: false,
    );
    Expression condition = ensureAssignableResult(
      boolType,
      conditionResult,
    ).expression;
    element.condition = condition..parent = element;
    flowAnalysis.ifStatement_thenBegin(
      flowAnalysis.getExpressionInfo(condition),
      element,
    );
    ExpressionInferenceResult thenResult = inferElement(
      element.then,
      inferredTypeArgument,
      inferredSpreadTypes,
      inferredConditionTypes,
    );
    element.then = thenResult.expression..parent = element;
    ExpressionInferenceResult? otherwiseResult;
    if (element.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      otherwiseResult = inferElement(
        element.otherwise!,
        inferredTypeArgument,
        inferredSpreadTypes,
        inferredConditionTypes,
      );
      element.otherwise = otherwiseResult.expression..parent = element;
    }
    flowAnalysis.ifStatement_end(element.otherwise != null);
    return new ExpressionInferenceResult(
      otherwiseResult == null
          ? thenResult.inferredType
          : typeSchemaEnvironment.getStandardUpperBound(
              thenResult.inferredType,
              otherwiseResult.inferredType,
            ),
      element,
    );
  }

  ExpressionInferenceResult _inferIfCaseElement(
    IfCaseElement element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    int? stackBase;
    assert(checkStackBase(element, stackBase = stackHeight));

    ListAndSetElementInferenceContext context =
        new ListAndSetElementInferenceContext(
          inferredTypeArgument: inferredTypeArgument,
          inferredSpreadTypes: inferredSpreadTypes,
          inferredConditionTypes: inferredConditionTypes,
        );
    IfCaseStatementResult<InvalidExpression> analysisResult =
        analyzeIfCaseElement(
          node: element,
          expression: element.expression,
          pattern: element.internalPatternGuard.pattern,
          variables: {
            for (InternalVariable variable
                in element.internalPatternGuard.pattern.declaredVariables)
              variable.cosmeticName!: variable,
          },
          guard: element.internalPatternGuard.guard,
          ifTrue: element.then,
          ifFalse: element.otherwise,
          context: context,
        );

    element.matchedValueType = analysisResult.matchedExpressionType
        .unwrapTypeView();

    assert(
      checkStack(element, stackBase, [
        /* ifFalse = */ ValueKinds.ExpressionOrNull,
        /* ifTrue = */ ValueKinds.Expression,
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern = */ ValueKinds.Pattern,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    Object? rewrite = popRewrite(NullValues.Expression);
    if (!identical(element.otherwise, rewrite)) {
      element.otherwise = (rewrite as Expression?)?..parent = element;
    }

    rewrite = popRewrite();
    if (!identical(element.then, rewrite)) {
      element.then = (rewrite as Expression)..parent = element;
    }

    InternalPatternGuard patternGuard = element.internalPatternGuard;
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
    rewrite = popRewrite();
    if (!identical(element.expression, rewrite)) {
      element.expression = (rewrite as Expression)..parent = patternGuard;
    }

    element.patternGuard = extern.createPatternGuard(
      pattern: pattern,
      guard: guard,
      fileOffset: patternGuard.fileOffset,
    );

    DartType thenType = context.inferredConditionTypes[element.then]!;
    DartType? otherwiseType = element.otherwise == null
        ? null
        : context.inferredConditionTypes[element.otherwise!]!;
    return new ExpressionInferenceResult(
      otherwiseType == null
          ? thenType
          : typeSchemaEnvironment.getStandardUpperBound(
              thenType,
              otherwiseType,
            ),
      element,
    );
  }

  ExpressionInferenceResult _inferPatternForElement(
    PatternForElement element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    int? stackBase;
    assert(checkStackBase(element, stackBase = stackHeight));

    InternalPatternVariableDeclaration patternVariableDeclaration =
        element.internalPatternVariableDeclaration;
    PatternVariableDeclarationAnalysisResult analysisResult =
        analyzePatternVariableDeclaration(
          patternVariableDeclaration,
          patternVariableDeclaration.pattern,
          patternVariableDeclaration.initializer,
          isFinal: patternVariableDeclaration.isFinal,
        );
    DartType matchedValueType = analysisResult.initializerType.unwrapTypeView();

    assert(
      checkStack(element, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]),
    );

    Pattern pattern = popRewrite() as Pattern;
    Expression initializer = popRewrite() as Expression;
    element.patternVariableDeclaration = extern
        .createPatternVariableDeclaration(
          pattern: pattern,
          initializer: initializer,
          isFinal: patternVariableDeclaration.isFinal,
          matchedValueType: matchedValueType,
          fileOffset: patternVariableDeclaration.fileOffset,
        );

    List<Variable> declaredVariables = pattern.declaredVariables;
    assert(declaredVariables.length == element.intermediateVariables.length);
    assert(declaredVariables.length == element.internalVariables.length);
    for (int i = 0; i < declaredVariables.length; i++) {
      DartType type = declaredVariables[i].type;

      Variable intermediateVariable =
          element.intermediateVariables[i].variable.astVariable;
      intermediateVariable.initializer = inferExpression(
        intermediateVariable.initializer!,
        type,
        isVoidAllowed: true,
      ).expression..parent = intermediateVariable;
      intermediateVariable.type = type;

      element.internalVariables[i].variable.type = type;
    }

    return _inferForElementBase(
      element,
      inferredTypeArgument,
      inferredSpreadTypes,
      inferredConditionTypes,
    );
  }

  ExpressionInferenceResult _inferForElement(
    ForElement element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    return _inferForElementBase(
      element,
      inferredTypeArgument,
      inferredSpreadTypes,
      inferredConditionTypes,
    );
  }

  ExpressionInferenceResult _inferForElementBase(
    ForElementBase element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    List<VariableDeclaration> variables = new List.filled(
      element.internalVariables.length,
      dummyVariableDeclaration,
      growable: true,
    );
    for (int index = 0; index < element.internalVariables.length; index++) {
      InternalVariableDeclaration variableDeclaration =
          element.internalVariables[index];
      InternalVariable variable = variableDeclaration.variable;
      if (variable.cosmeticName == null) {
        if (variable.astVariable.initializer != null) {
          ExpressionInferenceResult initializerResult = inferExpression(
            variable.astVariable.initializer!,
            variable.type,
            isVoidAllowed: true,
          );
          variable.astVariable.initializer = initializerResult.expression
            ..parent = variable.astVariable;
          variable.type = initializerResult.inferredType;
        }
        variables[index] = extern.createVariableDeclaration(
          variable.astVariable,
          fileOffset: variableDeclaration.fileOffset,
        );
      } else {
        VariableDeclarationInferenceResult variableResult =
            inferVariableDeclaration(variableDeclaration);
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
    element.variables = variables;

    flowAnalysis.for_conditionBegin(element);
    if (element.condition != null) {
      ExpressionInferenceResult conditionResult = inferExpression(
        element.condition!,
        coreTypes.boolRawType(Nullability.nonNullable),
        isVoidAllowed: false,
      );
      Expression assignableCondition = ensureAssignable(
        coreTypes.boolRawType(Nullability.nonNullable),
        conditionResult.inferredType,
        conditionResult.expression,
      );
      element.condition = assignableCondition..parent = element;
      inferredConditionTypes[element.condition!] = conditionResult.inferredType;
    }
    flowAnalysis.for_bodyBegin(null, switch (element.condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => flowAnalysis.getExpressionInfo(condition),
    });
    ExpressionInferenceResult bodyResult = inferElement(
      element.body,
      inferredTypeArgument,
      inferredSpreadTypes,
      inferredConditionTypes,
    );
    element.body = bodyResult.expression..parent = element;
    flowAnalysis.for_updaterBegin();
    for (int index = 0; index < element.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
        element.updates[index],
        const UnknownType(),
        isVoidAllowed: true,
      );
      element.updates[index] = updateResult.expression..parent = element;
    }
    flowAnalysis.for_end();
    return new ExpressionInferenceResult(bodyResult.inferredType, element);
  }

  ExpressionInferenceResult _inferForInElement(
    ForInElement node,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      // Coverage-ignore-block(suite): Not run.
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
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );

    Variable variable = node.variable = result.loopVariable;
    node.iterable = result.iterable..parent = node;

    flowAnalysis.forEach_bodyBegin(node);

    InternalVariable? declaredVariable = result.declaredVariable;
    if (declaredVariable != null) {
      flowAnalysis.declare(
        declaredVariable,
        new SharedTypeView(declaredVariable.type),
        initialized: true,
      );
      if (isClosureContextLoweringEnabled) {
        // Coverage-ignore-block(suite): Not run.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          declaredVariable.astVariable,
          captureKind: _captureKindForVariable(declaredVariable),
        );
      }
    }
    if (isClosureContextLoweringEnabled) {
      // Coverage-ignore-block(suite): Not run.
      if (declaredVariable?.astVariable != variable) {
        // [variable] is synthesized.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          variable,
          captureKind: CaptureKind.notCaptured,
        );
      }
    }

    node.encoding = result.computeEncoding();

    ExpressionInferenceResult bodyResult = inferElement(
      node.body,
      inferredTypeArgument,
      inferredSpreadTypes,
      inferredConditionTypes,
    );
    node.body = bodyResult.expression..parent = node;
    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();
    if (scopeProviderInfo != null) {
      // Coverage-ignore-block(suite): Not run.
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      // The scope will later be passed to the [ForInStatement] the [element]
      // is desugared into.
      node.scope = scopeProviderInfo.scope;
    }
    return new ExpressionInferenceResult(bodyResult.inferredType, node);
  }

  ExpressionInferenceResult inferElement(
    Expression element,
    DartType inferredTypeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    if (element is ControlFlowElement) {
      switch (element) {
        case SpreadElement():
          return _inferSpreadElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        case NullAwareElement():
          return _inferNullAwareElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        case IfElement():
          return _inferIfElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        case IfCaseElement():
          return _inferIfCaseElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        case ForElement():
          return _inferForElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        case PatternForElement():
          return _inferPatternForElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        case ForInElement():
          return _inferForInElement(
            element,
            inferredTypeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
      }
    } else {
      ExpressionInferenceResult result = inferExpression(
        element,
        inferredTypeArgument,
        isVoidAllowed: true,
      );
      if (inferredTypeArgument is! UnknownType) {
        result = ensureAssignableResult(
          inferredTypeArgument,
          result,
          isVoidAllowed: inferredTypeArgument is VoidType,
        );
      }
      return result;
    }
  }

  void _copyNonPromotionReasonToReplacement(
    TreeNode oldNode,
    TreeNode replacement,
  ) {
    if (!identical(oldNode, replacement) &&
        dataForTesting
                // Coverage-ignore(suite): Not run.
                ?.flowAnalysisResult !=
            null) {
      // Coverage-ignore-block(suite): Not run.
      dataForTesting!.flowAnalysisResult.nonPromotionReasons[replacement] =
          dataForTesting!.flowAnalysisResult.nonPromotionReasons[oldNode]!;
    }
  }

  void checkElement(
    ControlFlowElement item,
    Expression parent,
    DartType typeArgument,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    switch (item) {
      case SpreadElement():
        DartType? spreadType = inferredSpreadTypes[item.expression];
        if (spreadType is DynamicType) {
          Expression expression = ensureAssignable(
            coreTypes.iterableRawType(
              item.isNullAware ? Nullability.nullable : Nullability.nonNullable,
            ),
            spreadType,
            item.expression,
          );
          item.expression = expression..parent = item;
        }
      case NullAwareElement(:Expression expression):
        if (expression is ControlFlowElement) {
          // Coverage-ignore-block(suite): Not run.
          checkElement(
            expression,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
      case IfElement(:Expression then, :Expression? otherwise):
        if (then is ControlFlowElement) {
          checkElement(
            then,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
        if (otherwise is ControlFlowElement) {
          checkElement(
            otherwise,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
      case IfCaseElement(:Expression then, :Expression? otherwise):
        if (then is ControlFlowElement) {
          checkElement(
            then,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
        if (otherwise is ControlFlowElement) {
          checkElement(
            otherwise,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
      case ForElement(:Expression body):
        if (body is ControlFlowElement) {
          checkElement(
            body,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
      case PatternForElement(:Expression body):
        if (body is ControlFlowElement) {
          checkElement(
            body,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
      case ForInElement(:Expression body):
        if (body is ControlFlowElement) {
          checkElement(
            body,
            item,
            typeArgument,
            inferredSpreadTypes,
            inferredConditionTypes,
          );
        }
    }
  }

  @override
  ExpressionInferenceResult visitListLiteral(
    ListLiteral node,
    DartType typeContext,
  ) {
    Class listClass = coreTypes.listClass;
    InterfaceType listType = coreTypes.thisInterfaceType(
      listClass,
      Nullability.nonNullable,
    );
    List<DartType>? inferredTypes;
    DartType inferredTypeArgument;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];
    Map<TreeNode, DartType> inferredSpreadTypes =
        new Map<TreeNode, DartType>.identity();
    Map<Expression, DartType> inferredConditionTypes =
        new Map<Expression, DartType>.identity();
    TypeConstraintGatherer? gatherer;
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(
          listClass.typeParameters,
        );
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    listType = freshTypeParameters.substitute(listType) as InterfaceType;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
        listType,
        typeParametersToInfer,
        typeContext,
        isConst: node.isConst,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        typeOperations: operations,
        inferenceResultForTesting: dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.typeInferenceResult,
        treeNodeForTesting: node,
      );
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        /* previouslyInferredTypes= */ null,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: node,
        typeOperations: operations,
      );
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    for (int index = 0; index < node.expressions.length; ++index) {
      ExpressionInferenceResult result = inferElement(
        node.expressions[index],
        inferredTypeArgument,
        inferredSpreadTypes,
        inferredConditionTypes,
      );
      node.expressions[index] = result.expression..parent = node;
      actualTypes.add(result.inferredType);
      if (inferenceNeeded) {
        formalTypes.add(listType.typeArguments[0]);
      }
    }
    if (inferenceNeeded) {
      gatherer!.constrainArguments(
        formalTypes,
        actualTypes,
        treeNodeForTesting: node,
      );
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        inferredTypes!,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: node,
        typeOperations: operations,
      );
      if (dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        dataForTesting!.typeInferenceResult.inferredTypeArguments[node] =
            inferredTypes;
      }
      inferredTypeArgument = inferredTypes[0];
      node.typeArgument = inferredTypeArgument;
    }
    for (int i = 0; i < node.expressions.length; i++) {
      Expression expression = node.expressions[i];
      if (expression is ControlFlowElement) {
        checkElement(
          expression,
          node,
          node.typeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
        );
      }
    }
    DartType inferredType = new InterfaceType(
      listClass,
      Nullability.nonNullable,
      [inferredTypeArgument],
    );
    if (inferenceNeeded) {
      if (!libraryBuilder.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(node.typeArgument, node.fileOffset);
      }
    }

    Expression result = _translateListLiteral(node);
    return new ExpressionInferenceResult(inferredType, result);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRecordLiteral(
    RecordLiteral node,
    DartType typeContext,
  ) {
    // TODO(cstefantsova): Implement this method.
    return new ExpressionInferenceResult(node.recordType, node);
  }

  @override
  ExpressionInferenceResult visitLogicalExpression(
    LogicalExpression node,
    DartType typeContext,
  ) {
    InterfaceType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    flowAnalysis.logicalBinaryOp_begin();
    ExpressionInferenceResult leftResult = inferExpression(
      node.left,
      boolType,
      isVoidAllowed: false,
    );
    Expression left = ensureAssignableResult(boolType, leftResult).expression;
    node.left = left..parent = node;
    flowAnalysis.logicalBinaryOp_rightBegin(
      flowAnalysis.getExpressionInfo(node.left),
      node,
      isAnd: node.operatorEnum == LogicalExpressionOperator.AND,
    );
    ExpressionInferenceResult rightResult = inferExpression(
      node.right,
      boolType,
      isVoidAllowed: false,
    );
    Expression right = ensureAssignableResult(boolType, rightResult).expression;
    node.right = right..parent = node;
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.logicalBinaryOp_end(
        flowAnalysis.getExpressionInfo(node.right),
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND,
      ),
    );
    return new ExpressionInferenceResult(boolType, node);
  }

  Expression _translateNonConstListOrSet(
    Expression node,
    DartType elementType,
    List<Expression> elements, {
    bool isSet = false,
  }) {
    assert(
      (node is ListLiteral && !node.isConst) ||
          (node is SetLiteral && !node.isConst),
    );

    // Translate elements in place up to the first non-expression, if any.
    int index = 0;
    for (; index < elements.length; ++index) {
      if (elements[index] is ControlFlowElement) break;
    }

    // If there were only expressions, we are done.
    if (index == elements.length) {
      if (node is SetLiteral) {
        return _lowerSetLiteral(node);
      }
      return node;
    }

    InterfaceType receiverType = isSet
        ? typeSchemaEnvironment.setType(elementType, Nullability.nonNullable)
        : typeSchemaEnvironment.listType(elementType, Nullability.nonNullable);
    Variable? result;
    if (index == 0 && elements[index] is SpreadElement) {
      SpreadElement initialSpread = elements[index] as SpreadElement;
      final bool typeMatches =
          initialSpread.elementType != null &&
          typeSchemaEnvironment.isSubtypeOf(
            initialSpread.elementType!,
            elementType,
          );
      if (typeMatches && !initialSpread.isNullAware) {
        // Create a list or set of the initial spread element.
        Expression value = initialSpread.expression;
        index++;
        if (isSet) {
          result = _createVariable(
            new StaticInvocation(
              engine.setOf,
              new Arguments([value], types: [elementType])
                ..fileOffset = node.fileOffset,
            )..fileOffset = node.fileOffset,
            receiverType,
          );
        } else {
          result = _createVariable(
            new StaticInvocation(
              engine.listOf,
              new Arguments([value], types: [elementType])
                ..fileOffset = node.fileOffset,
            )..fileOffset = node.fileOffset,
            receiverType,
          );
        }
      }
    }
    List<Statement>? body;
    if (result == null) {
      // Create a list or set with the elements up to the first non-expression.
      if (isSet) {
        if (libraryBuilder.loader.target.backendTarget.supportsSetLiterals) {
          // Coverage-ignore-block(suite): Not run.
          // Include the elements up to the first non-expression in the set
          // literal.
          result = _createVariable(
            _lowerSetLiteral(
              _createSetLiteral(
                node.fileOffset,
                elementType,
                elements.sublist(0, index),
              ),
            ),
            receiverType,
          );
        } else {
          // TODO(johnniwinther): When all the back ends handle set literals we
          //  can use remove this branch.

          // Create an empty set using the [setFactory] constructor.
          result = _createVariable(
            new StaticInvocation(
              engine.setFactory,
              new Arguments([], types: [elementType])
                ..fileOffset = node.fileOffset,
            )..fileOffset = node.fileOffset,
            receiverType,
          );
          body = [
            extern.createVariableStatement(
              extern.createVariableDeclaration(result),
            ),
          ];
          // Add the elements up to the first non-expression.
          for (int j = 0; j < index; ++j) {
            _addExpressionElement(
              elements[j],
              receiverType,
              result,
              body,
              isSet: isSet,
            );
          }
        }
      } else {
        // Include the elements up to the first non-expression in the list
        // literal.
        result = _createVariable(
          _createListLiteral(
            node.fileOffset,
            elementType,
            elements.sublist(0, index),
          ),
          receiverType,
        );
      }
    }
    body ??= [
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    ];
    // Translate the elements starting with the first non-expression.
    for (; index < elements.length; ++index) {
      _translateElement(
        elements[index],
        receiverType,
        elementType,
        result,
        body,
        isSet: isSet,
      );
    }

    return _createBlockExpression(
      node.fileOffset,
      _createBlock(body),
      _createVariableGet(result),
    );
  }

  void _translateElement(
    Expression element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    if (element is ControlFlowElement) {
      switch (element) {
        case SpreadElement():
          _translateSpreadElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
        case NullAwareElement():
          _translateNullAwareElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
        case IfElement():
          _translateIfElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
        case IfCaseElement():
          _translateIfCaseElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
        case ForElement():
          _translateForElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
        case PatternForElement():
          _translatePatternForElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
        case ForInElement():
          _translateForInElement(
            element,
            receiverType,
            elementType,
            result,
            body,
            isSet: isSet,
          );
      }
    } else {
      _addExpressionElement(element, receiverType, result, body, isSet: isSet);
    }
  }

  void _addExpressionElement(
    Expression element,
    InterfaceType receiverType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    body.add(
      _createExpressionStatement(
        _createAdd(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          element,
          isSet: isSet,
        ),
      ),
    );
  }

  void _translateIfElement(
    IfElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    List<Statement> thenStatements = [];
    _translateElement(
      element.then,
      receiverType,
      elementType,
      result,
      thenStatements,
      isSet: isSet,
    );
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(
        element.otherwise!,
        receiverType,
        elementType,
        result,
        elseStatements = <Statement>[],
        isSet: isSet,
      );
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        : _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseStatements);
    }
    IfStatement ifStatement = _createIf(
      element.fileOffset,
      element.condition,
      thenBody,
      elseBody,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(element, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfCaseElement(
    IfCaseElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    List<Statement> thenStatements = [];
    _translateElement(
      element.then,
      receiverType,
      elementType,
      result,
      thenStatements,
      isSet: isSet,
    );
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(
        element.otherwise!,
        receiverType,
        elementType,
        result,
        elseStatements = <Statement>[],
        isSet: isSet,
      );
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        :
          // Coverage-ignore(suite): Not run.
          _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseStatements);
    }
    IfCaseStatement ifCaseStatement = _createIfCase(
      element.fileOffset,
      element.expression,
      element.matchedValueType!,
      element.patternGuard,
      thenBody,
      elseBody,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(element, ifCaseStatement);
    body.addAll(element.prelude);
    body.add(ifCaseStatement);
  }

  void _translateForElement(
    ForElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    List<Statement> statements = <Statement>[];
    _translateElement(
      element.body,
      receiverType,
      elementType,
      result,
      statements,
      isSet: isSet,
    );
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    ForStatement loop = _createForStatement(
      element.fileOffset,
      element.variables,
      element.condition,
      element.updates,
      loopBody,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(element, loop);
    body.add(loop);
  }

  void _translatePatternForElement(
    PatternForElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    List<Statement> statements = <Statement>[];
    _translateElement(
      element.body,
      receiverType,
      elementType,
      result,
      statements,
      isSet: isSet,
    );
    Statement loopBody = statements.length == 1
        ? statements.first
        :
          // Coverage-ignore(suite): Not run.
          _createBlock(statements);
    ForStatement loop = _createForStatement(
      element.fileOffset,
      element.variables,
      element.condition,
      element.updates,
      loopBody,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(element, loop);
    body.add(element.patternVariableDeclaration);
    for (InternalVariableDeclaration intermediateVariable
        in element.intermediateVariables) {
      body.add(
        extern.createVariableStatement(
          extern.createVariableDeclaration(
            intermediateVariable.variable.astVariable,
            fileOffset: intermediateVariable.fileOffset,
          ),
        ),
      );
    }
    body.add(loop);
  }

  void _translateForInElement(
    ForInElement node,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    List<Statement> statements;
    Statement? bodyPrologue = node.encoding!.bodyPrologue;
    if (bodyPrologue == null) {
      statements = [];
    } else {
      statements = bodyPrologue is Block
          ? bodyPrologue.statements
          : [bodyPrologue];
    }
    _translateElement(
      node.body,
      receiverType,
      elementType,
      result,
      statements,
      isSet: isSet,
    );
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    Statement loop = _createForInStatement(
      node.fileOffset,
      node.variable,
      node.iterable,
      loopBody,
      isAsync: node.isAsync,
    )..scope = node.scope;
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, loop);

    InvalidExpression? preLoopError = node.encoding!.preLoopError;
    if (preLoopError != null) {
      loop = createBlock([
        createExpressionStatement(preLoopError),
        loop,
      ], fileOffset: node.fileOffset);
    }
    body.add(loop);
  }

  void _translateSpreadElement(
    SpreadElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    Expression value = element.expression;

    final bool typeMatches =
        element.elementType != null &&
        typeSchemaEnvironment.isSubtypeOf(element.elementType!, elementType);
    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to 'add'.

      // Null-aware spreads require testing the subexpression's value.
      Variable? temp;
      if (element.isNullAware) {
        temp = _createVariable(
          value,
          typeSchemaEnvironment.iterableType(elementType, Nullability.nullable),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(
        _createAddAll(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          value,
          isSet,
        ),
      );

      if (element.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      Variable? temp;
      if (element.isNullAware) {
        temp = _createVariable(
          value,
          typeSchemaEnvironment.iterableType(
            const DynamicType(),
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      Variable variable = _createForInVariable(
        element.fileOffset,
        const DynamicType(),
      );
      Variable castedVar = _createVariable(
        _createImplicitAs(
          element.expression.fileOffset,
          _createVariableGet(variable),
          elementType,
        ),
        elementType,
      );
      Statement loopBody = _createBlock(<Statement>[
        extern.createVariableStatement(
          extern.createVariableDeclaration(castedVar),
        ),
        _createExpressionStatement(
          _createAdd(
            // Don't make a mess of jumping around (and make scope building
            // impossible).
            _createVariableGet(result)..fileOffset = TreeNode.noOffset,
            receiverType,
            _createVariableGet(castedVar),
            isSet: isSet,
          ),
        ),
      ]);
      Statement statement = _createForInStatement(
        element.fileOffset,
        variable,
        value,
        loopBody,
      );

      if (element.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    }
  }

  void _translateNullAwareElement(
    NullAwareElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    // The code below lowers null-aware elements into series of statements. For
    // example, the null-aware element in the literal `<String>[?expr]` will be
    // lowered into the following:
    //
    //   String? #temp = expr;
    //   if (#temp != null) {
    //     #t.add(#temp{String});
    //   }
    //
    // In that example `#t` is the collection literal being generated, and
    // `#temp{String}` represents the promotion of the variable `#temp` to the
    // non-nullable type `String`.
    //
    // Note that the type inference ensures that the static type of `expr` is a
    // subtype of `String?`, and by now we don't need to insert another cast to
    // ensure it.

    Expression value = element.expression;
    DartType nullableElementType = elementType.withDeclaredNullability(
      Nullability.nullable,
    );
    Variable temp = _createVariable(value, nullableElementType);
    body.add(
      extern.createVariableStatement(extern.createVariableDeclaration(temp)),
    );

    Statement statement = _createIf(
      temp.fileOffset,
      _createEqualsNull(_createVariableGet(temp), notEquals: true),
      _createExpressionStatement(
        _createAdd(
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          _createNullCheckedVariableGet(temp),
          isSet: isSet,
        ),
      ),
    );
    body.add(statement);
  }

  Expression _translateListLiteral(ListLiteral node) {
    if (node.isConst) {
      return _translateConstListOrSet(
        node,
        node.typeArgument,
        node.expressions,
        isSet: false,
      );
    } else {
      return _translateNonConstListOrSet(
        node,
        node.typeArgument,
        node.expressions,
        isSet: false,
      );
    }
  }

  Expression _translateSetLiteral(SetLiteral node) {
    if (node.isConst) {
      return _translateConstListOrSet(
        node,
        node.typeArgument,
        node.expressions,
        isSet: true,
      );
    } else {
      return _translateNonConstListOrSet(
        node,
        node.typeArgument,
        node.expressions,
        isSet: true,
      );
    }
  }

  Expression _translateMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return _translateConstMap(node);
    } else {
      return _translateNonConstMap(node);
    }
  }

  Expression _translateNonConstMap(MapLiteral node) {
    assert(!node.isConst);
    // Translate entries in place up to the first control-flow entry, if any.
    int index = 0;
    for (; index < node.entries.length; ++index) {
      if (node.entries[index] is ControlFlowMapEntry) break;
      node.entries[index] = node.entries[index]..parent = node;
    }

    // If there were no control-flow entries we are done.
    if (index == node.entries.length) return node;

    // Build a block expression and create an empty map.
    InterfaceType receiverType = typeSchemaEnvironment.mapType(
      node.keyType,
      node.valueType,
      Nullability.nonNullable,
    );
    Variable? result;

    if (index == 0 && node.entries[index] is SpreadMapEntry) {
      SpreadMapEntry initialSpread = node.entries[index] as SpreadMapEntry;
      final InterfaceType entryType = new InterfaceType(
        engine.mapEntryClass,
        Nullability.nonNullable,
        <DartType>[node.keyType, node.valueType],
      );
      final bool typeMatches =
          initialSpread.entryType != null &&
          typeSchemaEnvironment.isSubtypeOf(
            initialSpread.entryType!,
            entryType,
          );
      if (typeMatches && !initialSpread.isNullAware) {
        {
          // Create a map of the initial spread element.
          Expression value = initialSpread.expression;
          index++;
          result = _createVariable(
            new StaticInvocation(
              engine.mapOf,
              new Arguments([value], types: [node.keyType, node.valueType])
                ..fileOffset = node.fileOffset,
            )..fileOffset = node.fileOffset,
            receiverType,
          );
        }
      }
    }

    List<Statement>? body;
    if (result == null) {
      result = _createVariable(
        _createMapLiteral(node.fileOffset, node.keyType, node.valueType, []),
        receiverType,
      );
      body = [
        extern.createVariableStatement(
          extern.createVariableDeclaration(result),
        ),
      ];
      // Add all the entries up to the first control-flow entry.
      for (int j = 0; j < index; ++j) {
        _addNormalEntry(node.entries[j], receiverType, result, body);
      }
    }

    body ??= [
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    ];

    // Translate the elements starting with the first non-expression.
    for (; index < node.entries.length; ++index) {
      _translateEntry(
        node.entries[index],
        receiverType,
        node.keyType,
        node.valueType,
        result,
        body,
      );
    }

    return _createBlockExpression(
      node.fileOffset,
      _createBlock(body),
      _createVariableGet(result),
    );
  }

  void _translateEntry(
    MapLiteralEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    if (entry is ControlFlowMapEntry) {
      switch (entry) {
        case SpreadMapEntry():
          _translateSpreadEntry(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
        case NullAwareMapEntry():
          _translateNullAwareMapEntry(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
        case IfMapEntry():
          _translateIfEntry(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
        case IfCaseMapEntry():
          _translateIfCaseEntry(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
        case PatternForMapEntry():
          _translatePatternForEntry(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
        case ForMapEntry():
          _translateForEntry(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
        case ForInMapEntry():
          _translateForInEntry2(
            entry,
            receiverType,
            keyType,
            valueType,
            result,
            body,
          );
      }
    } else {
      _addNormalEntry(entry, receiverType, result, body);
    }
  }

  void _addNormalEntry(
    MapLiteralEntry entry,
    InterfaceType receiverType,
    Variable result,
    List<Statement> body,
  ) {
    body.add(
      _createExpressionStatement(
        _createIndexSet(
          entry.fileOffset,
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          entry.key,
          entry.value,
        ),
      ),
    );
  }

  void _translateIfEntry(
    IfMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> thenBody = [];
    _translateEntry(
      entry.then,
      receiverType,
      keyType,
      valueType,
      result,
      thenBody,
    );
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateEntry(
        entry.otherwise!,
        receiverType,
        keyType,
        valueType,
        result,
        elseBody = <Statement>[],
      );
    }
    Statement thenStatement = thenBody.length == 1
        ? thenBody.first
        : _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement = elseBody.length == 1
          ? elseBody.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseBody);
    }
    IfStatement ifStatement = _createIf(
      entry.fileOffset,
      entry.condition,
      thenStatement,
      elseStatement,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(entry, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfCaseEntry(
    IfCaseMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> thenBody = [];
    _translateEntry(
      entry.then,
      receiverType,
      keyType,
      valueType,
      result,
      thenBody,
    );
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateEntry(
        entry.otherwise!,
        receiverType,
        keyType,
        valueType,
        result,
        elseBody = <Statement>[],
      );
    }
    Statement thenStatement = thenBody.length == 1
        ? thenBody.first
        :
          // Coverage-ignore(suite): Not run.
          _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement = elseBody.length == 1
          ? elseBody.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseBody);
    }
    IfCaseStatement ifStatement = _createIfCase(
      entry.fileOffset,
      entry.expression,
      entry.matchedValueType!,
      entry.patternGuard,
      thenStatement,
      elseStatement,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(entry, ifStatement);
    body.addAll(entry.prelude);
    body.add(ifStatement);
  }

  void _translateForEntry(
    ForMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements = <Statement>[];
    _translateEntry(
      entry.body,
      receiverType,
      keyType,
      valueType,
      result,
      statements,
    );
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    ForStatement loop = _createForStatement(
      entry.fileOffset,
      entry.variables,
      entry.condition,
      entry.updates,
      loopBody,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(entry, loop);
    body.add(loop);
  }

  void _translatePatternForEntry(
    PatternForMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements = <Statement>[];
    _translateEntry(
      entry.body,
      receiverType,
      keyType,
      valueType,
      result,
      statements,
    );
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    ForStatement loop = _createForStatement(
      entry.fileOffset,
      entry.variables,
      entry.condition,
      entry.updates,
      loopBody,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(entry, loop);
    body.add(entry.patternVariableDeclaration);
    for (InternalVariableDeclaration intermediateVariable
        in entry.intermediateVariables) {
      body.add(
        extern.createVariableStatement(
          extern.createVariableDeclaration(
            intermediateVariable.variable.astVariable,
            fileOffset: intermediateVariable.fileOffset,
          ),
        ),
      );
    }
    body.add(loop);
  }

  void _translateForInEntry2(
    ForInMapEntry node,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements;
    Statement? bodyPrologue = node.encoding!.bodyPrologue;
    if (bodyPrologue == null) {
      statements = [];
    } else {
      statements = bodyPrologue is Block
          ? bodyPrologue.statements
          : [bodyPrologue];
    }
    _translateEntry(
      node.body,
      receiverType,
      keyType,
      valueType,
      result,
      statements,
    );
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    Statement loop = _createForInStatement(
      node.fileOffset,
      node.variable,
      node.iterable,
      loopBody,
      isAsync: node.isAsync,
    )..scope = node.scope;
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, loop);

    InvalidExpression? preLoopError = node.encoding!.preLoopError;
    if (preLoopError != null) {
      loop = createBlock([
        createExpressionStatement(preLoopError),
        loop,
      ], fileOffset: node.fileOffset);
    }

    body.add(loop);
  }

  void _translateSpreadEntry(
    SpreadMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    Expression value = entry.expression;

    final InterfaceType entryType = new InterfaceType(
      engine.mapEntryClass,
      Nullability.nonNullable,
      <DartType>[keyType, valueType],
    );
    final bool typeMatches =
        entry.entryType != null &&
        typeSchemaEnvironment.isSubtypeOf(entry.entryType!, entryType);

    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to '[]='.

      // Null-aware spreads require testing the subexpression's value.
      Variable? temp;
      if (entry.isNullAware) {
        temp = _createVariable(
          value,
          typeSchemaEnvironment.mapType(
            keyType,
            valueType,
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(
        _createMapAddAll(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          value,
        ),
      );

      if (entry.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      Variable? temp;
      if (entry.isNullAware) {
        temp = _createVariable(
          value,
          typeSchemaEnvironment.mapType(
            const DynamicType(),
            const DynamicType(),
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      final InterfaceType variableType = new InterfaceType(
        engine.mapEntryClass,
        Nullability.nonNullable,
        <DartType>[const DynamicType(), const DynamicType()],
      );
      Variable variable = _createForInVariable(entry.fileOffset, variableType);
      Variable keyVar = _createVariable(
        _createImplicitAs(
          entry.expression.fileOffset,
          _createGetKey(
            entry.expression.fileOffset,
            _createVariableGet(variable),
            variableType,
          ),
          keyType,
        ),
        keyType,
      );
      Variable valueVar = _createVariable(
        _createImplicitAs(
          entry.expression.fileOffset,
          _createGetValue(
            entry.expression.fileOffset,
            _createVariableGet(variable),
            variableType,
          ),
          valueType,
        ),
        valueType,
      );
      Statement loopBody = _createBlock(<Statement>[
        extern.createVariableStatement(
          extern.createVariableDeclaration(keyVar),
        ),
        extern.createVariableStatement(
          extern.createVariableDeclaration(valueVar),
        ),
        _createExpressionStatement(
          _createIndexSet(
            entry.expression.fileOffset,
            _createVariableGet(result),
            receiverType,
            _createVariableGet(keyVar),
            _createVariableGet(valueVar),
          ),
        ),
      ]);
      Statement statement = _createForInStatement(
        entry.fileOffset,
        variable,
        _createGetEntries(entry.fileOffset, value, receiverType),
        loopBody,
      );

      if (entry.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    }
  }

  void _translateNullAwareMapEntry(
    NullAwareMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    assert(entry.isKeyNullAware || entry.isValueNullAware);

    // The code below lowers null-aware map entries into series of statements.
    // For example, the null-aware entry in the literal
    // `<String, int>{?key: ?value}` will be lowered into the following:
    //
    //   String? #keyTemp = key as String?;
    //   if (#keyTemp != null) {
    //     int? #valueTemp = value as int?;
    //     if (#valueTemp != null) {
    //       #t[#keyTemp{String}] = #valueTemp{int};
    //     }
    //   }
    //
    // In that example `#t` is the collection literal being generated, and
    // `#keyTemp{String}` and `#valueTemp{int}` represent the promotions of the
    // variables `#keyTemp` and `#valueTemp` to the non-nullable types `String`
    // and `int` correspondingly.
    //
    // Note that the type inference ensures that the static type of `key` and
    // `value` are subtypes of `String?` and `int?` correspondingly, and by now
    // we don't need to insert another cast to ensure it.

    Expression keyExpression = entry.key;
    Expression valueExpression = entry.value;

    // Since the statement adding the entry to the map may include promotions of
    // the key or the value expressions, we can't create that statement until
    // the very end. Instead, we track the guard node that the add-entry
    // statement should be directly nested in and assign the add-entry
    // statement with the necessary promotions when we can create it.
    IfStatement? addedEntryStatementParent;

    Block desugaredStatement = _createBlock([]);

    if (entry.isValueNullAware) {
      DartType nullableValueType = valueType.withDeclaredNullability(
        Nullability.nullable,
      );
      Variable valueTemp = _createVariable(valueExpression, nullableValueType);
      valueExpression = _createNullCheckedVariableGet(valueTemp);

      IfStatement ifValueNotNullStatement = _createIf(
        valueTemp.fileOffset,
        _createEqualsNull(createVariableGet(valueTemp), notEquals: true),
        desugaredStatement,
      );
      addedEntryStatementParent ??= ifValueNotNullStatement;

      desugaredStatement = _createBlock([
        extern.createVariableStatement(
          extern.createVariableDeclaration(valueTemp),
        ),
        ifValueNotNullStatement,
      ])..fileOffset = entry.fileOffset;
    }

    if (entry.isKeyNullAware) {
      DartType nullableKeyType = keyType.withDeclaredNullability(
        Nullability.nullable,
      );
      Variable keyTemp = _createVariable(keyExpression, nullableKeyType);
      keyExpression = _createNullCheckedVariableGet(keyTemp);

      IfStatement ifKeyNotNullStatement = _createIf(
        keyTemp.fileOffset,
        _createEqualsNull(createVariableGet(keyTemp), notEquals: true),
        desugaredStatement,
      );
      addedEntryStatementParent ??= ifKeyNotNullStatement;

      desugaredStatement = _createBlock([
        extern.createVariableStatement(
          extern.createVariableDeclaration(keyTemp),
        ),
        ifKeyNotNullStatement,
      ])..fileOffset = entry.fileOffset;
    } else if (entry.isValueNullAware) {
      assert(!entry.isKeyNullAware);
      // The key is non null-aware, but the value is null-aware. In this case,
      // we need to hoist the key expression to preserve the evaluation order.
      // Consider the following example:
      //
      //   <String, int>{keyExpression(): ?valueExpression()}
      //
      // Without hoisting the key expression, the map literal will be desugared
      // as follows:
      //
      //   int? #valueTemp = valueExpression();
      //   if (#valueTemp != null) {
      //     #t[keyExpression()] = #valueTemp{int};
      //   }
      //
      // In that desugaring, `valueExpression` is executed before
      // `keyExpression`, which doesn't match the expected evaluation order.
      // With the hoisting of the key, the desugared expression will look as
      // follows:
      //
      //   String #keyTemp = keyExpression();
      //   int? #valueTemp = valueExpression();
      //   if (#valueTemp != null) {
      //     #t[#keyTemp] = #valueTemp{int};
      //   }

      Variable keyTemp = _createVariable(keyExpression, keyType);
      keyExpression = _createVariableGet(keyTemp);

      desugaredStatement.statements.insert(
        0,
        extern.createVariableStatement(
          extern.createVariableDeclaration(keyTemp),
        )..parent = desugaredStatement,
      );
    }

    // Since either the key or the value is null-aware, [desugaredStatement]
    // should be replaced with a null-checking [IfStatement].
    assert(
      addedEntryStatementParent != null &&
          desugaredStatement is! EmptyStatement,
    );
    addedEntryStatementParent!.then = _createExpressionStatement(
      _createIndexSet(
        entry.fileOffset,
        _createVariableGet(result)..fileOffset = TreeNode.noOffset,
        receiverType,
        keyExpression,
        valueExpression,
      ),
    );

    body.addAll(desugaredStatement.statements);
  }

  Expression _translateConstListOrSet(
    Expression node,
    DartType elementType,
    List<Expression> elements, {
    bool isSet = false,
  }) {
    assert(
      (node is ListLiteral && node.isConst) ||
          (node is SetLiteral && node.isConst),
    );

    // Translate elements in place up to the first non-expression, if any.
    int i = 0;
    for (; i < elements.length; ++i) {
      if (elements[i] is ControlFlowElement) break;
    }

    // If there were only expressions, we are done.
    if (i == elements.length) {
      return node;
    }

    Expression makeLiteral(int fileOffset, List<Expression> expressions) {
      if (isSet) {
        return _translateConstListOrSet(
          _createSetLiteral(
            fileOffset,
            elementType,
            expressions,
            isConst: true,
          ),
          elementType,
          expressions,
          isSet: true,
        );
      } else {
        return _translateConstListOrSet(
          _createListLiteral(
            fileOffset,
            elementType,
            expressions,
            isConst: true,
          ),
          elementType,
          expressions,
          isSet: false,
        );
      }
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<Expression>? currentPart = i > 0 ? elements.sublist(0, i) : null;

    DartType iterableType = typeSchemaEnvironment.iterableType(
      elementType,
      Nullability.nonNullable,
    );

    for (; i < elements.length; ++i) {
      Expression element = elements[i];
      if (element is ControlFlowElement) {
        switch (element) {
          case SpreadElement():
            if (currentPart != null) {
              parts.add(makeLiteral(node.fileOffset, currentPart));
              currentPart = null;
            }
            Expression spreadExpression = element.expression;
            if (element.isNullAware) {
              SyntheticVariable temp = _createVariable(
                spreadExpression,
                typeSchemaEnvironment.iterableType(
                  elementType,
                  Nullability.nullable,
                ),
              );
              parts.add(
                _createNullAwareGuard(
                  element.fileOffset,
                  temp,
                  makeLiteral(element.fileOffset, []),
                  iterableType,
                ),
              );
            } else {
              parts.add(spreadExpression);
            }
          case NullAwareElement():
            if (currentPart != null) {
              // Coverage-ignore-block(suite): Not run.
              parts.add(makeLiteral(node.fileOffset, currentPart));
              currentPart = null;
            }
            SyntheticVariable temp = _createVariable(
              element.expression,
              elementType.withDeclaredNullability(Nullability.nullable),
            );
            parts.add(
              _createNullAwareGuard(
                element.fileOffset,
                temp,
                makeLiteral(element.fileOffset, []),
                iterableType,
                nullCheckedValue: makeLiteral(element.fileOffset, [
                  _createNullCheckedVariableGet(temp),
                ]),
              ),
            );
          case IfElement():
            if (currentPart != null) {
              // Coverage-ignore-block(suite): Not run.
              parts.add(makeLiteral(node.fileOffset, currentPart));
              currentPart = null;
            }
            Expression condition = element.condition;
            Expression then = makeLiteral(element.then.fileOffset, [
              element.then,
            ]);
            Expression otherwise = element.otherwise != null
                ?
                  // Coverage-ignore(suite): Not run.
                  makeLiteral(element.otherwise!.fileOffset, [
                    element.otherwise!,
                  ])
                : makeLiteral(element.fileOffset, []);
            parts.add(
              _createConditionalExpression(
                element.fileOffset,
                condition,
                then,
                otherwise,
                iterableType,
              ),
            );
          // Coverage-ignore(suite): Not run.
          case IfCaseElement():
          case ForElement():
          case PatternForElement():
          case ForInElement():
            // Rejected earlier.
            problems.unhandled(
              "${element.runtimeType}",
              "_translateConstListOrSet",
              element.fileOffset,
              fileUri,
            );
        }
      } else {
        currentPart ??= <Expression>[];
        currentPart.add(element);
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(node.fileOffset, currentPart));
    }
    if (isSet) {
      return new SetConcatenation(parts, typeArgument: elementType)
        ..fileOffset = node.fileOffset;
    } else {
      return new ListConcatenation(parts, typeArgument: elementType)
        ..fileOffset = node.fileOffset;
    }
  }

  Expression _translateConstMap(MapLiteral node) {
    assert(node.isConst);
    // Translate entries in place up to the first control-flow entry, if any.
    int i = 0;
    for (; i < node.entries.length; ++i) {
      if (node.entries[i] is ControlFlowMapEntry) break;
    }

    // If there were no control-flow entries we are done.
    if (i == node.entries.length) return node;

    Expression makeLiteral(int fileOffset, List<MapLiteralEntry> entries) {
      return _translateConstMap(
        _createMapLiteral(
          fileOffset,
          node.keyType,
          node.valueType,
          entries,
          isConst: true,
        ),
      );
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<MapLiteralEntry>? currentPart = i > 0
        ? node.entries.sublist(0, i)
        : null;

    DartType collectionType = typeSchemaEnvironment.mapType(
      node.keyType,
      node.valueType,
      Nullability.nonNullable,
    );

    for (; i < node.entries.length; ++i) {
      MapLiteralEntry entry = node.entries[i];
      if (entry is ControlFlowMapEntry) {
        switch (entry) {
          case SpreadMapEntry():
            if (currentPart != null) {
              parts.add(makeLiteral(node.fileOffset, currentPart));
              currentPart = null;
            }
            Expression spreadExpression = entry.expression;
            if (entry.isNullAware) {
              SyntheticVariable temp = _createVariable(
                spreadExpression,
                collectionType.withDeclaredNullability(Nullability.nullable),
              );
              parts.add(
                _createNullAwareGuard(
                  entry.fileOffset,
                  temp,
                  makeLiteral(entry.fileOffset, []),
                  collectionType,
                ),
              );
            } else {
              parts.add(spreadExpression);
            }
          case NullAwareMapEntry():
            assert(entry.isKeyNullAware || entry.isValueNullAware);
            if (currentPart != null) {
              // Coverage-ignore-block(suite): Not run.
              parts.add(makeLiteral(node.fileOffset, currentPart));
              currentPart = null;
            }

            Expression keyExpression = entry.key;
            Expression valueExpression = entry.value;

            // Since the desugared map entry may include promotions of the key
            // or the value expressions, we can't finalize it until the later
            // stages of desugaring. To assign the promoted expressions as
            // necessary, we keep track of the map entry node via
            // [addedMapLiteralEntry].
            MapLiteralEntry? addedMapLiteralEntry;

            Expression desugaredExpression = new NullLiteral();

            if (entry.isValueNullAware) {
              SyntheticVariable valueTemp = _createVariable(
                valueExpression,
                node.valueType.withDeclaredNullability(Nullability.nullable),
              );
              valueExpression = _createNullCheckedVariableGet(valueTemp);
              Expression defaultValue = makeLiteral(entry.fileOffset, []);
              addedMapLiteralEntry ??= new MapLiteralEntry(
                keyExpression,
                valueExpression,
              );
              Expression nullCheckedValue = makeLiteral(
                entry.value.fileOffset,
                [addedMapLiteralEntry],
              );
              desugaredExpression = _createNullAwareGuard(
                entry.fileOffset,
                valueTemp,
                defaultValue,
                collectionType,
                nullCheckedValue: nullCheckedValue,
              );
            }

            if (entry.isKeyNullAware) {
              SyntheticVariable keyTemp = _createVariable(
                entry.key,
                node.keyType.withDeclaredNullability(Nullability.nullable),
              );
              keyExpression = _createNullCheckedVariableGet(keyTemp);
              Expression defaultValue = makeLiteral(entry.fileOffset, []);
              Expression nullCheckedKey;
              if (addedMapLiteralEntry == null) {
                assert(!entry.isValueNullAware);
                addedMapLiteralEntry = new MapLiteralEntry(
                  keyExpression,
                  valueExpression,
                );
                nullCheckedKey = makeLiteral(entry.key.fileOffset, [
                  addedMapLiteralEntry,
                ]);
              } else {
                assert(entry.isValueNullAware);
                addedMapLiteralEntry.key = keyExpression
                  ..parent = addedMapLiteralEntry;
                nullCheckedKey = desugaredExpression;
              }
              desugaredExpression = _createNullAwareGuard(
                entry.fileOffset,
                keyTemp,
                defaultValue,
                collectionType,
                nullCheckedValue: nullCheckedKey,
              );
            }

            // Since either the key or the value is null-aware,
            // [desugaredExpression] should be replaced with a null-checking
            // [Expression].
            assert(
              addedMapLiteralEntry != null &&
                  desugaredExpression is! NullLiteral,
            );

            parts.add(desugaredExpression);
          // Coverage-ignore(suite): Not run.
          case IfMapEntry():
            if (currentPart != null) {
              parts.add(makeLiteral(node.fileOffset, currentPart));
              currentPart = null;
            }
            Expression condition = entry.condition;
            Expression then = makeLiteral(entry.then.fileOffset, [entry.then]);
            Expression otherwise = entry.otherwise != null
                ? makeLiteral(entry.otherwise!.fileOffset, [entry.otherwise!])
                : makeLiteral(node.fileOffset, []);
            parts.add(
              _createConditionalExpression(
                entry.fileOffset,
                condition,
                then,
                otherwise,
                collectionType,
              ),
            );
          // Coverage-ignore(suite): Not run.
          case IfCaseMapEntry():
          case PatternForMapEntry():
          case ForMapEntry():
          case ForInMapEntry():
            // Rejected earlier.
            problems.unhandled(
              "${entry.runtimeType}",
              "_translateConstMap",
              entry.fileOffset,
              fileUri,
            );
        }
      } else {
        currentPart ??= <MapLiteralEntry>[];
        currentPart.add(entry);
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(node.fileOffset, currentPart));
    }
    return new MapConcatenation(
      parts,
      keyType: node.keyType,
      valueType: node.valueType,
    );
  }

  SyntheticVariable _createVariable(Expression expression, DartType type) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return extern.createVariableCache(expression, type);
  }

  Variable _createForInVariable(int fileOffset, DartType type) {
    assert(fileOffset != TreeNode.noOffset);
    return extern.createUninitializedVariable(
      type: type,
      fileOffset: fileOffset,
      isFinal: true,
      hasDeclaredInitializer: true,
    );
  }

  VariableGet _createVariableGet(Variable variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    return new VariableGet(variable)..fileOffset = variable.fileOffset;
  }

  VariableGet _createNullCheckedVariableGet(Variable variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    DartType promotedType = variable.type.withDeclaredNullability(
      Nullability.nonNullable,
    );
    if (promotedType != variable.type) {
      return new VariableGet(variable, promotedType)
        ..fileOffset = variable.fileOffset;
    }
    return _createVariableGet(variable);
  }

  MapLiteral _createMapLiteral(
    int fileOffset,
    DartType keyType,
    DartType valueType,
    List<MapLiteralEntry> entries, {
    bool isConst = false,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new MapLiteral(
      entries,
      keyType: keyType,
      valueType: valueType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }

  ListLiteral _createListLiteral(
    int fileOffset,
    DartType elementType,
    List<Expression> elements, {
    bool isConst = false,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new ListLiteral(
      elements,
      typeArgument: elementType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }

  SetLiteral _createSetLiteral(
    int fileOffset,
    DartType elementType,
    List<Expression> elements, {
    bool isConst = false,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new SetLiteral(elements, typeArgument: elementType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  Expression _createAdd(
    Expression receiver,
    InterfaceType receiverType,
    Expression argument, {
    required bool isSet,
  }) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(
          isSet ? engine.setAddFunctionType : engine.listAddFunctionType,
        );
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('add'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: isSet ? engine.setAdd : engine.listAdd,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createAddAll(
    Expression receiver,
    InterfaceType receiverType,
    Expression argument,
    bool isSet,
  ) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(
          isSet ? engine.setAddAllFunctionType : engine.listAddAllFunctionType,
        );
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('addAll'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: isSet ? engine.setAddAll : engine.listAddAll,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createMapAddAll(
    Expression receiver,
    InterfaceType receiverType,
    Expression argument,
  ) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(engine.mapAddAllFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('addAll'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: engine.mapAddAll,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createEqualsNull(
    Expression expression, {
    bool notEquals = false,
  }) {
    assert(expression.fileOffset != TreeNode.noOffset);
    Expression check = new EqualsNull(expression)
      ..fileOffset = expression.fileOffset;
    if (notEquals) {
      check = new Not(check)..fileOffset = expression.fileOffset;
    }
    return check;
  }

  Expression _createIndexSet(
    int fileOffset,
    Expression receiver,
    InterfaceType receiverType,
    Expression key,
    Expression value,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(engine.mapPutFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('[]='),
        new Arguments([key, value]),
        functionType: functionType as FunctionType,
        interfaceTarget: engine.mapPut,
      )
      ..fileOffset = fileOffset
      ..isInvariant = true;
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

  IfStatement _createIf(
    int fileOffset,
    Expression condition,
    Statement then, [
    Statement? otherwise,
  ]) {
    assert(fileOffset != TreeNode.noOffset);
    return new IfStatement(condition, then, otherwise)..fileOffset = fileOffset;
  }

  IfCaseStatement _createIfCase(
    int fileOffset,
    Expression condition,
    DartType matchedValueType,
    PatternGuard patternGuard,
    Statement then, [
    Statement? otherwise,
  ]) {
    assert(fileOffset != TreeNode.noOffset);
    return new IfCaseStatement(condition, patternGuard, then, otherwise)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
  }

  Expression _createGetKey(
    int fileOffset,
    Expression receiver,
    InterfaceType entryType,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(engine.mapEntryKey.type);
    return new InstanceGet(
      InstanceAccessKind.Instance,
      receiver,
      new Name('key'),
      interfaceTarget: engine.mapEntryKey,
      resultType: resultType,
    )..fileOffset = fileOffset;
  }

  Expression _createGetValue(
    int fileOffset,
    Expression receiver,
    InterfaceType entryType,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(engine.mapEntryValue.type);
    return new InstanceGet(
      InstanceAccessKind.Instance,
      receiver,
      new Name('value'),
      interfaceTarget: engine.mapEntryValue,
      resultType: resultType,
    )..fileOffset = fileOffset;
  }

  Expression _createGetEntries(
    int fileOffset,
    Expression receiver,
    InterfaceType mapType,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(mapType)
        .substituteType(engine.mapEntries.getterType);
    return new InstanceGet(
      InstanceAccessKind.Instance,
      receiver,
      new Name('entries'),
      interfaceTarget: engine.mapEntries,
      resultType: resultType,
    )..fileOffset = fileOffset;
  }

  ForStatement _createForStatement(
    int fileOffset,
    List<VariableDeclaration> variables,
    Expression? condition,
    List<Expression> updates,
    Statement body,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new ForStatement(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  ForInStatement _createForInStatement(
    int fileOffset,
    Variable variable,
    Expression iterable,
    Statement body, {
    bool isAsync = false,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new ForInStatement(variable, iterable, body, isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  Let _createNullAwareGuard(
    int fileOffset,
    SyntheticVariable variable,
    Expression defaultValue,
    DartType type, {
    Expression? nullCheckedValue,
  }) {
    return new Let(
      variable,
      _createConditionalExpression(
        fileOffset,
        _createEqualsNull(_createVariableGet(variable)),
        defaultValue,
        nullCheckedValue ?? _createNullCheckedVariableGet(variable),
        type,
      ),
    )..fileOffset = fileOffset;
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

  // Calculates the key and the value type of a spread map entry of type
  // spreadMapEntryType and stores them in output in positions offset and offset
  // + 1.  If the types can't be calculated, for example, if spreadMapEntryType
  // is a function type, the original values in output are preserved.
  void storeSpreadMapEntryElementTypes(
    DartType spreadMapEntryType,
    bool isNullAware,
    List<DartType?> output,
    int offset,
  ) {
    DartType typeBound = spreadMapEntryType.nonTypeParameterBound;
    if (coreTypes.isNull(typeBound)) {
      if (isNullAware) {
        output[offset] = output[offset + 1] = const NeverType.nonNullable();
      }
    } else if (typeBound is TypeDeclarationType) {
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

  MapLiteralEntry _inferSpreadMapEntry(
    SpreadMapEntry entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    if (entry.isNullAware) {
      spreadContext = computeNullable(spreadContext);
    }
    ExpressionInferenceResult spreadResult = inferExpression(
      entry.expression,
      spreadContext,
      isVoidAllowed: true,
    );
    entry.expression = spreadResult.expression..parent = entry;
    DartType spreadType = spreadResult.inferredType;
    inferredSpreadTypes[entry.expression] = spreadType;
    int length = actualTypes.length;
    actualTypes.add(noInferredType);
    actualTypes.add(noInferredType);
    storeSpreadMapEntryElementTypes(
      spreadType,
      entry.isNullAware,
      actualTypes,
      length,
    );
    DartType? actualKeyType = actualTypes[length];
    DartType? actualValueType = actualTypes[length + 1];
    DartType spreadTypeBound = spreadType.nonTypeParameterBound;
    DartType? actualElementType = getSpreadElementType(
      spreadType,
      spreadTypeBound,
      entry.isNullAware,
    );

    MapLiteralEntry replacement = entry;

    if (actualKeyType == noInferredType) {
      if (coreTypes.isNull(spreadTypeBound) && !entry.isNullAware) {
        replacement = new MapLiteralEntry(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonNullAwareSpreadIsNull.withArguments(
              spreadType: spreadType,
            ),
            fileUri: fileUri,
            fileOffset: entry.expression.fileOffset,
            length: 1,
          ),
          new NullLiteral(),
        )..fileOffset = entry.fileOffset;
      } else if (actualElementType != null) {
        if (spreadType.isPotentiallyNullable &&
            spreadType is! DynamicType &&
            spreadType is! NullType &&
            !entry.isNullAware) {
          Expression receiver = entry.expression;
          Expression problem = problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nullableSpreadError,
            fileUri: fileUri,
            fileOffset: receiver.fileOffset,
            length: 1,
            context: getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(
                flowAnalysis.getExpressionInfo(receiver),
              )(),
              entry,
              // Coverage-ignore(suite): Not run.
              (type) => !type.isPotentiallyNullable,
            ),
          );
          _copyNonPromotionReasonToReplacement(entry, problem);
          replacement = new SpreadMapEntry(problem, isNullAware: false)
            ..fileOffset = entry.fileOffset;
        }

        // Don't report the error here, it might be an ambiguous Set.  The
        // error is reported in checkMapEntry if it's disambiguated as map.
        offsets.iterableSpreadType = spreadType;
      } else {
        Expression receiver = entry.expression;
        Expression problem = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.spreadMapEntryTypeMismatch.withArguments(
            spreadType: spreadType,
          ),
          fileUri: fileUri,
          fileOffset: receiver.fileOffset,
          length: 1,
          context: getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(
              flowAnalysis.getExpressionInfo(receiver),
            )(),
            entry,
            // Coverage-ignore(suite): Not run.
            (type) => !type.isPotentiallyNullable,
          ),
        );
        _copyNonPromotionReasonToReplacement(entry, problem);
        replacement = new MapLiteralEntry(problem, new NullLiteral())
          ..fileOffset = entry.fileOffset;
      }
    } else if (spreadTypeBound is InterfaceType) {
      Expression? keyError;
      Expression? valueError;
      if (!isAssignable(inferredKeyType, actualKeyType)) {
        keyError = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.spreadMapEntryElementKeyTypeMismatch.withArguments(
            spreadKeyType: actualKeyType,
            mapKeyType: inferredKeyType,
          ),
          fileUri: fileUri,
          fileOffset: entry.expression.fileOffset,
          length: 1,
        );
      }
      if (!isAssignable(inferredValueType, actualValueType)) {
        valueError = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.spreadMapEntryElementValueTypeMismatch.withArguments(
            spreadValueType: actualValueType,
            mapValueType: inferredValueType,
          ),
          fileUri: fileUri,
          fileOffset: entry.expression.fileOffset,
          length: 1,
        );
      }
      if (spreadType.isPotentiallyNullable &&
          spreadType is! DynamicType &&
          spreadType is! NullType &&
          !entry.isNullAware) {
        Expression receiver = entry.expression;
        keyError = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.nullableSpreadError,
          fileUri: fileUri,
          fileOffset: receiver.fileOffset,
          length: 1,
          context: getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(
              flowAnalysis.getExpressionInfo(receiver),
            )(),
            entry,
            // Coverage-ignore(suite): Not run.
            (type) => !type.isPotentiallyNullable,
          ),
        );
        _copyNonPromotionReasonToReplacement(entry, keyError);
      }
      if (keyError != null || valueError != null) {
        keyError ??= new NullLiteral();
        valueError ??= new NullLiteral();
        replacement = new MapLiteralEntry(keyError, valueError)
          ..fileOffset = entry.fileOffset;
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
      Nullability.nonNullable,
      <DartType>[actualKeyType, actualValueType],
    );

    bool isMap = typeSchemaEnvironment.isSubtypeOf(
      spreadType,
      coreTypes.mapRawType(Nullability.nullable),
    );
    bool isIterable = typeSchemaEnvironment.isSubtypeOf(
      spreadType,
      coreTypes.iterableRawType(Nullability.nullable),
    );
    if (isMap && !isIterable) {
      offsets.mapSpreadOffset = entry.fileOffset;
    }
    if (!isMap && isIterable) {
      offsets.iterableSpreadOffset = entry.expression.fileOffset;
    }

    return replacement;
  }

  NullAwareMapEntry _inferNullAwareMapEntry(
    NullAwareMapEntry entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    DartType adjustedInferredKeyType = entry.isKeyNullAware
        ? inferredKeyType.withDeclaredNullability(Nullability.nullable)
        : inferredKeyType;
    ExpressionInferenceResult keyInferenceResult = inferExpression(
      entry.key,
      adjustedInferredKeyType,
      isVoidAllowed: true,
    );
    Expression key = ensureAssignableResult(
      adjustedInferredKeyType,
      keyInferenceResult,
      isVoidAllowed: inferredKeyType is VoidType,
    ).expression;
    entry.key = key..parent = entry;

    flowAnalysis.nullAwareMapEntry_valueBegin(
      flowAnalysis.getExpressionInfo(key),
      new SharedTypeView(keyInferenceResult.inferredType),
      isKeyNullAware: entry.isKeyNullAware,
    );

    DartType adjustedInferredValueType = entry.isValueNullAware
        ? inferredValueType.withDeclaredNullability(Nullability.nullable)
        : inferredValueType;
    ExpressionInferenceResult valueInferenceResult = inferExpression(
      entry.value,
      adjustedInferredValueType,
    );
    Expression value = ensureAssignableResult(
      adjustedInferredValueType,
      valueInferenceResult,
      isVoidAllowed: inferredValueType is VoidType,
    ).expression;
    entry.value = value..parent = entry;

    actualTypes.add(
      entry.isKeyNullAware
          ? computeNonNull(keyInferenceResult.inferredType)
          : keyInferenceResult.inferredType,
    );
    actualTypes.add(
      entry.isValueNullAware
          ? computeNonNull(valueInferenceResult.inferredType)
          : valueInferenceResult.inferredType,
    );
    actualTypesForSet.add(const DynamicType());

    offsets.mapEntryOffset = entry.fileOffset;

    flowAnalysis.nullAwareMapEntry_end(isKeyNullAware: entry.isKeyNullAware);

    return entry;
  }

  MapLiteralEntry _inferIfMapEntry(
    IfMapEntry entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    flowAnalysis.ifStatement_conditionBegin();
    DartType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult conditionResult = inferExpression(
      entry.condition,
      boolType,
      isVoidAllowed: false,
    );
    Expression condition = ensureAssignableResult(
      boolType,
      conditionResult,
    ).expression;
    entry.condition = condition..parent = entry;
    flowAnalysis.ifStatement_thenBegin(
      flowAnalysis.getExpressionInfo(condition),
      entry,
    );
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
      offsets,
    );
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
        offsets,
      );
      int length = actualTypes.length;
      actualTypes[length - 2] = typeSchemaEnvironment.getStandardUpperBound(
        actualKeyType,
        actualTypes[length - 2],
      );
      actualTypes[length - 1] = typeSchemaEnvironment.getStandardUpperBound(
        actualValueType,
        actualTypes[length - 1],
      );
      int lengthForSet = actualTypesForSet.length;
      actualTypesForSet[lengthForSet - 1] = typeSchemaEnvironment
          .getStandardUpperBound(
            actualTypeForSet,
            actualTypesForSet[lengthForSet - 1],
          );
      entry.otherwise = otherwise..parent = entry;
    }
    flowAnalysis.ifStatement_end(entry.otherwise != null);
    return entry;
  }

  MapLiteralEntry _inferIfCaseMapEntry(
    IfCaseMapEntry entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    int? stackBase;
    assert(checkStackBase(entry, stackBase = stackHeight));

    MapEntryInferenceContext context = new MapEntryInferenceContext(
      inferredKeyType: inferredKeyType,
      inferredValueType: inferredValueType,
      spreadContext: spreadContext,
      actualTypes: actualTypes,
      actualTypesForSet: actualTypesForSet,
      offsets: offsets,
      inferredSpreadTypes: inferredSpreadTypes,
      inferredConditionTypes: inferredConditionTypes,
    );
    IfCaseStatementResult<InvalidExpression> analysisResult =
        analyzeIfCaseElement(
          node: entry,
          expression: entry.expression,
          pattern: entry.internalPatternGuard.pattern,
          variables: {
            for (InternalVariable variable
                in entry.internalPatternGuard.pattern.declaredVariables)
              variable.cosmeticName!: variable,
          },
          guard: entry.internalPatternGuard.guard,
          ifTrue: entry.then,
          ifFalse: entry.otherwise,
          context: context,
        );
    if (entry.otherwise != null) {
      DartType actualValueType = actualTypes.removeLast();
      DartType actualKeyType = actualTypes.removeLast();
      int length = actualTypes.length;
      actualTypes[length - 2] = typeSchemaEnvironment.getStandardUpperBound(
        actualKeyType,
        actualTypes[length - 2],
      );
      actualTypes[length - 1] = typeSchemaEnvironment.getStandardUpperBound(
        actualValueType,
        actualTypes[length - 1],
      );
      DartType actualTypeForSet = actualTypesForSet.removeLast();
      int lengthForSet = actualTypesForSet.length;
      actualTypesForSet[lengthForSet - 1] = typeSchemaEnvironment
          .getStandardUpperBound(
            actualTypeForSet,
            actualTypesForSet[lengthForSet - 1],
          );
    }

    entry.matchedValueType = analysisResult.matchedExpressionType
        .unwrapTypeView();

    assert(
      checkStack(entry, stackBase, [
        /* ifFalse = */ unionOfKinds([
          ValueKinds.MapLiteralEntryOrNull,
          ValueKinds.ExpressionOrNull,
        ]),
        /* ifTrue = */ unionOfKinds([
          ValueKinds.MapLiteralEntry,
          ValueKinds.Expression,
        ]),
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern = */ ValueKinds.Pattern,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    Object? rewrite = popRewrite(NullValues.Expression);
    if (!identical(entry.otherwise, rewrite)) {
      // Coverage-ignore-block(suite): Not run.
      entry.otherwise = (rewrite as MapLiteralEntry?)?..parent = entry;
    }

    rewrite = popRewrite();
    if (!identical(entry.then, rewrite)) {
      // Coverage-ignore-block(suite): Not run.
      entry.then = (rewrite as MapLiteralEntry)..parent = entry;
    }

    InternalPatternGuard patternGuard = entry.internalPatternGuard;
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
    entry.patternGuard = extern.createPatternGuard(
      pattern: pattern,
      guard: guard,
      fileOffset: patternGuard.fileOffset,
    );

    rewrite = popRewrite();
    if (!identical(entry.expression, rewrite)) {
      entry.expression = (rewrite as Expression)..parent = patternGuard;
    }

    return entry;
  }

  MapLiteralEntry _inferPatternForMapEntry(
    PatternForMapEntry entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    int? stackBase;
    assert(checkStackBase(entry, stackBase = stackHeight));

    InternalPatternVariableDeclaration patternVariableDeclaration =
        entry.internalPatternVariableDeclaration;
    PatternVariableDeclarationAnalysisResult analysisResult =
        analyzePatternVariableDeclaration(
          patternVariableDeclaration,
          patternVariableDeclaration.pattern,
          patternVariableDeclaration.initializer,
          isFinal: patternVariableDeclaration.isFinal,
        );
    DartType matchedValueType = analysisResult.initializerType.unwrapTypeView();

    assert(
      checkStack(entry, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]),
    );

    Pattern pattern = popRewrite() as Pattern;
    Expression initializer = popRewrite() as Expression;
    entry.patternVariableDeclaration = extern.createPatternVariableDeclaration(
      pattern: pattern,
      initializer: initializer,
      isFinal: patternVariableDeclaration.isFinal,
      matchedValueType: matchedValueType,
      fileOffset: patternVariableDeclaration.fileOffset,
    );

    List<Variable> declaredVariables = pattern.declaredVariables;
    assert(declaredVariables.length == entry.intermediateVariables.length);
    assert(declaredVariables.length == entry.internalVariables.length);
    for (int i = 0; i < declaredVariables.length; i++) {
      DartType type = declaredVariables[i].type;

      InternalVariable intermediateVariable =
          entry.intermediateVariables[i].variable;
      intermediateVariable.astVariable.initializer = inferExpression(
        intermediateVariable.astVariable.initializer!,
        type,
        isVoidAllowed: true,
      ).expression..parent = intermediateVariable.astVariable;
      intermediateVariable.type = type;

      entry.internalVariables[i].variable.type = type;
    }

    return _inferForMapEntryBase(
      entry,
      parent,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredSpreadTypes,
      inferredConditionTypes,
      offsets,
    );
  }

  MapLiteralEntry _inferForMapEntry(
    ForMapEntry entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    return _inferForMapEntryBase(
      entry,
      parent,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredSpreadTypes,
      inferredConditionTypes,
      offsets,
    );
  }

  MapLiteralEntry _inferForMapEntryBase(
    ForMapEntryBase entry,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    List<VariableDeclaration> variables = new List.filled(
      entry.internalVariables.length,
      dummyVariableDeclaration,
      growable: true,
    );
    for (int index = 0; index < entry.internalVariables.length; index++) {
      InternalVariableDeclaration variableDeclaration =
          entry.internalVariables[index];
      Variable variable = variableDeclaration.variable.astVariable;

      if (variable.cosmeticName == null) {
        if (variable.initializer != null) {
          ExpressionInferenceResult result = inferExpression(
            variable.initializer!,
            variable.type,
            isVoidAllowed: true,
          );
          variable.initializer = result.expression..parent = variable;
          variable.type = result.inferredType;
        }
        variables[index] = createVariableDeclaration(variable);
      } else {
        VariableDeclarationInferenceResult variableResult =
            inferVariableDeclaration(variableDeclaration);
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
    entry.variables = variables;

    flowAnalysis.for_conditionBegin(entry);
    if (entry.condition != null) {
      ExpressionInferenceResult conditionResult = inferExpression(
        entry.condition!,
        coreTypes.boolRawType(Nullability.nonNullable),
        isVoidAllowed: false,
      );
      Expression condition = ensureAssignable(
        coreTypes.boolRawType(Nullability.nonNullable),
        conditionResult.inferredType,
        conditionResult.expression,
      );
      entry.condition = condition..parent = entry;
      inferredConditionTypes[entry.condition!] = conditionResult.inferredType;
    }
    flowAnalysis.for_bodyBegin(null, switch (entry.condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => flowAnalysis.getExpressionInfo(condition),
    });
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
      offsets,
    );
    entry.body = body..parent = entry;
    flowAnalysis.for_updaterBegin();
    for (int index = 0; index < entry.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
        entry.updates[index],
        const UnknownType(),
        isVoidAllowed: true,
      );
      entry.updates[index] = updateResult.expression..parent = entry;
    }
    flowAnalysis.for_end();
    return entry;
  }

  MapLiteralEntry _inferForInMapEntry(
    ForInMapEntry node,
    TreeNode parent,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<TreeNode, DartType> inferredSpreadTypes,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      // Coverage-ignore-block(suite): Not run.
      // [ForInMapEntry] will be desugared later into a [ForStatement], which
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
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
    Variable variable = node.variable = result.loopVariable;
    node.iterable = result.iterable..parent = node;

    flowAnalysis.forEach_bodyBegin(node);

    InternalVariable? declaredVariable = result.declaredVariable;
    if (declaredVariable != null) {
      flowAnalysis.declare(
        declaredVariable,
        new SharedTypeView(declaredVariable.type),
        initialized: true,
      );
      if (isClosureContextLoweringEnabled) {
        // Coverage-ignore-block(suite): Not run.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          declaredVariable.astVariable,
          captureKind: _captureKindForVariable(declaredVariable),
        );
      }
    }
    if (isClosureContextLoweringEnabled) {
      // Coverage-ignore-block(suite): Not run.
      if (declaredVariable?.astVariable != variable) {
        // [variable] is synthesized.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          variable,
          captureKind: CaptureKind.notCaptured,
        );
      }
    }
    node.encoding = result.computeEncoding();

    // Actual types are added by the recursive call.
    MapLiteralEntry body = inferMapEntry(
      node.body,
      node,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredSpreadTypes,
      inferredConditionTypes,
      offsets,
    );
    node.body = body..parent = node;
    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();
    if (scopeProviderInfo != null) {
      // Coverage-ignore-block(suite): Not run.
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      // The scope will later be passed to the [ForInStatement] the [entry]
      // is desugared into.
      node.scope = scopeProviderInfo.scope;
    }
    return node;
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
    _MapLiteralEntryOffsets offsets,
  ) {
    if (entry is ControlFlowMapEntry) {
      switch (entry) {
        case SpreadMapEntry():
          return _inferSpreadMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
        case NullAwareMapEntry():
          return _inferNullAwareMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
        case IfMapEntry():
          return _inferIfMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
        case IfCaseMapEntry():
          return _inferIfCaseMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
        case ForMapEntry():
          return _inferForMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
        case PatternForMapEntry():
          return _inferPatternForMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
        case ForInMapEntry():
          return _inferForInMapEntry(
            entry,
            parent,
            inferredKeyType,
            inferredValueType,
            spreadContext,
            actualTypes,
            actualTypesForSet,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
      }
    } else {
      ExpressionInferenceResult keyResult = inferExpression(
        entry.key,
        inferredKeyType,
        isVoidAllowed: true,
      );
      Expression key = ensureAssignableResult(
        inferredKeyType,
        keyResult,
        isVoidAllowed: inferredKeyType is VoidType,
      ).expression;
      entry.key = key..parent = entry;
      ExpressionInferenceResult valueResult = inferExpression(
        entry.value,
        inferredValueType,
        isVoidAllowed: true,
      );
      Expression value = ensureAssignableResult(
        inferredValueType,
        valueResult,
        isVoidAllowed: inferredValueType is VoidType,
      ).expression;
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
    _MapLiteralEntryOffsets offsets,
  ) {
    // It's disambiguated as a map literal.
    MapLiteralEntry replacement = entry;
    if (offsets.iterableSpreadOffset != null) {
      replacement = new MapLiteralEntry(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.spreadMapEntryTypeMismatch.withArguments(
            spreadType: offsets.iterableSpreadType!,
          ),
          fileUri: fileUri,
          fileOffset: offsets.iterableSpreadOffset!,
          length: 1,
        ),
        new NullLiteral(),
      )..fileOffset = offsets.iterableSpreadOffset!;
    }
    if (entry is ControlFlowMapEntry) {
      switch (entry) {
        case SpreadMapEntry():
          DartType? spreadType = inferredSpreadTypes[entry.expression];
          if (spreadType is DynamicType) {
            Expression expression = ensureAssignable(
              coreTypes.mapRawType(
                entry.isNullAware
                    ? Nullability.nullable
                    : Nullability.nonNullable,
              ),
              spreadType,
              entry.expression,
            );
            entry.expression = expression..parent = entry;
          }
        case IfMapEntry():
          MapLiteralEntry then = checkMapEntry(
            entry.then,
            keyType,
            valueType,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
          entry.then = then..parent = entry;
          if (entry.otherwise != null) {
            MapLiteralEntry otherwise = checkMapEntry(
              entry.otherwise!,
              keyType,
              valueType,
              inferredSpreadTypes,
              inferredConditionTypes,
              offsets,
            );
            entry.otherwise = otherwise..parent = entry;
          }
        case ForMapEntry():
          MapLiteralEntry body = checkMapEntry(
            entry.body,
            keyType,
            valueType,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
          entry.body = body..parent = entry;
        case PatternForMapEntry():
          MapLiteralEntry body = checkMapEntry(
            entry.body,
            keyType,
            valueType,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
          entry.body = body..parent = entry;
        case ForInMapEntry():
          MapLiteralEntry body = checkMapEntry(
            entry.body,
            keyType,
            valueType,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
          entry.body = body..parent = entry;
        case IfCaseMapEntry():
          MapLiteralEntry then = checkMapEntry(
            entry.then,
            keyType,
            valueType,
            inferredSpreadTypes,
            inferredConditionTypes,
            offsets,
          );
          entry.then = then..parent = entry;
          if (entry.otherwise != null) {
            MapLiteralEntry otherwise = checkMapEntry(
              entry.otherwise!,
              keyType,
              valueType,
              inferredSpreadTypes,
              inferredConditionTypes,
              offsets,
            );
            entry.otherwise = otherwise..parent = entry;
          }
        case NullAwareMapEntry():
        // Do nothing.  Assignability checks are done during type inference.
      }
    } else {
      // Do nothing.  Assignability checks are done during type inference.
    }
    return replacement;
  }

  @override
  ExpressionInferenceResult visitMapLiteral(
    MapLiteral node,
    DartType typeContext,
  ) {
    Class mapClass = coreTypes.mapClass;
    InterfaceType mapType = coreTypes.thisInterfaceType(
      mapClass,
      Nullability.nonNullable,
    );
    List<DartType>? inferredTypes;
    DartType inferredKeyType;
    DartType inferredValueType;

    assert(
      (node.keyType is ImplicitTypeArgument) ==
          (node.valueType is ImplicitTypeArgument),
    );
    bool inferenceNeeded = node.keyType is ImplicitTypeArgument;
    bool typeContextIsMap = node.keyType is! ImplicitTypeArgument;
    DartType? typeContextAsIterable;
    DartType? unfuturedTypeContext = typeSchemaEnvironment.flatten(typeContext);
    // Ambiguous set/map literal
    if (unfuturedTypeContext is TypeDeclarationType) {
      if (!typeContextIsMap) {
        // TODO(johnniwinther): Can we use the found type arguments instead of
        // the inferred types?
        typeContextIsMap =
            hierarchyBuilder.getTypeArgumentsAsInstanceOf(
              unfuturedTypeContext,
              coreTypes.mapClass,
            ) !=
            null;
      }
      typeContextAsIterable = hierarchyBuilder.getTypeAsInstanceOf(
        unfuturedTypeContext,
        coreTypes.iterableClass,
      );
      if (node.entries.isEmpty &&
          typeContextAsIterable != null &&
          !typeContextIsMap) {
        // Set literal
        SetLiteral setLiteral = new SetLiteral(
          [],
          typeArgument: const ImplicitTypeArgument(),
          isConst: node.isConst,
        )..fileOffset = node.fileOffset;
        return visitSetLiteral(setLiteral, typeContext);
      }
    }

    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];
    List<DartType> actualTypesForSet = [];
    Map<TreeNode, DartType> inferredSpreadTypes =
        new Map<TreeNode, DartType>.identity();
    Map<Expression, DartType> inferredConditionTypes =
        new Map<Expression, DartType>.identity();
    TypeConstraintGatherer? gatherer;
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(mapClass.typeParameters);
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    mapType = freshTypeParameters.substitute(mapType) as InterfaceType;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
        mapType,
        typeParametersToInfer,
        typeContext,
        isConst: node.isConst,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        typeOperations: operations,
        inferenceResultForTesting: dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.typeInferenceResult,
        treeNodeForTesting: node,
      );
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        /* previouslyInferredTypes= */ null,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: node,
        typeOperations: operations,
      );
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
    DartType spreadTypeContext = const UnknownType();
    if (typeContextAsIterable != null && !typeContextIsMap) {
      spreadTypeContext = typeContextAsIterable;
    } else if (typeContextAsIterable == null && typeContextIsMap) {
      spreadTypeContext = new InterfaceType(
        coreTypes.mapClass,
        Nullability.nonNullable,
        <DartType>[inferredKeyType, inferredValueType],
      );
    }
    for (int index = 0; index < node.entries.length; ++index) {
      MapLiteralEntry entry = inferMapEntry(
        node.entries[index],
        node,
        inferredKeyType,
        inferredValueType,
        spreadTypeContext,
        actualTypes,
        actualTypesForSet,
        inferredSpreadTypes,
        inferredConditionTypes,
        offsets,
      );
      node.entries[index] = entry..parent = node;
      if (inferenceNeeded) {
        formalTypes.add(mapType.typeArguments[0]);
        formalTypes.add(mapType.typeArguments[1]);
      }
    }
    hasMapEntry = offsets.mapEntryOffset != null;
    hasMapSpread = offsets.mapSpreadOffset != null;
    hasIterableSpread = offsets.iterableSpreadOffset != null;
    if (inferenceNeeded) {
      bool canBeSet = !hasMapSpread && !hasMapEntry && !typeContextIsMap;
      bool canBeMap = !hasIterableSpread && typeContextAsIterable == null;
      if (canBeSet && !canBeMap) {
        List<Expression> setElements = <Expression>[];
        List<DartType> formalTypesForSet = <DartType>[];
        InterfaceType setType = coreTypes.thisInterfaceType(
          coreTypes.setClass,
          Nullability.nonNullable,
        );
        FreshStructuralParametersFromTypeParameters freshTypeParameters =
            getFreshStructuralParametersFromTypeParameters(
              coreTypes.setClass.typeParameters,
            );
        List<StructuralParameter> typeParametersToInfer =
            freshTypeParameters.freshTypeParameters;
        setType = freshTypeParameters.substitute(setType) as InterfaceType;
        for (int i = 0; i < node.entries.length; ++i) {
          setElements.add(
            convertToElement(
              node.entries[i],
              assignedVariables.reassignInfo,
              actualType: actualTypesForSet[i],
            ),
          );
          formalTypesForSet.add(setType.typeArguments[0]);
        }

        // Note: we don't use the previously created gatherer because it was set
        // up presuming that the literal would be a map; we now know that it
        // needs to be a set.
        TypeConstraintGatherer gatherer = typeSchemaEnvironment
            .setupGenericTypeInference(
              setType,
              typeParametersToInfer,
              typeContext,
              isConst: node.isConst,
              inferenceUsingBoundsIsEnabled:
                  libraryFeatures.inferenceUsingBounds.isEnabled,
              typeOperations: operations,
              inferenceResultForTesting: dataForTesting
                  // Coverage-ignore(suite): Not run.
                  ?.typeInferenceResult,
              treeNodeForTesting: node,
            );
        List<DartType> inferredTypesForSet = typeSchemaEnvironment
            .choosePreliminaryTypes(
              gatherer.computeConstraints(),
              typeParametersToInfer,
              /* previouslyInferredTypes= */ null,
              inferenceUsingBoundsIsEnabled:
                  libraryFeatures.inferenceUsingBounds.isEnabled,
              dataForTesting: dataForTesting,
              treeNodeForTesting: node,
              typeOperations: operations,
            );
        gatherer.constrainArguments(
          formalTypesForSet,
          actualTypesForSet,
          treeNodeForTesting: node,
        );
        inferredTypesForSet = typeSchemaEnvironment.chooseFinalTypes(
          gatherer.computeConstraints(),
          typeParametersToInfer,
          inferredTypesForSet,
          inferenceUsingBoundsIsEnabled:
              libraryFeatures.inferenceUsingBounds.isEnabled,
          dataForTesting: dataForTesting,
          treeNodeForTesting: node,
          typeOperations: operations,
        );
        DartType inferredTypeArgument = inferredTypesForSet[0];

        SetLiteral setLiteral = new SetLiteral(
          setElements,
          typeArgument: inferredTypeArgument,
          isConst: node.isConst,
        )..fileOffset = node.fileOffset;
        for (Expression element in setLiteral.expressions) {
          if (element is ControlFlowElement) {
            checkElement(
              element,
              setLiteral,
              setLiteral.typeArgument,
              inferredSpreadTypes,
              inferredConditionTypes,
            );
          }
        }

        Expression result = _translateSetLiteral(setLiteral);
        DartType inferredType = new InterfaceType(
          coreTypes.setClass,
          Nullability.nonNullable,
          inferredTypesForSet,
        );
        return new ExpressionInferenceResult(inferredType, result);
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        Expression replacement = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.cantDisambiguateNotEnoughInformation,
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: 1,
        );
        return new ExpressionInferenceResult(
          NeverType.fromNullability(Nullability.nonNullable),
          replacement,
        );
      }
      if (!canBeSet && !canBeMap) {
        Expression replacement = problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.cantDisambiguateAmbiguousInformation,
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: 1,
        );
        return new ExpressionInferenceResult(
          NeverType.fromNullability(Nullability.nonNullable),
          replacement,
        );
      }
      gatherer!.constrainArguments(
        formalTypes,
        actualTypes,
        treeNodeForTesting: node,
      );
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        inferredTypes!,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: node,
        typeOperations: operations,
      );
      if (dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        dataForTesting!.typeInferenceResult.inferredTypeArguments[node] =
            inferredTypes;
      }
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
      node.keyType = inferredKeyType;
      node.valueType = inferredValueType;
    }
    for (int index = 0; index < node.entries.length; ++index) {
      MapLiteralEntry entry = checkMapEntry(
        node.entries[index],
        node.keyType,
        node.valueType,
        inferredSpreadTypes,
        inferredConditionTypes,
        offsets,
      );
      node.entries[index] = entry..parent = node;
    }
    DartType inferredType = new InterfaceType(
      mapClass,
      Nullability.nonNullable,
      [inferredKeyType, inferredValueType],
    );
    SourceLibraryBuilder library = libraryBuilder;
    // Either both [_declaredKeyType] and [_declaredValueType] are omitted or
    // none of them, so we may just check one.
    if (inferenceNeeded) {
      if (!library.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(node.keyType, node.fileOffset);
        checkGenericFunctionTypeArgument(node.valueType, node.fileOffset);
      }
    }

    Expression result = _translateMapLiteral(node);
    return new ExpressionInferenceResult(inferredType, result);
  }

  /// Convert [entry] to an [Expression], if possible. If [entry] cannot be
  /// converted an error reported through [helper] and an invalid expression is
  /// returned.
  ///
  /// [onConvertMapEntry] is called when a [ForMapEntry], [ForInMapEntry], or
  /// [IfMapEntry] is converted to a [ForElement], [ForInElement], or
  /// [IfElement], respectively.
  Expression convertToElement(
    MapLiteralEntry entry,
    void Function(TreeNode from, TreeNode to) onConvertMapEntry, {
    DartType? actualType,
  }) {
    if (entry is ControlFlowMapEntry) {
      switch (entry) {
        case SpreadMapEntry():
          return new SpreadElement(
              entry.expression,
              isNullAware: entry.isNullAware,
            )
            ..elementType = actualType
            ..fileOffset = entry.expression.fileOffset;
        case IfMapEntry():
          IfElement result = new IfElement(
            entry.condition,
            convertToElement(entry.then, onConvertMapEntry),
            entry.otherwise == null
                ? null
                :
                  // Coverage-ignore(suite): Not run.
                  convertToElement(entry.otherwise!, onConvertMapEntry),
          )..fileOffset = entry.fileOffset;
          onConvertMapEntry(entry, result);
          return result;
        case NullAwareMapEntry():
          // Coverage-ignore(suite): Not run.
          return _convertToErroneousElement(entry);
        case IfCaseMapEntry():
          IfCaseElement result =
              new IfCaseElement(
                  prelude: entry.prelude,
                  expression: entry.expression,
                  internalPatternGuard: entry.internalPatternGuard,
                  then: convertToElement(entry.then, onConvertMapEntry),
                  otherwise: entry.otherwise == null
                      ? null
                      :
                        // Coverage-ignore(suite): Not run.
                        convertToElement(entry.otherwise!, onConvertMapEntry),
                )
                ..matchedValueType = entry.matchedValueType
                ..patternGuard = entry.patternGuard
                ..fileOffset = entry.fileOffset;
          onConvertMapEntry(entry, result);
          return result;
        case PatternForMapEntry():
          PatternForElement result =
              new PatternForElement(
                  internalPatternVariableDeclaration:
                      entry.internalPatternVariableDeclaration,
                  intermediateVariables: entry.intermediateVariables,
                  internalVariables: entry.internalVariables,
                  condition: entry.condition,
                  updates: entry.updates,
                  body: convertToElement(entry.body, onConvertMapEntry),
                )
                ..patternVariableDeclaration = entry.patternVariableDeclaration
                ..variables = entry.variables
                ..fileOffset = entry.fileOffset;
          onConvertMapEntry(entry, result);
          return result;
        case ForMapEntry():
          ForElement result =
              new ForElement(
                  entry.internalVariables,
                  entry.condition,
                  entry.updates,
                  convertToElement(entry.body, onConvertMapEntry),
                )
                ..variables = entry.variables
                ..fileOffset = entry.fileOffset;
          onConvertMapEntry(entry, result);
          return result;
        case ForInMapEntry():
          ForInElement result = new ForInElement(
            entry.element,
            entry.iterable,
            convertToElement(entry.body, onConvertMapEntry),
            isAsync: entry.isAsync,
            fileOffset: entry.fileOffset,
            forOffset: entry.forOffset,
            encoding: entry.encoding,
          )..variable = entry.variable;
          onConvertMapEntry(entry, result);
          return result;
      }
    } else {
      return _convertToErroneousElement(entry);
    }
  }

  Expression _convertToErroneousElement(MapLiteralEntry entry) {
    Expression key = entry.key;
    if (key is InvalidExpression) {
      Expression value = entry.value;
      if (value is NullLiteral && value.fileOffset == TreeNode.noOffset) {
        // entry arose from an error.  Don't build another error.
        return key;
      }
    }
    // Coverage-ignore(suite): Not run.
    // TODO(johnniwinther): How can this be triggered? This will fail if
    // encountered in top level inference.
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: diag.expectedButGot.withArguments(expected: ','),
      fileUri: fileUri,
      fileOffset: entry.fileOffset,
      length: 1,
    );
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
    );
  }

  @override
  ExpressionInferenceResult visitNot(Not node, DartType typeContext) {
    InterfaceType boolType = coreTypes.boolRawType(Nullability.nonNullable);
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      boolType,
    );
    Expression operand = ensureAssignableResult(
      boolType,
      operandResult,
      fileOffset: node.fileOffset,
    ).expression;
    node.operand = operand..parent = node;
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.logicalNot_end(flowAnalysis.getExpressionInfo(node.operand)),
    );
    return new ExpressionInferenceResult(boolType, node);
  }

  @override
  ExpressionInferenceResult visitNullCheck(
    NullCheck node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult operandResult = inferExpression(
      node.operand,
      computeNullable(typeContext),
      continueNullShorting: true,
    );

    Expression operand = operandResult.expression;
    DartType operandType = operandResult.inferredType;

    node.operand = operand..parent = node;
    flowAnalysis.nonNullAssert_end(
      flowAnalysis.getExpressionInfo(node.operand),
    );
    DartType nonNullableResultType = operations
        .promoteToNonNull(new SharedTypeView(operandType))
        .unwrapTypeView();
    return new ExpressionInferenceResult(nonNullableResultType, node);
  }

  ExpressionInferenceResult visitStaticIncDec(
    StaticIncDec node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult readResult = inferStaticGet(
      member: node.getter,
      typeContext: typeContext,
      nameOffset: node.nameOffset,
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
      node.operatorOffset,
      writeContext,
      read,
      readType,
      node.isInc ? plusName : minusName,
      createIntLiteral(coreTypes, 1, fileOffset: node.operatorOffset),
      null,
    );
    DartType binaryType = binaryResult.inferredType;

    ExpressionInferenceResult writeResult = inferStaticSet(
      member: node.setter,
      rhsResult: binaryResult,
      writeContext: writeContext,
      assignOffset: node.operatorOffset,
      nameOffset: node.nameOffset,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable,
        createLet(writeVariable, createVariableGet(valueVariable)),
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

  ExpressionInferenceResult visitSuperIncDec(
    SuperIncDec node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult readResult = inferSuperPropertyGet(
      name: node.name,
      typeContext: const UnknownType(),
      member: node.getter,
      nameOffset: node.nameOffset,
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
      node.operatorOffset,
      writeType,
      read,
      readType,
      node.isInc ? plusName : minusName,
      createIntLiteral(coreTypes, 1, fileOffset: node.operatorOffset),
      null,
    );
    DartType binaryType = binaryResult.inferredType;

    ExpressionInferenceResult writeResult = inferSuperPropertySet(
      name: node.name,
      member: node.setter,
      rhsResult: binaryResult,
      writeContext: writeType,
      assignOffset: node.operatorOffset,
      nameOffset: node.nameOffset,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable,
        createLet(writeVariable, createVariableGet(valueVariable)),
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
      node.operatorOffset,
      writeContext,
      read,
      readType,
      node.isInc ? plusName : minusName,
      createIntLiteral(coreTypes, 1, fileOffset: node.operatorOffset),
      null,
    );
    DartType binaryType = binaryResult.inferredType;

    ExpressionInferenceResult writeResult = inferVariableSet(
      variable: node.variable,
      rhsResult: binaryResult,
      variableType: variableType,
      assignOffset: node.operatorOffset,
      nameOffset: node.nameOffset,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable,
        createLet(writeVariable, createVariableGet(valueVariable)),
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
      receiverVariable = createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = receiverType.toNonNull();
      readReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    } else if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      readReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    }

    ExpressionInferenceResult readResult = _computePropertyGet(
      node.nameOffset,
      readReceiver,
      receiverType,
      node.name,
      const UnknownType(),
      isThisReceiver: isThisExpression(node.receiver),
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
      node.operatorOffset,
      writeType,
      read,
      readType,
      node.isInc ? plusName : minusName,
      createIntLiteral(coreTypes, 1, fileOffset: node.fileOffset),
      null,
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
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable,
        createLet(writeVariable, createVariableGet(valueVariable)),
      );
    }

    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = createLet(receiverVariable, replacement);
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
      receiverVariable = createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = receiverType.toNonNull();
      readReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    } else if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      readReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
      writeReceiver = createVariableGet(
        receiverVariable,
        promotedType: receiverType,
      );
    }

    ExpressionInferenceResult readResult = _computePropertyGet(
      node.readOffset,
      readReceiver,
      receiverType,
      node.propertyName,
      const UnknownType(),
      isThisReceiver: isThisExpression(node.receiver),
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
      node.binaryOffset,
      writeType,
      read,
      readType,
      node.binaryName,
      node.value,
      null,
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
    );
    Expression write = writeResult.expression;

    Expression replacement = write;
    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = createLet(receiverVariable, replacement);
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
      receiverVariable = createVariable(receiver, receiverType);
      createNullAwareGuard(receiverVariable);
      receiverType = receiverType.toNonNull();
    } else {
      receiverVariable = createVariable(receiver, receiverType);
    }

    Expression readReceiver = createVariableGet(
      receiverVariable,
      promotedType: receiverType,
    );
    Expression writeReceiver = createVariableGet(
      receiverVariable,
      promotedType: receiverType,
    );

    ExpressionInferenceResult readResult = _computePropertyGet(
      node.readOffset,
      readReceiver,
      receiverType,
      node.propertyName,
      const UnknownType(),
      isThisReceiver: isThisExpression(node.receiver),
    ).expressionInferenceResult;

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    flowAnalysis.ifNullExpression_rightBegin(
      flowAnalysis.getExpressionInfo(read),
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
      Expression equalsNull = createEqualsNull(
        read,
        fileOffset: node.fileOffset,
      );
      replacement = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        write,
        new NullLiteral()..fileOffset = node.fileOffset,
        computeNullable(inferredType),
      );
    } else {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
      //
      SyntheticVariable readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(
        createVariableGet(readVariable),
        fileOffset: node.fileOffset,
      );
      VariableGet variableGet = createVariableGet(readVariable);
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
      replacement = createLet(readVariable, conditional);
    }
    if (!node.isNullAware) {
      // When the node is null-aware, the receiver variable is used as a
      // null-aware guard and is automatically inserted by the shorting system.
      // Otherwise, we have to manually insert the receiver variable here.
      replacement = createLet(receiverVariable, replacement);
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
      flowAnalysis.getExpressionInfo(read),
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
      Expression equalsNull = createEqualsNull(
        read,
        fileOffset: node.fileOffset,
      );
      replacement = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        writeResult.expression,
        new NullLiteral()..fileOffset = node.fileOffset,
        computeNullable(inferredType),
      );
    } else {
      // Encode `a ??= b` as:
      //
      //      let v1 = a in v1 == null ? a = b : v1
      //
      SyntheticVariable readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(
        createVariableGet(readVariable),
        fileOffset: node.fileOffset,
      );
      VariableGet variableGet = createVariableGet(readVariable);
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
      replacement = new Let(readVariable, conditional)
        ..fileOffset = node.fileOffset;
    }

    // Forward the expression in cases where flow analysis needs to use the
    // expression information. For example, for keeping the promotion in the
    // following if statement in `if ((x ??= 2) == null) { ... }`.
    flowAnalysis.storeExpressionInfo(
      replacement,
      flowAnalysis.getExpressionInfo(writeResult.expression),
    );

    return new ExpressionInferenceResult(inferredType, replacement);
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
          isThisReceiver: isThisExpression(node.receiver),
        );

    ExpressionInferenceResult indexResult = inferExpression(
      node.index,
      indexType,
      isVoidAllowed: true,
    );

    Expression index = ensureAssignableResult(
      indexType,
      indexResult,
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
    if (!node.forEffect && !isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
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
    ).expression;

    SyntheticVariable? indexVariable;
    if (!node.forEffect && !isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
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
      SyntheticVariable assignmentVariable = createVariable(
        assignment,
        const VoidType(),
      );
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
    ).expression;

    SyntheticVariable? indexVariable;
    if (!isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
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

    SyntheticVariable assignmentVariable = createVariable(
      assignment,
      const VoidType(),
    );
    Expression replacement = createLet(assignmentVariable, returnedValue);
    if (valueVariable != null) {
      replacement = createLet(valueVariable, replacement);
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
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
    ).expression;

    StaticInvocation replacement = createStaticInvocation(
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
    if (!node.forEffect && !isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
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
    ).expression;

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    SyntheticVariable? valueVariable;
    Expression? returnedValue;
    if (node.forEffect) {
      // Returned value is not needed.
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

    StaticInvocation assignment = createStaticInvocation(
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
      SyntheticVariable assignmentVariable = createVariable(
        assignment,
        const VoidType(),
      );
      replacement = createLet(assignmentVariable, returnedValue);
    }
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
    if (isPureExpression(readReceiver)) {
      writeReceiver = clonePureExpression(readReceiver);
    } else {
      receiverVariable = createVariable(readReceiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
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
      isThisReceiver: isThisExpression(node.receiver),
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
        flowAnalysis.whyNotPromoted(flowAnalysis.getExpressionInfo(readIndex));
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      whyNotPromoted: whyNotPromotedIndex,
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
      flowAnalysis.getExpressionInfo(read),
      new SharedTypeView(readType),
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      whyNotPromoted: whyNotPromotedIndex,
    );

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(valueType, valueResult);
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
      valueType,
    );

    Expression inner;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let indexVariable = a in
      //         o[indexVariable] == null ? o.[]=(indexVariable, b) : null
      //
      Expression equalsNull = createEqualsNull(
        read,
        fileOffset: node.testOffset,
      );
      ConditionalExpression conditional = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        write,
        new NullLiteral()..fileOffset = node.testOffset,
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
      SyntheticVariable readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(
        createVariableGet(readVariable),
        fileOffset: node.testOffset,
      );
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      VariableGet variableGet = createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        variableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue!);
      if (valueVariable != null) {
        result = createLet(valueVariable, result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        result,
        variableGet,
        inferredType,
      );
      inner = createLet(readVariable, conditional);
    }
    if (indexVariable != null) {
      inner = createLet(indexVariable, inner);
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
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
    );

    assert(readTarget.isInstanceMember || readTarget.isSuperMember);
    Expression read = new SuperMethodInvocation(
      new ThisExpression(),
      indexGetName,
      new Arguments(<Expression>[readIndex])..fileOffset = node.readOffset,
      readTarget.classMember as Procedure,
    )..fileOffset = node.readOffset;

    flowAnalysis.ifNullExpression_rightBegin(
      flowAnalysis.getExpressionInfo(read),
      new SharedTypeView(readType),
    );
    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(valueType, valueResult);
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
    } else if (isPureExpression(value)) {
      returnedValue = clonePureExpression(value);
    } else {
      valueVariable = createVariable(value, valueResult.inferredType);
      value = createVariableGet(valueVariable);
      returnedValue = createVariableGet(valueVariable);
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
      Expression equalsNull = createEqualsNull(
        read,
        fileOffset: node.testOffset,
      );
      replacement = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        write,
        new NullLiteral()..fileOffset = node.testOffset,
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

      SyntheticVariable readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(
        createVariableGet(readVariable),
        fileOffset: node.testOffset,
      );
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue!);
      if (valueVariable != null) {
        result = createLet(valueVariable, result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        result,
        readVariableGet,
        inferredType,
      );
      replacement = createLet(readVariable, conditional);
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
    receiverType = extensionOnType;

    SyntheticVariable? receiverVariable;
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
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
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
      flowAnalysis.getExpressionInfo(read),
      new SharedTypeView(readType),
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
    );

    ExpressionInferenceResult valueResult = inferExpression(
      node.value,
      valueType,
      isVoidAllowed: true,
    );
    valueResult = ensureAssignableResult(valueType, valueResult);
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
      Expression equalsNull = createEqualsNull(
        read,
        fileOffset: node.testOffset,
      );
      replacement = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        write,
        new NullLiteral()..fileOffset = node.testOffset,
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
      SyntheticVariable readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(
        createVariableGet(readVariable),
        fileOffset: node.testOffset,
      );
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (!identical(nonNullableReadType, readType)) {
        readVariableGet.promotedType = nonNullableReadType;
      }
      Expression result = createLet(writeVariable, returnedValue!);
      if (valueVariable != null) {
        result = createLet(valueVariable, result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        result,
        readVariableGet,
        inferredType,
      );
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
    Expression right, {
    required bool isNot,
  }) {
    ExpressionInfo? equalityInfo = flowAnalysis.getExpressionInfo(left);

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

    Expression? equals;
    if (_isNull(right)) {
      equals = new EqualsNull(left)..fileOffset = fileOffset;
    } else if (_isNull(left)) {
      equals = new EqualsNull(rightResult.expression)..fileOffset = fileOffset;
    }
    if (equals != null) {
      if (isNot) {
        equals = new Not(equals)..fileOffset = fileOffset;
      }
      flowAnalysis.storeExpressionInfo(
        equals,
        flowAnalysis.equalityOperation_end(
          equalityInfo,
          new SharedTypeView(leftType),
          flow.getExpressionInfo(rightResult.expression),
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
    );
    right = rightResult.expression;

    FunctionType functionType = equalsTarget
        .getFunctionType(this)
        .equalsFunctionType;
    equals = new EqualsCall(
      left,
      right,
      functionType: functionType,
      interfaceTarget: equalsTarget.classMember as Procedure,
    )..fileOffset = fileOffset;
    if (isNot) {
      equals = new Not(equals)..fileOffset = fileOffset;
    }

    flowAnalysis.storeExpressionInfo(
      equals,
      flowAnalysis.equalityOperation_end(
        equalityInfo,
        new SharedTypeView(leftType),
        flowAnalysis.getExpressionInfo(right),
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
  ExpressionInferenceResult _computeBinaryExpression(
    int fileOffset,
    DartType contextType,
    Expression left,
    DartType leftType,
    Name binaryName,
    Expression right,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  ) {
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

    rightResult = ensureAssignableResult(rightType, rightResult);
    right = rightResult.expression;

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
          right,
        );
        break;
      case ObjectAccessTargetKind.ambiguous:
        binary = createMissingBinary(
          fileOffset,
          left,
          leftType,
          binaryName,
          right,
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
            <Expression>[left, right],
            types: binaryTarget.receiverTypeArguments,
          )..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.invalid:
        binary = new DynamicInvocation(
          DynamicAccessKind.Invalid,
          left,
          binaryName,
          new Arguments(<Expression>[right])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
        binary = new DynamicInvocation(
          DynamicAccessKind.Dynamic,
          left,
          binaryName,
          new Arguments(<Expression>[right])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.never:
        binary = new DynamicInvocation(
          DynamicAccessKind.Never,
          left,
          binaryName,
          new Arguments(<Expression>[right])..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.superMember:
        binary = new InstanceInvocation(
          InstanceAccessKind.Instance,
          left,
          binaryName,
          new Arguments(<Expression>[right])..fileOffset = fileOffset,
          functionType: new FunctionType(
            [rightType],
            binaryType,
            Nullability.nonNullable,
          ),
          interfaceTarget: binaryTarget.classMember as Procedure,
        )..fileOffset = fileOffset;

        if (binaryCheckKind ==
            MethodContravarianceCheckKind.checkMethodReturn) {
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
        throw new UnsupportedError('Unexpected binary target ${binaryTarget}');
    }

    if (binaryTarget.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        whyNotPromoted?.call(),
        binary,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      return new ExpressionInferenceResult(
        binaryType,
        problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: binary,
          message: diag.nullableOperatorCallError.withArguments(
            operator: binaryName.text,
            receiverType: leftType,
          ),
          fileUri: fileUri,
          fileOffset: binary.fileOffset,
          length: binaryName.text.length,
          context: context,
        ),
      );
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
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted,
  ) {
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
        unary = new InstanceInvocation(
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
        throw new UnsupportedError('Unexpected unary target ${unaryTarget}');
    }

    if (unaryTarget.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        whyNotPromoted(),
        unary,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      // TODO(johnniwinther): Special case 'unary-' in messages. It should
      // probably be referred to as "Unary operator '-' ...".
      return new ExpressionInferenceResult(
        unaryType,
        problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: unary,
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
      );
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
        read = new InstanceInvocation(
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
        throw new UnsupportedError('Unexpected index get target ${readTarget}');
    }

    if (readTarget.isNullable) {
      return new ExpressionInferenceResult(
        readType,
        problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: read,
          message: diag.nullableOperatorCallError.withArguments(
            operator: indexGetName.text,
            receiverType: receiverType,
          ),
          fileUri: fileUri,
          fileOffset: read.fileOffset,
          length: noLength,
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
        throw new UnsupportedError(
          'Unexpected index set target ${writeTarget}',
        );
    }
    if (writeTarget.isNullable) {
      return problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: write,
        message: diag.nullableOperatorCallError.withArguments(
          operator: indexSetName.text,
          receiverType: receiverType,
        ),
        fileUri: fileUri,
        fileOffset: write.fileOffset,
        length: noLength,
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
  PropertyGetInferenceResult _computePropertyGet(
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Name propertyName,
    DartType typeContext, {
    required bool isThisReceiver,
    ObjectAccessTarget? readTarget,
    Expression? propertyGetNode,
  }) {
    Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(flowAnalysis.getExpressionInfo(receiver));

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
    if (propertyGetNode != null) {
      flowAnalysis.storeExpressionInfo(propertyGetNode, expressionInfo);
    }
    DartType? promotedReadType = wrappedPromotedReadType?.unwrapTypeView();
    return createPropertyGet(
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
    );
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
    if (isPureExpression(readReceiver)) {
      writeReceiver = clonePureExpression(readReceiver);
    } else {
      receiverVariable = createVariable(readReceiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
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
          isThisReceiver: isThisExpression(node.receiver),
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
        flowAnalysis.whyNotPromoted(flowAnalysis.getExpressionInfo(readIndex));
    Expression writeIndex;
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
      whyNotPromoted: whyNotPromotedIndex,
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
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
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
      node.binaryOffset,
      valueType,
      left,
      readType,
      node.binaryName,
      node.value,
      null,
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
      whyNotPromoted: whyNotPromotedIndex,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      fileOffset: node.fileOffset,
    );
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    SyntheticVariable? valueVariable;
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      inner = createLet(
        leftVariable!,
        createLet(writeVariable, createVariableGet(leftVariable)),
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      inner = createLet(
        valueVariable!,
        createLet(writeVariable, createVariableGet(valueVariable)),
      );
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
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
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
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
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
      node.binaryOffset,
      valueType,
      left,
      readType,
      node.binaryName,
      node.value,
      null,
    );

    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      fileOffset: node.fileOffset,
    );
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
    );

    SyntheticVariable? valueVariable;
    Expression valueExpression;
    if (node.forEffect || node.forPostIncDec) {
      valueExpression = binary;
    } else {
      valueVariable = createVariable(binary, binaryType);
      valueExpression = createVariableGet(valueVariable);
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        leftVariable!,
        createLet(writeVariable, createVariableGet(leftVariable)),
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable!,
        createLet(writeVariable, createVariableGet(valueVariable)),
      );
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
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
      treeNodeForTesting: node,
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

    receiver = ensureAssignable(extensionOnType, receiverType, receiver);
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
    if (isPureExpression(receiver)) {
      readReceiver = receiver;
      writeReceiver = clonePureExpression(receiver);
    } else {
      receiverVariable = createVariable(receiver, receiverType);
      readReceiver = createVariableGet(receiverVariable);
      writeReceiver = createVariableGet(receiverVariable);
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
    if (isPureExpression(readIndex)) {
      writeIndex = clonePureExpression(readIndex);
    } else {
      indexVariable = createVariable(readIndex, indexResult.inferredType);
      readIndex = createVariableGet(indexVariable);
      writeIndex = createVariableGet(indexVariable);
    }

    readIndex = ensureAssignable(
      readIndexType,
      indexResult.inferredType,
      readIndex,
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
      leftVariable = createVariable(read, readType);
      left = createVariableGet(leftVariable);
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
      node.binaryOffset,
      valueType,
      left,
      readType,
      node.binaryName,
      node.rhs,
      null,
    );

    writeIndex = ensureAssignable(
      writeIndexType,
      indexResult.inferredType,
      writeIndex,
    );
    binaryResult = ensureAssignableResult(
      valueType,
      binaryResult,
      fileOffset: node.fileOffset,
    );
    Expression binary = binaryResult.expression;
    DartType binaryType = binaryResult.inferredType;

    SyntheticVariable? valueVariable;
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        leftVariable!,
        createLet(writeVariable, createVariableGet(leftVariable)),
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        valueVariable!,
        createLet(writeVariable, createVariableGet(valueVariable)),
      );
    }
    if (indexVariable != null) {
      replacement = createLet(indexVariable, replacement);
    }
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(
      node.forPostIncDec ? readType : binaryType,
      replacement,
    );
  }

  @override
  ExpressionInferenceResult visitNullLiteral(
    NullLiteral node,
    DartType typeContext,
  ) {
    const NullType nullType = const NullType();
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.nullLiteral(new SharedTypeView(nullType)),
    );
    return new ExpressionInferenceResult(nullType, node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitLet(Let node, DartType typeContext) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalLet(
    InternalLet node,
    DartType typeContext,
  ) {
    DartType variableType = node.variable.type;
    ExpressionInferenceResult initializerResult = inferExpression(
      node.variable.astVariable.initializer!,
      variableType,
      isVoidAllowed: true,
    );
    SyntheticVariable variable = node.variable.astVariable;
    variable.initializer = initializerResult.expression..parent = variable;
    ExpressionInferenceResult bodyResult = inferExpression(
      node.body,
      typeContext,
      isVoidAllowed: true,
    );
    Expression body = bodyResult.expression..parent = node;
    DartType inferredType = bodyResult.inferredType;
    return new ExpressionInferenceResult(
      inferredType,
      extern.createLet(variable, body, fileOffset: node.fileOffset),
    );
  }

  ExpressionInferenceResult visitAnonymousMethodExpression(
    AnonymousMethodExpression node,
    DartType typeContext,
  ) {
    DartType variableType = node.variable.type;
    ExpressionInferenceResult initializerResult = inferExpression(
      node.variable.astVariable.initializer!,
      const UnknownType(),
      continueNullShorting: true,
    );

    Expression initializer = initializerResult.expression;
    DartType initializerType = initializerResult.inferredType;

    if (initializerType is VoidType) {
      initializer = problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: initializer,
        message: diag.voidExpression,
        fileUri: fileUri,
        fileOffset: initializer.fileOffset,
        length: noLength,
      );
    }

    if (node.isImplicitlyTyped) {
      node.variable.type = node.isNullAware
          ? initializerType.toNonNull()
          : initializerType;
    } else {
      DartType checkedType = node.isNullAware
          ? initializerType.toNonNull()
          : initializerType;
      if (!isAssignable(variableType, checkedType)) {
        initializer = wrapUnassignableExpression(
          initializer,
          checkedType,
          variableType,
          diag.anonymousMethodWrongParameterTypeCfe.withArguments(
            receiverType: checkedType,
            parameterType: variableType,
          ),
          fileOffset: node.typeOffset,
        );
      }
    }
    node.variable.astVariable.initializer = initializer..parent = node.variable;

    flowAnalysis.declare(
      node.variable,
      new SharedTypeView(node.variable.type),
      initialized: false,
    );
    flowAnalysis.initialize(
      node.variable,
      new SharedTypeView(node.variable.type),
      flowAnalysis.getExpressionInfo(node.variable.astVariable.initializer!),
      isFinal: false,
      isLate: false,
      isImplicitlyTyped: node.isImplicitlyTyped,
      inheritPromotableProperties: node.isParameterless,
    );
    if (node.isNullAware) {
      flow.nullAwareAccess_rightBegin(
        flowAnalysis.getExpressionInfo(node.variable.astVariable.initializer!),
        new SharedTypeView(initializerType),
        guardVariable: node.variable,
      );
    }

    if (node.isParameterless) {
      flow.thisBinding_begin(
        flowAnalysis.getExpressionInfo(node.variable.astVariable.initializer!),
      );
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
      inferredType = initializerType;

      SyntheticVariable tempVar = extern.createVariable(
        bodyResult.expression,
        const DynamicType(),
        isFinal: false,
      )..fileOffset = node.fileOffset;

      body = new Let(tempVar, new VariableGet(node.variable.astVariable))
        ..fileOffset = node.fileOffset;
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
        Variable resultVar = extern.createUninitializedVariable(
          type: inferredType,
          fileOffset: node.fileOffset,
        );
        return new BlockExpression(
          new Block([
            extern.createVariableStatement(
              extern.createVariableDeclaration(node.variable.astVariable),
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
        return new Let(node.variable.astVariable, body)
          ..fileOffset = node.fileOffset;
      }
    }

    Expression replacement;
    if (node.isNullAware) {
      SyntheticVariable tempVar = extern.createVariable(
        node.variable.astVariable.initializer!,
        initializerType,
        cosmeticName: "anonymous#receiver",
        isFinal: false,
        fileOffset: node.fileOffset,
      );

      Expression condition = new EqualsNull(new VariableGet(tempVar));
      Expression thenExpression = new NullLiteral();

      node.variable.astVariable.initializer =
          new AsExpression(new VariableGet(tempVar), node.variable.type)
            ..fileOffset = node.fileOffset
            ..parent = node.variable;

      Expression elseExpression = createLetOrBlock();

      replacement = new Let(
        tempVar,
        new ConditionalExpression(
          condition,
          thenExpression,
          elseExpression,
          inferredType.withDeclaredNullability(Nullability.nullable),
        ),
      )..fileOffset = node.fileOffset;

      inferredType = inferredType.withDeclaredNullability(Nullability.nullable);
    } else {
      replacement = createLetOrBlock();
    }

    if (node.isParameterless) {
      flowAnalysis.storeExpressionInfo(
        replacement,
        flowAnalysis.getExpressionInfo(node.body),
      );
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  ExpressionInferenceResult visitAnonymousMethodBlock(
    AnonymousMethodBlock node,
    DartType typeContext,
  ) {
    Variable resultVar = extern.createUninitializedVariable(
      type: const DynamicType(),
      fileOffset: node.fileOffset,
    );
    LabeledStatement label = new LabeledStatement(null)
      ..fileOffset = node.fileOffset;

    AnonymousMethodReturnContext context = new AnonymousMethodReturnContext(
      resultVariable: resultVar,
      label: label,
      typeContext: typeContext,
    );
    _returnContexts.push(context);

    DartType variableType = node.variable.type;
    ExpressionInferenceResult initializerResult = inferExpression(
      node.variable.astVariable.initializer!,
      const UnknownType(),
      continueNullShorting: true,
    );

    Expression initializer = initializerResult.expression;
    DartType initializerType = initializerResult.inferredType;

    if (initializerType is VoidType) {
      initializer = problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: initializer,
        message: diag.voidExpression,
        fileUri: fileUri,
        fileOffset: initializer.fileOffset,
        length: noLength,
      );
    }

    if (node.isImplicitlyTyped) {
      node.variable.type = node.isNullAware
          ? initializerType.toNonNull()
          : initializerType;
    } else {
      DartType checkedType = node.isNullAware
          ? initializerType.toNonNull()
          : initializerType;
      if (!isAssignable(variableType, checkedType)) {
        initializer = wrapUnassignableExpression(
          initializer,
          checkedType,
          variableType,
          diag.anonymousMethodWrongParameterTypeCfe.withArguments(
            receiverType: checkedType,
            parameterType: variableType,
          ),
          fileOffset: node.typeOffset,
        );
      }
    }
    node.variable.astVariable.initializer = initializer..parent = node.variable;

    flowAnalysis.declare(
      node.variable,
      new SharedTypeView(node.variable.type),
      initialized: false,
    );
    flowAnalysis.initialize(
      node.variable,
      new SharedTypeView(node.variable.type),
      flowAnalysis.getExpressionInfo(node.variable.astVariable.initializer!),
      isFinal: false,
      isLate: false,
      isImplicitlyTyped: node.isImplicitlyTyped,
      inheritPromotableProperties: node.isParameterless,
    );
    bool isNullAwareAccess = node.isNullAware && _enclosingCascade == null;
    if (node.isNullAware) {
      Expression receiverExpr = node.variable.astVariable.initializer!;
      SyntheticVariable? tempVar;

      if (isNullAwareAccess) {
        tempVar = extern.createVariable(
          receiverExpr,
          initializerType,
          isFinal: false,
          fileOffset: node.fileOffset,
        );
        receiverExpr = new VariableGet(tempVar);
      }

      node.variable.astVariable.initializer =
          new AsExpression(receiverExpr, node.variable.type)
            ..fileOffset = node.fileOffset
            ..parent = node.variable;

      if (isNullAwareAccess) {
        startNullShorting(
          new NullAwareGuard(tempVar!, node.variable.fileOffset, this),
          flowAnalysis.getExpressionInfo(tempVar.initializer!),
          new SharedTypeView(tempVar.type),
        );
      }
    }

    if (node.isParameterless) {
      flow.thisBinding_begin(
        flowAnalysis.getExpressionInfo(node.variable.astVariable.initializer!),
      );
    }

    flowAnalysis.labeledStatement_begin(label);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    bool isReachable = flowAnalysis.isReachable;
    flowAnalysis.labeledStatement_end();

    if (node.isParameterless) {
      flow.thisBinding_end();
    }

    _returnContexts.pop();

    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
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
      inferredType = initializerType;
    }

    Block block = new Block([
      extern.createVariableStatement(
        extern.createVariableDeclaration(node.variable.astVariable),
      ),
      extern.createVariableStatement(
        extern.createVariableDeclaration(resultVar),
      ),
      label,
    ])..fileOffset = node.fileOffset;

    Expression replacement = new BlockExpression(
      block,
      node.isCascade
          ? new VariableGet(node.variable.astVariable)
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
    );
    Expression replacement = replacementResult.expression;
    DartType replacementType = replacementResult.inferredType;

    return new ExpressionInferenceResult(replacementType, replacement);
  }

  @override
  PropertySetData computePropertySetData({
    required Expression receiver,
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

    receiver = receiverResult.expression;
    DartType receiverType = receiverResult.inferredType;

    if (isNullAware) {
      DartType nonNullReceiverType = receiverType.toNonNull();
      receiver = _createNonNullReceiver(
        receiver,
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
      receiver: receiver,
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
      node.fileOffset,
      receiver,
      receiverType,
      node.name,
      typeContext,
      isThisReceiver: isThisExpression(node.receiver),
      propertyGetNode: node,
    );
    ExpressionInferenceResult readResult =
        propertyGetInferenceResult.expressionInferenceResult;
    ExpressionInferenceResult expressionInferenceResult =
        new ExpressionInferenceResult(
          readResult.inferredType,
          readResult.expression,
        );
    flowAnalysis.storeExpressionInfo(
      expressionInferenceResult.expression,
      flowAnalysis.getExpressionInfo(node),
    );
    return expressionInferenceResult;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRecordIndexGet(
    RecordIndexGet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRecordNameGet(
    RecordNameGet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InitializerInferenceResult visitRedirectingInitializer(
    RedirectingInitializer node,
  ) {
    _unhandledInitializer(node);
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
      result = createInvalidInitializer(
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
    node.inferredTypeArguments = inferenceResult.typeArguments;
    node.positional = inferenceResult.positional;
    node.named = inferenceResult.named;

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
      result = createInvalidInitializer(
        problemReporting.buildProblemFromLocatedMessage(
          compilerContext: compilerContext,
          message: message,
        ),
        isRedirectingInitializer: true,
      );
    }
    return new InitializerInferenceResult.fromInvocationInferenceResult(
      result ?? node,
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
    ).expression;
    node.value = initializer..parent = node;
    return new SuccessfulInitializerInferenceResult(node);
  }

  @override
  ExpressionInferenceResult visitRethrow(Rethrow node, DartType typeContext) {
    flowAnalysis.handleExit();
    return new ExpressionInferenceResult(const NeverType.nonNullable(), node);
  }

  @override
  StatementInferenceResult visitReturnStatement(
    covariant ReturnStatementImpl node,
  ) {
    ReturnContext? context = returnContext;
    if (context is AnonymousMethodReturnContext) {
      Expression expression =
          node.expression ?? (new NullLiteral()..fileOffset = node.fileOffset);
      ExpressionInferenceResult expressionResult = inferExpression(
        expression,
        context.typeContext,
        isVoidAllowed: true,
      );
      context.returnTypes.add(expressionResult.inferredType);

      VariableSet assignment = new VariableSet(
        context.resultVariable,
        expressionResult.expression,
      )..fileOffset = node.fileOffset;
      BreakStatement breakStmt = new BreakStatement(context.label)
        ..fileOffset = node.fileOffset;

      flowAnalysis.handleBreak(context.label);

      Statement replacement = new Block([
        new ExpressionStatement(assignment)..fileOffset = node.fileOffset,
        breakStmt,
      ])..fileOffset = node.fileOffset;

      return new StatementInferenceResult.single(replacement);
    }

    DartType typeContext = bodyContext.returnContext;
    DartType inferredType;
    Variable? thisVariable = _constructorContext?.thisVariable;
    if (bodyContext.isRoot && thisVariable != null) {
      // The constructor is lowered with an explicit variable for `this`. This
      // means that `return;` should be encoded as `return #this;` where `#this`
      // is the [thisVariable].
      node.expression = extern.createVariableGet(
        thisVariable,
        fileOffset: node.fileOffset,
      )..parent = node;
      inferredType = thisVariable.type;
    } else if (node.expression != null) {
      ExpressionInferenceResult expressionResult = inferExpression(
        node.expression!,
        typeContext,
        isVoidAllowed: true,
      );
      node.expression = expressionResult.expression..parent = node;
      inferredType = expressionResult.inferredType;
    } else {
      inferredType = const NullType();
    }
    bodyContext.handleReturn(node, inferredType, node.isArrow);
    flowAnalysis.handleReturn();
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitSetLiteral(
    SetLiteral node,
    DartType typeContext,
  ) {
    Class setClass = coreTypes.setClass;
    InterfaceType setType = coreTypes.thisInterfaceType(
      setClass,
      Nullability.nonNullable,
    );
    List<DartType>? inferredTypes;
    DartType inferredTypeArgument;
    bool inferenceNeeded = node.typeArgument is ImplicitTypeArgument;
    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];
    Map<TreeNode, DartType> inferredSpreadTypes =
        new Map<TreeNode, DartType>.identity();
    Map<Expression, DartType> inferredConditionTypes =
        new Map<Expression, DartType>.identity();
    TypeConstraintGatherer? gatherer;
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(setClass.typeParameters);
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    setType = freshTypeParameters.substitute(setType) as InterfaceType;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
        setType,
        typeParametersToInfer,
        typeContext,
        isConst: node.isConst,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        typeOperations: operations,
        inferenceResultForTesting: dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.typeInferenceResult,
        treeNodeForTesting: node,
      );
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        /* previouslyInferredTypes= */ null,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: node,
        typeOperations: operations,
      );
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    for (int index = 0; index < node.expressions.length; ++index) {
      ExpressionInferenceResult result = inferElement(
        node.expressions[index],
        inferredTypeArgument,
        inferredSpreadTypes,
        inferredConditionTypes,
      );
      node.expressions[index] = result.expression..parent = node;
      actualTypes.add(result.inferredType);
      if (inferenceNeeded) {
        formalTypes.add(setType.typeArguments[0]);
      }
    }

    if (inferenceNeeded) {
      gatherer!.constrainArguments(
        formalTypes,
        actualTypes,
        treeNodeForTesting: node,
      );
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        inferredTypes!,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: node,
        typeOperations: operations,
      );
      if (dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        dataForTesting!.typeInferenceResult.inferredTypeArguments[node] =
            inferredTypes;
      }
      inferredTypeArgument = inferredTypes[0];
      node.typeArgument = inferredTypeArgument;
    }
    for (int i = 0; i < node.expressions.length; i++) {
      Expression element = node.expressions[i];
      if (element is ControlFlowElement) {
        checkElement(
          element,
          node,
          node.typeArgument,
          inferredSpreadTypes,
          inferredConditionTypes,
        );
      }
    }
    DartType inferredType = new InterfaceType(
      setClass,
      Nullability.nonNullable,
      [inferredTypeArgument],
    );
    if (inferenceNeeded) {
      if (!libraryBuilder.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(node.typeArgument, node.fileOffset);
      }
    }

    Expression result = _translateSetLiteral(node);
    return new ExpressionInferenceResult(inferredType, result);
  }

  /// Creates a lowering for [node] for targets that don't support the
  /// [SetLiteral] node.
  Expression _lowerSetLiteral(SetLiteral node) {
    if (libraryBuilder.loader.target.backendTarget.supportsSetLiterals) {
      return node;
    }
    if (node.isConst) {
      // Const set literals are transformed in the constant evaluator.
      return node;
    }

    // Create the set: Set<E> setVar = new Set<E>();
    InterfaceType receiverType;
    Variable setVar = extern.createVariable(
      new StaticInvocation(
        engine.setFactory,
        new Arguments([], types: [node.typeArgument]),
      ),
      receiverType = new InterfaceType(
        coreTypes.setClass,
        Nullability.nonNullable,
        [node.typeArgument],
      ),
    );

    // Now create a list of all statements needed.
    List<Statement> statements = [
      extern.createVariableStatement(extern.createVariableDeclaration(setVar)),
    ];
    for (int i = 0; i < node.expressions.length; i++) {
      Expression entry = node.expressions[i];
      DartType functionType = Substitution.fromInterfaceType(receiverType)
          .substituteType(engine.setAddMethodFunctionType);
      Expression methodInvocation =
          new InstanceInvocation(
              InstanceAccessKind.Instance,
              new VariableGet(setVar),
              new Name("add"),
              new Arguments([entry]),
              functionType: functionType as FunctionType,
              interfaceTarget: engine.setAddMethod,
            )
            ..fileOffset = entry.fileOffset
            ..isInvariant = true;
      statements.add(
        new ExpressionStatement(methodInvocation)
          ..fileOffset = methodInvocation.fileOffset,
      );
    }

    // Finally, return a BlockExpression with the statements, having the value
    // of the (now created) set.
    return new BlockExpression(new Block(statements), new VariableGet(setVar))
      ..fileOffset = node.fileOffset;
  }

  @override
  ExpressionInferenceResult visitStaticSet(
    StaticSet node,
    DartType typeContext,
  ) {
    DartType writeContext = computeStaticSetWriteContext(node.target);
    ExpressionInferenceResult rhsResult = inferExpression(
      node.value,
      writeContext,
      isVoidAllowed: true,
    );
    return inferStaticSet(
      member: node.target,
      rhsResult: rhsResult,
      writeContext: writeContext,
      assignOffset: node.fileOffset,
      nameOffset: node.fileOffset,
      node: node,
    );
  }

  @override
  ExpressionInferenceResult visitStaticGet(
    StaticGet node,
    DartType typeContext,
  ) {
    return inferStaticGet(
      member: node.target,
      typeContext: typeContext,
      nameOffset: node.fileOffset,
      node: node,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitStaticInvocation(
    StaticInvocation node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalStaticInvocation(
    InternalStaticInvocation node,
    DartType typeContext,
  ) {
    FunctionType calleeType = node.target.function.computeFunctionType(
      Nullability.nonNullable,
    );
    ActualArguments arguments = node.arguments;
    InvocationInferenceResult result = inferInvocation(
      this,
      typeContext,
      node.fileOffset,
      new InvocationTargetFunctionType(calleeType),
      node.typeArguments,
      arguments,
      staticTarget: node.target,
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
    Expression replacement = createStaticInvocation(
      node.target,
      createArgumentsFromInternalNode(
        result.typeArguments,
        result.positional,
        result.named,
        arguments,
      ),
      fileOffset: node.fileOffset,
    );
    flowAnalysis.storeExpressionInfo(
      replacement,
      flowAnalysis.getExpressionInfo(node),
    );
    return new ExpressionInferenceResult(
      result.inferredType,
      result.applyResult(replacement),
    );
  }

  @override
  ExpressionInferenceResult visitStringConcatenation(
    StringConcatenation node,
    DartType typeContext,
  ) {
    for (int index = 0; index < node.expressions.length; index++) {
      ExpressionInferenceResult result = inferExpression(
        node.expressions[index],
        const UnknownType(),
        isVoidAllowed: false,
      );
      node.expressions[index] = result.expression..parent = node;
    }
    return new ExpressionInferenceResult(
      coreTypes.stringRawType(Nullability.nonNullable),
      node,
    );
  }

  @override
  ExpressionInferenceResult visitStringLiteral(
    StringLiteral node,
    DartType typeContext,
  ) {
    return new ExpressionInferenceResult(
      coreTypes.stringRawType(Nullability.nonNullable),
      node,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  InitializerInferenceResult visitSuperInitializer(SuperInitializer node) {
    _unhandledInitializer(node);
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
      result = createInvalidInitializer(
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitAbstractSuperMethodInvocation(
    AbstractSuperMethodInvocation node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSuperMethodInvocation(
    SuperMethodInvocation node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitAbstractSuperPropertyGet(
    AbstractSuperPropertyGet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitSuperPropertyGet(
    SuperPropertyGet node,
    DartType typeContext,
  ) {
    if (isClosureContextLoweringEnabled) {
      node.receiver = new VariableGet(internalThisVariable)
        ..fileOffset = node.fileOffset;
    }
    return inferSuperPropertyGet(
      name: node.name,
      typeContext: typeContext,
      member: node.interfaceTarget,
      node: node,
      nameOffset: node.fileOffset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitAbstractSuperPropertySet(
    AbstractSuperPropertySet node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  ExpressionInferenceResult visitSuperPropertySet(
    SuperPropertySet node,
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
    if (isClosureContextLoweringEnabled) {
      node.receiver = new VariableGet(internalThisVariable)
        ..fileOffset = node.fileOffset;
    }
    return inferSuperPropertySet(
      name: node.name,
      member: node.interfaceTarget,
      rhsResult: rhsResult,
      writeContext: writeContext,
      assignOffset: node.fileOffset,
      nameOffset: node.fileOffset,
      node: node,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSwitchExpression(
    SwitchExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, result);
    return new ExpressionInferenceResult(valueType, result);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitSwitchStatement(SwitchStatement node) {
    _unhandledStatement(node);
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
    if (analysisResult.isExhaustive &&
        !analysisResult.hasDefault &&
        shouldThrowUnsoundnessException) {
      // Coverage-ignore-block(suite): Not run.
      if (!analysisResult.lastCaseTerminates) {
        LabeledStatement breakTarget;
        if (node.parent is LabeledStatement) {
          breakTarget = node.parent as LabeledStatement;
        } else {
          replacement = breakTarget = new LabeledStatement(node);
        }

        InternalSwitchStatementCase lastCase = node.cases.last;
        Statement body = lastCase.body;
        if (body is Block) {
          body.addStatement(
            extern.createBreakStatement(
              breakTarget,
              fileOffset: node.fileOffset,
            ),
          );
        }
      }
      cases.add(
        extern.createSwitchCase(
          expressions: [],
          expressionOffsets: [],
          body: _createExpressionStatement(
            createReachabilityError(
              node.fileOffset,
              diag.neverReachableSwitchDefaultError,
            ),
          ),
          isDefault: true,
          fileOffset: node.fileOffset,
        )..parent = replacement,
      );
    }

    assert(checkStack(node, stackBase, [/*empty*/]));

    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitPatternSwitchStatement(
    PatternSwitchStatement node,
  ) {
    _unhandledStatement(node);
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
              jointVariable.initializer = problemReporting.buildProblem(
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
              )..parent = jointVariable;
            }
          }
        }
      }
    }

    return new StatementInferenceResult.single(
      extern.createPatternSwitchStatement(
        expression: expression,
        cases: cases,
        expressionType: expressionType,
        lastCaseTerminates: lastCaseTerminates,
        fileOffset: node.fileOffset,
      ),
    );
  }

  @override
  ExpressionInferenceResult visitSymbolLiteral(
    SymbolLiteral node,
    DartType typeContext,
  ) {
    DartType inferredType = coreTypes.symbolRawType(Nullability.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitThisExpression(
    ThisExpression node,
    DartType typeContext,
  ) {
    DartType thisType =
        flowAnalysis.promotedTypeOfThis
                // Coverage-ignore(suite): Not run.
                ?.unwrapTypeView()
            as DartType? ??
        this.thisType!;
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.thisOrSuper(new SharedTypeView(thisType), isSuper: false),
    );
    if (isClosureContextLoweringEnabled) {
      return new ExpressionInferenceResult(
        thisType,
        new VariableGet(_contextAllocationStrategy.thisVariable)
          ..fileOffset = node.fileOffset,
      );
    } else {
      return new ExpressionInferenceResult(thisType, node);
    }
  }

  @override
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    ExpressionInferenceResult expressionResult = inferExpression(
      node.expression,
      coreTypes.objectNonNullableRawType,
      isVoidAllowed: false,
    );
    node.expression = expressionResult.expression..parent = node;
    flowAnalysis.handleExit();
    if (!isAssignable(
      typeSchemaEnvironment.objectNonNullableRawType,
      expressionResult.inferredType,
    )) {
      return new ExpressionInferenceResult(
        const DynamicType(),
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.throwingNotAssignableToObjectError.withArguments(
            thrownType: expressionResult.inferredType,
          ),
          fileUri: fileUri,
          fileOffset: node.expression.fileOffset,
          length: noLength,
        ),
      );
    }
    if (expressionResult.inferredType.isPotentiallyNullable) {
      node.expression =
          new AsExpression(node.expression, coreTypes.objectNonNullableRawType)
            ..isTypeError = true
            ..fileOffset = node.expression.fileOffset
            ..parent = node;
    }
    // Return BottomType in legacy mode for compatibility.
    return new ExpressionInferenceResult(const NeverType.nonNullable(), node);
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
          captureKind: _captureKindForVariable(exception),
        );
      }
      if (stackTrace != null) {
        // TODO(62401): Remove the casts when the flow analysis uses
        // [InternalExpressionVariable]s.
        _contextAllocationStrategy.handleDeclarationOfVariable(
          stackTrace.astVariable,
          captureKind: _captureKindForVariable(stackTrace),
        );
      }
    }
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.hasChanged ? bodyResult.statement : node.body;
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
    Statement tryBodyWithAssignedInfo = node.tryBlock;
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
    Statement result = tryBlockResult.hasChanged
        ? tryBlockResult.statement
        : node.tryBlock;
    if (catchBlocks != null) {
      result = new TryCatch(result, catchBlocks)..fileOffset = node.fileOffset;
    }
    if (node.finallyBlock != null) {
      result = new TryFinally(
        result,
        finalizerResult!.hasChanged
            ? finalizerResult.statement
            : node.finallyBlock!,
      )..fileOffset = node.fileOffset;
    }
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result);
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    return new StatementInferenceResult.single(result);
  }

  @override
  ExpressionInferenceResult visitTypeLiteral(
    TypeLiteral node,
    DartType typeContext,
  ) {
    DartType inferredType = coreTypes.typeRawType(Nullability.nonNullable);
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitVariableSet(
    VariableSet node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
      variable: variable,
      variableType: variableType,
      rhsResult: rhsResult,
      assignOffset: node.fileOffset,
      nameOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result.expression);
    return result;
  }

  VariableDeclarationInferenceResult inferVariableDeclaration(
    InternalVariableDeclaration node,
  ) {
    VariableDeclarationInferenceResult variableDeclarationInferenceResult =
        _inferInternalExpressionVariableDeclaration(node, node.variable);
    if (isClosureContextLoweringEnabled) {
      _contextAllocationStrategy.handleDeclarationOfVariable(
        node.variable.astVariable,
        captureKind: _captureKindForVariable(node.variable),
      );
    }
    return variableDeclarationInferenceResult;
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitVariableStatement(VariableStatement node) {
    _unhandledStatement(node);
  }

  StatementInferenceResult visitInternalVariableStatement(
    InternalVariableStatement node,
  ) {
    return inferVariableDeclaration(node.declaration)
        .toStatementInferenceResult(fileOffset: node.fileOffset);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitPatternVariableDeclaration(
    PatternVariableDeclaration node,
  ) {
    _unhandledStatement(node);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitVariableGet(
    VariableGet node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result.expression);
    return result;
  }

  @override
  StatementInferenceResult visitWhileStatement(WhileStatement node) {
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
    ).expression;
    node.condition = condition..parent = node;
    flowAnalysis.whileStatement_bodyBegin(
      node,
      flowAnalysis.getExpressionInfo(node.condition),
    );
    StatementInferenceResult bodyResult = inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = bodyResult.statement..parent = node;
    }
    flowAnalysis.whileStatement_end();
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      node.scope = scopeProviderInfo.scope;
    }
    return const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitYieldStatement(YieldStatement node) {
    YieldStatementResult analysisResult = analyzeYieldStatement(
      node,
      node.expression,
      isYieldStar: node.isYieldStar,
    );
    ExpressionInferenceResult expressionResult = new ExpressionInferenceResult(
      analysisResult.operandType.unwrapTypeView(),
      popRewrite() as Expression,
    );
    bodyContext.handleYield(node, expressionResult);
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitLoadLibrary(
    covariant LoadLibraryImpl node,
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
    return new ExpressionInferenceResult(inferredType, node);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitCheckLibraryIsLoaded(
    CheckLibraryIsLoaded node,
    DartType typeContext,
  ) {
    // TODO(cstefantsova): Figure out the suitable nullability for that.
    return _unhandledExpression(node, typeContext);
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
        flowAnalysis.whyNotPromoted(
          flowAnalysis.getExpressionInfo(leftResult.expression),
        );
    return _computeBinaryExpression(
      node.fileOffset,
      typeContext,
      leftResult.expression,
      leftResult.inferredType,
      node.binaryName,
      node.right,
      whyNotPromoted,
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
            Expression error = problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.integerLiteralIsOutOfRange.withArguments(
                literal: receiver.literal,
              ),
              fileUri: fileUri,
              fileOffset: receiver.fileOffset,
              length: receiver.literal.length,
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
          flowAnalysis.getExpressionInfo(expressionResult.expression),
        );
    return _computeUnaryExpression(
      node.fileOffset,
      expressionResult.expression,
      expressionResult.inferredType,
      node.unaryName,
      whyNotPromoted,
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
    List<Expression> positional = node.positional;
    List<NamedExpression> namedUnsorted = node.named;
    List<NamedExpression> named = namedUnsorted;
    Map<String, NamedExpression>? namedElements = node.namedElements;
    List<Object> originalElementOrder = node.originalElementOrder;
    List<SyntheticVariable>? hoistedExpressions;

    List<DartType>? positionalTypeContexts;
    Map<String, DartType>? namedTypeContexts;
    if (typeContext is RecordType &&
        typeContext.positional.length == positional.length &&
        typeContext.named.length == namedUnsorted.length) {
      namedTypeContexts = <String, DartType>{};
      for (NamedType namedType in typeContext.named) {
        namedTypeContexts[namedType.name] = namedType.type;
      }

      bool sameNames = true;
      for (int i = 0; sameNames && i < namedUnsorted.length; i++) {
        if (!namedTypeContexts.containsKey(namedUnsorted[i].name)) {
          sameNames = false;
        }
      }

      if (sameNames) {
        positionalTypeContexts = typeContext.positional;
      } else {
        namedTypeContexts = null;
      }
    }

    List<DartType> positionalTypes;
    List<NamedType> namedTypes;

    if (namedElements == null) {
      positionalTypes = [];
      namedTypes = [];
      for (int index = 0; index < positional.length; index++) {
        Expression expression = positional[index];

        DartType contextType =
            positionalTypeContexts?[index] ?? const UnknownType();
        ExpressionInferenceResult expressionResult = inferExpression(
          expression,
          contextType,
        );
        if (contextType is! UnknownType) {
          expressionResult =
              coerceExpressionForAssignment(
                contextType,
                expressionResult,
                treeNodeForTesting: node,
              ) ??
              expressionResult;
        }

        positionalTypes.add(
          expressionResult.postCoercionType ?? expressionResult.inferredType,
        );
        positional[index] = expressionResult.expression;
      }
    } else {
      positionalTypes = new List<DartType>.filled(
        positional.length,
        const UnknownType(),
      );
      Map<String, DartType> namedElementTypes = {};

      // Index into [positional] of the positional element we find next.
      int positionalIndex = 0;

      for (int index = 0; index < originalElementOrder.length; index++) {
        Object element = originalElementOrder[index];
        if (element is NamedExpression) {
          DartType contextType =
              namedTypeContexts?[element.name] ?? const UnknownType();
          ExpressionInferenceResult expressionResult = inferExpression(
            element.value,
            contextType,
          );
          if (contextType is! UnknownType) {
            expressionResult =
                coerceExpressionForAssignment(
                  contextType,
                  expressionResult,
                  treeNodeForTesting: node,
                ) ??
                expressionResult;
          }
          Expression expression = expressionResult.expression;
          DartType type =
              expressionResult.postCoercionType ??
              expressionResult.inferredType;
          element.value = expression..parent = element;
          namedElementTypes[element.name] = type;
        } else {
          DartType contextType =
              positionalTypeContexts?[positionalIndex] ?? const UnknownType();
          ExpressionInferenceResult expressionResult = inferExpression(
            element as Expression,
            contextType,
          );
          if (contextType is! UnknownType) {
            expressionResult =
                coerceExpressionForAssignment(
                  contextType,
                  expressionResult,
                  treeNodeForTesting: node,
                ) ??
                expressionResult;
          }
          Expression expression = expressionResult.expression;
          DartType type =
              expressionResult.postCoercionType ??
              expressionResult.inferredType;
          positional[positionalIndex] = expression;
          positionalTypes[positionalIndex] = type;
          positionalIndex++;
        }
      }

      List<String> sortedNames = namedElements.keys.toList()..sort();

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
      for (int index = originalElementOrder.length - 1; index >= 0; index--) {
        Object element = originalElementOrder[index];
        if (element is NamedExpression) {
          Expression expression = element.value;
          DartType type = namedElementTypes[element.name]!;
          // TODO(johnniwinther): Should we use [isPureExpression] as is, make
          // it include (simple) literals, or add a new predicate?
          if (needsHoisting && !isPureExpression(expression)) {
            // We hoist the value of the [NamedExpression] into a synthesized
            // variable, and replace the value with a read of the variable.
            SyntheticVariable variable = createVariable(expression, type);
            hoistedExpressions ??= [];
            hoistedExpressions.add(variable);
            element.value = createVariableGet(variable)..parent = element;
          }
          if (!namedNeedsSorting && element.name != sortedNames[nameIndex]) {
            // Named elements are not sorted, so we need to hoist and sort them.
            namedNeedsSorting = true;
            needsHoisting = enableHoisting;
          }
          nameIndex--;
        } else {
          Expression expression = positional[positionalIndex];
          DartType type = positionalTypes[positionalIndex];
          // TODO(johnniwinther): Should we use [isPureExpression] as is, make
          // it include (simple) literals, or add a new predicate?
          if (needsHoisting && !isPureExpression(expression)) {
            // We hoist the positional element into a synthesized variable, and
            // replace the element in [positional] with a read of the variable.
            SyntheticVariable variable = createVariable(expression, type);
            hoistedExpressions ??= [];
            hoistedExpressions.add(variable);
            positional[positionalIndex] = createVariableGet(variable);
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
        return new NamedType(name, namedElementTypes[name]!);
      });
      if (namedNeedsSorting) {
        // The [named] elements need to be sorted.
        named = [];
        for (String name in sortedNames) {
          named.add(namedElements[name]!);
        }
      }
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
        named,
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
        result = createLet(variable, result);
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
    Expression node,
    SharedTypeSchemaView context, {
    bool isVoidAllowed = false,
  }) {
    // Normally the CFE performs expression coercion in the process of type
    // inference of the nodes where an assignment is executed. The inference on
    // the pattern-related nodes is driven by the shared analysis, and some of
    // such nodes perform assignments. Here we determine if we're inferring the
    // expressions of one of such nodes, and perform the coercion if needed.
    TreeNode? parent = node.parent;

    // The case of pattern variable declaration. The initializer expression is
    // assigned to the pattern, and so the coercion needs to be performed.
    bool needsCoercion =
        parent is InternalPatternVariableDeclaration &&
        parent.initializer == node;

    // The case of pattern assignment. The expression is assigned to the
    // pattern, and so the coercion needs to be performed.
    needsCoercion =
        needsCoercion ||
        parent is InternalPatternAssignment && parent.expression == node;

    // The constant expressions in relational patterns are considered to be
    // passed into the corresponding operator, and so the coercion needs to be
    // performed.
    needsCoercion =
        needsCoercion ||
        parent is InternalRelationalPattern && parent.expression == node;

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
            treeNodeForTesting: node,
          ) ??
          expressionResult;
    }

    pushRewrite(expressionResult.expression);

    // The shared analysis logic uses the convention that the expressions passed
    // to flow analysis are the original (pre-lowered) expressions, whereas the
    // expressions passed to flow analysis by the CFE are the lowered
    // expressions. Since the caller of `dispatchExpression` is the shared
    // analysis logic, we need to transfer the flow analysis information that's
    // associated with `expressionResult.expression` (the post-lowered
    // expression) so that it becomes associated with `node` (the pre-lowered
    // expression).
    //
    // TODO(paulberry): eliminate the need for this--see
    // https://github.com/dart-lang/sdk/issues/52189.
    ExpressionInfo? flowAnalysisInfo = flow.getExpressionInfo(
      expressionResult.expression,
    );
    flow.storeExpressionInfo(node, flowAnalysisInfo);
    return new ExpressionTypeAnalysisResult(
      type: new SharedTypeView(expressionResult.inferredType),
      flowAnalysisInfo: flowAnalysisInfo,
    );
  }

  @override
  PatternResult dispatchPattern(SharedMatchContext context, TreeNode node) {
    if (node is InternalPattern) {
      return node.acceptInference(this, context);
    } else {
      return analyzeConstantPattern(context, node, node as Expression);
    }
  }

  @override
  SharedTypeSchemaView dispatchPatternSchema(Node node) {
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
            fields: <RecordPatternField<TreeNode, InternalPattern>>[
              for (InternalPattern element in node.patterns)
                if (element is InternalNamedPattern)
                  new RecordPatternField<TreeNode, InternalPattern>(
                    node: element,
                    name: element.name,
                    pattern: element.pattern,
                  )
                else
                  new RecordPatternField<TreeNode, InternalPattern>(
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
        node is TreeNode ? node.fileOffset : TreeNode.noOffset,
        fileUri,
      );
    }
  }

  @override
  void dispatchStatement(Statement statement) {
    StatementInferenceResult result = inferStatement(statement);
    pushRewrite(result.hasChanged ? result.statement : statement);
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
          LabeledStatement switchLabel = node.parent as LabeledStatement;
          BreakStatement syntheticBreak = new BreakStatement(switchLabel)
            ..fileOffset = TreeNode.noOffset;
          if (body is Block) {
            body.addStatement(syntheticBreak);
          } else {
            body = new Block([body, syntheticBreak])
              ..fileOffset = body.fileOffset;
          }
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
          LabeledStatement switchLabel = node.parent as LabeledStatement;
          BreakStatement syntheticBreak = new BreakStatement(switchLabel)
            ..fileOffset = TreeNode.noOffset;
          if (body is Block) {
            body.addStatement(syntheticBreak);
          } else {
            // Coverage-ignore-block(suite): Not run.
            body = new Block([body, syntheticBreak])
              ..fileOffset = body.fileOffset;
          }
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
            for (InternalVariable variable in case_.jointVariables)
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
  FlowAnalysis<TreeNode, Statement, Expression, InternalVariable> get flow =>
      flowAnalysis;

  @override
  SwitchExpressionMemberInfo<TreeNode, Expression, InternalVariable>
  getSwitchExpressionMemberInfo(Expression node, int index) {
    InternalSwitchExpressionCase switchExpressionCase =
        (node as InternalSwitchExpression).cases[index];
    InternalPattern pattern = switchExpressionCase.patternGuard.pattern;
    Map<String, InternalVariable> variables = {
      for (InternalVariable declaredVariable in pattern.declaredVariables)
        declaredVariable.cosmeticName!: declaredVariable,
    };
    return new SwitchExpressionMemberInfo<
      TreeNode,
      Expression,
      InternalVariable
    >(
      head: new CaseHeadOrDefaultInfo<TreeNode, Expression, InternalVariable>(
        pattern: pattern,
        guard: switchExpressionCase.patternGuard.guard,
        variables: variables,
      ),
      expression: switchExpressionCase.expression,
    );
  }

  @override
  SwitchStatementMemberInfo<TreeNode, Statement, Expression, InternalVariable>
  getSwitchStatementMemberInfo(
    covariant InternalSwitchStatement node,
    int caseIndex,
  ) {
    switch (node) {
      case InternalRegularSwitchStatement():
        InternalSwitchStatementCase case_ = node.cases[caseIndex];
        return new SwitchStatementMemberInfo(
          heads: [
            for (Expression expression in case_.expressions)
              new CaseHeadOrDefaultInfo(pattern: expression, variables: {}),
            if (case_.isDefault)
              new CaseHeadOrDefaultInfo(pattern: null, variables: {}),
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
              new CaseHeadOrDefaultInfo(
                pattern: patternGuard.pattern,
                guard: patternGuard.guard,
                variables: {
                  for (InternalVariable variable
                      in patternGuard.pattern.declaredVariables)
                    variable.cosmeticName!: variable,
                },
              ),
            if (case_.isDefault)
              new CaseHeadOrDefaultInfo(pattern: null, variables: {}),
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
    assert(checkStackBase(node as TreeNode, stackBase = stackHeight - 2));

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
    Statement node,
    int caseIndex,
    Iterable<InternalVariable> variables,
  ) {}

  @override
  void handleDefault(
    TreeNode node, {
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleNoStatement(Statement node) {
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
  void handleNoGuard(TreeNode node, int caseIndex) {
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
    TreeNode node, {
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
  bool isLegacySwitchExhaustive(TreeNode node, SharedTypeView expressionType) {
    Set<Field?>? enumFields = _enumFields;
    return enumFields != null && enumFields.isEmpty;
  }

  @override
  bool isVariablePattern(TreeNode node) {
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

    Object? rewrite = popRewrite();
    Expression expression = node.expression;
    if (!identical(node.expression, rewrite)) {
      expression = rewrite as Expression;
    }

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

    Map<String, Variable> leftDeclaredVariablesByName = {
      for (InternalVariable variable in node.left.declaredVariables)
        variable.cosmeticName!: variable.astVariable,
    };
    Map<String, Variable> jointVariableNames = {
      for (InternalVariable variable in node.orPatternJointVariables)
        variable.cosmeticName!: variable.astVariable,
    };
    for (InternalVariable rightVariable in node.right.declaredVariables) {
      String rightVariableName = rightVariable.cosmeticName!;
      Variable? leftVariable = leftDeclaredVariablesByName[rightVariableName];
      Variable? jointVariable = jointVariableNames[rightVariableName];
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
          fields: <RecordPatternField<TreeNode, InternalPattern>>[
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
        error: node.invalidExpression,
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

    Object? rewrite = popRewrite();
    Expression expression = node.expression;
    if (!identical(rewrite, node.expression)) {
      expression = rewrite as Expression;
    }

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

    List<RecordPatternField<TreeNode, InternalPattern>> fields = [
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitPatternAssignment(
    PatternAssignment node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
          error: problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.lateDefinitelyAssignedError.withArguments(
              variableName: node.variableName,
            ),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: node.variableName.length,
          ),
          declaredVariables: node.declaredVariables,
        );
      }
    } else if (variable.isStaticLate) {
      if (!isDefinitelyUnassigned) {
        replacement = extern.createInvalidPattern(
          error: problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.finalPossiblyAssignedError.withArguments(
              variableName: node.variableName,
            ),
            fileUri: fileUri,
            fileOffset: node.fileOffset,
            length: node.variableName.length,
          ),
          declaredVariables: node.declaredVariables,
        );
      }
    } else if (variable.isFinal &&
        // Coverage-ignore(suite): Not run.
        variable.hasDeclaredInitializer) {
      // Coverage-ignore-block(suite): Not run.
      replacement = extern.createInvalidPattern(
        error: problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.cannotAssignToFinalVariable.withArguments(
            variableName: node.variableName,
          ),
          fileUri: fileUri,
          fileOffset: node.fileOffset,
          length: node.variableName.length,
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
    required TreeNode? treeNodeForTesting,
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
          treeNodeForTesting: treeNodeForTesting,
        );
    return typeSchemaEnvironment.chooseFinalTypes(
      gatherer.computeConstraints(),
      typeParametersToInfer,
      null,
      inferenceUsingBoundsIsEnabled:
          libraryFeatures.inferenceUsingBounds.isEnabled,
      dataForTesting: dataForTesting,
      treeNodeForTesting: treeNodeForTesting,
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
            treeNodeForTesting: pattern,
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
            treeNodeForTesting: pattern,
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
            treeNodeForTesting: pattern,
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
  void dispatchCollectionElement(
    covariant TreeNode element,
    covariant CollectionElementInferenceContext context,
  ) {
    if (element is Expression) {
      context as ListAndSetElementInferenceContext;
      ExpressionInferenceResult inferenceResult = inferElement(
        element,
        context.inferredTypeArgument,
        context.inferredSpreadTypes,
        context.inferredConditionTypes,
      );
      // TODO(cstefantsova): Should the key to the map be [element] instead?
      context.inferredConditionTypes[inferenceResult.expression] =
          inferenceResult.inferredType;
      pushRewrite(inferenceResult.expression);
    } else if (element is MapLiteralEntry) {
      context as MapEntryInferenceContext;
      element = inferMapEntry(
        element,
        element.parent!,
        context.inferredKeyType,
        context.inferredValueType,
        context.spreadContext,
        context.actualTypes,
        context.actualTypesForSet,
        context.inferredSpreadTypes,
        context.inferredConditionTypes,
        context.offsets,
      );
      pushRewrite(element);
    } else {
      // Coverage-ignore-block(suite): Not run.
      problems.unsupported(
        "${element.runtimeType}",
        element.fileOffset,
        fileUri,
      );
    }
  }

  @override
  (Member?, SharedTypeView) resolveObjectPatternPropertyGet({
    required InternalPattern objectPattern,
    required SharedTypeView receiverType,
    required shared.RecordPatternField<TreeNode, InternalPattern> field,
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
  void handleNoCollectionElement(TreeNode element) {
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
  bool isRestPatternElement(Node node) {
    return node is InternalRestPattern || node is InternalMapPatternRestEntry;
  }

  @override
  InternalPattern? getRestPatternElementPattern(TreeNode node) {
    if (node is InternalMapPatternRestEntry) {
      return null;
    } else {
      return (node as InternalRestPattern).subPattern;
    }
  }

  @override
  void handleListPatternRestElement(
    InternalPattern container,
    TreeNode restElement,
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
    TreeNode restElement,
  ) {
    pushRewrite(
      extern.createMapPatternRestEntry(fileOffset: container.fileOffset),
    );
  }

  @override
  shared.MapPatternEntry<Expression, InternalPattern>? getMapPatternEntry(
    TreeNode element,
  ) {
    element as InternalMapPatternEntry;
    if (element is InternalMapPatternRestEntry) {
      return null;
    } else {
      return new shared.MapPatternEntry<Expression, InternalPattern>(
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
    Expression key = entryElement.key;
    Object? rewrite = popRewrite();
    if (!identical(rewrite, entryElement.key)) {
      key = rewrite as Expression;
    }

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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitAuxiliaryExpression(
    AuxiliaryExpression node,
    DartType typeContext,
  ) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InitializerInferenceResult visitAuxiliaryInitializer(
    AuxiliaryInitializer node,
  ) {
    if (node is InternalInitializer) {
      return node.acceptInference(this);
    }
    return _unhandledInitializer(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  StatementInferenceResult visitAuxiliaryStatement(AuxiliaryStatement node) {
    return _unhandledStatement(node);
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
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.dotShorthandsConstructorInvocationWithTypeArguments,
            fileUri: fileUri,
            fileOffset: node.nameOffset,
            length: node.name.text.length,
          ),
        );
      }

      if (constructor is Constructor) {
        if (!constructor.isConst && node.isConst) {
          return new ExpressionInferenceResult(
            const DynamicType(),
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nonConstConstructor,
              fileUri: fileUri,
              fileOffset: node.nameOffset,
              length: node.name.text.length,
            ),
          );
        }

        TypeDeclaration typeDeclaration = cachedContext.typeDeclaration;
        if (typeDeclaration is Class && typeDeclaration.isAbstract) {
          return new ExpressionInferenceResult(
            const DynamicType(),
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.abstractClassInstantiation.withArguments(
                name: typeDeclaration.name,
              ),
              fileUri: fileUri,
              fileOffset: node.nameOffset,
              length: node.name.text.length,
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
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nonConstConstructor,
              fileUri: fileUri,
              fileOffset: node.nameOffset,
              length: node.name.text.length,
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
      Expression receiver = new StaticGet(member)..fileOffset = node.fileOffset;
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
      );
    }

    // Error handling. At this point, we've exhausted all possible valid
    // invocations.
    Expression replacement;
    if (isKnown(cachedContext)) {
      // Error when we can't find the static member or constructor named
      // [node.name] in the declaration of [cachedContext].
      replacement = problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.dotShorthandsUndefinedInvocation.withArguments(
          memberName: node.name.text,
          contextType: cachedContext,
        ),
        fileUri: fileUri,
        fileOffset: node.nameOffset,
        length: node.name.text.length,
      );
    } else {
      // Error when no context type or an invalid context type is given to
      // resolve the dot shorthand.
      //
      // e.g. `var x = .one;`
      replacement = problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.dotShorthandsInvalidContext.withArguments(
          dotShorthandName: node.name.text,
        ),
        fileUri: fileUri,
        fileOffset: node.nameOffset,
        length: node.name.text.length,
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

    Member? member = findStaticMember(
      cachedContext,
      node.name,
      node.fileOffset,
    );
    ExpressionInferenceResult expressionInferenceResult;
    switch (member) {
      case Field():
        Expression staticGet = new StaticGet(member)
          ..fileOffset = node.fileOffset;
        expressionInferenceResult = inferExpression(staticGet, cachedContext);
      case Procedure():
        if (member.isGetter) {
          Expression staticGet = new StaticGet(member)
            ..fileOffset = node.fileOffset;
          expressionInferenceResult = inferExpression(staticGet, cachedContext);
        } else {
          // Method tearoffs.
          DartType type = member.function.computeFunctionType(
            Nullability.nonNullable,
          );
          Expression tearOff = new StaticTearOff(member)
            ..fileOffset = node.fileOffset;
          return instantiateTearOff(type, typeContext, tearOff);
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
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message:
                    diag.dotShorthandsConstructorInvocationWithTypeArguments,
                fileUri: fileUri,
                fileOffset: node.nameOffset,
                length: node.name.text.length,
              ),
            );
          }
          if (constructor is Constructor) {
            TypeDeclaration typeDeclaration = cachedContext.typeDeclaration;
            if (typeDeclaration is Class && typeDeclaration.isAbstract) {
              return new ExpressionInferenceResult(
                const DynamicType(),
                problemReporting.buildProblem(
                  compilerContext: compilerContext,
                  message: diag.abstractClassConstructorTearOff,
                  fileUri: fileUri,
                  fileOffset: node.nameOffset,
                  length: node.name.text.length,
                ),
              );
            }

            DartType type = constructor.function.computeFunctionType(
              Nullability.nonNullable,
            );
            Expression tearOff = new ConstructorTearOff(constructor)
              ..fileOffset = node.fileOffset;
            return instantiateTearOff(type, typeContext, tearOff);
          } else if (constructor is Procedure) {
            DartType type = constructor.function.computeFunctionType(
              Nullability.nonNullable,
            );
            Expression tearOff = new StaticTearOff(constructor)
              ..fileOffset = node.fileOffset;
            return instantiateTearOff(type, typeContext, tearOff);
          }
        }

        if (isKnown(cachedContext)) {
          // Error when we can't find the static getter or field [node.name] in
          // the declaration of [cachedContext].
          expressionInferenceResult = new ExpressionInferenceResult(
            const DynamicType(),
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
          );
        } else {
          // Error when no context type or an invalid context type is given to
          // resolve the dot shorthand.
          //
          // e.g. `var x = .one;`
          expressionInferenceResult = new ExpressionInferenceResult(
            const DynamicType(),
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
    }

    flowAnalysis.storeExpressionInfo(
      expressionInferenceResult.expression,
      flowAnalysis.getExpressionInfo(node),
    );
    return expressionInferenceResult;
  }

  @override
  bool isDotShorthand(Expression node) {
    return node is DotShorthand;
  }

  CaptureKind _captureKindForVariable(InternalVariable variable) {
    int variableKey = assignedVariables.promotionKeyStore.keyForVariable(
      variable,
    );

    if (assignedVariables.outsideAsserts.captured.contains(variableKey) ||
        assignedVariables.outsideAsserts.readCaptured.contains(variableKey)) {
      return CaptureKind.directCaptured;
    } else if (assignedVariables.insideAsserts.captured.contains(variableKey) ||
        assignedVariables.insideAsserts.readCaptured.contains(variableKey)) {
      return CaptureKind.assertCaptured;
    } else {
      return CaptureKind.notCaptured;
    }
  }

  List<VariableBase> _capturedVariablesForNode(TreeNode node) {
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

  VariableDeclarationInferenceResult
  _inferInternalExpressionVariableDeclaration(
    InternalVariableDeclaration variableDeclaration,
    InternalVariable internalVariable,
  ) {
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
        internalVariable.parent?.parent is! InternalForStatement) {
      if (internalVariable.astVariable.initializer case var initializer?
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
    if (internalVariable.astVariable.initializer != null) {
      if (internalVariable.isLate && internalVariable.hasDeclaredInitializer) {
        // TODO(62401): Remove the cast when the flow analysis uses
        // [InternalExpressionVariable]s.
        if (isClosureContextLoweringEnabled) {
          capturedContexts = _contextAllocationStrategy
              .computeCapturedVariableContexts(
                _capturedVariablesForNode(internalVariable.astVariable),
              );
        }
        flowAnalysis.lateInitializer_begin(internalVariable.astVariable);
      }
      initializerResult = inferExpression(
        internalVariable.astVariable.initializer!,
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
    if (initializerResult != null) {
      DartType initializerType = initializerResult.inferredType;
      flowAnalysis.initialize(
        internalVariable,
        new SharedTypeView(initializerType),
        flowAnalysis.getExpressionInfo(initializerResult.expression),
        isFinal: internalVariable.isFinal,
        isLate: internalVariable.isLate,
        isImplicitlyTyped: internalVariable.isImplicitlyTyped,
      );
      initializerResult = ensureAssignableResult(
        internalVariable.type,
        initializerResult,
        fileOffset: internalVariable.fileOffset,
        isVoidAllowed: internalVariable.type is VoidType,
      );
      Expression initializer = initializerResult.expression;
      internalVariable.astVariable.initializer = initializer
        ..parent = internalVariable.astVariable;
    }
    if (internalVariable.isLate &&
        libraryBuilder.loader.target.backendTarget.isLateLocalLoweringEnabled(
          hasInitializer: internalVariable.hasDeclaredInitializer,
          isFinal: internalVariable.isFinal,
          isPotentiallyNullable: internalVariable.type.isPotentiallyNullable,
        )) {
      int fileOffset = internalVariable.fileOffset;

      List<VariableDeclaration> variableDeclarations = [];
      List<FunctionDeclaration> functionDeclarations = [];
      variableDeclarations.add(
        extern.createVariableDeclaration(
          internalVariable.astVariable,
          fileOffset: variableDeclaration.fileOffset,
        ),
      );

      late_lowering.IsSetEncoding isSetEncoding = late_lowering
          .computeIsSetEncoding(
            internalVariable.type,
            late_lowering.computeIsSetStrategy(libraryBuilder),
          );
      Variable? isSetVariable;
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
        variableDeclarations.add(
          extern.createVariableDeclaration(isSetVariable),
        );
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

      Variable getVariable = extern.createUninitializedVariable(
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
          internalVariable.astVariable.initializer == null
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
                        internalVariable.astVariable.initializer!,
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
                        internalVariable.astVariable.initializer!,
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

      if (!internalVariable.isFinal ||
          internalVariable.astVariable.initializer == null) {
        internalVariable.isLateFinalWithoutInitializer =
            internalVariable.isFinal &&
            internalVariable.astVariable.initializer == null;
        Variable setVariable = extern.createUninitializedVariable(
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
      if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
        internalVariable.astVariable.initializer =
            new StaticInvocation(
                coreTypes.createSentinelMethod,
                new Arguments([], types: [internalVariable.type])
                  ..fileOffset = fileOffset,
              )
              ..fileOffset = fileOffset
              ..parent = internalVariable.astVariable;
      } else {
        internalVariable.astVariable.initializer = null;
      }
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
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(internalVariable, internalVariable.astVariable);
    return new VariableDeclarationInferenceResult.direct(
      extern.createVariableDeclaration(
        internalVariable.astVariable,
        capturedContexts: capturedContexts,
        fileOffset: variableDeclaration.fileOffset,
      ),
    );
  }

  @override
  ScopeProviderInfo beginFieldInference({
    required InternalThisVariable? internalThisVariable,
  }) {
    ScopeProviderInfo scopeProviderInfo =
        _contextAllocationStrategy.enterScopeProvider(
          scopeProviderInfoKind: internalThisVariable == null
              ? ScopeProviderInfoKind.StaticField
              : ScopeProviderInfoKind.InstanceField,
        )..thisVariable = internalThisVariable?.astVariable;
    if (internalThisVariable != null) {
      _contextAllocationStrategy.handleDeclarationOfVariable(
        internalThisVariable.astVariable,
        captureKind: _captureKindForVariable(internalThisVariable),
      );
    }
    return scopeProviderInfo;
  }

  @override
  void endFieldInference(ScopeProviderInfo scopeProviderInfo) {
    _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
  }
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

abstract class CollectionElementInferenceContext {
  Map<TreeNode, DartType> inferredSpreadTypes;
  Map<Expression, DartType> inferredConditionTypes;

  new({
    required this.inferredSpreadTypes,
    required this.inferredConditionTypes,
  });
}

class ListAndSetElementInferenceContext
    extends CollectionElementInferenceContext {
  DartType inferredTypeArgument;

  new({
    required this.inferredTypeArgument,
    required Map<TreeNode, DartType> inferredSpreadTypes,
    required Map<Expression, DartType> inferredConditionTypes,
  }) : super(
         inferredSpreadTypes: inferredSpreadTypes,
         inferredConditionTypes: inferredConditionTypes,
       );
}

class MapEntryInferenceContext extends CollectionElementInferenceContext {
  DartType inferredKeyType;
  DartType inferredValueType;
  DartType spreadContext;
  List<DartType> actualTypes;
  List<DartType> actualTypesForSet;
  _MapLiteralEntryOffsets offsets;

  new({
    required this.inferredKeyType,
    required this.inferredValueType,
    required this.spreadContext,
    required this.actualTypes,
    required this.actualTypesForSet,
    required this.offsets,
    required Map<TreeNode, DartType> inferredSpreadTypes,
    required Map<Expression, DartType> inferredConditionTypes,
  }) : super(
         inferredSpreadTypes: inferredSpreadTypes,
         inferredConditionTypes: inferredConditionTypes,
       );
}

abstract class ExpressionEvaluationHelper {
  ExpressionInferenceResult? visitInternalVariableGet(
    InternalVariableGet node,
    DartType typeContext,
    ProblemReporting problemReporting,
    CompilerContext compilerContext,
    Uri fileUri,
  );

  ExpressionInferenceResult? visitInternalVariableSet(
    InternalVariableSet node,
    DartType typeContext,
    ProblemReporting problemReporting,
    CompilerContext compilerContext,
    Uri fileUri,
  );

  OverwrittenInterfaceMember? overwriteFindInterfaceMember({
    required ObjectAccessTarget target,
    required DartType receiverType,
    required Name name,
    required bool setter,
  });
}

// Coverage-ignore(suite): Not run.
class OverwrittenInterfaceMember {
  final ObjectAccessTarget target;
  final Name name;

  new({required this.target, required this.name});
}

class _RedirectionTarget {
  final Member target;
  final List<DartType> typeArguments;

  new(this.target, this.typeArguments);
}
