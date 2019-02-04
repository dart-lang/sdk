// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

/// The JavaScript undefined constant.
///
/// This is initialized by DDC to JS `void 0`.
const undefined = null;

final Function(Object, Object, Object) defineProperty =
    JS('', 'Object.defineProperty');

defineValue(obj, name, value) {
  defineAccessor(obj, name, value: value, configurable: true, writable: true);
  return value;
}

final Function(Object, Object,
    {Object get,
    Object set,
    Object value,
    bool configurable,
    bool writable}) defineAccessor = JS('', 'Object.defineProperty');

final Function(Object, Object) getOwnPropertyDescriptor =
    JS('', 'Object.getOwnPropertyDescriptor');

final Iterable Function(Object) getOwnPropertyNames =
    JS('', 'Object.getOwnPropertyNames');

final Function(Object) getOwnPropertySymbols =
    JS('', 'Object.getOwnPropertySymbols');

final Function(Object) getPrototypeOf = JS('', 'Object.getPrototypeOf');

/// This error indicates a strong mode specific failure, other than a type
/// assertion failure (TypeError) or CastError.
void throwTypeError(String message) {
  if (JS('!', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw TypeErrorImpl(message);
}

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) {
  if (JS('!', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  JS('', 'throw Error(#)', message);
}

Iterable getOwnNamesAndSymbols(obj) {
  var names = getOwnPropertyNames(obj);
  var symbols = getOwnPropertySymbols(obj);
  return JS('', '#.concat(#)', names, symbols);
}

safeGetOwnProperty(obj, name) {
  var desc = getOwnPropertyDescriptor(obj, name);
  if (desc != null) return JS('', '#.value', desc);
}

/// Defines a lazy static field.
/// After initial get or set, it will replace itself with a value property.
// TODO(jmesserly): reusing descriptor objects has been shown to improve
// performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
defineLazyField(to, name, desc) => JS('', '''(() => {
  const initializer = $desc.get;
  let init = initializer;
  let value = null;
  $desc.get = function() {
    if (init == null) return value;
    let f = init;
    init = $throwCyclicInitializationError;
    if (f === init) f($name); // throw cycle error
    try {
      value = f();
      init = null;
      return value;
    } catch (e) {
      init = null;
      value = null;
      throw e;
    }
  };
  $desc.configurable = true;
  if ($desc.set != null) {
    $desc.set = function(x) {
      init = null;
      value = x;
    };
  }
  $_resetFields.push(() => {
    init = initializer;
    value = null;
  });
  return ${defineProperty(to, name, desc)};
})()''');

copyTheseProperties(to, from, names) {
  for (int i = 0, n = JS('!', '#.length', names); i < n; ++i) {
    var name = JS('', '#[#]', names, i);
    if (name == 'constructor') continue;
    copyProperty(to, from, name);
  }
  return to;
}

copyProperty(to, from, name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('!', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See https://github.com/dart-lang/sdk/issues/28324
    var existing = getOwnPropertyDescriptor(to, name);
    if (existing != null) {
      if (JS('!', '#.writable', existing)) {
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
