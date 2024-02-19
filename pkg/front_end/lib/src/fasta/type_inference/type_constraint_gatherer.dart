// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart'
    show NullabilitySuffix;

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show TypeDeclarationKind;

import 'package:kernel/ast.dart';

import 'package:kernel/type_algebra.dart';

import 'package:kernel/type_environment.dart';

import '../names.dart' show callName;

import 'type_inference_engine.dart';

import 'type_schema.dart';

import 'type_schema_environment.dart';

/// Creates a collection of [TypeConstraint]s corresponding to type parameters,
/// based on an attempt to make one type schema a subtype of another.
class TypeConstraintGatherer {
  final List<_ProtoConstraint> _protoConstraints = [];

  final List<StructuralParameter> _parametersToConstrain;

  final bool _isNonNullableByDefault;

  final OperationsCfe _typeOperations;

  final TypeSchemaEnvironment _environment;

  TypeConstraintGatherer(
      this._environment, Iterable<StructuralParameter> typeParameters,
      {required bool isNonNullableByDefault,
      required OperationsCfe typeOperations})
      : _typeOperations = typeOperations,
        _isNonNullableByDefault = isNonNullableByDefault,
        _parametersToConstrain =
            new List<StructuralParameter>.of(typeParameters);

  void addUpperBound(TypeConstraint constraint, DartType upper,
      {required bool isNonNullableByDefault}) {
    _environment.addUpperBound(constraint, upper,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  void addLowerBound(TypeConstraint constraint, DartType lower,
      {required bool isNonNullableByDefault}) {
    _environment.addLowerBound(constraint, lower,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  /// Applies all the argument constraints implied by trying to make
  /// [actualTypes] assignable to [formalTypes].
  void constrainArguments(
      List<DartType> formalTypes, List<DartType> actualTypes) {
    assert(formalTypes.length == actualTypes.length);
    for (int i = 0; i < formalTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      tryConstrainLower(formalTypes[i], actualTypes[i]);
    }
  }

  Member? getInterfaceMember(Class class_, Name name, {bool setter = false}) {
    return _environment.hierarchy
        .getInterfaceMember(class_, name, setter: setter);
  }

  List<DartType>? getTypeArgumentsAsInstanceOf(
      TypeDeclarationType type, TypeDeclaration typeDeclaration) {
    return _environment.getTypeArgumentsAsInstanceOf(type, typeDeclaration);
  }

  List<DartType>? getExtensionTypeArgumentsAsInstanceOf(
      ExtensionType type, ExtensionTypeDeclaration superclass) {
    return _environment.hierarchy
        .getExtensionTypeArgumentsAsInstanceOfExtensionTypeDeclaration(
            type, superclass);
  }

  /// Returns the set of type constraints that was gathered.
  Map<StructuralParameter, TypeConstraint> computeConstraints(
      {required bool isNonNullableByDefault}) {
    Map<StructuralParameter, TypeConstraint> result = {};
    for (StructuralParameter parameter in _parametersToConstrain) {
      result[parameter] = new TypeConstraint();
    }
    for (_ProtoConstraint protoConstraint in _protoConstraints) {
      if (protoConstraint.isUpper) {
        addUpperBound(result[protoConstraint.parameter]!, protoConstraint.bound,
            isNonNullableByDefault: isNonNullableByDefault);
      } else {
        addLowerBound(result[protoConstraint.parameter]!, protoConstraint.bound,
            isNonNullableByDefault: isNonNullableByDefault);
      }
    }
    return result;
  }

  /// Tries to constrain type parameters in [type], so that [bound] <: [type].
  ///
  /// Doesn't change the already accumulated set of constraints if [bound] isn't
  /// a subtype of [type] under any set of constraints.
  bool tryConstrainLower(DartType type, DartType bound) {
    if (_isNonNullableByDefault) {
      return _tryNullabilityAwareSubtypeMatch(bound, type,
          constrainSupertype: true);
    } else {
      return _tryNullabilityObliviousSubtypeMatch(bound, type);
    }
  }

  /// Tries to constrain type parameters in [type], so that [type] <: [bound].
  ///
  /// Doesn't change the already accumulated set of constraints if [type] isn't
  /// a subtype of [bound] under any set of constraints.
  bool tryConstrainUpper(DartType type, DartType bound) {
    if (_isNonNullableByDefault) {
      return _tryNullabilityAwareSubtypeMatch(type, bound,
          constrainSupertype: false);
    } else {
      return _tryNullabilityObliviousSubtypeMatch(type, bound);
    }
  }

  /// Tries to match [subtype] against [supertype].
  ///
  /// If the match succeeds, the member returns true, and the resulting type
  /// constraints are recorded for later use by [computeConstraints].  If the
  /// match fails, the member returns false, and the set of type
  /// constraints is unchanged.
  bool _tryNullabilityObliviousSubtypeMatch(
      DartType subtype, DartType supertype) {
    int baseConstraintCount = _protoConstraints.length;
    bool isMatch = _isNullabilityObliviousSubtypeMatch(subtype, supertype);
    if (!isMatch) {
      _protoConstraints.length = baseConstraintCount;
    }
    return isMatch;
  }

  /// Tries to match [subtype] against [supertype].
  ///
  /// If the match succeeds, the member returns true, and the resulting type
  /// constraints are recorded for later use by [computeConstraints].  If the
  /// match fails, the member returns false, and the set of type constraints is
  /// unchanged.
  ///
  /// In contrast with [_tryNullabilityObliviousSubtypeMatch], this method
  /// distinguishes between cases when the type parameters to constraint occur
  /// in [subtype] and in [supertype].  If [constrainSupertype] is true, the
  /// type parameters to constrain occur in [supertype]; otherwise, they occur
  /// in [subtype].  If one type contains the type parameters to constrain, the
  /// other one isn't allowed to contain them.  The type that contains the type
  /// parameters isn't allowed to also contain [UnknownType], that is, to be a
  /// type schema.
  bool _tryNullabilityAwareSubtypeMatch(DartType subtype, DartType supertype,
      {required bool constrainSupertype}) {
    int baseConstraintCount = _protoConstraints.length;
    bool isMatch = _isNullabilityAwareSubtypeMatch(subtype, supertype,
        constrainSupertype: constrainSupertype);
    if (!isMatch) {
      _protoConstraints.length = baseConstraintCount;
    }
    return isMatch;
  }

  /// Add constraint: [lower] <: [parameter] <: TOP.
  void _constrainParameterLower(StructuralParameter parameter, DartType lower) {
    _protoConstraints.add(new _ProtoConstraint.lower(parameter, lower));
  }

  /// Add constraint: BOTTOM <: [parameter] <: [upper].
  void _constrainParameterUpper(StructuralParameter parameter, DartType upper) {
    _protoConstraints.add(new _ProtoConstraint.upper(parameter, upper));
  }

  bool _isFunctionSubtypeMatch(FunctionType subtype, FunctionType supertype) {
    // A function type `(M0,..., Mn, [M{n+1}, ..., Mm]) -> R0` is a subtype
    // match for a function type `(N0,..., Nk, [N{k+1}, ..., Nr]) -> R1` with
    // respect to `L` under constraints `C0 + ... + Cr + C`
    // - If `R0` is a subtype match for a type `R1` with respect to `L` under
    //   constraints `C`:
    // - If `n <= k` and `r <= m`.
    // - And for `i` in `0...r`, `Ni` is a subtype match for `Mi` with respect
    //   to `L` under constraints `Ci`.
    // Function types with named parameters are treated analogously to the
    // positional parameter case above.
    // A generic function type `<T0 extends B0, ..., Tn extends Bn>F0` is a
    // subtype match for a generic function type `<S0 extends B0, ..., Sn
    // extends Bn>F1` with respect to `L` under constraints `Cl`:
    // - If `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for `F0[Z0/S0, ...,
    //   Zn/Sn]` with respect to `L` under constraints `C`, where each `Zi` is a
    //   fresh type variable with bound `Bi`.
    // - And `Cl` is `C` with each constraint replaced with its closure with
    //   respect to `[Z0, ..., Zn]`.
    if (subtype.requiredParameterCount > supertype.requiredParameterCount) {
      return false;
    }
    if (subtype.positionalParameters.length <
        supertype.positionalParameters.length) {
      return false;
    }
    if (subtype.typeParameters.length != supertype.typeParameters.length) {
      return false;
    }
    if (subtype.typeParameters.isNotEmpty) {
      List<StructuralParameter> freshTypeVariables = [];
      List<DartType> freshTypeVariablesAsTypes = [];
      if (!_matchTypeFormals(subtype.typeParameters, supertype.typeParameters,
          freshTypeVariables, freshTypeVariablesAsTypes)) {
        return false;
      }

      subtype = FunctionTypeInstantiator.instantiate(
          subtype, freshTypeVariablesAsTypes);
      supertype = FunctionTypeInstantiator.instantiate(
          supertype, freshTypeVariablesAsTypes);
    }

    // Test the return types.
    if (supertype.returnType is! VoidType &&
        !_isNullabilityObliviousSubtypeMatch(
            subtype.returnType, supertype.returnType)) {
      return false;
    }

    // Test the parameter types.
    for (int i = 0; i < supertype.positionalParameters.length; ++i) {
      DartType supertypeParameter = supertype.positionalParameters[i];
      DartType subtypeParameter = subtype.positionalParameters[i];
      // Termination: Both types shrink in size.
      if (!_isNullabilityObliviousSubtypeMatch(
          supertypeParameter, subtypeParameter)) {
        return false;
      }
    }
    int subtypeNameIndex = 0;
    for (NamedType supertypeParameter in supertype.namedParameters) {
      while (subtypeNameIndex < subtype.namedParameters.length &&
          subtype.namedParameters[subtypeNameIndex].name !=
              supertypeParameter.name) {
        ++subtypeNameIndex;
      }
      if (subtypeNameIndex == subtype.namedParameters.length) return false;
      NamedType subtypeParameter = subtype.namedParameters[subtypeNameIndex];
      // Termination: Both types shrink in size.
      if (!_isNullabilityObliviousSubtypeMatch(
          supertypeParameter.type, subtypeParameter.type)) {
        return false;
      }
    }
    return true;
  }

  /// Whether the [subtype] interface is a subtype of the [supertype] interface
  /// with respect to variance.
  ///
  /// [constrainSupertype] is used in [_isNullabilityAwareSubtypeMatch] to
  /// check if the type parameters to constrain occur in the [supertype];
  /// otherwise they occur in the [subtype].
  bool _isNullabilityAwareInterfaceSubtypeMatch(
      InterfaceType subtype, InterfaceType supertype,
      {required bool constrainSupertype}) {
    List<DartType>? matchingSupertypeOfSubtypeArguments =
        getTypeArgumentsAsInstanceOf(subtype, supertype.classNode);
    if (matchingSupertypeOfSubtypeArguments == null) return false;
    for (int i = 0; i < supertype.classNode.typeParameters.length; i++) {
      int parameterVariance = supertype.classNode.typeParameters[i].variance;
      if (parameterVariance == Variance.contravariant) {
        if (!_isNullabilityAwareSubtypeMatch(
          supertype.typeArguments[i],
          matchingSupertypeOfSubtypeArguments[i],
          constrainSupertype: !constrainSupertype,
        )) {
          return false;
        }
      } else if (parameterVariance == Variance.invariant) {
        if (!_isNullabilityAwareSubtypeMatch(
              supertype.typeArguments[i],
              matchingSupertypeOfSubtypeArguments[i],
              constrainSupertype: !constrainSupertype,
            ) ||
            !_isNullabilityAwareSubtypeMatch(
              matchingSupertypeOfSubtypeArguments[i],
              supertype.typeArguments[i],
              constrainSupertype: constrainSupertype,
            )) {
          return false;
        }
      } else {
        if (!_isNullabilityAwareSubtypeMatch(
          matchingSupertypeOfSubtypeArguments[i],
          supertype.typeArguments[i],
          constrainSupertype: constrainSupertype,
        )) {
          return false;
        }
      }
    }
    return true;
  }

  /// Whether the [subtype] interface is a subtype of the [supertype] interface
  /// with respect to variance.
  bool _isNullabilityObliviousInterfaceSubtypeMatch(
      InterfaceType subtype, InterfaceType supertype) {
    // A type `P<M0, ..., Mk>` is a subtype match for `P<N0, ..., Nk>` with
    // respect to `L` under constraints `C0 + ... + Ck`:
    // - If `Mi` is a subtype match for `Ni` with respect to `L` under
    //   constraints `Ci`.
    // A type `P<M0, ..., Mk>` is a subtype match for `Q<N0, ..., Nj>` with
    // respect to `L` under constraints `C`:
    // - If `R<B0, ..., Bj>` is the superclass of `P<M0, ..., Mk>` and `R<B0,
    //   ..., Bj>` is a subtype match for `Q<N0, ..., Nj>` with respect to `L`
    //   under constraints `C`.
    // - Or `R<B0, ..., Bj>` is one of the interfaces implemented by `P<M0, ...,
    //   Mk>` (considered in lexical order) and `R<B0, ..., Bj>` is a subtype
    //   match for `Q<N0, ..., Nj>` with respect to `L` under constraints `C`.
    // - Or `R<B0, ..., Bj>` is a mixin into `P<M0, ..., Mk>` (considered in
    //   lexical order) and `R<B0, ..., Bj>` is a subtype match for `Q<N0, ...,
    //   Nj>` with respect to `L` under constraints `C`.

    // Note that since kernel requires that no class may only appear in the set
    // of supertypes of a given type more than once, the order of the checks
    // above is irrelevant; we just need to find the matched superclass,
    // substitute, and then iterate through type variables.
    List<DartType>? matchingSupertypeOfSubtypeArguments =
        getTypeArgumentsAsInstanceOf(subtype, supertype.classNode);
    if (matchingSupertypeOfSubtypeArguments == null) return false;
    for (int i = 0; i < supertype.classNode.typeParameters.length; i++) {
      // Generate constraints and subtype match with respect to variance.
      int parameterVariance = supertype.classNode.typeParameters[i].variance;
      if (parameterVariance == Variance.contravariant) {
        if (!_isNullabilityObliviousSubtypeMatch(supertype.typeArguments[i],
            matchingSupertypeOfSubtypeArguments[i])) {
          return false;
        }
      } else if (parameterVariance == Variance.invariant) {
        if (!_isNullabilityObliviousSubtypeMatch(supertype.typeArguments[i],
                matchingSupertypeOfSubtypeArguments[i]) ||
            !_isNullabilityObliviousSubtypeMatch(
                matchingSupertypeOfSubtypeArguments[i],
                supertype.typeArguments[i])) {
          return false;
        }
      } else {
        if (!_isNullabilityObliviousSubtypeMatch(
            matchingSupertypeOfSubtypeArguments[i],
            supertype.typeArguments[i])) {
          return false;
        }
      }
    }
    return true;
  }

  /// Matches [p] against [q] as a subtype against supertype.
  ///
  /// Returns true if [p] is a subtype of [q] under some constraints, and false
  /// otherwise.  The constraints making the relation possible are recorded to
  /// [_protoConstraints].  It is the responsibility of the caller to cleanup
  /// [_protoConstraints] in case [p] can't be a subtype of [q].
  ///
  /// If [constrainSupertype] is true, the type parameters to constrain occur in
  /// [supertype]; otherwise, they occur in [subtype].  If one type contains the
  /// type parameters to constrain, the other one isn't allowed to contain them.
  /// The type that contains the type parameters isn't allowed to also contain
  /// [UnknownType], that is, to be a type schema.
  bool _isNullabilityAwareSubtypeMatch(DartType p, DartType q,
      {required bool constrainSupertype}) {
    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the subtype (that is, [p]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        !constrainSupertype ||
            !containsStructuralTypeVariable(p, _parametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        : throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "constrainSupertype -> !containsTypeVariable(q)");

    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the supertype is not allowed to contain [UnknownType] as its part,
    // that is, the supertype should be fully known.  To check that, the assert
    // below uses the equivalence of the following: X -> Y  <=>  !X || Y.
    assert(
        !constrainSupertype || isKnown(q),
        "Failed implication check: "
        "constrainSupertype -> isKnown(q)");

    // If the type parameters being constrained occur in the subtype (that is,
    // [p]), the subtype is not allowed to contain [UnknownType] as its part,
    // that is, the subtype should be fully known.  To check that, the assert
    // below uses the equivalence of the following: X -> Y  <=>  !X || Y.
    assert(
        constrainSupertype || isKnown(p),
        "Failed implication check: "
        "!constrainSupertype -> isKnown(p)");

    // If the type parameters being constrained occur in the subtype (that is,
    // [p]), the supertype (that is, [q]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        constrainSupertype ||
            !containsStructuralTypeVariable(q, _parametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        : throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "!constrainSupertype -> !containsTypeVariable(q)");

    if (p is InvalidType || q is InvalidType) return false;

    // If P is _ then the match holds with no constraints.
    if (_typeOperations.isUnknownType(p)) return true;

    // If Q is _ then the match holds with no constraints.
    if (_typeOperations.isUnknownType(q)) return true;

    // If P is a type variable X in L, then the match holds:
    //
    // Under constraint _ <: X <: Q.
    // TODO(cstefantsova): Don't forget to remove the commented out code below.
    // [TypeParameter] objects are never the target of inference, and the
    // condition will always fail for them.
    if (p is StructuralParameterType &&
        isStructuralParameterTypeWithoutNullabilityMarker(p,
            isNonNullableByDefault: _isNonNullableByDefault) &&
        _parametersToConstrain.contains(p.parameter)) {
      _constrainParameterUpper(p.parameter, q);
      return true;
    }

    // If Q is a type variable X in L, then the match holds:
    //
    // Under constraint P <: X <: _.
    // TODO(cstefantsova): Don't forget to remove the commented out code below.
    // [TypeParameter] objects are never the target of inference, and the
    // condition will always fail for them.
    if (q is StructuralParameterType &&
        isStructuralParameterTypeWithoutNullabilityMarker(q,
            isNonNullableByDefault: _isNonNullableByDefault) &&
        _parametersToConstrain.contains(q.parameter)) {
      _constrainParameterLower(q.parameter, p);
      return true;
    }

    // If P and Q are identical types, then the subtype match holds under no
    // constraints.
    //
    // We're only checking primitive types for equality, because the algorithm
    // will recurse over non-primitive types anyway.
    if (identical(p, q) ||
        isPrimitiveDartType(p) && isPrimitiveDartType(q) && p == q) {
      return true;
    }

    // If P is a legacy type P0* then the match holds under constraint set C:
    //
    // Only if P0 is a subtype match for Q under constraint set C.
    if (_typeOperations.getNullabilitySuffix(p) == NullabilitySuffix.star) {
      return _isNullabilityAwareSubtypeMatch(
          _typeOperations.withNullabilitySuffix(p, NullabilitySuffix.none), q,
          constrainSupertype: constrainSupertype);
    }

    // If Q is a legacy type Q0* then the match holds under constraint set C:
    //
    // If P is dynamic or void and P is a subtype match for Q0 under constraint
    // set C.
    // Or if P is not dynamic or void and P is a subtype match for Q0? under
    // constraint set C.
    if (_typeOperations.getNullabilitySuffix(q) == NullabilitySuffix.star) {
      final int baseConstraintCount = _protoConstraints.length;

      if ((_typeOperations.isDynamic(p) || _typeOperations.isVoid(p)) &&
          _isNullabilityAwareSubtypeMatch(p,
              _typeOperations.withNullabilitySuffix(q, NullabilitySuffix.none),
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (!_typeOperations.isDynamic(p) &&
          !_typeOperations.isVoid(p) &&
          _isNullabilityAwareSubtypeMatch(
              p,
              _typeOperations.withNullabilitySuffix(
                  q, NullabilitySuffix.question),
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If Q is FutureOr<Q0> the match holds under constraint set C:
    //
    // If P is FutureOr<P0> and P0 is a subtype match for Q0 under constraint
    // set C.  Or if P is a subtype match for Future<Q0> under non-empty
    // constraint set C.  Or if P is a subtype match for Q0 under constraint set
    // C.  Or if P is a subtype match for Future<Q0> under empty constraint set
    // C.
    if (_typeOperations.matchFutureOr(q) != null) {
      final int baseConstraintCount = _protoConstraints.length;

      if (p is FutureOrType &&
          _isNullabilityAwareSubtypeMatch(
              p.typeArgument, (q as FutureOrType).typeArgument,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      bool isMatchWithFuture = _isNullabilityAwareSubtypeMatch(
          p,
          _environment.futureType(
              (q as FutureOrType).typeArgument, Nullability.nonNullable),
          constrainSupertype: constrainSupertype);
      bool matchWithFutureAddsConstraints =
          _protoConstraints.length != baseConstraintCount;
      if (isMatchWithFuture && matchWithFutureAddsConstraints) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (_isNullabilityAwareSubtypeMatch(p, q.typeArgument,
          constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (isMatchWithFuture && !matchWithFutureAddsConstraints) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If Q is Q0? the match holds under constraint set C:
    //
    // If P is P0? and P0 is a subtype match for Q0 under constraint set C.
    // Or if P is dynamic or void and Object is a subtype match for Q0 under
    // constraint set C.
    // Or if P is a subtype match for Q0 under non-empty constraint set C.
    // Or if P is a subtype match for Null under constraint set C.
    // Or if P is a subtype match for Q0 under empty constraint set C.
    if (_typeOperations.getNullabilitySuffix(q) == NullabilitySuffix.question) {
      final int baseConstraintCount = _protoConstraints.length;
      final DartType rawP =
          _typeOperations.withNullabilitySuffix(p, NullabilitySuffix.none);
      final DartType rawQ =
          _typeOperations.withNullabilitySuffix(q, NullabilitySuffix.none);

      if (_typeOperations.getNullabilitySuffix(p) ==
              NullabilitySuffix.question &&
          _isNullabilityAwareSubtypeMatch(rawP, rawQ,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if ((_typeOperations.isDynamic(p) || _typeOperations.isVoid(p)) &&
          _isNullabilityAwareSubtypeMatch(_typeOperations.objectType, rawQ,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      bool isMatchWithRawQ = _isNullabilityAwareSubtypeMatch(p, rawQ,
          constrainSupertype: constrainSupertype);
      bool matchWithRawQAddsConstraints =
          _protoConstraints.length != baseConstraintCount;
      if (isMatchWithRawQ && matchWithRawQAddsConstraints) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (_isNullabilityAwareSubtypeMatch(p, _typeOperations.nullType,
          constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (isMatchWithRawQ && !matchWithRawQAddsConstraints) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If P is FutureOr<P0> the match holds under constraint set C1 + C2:
    //
    // If Future<P0> is a subtype match for Q under constraint set C1.
    // And if P0 is a subtype match for Q under constraint set C2.
    if (_typeOperations.matchFutureOr(p) != null) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(
              _environment.futureType(
                  (p as FutureOrType).typeArgument, Nullability.nonNullable),
              q,
              constrainSupertype: constrainSupertype) &&
          _isNullabilityAwareSubtypeMatch(p.typeArgument, q,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If P is P0? the match holds under constraint set C1 + C2:
    //
    // If P0 is a subtype match for Q under constraint set C1.
    // And if Null is a subtype match for Q under constraint set C2.
    if (isNullableTypeConstructorApplication(p)) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(
              _typeOperations.withNullabilitySuffix(p, NullabilitySuffix.none),
              q,
              constrainSupertype: constrainSupertype) &&
          _isNullabilityAwareSubtypeMatch(_typeOperations.nullType, q,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If Q is dynamic, Object?, or void then the match holds under no
    // constraints.
    if (_typeOperations.isDynamic(q) ||
        _typeOperations.isVoid(q) ||
        q == _typeOperations.objectQuestionType) {
      return true;
    }

    // If P is Never then the match holds under no constraints.
    if (_typeOperations.isNever(p) &&
        _typeOperations.getNullabilitySuffix(p) == NullabilitySuffix.none) {
      return true;
    }

    // If Q is Object, then the match holds under no constraints:
    //
    // Only if P is non-nullable.
    if (q == _typeOperations.objectType) {
      return _typeOperations.getNullabilitySuffix(p) == NullabilitySuffix.none;
    }

    // If P is Null, then the match holds under no constraints:
    //
    // Only if Q is nullable.
    if (_typeOperations.isNull(p)) {
      return q.nullability == Nullability.nullable;
    }

    // If P is a type variable X with bound B (or a promoted type variable X &
    // B), the match holds with constraint set C:
    //
    // If B is a subtype match for Q with constraint set C.  Note that we have
    // already eliminated the case that X is a variable in L.
    if (p is TypeParameterType) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(p.bound, q,
          constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    } else if (p is StructuralParameterType) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(p.bound, q,
          constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If P is C<M0, ..., Mk> and Q is C<N0, ..., Nk>, then the match holds
    // under constraints C0 + ... + Ck:
    //
    // If Mi is a subtype match for Ni with respect to L under constraints Ci.
    TypeDeclarationKind? pTypeDeclarationKind =
        _typeOperations.getTypeDeclarationKind(p);
    TypeDeclarationKind? qTypeDeclarationKind =
        _typeOperations.getTypeDeclarationKind(q);
    if (pTypeDeclarationKind == TypeDeclarationKind.interfaceDeclaration &&
        qTypeDeclarationKind == TypeDeclarationKind.interfaceDeclaration) {
      if ((p as InterfaceType).classNode == (q as InterfaceType).classNode) {
        assert(p.typeArguments.length == q.typeArguments.length);

        final int baseConstraintCount = _protoConstraints.length;
        bool isMatch = true;
        for (int i = 0; isMatch && i < p.typeArguments.length; ++i) {
          isMatch = _isNullabilityAwareInterfaceSubtypeMatch(p, q,
              constrainSupertype: constrainSupertype);
        }
        if (isMatch) return true;
        _protoConstraints.length = baseConstraintCount;
      }
    } else if (pTypeDeclarationKind ==
            TypeDeclarationKind.extensionTypeDeclaration &&
        qTypeDeclarationKind == TypeDeclarationKind.extensionTypeDeclaration) {
      if ((p as ExtensionType).extensionTypeDeclaration ==
          (q as ExtensionType).extensionTypeDeclaration) {
        assert(p.typeArguments.length == q.typeArguments.length);

        final int baseConstraintCount = _protoConstraints.length;
        bool isMatch = true;
        for (int i = 0; isMatch && i < p.typeArguments.length; ++i) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(
                  p.typeArguments[i], q.typeArguments[i],
                  constrainSupertype: constrainSupertype);
        }
        if (isMatch) return true;
        _protoConstraints.length = baseConstraintCount;
      }
    }

    // If P is C0<M0, ..., Mk> and Q is C1<N0, ..., Nj> then the match holds
    // with respect to L under constraints C:
    //
    // If C1<B0, ..., Bj> is a superinterface of C0<M0, ..., Mk> and C1<B0, ...,
    // Bj> is a subtype match for C1<N0, ..., Nj> with respect to L under
    // constraints C.
    if (pTypeDeclarationKind != null && qTypeDeclarationKind != null) {
      final List<DartType>? sArguments = getTypeArgumentsAsInstanceOf(
          p as TypeDeclarationType, (q as TypeDeclarationType).typeDeclaration);
      if (sArguments != null) {
        assert(sArguments.length == q.typeArguments.length);

        final int baseConstraintCount = _protoConstraints.length;
        bool isMatch = true;
        for (int i = 0; isMatch && i < sArguments.length; ++i) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(sArguments[i], q.typeArguments[i],
                  constrainSupertype: constrainSupertype);
        }
        if (isMatch) return true;
        _protoConstraints.length = baseConstraintCount;
      }
    }

    // If Q is Function then the match holds under no constraints:
    //
    // If P is a function type.
    if (q == _environment.coreTypes.functionNonNullableRawType &&
        _typeOperations.isFunctionType(p)) {
      return true;
    }

    // A function type (M0,..., Mn, [M{n+1}, ..., Mm]) -> R0 is a subtype match
    // for a function type (N0,..., Nk, [N{k+1}, ..., Nr]) -> R1 with respect to
    // L under constraints C0 + ... + Cr + C
    //
    // If R0 is a subtype match for a type R1 with respect to L under
    // constraints C.  If n <= k and r <= m.  And for i in 0...r, Ni is a
    // subtype match for Mi with respect to L under constraints Ci.
    if (_typeOperations.isFunctionType(p) &&
        _typeOperations.isFunctionType(q) &&
        (p as FunctionType).typeParameters.isEmpty &&
        (q as FunctionType).typeParameters.isEmpty &&
        p.namedParameters.isEmpty &&
        q.namedParameters.isEmpty &&
        p.requiredParameterCount <= q.requiredParameterCount &&
        p.positionalParameters.length >= q.positionalParameters.length) {
      final int baseConstraintCount = _protoConstraints.length;

      if (_isNullabilityAwareSubtypeMatch(p.returnType, q.returnType,
          constrainSupertype: constrainSupertype)) {
        bool isMatch = true;
        for (int i = 0; isMatch && i < q.positionalParameters.length; ++i) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(
                  q.positionalParameters[i], p.positionalParameters[i],
                  constrainSupertype: !constrainSupertype);
        }
        if (isMatch) return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // Function types with named parameters are treated analogously to the
    // positional parameter case above.
    if (_typeOperations.isFunctionType(p) &&
        _typeOperations.isFunctionType(q) &&
        (p as FunctionType).typeParameters.isEmpty &&
        (q as FunctionType).typeParameters.isEmpty &&
        p.positionalParameters.length == p.requiredParameterCount &&
        q.positionalParameters.length == q.requiredParameterCount &&
        p.requiredParameterCount == q.requiredParameterCount &&
        (p.namedParameters.isNotEmpty || q.namedParameters.isNotEmpty)) {
      final int baseConstraintCount = _protoConstraints.length;

      if (_isNullabilityAwareSubtypeMatch(p.returnType, q.returnType,
          constrainSupertype: constrainSupertype)) {
        bool isMatch = true;
        for (int i = 0; isMatch && i < p.positionalParameters.length; ++i) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(
                  q.positionalParameters[i], p.positionalParameters[i],
                  constrainSupertype: !constrainSupertype);
        }
        Map<String, DartType> pNamedTypes = {};
        for (int i = 0; isMatch && i < p.namedParameters.length; ++i) {
          pNamedTypes[p.namedParameters[i].name] = p.namedParameters[i].type;
        }
        for (int i = 0; isMatch && i < q.namedParameters.length; ++i) {
          isMatch =
              isMatch && pNamedTypes.containsKey(q.namedParameters[i].name);
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(q.namedParameters[i].type,
                  pNamedTypes[q.namedParameters[i].name]!,
                  constrainSupertype: !constrainSupertype);
        }
        if (isMatch) return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // A generic function type <T0 extends B00, ..., Tn extends B0n>F0 is a
    // subtype match for a generic function type <S0 extends B10, ..., Sn
    // extends B1n>F1 with respect to L under constraint set C2
    //
    // If B0i is a subtype match for B1i with constraint set Ci0.  And B1i is a
    // subtype match for B0i with constraint set Ci1.  And Ci2 is Ci0 + Ci1.
    //
    // And Z0...Zn are fresh variables with bounds B20, ..., B2n, Where B2i is
    // B0i[Z0/T0, ..., Zn/Tn] if P is a type schema.  Or B2i is B1i[Z0/S0, ...,
    // Zn/Sn] if Q is a type schema.  In other words, we choose the bounds for
    // the fresh variables from whichever of the two generic function types is a
    // type schema and does not contain any variables from L.
    //
    // And F0[Z0/T0, ..., Zn/Tn] is a subtype match for F1[Z0/S0, ..., Zn/Sn]
    // with respect to L under constraints C0.  And C1 is C02 + ... + Cn2 + C0.
    // And C2 is C1 with each constraint replaced with its closure with respect
    // to [Z0, ..., Zn].
    if (_typeOperations.isFunctionType(p) &&
        _typeOperations.isFunctionType(q) &&
        (p as FunctionType).typeParameters.isNotEmpty &&
        (q as FunctionType).typeParameters.isNotEmpty &&
        p.typeParameters.length == q.typeParameters.length) {
      final int baseConstraintCount = _protoConstraints.length;

      bool isMatch = true;
      for (int i = 0; isMatch && i < p.typeParameters.length; ++i) {
        isMatch = isMatch &&
            _isNullabilityAwareSubtypeMatch(
                p.typeParameters[i].bound, q.typeParameters[i].bound,
                constrainSupertype: constrainSupertype) &&
            _isNullabilityAwareSubtypeMatch(
                q.typeParameters[i].bound, p.typeParameters[i].bound,
                constrainSupertype: !constrainSupertype);
      }
      if (isMatch) {
        List<DartType> typeParametersOfPAsTypesForQ =
            new List<DartType>.generate(
                p.typeParameters.length,
                (int i) => new StructuralParameterType.forAlphaRenaming(
                    q.typeParameters[i], p.typeParameters[i]));
        FunctionType instantiatedP = p.withoutTypeParameters;
        FunctionType instantiatedQ = FunctionTypeInstantiator.instantiate(
            q, typeParametersOfPAsTypesForQ);
        if (_isNullabilityAwareSubtypeMatch(instantiatedP, instantiatedQ,
            constrainSupertype: constrainSupertype)) {
          List<_ProtoConstraint> constraints =
              _protoConstraints.sublist(baseConstraintCount);
          _protoConstraints.length = baseConstraintCount;
          NullabilityAwareTypeVariableEliminator eliminator =
              new NullabilityAwareTypeVariableEliminator(
                  structuralEliminationTargets: p.typeParameters.toSet(),
                  nominalEliminationTargets: {},
                  bottomType: _typeOperations.neverType,
                  topType: _typeOperations.objectQuestionType,
                  topFunctionType:
                      _environment.coreTypes.functionNonNullableRawType,
                  unhandledTypeHandler: (DartType type, ignored) =>
                      type is UnknownType
                          ? false
                          : throw new UnsupportedError(
                              "Unsupported type '${type.runtimeType}'."));
          for (_ProtoConstraint constraint in constraints) {
            if (constraint.isUpper) {
              _constrainParameterUpper(constraint.parameter,
                  eliminator.eliminateToLeast(constraint.bound));
            } else {
              _constrainParameterLower(constraint.parameter,
                  eliminator.eliminateToGreatest(constraint.bound));
            }
          }
          return true;
        }
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // A type P is a subtype match for Record with respect to L under no
    // constraints:
    //
    // If P is a record type or Record.
    if (q == _environment.coreTypes.recordNonNullableRawType &&
        p is RecordType) {
      return true;
    }

    // A record type `(M0,..., Mk, {M{k+1} d{k+1}, ..., Mm dm])` is a subtype
    // match for a record type `(N0,..., Nk, {N{k+1} d{k+1}, ..., Nm dm])` with
    // respect to `L` under constraints `C0 + ... + Cm`
    // If for `i` in `0...m`, `Mi` is a subtype match for `Ni` with respect to
    // `L` under constraints `Ci`.
    if (_typeOperations.isRecordType(p) &&
        _typeOperations.isRecordType(q) &&
        (p as RecordType).positional.length ==
            (q as RecordType).positional.length &&
        p.named.length == q.named.length) {
      bool sameNames = true;
      for (int i = 0; sameNames && i < p.named.length; i++) {
        if (p.named[i] != p.named[i]) {
          sameNames = false;
        }
      }
      if (sameNames) {
        bool isMatch = true;
        for (int i = 0; isMatch && i < p.positional.length; i++) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(p.positional[i], q.positional[i],
                  constrainSupertype: constrainSupertype);
        }
        for (int i = 0; isMatch && i < p.named.length; i++) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(p.named[i].type, q.named[i].type,
                  constrainSupertype: constrainSupertype);
        }
        if (isMatch) return true;
      }
    }

    return false;
  }

  /// Attempts to match [subtype] as a subtype of [supertype], gathering any
  /// constraints discovered in the process.
  ///
  /// If a set of constraints was found, `true` is returned and the caller
  /// may proceed to call [computeConstraints].  Otherwise, `false` is returned.
  ///
  /// In the case where `false` is returned, some bogus constraints may have
  /// been added to [_protoConstraints].  It is the caller's responsibility to
  /// discard them if necessary.
  bool _isNullabilityObliviousSubtypeMatch(
      DartType subtype, DartType supertype) {
    // The unknown type `?` is a subtype match for any type `Q` with no
    // constraints.
    if (_typeOperations.isUnknownType(subtype)) return true;
    // Any type `P` is a subtype match for the unknown type `?` with no
    // constraints.
    if (_typeOperations.isUnknownType(supertype)) return true;
    // A type variable `T` in `L` is a subtype match for any type schema `Q`:
    // - Under constraint `T <: Q`.

    // TODO(cstefantsova): Don't forget to remove the commented out code below.
    // [TypeParameter] objects are never the target of inference, and the
    // condition will always fail for them.

    // if (subtype is TypeParameterType &&
    //     _parametersToConstrain.contains(subtype.parameter)) {
    //   _constrainParameterUpper(subtype.parameter, supertype);
    //   return true;
    // }
    if (subtype is StructuralParameterType &&
        _parametersToConstrain.contains(subtype.parameter)) {
      _constrainParameterUpper(subtype.parameter, supertype);
      return true;
    }
    // A type schema `Q` is a subtype match for a type variable `T` in `L`:
    // - Under constraint `Q <: T`.

    // TODO(cstefantsova): Don't forget to remove the commented out code below.
    // [TypeParameter] objects are never the target of inference, and the
    // condition will always fail for them.

    // if (supertype is TypeParameterType &&
    //     _parametersToConstrain.contains(supertype.parameter)) {
    //   _constrainParameterLower(supertype.parameter, subtype);
    //   return true;
    // }
    if (supertype is StructuralParameterType &&
        _parametersToConstrain.contains(supertype.parameter)) {
      _constrainParameterLower(supertype.parameter, subtype);
      return true;
    }
    // Any two equal types `P` and `Q` are subtype matches under no constraints.
    // Note: to avoid making the algorithm quadratic, we just check for
    // identical().  If P and Q are equal but not identical, recursing through
    // the types will give the proper result.
    if (identical(subtype, supertype)) return true;

    // Handle FutureOr<T> union type.
    if (_typeOperations.matchFutureOr(subtype) != null) {
      DartType subtypeArg = (subtype as FutureOrType).typeArgument;
      if (supertype is FutureOrType) {
        // `FutureOr<P>` is a subtype match for `FutureOr<Q>` with respect to
        // `L` under constraints `C`:
        // - If `P` is a subtype match for `Q` with respect to `L` under
        //   constraints `C`.
        DartType supertypeArg = supertype.typeArgument;
        return _isNullabilityObliviousSubtypeMatch(subtypeArg, supertypeArg);
      }

      // `FutureOr<P>` is a subtype match for `Q` with respect to `L` under
      // constraints `C0 + C1`:
      // - If `Future<P>` is a subtype match for `Q` with respect to `L` under
      //   constraints `C0`.
      // - And `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C1`.
      InterfaceType subtypeFuture = _environment.futureType(
          subtypeArg,
          _isNonNullableByDefault
              ? Nullability.nonNullable
              : Nullability.legacy);
      return _isNullabilityObliviousSubtypeMatch(subtypeFuture, supertype) &&
          _isNullabilityObliviousSubtypeMatch(subtypeArg, supertype) &&
          new IsSubtypeOf.basedSolelyOnNullabilities(subtype, supertype)
              .isSubtypeWhenUsingNullabilities();
    }

    if (_typeOperations.matchFutureOr(supertype) != null) {
      // `P` is a subtype match for `FutureOr<Q>` with respect to `L` under
      // constraints `C`:
      // - If `P` is a subtype match for `Future<Q>` with respect to `L` under
      //   constraints `C`.
      // - Or `P` is not a subtype match for `Future<Q>` with respect to `L`
      //   under constraints `C`
      //   - And `P` is a subtype match for `Q` with respect to `L` under
      //     constraints `C`

      // Since FutureOr<S> is a union type Future<S> U S where U denotes the
      // union operation on types, T? is T U Null, T U T = T, S U T = T U S, and
      // S U (T U V) = (S U T) U V, the following is true:
      //
      //   - FutureOr<S?> = S? U Future<S?>?
      //   - FutureOr<S>? = S? U Future<S>?
      //
      // To compute the nullabilities for the two types in the union, the
      // nullability of the argument and the declared nullability of FutureOr
      // should be united.  Also, computeNullability is used to fetch the
      // nullability of the argument because it can be a FutureOr itself.
      Nullability unitedNullability = uniteNullabilities(
          (supertype as FutureOrType).typeArgument.nullability,
          supertype.nullability);
      DartType supertypeArg =
          supertype.typeArgument.withDeclaredNullability(unitedNullability);
      DartType supertypeFuture =
          _environment.futureType(supertypeArg, unitedNullability);

      // The match against FutureOr<X> succeeds if the match against either
      // Future<X> or X succeeds.  If they both succeed, the one adding new
      // constraints should be preferred.  If both matches against Future<X> and
      // X add new constraints, the former should be preferred over the latter.
      int oldProtoConstraintsLength = _protoConstraints.length;
      bool matchesFuture =
          _tryNullabilityObliviousSubtypeMatch(subtype, supertypeFuture);
      bool matchesArg = oldProtoConstraintsLength != _protoConstraints.length
          ? false
          : _isNullabilityObliviousSubtypeMatch(subtype, supertypeArg);
      return matchesFuture || matchesArg;
    }

    // Any type `P` is a subtype match for `dynamic`, `Object`, or `void` under
    // no constraints.
    if (_isTop(supertype)) return true;
    // `Null` is a subtype match for any type `Q` under no constraints.
    // Note that nullable types will change this.
    if (_typeOperations.isNull(subtype)) return true;

    // A type variable `T` not in `L` with bound `P` is a subtype match for the
    // same type variable `T` with bound `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is a subtype match for `Q` with respect to `L` under constraints
    //   `C`.
    if (subtype is TypeParameterType) {
      if (supertype is TypeParameterType &&
          identical(subtype.parameter, supertype.parameter)) {
        // Kernel doesn't yet allow a type variable to have different bounds
        // under different circumstances (see dartbug.com/29529) so for now if
        // we get here, the bounds must be the same.
        // TODO(paulberry): update this code once dartbug.com/29529 is
        // addressed.
        return true;
      }
      // A type variable `T` not in `L` with bound `P` is a subtype match for a
      // type `Q` with respect to `L` under constraints `C`:
      // - If `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C`.
      return _isNullabilityObliviousSubtypeMatch(
          subtype.parameter.bound, supertype);
    } else if (subtype is StructuralParameterType) {
      if (supertype is StructuralParameterType &&
          identical(subtype.parameter, supertype.parameter)) {
        // Kernel doesn't yet allow a type variable to have different bounds
        // under different circumstances (see dartbug.com/29529) so for now if
        // we get here, the bounds must be the same.
        // TODO(paulberry): update this code once dartbug.com/29529 is
        // addressed.
        return true;
      }
      // A type variable `T` not in `L` with bound `P` is a subtype match for a
      // type `Q` with respect to `L` under constraints `C`:
      // - If `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C`.
      return _isNullabilityObliviousSubtypeMatch(
          subtype.parameter.bound, supertype);
    }
    if (_typeOperations.isInterfaceType(subtype) &&
        _typeOperations.isInterfaceType(supertype)) {
      return _isNullabilityObliviousInterfaceSubtypeMatch(
          subtype as InterfaceType, supertype as InterfaceType);
    }
    if (_typeOperations.isFunctionType(subtype)) {
      if (_typeOperations.isInterfaceType(supertype)) {
        return supertype == _environment.coreTypes.functionLegacyRawType ||
            supertype == _environment.coreTypes.objectLegacyRawType;
      } else if (supertype is FunctionType) {
        return _isFunctionSubtypeMatch(subtype as FunctionType, supertype);
      }
    }
    // A type `P` is a subtype match for a type `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is an interface type which implements a call method of type `F`,
    //   and `F` is a subtype match for a type `Q` with respect to `L` under
    //   constraints `C`.
    if (_typeOperations.isInterfaceType(subtype)) {
      Member? callMember =
          getInterfaceMember((subtype as InterfaceType).classNode, callName);
      if (callMember is Procedure && !callMember.isGetter) {
        DartType callType = callMember.getterType;
        callType =
            Substitution.fromInterfaceType(subtype).substituteType(callType);
        // TODO(kmillikin): The subtype check will fail if the type of a
        // generic call method is a subtype of a non-generic function type.
        // For example, if `T call<T>(T arg)` is a subtype of `S->S` for some
        // S.  However, explicitly tearing off that call method will work and
        // insert an explicit instantiation, so the implicit tear off should
        // work as well.  Figure out how to support this case.
        return _isNullabilityObliviousSubtypeMatch(callType, supertype);
      }
    }
    return false;
  }

  bool _isTop(DartType type) =>
      type is DynamicType ||
      type is VoidType ||
      type == _environment.coreTypes.objectLegacyRawType;

  /// Given two lists of function type formal parameters, checks that their
  /// bounds are compatible.
  ///
  /// The return value indicates whether a match was found.  If it was, entries
  /// are added to [substitution1] and [substitution2] which substitute a fresh
  /// set of type variables for the type parameters [params1] and [params2],
  /// respectively, allowing further comparison.
  bool _matchTypeFormals(
      List<StructuralParameter> params1,
      List<StructuralParameter> params2,
      List<StructuralParameter> freshTypeVariables,
      List<DartType> freshTypeVariablesAsTypes) {
    assert(params1.length == params2.length);
    // TODO(paulberry): in imitation of analyzer, we're checking the bounds as
    // we build up the substitutions.  But I don't think that's correct--I think
    // we should build up both substitutions completely before checking any
    // bounds.  See dartbug.com/29629.
    for (int i = 0; i < params1.length; ++i) {
      StructuralParameter pFresh = new StructuralParameter(params2[i].name);
      freshTypeVariables.add(pFresh);
      DartType variableFresh =
          new StructuralParameterType.forAlphaRenaming(params2[i], pFresh);
      freshTypeVariablesAsTypes.add(variableFresh);
      DartType bound1 = new FunctionTypeInstantiator.fromIterables(
              params1.sublist(0, i + 1), freshTypeVariablesAsTypes)
          .substitute(params1[i].bound);
      DartType bound2 = new FunctionTypeInstantiator.fromIterables(
              params2.sublist(0, i + 1), freshTypeVariablesAsTypes)
          .substitute(params2[i].bound);
      pFresh.bound = bound2;
      if (!_isNullabilityObliviousSubtypeMatch(bound2, bound1)) return false;
    }
    return true;
  }
}

/// Tracks a single constraint on a single type variable.
///
/// This is called "_ProtoConstraint" to distinguish from [TypeConstraint],
/// which tracks the upper and lower bounds that are together implied by a set
/// of [_ProtoConstraint]s.
class _ProtoConstraint {
  final StructuralParameter parameter;

  final DartType bound;

  final bool isUpper;

  _ProtoConstraint.lower(this.parameter, this.bound) : isUpper = false;

  _ProtoConstraint.upper(this.parameter, this.bound) : isUpper = true;

  @override
  String toString() {
    return isUpper
        ? "${parameter.name} <: $bound"
        : "$bound <: ${parameter.name}";
  }
}
