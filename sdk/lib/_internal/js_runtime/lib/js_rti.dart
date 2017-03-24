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
 *  2) a JavaScript array: the first entry is of type 1 and contains the
 *     subtyping flags and the substitution of the type and the rest of the
 *     array are the type arguments.
 *  3) `null`: the dynamic type.
 *  4) a JavaScript object representing the function type. For instance, it has
 *     the form  {ret: rti, args: [rti], opt: [rti], named: {name: rti}} for a
 *     function with a return type, regular, optional and named arguments.
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
 *     a list expression. The function may also return null, which is equivalent
 *     to an array containing only null values.
 */

part of _js_helper;

Type createRuntimeType(String name) {
  // Use a 'JS' cast to String.  Since this is registered as used by the
  // backend, type inference assumes the worst (name is dynamic).
  return new TypeImpl(JS('String', '#', name));
}

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
    return (other is TypeImpl) && _typeName == other._typeName;
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
 * Sets the runtime type information on [target]. [rti] is a type
 * representation of type 4 or 5, that is, either a JavaScript array or
 * `null`.
 */
// Don't inline.  Let the JS engine inline this.  The call expression is much
// more compact that the inlined expansion.
// TODO(sra): For most objects it would be better to initialize the type info as
// a field in the constructor: http://dartbug.com/22676 .
@NoInline()
Object setRuntimeTypeInfo(Object target, var rti) {
  assert(rti == null || isJsArray(rti));
  String rtiName = JS_GET_NAME(JsGetName.RTI_NAME);
  JS('var', r'#[#] = #', target, rtiName, rti);
  return target;
}

/**
 * Returns the runtime type information of [target]. The returned value is a
 * list of type representations for the type arguments.
 */
getRuntimeTypeInfo(Object target) {
  if (target == null) return null;
  String rtiName = JS_GET_NAME(JsGetName.RTI_NAME);
  return JS('var', r'#[#]', target, rtiName);
}

/**
 * Returns the type arguments of [target] as an instance of [substitutionName].
 */
getRuntimeTypeArguments(target, substitutionName) {
  var substitution = getField(
      target, '${JS_GET_NAME(JsGetName.OPERATOR_AS_PREFIX)}$substitutionName');
  return substitute(substitution, getRuntimeTypeInfo(target));
}

/**
 * Returns the [index]th type argument of [target] as an instance of
 * [substitutionName].
 */
@NoThrows()
@NoSideEffects()
@NoInline()
getRuntimeTypeArgument(Object target, String substitutionName, int index) {
  var arguments = getRuntimeTypeArguments(target, substitutionName);
  return arguments == null ? null : getIndex(arguments, index);
}

@NoThrows()
@NoSideEffects()
@NoInline()
getTypeArgumentByIndex(Object target, int index) {
  var rti = getRuntimeTypeInfo(target);
  return rti == null ? null : getIndex(rti, index);
}

/**
 * Retrieves the class name from type information stored on the constructor
 * of [object].
 */
String getClassName(var object) {
  return rawRtiToJsConstructorName(getRawRuntimeType(getInterceptor(object)));
}

/**
 * Creates the string representation for the type representation [rti]
 * of type 4, the JavaScript array, where the first element represents the class
 * and the remaining elements represent the type arguments.
 */
String getRuntimeTypeAsString(var rti, {String onTypeVariable(int i)}) {
  assert(isJsArray(rti));
  String className = rawRtiToJsConstructorName(getIndex(rti, 0));
  return '$className${joinArguments(rti, 1, onTypeVariable: onTypeVariable)}';
}

/**
 * Returns a human-readable representation of the type representation [rti].
 */
