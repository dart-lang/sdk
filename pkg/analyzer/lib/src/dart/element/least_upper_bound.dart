// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/// The instantiation of a [ClassElement] with type arguments.
///
/// It is not a [DartType] itself, because it does not have nullability.
/// But it should be used where nullability does not make sense - to specify
/// superclasses, mixins, and implemented interfaces.
class InstantiatedClass {
  final ClassElement element;
  final List<DartType> arguments;

  final Substitution _substitution;

  InstantiatedClass(this.element, this.arguments)
      : _substitution = Substitution.fromPairs(
          element.typeParameters,
          arguments,
        );

  /// Return the [InstantiatedClass] that corresponds to the [type] - with the
  /// same element and type arguments, ignoring its nullability suffix.
  factory InstantiatedClass.of(InterfaceType type) {
    return InstantiatedClass(type.element, type.typeArguments);
  }

  @override
  int get hashCode {
    var hash = 0x3fffffff & element.hashCode;
    for (var i = 0; i < arguments.length; i++) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ arguments[i].hashCode));
    }
    return hash;
  }

  /// Return the interfaces that are directly implemented by this class.
  List<InstantiatedClass> get interfaces {
    var interfaces = element.interfaces;

    var result = List<InstantiatedClass>(interfaces.length);
    for (var i = 0; i < interfaces.length; i++) {
      var interface = interfaces[i];
      var substituted = _substitution.substituteType(interface);
      result[i] = InstantiatedClass.of(substituted);
    }

    return result;
  }

  /// Return `true` if this type represents the type 'Function' defined in the
  /// dart:core library.
  bool get isDartCoreFunction {
    return element.name == 'Function' && element.library.isDartCore;
  }

  /// Return the superclass of this type, or `null` if this type represents
  /// the class 'Object'.
  InstantiatedClass get superclass {
    var supertype = element.supertype;
    if (supertype == null) return null;

    supertype = _substitution.substituteType(supertype);
    return InstantiatedClass.of(supertype);
  }

  /// Return a list containing all of the superclass constraints defined for
  /// this class. The list will be empty if this class does not represent a
  /// mixin declaration. If this class _does_ represent a mixin declaration but
  /// the declaration does not have an `on` clause, then the list will contain
  /// the type for the class `Object`.
  List<InstantiatedClass> get superclassConstraints {
    var constraints = element.superclassConstraints;

    var result = List<InstantiatedClass>(constraints.length);
    for (var i = 0; i < constraints.length; i++) {
      var constraint = constraints[i];
      var substituted = _substitution.substituteType(constraint);
      result[i] = InstantiatedClass.of(substituted);
    }

    return result;
  }

  @visibleForTesting
  InterfaceType get withNullabilitySuffixNone {
    return withNullability(NullabilitySuffix.none);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is InstantiatedClass) {
      if (element != other.element) return false;
      if (arguments.length != other.arguments.length) return false;
      for (var i = 0; i < arguments.length; i++) {
        if (arguments[i] != other.arguments[i]) return false;
      }
      return true;
    }
    return false;
  }

  InstantiatedClass mapArguments(DartType Function(DartType) f) {
    var mappedArguments = arguments.map(f).toList();
    return InstantiatedClass(element, mappedArguments);
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write(element.name);
    if (arguments.isNotEmpty) {
      buffer.write('<');
      buffer.write(arguments.join(', '));
      buffer.write('>');
    }
    return buffer.toString();
  }

  InterfaceType withNullability(NullabilitySuffix nullability) {
    return InterfaceTypeImpl(
      element: element,
      typeArguments: arguments,
      nullabilitySuffix: nullability,
    );
  }
}

class InterfaceLeastUpperBoundHelper {
  final TypeSystemImpl typeSystem;

  InterfaceLeastUpperBoundHelper(this.typeSystem);

