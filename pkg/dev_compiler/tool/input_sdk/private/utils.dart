// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._utils;

import 'dart:_foreign_helper' show JS;

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
void throwStrongModeError(String message) => JS('', '''((message) => {
  throw new StrongModeError(message);
})(#)''', message);

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) => JS('', '''((message) => {
  throw Error(message);
})(#)''', message);

// TODO(ochafik): Re-introduce a @JS annotation in the SDK (same as package:js)
// so that this is named 'assert' in JavaScript.
void assert_(bool condition) => JS('', '''((condition) => {
  if (!condition) throwInternalError("The compiler is broken: failed assert");
})(#)''', condition);

getOwnNamesAndSymbols(obj) => JS('', '''((obj) => {
  return getOwnPropertyNames(obj).concat(getOwnPropertySymbols(obj));
})(#)''', obj);

safeGetOwnProperty(obj, String name) => JS('', '''((obj, name) => {
  let desc = getOwnPropertyDescriptor(obj, name);
  if (desc) return desc.value;
})(#, #)''', obj, name);

/// Defines a lazy property.
/// After initial get or set, it will replace itself with a value property.
// TODO(jmesserly): reusing descriptor objects has been shown to improve
// performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
defineLazyProperty(to, name, desc) => JS('', '''((to, name, desc) => {
  let init = desc.get;
    let value = null;

    function lazySetter(x) {
      init = null;
      value = x;
    }
    function circularInitError() {
      throwInternalError('circular initialization for field ' + name);
    }
    function lazyGetter() {
      if (init == null) return value;

      // Compute and store the value, guarding against reentry.
      let f = init;
      init = circularInitError;
      lazySetter(f());
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (desc.set) desc.set = lazySetter;
    return defineProperty(to, name, desc);
})(#, #, #)''', to, name, desc);

void defineLazy(to, from) => JS('', '''((to, from) => {
  for (let name of getOwnNamesAndSymbols(from)) {
    defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
  }
})(#, #)''', to, from);

defineMemoizedGetter(obj, String name, getter) =>
    JS('', '''((obj, name, getter) => {
  return defineLazyProperty(obj, name, {get: getter});
})(#, #, #)''', obj, name, getter);

copyTheseProperties(to, from, names) => JS('', '''((to, from, names) => {
  for (let name of names) {
    var desc = getOwnPropertyDescriptor(from, name);
    if (desc != void 0) {
      defineProperty(to, name, desc);
    } else {
      defineLazyProperty(to, name, () => from[name]);
    }
  }
  return to;
})(#, #, #)''', to, from, names);

/// Copy properties from source to destination object.
/// This operation is commonly called `mixin` in JS.
copyProperties(to, from) => JS('', '''((to, from) => {
  return copyTheseProperties(to, from, getOwnNamesAndSymbols(from));
})(#, #)''', to, from);

/// Exports from one Dart module to another.
// TODO(ochafik): Re-introduce a @JS annotation in the SDK (same as package:js)
// so that this is named 'export' in JavaScript.
export_(to, from, show, hide) => JS('', '''((to, from, show, hide) => {
  if (show == void 0 || show.length == 0) {
    show = getOwnNamesAndSymbols(from);
  }
  if (hide != void 0) {
    var hideMap = new Set(hide);
    show = show.filter((k) => !hideMap.has(k));
  }
  return copyTheseProperties(to, from, show);
})(#, #, #, #)''', to, from, show, hide);
