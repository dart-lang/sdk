// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/core_types.dart';

import 'package:kernel/type_algebra.dart';

import 'package:kernel/type_environment.dart';

import 'type_schema.dart' show UnknownType;

import '../names.dart' show callName;

import 'type_schema.dart';

import 'type_schema_environment.dart';

/// Creates a collection of [TypeConstraint]s corresponding to type parameters,
/// based on an attempt to make one type schema a subtype of another.
abstract class TypeConstraintGatherer {
  final List<_ProtoConstraint> _protoConstraints = [];

  final List<TypeParameter> _parametersToConstrain;

  final Library _currentLibrary;

  /// Creates a [TypeConstraintGatherer] which is prepared to gather type
  /// constraints for the given [typeParameters].
  TypeConstraintGatherer.subclassing(
      Iterable<TypeParameter> typeParameters, this._currentLibrary)
      : _parametersToConstrain = typeParameters.toList();

  factory TypeConstraintGatherer(TypeSchemaEnvironment environment,
      Iterable<TypeParameter> typeParameters, Library currentLibrary) {
    return new TypeSchemaConstraintGatherer(
        environment, typeParameters, currentLibrary);
  }

  CoreTypes get coreTypes;

  void addUpperBound(
      TypeConstraint constraint, DartType upper, Library clientLibrary);

  void addLowerBound(
      TypeConstraint constraint, DartType lower, Library clientLibrary);

