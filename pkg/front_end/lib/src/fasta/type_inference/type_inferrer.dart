// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:core' hide MapEntry;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';

import 'package:kernel/ast.dart' hide Variance;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart';

import 'package:kernel/type_environment.dart';

import 'package:kernel/src/bounds_checks.dart' show calculateBounds;

import '../../base/instrumentation.dart'
    show
        Instrumentation,
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;

import '../builder/extension_builder.dart';
import '../builder/member_builder.dart';

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        Template,
        messageReturnFromVoidFunction,
        messageReturnWithoutExpression,
        messageVoidExpression,
        noLength,
        templateArgumentTypeNotAssignable,
        templateDuplicatedNamedArgument,
        templateImplicitCallOfNonMethod,
        templateInvalidAssignment,
        templateInvalidCastFunctionExpr,
        templateInvalidCastLiteralList,
        templateInvalidCastLiteralMap,
        templateInvalidCastLiteralSet,
        templateInvalidCastLocalFunction,
        templateInvalidCastNewExpr,
        templateInvalidCastStaticMethod,
        templateInvalidCastTopLevelFunction,
        templateInvokeNonFunction,
        templateMixinInferenceNoMatchingClass,
        templateUndefinedGetter,
        templateUndefinedMethod,
        templateUndefinedSetter;

import '../kernel/expression_generator.dart' show buildIsNull;

import '../kernel/kernel_shadow_ast.dart'
    show
        ShadowTypeInferenceEngine,
        ShadowTypeInferrer,
        VariableDeclarationImpl,
        getExplicitTypeArguments,
        getExtensionTypeParameterCount;

import '../kernel/type_algorithms.dart' show hasAnyTypeVariables;

import '../names.dart';

import '../problems.dart' show unexpected, unhandled;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'inference_helper.dart' show InferenceHelper;

import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;

import 'type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly, TypeInferenceEngine, Variance;

import 'type_promotion.dart' show TypePromoter;

import 'type_schema.dart' show isKnown, UnknownType;

import 'type_schema_elimination.dart' show greatestClosure;

import 'type_schema_environment.dart'
    show
        getNamedParameterType,
        getPositionalParameterType,
        TypeConstraint,
        TypeVariableEliminator,
        TypeSchemaEnvironment;

/// Given a [FunctionNode], gets the named parameter identified by [name], or
/// `null` if there is no parameter with the given name.
VariableDeclaration getNamedFormal(FunctionNode function, String name) {
  for (VariableDeclaration formal in function.namedParameters) {
    if (formal.name == name) return formal;
  }
  return null;
}

