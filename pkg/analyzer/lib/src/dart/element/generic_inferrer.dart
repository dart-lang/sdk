// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart' show AstNode, ConstructorName;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/error/codes.dart' show HintCode, StrongModeCode;
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';

bool _isBottom(DartType t) {
  return (t.isBottom && t.nullabilitySuffix != NullabilitySuffix.question) ||
      identical(t, UnknownInferredType.instance);
}

/// Is [t] the bottom of the legacy type hierarchy.
bool _isLegacyBottom(DartType t, {@required bool orTrueBottom}) {
  return (t.isBottom && t.nullabilitySuffix == NullabilitySuffix.question) ||
      t.isDartCoreNull ||
      (orTrueBottom ? _isBottom(t) : false);
}

/// Is [t] the top of the legacy type hierarch.
bool _isLegacyTop(DartType t, {@required bool orTrueTop}) {
  if (t.isDartAsyncFutureOr) {
    return _isLegacyTop((t as InterfaceType).typeArguments[0],
        orTrueTop: orTrueTop);
  }
  if (t.isObject && t.nullabilitySuffix == NullabilitySuffix.none) {
    return true;
  }
  return orTrueTop ? _isTop(t) : false;
}

bool _isTop(DartType t) {
  if (t.isDartAsyncFutureOr) {
    return _isTop((t as InterfaceType).typeArguments[0]);
  }
  return t.isDynamic ||
      (t.isObject && t.nullabilitySuffix != NullabilitySuffix.none) ||
      t.isVoid ||
      identical(t, UnknownInferredType.instance);
}

/// Tracks upper and lower type bounds for a set of type parameters.
///
/// This class is used by calling [isSubtypeOf]. When it encounters one of
/// the type parameters it is inferring, it will record the constraint, and
/// optimistically assume the constraint will be satisfied.
///
/// For example if we are inferring type parameter A, and we ask if
/// `A <: num`, this will record that A must be a subytpe of `num`. It also
/// handles cases when A appears as part of the structure of another type, for
/// example `Iterable<A> <: Iterable<num>` would infer the same constraint
/// (due to covariant generic types) as would `() -> A <: () -> num`. In
/// contrast `(A) -> void <: (num) -> void`.
///
/// Once the lower/upper bounds are determined, [infer] should be called to
/// finish the inference. It will instantiate a generic function type with the
/// inferred types for each type parameter.
///
/// It can also optionally compute a partial solution, in case some of the type
/// parameters could not be inferred (because the constraints cannot be
/// satisfied), or bail on the inference when this happens.
///
/// As currently designed, an instance of this class should only be used to
/// infer a single call and discarded immediately afterwards.
class GenericInferrer {
  final TypeSystemImpl _typeSystem;
  final Map<TypeParameterElement, List<_TypeConstraint>> constraints = {};

  /// Buffer recording constraints recorded while performing a recursive call to
  /// [_matchSubtypeOf] that might fail, so that any constraints recorded during
  /// the failed match can be rewound.
  final _undoBuffer = <_TypeConstraint>[];

  GenericInferrer(
    this._typeSystem,
    Iterable<TypeParameterElement> typeFormals,
  ) {
    for (var formal in typeFormals) {
      constraints[formal] = [];
    }
  }

  bool get isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeProvider get typeProvider => _typeSystem.typeProvider;

  /// Apply an argument constraint, which asserts that the [argument] staticType
  /// is a subtype of the [parameterType].
  void constrainArgument(
      DartType argumentType, DartType parameterType, String parameterName,
      {ClassElement genericClass}) {
    var origin = _TypeConstraintFromArgument(
      argumentType,
      parameterType,
      parameterName,
      genericClass: genericClass,
      isNonNullableByDefault: isNonNullableByDefault,
    );
    tryMatchSubtypeOf(argumentType, parameterType, origin, covariant: false);
  }

  /// Constrain a universal function type [fnType] used in a context
  /// [contextType].
  void constrainGenericFunctionInContext(
      FunctionType fnType, DartType contextType) {
    var origin = _TypeConstraintFromFunctionContext(
      fnType,
      contextType,
      isNonNullableByDefault: isNonNullableByDefault,
    );

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType = FunctionTypeImpl(
      typeFormals: const [],
      parameters: fnType.parameters,
      returnType: fnType.returnType,
      nullabilitySuffix: fnType.nullabilitySuffix,
    );
    tryMatchSubtypeOf(inferFnType, contextType, origin, covariant: true);
  }

