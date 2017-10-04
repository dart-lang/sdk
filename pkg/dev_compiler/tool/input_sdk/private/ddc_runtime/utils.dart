// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

/// The JavaScript undefined constant.
///
/// This is initialized by DDC to JS void 0.
const undefined = null;

final Function(Object, Object, Object) defineProperty =
    JS('', 'Object.defineProperty');

defineValue(obj, name, value) {
  defineProperty(obj, name,
      JS('', '{ value: #, configurable: true, writable: true }', value));
  return value;
}

void defineGetter(obj, name, getter) {
  defineProperty(obj, name, JS('', '{get: #}', getter));
}

void defineLazyGetter(obj, name, compute) {
  var x = null;
  defineProperty(
      obj,
      name,
      JS('', '{ get: () => # != null ? # : # = #(), configurable: true }', x, x,
          x, compute));
}

final Function(Object, Object) getOwnPropertyDescriptor =
    JS('', 'Object.getOwnPropertyDescriptor');

final Function(Object) getOwnPropertyNames =
    JS('', 'Object.getOwnPropertyNames');

final Function(Object) getOwnPropertySymbols =
    JS('', 'Object.getOwnPropertySymbols');

final hasOwnProperty = JS('', 'Object.prototype.hasOwnProperty');

/// This error indicates a strong mode specific failure, other than a type
/// assertion failure (TypeError) or CastError.
void throwTypeError(String message) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new TypeErrorImplementation.fromMessage(message);
}

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
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
defineLazyField(to, name, desc) => JS(
    '',
    '''(() => {
  let init = $desc.get;
  let value = null;
  $desc.get = function() {
    if (init == null) return value;

    // Compute and store the value, guarding against reentry.
    let f = init;
    init = () => $throwCyclicInitializationError($name);
    try {
      return value = f();
    } finally {
      init = null;
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
  for (var i = 0; i < JS('int', '#.length', names); ++i) {
    copyProperty(to, from, JS('', '#[#]', names, i));
  }
  return to;
}

copyProperty(to, from, name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('bool', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See https://github.com/dart-lang/sdk/issues/28324
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
