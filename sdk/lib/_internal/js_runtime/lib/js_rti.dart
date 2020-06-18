// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This part contains helpers for supporting runtime type information.
///
/// The helper use a mixture of Dart and JavaScript objects. To indicate which
/// is used where we adopt the scheme of using explicit type annotation for Dart
/// objects and 'var' or omitted return type for JavaScript objects.
///
/// Since bool, int, and String values are represented by the same JavaScript
/// primitives, type annotations are used for these types in all cases.
///
/// Several methods use a common JavaScript encoding of runtime type
/// information.  This encoding is referred to as the type representation which
/// is one of these:
///  1) a JavaScript constructor for a class C: the represented type is the raw
///     type C.
///  2) a JavaScript array: the first entry is of type 1 and contains the
///     subtyping flags and the substitution of the type and the rest of the
///     array are the type arguments.
///  3) `null`: the dynamic type.
///  4) a JavaScript object representing the function type. For instance, it has
///     the form {ret: rti, args: [rti], opt: [rti], named: {name: rti}} for a
///     function with a return type, regular, optional and named arguments.
///     Generic function types have a 'bounds' property.
///
/// To check subtype relations between generic classes we use a JavaScript
/// expression that describes the necessary substitution for type arguments.
/// Such a substitution expression can be:
///  1) `null`, if no substituted check is necessary, because the
///     type variables are the same or there are no type variables in the class
///     that is checked for.
///  2) A list expression describing the type arguments to be used in the
///     subtype check, if the type arguments to be used in the check do not
///     depend on the type arguments of the object.
///  3) A function mapping the type variables of the object to be checked to a
///     list expression. The function may also return null, which is equivalent
///     to an array containing only null values.

part of _js_helper;

/// Sets the runtime type information on [target]. [rti] is a type
/// representation of type 4 or 5, that is, either a JavaScript array or `null`.
///
/// Called from generated code.
///
/// This is used only for marking JavaScript Arrays (JSArray) with the element
/// type.
// Don't inline.  Let the JS engine inline this.  The call expression is much
// more compact that the inlined expansion.
@pragma('dart2js:noInline')
Object setRuntimeTypeInfo(Object target, var rti) {
  assert(rti != null);
  var rtiProperty = JS_EMBEDDED_GLOBAL('', ARRAY_RTI_PROPERTY);
  JS('var', r'#[#] = #', target, rtiProperty, rti);
  return target;
}

Type getRuntimeType(var object) {
  return newRti.getRuntimeType(object);
}

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
