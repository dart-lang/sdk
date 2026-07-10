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
import '../base/messages.dart';
import '../base/problems.dart'
    as problems
    show internalProblem, unhandled, unimplemented, unsupported;
import '../base/uri_offset.dart';
import '../builder/library_builder.dart';
import '../codes/diagnostic.dart' as diag;
import '../dill/dill_library_builder.dart';
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/external_ast_helper.dart';
import '../kernel/inferred_collections.dart';
import '../kernel/internal_ast_helper.dart' as intern;
import '../kernel/hierarchy/class_member.dart';
import '../kernel/internal_ast.dart';
import '../kernel/late_lowering.dart' as late_lowering;
import '../source/check_helper.dart';
import '../source/source_library_builder.dart';
import '../util/expression_evaluation_helpers.dart';
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
          TreeNode,
          InternalStatement,
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
    storeExpressionInfo(wholeExpression, null);
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
    SyntheticVariable receiverVariable = createVariable(receiver, receiverType);
    createNullAwareGuard(receiverVariable);
    Expression variableGet = createVariableGet(
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
          this,
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
      // Coverage-ignore-block(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitBlockExpression(
    BlockExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitStaticTearOff(
    StaticTearOff node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    );
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitFileUriExpression(
    FileUriExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
    return new ExpressionInferenceResult(result.inferredType, replacement);
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitConstructorTearOff(
    ConstructorTearOff node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
    return instantiateTearOff(type, typeContext, replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRedirectingFactoryTearOff(
    RedirectingFactoryTearOff node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
    return instantiateTearOff(type, typeContext, replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitTypedefTearOff(
    TypedefTearOff node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInvalidExpression(
    InvalidExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitInstantiation(
    Instantiation node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, result);
    return new ExpressionInferenceResult(resultType, result);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitIntLiteral(
    IntLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitAsExpression(
    AsExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitAwaitExpression(
    AwaitExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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
    ?.registerAlias(node, replacement);

    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      replacement.scope = scopeProviderInfo.scope;
    }
    return new StatementInferenceResult.single(replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitBoolLiteral(
    BoolLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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
    node.target.addUser(replacement);
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
    node.target.addUser(replacement);
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
        this,
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
  PropertyTarget<Expression> computePropertyTarget(Expression target) {
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitConditionalExpression(
    ConditionalExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    registerIfUnreachableForTesting(then, isReachable: isThenReachable);
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
      otherwise,
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
    ?.registerAlias(node, replacement);
    return new ExpressionInferenceResult(inferredType, replacement);
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
        variable: valueVariable!,
        body: createLet(
          variable: assignmentVariable,
          body: createVariableGet(valueVariable),
        ),
      );
      if (receiverVariable != null) {
        replacement = createLet(variable: receiverVariable, body: replacement);
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
      intern.createIntLiteral(value: 1, fileOffset: node.fileOffset),
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
        variable: valueVariable,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
        ),
      );
    } else if (binaryVariable != null) {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        variable: binaryVariable,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(binaryVariable),
        ),
      );
    } else {
      replacement = write;
    }
    if (receiverVariable != null) {
      replacement = createLet(variable: receiverVariable, body: replacement);
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
      isThisReceiver: _isThisExpression(node.receiver),
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
        extern.createNullLiteral(fileOffset: node.fileOffset),
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
      replacement = createLet(variable: readVariable, body: conditional);
    }
    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = createLet(variable: receiverVariable, body: replacement);
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
        variable: valueVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
        ),
      );
    }
    if (receiverVariable != null) {
      replacement = createLet(variable: receiverVariable, body: replacement);
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

  StatementInferenceResult visitInternalDoStatement(InternalDoStatement node) {
    flowAnalysis.doStatement_bodyBegin(node);
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;

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
    flowAnalysis.doStatement_end(getExpressionInfo(condition));
    Statement replacement = extern.createDoStatement(
      body,
      condition,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitDoubleLiteral(
    DoubleLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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
    ?.registerAlias(node, replacement);
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
    ?.registerAlias(node, replacement);
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

    DeclaredVariable loopVariable = extern.createUninitializedVariable(
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
      ).expression;
    }

    flowAnalysis.for_bodyBegin(node, switch (condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => getExpressionInfo(condition),
    });
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;
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
    ?.registerAlias(variable, variable.astVariable);
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, replacement);
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
    if (_isThisExpression(left)) {
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
    ?.registerAlias(node, replacement);
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
    ?.registerAlias(node, replacement);
    DartType inferredType = coreTypes.intRawType(Nullability.nonNullable);
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitIsExpression(
    IsExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    Expression operand = operandResult.expression..parent = node;
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
    ?.registerAlias(node, replacement);
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
    LabeledStatement replacement = extern.createLabeledStatement(
      body,
      fileOffset: node.fileOffset,
    );
    node.registerReplacement(replacement);
    return new StatementInferenceResult.single(replacement);
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

  ElementInferenceResult _inferSpreadElement(
    SpreadElement element,
    DartType inferredTypeArgument,
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
    Expression? replacement;
    Expression expression = spreadResult.expression;
    final DartType spreadType = spreadResult.inferredType;
    DartType spreadTypeBound = spreadType.nonTypeParameterBound;
    DartType? spreadElementType = getSpreadElementType(
      spreadType,
      spreadTypeBound,
      element.isNullAware,
    );
    if (spreadElementType == null) {
      if (coreTypes.isNull(spreadTypeBound) && !element.isNullAware) {
        replacement = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonNullAwareSpreadIsNull.withArguments(
              spreadType: spreadType,
            ),
            fileUri: fileUri,
            fileOffset: element.expression.fileOffset,
            length: 1,
          ),
        );
      } else {
        if (spreadType.isPotentiallyNullable &&
            spreadType is! DynamicType &&
            spreadType is! NullType &&
            !element.isNullAware) {
          Expression receiver = expression;
          replacement = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nullableSpreadError,
              fileUri: fileUri,
              fileOffset: receiver.fileOffset,
              length: 1,
              context: getWhyNotPromotedContext(
                flowAnalysis.whyNotPromoted(getExpressionInfo(receiver))(),
                element,
                // Coverage-ignore(suite): Not run.
                (type) => !type.isPotentiallyNullable,
              ),
            ),
          );
        }

        replacement = extern.createInvalidExpressionFromErrorText(
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
        _copyNonPromotionReasonToReplacement(element, replacement);
      }
    } else if (spreadTypeBound is InterfaceType) {
      if (!isAssignable(inferredTypeArgument, spreadElementType)) {
        replacement = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.spreadElementTypeMismatch.withArguments(
              spreadElementType: spreadElementType,
              collectionElementType: inferredTypeArgument,
            ),
            fileUri: fileUri,
            fileOffset: expression.fileOffset,
            length: 1,
          ),
        );
      }
      if (spreadType.isPotentiallyNullable &&
          spreadType is! DynamicType &&
          spreadType is! NullType &&
          !element.isNullAware) {
        Expression receiver = expression;
        replacement = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nullableSpreadError,
            fileUri: fileUri,
            fileOffset: receiver.fileOffset,
            length: 1,
            context: getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(getExpressionInfo(receiver))(),
              element,
              // Coverage-ignore(suite): Not run.
              (type) => !type.isPotentiallyNullable,
            ),
          ),
        );
        _copyNonPromotionReasonToReplacement(element, replacement);
      }
    }

    // Use 'dynamic' for error recovery.
    DartType elementType = spreadElementType ?? const DynamicType();

    InferredElement inferredElement = replacement != null
        ? new InferredExpressionElement(
            expression: replacement,
            fileOffset: replacement.fileOffset,
          )
        : new InferredSpreadElement(
            expression: expression,
            isNullAware: element.isNullAware,
            expressionType: spreadType,
            elementType: elementType,
            nodeForTesting: element,
            fileOffset: element.fileOffset,
          );
    return new ElementInferenceResult(
      // TODO(johnniwinther): Should this be InvalidType for errors.
      inferredType: spreadElementType ?? const DynamicType(),
      element: inferredElement,
    );
  }

  ElementInferenceResult _inferNullAwareElement(
    NullAwareElement element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    DartType nonNullableInferredTypeArgument = inferredTypeArgument
        .withDeclaredNullability(Nullability.nullable);
    ExpressionInferenceResult expressionResult = inferExpression(
      element.expression,
      nonNullableInferredTypeArgument,
      isVoidAllowed: true,
    );
    if (nonNullableInferredTypeArgument is! UnknownType) {
      expressionResult = ensureAssignableResult(
        nonNullableInferredTypeArgument,
        expressionResult,
        isVoidAllowed: nonNullableInferredTypeArgument is VoidType,
      );
    }
    InferredElement inferredElement = new InferredNullAwareElement(
      expression: expressionResult.expression,
      fileOffset: element.fileOffset,
    );
    return new ElementInferenceResult(
      inferredType: computeNonNull(expressionResult.inferredType),
      element: inferredElement,
    );
  }

  ElementInferenceResult _inferIfElement(
    IfElement element,
    DartType inferredTypeArgument,
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
    flowAnalysis.ifStatement_thenBegin(getExpressionInfo(condition), element);
    ElementInferenceResult thenResult = inferElement(
      element.then,
      inferredTypeArgument,
      inferredConditionTypes,
    );
    ElementInferenceResult? otherwiseResult;
    if (element.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      otherwiseResult = inferElement(
        element.otherwise!,
        inferredTypeArgument,
        inferredConditionTypes,
      );
    }
    flowAnalysis.ifStatement_end(element.otherwise != null);
    InferredElement inferredElement = new InferredIfElement(
      condition: condition,
      then: thenResult.element,
      otherwise: otherwiseResult?.element,
      nodeForTesting: element,
      fileOffset: element.fileOffset,
    );
    return new ElementInferenceResult(
      inferredType: otherwiseResult == null
          ? thenResult.inferredType
          : typeSchemaEnvironment.getStandardUpperBound(
              thenResult.inferredType,
              otherwiseResult.inferredType,
            ),
      element: inferredElement,
    );
  }

  ElementInferenceResult _inferIfCaseElement(
    IfCaseElement element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    int? stackBase;
    assert(checkStackBase(element, stackBase = stackHeight));

    ListAndSetElementInferenceContext context =
        new ListAndSetElementInferenceContext(
          inferredTypeArgument: inferredTypeArgument,
          inferredConditionTypes: inferredConditionTypes,
        );
    IfCaseStatementResult<InvalidExpression> analysisResult =
        analyzeIfCaseElement(
          node: element,
          expression: element.expression,
          pattern: element.patternGuard.pattern,
          variables: {
            for (InternalVariable variable
                in element.patternGuard.pattern.declaredVariables)
              variable.cosmeticName!: variable,
          },
          guard: element.patternGuard.guard,
          ifTrue: element.then,
          ifFalse: element.otherwise,
          context: context,
        );

    DartType matchedValueType = analysisResult.matchedExpressionType
        .unwrapTypeView();

    assert(
      checkStack(element, stackBase, [
        /* ifFalse = */ ValueKinds.InferredElementOrNull,
        /* ifTrue = */ ValueKinds.InferredElement,
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern = */ ValueKinds.Pattern,
        /* scrutinee = */ ValueKinds.Expression,
      ]),
    );

    InferredElement? otherwise =
        popRewrite(NullValues.Expression) as InferredElement?;
    InferredElement then = popRewrite() as InferredElement;

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
      fileOffset: element.patternGuard.fileOffset,
    );

    DartType thenType = context.inferredConditionTypes[element.then]!;
    DartType? otherwiseType = element.otherwise == null
        ? null
        : context.inferredConditionTypes[element.otherwise!]!;
    InferredElement inferredElement = new InferredIfCaseElement(
      expression: expression,
      patternGuard: patternGuard,
      then: then,
      otherwise: otherwise,
      matchedValueType: matchedValueType,
      nodeForTesting: element,
      fileOffset: element.fileOffset,
    );
    return new ElementInferenceResult(
      inferredType: otherwiseType == null
          ? thenType
          : typeSchemaEnvironment.getStandardUpperBound(
              thenType,
              otherwiseType,
            ),
      element: inferredElement,
    );
  }

  ElementInferenceResult _inferPatternForElement(
    PatternForElement element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    int? stackBase;
    assert(checkStackBase(element, stackBase = stackHeight));

    InternalPatternVariableDeclaration internalPatternVariableDeclaration =
        element.patternVariableDeclaration;
    PatternVariableDeclarationAnalysisResult analysisResult =
        analyzePatternVariableDeclaration(
          internalPatternVariableDeclaration,
          internalPatternVariableDeclaration.pattern,
          internalPatternVariableDeclaration.initializer,
          isFinal: internalPatternVariableDeclaration.isFinal,
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
    PatternVariableDeclaration patternVariableDeclaration = extern
        .createPatternVariableDeclaration(
          pattern: pattern,
          initializer: initializer,
          isFinal: internalPatternVariableDeclaration.isFinal,
          matchedValueType: matchedValueType,
          fileOffset: internalPatternVariableDeclaration.fileOffset,
        );

    List<Variable> declaredVariables = pattern.declaredVariables;
    assert(declaredVariables.length == element.intermediateVariables.length);
    assert(declaredVariables.length == element.variables.length);
    List<VariableDeclaration> intermediateVariables = new List.filled(
      element.intermediateVariables.length,
      dummyVariableDeclaration,
    );
    for (int i = 0; i < declaredVariables.length; i++) {
      DartType type = declaredVariables[i].type;

      InternalVariableDeclaration intermediateVariableDeclaration =
          element.intermediateVariables[i];
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

      element.variables[i].variable.type = type;
    }

    ForElementBaseResult result = _inferForElementBase(
      element,
      inferredTypeArgument,
      inferredConditionTypes,
    );
    return new ElementInferenceResult(
      inferredType: result.inferredType,
      element: new InferredPatternForElement(
        patternVariableDeclaration: patternVariableDeclaration,
        intermediateVariables: intermediateVariables,
        variables: result.variables,
        condition: result.condition,
        updates: result.updates,
        body: result.body,
        nodeForTesting: element,
        fileOffset: element.fileOffset,
      ),
    );
  }

  ElementInferenceResult _inferForElement(
    ForElement element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    ForElementBaseResult result = _inferForElementBase(
      element,
      inferredTypeArgument,
      inferredConditionTypes,
    );
    return new ElementInferenceResult(
      inferredType: result.inferredType,
      element: new InferredForElement(
        variables: result.variables,
        condition: result.condition,
        updates: result.updates,
        body: result.body,
        nodeForTesting: element,
        fileOffset: element.fileOffset,
      ),
    );
  }

  ForElementBaseResult _inferForElementBase(
    ForElementBase element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    List<VariableDeclaration> variables = new List.filled(
      element.variables.length,
      dummyVariableDeclaration,
      growable: true,
    );
    for (int index = 0; index < element.variables.length; index++) {
      InternalVariableDeclaration variableDeclaration =
          element.variables[index];
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

    flowAnalysis.for_conditionBegin(element);
    Expression? condition;
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
      condition = assignableCondition;
      inferredConditionTypes[condition] = conditionResult.inferredType;
    }
    flowAnalysis.for_bodyBegin(null, switch (condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => getExpressionInfo(condition),
    });
    ElementInferenceResult bodyResult = inferElement(
      element.body,
      inferredTypeArgument,
      inferredConditionTypes,
    );
    InferredElement body = bodyResult.element;
    flowAnalysis.for_updaterBegin();
    List<Expression> updates = new List.filled(
      element.updates.length,
      dummyExpression,
    );
    for (int index = 0; index < element.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
        element.updates[index],
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

  ElementInferenceResult _inferForInElement(
    ForInElement element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
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
    ForInHeaderResult result = element.element.inferForInHeader(
      this,
      node: element,
      iterable: element.iterable,
      isAsync: element.isAsync,
      forOffset: element.forOffset,
    );

    DeclaredVariable variable = result.loopVariable;
    Expression iterable = result.iterable;

    flowAnalysis.forEach_bodyBegin(element);

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

    ElementInferenceResult bodyResult = inferElement(
      element.body,
      inferredTypeArgument,
      inferredConditionTypes,
    );
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
        isAsync: element.isAsync,
        scope: scope,
        nodeForTesting: element,
        fileOffset: element.fileOffset,
      ),
    );
  }

  ElementInferenceResult inferElement(
    Expression element,
    DartType inferredTypeArgument,
    Map<Expression, DartType> inferredConditionTypes,
  ) {
    if (element is ControlFlowElement) {
      switch (element) {
        case SpreadElement():
          return _inferSpreadElement(
            element,
            inferredTypeArgument,
            inferredConditionTypes,
          );
        case NullAwareElement():
          return _inferNullAwareElement(
            element,
            inferredTypeArgument,
            inferredConditionTypes,
          );
        case IfElement():
          return _inferIfElement(
            element,
            inferredTypeArgument,
            inferredConditionTypes,
          );
        case IfCaseElement():
          return _inferIfCaseElement(
            element,
            inferredTypeArgument,
            inferredConditionTypes,
          );
        case ForElement():
          return _inferForElement(
            element,
            inferredTypeArgument,
            inferredConditionTypes,
          );
        case PatternForElement():
          return _inferPatternForElement(
            element,
            inferredTypeArgument,
            inferredConditionTypes,
          );
        case ForInElement():
          return _inferForInElement(
            element,
            inferredTypeArgument,
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
      return new ElementInferenceResult(
        inferredType: result.inferredType,
        element: new InferredExpressionElement(
          expression: result.expression,
          fileOffset: element.fileOffset,
        ),
      );
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

  void _checkElement({
    required InferredElement element,
    required DartType typeArgument,
  }) {
    switch (element) {
      case InferredSpreadElement():
        DartType spreadType = element.expressionType;
        if (spreadType is DynamicType) {
          Expression expression = ensureAssignable(
            coreTypes.iterableRawType(
              element.isNullAware
                  ? Nullability.nullable
                  : Nullability.nonNullable,
            ),
            spreadType,
            element.expression,
          );
          element.expression = expression..parent = element;
        }
      case InferredIfElement():
        _checkElement(element: element.then, typeArgument: typeArgument);
        if (element.otherwise != null) {
          _checkElement(
            element: element.otherwise!,
            typeArgument: typeArgument,
          );
        }
      case InferredIfCaseElement():
        _checkElement(element: element.then, typeArgument: typeArgument);
        if (element.otherwise != null) {
          _checkElement(
            element: element.otherwise!,
            typeArgument: typeArgument,
          );
        }
      case InferredForElement():
        _checkElement(element: element.body, typeArgument: typeArgument);
      case InferredPatternForElement():
        _checkElement(element: element.body, typeArgument: typeArgument);
      case InferredForInElement():
        _checkElement(element: element.body, typeArgument: typeArgument);
      case InferredNullAwareElement():
      case InferredExpressionElement():
      // Do nothing.  Assignability checks are done during type inference.
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitListLiteral(
    ListLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalListLiteral(
    InternalListLiteral node,
    DartType typeContext,
  ) {
    Class listClass = coreTypes.listClass;
    InterfaceType listType = coreTypes.thisInterfaceType(
      listClass,
      Nullability.nonNullable,
    );
    List<DartType>? inferredTypes;
    DartType typeArgument;
    bool inferenceNeeded = node.typeArgument == null;
    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];
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
      typeArgument = inferredTypes[0];
    } else {
      typeArgument = node.typeArgument!;
    }
    List<InferredElement> elements = new List.filled(
      node.expressions.length,
      dummyInferredElement,
    );
    for (int index = 0; index < node.expressions.length; ++index) {
      ElementInferenceResult result = inferElement(
        node.expressions[index],
        typeArgument,
        inferredConditionTypes,
      );
      elements[index] = result.element;
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
      typeArgument = inferredTypes[0];
    }
    for (int i = 0; i < elements.length; i++) {
      InferredElement element = elements[i];
      _checkElement(element: element, typeArgument: typeArgument);
    }
    DartType inferredType = new InterfaceType(
      listClass,
      Nullability.nonNullable,
      [typeArgument],
    );
    if (inferenceNeeded) {
      if (!libraryBuilder.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(typeArgument, node.fileOffset);
      }
    }

    Expression result = _translateListLiteral(
      typeArgument: typeArgument,
      elements: elements,
      isConst: node.isConst,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result);
    dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.externalToInternalNodeMap[result] =
        node;
    return new ExpressionInferenceResult(inferredType, result);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRecordLiteral(
    RecordLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitLogicalExpression(
    LogicalExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    Expression left = ensureAssignableResult(boolType, leftResult).expression;
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
    Expression right = ensureAssignableResult(boolType, rightResult).expression;
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
    ?.registerAlias(node, replacement);
    return new ExpressionInferenceResult(boolType, replacement);
  }

  Expression _translateNonConstListOrSet({
    required DartType elementType,
    required List<InferredElement> elements,
    required bool isSet,
    required int fileOffset,
  }) {
    // Translate elements in place up to the first non-expression, if any.
    int index = 0;
    for (; index < elements.length; ++index) {
      if (elements[index] is! InferredExpressionElement) break;
    }

    // If there were only expressions, we are done.
    if (index == elements.length) {
      if (isSet) {
        return _lowerSetLiteral(
          _createSetLiteral(
            elementType: elementType,
            expressions: _convertElementsToExpressions(elements),
            fileOffset: fileOffset,
            isConst: false,
          ),
        );
      } else {
        return _createListLiteral(
          elementType: elementType,
          expressions: _convertElementsToExpressions(elements),
          fileOffset: fileOffset,
          isConst: false,
        );
      }
    }

    InterfaceType receiverType = isSet
        ? typeSchemaEnvironment.setType(elementType, Nullability.nonNullable)
        : typeSchemaEnvironment.listType(elementType, Nullability.nonNullable);
    DeclaredVariable? result;
    if (index == 0 && elements[index] is InferredSpreadElement) {
      InferredSpreadElement initialSpread =
          elements[index] as InferredSpreadElement;
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
                ..fileOffset = fileOffset,
            )..fileOffset = fileOffset,
            receiverType,
          );
        } else {
          result = _createVariable(
            new StaticInvocation(
              engine.listOf,
              new Arguments([value], types: [elementType])
                ..fileOffset = fileOffset,
            )..fileOffset = fileOffset,
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
                elementType: elementType,
                expressions: _convertElementsToExpressions(
                  elements,
                  count: index,
                ),
                fileOffset: fileOffset,
                isConst: false,
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
              new Arguments([], types: [elementType])..fileOffset = fileOffset,
            )..fileOffset = fileOffset,
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
              elements[j] as InferredExpressionElement,
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
            elementType: elementType,
            expressions: _convertElementsToExpressions(elements, count: index),
            fileOffset: fileOffset,
            isConst: false,
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
      fileOffset,
      _createBlock(body),
      _createVariableGet(result),
    );
  }

  void _translateElement(
    InferredElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    switch (element) {
      case InferredSpreadElement():
        _translateSpreadElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredNullAwareElement():
        _translateNullAwareElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredIfElement():
        _translateIfElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredIfCaseElement():
        _translateIfCaseElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredForElement():
        _translateForElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredPatternForElement():
        _translatePatternForElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredForInElement():
        _translateForInElement(
          element,
          receiverType,
          elementType,
          result,
          body,
          isSet: isSet,
        );
      case InferredExpressionElement():
        _addExpressionElement(
          element,
          receiverType,
          result,
          body,
          isSet: isSet,
        );
    }
  }

  void _addExpressionElement(
    InferredExpressionElement element,
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
          element.expression,
          isSet: isSet,
        ),
      ),
    );
  }

  void _translateIfElement(
    InferredIfElement element,
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
    ?.registerAlias(element.nodeForTesting, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfCaseElement(
    InferredIfCaseElement element,
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
    ?.registerAlias(element.nodeForTesting, ifCaseStatement);
    body.add(ifCaseStatement);
  }

  void _translateForElement(
    InferredForElement element,
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
    ?.registerAlias(element.nodeForTesting, loop);
    body.add(loop);
  }

  void _translatePatternForElement(
    InferredPatternForElement element,
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
    ?.registerAlias(element.nodeForTesting, loop);
    body.add(element.patternVariableDeclaration);
    for (VariableDeclaration intermediateVariable
        in element.intermediateVariables) {
      body.add(extern.createVariableStatement(intermediateVariable));
    }
    body.add(loop);
  }

  void _translateForInElement(
    InferredForInElement element,
    InterfaceType receiverType,
    DartType elementType,
    Variable result,
    List<Statement> body, {
    required bool isSet,
  }) {
    List<Statement> statements;
    Statement? bodyPrologue = element.encoding.bodyPrologue;
    if (bodyPrologue == null) {
      statements = [];
    } else {
      statements = bodyPrologue is Block
          ? bodyPrologue.statements
          : [bodyPrologue];
    }
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
    Statement loop = _createForInStatement(
      element.fileOffset,
      element.variable,
      element.iterable,
      loopBody,
      isAsync: element.isAsync,
    )..scope = element.scope;
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(element.nodeForTesting, loop);

    InvalidExpression? preLoopError = element.encoding.preLoopError;
    if (preLoopError != null) {
      loop = createBlock([
        createExpressionStatement(preLoopError),
        loop,
      ], fileOffset: element.fileOffset);
    }
    body.add(loop);
  }

  void _translateSpreadElement(
    InferredSpreadElement element,
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
      DeclaredVariable? temp;
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
      DeclaredVariable? temp;
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

      DeclaredVariable variable = _createForInVariable(
        element.fileOffset,
        const DynamicType(),
      );
      DeclaredVariable castedVar = _createVariable(
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
    InferredNullAwareElement element,
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
    DeclaredVariable temp = _createVariable(value, nullableElementType);
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

  List<Expression> _convertElementsToExpressions(
    List<InferredElement> elements, {
    int? count,
  }) {
    return new List.generate(
      count ?? elements.length,
      (int index) => (elements[index] as InferredExpressionElement).expression,
    );
  }

  Expression _translateListLiteral({
    required DartType typeArgument,
    required List<InferredElement> elements,
    required bool isConst,
    required int fileOffset,
  }) {
    if (isConst) {
      return _translateConstListOrSet(
        elementType: typeArgument,
        elements: elements,
        isSet: false,
        fileOffset: fileOffset,
      );
    } else {
      return _translateNonConstListOrSet(
        elementType: typeArgument,
        elements: elements,
        isSet: false,
        fileOffset: fileOffset,
      );
    }
  }

  Expression _translateSetLiteral({
    required DartType typeArgument,
    required List<InferredElement> elements,
    required bool isConst,
    required int fileOffset,
  }) {
    if (isConst) {
      return _translateConstListOrSet(
        elementType: typeArgument,
        elements: elements,
        isSet: true,
        fileOffset: fileOffset,
      );
    } else {
      return _translateNonConstListOrSet(
        elementType: typeArgument,
        elements: elements,
        isSet: true,
        fileOffset: fileOffset,
      );
    }
  }

  Expression _translateMapLiteral({
    required List<InferredMapLiteralEntry> entries,
    required DartType keyType,
    required DartType valueType,
    required bool isConst,
    required int fileOffset,
  }) {
    if (isConst) {
      return _translateConstMap(
        entries: entries,
        keyType: keyType,
        valueType: valueType,
        fileOffset: fileOffset,
      );
    } else {
      return _translateNonConstMap(
        entries: entries,
        keyType: keyType,
        valueType: valueType,
        fileOffset: fileOffset,
      );
    }
  }

  Expression _translateNonConstMap({
    required List<InferredMapLiteralEntry> entries,
    required DartType keyType,
    required DartType valueType,
    required int fileOffset,
  }) {
    // Translate entries in place up to the first control-flow entry, if any.
    int index = 0;
    for (; index < entries.length; ++index) {
      if (entries[index] is! InferredRegularMapLiteralEntry) break;
    }

    // If there were no control-flow entries we are done.
    if (index == entries.length) {
      return _createMapLiteral(
        fileOffset: fileOffset,
        keyType: keyType,
        valueType: valueType,
        entries: entries,
        isConst: false,
      );
    }

    // Build a block expression and create an empty map.
    InterfaceType receiverType = typeSchemaEnvironment.mapType(
      keyType,
      valueType,
      Nullability.nonNullable,
    );
    DeclaredVariable? result;

    if (index == 0 && entries[index] is InferredSpreadMapEntry) {
      InferredSpreadMapEntry initialSpread =
          entries[index] as InferredSpreadMapEntry;
      final InterfaceType entryType = new InterfaceType(
        engine.mapEntryClass,
        Nullability.nonNullable,
        <DartType>[keyType, valueType],
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
              new Arguments([value], types: [keyType, valueType])
                ..fileOffset = fileOffset,
            )..fileOffset = fileOffset,
            receiverType,
          );
        }
      }
    }

    List<Statement>? body;
    if (result == null) {
      result = _createVariable(
        _createMapLiteral(
          fileOffset: fileOffset,
          keyType: keyType,
          valueType: valueType,
          entries: [],
          isConst: false,
        ),
        receiverType,
      );
      body = [
        extern.createVariableStatement(
          extern.createVariableDeclaration(result),
        ),
      ];
      // Add all the entries up to the first control-flow entry.
      for (int j = 0; j < index; ++j) {
        _addNormalEntry(
          entries[j] as InferredRegularMapLiteralEntry,
          receiverType,
          result,
          body,
        );
      }
    }

    body ??= [
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    ];

    // Translate the elements starting with the first non-expression.
    for (; index < entries.length; ++index) {
      _translateEntry(
        entries[index],
        receiverType,
        keyType,
        valueType,
        result,
        body,
      );
    }

    return _createBlockExpression(
      fileOffset,
      _createBlock(body),
      _createVariableGet(result),
    );
  }

  void _translateEntry(
    InferredMapLiteralEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    switch (entry) {
      case InferredSpreadMapEntry():
        _translateSpreadEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredNullAwareMapEntry():
        _translateNullAwareMapEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredIfMapEntry():
        _translateIfEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredIfCaseMapEntry():
        _translateIfCaseEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredPatternForMapEntry():
        _translatePatternForEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredForMapEntry():
        _translateForEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredForInMapEntry():
        _translateForInEntry(
          entry,
          receiverType,
          keyType,
          valueType,
          result,
          body,
        );
      case InferredRegularMapLiteralEntry():
        _addNormalEntry(entry, receiverType, result, body);
    }
  }

  void _addNormalEntry(
    InferredRegularMapLiteralEntry entry,
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
    InferredIfMapEntry entry,
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
    ?.registerAlias(entry.nodeForTesting, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfCaseEntry(
    InferredIfCaseMapEntry entry,
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
      entry.matchedValueType,
      entry.patternGuard,
      thenStatement,
      elseStatement,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(entry.nodeForTesting, ifStatement);
    body.add(ifStatement);
  }

  void _translateForEntry(
    InferredForMapEntry entry,
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
    ?.registerAlias(entry.nodeForTesting, loop);
    body.add(loop);
  }

  void _translatePatternForEntry(
    InferredPatternForMapEntry entry,
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
    ?.registerAlias(entry.nodeForTesting, loop);
    body.add(entry.patternVariableDeclaration);
    for (VariableDeclaration intermediateVariable
        in entry.intermediateVariables) {
      body.add(extern.createVariableStatement(intermediateVariable));
    }
    body.add(loop);
  }

  void _translateForInEntry(
    InferredForInMapEntry entry,
    InterfaceType receiverType,
    DartType keyType,
    DartType valueType,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements;
    Statement? bodyPrologue = entry.encoding.bodyPrologue;
    if (bodyPrologue == null) {
      statements = [];
    } else {
      statements = bodyPrologue is Block
          ? bodyPrologue.statements
          : [bodyPrologue];
    }
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
    Statement loop = _createForInStatement(
      entry.fileOffset,
      entry.variable,
      entry.iterable,
      loopBody,
      isAsync: entry.isAsync,
    )..scope = entry.scope;
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(entry.nodeForTesting, loop);

    InvalidExpression? preLoopError = entry.encoding.preLoopError;
    if (preLoopError != null) {
      loop = createBlock([
        createExpressionStatement(preLoopError),
        loop,
      ], fileOffset: entry.fileOffset);
    }

    body.add(loop);
  }

  void _translateSpreadEntry(
    InferredSpreadMapEntry entry,
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
      DeclaredVariable? temp;
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
      DeclaredVariable? temp;
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
      DeclaredVariable variable = _createForInVariable(
        entry.fileOffset,
        variableType,
      );
      DeclaredVariable keyVar = _createVariable(
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
      DeclaredVariable valueVar = _createVariable(
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
    InferredNullAwareMapEntry entry,
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
      DeclaredVariable valueTemp = _createVariable(
        valueExpression,
        nullableValueType,
      );
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
      DeclaredVariable keyTemp = _createVariable(
        keyExpression,
        nullableKeyType,
      );
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

      DeclaredVariable keyTemp = _createVariable(keyExpression, keyType);
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

  Expression _translateConstListOrSet({
    required DartType elementType,
    required List<InferredElement> elements,
    required int fileOffset,
    required bool isSet,
  }) {
    // Translate elements in place up to the first non-expression, if any.
    int i = 0;
    for (; i < elements.length; ++i) {
      if (elements[i] is! InferredExpressionElement) break;
    }

    // If there were only expressions, we are done.
    if (i == elements.length) {
      if (isSet) {
        return _createSetLiteral(
          elementType: elementType,
          expressions: _convertElementsToExpressions(elements),
          isConst: true,
          fileOffset: fileOffset,
        );
      } else {
        return _createListLiteral(
          elementType: elementType,
          expressions: _convertElementsToExpressions(elements),
          isConst: true,
          fileOffset: fileOffset,
        );
      }
    }

    Expression makeLiteral(int fileOffset, List<InferredElement> elements) {
      if (isSet) {
        return _translateConstListOrSet(
          elementType: elementType,
          elements: elements,
          isSet: true,
          fileOffset: fileOffset,
        );
      } else {
        return _translateConstListOrSet(
          elementType: elementType,
          elements: elements,
          isSet: false,
          fileOffset: fileOffset,
        );
      }
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<InferredElement>? currentPart = i > 0 ? elements.sublist(0, i) : null;

    DartType iterableType = typeSchemaEnvironment.iterableType(
      elementType,
      Nullability.nonNullable,
    );

    for (; i < elements.length; ++i) {
      InferredElement element = elements[i];
      switch (element) {
        case InferredSpreadElement():
          if (currentPart != null) {
            parts.add(makeLiteral(fileOffset, currentPart));
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
        case InferredNullAwareElement():
          if (currentPart != null) {
            // Coverage-ignore-block(suite): Not run.
            parts.add(makeLiteral(fileOffset, currentPart));
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
                // TODO(johnniwinther): Avoid creating an
                //  [InferredExpressionElement] here.
                new InferredExpressionElement(
                  expression: _createNullCheckedVariableGet(temp),
                  fileOffset: element.fileOffset,
                ),
              ]),
            ),
          );
        case InferredIfElement():
          if (currentPart != null) {
            // Coverage-ignore-block(suite): Not run.
            parts.add(makeLiteral(fileOffset, currentPart));
            currentPart = null;
          }
          Expression condition = element.condition;
          Expression then = makeLiteral(element.then.fileOffset, [
            element.then,
          ]);
          Expression otherwise = element.otherwise != null
              ?
                // Coverage-ignore(suite): Not run.
                makeLiteral(element.otherwise!.fileOffset, [element.otherwise!])
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
        case InferredIfCaseElement():
        case InferredForElement():
        case InferredPatternForElement():
        case InferredForInElement():
          // Coverage-ignore(suite): Not run.
          // Rejected earlier.
          problems.unhandled(
            "${element.runtimeType}",
            "_translateConstListOrSet",
            element.fileOffset,
            fileUri,
          );
        case InferredExpressionElement():
          currentPart ??= [];
          currentPart.add(element);
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(fileOffset, currentPart));
    }
    if (isSet) {
      return new SetConcatenation(parts, typeArgument: elementType)
        ..fileOffset = fileOffset;
    } else {
      return new ListConcatenation(parts, typeArgument: elementType)
        ..fileOffset = fileOffset;
    }
  }

  Expression _translateConstMap({
    required List<InferredMapLiteralEntry> entries,
    required DartType keyType,
    required DartType valueType,
    required int fileOffset,
  }) {
    // Translate entries in place up to the first control-flow entry, if any.
    int i = 0;
    for (; i < entries.length; ++i) {
      if (entries[i] is! InferredRegularMapLiteralEntry) break;
    }

    // If there were no control-flow entries we are done.
    if (i == entries.length) {
      return _createMapLiteral(
        fileOffset: fileOffset,
        keyType: keyType,
        valueType: valueType,
        entries: entries,
        isConst: true,
      );
    }

    Expression makeLiteral(
      int fileOffset,
      List<InferredMapLiteralEntry> entries,
    ) {
      return _translateConstMap(
        fileOffset: fileOffset,
        keyType: keyType,
        valueType: valueType,
        entries: entries,
      );
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<InferredMapLiteralEntry>? currentPart = i > 0
        ? entries.sublist(0, i)
        : null;

    DartType collectionType = typeSchemaEnvironment.mapType(
      keyType,
      valueType,
      Nullability.nonNullable,
    );

    for (; i < entries.length; ++i) {
      InferredMapLiteralEntry entry = entries[i];
      switch (entry) {
        case InferredSpreadMapEntry():
          if (currentPart != null) {
            parts.add(makeLiteral(fileOffset, currentPart));
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
        case InferredNullAwareMapEntry():
          assert(entry.isKeyNullAware || entry.isValueNullAware);
          if (currentPart != null) {
            // Coverage-ignore-block(suite): Not run.
            parts.add(makeLiteral(fileOffset, currentPart));
            currentPart = null;
          }

          Expression desugaredExpression = extern.createNullLiteral(
            fileOffset: TreeNode.noOffset,
          );

          if (entry.isKeyNullAware && entry.isValueNullAware) {
            SyntheticVariable keyTemp = _createVariable(
              entry.key,
              keyType.withDeclaredNullability(Nullability.nullable),
            );
            Expression keyExpression = _createNullCheckedVariableGet(keyTemp);

            SyntheticVariable valueTemp = _createVariable(
              entry.value,
              valueType.withDeclaredNullability(Nullability.nullable),
            );
            Expression valueExpression = _createNullCheckedVariableGet(
              valueTemp,
            );

            InferredMapLiteralEntry addedMapLiteralEntry =
                new InferredRegularMapLiteralEntry(
                  keyExpression,
                  valueExpression,
                  fileOffset: entry.fileOffset,
                );
            Expression nullCheckedKeyValue = makeLiteral(
              entry.value.fileOffset,
              [addedMapLiteralEntry],
            );
            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              valueTemp,
              makeLiteral(entry.fileOffset, []),
              collectionType,
              nullCheckedValue: nullCheckedKeyValue,
            );
            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              keyTemp,
              makeLiteral(entry.fileOffset, []),
              collectionType,
              nullCheckedValue: desugaredExpression,
            );
          } else if (entry.isValueNullAware) {
            SyntheticVariable valueTemp = _createVariable(
              entry.value,
              valueType.withDeclaredNullability(Nullability.nullable),
            );
            Expression valueExpression = _createNullCheckedVariableGet(
              valueTemp,
            );
            Expression defaultValue = makeLiteral(entry.fileOffset, []);
            InferredMapLiteralEntry addedMapLiteralEntry =
                new InferredRegularMapLiteralEntry(
                  entry.key,
                  valueExpression,
                  fileOffset: entry.fileOffset,
                );
            Expression nullCheckedValue = makeLiteral(entry.value.fileOffset, [
              addedMapLiteralEntry,
            ]);
            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              valueTemp,
              defaultValue,
              collectionType,
              nullCheckedValue: nullCheckedValue,
            );
          } else {
            assert(entry.isKeyNullAware);
            SyntheticVariable keyTemp = _createVariable(
              entry.key,
              keyType.withDeclaredNullability(Nullability.nullable),
            );
            Expression keyExpression = _createNullCheckedVariableGet(keyTemp);
            Expression defaultValue = makeLiteral(entry.fileOffset, []);

            InferredMapLiteralEntry addedMapLiteralEntry =
                new InferredRegularMapLiteralEntry(
                  keyExpression,
                  entry.value,
                  fileOffset: entry.fileOffset,
                );
            Expression nullCheckedKey = makeLiteral(entry.key.fileOffset, [
              addedMapLiteralEntry,
            ]);

            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              keyTemp,
              defaultValue,
              collectionType,
              nullCheckedValue: nullCheckedKey,
            );
          }

          parts.add(desugaredExpression);
        case InferredIfMapEntry():
          if (currentPart != null) {
            // Coverage-ignore-block(suite): Not run.
            parts.add(makeLiteral(fileOffset, currentPart));
            currentPart = null;
          }
          // Coverage-ignore(suite): Not run.
          Expression condition = entry.condition;
          // Coverage-ignore(suite): Not run.
          Expression then = makeLiteral(entry.then.fileOffset, [entry.then]);
          // Coverage-ignore(suite): Not run.
          Expression otherwise = entry.otherwise != null
              ? makeLiteral(entry.otherwise!.fileOffset, [entry.otherwise!])
              : makeLiteral(fileOffset, []);
          // Coverage-ignore(suite): Not run.
          parts.add(
            _createConditionalExpression(
              entry.fileOffset,
              condition,
              then,
              otherwise,
              collectionType,
            ),
          );
        case InferredIfCaseMapEntry():
        case InferredPatternForMapEntry():
        case InferredForMapEntry():
        case InferredForInMapEntry():
          // Coverage-ignore(suite): Not run.
          // Rejected earlier.
          problems.unhandled(
            "${entry.runtimeType}",
            "_translateConstMap",
            entry.fileOffset,
            fileUri,
          );
        case InferredRegularMapLiteralEntry():
          currentPart ??= [];
          currentPart.add(entry);
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(fileOffset, currentPart));
    }
    return new MapConcatenation(parts, keyType: keyType, valueType: valueType);
  }

  SyntheticVariable _createVariable(Expression expression, DartType type) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return extern.createVariableCache(expression, type);
  }

  DeclaredVariable _createForInVariable(int fileOffset, DartType type) {
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

  MapLiteral _createMapLiteral({
    required int fileOffset,
    required DartType keyType,
    required DartType valueType,
    required List<InferredMapLiteralEntry> entries,
    required bool isConst,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new MapLiteral(
      new List.generate(entries.length, (int index) {
        InferredRegularMapLiteralEntry entry =
            entries[index] as InferredRegularMapLiteralEntry;
        return extern.createMapLiteralEntry(
          entry.key,
          entry.value,
          fileOffset: entry.fileOffset,
        );
      }),
      keyType: keyType,
      valueType: valueType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }

  ListLiteral _createListLiteral({
    required int fileOffset,
    required DartType elementType,
    required List<Expression> expressions,
    required bool isConst,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new ListLiteral(
      expressions,
      typeArgument: elementType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }

  SetLiteral _createSetLiteral({
    required int fileOffset,
    required DartType elementType,
    required List<Expression> expressions,
    required bool isConst,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new SetLiteral(
      expressions,
      typeArgument: elementType,
      isConst: isConst,
    )..fileOffset = fileOffset;
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
    DeclaredVariable variable,
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

  InferredMapLiteralEntry _inferSpreadMapEntry(
    SpreadMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
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
    Expression expression = spreadResult.expression;
    final DartType spreadType = spreadResult.inferredType;
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

    InferredMapLiteralEntry? replacement;

    if (actualKeyType == noInferredType) {
      if (coreTypes.isNull(spreadTypeBound) && !entry.isNullAware) {
        replacement = new InferredRegularMapLiteralEntry(
          extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nonNullAwareSpreadIsNull.withArguments(
                spreadType: spreadType,
              ),
              fileUri: fileUri,
              fileOffset: entry.expression.fileOffset,
              length: 1,
            ),
          ),
          extern.createNullLiteral(fileOffset: TreeNode.noOffset),
          fileOffset: entry.fileOffset,
        );
      } else if (actualElementType != null) {
        if (spreadType.isPotentiallyNullable &&
            spreadType is! DynamicType &&
            spreadType is! NullType &&
            !entry.isNullAware) {
          Expression receiver = entry.expression;
          Expression problem = extern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.nullableSpreadError,
              fileUri: fileUri,
              fileOffset: receiver.fileOffset,
              length: 1,
              context: getWhyNotPromotedContext(
                flowAnalysis.whyNotPromoted(getExpressionInfo(receiver))(),
                entry,
                // Coverage-ignore(suite): Not run.
                (type) => !type.isPotentiallyNullable,
              ),
            ),
          );
          _copyNonPromotionReasonToReplacement(entry, problem);
          // TODO(johnniwinther): Should we create a regular map literal entry
          // like below?
          expression = problem;
        }

        // Don't report the error here, it might be an ambiguous Set.  The
        // error is reported in checkMapEntry if it's disambiguated as map.
        offsets.iterableSpreadType = spreadType;
      } else {
        Expression receiver = entry.expression;
        Expression problem = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.spreadMapEntryTypeMismatch.withArguments(
              spreadType: spreadType,
            ),
            fileUri: fileUri,
            fileOffset: receiver.fileOffset,
            length: 1,
            context: getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(getExpressionInfo(receiver))(),
              entry,
              // Coverage-ignore(suite): Not run.
              (type) => !type.isPotentiallyNullable,
            ),
          ),
        );
        _copyNonPromotionReasonToReplacement(entry, problem);
        replacement = new InferredRegularMapLiteralEntry(
          problem,
          extern.createNullLiteral(fileOffset: TreeNode.noOffset),
          fileOffset: entry.fileOffset,
        );
      }
    } else if (spreadTypeBound is InterfaceType) {
      Expression? keyError;
      Expression? valueError;
      if (!isAssignable(inferredKeyType, actualKeyType)) {
        keyError = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.spreadMapEntryElementKeyTypeMismatch.withArguments(
              spreadKeyType: actualKeyType,
              mapKeyType: inferredKeyType,
            ),
            fileUri: fileUri,
            fileOffset: entry.expression.fileOffset,
            length: 1,
          ),
        );
      }
      if (!isAssignable(inferredValueType, actualValueType)) {
        valueError = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.spreadMapEntryElementValueTypeMismatch.withArguments(
              spreadValueType: actualValueType,
              mapValueType: inferredValueType,
            ),
            fileUri: fileUri,
            fileOffset: entry.expression.fileOffset,
            length: 1,
          ),
        );
      }
      if (spreadType.isPotentiallyNullable &&
          spreadType is! DynamicType &&
          spreadType is! NullType &&
          !entry.isNullAware) {
        Expression receiver = entry.expression;
        keyError = extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nullableSpreadError,
            fileUri: fileUri,
            fileOffset: receiver.fileOffset,
            length: 1,
            context: getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(getExpressionInfo(receiver))(),
              entry,
              // Coverage-ignore(suite): Not run.
              (type) => !type.isPotentiallyNullable,
            ),
          ),
        );
        _copyNonPromotionReasonToReplacement(entry, keyError);
      }
      if (keyError != null || valueError != null) {
        keyError ??= extern.createNullLiteral(fileOffset: TreeNode.noOffset);
        valueError ??= extern.createNullLiteral(fileOffset: TreeNode.noOffset);
        replacement = new InferredRegularMapLiteralEntry(
          keyError,
          valueError,
          fileOffset: entry.fileOffset,
        );
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
    DartType entryType = new InterfaceType(
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

    return replacement ??
        new InferredSpreadMapEntry(
          expression: expression,
          expressionType: spreadType,
          isNullAware: entry.isNullAware,
          entryType: entryType,
          nodeForTesting: entry,
          fileOffset: entry.fileOffset,
        );
  }

  InferredMapLiteralEntry _inferNullAwareMapEntry(
    NullAwareMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
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

    flowAnalysis.nullAwareMapEntry_valueBegin(
      getExpressionInfo(key),
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

    return new InferredNullAwareMapEntry(
      isKeyNullAware: entry.isKeyNullAware,
      key: key,
      isValueNullAware: entry.isValueNullAware,
      value: value,
      fileOffset: entry.fileOffset,
    );
  }

  InferredMapLiteralEntry _inferIfMapEntry(
    IfMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
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

    flowAnalysis.ifStatement_thenBegin(getExpressionInfo(condition), entry);
    // Note that this recursive invocation of inferMapEntry will add two types
    // to actualTypes; they are the actual types of the current invocation if
    // the 'else' branch is empty.
    InferredMapLiteralEntry then = inferMapEntry(
      entry.then,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredConditionTypes,
      offsets,
    );

    InferredMapLiteralEntry? otherwise;
    if (entry.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      // We need to modify the actual types added in the recursive call to
      // inferMapEntry.
      DartType? actualValueType = actualTypes.removeLast();
      DartType? actualKeyType = actualTypes.removeLast();
      DartType actualTypeForSet = actualTypesForSet.removeLast();
      otherwise = inferMapEntry(
        entry.otherwise!,
        inferredKeyType,
        inferredValueType,
        spreadContext,
        actualTypes,
        actualTypesForSet,
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
    }
    flowAnalysis.ifStatement_end(entry.otherwise != null);
    return new InferredIfMapEntry(
      condition: condition,
      then: then,
      otherwise: otherwise,
      nodeForTesting: entry,
      fileOffset: entry.fileOffset,
    );
  }

  InferredMapLiteralEntry _inferIfCaseMapEntry(
    IfCaseMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
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
      inferredConditionTypes: inferredConditionTypes,
    );
    IfCaseStatementResult<InvalidExpression> analysisResult =
        analyzeIfCaseElement(
          node: entry,
          expression: entry.expression,
          pattern: entry.patternGuard.pattern,
          variables: {
            for (InternalVariable variable
                in entry.patternGuard.pattern.declaredVariables)
              variable.cosmeticName!: variable,
          },
          guard: entry.patternGuard.guard,
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

    DartType matchedValueType = analysisResult.matchedExpressionType
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

    InferredMapLiteralEntry? otherwise =
        popRewrite(NullValues.Expression) as InferredMapLiteralEntry?;

    InferredMapLiteralEntry then = popRewrite() as InferredMapLiteralEntry;

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
    PatternGuard patternGuard = extern.createPatternGuard(
      pattern: pattern,
      guard: guard,
      fileOffset: entry.patternGuard.fileOffset,
    );

    Expression expression = popRewrite() as Expression;

    return new InferredIfCaseMapEntry(
      expression: expression,
      patternGuard: patternGuard,
      then: then,
      otherwise: otherwise,
      matchedValueType: matchedValueType,
      nodeForTesting: entry,
      fileOffset: entry.fileOffset,
    );
  }

  InferredMapLiteralEntry _inferPatternForMapEntry(
    PatternForMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    int? stackBase;
    assert(checkStackBase(entry, stackBase = stackHeight));

    InternalPatternVariableDeclaration internalPatternVariableDeclaration =
        entry.patternVariableDeclaration;
    PatternVariableDeclarationAnalysisResult analysisResult =
        analyzePatternVariableDeclaration(
          internalPatternVariableDeclaration,
          internalPatternVariableDeclaration.pattern,
          internalPatternVariableDeclaration.initializer,
          isFinal: internalPatternVariableDeclaration.isFinal,
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
    PatternVariableDeclaration patternVariableDeclaration = extern
        .createPatternVariableDeclaration(
          pattern: pattern,
          initializer: initializer,
          isFinal: internalPatternVariableDeclaration.isFinal,
          matchedValueType: matchedValueType,
          fileOffset: internalPatternVariableDeclaration.fileOffset,
        );

    List<Variable> declaredVariables = pattern.declaredVariables;
    assert(declaredVariables.length == entry.intermediateVariables.length);
    assert(declaredVariables.length == entry.variables.length);
    List<VariableDeclaration> intermediateVariables = new List.filled(
      entry.intermediateVariables.length,
      dummyVariableDeclaration,
    );
    for (int i = 0; i < declaredVariables.length; i++) {
      DartType type = declaredVariables[i].type;

      InternalVariableDeclaration intermediateVariableDeclaration =
          entry.intermediateVariables[i];
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
      entry.variables[i].variable.type = type;
    }

    ForMapEntryBaseResult result = _inferForMapEntryBase(
      entry,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredConditionTypes,
      offsets,
    );
    return new InferredPatternForMapEntry(
      patternVariableDeclaration: patternVariableDeclaration,
      intermediateVariables: intermediateVariables,
      variables: result.variables,
      condition: result.condition,
      updates: result.updates,
      body: result.body,
      nodeForTesting: entry,
      fileOffset: entry.fileOffset,
    );
  }

  InferredMapLiteralEntry _inferForMapEntry(
    ForMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    ForMapEntryBaseResult result = _inferForMapEntryBase(
      entry,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredConditionTypes,
      offsets,
    );
    return new InferredForMapEntry(
      variables: result.variables,
      condition: result.condition,
      updates: result.updates,
      body: result.body,
      nodeForTesting: entry,
      fileOffset: entry.fileOffset,
    );
  }

  ForMapEntryBaseResult _inferForMapEntryBase(
    ForMapEntryBase entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    List<VariableDeclaration> variables = new List.filled(
      entry.variables.length,
      dummyVariableDeclaration,
      growable: true,
    );
    for (int index = 0; index < entry.variables.length; index++) {
      InternalVariableDeclaration variableDeclaration = entry.variables[index];
      InternalDeclaredVariable variable = variableDeclaration.variable;

      if (variable.cosmeticName == null) {
        Expression? initializer;
        if (variableDeclaration.initializer != null) {
          ExpressionInferenceResult result = inferExpression(
            variableDeclaration.initializer!,
            variable.type,
            isVoidAllowed: true,
          );
          initializer = result.expression;
          variable.type = result.inferredType;
        }
        variables[index] = createVariableDeclaration(
          variable.astVariable,
          initializer: initializer,
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

    flowAnalysis.for_conditionBegin(entry);
    Expression? condition;
    if (entry.condition != null) {
      ExpressionInferenceResult conditionResult = inferExpression(
        entry.condition!,
        coreTypes.boolRawType(Nullability.nonNullable),
        isVoidAllowed: false,
      );
      condition = ensureAssignable(
        coreTypes.boolRawType(Nullability.nonNullable),
        conditionResult.inferredType,
        conditionResult.expression,
      );
      inferredConditionTypes[entry.condition!] = conditionResult.inferredType;
    }
    flowAnalysis.for_bodyBegin(null, switch (condition) {
      null => flowAnalysis.booleanLiteral(true),
      var condition => getExpressionInfo(condition),
    });
    // Actual types are added by the recursive call.
    InferredMapLiteralEntry body = inferMapEntry(
      entry.body,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredConditionTypes,
      offsets,
    );

    flowAnalysis.for_updaterBegin();
    List<Expression> updates = new List.filled(
      entry.updates.length,
      dummyExpression,
    );
    for (int index = 0; index < entry.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
        entry.updates[index],
        const UnknownType(),
        isVoidAllowed: true,
      );
      updates[index] = updateResult.expression;
    }
    flowAnalysis.for_end();
    return new ForMapEntryBaseResult(
      variables: variables,
      condition: condition,
      body: body,
      updates: updates,
    );
  }

  InferredMapLiteralEntry _inferForInMapEntry(
    ForInMapEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      // [ForInMapEntry] will be desugared later into a [ForStatement], which
      // will be responsible for the scope. Therefore, the supplied
      // [ScopeProviderInfoKind] to [enterScopeProvider] is
      // [ScopeProviderInfoKind.ForInStatement].
      scopeProviderInfo = _contextAllocationStrategy.enterScopeProvider(
        scopeProviderInfoKind: ScopeProviderInfoKind.Loop,
      );
    }
    ForInHeaderResult result = entry.element.inferForInHeader(
      this,
      node: entry,
      iterable: entry.iterable,
      isAsync: entry.isAsync,
      forOffset: entry.forOffset,
    );
    DeclaredVariable variable = result.loopVariable;
    Expression iterable = result.iterable;

    flowAnalysis.forEach_bodyBegin(entry);

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

    // Actual types are added by the recursive call.
    InferredMapLiteralEntry body = inferMapEntry(
      entry.body,
      inferredKeyType,
      inferredValueType,
      spreadContext,
      actualTypes,
      actualTypesForSet,
      inferredConditionTypes,
      offsets,
    );

    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();
    Scope? scope;
    if (scopeProviderInfo != null) {
      _contextAllocationStrategy.exitScopeProvider(scopeProviderInfo);
      // The scope will later be passed to the [ForInStatement] the [entry]
      // is desugared into.
      scope = scopeProviderInfo.scope;
    }
    return new InferredForInMapEntry(
      variable: variable,
      encoding: encoding,
      iterable: iterable,
      body: body,
      isAsync: entry.isAsync,
      scope: scope,
      nodeForTesting: entry,
      fileOffset: entry.fileOffset,
    );
  }

  // Note that inferMapEntry adds exactly two elements to actualTypes -- the
  // actual types of the key and the value.  The same technique is used for
  // actualTypesForSet, only inferMapEntry adds exactly one element to that
  // list: the actual type of the iterable spread elements in case the map
  // literal will be disambiguated as a set literal later.
  InferredMapLiteralEntry inferMapEntry(
    InternalMapLiteralEntry entry,
    DartType inferredKeyType,
    DartType inferredValueType,
    DartType spreadContext,
    List<DartType> actualTypes,
    List<DartType> actualTypesForSet,
    Map<Expression, DartType> inferredConditionTypes,
    _MapLiteralEntryOffsets offsets,
  ) {
    switch (entry) {
      case SpreadMapEntry():
        return _inferSpreadMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case NullAwareMapEntry():
        return _inferNullAwareMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case IfMapEntry():
        return _inferIfMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case IfCaseMapEntry():
        return _inferIfCaseMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case ForMapEntry():
        return _inferForMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case PatternForMapEntry():
        return _inferPatternForMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case ForInMapEntry():
        return _inferForInMapEntry(
          entry,
          inferredKeyType,
          inferredValueType,
          spreadContext,
          actualTypes,
          actualTypesForSet,
          inferredConditionTypes,
          offsets,
        );
      case RegularMapLiteralEntry():
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
        actualTypes.add(keyResult.inferredType);
        actualTypes.add(valueResult.inferredType);
        // Use 'dynamic' for error recovery.
        actualTypesForSet.add(const DynamicType());
        offsets.mapEntryOffset = entry.fileOffset;
        return new InferredRegularMapLiteralEntry(
          key,
          value,
          fileOffset: entry.fileOffset,
        );
    }
  }

  InferredMapLiteralEntry _checkMapEntry(
    InferredMapLiteralEntry entry,
    DartType keyType,
    DartType valueType,
    _MapLiteralEntryOffsets offsets,
  ) {
    // It's disambiguated as a map literal.
    InferredMapLiteralEntry replacement = entry;
    if (offsets.iterableSpreadOffset != null) {
      replacement = new InferredRegularMapLiteralEntry(
        extern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.spreadMapEntryTypeMismatch.withArguments(
              spreadType: offsets.iterableSpreadType!,
            ),
            fileUri: fileUri,
            fileOffset: offsets.iterableSpreadOffset!,
            length: 1,
          ),
        ),
        extern.createNullLiteral(fileOffset: TreeNode.noOffset),
        fileOffset: offsets.iterableSpreadOffset!,
      );
    }
    switch (entry) {
      case InferredSpreadMapEntry():
        DartType spreadType = entry.expressionType;
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
          entry.expression = expression;
        }
      case InferredIfMapEntry():
        InferredMapLiteralEntry then = _checkMapEntry(
          entry.then,
          keyType,
          valueType,
          offsets,
        );
        entry.then = then;
        if (entry.otherwise != null) {
          InferredMapLiteralEntry otherwise = _checkMapEntry(
            entry.otherwise!,
            keyType,
            valueType,
            offsets,
          );
          entry.otherwise = otherwise;
        }
      case InferredForMapEntry():
        InferredMapLiteralEntry body = _checkMapEntry(
          entry.body,
          keyType,
          valueType,
          offsets,
        );
        entry.body = body;
      case InferredPatternForMapEntry():
        InferredMapLiteralEntry body = _checkMapEntry(
          entry.body,
          keyType,
          valueType,
          offsets,
        );
        entry.body = body;
      case InferredForInMapEntry():
        InferredMapLiteralEntry body = _checkMapEntry(
          entry.body,
          keyType,
          valueType,
          offsets,
        );
        entry.body = body;
      case InferredIfCaseMapEntry():
        InferredMapLiteralEntry then = _checkMapEntry(
          entry.then,
          keyType,
          valueType,
          offsets,
        );
        entry.then = then;
        if (entry.otherwise != null) {
          InferredMapLiteralEntry otherwise = _checkMapEntry(
            entry.otherwise!,
            keyType,
            valueType,
            offsets,
          );
          entry.otherwise = otherwise;
        }
      case InferredNullAwareMapEntry():
      case InferredRegularMapLiteralEntry():
      // Do nothing.  Assignability checks are done during type inference.
    }
    return replacement;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitMapLiteral(
    MapLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalMapLiteral(
    InternalMapLiteral node,
    DartType typeContext,
  ) {
    Class mapClass = coreTypes.mapClass;
    InterfaceType mapType = coreTypes.thisInterfaceType(
      mapClass,
      Nullability.nonNullable,
    );
    List<DartType>? inferredTypes;
    DartType keyType;
    DartType valueType;

    assert((node.keyType == null) == (node.valueType == null));
    bool inferenceNeeded = node.keyType == null;
    bool typeContextIsMap = node.keyType != null;
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
        InternalSetLiteral setLiteral = new InternalSetLiteral(
          [],
          isConst: node.isConst,
          fileOffset: node.fileOffset,
        );
        return visitInternalSetLiteral(setLiteral, typeContext);
      }
    }

    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];
    List<DartType> actualTypesForSet = [];
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
      keyType = inferredTypes[0];
      valueType = inferredTypes[1];
    } else {
      keyType = node.keyType!;
      valueType = node.valueType!;
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
        <DartType>[keyType, valueType],
      );
    }
    List<InferredMapLiteralEntry> entries = new List.filled(
      node.entries.length,
      dummyMapLiteralEntryResult,
    );
    for (int index = 0; index < node.entries.length; ++index) {
      InferredMapLiteralEntry entry = inferMapEntry(
        node.entries[index],
        keyType,
        valueType,
        spreadTypeContext,
        actualTypes,
        actualTypesForSet,
        inferredConditionTypes,
        offsets,
      );
      entries[index] = entry;
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
        List<InferredElement> setElements = [];
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
        for (int i = 0; i < entries.length; ++i) {
          setElements.add(
            convertToElement(
              entries[i],
              (a, b) {} /*assignedVariables.reassignInfo*/,
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

        for (InferredElement element in setElements) {
          _checkElement(element: element, typeArgument: inferredTypeArgument);
        }

        Expression result = _translateSetLiteral(
          elements: setElements,
          typeArgument: inferredTypeArgument,
          isConst: node.isConst,
          fileOffset: node.fileOffset,
        );
        DartType inferredType = new InterfaceType(
          coreTypes.setClass,
          Nullability.nonNullable,
          inferredTypesForSet,
        );
        return new ExpressionInferenceResult(inferredType, result);
      }
      if (canBeSet && canBeMap && entries.isNotEmpty) {
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
      }
      if (!canBeSet && !canBeMap) {
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
      keyType = inferredTypes[0];
      valueType = inferredTypes[1];
    }
    for (int index = 0; index < entries.length; ++index) {
      InferredMapLiteralEntry entry = _checkMapEntry(
        entries[index],
        keyType,
        valueType,
        offsets,
      );
      entries[index] = entry;
    }
    DartType inferredType = new InterfaceType(
      mapClass,
      Nullability.nonNullable,
      [keyType, valueType],
    );
    SourceLibraryBuilder library = libraryBuilder;
    // Either both [_declaredKeyType] and [_declaredValueType] are omitted or
    // none of them, so we may just check one.
    if (inferenceNeeded) {
      if (!library.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(keyType, node.fileOffset);
        checkGenericFunctionTypeArgument(valueType, node.fileOffset);
      }
    }

    Expression result = _translateMapLiteral(
      entries: entries,
      keyType: keyType,
      valueType: valueType,
      isConst: node.isConst,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result);
    dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.externalToInternalNodeMap[result] =
        node;
    return new ExpressionInferenceResult(inferredType, result);
  }

  /// Convert [entry] to an [Expression], if possible. If [entry] cannot be
  /// converted an error reported through [helper] and an invalid expression is
  /// returned.
  ///
  /// [onConvertMapEntry] is called when a [ForMapEntry], [ForInMapEntry], or
  /// [IfMapEntry] is converted to a [ForElement], [ForInElement], or
  /// [IfElement], respectively.
  InferredElement convertToElement(
    InferredMapLiteralEntry entry,
    void Function(TreeNode from, TreeNode to) onConvertMapEntry, {
    DartType? actualType,
  }) {
    switch (entry) {
      case InferredSpreadMapEntry():
        return new InferredSpreadElement(
          expression: entry.expression,
          expressionType: entry.expressionType,
          isNullAware: entry.isNullAware,
          elementType: actualType,
          nodeForTesting: entry.nodeForTesting,
          fileOffset: entry.expression.fileOffset,
        );
      case InferredIfMapEntry():
        InferredIfElement result = new InferredIfElement(
          condition: entry.condition,
          then: convertToElement(entry.then, onConvertMapEntry),
          otherwise: entry.otherwise == null
              ? null
              :
                // Coverage-ignore(suite): Not run.
                convertToElement(entry.otherwise!, onConvertMapEntry),
          nodeForTesting: entry.nodeForTesting,
          fileOffset: entry.fileOffset,
        );
        onConvertMapEntry(entry, result);
        return result;
      case InferredNullAwareMapEntry():
        // Coverage-ignore(suite): Not run.
        return _convertToErroneousElement(
          entry.key,
          entry.value,
          fileOffset: entry.fileOffset,
        );
      case InferredIfCaseMapEntry():
        InferredIfCaseElement result = new InferredIfCaseElement(
          expression: entry.expression,
          patternGuard: entry.patternGuard,
          then: convertToElement(entry.then, onConvertMapEntry),
          otherwise: entry.otherwise == null
              ? null
              :
                // Coverage-ignore(suite): Not run.
                convertToElement(entry.otherwise!, onConvertMapEntry),
          matchedValueType: entry.matchedValueType,
          nodeForTesting: entry.nodeForTesting,
          fileOffset: entry.fileOffset,
        );
        onConvertMapEntry(entry, result);
        return result;
      case InferredPatternForMapEntry():
        InferredPatternForElement result = new InferredPatternForElement(
          patternVariableDeclaration: entry.patternVariableDeclaration,
          intermediateVariables: entry.intermediateVariables,
          variables: entry.variables,
          condition: entry.condition,
          updates: entry.updates,
          body: convertToElement(entry.body, onConvertMapEntry),
          nodeForTesting: entry.nodeForTesting,
          fileOffset: entry.fileOffset,
        );
        onConvertMapEntry(entry, result);
        return result;
      case InferredForMapEntry():
        InferredForElement result = new InferredForElement(
          variables: entry.variables,
          condition: entry.condition,
          updates: entry.updates,
          body: convertToElement(entry.body, onConvertMapEntry),
          nodeForTesting: entry.nodeForTesting,
          fileOffset: entry.fileOffset,
        );
        onConvertMapEntry(entry, result);
        return result;
      case InferredForInMapEntry():
        InferredForInElement result = new InferredForInElement(
          variable: entry.variable,
          iterable: entry.iterable,
          body: convertToElement(entry.body, onConvertMapEntry),
          isAsync: entry.isAsync,
          nodeForTesting: entry.nodeForTesting,
          fileOffset: entry.fileOffset,
          encoding: entry.encoding,
          scope: entry.scope,
        );
        onConvertMapEntry(entry, result);
        return result;
      case InferredRegularMapLiteralEntry():
        return _convertToErroneousElement(
          entry.key,
          entry.value,
          fileOffset: entry.fileOffset,
        );
    }
  }

  InferredElement _convertToErroneousElement(
    Expression key,
    Expression value, {
    required int fileOffset,
  }) {
    if (key is InvalidExpression) {
      if (value is NullLiteral && value.fileOffset == TreeNode.noOffset) {
        // entry arose from an error.  Don't build another error.
        return new InferredExpressionElement(
          expression: key,
          fileOffset: fileOffset,
        );
      }
    }
    // Coverage-ignore(suite): Not run.
    // TODO(johnniwinther): How can this be triggered? This will fail if
    // encountered in top level inference.
    return new InferredExpressionElement(
      expression: extern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.expectedButGot.withArguments(expected: ','),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: 1,
        ),
      ),
      fileOffset: fileOffset,
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
      isImplicitThis: node.isImplicitThis,
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitNot(Not node, DartType typeContext) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
    return new ExpressionInferenceResult(boolType, replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitNullCheck(
    NullCheck node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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
      intern.createIntLiteral(value: 1, fileOffset: node.operatorOffset),
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
        variable: valueVariable,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
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
      intern.createIntLiteral(value: 1, fileOffset: node.operatorOffset),
      null,
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
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        variable: valueVariable,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
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
      intern.createIntLiteral(value: 1, fileOffset: node.operatorOffset),
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
        variable: valueVariable,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
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
      isThisReceiver: _isThisExpression(node.receiver),
      isImplicitThis: node.isImplicitThis,
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
      intern.createIntLiteral(value: 1, fileOffset: node.fileOffset),
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
      isImplicitThis: node.isImplicitThis,
    );
    Expression write = writeResult.expression;

    Expression replacement;
    if (valueVariable == null) {
      replacement = write;
    } else {
      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        variable: valueVariable,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
        ),
      );
    }

    if (receiverVariable != null) {
      if (!node.isNullAware) {
        // When the node is null-aware, the receiver variable is used as a
        // null-aware guard and is automatically inserted by the shorting
        // system. Otherwise, we have to manually insert the receiver variable
        // here.
        replacement = createLet(variable: receiverVariable, body: replacement);
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
      isThisReceiver: _isThisExpression(node.receiver),
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
        replacement = createLet(variable: receiverVariable, body: replacement);
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
      isThisReceiver: _isThisExpression(node.receiver),
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
        extern.createNullLiteral(fileOffset: node.fileOffset),
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
      replacement = createLet(variable: readVariable, body: conditional);
    }
    if (!node.isNullAware) {
      // When the node is null-aware, the receiver variable is used as a
      // null-aware guard and is automatically inserted by the shorting system.
      // Otherwise, we have to manually insert the receiver variable here.
      replacement = createLet(variable: receiverVariable, body: replacement);
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
      Expression equalsNull = createEqualsNull(
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
    storeExpressionInfo(replacement, getExpressionInfo(writeResult.expression));

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  bool _isThisExpression(Expression expression) {
    return expression is ThisExpression ||
        expression is InternalThisExpression ||
        expression is VariableGet && expression.variable is ThisVariable;
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
          isThisReceiver: _isThisExpression(node.receiver),
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
      replacement = createLet(
        variable: assignmentVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        replacement = createLet(variable: valueVariable, body: replacement);
      }
      if (indexVariable != null) {
        replacement = createLet(variable: indexVariable, body: replacement);
      }
      if (receiverVariable != null) {
        replacement = createLet(variable: receiverVariable, body: replacement);
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
    Expression replacement = createLet(
      variable: assignmentVariable,
      body: returnedValue,
    );
    if (valueVariable != null) {
      replacement = createLet(variable: valueVariable, body: replacement);
    }
    if (indexVariable != null) {
      replacement = createLet(variable: indexVariable, body: replacement);
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
      replacement = createLet(
        variable: assignmentVariable,
        body: returnedValue,
      );
    }
    if (valueVariable != null) {
      replacement = createLet(variable: valueVariable, body: replacement);
    }
    if (receiverVariable != null) {
      replacement = createLet(variable: receiverVariable, body: replacement);
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
      isThisReceiver: _isThisExpression(node.receiver),
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
      getExpressionInfo(read),
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
      Expression result = createLet(
        variable: writeVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        result = createLet(variable: valueVariable, body: result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.testOffset,
        equalsNull,
        result,
        variableGet,
        inferredType,
      );
      inner = createLet(variable: readVariable, body: conditional);
    }
    if (indexVariable != null) {
      inner = createLet(variable: indexVariable, body: inner);
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
      getExpressionInfo(read),
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
      Expression result = createLet(
        variable: writeVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        result = createLet(variable: valueVariable, body: result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        result,
        readVariableGet,
        inferredType,
      );
      replacement = createLet(variable: readVariable, body: conditional);
    }
    if (indexVariable != null) {
      replacement = createLet(variable: indexVariable, body: replacement);
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
      getExpressionInfo(read),
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
      Expression result = createLet(
        variable: writeVariable,
        body: returnedValue!,
      );
      if (valueVariable != null) {
        result = createLet(variable: valueVariable, body: result);
      }
      ConditionalExpression conditional = _createConditionalExpression(
        node.fileOffset,
        equalsNull,
        result,
        readVariableGet,
        inferredType,
      );
      replacement = createLet(variable: readVariable, body: conditional);
    }
    if (indexVariable != null) {
      replacement = createLet(variable: indexVariable, body: replacement);
    }
    if (receiverVariable != null) {
      replacement = new Let(receiverVariable, replacement);
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
    Expression right, {
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
      storeExpressionInfo(
        equals,
        flowAnalysis.equalityOperation_end(
          equalityInfo,
          new SharedTypeView(leftType),
          getExpressionInfo(rightResult.expression),
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

    storeExpressionInfo(
      equals,
      flowAnalysis.equalityOperation_end(
        equalityInfo,
        new SharedTypeView(leftType),
        getExpressionInfo(right),
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
        InstanceInvocation instanceInvocation = binary = new InstanceInvocation(
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
        binary,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      return new ExpressionInferenceResult(
        binaryType,
        extern.createInvalidExpressionFromErrorText(
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
        unary,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      // TODO(johnniwinther): Special case 'unary-' in messages. It should
      // probably be referred to as "Unary operator '-' ...".
      return new ExpressionInferenceResult(
        unaryType,
        extern.createInvalidExpressionFromErrorText(
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
  PropertyGetInferenceResult _computePropertyGet(
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Name propertyName,
    DartType typeContext, {
    required bool isThisReceiver,
    ObjectAccessTarget? readTarget,
    PropertyGet? propertyGetNode,
    bool? isImplicitThis,
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
    if (propertyGetNode != null) {
      storeExpressionInfo(propertyGetNode, expressionInfo);
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
      isImplicitThis: isImplicitThis,
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
          isThisReceiver: _isThisExpression(node.receiver),
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
        variable: leftVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(leftVariable),
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      inner = createLet(
        variable: valueVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
        ),
      );
    }
    if (indexVariable != null) {
      inner = createLet(variable: indexVariable, body: inner);
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
        variable: leftVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(leftVariable),
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        variable: valueVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
        ),
      );
    }
    if (indexVariable != null) {
      replacement = createLet(variable: indexVariable, body: replacement);
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
        variable: leftVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(leftVariable),
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

      SyntheticVariable writeVariable = createVariable(write, const VoidType());
      replacement = createLet(
        variable: valueVariable!,
        body: createLet(
          variable: writeVariable,
          body: createVariableGet(valueVariable),
        ),
      );
    }
    if (indexVariable != null) {
      replacement = createLet(variable: indexVariable, body: replacement);
    }
    if (receiverVariable != null) {
      replacement = createLet(variable: receiverVariable, body: replacement);
    }
    replacement.fileOffset = node.fileOffset;
    return new ExpressionInferenceResult(
      node.forPostIncDec ? readType : binaryType,
      replacement,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitNullLiteral(
    NullLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitLet(Let node, DartType typeContext) {
    _unhandledExpression(node, typeContext);
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
    Expression body = bodyResult.expression..parent = node;
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
          receiver,
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
    InternalLabeledStatement internalLabel = new InternalLabeledStatement(
      null,
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
          receiver,
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
          new NullAwareGuard(tempVar!, node.variable.fileOffset, this),
          getExpressionInfo(tempVar.initializer!),
          new SharedTypeView(tempVar.type),
        );
      }
    }

    if (node.isParameterless) {
      flow.thisBinding_begin(getExpressionInfo(node.receiver));
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
    internalLabel.registerReplacement(label);

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
      isThisReceiver: _isThisExpression(node.receiver),
      propertyGetNode: node,
      isImplicitThis: node.isImplicitThis,
    );
    ExpressionInferenceResult readResult =
        propertyGetInferenceResult.expressionInferenceResult;
    ExpressionInferenceResult expressionInferenceResult =
        new ExpressionInferenceResult(
          readResult.inferredType,
          readResult.expression,
        );
    storeExpressionInfo(
      expressionInferenceResult.expression,
      getExpressionInfo(node),
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
      result = createInvalidInitializer2(
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
      result = createInvalidInitializer2(
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
    ).expression;
    Initializer replacement =
        new ExternalExtensionTypeRepresentationFieldInitializer(
          node.field,
          initializer,
          fileOffset: node.fileOffset,
        );
    return new SuccessfulInitializerInferenceResult(replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitRethrow(Rethrow node, DartType typeContext) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalRethrow(
    InternalRethrow node,
    DartType typeContext,
  ) {
    flowAnalysis.handleExit();
    Expression replacement = extern.createRethrow(fileOffset: node.fileOffset);
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, replacement);
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
    bodyContext.handleReturn(replacement, inferredType, node.isArrow);
    flowAnalysis.handleReturn();
    return new StatementInferenceResult.single(replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSetLiteral(
    SetLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalSetLiteral(
    InternalSetLiteral node,
    DartType typeContext,
  ) {
    Class setClass = coreTypes.setClass;
    InterfaceType setType = coreTypes.thisInterfaceType(
      setClass,
      Nullability.nonNullable,
    );
    List<DartType>? inferredTypes;
    DartType typeArgument;
    bool inferenceNeeded = node.typeArgument == null;
    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];
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
      typeArgument = inferredTypes[0];
    } else {
      typeArgument = node.typeArgument!;
    }
    List<InferredElement> elements = new List.filled(
      node.expressions.length,
      dummyInferredElement,
    );
    for (int index = 0; index < node.expressions.length; ++index) {
      ElementInferenceResult result = inferElement(
        node.expressions[index],
        typeArgument,
        inferredConditionTypes,
      );
      elements[index] = result.element;
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
      typeArgument = inferredTypes[0];
    }
    for (int i = 0; i < elements.length; i++) {
      InferredElement element = elements[i];
      _checkElement(element: element, typeArgument: typeArgument);
    }
    DartType inferredType = new InterfaceType(
      setClass,
      Nullability.nonNullable,
      [typeArgument],
    );
    if (inferenceNeeded) {
      if (!libraryBuilder.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(typeArgument, node.fileOffset);
      }
    }

    Expression result = _translateSetLiteral(
      elements: elements,
      typeArgument: typeArgument,
      isConst: node.isConst,
      fileOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result);
    dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.externalToInternalNodeMap[result] =
        node;
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
    DeclaredVariable setVar = extern.createVariable(
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitStaticSet(
    StaticSet node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result.expression);
    return result;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitStaticGet(
    StaticGet node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
  }

  ExpressionInferenceResult visitInternalStaticGet(
    InternalStaticGet node,
    DartType typeContext,
  ) {
    ExpressionInferenceResult result = inferStaticGet(
      member: node.target,
      typeContext: typeContext,
      nameOffset: node.fileOffset,
    );
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, result.expression);
    return result;
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
    storeExpressionInfo(replacement, result.expressionInfo);
    return new ExpressionInferenceResult(
      result.inferredType,
      result.applyResult(replacement),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitStringConcatenation(
    StringConcatenation node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitStringLiteral(
    StringLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
      result = createInvalidInitializer2(
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSuperPropertyGet(
    SuperPropertyGet node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSuperPropertySet(
    SuperPropertySet node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitSymbolLiteral(
    SymbolLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitThisExpression(
    ThisExpression node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, result);
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    return new StatementInferenceResult.single(result);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitTypeLiteral(
    TypeLiteral node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ).expression;
    flowAnalysis.whileStatement_bodyBegin(node, getExpressionInfo(condition));
    StatementInferenceResult bodyResult = inferStatement(node.body);
    Statement body = bodyResult.statement;

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
    ?.registerAlias(node, replacement);
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
    bodyContext.handleYield(replacement, expressionResult);
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerAlias(node, replacement);
    return new StatementInferenceResult.single(replacement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInferenceResult visitLoadLibrary(
    LoadLibrary node,
    DartType typeContext,
  ) {
    _unhandledExpression(node, typeContext);
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
    ?.registerAlias(node, replacement);
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
        flowAnalysis.whyNotPromoted(getExpressionInfo(leftResult.expression));
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
          Expression expression = field.value;
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
                  treeNodeForTesting: node,
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
                  treeNodeForTesting: node,
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
            if (needsHoisting && !isPureExpression(expression)) {
              // We hoist the value of the [NamedExpression] into a synthesized
              // variable, and replace the value with a read of the variable.
              SyntheticVariable variable = createVariable(expression, type);
              hoistedExpressions ??= [];
              hoistedExpressions.add(variable);
              namedExpression.value = createVariableGet(variable)
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
            if (needsHoisting && !isPureExpression(expression)) {
              // We hoist the positional element into a synthesized variable,
              // and replace the element in [positional] with a read of the
              // variable.
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
        result = createLet(variable: variable, body: result);
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
            treeNodeForTesting: node,
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
          InternalLabeledStatement switchLabel =
              node.parent as InternalLabeledStatement;
          BreakStatement syntheticBreak = extern.createBreakStatement(
            dummyLabeledStatement,
            fileOffset: TreeNode.noOffset,
          );
          switchLabel.addUser(syntheticBreak);
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
  FlowAnalysis<TreeNode, InternalStatement, Expression, InternalVariable>
  get flow => flowAnalysis;

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
  SwitchStatementMemberInfo<
    TreeNode,
    InternalStatement,
    Expression,
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
    InternalStatement node,
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
      ElementInferenceResult inferenceResult = inferElement(
        element,
        context.inferredTypeArgument,
        context.inferredConditionTypes,
      );
      // TODO(cstefantsova): Should the key to the map be [element] instead?
      context.inferredConditionTypes[element] = inferenceResult.inferredType;
      pushRewrite(inferenceResult.element);
    } else if (element is InternalMapLiteralEntry) {
      context as MapEntryInferenceContext;
      pushRewrite(
        inferMapEntry(
          element,
          context.inferredKeyType,
          context.inferredValueType,
          context.spreadContext,
          context.actualTypes,
          context.actualTypesForSet,
          context.inferredConditionTypes,
          context.offsets,
        ),
      );
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
        );
      case Procedure():
        if (member.isGetter) {
          expressionInferenceResult = inferStaticGet(
            member: member,
            typeContext: cachedContext,
            nameOffset: node.fileOffset,
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

    storeExpressionInfo(
      expressionInferenceResult.expression,
      getExpressionInfo(node),
    );
    return expressionInferenceResult;
  }

  @override
  bool isDotShorthand(Expression node) {
    return node is DotShorthand;
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
                _capturedVariablesForNode(internalVariable.astVariable),
              );
        }
        flowAnalysis.lateInitializer_begin(internalVariable.astVariable);
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
      ?.registerAlias(internalVariable, internalVariable.astVariable);
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
  Map<Expression, DartType> inferredConditionTypes;

  new({required this.inferredConditionTypes});
}

class ListAndSetElementInferenceContext
    extends CollectionElementInferenceContext {
  DartType inferredTypeArgument;

  new({
    required this.inferredTypeArgument,
    required Map<Expression, DartType> inferredConditionTypes,
  }) : super(inferredConditionTypes: inferredConditionTypes);
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
    required Map<Expression, DartType> inferredConditionTypes,
  }) : super(inferredConditionTypes: inferredConditionTypes);
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

class ForMapEntryBaseResult({
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final InferredMapLiteralEntry body,
  required final List<Expression> updates,
});

class ForElementBaseResult({
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final InferredElement body,
  required final List<Expression> updates,
  required final DartType inferredType,
});
