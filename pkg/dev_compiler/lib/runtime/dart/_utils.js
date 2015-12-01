dart_library.library('dart/_utils', null, /* Imports */[
], /* Lazy imports */[
], function(exports, dart) {
  'use strict';
  const defineProperty = Object.defineProperty;
  const getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const getOwnPropertyNames = Object.getOwnPropertyNames;
  const getOwnPropertySymbols = Object.getOwnPropertySymbols;
  const hasOwnProperty = Object.prototype.hasOwnProperty;
  const StrongModeError = (function() {
    function StrongModeError(message) {
      Error.call(this);
      this.message = message;
    }
    ;
    Object.setPrototypeOf(StrongModeError.prototype, Error.prototype);
    return StrongModeError;
  })();
  function throwStrongModeError(message) {
    throw new StrongModeError(message);
  }
  function throwInternalError(message) {
    throw Error(message);
  }
  function assert_(condition) {
    if (!condition)
      throwInternalError("The compiler is broken: failed assert");
  }
  function getOwnNamesAndSymbols(obj) {
    return getOwnPropertyNames(obj).concat(getOwnPropertySymbols(obj));
  }
  function safeGetOwnProperty(obj, name) {
    let desc = getOwnPropertyDescriptor(obj, name);
    if (desc)
      return desc.value;
  }
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
      if (init == null)
        return value;
      let f = init;
      init = circularInitError;
      lazySetter(f());
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (desc.set)
      desc.set = lazySetter;
    return defineProperty(to, name, desc);
  }
  function defineLazy(to, from) {
    for (let name of getOwnNamesAndSymbols(from)) {
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  function defineMemoizedGetter(obj, name, getter) {
    return defineLazyProperty(obj, name, {get: getter});
  }
  function copyTheseProperties(to, from, names) {
    for (let name of names) {
      var desc = getOwnPropertyDescriptor(from, name);
      if (desc != void 0) {
        defineProperty(to, name, desc);
      } else {
        defineLazyProperty(to, name, () => from[name]);
      }
    }
    return to;
  }
  function copyProperties(to, from) {
    return copyTheseProperties(to, from, getOwnNamesAndSymbols(from));
  }
  function export_(to, from, show, hide) {
    if (show == void 0 || show.length == 0) {
      show = getOwnNamesAndSymbols(from);
    }
    if (hide != void 0) {
      var hideMap = new Set(hide);
      show = show.filter(k => !hideMap.has(k));
    }
    return copyTheseProperties(to, from, show);
  }
  // Exports:
  exports.defineProperty = defineProperty;
  exports.getOwnPropertyDescriptor = getOwnPropertyDescriptor;
  exports.getOwnPropertyNames = getOwnPropertyNames;
  exports.getOwnPropertySymbols = getOwnPropertySymbols;
  exports.hasOwnProperty = hasOwnProperty;
  exports.StrongModeError = StrongModeError;
  exports.throwStrongModeError = throwStrongModeError;
  exports.throwInternalError = throwInternalError;
  exports.assert_ = assert_;
  exports.getOwnNamesAndSymbols = getOwnNamesAndSymbols;
  exports.safeGetOwnProperty = safeGetOwnProperty;
  exports.defineLazyProperty = defineLazyProperty;
  exports.defineLazy = defineLazy;
  exports.defineMemoizedGetter = defineMemoizedGetter;
  exports.copyTheseProperties = copyTheseProperties;
  exports.copyProperties = copyProperties;
  exports.export_ = export_;
});
