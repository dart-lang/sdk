// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/deferred_function_literal_heuristic.dart';
import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/names.dart';
import 'package:kernel/src/bounds_checks.dart'
    show calculateBounds, isGenericFunctionTypeOrAlias;
import 'package:kernel/src/future_value_type.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../api_prototype/lowering_predicates.dart';
import '../base/compiler_context.dart';
import '../base/extension_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/problems.dart' show internalProblem, unhandled;
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../kernel/assigned_variables_impl.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart' show hasAnyTypeParameters;
import '../source/check_helper.dart';
import '../source/source_library_builder.dart'
    show FieldNonPromotabilityInfo, SourceLibraryBuilder;
import '../source/source_member_builder.dart';
import '../testing/id_extractor.dart';
import '../util/helpers.dart';
import 'closure_context.dart';
import 'context_allocation_strategy.dart';
import 'external_ast_helper.dart';
import 'inference_results.dart';
import 'inference_visitor.dart';
import 'object_access_target.dart';
import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;
import 'type_demotion.dart';
import 'type_inference_engine.dart';
import 'type_inferrer.dart' show TypeInferrerImpl;
import 'type_schema.dart' show isKnown, UnknownType;
import 'type_schema_environment.dart'
    show
        getNamedParameterType,
        getPositionalParameterType,
        AllTypeParameterEliminator,
        TypeSchemaEnvironment;

/// Given a [FunctionExpression], computes a set whose elements consist of (a)
/// an integer corresponding to the zero-based index of each positional
/// parameter of the function expression that has an explicit type annotation,
/// and (b) a string corresponding to the name of each named parameter of the
/// function expression that has an explicit type annotation.
Set<Object> _computeExplicitlyTypedParameterSet(
  FunctionExpression functionExpression,
) {
  Set<Object> result = {};
  int unnamedParameterIndex = 0;
  for (VariableDeclaration positionalParameter
      in functionExpression.function.positionalParameters) {
    int key = unnamedParameterIndex++;
    if (!(positionalParameter as VariableDeclarationImpl).isImplicitlyTyped) {
      result.add(key);
    }
  }
  for (VariableDeclaration namedParameter
      in functionExpression.function.namedParameters) {
    String key = namedParameter.name!;
    if (!(namedParameter as VariableDeclarationImpl).isImplicitlyTyped) {
      result.add(key);
    }
  }
  return result;
}

/// Given an function type, computes a map based on the parameters whose keys
/// are either the parameter name (for named parameters) or the zero-based
/// integer index (for unnamed parameters), and whose values are the parameter
/// types.
Map<Object, DartType> _computeParameterMap(FunctionType functionType) => {
  for (int i = 0; i < functionType.positionalParameters.length; i++)
    i: functionType.positionalParameters[i],
  for (NamedType namedType in functionType.namedParameters)
    namedType.name: namedType.type,
};

/// Enum denoting the kinds of contravariance check that might need to be
/// inserted for a method call.
enum MethodContravarianceCheckKind {
  /// No contravariance check is needed.
  none,

  /// The return value from the method call needs to be checked.
  checkMethodReturn,

  /// The method call needs to be desugared into a getter call, followed by an
  /// "as" check, followed by an invocation of the resulting function object.
  checkGetterReturn,
}

abstract class InferenceVisitorBase implements InferenceVisitor {
  final TypeInferrerImpl _inferrer;

  /// Helper used to issue correct error messages and avoid access to
  /// unavailable variables upon expression evaluation.
  final ExpressionEvaluationHelper? expressionEvaluationHelper;

  final Uri fileUri;

  InferenceVisitorBase(
    this._inferrer,
    this.fileUri,
    this.expressionEvaluationHelper,
  );

  ThisVariable get internalThisVariable;

  // TODO(cstefantsova): Replace this flag by implementing the default
  // strategy.
  bool get isClosureContextLoweringEnabled => _inferrer
      .libraryBuilder
      .loader
      .target
      .backendTarget
      .flags
      .isClosureContextLoweringEnabled;

  AssignedVariablesImpl get assignedVariables => _inferrer.assignedVariables;

  InterfaceType? get thisType => _inferrer.thisType;

  ClassHierarchyBase get hierarchyBuilder => _inferrer.engine.hierarchyBuilder;

  ClassHierarchyMembers get membersBuilder => _inferrer.engine.membersBuilder;

  InferenceDataForTesting? get dataForTesting => _inferrer.dataForTesting;

  FlowAnalysis<TreeNode, Statement, Expression, ExpressionVariable>
  get flowAnalysis => _inferrer.flowAnalysis;

  /// Provides access to the [OperationsCfe] object.  This is needed by
  /// [isAssignable] and for caching types.
  OperationsCfe get cfeOperations => _inferrer.operations;

  TypeSchemaEnvironment get typeSchemaEnvironment =>
      _inferrer.typeSchemaEnvironment;

  TypeInferenceEngine get engine => _inferrer.engine;

  CoreTypes get coreTypes => engine.coreTypes;

  @pragma("vm:prefer-inline")
  SourceLibraryBuilder get libraryBuilder => _inferrer.libraryBuilder;

  @pragma("vm:prefer-inline")
  ProblemReporting get problemReporting => _inferrer.libraryBuilder;

  @pragma("vm:prefer-inline")
  CompilerContext get compilerContext =>
      _inferrer.libraryBuilder.loader.target.context;

  ProblemReportingHelper get problemReportingHelper => libraryBuilder.loader;

  ExtensionScope get extensionScope => _inferrer.extensionScope;

  bool get isInferenceUpdate1Enabled =>
      libraryBuilder.isInferenceUpdate1Enabled;

  LibraryFeatures get libraryFeatures => libraryBuilder.libraryFeatures;

  DartType get bottomType => const NeverType.nonNullable();

  // Coverage-ignore(suite): Not run.
  StaticTypeContext get staticTypeContext => _inferrer.staticTypeContext;

  DartType computeGreatestClosure(DartType type) {
    return cfeOperations.greatestClosureOfSchema(
          new SharedTypeSchemaView(type),
          topType: new SharedTypeView(const DynamicType()),
        )
        as DartType;
  }

  DartType computeGreatestClosure2(DartType type) {
    return cfeOperations.greatestClosureOfSchema(
          new SharedTypeSchemaView(type),
          topType: new SharedTypeView(coreTypes.objectNullableRawType),
        )
        as DartType;
  }

  DartType computeNullable(DartType type) =>
      cfeOperations.makeNullableInternal(type);

  // Coverage-ignore(suite): Not run.
  Expression createReachabilityError(int fileOffset, Message errorMessage) {
    Arguments arguments = new Arguments([
      new StringLiteral(errorMessage.problemMessage)..fileOffset = fileOffset,
    ])..fileOffset = fileOffset;
    return new Throw(
        new ConstructorInvocation(
          coreTypes.reachabilityErrorConstructor,
          arguments,
        )..fileOffset = fileOffset,
      )
      ..fileOffset = fileOffset
      ..forErrorHandling = true;
  }

  /// Computes a list of context messages explaining why [receiver] was not
  /// promoted, to be used when reporting an error for a larger expression
  /// containing [receiver].  [node] is the containing tree node.
  List<LocatedMessage>? getWhyNotPromotedContext(
    Map<SharedTypeView, NonPromotionReason>? whyNotPromoted,
    TreeNode node,
    bool Function(DartType) typeFilter,
  ) {
    List<LocatedMessage>? context;
    if (whyNotPromoted != null && whyNotPromoted.isNotEmpty) {
      _WhyNotPromotedVisitor whyNotPromotedVisitor = new _WhyNotPromotedVisitor(
        this,
      );
      for (MapEntry<SharedTypeView, NonPromotionReason> entry
          in whyNotPromoted.entries) {
        if (!typeFilter(entry.key.unwrapTypeView())) continue;
        List<LocatedMessage> messages = entry.value.accept(
          whyNotPromotedVisitor,
        );
        if (dataForTesting != null) {
          // Coverage-ignore-block(suite): Not run.
          String nonPromotionReasonText = entry.value.shortName;
          List<String> args = <String>[];
          if (whyNotPromotedVisitor.propertyReference != null) {
            Id id = computeMemberId(whyNotPromotedVisitor.propertyReference!);
            args.add('target: $id');
          }
          if (args.isNotEmpty) {
            nonPromotionReasonText += '(${args.join(', ')})';
          }
          TreeNode origNode = node;
          while (origNode is VariableGet &&
              origNode.variable.name == null &&
              origNode.variable.initializer != null) {
            // This is a read of a synthetic variable, presumably from a "let".
            // Find the original expression.
            // TODO(johnniwinther): add a general solution for getting the
            // original node for testing.
            origNode = origNode.variable.initializer!;
          }
          dataForTesting!.flowAnalysisResult.nonPromotionReasons[origNode] =
              nonPromotionReasonText;
        }
        // Note: this will always pick the first viable reason (only).  I
        // (paulberry) believe this is the one that will be the most relevant,
        // but I need to do more testing to validate that.  I can't do that
        // additional testing yet because at the moment we only handle failed
        // promotions to non-nullable.
        // TODO(paulberry): do more testing and then expand on the comment
        // above.
        if (messages.isNotEmpty) {
          context = messages;
        }
        break;
      }
    }
    return context;
  }

  /// Returns `true` if exceptions should be thrown in paths reachable only due
  /// to unsoundness in flow analysis in mixed mode.
  // TODO(johnniwinther): Remove this.
  bool get shouldThrowUnsoundnessException => false;

  void registerIfUnreachableForTesting(TreeNode node, {bool? isReachable}) {
    if (dataForTesting == null) return;
    // Coverage-ignore-block(suite): Not run.
    isReachable ??= flowAnalysis.isReachable;
    if (!isReachable) {
      dataForTesting!.flowAnalysisResult.unreachableNodes.add(node);
    }
  }

  /// Ensures that the type of [member] has been computed.
  void ensureMemberType(Member member) {
    _inferConstructorParameterTypes(member);
    TypeDependency? typeDependency = engine.typeDependencies.remove(member);
    if (typeDependency != null) {
      ensureMemberType(typeDependency.original);
      typeDependency.copyInferred();
    }
  }

  /// Ensures that all parameter types of [constructor] have been inferred.
  void _inferConstructorParameterTypes(Member target) {
    InferableMember? inferableMember = engine.beingInferred[target];
    if (inferableMember != null) {
      inferableMember.reportCyclicDependency();
    } else {
      inferableMember = engine.toBeInferred.remove(target);
      if (inferableMember != null) {
        engine.beingInferred[target] = inferableMember;
        inferableMember.inferMemberTypes(hierarchyBuilder);
        engine.beingInferred.remove(target);
      }
    }
  }

  bool isDoubleContext(DartType typeContext) {
    // A context is a double context if double is assignable to it but int is
    // not.  That is the type context is a double context if it is:
    //   * double
    //   * FutureOr<T> where T is a double context
    //
    // We check directly, rather than using isAssignable because it's simpler.
    while (typeContext is FutureOrType) {
      FutureOrType type = typeContext;
      typeContext = type.typeArgument;
    }
    return typeContext is InterfaceType &&
        typeContext.classReference == coreTypes.doubleClass.reference;
  }

  bool isAssignable(DartType contextType, DartType expressionType) {
    return cfeOperations.isAssignableTo(
      new SharedTypeView(expressionType),
      new SharedTypeView(contextType),
    );
  }

  /// Ensures that [expressionType] is assignable to [contextType].
  ///
  /// Checks whether [expressionType] can be assigned to the greatest closure of
  /// [contextType], and inserts an implicit downcast, inserts a tear-off, or
  /// reports an error if appropriate.
  ///
  /// If [declaredContextType] is provided, this is used instead of
  /// [contextType] for reporting the type against which [expressionType] isn't
  /// assignable. This is used when checking the assignability of return
  /// statements in async functions in which the assignability is checked
  /// against the future value type but the reporting should refer to the
  /// declared return type.
  ///
  /// If [runtimeCheckedType] is provided, this is used for the implicit cast,
  /// otherwise [contextType] is used. This is used for return from async
  /// where the returned expression is wrapped in a `Future`, if necessary,
  /// before returned and therefore shouldn't be checked to be a `Future`
  /// directly.
  Expression ensureAssignable(
    DartType expectedType,
    DartType expressionType,
    Expression expression, {
    int? fileOffset,
    DartType? declaredContextType,
    DartType? runtimeCheckedType,
    bool isVoidAllowed = false,
    bool coerceExpression = true,
    Template<
      Message Function({
        required DartType actualType,
        required DartType expectedType,
      })
    >?
    errorTemplate,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    return ensureAssignableResult(
      expectedType,
      new ExpressionInferenceResult(expressionType, expression),
      fileOffset: fileOffset,
      declaredContextType: declaredContextType,
      runtimeCheckedType: runtimeCheckedType,
      isVoidAllowed: isVoidAllowed,
      coerceExpression: coerceExpression,
      errorTemplate: errorTemplate,
      whyNotPromoted: whyNotPromoted,
    ).expression;
  }

  /// Coerces expression ensuring its assignability to [contextType]
  ///
  /// If the expression is assignable without coercion, [inferenceResult]
  /// is returned unchanged. If no coercion is possible for the given types,
  /// `null` is returned.
  ExpressionInferenceResult? coerceExpressionForAssignment(
    DartType contextType,
    ExpressionInferenceResult inferenceResult, {
    int? fileOffset,
    DartType? declaredContextType,
    DartType? runtimeCheckedType,
    bool isVoidAllowed = false,
    bool coerceExpression = true,
    required TreeNode? treeNodeForTesting,
  }) {
    fileOffset ??= inferenceResult.expression.fileOffset;
    contextType = computeGreatestClosure(contextType);

    DartType initialContextType = runtimeCheckedType ?? contextType;

    Template<
      Message Function({
        required DartType actualType,
        required DartType expectedType,
      })
    >?
    preciseTypeErrorTemplate = _getPreciseTypeErrorTemplate(
      inferenceResult.expression,
    );
    AssignabilityResult assignabilityResult = _computeAssignabilityKind(
      contextType,
      inferenceResult.inferredType,
      isVoidAllowed: isVoidAllowed,
      isExpressionTypePrecise: preciseTypeErrorTemplate != null,
      coerceExpression: coerceExpression,
      fileOffset: fileOffset,
      treeNodeForTesting: treeNodeForTesting,
    );

    if (assignabilityResult.needsTearOff) {
      TypedTearoff typedTearoff = _tearOffCall(
        inferenceResult.expression,
        inferenceResult.inferredType,
        fileOffset,
      );
      inferenceResult = new ExpressionInferenceResult(
        typedTearoff.tearoffType,
        typedTearoff.tearoff,
      );
    }
    if (assignabilityResult.implicitInstantiation != null) {
      inferenceResult = _applyImplicitInstantiation(
        assignabilityResult.implicitInstantiation,
        inferenceResult.inferredType,
        inferenceResult.expression,
      );
    }

    DartType expressionType = inferenceResult.inferredType;
    Expression expression = inferenceResult.expression;
    switch (assignabilityResult.kind) {
      case AssignabilityKind.assignable:
        return inferenceResult;
      case AssignabilityKind.assignableCast:
        // Insert an implicit downcast.
        Expression asExpression =
            new AsExpression(expression, initialContextType)
              ..isTypeError = true
              ..isForDynamic = expressionType is DynamicType
              ..fileOffset = fileOffset;
        flowAnalysis.forwardExpression(asExpression, expression);
        return new ExpressionInferenceResult(
          expressionType,
          asExpression,
          postCoercionType: initialContextType,
        );
      case AssignabilityKind.unassignable:
        // Error: not assignable.  Perform error recovery.
        return null;
      case AssignabilityKind.unassignableVoid:
        // Error: not assignable.  Perform error recovery.
        return null;
      case AssignabilityKind.unassignablePrecise:
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        return null;
      case AssignabilityKind.unassignableCantTearoff:
        return null;
      case AssignabilityKind.unassignableNullability:
        return null;
    }
  }

  /// Performs assignability checks on an expression
  ///
  /// [inferenceResult.expression] of type [inferenceResult.inferredType] is
  /// checked for assignability to [contextType]. The errors are reported on the
  /// current library and the expression wrapped in an [InvalidExpression], if
  /// needed. If no change is made, [inferenceResult] is returned unchanged.
  ///
  /// If [isCoercionAllowed] is `true`, the assignability check is made
  /// accounting for a possible coercion that may adjust the type of the
  /// expression.
  ExpressionInferenceResult reportAssignabilityErrors(
    DartType contextType,
    ExpressionInferenceResult inferenceResult, {
    int? fileOffset,
    DartType? declaredContextType,
    DartType? runtimeCheckedType,
    bool isVoidAllowed = false,
    bool isCoercionAllowed = true,
    Template<
      Message Function({
        required DartType actualType,
        required DartType expectedType,
      })
    >?
    errorTemplate,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    errorTemplate ??= diag.invalidAssignmentError;

    fileOffset ??= inferenceResult.expression.fileOffset;
    contextType = computeGreatestClosure(contextType);

    Template<
      Message Function({
        required DartType actualType,
        required DartType expectedType,
      })
    >?
    preciseTypeErrorTemplate = _getPreciseTypeErrorTemplate(
      inferenceResult.expression,
    );
    AssignabilityResult assignabilityResult = _computeAssignabilityKind(
      contextType,
      inferenceResult.inferredType,
      isVoidAllowed: isVoidAllowed,
      isExpressionTypePrecise: preciseTypeErrorTemplate != null,
      coerceExpression: isCoercionAllowed,
      fileOffset: fileOffset,
      treeNodeForTesting: inferenceResult.expression,
    );

    if (assignabilityResult.needsTearOff) {
      TypedTearoff typedTearoff = _tearOffCall(
        inferenceResult.expression,
        inferenceResult.inferredType,
        fileOffset,
      );
      inferenceResult = new ExpressionInferenceResult(
        typedTearoff.tearoffType,
        typedTearoff.tearoff,
      );
    }
    if (assignabilityResult.implicitInstantiation != null) {
      inferenceResult = _applyImplicitInstantiation(
        assignabilityResult.implicitInstantiation,
        inferenceResult.inferredType,
        inferenceResult.expression,
      );
    }

    DartType expressionType = inferenceResult.inferredType;
    Expression expression = inferenceResult.expression;
    DartType? postCoercionType = inferenceResult.postCoercionType;
    Expression? result;
    switch (assignabilityResult.kind) {
      case AssignabilityKind.assignable:
        break;
      case AssignabilityKind.assignableCast:
        break;
      case AssignabilityKind.unassignable:
        // Error: not assignable.  Perform error recovery.
        result = _wrapUnassignableExpression(
          expression,
          expressionType,
          contextType,
          errorTemplate.withArguments(
            actualType: expressionType,
            expectedType: declaredContextType ?? contextType,
          ),
        );
        break;
      case AssignabilityKind.unassignableVoid:
        // Error: not assignable.  Perform error recovery.
        result = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: expression,
          message: diag.voidExpression,
          fileUri: fileUri,
          fileOffset: expression.fileOffset,
          length: noLength,
        );
        break;
      case AssignabilityKind.unassignablePrecise:
        // Coverage-ignore(suite): Not run.
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        result = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: expression,
          message: preciseTypeErrorTemplate!.withArguments(
            actualType: expressionType,
            expectedType: contextType,
          ),
          fileUri: fileUri,
          fileOffset: expression.fileOffset,
          length: noLength,
        );
        break;
      case AssignabilityKind.unassignableCantTearoff:
        result = _wrapTearoffErrorExpression(expression, contextType);
        break;
      case AssignabilityKind.unassignableNullability:
        if (expressionType == assignabilityResult.subtype &&
            contextType == assignabilityResult.supertype &&
            expression is! NullLiteral &&
            expressionType is! NullType) {
          whyNotPromoted ??= flowAnalysis.whyNotPromoted(expression);
          result = _wrapUnassignableExpression(
            expression,
            expressionType,
            contextType,
            errorTemplate.withArguments(
              actualType: expressionType,
              expectedType: declaredContextType ?? contextType,
            ),
            context: getWhyNotPromotedContext(
              whyNotPromoted.call(),
              expression,
              // Coverage-ignore(suite): Not run.
              (type) => typeSchemaEnvironment.isSubtypeOf(type, contextType),
            ),
          );
        } else {
          result = _wrapUnassignableExpression(
            expression,
            expressionType,
            contextType,
            errorTemplate.withArguments(
              actualType: expressionType,
              expectedType: declaredContextType ?? contextType,
            ),
          );
        }
        break;
    }

    if (result != null) {
      flowAnalysis.forwardExpression(result, expression);
      return new ExpressionInferenceResult(
        expressionType,
        result,
        postCoercionType: postCoercionType,
      );
    } else {
      return inferenceResult;
    }
  }

  /// Same as [ensureAssignable], but accepts an [ExpressionInferenceResult]
  /// rather than an expression and a type separately.  If no change is made,
  /// [inferenceResult] is returned unchanged.
  ExpressionInferenceResult ensureAssignableResult(
    DartType contextType,
    ExpressionInferenceResult inferenceResult, {
    int? fileOffset,
    DartType? declaredContextType,
    DartType? runtimeCheckedType,
    bool isVoidAllowed = false,
    bool coerceExpression = true,
    Template<
      Message Function({
        required DartType actualType,
        required DartType expectedType,
      })
    >?
    errorTemplate,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (coerceExpression) {
      ExpressionInferenceResult? coercionResult = coerceExpressionForAssignment(
        contextType,
        inferenceResult,
        fileOffset: fileOffset,
        declaredContextType: declaredContextType,
        runtimeCheckedType: runtimeCheckedType,
        isVoidAllowed: isVoidAllowed,
        coerceExpression: coerceExpression,
        treeNodeForTesting: inferenceResult.expression,
      );
      if (coercionResult != null) {
        return coercionResult;
      }
    }

    inferenceResult = reportAssignabilityErrors(
      contextType,
      inferenceResult,
      fileOffset: fileOffset,
      declaredContextType: declaredContextType,
      runtimeCheckedType: runtimeCheckedType,
      isVoidAllowed: isVoidAllowed,
      isCoercionAllowed: coerceExpression,
      errorTemplate: errorTemplate,
      whyNotPromoted: whyNotPromoted,
    );

    return inferenceResult;
  }

  Expression _wrapTearoffErrorExpression(
    Expression expression,
    DartType contextType,
  ) {
    Expression errorNode =
        new AsExpression(
            expression,
            // TODO(johnniwinther): Fix this.
            // TODO(ahe): The outline phase doesn't correctly remove invalid
            // uses of type parameters, for example, on static members. Once
            // that has been fixed, we should always be able to use
            // [contextType] directly here.
            hasAnyTypeParameters(contextType)
                ? const NeverType.nonNullable()
                : contextType,
          )
          ..isTypeError = true
          ..fileOffset = expression.fileOffset;
    if (contextType is! InvalidType) {
      errorNode = problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: errorNode,
        message: diag.nullableTearoffError.withArguments(
          methodName: callName.text,
        ),
        fileUri: fileUri,
        fileOffset: errorNode.fileOffset,
        length: noLength,
      );
    }
    return errorNode;
  }

