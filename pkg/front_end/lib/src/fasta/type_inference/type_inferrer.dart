// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:kernel/ast.dart'
    show DartType, DynamicType, InterfaceType, Member;
import 'package:kernel/core_types.dart';

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

  _InferenceContext _context;

  TypeInferrerImpl(TypeInferenceEngineImpl<F> engine, this.uri)
      : coreTypes = engine.coreTypes,
        strongMode = engine.strongMode,
        instrumentation = engine.instrumentation {
    // The return type only needs to be inferred for closures, so we can safely
    // set isAsync and isGenerator to false in the outermost context.
    // TODO(paulberry): this seems brittle.  Would it be better to leave
    // _context as `null` here?
    _context = new _InferenceContext(false, false);
  }

  /// Gets the type promoter that should be used to promote types during
  /// inference.
  TypePromoter<E, V> get typePromoter;

  /// Gets the initializer for the given [field], or `null` if there is no
  /// initializer.
  E getFieldInitializer(F field);

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
    _InferenceContext oldContext = _context;
    _context = new _InferenceContext(isAsync, isGenerator);
    inferStatement(body);
    DartType inferredReturnType;
    if (needToSetReturnType || typeNeeded) {
      inferredReturnType = _context.inferredReturnType;
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
    _context = oldContext;
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
    var inferredType =
        inferExpression(initializer, declaredType, declaredType == null);
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
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _InferenceContext {
  final bool isAsync;

  final bool isGenerator;

  DartType _inferredReturnType;

  _InferenceContext(this.isAsync, this.isGenerator);

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