  /// This currently does not implement a very complete least upper bound
  /// algorithm, but handles a couple of the very common cases that are
  /// causing pain in real code.  The current algorithm is:
  /// 1. If either of the types is a supertype of the other, return it.
  ///    This is in fact the best result in this case.
  /// 2. If the two types have the same class element and are implicitly or
  ///    explicitly covariant, then take the pointwise least upper bound of
  ///    the type arguments. This is again the best result, except that the
  ///    recursive calls may not return the true least upper bounds. The
  ///    result is guaranteed to be a well-formed type under the assumption
  ///    that the input types were well-formed (and assuming that the
  ///    recursive calls return well-formed types).
  ///    If the variance of the type parameter is contravariant, we take the
  ///    greatest lower bound of the type arguments. If the variance of the
  ///    type parameter is invariant, we verify if the type arguments satisfy
  ///    subtyping in both directions, then choose a bound.
  /// 3. Otherwise return the spec-defined least upper bound.  This will
  ///    be an upper bound, might (or might not) be least, and might
  ///    (or might not) be a well-formed type.
  ///
  /// TODO(leafp): Use matchTypes or something similar here to handle the
  ///  case where one of the types is a superclass (but not supertype) of
  ///  the other, e.g. LUB(Iterable<double>, List<int>) = Iterable<num>
  /// TODO(leafp): Figure out the right final algorithm and implement it.
  InterfaceTypeImpl compute(InterfaceTypeImpl type1, InterfaceTypeImpl type2) {
    var nullability = _chooseNullability(type1, type2);

    // Strip off nullability.
    type1 = type1.withNullability(NullabilitySuffix.none);
    type2 = type2.withNullability(NullabilitySuffix.none);

    if (typeSystem.isSubtypeOf2(type1, type2)) {
      return type2.withNullability(nullability);
    }
    if (typeSystem.isSubtypeOf2(type2, type1)) {
      return type1.withNullability(nullability);
    }

    if (type1.element == type2.element) {
      var args1 = type1.typeArguments;
      var args2 = type2.typeArguments;
      var params = type1.element.typeParameters;
      assert(args1.length == args2.length);
      assert(args1.length == params.length);

      var args = List<DartType>(args1.length);
      for (int i = 0; i < args1.length; i++) {
        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        Variance parameterVariance =
            (params[i] as TypeParameterElementImpl).variance;
        if (parameterVariance.isCovariant) {
          args[i] = typeSystem.getLeastUpperBound(args1[i], args2[i]);
        } else if (parameterVariance.isContravariant) {
          if (typeSystem is TypeSystemImpl) {
            args[i] = typeSystem.getGreatestLowerBound(args1[i], args2[i]);
          } else {
            args[i] = typeSystem.getLeastUpperBound(args1[i], args2[i]);
          }
        } else if (parameterVariance.isInvariant) {
          if (!typeSystem.isSubtypeOf2(args1[i], args2[i]) ||
              !typeSystem.isSubtypeOf2(args2[i], args1[i])) {
            // No bound will be valid, find bound at the interface level.
            return _computeLeastUpperBound(
              InstantiatedClass.of(type1),
              InstantiatedClass.of(type2),
            ).withNullability(nullability);
          }
          // TODO (kallentu) : Fix asymmetric bounds behavior for invariant type
          //  parameters.
          args[i] = args1[i];
        } else {
          throw StateError('Type parameter ${params[i]} has unknown '
              'variance $parameterVariance for bounds calculation.');
        }
      }

      return InterfaceTypeImpl(
        element: type1.element,
        typeArguments: args,
        nullabilitySuffix: nullability,
      );
    }

    var result = _computeLeastUpperBound(
      InstantiatedClass.of(type1),
      InstantiatedClass.of(type2),
    );
    return result.withNullability(nullability);
  }

  /// Return all of the superinterfaces of the given [type].
  @visibleForTesting
  Set<InstantiatedClass> computeSuperinterfaceSet(InstantiatedClass type) {
    var result = <InstantiatedClass>{};
    _addSuperinterfaces(result, type);
    if (typeSystem.isNonNullableByDefault) {
      return result;
    } else {
      return result.map((e) {
        return e.mapArguments(typeSystem.toLegacyType);
      }).toSet();
    }
  }

  /// Compute the least upper bound of types [i] and [j], both of which are
  /// known to be interface types.
  ///
  /// In the event that the algorithm fails (which might occur due to a bug in
  /// the analyzer), `null` is returned.
  InstantiatedClass _computeLeastUpperBound(
    InstantiatedClass i,
    InstantiatedClass j,
  ) {
    // compute set of supertypes
    var si = computeSuperinterfaceSet(i);
    var sj = computeSuperinterfaceSet(j);

    // union si with i and sj with j
    si.add(i);
    sj.add(j);

    // compute intersection, reference as set 's'
    var s = _intersection(si, sj);
    return _computeTypeAtMaxUniqueDepth(s);
  }