String runtimeTypeToString(var rti, {String onTypeVariable(int i)}) {
  if (rti == null) {
    return 'dynamic';
  }
  if (isJsArray(rti)) {
    // A list representing a type with arguments.
    return getRuntimeTypeAsString(rti, onTypeVariable: onTypeVariable);
  }
  if (isJsFunction(rti)) {
    // A reference to the constructor.
    return rawRtiToJsConstructorName(rti);
  }
  if (rti is int) {
    return '${onTypeVariable == null ? rti : onTypeVariable(rti)}';
  }
  String functionPropertyName = JS_GET_NAME(JsGetName.FUNCTION_TYPE_TAG);
  if (JS('bool', 'typeof #[#] != "undefined"', rti, functionPropertyName)) {
    // If the RTI has typedef equivalence info (via mirrors), use that since the
    // mirrors helpers will re-parse the generated string.

    String typedefPropertyName = JS_GET_NAME(JsGetName.TYPEDEF_TAG);
    var typedefInfo = JS('', '#[#]', rti, typedefPropertyName);
    if (typedefInfo != null) {
      return runtimeTypeToString(typedefInfo, onTypeVariable: onTypeVariable);
    }
    return _functionRtiToString(rti, onTypeVariable);
  }
  // We should not get here.
  return 'unknown-reified-type';
}

String _functionRtiToString(var rti, String onTypeVariable(int i)) {
  String returnTypeText;
  String voidTag = JS_GET_NAME(JsGetName.FUNCTION_TYPE_VOID_RETURN_TAG);
  if (JS('bool', '!!#[#]', rti, voidTag)) {
    returnTypeText = 'void';
  } else {
    String returnTypeTag = JS_GET_NAME(JsGetName.FUNCTION_TYPE_RETURN_TYPE_TAG);
    var returnRti = JS('', '#[#]', rti, returnTypeTag);
    returnTypeText =
        runtimeTypeToString(returnRti, onTypeVariable: onTypeVariable);
  }

  String argumentsText = '';
  String sep = '';

  String requiredParamsTag =
      JS_GET_NAME(JsGetName.FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG);
  bool hasArguments = JS('bool', '# in #', requiredParamsTag, rti);
  if (hasArguments) {
    List arguments = JS('JSFixedArray', '#[#]', rti, requiredParamsTag);
    for (var argument in arguments) {
      argumentsText += sep;
      argumentsText +=
          runtimeTypeToString(argument, onTypeVariable: onTypeVariable);
      sep = ', ';
    }
  }

  String optionalParamsTag =
      JS_GET_NAME(JsGetName.FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG);
  bool hasOptionalArguments = JS('bool', '# in #', optionalParamsTag, rti);
  if (hasOptionalArguments) {
    List optionalArguments = JS('JSFixedArray', '#[#]', rti, optionalParamsTag);
    argumentsText += '$sep[';
    sep = '';
    for (var argument in optionalArguments) {
      argumentsText += sep;
      argumentsText +=
          runtimeTypeToString(argument, onTypeVariable: onTypeVariable);
      sep = ', ';
    }
    argumentsText += ']';
  }

  String namedParamsTag =
      JS_GET_NAME(JsGetName.FUNCTION_TYPE_NAMED_PARAMETERS_TAG);
  bool hasNamedArguments = JS('bool', '# in #', namedParamsTag, rti);
  if (hasNamedArguments) {
    var namedArguments = JS('', '#[#]', rti, namedParamsTag);
    argumentsText += '$sep{';
    sep = '';
    for (String name in extractKeys(namedArguments)) {
      argumentsText += sep;
      argumentsText += runtimeTypeToString(JS('', '#[#]', namedArguments, name),
          onTypeVariable: onTypeVariable);
      argumentsText += ' $name';
      sep = ', ';
    }
    argumentsText += '}';
  }

  // TODO(sra): Below is the same format as the VM. Change to:
  //
  //     '${returnTypeText} Function(${argumentsText})';
  //
  return '(${argumentsText}) => ${returnTypeText}';
}

/**
 * Creates a comma-separated string of human-readable representations of the
 * type representations in the JavaScript array [types] starting at index
 * [startIndex].
 */
