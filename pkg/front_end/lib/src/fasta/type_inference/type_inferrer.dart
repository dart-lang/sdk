// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/canonical_name.dart' as kernel;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/bounds_checks.dart' show calculateBounds;
import 'package:kernel/src/future_value_type.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../base/instrumentation.dart'
    show
        Instrumentation,
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;
import '../../base/nnbd_mode.dart';
import '../../testing/id_extractor.dart';
import '../../testing/id_testing_utils.dart';
import '../builder/extension_builder.dart';
import '../builder/member_builder.dart';
import '../fasta_codes.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/inference_visitor.dart';
import '../kernel/internal_ast.dart';
import '../kernel/invalid_type.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart' show hasAnyTypeVariables;
import '../names.dart';
import '../problems.dart' show internalProblem, unexpected, unhandled;
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'inference_helper.dart' show InferenceHelper;
import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;
import 'type_demotion.dart';
import 'type_inference_engine.dart';
import 'type_schema.dart' show isKnown, UnknownType;
import 'type_schema_elimination.dart' show greatestClosure;
import 'type_schema_environment.dart'
    show
        getNamedParameterType,
        getPositionalParameterType,
        TypeConstraint,
        TypeVariableEliminator,
        TypeSchemaEnvironment;

part 'closure_context.dart';

/// Given a [FunctionNode], gets the named parameter identified by [name], or
/// `null` if there is no parameter with the given name.
VariableDeclaration? getNamedFormal(FunctionNode function, String name) {
  for (VariableDeclaration formal in function.namedParameters) {
    if (formal.name == name) return formal;
  }
  return null;
}

/// Given a [FunctionNode], gets the [i]th positional formal parameter, or
/// `null` if there is no parameter with that index.
VariableDeclaration? getPositionalFormal(FunctionNode function, int i) {
  if (i < function.positionalParameters.length) {
    return function.positionalParameters[i];
  } else {
    return null;
  }
}

