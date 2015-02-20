library ddc.runtime.dart_runtime;

import 'dart:mirrors';

import 'package:ddc/config.dart';

dynamic dload(dynamic obj, String field) {
  var symbol = new Symbol(field);
  var mirror = reflect(obj);
  // TODO(vsm): Does this create an NSM?
  var fieldMirror = mirror.getField(symbol);
  return fieldMirror.reflectee;
}

dynamic dinvokef(dynamic f, List args) {
  // TODO(vsm): Support named arguments.
  assert(f is Function);
  return Function.apply(f, args);
}

// A workaround to manufacture a generic Type object inline.
// We use mirrors to extract type T given a TypeFunction<T>.
// E.g., Map<String, String> is not a valid literal in Dart.
// Instead, use: type((Map<String, String> _) {});
// See bug: https://code.google.com/p/dart/issues/detail?id=11923
typedef TypeFunction<T>(T x);

Type type(TypeFunction f) {
  ClosureMirror cm = reflect(f);
  MethodMirror mm = cm.function;
  ParameterMirror pm = mm.parameters[0];
  TypeMirror tm = pm.type;
  return tm.reflectedType;
}

dynamic cast(dynamic obj, Type staticType) {
  // This is our 'as' equivalent.
  if (obj == null) {
    // A null can be cast only to non-primitive types.
    if (!isPrimitiveType(staticType)) return null;
  } else {
    // For non-null values, val is T => val as T succeeds.
    if (instanceOf(obj, staticType)) return obj;
  }
  // TODO(vsm): Add message.
  throw new CastError();
}

bool instanceOf(dynamic obj, Type staticType) {
  // This is our 'is' equivalent.
  if (obj == null) {
    // Only true for the Object type.
    return staticType == Object || staticType == dynamic || staticType == Null;
  }

  Type runtimeType = obj.runtimeType;
  return _isSubType(reflectType(runtimeType), reflectType(staticType));
}

bool isGroundType(Type type) {
  // These are types allow in is / as expressions.
  final mirror = reflectType(type);
  // Disallow functions.
  if (mirror is FunctionTypeMirror) return false;
  if (mirror is TypedefMirror) return false;
  // Disallow generic type parameters.
  if (mirror is TypeVariableMirror) return false;

  if (mirror is ClassMirror) {
    return _isRawClass(mirror);
  }

  // Only dynamic should be left.  Should this be allowed?
  // It's not particularly useful.
  assert(mirror.reflectedType == dynamic);
  return true;
}

final _primitiveMap = {
  'int': int,
  'double': double,
  'num': num,
  'bool': bool,
  'String': String,
};

// TODO(vsm): Make this configurable?  Using default settings for now.
final _typeOptions = new TypeOptions();

Set<Type> _primitives = () {
  var types = _typeOptions.nonnullableTypes;
  var set = new Set<Type>.from(types.map((t) => _primitiveMap[t]));
  return set;
}();

bool isPrimitiveType(Type t) {
  return _primitives.contains(t);
}

class Arity {
  final int normal;
  final int optionalPositional;

  Arity._internal(this.normal, this.optionalPositional);

  int get min => normal;
  int get max => normal + optionalPositional;
}

Arity getArity(Function f) {
  final FunctionTypeMirror mirror = reflectType(f.runtimeType);
  final parameters = mirror.parameters;
  int normal = 0;
  int optionalPositional = 0;
  for (var parameter in parameters) {
    if (parameter.isNamed) {
      // Ignore named parameters - these cannot be passed positionally.
    } else if (parameter.isOptional) {
      optionalPositional++;
    } else {
      normal++;
    }
  }
  return new Arity._internal(normal, optionalPositional);
}

bool _isFunctionSubType(TypeMirror t1, TypeMirror t2) {
  // Function types follow the standard non-Dart rule:
  // - contravariant on param types
  // - covariant on return type
  final f1 = t1 as FunctionTypeMirror;
  final f2 = t2 as FunctionTypeMirror;

  final params1 = f1.parameters;
  final params2 = f2.parameters;
  final ret1 = f1.returnType;
  final ret2 = f2.returnType;
  return _isFunctionSubTypeHelper(ret1, params1, ret2, params2);
}

bool _isFunctionSubTypeHelper(TypeMirror ret1, List<ParameterMirror> params1,
    TypeMirror ret2, List<ParameterMirror> params2) {
  if (!_isSubType(ret1, ret2)) {
    // Covariant return types
    // Note, void (which can only appear as a return type) is effectively
    // treated as dynamic.  If the base return type is void, we allow any
    // subtype return type.
    // E.g., we allow:
    //   () -> int <: () -> void
    if (ret2.simpleName != const Symbol('void')) {
      return false;
    }
  }

  if (params1.length < params2.length) {
    return false;
  }

  for (int i = 0; i < params2.length; ++i) {
    ParameterMirror p1 = params1[i];
    ParameterMirror p2 = params2[i];

    // Contravariant parameter types.
    if (!_isSubType(p2.type, p1.type)) {
      return false;
    }

    // Optional parameters.
    if (p2.isOptional) {
      // If the base param is optional, the sub param must be optional:
      if (!p1.isOptional) return false;
      if (!p2.isNamed) {
        // either neither are named or
        if (p1.isNamed) return false;
      } else {
        // both are named with the same name
        if (!p1.isNamed || p1.simpleName != p2.simpleName) return false;
      }
    } else {
      // If the base param is required, the sub may be optional, but not named.
      if (p1.isNamed) return false;
    }
  }

  for (int i = params2.length; i < params1.length; ++i) {
    ParameterMirror p1 = params1[i];
    // Any additional sub params must be optional.
    if (!p1.isOptional) return false;
  }

  return true;
}