  /// Apply a return type constraint, which asserts that the [declaredType]
  /// is a subtype of the [contextType].
  void constrainReturnType(DartType declaredType, DartType contextType) {
    var origin = _TypeConstraintFromReturnType(
      declaredType,
      contextType,
      isNonNullableByDefault: isNonNullableByDefault,
    );
    tryMatchSubtypeOf(declaredType, contextType, origin, covariant: true);
  }

  /// Given the constraints that were given by calling [constrainArgument] and
  /// [constrainReturnType], find the type arguments for the [typeFormals] that
  /// satisfies these constraints.
  ///
  /// If [downwardsInferPhase] is set, we are in the first pass of inference,
  /// pushing context types down. At that point we are allowed to push down
  /// `?` to precisely represent an unknown type. If [downwardsInferPhase] is
  /// false, we are on our final inference pass, have all available information
  /// including argument types, and must not conclude `?` for any type formal.
  List<DartType> infer(List<TypeParameterElement> typeFormals,
      {bool considerExtendsClause = true,
      ErrorReporter errorReporter,
      AstNode errorNode,
      bool failAtError = false,
      bool downwardsInferPhase = false}) {
    // Initialize the inferred type array.
    //
    // In the downwards phase, they all start as `?` to offer reasonable
    // degradation for f-bounded type parameters.
    var inferredTypes =
        List<DartType>.filled(typeFormals.length, UnknownInferredType.instance);

    for (int i = 0; i < typeFormals.length; i++) {
      // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
      // variance is added to the interface.
      TypeParameterElementImpl typeParam = typeFormals[i];
      _TypeConstraint extendsClause;
      if (considerExtendsClause && typeParam.bound != null) {
        extendsClause = _TypeConstraint.fromExtends(
          typeParam,
          Substitution.fromPairs(typeFormals, inferredTypes)
              .substituteType(typeParam.bound),
          isNonNullableByDefault: isNonNullableByDefault,
        );
      }

      inferredTypes[i] = downwardsInferPhase
          ? _inferTypeParameterFromContext(
              constraints[typeParam], extendsClause,
              isContravariant: typeParam.variance.isContravariant)
          : _inferTypeParameterFromAll(constraints[typeParam], extendsClause,
              isContravariant: typeParam.variance.isContravariant,
              preferUpwardsInference: !typeParam.isLegacyCovariant);
    }

    // If the downwards infer phase has failed, we'll catch this in the upwards
    // phase later on.
    if (downwardsInferPhase) {
      return inferredTypes;
    }

    // Check the inferred types against all of the constraints.
    var knownTypes = <TypeParameterElement, DartType>{};
    for (int i = 0; i < typeFormals.length; i++) {
      TypeParameterElement typeParam = typeFormals[i];
      var constraints = this.constraints[typeParam];
      var typeParamBound = typeParam.bound != null
          ? Substitution.fromPairs(typeFormals, inferredTypes)
              .substituteType(typeParam.bound)
          : typeProvider.dynamicType;

      var inferred = inferredTypes[i];
      bool success =
          constraints.every((c) => c.isSatisifedBy(_typeSystem, inferred));
      if (success && !typeParamBound.isDynamic) {
        // If everything else succeeded, check the `extends` constraint.
        var extendsConstraint = _TypeConstraint.fromExtends(
          typeParam,
          typeParamBound,
          isNonNullableByDefault: isNonNullableByDefault,
        );
        constraints.add(extendsConstraint);
        success = extendsConstraint.isSatisifedBy(_typeSystem, inferred);
      }

      if (!success) {
        if (failAtError) return null;
        errorReporter?.reportErrorForNode(
            StrongModeCode.COULD_NOT_INFER,
            errorNode,
            [typeParam.name, _formatError(typeParam, inferred, constraints)]);

        // Heuristic: even if we failed, keep the erroneous type.
        // It should satisfy at least some of the constraints (e.g. the return
        // context). If we fall back to instantiateToBounds, we'll typically get
        // more errors (e.g. because `dynamic` is the most common bound).
      }

      if (inferred is FunctionType && inferred.typeFormals.isNotEmpty) {
        if (failAtError) return null;
        var typeFormals = (inferred as FunctionType).typeFormals;
        var typeFormalsStr = typeFormals.map(_elementStr).join(', ');
        errorReporter
            ?.reportErrorForNode(StrongModeCode.COULD_NOT_INFER, errorNode, [
          typeParam.name,
          ' Inferred candidate type ${_typeStr(inferred)} has type parameters'
              ' [$typeFormalsStr], but a function with'
              ' type parameters cannot be used as a type argument.'
        ]);

        // Heuristic: Using a generic function type as a bound makes subtyping
        // undecidable. Therefore, we cannot keep [inferred] unless we wish to
        // generate bogus subtyping errors. Instead generate plain [Function],
        // which is the most general function type.
        inferred = typeProvider.functionType;
      }

      if (UnknownInferredType.isKnown(inferred)) {
        knownTypes[typeParam] = inferred;
      } else if (_typeSystem.strictInference) {
        // [typeParam] could not be inferred. A result will still be returned
        // by [infer], with [typeParam] filled in as its bounds. This is
        // considered a failure of inference, under the "strict-inference"
        // mode.
        if (errorNode is ConstructorName) {
          String constructorName = '${errorNode.type}.${errorNode.name}';
          errorReporter?.reportErrorForNode(
              HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION,
              errorNode,
              [constructorName]);
        }
        // TODO(srawlins): More inference failure cases, like functions, and
        // function expressions.
      }
    }

    // Use instantiate to bounds to finish things off.
    var hasError = List<bool>.filled(typeFormals.length, false);
    var result = _typeSystem.instantiateTypeFormalsToBounds(typeFormals,
        hasError: hasError, knownTypes: knownTypes);

    // Report any errors from instantiateToBounds.
    for (int i = 0; i < hasError.length; i++) {
      if (hasError[i]) {
        if (failAtError) return null;
        TypeParameterElement typeParam = typeFormals[i];
        var typeParamBound = Substitution.fromPairs(typeFormals, inferredTypes)
            .substituteType(typeParam.bound ?? typeProvider.objectType);
        // TODO(jmesserly): improve this error message.
        errorReporter
            ?.reportErrorForNode(StrongModeCode.COULD_NOT_INFER, errorNode, [
          typeParam.name,
          "\nRecursive bound cannot be instantiated: '$typeParamBound'."
              "\nConsider passing explicit type argument(s) "
              "to the generic.\n\n'"
        ]);
      }
    }

    return result;
  }

