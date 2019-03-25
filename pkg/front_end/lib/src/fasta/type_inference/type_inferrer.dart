// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' as kernel;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsExpression,
        AsyncMarker,
        BottomType,
        Class,
        ConditionalExpression,
        ConstructorInvocation,
        DartType,
        DynamicType,
        Expression,
        Field,
        FunctionExpression,
        FunctionNode,
        FunctionType,
        Instantiation,
        InterfaceType,
        InvalidType,
        InvocationExpression,
        Let,
        ListLiteral,
        MapLiteral,
        Member,
        MethodInvocation,
        Name,
        NullLiteral,
        Procedure,
        ProcedureKind,
        PropertyGet,
        PropertySet,
        ReturnStatement,
        SetLiteral,
        Statement,
        StaticGet,
        SuperMethodInvocation,
        SuperPropertyGet,
        SuperPropertySet,
        Supertype,
        ThisExpression,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VoidType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart'
    show getFreshTypeParameters, Substitution;

import 'package:kernel/src/bounds_checks.dart' show calculateBounds;

import '../../base/instrumentation.dart'
    show
        Instrumentation,
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;

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
        templateInternalProblemNoInferredTypeStored,
        templateInternalProblemStoringMultipleInferredTypes,
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

import '../kernel/kernel_builder.dart' show KernelLibraryBuilder;

import '../kernel/kernel_expression_generator.dart' show buildIsNull;

import '../kernel/kernel_shadow_ast.dart'
    show
        ExpressionJudgment,
        ShadowClass,
        ShadowField,
        ShadowTypeInferenceEngine,
        ShadowTypeInferrer,
        VariableDeclarationJudgment,
        getExplicitTypeArguments,
        getInferredType;

import '../kernel/type_algorithms.dart' show hasAnyTypeVariables;

import '../names.dart' show callName, unaryMinusName;

import '../problems.dart' show internalProblem, unexpected, unhandled;

import 'inference_helper.dart' show InferenceHelper;

import 'interface_resolver.dart' show ForwardingNode, SyntheticAccessor;

import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;

import 'type_inference_engine.dart'
    show IncludesTypeParametersCovariantly, TypeInferenceEngine;

import 'type_promotion.dart' show TypePromoter;

import 'type_schema.dart' show isKnown, UnknownType;

import 'type_schema_elimination.dart' show greatestClosure;

import 'type_schema_environment.dart'
    show
        getNamedParameterType,
        getPositionalParameterType,
        TypeVariableEliminator,
        TypeSchemaEnvironment;

