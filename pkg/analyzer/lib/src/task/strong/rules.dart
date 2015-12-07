// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this was ported from package:dev_compiler, and needs to be
// refactored to fit into analyzer.
library analyzer.src.task.strong.rules;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';

import 'info.dart';

// TODO(jmesserly): this entire file needs to be removed in favor of TypeSystem.

final _objectMap = new Expando('providerToObjectMap');
Map<String, DartType> getObjectMemberMap(TypeProvider typeProvider) {
  var map = _objectMap[typeProvider] as Map<String, DartType>;
  if (map == null) {
    map = <String, DartType>{};
    _objectMap[typeProvider] = map;
    var objectType = typeProvider.objectType;
    var element = objectType.element;
    // Only record methods (including getters) with no parameters.  As parameters are contravariant wrt
    // type, using Object's version may be too strict.
    // Add instance methods.
    element.methods.where((method) => !method.isStatic).forEach((method) {
      map[method.name] = method.type;
    });
    // Add getters.
    element.accessors
        .where((member) => !member.isStatic && member.isGetter)
        .forEach((member) {
      map[member.name] = member.type.returnType;
    });
  }
  return map;
}

class TypeRules {
  final TypeProvider provider;

  /// Map of fields / properties / methods on Object.
  final Map<String, DartType> objectMembers;

  DownwardsInference inferrer;

  TypeRules(TypeProvider provider)
      : provider = provider,
        objectMembers = getObjectMemberMap(provider) {
    inferrer = new DownwardsInference(this);
  }