  Member getInterfaceMember(Class class_, Name name, {bool setter: false});

  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes);

  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass);

  InterfaceType futureType(DartType type, Nullability nullability);

  /// Returns the set of type constraints that was gathered.
  Map<TypeParameter, TypeConstraint> computeConstraints(Library clientLibrary) {
    Map<TypeParameter, TypeConstraint> result =
        <TypeParameter, TypeConstraint>{};
    for (TypeParameter parameter in _parametersToConstrain) {
      result[parameter] = new TypeConstraint();
    }
    for (_ProtoConstraint protoConstraint in _protoConstraints) {
      if (protoConstraint.isUpper) {
        addUpperBound(result[protoConstraint.parameter], protoConstraint.bound,
            clientLibrary);
      } else {
        addLowerBound(result[protoConstraint.parameter], protoConstraint.bound,
            clientLibrary);
      }
    }
    return result;
  }

  /// Tries to constrain type parameters in [type], so that [bound] <: [type].
  ///
  /// Doesn't change the already accumulated set of constraints if [bound] isn't
  /// a subtype of [type] under any set of constraints.
  bool tryConstrainLower(DartType type, DartType bound) {
    if (_currentLibrary.isNonNullableByDefault) {
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
    if (_currentLibrary.isNonNullableByDefault) {
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
      {bool constrainSupertype}) {
    assert(constrainSupertype != null);
    int baseConstraintCount = _protoConstraints.length;
    bool isMatch = _isNullabilityAwareSubtypeMatch(subtype, supertype,
        constrainSupertype: constrainSupertype);
    if (!isMatch) {
      _protoConstraints.length = baseConstraintCount;
    }
    return isMatch;
  }

  /// Add constraint: [lower] <: [parameter] <: TOP.
  void _constrainParameterLower(TypeParameter parameter, DartType lower) {
    _protoConstraints.add(new _ProtoConstraint.lower(parameter, lower));
  }

  /// Add constraint: BOTTOM <: [parameter] <: [upper].
  void _constrainParameterUpper(TypeParameter parameter, DartType upper) {
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
      Map<TypeParameter, DartType> subtypeSubstitution =
          <TypeParameter, DartType>{};
      Map<TypeParameter, DartType> supertypeSubstitution =
          <TypeParameter, DartType>{};
      List<TypeParameter> freshTypeVariables = <TypeParameter>[];
      if (!_matchTypeFormals(subtype.typeParameters, supertype.typeParameters,
          subtypeSubstitution, supertypeSubstitution, freshTypeVariables)) {
        return false;
      }

      subtype = substituteTypeParams(
          subtype, subtypeSubstitution, freshTypeVariables);
      supertype = substituteTypeParams(
          supertype, supertypeSubstitution, freshTypeVariables);
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

  bool _isInterfaceSubtypeMatch(
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
    List<DartType> matchingSupertypeOfSubtypeArguments =
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

  bool _isNull(DartType type) {
    // TODO(paulberry): would it be better to call this "_isBottom", and to have
    // it return `true` for both Null and bottom types?  Revisit this once
    // enough functionality is implemented that we can compare the behavior with
    // the old analyzer-based implementation.
    return type is NullType;
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
      {bool constrainSupertype}) {
    assert(p != null);
    assert(q != null);
    assert(constrainSupertype != null);

    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the subtype (that is, [p]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        !constrainSupertype ||
            !containsTypeVariable(p, _parametersToConstrain.toSet(),
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
            !containsTypeVariable(q, _parametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        : throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "!constrainSupertype -> !containsTypeVariable(q)");

    if (p is InvalidType || q is InvalidType) return false;

    // If P is _ then the match holds with no constraints.
    if (p is UnknownType) return true;

    // If Q is _ then the match holds with no constraints.
    if (q is UnknownType) return true;

    // If P is a type variable X in L, then the match holds:
    //
    // Under constraint _ <: X <: Q.
    if (p is TypeParameterType &&
        isTypeParameterTypeWithoutNullabilityMarker(p, _currentLibrary) &&
        _parametersToConstrain.contains(p.parameter)) {
      _constrainParameterUpper(p.parameter, q);
      return true;
    }

    // If Q is a type variable X in L, then the match holds:
    //
    // Under constraint P <: X <: _.
    if (q is TypeParameterType &&
        isTypeParameterTypeWithoutNullabilityMarker(q, _currentLibrary) &&
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
    if (isLegacyTypeConstructorApplication(p, _currentLibrary)) {
      return _isNullabilityAwareSubtypeMatch(
          computeTypeWithoutNullabilityMarker(p, _currentLibrary), q,
          constrainSupertype: constrainSupertype);
    }

    // If Q is a legacy type Q0* then the match holds under constraint set C:
    //
    // If P is dynamic or void and P is a subtype match for Q0 under constraint
    // set C.
    // Or if P is not dynamic or void and P is a subtype match for Q0? under
    // constraint set C.
    if (isLegacyTypeConstructorApplication(q, _currentLibrary)) {
      final int baseConstraintCount = _protoConstraints.length;

      if ((p is DynamicType || p is VoidType) &&
          _isNullabilityAwareSubtypeMatch(
              p, computeTypeWithoutNullabilityMarker(q, _currentLibrary),
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (p is! DynamicType &&
          p is! VoidType &&
          _isNullabilityAwareSubtypeMatch(
              p, q.withDeclaredNullability(Nullability.nullable),
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
    if (q is FutureOrType) {
      final int baseConstraintCount = _protoConstraints.length;

      if (p is FutureOrType &&
          _isNullabilityAwareSubtypeMatch(p.typeArgument, q.typeArgument,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      bool isMatchWithFuture = _isNullabilityAwareSubtypeMatch(
          p, futureType(q.typeArgument, Nullability.nonNullable),
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
    if (isNullableTypeConstructorApplication(q)) {
      final int baseConstraintCount = _protoConstraints.length;
      final DartType rawP =
          computeTypeWithoutNullabilityMarker(p, _currentLibrary);
      final DartType rawQ =
          computeTypeWithoutNullabilityMarker(q, _currentLibrary);

      if (isNullableTypeConstructorApplication(p) &&
          _isNullabilityAwareSubtypeMatch(rawP, rawQ,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if ((p is DynamicType || p is VoidType) &&
          _isNullabilityAwareSubtypeMatch(
              coreTypes.objectNonNullableRawType, rawQ,
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

      if (_isNullabilityAwareSubtypeMatch(p, const NullType(),
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
    if (p is FutureOrType) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(
              futureType(p.typeArgument, Nullability.nonNullable), q,
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
              computeTypeWithoutNullabilityMarker(p, _currentLibrary), q,
              constrainSupertype: constrainSupertype) &&
          _isNullabilityAwareSubtypeMatch(const NullType(), q,
              constrainSupertype: constrainSupertype)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If Q is dynamic, Object?, or void then the match holds under no
    // constraints.
    if (q is DynamicType ||
        q is VoidType ||
        q == coreTypes.objectNullableRawType) {
      return true;
    }

    // If P is Never then the match holds under no constraints.
    if (p is NeverType && p.declaredNullability == Nullability.nonNullable) {
      return true;
    }

    // If Q is Object, then the match holds under no constraints:
    //
    // Only if P is non-nullable.
    if (q == coreTypes.objectNonNullableRawType) {
      return p.nullability == Nullability.nonNullable;
    }

    // If P is Null, then the match holds under no constraints:
    //
    // Only if Q is nullable.
    if (p is NullType) {
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
    }

    // If P is C<M0, ..., Mk> and Q is C<N0, ..., Nk>, then the match holds
    // under constraints C0 + ... + Ck:
    //
    // If Mi is a subtype match for Ni with respect to L under constraints Ci.
    if (p is InterfaceType &&
        q is InterfaceType &&
        p.classNode == q.classNode) {
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

    // If P is C0<M0, ..., Mk> and Q is C1<N0, ..., Nj> then the match holds
    // with respect to L under constraints C:
    //
    // If C1<B0, ..., Bj> is a superinterface of C0<M0, ..., Mk> and C1<B0, ...,
    // Bj> is a subtype match for C1<N0, ..., Nj> with respect to L under
    // constraints C.
    if (p is InterfaceType && q is InterfaceType) {
      final List<DartType> sArguments =
          getTypeArgumentsAsInstanceOf(p, q.classNode);
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
    if (q == coreTypes.functionNonNullableRawType && p is FunctionType) {
      return true;
    }

    // A function type (M0,..., Mn, [M{n+1}, ..., Mm]) -> R0 is a subtype match
    // for a function type (N0,..., Nk, [N{k+1}, ..., Nr]) -> R1 with respect to
    // L under constraints C0 + ... + Cr + C
    //
    // If R0 is a subtype match for a type R1 with respect to L under
    // constraints C.  If n <= k and r <= m.  And for i in 0...r, Ni is a
    // subtype match for Mi with respect to L under constraints Ci.
    if (p is FunctionType &&
        q is FunctionType &&
        p.typeParameters.isEmpty &&
        q.typeParameters.isEmpty &&
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
    if (p is FunctionType &&
        q is FunctionType &&
        p.typeParameters.isEmpty &&
        q.typeParameters.isEmpty &&
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
                  pNamedTypes[q.namedParameters[i].name],
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
    if (p is FunctionType &&
        q is FunctionType &&
        p.typeParameters.isNotEmpty &&
        q.typeParameters.isNotEmpty &&
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
        FreshTypeParameters freshTypeParameters = getFreshTypeParameters(
            constrainSupertype ? p.typeParameters : q.typeParameters);
        Substitution substitutionForBound = freshTypeParameters.substitution;
        FunctionType constrainedType = constrainSupertype ? q : p;
        Map<TypeParameter, DartType> substitutionMapForConstrainedType = {};
        for (int i = 0; i < constrainedType.typeParameters.length; ++i) {
          substitutionMapForConstrainedType[constrainedType.typeParameters[i]] =
              new TypeParameterType.forAlphaRenaming(
                  constrainedType.typeParameters[i],
                  freshTypeParameters.freshTypeParameters[i]);
        }
        Substitution substitutionForConstrainedType =
            Substitution.fromMap(substitutionMapForConstrainedType);
        Substitution substitutionForP = constrainSupertype
            ? substitutionForBound
            : substitutionForConstrainedType;
        Substitution substitutionForQ = constrainSupertype
            ? substitutionForConstrainedType
            : substitutionForBound;
        if (_isNullabilityAwareSubtypeMatch(
            substitutionForP.substituteType(p.withoutTypeParameters),
            substitutionForQ.substituteType(q.withoutTypeParameters),
            constrainSupertype: constrainSupertype)) {
          List<_ProtoConstraint> constraints =
              _protoConstraints.sublist(baseConstraintCount);
          _protoConstraints.length = baseConstraintCount;
          NullabilityAwareTypeVariableEliminator eliminator =
              new NullabilityAwareTypeVariableEliminator(
                  eliminationTargets:
                      freshTypeParameters.freshTypeParameters.toSet(),
                  bottomType: const NeverType(Nullability.nonNullable),
                  topType: coreTypes.objectNullableRawType,
                  topFunctionType: coreTypes.functionNonNullableRawType,
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
    if (subtype is UnknownType) return true;
    // Any type `P` is a subtype match for the unknown type `?` with no
    // constraints.
    if (supertype is UnknownType) return true;
    // A type variable `T` in `L` is a subtype match for any type schema `Q`:
    // - Under constraint `T <: Q`.
    if (subtype is TypeParameterType &&
        _parametersToConstrain.contains(subtype.parameter)) {
      _constrainParameterUpper(subtype.parameter, supertype);
      return true;
    }
    // A type schema `Q` is a subtype match for a type variable `T` in `L`:
    // - Under constraint `Q <: T`.
    if (supertype is TypeParameterType &&
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
    if (subtype is FutureOrType) {
      DartType subtypeArg = subtype.typeArgument;
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
      InterfaceType subtypeFuture =
          futureType(subtypeArg, _currentLibrary.nonNullable);
      return _isNullabilityObliviousSubtypeMatch(subtypeFuture, supertype) &&
          _isNullabilityObliviousSubtypeMatch(subtypeArg, supertype) &&
          new IsSubtypeOf.basedSolelyOnNullabilities(subtype, supertype)
              .isSubtypeWhenUsingNullabilities();
    }

    if (supertype is FutureOrType) {
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
          supertype.typeArgument.nullability, supertype.nullability);
      DartType supertypeArg =
          supertype.typeArgument.withDeclaredNullability(unitedNullability);
      DartType supertypeFuture = futureType(supertypeArg, unitedNullability);

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
    if (_isNull(subtype)) return true;

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
    }
    if (subtype is InterfaceType && supertype is InterfaceType) {
      return _isInterfaceSubtypeMatch(subtype, supertype);
    }
    if (subtype is FunctionType) {
      if (supertype is InterfaceType) {
        return supertype == coreTypes.functionLegacyRawType ||
            supertype == coreTypes.objectLegacyRawType;
      } else if (supertype is FunctionType) {
        return _isFunctionSubtypeMatch(subtype, supertype);
      }
    }
    // A type `P` is a subtype match for a type `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is an interface type which implements a call method of type `F`,
    //   and `F` is a subtype match for a type `Q` with respect to `L` under
    //   constraints `C`.
    if (subtype is InterfaceType) {
      Member callMember = getInterfaceMember(subtype.classNode, callName);
      if (callMember is Procedure && !callMember.isGetter) {
        DartType callType = callMember.getterType;
        if (callType != null) {
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
    }
    return false;
  }

  bool _isTop(DartType type) =>
      type is DynamicType ||
      type is VoidType ||
      type == coreTypes.objectLegacyRawType;

  /// Given two lists of function type formal parameters, checks that their
  /// bounds are compatible.
  ///
  /// The return value indicates whether a match was found.  If it was, entries
  /// are added to [substitution1] and [substitution2] which substitute a fresh
  /// set of type variables for the type parameters [params1] and [params2],
  /// respectively, allowing further comparison.
  bool _matchTypeFormals(
      List<TypeParameter> params1,
      List<TypeParameter> params2,
      Map<TypeParameter, DartType> substitution1,
      Map<TypeParameter, DartType> substitution2,
      List<TypeParameter> freshTypeVariables) {
    assert(params1.length == params2.length);
    // TODO(paulberry): in imitation of analyzer, we're checking the bounds as
    // we build up the substitutions.  But I don't think that's correct--I think
    // we should build up both substitutions completely before checking any
    // bounds.  See dartbug.com/29629.
    for (int i = 0; i < params1.length; ++i) {
      TypeParameter pFresh = new TypeParameter(params2[i].name);
      freshTypeVariables.add(pFresh);
      DartType variableFresh =
          new TypeParameterType.forAlphaRenaming(params2[i], pFresh);
      substitution1[params1[i]] = variableFresh;
      substitution2[params2[i]] = variableFresh;
      DartType bound1 = substitute(params1[i].bound, substitution1);
      DartType bound2 = substitute(params2[i].bound, substitution2);
      pFresh.bound = bound2;
      if (!_isNullabilityObliviousSubtypeMatch(bound2, bound1)) return false;
    }
    return true;
  }
}

class TypeSchemaConstraintGatherer extends TypeConstraintGatherer {
  final TypeSchemaEnvironment environment;

  TypeSchemaConstraintGatherer(this.environment,
      Iterable<TypeParameter> typeParameters, Library currentLibrary)
      : super.subclassing(typeParameters, currentLibrary);

  @override
  CoreTypes get coreTypes => environment.coreTypes;

  @override
  void addUpperBound(
      TypeConstraint constraint, DartType upper, Library clientLibrary) {
    environment.addUpperBound(constraint, upper, clientLibrary);
  }

  @override
  void addLowerBound(
      TypeConstraint constraint, DartType lower, Library clientLibrary) {
    environment.addLowerBound(constraint, lower, clientLibrary);
  }

  @override
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    return environment.hierarchy
        .getInterfaceMember(class_, name, setter: setter);
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
    return environment.getTypeAsInstanceOf(
        type, superclass, clientLibrary, coreTypes);
  }

  @override
  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    return environment.getTypeArgumentsAsInstanceOf(type, superclass);
  }

  @override
  InterfaceType futureType(DartType type, Nullability nullability) {
    return environment.futureType(type, nullability);
  }
}

/// Tracks a single constraint on a single type variable.
///
/// This is called "_ProtoConstraint" to distinguish from [TypeConstraint],
/// which tracks the upper and lower bounds that are together implied by a set
/// of [_ProtoConstraint]s.
class _ProtoConstraint {
  final TypeParameter parameter;

  final DartType bound;

  final bool isUpper;

  _ProtoConstraint.lower(this.parameter, this.bound) : isUpper = false;

  _ProtoConstraint.upper(this.parameter, this.bound) : isUpper = true;

  String toString() {
    return isUpper
        ? "${parameter.name} <: $bound"
        : "$bound <: ${parameter.name}";
  }
}
