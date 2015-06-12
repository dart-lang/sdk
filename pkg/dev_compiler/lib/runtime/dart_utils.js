// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This library defines a set of general javascript utilities for us
 * by the Dart runtime.
*/

var dart_utils;
(function (dart_utils) {
  'use strict';

  const defineProperty = Object.defineProperty;
  const getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const getOwnPropertyNames = Object.getOwnPropertyNames;
  const getOwnPropertySymbols = Object.getOwnPropertySymbols;

  const hasOwnProperty = Object.prototype.hasOwnProperty;

  const slice = [].slice;


  /** This error indicates a bug in the runtime or the compiler.
   */
  function throwError(message) {
    throw Error(message);
  }
  dart_utils.throwError = throwError;

  function assert(condition) {
    if (!condition) throwError("The compiler is broken: failed assert");
  }
  dart_utils.assert = assert;

  function getOwnNamesAndSymbols(obj) {
    return getOwnPropertyNames(obj).concat(getOwnPropertySymbols(obj));
  }
  dart_utils.getOwnNamesAndSymbols = getOwnNamesAndSymbols;

  function safeGetOwnProperty(obj, name) {
    let desc = getOwnPropertyDescriptor(obj, name);
    if (desc) return desc.value;
  }
  dart_utils.safeGetOwnProperty = safeGetOwnProperty;

  /**
   * Defines a lazy property.
   * After initial get or set, it will replace itself with a value property.
   */
  // TODO(jmesserly): is this the best implementation for JS engines?
  // TODO(jmesserly): reusing descriptor objects has been shown to improve
  // performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
  function defineLazyProperty(to, name, desc) {
    let init = desc.get;
    let writable = !!desc.set;
    function lazySetter(value) {
      defineProperty(to, name, { value: value, writable: writable });
    }
    function lazyGetter() {
      // Clear the init function to detect circular initialization.
      let f = init;
      if (f === null) {
        throwError('circular initialization for field ' + name);
      }
      init = null;

      // Compute and store the value.
      let value = f();
      lazySetter(value);
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (writable) desc.set = lazySetter;
    defineProperty(to, name, desc);
  }
  dart_utils.defineLazyProperty = defineLazyProperty;

  function defineLazy(to, from) {
    for (let name of getOwnNamesAndSymbols(from)) {
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  dart_utils.defineLazy = defineLazy;

  function defineMemoizedGetter(obj, name, get) {
    let cache = null;
    function getter() {
      if (cache != null) return cache;
      cache = get();
      get = null;
      return cache;
    }
    defineProperty(obj, name, {get: getter, configurable: true});
  }
  dart_utils.defineMemoizedGetter = defineMemoizedGetter;

  function copyTheseProperties(to, from, names) {
    for (let name of names) {
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
    return to;
  }
  dart_utils.copyTheseProperties = copyTheseProperties;

  /**
   * Copy properties from source to destination object.
   * This operation is commonly called `mixin` in JS.
   */
  function copyProperties(to, from) {
    return copyTheseProperties(to, from, getOwnNamesAndSymbols(from));
  }
  dart_utils.copyProperties = copyProperties;

})(dart_utils || (dart_utils = {}));
