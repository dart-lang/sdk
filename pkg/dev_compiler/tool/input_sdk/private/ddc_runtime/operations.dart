// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines runtime operations on objects used by the code
/// generator.
part of dart._runtime;

_canonicalFieldName(obj, name, args, displayName) => JS('', '''(() => {
  $name = $canonicalMember($obj, $name);
  if ($name) return $name;
  // TODO(jmesserly): in the future we might have types that "overlay" Dart
  // methods while also exposing the full native API, e.g. dart:html vs
  // dart:dom. To support that we'd need to fall back to the normal name
  // if an extension method wasn't found.
  $throwNoSuchMethodFunc($obj, $displayName, $args);
})()''');

dload(obj, field) => JS('', '''(() => {
  $field = $_canonicalFieldName($obj, $field, [], $field);
  if ($hasMethod($obj, $field)) {
    return $bind($obj, $field);
  }
  // TODO(vsm): Implement NSM robustly.  An 'in' check breaks on certain
  // types.  hasOwnProperty doesn't chase the proto chain.
  // Also, do we want an NSM on regular JS objects?
  // See: https://github.com/dart-lang/dev_compiler/issues/169
  let result = $obj[$field];
  return result;
})()''');

dput(obj, field, value) => JS('', '''(() => {
  $field = $_canonicalFieldName($obj, $field, [$value], $field);
  // TODO(vsm): Implement NSM and type checks.
  // See: https://github.com/dart-lang/dev_compiler/issues/170
  $obj[$field] = $value;
  return $value;
})()''');

/// Check that a function of a given type can be applied to
/// actuals.
checkApply(type, actuals) => JS('', '''(() => {
  if ($actuals.length < $type.args.length) return false;
  let index = 0;
  for(let i = 0; i < $type.args.length; ++i) {
    if (!$instanceOfOrNull($actuals[i], $type.args[i])) return false;
    ++index;
  }
  if ($actuals.length == $type.args.length) return true;
  let extras = $actuals.length - $type.args.length;
  if ($type.optionals.length > 0) {
    if (extras > $type.optionals.length) return false;
    for(let i = 0, j=index; i < extras; ++i, ++j) {
      if (!$instanceOfOrNull($actuals[j], $type.optionals[i])) return false;
    }
    return true;
  }
  // TODO(leafp): We can't tell when someone might be calling
  // something expecting an optional argument with named arguments

  if (extras != 1) return false;
  // An empty named list means no named arguments
  if ($getOwnPropertyNames($type.named).length == 0) return false;
  let opts = $actuals[index];
  let names = $getOwnPropertyNames(opts);
  // Type is something other than a map
  if (names.length == 0) return false;
  for (var name of names) {
    if (!($hasOwnProperty.call($type.named, name))) {
      return false;
    }
    if (!$instanceOfOrNull(opts[name], $type.named[name])) return false;
  }
  return true;
})()''');


throwNoSuchMethod(obj, name, pArgs, nArgs, extras) => JS('', '''(() => {
  $throw_(new $NoSuchMethodError($obj, $name, $pArgs, $nArgs, $extras));
})()''');

throwNoSuchMethodFunc(obj, name, pArgs, opt_func) => JS('', '''(() => {
  if ($obj === void 0) $obj = $opt_func;
  $throwNoSuchMethod($obj, $name, $pArgs);
})()''');

checkAndCall(f, ftype, obj, args, name) => JS('', '''(() => {
  let originalFunction = $f;
  if (!($f instanceof Function)) {
    // We're not a function (and hence not a method either)
    // Grab the `call` method if it's not a function.
    if ($f != null) {
      $ftype = $getMethodType($f, 'call');
      $f = $f.call;
    }
    if (!($f instanceof Function)) {
      $throwNoSuchMethodFunc($obj, $name, $args, originalFunction);
    }
  }
  // If f is a function, but not a method (no method type)
  // then it should have been a function valued field, so
  // get the type from the function.
  if ($ftype === void 0) {
    $ftype = $read($f);
  }

  if (!$ftype) {
    // TODO(leafp): Allow JS objects to go through?
    // This includes the DOM.
    return $f.apply($obj, $args);
  }

  if ($checkApply($ftype, $args)) {
    return $f.apply($obj, $args);
  }

  // TODO(leafp): throw a type error (rather than NSM)
  // if the arity matches but the types are wrong.
  $throwNoSuchMethodFunc($obj, $name, $args, originalFunction);
})()''');

dcall(f, @rest args) => JS('', '''(() => {
  let ftype = $read($f);
  return $checkAndCall($f, ftype, void 0, $args, 'call');
})()''');

/// Shared code for dsend, dindex, and dsetindex. */
callMethod(obj, name, args, displayName) => JS('', '''(() => {
  let symbol = $_canonicalFieldName($obj, $name, $args, $displayName);
  let f = $obj != null ? $obj[symbol] : null;
  let ftype = $getMethodType($obj, $name);
  return $checkAndCall(f, ftype, $obj, $args, $displayName);
})()''');

