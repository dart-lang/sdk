// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

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
  throw TypeErrorImpl(message);
}

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) {
  JS('', 'throw Error(#)', message);
}

Iterable getOwnNamesAndSymbols(obj) {
  var names = getOwnPropertyNames(obj);
  var symbols = getOwnPropertySymbols(obj);
  return JS('', '#.concat(#)', names, symbols);
}

/// Returns the value of field `name` on `obj`.
///
/// We use this instead of obj[name] since obj[name] checks the entire
/// prototype chain instead of just `obj`.
safeGetOwnProperty(obj, name) {
  if (JS<bool>('!', '#.hasOwnProperty(#)', obj, name))
    return JS<Object>('', '#[#]', obj, name);
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

    // On the first (non-cyclic) execution, record the field so we can reset it
    // later if needed (hot restart).
    $_resetFields.push(() => {
      init = initializer;
      value = null;
    });

    // Try to evaluate the field, using try+catch to ensure we implement the
    // correct Dart error semantics.
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
