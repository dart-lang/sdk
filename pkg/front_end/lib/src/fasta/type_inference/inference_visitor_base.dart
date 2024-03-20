// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/deferred_function_literal_heuristic.dart';
import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/names.dart';
import 'package:kernel/src/bounds_checks.dart'
    show calculateBounds, isGenericFunctionTypeOrAlias;
import 'package:kernel/src/future_value_type.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../api_prototype/experimental_flags.dart';
import '../../base/instrumentation.dart'
    show
        Instrumentation,
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;
import '../../base/nnbd_mode.dart';
import '../../testing/id_extractor.dart';
import '../../testing/id_testing_utils.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../codes/fasta_codes.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart' show hasAnyTypeVariables;
import '../problems.dart' show internalProblem, unhandled;
import '../source/source_constructor_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart'
    show FieldNonPromotabilityInfo, SourceLibraryBuilder;
import '../source/source_procedure_builder.dart';
import '../util/helpers.dart';
import 'closure_context.dart';
import 'external_ast_helper.dart';
import 'inference_helper.dart' show InferenceHelper;
import 'inference_results.dart';
import 'inference_visitor.dart';
import 'object_access_target.dart';
import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;
import 'type_demotion.dart';
import 'type_inference_engine.dart';
import 'type_inferrer.dart' show TypeInferrerImpl;
import 'type_schema.dart' show isKnown, UnknownType;
import 'type_schema_elimination.dart' show greatestClosure;
import 'type_schema_environment.dart'
    show
        getNamedParameterType,
        getPositionalParameterType,
        TypeVariableEliminator,
        TypeSchemaEnvironment;

/// Given a [FunctionExpression], computes a set whose elements consist of (a)
/// an integer corresponding to the zero-based index of each positional
/// parameter of the function expression that has an explicit type annotation,
/// and (b) a string corresponding to the name of each named parameter of the
/// function expression that has an explicit type annotation.
Set<Object> _computeExplicitlyTypedParameterSet(
    FunctionExpression functionExpression) {
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
        namedType.name: namedType.type
    };

