// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This library defines a set of general javascript utilities for us
 * by the Dart runtime.
*/

var dart_utils =
  typeof module != "undefined" && module.exports || {};

(function (dart_utils) {
  'use strict';

  const defineProperty = Object.defineProperty;
  const getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const getOwnPropertyNames = Object.getOwnPropertyNames;
  const getOwnPropertySymbols = Object.getOwnPropertySymbols;

  const hasOwnProperty = Object.prototype.hasOwnProperty;

  class StrongModeError extends Error {
    constructor(message) {
      super(message);
    }
  }

  /** This error indicates a strong mode specific failure.
   */
  function throwStrongModeError(message) {
    throw new StrongModeError(message);
  }
  dart_utils.throwStrongModeError = throwStrongModeError;

  /** This error indicates a bug in the runtime or the compiler.
   */
  function throwInternalError(message) {
    throw Error(message);
  }
  dart_utils.throwInternalError = throwInternalError;

  function assert(condition) {
    if (!condition) throwInternalError("The compiler is broken: failed assert");
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
  // TODO(jmesserly): reusing descriptor objects has been shown to improve
  // performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
  function defineLazyProperty(to, name, desc) {
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
  }
  dart_utils.defineLazyProperty = defineLazyProperty;

  function defineLazy(to, from) {
    for (let name of getOwnNamesAndSymbols(from)) {
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  dart_utils.defineLazy = defineLazy;

  function defineMemoizedGetter(obj, name, getter) {
    return defineLazyProperty(obj, name, {get: getter});
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

  /** Exports from one Dart module to another. */
  function export_(to, from, show, hide) {
    if (show == void 0) {
      show = getOwnNamesAndSymbols(from);
    }
    if (hide != void 0) {
      var hideMap = new Set(hide);
      show = show.filter((k) => !hideMap.has(k));
    }
    return copyTheseProperties(to, from, show);
  }
  dart_utils.export = export_;

})(dart_utils);
