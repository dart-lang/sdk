// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.checker.rules;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';

import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/utils.dart' as utils;

abstract class TypeRules {
  final TypeProvider provider;
  LibraryInfo currentLibraryInfo = null;

  /// Map of fields / properties / methods on Object.
  final Map<String, DartType> objectMembers;

  TypeRules(TypeProvider provider)
      : provider = provider,
        objectMembers = utils.getObjectMemberMap(provider);

  MissingTypeReporter reportMissingType;

  bool isSubTypeOf(DartType t1, DartType t2);
  bool isAssignable(DartType t1, DartType t2);

  bool isGroundType(DartType t) => true;
  // TODO(vsm): The default implementation is not ignoring the return type,
  // only the restricted override is.
  bool isFunctionSubTypeOf(FunctionType f1, FunctionType f2,
          {bool fuzzyArrows: true, bool ignoreReturn: false}) =>
      isSubTypeOf(f1, f2);

  bool isBoolType(DartType t) => t == provider.boolType;
  bool isDoubleType(DartType t) => t == provider.doubleType;
  bool isIntType(DartType t) => t == provider.intType;
  bool isNumType(DartType t) => t == provider.intType.superclass;
  bool isStringType(DartType t) => t == provider.stringType;
  bool isNonNullableType(DartType t) => false;
  bool maybeNonNullableType(DartType t) => false;

  StaticInfo checkAssignment(Expression expr, DartType t, bool constContext);

  DartType getStaticType(Expression expr) => expr.staticType;

  /// Given a type t, if t is an interface type with a call method
  /// defined, return the function type for the call method, otherwise
  /// return null.
  FunctionType getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      ClassElement element = t.element;
      InheritanceManager manager = new InheritanceManager(element.library);
      FunctionType callType = manager.lookupMemberType(t, "call");
      return callType;
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

  DartType elementType(Element e);

  bool isDynamicTarget(Expression expr);
  bool isDynamicCall(Expression call);
}

// TODO(jmesserly): this is unused.
class DartRules extends TypeRules {
  DartRules(TypeProvider provider) : super(provider);

  MissingTypeReporter reportMissingType = null;

  bool isSubTypeOf(DartType t1, DartType t2) {
    return t1.isSubtypeOf(t2);
  }

  bool isAssignable(DartType t1, DartType t2) {
    return t1.isAssignableTo(t2);
  }

  StaticInfo checkAssignment(
      Expression expr, DartType toType, bool constContext) {
    final fromType = getStaticType(expr);
    if (!isAssignable(fromType, toType)) {
      return new StaticTypeError(this, expr, toType);
    }
    return null;
  }

  DartType elementType(Element e) {
    return (e as dynamic).type;
  }

  /// By default, all invocations are dynamic in Dart.
  bool isDynamic(DartType t) => true;
  bool isDynamicTarget(Expression expr) => true;
  bool isDynamicCall(Expression call) => true;
}

typedef void MissingTypeReporter(Expression expr);

class RestrictedRules extends TypeRules {
  MissingTypeReporter reportMissingType = null;
  final RulesOptions options;
  final List<DartType> _nonnullableTypes;
  DownwardsInference inferrer;

  DartType _typeFromName(String name) {
    switch (name) {
      case 'int':
        return provider.intType;
      case 'double':
        return provider.doubleType;
      case 'num':
        return provider.numType;
      case 'bool':
        return provider.boolType;
      case 'String':
        return provider.stringType;
      default:
        throw new UnsupportedError('Unsupported non-nullable type $name');
    }
  }

  RestrictedRules(TypeProvider provider, {this.options})
      : _nonnullableTypes = <DartType>[],
        super(provider) {
    var types = options.nonnullableTypes;
    _nonnullableTypes.addAll(types.map(_typeFromName));
    inferrer = new DownwardsInference(this);
  }

  DartType getStaticType(Expression expr) {
    var type = expr.staticType;
    if (type != null) return type;
    if (reportMissingType != null) reportMissingType(expr);
    return provider.dynamicType;
  }

  bool _isBottom(DartType t, {bool dynamicIsBottom: false}) {
    if (t.isDynamic && dynamicIsBottom) return true;
    // TODO(vsm): We need direct support for non-nullability in DartType.
    // This should check on "true/nonnullable" Bottom
    if (t.isBottom && _nonnullableTypes.isEmpty) return true;
    return false;
  }

  bool _isTop(DartType t, {bool dynamicIsBottom: false}) {
    if (t.isDynamic && !dynamicIsBottom) return true;
    if (t.isObject) return true;
    return false;
  }

  bool isNonNullableType(DartType t) => _nonnullableTypes.contains(t);