String joinArguments(var types, int startIndex,
    {String onTypeVariable(int i)}) {
  if (types == null) return '';
  assert(isJsArray(types));
  bool firstArgument = true;
  bool allDynamic = true;
  StringBuffer buffer = new StringBuffer('');
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
  if (object is Closure) {
    // This excludes classes that implement Function via a `call` method, but
    // includes classes generated to represent closures in closure conversion.
    var functionRti = extractFunctionTypeObjectFrom(object);
    if (functionRti != null) {
      return runtimeTypeToString(functionRti);
    }
  }
  String className = getClassName(object);
  if (object == null) return className;
  String rtiName = JS_GET_NAME(JsGetName.RTI_NAME);
  var rti = JS('var', r'#[#]', object, rtiName);
  return "$className${joinArguments(rti, 0)}";
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
  if (substitution == null) return arguments;
  assert(isJsFunction(substitution));
  assert(arguments == null || isJsArray(arguments));
  substitution = invoke(substitution, arguments);
  if (substitution == null) return null;
  if (isJsArray(substitution)) {
    // Substitutions are generated too late to mark Array as used, so use a
    // tautological JS 'cast' to mark Array as used. This is needed only in
    // some tiny tests where the substition is the only thing that creates an
    // Array.
    return JS('JSArray', '#', substitution);
  }
  if (isJsFunction(substitution)) {
    // TODO(johnniwinther): Check if this is still needed.
    return invoke(substitution, arguments);
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
  // When we read the field and it is not there, [isSubclass] will be `null`.
  if (isSubclass == null) return false;
  // Should the asField function be passed the receiver?
  var substitution = getField(interceptor, asField);
  return checkArguments(substitution, arguments, checks);
}

/// Returns the field's type name.
///
/// In minified mode, uses the unminified names if available.
String computeTypeName(String isField, List arguments) {
  // Extract the class name from the is field and append the textual
  // representation of the type arguments.
  return Primitives.formatType(
      isCheckPropertyToJsConstructorName(isField), arguments);
}

Object subtypeCast(Object object, String isField, List checks, String asField) {
  if (object == null) return object;
  if (checkSubtype(object, isField, checks, asField)) return object;
  String actualType = Primitives.objectTypeName(object);
  String typeName = computeTypeName(isField, checks);
  // TODO(johnniwinther): Move type lookup to [CastErrorImplementation] to
  // align with [TypeErrorImplementation].
  throw new CastErrorImplementation(actualType, typeName);
}

Object assertSubtype(
    Object object, String isField, List checks, String asField) {
  if (object == null) return object;
  if (checkSubtype(object, isField, checks, asField)) return object;
  String typeName = computeTypeName(isField, checks);
  throw new TypeErrorImplementation(object, typeName);
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
 * [s] and [t] are either `null` or JavaScript arrays of type representations,
 * A `null` argument is interpreted as the arguments of a raw type, that is a
 * list of `dynamic`. If [s] and [t] are JavaScript arrays they must be of the
 * same length.
 *
 * See the comment in the beginning of this file for a description of type
 * representations.
 */
bool areSubtypes(var s, var t) {
  // `null` means a raw type.
  if (s == null || t == null) return true;

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
 * Returns `true` if the runtime type representation [type] is a supertype of
 * [Null].
 */
bool isSupertypeOfNull(var type) {
  // `null` means `dynamic`.
  return type == null || isDartObjectTypeRti(type) || isNullTypeRti(type);
}

/**
 * Tests whether the Dart object [o] is a subtype of the runtime type
 * representation [t].
 *
 * See the comment in the beginning of this file for a description of type
 * representations.
 */
bool checkSubtypeOfRuntimeType(o, t) {
  if (o == null) return isSupertypeOfNull(t);
  if (t == null) return true;
  // Get the runtime type information from the object here, because we may
  // overwrite o with the interceptor below.
  var rti = getRuntimeTypeInfo(o);
  o = getInterceptor(o);
  var type = getRawRuntimeType(o);
  if (rti != null) {
    // If the type has type variables (that is, `rti != null`), make a copy of
    // the type arguments and insert [o] in the first position to create a
    // compound type representation.
    rti = JS('JSExtendableArray', '#.slice()', rti); // Make a copy.
    JS('', '#.splice(0, 0, #)', rti, type); // Insert type at position 0.
    type = rti;
  }
  if (isDartFunctionType(t)) {
    // Functions are treated specially and have their type information stored
    // directly in the instance.
    var targetSignatureFunction =
        getField(o, '${JS_GET_NAME(JsGetName.SIGNATURE_NAME)}');
    if (targetSignatureFunction == null) return false;
    type = invokeOn(targetSignatureFunction, o, null);
    return isFunctionSubtype(type, t);
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
 * JavaScript array or `null`.
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
 *
 * The arguments [s] and [t] must be types, usually represented by the
 * constructor of the class, or an array (for generic types).
 */
bool isSubtype(var s, var t) {
  // Subtyping is reflexive.
  if (isIdentical(s, t)) return true;
  // If either type is dynamic, [s] is a subtype of [t].
  if (s == null || t == null) return true;
  if (isNullType(s)) return true;
  if (isDartFunctionType(t)) {
    return isFunctionSubtype(s, t);
  }
  // Check function types against the Function class and the Object class.
  if (isDartFunctionType(s)) {
    return isDartFunctionTypeRti(t) || isDartObjectTypeRti(t);
  }

  // Get the object describing the class and check for the subtyping flag
  // constructed from the type of [t].
  var typeOfS = isJsArray(s) ? getIndex(s, 0) : s;
  var typeOfT = isJsArray(t) ? getIndex(t, 0) : t;

  // Check for a subtyping flag.
  // Get the necessary substitution of the type arguments, if there is one.
  var substitution;
  if (isNotIdentical(typeOfT, typeOfS)) {
    String typeOfTString = runtimeTypeToString(typeOfT);
    if (!builtinIsSubtype(typeOfS, typeOfTString)) {
      return false;
    }
    var typeOfSPrototype = JS('', '#.prototype', typeOfS);
    var field = '${JS_GET_NAME(JsGetName.OPERATOR_AS_PREFIX)}${typeOfTString}';
    substitution = getField(typeOfSPrototype, field);
  }
  // The class of [s] is a subclass of the class of [t].  If [s] has no type
  // arguments and no substitution, it is used as raw type.  If [t] has no
  // type arguments, it used as a raw type.  In both cases, [s] is a subtype
  // of [t].
  if ((!isJsArray(s) && substitution == null) || !isJsArray(t)) {
    return true;
  }
  // Recursively check the type arguments.
  return checkArguments(substitution, getArguments(s), getArguments(t));
}

bool isAssignable(var s, var t) {
  return isSubtype(s, t) || isSubtype(t, s);
}

/**
 * If [allowShorter] is `true`, [t] is allowed to be shorter than [s].
 */
bool areAssignable(List s, List t, bool allowShorter) {
  // Both lists are empty and thus equal.
  if (t == null && s == null) return true;
  // [t] is empty (and [s] is not) => only OK if [allowShorter].
  if (t == null) return allowShorter;
  // [s] is empty (and [t] is not) => [s] is not longer or equal to [t].
  if (s == null) return false;

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
  if (t == null) return true;
  if (s == null) return false;

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
  assert(isDartFunctionType(t));
  if (!isDartFunctionType(s)) return false;
  var voidReturnTag = JS_GET_NAME(JsGetName.FUNCTION_TYPE_VOID_RETURN_TAG);
  var returnTypeTag = JS_GET_NAME(JsGetName.FUNCTION_TYPE_RETURN_TYPE_TAG);
  if (hasField(s, voidReturnTag)) {
    if (hasNoField(t, voidReturnTag) && hasField(t, returnTypeTag)) {
      return false;
    }
  } else if (hasNoField(t, voidReturnTag)) {
    var sReturnType = getField(s, returnTypeTag);
    var tReturnType = getField(t, returnTypeTag);
    if (!isAssignable(sReturnType, tReturnType)) return false;
  }
  var requiredParametersTag =
      JS_GET_NAME(JsGetName.FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG);
  var sParameterTypes = getField(s, requiredParametersTag);
  var tParameterTypes = getField(t, requiredParametersTag);

  var optionalParametersTag =
      JS_GET_NAME(JsGetName.FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG);
  var sOptionalParameterTypes = getField(s, optionalParametersTag);
  var tOptionalParameterTypes = getField(t, optionalParametersTag);

  int sParametersLen = sParameterTypes != null ? getLength(sParameterTypes) : 0;
  int tParametersLen = tParameterTypes != null ? getLength(tParameterTypes) : 0;

  int sOptionalParametersLen =
      sOptionalParameterTypes != null ? getLength(sOptionalParameterTypes) : 0;
  int tOptionalParametersLen =
      tOptionalParameterTypes != null ? getLength(tOptionalParameterTypes) : 0;

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
    if (!areAssignable(
        sOptionalParameterTypes, tOptionalParameterTypes, true)) {
      return false;
    }
  } else {
    // Complex case: Optional parameters of [s] for required parameters of [t].
    int pos = 0;
    // Check all required parameters of [s].
    for (; pos < sParametersLen; pos++) {
      if (!isAssignable(
          getIndex(sParameterTypes, pos), getIndex(tParameterTypes, pos))) {
        return false;
      }
    }
    int sPos = 0;
    int tPos = pos;
    // Check the remaining parameters of [t] with the first optional parameters
    // of [s].
    for (; tPos < tParametersLen; sPos++, tPos++) {
      if (!isAssignable(getIndex(sOptionalParameterTypes, sPos),
          getIndex(tParameterTypes, tPos))) {
        return false;
      }
    }
    tPos = 0;
    // Check the optional parameters of [t] with the remaining optional
    // parameters of [s]:
    for (; tPos < tOptionalParametersLen; sPos++, tPos++) {
      if (!isAssignable(getIndex(sOptionalParameterTypes, sPos),
          getIndex(tOptionalParameterTypes, tPos))) {
        return false;
      }
    }
  }

  var namedParametersTag =
      JS_GET_NAME(JsGetName.FUNCTION_TYPE_NAMED_PARAMETERS_TAG);
  var sNamedParameters = getField(s, namedParametersTag);
  var tNamedParameters = getField(t, namedParametersTag);
  return areAssignableMaps(sNamedParameters, tNamedParameters);
}

/**
 * Calls the JavaScript [function] with the [arguments] with the global scope
 * as the `this` context.
 */
invoke(var function, var arguments) => invokeOn(function, null, arguments);

/**
 * Calls the JavaScript [function] with the [arguments] with [receiver] as the
 * `this` context.
 */
Object invokeOn(function, receiver, arguments) {
  assert(isJsFunction(function));
  assert(arguments == null || isJsArray(arguments));
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

/// Returns `true` if [o] is a JavaScript function.
bool isJsFunction(var o) => JS('bool', r'typeof # == "function"', o);

/// Returns `true` if [o] is a JavaScript object.
bool isJsObject(var o) => JS('bool', r"typeof # == 'object'", o);

/**
 * Returns `true` if the JavaScript values [s] and [t] are identical. We use
 * this helper instead of [identical] because `identical` needs to merge
 * `null` and `undefined` (which we can avoid).
 */
bool isIdentical(var s, var t) => JS('bool', '# === #', s, t);

/**
 * Returns `true` if the JavaScript values [s] and [t] are not identical. We use
 * this helper instead of [identical] because `identical` needs to merge
 * `null` and `undefined` (which we can avoid).
 */
bool isNotIdentical(var s, var t) => JS('bool', '# !== #', s, t);