  /// Tries to make [i1] a subtype of [i2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, any constraints that were accumulated during the match
  /// attempt have been rewound (see [_rewindConstraints]).
  bool tryMatchSubtypeOf(DartType t1, DartType t2, _TypeConstraintOrigin origin,
      {@required bool covariant}) {
    int previousRewindBufferLength = _undoBuffer.length;
    bool success = _matchSubtypeOf(t1, t2, null, origin, covariant: covariant);
    if (!success) {
      _rewindConstraints(previousRewindBufferLength);
    }
    return success;
  }

  /// Choose the bound that was implied by the return type, if any.
  ///
  /// Which bound this is depends on what positions the type parameter
  /// appears in. If the type only appears only in a contravariant position,
  /// we will choose the lower bound instead.
  ///
  /// For example given:
  ///
  ///     Func1<T, bool> makeComparer<T>(T x) => (T y) => x() == y;
  ///
  ///     main() {
  ///       Func1<num, bool> t = makeComparer/* infer <num> */(42);
  ///       print(t(42.0)); /// false, no error.
  ///     }
  ///
  /// The constraints we collect are:
  ///
  /// * `num <: T`
  /// * `int <: T`
  ///
  /// ... and no upper bound. Therefore the lower bound is the best choice.
  ///
  /// If [isContravariant] is `true`, then we are solving for a contravariant
  /// type parameter which means we choose the upper bound rather than the
  /// lower bound for normally covariant type parameters.
  DartType _chooseTypeFromConstraints(Iterable<_TypeConstraint> constraints,
      {bool toKnownType = false, @required bool isContravariant}) {
    DartType lower = UnknownInferredType.instance;
    DartType upper = UnknownInferredType.instance;
    for (var constraint in constraints) {
      // Given constraints:
      //
      //     L1 <: T <: U1
      //     L2 <: T <: U2
      //
      // These can be combined to produce:
      //
      //     LUB(L1, L2) <: T <: GLB(U1, U2).
      //
      // This can then be done for all constraints in sequence.
      //
      // This resulting constraint may be unsatisfiable; in that case inference
      // will fail.
      upper = _getGreatestLowerBound(upper, constraint.upperBound);
      lower = _typeSystem.getLeastUpperBound(lower, constraint.lowerBound);
      upper = _toLegacyType(upper);
      lower = _toLegacyType(lower);
    }

    // Prefer the known bound, if any.
    // Otherwise take whatever bound has partial information, e.g. `Iterable<?>`
    //
    // For both of those, prefer the lower bound (arbitrary heuristic) or upper
    // bound if [isContravariant] is `true`
    if (isContravariant) {
      if (UnknownInferredType.isKnown(upper)) {
        return upper;
      }
      if (UnknownInferredType.isKnown(lower)) {
        return lower;
      }
      if (!identical(UnknownInferredType.instance, upper)) {
        return toKnownType ? _typeSystem.greatestClosure(upper) : upper;
      }
      if (!identical(UnknownInferredType.instance, lower)) {
        return toKnownType ? _typeSystem.leastClosure(lower) : lower;
      }
      return upper;
    } else {
      if (UnknownInferredType.isKnown(lower)) {
        return lower;
      }
      if (UnknownInferredType.isKnown(upper)) {
        return upper;
      }
      if (!identical(UnknownInferredType.instance, lower)) {
        return toKnownType ? _typeSystem.leastClosure(lower) : lower;
      }
      if (!identical(UnknownInferredType.instance, upper)) {
        return toKnownType ? _typeSystem.greatestClosure(upper) : upper;
      }
      return lower;
    }
  }

