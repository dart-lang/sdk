// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This part contains helpers for supporting runtime type information.
 *
 * The helper use a mixture of Dart and JavaScript objects. To indicate which is
 * used where we adopt the scheme of using explicit type annotation for Dart
 * objects and 'var' or omitted return type for JavaScript objects.
 *
 * Since bool, int, and String values are represented by the same JavaScript
 * primitives, type annotations are used for these types in all cases.
 *
 * Several methods use a common JavaScript encoding of runtime type information.
 * This encoding is referred to as the type representation which is one of
 * these:
 *  1) a JavaScript constructor for a class C: the represented type is the raw
 *     type C.
 *  2) a Dart object: this is the interceptor instance for a native type.
 *  3) a JavaScript object: this represents a class for which there is no
 *     JavaScript constructor, because it is only used in type arguments or it
 *     is native. The represented type is the raw type of this class.
 *  4) a JavaScript array: the first entry is of type 1, 2 or 3 and contains the
 *     subtyping flags and the substitution of the type and the rest of the
 *     array are the type arguments.
 *  5) `null`: the dynamic type.
 *
 *
 * To check subtype relations between generic classes we use a JavaScript
 * expression that describes the necessary substitution for type arguments.
 * Such a substitution expresssion can be:
 *  1) `null`, if no substituted check is necessary, because the
 *     type variables are the same or there are no type variables in the class
 *     that is checked for.
 *  2) A list expression describing the type arguments to be used in the
 *     subtype check, if the type arguments to be used in the check do not
 *     depend on the type arguments of the object.
 *  3) A function mapping the type variables of the object to be checked to
 *     a list expression.
 */

part of _js_helper;

Type createRuntimeType(String name) => new TypeImpl(name);

class TypeImpl implements Type {
  final String _typeName;
  String _unmangledName;

  TypeImpl(this._typeName);

  String toString() {
    if (_unmangledName != null) return _unmangledName;
    String unmangledName = unmangleAllIdentifiersIfPreservedAnyways(_typeName);
    return _unmangledName = unmangledName;
  }

  // TODO(ahe): This is a poor hashCode as it collides with its name.
  int get hashCode => _typeName.hashCode;

  bool operator ==(other) {
    return  (other is TypeImpl) && _typeName == other._typeName;
  }
}

/**
 * Represents a type variable.
 *
 * This class holds the information needed when reflecting on generic classes
 * and their members.
 */
class TypeVariable {
  final Type owner;
  final String name;
  final int bound;

  const TypeVariable(this.owner, this.name, this.bound);
}

getMangledTypeName(TypeImpl type) => type._typeName;

/**
 * Sets the runtime type information on [target]. [typeInfo] is a type
 * representation of type 4 or 5, that is, either a JavaScript array or
 * [:null:].
 */
Object setRuntimeTypeInfo(Object target, var typeInfo) {
  assert(isNull(typeInfo) || isJsArray(typeInfo));
  // We have to check for null because factories may return null.
  if (target != null) JS('var', r'#.$builtinTypeInfo = #', target, typeInfo);
  return target;
}

/**
 * Returns the runtime type information of [target]. The returned value is a
 * list of type representations for the type arguments.
 */
getRuntimeTypeInfo(Object target) {
  if (target == null) return null;
  return JS('var', r'#.$builtinTypeInfo', target);
}

/**
 * Returns the type arguments of [target] as an instance of [substitutionName].
 */
getRuntimeTypeArguments(target, substitutionName) {
  var substitution =
      getField(target, '${JS_OPERATOR_AS_PREFIX()}$substitutionName');
  return substitute(substitution, getRuntimeTypeInfo(target));
}

/**
 * Returns the [index]th type argument of [target] as an instance of
 * [substitutionName].
 */
@NoThrows() @NoSideEffects() @NoInline()
getRuntimeTypeArgument(Object target, String substitutionName, int index) {
  var arguments = getRuntimeTypeArguments(target, substitutionName);
  return isNull(arguments) ? null : getIndex(arguments, index);
}

