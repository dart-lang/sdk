// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

/// Creates a collection of [TypeConstraint]s corresponding to type parameters,
/// based on an attempt to make one type schema a subtype of another.
class TypeConstraintGatherer {
  final TypeSchemaEnvironment environment;

  final _protoConstraints = <_ProtoConstraint>[];

  final List<TypeParameter> _parametersToConstrain;

  /// Creates a [TypeConstraintGatherer] which is prepared to gather type
  /// constraints for the given [typeParameters].
  TypeConstraintGatherer(
      this.environment, Iterable<TypeParameter> typeParameters)
      : _parametersToConstrain = typeParameters.toList();

  /// Returns the set of type constraints that was gathered.
  Map<TypeParameter, TypeConstraint> computeConstraints() {
    var result = <TypeParameter, TypeConstraint>{};
    for (var parameter in _parametersToConstrain) {
      result[parameter] = new TypeConstraint();
    }
    for (var protoConstraint in _protoConstraints) {
      if (protoConstraint.isUpper) {
        environment.addUpperBound(
            result[protoConstraint.parameter], protoConstraint.bound);
      } else {
        environment.addLowerBound(
            result[protoConstraint.parameter], protoConstraint.bound);
      }
    }
    return result;
  }

  /// Tries to match [subtype] against [supertype].
  ///
  /// If the match suceeds, the resulting type constraints are recorded for
  /// later use by [computeConstraints].  If the match fails, the set of type
  /// constraints is unchanged.
  bool trySubtypeMatch(DartType subtype, DartType supertype) {
    int oldProtoConstraintsLength = _protoConstraints.length;
    bool isMatch = _isSubtypeMatch(subtype, supertype);
    if (!isMatch) {
      _protoConstraints.length = oldProtoConstraintsLength;
    }
    return isMatch;
  }

  void _constrainLower(TypeParameter parameter, DartType lower) {
    _protoConstraints.add(new _ProtoConstraint.lower(parameter, lower));
  }