  String _elementStr(Element element) {
    return element.getDisplayString(withNullability: isNonNullableByDefault);
  }

  String _formatError(TypeParameterElement typeParam, DartType inferred,
      Iterable<_TypeConstraint> constraints) {
    var inferredStr = inferred.getDisplayString(
      withNullability: isNonNullableByDefault,
    );
    var intro = "Tried to infer '$inferredStr' for '${typeParam.name}'"
        " which doesn't work:";

    var constraintsByOrigin = <_TypeConstraintOrigin, List<_TypeConstraint>>{};
    for (var c in constraints) {
      constraintsByOrigin.putIfAbsent(c.origin, () => []).add(c);
    }

    // Only report unique constraint origins.
    Iterable<_TypeConstraint> isSatisified(bool expected) => constraintsByOrigin
        .values
        .where((l) =>
            l.every((c) => c.isSatisifedBy(_typeSystem, inferred)) == expected)
        .expand((i) => i);

    String unsatisified = _formatConstraints(isSatisified(false));
    String satisified = _formatConstraints(isSatisified(true));

    assert(unsatisified.isNotEmpty);
    if (satisified.isNotEmpty) {
      satisified = "\nThe type '$inferredStr' was inferred from:\n$satisified";
    }

    return '\n\n$intro\n$unsatisified$satisified\n\n'
        'Consider passing explicit type argument(s) to the generic.\n\n';
  }