  /// Return the length of the longest inheritance path from the [element] to
  /// Object.
  @visibleForTesting
  static int computeLongestInheritancePathToObject(ClassElement element) {
    return _computeLongestInheritancePathToObject(
      element,
      0,
      <ClassElement>{},
    );
  }

  /// Add all of the superinterfaces of the given [type] to the given [set].
  static void _addSuperinterfaces(
      Set<InstantiatedClass> set, InstantiatedClass type) {
    for (var interface in type.interfaces) {
      if (!interface.isDartCoreFunction) {
        if (set.add(interface)) {
          _addSuperinterfaces(set, interface);
        }
      }
    }

    for (var constraint in type.superclassConstraints) {
      if (!constraint.isDartCoreFunction) {
        if (set.add(constraint)) {
          _addSuperinterfaces(set, constraint);
        }
      }
    }

    var supertype = type.superclass;
    if (supertype != null && !supertype.isDartCoreFunction) {
      if (set.add(supertype)) {
        _addSuperinterfaces(set, supertype);
      }
    }
  }

  static NullabilitySuffix _chooseNullability(
    InterfaceTypeImpl type1,
    InterfaceTypeImpl type2,
  ) {
    var nullability1 = type1.nullabilitySuffix;
    var nullability2 = type2.nullabilitySuffix;
    if (nullability1 == NullabilitySuffix.question ||
        nullability2 == NullabilitySuffix.question) {
      return NullabilitySuffix.question;
    } else if (nullability1 == NullabilitySuffix.star ||
        nullability2 == NullabilitySuffix.star) {
      return NullabilitySuffix.star;
    }
    return NullabilitySuffix.none;
  }

  /// Return the length of the longest inheritance path from a subtype of the
  /// given [element] to Object, where the given [depth] is the length of the
  /// longest path from the subtype to this type. The set of [visitedElements]
  /// is used to prevent infinite recursion in the case of a cyclic type
  /// structure.
  static int _computeLongestInheritancePathToObject(
      ClassElement element, int depth, Set<ClassElement> visitedElements) {
    // Object case
    if (element.isDartCoreObject || visitedElements.contains(element)) {
      return depth;
    }
    int longestPath = 1;
    try {
      visitedElements.add(element);
      int pathLength;

      // loop through each of the superinterfaces recursively calling this
      // method and keeping track of the longest path to return
      for (InterfaceType interface in element.superclassConstraints) {
        pathLength = _computeLongestInheritancePathToObject(
            interface.element, depth + 1, visitedElements);
        if (pathLength > longestPath) {
          longestPath = pathLength;
        }
      }

      // loop through each of the superinterfaces recursively calling this
      // method and keeping track of the longest path to return
      for (InterfaceType interface in element.interfaces) {
        pathLength = _computeLongestInheritancePathToObject(
            interface.element, depth + 1, visitedElements);
        if (pathLength > longestPath) {
          longestPath = pathLength;
        }
      }

      // finally, perform this same check on the super type
      // TODO(brianwilkerson) Does this also need to add in the number of mixin
      // classes?
      InterfaceType supertype = element.supertype;
      if (supertype != null) {
        pathLength = _computeLongestInheritancePathToObject(
            supertype.element, depth + 1, visitedElements);
        if (pathLength > longestPath) {
          longestPath = pathLength;
        }
      }
    } finally {
      visitedElements.remove(element);
    }
    return longestPath;
  }