  void _constrainUpper(TypeParameter parameter, DartType upper) {
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
    if (subtype.typeParameters.isNotEmpty ||
        supertype.typeParameters.isNotEmpty) {
      var subtypeSubstitution = <TypeParameter, DartType>{};
      var supertypeSubstitution = <TypeParameter, DartType>{};
      if (!_matchTypeFormals(subtype.typeParameters, supertype.typeParameters,
          subtypeSubstitution, supertypeSubstitution)) {
        return false;
      }

      // TODO(paulberry): try to push this functionality into kernel.
      FunctionType substituteTypeParams(
          FunctionType type, Map<TypeParameter, DartType> substitutionMap) {
        var substitution = Substitution.fromMap(substitutionMap);
        return new FunctionType(
            type.positionalParameters.map(substitution.substituteType).toList(),
            substitution.substituteType(type.returnType),
            namedParameters: type.namedParameters
                .map((named) => new NamedType(
                    named.name, substitution.substituteType(named.type)))
                .toList(),
            typeParameters: substitutionMap.keys.toList(),
            requiredParameterCount: type.requiredParameterCount);
      }

      subtype = substituteTypeParams(subtype, subtypeSubstitution);
      supertype = substituteTypeParams(supertype, supertypeSubstitution);
    }

    // Test the return types.
    if (supertype.returnType is! VoidType &&
        !_isSubtypeMatch(subtype.returnType, supertype.returnType)) {
      return false;
    }

    // Test the parameter types.
    for (int i = 0; i < supertype.positionalParameters.length; ++i) {
      var supertypeParameter = supertype.positionalParameters[i];
      var subtypeParameter = subtype.positionalParameters[i];
      // Termination: Both types shrink in size.
      if (!_isSubtypeMatch(supertypeParameter, subtypeParameter)) {
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
      if (!_isSubtypeMatch(supertypeParameter.type, subtypeParameter.type)) {
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
    var matchingSupertypeOfSubtype =
        environment.hierarchy.getTypeAsInstanceOf(subtype, supertype.classNode);
    if (matchingSupertypeOfSubtype == null) return false;
    for (int i = 0; i < supertype.classNode.typeParameters.length; i++) {
      if (!_isSubtypeMatch(matchingSupertypeOfSubtype.typeArguments[i],
          supertype.typeArguments[i])) {
        return false;
      }
    }
    return true;
  }

  bool _isNull(DartType type) {
    // TODO(paulberry): would it be better to call this "_isBottom", and to have
    // it return `true` for both Null and bottom types?  Revisit this once
    // enough functionality is implemented that we can compare the behavior with
    // the old analyzer-based implementation.
    return type is InterfaceType &&
        identical(type.classNode, environment.coreTypes.nullClass);
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
  bool _isSubtypeMatch(DartType subtype, DartType supertype) {
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
      _constrainUpper(subtype.parameter, supertype);
      return true;
    }
    // A type schema `Q` is a subtype match for a type variable `T` in `L`:
    // - Under constraint `Q <: T`.
    if (supertype is TypeParameterType &&
        _parametersToConstrain.contains(supertype.parameter)) {
      _constrainLower(supertype.parameter, subtype);
      return true;
    }
    // Any two equal types `P` and `Q` are subtype matches under no constraints.
    // Note: to avoid making the algorithm quadratic, we just check for
    // identical().  If P and Q are equal but not identical, recursing through
    // the types will give the proper result.
    if (identical(subtype, supertype)) return true;
    // Any type `P` is a subtype match for `dynamic`, `Object`, or `void` under
    // no constraints.
    if (_isTop(supertype)) return true;
    // `Null` is a subtype match for any type `Q` under no constraints.
    // Note that nullable types will change this.
    if (_isNull(subtype)) return true;
    // `FutureOr<P>` is a subtype match for `FutureOr<Q>` with respect to `L`
    // under constraints `C`:
    // - If `P` is a subtype match for `Q` with respect to `L` under constraints
    //   `C`.
    // TODO(paulberry): implement this case.
    // `FutureOr<P>` is a subtype match for `Q` with respect to `L` under
    // constraints `C0 + C1`:
    // - If `Future<P>` is a subtype match for `Q` with respect to `L` under
    //   constraints `C0`.
    // - And `P` is a subtype match for `Q` with respect to `L` under
    //   constraints `C1`.
    // TODO(paulberry): implement this case.
    // `P` is a subtype match for `FutureOr<Q>` with respect to `L` under
    // constraints `C`:
    // - If `P` is a subtype match for `Future<Q>` with respect to `L` under
    //   constraints `C`.
    // - Or `P` is not a subtype match for `Future<Q>` with respect to `L` under
    //   constraints `C`
    //   - And `P` is a subtype match for `Q` with respect to `L` under
    //     constraints `C`
    // TODO(paulberry): implement this case.
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
      return _isSubtypeMatch(subtype.parameter.bound, supertype);
    }
    if (subtype is InterfaceType && supertype is InterfaceType) {
      return _isInterfaceSubtypeMatch(subtype, supertype);
    }
    // A type `P` is a subtype match for `Function` with respect to `L` under no
    // constraints:
    // - If `P` implements a call method.
    // - Or if `P` is a function type.
    // TODO(paulberry): implement this case.
    // A type `P` is a subtype match for a type `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is an interface type which implements a call method of type `F`,
    //   and `F` is a subtype match for a type `Q` with respect to `L` under
    //   constraints `C`.
    // TODO(paulberry): implement this case.
    if (subtype is FunctionType) {
      if (supertype is InterfaceType) {
        if (identical(
                supertype.classNode, environment.coreTypes.functionClass) ||
            identical(supertype.classNode, environment.coreTypes.objectClass)) {
          return true;
        } else {
          return false;
        }
      }
      if (supertype is FunctionType) {
        return _isFunctionSubtypeMatch(subtype, supertype);
      }
    }
    return false;
  }

  bool _isTop(DartType type) =>
      type is DynamicType ||
      type is VoidType ||
      (type is InterfaceType &&
          identical(type.classNode, environment.coreTypes.objectClass));

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
      Map<TypeParameter, DartType> substitution2) {
    int count = params1.length;
    if (count != params2.length) return false;
    // TODO(paulberry): in imitation of analyzer, we're checking the bounds as
    // we build up the substitutions.  But I don't think that's correct--I think
    // we should build up both substitutions completely before checking any
    // bounds.  See dartbug.com/29629.
    for (int i = 0; i < count; i++) {
      TypeParameter pFresh = new TypeParameter(params2[i].name);
      DartType variableFresh = new TypeParameterType(pFresh);
      substitution1[params1[i]] = variableFresh;
      substitution2[params2[i]] = variableFresh;
      DartType bound1 = substitute(params1[i].bound, substitution1);
      DartType bound2 = substitute(params2[i].bound, substitution2);
      pFresh.bound = bound2;
      if (!_isSubtypeMatch(bound2, bound1)) return false;
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
  final TypeParameter parameter;

  final DartType bound;

  final bool isUpper;

  _ProtoConstraint.lower(this.parameter, this.bound) : isUpper = false;

  _ProtoConstraint.upper(this.parameter, this.bound) : isUpper = true;
}
