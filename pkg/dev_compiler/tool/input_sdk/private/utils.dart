// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

final defineProperty = JS('', 'Object.defineProperty');
final getOwnPropertyDescriptor = JS('', 'Object.getOwnPropertyDescriptor');
final getOwnPropertyNames = JS('', 'Object.getOwnPropertyNames');
final getOwnPropertySymbols = JS('', 'Object.getOwnPropertySymbols');

final hasOwnProperty = JS('', 'Object.prototype.hasOwnProperty');

// TODO(ochafik): Add ES6 class syntax support to JS intrinsics to avoid this.
final StrongModeError = JS('', '''(function() {
  function StrongModeError(message) {
    Error.call(this);
    this.message = message;
  };
  Object.setPrototypeOf(StrongModeError.prototype, Error.prototype);
  return StrongModeError;
})()''');

/// This error indicates a strong mode specific failure.
void throwStrongModeError(String message) => JS('', '''(() => {
  throw new $StrongModeError($message);
})()''');

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) => JS('', '''(() => {
  throw Error($message);
})()''');

getOwnNamesAndSymbols(obj) => JS('', '''(() => {
  return $getOwnPropertyNames($obj).concat($getOwnPropertySymbols($obj));
})()''');

safeGetOwnProperty(obj, String name) => JS('', '''(() => {
  let desc = $getOwnPropertyDescriptor($obj, $name);
  if (desc) return desc.value;
})()''');

/// Defines a lazy property.
/// After initial get or set, it will replace itself with a value property.
// TODO(jmesserly): reusing descriptor objects has been shown to improve
// performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
defineLazyProperty(to, name, desc) => JS('', '''(() => {
  let init = $desc.get;
    let value = null;

    function lazySetter(x) {
      init = null;
      value = x;
    }
    function circularInitError() {
      $throwInternalError('circular initialization for field ' + $name);
    }
    function lazyGetter() {
      if (init == null) return value;

      // Compute and store the value, guarding against reentry.
      let f = init;
      init = circularInitError;
      lazySetter(f());
      return value;
    }
    $desc.get = lazyGetter;
    $desc.configurable = true;
    if ($desc.set) $desc.set = lazySetter;
    return $defineProperty($to, $name, $desc);
})()''');

void defineLazy(to, from) => JS('', '''(() => {
  for (let name of $getOwnNamesAndSymbols($from)) {
    $defineLazyProperty($to, name, $getOwnPropertyDescriptor($from, name));
  }
})()''');

defineMemoizedGetter(obj, String name, getter) => JS('', '''(() => {
  return $defineLazyProperty($obj, $name, {get: $getter});
})()''');

copyTheseProperties(to, from, names) => JS('', '''(() => {
  for (let name of $names) {
    var desc = $getOwnPropertyDescriptor($from, name);
    if (desc != void 0) {
      $defineProperty($to, name, desc);
    } else {
      $defineLazyProperty($to, name, () => $from[name]);
    }
  }
  return $to;
})()''');

/// Copy properties from source to destination object.
/// This operation is commonly called `mixin` in JS.
copyProperties(to, from) => JS('', '''(() => {
  return $copyTheseProperties($to, $from, $getOwnNamesAndSymbols($from));
})()''');

/// Exports from one Dart module to another.
@JSExportName('export')
export_(to, from, show, hide) => JS('', '''(() => {
  if ($show == void 0 || $show.length == 0) {
    $show = $getOwnNamesAndSymbols($from);
  }
  if ($hide != void 0) {
    var hideMap = new Set($hide);
    $show = $show.filter((k) => !hideMap.has(k));
  }
  return $copyTheseProperties($to, $from, $show);
})()''');
