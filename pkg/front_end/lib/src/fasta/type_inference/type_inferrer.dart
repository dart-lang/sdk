// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart'
    show
        BottomType,
        Constructor,
        DartType,
        DynamicType,
        FunctionNode,
        InterfaceType,
        Member;
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

/// Keeps track of the local state for the type inference that occurs during
/// compilation of a single method body or top level initializer.
///
/// This class abstracts away the representation of the underlying AST using
/// generic parameters.  TODO(paulberry): would it make more sense to abstract
/// away the representation of types as well?
///
/// Derived classes should set S, E, V, and F to the class they use to represent
/// statements, expressions, variable declarations, and field declarations,
/// respectively.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. BodyBuilder).  Derived classes should derive from [TypeInferrerImpl].
abstract class TypeInferrer<S, E, V, F> {
  /// Gets the [TypePromoter] that can be used to perform type promotion within
  /// this method body or initializer.
  TypePromoter<E, V> get typePromoter;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  String get uri;

  /// Gets the [FieldNode] corresponding to the given [readTarget], if any.
  FieldNode<F> getFieldNodeForReadTarget(Member readTarget);

  /// Performs type inference on the given [statement].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the statement type and calls the appropriate specialized "infer" method.
  void inferStatement(S statement);
}

/// Derived class containing generic implementations of [TypeInferrer].
///
/// This class contains as much of the implementation of type inference as
/// possible without knowing the identity of the type parameters.  It defers to
/// abstract methods for everything else.
abstract class TypeInferrerImpl<S, E, V, F> extends TypeInferrer<S, E, V, F> {
  @override
  final String uri;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  final bool isTopLevel = false;

  final CoreTypes coreTypes;

  final bool strongMode;

  final Instrumentation instrumentation;

  final TypeSchemaEnvironment typeSchemaEnvironment;

  /// Context information for the current closure, or `null` if we are not
  /// inside a closure.
  _ClosureContext _closureContext;

  TypeInferrerImpl(TypeInferenceEngineImpl<F> engine, this.uri)
      : coreTypes = engine.coreTypes,
        strongMode = engine.strongMode,
        instrumentation = engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment;

  /// Gets the type promoter that should be used to promote types during
  /// inference.
  TypePromoter<E, V> get typePromoter;

  /// Gets the initializer for the given [field], or `null` if there is no
  /// initializer.
  E getFieldInitializer(F field);