dsend(obj, method, @rest args) => JS('', '''(() => {
  return $callMethod($obj, $method, $args, $method);
})()''');

dindex(obj, index) => JS('', '''(() => {
  return $callMethod($obj, 'get', [$index], '[]');
})()''');

dsetindex(obj, index, value) => JS('', '''(() => {
  $callMethod($obj, 'set', [$index, $value], '[]=');
  return $value;
})()''');

_ignoreTypeFailure(actual, type) => JS('', '''(() => {
  // TODO(vsm): Remove this hack ...
  // This is primarily due to the lack of generic methods,
  // but we need to triage all the types.
  if (isSubtype($type, $Iterable) && isSubtype($actual, $Iterable) ||
      isSubtype($type, $Future) && isSubtype($actual, $Future) ||
      isSubtype($type, $Map) && isSubtype($actual, $Map) ||
      isSubtype($type, $Function) && isSubtype($actual, $Function) ||
      isSubtype($type, $Stream) && isSubtype($actual, $Stream) ||
      isSubtype($type, $StreamSubscription) &&
          isSubtype($actual, $StreamSubscription)) {
    console.warn('Ignoring cast fail from ' + $typeName($actual) +
      ' to ' + $typeName($type));
    return true;
  }
  return false;
})()''');

strongInstanceOf(obj, type, ignoreFromWhiteList) => JS('', '''(() => {
  let actual = $realRuntimeType($obj);
  if ($isSubtype(actual, $type) || actual == $jsobject ||
      actual == $int && type == $double) return true;
  if ($ignoreFromWhiteList == void 0) return false;
  if ($isGroundType($type)) return false;
  if ($_ignoreTypeFailure(actual, $type)) return true;
  return false;
})()''');

instanceOfOrNull(obj, type) => JS('', '''(() => {
  if (($obj == null) || $strongInstanceOf($obj, $type, true)) return true;
  return false;
})()''');

instanceOf(obj, type) => JS('', '''(() => {
  if ($strongInstanceOf($obj, $type)) return true;
  // TODO(#296): This is perhaps too eager to throw a StrongModeError?
  // It will throw on <int>[] is List<String>.
  // TODO(vsm): We can statically detect many cases where this
  // check is unnecessary.
  if ($isGroundType($type)) return false;
  let actual = $realRuntimeType($obj);
  $throwStrongModeError('Strong mode is check failure: ' +
    $typeName(actual) + ' does not soundly subtype ' +
    $typeName($type));
})()''');

cast(obj, type) => JS('', '''(() => {
  // TODO(#296): This is perhaps too eager to throw a StrongModeError?
  // TODO(vsm): handle non-nullable types
  if ($instanceOfOrNull($obj, $type)) return $obj;
  let actual = $realRuntimeType($obj);
  if ($isGroundType($type)) $throwCastError(actual, $type);

  if ($_ignoreTypeFailure(actual, $type)) return $obj;

  $throwStrongModeError('Strong mode cast failure from ' +
    $typeName(actual) + ' to ' + $typeName($type));
})()''');

asInt(obj) => JS('', '''(() => {
  if ($obj == null) {
    return null;
  }
  if (Math.floor($obj) != $obj) {
    // Note: null will also be caught by this check
    $throwCastError($realRuntimeType($obj), $int);
  }
  return $obj;
})()''');

arity(f) => JS('', '''(() => {
  // TODO(jmesserly): need to parse optional params.
  // In ES6, length is the number of required arguments.
  return { min: $f.length, max: $f.length };
})()''');

equals(x, y) => JS('', '''(() => {
  if ($x == null || $y == null) return $x == $y;
  let eq = $x['=='];
  return eq ? eq.call($x, $y) : $x === $y;
})()''');

/// Checks that `x` is not null or undefined. */
notNull(x) => JS('', '''(() => {
  if ($x == null) $throwNullValueError();
  return $x;
})()''');

///
/// Creates a dart:collection LinkedHashMap.
///
/// For a map with string keys an object literal can be used, for example
/// `map({'hi': 1, 'there': 2})`.
///
/// Otherwise an array should be used, for example `map([1, 2, 3, 4])` will
/// create a map with keys [1, 3] and values [2, 4]. Each key-value pair
/// should be adjacent entries in the array.
///
/// For a map with no keys the function can be called with no arguments, for
/// example `map()`.
///
// TODO(jmesserly): this could be faster
// TODO(jmesserly): we can use default values `= dynamic` once #417 is fixed.
// TODO(jmesserly): move this to classes for consistentcy with list literals?
map(values, [K, V]) => JS('', '''(() => {
  if ($K == null) $K = $dynamicR;
  if ($V == null) $V = $dynamicR;
  let map = ${getGenericClass(LinkedHashMap)}($K, $V).new();
  if (Array.isArray($values)) {
    for (let i = 0, end = $values.length - 1; i < end; i += 2) {
      let key = $values[i];
      let value = $values[i + 1];
      map.set(key, value);
    }
  } else if (typeof $values === 'object') {
    for (let key of $getOwnPropertyNames($values)) {
      map.set(key, $values[key]);
    }
  }
  return map;
})()''');