  /// Return the type from the [types] list that has the longest inheritance
  /// path to Object of unique length.
  static InstantiatedClass _computeTypeAtMaxUniqueDepth(
    List<InstantiatedClass> types,
  ) {
    // for each element in Set s, compute the largest inheritance path to Object
    List<int> depths = List<int>.filled(types.length, 0);
    int maxDepth = 0;
    for (int i = 0; i < types.length; i++) {
      depths[i] = computeLongestInheritancePathToObject(types[i].element);
      if (depths[i] > maxDepth) {
        maxDepth = depths[i];
      }
    }
    // ensure that the currently computed maxDepth is unique,
    // otherwise, decrement and test for uniqueness again
    for (; maxDepth >= 0; maxDepth--) {
      int indexOfLeastUpperBound = -1;
      int numberOfTypesAtMaxDepth = 0;
      for (int m = 0; m < depths.length; m++) {
        if (depths[m] == maxDepth) {
          numberOfTypesAtMaxDepth++;
          indexOfLeastUpperBound = m;
        }
      }
      if (numberOfTypesAtMaxDepth == 1) {
        return types[indexOfLeastUpperBound];
      }
    }
    // Should be impossible--there should always be exactly one type with the
    // maximum depth.
    assert(false);
    return null;
  }

  /// Return the intersection of the [first] and [second] sets of types, where
  /// intersection is based on the equality of the types themselves.
  static List<InstantiatedClass> _intersection(
    Set<InstantiatedClass> first,
    Set<InstantiatedClass> second,
  ) {
    var result = first.toSet();
    result.retainAll(second);
    return result.toList();
  }
}

class LeastUpperBoundHelper {
  final TypeSystemImpl _typeSystem;

  LeastUpperBoundHelper(this._typeSystem);

