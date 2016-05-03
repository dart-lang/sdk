// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

defineProperty(obj, name, desc) =>
    JS('', 'Object.defineProperty(#, #, #)', obj, name, desc);

getOwnPropertyDescriptor(obj, name) =>
    JS('', 'Object.getOwnPropertyDescriptor(#, #)', obj, name);

getOwnPropertyNames(obj) => JS('', 'Object.getOwnPropertyNames(#)', obj);

getOwnPropertySymbols(obj) => JS('', 'Object.getOwnPropertySymbols(#)', obj);

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
void throwStrongModeError(String message) {
  JS('', 'throw new #(#);', StrongModeError, message);
}

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) {
  JS('', 'throw Error(#)', message);
}

getOwnNamesAndSymbols(obj) {
  var names = getOwnPropertyNames(obj);
  var symbols = getOwnPropertySymbols(obj);
  return JS('', '#.concat(#)', names, symbols);
}

safeGetOwnProperty(obj, String name) {
  var desc = getOwnPropertyDescriptor(obj, name);
  if (desc != null) return JS('', '#.value', desc);
}

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

defineMemoizedGetter(obj, String name, getter) {
  return defineLazyProperty(obj, name, JS('', '{get: #}', getter));
}

copyTheseProperties(to, from, names) => JS('', '''(() => {
  for (let name of $names) {
    $copyProperty($to, $from, name);
  }
  return $to;
})()''');

copyProperty(to, from, name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('bool', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See: https://github.com/dart-lang/dev_compiler/issues/487
    var existing = getOwnPropertyDescriptor(to, name);
    if (existing != null) {
      if (JS('bool', '#.writable', existing)) {
        JS('', '#[#] = #.value', to, name, desc);
      }
      return;
    }
  }
  defineProperty(to, name, desc);
}

@JSExportName('export')
exportProperty(to, from, name) => copyProperty(to, from, name);

/// Copy properties from source to destination object.
/// This operation is commonly called `mixin` in JS.
copyProperties(to, from) {
  return copyTheseProperties(to, from, getOwnNamesAndSymbols(from));
}
