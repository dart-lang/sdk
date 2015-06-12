// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This library defines the association between runtime objects and
 * runtime types.
*/

dart_library.library('dart_runtime/_rtti', null, /* Imports */[
], /* Lazy Imports */[
  'dart/core',
  'dart_runtime/_types'
], function(exports, core, types) {
  'use strict';

  const defineLazyProperty = dart_utils.defineLazyProperty;

  const defineProperty = Object.defineProperty;

  const slice = [].slice;

  /**
   *Tag a closure with a type, using one of three forms:
   * dart.fn(cls) marks cls has having no optional or named
   *  parameters, with all argument and return types as dynamic
   * dart.fn(cls, func) marks cls with the lazily computed
   *  runtime type as computed by func()
   * dart.fn(cls, rType, argsT, extras) marks cls as having the
   * runtime type dart.functionType(rType, argsT, extras)
   */
  function fn(closure/* ...args*/) {
    // Closure and a lazy type constructor
    if (arguments.length == 2) {
      defineLazyProperty(closure, _runtimeType, {get : arguments[1]});
      return closure;
    }
    let t;
    if (arguments.length == 1) {
      // No type arguments, it's all dynamic
      let len = closure.length;
      let build = () => {
        let args = Array.apply(null, new Array(len)).map(() => core.Object);
        return types.functionType(core.Object, args);
      };
      // We could be called before Object is defined.
      if (core.Object === void 0) return fn(closure, build);
      t = build();
    } else {
      // We're passed the piecewise components of the function type,
      // construct it.
      let args = slice.call(arguments, 1);
      t = types.functionType.apply(null, args);
    }
    tag(closure, t);
    return closure;
  }
  exports.fn = fn;

  // TODO(vsm): How should we encode the runtime type?
  const _runtimeType = Symbol('_runtimeType');

  function checkPrimitiveType(obj) {
    switch (typeof obj) {
      case "undefined":
        return core.Null;
      case "number":
        return Math.floor(obj) == obj ? core.int : core.double;
      case "boolean":
        return core.bool;
      case "string":
        return core.String;
      case "symbol":
        return Symbol;
    }
    // Undefined is handled above. For historical reasons,
    // typeof null == "object" in JS.
    if (obj === null) return core.Null;
    return null;
  }

  function runtimeType(obj) {
    let result = checkPrimitiveType(obj);
    if (result !== null) return result;
    return obj.runtimeType;
  }
  exports.runtimeType = runtimeType;

  function getFunctionType(obj) {
    // TODO(vsm): Encode this properly on the function for Dart-generated code.
    let args = Array.apply(null, new Array(obj.length)).map(() => core.Object);
    return types.functionType(types.bottom, args);
  }

  /**
   * Returns the runtime type of obj. This is the same as `obj.realRuntimeType`
   * but will not call an overridden getter.
   *
   * Currently this will return null for non-Dart objects.
   */
  function realRuntimeType(obj) {
    let result = checkPrimitiveType(obj);
    if (result !== null) return result;
    // TODO(vsm): Should we treat Dart and JS objects differently here?
    // E.g., we can check if obj instanceof core.Object to differentiate.
    result = obj[_runtimeType];
    if (result) return result;
    result = obj.constructor;
    if (result == Function) {
      return getFunctionType(obj);
    }
    return result;
  }
  exports.realRuntimeType = realRuntimeType;

  function LazyTagged(infoFn) {
    class _Tagged {
      get [_runtimeType]() {return infoFn();}
    }
    return _Tagged;
  }
  exports.LazyTagged = LazyTagged;

  function read(value) { 
    return value[_runtimeType];
  }
  exports.read = read;

  function tag(value, info) {
    value[_runtimeType] = info;
  }
  exports.tag = tag;

  function tagComputed(value, compute) {
    defineProperty(value, _runtimeType, { get: compute });
  }
  exports.tagComputed = tagComputed;

  function tagMemoized(value, compute) {
    let cache = null;
    function getter() {
      if (compute == null) return cache;
      cache = compute();
      compute = null;
      return cache;
    }
    tagComputed(value, getter);
  }
  exports.tagMemoized = tagMemoized;
});
