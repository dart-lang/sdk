// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the association between runtime objects and
/// runtime types.
part of dart._runtime;

///
/// Runtime type information.  This module defines the mapping from
/// runtime objects to their runtime type information.  See the types
/// module for the definition of how type information is represented.
///
/// Runtime objects fall into four main categories:
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
///

///
///Tag a closure with a type, using one of three forms:
/// dart.fn(cls) marks cls has having no optional or named
///  parameters, with all argument and return types as dynamic
/// dart.fn(cls, func) marks cls with the lazily computed
///  runtime type as computed by func()
/// dart.fn(cls, rType, argsT, extras) marks cls as having the
/// runtime type dart.functionType(rType, argsT, extras)
///
/// Note that since we are producing a type for a concrete function,
/// it is sound to use the definite arrow type.
///
fn(closure, @rest args) => JS('', '''(() => {
  // Closure and a lazy type constructor
  if ($args.length == 1) {
    $defineLazyProperty($closure, $_runtimeType, {get : $args[0]});
    return $closure;
  }
  let t;
  if ($args.length == 0) {
    // No type arguments, it's all dynamic
    t = $definiteFunctionType(
      $dynamicR, Array($closure.length).fill($dynamicR));
  } else {
    // We're passed the piecewise components of the function type,
    // construct it.
    t = $definiteFunctionType.apply(null, $args);
  }
  tag($closure, t);
  return $closure;
})()''');

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
  // Lookup primitive (int/double/string)
  let result = $checkPrimitiveType($obj);
  if (result !== null) return result;

  // Lookup recorded type
  result = $obj.runtimeType;
  if (result) return result;

  return $_nonPrimitiveRuntimeType(obj);
})()''');

getFunctionType(obj) => JS('', '''(() => {
  // TODO(vsm): Encode this properly on the function for Dart-generated code.
  let args = Array($obj.length).fill($dynamicR);
  return $definiteFunctionType($bottom, args);
})()''');

///
/// Returns the runtime type of obj. This is the same as `obj.realRuntimeType`
/// but will not call an overridden getter.
///
/// Currently this will return null for non-Dart objects.
///
realRuntimeType(obj) => JS('', '''(() => {
  // Lookup primitive type
  let result = $checkPrimitiveType($obj);
  if (result !== null) return result;

  return $_nonPrimitiveRuntimeType(obj);
})()''');

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

LazyTagged(infoFn) => JS('', '''(() => {
  class _Tagged {
    get [$_runtimeType]() {return $infoFn();}
  }
  return _Tagged;
})()''');

read(value) => JS('', '''(() => {
  return $value[$_runtimeType];
})()''');

tag(value, info) => JS('', '''(() => {
  $value[$_runtimeType] = $info;
})()''');

tagComputed(value, compute) => JS('', '''(() => {
  $defineProperty($value, $_runtimeType, { get: $compute });
})()''');

tagMemoized(value, compute) => JS('', '''(() => {
  let cache = null;
  function getter() {
    if ($compute == null) return cache;
    cache = $compute();
    $compute = null;
    return cache;
  }
  $tagComputed($value, getter);
})()''');