  bool maybeNonNullableType(DartType t) {
    // Return true iff t *may* be a primitive type.
    // If t is a generic type parameter, return true if it may be
    // instantiated as a primitive.
    if (isNonNullableType(t)) {
      return true;
    } else if (t is TypeParameterType) {
      var bound = t.element.bound;
      if (bound == null) {
        bound = provider.dynamicType;
      }
      return _nonnullableTypes.any((DartType p) => isSubTypeOf(p, bound));
    } else {
      return false;
    }
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

    throw new StateError("Unexpected type");
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

    // The null type is a subtype of any nonnullable type.
    // TODO(vsm): Note, t1.isBottom still allows for null confusingly.
    // _isBottom(t1) does not necessarily imply t1.isBottom if there are
    // nonnullable types in the system.
    if (t1.isBottom) {
      // Return false iff t2 *may* be a primitive type.
      return !maybeNonNullableType(t2);
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
  // If wrap is true and both are function types, a closure
  // wrapper coercion is produced using _wrapTo (see above)
  // Returns the error coercion if the types cannot be coerced
  // according to our current criteria.
  Coercion _coerceTo(DartType fromT, DartType toT) {
    // We can use anything as void
    if (toT.isVoid) return Coercion.identity(toT);

    // fromT <: toT, no coercion needed
    if (isSubTypeOf(fromT, toT)) return Coercion.identity(toT);

    // For now, reject conversions between function types and
    // call method objects.  We could choose to allow casts here.
    // Wrapping a function type to assign it to a call method
    // object will never succeed.  Wrapping the other way could
    // be allowed.
    if ((fromT is FunctionType && getCallMethodType(toT) != null) ||
        (toT is FunctionType && getCallMethodType(fromT) != null)) {
      return Coercion.error();
    }

    // Downcast if toT <: fromT
    if (isSubTypeOf(toT, fromT)) return Coercion.cast(fromT, toT);

    // Downcast if toT <===> fromT
    // The intention here is to allow casts that are sideways in the restricted
    // type system, but allowed in the regular dart type system, since these
    // are likely to succeed.  The canonical example is List<dynamic> and
    // Iterable<T> for some concrete T (e.g. Object).  These are unrelated
    // in the restricted system, but List<dynamic> <: Iterable<T> in dart.
    if (options.relaxedCasts && fromT.isAssignableTo(toT)) {
      return Coercion.cast(fromT, toT);
    }
    return Coercion.error();
  }

  StaticInfo checkAssignment(Expression expr, DartType toT, bool constContext) {
    final fromT = getStaticType(expr);
    final Coercion c = _coerceTo(fromT, toT);
    if (c is Identity) return null;
    if (c is CoercionError) return new StaticTypeError(this, expr, toT);
    var reason = null;
    if (options.inferDownwards) {
      var errors = <String>[];
      var ok = inferrer.inferExpression(expr, toT, errors);
      if (ok) return InferredType.create(this, expr, toT);
      reason = (errors.isNotEmpty) ? errors.first : null;
    }
    if (c is Cast) return DownCast.create(this, expr, c, reason: reason);
    assert(false);
    return null;
  }

  DartType elementType(Element e) {
    return (e as dynamic).type;
  }

  /// Returns `true` if the target expression is dynamic.
  // TODO(jmesserly): remove this in favor of utils? Or a static method here?
  bool isDynamicTarget(Expression target) => utils.isDynamicTarget(target);

  /// Returns `true` if the expression is a dynamic function call or method
  /// invocation.
  bool isDynamicCall(Expression call) {
    var t = getTypeAsCaller(call);
    // TODO(leafp): This will currently return true if t is Function
    // This is probably the most correct thing to do for now, since
    // this code is also used by the back end.  Maybe revisit at some
    // point?
    if (t == null) return true;
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

    var ft = t as FunctionType;
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
    if (e is ConditionalExpression) {
      return _inferConditionalExpression(e, t, errors);
    }
    if (e is ParenthesizedExpression) {
      return _inferParenthesizedExpression(e, t, errors);
    }
    if (rules.isSubTypeOf(rules.getStaticType(e), t)) return true;
    if (cast && rules.getStaticType(e).isDynamic) {
      annotateCastFromDynamic(e, t);
      return true;
    }
    if (e is FunctionExpression) return _inferFunctionExpression(e, t, errors);
    if (e is ListLiteral) return _inferListLiteral(e, t, errors);
    if (e is MapLiteral) return _inferMapLiteral(e, t, errors);
    if (e is NamedExpression) return _inferNamedExpression(e, t, errors);
    if (e is InstanceCreationExpression) {
      return _inferInstanceCreationExpression(e, t, errors);
    }
    errors.add("$e cannot be typed as $t");
    return false;
  }

  /// If t1 = I<dynamic, ..., dynamic>, then look for a supertype
  /// of t1 of the form K<S0, ..., Sm> where t2 = K<S0', ..., Sm'>
  /// If the supertype exists, use the constraints S0 <: S0', ... Sm <: Sm'
  /// to derive a concrete instantation for I of the form <T0, ..., Tn>,
  /// such that I<T0, .., Tn> <: t2
  List<DartType> _matchTypes(InterfaceType t1, InterfaceType t2) {
    if (t1 == t2) return t2.typeArguments;
    var tArgs1 = t1.typeArguments;
    var tArgs2 = t2.typeArguments;
    // If t1 isn't a raw type, bail out
    if (tArgs1 != null && tArgs1.any((t) => !t.isDynamic)) return null;

    // This is our inferred type argument list.  We start at all dynamic,
    // and fill in with inferred types when we reach a match.
    var actuals =
        new List<DartType>.filled(tArgs1.length, rules.provider.dynamicType);

    // When we find the supertype of t1 with the same
    // classname as t2 (see below), we have the following:
    // If t1 is an instantiation of a class T1<X0, ..., Xn>
    // and t2 is an instantiation of a class T2<Y0, ...., Ym>
    // of the form t2 = T2<S0, ..., Sm>
    // then we want to choose instantiations for the Xi
    // T0, ..., Tn such that T1<T0, ..., Tn> <: t2 .
    // To find this, we simply instantate T1 with
    // X0, ..., Xn, and then find its superclass
    // T2<T0', ..., Tn'>.  We then solve the constraint
    // set T0' <: S0, ..., Tn' <: Sn for the Xi.
    // Currently, we only handle constraints where
    // the Ti' is one of the Xi'.  If there are multiple
    // constraints on some Xi, we choose the lower of the
    // two (if it exists).
    bool permute(List<DartType> permutedArgs) {
      if (permutedArgs == null) return false;
      var ps = t1.typeParameters;
      var ts = ps.map((p) => p.type).toList();
      for (int i = 0; i < permutedArgs.length; i++) {
        var tVar = permutedArgs[i];
        var tActual = tArgs2[i];
        var index = ts.indexOf(tVar);
        if (index >= 0 && rules.isSubTypeOf(tActual, actuals[index])) {
          actuals[index] = tActual;
        }
      }
      return actuals.any((x) => !x.isDynamic);
    }

    // Look for the first supertype of t1 with the same class name as t2.
    bool match(InterfaceType t1) {
      if (t1.element == t2.element) {
        return permute(t1.typeArguments);
      }

      if (t1 == rules.provider.objectType) return false;

      if (match(t1.superclass)) return true;

      for (final parent in t1.interfaces) {
        if (match(parent)) return true;
      }

      for (final parent in t1.mixins) {
        if (match(parent)) return true;
      }
      return false;
    }

    // We have that t1 = T1<dynamic, ..., dynamic>.
    // To match t1 against t2, we use the uninstantiated version
    // of t1, essentially treating it as an instantiation with
    // fresh variables, and solve for the variables.
    // t1.element.type will be of the form T1<X0, ..., Xn>
    if (!match(t1.element.type)) return null;
    var newT1 = t1.element.type.substitute4(actuals);
    // If we found a solution, return it.
    if (rules.isSubTypeOf(newT1, t2)) return actuals;
    return null;
  }

  /// These assume that e is not already a subtype of t

  bool _inferConditionalExpression(
      ConditionalExpression e, DartType t, errors) {
    return _inferExpression(e.thenExpression, t, errors) &&
        _inferExpression(e.elseExpression, t, errors);
  }

  bool _inferParenthesizedExpression(
      ParenthesizedExpression e, DartType t, errors) {
    return _inferExpression(e.expression, t, errors);
  }

  bool _inferInstanceCreationExpression(
      InstanceCreationExpression e, DartType t, errors) {
    var arguments = e.argumentList.arguments;
    var rawType = rules.getStaticType(e);
    // rawType is the instantiated type of the instance
    if (rawType is! InterfaceType) return false;
    var type = (rawType as InterfaceType);
    if (type.typeParameters == null ||
        type.typeParameters.length == 0) return false;
    if (e.constructorName.type == null) return false;
    // classTypeName is the type name of the class being instantiated
    var classTypeName = e.constructorName.type;
    // Check that we were not passed any type arguments
    if (classTypeName.typeArguments != null) return false;
    // Infer type arguments
    var targs = _matchTypes(type, t);
    if (targs == null) return false;
    if (e.staticElement == null) return false;
    var constructorElement = e.staticElement;
    // From the constructor element get:
    //  the instantiated type of the constructor, then
    //     the uninstantiated element for the constructor, then
    //        the uninstantiated type for the constructor
    var rawConstructorElement =
        constructorElement.type.element as ConstructorElement;
    var baseType = rawConstructorElement.type;
    if (baseType == null) return false;
    // From the interface type (instantiated), get:
    //  the uninstantiated element, then
    //    the uninstantiated type, then
    //      the type arguments (aka the type parameters)
    var tparams = type.element.type.typeArguments;
    // Take the uninstantiated constructor type, and replace the type
    // parameters with the inferred arguments.
    var fType = baseType.substitute2(targs, tparams);
    {
      var rTypes = fType.normalParameterTypes;
      var oTypes = fType.optionalParameterTypes;
      var pTypes = new List.from(rTypes)..addAll(oTypes);
      var pArgs = arguments.where((x) => x is! NamedExpression);
      var pi = 0;
      for (var arg in pArgs) {
        if (pi >= pTypes.length) return false;
        var argType = pTypes[pi];
        if (!_inferExpression(arg, argType, errors)) return false;
        pi++;
      }
      var nTypes = fType.namedParameterTypes;
      for (var arg0 in arguments) {
        if (arg0 is! NamedExpression) continue;
        var arg = arg0 as NamedExpression;
        SimpleIdentifier nameNode = arg.name.label;
        String name = nameNode.name;
        var argType = nTypes[name];
        if (argType == null) return false;
        if (!_inferExpression(arg, argType, errors)) return false;
      }
    }
    annotateInstanceCreationExpression(e, targs);
    return true;
  }

  bool _inferNamedExpression(NamedExpression e, DartType t, errors) {
    return _inferExpression(e.expression, t, errors);
  }

  bool _inferFunctionExpression(FunctionExpression e, DartType t, errors) {
    if (t is! FunctionType) return false;
    var fType = t as FunctionType;
    var eType = e.staticType as FunctionType;
    if (eType is! FunctionType) return false;

    // We have a function literal, so we can treat the arrow type
    // as non-fuzzy.  Since we're not improving on parameter types
    // currently, if this check fails then we cannot succeed, so
    // bail out.  Otherwise, we never need to check the parameter types
    // again.
    if (!rules.isFunctionSubTypeOf(eType, fType,
        fuzzyArrows: false, ignoreReturn: true)) return false;

    // This only entered inference because of fuzzy typing.
    // The function type is already specific enough, we can just
    // succeed and treat it as a successful inference
    if (rules.isSubTypeOf(eType.returnType, fType.returnType)) return true;

    // Fuzzy typing again, handle the void case (not caught by the previous)
    if (fType.returnType.isVoid) return true;

    if (e.body is! ExpressionFunctionBody) return false;
    var body = (e.body as ExpressionFunctionBody).expression;
    if (!_inferExpression(body, fType.returnType, errors)) return false;

    // TODO(leafp): Try narrowing the argument types if possible
    // to get better code in the function body.  This requires checking
    // that the body is well-typed at the more specific type.

    // At this point, we know that the parameter types are in the appropriate subtype
    // relation, and we have checked that we can type the body at the appropriate return
    // type, so we can are done.
    annotateFunctionExpression(e, fType.returnType);
    return true;
  }

  bool _inferListLiteral(ListLiteral e, DartType t, errors) {
    var dyn = rules.provider.dynamicType;
    var listT = rules.provider.listType.substitute4([dyn]);
    // List <: t (using dart rules) must be true
    if (!listT.isSubtypeOf(t)) return false;
    // The list literal must have no type arguments
    if (e.typeArguments != null) return false;
    if (t is! InterfaceType) return false;
    var targs = _matchTypes(listT, t);
    if (targs == null) return false;
    assert(targs.length == 1);
    var etype = targs[0];
    assert(!etype.isDynamic);
    var elements = e.elements;
    var b = elements.every((e) => _inferExpression(e, etype, errors));
    if (b) annotateListLiteral(e, targs);
    return b;
  }

  bool _inferMapLiteral(MapLiteral e, DartType t, errors) {
    var dyn = rules.provider.dynamicType;
    var mapT = rules.provider.mapType.substitute4([dyn, dyn]);
    // Map <: t (using dart rules) must be true
    if (!mapT.isSubtypeOf(t)) return false;
    // The map literal must have no type arguments
    if (e.typeArguments != null) return false;
    if (t is! InterfaceType) return false;
    var targs = _matchTypes(mapT, t);
    if (targs == null) return false;
    assert(targs.length == 2);
    var kType = targs[0];
    var vType = targs[1];
    assert(!(kType.isDynamic && vType.isDynamic));
    var entries = e.entries;
    bool inferEntry(MapLiteralEntry entry) {
      return _inferExpression(entry.key, kType, errors) &&
          _inferExpression(entry.value, vType, errors);
    }
    var b = entries.every(inferEntry);
    if (b) annotateMapLiteral(e, targs);
    return b;
  }
}
