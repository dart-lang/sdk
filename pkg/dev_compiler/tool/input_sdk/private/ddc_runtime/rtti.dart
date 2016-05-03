// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the association between runtime objects and
/// runtime types.
part of dart._runtime;

/// Runtime type information.  This module defines the mapping from
/// runtime objects to their runtime type information.  See the types
/// module for the definition of how type information is represented.
///
/// There are two kinds of objects that represent "types" at runtime. A
/// "runtime type" contains all of the data needed to implement the runtime
/// type checking inserted by the compiler. These objects fall into four
/// categories:
///
///   - Things represented by javascript primitives, such as
///     null, numbers, booleans, strings, and symbols.  For these
///     we map directly from the javascript type (given by typeof)
///     to the appropriate class type from core, which serves as their
///     rtti.
///
///   - Functions, which are represented by javascript functions.
///     Representations of Dart functions always have a
///     _runtimeType property attached to them with the appropriate
///     rtti.
///
///   - Objects (instances) which are represented by instances of
///     javascript (ES6) classes.  Their types are given by their
///     classes, and the rtti is accessed by projecting out their
///     constructor field.
///
///   - Types objects, which are represented as described in the types
///     module.  Types always have a _runtimeType property attached to
///     them with the appropriate rtti.  The rtti for these is always
///     core.Type.  TODO(leafp): consider the possibility that we can
///     reliably recognize type objects and map directly to core.Type
///     rather than attaching this property everywhere.
///
/// The other kind of object representing a "type" is the instances of the
/// dart:core Type class. These are the user visible objects you get by calling
/// "runtimeType" on an object or using a class literal expression. These are
/// different from the above objects, and are created by calling `wrapType()`
/// on a runtime type.

/// Tag a closure with a type, using one of two forms:
///
/// `dart.fn(cls)` marks cls has having no optional or named
/// parameters, with all argument and return types as dynamic.
///
/// `dart.fn(cls, rType, argsT, extras)` marks cls as having the
/// runtime type dart.functionType(rType, argsT, extras).
///
/// Note that since we are producing a type for a concrete function,
/// it is sound to use the definite arrow type.
///
fn(closure, rType, argsT, extras) {
  var t;
  if (rType == null) {
    // No type arguments, it's all dynamic
    t = definiteFunctionType(
        dynamicR,
        JS('', 'Array(#.length).fill(#)', closure, dynamicR),
        JS('', 'void 0'));
  } else {
    // We're passed the piecewise components of the function type,
    // construct it.
    t = definiteFunctionType(rType, argsT, extras);
  }
  tag(closure, t);
  return closure;
}

lazyFn(closure, computeTypeParts) {
  tagLazy(closure, JS('', '''() => {
    let parts = #();
    return #(parts[0], parts[1], parts[2]);
  }''', computeTypeParts, definiteFunctionType));
  return closure;
}

// TODO(vsm): How should we encode the runtime type?
final _runtimeType = JS('', 'Symbol("_runtimeType")');

checkPrimitiveType(obj) => JS('', '''(() => {
  switch (typeof $obj) {
    case "undefined":
      return $Null;
    case "number":
      return Math.floor($obj) == $obj ? $int : $double;
    case "boolean":
      return $bool;
    case "string":
      return $String;
    case "symbol":
      return Symbol;
  }
  // Undefined is handled above. For historical reasons,
  // typeof null == "object" in JS.
  if ($obj === null) return $Null;
  return null;
})()''');

runtimeType(obj) => JS('', '''(() => {
  // Handle primitives where the method isn't on the object.
  let result = $checkPrimitiveType($obj);
  if (result !== null) return $wrapType(result);

  // Delegate to the actual method on the object.
  return $obj.runtimeType;
})()''');

getFunctionType(obj) => JS('', '''(() => {
  // TODO(vsm): Encode this properly on the function for Dart-generated code.
  let args = Array($obj.length).fill($dynamicR);
  return $definiteFunctionType($bottom, args);
})()''');

/// The base implementation of Object.runtimeType.
objectRuntimeType(obj) => wrapType(getReifiedType(obj));

/// Returns an the runtime representation of the type of obj.
///
/// The resulting object is used internally for runtime type checking. This is
/// different from the user-visible Type object returned by calling
/// `runtimeType` on some Dart object.
getReifiedType(obj) {
  var result = checkPrimitiveType(obj);
  if (result != null) return result;
  return _nonPrimitiveRuntimeType(obj);
}

_nonPrimitiveRuntimeType(obj) => JS('', '''(() => {
  // Lookup recorded *real* type (not user definable runtimeType)
  // TODO(vsm): Should we treat Dart and JS objects differently here?
  // E.g., we can check if obj instanceof core.Object to differentiate.
  let result = $obj[$_runtimeType];
  if (result) return result;

  // Lookup extension type
  result = $obj[$_extensionType];
  if (result) return result;

  // Fallback on constructor for class types
  result = $obj.constructor;
  if (result == Function) {
    // An undecorated Function should have come from
    // JavaScript.  Treat as untyped.
    return $jsobject;
  }
  return result;
})()''');

/// Given an internal runtime type object, wraps it in a `WrappedType` object
/// that implements the dart:core Type interface.
wrapType(type) {
  // If we've already wrapped this type once, use the previous wrapper. This
  // way, multiple references to the same type return an identical Type.
  if (JS('bool', '#.hasOwnProperty(#)', type, _typeObject)) {
    return JS('', '#[#]', type, _typeObject);
  }
  return JS('', '#[#] = new #(#)', type, _typeObject, WrappedType, type);
}

_getRuntimeType(value) => JS('', '#[#]', value, _runtimeType);

/// Tag the runtime type of [value] to be type [t].
void tag(value, t) {
  JS('', '#[#] = #', value, _runtimeType, t);
}

void tagComputed(value, compute) {
  JS('', '#(#, #, { get: # })', defineProperty, value, _runtimeType, compute);
}

void tagLazy(value, compute) {
  JS('', '#(#, #, { get: # })',
      defineLazyProperty, value, _runtimeType, compute);
}
