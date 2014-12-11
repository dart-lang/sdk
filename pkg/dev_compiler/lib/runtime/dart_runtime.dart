library ddc.runtime.dart_runtime;

import 'dart:mirrors';

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

bool isPrimitiveType(Type t) {
  if (t == int || t == double || t == bool) return true;
  return false;
}

bool _isPrimitiveType(TypeMirror m) {
  if (!m.hasReflectedType) return false;
  var t = m.reflectedType;
  return isPrimitiveType(t);
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

  if (!_isSubType(ret1, ret2)) {
    // Covariant return types.
    return false;
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

  // We are more restrictive than Dart's covariant generics.
  // Ours are invariant, with the addition that:
  // - S<T> <: S
  // - S<dynamic> == S
  if (m1 == m2) return true;

  if (m1.hasReflectedType && m1.reflectedType == Object) return false;

  // Check if m1 is not in raw form.
  if (m1 != m1.originalDeclaration) {
    // Raw(m1) <: m2 => m1 <: m2
    if (_isClassSubType(m1.originalDeclaration, m2)) {
      return true;
    }
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

  if (t1 is! FunctionTypeMirror || t2 is! FunctionTypeMirror) return false;

  // Functions
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
  return _isFunctionSubType(c1 as FunctionTypeMirror, c2 as FunctionTypeMirror);
}
