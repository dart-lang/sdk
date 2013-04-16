// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

setRuntimeTypeInfo(target, typeInfo) {
  assert(typeInfo == null || isJsArray(typeInfo));
  // We have to check for null because factories may return null.
  if (target != null) JS('var', r'#.$builtinTypeInfo = #', target, typeInfo);
}

getRuntimeTypeInfo(target) {
  if (target == null) return null;
  return JS('var', r'#.$builtinTypeInfo', target);
}

getRuntimeTypeArgument(target, substitution, index) {
  var arguments = substitute(substitution, getRuntimeTypeInfo(target));
  return (arguments == null) ? null : getField(arguments, index);
}

class TypeImpl implements Type {
  final String typeName;
  TypeImpl(this.typeName);
  toString() => typeName;
  int get hashCode => typeName.hashCode;
  bool operator ==(other) {
    if (other is !TypeImpl) return false;
    return typeName == other.typeName;
  }
}

String getClassName(var object) {
  return JS('String', r'#.constructor.builtin$cls', object);
}

String getRuntimeTypeAsString(List runtimeType) {
  String className = getConstructorName(runtimeType[0]);
  return '$className${joinArguments(runtimeType, 1)}';
}

String getConstructorName(type) => JS('String', r'#.builtin$cls', type);

String runtimeTypeToString(type) {
  if (type == null) {
    return 'dynamic';
  } else if (isJsArray(type)) {
    // A list representing a type with arguments.
    return getRuntimeTypeAsString(type);
  } else {
    // A reference to the constructor.
    return getConstructorName(type);
  }
}

String joinArguments(var types, int startIndex) {
  if (types == null) return '';
  bool firstArgument = true;
  bool allDynamic = true;
  StringBuffer buffer = new StringBuffer();
  for (int index = startIndex; index < types.length; index++) {
    if (firstArgument) {
      firstArgument = false;
    } else {
      buffer.write(', ');
    }
    var argument = types[index];
    if (argument != null) {
      allDynamic = false;
    }
    buffer.write(runtimeTypeToString(argument));
  }
  return allDynamic ? '' : '<$buffer>';
}

String getRuntimeTypeString(var object) {
  String className = isJsArray(object) ? 'List' : getClassName(object);
  var typeInfo = JS('var', r'#.$builtinTypeInfo', object);
  return "$className${joinArguments(typeInfo, 0)}";
}

bool isJsFunction(var o) => JS('bool', r'typeof # == "function"', o);

Object invoke(function, arguments) {
  return JS('var', r'#.apply(null, #)', function, arguments);
}

Object call(target, name) => JS('var', r'#[#]()', target, name);

substitute(var substitution, var arguments) {
  if (isJsArray(substitution)) {
    arguments = substitution;
  } else if (isJsFunction(substitution)) {
    arguments = invoke(substitution, arguments);
  }
  return arguments;
}

/**
 * Perform a type check with arguments on the Dart object [object].
 *
 * Parameters:
 * - [isField]: the name of the flag/function to check if the object
 *   is of the correct class.
 * - [checks]: the (JavaScript) list of type representations for the
 *   arguments to check against.
 * - [asField]: the name of the function that transforms the type
 *   arguments of [objects] to an instance of the class that we check
 *   against.
 */
bool checkSubtype(Object object, String isField, List checks, String asField) {
  if (object == null) return false;
  var arguments = getRuntimeTypeInfo(object);
  // Interceptor is needed for JSArray and native classes.
  // TODO(sra): It could be a more specialized interceptor since [object] is not
  // `null` or a primitive.
  // TODO(9586): Move type info for static functions onto an interceptor.
  var interceptor = isJsFunction(object) ? object : getInterceptor(object);
  bool isSubclass = getField(interceptor, isField);
  // When we read the field and it is not there, [isSubclass] will be [:null:].
  if (isSubclass == null || !isSubclass) return false;
  // Should the asField function be passed the receiver?
  var substitution = getField(interceptor, asField);
  return checkArguments(substitution, arguments, checks);
}

/**
 * Check that the types in the list [arguments] are subtypes of the types in
 * list [checks] (at the respective positions), possibly applying [substitution]
 * to the arguments before the check.
 *
 * See [:RuntimeTypes.getSubtypeSubstitution:] for a description of the possible
 * values for [substitution].
 */
