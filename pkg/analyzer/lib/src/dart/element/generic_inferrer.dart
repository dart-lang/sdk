// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart' show AstNode, ConstructorName;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart'
    show CompileTimeErrorCode, HintCode;
import 'package:meta/meta.dart';

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
  final Set<TypeParameterElement> _typeParameters = Set.identity();
  final Map<TypeParameterElement, List<_TypeConstraint>> _constraints = {};

  GenericInferrer(
    this._typeSystem,
    Iterable<TypeParameterElement> typeFormals,
  ) {
    _typeParameters.addAll(typeFormals);
    for (var formal in typeFormals) {
      _constraints[formal] = [];
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
  /// `_` to precisely represent an unknown type. If [downwardsInferPhase] is
  /// false, we are on our final inference pass, have all available information
  /// including argument types, and must not conclude `_` for any type formal.
  List<DartType> infer(List<TypeParameterElement> typeFormals,
      {bool considerExtendsClause = true,
      ErrorReporter errorReporter,
      AstNode errorNode,
      bool failAtError = false,
      bool downwardsInferPhase = false}) {
    // Initialize the inferred type array.
    //
    // In the downwards phase, they all start as `_` to offer reasonable
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
              _constraints[typeParam], extendsClause,
              isContravariant: typeParam.variance.isContravariant)
          : _inferTypeParameterFromAll(_constraints[typeParam], extendsClause,
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
      var constraints = _constraints[typeParam];

      var typeParamBound = typeParam.bound;
      if (typeParamBound != null) {
        typeParamBound = Substitution.fromPairs(typeFormals, inferredTypes)
            .substituteType(typeParamBound);
        typeParamBound = _toLegacyElementIfOptOut(typeParamBound);
      } else {
        typeParamBound = typeProvider.dynamicType;
      }

      var inferred = inferredTypes[i];
      bool success =
          constraints.every((c) => c.isSatisfiedBy(_typeSystem, inferred));
      if (success && !typeParamBound.isDynamic) {
        // If everything else succeeded, check the `extends` constraint.
        var extendsConstraint = _TypeConstraint.fromExtends(
          typeParam,
          typeParamBound,
          isNonNullableByDefault: isNonNullableByDefault,
        );
        constraints.add(extendsConstraint);
        success = extendsConstraint.isSatisfiedBy(_typeSystem, inferred);
      }

      if (!success) {
        if (failAtError) return null;
        errorReporter?.reportErrorForNode(
            CompileTimeErrorCode.COULD_NOT_INFER,
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
        errorReporter?.reportErrorForNode(
            CompileTimeErrorCode.COULD_NOT_INFER, errorNode, [
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
        if (errorNode is ConstructorName &&
            !(errorNode.type.type as InterfaceType)
                .element
                .hasOptionalTypeArgs) {
          String constructorName = errorNode.name == null
              ? errorNode.type.name.name
              : '${errorNode.type}.${errorNode.name}';
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
        errorReporter?.reportErrorForNode(
            CompileTimeErrorCode.COULD_NOT_INFER, errorNode, [
          typeParam.name,
          "\nRecursive bound cannot be instantiated: '$typeParamBound'."
              "\nConsider passing explicit type argument(s) "
              "to the generic.\n\n'"
        ]);
      }
    }

    _nonNullifyTypes(result);
    return result;
  }

  /// Tries to make [i1] a subtype of [i2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, any constraints that were accumulated during the match
  /// attempt have been rewound (see [_rewindConstraints]).
  bool tryMatchSubtypeOf(DartType t1, DartType t2, _TypeConstraintOrigin origin,
      {@required bool covariant}) {
    var gatherer = TypeConstraintGatherer(
      typeSystem: _typeSystem,
      typeParameters: _typeParameters,
    );
    var success = gatherer.trySubtypeMatch(t1, t2, !covariant);
    if (success) {
      var constraints = gatherer.computeConstraints();
      for (var entry in constraints.entries) {
        if (!entry.value.isEmpty) {
          _constraints[entry.key].add(
            _TypeConstraint(
              origin,
              entry.key,
              lower: entry.value.lower,
              upper: entry.value.upper,
            ),
          );
        }
      }
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
      upper = _typeSystem.getGreatestLowerBound(upper, constraint.upperBound);
      lower = _typeSystem.getLeastUpperBound(lower, constraint.lowerBound);
      upper = _toLegacyElementIfOptOut(upper);
      lower = _toLegacyElementIfOptOut(lower);
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
            l.every((c) => c.isSatisfiedBy(_typeSystem, inferred)) == expected)
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

  void _nonNullifyTypes(List<DartType> types) {
    if (_typeSystem.isNonNullableByDefault) {
      for (var i = 0; i < types.length; i++) {
        types[i] = _typeSystem.nonNullifyLegacy(types[i]);
      }
    }
    for (var i = 0; i < types.length; i++) {
      types[i] = _typeSystem.demoteType(types[i]);
    }
  }

  /// If in a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType _toLegacyElementIfOptOut(DartType type) {
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
      var middlePad = ' ' * prefixMax;
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

  bool isSatisfiedBy(TypeSystemImpl ts, DartType type) {
    return ts.isSubtypeOf2(lowerBound, type) &&
        ts.isSubtypeOf2(type, upperBound);
  }

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
  List<String> formatError() {
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
  List<String> formatError() {
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
  List<String> formatError() {
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
  List<String> formatError() {
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