  /// This is first calls strong mode's GLB, but if it fails to find anything
  /// (i.e. returns the bottom type), we kick in a few additional rules:
  ///
  /// - `GLB(FutureOr<A>, B)` is defined as:
  ///   - `GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>`
  ///   - `GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>`
  ///   - else `GLB(FutureOr<A>, B) == GLB(A, B)`
  /// - `GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)` (defined above),
  /// - else `GLB(A, B) == Null`
  DartType _getGreatestLowerBound(DartType t1, DartType t2) {
    var result = _typeSystem.getGreatestLowerBound(t1, t2);
    if (result.isBottom) {
      // See if we can do better by considering FutureOr rules.
      if (t1 is InterfaceType && t1.isDartAsyncFutureOr) {
        var t1TypeArg = t1.typeArguments[0];
        if (t2 is InterfaceType) {
          //  GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>
          if (t2.isDartAsyncFutureOr) {
            var t2TypeArg = t2.typeArguments[0];
            return typeProvider
                .futureOrType2(_getGreatestLowerBound(t1TypeArg, t2TypeArg));
          }
          // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
          if (t2.isDartAsyncFuture) {
            var t2TypeArg = t2.typeArguments[0];
            return typeProvider
                .futureType2(_getGreatestLowerBound(t1TypeArg, t2TypeArg));
          }
        }
        // GLB(FutureOr<A>, B) == GLB(A, B)
        return _getGreatestLowerBound(t1TypeArg, t2);
      }
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        // GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)
        return _getGreatestLowerBound(t2, t1);
      }
    }
    return result;
  }

  DartType _inferTypeParameterFromAll(
      List<_TypeConstraint> constraints, _TypeConstraint extendsClause,
      {@required bool isContravariant, @required bool preferUpwardsInference}) {
    // See if we already fixed this type from downwards inference.
    // If so, then we aren't allowed to change it based on argument types unless
    // [preferUpwardsInference] is true.
    DartType t = _inferTypeParameterFromContext(
        constraints.where((c) => c.isDownwards), extendsClause,
        isContravariant: isContravariant);
    if (!preferUpwardsInference && UnknownInferredType.isKnown(t)) {
      // Remove constraints that aren't downward ones; we'll ignore these for
      // error reporting, because inference already succeeded.
      constraints.removeWhere((c) => !c.isDownwards);
      return t;
    }

    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
    }

    var choice = _chooseTypeFromConstraints(constraints,
        toKnownType: true, isContravariant: isContravariant);
    return choice;
  }

  DartType _inferTypeParameterFromContext(
      Iterable<_TypeConstraint> constraints, _TypeConstraint extendsClause,
      {@required bool isContravariant}) {
    DartType t = _chooseTypeFromConstraints(constraints,
        isContravariant: isContravariant);
    if (UnknownInferredType.isUnknown(t)) {
      return t;
    }

    // If we're about to make our final choice, apply the extends clause.
    // This gives us a chance to refine the choice, in case it would violate
    // the `extends` clause. For example:
    //
    //     Object obj = math.min/*<infer Object, error>*/(1, 2);
    //
    // If we consider the `T extends num` we conclude `<num>`, which works.
    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
      return _chooseTypeFromConstraints(constraints,
          isContravariant: isContravariant);
    }
    return t;
  }

  /// Tries to make [i1] a subtype of [i2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, the caller is responsible for ignoring any constraints that
  /// were accumulated (see [_rewindConstraints]).
  bool _matchInterfaceSubtypeOf(InterfaceType i1, InterfaceType i2,
      Set<Element> visited, _TypeConstraintOrigin origin,
      {@required bool covariant}) {
    if (identical(i1, i2)) {
      return true;
    }

    if (i1.element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;
      List<TypeParameterElement> tParams = i1.element.typeParameters;
      assert(tArgs1.length == tArgs2.length);
      assert(tArgs1.length == tParams.length);
      for (int i = 0; i < tArgs1.length; i++) {
        TypeParameterElement typeParameterElement = tParams[i];

        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        Variance parameterVariance =
            (typeParameterElement as TypeParameterElementImpl).variance;
        if (parameterVariance.isCovariant) {
          if (!_matchSubtypeOf(tArgs1[i], tArgs2[i], HashSet<Element>(), origin,
              covariant: covariant)) {
            return false;
          }
        } else if (parameterVariance.isContravariant) {
          if (!_matchSubtypeOf(tArgs2[i], tArgs1[i], HashSet<Element>(), origin,
              covariant: !covariant)) {
            return false;
          }
        } else if (parameterVariance.isInvariant) {
          if (!_matchSubtypeOf(tArgs1[i], tArgs2[i], HashSet<Element>(), origin,
                  covariant: covariant) ||
              !_matchSubtypeOf(tArgs2[i], tArgs1[i], HashSet<Element>(), origin,
                  covariant: !covariant)) {
            return false;
          }
        } else {
          throw StateError("Type parameter ${tParams[i]} has unknown "
              "variance $parameterVariance for inference.");
        }
      }
      return true;
    }
    if (i1.isObject) {
      return false;
    }

    // Guard against loops in the class hierarchy
    bool guardedInterfaceSubtype(InterfaceType t1) {
      visited ??= HashSet<Element>();
      if (visited.add(t1.element)) {
        bool matched = _matchInterfaceSubtypeOf(t1, i2, visited, origin,
            covariant: covariant);
        visited.remove(t1.element);
        return matched;
      } else {
        // In the case of a recursive type parameter, consider the subtype
        // match to have failed.
        return false;
      }
    }

    // We don't need to search the entire class hierarchy, since a given
    // subclass can't appear multiple times with different generic parameters.
    // So shortcut to the first match found.
    //
    // We don't need undo logic here because if the classes don't match, nothing
    // is added to the constraint set.
    var superclass = i1.superclass;
    if (superclass != null && guardedInterfaceSubtype(superclass)) return true;
    for (final parent in i1.interfaces) {
      if (guardedInterfaceSubtype(parent)) return true;
    }
    for (final parent in i1.mixins) {
      if (guardedInterfaceSubtype(parent)) return true;
    }
    for (final parent in i1.superclassConstraints) {
      if (guardedInterfaceSubtype(parent)) return true;
    }
    return false;
  }

  /// Assert that [t1] will be a subtype of [t2], and returns if the constraint
  /// can be satisfied.
  ///
  /// [covariant] must be true if [t1] is a declared type of the generic
  /// function and [t2] is the context type, or false if the reverse. For
  /// example [covariant] is used when [t1] is the declared return type
  /// and [t2] is the context type. Contravariant would be used if [t1] is the
  /// argument type (i.e. passed in to the generic function) and [t2] is the
  /// declared parameter type.
  ///
  /// [origin] indicates where the constraint came from, for example an argument
  /// or return type.
  bool _matchSubtypeOf(DartType t1, DartType t2, Set<Element> visited,
      _TypeConstraintOrigin origin,
      {@required bool covariant}) {
    if (covariant && t1 is TypeParameterType) {
      var constraints = this.constraints[t1.element];
      if (constraints != null) {
        if (!identical(t2, UnknownInferredType.instance)) {
          if (t1.nullabilitySuffix == NullabilitySuffix.question) {
            t2 = _typeSystem.promoteToNonNull(t2);
          }
          var constraint = _TypeConstraint(origin, t1.element, upper: t2);
          constraints.add(constraint);
          _undoBuffer.add(constraint);
        }
        return true;
      }
    }
    if (!covariant && t2 is TypeParameterType) {
      var constraints = this.constraints[t2.element];
      if (constraints != null) {
        if (!identical(t1, UnknownInferredType.instance)) {
          if (t2.nullabilitySuffix == NullabilitySuffix.question) {
            t1 = _typeSystem.promoteToNonNull(t1);
          }
          var constraint = _TypeConstraint(origin, t2.element, lower: t1);
          constraints.add(constraint);
          _undoBuffer.add(constraint);
        }
        return true;
      }
    }

    if (identical(t1, t2)) {
      return true;
    }

    // TODO(jmesserly): this logic is taken from subtype.
    bool matchSubtype(DartType t1, DartType t2) {
      return _matchSubtypeOf(t1, t2, null, origin, covariant: covariant);
    }

    // Handle FutureOr<T> union type.
    if (t1 is InterfaceType && t1.isDartAsyncFutureOr) {
      var t1TypeArg = t1.typeArguments[0];
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        var t2TypeArg = t2.typeArguments[0];
        // FutureOr<A> <: FutureOr<B> iff A <: B
        return matchSubtype(t1TypeArg, t2TypeArg);
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      var t1Future = typeProvider.futureType2(t1TypeArg);
      return matchSubtype(t1Future, t2) && matchSubtype(t1TypeArg, t2);
    }

    if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      var t2TypeArg = t2.typeArguments[0];
      var t2Future = typeProvider.futureType2(t2TypeArg);

      // First we try matching `t1 <: Future<A>`.  If that succeeds *and*
      // records at least one constraint, then we proceed using that constraint.
      var previousRewindBufferLength = _undoBuffer.length;
      var success =
          tryMatchSubtypeOf(t1, t2Future, origin, covariant: covariant);

      if (_undoBuffer.length != previousRewindBufferLength) {
        // Trying to match `t1 <: Future<A>` succeeded and recorded constraints,
        // so those are the constraints we want.
        return true;
      } else {
        // Either `t1 <: Future<A>` failed to match, or it matched trivially
        // without recording any constraints (e.g. because t1 is `Null`).  We
        // want constraints, because they let us do more precise inference, so
        // go ahead and try matching `t1 <: A` to see if it records any
        // constraints.
        if (tryMatchSubtypeOf(t1, t2TypeArg, origin, covariant: covariant)) {
          // Trying to match `t1 <: A` succeeded.  If it recorded constraints,
          // those are the constraints we want.  If it didn't, then there's no
          // way we're going to get any constraints.  So either way, we want to
          // return `true` since the match suceeded and the constraints we want
          // (if any) have been recorded.
          return true;
        } else {
          // Trying to match `t1 <: A` failed.  So there's no way we are going
          // to get any constraints.  Just return `success` to indicate whether
          // the match succeeded.
          return success;
        }
      }
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  True if T == S
    //  Or true if bound of S is S' and S' <: T

    if (t1 is TypeParameterType) {
      // Guard against recursive type parameters
      //
      // TODO(jmesserly): this function isn't guarding against anything (it's
      // not passsing down `visitedSet`, so adding the element has no effect).
      bool guardedSubtype(DartType t1, DartType t2) {
        var visitedSet = visited ?? HashSet<Element>();
        if (visitedSet.add(t1.element)) {
          bool matched = matchSubtype(t1, t2);
          visitedSet.remove(t1.element);
          return matched;
        } else {
          // In the case of a recursive type parameter, consider the subtype
          // match to have failed.
          return false;
        }
      }

      if (t2 is TypeParameterType && t1.definition == t2.definition) {
        return guardedSubtype(t1.bound, t2.bound);
      }
      return guardedSubtype(t1.bound, t2);
    }
    if (t2 is TypeParameterType) {
      return false;
    }

    // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    if (_isLegacyBottom(t1, orTrueBottom: true) ||
        _isLegacyTop(t2, orTrueTop: true)) return true;

    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _matchInterfaceSubtypeOf(t1, t2, visited, origin,
          covariant: covariant);
    }

    if (t1 is FunctionType && t2 is FunctionType) {
      return FunctionTypeImpl.relate(t1, t2, matchSubtype,
          parameterRelation: (p1, p2) {
            return _matchSubtypeOf(p2.type, p1.type, null, origin,
                covariant: !covariant);
          },
          // Type parameter bounds are invariant.
          boundsRelation: (t1, t2, p1, p2) =>
              matchSubtype(t1, t2) && matchSubtype(t2, t1));
    }

    if (t1 is FunctionType && t2 == typeProvider.functionType) {
      return true;
    }

    return false;
  }

  /// Un-does constraints that were gathered by a failed match attempt, until
  /// [_undoBuffer] has length [previousRewindBufferLength].
  ///
  /// The intended usage is that the caller should record the length of
  /// [_undoBuffer] before attempting to make a match.  Then, if the match
  /// fails, pass the recorded length to this method to erase any constraints
  /// that were recorded during the failed match.
  void _rewindConstraints(int previousRewindBufferLength) {
    while (_undoBuffer.length > previousRewindBufferLength) {
      var constraint = _undoBuffer.removeLast();
      var element = constraint.typeParameter;
      assert(identical(constraints[element].last, constraint));
      constraints[element].removeLast();
    }
  }

  /// If in a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType _toLegacyType(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: isNonNullableByDefault);
  }

  static String _formatConstraints(Iterable<_TypeConstraint> constraints) {
    List<List<String>> lineParts =
        Set<_TypeConstraintOrigin>.from(constraints.map((c) => c.origin))
            .map((o) => o.formatError())
            .toList();

    int prefixMax = lineParts.map((p) => p[0].length).fold(0, math.max);

    // Use a set to prevent identical message lines.
    // (It's not uncommon for the same constraint to show up in a few places.)
    var messageLines = Set<String>.from(lineParts.map((parts) {
      var prefix = parts[0];
      var middle = parts[1];
      var prefixPad = ' ' * (prefixMax - prefix.length);
      var middlePad = ' ' * (prefixMax);
      var end = "";
      if (parts.length > 2) {
        end = '\n  $middlePad ${parts[2]}';
      }
      return '  $prefix$prefixPad $middle$end';
    }));

    return messageLines.join('\n');
  }
}