bool checkArguments(var substitution, var arguments, var checks) {
  return areSubtypes(substitute(substitution, arguments), checks);
}

bool areSubtypes(List s, List t) {
  // [:null:] means a raw type.
  if (s == null || t == null) return true;

  assert(isJsArray(s));
  assert(isJsArray(t));
  assert(s.length == t.length);

  int len = s.length;
  for (int i = 0; i < len; i++) {
    if (!isSubtype(s[i], t[i])) {
      return false;
    }
  }
  return true;
}

getArguments(var type) {
  return isJsArray(type) ? JS('var', r'#.slice(1)', type) : null;
}

getField(var object, var name) => JS('var', r'#[#]', object, name);

/**
 * Tests whether the Dart object [o] is a subtype of the runtime type
 * representation [t], which is a type representation as described in the
 * comment on [isSubtype].
 */
bool objectIsSubtype(Object o, var t) {
  if (JS('bool', '# == null', o) || JS('bool', '# == null', t)) return true;
  // Get the runtime type information from the object here, because we may
  // overwrite o with the interceptor below.
  var rti = getRuntimeTypeInfo(o);
  // Check for native objects and use the interceptor instead of the object.
  // TODO(9586): Move type info for static functions onto an interceptor.
  o = isJsFunction(o) ? o : getInterceptor(o);
  // We can use the object as its own type representation because we install
  // the subtype flags and the substitution on the prototype, so they are
  // properties of the object in JS.
  var type;
  if (JS('bool', '# != null', rti)) {
    // If the type has type variables (that is, [:rti != null:]), make a copy of
    // the type arguments and insert [o] in the first position to create a
    // compound type representation.
    type = JS('List', '#.slice()', rti);
    JS('', '#.splice(0, 0, #)', type, o);
  } else {
    // Use the object as representation of the raw type.
    type = o;
  }
  return isSubtype(type, t);
}

/**
 * Check whether the type represented by [s] is a subtype of the type
 * represented by [t].
 *
 * Type representations can be:
 *  1) a JavaScript constructor for a class C: the represented type is the raw
 *     type C.
 *  2) a Dart object: this is the interceptor instance for a native type.
 *  3) a JavaScript object: this represents a class for which there is no
 *     JavaScript constructor, because it is only used in type arguments or it
 *     is native. The represented type is the raw type of this class.
 *  4) a JavaScript array: the first entry is of type 1, 2 or 3 and contains the
 *     subtyping flags and the substitution of the type and the rest of the
 *     array are the type arguments.
 *  5) [:null:]: the dynamic type.
 */
bool isSubtype(var s, var t) {
  // If either type is dynamic, [s] is a subtype of [t].
  if (JS('bool', '# == null', s) || JS('bool', '# == null', t)) return true;
  // Subtyping is reflexive.
  if (JS('bool', '# === #', s, t)) return true;
  // Get the object describing the class and check for the subtyping flag
  // constructed from the type of [t].
  var typeOfS = isJsArray(s) ? s[0] : s;
  var typeOfT = isJsArray(t) ? t[0] : t;
  // Check for a subtyping flag.
  var test = '${JS_OPERATOR_IS_PREFIX()}${runtimeTypeToString(typeOfT)}';
  if (getField(typeOfS, test) == null) return false;
  // Get the necessary substitution of the type arguments, if there is one.
  var substitution;
  if (JS('bool', '# !== #', typeOfT, typeOfS)) {
    var field = '${JS_OPERATOR_AS_PREFIX()}${runtimeTypeToString(typeOfT)}';
    substitution = getField(typeOfS, field);
  }
  // The class of [s] is a subclass of the class of [t].  If [s] has no type
  // arguments and no substitution, it is used as raw type.  If [t] has no
  // type arguments, it used as a raw type.  In both cases, [s] is a subtype
  // of [t].
  if ((!isJsArray(s) && JS('bool', '# == null', substitution)) ||
      !isJsArray(t)) {
    return true;
  }
  // Recursively check the type arguments.
  return checkArguments(substitution, getArguments(s), getArguments(t));
}

createRuntimeType(String name) => new TypeImpl(name);