/// Given a [FunctionNode], gets the named parameter identified by [name], or
/// `null` if there is no parameter with the given name.
VariableDeclaration getNamedFormal(FunctionNode function, String name) {
  for (var formal in function.namedParameters) {
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
    var flattenedReturnType = isAsync
        ? inferrer.typeSchemaEnvironment.unfutureType(returnType)
        : returnType;
    if (statement.expression == null) {
      // Sync: return; is a valid return if T is void, dynamic, or Null.
      // Async: return; is a valid return if flatten(T) is void, dynamic, or
      // Null.
      if (flattenedReturnType is VoidType ||
          flattenedReturnType is DynamicType ||
          flattenedReturnType == inferrer.coreTypes.nullClass.rawType) {
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
    var flattenedExpressionType = isAsync
        ? inferrer.typeSchemaEnvironment.unfutureType(expressionType)
        : expressionType;
    if (returnType is VoidType &&
        flattenedExpressionType is! VoidType &&
        flattenedExpressionType is! DynamicType &&
        flattenedExpressionType != inferrer.coreTypes.nullClass.rawType) {
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
        flattenedReturnType != inferrer.coreTypes.nullClass.rawType) {
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
      var unwrappedType = type;
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
    var expectedType = isYieldStar
        ? _wrapAsyncOrGenerator(inferrer, returnOrYieldContext)
        : returnOrYieldContext;
    if (inferrer.ensureAssignable(expectedType, type, expression, fileOffset,
            isReturnFromAsync: isAsync) !=
        null) {
      type = greatestClosure(inferrer.coreTypes, expectedType);
    }
    if (_needToInferReturnType) {
      var unwrappedType = type;
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
    if (!inferrer.typeSchemaEnvironment
        .isSubtypeOf(inferredType, returnOrYieldContext)) {
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
      KernelLibraryBuilder library) = ShadowTypeInferrer.private;

  KernelLibraryBuilder get library;

  /// Gets the [TypePromoter] that can be used to perform type promotion within
  /// this method body or initializer.
  TypePromoter get typePromoter;

  /// Gets the [TypeSchemaEnvironment] being used for type inference.
  TypeSchemaEnvironment get typeSchemaEnvironment;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  Uri get uri;

  /// Performs full type inference on the given field initializer.
  void inferFieldInitializer(InferenceHelper helper, DartType declaredType,
      kernel.Expression initializer);

  /// Performs type inference on the given function body.
  void inferFunctionBody(InferenceHelper helper, DartType returnType,
      AsyncMarker asyncMarker, Statement body);

  /// Performs type inference on the given constructor initializer.
  void inferInitializer(InferenceHelper helper, kernel.Initializer initializer);

  /// Performs type inference on the given metadata annotations.
  void inferMetadata(
      InferenceHelper helper, List<kernel.Expression> annotations);

  /// Performs type inference on the given metadata annotations keeping the
  /// existing helper if possible.
  void inferMetadataKeepingHelper(List<kernel.Expression> annotations);

  /// Performs type inference on the given function parameter initializer
  /// expression.
  void inferParameterInitializer(InferenceHelper helper,
      kernel.Expression initializer, DartType declaredType);
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
  final KernelLibraryBuilder library;

  final Map<TreeNode, DartType> inferredTypesMap = <TreeNode, DartType>{};

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
      : assert((topLevel && library == null) || (!topLevel && library != null)),
        classHierarchy = engine.classHierarchy,
        instrumentation = topLevel ? null : engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment,
        isTopLevel = topLevel,
        super.private(engine.coreTypes);

  DartType storeInferredType(TreeNode node, DartType type) {
    if (node is ExpressionJudgment) {
      return node.inferredType = type;
    } else {
      if (inferredTypesMap.containsKey(node)) {
        internalProblem(
            templateInternalProblemStoringMultipleInferredTypes.withArguments(
                inferredTypesMap[node], "${node.runtimeType}"),
            node.fileOffset,
            uri);
      }
      return inferredTypesMap[node] = type;
    }
  }

  DartType readInferredType(TreeNode node) {
    if (!inferredTypesMap.containsKey(node) && !isTopLevel) {
      internalProblem(
          templateInternalProblemNoInferredTypeStored
              .withArguments("${node.runtimeType}"),
          node.fileOffset,
          uri);
    }
    return inferredTypesMap[node];
  }

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
    return typeContext == coreTypes.doubleClass.rawType;
  }

  bool isAssignable(DartType expectedType, DartType actualType) {
    return typeSchemaEnvironment.isSubtypeOf(expectedType, actualType) ||
        typeSchemaEnvironment.isSubtypeOf(actualType, expectedType);
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
      var classNode = (actualType as InterfaceType).classNode;
      var callMember = classHierarchy.getInterfaceMember(classNode, callName);
      if (callMember is Procedure && callMember.kind == ProcedureKind.Method) {
        if (_shouldTearOffCall(expectedType, actualType)) {
          // Replace expression with:
          // `let t = expression in t == null ? null : t.call`
          var parent = expression.parent;
          var t = new VariableDeclaration.forValue(expression, type: actualType)
            ..fileOffset = fileOffset;
          var nullCheck = buildIsNull(new VariableGet(t), fileOffset, helper);
          var tearOff =
              new PropertyGet(new VariableGet(t), callName, callMember)
                ..fileOffset = fileOffset;
          actualType = getCalleeType(callMember, actualType);
          var conditional = new ConditionalExpression(nullCheck,
              new NullLiteral()..fileOffset = fileOffset, tearOff, actualType);
          var let = new Let(t, conditional)..fileOffset = fileOffset;
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
        typeSchemaEnvironment.isSubtypeOf(actualType, expectedType)) {
      // Types are compatible.
      return null;
    }

    if (!typeSchemaEnvironment.isSubtypeOf(expectedType, actualType)) {
      // Error: not assignable.  Perform error recovery.
      var parent = expression.parent;
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
      var template = _getPreciseTypeErrorTemplate(expression);
      if (template != null) {
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        var parent = expression.parent;
        var errorNode = helper.wrapInProblem(expression,
            template.withArguments(actualType, expectedType), noLength);
        parent?.replaceChild(expression, errorNode);
        return errorNode;
      } else {
        // Insert an implicit downcast.
        var parent = expression.parent;
        var typeCheck = new AsExpression(expression, initialExpectedType)
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
  Object findInterfaceMember(DartType receiverType, Name name, int fileOffset,
      {Template<Message Function(String, DartType)> errorTemplate,
      Expression expression,
      Expression receiver,
      bool setter: false,
      bool instrumented: true}) {
    assert(receiverType != null && isKnown(receiverType));

    receiverType = resolveTypeParameter(receiverType);

    if (receiverType is FunctionType && name.name == 'call') {
      return 'call';
    }

    Class classNode = receiverType is InterfaceType
        ? receiverType.classNode
        : coreTypes.objectClass;
    Member interfaceMember = _getInterfaceMember(classNode, name, setter);
    if (instrumented &&
        receiverType != const DynamicType() &&
        interfaceMember != null) {
      instrumentation?.record(uri, fileOffset, 'target',
          new InstrumentationValueForMember(interfaceMember));
    }

    if (!isTopLevel &&
        interfaceMember == null &&
        receiverType is! DynamicType &&
        receiverType is! InvalidType &&
        !(receiverType == coreTypes.functionClass.rawType &&
            name.name == 'call') &&
        errorTemplate != null) {
      int length = name.name.length;
      if (identical(name.name, callName.name) ||
          identical(name.name, unaryMinusName.name)) {
        length = 1;
      }
      expression.parent.replaceChild(
          expression,
          helper.desugarSyntheticExpression(helper.buildProblem(
              errorTemplate.withArguments(name.name, receiverType),
              fileOffset,
              length)));
    }
    return interfaceMember;
  }

  /// Finds a member of [receiverType] called [name] and records it in
  /// [methodInvocation].
  Object findMethodInvocationMember(
      DartType receiverType, InvocationExpression methodInvocation,
      {bool instrumented: true}) {
    // TODO(paulberry): could we add getters to InvocationExpression to make
    // these is-checks unnecessary?
    if (methodInvocation is MethodInvocation) {
      var interfaceMember = findInterfaceMember(
          receiverType, methodInvocation.name, methodInvocation.fileOffset,
          errorTemplate: templateUndefinedMethod,
          expression: methodInvocation,
          receiver: methodInvocation.receiver,
          instrumented: instrumented);
      if (receiverType == const DynamicType() && interfaceMember is Procedure) {
        var arguments = methodInvocation.arguments;
        var signature = interfaceMember.function;
        if (arguments.positional.length < signature.requiredParameterCount ||
            arguments.positional.length >
                signature.positionalParameters.length) {
          return null;
        }
        for (var argument in arguments.named) {
          if (!signature.namedParameters
              .any((declaration) => declaration.name == argument.name)) {
            return null;
          }
        }
        if (instrumented && instrumentation != null) {
          instrumentation.record(uri, methodInvocation.fileOffset, 'target',
              new InstrumentationValueForMember(interfaceMember));
        }
        methodInvocation.interfaceTarget = interfaceMember;
      } else if (interfaceMember is Member) {
        methodInvocation.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else if (methodInvocation is SuperMethodInvocation) {
      assert(receiverType != const DynamicType());
      var interfaceMember = findInterfaceMember(
          receiverType, methodInvocation.name, methodInvocation.fileOffset,
          instrumented: instrumented);
      if (interfaceMember is Member) {
        methodInvocation.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else {
      throw unhandled("${methodInvocation.runtimeType}",
          "findMethodInvocationMember", methodInvocation.fileOffset, uri);
    }
  }

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation and records it in [propertyGet].
  Object findPropertyGetMember(DartType receiverType, Expression propertyGet,
      {bool instrumented: true}) {
    // TODO(paulberry): could we add a common base class to PropertyGet and
    // SuperPropertyGet to make these is-checks unnecessary?
    if (propertyGet is PropertyGet) {
      var interfaceMember = findInterfaceMember(
          receiverType, propertyGet.name, propertyGet.fileOffset,
          errorTemplate: templateUndefinedGetter,
          expression: propertyGet,
          receiver: propertyGet.receiver,
          instrumented: instrumented);
      if (interfaceMember is Member) {
        if (instrumented &&
            instrumentation != null &&
            receiverType == const DynamicType()) {
          instrumentation.record(uri, propertyGet.fileOffset, 'target',
              new InstrumentationValueForMember(interfaceMember));
        }
        propertyGet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else if (propertyGet is SuperPropertyGet) {
      assert(receiverType != const DynamicType());
      var interfaceMember = findInterfaceMember(
          receiverType, propertyGet.name, propertyGet.fileOffset,
          instrumented: instrumented);
      if (interfaceMember is Member) {
        propertyGet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else {
      return unhandled("${propertyGet.runtimeType}", "findPropertyGetMember",
          propertyGet.fileOffset, uri);
    }
  }

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation and records it in [propertySet].
  Object findPropertySetMember(DartType receiverType, Expression propertySet,
      {bool instrumented: true}) {
    if (propertySet is PropertySet) {
      var interfaceMember = findInterfaceMember(
          receiverType, propertySet.name, propertySet.fileOffset,
          errorTemplate: templateUndefinedSetter,
          expression: propertySet,
          receiver: propertySet.receiver,
          setter: true,
          instrumented: instrumented);
      if (interfaceMember is Member) {
        if (instrumented &&
            instrumentation != null &&
            receiverType == const DynamicType()) {
          instrumentation.record(uri, propertySet.fileOffset, 'target',
              new InstrumentationValueForMember(interfaceMember));
        }
        propertySet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else if (propertySet is SuperPropertySet) {
      assert(receiverType != const DynamicType());
      var interfaceMember = findInterfaceMember(
          receiverType, propertySet.name, propertySet.fileOffset,
          setter: true, instrumented: instrumented);
      if (interfaceMember is Member) {
        propertySet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else {
      throw unhandled("${propertySet.runtimeType}", "findPropertySetMember",
          propertySet.fileOffset, uri);
    }
  }

  FunctionType getCalleeFunctionType(DartType calleeType, bool followCall) {
    if (calleeType is FunctionType) {
      return calleeType;
    } else if (followCall && calleeType is InterfaceType) {
      var member = _getInterfaceMember(calleeType.classNode, callName, false);
      var callType = getCalleeType(member, calleeType);
      if (callType is FunctionType) {
        return callType;
      }
    }
    return unknownFunction;
  }

  DartType getCalleeType(Object interfaceMember, DartType receiverType) {
    if (identical(interfaceMember, 'call')) {
      return receiverType;
    } else if (interfaceMember == null) {
      return const DynamicType();
    } else if (interfaceMember is Member) {
      var memberClass = interfaceMember.enclosingClass;
      DartType calleeType;
      if (interfaceMember is Procedure) {
        if (interfaceMember.kind == ProcedureKind.Getter) {
          calleeType = interfaceMember.function.returnType;
        } else {
          calleeType = interfaceMember.function.functionType;
        }
      } else if (interfaceMember is Field) {
        calleeType = interfaceMember.type;
      } else {
        throw unhandled(interfaceMember.runtimeType.toString(), 'getCalleeType',
            null, null);
      }
      if (memberClass.typeParameters.isNotEmpty) {
        receiverType = resolveTypeParameter(receiverType);
        if (receiverType is InterfaceType) {
          var castedType =
              classHierarchy.getTypeAsInstanceOf(receiverType, memberClass);
          calleeType = Substitution.fromInterfaceType(castedType)
              .substituteType(calleeType);
        }
      }
      return calleeType;
    } else {
      throw unhandled(
          interfaceMember.runtimeType.toString(), 'getCalleeType', null, null);
    }
  }

  DartType getDerivedTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType) {
      var typeAsInstanceOfClass =
          classHierarchy.getTypeAsInstanceOf(type, class_);
      if (typeAsInstanceOfClass != null) {
        return typeAsInstanceOfClass.typeArguments[0];
      }
    }
    return null;
  }

  /// Gets the initializer for the given [field], or `null` if there is no
  /// initializer.
  Expression getFieldInitializer(ShadowField field);

  /// If the [member] is a forwarding stub, return the target it forwards to.
  /// Otherwise return the given [member].
  Member getRealTarget(Member member) {
    if (member is Procedure && member.isForwardingStub) {
      return member.forwardingStubInterfaceTarget;
    }
    return member;
  }

  DartType getSetterType(Object interfaceMember, DartType receiverType) {
    if (interfaceMember is FunctionType) {
      return interfaceMember;
    } else if (interfaceMember == null) {
      return const DynamicType();
    } else if (interfaceMember is Member) {
      var memberClass = interfaceMember.enclosingClass;
      DartType setterType;
      if (interfaceMember is Procedure) {
        assert(interfaceMember.kind == ProcedureKind.Setter);
        var setterParameters = interfaceMember.function.positionalParameters;
        setterType = setterParameters.length > 0
            ? setterParameters[0].type
            : const DynamicType();
      } else if (interfaceMember is Field) {
        setterType = interfaceMember.type;
      } else {
        throw unhandled(interfaceMember.runtimeType.toString(), 'getSetterType',
            null, null);
      }
      if (memberClass.typeParameters.isNotEmpty) {
        receiverType = resolveTypeParameter(receiverType);
        if (receiverType is InterfaceType) {
          var castedType =
              classHierarchy.getTypeAsInstanceOf(receiverType, memberClass);
          setterType = Substitution.fromInterfaceType(castedType)
              .substituteType(setterType);
        }
      }
      return setterType;
    } else {
      throw unhandled(
          interfaceMember.runtimeType.toString(), 'getSetterType', null, null);
    }
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
    var expressionToReplace = desugaredInvocation ?? expression;
    switch (checkKind) {
      case MethodContravarianceCheckKind.checkMethodReturn:
        var parent = expressionToReplace.parent;
        var replacement = new AsExpression(expressionToReplace, inferredType)
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
        var parent = expressionToReplace.parent;
        var propertyGet = new PropertyGet(desugaredInvocation.receiver,
            desugaredInvocation.name, desugaredInvocation.interfaceTarget);
        var asExpression = new AsExpression(propertyGet, functionType)
          ..isTypeError = true
          ..fileOffset = fileOffset;
        var replacement = new MethodInvocation(
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
      Object interfaceMember,
      PropertyGet desugaredGet,
      Expression expression,
      DartType inferredType,
      int fileOffset) {
    bool checkReturn = false;
    if (receiver != null &&
        interfaceMember != null &&
        receiver is! ThisExpression) {
      if (interfaceMember is Procedure) {
        checkReturn = typeParametersOccurNegatively(
            interfaceMember.enclosingClass,
            interfaceMember.function.returnType);
      } else if (interfaceMember is Field) {
        checkReturn = typeParametersOccurNegatively(
            interfaceMember.enclosingClass, interfaceMember.type);
      }
    }
    var replacedExpression = desugaredGet ?? expression;
    if (checkReturn) {
      var expressionToReplace = replacedExpression;
      var parent = expressionToReplace.parent;
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
  /// actual type of the expression.  If [typeNeeded] is `true`, the actual type
  /// of the expression is returned; otherwise `null` is returned.
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the expression type and calls the appropriate specialized "infer" method.
  DartType inferExpression(
      kernel.Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed});

  @override
  void inferFieldInitializer(
    InferenceHelper helper,
    DartType context,
    kernel.Expression initializer,
  ) {
    assert(closureContext == null);
    assert(!isTopLevel);
    this.helper = helper;
    var actualType =
        inferExpression(initializer, context, true, isVoidAllowed: true);
    ensureAssignable(context, actualType, initializer, initializer.fileOffset,
        isVoidAllowed: context is VoidType);
    this.helper = null;
  }

  /// Performs type inference on the given [field]'s initializer expression.
  ///
  /// Derived classes should provide an implementation that calls
  /// [inferExpression] for the given [field]'s initializer expression.
  DartType inferFieldTopLevel(ShadowField field);

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

  /// Performs the type inference steps that are shared by all kinds of
  /// invocations (constructors, instance methods, and static methods).
  ExpressionInferenceResult inferInvocation(DartType typeContext, int offset,
      FunctionType calleeType, DartType returnType, Arguments arguments,
      {bool isOverloadedArithmeticOperator: false,
      DartType receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false}) {
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
      var fresh = getFreshTypeParameters(calleeTypeParameters);
      calleeType = fresh.applyToFunctionType(calleeType);
      returnType = fresh.substitute(returnType);
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
      typeSchemaEnvironment.inferGenericFunctionOrType(returnType,
          calleeTypeParameters, null, null, typeContext, inferredTypes);
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
      var expressionType = inferExpression(
          expression,
          inferredFormalType,
          inferenceNeeded ||
              isOverloadedArithmeticOperator ||
              typeChecksNeeded);
      if (inferenceNeeded || typeChecksNeeded) {
        formalTypes.add(formalType);
        actualTypes.add(expressionType);
      }
      if (isOverloadedArithmeticOperator) {
        returnType = typeSchemaEnvironment.getTypeOfOverloadedArithmetic(
            receiverType, expressionType);
      }
    });

    // Check for and remove duplicated named arguments.
    var named = arguments.named;
    if (named.length == 2) {
      if (named[0].name == named[1].name) {
        var name = named[1].name;
        var error = helper.desugarSyntheticExpression(helper.buildProblem(
            templateDuplicatedNamedArgument.withArguments(name),
            named[1].fileOffset,
            name.length));
        arguments.named = [new kernel.NamedExpression(named[1].name, error)];
        formalTypes.removeLast();
        actualTypes.removeLast();
      }
    } else if (named.length > 2) {
      var seenNames = <String, kernel.NamedExpression>{};
      var hasProblem = false;
      var namedTypeIndex = arguments.positional.length;
      var uniqueNamed = <kernel.NamedExpression>[];
      for (var expression in named) {
        var name = expression.name;
        if (seenNames.containsKey(name)) {
          hasProblem = true;
          var prevNamedExpression = seenNames[name];
          prevNamedExpression.value = helper.desugarSyntheticExpression(
              helper.buildProblem(
                  templateDuplicatedNamedArgument.withArguments(name),
                  expression.fileOffset,
                  name.length))
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
          returnType,
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
          var formalType = formalTypes[i];
          var expectedType = substitution != null
              ? substitution.substituteType(formalType)
              : formalType;
          var actualType = actualTypes[i];
          var expression = i < numPositionalArgs
              ? arguments.positional[i]
              : arguments.named[i - numPositionalArgs].value;
          ensureAssignable(
              expectedType, actualType, expression, expression.fileOffset,
              isVoidAllowed: expectedType is VoidType,
              template: templateArgumentTypeNotAssignable);
        }
      }
    }
    DartType inferredType;
    lastInferredSubstitution = substitution;
    lastCalleeType = calleeType;
    inferredType = substitution == null
        ? returnType
        : substitution.substituteType(returnType);
    return new ExpressionInferenceResult(null, inferredType);
  }

  ExpressionInferenceResult inferLocalFunction(FunctionNode function,
      DartType typeContext, int fileOffset, DartType returnContext) {
    bool hasImplicitReturnType = false;
    if (returnContext == null) {
      hasImplicitReturnType = true;
      returnContext = const DynamicType();
    }
    if (!isTopLevel) {
      var positionalParameters = function.positionalParameters;
      for (var i = 0; i < positionalParameters.length; i++) {
        var parameter = positionalParameters[i];
        inferMetadataKeepingHelper(parameter.annotations);
        if (parameter.initializer != null) {
          inferExpression(parameter.initializer, parameter.type, !isTopLevel);
        }
      }
      for (var parameter in function.namedParameters) {
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
      var substitutionMap = <TypeParameter, DartType>{};
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
      VariableDeclarationJudgment formal = formals[i];
      if (VariableDeclarationJudgment.isImplicitlyTyped(formal)) {
        DartType inferredType;
        if (formalTypesFromContext[i] == coreTypes.nullClass.rawType) {
          inferredType = coreTypes.objectClass.rawType;
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
    returnContext = substitution.substituteType(returnContext);

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
    return new ExpressionInferenceResult(null, function.functionType);
  }

  @override
  void inferMetadata(
      InferenceHelper helper, List<kernel.Expression> annotations) {
    if (annotations != null) {
      this.helper = helper;
      inferMetadataKeepingHelper(annotations);
      this.helper = null;
    }
  }

  @override
  void inferMetadataKeepingHelper(List<kernel.Expression> annotations) {
    if (annotations != null) {
      // Place annotations in a temporary list literal so that they will have a
      // parent.  This is necessary in case any of the annotations need to get
      // replaced during type inference.
      var parents = annotations.map((e) => e.parent).toList();
      new ListLiteral(annotations);
      for (var annotation in annotations) {
        inferExpression(annotation, const UnknownType(), !isTopLevel);
      }
      for (int i = 0; i < annotations.length; ++i) {
        annotations[i].parent = parents[i];
      }
    }
  }

  /// Performs the core type inference algorithm for method invocations (this
  /// handles both null-aware and non-null-aware method invocations).
  ExpressionInferenceResult inferMethodInvocation(
      kernel.Expression expression,
      kernel.Expression receiver,
      int fileOffset,
      bool isImplicitCall,
      DartType typeContext,
      {VariableDeclaration receiverVariable,
      MethodInvocation desugaredInvocation,
      Object interfaceMember,
      Name methodName,
      Arguments arguments}) {
    // First infer the receiver so we can look up the method that was invoked.
    var receiverType = receiver == null
        ? thisType
        : inferExpression(receiver, const UnknownType(), true);
    receiverVariable?.type = receiverType;
    if (desugaredInvocation != null) {
      interfaceMember =
          findMethodInvocationMember(receiverType, desugaredInvocation);
      methodName = desugaredInvocation.name;
      arguments = desugaredInvocation.arguments;
    }
    bool isOverloadedArithmeticOperator = interfaceMember is Procedure &&
        typeSchemaEnvironment.isOverloadedArithmeticOperatorAndType(
            interfaceMember, receiverType);
    var calleeType = getCalleeType(interfaceMember, receiverType);
    var functionType = getCalleeFunctionType(calleeType, !isImplicitCall);

    if (interfaceMember != null &&
        calleeType is! DynamicType &&
        calleeType != coreTypes.functionClass.rawType &&
        identical(functionType, unknownFunction)) {
      var parent = expression.parent;
      kernel.Expression error = helper.wrapInProblem(expression,
          templateInvokeNonFunction.withArguments(methodName.name), noLength);
      parent?.replaceChild(expression, error);
      return new ExpressionInferenceResult(null, const DynamicType());
    }
    var checkKind = preCheckInvocationContravariance(receiver, receiverType,
        interfaceMember, desugaredInvocation, arguments, expression);
    var inferenceResult = inferInvocation(typeContext, fileOffset, functionType,
        functionType.returnType, arguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        receiverType: receiverType);
    var inferredType = inferenceResult.type;
    if (methodName.name == '==') {
      inferredType = coreTypes.boolClass.rawType;
    }
    handleInvocationContravariance(checkKind, desugaredInvocation, arguments,
        expression, inferredType, functionType, fileOffset);
    if (!identical(interfaceMember, 'call')) {
      if (isImplicitCall &&
          interfaceMember != null &&
          !(interfaceMember is Procedure &&
              interfaceMember.kind == ProcedureKind.Method) &&
          receiverType is! DynamicType &&
          receiverType != typeSchemaEnvironment.rawFunctionType) {
        var parent = expression.parent;
        var errorNode = helper.wrapInProblem(
            expression,
            templateImplicitCallOfNonMethod.withArguments(receiverType),
            noLength);
        parent?.replaceChild(expression, errorNode);
      }
    }

    // If [arguments] were inferred, check them.
    // TODO(dmitryas): Figure out why [library] is sometimes null.
    if (library != null) {
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
        interfaceTarget = interfaceMember is Member ? interfaceMember : null;
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
          fileOffset,
          inferred: getExplicitTypeArguments(arguments) == null);
    }

    return new ExpressionInferenceResult(null, inferredType);
  }

  @override
  void inferParameterInitializer(InferenceHelper helper,
      kernel.Expression initializer, DartType declaredType) {
    assert(closureContext == null);
    this.helper = helper;
    assert(declaredType != null);
    var actualType = inferExpression(initializer, declaredType, true);
    ensureAssignable(
        declaredType, actualType, initializer, initializer.fileOffset);
    this.helper = null;
  }

  /// Performs the core type inference algorithm for property gets (this handles
  /// both null-aware and non-null-aware property gets).
  void inferPropertyGet(Expression expression, Expression receiver,
      int fileOffset, DartType typeContext,
      {VariableDeclaration receiverVariable,
      PropertyGet desugaredGet,
      Object interfaceMember,
      Name propertyName}) {
    // First infer the receiver so we can look up the getter that was invoked.
    DartType receiverType;
    if (receiver == null) {
      receiverType = thisType;
    } else {
      inferExpression(receiver, const UnknownType(), true);
      receiverType = getInferredType(receiver, this);
    }
    receiverVariable?.type = receiverType;
    propertyName ??= desugaredGet.name;
    if (desugaredGet != null) {
      interfaceMember = findInterfaceMember(
          receiverType, propertyName, fileOffset,
          errorTemplate: templateUndefinedGetter,
          expression: expression,
          receiver: receiver);
      if (interfaceMember is Member) {
        if (instrumentation != null && receiverType == const DynamicType()) {
          instrumentation.record(uri, desugaredGet.fileOffset, 'target',
              new InstrumentationValueForMember(interfaceMember));
        }
        desugaredGet.interfaceTarget = interfaceMember;
      }
    }
    var inferredType = getCalleeType(interfaceMember, receiverType);
    var replacedExpression = handlePropertyGetContravariance(receiver,
        interfaceMember, desugaredGet, expression, inferredType, fileOffset);
    if ((interfaceMember is Procedure &&
        interfaceMember.kind == ProcedureKind.Method)) {
      inferredType =
          instantiateTearOff(inferredType, typeContext, replacedExpression);
    }
    storeInferredType(expression, inferredType);
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
      var typeParameters = tearoffType.typeParameters;
      if (typeParameters.isNotEmpty) {
        var inferredTypes = new List<DartType>.filled(
            typeParameters.length, const UnknownType());
        var instantiatedType = tearoffType.withoutTypeParameters;
        typeSchemaEnvironment.inferGenericFunctionOrType(
            instantiatedType, typeParameters, [], [], context, inferredTypes);
        if (!isTopLevel) {
          var parent = expression.parent;
          parent.replaceChild(
              expression,
              new Instantiation(expression, inferredTypes)
                ..fileOffset = expression.fileOffset);
        }
        var substitution =
            Substitution.fromPairs(typeParameters, inferredTypes);
        return substitution.substituteType(instantiatedType);
      }
    }
    return tearoffType;
  }

  /// True if [type] has negative occurrences of any of [class_]'s type
  /// parameters.
  ///
  /// A negative occurrence of a type parameter is one that is to the left of
  /// an odd number of arrows.  For example, T occurs negatively in T -> T0,
  /// T0 -> (T -> T1), (T0 -> T) -> T1 but not in (T -> T0) -> T1.
  static bool typeParametersOccurNegatively(Class class_, DartType type) {
    if (class_.typeParameters.isEmpty) return false;
    var checker = new IncludesTypeParametersCovariantly(class_.typeParameters)
      ..inCovariantContext = false;
    return type.accept(checker);
  }

  /// Determines the dispatch category of a [MethodInvocation] and returns a
  /// boolean indicating whether an "as" check will need to be added due to
  /// contravariance.
  MethodContravarianceCheckKind preCheckInvocationContravariance(
      Expression receiver,
      DartType receiverType,
      Object interfaceMember,
      MethodInvocation desugaredInvocation,
      Arguments arguments,
      Expression expression) {
    if (interfaceMember is Field ||
        interfaceMember is Procedure &&
            interfaceMember.kind == ProcedureKind.Getter) {
      var getType = getCalleeType(interfaceMember, receiverType);
      if (getType is DynamicType) {
        return MethodContravarianceCheckKind.none;
      }
      if (receiver != null && receiver is! ThisExpression) {
        if ((interfaceMember is Field &&
                typeParametersOccurNegatively(
                    interfaceMember.enclosingClass, interfaceMember.type)) ||
            (interfaceMember is Procedure &&
                typeParametersOccurNegatively(interfaceMember.enclosingClass,
                    interfaceMember.function.returnType))) {
          return MethodContravarianceCheckKind.checkGetterReturn;
        }
      }
    } else if (receiver != null &&
        receiver is! ThisExpression &&
        interfaceMember is Procedure &&
        typeParametersOccurNegatively(interfaceMember.enclosingClass,
            interfaceMember.function.returnType)) {
      return MethodContravarianceCheckKind.checkMethodReturn;
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

    var resolved = resolveOneStep(type);
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
      var step1 = resolveOneStep(hare);
      if (step1 == null) return hare;
      var step2 = resolveOneStep(step1);
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
    var typeWithoutFutureOr = type ?? const DynamicType();
    return new InterfaceType(
        coreTypes.futureClass, <DartType>[typeWithoutFutureOr]);
  }

  DartType wrapType(DartType type, Class class_) {
    return new InterfaceType(class_, <DartType>[type ?? const DynamicType()]);
  }

  void _forEachArgument(
      Arguments arguments, void callback(String name, Expression expression)) {
    for (var expression in arguments.positional) {
      callback(null, expression);
    }
    for (var namedExpression in arguments.named) {
      callback(namedExpression.name, namedExpression.value);
    }
  }

  Member _getInterfaceMember(Class class_, Name name, bool setter) {
    if (class_ is ShadowClass) {
      var classInferenceInfo = ShadowClass.getClassInferenceInfo(class_);
      if (classInferenceInfo != null) {
        var member = ClassHierarchy.findMemberByName(
            setter
                ? classInferenceInfo.setters
                : classInferenceInfo.gettersAndMethods,
            name);
        if (member == null) return null;
        member = member is ForwardingNode ? member.resolve() : member;
        member = member is SyntheticAccessor
            ? SyntheticAccessor.getField(member)
            : member;
        TypeInferenceEngine.resolveInferenceNode(member);
        return member;
      }
    }
    return classHierarchy.getInterfaceMember(class_, name, setter: setter);
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
      var target = expression.target;
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
      var variable = expression.variable;
      if (variable is VariableDeclarationJudgment &&
          VariableDeclarationJudgment.isLocalFunction(variable)) {
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
    if (expectedType == typeSchemaEnvironment.rawFunctionType) {
      if (!typeSchemaEnvironment.isSubtypeOf(actualType, expectedType)) {
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
      // ..., Xn that occured free in S0 and S1.  Treat S0 and S1 as separate
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
      var mixinSuperclass = mixinSupertype.classNode;
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
      var substitution = Substitution.fromSupertype(mixinSupertype);
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
    var result = gatherer.computeConstraints();
    // Generate new type parameters with the solution as bounds.
    List<TypeParameter> parameters = mixinClass.typeParameters.map((p) {
      var constraint = result[p];
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
    var substitution = Substitution.fromPairs(mixinClass.typeParameters,
        parameters.map((p) => new TypeParameterType(p)).toList());
    for (var p in parameters) {
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
  final Expression expression;
  final DartType type;

  ExpressionInferenceResult(this.expression, this.type);
}