/// A constraint on a type parameter that we're inferring.
class _TypeConstraint extends _TypeRange {
  /// The type parameter that is constrained by [lowerBound] or [upperBound].
  final TypeParameterElement typeParameter;

  /// Where this constraint comes from, used for error messages.
  ///
  /// See [toString].
  final _TypeConstraintOrigin origin;

  _TypeConstraint(this.origin, this.typeParameter,
      {DartType upper, DartType lower})
      : super(upper: upper, lower: lower);

  _TypeConstraint.fromExtends(
      TypeParameterElement element, DartType extendsType,
      {@required bool isNonNullableByDefault})
      : this(
            _TypeConstraintFromExtendsClause(
              element,
              extendsType,
              isNonNullableByDefault: isNonNullableByDefault,
            ),
            element,
            upper: extendsType);

  bool get isDownwards => origin is! _TypeConstraintFromArgument;

  bool isSatisifedBy(TypeSystemImpl ts, DartType type) =>
      ts.isSubtypeOf2(lowerBound, type) && ts.isSubtypeOf2(type, upperBound);

  /// Converts this constraint to a message suitable for a type inference error.
  @override
  String toString() => !identical(upperBound, UnknownInferredType.instance)
      ? "'$typeParameter' must extend '$upperBound'"
      : "'$lowerBound' must extend '$typeParameter'";
}

