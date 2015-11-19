// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.type_system;

import 'dart:collection';

import 'element.dart';
import 'engine.dart' show AnalysisContext;
import 'resolver.dart' show TypeProvider;

typedef bool _GuardedSubtypeChecker<T>(T t1, T t2, Set<Element> visited);

typedef bool _SubtypeChecker<T>(T t1, T t2);


/**
 * Implementation of [TypeSystem] using the strong mode rules.
 * https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md
 */
class StrongTypeSystemImpl implements TypeSystem {
  final _specTypeSystem = new TypeSystemImpl();

  StrongTypeSystemImpl();

  @override
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2) {
    // TODO(leafp): Implement a strong mode version of this.
    return _specTypeSystem.getLeastUpperBound(typeProvider, type1, type2);
  }

  // TODO(leafp): Document the rules in play here
  @override
  bool isAssignableTo(DartType fromType, DartType toType) {
    // An actual subtype
    if (isSubtypeOf(fromType, toType)) {
      return true;
    }

    // Don't allow implicit downcasts between function types
    // and call method objects, as these will almost always fail.
    if ((fromType is FunctionType && _getCallMethodType(toType) != null) ||
        (toType is FunctionType && _getCallMethodType(fromType) != null)) {
      return false;
    }

    // If the subtype relation goes the other way, allow the implicit downcast.
    // TODO(leafp): Emit warnings and hints for these in some way.
    // TODO(leafp): Consider adding a flag to disable these?  Or just rely on
    //   --warnings-as-errors?
    if (isSubtypeOf(toType, fromType) ||
        _specTypeSystem.isAssignableTo(toType, fromType)) {
      // TODO(leafp): error if type is known to be exact (literal,
      //  instance creation).
      // TODO(leafp): Warn on composite downcast.
      // TODO(leafp): hint on object/dynamic downcast.
      // TODO(leafp): Consider allowing assignment casts.
      return true;
    }

    return false;
  }

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return _isSubtypeOf(leftType, rightType, null);
  }

  FunctionType _getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      return t.lookUpInheritedMethod("call")?.type;
    }
    return null;
  }

  // Given a type t, if t is an interface type with a call method
  // defined, return the function type for the call method, otherwise
  // return null.
  _GuardedSubtypeChecker<DartType> _guard(
      _GuardedSubtypeChecker<DartType> check) {
    return (DartType t1, DartType t2, Set<Element> visited) {
      Element element = t1.element;
      if (visited == null) {
        visited = new HashSet<Element>();
      }
      if (element == null || !visited.add(element)) {
        return false;
      }
      try {
        return check(t1, t2, visited);
      } finally {
        visited.remove(element);
      }
    };
  }

  bool _isBottom(DartType t, {bool dynamicIsBottom: false}) {
    return (t.isDynamic && dynamicIsBottom) || t.isBottom;
  }

  // Guard against loops in the class hierarchy
  /**
   * Check that [f1] is a subtype of [f2].
   * [fuzzyArrows] indicates whether or not the f1 and f2 should be
   * treated as fuzzy arrow types (and hence dynamic parameters to f2 treated
   * as bottom).
   */
  bool _isFunctionSubtypeOf(FunctionType f1, FunctionType f2,
      {bool fuzzyArrows: true}) {
    final r1s = f1.normalParameterTypes;
    final o1s = f1.optionalParameterTypes;
    final n1s = f1.namedParameterTypes;
    final r2s = f2.normalParameterTypes;
    final o2s = f2.optionalParameterTypes;
    final n2s = f2.namedParameterTypes;
    final ret1 = f1.returnType;
    final ret2 = f2.returnType;

    // A -> B <: C -> D if C <: A and
    // either D is void or B <: D
    if (!ret2.isVoid && !isSubtypeOf(ret1, ret2)) {
      return false;
    }

    // Reject if one has named and the other has optional
    if (n1s.length > 0 && o2s.length > 0) {
      return false;
    }
    if (n2s.length > 0 && o1s.length > 0) {
      return false;
    }

    // Rebind _isSubtypeOf for convenience
    _SubtypeChecker<DartType> parameterSubtype = (DartType t1, DartType t2) =>
        _isSubtypeOf(t1, t2, null, dynamicIsBottom: fuzzyArrows);

    // f2 has named parameters
    if (n2s.length > 0) {
      // Check that every named parameter in f2 has a match in f1
      for (String k2 in n2s.keys) {
        if (!n1s.containsKey(k2)) {
          return false;
        }
        if (!parameterSubtype(n2s[k2], n1s[k2])) {
          return false;
        }
      }
    }
    // If we get here, we either have no named parameters,
    // or else the named parameters match and we have no optional
    // parameters

    // If f1 has more required parameters, reject
    if (r1s.length > r2s.length) {
      return false;
    }

    // If f2 has more required + optional parameters, reject
    if (r2s.length + o2s.length > r1s.length + o1s.length) {
      return false;
    }

    // The parameter lists must look like the following at this point
    // where rrr is a region of required, and ooo is a region of optionals.
    // f1: rrr ooo ooo ooo
    // f2: rrr rrr ooo
    int rr = r1s.length; // required in both
    int or = r2s.length - r1s.length; // optional in f1, required in f2
    int oo = o2s.length; // optional in both

    for (int i = 0; i < rr; ++i) {
      if (!parameterSubtype(r2s[i], r1s[i])) {
        return false;
      }
    }
    for (int i = 0, j = rr; i < or; ++i, ++j) {
      if (!parameterSubtype(r2s[j], o1s[i])) {
        return false;
      }
    }
    for (int i = or, j = 0; i < oo; ++i, ++j) {
      if (!parameterSubtype(o2s[j], o1s[i])) {
        return false;
      }
    }
    return true;
  }

  bool _isInterfaceSubtypeOf(
      InterfaceType i1, InterfaceType i2, Set<Element> visited) {
    // Guard recursive calls
    _GuardedSubtypeChecker<InterfaceType> guardedInterfaceSubtype =
        _guard(_isInterfaceSubtypeOf);

    if (i1 == i2) {
      return true;
    }

    if (i1.element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;

      assert(tArgs1.length == tArgs2.length);

      for (int i = 0; i < tArgs1.length; i++) {
        DartType t1 = tArgs1[i];
        DartType t2 = tArgs2[i];
        if (!isSubtypeOf(t1, t2)) {
          return false;
        }
      }
      return true;
    }

    if (i2.isDartCoreFunction && i1.element.getMethod("call") != null) {
      return true;
    }

    if (i1.isObject) {
      return false;
    }

    if (guardedInterfaceSubtype(i1.superclass, i2, visited)) {
      return true;
    }

    for (final parent in i1.interfaces) {
      if (guardedInterfaceSubtype(parent, i2, visited)) {
        return true;
      }
    }

    for (final parent in i1.mixins) {
      if (guardedInterfaceSubtype(parent, i2, visited)) {
        return true;
      }
    }

    return false;
  }

  bool _isSubtypeOf(DartType t1, DartType t2, Set<Element> visited,
      {bool dynamicIsBottom: false}) {
    // Guard recursive calls
    _GuardedSubtypeChecker<DartType> guardedSubtype = _guard(_isSubtypeOf);

    if (t1 == t2) {
      return true;
    }

    // The types are void, dynamic, bottom, interface types, function types
    // and type parameters.  We proceed by eliminating these different classes
    // from consideration.

    // Trivially true.
    if (_isTop(t2, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(t1, dynamicIsBottom: dynamicIsBottom)) {
      return true;
    }

    // Trivially false.
    if (_isTop(t1, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(t2, dynamicIsBottom: dynamicIsBottom)) {
      return false;
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  S != T (handled above)
    //  So only true if bound of S is S' and
    //  S' <: T
    if (t1 is TypeParameterType) {
      DartType bound = t1.element.bound;
      if (bound == null) return false;
      return guardedSubtype(bound, t2, visited);
    }

    if (t2 is TypeParameterType) {
      return false;
    }

    if (t1.isVoid || t2.isVoid) {
      return false;
    }

    // We've eliminated void, dynamic, bottom, and type parameters.  The only
    // cases are the combinations of interface type and function type.

    // A function type can only subtype an interface type if
    // the interface type is Function
    if (t1 is FunctionType && t2 is InterfaceType) {
      return t2.isDartCoreFunction;
    }

    // An interface type can only subtype a function type if
    // the interface type declares a call method with a type
    // which is a super type of the function type.
    if (t1 is InterfaceType && t2 is FunctionType) {
      var callType = _getCallMethodType(t1);
      return (callType != null) && _isFunctionSubtypeOf(callType, t2);
    }

    // Two interface types
    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _isInterfaceSubtypeOf(t1, t2, visited);
    }

    return _isFunctionSubtypeOf(t1 as FunctionType, t2 as FunctionType);
  }

  // TODO(leafp): Document the rules in play here
  bool _isTop(DartType t, {bool dynamicIsBottom: false}) {
    return (t.isDynamic && !dynamicIsBottom) || t.isObject;
  }
}


/**
 * The interface `TypeSystem` defines the behavior of an object representing
 * the type system.  This provides a common location to put methods that act on
 * types but may need access to more global data structures, and it paves the
 * way for a possible future where we may wish to make the type system
 * pluggable.
 */
abstract class TypeSystem {
  /**
   * Compute the least upper bound of two types.
   */
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2);

  /**
   * Return `true` if the [leftType] is assignable to the [rightType] (that is,
   * if leftType <==> rightType).
   */
  bool isAssignableTo(DartType leftType, DartType rightType);

  /**
   * Return `true` if the [leftType] is a subtype of the [rightType] (that is,
   * if leftType <: rightType).
   */
  bool isSubtypeOf(DartType leftType, DartType rightType);

  /**
   * Create either a strong mode or regular type system based on context.
   */
  static TypeSystem create(AnalysisContext context) {
    return (context.analysisOptions.strongMode)
        ? new StrongTypeSystemImpl()
        : new TypeSystemImpl();
  }
}

