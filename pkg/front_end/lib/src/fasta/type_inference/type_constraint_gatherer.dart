// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';

/// Attempts to find a set of constraints for the given [typeParameters] under
/// which [subtype] is a subtype of [supertype].  If such a set can be found, it
/// is returned (as a map from type parameter to constraint).  If it can't,
/// `null` is returned.
Map<TypeParameter, TypeConstraint> subtypeMatch(
    TypeSchemaEnvironment environment,
    Iterable<TypeParameter> typeParameters,
    DartType subtype,
    DartType supertype) {
  var typeConstraintGatherer =
      new _TypeConstraintGatherer(environment, typeParameters);
  if (typeConstraintGatherer.isSubtypeMatch(subtype, supertype)) {
    return typeConstraintGatherer.computeConstraints();
  } else {
    return null;
  }
}

class _ProtoConstraint {
  final TypeParameter parameter;

  final DartType bound;

  final bool isUpper;

  _ProtoConstraint.lower(this.parameter, this.bound) : isUpper = false;

  _ProtoConstraint.upper(this.parameter, this.bound) : isUpper = true;
}

/// Creates a collection of [TypeConstraint]s corresponding to type parameters,
/// based on an attempt to make one type schema a subtype of another.
class _TypeConstraintGatherer {
  final TypeSchemaEnvironment environment;

  final _protoConstraints = <_ProtoConstraint>[];

  final List<TypeParameter> _parametersToConstrain;

  /// Creates a [TypeConstraintGatherer] which is prepared to gather type
  /// constraints for the given [typeParameters].
  _TypeConstraintGatherer(
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

  /// Attempts to match [subtype] as a subtype of [supertype], gathering any
  /// constraints discovered in the process.  If a set of constraints was found,
  /// `true` is returned and the caller may proceed to call
  /// [computeConstraints].  Otherwise, `false` is returned and the set of
  /// gathered constraints is undefined.
  bool isSubtypeMatch(DartType subtype, DartType supertype) {
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
      return isSubtypeMatch(subtype.parameter.bound, supertype);
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
    // TODO(paulberry): implement this case.
    // A generic function type `<T0 extends B0, ..., Tn extends Bn>F0` is a
    // subtype match for a generic function type `<S0 extends B0, ..., Sn
    // extends Bn>F1` with respect to `L` under constraints `Cl`:
    // - If `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for `F0[Z0/S0, ...,
    //   Zn/Sn]` with respect to `L` under constraints `C`, where each `Zi` is a
    //   fresh type variable with bound `Bi`.
    // - And `Cl` is `C` with each constraint replaced with its closure with
    //   respect to `[Z0, ..., Zn]`.
    // TODO(paulberry): implement this case.
    return false;
  }

  void _constrainLower(TypeParameter parameter, DartType lower) {
    _protoConstraints.add(new _ProtoConstraint.lower(parameter, lower));
  }

  void _constrainUpper(TypeParameter parameter, DartType upper) {
    _protoConstraints.add(new _ProtoConstraint.upper(parameter, upper));
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
      if (!isSubtypeMatch(matchingSupertypeOfSubtype.typeArguments[i],
          supertype.typeArguments[i])) {
        return false;
      }
    }
    return true;
  }

  bool _isNull(DartType type) =>
      type is InterfaceType &&
      identical(type.classNode, environment.coreTypes.nullClass);

  bool _isTop(DartType type) =>
      type is DynamicType ||
      type is VoidType ||
      (type is InterfaceType &&
          identical(type.classNode, environment.coreTypes.objectClass));
}