bool isOverloadableArithmeticOperator(String name) {
  return identical(name, '+') ||
      identical(name, '-') ||
      identical(name, '*') ||
      identical(name, '%');
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

/// Keeps track of the local state for the type inference that occurs during
/// compilation of a single method body or top level initializer.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. BodyBuilder).  Derived classes should derive from [TypeInferrerImpl].
abstract class TypeInferrer {
  SourceLibraryBuilder get library;

  /// Gets the [TypeSchemaEnvironment] being used for type inference.
  TypeSchemaEnvironment get typeSchemaEnvironment;

  /// Returns the [FlowAnalysis] used during inference.
  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration, DartType>
      get flowAnalysis;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  Uri get uriForInstrumentation;

  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables;

  /// Performs full type inference on the given field initializer.
  ExpressionInferenceResult inferFieldInitializer(
      InferenceHelper helper, DartType declaredType, Expression initializer);

  /// Returns the type used as the inferred type of a variable declaration,
  /// based on the static type of the initializer expression, given by
  /// [initializerType].
  DartType inferDeclarationType(DartType initializerType);

  /// Performs type inference on [expression].
  ExpressionInferenceResult inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false, bool forEffect: false});

  /// Performs type inference on the given function body.
  InferredFunctionBody inferFunctionBody(InferenceHelper helper, int fileOffset,
      DartType returnType, AsyncMarker asyncMarker, Statement body);

  /// Performs type inference on the given constructor initializer.
  InitializerInferenceResult inferInitializer(
      InferenceHelper helper, Initializer initializer);

  /// Performs type inference on the given metadata annotations.
  void inferMetadata(
      InferenceHelper helper, TreeNode? parent, List<Expression>? annotations);

  /// Performs type inference on the given metadata annotations keeping the
  /// existing helper if possible.
  void inferMetadataKeepingHelper(
      TreeNode parent, List<Expression> annotations);

  /// Performs type inference on the given function parameter initializer
  /// expression.
  Expression inferParameterInitializer(
      InferenceHelper helper,
      Expression initializer,
      DartType declaredType,
      bool hasDeclaredInitializer);

  /// Ensures that all parameter types of [constructor] have been inferred.
  // TODO(johnniwinther): We are still parameters on synthesized mixin
  //  application constructors.
  void inferConstructorParameterTypes(Constructor constructor);
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class TypeInferrerImpl implements TypeInferrer {
  /// Marker object to indicate that a function takes an unknown number
  /// of arguments.
  final FunctionType unknownFunction;

  final TypeInferenceEngine engine;

  @override
  late final FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration,
          DartType> flowAnalysis =
      library.isNonNullableByDefault
          ? new FlowAnalysis(
              new TypeOperationsCfe(engine.typeSchemaEnvironment),
              assignedVariables,
              respectImplicitlyTypedVarInitializers:
                  library.enableConstructorTearOffsInLibrary)
          : new FlowAnalysis.legacy(
              new TypeOperationsCfe(engine.typeSchemaEnvironment),
              assignedVariables);

  @override
  final AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;

  final InferenceDataForTesting? dataForTesting;

  @override
  final Uri uriForInstrumentation;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  final bool isTopLevel;

  final ClassHierarchy classHierarchy;

  final Instrumentation? instrumentation;

  @override
  final TypeSchemaEnvironment typeSchemaEnvironment;

  final InterfaceType? thisType;

  @override
  final SourceLibraryBuilder library;

  InferenceHelper? helper;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  ClosureContext? closureContext;

  TypeInferrerImpl(this.engine, this.uriForInstrumentation, bool topLevel,
      this.thisType, this.library, this.assignedVariables, this.dataForTesting)
      // ignore: unnecessary_null_comparison
      : assert(library != null),
        unknownFunction = new FunctionType(
            const [], const DynamicType(), library.nonNullable),
        classHierarchy = engine.classHierarchy,
        instrumentation = topLevel ? null : engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment,
        isTopLevel = topLevel {}

  CoreTypes get coreTypes => engine.coreTypes;

  bool get isNonNullableByDefault => library.isNonNullableByDefault;

  NnbdMode get nnbdMode => library.loader.nnbdMode;

  DartType get bottomType =>
      isNonNullableByDefault ? const NeverType.nonNullable() : const NullType();

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
    return type.withDeclaredNullability(library.nullable);
  }

  Expression createReachabilityError(
      int fileOffset, Message errorMessage, Message warningMessage) {
    if (library.loader.target.context.options.warnOnReachabilityCheck &&
        // ignore: unnecessary_null_comparison
        warningMessage != null) {
      helper?.addProblem(warningMessage, fileOffset, noLength);
    }
    Arguments arguments;
    // ignore: unnecessary_null_comparison
    if (errorMessage != null) {
      arguments = new Arguments([
        new StringLiteral(errorMessage.problemMessage)..fileOffset = fileOffset
      ])
        ..fileOffset = fileOffset;
    } else {
      arguments = new Arguments([])..fileOffset = fileOffset;
    }
    // ignore: unnecessary_null_comparison
    assert(coreTypes.reachabilityErrorConstructor != null);
    return new Throw(
        new ConstructorInvocation(
            coreTypes.reachabilityErrorConstructor, arguments)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
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
        LocatedMessage? message = entry.value.accept(whyNotPromotedVisitor);
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
        if (message != null) {
          context = [message];
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
    if (member is Constructor) {
      inferConstructorParameterTypes(member);
    }
    TypeDependency? typeDependency = engine.typeDependencies.remove(member);
    if (typeDependency != null) {
      ensureMemberType(typeDependency.original);
      typeDependency.copyInferred();
    }
  }

  @override
  void inferConstructorParameterTypes(Constructor target) {
    DeclaredSourceConstructorBuilder? constructor =
        engine.beingInferred[target];
    if (constructor != null) {
      // There is a cyclic dependency where inferring the types of the
      // initializing formals of a constructor required us to infer the
      // corresponding field type which required us to know the type of the
      // constructor.
      String name = target.enclosingClass.name;
      if (target.name.text.isNotEmpty) {
        // TODO(ahe): Use `inferrer.helper.constructorNameForDiagnostics`
        // instead. However, `inferrer.helper` may be null.
        name += ".${target.name.text}";
      }
      constructor.library.addProblem(
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
    } else if ((constructor = engine.toBeInferred[target]) != null) {
      engine.toBeInferred.remove(target);
      engine.beingInferred[target] = constructor!;
      constructor.inferFormalTypes(classHierarchy);
      engine.beingInferred.remove(target);
    }
  }

  @override
  InitializerInferenceResult inferInitializer(
      InferenceHelper helper, Initializer initializer) {
    this.helper = helper;
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    InitializerInferenceResult inferenceResult;
    if (initializer is InitializerJudgment) {
      inferenceResult = initializer.acceptInference(new InferenceVisitor(this));
    } else {
      inferenceResult = initializer.accept(new InferenceVisitor(this));
    }
    this.helper = null;
    return inferenceResult;
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
        typeContext.classNode == coreTypes.doubleClass;
  }

  bool isAssignable(DartType contextType, DartType expressionType) {
    if (isNonNullableByDefault) {
      if (expressionType is DynamicType) return true;
      return typeSchemaEnvironment
          .performNullabilityAwareSubtypeCheck(expressionType, contextType)
          .isSubtypeWhenUsingNullabilities();
    }
    return typeSchemaEnvironment
        .performNullabilityAwareSubtypeCheck(expressionType, contextType)
        .orSubtypeCheckFor(contextType, expressionType, typeSchemaEnvironment)
        .isSubtypeWhenIgnoringNullabilities();
  }

  Expression ensureAssignableResult(
      DartType expectedType, ExpressionInferenceResult result,
      {int? fileOffset,
      bool isVoidAllowed: false,
      Template<Message Function(DartType, DartType, bool)>? errorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityErrorTemplate,
      Template<Message Function(DartType, bool)>? nullabilityNullErrorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityNullTypeErrorTemplate,
      Template<Message Function(DartType, DartType, DartType, DartType, bool)>?
          nullabilityPartErrorTemplate}) {
    return ensureAssignable(
        expectedType, result.inferredType, result.expression,
        fileOffset: fileOffset,
        isVoidAllowed: isVoidAllowed,
        errorTemplate: errorTemplate,
        nullabilityErrorTemplate: nullabilityErrorTemplate,
        nullabilityNullErrorTemplate: nullabilityNullErrorTemplate,
        nullabilityNullTypeErrorTemplate: nullabilityNullTypeErrorTemplate,
        nullabilityPartErrorTemplate: nullabilityPartErrorTemplate);
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
      DartType contextType, DartType expressionType, Expression expression,
      {int? fileOffset,
      DartType? declaredContextType,
      DartType? runtimeCheckedType,
      bool isVoidAllowed: false,
      Template<Message Function(DartType, DartType, bool)>? errorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityErrorTemplate,
      Template<Message Function(DartType, bool)>? nullabilityNullErrorTemplate,
      Template<Message Function(DartType, DartType, bool)>?
          nullabilityNullTypeErrorTemplate,
      Template<Message Function(DartType, DartType, DartType, DartType, bool)>?
          nullabilityPartErrorTemplate,
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    // ignore: unnecessary_null_comparison
    assert(contextType != null);

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

    // We don't need to insert assignability checks when doing top level type
    // inference since top level type inference only cares about the type that
    // is inferred (the kernel code is discarded).
    if (isTopLevel) return expression;

    fileOffset ??= expression.fileOffset;
    contextType = computeGreatestClosure(contextType);

    DartType initialContextType = runtimeCheckedType ?? contextType;

    Template<Message Function(DartType, DartType, bool)>?
        preciseTypeErrorTemplate = _getPreciseTypeErrorTemplate(expression);
    AssignabilityResult assignabilityResult = _computeAssignabilityKind(
        contextType, expressionType,
        isNonNullableByDefault: isNonNullableByDefault,
        isVoidAllowed: isVoidAllowed,
        isExpressionTypePrecise: preciseTypeErrorTemplate != null);

    if (assignabilityResult.needsTearOff) {
      TypedTearoff typedTearoff =
          _tearOffCall(expression, expressionType as InterfaceType, fileOffset);
      expression = typedTearoff.tearoff;
      expressionType = typedTearoff.tearoffType;
    }
    if (assignabilityResult.implicitInstantiation != null) {
      ExpressionInferenceResult instantiationResult =
          _applyImplicitInstantiation(assignabilityResult.implicitInstantiation,
              expressionType, expression);
      expression = instantiationResult.expression;
      expressionType = instantiationResult.inferredType;
    }

    Expression result;
    switch (assignabilityResult.kind) {
      case AssignabilityKind.assignable:
        result = expression;
        break;
      case AssignabilityKind.assignableCast:
        // Insert an implicit downcast.
        result = new AsExpression(expression, initialContextType)
          ..isTypeError = true
          ..isForNonNullableByDefault = isNonNullableByDefault
          ..isForDynamic = expressionType is DynamicType
          ..fileOffset = fileOffset;
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
        result = helper!.wrapInProblem(
            expression, messageVoidExpression, expression.fileOffset, noLength);
        break;
      case AssignabilityKind.unassignablePrecise:
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        result = helper!.wrapInProblem(
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
            fileOffset, helper!.uri);
    }

    if (!identical(result, expression)) {
      flowAnalysis.forwardExpression(result, expression);
    }
    return result;
  }

  Expression _wrapTearoffErrorExpression(Expression expression,
      DartType contextType, Template<Message Function(String)> template) {
    // ignore: unnecessary_null_comparison
    assert(template != null);
    Expression errorNode = new AsExpression(
        expression,
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
      errorNode = helper!.wrapInProblem(
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
      errorNode = helper!.wrapInProblem(
          errorNode, message, errorNode.fileOffset, noLength,
          context: context);
    }
    return errorNode;
  }

  TypedTearoff _tearOffCall(
      Expression expression, InterfaceType expressionType, int fileOffset) {
    Class classNode = expressionType.classNode;
    Member callMember = classHierarchy.getInterfaceMember(classNode, callName)!;
    assert(callMember is Procedure && callMember.kind == ProcedureKind.Method);

    // Replace expression with:
    // `let t = expression in t == null ? null : t.call`
    VariableDeclaration t =
        new VariableDeclaration.forValue(expression, type: expressionType)
          ..fileOffset = fileOffset;

    // TODO(johnniwinther): Avoid null-check for non-nullable expressions.
    Expression nullCheck =
        new EqualsNull(new VariableGet(t)..fileOffset = fileOffset)
          ..fileOffset = fileOffset;

    DartType tearoffType =
        getGetterTypeForMemberTarget(callMember, expressionType)
            .withDeclaredNullability(expressionType.nullability);
    Expression tearOff = new InstanceTearOff(
        InstanceAccessKind.Instance, new VariableGet(t), callName,
        interfaceTarget: callMember as Procedure, resultType: tearoffType)
      ..fileOffset = fileOffset;
    ConditionalExpression conditional = new ConditionalExpression(nullCheck,
        new NullLiteral()..fileOffset = fileOffset, tearOff, tearoffType);
    return new TypedTearoff(
        tearoffType, new Let(t, conditional)..fileOffset = fileOffset);
  }

  /// Computes the assignability kind of [expressionType] to [contextType].
  ///
  /// The computation is side-effect free.
  AssignabilityResult _computeAssignabilityKind(
      DartType contextType, DartType expressionType,
      {required bool isNonNullableByDefault,
      required bool isVoidAllowed,
      required bool isExpressionTypePrecise}) {
    // ignore: unnecessary_null_comparison
    assert(isNonNullableByDefault != null);
    // ignore: unnecessary_null_comparison
    assert(isVoidAllowed != null);
    // ignore: unnecessary_null_comparison
    assert(isExpressionTypePrecise != null);

    // If an interface type is being assigned to a function type, see if we
    // should tear off `.call`.
    // TODO(paulberry): use resolveTypeParameter.  See findInterfaceMember.
    bool needsTearoff = false;
    if (expressionType is InterfaceType) {
      Class classNode = expressionType.classNode;
      Member? callMember =
          classHierarchy.getInterfaceMember(classNode, callName);
      if (callMember is Procedure && callMember.kind == ProcedureKind.Method) {
        if (_shouldTearOffCall(contextType, expressionType)) {
          needsTearoff = true;
          if (isNonNullableByDefault && expressionType.isPotentiallyNullable) {
            return const AssignabilityResult(
                AssignabilityKind.unassignableCantTearoff,
                needsTearOff: false);
          }
          expressionType =
              getGetterTypeForMemberTarget(callMember, expressionType)
                  .withDeclaredNullability(expressionType.nullability);
        }
      }
    }
    ImplicitInstantiation? implicitInstantiation;
    if (library.enableConstructorTearOffsInLibrary) {
      implicitInstantiation =
          computeImplicitInstantiation(expressionType, contextType);
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
    // Insert an implicit downcast.
    return new AssignabilityResult(AssignabilityKind.assignableCast,
        needsTearOff: needsTearoff,
        implicitInstantiation: implicitInstantiation);
  }

  bool isNull(DartType type) {
    return type is NullType;
  }

  /// Computes the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType]. If [explicitTypeArguments]
  /// are provided, these are returned, otherwise type arguments are inferred
  /// using [receiverType].
  List<DartType> computeExtensionTypeArgument(Extension extension,
      List<DartType>? explicitTypeArguments, DartType receiverType) {
    if (explicitTypeArguments != null) {
      assert(explicitTypeArguments.length == extension.typeParameters.length);
      return explicitTypeArguments;
    } else if (extension.typeParameters.isEmpty) {
      assert(explicitTypeArguments == null);
      return const <DartType>[];
    } else {
      return inferExtensionTypeArguments(extension, receiverType);
    }
  }

  /// Infers the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType].
  List<DartType> inferExtensionTypeArguments(
      Extension extension, DartType receiverType) {
    List<TypeParameter> typeParameters = extension.typeParameters;
    DartType onType = extension.onType;
    List<DartType> inferredTypes =
        new List<DartType>.filled(typeParameters.length, const UnknownType());
    typeSchemaEnvironment.inferGenericFunctionOrType(null, typeParameters,
        [onType], [receiverType], null, inferredTypes, library.library);
    return inferredTypes;
  }

  ObjectAccessTarget _findShownExtensionTypeMember(
      ExtensionType receiverType, Name name, int fileOffset,
      {required ObjectAccessTarget defaultTarget,
      required CallSiteAccessKind callSiteAccessKind,
      required bool isPotentiallyNullable}) {
    Extension extension = receiverType.extension;
    ExtensionTypeShowHideClause? showHideClause = extension.showHideClause;
    if (showHideClause == null) return defaultTarget;

    kernel.Reference? reference = showHideClause.findShownReference(
        name, callSiteAccessKind, classHierarchy);
    if (reference != null) {
      return new ObjectAccessTarget.interfaceMember(reference.asMember,
          isPotentiallyNullable: isPotentiallyNullable);
    } else {
      return defaultTarget;
    }
  }

  /// Returns extension member declared immediately for [receiverType].
  ///
  /// If none is found, [defaultTarget] is returned.
  ObjectAccessTarget _findDirectExtensionTypeMember(
      ExtensionType receiverType, Name name, int fileOffset,
      {required ObjectAccessTarget defaultTarget, required bool isSetter}) {
    Member? targetMember;
    Member? targetTearoff;
    ProcedureKind? targetKind;
    for (ExtensionMemberDescriptor descriptor
        in receiverType.extension.members) {
      if (descriptor.name == name) {
        switch (descriptor.kind) {
          case ExtensionMemberKind.Method:
            if (!isSetter) {
              targetMember = descriptor.member.asMember;
              targetTearoff ??= targetMember;
              targetKind = ProcedureKind.Method;
            }
            break;
          case ExtensionMemberKind.TearOff:
            if (!isSetter) {
              targetTearoff = descriptor.member.asMember;
            }
            break;
          case ExtensionMemberKind.Getter:
            if (!isSetter) {
              targetMember = descriptor.member.asMember;
              targetTearoff = null;
              targetKind = ProcedureKind.Getter;
            }
            break;
          case ExtensionMemberKind.Setter:
            if (isSetter) {
              targetMember = descriptor.member.asMember;
              targetTearoff = null;
              targetKind = ProcedureKind.Setter;
            }
            break;
          case ExtensionMemberKind.Operator:
            if (!isSetter) {
              targetMember = descriptor.member.asMember;
              targetTearoff = null;
              targetKind = ProcedureKind.Operator;
            }
            break;
          default:
            unhandled("${descriptor.kind}", "_findDirectExtensionMember",
                fileOffset, library.fileUri);
        }
      }
    }
    if (targetMember != null) {
      assert(targetKind != null);
      return new ObjectAccessTarget.extensionMember(
          targetMember, targetTearoff, targetKind!, receiverType.typeArguments);
    } else {
      return defaultTarget;
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
      DartType receiverType, Class classNode, Name name, int fileOffset,
      {bool setter: false,
      ObjectAccessTarget? defaultTarget,
      bool isPotentiallyNullableAccess: false}) {
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
      otherIsSetter = !setter;
    }

    Member? otherMember =
        _getInterfaceMember(classNode, otherName, otherIsSetter, fileOffset);
    if (otherMember != null) {
      // If we're looking for `foo` and `foo=` can be found or vice-versa then
      // extension methods should not be found.
      return defaultTarget;
    }

    ExtensionAccessCandidate? bestSoFar;
    List<ExtensionAccessCandidate> noneMoreSpecific = [];
    library.forEachExtensionInScope((ExtensionBuilder extensionBuilder) {
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
              extensionBuilder.extension, receiverType);
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
              typeParameters, coreTypes.objectClass, library.library);
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
                    setter ? thisBuilder.writeTarget! : thisBuilder.readTarget!,
                    thisBuilder.readTarget,
                    setter ? ProcedureKind.Setter : ProcedureKind.Getter,
                    inferredTypeArguments,
                    isPotentiallyNullable: isPotentiallyNullableAccess);
              }
            } else {
              target = new ObjectAccessTarget.extensionMember(
                  setter ? thisBuilder.writeTarget! : thisBuilder.invokeTarget!,
                  thisBuilder.readTarget,
                  thisBuilder.kind!,
                  inferredTypeArguments,
                  isPotentiallyNullable: isPotentiallyNullableAccess);
            }
          }
          ExtensionAccessCandidate candidate = new ExtensionAccessCandidate(
              (thisBuilder ?? otherBuilder)!,
              onType,
              onTypeInstantiateToBounds,
              target,
              isPlatform: extensionBuilder.library.importUri.isScheme('dart'));
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
        return new AmbiguousExtensionAccessTarget(noneMoreSpecific);
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
      {required CallSiteAccessKind callSiteAccessKind,
      bool instrumented: true,
      bool includeExtensionMethods: false}) {
    // ignore: unnecessary_null_comparison
    assert(receiverType != null && isKnown(receiverType));

    bool isSetter = callSiteAccessKind == CallSiteAccessKind.setterInvocation;

    DartType receiverBound = resolveTypeParameter(receiverType);

    bool isReceiverTypePotentiallyNullable = isNonNullableByDefault &&
        receiverType.isPotentiallyNullable &&
        // Calls to `==` are always on a non-null receiver.
        name != equalsName;

    Class classNode = receiverBound is InterfaceType
        ? receiverBound.classNode
        : coreTypes.objectClass;

    if (isReceiverTypePotentiallyNullable) {
      Member? member = _getInterfaceMember(
          coreTypes.objectClass, name, isSetter, fileOffset);
      if (member != null) {
        // Null implements all Object members so this is not considered a
        // potentially nullable access.
        return new ObjectAccessTarget.objectMember(member);
      }
      if (includeExtensionMethods && receiverBound is! DynamicType) {
        ObjectAccessTarget? target = _findExtensionMember(
            isNonNullableByDefault ? receiverType : receiverBound,
            coreTypes.objectClass,
            name,
            fileOffset,
            setter: isSetter);
        if (target != null) {
          return target;
        }
      }
    }

    if (receiverBound is FunctionType && name == callName) {
      return isReceiverTypePotentiallyNullable
          ? const ObjectAccessTarget.nullableCallFunction()
          : const ObjectAccessTarget.callFunction();
    } else if (receiverBound is NeverType) {
      switch (receiverBound.nullability) {
        case Nullability.nonNullable:
          return const ObjectAccessTarget.never();
        case Nullability.nullable:
        case Nullability.legacy:
          // Never? and Never* are equivalent to Null.
          return findInterfaceMember(const NullType(), name, fileOffset,
              callSiteAccessKind: callSiteAccessKind);
        case Nullability.undetermined:
          return internalProblem(
              templateInternalProblemUnsupportedNullability.withArguments(
                  "${receiverBound.nullability}",
                  receiverBound,
                  isNonNullableByDefault),
              fileOffset,
              library.fileUri);
      }
    }

    ObjectAccessTarget? target;
    Member? interfaceMember =
        _getInterfaceMember(classNode, name, isSetter, fileOffset);
    if (interfaceMember != null) {
      target = new ObjectAccessTarget.interfaceMember(interfaceMember,
          isPotentiallyNullable: isReceiverTypePotentiallyNullable);
    } else if (receiverBound is DynamicType) {
      target = const ObjectAccessTarget.dynamic();
    } else if (receiverBound is InvalidType) {
      target = const ObjectAccessTarget.invalid();
    } else if (receiverBound is InterfaceType &&
        receiverBound.classNode == coreTypes.functionClass &&
        name == callName) {
      target = isReceiverTypePotentiallyNullable
          ? const ObjectAccessTarget.nullableCallFunction()
          : const ObjectAccessTarget.callFunction();
    } else if (library.enableExtensionTypesInLibrary &&
        receiverBound is ExtensionType) {
      target = _findDirectExtensionTypeMember(receiverBound, name, fileOffset,
          isSetter: isSetter,
          defaultTarget: const ObjectAccessTarget.missing());
      if (target.kind == ObjectAccessTargetKind.missing) {
        target = _findShownExtensionTypeMember(receiverBound, name, fileOffset,
            callSiteAccessKind: callSiteAccessKind,
            isPotentiallyNullable: isReceiverTypePotentiallyNullable,
            defaultTarget: const ObjectAccessTarget.missing());
      }
    } else {
      target = const ObjectAccessTarget.missing();
    }
    if (instrumented &&
        receiverBound != const DynamicType() &&
        (target.isInstanceMember || target.isObjectMember)) {
      instrumentation?.record(uriForInstrumentation, fileOffset, 'target',
          new InstrumentationValueForMember(target.member!));
    }

    if (target.isMissing && includeExtensionMethods) {
      if (isReceiverTypePotentiallyNullable) {
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
            fileOffset,
            setter: isSetter,
            defaultTarget: target,
            isPotentiallyNullableAccess: true)!;
      } else {
        target = _findExtensionMember(
            isNonNullableByDefault ? receiverType : receiverBound,
            classNode,
            name,
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
    // ignore: unnecessary_null_comparison
    assert(receiverType != null && isKnown(receiverType));
    // ignore: unnecessary_null_comparison
    if (!isTopLevel && target.isMissing && errorTemplate != null) {
      int length = name.text.length;
      if (identical(name.text, callName.text) ||
          identical(name.text, unaryMinusName.text)) {
        length = 1;
      }
      return helper!.buildProblem(
          errorTemplate.withArguments(name.text,
              resolveTypeParameter(receiverType), isNonNullableByDefault),
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

  /// Returns the type of [target] when accessed as a getter on [receiverType].
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
  DartType getGetterType(ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        return receiverType;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        return const DynamicType();
      case ObjectAccessTargetKind.never:
        return const NeverType.nonNullable();
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        return getGetterTypeForMemberTarget(target.member!, receiverType);
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(target.inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, target.inferredExtensionTypeArguments);
            DartType resultType = substitution.substituteType(new FunctionType(
                functionType.positionalParameters.skip(1).toList(),
                functionType.returnType,
                library.nonNullable,
                namedParameters: functionType.namedParameters,
                typeParameters: functionType.typeParameters
                    .skip(target.inferredExtensionTypeArguments.length)
                    .toList(),
                requiredParameterCount:
                    functionType.requiredParameterCount - 1));
            if (!isNonNullableByDefault) {
              resultType = legacyErasure(resultType);
            }
            return resultType;
          case ProcedureKind.Getter:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(target.inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, target.inferredExtensionTypeArguments);
            DartType resultType =
                substitution.substituteType(functionType.returnType);
            if (!isNonNullableByDefault) {
              resultType = legacyErasure(resultType);
            }
            return resultType;
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
            break;
        }
    }
    throw unhandled('$target', 'getGetterType', -1, null);
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
      Member interfaceMember, DartType receiverType) {
    Class memberClass = interfaceMember.enclosingClass!;
    assert(interfaceMember is Field || interfaceMember is Procedure,
        "Unexpected interface member $interfaceMember.");
    DartType calleeType = interfaceMember.getterType;
    if (memberClass.typeParameters.isNotEmpty) {
      receiverType = resolveTypeParameter(receiverType);
      if (receiverType is InterfaceType) {
        List<DartType> castedTypeArguments = classHierarchy
            .getTypeArgumentsAsInstanceOf(receiverType, memberClass)!;
        calleeType = Substitution.fromPairs(
                memberClass.typeParameters, castedTypeArguments)
            .substituteType(calleeType);
      }
    }
    if (!isNonNullableByDefault) {
      calleeType = legacyErasure(calleeType);
    }
    return calleeType;
  }

  /// Returns the type of [target] when accessed as an invocation on
  /// [receiverType].
  ///
  /// If the target is known not to be invokable [unknownFunction] is returned.
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      T method() {}
  ///      T Function() getter1 => null;
  ///      T getter2 => null;
  ///    }
  ///
  ///    Class<int> c = ...
  ///    c.method; // The getter type is `int Function()`.
  ///    c.getter1; // The getter type is `int Function()`.
  ///    c.getter2; // The getter type is [unknownFunction].
  ///
  FunctionType getFunctionType(
      ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        return _getFunctionType(receiverType);
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        return unknownFunction;
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        return _getFunctionType(
            getGetterTypeForMemberTarget(target.member!, receiverType));
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            if (!isNonNullableByDefault) {
              functionType = legacyErasure(functionType) as FunctionType;
            }
            return functionType;
          case ProcedureKind.Getter:
            // TODO(johnniwinther): Handle implicit .call on extension getter.
            return _getFunctionType(target.member!.function!.returnType);
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
            break;
        }
    }
    throw unhandled('$target', 'getFunctionType', -1, null);
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

  /// Returns the return type of the invocation of [target] on [receiverType].
  // TODO(johnniwinther): Cleanup [getFunctionType], [getReturnType],
  // [getIndexKeyType] and [getIndexSetValueType]. We shouldn't need that many.
  DartType getReturnType(ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member!, receiverType));
        return functionType.returnType;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            DartType returnType = functionType.returnType;
            if (functionType.typeParameters.isNotEmpty) {
              Substitution substitution = Substitution.fromPairs(
                  functionType.typeParameters,
                  target.inferredExtensionTypeArguments);
              returnType = substitution.substituteType(returnType);
            }
            if (!isNonNullableByDefault) {
              returnType = legacyErasure(returnType);
            }
            return returnType;
          default:
            throw unhandled('$target', 'getFunctionType', -1, null);
        }
      case ObjectAccessTargetKind.never:
        return const NeverType.nonNullable();
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  DartType getPositionalParameterTypeForTarget(
      ObjectAccessTarget target, DartType receiverType, int index) {
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member!, receiverType));
        if (functionType.positionalParameters.length > index) {
          return functionType.positionalParameters[index];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        FunctionType functionType =
            target.member!.function!.computeFunctionType(library.nonNullable);
        if (functionType.positionalParameters.length > index + 1) {
          DartType keyType = functionType.positionalParameters[index + 1];
          if (functionType.typeParameters.isNotEmpty) {
            Substitution substitution = Substitution.fromPairs(
                functionType.typeParameters,
                target.inferredExtensionTypeArguments);
            keyType = substitution.substituteType(keyType);
          }
          if (!isNonNullableByDefault) {
            keyType = legacyErasure(keyType);
          }
          return keyType;
        }
        break;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  /// Returns the type of the 'key' parameter in an [] or []= implementation.
  ///
  /// For instance
  ///
  ///    class Class<K, V> {
  ///      V operator [](K key) => null;
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    extension Extension<K, V> on Class<K, V> {
  ///      V operator [](K key) => null;
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    new Class<int, String>()[0];             // The key type is `int`.
  ///    new Class<int, String>()[0] = 'foo';     // The key type is `int`.
  ///    Extension<int, String>(null)[0];         // The key type is `int`.
  ///    Extension<int, String>(null)[0] = 'foo'; // The key type is `int`.
  ///
  DartType getIndexKeyType(ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member!, receiverType));
        if (functionType.positionalParameters.length >= 1) {
          return functionType.positionalParameters[0];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            if (functionType.positionalParameters.length >= 2) {
              DartType keyType = functionType.positionalParameters[1];
              if (functionType.typeParameters.isNotEmpty) {
                Substitution substitution = Substitution.fromPairs(
                    functionType.typeParameters,
                    target.inferredExtensionTypeArguments);
                keyType = substitution.substituteType(keyType);
              }
              if (!isNonNullableByDefault) {
                keyType = legacyErasure(keyType);
              }
              return keyType;
            }
            break;
          default:
            throw unhandled('$target', 'getFunctionType', -1, null);
        }
        break;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  /// Returns the type of the 'value' parameter in an []= implementation.
  ///
  /// For instance
  ///
  ///    class Class<K, V> {
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    extension Extension<K, V> on Class<K, V> {
  ///      void operator []=(K key, V value) {}
  ///    }
  ///
  ///    new Class<int, String>()[0] = 'foo';     // The value type is `String`.
  ///    Extension<int, String>(null)[0] = 'foo'; // The value type is `String`.
  ///
  DartType getIndexSetValueType(
      ObjectAccessTarget target, DartType? receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member!, receiverType!));
        if (functionType.positionalParameters.length >= 2) {
          return functionType.positionalParameters[1];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            if (functionType.positionalParameters.length >= 3) {
              DartType indexType = functionType.positionalParameters[2];
              if (functionType.typeParameters.isNotEmpty) {
                Substitution substitution = Substitution.fromPairs(
                    functionType.typeParameters,
                    target.inferredExtensionTypeArguments);
                indexType = substitution.substituteType(indexType);
              }
              if (!isNonNullableByDefault) {
                indexType = legacyErasure(indexType);
              }
              return indexType;
            }
            break;
          default:
            throw unhandled('$target', 'getFunctionType', -1, null);
        }
        break;
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        break;
    }
    return const DynamicType();
  }

  FunctionType _getFunctionType(DartType calleeType) {
    calleeType = resolveTypeParameter(calleeType);
    if (calleeType is FunctionType) {
      if (!isNonNullableByDefault) {
        calleeType = legacyErasure(calleeType);
      }
      return calleeType as FunctionType;
    }
    return unknownFunction;
  }

  FunctionType getFunctionTypeForImplicitCall(DartType calleeType) {
    calleeType = resolveTypeParameter(calleeType);
    if (calleeType is FunctionType) {
      if (!isNonNullableByDefault) {
        calleeType = legacyErasure(calleeType);
      }
      return calleeType as FunctionType;
    } else if (calleeType is InterfaceType) {
      Member? member =
          _getInterfaceMember(calleeType.classNode, callName, false, -1);
      if (member != null) {
        DartType callType = getGetterTypeForMemberTarget(member, calleeType);
        if (callType is FunctionType) {
          if (!isNonNullableByDefault) {
            callType = legacyErasure(callType);
          }
          return callType as FunctionType;
        }
      }
    }
    return unknownFunction;
  }

  DartType? getDerivedTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType) {
      List<DartType>? typeArgumentsAsInstanceOfClass =
          classHierarchy.getTypeArgumentsAsInstanceOf(type, class_);
      if (typeArgumentsAsInstanceOfClass != null) {
        return typeArgumentsAsInstanceOfClass[0];
      }
    }
    return null;
  }

  /// If the [member] is a forwarding stub, return the target it forwards to.
  /// Otherwise return the given [member].
  Member getRealTarget(Member member) {
    if (member is Procedure && member.isForwardingStub) {
      return member.abstractForwardingStubTarget!;
    }
    return member;
  }

  DartType getSetterType(ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.never:
      case ObjectAccessTargetKind.missing:
      case ObjectAccessTargetKind.ambiguous:
        return const DynamicType();
      case ObjectAccessTargetKind.invalid:
        return const InvalidType();
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        Member interfaceMember = target.member!;
        Class memberClass = interfaceMember.enclosingClass!;
        DartType setterType;
        if (interfaceMember is Procedure) {
          assert(interfaceMember.kind == ProcedureKind.Setter);
          List<VariableDeclaration> setterParameters =
              interfaceMember.function.positionalParameters;
          setterType = setterParameters.length > 0
              ? setterParameters[0].type
              : const DynamicType();
        } else if (interfaceMember is Field) {
          setterType = interfaceMember.type;
        } else {
          throw unhandled(interfaceMember.runtimeType.toString(),
              'getSetterType', -1, null);
        }
        if (memberClass.typeParameters.isNotEmpty) {
          receiverType = resolveTypeParameter(receiverType);
          if (receiverType is InterfaceType) {
            setterType = Substitution.fromPairs(
                    memberClass.typeParameters,
                    classHierarchy.getTypeArgumentsAsInstanceOf(
                        receiverType, memberClass)!)
                .substituteType(setterType);
          }
        }
        if (!isNonNullableByDefault) {
          setterType = legacyErasure(setterType);
        }
        return setterType;
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Setter:
            FunctionType functionType = target.member!.function!
                .computeFunctionType(library.nonNullable);
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(target.inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, target.inferredExtensionTypeArguments);
            DartType setterType = substitution
                .substituteType(functionType.positionalParameters[1]);
            if (!isNonNullableByDefault) {
              setterType = legacyErasure(setterType);
            }
            return setterType;
          case ProcedureKind.Method:
          case ProcedureKind.Getter:
          case ProcedureKind.Factory:
          case ProcedureKind.Operator:
            break;
        }
        // TODO(johnniwinther): Compute the right setter type.
        return const DynamicType();
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.nullableCallFunction:
        break;
    }
    throw unhandled(target.runtimeType.toString(), 'getSetterType', -1, null);
  }

  DartType getTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType && identical(type.classNode, class_)) {
      return type.typeArguments[0];
    } else {
      return const UnknownType();
    }
  }

  /// Modifies a type as appropriate when inferring a declared variable's type.
  @override
  DartType inferDeclarationType(DartType initializerType,
      {bool forSyntheticVariable: false}) {
    if (initializerType is NullType) {
      // If the initializer type is Null or bottom, the inferred type is
      // dynamic.
      // TODO(paulberry): this rule is inherited from analyzer behavior but is
      // not spec'ed anywhere.
      return const DynamicType();
    }
    if (forSyntheticVariable) {
      return normalizeNullabilityInLibrary(initializerType, library.library);
    } else {
      return demoteTypeInLibrary(initializerType, library.library);
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
        helper!.wrapInProblem(
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

  /// Performs type inference on the given [expression].
  ///
  /// [typeContext] is the expected type of the expression, based on surrounding
  /// code.  [typeNeeded] indicates whether it is necessary to compute the
  /// actual type of the expression.  If [typeNeeded] is `true`,
  /// [ExpressionInferenceResult.inferredType] is the actual type of the
  /// expression; otherwise `null`.
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the expression type and calls the appropriate specialized "infer" method.
  ExpressionInferenceResult _inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false, bool forEffect: false}) {
    registerIfUnreachableForTesting(expression);

    // `null` should never be used as the type context.  An instance of
    // `UnknownType` should be used instead.
    // ignore: unnecessary_null_comparison
    assert(typeContext != null);

    // For full (non-top level) inference, we need access to the
    // ExpressionGeneratorHelper so that we can perform error recovery.
    assert(isTopLevel || helper != null);

    // When doing top level inference, we skip subexpressions whose type isn't
    // needed so that we don't induce bogus dependencies on fields mentioned in
    // those subexpressions.
    if (!typeNeeded) {
      return new ExpressionInferenceResult(const UnknownType(), expression);
    }

    InferenceVisitor visitor = new InferenceVisitor(this);
    ExpressionInferenceResult result;
    if (expression is ExpressionJudgment) {
      result = expression.acceptInference(visitor, typeContext);
    } else if (expression is InternalExpression) {
      result = expression.acceptInference(visitor, typeContext);
    } else {
      result = expression.accept1(visitor, typeContext);
    }
    DartType inferredType = result.inferredType;
    // ignore: unnecessary_null_comparison
    assert(inferredType != null,
        "No type inferred for $expression (${expression.runtimeType}).");
    if (inferredType is VoidType && !isVoidAllowed) {
      if (expression.parent is! ArgumentsImpl) {
        helper?.addProblem(
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

  @override
  ExpressionInferenceResult inferFieldInitializer(
    InferenceHelper helper,
    DartType context,
    Expression initializer,
  ) {
    assert(closureContext == null);
    assert(!isTopLevel);
    this.helper = helper;
    ExpressionInferenceResult initializerResult =
        inferExpression(initializer, context, true, isVoidAllowed: true);
    initializer = ensureAssignableResult(context, initializerResult,
        isVoidAllowed: context is VoidType);
    this.helper = null;
    return new ExpressionInferenceResult(
        initializerResult.inferredType, initializer);
  }

  @override
  InferredFunctionBody inferFunctionBody(InferenceHelper helper, int fileOffset,
      DartType returnType, AsyncMarker asyncMarker, Statement body) {
    // ignore: unnecessary_null_comparison
    assert(body != null);
    // ignore: unnecessary_null_comparison
    assert(closureContext == null);
    this.helper = helper;
    closureContext = new ClosureContext(this, asyncMarker, returnType, false);
    StatementInferenceResult result = inferStatement(body);
    if (dataForTesting != null) {
      if (!flowAnalysis.isReachable) {
        dataForTesting!.flowAnalysisResult.functionBodiesThatDontComplete
            .add(body);
      }
    }
    result =
        closureContext!.handleImplicitReturn(this, body, result, fileOffset);
    DartType? futureValueType = closureContext!.futureValueType;
    assert(
        !(isNonNullableByDefault &&
            asyncMarker == AsyncMarker.Async &&
            futureValueType == null),
        "No future value type computed.");
    closureContext = null;
    this.helper = null;
    flowAnalysis.finish();
    return new InferredFunctionBody(
        result.hasChanged ? result.statement : body, futureValueType);
  }

  InvocationInferenceResult inferInvocation(DartType typeContext, int offset,
      FunctionType calleeType, ArgumentsImpl arguments,
      {List<VariableDeclaration>? hoistedExpressions,
      bool isSpecialCasedBinaryOperator: false,
      bool isSpecialCasedTernaryOperator: false,
      DartType? receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false,
      bool isImplicitExtensionMember: false,
      bool isImplicitCall: false,
      Member? staticTarget,
      bool isExtensionMemberInvocation = false}) {
    int extensionTypeParameterCount = getExtensionTypeParameterCount(arguments);
    if (extensionTypeParameterCount != 0) {
      return _inferGenericExtensionMethodInvocation(extensionTypeParameterCount,
          typeContext, offset, calleeType, arguments, hoistedExpressions,
          isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
          isSpecialCasedTernaryOperator: isSpecialCasedTernaryOperator,
          receiverType: receiverType,
          skipTypeArgumentInference: skipTypeArgumentInference,
          isConst: isConst,
          isImplicitExtensionMember: isImplicitExtensionMember);
    }
    return _inferInvocation(
        typeContext, offset, calleeType, arguments, hoistedExpressions,
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
      int extensionTypeParameterCount,
      DartType typeContext,
      int offset,
      FunctionType calleeType,
      Arguments arguments,
      List<VariableDeclaration>? hoistedExpressions,
      {bool isSpecialCasedBinaryOperator: false,
      bool isSpecialCasedTernaryOperator: false,
      DartType? receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false,
      bool isImplicitExtensionMember: false,
      bool isImplicitCall: false,
      Member? staticTarget}) {
    FunctionType extensionFunctionType = new FunctionType(
        [calleeType.positionalParameters.first],
        const DynamicType(),
        library.nonNullable,
        requiredParameterCount: 1,
        typeParameters: calleeType.typeParameters
            .take(extensionTypeParameterCount)
            .toList());
    ArgumentsImpl extensionArguments = engine.forest.createArguments(
        arguments.fileOffset, [arguments.positional.first],
        types: getExplicitExtensionTypeArguments(arguments));
    _inferInvocation(const UnknownType(), offset, extensionFunctionType,
        extensionArguments, hoistedExpressions,
        skipTypeArgumentInference: skipTypeArgumentInference,
        receiverType: receiverType,
        isImplicitExtensionMember: isImplicitExtensionMember,
        isImplicitCall: isImplicitCall,
        staticTarget: staticTarget,
        isExtensionMemberInvocation: true);
    Substitution extensionSubstitution = Substitution.fromPairs(
        extensionFunctionType.typeParameters, extensionArguments.types);

    List<TypeParameter> targetTypeParameters = const <TypeParameter>[];
    if (calleeType.typeParameters.length > extensionTypeParameterCount) {
      targetTypeParameters =
          calleeType.typeParameters.skip(extensionTypeParameterCount).toList();
    }
    FunctionType targetFunctionType = new FunctionType(
        calleeType.positionalParameters.skip(1).toList(),
        calleeType.returnType,
        library.nonNullable,
        requiredParameterCount: calleeType.requiredParameterCount - 1,
        namedParameters: calleeType.namedParameters,
        typeParameters: targetTypeParameters);
    targetFunctionType = extensionSubstitution
        .substituteType(targetFunctionType) as FunctionType;
    ArgumentsImpl targetArguments = engine.forest.createArguments(
        arguments.fileOffset, arguments.positional.skip(1).toList(),
        named: arguments.named, types: getExplicitTypeArguments(arguments));
    InvocationInferenceResult result = _inferInvocation(typeContext, offset,
        targetFunctionType, targetArguments, hoistedExpressions,
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
      DartType typeContext,
      int offset,
      FunctionType calleeType,
      ArgumentsImpl arguments,
      List<VariableDeclaration>? hoistedExpressions,
      {bool isSpecialCasedBinaryOperator: false,
      bool isSpecialCasedTernaryOperator: false,
      DartType? receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false,
      bool isImplicitExtensionMember: false,
      required bool isImplicitCall,
      Member? staticTarget,
      bool isExtensionMemberInvocation: false}) {
    // [receiverType] must be provided for special-cased operators.
    assert(!isSpecialCasedBinaryOperator && !isSpecialCasedTernaryOperator ||
        receiverType != null);

    List<TypeParameter> calleeTypeParameters = calleeType.typeParameters;
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
      FreshTypeParameters fresh = getFreshTypeParameters(calleeTypeParameters);
      calleeType = fresh.applyToFunctionType(calleeType);
      calleeTypeParameters = fresh.freshTypeParameters;
    }

    List<DartType>? explicitTypeArguments = getExplicitTypeArguments(arguments);

    bool inferenceNeeded = !skipTypeArgumentInference &&
        explicitTypeArguments == null &&
        calleeTypeParameters.isNotEmpty;
    bool typeChecksNeeded = !isTopLevel;

    List<DartType>? inferredTypes;
    Substitution? substitution;
    List<DartType>? formalTypes;
    List<DartType>? actualTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }

    List<VariableDeclaration>? localHoistedExpressions;
    if (library.enableNamedArgumentsAnywhereInLibrary &&
        arguments.argumentsOriginalOrder != null &&
        hoistedExpressions == null &&
        !isTopLevel) {
      hoistedExpressions = localHoistedExpressions = <VariableDeclaration>[];
    }

    if (inferenceNeeded) {
      // ignore: unnecessary_null_comparison
      if (isConst && typeContext != null) {
        typeContext = new TypeVariableEliminator(
                bottomType,
                isNonNullableByDefault
                    ? coreTypes.objectNullableRawType
                    : coreTypes.objectLegacyRawType)
            .substituteType(typeContext);
      }
      inferredTypes = new List<DartType>.filled(
          calleeTypeParameters.length, const UnknownType());
      typeSchemaEnvironment.inferGenericFunctionOrType(
          isNonNullableByDefault
              ? calleeType.returnType
              : legacyErasure(calleeType.returnType),
          calleeTypeParameters,
          null,
          null,
          typeContext,
          inferredTypes,
          library.library);
      substitution =
          Substitution.fromPairs(calleeTypeParameters, inferredTypes);
    } else if (explicitTypeArguments != null &&
        calleeTypeParameters.length == explicitTypeArguments.length) {
      substitution =
          Substitution.fromPairs(calleeTypeParameters, explicitTypeArguments);
    } else if (calleeTypeParameters.length != 0) {
      substitution = Substitution.fromPairs(
          calleeTypeParameters,
          new List<DartType>.filled(
              calleeTypeParameters.length, const DynamicType()));
    }
    bool isIdentical =
        staticTarget == typeSchemaEnvironment.coreTypes.identicalProcedure;
    // TODO(paulberry): if we are doing top level inference and type arguments
    // were omitted, report an error.
    List<Object?> argumentsEvaluationOrder;
    if (library.enableNamedArgumentsAnywhereInLibrary &&
        arguments.argumentsOriginalOrder != null) {
      if (staticTarget?.isExtensionMember ?? false) {
        // Add the receiver.
        argumentsEvaluationOrder = <Object?>[
          arguments.positional[0],
          ...arguments.argumentsOriginalOrder!
        ];
      } else {
        argumentsEvaluationOrder = arguments.argumentsOriginalOrder!;
      }
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
    if (library.enableNamedArgumentsAnywhereInLibrary) {
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

    int positionalIndex = 0;
    int namedIndex = 0;
    for (int evaluationOrderIndex = 0;
        evaluationOrderIndex < argumentsEvaluationOrder.length;
        evaluationOrderIndex++) {
      Object? argument = argumentsEvaluationOrder[evaluationOrderIndex];
      assert(
          argument is Expression || argument is NamedExpression,
          "Expected the argument to be either an Expression "
          "or a NamedExpression, got '${argument.runtimeType}'.");
      if (argument is Expression) {
        int index = positionalIndex++;
        DartType formalType = getPositionalParameterType(calleeType, index);
        DartType inferredFormalType = substitution != null
            ? substitution.substituteType(formalType)
            : formalType;
        DartType inferredType;
        if (isImplicitExtensionMember && index == 0) {
          assert(
              receiverType != null,
              "No receiver type provided for implicit extension member "
              "invocation.");
          continue;
        } else {
          if (isSpecialCasedBinaryOperator) {
            inferredFormalType = typeSchemaEnvironment
                .getContextTypeOfSpecialCasedBinaryOperator(
                    typeContext, receiverType!, inferredFormalType,
                    isNonNullableByDefault: isNonNullableByDefault);
          } else if (isSpecialCasedTernaryOperator) {
            inferredFormalType = typeSchemaEnvironment
                .getContextTypeOfSpecialCasedTernaryOperator(
                    typeContext, receiverType!, inferredFormalType,
                    isNonNullableByDefault: isNonNullableByDefault);
          }
          ExpressionInferenceResult result = inferExpression(
              arguments.positional[index],
              isNonNullableByDefault
                  ? inferredFormalType
                  : legacyErasure(inferredFormalType),
              inferenceNeeded ||
                  isSpecialCasedBinaryOperator ||
                  isSpecialCasedTernaryOperator ||
                  typeChecksNeeded);
          inferredType = identical(result.inferredType, noInferredType) ||
                  isNonNullableByDefault
              ? result.inferredType
              : legacyErasure(result.inferredType);
          if (localHoistedExpressions != null &&
              evaluationOrderIndex >= hoistingEndIndex) {
            hoistedExpressions = null;
          }
          Expression expression =
              _hoist(result.expression, inferredType, hoistedExpressions);
          if (isIdentical && arguments.positional.length == 2) {
            if (index == 0) {
              flowAnalysis.equalityOp_rightBegin(expression, inferredType);
            } else {
              flowAnalysis.equalityOp_end(
                  arguments.parent as Expression, expression, inferredType);
            }
          }
          arguments.positional[index] = expression..parent = arguments;
        }
        if (inferenceNeeded || typeChecksNeeded) {
          formalTypes!.add(formalType);
          actualTypes!.add(inferredType);
        }
      } else {
        assert(argument is NamedExpression);
        int index = namedIndex++;
        NamedExpression namedArgument = arguments.named[index];
        DartType formalType =
            getNamedParameterType(calleeType, namedArgument.name);
        DartType inferredFormalType = substitution != null
            ? substitution.substituteType(formalType)
            : formalType;
        ExpressionInferenceResult result = inferExpression(
            namedArgument.value,
            isNonNullableByDefault
                ? inferredFormalType
                : legacyErasure(inferredFormalType),
            inferenceNeeded ||
                isSpecialCasedBinaryOperator ||
                typeChecksNeeded);
        DartType inferredType =
            identical(result.inferredType, noInferredType) ||
                    isNonNullableByDefault
                ? result.inferredType
                : legacyErasure(result.inferredType);
        if (localHoistedExpressions != null &&
            evaluationOrderIndex >= hoistingEndIndex) {
          hoistedExpressions = null;
        }
        Expression expression =
            _hoist(result.expression, inferredType, hoistedExpressions);
        namedArgument.value = expression..parent = namedArgument;
        if (inferenceNeeded || typeChecksNeeded) {
          formalTypes!.add(formalType);
          actualTypes!.add(inferredType);
        }
      }
    }
    assert(
        positionalIndex == arguments.positional.length,
        "Expected 'positionalIndex' to be ${arguments.positional.length}, "
        "got ${positionalIndex}.");
    assert(
        namedIndex == arguments.named.length,
        "Expected 'namedIndex' to be ${arguments.named.length}, "
        "got ${namedIndex}.");
    if (isSpecialCasedBinaryOperator) {
      calleeType = replaceReturnType(
          calleeType,
          typeSchemaEnvironment.getTypeOfSpecialCasedBinaryOperator(
              receiverType!, actualTypes![0],
              isNonNullableByDefault: isNonNullableByDefault));
    } else if (isSpecialCasedTernaryOperator) {
      calleeType = replaceReturnType(
          calleeType,
          typeSchemaEnvironment.getTypeOfSpecialCasedTernaryOperator(
              receiverType!, actualTypes![0], actualTypes[1], library.library));
    }

    // Check for and remove duplicated named arguments.
    List<NamedExpression> named = arguments.named;
    if (named.length == 2) {
      if (named[0].name == named[1].name) {
        String name = named[1].name;
        Expression error = helper!.wrapInProblem(
            _createDuplicateExpression(
                named[0].fileOffset, named[0].value, named[1].value),
            templateDuplicatedNamedArgument.withArguments(name),
            named[1].fileOffset,
            name.length);
        arguments.named = [new NamedExpression(named[1].name, error)];
        formalTypes!.removeLast();
        actualTypes!.removeLast();
      }
    } else if (named.length > 2) {
      Map<String, NamedExpression> seenNames = <String, NamedExpression>{};
      bool hasProblem = false;
      int namedTypeIndex = arguments.positional.length;
      List<NamedExpression> uniqueNamed = <NamedExpression>[];
      for (NamedExpression expression in named) {
        String name = expression.name;
        if (seenNames.containsKey(name)) {
          hasProblem = true;
          NamedExpression prevNamedExpression = seenNames[name]!;
          prevNamedExpression.value = helper!.wrapInProblem(
              _createDuplicateExpression(prevNamedExpression.fileOffset,
                  prevNamedExpression.value, expression.value),
              templateDuplicatedNamedArgument.withArguments(name),
              expression.fileOffset,
              name.length)
            ..parent = prevNamedExpression;
          formalTypes!.removeAt(namedTypeIndex);
          actualTypes!.removeAt(namedTypeIndex);
        } else {
          seenNames[name] = expression;
          uniqueNamed.add(expression);
          namedTypeIndex++;
        }
      }
      if (hasProblem) {
        arguments.named = uniqueNamed;
      }
    }

    if (inferenceNeeded) {
      typeSchemaEnvironment.inferGenericFunctionOrType(
          calleeType.returnType,
          calleeTypeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes!,
          library.library);
      assert(inferredTypes.every((type) => isKnown(type)),
          "Unknown type(s) in inferred types: $inferredTypes.");
      assert(inferredTypes.every((type) => !hasPromotedTypeVariable(type)),
          "Promoted type variable(s) in inferred types: $inferredTypes.");
      substitution =
          Substitution.fromPairs(calleeTypeParameters, inferredTypes);
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
    List<DartType> positionalArgumentTypes = [];
    List<NamedType> namedArgumentTypes = [];
    if (typeChecksNeeded && !identical(calleeType, unknownFunction)) {
      LocatedMessage? argMessage = helper!.checkArgumentsForType(
          calleeType, arguments, offset,
          isExtensionMemberInvocation: isExtensionMemberInvocation);
      if (argMessage != null) {
        return new WrapInProblemInferenceResult(
            const InvalidType(),
            const InvalidType(),
            argMessage.messageObject,
            argMessage.charOffset,
            argMessage.length,
            helper!,
            isInapplicable: true);
      } else {
        // Argument counts and names match. Compare types.
        int positionalShift = isImplicitExtensionMember ? 1 : 0;
        int numPositionalArgs = arguments.positional.length - positionalShift;
        for (int i = 0; i < formalTypes!.length; i++) {
          DartType formalType = formalTypes[i];
          DartType expectedType = substitution != null
              ? substitution.substituteType(formalType)
              : formalType;
          DartType actualType = actualTypes![i];
          Expression expression;
          NamedExpression? namedExpression;
          if (i < numPositionalArgs) {
            expression = arguments.positional[positionalShift + i];
            positionalArgumentTypes.add(actualType);
          } else {
            namedExpression = arguments.named[i - numPositionalArgs];
            expression = namedExpression.value;
            namedArgumentTypes
                .add(new NamedType(namedExpression.name, actualType));
          }
          expression = ensureAssignable(expectedType, actualType, expression,
              isVoidAllowed: expectedType is VoidType,
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
            arguments.positional[positionalShift + i] = expression
              ..parent = arguments;
          } else {
            namedExpression.value = expression..parent = namedExpression;
          }
        }
      }
    }
    DartType inferredType;
    if (substitution != null) {
      calleeType = substitution.substituteType(calleeType.withoutTypeParameters)
          as FunctionType;
    }
    inferredType = calleeType.returnType;
    assert(
        !containsFreeFunctionTypeVariables(inferredType),
        "Inferred return type $inferredType contains free variables."
        "Inferred function type: $calleeType.");

    if (!isNonNullableByDefault) {
      inferredType = legacyErasure(inferredType);
      calleeType = legacyErasure(calleeType) as FunctionType;
    }

    return new SuccessfulInferenceResult(inferredType, calleeType,
        hoistedArguments: localHoistedExpressions,
        inferredReceiverType: receiverType);
  }

  FunctionType inferLocalFunction(FunctionNode function, DartType? typeContext,
      int fileOffset, DartType? returnContext) {
    bool hasImplicitReturnType = false;
    if (returnContext == null) {
      hasImplicitReturnType = true;
      returnContext =
          isNonNullableByDefault ? const UnknownType() : const DynamicType();
    }
    if (!isTopLevel) {
      List<VariableDeclaration> positionalParameters =
          function.positionalParameters;
      for (int i = 0; i < positionalParameters.length; i++) {
        VariableDeclaration parameter = positionalParameters[i];
        flowAnalysis.declare(parameter, true);
        inferMetadataKeepingHelper(parameter, parameter.annotations);
        if (parameter.initializer != null) {
          ExpressionInferenceResult initializerResult = inferExpression(
              parameter.initializer!, parameter.type, !isTopLevel);
          parameter.initializer = initializerResult.expression
            ..parent = parameter;
        }
      }
      for (VariableDeclaration parameter in function.namedParameters) {
        flowAnalysis.declare(parameter, true);
        inferMetadataKeepingHelper(parameter, parameter.annotations);
        ExpressionInferenceResult initializerResult = inferExpression(
            parameter.initializer!, parameter.type, !isTopLevel);
        parameter.initializer = initializerResult.expression
          ..parent = parameter;
      }
    }

    // Let `<T0, ..., Tn>` be the set of type parameters of the closure (with
    // `n`=0 if there are no type parameters).
    List<TypeParameter> typeParameters = function.typeParameters;

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
    Substitution substitution;
    List<DartType?> formalTypesFromContext =
        new List<DartType?>.filled(formals.length, null);
    if (typeContext is FunctionType &&
        typeContext.typeParameters.length == typeParameters.length) {
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
      Map<TypeParameter, DartType> substitutionMap =
          <TypeParameter, DartType>{};
      for (int i = 0; i < typeContext.typeParameters.length; i++) {
        substitutionMap[typeContext.typeParameters[i]] =
            i < typeParameters.length
                ? new TypeParameterType.forAlphaRenaming(
                    typeContext.typeParameters[i], typeParameters[i])
                : const DynamicType();
      }
      substitution = Substitution.fromMap(substitutionMap);
    } else {
      // If the match is not successful because  `K` is `_`, let all `Si`, all
      // `Qi`, and `N` all be `_`.

      // If the match is not successful for any other reason, this will result
      // in a type error, so the implementation is free to choose the best
      // error recovery path.
      substitution = Substitution.empty;
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
              substitution.substituteType(formalTypesFromContext[i]!));
          if (typeSchemaEnvironment.isSubtypeOf(
              inferredType,
              const NullType(),
              isNonNullableByDefault
                  ? SubtypeCheckMode.withNullabilities
                  : SubtypeCheckMode.ignoringNullabilities)) {
            inferredType = coreTypes.objectRawType(library.nullable);
          }
        } else {
          inferredType = const DynamicType();
        }
        instrumentation?.record(uriForInstrumentation, formal.fileOffset,
            'type', new InstrumentationValueForType(inferredType));
        formal.type = demoteTypeInLibrary(inferredType, library.library);
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
          library.addProblem(
              templateOptionalNonNullableWithoutInitializerError.withArguments(
                  formal.name!, formal.type, isNonNullableByDefault),
              formal.fileOffset,
              formal.name!.length,
              library.importUri);
        }
      }
    }

    if (isNonNullableByDefault) {
      for (VariableDeclaration parameter in function.namedParameters) {
        VariableDeclarationImpl formal = parameter as VariableDeclarationImpl;
        // Required named parameters shouldn't have initializers.
        if (formal.isRequired && formal.hasDeclaredInitializer) {
          library.addProblem(
              templateRequiredNamedParameterHasDefaultValueError
                  .withArguments(formal.name!),
              formal.fileOffset,
              formal.name!.length,
              library.importUri);
        }
      }
    }

    // Let `N'` be `N[T/S]`.  The [ClosureContext] constructor will adjust
    // accordingly if the closure is declared with `async`, `async*`, or
    // `sync*`.
    if (returnContext is! UnknownType) {
      returnContext = substitution.substituteType(returnContext);
    }

    // Apply type inference to `B` in return context `N’`, with any references
    // to `xi` in `B` having type `Pi`.  This produces `B’`.
    bool needToSetReturnType = hasImplicitReturnType;
    ClosureContext? oldClosureContext = this.closureContext;
    ClosureContext closureContext = new ClosureContext(
        this, function.asyncMarker, returnContext, needToSetReturnType);
    this.closureContext = closureContext;
    StatementInferenceResult bodyResult = inferStatement(function.body!);

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
    function.futureValueType = closureContext.futureValueType;
    assert(
        !(isNonNullableByDefault &&
            function.asyncMarker == AsyncMarker.Async &&
            function.futureValueType == null),
        "No future value type computed.");

    if (bodyResult.hasChanged) {
      function.body = bodyResult.statement..parent = function;
    }
    this.closureContext = oldClosureContext;
    return function.computeFunctionType(library.nonNullable);
  }

  @override
  void inferMetadata(
      InferenceHelper helper, TreeNode? parent, List<Expression>? annotations) {
    if (annotations != null) {
      this.helper = helper;
      inferMetadataKeepingHelper(parent, annotations);
      this.helper = null;
    }
  }

  @override
  void inferMetadataKeepingHelper(
      TreeNode? parent, List<Expression>? annotations) {
    if (annotations != null) {
      for (int index = 0; index < annotations.length; index++) {
        ExpressionInferenceResult result = inferExpression(
            annotations[index], const UnknownType(), !isTopLevel);
        annotations[index] = result.expression..parent = parent;
      }
    }
  }

  StaticInvocation transformExtensionMethodInvocation(int fileOffset,
      ObjectAccessTarget target, Expression receiver, Arguments arguments) {
    assert(target.isExtensionMember || target.isNullableExtensionMember);
    Procedure procedure = target.member as Procedure;
    return engine.forest.createStaticInvocation(
        fileOffset,
        procedure,
        engine.forest.createArgumentsForExtensionMethod(
            arguments.fileOffset,
            target.inferredExtensionTypeArguments.length,
            procedure.function.typeParameters.length -
                target.inferredExtensionTypeArguments.length,
            receiver,
            extensionTypeArguments: target.inferredExtensionTypeArguments,
            positionalArguments: arguments.positional,
            namedArguments: arguments.named,
            typeArguments: arguments.types));
  }

  ExpressionInferenceResult _inferDynamicInvocation(
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);
    InvocationInferenceResult result = inferInvocation(
        typeContext, fileOffset, unknownFunction, arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: const DynamicType(),
        isImplicitCall: isImplicitCall);
    assert(name != equalsName);
    Expression expression = new DynamicInvocation(
        DynamicAccessKind.Dynamic, receiver, name, arguments)
      ..fileOffset = fileOffset;
    return createNullAwareExpressionInferenceResult(
        result.inferredType, result.applyResult(expression), nullAwareGuards);
  }

  ExpressionInferenceResult _inferNeverInvocation(
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      NeverType receiverType,
      Name name,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);
    InvocationInferenceResult result = inferInvocation(
        typeContext, fileOffset, unknownFunction, arguments,
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
    // ignore: unnecessary_null_comparison
    assert(isExpressionInvocation != null);
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);
    Expression error = createMissingMethodInvocation(
        fileOffset, receiver, receiverType, name, arguments,
        isExpressionInvocation: isExpressionInvocation,
        implicitInvocationPropertyName: implicitInvocationPropertyName,
        extensionAccessCandidates:
            target.isAmbiguous ? target.candidates : null);
    inferInvocation(typeContext, fileOffset, unknownFunction, arguments,
        hoistedExpressions: hoistedExpressions,
        receiverType: receiverType,
        isImplicitCall: isExpressionInvocation || isImplicitCall);
    assert(name != equalsName);
    // TODO(johnniwinther): Use InvalidType instead.
    return createNullAwareExpressionInferenceResult(
        const DynamicType(), error, nullAwareGuards);
  }

  ExpressionInferenceResult _inferExtensionInvocation(
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
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);
    assert(target.isExtensionMember || target.isNullableExtensionMember);
    DartType calleeType = getGetterType(target, receiverType);
    FunctionType functionType = getFunctionType(target, receiverType);

    if (target.extensionMethodKind == ProcedureKind.Getter) {
      StaticInvocation staticInvocation = transformExtensionMethodInvocation(
          fileOffset, target, receiver, new Arguments.empty());
      ExpressionInferenceResult result = inferMethodInvocation(
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

      if (!isTopLevel && target.isNullable) {
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
      InvocationInferenceResult result = inferInvocation(typeContext,
          fileOffset, functionType, staticInvocation.arguments as ArgumentsImpl,
          hoistedExpressions: hoistedExpressions,
          receiverType: receiverType,
          isImplicitExtensionMember: true,
          isImplicitCall: isImplicitCall,
          isExtensionMemberInvocation: true);
      if (!isTopLevel) {
        library.checkBoundsInStaticInvocation(
            staticInvocation,
            typeSchemaEnvironment,
            helper!.uri,
            getTypeArgumentsInfo(arguments));
      }

      Expression replacement = result.applyResult(staticInvocation);
      if (!isTopLevel && target.isNullable) {
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
          replacement = helper!.wrapInProblem(
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
          replacement = helper!.wrapInProblem(
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
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isImplicitCall}) {
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);
    assert(target.isCallFunction || target.isNullableCallFunction);
    FunctionType declaredFunctionType = getFunctionType(target, receiverType);
    InvocationInferenceResult result = inferInvocation(
        typeContext, fileOffset, declaredFunctionType, arguments,
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
    if (!isTopLevel && target.isNullableCallFunction) {
      List<LocatedMessage>? context = getWhyNotPromotedContext(
          flowAnalysis.whyNotPromoted(receiver)(),
          expression,
          (type) => !type.isPotentiallyNullable);
      if (isImplicitCall) {
        // Handles cases like:
        //   void Function()? f;
        //   f();
        replacement = helper!.wrapInProblem(
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
        replacement = helper!.wrapInProblem(
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
        library.nonNullable,
        namedParameters: new List<NamedType>.generate(arguments.named.length,
            (int index) => new NamedType(arguments.named[index].name, type)));
  }

  ExpressionInferenceResult _inferInstanceMethodInvocation(
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
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);
    // ignore: unnecessary_null_comparison
    assert(isSpecialCasedBinaryOperator != null);
    // ignore: unnecessary_null_comparison
    assert(isSpecialCasedTernaryOperator != null);
    assert(target.isInstanceMember ||
        target.isObjectMember ||
        target.isNullableInstanceMember);
    Procedure? method = target.member as Procedure;
    assert(method.kind == ProcedureKind.Method,
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

    DartType calleeType = getGetterType(target, receiverType);
    FunctionType declaredFunctionType = getFunctionType(target, receiverType);

    bool contravariantCheck = false;
    if (receiver is! ThisExpression &&
        method != null &&
        returnedTypeParametersOccurNonCovariantly(
            method.enclosingClass!, method.function.returnType)) {
      contravariantCheck = true;
    }
    InvocationInferenceResult result = inferInvocation(typeContext, fileOffset,
        declaredFunctionType, arguments as ArgumentsImpl,
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
    if (!isTopLevel && target.isNullable) {
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
        replacement = helper!.wrapInProblem(
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
        replacement = helper!.wrapInProblem(
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
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isExpressionInvocation}) {
    // ignore: unnecessary_null_comparison
    assert(isExpressionInvocation != null);
    assert(target.isInstanceMember ||
        target.isObjectMember ||
        target.isNullableInstanceMember);
    Procedure? getter = target.member as Procedure;
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

    DartType calleeType = getGetterType(target, receiverType);
    FunctionType functionType = getFunctionTypeForImplicitCall(calleeType);

    List<VariableDeclaration>? locallyHoistedExpressions;
    if (hoistedExpressions == null && !isTopLevel) {
      // We don't hoist in top-level inference.
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
            getter.enclosingClass!, getter.function.returnType)) {
      propertyGet = new AsExpression(propertyGet, functionType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..isForNonNullableByDefault = isNonNullableByDefault
        ..fileOffset = fileOffset;
      if (instrumentation != null) {
        int offset =
            arguments.fileOffset == -1 ? fileOffset : arguments.fileOffset;
        instrumentation!.record(uriForInstrumentation, offset,
            'checkGetterReturn', new InstrumentationValueForType(functionType));
      }
    }

    if (isExpressionInvocation) {
      if (isTopLevel) {
        // Create an expression invocation for reporting the error during
        // full inference.
        return new ExpressionInferenceResult(
            const InvalidType(),
            new ExpressionInvocation(receiver, arguments)
              ..fileOffset = fileOffset);
      } else {
        Expression error = helper!.buildProblem(
            templateImplicitCallOfNonMethod.withArguments(
                receiverType, isNonNullableByDefault),
            fileOffset,
            noLength);
        return new ExpressionInferenceResult(const InvalidType(), error);
      }
    }

    ExpressionInferenceResult invocationResult = inferMethodInvocation(
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

    if (!isTopLevel && target.isNullable) {
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

    if (!library.loader.target.backendTarget.supportsExplicitGetterCalls) {
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
    if (hoistedExpressions != null && expression is! ThisExpression) {
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
      int fileOffset,
      Link<NullAwareGuard> nullAwareGuards,
      Expression receiver,
      DartType receiverType,
      ObjectAccessTarget target,
      ArgumentsImpl arguments,
      DartType typeContext,
      List<VariableDeclaration>? hoistedExpressions,
      {required bool isExpressionInvocation}) {
    // ignore: unnecessary_null_comparison
    assert(isExpressionInvocation != null);
    assert(target.isInstanceMember ||
        target.isObjectMember ||
        target.isNullableInstanceMember);
    Field field = target.member as Field;

    DartType calleeType = getGetterType(target, receiverType);
    FunctionType functionType = getFunctionTypeForImplicitCall(calleeType);

    List<VariableDeclaration>? locallyHoistedExpressions;
    if (hoistedExpressions == null && !isTopLevel) {
      // We don't hoist in top-level inference.
      hoistedExpressions = locallyHoistedExpressions = <VariableDeclaration>[];
    }
    if (arguments.positional.isNotEmpty || arguments.named.isNotEmpty) {
      receiver = _hoist(receiver, receiverType, hoistedExpressions);
    }

    Map<DartType, NonPromotionReason> Function()? whyNotPromoted;
    if (!isTopLevel && target.isNullable) {
      // We won't report the error until later (after we have an
      // invocationResult), but we need to gather "why not promoted" info now,
      // before we tell flow analysis about the property get.
      whyNotPromoted = flowAnalysis.whyNotPromoted(receiver);
    }

    Name originalName = field.name;
    Expression originalReceiver = receiver;
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
        kind, originalReceiver, originalName,
        resultType: calleeType, interfaceTarget: originalTarget)
      ..fileOffset = fileOffset;
    flowAnalysis.propertyGet(originalPropertyGet, originalReceiver,
        originalName.text, originalTarget, calleeType);
    Expression propertyGet = originalPropertyGet;
    if (receiver is! ThisExpression &&
        calleeType is! DynamicType &&
        returnedTypeParametersOccurNonCovariantly(
            field.enclosingClass!, field.type)) {
      propertyGet = new AsExpression(propertyGet, functionType)
        ..isTypeError = true
        ..isCovarianceCheck = true
        ..isForNonNullableByDefault = isNonNullableByDefault
        ..fileOffset = fileOffset;
      if (instrumentation != null) {
        int offset =
            arguments.fileOffset == -1 ? fileOffset : arguments.fileOffset;
        instrumentation!.record(uriForInstrumentation, offset,
            'checkGetterReturn', new InstrumentationValueForType(functionType));
      }
    }

    if (isExpressionInvocation) {
      if (isTopLevel) {
        // Create an expression invocation for reporting the error during
        // full inference.
        return new ExpressionInferenceResult(
            const InvalidType(),
            new ExpressionInvocation(receiver, arguments)
              ..fileOffset = fileOffset);
      } else {
        Expression error = helper!.buildProblem(
            templateImplicitCallOfNonMethod.withArguments(
                receiverType, isNonNullableByDefault),
            fileOffset,
            noLength);
        return new ExpressionInferenceResult(const InvalidType(), error);
      }
    }

    ExpressionInferenceResult invocationResult = inferMethodInvocation(
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

    if (!isTopLevel && target.isNullable) {
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

    if (!library.loader.target.backendTarget.supportsExplicitGetterCalls) {
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

  /// Performs the core type inference algorithm for method invocations.
  ExpressionInferenceResult inferMethodInvocation(
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
      List<VariableDeclaration>? hoistedExpressions}) {
    // ignore: unnecessary_null_comparison
    assert(isExpressionInvocation != null);
    // ignore: unnecessary_null_comparison
    assert(isImplicitCall != null);

    ObjectAccessTarget target = findInterfaceMember(
        receiverType, name, fileOffset,
        instrumented: true,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.methodInvocation);

    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
      case ObjectAccessTargetKind.objectMember:
      case ObjectAccessTargetKind.nullableInstanceMember:
        Member member = target.member!;
        if (member is Procedure) {
          if (member.kind == ProcedureKind.Getter) {
            return _inferInstanceGetterInvocation(
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
                isSpecialCasedBinaryOperatorForReceiverType(
                    target, receiverType);
            return _inferInstanceMethodInvocation(
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
                    isSpecialCasedTernaryOperator(target));
          }
        } else {
          return _inferInstanceFieldInvocation(
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
        return _inferFunctionInvocation(fileOffset, nullAwareGuards, receiver,
            receiverType, target, arguments, typeContext, hoistedExpressions,
            isImplicitCall: isImplicitCall);
      case ObjectAccessTargetKind.extensionMember:
      case ObjectAccessTargetKind.nullableExtensionMember:
        return _inferExtensionInvocation(
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
        return _inferDynamicInvocation(fileOffset, nullAwareGuards, receiver,
            name, arguments, typeContext, hoistedExpressions,
            isImplicitCall: isExpressionInvocation || isImplicitCall);
      case ObjectAccessTargetKind.never:
        return _inferNeverInvocation(
            fileOffset,
            nullAwareGuards,
            receiver,
            receiverType as NeverType,
            name,
            arguments,
            typeContext,
            hoistedExpressions,
            isImplicitCall: isImplicitCall);
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
    if (!isTopLevel) {
      // We only perform checks in full inference.

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
      library.checkBoundsInMethodInvocation(
          actualReceiverType,
          typeSchemaEnvironment,
          classHierarchy,
          this,
          actualMethodName,
          interfaceTarget,
          arguments,
          helper!.uri,
          fileOffset);
    }
  }

  void checkBoundsInInstantiation(
      FunctionType functionType, List<DartType> arguments, int fileOffset,
      {required bool inferred}) {
    // ignore: unnecessary_null_comparison
    assert(inferred != null);
    // If [arguments] were inferred, check them.
    if (!isTopLevel) {
      // We only perform checks in full inference.
      library.checkBoundsInInstantiation(typeSchemaEnvironment, classHierarchy,
          this, functionType, arguments, helper!.uri, fileOffset,
          inferred: inferred);
    }
  }

  void _checkBoundsInFunctionInvocation(FunctionType functionType,
      String? localName, Arguments arguments, int fileOffset) {
    // If [arguments] were inferred, check them.
    if (!isTopLevel) {
      // We only perform checks in full inference.
      library.checkBoundsInFunctionInvocation(
          typeSchemaEnvironment,
          classHierarchy,
          this,
          functionType,
          localName,
          arguments,
          helper!.uri,
          fileOffset);
    }
  }

  bool isSpecialCasedBinaryOperatorForReceiverType(
      ObjectAccessTarget target, DartType receiverType) {
    return (target.isInstanceMember ||
            target.isObjectMember ||
            target.isNullableInstanceMember) &&
        target.member is Procedure &&
        typeSchemaEnvironment.isSpecialCasesBinaryForReceiverType(
            target.member as Procedure, receiverType,
            isNonNullableByDefault: isNonNullableByDefault);
  }

  bool isSpecialCasedTernaryOperator(ObjectAccessTarget target) {
    return (target.isInstanceMember ||
            target.isObjectMember ||
            target.isNullableInstanceMember) &&
        target.member is Procedure &&
        typeSchemaEnvironment.isSpecialCasedTernaryOperator(
            target.member as Procedure,
            isNonNullableByDefault: isNonNullableByDefault);
  }

  /// Performs the core type inference algorithm for super method invocations.
  ExpressionInferenceResult inferSuperMethodInvocation(
      SuperMethodInvocation expression,
      DartType typeContext,
      Procedure? procedure) {
    ObjectAccessTarget target = procedure != null
        ? new ObjectAccessTarget.interfaceMember(procedure,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();
    int fileOffset = expression.fileOffset;
    Name methodName = expression.name;
    ArgumentsImpl arguments = expression.arguments as ArgumentsImpl;
    DartType receiverType = thisType!;
    bool isSpecialCasedBinaryOperator =
        isSpecialCasedBinaryOperatorForReceiverType(target, receiverType);
    DartType calleeType = getGetterType(target, receiverType);
    FunctionType functionType = getFunctionType(target, receiverType);
    if (procedure != null) {
      calleeType =
          computeTypeFromSuperClass(procedure.enclosingClass!, calleeType);
      functionType =
          computeTypeFromSuperClass(procedure.enclosingClass!, functionType)
              as FunctionType;
    }
    if (isNonNullableByDefault &&
        expression.name == equalsName &&
        functionType.positionalParameters.length == 1) {
      // operator == always allows nullable arguments.
      functionType = new FunctionType([
        functionType.positionalParameters.single
            .withDeclaredNullability(library.nullable)
      ], functionType.returnType, functionType.declaredNullability);
    }
    InvocationInferenceResult result = inferInvocation(
        typeContext, fileOffset, functionType, arguments,
        isSpecialCasedBinaryOperator: isSpecialCasedBinaryOperator,
        receiverType: receiverType,
        isImplicitExtensionMember: false);
    DartType inferredType = result.inferredType;
    if (methodName.text == '==') {
      inferredType = coreTypes.boolRawType(library.nonNullable);
    }
    _checkBoundsInMethodInvocation(
        target, receiverType, calleeType, methodName, arguments, fileOffset);

    return new ExpressionInferenceResult(
        inferredType, result.applyResult(expression));
  }

  @override
  Expression inferParameterInitializer(
      InferenceHelper helper,
      Expression initializer,
      DartType declaredType,
      bool hasDeclaredInitializer) {
    assert(closureContext == null);
    this.helper = helper;
    // ignore: unnecessary_null_comparison
    assert(declaredType != null);
    ExpressionInferenceResult result =
        inferExpression(initializer, declaredType, true);
    if (hasDeclaredInitializer) {
      initializer = ensureAssignableResult(declaredType, result);
    }
    this.helper = null;
    return initializer;
  }

  /// Performs the core type inference algorithm for super property get.
  ExpressionInferenceResult inferSuperPropertyGet(
      SuperPropertyGet expression, DartType typeContext, Member? member) {
    ObjectAccessTarget readTarget = member != null
        ? new ObjectAccessTarget.interfaceMember(member,
            isPotentiallyNullable: false)
        : const ObjectAccessTarget.missing();
    DartType receiverType = thisType!;
    DartType inferredType = getGetterType(readTarget, receiverType);
    if (member != null) {
      inferredType =
          computeTypeFromSuperClass(member.enclosingClass!, inferredType);
    }
    if (member is Procedure && member.kind == ProcedureKind.Method) {
      return instantiateTearOff(inferredType, typeContext, expression);
    }
    flowAnalysis.thisOrSuperPropertyGet(
        expression, expression.name.text, member, inferredType);
    return new ExpressionInferenceResult(inferredType, expression);
  }

  /// Performs type inference on the given [statement].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the statement type and calls the appropriate specialized "infer" method.
  StatementInferenceResult inferStatement(Statement statement) {
    registerIfUnreachableForTesting(statement);

    // For full (non-top level) inference, we need access to the
    // ExpressionGeneratorHelper so that we can perform error recovery.
    if (!isTopLevel) assert(helper != null);
    InferenceVisitor visitor = new InferenceVisitor(this);
    if (statement is InternalStatement) {
      return statement.acceptInference(visitor);
    } else {
      return statement.accept(visitor);
    }
  }

  /// Computes the implicit instantiation from an expression of [tearOffType]
  /// to the [context] type. Return `null` if an implicit instantiation is not
  /// necessary or possible.
  ImplicitInstantiation? computeImplicitInstantiation(
      DartType tearoffType, DartType context) {
    if (tearoffType is FunctionType &&
        context is FunctionType &&
        context.typeParameters.isEmpty) {
      FunctionType functionType = tearoffType;
      List<TypeParameter> typeParameters = functionType.typeParameters;
      if (typeParameters.isNotEmpty) {
        List<DartType> inferredTypes = new List<DartType>.filled(
            typeParameters.length, const UnknownType());
        FunctionType instantiatedType = functionType.withoutTypeParameters;
        typeSchemaEnvironment.inferGenericFunctionOrType(instantiatedType,
            typeParameters, [], [], context, inferredTypes, library.library);
        Substitution substitution =
            Substitution.fromPairs(typeParameters, inferredTypes);
        tearoffType = substitution.substituteType(instantiatedType);
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
      List<DartType> typeArguments = implicitInstantiation.typeArguments;
      if (!isTopLevel) {
        checkBoundsInInstantiation(implicitInstantiation.functionType,
            typeArguments, expression.fileOffset,
            inferred: true);
      }
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
      expression = new Instantiation(expression, typeArguments)
        ..fileOffset = expression.fileOffset;
      tearOffType = implicitInstantiation.instantiatedType;
    }
    return new ExpressionInferenceResult(tearOffType, expression);
  }

  /// Performs the type inference steps necessary to instantiate a tear-off
  /// (if necessary).
  ExpressionInferenceResult instantiateTearOff(
      DartType tearoffType, DartType context, Expression expression) {
    ImplicitInstantiation? implicitInstantiation =
        computeImplicitInstantiation(tearoffType, context);
    return _applyImplicitInstantiation(
        implicitInstantiation, tearoffType, expression);
  }

  /// True if the returned [type] has non-covariant occurrences of any of
  /// [class_]'s type parameters.
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
      Class class_, DartType type) {
    if (class_.typeParameters.isEmpty) return false;
    IncludesTypeParametersNonCovariantly checker =
        new IncludesTypeParametersNonCovariantly(class_.typeParameters,
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
    // ignore: unnecessary_null_comparison
    assert(isThisReceiver != null);
    if (target.isInstanceMember || target.isObjectMember) {
      Member interfaceMember = target.member!;
      if (interfaceMember is Field ||
          interfaceMember is Procedure &&
              interfaceMember.kind == ProcedureKind.Getter) {
        DartType getType = getGetterType(target, receiverType);
        if (getType is DynamicType) {
          return MethodContravarianceCheckKind.none;
        }
        if (!isThisReceiver) {
          if ((interfaceMember is Field &&
                  returnedTypeParametersOccurNonCovariantly(
                      interfaceMember.enclosingClass!, interfaceMember.type)) ||
              (interfaceMember is Procedure &&
                  returnedTypeParametersOccurNonCovariantly(
                      interfaceMember.enclosingClass!,
                      interfaceMember.function.returnType))) {
            return MethodContravarianceCheckKind.checkGetterReturn;
          }
        }
      } else if (!isThisReceiver &&
          interfaceMember is Procedure &&
          returnedTypeParametersOccurNonCovariantly(
              interfaceMember.enclosingClass!,
              interfaceMember.function.returnType)) {
        return MethodContravarianceCheckKind.checkMethodReturn;
      }
    }
    return MethodContravarianceCheckKind.none;
  }

  /// If the given [type] is a [TypeParameterType], resolve it to its bound.
  DartType resolveTypeParameter(DartType type) {
    DartType? resolveOneStep(DartType type) {
      if (type is TypeParameterType) {
        return type.bound;
      } else {
        return null;
      }
    }

    DartType? resolved = resolveOneStep(type);
    if (resolved == null) return type;

    // Detect circularities using the tortoise-and-hare algorithm.
    DartType? tortoise = resolved;
    DartType? hare = resolveOneStep(tortoise);
    if (hare == null) return tortoise;
    while (true) {
      if (identical(tortoise, hare)) {
        // We found a circularity.  Give up and return `dynamic`.
        return const DynamicType();
      }

      // Hare takes two steps
      DartType? step1 = resolveOneStep(hare!);
      if (step1 == null) return hare;
      DartType? step2 = resolveOneStep(step1);
      if (step2 == null) return step1;
      hare = step2;

      // Tortoise takes one step
      tortoise = resolveOneStep(tortoise!);
    }
  }

  DartType wrapFutureOrType(DartType type) {
    if (type is FutureOrType) {
      return type;
    }
    // TODO(paulberry): If [type] is a subtype of `Future`, should we just
    // return it unmodified?
    // ignore: unnecessary_null_comparison
    if (type == null) {
      return coreTypes.futureRawType(library.nullable);
    }
    return new FutureOrType(type, library.nonNullable);
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
  /// This is the same as the [futureValueType] except that this handles
  /// the unknown type.
  DartType computeFutureValueTypeSchema(DartType type) {
    return type.accept1(new FutureValueTypeVisitor(unhandledTypeHandler:
        (DartType node, CoreTypes coreTypes,
            DartType Function(DartType node, CoreTypes coreTypes) recursor) {
      if (node is UnknownType) {
        // futureValueTypeSchema(_) = _.
        return node;
      }
      throw new UnsupportedError("Unsupported type '${node.runtimeType}'.");
    }), coreTypes);
  }

  Member? _getInterfaceMember(
      Class class_, Name name, bool setter, int charOffset) {
    ClassMember? classMember = engine.membersBuilder
        .getInterfaceClassMember(class_, name, setter: setter);
    if (classMember != null) {
      if (classMember.isStatic) {
        classMember = null;
      } else if (classMember.isDuplicate) {
        if (!isTopLevel) {
          library.addProblem(
              templateDuplicatedDeclarationUse.withArguments(name.text),
              charOffset,
              name.text.length,
              helper!.uri);
        }
        classMember = null;
      }
    }
    Member? member = classMember?.getMember(engine.membersBuilder);
    if (member == null && library.isPatch) {
      // TODO(johnniwinther): Injected members are currently not included
      // in the class hierarchy builder.
      member ??=
          classHierarchy.getInterfaceMember(class_, name, setter: setter);
    }
    return TypeInferenceEngine.resolveInferenceNode(member);
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
    if (expression is SetLiteral) {
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
        contextType.classNode == typeSchemaEnvironment.functionClass) {
      if (!typeSchemaEnvironment.isSubtypeOf(expressionType, contextType,
          SubtypeCheckMode.ignoringNullabilities)) {
        return true;
      }
    }
    return false;
  }

  Expression createMissingSuperIndexGet(int fileOffset, Expression index) {
    if (isTopLevel) {
      return engine.forest.createSuperMethodInvocation(fileOffset, indexGetName,
          null, engine.forest.createArguments(fileOffset, <Expression>[index]));
    } else {
      return helper!.buildProblem(
          templateSuperclassHasNoMethod.withArguments(indexGetName.text),
          fileOffset,
          noLength);
    }
  }

  Expression createMissingSuperIndexSet(
      int fileOffset, Expression index, Expression value) {
    if (isTopLevel) {
      return engine.forest.createSuperMethodInvocation(
          fileOffset,
          indexSetName,
          null,
          engine.forest
              .createArguments(fileOffset, <Expression>[index, value]));
    } else {
      return helper!.buildProblem(
          templateSuperclassHasNoMethod.withArguments(indexSetName.text),
          fileOffset,
          noLength);
    }
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
      Expression wrappedExpression,
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
    return helper!.wrapInProblem(
        wrappedExpression,
        template.withArguments(name.text, resolveTypeParameter(receiverType),
            isNonNullableByDefault),
        fileOffset,
        length,
        context: context);
  }

  Expression createMissingMethodInvocation(int fileOffset, Expression receiver,
      DartType receiverType, Name name, Arguments arguments,
      {required bool isExpressionInvocation,
      Name? implicitInvocationPropertyName,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    // ignore: unnecessary_null_comparison
    assert(isExpressionInvocation != null);
    if (isTopLevel) {
      return engine.forest
          .createMethodInvocation(fileOffset, receiver, name, arguments);
    } else if (implicitInvocationPropertyName != null) {
      assert(extensionAccessCandidates == null);
      return helper!.wrapInProblem(
          _createInvalidInvocation(fileOffset, receiver, name, arguments),
          templateInvokeNonFunction
              .withArguments(implicitInvocationPropertyName.text),
          fileOffset,
          implicitInvocationPropertyName.text.length);
    } else {
      return _reportMissingOrAmbiguousMember(
          fileOffset,
          isExpressionInvocation ? noLength : name.text.length,
          receiverType,
          name,
          _createInvalidInvocation(fileOffset, receiver, name, arguments),
          extensionAccessCandidates,
          receiverType is ExtensionType
              ? templateUndefinedExtensionMethod
              : templateUndefinedMethod,
          templateAmbiguousExtensionMethod);
    }
  }

  Expression createMissingPropertyGet(int fileOffset, Expression receiver,
      DartType receiverType, Name propertyName,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    if (isTopLevel) {
      return engine.forest
          .createPropertyGet(fileOffset, receiver, propertyName);
    } else {
      Template<Message Function(String, DartType, bool)> templateMissing;
      if (receiverType is ExtensionType) {
        templateMissing = templateUndefinedExtensionGetter;
      } else {
        templateMissing = templateUndefinedGetter;
      }
      return _reportMissingOrAmbiguousMember(
          fileOffset,
          propertyName.text.length,
          receiverType,
          propertyName,
          _createInvalidGet(fileOffset, receiver, propertyName),
          extensionAccessCandidates,
          templateMissing,
          templateAmbiguousExtensionProperty);
    }
  }

  Expression createMissingPropertySet(int fileOffset, Expression receiver,
      DartType receiverType, Name propertyName, Expression value,
      {required bool forEffect,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    // ignore: unnecessary_null_comparison
    assert(forEffect != null);
    if (isTopLevel) {
      return engine.forest.createPropertySet(
          fileOffset, receiver, propertyName, value,
          forEffect: forEffect);
    } else {
      Template<Message Function(String, DartType, bool)> templateMissing;
      if (receiverType is ExtensionType) {
        templateMissing = templateUndefinedExtensionSetter;
      } else {
        templateMissing = templateUndefinedSetter;
      }
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
  }

  Expression createMissingIndexGet(int fileOffset, Expression receiver,
      DartType receiverType, Expression index,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    if (isTopLevel) {
      return engine.forest.createIndexGet(fileOffset, receiver, index);
    } else {
      Template<Message Function(String, DartType, bool)> templateMissing;
      if (receiverType is ExtensionType) {
        templateMissing = templateUndefinedExtensionOperator;
      } else {
        templateMissing = templateUndefinedOperator;
      }
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
  }

  Expression createMissingIndexSet(int fileOffset, Expression receiver,
      DartType receiverType, Expression index, Expression value,
      {required bool forEffect,
      List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    // ignore: unnecessary_null_comparison
    assert(forEffect != null);
    if (isTopLevel) {
      return engine.forest.createIndexSet(fileOffset, receiver, index, value,
          forEffect: forEffect);
    } else {
      Template<Message Function(String, DartType, bool)> templateMissing;
      if (receiverType is ExtensionType) {
        templateMissing = templateUndefinedExtensionOperator;
      } else {
        templateMissing = templateUndefinedOperator;
      }
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
  }

  Expression createMissingBinary(int fileOffset, Expression left,
      DartType leftType, Name binaryName, Expression right,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    assert(binaryName != equalsName);
    if (isTopLevel) {
      return engine.forest.createMethodInvocation(fileOffset, left, binaryName,
          engine.forest.createArguments(fileOffset, <Expression>[right]));
    } else {
      Template<Message Function(String, DartType, bool)> templateMissing;
      if (leftType is ExtensionType) {
        templateMissing = templateUndefinedExtensionOperator;
      } else {
        templateMissing = templateUndefinedOperator;
      }
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
  }

  Expression createMissingUnary(int fileOffset, Expression expression,
      DartType expressionType, Name unaryName,
      {List<ExtensionAccessCandidate>? extensionAccessCandidates}) {
    if (isTopLevel) {
      return new UnaryExpression(unaryName, expression)
        ..fileOffset = fileOffset;
    } else {
      Template<Message Function(String, DartType, bool)> templateMissing;
      if (expressionType is ExtensionType) {
        templateMissing = templateUndefinedExtensionOperator;
      } else {
        templateMissing = templateUndefinedOperator;
      }
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
  }

  /// Creates a `e == null` test for the expression [left] using the
  /// [fileOffset] as file offset for the created nodes.
  Expression createEqualsNull(int fileOffset, Expression left) {
    return new EqualsNull(left)..fileOffset = fileOffset;
  }
}

abstract class MixinInferrer {
  final CoreTypes coreTypes;
  final TypeConstraintGatherer gatherer;

  MixinInferrer(this.coreTypes, this.gatherer);

  Supertype? asInstantiationOf(Supertype type, Class superclass);

  void reportProblem(Message message, Class cls);

  void generateConstraints(
      Class mixinClass, Supertype baseType, Supertype mixinSupertype) {
    if (mixinSupertype.typeArguments.isEmpty) {
      // The supertype constraint isn't generic; it doesn't constrain anything.
    } else if (mixinSupertype.classNode.isAnonymousMixin) {
      // We have either a mixin declaration `mixin M<X0, ..., Xn> on S0, S1` or
      // a VM-style super mixin `abstract class M<X0, ..., Xn> extends S0 with
      // S1` where S0 and S1 are superclass constraints that possibly have type
      // arguments.
      //
      // It has been compiled by naming the superclass to either:
      //
      // abstract class S0&S1<...> extends Object implements S0, S1 {}
      // abstract class M<X0, ..., Xn> extends S0&S1<...> ...
      //
      // for a mixin declaration, or else:
      //
      // abstract class S0&S1<...> = S0 with S1;
      // abstract class M<X0, ..., Xn> extends S0&S1<...>
      //
      // for a VM-style super mixin.  The type parameters of S0&S1 are the X0,
      // ..., Xn that occurred free in S0 and S1.  Treat S0 and S1 as separate
      // supertype constraints by recursively calling this algorithm.
      //
      // In the Dart VM the mixin application classes themselves are all
      // eliminated by translating them to normal classes.  In that case, the
      // mixin appears as the only interface in the introduced class.  We
      // support three forms for the superclass constraints:
      //
      // abstract class S0&S1<...> extends Object implements S0, S1 {}
      // abstract class S0&S1<...> = S0 with S1;
      // abstract class S0&S1<...> extends S0 implements S1 {}
      Class mixinSuperclass = mixinSupertype.classNode;
      if (mixinSuperclass.mixedInType == null &&
          mixinSuperclass.implementedTypes.length != 1 &&
          (mixinSuperclass.superclass != coreTypes.objectClass ||
              mixinSuperclass.implementedTypes.length != 2)) {
        unexpected(
            'Compiler-generated mixin applications have a mixin or else '
                'implement exactly one type',
            '$mixinSuperclass implements '
                '${mixinSuperclass.implementedTypes.length} types',
            mixinSuperclass.fileOffset,
            mixinSuperclass.fileUri);
      }
      Substitution substitution = Substitution.fromSupertype(mixinSupertype);
      Supertype s0, s1;
      if (mixinSuperclass.implementedTypes.length == 2) {
        s0 = mixinSuperclass.implementedTypes[0];
        s1 = mixinSuperclass.implementedTypes[1];
      } else if (mixinSuperclass.implementedTypes.length == 1) {
        s0 = mixinSuperclass.supertype!;
        s1 = mixinSuperclass.implementedTypes.first;
      } else {
        s0 = mixinSuperclass.supertype!;
        s1 = mixinSuperclass.mixedInType!;
      }
      s0 = substitution.substituteSupertype(s0);
      s1 = substitution.substituteSupertype(s1);
      generateConstraints(mixinClass, baseType, s0);
      generateConstraints(mixinClass, baseType, s1);
    } else {
      // Find the type U0 which is baseType as an instance of mixinSupertype's
      // class.
      Supertype? supertype =
          asInstantiationOf(baseType, mixinSupertype.classNode);
      if (supertype == null) {
        reportProblem(
            templateMixinInferenceNoMatchingClass.withArguments(
                mixinClass.name,
                baseType.classNode.name,
                mixinSupertype.asInterfaceType,
                mixinClass.enclosingLibrary.isNonNullableByDefault),
            mixinClass);
        return;
      }
      InterfaceType u0 = Substitution.fromSupertype(baseType)
          .substituteSupertype(supertype)
          .asInterfaceType;
      // We want to solve U0 = S0 where S0 is mixinSupertype, but we only have
      // a subtype constraints.  Solve for equality by solving
      // both U0 <: S0 and S0 <: U0.
      InterfaceType s0 = mixinSupertype.asInterfaceType;

      gatherer.tryConstrainLower(s0, u0);
      gatherer.tryConstrainUpper(s0, u0);
    }
  }

  void infer(Class classNode) {
    Supertype mixedInType = classNode.mixedInType!;
    assert(mixedInType.typeArguments.every((t) => t == const UnknownType()));
    // Note that we have no anonymous mixin applications, they have all
    // been named.  Note also that mixin composition has been translated
    // so that we only have mixin applications of the form `S with M`.
    Supertype baseType = classNode.supertype!;
    Class mixinClass = mixedInType.classNode;
    Supertype mixinSupertype = mixinClass.supertype!;
    // Generate constraints based on the mixin's supertype.
    generateConstraints(mixinClass, baseType, mixinSupertype);
    // Solve them to get a map from type parameters to upper and lower
    // bounds.
    Map<TypeParameter, TypeConstraint> result =
        gatherer.computeConstraints(classNode.enclosingLibrary);
    // Generate new type parameters with the solution as bounds.
    List<TypeParameter> parameters = mixinClass.typeParameters.map((p) {
      TypeConstraint? constraint = result[p];
      // Because we solved for equality, a valid solution has a parameter
      // either unconstrained or else with identical upper and lower bounds.
      if (constraint != null && constraint.upper != constraint.lower) {
        reportProblem(
            templateMixinInferenceNoMatchingClass.withArguments(
                mixinClass.name,
                baseType.classNode.name,
                mixinSupertype.asInterfaceType,
                mixinClass.enclosingLibrary.isNonNullableByDefault),
            mixinClass);
        return p;
      }
      assert(constraint == null || constraint.upper == constraint.lower);
      bool exact =
          constraint != null && constraint.upper != const UnknownType();
      return new TypeParameter(
          p.name, exact ? constraint.upper : p.bound, p.defaultType);
    }).toList();
    // Bounds might mention the mixin class's type parameters so we have to
    // substitute them before calling instantiate to bounds.
    Substitution substitution = Substitution.fromPairs(
        mixinClass.typeParameters,
        new List<DartType>.generate(
            parameters.length,
            (i) => new TypeParameterType.forAlphaRenaming(
                mixinClass.typeParameters[i], parameters[i])));
    for (TypeParameter p in parameters) {
      p.bound = substitution.substituteType(p.bound);
    }
    // Use instantiate to bounds.
    List<DartType> bounds = calculateBounds(
        parameters, coreTypes.objectClass, classNode.enclosingLibrary);
    for (int i = 0; i < mixedInType.typeArguments.length; ++i) {
      mixedInType.typeArguments[i] = bounds[i];
    }
  }
}

/// The result of a statement inference.
class StatementInferenceResult {
  const StatementInferenceResult();

  factory StatementInferenceResult.single(Statement statement) =
      SingleStatementInferenceResult;

  factory StatementInferenceResult.multiple(
          int fileOffset, List<Statement> statements) =
      MultipleStatementInferenceResult;

  bool get hasChanged => false;

  Statement get statement =>
      throw new UnsupportedError('StatementInferenceResult.statement');

  int get statementCount =>
      throw new UnsupportedError('StatementInferenceResult.statementCount');

  List<Statement> get statements =>
      throw new UnsupportedError('StatementInferenceResult.statements');
}

class SingleStatementInferenceResult implements StatementInferenceResult {
  @override
  final Statement statement;

  SingleStatementInferenceResult(this.statement);

  @override
  bool get hasChanged => true;

  @override
  int get statementCount => 1;

  @override
  List<Statement> get statements =>
      throw new UnsupportedError('SingleStatementInferenceResult.statements');
}

class MultipleStatementInferenceResult implements StatementInferenceResult {
  final int fileOffset;
  @override
  final List<Statement> statements;

  MultipleStatementInferenceResult(this.fileOffset, this.statements);

  @override
  bool get hasChanged => true;

  @override
  Statement get statement => new Block(statements)..fileOffset = fileOffset;

  @override
  int get statementCount => statements.length;
}

/// Tells the inferred type and how the code should be transformed.
///
/// It is intended for use by generalized inference methods, such as
/// [TypeInferrerImpl.inferInvocation], where the input [Expression] isn't
/// available for rewriting.  So, instead of transforming the code, the result
/// of the inference provides a way to transform the code at the point of
/// invocation.
abstract class InvocationInferenceResult {
  DartType get inferredType;

  DartType get functionType;

  /// Applies the result of the inference to the expression being inferred.
  ///
  /// A successful result leaves [expression] intact, and an error detected
  /// during inference would wrap the expression into an [InvalidExpression].
  Expression applyResult(Expression expression);

  /// Returns `true` if the arguments of the call where not applicable to the
  /// target.
  bool get isInapplicable;
}

class SuccessfulInferenceResult implements InvocationInferenceResult {
  @override
  final DartType inferredType;

  @override
  final FunctionType functionType;

  final List<VariableDeclaration>? hoistedArguments;

  final DartType? inferredReceiverType;

  SuccessfulInferenceResult(this.inferredType, this.functionType,
      {this.hoistedArguments, this.inferredReceiverType});

  @override
  Expression applyResult(Expression expression) {
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments == null || hoistedArguments.isEmpty) {
      return expression;
    } else {
      assert(expression is InvocationExpression);
      if (expression is FactoryConstructorInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is TypeAliasedConstructorInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is TypeAliasedFactoryInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is ConstructorInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is DynamicInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is FunctionInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is InstanceGetterInvocation) {
        // The hoisting of InstanceGetterInvocation is performed elsewhere.
        return expression;
      } else if (expression is InstanceInvocation) {
        VariableDeclaration receiver = createVariable(
            expression.receiver, inferredReceiverType ?? const DynamicType());
        expression.receiver = createVariableGet(receiver)..parent = expression;
        return createLet(
            receiver, _insertHoistedExpressions(expression, hoistedArguments));
      } else if (expression is LocalFunctionInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is StaticInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else if (expression is SuperMethodInvocation) {
        return _insertHoistedExpressions(expression, hoistedArguments);
      } else {
        throw new StateError(
            "Unhandled invocation kind '${expression.runtimeType}'.");
      }
    }
  }

  static Expression _insertHoistedExpressions(
      Expression expression, List<VariableDeclaration> hoistedExpressions) {
    if (hoistedExpressions.isNotEmpty) {
      for (int index = hoistedExpressions.length - 1; index >= 0; index--) {
        expression = createLet(hoistedExpressions[index], expression);
      }
    }
    return expression;
  }

  @override
  bool get isInapplicable => false;
}

class WrapInProblemInferenceResult implements InvocationInferenceResult {
  @override
  final DartType inferredType;

  @override
  final DartType functionType;

  final Message message;

  final int fileOffset;

  final int length;

  final InferenceHelper helper;

  @override
  final bool isInapplicable;

  WrapInProblemInferenceResult(this.inferredType, this.functionType,
      this.message, this.fileOffset, this.length, this.helper,
      {required this.isInapplicable})
      // ignore: unnecessary_null_comparison
      : assert(isInapplicable != null);

  @override
  Expression applyResult(Expression expression) {
    return helper.wrapInProblem(expression, message, fileOffset, length);
  }
}

abstract class InitializerInferenceResult {
  /// Modifies list of initializers in-place to apply the inference result.
  void applyResult(List<Initializer> initializers, TreeNode? parent);

  factory InitializerInferenceResult.fromInvocationInferenceResult(
      InvocationInferenceResult invocationInferenceResult) {
    if (invocationInferenceResult is SuccessfulInferenceResult) {
      return new SuccessfulInitializerInvocationInferenceResult
          .fromSuccessfulInferenceResult(invocationInferenceResult);
    } else {
      return new WrapInProblemInitializerInferenceResult
              .fromWrapInProblemInferenceResult(
          invocationInferenceResult as WrapInProblemInferenceResult);
    }
  }
}

class SuccessfulInitializerInferenceResult
    implements InitializerInferenceResult {
  const SuccessfulInitializerInferenceResult();

  @override
  void applyResult(List<Initializer> initializers, TreeNode? parent) {}
}

class SuccessfulInitializerInvocationInferenceResult
    implements InitializerInferenceResult {
  final DartType inferredType;

  final FunctionType functionType;

  final List<VariableDeclaration>? hoistedArguments;

  final DartType? inferredReceiverType;

  SuccessfulInitializerInvocationInferenceResult(
      {required this.inferredType,
      required this.functionType,
      required this.hoistedArguments,
      required this.inferredReceiverType});

  SuccessfulInitializerInvocationInferenceResult.fromSuccessfulInferenceResult(
      SuccessfulInferenceResult successfulInferenceResult)
      : this(
            inferredType: successfulInferenceResult.inferredType,
            functionType: successfulInferenceResult.functionType,
            hoistedArguments: successfulInferenceResult.hoistedArguments,
            inferredReceiverType:
                successfulInferenceResult.inferredReceiverType);

  @override
  void applyResult(List<Initializer> initializers, TreeNode? parent) {
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments != null && hoistedArguments.isNotEmpty) {
      for (VariableDeclaration hoistedArgument in hoistedArguments) {
        initializers.add(new LocalInitializer(hoistedArgument)
          ..parent = parent
          ..fileOffset = hoistedArgument.fileOffset);
      }
    }
  }
}

class WrapInProblemInitializerInferenceResult
    implements InitializerInferenceResult {
  WrapInProblemInitializerInferenceResult.fromWrapInProblemInferenceResult(
      WrapInProblemInferenceResult wrapInProblemInferenceResult);

  @override
  void applyResult(List<Initializer> initializers, TreeNode? parent) {}
}

/// The result of inference of a property get expression.
class PropertyGetInferenceResult {
  /// The main inference result.
  final ExpressionInferenceResult expressionInferenceResult;

  /// The property that was looked up, or `null` if no property was found.
  final Member? member;

  PropertyGetInferenceResult(this.expressionInferenceResult, this.member);
}

/// The result of an expression inference.
class ExpressionInferenceResult {
  /// The inferred type of the expression.
  final DartType inferredType;

  /// The inferred expression.
  final Expression expression;

  ExpressionInferenceResult(this.inferredType, this.expression)
      // ignore: unnecessary_null_comparison
      : assert(expression != null);

  /// The guards used for null-aware access if the expression is part of a
  /// null-shorting.
  Link<NullAwareGuard> get nullAwareGuards => const Link<NullAwareGuard>();

  /// If the expression is part of a null-shorting, this is the action performed
  /// on the guarded variable, found as the first guard in [nullAwareGuards].
  /// Otherwise, this is the same as [expression].
  Expression get nullAwareAction => expression;

  DartType get nullAwareActionType => inferredType;

  ExpressionInferenceResult stopShorting() => this;

  @override
  String toString() => 'ExpressionInferenceResult($inferredType,$expression)';
}

/// A guard used for creating null-shorting null-aware actions.
class NullAwareGuard {
  /// The variable used to guard the null-aware action.
  final VariableDeclaration _nullAwareVariable;

  /// The file offset used for the null-test.
  int _nullAwareFileOffset;

  final TypeInferrerImpl _inferrer;

  NullAwareGuard(
      this._nullAwareVariable, this._nullAwareFileOffset, this._inferrer)
      // ignore: unnecessary_null_comparison
      : assert(_nullAwareVariable != null),
        // ignore: unnecessary_null_comparison
        assert(_nullAwareFileOffset != null),
        // ignore: unnecessary_null_comparison
        assert(_inferrer != null) {
    // Ensure the initializer of [_nullAwareVariable] is promoted to
    // non-nullable.
    _inferrer.flowAnalysis.nullAwareAccess_rightBegin(
        _nullAwareVariable.initializer, _nullAwareVariable.type);
    // Ensure [_nullAwareVariable] is promoted to non-nullable.
    // TODO(johnniwinther): Avoid creating a [VariableGet] to promote the
    // variable.
    VariableGet read = new VariableGet(_nullAwareVariable);
    _inferrer.flowAnalysis.variableRead(read, _nullAwareVariable);
    _inferrer.flowAnalysis
        .nullAwareAccess_rightBegin(read, _nullAwareVariable.type);
  }

  /// Creates the null-guarded application of [nullAwareAction] with the
  /// [inferredType].
  ///
  /// For an null-aware action `v.e` on the [_nullAwareVariable] `v` the created
  /// expression is
  ///
  ///     let v in v == null ? null : v.e
  ///
  Expression createExpression(
      DartType inferredType, Expression nullAwareAction) {
    // End non-nullable promotion of [_nullAwareVariable].
    _inferrer.flowAnalysis.nullAwareAccess_end();
    // End non-nullable promotion of the initializer of [_nullAwareVariable].
    _inferrer.flowAnalysis.nullAwareAccess_end();
    Expression equalsNull = _inferrer.createEqualsNull(
        _nullAwareFileOffset, createVariableGet(_nullAwareVariable));
    ConditionalExpression condition = new ConditionalExpression(
        equalsNull,
        new NullLiteral()..fileOffset = _nullAwareFileOffset,
        nullAwareAction,
        inferredType)
      ..fileOffset = _nullAwareFileOffset;
    return new Let(_nullAwareVariable, condition)
      ..fileOffset = _nullAwareFileOffset;
  }

  @override
  String toString() =>
      'NullAwareGuard($_nullAwareVariable,$_nullAwareFileOffset)';
}

/// The result of an expression inference that is guarded with a null aware
/// variable.
class NullAwareExpressionInferenceResult implements ExpressionInferenceResult {
  /// The inferred type of the expression.
  @override
  final DartType inferredType;

  /// The inferred type of the [nullAwareAction].
  @override
  final DartType nullAwareActionType;

  @override
  final Link<NullAwareGuard> nullAwareGuards;

  @override
  final Expression nullAwareAction;

  NullAwareExpressionInferenceResult(this.inferredType,
      this.nullAwareActionType, this.nullAwareGuards, this.nullAwareAction)
      : assert(nullAwareGuards.isNotEmpty),
        // ignore: unnecessary_null_comparison
        assert(nullAwareAction != null);

  @override
  Expression get expression {
    throw new UnsupportedError('Shorting must be explicitly stopped before'
        'accessing the expression result of a '
        'NullAwareExpressionInferenceResult');
  }

  @override
  ExpressionInferenceResult stopShorting() {
    Expression expression = nullAwareAction;
    Link<NullAwareGuard> nullAwareGuard = nullAwareGuards;
    while (nullAwareGuard.isNotEmpty) {
      expression =
          nullAwareGuard.head.createExpression(inferredType, expression);
      nullAwareGuard = nullAwareGuard.tail!;
    }
    return new ExpressionInferenceResult(inferredType, expression);
  }

  @override
  String toString() =>
      'NullAwareExpressionInferenceResult($inferredType,$nullAwareGuards,'
      '$nullAwareAction)';
}

enum ObjectAccessTargetKind {
  /// A valid access to a statically known instance member on a non-nullable
  /// receiver.
  instanceMember,

  /// A potentially nullable access to a statically known instance member. This
  /// is an erroneous case and a compile-time error is reported.
  nullableInstanceMember,

  /// A valid access to a statically known instance Object member on a
  /// potentially nullable receiver.
  objectMember,

  /// A (non-nullable) access to the `.call` method of a function. This is used
  /// for access on `Function` and on function types.
  callFunction,

  /// A potentially nullable access to the `.call` method of a function. This is
  /// an erroneous case and a compile-time error is reported.
  nullableCallFunction,

  /// A valid access to an extension member.
  extensionMember,

  /// A potentially nullable access to an extension member on an extension of
  /// a non-nullable type. This is an erroneous case and a compile-time error is
  /// reported.
  nullableExtensionMember,

  /// An access on a receiver of type `dynamic`.
  dynamic,

  /// An access on a receiver of type `Never`.
  never,

  /// An access on a receiver of an invalid type. This case is the result of
  /// a previously report error and no error is report this case.
  invalid,

  /// An access to a statically unknown instance member. This is an erroneous
  /// case and a compile-time error is reported.
  missing,

  /// An access to multiple extension members, none of which are most specific.
  /// This is an erroneous case and a compile-time error is reported.
  ambiguous,
}

/// Result for performing an access on an object, like `o.foo`, `o.foo()` and
/// `o.foo = ...`.
class ObjectAccessTarget {
  final ObjectAccessTargetKind kind;
  final Member? member;

  const ObjectAccessTarget.internal(this.kind, this.member);

  /// Creates an access to the instance [member].
  factory ObjectAccessTarget.interfaceMember(Member member,
      {required bool isPotentiallyNullable}) {
    // ignore: unnecessary_null_comparison
    assert(member != null);
    // ignore: unnecessary_null_comparison
    assert(isPotentiallyNullable != null);
    return new ObjectAccessTarget.internal(
        isPotentiallyNullable
            ? ObjectAccessTargetKind.nullableInstanceMember
            : ObjectAccessTargetKind.instanceMember,
        member);
  }

  /// Creates an access to the Object [member].
  factory ObjectAccessTarget.objectMember(Member member) {
    // ignore: unnecessary_null_comparison
    assert(member != null);
    return new ObjectAccessTarget.internal(
        ObjectAccessTargetKind.objectMember, member);
  }

  /// Creates an access to the extension [member].
  factory ObjectAccessTarget.extensionMember(
      Member member,
      Member? tearoffTarget,
      ProcedureKind kind,
      List<DartType> inferredTypeArguments,
      {bool isPotentiallyNullable}) = ExtensionAccessTarget;

  /// Creates an access to a 'call' method on a function, i.e. a function
  /// invocation.
  const ObjectAccessTarget.callFunction()
      : this.internal(ObjectAccessTargetKind.callFunction, null);

  /// Creates an access to a 'call' method on a potentially nullable function,
  /// i.e. a function invocation.
  const ObjectAccessTarget.nullableCallFunction()
      : this.internal(ObjectAccessTargetKind.nullableCallFunction, null);

  /// Creates an access on a dynamic receiver type with no known target.
  const ObjectAccessTarget.dynamic()
      : this.internal(ObjectAccessTargetKind.dynamic, null);

  /// Creates an access on a receiver of type Never with no known target.
  const ObjectAccessTarget.never()
      : this.internal(ObjectAccessTargetKind.never, null);

  /// Creates an access with no target due to an invalid receiver type.
  ///
  /// This is not in itself an error but a consequence of another error.
  const ObjectAccessTarget.invalid()
      : this.internal(ObjectAccessTargetKind.invalid, null);

  /// Creates an access with no target.
  ///
  /// This is an error case.
  const ObjectAccessTarget.missing()
      : this.internal(ObjectAccessTargetKind.missing, null);

  /// Returns `true` if this is an access to an instance member.
  bool get isInstanceMember => kind == ObjectAccessTargetKind.instanceMember;

  /// Returns `true` if this is an access to an Object member.
  bool get isObjectMember => kind == ObjectAccessTargetKind.objectMember;

  /// Returns `true` if this is an access to an extension member.
  bool get isExtensionMember => kind == ObjectAccessTargetKind.extensionMember;

  /// Returns `true` if this is an access to the 'call' method on a function.
  bool get isCallFunction => kind == ObjectAccessTargetKind.callFunction;

  /// Returns `true` if this is an access to the 'call' method on a potentially
  /// nullable function.
  bool get isNullableCallFunction =>
      kind == ObjectAccessTargetKind.nullableCallFunction;

  /// Returns `true` if this is an access on a `dynamic` receiver type.
  bool get isDynamic => kind == ObjectAccessTargetKind.dynamic;

  /// Returns `true` if this is an access on a `Never` receiver type.
  bool get isNever => kind == ObjectAccessTargetKind.never;

  /// Returns `true` if this is an access on an invalid receiver type.
  bool get isInvalid => kind == ObjectAccessTargetKind.invalid;

  /// Returns `true` if this is an access with no target.
  bool get isMissing => kind == ObjectAccessTargetKind.missing;

  /// Returns `true` if this is an access with no unambiguous target. This
  /// occurs when an implicit extension access is ambiguous.
  bool get isAmbiguous => kind == ObjectAccessTargetKind.ambiguous;

  /// Returns `true` if this is an access to an instance member on a potentially
  /// nullable receiver.
  bool get isNullableInstanceMember =>
      kind == ObjectAccessTargetKind.nullableInstanceMember;

  /// Returns `true` if this is an access to an instance member on a potentially
  /// nullable receiver.
  bool get isNullableExtensionMember =>
      kind == ObjectAccessTargetKind.nullableExtensionMember;

  /// Returns `true` if this is an access to an instance member on a potentially
  /// nullable receiver.
  bool get isNullable =>
      isNullableInstanceMember ||
      isNullableCallFunction ||
      isNullableExtensionMember;

  /// Returns the candidates for an ambiguous extension access.
  List<ExtensionAccessCandidate> get candidates =>
      throw new UnsupportedError('ObjectAccessTarget.candidates');

  /// Returns the original procedure kind, if this is an extension method
  /// target.
  ///
  /// This is need because getters, setters, and methods are converted into
  /// top level methods, but access and invocation should still be treated as
  /// if they are the original procedure kind.
  ProcedureKind get extensionMethodKind =>
      throw new UnsupportedError('ObjectAccessTarget.extensionMethodKind');

  /// Returns inferred type arguments for the type parameters of an extension
  /// method that comes from the extension declaration.
  List<DartType> get inferredExtensionTypeArguments =>
      throw new UnsupportedError(
          'ObjectAccessTarget.inferredExtensionTypeArguments');

  /// Returns the member to use for a tearoff.
  ///
  /// This is currently used for extension methods.
  // TODO(johnniwinther): Normalize use by having `readTarget` and
  //  `invokeTarget`?
  Member? get tearoffTarget =>
      throw new UnsupportedError('ObjectAccessTarget.tearoffTarget');

  @override
  String toString() => 'ObjectAccessTarget($kind,$member)';
}

class ExtensionAccessTarget extends ObjectAccessTarget {
  @override
  final Member? tearoffTarget;
  @override
  final ProcedureKind extensionMethodKind;
  @override
  final List<DartType> inferredExtensionTypeArguments;

  ExtensionAccessTarget(Member member, this.tearoffTarget,
      this.extensionMethodKind, this.inferredExtensionTypeArguments,
      {bool isPotentiallyNullable: false})
      : super.internal(
            isPotentiallyNullable
                ? ObjectAccessTargetKind.nullableExtensionMember
                : ObjectAccessTargetKind.extensionMember,
            member);

  @override
  String toString() =>
      'ExtensionAccessTarget($kind,$member,$extensionMethodKind,'
      '$inferredExtensionTypeArguments)';
}

class AmbiguousExtensionAccessTarget extends ObjectAccessTarget {
  @override
  final List<ExtensionAccessCandidate> candidates;

  AmbiguousExtensionAccessTarget(this.candidates)
      : super.internal(ObjectAccessTargetKind.ambiguous, null);

  @override
  String toString() => 'AmbiguousExtensionAccessTarget($kind,$candidates)';
}

class ExtensionAccessCandidate {
  final MemberBuilder memberBuilder;
  final bool isPlatform;
  final DartType onType;
  final DartType onTypeInstantiateToBounds;
  final ObjectAccessTarget target;

  ExtensionAccessCandidate(this.memberBuilder, this.onType,
      this.onTypeInstantiateToBounds, this.target,
      {required this.isPlatform})
      // ignore: unnecessary_null_comparison
      : assert(isPlatform != null);

  bool? isMoreSpecificThan(TypeSchemaEnvironment typeSchemaEnvironment,
      ExtensionAccessCandidate other) {
    if (this.isPlatform == other.isPlatform) {
      // Both are platform or not platform.
      bool thisIsSubtype = typeSchemaEnvironment.isSubtypeOf(
          this.onType, other.onType, SubtypeCheckMode.withNullabilities);
      bool thisIsSupertype = typeSchemaEnvironment.isSubtypeOf(
          other.onType, this.onType, SubtypeCheckMode.withNullabilities);
      if (thisIsSubtype && !thisIsSupertype) {
        // This is subtype of other and not vice-versa.
        return true;
      } else if (thisIsSupertype && !thisIsSubtype) {
        // [other] is subtype of this and not vice-versa.
        return false;
      } else if (thisIsSubtype || thisIsSupertype) {
        thisIsSubtype = typeSchemaEnvironment.isSubtypeOf(
            this.onTypeInstantiateToBounds,
            other.onTypeInstantiateToBounds,
            SubtypeCheckMode.withNullabilities);
        thisIsSupertype = typeSchemaEnvironment.isSubtypeOf(
            other.onTypeInstantiateToBounds,
            this.onTypeInstantiateToBounds,
            SubtypeCheckMode.withNullabilities);
        if (thisIsSubtype && !thisIsSupertype) {
          // This is subtype of other and not vice-versa.
          return true;
        } else if (thisIsSupertype && !thisIsSubtype) {
          // [other] is subtype of this and not vice-versa.
          return false;
        }
      }
    } else if (other.isPlatform) {
      // This is not platform, [other] is: this  is more specific.
      return true;
    } else {
      // This is platform, [other] is not: other is more specific.
      return false;
    }
    // Neither is more specific than the other.
    return null;
  }
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

class InferredFunctionBody {
  final Statement body;
  final DartType? futureValueType;

  InferredFunctionBody(this.body, this.futureValueType);
}

class _WhyNotPromotedVisitor
    implements
        NonPromotionReasonVisitor<LocatedMessage?, Node, VariableDeclaration,
            DartType> {
  final TypeInferrerImpl inferrer;

  Member? propertyReference;

  DartType? propertyType;

  _WhyNotPromotedVisitor(this.inferrer);

  @override
  LocatedMessage? visitDemoteViaExplicitWrite(
      DemoteViaExplicitWrite<VariableDeclaration> reason) {
    TreeNode node = reason.node as TreeNode;
    if (inferrer.dataForTesting != null) {
      inferrer.dataForTesting!.flowAnalysisResult
          .nonPromotionReasonTargets[node] = reason.shortName;
    }
    int offset = node.fileOffset;
    return templateVariableCouldBeNullDueToWrite
        .withArguments(reason.variable.name!, reason.documentationLink)
        .withLocation(inferrer.helper!.uri, offset, noLength);
  }

  @override
  LocatedMessage? visitPropertyNotPromoted(
      PropertyNotPromoted<DartType> reason) {
    Object? member = reason.propertyMember;
    if (member is Member) {
      propertyReference = member;
      propertyType = reason.staticType;
      return templateFieldNotPromoted
          .withArguments(reason.propertyName, reason.documentationLink)
          .withLocation(member.fileUri, member.fileOffset, noLength);
    } else {
      assert(member == null,
          'Unrecognized property member: ${member.runtimeType}');
      return null;
    }
  }

  @override
  LocatedMessage visitThisNotPromoted(ThisNotPromoted reason) {
    return templateThisNotPromoted
        .withArguments(reason.documentationLink)
        .withoutLocation();
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