class _TypeConstraintFromArgument extends _TypeConstraintOrigin {
  final DartType argumentType;
  final DartType parameterType;
  final String parameterName;
  final ClassElement genericClass;

  _TypeConstraintFromArgument(
      this.argumentType, this.parameterType, this.parameterName,
      {this.genericClass, @required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    // TODO(jmesserly): we should highlight the span. That would be more useful.
    // However in summary code it doesn't look like the AST node with span is
    // available.
    String prefix;
    if (genericClass != null &&
        (genericClass.name == "List" || genericClass.name == "Map") &&
        genericClass.library.isDartCore == true) {
      // This will become:
      //     "List element"
      //     "Map key"
      //     "Map value"
      prefix = "${genericClass.name} $parameterName";
    } else {
      prefix = "Parameter '$parameterName'";
    }

    return [
      prefix,
      "declared as     '${_typeStr(parameterType)}'",
      "but argument is '${_typeStr(argumentType)}'."
    ];
  }
}

class _TypeConstraintFromExtendsClause extends _TypeConstraintOrigin {
  final TypeParameterElement typeParam;
  final DartType extendsType;

  _TypeConstraintFromExtendsClause(this.typeParam, this.extendsType,
      {@required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    return [
      "Type parameter '${typeParam.name}'",
      "declared to extend '${_typeStr(extendsType)}'."
    ];
  }
}

class _TypeConstraintFromFunctionContext extends _TypeConstraintOrigin {
  final DartType contextType;
  final DartType functionType;