@JSExportName('assert')
assert_(condition) => JS('', '''(() => {
  if (!$condition) $throwAssertionError();
})()''');

final _stack = JS('', 'new WeakMap()');
@JSExportName('throw')
throw_(obj) => JS('', '''(() => {
  if ($obj != null && (typeof $obj == 'object' || typeof $obj == 'function')) {
    // TODO(jmesserly): couldn't we store the most recent stack in a single
    // variable? There should only be one active stack trace. That would
    // allow it to work for things like strings and numbers.
    $_stack.set($obj, new Error());
  }
  throw $obj;
})()''');

getError(exception) => JS('', '''(() => {
  var stack = $_stack.get($exception);
  return stack !== void 0 ? stack : $exception;
})()''');

// This is a utility function: it is only intended to be called from dev
// tools.
stackPrint(exception) => JS('', '''(() => {
  var error = $getError($exception);
  console.log(error.stack ? error.stack : 'No stack trace for: ' + error);
})()''');

stackTrace(exception) => JS('', '''(() => {
  var error = $getError($exception);
  return $getTraceFromException(error);
})()''');

///
/// Implements a sequence of .? operations.
///
/// Will call each successive callback, unless one returns null, which stops
/// the sequence.
///
nullSafe(obj, @rest callbacks) => JS('', '''(() => {
  if ($obj == null) return $obj;
  for (const callback of $callbacks) {
    $obj = callback($obj);
    if ($obj == null) break;
  }
  return $obj;
})()''');

final _value = JS('', 'Symbol("_value")');
///
/// Looks up a sequence of [keys] in [map], recursively, and
/// returns the result. If the value is not found, [valueFn] will be called to
/// add it. For example:
///
///     let map = new Map();
///     putIfAbsent(map, [1, 2, 'hi ', 'there '], () => 'world');
///
/// ... will create a Map with a structure like:
///
///     { 1: { 2: { 'hi ': { 'there ': 'world' } } } }
///
multiKeyPutIfAbsent(map, keys, valueFn) => JS('', '''(() => {
  for (let k of $keys) {
    let value = $map.get(k);
    if (!value) {
      // TODO(jmesserly): most of these maps are very small (e.g. 1 item),
      // so it may be worth optimizing for that.
      $map.set(k, value = new Map());
    }
    $map = value;
  }
  if ($map.has($_value)) return $map.get($_value);
  let value = $valueFn();
  $map.set($_value, value);
  return value;
})()''');

/// The global constant table. */
final constants = JS('', 'new Map()');

///
/// Canonicalize a constant object.
///
/// Preconditions:
/// - `obj` is an objects or array, not a primitive.
/// - nested values of the object are themselves already canonicalized.
///
@JSExportName('const')
const_(obj) => JS('', '''(() => {
  let objectKey = [$realRuntimeType($obj)];
  // TODO(jmesserly): there's no guarantee in JS that names/symbols are
  // returned in the same order.
  //
  // We could probably get the same order if we're judicious about
  // initializing fields in a consistent order across all const constructors.
  // Alternatively we need a way to sort them to make consistent.
  //
  // Right now we use the (name,value) pairs in sequence, which prevents
  // an object with incorrect field values being returned, but won't
  // canonicalize correctly if key order is different.
  for (let name of $getOwnNamesAndSymbols($obj)) {
    objectKey.push(name);
    objectKey.push($obj[name]);
  }
  return $multiKeyPutIfAbsent($constants, objectKey, () => $obj);
})()''');


// The following are helpers for Object methods when the receiver
// may be null or primitive.  These should only be generated by
// the compiler.
hashCode(obj) => JS('', '''(() => {
  if ($obj == null) {
    return 0;
  }
  // TODO(vsm): What should we do for primitives and non-Dart objects?
  switch (typeof $obj) {
  case "number":
  case "boolean":
    return $obj & 0x1FFFFFFF;
  case "string":
      // TODO(vsm): Call the JSString hashCode?
    return $obj.length;
  }
  return $obj.hashCode;
})()''');

toString(obj) => JS('', '''(() => {
  if ($obj == null) {
    return "null";
  }
  return $obj.toString();
})()''');

noSuchMethod(obj, invocation) => JS('', '''(() => {
  if ($obj == null) {
    $throwNoSuchMethod($obj, $invocation.memberName,
      $invocation.positionalArguments, $invocation.namedArguments);
  }
  switch (typeof $obj) {
    case "number":
    case "boolean":
    case "string":
      $throwNoSuchMethod($obj, $invocation.memberName,
        $invocation.positionalArguments, $invocation.namedArguments);
  }
  return $obj.noSuchMethod($invocation);
})()''');

final JsIterator = JS('', '''
  class JsIterator {
    constructor(dartIterator) {
      this.dartIterator = dartIterator;
    }
    next() {
      let i = this.dartIterator;
      let done = !i.moveNext();
      return { done: done, value: done ? void 0 : i.current };
    }
  }
''');