  /// Performs the core type inference algorithm for type cast expressions.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferAsExpression(
      DartType typeContext, bool typeNeeded, E operand, DartType type) {
    inferExpression(operand, null, false);
    return typeNeeded ? type : null;
  }

  /// Performs the core type inference algorithm for boolean literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferBoolLiteral(DartType typeContext, bool typeNeeded) {
    return typeNeeded ? coreTypes.boolClass.rawType : null;
  }

  /// Performs the core type inference algorithm for conditional expressions.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  ///
  /// [condition], [then], and [otherwise] are the subexpressions.  The inferred
  /// type is reported via [setStaticType].
  DartType inferConditionalExpression(DartType typeContext, bool typeNeeded,
      E condition, E then, E otherwise, void setStaticType(DartType type)) {
    inferExpression(condition, coreTypes.boolClass.rawType, false);
    // TODO(paulberry): is it correct to pass the context down?
    DartType thenType = inferExpression(then, typeContext, true);
    DartType otherwiseType = inferExpression(otherwise, typeContext, true);
    // TODO(paulberry): the spec proposal says we should only use LUB if the
    // typeContext is `null`.  If typeContext is non-null, we should use the
    // greatest closure of the context with respect to `?`
    DartType type =
        typeSchemaEnvironment.getLeastUpperBound(thenType, otherwiseType);
    setStaticType(type);
    return typeNeeded ? type : null;
  }

  /// Performs the core type inference algorithm for constructor invocations.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  ///
  /// [offset] is the location of the constructor invocation in the source file.
  /// [target] is the constructor that is being called.  [explicitTypeArguments]
  /// is the set of type arguments explicitly provided, or `null` if no type
  /// arguments were provided.  [forEachArgument] is a callback which can be
  /// used to iterate through all constructor arguments (both named and
  /// positional).  [setInferredTypeArguments] is a callback which can be used
  /// to record the inferred type arguments.
  DartType inferConstructorInvocation(
      DartType typeContext,
      bool typeNeeded,
      int offset,
      Constructor target,
      List<DartType> explicitTypeArguments,
      void forEachArgument(void callback(String name, E expression)),
      void setInferredTypeArguments(List<DartType> types)) {
    List<DartType> inferredTypes;
    Substitution substitution;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    var targetClass = target.enclosingClass;
    var targetTypeParameters = targetClass.typeParameters;
    bool inferenceNeeded = explicitTypeArguments == null &&
        strongMode &&
        targetTypeParameters.isNotEmpty;
    if (inferenceNeeded) {
      inferredTypes = new List<DartType>.filled(
          targetTypeParameters.length, const UnknownType());
      typeSchemaEnvironment.inferGenericFunctionOrType(targetClass.thisType,
          targetClass.typeParameters, null, null, typeContext, inferredTypes);
      substitution =
          Substitution.fromPairs(targetTypeParameters, inferredTypes);
      formalTypes = [];
      actualTypes = [];
    } else if (explicitTypeArguments != null) {
      substitution =
          Substitution.fromPairs(targetTypeParameters, explicitTypeArguments);
    }
    int i = 0;
    forEachArgument((name, expression) {
      DartType formalType = name != null
          ? _getNamedParameterType(target.function, name)
          : _getPositionalParameterType(target.function, i++);
      DartType inferredFormalType = substitution != null
          ? substitution.substituteType(formalType)
          : formalType;
      var expressionType =
          inferExpression(expression, inferredFormalType, inferenceNeeded);
      if (inferenceNeeded) {
        formalTypes.add(formalType);
        actualTypes.add(expressionType);
      }
    });
    if (inferenceNeeded) {
      typeSchemaEnvironment.inferGenericFunctionOrType(
          targetClass.thisType,
          targetClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      substitution =
          Substitution.fromPairs(targetTypeParameters, inferredTypes);
      instrumentation?.record(Uri.parse(uri), offset, 'typeArgs',
          new InstrumentationValueForTypeArgs(inferredTypes));
      setInferredTypeArguments(inferredTypes);
    }
    if (typeNeeded) {
      return substitution == null
          ? targetClass.rawType
          : substitution.substituteType(targetClass.thisType);
    } else {
      return null;
    }
  }

  /// Maps the type of a variable's initializer expression to the correct
  /// inferred type for the variable.
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

  /// Performs the core type inference algorithm for double literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferDoubleLiteral(DartType typeContext, bool typeNeeded) {
    return typeNeeded ? coreTypes.doubleClass.rawType : null;
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
  DartType inferExpression(E expression, DartType typeContext, bool typeNeeded);

  /// Performs the core type inference algorithm for expression statements.
  void inferExpressionStatement(E expression) {
    inferExpression(expression, null, false);
  }

  /// Performs type inference on the given [field]'s initializer expression.
  ///
  /// Derived classes should provide an implementation that calls
  /// [inferExpression] for the given [field]'s initializer expression.
  DartType inferFieldInitializer(F field, DartType type, bool typeNeeded);

  /// Performs the core type inference algorithm for function expressions.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  ///
  /// [body] is the body of the expression.  [isExpressionFunction] indicates
  /// whether the function expression was declared using "=>" syntax.  [isAsync]
  /// and [isGenerator] together indicate whether the function is marked as
  /// "async", "async*", or "sync*".  [offset] is the character offset of the
  /// function expression.
  ///
  /// [setReturnType] is a callback that will be used to store the return type
  /// of the function expression.  [getFunctionType] is a callback that will be
  /// used to query the function expression for its full expression type.
  DartType inferFunctionExpression(
      DartType typeContext,
      bool typeNeeded,
      S body,
      bool isExpressionFunction,
      bool isAsync,
      bool isGenerator,
      int offset,
      void setReturnType(DartType type),
      DartType getFunctionType()) {
    // TODO(paulberry): do we also need to visit default parameter values?
    // TODO(paulberry): infer argument types and type parameters.
    // TODO(paulberry): full support for generators.
    // TODO(paulberry): Dart 1.0 rules say we only need to set the function
    // node's return type if it uses expression syntax.  Does that make sense
    // for Dart 2.0?
    bool needToSetReturnType = isExpressionFunction;
    _ClosureContext oldClosureContext = _closureContext;
    _closureContext = new _ClosureContext(isAsync, isGenerator);
    inferStatement(body);
    DartType inferredReturnType;
    if (needToSetReturnType || typeNeeded) {
      inferredReturnType = _closureContext.inferredReturnType;
      if (isAsync) {
        inferredReturnType = new InterfaceType(
            coreTypes.futureClass, <DartType>[inferredReturnType]);
      }
    }
    if (needToSetReturnType) {
      instrumentation?.record(Uri.parse(uri), offset, 'returnType',
          new InstrumentationValueForType(inferredReturnType));
      setReturnType(inferredReturnType);
    }
    _closureContext = oldClosureContext;
    if (typeNeeded) {
      return getFunctionType();
    } else {
      return null;
    }
  }

  /// Performs the core type inference algorithm for if statements.
  void inferIfStatement(E condition, S then, S otherwise) {
    inferExpression(condition, coreTypes.boolClass.rawType, false);
    inferStatement(then);
    if (otherwise != null) inferStatement(otherwise);
  }

  /// Performs the core type inference algorithm for integer literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferIntLiteral(DartType typeContext, bool typeNeeded) {
    return typeNeeded ? coreTypes.intClass.rawType : null;
  }

  /// Performs the core type inference algorithm for an "is" expression.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  ///
  /// [operand] is the expression appearing to the left of "is".
  DartType inferIsExpression(DartType typeContext, bool typeNeeded, E operand) {
    inferExpression(operand, null, false);
    return typeNeeded ? coreTypes.boolClass.rawType : null;
  }

  /// Performs the core type inference algorithm for list literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferListLiteral(
      DartType typeContext,
      bool typeNeeded,
      int offset,
      DartType declaredTypeArgument,
      Iterable<E> expressions,
      void setTypeArgument(DartType typeArgument)) {
    var listClass = coreTypes.listClass;
    var listType = listClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = declaredTypeArgument == null && strongMode;
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType()];
      typeSchemaEnvironment.inferGenericFunctionOrType(listType,
          listClass.typeParameters, null, null, typeContext, inferredTypes);
      inferredTypeArgument = inferredTypes[0];
      formalTypes = [];
      actualTypes = [];
    } else {
      inferredTypeArgument = declaredTypeArgument ?? const DynamicType();
    }
    for (var expression in expressions) {
      var expressionType =
          inferExpression(expression, inferredTypeArgument, inferenceNeeded);
      if (inferenceNeeded) {
        formalTypes.add(listType.typeArguments[0]);
        actualTypes.add(expressionType);
      }
    }
    if (inferenceNeeded) {
      typeSchemaEnvironment.inferGenericFunctionOrType(
          listType,
          listClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      inferredTypeArgument = inferredTypes[0];
      instrumentation?.record(Uri.parse(uri), offset, 'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      setTypeArgument(inferredTypeArgument);
    }
    return typeNeeded
        ? new InterfaceType(listClass, [inferredTypeArgument])
        : null;
  }

  /// Performs the core type inference algorithm for null literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferNullLiteral(DartType typeContext, bool typeNeeded) {
    return typeNeeded ? coreTypes.nullClass.rawType : null;
  }

  /// Performs the core type inference algorithm for static variable getters.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  ///
  /// [getterType] is the type of the field being referenced, or the return type
  /// of the getter.
  DartType inferStaticGet(
      DartType typeContext, bool typeNeeded, DartType getterType) {
    return typeNeeded ? getterType : null;
  }

  /// Performs the core type inference algorithm for string concatenations.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferStringConcatenation(
      DartType typeContext, bool typeNeeded, Iterable<E> expressions) {
    for (E expression in expressions) {
      inferExpression(expression, null, false);
    }
    return typeNeeded ? coreTypes.stringClass.rawType : null;
  }

  /// Performs the core type inference algorithm for string literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferStringLiteral(DartType typeContext, bool typeNeeded) {
    return typeNeeded ? coreTypes.stringClass.rawType : null;
  }

  /// Performs the core type inference algorithm for variable declarations.
  ///
  /// [declaredType] is the declared type of the variable, or `null` if the type
  /// should be inferred.  [initializer] is the initializer expression.
  /// [offset] is the character offset of the variable declaration (for
  /// instrumentation).  [setType] is a callback that will be used to set the
  /// inferred type.
  void inferVariableDeclaration(DartType declaredType, E initializer,
      int offset, void setType(DartType type)) {
    if (initializer == null) return;
    var inferredType = inferDeclarationType(
        inferExpression(initializer, declaredType, declaredType == null));
    if (strongMode && declaredType == null) {
      instrumentation?.record(Uri.parse(uri), offset, 'type',
          new InstrumentationValueForType(inferredType));
      setType(inferredType);
    }
  }

  DartType inferVariableGet(
      DartType typeContext,
      bool typeNeeded,
      bool mutatedInClosure,
      TypePromotionFact<V> typePromotionFact,
      TypePromotionScope typePromotionScope,
      int offset,
      DartType declaredType,
      void setPromotedType(DartType type)) {
    DartType promotedType = typePromoter.computePromotedType(
        typePromotionFact, typePromotionScope, mutatedInClosure);
    instrumentation?.record(
        Uri.parse(uri),
        offset,
        'promotedType',
        promotedType != null
            ? new InstrumentationValueForType(promotedType)
            : const InstrumentationValueLiteral('none'));
    setPromotedType(promotedType);
    return typeNeeded
        ? (promotedType ?? declaredType ?? const DynamicType())
        : null;
  }

  DartType inferVariableSet(
      DartType typeContext, bool typeNeeded, DartType declaredType, E value) {
    return inferExpression(value, declaredType, typeNeeded);
  }

  DartType _getNamedParameterType(FunctionNode function, String name) {
    // TODO(paulberry): is there a kernel function that does this binary search?
    int lower = 0;
    int upper = function.namedParameters.length - 1;
    while (lower <= upper) {
      int pivot = (lower + upper) ~/ 2;
      int comparison = name.compareTo(function.namedParameters[pivot].name);
      if (comparison == 0) {
        return function.namedParameters[pivot].type;
      } else if (comparison < 0) {
        upper = pivot - 1;
      } else {
        lower = pivot + 1;
      }
    }
    return const DynamicType();
  }

  DartType _getPositionalParameterType(FunctionNode function, int i) {
    if (i < function.positionalParameters.length) {
      return function.positionalParameters[i].type;
    } else {
      return const DynamicType();
    }
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _ClosureContext {
  final bool isAsync;

  final bool isGenerator;

  DartType _inferredReturnType;

  _ClosureContext(this.isAsync, this.isGenerator);

  /// Gets the return type that was inferred for the current closure.
  get inferredReturnType {
    if (_inferredReturnType == null) {
      // No return statement found.
      // TODO(paulberry): is it correct to infer `dynamic`?
      return const DynamicType();
    }
    return _inferredReturnType;
  }
}