  Expression _wrapUnassignableExpression(
    Expression expression,
    DartType expressionType,
    DartType contextType,
    Message message, {
    List<LocatedMessage>? context,
  }) {
    Expression errorNode =
        new AsExpression(
            expression,
            // TODO(johnniwinther): Fix this.
            // TODO(ahe): The outline phase doesn't correctly remove invalid
            // uses of type parameters, for example, on static members. Once
            // that has been fixed, we should always be able to use
            // [contextType] directly here.
            hasAnyTypeParameters(contextType)
                ? const NeverType.nonNullable()
                : contextType,
          )
          ..isTypeError = true
          ..fileOffset = expression.fileOffset;
    if (contextType is! InvalidType && expressionType is! InvalidType) {
      errorNode = problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: errorNode,
        message: message,
        fileUri: fileUri,
        fileOffset: errorNode.fileOffset,
        length: noLength,
        context: context,
      );
    }
    return errorNode;
  }

  TypedTearoff _tearOffCall(
    Expression expression,
    DartType expressionType,
    int fileOffset,
  ) {
    ObjectAccessTarget target = findInterfaceMember(
      expressionType,
      callName,
      fileOffset,
      isSetter: false,
    );

    Expression tearOff;
    DartType tearoffType = target.getGetterType(this);
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
        // TODO(johnniwinther): Avoid null-check for non-nullable expressions.

        // Replace expression with:
        // `let t = expression in t == null ? null : t.call`
        VariableDeclaration t = new VariableDeclaration.forValue(
          expression,
          type: expressionType,
        )..fileOffset = fileOffset;
        tearOff = new Let(
          t,
          new ConditionalExpression(
            new EqualsNull(new VariableGet(t)..fileOffset = fileOffset)
              ..fileOffset = fileOffset,
            new NullLiteral()..fileOffset = fileOffset,
            new InstanceTearOff(
              InstanceAccessKind.Instance,
              new VariableGet(t),
              callName,
              interfaceTarget: target.member as Procedure,
              resultType: tearoffType,
            )..fileOffset = fileOffset,
            tearoffType,
          ),
        )..fileOffset = fileOffset;
      case ObjectAccessTargetKind.extensionTypeMember:
        tearOff = new StaticInvocation(
          target.tearoffTarget as Procedure,
          new Arguments([expression], types: target.receiverTypeArguments)
            ..fileOffset = fileOffset,
        )..fileOffset = fileOffset;
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableInstanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.superMember:
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        throw new UnsupportedError("Unexpected call tear-off $target.");
    }

    return new TypedTearoff(tearoffType, tearOff);
  }

  /// Computes the assignability kind of [expressionType] to [contextType].
  ///
  /// The computation is side-effect free.
  AssignabilityResult _computeAssignabilityKind(
    DartType contextType,
    DartType expressionType, {
    required bool isVoidAllowed,
    required bool isExpressionTypePrecise,
    required bool coerceExpression,
    required int fileOffset,
    required TreeNode? treeNodeForTesting,
  }) {
    // If an interface type is being assigned to a function type, see if we
    // should tear off `.call`.
    // TODO(paulberry): use resolveTypeParameter.  See findInterfaceMember.
    bool needsTearoff = false;
    if (coerceExpression && _shouldTearOffCall(contextType, expressionType)) {
      ObjectAccessTarget target = findInterfaceMember(
        expressionType,
        callName,
        fileOffset,
        isSetter: false,
      );
      bool shouldTearOff;
      switch (target.kind) {
        case ObjectAccessTargetKind.instanceMember:
        case ObjectAccessTargetKind.nullableInstanceMember:
          Member? member = target.member;
          shouldTearOff =
              member is Procedure && member.kind == ProcedureKind.Method;
        case ObjectAccessTargetKind.extensionTypeMember:
        case ObjectAccessTargetKind.nullableExtensionTypeMember:
          shouldTearOff = target.tearoffTarget is Procedure;
        case ObjectAccessTargetKind.objectMember:
        case ObjectAccessTargetKind.superMember:
        case ObjectAccessTargetKind.extensionMember:
        case ObjectAccessTargetKind.nullableExtensionMember:
        case ObjectAccessTargetKind.dynamic:
        case ObjectAccessTargetKind.never:
        case ObjectAccessTargetKind.invalid:
        case ObjectAccessTargetKind.missing:
        case ObjectAccessTargetKind.ambiguous:
        case ObjectAccessTargetKind.recordIndexed:
        case ObjectAccessTargetKind.recordNamed:
        case ObjectAccessTargetKind.nullableRecordIndexed:
        case ObjectAccessTargetKind.nullableRecordNamed:
        case ObjectAccessTargetKind.callFunction:
        case ObjectAccessTargetKind.nullableCallFunction:
        case ObjectAccessTargetKind.extensionTypeRepresentation:
        // Coverage-ignore(suite): Not run.
        case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
          shouldTearOff = false;
      }
      if (shouldTearOff) {
        needsTearoff = true;
        if (target.isNullable) {
          return const AssignabilityResult(
            AssignabilityKind.unassignableCantTearoff,
            needsTearOff: false,
          );
        }
        expressionType = target.getGetterType(this);
      }
    }
    ImplicitInstantiation? implicitInstantiation;
    if (coerceExpression && libraryFeatures.constructorTearoffs.isEnabled) {
      implicitInstantiation = computeImplicitInstantiation(
        expressionType,
        contextType,
        treeNodeForTesting: treeNodeForTesting,
      );
      if (implicitInstantiation != null) {
        expressionType = implicitInstantiation.instantiatedType;
      }
    }

    if (expressionType is VoidType && !isVoidAllowed) {
      assert(implicitInstantiation == null);
      assert(!needsTearoff);
      return const AssignabilityResult(
        AssignabilityKind.unassignableVoid,
        needsTearOff: false,
      );
    }

    IsSubtypeOf isDirectSubtypeResult = typeSchemaEnvironment
        .performSubtypeCheck(expressionType, contextType);
    bool isDirectlyAssignable = isDirectSubtypeResult.isSuccess();
    if (isDirectlyAssignable) {
      return new AssignabilityResult(
        AssignabilityKind.assignable,
        needsTearOff: needsTearoff,
        implicitInstantiation: implicitInstantiation,
      );
    }

    bool isIndirectlyAssignable = expressionType is DynamicType;
    if (!isIndirectlyAssignable) {
      if (typeSchemaEnvironment
          .performSubtypeCheck(
            expressionType,
            contextType.withDeclaredNullability(Nullability.nullable),
          )
          .isSuccess()) {
        return new AssignabilityResult.withTypes(
          AssignabilityKind.unassignableNullability,
          expressionType,
          contextType,
          needsTearOff: needsTearoff,
          implicitInstantiation: implicitInstantiation,
        );
      } else {
        return new AssignabilityResult(
          AssignabilityKind.unassignable,
          needsTearOff: needsTearoff,
          implicitInstantiation: implicitInstantiation,
        );
      }
    }
    if (isExpressionTypePrecise) {
      // Coverage-ignore-block(suite): Not run.
      // The type of the expression is known precisely, so an implicit
      // downcast is guaranteed to fail.  Insert a compile-time error.
      assert(implicitInstantiation == null);
      assert(!needsTearoff);
      return const AssignabilityResult(
        AssignabilityKind.unassignablePrecise,
        needsTearOff: false,
      );
    }

    if (coerceExpression) {
      // Insert an implicit downcast.
      return new AssignabilityResult(
        AssignabilityKind.assignableCast,
        needsTearOff: needsTearoff,
        implicitInstantiation: implicitInstantiation,
      );
    }

    return new AssignabilityResult(
      AssignabilityKind.unassignable,
      needsTearOff: needsTearoff,
      implicitInstantiation: implicitInstantiation,
    );
  }

  /// Computes the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType]. If [explicitTypeArguments]
  /// are provided, these are returned, otherwise type arguments are inferred
  /// using [receiverType].
  DartType computeExplicitExtensionReceiverContextType(
    Extension extension,
    List<DartType>? explicitTypeArguments,
  ) {
    if (extension.typeParameters.isEmpty) {
      assert(explicitTypeArguments == null);
      return extension.onType;
    } else {
      List<DartType> typeArguments;
      if (explicitTypeArguments != null) {
        assert(explicitTypeArguments.length == extension.typeParameters.length);
        typeArguments = explicitTypeArguments;
      } else {
        typeArguments = new List.filled(
          extension.typeParameters.length,
          const UnknownType(),
        );
      }
      return Substitution.fromPairs(
        extension.typeParameters,
        typeArguments,
      ).substituteType(extension.onType);
    }
  }

  /// Computes the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType]. If [explicitTypeArguments]
  /// are provided, these are returned, otherwise type arguments are inferred
  /// using [receiverType].
  List<DartType> computeExtensionTypeArgument(
    Extension extension,
    List<DartType>? explicitTypeArguments,
    DartType receiverType, {
    required TreeNode treeNodeForTesting,
  }) {
    if (explicitTypeArguments != null) {
      assert(explicitTypeArguments.length == extension.typeParameters.length);
      return explicitTypeArguments;
    } else if (extension.typeParameters.isEmpty) {
      assert(explicitTypeArguments == null);
      return const <DartType>[];
    } else {
      return inferExtensionTypeArguments(
        extension,
        receiverType,
        treeNodeForTesting: treeNodeForTesting,
      );
    }
  }

  /// Infers the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType].
  List<DartType> inferExtensionTypeArguments(
    Extension extension,
    DartType receiverType, {
    required TreeNode? treeNodeForTesting,
  }) {
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(
          extension.typeParameters,
        );
    List<StructuralParameter> typeParameters =
        freshTypeParameters.freshTypeParameters;
    DartType onType = freshTypeParameters.substitute(extension.onType);
    List<DartType> inferredTypes = new List<DartType>.filled(
      typeParameters.length,
      const UnknownType(),
    );
    TypeConstraintGatherer gatherer = typeSchemaEnvironment
        .setupGenericTypeInference(
          null,
          typeParameters,
          null,
          typeOperations: cfeOperations,
          inferenceUsingBoundsIsEnabled:
              libraryFeatures.inferenceUsingBounds.isEnabled,
          inferenceResultForTesting: dataForTesting
              // Coverage-ignore(suite): Not run.
              ?.typeInferenceResult,
          treeNodeForTesting: treeNodeForTesting,
        );
    gatherer.constrainArguments(
      [onType],
      [receiverType],
      treeNodeForTesting: treeNodeForTesting,
    );
    inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
      gatherer.computeConstraints(),
      typeParameters,
      inferredTypes,
      inferenceUsingBoundsIsEnabled:
          libraryFeatures.inferenceUsingBounds.isEnabled,
      dataForTesting: dataForTesting,
      treeNodeForTesting: treeNodeForTesting,
      typeOperations: cfeOperations,
    );
    return inferredTypes;
  }

  ObjectAccessTarget? _findExtensionTypeMember(
    DartType receiverType,
    ExtensionType extensionType,
    Name name,
    int fileOffset, {
    required bool isSetter,
    required bool hasNonObjectMemberAccess,
    bool isDotShorthand = false,
  }) {
    ClassMember? classMember = isDotShorthand
        ? _getExtensionTypeStaticMember(
            extensionType.extensionTypeDeclaration,
            name,
            false,
          )
        : _getExtensionTypeMember(
            extensionType.extensionTypeDeclaration,
            name,
            isSetter,
          );
    if (classMember == null) {
      return null;
    }
    Member? member = classMember.getMember(engine.membersBuilder);
    if (member is Procedure &&
        member.stubKind == ProcedureStubKind.RepresentationField) {
      return new ObjectAccessTarget.extensionTypeRepresentation(
        receiverType,
        extensionType,
        member,
        hasNonObjectMemberAccess: hasNonObjectMemberAccess,
      );
    }
    if (member.isExtensionTypeMember) {
      ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
          classMember.declarationBuilder as ExtensionTypeDeclarationBuilder;
      ExtensionTypeDeclaration extensionTypeDeclaration =
          extensionTypeDeclarationBuilder.extensionTypeDeclaration;
      ClassMemberKind kind = classMember.memberKind;
      return new ObjectAccessTarget.extensionTypeMember(
        receiverType,
        member,
        classMember.getTearOff(engine.membersBuilder),
        kind,
        hierarchyBuilder.getTypeArgumentsAsInstanceOf(
          extensionType,
          extensionTypeDeclaration,
        )!,
        hasNonObjectMemberAccess: hasNonObjectMemberAccess,
      );
    } else {
      return new ObjectAccessTarget.interfaceMember(
        receiverType,
        member,
        hasNonObjectMemberAccess: hasNonObjectMemberAccess,
      );
    }
  }

  /// Returns the extension member access by the given [name] for a receiver
  /// with the static [receiverType].
  ///
  /// If none is found, [defaultTarget] is returned.
  ///
  /// If multiple are found, none more specific, an
  /// [AmbiguousExtensionAccessTarget] is returned. This access kind results in
  /// a compile-time error, but is used to provide a better message than just
  /// reporting that the receiver does not have a member by the given name.
  ///
  /// If [isPotentiallyNullableAccess] is `true`, the returned extension member
  /// is flagged as a nullable extension member access. This access kind results
  /// in a compile-time error, but is used to provide a better message than just
  /// reporting that the receiver does not have a member by the given name.
  ObjectAccessTarget? _findExtensionMember(
    DartType receiverType,
    Class classNode,
    Name name,
    _ObjectAccessDescriptor descriptor,
    int fileOffset, {
    bool setter = false,
    ObjectAccessTarget? defaultTarget,
    bool isPotentiallyNullableAccess = false,
  }) {
    if (descriptor.hasComplementaryTarget(this)) {
      // If we're looking for `foo` and `foo=` can be found or vice-versa then
      // extension methods should not be found.
      return defaultTarget;
    }

    ExtensionAccessCandidate? bestSoFar;
    List<ExtensionAccessCandidate> noneMoreSpecific = [];
    extensionScope.forEachExtension((ExtensionBuilder extensionBuilder) {
      MemberLookupResult? result = extensionBuilder.lookupExtensionMemberByName(
        name,
      );
      if (result == null || result.isInvalidLookup || result.isStatic) {
        return;
      }
      MemberBuilder? thisBuilder;
      MemberBuilder? otherBuilder;
      if (setter || name == indexSetName) {
        // Setters and `operator []=` are returned through the setable.
        thisBuilder = result.setable;
        otherBuilder = result.getable;
      } else {
        thisBuilder = result.getable;
        otherBuilder = result.setable;
      }
      assert(thisBuilder != null || otherBuilder != null);
      DartType onType;
      DartType onTypeInstantiateToBounds;
      List<DartType> inferredTypeArguments;
      if (extensionBuilder.extension.typeParameters.isEmpty) {
        onTypeInstantiateToBounds = onType = extensionBuilder.extension.onType;
        inferredTypeArguments = const <DartType>[];
      } else {
        List<TypeParameter> typeParameters =
            extensionBuilder.extension.typeParameters;
        inferredTypeArguments = inferExtensionTypeArguments(
          extensionBuilder.extension,
          receiverType,
          treeNodeForTesting: null,
        );
        Substitution inferredSubstitution = Substitution.fromPairs(
          typeParameters,
          inferredTypeArguments,
        );

        for (int index = 0; index < typeParameters.length; index++) {
          TypeParameter typeParameter = typeParameters[index];
          DartType typeArgument = inferredTypeArguments[index];
          DartType bound = inferredSubstitution.substituteType(
            typeParameter.bound,
          );
          if (!typeSchemaEnvironment.isSubtypeOf(typeArgument, bound)) {
            return;
          }
        }
        onType = inferredSubstitution.substituteType(
          extensionBuilder.extension.onType,
        );
        List<DartType> instantiateToBoundTypeArguments = calculateBounds(
          typeParameters,
          coreTypes.objectClass,
        );
        Substitution instantiateToBoundsSubstitution = Substitution.fromPairs(
          typeParameters,
          instantiateToBoundTypeArguments,
        );
        onTypeInstantiateToBounds = instantiateToBoundsSubstitution
            .substituteType(extensionBuilder.extension.onType);
      }

      if (typeSchemaEnvironment.isSubtypeOf(receiverType, onType)) {
        ObjectAccessTarget target = const ObjectAccessTarget.missing();
        if (thisBuilder != null) {
          Member? member;
          ClassMemberKind classMemberKind;
          if (thisBuilder.isProperty) {
            if (setter) {
              classMemberKind = ClassMemberKind.Setter;
              member = thisBuilder.writeTarget!;
            } else {
              classMemberKind = ClassMemberKind.Getter;
              member = thisBuilder.readTarget!;
            }
          } else {
            assert(!setter, "Unexpected method found as setter: $thisBuilder");
            classMemberKind = ClassMemberKind.Method;
            member = thisBuilder.invokeTarget!;
          }
          Member? tearoffTarget = thisBuilder.readTarget;
          target = new ObjectAccessTarget.extensionMember(
            receiverType,
            member,
            tearoffTarget,
            classMemberKind,
            inferredTypeArguments,
            isPotentiallyNullable: isPotentiallyNullableAccess,
          );
        }
        ExtensionAccessCandidate candidate = new ExtensionAccessCandidate(
          (thisBuilder ?? otherBuilder)!,
          onType,
          onTypeInstantiateToBounds,
          target,
          isPlatform: extensionBuilder.libraryBuilder.importUri.isScheme(
            'dart',
          ),
        );
        if (noneMoreSpecific.isNotEmpty) {
          // Coverage-ignore-block(suite): Not run.
          bool isMostSpecific = true;
          for (ExtensionAccessCandidate other in noneMoreSpecific) {
            bool? isMoreSpecific = candidate.isMoreSpecificThan(
              typeSchemaEnvironment,
              other,
            );
            if (isMoreSpecific != true) {
              isMostSpecific = false;
              break;
            }
          }
          if (isMostSpecific) {
            bestSoFar = candidate;
            noneMoreSpecific.clear();
          } else {
            noneMoreSpecific.add(candidate);
          }
        } else if (bestSoFar == null) {
          bestSoFar = candidate;
        } else {
          bool? isMoreSpecific = candidate.isMoreSpecificThan(
            typeSchemaEnvironment,
            bestSoFar!,
          );
          if (isMoreSpecific == true) {
            bestSoFar = candidate;
          } else if (isMoreSpecific == null) {
            noneMoreSpecific.add(bestSoFar!);
            noneMoreSpecific.add(candidate);
            bestSoFar = null;
          }
        }
      }
    });
    if (bestSoFar != null) {
      return bestSoFar!.target;
    } else {
      if (noneMoreSpecific.isNotEmpty) {
        return new AmbiguousExtensionAccessTarget(
          receiverType,
          noneMoreSpecific,
        );
      }
    }
    return defaultTarget;
  }

  /// Finds a constructor of [type] called [name].
  Member? findConstructor(
    TypeDeclarationType type,
    Name name,
    int fileOffset, {
    bool isTearoff = false,
  }) {
    // TODO(Dart Model team): Seems like an abstraction level issue to require
    // going from `Class` objects back to builders to find a `Member`.
    DeclarationBuilder builder;
    switch (type) {
      case InterfaceType():
        builder = engine.hierarchyBuilder.loader
            .computeClassBuilderFromTargetClass(type.classNode);
      case ExtensionType():
        builder = engine.hierarchyBuilder.loader
            .computeExtensionTypeBuilderFromTargetExtensionType(
              type.extensionTypeDeclaration,
            );
    }

    MemberLookupResult? result = builder.findConstructorOrFactory(
      name.text,
      libraryBuilder,
    );
    if (result == null || result.isInvalidLookup) {
      return null;
    }
    MemberBuilder? constructorBuilder = result.getable;
    return isTearoff
        ? constructorBuilder?.readTarget
        : constructorBuilder?.invokeTarget;
  }

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation using [fileOffset].
  ///
  /// For the case where [receiverType] is a [FunctionType], and the name
  /// is `call`, the string 'call' is returned as a sentinel object.
  ///
  /// For the case where [receiverType] is `dynamic`, and the name is declared
  /// in Object, the member from Object is returned though the call may not end
  /// up targeting it if the arguments do not match (the basic principle is that
  /// the Object member is used for inferring types only if noSuchMethod cannot
  /// be targeted due to, e.g., an incorrect argument count).
  ObjectAccessTarget findInterfaceMember(
    DartType receiverType,
    Name name,
    int fileOffset, {
    required bool isSetter,
    bool instrumented = true,
    bool includeExtensionMethods = false,
  }) {
    assert(isKnown(receiverType));

    DartType receiverBound = receiverType.nonTypeParameterBound;

    bool hasNonObjectMemberAccess =
        receiverType.hasNonObjectMemberAccess ||
        // Calls to `==` are always on a non-null receiver.
        name == equalsName;

    Class classNode = receiverBound is InterfaceType
        ? receiverBound.classNode
        : coreTypes.objectClass;
    _ObjectAccessDescriptor objectAccessDescriptor =
        new _ObjectAccessDescriptor(
          receiverType: receiverType,
          name: name,
          classNode: classNode,
          receiverBound: receiverBound,
          hasNonObjectMemberAccess: hasNonObjectMemberAccess,
          isSetter: isSetter,
          fileOffset: fileOffset,
        );

    if (!hasNonObjectMemberAccess) {
      Member? member = _getInterfaceMember(
        coreTypes.objectClass,
        name,
        isSetter,
      );
      if (member != null) {
        // Null implements all Object members so this is not considered a
        // potentially nullable access.
        return new ObjectAccessTarget.objectMember(receiverType, member);
      }
      if (includeExtensionMethods && receiverBound is! DynamicType) {
        ObjectAccessTarget? target = _findExtensionMember(
          receiverType,
          coreTypes.objectClass,
          name,
          objectAccessDescriptor,
          fileOffset,
          setter: isSetter,
        );
        if (target != null) {
          return target;
        } else if (receiverBound is ExtensionType &&
            name.text ==
                receiverBound.extensionTypeDeclaration.representationName) {
          // Coverage-ignore-block(suite): Not run.
          ObjectAccessTarget target = objectAccessDescriptor
              .findNonExtensionTarget(this);
          if (!target.isMissing) {
            return target;
          }
        }
      }
    }

    ObjectAccessTarget target = objectAccessDescriptor.findNonExtensionTarget(
      this,
    );
    if (target.isMissing && includeExtensionMethods) {
      if (!hasNonObjectMemberAccess) {
        // When the receiver type is potentially nullable we would have found
        // the extension member above, if available. Therefore we know that we
        // are in an erroneous case and instead look up the extension member on
        // the non-nullable receiver bound but flag the found target as a
        // nullable extension member access. This is done to provide the better
        // error message that the extension member exists but that the access is
        // invalid.
        target = _findExtensionMember(
          receiverType.toNonNull(),
          classNode,
          name,
          objectAccessDescriptor,
          fileOffset,
          setter: isSetter,
          defaultTarget: target,
          isPotentiallyNullableAccess: true,
        )!;
      } else {
        target = _findExtensionMember(
          receiverType,
          classNode,
          name,
          objectAccessDescriptor,
          fileOffset,
          setter: isSetter,
          defaultTarget: target,
        )!;
      }
    }
    return target;
  }

  /// Finds a static member of [type] called [name].
  Member? findStaticMember(DartType type, Name name, int fileOffset) {
    if (type is! TypeDeclarationType) return null;
    switch (type) {
      case InterfaceType():
        return _getStaticMember(type.classNode, name, false);
      case ExtensionType():
        ObjectAccessTarget? target = _findExtensionTypeMember(
          type,
          type,
          name,
          fileOffset,
          isSetter: false,
          hasNonObjectMemberAccess: type.hasNonObjectMemberAccess,
          isDotShorthand: true,
        );
        return target?.member;
    }
  }

  /// If target is missing on a non-dynamic receiver, an error is reported
  /// using [diag.undefinedSetter] and an invalid expression is returned.
  Expression? reportMissingInterfaceMember(
    ObjectAccessTarget target,
    DartType receiverType,
    Name name,
    int fileOffset,
  ) {
    assert(isKnown(receiverType));
    if (target.isMissing) {
      int length = name.text.length;
      if (identical(name.text, callName.text) ||
          identical(name.text, unaryMinusName.text)) {
        length = 1;
      }
      return problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.undefinedSetter.withArguments(
          name: name.text,
          type: receiverType.nonTypeParameterBound,
        ),
        fileUri: fileUri,
        fileOffset: fileOffset,
        length: length,
      );
    }
    return null;
  }

  /// Returns the getter type of [interfaceMember] on a receiver of type
  /// [receiverType].
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      T method() {}
  ///      T getter => null;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method; // The getter type is `int Function()`.
  ///    c.getter; // The getter type is `int`.
  ///
  DartType getGetterTypeForMemberTarget(
    Member interfaceMember,
    DartType receiverType, {
    required bool isSuper,
  }) {
    assert(
      interfaceMember is Field || interfaceMember is Procedure,
      "Unexpected interface member $interfaceMember.",
    );
    DartType calleeType = isSuper
        ? interfaceMember.superGetterType
        : interfaceMember.getterType;
    return _getTypeForMemberTarget(interfaceMember, calleeType, receiverType);
  }

  /// Returns the setter type of [interfaceMember] on a receiver of type
  /// [receiverType].
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      void set setter(T value) {}
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.setter = 42; // The setter type is `int`.
  ///
  DartType getSetterTypeForMemberTarget(
    Member interfaceMember,
    DartType receiverType, {
    required bool isSuper,
  }) {
    assert(
      interfaceMember is Field || interfaceMember is Procedure,
      "Unexpected interface member $interfaceMember.",
    );
    DartType calleeType = isSuper
        ? interfaceMember.superSetterType
        : interfaceMember.setterType;
    return _getTypeForMemberTarget(interfaceMember, calleeType, receiverType);
  }

  DartType _getTypeForMemberTarget(
    Member interfaceMember,
    DartType calleeType,
    DartType receiverType,
  ) {
    TypeDeclaration enclosingTypeDeclaration =
        interfaceMember.enclosingTypeDeclaration!;
    if (enclosingTypeDeclaration.typeParameters.isNotEmpty) {
      receiverType = receiverType.nonTypeParameterBound;
      if (receiverType is TypeDeclarationType) {
        List<DartType> castedTypeArguments = hierarchyBuilder
            .getTypeArgumentsAsInstanceOf(
              receiverType,
              enclosingTypeDeclaration,
            )!;
        calleeType = Substitution.fromPairs(
          enclosingTypeDeclaration.typeParameters,
          castedTypeArguments,
        ).substituteType(calleeType);
      }
    }
    return calleeType;
  }

  /// Returns the type of the receiver argument in an access to an extension
  /// member on [extension] with the given extension [typeArguments].
  DartType getExtensionReceiverType(
    Extension extension,
    List<DartType> typeArguments,
  ) {
    DartType receiverType = extension.onType;
    if (extension.typeParameters.isNotEmpty) {
      Substitution substitution = Substitution.fromPairs(
        extension.typeParameters,
        typeArguments,
      );
      return substitution.substituteType(receiverType);
    }
    return receiverType;
  }

  DartType? getDerivedTypeArgumentOf(DartType type, Class class_) {
    if (type is TypeDeclarationType) {
      List<DartType>? typeArgumentsAsInstanceOfClass = hierarchyBuilder
          .getTypeArgumentsAsInstanceOf(type, class_);
      if (typeArgumentsAsInstanceOfClass != null) {
        return typeArgumentsAsInstanceOfClass[0];
      }
    }
    return null;
  }

  DartType getTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType && identical(type.classNode, class_)) {
      return type.typeArguments[0];
    } else {
      return const UnknownType();
    }
  }

  /// Returns the type used as the inferred type of a variable declaration,
  /// based on the static type of the initializer expression, given by
  /// [initializerType].
  DartType inferDeclarationType(
    DartType initializerType, {
    bool forSyntheticVariable = false,
    required InferenceDefaultType inferenceDefaultType,
  }) {
    if (forSyntheticVariable) {
      return initializerType;
    } else if (initializerType is NullType) {
      switch (inferenceDefaultType) {
        case InferenceDefaultType.NullableObject:
          // For primary constructors, `Object?` used in this case.
          return coreTypes.objectNullableRawType;
        case InferenceDefaultType.Dynamic:
          // If the initializer type is Null or bottom, the inferred type is
          // dynamic.
          // TODO(paulberry): this rule is inherited from analyzer behavior but
          //  is not spec'ed anywhere.
          return const DynamicType();
      }
    } else {
      return demoteTypeInLibrary(initializerType);
    }
  }

  ExpressionInferenceResult wrapExpressionInferenceResultInProblem(
    ExpressionInferenceResult result,
    Message message,
    int fileOffset,
    int length, {
    List<LocatedMessage>? context,
  }) {
    return new ExpressionInferenceResult(
      result.inferredType,
      problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: result.expression,
        message: message,
        fileUri: fileUri,
        fileOffset: fileOffset,
        length: length,
        context: context,
      ),
    );
  }

  InvocationInferenceResult inferInvocation(
    InferenceVisitor visitor,
    DartType typeContext,
    int offset,
    InvocationTargetType invocationTargetType,
    TypeArguments? typeArguments,
    ActualArguments arguments, {
    List<VariableDeclaration>? hoistedExpressions,
    bool isSpecialCasedBinaryOperator = false,
    bool isSpecialCasedTernaryOperator = false,
    DartType? receiverType,
    bool skipTypeArgumentInference = false,
    bool isConst = false,
    bool isImplicitCall = false,
    Member? staticTarget,
  }) {
    FunctionType calleeType = invocationTargetType
        .computeFunctionTypeForInference(typeArguments?.types, arguments);
    return _inferInvocation(
      visitor,
      typeContext,
      offset,
      calleeType,
      typeArguments,
      arguments,
      hoistedExpressions,
      isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
      isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator,
      receiverType: receiverType,
      skipTypeArgumentInference: skipTypeArgumentInference,
      isConst: isConst,
      isImplicitCall: isImplicitCall,
      staticTarget: staticTarget,
    );
  }

  /// Performs the type inference steps that are shared by all kinds of
  /// invocations (constructors, instance methods, and static methods).
  InvocationInferenceResult _inferInvocation(
    InferenceVisitor visitor,
    DartType typeContext,
    int offset,
    FunctionType calleeType,
    TypeArguments? typeArguments,
    ActualArguments actualArguments,
    List<VariableDeclaration>? hoistedExpressions, {
    bool isSpecialCasedBinaryOperator = false,
    bool isSpecialCasedTernaryOperator = false,
    DartType? receiverType,
    bool skipTypeArgumentInference = false,
    bool isConst = false,
    required bool isImplicitCall,
    Member? staticTarget,
  }) {
    // [receiverType] must be provided for special-cased operators.
    assert(
      !isSpecialCasedBinaryOperator && !isSpecialCasedTernaryOperator ||
          receiverType != null,
    );

    List<StructuralParameter> calleeTypeParameters = calleeType.typeParameters;
    if (calleeTypeParameters.isNotEmpty) {
      // It's possible that one of the callee type parameters might match a type
      // that already exists as part of inference (e.g. the type of an
      // argument).  This might happen, for instance, in the case where a
      // function or method makes a recursive call to itself.  To avoid the
      // callee type parameters accidentally matching a type that already
      // exists, and creating invalid inference results, we need to create fresh
      // type parameters for the callee (see dartbug.com/31759).
      // TODO(paulberry): is it possible to find a narrower set of circumstances
      // in which me must do this, to avoid a performance regression?
      FreshStructuralParameters fresh = getFreshStructuralParameters(
        calleeTypeParameters,
      );
      calleeType = fresh.applyToFunctionType(calleeType);
      calleeTypeParameters = fresh.freshTypeParameters;
    }

    List<DartType>? explicitTypeArguments = typeArguments?.types;

    bool inferenceNeeded =
        !skipTypeArgumentInference &&
        explicitTypeArguments == null &&
        calleeTypeParameters.isNotEmpty;

    List<DartType>? inferredTypes;
    FunctionTypeInstantiator? instantiator;

    List<VariableDeclaration>? localHoistedExpressions;
    if (actualArguments.hasNamedBeforePositional &&
        hoistedExpressions == null &&
        !isConst) {
      hoistedExpressions = localHoistedExpressions = <VariableDeclaration>[];
    }

    TypeConstraintGatherer? gatherer;
    if (inferenceNeeded) {
      if (isConst) {
        typeContext = new AllTypeParameterEliminator(
          bottomType,
          coreTypes.objectNullableRawType,
        ).substituteType(typeContext);
      }
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
        calleeType.returnType,
        calleeTypeParameters,
        typeContext,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        typeOperations: cfeOperations,
        inferenceResultForTesting: dataForTesting
            // Coverage-ignore(suite): Not run.
            ?.typeInferenceResult,
        treeNodeForTesting: actualArguments,
      );
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
        gatherer.computeConstraints(),
        calleeTypeParameters,
        /* previouslyInferredTypes= */ null,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: actualArguments,
        typeOperations: cfeOperations,
      );
      instantiator = new FunctionTypeInstantiator.fromIterables(
        calleeTypeParameters,
        inferredTypes,
      );
    } else if (explicitTypeArguments != null &&
        calleeTypeParameters.length == explicitTypeArguments.length) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
        calleeTypeParameters,
        explicitTypeArguments,
      );
    } else if (calleeTypeParameters.length != 0) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
        calleeTypeParameters,
        new List<DartType>.filled(
          calleeTypeParameters.length,
          const DynamicType(),
        ),
      );
    }
    bool isIdenticalCall =
        staticTarget == typeSchemaEnvironment.coreTypes.identicalProcedure &&
        actualArguments.positionalCount == 2;
    // TODO(paulberry): if we are doing top level inference and type arguments
    // were omitted, report an error.
    List<Argument> arguments = actualArguments.argumentList;

    // The following loop determines how many argument expressions should be
    // hoisted to preserve the evaluation order. The computation is based on the
    // following observation: the largest suffix of the argument vector, such
    // that every positional argument in that suffix comes before any named
    // argument, retains the evaluation order after the rest of the arguments
    // are hoisted, and therefore doesn't need to be hoisted itself. The loop
    // below finds the starting position of such suffix and stores it in the
    // [hoistingEndIndex] variable. In case all positional arguments come
    // before all named arguments, the suffix coincides with the entire argument
    // vector, and none of the arguments is hoisted. That way the legacy
    // behavior is preserved.
    int hoistingEndIndex;
    if (actualArguments.hasNamedBeforePositional) {
      hoistingEndIndex = arguments.length - 1;
      for (
        int i = arguments.length - 2;
        i >= 0 && hoistingEndIndex == i + 1;
        i--
      ) {
        int previousWeight = arguments[i + 1] is NamedArgument ? 1 : 0;
        int currentWeight = arguments[i] is NamedArgument ? 1 : 0;
        if (currentWeight <= previousWeight) {
          --hoistingEndIndex;
        }
      }
    } else {
      hoistingEndIndex = 0;
    }

    ExpressionInferenceResult inferArgument(_ArgumentInfo argumentInfo) {
      DartType inferredFormalType = argumentInfo.computeInferredFormalType(
        instantiator,
      );
      if (!argumentInfo.isNamed) {
        if (isSpecialCasedBinaryOperator) {
          inferredFormalType = typeSchemaEnvironment
              .getContextTypeOfSpecialCasedBinaryOperator(
                typeContext,
                receiverType!,
                inferredFormalType,
              );
        } else if (isSpecialCasedTernaryOperator) {
          inferredFormalType = typeSchemaEnvironment
              .getContextTypeOfSpecialCasedTernaryOperator(
                typeContext,
                receiverType!,
                inferredFormalType,
              );
        }
      }
      return visitor.inferExpression(
        argumentInfo.argument.expression,
        inferredFormalType,
        isVoidAllowed: true,
      );
    }

    int positionalIndex = 0;
    List<_ArgumentInfo> argumentsInfo = [];
    List<_ArgumentInfo> undeferredArguments = [];
    List<_DeferredArgumentInfo>? deferredFunctionLiterals;
    for (int index = 0; index < arguments.length; index++) {
      Argument argument = arguments[index];
      DartType formalType;
      switch (argument) {
        case PositionalArgument():
          formalType = getPositionalParameterType(
            calleeType,
            positionalIndex++,
          );
        case NamedArgument():
          formalType = getNamedParameterType(calleeType, argument.name);
      }
      Expression unparenthesizedExpression = argument.expression;
      while (unparenthesizedExpression is ParenthesizedExpression) {
        unparenthesizedExpression = unparenthesizedExpression.expression;
      }
      if (isInferenceUpdate1Enabled &&
          unparenthesizedExpression is FunctionExpression) {
        _DeferredArgumentInfo argumentInfo = new _DeferredArgumentInfo(
          argument: argument,
          formalType: formalType,
          unparenthesizedExpression: unparenthesizedExpression,
        );
        argumentsInfo.add(argumentInfo);
        (deferredFunctionLiterals ??= []).add(argumentInfo);
      } else {
        _ArgumentInfo argumentInfo = new _ArgumentInfo(
          argument: argument,
          formalType: formalType,
        );
        argumentsInfo.add(argumentInfo);
        undeferredArguments.add(argumentInfo);
        ExpressionInferenceResult result = inferArgument(argumentInfo);
        DartType inferredType = result.inferredType;
        if (localHoistedExpressions != null && index >= hoistingEndIndex) {
          hoistedExpressions = null;
        }
        Expression expression = _hoist(
          result.expression,
          inferredType,
          hoistedExpressions,
        );
        if (isIdenticalCall) {
          argumentInfo.identicalInfo = flowAnalysis.getExpressionInfo(
            expression,
          );
        }
        argument.expression = expression;
        gatherer?.tryConstrainLower(
          formalType,
          inferredType,
          treeNodeForTesting: actualArguments,
        );
        argumentInfo.actualType = inferredType;
        argumentInfo.argumentInferenceResult = result;
      }
    }
    if (deferredFunctionLiterals != null) {
      bool isFirstStage = true;
      List<List<_DeferredArgumentInfo>> stages =
          new _FunctionLiteralDependencies(
            deferredFunctionLiterals,
            calleeType.typeParameters.toSet(),
            inferenceNeeded ? undeferredArguments : const [],
          ).planReconciliationStages();
      for (int i = 0; i < stages.length; i++) {
        List<_DeferredArgumentInfo> stage = stages[i];
        if (gatherer != null && !isFirstStage) {
          inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
            gatherer.computeConstraints(),
            calleeTypeParameters,
            inferredTypes,
            inferenceUsingBoundsIsEnabled:
                libraryFeatures.inferenceUsingBounds.isEnabled,
            dataForTesting: dataForTesting,
            treeNodeForTesting: actualArguments,
            typeOperations: cfeOperations,
          );
          instantiator = new FunctionTypeInstantiator.fromIterables(
            calleeTypeParameters,
            inferredTypes,
          );
        }
        for (int j = 0; j < stage.length; j++) {
          _DeferredArgumentInfo deferredArgument = stage[j];
          ExpressionInferenceResult result = inferArgument(deferredArgument);
          DartType inferredType = result.inferredType;
          Expression expression = result.expression;
          if (isIdenticalCall) {
            deferredArgument.identicalInfo = flowAnalysis.getExpressionInfo(
              expression,
            );
          }
          deferredArgument.argument.expression = expression;
          gatherer?.tryConstrainLower(
            deferredArgument.formalType,
            inferredType,
            treeNodeForTesting: actualArguments,
          );
          deferredArgument.actualType = inferredType;
          deferredArgument.argumentInferenceResult = result;
        }
        isFirstStage = false;
      }
    }

    if (isIdenticalCall) {
      flowAnalysis.storeExpressionInfo(
        actualArguments.parent as Expression,
        flowAnalysis.equalityOperation_end(
          argumentsInfo[0].identicalInfo,
          new SharedTypeView(argumentsInfo[0].actualType),
          argumentsInfo[1].identicalInfo,
          new SharedTypeView(argumentsInfo[1].actualType),
        ),
      );
    }

    if (isSpecialCasedBinaryOperator || isSpecialCasedTernaryOperator) {
      LocatedMessage? argMessage = problemReporting.checkArgumentsForType(
        function: calleeType,
        explicitTypeArguments: typeArguments,
        arguments: actualArguments,
        fileUri: fileUri,
        fileOffset: offset,
      );
      if (argMessage != null) {
        var (List<Expression> positional, List<NamedExpression> named) =
            argumentsInfo.computeArguments();
        return new WrapInProblemInferenceResult(
          message: argMessage,
          problemReporting: problemReporting,
          compilerContext: compilerContext,
          isInapplicable: true,
          hoistedArguments: localHoistedExpressions,
          positional: positional,
          named: named,
        );
      }
      if (isSpecialCasedBinaryOperator) {
        calleeType = replaceReturnType(
          calleeType,
          typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
            receiverType!,
            argumentsInfo[0].actualType,
          ),
        );
      } else if (isSpecialCasedTernaryOperator) {
        calleeType = replaceReturnType(
          calleeType,
          typeSchemaEnvironment.getTypeOfSpecialCasedTernaryOperator(
            receiverType!,
            argumentsInfo[0].actualType,
            argumentsInfo[1].actualType,
          ),
        );
      }
    }

    // Check for and remove duplicated named arguments.
    Map<String, NamedExpression> seenNames = <String, NamedExpression>{};
    for (_ArgumentInfo argumentInfo in argumentsInfo) {
      Argument argument = argumentInfo.argument;
      switch (argument) {
        case NamedArgument():
          NamedExpression namedExpression = argument.namedExpression;
          String name = namedExpression.name;
          if (seenNames.containsKey(name)) {
            argumentInfo.isDuplicateNamed = true;
            NamedExpression prevNamedExpression = seenNames[name]!;
            prevNamedExpression.value = problemReporting.wrapInProblem(
              compilerContext: compilerContext,
              expression: _createDuplicateExpression(
                prevNamedExpression.fileOffset,
                prevNamedExpression.value,
                namedExpression.value,
              ),
              message: diag.duplicatedNamedArgument.withArguments(name: name),
              fileUri: fileUri,
              fileOffset: namedExpression.fileOffset,
              length: name.length,
            )..parent = prevNamedExpression;
          } else {
            seenNames[name] = namedExpression;
          }
        case PositionalArgument():
          break;
      }
    }

    // Before choosing the final types, we perform coercion and feed the
    // resulting types back into the type inference via constraint generation.
    for (_ArgumentInfo paramInfo in argumentsInfo) {
      ExpressionInferenceResult argumentResult = new ExpressionInferenceResult(
        paramInfo.actualType,
        paramInfo.argument.expression,
      );
      if (paramInfo.coerceExpression) {
        DartType expectedType = paramInfo.computeInferredFormalType(
          instantiator,
        );
        ExpressionInferenceResult? coercionResult =
            coerceExpressionForAssignment(
              expectedType,
              argumentResult,
              isVoidAllowed: expectedType is VoidType,
              treeNodeForTesting: argumentResult.expression,
            );

        if (coercionResult != null) {
          argumentResult = coercionResult;
          paramInfo.argument.expression = argumentResult.expression;

          // Feed the coercion result back to the inference.
          gatherer?.tryConstrainLower(
            paramInfo.formalType,
            argumentResult.inferredType,
            treeNodeForTesting: actualArguments,
          );
        }
      }
      paramInfo.argumentInferenceResult = argumentResult;
    }

    if (inferenceNeeded) {
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
        gatherer!.computeConstraints(),
        calleeTypeParameters,
        inferredTypes!,
        inferenceUsingBoundsIsEnabled:
            libraryFeatures.inferenceUsingBounds.isEnabled,
        dataForTesting: dataForTesting,
        treeNodeForTesting: actualArguments,
        typeOperations: cfeOperations,
      );
      assert(
        inferredTypes.every((type) => isKnown(type)),
        "Unknown type(s) in inferred types: $inferredTypes.",
      );
      assert(
        inferredTypes.every((type) => !hasPromotedTypeParameter(type)),
        "Promoted type parameter(s) in inferred types: $inferredTypes.",
      );
      instantiator = new FunctionTypeInstantiator.fromIterables(
        calleeTypeParameters,
        inferredTypes,
      );
      if (dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        assert(actualArguments.fileOffset != TreeNode.noOffset);
        dataForTesting!
                .typeInferenceResult
                .inferredTypeArguments[actualArguments] =
            inferredTypes;
      }
    }

    LocatedMessage? argMessage = problemReporting.checkArgumentsForType(
      function: calleeType,
      explicitTypeArguments: typeArguments,
      arguments: actualArguments,
      fileUri: fileUri,
      fileOffset: offset,
    );
    if (argMessage != null) {
      var (List<Expression> positional, List<NamedExpression> named) =
          argumentsInfo.computeArguments();
      return new WrapInProblemInferenceResult(
        message: argMessage,
        problemReporting: problemReporting,
        compilerContext: compilerContext,
        isInapplicable: true,
        hoistedArguments: localHoistedExpressions,
        positional: positional,
        named: named,
      );
    } else {
      for (_ArgumentInfo argumentInfo in argumentsInfo) {
        ExpressionInferenceResult argumentResultToCheck =
            argumentInfo.argumentInferenceResult!;
        DartType expectedType = argumentInfo.computeInferredFormalType(
          instantiator,
        );
        argumentResultToCheck = reportAssignabilityErrors(
          expectedType,
          argumentResultToCheck,
          isVoidAllowed: expectedType is VoidType,
          isCoercionAllowed: argumentInfo.coerceExpression,
          errorTemplate: diag.argumentTypeNotAssignable,
        );

        argumentInfo.argument.expression = argumentResultToCheck.expression;
      }
    }

    DartType inferredType;
    if (instantiator != null) {
      calleeType =
          instantiator.substitute(calleeType.withoutTypeParameters)
              as FunctionType;
    }
    inferredType = calleeType.returnType;
    assert(
      !containsFreeStructuralParameters(inferredType),
      "Inferred return type $inferredType contains free variables. "
      "Inferred function type: $calleeType.",
    );

    var (List<Expression> positional, List<NamedExpression> named) =
        argumentsInfo.computeArguments();
    return new SuccessfulInferenceResult(
      inferredType: inferredType,
      functionType: calleeType,
      typeArguments: inferredTypes ?? explicitTypeArguments ?? [],
      positional: positional,
      named: named,
      hoistedArguments: localHoistedExpressions,
      inferredReceiverType: receiverType,
    );
  }

  FunctionType inferLocalFunction(
    InferenceVisitor visitor,
    FunctionNode function,
    DartType? typeContext,
    int fileOffset,
    DartType? returnContext,
  ) {
    bool hasImplicitReturnType = false;
    if (returnContext == null) {
      hasImplicitReturnType = true;
      returnContext = const UnknownType();
    }

    // Let `<T0, ..., Tn>` be the set of type parameters of the closure (with
    // `n`=0 if there are no type parameters).
    List<TypeParameter> functionTypeParameters = function.typeParameters;

    // Let `(P0 x0, ..., Pm xm)` be the set of formal parameters of the closure
    // (including required, positional optional, and named optional parameters).
    // If any type `Pi` is missing, denote it as `_`.
    List<VariableDeclaration> formals = [
      ...function.positionalParameters,
      ...function.namedParameters,
    ];

    // Let `B` denote the closure body.  If `B` is an expression function body
    // (`=> e`), treat it as equivalent to a block function body containing a
    // single `return` statement (`{ return e; }`).

    // Attempt to match `K` as a function type compatible with the closure (that
    // is, one having n type parameters and a compatible set of formal
    // parameters).  If there is a successful match, let `<S0, ..., Sn>` be the
    // set of matched type parameters and `(Q0, ..., Qm)` be the set of matched
    // formal parameter types, and let `N` be the return type.
    FunctionTypeInstantiator? instantiator;
    List<DartType?> formalTypesFromContext = new List<DartType?>.filled(
      formals.length,
      null,
    );
    if (typeContext is FunctionType &&
        typeContext.typeParameters.length == functionTypeParameters.length) {
      for (int i = 0; i < formals.length; i++) {
        if (i < function.positionalParameters.length) {
          formalTypesFromContext[i] = getPositionalParameterType(
            typeContext,
            i,
          );
        } else {
          formalTypesFromContext[i] = getNamedParameterType(
            typeContext,
            formals[i].name!,
          );
        }
      }
      returnContext = typeContext.returnType;

      // Let `[T/S]` denote the type substitution where each `Si` is replaced
      // with the corresponding `Ti`.
      instantiator = new FunctionTypeInstantiator.fromIterables(
        typeContext.typeParameters,
        [
          for (TypeParameter parameter in functionTypeParameters)
            new TypeParameterType.withDefaultNullability(parameter),
        ],
      );
    } else {
      // If the match is not successful because  `K` is `_`, let all `Si`, all
      // `Qi`, and `N` all be `_`.

      // If the match is not successful for any other reason, this will result
      // in a type error, so the implementation is free to choose the best
      // error recovery path.
      instantiator = null;
    }

    // Define `Ri` as follows: if `Pi` is not `_`, let `Ri` be `Pi`.
    // Otherwise, if `Qi` is not `_`, let `Ri` be the greatest closure of
    // `Qi[T/S]` with respect to `?`.  Otherwise, let `Ri` be `dynamic`.
    for (int i = 0; i < formals.length; i++) {
      InternalExpressionVariable formal =
          formals[i] as InternalExpressionVariable;
      if (formal.isImplicitlyTyped) {
        DartType inferredType;
        if (formalTypesFromContext[i] != null) {
          inferredType = computeGreatestClosure2(
            instantiator?.substitute(formalTypesFromContext[i]!) ??
                // Coverage-ignore(suite): Not run.
                formalTypesFromContext[i]!,
          );
          if (typeSchemaEnvironment.isSubtypeOf(
            inferredType,
            const NullType(),
          )) {
            inferredType = coreTypes.objectRawType(Nullability.nullable);
          }
        } else {
          inferredType = const DynamicType();
        }
        formal.type = demoteTypeInLibrary(inferredType);
        if (dataForTesting != null) {
          // Coverage-ignore-block(suite): Not run.
          dataForTesting!.typeInferenceResult.inferredVariableTypes[formal] =
              formal.type;
        }
      }

      // If a parameter is a positional or named optional parameter and its
      // type is potentially non-nullable, it should have an initializer.
      bool isOptionalPositional =
          function.requiredParameterCount <= i &&
          i < function.positionalParameters.length;
      bool isOptionalNamed =
          i >= function.positionalParameters.length && !formal.isRequired;
      if ((isOptionalPositional || isOptionalNamed) &&
          formal.type.isPotentiallyNonNullable &&
          !formal.hasDeclaredInitializer) {
        libraryBuilder.addProblem(
          diag.optionalNonNullableWithoutInitializerError.withArguments(
            parameterName: formal.cosmeticName!,
            parameterType: formal.type,
          ),
          formal.fileOffset,
          formal.cosmeticName!.length,
          fileUri,
        );
        formal.isErroneouslyInitialized = true;
      }
    }

    List<VariableDeclaration> positionalParameters =
        function.positionalParameters;
    for (int i = 0; i < positionalParameters.length; i++) {
      VariableDeclaration parameter = positionalParameters[i];
      // TODO(62401): Remove the cast when the flow analysis uses
      // [InternalExpressionVariable]s.
      ExpressionVariable parameterAstVariable =
          (parameter as InternalExpressionVariable).astVariable;
      flowAnalysis.declare(
        parameterAstVariable,
        new SharedTypeView(parameterAstVariable.type),
        initialized: true,
      );
      inferMetadata(visitor, parameter);
      if (parameter.initializer != null) {
        ExpressionInferenceResult initializerResult = visitor.inferExpression(
          parameter.initializer!,
          parameter.type,
        );
        parameter.initializer = initializerResult.expression
          ..parent = parameter;
      }
    }
    for (VariableDeclaration parameter in function.namedParameters) {
      // TODO(62401): Remove the cast when the flow analysis uses
      // [InternalExpressionVariable]s.
      ExpressionVariable parameterAstVariable =
          (parameter as InternalExpressionVariable).astVariable;
      flowAnalysis.declare(
        parameterAstVariable,
        new SharedTypeView(parameterAstVariable.type),
        initialized: true,
      );
      inferMetadata(visitor, parameter);
      if (parameter.initializer != null) {
        ExpressionInferenceResult initializerResult = visitor.inferExpression(
          parameter.initializer!,
          parameter.type,
        );
        parameter.initializer = initializerResult.expression
          ..parent = parameter;
      }
    }

    for (VariableDeclaration parameter in function.namedParameters) {
      InternalExpressionVariable formal =
          parameter as InternalExpressionVariable;
      // Required named parameters shouldn't have initializers.
      if (formal.isRequired && formal.hasDeclaredInitializer) {
        libraryBuilder.addProblem(
          diag.requiredNamedParameterHasDefaultValueError.withArguments(
            parameterName: formal.cosmeticName!,
          ),
          formal.fileOffset,
          formal.cosmeticName!.length,
          fileUri,
        );
      }
    }

    // Let `N'` be `N[T/S]`.  The [ClosureContext] constructor will adjust
    // accordingly if the closure is declared with `async`, `async*`, or
    // `sync*`.
    if (returnContext is! UnknownType) {
      returnContext = instantiator?.substitute(returnContext) ?? returnContext;
    }

    // Apply type inference to `B` in return context `N’`, with any references
    // to `xi` in `B` having type `Pi`.  This produces `B’`.
    bool needToSetReturnType = hasImplicitReturnType;
    ClosureContext closureContext = new ClosureContext(
      this,
      function.asyncMarker,
      returnContext,
      needToSetReturnType,
    );
    StatementInferenceResult bodyResult = visitor.inferStatement(
      function.body!,
      closureContext,
    );

    // If the closure is declared with `async*` or `sync*`, let `M` be the
    // least upper bound of the types of the `yield` expressions in `B’`, or
    // `void` if `B’` contains no `yield` expressions.  Otherwise, let `M` be
    // the least upper bound of the types of the `return` expressions in `B’`,
    // or `void` if `B’` contains no `return` expressions.
    if (needToSetReturnType) {
      DartType inferredReturnType = closureContext.inferReturnType(
        this,
        hasImplicitReturn: flowAnalysis.isReachable,
      );

      // Then the result of inference is `<T0, ..., Tn>(R0 x0, ..., Rn xn) B`
      // with type `<T0, ..., Tn>(R0, ..., Rn) -> M’` (with some of the `Ri` and
      // `xi` denoted as optional or named parameters, if appropriate).
      function.returnType = inferredReturnType;
    }
    bodyResult = closureContext.handleImplicitReturn(
      this,
      function.body!,
      bodyResult,
      fileOffset,
    );
    function.emittedValueType = closureContext.emittedValueType;

    if (bodyResult.hasChanged) {
      function.body = bodyResult.statement..parent = function;
    }
    return function.computeFunctionType(Nullability.nonNullable);
  }

  /// Infers the [annotations].
  ///
  /// If [indices] is provided, only the annotations at the given indices are
  /// inferred. Otherwise all annotations are inferred.
  void inferMetadata(
    InferenceVisitor visitor,
    Annotatable annotatable, {
    List<int>? indices,
  }) {
    List<Expression> annotations = annotatable.annotations;
    if (indices != null) {
      for (int index in indices) {
        _inferMetadataAt(visitor, annotatable, annotations, index);
      }
    } else {
      for (int index = 0; index < annotations.length; index++) {
        _inferMetadataAt(visitor, annotatable, annotations, index);
      }
    }
  }

  void _inferMetadataAt(
    InferenceVisitor visitor,
    Annotatable annotatable,
    List<Expression> annotations,
    int index,
  ) {
    ExpressionInferenceResult result = visitor.inferExpression(
      annotations[index],
      const UnknownType(),
    );
    annotations[index] = result.expression..parent = annotatable;
  }

  StaticInvocation createExtensionInvocation({
    required int invocationOffset,
    required int argumentsOffset,
    required ObjectAccessTarget target,
    required Expression receiver,
    required List<DartType> explicitOrInferredTypeArguments,
    required List<Expression> positionalArguments,
    required List<NamedExpression> namedArguments,
  }) {
    assert(
      target.isExtensionMember ||
          target.isNullableExtensionMember ||
          target.isExtensionTypeMember ||
          target.isNullableExtensionTypeMember,
    );
    Procedure procedure = target.member as Procedure;
    Arguments extensionInvocationArguments = new Arguments(
      [receiver, ...positionalArguments],
      named: namedArguments,
      types: [
        ...target.receiverTypeArguments,
        ...explicitOrInferredTypeArguments,
      ],
    )..fileOffset = argumentsOffset;
    return createStaticInvocation(
      procedure,
      extensionInvocationArguments,
      fileOffset: invocationOffset,
    );
  }

  ExpressionInferenceResult _inferDynamicInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isImplicitCall,
  }) {
    InvocationInferenceResult result = inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      const InvocationTargetDynamicType(),
      typeArguments,
      arguments,
      hoistedExpressions: hoistedExpressions,
      receiverType: const DynamicType(),
      isImplicitCall: isImplicitCall,
    );
    assert(name != equalsName);
    Expression expression =
        new DynamicInvocation(
            DynamicAccessKind.Dynamic,
            receiver,
            name,
            createArgumentsFromInternalNode(
              result.typeArguments,
              result.positional,
              result.named,
              arguments,
            ),
          )
          ..isImplicitCall = isImplicitCall
          ..fileOffset = fileOffset;
    return new ExpressionInferenceResult(
      result.inferredType,
      result.applyResult(expression),
    );
  }

  ExpressionInferenceResult _inferNeverInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isImplicitCall,
  }) {
    InvocationInferenceResult result = inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      const InvocationTargetNeverType(),
      typeArguments,
      arguments,
      hoistedExpressions: hoistedExpressions,
      receiverType: receiverType,
      isImplicitCall: isImplicitCall,
    );
    assert(name != equalsName);
    Expression expression = new DynamicInvocation(
      DynamicAccessKind.Never,
      receiver,
      name,
      createArgumentsFromInternalNode(
        result.typeArguments,
        result.positional,
        result.named,
        arguments,
      ),
    )..fileOffset = fileOffset;
    return new ExpressionInferenceResult(
      const NeverType.nonNullable(),
      result.applyResult(expression),
    );
  }

  ExpressionInferenceResult _inferMissingInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    ObjectAccessTarget target,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isExpressionInvocation,
    required bool isImplicitCall,
    Name? implicitInvocationPropertyName,
  }) {
    assert(target.isMissing || target.isAmbiguous);
    InvocationInferenceResult inferenceResult = inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      const InvocationTargetInvalidType(),
      typeArguments,
      arguments,
      hoistedExpressions: hoistedExpressions,
      receiverType: receiverType,
      isImplicitCall: isExpressionInvocation || isImplicitCall,
    );
    Expression error = createMissingMethodInvocation(
      fileOffset,
      receiverType,
      name,
      receiver: receiver,
      arguments: createArgumentsFromInternalNode(
        // TODO(johnniwinther): Should these be the inferred type arguments?
        typeArguments?.types ?? [],
        inferenceResult.positional,
        inferenceResult.named,
        arguments,
      ),
      isExpressionInvocation: isExpressionInvocation,
      implicitInvocationPropertyName: implicitInvocationPropertyName,
      extensionAccessCandidates: target.isAmbiguous ? target.candidates : null,
    );
    Expression replacementError = inferenceResult.applyResult(error);
    assert(name != equalsName);
    // TODO(johnniwinther): Use InvalidType instead.
    return new ExpressionInferenceResult(const DynamicType(), replacementError);
  }

  ExpressionInferenceResult _inferExtensionInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    ObjectAccessTarget target,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isImplicitCall,
  }) {
    assert(
      target.isExtensionMember ||
          target.isNullableExtensionMember ||
          target.isExtensionTypeMember ||
          target.isNullableExtensionTypeMember,
    );
    DartType calleeType = target.getGetterType(this);
    InvocationTargetType invocationTargetType = target.getFunctionType(this);

    if (target.declarationMethodKind == ClassMemberKind.Getter) {
      StaticInvocation staticInvocation = createExtensionInvocation(
        invocationOffset: fileOffset,
        argumentsOffset: fileOffset,
        target: target,
        receiver: receiver,
        explicitOrInferredTypeArguments: [],
        positionalArguments: [],
        namedArguments: [],
      );
      ExpressionInferenceResult result = inferMethodInvocation(
        visitor,
        fileOffset,
        staticInvocation,
        calleeType,
        callName,
        typeArguments,
        arguments,
        typeContext,
        hoistedExpressions: hoistedExpressions,
        isExpressionInvocation: false,
        isImplicitCall: true,
        implicitInvocationPropertyName: name,
      );

      if (target.isNullable) {
        // Handles cases like:
        //   C? c;
        //   c();
        // where there is an extension on C defined as:
        //   extension on C {
        //     void Function() get call => () {};
        //   }
        List<LocatedMessage>? context = getWhyNotPromotedContext(
          flowAnalysis.whyNotPromoted(receiver)(),
          staticInvocation,
          // Coverage-ignore(suite): Not run.
          (type) => !type.isPotentiallyNullable,
        );
        result = wrapExpressionInferenceResultInProblem(
          result,
          diag.nullableExpressionCallError.withArguments(type: receiverType),
          fileOffset,
          noLength,
          context: context,
        );
      }

      return result;
    } else {
      InvocationInferenceResult result = inferInvocation(
        visitor,
        typeContext,
        fileOffset,
        invocationTargetType,
        typeArguments,
        arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: receiverType,
        isImplicitCall: isImplicitCall,
      );
      problemReporting.checkBoundsInStaticInvocation(
        problemReportingHelper: problemReportingHelper,
        libraryFeatures: libraryFeatures,
        targetName: name.text,
        typeEnvironment: typeSchemaEnvironment,
        fileUri: fileUri,
        fileOffset: fileOffset,
        hasInferredTypeArguments: typeArguments == null,
        typeParameters: target.getTypeParameters(),
        explicitOrInferredTypeArguments: result.typeArguments,
      );

      StaticInvocation staticInvocation = createExtensionInvocation(
        invocationOffset: fileOffset,
        argumentsOffset: arguments.fileOffset,
        target: target,
        receiver: receiver,
        explicitOrInferredTypeArguments: result.typeArguments,
        positionalArguments: result.positional,
        namedArguments: result.named,
      );

      Expression replacement = result.applyResult(
        staticInvocation,
        extensionReceiverType: receiverType,
      );
      if (target.isNullable) {
        List<LocatedMessage>? context = getWhyNotPromotedContext(
          flowAnalysis.whyNotPromoted(receiver)(),
          staticInvocation,
          // Coverage-ignore(suite): Not run.
          (type) => !type.isPotentiallyNullable,
        );
        if (isImplicitCall) {
          // Handles cases like:
          //   int? i;
          //   i();
          // where there is an extension:
          //   extension on int {
          //     void call() {}
          //   }
          replacement = problemReporting.wrapInProblem(
            compilerContext: compilerContext,
            expression: replacement,
            message: diag.nullableExpressionCallError.withArguments(
              type: receiverType,
            ),
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: noLength,
            context: context,
          );
        } else {
          // Handles cases like:
          //   int? i;
          //   i.methodOnNonNullInt();
          // where `methodOnNonNullInt` is declared in an extension:
          //   extension on int {
          //     void methodOnNonNullInt() {}
          //   }
          replacement = problemReporting.wrapInProblem(
            compilerContext: compilerContext,
            expression: replacement,
            message: diag.nullableMethodCallError.withArguments(
              methodName: name.text,
              receiverType: receiverType,
            ),
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: name.text.length,
            context: context,
          );
        }
      }
      return new ExpressionInferenceResult(result.inferredType, replacement);
    }
  }

  ExpressionInferenceResult _inferFunctionInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    ObjectAccessTarget target,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isImplicitCall,
  }) {
    assert(target.isCallFunction || target.isNullableCallFunction);
    InvocationTargetType invocationTargetType = target.getFunctionType(this);
    InvocationInferenceResult result = inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      invocationTargetType,
      typeArguments,
      arguments,
      hoistedExpressions: hoistedExpressions,
      receiverType: receiverType,
      isImplicitCall: isImplicitCall,
    );
    Expression? expression;
    String? localName;

    DartType inferredFunctionType = result.functionType;
    if (result.isInapplicable) {
      // This was a function invocation whose arguments didn't match
      // the parameters.
      expression = new FunctionInvocation(
        FunctionAccessKind.Inapplicable,
        receiver,
        createArgumentsFromInternalNode(
          result.typeArguments,
          result.positional,
          result.named,
          arguments,
        ),
        functionType: null,
      )..fileOffset = fileOffset;
    } else if (receiver is VariableGet) {
      ExpressionVariable variable = receiver.variable;
      TreeNode? parent = variable.parent;
      if (parent is FunctionDeclaration) {
        assert(
          invocationTargetType is InvocationTargetFunctionType,
          "Unknown function type for local function invocation.",
        );
        localName = variable.cosmeticName!;
        expression = new LocalFunctionInvocation(
          variable as VariableDeclaration,
          createArgumentsFromInternalNode(
            result.typeArguments,
            result.positional,
            result.named,
            arguments,
          ),
          functionType: inferredFunctionType as FunctionType,
        )..fileOffset = receiver.fileOffset;
      }
    }
    expression ??= new FunctionInvocation(
      target.isNullableCallFunction
          ? FunctionAccessKind.Nullable
          : invocationTargetType.functionAccessKind,
      receiver,
      createArgumentsFromInternalNode(
        result.typeArguments,
        result.positional,
        result.named,
        arguments,
      ),
      functionType: switch (invocationTargetType) {
        InvocationTargetFunctionType() => inferredFunctionType as FunctionType,
        _ => null,
      },
    )..fileOffset = fileOffset;

    _checkBoundsInFunctionInvocation(
      invocationTargetType.computeFunctionTypeForInference(
        result.typeArguments,
        arguments,
      ),
      localName,
      result.typeArguments,
      arguments,
      fileOffset,
      hasInferredTypeArguments: typeArguments == null,
    );

    Expression replacement = result.applyResult(expression);
    if (target.isNullableCallFunction) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        flowAnalysis.whyNotPromoted(receiver)(),
        expression,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      if (isImplicitCall) {
        // Handles cases like:
        //   void Function()? f;
        //   f();
        replacement = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: replacement,
          message: diag.nullableExpressionCallError.withArguments(
            type: receiverType,
          ),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: noLength,
          context: context,
        );
      } else {
        // Handles cases like:
        //   void Function()? f;
        //   f.call();
        replacement = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: replacement,
          message: diag.nullableMethodCallError.withArguments(
            methodName: callName.text,
            receiverType: receiverType,
          ),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: callName.text.length,
          context: context,
        );
      }
    }
    // TODO(johnniwinther): Check that type arguments against the bounds.
    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  FunctionType _computeFunctionTypeForArguments(
    ActualArguments arguments,
    DartType type,
  ) {
    return new FunctionType(
      new List<DartType>.filled(arguments.positionalCount, type),
      type,
      Nullability.nonNullable,
      namedParameters: arguments.namedCount > 0
          ? arguments.argumentList
                .whereType<NamedArgument>()
                .map((a) => new NamedType(a.name, type))
                .toList()
          : [],
    );
  }

  /// Returns `true` if [arguments] don't apply to [signature].
  ///
  /// This is used to determine whether an invocation on `dynamic` matches the
  /// resolved target on `Object`.
  bool _isInvalidDynamicTarget(
    FunctionNode signature,
    ActualArguments arguments,
  ) {
    if (arguments.positionalCount < signature.requiredParameterCount ||
        arguments.positionalCount > signature.positionalParameters.length) {
      return true;
    }
    if (arguments.namedCount > 0) {
      for (Argument argument in arguments.argumentList) {
        switch (argument) {
          case NamedArgument():
            if (!signature.namedParameters.any(
              // Coverage-ignore(suite): Not run.
              (declaration) => declaration.name == argument.name,
            )) {
              return true;
            }
          case PositionalArgument():
            break;
        }
      }
    }
    return false;
  }

  ExpressionInferenceResult _inferInstanceMethodInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    ObjectAccessTarget target,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isImplicitCall,
    required bool isSpecialCasedBinaryOperator,
    required bool isSpecialCasedTernaryOperator,
  }) {
    assert(
      target.isInstanceMember ||
          target.isObjectMember ||
          target.isNullableInstanceMember,
    );
    Procedure? method = target.classMember as Procedure;
    assert(
      method.kind == ProcedureKind.Method ||
          // Coverage-ignore(suite): Not run.
          method.kind == ProcedureKind.Operator,
      "Unexpected instance method $method",
    );
    Name methodName = method.name;
    if (receiverType == const DynamicType() &&
        _isInvalidDynamicTarget(method.function, arguments)) {
      target = const ObjectAccessTarget.dynamic();
      method = null;
    }

    DartType calleeType = target.getGetterType(this);
    InvocationTargetType invocationTargetType = target.getFunctionType(this);

    bool contravariantCheck = false;
    if (receiver is! ThisExpression &&
        method != null &&
        returnedTypeParametersOccurNonCovariantly(
          method.enclosingTypeDeclaration!,
          method.function.returnType,
        )) {
      contravariantCheck = true;
    }
    InvocationInferenceResult result = inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      invocationTargetType,
      typeArguments,
      arguments,
      hoistedExpressions: hoistedExpressions,
      receiverType: receiverType,
      isImplicitCall: isImplicitCall,
      isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
      isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator,
    );

    Expression expression;
    DartType inferredFunctionType = result.functionType;
    if (target.isDynamic) {
      // This was an Object member invocation whose arguments didn't match
      // the parameters.
      expression =
          new DynamicInvocation(
              DynamicAccessKind.Dynamic,
              receiver,
              methodName,
              createArgumentsFromInternalNode(
                result.typeArguments,
                result.positional,
                result.named,
                arguments,
              ),
            )
            ..isImplicitCall = isImplicitCall
            ..fileOffset = fileOffset;
    } else if (result.isInapplicable) {
      // This was a method invocation whose arguments didn't match
      // the parameters.
      expression = new InstanceInvocation(
        InstanceAccessKind.Inapplicable,
        receiver,
        methodName,
        createArgumentsFromInternalNode(
          result.typeArguments,
          result.positional,
          result.named,
          arguments,
        ),
        functionType: _computeFunctionTypeForArguments(
          arguments,
          const InvalidType(),
        ),
        interfaceTarget: method!,
      )..fileOffset = fileOffset;
    } else {
      assert(
        inferredFunctionType is FunctionType &&
            invocationTargetType is InvocationTargetFunctionType,
        "No function type found for $receiver.$methodName ($target) on "
        "$receiverType",
      );
      InstanceAccessKind kind;
      switch (target.kind) {
        case ObjectAccessTargetKind.instanceMember:
          kind = InstanceAccessKind.Instance;
          break;
        case ObjectAccessTargetKind.nullableInstanceMember:
          kind = InstanceAccessKind.Nullable;
          break;
        case ObjectAccessTargetKind.objectMember:
          kind = InstanceAccessKind.Object;
          break;
        // Coverage-ignore(suite): Not run.
        default:
          throw new UnsupportedError('Unexpected target kind $target');
      }
      expression = new InstanceInvocation(
        kind,
        receiver,
        methodName,
        createArgumentsFromInternalNode(
          result.typeArguments,
          result.positional,
          result.named,
          arguments,
        ),
        functionType: inferredFunctionType as FunctionType,
        interfaceTarget: method!,
      )..fileOffset = fileOffset;
    }
    Expression replacement;
    if (contravariantCheck) {
      // TODO(johnniwinther): Merge with the replacement computation below.
      replacement = new AsExpression(expression, result.inferredType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..fileOffset = fileOffset;
    } else {
      replacement = expression;
    }

    _checkBoundsInMethodInvocation(
      target,
      receiverType,
      calleeType,
      methodName,
      result.typeArguments,
      arguments,
      fileOffset,
      hasInferredTypeArguments: typeArguments == null,
    );

    replacement = result.applyResult(replacement);
    if (target.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        flowAnalysis.whyNotPromoted(receiver)(),
        expression,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      if (isImplicitCall) {
        // Handles cases like:
        //   C? c;
        //   c();
        // Where C is defined as:
        //   class C {
        //     void call();
        //   }
        replacement = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: replacement,
          message: diag.nullableExpressionCallError.withArguments(
            type: receiverType,
          ),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: noLength,
          context: context,
        );
      } else {
        // Handles cases like:
        //   int? i;
        //   i.abs();
        replacement = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: replacement,
          message: diag.nullableMethodCallError.withArguments(
            methodName: methodName.text,
            receiverType: receiverType,
          ),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: methodName.text.length,
          context: context,
        );
      }
    }

    return new ExpressionInferenceResult(result.inferredType, replacement);
  }

  ExpressionInferenceResult _finishFieldGetterInvocation(
    InferenceVisitor visitor, {
    required int fileOffset,
    required Expression receiver,
    required DartType receiverType,
    required ObjectAccessTarget target,
    required Member member,
    required DartType declaredMemberType,
    required DartType calleeType,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required DartType typeContext,
    required List<VariableDeclaration>? hoistedExpressions,
    required bool isExpressionInvocation,
  }) {
    Expression originalReceiver = receiver;

    List<VariableDeclaration>? locallyHoistedExpressions;
    if (hoistedExpressions == null) {
      hoistedExpressions = locallyHoistedExpressions = <VariableDeclaration>[];
    }
    if (arguments.positionalCount > 0 || arguments.namedCount > 0) {
      receiver = _hoist(receiver, receiverType, hoistedExpressions);
    }

    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted;
    if (target.isNullable) {
      // We won't report the error until later (after we have an
      // invocationResult), but we need to gather "why not promoted" info now,
      // before we tell flow analysis about the property get.
      whyNotPromoted = flowAnalysis.whyNotPromoted(originalReceiver);
    }

    Name originalName = member.name;
    Member originalTarget = member;
    InstanceAccessKind kind;
    switch (target.kind) {
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
        // If we ever have function typed fields/getters on Object, this case
        // can be triggered, if call with inapplicable arguments.
        throw new UnsupportedError('Unexpected target kind $target');
    }
    InstanceGet originalPropertyGet = new InstanceGet(
      kind,
      receiver,
      originalName,
      resultType: calleeType,
      interfaceTarget: originalTarget,
    )..fileOffset = fileOffset;
    var (
      SharedTypeView? wrappedPromotedType,
      ExpressionInfo? expressionInfo,
    ) = flowAnalysis.propertyGet(
      computePropertyTarget(originalReceiver),
      originalName.text,
      originalTarget,
      new SharedTypeView(calleeType),
    );
    flowAnalysis.storeExpressionInfo(originalPropertyGet, expressionInfo);
    DartType? promotedCalleeType = wrappedPromotedType?.unwrapTypeView();
    originalPropertyGet.resultType = calleeType;
    Expression propertyGet = originalPropertyGet;
    if (receiver is! ThisExpression &&
        calleeType is! DynamicType &&
        returnedTypeParametersOccurNonCovariantly(
          member.enclosingTypeDeclaration!,
          declaredMemberType,
        )) {
      propertyGet = new AsExpression(propertyGet, calleeType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..fileOffset = fileOffset;
    }

    if (promotedCalleeType != null) {
      propertyGet = new AsExpression(propertyGet, promotedCalleeType)
        ..isUnchecked = true
        ..fileOffset = fileOffset;
      calleeType = promotedCalleeType;
    }

    if (isExpressionInvocation) {
      Expression error = problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.implicitCallOfNonMethod.withArguments(type: receiverType),
        fileUri: fileUri,
        fileOffset: fileOffset,
        length: noLength,
      );
      return new ExpressionInferenceResult(const InvalidType(), error);
    }

    ExpressionInferenceResult invocationResult = inferMethodInvocation(
      visitor,
      arguments.fileOffset,
      propertyGet,
      calleeType,
      callName,
      typeArguments,
      arguments,
      typeContext,
      isExpressionInvocation: false,
      isImplicitCall: true,
      hoistedExpressions: hoistedExpressions,
      implicitInvocationPropertyName: member.name,
    );

    if (target.isNullable) {
      // Handles cases like:
      //   C? c;
      //   c.foo();
      // Where C is defined as:
      //   class C {
      //     void Function() foo;
      //     C(this.foo);
      //   }
      // TODO(paulberry): would it be better to report NullableMethodCallError
      // in this scenario?
      List<LocatedMessage>? context = getWhyNotPromotedContext(
        whyNotPromoted!(),
        invocationResult.expression,
        // Coverage-ignore(suite): Not run.
        (type) => !type.isPotentiallyNullable,
      );
      invocationResult = wrapExpressionInferenceResultInProblem(
        invocationResult,
        diag.nullableExpressionCallError.withArguments(type: receiverType),
        fileOffset,
        noLength,
        context: context,
      );
    }

    if (!libraryBuilder
        .loader
        .target
        .backendTarget
        .supportsExplicitGetterCalls) {
      // TODO(johnniwinther): Remove this when dart2js/ddc supports explicit
      //  getter calls.
      Expression nullAwareAction = invocationResult.expression;
      if (nullAwareAction is InstanceInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
          invocationResult.inferredType,
          new InstanceGetterInvocation(
            originalPropertyGet.kind,
            receiver,
            originalName,
            nullAwareAction.arguments,
            interfaceTarget: originalTarget,
            functionType: nullAwareAction.functionType,
          )..fileOffset = nullAwareAction.fileOffset,
        );
      } else if (nullAwareAction is DynamicInvocation &&
          // Coverage-ignore(suite): Not run.
          nullAwareAction.receiver == originalPropertyGet) {
        // Coverage-ignore-block(suite): Not run.
        invocationResult = new ExpressionInferenceResult(
          invocationResult.inferredType,
          new InstanceGetterInvocation(
            originalPropertyGet.kind,
            receiver,
            originalName,
            nullAwareAction.arguments,
            interfaceTarget: originalTarget,
            functionType: null,
          )..fileOffset = nullAwareAction.fileOffset,
        );
      } else if (nullAwareAction is FunctionInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
          invocationResult.inferredType,
          new InstanceGetterInvocation(
            originalPropertyGet.kind,
            receiver,
            originalName,
            nullAwareAction.arguments,
            interfaceTarget: originalTarget,
            functionType: nullAwareAction.functionType,
          )..fileOffset = nullAwareAction.fileOffset,
        );
      }
    }
    invocationResult = _insertHoistedExpression(
      invocationResult,
      locallyHoistedExpressions,
    );
    return new ExpressionInferenceResult(
      invocationResult.inferredType,
      invocationResult.expression,
    );
  }

  ExpressionInferenceResult _inferInstanceGetterInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    ObjectAccessTarget target,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isExpressionInvocation,
  }) {
    assert(
      target.isInstanceMember ||
          target.isObjectMember ||
          target.isNullableInstanceMember,
    );
    Procedure? getter = target.classMember as Procedure;
    assert(getter.kind == ProcedureKind.Getter);

    if (receiverType == const DynamicType() &&
        _isInvalidDynamicTarget(getter.function, arguments)) {
      target = const ObjectAccessTarget.dynamic();
    }

    DartType calleeType = target.getGetterType(this);

    return _finishFieldGetterInvocation(
      visitor,
      fileOffset: fileOffset,
      receiver: receiver,
      receiverType: receiverType,
      target: target,
      member: getter,
      declaredMemberType: getter.function.returnType,
      calleeType: calleeType,
      typeArguments: typeArguments,
      arguments: arguments,
      typeContext: typeContext,
      hoistedExpressions: hoistedExpressions,
      isExpressionInvocation: isExpressionInvocation,
    );
  }

  Expression _hoist(
    Expression expression,
    DartType type,
    List<VariableDeclaration>? hoistedExpressions,
  ) {
    if (hoistedExpressions != null &&
        expression is! ThisExpression &&
        expression is! FunctionExpression) {
      VariableDeclaration variable = createVariable(expression, type);
      hoistedExpressions.add(variable);
      return createVariableGet(variable);
    }
    return expression;
  }

  ExpressionInferenceResult _insertHoistedExpression(
    ExpressionInferenceResult result,
    List<VariableDeclaration>? hoistedExpressions,
  ) {
    if (hoistedExpressions != null && hoistedExpressions.isNotEmpty) {
      Expression expression = result.expression;
      for (int index = hoistedExpressions.length - 1; index >= 0; index--) {
        expression = createLet(hoistedExpressions[index], expression);
      }
      return new ExpressionInferenceResult(result.inferredType, expression);
    }
    return result;
  }

  ExpressionInferenceResult _inferInstanceFieldInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    ObjectAccessTarget target,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext,
    List<VariableDeclaration>? hoistedExpressions, {
    required bool isExpressionInvocation,
  }) {
    assert(
      target.isInstanceMember ||
          target.isObjectMember ||
          target.isNullableInstanceMember,
    );
    Field field = target.classMember as Field;
    DartType calleeType = target.getGetterType(this);

    return _finishFieldGetterInvocation(
      visitor,
      fileOffset: fileOffset,
      receiver: receiver,
      receiverType: receiverType,
      target: target,
      member: field,
      declaredMemberType: field.type,
      calleeType: calleeType,
      typeArguments: typeArguments,
      arguments: arguments,
      typeContext: typeContext,
      hoistedExpressions: hoistedExpressions,
      isExpressionInvocation: isExpressionInvocation,
    );
  }

  /// Computes an appropriate [PropertyTarget] for use in flow analysis to
  /// represent the given [target].
  PropertyTarget<Expression> computePropertyTarget(Expression target);

  /// Performs the core type inference algorithm for method invocations.
  ExpressionInferenceResult inferMethodInvocation(
    InferenceVisitor visitor,
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    DartType typeContext, {
    required bool isExpressionInvocation,
    required bool isImplicitCall,
    Name? implicitInvocationPropertyName,
    List<VariableDeclaration>? hoistedExpressions,
    ObjectAccessTarget? target,
  }) {
    target ??= findInterfaceMember(
      receiverType,
      name,
      fileOffset,
      instrumented: true,
      includeExtensionMethods: true,
      isSetter: false,
    );

    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      OverwrittenInterfaceMember? overWritten = expressionEvaluationHelper
          ?.overwriteFindInterfaceMember(
            target: target,
            name: name,
            receiverType: receiverType,
            setter: false,
          );
      if (overWritten != null) {
        target = overWritten.target;
        name = overWritten.name;
      }
    }

    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
      case ObjectAccessTargetKind.superMember:
        Member member = target.classMember!;
        if (member is Procedure) {
          if (member.kind == ProcedureKind.Getter) {
            return _inferInstanceGetterInvocation(
              visitor,
              fileOffset,
              receiver,
              receiverType,
              target,
              typeArguments,
              arguments,
              typeContext,
              hoistedExpressions,
              isExpressionInvocation: isExpressionInvocation,
            );
          } else {
            bool isSpecialCasedBinaryOperator = target
                .isSpecialCasedBinaryOperator(this);
            return _inferInstanceMethodInvocation(
              visitor,
              fileOffset,
              receiver,
              receiverType,
              target,
              typeArguments,
              arguments,
              typeContext,
              hoistedExpressions,
              isImplicitCall: isImplicitCall,
              isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
              isSpecialCasedTernaryOperator: target
                  .isSpecialCasedTernaryOperator(this),
            );
          }
        } else {
          return _inferInstanceFieldInvocation(
            visitor,
            fileOffset,
            receiver,
            receiverType,
            target,
            typeArguments,
            arguments,
            typeContext,
            hoistedExpressions,
            isExpressionInvocation: isExpressionInvocation,
          );
        }
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        return _inferFunctionInvocation(
          visitor,
          fileOffset,
          receiver,
          receiverType,
          target,
          typeArguments,
          arguments,
          typeContext,
          hoistedExpressions,
          isImplicitCall: isImplicitCall,
        );
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        return _inferExtensionInvocation(
          visitor,
          fileOffset,
          receiver,
          receiverType,
          target,
          name,
          typeArguments,
          arguments,
          typeContext,
          hoistedExpressions,
          isImplicitCall: isImplicitCall,
        );
      case ObjectAccessTargetKind.ambiguous:
      case ObjectAccessTargetKind.missing:
        return _inferMissingInvocation(
          visitor,
          fileOffset,
          receiver,
          receiverType,
          target,
          name,
          typeArguments,
          arguments,
          typeContext,
          hoistedExpressions,
          isExpressionInvocation: isExpressionInvocation,
          isImplicitCall: isImplicitCall,
          implicitInvocationPropertyName: implicitInvocationPropertyName,
        );
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
        return _inferDynamicInvocation(
          visitor,
          fileOffset,
          receiver,
          name,
          typeArguments,
          arguments,
          typeContext,
          hoistedExpressions,
          isImplicitCall: isExpressionInvocation || isImplicitCall,
        );
      case ObjectAccessTargetKind.never:
        return _inferNeverInvocation(
          visitor,
          fileOffset,
          receiver,
          receiverType,
          name,
          typeArguments,
          arguments,
          typeContext,
          hoistedExpressions,
          isImplicitCall: isImplicitCall,
        );
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
        DartType type = target.getGetterType(this);
        Expression read = new RecordIndexGet(
          receiver,
          target.receiverType as RecordType,
          target.recordFieldIndex!,
        )..fileOffset = fileOffset;
        ExpressionInferenceResult readResult = new ExpressionInferenceResult(
          type,
          read,
        );
        if (target.isNullable) {
          // Handles cases like:
          //   (void Function())? r;
          //   r.$1();
          List<LocatedMessage>? context = getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(receiver)(),
            receiver,
            // Coverage-ignore(suite): Not run.
            (type) => !type.isPotentiallyNullable,
          );
          readResult = wrapExpressionInferenceResultInProblem(
            readResult,
            diag.nullableExpressionCallError.withArguments(type: receiverType),
            fileOffset,
            noLength,
            context: context,
          );
        }
        return inferMethodInvocation(
          visitor,
          arguments.fileOffset,
          readResult.expression,
          readResult.inferredType,
          callName,
          typeArguments,
          arguments,
          typeContext,
          isExpressionInvocation: false,
          isImplicitCall: true,
          hoistedExpressions: hoistedExpressions,
        );
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordNamed:
        if (isImplicitCall && !target.isNullable) {
          libraryBuilder.addProblem(
            diag.recordUsedAsCallable,
            receiver.fileOffset,
            noLength,
            fileUri,
          );
        }
        DartType type = target.getGetterType(this);
        Expression read = new RecordNameGet(
          receiver,
          target.receiverType as RecordType,
          target.recordFieldName!,
        )..fileOffset = fileOffset;
        ExpressionInferenceResult readResult = new ExpressionInferenceResult(
          type,
          read,
        );
        if (target.isNullable) {
          // Handles cases like:
          //   ({void Function() foo})? r;
          //   r.foo();
          List<LocatedMessage>? context = getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(receiver)(),
            receiver,
            // Coverage-ignore(suite): Not run.
            (type) => !type.isPotentiallyNullable,
          );
          readResult = wrapExpressionInferenceResultInProblem(
            readResult,
            diag.nullableExpressionCallError.withArguments(type: receiverType),
            fileOffset,
            noLength,
            context: context,
          );
        }
        return inferMethodInvocation(
          visitor,
          arguments.fileOffset,
          readResult.expression,
          readResult.inferredType,
          callName,
          typeArguments,
          arguments,
          typeContext,
          isExpressionInvocation: false,
          isImplicitCall: true,
          hoistedExpressions: hoistedExpressions,
        );
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        DartType type = target.getGetterType(this);
        var (SharedTypeView? wrappedPromotedType, _) = flowAnalysis.propertyGet(
          computePropertyTarget(receiver),
          name.text,
          (target as ExtensionTypeRepresentationAccessTarget)
              .representationField,
          new SharedTypeView(type),
        );
        // Coverage-ignore(suite): Not run.
        type = wrappedPromotedType?.unwrapTypeView() ?? type;
        Expression read = new AsExpression(receiver, type)
          ..isUnchecked = true
          ..fileOffset = fileOffset;
        ExpressionInferenceResult readResult = new ExpressionInferenceResult(
          type,
          read,
        );
        if (target.isNullable) {
          // Coverage-ignore-block(suite): Not run.
          // Handles cases like:
          //
          //   extension type Foo(void Function() bar) {}
          //   method(Foo? r) => r.bar();
          //
          List<LocatedMessage>? context = getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(receiver)(),
            receiver,
            (type) => !type.isPotentiallyNullable,
          );
          readResult = wrapExpressionInferenceResultInProblem(
            readResult,
            diag.nullableExpressionCallError.withArguments(type: receiverType),
            fileOffset,
            noLength,
            context: context,
          );
        }
        return inferMethodInvocation(
          visitor,
          arguments.fileOffset,
          readResult.expression,
          readResult.inferredType,
          callName,
          typeArguments,
          arguments,
          typeContext,
          isExpressionInvocation: false,
          isImplicitCall: true,
          hoistedExpressions: hoistedExpressions,
        );
    }
  }

  void _checkBoundsInMethodInvocation(
    ObjectAccessTarget target,
    DartType receiverType,
    DartType calleeType,
    Name methodName,
    List<DartType> typeArguments,
    ActualArguments arguments,
    int fileOffset, {
    required bool hasInferredTypeArguments,
  }) {
    // If [arguments] were inferred, check them.

    // [actualReceiverType], [interfaceTarget], and [actualMethodName] below
    // are for a workaround for the cases like the following:
    //
    //     class C1 { var f = new C2(); }
    //     class C2 { int call<X extends num>(X x) => 42; }
    //     main() { C1 c = new C1(); c.f("foobar"); }
    DartType actualReceiverType;
    Member? interfaceTarget;
    Name actualMethodName;
    if (calleeType is InterfaceType) {
      // Coverage-ignore-block(suite): Not run.
      actualReceiverType = calleeType;
      interfaceTarget = null;
      actualMethodName = callName;
    } else {
      actualReceiverType = receiverType;
      interfaceTarget = (target.isInstanceMember || target.isObjectMember)
          ? target.member
          : null;
      actualMethodName = methodName;
    }
    problemReporting.checkBoundsInMethodInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      receiverType: actualReceiverType,
      typeEnvironment: typeSchemaEnvironment,
      classHierarchy: hierarchyBuilder,
      membersHierarchy: membersBuilder,
      name: actualMethodName,
      interfaceTarget: interfaceTarget,
      explicitOrInferredTypeArguments: typeArguments,
      arguments: arguments,
      fileUri: fileUri,
      fileOffset: fileOffset,
      hasInferredTypeArguments: hasInferredTypeArguments,
    );
  }

  void checkBoundsInInstantiation(
    FunctionType functionType,
    List<DartType> arguments,
    int fileOffset, {
    required bool inferred,
  }) {
    // If [arguments] were inferred, check them.

    problemReporting.checkBoundsInInstantiation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      typeEnvironment: typeSchemaEnvironment,
      functionType: functionType,
      explicitOrInferredTypeArguments: arguments,
      fileUri: fileUri,
      fileOffset: fileOffset,
      hasInferredTypeArguments: inferred,
    );
  }

  void _checkBoundsInFunctionInvocation(
    FunctionType functionType,
    String? localName,
    List<DartType> explicitOrInferredTypeArguments,
    ActualArguments arguments,
    int fileOffset, {
    required bool hasInferredTypeArguments,
  }) {
    // If [arguments] were inferred, check them.
    problemReporting.checkBoundsInFunctionInvocation(
      problemReportingHelper: problemReportingHelper,
      libraryFeatures: libraryFeatures,
      typeEnvironment: typeSchemaEnvironment,
      functionType: functionType,
      localName: localName,
      explicitOrInferredTypeArguments: explicitOrInferredTypeArguments,
      arguments: arguments,
      fileUri: fileUri,
      fileOffset: fileOffset,
      hasInferredTypeArguments: hasInferredTypeArguments,
    );
  }

  /// Performs the core type inference algorithm for super method invocations.
  ExpressionInferenceResult inferSuperMethodInvocation(
    InferenceVisitor visitor, {
    required Name name,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required DartType typeContext,
    required Procedure procedure,
    required int fileOffset,
  }) {
    ObjectAccessTarget target = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(
            thisType!,
            procedure,
            hasNonObjectMemberAccess: true,
          )
        : new ObjectAccessTarget.superMember(thisType!, procedure);
    DartType receiverType = thisType!;
    bool isSpecialCasedBinaryOperator = target.isSpecialCasedBinaryOperator(
      this,
    );
    DartType calleeType = target.getGetterType(this);
    InvocationTargetType invocationTargetType = target.getFunctionType(this);
    if (name == equalsName) {
      switch (invocationTargetType) {
        case InvocationTargetFunctionType():
          FunctionType functionType = invocationTargetType.functionType;
          if (functionType.positionalParameters.length == 1 &&
              functionType.positionalParameters.first.nullability !=
                  Nullability.nullable) {
            // operator == always allows nullable arguments.
            invocationTargetType = new InvocationTargetFunctionType(
              new FunctionType(
                [
                  functionType.positionalParameters.single
                      .withDeclaredNullability(Nullability.nullable),
                ],
                functionType.returnType,
                functionType.declaredNullability,
              ),
            );
          }
        // Coverage-ignore(suite): Not run.
        case InvocationTargetDynamicType():
        case InvocationTargetNeverType():
        case InvocationTargetInvalidType():
      }
    }
    InvocationInferenceResult result = inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      invocationTargetType,
      typeArguments,
      arguments,
      isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
      receiverType: receiverType,
    );
    DartType inferredType = result.inferredType;
    if (name.text == '==') {
      inferredType = coreTypes.boolRawType(Nullability.nonNullable);
    }
    _checkBoundsInMethodInvocation(
      target,
      receiverType,
      calleeType,
      name,
      result.typeArguments,
      arguments,
      fileOffset,
      hasInferredTypeArguments: typeArguments == null,
    );
    return new ExpressionInferenceResult(
      inferredType,
      result.applyResult(
        createSuperMethodInvocation(
          isClosureContextLoweringEnabled
              ? (new VariableGet(internalThisVariable)..fileOffset = fileOffset)
              : (new ThisExpression()..fileOffset = fileOffset),
          name,
          procedure,
          createArgumentsFromInternalNode(
            result.typeArguments,
            result.positional,
            result.named,
            arguments,
          ),
          fileOffset: fileOffset,
        ),
      ),
    );
  }

  /// Performs the inference for a super property get of [member].
  ///
  /// If [node] is provided, it is used as the basis for the resulting
  /// expression, otherwise a new [SuperPropertyGet] is created.
  ExpressionInferenceResult inferSuperPropertyGet({
    required Name name,
    required DartType typeContext,
    required Member member,
    required int nameOffset,
    Expression? node,
  }) {
    TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);

    bool isAbstract = thisType!.classNode.isMixinDeclaration;
    ObjectAccessTarget readTarget = isAbstract
        ? new ObjectAccessTarget.interfaceMember(
            thisType!,
            member,
            hasNonObjectMemberAccess: true,
          )
        : new ObjectAccessTarget.superMember(thisType!, member);
    DartType inferredType = readTarget.getGetterType(this);
    node ??=
        // TODO(johnniwinther): Create an [AbstractSuperPropertyGet] if
        //  [isAbstract] is `true`, once [AbstractSuperPropertyGet] is
        //  supported by backends.
        new SuperPropertyGet(
          isClosureContextLoweringEnabled
              ? (new VariableGet(internalThisVariable)..fileOffset = nameOffset)
              : (new ThisExpression()..fileOffset = nameOffset),
          name,
          member,
        )..fileOffset = nameOffset;
    if (member is Procedure && member.kind == ProcedureKind.Method) {
      return instantiateTearOff(inferredType, typeContext, node);
    }
    var (
      SharedTypeView? wrappedPromotedType,
      ExpressionInfo? expressionInfo,
    ) = flowAnalysis.propertyGet(
      SuperPropertyTarget.singleton,
      name.text,
      member,
      new SharedTypeView(inferredType),
    );
    flowAnalysis.storeExpressionInfo(node, expressionInfo);
    DartType? promotedType = wrappedPromotedType?.unwrapTypeView();
    if (promotedType != null) {
      node = new AsExpression(node, promotedType)
        ..isUnchecked = true
        ..fileOffset = nameOffset;
      inferredType = promotedType;
    }
    return new ExpressionInferenceResult(inferredType, node);
  }

  /// Computes the type context for the value expression in a super property set
  /// to [member].
  DartType computeSuperPropertySetWriteContext(Member member) {
    TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
    ObjectAccessTarget writeTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(
            thisType!,
            member,
            hasNonObjectMemberAccess: true,
          )
        : new ObjectAccessTarget.superMember(thisType!, member);
    return writeTarget.getSetterType(this);
  }

  /// Performs the inference of a super property set to [member] with the
  /// value from [rhsResult].
  ///
  /// If [node] is provided, it is used as the basis for the resulting
  /// expression, otherwise a new [SuperPropertySet] is created.
  ExpressionInferenceResult inferSuperPropertySet({
    required Name name,
    required Member member,
    required ExpressionInferenceResult rhsResult,
    required DartType writeContext,
    required int assignOffset,
    required int nameOffset,
    Expression? node,
  }) {
    rhsResult = ensureAssignableResult(
      writeContext,
      rhsResult,
      fileOffset: assignOffset,
      isVoidAllowed: writeContext is VoidType,
    );
    Expression rhs = rhsResult.expression;
    if (node is SuperPropertySet) {
      node.value = rhs..parent = node;
    } else if (node is AbstractSuperPropertySet) {
      // Coverage-ignore-block(suite): Not run.
      node.value = rhs..parent = node;
    } else {
      assert(node == null, "Unexpected node for super property set $node.");
      node = new SuperPropertySet(
        isClosureContextLoweringEnabled
            ? (new VariableGet(internalThisVariable)..fileOffset = nameOffset)
            : (new ThisExpression()..fileOffset = nameOffset),
        name,
        rhs,
        member,
      )..fileOffset = nameOffset;
    }
    return new ExpressionInferenceResult(rhsResult.inferredType, node!);
  }

  /// Performs the inference for a static get of [member].
  ///
  /// If [node] is provided, it is used as the basis for the resulting
  /// expression, otherwise a new [StaticGet] is created.
  ExpressionInferenceResult inferStaticGet({
    required Member member,
    required DartType typeContext,
    required int nameOffset,
    Expression? node,
  }) {
    TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
    DartType type = member.getterType;

    node ??= new StaticGet(member)..fileOffset = nameOffset;
    if (member is Procedure && member.kind == ProcedureKind.Method) {
      // Coverage-ignore-block(suite): Not run.
      Expression tearOff = new StaticTearOff(member)
        ..fileOffset = node.fileOffset;
      return instantiateTearOff(type, typeContext, tearOff);
    } else {
      return new ExpressionInferenceResult(type, node);
    }
  }

  /// Computes the type context for the value expression in a static set to
  /// [member].
  DartType computeStaticSetWriteContext(Member member) {
    TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
    return member.setterType;
  }

  /// Performs the inference of a static set to [member] with the value from
  /// [rhsResult].
  ///
  /// If [node] is provided, it is used as the basis for the resulting
  /// expression, otherwise a new [StaticSet] is created.
  ExpressionInferenceResult inferStaticSet({
    required Member member,
    required ExpressionInferenceResult rhsResult,
    required DartType writeContext,
    required int assignOffset,
    required int nameOffset,
    StaticSet? node,
  }) {
    rhsResult = ensureAssignableResult(
      writeContext,
      rhsResult,
      fileOffset: assignOffset,
      isVoidAllowed: writeContext is VoidType,
    );
    Expression rhs = rhsResult.expression;
    if (node != null) {
      node.value = rhs..parent = node;
    } else {
      node = new StaticSet(member, rhs)..fileOffset = nameOffset;
    }
    DartType rhsType = rhsResult.inferredType;
    return new ExpressionInferenceResult(rhsType, node);
  }

  /// Performs the inference for a local get of [variable].
  ///
  /// If [node] is provided, it is used as the basis for the resulting
  /// expression, otherwise a new [VariableGet] is created.
  ExpressionInferenceResult inferVariableGet({
    required InternalExpressionVariable variable,
    required DartType typeContext,
    required int nameOffset,
    VariableGet? node,
  }) {
    node ??= new VariableGet(variable.astVariable)..fileOffset = nameOffset;
    DartType? promotedType;
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    ExpressionInfo? expressionInfo;
    if (isExtensionThis(variable.astVariable)) {
      expressionInfo = flowAnalysis.thisOrSuper(
        new SharedTypeView(variable.type),
        isSuper: true,
      );
    } else if (!variable.isLocalFunction) {
      // Don't promote local functions.
      SharedTypeView? wrappedPromotedType;
      (wrappedPromotedType, expressionInfo) = flowAnalysis.variableRead(
        variable.astVariable,
      );
      promotedType = wrappedPromotedType?.unwrapTypeView();
    }
    flowAnalysis.storeExpressionInfo(node, expressionInfo);
    node.promotedType = promotedType;
    DartType resultType = promotedType ?? declaredOrInferredType;
    Expression resultExpression;
    if (variable.isLocalFunction) {
      return instantiateTearOff(resultType, typeContext, node);
    } else if (variable.lateGetter != null) {
      resultExpression = new LocalFunctionInvocation(
        variable.lateGetter!,
        new Arguments(<Expression>[])..fileOffset = node.fileOffset,
        functionType: variable.lateGetter!.type as FunctionType,
      )..fileOffset = node.fileOffset;
      // Future calls to flow analysis will be using `resultExpression` to refer
      // to the variable get, so instruct flow analysis to forward the
      // expression information.
      flowAnalysis.forwardExpression(resultExpression, node);
    } else {
      resultExpression = node..expressionVariable = variable.astVariable;
    }

    bool isUnassigned = !flowAnalysis.isAssigned(variable.astVariable);
    if (isUnassigned) {
      dataForTesting
          // Coverage-ignore(suite): Not run.
          ?.flowAnalysisResult // Coverage-ignore(suite): Not run.
          .potentiallyUnassignedNodes // Coverage-ignore(suite): Not run.
          .add(node);
    }
    bool isDefinitelyUnassigned = flowAnalysis.isUnassigned(
      variable.astVariable,
    );
    if (isDefinitelyUnassigned) {
      dataForTesting
          // Coverage-ignore(suite): Not run.
          ?.flowAnalysisResult // Coverage-ignore(suite): Not run.
          .definitelyUnassignedNodes // Coverage-ignore(suite): Not run.
          .add(node);
    }
    // Synthetic variables, local functions, and variables with
    // invalid types aren't checked.
    if (variable.cosmeticName != null &&
        !variable.isLocalFunction &&
        declaredOrInferredType is! InvalidType) {
      if (variable.isLate || variable.lateGetter != null) {
        if (isDefinitelyUnassigned) {
          String name = variable.lateName ?? variable.cosmeticName!;
          return new ExpressionInferenceResult(
            resultType,
            problemReporting.wrapInProblem(
              compilerContext: compilerContext,
              expression: resultExpression,
              message: diag.lateDefinitelyUnassignedError.withArguments(
                variableName: name,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: name.length,
            ),
          );
        }
      } else {
        if (isUnassigned) {
          if (variable.isFinal) {
            return new ExpressionInferenceResult(
              resultType,
              problemReporting.wrapInProblem(
                compilerContext: compilerContext,
                expression: resultExpression,
                message: diag.finalNotAssignedError.withArguments(
                  variableName: node.variable.name!,
                ),
                fileUri: fileUri,
                fileOffset: node.fileOffset,
                length: node.variable.name!.length,
              ),
            );
          } else if (declaredOrInferredType.isPotentiallyNonNullable) {
            return new ExpressionInferenceResult(
              resultType,
              problemReporting.wrapInProblem(
                compilerContext: compilerContext,
                expression: resultExpression,
                message: diag.nonNullableNotAssignedError.withArguments(
                  variableName: node.expressionVariable.cosmeticName!,
                ),
                fileUri: fileUri,
                fileOffset: node.fileOffset,
                length: node.expressionVariable.cosmeticName!.length,
              ),
            );
          }
        }
      }
    }

    return new ExpressionInferenceResult(resultType, resultExpression);
  }

  /// Computes the possible promoted variable type of [variable] and the type
  /// context for the value expression in a local set to [variable].
  (DartType variableType, DartType writeContext)
  computeVariableSetTypeAndWriteContext(InternalExpressionVariable variable) {
    DartType declaredOrInferredType = variable.lateType ?? variable.type;
    DartType? promotedType = flowAnalysis
        .promotedType(variable.astVariable)
        ?.unwrapTypeView();
    return (declaredOrInferredType, promotedType ?? declaredOrInferredType);
  }

  /// Performs the inference of a local set to [variable] with the value from
  /// [rhsResult].
  ///
  /// If [node] is provided, it is used as the basis for the resulting
  /// expression, otherwise a new [VariableSet] is created.
  ExpressionInferenceResult inferVariableSet({
    required InternalExpressionVariable variable,
    required DartType variableType,
    required ExpressionInferenceResult rhsResult,
    required int assignOffset,
    required int nameOffset,
    VariableSet? node,
  }) {
    bool isDefinitelyAssigned = flowAnalysis.isAssigned(variable.astVariable);
    bool isDefinitelyUnassigned = flowAnalysis.isUnassigned(
      variable.astVariable,
    );
    rhsResult = ensureAssignableResult(
      variableType,
      rhsResult,
      fileOffset: assignOffset,
      isVoidAllowed: variableType is VoidType,
    );
    Expression rhs = rhsResult.expression;
    node ??= new VariableSet(variable.astVariable, rhs)
      ..fileOffset = nameOffset;
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.write(
        node,
        variable.astVariable,
        new SharedTypeView(rhsResult.inferredType),
        rhsResult.expression,
      ),
    );
    DartType resultType = rhsResult.inferredType;
    Expression resultExpression;
    if (variable.lateSetter != null) {
      resultExpression = new LocalFunctionInvocation(
        variable.lateSetter!,
        new Arguments(<Expression>[rhs])..fileOffset = node.fileOffset,
        functionType: variable.lateSetter!.type as FunctionType,
      )..fileOffset = node.fileOffset;
      // Future calls to flow analysis will be using `resultExpression` to refer
      // to the variable set, so instruct flow analysis to forward the
      // expression information.
      flowAnalysis.forwardExpression(resultExpression, node);
    } else {
      node.value = rhs..parent = node;
      resultExpression = node..expressionVariable = variable.astVariable;
    }
    // Synthetic variables, local functions, and variables with
    // invalid types aren't checked.
    if (variable.cosmeticName != null &&
        !variable.isLocalFunction &&
        variableType is! InvalidType) {
      if ((variable.isLate && variable.isFinal) ||
          variable.isLateFinalWithoutInitializer) {
        if (isDefinitelyAssigned) {
          return new ExpressionInferenceResult(
            resultType,
            problemReporting.wrapInProblem(
              compilerContext: compilerContext,
              expression: resultExpression,
              message: diag.lateDefinitelyAssignedError.withArguments(
                variableName: node.variable.name!,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: node.variable.name!.length,
            ),
          );
        }
      } else if (variable.isStaticLate) {
        if (!isDefinitelyUnassigned) {
          return new ExpressionInferenceResult(
            resultType,
            problemReporting.wrapInProblem(
              compilerContext: compilerContext,
              expression: resultExpression,
              message: diag.finalPossiblyAssignedError.withArguments(
                variableName: node.variable.name!,
              ),
              fileUri: fileUri,
              fileOffset: node.fileOffset,
              length: node.variable.name!.length,
            ),
          );
        }
      }
    }
    return new ExpressionInferenceResult(resultType, resultExpression);
  }

  /// Computes the implicit instantiation from an expression of [tearOffType]
  /// to the [context] type. Return `null` if an implicit instantiation is not
  /// necessary or possible.
  ImplicitInstantiation? computeImplicitInstantiation(
    DartType tearoffType,
    DartType context, {
    required TreeNode? treeNodeForTesting,
  }) {
    if (tearoffType is FunctionType &&
        context is FunctionType &&
        context.typeParameters.isEmpty) {
      FunctionType functionType = tearoffType;
      List<StructuralParameter> typeParameters = functionType.typeParameters;
      if (typeParameters.isNotEmpty) {
        List<DartType> inferredTypes = new List<DartType>.filled(
          typeParameters.length,
          const UnknownType(),
        );
        FunctionType instantiatedType = functionType.withoutTypeParameters;
        TypeConstraintGatherer gatherer = typeSchemaEnvironment
            .setupGenericTypeInference(
              instantiatedType,
              typeParameters,
              context,
              inferenceUsingBoundsIsEnabled:
                  libraryFeatures.inferenceUsingBounds.isEnabled,
              typeOperations: cfeOperations,
              inferenceResultForTesting: dataForTesting
                  // Coverage-ignore(suite): Not run.
                  ?.typeInferenceResult,
              treeNodeForTesting: treeNodeForTesting,
            );
        inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
          gatherer.computeConstraints(),
          typeParameters,
          inferredTypes,
          inferenceUsingBoundsIsEnabled:
              libraryFeatures.inferenceUsingBounds.isEnabled,
          dataForTesting: dataForTesting,
          treeNodeForTesting: treeNodeForTesting,
          typeOperations: cfeOperations,
        );
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
              typeParameters,
              inferredTypes,
            );
        tearoffType = instantiator.substitute(instantiatedType);
        return new ImplicitInstantiation(
          inferredTypes,
          functionType,
          tearoffType,
        );
      }
    }
    return null;
  }

  ExpressionInferenceResult _applyImplicitInstantiation(
    ImplicitInstantiation? implicitInstantiation,
    DartType tearOffType,
    Expression expression,
  ) {
    if (implicitInstantiation != null) {
      FunctionType uninstantiatedType = implicitInstantiation.functionType;

      List<DartType> typeArguments = implicitInstantiation.typeArguments;
      checkBoundsInInstantiation(
        uninstantiatedType,
        typeArguments,
        expression.fileOffset,
        inferred: true,
      );

      if (expression is TypedefTearOff) {
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
              expression.structuralParameters,
              typeArguments,
            );
        typeArguments = expression.typeArguments
            .map(instantiator.substitute)
            .toList();
        expression = expression.expression;
      } else {
        LoweredTypedefTearOff? loweredTypedefTearOff =
            LoweredTypedefTearOff.fromExpression(expression);
        if (loweredTypedefTearOff != null) {
          Substitution substitution = Substitution.fromPairs(
            loweredTypedefTearOff.typedefTearOff.function.typeParameters,
            typeArguments,
          );
          typeArguments = loweredTypedefTearOff.typeArguments
              .map(substitution.substituteType)
              .toList();
          expression = loweredTypedefTearOff.targetTearOff;
        }
      }
      tearOffType = implicitInstantiation.instantiatedType;
      if (uninstantiatedType.isPotentiallyNullable) {
        // Replace expression with:
        // `let t = expression in t == null ? null : t<...>`
        VariableDeclaration t = new VariableDeclaration.forValue(
          expression,
          type: uninstantiatedType,
        )..fileOffset = expression.fileOffset;

        Expression nullCheck = new EqualsNull(
          new VariableGet(t)..fileOffset = expression.fileOffset,
        )..fileOffset = expression.fileOffset;

        ConditionalExpression conditional = new ConditionalExpression(
          nullCheck,
          new NullLiteral()..fileOffset = expression.fileOffset,
          new Instantiation(
            new VariableGet(t, uninstantiatedType.toNonNull()),
            typeArguments,
          )..fileOffset = expression.fileOffset,
          tearOffType,
        );
        expression = new Let(t, conditional)
          ..fileOffset = expression.fileOffset;
      } else {
        expression = new Instantiation(expression, typeArguments)
          ..fileOffset = expression.fileOffset;
      }
    }
    return new ExpressionInferenceResult(tearOffType, expression);
  }

  /// Performs the type inference steps necessary to instantiate a tear-off
  /// (if necessary).
  ExpressionInferenceResult instantiateTearOff(
    DartType tearoffType,
    DartType context,
    Expression expression,
  ) {
    ImplicitInstantiation? implicitInstantiation = computeImplicitInstantiation(
      tearoffType,
      context,
      treeNodeForTesting: expression,
    );
    return _applyImplicitInstantiation(
      implicitInstantiation,
      tearoffType,
      expression,
    );
  }

  /// True if the returned [type] has non-covariant occurrences of any of
  /// the type parameters from [enclosingTypeDeclaration], the enclosing class
  /// or extension type declaration.
  ///
  /// A non-covariant occurrence of a type parameter is either a contravariant
  /// or an invariant position.
  ///
  /// A contravariant position is to the left of an odd number of arrows. For
  /// example, T occurs contravariantly in T -> T0, T0 -> (T -> T1),
  /// (T0 -> T) -> T1 but not in (T -> T0) -> T1.
  ///
  /// An invariant position is without a bound of a type parameter. For example,
  /// T occurs invariantly in `S Function<S extends T>()` and
  /// `void Function<S extends C<T>>(S)`.
  static bool returnedTypeParametersOccurNonCovariantly(
    TypeDeclaration enclosingTypeDeclaration,
    DartType type,
  ) {
    if (enclosingTypeDeclaration.typeParameters.isEmpty) return false;
    IncludesTypeParametersNonCovariantly checker =
        new IncludesTypeParametersNonCovariantly(
          enclosingTypeDeclaration.typeParameters,
          // We are checking the returned type (field/getter type or return
          // type of a method) and this is a covariant position.
          initialVariance: Variance.covariant,
        );
    return type.accept(checker);
  }

  /// Determines the dispatch category of a [MethodInvocation] and returns a
  /// boolean indicating whether an "as" check will need to be added due to
  /// contravariance.
  MethodContravarianceCheckKind preCheckInvocationContravariance(
    DartType receiverType,
    ObjectAccessTarget target, {
    required bool isThisReceiver,
  }) {
    if (target.isInstanceMember || target.isObjectMember) {
      Member interfaceMember = target.member!;
      if (interfaceMember is Field ||
          interfaceMember is Procedure &&
              interfaceMember.kind == ProcedureKind.Getter) {
        // Coverage-ignore-block(suite): Not run.
        DartType getType = target.getGetterType(this);
        if (getType is DynamicType) {
          return MethodContravarianceCheckKind.none;
        }
        if (!isThisReceiver) {
          if ((interfaceMember is Field &&
                  returnedTypeParametersOccurNonCovariantly(
                    interfaceMember.enclosingTypeDeclaration!,
                    interfaceMember.type,
                  )) ||
              (interfaceMember is Procedure &&
                  returnedTypeParametersOccurNonCovariantly(
                    interfaceMember.enclosingTypeDeclaration!,
                    interfaceMember.function.returnType,
                  ))) {
            return MethodContravarianceCheckKind.checkGetterReturn;
          }
        }
      } else if (!isThisReceiver &&
          interfaceMember is Procedure &&
          returnedTypeParametersOccurNonCovariantly(
            interfaceMember.enclosingTypeDeclaration!,
            interfaceMember.function.returnType,
          )) {
        return MethodContravarianceCheckKind.checkMethodReturn;
      }
    }
    return MethodContravarianceCheckKind.none;
  }

  DartType wrapFutureOrType(DartType type) {
    if (type is FutureOrType) {
      return type;
    }
    // TODO(paulberry): If [type] is a subtype of `Future`, should we just
    // return it unmodified?
    return new FutureOrType(type, Nullability.nonNullable);
  }

  DartType wrapFutureType(DartType type, Nullability nullability) {
    return new InterfaceType(coreTypes.futureClass, nullability, <DartType>[
      type,
    ]);
  }

  DartType wrapType(DartType type, Class class_, Nullability nullability) {
    return new InterfaceType(class_, nullability, <DartType>[type]);
  }

  /// Computes the `futureValueTypeSchema` for the type schema [type].
  ///
  /// This is the same as the [emittedValueType] except that this handles
  /// the unknown type.
  DartType computeFutureValueTypeSchema(DartType type) {
    return type.accept1(
      new FutureValueTypeVisitor(
        unhandledTypeHandler:
            (
              AuxiliaryType node,
              CoreTypes coreTypes,
              DartType Function(AuxiliaryType node, CoreTypes coreTypes)
              recursor,
            ) {
              if (node is UnknownType) {
                // futureValueTypeSchema(_) = _.
                return node;
              }
              // Coverage-ignore-block(suite): Not run.
              throw new UnsupportedError(
                "Unsupported type '${node.runtimeType}'.",
              );
            },
      ),
      coreTypes,
    );
  }

  Member? _getInterfaceMember(Class class_, Name name, bool setter) {
    Member? member = engine.membersBuilder.getInterfaceMember(
      class_,
      name,
      setter: setter,
    );
    return TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
  }

  Member? _getStaticMember(Class class_, Name name, bool setter) {
    Member? member = engine.membersBuilder.getStaticMember(
      class_,
      name,
      setter: setter,
    );
    return TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
  }

  ClassMember? _getExtensionTypeMember(
    ExtensionTypeDeclaration extensionTypeDeclaration,
    Name name,
    bool setter,
  ) {
    ClassMember? member = engine.membersBuilder.getExtensionTypeClassMember(
      extensionTypeDeclaration,
      name,
      setter: setter,
    );
    TypeInferenceEngine.resolveInferenceNode(
      member?.getMember(engine.membersBuilder),
      hierarchyBuilder,
    );
    return member;
  }

  ClassMember? _getExtensionTypeStaticMember(
    ExtensionTypeDeclaration extensionTypeDeclaration,
    Name name,
    bool setter,
  ) {
    ClassMember? member = engine.membersBuilder
        .getExtensionTypeStaticClassMember(
          extensionTypeDeclaration,
          name,
          setter: setter,
        );
    TypeInferenceEngine.resolveInferenceNode(
      member?.getMember(engine.membersBuilder),
      hierarchyBuilder,
    );
    return member;
  }

  bool _isLoweredSetLiteral(Expression expression) {
    if (libraryBuilder.loader.target.backendTarget.supportsSetLiterals) {
      return false;
    }
    if (expression is! BlockExpression) return false;
    Expression value = expression.value;
    if (value is! VariableGet) return false;
    if (expression.body.statements.isEmpty) return false;
    Statement first = expression.body.statements.first;
    if (first is! VariableDeclaration) return false;
    Expression? initializer = first.initializer;
    if (initializer is! StaticInvocation) return false;
    if (initializer.target != engine.setFactory) return false;
    return value.variable == first;
  }

  /// Determines if the given [expression]'s type is precisely known at compile
  /// time.
  ///
  /// If it is, an error message template is returned, which can be used by the
  /// caller to report an invalid cast.  Otherwise, `null` is returned.
  Template<
    Message Function({
      required DartType actualType,
      required DartType expectedType,
    })
  >?
  _getPreciseTypeErrorTemplate(Expression expression) {
    if (expression is ListLiteral) {
      return diag.invalidCastLiteralList;
    }
    if (expression is MapLiteral) {
      return diag.invalidCastLiteralMap;
    }
    if (expression is SetLiteral || _isLoweredSetLiteral(expression)) {
      return diag.invalidCastLiteralSet;
    }
    if (expression is FunctionExpression) {
      return diag.invalidCastFunctionExpr;
    }
    if (expression is ConstructorInvocation) {
      return diag.invalidCastNewExpr;
    }
    if (expression is StaticGet) {
      Member target = expression.target;
      if (target is Procedure && target.kind == ProcedureKind.Method) {
        // Coverage-ignore-block(suite): Not run.
        if (target.enclosingClass != null) {
          return diag.invalidCastStaticMethod;
        } else {
          return diag.invalidCastTopLevelFunction;
        }
      }
      return null;
    }
    if (expression is StaticTearOff) {
      Member target = expression.target;
      if (target.enclosingClass != null) {
        return diag.invalidCastStaticMethod;
      } else {
        return diag.invalidCastTopLevelFunction;
      }
    }
    if (expression is VariableGet) {
      ExpressionVariable variable = expression.expressionVariable;
      if (variable is VariableDeclarationImpl && variable.isLocalFunction) {
        return diag.invalidCastLocalFunction;
      }
    }
    return null;
  }

  bool _shouldTearOffCall(DartType contextType, DartType expressionType) {
    if (contextType is FutureOrType) {
      contextType = contextType.typeArgument;
    }
    if (contextType is FunctionType) return true;
    if (contextType is InterfaceType &&
        contextType.classReference ==
            typeSchemaEnvironment.functionClass.reference) {
      if (!typeSchemaEnvironment.isSubtypeOf(expressionType, contextType)) {
        return true;
      }
    }
    return false;
  }

  /// Creates an expression the represents the invalid invocation of [name] on
  /// [receiver] with [arguments].
  ///
  /// This is used to ensure that subexpressions of invalid invocations are part
  /// of the AST using `helper.wrapInProblem`.
  Expression _createInvalidInvocation(
    int fileOffset,
    Expression receiver,
    Name name,
    Arguments arguments,
  ) {
    return new DynamicInvocation(
      DynamicAccessKind.Unresolved,
      receiver,
      name,
      arguments,
    )..fileOffset = fileOffset;
  }

  /// Creates an expression the represents the invalid get of [name] on
  /// [receiver].
  ///
  /// This is used to ensure that subexpressions of invalid gets are part
  /// of the AST using `helper.wrapInProblem`.
  Expression _createInvalidGet(int fileOffset, Expression receiver, Name name) {
    return new DynamicGet(DynamicAccessKind.Unresolved, receiver, name)
      ..fileOffset = fileOffset;
  }

  /// Creates an expression the represents the invalid set of [name] on
  /// [receiver] with [value].
  ///
  /// This is used to ensure that subexpressions of invalid gets are part
  /// of the AST using `helper.wrapInProblem`.
  Expression _createInvalidSet(
    int fileOffset,
    Expression receiver,
    Name name,
    Expression value,
  ) {
    return new DynamicSet(DynamicAccessKind.Unresolved, receiver, name, value)
      ..fileOffset = fileOffset;
  }

  /// Creates an expression the represents a duplicate expression occurring
  /// for instance as the [first] and [second] occurrence of named arguments
  /// with the same name.
  ///
  /// This is used to ensure that subexpressions of duplicate expressions are
  /// part of the AST using `helper.wrapInProblem`.
  Expression _createDuplicateExpression(
    int fileOffset,
    Expression first,
    Expression second,
  ) {
    return new BlockExpression(
      new Block([new ExpressionStatement(first)..fileOffset = fileOffset])
        ..fileOffset = fileOffset,
      second,
    )..fileOffset = fileOffset;
  }

  Expression _reportMissingOrAmbiguousMember(
    int fileOffset,
    int length,
    DartType receiverType,
    Name name,
    Expression? wrappedExpression,
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
    Template<Message Function({required String name, required DartType type})>
    missingTemplate,
    Template<Message Function({required String name, required DartType type})>
    ambiguousTemplate,
  ) {
    List<LocatedMessage>? context;
    Template<Message Function({required String name, required DartType type})>
    template = missingTemplate;
    if (extensionAccessCandidates != null) {
      context = extensionAccessCandidates
          .map(
            (ExtensionAccessCandidate c) =>
                diag.ambiguousExtensionCause.withLocation(
                  c.memberBuilder.fileUri!,
                  c.memberBuilder.fileOffset,
                  name == unaryMinusName ? 1 : c.memberBuilder.name.length,
                ),
          )
          .toList();
      template = ambiguousTemplate;
    }
    if (wrappedExpression != null) {
      return problemReporting.wrapInProblem(
        compilerContext: compilerContext,
        expression: wrappedExpression,
        message: template.withArguments(
          name: name.text,
          type: receiverType.nonTypeParameterBound,
        ),
        fileUri: fileUri,
        fileOffset: fileOffset,
        length: length,
        context: context,
      );
    } else {
      return problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: template.withArguments(
          name: name.text,
          type: receiverType.nonTypeParameterBound,
        ),
        fileUri: fileUri,
        fileOffset: fileOffset,
        length: length,
        context: context,
      );
    }
  }

  Expression createMissingMethodInvocation(
    int fileOffset,
    DartType receiverType,
    Name name, {
    Expression? receiver,
    Arguments? arguments,
    required bool isExpressionInvocation,
    Name? implicitInvocationPropertyName,
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    assert(
      (receiver == null) == (arguments == null),
      "Receiver and arguments must be supplied together.",
    );
    if (implicitInvocationPropertyName != null) {
      assert(extensionAccessCandidates == null);
      if (receiver != null) {
        return problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: _createInvalidInvocation(
            fileOffset,
            receiver,
            name,
            arguments!,
          ),
          message: diag.invokeNonFunction.withArguments(
            name: implicitInvocationPropertyName.text,
          ),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: implicitInvocationPropertyName.text.length,
        );
      } else {
        // Coverage-ignore-block(suite): Not run.
        return problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: diag.invokeNonFunction.withArguments(
            name: implicitInvocationPropertyName.text,
          ),
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: implicitInvocationPropertyName.text.length,
        );
      }
    } else {
      return _reportMissingOrAmbiguousMember(
        fileOffset,
        isExpressionInvocation ? noLength : name.text.length,
        receiverType,
        name,
        receiver != null
            ? _createInvalidInvocation(fileOffset, receiver, name, arguments!)
            : null,
        extensionAccessCandidates,
        diag.undefinedMethod,
        diag.ambiguousExtensionMethod,
      );
    }
  }

  PropertyGetInferenceResult createPropertyGet({
    required int fileOffset,
    required Expression receiver,
    required DartType receiverType,
    required Name propertyName,
    required DartType typeContext,
    ObjectAccessTarget? readTarget,
    DartType? readType,
    required DartType? promotedReadType,
    required bool isThisReceiver,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    Expression read;
    ExpressionInferenceResult? readResult;

    // Coverage-ignore(suite): Not run.
    readTarget ??= findInterfaceMember(
      receiverType,
      propertyName,
      fileOffset,
      includeExtensionMethods: true,
      isSetter: false,
    );

    if (expressionEvaluationHelper != null) {
      // Coverage-ignore-block(suite): Not run.
      OverwrittenInterfaceMember? overWritten = expressionEvaluationHelper
          ?.overwriteFindInterfaceMember(
            target: readTarget,
            name: propertyName,
            receiverType: receiverType,
            setter: false,
          );
      if (overWritten != null) {
        readTarget = overWritten.target;
        propertyName = overWritten.name;
      }
    }

    // Coverage-ignore(suite): Not run.
    readType ??= readTarget.getGetterType(this);

    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = createMissingPropertyGet(
          fileOffset,
          receiverType,
          propertyName,
          receiver: receiver,
        );
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = createMissingPropertyGet(
          fileOffset,
          receiverType,
          propertyName,
          receiver: receiver,
          extensionAccessCandidates: readTarget.candidates,
        );
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        switch (readTarget.declarationMethodKind) {
          case ClassMemberKind.Getter:
            read = new StaticInvocation(
              readTarget.member as Procedure,
              new Arguments(
                <Expression>[receiver],
                types: readTarget.receiverTypeArguments,
              )..fileOffset = fileOffset,
            )..fileOffset = fileOffset;
            break;
          case ClassMemberKind.Method:
            read = new StaticInvocation(
              readTarget.tearoffTarget as Procedure,
              new Arguments(
                <Expression>[receiver],
                types: readTarget.receiverTypeArguments,
              )..fileOffset = fileOffset,
            )..fileOffset = fileOffset;
            readResult = instantiateTearOff(readType, typeContext, read);
            break;
          // Coverage-ignore(suite): Not run.
          case ClassMemberKind.Setter:
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
      case ObjectAccessTargetKind.superMember:
        Member member = readTarget.classMember!;
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
          // Coverage-ignore(suite): Not run.
          default:
            throw new UnsupportedError('Unexpected target kind $readTarget');
        }
        if (member is Procedure && member.kind == ProcedureKind.Method) {
          read = new InstanceTearOff(
            kind,
            receiver,
            propertyName,
            interfaceTarget: member,
            resultType: readType,
          )..fileOffset = fileOffset;
        } else {
          read = new InstanceGet(
            kind,
            receiver,
            propertyName,
            interfaceTarget: member,
            resultType: readType,
          )..fileOffset = fileOffset;
        }
        bool checkReturn = false;
        if ((readTarget.isInstanceMember || readTarget.isObjectMember) &&
            !isThisReceiver) {
          Member interfaceMember = readTarget.classMember!;
          if (interfaceMember is Procedure) {
            GenericDeclaration? enclosingDeclaration =
                interfaceMember.enclosingTypeDeclaration!;
            if (enclosingDeclaration.typeParameters.isEmpty) {
              checkReturn = false;
            } else {
              DartType typeToCheck = interfaceMember.function
                  .computeFunctionType(Nullability.nonNullable);
              checkReturn =
                  InferenceVisitorBase // force line break
                  .returnedTypeParametersOccurNonCovariantly(
                    interfaceMember.enclosingTypeDeclaration!,
                    typeToCheck,
                  );
            }
          } else if (interfaceMember is Field) {
            checkReturn =
                InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                  interfaceMember.enclosingTypeDeclaration!,
                  interfaceMember.type,
                );
          }
        }
        if (checkReturn) {
          read = new AsExpression(read, readType)
            ..isTypeError = true
            ..isCovarianceCheck = true
            ..fileOffset = fileOffset;
        }
        if (member is Procedure && member.kind == ProcedureKind.Method) {
          readResult = instantiateTearOff(readType, typeContext, read);
        }
        break;
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
        read = new RecordIndexGet(
          receiver,
          readTarget.receiverType as RecordType,
          readTarget.recordFieldIndex!,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordNamed:
        read = new RecordNameGet(
          receiver,
          readTarget.receiverType as RecordType,
          readTarget.recordFieldName!,
        )..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        read = new AsExpression(receiver, readType)
          ..isUnchecked = true
          ..fileOffset = fileOffset;
        break;
    }

    if (promotedReadType != null) {
      read = new AsExpression(read, promotedReadType)
        ..isUnchecked = true
        ..fileOffset = fileOffset;
      readType = promotedReadType;
    }

    readResult ??= new ExpressionInferenceResult(readType, read);
    if (readTarget.isNullable) {
      readResult = wrapExpressionInferenceResultInProblem(
        readResult,
        diag.nullablePropertyAccessError.withArguments(
          propertyName: propertyName.text,
          receiverType: receiverType,
        ),
        read.fileOffset,
        propertyName.text.length,
        context: whyNotPromoted != null
            ? getWhyNotPromotedContext(
                whyNotPromoted(),
                read,
                (type) => !type.isPotentiallyNullable,
              )
            : null,
      );
    }
    return new PropertyGetInferenceResult(readResult, readTarget.member);
  }

  Expression createMissingPropertyGet(
    int fileOffset,
    DartType receiverType,
    Name propertyName, {
    Expression? receiver,
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    Template<Message Function({required String name, required DartType type})>
    codeMissing = diag.undefinedGetter;
    return _reportMissingOrAmbiguousMember(
      fileOffset,
      propertyName.text.length,
      receiverType,
      propertyName,
      receiver != null
          ? _createInvalidGet(fileOffset, receiver, propertyName)
          : null,
      extensionAccessCandidates,
      codeMissing,
      diag.ambiguousExtensionProperty,
    );
  }

  Expression createMissingPropertySet(
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Name propertyName,
    Expression value, {
    required bool forEffect,
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    Template<Message Function({required String name, required DartType type})>
    codeMissing = diag.undefinedSetter;
    return _reportMissingOrAmbiguousMember(
      fileOffset,
      propertyName.text.length,
      receiverType,
      propertyName,
      _createInvalidSet(fileOffset, receiver, propertyName, value),
      extensionAccessCandidates,
      codeMissing,
      diag.ambiguousExtensionProperty,
    );
  }

  Expression createMissingIndexGet(
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Expression index, {
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    Template<Message Function({required String name, required DartType type})>
    codeMissing = diag.undefinedOperator;

    return _reportMissingOrAmbiguousMember(
      fileOffset,
      noLength,
      receiverType,
      indexGetName,
      _createInvalidInvocation(
        fileOffset,
        receiver,
        indexGetName,
        new Arguments([index])..fileOffset = fileOffset,
      ),
      extensionAccessCandidates,
      codeMissing,
      diag.ambiguousExtensionOperator,
    );
  }

  Expression createMissingIndexSet(
    int fileOffset,
    Expression receiver,
    DartType receiverType,
    Expression index,
    Expression value, {
    required bool forEffect,
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    Template<Message Function({required String name, required DartType type})>
    codeMissing = diag.undefinedOperator;
    return _reportMissingOrAmbiguousMember(
      fileOffset,
      noLength,
      receiverType,
      indexSetName,
      _createInvalidInvocation(
        fileOffset,
        receiver,
        indexSetName,
        new Arguments([index, value])..fileOffset = fileOffset,
      ),
      extensionAccessCandidates,
      codeMissing,
      diag.ambiguousExtensionOperator,
    );
  }

  Expression createMissingBinary(
    int fileOffset,
    Expression left,
    DartType leftType,
    Name binaryName,
    Expression right, {
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    assert(binaryName != equalsName);
    Template<Message Function({required String name, required DartType type})>
    codeMissing = diag.undefinedOperator;
    return _reportMissingOrAmbiguousMember(
      fileOffset,
      binaryName.text.length,
      leftType,
      binaryName,
      _createInvalidInvocation(
        fileOffset,
        left,
        binaryName,
        new Arguments([right])..fileOffset = fileOffset,
      ),
      extensionAccessCandidates,
      codeMissing,
      diag.ambiguousExtensionOperator,
    );
  }

  Expression createMissingUnary(
    int fileOffset,
    Expression expression,
    DartType expressionType,
    Name unaryName, {
    List<ExtensionAccessCandidate>? extensionAccessCandidates,
  }) {
    Template<Message Function({required String name, required DartType type})>
    codeMissing = diag.undefinedOperator;
    return _reportMissingOrAmbiguousMember(
      fileOffset,
      unaryName == unaryMinusName ? 1 : unaryName.text.length,
      expressionType,
      unaryName,
      _createInvalidInvocation(
        fileOffset,
        expression,
        unaryName,
        new Arguments([])..fileOffset = fileOffset,
      ),
      extensionAccessCandidates,
      codeMissing,
      diag.ambiguousExtensionOperator,
    );
  }

  /// Creates a `e == null` test for the expression [left] using the
  /// [fileOffset] as file offset for the created nodes.
  Expression createEqualsNull(int fileOffset, Expression left) {
    return new EqualsNull(left)..fileOffset = fileOffset;
  }

  /// Reports an error if [typeArgument] is a generic function type.
  ///
  /// This is use for reporting generic function types used as a type argument,
  /// which was disallowed before the 'generic-metadata' feature was enabled.
  void checkGenericFunctionTypeArgument(DartType typeArgument, int fileOffset) {
    assert(!libraryBuilder.libraryFeatures.genericMetadata.isEnabled);
    if (isGenericFunctionTypeOrAlias(typeArgument)) {
      libraryBuilder.addProblem(
        diag.genericFunctionTypeInferredAsActualTypeArgument.withArguments(
          type: typeArgument,
        ),
        fileOffset,
        noLength,
        fileUri,
      );
    }
  }

  Expression? checkWebIntLiteralsErrorIfUnexact(
    int value,
    String? literal,
    int charOffset,
  ) {
    if (value >= 0 && value <= (1 << 53)) return null;
    if (!libraryBuilder
        .loader
        .target
        .backendTarget
        .errorOnUnexactWebIntLiterals) {
      return null;
    }
    BigInt asInt = new BigInt.from(value).toUnsigned(64);
    BigInt asDouble = new BigInt.from(asInt.toDouble());
    if (asInt == asDouble) return null;
    // Coverage-ignore-block(suite): Not run.
    String text = literal ?? value.toString();
    String nearest = text.startsWith('0x') || text.startsWith('0X')
        ? '0x${asDouble.toRadixString(16)}'
        : asDouble.toString();
    int length = literal?.length ?? noLength;
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: diag.webLiteralCannotBeRepresentedExactly.withArguments(
        integerLiteral: text,
        nearestJsValue: nearest,
      ),
      fileUri: fileUri,
      fileOffset: charOffset,
      length: length,
    );
  }

  /// Creates [Arguments] from [node].
  ///
  /// This records the relation which data for testing.
  Arguments createArgumentsFromInternalNode(
    List<DartType> typeArguments,
    List<Expression> positionalArguments,
    List<NamedExpression> namedArguments,
    ActualArguments node,
  ) {
    Arguments arguments = node.toArguments(
      typeArguments,
      positionalArguments,
      namedArguments,
    );
    if (dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      dataForTesting!.externalToInternalNodeMap[arguments] = node;
    }
    return arguments;
  }

  /// The client of type inference should call this method after asking
  /// inference to visit a node.  This performs assertions to make sure that
  /// temporary type inference state has been properly cleaned up.
  void checkCleanState();

  /// Performs preliminary computations before inferring the body of a function.
  ///
  /// [parameters] are those of the function being inferred.
  ScopeProviderInfo beginFunctionBodyInference(
    List<VariableDeclaration> parameters, {
    required ThisVariable? internalThisVariable,
  });

  /// Performs finishing computations after inferring the body of a function.
  void endFunctionBodyInference(ScopeProviderInfo scopeProviderInfo);
}

/// Describes assignability kind of one type to another.
enum AssignabilityKind {
  /// Unconditionally assignable.
  assignable,

  /// Assignable, but needs an implicit downcast.
  assignableCast,

  /// Unconditionally unassignable.
  unassignable,

  /// Trying to use void in an inappropriate context.
  unassignableVoid,

  /// The right-hand side type is precise, and the downcast will fail.
  unassignablePrecise,

  /// Unassignable because the tear-off can't be done on the nullable receiver.
  unassignableCantTearoff,

  /// Unassignable only because of nullability modifiers.
  unassignableNullability,
}

class AssignabilityResult {
  final AssignabilityKind kind;
  final DartType? subtype; // Can be null.
  final DartType? supertype; // Can be null.
  final bool needsTearOff;
  final ImplicitInstantiation? implicitInstantiation;

  const AssignabilityResult(
    this.kind, {
    required this.needsTearOff,
    this.implicitInstantiation,
  }) : subtype = null,
       supertype = null;

  AssignabilityResult.withTypes(
    this.kind,
    this.subtype,
    this.supertype, {
    required this.needsTearOff,
    this.implicitInstantiation,
  });
}

/// Convenient way to return both a tear-off expression and its type.
class TypedTearoff {
  final DartType tearoffType;
  final Expression tearoff;

  TypedTearoff(this.tearoffType, this.tearoff);
}

FunctionType replaceReturnType(FunctionType functionType, DartType returnType) {
  return new FunctionType(
    functionType.positionalParameters,
    returnType,
    functionType.declaredNullability,
    requiredParameterCount: functionType.requiredParameterCount,
    namedParameters: functionType.namedParameters,
    typeParameters: functionType.typeParameters,
  );
}

class _WhyNotPromotedVisitor
    implements
        NonPromotionReasonVisitor<
          List<LocatedMessage>,
          Node,
          ExpressionVariable
        > {
  final InferenceVisitorBase inferrer;

  Member? propertyReference;

  _WhyNotPromotedVisitor(this.inferrer);

  @override
  List<LocatedMessage> visitDemoteViaExplicitWrite(
    DemoteViaExplicitWrite<ExpressionVariable> reason,
  ) {
    TreeNode node = reason.node as TreeNode;
    if (inferrer.dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      inferrer
              .dataForTesting!
              .flowAnalysisResult
              .nonPromotionReasonTargets[node] =
          reason.shortName;
    }
    int offset = node.fileOffset;
    return [
      diag.variableCouldBeNullDueToWrite
          .withArguments(
            variableName: reason.variable.cosmeticName!,
            documentationUrl: reason.documentationLink.url,
          )
          .withLocation(inferrer.fileUri, offset, noLength),
    ];
  }

  @override
  List<LocatedMessage> visitPropertyNotPromotedForNonInherentReason(
    PropertyNotPromotedForNonInherentReason reason,
  ) {
    FieldNonPromotabilityInfo? fieldNonPromotabilityInfo =
        inferrer.libraryBuilder.fieldNonPromotabilityInfo;
    if (fieldNonPromotabilityInfo == null) {
      // Coverage-ignore-block(suite): Not run.
      assert(
        false,
        "Missing field non-promotability info for "
        "${inferrer.libraryBuilder}.",
      );
      return const [];
    }
    FieldNameNonPromotabilityInfo<
      Class,
      SourceMemberBuilder,
      SourceMemberBuilder
    >?
    fieldNameInfo =
        fieldNonPromotabilityInfo.fieldNameInfo[reason.propertyName];
    List<LocatedMessage> messages = [];
    if (fieldNameInfo != null) {
      for (SourceMemberBuilder field in fieldNameInfo.conflictingFields) {
        messages.add(
          diag.fieldNotPromotedBecauseConflictingField
              .withArguments(
                propertyName: reason.propertyName,
                conflictingFieldClassName:
                    field.readTarget!.enclosingClass!.name,
                documentationUrl: NonPromotionDocumentationLink
                    .conflictingNonPromotableField
                    .url,
              )
              .withLocation(field.fileUri, field.fileOffset, noLength),
        );
      }
      for (SourceMemberBuilder getter in fieldNameInfo.conflictingGetters) {
        messages.add(
          diag.fieldNotPromotedBecauseConflictingGetter
              .withArguments(
                propertyName: reason.propertyName,
                conflictingGetterClassName:
                    getter.readTarget!.enclosingClass!.name,
                documentationUrl:
                    NonPromotionDocumentationLink.conflictingGetter.url,
              )
              .withLocation(getter.fileUri, getter.fileOffset, noLength),
        );
      }
      for (Class nsmClass in fieldNameInfo.conflictingNsmClasses) {
        messages.add(
          diag.fieldNotPromotedBecauseConflictingNsmForwarder
              .withArguments(
                propertyName: reason.propertyName,
                conflictingNsmClassName: nsmClass.name,
                documentationUrl: NonPromotionDocumentationLink
                    .conflictingNoSuchMethodForwarder
                    .url,
              )
              .withLocation(nsmClass.fileUri, nsmClass.fileOffset, noLength),
        );
      }
    }
    if (reason.fieldPromotionEnabled) {
      // The only possible non-inherent reasons for field promotion to fail are
      // because of conflicts and because field promotion is disabled. So if
      // field promotion is enabled, the loops above should have found a
      // conflict.
      assert(messages.isNotEmpty);
    } else {
      _addFieldPromotionUnavailableMessage(reason, messages);
    }
    return messages;
  }

  @override
  List<LocatedMessage> visitPropertyNotPromotedForInherentReason(
    PropertyNotPromotedForInherentReason reason,
  ) {
    Object? member = reason.propertyMember;
    if (member is Member) {
      if (member case Procedure(:var stubTarget?)) {
        // Use the stub target so that the context message has a better source
        // location.
        member = stubTarget;
      }
      propertyReference = member;
      Template<
        Message Function({
          required String propertyName,
          required String documentationUrl,
        })
      >
      template = switch (reason.whyNotPromotable) {
        PropertyNonPromotabilityReason.isNotField =>
          diag.fieldNotPromotedBecauseNotField,
        PropertyNonPromotabilityReason.isNotPrivate =>
          diag.fieldNotPromotedBecauseNotPrivate,
        PropertyNonPromotabilityReason.isExternal =>
          diag.fieldNotPromotedBecauseExternal,
        PropertyNonPromotabilityReason.isNotFinal =>
          diag.fieldNotPromotedBecauseNotFinal,
      };
      List<LocatedMessage> messages = [
        template
            .withArguments(
              propertyName: reason.propertyName,
              documentationUrl: reason.documentationLink.url,
            )
            .withLocation(member.fileUri, member.fileOffset, noLength),
      ];
      if (!reason.fieldPromotionEnabled) {
        // Coverage-ignore-block(suite): Not run.
        _addFieldPromotionUnavailableMessage(reason, messages);
      }
      return messages;
    } else {
      // Coverage-ignore-block(suite): Not run.
      assert(
        member == null,
        'Unrecognized property member: ${member.runtimeType}',
      );
      return const [];
    }
  }

  @override
  List<LocatedMessage> visitThisNotPromoted(ThisNotPromoted reason) {
    return [
      diag.thisNotPromoted
          .withArguments(documentationUrl: reason.documentationLink.url)
          .withoutLocation(),
    ];
  }

  void _addFieldPromotionUnavailableMessage(
    PropertyNotPromoted reason,
    List<LocatedMessage> messages,
  ) {
    Object? member = reason.propertyMember;
    if (member is Member) {
      messages.add(
        diag.fieldNotPromotedBecauseNotEnabled
            .withArguments(
              variableName: reason.propertyName,
              documentationUrl:
                  NonPromotionDocumentationLink.fieldPromotionUnavailable.url,
            )
            .withLocation(member.fileUri, member.fileOffset, noLength),
      );
    }
  }
}

/// Sentinel type used as the result in top level inference when the type is
/// not needed.
// TODO(johnniwinther): Should we have a special DartType implementation for
// this.
final DartType noInferredType = new UnknownType();

class ImplicitInstantiation {
  /// The type arguments for the instantiation.
  final List<DartType> typeArguments;

  /// The function type before the instantiation.
  final FunctionType functionType;

  /// The function type after the instantiation.
  final DartType instantiatedType;

  ImplicitInstantiation(
    this.typeArguments,
    this.functionType,
    this.instantiatedType,
  );
}

/// Information about an invocation argument that needs to be resolved later due
/// to the fact that it's a function literal and the `inference-update-1`
/// feature is enabled.
class _DeferredArgumentInfo extends _ArgumentInfo {
  /// The unparenthesized argument expression.
  final FunctionExpression unparenthesizedExpression;

  _DeferredArgumentInfo({
    required super.argument,
    required super.formalType,
    required this.unparenthesizedExpression,
  });

  // Coverage-ignore(suite): Not run.
  /// The argument expression (possibly wrapped in an arbitrary number of
  /// ParenthesizedExpressions).
  Expression get argumentExpression => argument.expression;
}

/// Extension of the shared [FunctionLiteralDependencies] logic used by the
/// front end.
class _FunctionLiteralDependencies
    extends
        FunctionLiteralDependencies<
          StructuralParameter,
          _ArgumentInfo,
          _DeferredArgumentInfo
        > {
  _FunctionLiteralDependencies(
    Iterable<_DeferredArgumentInfo> deferredParamInfo,
    Iterable<StructuralParameter> typeParameters,
    List<_ArgumentInfo> undeferredParamInfo,
  ) : super(deferredParamInfo, typeParameters, undeferredParamInfo);

  @override
  Iterable<StructuralParameter> typeVarsFreeInParamParams(
    _DeferredArgumentInfo param,
  ) {
    DartType type = param.formalType;
    if (type is FunctionType) {
      Map<Object, DartType> parameterMap = _computeParameterMap(type);
      Set<Object> explicitlyTypedParameters =
          _computeExplicitlyTypedParameterSet(param.unparenthesizedExpression);
      Set<StructuralParameter> result = {};
      for (MapEntry<Object, DartType> entry in parameterMap.entries) {
        if (explicitlyTypedParameters.contains(entry.key)) continue;
        result.addAll(allFreeTypeParameters(entry.value));
      }
      return result;
    } else {
      return const [];
    }
  }

  @override
  Iterable<StructuralParameter> typeVarsFreeInParamReturns(
    _ArgumentInfo param,
  ) {
    DartType type = param.formalType;
    if (type is FunctionType) {
      return allFreeTypeParameters(type.returnType);
    } else {
      return allFreeTypeParameters(type);
    }
  }
}

/// Information about an invocation argument that may or may not have already
/// been resolved.
class _ArgumentInfo {
  /// The actual argument.
  final Argument argument;

  /// The (unsubstituted) type of the formal parameter corresponding to this
  /// argument.
  final DartType formalType;

  /// The actual type of the argument.
  ///
  /// Initially we don't have an inferred type, so we fill it in with
  /// [UnknownType].  Later, when we infer a type, we'll replace it.
  DartType actualType = const UnknownType();

  /// The (substituted) type of the formal parameter corresponding to this
  /// argument.
  DartType computeInferredFormalType(FunctionTypeInstantiator? instantiator) =>
      instantiator != null ? instantiator.substitute(formalType) : formalType;

  /// If this is an argument to a call to `identical`, this will hold the
  /// flow analysis information computed during inference.
  ExpressionInfo? identicalInfo;

  /// The holds the possibly coerced result of the inference.
  ///
  /// This is used to check the argument for assignability.
  ExpressionInferenceResult? argumentInferenceResult;

  /// Set to `true` if this argument is a duplicate named argument.
  ///
  /// If `true`, the argument is not included in the output AST.
  bool isDuplicateNamed = false;

  _ArgumentInfo({required this.argument, required this.formalType});

  /// Indicates whether this is a named argument.
  bool get isNamed => argument is NamedArgument;

  /// Returns `true` if the argument expression should be coerced.
  bool get coerceExpression => !argument.isSuperParameter;
}

extension on List<_ArgumentInfo> {
  (List<Expression> positional, List<NamedExpression> named)
  computeArguments() {
    List<Expression> positional = [];
    List<NamedExpression> named = [];
    for (_ArgumentInfo argumentInfo in this) {
      if (argumentInfo.isDuplicateNamed) {
        continue;
      }
      Argument argument = argumentInfo.argument;
      switch (argument) {
        case PositionalArgument():
          positional.add(argument.expression);
        case NamedArgument():
          named.add(argument.namedExpression);
      }
    }
    return (positional, named);
  }
}

class _ObjectAccessDescriptor {
  final DartType receiverType;
  final Name name;
  final DartType receiverBound;
  final Class classNode;
  final bool hasNonObjectMemberAccess;
  final bool isSetter;
  final int fileOffset;

  _ObjectAccessDescriptor({
    required this.receiverType,
    required this.name,
    required this.receiverBound,
    required this.classNode,
    required this.hasNonObjectMemberAccess,
    required this.isSetter,
    required this.fileOffset,
  });

  /// Returns the [ObjectAccessTarget] corresponding to this descriptor.
  ObjectAccessTarget findNonExtensionTarget(InferenceVisitorBase visitor) {
    return _findNonExtensionTargetInternal(visitor, name, isSetter: isSetter);
  }

  ObjectAccessTarget _findNonExtensionTargetInternal(
    InferenceVisitorBase visitor,
    Name name, {
    required bool isSetter,
  }) {
    final DartType receiverBound = this.receiverBound;

    if (receiverBound is InterfaceType) {
      // This is what happens most often: Skip the other `if`s.
    } else if (receiverBound is FunctionType && name == callName && !isSetter) {
      return hasNonObjectMemberAccess
          ? new ObjectAccessTarget.callFunction(receiverType)
          : new ObjectAccessTarget.nullableCallFunction(receiverType);
    } else if (receiverBound is NeverType) {
      switch (receiverBound.nullability) {
        case Nullability.nonNullable:
          Member? interfaceMember = visitor._getInterfaceMember(
            classNode,
            name,
            isSetter,
          );
          FunctionType? functionType;
          if (interfaceMember is Procedure) {
            // The member exists on `Object` but has a special function type
            // that we compute here.
            FunctionNode function = interfaceMember.function;
            assert(
              function.namedParameters.isEmpty,
              "Unexpected named parameters on $classNode member "
              "$interfaceMember.",
            );
            assert(
              function.typeParameters.isEmpty,
              "Unexpected type parameters on $classNode member "
              "$interfaceMember.",
            );
            functionType = new FunctionType(
              new List<DartType>.filled(
                function.positionalParameters.length,
                const DynamicType(),
              ),
              const NeverType.nonNullable(),
              Nullability.nonNullable,
            );
          }
          return new ObjectAccessTarget.never(
            member: interfaceMember,
            functionType: functionType,
          );
        case Nullability.nullable:
          // Never? is equivalent to Null.
          return visitor.findInterfaceMember(
            const NullType(),
            name,
            fileOffset,
            isSetter: isSetter,
          );
        // Coverage-ignore(suite): Not run.
        case Nullability.undetermined:
          return internalProblem(
            diag.internalProblemUnsupportedNullability.withArguments(
              nullability: "${receiverBound.nullability}",
              type: receiverBound,
            ),
            fileOffset,
            visitor.libraryBuilder.fileUri,
          );
      }
    } else if (receiverBound is RecordType && !isSetter) {
      String text = name.text;
      int? index = tryParseRecordPositionalGetterName(
        text,
        receiverBound.positional.length,
      );
      if (index != null) {
        DartType fieldType = receiverBound.positional[index];
        return hasNonObjectMemberAccess
            ? new RecordIndexTarget.nonNullable(receiverBound, fieldType, index)
            : new RecordIndexTarget.nullable(receiverBound, fieldType, index);
      }
      for (NamedType field in receiverBound.named) {
        if (field.name == text) {
          return hasNonObjectMemberAccess
              ? new RecordNameTarget.nonNullable(
                  receiverBound,
                  field.type,
                  field.name,
                )
              : new RecordNameTarget.nullable(
                  receiverBound,
                  field.type,
                  field.name,
                );
        }
      }
    } else if (receiverBound is ExtensionType) {
      ObjectAccessTarget? target = visitor._findExtensionTypeMember(
        receiverType,
        receiverBound,
        name,
        fileOffset,
        isSetter: isSetter,
        hasNonObjectMemberAccess: hasNonObjectMemberAccess,
      );
      if (target != null) {
        return target;
      }
    }

    ObjectAccessTarget? target;
    Member? interfaceMember = visitor._getInterfaceMember(
      classNode,
      name,
      isSetter,
    );
    if (interfaceMember != null) {
      target = new ObjectAccessTarget.interfaceMember(
        receiverType,
        interfaceMember,
        hasNonObjectMemberAccess: hasNonObjectMemberAccess,
      );
    } else if (receiverBound is DynamicType) {
      target = const ObjectAccessTarget.dynamic();
    } else if (receiverBound is InvalidType) {
      target = const ObjectAccessTarget.invalid();
    } else if (receiverBound is InterfaceType &&
        receiverBound.classNode == visitor.coreTypes.functionClass &&
        name == callName &&
        !isSetter) {
      target = hasNonObjectMemberAccess
          ? new ObjectAccessTarget.callFunction(receiverType)
          : new ObjectAccessTarget.nullableCallFunction(receiverType);
    } else {
      target = const ObjectAccessTarget.missing();
    }
    return target;
  }

  Name? _complementaryName;

  bool? _complementaryIsSetter;

  void _computeComplementaryNameAndKind() {
    if (_complementaryName == null) {
      Name otherName = name;
      bool otherIsSetter;
      if (name == indexGetName) {
        // [] must be checked against []=.
        otherName = indexSetName;
        otherIsSetter = false;
      } else if (name == indexSetName) {
        // []= must be checked against [].
        otherName = indexGetName;
        otherIsSetter = false;
      } else {
        otherName = name;
        otherIsSetter = !isSetter;
      }
      _complementaryName = otherName;
      _complementaryIsSetter = otherIsSetter;
    }
  }

  /// Returns `true` if this descriptor has a valid target for the complementary
  /// getter/setter access corresponding to this descriptor.
  bool hasComplementaryTarget(InferenceVisitorBase visitor) {
    _computeComplementaryNameAndKind();
    Name otherName = _complementaryName!;
    bool otherIsSetter = _complementaryIsSetter!;
    ObjectAccessTarget other = _findNonExtensionTargetInternal(
      visitor,
      otherName,
      isSetter: otherIsSetter,
    );
    switch (other.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.superMember:
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.ambiguous:
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.extensionTypeRepresentation:
        return true;
      case ObjectAccessTargetKind.nullableInstanceMember:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.nullableRecordIndexed:
      case ObjectAccessTargetKind.nullableRecordNamed:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
      // Coverage-ignore(suite): Not run.
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        return false;
    }
  }
}
