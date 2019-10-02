// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:math' as math;

import 'package:kernel/ast.dart'
    show
        BottomType,
        Class,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        InvalidType,
        NamedType,
        Nullability,
        TypeParameterType,
        VoidType;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import 'type_schema.dart' show UnknownType;

abstract class StandardBounds {
  Class get functionClass;
  Class get futureClass;
  Class get futureOrClass;
  InterfaceType get nullType;
  InterfaceType get objectLegacyRawType;
  InterfaceType get functionLegacyRawType;

  bool isSubtypeOf(DartType subtype, DartType supertype, SubtypeCheckMode mode);

  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2);

  /// Computes the standard lower bound of [type1] and [type2].
  ///
  /// Standard lower bound is a lower bound function that imposes an
  /// ordering on the top types `void`, `dynamic`, and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardLowerBound(DartType type1, DartType type2) {
    // For all types T, SLB(T,T) = T.  Note that we don't test for equality
    // because we don't want to make the algorithm quadratic.  This is ok
    // because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, SLB(?, T) = SLB(T, ?) = T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }

    // SLB(void, T) = SLB(T, void) = T.
    if (type1 is VoidType) {
      return type2;
    }
    if (type2 is VoidType) {
      return type1;
    }

    // SLB(dynamic, T) = SLB(T, dynamic) = T if T is not void.
    if (type1 is DynamicType) {
      return type2;
    }
    if (type2 is DynamicType) {
      return type1;
    }

    // SLB(Object, T) = SLB(T, Object) = T if T is not void or dynamic.
    if (type1 == objectLegacyRawType) {
      return type2;
    }
    if (type2 == objectLegacyRawType) {
      return type1;
    }

    // SLB(bottom, T) = SLB(T, bottom) = bottom.
    if (type1 is BottomType) return type1;
    if (type2 is BottomType) return type2;
    if (type1 == nullType) return type1;
    if (type2 == nullType) return type2;

    // Function types have structural lower bounds.
    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionStandardLowerBound(type1, type2);
    }

    // Otherwise, the lower bounds  of two types is one of them it if it is a
    // subtype of the other.
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.ignoringNullabilities)) {
      return type1;
    }

    if (isSubtypeOf(type2, type1, SubtypeCheckMode.ignoringNullabilities)) {
      return type2;
    }

    // See https://github.com/dart-lang/sdk/issues/37439#issuecomment-519654959.
    if (type1 is InterfaceType && type1.classNode == futureOrClass) {
      if (type2 is InterfaceType) {
        if (type2.classNode == futureOrClass) {
          // GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>
          return new InterfaceType(futureOrClass, <DartType>[
            getStandardLowerBound(
                type1.typeArguments[0], type2.typeArguments[0])
          ]);
        }
        if (type2.classNode == futureClass) {
          // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
          return new InterfaceType(futureClass, <DartType>[
            getStandardLowerBound(
                type1.typeArguments[0], type2.typeArguments[0])
          ]);
        }
      }
      // GLB(FutureOr<A>, B) == GLB(A, B)
      return getStandardLowerBound(type1.typeArguments[0], type2);
    }
    // The if-statement below handles the following rule:
    //     GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)
    // It's broken down into sub-cases instead of making a recursive call to
    // avoid making the checks that were already made above.  Note that at this
    // point it's not possible for type1 to be a FutureOr.
    if (type2 is InterfaceType && type2.classNode == futureOrClass) {
      if (type1 is InterfaceType && type1.classNode == futureClass) {
        // GLB(Future<A>, FutureOr<B>) == Future<GLB(B, A)>
        return new InterfaceType(futureClass, <DartType>[
          getStandardLowerBound(type2.typeArguments[0], type1.typeArguments[0])
        ]);
      }
      // GLB(A, FutureOr<B>) == GLB(B, A)
      return getStandardLowerBound(type2.typeArguments[0], type1);
    }

    // No subtype relation, so the lower bound is bottom.
    return const BottomType();
  }

  /// Computes the standard upper bound of two types.
  ///
  /// Standard upper bound is an upper bound function that imposes an ordering
  /// on the top types 'void', 'dynamic', and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardUpperBound(DartType type1, DartType type2) {
    // For all types T, SUB(T,T) = T.  Note that we don't test for equality
    // because we don't want to make the algorithm quadratic.  This is ok
    // because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, SUB(?, T) = SUB(T, ?) = T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }

    // SUB(void, T) = SUB(T, void) = void.
    if (type1 is VoidType) {
      return type1;
    }
    if (type2 is VoidType) {
      return type2;
    }

    // SUB(dynamic, T) = SUB(T, dynamic) = dynamic if T is not void.
    if (type1 is DynamicType) {
      return type1;
    }
    if (type2 is DynamicType) {
      return type2;
    }

    // SUB(Object, T) = SUB(T, Object) = Object if T is not void or dynamic.
    if (type1 == objectLegacyRawType) {
      return type1;
    }
    if (type2 == objectLegacyRawType) {
      return type2;
    }

    // SUB(bottom, T) = SUB(T, bottom) = T.
    if (type1 is BottomType) return type2;
    if (type2 is BottomType) return type1;
    if (type1 == nullType) return type2;
    if (type2 == nullType) return type1;

    if (type1 is TypeParameterType || type2 is TypeParameterType) {
      return _typeParameterStandardUpperBound(type1, type2);
    }

    // The standard upper bound of a function type and an interface type T is
    // the standard upper bound of Function and T.
    if (type1 is FunctionType && type2 is InterfaceType) {
      type1 = functionLegacyRawType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      type2 = functionLegacyRawType;
    }

    // At this point type1 and type2 should both either be interface types or
    // function types.
    if (type1 is InterfaceType && type2 is InterfaceType) {
      return _interfaceStandardUpperBound(type1, type2);
    }

    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionStandardUpperBound(type1, type2);
    }

    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }

    // Should never happen. As a defensive measure, return the dynamic type.
    assert(false, "type1 = $type1; type2 = $type2");
    return const DynamicType();
  }

  /// Compute the standard lower bound of function types [f] and [g].
  ///
  /// The spec rules for SLB on function types, informally, are pretty simple:
  ///
  /// - If a parameter is required in both, it stays required.
  ///
  /// - If a positional parameter is optional or missing in one, it becomes
  ///   optional.  (This is because we're trying to build a function type which
  ///   is a subtype of both [f] and [g], meaning it accepts all possible inputs
  ///   that [f] and [g] accept.)
  ///
  /// - Named parameters are unioned together.
  ///
  /// - For any parameter that exists in both functions, use the SUB of them as
  ///   the resulting parameter type.
  ///
  /// - Use the SLB of their return types.
  DartType _functionStandardLowerBound(FunctionType f, FunctionType g) {
    // TODO(rnystrom,paulberry): Right now, this assumes f and g do not have any
    // type parameters. Revisit that in the presence of generic methods.

    // Calculate the SUB of each corresponding pair of parameters.
    int totalPositional =
        math.max(f.positionalParameters.length, g.positionalParameters.length);
    List<DartType> positionalParameters = new List<DartType>(totalPositional);
    for (int i = 0; i < totalPositional; i++) {
      if (i < f.positionalParameters.length) {
        DartType fType = f.positionalParameters[i];
        if (i < g.positionalParameters.length) {
          DartType gType = g.positionalParameters[i];
          positionalParameters[i] = getStandardUpperBound(fType, gType);
        } else {
          positionalParameters[i] = fType;
        }
      } else {
        positionalParameters[i] = g.positionalParameters[i];
      }
    }

    // Parameters that are required in both functions are required in the
    // result.  Parameters that are optional or missing in either end up
    // optional.
    int requiredParameterCount =
        math.min(f.requiredParameterCount, g.requiredParameterCount);
    bool hasPositional = requiredParameterCount < totalPositional;

    // Union the named parameters together.
    List<NamedType> namedParameters = [];
    {
      int i = 0;
      int j = 0;
      while (true) {
        if (i < f.namedParameters.length) {
          if (j < g.namedParameters.length) {
            String fName = f.namedParameters[i].name;
            String gName = g.namedParameters[j].name;
            int order = fName.compareTo(gName);
            if (order < 0) {
              namedParameters.add(f.namedParameters[i++]);
            } else if (order > 0) {
              namedParameters.add(g.namedParameters[j++]);
            } else {
              namedParameters.add(new NamedType(
                  fName,
                  getStandardUpperBound(f.namedParameters[i++].type,
                      g.namedParameters[j++].type)));
            }
          } else {
            namedParameters.addAll(f.namedParameters.skip(i));
            break;
          }
        } else {
          namedParameters.addAll(g.namedParameters.skip(j));
          break;
        }
      }
    }
    bool hasNamed = namedParameters.isNotEmpty;

    // Edge case. Dart does not support functions with both optional positional
    // and named parameters. If we would synthesize that, give up.
    if (hasPositional && hasNamed) return const BottomType();

    // Calculate the SLB of the return type.
    DartType returnType = getStandardLowerBound(f.returnType, g.returnType);
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  /// Compute the standard upper bound of function types [f] and [g].
  ///
  /// The rules for SUB on function types, informally, are pretty simple:
  ///
  /// - If the functions don't have the same number of required parameters,
  ///   always return `Function`.
  ///
  /// - Discard any optional named or positional parameters the two types do not
  ///   have in common.
  ///
  /// - Compute the SLB of each corresponding pair of parameter types, and the
  ///   SUB of the return types.  Return a function type with those types.
  DartType _functionStandardUpperBound(FunctionType f, FunctionType g) {
    // TODO(rnystrom): Right now, this assumes f and g do not have any type
    // parameters. Revisit that in the presence of generic methods.

    // If F and G differ in their number of required parameters, then the
    // standard upper bound of F and G is Function.
    // TODO(paulberry): We could do better here, e.g.:
    //   SUB(([int]) -> void, (int) -> void) = (int) -> void
    if (f.requiredParameterCount != g.requiredParameterCount) {
      return new InterfaceType(
          functionClass, const <DynamicType>[], Nullability.legacy);
    }
    int requiredParameterCount = f.requiredParameterCount;

    // Calculate the SLB of each corresponding pair of parameters.
    // Ignore any extra optional positional parameters if one has more than the
    // other.
    int totalPositional =
        math.min(f.positionalParameters.length, g.positionalParameters.length);
    List<DartType> positionalParameters = new List<DartType>(totalPositional);
    for (int i = 0; i < totalPositional; i++) {
      positionalParameters[i] = getStandardLowerBound(
          f.positionalParameters[i], g.positionalParameters[i]);
    }

    // Intersect the named parameters.
    List<NamedType> namedParameters = [];
    {
      int i = 0;
      int j = 0;
      while (true) {
        if (i < f.namedParameters.length) {
          if (j < g.namedParameters.length) {
            String fName = f.namedParameters[i].name;
            String gName = g.namedParameters[j].name;
            int order = fName.compareTo(gName);
            if (order < 0) {
              i++;
            } else if (order > 0) {
              j++;
            } else {
              namedParameters.add(new NamedType(
                  fName,
                  getStandardLowerBound(f.namedParameters[i++].type,
                      g.namedParameters[j++].type)));
            }
          } else {
            break;
          }
        } else {
          break;
        }
      }
    }

    // Calculate the SUB of the return type.
    DartType returnType = getStandardUpperBound(f.returnType, g.returnType);
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  DartType _interfaceStandardUpperBound(
      InterfaceType type1, InterfaceType type2) {
    // This currently does not implement a very complete standard upper bound
    // algorithm, but handles a couple of the very common cases that are
    // causing pain in real code.  The current algorithm is:
    // 1. If either of the types is a supertype of the other, return it.
    //    This is in fact the best result in this case.
    // 2. If the two types have the same class element, then take the
    //    pointwise standard upper bound of the type arguments.  This is again
    //    the best result, except that the recursive calls may not return
    //    the true standard upper bounds.  The result is guaranteed to be a
    //    well-formed type under the assumption that the input types were
    //    well-formed (and assuming that the recursive calls return
    //    well-formed types).
    // 3. Otherwise return the spec-defined standard upper bound.  This will
    //    be an upper bound, might (or might not) be least, and might
    //    (or might not) be a well-formed type.
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.ignoringNullabilities)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1, SubtypeCheckMode.ignoringNullabilities)) {
      return type1;
    }
    if (type1 is InterfaceType &&
        type2 is InterfaceType &&
        identical(type1.classNode, type2.classNode)) {
      List<DartType> tArgs1 = type1.typeArguments;
      List<DartType> tArgs2 = type2.typeArguments;

      assert(tArgs1.length == tArgs2.length);
      List<DartType> tArgs = new List(tArgs1.length);
      for (int i = 0; i < tArgs1.length; i++) {
        tArgs[i] = getStandardUpperBound(tArgs1[i], tArgs2[i]);
      }
      return new InterfaceType(type1.classNode, tArgs);
    }
    return getLegacyLeastUpperBound(type1, type2);
  }

  DartType _typeParameterStandardUpperBound(DartType type1, DartType type2) {
    // This currently just implements a simple standard upper bound to
    // handle some common cases.  It also avoids some termination issues
    // with the naive spec algorithm.  The standard upper bound of two types
    // (at least one of which is a type parameter) is computed here as:
    // 1. If either type is a supertype of the other, return it.
    // 2. If the first type is a type parameter, replace it with its bound,
    //    with recursive occurrences of itself replaced with Object.
    //    The second part of this should ensure termination.  Informally,
    //    each type variable instantiation in one of the arguments to the
    //    standard upper bound algorithm now strictly reduces the number
    //    of bound variables in scope in that argument position.
    // 3. If the second type is a type parameter, do the symmetric operation
    //    to #2.
    //
    // It's not immediately obvious why this is symmetric in the case that both
    // of them are type parameters.  For #1, symmetry holds since subtype
    // is antisymmetric.  For #2, it's clearly not symmetric if upper bounds of
    // bottom are allowed.  Ignoring this (for various reasons, not least
    // of which that there's no way to write it), there's an informal
    // argument (that might even be right) that you will always either
    // end up expanding both of them or else returning the same result no matter
    // which order you expand them in.  A key observation is that
    // identical(expand(type1), type2) => subtype(type1, type2)
    // and hence the contra-positive.
    //
    // TODO(leafp): Think this through and figure out what's the right
    // definition.  Be careful about termination.
    //
    // I suspect in general a reasonable algorithm is to expand the innermost
    // type variable first.  Alternatively, you could probably choose to treat
    // it as just an instance of the interface type upper bound problem, with
    // the "inheritance" chain extended by the bounds placed on the variables.
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.ignoringNullabilities)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1, SubtypeCheckMode.ignoringNullabilities)) {
      return type1;
    }
    if (type1 is TypeParameterType) {
      // TODO(paulberry): Analyzer collapses simple bounds in one step, i.e. for
      // C<T extends U, U extends List>, T gets resolved directly to List.  Do
      // we need to replicate that behavior?
      return getStandardUpperBound(
          Substitution.fromMap({type1.parameter: objectLegacyRawType})
              .substituteType(type1.parameter.bound),
          type2);
    } else if (type2 is TypeParameterType) {
      return getStandardUpperBound(
          type1,
          Substitution.fromMap({type2.parameter: objectLegacyRawType})
              .substituteType(type2.parameter.bound));
    } else {
      // We should only be called when at least one of the types is a
      // TypeParameterType
      assert(false);
      return const DynamicType();
    }
  }
}