/// Given a [FunctionNode], gets the [i]th positional formal parameter, or
/// `null` if there is no parameter with that index.
VariableDeclaration getPositionalFormal(FunctionNode function, int i) {
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

/// Keeps track of information about the innermost function or closure being
/// inferred.
class ClosureContext {
  final bool isAsync;

  final bool isGenerator;

  /// The typing expectation for the subexpression of a `return` or `yield`
  /// statement inside the function.
  ///
  /// For non-generator async functions, this will be a "FutureOr" type (since
  /// it is permissible for such a function to return either a direct value or
  /// a future).
  ///
  /// For generator functions containing a `yield*` statement, the expected type
  /// for the subexpression of the `yield*` statement is the result of wrapping
  /// this typing expectation in `Stream` or `Iterator`, as appropriate.
  final DartType returnOrYieldContext;

  final DartType declaredReturnType;

  final bool _needToInferReturnType;

  /// The type that actually appeared as the subexpression of `return` or
  /// `yield` statements inside the function.
  ///
  /// For non-generator async functions, this is the "unwrapped" type (e.g. if
  /// the function is expected to return `Future<int>`, this is `int`).
  ///
  /// For generator functions containing a `yield*` statement, the type that
  /// appeared as the subexpression of the `yield*` statement was the result of
  /// wrapping this type in `Stream` or `Iterator`, as appropriate.
  DartType _inferredUnwrappedReturnOrYieldType;

  /// Whether the function is an arrow function.
  bool isArrow;

  /// A list of return statements in functions whose return type is being
  /// inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<ReturnStatement> returnStatements;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType> returnExpressionTypes;

  factory ClosureContext(TypeInferrerImpl inferrer, AsyncMarker asyncMarker,
      DartType returnContext, bool needToInferReturnType) {
    assert(returnContext != null);
    DartType declaredReturnType =
        greatestClosure(inferrer.coreTypes, returnContext);
    bool isAsync = asyncMarker == AsyncMarker.Async ||
        asyncMarker == AsyncMarker.AsyncStar;
    bool isGenerator = asyncMarker == AsyncMarker.SyncStar ||
        asyncMarker == AsyncMarker.AsyncStar;
    if (isGenerator) {
      if (isAsync) {
        returnContext = inferrer.getTypeArgumentOf(
            returnContext, inferrer.coreTypes.streamClass);
      } else {
        returnContext = inferrer.getTypeArgumentOf(
            returnContext, inferrer.coreTypes.iterableClass);
      }
    } else if (isAsync) {
      returnContext = inferrer.wrapFutureOrType(
          inferrer.typeSchemaEnvironment.unfutureType(returnContext));
    }
    return new ClosureContext._(isAsync, isGenerator, returnContext,
        declaredReturnType, needToInferReturnType);
  }

  ClosureContext._(this.isAsync, this.isGenerator, this.returnOrYieldContext,
      this.declaredReturnType, this._needToInferReturnType) {
    if (_needToInferReturnType) {
      returnStatements = [];
      returnExpressionTypes = [];
    }
  }

  bool checkValidReturn(TypeInferrerImpl inferrer, DartType returnType,
      ReturnStatement statement, DartType expressionType) {
    // The rules for valid returns for functions with return type T and possibly
    // a return expression with static type S.
    DartType flattenedReturnType = isAsync
        ? inferrer.typeSchemaEnvironment.unfutureType(returnType)
        : returnType;
    if (statement.expression == null) {
      // Sync: return; is a valid return if T is void, dynamic, or Null.
      // Async: return; is a valid return if flatten(T) is void, dynamic, or
      // Null.
      if (flattenedReturnType is VoidType ||
          flattenedReturnType is DynamicType ||
          flattenedReturnType == inferrer.coreTypes.nullType) {
        return true;
      }
      statement.expression = inferrer.helper.wrapInProblem(
          new NullLiteral()..fileOffset = statement.fileOffset,
          messageReturnWithoutExpression,
          noLength)
        ..parent = statement;
      return false;
    }

    // Arrow functions are valid if:
    // Sync: T is void or return exp; is a valid for a block-bodied function.
    // Async: flatten(T) is void or return exp; is valid for a block-bodied
    // function.
    if (isArrow && flattenedReturnType is VoidType) return true;

    // Sync: invalid if T is void and S is not void, dynamic, or Null
    // Async: invalid if T is void and flatten(S) is not void, dynamic, or Null.
    DartType flattenedExpressionType = isAsync
        ? inferrer.typeSchemaEnvironment.unfutureType(expressionType)
        : expressionType;
    if (returnType is VoidType &&
        flattenedExpressionType is! VoidType &&
        flattenedExpressionType is! DynamicType &&
        flattenedExpressionType != inferrer.coreTypes.nullType) {
      statement.expression = inferrer.helper.wrapInProblem(
          statement.expression, messageReturnFromVoidFunction, noLength)
        ..parent = statement;
      return false;
    }

    // Sync: invalid if S is void and T is not void, dynamic, or Null.
    // Async: invalid if flatten(S) is void and flatten(T) is not void, dynamic,
    // or Null.
    if (flattenedExpressionType is VoidType &&
        flattenedReturnType is! VoidType &&
        flattenedReturnType is! DynamicType &&
        flattenedReturnType != inferrer.coreTypes.nullType) {
      statement.expression = inferrer.helper
          .wrapInProblem(statement.expression, messageVoidExpression, noLength)
            ..parent = statement;
      return false;
    }

    // The caller will check that the return expression is assignable to the
    // return type.
    return true;
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  void handleReturn(TypeInferrerImpl inferrer, ReturnStatement statement,
      DartType type, bool isArrow) {
    if (isGenerator) return;
    // The first return we see tells us if we have an arrow function.
    if (this.isArrow == null) {
      this.isArrow = isArrow;
    } else {
      assert(this.isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      returnStatements.add(statement);
      returnExpressionTypes.add(type);

      // The return expression has to be assignable to the return type
      // expectation from the downwards inference context.
      if (statement.expression != null &&
          inferrer.ensureAssignable(returnOrYieldContext, type,
                  statement.expression, statement.fileOffset,
                  isReturnFromAsync: isAsync, isVoidAllowed: true) !=
              null) {
        // Not assignable, use the expectation.
        type = greatestClosure(inferrer.coreTypes, returnOrYieldContext);
      }
      DartType unwrappedType = type;
      if (isAsync) {
        unwrappedType = inferrer.typeSchemaEnvironment.unfutureType(type);
      }
      if (_inferredUnwrappedReturnOrYieldType == null) {
        _inferredUnwrappedReturnOrYieldType = unwrappedType;
      } else {
        _inferredUnwrappedReturnOrYieldType = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(
                _inferredUnwrappedReturnOrYieldType, unwrappedType);
      }
      return;
    }

    // If we are not inferring a type we can immediately check that the return
    // is valid.
    if (checkValidReturn(inferrer, declaredReturnType, statement, type) &&
        statement.expression != null) {
      inferrer.ensureAssignable(returnOrYieldContext, type,
          statement.expression, statement.fileOffset,
          isReturnFromAsync: isAsync, isVoidAllowed: true);
    }
  }

  void handleYield(TypeInferrerImpl inferrer, bool isYieldStar, DartType type,
      Expression expression, int fileOffset) {
    if (!isGenerator) return;
    DartType expectedType = isYieldStar
        ? _wrapAsyncOrGenerator(inferrer, returnOrYieldContext)
        : returnOrYieldContext;
    if (inferrer.ensureAssignable(expectedType, type, expression, fileOffset,
            isReturnFromAsync: isAsync) !=
        null) {
      type = greatestClosure(inferrer.coreTypes, expectedType);
    }
    if (_needToInferReturnType) {
      DartType unwrappedType = type;
      if (isYieldStar) {
        unwrappedType = inferrer.getDerivedTypeArgumentOf(
                type,
                isAsync
                    ? inferrer.coreTypes.streamClass
                    : inferrer.coreTypes.iterableClass) ??
            type;
      }
      if (_inferredUnwrappedReturnOrYieldType == null) {
        _inferredUnwrappedReturnOrYieldType = unwrappedType;
      } else {
        _inferredUnwrappedReturnOrYieldType = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(
                _inferredUnwrappedReturnOrYieldType, unwrappedType);
      }
    }
  }

  DartType inferReturnType(TypeInferrerImpl inferrer) {
    assert(_needToInferReturnType);
    DartType inferredType =
        inferrer.inferReturnType(_inferredUnwrappedReturnOrYieldType);
    if (!inferrer.typeSchemaEnvironment.isSubtypeOf(inferredType,
        returnOrYieldContext, SubtypeCheckMode.ignoringNullabilities)) {
      // If the inferred return type isn't a subtype of the context, we use the
      // context.
      inferredType = greatestClosure(inferrer.coreTypes, returnOrYieldContext);
    }

    inferredType = _wrapAsyncOrGenerator(inferrer, inferredType);
    for (int i = 0; i < returnStatements.length; ++i) {
      checkValidReturn(inferrer, inferredType, returnStatements[i],
          returnExpressionTypes[i]);
    }

    return inferredType;
  }

  DartType _wrapAsyncOrGenerator(TypeInferrerImpl inferrer, DartType type) {
    if (isGenerator) {
      if (isAsync) {
        return inferrer.wrapType(type, inferrer.coreTypes.streamClass);
      } else {
        return inferrer.wrapType(type, inferrer.coreTypes.iterableClass);
      }
    } else if (isAsync) {
      return inferrer.wrapFutureType(type);
    } else {
      return type;
    }
  }
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
  final CoreTypes coreTypes;

  TypeInferrer.private(this.coreTypes);

  factory TypeInferrer(
      ShadowTypeInferenceEngine engine,
      Uri uri,
      bool topLevel,
      InterfaceType thisType,
      SourceLibraryBuilder library) = ShadowTypeInferrer.private;

  SourceLibraryBuilder get library;

  /// Gets the [TypePromoter] that can be used to perform type promotion within
  /// this method body or initializer.
  TypePromoter get typePromoter;

  /// Gets the [TypeSchemaEnvironment] being used for type inference.
  TypeSchemaEnvironment get typeSchemaEnvironment;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  Uri get uri;

  /// Performs full type inference on the given field initializer.
  void inferFieldInitializer(
      InferenceHelper helper, DartType declaredType, Expression initializer);

  /// Performs type inference on the given function body.
  void inferFunctionBody(InferenceHelper helper, DartType returnType,
      AsyncMarker asyncMarker, Statement body);

  /// Performs type inference on the given constructor initializer.
  void inferInitializer(InferenceHelper helper, Initializer initializer);

  /// Performs type inference on the given metadata annotations.
  void inferMetadata(InferenceHelper helper, List<Expression> annotations);

  /// Performs type inference on the given metadata annotations keeping the
  /// existing helper if possible.
  void inferMetadataKeepingHelper(List<Expression> annotations);

  /// Performs type inference on the given function parameter initializer
  /// expression.
  void inferParameterInitializer(
      InferenceHelper helper, Expression initializer, DartType declaredType);
}

/// Derived class containing generic implementations of [TypeInferrer].
///
/// This class contains as much of the implementation of type inference as
/// possible without knowing the identity of the type parameters.  It defers to
/// abstract methods for everything else.
abstract class TypeInferrerImpl extends TypeInferrer {
  /// Marker object to indicate that a function takes an unknown number
  /// of arguments.
  static final FunctionType unknownFunction =
      new FunctionType(const [], const DynamicType());

  final TypeInferenceEngine engine;

  @override
  final Uri uri;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  final bool isTopLevel;

  final ClassHierarchy classHierarchy;

  final Instrumentation instrumentation;

  final TypeSchemaEnvironment typeSchemaEnvironment;

  final InterfaceType thisType;

  @override
  final SourceLibraryBuilder library;

  InferenceHelper helper;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  ClosureContext closureContext;

  /// The [Substitution] inferred by the last [inferInvocation], or `null` if
  /// the last invocation didn't require any inference.
  Substitution lastInferredSubstitution;

  /// The [FunctionType] of the callee in the last [inferInvocation], or `null`
  /// if the last invocation didn't require any inference.
  FunctionType lastCalleeType;

  TypeInferrerImpl.private(
      this.engine, this.uri, bool topLevel, this.thisType, this.library)
      : assert(library != null),
        classHierarchy = engine.classHierarchy,
        instrumentation = topLevel ? null : engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment,
        isTopLevel = topLevel,
        super.private(engine.coreTypes);

  /// Gets the type promoter that should be used to promote types during
  /// inference.
  TypePromoter get typePromoter;

  bool isDoubleContext(DartType typeContext) {
    // A context is a double context if double is assignable to it but int is
    // not.  That is the type context is a double context if it is:
    //   * double
    //   * FutureOr<T> where T is a double context
    //
    // We check directly, rather than using isAssignable because it's simpler.
    while (typeContext is InterfaceType &&
        typeContext.classNode == coreTypes.futureOrClass &&
        typeContext.typeArguments.isNotEmpty) {
      InterfaceType type = typeContext;
      typeContext = type.typeArguments.first;
    }
    return typeContext is InterfaceType &&
        typeContext.classNode == coreTypes.doubleClass;
  }

  bool isAssignable(DartType expectedType, DartType actualType) {
    return typeSchemaEnvironment.isSubtypeOf(
            expectedType, actualType, SubtypeCheckMode.ignoringNullabilities) ||
        typeSchemaEnvironment.isSubtypeOf(
            actualType, expectedType, SubtypeCheckMode.ignoringNullabilities);
  }

  /// Checks whether [actualType] can be assigned to the greatest closure of
  /// [expectedType], and inserts an implicit downcast if appropriate.
  Expression ensureAssignable(DartType expectedType, DartType actualType,
      Expression expression, int fileOffset,
      {bool isReturnFromAsync: false,
      bool isVoidAllowed: false,
      Template<Message Function(DartType, DartType)> template}) {
    assert(expectedType != null);
    expectedType = greatestClosure(coreTypes, expectedType);

    DartType initialExpectedType = expectedType;
    if (isReturnFromAsync && !isAssignable(expectedType, actualType)) {
      // If the body of the function is async, the expected return type has the
      // shape FutureOr<T>.  We check both branches for FutureOr here: both T
      // and Future<T>.
      DartType unfuturedExpectedType =
          typeSchemaEnvironment.unfutureType(expectedType);
      DartType futuredExpectedType = wrapFutureType(unfuturedExpectedType);
      if (isAssignable(unfuturedExpectedType, actualType)) {
        expectedType = unfuturedExpectedType;
      } else if (isAssignable(futuredExpectedType, actualType)) {
        expectedType = futuredExpectedType;
      }
    }

    // We don't need to insert assignability checks when doing top level type
    // inference since top level type inference only cares about the type that
    // is inferred (the kernel code is discarded).
    if (isTopLevel) return null;

    // If an interface type is being assigned to a function type, see if we
    // should tear off `.call`.
    // TODO(paulberry): use resolveTypeParameter.  See findInterfaceMember.
    if (actualType is InterfaceType) {
      Class classNode = (actualType as InterfaceType).classNode;
      Member callMember =
          classHierarchy.getInterfaceMember(classNode, callName);
      if (callMember is Procedure && callMember.kind == ProcedureKind.Method) {
        if (_shouldTearOffCall(expectedType, actualType)) {
          // Replace expression with:
          // `let t = expression in t == null ? null : t.call`
          TreeNode parent = expression.parent;
          VariableDeclaration t =
              new VariableDeclaration.forValue(expression, type: actualType)
                ..fileOffset = fileOffset;
          Expression nullCheck =
              buildIsNull(new VariableGet(t), fileOffset, helper);
          PropertyGet tearOff =
              new PropertyGet(new VariableGet(t), callName, callMember)
                ..fileOffset = fileOffset;
          actualType = getGetterTypeForMemberTarget(callMember, actualType);
          ConditionalExpression conditional = new ConditionalExpression(
              nullCheck,
              new NullLiteral()..fileOffset = fileOffset,
              tearOff,
              actualType);
          Let let = new Let(t, conditional)..fileOffset = fileOffset;
          parent?.replaceChild(expression, let);
          expression = let;
        }
      }
    }

    if (actualType is VoidType && !isVoidAllowed) {
      // Error: not assignable.  Perform error recovery.
      TreeNode parent = expression.parent;
      Expression errorNode =
          helper.wrapInProblem(expression, messageVoidExpression, noLength);
      parent?.replaceChild(expression, errorNode);
      return errorNode;
    }

    if (expectedType == null ||
        typeSchemaEnvironment.isSubtypeOf(
            actualType, expectedType, SubtypeCheckMode.ignoringNullabilities)) {
      // Types are compatible.
      return null;
    }

    if (!typeSchemaEnvironment.isSubtypeOf(
        expectedType, actualType, SubtypeCheckMode.ignoringNullabilities)) {
      // Error: not assignable.  Perform error recovery.
      TreeNode parent = expression.parent;
      Expression errorNode = new AsExpression(
          expression,
          // TODO(ahe): The outline phase doesn't correctly remove invalid
          // uses of type variables, for example, on static members. Once
          // that has been fixed, we should always be able to use
          // [expectedType] directly here.
          hasAnyTypeVariables(expectedType) ? const BottomType() : expectedType)
        ..isTypeError = true
        ..fileOffset = expression.fileOffset;
      if (expectedType is! InvalidType && actualType is! InvalidType) {
        errorNode = helper.wrapInProblem(
            errorNode,
            (template ?? templateInvalidAssignment)
                .withArguments(actualType, expectedType),
            noLength);
      }
      parent?.replaceChild(expression, errorNode);
      return errorNode;
    } else {
      Template<Message Function(DartType, DartType)> template =
          _getPreciseTypeErrorTemplate(expression);
      if (template != null) {
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        TreeNode parent = expression.parent;
        Expression errorNode = helper.wrapInProblem(expression,
            template.withArguments(actualType, expectedType), noLength);
        parent?.replaceChild(expression, errorNode);
        return errorNode;
      } else {
        // Insert an implicit downcast.
        TreeNode parent = expression.parent;
        AsExpression typeCheck =
            new AsExpression(expression, initialExpectedType)
              ..isTypeError = true
              ..fileOffset = fileOffset;
        parent?.replaceChild(expression, typeCheck);
        return typeCheck;
      }
    }
  }

  bool isNull(DartType type) {
    return type is InterfaceType && type.classNode == coreTypes.nullClass;
  }

  /// Computes the type arguments for an access to an extension instance member
  /// on [extension] with the static [receiverType]. If [explicitTypeArguments]
  /// are provided, these are returned, otherwise type arguments are inferred
  /// using [receiverType].
  List<DartType> computeExtensionTypeArgument(Extension extension,
      List<DartType> explicitTypeArguments, DartType receiverType) {
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
    typeSchemaEnvironment.inferGenericFunctionOrType(
        null, typeParameters, [onType], [receiverType], null, inferredTypes);
    return inferredTypes;
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
      {bool setter: false,
      bool instrumented: true,
      bool includeExtensionMethods: false}) {
    assert(receiverType != null && isKnown(receiverType));

    receiverType = resolveTypeParameter(receiverType);

    if (receiverType is FunctionType && name.name == 'call') {
      return const ObjectAccessTarget.callFunction();
    }

    Class classNode = receiverType is InterfaceType
        ? receiverType.classNode
        : coreTypes.objectClass;
    Member interfaceMember =
        _getInterfaceMember(classNode, name, setter, fileOffset);
    ObjectAccessTarget target;
    if (interfaceMember != null) {
      target = new ObjectAccessTarget.interfaceMember(interfaceMember);
    } else if (receiverType is DynamicType) {
      target = const ObjectAccessTarget.dynamic();
    } else if (receiverType is InvalidType) {
      target = const ObjectAccessTarget.invalid();
    } else if (receiverType == coreTypes.functionLegacyRawType &&
        name.name == 'call') {
      target = const ObjectAccessTarget.callFunction();
    } else {
      target = const ObjectAccessTarget.missing();
    }
    if (instrumented &&
        receiverType != const DynamicType() &&
        target.isInstanceMember) {
      instrumentation?.record(uri, fileOffset, 'target',
          new InstrumentationValueForMember(target.member));
    }

    if (target.isUnresolved &&
        receiverType is! DynamicType &&
        includeExtensionMethods) {
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

      Member otherMember =
          _getInterfaceMember(classNode, otherName, otherIsSetter, fileOffset);
      if (otherMember != null) {
        // If we're looking for `foo` and `foo=` can be found or vice-versa then
        // extension methods should not be found.
        return target;
      }

      ExtensionAccessCandidate bestSoFar;
      List<ExtensionAccessCandidate> noneMoreSpecific = [];
      library.scope.forEachExtension((ExtensionBuilder extensionBuilder) {
        MemberBuilder thisBuilder =
            extensionBuilder.lookupLocalMember(name.name, setter: setter);
        MemberBuilder otherBuilder = extensionBuilder
            .lookupLocalMember(otherName.name, setter: otherIsSetter);
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
              if (!typeSchemaEnvironment.isSubtypeOf(typeArgument, bound,
                  SubtypeCheckMode.ignoringNullabilities)) {
                return;
              }
            }
            onType = inferredSubstitution
                .substituteType(extensionBuilder.extension.onType);
            List<DartType> instantiateToBoundTypeArguments =
                calculateBounds(typeParameters, coreTypes.objectClass);
            Substitution instantiateToBoundsSubstitution =
                Substitution.fromPairs(
                    typeParameters, instantiateToBoundTypeArguments);
            onTypeInstantiateToBounds = instantiateToBoundsSubstitution
                .substituteType(extensionBuilder.extension.onType);
          }

          if (typeSchemaEnvironment.isSubtypeOf(
              receiverType, onType, SubtypeCheckMode.ignoringNullabilities)) {
            ExtensionAccessCandidate candidate = new ExtensionAccessCandidate(
                onType,
                onTypeInstantiateToBounds,
                thisBuilder != null
                    ? new ObjectAccessTarget.extensionMember(
                        thisBuilder.procedure,
                        thisBuilder.extensionTearOff,
                        thisBuilder.kind,
                        inferredTypeArguments)
                    : const ObjectAccessTarget.missing(),
                isPlatform: extensionBuilder.library.uri.scheme == 'dart');
            if (noneMoreSpecific.isNotEmpty) {
              bool isMostSpecific = true;
              for (ExtensionAccessCandidate other in noneMoreSpecific) {
                bool isMoreSpecific =
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
              bool isMoreSpecific = candidate.isMoreSpecificThan(
                  typeSchemaEnvironment, bestSoFar);
              if (isMoreSpecific == true) {
                bestSoFar = candidate;
              } else if (isMoreSpecific == null) {
                noneMoreSpecific.add(bestSoFar);
                noneMoreSpecific.add(candidate);
                bestSoFar = null;
              }
            }
          }
        }
      });
      if (bestSoFar != null) {
        target = bestSoFar.target;
      } else {
        // TODO(johnniwinther): Report a better error message when more than
        // one potential targets were found.
      }
    }
    return target;
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
  ///
  /// If no target is found on a non-dynamic receiver an error is reported
  /// using [errorTemplate] and [expression] is replaced by an invalid
  /// expression.
  ObjectAccessTarget findInterfaceMemberOrReport(
      DartType receiverType,
      Name name,
      int fileOffset,
      Template<Message Function(String, DartType)> errorTemplate,
      Expression expression,
      {bool setter: false,
      bool instrumented: true,
      bool includeExtensionMethods: false}) {
    ObjectAccessTarget target = findInterfaceMember(
        receiverType, name, fileOffset,
        setter: setter,
        instrumented: instrumented,
        includeExtensionMethods: includeExtensionMethods);

    assert(receiverType != null && isKnown(receiverType));
    if (!isTopLevel && target.isMissing && errorTemplate != null) {
      int length = name.name.length;
      if (identical(name.name, callName.name) ||
          identical(name.name, unaryMinusName.name)) {
        length = 1;
      }
      expression.parent.replaceChild(
          expression,
          helper.buildProblem(
              errorTemplate.withArguments(
                  name.name, resolveTypeParameter(receiverType)),
              fileOffset,
              length));
    }
    return target;
  }

  /// Finds a member of [receiverType] called [name] and records it in
  /// [methodInvocation].
  ObjectAccessTarget findMethodInvocationMember(
      DartType receiverType, InvocationExpression methodInvocation,
      {bool instrumented: true}) {
    // TODO(paulberry): could we add getters to InvocationExpression to make
    // these is-checks unnecessary?
    if (methodInvocation is MethodInvocation) {
      ObjectAccessTarget interfaceTarget = findInterfaceMemberOrReport(
          receiverType,
          methodInvocation.name,
          methodInvocation.fileOffset,
          templateUndefinedMethod,
          methodInvocation,
          instrumented: instrumented,
          includeExtensionMethods: true);
      if (interfaceTarget.isInstanceMember) {
        Member interfaceMember = interfaceTarget.member;
        if (receiverType == const DynamicType() &&
            interfaceMember is Procedure) {
          Arguments arguments = methodInvocation.arguments;
          FunctionNode signature = interfaceMember.function;
          if (arguments.positional.length < signature.requiredParameterCount ||
              arguments.positional.length >
                  signature.positionalParameters.length) {
            return const ObjectAccessTarget.unresolved();
          }
          for (NamedExpression argument in arguments.named) {
            if (!signature.namedParameters
                .any((declaration) => declaration.name == argument.name)) {
              return const ObjectAccessTarget.unresolved();
            }
          }
          if (instrumented && instrumentation != null) {
            instrumentation.record(uri, methodInvocation.fileOffset, 'target',
                new InstrumentationValueForMember(interfaceMember));
          }
        }
        methodInvocation.interfaceTarget = interfaceMember;
      }
      return interfaceTarget;
    } else if (methodInvocation is SuperMethodInvocation) {
      assert(receiverType != const DynamicType());
      ObjectAccessTarget interfaceTarget = findInterfaceMember(
          receiverType, methodInvocation.name, methodInvocation.fileOffset,
          instrumented: instrumented);
      if (interfaceTarget.isInstanceMember) {
        methodInvocation.interfaceTarget = interfaceTarget.member;
      }
      return interfaceTarget;
    } else {
      throw unhandled("${methodInvocation.runtimeType}",
          "findMethodInvocationMember", methodInvocation.fileOffset, uri);
    }
  }

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation and records it in [propertyGet].
  ObjectAccessTarget findPropertyGetMember(
      DartType receiverType, Expression propertyGet,
      {bool instrumented: true}) {
    // TODO(paulberry): could we add a common base class to PropertyGet and
    // SuperPropertyGet to make these is-checks unnecessary?
    if (propertyGet is PropertyGet) {
      ObjectAccessTarget readTarget = findInterfaceMemberOrReport(
          receiverType,
          propertyGet.name,
          propertyGet.fileOffset,
          templateUndefinedGetter,
          propertyGet,
          instrumented: instrumented);
      if (readTarget.isInstanceMember) {
        if (instrumented &&
            instrumentation != null &&
            receiverType == const DynamicType()) {
          instrumentation.record(uri, propertyGet.fileOffset, 'target',
              new InstrumentationValueForMember(readTarget.member));
        }
        propertyGet.interfaceTarget = readTarget.member;
      }
      return readTarget;
    } else if (propertyGet is SuperPropertyGet) {
      assert(receiverType != const DynamicType());
      ObjectAccessTarget interfaceMember = findInterfaceMember(
          receiverType, propertyGet.name, propertyGet.fileOffset,
          instrumented: instrumented);
      if (interfaceMember.isInstanceMember) {
        propertyGet.interfaceTarget = interfaceMember.member;
      }
      return interfaceMember;
    } else {
      return unhandled("${propertyGet.runtimeType}", "findPropertyGetMember",
          propertyGet.fileOffset, uri);
    }
  }

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation and records it in [propertySet].
  ObjectAccessTarget findPropertySetMember(
      DartType receiverType, Expression propertySet,
      {bool instrumented: true}) {
    if (propertySet is PropertySet) {
      ObjectAccessTarget writeTarget = findInterfaceMemberOrReport(
          receiverType,
          propertySet.name,
          propertySet.fileOffset,
          templateUndefinedSetter,
          propertySet,
          setter: true,
          instrumented: instrumented,
          includeExtensionMethods: true);
      if (writeTarget.isInstanceMember) {
        if (instrumented &&
            instrumentation != null &&
            receiverType == const DynamicType()) {
          instrumentation.record(uri, propertySet.fileOffset, 'target',
              new InstrumentationValueForMember(writeTarget.member));
        }
        propertySet.interfaceTarget = writeTarget.member;
      }
      return writeTarget;
    } else if (propertySet is SuperPropertySet) {
      assert(receiverType != const DynamicType());
      ObjectAccessTarget interfaceMember = findInterfaceMember(
          receiverType, propertySet.name, propertySet.fileOffset,
          setter: true, instrumented: instrumented);
      if (interfaceMember.isInstanceMember) {
        propertySet.interfaceTarget = interfaceMember.member;
      }
      return interfaceMember;
    } else {
      throw unhandled("${propertySet.runtimeType}", "findPropertySetMember",
          propertySet.fileOffset, uri);
    }
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
        return receiverType;
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
        return const DynamicType();
      case ObjectAccessTargetKind.instanceMember:
        return getGetterTypeForMemberTarget(target.member, receiverType);
      case ObjectAccessTargetKind.extensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            FunctionType functionType = target.member.function.functionType;
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(target.inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, target.inferredExtensionTypeArguments);
            return substitution.substituteType(new FunctionType(
                functionType.positionalParameters.skip(1).toList(),
                functionType.returnType,
                namedParameters: functionType.namedParameters,
                typeParameters: functionType.typeParameters
                    .skip(target.inferredExtensionTypeArguments.length)
                    .toList(),
                requiredParameterCount:
                    functionType.requiredParameterCount - 1));
          case ProcedureKind.Getter:
            FunctionType functionType = target.member.function.functionType;
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(target.inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, target.inferredExtensionTypeArguments);
            return substitution.substituteType(functionType.returnType);
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
            break;
        }
    }
    throw unhandled('$target', 'getGetterType', null, null);
  }

  /// Returns the getter type of [member] on a receiver of type [receiverType].
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
    Class memberClass = interfaceMember.enclosingClass;
    assert(interfaceMember is Field || interfaceMember is Procedure,
        "Unexpected interface member $interfaceMember.");
    DartType calleeType = interfaceMember.getterType;
    if (memberClass.typeParameters.isNotEmpty) {
      receiverType = resolveTypeParameter(receiverType);
      if (receiverType is InterfaceType) {
        InterfaceType castedType =
            classHierarchy.getTypeAsInstanceOf(receiverType, memberClass);
        calleeType = Substitution.fromInterfaceType(castedType)
            .substituteType(calleeType);
      }
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
      ObjectAccessTarget target, DartType receiverType, bool followCall) {
    switch (target.kind) {
      case ObjectAccessTargetKind.callFunction:
        return _getFunctionType(receiverType, followCall);
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
        return unknownFunction;
      case ObjectAccessTargetKind.instanceMember:
        return _getFunctionType(
            getGetterTypeForMemberTarget(target.member, receiverType),
            followCall);
      case ObjectAccessTargetKind.extensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            return target.member.function.functionType;
          case ProcedureKind.Getter:
            // TODO(johnniwinther): Handle implicit .call on extension getter.
            return _getFunctionType(target.member.function.returnType, false);
          case ProcedureKind.Setter:
          case ProcedureKind.Factory:
            break;
        }
    }
    throw unhandled('$target', 'getFunctionType', null, null);
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
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member, receiverType), false);
        return functionType.returnType;
        break;
      case ObjectAccessTargetKind.extensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = target.member.function.functionType;
            DartType returnType = functionType.returnType;
            if (functionType.typeParameters.isNotEmpty) {
              Substitution substitution = Substitution.fromPairs(
                  functionType.typeParameters,
                  target.inferredExtensionTypeArguments);
              return substitution.substituteType(returnType);
            }
            return returnType;
          default:
            throw unhandled('$target', 'getFunctionType', null, null);
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
        break;
    }
    return const DynamicType();
  }

  DartType getPositionalParameterTypeForTarget(
      ObjectAccessTarget target, DartType receiverType, int index) {
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member, receiverType), false);
        if (functionType.positionalParameters.length > index) {
          return functionType.positionalParameters[index];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
        FunctionType functionType = target.member.function.functionType;
        if (functionType.positionalParameters.length > index + 1) {
          DartType keyType = functionType.positionalParameters[index + 1];
          if (functionType.typeParameters.isNotEmpty) {
            Substitution substitution = Substitution.fromPairs(
                functionType.typeParameters,
                target.inferredExtensionTypeArguments);
            return substitution.substituteType(keyType);
          }
          return keyType;
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
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
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member, receiverType), false);
        if (functionType.positionalParameters.length >= 1) {
          return functionType.positionalParameters[0];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = target.member.function.functionType;
            if (functionType.positionalParameters.length >= 2) {
              DartType keyType = functionType.positionalParameters[1];
              if (functionType.typeParameters.isNotEmpty) {
                Substitution substitution = Substitution.fromPairs(
                    functionType.typeParameters,
                    target.inferredExtensionTypeArguments);
                return substitution.substituteType(keyType);
              }
              return keyType;
            }
            break;
          default:
            throw unhandled('$target', 'getFunctionType', null, null);
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
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
      ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.instanceMember:
        FunctionType functionType = _getFunctionType(
            getGetterTypeForMemberTarget(target.member, receiverType), false);
        if (functionType.positionalParameters.length >= 2) {
          return functionType.positionalParameters[1];
        }
        break;
      case ObjectAccessTargetKind.extensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Operator:
            FunctionType functionType = target.member.function.functionType;
            if (functionType.positionalParameters.length >= 3) {
              DartType indexType = functionType.positionalParameters[2];
              if (functionType.typeParameters.isNotEmpty) {
                Substitution substitution = Substitution.fromPairs(
                    functionType.typeParameters,
                    target.inferredExtensionTypeArguments);
                return substitution.substituteType(indexType);
              }
              return indexType;
            }
            break;
          default:
            throw unhandled('$target', 'getFunctionType', null, null);
        }
        break;
      case ObjectAccessTargetKind.callFunction:
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
        break;
    }
    return const DynamicType();
  }

  FunctionType _getFunctionType(DartType calleeType, bool followCall) {
    if (calleeType is FunctionType) {
      return calleeType;
    } else if (followCall && calleeType is InterfaceType) {
      Member member =
          _getInterfaceMember(calleeType.classNode, callName, false, -1);
      if (member != null) {
        DartType callType = getGetterTypeForMemberTarget(member, calleeType);
        if (callType is FunctionType) {
          return callType;
        }
      }
    }
    return unknownFunction;
  }

  DartType getDerivedTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType) {
      InterfaceType typeAsInstanceOfClass =
          classHierarchy.getTypeAsInstanceOf(type, class_);
      if (typeAsInstanceOfClass != null) {
        return typeAsInstanceOfClass.typeArguments[0];
      }
    }
    return null;
  }

  /// Gets the initializer for the given [field], or `null` if there is no
  /// initializer.
  Expression getFieldInitializer(Field field);

  /// If the [member] is a forwarding stub, return the target it forwards to.
  /// Otherwise return the given [member].
  Member getRealTarget(Member member) {
    if (member is Procedure && member.isForwardingStub) {
      return member.forwardingStubInterfaceTarget;
    }
    return member;
  }

  DartType getSetterType(ObjectAccessTarget target, DartType receiverType) {
    switch (target.kind) {
      case ObjectAccessTargetKind.unresolved:
      case ObjectAccessTargetKind.dynamic:
      case ObjectAccessTargetKind.invalid:
      case ObjectAccessTargetKind.missing:
        return const DynamicType();
      case ObjectAccessTargetKind.instanceMember:
        Member interfaceMember = target.member;
        Class memberClass = interfaceMember.enclosingClass;
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
              'getSetterType', null, null);
        }
        if (memberClass.typeParameters.isNotEmpty) {
          receiverType = resolveTypeParameter(receiverType);
          if (receiverType is InterfaceType) {
            InterfaceType castedType =
                classHierarchy.getTypeAsInstanceOf(receiverType, memberClass);
            setterType = Substitution.fromInterfaceType(castedType)
                .substituteType(setterType);
          }
        }
        return setterType;
      case ObjectAccessTargetKind.extensionMember:
        switch (target.extensionMethodKind) {
          case ProcedureKind.Setter:
            FunctionType functionType = target.member.function.functionType;
            List<TypeParameter> extensionTypeParameters = functionType
                .typeParameters
                .take(target.inferredExtensionTypeArguments.length)
                .toList();
            Substitution substitution = Substitution.fromPairs(
                extensionTypeParameters, target.inferredExtensionTypeArguments);
            return substitution
                .substituteType(functionType.positionalParameters[1]);
          case ProcedureKind.Method:
          case ProcedureKind.Getter:
          case ProcedureKind.Factory:
          case ProcedureKind.Operator:
            break;
        }
        // TODO(johnniwinther): Compute the right setter type.
        return const DynamicType();
      case ObjectAccessTargetKind.callFunction:
        break;
    }
    throw unhandled(target.runtimeType.toString(), 'getSetterType', null, null);
  }

  DartType getTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType && identical(type.classNode, class_)) {
      return type.typeArguments[0];
    } else {
      return const UnknownType();
    }
  }

  /// Adds an "as" check to a [MethodInvocation] if necessary due to
  /// contravariance.
  ///
  /// The returned expression is the [AsExpression], if one was added; otherwise
  /// it is the [MethodInvocation].
  Expression handleInvocationContravariance(
      MethodContravarianceCheckKind checkKind,
      MethodInvocation desugaredInvocation,
      Arguments arguments,
      Expression expression,
      DartType inferredType,
      FunctionType functionType,
      int fileOffset) {
    Expression expressionToReplace = desugaredInvocation ?? expression;
    switch (checkKind) {
      case MethodContravarianceCheckKind.checkMethodReturn:
        TreeNode parent = expressionToReplace.parent;
        AsExpression replacement =
            new AsExpression(expressionToReplace, inferredType)
              ..isTypeError = true
              ..fileOffset = fileOffset;
        parent.replaceChild(expressionToReplace, replacement);
        if (instrumentation != null) {
          int offset = arguments.fileOffset == -1
              ? expression.fileOffset
              : arguments.fileOffset;
          instrumentation.record(uri, offset, 'checkReturn',
              new InstrumentationValueForType(inferredType));
        }
        return replacement;
      case MethodContravarianceCheckKind.checkGetterReturn:
        TreeNode parent = expressionToReplace.parent;
        PropertyGet propertyGet = new PropertyGet(desugaredInvocation.receiver,
            desugaredInvocation.name, desugaredInvocation.interfaceTarget);
        AsExpression asExpression = new AsExpression(propertyGet, functionType)
          ..isTypeError = true
          ..fileOffset = fileOffset;
        MethodInvocation replacement = new MethodInvocation(
            asExpression, callName, desugaredInvocation.arguments);
        parent.replaceChild(expressionToReplace, replacement);
        if (instrumentation != null) {
          int offset = arguments.fileOffset == -1
              ? expression.fileOffset
              : arguments.fileOffset;
          instrumentation.record(uri, offset, 'checkGetterReturn',
              new InstrumentationValueForType(functionType));
        }
        return replacement;
      case MethodContravarianceCheckKind.none:
        break;
    }
    return expressionToReplace;
  }

  /// Add an "as" check if necessary due to contravariance.
  ///
  /// Returns the "as" check if it was added; otherwise returns the original
  /// expression.
  Expression handlePropertyGetContravariance(
      Expression receiver,
      ObjectAccessTarget readTarget,
      PropertyGet desugaredGet,
      Expression expression,
      DartType inferredType,
      int fileOffset) {
    bool checkReturn = false;
    if (receiver != null &&
        readTarget.isInstanceMember &&
        receiver is! ThisExpression) {
      Member interfaceMember = readTarget.member;
      if (interfaceMember is Procedure) {
        checkReturn = returnedTypeParametersOccurNonCovariantly(
            interfaceMember.enclosingClass,
            interfaceMember.function.returnType);
      } else if (interfaceMember is Field) {
        checkReturn = returnedTypeParametersOccurNonCovariantly(
            interfaceMember.enclosingClass, interfaceMember.type);
      }
    }
    Expression replacedExpression = desugaredGet ?? expression;
    if (checkReturn) {
      Expression expressionToReplace = replacedExpression;
      TreeNode parent = expressionToReplace.parent;
      replacedExpression = new AsExpression(expressionToReplace, inferredType)
        ..isTypeError = true
        ..fileOffset = fileOffset;
      parent.replaceChild(expressionToReplace, replacedExpression);
    }
    if (instrumentation != null && checkReturn) {
      instrumentation.record(uri, expression.fileOffset, 'checkReturn',
          new InstrumentationValueForType(inferredType));
    }
    return replacedExpression;
  }

  /// Modifies a type as appropriate when inferring a declared variable's type.
  DartType inferDeclarationType(DartType initializerType) {
    if (initializerType is BottomType ||
        (initializerType is InterfaceType &&
            initializerType.classNode == coreTypes.nullClass)) {
      // If the initializer type is Null or bottom, the inferred type is
      // dynamic.
      // TODO(paulberry): this rule is inherited from analyzer behavior but is
      // not spec'ed anywhere.
      return const DynamicType();
    }
    return initializerType;
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
  ExpressionInferenceResult inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed});

  @override
  void inferFieldInitializer(
    InferenceHelper helper,
    DartType context,
    Expression initializer,
  ) {
    assert(closureContext == null);
    assert(!isTopLevel);
    this.helper = helper;
    ExpressionInferenceResult result =
        inferExpression(initializer, context, true, isVoidAllowed: true);
    if (result.replacement != null) {
      initializer = result.replacement;
    }
    ensureAssignable(
        context, result.inferredType, initializer, initializer.fileOffset,
        isVoidAllowed: context is VoidType);
    this.helper = null;
  }

  @override
  void inferFunctionBody(InferenceHelper helper, DartType returnType,
      AsyncMarker asyncMarker, Statement body) {
    assert(closureContext == null);
    this.helper = helper;
    closureContext = new ClosureContext(this, asyncMarker, returnType, false);
    inferStatement(body);
    closureContext = null;
    this.helper = null;
  }

  DartType inferInvocation(DartType typeContext, int offset,
      FunctionType calleeType, Arguments arguments,
      {bool isOverloadedArithmeticOperator: false,
      DartType returnType,
      DartType receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false,
      bool isImplicitExtensionMember: false}) {
    assert(
        returnType == null || !containsFreeFunctionTypeVariables(returnType),
        "Return type $returnType contains free variables."
        "Provided function type: $calleeType.");
    int extensionTypeParameterCount = getExtensionTypeParameterCount(arguments);
    if (extensionTypeParameterCount != 0) {
      assert(returnType == null,
          "Unexpected explicit return type for extension method invocation.");
      return _inferGenericExtensionMethodInvocation(extensionTypeParameterCount,
          typeContext, offset, calleeType, arguments,
          isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
          receiverType: receiverType,
          skipTypeArgumentInference: skipTypeArgumentInference,
          isConst: isConst,
          isImplicitExtensionMember: isImplicitExtensionMember);
    }
    return _inferInvocation(typeContext, offset, calleeType, arguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        receiverType: receiverType,
        returnType: returnType,
        skipTypeArgumentInference: skipTypeArgumentInference,
        isConst: isConst,
        isImplicitExtensionMember: isImplicitExtensionMember);
  }

  DartType _inferGenericExtensionMethodInvocation(
      int extensionTypeParameterCount,
      DartType typeContext,
      int offset,
      FunctionType calleeType,
      Arguments arguments,
      {bool isOverloadedArithmeticOperator: false,
      DartType receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false,
      bool isImplicitExtensionMember: false}) {
    FunctionType extensionFunctionType = new FunctionType(
        [calleeType.positionalParameters.first], const DynamicType(),
        requiredParameterCount: 1,
        typeParameters: calleeType.typeParameters
            .take(extensionTypeParameterCount)
            .toList());
    Arguments extensionArguments = helper.forest.createArguments(
        arguments.fileOffset, [arguments.positional.first],
        types: getExplicitExtensionTypeArguments(arguments));
    _inferInvocation(
        const UnknownType(), offset, extensionFunctionType, extensionArguments,
        skipTypeArgumentInference: skipTypeArgumentInference,
        receiverType: receiverType,
        isImplicitExtensionMember: isImplicitExtensionMember);
    Substitution extensionSubstitution = Substitution.fromPairs(
        extensionFunctionType.typeParameters, extensionArguments.types);

    List<TypeParameter> targetTypeParameters = const <TypeParameter>[];
    if (calleeType.typeParameters.length > extensionTypeParameterCount) {
      targetTypeParameters =
          calleeType.typeParameters.skip(extensionTypeParameterCount).toList();
    }
    FunctionType targetFunctionType = new FunctionType(
        calleeType.positionalParameters.skip(1).toList(), calleeType.returnType,
        requiredParameterCount: calleeType.requiredParameterCount - 1,
        namedParameters: calleeType.namedParameters,
        typeParameters: targetTypeParameters);
    targetFunctionType =
        extensionSubstitution.substituteType(targetFunctionType);
    Arguments targetArguments = helper.forest.createArguments(
        arguments.fileOffset, arguments.positional.skip(1).toList(),
        named: arguments.named, types: getExplicitTypeArguments(arguments));
    DartType inferredType = _inferInvocation(
        typeContext, offset, targetFunctionType, targetArguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        skipTypeArgumentInference: skipTypeArgumentInference,
        isConst: isConst);
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
    return inferredType;
  }

  /// Performs the type inference steps that are shared by all kinds of
  /// invocations (constructors, instance methods, and static methods).
  DartType _inferInvocation(DartType typeContext, int offset,
      FunctionType calleeType, Arguments arguments,
      {bool isOverloadedArithmeticOperator: false,
      bool isBinaryOperator: false,
      DartType receiverType,
      DartType returnType,
      bool skipTypeArgumentInference: false,
      bool isConst: false,
      bool isImplicitExtensionMember: false}) {
    assert(
        returnType == null || !containsFreeFunctionTypeVariables(returnType),
        "Return type $returnType contains free variables."
        "Provided function type: $calleeType.");
    lastInferredSubstitution = null;
    lastCalleeType = null;
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
      if (returnType != null) {
        returnType = fresh.substitute(returnType);
      }
      calleeTypeParameters = fresh.freshTypeParameters;
    }
    List<DartType> explicitTypeArguments = getExplicitTypeArguments(arguments);
    bool inferenceNeeded = !skipTypeArgumentInference &&
        explicitTypeArguments == null &&
        calleeTypeParameters.isNotEmpty;
    bool typeChecksNeeded = !isTopLevel;
    List<DartType> inferredTypes;
    Substitution substitution;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }
    if (inferenceNeeded) {
      if (isConst && typeContext != null) {
        typeContext =
            new TypeVariableEliminator(coreTypes).substituteType(typeContext);
      }
      inferredTypes = new List<DartType>.filled(
          calleeTypeParameters.length, const UnknownType());
      typeSchemaEnvironment.inferGenericFunctionOrType(
          returnType ?? calleeType.returnType,
          calleeTypeParameters,
          null,
          null,
          typeContext,
          inferredTypes);
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
    // TODO(paulberry): if we are doing top level inference and type arguments
    // were omitted, report an error.
    int i = 0;
    _forEachArgument(arguments, (name, expression) {
      DartType formalType = name != null
          ? getNamedParameterType(calleeType, name)
          : getPositionalParameterType(calleeType, i++);
      DartType inferredFormalType = substitution != null
          ? substitution.substituteType(formalType)
          : formalType;
      DartType inferredType;
      if (isImplicitExtensionMember && i == 1) {
        assert(
            receiverType != null,
            "No receiver type provided for implicit extension member "
            "invocation.");
        inferredType = receiverType;
      } else {
        ExpressionInferenceResult result = inferExpression(
            expression,
            inferredFormalType,
            inferenceNeeded ||
                isOverloadedArithmeticOperator ||
                typeChecksNeeded);
        inferredType = result.inferredType;
      }
      if (inferenceNeeded || typeChecksNeeded) {
        formalTypes.add(formalType);
        actualTypes.add(inferredType);
      }
      if (isOverloadedArithmeticOperator) {
        returnType = typeSchemaEnvironment.getTypeOfOverloadedArithmetic(
            receiverType, inferredType);
      }
    });

    // Check for and remove duplicated named arguments.
    List<NamedExpression> named = arguments.named;
    if (named.length == 2) {
      if (named[0].name == named[1].name) {
        String name = named[1].name;
        Expression error = helper.buildProblem(
            templateDuplicatedNamedArgument.withArguments(name),
            named[1].fileOffset,
            name.length);
        arguments.named = [new NamedExpression(named[1].name, error)];
        formalTypes.removeLast();
        actualTypes.removeLast();
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
          NamedExpression prevNamedExpression = seenNames[name];
          prevNamedExpression.value = helper.buildProblem(
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
    }

    if (inferenceNeeded) {
      typeSchemaEnvironment.inferGenericFunctionOrType(
          returnType ?? calleeType.returnType,
          calleeTypeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      substitution =
          Substitution.fromPairs(calleeTypeParameters, inferredTypes);
      instrumentation?.record(uri, offset, 'typeArgs',
          new InstrumentationValueForTypeArgs(inferredTypes));
      arguments.types.clear();
      arguments.types.addAll(inferredTypes);
    }
    if (typeChecksNeeded && !identical(calleeType, unknownFunction)) {
      LocatedMessage argMessage =
          helper.checkArgumentsForType(calleeType, arguments, offset);
      if (argMessage != null) {
        helper.addProblem(
            argMessage.messageObject, argMessage.charOffset, argMessage.length);
      } else {
        // Argument counts and names match. Compare types.
        int numPositionalArgs = arguments.positional.length;
        for (int i = 0; i < formalTypes.length; i++) {
          DartType formalType = formalTypes[i];
          DartType expectedType = substitution != null
              ? substitution.substituteType(formalType)
              : formalType;
          DartType actualType = actualTypes[i];
          Expression expression = i < numPositionalArgs
              ? arguments.positional[i]
              : arguments.named[i - numPositionalArgs].value;
          ensureAssignable(
              expectedType, actualType, expression, expression.fileOffset,
              isVoidAllowed: expectedType is VoidType,
              // TODO(johnniwinther): Specialize message for operator
              // invocations.
              template: templateArgumentTypeNotAssignable);
        }
      }
    }
    DartType inferredType;
    lastInferredSubstitution = substitution;
    lastCalleeType = calleeType;
    if (returnType != null) {
      inferredType = substitution == null
          ? returnType
          : substitution.substituteType(returnType);
    } else {
      if (substitution != null) {
        calleeType =
            substitution.substituteType(calleeType.withoutTypeParameters);
      }
      inferredType = calleeType.returnType;
    }
    assert(
        !containsFreeFunctionTypeVariables(inferredType),
        "Inferred return type $inferredType contains free variables."
        "Inferred function type: $calleeType.");
    return inferredType;
  }

  DartType inferLocalFunction(FunctionNode function, DartType typeContext,
      int fileOffset, DartType returnContext) {
    bool hasImplicitReturnType = false;
    if (returnContext == null) {
      hasImplicitReturnType = true;
      returnContext = const DynamicType();
    }
    if (!isTopLevel) {
      List<VariableDeclaration> positionalParameters =
          function.positionalParameters;
      for (int i = 0; i < positionalParameters.length; i++) {
        VariableDeclaration parameter = positionalParameters[i];
        inferMetadataKeepingHelper(parameter.annotations);
        if (parameter.initializer != null) {
          inferExpression(parameter.initializer, parameter.type, !isTopLevel);
        }
      }
      for (VariableDeclaration parameter in function.namedParameters) {
        inferMetadataKeepingHelper(parameter.annotations);
        inferExpression(parameter.initializer, parameter.type, !isTopLevel);
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
    List<DartType> formalTypesFromContext =
        new List<DartType>.filled(formals.length, null);
    if (typeContext is FunctionType) {
      for (int i = 0; i < formals.length; i++) {
        if (i < function.positionalParameters.length) {
          formalTypesFromContext[i] =
              getPositionalParameterType(typeContext, i);
        } else {
          formalTypesFromContext[i] =
              getNamedParameterType(typeContext, formals[i].name);
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
                ? new TypeParameterType(typeParameters[i])
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
      VariableDeclarationImpl formal = formals[i];
      if (VariableDeclarationImpl.isImplicitlyTyped(formal)) {
        DartType inferredType;
        if (formalTypesFromContext[i] == coreTypes.nullType) {
          inferredType = coreTypes.objectRawType(library.nullable);
        } else if (formalTypesFromContext[i] != null) {
          inferredType = greatestClosure(coreTypes,
              substitution.substituteType(formalTypesFromContext[i]));
        } else {
          inferredType = const DynamicType();
        }
        instrumentation?.record(uri, formal.fileOffset, 'type',
            new InstrumentationValueForType(inferredType));
        formal.type = inferredType;
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
    ClosureContext oldClosureContext = this.closureContext;
    ClosureContext closureContext = new ClosureContext(
        this, function.asyncMarker, returnContext, needToSetReturnType);
    this.closureContext = closureContext;
    inferStatement(function.body);

    // If the closure is declared with `async*` or `sync*`, let `M` be the
    // least upper bound of the types of the `yield` expressions in `B’`, or
    // `void` if `B’` contains no `yield` expressions.  Otherwise, let `M` be
    // the least upper bound of the types of the `return` expressions in `B’`,
    // or `void` if `B’` contains no `return` expressions.
    DartType inferredReturnType;
    if (needToSetReturnType) {
      inferredReturnType = closureContext.inferReturnType(this);
    }

    // Then the result of inference is `<T0, ..., Tn>(R0 x0, ..., Rn xn) B` with
    // type `<T0, ..., Tn>(R0, ..., Rn) -> M’` (with some of the `Ri` and `xi`
    // denoted as optional or named parameters, if appropriate).
    if (needToSetReturnType) {
      instrumentation?.record(uri, fileOffset, 'returnType',
          new InstrumentationValueForType(inferredReturnType));
      function.returnType = inferredReturnType;
    }
    this.closureContext = oldClosureContext;
    return function.functionType;
  }

  @override
  void inferMetadata(InferenceHelper helper, List<Expression> annotations) {
    if (annotations != null) {
      this.helper = helper;
      inferMetadataKeepingHelper(annotations);
      this.helper = null;
    }
  }

  @override
  void inferMetadataKeepingHelper(List<Expression> annotations) {
    if (annotations != null) {
      // Place annotations in a temporary list literal so that they will have a
      // parent.  This is necessary in case any of the annotations need to get
      // replaced during type inference.
      List<TreeNode> parents = annotations.map((e) => e.parent).toList();
      new ListLiteral(annotations);
      for (Expression annotation in annotations) {
        inferExpression(annotation, const UnknownType(), !isTopLevel);
      }
      for (int i = 0; i < annotations.length; ++i) {
        annotations[i].parent = parents[i];
      }
    }
  }

  StaticInvocation transformExtensionMethodInvocation(ObjectAccessTarget target,
      Expression expression, Expression receiver, Arguments arguments) {
    assert(target.isExtensionMember);
    Procedure procedure = target.member;
    Expression replacement;
    expression.parent.replaceChild(
        expression,
        replacement = helper.forest.createStaticInvocation(
            expression.fileOffset,
            target.member,
            arguments = helper.forest.createArgumentsForExtensionMethod(
                arguments.fileOffset,
                target.inferredExtensionTypeArguments.length,
                procedure.function.typeParameters.length -
                    target.inferredExtensionTypeArguments.length,
                receiver,
                extensionTypeArguments: target.inferredExtensionTypeArguments,
                positionalArguments: arguments.positional,
                namedArguments: arguments.named,
                typeArguments: arguments.types)));
    return replacement;
  }

  /// Performs the core type inference algorithm for method invocations (this
  /// handles both null-aware and non-null-aware method invocations).
  ExpressionInferenceResult inferMethodInvocation(
      MethodInvocationImpl node, DartType typeContext) {
    // First infer the receiver so we can look up the method that was invoked.
    ExpressionInferenceResult result =
        inferExpression(node.receiver, const UnknownType(), true);
    DartType receiverType = result.inferredType;
    ObjectAccessTarget target = findMethodInvocationMember(receiverType, node);
    Name methodName = node.name;
    Arguments arguments = node.arguments;
    assert(target != null, "No target for ${node}.");
    bool isOverloadedArithmeticOperator =
        isOverloadedArithmeticOperatorAndType(target, receiverType);
    DartType calleeType = getGetterType(target, receiverType);
    FunctionType functionType =
        getFunctionType(target, receiverType, !node.isImplicitCall);

    if (!target.isUnresolved &&
        calleeType is! DynamicType &&
        !(calleeType is InterfaceType &&
            calleeType.classNode == coreTypes.functionClass) &&
        identical(functionType, unknownFunction)) {
      TreeNode parent = node.parent;
      Expression error = helper.wrapInProblem(node,
          templateInvokeNonFunction.withArguments(methodName.name), noLength);
      parent?.replaceChild(node, error);
      return const ExpressionInferenceResult(const DynamicType());
    }
    MethodContravarianceCheckKind checkKind = preCheckInvocationContravariance(
        receiverType, target,
        isThisReceiver: node.receiver is ThisExpression);
    StaticInvocation replacement;
    if (target.isExtensionMember) {
      replacement = transformExtensionMethodInvocation(
          target, node, node.receiver, arguments);
      arguments = replacement.arguments;
    }
    DartType inferredType = inferInvocation(
        typeContext, node.fileOffset, functionType, arguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        receiverType: receiverType,
        isImplicitExtensionMember: target.isExtensionMember);
    if (methodName.name == '==') {
      inferredType = coreTypes.boolRawType(library.nonNullable);
    }
    handleInvocationContravariance(checkKind, node, arguments, node,
        inferredType, functionType, node.fileOffset);
    if (node.isImplicitCall && target.isInstanceMember) {
      Member member = target.member;
      if (!(member is Procedure && member.kind == ProcedureKind.Method)) {
        TreeNode parent = node.parent;
        Expression errorNode = helper.wrapInProblem(
            node,
            templateImplicitCallOfNonMethod.withArguments(receiverType),
            noLength);
        parent?.replaceChild(node, errorNode);
      }
    }
    if (target.isExtensionMember) {
      library.checkBoundsInStaticInvocation(
          replacement, typeSchemaEnvironment, helper.uri);
    } else {
      _checkBoundsInMethodInvocation(target, receiverType, calleeType,
          methodName, arguments, node.fileOffset);
    }

    return new ExpressionInferenceResult(inferredType, replacement);
  }

  void _checkBoundsInMethodInvocation(
      ObjectAccessTarget target,
      DartType receiverType,
      DartType calleeType,
      Name methodName,
      Arguments arguments,
      int fileOffset) {
    // If [arguments] were inferred, check them.
    // TODO(dmitryas): Figure out why [library] is sometimes null? Answer:
    // because top level inference never got a library. This has changed so
    // we always have a library. Should we still skip this for top level
    // inference?
    if (!isTopLevel) {
      // [actualReceiverType], [interfaceTarget], and [actualMethodName] below
      // are for a workaround for the cases like the following:
      //
      //     class C1 { var f = new C2(); }
      //     class C2 { int call<X extends num>(X x) => 42; }
      //     main() { C1 c = new C1(); c.f("foobar"); }
      DartType actualReceiverType;
      Member interfaceTarget;
      Name actualMethodName;
      if (calleeType is InterfaceType) {
        actualReceiverType = calleeType;
        interfaceTarget = null;
        actualMethodName = callName;
      } else {
        actualReceiverType = receiverType;
        interfaceTarget = target.isInstanceMember ? target.member : null;
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
          helper.uri,
          fileOffset,
          inferred: getExplicitTypeArguments(arguments) == null);
    }
  }

  bool isOverloadedArithmeticOperatorAndType(
      ObjectAccessTarget target, DartType receiverType) {
    return target.isInstanceMember &&
        target.member is Procedure &&
        typeSchemaEnvironment.isOverloadedArithmeticOperatorAndType(
            target.member, receiverType);
  }

  /// Performs the core type inference algorithm for super method invocations.
  ExpressionInferenceResult inferSuperMethodInvocation(
      SuperMethodInvocation expression,
      DartType typeContext,
      ObjectAccessTarget target) {
    int fileOffset = expression.fileOffset;
    Name methodName = expression.name;
    Arguments arguments = expression.arguments;
    DartType receiverType = thisType;
    bool isOverloadedArithmeticOperator =
        isOverloadedArithmeticOperatorAndType(target, receiverType);
    DartType calleeType = getGetterType(target, receiverType);
    FunctionType functionType = getFunctionType(target, receiverType, true);

    if (!target.isUnresolved &&
        calleeType is! DynamicType &&
        !(calleeType is InterfaceType &&
            calleeType.classNode == coreTypes.functionClass) &&
        identical(functionType, unknownFunction)) {
      TreeNode parent = expression.parent;
      Expression error = helper.wrapInProblem(expression,
          templateInvokeNonFunction.withArguments(methodName.name), noLength);
      parent?.replaceChild(expression, error);
      return const ExpressionInferenceResult(const DynamicType());
    }
    DartType inferredType = inferInvocation(
        typeContext, fileOffset, functionType, arguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        receiverType: receiverType,
        isImplicitExtensionMember: target.isExtensionMember);
    if (methodName.name == '==') {
      inferredType = coreTypes.boolRawType(library.nonNullable);
    }
    _checkBoundsInMethodInvocation(
        target, receiverType, calleeType, methodName, arguments, fileOffset);

    return new ExpressionInferenceResult(inferredType);
  }

  @override
  void inferParameterInitializer(
      InferenceHelper helper, Expression initializer, DartType declaredType) {
    assert(closureContext == null);
    this.helper = helper;
    assert(declaredType != null);
    ExpressionInferenceResult result =
        inferExpression(initializer, declaredType, true);
    if (result.replacement != null) {
      initializer = result.replacement;
    }
    ensureAssignable(
        declaredType, result.inferredType, initializer, initializer.fileOffset);
    this.helper = null;
  }

  /// Performs the core type inference algorithm for property gets (this handles
  /// both null-aware and non-null-aware property gets).
  ExpressionInferenceResult inferPropertyGet(
      Expression expression,
      Expression receiver,
      int fileOffset,
      DartType typeContext,
      PropertyGet propertyGet,
      {VariableDeclaration nullAwareReceiverVariable}) {
    // First infer the receiver so we can look up the getter that was invoked.
    DartType receiverType;
    if (receiver == null) {
      receiverType = thisType;
    } else {
      ExpressionInferenceResult result =
          inferExpression(receiver, const UnknownType(), true);
      if (result.replacement != null) {
        receiver = result.replacement;
      }
      receiverType = result.inferredType;
    }
    nullAwareReceiverVariable?.type = receiverType;
    Name propertyName = propertyGet.name;
    ObjectAccessTarget readTarget = findInterfaceMemberOrReport(receiverType,
        propertyName, fileOffset, templateUndefinedGetter, expression,
        includeExtensionMethods: true);
    if (readTarget.isInstanceMember) {
      if (instrumentation != null && receiverType == const DynamicType()) {
        instrumentation.record(uri, propertyGet.fileOffset, 'target',
            new InstrumentationValueForMember(readTarget.member));
      }
      propertyGet.interfaceTarget = readTarget.member;
    }
    DartType inferredType = getGetterType(readTarget, receiverType);
    Expression replacedExpression = handlePropertyGetContravariance(receiver,
        readTarget, propertyGet, expression, inferredType, fileOffset);
    Expression replacement;
    if (readTarget.isInstanceMember) {
      Member member = readTarget.member;
      if (member is Procedure && member.kind == ProcedureKind.Method) {
        inferredType =
            instantiateTearOff(inferredType, typeContext, replacedExpression);
      }
    } else if (readTarget.isExtensionMember) {
      int fileOffset = expression.fileOffset;
      switch (readTarget.extensionMethodKind) {
        case ProcedureKind.Getter:
          expression.parent.replaceChild(
              expression,
              replacement = expression = helper.forest.createStaticInvocation(
                  fileOffset,
                  readTarget.member,
                  helper.forest.createArgumentsForExtensionMethod(
                      fileOffset,
                      readTarget.inferredExtensionTypeArguments.length,
                      0,
                      receiver,
                      extensionTypeArguments:
                          readTarget.inferredExtensionTypeArguments)));
          break;
        case ProcedureKind.Method:
          expression.parent.replaceChild(
              expression,
              replacement = expression = helper.forest.createStaticInvocation(
                  fileOffset,
                  readTarget.tearoffTarget,
                  helper.forest.createArgumentsForExtensionMethod(
                      fileOffset,
                      readTarget.inferredExtensionTypeArguments.length,
                      0,
                      receiver,
                      extensionTypeArguments:
                          readTarget.inferredExtensionTypeArguments)));
          inferredType =
              instantiateTearOff(inferredType, typeContext, expression);
          break;
        case ProcedureKind.Setter:
        case ProcedureKind.Factory:
        case ProcedureKind.Operator:
          unhandled('$readTarget', "inferPropertyGet", fileOffset, uri);
          break;
      }
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  /// Performs the core type inference algorithm for super property get.
  ExpressionInferenceResult inferSuperPropertyGet(SuperPropertyGet expression,
      DartType typeContext, ObjectAccessTarget readTarget) {
    DartType receiverType = thisType;
    DartType inferredType = getGetterType(readTarget, receiverType);
    Expression replacement;
    if (readTarget.isInstanceMember) {
      Member member = readTarget.member;
      if (member is Procedure && member.kind == ProcedureKind.Method) {
        inferredType =
            instantiateTearOff(inferredType, typeContext, expression);
      }
    }
    return new ExpressionInferenceResult(inferredType, replacement);
  }

  /// Modifies a type as appropriate when inferring a closure return type.
  DartType inferReturnType(DartType returnType) {
    return returnType ?? typeSchemaEnvironment.nullType;
  }

  /// Performs type inference on the given [statement].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the statement type and calls the appropriate specialized "infer" method.
  void inferStatement(Statement statement);

  /// Performs the type inference steps necessary to instantiate a tear-off
  /// (if necessary).
  DartType instantiateTearOff(
      DartType tearoffType, DartType context, Expression expression) {
    if (tearoffType is FunctionType &&
        context is FunctionType &&
        context.typeParameters.isEmpty) {
      List<TypeParameter> typeParameters = tearoffType.typeParameters;
      if (typeParameters.isNotEmpty) {
        List<DartType> inferredTypes = new List<DartType>.filled(
            typeParameters.length, const UnknownType());
        FunctionType instantiatedType = tearoffType.withoutTypeParameters;
        typeSchemaEnvironment.inferGenericFunctionOrType(
            instantiatedType, typeParameters, [], [], context, inferredTypes);
        if (!isTopLevel) {
          TreeNode parent = expression.parent;
          parent.replaceChild(
              expression,
              new Instantiation(expression, inferredTypes)
                ..fileOffset = expression.fileOffset);
        }
        Substitution substitution =
            Substitution.fromPairs(typeParameters, inferredTypes);
        return substitution.substituteType(instantiatedType);
      }
    }
    return tearoffType;
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
      {bool isThisReceiver}) {
    assert(isThisReceiver != null);
    if (target.isInstanceMember) {
      Member interfaceMember = target.member;
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
                      interfaceMember.enclosingClass, interfaceMember.type)) ||
              (interfaceMember is Procedure &&
                  returnedTypeParametersOccurNonCovariantly(
                      interfaceMember.enclosingClass,
                      interfaceMember.function.returnType))) {
            return MethodContravarianceCheckKind.checkGetterReturn;
          }
        }
      } else if (!isThisReceiver &&
          interfaceMember is Procedure &&
          returnedTypeParametersOccurNonCovariantly(
              interfaceMember.enclosingClass,
              interfaceMember.function.returnType)) {
        return MethodContravarianceCheckKind.checkMethodReturn;
      }
    }
    return MethodContravarianceCheckKind.none;
  }

  /// If the given [type] is a [TypeParameterType], resolve it to its bound.
  DartType resolveTypeParameter(DartType type) {
    DartType resolveOneStep(DartType type) {
      if (type is TypeParameterType) {
        return type.bound;
      } else {
        return null;
      }
    }

    DartType resolved = resolveOneStep(type);
    if (resolved == null) return type;

    // Detect circularities using the tortoise-and-hare algorithm.
    type = resolved;
    DartType hare = resolveOneStep(type);
    if (hare == null) return type;
    while (true) {
      if (identical(type, hare)) {
        // We found a circularity.  Give up and return `dynamic`.
        return const DynamicType();
      }

      // Hare takes two steps
      DartType step1 = resolveOneStep(hare);
      if (step1 == null) return hare;
      DartType step2 = resolveOneStep(step1);
      if (step2 == null) return hare;
      hare = step2;

      // Tortoise takes one step
      type = resolveOneStep(type);
    }
  }

  DartType wrapFutureOrType(DartType type) {
    if (type is InterfaceType &&
        identical(type.classNode, coreTypes.futureOrClass)) {
      return type;
    }
    // TODO(paulberry): If [type] is a subtype of `Future`, should we just
    // return it unmodified?
    return new InterfaceType(
        coreTypes.futureOrClass, <DartType>[type ?? const DynamicType()]);
  }

  DartType wrapFutureType(DartType type) {
    DartType typeWithoutFutureOr = type ?? const DynamicType();
    return new InterfaceType(
        coreTypes.futureClass, <DartType>[typeWithoutFutureOr]);
  }

  DartType wrapType(DartType type, Class class_) {
    return new InterfaceType(class_, <DartType>[type ?? const DynamicType()]);
  }

  void _forEachArgument(
      Arguments arguments, void callback(String name, Expression expression)) {
    for (Expression expression in arguments.positional) {
      callback(null, expression);
    }
    for (NamedExpression namedExpression in arguments.named) {
      callback(namedExpression.name, namedExpression.value);
    }
  }

  Member _getInterfaceMember(
      Class class_, Name name, bool setter, int charOffset) {
    Member member = engine.hierarchyBuilder.getCombinedMemberSignatureKernel(
        class_, name, setter, charOffset, library);
    if (member == null && library.isPatch) {
      // TODO(dmitryas): Hack for parts.
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
  Template<Message Function(DartType, DartType)> _getPreciseTypeErrorTemplate(
      Expression expression) {
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
    if (expression is VariableGet) {
      VariableDeclaration variable = expression.variable;
      if (variable is VariableDeclarationImpl &&
          VariableDeclarationImpl.isLocalFunction(variable)) {
        return templateInvalidCastLocalFunction;
      }
    }
    return null;
  }

  bool _shouldTearOffCall(DartType expectedType, DartType actualType) {
    if (expectedType is InterfaceType &&
        expectedType.classNode == typeSchemaEnvironment.futureOrClass) {
      expectedType = (expectedType as InterfaceType).typeArguments[0];
    }
    if (expectedType is FunctionType) return true;
    if (expectedType == typeSchemaEnvironment.functionLegacyRawType) {
      if (!typeSchemaEnvironment.isSubtypeOf(
          actualType, expectedType, SubtypeCheckMode.ignoringNullabilities)) {
        return true;
      }
    }
    return false;
  }
}

abstract class MixinInferrer {
  final CoreTypes coreTypes;
  final TypeConstraintGatherer gatherer;

  MixinInferrer(this.coreTypes, this.gatherer);

  Supertype asInstantiationOf(Supertype type, Class superclass);

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
        s0 = mixinSuperclass.supertype;
        s1 = mixinSuperclass.implementedTypes.first;
      } else {
        s0 = mixinSuperclass.supertype;
        s1 = mixinSuperclass.mixedInType;
      }
      s0 = substitution.substituteSupertype(s0);
      s1 = substitution.substituteSupertype(s1);
      generateConstraints(mixinClass, baseType, s0);
      generateConstraints(mixinClass, baseType, s1);
    } else {
      // Find the type U0 which is baseType as an instance of mixinSupertype's
      // class.
      Supertype supertype =
          asInstantiationOf(baseType, mixinSupertype.classNode);
      if (supertype == null) {
        reportProblem(
            templateMixinInferenceNoMatchingClass.withArguments(mixinClass.name,
                baseType.classNode.name, mixinSupertype.asInterfaceType),
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
      gatherer.trySubtypeMatch(u0, s0);
      gatherer.trySubtypeMatch(s0, u0);
    }
  }

  void infer(Class classNode) {
    Supertype mixedInType = classNode.mixedInType;
    assert(mixedInType.typeArguments.every((t) => t == const UnknownType()));
    // Note that we have no anonymous mixin applications, they have all
    // been named.  Note also that mixin composition has been translated
    // so that we only have mixin applications of the form `S with M`.
    Supertype baseType = classNode.supertype;
    Class mixinClass = mixedInType.classNode;
    Supertype mixinSupertype = mixinClass.supertype;
    // Generate constraints based on the mixin's supertype.
    generateConstraints(mixinClass, baseType, mixinSupertype);
    // Solve them to get a map from type parameters to upper and lower
    // bounds.
    Map<TypeParameter, TypeConstraint> result = gatherer.computeConstraints();
    // Generate new type parameters with the solution as bounds.
    List<TypeParameter> parameters = mixinClass.typeParameters.map((p) {
      TypeConstraint constraint = result[p];
      // Because we solved for equality, a valid solution has a parameter
      // either unconstrained or else with identical upper and lower bounds.
      if (constraint != null && constraint.upper != constraint.lower) {
        reportProblem(
            templateMixinInferenceNoMatchingClass.withArguments(mixinClass.name,
                baseType.classNode.name, mixinSupertype.asInterfaceType),
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
        parameters.map((p) => new TypeParameterType(p)).toList());
    for (TypeParameter p in parameters) {
      p.bound = substitution.substituteType(p.bound);
    }
    // Use instantiate to bounds.
    List<DartType> bounds = calculateBounds(parameters, coreTypes.objectClass);
    for (int i = 0; i < mixedInType.typeArguments.length; ++i) {
      mixedInType.typeArguments[i] = bounds[i];
    }
  }
}

/// The result of an expression inference.
class ExpressionInferenceResult {
  /// The inferred type of the expression.
  final DartType inferredType;

  /// If not-null, the [replacement] that replaced the inferred expression.
  final Expression replacement;

  const ExpressionInferenceResult(this.inferredType, [this.replacement]);
}

enum ObjectAccessTargetKind {
  instanceMember,
  callFunction,
  extensionMember,
  dynamic,
  invalid,
  missing,
  // TODO(johnniwinther): Remove this.
  unresolved,
}

/// Result for performing an access on an object, like `o.foo`, `o.foo()` and
/// `o.foo = ...`.
class ObjectAccessTarget {
  final ObjectAccessTargetKind kind;
  final Member member;

  const ObjectAccessTarget.internal(this.kind, this.member);

  /// Creates an access to the instance [member].
  factory ObjectAccessTarget.interfaceMember(Member member) {
    assert(member != null);
    return new ObjectAccessTarget.internal(
        ObjectAccessTargetKind.instanceMember, member);
  }

  /// Creates an access to the extension [member].
  factory ObjectAccessTarget.extensionMember(
      Member member,
      Member tearoffTarget,
      ProcedureKind kind,
      List<DartType> inferredTypeArguments) = ExtensionAccessTarget;

  /// Creates an access to a 'call' method on a function, i.e. a function
  /// invocation.
  const ObjectAccessTarget.callFunction()
      : this.internal(ObjectAccessTargetKind.callFunction, null);

  /// Creates an access with no known target.
  const ObjectAccessTarget.unresolved()
      : this.internal(ObjectAccessTargetKind.unresolved, null);

  /// Creates an access on a dynamic receiver type with no known target.
  const ObjectAccessTarget.dynamic()
      : this.internal(ObjectAccessTargetKind.dynamic, null);

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

  /// Returns `true` if this is an access to an extension member.
  bool get isExtensionMember => kind == ObjectAccessTargetKind.extensionMember;

  /// Returns `true` if this is an access to the 'call' method on a function.
  bool get isCallFunction => kind == ObjectAccessTargetKind.callFunction;

  /// Returns `true` if this is an access without a known target.
  bool get isUnresolved =>
      kind == ObjectAccessTargetKind.unresolved ||
      isDynamic ||
      isInvalid ||
      isMissing;

  /// Returns `true` if this is an access on a dynamic receiver type.
  bool get isDynamic => kind == ObjectAccessTargetKind.dynamic;

  /// Returns `true` if this is an access on an invalid receiver type.
  bool get isInvalid => kind == ObjectAccessTargetKind.invalid;

  /// Returns `true` if this is an access with no target.
  bool get isMissing => kind == ObjectAccessTargetKind.missing;

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
  Member get tearoffTarget =>
      throw new UnsupportedError('ObjectAccessTarget.tearoffTarget');

  @override
  String toString() => 'ObjectAccessTarget($kind,$member)';
}

class ExtensionAccessTarget extends ObjectAccessTarget {
  final Member tearoffTarget;
  final ProcedureKind extensionMethodKind;
  final List<DartType> inferredExtensionTypeArguments;

  ExtensionAccessTarget(Member member, this.tearoffTarget,
      this.extensionMethodKind, this.inferredExtensionTypeArguments)
      : super.internal(ObjectAccessTargetKind.extensionMember, member);

  @override
  String toString() =>
      'ExtensionAccessTarget($kind,$member,$extensionMethodKind,'
      '$inferredExtensionTypeArguments)';
}

class ExtensionAccessCandidate {
  final bool isPlatform;
  final DartType onType;
  final DartType onTypeInstantiateToBounds;
  final ObjectAccessTarget target;

  ExtensionAccessCandidate(
      this.onType, this.onTypeInstantiateToBounds, this.target,
      {this.isPlatform});

  bool isMoreSpecificThan(TypeSchemaEnvironment typeSchemaEnvironment,
      ExtensionAccessCandidate other) {
    if (this.isPlatform == other.isPlatform) {
      // Both are platform or not platform.
      bool thisIsSubtype = typeSchemaEnvironment.isSubtypeOf(
          this.onType, other.onType, SubtypeCheckMode.ignoringNullabilities);
      bool thisIsSupertype = typeSchemaEnvironment.isSubtypeOf(
          other.onType, this.onType, SubtypeCheckMode.ignoringNullabilities);
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
            SubtypeCheckMode.ignoringNullabilities);
        thisIsSupertype = typeSchemaEnvironment.isSubtypeOf(
            other.onTypeInstantiateToBounds,
            this.onTypeInstantiateToBounds,
            SubtypeCheckMode.ignoringNullabilities);
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
