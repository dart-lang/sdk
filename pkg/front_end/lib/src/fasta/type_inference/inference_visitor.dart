// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jensj): Probably all `_createVariableGet(result)` needs their offset
// "nulled out".

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    hide MapPatternEntry;
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:_fe_analyzer_shared/src/util/null_value.dart';
import 'package:_fe_analyzer_shared/src/util/stack_checker.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../api_prototype/experimental_flags.dart';
import '../../base/instrumentation.dart'
    show
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;
import '../codes/fasta_codes.dart';
import '../kernel/body_builder.dart' show combineStatements;
import '../kernel/collections.dart'
    show
        ControlFlowElement,
        ControlFlowMapEntry,
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement,
        SpreadMapEntry,
        convertToElement;
import '../kernel/hierarchy/class_member.dart';
import '../kernel/implicit_type_argument.dart' show ImplicitTypeArgument;
import '../kernel/internal_ast.dart';
import '../kernel/late_lowering.dart' as late_lowering;
import '../problems.dart' as problems
    show internalProblem, unhandled, unsupported;
import '../source/constructor_declaration.dart';
import '../source/source_library_builder.dart';
import '../uri_offset.dart';
import 'closure_context.dart';
import 'external_ast_helper.dart';
import 'for_in.dart';
import 'inference_helper.dart';
import 'inference_results.dart';
import 'inference_visitor_base.dart';
import 'object_access_target.dart';
import 'shared_type_analyzer.dart';
import 'stack_values.dart';
import 'type_constraint_gatherer.dart';
import 'type_inference_engine.dart';
import 'type_inferrer.dart' show TypeInferrerImpl;
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
      Expression expression, DartType typeContext,
      {bool isVoidAllowed = false, bool forEffect = false});

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
    with
        TypeAnalyzer<TreeNode, Statement, Expression, VariableDeclaration,
            DartType, Pattern, InvalidExpression, DartType>,
        StackChecker
    implements
        ExpressionVisitor1<ExpressionInferenceResult, DartType>,
        StatementVisitor<StatementInferenceResult>,
        InitializerVisitor<InitializerInferenceResult>,
        PatternVisitor1<void, SharedMatchContext>,
        InferenceVisitor {
  /// Debug-only: if `true`, manipulations of [_rewriteStack] performed by
  /// [popRewrite] and [pushRewrite] will be printed.
  static const bool _debugRewriteStack = false;

  Class? mapEntryClass;

  @override
  final OperationsCfe operations;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  ClosureContext? _closureContext;

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
  final TypeAnalyzerOptions options;

  final ConstructorDeclaration? constructorDeclaration;

  @override
  late final SharedTypeAnalyzerErrors errors = new SharedTypeAnalyzerErrors(
      visitor: this,
      helper: helper,
      uri: uriForInstrumentation,
      coreTypes: coreTypes,
      isNonNullableByDefault: isNonNullableByDefault);

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

  InferenceVisitorImpl(TypeInferrerImpl inferrer, InferenceHelper helper,
      this.constructorDeclaration, this.operations)
      : options = new TypeAnalyzerOptions(
            nullSafetyEnabled: inferrer.libraryBuilder.isNonNullableByDefault,
            patternsEnabled:
                inferrer.libraryBuilder.libraryFeatures.patterns.isEnabled,
            inferenceUpdate3Enabled: inferrer
                .libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled),
        super(inferrer, helper);

  @override
  int get stackHeight => _rewriteStack.length;

  @override
  Object? lookupStack(int index) =>
      _rewriteStack[_rewriteStack.length - index - 1];

  /// Used to report an internal error encountered in the stack listener.
  @override
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
    return checkStackBaseStateForAssert(helper.uri, node?.fileOffset, base);
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
    return checkStackStateForAssert(helper.uri, node?.fileOffset, kinds,
        base: base);
  }

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
      Expression expression, DartType typeContext,
      {bool isVoidAllowed = false, bool forEffect = false}) {
    registerIfUnreachableForTesting(expression);

    ExpressionInferenceResult result;
    if (expression is ExpressionJudgment) {
      result = expression.acceptInference(this, typeContext);
    } else if (expression is InternalExpression) {
      result = expression.acceptInference(this, typeContext);
    } else {
      result = expression.accept1(this, typeContext);
    }
    DartType inferredType = result.inferredType;
    if (inferredType is VoidType && !isVoidAllowed) {
      if (expression.parent is! ArgumentsImpl) {
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
            createReachabilityError(
                expression.fileOffset, messageNeverValueError));
        flowAnalysis.forwardExpression(replacement, result.expression);
        result =
            new ExpressionInferenceResult(result.inferredType, replacement);
      }
    }
    return result;
  }

  @override
  ExpressionInferenceResult inferExpression(
      Expression expression, DartType typeContext,
      {bool isVoidAllowed = false, bool forEffect = false}) {
    ExpressionInferenceResult result = _inferExpression(expression, typeContext,
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
      Expression expression, DartType typeContext,
      {bool isVoidAllowed = false, bool forEffect = false}) {
    ExpressionInferenceResult result = _inferExpression(expression, typeContext,
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
        variable.initializer!, const UnknownType(),
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
        variable.initializer!, const UnknownType(),
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
  UriOffset _computeUriOffset(TreeNode node) {
    Uri uri = helper.uri;
    int fileOffset = node.fileOffset;
    return new UriOffset(uri, fileOffset);
  }

  ExpressionInferenceResult _unhandledExpression(
      Expression node, DartType typeContext) {
    UriOffset uriOffset = _computeUriOffset(node);
    problems.unhandled("$node (${node.runtimeType})", "InferenceVisitor",
        uriOffset.fileOffset, uriOffset.uri);
  }

  @override
  ExpressionInferenceResult visitBlockExpression(
      BlockExpression node, DartType typeContext) {
    // This is only used for error cases. The spec doesn't use this and
    // therefore doesn't specify the type context for the subterms.
    StatementInferenceResult bodyResult = inferStatement(node.body);
    if (bodyResult.hasChanged) {
      node.body = (bodyResult.statement as Block)..parent = node;
    }
    ExpressionInferenceResult valueResult =
        inferExpression(node.value, const UnknownType(), isVoidAllowed: true);
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
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitInstanceTearOff(
      InstanceTearOff node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitDynamicInvocation(
      DynamicInvocation node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitDynamicSet(
      DynamicSet node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitEqualsCall(
      EqualsCall node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitEqualsNull(
      EqualsNull node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitFunctionInvocation(
      FunctionInvocation node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitInstanceInvocation(
      InstanceInvocation node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitInstanceGetterInvocation(
      InstanceGetterInvocation node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitInstanceSet(
      InstanceSet node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitLocalFunctionInvocation(
      LocalFunctionInvocation node, DartType typeContext) {
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
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
    // This node is created as part of a lowering and doesn't need inference.
    return new ExpressionInferenceResult(
        node.getStaticType(staticTypeContext), node);
  }

  @override
  ExpressionInferenceResult visitFileUriExpression(
      FileUriExpression node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferExpression(node.expression, typeContext);
    node.expression = result.expression..parent = node;
    return new ExpressionInferenceResult(result.inferredType, node);
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
        node.expression, const UnknownType(),
        isVoidAllowed: true);
    node.expression = expressionResult.expression..parent = node;
    assert(
        expressionResult.inferredType is FunctionType,
        "Expected a FunctionType from tearing off a constructor from "
        "a typedef, but got '${expressionResult.inferredType.runtimeType}'.");
    FunctionType expressionType = expressionResult.inferredType as FunctionType;

    assert(expressionType.typeParameters.length == node.typeArguments.length);
    FunctionType resultType = FunctionTypeInstantiator.instantiate(
        expressionType, node.typeArguments);
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(node.typeParameters);
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
    UriOffset uriOffset = _computeUriOffset(node);
    return problems.unhandled("${node.runtimeType}", "InferenceVisitor",
        uriOffset.fileOffset, uriOffset.uri);
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
    problems.unhandled("${node.runtimeType}", "InferenceVisitor",
        node.fileOffset, node.location!.file);
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
      ExpressionInferenceResult result =
          inferExpression(node.expression!, typeContext, isVoidAllowed: true);
      node.expression = result.expression..parent = node;
    }
    return new ExpressionInferenceResult(const InvalidType(), node);
  }

  @override
  ExpressionInferenceResult visitInstantiation(
      Instantiation node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferExpression(
        node.expression, const UnknownType(),
        isVoidAllowed: true);
    Expression operand = operandResult.expression;
    DartType operandType = operandResult.inferredType;
    if (operandType is! FunctionType) {
      ObjectAccessTarget callMember = findInterfaceMember(
          operandType, callName, operand.fileOffset,
          isSetter: false, includeExtensionMethods: true);
      switch (callMember.kind) {
        case ObjectAccessTargetKind.instanceMember:
          Member? target = callMember.classMember;
          if (target is Procedure && target.kind == ProcedureKind.Method) {
            operandType = callMember.getGetterType(this);
            operand = new InstanceTearOff(
                InstanceAccessKind.Instance, operand, callName,
                interfaceTarget: target, resultType: operandType)
              ..fileOffset = operand.fileOffset;
          }
          break;
        case ObjectAccessTargetKind.extensionMember:
        case ObjectAccessTargetKind.extensionTypeMember:
          if (callMember.tearoffTarget != null &&
              callMember.declarationMethodKind == ClassMemberKind.Method) {
            operandType = callMember.getGetterType(this);
            operand = new StaticInvocation(
                callMember.tearoffTarget as Procedure,
                new Arguments(<Expression>[operand],
                    types: callMember.receiverTypeArguments)
                  ..fileOffset = operand.fileOffset)
              ..fileOffset = operand.fileOffset;
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
            operandType, node.typeArguments, node.fileOffset,
            inferred: false);
        if (operandType.isPotentiallyNullable) {
          result = helper.buildProblem(
              templateInstantiationNullableGenericFunctionType.withArguments(
                  operandType, isNonNullableByDefault),
              node.fileOffset,
              noLength);
        } else {
          resultType = FunctionTypeInstantiator.instantiate(
              operandType, node.typeArguments);
        }
      } else {
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
                  operandType.typeParameters.length, node.typeArguments.length),
              node.fileOffset,
              noLength);
        } else if (operandType.typeParameters.length <
            node.typeArguments.length) {
          result = helper.buildProblem(
              templateInstantiationTooManyArguments.withArguments(
                  operandType.typeParameters.length, node.typeArguments.length),
              node.fileOffset,
              noLength);
        }
      }
    } else if (operandType is! InvalidType) {
      result = helper.buildProblem(
          templateInstantiationNonGenericFunctionType.withArguments(
              operandType, isNonNullableByDefault),
          node.fileOffset,
          noLength);
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
    ExpressionInferenceResult operandResult =
        inferExpression(node.operand, const UnknownType(), isVoidAllowed: true);
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
    ExpressionInferenceResult conditionResult =
        inferExpression(node.condition, expectedType, isVoidAllowed: true);

    Expression condition =
        ensureAssignableResult(expectedType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.assert_afterCondition(node.condition);
    if (node.message != null) {
      ExpressionInferenceResult messageResult = inferExpression(
          node.message!, const UnknownType(),
          isVoidAllowed: true);
      node.message = messageResult.expression..parent = node;
    }
    flowAnalysis.assert_end();
    return const StatementInferenceResult();
  }

  bool _isIncompatibleWithAwait(DartType type) {
    if (isNullableTypeConstructorApplication(type)) {
      return _isIncompatibleWithAwait(computeTypeWithoutNullabilityMarker(
          (type),
          isNonNullableByDefault: isNonNullableByDefault));
    } else {
      switch (type) {
        case ExtensionType():
          return typeSchemaEnvironment.hierarchy
                  .getExtensionTypeAsInstanceOfClass(
                      type, coreTypes.futureClass,
                      isNonNullableByDefault:
                          libraryBuilder.isNonNullableByDefault) ==
              null;
        case TypeParameterType():
          return _isIncompatibleWithAwait(type.parameter.bound);
        case StructuralParameterType():
          return _isIncompatibleWithAwait(type.parameter.bound);
        case IntersectionType():
          return _isIncompatibleWithAwait(type.right);
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
      AwaitExpression node, DartType typeContext) {
    if (!typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = wrapFutureOrType(typeContext);
    }
    ExpressionInferenceResult operandResult = inferExpression(
        node.operand, typeContext,
        isVoidAllowed: !isNonNullableByDefault);
    DartType operandType = operandResult.inferredType;
    DartType flattenType = typeSchemaEnvironment.flatten(operandType);
    if (_isIncompatibleWithAwait(operandType)) {
      Expression wrapped = operandResult.expression;
      node.operand = helper.wrapInProblem(
          wrapped, messageAwaitOfExtensionTypeNotFuture, wrapped.fileOffset, 1);
      wrapped.parent = node.operand;
    } else {
      node.operand = operandResult.expression..parent = node;
    }
    DartType runtimeCheckType = new InterfaceType(
        coreTypes.futureClass, libraryBuilder.nonNullable, [flattenType]);
    if (!typeSchemaEnvironment.isSubtypeOf(
        operandType, runtimeCheckType, SubtypeCheckMode.withNullabilities)) {
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
      flowAnalysis.handleContinue(node.targetStatement);
    } else {
      flowAnalysis.handleBreak(node.targetStatement);
    }
    return const StatementInferenceResult();
  }

  ExpressionInferenceResult visitCascade(Cascade node, DartType typeContext) {
    ExpressionInferenceResult result = inferExpression(
        node.variable.initializer!, typeContext,
        isVoidAllowed: false);

    node.variable.initializer = result.expression..parent = node.variable;
    node.variable.type = result.inferredType;
    flowAnalysis.cascadeExpression_afterTarget(
        result.expression, result.inferredType,
        isNullAware: node.isNullAware);
    NullAwareGuard? nullAwareGuard;
    if (node.isNullAware) {
      nullAwareGuard = createNullAwareGuard(node.variable);
    }

    Cascade? previousEnclosingCascade = _enclosingCascade;
    _enclosingCascade = node;
    List<ExpressionInferenceResult> expressionResults =
        <ExpressionInferenceResult>[];
    for (Expression expression in node.expressions) {
      expressionResults.add(inferExpression(expression, const UnknownType(),
          isVoidAllowed: true, forEffect: true));
    }
    List<Statement> body = [];
    for (int index = 0; index < expressionResults.length; index++) {
      body.add(_createExpressionStatement(expressionResults[index].expression));
    }
    _enclosingCascade = previousEnclosingCascade;

    Expression replacement = _createBlockExpression(node.variable.fileOffset,
        _createBlock(body), createVariableGet(node.variable));

    if (node.isNullAware) {
      replacement =
          nullAwareGuard!.createExpression(result.inferredType, replacement);
    } else {
      replacement = new Let(node.variable, replacement)
        ..fileOffset = node.fileOffset;
    }
    flowAnalysis.cascadeExpression_end(replacement);
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  @override
  PropertyTarget<Expression> computePropertyTarget(Expression target) {
    if (_enclosingCascade case Cascade(:var variable)
        when target is VariableGet && target.variable == variable) {
      // `target` is an implicit reference to the target of a cascade
      // expression; flow analysis uses `CascadePropertyTarget` to represent
      // this situation.
      return CascadePropertyTarget.singleton;
    } else {
      // `target` is an ordinary expression.
      return new ExpressionPropertyTarget(target);
    }
  }

  Block _createBlock(List<Statement> statements) {
    return new Block(statements);
  }

  BlockExpression _createBlockExpression(
      int fileOffset, Block body, Expression value) {
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
      ConditionalExpression node, DartType typeContext) {
    flowAnalysis.conditional_conditionBegin();
    InterfaceType expectedType =
        coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult =
        inferExpression(node.condition, expectedType, isVoidAllowed: true);
    Expression condition =
        ensureAssignableResult(expectedType, conditionResult).expression;
    node.condition = condition..parent = node;
    flowAnalysis.conditional_thenBegin(node.condition, node);
    bool isThenReachable = flowAnalysis.isReachable;

    // A conditional expression `E` of the form `b ? e1 : e2` with context
    // type `K` is analyzed as follows:
    //
    // - Let `T1` be the type of `e1` inferred with context type `K`
    ExpressionInferenceResult thenResult =
        inferExpression(node.then, typeContext, isVoidAllowed: true);
    node.then = thenResult.expression..parent = node;
    registerIfUnreachableForTesting(node.then, isReachable: isThenReachable);
    DartType t1 = thenResult.inferredType;

    // - Let `T2` be the type of `e2` inferred with context type `K`
    flowAnalysis.conditional_elseBegin(node.then, thenResult.inferredType);
    bool isOtherwiseReachable = flowAnalysis.isReachable;
    ExpressionInferenceResult otherwiseResult =
        inferExpression(node.otherwise, typeContext, isVoidAllowed: true);
    node.otherwise = otherwiseResult.expression..parent = node;
    registerIfUnreachableForTesting(node.otherwise,
        isReachable: isOtherwiseReachable);
    DartType t2 = otherwiseResult.inferredType;

    // - Let `T` be  `UP(T1, T2)`
    DartType t = typeSchemaEnvironment.getStandardUpperBound(t1, t2,
        isNonNullableByDefault: isNonNullableByDefault);

    // - Let `S` be the greatest closure of `K`
    DartType s = computeGreatestClosure(typeContext);

    DartType inferredType;
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled) {
      inferredType = t;
    } else
    // - If `T <: S` then the type of `E` is `T`
    if (typeSchemaEnvironment.isSubtypeOf(
        t, s, SubtypeCheckMode.withNullabilities)) {
      inferredType = t;
    } else
    // - Otherwise, if `T1 <: S` and `T2 <: S`, then the type of `E` is `S`
    if (typeSchemaEnvironment.isSubtypeOf(
            t1, s, SubtypeCheckMode.withNullabilities) &&
        typeSchemaEnvironment.isSubtypeOf(
            t2, s, SubtypeCheckMode.withNullabilities)) {
      inferredType = s;
    } else
    // - Otherwise, the type of `E` is `T`
    {
      inferredType = t;
    }

    flowAnalysis.conditional_end(
        node, inferredType, node.otherwise, otherwiseResult.inferredType);
    node.staticType = inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  @override
  ExpressionInferenceResult visitConstructorInvocation(
      ConstructorInvocation node, DartType typeContext) {
    ensureMemberType(node.target);
    bool hadExplicitTypeArguments = hasExplicitTypeArguments(node.arguments);
    FunctionType functionType = node.target.function
        .computeThisFunctionType(libraryBuilder.nonNullable);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, functionType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    SourceLibraryBuilder library = libraryBuilder;
    if (!hadExplicitTypeArguments) {
      library.checkBoundsInConstructorInvocation(
          node, typeSchemaEnvironment, helper.uri,
          inferred: true);
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
    FunctionType calleeType =
        node.target.function.computeFunctionType(libraryBuilder.nonNullable);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        staticTarget: node.target);
    StaticInvocation replacement =
        new StaticInvocation(node.target, node.arguments);
    libraryBuilder.checkBoundsInStaticInvocation(
        replacement, typeSchemaEnvironment, helper.uri, typeArgumentsInfo);
    return instantiateTearOff(
        result.inferredType, typeContext, result.applyResult(replacement));
  }

  ExpressionInferenceResult visitExtensionSet(
      ExtensionSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferExpression(
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension, node.explicitTypeArguments, receiverResult.inferredType,
        treeNodeForTesting: node);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    ObjectAccessTarget target = new ExtensionAccessTarget(receiverType,
        node.target, null, ClassMemberKind.Setter, extensionTypeArguments);

    DartType valueType = target.getSetterType(this);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: false);
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
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension, node.explicitTypeArguments, receiverResult.inferredType,
        treeNodeForTesting: node);

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
        : new ExtensionAccessTarget(receiverType, node.getter!, null,
            ClassMemberKind.Getter, extensionTypeArguments);

    DartType readType = readTarget.getGetterType(this);

    Expression read;
    if (readTarget.isMissing) {
      read = createMissingPropertyGet(
          node.readOffset, readType, node.propertyName,
          receiver: readReceiver);
    } else {
      assert(readTarget.isExtensionMember);
      read = new StaticInvocation(
          readTarget.member as Procedure,
          new Arguments(<Expression>[
            readReceiver,
          ], types: readTarget.receiverTypeArguments)
            ..fileOffset = node.readOffset)
        ..fileOffset = node.readOffset;
    }

    ObjectAccessTarget writeTarget = node.setter == null
        ? const ObjectAccessTarget.missing()
        : new ExtensionAccessTarget(receiverType, node.setter!, null,
            ClassMemberKind.Setter, extensionTypeArguments);

    DartType valueType = writeTarget.getSetterType(this);

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
          ], types: writeTarget.receiverTypeArguments)
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
    ExpressionInferenceResult result =
        inferExpression(node.expression, typeContext, isVoidAllowed: true);

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
    ExpressionInferenceResult conditionResult =
        inferExpression(node.condition, boolType, isVoidAllowed: true);
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
        node.expression, const UnknownType(),
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
    SourceLibraryBuilder library = libraryBuilder;
    if (!hadExplicitTypeArguments) {
      library.checkBoundsInFactoryInvocation(
          node, typeSchemaEnvironment, helper.uri,
          inferred: true);
    }
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  /// Returns the function type of [constructor] when called through [typedef].
  FunctionType _computeAliasedConstructorFunctionType(
      Constructor constructor, Typedef typedef) {
    ensureMemberType(constructor);
    FunctionNode function = constructor.function;
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> classTypeParametersCopy =
        new List.of(constructor.enclosingClass.typeParameters);
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typedef.typeParameters);
    List<StructuralParameter> typedefTypeParametersCopy =
        freshTypeParameters.freshTypeParameters;
    List<DartType> asTypeArguments = freshTypeParameters.freshTypeArguments;
    TypedefType typedefType = new TypedefType(
        typedef, libraryBuilder.library.nonNullable, asTypeArguments);
    DartType unaliasedTypedef = typedefType.unalias;
    assert(unaliasedTypedef is InterfaceType,
        "[typedef] is assumed to resolve to an interface type");
    InterfaceType targetType = unaliasedTypedef as InterfaceType;
    Substitution substitution = Substitution.fromPairs(
        classTypeParametersCopy, targetType.typeArguments);
    List<DartType> positional = function.positionalParameters
        .map((VariableDeclaration decl) =>
            substitution.substituteType(decl.type))
        .toList(growable: false);
    List<NamedType> named = function.namedParameters
        .map((VariableDeclaration decl) => new NamedType(
            decl.name!, substitution.substituteType(decl.type),
            isRequired: decl.isRequired))
        .toList(growable: false);
    named.sort();
    return new FunctionType(
        positional, typedefType.unalias, libraryBuilder.library.nonNullable,
        namedParameters: named,
        typeParameters: typedefTypeParametersCopy,
        requiredParameterCount: function.requiredParameterCount);
  }

  ExpressionInferenceResult visitTypeAliasedConstructorInvocation(
      TypeAliasedConstructorInvocation node, DartType typeContext) {
    assert(getExplicitTypeArguments(node.arguments) == null);
    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType =
        _computeAliasedConstructorFunctionType(node.target, typedef);
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;

    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  /// Returns the function type of [factory] when called through [typedef].
  FunctionType _computeAliasedFactoryFunctionType(
      Procedure factory, Typedef typedef) {
    assert(factory.isFactory || factory.isExtensionTypeMember,
        "Only run this method on a factory: $factory");
    ensureMemberType(factory);
    FunctionNode function = factory.function;
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> classTypeParametersCopy =
        new List.of(function.typeParameters);
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typedef.typeParameters);
    List<StructuralParameter> typedefTypeParametersCopy =
        freshTypeParameters.freshTypeParameters;
    List<DartType> asTypeArguments = freshTypeParameters.freshTypeArguments;
    TypedefType typedefType = new TypedefType(
        typedef, libraryBuilder.library.nonNullable, asTypeArguments);
    DartType unaliasedTypedef = typedefType.unalias;
    assert(unaliasedTypedef is TypeDeclarationType,
        "[typedef] is assumed to resolve to a type declaration type");
    TypeDeclarationType targetType = unaliasedTypedef as TypeDeclarationType;
    Substitution substitution = Substitution.fromPairs(
        classTypeParametersCopy, targetType.typeArguments);
    List<DartType> positional = function.positionalParameters
        .map((VariableDeclaration decl) =>
            substitution.substituteType(decl.type))
        .toList(growable: false);
    List<NamedType> named = function.namedParameters
        .map((VariableDeclaration decl) => new NamedType(
            decl.name!, substitution.substituteType(decl.type),
            isRequired: decl.isRequired))
        .toList(growable: false);
    named.sort();
    return new FunctionType(
        positional, typedefType.unalias, libraryBuilder.library.nonNullable,
        namedParameters: named,
        typeParameters: typedefTypeParametersCopy,
        requiredParameterCount: function.requiredParameterCount);
  }

  ExpressionInferenceResult visitTypeAliasedFactoryInvocation(
      TypeAliasedFactoryInvocation node, DartType typeContext) {
    assert(getExplicitTypeArguments(node.arguments) == null);
    Typedef typedef = node.typeAliasBuilder.typedef;
    FunctionType calleeType =
        _computeAliasedFactoryFunctionType(node.target, typedef);
    calleeType = replaceReturnType(calleeType, calleeType.returnType.unalias);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        isConst: node.isConst, staticTarget: node.target);
    node.hasBeenInferred = true;
    Expression resultNode = node;
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(resultNode));
  }

  @override
  InitializerInferenceResult visitFieldInitializer(FieldInitializer node) {
    DartType fieldType = node.field.type;
    fieldType = constructorDeclaration!.substituteFieldType(fieldType);
    ExpressionInferenceResult initializerResult =
        inferExpression(node.value, fieldType);
    Expression initializer = ensureAssignableResult(
            fieldType, initializerResult,
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
      {bool isAsync = false}) {
    DartType elementType;
    bool isVariableTypeNeeded = false;
    if (variable is VariableDeclarationImpl && variable.isImplicitlyTyped) {
      isVariableTypeNeeded = true;
      elementType = const UnknownType();
    } else {
      elementType = variable.type;
    }

    ExpressionInferenceResult iterableResult =
        inferForInIterable(iterable, elementType, isAsync: isAsync);
    DartType inferredType = iterableResult.inferredType;
    if (isVariableTypeNeeded) {
      instrumentation?.record(uriForInstrumentation, variable.fileOffset,
          'type', new InstrumentationValueForType(inferredType));
      variable.type = inferredType;
    }

    // This is matched by the call to [forEach_end] in
    // [inferElement], [inferMapEntry] or [inferForInStatement].
    flowAnalysis.declare(variable, variable.type, initialized: true);
    flowAnalysis.forEach_bodyBegin(node);

    VariableDeclaration tempVariable = new VariableDeclaration(null,
        type: inferredType, isFinal: true, isSynthesized: true);
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
      Expression iterable, DartType elementType,
      {bool isAsync = false}) {
    Class iterableClass =
        isAsync ? coreTypes.streamClass : coreTypes.iterableClass;
    DartType context =
        wrapType(elementType, iterableClass, libraryBuilder.nonNullable);
    ExpressionInferenceResult iterableResult =
        inferExpression(iterable, context, isVoidAllowed: false);
    DartType iterableType = iterableResult.inferredType;
    iterable = iterableResult.expression;
    DartType inferredExpressionType = iterableType.nonTypeVariableBound;
    iterable = ensureAssignable(
        wrapType(
            const DynamicType(), iterableClass, libraryBuilder.nonNullable),
        inferredExpressionType,
        iterable,
        errorTemplate: templateForInLoopTypeNotIterable,
        nullabilityErrorTemplate: templateForInLoopTypeNotIterableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopTypeNotIterablePartNullability);
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
      UriOffset uriOffset = _computeUriOffset(syntheticAssignment!);
      return problems.unhandled(
          "${syntheticAssignment.runtimeType}",
          "handleForInStatementWithoutVariable",
          uriOffset.fileOffset,
          uriOffset.uri);
    }
  }

  ForInResult _handleForInWithoutVariable(
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Expression? syntheticAssignment,
      Statement? expressionEffects,
      {bool isAsync = false,
      required bool hasProblem}) {
    ForInVariable forInVariable =
        computeForInVariable(syntheticAssignment, hasProblem);
    DartType elementType = forInVariable.computeElementType(this);
    ExpressionInferenceResult iterableResult =
        inferForInIterable(iterable, elementType, isAsync: isAsync);
    DartType inferredType = iterableResult.inferredType;
    variable.type = inferredType;
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

  ForInResult _handlePatternForIn(
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Expression? syntheticAssignment,
      PatternVariableDeclaration patternVariableDeclaration,
      {bool isAsync = false,
      required bool hasProblem}) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternForInResult<DartType, InvalidExpression> result =
        analyzePatternForIn(
            node: node,
            hasAwait: isAsync,
            pattern: patternVariableDeclaration.pattern,
            expression: iterable,
            dispatchBody: () {});
    patternVariableDeclaration.matchedValueType = result.elementType;
    if (result.patternForInExpressionIsNotIterableError != null) {
      // The error is reported elsewhere.
    }

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
      /* initializer = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(rewrite, patternVariableDeclaration.pattern)) {
      patternVariableDeclaration.pattern = (rewrite as Pattern)
        ..parent = patternVariableDeclaration;
    }

    rewrite = popRewrite();
    if (!identical(rewrite, patternVariableDeclaration.initializer)) {
      iterable = (rewrite as Expression)..parent = node;
    }

    ForInVariable forInVariable =
        new PatternVariableDeclarationForInVariable(patternVariableDeclaration);

    variable.type = result.elementType;
    iterable = ensureAssignable(
        wrapType(
            const DynamicType(),
            isAsync ? coreTypes.streamClass : coreTypes.iterableClass,
            libraryBuilder.nonNullable),
        result.expressionType,
        iterable,
        errorTemplate: templateForInLoopTypeNotIterable,
        nullabilityErrorTemplate: templateForInLoopTypeNotIterableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopTypeNotIterablePartNullability);
    // This is matched by the call to [forEach_end] in
    // [inferElement], [inferMapEntry] or [inferForInStatement].
    flowAnalysis.forEach_bodyBegin(node);
    syntheticAssignment =
        forInVariable.inferAssignment(this, result.elementType);
    if (syntheticAssignment is VariableSet) {
      flowAnalysis.write(node, variable, result.elementType, null);
    }

    return new ForInResult(variable, /*iterableResult.expression*/ iterable,
        syntheticAssignment, patternVariableDeclaration);
  }

  ForInResult handleForInWithoutVariable(
      TreeNode node,
      VariableDeclaration variable,
      Expression iterable,
      Expression? syntheticAssignment,
      Statement? expressionEffects,
      {bool isAsync = false,
      required bool hasProblem}) {
    if (expressionEffects is PatternVariableDeclaration) {
      return _handlePatternForIn(
          node, variable, iterable, syntheticAssignment, expressionEffects,
          isAsync: isAsync, hasProblem: hasProblem);
    } else {
      return _handleForInWithoutVariable(
          node, variable, iterable, syntheticAssignment, expressionEffects,
          isAsync: isAsync, hasProblem: hasProblem);
    }
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
              variable.initializer!, const UnknownType(),
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
      ExpressionInferenceResult conditionResult =
          inferExpression(node.condition!, expectedType, isVoidAllowed: true);
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
          node.updates[index], const UnknownType(),
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
    bool oldInTryOrLocalFunction = _inTryOrLocalFunction;
    _inTryOrLocalFunction = true;
    VariableDeclaration variable = node.variable;
    flowAnalysis.functionExpression_begin(node);
    inferMetadata(this, variable, variable.annotations);
    DartType? returnContext =
        node.hasImplicitReturnType ? null : node.function.returnType;
    FunctionType inferredType =
        visitFunctionNode(node.function, null, returnContext, node.fileOffset);
    if (dataForTesting != null && node.hasImplicitReturnType) {
      dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
          inferredType.returnType;
    }
    variable.type = inferredType;
    flowAnalysis.declare(variable, variable.type, initialized: true);
    flowAnalysis.functionExpression_end();
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitFunctionExpression(
      FunctionExpression node, DartType typeContext) {
    bool oldInTryOrLocalFunction = _inTryOrLocalFunction;
    _inTryOrLocalFunction = true;
    flowAnalysis.functionExpression_begin(node);
    FunctionType inferredType =
        visitFunctionNode(node.function, typeContext, null, node.fileOffset);
    if (dataForTesting != null) {
      dataForTesting!.typeInferenceResult.inferredVariableTypes[node] =
          inferredType.returnType;
    }
    flowAnalysis.functionExpression_end();
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitIfNullExpression(
      IfNullExpression node, DartType typeContext) {
    // An if-null expression `E` of the form `e1 ?? e2` with context type `K` is
    // analyzed as follows:
    //
    // - Let `T1` be the type of `e1` inferred with context type `K?`.
    ExpressionInferenceResult lhsResult = inferExpression(
        node.left, computeNullable(typeContext),
        isVoidAllowed: false);
    DartType t1 = lhsResult.inferredType;

    // This ends any shorting in `node.left`.
    Expression left = lhsResult.expression;

    flowAnalysis.ifNullExpression_rightBegin(node.left, t1);

    // - Let `T2` be the type of `e2` inferred with context type `J`, where:
    //   - If `K` is `_`, `J = T1`.
    DartType j;
    if (typeContext is UnknownType) {
      j = t1;
    } else
    //   - Otherwise, `J = K`.
    {
      j = typeContext;
    }
    ExpressionInferenceResult rhsResult =
        inferExpression(node.right, j, isVoidAllowed: true);
    DartType t2 = rhsResult.inferredType;
    flowAnalysis.ifNullExpression_end();

    // - Let `T` be `UP(NonNull(T1), T2)`.
    DartType nonNullT1 = t1.toNonNull();
    DartType t = typeSchemaEnvironment.getStandardUpperBound(nonNullT1, t2,
        isNonNullableByDefault: isNonNullableByDefault);

    // - Let `S` be the greatest closure of `K`.
    DartType s = computeGreatestClosure(typeContext);

    DartType inferredType;
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled) {
      inferredType = t;
    } else
    // - If `T <: S`, then the type of `E` is `T`.
    if (typeSchemaEnvironment.isSubtypeOf(
        t, s, SubtypeCheckMode.withNullabilities)) {
      inferredType = t;
    } else
    // - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of `E` is
    //   `S`.
    if (typeSchemaEnvironment.isSubtypeOf(
            nonNullT1, s, SubtypeCheckMode.withNullabilities) &&
        typeSchemaEnvironment.isSubtypeOf(
            t2, s, SubtypeCheckMode.withNullabilities)) {
      inferredType = s;
    } else
    // - Otherwise, the type of `E` is `T`.
    {
      inferredType = t;
    }

    Expression replacement;
    if (left is ThisExpression) {
      replacement = left;
    } else {
      VariableDeclaration variable = createVariable(left, t1);
      Expression equalsNull = createEqualsNull(createVariableGet(variable),
          fileOffset: lhsResult.expression.fileOffset);
      VariableGet variableGet = createVariableGet(variable);
      if (isNonNullableByDefault && !identical(nonNullT1, t1)) {
        variableGet.promotedType = nonNullT1;
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
    ExpressionInferenceResult conditionResult =
        inferExpression(node.condition, expectedType, isVoidAllowed: true);
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

  @override
  StatementInferenceResult visitIfCaseStatement(IfCaseStatement node) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    IfCaseStatementResult<DartType, InvalidExpression> analysisResult =
        analyzeIfCaseStatement(node, node.expression, node.patternGuard.pattern,
            node.patternGuard.guard, node.then, node.otherwise, {
      for (VariableDeclaration variable
          in node.patternGuard.pattern.declaredVariables)
        variable.name!: variable
    });

    node.matchedValueType = analysisResult.matchedExpressionType;

    assert(checkStack(node, stackBase, [
      /* ifFalse = */ ValueKinds.StatementOrNull,
      /* ifTrue = */ ValueKinds.Statement,
      /* guard = */ ValueKinds.ExpressionOrNull,
      /* pattern = */ ValueKinds.Pattern,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite(NullValues.Statement);
    if (!identical(node.otherwise, rewrite)) {
      node.otherwise = (rewrite as Statement)..parent = node;
    }
    rewrite = popRewrite();
    if (!identical(node.then, rewrite)) {
      node.then = (rewrite as Statement)..parent = node;
    }
    rewrite = popRewrite(NullValues.Expression);
    InvalidExpression? guardError = analysisResult.nonBooleanGuardError;
    if (guardError != null) {
      node.patternGuard.guard = guardError..parent = node.patternGuard;
    } else {
      if (!identical(node.patternGuard.guard, rewrite)) {
        node.patternGuard.guard = (rewrite as Expression)
          ..parent = node.patternGuard;
      }
      if (analysisResult.guardType is DynamicType) {
        node.patternGuard.guard = _createImplicitAs(
            node.patternGuard.guard!.fileOffset,
            node.patternGuard.guard!,
            coreTypes.boolNonNullableRawType)
          ..parent = node.patternGuard;
      }
    }
    rewrite = popRewrite();
    if (!identical(node.patternGuard.pattern, rewrite)) {
      node.patternGuard.pattern = (rewrite as Pattern)
        ..parent = node.patternGuard;
    }
    rewrite = popRewrite();
    if (!identical(node.expression, rewrite)) {
      node.expression = (rewrite as Expression)..parent = node;
    }

    assert(checkStack(node, stackBase, [/*empty*/]));

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
        node.variable.initializer!, const UnknownType(),
        isVoidAllowed: false);
    node.variable.initializer = initializerResult.expression
      ..parent = node.variable;
    return const SuccessfulInitializerInferenceResult();
  }

  InitializerInferenceResult visitShadowInvalidFieldInitializer(
      ShadowInvalidFieldInitializer node) {
    ExpressionInferenceResult initializerResult =
        inferExpression(node.value, node.fieldType, isVoidAllowed: false);
    node.value = initializerResult.expression..parent = node;
    return const SuccessfulInitializerInferenceResult();
  }

  @override
  ExpressionInferenceResult visitIsExpression(
      IsExpression node, DartType typeContext) {
    ExpressionInferenceResult operandResult = inferExpression(
        node.operand, const UnknownType(),
        isVoidAllowed: false);
    node.operand = operandResult.expression..parent = node;
    flowAnalysis.isExpression_end(
        node, node.operand, /*isNot:*/ false, node.type);
    return new ExpressionInferenceResult(
        coreTypes.boolRawType(libraryBuilder.nonNullable), node);
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
      DartType spreadType, DartType spreadTypeBound, bool isNullAware) {
    if (coreTypes.isNull(spreadTypeBound)) {
      if (isNonNullableByDefault) {
        return isNullAware ? const NeverType.nonNullable() : null;
      } else {
        return isNullAware ? const NullType() : null;
      }
    }
    if (spreadTypeBound is TypeDeclarationType) {
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

  ExpressionInferenceResult _inferSpreadElement(
      SpreadElement element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    ExpressionInferenceResult spreadResult = inferExpression(
        element.expression,
        new InterfaceType(
            coreTypes.iterableClass,
            libraryBuilder.nullableIfTrue(element.isNullAware),
            <DartType>[inferredTypeArgument]),
        isVoidAllowed: true);
    element.expression = spreadResult.expression..parent = element;
    DartType spreadType = spreadResult.inferredType;
    inferredSpreadTypes[element.expression] = spreadType;
    Expression replacement = element;
    DartType spreadTypeBound = spreadType.nonTypeVariableBound;
    DartType? spreadElementType =
        getSpreadElementType(spreadType, spreadTypeBound, element.isNullAware);
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
                  templateSpreadElementTypeMismatchNullability.withArguments(
                      spreadElementType,
                      inferredTypeArgument,
                      isNonNullableByDefault),
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
              templateSpreadElementTypeMismatch.withArguments(spreadElementType,
                  inferredTypeArgument, isNonNullableByDefault),
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

    // Use 'dynamic' for error recovery.
    element.elementType = spreadElementType ?? const DynamicType();
    return new ExpressionInferenceResult(element.elementType!, replacement);
  }

  ExpressionInferenceResult _inferIfElement(
      IfElement element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    flowAnalysis.ifStatement_conditionBegin();
    DartType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult =
        inferExpression(element.condition, boolType, isVoidAllowed: false);
    Expression condition =
        ensureAssignableResult(boolType, conditionResult).expression;
    element.condition = condition..parent = element;
    flowAnalysis.ifStatement_thenBegin(condition, element);
    ExpressionInferenceResult thenResult = inferElement(element.then,
        inferredTypeArgument, inferredSpreadTypes, inferredConditionTypes);
    element.then = thenResult.expression..parent = element;
    ExpressionInferenceResult? otherwiseResult;
    if (element.otherwise != null) {
      flowAnalysis.ifStatement_elseBegin();
      otherwiseResult = inferElement(element.otherwise!, inferredTypeArgument,
          inferredSpreadTypes, inferredConditionTypes);
      element.otherwise = otherwiseResult.expression..parent = element;
    }
    flowAnalysis.ifStatement_end(element.otherwise != null);
    return new ExpressionInferenceResult(
        otherwiseResult == null
            ? thenResult.inferredType
            : typeSchemaEnvironment.getStandardUpperBound(
                thenResult.inferredType, otherwiseResult.inferredType,
                isNonNullableByDefault: isNonNullableByDefault),
        element);
  }

  ExpressionInferenceResult _inferIfCaseElement(
      IfCaseElement element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    int? stackBase;
    assert(checkStackBase(element, stackBase = stackHeight));

    ListAndSetElementInferenceContext context =
        new ListAndSetElementInferenceContext(
            inferredTypeArgument: inferredTypeArgument,
            inferredSpreadTypes: inferredSpreadTypes,
            inferredConditionTypes: inferredConditionTypes);
    IfCaseStatementResult<DartType, InvalidExpression> analysisResult =
        analyzeIfCaseElement(
            node: element,
            expression: element.expression,
            pattern: element.patternGuard.pattern,
            variables: {
              for (VariableDeclaration variable
                  in element.patternGuard.pattern.declaredVariables)
                variable.name!: variable
            },
            guard: element.patternGuard.guard,
            ifTrue: element.then,
            ifFalse: element.otherwise,
            context: context);

    element.matchedValueType = analysisResult.matchedExpressionType;

    assert(checkStack(element, stackBase, [
      /* ifFalse = */ ValueKinds.ExpressionOrNull,
      /* ifTrue = */ ValueKinds.Expression,
      /* guard = */ ValueKinds.ExpressionOrNull,
      /* pattern = */ ValueKinds.Pattern,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite(NullValues.Expression);
    if (!identical(element.otherwise, rewrite)) {
      element.otherwise = (rewrite as Expression?)?..parent = element;
    }

    rewrite = popRewrite();
    if (!identical(element.then, rewrite)) {
      element.then = (rewrite as Expression)..parent = element;
    }

    PatternGuard patternGuard = element.patternGuard;
    rewrite = popRewrite(NullValues.Expression);
    InvalidExpression? guardError = analysisResult.nonBooleanGuardError;
    if (guardError != null) {
      patternGuard.guard = guardError..parent = patternGuard;
    } else {
      if (!identical(patternGuard.guard, rewrite)) {
        patternGuard.guard = (rewrite as Expression?)?..parent = patternGuard;
      }
      if (analysisResult.guardType is DynamicType) {
        patternGuard.guard = _createImplicitAs(patternGuard.guard!.fileOffset,
            patternGuard.guard!, coreTypes.boolNonNullableRawType)
          ..parent = patternGuard;
      }
    }

    rewrite = popRewrite();
    if (!identical(patternGuard.pattern, rewrite)) {
      patternGuard.pattern = (rewrite as Pattern)..parent = patternGuard;
    }

    rewrite = popRewrite();
    if (!identical(element.expression, rewrite)) {
      element.expression = (rewrite as Expression)..parent = patternGuard;
    }

    DartType thenType = context.inferredConditionTypes[element.then]!;
    DartType? otherwiseType = element.otherwise == null
        ? null
        : context.inferredConditionTypes[element.otherwise!]!;
    return new ExpressionInferenceResult(
        otherwiseType == null
            ? thenType
            : typeSchemaEnvironment.getStandardUpperBound(
                thenType, otherwiseType,
                isNonNullableByDefault: isNonNullableByDefault),
        element);
  }

  ExpressionInferenceResult _inferForElement(
      ForElement element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    if (element is PatternForElement) {
      int? stackBase;
      assert(checkStackBase(element, stackBase = stackHeight));

      PatternVariableDeclaration patternVariableDeclaration =
          element.patternVariableDeclaration;
      PatternVariableDeclarationAnalysisResult<DartType, DartType>
          analysisResult = analyzePatternVariableDeclaration(
              patternVariableDeclaration,
              patternVariableDeclaration.pattern,
              patternVariableDeclaration.initializer,
              isFinal: patternVariableDeclaration.isFinal);
      patternVariableDeclaration.matchedValueType =
          analysisResult.initializerType;

      assert(checkStack(element, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]));

      Object? rewrite = popRewrite(NullValues.Expression);
      if (!identical(patternVariableDeclaration.pattern, rewrite)) {
        patternVariableDeclaration.pattern = (rewrite as Pattern)
          ..parent = patternVariableDeclaration;
      }

      rewrite = popRewrite();
      if (!identical(patternVariableDeclaration.initializer, rewrite)) {
        patternVariableDeclaration.initializer = (rewrite as Expression)
          ..parent = patternVariableDeclaration;
      }

      List<VariableDeclaration> declaredVariables =
          patternVariableDeclaration.pattern.declaredVariables;
      assert(declaredVariables.length == element.intermediateVariables.length);
      assert(declaredVariables.length == element.variables.length);
      for (int i = 0; i < declaredVariables.length; i++) {
        DartType type = declaredVariables[i].type;
        element.intermediateVariables[i].type = type;
        element.variables[i].type = type;
      }
    }
    // TODO(johnniwinther): Use _visitStatements instead.
    List<VariableDeclaration>? variables;
    for (int index = 0; index < element.variables.length; index++) {
      VariableDeclaration variable = element.variables[index];
      if (variable.name == null) {
        if (variable.initializer != null) {
          ExpressionInferenceResult initializerResult = inferExpression(
              variable.initializer!, variable.type,
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
          element.condition!, coreTypes.boolRawType(libraryBuilder.nonNullable),
          isVoidAllowed: false);
      element.condition = conditionResult.expression..parent = element;
      inferredConditionTypes[element.condition!] = conditionResult.inferredType;
    }
    flowAnalysis.for_bodyBegin(null, element.condition);
    ExpressionInferenceResult bodyResult = inferElement(element.body,
        inferredTypeArgument, inferredSpreadTypes, inferredConditionTypes);
    element.body = bodyResult.expression..parent = element;
    flowAnalysis.for_updaterBegin();
    for (int index = 0; index < element.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
          element.updates[index], const UnknownType(),
          isVoidAllowed: true);
      element.updates[index] = updateResult.expression..parent = element;
    }
    flowAnalysis.for_end();
    return new ExpressionInferenceResult(bodyResult.inferredType, element);
  }

  ExpressionInferenceResult _inferForInElement(
      ForInElement element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
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
      ExpressionInferenceResult problemResult = inferExpression(
          element.problem!, const UnknownType(),
          isVoidAllowed: true);
      element.problem = problemResult.expression..parent = element;
    }
    ExpressionInferenceResult bodyResult = inferElement(element.body,
        inferredTypeArgument, inferredSpreadTypes, inferredConditionTypes);
    element.body = bodyResult.expression..parent = element;
    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();
    return new ExpressionInferenceResult(bodyResult.inferredType, element);
  }

  ExpressionInferenceResult inferElement(
      Expression element,
      DartType inferredTypeArgument,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes) {
    if (element is SpreadElement) {
      return _inferSpreadElement(element, inferredTypeArgument,
          inferredSpreadTypes, inferredConditionTypes);
    } else if (element is IfElement) {
      return _inferIfElement(element, inferredTypeArgument, inferredSpreadTypes,
          inferredConditionTypes);
    } else if (element is IfCaseElement) {
      return _inferIfCaseElement(element, inferredTypeArgument,
          inferredSpreadTypes, inferredConditionTypes);
    } else if (element is ForElement) {
      return _inferForElement(element, inferredTypeArgument,
          inferredSpreadTypes, inferredConditionTypes);
    } else if (element is ForInElement) {
      return _inferForInElement(element, inferredTypeArgument,
          inferredSpreadTypes, inferredConditionTypes);
    } else {
      ExpressionInferenceResult result =
          inferExpression(element, inferredTypeArgument, isVoidAllowed: true);
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
            listClass.typeParameters);
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    listType = freshTypeParameters.substitute(listType) as InterfaceType;
    if (inferenceNeeded) {
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
          listType, typeParametersToInfer, typeContext,
          isNonNullableByDefault: isNonNullableByDefault,
          isConst: node.isConst,
          typeOperations: operations,
          inferenceResultForTesting: dataForTesting?.typeInferenceResult,
          treeNodeForTesting: node);
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
          gatherer, typeParametersToInfer, null,
          isNonNullableByDefault: isNonNullableByDefault);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    for (int index = 0; index < node.expressions.length; ++index) {
      ExpressionInferenceResult result = inferElement(node.expressions[index],
          inferredTypeArgument, inferredSpreadTypes, inferredConditionTypes);
      node.expressions[index] = result.expression..parent = node;
      actualTypes.add(result.inferredType);
      if (inferenceNeeded) {
        formalTypes.add(listType.typeArguments[0]);
      }
    }
    if (inferenceNeeded) {
      gatherer!.constrainArguments(formalTypes, actualTypes,
          treeNodeForTesting: node);
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
          gatherer, typeParametersToInfer, inferredTypes!,
          isNonNullableByDefault: isNonNullableByDefault);
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
    for (int i = 0; i < node.expressions.length; i++) {
      checkElement(node.expressions[i], node, node.typeArgument,
          inferredSpreadTypes, inferredConditionTypes);
    }
    DartType inferredType = new InterfaceType(
        listClass, libraryBuilder.nonNullable, [inferredTypeArgument]);
    if (inferenceNeeded) {
      if (!libraryBuilder.libraryFeatures.genericMetadata.isEnabled) {
        checkGenericFunctionTypeArgument(node.typeArgument, node.fileOffset);
      }
    }

    Expression result = _translateListLiteral(node);
    return new ExpressionInferenceResult(inferredType, result);
  }

  @override
  ExpressionInferenceResult visitRecordLiteral(
      RecordLiteral node, DartType typeContext) {
    // TODO(cstefantsova): Implement this method.
    return new ExpressionInferenceResult(node.recordType, node);
  }

  @override
  ExpressionInferenceResult visitLogicalExpression(
      LogicalExpression node, DartType typeContext) {
    InterfaceType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    flowAnalysis.logicalBinaryOp_begin();
    ExpressionInferenceResult leftResult =
        inferExpression(node.left, boolType, isVoidAllowed: false);
    Expression left = ensureAssignableResult(boolType, leftResult).expression;
    node.left = left..parent = node;
    flowAnalysis.logicalBinaryOp_rightBegin(node.left, node,
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND);
    ExpressionInferenceResult rightResult =
        inferExpression(node.right, boolType, isVoidAllowed: false);
    Expression right = ensureAssignableResult(boolType, rightResult).expression;
    node.right = right..parent = node;
    flowAnalysis.logicalBinaryOp_end(node, node.right,
        isAnd: node.operatorEnum == LogicalExpressionOperator.AND);
    return new ExpressionInferenceResult(boolType, node);
  }

  Expression _translateNonConstListOrSet(
      Expression node, DartType elementType, List<Expression> elements,
      {bool isSet = false}) {
    assert((node is ListLiteral && !node.isConst) ||
        (node is SetLiteral && !node.isConst));

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
        ? typeSchemaEnvironment.setType(elementType, libraryBuilder.nonNullable)
        : typeSchemaEnvironment.listType(
            elementType, libraryBuilder.nonNullable);
    VariableDeclaration? result;
    if (index == 0 && elements[index] is SpreadElement) {
      SpreadElement initialSpread = elements[index] as SpreadElement;
      final bool typeMatches = initialSpread.elementType != null &&
          typeSchemaEnvironment.isSubtypeOf(initialSpread.elementType!,
              elementType, SubtypeCheckMode.withNullabilities);
      if (typeMatches && !initialSpread.isNullAware) {
        // Create a list or set of the initial spread element.
        Expression value = initialSpread.expression;
        index++;
        if (isSet) {
          result = _createVariable(
              new StaticInvocation(
                  engine.setOf,
                  new Arguments([value], types: [elementType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
        } else {
          result = _createVariable(
              new StaticInvocation(
                  engine.listOf,
                  new Arguments([value], types: [elementType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
        }
      }
    }
    List<Statement>? body;
    if (result == null) {
      // Create a list or set with the elements up to the first non-expression.
      if (isSet) {
        if (libraryBuilder.loader.target.backendTarget.supportsSetLiterals) {
          // Include the elements up to the first non-expression in the set
          // literal.
          result = _createVariable(
              _lowerSetLiteral(_createSetLiteral(
                  node.fileOffset, elementType, elements.sublist(0, index))),
              receiverType);
        } else {
          // TODO(johnniwinther): When all the back ends handle set literals we
          //  can use remove this branch.

          // Create an empty set using the [setFactory] constructor.
          result = _createVariable(
              new StaticInvocation(
                  engine.setFactory,
                  new Arguments([], types: [elementType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
          body = [result];
          // Add the elements up to the first non-expression.
          for (int j = 0; j < index; ++j) {
            _addExpressionElement(elements[j], receiverType, result, body,
                isSet: isSet);
          }
        }
      } else {
        // Include the elements up to the first non-expression in the list
        // literal.
        result = _createVariable(
            _createListLiteral(
                node.fileOffset, elementType, elements.sublist(0, index)),
            receiverType);
      }
    }
    body ??= [result];
    // Translate the elements starting with the first non-expression.
    for (; index < elements.length; ++index) {
      _translateElement(
          elements[index], receiverType, elementType, result, body,
          isSet: isSet);
    }

    return _createBlockExpression(
        node.fileOffset, _createBlock(body), _createVariableGet(result));
  }

  void _translateElement(Expression element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    if (element is SpreadElement) {
      _translateSpreadElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else if (element is IfElement) {
      _translateIfElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else if (element is IfCaseElement) {
      _translateIfCaseElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else if (element is ForElement) {
      if (element is PatternForElement) {
        _translatePatternForElement(
            element, receiverType, elementType, result, body,
            isSet: isSet);
      } else {
        _translateForElement(element, receiverType, elementType, result, body,
            isSet: isSet);
      }
    } else if (element is ForInElement) {
      _translateForInElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else {
      _addExpressionElement(element, receiverType, result, body, isSet: isSet);
    }
  }

  void _addExpressionElement(Expression element, InterfaceType receiverType,
      VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    body.add(_createExpressionStatement(_createAdd(
        // Don't make a mess of jumping around (and make scope building
        // impossible).
        _createVariableGet(result)..fileOffset = TreeNode.noOffset,
        receiverType,
        element,
        isSet: isSet)));
  }

  void _translateIfElement(IfElement element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    List<Statement> thenStatements = [];
    _translateElement(
        element.then, receiverType, elementType, result, thenStatements,
        isSet: isSet);
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(element.otherwise!, receiverType, elementType, result,
          elseStatements = <Statement>[],
          isSet: isSet);
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        : _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          : _createBlock(elseStatements);
    }
    IfStatement ifStatement =
        _createIf(element.fileOffset, element.condition, thenBody, elseBody);
    libraryBuilder.loader.dataForTesting?.registerAlias(element, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfCaseElement(
      IfCaseElement element,
      InterfaceType receiverType,
      DartType elementType,
      VariableDeclaration result,
      List<Statement> body,
      {required bool isSet}) {
    List<Statement> thenStatements = [];
    _translateElement(
        element.then, receiverType, elementType, result, thenStatements,
        isSet: isSet);
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(element.otherwise!, receiverType, elementType, result,
          elseStatements = <Statement>[],
          isSet: isSet);
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        : _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          : _createBlock(elseStatements);
    }
    IfCaseStatement ifCaseStatement = _createIfCase(
        element.fileOffset,
        element.expression,
        element.matchedValueType!,
        element.patternGuard,
        thenBody,
        elseBody);
    libraryBuilder.loader.dataForTesting
        ?.registerAlias(element, ifCaseStatement);
    body.addAll(element.prelude);
    body.add(ifCaseStatement);
  }

  void _translateForElement(ForElement element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    List<Statement> statements = <Statement>[];
    _translateElement(
        element.body, receiverType, elementType, result, statements,
        isSet: isSet);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    ForStatement loop = _createForStatement(element.fileOffset,
        element.variables, element.condition, element.updates, loopBody);
    libraryBuilder.loader.dataForTesting?.registerAlias(element, loop);
    body.add(loop);
  }

  void _translatePatternForElement(
      PatternForElement element,
      InterfaceType receiverType,
      DartType elementType,
      VariableDeclaration result,
      List<Statement> body,
      {required bool isSet}) {
    List<Statement> statements = <Statement>[];
    _translateElement(
        element.body, receiverType, elementType, result, statements,
        isSet: isSet);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    ForStatement loop = _createForStatement(element.fileOffset,
        element.variables, element.condition, element.updates, loopBody);
    libraryBuilder.loader.dataForTesting?.registerAlias(element, loop);
    body.add(element.patternVariableDeclaration);
    body.addAll(element.intermediateVariables);
    body.add(loop);
  }

  void _translateForInElement(ForInElement element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    List<Statement> statements;
    Statement? prologue = element.prologue;
    if (prologue == null) {
      statements = <Statement>[];
    } else {
      statements =
          prologue is Block ? prologue.statements : <Statement>[prologue];
    }
    _translateElement(
        element.body, receiverType, elementType, result, statements,
        isSet: isSet);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    if (element.problem != null) {
      body.add(_createExpressionStatement(element.problem!));
    }
    ForInStatement loop = _createForInStatement(
        element.fileOffset, element.variable, element.iterable, loopBody,
        isAsync: element.isAsync);
    libraryBuilder.loader.dataForTesting?.registerAlias(element, loop);
    body.add(loop);
  }

  void _translateSpreadElement(
      SpreadElement element,
      InterfaceType receiverType,
      DartType elementType,
      VariableDeclaration result,
      List<Statement> body,
      {required bool isSet}) {
    Expression value = element.expression;

    final bool typeMatches = element.elementType != null &&
        typeSchemaEnvironment.isSubtypeOf(element.elementType!, elementType,
            SubtypeCheckMode.withNullabilities);
    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to 'add'.

      // Null-aware spreads require testing the subexpression's value.
      VariableDeclaration? temp;
      if (element.isNullAware) {
        temp = _createVariable(
            value,
            typeSchemaEnvironment.iterableType(
                elementType, libraryBuilder.nullable));
        body.add(temp);
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(_createAddAll(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          value,
          isSet));

      if (element.isNullAware) {
        statement = _createIf(
            temp!.fileOffset,
            _createEqualsNull(_createVariableGet(temp), notEquals: true),
            statement);
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      VariableDeclaration? temp;
      if (element.isNullAware) {
        temp = _createVariable(
            value,
            typeSchemaEnvironment.iterableType(
                const DynamicType(), libraryBuilder.nullable));
        body.add(temp);
        value = _createNullCheckedVariableGet(temp);
      }

      VariableDeclaration variable =
          _createForInVariable(element.fileOffset, const DynamicType());
      VariableDeclaration castedVar = _createVariable(
          _createImplicitAs(element.expression.fileOffset,
              _createVariableGet(variable), elementType),
          elementType);
      Statement loopBody = _createBlock(<Statement>[
        castedVar,
        _createExpressionStatement(_createAdd(
            // Don't make a mess of jumping around (and make scope building
            // impossible).
            _createVariableGet(result)..fileOffset = TreeNode.noOffset,
            receiverType,
            _createVariableGet(castedVar),
            isSet: isSet))
      ]);
      Statement statement =
          _createForInStatement(element.fileOffset, variable, value, loopBody);

      if (element.isNullAware) {
        statement = _createIf(
            temp!.fileOffset,
            _createEqualsNull(_createVariableGet(temp), notEquals: true),
            statement);
      }
      body.add(statement);
    }
  }

  Expression _translateListLiteral(ListLiteral node) {
    if (node.isConst) {
      return _translateConstListOrSet(node, node.typeArgument, node.expressions,
          isSet: false);
    } else {
      return _translateNonConstListOrSet(
          node, node.typeArgument, node.expressions,
          isSet: false);
    }
  }

  Expression _translateSetLiteral(SetLiteral node) {
    if (node.isConst) {
      return _translateConstListOrSet(node, node.typeArgument, node.expressions,
          isSet: true);
    } else {
      return _translateNonConstListOrSet(
          node, node.typeArgument, node.expressions,
          isSet: true);
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
        node.keyType, node.valueType, libraryBuilder.nonNullable);
    VariableDeclaration? result;

    if (index == 0 && node.entries[index] is SpreadMapEntry) {
      SpreadMapEntry initialSpread = node.entries[index] as SpreadMapEntry;
      final InterfaceType entryType = new InterfaceType(engine.mapEntryClass,
          libraryBuilder.nonNullable, <DartType>[node.keyType, node.valueType]);
      final bool typeMatches = initialSpread.entryType != null &&
          typeSchemaEnvironment.isSubtypeOf(initialSpread.entryType!, entryType,
              SubtypeCheckMode.withNullabilities);
      if (typeMatches && !initialSpread.isNullAware) {
        {
          // Create a map of the initial spread element.
          Expression value = initialSpread.expression;
          index++;
          result = _createVariable(
              new StaticInvocation(
                  engine.mapOf,
                  new Arguments([value], types: [node.keyType, node.valueType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
        }
      }
    }

    List<Statement>? body;
    if (result == null) {
      result = _createVariable(
          _createMapLiteral(node.fileOffset, node.keyType, node.valueType, []),
          receiverType);
      body = [result];
      // Add all the entries up to the first control-flow entry.
      for (int j = 0; j < index; ++j) {
        _addNormalEntry(node.entries[j], receiverType, result, body);
      }
    }

    body ??= [result];

    // Translate the elements starting with the first non-expression.
    for (; index < node.entries.length; ++index) {
      _translateEntry(node.entries[index], receiverType, node.keyType,
          node.valueType, result, body);
    }

    return _createBlockExpression(
        node.fileOffset, _createBlock(body), _createVariableGet(result));
  }

  void _translateEntry(
      MapLiteralEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    if (entry is SpreadMapEntry) {
      _translateSpreadEntry(
          entry, receiverType, keyType, valueType, result, body);
    } else if (entry is IfMapEntry) {
      _translateIfEntry(entry, receiverType, keyType, valueType, result, body);
    } else if (entry is IfCaseMapEntry) {
      _translateIfCaseEntry(
          entry, receiverType, keyType, valueType, result, body);
    } else if (entry is ForMapEntry) {
      if (entry is PatternForMapEntry) {
        _translatePatternForEntry(
            entry, receiverType, keyType, valueType, result, body);
      } else {
        _translateForEntry(
            entry, receiverType, keyType, valueType, result, body);
      }
    } else if (entry is ForInMapEntry) {
      _translateForInEntry(
          entry, receiverType, keyType, valueType, result, body);
    } else {
      _addNormalEntry(entry, receiverType, result, body);
    }
  }

  void _addNormalEntry(MapLiteralEntry entry, InterfaceType receiverType,
      VariableDeclaration result, List<Statement> body) {
    body.add(_createExpressionStatement(_createIndexSet(
        entry.fileOffset,
        _createVariableGet(result)..fileOffset = TreeNode.noOffset,
        receiverType,
        entry.key,
        entry.value)));
  }

  void _translateIfEntry(
      IfMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> thenBody = [];
    _translateEntry(
        entry.then, receiverType, keyType, valueType, result, thenBody);
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateEntry(entry.otherwise!, receiverType, keyType, valueType,
          result, elseBody = <Statement>[]);
    }
    Statement thenStatement =
        thenBody.length == 1 ? thenBody.first : _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement =
          elseBody.length == 1 ? elseBody.first : _createBlock(elseBody);
    }
    IfStatement ifStatement = _createIf(
        entry.fileOffset, entry.condition, thenStatement, elseStatement);
    libraryBuilder.loader.dataForTesting?.registerAlias(entry, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfCaseEntry(
      IfCaseMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> thenBody = [];
    _translateEntry(
        entry.then, receiverType, keyType, valueType, result, thenBody);
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateEntry(entry.otherwise!, receiverType, keyType, valueType,
          result, elseBody = <Statement>[]);
    }
    Statement thenStatement =
        thenBody.length == 1 ? thenBody.first : _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement =
          elseBody.length == 1 ? elseBody.first : _createBlock(elseBody);
    }
    IfCaseStatement ifStatement = _createIfCase(
        entry.fileOffset,
        entry.expression,
        entry.matchedValueType!,
        entry.patternGuard,
        thenStatement,
        elseStatement);
    libraryBuilder.loader.dataForTesting?.registerAlias(entry, ifStatement);
    body.addAll(entry.prelude);
    body.add(ifStatement);
  }

  void _translateForEntry(
      ForMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> statements = <Statement>[];
    _translateEntry(
        entry.body, receiverType, keyType, valueType, result, statements);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    ForStatement loop = _createForStatement(entry.fileOffset, entry.variables,
        entry.condition, entry.updates, loopBody);
    libraryBuilder.loader.dataForTesting?.registerAlias(entry, loop);
    body.add(loop);
  }

  void _translatePatternForEntry(
      PatternForMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> statements = <Statement>[];
    _translateEntry(
        entry.body, receiverType, keyType, valueType, result, statements);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    ForStatement loop = _createForStatement(entry.fileOffset, entry.variables,
        entry.condition, entry.updates, loopBody);
    libraryBuilder.loader.dataForTesting?.registerAlias(entry, loop);
    body.add(entry.patternVariableDeclaration);
    body.addAll(entry.intermediateVariables);
    body.add(loop);
  }

  void _translateForInEntry(
      ForInMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> statements;
    Statement? prologue = entry.prologue;
    if (prologue == null) {
      statements = <Statement>[];
    } else {
      statements =
          prologue is Block ? prologue.statements : <Statement>[prologue];
    }
    _translateEntry(
        entry.body, receiverType, keyType, valueType, result, statements);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    if (entry.problem != null) {
      body.add(_createExpressionStatement(entry.problem!));
    }
    ForInStatement loop = _createForInStatement(
        entry.fileOffset, entry.variable, entry.iterable, loopBody,
        isAsync: entry.isAsync);
    libraryBuilder.loader.dataForTesting?.registerAlias(entry, loop);
    body.add(loop);
  }

  void _translateSpreadEntry(
      SpreadMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    Expression value = entry.expression;

    final InterfaceType entryType = new InterfaceType(engine.mapEntryClass,
        libraryBuilder.nonNullable, <DartType>[keyType, valueType]);
    final bool typeMatches = entry.entryType != null &&
        typeSchemaEnvironment.isSubtypeOf(
            entry.entryType!, entryType, SubtypeCheckMode.withNullabilities);

    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to '[]='.

      // Null-aware spreads require testing the subexpression's value.
      VariableDeclaration? temp;
      if (entry.isNullAware) {
        temp = _createVariable(
            value,
            typeSchemaEnvironment.mapType(
                keyType, valueType, libraryBuilder.nullable));
        body.add(temp);
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(_createMapAddAll(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          receiverType,
          value));

      if (entry.isNullAware) {
        statement = _createIf(
            temp!.fileOffset,
            _createEqualsNull(_createVariableGet(temp), notEquals: true),
            statement);
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      VariableDeclaration? temp;
      if (entry.isNullAware) {
        temp = _createVariable(
            value,
            typeSchemaEnvironment.mapType(const DynamicType(),
                const DynamicType(), libraryBuilder.nullable));
        body.add(temp);
        value = _createNullCheckedVariableGet(temp);
      }

      final InterfaceType variableType = new InterfaceType(
          engine.mapEntryClass,
          libraryBuilder.nonNullable,
          <DartType>[const DynamicType(), const DynamicType()]);
      VariableDeclaration variable =
          _createForInVariable(entry.fileOffset, variableType);
      VariableDeclaration keyVar = _createVariable(
          _createImplicitAs(
              entry.expression.fileOffset,
              _createGetKey(entry.expression.fileOffset,
                  _createVariableGet(variable), variableType),
              keyType),
          keyType);
      VariableDeclaration valueVar = _createVariable(
          _createImplicitAs(
              entry.expression.fileOffset,
              _createGetValue(entry.expression.fileOffset,
                  _createVariableGet(variable), variableType),
              valueType),
          valueType);
      Statement loopBody = _createBlock(<Statement>[
        keyVar,
        valueVar,
        _createExpressionStatement(_createIndexSet(
            entry.expression.fileOffset,
            _createVariableGet(result),
            receiverType,
            _createVariableGet(keyVar),
            _createVariableGet(valueVar)))
      ]);
      Statement statement = _createForInStatement(entry.fileOffset, variable,
          _createGetEntries(entry.fileOffset, value, receiverType), loopBody);

      if (entry.isNullAware) {
        statement = _createIf(
            temp!.fileOffset,
            _createEqualsNull(_createVariableGet(temp), notEquals: true),
            statement);
      }
      body.add(statement);
    }
  }

  Expression _translateConstListOrSet(
      Expression node, DartType elementType, List<Expression> elements,
      {bool isSet = false}) {
    assert((node is ListLiteral && node.isConst) ||
        (node is SetLiteral && node.isConst));

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
            _createSetLiteral(fileOffset, elementType, expressions,
                isConst: true),
            elementType,
            expressions,
            isSet: true);
      } else {
        return _translateConstListOrSet(
            _createListLiteral(fileOffset, elementType, expressions,
                isConst: true),
            elementType,
            expressions,
            isSet: false);
      }
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<Expression>? currentPart = i > 0 ? elements.sublist(0, i) : null;

    DartType iterableType = typeSchemaEnvironment.iterableType(
        elementType, libraryBuilder.nonNullable);

    for (; i < elements.length; ++i) {
      Expression element = elements[i];
      if (element is SpreadElement) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression spreadExpression = element.expression;
        if (element.isNullAware) {
          VariableDeclaration temp = _createVariable(
              spreadExpression,
              typeSchemaEnvironment.iterableType(
                  elementType, libraryBuilder.nullable));
          parts.add(_createNullAwareGuard(element.fileOffset, temp,
              makeLiteral(element.fileOffset, []), iterableType));
        } else {
          parts.add(spreadExpression);
        }
      } else if (element is IfElement) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression condition = element.condition;
        Expression then = makeLiteral(element.then.fileOffset, [element.then]);
        Expression otherwise = element.otherwise != null
            ? makeLiteral(element.otherwise!.fileOffset, [element.otherwise!])
            : makeLiteral(element.fileOffset, []);
        parts.add(_createConditionalExpression(
            element.fileOffset, condition, then, otherwise, iterableType));
      } else if (element is ForElement || element is ForInElement) {
        // Rejected earlier.
        problems.unhandled("${element.runtimeType}", "_translateConstListOrSet",
            element.fileOffset, helper.uri);
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
      return _translateConstMap(_createMapLiteral(
          fileOffset, node.keyType, node.valueType, entries,
          isConst: true));
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<MapLiteralEntry>? currentPart =
        i > 0 ? node.entries.sublist(0, i) : null;

    DartType collectionType = typeSchemaEnvironment.mapType(
        node.keyType, node.valueType, libraryBuilder.nonNullable);

    for (; i < node.entries.length; ++i) {
      MapLiteralEntry entry = node.entries[i];
      if (entry is SpreadMapEntry) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression spreadExpression = entry.expression;
        if (entry.isNullAware) {
          VariableDeclaration temp = _createVariable(spreadExpression,
              collectionType.withDeclaredNullability(libraryBuilder.nullable));
          parts.add(_createNullAwareGuard(entry.fileOffset, temp,
              makeLiteral(entry.fileOffset, []), collectionType));
        } else {
          parts.add(spreadExpression);
        }
      } else if (entry is IfMapEntry) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression condition = entry.condition;
        Expression then = makeLiteral(entry.then.fileOffset, [entry.then]);
        Expression otherwise = entry.otherwise != null
            ? makeLiteral(entry.otherwise!.fileOffset, [entry.otherwise!])
            : makeLiteral(node.fileOffset, []);
        parts.add(_createConditionalExpression(
            entry.fileOffset, condition, then, otherwise, collectionType));
      } else if (entry is ForMapEntry || entry is ForInMapEntry) {
        // Rejected earlier.
        problems.unhandled("${entry.runtimeType}", "_translateConstMap",
            entry.fileOffset, helper.uri);
      } else {
        currentPart ??= <MapLiteralEntry>[];
        currentPart.add(entry);
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(node.fileOffset, currentPart));
    }
    return new MapConcatenation(parts,
        keyType: node.keyType, valueType: node.valueType);
  }

  VariableDeclaration _createVariable(Expression expression, DartType type) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return new VariableDeclaration.forValue(expression, type: type)
      ..fileOffset = expression.fileOffset;
  }

  VariableDeclaration _createForInVariable(int fileOffset, DartType type) {
    assert(fileOffset != TreeNode.noOffset);
    return new VariableDeclaration.forValue(null, type: type)
      ..fileOffset = fileOffset;
  }

  VariableGet _createVariableGet(VariableDeclaration variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    return new VariableGet(variable)..fileOffset = variable.fileOffset;
  }

  VariableGet _createNullCheckedVariableGet(VariableDeclaration variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    DartType promotedType =
        variable.type.withDeclaredNullability(libraryBuilder.nonNullable);
    if (promotedType != variable.type) {
      return new VariableGet(variable, promotedType)
        ..fileOffset = variable.fileOffset;
    }
    return _createVariableGet(variable);
  }

  MapLiteral _createMapLiteral(int fileOffset, DartType keyType,
      DartType valueType, List<MapLiteralEntry> entries,
      {bool isConst = false}) {
    assert(fileOffset != TreeNode.noOffset);
    return new MapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  ListLiteral _createListLiteral(
      int fileOffset, DartType elementType, List<Expression> elements,
      {bool isConst = false}) {
    assert(fileOffset != TreeNode.noOffset);
    return new ListLiteral(elements,
        typeArgument: elementType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  SetLiteral _createSetLiteral(
      int fileOffset, DartType elementType, List<Expression> elements,
      {bool isConst = false}) {
    assert(fileOffset != TreeNode.noOffset);
    return new SetLiteral(elements, typeArgument: elementType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  Expression _createAdd(
      Expression receiver, InterfaceType receiverType, Expression argument,
      {required bool isSet}) {
    assert(argument.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${argument}.");
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(
            isSet ? engine.setAddFunctionType : engine.listAddFunctionType);
    if (!isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('add'), new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: isSet ? engine.setAdd : engine.listAdd)
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createAddAll(Expression receiver, InterfaceType receiverType,
      Expression argument, bool isSet) {
    assert(argument.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${argument}.");
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(isSet
            ? engine.setAddAllFunctionType
            : engine.listAddAllFunctionType);
    if (!isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('addAll'), new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: isSet ? engine.setAddAll : engine.listAddAll)
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createMapAddAll(
      Expression receiver, InterfaceType receiverType, Expression argument) {
    assert(argument.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${argument}.");
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(engine.mapAddAllFunctionType);
    if (!isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('addAll'), new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: engine.mapAddAll)
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createEqualsNull(Expression expression,
      {bool notEquals = false}) {
    assert(expression.fileOffset != TreeNode.noOffset);
    Expression check = new EqualsNull(expression)
      ..fileOffset = expression.fileOffset;
    if (notEquals) {
      check = new Not(check)..fileOffset = expression.fileOffset;
    }
    return check;
  }

  Expression _createIndexSet(int fileOffset, Expression receiver,
      InterfaceType receiverType, Expression key, Expression value) {
    assert(fileOffset != TreeNode.noOffset);
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(engine.mapPutFunctionType);
    if (!isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('[]='), new Arguments([key, value]),
        functionType: functionType as FunctionType,
        interfaceTarget: engine.mapPut)
      ..fileOffset = fileOffset
      ..isInvariant = true;
  }

  AsExpression _createImplicitAs(
      int fileOffset, Expression expression, DartType type) {
    assert(fileOffset != TreeNode.noOffset);
    return new AsExpression(expression, type)
      ..isTypeError = true
      ..isForNonNullableByDefault = isNonNullableByDefault
      ..fileOffset = fileOffset;
  }

  IfStatement _createIf(int fileOffset, Expression condition, Statement then,
      [Statement? otherwise]) {
    assert(fileOffset != TreeNode.noOffset);
    return new IfStatement(condition, then, otherwise)..fileOffset = fileOffset;
  }

  IfCaseStatement _createIfCase(int fileOffset, Expression condition,
      DartType matchedValueType, PatternGuard patternGuard, Statement then,
      [Statement? otherwise]) {
    assert(fileOffset != TreeNode.noOffset);
    return new IfCaseStatement(condition, patternGuard, then, otherwise)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
  }

  Expression _createGetKey(
      int fileOffset, Expression receiver, InterfaceType entryType) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(engine.mapEntryKey.type);
    return new InstanceGet(
        InstanceAccessKind.Instance, receiver, new Name('key'),
        interfaceTarget: engine.mapEntryKey, resultType: resultType)
      ..fileOffset = fileOffset;
  }

  Expression _createGetValue(
      int fileOffset, Expression receiver, InterfaceType entryType) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(engine.mapEntryValue.type);
    return new InstanceGet(
        InstanceAccessKind.Instance, receiver, new Name('value'),
        interfaceTarget: engine.mapEntryValue, resultType: resultType)
      ..fileOffset = fileOffset;
  }

  Expression _createGetEntries(
      int fileOffset, Expression receiver, InterfaceType mapType) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(mapType)
        .substituteType(engine.mapEntries.getterType);
    return new InstanceGet(
        InstanceAccessKind.Instance, receiver, new Name('entries'),
        interfaceTarget: engine.mapEntries, resultType: resultType)
      ..fileOffset = fileOffset;
  }

  ForStatement _createForStatement(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression? condition,
      List<Expression> updates,
      Statement body) {
    assert(fileOffset != TreeNode.noOffset);
    return new ForStatement(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  ForInStatement _createForInStatement(int fileOffset,
      VariableDeclaration variable, Expression iterable, Statement body,
      {bool isAsync = false}) {
    assert(fileOffset != TreeNode.noOffset);
    return new ForInStatement(variable, iterable, body, isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  Let _createNullAwareGuard(int fileOffset, VariableDeclaration variable,
      Expression defaultValue, DartType type) {
    return new Let(
        variable,
        _createConditionalExpression(
            fileOffset,
            _createEqualsNull(_createVariableGet(variable)),
            defaultValue,
            _createNullCheckedVariableGet(variable),
            type))
      ..fileOffset = fileOffset;
  }

  ConditionalExpression _createConditionalExpression(
      int fileOffset,
      Expression condition,
      Expression then,
      Expression otherwise,
      DartType type) {
    assert(fileOffset != TreeNode.noOffset);
    return new ConditionalExpression(condition, then, otherwise, type)
      ..fileOffset = fileOffset;
  }

  // Calculates the key and the value type of a spread map entry of type
  // spreadMapEntryType and stores them in output in positions offset and offset
  // + 1.  If the types can't be calculated, for example, if spreadMapEntryType
  // is a function type, the original values in output are preserved.
  void storeSpreadMapEntryElementTypes(DartType spreadMapEntryType,
      bool isNullAware, List<DartType?> output, int offset) {
    DartType typeBound = spreadMapEntryType.nonTypeVariableBound;
    if (coreTypes.isNull(typeBound)) {
      if (isNullAware) {
        if (isNonNullableByDefault) {
          output[offset] = output[offset + 1] = const NeverType.nonNullable();
        } else {
          output[offset] = output[offset + 1] = const NullType();
        }
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
      _MapLiteralEntryOffsets offsets) {
    if (entry.isNullAware) {
      spreadContext = computeNullable(spreadContext);
    }
    ExpressionInferenceResult spreadResult =
        inferExpression(entry.expression, spreadContext, isVoidAllowed: true);
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
    DartType spreadTypeBound = spreadType.nonTypeVariableBound;
    DartType? actualElementType =
        getSpreadElementType(spreadType, spreadTypeBound, entry.isNullAware);

    MapLiteralEntry replacement = entry;

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
                templateSpreadMapEntryElementValueTypeMismatch.withArguments(
                    actualValueType, inferredValueType, isNonNullableByDefault),
                entry.expression.fileOffset,
                1);
          }
        } else {
          valueError = helper.buildProblem(
              templateSpreadMapEntryElementValueTypeMismatch.withArguments(
                  actualValueType, inferredValueType, isNonNullableByDefault),
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
    entry.entryType = new InterfaceType(mapEntryClass!,
        libraryBuilder.nonNullable, <DartType>[actualKeyType, actualValueType]);

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
      _MapLiteralEntryOffsets offsets) {
    flowAnalysis.ifStatement_conditionBegin();
    DartType boolType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult =
        inferExpression(entry.condition, boolType, isVoidAllowed: false);
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
          offsets);
      int length = actualTypes.length;
      actualTypes[length - 2] = typeSchemaEnvironment.getStandardUpperBound(
          actualKeyType, actualTypes[length - 2],
          isNonNullableByDefault: isNonNullableByDefault);
      actualTypes[length - 1] = typeSchemaEnvironment.getStandardUpperBound(
          actualValueType, actualTypes[length - 1],
          isNonNullableByDefault: isNonNullableByDefault);
      int lengthForSet = actualTypesForSet.length;
      actualTypesForSet[lengthForSet - 1] =
          typeSchemaEnvironment.getStandardUpperBound(
              actualTypeForSet, actualTypesForSet[lengthForSet - 1],
              isNonNullableByDefault: isNonNullableByDefault);
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
      _MapLiteralEntryOffsets offsets) {
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
        inferredConditionTypes: inferredConditionTypes);
    IfCaseStatementResult<DartType, InvalidExpression> analysisResult =
        analyzeIfCaseElement(
            node: entry,
            expression: entry.expression,
            pattern: entry.patternGuard.pattern,
            variables: {
              for (VariableDeclaration variable
                  in entry.patternGuard.pattern.declaredVariables)
                variable.name!: variable
            },
            guard: entry.patternGuard.guard,
            ifTrue: entry.then,
            ifFalse: entry.otherwise,
            context: context);
    if (entry.otherwise != null) {
      DartType actualValueType = actualTypes.removeLast();
      DartType actualKeyType = actualTypes.removeLast();
      int length = actualTypes.length;
      actualTypes[length - 2] = typeSchemaEnvironment.getStandardUpperBound(
          actualKeyType, actualTypes[length - 2],
          isNonNullableByDefault: isNonNullableByDefault);
      actualTypes[length - 1] = typeSchemaEnvironment.getStandardUpperBound(
          actualValueType, actualTypes[length - 1],
          isNonNullableByDefault: isNonNullableByDefault);
      DartType actualTypeForSet = actualTypesForSet.removeLast();
      int lengthForSet = actualTypesForSet.length;
      actualTypesForSet[lengthForSet - 1] =
          typeSchemaEnvironment.getStandardUpperBound(
              actualTypeForSet, actualTypesForSet[lengthForSet - 1],
              isNonNullableByDefault: isNonNullableByDefault);
    }

    entry.matchedValueType = analysisResult.matchedExpressionType;

    assert(checkStack(entry, stackBase, [
      /* ifFalse = */ unionOfKinds(
          [ValueKinds.MapLiteralEntryOrNull, ValueKinds.ExpressionOrNull]),
      /* ifTrue = */ unionOfKinds(
          [ValueKinds.MapLiteralEntry, ValueKinds.Expression]),
      /* guard = */ ValueKinds.ExpressionOrNull,
      /* pattern = */ ValueKinds.Pattern,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite(NullValues.Expression);
    if (!identical(entry.otherwise, rewrite)) {
      entry.otherwise = (rewrite as MapLiteralEntry?)?..parent = entry;
    }

    rewrite = popRewrite();
    if (!identical(entry.then, rewrite)) {
      entry.then = (rewrite as MapLiteralEntry)..parent = entry;
    }

    PatternGuard patternGuard = entry.patternGuard;
    rewrite = popRewrite(NullValues.Expression);
    InvalidExpression? guardError = analysisResult.nonBooleanGuardError;
    if (guardError != null) {
      patternGuard.guard = guardError..parent = patternGuard;
    } else {
      if (!identical(patternGuard.guard, rewrite)) {
        patternGuard.guard = (rewrite as Expression?)?..parent = patternGuard;
      }
      if (analysisResult.guardType is DynamicType) {
        patternGuard.guard = _createImplicitAs(patternGuard.guard!.fileOffset,
            patternGuard.guard!, coreTypes.boolNonNullableRawType)
          ..parent = patternGuard;
      }
    }

    rewrite = popRewrite();
    if (!identical(patternGuard.pattern, rewrite)) {
      patternGuard.pattern = (rewrite as Pattern)..parent = patternGuard;
    }

    rewrite = popRewrite();
    if (!identical(entry.expression, rewrite)) {
      entry.expression = (rewrite as Expression)..parent = patternGuard;
    }

    return entry;
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
      _MapLiteralEntryOffsets offsets) {
    if (entry is PatternForMapEntry) {
      int? stackBase;
      assert(checkStackBase(entry, stackBase = stackHeight));

      PatternVariableDeclaration patternVariableDeclaration =
          entry.patternVariableDeclaration;
      PatternVariableDeclarationAnalysisResult<DartType, DartType>
          analysisResult = analyzePatternVariableDeclaration(
              patternVariableDeclaration,
              patternVariableDeclaration.pattern,
              patternVariableDeclaration.initializer,
              isFinal: patternVariableDeclaration.isFinal);
      patternVariableDeclaration.matchedValueType =
          analysisResult.initializerType;

      assert(checkStack(entry, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
        /* initializer = */ ValueKinds.Expression,
      ]));

      Object? rewrite = popRewrite(NullValues.Expression);
      if (!identical(patternVariableDeclaration.pattern, rewrite)) {
        patternVariableDeclaration.pattern = (rewrite as Pattern)
          ..parent = patternVariableDeclaration;
      }

      rewrite = popRewrite();
      if (!identical(patternVariableDeclaration.initializer, rewrite)) {
        patternVariableDeclaration.initializer = (rewrite as Expression)
          ..parent = patternVariableDeclaration;
      }

      List<VariableDeclaration> declaredVariables =
          patternVariableDeclaration.pattern.declaredVariables;
      assert(declaredVariables.length == entry.intermediateVariables.length);
      assert(declaredVariables.length == entry.variables.length);
      for (int i = 0; i < declaredVariables.length; i++) {
        DartType type = declaredVariables[i].type;
        entry.intermediateVariables[i].type = type;
        entry.variables[i].type = type;
      }
    }
    // TODO(johnniwinther): Use _visitStatements instead.
    List<VariableDeclaration>? variables;
    for (int index = 0; index < entry.variables.length; index++) {
      VariableDeclaration variable = entry.variables[index];
      if (variable.name == null) {
        if (variable.initializer != null) {
          ExpressionInferenceResult result = inferExpression(
              variable.initializer!, variable.type,
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
          entry.condition!, coreTypes.boolRawType(libraryBuilder.nonNullable),
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
        offsets);
    entry.body = body..parent = entry;
    flowAnalysis.for_updaterBegin();
    for (int index = 0; index < entry.updates.length; index++) {
      ExpressionInferenceResult updateResult = inferExpression(
          entry.updates[index], const UnknownType(),
          isVoidAllowed: true);
      entry.updates[index] = updateResult.expression..parent = entry;
    }
    flowAnalysis.for_end();
    return entry;
  }

  MapLiteralEntry _inferForInMapEntry(
      ForInMapEntry entry,
      TreeNode parent,
      DartType inferredKeyType,
      DartType inferredValueType,
      DartType spreadContext,
      List<DartType> actualTypes,
      List<DartType> actualTypesForSet,
      Map<TreeNode, DartType> inferredSpreadTypes,
      Map<Expression, DartType> inferredConditionTypes,
      _MapLiteralEntryOffsets offsets) {
    ForInResult result;
    if (entry.variable.name == null) {
      result = handleForInWithoutVariable(entry, entry.variable, entry.iterable,
          entry.syntheticAssignment, entry.expressionEffects,
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
          entry.problem!, const UnknownType(),
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
        offsets);
    entry.body = body..parent = entry;
    // This is matched by the call to [forEach_bodyBegin] in
    // [handleForInWithoutVariable] or [handleForInDeclaringVariable].
    flowAnalysis.forEach_end();
    return entry;
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
      _MapLiteralEntryOffsets offsets) {
    if (entry is SpreadMapEntry) {
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
          offsets);
    } else if (entry is IfMapEntry) {
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
          offsets);
    } else if (entry is IfCaseMapEntry) {
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
          offsets);
    } else if (entry is ForMapEntry) {
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
          offsets);
    } else if (entry is ForInMapEntry) {
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
          offsets);
    } else {
      ExpressionInferenceResult keyResult =
          inferExpression(entry.key, inferredKeyType, isVoidAllowed: true);
      Expression key = ensureAssignableResult(inferredKeyType, keyResult,
              isVoidAllowed: inferredKeyType is VoidType)
          .expression;
      entry.key = key..parent = entry;
      ExpressionInferenceResult valueResult =
          inferExpression(entry.value, inferredValueType, isVoidAllowed: true);
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

    assert((node.keyType is ImplicitTypeArgument) ==
        (node.valueType is ImplicitTypeArgument));
    bool inferenceNeeded = node.keyType is ImplicitTypeArgument;
    bool typeContextIsMap = node.keyType is! ImplicitTypeArgument;
    DartType? typeContextAsIterable;
    DartType? unfuturedTypeContext = typeSchemaEnvironment.flatten(typeContext);
    // Ambiguous set/map literal
    if (unfuturedTypeContext is TypeDeclarationType) {
      if (!typeContextIsMap) {
        // TODO(johnniwinther): Can we use the found type arguments instead of
        // the inferred types?
        typeContextIsMap = hierarchyBuilder.getTypeArgumentsAsInstanceOf(
                unfuturedTypeContext, coreTypes.mapClass) !=
            null;
      }
      typeContextAsIterable = hierarchyBuilder.getTypeAsInstanceOf(
          unfuturedTypeContext, coreTypes.iterableClass,
          isNonNullableByDefault: isNonNullableByDefault);
      if (node.entries.isEmpty &&
          typeContextAsIterable != null &&
          !typeContextIsMap) {
        // Set literal
        SetLiteral setLiteral = new SetLiteral([],
            typeArgument: const ImplicitTypeArgument(), isConst: node.isConst)
          ..fileOffset = node.fileOffset;
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
          mapType, typeParametersToInfer, typeContext,
          isNonNullableByDefault: isNonNullableByDefault,
          isConst: node.isConst,
          typeOperations: operations,
          inferenceResultForTesting: dataForTesting?.typeInferenceResult,
          treeNodeForTesting: node);
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
          gatherer, typeParametersToInfer, null,
          isNonNullableByDefault: isNonNullableByDefault);
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
          actualTypes,
          actualTypesForSet,
          inferredSpreadTypes,
          inferredConditionTypes,
          offsets);
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
            coreTypes.setClass, libraryBuilder.nonNullable);
        FreshStructuralParametersFromTypeParameters freshTypeParameters =
            getFreshStructuralParametersFromTypeParameters(
                coreTypes.setClass.typeParameters);
        List<StructuralParameter> typeParametersToInfer =
            freshTypeParameters.freshTypeParameters;
        setType = freshTypeParameters.substitute(setType) as InterfaceType;
        for (int i = 0; i < node.entries.length; ++i) {
          setElements.add(convertToElement(
            node.entries[i],
            helper,
            assignedVariables.reassignInfo,
            actualType: actualTypesForSet[i],
          ));
          formalTypesForSet.add(setType.typeArguments[0]);
        }

        // Note: we don't use the previously created gatherer because it was set
        // up presuming that the literal would be a map; we now know that it
        // needs to be a set.
        TypeConstraintGatherer gatherer =
            typeSchemaEnvironment.setupGenericTypeInference(
                setType, typeParametersToInfer, typeContext,
                isNonNullableByDefault: isNonNullableByDefault,
                isConst: node.isConst,
                typeOperations: operations,
                inferenceResultForTesting: dataForTesting?.typeInferenceResult,
                treeNodeForTesting: node);
        List<DartType> inferredTypesForSet = typeSchemaEnvironment
            .choosePreliminaryTypes(gatherer, typeParametersToInfer, null,
                isNonNullableByDefault: isNonNullableByDefault);
        gatherer.constrainArguments(formalTypesForSet, actualTypesForSet,
            treeNodeForTesting: node);
        inferredTypesForSet = typeSchemaEnvironment.chooseFinalTypes(
            gatherer, typeParametersToInfer, inferredTypesForSet,
            isNonNullableByDefault: isNonNullableByDefault);
        DartType inferredTypeArgument = inferredTypesForSet[0];
        instrumentation?.record(
            uriForInstrumentation,
            node.fileOffset,
            'typeArgs',
            new InstrumentationValueForTypeArgs([inferredTypeArgument]));

        SetLiteral setLiteral = new SetLiteral(setElements,
            typeArgument: inferredTypeArgument, isConst: node.isConst)
          ..fileOffset = node.fileOffset;
        for (int i = 0; i < setLiteral.expressions.length; i++) {
          checkElement(
              setLiteral.expressions[i],
              setLiteral,
              setLiteral.typeArgument,
              inferredSpreadTypes,
              inferredConditionTypes);
        }

        Expression result = _translateSetLiteral(setLiteral);
        DartType inferredType = new InterfaceType(coreTypes.setClass,
            libraryBuilder.nonNullable, inferredTypesForSet);
        return new ExpressionInferenceResult(inferredType, result);
      }
      if (canBeSet && canBeMap && node.entries.isNotEmpty) {
        Expression replacement = helper.buildProblem(
            messageCantDisambiguateNotEnoughInformation, node.fileOffset, 1);
        return new ExpressionInferenceResult(
            NeverType.fromNullability(libraryBuilder.nonNullable), replacement);
      }
      if (!canBeSet && !canBeMap) {
        Expression replacement = helper.buildProblem(
            messageCantDisambiguateAmbiguousInformation, node.fileOffset, 1);
        return new ExpressionInferenceResult(
            NeverType.fromNullability(libraryBuilder.nonNullable), replacement);
      }
      gatherer!.constrainArguments(formalTypes, actualTypes,
          treeNodeForTesting: node);
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
          gatherer, typeParametersToInfer, inferredTypes!,
          isNonNullableByDefault: isNonNullableByDefault);
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
    for (int index = 0; index < node.entries.length; ++index) {
      MapLiteralEntry entry = checkMapEntry(node.entries[index], node.keyType,
          node.valueType, inferredSpreadTypes, inferredConditionTypes, offsets);
      node.entries[index] = entry..parent = node;
    }
    DartType inferredType = new InterfaceType(mapClass,
        libraryBuilder.nonNullable, [inferredKeyType, inferredValueType]);
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

  ExpressionInferenceResult visitMethodInvocation(
      MethodInvocation node, DartType typeContext) {
    assert(node.name != unaryMinusName);
    ExpressionInferenceResult result =
        inferNullAwareExpression(node.receiver, const UnknownType());
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
      ObjectAccessTarget target = new ObjectAccessTarget.interfaceMember(
          thisType!, member,
          hasNonObjectMemberAccess: true);
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
      libraryBuilder.checkBoundsInStaticInvocation(
          invocation, typeSchemaEnvironment, helper.uri, typeArgumentsInfo);
      return new ExpressionInferenceResult(
          result.inferredType, result.applyResult(invocation));
    } else {
      // TODO(johnniwinther): Handle augmentation of field with inferred types.
      TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
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
        inferNullAwareExpression(node.expression, const UnknownType());
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
        inferExpression(node.operand, boolType);
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
    ExpressionInferenceResult operandResult =
        inferNullAwareExpression(node.operand, computeNullable(typeContext));

    Link<NullAwareGuard> nullAwareGuards = operandResult.nullAwareGuards;
    Expression operand = operandResult.nullAwareAction;
    DartType operandType = operandResult.nullAwareActionType;

    node.operand = operand..parent = node;
    flowAnalysis.nonNullAssert_end(node.operand);
    DartType nonNullableResultType = operations.promoteToNonNull(operandType);
    return createNullAwareExpressionInferenceResult(
        nonNullableResultType, node, nullAwareGuards);
  }

  ExpressionInferenceResult visitNullAwareMethodInvocation(
      NullAwareMethodInvocation node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferSyntheticVariableNullAware(node.variable);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult invocationResult =
        inferExpression(node.invocation, typeContext, isVoidAllowed: true);
    return createNullAwareExpressionInferenceResult(
        invocationResult.inferredType,
        invocationResult.expression,
        nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwarePropertyGet(
      NullAwarePropertyGet node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferSyntheticVariableNullAware(node.variable);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult readResult =
        inferExpression(node.read, typeContext);
    return createNullAwareExpressionInferenceResult(readResult.inferredType,
        readResult.expression, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwarePropertySet(
      NullAwarePropertySet node, DartType typeContext) {
    Link<NullAwareGuard> nullAwareGuards =
        inferSyntheticVariableNullAware(node.variable);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult writeResult =
        inferExpression(node.write, typeContext, isVoidAllowed: true);
    return createNullAwareExpressionInferenceResult(writeResult.inferredType,
        writeResult.expression, nullAwareGuards.prepend(nullAwareGuard));
  }

  ExpressionInferenceResult visitNullAwareExtension(
      NullAwareExtension node, DartType typeContext) {
    inferSyntheticVariable(node.variable);
    NullAwareGuard nullAwareGuard = createNullAwareGuard(node.variable);
    ExpressionInferenceResult expressionResult =
        inferExpression(node.expression, typeContext);
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
        node.receiver, const UnknownType(),
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
        isSetter: true, instrumented: true, includeExtensionMethods: true);
    DartType writeType = writeTarget.getSetterType(this);

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

    ExpressionInferenceResult writeResult = _computePropertySet(
        node.writeOffset,
        writeReceiver,
        receiverType,
        node.propertyName,
        writeTarget,
        binary,
        valueType: binaryType,
        forEffect: node.forEffect);
    Expression write = writeResult.expression;

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
        node.receiver, const UnknownType(),
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

    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;

    ObjectAccessTarget writeTarget = findInterfaceMember(
        receiverType, node.propertyName, receiver.fileOffset,
        isSetter: true, instrumented: true, includeExtensionMethods: true);
    DartType writeContext = writeTarget.getSetterType(this);

    flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.rhs, writeContext, isVoidAllowed: true);
    flowAnalysis.ifNullExpression_end();

    rhsResult = ensureAssignableResult(writeContext, rhsResult);
    Expression rhs = rhsResult.expression;

    DartType writeType = rhsResult.inferredType;
    ExpressionInferenceResult writeResult = _computePropertySet(
        node.writeOffset,
        writeReceiver,
        receiverType,
        node.propertyName,
        writeTarget,
        rhs,
        forEffect: node.forEffect,
        valueType: writeType);
    Expression write = writeResult.expression;

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
        nonNullableReadType: nonNullableReadType,
        rhsType: writeType,
        typeContext: typeContext);

    Expression replacement;
    if (node.forEffect) {
      // Encode `o.a ??= b` as:
      //
      //     let v1 = o in v1.a == null ? v1.a = b : null
      //
      Expression equalsNull =
          createEqualsNull(read, fileOffset: node.fileOffset);
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
      Expression equalsNull = createEqualsNull(createVariableGet(readVariable),
          fileOffset: node.fileOffset);
      VariableGet variableGet = createVariableGet(readVariable);
      if (isNonNullableByDefault && !identical(nonNullableReadType, readType)) {
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

  DartType _analyzeIfNullTypes(
      {required DartType nonNullableReadType,
      required DartType rhsType,
      required DartType typeContext}) {
    // - An if-null assignment `E` of the form `lvalue ??= e` with context type
    //   `K` is analyzed as follows:
    //
    //   - Let `T1` be the read type the lvalue.
    //   - Let `T2` be the type of `e` inferred with context type `T1`.
    DartType t2 = rhsType;
    //   - Let `T` be `UP(NonNull(T1), T2)`.
    DartType nonNullT1 = nonNullableReadType;
    DartType t = typeSchemaEnvironment.getStandardUpperBound(nonNullT1, t2,
        isNonNullableByDefault: isNonNullableByDefault);
    //   - Let `S` be the greatest closure of `K`.
    DartType s = computeGreatestClosure(typeContext);
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled) {
      return t;
    } else
    //   - If `T <: S`, then the type of `E` is `T`.
    if (typeSchemaEnvironment.isSubtypeOf(
        t, s, SubtypeCheckMode.withNullabilities)) {
      return t;
    }
    //   - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of
    //     `E` is `S`.
    if (typeSchemaEnvironment.isSubtypeOf(
            nonNullT1, s, SubtypeCheckMode.withNullabilities) &&
        typeSchemaEnvironment.isSubtypeOf(
            t2, s, SubtypeCheckMode.withNullabilities)) {
      return s;
    }
    //   - Otherwise, the type of `E` is `T`.
    return t;
  }

  ExpressionInferenceResult visitIfNullSet(
      IfNullSet node, DartType typeContext) {
    ExpressionInferenceResult readResult =
        inferNullAwareExpression(node.read, const UnknownType());

    Link<NullAwareGuard> nullAwareGuards = readResult.nullAwareGuards;
    Expression read = readResult.nullAwareAction;
    DartType readType = readResult.nullAwareActionType;

    flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult writeResult =
        inferExpression(node.write, typeContext, isVoidAllowed: true);
    flowAnalysis.ifNullExpression_end();

    DartType originalReadType = readType;
    DartType nonNullableReadType = originalReadType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
        nonNullableReadType: nonNullableReadType,
        rhsType: writeResult.inferredType,
        typeContext: typeContext);

    Expression replacement;
    if (node.forEffect) {
      // Encode `a ??= b` as:
      //
      //     a == null ? a = b : null
      //
      Expression equalsNull =
          createEqualsNull(read, fileOffset: node.fileOffset);
      replacement = new ConditionalExpression(
          equalsNull,
          writeResult.expression,
          new NullLiteral()..fileOffset = node.fileOffset,
          computeNullable(inferredType))
        ..fileOffset = node.fileOffset;
    } else {
      // Encode `a ??= b` as:
      //
      //      let v1 = a in v1 == null ? a = b : v1
      //
      VariableDeclaration readVariable = createVariable(read, readType);
      Expression equalsNull = createEqualsNull(createVariableGet(readVariable),
          fileOffset: node.fileOffset);
      VariableGet variableGet = createVariableGet(readVariable);
      if (isNonNullableByDefault &&
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
        node.receiver, const UnknownType(),
        isVoidAllowed: true);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
        receiverType, indexGetName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);

    DartType indexType = indexGetTarget.getIndexKeyType(this);

    MethodContravarianceCheckKind readCheckKind =
        preCheckInvocationContravariance(receiverType, indexGetTarget,
            isThisReceiver: node.receiver is ThisExpression);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, isVoidAllowed: true);

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
        node.receiver, const UnknownType(),
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
        includeExtensionMethods: true, isSetter: false);

    DartType indexType = indexSetTarget.getIndexKeyType(this);
    DartType valueType = indexSetTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    VariableDeclaration? indexVariable;
    if (!node.forEffect && !isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
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
    ObjectAccessTarget indexSetTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(thisType!, node.setter,
            hasNonObjectMemberAccess: true)
        : new ObjectAccessTarget.superMember(thisType!, node.setter);

    DartType indexType = indexSetTarget.getIndexKeyType(this);
    DartType valueType = indexSetTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    VariableDeclaration? indexVariable;
    if (!isPureExpression(index)) {
      indexVariable = createVariable(index, indexResult.inferredType);
      index = createVariableGet(indexVariable);
    }

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
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

    assert(indexSetTarget.isInstanceMember || indexSetTarget.isSuperMember,
        'Unexpected index set target $indexSetTarget.');
    instrumentation?.record(uriForInstrumentation, node.fileOffset, 'target',
        new InstrumentationValueForMember(node.setter));
    Expression assignment = new SuperMethodInvocation(
        indexSetName,
        new Arguments(<Expression>[index, value])..fileOffset = node.fileOffset,
        indexSetTarget.classMember as Procedure)
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
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension, node.explicitTypeArguments, receiverResult.inferredType,
        treeNodeForTesting: node);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    Expression receiver =
        ensureAssignableResult(receiverType, receiverResult).expression;

    VariableDeclaration? receiverVariable;
    if (!isPureExpression(receiver)) {
      receiverVariable = createVariable(receiver, receiverType);
      receiver = createVariableGet(receiverVariable);
    }

    ObjectAccessTarget target = new ExtensionAccessTarget(receiverType,
        node.setter, null, ClassMemberKind.Method, extensionTypeArguments);

    DartType indexType = target.getIndexKeyType(this);
    DartType valueType = target.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, indexType, isVoidAllowed: true);

    Expression index =
        ensureAssignableResult(indexType, indexResult).expression;

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
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
        node.receiver, const UnknownType(),
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
        includeExtensionMethods: true, isSetter: false);

    MethodContravarianceCheckKind checkKind = preCheckInvocationContravariance(
        receiverType, readTarget,
        isThisReceiver: node.receiver is ThisExpression);

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ObjectAccessTarget writeTarget = findInterfaceMember(
        receiverType, indexSetName, node.writeOffset,
        includeExtensionMethods: true, isSetter: false);

    DartType writeIndexType = writeTarget.getIndexKeyType(this);
    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, isVoidAllowed: true);

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
    Expression read = readResult.expression;
    DartType readType = readResult.inferredType;
    flowAnalysis.ifNullExpression_rightBegin(read, readType);

    writeIndex = ensureAssignable(
        writeIndexType, indexResult.inferredType, writeIndex,
        whyNotPromoted: whyNotPromotedIndex);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
        nonNullableReadType: nonNullableReadType,
        rhsType: valueResult.inferredType,
        typeContext: typeContext);

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
      Expression equalsNull =
          createEqualsNull(read, fileOffset: node.testOffset);
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
      Expression equalsNull = createEqualsNull(createVariableGet(readVariable),
          fileOffset: node.testOffset);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet variableGet = createVariableGet(readVariable);
      if (isNonNullableByDefault && !identical(nonNullableReadType, readType)) {
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
        ? (thisType!.classNode.isMixinDeclaration
            ? new ObjectAccessTarget.interfaceMember(thisType!, node.getter!,
                hasNonObjectMemberAccess: true)
            : new ObjectAccessTarget.superMember(thisType!, node.getter!))
        : const ObjectAccessTarget.missing();

    DartType readType = readTarget.getReturnType(this);
    DartType readIndexType = readTarget.getIndexKeyType(this);

    ObjectAccessTarget writeTarget = node.setter != null
        ? (thisType!.classNode.isMixinDeclaration
            ? new ObjectAccessTarget.interfaceMember(thisType!, node.setter!,
                hasNonObjectMemberAccess: true)
            : new ObjectAccessTarget.superMember(thisType!, node.setter!))
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = writeTarget.getIndexKeyType(this);
    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, isVoidAllowed: true);

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

    assert(readTarget.isInstanceMember || readTarget.isSuperMember);
    instrumentation?.record(uriForInstrumentation, node.readOffset, 'target',
        new InstrumentationValueForMember(node.getter!));
    Expression read = new SuperMethodInvocation(
        indexGetName,
        new Arguments(<Expression>[
          readIndex,
        ])
          ..fileOffset = node.readOffset,
        readTarget.classMember as Procedure)
      ..fileOffset = node.readOffset;

    flowAnalysis.ifNullExpression_rightBegin(read, readType);
    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
        nonNullableReadType: nonNullableReadType,
        rhsType: valueResult.inferredType,
        typeContext: typeContext);

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

    assert(writeTarget.isInstanceMember || writeTarget.isSuperMember);
    instrumentation?.record(uriForInstrumentation, node.writeOffset, 'target',
        new InstrumentationValueForMember(node.setter!));
    Expression write = new SuperMethodInvocation(
        indexSetName,
        new Arguments(<Expression>[writeIndex, value])
          ..fileOffset = node.writeOffset,
        writeTarget.classMember as Procedure)
      ..fileOffset = node.writeOffset;

    Expression replacement;
    if (node.forEffect) {
      // Encode `o[a] ??= b` as:
      //
      //     let v1 = a in
      //        super[v1] == null ? super.[]=(v1, b) : null
      //
      assert(valueVariable == null);
      Expression equalsNull =
          createEqualsNull(read, fileOffset: node.testOffset);
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
      Expression equalsNull = createEqualsNull(createVariableGet(readVariable),
          fileOffset: node.testOffset);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (isNonNullableByDefault && !identical(nonNullableReadType, readType)) {
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
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension, node.explicitTypeArguments, receiverResult.inferredType,
        treeNodeForTesting: node);

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
        ? new ExtensionAccessTarget(receiverType, node.getter!, null,
            ClassMemberKind.Method, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ObjectAccessTarget writeTarget = node.setter != null
        ? new ExtensionAccessTarget(receiverType, node.setter!, null,
            ClassMemberKind.Method, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = writeTarget.getIndexKeyType(this);
    DartType valueType = writeTarget.getIndexSetValueType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, isVoidAllowed: true);

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
    flowAnalysis.ifNullExpression_rightBegin(read, readType);

    writeIndex =
        ensureAssignable(writeIndexType, indexResult.inferredType, writeIndex);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;
    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
        nonNullableReadType: nonNullableReadType,
        rhsType: valueResult.inferredType,
        typeContext: typeContext);

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
      Expression equalsNull =
          createEqualsNull(read, fileOffset: node.testOffset);
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
      Expression equalsNull = createEqualsNull(createVariableGet(readVariable),
          fileOffset: node.testOffset);
      VariableDeclaration writeVariable =
          createVariable(write, const VoidType());
      VariableGet readVariableGet = createVariableGet(readVariable);
      if (isNonNullableByDefault && !identical(nonNullableReadType, readType)) {
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
    ExpressionInfo<DartType>? equalityInfo =
        flowAnalysis.equalityOperand_end(left, leftType);

    Expression? equals;
    ExpressionInferenceResult rightResult =
        inferExpression(right, const UnknownType(), isVoidAllowed: false);

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
        includeExtensionMethods: true, isSetter: false);

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
    DartType rightType = equalsTarget.getBinaryOperandType(this);
    if (libraryBuilder.isNonNullableByDefault) {
      rightType = operations.getNullableType(rightType);
    } else {
      rightType = operations.getLegacyType(rightType);
    }
    DartType contextType =
        rightType.withDeclaredNullability(libraryBuilder.nullable);
    rightResult = ensureAssignableResult(contextType, rightResult,
        errorTemplate: templateArgumentTypeNotAssignable,
        nullabilityErrorTemplate: templateArgumentTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateArgumentTypeNotAssignablePartNullability,
        nullabilityNullErrorTemplate:
            templateArgumentTypeNotAssignableNullabilityNull,
        nullabilityNullTypeErrorTemplate:
            templateArgumentTypeNotAssignableNullabilityNullType);
    right = rightResult.expression;

    FunctionType functionType = equalsTarget.getFunctionType(this);
    equals = new EqualsCall(left, right,
        functionType: functionType,
        interfaceTarget: equalsTarget.classMember as Procedure)
      ..fileOffset = fileOffset;
    if (isNot) {
      equals = new Not(equals)..fileOffset = fileOffset;
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
        includeExtensionMethods: true, isSetter: false);

    MethodContravarianceCheckKind binaryCheckKind =
        preCheckInvocationContravariance(leftType, binaryTarget,
            isThisReceiver: false);

    DartType binaryType = binaryTarget.getReturnType(this);
    DartType rightType = binaryTarget.getBinaryOperandType(this);

    bool isSpecialCasedBinaryOperator =
        binaryTarget.isSpecialCasedBinaryOperator(this);

    DartType rightContextType = rightType;
    if (isSpecialCasedBinaryOperator) {
      rightContextType =
          typeSchemaEnvironment.getContextTypeOfSpecialCasedBinaryOperator(
              contextType, leftType, rightType,
              isNonNullableByDefault: isNonNullableByDefault);
    }

    ExpressionInferenceResult rightResult =
        inferExpression(right, rightContextType, isVoidAllowed: true);

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
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        assert(binaryTarget.declarationMethodKind != ClassMemberKind.Setter);
        binary = new StaticInvocation(
            binaryTarget.member as Procedure,
            new Arguments(<Expression>[
              left,
              right,
            ], types: binaryTarget.receiverTypeArguments)
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
      case ObjectAccessTargetKind.superMember:
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
            interfaceTarget: binaryTarget.classMember as Procedure)
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
        includeExtensionMethods: true, isSetter: false);

    MethodContravarianceCheckKind unaryCheckKind =
        preCheckInvocationContravariance(expressionType, unaryTarget,
            isThisReceiver: false);

    DartType unaryType = unaryTarget.getReturnType(this);

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
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        assert(unaryTarget.declarationMethodKind != ClassMemberKind.Setter);
        unary = new StaticInvocation(
            unaryTarget.member as Procedure,
            new Arguments(<Expression>[
              expression,
            ], types: unaryTarget.receiverTypeArguments)
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
      case ObjectAccessTargetKind.superMember:
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
            interfaceTarget: unaryTarget.classMember as Procedure)
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
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        throw new UnsupportedError('Unexpected unary target ${unaryTarget}');
    }

    if (!isNonNullableByDefault) {
      unaryType = legacyErasure(unaryType);
    }

    if (unaryTarget.isNullable) {
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
    DartType readType = readTarget.getReturnType(this);
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
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        read = new StaticInvocation(
            readTarget.member as Procedure,
            new Arguments(<Expression>[
              readReceiver,
              readIndex,
            ], types: readTarget.receiverTypeArguments)
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
      case ObjectAccessTargetKind.superMember:
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
            interfaceTarget: readTarget.classMember as Procedure)
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
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        throw new UnsupportedError('Unexpected index get target ${readTarget}');
    }

    if (!isNonNullableByDefault) {
      readType = legacyErasure(readType);
    }

    if (readTarget.isNullable) {
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
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        assert(writeTarget.declarationMethodKind != ClassMemberKind.Setter);
        write = new StaticInvocation(
            writeTarget.member as Procedure,
            new Arguments(<Expression>[receiver, index, value],
                types: writeTarget.receiverTypeArguments)
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
      case ObjectAccessTargetKind.superMember:
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
            interfaceTarget: writeTarget.classMember as Procedure)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        throw new UnsupportedError(
            'Unexpected index set target ${writeTarget}');
    }
    if (writeTarget.isNullable) {
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
      ObjectAccessTarget? readTarget,
      Expression? propertyGetNode}) {
    Map<DartType, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(receiver);

    readTarget ??= findInterfaceMember(receiverType, propertyName, fileOffset,
        includeExtensionMethods: true, isSetter: false);

    DartType readType = readTarget.getGetterType(this);
    DartType? promotedReadType = flowAnalysis.propertyGet(
        propertyGetNode,
        computePropertyTarget(receiver),
        propertyName.text,
        readTarget is ExtensionTypeRepresentationAccessTarget
            ? readTarget.representationField
            : readTarget.member,
        readType);
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
        whyNotPromoted: whyNotPromoted);
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
  ///
  /// The returned [ExpressionInferenceResult] holds the generated expression
  /// and the type of this expression. Normally this is the [valueType] but
  /// for setter extension for effect, the generated expression has type
  /// `void`.
  ExpressionInferenceResult _computePropertySet(
      int fileOffset,
      Expression receiver,
      DartType receiverType,
      Name propertyName,
      ObjectAccessTarget writeTarget,
      Expression value,
      {required DartType valueType,
      required bool forEffect}) {
    Expression write;
    DartType writeType = valueType;
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
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        if (forEffect) {
          write = new StaticInvocation(
              writeTarget.member as Procedure,
              new Arguments(<Expression>[receiver, value],
                  types: writeTarget.receiverTypeArguments)
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset;
          // The generate invocation has a void return type.
          writeType = const VoidType();
        } else {
          VariableDeclaration valueVariable = createVariable(value, valueType);
          VariableDeclaration assignmentVariable = createVariable(
              new StaticInvocation(
                  writeTarget.member as Procedure,
                  new Arguments(
                      <Expression>[receiver, createVariableGet(valueVariable)],
                      types: writeTarget.receiverTypeArguments)
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
      case ObjectAccessTargetKind.superMember:
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
            interfaceTarget: writeTarget.classMember!)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        throw new UnsupportedError('Unexpected write target ${writeTarget}');
    }
    Expression result;
    if (writeTarget.isNullable) {
      result = helper.wrapInProblem(
          write,
          templateNullablePropertyAccessError.withArguments(
              propertyName.text, receiverType, isNonNullableByDefault),
          write.fileOffset,
          propertyName.text.length);
    } else {
      result = write;
    }
    return new ExpressionInferenceResult(writeType, result);
  }

  ExpressionInferenceResult visitCompoundIndexSet(
      CompoundIndexSet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(),
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
        includeExtensionMethods: true, isSetter: false);

    MethodContravarianceCheckKind readCheckKind =
        preCheckInvocationContravariance(receiverType, readTarget,
            isThisReceiver: node.receiver is ThisExpression);

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, isVoidAllowed: true);

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
        includeExtensionMethods: true, isSetter: false);

    DartType writeIndexType = writeTarget.getIndexKeyType(this);

    DartType valueType = writeTarget.getIndexSetValueType(this);

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
        node.receiver, const UnknownType(),
        isVoidAllowed: true);

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
        isSetter: true, includeExtensionMethods: true);

    DartType valueType = writeTarget.getSetterType(this);

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

    ExpressionInferenceResult writeResult = _computePropertySet(
        node.writeOffset,
        writeReceiver,
        nonNullReceiverType,
        node.propertyName,
        writeTarget,
        valueExpression,
        valueType: binaryType,
        forEffect: true);
    Expression write = writeResult.expression;
    DartType writeType = writeResult.inferredType;

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

      VariableDeclaration writeVariable = createVariable(write, writeType);
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
    ObjectAccessTarget readTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(thisType!, node.getter,
            hasNonObjectMemberAccess: true)
        : new ObjectAccessTarget.superMember(thisType!, node.getter);

    DartType readType = readTarget.getReturnType(this);
    DartType readIndexType = readTarget.getIndexKeyType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, isVoidAllowed: true);

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

    assert(readTarget.isInstanceMember || readTarget.isSuperMember);
    instrumentation?.record(uriForInstrumentation, node.readOffset, 'target',
        new InstrumentationValueForMember(node.getter));
    Expression read = new SuperMethodInvocation(
        indexGetName,
        new Arguments(<Expression>[
          readIndex,
        ])
          ..fileOffset = node.readOffset,
        readTarget.classMember as Procedure)
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
    ObjectAccessTarget writeTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(thisType!, node.setter,
            hasNonObjectMemberAccess: true)
        : new ObjectAccessTarget.superMember(thisType!, node.setter);

    DartType writeIndexType = writeTarget.getIndexKeyType(this);

    DartType valueType = writeTarget.getIndexSetValueType(this);

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

    assert(writeTarget.isInstanceMember || writeTarget.isSuperMember);
    instrumentation?.record(uriForInstrumentation, node.writeOffset, 'target',
        new InstrumentationValueForMember(node.setter));
    Expression write = new SuperMethodInvocation(
        indexSetName,
        new Arguments(<Expression>[writeIndex, valueExpression])
          ..fileOffset = node.writeOffset,
        writeTarget.classMember as Procedure)
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
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

    List<DartType> extensionTypeArguments = computeExtensionTypeArgument(
        node.extension, node.explicitTypeArguments, receiverResult.inferredType,
        treeNodeForTesting: node);

    DartType receiverType =
        getExtensionReceiverType(node.extension, extensionTypeArguments);

    ObjectAccessTarget readTarget = node.getter != null
        ? new ExtensionAccessTarget(receiverType, node.getter!, null,
            ClassMemberKind.Method, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

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

    DartType readIndexType = readTarget.getIndexKeyType(this);

    ExpressionInferenceResult indexResult =
        inferExpression(node.index, readIndexType, isVoidAllowed: true);

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
        ? new ExtensionAccessTarget(receiverType, node.setter!, null,
            ClassMemberKind.Method, extensionTypeArguments)
        : const ObjectAccessTarget.missing();

    DartType writeIndexType = writeTarget.getIndexKeyType(this);

    DartType valueType = writeTarget.getIndexSetValueType(this);

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
    const NullType nullType = const NullType();
    flowAnalysis.nullLiteral(node, nullType);
    return new ExpressionInferenceResult(nullType, node);
  }

  @override
  ExpressionInferenceResult visitLet(Let node, DartType typeContext) {
    DartType variableType = node.variable.type;
    ExpressionInferenceResult initializerResult = inferExpression(
        node.variable.initializer!, variableType,
        isVoidAllowed: true);
    node.variable.initializer = initializerResult.expression
      ..parent = node.variable;
    ExpressionInferenceResult bodyResult =
        inferExpression(node.body, typeContext, isVoidAllowed: true);
    node.body = bodyResult.expression..parent = node;
    DartType inferredType = bodyResult.inferredType;
    return new ExpressionInferenceResult(inferredType, node);
  }

  ExpressionInferenceResult visitPropertySet(
      PropertySet node, DartType typeContext) {
    ExpressionInferenceResult receiverResult = inferNullAwareExpression(
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    ObjectAccessTarget target = findInterfaceMember(
        receiverType, node.name, node.fileOffset,
        isSetter: true, instrumented: true, includeExtensionMethods: true);
    if (target.isInstanceMember || target.isObjectMember) {
      if (instrumentation != null && receiverType == const DynamicType()) {
        instrumentation!.record(uriForInstrumentation, node.fileOffset,
            'target', new InstrumentationValueForMember(target.member!));
      }
    }
    DartType writeContext = target.getSetterType(this);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    DartType rhsType = rhsResult.inferredType;

    ExpressionInferenceResult replacementResult = _computePropertySet(
        node.fileOffset, receiver, receiverType, node.name, target, rhs,
        valueType: rhsType, forEffect: node.forEffect);
    Expression replacement = replacementResult.expression;
    DartType replacementType = replacementResult.inferredType;

    return createNullAwareExpressionInferenceResult(
        replacementType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult visitAugmentSuperSet(
      AugmentSuperSet node, DartType typeContext) {
    Member member = node.target;
    if (member.isInstanceMember) {
      Expression receiver = new ThisExpression()..fileOffset = node.fileOffset;
      DartType receiverType = thisType!;

      ObjectAccessTarget target = new ObjectAccessTarget.interfaceMember(
          thisType!, member,
          hasNonObjectMemberAccess: true);
      if (target.isInstanceMember || target.isObjectMember) {
        if (instrumentation != null && receiverType == const DynamicType()) {
          instrumentation!.record(uriForInstrumentation, node.fileOffset,
              'target', new InstrumentationValueForMember(target.member!));
        }
      }
      DartType writeContext = target.getSetterType(this);
      ExpressionInferenceResult rhsResult =
          inferExpression(node.value, writeContext, isVoidAllowed: true);
      rhsResult = ensureAssignableResult(writeContext, rhsResult,
          fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
      Expression rhs = rhsResult.expression;
      DartType rhsType = rhsResult.inferredType;

      ExpressionInferenceResult replacementResult = _computePropertySet(
          node.fileOffset, receiver, receiverType, member.name, target, rhs,
          valueType: rhsType, forEffect: node.forEffect);
      Expression replacement = replacementResult.expression;
      DartType replacementType = replacementResult.inferredType;

      return new ExpressionInferenceResult(replacementType, replacement);
    } else {
      // TODO(johnniwinther): Handle augmentation of field with inferred types.
      TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
      DartType writeContext = member.setterType;
      ExpressionInferenceResult rhsResult =
          inferExpression(node.value, writeContext, isVoidAllowed: true);
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
        node.receiver, const UnknownType(),
        isVoidAllowed: false);

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
        isSetter: true, includeExtensionMethods: true);

    DartType valueType = writeTarget.getSetterType(this);

    ExpressionInferenceResult valueResult =
        inferExpression(node.value, valueType, isVoidAllowed: true);
    valueResult = ensureAssignableResult(valueType, valueResult);
    Expression value = valueResult.expression;

    ExpressionInferenceResult writeResult = _computePropertySet(
        node.writeOffset,
        writeReceiver,
        nonNullReceiverType,
        node.name,
        writeTarget,
        value,
        valueType: valueResult.inferredType,
        forEffect: node.forEffect);
    Expression write = writeResult.expression;

    flowAnalysis.ifNullExpression_end();

    DartType nonNullableReadType = readType.toNonNull();
    DartType inferredType = _analyzeIfNullTypes(
        nonNullableReadType: nonNullableReadType,
        rhsType: valueResult.inferredType,
        typeContext: typeContext);

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
          createEqualsNull(read, fileOffset: node.readOffset);
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
          createEqualsNull(read, fileOffset: receiverVariable.fileOffset);
      VariableGet variableGet = createVariableGet(readVariable!);
      if (isNonNullableByDefault && !identical(nonNullableReadType, readType)) {
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
    ExpressionInferenceResult receiverResult =
        inferNullAwareExpression(node.receiver, const UnknownType());

    Link<NullAwareGuard> nullAwareGuards = receiverResult.nullAwareGuards;
    Expression receiver = receiverResult.nullAwareAction;
    DartType receiverType = receiverResult.nullAwareActionType;

    node.receiver = receiver..parent = node;

    PropertyGetInferenceResult propertyGetInferenceResult = _computePropertyGet(
        node.fileOffset, receiver, receiverType, node.name, typeContext,
        isThisReceiver: node.receiver is ThisExpression, propertyGetNode: node);
    ExpressionInferenceResult readResult =
        propertyGetInferenceResult.expressionInferenceResult;
    ExpressionInferenceResult expressionInferenceResult =
        createNullAwareExpressionInferenceResult(
            readResult.inferredType, readResult.expression, nullAwareGuards);
    flowAnalysis.forwardExpression(
        expressionInferenceResult.nullAwareAction, node);
    return expressionInferenceResult;
  }

  @override
  ExpressionInferenceResult visitRecordIndexGet(
      RecordIndexGet node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferNullAwareExpression(node.receiver, const UnknownType());

    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;

    node.receiver = receiver..parent = node;

    if (receiverType is RecordType) {
      if (node.index < receiverType.positional.length) {
        DartType resultType = receiverType.positional[node.index];
        return createNullAwareExpressionInferenceResult(
            resultType, node, nullAwareGuards);
      } else {
        return wrapExpressionInferenceResultInProblem(
            createNullAwareExpressionInferenceResult(
                const InvalidType(), node, nullAwareGuards),
            templateIndexOutOfBoundInRecordIndexGet.withArguments(
                node.index,
                receiverType.positional.length,
                receiverType,
                isNonNullableByDefault),
            node.fileOffset,
            noLength);
      }
    } else {
      return wrapExpressionInferenceResultInProblem(
          createNullAwareExpressionInferenceResult(
              const InvalidType(), node, nullAwareGuards),
          templateInternalProblemUnsupported.withArguments("RecordIndexGet"),
          node.fileOffset,
          noLength);
    }
  }

  @override
  ExpressionInferenceResult visitRecordNameGet(
      RecordNameGet node, DartType typeContext) {
    ExpressionInferenceResult result =
        inferNullAwareExpression(node.receiver, const UnknownType());

    Link<NullAwareGuard> nullAwareGuards = result.nullAwareGuards;
    Expression receiver = result.nullAwareAction;
    DartType receiverType = result.nullAwareActionType;

    node.receiver = receiver..parent = node;

    if (receiverType is RecordType) {
      DartType? resultType;
      for (NamedType namedType in receiverType.named) {
        if (namedType.name == node.name) {
          resultType = namedType.type;
          break;
        }
      }
      if (resultType != null) {
        return createNullAwareExpressionInferenceResult(
            resultType, node, nullAwareGuards);
      } else {
        return wrapExpressionInferenceResultInProblem(
            createNullAwareExpressionInferenceResult(
                const InvalidType(), node, nullAwareGuards),
            templateNameNotFoundInRecordNameGet.withArguments(
                node.name, receiverType, isNonNullableByDefault),
            node.fileOffset,
            noLength);
      }
    } else {
      return wrapExpressionInferenceResultInProblem(
          createNullAwareExpressionInferenceResult(
              const InvalidType(), node, nullAwareGuards),
          templateInternalProblemUnsupported.withArguments("RecordIndexGet"),
          node.fileOffset,
          noLength);
    }
  }

  ExpressionInferenceResult visitAugmentSuperGet(
      AugmentSuperGet node, DartType typeContext) {
    Member member = node.target;
    if (member.isInstanceMember) {
      ObjectAccessTarget target = new ObjectAccessTarget.interfaceMember(
          thisType!, member,
          hasNonObjectMemberAccess: true);
      Expression receiver = new ThisExpression()..fileOffset = node.fileOffset;
      DartType receiverType = thisType!;

      PropertyGetInferenceResult propertyGetInferenceResult =
          _computePropertyGet(
              node.fileOffset, receiver, receiverType, member.name, typeContext,
              isThisReceiver: true, readTarget: target, propertyGetNode: node);
      ExpressionInferenceResult readResult =
          propertyGetInferenceResult.expressionInferenceResult;
      return new ExpressionInferenceResult(
          readResult.inferredType, readResult.expression);
    } else {
      // TODO(johnniwinther): Handle augmentation of field with inferred types.
      TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
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
    ensureMemberType(node.target);
    List<TypeParameter> classTypeParameters =
        node.target.enclosingClass.typeParameters;
    List<DartType> typeArguments = new List<DartType>.generate(
        classTypeParameters.length,
        (int i) => new TypeParameterType.withDefaultNullabilityForLibrary(
            classTypeParameters[i], libraryBuilder.library),
        growable: false);
    // The redirecting initializer syntax doesn't include type arguments passed
    // to the target constructor but we need to add them to the arguments before
    // calling [inferInvocation]. These are removed again afterwards.
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

  InitializerInferenceResult visitExtensionTypeRedirectingInitializer(
      ExtensionTypeRedirectingInitializer node) {
    ensureMemberType(node.target);
    List<TypeParameter> constructorTypeParameters =
        constructorDeclaration!.function.typeParameters;
    List<DartType> typeArguments = new List<DartType>.generate(
        constructorTypeParameters.length,
        (int i) => new TypeParameterType.withDefaultNullabilityForLibrary(
            constructorTypeParameters[i], libraryBuilder.library),
        growable: false);
    // The redirecting initializer syntax doesn't include type arguments passed
    // to the target constructor but we need to add them to the arguments before
    // calling [inferInvocation].
    //
    // Unlike in [visitRedirectingInitializer] we leave in the type arguments
    // for the call to the target, since these are needed for the static
    // invocation of the lowering.
    ArgumentsImpl.setNonInferrableArgumentTypes(
        node.arguments as ArgumentsImpl, typeArguments);
    FunctionType functionType = node.target.function
        .computeThisFunctionType(libraryBuilder.nonNullable);
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

  InitializerInferenceResult visitExtensionTypeRepresentationFieldInitializer(
      ExtensionTypeRepresentationFieldInitializer node) {
    DartType fieldType = node.field.getterType;
    fieldType = constructorDeclaration!.substituteFieldType(fieldType);
    ExpressionInferenceResult initializerResult =
        inferExpression(node.value, fieldType);
    Expression initializer = ensureAssignableResult(
            fieldType, initializerResult,
            fileOffset: node.fileOffset)
        .expression;
    node.value = initializer..parent = node;
    return const SuccessfulInitializerInferenceResult();
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
      ExpressionInferenceResult expressionResult =
          inferExpression(node.expression!, typeContext, isVoidAllowed: true);
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
          setType, typeParametersToInfer, typeContext,
          isNonNullableByDefault: isNonNullableByDefault,
          isConst: node.isConst,
          typeOperations: operations,
          inferenceResultForTesting: dataForTesting?.typeInferenceResult,
          treeNodeForTesting: node);
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
          gatherer, typeParametersToInfer, null,
          isNonNullableByDefault: isNonNullableByDefault);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = node.typeArgument;
    }
    for (int index = 0; index < node.expressions.length; ++index) {
      ExpressionInferenceResult result = inferElement(node.expressions[index],
          inferredTypeArgument, inferredSpreadTypes, inferredConditionTypes);
      node.expressions[index] = result.expression..parent = node;
      actualTypes.add(result.inferredType);
      if (inferenceNeeded) {
        formalTypes.add(setType.typeArguments[0]);
      }
    }

    if (inferenceNeeded) {
      gatherer!.constrainArguments(formalTypes, actualTypes,
          treeNodeForTesting: node);
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
          gatherer, typeParametersToInfer, inferredTypes!,
          isNonNullableByDefault: isNonNullableByDefault);
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
    for (int i = 0; i < node.expressions.length; i++) {
      checkElement(node.expressions[i], node, node.typeArgument,
          inferredSpreadTypes, inferredConditionTypes);
    }
    DartType inferredType = new InterfaceType(
        setClass, libraryBuilder.nonNullable, [inferredTypeArgument]);
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
    VariableDeclaration setVar = new VariableDeclaration.forValue(
        new StaticInvocation(
            engine.setFactory, new Arguments([], types: [node.typeArgument])),
        type: receiverType = new InterfaceType(coreTypes.setClass,
            libraryBuilder.nonNullable, [node.typeArgument]));

    // Now create a list of all statements needed.
    List<Statement> statements = [setVar];
    for (int i = 0; i < node.expressions.length; i++) {
      Expression entry = node.expressions[i];
      DartType functionType = Substitution.fromInterfaceType(receiverType)
          .substituteType(engine.setAddMethodFunctionType);
      if (!isNonNullableByDefault) {
        functionType = legacyErasure(functionType);
      }
      Expression methodInvocation = new InstanceInvocation(
          InstanceAccessKind.Instance,
          new VariableGet(setVar),
          new Name("add"),
          new Arguments([entry]),
          functionType: functionType as FunctionType,
          interfaceTarget: engine.setAddMethod)
        ..fileOffset = entry.fileOffset
        ..isInvariant = true;
      statements.add(new ExpressionStatement(methodInvocation)
        ..fileOffset = methodInvocation.fileOffset);
    }

    // Finally, return a BlockExpression with the statements, having the value
    // of the (now created) set.
    return new BlockExpression(new Block(statements), new VariableGet(setVar))
      ..fileOffset = node.fileOffset;
  }

  @override
  ExpressionInferenceResult visitStaticSet(
      StaticSet node, DartType typeContext) {
    Member writeMember = node.target;
    TypeInferenceEngine.resolveInferenceNode(writeMember, hierarchyBuilder);
    DartType writeContext = writeMember.setterType;
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, isVoidAllowed: true);
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
    TypeInferenceEngine.resolveInferenceNode(target, hierarchyBuilder);
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
    FunctionType calleeType =
        node.target.function.computeFunctionType(libraryBuilder.nonNullable);
    TypeArgumentsInfo typeArgumentsInfo = getTypeArgumentsInfo(node.arguments);
    InvocationInferenceResult result = inferInvocation(this, typeContext,
        node.fileOffset, calleeType, node.arguments as ArgumentsImpl,
        staticTarget: node.target);
    libraryBuilder.checkBoundsInStaticInvocation(
        node, typeSchemaEnvironment, helper.uri, typeArgumentsInfo);
    return new ExpressionInferenceResult(
        result.inferredType, result.applyResult(node));
  }

  @override
  ExpressionInferenceResult visitStringConcatenation(
      StringConcatenation node, DartType typeContext) {
    for (int index = 0; index < node.expressions.length; index++) {
      ExpressionInferenceResult result = inferExpression(
          node.expressions[index], const UnknownType(),
          isVoidAllowed: false);
      node.expressions[index] = result.expression..parent = node;
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
    ensureMemberType(node.target);

    Supertype asSuperClass = hierarchyBuilder.getClassAsInstanceOf(
        thisType!.classNode, node.target.enclosingClass)!;

    FunctionType targetType = node.target.function
        .computeThisFunctionType(libraryBuilder.nonNullable);

    FunctionType instantiatedTargetType = FunctionTypeInstantiator.instantiate(
        targetType, asSuperClass.typeArguments);

    FunctionType functionType =
        replaceReturnType(instantiatedTargetType, thisType!);

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
    ObjectAccessTarget writeTarget = new ObjectAccessTarget.interfaceMember(
        thisType!, node.interfaceTarget,
        hasNonObjectMemberAccess: true);
    DartType writeContext = writeTarget.getSetterType(this);
    writeContext = computeTypeFromSuperClass(
        node.interfaceTarget.enclosingClass!, writeContext);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    node.value = rhs..parent = node;
    return new ExpressionInferenceResult(rhsResult.inferredType, node);
  }

  @override
  ExpressionInferenceResult visitSuperPropertySet(
      SuperPropertySet node, DartType typeContext) {
    ObjectAccessTarget writeTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(
            thisType!, node.interfaceTarget,
            hasNonObjectMemberAccess: true)
        : new ObjectAccessTarget.superMember(thisType!, node.interfaceTarget);
    DartType writeContext = writeTarget.getSetterType(this);
    writeContext = computeTypeFromSuperClass(
        node.interfaceTarget.enclosingClass!, writeContext);
    ExpressionInferenceResult rhsResult =
        inferExpression(node.value, writeContext, isVoidAllowed: true);
    rhsResult = ensureAssignableResult(writeContext, rhsResult,
        fileOffset: node.fileOffset, isVoidAllowed: writeContext is VoidType);
    Expression rhs = rhsResult.expression;
    node.value = rhs..parent = node;
    return new ExpressionInferenceResult(rhsResult.inferredType, node);
  }

  @override
  ExpressionInferenceResult visitSwitchExpression(
      SwitchExpression node, DartType typeContext) {
    Set<Field?>? previousEnumFields = _enumFields;

    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    SwitchExpressionResult<DartType, InvalidExpression> analysisResult =
        analyzeSwitchExpression(
            node, node.expression, node.cases.length, typeContext);
    DartType valueType = analysisResult.type;
    node.staticType = valueType;

    assert(checkStack(node, stackBase, [
      /* scrutineeType = */ ValueKinds.DartType,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    DartType scrutineeType = popRewrite() as DartType;
    node.expressionType = scrutineeType;

    assert(checkStack(node, stackBase, [
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (rewrite != null && !identical(node.expression, rewrite)) {
      node.expression = rewrite as Expression..parent = node;
    }

    for (int caseIndex = 0; caseIndex < node.cases.length; caseIndex++) {
      SwitchExpressionCase switchCase = node.cases[caseIndex];
      PatternGuard patternGuard = switchCase.patternGuard;

      InvalidExpression? guardError =
          analysisResult.nonBooleanGuardErrors?[caseIndex];
      if (guardError != null) {
        patternGuard.guard = guardError..parent = patternGuard;
      } else if (patternGuard.guard != null) {
        if (analysisResult.guardTypes![caseIndex] is DynamicType) {
          patternGuard.guard = _createImplicitAs(patternGuard.guard!.fileOffset,
              patternGuard.guard!, coreTypes.boolNonNullableRawType)
            ..parent = patternGuard;
        }
      }
    }

    _enumFields = previousEnumFields;

    assert(checkStack(node, stackBase, [/*empty*/]));

    return new ExpressionInferenceResult(valueType, node);
  }

  @override
  StatementInferenceResult visitSwitchStatement(SwitchStatement node) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    Set<Field?>? previousEnumFields = _enumFields;
    Expression expression = node.expression;
    SwitchStatementTypeAnalysisResult<DartType, InvalidExpression>
        analysisResult =
        analyzeSwitchStatement(node, expression, node.cases.length);

    node.expressionType = analysisResult.scrutineeType;

    assert(checkStack(node, stackBase, [
      /* cases = */ ...repeatedKind(ValueKinds.SwitchCase, node.cases.length),
      /* scrutinee type = */ ValueKinds.DartType,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    for (int i = node.cases.length - 1; i >= 0; i--) {
      popRewrite(); // StatementCase
    }

    // Note that a switch statement with a `default` clause is always considered
    // exhaustive, but the kernel format also keeps track of whether the switch
    // statement is "explicitly exhaustive", meaning that it has a `case` clause
    // for every possible enum value.  It is only necessary to set this flag if
    // the switch doesn't have a `default` clause.
    if (!analysisResult.hasDefault) {
      node.isExplicitlyExhaustive = analysisResult.isExhaustive;
    }
    _enumFields = previousEnumFields;

    assert(checkStack(node, stackBase, [
      /* scrutineeType = */ ValueKinds.DartType,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    popRewrite(); // Scrutinee type.

    assert(checkStack(node, stackBase, [
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(expression, rewrite)) {
      expression = rewrite as Expression;
      node.expression = expression..parent = node;
    }

    Statement? replacement;
    if (analysisResult.isExhaustive &&
        !analysisResult.hasDefault &&
        shouldThrowUnsoundnessException) {
      if (!analysisResult.lastCaseTerminates) {
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
              node.fileOffset, messageNeverReachableSwitchDefaultError)),
          isDefault: true)
        ..fileOffset = node.fileOffset
        ..parent = node);
    }

    assert(checkStack(node, stackBase, [/*empty*/]));

    return replacement != null
        ? new StatementInferenceResult.single(replacement)
        : const StatementInferenceResult();
  }

  @override
  StatementInferenceResult visitPatternSwitchStatement(
      PatternSwitchStatement node) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    SwitchStatementTypeAnalysisResult<DartType, InvalidExpression>
        analysisResult =
        analyzeSwitchStatement(node, node.expression, node.cases.length);

    node.lastCaseTerminates = analysisResult.lastCaseTerminates;

    assert(checkStack(node, stackBase, [
      /* cases = */ ...repeatedKind(ValueKinds.SwitchCase, node.cases.length),
      /* scrutinee type = */ ValueKinds.DartType,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    node.expressionType = analysisResult.scrutineeType;
    for (int i = node.cases.length - 1; i >= 0; i--) {
      Object? rewrite = popRewrite();
      if (!identical(rewrite, node.cases[i])) {
        node.cases[i] = (rewrite as PatternSwitchCase)..parent = node;
      }
    }

    assert(checkStack(node, stackBase, [
      /* scrutinee type = */ ValueKinds.DartType,
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    popRewrite(); // Scrutinee type.

    assert(checkStack(node, stackBase, [
      /* scrutinee = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(node.expression, rewrite)) {
      node.expression = rewrite as Expression..parent = node;
    }

    for (int caseIndex = 0; caseIndex < node.cases.length; caseIndex++) {
      PatternSwitchCase switchCase = node.cases[caseIndex];
      List<VariableDeclaration> jointVariablesNotInAll = [];
      for (int headIndex = 0;
          headIndex < switchCase.patternGuards.length;
          headIndex++) {
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
                coreTypes.boolNonNullableRawType)
              ..parent = patternGuard;
          }
        }

        Map<String, DartType> inferredVariableTypes = {
          for (VariableDeclaration variable in pattern.declaredVariables)
            variable.name!: variable.type
        };
        if (headIndex == 0) {
          for (VariableDeclaration jointVariable in switchCase.jointVariables) {
            DartType? inferredType = inferredVariableTypes[jointVariable.name!];
            if (inferredType != null) {
              jointVariable.type = inferredType;
            } else {
              jointVariable.type = const InvalidType();
              jointVariablesNotInAll.add(jointVariable);
            }
          }
        } else {
          for (int i = 0; i < switchCase.jointVariables.length; ++i) {
            VariableDeclaration jointVariable = switchCase.jointVariables[i];
            // The error on joint variables not present in all case heads is
            // reported in BodyBuilder.
            DartType? inferredType = inferredVariableTypes[jointVariable.name!];
            if (!jointVariablesNotInAll.contains(jointVariable) &&
                inferredType != null &&
                jointVariable.type != inferredType) {
              jointVariable.initializer = helper.buildProblem(
                  templateJointPatternVariablesMismatch
                      .withArguments(jointVariable.name!),
                  switchCase.jointVariableFirstUseOffsets?[i] ??
                      jointVariable.fileOffset,
                  noLength)
                ..parent = jointVariable;
            }
          }
        }
      }
    }

    return const StatementInferenceResult();
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
    flowAnalysis.thisOrSuper(node, thisType!, isSuper: false);
    return new ExpressionInferenceResult(thisType!, node);
  }

  @override
  ExpressionInferenceResult visitThrow(Throw node, DartType typeContext) {
    ExpressionInferenceResult expressionResult = inferExpression(
        node.expression, const UnknownType(),
        isVoidAllowed: false);
    node.expression = expressionResult.expression..parent = node;
    flowAnalysis.handleExit();
    if (isNonNullableByDefault) {
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
    if (isNonNullableByDefault &&
        expressionResult.inferredType.isPotentiallyNullable) {
      node.expression =
          new AsExpression(node.expression, coreTypes.objectNonNullableRawType)
            ..isTypeError = true
            ..isForNonNullableByDefault = true
            ..fileOffset = node.expression.fileOffset
            ..parent = node;
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
    _inTryOrLocalFunction = oldInTryOrLocalFunction;
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
        node.value, promotedType ?? declaredOrInferredType,
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
    if (isNonNullableByDefault) {
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
    if (node.initializer != null) {
      if (node.isLate && node.hasDeclaredInitializer) {
        flowAnalysis.lateInitializer_begin(node);
      }
      initializerResult =
          inferExpression(node.initializer!, declaredType, isVoidAllowed: true);
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
    flowAnalysis.declare(node, node.type,
        initialized: node.hasDeclaredInitializer);
    if (initializerResult != null) {
      DartType initializerType = initializerResult.inferredType;
      flowAnalysis.initialize(
          node, initializerType, initializerResult.expression,
          isFinal: node.isFinal,
          isLate: node.isLate,
          isImplicitlyTyped: node.isImplicitlyTyped);
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

      Expression createVariableRead({bool needsPromotion = false}) {
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
  StatementInferenceResult visitPatternVariableDeclaration(
      PatternVariableDeclaration node) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternVariableDeclarationAnalysisResult<DartType, DartType>
        analysisResult = analyzePatternVariableDeclaration(
            node, node.pattern, node.initializer,
            isFinal: node.isFinal);
    node.matchedValueType = analysisResult.initializerType;

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
      /* initializer = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.pattern)) {
      node.pattern = rewrite as Pattern..parent = node;
    }

    assert(checkStack(node, stackBase, [
      /* initializer = */ ValueKinds.Expression,
    ]));

    rewrite = popRewrite();
    if (!identical(node.initializer, rewrite)) {
      node.initializer = rewrite as Expression..parent = node;
    }

    return const StatementInferenceResult();
  }

  @override
  ExpressionInferenceResult visitVariableGet(
      VariableGet node, DartType typeContext) {
    if (node is! VariableGetImpl) {
      // This node is created as part of a lowering and doesn't need inference.
      return new ExpressionInferenceResult(
          node.promotedType ?? node.variable.type, node);
    }
    VariableDeclarationImpl variable = node.variable as VariableDeclarationImpl;
    DartType? promotedType;
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    if (isExtensionThis(variable)) {
      flowAnalysis.thisOrSuper(node, variable.type, isSuper: true);
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

    return new ExpressionInferenceResult(resultType, resultExpression);
  }

  @override
  StatementInferenceResult visitWhileStatement(WhileStatement node) {
    flowAnalysis.whileStatement_conditionBegin(node);
    InterfaceType expectedType =
        coreTypes.boolRawType(libraryBuilder.nonNullable);
    ExpressionInferenceResult conditionResult =
        inferExpression(node.condition, expectedType, isVoidAllowed: false);
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
    expressionResult =
        inferExpression(node.expression, typeContext, isVoidAllowed: true);
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
        inferExpression(node.left, const UnknownType());
    return _computeEqualsExpression(node.fileOffset, leftResult.expression,
        leftResult.inferredType, node.right,
        isNot: node.isNot);
  }

  ExpressionInferenceResult visitBinary(
      BinaryExpression node, DartType typeContext) {
    ExpressionInferenceResult leftResult =
        inferExpression(node.left, const UnknownType());
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
    if (expressionResult == null) {
      expressionResult = inferExpression(node.expression, const UnknownType());
    }
    Map<DartType, NonPromotionReason> Function() whyNotPromoted =
        flowAnalysis.whyNotPromoted(expressionResult.expression);
    return _computeUnaryExpression(node.fileOffset, expressionResult.expression,
        expressionResult.inferredType, node.unaryName, whyNotPromoted);
  }

  ExpressionInferenceResult visitParenthesized(
      ParenthesizedExpression node, DartType typeContext) {
    return inferExpression(node.expression, typeContext, isVoidAllowed: true);
  }

  ExpressionInferenceResult visitInternalRecordLiteral(
      InternalRecordLiteral node, DartType typeContext) {
    List<Expression> positional = node.positional;
    List<NamedExpression> namedUnsorted = node.named;
    List<NamedExpression> named = namedUnsorted;
    Map<String, NamedExpression>? namedElements = node.namedElements;
    List<Object> originalElementOrder = node.originalElementOrder;
    List<VariableDeclaration>? hoistedExpressions;

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
    // ignore: UNUSED_LOCAL_VARIABLE
    List<NamedType> namedTypes;

    if (namedElements == null) {
      positionalTypes = [];
      namedTypes = [];
      for (int index = 0; index < positional.length; index++) {
        Expression expression = positional[index];

        DartType contextType =
            positionalTypeContexts?[index] ?? const UnknownType();
        ExpressionInferenceResult expressionResult =
            inferExpression(expression, contextType);
        if (contextType is! UnknownType) {
          expressionResult = coerceExpressionForAssignment(
                  contextType, expressionResult,
                  treeNodeForTesting: node) ??
              expressionResult;
        }

        positionalTypes.add(
            expressionResult.postCoercionType ?? expressionResult.inferredType);
        positional[index] = expressionResult.expression;
      }
    } else {
      List<String> sortedNames = namedElements.keys.toList()..sort();

      positionalTypes =
          new List<DartType>.filled(positional.length, const UnknownType());
      Map<String, DartType> namedElementTypes = {};

      // Index into [sortedNames] of the named element we expected to find
      // next, for the named elements to be sorted. This also used to detect
      // when all named elements have been seen, even when they are not sorted.
      int nameIndex = sortedNames.length - 1;

      // Index into [positional] of the positional element we find next.
      int positionalIndex = positional.length - 1;

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
      for (int index = originalElementOrder.length - 1; index >= 0; index--) {
        Object element = originalElementOrder[index];
        if (element is NamedExpression) {
          DartType contextType =
              namedTypeContexts?[element.name] ?? const UnknownType();
          ExpressionInferenceResult expressionResult =
              inferExpression(element.value, contextType);
          if (contextType is! UnknownType) {
            expressionResult = coerceExpressionForAssignment(
                    contextType, expressionResult,
                    treeNodeForTesting: node) ??
                expressionResult;
          }
          Expression expression = expressionResult.expression;
          DartType type = expressionResult.postCoercionType ??
              expressionResult.inferredType;
          // TODO(johnniwinther): Should we use [isPureExpression] as is, make
          // it include (simple) literals, or add a new predicate?
          if (needsHoisting && !isPureExpression(expression)) {
            // We hoist the value of the [NamedExpression] into a synthesized
            // variable, and replace the value with a read of the variable.
            VariableDeclaration variable = createVariable(expression, type);
            hoistedExpressions ??= [];
            hoistedExpressions.add(variable);
            element.value = createVariableGet(variable)..parent = element;
          } else {
            element.value = expression..parent = element;
          }
          namedElementTypes[element.name] = type;
          if (!namedNeedsSorting && element.name != sortedNames[nameIndex]) {
            // Named elements are not sorted, so we need to hoist and sort them.
            namedNeedsSorting = true;
            needsHoisting = enableHoisting;
          }
          nameIndex--;
        } else {
          DartType contextType =
              positionalTypeContexts?[positionalIndex] ?? const UnknownType();
          ExpressionInferenceResult expressionResult =
              inferExpression(element as Expression, contextType);
          if (contextType is! UnknownType) {
            expressionResult = coerceExpressionForAssignment(
                    contextType, expressionResult,
                    treeNodeForTesting: node) ??
                expressionResult;
          }
          Expression expression = expressionResult.expression;
          DartType type = expressionResult.postCoercionType ??
              expressionResult.inferredType;
          // TODO(johnniwinther): Should we use [isPureExpression] as is, make
          // it include (simple) literals, or add a new predicate?
          if (needsHoisting && !isPureExpression(expression)) {
            // We hoist the positional element into a synthesized variable, and
            // replace the element in [positional] with a read of the variable.
            VariableDeclaration variable = createVariable(expression, type);
            hoistedExpressions ??= [];
            hoistedExpressions.add(variable);
            positional[positionalIndex] = createVariableGet(variable);
          } else {
            positional[positionalIndex] = expression;
            if (nameIndex >= 0) {
              // We have not seen all named elements yet, so we must hoist the
              // remaining named elements and the preceding positional elements.
              needsHoisting = enableHoisting;
            }
          }
          positionalTypes[positionalIndex] = type;
          positionalIndex--;
        }
      }
      namedTypes =
          new List<NamedType>.generate(sortedNames.length, (int index) {
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
      result = new InvalidExpression(templateExperimentNotEnabledOffByDefault
          .withArguments(ExperimentalFlag.records.name)
          .withoutLocation()
          .problemMessage);
    } else {
      result = new RecordLiteral(
          positional,
          named,
          type = new RecordType(
              positionalTypes, namedTypes, libraryBuilder.nonNullable),
          isConst: node.isConst)
        ..fileOffset = node.fileOffset;
    }
    if (hoistedExpressions != null) {
      for (VariableDeclaration variable in hoistedExpressions) {
        result = createLet(variable, result);
      }
    }
    return new ExpressionInferenceResult(type, result);
  }

  /// Pops the top entry off of [_rewriteStack].
  Object? popRewrite([NullValue? nullValue]) {
    Object entry = _rewriteStack.removeLast();
    if (_debugRewriteStack) {
      assert(_debugPrint('POP ${entry.runtimeType} $entry'));
    }
    if (entry is! NullValue) {
      return entry;
    }
    assert(nullValue == entry,
        "Unexpected null value. Expected ${nullValue}, actual $entry");
    return null;
  }

  /// Pushes an entry onto [_rewriteStack].
  void pushRewrite(Object node) {
    if (_debugRewriteStack) {
      assert(_debugPrint('PUSH ${node.runtimeType} $node'));
    }
    _rewriteStack.add(node);
  }

  /// Helper function used to print information to the console in debug mode.
  /// This method returns `true` so that it can be conveniently called inside of
  /// an `assert` statement.
  bool _debugPrint(String s) {
    print(s);
    return true;
  }

  @override
  ExpressionTypeAnalysisResult<DartType> dispatchExpression(
      Expression node, DartType context) {
    // Normally the CFE performs expression coercion in the process of type
    // inference of the nodes where an assignment is executed. The inference on
    // the pattern-related nodes is driven by the shared analysis, and some of
    // such nodes perform assignments. Here we determine if we're inferring the
    // expressions of one of such nodes, and perform the coercion if needed.
    TreeNode? parent = node.parent;

    // The case of pattern variable declaration. The initializer expression is
    // assigned to the pattern, and so the coercion needs to be performed.
    bool needsCoercion =
        parent is PatternVariableDeclaration && parent.initializer == node;

    // The case of pattern assignment. The expression is assigned to the
    // pattern, and so the coercion needs to be performed.
    needsCoercion = needsCoercion ||
        parent is PatternAssignment && parent.expression == node;

    // The constant expressions in relational patterns are considered to be
    // passed into the corresponding operator, and so the coercion needs to be
    // performed.
    needsCoercion = needsCoercion ||
        parent is RelationalPattern && parent.expression == node;

    ExpressionInferenceResult expressionResult =
        // TODO(johnniwinther): Handle [isVoidAllowed] through
        //  [dispatchExpression].
        inferExpression(node, context, isVoidAllowed: true).stopShorting();

    if (needsCoercion) {
      expressionResult = coerceExpressionForAssignment(
              context, expressionResult,
              treeNodeForTesting: node) ??
          expressionResult;
    }

    pushRewrite(expressionResult.expression);

    // The shared analysis logic uses the convention that the expressions passed
    // to flow analysis are the original (pre-lowered) expressions, whereas the
    // expressions passed to flow analysis by the CFE are the lowered
    // expressions. Since the caller of `dispatchExpression` is the shared
    // analysis logic, we need to use `flow.forwardExpression` let flow analysis
    // know that in future, we'll be referring to the expression using `node`
    // (its pre-lowered form) rather than `expressionResult.expression` (its
    // post-lowered form).
    //
    // TODO(paulberry): eliminate the need for this--see
    // https://github.com/dart-lang/sdk/issues/52189.
    flow.forwardExpression(node, expressionResult.expression);
    return new SimpleTypeAnalysisResult(type: expressionResult.inferredType);
  }

  @override
  void dispatchPattern(SharedMatchContext context, TreeNode node) {
    if (node is Pattern) {
      node.accept1(this, context);
    } else {
      analyzeConstantPattern(context, node, node as Expression);
    }
  }

  @override
  DartType dispatchPatternSchema(Node node) {
    if (node is AndPattern) {
      return analyzeLogicalAndPatternSchema(node.left, node.right);
    } else if (node is AssignedVariablePattern) {
      return analyzeAssignedVariablePatternSchema(node.variable);
    } else if (node is CastPattern) {
      return analyzeCastPatternSchema();
    } else if (node is ConstantPattern) {
      return analyzeConstantPatternSchema();
    } else if (node is ListPattern) {
      return analyzeListPatternSchema(
          elementType: node.typeArgument, elements: node.patterns);
    } else if (node is MapPattern) {
      return analyzeMapPatternSchema(
          typeArguments: node.keyType != null && node.valueType != null
              ? (keyType: node.keyType!, valueType: node.valueType!)
              : null,
          elements: node.entries);
    } else if (node is NamedPattern) {
      return dispatchPatternSchema(node.pattern);
    } else if (node is NullAssertPattern) {
      return analyzeNullCheckOrAssertPatternSchema(node.pattern,
          isAssert: true);
    } else if (node is NullCheckPattern) {
      return analyzeNullCheckOrAssertPatternSchema(node.pattern,
          isAssert: false);
    } else if (node is ObjectPattern) {
      return analyzeObjectPatternSchema(node.requiredType);
    } else if (node is OrPattern) {
      return analyzeLogicalOrPatternSchema(node.left, node.right);
    } else if (node is RecordPattern) {
      return analyzeRecordPatternSchema(
          fields: <RecordPatternField<TreeNode, Pattern>>[
            for (Pattern element in node.patterns)
              if (element is NamedPattern)
                new RecordPatternField<TreeNode, Pattern>(
                    node: element, name: element.name, pattern: element.pattern)
              else
                new RecordPatternField<TreeNode, Pattern>(
                    node: element, name: null, pattern: element)
          ]);
    } else if (node is RelationalPattern) {
      return analyzeRelationalPatternSchema();
    } else if (node is RestPattern) {
      // This pattern can't appear on it's own.
      return const InvalidType();
    } else if (node is VariablePattern) {
      return analyzeDeclaredVariablePatternSchema(node.type);
    } else if (node is WildcardPattern) {
      return analyzeDeclaredVariablePatternSchema(node.type);
    } else if (node is InvalidPattern) {
      return const InvalidType();
    } else {
      return problems.unhandled("${node.runtimeType}", "dispatchPatternSchema",
          node is TreeNode ? node.fileOffset : TreeNode.noOffset, helper.uri);
    }
  }

  @override
  void dispatchStatement(Statement statement) {
    StatementInferenceResult result = inferStatement(statement);
    pushRewrite(result.hasChanged ? result.statement : statement);
  }

  @override
  void finishExpressionCase(Expression node, int caseIndex) {
    SwitchExpressionCase switchExpressionCase =
        (node as SwitchExpression).cases[caseIndex];
    Object? rewrite = popRewrite();
    if (!identical(switchExpressionCase.expression, rewrite)) {
      switchExpressionCase.expression = rewrite as Expression
        ..parent = switchExpressionCase;
    }
  }

  @override
  void handleMergedStatementCase(covariant SwitchStatement node,
      {required int caseIndex, required bool isTerminating}) {
    SwitchCase case_ = node.cases[caseIndex];

    int? stackBase;
    assert(checkStackBase(
        node, stackBase = stackHeight - (1 + case_.caseHeadCount)));

    assert(checkStack(node, stackBase, [
      /* body = */ ValueKinds.Statement,
      /* case heads = */ ...repeatedKind(
          ValueKinds.SwitchCase, case_.caseHeadCount),
    ]));

    Statement body = case_.body;
    Object? rewrite = popRewrite();
    if (!identical(body, rewrite)) {
      body = rewrite as Statement;
      case_.body = body..parent = case_;
    }

    assert(checkStack(node, stackBase, [
      /* case heads = */ ...repeatedKind(
          ValueKinds.SwitchCase, case_.caseHeadCount)
    ]));

    // When patterns are enable, if this is not the last case and it is not
    // terminating, we insert a synthetic break.
    if (libraryBuilder.libraryFeatures.patterns.isEnabled &&
        !isTerminating &&
        caseIndex < node.cases.length - 1) {
      LabeledStatement switchLabel = node.parent as LabeledStatement;
      BreakStatement syntheticBreak = new BreakStatement(switchLabel)
        ..fileOffset = TreeNode.noOffset;
      if (body is Block) {
        body.statements.add(syntheticBreak);
        syntheticBreak.parent = body;
      } else {
        body = new Block([body, syntheticBreak])..fileOffset = body.fileOffset;
        case_.body = body..parent = case_;
      }
    }

    if (node is PatternSwitchStatement) {
      if (case_ is PatternSwitchCase) {
        assert(checkStack(node, stackBase, [
          /* case heads = */ ...repeatedKind(
              ValueKinds.SwitchCase, case_.patternGuards.length)
        ]));

        for (int i = 0; i < case_.patternGuards.length; i++) {
          popRewrite(); // CaseHead
        }
      } else {
        popRewrite(); // CaseHead
      }
    } else {
      if (case_ is SwitchCaseImpl) {
        assert(checkStack(node, stackBase, [
          /* case heads = */ ...repeatedKind(
              ValueKinds.SwitchCase, case_.expressions.length)
        ]));

        for (int i = 0; i < case_.expressions.length; i++) {
          popRewrite(); // CaseHead
        }
      } else {
        popRewrite(); // CaseHead
      }
    }

    assert(checkStack(node, stackBase, [/*empty*/]));

    pushRewrite(case_);

    assert(checkStack(node, stackBase, [/* case = */ ValueKinds.SwitchCase]));
  }

  @override
  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration, DartType>
      get flow => flowAnalysis;

  @override
  SwitchExpressionMemberInfo<TreeNode, Expression, VariableDeclaration>
      getSwitchExpressionMemberInfo(Expression node, int index) {
    SwitchExpressionCase switchExpressionCase =
        (node as SwitchExpression).cases[index];
    Pattern pattern = switchExpressionCase.patternGuard.pattern;
    Map<String, VariableDeclaration> variables = {
      for (VariableDeclaration declaredVariable in pattern.declaredVariables)
        declaredVariable.name!: declaredVariable
    };
    return new SwitchExpressionMemberInfo<TreeNode, Expression,
            VariableDeclaration>(
        head: new CaseHeadOrDefaultInfo<TreeNode, Expression,
                VariableDeclaration>(
            pattern: pattern,
            guard: switchExpressionCase.patternGuard.guard,
            variables: variables),
        expression: switchExpressionCase.expression);
  }

  @override
  SwitchStatementMemberInfo<TreeNode, Statement, Expression,
          VariableDeclaration>
      getSwitchStatementMemberInfo(
          covariant SwitchStatement node, int caseIndex) {
    SwitchCase case_ = node.cases[caseIndex];
    if (case_ is SwitchCaseImpl) {
      return new SwitchStatementMemberInfo(heads: [
        for (Expression expression in case_.expressions)
          new CaseHeadOrDefaultInfo(
            pattern: expression,
            variables: {},
          ),
        if (case_.isDefault)
          new CaseHeadOrDefaultInfo(
            pattern: null,
            variables: {},
          )
      ], body: [
        case_.body
      ], variables: {}, hasLabels: case_.hasLabel);
    } else {
      case_ as PatternSwitchCase;
      return new SwitchStatementMemberInfo(heads: [
        for (PatternGuard patternGuard in case_.patternGuards)
          new CaseHeadOrDefaultInfo(
            pattern: patternGuard.pattern,
            guard: patternGuard.guard,
            variables: {
              for (VariableDeclaration variable
                  in patternGuard.pattern.declaredVariables)
                variable.name!: variable
            },
          ),
        if (case_.isDefault)
          new CaseHeadOrDefaultInfo(
            pattern: null,
            variables: {},
          )
      ], body: [
        case_.body
      ], variables: {
        for (VariableDeclaration jointVariable in case_.jointVariables)
          jointVariable.name!: jointVariable
      }, hasLabels: case_.hasLabel);
    }
  }

  @override
  void handleCaseHead(
      covariant /* SwitchStatement | SwitchExpression */ Object node,
      {required int caseIndex,
      required int subIndex}) {
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

    if (node is SwitchStatement) {
      assert(checkStack(node, stackBase, [
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern or expression = */ unionOfKinds(
            [ValueKinds.Pattern, ValueKinds.Expression]),
      ]));

      Object? guardRewrite = popRewrite(NullValues.Expression);

      assert(checkStack(node, stackBase, [
        /* pattern or expression = */ unionOfKinds(
            [ValueKinds.Pattern, ValueKinds.Expression]),
      ]));

      SwitchCase case_ = node.cases[caseIndex];
      if (case_ is SwitchCaseImpl) {
        Expression expression = case_.expressions[subIndex];
        Object? rewrite = popRewrite();

        assert(checkStack(node, stackBase, [/*empty*/]));

        if (!identical(expression, rewrite)) {
          expression = rewrite as Expression;
          case_.expressions[subIndex] = expression..parent = case_;
        }
        handleConstantPattern(expression);

        pushRewrite(case_);
      } else {
        PatternGuard patternGuard =
            (case_ as PatternSwitchCase).patternGuards[subIndex];
        if (guardRewrite != null &&
            !identical(guardRewrite, patternGuard.guard)) {
          patternGuard.guard = (guardRewrite as Expression)
            ..parent = patternGuard;
        }
        Object? rewrite = popRewrite();
        if (!identical(rewrite, patternGuard.pattern)) {
          patternGuard.pattern = (rewrite as Pattern)..parent = patternGuard;
        }
        if (patternGuard.guard == null) {
          Pattern pattern = patternGuard.pattern;
          if (pattern is ConstantPattern) {
            handleConstantPattern(pattern.expression);
          }
        }

        pushRewrite(case_);
      }
    } else {
      SwitchExpressionCase switchExpressionCase =
          (node as SwitchExpression).cases[caseIndex];
      PatternGuard patternGuard = switchExpressionCase.patternGuard;

      assert(checkStack(node, stackBase, [
        /* guard = */ ValueKinds.ExpressionOrNull,
        /* pattern = */ ValueKinds.Pattern,
      ]));

      Object? guard = popRewrite(NullValues.Expression);
      if (guard != null && !identical(patternGuard.guard, guard)) {
        patternGuard.guard = (guard as Expression)..parent = patternGuard;
      }

      assert(checkStack(node, stackBase, [
        /* pattern = */ ValueKinds.Pattern,
      ]));

      Object? pattern = popRewrite();

      assert(checkStack(node, stackBase, [/*empty*/]));

      if (pattern != null && !identical(patternGuard.pattern, pattern)) {
        patternGuard.pattern = (pattern as Pattern)..parent = patternGuard;
      }
      if (patternGuard.guard == null) {
        Pattern pattern = patternGuard.pattern;
        if (pattern is ConstantPattern) {
          handleConstantPattern(pattern.expression);
        }
      }
    }
  }

  @override
  void handleCase_afterCaseHeads(
      Statement node, int caseIndex, Iterable<VariableDeclaration> variables) {}

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

    assert(checkStack(node, stackBase, [
      /* statement = */ ValueKinds.StatementOrNull,
    ]));
  }

  @override
  void handleNoGuard(TreeNode node, int caseIndex) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    pushRewrite(NullValues.Expression);

    assert(checkStack(node, stackBase, [
      /* expression = */ ValueKinds.ExpressionOrNull,
    ]));
  }

  @override
  void handleSwitchBeforeAlternative(
    TreeNode node, {
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleSwitchScrutinee(DartType type) {
    if ((!options.patternsEnabled) &&
        type is InterfaceType &&
        type.classNode.isEnum) {
      _enumFields = <Field?>{
        ...type.classNode.fields.where((Field field) => field.isEnumElement),
        if (type.isPotentiallyNullable) null
      };
    } else {
      _enumFields = null;
    }

    pushRewrite(type);
  }

  @override
  bool isLegacySwitchExhaustive(TreeNode node, DartType expressionType) {
    Set<Field?>? enumFields = _enumFields;
    return enumFields != null && enumFields.isEmpty;
  }

  @override
  bool isVariablePattern(TreeNode node) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void setVariableType(VariableDeclaration variable, DartType type) {
    variable.type = type;
  }

  @override
  DartType variableTypeFromInitializerType(DartType type) {
    // TODO(paulberry): make a test verifying that we don't need to pass
    // `forSyntheticVariable: true` (and possibly a language issue)
    return inferDeclarationType(type);
  }

  @override
  void checkCleanState() {
    assert(_rewriteStack.isEmpty);
  }

  @override
  void visitVariablePattern(VariablePattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    node.matchedValueType = flow.getMatchedValueType();

    DeclaredVariablePatternResult<DartType, InvalidExpression> analysisResult =
        analyzeDeclaredVariablePattern(
            context, node, node.variable, node.variable.name!, node.type);

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    DartType inferredType = analysisResult.staticType;
    instrumentation?.record(uriForInstrumentation, node.variable.fileOffset,
        'type', new InstrumentationValueForType(inferredType));
    if (node.type == null) {
      node.variable.type = inferredType;
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitWildcardPattern(WildcardPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    WildcardPatternResult<InvalidExpression> analysisResult =
        analyzeWildcardPattern(
            context: context, node: node, declaredType: node.type);

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitConstantPattern(ConstantPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    ConstantPatternResult<DartType, InvalidExpression> analysisResult =
        analyzeConstantPattern(context, node, node.expression);

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    DartType expressionType =
        node.expressionType = analysisResult.expressionType;

    ObjectAccessTarget equalsInvokeTarget = findInterfaceMember(
        expressionType, equalsName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(equalsInvokeTarget.isInstanceMember ||
        equalsInvokeTarget.isObjectMember ||
        equalsInvokeTarget.isNever);

    node.equalsTarget = equalsInvokeTarget.classMember as Procedure;
    node.equalsType = equalsInvokeTarget.getFunctionType(this);

    assert(checkStack(node, stackBase, [
      /* expression = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(node.expression, rewrite)) {
      node.expression = (rewrite as Expression)..parent = node;
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitAndPattern(AndPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    analyzeLogicalAndPattern(context, node, node.left, node.right);

    assert(checkStack(node, stackBase, [
      /* right = */ ValueKinds.Pattern,
      /* left = */ ValueKinds.Pattern,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.right)) {
      node.right = (rewrite as Pattern)..parent = node;
    }

    rewrite = popRewrite();
    if (!identical(rewrite, node.left)) {
      node.left = (rewrite as Pattern)..parent = node;
    }

    pushRewrite(node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitOrPattern(OrPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    LogicalOrPatternResult<InvalidExpression> analysisResult =
        analyzeLogicalOrPattern(context, node, node.left, node.right);

    assert(checkStack(node, stackBase, [
      /* right = */ ValueKinds.Pattern,
      /* left = */ ValueKinds.Pattern,
    ]));

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.right)) {
      node.right = (rewrite as Pattern)..parent = node;
    }

    rewrite = popRewrite();
    if (!identical(rewrite, node.left)) {
      node.left = (rewrite as Pattern)..parent = node;
    }

    Map<String, VariableDeclaration> leftDeclaredVariablesByName = {
      for (VariableDeclaration variable in node.left.declaredVariables)
        variable.name!: variable
    };
    Map<String, VariableDeclaration> jointVariableNames = {
      for (VariableDeclaration variable in node.orPatternJointVariables)
        variable.name!: variable
    };
    for (VariableDeclaration rightVariable in node.right.declaredVariables) {
      String rightVariableName = rightVariable.name!;
      VariableDeclaration? leftVariable =
          leftDeclaredVariablesByName[rightVariableName];
      VariableDeclaration? jointVariable =
          jointVariableNames[rightVariableName];
      if (leftVariable != null && jointVariable != null) {
        if (leftVariable.type != rightVariable.type ||
            leftVariable.isFinal != rightVariable.isFinal) {
          helper.addProblem(
              templateJointPatternVariablesMismatch
                  .withArguments(rightVariableName),
              leftVariable.fileOffset,
              rightVariableName.length);
        } else {
          jointVariable.isFinal = rightVariable.isFinal;
          jointVariable.type = rightVariable.type;
        }
      }
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitCastPattern(CastPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    analyzeCastPattern(
      context: context,
      pattern: node,
      innerPattern: node.pattern,
      requiredType: node.type,
    );

    assert(checkStack(node, stackBase, [
      /* subpattern = */ ValueKinds.Pattern,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.pattern)) {
      node.pattern = (rewrite as Pattern)..parent = node;
    }

    pushRewrite(node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitNullAssertPattern(
      NullAssertPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    NullCheckOrAssertPatternResult<InvalidExpression> analysisResult =
        analyzeNullCheckOrAssertPattern(context, node, node.pattern,
            isAssert: true);

    assert(checkStack(node, stackBase, [
      /* subpattern = */ ValueKinds.Pattern,
    ]));

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.pattern)) {
      node.pattern = (rewrite as Pattern)..parent = node;
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitNullCheckPattern(
      NullCheckPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    analyzeNullCheckOrAssertPattern(context, node, node.pattern,
        isAssert: false);

    assert(checkStack(node, stackBase, [
      /* subpattern = */ ValueKinds.Pattern,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.pattern)) {
      node.pattern = (rewrite as Pattern)..parent = node;
    }

    pushRewrite(node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitListPattern(ListPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DartType matchedValueType =
        node.matchedValueType = flow.getMatchedValueType();

    ListPatternResult<DartType, InvalidExpression> analysisResult =
        analyzeListPattern(context, node,
            elements: node.patterns, elementType: node.typeArgument);

    assert(checkStack(node, stackBase, [
      /* subpatterns = */ ...repeatedKind(
          ValueKinds.Pattern, node.patterns.length)
    ]));

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    for (int i = node.patterns.length - 1; i >= 0; i--) {
      Object? rewrite = popRewrite();
      InvalidExpression? error = analysisResult.duplicateRestPatternErrors?[i];
      if (error != null) {
        node.patterns[i] = new InvalidPattern(error,
            declaredVariables: node.patterns[i].declaredVariables)
          ..fileOffset = error.fileOffset
          ..parent = node;
      } else if (!identical(rewrite, node.patterns[i])) {
        node.patterns[i] = (rewrite as Pattern)..parent = node;
      }
    }

    // TODO(johnniwinther): The required type computed by the type analyzer
    // isn't trivially `List<dynamic>` in all cases. Does that matter for the
    // lowering?
    DartType requiredType = node.requiredType = analysisResult.requiredType;

    node.needsCheck =
        _needsCheck(matchedType: matchedValueType, requiredType: requiredType);

    DartType lookupType;
    if (node.needsCheck) {
      lookupType = node.lookupType = requiredType;
    } else {
      lookupType = node.lookupType = matchedValueType;
    }

    ObjectAccessTarget lengthTarget = findInterfaceMember(
        lookupType, lengthName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(lengthTarget.isInstanceMember);

    DartType lengthType = node.lengthType = lengthTarget.getGetterType(this);
    node.lengthTarget = lengthTarget.classMember!;

    ObjectAccessTarget sublistInvokeTarget = findInterfaceMember(
        lookupType, sublistName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(sublistInvokeTarget.isInstanceMember);

    node.sublistTarget = sublistInvokeTarget.classMember as Procedure;
    node.sublistType = sublistInvokeTarget.getFunctionType(this);

    ObjectAccessTarget minusTarget = findInterfaceMember(
        lengthType, minusName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(minusTarget.isInstanceMember);
    assert(minusTarget.isSpecialCasedBinaryOperator(this));

    node.minusTarget = minusTarget.classMember as Procedure;
    node.minusType = replaceReturnType(
        minusTarget.getFunctionType(this),
        typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
            lengthType, coreTypes.intNonNullableRawType,
            isNonNullableByDefault: isNonNullableByDefault));

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
        lookupType, indexGetName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(indexGetTarget.isInstanceMember);

    node.indexGetTarget = indexGetTarget.classMember as Procedure;
    node.indexGetType = indexGetTarget.getFunctionType(this);

    for (Pattern pattern in node.patterns) {
      if (pattern is RestPattern) {
        node.hasRestPattern = true;
        break;
      }
    }

    if (node.hasRestPattern) {
      ObjectAccessTarget greaterThanOrEqualTarget = findInterfaceMember(
          lengthType, greaterThanOrEqualsName, node.fileOffset,
          includeExtensionMethods: true, isSetter: false);
      assert(greaterThanOrEqualTarget.isInstanceMember);

      node.lengthCheckTarget =
          greaterThanOrEqualTarget.classMember as Procedure;
      node.lengthCheckType = greaterThanOrEqualTarget.getFunctionType(this);
    } else if (node.patterns.isEmpty) {
      ObjectAccessTarget lessThanOrEqualsInvokeTarget = findInterfaceMember(
          lengthType, lessThanOrEqualsName, node.fileOffset,
          includeExtensionMethods: true, isSetter: false);
      assert(lessThanOrEqualsInvokeTarget.isInstanceMember ||
          lessThanOrEqualsInvokeTarget.isObjectMember);

      node.lengthCheckTarget =
          lessThanOrEqualsInvokeTarget.classMember as Procedure;
      node.lengthCheckType = lessThanOrEqualsInvokeTarget.getFunctionType(this);
    } else {
      ObjectAccessTarget equalsInvokeTarget = findInterfaceMember(
          lengthType, equalsName, node.fileOffset,
          includeExtensionMethods: true, isSetter: false);
      assert(equalsInvokeTarget.isInstanceMember ||
          equalsInvokeTarget.isObjectMember);

      node.lengthCheckTarget = equalsInvokeTarget.classMember as Procedure;
      node.lengthCheckType = equalsInvokeTarget.getFunctionType(this);
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  bool _needsCast(
      {required DartType matchedType, required DartType requiredType}) {
    return !typeSchemaEnvironment.isSubtypeOf(
        matchedType, requiredType, SubtypeCheckMode.withNullabilities);
  }

  bool _needsCheck(
      {required DartType matchedType, required DartType requiredType}) {
    // TODO(johnniwinther): Should we use `isSubtypeOf` here instead?
    return !isAssignable(requiredType, matchedType) ||
        matchedType is InvalidType ||
        matchedType is DynamicType;
  }

  @override
  void visitObjectPattern(ObjectPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DartType matchedValueType =
        node.matchedValueType = flow.getMatchedValueType();

    ObjectPatternResult<DartType, InvalidExpression> analysisResult =
        analyzeObjectPattern(context, node,
            fields: <RecordPatternField<TreeNode, Pattern>>[
          for (NamedPattern field in node.fields)
            new RecordPatternField(
                node: field, name: field.name, pattern: field.pattern)
        ]);

    assert(checkStack(node, stackBase, [
      /* subpatterns = */ ...repeatedKind(
          ValueKinds.Pattern, node.fields.length)
    ]));

    node.requiredType = analysisResult.requiredType;

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    for (int i = node.fields.length - 1; i >= 0; i--) {
      NamedPattern field = node.fields[i];
      Object? rewrite = popRewrite();
      InvalidExpression? error =
          analysisResult.duplicateRecordPatternFieldErrors?[i];
      if (error != null) {
        field.pattern = new InvalidPattern(error,
            declaredVariables: field.pattern.declaredVariables)
          ..fileOffset = error.fileOffset
          ..parent = field;
      } else if (!identical(rewrite, field.pattern)) {
        field.pattern = (rewrite as Pattern)..parent = field;
      }
    }

    node.needsCheck = _needsCheck(
        matchedType: matchedValueType, requiredType: node.requiredType);

    if (node.needsCheck) {
      node.lookupType = node.requiredType;
    } else {
      node.lookupType = matchedValueType;
    }

    for (NamedPattern field in node.fields) {
      field.fieldName = new Name(field.name, libraryBuilder.library);

      ObjectAccessTarget fieldTarget = findInterfaceMember(
          node.requiredType, field.fieldName, field.fileOffset,
          includeExtensionMethods: true, isSetter: false);

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
              node.requiredType.nonTypeVariableBound as RecordType;
          field.accessKind = ObjectAccessKind.RecordNamed;
          break;
        case ObjectAccessTargetKind.recordIndexed:
          field.recordType =
              node.requiredType.nonTypeVariableBound as RecordType;
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
          field.pattern = new InvalidPattern(
              createMissingPropertyGet(
                  field.fileOffset, node.requiredType, field.fieldName),
              declaredVariables: field.pattern.declaredVariables)
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
          problems.unsupported(
              'Object field target $fieldTarget', node.fileOffset, helper.uri);
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
          field.accessKind = ObjectAccessKind.Dynamic;
          break;
      }
      if (fieldTarget.isInstanceMember || fieldTarget.isObjectMember) {
        // TODO(johnniwinther): Use [fieldTarget] to compute the checked type.
        Member interfaceMember = fieldTarget.classMember!;
        if (interfaceMember is Procedure) {
          DartType typeToCheck = isNonNullableByDefault
              ? interfaceMember.function
                  .computeFunctionType(libraryBuilder.nonNullable)
              : interfaceMember.function.returnType;
          field.checkReturn =
              InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                  interfaceMember.enclosingTypeDeclaration!, typeToCheck);
        } else if (interfaceMember is Field) {
          field.checkReturn =
              InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                  interfaceMember.enclosingTypeDeclaration!,
                  interfaceMember.type);
        }
      }
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitRestPattern(RestPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    pushRewrite(node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitInvalidPattern(InvalidPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    pushRewrite(node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitRelationalPattern(
      RelationalPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DartType matchedValueType =
        node.matchedValueType = flow.getMatchedValueType();

    RelationalPatternResult<DartType, InvalidExpression> analysisResult =
        analyzeRelationalPattern(context, node, node.expression);

    assert(checkStack(node, stackBase, [
      /* expression = */ ValueKinds.Expression,
    ]));

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.refutablePatternInIrrefutableContextError ??
            analysisResult.operatorReturnTypeNotAssignableToBoolError ??
            analysisResult.argumentTypeNotAssignableError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    Object? rewrite = popRewrite();
    if (!identical(rewrite, node.expression)) {
      node.expression = (rewrite as Expression)..parent = node;
    }

    DartType expressionType = analysisResult.operandType;
    node.expressionType = expressionType;

    Name name;
    switch (node.kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        name = node.name = equalsName;
        break;
      case RelationalPatternKind.lessThan:
        name = node.name = lessThanName;
        break;
      case RelationalPatternKind.lessThanEqual:
        name = node.name = lessThanOrEqualsName;
        break;
      case RelationalPatternKind.greaterThan:
        name = node.name = greaterThanName;
        break;
      case RelationalPatternKind.greaterThanEqual:
        name = node.name = greaterThanOrEqualsName;
        break;
    }
    ObjectAccessTarget invokeTarget = findInterfaceMember(
        matchedValueType, name, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    switch (node.kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        assert(invokeTarget.isInstanceMember ||
            invokeTarget.isObjectMember ||
            invokeTarget.isNever);

        node.functionType = invokeTarget.getFunctionType(this);
        node.accessKind = RelationalAccessKind.Instance;
        node.target = invokeTarget.classMember as Procedure;
        break;
      case RelationalPatternKind.lessThan:
      case RelationalPatternKind.lessThanEqual:
      case RelationalPatternKind.greaterThan:
      case RelationalPatternKind.greaterThanEqual:
        switch (invokeTarget.kind) {
          case ObjectAccessTargetKind.instanceMember:
            node.functionType = invokeTarget.getFunctionType(this);
            node.target = invokeTarget.classMember as Procedure;
            node.accessKind = RelationalAccessKind.Instance;
            break;
          case ObjectAccessTargetKind.nullableInstanceMember:
          case ObjectAccessTargetKind.nullableExtensionMember:
          case ObjectAccessTargetKind.nullableExtensionTypeMember:
          case ObjectAccessTargetKind.missing:
          case ObjectAccessTargetKind.ambiguous:
            replacement ??= new InvalidPattern(
                createMissingMethodInvocation(
                    node.fileOffset, matchedValueType, name,
                    isExpressionInvocation: false),
                declaredVariables: node.declaredVariables)
              ..fileOffset = node.fileOffset;
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
            problems.unsupported('Relational pattern target $invokeTarget',
                node.fileOffset, helper.uri);
          case ObjectAccessTargetKind.extensionMember:
          case ObjectAccessTargetKind.extensionTypeMember:
            node.functionType = invokeTarget.getFunctionType(this);
            node.typeArguments = invokeTarget.receiverTypeArguments;
            node.target = invokeTarget.member as Procedure;
            node.accessKind = RelationalAccessKind.Static;
            break;
          case ObjectAccessTargetKind.dynamic:
            node.accessKind = RelationalAccessKind.Dynamic;
            break;
          case ObjectAccessTargetKind.never:
            node.accessKind = RelationalAccessKind.Never;
            break;
          case ObjectAccessTargetKind.invalid:
            node.accessKind = RelationalAccessKind.Invalid;
            break;
        }
        break;
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitMapPattern(MapPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DartType matchedValueType =
        node.matchedValueType = flow.getMatchedValueType();

    ({DartType keyType, DartType valueType})? typeArguments =
        node.keyType == null && node.valueType == null
            ? null
            : (
                keyType: node.keyType ?? const DynamicType(),
                valueType: node.valueType ?? const DynamicType()
              );
    MapPatternResult<DartType, InvalidExpression> analysisResult =
        analyzeMapPattern(context, node,
            typeArguments: typeArguments, elements: node.entries);

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    error = analysisResult.emptyMapPatternError;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    // TODO(johnniwinther): The required type computed by the type analyzer
    // isn't trivially `Map<dynamic, dynamic>` in all cases. Does that matter
    // for the lowering?
    DartType requiredType = node.requiredType = analysisResult.requiredType;

    node.needsCheck =
        _needsCheck(matchedType: matchedValueType, requiredType: requiredType);

    DartType lookupType;
    if (node.needsCheck) {
      lookupType = node.lookupType = requiredType;
    } else {
      lookupType = node.lookupType = matchedValueType;
    }

    ObjectAccessTarget containsKeyTarget = findInterfaceMember(
        lookupType, containsKeyName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(containsKeyTarget.isInstanceMember);

    node.containsKeyTarget = containsKeyTarget.classMember as Procedure;
    node.containsKeyType = containsKeyTarget.getFunctionType(this);

    ObjectAccessTarget indexGetTarget = findInterfaceMember(
        lookupType, indexGetName, node.fileOffset,
        includeExtensionMethods: true, isSetter: false);
    assert(indexGetTarget.isInstanceMember);

    node.indexGetTarget = indexGetTarget.classMember as Procedure;
    node.indexGetType = indexGetTarget.getFunctionType(this);

    assert(checkStack(node, stackBase, [
      /* entries = */ ...repeatedKind(
          ValueKinds.MapPatternEntry, node.entries.length)
    ]));

    for (int i = node.entries.length - 1; i >= 0; i--) {
      Object? rewrite = popRewrite();
      if (!identical(node.entries[i], rewrite)) {
        node.entries[i] = (rewrite as MapPatternEntry)..parent = node;
      }
    }

    Map<int, InvalidExpression>? restPatternErrors =
        analysisResult.restPatternErrors;
    if (restPatternErrors != null) {
      InvalidExpression? firstError;
      int insertionIndex = 0;
      for (int readIndex = 0; readIndex < node.entries.length; readIndex++) {
        InvalidExpression? error = restPatternErrors[readIndex];
        if (error != null) {
          firstError ??= error;
        } else {
          node.entries[insertionIndex++] = node.entries[readIndex];
        }
      }
      node.entries.length = insertionIndex;
      if (insertionIndex == 0) {
        replacement ??= new InvalidPattern(firstError!,
            declaredVariables: node.declaredVariables)
          ..fileOffset = node.fileOffset;
      }
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitNamedPattern(NamedPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    // TODO(cstefantsova): Implement visitNamedPattern.
    pushRewrite(node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  void visitRecordPattern(RecordPattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DartType matchedValueType =
        node.matchedValueType = flow.getMatchedValueType();

    List<RecordPatternField<TreeNode, Pattern>> fields = [
      for (Pattern fieldPattern in node.patterns)
        new RecordPatternField(
            node: fieldPattern,
            pattern: fieldPattern is NamedPattern
                ? fieldPattern.pattern
                : fieldPattern,
            name: fieldPattern is NamedPattern ? fieldPattern.name : null)
    ];
    RecordPatternResult<DartType, InvalidExpression> analysisResult =
        analyzeRecordPattern(context, node, fields: fields);

    assert(checkStack(node, stackBase, [
      /* fields = */ ...repeatedKind(ValueKinds.Pattern, node.patterns.length)
    ]));

    Pattern? replacement;

    InvalidExpression? error =
        analysisResult.patternTypeMismatchInIrrefutableContextError ??
            analysisResult.duplicateRecordPatternFieldErrors?.values.first;
    if (error != null) {
      replacement =
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    RecordType requiredType =
        node.requiredType = analysisResult.requiredType as RecordType;

    // TODO(johnniwinther): How does `recordType` relate to `node.recordType`?
    node.needsCheck =
        _needsCheck(matchedType: matchedValueType, requiredType: requiredType);
    if (node.needsCheck) {
      node.lookupType = requiredType;
    } else {
      DartType resolvedType = matchedValueType.nonTypeVariableBound;
      if (resolvedType is RecordType) {
        node.lookupType = resolvedType;
      } else {
        // In case of the matched type being an invalid type we use the
        // required type instead.
        node.lookupType = requiredType;
      }
    }

    for (int i = node.patterns.length - 1; i >= 0; i--) {
      Pattern subPattern = node.patterns[i];
      Object? rewrite = popRewrite();
      if (subPattern is NamedPattern) {
        if (!identical(rewrite, subPattern.pattern)) {
          subPattern.pattern = (rewrite as Pattern)..parent = subPattern;
        }
      } else {
        if (!identical(rewrite, subPattern)) {
          node.patterns[i] = (rewrite as Pattern)..parent = node;
        }
      }
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  @override
  ExpressionInferenceResult visitPatternAssignment(
      PatternAssignment node, DartType typeContext) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    PatternAssignmentAnalysisResult<DartType, DartType> analysisResult =
        analyzePatternAssignment(node, node.pattern, node.expression);
    node.matchedValueType = analysisResult.type;

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
      /* expression = */ ValueKinds.Expression,
    ]));

    Object? rewrite = popRewrite();
    if (!identical(node.pattern, rewrite)) {
      node.pattern = rewrite as Pattern..parent = node;
    }

    assert(checkStack(node, stackBase, [
      /* expression = */ ValueKinds.Expression,
    ]));

    rewrite = popRewrite();
    if (!identical(node.expression, rewrite)) {
      node.expression = rewrite as Expression..parent = node;
    }

    assert(checkStack(node, stackBase, [/*empty*/]));

    return new ExpressionInferenceResult(
        analysisResult.resolveShorting(), node);
  }

  @override
  void visitAssignedVariablePattern(
      AssignedVariablePattern node, SharedMatchContext context) {
    int? stackBase;
    assert(checkStackBase(node, stackBase = stackHeight));

    DartType matchedValueType =
        node.matchedValueType = flow.getMatchedValueType();
    node.needsCast = _needsCast(
        matchedType: matchedValueType, requiredType: node.variable.type);
    node.hasObservableEffect = _inTryOrLocalFunction;

    // TODO(johnniwinther): Share this through the type analyzer.
    Pattern? replacement;
    VariableDeclarationImpl variable = node.variable as VariableDeclarationImpl;
    if (isNonNullableByDefault) {
      bool isDefinitelyAssigned = flowAnalysis.isAssigned(variable);
      bool isDefinitelyUnassigned = flowAnalysis.isUnassigned(variable);
      if ((variable.isLate && variable.isFinal) ||
          variable.isLateFinalWithoutInitializer) {
        if (isDefinitelyAssigned) {
          replacement = new InvalidPattern(
              helper.buildProblem(
                  templateLateDefinitelyAssignedError
                      .withArguments(node.variable.name!),
                  node.fileOffset,
                  node.variable.name!.length),
              declaredVariables: node.declaredVariables)
            ..fileOffset = node.fileOffset;
        }
      } else if (variable.isStaticLate) {
        if (!isDefinitelyUnassigned) {
          replacement = new InvalidPattern(
              helper.buildProblem(
                  templateFinalPossiblyAssignedError
                      .withArguments(node.variable.name!),
                  node.fileOffset,
                  node.variable.name!.length),
              declaredVariables: node.declaredVariables)
            ..fileOffset = node.fileOffset;
        }
      } else if (variable.isFinal && variable.hasDeclaredInitializer) {
        replacement = new InvalidPattern(
            helper.buildProblem(
                templateCannotAssignToFinalVariable
                    .withArguments(node.variable.name!),
                node.fileOffset,
                node.variable.name!.length),
            declaredVariables: node.declaredVariables)
          ..fileOffset = node.fileOffset;
      }
    }

    AssignedVariablePatternResult<InvalidExpression> analysisResult =
        analyzeAssignedVariablePattern(context, node, node.variable);

    InvalidExpression? error =
        analysisResult.duplicateAssignmentPatternVariableError ??
            analysisResult.patternTypeMismatchInIrrefutableContextError;
    if (error != null) {
      replacement ??=
          new InvalidPattern(error, declaredVariables: node.declaredVariables)
            ..fileOffset = error.fileOffset;
    }

    pushRewrite(replacement ?? node);

    assert(checkStack(node, stackBase, [
      /* pattern = */ ValueKinds.Pattern,
    ]));
  }

  /// Infers type arguments corresponding to [typeParameters] so that, when
  /// substituted into [declaredType], the resulting type matches [contextType].
  List<DartType> _inferTypeArguments(
      {required List<TypeParameter> typeParameters,
      required DartType declaredType,
      required DartType contextType,
      required TreeNode? treeNodeForTesting}) {
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typeParameters);
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    declaredType = freshTypeParameters.substitute(declaredType);
    TypeConstraintGatherer gatherer =
        typeSchemaEnvironment.setupGenericTypeInference(
            declaredType, typeParametersToInfer, contextType,
            isNonNullableByDefault: isNonNullableByDefault,
            typeOperations: operations,
            inferenceResultForTesting: dataForTesting?.typeInferenceResult,
            treeNodeForTesting: treeNodeForTesting);
    return typeSchemaEnvironment.chooseFinalTypes(
        gatherer, typeParametersToInfer, null,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  @override
  DartType downwardInferObjectPatternRequiredType({
    required DartType matchedType,
    required covariant ObjectPatternInternal pattern,
  }) {
    DartType requiredType = pattern.requiredType;
    if (!pattern.hasExplicitTypeArguments) {
      Typedef? typedef = pattern.typedef;
      if (typedef != null) {
        List<TypeParameter> typedefTypeParameters = typedef.typeParameters;
        if (typedefTypeParameters.isNotEmpty) {
          List<DartType> asTypeArguments =
              getAsTypeArguments(typedefTypeParameters, libraryBuilder.library);
          TypedefType typedefType = new TypedefType(
              typedef, libraryBuilder.library.nonNullable, asTypeArguments);
          DartType unaliasedTypedef = typedefType.unalias;
          List<DartType> inferredTypeArguments = _inferTypeArguments(
              typeParameters: typedefTypeParameters,
              declaredType: unaliasedTypedef,
              contextType: matchedType,
              treeNodeForTesting: pattern);
          requiredType = new TypedefType(typedef,
                  libraryBuilder.library.nonNullable, inferredTypeArguments)
              .unalias;
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
          InterfaceType declaredType = new InterfaceType(requiredType.classNode,
              requiredType.declaredNullability, fresh.freshTypeArguments);
          typeParameters = fresh.freshTypeParameters;

          List<DartType> inferredTypeArguments = _inferTypeArguments(
              typeParameters: typeParameters,
              declaredType: declaredType,
              contextType: matchedType,
              treeNodeForTesting: pattern);
          requiredType = new InterfaceType(requiredType.classNode,
              requiredType.declaredNullability, inferredTypeArguments);
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
              fresh.freshTypeArguments);
          typeParameters = fresh.freshTypeParameters;

          List<DartType> inferredTypeArguments = _inferTypeArguments(
              typeParameters: typeParameters,
              declaredType: declaredType,
              contextType: matchedType,
              treeNodeForTesting: pattern);
          requiredType = new ExtensionType(
              requiredType.extensionTypeDeclaration,
              requiredType.declaredNullability,
              inferredTypeArguments);
        }
      }
    }
    return requiredType;
  }

  @override
  void dispatchCollectionElement(covariant TreeNode element,
      covariant CollectionElementInferenceContext context) {
    if (element is Expression) {
      context as ListAndSetElementInferenceContext;
      ExpressionInferenceResult inferenceResult = inferElement(
          element,
          context.inferredTypeArgument,
          context.inferredSpreadTypes,
          context.inferredConditionTypes);
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
          context.offsets);
      pushRewrite(element);
    } else {
      problems.unsupported(
          "${element.runtimeType}", element.fileOffset, helper.uri);
    }
  }

  @override
  (Member?, DartType) resolveObjectPatternPropertyGet({
    required Pattern objectPattern,
    required DartType receiverType,
    required shared.RecordPatternField<TreeNode, Pattern> field,
  }) {
    String fieldName = field.name!;
    ObjectAccessTarget fieldAccessTarget = findInterfaceMember(receiverType,
        new Name(fieldName, libraryBuilder.library), field.pattern.fileOffset,
        isSetter: false, includeExtensionMethods: true);
    // TODO(johnniwinther): Should we use the `fieldAccessTarget.classMember`
    //  here?
    return (fieldAccessTarget.member, fieldAccessTarget.getGetterType(this));
  }

  @override
  void handleNoCollectionElement(TreeNode element) {
    pushRewrite(NullValues.Expression);
  }

  @override
  void finishJoinedPatternVariable(
    VariableDeclaration variable, {
    required JoinedPatternVariableLocation location,
    required JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required DartType type,
  }) {
    variable
      ..isFinal = isFinal
      ..type = type;
  }

  @override
  bool isRestPatternElement(Node node) {
    return node is RestPattern || node is MapPatternRestEntry;
  }

  @override
  Pattern? getRestPatternElementPattern(TreeNode node) {
    if (node is MapPatternRestEntry) {
      return null;
    } else {
      return (node as RestPattern).subPattern;
    }
  }

  @override
  void handleListPatternRestElement(Pattern container, TreeNode restElement) {
    RestPattern restPattern = restElement as RestPattern;
    int? stackBase;
    if (restPattern.subPattern != null) {
      assert(checkStackBase(restPattern, stackBase = stackHeight - 1));

      assert(checkStack(
          restPattern, stackBase, [/* subpattern = */ ValueKinds.Pattern]));

      Object? rewrite = popRewrite();
      if (!identical(rewrite, restPattern.subPattern)) {
        restPattern.subPattern = (rewrite as Pattern)..parent = restPattern;
      }
    } else {
      assert(checkStackBase(restPattern, stackBase = stackHeight));
    }

    assert(checkStack(restPattern, stackBase, [/*empty*/]));

    pushRewrite(restElement);

    assert(checkStack(
        restPattern, stackBase, [/* rest pattern = */ ValueKinds.Pattern]));
  }

  @override
  void handleMapPatternRestElement(Pattern container, TreeNode restElement) {
    pushRewrite(restElement);
  }

  @override
  shared.MapPatternEntry<Expression, Pattern>? getMapPatternEntry(
      TreeNode element) {
    element as MapPatternEntry;
    if (element is MapPatternRestEntry) {
      return null;
    } else {
      return new shared.MapPatternEntry<Expression, Pattern>(
          key: element.key, value: element.value);
    }
  }

  @override
  void handleMapPatternEntry(Pattern container,
      covariant MapPatternEntry entryElement, DartType keyType) {
    Object? rewrite = popRewrite();
    if (!identical(rewrite, entryElement.value)) {
      entryElement.value = rewrite as Pattern..parent = entryElement;
    }

    rewrite = popRewrite();
    if (!identical(rewrite, entryElement.key)) {
      entryElement.key = (rewrite as Expression)..parent = entryElement;
    }

    entryElement.keyType = keyType;

    pushRewrite(entryElement);
  }

  @override
  RelationalOperatorResolution<DartType>? resolveRelationalPatternOperator(
      covariant RelationalPattern node, DartType matchedValueType) {
    // TODO(johnniwinther): Reuse computed values between here and
    // visitRelationalPattern.
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
        matchedValueType, operatorName, node.fileOffset,
        isSetter: false);

    DartType returnType = binaryTarget.getReturnType(this);
    DartType parameterType = binaryTarget.getBinaryOperandType(this);

    assert(!binaryTarget.isSpecialCasedBinaryOperator(this));

    return new RelationalOperatorResolution(
        kind: kind, parameterType: parameterType, returnType: returnType);
  }

  @override
  ExpressionInferenceResult visitAuxiliaryExpression(
      AuxiliaryExpression node, DartType typeContext) {
    return _unhandledExpression(node, typeContext);
  }

  @override
  InitializerInferenceResult visitAuxiliaryInitializer(
      AuxiliaryInitializer node) {
    if (node is InternalInitializer) {
      return node.acceptInference(this);
    }
    return _unhandledInitializer(node);
  }

  @override
  StatementInferenceResult visitAuxiliaryStatement(AuxiliaryStatement node) {
    return _unhandledStatement(node);
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

extension on SwitchCase {
  int get caseHeadCount {
    int count = 0;
    if (this is PatternSwitchCase) {
      count += (this as PatternSwitchCase).patternGuards.length;
    } else {
      count += this.expressions.length;
    }
    return count;
  }
}

abstract class CollectionElementInferenceContext {
  Map<TreeNode, DartType> inferredSpreadTypes;
  Map<Expression, DartType> inferredConditionTypes;

  CollectionElementInferenceContext(
      {required this.inferredSpreadTypes,
      required this.inferredConditionTypes});
}

class ListAndSetElementInferenceContext
    extends CollectionElementInferenceContext {
  DartType inferredTypeArgument;

  ListAndSetElementInferenceContext(
      {required this.inferredTypeArgument,
      required Map<TreeNode, DartType> inferredSpreadTypes,
      required Map<Expression, DartType> inferredConditionTypes})
      : super(
            inferredSpreadTypes: inferredSpreadTypes,
            inferredConditionTypes: inferredConditionTypes);
}

class MapEntryInferenceContext extends CollectionElementInferenceContext {
  DartType inferredKeyType;
  DartType inferredValueType;
  DartType spreadContext;
  List<DartType> actualTypes;
  List<DartType> actualTypesForSet;
  _MapLiteralEntryOffsets offsets;

  MapEntryInferenceContext(
      {required this.inferredKeyType,
      required this.inferredValueType,
      required this.spreadContext,
      required this.actualTypes,
      required this.actualTypesForSet,
      required this.offsets,
      required Map<TreeNode, DartType> inferredSpreadTypes,
      required Map<Expression, DartType> inferredConditionTypes})
      : super(
            inferredSpreadTypes: inferredSpreadTypes,
            inferredConditionTypes: inferredConditionTypes);
}