  _TypeConstraintFromFunctionContext(this.functionType, this.contextType,
      {@required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    return [
      "Function type",
      "declared as '${_typeStr(functionType)}'",
      "used where  '${_typeStr(contextType)}' is required."
    ];
  }
}

class _TypeConstraintFromReturnType extends _TypeConstraintOrigin {
  final DartType contextType;
  final DartType declaredType;

  _TypeConstraintFromReturnType(this.declaredType, this.contextType,
      {@required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    return [
      "Return type",
      "declared as '${_typeStr(declaredType)}'",
      "used where  '${_typeStr(contextType)}' is required."
    ];
  }
}

/// The origin of a type constraint, for the purposes of producing a human
/// readable error message during type inference as well as determining whether
/// the constraint was used to fix the type parameter or not.
abstract class _TypeConstraintOrigin {
  final bool isNonNullableByDefault;

  _TypeConstraintOrigin({@required this.isNonNullableByDefault});

  List<String> formatError();

  String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: isNonNullableByDefault);
  }
}

class _TypeRange {
  /// The upper bound of the type parameter. In other words, T <: upperBound.
  ///
  /// In Dart this can be written as `<T extends UpperBoundType>`.
  ///
  /// In inference, this can happen as a result of parameters of function type.
  /// For example, consider a signature like:
  ///
  ///     T reduce<T>(List<T> values, T f(T x, T y));
  ///
  /// and a call to it like:
  ///
  ///     reduce(values, (num x, num y) => ...);
  ///
  /// From the function expression's parameters, we conclude `T <: num`. We may
  /// still be able to conclude a different [lower] based on `values` or
  /// the type of the elided `=> ...` body. For example:
  ///
  ///      reduce(['x'], (num x, num y) => 'hi');
  ///
  /// Here the [lower] will be `String` and the upper bound will be `num`,
  /// which cannot be satisfied, so this is ill typed.
  final DartType upperBound;

  /// The lower bound of the type parameter. In other words, lowerBound <: T.
  ///
  /// This kind of constraint cannot be expressed in Dart, but it applies when
  /// we're doing inference. For example, consider a signature like:
  ///
  ///     T pickAtRandom<T>(T x, T y);
  ///
  /// and a call to it like:
  ///
  ///     pickAtRandom(1, 2.0)
  ///
  /// when we see the first parameter is an `int`, we know that `int <: T`.
  /// When we see `double` this implies `double <: T`.
  /// Combining these constraints results in a lower bound of `num`.
  ///
  /// In general, we choose the lower bound as our inferred type, so we can
  /// offer the most constrained (strongest) result type.
  final DartType lowerBound;

  _TypeRange({DartType lower, DartType upper})
      : lowerBound = lower ?? UnknownInferredType.instance,
        upperBound = upper ?? UnknownInferredType.instance;

  /// Formats the typeRange as a string suitable for unit testing.
  ///
  /// For example, if [typeName] is 'T' and the range has bounds int and Object
  /// respectively, the returned string will be 'int <: T <: Object'.
  @visibleForTesting
  String format(String typeName, {@required bool withNullability}) {
    String typeStr(DartType type) {
      return type.getDisplayString(withNullability: withNullability);
    }

    var lowerString = identical(lowerBound, UnknownInferredType.instance)
        ? ''
        : '${typeStr(lowerBound)} <: ';
    var upperString = identical(upperBound, UnknownInferredType.instance)
        ? ''
        : ' <: ${typeStr(upperBound)}';
    return '$lowerString$typeName$upperString';
  }

  @override
  String toString() => format('(type)', withNullability: true);
}