  /// Given a type t, if t is an interface type with a call method
  /// defined, return the function type for the call method, otherwise
  /// return null.
  FunctionType getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      return t.lookUpMethod("call", null)?.type;
    }
    return null;
  }

  /// Given an expression, return its type assuming it is
  /// in the caller position of a call (that is, accounting
  /// for the possibility of a call method).  Returns null
  /// if expression is not statically callable.
  FunctionType getTypeAsCaller(Expression applicand) {
    var t = getStaticType(applicand);
    if (t is InterfaceType) {
      return getCallMethodType(t);
    }
    if (t is FunctionType) return t;
    return null;
  }

  /// Gets the expected return type of the given function [body], either from
  /// a normal return/yield, or from a yield*.
  DartType getExpectedReturnType(FunctionBody body, {bool yieldStar: false}) {
    FunctionType functionType;
    var parent = body.parent;
    if (parent is Declaration) {
      functionType = elementType(parent.element);
    } else {
      assert(parent is FunctionExpression);
      functionType = getStaticType(parent);
    }

    var type = functionType.returnType;

    InterfaceType expectedType = null;
    if (body.isAsynchronous) {
      if (body.isGenerator) {
        // Stream<T> -> T
        expectedType = provider.streamType;
      } else {
        // Future<T> -> T
        // TODO(vsm): Revisit with issue #228.
        expectedType = provider.futureType;
      }
    } else {
      if (body.isGenerator) {
        // Iterable<T> -> T
        expectedType = provider.iterableType;
      } else {
        // T -> T
        return type;
      }
    }
    if (yieldStar) {
      if (type.isDynamic) {
        // Ensure it's at least a Stream / Iterable.
        return expectedType.substitute4([provider.dynamicType]);
      } else {
        // Analyzer will provide a separate error if expected type
        // is not compatible with type.
        return type;
      }
    }
    if (type.isDynamic) {
      return type;
    } else if (type is InterfaceType && type.element == expectedType.element) {
      return type.typeArguments[0];
    } else {
      // Malformed type - fallback on analyzer error.
      return null;
    }
  }

  DartType getStaticType(Expression expr) {
    return expr.staticType ?? provider.dynamicType;
  }

  bool _isBottom(DartType t, {bool dynamicIsBottom: false}) {
    if (t.isDynamic && dynamicIsBottom) return true;
    // TODO(vsm): We need direct support for non-nullability in DartType.
    // This should check on "true/nonnullable" Bottom
    if (t.isBottom) return true;
    return false;
  }

  bool _isTop(DartType t, {bool dynamicIsBottom: false}) {
    if (t.isDynamic && !dynamicIsBottom) return true;
    if (t.isObject) return true;
    return false;
  }

  bool _anyParameterType(FunctionType ft, bool predicate(DartType t)) {
    return ft.normalParameterTypes.any(predicate) ||
        ft.optionalParameterTypes.any(predicate) ||
        ft.namedParameterTypes.values.any(predicate);
  }

  // TODO(leafp): Revisit this.
  bool isGroundType(DartType t) {
    if (t is TypeParameterType) return false;
    if (_isTop(t)) return true;

    if (t is FunctionType) {
      if (!_isTop(t.returnType) ||
          _anyParameterType(t, (pt) => !_isBottom(pt, dynamicIsBottom: true))) {
        return false;
      } else {
        return true;
      }
    }

    if (t is InterfaceType) {
      var typeArguments = t.typeArguments;
      for (var typeArgument in typeArguments) {
        if (!_isTop(typeArgument)) return false;
      }
      return true;
    }

    // We should not see any other type aside from malformed code.
    return false;
  }

  /// Check that f1 is a subtype of f2. [ignoreReturn] is used in the DDC
  /// checker to determine whether f1 would be a subtype of f2 if the return
  /// type of f1 is set to match f2's return type.
  // [fuzzyArrows] indicates whether or not the f1 and f2 should be
  // treated as fuzzy arrow types (and hence dynamic parameters to f2 treated as
  // bottom).
  bool isFunctionSubTypeOf(FunctionType f1, FunctionType f2,
      {bool fuzzyArrows: true, bool ignoreReturn: false}) {
    final r1s = f1.normalParameterTypes;
    final o1s = f1.optionalParameterTypes;
    final n1s = f1.namedParameterTypes;
    final r2s = f2.normalParameterTypes;
    final o2s = f2.optionalParameterTypes;
    final n2s = f2.namedParameterTypes;
    final ret1 = ignoreReturn ? f2.returnType : f1.returnType;
    final ret2 = f2.returnType;

    // A -> B <: C -> D if C <: A and
    // either D is void or B <: D
    if (!ret2.isVoid && !isSubTypeOf(ret1, ret2)) return false;

    // Reject if one has named and the other has optional
    if (n1s.length > 0 && o2s.length > 0) return false;
    if (n2s.length > 0 && o1s.length > 0) return false;

    // f2 has named parameters
    if (n2s.length > 0) {
      // Check that every named parameter in f2 has a match in f1
      for (String k2 in n2s.keys) {
        if (!n1s.containsKey(k2)) return false;
        if (!isSubTypeOf(n2s[k2], n1s[k2],
            dynamicIsBottom: fuzzyArrows)) return false;
      }
    }
    // If we get here, we either have no named parameters,
    // or else the named parameters match and we have no optional
    // parameters

    // If f1 has more required parameters, reject
    if (r1s.length > r2s.length) return false;

    // If f2 has more required + optional parameters, reject
    if (r2s.length + o2s.length > r1s.length + o1s.length) return false;

    // The parameter lists must look like the following at this point
    // where rrr is a region of required, and ooo is a region of optionals.
    // f1: rrr ooo ooo ooo
    // f2: rrr rrr ooo
    int rr = r1s.length; // required in both
    int or = r2s.length - r1s.length; // optional in f1, required in f2
    int oo = o2s.length; // optional in both

    for (int i = 0; i < rr; ++i) {
      if (!isSubTypeOf(r2s[i], r1s[i],
          dynamicIsBottom: fuzzyArrows)) return false;
    }
    for (int i = 0, j = rr; i < or; ++i, ++j) {
      if (!isSubTypeOf(r2s[j], o1s[i],
          dynamicIsBottom: fuzzyArrows)) return false;
    }
    for (int i = or, j = 0; i < oo; ++i, ++j) {
      if (!isSubTypeOf(o2s[j], o1s[i],
          dynamicIsBottom: fuzzyArrows)) return false;
    }
    return true;
  }

  bool _isInterfaceSubTypeOf(InterfaceType i1, InterfaceType i2) {
    if (i1 == i2) return true;

    if (i1.element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;

      // TODO(leafp): Verify that this is always true
      // Do raw types get filled in?
      assert(tArgs1.length == tArgs2.length);

      for (int i = 0; i < tArgs1.length; i++) {
        DartType t1 = tArgs1[i];
        DartType t2 = tArgs2[i];
        if (!isSubTypeOf(t1, t2)) return false;
      }
      return true;
    }

    if (i2.isDartCoreFunction) {
      if (i1.element.getMethod("call") != null) return true;
    }

    if (i1 == provider.objectType) return false;

    if (_isInterfaceSubTypeOf(i1.superclass, i2)) return true;

    for (final parent in i1.interfaces) {
      if (_isInterfaceSubTypeOf(parent, i2)) return true;
    }

    for (final parent in i1.mixins) {
      if (_isInterfaceSubTypeOf(parent, i2)) return true;
    }

    return false;
  }

  bool isSubTypeOf(DartType t1, DartType t2, {bool dynamicIsBottom: false}) {
    if (t1 == t2) return true;

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

    // The null type is a subtype of any nullable type, which is all Dart types.
    // TODO(vsm): Note, t1.isBottom still allows for null confusingly.
    // _isBottom(t1) does not necessarily imply t1.isBottom if there are
    // nonnullable types in the system.
    if (t1.isBottom) {
      return true;
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  S != T (handled above)
    //  So only true if bound of S is S' and
    //  S' <: T
    if (t1 is TypeParameterType) {
      DartType bound = t1.element.bound;
      if (bound == null) return false;
      return isSubTypeOf(bound, t2);
    }

    if (t2 is TypeParameterType) {
      return false;
    }

    if (t1.isVoid || t2.isVoid) {
      return false;
    }

    if (t2.isDartCoreFunction) {
      if (t1 is FunctionType) return true;
      if (t1.element is ClassElement) {
        if ((t1.element as ClassElement).getMethod("call") != null) return true;
      }
    }

    // "Traditional" name-based subtype check.
    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _isInterfaceSubTypeOf(t1, t2);
    }

    if (t1 is! FunctionType && t2 is! FunctionType) return false;

    if (t1 is InterfaceType && t2 is FunctionType) {
      var callType = getCallMethodType(t1);
      if (callType == null) return false;
      return isFunctionSubTypeOf(callType, t2);
    }

    if (t1 is FunctionType && t2 is InterfaceType) {
      return false;
    }

    // Functions
    // Note: it appears under the hood all Dart functions map to a class /
    // hidden type that:
    //  (a) subtypes Object (an internal _FunctionImpl in the VM)
    //  (b) implements Function
    //  (c) provides standard Object members (hashCode, toString)
    //  (d) contains private members (corresponding to _FunctionImpl?)
    //  (e) provides a call method to handle the actual function invocation
    //
    // The standard Dart subtyping rules are structural in nature.  I.e.,
    // bivariant on arguments and return type.
    //
    // The below tries for a more traditional subtyping rule:
    // - covariant on return type
    // - contravariant on parameters
    // - 'sensible' (?) rules on optional and/or named params
    // but doesn't properly mix with class subtyping.  I suspect Java 8 lambdas
    // essentially map to dynamic (and rely on invokedynamic) due to similar
    // issues.
    return isFunctionSubTypeOf(t1 as FunctionType, t2 as FunctionType);
  }

  bool isAssignable(DartType t1, DartType t2) {
    return isSubTypeOf(t1, t2);
  }

  // Produce a coercion which coerces something of type fromT
  // to something of type toT.
  // Returns the error coercion if the types cannot be coerced
  // according to our current criteria.
  Coercion _coerceTo(DartType fromT, DartType toT) {
    // We can use anything as void
    if (toT.isVoid) return Coercion.identity(toT);

    // fromT <: toT, no coercion needed
    if (isSubTypeOf(fromT, toT)) return Coercion.identity(toT);

    // TODO(vsm): We can get rid of the second clause if we disallow
    // all sideways casts - see TODO below.
    // -------
    // Note: a function type is never assignable to a class per the Dart
    // spec - even if it has a compatible call method.  We disallow as
    // well for consistency.
    if ((fromT is FunctionType && getCallMethodType(toT) != null) ||
        (toT is FunctionType && getCallMethodType(fromT) != null)) {
      return Coercion.error();
    }

    // Downcast if toT <: fromT
    if (isSubTypeOf(toT, fromT)) return Coercion.cast(fromT, toT);

    // TODO(vsm): Once we have generic methods, we should delete this
    // workaround.  These sideways casts are always ones we warn about
    // - i.e., we think they are likely to fail at runtime.
    // -------
    // Downcast if toT <===> fromT
    // The intention here is to allow casts that are sideways in the restricted
    // type system, but allowed in the regular dart type system, since these
    // are likely to succeed.  The canonical example is List<dynamic> and
    // Iterable<T> for some concrete T (e.g. Object).  These are unrelated
    // in the restricted system, but List<dynamic> <: Iterable<T> in dart.
    if (fromT.isAssignableTo(toT)) {
      return Coercion.cast(fromT, toT);
    }

    return Coercion.error();
  }

  StaticInfo checkAssignment(Expression expr, DartType toT) {
    final fromT = getStaticType(expr);
    final Coercion c = _coerceTo(fromT, toT);
    if (c is Identity) return null;
    if (c is CoercionError) return new StaticTypeError(this, expr, toT);
    var reason = null;

    var errors = <String>[];

    var ok = inferrer.inferExpression(expr, toT, errors);
    if (ok) return InferredType.create(this, expr, toT);
    reason = (errors.isNotEmpty) ? errors.first : null;

    if (c is Cast) return DownCast.create(this, expr, c, reason: reason);
    assert(false);
    return null;
  }

  DartType elementType(Element e) {
    if (e == null) {
      // Malformed code - just return dynamic.
      return provider.dynamicType;
    }
    return (e as dynamic).type;
  }

  bool _isLibraryPrefix(Expression node) =>
      node is SimpleIdentifier && node.staticElement is PrefixElement;

  /// Returns `true` if the target expression is dynamic.
  bool isDynamicTarget(Expression node) {
    if (node == null) return false;

    if (_isLibraryPrefix(node)) return false;

    // Null type happens when we have unknown identifiers, like a dart: import
    // that doesn't resolve.
    var type = node.staticType;
    return type == null || type.isDynamic;
  }

  /// Returns `true` if the expression is a dynamic function call or method
  /// invocation.
  bool isDynamicCall(Expression call) {
    var ft = getTypeAsCaller(call);
    // TODO(leafp): This will currently return true if t is Function
    // This is probably the most correct thing to do for now, since
    // this code is also used by the back end.  Maybe revisit at some
    // point?
    if (ft == null) return true;
    // Dynamic as the parameter type is treated as bottom.  A function with
    // a dynamic parameter type requires a dynamic call in general.
    // However, as an optimization, if we have an original definition, we know
    // dynamic is reified as Object - in this case a regular call is fine.
    if (call is SimpleIdentifier) {
      var element = call.staticElement;
      if (element is FunctionElement || element is MethodElement) {
        // An original declaration.
        return false;
      }
    }

    return _anyParameterType(ft, (pt) => pt.isDynamic);
  }
}