bool _isClassSubType(ClassMirror m1, ClassMirror m2) {
  // TODO(vsm): Consider some caching for efficiency here.

  // We support Dart's covariant generics with the caveat that we do not
  // substitute bottom for dynamic in subtyping rules.
  // I.e., given T1, ..., Tn where at least one Ti != dynamic we disallow:
  // - S !<: S<T1, ..., Tn>
  // - S<dynamic, ..., dynamic> !<: S<T1, ..., Tn>
  if (m1 == m2) return true;

  if (m1.hasReflectedType && m1.reflectedType == Object) return false;

  // Check if m1 and m2 have the same raw type.  If so, check covariance on
  // type parameters.
  if (m1.originalDeclaration == m2.originalDeclaration) {
    final typeArguments1 = m1.typeArguments;
    final typeArguments2 = m2.typeArguments;
    final length = typeArguments1.length;
    if (typeArguments2.length == 0) {
      // m2 is the raw form of m1
      return true;
    } else if (typeArguments1.length == 0) {
      // m1 is raw, but m2 is not
      return false;
    }
    assert(typeArguments2.length == length);
    for (var i = 0; i < length; ++i) {
      var typeArgument1 = typeArguments1[i];
      var typeArgument2 = typeArguments2[i];
      if (!_isSubType(typeArgument1, typeArgument2)) {
        return false;
      }
    }
    return true;
  }

  // Check superclass.
  if (_isClassSubType(m1.superclass, m2)) return true;

  // Check interfaces.
  for (final parent in m1.superinterfaces) {
    if (_isClassSubType(parent, m2)) return true;
  }

  return false;
}

bool _isRawClass(ClassMirror mirror) {
  // Allow only raw types.
  if (mirror == mirror.originalDeclaration) return true;
  final dynamicMirror = reflectType(dynamic);
  for (var typeArgument in mirror.typeArguments) {
    if (typeArgument != dynamicMirror) return false;
  }
  return true;
}

TypeMirror _canonicalizeTypeMirror(TypeMirror t) {
  if (t is TypedefMirror) {
    // We canonicalize Typedefs to their underlying function types.
    t = (t as TypedefMirror).referent;
  }
  if (t is ClassMirror && _isRawClass(t)) {
    // We canonicalize T<dynamic> to T.
    t = t.originalDeclaration;
  }
  return t;
}

bool _reflects(TypeMirror mirror, Type t) {
  return mirror.hasReflectedType && mirror.reflectedType == t;
}

bool _isSubType(TypeMirror t1, TypeMirror t2) {
  t1 = _canonicalizeTypeMirror(t1);
  t2 = _canonicalizeTypeMirror(t2);

  if (t1 == t2) return true;

  // In Dart, dynamic is effectively both top and bottom.
  // Here, we treat dynamic as top - the base type of everything.
  if (_reflects(t1, dynamic)) return false;
  if (_reflects(t2, dynamic)) return true;

  // Object only subtypes dynamic and Object.
  if (_reflects(t2, Object)) return true;
  if (_reflects(t1, Object)) return false;

  // "Traditional" name-based subtype check.
  final c1 = t1 as ClassMirror;
  final c2 = t2 as ClassMirror;
  if (_isClassSubType(c1, c2)) {
    return true;
  }

  // Function subtyping.
  // Note: it appears under the hood all Dart functions map to a class / hidden type
  // that:
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
  // but doesn't properly mix with class subtyping yet.
  //
  // Note, a class type that implements a call method implicitly subtypes
  // the function type of the call method.  However, the converse is not true:
  // a function type does not subtype a class type with a call method.

  // If c1 is not a proper function or a class type with call method,
  // return false.
  TypeMirror ret1;
  List<ParameterMirror> params1;
  // Note, a proper function has a call method, but it's not a regular method,
  // so we break out the two cases.
  if (c1 is FunctionTypeMirror) {
    // Regular function
    ret1 = c1.returnType;
    params1 = c1.parameters;
  } else {
    var call1 = c1.instanceMembers[#call];
    if (call1 == null || !call1.isRegularMethod) return false;
    // Class that emulate a function
    ret1 = call1.returnType;
    params1 = call1.parameters;
  }

  // Any type that implements a call method implicitly subtypes Function.
  if (_reflects(c2, Function)) return true;

  // Check structural function subtyping
  return _isFunctionSubTypeHelper(ret1, params1, c2.returnType, c2.parameters);
}
