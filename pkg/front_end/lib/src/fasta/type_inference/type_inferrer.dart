// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

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
        DispatchCategory,
        DynamicType,
        Expression,
        Field,
        FunctionExpression,
        FunctionNode,
        FunctionType,
        Initializer,
        Instantiation,
        InterfaceType,
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
        Statement,
        StaticGet,
        SuperMethodInvocation,
        SuperPropertyGet,
        SuperPropertySet,
        Supertype,
        ThisExpression,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VoidType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy, MixinInferrer;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart'
    show calculateBounds, getFreshTypeParameters, Substitution;

import '../../base/instrumentation.dart'
    show
        Instrumentation,
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs,
        InstrumentationValueLiteral;

import '../fasta_codes.dart';

import '../kernel/fasta_accessors.dart'
    show BuilderHelper, CalleeDesignation, FunctionTypeAccessor;

import '../kernel/frontend_accessors.dart' show buildIsNull;

import '../kernel/kernel_shadow_ast.dart'
    show
        getExplicitTypeArguments,
        ShadowClass,
        ShadowConstructorInvocation,
        ShadowField,
        ShadowMember,
        ShadowNullLiteral,
        ShadowVariableDeclaration;

import '../names.dart' show callName;

import '../problems.dart' show unexpected, unhandled;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart' show SourceLoader;

import 'interface_resolver.dart' show ForwardingNode, SyntheticAccessor;

import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;

import 'type_inference_engine.dart' show TypeInferenceEngineImpl;