/// Computes a list of [_ParamInfo] objects corresponding to the invocation
/// parameters that were *not* deferred.
List<_ParamInfo> _computeUndeferredParamInfo(List<DartType> formalTypes,
    List<_DeferredParamInfo> deferredFunctionLiterals) {
  Set<int> evaluationOrderIndicesAlreadyCovered = {
    for (_DeferredParamInfo functionLiteral in deferredFunctionLiterals)
      functionLiteral.evaluationOrderIndex
  };
  assert(evaluationOrderIndicesAlreadyCovered
      .every((i) => 0 <= i && i < formalTypes.length));
  return [
    for (int i = 0; i < formalTypes.length; i++)
      if (!evaluationOrderIndicesAlreadyCovered.contains(i))
        new _ParamInfo(formalTypes[i])
  ];
}

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

  final InferenceHelper _helper;

  InferenceVisitorBase(this._inferrer, this._helper);

  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables =>
      _inferrer.assignedVariables;

  FunctionType get unknownFunction => _inferrer.unknownFunction;

  InterfaceType? get thisType => _inferrer.thisType;

  Uri get uriForInstrumentation => _inferrer.uriForInstrumentation;

  Instrumentation? get instrumentation => _inferrer.instrumentation;

  ClassHierarchyBase get hierarchyBuilder => _inferrer.engine.hierarchyBuilder;

  ClassHierarchyMembers get membersBuilder => _inferrer.engine.membersBuilder;

  InferenceDataForTesting? get dataForTesting => _inferrer.dataForTesting;

  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration, DartType>
      get flowAnalysis => _inferrer.flowAnalysis;

  /// Provides access to the [OperationsCfe] object.  This is needed by
  /// [isAssignable] and for caching types.
  OperationsCfe get cfeOperations => _inferrer.operations;

  TypeSchemaEnvironment get typeSchemaEnvironment =>
      _inferrer.typeSchemaEnvironment;

  TypeInferenceEngine get engine => _inferrer.engine;

  InferenceHelper get helper => _helper;

  CoreTypes get coreTypes => engine.coreTypes;

  @pragma("vm:prefer-inline")
  SourceLibraryBuilder get libraryBuilder => _inferrer.libraryBuilder;

  bool get isInferenceUpdate1Enabled =>
      libraryBuilder.isInferenceUpdate1Enabled;

  bool get isNonNullableByDefault => libraryBuilder.isNonNullableByDefault;

  NnbdMode get nnbdMode => libraryBuilder.loader.nnbdMode;

  LibraryFeatures get libraryFeatures => libraryBuilder.libraryFeatures;

  DartType get bottomType =>
      isNonNullableByDefault ? const NeverType.nonNullable() : const NullType();

  StaticTypeContext get staticTypeContext => _inferrer.staticTypeContext;

  DartType computeGreatestClosure(DartType type) {
    return greatestClosure(type, const DynamicType(), bottomType);
  }

  DartType computeGreatestClosure2(DartType type) {
    return greatestClosure(
        type,
        isNonNullableByDefault
            ? coreTypes.objectNullableRawType
            : const DynamicType(),
        bottomType);
  }

  DartType computeNullable(DartType type) {
    if (type is NullType || type is NeverType) {
      return const NullType();
    }
    if (libraryBuilder.isNonNullableByDefault) {
      return cfeOperations.getNullableType(type);
    } else {
      return cfeOperations.getLegacyType(type);
    }
  }

  Expression createReachabilityError(int fileOffset, Message errorMessage) {
    Arguments arguments = new Arguments([
      new StringLiteral(errorMessage.problemMessage)..fileOffset = fileOffset
    ])
      ..fileOffset = fileOffset;
    return new Throw(
        new ConstructorInvocation(
            coreTypes.reachabilityErrorConstructor, arguments)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset
      ..forErrorHandling = true;
  }

  /// Computes a list of context messages explaining why [receiver] was not
  /// promoted, to be used when reporting an error for a larger expression
  /// containing [receiver].  [node] is the containing tree node.
  List<LocatedMessage>? getWhyNotPromotedContext(
      Map<DartType, NonPromotionReason>? whyNotPromoted,
      TreeNode node,
      bool Function(DartType) typeFilter) {
    List<LocatedMessage>? context;
    if (whyNotPromoted != null && whyNotPromoted.isNotEmpty) {
      _WhyNotPromotedVisitor whyNotPromotedVisitor =
          new _WhyNotPromotedVisitor(this);
      for (MapEntry<DartType, NonPromotionReason> entry
          in whyNotPromoted.entries) {
        if (!typeFilter(entry.key)) continue;
        List<LocatedMessage> messages =
            entry.value.accept(whyNotPromotedVisitor);
        if (dataForTesting != null) {
          String nonPromotionReasonText = entry.value.shortName;
          List<String> args = <String>[];
          if (whyNotPromotedVisitor.propertyReference != null) {
            Id id = computeMemberId(whyNotPromotedVisitor.propertyReference!);
            args.add('target: $id');
          }
          if (whyNotPromotedVisitor.propertyType != null) {
            String typeText = typeToText(whyNotPromotedVisitor.propertyType!,
                TypeRepresentation.analyzerNonNullableByDefault);
            args.add('type: $typeText');
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
  bool get shouldThrowUnsoundnessException =>
      isNonNullableByDefault && nnbdMode != NnbdMode.Strong;

  void registerIfUnreachableForTesting(TreeNode node, {bool? isReachable}) {
    if (dataForTesting == null) return;
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
    SourceConstructorBuilder? constructorBuilder = engine.beingInferred[target];
    if (constructorBuilder != null) {
      // There is a cyclic dependency where inferring the types of the
      // initializing formals of a constructor required us to infer the
      // corresponding field type which required us to know the type of the
      // constructor.
      String name = constructorBuilder.declarationBuilder.name;
      if (target.name.text.isNotEmpty) {
        // TODO(ahe): Use `inferrer.helper.constructorNameForDiagnostics`
        // instead. However, `inferrer.helper` may be null.
        name += ".${target.name.text}";
      }
      constructorBuilder.libraryBuilder.addProblem(
          templateCantInferTypeDueToCircularity.withArguments(name),
          target.fileOffset,
          name.length,
          target.fileUri);
      // TODO(johnniwinther): Is this needed? VariableDeclaration.type is
      // non-nullable so the loops have no effect.
      /*for (VariableDeclaration declaration
          in target.function.positionalParameters) {
        declaration.type ??= const InvalidType();
      }
      for (VariableDeclaration declaration in target.function.namedParameters) {
        declaration.type ??= const InvalidType();
      }*/
    } else if ((constructorBuilder = engine.toBeInferred[target]) != null) {
      engine.toBeInferred.remove(target);
      engine.beingInferred[target] = constructorBuilder!;
      constructorBuilder.inferFormalTypes(hierarchyBuilder);
      engine.beingInferred.remove(target);
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

  bool isAssignable(DartType contextType, DartType expressionType) =>
      cfeOperations.isAssignableTo(expressionType, contextType);

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
      DartType expectedType, DartType expressionType, Expression expression,
      {int? fileOffset,
      DartType? declaredContextType,
      DartType? runtimeCheckedType,
      bool isVoidAllowed = false,
      bool coerceExpression = true,
      Template<Message Function(DartType, DartType, bool)>? errorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityErrorTemplate,
      Template<Message Function(DartType, bool)>? nullabilityNullErrorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityNullTypeErrorTemplate,
      Template<Message Function(DartType, DartType, DartType, DartType, bool)>?
          nullabilityPartErrorTemplate,
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    return ensureAssignableResult(expectedType,
            new ExpressionInferenceResult(expressionType, expression),
            fileOffset: fileOffset,
            declaredContextType: declaredContextType,
            runtimeCheckedType: runtimeCheckedType,
            isVoidAllowed: isVoidAllowed,
            coerceExpression: coerceExpression,
            errorTemplate: errorTemplate,
            nullabilityErrorTemplate: nullabilityErrorTemplate,
            nullabilityNullErrorTemplate: nullabilityNullErrorTemplate,
            nullabilityNullTypeErrorTemplate: nullabilityNullTypeErrorTemplate,
            nullabilityPartErrorTemplate: nullabilityPartErrorTemplate,
            whyNotPromoted: whyNotPromoted)
        .expression;
  }

  /// Coerces expression ensuring its assignability to [contextType]
  ///
  /// If the expression is assignable without coercion, [inferenceResult]
  /// is returned unchanged. If no coercion is possible for the given types,
  /// `null` is returned.
  ExpressionInferenceResult? coerceExpressionForAssignment(
      DartType contextType, ExpressionInferenceResult inferenceResult,
      {int? fileOffset,
      DartType? declaredContextType,
      DartType? runtimeCheckedType,
      bool isVoidAllowed = false,
      bool coerceExpression = true,
      required TreeNode? treeNodeForTesting}) {
    fileOffset ??= inferenceResult.expression.fileOffset;
    contextType = computeGreatestClosure(contextType);

    DartType initialContextType = runtimeCheckedType ?? contextType;

    Template<Message Function(DartType, DartType, bool)>?
        preciseTypeErrorTemplate =
        _getPreciseTypeErrorTemplate(inferenceResult.expression);
    AssignabilityResult assignabilityResult = _computeAssignabilityKind(
        contextType, inferenceResult.inferredType,
        isNonNullableByDefault: isNonNullableByDefault,
        isVoidAllowed: isVoidAllowed,
        isExpressionTypePrecise: preciseTypeErrorTemplate != null,
        coerceExpression: coerceExpression,
        fileOffset: fileOffset,
        treeNodeForTesting: treeNodeForTesting);

    if (assignabilityResult.needsTearOff) {
      TypedTearoff typedTearoff = _tearOffCall(
          inferenceResult.expression, inferenceResult.inferredType, fileOffset);
      inferenceResult = new ExpressionInferenceResult(
          typedTearoff.tearoffType, typedTearoff.tearoff);
    }
    if (assignabilityResult.implicitInstantiation != null) {
      inferenceResult = _applyImplicitInstantiation(
          assignabilityResult.implicitInstantiation,
          inferenceResult.inferredType,
          inferenceResult.expression);
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
              ..isForNonNullableByDefault = isNonNullableByDefault
              ..isForDynamic = expressionType is DynamicType
              ..fileOffset = fileOffset;
        flowAnalysis.forwardExpression(asExpression, expression);
        return new ExpressionInferenceResult(expressionType, asExpression,
            postCoercionType: initialContextType);
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
      default:
        return unhandled("${assignabilityResult}", "ensureAssignable",
            fileOffset, helper.uri);
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
      DartType contextType, ExpressionInferenceResult inferenceResult,
      {int? fileOffset,
      DartType? declaredContextType,
      DartType? runtimeCheckedType,
      bool isVoidAllowed = false,
      bool isCoercionAllowed = true,
      Template<Message Function(DartType, DartType, bool)>? errorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityErrorTemplate,
      Template<Message Function(DartType, bool)>? nullabilityNullErrorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityNullTypeErrorTemplate,
      Template<Message Function(DartType, DartType, DartType, DartType, bool)>?
          nullabilityPartErrorTemplate,
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    // [errorTemplate], [nullabilityErrorTemplate], and
    // [nullabilityPartErrorTemplate] should be provided together.
    assert((errorTemplate == null) == (nullabilityErrorTemplate == null) &&
        (nullabilityErrorTemplate == null) ==
            (nullabilityPartErrorTemplate == null));
    // [nullabilityNullErrorTemplate] and [nullabilityNullTypeErrorTemplate]
    // should be provided together.
    assert((nullabilityNullErrorTemplate == null) ==
        (nullabilityNullTypeErrorTemplate == null));
    errorTemplate ??= templateInvalidAssignmentError;
    if (nullabilityErrorTemplate == null) {
      // Use [templateInvalidAssignmentErrorNullabilityNull] only if no
      // specific [nullabilityErrorTemplate] template was passed.
      nullabilityNullErrorTemplate ??=
          templateInvalidAssignmentErrorNullabilityNull;
    }
    nullabilityNullTypeErrorTemplate ??= nullabilityErrorTemplate ??
        templateInvalidAssignmentErrorNullabilityNullType;
    nullabilityErrorTemplate ??= templateInvalidAssignmentErrorNullability;
    nullabilityPartErrorTemplate ??=
        templateInvalidAssignmentErrorPartNullability;

    fileOffset ??= inferenceResult.expression.fileOffset;
    contextType = computeGreatestClosure(contextType);

    Template<Message Function(DartType, DartType, bool)>?
        preciseTypeErrorTemplate =
        _getPreciseTypeErrorTemplate(inferenceResult.expression);
    AssignabilityResult assignabilityResult = _computeAssignabilityKind(
        contextType, inferenceResult.inferredType,
        isNonNullableByDefault: isNonNullableByDefault,
        isVoidAllowed: isVoidAllowed,
        isExpressionTypePrecise: preciseTypeErrorTemplate != null,
        coerceExpression: isCoercionAllowed,
        fileOffset: fileOffset,
        treeNodeForTesting: inferenceResult.expression);

    if (assignabilityResult.needsTearOff) {
      TypedTearoff typedTearoff = _tearOffCall(
          inferenceResult.expression, inferenceResult.inferredType, fileOffset);
      inferenceResult = new ExpressionInferenceResult(
          typedTearoff.tearoffType, typedTearoff.tearoff);
    }
    if (assignabilityResult.implicitInstantiation != null) {
      inferenceResult = _applyImplicitInstantiation(
          assignabilityResult.implicitInstantiation,
          inferenceResult.inferredType,
          inferenceResult.expression);
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
            errorTemplate.withArguments(expressionType,
                declaredContextType ?? contextType, isNonNullableByDefault));
        break;
      case AssignabilityKind.unassignableVoid:
        // Error: not assignable.  Perform error recovery.
        result = helper.wrapInProblem(
            expression, messageVoidExpression, expression.fileOffset, noLength);
        break;
      case AssignabilityKind.unassignablePrecise:
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        result = helper.wrapInProblem(
            expression,
            preciseTypeErrorTemplate!.withArguments(
                expressionType, contextType, isNonNullableByDefault),
            expression.fileOffset,
            noLength);
        break;
      case AssignabilityKind.unassignableCantTearoff:
        result = _wrapTearoffErrorExpression(
            expression, contextType, templateNullableTearoffError);
        break;
      case AssignabilityKind.unassignableNullability:
        if (expressionType == assignabilityResult.subtype &&
            contextType == assignabilityResult.supertype) {
          if (expression is NullLiteral &&
              nullabilityNullErrorTemplate != null) {
            result = _wrapUnassignableExpression(
                expression,
                expressionType,
                contextType,
                nullabilityNullErrorTemplate.withArguments(
                    declaredContextType ?? contextType,
                    isNonNullableByDefault));
          } else if (expressionType is NullType) {
            result = _wrapUnassignableExpression(
                expression,
                expressionType,
                contextType,
                nullabilityNullTypeErrorTemplate.withArguments(
                    expressionType,
                    declaredContextType ?? contextType,
                    isNonNullableByDefault));
          } else {
            whyNotPromoted ??= flowAnalysis.whyNotPromoted(expression);
            result = _wrapUnassignableExpression(
                expression,
                expressionType,
                contextType,
                nullabilityErrorTemplate.withArguments(expressionType,
                    declaredContextType ?? contextType, isNonNullableByDefault),
                context: getWhyNotPromotedContext(
                    whyNotPromoted.call(),
                    expression,
                    (type) => typeSchemaEnvironment.isSubtypeOf(type,
                        contextType, SubtypeCheckMode.withNullabilities)));
          }
        } else {
          result = _wrapUnassignableExpression(
              expression,
              expressionType,
              contextType,
              nullabilityPartErrorTemplate.withArguments(
                  expressionType,
                  declaredContextType ?? contextType,
                  assignabilityResult.subtype!,
                  assignabilityResult.supertype!,
                  isNonNullableByDefault));
        }
        break;
      default:
        return unhandled("${assignabilityResult}", "ensureAssignable",
            fileOffset, helper.uri);
    }

    if (result != null) {
      flowAnalysis.forwardExpression(result, expression);
      return new ExpressionInferenceResult(expressionType, result,
          postCoercionType: postCoercionType);
    } else {
      return inferenceResult;
    }
  }

  /// Same as [ensureAssignable], but accepts an [ExpressionInferenceResult]
  /// rather than an expression and a type separately.  If no change is made,
  /// [inferenceResult] is returned unchanged.
  ExpressionInferenceResult ensureAssignableResult(
      DartType contextType, ExpressionInferenceResult inferenceResult,
      {int? fileOffset,
      DartType? declaredContextType,
      DartType? runtimeCheckedType,
      bool isVoidAllowed = false,
      bool coerceExpression = true,
      Template<Message Function(DartType, DartType, bool)>? errorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityErrorTemplate,
      Template<Message Function(DartType, bool)>? nullabilityNullErrorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityNullTypeErrorTemplate,
      Template<Message Function(DartType, DartType, DartType, DartType, bool)>?
          nullabilityPartErrorTemplate,
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    if (coerceExpression) {
      ExpressionInferenceResult? coercionResult = coerceExpressionForAssignment(
          contextType, inferenceResult,
          fileOffset: fileOffset,
          declaredContextType: declaredContextType,
          runtimeCheckedType: runtimeCheckedType,
          isVoidAllowed: isVoidAllowed,
          coerceExpression: coerceExpression,
          treeNodeForTesting: inferenceResult.expression);
      if (coercionResult != null) {
        return coercionResult;
      }
    }

    inferenceResult = reportAssignabilityErrors(contextType, inferenceResult,
        fileOffset: fileOffset,
        declaredContextType: declaredContextType,
        runtimeCheckedType: runtimeCheckedType,
        isVoidAllowed: isVoidAllowed,
        isCoercionAllowed: coerceExpression,
        errorTemplate: errorTemplate,
        nullabilityErrorTemplate: nullabilityErrorTemplate,
        nullabilityNullErrorTemplate: nullabilityNullErrorTemplate,
        nullabilityNullTypeErrorTemplate: nullabilityNullTypeErrorTemplate,
        nullabilityPartErrorTemplate: nullabilityPartErrorTemplate,
        whyNotPromoted: whyNotPromoted);

    return inferenceResult;
  }

  Expression _wrapTearoffErrorExpression(Expression expression,
      DartType contextType, Template<Message Function(String)> template) {
    Expression errorNode = new AsExpression(
        expression,
        // TODO(johnniwinther): Fix this.
        // TODO(ahe): The outline phase doesn't correctly remove invalid
        // uses of type variables, for example, on static members. Once
        // that has been fixed, we should always be able to use
        // [contextType] directly here.
        hasAnyTypeVariables(contextType)
            ? const NeverType.nonNullable()
            : contextType)
      ..isTypeError = true
      ..fileOffset = expression.fileOffset;
    if (contextType is! InvalidType) {
      errorNode = helper.wrapInProblem(
          errorNode,
          template.withArguments(callName.text),
          errorNode.fileOffset,
          noLength);
    }
    return errorNode;
  }

  Expression _wrapUnassignableExpression(Expression expression,
      DartType expressionType, DartType contextType, Message message,
      {List<LocatedMessage>? context}) {
    Expression errorNode = new AsExpression(
        expression,
        // TODO(johnniwinther): Fix this.
        // TODO(ahe): The outline phase doesn't correctly remove invalid
        // uses of type variables, for example, on static members. Once
        // that has been fixed, we should always be able to use
        // [contextType] directly here.
        hasAnyTypeVariables(contextType)
            ? const NeverType.nonNullable()
            : contextType)
      ..isTypeError = true
      ..isForNonNullableByDefault = isNonNullableByDefault
      ..fileOffset = expression.fileOffset;
    if (contextType is! InvalidType && expressionType is! InvalidType) {
      errorNode = helper.wrapInProblem(
          errorNode, message, errorNode.fileOffset, noLength,
          context: context);
    }
    return errorNode;
  }

  TypedTearoff _tearOffCall(
      Expression expression, DartType expressionType, int fileOffset) {
    ObjectAccessTarget target = findInterfaceMember(
        expressionType, callName, fileOffset,
        isSetter: false);

    Expression tearOff;
    DartType tearoffType = target.getGetterType(this);
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
        // TODO(johnniwinther): Avoid null-check for non-nullable expressions.

        // Replace expression with:
        // `let t = expression in t == null ? null : t.call`
        VariableDeclaration t =
            new VariableDeclaration.forValue(expression, type: expressionType)
              ..fileOffset = fileOffset;
        tearOff = new Let(
            t,
            new ConditionalExpression(
                new EqualsNull(new VariableGet(t)..fileOffset = fileOffset)
                  ..fileOffset = fileOffset,
                new NullLiteral()..fileOffset = fileOffset,
                new InstanceTearOff(
                    InstanceAccessKind.Instance, new VariableGet(t), callName,
                    interfaceTarget: target.member as Procedure,
                    resultType: tearoffType)
                  ..fileOffset = fileOffset,
                tearoffType))
          ..fileOffset = fileOffset;
      case ObjectAccessTargetKind.extensionTypeMember:
        tearOff = new StaticInvocation(
            target.tearoffTarget as Procedure,
            new Arguments([expression], types: target.receiverTypeArguments)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
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
      DartType contextType, DartType expressionType,
      {required bool isNonNullableByDefault,
      required bool isVoidAllowed,
      required bool isExpressionTypePrecise,
      required bool coerceExpression,
      required int fileOffset,
      required TreeNode? treeNodeForTesting}) {
    // If an interface type is being assigned to a function type, see if we
    // should tear off `.call`.
    // TODO(paulberry): use resolveTypeParameter.  See findInterfaceMember.
    bool needsTearoff = false;
    if (coerceExpression && _shouldTearOffCall(contextType, expressionType)) {
      ObjectAccessTarget target = findInterfaceMember(
          expressionType, callName, fileOffset,
          isSetter: false);
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
        case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
          shouldTearOff = false;
      }
      if (shouldTearOff) {
        needsTearoff = true;
        if (isNonNullableByDefault && target.isNullable) {
          return const AssignabilityResult(
              AssignabilityKind.unassignableCantTearoff,
              needsTearOff: false);
        }
        expressionType = target.getGetterType(this);
      }
    }
    ImplicitInstantiation? implicitInstantiation;
    if (coerceExpression && libraryFeatures.constructorTearoffs.isEnabled) {
      implicitInstantiation = computeImplicitInstantiation(
          expressionType, contextType,
          treeNodeForTesting: treeNodeForTesting);
      if (implicitInstantiation != null) {
        expressionType = implicitInstantiation.instantiatedType;
      }
    }

    if (expressionType is VoidType && !isVoidAllowed) {
      assert(implicitInstantiation == null);
      assert(!needsTearoff);
      return const AssignabilityResult(AssignabilityKind.unassignableVoid,
          needsTearOff: false);
    }

    IsSubtypeOf isDirectSubtypeResult = typeSchemaEnvironment
        .performNullabilityAwareSubtypeCheck(expressionType, contextType);
    bool isDirectlyAssignable = isNonNullableByDefault
        ? isDirectSubtypeResult.isSubtypeWhenUsingNullabilities()
        : isDirectSubtypeResult.isSubtypeWhenIgnoringNullabilities();
    if (isDirectlyAssignable) {
      return new AssignabilityResult(AssignabilityKind.assignable,
          needsTearOff: needsTearoff,
          implicitInstantiation: implicitInstantiation);
    }

    bool isIndirectlyAssignable = isNonNullableByDefault
        ? expressionType is DynamicType
        : typeSchemaEnvironment
            .performNullabilityAwareSubtypeCheck(contextType, expressionType)
            .isSubtypeWhenIgnoringNullabilities();
    if (!isIndirectlyAssignable) {
      if (isNonNullableByDefault &&
          isDirectSubtypeResult.isSubtypeWhenIgnoringNullabilities()) {
        return new AssignabilityResult.withTypes(
            AssignabilityKind.unassignableNullability,
            isDirectSubtypeResult.subtype,
            isDirectSubtypeResult.supertype,
            needsTearOff: needsTearoff,
            implicitInstantiation: implicitInstantiation);
      } else {
        return new AssignabilityResult(AssignabilityKind.unassignable,
            needsTearOff: needsTearoff,
            implicitInstantiation: implicitInstantiation);
      }
    }
    if (isExpressionTypePrecise) {
      // The type of the expression is known precisely, so an implicit
      // downcast is guaranteed to fail.  Insert a compile-time error.
      assert(implicitInstantiation == null);
      assert(!needsTearoff);
      return const AssignabilityResult(AssignabilityKind.unassignablePrecise,
          needsTearOff: false);
    }

    if (coerceExpression) {
      // Insert an implicit downcast.
      return new AssignabilityResult(AssignabilityKind.assignableCast,
          needsTearOff: needsTearoff,
          implicitInstantiation: implicitInstantiation);
    }

    return new AssignabilityResult(AssignabilityKind.unassignable,
        needsTearOff: needsTearoff,
        implicitInstantiation: implicitInstantiation);
  }

  /// Computes the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType]. If [explicitTypeArguments]
  /// are provided, these are returned, otherwise type arguments are inferred
  /// using [receiverType].
  List<DartType> computeExtensionTypeArgument(Extension extension,
      List<DartType>? explicitTypeArguments, DartType receiverType,
      {required TreeNode treeNodeForTesting}) {
    if (explicitTypeArguments != null) {
      assert(explicitTypeArguments.length == extension.typeParameters.length);
      return explicitTypeArguments;
    } else if (extension.typeParameters.isEmpty) {
      assert(explicitTypeArguments == null);
      return const <DartType>[];
    } else {
      return inferExtensionTypeArguments(extension, receiverType,
          treeNodeForTesting: treeNodeForTesting);
    }
  }

  /// Infers the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType].
  List<DartType> inferExtensionTypeArguments(
      Extension extension, DartType receiverType,
      {required TreeNode? treeNodeForTesting}) {
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(
            extension.typeParameters);
    List<StructuralParameter> typeParameters =
        freshTypeParameters.freshTypeParameters;
    DartType onType = freshTypeParameters.substitute(extension.onType);
    List<DartType> inferredTypes =
        new List<DartType>.filled(typeParameters.length, const UnknownType());
    TypeConstraintGatherer gatherer = typeSchemaEnvironment
        .setupGenericTypeInference(null, typeParameters, null,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault,
            typeOperations: cfeOperations,
            inferenceResultForTesting: dataForTesting?.typeInferenceResult,
            treeNodeForTesting: treeNodeForTesting);
    gatherer.constrainArguments([onType], [receiverType],
        treeNodeForTesting: treeNodeForTesting);
    inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
        gatherer, typeParameters, inferredTypes,
        isNonNullableByDefault: isNonNullableByDefault);
    return inferredTypes;
  }

  ObjectAccessTarget? _findExtensionTypeMember(DartType receiverType,
      ExtensionType extensionType, Name name, int fileOffset,
      {required bool isSetter, required bool hasNonObjectMemberAccess}) {
    ClassMember? classMember = _getExtensionTypeMember(
        extensionType.extensionTypeDeclaration, name, isSetter);
    if (classMember == null) {
      return null;
    }
    Member? member = classMember.getMember(engine.membersBuilder);
    if (member is Procedure &&
        member.stubKind == ProcedureStubKind.RepresentationField) {
      return new ObjectAccessTarget.extensionTypeRepresentation(
          receiverType, extensionType, member,
          hasNonObjectMemberAccess: hasNonObjectMemberAccess);
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
              extensionType, extensionTypeDeclaration)!,
          hasNonObjectMemberAccess: hasNonObjectMemberAccess);
    } else {
      return new ObjectAccessTarget.interfaceMember(receiverType, member,
          hasNonObjectMemberAccess: hasNonObjectMemberAccess);
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
      int fileOffset,
      {bool setter = false,
      ObjectAccessTarget? defaultTarget,
      bool isPotentiallyNullableAccess = false}) {
    if (descriptor.hasComplementaryTarget(this)) {
      // If we're looking for `foo` and `foo=` can be found or vice-versa then
      // extension methods should not be found.
      return defaultTarget;
    }

    Name otherName = descriptor.complementaryName;
    bool otherIsSetter = descriptor.complementaryIsSetter;
    ExtensionAccessCandidate? bestSoFar;
    List<ExtensionAccessCandidate> noneMoreSpecific = [];
    libraryBuilder.forEachExtensionInScope((ExtensionBuilder extensionBuilder) {
      MemberBuilder? thisBuilder = extensionBuilder
          .lookupLocalMemberByName(name, setter: setter) as MemberBuilder?;
      MemberBuilder? otherBuilder = extensionBuilder.lookupLocalMemberByName(
          otherName,
          setter: otherIsSetter) as MemberBuilder?;
      if ((thisBuilder != null && !thisBuilder.isStatic) ||
          (otherBuilder != null && !otherBuilder.isStatic)) {
        DartType onType;
        DartType onTypeInstantiateToBounds;
        List<DartType> inferredTypeArguments;
        if (extensionBuilder.extension.typeParameters.isEmpty) {
          onTypeInstantiateToBounds =
              onType = extensionBuilder.extension.onType;
          inferredTypeArguments = const <DartType>[];
        } else {
          List<TypeParameter> typeParameters =
              extensionBuilder.extension.typeParameters;
          inferredTypeArguments = inferExtensionTypeArguments(
              extensionBuilder.extension, receiverType,
              treeNodeForTesting: null);
          Substitution inferredSubstitution =
              Substitution.fromPairs(typeParameters, inferredTypeArguments);

          for (int index = 0; index < typeParameters.length; index++) {
            TypeParameter typeParameter = typeParameters[index];
            DartType typeArgument = inferredTypeArguments[index];
            DartType bound =
                inferredSubstitution.substituteType(typeParameter.bound);
            if (!typeSchemaEnvironment.isSubtypeOf(
                typeArgument, bound, SubtypeCheckMode.withNullabilities)) {
              return;
            }
          }
          onType = inferredSubstitution
              .substituteType(extensionBuilder.extension.onType);
          List<DartType> instantiateToBoundTypeArguments = calculateBounds(
              typeParameters, coreTypes.objectClass,
              isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
          Substitution instantiateToBoundsSubstitution = Substitution.fromPairs(
              typeParameters, instantiateToBoundTypeArguments);
          onTypeInstantiateToBounds = instantiateToBoundsSubstitution
              .substituteType(extensionBuilder.extension.onType);
        }

        if (typeSchemaEnvironment.isSubtypeOf(
            receiverType, onType, SubtypeCheckMode.withNullabilities)) {
          ObjectAccessTarget target = const ObjectAccessTarget.missing();
          if (thisBuilder != null && !thisBuilder.isStatic) {
            if (thisBuilder.isField) {
              if (thisBuilder.isExternal) {
                target = new ObjectAccessTarget.extensionMember(
                    receiverType,
                    setter ? thisBuilder.writeTarget! : thisBuilder.readTarget!,
                    thisBuilder.readTarget,
                    setter ? ClassMemberKind.Setter : ClassMemberKind.Getter,
                    inferredTypeArguments,
                    isPotentiallyNullable: isPotentiallyNullableAccess);
              }
            } else {
              ClassMemberKind classMemberKind;
              switch (thisBuilder.kind) {
                case ProcedureKind.Method:
                case ProcedureKind.Operator:
                  classMemberKind = ClassMemberKind.Method;
                case ProcedureKind.Getter:
                  classMemberKind = ClassMemberKind.Getter;
                case ProcedureKind.Setter:
                  classMemberKind = ClassMemberKind.Setter;
                case ProcedureKind.Factory:
                case null:
                  throw new UnsupportedError(
                      "Unexpected procedure kind ${thisBuilder.kind} on "
                      "builder $thisBuilder.");
              }
              target = new ObjectAccessTarget.extensionMember(
                  receiverType,
                  setter ? thisBuilder.writeTarget! : thisBuilder.invokeTarget!,
                  thisBuilder.readTarget,
                  classMemberKind,
                  inferredTypeArguments,
                  isPotentiallyNullable: isPotentiallyNullableAccess);
            }
          }
          ExtensionAccessCandidate candidate = new ExtensionAccessCandidate(
              (thisBuilder ?? otherBuilder)!,
              onType,
              onTypeInstantiateToBounds,
              target,
              isPlatform:
                  extensionBuilder.libraryBuilder.importUri.isScheme('dart'));
          if (noneMoreSpecific.isNotEmpty) {
            bool isMostSpecific = true;
            for (ExtensionAccessCandidate other in noneMoreSpecific) {
              bool? isMoreSpecific =
                  candidate.isMoreSpecificThan(typeSchemaEnvironment, other);
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
            bool? isMoreSpecific =
                candidate.isMoreSpecificThan(typeSchemaEnvironment, bestSoFar!);
            if (isMoreSpecific == true) {
              bestSoFar = candidate;
            } else if (isMoreSpecific == null) {
              noneMoreSpecific.add(bestSoFar!);
              noneMoreSpecific.add(candidate);
              bestSoFar = null;
            }
          }
        }
      }
    });
    if (bestSoFar != null) {
      return bestSoFar!.target;
    } else {
      if (noneMoreSpecific.isNotEmpty) {
        return new AmbiguousExtensionAccessTarget(
            receiverType, noneMoreSpecific);
      }
    }
    return defaultTarget;
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
      DartType receiverType, Name name, int fileOffset,
      {required bool isSetter,
      bool instrumented = true,
      bool includeExtensionMethods = false}) {
    assert(isKnown(receiverType));

    DartType receiverBound = receiverType.nonTypeVariableBound;

    bool hasNonObjectMemberAccess = !isNonNullableByDefault ||
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
            fileOffset: fileOffset);

    if (!hasNonObjectMemberAccess) {
      Member? member =
          _getInterfaceMember(coreTypes.objectClass, name, isSetter);
      if (member != null) {
        // Null implements all Object members so this is not considered a
        // potentially nullable access.
        return new ObjectAccessTarget.objectMember(receiverType, member);
      }
      if (includeExtensionMethods && receiverBound is! DynamicType) {
        ObjectAccessTarget? target = _findExtensionMember(
            isNonNullableByDefault ? receiverType : receiverBound,
            coreTypes.objectClass,
            name,
            objectAccessDescriptor,
            fileOffset,
            setter: isSetter);
        if (target != null) {
          return target;
        } else if (receiverBound is ExtensionType &&
            name.text ==
                receiverBound.extensionTypeDeclaration.representationName) {
          ObjectAccessTarget target =
              objectAccessDescriptor.findNonExtensionTarget(this);
          if (!target.isMissing) {
            return target;
          }
        }
      }
    }

    ObjectAccessTarget target =
        objectAccessDescriptor.findNonExtensionTarget(this);
    if (instrumentation != null &&
        instrumented &&
        receiverBound != const DynamicType() &&
        (target.isInstanceMember || target.isObjectMember)) {
      instrumentation?.record(uriForInstrumentation, fileOffset, 'target',
          new InstrumentationValueForMember(target.member!));
    }

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
            isNonNullableByDefault
                ? receiverType.toNonNull()
                : receiverBound.toNonNull(),
            classNode,
            name,
            objectAccessDescriptor,
            fileOffset,
            setter: isSetter,
            defaultTarget: target,
            isPotentiallyNullableAccess: true)!;
      } else {
        target = _findExtensionMember(
            isNonNullableByDefault ? receiverType : receiverBound,
            classNode,
            name,
            objectAccessDescriptor,
            fileOffset,
            setter: isSetter,
            defaultTarget: target)!;
      }
    }
    return target;
  }

  /// If target is missing on a non-dynamic receiver, an error is reported
  /// using [errorTemplate] and an invalid expression is returned.
  Expression? reportMissingInterfaceMember(
      ObjectAccessTarget target,
      DartType receiverType,
      Name name,
      int fileOffset,
      Template<Message Function(String, DartType, bool)> errorTemplate) {
    assert(isKnown(receiverType));
    if (target.isMissing) {
      int length = name.text.length;
      if (identical(name.text, callName.text) ||
          identical(name.text, unaryMinusName.text)) {
        length = 1;
      }
      return helper.buildProblem(
          errorTemplate.withArguments(name.text,
              receiverType.nonTypeVariableBound, isNonNullableByDefault),
          fileOffset,
          length);
    }
    return null;
  }

  /// Returns [type] as passed from [superClass] to the current class.
  ///
  /// If a legacy class occurs between the current class and [superClass] then
  /// [type] needs to be legacy erased. For instance
  ///
  ///    // Opt in:
  ///    class Super {
  ///      int extendedMethod(int i, {required int j}) => i;
  ///    }
  ///    class Mixin {
  ///      int mixedInMethod(int i, {required int j}) => i;
  ///    }
  ///    // Opt out:
  ///    class Legacy extends Super with Mixin {}
  ///    // Opt in:
  ///    class Class extends Legacy {
  ///      test() {
  ///        // Ok to call `Legacy.extendedMethod` since its type is
  ///        // `int* Function(int*, {int* j})`.
  ///        super.extendedMethod(null);
  ///        // Ok to call `Legacy.mixedInMethod` since its type is
  ///        // `int* Function(int*, {int* j})`.
  ///        super.mixedInMethod(null);
  ///      }
  ///    }
  ///
  DartType computeTypeFromSuperClass(Class superClass, DartType type) {
    if (needsLegacyErasure(thisType!.classNode, superClass)) {
      type = legacyErasure(type);
    }
    return type;
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
      Member interfaceMember, DartType receiverType,
      {required bool isSuper}) {
    assert(interfaceMember is Field || interfaceMember is Procedure,
        "Unexpected interface member $interfaceMember.");
    DartType calleeType =
        isSuper ? interfaceMember.superGetterType : interfaceMember.getterType;
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
      Member interfaceMember, DartType receiverType,
      {required bool isSuper}) {
    assert(interfaceMember is Field || interfaceMember is Procedure,
        "Unexpected interface member $interfaceMember.");
    DartType calleeType =
        isSuper ? interfaceMember.superSetterType : interfaceMember.setterType;
    return _getTypeForMemberTarget(interfaceMember, calleeType, receiverType);
  }

  DartType _getTypeForMemberTarget(
      Member interfaceMember, DartType calleeType, DartType receiverType) {
    TypeDeclaration enclosingTypeDeclaration =
        interfaceMember.enclosingTypeDeclaration!;
    if (enclosingTypeDeclaration.typeParameters.isNotEmpty) {
      receiverType = receiverType.nonTypeVariableBound;
      if (receiverType is TypeDeclarationType) {
        List<DartType> castedTypeArguments =
            hierarchyBuilder.getTypeArgumentsAsInstanceOf(
                receiverType, enclosingTypeDeclaration)!;
        calleeType = Substitution.fromPairs(
                enclosingTypeDeclaration.typeParameters, castedTypeArguments)
            .substituteType(calleeType);
      }
    }
    if (!isNonNullableByDefault) {
      calleeType = legacyErasure(calleeType);
    }
    return calleeType;
  }

  /// Returns the type of the receiver argument in an access to an extension
  /// member on [extension] with the given extension [typeArguments].
  DartType getExtensionReceiverType(
      Extension extension, List<DartType> typeArguments) {
    DartType receiverType = extension.onType;
    if (extension.typeParameters.isNotEmpty) {
      Substitution substitution =
          Substitution.fromPairs(extension.typeParameters, typeArguments);
      return substitution.substituteType(receiverType);
    }
    return receiverType;
  }

  DartType? getDerivedTypeArgumentOf(DartType type, Class class_) {
    if (type is TypeDeclarationType) {
      List<DartType>? typeArgumentsAsInstanceOfClass =
          hierarchyBuilder.getTypeArgumentsAsInstanceOf(type, class_);
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
  DartType inferDeclarationType(DartType initializerType,
      {bool forSyntheticVariable = false}) {
    if (forSyntheticVariable) {
      return normalizeNullabilityInLibrary(
          initializerType, libraryBuilder.library);
    } else if (initializerType is NullType) {
      // If the initializer type is Null or bottom, the inferred type is
      // dynamic.
      // TODO(paulberry): this rule is inherited from analyzer behavior but is
      // not spec'ed anywhere.
      return const DynamicType();
    } else {
      return demoteTypeInLibrary(initializerType,
          isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
    }
  }

  NullAwareGuard createNullAwareGuard(VariableDeclaration variable) {
    return new NullAwareGuard(variable, variable.fileOffset, this);
  }

  ExpressionInferenceResult wrapExpressionInferenceResultInProblem(
      ExpressionInferenceResult result,
      Message message,
      int fileOffset,
      int length,
      {List<LocatedMessage>? context}) {
    return createNullAwareExpressionInferenceResult(
        result.inferredType,
        helper.wrapInProblem(
            result.nullAwareAction, message, fileOffset, length,
            context: context),
        result.nullAwareGuards);
  }

  ExpressionInferenceResult createNullAwareExpressionInferenceResult(
      DartType inferredType,
      Expression expression,
      Link<NullAwareGuard>? nullAwareGuards) {
    if (nullAwareGuards != null && nullAwareGuards.isNotEmpty) {
      return new NullAwareExpressionInferenceResult(
          computeNullable(inferredType),
          inferredType,
          nullAwareGuards,
          expression);
    } else {
      return new ExpressionInferenceResult(inferredType, expression);
    }
  }

  InvocationInferenceResult inferInvocation(
      InferenceVisitor visitor,
      DartType typeContext,
      int offset,
      FunctionType calleeType,
      ArgumentsImpl arguments,
      {List<VariableDeclaration>? hoistedExpressions,
      bool isSpecialCasedBinaryOperator = false,
      bool isSpecialCasedTernaryOperator = false,
      DartType? receiverType,
      bool skipTypeArgumentInference = false,
      bool isConst = false,
      bool isImplicitExtensionMember = false,
      bool isImplicitCall = false,
      Member? staticTarget,
      bool isExtensionMemberInvocation = false}) {
    int extensionTypeParameterCount = getExtensionTypeParameterCount(arguments);
    if (extensionTypeParameterCount != 0) {
      return _inferGenericExtensionMethodInvocation(
          visitor,
          extensionTypeParameterCount,
          typeContext,
          offset,
          calleeType,
          arguments,
          hoistedExpressions,
          isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
          isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator,
          receiverType: receiverType,
          skipTypeArgumentInference: skipTypeArgumentInference,
          isConst: isConst,
          isImplicitExtensionMember: isImplicitExtensionMember);
    }
    return _inferInvocation(
        visitor, typeContext, offset, calleeType, arguments, hoistedExpressions,
        isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
        isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator,
        receiverType: receiverType,
        skipTypeArgumentInference: skipTypeArgumentInference,
        isConst: isConst,
        isImplicitExtensionMember: isImplicitExtensionMember,
        isImplicitCall: isImplicitCall,
        staticTarget: staticTarget,
        isExtensionMemberInvocation: isExtensionMemberInvocation);
  }

  InvocationInferenceResult _inferGenericExtensionMethodInvocation(
      InferenceVisitor visitor,
      int extensionTypeParameterCount,
      DartType typeContext,
      int offset,
      FunctionType calleeType,
      Arguments arguments,
      List<VariableDeclaration>? hoistedExpressions,
      {bool isSpecialCasedBinaryOperator = false,
      bool isSpecialCasedTernaryOperator = false,
      DartType? receiverType,
      bool skipTypeArgumentInference = false,
      bool isConst = false,
      bool isImplicitExtensionMember = false,
      bool isImplicitCall = false,
      Member? staticTarget}) {
    FunctionType extensionFunctionType = new FunctionType(
        [calleeType.positionalParameters.first],
        const DynamicType(),
        libraryBuilder.nonNullable,
        requiredParameterCount: 1,
        typeParameters: calleeType.typeParameters
            .take(extensionTypeParameterCount)
            .toList());
    ArgumentsImpl extensionArguments = new ArgumentsImpl(
        [arguments.positional.first],
        types: getExplicitExtensionTypeArguments(arguments))
      ..fileOffset = arguments.fileOffset;
    _inferInvocation(visitor, const UnknownType(), offset,
        extensionFunctionType, extensionArguments, hoistedExpressions,
        skipTypeArgumentInference: skipTypeArgumentInference,
        receiverType: receiverType,
        isImplicitExtensionMember: isImplicitExtensionMember,
        isImplicitCall: isImplicitCall,
        staticTarget: staticTarget,
        isExtensionMemberInvocation: true);
    FunctionTypeInstantiator extensionInstantiator =
        new FunctionTypeInstantiator.fromIterables(
            extensionFunctionType.typeParameters, extensionArguments.types);

    List<StructuralParameter> targetTypeParameters =
        const <StructuralParameter>[];
    if (calleeType.typeParameters.length > extensionTypeParameterCount) {
      targetTypeParameters =
          calleeType.typeParameters.skip(extensionTypeParameterCount).toList();
    }
    FunctionType targetFunctionType = new FunctionType(
        calleeType.positionalParameters.skip(1).toList(),
        calleeType.returnType,
        libraryBuilder.nonNullable,
        requiredParameterCount: calleeType.requiredParameterCount - 1,
        namedParameters: calleeType.namedParameters,
        typeParameters: targetTypeParameters);
    targetFunctionType =
        extensionInstantiator.substitute(targetFunctionType) as FunctionType;
    ArgumentsImpl targetArguments = new ArgumentsImpl(
        arguments.positional.skip(1).toList(),
        named: arguments.named,
        types: getExplicitTypeArguments(arguments))
      ..fileOffset = arguments.fileOffset;
    InvocationInferenceResult result = _inferInvocation(visitor, typeContext,
        offset, targetFunctionType, targetArguments, hoistedExpressions,
        isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
        isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator,
        skipTypeArgumentInference: skipTypeArgumentInference,
        isConst: isConst,
        isImplicitCall: isImplicitCall,
        staticTarget: staticTarget);
    arguments.positional.clear();
    arguments.positional.addAll(extensionArguments.positional);
    arguments.positional.addAll(targetArguments.positional);
    setParents(arguments.positional, arguments);
    // The `targetArguments.named` is the same list as `arguments.named` so
    // we just need to ensure that parent relations are realigned.
    setParents(arguments.named, arguments);
    arguments.types.clear();
    arguments.types.addAll(extensionArguments.types);
    arguments.types.addAll(targetArguments.types);
    return result;
  }

  /// Performs the type inference steps that are shared by all kinds of
  /// invocations (constructors, instance methods, and static methods).
  InvocationInferenceResult _inferInvocation(
      InferenceVisitor visitor,
      DartType typeContext,
      int offset,
      FunctionType calleeType,
      ArgumentsImpl arguments,
      List<VariableDeclaration>? hoistedExpressions,
      {bool isSpecialCasedBinaryOperator = false,
      bool isSpecialCasedTernaryOperator = false,
      DartType? receiverType,
      bool skipTypeArgumentInference = false,
      bool isConst = false,
      bool isImplicitExtensionMember = false,
      required bool isImplicitCall,
      Member? staticTarget,
      bool isExtensionMemberInvocation = false}) {
    // [receiverType] must be provided for special-cased operators.
    assert(!isSpecialCasedBinaryOperator && !isSpecialCasedTernaryOperator ||
        receiverType != null);

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
      FreshStructuralParameters fresh =
          getFreshStructuralParameters(calleeTypeParameters);
      calleeType = fresh.applyToFunctionType(calleeType);
      calleeTypeParameters = fresh.freshTypeParameters;
    }

    List<DartType>? explicitTypeArguments = getExplicitTypeArguments(arguments);

    bool inferenceNeeded = !skipTypeArgumentInference &&
        explicitTypeArguments == null &&
        calleeTypeParameters.isNotEmpty;

    List<DartType>? inferredTypes;
    FunctionTypeInstantiator? instantiator;
    List<DartType> formalTypes = [];
    List<DartType> actualTypes = [];

    List<VariableDeclaration>? localHoistedExpressions;
    if (libraryFeatures.namedArgumentsAnywhere.isEnabled &&
        arguments.argumentsOriginalOrder != null &&
        hoistedExpressions == null &&
        !isConst) {
      hoistedExpressions = localHoistedExpressions = <VariableDeclaration>[];
    }

    TypeConstraintGatherer? gatherer;
    if (inferenceNeeded) {
      if (isConst) {
        typeContext = new TypeVariableEliminator(
                bottomType,
                isNonNullableByDefault
                    ? coreTypes.objectNullableRawType
                    : coreTypes.objectLegacyRawType)
            .substituteType(typeContext);
      }
      gatherer = typeSchemaEnvironment.setupGenericTypeInference(
          isNonNullableByDefault
              ? calleeType.returnType
              : legacyErasure(calleeType.returnType),
          calleeTypeParameters,
          typeContext,
          isNonNullableByDefault: isNonNullableByDefault,
          typeOperations: cfeOperations,
          inferenceResultForTesting: dataForTesting?.typeInferenceResult,
          treeNodeForTesting: arguments);
      inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
          gatherer, calleeTypeParameters, null,
          isNonNullableByDefault: isNonNullableByDefault);
      instantiator = new FunctionTypeInstantiator.fromIterables(
          calleeTypeParameters, inferredTypes);
    } else if (explicitTypeArguments != null &&
        calleeTypeParameters.length == explicitTypeArguments.length) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
          calleeTypeParameters, explicitTypeArguments);
    } else if (calleeTypeParameters.length != 0) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
          calleeTypeParameters,
          new List<DartType>.filled(
              calleeTypeParameters.length, const DynamicType()));
    }
    bool isIdentical =
        staticTarget == typeSchemaEnvironment.coreTypes.identicalProcedure;
    // TODO(paulberry): if we are doing top level inference and type arguments
    // were omitted, report an error.
    List<Object?> argumentsEvaluationOrder;
    if (libraryFeatures.namedArgumentsAnywhere.isEnabled &&
        arguments.argumentsOriginalOrder != null) {
      argumentsEvaluationOrder = arguments.argumentsOriginalOrder!;
    } else {
      argumentsEvaluationOrder = <Object?>[
        ...arguments.positional,
        ...arguments.named
      ];
    }
    arguments.argumentsOriginalOrder = null;

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
    if (libraryFeatures.namedArgumentsAnywhere.isEnabled) {
      hoistingEndIndex = argumentsEvaluationOrder.length - 1;
      for (int i = argumentsEvaluationOrder.length - 2;
          i >= 0 && hoistingEndIndex == i + 1;
          i--) {
        int previousWeight =
            argumentsEvaluationOrder[i + 1] is NamedExpression ? 1 : 0;
        int currentWeight =
            argumentsEvaluationOrder[i] is NamedExpression ? 1 : 0;
        if (currentWeight <= previousWeight) {
          --hoistingEndIndex;
        }
      }
    } else {
      hoistingEndIndex = 0;
    }

    ExpressionInferenceResult inferArgument(
        DartType formalType, Expression argumentExpression,
        {required bool isNamed}) {
      DartType inferredFormalType = instantiator != null
          ? instantiator.substitute(formalType)
          : formalType;
      if (!isNamed) {
        if (isSpecialCasedBinaryOperator) {
          inferredFormalType =
              typeSchemaEnvironment.getContextTypeOfSpecialCasedBinaryOperator(
                  typeContext, receiverType!, inferredFormalType,
                  isNonNullableByDefault: isNonNullableByDefault);
        } else if (isSpecialCasedTernaryOperator) {
          inferredFormalType =
              typeSchemaEnvironment.getContextTypeOfSpecialCasedTernaryOperator(
                  typeContext, receiverType!, inferredFormalType,
                  isNonNullableByDefault: isNonNullableByDefault);
        }
      }
      return visitor.inferExpression(
          argumentExpression,
          isNonNullableByDefault
              ? inferredFormalType
              : legacyErasure(inferredFormalType));
    }

    List<ExpressionInfo<DartType>?>? identicalInfo =
        isIdentical && arguments.positional.length == 2 ? [] : null;
    int positionalIndex = 0;
    int namedIndex = 0;
    List<_DeferredParamInfo>? deferredFunctionLiterals;
    for (int evaluationOrderIndex = 0;
        evaluationOrderIndex < argumentsEvaluationOrder.length;
        evaluationOrderIndex++) {
      Object? argument = argumentsEvaluationOrder[evaluationOrderIndex];
      assert(
          argument is Expression || argument is NamedExpression,
          "Expected the argument to be either an Expression "
          "or a NamedExpression, got '${argument.runtimeType}'.");
      int index;
      DartType formalType;
      Expression argumentExpression;
      bool isExpression = argument is Expression;
      if (isExpression) {
        index = positionalIndex++;
        formalType = getPositionalParameterType(calleeType, index);
        argumentExpression = arguments.positional[index];
      } else {
        index = namedIndex++;
        NamedExpression namedArgument = arguments.named[index];
        formalType = getNamedParameterType(calleeType, namedArgument.name);
        argumentExpression = namedArgument.value;
      }
      if (isExpression && isImplicitExtensionMember && index == 0) {
        assert(
            receiverType != null,
            "No receiver type provided for implicit extension member "
            "invocation.");
        continue;
      }
      Expression unparenthesizedExpression = argumentExpression;
      while (unparenthesizedExpression is ParenthesizedExpression) {
        unparenthesizedExpression = unparenthesizedExpression.expression;
      }
      if (isInferenceUpdate1Enabled &&
          unparenthesizedExpression is FunctionExpression) {
        (deferredFunctionLiterals ??= []).add(new _DeferredParamInfo(
            formalType: formalType,
            argumentExpression: argumentExpression,
            unparenthesizedExpression: unparenthesizedExpression,
            isNamed: !isExpression,
            evaluationOrderIndex: isImplicitExtensionMember
                ? evaluationOrderIndex - 1
                : evaluationOrderIndex,
            index: index));
        // We don't have `identical` info yet, so fill it in with `null` for
        // now.  Later, when we visit the function literal, we'll replace it.
        identicalInfo?.add(null);
        formalTypes.add(formalType);
        // We don't have an inferred type yet, so fill it in with UnknownType
        // for now.  Later, when we infer a type, we'll replace it.
        actualTypes.add(const UnknownType());
      } else {
        ExpressionInferenceResult result = inferArgument(
            formalType, argumentExpression,
            isNamed: !isExpression);
        DartType inferredType = _computeInferredType(result);
        if (localHoistedExpressions != null &&
            evaluationOrderIndex >= hoistingEndIndex) {
          hoistedExpressions = null;
        }
        Expression expression =
            _hoist(result.expression, inferredType, hoistedExpressions);
        identicalInfo
            ?.add(flowAnalysis.equalityOperand_end(expression, inferredType));
        if (isExpression) {
          arguments.positional[index] = expression..parent = arguments;
        } else {
          NamedExpression namedArgument = arguments.named[index];
          namedArgument.value = expression..parent = namedArgument;
        }
        gatherer?.tryConstrainLower(formalType, inferredType,
            treeNodeForTesting: arguments);
        formalTypes.add(formalType);
        actualTypes.add(inferredType);
      }
    }
    if (deferredFunctionLiterals != null) {
      bool isFirstStage = true;
      for (List<_DeferredParamInfo> stage in new _FunctionLiteralDependencies(
              deferredFunctionLiterals,
              calleeType.typeParameters.toSet(),
              inferenceNeeded
                  ? _computeUndeferredParamInfo(
                      formalTypes, deferredFunctionLiterals)
                  : const [])
          .planReconciliationStages()) {
        if (gatherer != null && !isFirstStage) {
          inferredTypes = typeSchemaEnvironment.choosePreliminaryTypes(
              gatherer, calleeTypeParameters, inferredTypes,
              isNonNullableByDefault: isNonNullableByDefault);
          instantiator = new FunctionTypeInstantiator.fromIterables(
              calleeTypeParameters, inferredTypes);
        }
        for (_DeferredParamInfo deferredArgument in stage) {
          ExpressionInferenceResult result = inferArgument(
              deferredArgument.formalType, deferredArgument.argumentExpression,
              isNamed: deferredArgument.isNamed);
          DartType inferredType = _computeInferredType(result);
          Expression expression = result.expression;
          identicalInfo?[deferredArgument.evaluationOrderIndex] =
              flowAnalysis.equalityOperand_end(expression, inferredType);
          if (deferredArgument.isNamed) {
            NamedExpression namedArgument =
                arguments.named[deferredArgument.index];
            namedArgument.value = expression..parent = namedArgument;
          } else {
            arguments.positional[deferredArgument.index] = expression
              ..parent = arguments;
          }
          gatherer?.tryConstrainLower(deferredArgument.formalType, inferredType,
              treeNodeForTesting: arguments);
          actualTypes[deferredArgument.evaluationOrderIndex] = inferredType;
        }
        isFirstStage = false;
      }
    }
    if (identicalInfo != null) {
      flowAnalysis.equalityOperation_end(
          arguments.parent as Expression, identicalInfo[0], identicalInfo[1]);
    }
    assert(
        positionalIndex == arguments.positional.length,
        "Expected 'positionalIndex' to be ${arguments.positional.length}, "
        "got ${positionalIndex}.");
    assert(
        namedIndex == arguments.named.length,
        "Expected 'namedIndex' to be ${arguments.named.length}, "
        "got ${namedIndex}.");

    if (isSpecialCasedBinaryOperator || isSpecialCasedTernaryOperator) {
      if (!identical(calleeType, unknownFunction)) {
        LocatedMessage? argMessage = helper.checkArgumentsForType(
            calleeType, arguments, offset,
            isExtensionMemberInvocation: isExtensionMemberInvocation);
        if (argMessage != null) {
          return new WrapInProblemInferenceResult(
              const InvalidType(),
              const InvalidType(),
              argMessage.messageObject,
              argMessage.charOffset,
              argMessage.length,
              helper,
              isInapplicable: true,
              hoistedArguments: localHoistedExpressions);
        }
      }
      if (isSpecialCasedBinaryOperator) {
        calleeType = replaceReturnType(
            calleeType,
            typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
                receiverType!, actualTypes[0],
                isNonNullableByDefault: isNonNullableByDefault));
      } else if (isSpecialCasedTernaryOperator) {
        calleeType = replaceReturnType(
            calleeType,
            typeSchemaEnvironment.getTypeOfSpecialCasedTernaryOperator(
                receiverType!,
                actualTypes[0],
                actualTypes[1],
                libraryBuilder.library));
      }
    }

    // Check for and remove duplicated named arguments.
    List<NamedExpression> named = arguments.named;
    Map<String, NamedExpression> seenNames = <String, NamedExpression>{};
    bool hasProblem = false;
    int namedTypeIndex = arguments.positional.length;
    List<NamedExpression> uniqueNamed = <NamedExpression>[];
    for (NamedExpression expression in named) {
      String name = expression.name;
      if (seenNames.containsKey(name)) {
        hasProblem = true;
        NamedExpression prevNamedExpression = seenNames[name]!;
        prevNamedExpression.value = helper.wrapInProblem(
            _createDuplicateExpression(prevNamedExpression.fileOffset,
                prevNamedExpression.value, expression.value),
            templateDuplicatedNamedArgument.withArguments(name),
            expression.fileOffset,
            name.length)
          ..parent = prevNamedExpression;
        formalTypes.removeAt(namedTypeIndex);
        actualTypes.removeAt(namedTypeIndex);
      } else {
        seenNames[name] = expression;
        uniqueNamed.add(expression);
        namedTypeIndex++;
      }
    }
    if (hasProblem) {
      arguments.named = uniqueNamed;
    }

    if (inferenceNeeded) {
      inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
          gatherer!, calleeTypeParameters, inferredTypes!,
          isNonNullableByDefault: isNonNullableByDefault);
      assert(inferredTypes.every((type) => isKnown(type)),
          "Unknown type(s) in inferred types: $inferredTypes.");
      assert(inferredTypes.every((type) => !hasPromotedTypeVariable(type)),
          "Promoted type variable(s) in inferred types: $inferredTypes.");
      instantiator = new FunctionTypeInstantiator.fromIterables(
          calleeTypeParameters, inferredTypes);
      instrumentation?.record(uriForInstrumentation, offset, 'typeArgs',
          new InstrumentationValueForTypeArgs(inferredTypes));
      arguments.types.clear();
      arguments.types.addAll(inferredTypes);
      if (dataForTesting != null) {
        assert(arguments.fileOffset != TreeNode.noOffset);
        dataForTesting!.typeInferenceResult.inferredTypeArguments[arguments] =
            inferredTypes;
      }
    }
    if (!identical(calleeType, unknownFunction)) {
      LocatedMessage? argMessage = helper.checkArgumentsForType(
          calleeType, arguments, offset,
          isExtensionMemberInvocation: isExtensionMemberInvocation);
      if (argMessage != null) {
        return new WrapInProblemInferenceResult(
            const InvalidType(),
            const InvalidType(),
            argMessage.messageObject,
            argMessage.charOffset,
            argMessage.length,
            helper,
            isInapplicable: true,
            hoistedArguments: localHoistedExpressions);
      } else {
        // Argument counts and names match. Compare types.
        int positionalShift = isImplicitExtensionMember ? 1 : 0;
        int positionalIndex = 0;
        int namedIndex = 0;
        for (int i = 0; i < formalTypes.length; i++) {
          DartType formalType = formalTypes[i];
          DartType expectedType = instantiator != null
              ? instantiator.substitute(formalType)
              : formalType;
          DartType actualType = actualTypes[i];
          Expression expression;
          NamedExpression? namedExpression;
          bool coerceExpression;
          Object? argumentInEvaluationOrder =
              argumentsEvaluationOrder[i + positionalShift];
          if (argumentInEvaluationOrder is Expression) {
            expression =
                arguments.positional[positionalShift + positionalIndex];
            coerceExpression = !arguments.positionalAreSuperParameters;
          } else {
            namedExpression = arguments.named[namedIndex];
            expression = namedExpression.value;
            coerceExpression = !(arguments.namedSuperParameterNames
                    ?.contains(namedExpression.name) ??
                false);
          }
          expression = ensureAssignable(expectedType, actualType, expression,
              isVoidAllowed: expectedType is VoidType,
              coerceExpression: coerceExpression,
              // TODO(johnniwinther): Specialize message for operator
              // invocations.
              errorTemplate: templateArgumentTypeNotAssignable,
              nullabilityErrorTemplate:
                  templateArgumentTypeNotAssignableNullability,
              nullabilityPartErrorTemplate:
                  templateArgumentTypeNotAssignablePartNullability,
              nullabilityNullErrorTemplate:
                  templateArgumentTypeNotAssignableNullabilityNull,
              nullabilityNullTypeErrorTemplate:
                  templateArgumentTypeNotAssignableNullabilityNullType);
          if (namedExpression == null) {
            arguments.positional[positionalShift + positionalIndex] = expression
              ..parent = arguments;
            positionalIndex++;
          } else {
            namedExpression.value = expression..parent = namedExpression;
            namedIndex++;
          }
        }
      }
    }
    DartType inferredType;
    if (instantiator != null) {
      calleeType = instantiator.substitute(calleeType.withoutTypeParameters)
          as FunctionType;
    }
    inferredType = calleeType.returnType;
    assert(
        !containsFreeFunctionTypeVariables(inferredType),
        "Inferred return type $inferredType contains free variables. "
        "Inferred function type: $calleeType.");

    if (!isNonNullableByDefault) {
      inferredType = legacyErasure(inferredType);
      calleeType = legacyErasure(calleeType) as FunctionType;
    }

    return new SuccessfulInferenceResult(inferredType, calleeType,
        hoistedArguments: localHoistedExpressions,
        inferredReceiverType: receiverType);
  }

  FunctionType inferLocalFunction(
      InferenceVisitor visitor,
      FunctionNode function,
      DartType? typeContext,
      int fileOffset,
      DartType? returnContext) {
    bool hasImplicitReturnType = false;
    if (returnContext == null) {
      hasImplicitReturnType = true;
      returnContext =
          isNonNullableByDefault ? const UnknownType() : const DynamicType();
    }
    List<VariableDeclaration> positionalParameters =
        function.positionalParameters;
    for (int i = 0; i < positionalParameters.length; i++) {
      VariableDeclaration parameter = positionalParameters[i];
      flowAnalysis.declare(parameter, parameter.type, initialized: true);
      inferMetadata(visitor, parameter, parameter.annotations);
      if (parameter.initializer != null) {
        ExpressionInferenceResult initializerResult =
            visitor.inferExpression(parameter.initializer!, parameter.type);
        parameter.initializer = initializerResult.expression
          ..parent = parameter;
      }
    }
    for (VariableDeclaration parameter in function.namedParameters) {
      flowAnalysis.declare(parameter, parameter.type, initialized: true);
      inferMetadata(visitor, parameter, parameter.annotations);
      if (parameter.initializer != null) {
        ExpressionInferenceResult initializerResult =
            visitor.inferExpression(parameter.initializer!, parameter.type);
        parameter.initializer = initializerResult.expression
          ..parent = parameter;
      }
    }

    // Let `<T0, ..., Tn>` be the set of type parameters of the closure (with
    // `n`=0 if there are no type parameters).
    List<TypeParameter> functionTypeParameters = function.typeParameters;

    // Let `(P0 x0, ..., Pm xm)` be the set of formal parameters of the closure
    // (including required, positional optional, and named optional parameters).
    // If any type `Pi` is missing, denote it as `_`.
    List<VariableDeclaration> formals = function.positionalParameters.toList()
      ..addAll(function.namedParameters);

    // Let `B` denote the closure body.  If `B` is an expression function body
    // (`=> e`), treat it as equivalent to a block function body containing a
    // single `return` statement (`{ return e; }`).

    // Attempt to match `K` as a function type compatible with the closure (that
    // is, one having n type parameters and a compatible set of formal
    // parameters).  If there is a successful match, let `<S0, ..., Sn>` be the
    // set of matched type parameters and `(Q0, ..., Qm)` be the set of matched
    // formal parameter types, and let `N` be the return type.
    FunctionTypeInstantiator? instantiator;
    List<DartType?> formalTypesFromContext =
        new List<DartType?>.filled(formals.length, null);
    if (typeContext is FunctionType &&
        typeContext.typeParameters.length == functionTypeParameters.length) {
      for (int i = 0; i < formals.length; i++) {
        if (i < function.positionalParameters.length) {
          formalTypesFromContext[i] =
              getPositionalParameterType(typeContext, i);
        } else {
          formalTypesFromContext[i] =
              getNamedParameterType(typeContext, formals[i].name!);
        }
      }
      returnContext = typeContext.returnType;

      // Let `[T/S]` denote the type substitution where each `Si` is replaced
      // with the corresponding `Ti`.
      instantiator = new FunctionTypeInstantiator.fromIterables(
          typeContext.typeParameters,
          new List<DartType>.generate(
              typeContext.typeParameters.length,
              (int i) => new TypeParameterType
                  .forAlphaRenamingFromStructuralParameters(
                  typeContext.typeParameters[i], functionTypeParameters[i])));
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
      VariableDeclarationImpl formal = formals[i] as VariableDeclarationImpl;
      if (formal.isImplicitlyTyped) {
        DartType inferredType;
        if (formalTypesFromContext[i] != null) {
          inferredType = computeGreatestClosure2(
              instantiator?.substitute(formalTypesFromContext[i]!) ??
                  formalTypesFromContext[i]!);
          if (typeSchemaEnvironment.isSubtypeOf(
              inferredType,
              const NullType(),
              isNonNullableByDefault
                  ? SubtypeCheckMode.withNullabilities
                  : SubtypeCheckMode.ignoringNullabilities)) {
            inferredType = coreTypes.objectRawType(libraryBuilder.nullable);
          }
        } else {
          inferredType = const DynamicType();
        }
        instrumentation?.record(uriForInstrumentation, formal.fileOffset,
            'type', new InstrumentationValueForType(inferredType));
        formal.type = demoteTypeInLibrary(inferredType,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
        if (dataForTesting != null) {
          dataForTesting!.typeInferenceResult.inferredVariableTypes[formal] =
              formal.type;
        }
      }

      if (isNonNullableByDefault) {
        // If a parameter is a positional or named optional parameter and its
        // type is potentially non-nullable, it should have an initializer.
        bool isOptionalPositional = function.requiredParameterCount <= i &&
            i < function.positionalParameters.length;
        bool isOptionalNamed =
            i >= function.positionalParameters.length && !formal.isRequired;
        if ((isOptionalPositional || isOptionalNamed) &&
            formal.type.isPotentiallyNonNullable &&
            !formal.hasDeclaredInitializer) {
          libraryBuilder.addProblem(
              templateOptionalNonNullableWithoutInitializerError.withArguments(
                  formal.name!, formal.type, isNonNullableByDefault),
              formal.fileOffset,
              formal.name!.length,
              libraryBuilder.importUri);
        }
      }
    }

    if (isNonNullableByDefault) {
      for (VariableDeclaration parameter in function.namedParameters) {
        VariableDeclarationImpl formal = parameter as VariableDeclarationImpl;
        // Required named parameters shouldn't have initializers.
        if (formal.isRequired && formal.hasDeclaredInitializer) {
          libraryBuilder.addProblem(
              templateRequiredNamedParameterHasDefaultValueError
                  .withArguments(formal.name!),
              formal.fileOffset,
              formal.name!.length,
              libraryBuilder.importUri);
        }
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
        this, function.asyncMarker, returnContext, needToSetReturnType);
    StatementInferenceResult bodyResult =
        visitor.inferStatement(function.body!, closureContext);

    // If the closure is declared with `async*` or `sync*`, let `M` be the
    // least upper bound of the types of the `yield` expressions in `B’`, or
    // `void` if `B’` contains no `yield` expressions.  Otherwise, let `M` be
    // the least upper bound of the types of the `return` expressions in `B’`,
    // or `void` if `B’` contains no `return` expressions.
    if (needToSetReturnType) {
      DartType inferredReturnType = closureContext.inferReturnType(this,
          hasImplicitReturn: flowAnalysis.isReachable);

      // Then the result of inference is `<T0, ..., Tn>(R0 x0, ..., Rn xn) B`
      // with type `<T0, ..., Tn>(R0, ..., Rn) -> M’` (with some of the `Ri` and
      // `xi` denoted as optional or named parameters, if appropriate).
      instrumentation?.record(uriForInstrumentation, fileOffset, 'returnType',
          new InstrumentationValueForType(inferredReturnType));
      function.returnType = inferredReturnType;
    }
    bodyResult = closureContext.handleImplicitReturn(
        this, function.body!, bodyResult, fileOffset);
    function.emittedValueType = closureContext.emittedValueType;

    if (bodyResult.hasChanged) {
      function.body = bodyResult.statement..parent = function;
    }
    return function.computeFunctionType(libraryBuilder.nonNullable);
  }

  void inferMetadata(InferenceVisitor visitor, TreeNode? parent,
      List<Expression>? annotations) {
    if (annotations != null) {
      for (int index = 0; index < annotations.length; index++) {
        ExpressionInferenceResult result =
            visitor.inferExpression(annotations[index], const UnknownType());
        annotations[index] = result.expression..parent = parent;
      }
    }
  }

  StaticInvocation transformExtensionMethodInvocation(int fileOffset,
      ObjectAccessTarget target, Expression receiver, Arguments arguments) {
    assert(target.isExtensionMember ||
        target.isNullableExtensionMember ||
        target.isExtensionTypeMember ||
        target.isNullableExtensionTypeMember);
    Procedure procedure = target.member as Procedure;
    return createStaticInvocation(
        procedure,
        new ArgumentsImpl.forExtensionMethod(
            target.receiverTypeArguments.length,
            procedure.function.typeParameters.length -
                target.receiverTypeArguments.length,
            receiver,
            extensionTypeArguments: target.receiverTypeArguments,
            positionalArguments: arguments.positional,
            namedArguments: arguments.named,
            typeArguments: arguments.types)
          ..fileOffset = arguments.fileOffset,
        fileOffset: fileOffset);
  }

  ExpressionInferenceResult _inferDynamicInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    InvocationInferenceResult result = inferInvocation(
        visitor, typeContext, fileOffset, unknownFunction, arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: const DynamicType(),
        isImplicitCall: isImplicitCall);
    assert(name != equalsName);
    Expression expression = new DynamicInvocation(
        DynamicAccessKind.Dynamic, receiver, name, arguments)
      ..isImplicitCall = isImplicitCall
      ..fileOffset = fileOffset;
    return createNullAwareExpressionInferenceResult(
        result.inferredType, result.applyResult(expression), nullAwareGuards);
  }

  ExpressionInferenceResult _inferNeverInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      NeverType receiverType,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    InvocationInferenceResult result = inferInvocation(
        visitor, typeContext, fileOffset, unknownFunction, arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: receiverType,
        isImplicitCall: isImplicitCall);
    assert(name != equalsName);
    Expression expression = new DynamicInvocation(
        DynamicAccessKind.Never, receiver, name, arguments)
      ..fileOffset = fileOffset;
    return createNullAwareExpressionInferenceResult(
        const NeverType.nonNullable(),
        result.applyResult(expression),
        nullAwareGuards);
  }

  ExpressionInferenceResult _inferMissingInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isExpressionInvocation,
      required bool isImplicitCall,
      Name? implicitInvocationPropertyName}) {
    assert(target.isMissing || target.isAmbiguous);
    Expression error = createMissingMethodInvocation(
        fileOffset, receiverType, name,
        receiver: receiver,
        arguments: arguments,
        isExpressionInvocation: isExpressionInvocation,
        implicitInvocationPropertyName: implicitInvocationPropertyName,
        extensionAccessCandidates:
            target.isAmbiguous ? target.candidates : null);
    InvocationInferenceResult inferenceResult = inferInvocation(
        visitor, typeContext, fileOffset, unknownFunction, arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: receiverType,
        isImplicitCall: isExpressionInvocation || isImplicitCall);
    Expression replacementError = inferenceResult.applyResult(error);
    assert(name != equalsName);
    // TODO(johnniwinther): Use InvalidType instead.
    return createNullAwareExpressionInferenceResult(
        const DynamicType(), replacementError, nullAwareGuards);
  }

  ExpressionInferenceResult _inferExtensionInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    assert(target.isExtensionMember ||
        target.isNullableExtensionMember ||
        target.isExtensionTypeMember ||
        target.isNullableExtensionTypeMember);
    DartType calleeType = target.getGetterType(this);
    FunctionType functionType = target.getFunctionType(this);

    if (target.declarationMethodKind == ClassMemberKind.Getter) {
      StaticInvocation staticInvocation = transformExtensionMethodInvocation(
          fileOffset, target, receiver, new Arguments.empty());
      ExpressionInferenceResult result = inferMethodInvocation(
          visitor,
          fileOffset,
          nullAwareGuards,
          staticInvocation,
          calleeType,
          callName,
          arguments,
          typeContext,
          hoistedExpressions: hoistedExpressions,
          isExpressionInvocation: false,
          isImplicitCall: true,
          implicitInvocationPropertyName: name);

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
            (type) => !type.isPotentiallyNullable);
        result = wrapExpressionInferenceResultInProblem(
            result,
            templateNullableExpressionCallError.withArguments(
                receiverType, isNonNullableByDefault),
            fileOffset,
            noLength,
            context: context);
      }

      return result;
    } else {
      StaticInvocation staticInvocation = transformExtensionMethodInvocation(
          fileOffset, target, receiver, arguments);
      InvocationInferenceResult result = inferInvocation(visitor, typeContext,
          fileOffset, functionType, staticInvocation.arguments as ArgumentsImpl,
          hoistedExpressions: hoistedExpressions,
          receiverType: receiverType,
          isImplicitExtensionMember: true,
          isImplicitCall: isImplicitCall,
          isExtensionMemberInvocation: true);
      libraryBuilder.checkBoundsInStaticInvocation(staticInvocation,
          typeSchemaEnvironment, helper.uri, getTypeArgumentsInfo(arguments));

      Expression replacement = result.applyResult(staticInvocation);
      if (target.isNullable) {
        List<LocatedMessage>? context = getWhyNotPromotedContext(
            flowAnalysis.whyNotPromoted(receiver)(),
            staticInvocation,
            (type) => !type.isPotentiallyNullable);
        if (isImplicitCall) {
          // Handles cases like:
          //   int? i;
          //   i();
          // where there is an extension:
          //   extension on int {
          //     void call() {}
          //   }
          replacement = helper.wrapInProblem(
              replacement,
              templateNullableExpressionCallError.withArguments(
                  receiverType, isNonNullableByDefault),
              fileOffset,
              noLength,
              context: context);
        } else {
          // Handles cases like:
          //   int? i;
          //   i.methodOnNonNullInt();
          // where `methodOnNonNullInt` is declared in an extension:
          //   extension on int {
          //     void methodOnNonNullInt() {}
          //   }
          replacement = helper.wrapInProblem(
              replacement,
              templateNullableMethodCallError.withArguments(
                  name.text, receiverType, isNonNullableByDefault),
              fileOffset,
              name.text.length,
              context: context);
        }
      }
      return createNullAwareExpressionInferenceResult(
          result.inferredType, replacement, nullAwareGuards);
    }
  }

  ExpressionInferenceResult _inferFunctionInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    assert(target.isCallFunction || target.isNullableCallFunction);
    FunctionType declaredFunctionType = target.getFunctionType(this);
    InvocationInferenceResult result = inferInvocation(
        visitor, typeContext, fileOffset, declaredFunctionType, arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: receiverType,
        isImplicitCall: isImplicitCall);
    Expression? expression;
    String? localName;

    DartType inferredFunctionType = result.functionType;
    if (result.isInapplicable) {
      // This was a function invocation whose arguments didn't match
      // the parameters.
      expression = new FunctionInvocation(
          FunctionAccessKind.Inapplicable, receiver, arguments,
          functionType: null)
        ..fileOffset = fileOffset;
    } else if (receiver is VariableGet) {
      VariableDeclaration variable = receiver.variable;
      TreeNode? parent = variable.parent;
      if (parent is FunctionDeclaration) {
        assert(!identical(inferredFunctionType, unknownFunction),
            "Unknown function type for local function invocation.");
        localName = variable.name!;
        expression = new LocalFunctionInvocation(variable, arguments,
            functionType: inferredFunctionType as FunctionType)
          ..fileOffset = receiver.fileOffset;
      }
    }
    expression ??= new FunctionInvocation(
        target.isNullableCallFunction
            ? FunctionAccessKind.Nullable
            : (identical(inferredFunctionType, unknownFunction)
                ? FunctionAccessKind.Function
                : FunctionAccessKind.FunctionType),
        receiver,
        arguments,
        functionType: identical(inferredFunctionType, unknownFunction)
            ? null
            : inferredFunctionType as FunctionType)
      ..fileOffset = fileOffset;

    _checkBoundsInFunctionInvocation(
        declaredFunctionType, localName, arguments, fileOffset);

    Expression replacement = result.applyResult(expression);
    if (target.isNullableCallFunction) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
          flowAnalysis.whyNotPromoted(receiver)(),
          expression,
          (type) => !type.isPotentiallyNullable);
      if (isImplicitCall) {
        // Handles cases like:
        //   void Function()? f;
        //   f();
        replacement = helper.wrapInProblem(
            replacement,
            templateNullableExpressionCallError.withArguments(
                receiverType, isNonNullableByDefault),
            fileOffset,
            noLength,
            context: context);
      } else {
        // Handles cases like:
        //   void Function()? f;
        //   f.call();
        replacement = helper.wrapInProblem(
            replacement,
            templateNullableMethodCallError.withArguments(
                callName.text, receiverType, isNonNullableByDefault),
            fileOffset,
            callName.text.length,
            context: context);
      }
    }
    // TODO(johnniwinther): Check that type arguments against the bounds.
    return createNullAwareExpressionInferenceResult(
        result.inferredType, replacement, nullAwareGuards);
  }

  FunctionType _computeFunctionTypeForArguments(
      Arguments arguments, DartType type) {
    return new FunctionType(
        new List<DartType>.filled(arguments.positional.length, type),
        type,
        libraryBuilder.nonNullable,
        namedParameters: new List<NamedType>.generate(arguments.named.length,
            (int index) => new NamedType(arguments.named[index].name, type)));
  }

  ExpressionInferenceResult _inferInstanceMethodInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      Arguments arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall,
      required bool isSpecialCasedBinaryOperator,
      required bool isSpecialCasedTernaryOperator}) {
    assert(target.isInstanceMember ||
        target.isObjectMember ||
        target.isNullableInstanceMember);
    Procedure? method = target.classMember as Procedure;
    assert(
        method.kind == ProcedureKind.Method ||
            method.kind == ProcedureKind.Operator,
        "Unexpected instance method $method");
    Name methodName = method.name;

    if (receiverType == const DynamicType()) {
      FunctionNode signature = method.function;
      if (arguments.positional.length < signature.requiredParameterCount ||
          arguments.positional.length > signature.positionalParameters.length) {
        target = const ObjectAccessTarget.dynamic();
        method = null;
      }
      for (NamedExpression argument in arguments.named) {
        if (!signature.namedParameters
            .any((declaration) => declaration.name == argument.name)) {
          target = const ObjectAccessTarget.dynamic();
          method = null;
        }
      }
      if (instrumentation != null && method != null) {
        instrumentation!.record(uriForInstrumentation, fileOffset, 'target',
            new InstrumentationValueForMember(method));
      }
    }

    DartType calleeType = target.getGetterType(this);
    FunctionType declaredFunctionType = target.getFunctionType(this);

    bool contravariantCheck = false;
    if (receiver is! ThisExpression &&
        method != null &&
        returnedTypeParametersOccurNonCovariantly(
            method.enclosingTypeDeclaration!, method.function.returnType)) {
      contravariantCheck = true;
    }
    InvocationInferenceResult result = inferInvocation(visitor, typeContext,
        fileOffset, declaredFunctionType, arguments as ArgumentsImpl,
        hoistedExpressions: hoistedExpressions,
        receiverType: receiverType,
        isImplicitCall: isImplicitCall,
        isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
        isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator);

    Expression expression;
    DartType inferredFunctionType = result.functionType;
    if (target.isDynamic) {
      // This was an Object member invocation whose arguments didn't match
      // the parameters.
      expression = new DynamicInvocation(
          DynamicAccessKind.Dynamic, receiver, methodName, arguments)
        ..isImplicitCall = isImplicitCall
        ..fileOffset = fileOffset;
    } else if (result.isInapplicable) {
      // This was a method invocation whose arguments didn't match
      // the parameters.
      expression = new InstanceInvocation(
          InstanceAccessKind.Inapplicable, receiver, methodName, arguments,
          functionType:
              _computeFunctionTypeForArguments(arguments, const InvalidType()),
          interfaceTarget: method!)
        ..fileOffset = fileOffset;
    } else {
      assert(
          inferredFunctionType is FunctionType &&
              !identical(unknownFunction, inferredFunctionType),
          "No function type found for $receiver.$methodName ($target) on "
          "$receiverType");
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
        default:
          throw new UnsupportedError('Unexpected target kind $target');
      }
      expression = new InstanceInvocation(kind, receiver, methodName, arguments,
          functionType: inferredFunctionType as FunctionType,
          interfaceTarget: method!)
        ..fileOffset = fileOffset;
    }
    Expression replacement;
    if (contravariantCheck) {
      // TODO(johnniwinther): Merge with the replacement computation below.
      replacement = new AsExpression(expression, result.inferredType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..isForNonNullableByDefault = isNonNullableByDefault
        ..fileOffset = fileOffset;
      if (instrumentation != null) {
        int offset =
            arguments.fileOffset == -1 ? fileOffset : arguments.fileOffset;
        instrumentation!.record(uriForInstrumentation, offset, 'checkReturn',
            new InstrumentationValueForType(result.inferredType));
      }
    } else {
      replacement = expression;
    }

    _checkBoundsInMethodInvocation(
        target, receiverType, calleeType, methodName, arguments, fileOffset);

    replacement = result.applyResult(replacement);
    if (target.isNullable) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
          flowAnalysis.whyNotPromoted(receiver)(),
          expression,
          (type) => !type.isPotentiallyNullable);
      if (isImplicitCall) {
        // Handles cases like:
        //   C? c;
        //   c();
        // Where C is defined as:
        //   class C {
        //     void call();
        //   }
        replacement = helper.wrapInProblem(
            replacement,
            templateNullableExpressionCallError.withArguments(
                receiverType, isNonNullableByDefault),
            fileOffset,
            noLength,
            context: context);
      } else {
        // Handles cases like:
        //   int? i;
        //   i.abs();
        replacement = helper.wrapInProblem(
            replacement,
            templateNullableMethodCallError.withArguments(
                methodName.text, receiverType, isNonNullableByDefault),
            fileOffset,
            methodName.text.length,
            context: context);
      }
    }

    return createNullAwareExpressionInferenceResult(
        result.inferredType, replacement, nullAwareGuards);
  }

  ExpressionInferenceResult _inferInstanceGetterInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isExpressionInvocation}) {
    assert(target.isInstanceMember ||
        target.isObjectMember ||
        target.isNullableInstanceMember);
    Procedure? getter = target.classMember as Procedure;
    assert(getter.kind == ProcedureKind.Getter);

    // TODO(johnniwinther): This is inconsistent with the handling below. Remove
    // this or add handling similar to [_inferMethodInvocation].
    if (receiverType == const DynamicType()) {
      FunctionNode signature = getter.function;
      if (arguments.positional.length < signature.requiredParameterCount ||
          arguments.positional.length > signature.positionalParameters.length) {
        target = const ObjectAccessTarget.dynamic();
        getter = null;
      }
      for (NamedExpression argument in arguments.named) {
        if (!signature.namedParameters
            .any((declaration) => declaration.name == argument.name)) {
          target = const ObjectAccessTarget.dynamic();
          getter = null;
        }
      }
      if (instrumentation != null && getter != null) {
        instrumentation!.record(uriForInstrumentation, fileOffset, 'target',
            new InstrumentationValueForMember(getter));
      }
    }

    DartType calleeType = target.getGetterType(this);

    List<VariableDeclaration>? locallyHoistedExpressions;
    if (hoistedExpressions == null) {
      hoistedExpressions = locallyHoistedExpressions = <VariableDeclaration>[];
    }
    if (arguments.positional.isNotEmpty || arguments.named.isNotEmpty) {
      receiver = _hoist(receiver, receiverType, hoistedExpressions);
    }

    Name originalName = getter!.name;
    Expression originalReceiver = receiver;
    Member originalTarget = getter;
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
      default:
        throw new UnsupportedError('Unexpected target kind $target');
    }
    InstanceGet originalPropertyGet = new InstanceGet(
        kind, originalReceiver, originalName,
        resultType: calleeType, interfaceTarget: originalTarget)
      ..fileOffset = fileOffset;
    Expression propertyGet = originalPropertyGet;
    if (calleeType is! DynamicType &&
        receiver is! ThisExpression &&
        returnedTypeParametersOccurNonCovariantly(
            getter.enclosingTypeDeclaration!, getter.function.returnType)) {
      propertyGet = new AsExpression(propertyGet, calleeType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..isForNonNullableByDefault = isNonNullableByDefault
        ..fileOffset = fileOffset;
      if (instrumentation != null) {
        int offset =
            arguments.fileOffset == -1 ? fileOffset : arguments.fileOffset;
        instrumentation!.record(uriForInstrumentation, offset,
            'checkGetterReturn', new InstrumentationValueForType(calleeType));
      }
    }

    if (isExpressionInvocation) {
      Expression error = helper.buildProblem(
          templateImplicitCallOfNonMethod.withArguments(
              receiverType, isNonNullableByDefault),
          fileOffset,
          noLength);
      return new ExpressionInferenceResult(const InvalidType(), error);
    }

    ExpressionInferenceResult invocationResult = inferMethodInvocation(
        visitor,
        arguments.fileOffset,
        const Link<NullAwareGuard>(),
        propertyGet,
        calleeType,
        callName,
        arguments,
        typeContext,
        hoistedExpressions: hoistedExpressions,
        isExpressionInvocation: false,
        isImplicitCall: true,
        implicitInvocationPropertyName: getter.name);

    if (target.isNullable) {
      // Handles cases like:
      //   C? c;
      //   c.foo();
      // Where C is defined as:
      //   class C {
      //     void Function() get foo => () {};
      //   }
      List<LocatedMessage>? context = getWhyNotPromotedContext(
          flowAnalysis.whyNotPromoted(receiver)(),
          invocationResult.expression,
          (type) => !type.isPotentiallyNullable);
      invocationResult = wrapExpressionInferenceResultInProblem(
          invocationResult,
          templateNullableExpressionCallError.withArguments(
              receiverType, isNonNullableByDefault),
          fileOffset,
          noLength,
          context: context);
    }

    if (!libraryBuilder
        .loader.target.backendTarget.supportsExplicitGetterCalls) {
      // TODO(johnniwinther): Remove this when dart2js/ddc supports explicit
      //  getter calls.
      Expression nullAwareAction = invocationResult.nullAwareAction;
      if (nullAwareAction is InstanceInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
            invocationResult.inferredType,
            new InstanceGetterInvocation(originalPropertyGet.kind,
                originalReceiver, originalName, nullAwareAction.arguments,
                interfaceTarget: originalTarget,
                functionType: nullAwareAction.functionType)
              ..fileOffset = nullAwareAction.fileOffset);
      } else if (nullAwareAction is DynamicInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
            invocationResult.inferredType,
            new InstanceGetterInvocation(originalPropertyGet.kind,
                originalReceiver, originalName, nullAwareAction.arguments,
                interfaceTarget: originalTarget, functionType: null)
              ..fileOffset = nullAwareAction.fileOffset);
      } else if (nullAwareAction is FunctionInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
            invocationResult.inferredType,
            new InstanceGetterInvocation(originalPropertyGet.kind,
                originalReceiver, originalName, nullAwareAction.arguments,
                interfaceTarget: originalTarget,
                functionType: nullAwareAction.functionType)
              ..fileOffset = nullAwareAction.fileOffset);
      }
    }
    invocationResult =
        _insertHoistedExpression(invocationResult, locallyHoistedExpressions);
    return createNullAwareExpressionInferenceResult(
        invocationResult.inferredType,
        invocationResult.expression,
        nullAwareGuards);
  }

  Expression _hoist(Expression expression, DartType type,
      List<VariableDeclaration>? hoistedExpressions) {
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
      List<VariableDeclaration>? hoistedExpressions) {
    if (hoistedExpressions != null && hoistedExpressions.isNotEmpty) {
      Expression expression = result.nullAwareAction;
      for (int index = hoistedExpressions.length - 1; index >= 0; index--) {
        expression = createLet(hoistedExpressions[index], expression);
      }
      return createNullAwareExpressionInferenceResult(
          result.inferredType, expression, result.nullAwareGuards);
    }
    return result;
  }

  ExpressionInferenceResult _inferInstanceFieldInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isExpressionInvocation}) {
    assert(target.isInstanceMember ||
        target.isObjectMember ||
        target.isNullableInstanceMember);
    Field field = target.classMember as Field;
    Expression originalReceiver = receiver;

    DartType calleeType = target.getGetterType(this);

    List<VariableDeclaration>? locallyHoistedExpressions;
    if (hoistedExpressions == null) {
      hoistedExpressions = locallyHoistedExpressions = <VariableDeclaration>[];
    }
    if (arguments.positional.isNotEmpty || arguments.named.isNotEmpty) {
      receiver = _hoist(receiver, receiverType, hoistedExpressions);
    }

    Map<DartType, NonPromotionReason> Function()? whyNotPromoted;
    if (target.isNullable) {
      // We won't report the error until later (after we have an
      // invocationResult), but we need to gather "why not promoted" info now,
      // before we tell flow analysis about the property get.
      whyNotPromoted = flowAnalysis.whyNotPromoted(originalReceiver);
    }

    Name originalName = field.name;
    Member originalTarget = field;
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
      default:
        throw new UnsupportedError('Unexpected target kind $target');
    }
    InstanceGet originalPropertyGet = new InstanceGet(
        kind, receiver, originalName,
        resultType: calleeType, interfaceTarget: originalTarget)
      ..fileOffset = fileOffset;
    DartType? promotedCalleeType = flowAnalysis.propertyGet(
        originalPropertyGet,
        computePropertyTarget(originalReceiver),
        originalName.text,
        originalTarget,
        calleeType);
    originalPropertyGet.resultType = calleeType;
    Expression propertyGet = originalPropertyGet;
    if (receiver is! ThisExpression &&
        calleeType is! DynamicType &&
        returnedTypeParametersOccurNonCovariantly(
            field.enclosingTypeDeclaration!, field.type)) {
      propertyGet = new AsExpression(propertyGet, calleeType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..isForNonNullableByDefault = isNonNullableByDefault
        ..fileOffset = fileOffset;
      if (instrumentation != null) {
        int offset =
            arguments.fileOffset == -1 ? fileOffset : arguments.fileOffset;
        instrumentation!.record(uriForInstrumentation, offset,
            'checkGetterReturn', new InstrumentationValueForType(calleeType));
      }
    }

    if (promotedCalleeType != null) {
      propertyGet = new AsExpression(propertyGet, promotedCalleeType)
        ..isUnchecked = true
        ..fileOffset = fileOffset;
      calleeType = promotedCalleeType;
    }

    if (isExpressionInvocation) {
      Expression error = helper.buildProblem(
          templateImplicitCallOfNonMethod.withArguments(
              receiverType, isNonNullableByDefault),
          fileOffset,
          noLength);
      return new ExpressionInferenceResult(const InvalidType(), error);
    }

    ExpressionInferenceResult invocationResult = inferMethodInvocation(
        visitor,
        arguments.fileOffset,
        const Link<NullAwareGuard>(),
        propertyGet,
        calleeType,
        callName,
        arguments,
        typeContext,
        isExpressionInvocation: false,
        isImplicitCall: true,
        hoistedExpressions: hoistedExpressions,
        implicitInvocationPropertyName: field.name);

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
          (type) => !type.isPotentiallyNullable);
      invocationResult = wrapExpressionInferenceResultInProblem(
          invocationResult,
          templateNullableExpressionCallError.withArguments(
              receiverType, isNonNullableByDefault),
          fileOffset,
          noLength,
          context: context);
    }

    if (!libraryBuilder
        .loader.target.backendTarget.supportsExplicitGetterCalls) {
      // TODO(johnniwinther): Remove this when dart2js/ddc supports explicit
      //  getter calls.
      Expression nullAwareAction = invocationResult.nullAwareAction;
      if (nullAwareAction is InstanceInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
            invocationResult.inferredType,
            new InstanceGetterInvocation(originalPropertyGet.kind, receiver,
                originalName, nullAwareAction.arguments,
                interfaceTarget: originalTarget,
                functionType: nullAwareAction.functionType)
              ..fileOffset = nullAwareAction.fileOffset);
      } else if (nullAwareAction is DynamicInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
            invocationResult.inferredType,
            new InstanceGetterInvocation(originalPropertyGet.kind, receiver,
                originalName, nullAwareAction.arguments,
                interfaceTarget: originalTarget, functionType: null)
              ..fileOffset = nullAwareAction.fileOffset);
      } else if (nullAwareAction is FunctionInvocation &&
          nullAwareAction.receiver == originalPropertyGet) {
        invocationResult = new ExpressionInferenceResult(
            invocationResult.inferredType,
            new InstanceGetterInvocation(originalPropertyGet.kind, receiver,
                originalName, nullAwareAction.arguments,
                interfaceTarget: originalTarget,
                functionType: nullAwareAction.functionType)
              ..fileOffset = nullAwareAction.fileOffset);
      }
    }
    invocationResult =
        _insertHoistedExpression(invocationResult, locallyHoistedExpressions);
    return createNullAwareExpressionInferenceResult(
        invocationResult.inferredType,
        invocationResult.expression,
        nullAwareGuards);
  }

  /// Computes an appropriate [PropertyTarget] for use in flow analysis to
  /// represent the given [target].
  PropertyTarget<Expression> computePropertyTarget(Expression target);

  /// Performs the core type inference algorithm for method invocations.
  ExpressionInferenceResult inferMethodInvocation(
      InferenceVisitor visitor,
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      {required bool isExpressionInvocation,
      required bool isImplicitCall,
      Name? implicitInvocationPropertyName,
      List<VariableDeclaration>? hoistedExpressions,
      ObjectAccessTarget? target}) {
    target ??= findInterfaceMember(receiverType, name, fileOffset,
        instrumented: true, includeExtensionMethods: true, isSetter: false);

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
                nullAwareGuards,
                receiver,
                receiverType,
                target,
                arguments,
                typeContext,
                hoistedExpressions,
                isExpressionInvocation: isExpressionInvocation);
          } else {
            bool isSpecialCasedBinaryOperator =
                target.isSpecialCasedBinaryOperator(this);
            return _inferInstanceMethodInvocation(
                visitor,
                fileOffset,
                nullAwareGuards,
                receiver,
                receiverType,
                target,
                arguments,
                typeContext,
                hoistedExpressions,
                isImplicitCall: isImplicitCall,
                isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
                isSpecialCasedTernaryOperator:
                    target.isSpecialCasedTernaryOperator(this));
          }
        } else {
          return _inferInstanceFieldInvocation(
              visitor,
              fileOffset,
              nullAwareGuards,
              receiver,
              receiverType,
              target,
              arguments,
              typeContext,
              hoistedExpressions,
              isExpressionInvocation: isExpressionInvocation);
        }
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        return _inferFunctionInvocation(
            visitor,
            fileOffset,
            nullAwareGuards,
            receiver,
            receiverType,
            target,
            arguments,
            typeContext,
            hoistedExpressions,
            isImplicitCall: isImplicitCall);
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        return _inferExtensionInvocation(
            visitor,
            fileOffset,
            nullAwareGuards,
            receiver,
            receiverType,
            target,
            name,
            arguments,
            typeContext,
            hoistedExpressions,
            isImplicitCall: isImplicitCall);
      case ObjectAccessTargetKind.ambiguous:
      case ObjectAccessTargetKind.missing:
        return _inferMissingInvocation(
            visitor,
            fileOffset,
            nullAwareGuards,
            receiver,
            receiverType,
            target,
            name,
            arguments,
            typeContext,
            hoistedExpressions,
            isExpressionInvocation: isExpressionInvocation,
            isImplicitCall: isImplicitCall,
            implicitInvocationPropertyName: implicitInvocationPropertyName);
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
        return _inferDynamicInvocation(visitor, fileOffset, nullAwareGuards,
            receiver, name, arguments, typeContext, hoistedExpressions,
            isImplicitCall: isExpressionInvocation || isImplicitCall);
      case ObjectAccessTargetKind.never:
        return _inferNeverInvocation(
            visitor,
            fileOffset,
            nullAwareGuards,
            receiver,
            receiverType as NeverType,
            name,
            arguments,
            typeContext,
            hoistedExpressions,
            isImplicitCall: isImplicitCall);
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
        DartType type = target.getGetterType(this);
        Expression read = new RecordIndexGet(receiver,
            target.receiverType as RecordType, target.recordFieldIndex!)
          ..fileOffset = fileOffset;
        ExpressionInferenceResult readResult =
            new ExpressionInferenceResult(type, read);
        if (target.isNullable) {
          // Handles cases like:
          //   (void Function())? r;
          //   r.$1();
          List<LocatedMessage>? context = getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(receiver)(),
              receiver,
              (type) => !type.isPotentiallyNullable);
          readResult = wrapExpressionInferenceResultInProblem(
              readResult,
              templateNullableExpressionCallError.withArguments(
                  receiverType, isNonNullableByDefault),
              fileOffset,
              noLength,
              context: context);
        }
        return inferMethodInvocation(
            visitor,
            arguments.fileOffset,
            nullAwareGuards,
            readResult.expression,
            readResult.inferredType,
            callName,
            arguments,
            typeContext,
            isExpressionInvocation: false,
            isImplicitCall: true,
            hoistedExpressions: hoistedExpressions);
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordNamed:
        if (isImplicitCall && !target.isNullable) {
          libraryBuilder.addProblem(messageRecordUsedAsCallable,
              receiver.fileOffset, noLength, libraryBuilder.fileUri);
        }
        DartType type = target.getGetterType(this);
        Expression read = new RecordNameGet(receiver,
            target.receiverType as RecordType, target.recordFieldName!)
          ..fileOffset = fileOffset;
        ExpressionInferenceResult readResult =
            new ExpressionInferenceResult(type, read);
        if (target.isNullable) {
          // Handles cases like:
          //   ({void Function() foo})? r;
          //   r.foo();
          List<LocatedMessage>? context = getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(receiver)(),
              receiver,
              (type) => !type.isPotentiallyNullable);
          readResult = wrapExpressionInferenceResultInProblem(
              readResult,
              templateNullableExpressionCallError.withArguments(
                  receiverType, isNonNullableByDefault),
              fileOffset,
              noLength,
              context: context);
        }
        return inferMethodInvocation(
            visitor,
            arguments.fileOffset,
            nullAwareGuards,
            readResult.expression,
            readResult.inferredType,
            callName,
            arguments,
            typeContext,
            isExpressionInvocation: false,
            isImplicitCall: true,
            hoistedExpressions: hoistedExpressions);
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        DartType type = target.getGetterType(this);
        type = flowAnalysis.propertyGet(
                null,
                computePropertyTarget(receiver),
                name.text,
                (target as ExtensionTypeRepresentationAccessTarget)
                    .representationField,
                type) ??
            type;
        Expression read = new AsExpression(receiver, type)
          ..isForNonNullableByDefault = true
          ..isUnchecked = true
          ..fileOffset = fileOffset;
        ExpressionInferenceResult readResult =
            new ExpressionInferenceResult(type, read);
        if (target.isNullable) {
          // Handles cases like:
          //
          //   extension type Foo(void Function() bar) {}
          //   method(Foo? r) => r.bar();
          //
          List<LocatedMessage>? context = getWhyNotPromotedContext(
              flowAnalysis.whyNotPromoted(receiver)(),
              receiver,
              (type) => !type.isPotentiallyNullable);
          readResult = wrapExpressionInferenceResultInProblem(
              readResult,
              templateNullableExpressionCallError.withArguments(
                  receiverType, isNonNullableByDefault),
              fileOffset,
              noLength,
              context: context);
        }
        return inferMethodInvocation(
            visitor,
            arguments.fileOffset,
            nullAwareGuards,
            readResult.expression,
            readResult.inferredType,
            callName,
            arguments,
            typeContext,
            isExpressionInvocation: false,
            isImplicitCall: true,
            hoistedExpressions: hoistedExpressions);
    }
  }

  void _checkBoundsInMethodInvocation(
      ObjectAccessTarget target,
      DartType receiverType,
      DartType calleeType,
      Name methodName,
      Arguments arguments,
      int fileOffset) {
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
    libraryBuilder.checkBoundsInMethodInvocation(
        actualReceiverType,
        typeSchemaEnvironment,
        hierarchyBuilder,
        membersBuilder,
        actualMethodName,
        interfaceTarget,
        arguments,
        helper.uri,
        fileOffset);
  }

  void checkBoundsInInstantiation(
      FunctionType functionType, List<DartType> arguments, int fileOffset,
      {required bool inferred}) {
    // If [arguments] were inferred, check them.

    libraryBuilder.checkBoundsInInstantiation(
        typeSchemaEnvironment, functionType, arguments, helper.uri, fileOffset,
        inferred: inferred);
  }

  void _checkBoundsInFunctionInvocation(FunctionType functionType,
      String? localName, Arguments arguments, int fileOffset) {
    // If [arguments] were inferred, check them.
    libraryBuilder.checkBoundsInFunctionInvocation(typeSchemaEnvironment,
        functionType, localName, arguments, helper.uri, fileOffset);
  }

  /// Performs the core type inference algorithm for super method invocations.
  ExpressionInferenceResult inferSuperMethodInvocation(
      InferenceVisitor visitor,
      Expression expression,
      Name methodName,
      ArgumentsImpl arguments,
      DartType typeContext,
      Procedure procedure) {
    int fileOffset = expression.fileOffset;
    ObjectAccessTarget target = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(thisType!, procedure,
            hasNonObjectMemberAccess: true)
        : new ObjectAccessTarget.superMember(thisType!, procedure);
    DartType receiverType = thisType!;
    bool isSpecialCasedBinaryOperator =
        target.isSpecialCasedBinaryOperator(this);
    DartType calleeType = computeTypeFromSuperClass(
        procedure.enclosingClass!, target.getGetterType(this));
    FunctionType functionType = computeTypeFromSuperClass(
            procedure.enclosingClass!, target.getFunctionType(this))
        as FunctionType;
    if (isNonNullableByDefault &&
        methodName == equalsName &&
        functionType.positionalParameters.length == 1) {
      // operator == always allows nullable arguments.
      functionType = new FunctionType([
        functionType.positionalParameters.single
            .withDeclaredNullability(libraryBuilder.nullable)
      ], functionType.returnType, functionType.declaredNullability);
    }
    InvocationInferenceResult result = inferInvocation(
        visitor, typeContext, fileOffset, functionType, arguments,
        isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
        receiverType: receiverType,
        isImplicitExtensionMember: false);
    DartType inferredType = result.inferredType;
    if (methodName.text == '==') {
      inferredType = coreTypes.boolRawType(libraryBuilder.nonNullable);
    }
    _checkBoundsInMethodInvocation(
        target, receiverType, calleeType, methodName, arguments, fileOffset);

    return new ExpressionInferenceResult(
        inferredType, result.applyResult(expression));
  }

  /// Performs the core type inference algorithm for super property get.
  ExpressionInferenceResult inferSuperPropertyGet(
      Expression expression, Name name, DartType typeContext, Member member) {
    ObjectAccessTarget readTarget = thisType!.classNode.isMixinDeclaration
        ? new ObjectAccessTarget.interfaceMember(thisType!, member,
            hasNonObjectMemberAccess: true)
        : new ObjectAccessTarget.superMember(thisType!, member);
    DartType inferredType = computeTypeFromSuperClass(
        member.enclosingClass!, readTarget.getGetterType(this));
    if (member is Procedure && member.kind == ProcedureKind.Method) {
      return instantiateTearOff(inferredType, typeContext, expression);
    }
    DartType? promotedType = flowAnalysis.propertyGet(expression,
        SuperPropertyTarget.singleton, name.text, member, inferredType);
    if (promotedType != null) {
      expression = new AsExpression(expression, promotedType)
        ..isUnchecked = true
        ..fileOffset = expression.fileOffset;
      inferredType = promotedType;
    }
    return new ExpressionInferenceResult(inferredType, expression);
  }

  /// Computes the implicit instantiation from an expression of [tearOffType]
  /// to the [context] type. Return `null` if an implicit instantiation is not
  /// necessary or possible.
  ImplicitInstantiation? computeImplicitInstantiation(
      DartType tearoffType, DartType context,
      {required TreeNode? treeNodeForTesting}) {
    if (tearoffType is FunctionType &&
        context is FunctionType &&
        context.typeParameters.isEmpty) {
      FunctionType functionType = tearoffType;
      List<StructuralParameter> typeParameters = functionType.typeParameters;
      if (typeParameters.isNotEmpty) {
        List<DartType> inferredTypes = new List<DartType>.filled(
            typeParameters.length, const UnknownType());
        FunctionType instantiatedType = functionType.withoutTypeParameters;
        TypeConstraintGatherer gatherer =
            typeSchemaEnvironment.setupGenericTypeInference(
                instantiatedType, typeParameters, context,
                isNonNullableByDefault: isNonNullableByDefault,
                typeOperations: cfeOperations,
                inferenceResultForTesting: dataForTesting?.typeInferenceResult,
                treeNodeForTesting: treeNodeForTesting);
        inferredTypes = typeSchemaEnvironment.chooseFinalTypes(
            gatherer, typeParameters, inferredTypes,
            isNonNullableByDefault: isNonNullableByDefault);
        FunctionTypeInstantiator instantiator =
            new FunctionTypeInstantiator.fromIterables(
                typeParameters, inferredTypes);
        tearoffType = instantiator.substitute(instantiatedType);
        return new ImplicitInstantiation(
            inferredTypes, functionType, tearoffType);
      }
    }
    return null;
  }

  ExpressionInferenceResult _applyImplicitInstantiation(
      ImplicitInstantiation? implicitInstantiation,
      DartType tearOffType,
      Expression expression) {
    if (implicitInstantiation != null) {
      FunctionType uninstantiatedType = implicitInstantiation.functionType;

      List<DartType> typeArguments = implicitInstantiation.typeArguments;
      checkBoundsInInstantiation(
          uninstantiatedType, typeArguments, expression.fileOffset,
          inferred: true);

      if (expression is TypedefTearOff) {
        Substitution substitution =
            Substitution.fromPairs(expression.typeParameters, typeArguments);
        typeArguments =
            expression.typeArguments.map(substitution.substituteType).toList();
        expression = expression.expression;
      } else {
        LoweredTypedefTearOff? loweredTypedefTearOff =
            LoweredTypedefTearOff.fromExpression(expression);
        if (loweredTypedefTearOff != null) {
          Substitution substitution = Substitution.fromPairs(
              loweredTypedefTearOff.typedefTearOff.function.typeParameters,
              typeArguments);
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
        VariableDeclaration t = new VariableDeclaration.forValue(expression,
            type: uninstantiatedType)
          ..fileOffset = expression.fileOffset;

        Expression nullCheck = new EqualsNull(
            new VariableGet(t)..fileOffset = expression.fileOffset)
          ..fileOffset = expression.fileOffset;

        ConditionalExpression conditional = new ConditionalExpression(
            nullCheck,
            new NullLiteral()..fileOffset = expression.fileOffset,
            new Instantiation(
                new VariableGet(t, uninstantiatedType.toNonNull()),
                typeArguments)
              ..fileOffset = expression.fileOffset,
            tearOffType);
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
      DartType tearoffType, DartType context, Expression expression) {
    ImplicitInstantiation? implicitInstantiation = computeImplicitInstantiation(
        tearoffType, context,
        treeNodeForTesting: expression);
    return _applyImplicitInstantiation(
        implicitInstantiation, tearoffType, expression);
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
      TypeDeclaration enclosingTypeDeclaration, DartType type) {
    if (enclosingTypeDeclaration.typeParameters.isEmpty) return false;
    IncludesTypeParametersNonCovariantly checker =
        new IncludesTypeParametersNonCovariantly(
            enclosingTypeDeclaration.typeParameters,
            // We are checking the returned type (field/getter type or return
            // type of a method) and this is a covariant position.
            initialVariance: Variance.covariant);
    return type.accept(checker);
  }

  /// Determines the dispatch category of a [MethodInvocation] and returns a
  /// boolean indicating whether an "as" check will need to be added due to
  /// contravariance.
  MethodContravarianceCheckKind preCheckInvocationContravariance(
      DartType receiverType, ObjectAccessTarget target,
      {required bool isThisReceiver}) {
    if (target.isInstanceMember || target.isObjectMember) {
      Member interfaceMember = target.member!;
      if (interfaceMember is Field ||
          interfaceMember is Procedure &&
              interfaceMember.kind == ProcedureKind.Getter) {
        DartType getType = target.getGetterType(this);
        if (getType is DynamicType) {
          return MethodContravarianceCheckKind.none;
        }
        if (!isThisReceiver) {
          if ((interfaceMember is Field &&
                  returnedTypeParametersOccurNonCovariantly(
                      interfaceMember.enclosingTypeDeclaration!,
                      interfaceMember.type)) ||
              (interfaceMember is Procedure &&
                  returnedTypeParametersOccurNonCovariantly(
                      interfaceMember.enclosingTypeDeclaration!,
                      interfaceMember.function.returnType))) {
            return MethodContravarianceCheckKind.checkGetterReturn;
          }
        }
      } else if (!isThisReceiver &&
          interfaceMember is Procedure &&
          returnedTypeParametersOccurNonCovariantly(
              interfaceMember.enclosingTypeDeclaration!,
              interfaceMember.function.returnType)) {
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
    return new FutureOrType(type, libraryBuilder.nonNullable);
  }

  DartType wrapFutureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        coreTypes.futureClass, nullability, <DartType>[type]);
  }

  DartType wrapType(DartType type, Class class_, Nullability nullability) {
    return new InterfaceType(class_, nullability, <DartType>[type]);
  }

  /// Computes the `futureValueTypeSchema` for the type schema [type].
  ///
  /// This is the same as the [emittedValueType] except that this handles
  /// the unknown type.
  DartType computeFutureValueTypeSchema(DartType type) {
    return type.accept1(new FutureValueTypeVisitor(unhandledTypeHandler:
        (AuxiliaryType node,
            CoreTypes coreTypes,
            DartType Function(AuxiliaryType node, CoreTypes coreTypes)
                recursor) {
      if (node is UnknownType) {
        // futureValueTypeSchema(_) = _.
        return node;
      }
      throw new UnsupportedError("Unsupported type '${node.runtimeType}'.");
    }), coreTypes);
  }

  Member? _getInterfaceMember(Class class_, Name name, bool setter) {
    Member? member =
        engine.membersBuilder.getInterfaceMember(class_, name, setter: setter);
    return TypeInferenceEngine.resolveInferenceNode(member, hierarchyBuilder);
  }

  ClassMember? _getExtensionTypeMember(
      ExtensionTypeDeclaration extensionTypeDeclaration,
      Name name,
      bool setter) {
    ClassMember? member = engine.membersBuilder.getExtensionTypeClassMember(
        extensionTypeDeclaration, name,
        setter: setter);
    TypeInferenceEngine.resolveInferenceNode(
        member?.getMember(engine.membersBuilder), hierarchyBuilder);
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
  Template<Message Function(DartType, DartType, bool)>?
      _getPreciseTypeErrorTemplate(Expression expression) {
    if (expression is ListLiteral) {
      return templateInvalidCastLiteralList;
    }
    if (expression is MapLiteral) {
      return templateInvalidCastLiteralMap;
    }
    if (expression is SetLiteral || _isLoweredSetLiteral(expression)) {
      return templateInvalidCastLiteralSet;
    }
    if (expression is FunctionExpression) {
      return templateInvalidCastFunctionExpr;
    }
    if (expression is ConstructorInvocation) {
      return templateInvalidCastNewExpr;
    }
    if (expression is StaticGet) {
      Member target = expression.target;
      if (target is Procedure && target.kind == ProcedureKind.Method) {
        if (target.enclosingClass != null) {
          return templateInvalidCastStaticMethod;
        } else {
          return templateInvalidCastTopLevelFunction;
        }
      }
      return null;
    }
    if (expression is StaticTearOff) {
      Member target = expression.target;
      if (target.enclosingClass != null) {
        return templateInvalidCastStaticMethod;
      } else {
        return templateInvalidCastTopLevelFunction;
      }
    }
    if (expression is VariableGet) {
      VariableDeclaration variable = expression.variable;
      if (variable is VariableDeclarationImpl && variable.isLocalFunction) {
        return templateInvalidCastLocalFunction;
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
      if (!typeSchemaEnvironment.isSubtypeOf(expressionType, contextType,
          SubtypeCheckMode.ignoringNullabilities)) {
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
      int fileOffset, Expression receiver, Name name, Arguments arguments) {
    return new DynamicInvocation(
        DynamicAccessKind.Unresolved, receiver, name, arguments)
      ..fileOffset = fileOffset;
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
      int fileOffset, Expression receiver, Name name, Expression value) {
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
      int fileOffset, Expression first, Expression second) {
    return new BlockExpression(
        new Block([new ExpressionStatement(first)..fileOffset = fileOffset])
          ..fileOffset = fileOffset,
        second)
      ..fileOffset = fileOffset;
  }

  Expression _reportMissingOrAmbiguousMember(
      int fileOffset,
      int length,
      DartType receiverType,
      Name name,
      Expression? wrappedExpression,
      List<ExtensionAccessCandidate>? extensionAccessCandidates,
      Template<Message Function(String, DartType, bool)> missingTemplate,
      Template<Message Function(String, DartType, bool)> ambiguousTemplate) {
    List<LocatedMessage>? context;
    Template<Message Function(String, DartType, bool)> template =
        missingTemplate;
    if (extensionAccessCandidates != null) {
      context = extensionAccessCandidates
          .map((ExtensionAccessCandidate c) =>
              messageAmbiguousExtensionCause.withLocation(
                  c.memberBuilder.fileUri!,
                  c.memberBuilder.charOffset,
                  name == unaryMinusName ? 1 : c.memberBuilder.name.length))
          .toList();
      template = ambiguousTemplate;
    }
    if (wrappedExpression != null) {
      return helper.wrapInProblem(
          wrappedExpression,
          template.withArguments(name.text, receiverType.nonTypeVariableBound,
              isNonNullableByDefault),
          fileOffset,
          length,
          context: context);
    } else {
      return helper.buildProblem(
          template.withArguments(name.text, receiverType.nonTypeVariableBound,
              isNonNullableByDefault),
          fileOffset,
          length,
          context: context);
    }
  }

  Expression createMissingMethodInvocation(
      int fileOffset, DartType receiverType, Name name,
      {Expression? receiver,
      Arguments? arguments,
      required bool isExpressionInvocation,
      Name? implicitInvocationPropertyName,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    assert((receiver == null) == (arguments == null),
        "Receiver and arguments must be supplied together.");
    if (implicitInvocationPropertyName != null) {
      assert(extensionAccessCandidates == null);
      if (receiver != null) {
        return helper.wrapInProblem(
            _createInvalidInvocation(fileOffset, receiver, name, arguments!),
            templateInvokeNonFunction
                .withArguments(implicitInvocationPropertyName.text),
            fileOffset,
            implicitInvocationPropertyName.text.length);
      } else {
        return helper.buildProblem(
            templateInvokeNonFunction
                .withArguments(implicitInvocationPropertyName.text),
            fileOffset,
            implicitInvocationPropertyName.text.length);
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
          templateUndefinedMethod,
          templateAmbiguousExtensionMethod);
    }
  }

  PropertyGetInferenceResult createPropertyGet(
      {required int fileOffset,
      required Expression receiver,
      required DartType receiverType,
      required Name propertyName,
      required DartType typeContext,
      ObjectAccessTarget? readTarget,
      DartType? readType,
      required DartType? promotedReadType,
      required bool isThisReceiver,
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    Expression read;
    ExpressionInferenceResult? readResult;

    readTarget ??= findInterfaceMember(receiverType, propertyName, fileOffset,
        includeExtensionMethods: true, isSetter: false);
    readType ??= readTarget.getGetterType(this);

    switch (readTarget.kind) {
      case ObjectAccessTargetKind.missing:
        read = createMissingPropertyGet(fileOffset, receiverType, propertyName,
            receiver: receiver);
        break;
      case ObjectAccessTargetKind.ambiguous:
        read = createMissingPropertyGet(fileOffset, receiverType, propertyName,
            receiver: receiver,
            extensionAccessCandidates: readTarget.candidates);
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
      case ObjectAccessTargetKind.extensionTypeMember:
      case ObjectAccessTargetKind.nullableExtensionTypeMember:
        switch (readTarget.declarationMethodKind) {
          case ClassMemberKind.Getter:
            read = new StaticInvocation(
                readTarget.member as Procedure,
                new ArgumentsImpl(<Expression>[
                  receiver,
                ], types: readTarget.receiverTypeArguments)
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset;
            break;
          case ClassMemberKind.Method:
            read = new StaticInvocation(
                readTarget.tearoffTarget as Procedure,
                new Arguments(<Expression>[
                  receiver,
                ], types: readTarget.receiverTypeArguments)
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset;
            readResult = instantiateTearOff(readType, typeContext, read);
            break;
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
          Member interfaceMember = readTarget.classMember!;
          if (interfaceMember is Procedure) {
            GenericDeclaration? enclosingDeclaration =
                interfaceMember.enclosingTypeDeclaration!;
            if (enclosingDeclaration.typeParameters.isEmpty) {
              checkReturn = false;
            } else {
              DartType typeToCheck = isNonNullableByDefault
                  ? interfaceMember.function
                      .computeFunctionType(libraryBuilder.nonNullable)
                  : interfaceMember.function.returnType;
              checkReturn = InferenceVisitorBase
                  .returnedTypeParametersOccurNonCovariantly(
                      interfaceMember.enclosingTypeDeclaration!, typeToCheck);
            }
          } else if (interfaceMember is Field) {
            checkReturn =
                InferenceVisitorBase.returnedTypeParametersOccurNonCovariantly(
                    interfaceMember.enclosingTypeDeclaration!,
                    interfaceMember.type);
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
      case ObjectAccessTargetKind.recordIndexed:
      case ObjectAccessTargetKind.nullableRecordIndexed:
        read = new RecordIndexGet(receiver,
            readTarget.receiverType as RecordType, readTarget.recordFieldIndex!)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.recordNamed:
      case ObjectAccessTargetKind.nullableRecordNamed:
        read = new RecordNameGet(receiver,
            readTarget.receiverType as RecordType, readTarget.recordFieldName!)
          ..fileOffset = fileOffset;
        break;
      case ObjectAccessTargetKind.extensionTypeRepresentation:
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        read = new AsExpression(receiver, readType)
          ..isForNonNullableByDefault = isNonNullableByDefault
          ..isUnchecked = true
          ..fileOffset = fileOffset;
        break;
    }

    if (promotedReadType != null) {
      read = new AsExpression(read, promotedReadType)
        ..isForNonNullableByDefault = isNonNullableByDefault
        ..isUnchecked = true
        ..fileOffset = fileOffset;
      readType = promotedReadType;
    }

    if (!isNonNullableByDefault) {
      readType = legacyErasure(readType);
    }

    readResult ??= new ExpressionInferenceResult(readType, read);
    if (readTarget.isNullable) {
      readResult = wrapExpressionInferenceResultInProblem(
          readResult,
          templateNullablePropertyAccessError.withArguments(
              propertyName.text, receiverType, isNonNullableByDefault),
          read.fileOffset,
          propertyName.text.length,
          context: whyNotPromoted != null
              ? getWhyNotPromotedContext(
                  whyNotPromoted(), read, (type) => !type.isPotentiallyNullable)
              : null);
    }
    return new PropertyGetInferenceResult(readResult, readTarget.member);
  }

  Expression createMissingPropertyGet(
      int fileOffset, DartType receiverType, Name propertyName,
      {Expression? receiver,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    Template<Message Function(String, DartType, bool)> templateMissing =
        templateUndefinedGetter;
    return _reportMissingOrAmbiguousMember(
        fileOffset,
        propertyName.text.length,
        receiverType,
        propertyName,
        receiver != null
            ? _createInvalidGet(fileOffset, receiver, propertyName)
            : null,
        extensionAccessCandidates,
        templateMissing,
        templateAmbiguousExtensionProperty);
  }

  Expression createMissingPropertySet(int fileOffset, Expression receiver,
      DartType receiverType, Name propertyName, Expression value,
      {required bool forEffect,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    Template<Message Function(String, DartType, bool)> templateMissing =
        templateUndefinedSetter;
    return _reportMissingOrAmbiguousMember(
        fileOffset,
        propertyName.text.length,
        receiverType,
        propertyName,
        _createInvalidSet(fileOffset, receiver, propertyName, value),
        extensionAccessCandidates,
        templateMissing,
        templateAmbiguousExtensionProperty);
  }

  Expression createMissingIndexGet(int fileOffset, Expression receiver,
      DartType receiverType, Expression index,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    Template<Message Function(String, DartType, bool)> templateMissing =
        templateUndefinedOperator;

    return _reportMissingOrAmbiguousMember(
        fileOffset,
        noLength,
        receiverType,
        indexGetName,
        _createInvalidInvocation(fileOffset, receiver, indexGetName,
            new Arguments([index])..fileOffset = fileOffset),
        extensionAccessCandidates,
        templateMissing,
        templateAmbiguousExtensionOperator);
  }

  Expression createMissingIndexSet(int fileOffset, Expression receiver,
      DartType receiverType, Expression index, Expression value,
      {required bool forEffect,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    Template<Message Function(String, DartType, bool)> templateMissing =
        templateUndefinedOperator;
    return _reportMissingOrAmbiguousMember(
        fileOffset,
        noLength,
        receiverType,
        indexSetName,
        _createInvalidInvocation(fileOffset, receiver, indexSetName,
            new Arguments([index, value])..fileOffset = fileOffset),
        extensionAccessCandidates,
        templateMissing,
        templateAmbiguousExtensionOperator);
  }

  Expression createMissingBinary(int fileOffset, Expression left,
      DartType leftType, Name binaryName, Expression right,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    assert(binaryName != equalsName);
    Template<Message Function(String, DartType, bool)> templateMissing =
        templateUndefinedOperator;
    return _reportMissingOrAmbiguousMember(
        fileOffset,
        binaryName.text.length,
        leftType,
        binaryName,
        _createInvalidInvocation(fileOffset, left, binaryName,
            new Arguments([right])..fileOffset = fileOffset),
        extensionAccessCandidates,
        templateMissing,
        templateAmbiguousExtensionOperator);
  }

  Expression createMissingUnary(int fileOffset, Expression expression,
      DartType expressionType, Name unaryName,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    Template<Message Function(String, DartType, bool)> templateMissing =
        templateUndefinedOperator;
    return _reportMissingOrAmbiguousMember(
        fileOffset,
        unaryName == unaryMinusName ? 1 : unaryName.text.length,
        expressionType,
        unaryName,
        _createInvalidInvocation(fileOffset, expression, unaryName,
            new Arguments([])..fileOffset = fileOffset),
        extensionAccessCandidates,
        templateMissing,
        templateAmbiguousExtensionOperator);
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
          templateGenericFunctionTypeInferredAsActualTypeArgument.withArguments(
              typeArgument, isNonNullableByDefault),
          fileOffset,
          noLength,
          helper.uri);
    }
  }

  DartType _computeInferredType(ExpressionInferenceResult result) =>
      identical(result.inferredType, noInferredType) || isNonNullableByDefault
          ? result.inferredType
          : legacyErasure(result.inferredType);

  Expression? checkWebIntLiteralsErrorIfUnexact(
      int value, String? literal, int charOffset) {
    if (value >= 0 && value <= (1 << 53)) return null;
    if (!libraryBuilder
        .loader.target.backendTarget.errorOnUnexactWebIntLiterals) {
      return null;
    }
    BigInt asInt = new BigInt.from(value).toUnsigned(64);
    BigInt asDouble = new BigInt.from(asInt.toDouble());
    if (asInt == asDouble) return null;
    String text = literal ?? value.toString();
    String nearest = text.startsWith('0x') || text.startsWith('0X')
        ? '0x${asDouble.toRadixString(16)}'
        : asDouble.toString();
    int length = literal?.length ?? noLength;
    return helper.buildProblem(
        templateWebLiteralCannotBeRepresentedExactly.withArguments(
            text, nearest),
        charOffset,
        length);
  }

  /// The client of type inference should call this method after asking
  /// inference to visit a node.  This performs assertions to make sure that
  /// temporary type inference state has been properly cleaned up.
  void checkCleanState();
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

  const AssignabilityResult(this.kind,
      {required this.needsTearOff, this.implicitInstantiation})
      : subtype = null,
        supertype = null;

  AssignabilityResult.withTypes(this.kind, this.subtype, this.supertype,
      {required this.needsTearOff, this.implicitInstantiation});
}

/// Convenient way to return both a tear-off expression and its type.
class TypedTearoff {
  final DartType tearoffType;
  final Expression tearoff;

  TypedTearoff(this.tearoffType, this.tearoff);
}

FunctionType replaceReturnType(FunctionType functionType, DartType returnType) {
  return new FunctionType(functionType.positionalParameters, returnType,
      functionType.declaredNullability,
      requiredParameterCount: functionType.requiredParameterCount,
      namedParameters: functionType.namedParameters,
      typeParameters: functionType.typeParameters);
}

class _WhyNotPromotedVisitor
    implements
        NonPromotionReasonVisitor<List<LocatedMessage>, Node,
            VariableDeclaration, DartType> {
  final InferenceVisitorBase inferrer;

  Member? propertyReference;

  DartType? propertyType;

  _WhyNotPromotedVisitor(this.inferrer);

  @override
  List<LocatedMessage> visitDemoteViaExplicitWrite(
      DemoteViaExplicitWrite<VariableDeclaration> reason) {
    TreeNode node = reason.node as TreeNode;
    if (inferrer.dataForTesting != null) {
      inferrer.dataForTesting!.flowAnalysisResult
          .nonPromotionReasonTargets[node] = reason.shortName;
    }
    int offset = node.fileOffset;
    return [
      templateVariableCouldBeNullDueToWrite
          .withArguments(reason.variable.name!, reason.documentationLink.url)
          .withLocation(inferrer.helper.uri, offset, noLength)
    ];
  }

  @override
  List<LocatedMessage> visitPropertyNotPromotedForNonInherentReason(
      PropertyNotPromotedForNonInherentReason<DartType> reason) {
    FieldNonPromotabilityInfo? fieldNonPromotabilityInfo =
        this.inferrer.libraryBuilder.fieldNonPromotabilityInfo;
    if (fieldNonPromotabilityInfo == null) {
      // `fieldPromotabilityInfo` is computed for all library builders except
      // those for augmentation libraries.
      assert(this.inferrer.libraryBuilder.isAugmenting);
      // "why not promoted" functionality is not supported in augmentation
      // libraries, so just don't generate a context message.
      return const [];
    }
    FieldNameNonPromotabilityInfo<Class, SourceFieldBuilder,
            SourceProcedureBuilder>? fieldNameInfo =
        fieldNonPromotabilityInfo.fieldNameInfo[reason.propertyName];
    List<LocatedMessage> messages = [];
    if (fieldNameInfo != null) {
      for (SourceFieldBuilder field in fieldNameInfo.conflictingFields) {
        messages.add(templateFieldNotPromotedBecauseConflictingField
            .withArguments(
                reason.propertyName,
                field.readTarget.enclosingClass!.name,
                NonPromotionDocumentationLink.conflictingNonPromotableField.url)
            .withLocation(field.fileUri, field.charOffset, noLength));
      }
      for (SourceProcedureBuilder getter in fieldNameInfo.conflictingGetters) {
        messages.add(templateFieldNotPromotedBecauseConflictingGetter
            .withArguments(
                reason.propertyName,
                getter.procedure.enclosingClass!.name,
                NonPromotionDocumentationLink.conflictingGetter.url)
            .withLocation(getter.fileUri, getter.charOffset, noLength));
      }
      for (Class nsmClass in fieldNameInfo.conflictingNsmClasses) {
        messages.add(templateFieldNotPromotedBecauseConflictingNsmForwarder
            .withArguments(
                reason.propertyName,
                nsmClass.name,
                NonPromotionDocumentationLink
                    .conflictingNoSuchMethodForwarder.url)
            .withLocation(nsmClass.fileUri, nsmClass.fileOffset, noLength));
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
      PropertyNotPromotedForInherentReason<DartType> reason) {
    Object? member = reason.propertyMember;
    if (member is Member) {
      if (member case Procedure(:var stubTarget?)) {
        // Use the stub target so that the context message has a better source
        // location.
        member = stubTarget;
      }
      propertyReference = member;
      propertyType = reason.staticType;
      Template<Message Function(String, String)> template =
          switch (reason.whyNotPromotable) {
        PropertyNonPromotabilityReason.isNotField =>
          templateFieldNotPromotedBecauseNotField,
        PropertyNonPromotabilityReason.isNotPrivate =>
          templateFieldNotPromotedBecauseNotPrivate,
        PropertyNonPromotabilityReason.isExternal =>
          templateFieldNotPromotedBecauseExternal,
        PropertyNonPromotabilityReason.isNotFinal =>
          templateFieldNotPromotedBecauseNotFinal
      };
      List<LocatedMessage> messages = [
        template
            .withArguments(reason.propertyName, reason.documentationLink.url)
            .withLocation(member.fileUri, member.fileOffset, noLength)
      ];
      if (!reason.fieldPromotionEnabled) {
        _addFieldPromotionUnavailableMessage(reason, messages);
      }
      return messages;
    } else {
      assert(member == null,
          'Unrecognized property member: ${member.runtimeType}');
      return const [];
    }
  }

  @override
  List<LocatedMessage> visitThisNotPromoted(ThisNotPromoted reason) {
    return [
      templateThisNotPromoted
          .withArguments(reason.documentationLink.url)
          .withoutLocation()
    ];
  }

  void _addFieldPromotionUnavailableMessage(
      PropertyNotPromoted<DartType> reason, List<LocatedMessage> messages) {
    Object? member = reason.propertyMember;
    if (member is Member) {
      messages.add(templateFieldNotPromotedBecauseNotEnabled
          .withArguments(reason.propertyName,
              NonPromotionDocumentationLink.fieldPromotionUnavailable.url)
          .withLocation(member.fileUri, member.fileOffset, noLength));
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
      this.typeArguments, this.functionType, this.instantiatedType);
}

/// Information about an invocation argument that needs to be resolved later due
/// to the fact that it's a function literal and the `inference-update-1`
/// feature is enabled.
class _DeferredParamInfo extends _ParamInfo {
  /// The argument expression (possibly wrapped in an arbitrary number of
  /// ParenthesizedExpressions).
  final Expression argumentExpression;

  /// The unparenthesized argument expression.
  final FunctionExpression unparenthesizedExpression;

  /// Indicates whether this is a named argument.
  final bool isNamed;

  /// The index into the full argument list (considering both named and unnamed
  /// arguments) of the function literal expression.
  final int evaluationOrderIndex;

  /// The index into either [Arguments.named] or [Arguments.positional] of the
  /// function literal expression (depending upon the value of [isNamed]).
  final int index;

  _DeferredParamInfo(
      {required DartType formalType,
      required this.argumentExpression,
      required this.unparenthesizedExpression,
      required this.isNamed,
      required this.evaluationOrderIndex,
      required this.index})
      : super(formalType);
}

/// Extension of the shared [FunctionLiteralDependencies] logic used by the
/// front end.
class _FunctionLiteralDependencies extends FunctionLiteralDependencies<
    StructuralParameter, _ParamInfo, _DeferredParamInfo> {
  _FunctionLiteralDependencies(
      Iterable<_DeferredParamInfo> deferredParamInfo,
      Iterable<StructuralParameter> typeVariables,
      List<_ParamInfo> undeferredParamInfo)
      : super(deferredParamInfo, typeVariables, undeferredParamInfo);

  @override
  Iterable<StructuralParameter> typeVarsFreeInParamParams(
      _DeferredParamInfo paramInfo) {
    DartType type = paramInfo.formalType;
    if (type is FunctionType) {
      Map<Object, DartType> parameterMap = _computeParameterMap(type);
      Set<Object> explicitlyTypedParameters =
          _computeExplicitlyTypedParameterSet(
              paramInfo.unparenthesizedExpression);
      Set<StructuralParameter> result = {};
      for (MapEntry<Object, DartType> entry in parameterMap.entries) {
        if (explicitlyTypedParameters.contains(entry.key)) continue;
        result.addAll(allFreeTypeVariables(entry.value));
      }
      return result;
    } else {
      return const [];
    }
  }

  @override
  Iterable<StructuralParameter> typeVarsFreeInParamReturns(
      _ParamInfo paramInfo) {
    DartType type = paramInfo.formalType;
    if (type is FunctionType) {
      return allFreeTypeVariables(type.returnType);
    } else {
      return allFreeTypeVariables(type);
    }
  }
}

/// Information about an invocation argument that may or may not have already
/// been resolved, as part of the deferred resolution mechanism for the
/// `inference-update-1` feature.
class _ParamInfo {
  /// The (unsubstituted) type of the formal parameter corresponding to this
  /// argument.
  final DartType formalType;

  _ParamInfo(this.formalType);
}

class _ObjectAccessDescriptor {
  final DartType receiverType;
  final Name name;
  final DartType receiverBound;
  final Class classNode;
  final bool hasNonObjectMemberAccess;
  final bool isSetter;
  final int fileOffset;

  _ObjectAccessDescriptor(
      {required this.receiverType,
      required this.name,
      required this.receiverBound,
      required this.classNode,
      required this.hasNonObjectMemberAccess,
      required this.isSetter,
      required this.fileOffset});

  /// Returns the [ObjectAccessTarget] corresponding to this descriptor.
  ObjectAccessTarget findNonExtensionTarget(InferenceVisitorBase visitor) {
    return _findNonExtensionTargetInternal(visitor, name, isSetter: isSetter);
  }

  ObjectAccessTarget _findNonExtensionTargetInternal(
      InferenceVisitorBase visitor, Name name,
      {required bool isSetter}) {
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
          Member? interfaceMember =
              visitor._getInterfaceMember(classNode, name, isSetter);
          FunctionType? functionType;
          if (interfaceMember is Procedure) {
            // The member exists on `Object` but has a special function type
            // that we compute here.
            FunctionNode function = interfaceMember.function;
            assert(
                function.namedParameters.isEmpty,
                "Unexpected named parameters on $classNode member "
                "$interfaceMember.");
            assert(
                function.typeParameters.isEmpty,
                "Unexpected type parameters on $classNode member "
                "$interfaceMember.");
            functionType = new FunctionType(
                new List<DartType>.filled(
                    function.positionalParameters.length, const DynamicType()),
                const NeverType.nonNullable(),
                Nullability.nonNullable);
          }
          return new ObjectAccessTarget.never(
            member: interfaceMember,
            functionType: functionType,
          );
        case Nullability.nullable:
        case Nullability.legacy:
          // Never? and Never* are equivalent to Null.
          return visitor.findInterfaceMember(const NullType(), name, fileOffset,
              isSetter: isSetter);
        case Nullability.undetermined:
          return internalProblem(
              templateInternalProblemUnsupportedNullability.withArguments(
                  "${receiverBound.nullability}",
                  receiverBound,
                  visitor.isNonNullableByDefault),
              fileOffset,
              visitor.libraryBuilder.fileUri);
      }
    } else if (receiverBound is RecordType && !isSetter) {
      String text = name.text;
      int? index = tryParseRecordPositionalGetterName(
          text, receiverBound.positional.length);
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
                  receiverBound, field.type, field.name)
              : new RecordNameTarget.nullable(
                  receiverBound, field.type, field.name);
        }
      }
    } else if (receiverBound is ExtensionType) {
      ObjectAccessTarget? target = visitor._findExtensionTypeMember(
          receiverType, receiverBound, name, fileOffset,
          isSetter: isSetter,
          hasNonObjectMemberAccess: hasNonObjectMemberAccess);
      if (target != null) {
        return target;
      }
    }

    ObjectAccessTarget? target;
    Member? interfaceMember =
        visitor._getInterfaceMember(classNode, name, isSetter);
    if (interfaceMember != null) {
      target = new ObjectAccessTarget.interfaceMember(
          receiverType, interfaceMember,
          hasNonObjectMemberAccess: hasNonObjectMemberAccess);
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

  /// Returns the name of the complementary getter/setter access corresponding
  /// to this descriptor.
  Name get complementaryName {
    _computeComplementaryNameAndKind();
    return _complementaryName!;
  }

  bool? _complementaryIsSetter;

  /// Returns `true` if the complementary getter/setter access corresponding to
  /// this descriptor is a setter access.
  bool get complementaryIsSetter {
    _computeComplementaryNameAndKind();
    return _complementaryIsSetter!;
  }

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
        visitor, otherName,
        isSetter: otherIsSetter);
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
      case ObjectAccessTargetKind.nullableExtensionTypeRepresentation:
        return false;
    }
  }
}