  InterfaceType get _interfaceTypeFunctionNone {
    return _typeSystem.typeProvider.functionType.element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Compute the least upper bound of two types.
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/upper-lower-bounds.md`
  DartType getLeastUpperBound(DartType T1, DartType T2) {
    // UP(T, T) = T
    if (identical(T1, T2)) {
      return T1;
    }

    // For any type T, UP(?, T) == T.
    if (identical(T1, UnknownInferredType.instance)) {
      return T2;
    }
    if (identical(T2, UnknownInferredType.instance)) {
      return T1;
    }

    var T1_isTop = _typeSystem.isTop(T1);
    var T2_isTop = _typeSystem.isTop(T2);

    // UP(T1, T2) where TOP(T1) and TOP(T2)
    if (T1_isTop && T2_isTop) {
      // * T1 if MORETOP(T1, T2)
      // * T2 otherwise
      if (_typeSystem.isMoreTop(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    // UP(T1, T2) = T1 if TOP(T1)
    if (T1_isTop) {
      return T1;
    }

    // UP(T1, T2) = T2 if TOP(T2)
    if (T2_isTop) {
      return T2;
    }

    var T1_isBottom = _typeSystem.isBottom(T1);
    var T2_isBottom = _typeSystem.isBottom(T2);

    // UP(T1, T2) where BOTTOM(T1) and BOTTOM(T2)
    if (T1_isBottom && T2_isBottom) {
      // * T2 if MOREBOTTOM(T1, T2)
      // * T1 otherwise
      if (_typeSystem.isMoreBottom(T1, T2)) {
        return T2;
      } else {
        return T1;
      }
    }

    // UP(T1, T2) = T2 if BOTTOM(T1)
    if (T1_isBottom) {
      return T2;
    }

    // UP(T1, T2) = T1 if BOTTOM(T2)
    if (T2_isBottom) {
      return T1;
    }

    var T1_isNull = _typeSystem.isNull(T1);
    var T2_isNull = _typeSystem.isNull(T2);

    // UP(T1, T2) where NULL(T1) and NULL(T2)
    if (T1_isNull && T2_isNull) {
      // * T2 if MOREBOTTOM(T1, T2)
      // * T1 otherwise
      if (_typeSystem.isMoreBottom(T1, T2)) {
        return T2;
      } else {
        return T1;
      }
    }

    var T1_impl = T1 as TypeImpl;
    var T2_impl = T2 as TypeImpl;

    var T1_nullability = T1_impl.nullabilitySuffix;
    var T2_nullability = T2_impl.nullabilitySuffix;

    // UP(T1, T2) where NULL(T1)
    if (T1_isNull) {
      // * T2 if T2 is nullable
      // * T2* if Null <: T2 or T1 <: Object (that is, T1 or T2 is legacy)
      // * T2? otherwise
      if (_typeSystem.isNullable(T2)) {
        return T2;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        return T2_impl.withNullability(NullabilitySuffix.star);
      } else {
        return _typeSystem.makeNullable(T2);
      }
    }

    // UP(T1, T2) where NULL(T2)
    if (T2_isNull) {
      // * T1 if T1 is nullable
      // * T1* if Null <: T1 or T2 <: Object (that is, T1 or T2 is legacy)
      // * T1? otherwise
      if (_typeSystem.isNullable(T1)) {
        return T1;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        return T1_impl.withNullability(NullabilitySuffix.star);
      } else {
        return _typeSystem.makeNullable(T1);
      }
    }

    var T1_isObject = _typeSystem.isObject(T1);
    var T2_isObject = _typeSystem.isObject(T2);

    // UP(T1, T2) where OBJECT(T1) and OBJECT(T2)
    if (T1_isObject && T2_isObject) {
      // * T1 if MORETOP(T1, T2)
      // * T2 otherwise
      if (_typeSystem.isMoreTop(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    // UP(T1, T2) where OBJECT(T1)
    if (T1_isObject) {
      // * T1 if T2 is non-nullable
      // * T1? otherwise
      if (_typeSystem.isNonNullable(T2)) {
        return T1;
      } else {
        return _typeSystem.makeNullable(T1);
      }
    }

    // UP(T1, T2) where OBJECT(T2)
    if (T2_isObject) {
      // * T2 if T1 is non-nullable
      // * T2? otherwise
      if (_typeSystem.isNonNullable(T1)) {
        return T2;
      } else {
        return _typeSystem.makeNullable(T2);
      }
    }

    // UP(T1*, T2*) = S* where S is UP(T1, T2)
    // UP(T1*, T2?) = S? where S is UP(T1, T2)
    // UP(T1?, T2*) = S? where S is UP(T1, T2)
    // UP(T1*, T2) = S* where S is UP(T1, T2)
    // UP(T1, T2*) = S* where S is UP(T1, T2)
    // UP(T1?, T2?) = S? where S is UP(T1, T2)
    // UP(T1?, T2) = S? where S is UP(T1, T2)
    // UP(T1, T2?) = S? where S is UP(T1, T2)
    if (T1_nullability != NullabilitySuffix.none ||
        T2_nullability != NullabilitySuffix.none) {
      var resultNullability = NullabilitySuffix.none;
      if (T1_nullability == NullabilitySuffix.question ||
          T2_nullability == NullabilitySuffix.question) {
        resultNullability = NullabilitySuffix.question;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        resultNullability = NullabilitySuffix.star;
      }
      var T1_none = T1_impl.withNullability(NullabilitySuffix.none);
      var T2_none = T2_impl.withNullability(NullabilitySuffix.none);
      var S = getLeastUpperBound(T1_none, T2_none);
      return (S as TypeImpl).withNullability(resultNullability);
    }

    assert(T1_nullability == NullabilitySuffix.none);
    assert(T2_nullability == NullabilitySuffix.none);

    // UP(X1 extends B1, T2)
    // UP(X1 & B1, T2)
    if (T1 is TypeParameterType) {
      // T2 if X1 <: T2
      if (_typeSystem.isSubtypeOf2(T1, T2)) {
        return T2;
      }
      // otherwise X1 if T2 <: X1
      if (_typeSystem.isSubtypeOf2(T2, T1)) {
        return T1;
      }
      // otherwise UP(B1[Object/X1], T2)
      var T1_toObject = _typeParameterResolveToObjectBounds(T1);
      return getLeastUpperBound(T1_toObject, T2);
    }

    // UP(T1, X2 extends B2)
    // UP(T1, X2 & B2)
    if (T2 is TypeParameterType) {
      // X2 if T1 <: X2
      if (_typeSystem.isSubtypeOf2(T1, T2)) {
        // TODO(scheglov) How to get here?
        return T2;
      }
      // otherwise T1 if X2 <: T1
      if (_typeSystem.isSubtypeOf2(T2, T1)) {
        return T1;
      }
      // otherwise UP(T1, B2[Object/X2])
      var T2_toObject = _typeParameterResolveToObjectBounds(T2);
      return getLeastUpperBound(T1, T2_toObject);
    }

    // UP(T Function<...>(...), Function) = Function
    if (T1 is FunctionType && T2.isDartCoreFunction) {
      return T2;
    }

    // UP(Function, T Function<...>(...)) = Function
    if (T1.isDartCoreFunction && T2 is FunctionType) {
      return T1;
    }

    // UP(T Function<...>(...), S Function<...>(...)) = Function
    // And other, more interesting variants.
    if (T1 is FunctionType && T2 is FunctionType) {
      return _functionType(T1, T2);
    }

    // UP(T Function<...>(...), T2) = Object
    // UP(T1, T Function<...>(...)) = Object
    if (T1 is FunctionType || T2 is FunctionType) {
      return _typeSystem.objectNone;
    }

    // UP(T1, T2) = T2 if T1 <: T2
    // UP(T1, T2) = T1 if T2 <: T1
    // And other, more complex variants of interface types.
    var helper = InterfaceLeastUpperBoundHelper(_typeSystem);
    return helper.compute(T1, T2);
  }

  /// Compute the least upper bound of function types [f] and [g].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/upper-lower-bounds.md`
  DartType _functionType(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // The number of type parameters must be the same.
    // Otherwise the result is `Function`.
    if (fTypeFormals.length != gTypeFormals.length) {
      return _interfaceTypeFunctionNone;
    }

    // The bounds of type parameters must be equal.
    // Otherwise the result is `Function`.
    var freshTypeFormalTypes =
        FunctionTypeImpl.relateTypeFormals(f, g, (t, s, _, __) => t == s);
    if (freshTypeFormalTypes == null) {
      return _interfaceTypeFunctionNone;
    }

    var typeFormals = freshTypeFormalTypes
        .map<TypeParameterElement>((t) => t.element)
        .toList();

    f = f.instantiate(freshTypeFormalTypes);
    g = g.instantiate(freshTypeFormalTypes);

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    var parameters = <ParameterElement>[];
    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isRequiredPositional) {
        if (gParameter.isRequiredPositional) {
          fIndex++;
          gIndex++;
          parameters.add(
            fParameter.copyWith(
              type: _parameterType(fParameter, gParameter),
            ),
          );
        } else {
          break;
        }
      } else if (fParameter.isOptionalPositional) {
        if (gParameter.isOptionalPositional) {
          fIndex++;
          gIndex++;
          parameters.add(
            fParameter.copyWith(
              type: _parameterType(fParameter, gParameter),
            ),
          );
        } else {
          break;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            fIndex++;
            gIndex++;
            parameters.add(
              fParameter.copyWith(
                type: _parameterType(fParameter, gParameter),
                kind: fParameter.isRequiredNamed || gParameter.isRequiredNamed
                    ? ParameterKind.NAMED_REQUIRED
                    : ParameterKind.NAMED,
              ),
            );
          } else if (compareNames < 0) {
            if (fParameter.isRequiredNamed) {
              // We cannot skip required named.
              return _interfaceTypeFunctionNone;
            } else {
              fIndex++;
            }
          } else {
            assert(compareNames > 0);
            if (gParameter.isRequiredNamed) {
              // We cannot skip required named.
              return _interfaceTypeFunctionNone;
            } else {
              gIndex++;
            }
          }
        } else {
          break;
        }
      }
    }

    while (fIndex < fParameters.length) {
      var fParameter = fParameters[fIndex++];
      if (fParameter.isNotOptional) {
        return _interfaceTypeFunctionNone;
      }
    }

    while (gIndex < gParameters.length) {
      var gParameter = gParameters[gIndex++];
      if (gParameter.isNotOptional) {
        return _interfaceTypeFunctionNone;
      }
    }

    var returnType = getLeastUpperBound(f.returnType, g.returnType);

    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType _parameterType(ParameterElement a, ParameterElement b) {
    return _typeSystem.getGreatestLowerBound(a.type, b.type);
  }

  /// TODO(scheglov) Use greatest closure.
  /// See https://github.com/dart-lang/language/pull/1195
  DartType _typeParameterResolveToObjectBounds(DartType type) {
    var element = type.element;

    var objectType = _typeSystem.isNonNullableByDefault
        ? _typeSystem.objectQuestion
        : _typeSystem.objectStar;

    type = type.resolveToBound(objectType);
    return Substitution.fromMap({element: objectType}).substituteType(type);
  }
}