/**
 * Implementation of [TypeSystem] using the rules in the Dart specification.
 */
class TypeSystemImpl implements TypeSystem {
  TypeSystemImpl();

  @override
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2) {
    // The least upper bound relation is reflexive.
    if (identical(type1, type2)) {
      return type1;
    }
    // The least upper bound of dynamic and any type T is dynamic.
    if (type1.isDynamic) {
      return type1;
    }
    if (type2.isDynamic) {
      return type2;
    }
    // The least upper bound of void and any type T != dynamic is void.
    if (type1.isVoid) {
      return type1;
    }
    if (type2.isVoid) {
      return type2;
    }
    // The least upper bound of bottom and any type T is T.
    if (type1.isBottom) {
      return type2;
    }
    if (type2.isBottom) {
      return type1;
    }
    // Let U be a type variable with upper bound B.  The least upper bound of U
    // and a type T is the least upper bound of B and T.
    while (type1 is TypeParameterType) {
      // TODO(paulberry): is this correct in the complex of F-bounded
      // polymorphism?
      DartType bound = (type1 as TypeParameterType).element.bound;
      if (bound == null) {
        bound = typeProvider.objectType;
      }
      type1 = bound;
    }
    while (type2 is TypeParameterType) {
      // TODO(paulberry): is this correct in the context of F-bounded
      // polymorphism?
      DartType bound = (type2 as TypeParameterType).element.bound;
      if (bound == null) {
        bound = typeProvider.objectType;
      }
      type2 = bound;
    }
    // The least upper bound of a function type and an interface type T is the
    // least upper bound of Function and T.
    if (type1 is FunctionType && type2 is InterfaceType) {
      type1 = typeProvider.functionType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      type2 = typeProvider.functionType;
    }

    // At this point type1 and type2 should both either be interface types or
    // function types.
    if (type1 is InterfaceType && type2 is InterfaceType) {
      InterfaceType result =
          InterfaceTypeImpl.computeLeastUpperBound(type1, type2);
      if (result == null) {
        return typeProvider.dynamicType;
      }
      return result;
    } else if (type1 is FunctionType && type2 is FunctionType) {
      FunctionType result =
          FunctionTypeImpl.computeLeastUpperBound(type1, type2);
      if (result == null) {
        return typeProvider.functionType;
      }
      return result;
    } else {
      // Should never happen.  As a defensive measure, return the dynamic type.
      assert(false);
      return typeProvider.dynamicType;
    }
  }

  @override
  bool isAssignableTo(DartType leftType, DartType rightType) {
    return leftType.isAssignableTo(rightType);
  }

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return leftType.isSubtypeOf(rightType);
  }
}
