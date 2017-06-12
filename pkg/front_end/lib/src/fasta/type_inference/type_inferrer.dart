// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_elimination.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
        BottomType,
        Class,
        DartType,
        DynamicType,
        Expression,
        Field,
        FunctionType,
        InterfaceType,
        Member,
        Name,
        Procedure,
        Statement,
        TypeParameterType,
        VariableDeclaration,
        VoidType;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

/// Keeps track of information about the innermost function or closure being
/// inferred.
class ClosureContext {
  final bool isAsync;

  final bool isGenerator;

  final DartType returnContext;

  DartType _inferredReturnType;

  factory ClosureContext(TypeInferrerImpl inferrer, AsyncMarker asyncMarker,
      DartType returnContext) {
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
      // TODO(paulberry): do we have to handle FutureOr<> here?
      returnContext = inferrer.getTypeArgumentOf(
          returnContext, inferrer.coreTypes.futureClass);
    }
    return new ClosureContext._(isAsync, isGenerator, returnContext);
  }

  ClosureContext._(this.isAsync, this.isGenerator, this.returnContext);

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  void handleReturn(TypeInferrerImpl inferrer, DartType type) {
    if (isGenerator) return;
    if (isAsync) {
      type = inferrer.typeSchemaEnvironment.flattenFutures(type);
    }
    _updateInferredReturnType(inferrer, type);
  }

  void handleYield(TypeInferrerImpl inferrer, bool isYieldStar, DartType type) {
    if (!isGenerator) return;
    if (isYieldStar) {
      type = inferrer.getDerivedTypeArgumentOf(
          type,
          isAsync
              ? inferrer.coreTypes.streamClass
              : inferrer.coreTypes.iterableClass);
      if (type == null) return;
    }
    _updateInferredReturnType(inferrer, type);
  }

  DartType inferReturnType(
      TypeInferrerImpl inferrer, bool isExpressionFunction) {
    DartType inferredReturnType =
        inferrer.inferReturnType(_inferredReturnType, isExpressionFunction);
    if (!isExpressionFunction &&
        returnContext != null &&
        (!inferrer.typeSchemaEnvironment
                .isSubtypeOf(inferredReturnType, returnContext) ||
            returnContext is VoidType)) {
      // For block-bodied functions, if the inferred return type isn't a
      // subtype of the context (or the context is void), we use the context.
      // TODO(paulberry): this is inherited from analyzer; it's not part of
      // the spec.  See also dartbug.com/29606.
      inferredReturnType = greatestClosure(inferrer.coreTypes, returnContext);
    }

    if (isGenerator) {
      if (isAsync) {
        inferredReturnType = inferrer.wrapType(
            inferredReturnType, inferrer.coreTypes.streamClass);
      } else {
        inferredReturnType = inferrer.wrapType(
            inferredReturnType, inferrer.coreTypes.iterableClass);
      }
    } else if (isAsync) {
      inferredReturnType = inferrer.wrapFutureType(inferredReturnType);
    }

    return inferredReturnType;
  }

  void _updateInferredReturnType(TypeInferrerImpl inferrer, DartType type) {
    if (_inferredReturnType == null) {
      _inferredReturnType = type;
    } else {
      _inferredReturnType = inferrer.typeSchemaEnvironment
          .getLeastUpperBound(_inferredReturnType, type);
    }
  }
}

/// Keeps track of the local state for the type inference that occurs during
/// compilation of a single method body or top level initializer.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. BodyBuilder).  Derived classes should derive from [TypeInferrerImpl].
abstract class TypeInferrer {
  /// Gets the [TypePromoter] that can be used to perform type promotion within
  /// this method body or initializer.
  TypePromoter<Expression, VariableDeclaration> get typePromoter;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  String get uri;

  /// Gets the [FieldNode] corresponding to the given [readTarget], if any.
  FieldNode getFieldNodeForReadTarget(Member readTarget);

  /// Performs type inference on the given function body.
  void inferFunctionBody(
      DartType returnType, AsyncMarker asyncMarker, Statement body);
}

/// Derived class containing generic implementations of [TypeInferrer].
///
/// This class contains as much of the implementation of type inference as
/// possible without knowing the identity of the type parameters.  It defers to
/// abstract methods for everything else.
abstract class TypeInferrerImpl extends TypeInferrer {
  static final FunctionType _functionReturningDynamic =
      new FunctionType(const [], const DynamicType());

  @override
  final String uri;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  final bool isTopLevel = false;

  final CoreTypes coreTypes;

  final bool strongMode;

  final ClassHierarchy classHierarchy;

  final Instrumentation instrumentation;

  final TypeSchemaEnvironment typeSchemaEnvironment;

  final TypeInferenceListener listener;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  ClosureContext closureContext;

  TypeInferrerImpl(TypeInferenceEngineImpl engine, this.uri, this.listener)
      : coreTypes = engine.coreTypes,
        strongMode = engine.strongMode,
        classHierarchy = engine.classHierarchy,
        instrumentation = engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment;

  /// Gets the type promoter that should be used to promote types during
  /// inference.
  TypePromoter<Expression, VariableDeclaration> get typePromoter;