class DownwardsInference {
  final TypeRules rules;

  DownwardsInference(this.rules);

  /// Called for each list literal which gets inferred
  void annotateListLiteral(ListLiteral e, List<DartType> targs) {}

  /// Called for each map literal which gets inferred
  void annotateMapLiteral(MapLiteral e, List<DartType> targs) {}

  /// Called for each new/const which gets inferred
  void annotateInstanceCreationExpression(
      InstanceCreationExpression e, List<DartType> targs) {}

  /// Called for cast from dynamic required for inference to succeed
  void annotateCastFromDynamic(Expression e, DartType t) {}

  /// Called for each function expression return type inferred
  void annotateFunctionExpression(FunctionExpression e, DartType returnType) {}

  /// Downward inference
  bool inferExpression(Expression e, DartType t, List<String> errors) {
    // Don't cast top level expressions, only sub-expressions
    return _inferExpression(e, t, errors, cast: false);
  }

  /// Downward inference
  bool _inferExpression(Expression e, DartType t, List<String> errors,
      {cast: true}) {
    if (rules.isSubTypeOf(rules.getStaticType(e), t)) return true;
    if (cast && rules.getStaticType(e).isDynamic) {
      annotateCastFromDynamic(e, t);
      return true;
    }
    errors.add("$e cannot be typed as $t");
    return false;
  }
}