@NoThrows() @NoSideEffects() @NoInline()
getTypeArgumentByIndex(Object target, int index) {
  var rti = getRuntimeTypeInfo(target);
  return isNull(rti) ? null : getIndex(rti, index);
}

void copyTypeArguments(Object source, Object target) {
  JS('var', r'#.$builtinTypeInfo = #.$builtinTypeInfo', target, source);
}

/**
 * Retrieves the class name from type information stored on the constructor
 * of [object].
 */
String getClassName(var object) {
  return JS('String', r'#.constructor.builtin$cls', getInterceptor(object));
}

/**
 * Creates the string representation for the type representation [runtimeType]
 * of type 4, the JavaScript array, where the first element represents the class
 * and the remaining elements represent the type arguments.
 */
String getRuntimeTypeAsString(var runtimeType, {String onTypeVariable(int i)}) {
  assert(isJsArray(runtimeType));
  String className = getConstructorName(getIndex(runtimeType, 0));
  return '$className'
         '${joinArguments(runtimeType, 1, onTypeVariable: onTypeVariable)}';
}

/**
 * Retrieves the class name from type information stored on the constructor
 * [type].
 */
String getConstructorName(var type) => JS('String', r'#.builtin$cls', type);

/**
 * Returns a human-readable representation of the type representation [type].
 */
String runtimeTypeToString(var type, {String onTypeVariable(int i)}) {
  if (isNull(type)) {
    return 'dynamic';
  } else if (isJsArray(type)) {
    // A list representing a type with arguments.
    return getRuntimeTypeAsString(type, onTypeVariable: onTypeVariable);
  } else if (isJsFunction(type)) {
    // A reference to the constructor.
    return getConstructorName(type);
  } else if (type is int) {
    if (onTypeVariable == null) {
      return type.toString();
    } else {
      return onTypeVariable(type);
    }
  } else {
    // TODO(ahe): Handle function types, and be sure to always return a string.
    return null;
  }
}

/**
 * Creates a comma-separated string of human-readable representations of the
 * type representations in the JavaScript array [types] starting at index
 * [startIndex].
 */
String joinArguments(var types, int startIndex,
                     {String onTypeVariable(int i)}) {
  if (isNull(types)) return '';
  assert(isJsArray(types));
  bool firstArgument = true;
  bool allDynamic = true;
  StringBuffer buffer = new StringBuffer();
  for (int index = startIndex; index < getLength(types); index++) {
    if (firstArgument) {
      firstArgument = false;
    } else {
      buffer.write(', ');
    }
    var argument = getIndex(types, index);
    if (argument != null) {
      allDynamic = false;
    }
    buffer.write(runtimeTypeToString(argument, onTypeVariable: onTypeVariable));
  }
  return allDynamic ? '' : '<$buffer>';
}

/**
 * Returns a human-readable representation of the type of [object].
 *
 * In minified mode does *not* use unminified identifiers (even when present).
 */
String getRuntimeTypeString(var object) {
  String className = getClassName(object);
  if (object == null) return className;
  var typeInfo = JS('var', r'#.$builtinTypeInfo', object);
  return "$className${joinArguments(typeInfo, 0)}";
}

Type getRuntimeType(var object) {
  String type = getRuntimeTypeString(object);
  return new TypeImpl(type);
}

/**
 * Applies the [substitution] on the [arguments].
 *
 * See the comment in the beginning of this file for a description of the
 * possible values for [substitution].
 */