  FunctionType getCalleeFunctionType(Member interfaceMember,
      DartType receiverType, Name methodName, int offset) {
    if (receiverType is InterfaceType) {
      if (interfaceMember == null) return _functionReturningDynamic;
      var memberClass = interfaceMember.enclosingClass;
      if (interfaceMember is Procedure) {
        instrumentation?.record(Uri.parse(uri), offset, 'target',
            new InstrumentationValueForProcedure(interfaceMember));
        var memberFunctionType = interfaceMember.function.functionType;
        if (memberClass.typeParameters.isNotEmpty) {
          var castedType = classHierarchy.getClassAsInstanceOf(
              receiverType.classNode, memberClass);
          memberFunctionType = Substitution
              .fromInterfaceType(Substitution
                  .fromInterfaceType(receiverType)
                  .substituteType(castedType.asInterfaceType))
              .substituteType(memberFunctionType);
        }
        return memberFunctionType;
      } else if (interfaceMember is Field) {
        // TODO(paulberry): handle this case
        return _functionReturningDynamic;
      } else {
        return _functionReturningDynamic;
      }
    } else if (receiverType is DynamicType) {
      return _functionReturningDynamic;
    } else if (receiverType is FunctionType) {
      // TODO(paulberry): handle the case of invoking .call() or .toString() on
      // a function type.
      return _functionReturningDynamic;
    } else if (receiverType is TypeParameterType) {
      // TODO(paulberry): use the bound
      return _functionReturningDynamic;
    } else {
      // TODO(paulberry): handle the case of invoking .toString() on a type
      // that's none of the above (e.g. `dynamic` or `bottom`)
      return _functionReturningDynamic;
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
  Expression getFieldInitializer(KernelField field);

  DartType getNamedParameterType(FunctionType functionType, String name) {
    return functionType.getNamedParameter(name) ?? const DynamicType();
  }

  DartType getPositionalParameterType(FunctionType functionType, int i) {
    if (i < functionType.positionalParameters.length) {
      return functionType.positionalParameters[i];
    } else {
      return const DynamicType();
    }
  }

  DartType getTypeArgumentOf(DartType type, Class class_) {
    if (type is InterfaceType && identical(type.classNode, class_)) {
      return type.typeArguments[0];
    } else {
      return null;
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

  /// Performs type inference on the given [field]'s initializer expression.
  ///
  /// Derived classes should provide an implementation that calls
  /// [inferExpression] for the given [field]'s initializer expression.
  DartType inferFieldInitializer(
      KernelField field, DartType type, bool typeNeeded);

  @override
  void inferFunctionBody(
      DartType returnType, AsyncMarker asyncMarker, Statement body) {
    assert(closureContext == null);
    closureContext = new ClosureContext(this, asyncMarker, returnType);
    inferStatement(body);
    closureContext = null;
  }

  /// Performs the type inference steps that are shared by all kinds of
  /// invocations (constructors, instance methods, and static methods).
  DartType inferInvocation(DartType typeContext, bool typeNeeded, int offset,
      FunctionType calleeType, DartType returnType, Arguments arguments,
      {bool isOverloadedArithmeticOperator: false, DartType receiverType}) {
    var calleeTypeParameters = calleeType.typeParameters;
    List<DartType> explicitTypeArguments = getExplicitTypeArguments(arguments);
    bool inferenceNeeded = explicitTypeArguments == null &&
        strongMode &&
        calleeTypeParameters.isNotEmpty;
    List<DartType> inferredTypes;
    Substitution substitution;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    if (inferenceNeeded) {
      inferredTypes = new List<DartType>.filled(
          calleeTypeParameters.length, const UnknownType());
      typeSchemaEnvironment.inferGenericFunctionOrType(returnType,
          calleeTypeParameters, null, null, typeContext, inferredTypes);
      substitution =
          Substitution.fromPairs(calleeTypeParameters, inferredTypes);
      formalTypes = [];
      actualTypes = [];
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
    int i = 0;
    _forEachArgument(arguments, (name, expression) {
      DartType formalType = name != null
          ? getNamedParameterType(calleeType, name)
          : getPositionalParameterType(calleeType, i++);
      DartType inferredFormalType = substitution != null
          ? substitution.substituteType(formalType)
          : formalType;
      var expressionType = inferExpression(expression, inferredFormalType,
          inferenceNeeded || isOverloadedArithmeticOperator);
      if (inferenceNeeded) {
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
      instrumentation?.record(Uri.parse(uri), offset, 'typeArgs',
          new InstrumentationValueForTypeArgs(inferredTypes));
      arguments.types.clear();
      arguments.types.addAll(inferredTypes);
    }
    DartType inferredType;
    if (typeNeeded) {
      inferredType = substitution == null
          ? returnType
          : substitution.substituteType(returnType);
    }
    return inferredType;
  }

  /// Modifies a type as appropriate when inferring a closure return type.
  DartType inferReturnType(DartType returnType, bool isExpressionFunction) {
    if (returnType == null) {
      // Analyzer infers `Null` if there is no `return` expression; the spec
      // says to return `void`.  TODO(paulberry): resolve this difference.
      return coreTypes.nullClass.rawType;
    }
    if (isExpressionFunction &&
        returnType is InterfaceType &&
        identical(returnType.classNode, coreTypes.nullClass)) {
      // Analyzer coerces `Null` to `dynamic` in expression functions; the spec
      // doesn't say to do this.  TODO(paulberry): resolve this difference.
      return const DynamicType();
    }
    return returnType;
  }

  /// Performs type inference on the given [statement].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the statement type and calls the appropriate specialized "infer" method.
  void inferStatement(Statement statement);

  DartType wrapFutureType(DartType type) {
    var typeWithoutFutureOr = type;
    if (type is InterfaceType &&
        identical(type.classNode, coreTypes.futureOrClass)) {
      typeWithoutFutureOr = type.typeArguments[0];
    }
    return new InterfaceType(coreTypes.futureClass,
        <DartType>[typeSchemaEnvironment.flattenFutures(typeWithoutFutureOr)]);
  }

  DartType wrapType(DartType type, Class class_) {
    return new InterfaceType(class_, <DartType>[type]);
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
}