import 'type_promotion.dart' show TypePromoter, TypePromoterDisabled;

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

  final bool _needToInferReturnType;

  final bool _needImplicitDowncasts;

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

  factory ClosureContext(
      TypeInferrerImpl inferrer,
      AsyncMarker asyncMarker,
      DartType returnContext,
      bool needToInferReturnType,
      bool needImplicitDowncasts) {
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
        needToInferReturnType, needImplicitDowncasts);
  }

  ClosureContext._(this.isAsync, this.isGenerator, this.returnOrYieldContext,
      this._needToInferReturnType, this._needImplicitDowncasts) {
    assert(returnOrYieldContext != null);
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  void handleReturn(TypeInferrerImpl inferrer, DartType type,
      Expression expression, int fileOffset) {
    if (isGenerator) return;
    _updateInferredReturnType(
        inferrer, type, expression, fileOffset, true, false);
  }

  void handleYield(TypeInferrerImpl inferrer, bool isYieldStar, DartType type,
      Expression expression, int fileOffset) {
    if (!isGenerator) return;
    _updateInferredReturnType(
        inferrer, type, expression, fileOffset, false, isYieldStar);
  }

  DartType inferReturnType(TypeInferrerImpl inferrer) {
    assert(_needToInferReturnType);
    DartType inferredType =
        inferrer.inferReturnType(_inferredUnwrappedReturnOrYieldType);
    if (returnOrYieldContext != null &&
        !_analyzerSubtypeOf(inferrer, inferredType, returnOrYieldContext)) {
      // If the inferred return type isn't a subtype of the context, we use the
      // context.
      inferredType = returnOrYieldContext;
    }

    return _wrapAsyncOrGenerator(inferrer, inferredType);
  }

  void _updateInferredReturnType(TypeInferrerImpl inferrer, DartType type,
      Expression expression, int fileOffset, bool isReturn, bool isYieldStar) {
    if (_needImplicitDowncasts) {
      var expectedType = isYieldStar
          ? _wrapAsyncOrGenerator(inferrer, returnOrYieldContext)
          : returnOrYieldContext;
      if (expectedType != null) {
        expectedType = greatestClosure(inferrer.coreTypes, expectedType);
        if (inferrer.ensureAssignable(
                expectedType, type, expression, fileOffset,
                isReturnFromAsync: isAsync) !=
            null) {
          type = expectedType;
        }
      }
    }
    var unwrappedType = type;
    if (isAsync && isReturn) {
      unwrappedType = inferrer.typeSchemaEnvironment.unfutureType(type);
    } else if (isYieldStar) {
      unwrappedType = inferrer.getDerivedTypeArgumentOf(
              type,
              isAsync
                  ? inferrer.coreTypes.streamClass
                  : inferrer.coreTypes.iterableClass) ??
          type;
    }
    if (_needToInferReturnType) {
      if (_inferredUnwrappedReturnOrYieldType == null) {
        _inferredUnwrappedReturnOrYieldType = unwrappedType;
      } else {
        _inferredUnwrappedReturnOrYieldType = inferrer.typeSchemaEnvironment
            .getLeastUpperBound(
                _inferredUnwrappedReturnOrYieldType, unwrappedType);
      }
    }
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

  static bool _analyzerSubtypeOf(
      TypeInferrerImpl inferrer, DartType subtype, DartType supertype) {
    if (supertype is VoidType) {
      if (subtype is VoidType) return true;
      if (subtype is InterfaceType &&
          identical(subtype.classNode, inferrer.coreTypes.nullClass)) {
        return true;
      }
      return false;
    }
    return inferrer.typeSchemaEnvironment.isSubtypeOf(subtype, supertype);
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
      BuilderHelper helper, DartType declaredType, Expression initializer);

  /// Performs type inference on the given function body.
  void inferFunctionBody(BuilderHelper helper, DartType returnType,
      AsyncMarker asyncMarker, Statement body);

  /// Performs type inference on the given constructor initializer.
  void inferInitializer(BuilderHelper helper, Initializer initializer);

  /// Performs type inference on the given metadata annotations.
  void inferMetadata(BuilderHelper helper, List<Expression> annotations);

  /// Performs type inference on the given function parameter initializer
  /// expression.
  void inferParameterInitializer(
      BuilderHelper helper, Expression initializer, DartType declaredType);
}

/// Implementation of [TypeInferrer] which doesn't do any type inference.
///
/// This is intended for profiling, to ensure that type inference and type
/// promotion do not slow down compilation too much.
class TypeInferrerDisabled extends TypeInferrer {
  @override
  final typePromoter = new TypePromoterDisabled();

  @override
  final TypeSchemaEnvironment typeSchemaEnvironment;

  TypeInferrerDisabled(this.typeSchemaEnvironment);

  @override
  Uri get uri => null;

  @override
  void inferFieldInitializer(
      BuilderHelper helper, DartType declaredType, Expression initializer) {}

  @override
  void inferFunctionBody(BuilderHelper helper, DartType returnType,
      AsyncMarker asyncMarker, Statement body) {}

  @override
  void inferInitializer(BuilderHelper helper, Initializer initializer) {}

  @override
  void inferMetadata(BuilderHelper helper, List<Expression> annotations) {}

  @override
  void inferParameterInitializer(
      BuilderHelper helper, Expression initializer, DartType declaredType) {}
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

  final TypeInferenceEngineImpl engine;

  @override
  final Uri uri;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  final bool isTopLevel;

  final CoreTypes coreTypes;

  final bool strongMode;

  final ClassHierarchy classHierarchy;

  final Instrumentation instrumentation;

  final TypeSchemaEnvironment typeSchemaEnvironment;

  final InterfaceType thisType;

  final SourceLibraryBuilder library;

  BuilderHelper helper;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  ClosureContext closureContext;

  /// The [Substitution] inferred by the last [inferInvocation], or `null` if
  /// the last invocation didn't require any inference.
  Substitution lastInferredSubstitution;

  /// The [FunctionType] of the callee in the last [inferInvocation], or `null`
  /// if the last invocation didn't require any inference.
  FunctionType lastCalleeType;

  TypeInferrerImpl(
      this.engine, this.uri, bool topLevel, this.thisType, this.library)
      : coreTypes = engine.coreTypes,
        strongMode = engine.strongMode,
        classHierarchy = engine.classHierarchy,
        instrumentation = topLevel ? null : engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment,
        isTopLevel = topLevel;

  /// Gets the type promoter that should be used to promote types during
  /// inference.
  TypePromoter get typePromoter;

  bool isAssignable(DartType expectedType, DartType actualType) {
    return typeSchemaEnvironment.isSubtypeOf(expectedType, actualType) ||
        typeSchemaEnvironment.isSubtypeOf(actualType, expectedType);
  }

  /// Checks whether [actualType] can be assigned to the greatest closure of
  /// [expectedType], and inserts an implicit downcast if appropriate.
  Expression ensureAssignable(DartType expectedType, DartType actualType,
      Expression expression, int fileOffset,
      {bool isReturnFromAsync = false}) {
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

    // This logic is strong mode only; in legacy mode anything goes.
    if (!strongMode) return null;

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
          var nullCheck = buildIsNull(new VariableGet(t), fileOffset);
          var tearOff =
              new PropertyGet(new VariableGet(t), callName, callMember)
                ..fileOffset = fileOffset;
          actualType = getCalleeType(callMember, actualType);
          var conditional = new ConditionalExpression(nullCheck,
              new NullLiteral()..fileOffset = fileOffset, tearOff, actualType);
          var let = new Let(t, conditional);
          parent?.replaceChild(expression, let);
          expression = let;
        }
      }
    }

    if (expectedType == null ||
        typeSchemaEnvironment.isSubtypeOf(actualType, expectedType)) {
      // Types are compatible.
      return null;
    }

    if (!typeSchemaEnvironment.isSubtypeOf(expectedType, actualType)) {
      // Error: not assignable.  Perform error recovery.
      var parent = expression.parent;
      var errorNode = helper.wrapInCompileTimeError(expression,
          templateInvalidAssignment.withArguments(actualType, expectedType));
      parent?.replaceChild(expression, errorNode);
      return errorNode;
    } else {
      var template = _getPreciseTypeErrorTemplate(expression);
      if (template != null) {
        // The type of the expression is known precisely, so an implicit
        // downcast is guaranteed to fail.  Insert a compile-time error.
        var parent = expression.parent;
        var errorNode = helper.wrapInCompileTimeError(
            expression, template.withArguments(actualType, expectedType));
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

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation using [fileOffset].
  ///
  /// For the special case where [receiverType] is a [FunctionType], and the
  /// method name is `call`, the string `call` is returned as a sentinel object.
  Object findInterfaceMember(DartType receiverType, Name name, int fileOffset,
      {Template<Message Function(String, DartType)> errorTemplate,
      Expression expression,
      Expression receiver,
      bool setter: false,
      bool silent: false}) {
    assert(receiverType != null && isKnown(receiverType));

    // Our non-strong golden files currently don't include interface
    // targets, so we can't store the interface target without causing tests
    // to fail.  TODO(paulberry): fix this.
    if (!strongMode) return null;

    receiverType = resolveTypeParameter(receiverType);

    if (receiverType is FunctionType && name.name == 'call') {
      return 'call';
    }

    Member interfaceMember;
    if (receiverType is! DynamicType) {
      Class classNode = receiverType is InterfaceType
          ? receiverType.classNode
          : coreTypes.objectClass;
      interfaceMember = _getInterfaceMember(classNode, name, setter);
      if (!silent && interfaceMember != null) {
        instrumentation?.record(uri, fileOffset, 'target',
            new InstrumentationValueForMember(interfaceMember));
      }
    }

    if (!isTopLevel &&
        interfaceMember == null &&
        receiverType is! DynamicType &&
        !(receiverType == coreTypes.functionClass.rawType &&
            name.name == 'call') &&
        errorTemplate != null) {
      expression.parent.replaceChild(
          expression,
          new Let(
              new VariableDeclaration.forValue(receiver)
                ..fileOffset = receiver.fileOffset,
              helper.buildCompileTimeError(
                  errorTemplate.withArguments(name.name, receiverType),
                  fileOffset,
                  noLength))
            ..fileOffset = fileOffset);
    }
    return interfaceMember;
  }

  /// Finds a member of [receiverType] called [name], and if it is found,
  /// reports it through instrumentation and records it in [methodInvocation].
  Object findMethodInvocationMember(
      DartType receiverType, InvocationExpression methodInvocation,
      {bool silent: false}) {
    // TODO(paulberry): could we add getters to InvocationExpression to make
    // these is-checks unnecessary?
    if (methodInvocation is MethodInvocation) {
      var interfaceMember = findInterfaceMember(
          receiverType, methodInvocation.name, methodInvocation.fileOffset,
          errorTemplate: templateUndefinedMethod,
          expression: methodInvocation,
          receiver: methodInvocation.receiver,
          silent: silent);
      if (strongMode && interfaceMember is Member) {
        methodInvocation.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else if (methodInvocation is SuperMethodInvocation) {
      var interfaceMember = findInterfaceMember(
          receiverType, methodInvocation.name, methodInvocation.fileOffset,
          silent: silent);
      if (strongMode && interfaceMember is Member) {
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
      {bool silent: false}) {
    // TODO(paulberry): could we add a common base class to PropertyGet and
    // SuperPropertyGet to make these is-checks unnecessary?
    if (propertyGet is PropertyGet) {
      var interfaceMember = findInterfaceMember(
          receiverType, propertyGet.name, propertyGet.fileOffset,
          errorTemplate: templateUndefinedGetter,
          expression: propertyGet,
          receiver: propertyGet.receiver,
          silent: silent);
      if (strongMode && interfaceMember is Member) {
        propertyGet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else if (propertyGet is SuperPropertyGet) {
      var interfaceMember = findInterfaceMember(
          receiverType, propertyGet.name, propertyGet.fileOffset,
          silent: silent);
      if (strongMode && interfaceMember is Member) {
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
      {bool silent: false}) {
    if (propertySet is PropertySet) {
      var interfaceMember = findInterfaceMember(
          receiverType, propertySet.name, propertySet.fileOffset,
          errorTemplate: templateUndefinedSetter,
          expression: propertySet,
          receiver: propertySet.receiver,
          setter: true,
          silent: silent);
      if (strongMode && interfaceMember is Member) {
        propertySet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else if (propertySet is SuperPropertySet) {
      var interfaceMember = findInterfaceMember(
          receiverType, propertySet.name, propertySet.fileOffset,
          setter: true, silent: silent);
      if (strongMode && interfaceMember is Member) {
        propertySet.interfaceTarget = interfaceMember;
      }
      return interfaceMember;
    } else {
      throw unhandled("${propertySet.runtimeType}", "findPropertySetMember",
          propertySet.fileOffset, uri);
    }
  }

  FunctionType getCalleeFunctionType(
      Object interfaceMember, DartType receiverType, bool followCall) {
    var type = getCalleeType(interfaceMember, receiverType);
    if (type is FunctionType) {
      return type;
    } else if (followCall && type is InterfaceType) {
      var member = _getInterfaceMember(type.classNode, callName, false);
      var callType = getCalleeType(member, type);
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
          calleeType = Substitution
              .fromInterfaceType(castedType)
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
          setterType = Substitution
              .fromInterfaceType(castedType)
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

  /// Determines the dispatch category of a [PropertyGet] and adds an "as" check
  /// if necessary due to contravariance.
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
    DispatchCategory callKind;
    if (receiver is ThisExpression || receiver == null) {
      callKind = DispatchCategory.viaThis;
    } else if (interfaceMember == null) {
      callKind = DispatchCategory.dynamicDispatch;
    } else {
      callKind = DispatchCategory.interface;
    }
    desugaredGet?.dispatchCategory = callKind;
    bool checkReturn = false;
    if (callKind == DispatchCategory.interface) {
      if (interfaceMember is Procedure) {
        checkReturn = interfaceMember.isGenericContravariant;
      } else if (interfaceMember is Field) {
        checkReturn = interfaceMember.isGenericContravariant;
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
    if (instrumentation != null) {
      int offset = expression.fileOffset;
      switch (callKind) {
        case DispatchCategory.dynamicDispatch:
          instrumentation.record(uri, offset, 'callKind',
              new InstrumentationValueLiteral('dynamic'));
          break;
        case DispatchCategory.viaThis:
          instrumentation.record(
              uri, offset, 'callKind', new InstrumentationValueLiteral('this'));
          break;
        default:
          break;
      }
      if (checkReturn) {
        instrumentation.record(uri, offset, 'checkReturn',
            new InstrumentationValueForType(inferredType));
      }
    }
    return replacedExpression;
  }

  /// Determines the dispatch category of a [PropertySet].
  void handlePropertySetContravariance(Expression receiver,
      Object interfaceMember, PropertySet desugaredSet, Expression expression) {
    DispatchCategory callKind;
    if (receiver is ThisExpression || receiver == null) {
      callKind = DispatchCategory.viaThis;
    } else if (interfaceMember == null) {
      callKind = DispatchCategory.dynamicDispatch;
    } else {
      callKind = DispatchCategory.interface;
    }
    desugaredSet?.dispatchCategory = callKind;
    if (instrumentation != null) {
      int offset = expression.fileOffset;
      switch (callKind) {
        case DispatchCategory.dynamicDispatch:
          instrumentation.record(uri, offset, 'callKind',
              new InstrumentationValueLiteral('dynamic'));
          break;
        case DispatchCategory.viaThis:
          instrumentation.record(
              uri, offset, 'callKind', new InstrumentationValueLiteral('this'));
          break;
        default:
          break;
      }
    }
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
      Expression expression, DartType typeContext, bool typeNeeded);

  @override
  void inferFieldInitializer(
      BuilderHelper helper, DartType declaredType, Expression initializer) {
    assert(closureContext == null);
    this.helper = helper;
    var actualType = inferExpression(
        initializer, declaredType ?? const UnknownType(), declaredType != null);
    if (declaredType != null) {
      ensureAssignable(
          declaredType, actualType, initializer, initializer.fileOffset);
    }
    this.helper = null;
  }

  /// Performs type inference on the given [field]'s initializer expression.
  ///
  /// Derived classes should provide an implementation that calls
  /// [inferExpression] for the given [field]'s initializer expression.
  DartType inferFieldTopLevel(ShadowField field, bool typeNeeded);

  @override
  void inferFunctionBody(BuilderHelper helper, DartType returnType,
      AsyncMarker asyncMarker, Statement body) {
    assert(closureContext == null);
    this.helper = helper;
    closureContext =
        new ClosureContext(this, asyncMarker, returnType, false, true);
    inferStatement(body);
    closureContext = null;
    this.helper = null;
  }

  /// Performs the type inference steps that are shared by all kinds of
  /// invocations (constructors, instance methods, and static methods).
  DartType inferInvocation(DartType typeContext, int offset,
      FunctionType calleeType, DartType returnType, Arguments arguments,
      {bool isOverloadedArithmeticOperator: false,
      DartType receiverType,
      bool skipTypeArgumentInference: false,
      bool isConst: false}) {
    lastInferredSubstitution = null;
    lastCalleeType = null;
    var calleeTypeParameters = calleeType.typeParameters;
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
        strongMode &&
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
      CalleeDesignation calleeKind = receiverType is FunctionType
          ? CalleeDesignation.Function
          : CalleeDesignation.Method;
      LocatedMessage argMessage = helper.checkArguments(
          new FunctionTypeAccessor.fromType(calleeType),
          arguments,
          calleeKind,
          offset);
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
              expectedType, actualType, expression, expression.fileOffset);
        }
      }
    }
    DartType inferredType;
    lastInferredSubstitution = substitution;
    lastCalleeType = calleeType;
    inferredType = substitution == null
        ? returnType
        : substitution.substituteType(returnType);
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
      var positionalParameters = function.positionalParameters;
      for (var i = 0; i < positionalParameters.length; i++) {
        var parameter = positionalParameters[i];
        if (i >= function.requiredParameterCount &&
            parameter.initializer == null) {
          parameter.initializer = new ShadowNullLiteral()..parent = parameter;
        }
        if (parameter.initializer != null) {
          inferExpression(parameter.initializer, parameter.type, false);
        }
      }
      for (var parameter in function.namedParameters) {
        if (parameter.initializer == null) {
          parameter.initializer = new ShadowNullLiteral()..parent = parameter;
        }
        inferExpression(parameter.initializer, parameter.type, false);
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
    if (strongMode && typeContext is FunctionType) {
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
      ShadowVariableDeclaration formal = formals[i];
      if (ShadowVariableDeclaration.isImplicitlyTyped(formal)) {
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
    bool needToSetReturnType = hasImplicitReturnType && strongMode;
    ClosureContext oldClosureContext = this.closureContext;
    bool needImplicitDowncasts = returnContext != null;
    ClosureContext closureContext = new ClosureContext(
        this,
        function.asyncMarker,
        returnContext,
        needToSetReturnType,
        needImplicitDowncasts);
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
    } else if (!strongMode && hasImplicitReturnType) {
      function.returnType =
          closureContext._wrapAsyncOrGenerator(this, const DynamicType());
    }
    this.closureContext = oldClosureContext;
    return function.functionType;
  }

  @override
  void inferMetadata(BuilderHelper helper, List<Expression> annotations) {
    if (annotations != null) {
      this.helper = helper;
      // Place annotations in a temporary list literal so that they will have a
      // parent.  This is necessary in case any of the annotations need to get
      // replaced during type inference.
      new ListLiteral(annotations);
      for (var annotation in annotations) {
        inferExpression(annotation, const UnknownType(), false);
      }
      this.helper = null;
    }
  }

  /// Performs the core type inference algorithm for method invocations (this
  /// handles both null-aware and non-null-aware method invocations).
  DartType inferMethodInvocation(Expression expression, Expression receiver,
      int fileOffset, bool isImplicitCall, DartType typeContext,
      {VariableDeclaration receiverVariable,
      MethodInvocation desugaredInvocation,
      Object interfaceMember,
      Name methodName,
      Arguments arguments}) {
    // First infer the receiver so we can look up the method that was invoked.
    var receiverType = receiver == null
        ? thisType
        : inferExpression(receiver, const UnknownType(), true);
    if (strongMode) {
      receiverVariable?.type = receiverType;
    }
    bool isOverloadedArithmeticOperator = false;
    if (desugaredInvocation != null) {
      interfaceMember =
          findMethodInvocationMember(receiverType, desugaredInvocation);
      methodName = desugaredInvocation.name;
      arguments = desugaredInvocation.arguments;
    }
    if (interfaceMember is Procedure) {
      isOverloadedArithmeticOperator = typeSchemaEnvironment
          .isOverloadedArithmeticOperatorAndType(interfaceMember, receiverType);
    }
    var calleeType =
        getCalleeFunctionType(interfaceMember, receiverType, !isImplicitCall);
    var checkKind = preCheckInvocationContravariance(receiver, receiverType,
        interfaceMember, desugaredInvocation, arguments, expression);
    var inferredType = inferInvocation(
        typeContext, fileOffset, calleeType, calleeType.returnType, arguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        receiverType: receiverType);
    if (methodName.name == '==') {
      inferredType = coreTypes.boolClass.rawType;
    }
    handleInvocationContravariance(checkKind, desugaredInvocation, arguments,
        expression, inferredType, calleeType, fileOffset);
    if (!identical(interfaceMember, 'call') &&
        strongMode &&
        isImplicitCall &&
        interfaceMember != null &&
        !(interfaceMember is Procedure &&
            interfaceMember.kind == ProcedureKind.Method) &&
        receiverType is! DynamicType &&
        receiverType != typeSchemaEnvironment.rawFunctionType) {
      var parent = expression.parent;
      var errorNode = helper.wrapInCompileTimeError(expression,
          templateImplicitCallOfNonMethod.withArguments(receiverType));
      parent?.replaceChild(expression, errorNode);
    }
    return inferredType;
  }

  @override
  void inferParameterInitializer(
      BuilderHelper helper, Expression initializer, DartType declaredType) {
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
  DartType inferPropertyGet(Expression expression, Expression receiver,
      int fileOffset, DartType typeContext,
      {VariableDeclaration receiverVariable,
      PropertyGet desugaredGet,
      Object interfaceMember,
      Name propertyName}) {
    // First infer the receiver so we can look up the getter that was invoked.
    var receiverType = receiver == null
        ? thisType
        : inferExpression(receiver, const UnknownType(), true);
    if (strongMode) {
      receiverVariable?.type = receiverType;
    }
    propertyName ??= desugaredGet.name;
    if (desugaredGet != null) {
      interfaceMember = findInterfaceMember(
          receiverType, propertyName, fileOffset,
          errorTemplate: templateUndefinedGetter,
          expression: expression,
          receiver: desugaredGet.receiver);
      if (interfaceMember is Member) {
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
    return inferredType;
  }

  /// Modifies a type as appropriate when inferring a closure return type.
  DartType inferReturnType(DartType returnType) {
    if (returnType == null) {
      // Analyzer infers `Null` if there is no `return` expression; the spec
      // says to return `void`.  TODO(paulberry): resolve this difference.
      return coreTypes.nullClass.rawType;
    }
    return returnType;
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
    if (strongMode &&
        tearoffType is FunctionType &&
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
    DispatchCategory callKind;
    var checkKind = MethodContravarianceCheckKind.none;
    if (interfaceMember is Field ||
        interfaceMember is Procedure &&
            interfaceMember.kind == ProcedureKind.Getter) {
      var getType = getCalleeType(interfaceMember, receiverType);
      if (getType is DynamicType) {
        callKind = DispatchCategory.dynamicDispatch;
      } else {
        callKind = DispatchCategory.closure;
        if (receiver is! ThisExpression && receiver != null) {
          if (interfaceMember is Field &&
              interfaceMember.isGenericContravariant) {
            checkKind = MethodContravarianceCheckKind.checkGetterReturn;
          } else if (interfaceMember is Procedure &&
              interfaceMember.isGenericContravariant) {
            checkKind = MethodContravarianceCheckKind.checkGetterReturn;
          }
        }
      }
    } else if (receiver is ThisExpression || receiver == null) {
      callKind = DispatchCategory.viaThis;
    } else if (identical(interfaceMember, 'call')) {
      callKind = DispatchCategory.closure;
    } else if (interfaceMember == null) {
      callKind = DispatchCategory.dynamicDispatch;
    } else {
      callKind = DispatchCategory.interface;
      if (interfaceMember is Procedure &&
          interfaceMember.isGenericContravariant) {
        checkKind = MethodContravarianceCheckKind.checkMethodReturn;
      }
    }
    desugaredInvocation?.dispatchCategory = callKind;
    if (instrumentation != null) {
      int offset = arguments.fileOffset == -1
          ? expression.fileOffset
          : arguments.fileOffset;
      switch (callKind) {
        case DispatchCategory.closure:
          instrumentation.record(uri, offset, 'callKind',
              new InstrumentationValueLiteral('closure'));
          break;
        case DispatchCategory.dynamicDispatch:
          instrumentation.record(uri, offset, 'callKind',
              new InstrumentationValueLiteral('dynamic'));
          break;
        case DispatchCategory.viaThis:
          instrumentation.record(
              uri, offset, 'callKind', new InstrumentationValueLiteral('this'));
          break;
        default:
          break;
      }
    }
    return checkKind;
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
        ShadowMember.resolveInferenceNode(member);
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
    if (expression is FunctionExpression) {
      return templateInvalidCastFunctionExpr;
    }
    if (expression is ConstructorInvocation) {
      if (ShadowConstructorInvocation.isRedirected(expression)) {
        return null;
      } else {
        return templateInvalidCastNewExpr;
      }
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
      if (variable is ShadowVariableDeclaration &&
          ShadowVariableDeclaration.isLocalFunction(variable)) {
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

class LegacyModeMixinInferrer implements MixinInferrer {
  void infer(ClassHierarchy hierarchy, Class classNode) {
    Supertype mixedInType = classNode.mixedInType;
    if (mixedInType.typeArguments.isNotEmpty &&
        mixedInType.typeArguments.first == const UnknownType()) {
      assert(mixedInType.typeArguments.every((t) => t == const UnknownType()));
      for (int i = 0; i < mixedInType.typeArguments.length; ++i) {
        mixedInType.typeArguments[i] = const DynamicType();
      }
    }
  }
}

class StrongModeMixinInferrer implements MixinInferrer {
  final CoreTypes coreTypes;
  final SourceLoader loader;
  TypeConstraintGatherer gatherer;

  StrongModeMixinInferrer(this.loader) : coreTypes = loader.coreTypes;

  void generateConstraints(ClassHierarchy hierarchy, Class mixinClass,
      Supertype baseType, Supertype mixinSupertype) {
    if (mixinSupertype.typeArguments.isEmpty) {
      // The supertype constraint isn't generic; it doesn't constrain anything.
    } else if (mixinSupertype.classNode.isSyntheticMixinImplementation) {
      // We had a mixin M<X0, ..., Xn> with a superclass constraint of the form
      // S0 with M0 where S0 and M0 each possibly have type arguments.  That has
      // been compiled a named mixin application class of the form
      //
      // class S0&M0<...> = S0 with M0;
      // class M<X0, ..., Xn> extends S0&M0<...>
      //
      // where the type parameters of S0&M0 are the X0, ..., Xn that occured
      // free in S0 and M0.  Treat S0 and M0 as separate supertype constraints
      // by recursively calling this algorithm.
      //
      // In some back ends (e.g., the Dart VM) the mixin application classes
      // themselves are all eliminated by translating them to normal classes.
      // In that case, the mixin appears as the only interface in the
      // introduced class:
      //
      // class S0&M0<...> extends S0 implements M0 {}
      var mixinSuperclass = mixinSupertype.classNode;
      if (mixinSuperclass.mixedInType == null &&
          mixinSuperclass.implementedTypes.length != 1) {
        unexpected(
            'Compiler-generated mixin applications have a mixin or else '
            'implement exactly one type',
            '$mixinSuperclass implements '
            '${mixinSuperclass.implementedTypes.length} types',
            mixinSuperclass.fileOffset,
            mixinSuperclass.fileUri);
      }
      var substitution = Substitution.fromSupertype(mixinSupertype);
      var s0 = substitution.substituteSupertype(mixinSuperclass.supertype);
      var m0 = substitution.substituteSupertype(mixinSuperclass.mixedInType ??
          mixinSuperclass.implementedTypes.first);
      generateConstraints(hierarchy, mixinClass, baseType, s0);
      generateConstraints(hierarchy, mixinClass, baseType, m0);
    } else {
      // Find the type U0 which is baseType as an instance of mixinSupertype's
      // class.
      Supertype supertype =
          hierarchy.asInstantiationOf(baseType, mixinSupertype.classNode);
      if (supertype == null) {
        loader.addProblem(
            templateMixinInferenceNoMatchingClass.withArguments(mixinClass.name,
                baseType.classNode.name, mixinSupertype.asInterfaceType),
            mixinClass.fileOffset,
            noLength,
            mixinClass.fileUri);
        return;
      }
      InterfaceType u0 = Substitution
          .fromSupertype(baseType)
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

  void infer(ClassHierarchy hierarchy, Class classNode) {
    Supertype mixedInType = classNode.mixedInType;
    if (mixedInType.typeArguments.isNotEmpty &&
        mixedInType.typeArguments.first == const UnknownType()) {
      assert(mixedInType.typeArguments.every((t) => t == const UnknownType()));
      // Note that we have no anonymous mixin applications, they have all
      // been named.  Note also that mixin composition has been translated
      // so that we only have mixin applications of the form `S with M`.
      Supertype baseType = classNode.supertype;
      Class mixinClass = mixedInType.classNode;
      Supertype mixinSupertype = mixinClass.supertype;
      gatherer = new TypeConstraintGatherer(
          new TypeSchemaEnvironment(loader.coreTypes, hierarchy, true),
          mixinClass.typeParameters);
      // Generate constraints based on the mixin's supertype.
      generateConstraints(hierarchy, mixinClass, baseType, mixinSupertype);
      // Solve them to get a map from type parameters to upper and lower
      // bounds.
      var result = gatherer.computeConstraints();
      // Generate new type parameters with the solution as bounds.
      List<TypeParameter> parameters = mixinClass.typeParameters.map((p) {
        var constraint = result[p];
        // Because we solved for equality, a valid solution has a parameter
        // either unconstrained or else with identical upper and lower bounds.
        if (constraint != null && constraint.upper != constraint.lower) {
          loader.addProblem(
              templateMixinInferenceNoMatchingClass.withArguments(
                  mixinClass.name,
                  baseType.classNode.name,
                  mixinSupertype.asInterfaceType),
              mixinClass.fileOffset,
              noLength,
              mixinClass.fileUri);
          return p;
        }
        assert(constraint == null || constraint.upper == constraint.lower);
        return new TypeParameter(
            p.name,
            constraint == null || constraint.upper == const UnknownType()
                ? p.bound
                : constraint.upper);
      }).toList();
      // Bounds might mention the mixin class's type parameters so we have to
      // substitute them before calling instantiate to bounds.
      var substitution = Substitution.fromPairs(mixinClass.typeParameters,
          parameters.map((p) => new TypeParameterType(p)).toList());
      for (var p in parameters) {
        p.bound = substitution.substituteType(p.bound);
      }
      // Use instantiate to bounds.
      List<DartType> bounds =
          calculateBounds(parameters, loader.coreTypes.objectClass);
      for (int i = 0; i < mixedInType.typeArguments.length; ++i) {
        mixedInType.typeArguments[i] = bounds[i];
      }
      gatherer = null;
    }
  }
}