substitute(var substitution, var arguments) {
  assert(isNull(substitution) ||
         isJsArray(substitution) ||
         isJsFunction(substitution));
  assert(isNull(arguments) || isJsArray(arguments));
  if (isJsArray(substitution)) {
    arguments = substitution;
  } else if (isJsFunction(substitution)) {
    substitution = invoke(substitution, arguments);
    if (isJsArray(substitution)) {
      arguments = substitution;
    } else if (isJsFunction(substitution)) {
      // TODO(johnniwinther): Check if this is still needed.
      arguments = invoke(substitution, arguments);
    }
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
  var interceptor = getInterceptor(object);
  var isSubclass = getField(interceptor, isField);
  // When we read the field and it is not there, [isSubclass] will be [:null:].
  if (isNull(isSubclass)) return false;
  // Should the asField function be passed the receiver?
  var substitution = getField(interceptor, asField);
  return checkArguments(substitution, arguments, checks);
}

/// Returns the field's type name.
///
/// In minified mode, uses the unminified names if available.
String computeTypeName(String isField, List arguments) {
  // Shorten the field name to the class name and append the textual
  // representation of the type arguments.
  int prefixLength = JS_OPERATOR_IS_PREFIX().length;
  return Primitives.formatType(isField.substring(prefixLength, isField.length),
                               arguments);
}

Object subtypeCast(Object object, String isField, List checks, String asField) {
  if (object != null && !checkSubtype(object, isField, checks, asField)) {
    String actualType = Primitives.objectTypeName(object);
    String typeName = computeTypeName(isField, checks);
    // TODO(johnniwinther): Move type lookup to [CastErrorImplementation] to
    // align with [TypeErrorImplementation].
    throw new CastErrorImplementation(actualType, typeName);
  }
  return object;
}

Object assertSubtype(Object object, String isField, List checks,
                     String asField) {
  if (object != null && !checkSubtype(object, isField, checks, asField)) {
    String typeName = computeTypeName(isField, checks);
    throw new TypeErrorImplementation(object, typeName);
  }
  return object;
}

/// Checks that the type represented by [subtype] is a subtype of [supertype].
/// If not a type error with [message] is thrown.
assertIsSubtype(var subtype, var supertype, String message) {
  if (!isSubtype(subtype, supertype)) {
    throwTypeError(message);
  }
}

throwTypeError(message) {
  throw new TypeErrorImplementation.fromMessage(message);
}

/**
 * Check that the types in the list [arguments] are subtypes of the types in
 * list [checks] (at the respective positions), possibly applying [substitution]
 * to the arguments before the check.
 *
 * See the comment in the beginning of this file for a description of the
 * possible values for [substitution].
 */
bool checkArguments(var substitution, var arguments, var checks) {
  return areSubtypes(substitute(substitution, arguments), checks);
}

/**
 * Checks whether the types of [s] are all subtypes of the types of [t].
 *
 * [s] and [t] are either [:null:] or JavaScript arrays of type representations,
 * A [:null:] argument is interpreted as the arguments of a raw type, that is a
 * list of [:dynamic:]. If [s] and [t] are JavaScript arrays they must be of the
 * same length.
 *
 * See the comment in the beginning of this file for a description of type
 * representations.
 */
bool areSubtypes(var s, var t) {
  // [:null:] means a raw type.
  if (isNull(s) || isNull(t)) return true;

  assert(isJsArray(s));
  assert(isJsArray(t));
  assert(getLength(s) == getLength(t));

  int len = getLength(s);
  for (int i = 0; i < len; i++) {
    if (!isSubtype(getIndex(s, i), getIndex(t, i))) {
      return false;
    }
  }
  return true;
}

/**
 * Computes the signature by applying the type arguments of [context] as an
 * instance of [contextName] to the signature function [signature].
 */
computeSignature(var signature, var context, var contextName) {
  var typeArguments = getRuntimeTypeArguments(context, contextName);
  return invokeOn(signature, context, typeArguments);
}

/**
 * Returns [:true:] if the runtime type representation [type] is a supertype of
 * [:Null:].
 */
bool isSupertypeOfNull(var type) {
  // `null` means `dynamic`.
  return isNull(type) || getConstructorName(type) == JS_OBJECT_CLASS_NAME()
                      || getConstructorName(type) == JS_NULL_CLASS_NAME();
}

/**
 * Tests whether the Dart object [o] is a subtype of the runtime type
 * representation [t].
 *
 * See the comment in the beginning of this file for a description of type
 * representations.
 */
bool checkSubtypeOfRuntimeType(o, t) {
  if (isNull(o)) return isSupertypeOfNull(t);
  if (isNull(t)) return true;
  // Get the runtime type information from the object here, because we may
  // overwrite o with the interceptor below.
  var rti = getRuntimeTypeInfo(o);
  o = getInterceptor(o);
  // We can use the object as its own type representation because we install
  // the subtype flags and the substitution on the prototype, so they are
  // properties of the object in JS.
  var type;
  if (isNotNull(rti)) {
    // If the type has type variables (that is, [:rti != null:]), make a copy of
    // the type arguments and insert [o] in the first position to create a
    // compound type representation.
    type = JS('JSExtendableArray', '#.slice()', rti);
    JS('', '#.splice(0, 0, #)', type, o);
  } else {
    // Use the object as representation of the raw type.
    type = o;
  }
  return isSubtype(type, t);
}

Object subtypeOfRuntimeTypeCast(Object object, var type) {
  if (object != null && !checkSubtypeOfRuntimeType(object, type)) {
    String actualType = Primitives.objectTypeName(object);
    throw new CastErrorImplementation(actualType, runtimeTypeToString(type));
  }
  return object;
}

Object assertSubtypeOfRuntimeType(Object object, var type) {
  if (object != null && !checkSubtypeOfRuntimeType(object, type)) {
    throw new TypeErrorImplementation(object, runtimeTypeToString(type));
  }
  return object;
}

/**
 * Extracts the type arguments from a type representation. The result is a
 * JavaScript array or [:null:].
 */
getArguments(var type) {
  return isJsArray(type) ? JS('var', r'#.slice(1)', type) : null;
}

/**
 * Checks whether the type represented by the type representation [s] is a
 * subtype of the type represented by the type representation [t].
 *
 * See the comment in the beginning of this file for a description of type
 * representations.
 */
bool isSubtype(var s, var t) {
  // Subtyping is reflexive.
  if (isIdentical(s, t)) return true;
  // If either type is dynamic, [s] is a subtype of [t].
  if (isNull(s) || isNull(t)) return true;
  if (hasField(t, '${JS_FUNCTION_TYPE_TAG()}')) {
    if (hasNoField(s, '${JS_FUNCTION_TYPE_TAG()}')) {
      var signatureName =
          '${JS_OPERATOR_IS_PREFIX()}_${getField(t, JS_FUNCTION_TYPE_TAG())}';
      if (hasField(s, signatureName)) return true;
      var targetSignatureFunction = getField(s, '${JS_SIGNATURE_NAME()}');
      if (isNull(targetSignatureFunction)) return false;
      s = invokeOn(targetSignatureFunction, s, null);
    }
    return isFunctionSubtype(s, t);
  }
  // Check function types against the Function class.
  if (getConstructorName(t) == JS_FUNCTION_CLASS_NAME() &&
      hasField(s, '${JS_FUNCTION_TYPE_TAG()}')) {
    return true;
  }
  // Get the object describing the class and check for the subtyping flag
  // constructed from the type of [t].
  var typeOfS = isJsArray(s) ? getIndex(s, 0) : s;
  var typeOfT = isJsArray(t) ? getIndex(t, 0) : t;
  // Check for a subtyping flag.
  var name = runtimeTypeToString(typeOfT);
  // Get the necessary substitution of the type arguments, if there is one.
  var substitution;
  if (isNotIdentical(typeOfT, typeOfS)) {
    var test = '${JS_OPERATOR_IS_PREFIX()}${name}';
    if (hasNoField(typeOfS, test)) return false;
    var field = '${JS_OPERATOR_AS_PREFIX()}${runtimeTypeToString(typeOfT)}';
    substitution = getField(typeOfS, field);
  }
  // The class of [s] is a subclass of the class of [t].  If [s] has no type
  // arguments and no substitution, it is used as raw type.  If [t] has no
  // type arguments, it used as a raw type.  In both cases, [s] is a subtype
  // of [t].
  if ((!isJsArray(s) && isNull(substitution)) || !isJsArray(t)) {
    return true;
  }
  // Recursively check the type arguments.
  return checkArguments(substitution, getArguments(s), getArguments(t));
}

bool isAssignable(var s, var t) {
  return isSubtype(s, t) || isSubtype(t, s);
}

/**
 * If [allowShorter] is [:true:], [t] is allowed to be shorter than [s].
 */
bool areAssignable(List s, List t, bool allowShorter) {
  // Both lists are empty and thus equal.
  if (isNull(t) && isNull(s)) return true;
  // [t] is empty (and [s] is not) => only OK if [allowShorter].
  if (isNull(t)) return allowShorter;
  // [s] is empty (and [t] is not) => [s] is not longer or equal to [t].
  if (isNull(s)) return false;

  assert(isJsArray(s));
  assert(isJsArray(t));

  int sLength = getLength(s);
  int tLength = getLength(t);
  if (allowShorter) {
    if (sLength < tLength) return false;
  } else {
    if (sLength != tLength) return false;
  }

  for (int i = 0; i < tLength; i++) {
    if (!isAssignable(getIndex(s, i), getIndex(t, i))) {
      return false;
    }
  }
  return true;
}

bool areAssignableMaps(var s, var t) {
  if (isNull(t)) return true;
  if (isNull(s)) return false;

  assert(isJsObject(s));
  assert(isJsObject(t));

  List names =
      JSArray.markFixedList(JS('', 'Object.getOwnPropertyNames(#)', t));
  for (int i = 0; i < names.length; i++) {
    var name = names[i];
    if (JS('bool', '!Object.hasOwnProperty.call(#, #)', s, name)) {
      return false;
    }
    var tType = JS('', '#[#]', t, name);
    var sType = JS('', '#[#]', s, name);
    if (!isAssignable(tType, sType)) return false;
  }
  return true;
}

bool isFunctionSubtype(var s, var t) {
  assert(hasField(t, '${JS_FUNCTION_TYPE_TAG()}'));
  if (hasNoField(s, '${JS_FUNCTION_TYPE_TAG()}')) return false;
  if (hasField(s, '${JS_FUNCTION_TYPE_VOID_RETURN_TAG()}')) {
    if (hasNoField(t, '${JS_FUNCTION_TYPE_VOID_RETURN_TAG()}') &&
        hasField(t, '${JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}')) {
      return false;
    }
  } else if (hasNoField(t, '${JS_FUNCTION_TYPE_VOID_RETURN_TAG()}')) {
    var sReturnType = getField(s, '${JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}');
    var tReturnType = getField(t, '${JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}');
    if (!isAssignable(sReturnType, tReturnType)) return false;
  }
  var sParameterTypes =
      getField(s, '${JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()}');
  var tParameterTypes =
      getField(t, '${JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()}');

  var sOptionalParameterTypes =
      getField(s, '${JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()}');
  var tOptionalParameterTypes =
      getField(t, '${JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()}');

  int sParametersLen =
      isNotNull(sParameterTypes) ? getLength(sParameterTypes) : 0;
  int tParametersLen =
      isNotNull(tParameterTypes) ? getLength(tParameterTypes) : 0;

  int sOptionalParametersLen = isNotNull(sOptionalParameterTypes)
      ? getLength(sOptionalParameterTypes) : 0;
  int tOptionalParametersLen = isNotNull(tOptionalParameterTypes)
      ? getLength(tOptionalParameterTypes) : 0;

  if (sParametersLen > tParametersLen) {
    // Too many required parameters in [s].
    return false;
  }
  if (sParametersLen + sOptionalParametersLen <
      tParametersLen + tOptionalParametersLen) {
    // Too few required and optional parameters in [s].
    return false;
  }
  if (sParametersLen == tParametersLen) {
    // Simple case: Same number of required parameters.
    if (!areAssignable(sParameterTypes, tParameterTypes, false)) return false;
    if (!areAssignable(sOptionalParameterTypes,
                       tOptionalParameterTypes, true)) {
      return false;
    }
  } else {
    // Complex case: Optional parameters of [s] for required parameters of [t].
    int pos = 0;
    // Check all required parameters of [s].
    for (; pos < sParametersLen; pos++) {
      if (!isAssignable(getIndex(sParameterTypes, pos),
                        getIndex(tParameterTypes, pos))) {
        return false;
      }
    }
    int sPos = 0;
    int tPos = pos;
    // Check the remaining parameters of [t] with the first optional parameters
    // of [s].
    for (; tPos < tParametersLen ; sPos++, tPos++) {
      if (!isAssignable(getIndex(sOptionalParameterTypes, sPos),
                        getIndex(tParameterTypes, tPos))) {
        return false;
      }
    }
    tPos = 0;
    // Check the optional parameters of [t] with the remaining optional
    // parameters of [s]:
    for (; tPos < tOptionalParametersLen ; sPos++, tPos++) {
      if (!isAssignable(getIndex(sOptionalParameterTypes, sPos),
                        getIndex(tOptionalParameterTypes, tPos))) {
        return false;
      }
    }
  }

  var sNamedParameters =
      getField(s, '${JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()}');
  var tNamedParameters =
      getField(t, '${JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()}');
  return areAssignableMaps(sNamedParameters, tNamedParameters);
}

/**
 * Calls the JavaScript [function] with the [arguments] with the global scope
 * as the [:this:] context.
 */
invoke(var function, var arguments) => invokeOn(function, null, arguments);

/**
 * Calls the JavaScript [function] with the [arguments] with [receiver] as the
 * [:this:] context.
 */
Object invokeOn(function, receiver, arguments) {
  assert(isJsFunction(function));
  assert(isNull(arguments) || isJsArray(arguments));
  return JS('var', r'#.apply(#, #)', function, receiver, arguments);
}

/// Calls the property [name] on the JavaScript [object].
call(var object, String name) => JS('var', r'#[#]()', object, name);

/// Returns the property [name] of the JavaScript object [object].
getField(var object, String name) => JS('var', r'#[#]', object, name);

/// Returns the property [index] of the JavaScript array [array].
getIndex(var array, int index) {
  assert(isJsArray(array));
  return JS('var', r'#[#]', array, index);
}

/// Returns the length of the JavaScript array [array].
int getLength(var array) {
  assert(isJsArray(array));
  return JS('int', r'#.length', array);
}

/// Returns whether [value] is a JavaScript array.
bool isJsArray(var value) {
  return value is JSArray;
}

hasField(var object, var name) => JS('bool', r'# in #', name, object);

hasNoField(var object, var name) => !hasField(object, name);

/// Returns [:true:] if [o] is a JavaScript function.
bool isJsFunction(var o) => JS('bool', r'typeof # == "function"', o);

/// Returns [:true:] if [o] is a JavaScript object.
bool isJsObject(var o) => JS('bool', r"typeof # == 'object'", o);

/**
 * Returns [:true:] if [o] is equal to [:null:], that is either [:null:] or
 * [:undefined:]. We use this helper to avoid generating code under the invalid
 * assumption that [o] is a Dart value.
 */
bool isNull(var o) => JS('bool', '# == null', o);

/**
 * Returns [:true:] if [o] is not equal to [:null:], that is neither [:null:]
 * nor [:undefined:].  We use this helper to avoid generating code under the
 * invalid assumption that [o] is a Dart value.
 */
bool isNotNull(var o) => JS('bool', '# != null', o);

/**
 * Returns [:true:] if the JavaScript values [s] and [t] are identical. We use
 * this helper to avoid generating code under the invalid assumption that [s]
 * and [t] are Dart values.
 */
bool isIdentical(var s, var t) => JS('bool', '# === #', s, t);

/**
 * Returns [:true:] if the JavaScript values [s] and [t] are not identical. We
 * use this helper to avoid generating code under the invalid assumption that
 * [s] and [t] are Dart values.
 */
bool isNotIdentical(var s, var t) => JS('bool', '# !== #', s, t);
