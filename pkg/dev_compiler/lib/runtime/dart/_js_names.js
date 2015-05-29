var _js_names = dart.defineLibrary(_js_names, {});
var _foreign_helper = dart.lazyImport(_foreign_helper);
var _js_embedded_names = dart.import(_js_embedded_names);
var core = dart.import(core);
var _interceptors = dart.import(_interceptors);
var _js_helper = dart.lazyImport(_js_helper);
(function(exports, _foreign_helper, _js_embedded_names, core, _interceptors, _js_helper) {
  'use strict';
  function preserveNames() {
  }
  dart.fn(preserveNames);
  dart.defineLazyProperties(exports, {
    get mangledNames() {
      return computeMangledNames(_foreign_helper.JS_EMBEDDED_GLOBAL('=Object', _js_embedded_names.MANGLED_NAMES), false);
    },
    get reflectiveNames() {
      return computeReflectiveNames(exports.mangledNames);
    },
    get mangledGlobalNames() {
      return computeMangledNames(_foreign_helper.JS_EMBEDDED_GLOBAL('=Object', _js_embedded_names.MANGLED_GLOBAL_NAMES), true);
    },
    get reflectiveGlobalNames() {
      return computeReflectiveNames(exports.mangledGlobalNames);
    }
  });
  function computeMangledNames(jsMangledNames, isGlobal) {
    preserveNames();
    let keys = extractKeys(jsMangledNames);
    let result = dart.map();
    let getterPrefix = _foreign_helper.JS_GET_NAME('GETTER_PREFIX');
    let getterPrefixLength = getterPrefix.length;
    let setterPrefix = _foreign_helper.JS_GET_NAME('SETTER_PREFIX');
    for (let key of dart.as(keys, core.Iterable$(core.String))) {
      let value = jsMangledNames[key];
      result.set(key, value);
      if (!dart.notNull(isGlobal)) {
        if (key.startsWith(getterPrefix)) {
          result.set(`${setterPrefix}${key.substring(getterPrefixLength)}`, `${value}=`);
        }
      }
    }
    return result;
  }
  dart.fn(computeMangledNames, core.Map$(core.String, core.String), [core.Object, core.bool]);
  function computeReflectiveNames(map) {
    preserveNames();
    let result = dart.map();
    map.forEach(dart.fn((mangledName, reflectiveName) => {
      result.set(reflectiveName, mangledName);
    }, core.Object, [core.String, core.String]));
    return result;
  }
  dart.fn(computeReflectiveNames, core.Map$(core.String, core.String), [core.Map$(core.String, core.String)]);
  function extractKeys(victim) {
    let result = function(victim, hasOwnProperty) {
      var result = [];
      for (var key in victim) {
        if (hasOwnProperty.call(victim, key))
          result.push(key);
      }
      return result;
    }(victim, Object.prototype.hasOwnProperty);
    return _interceptors.JSArray.markFixed(result);
  }
  dart.fn(extractKeys, core.List, [core.Object]);
  function unmangleGlobalNameIfPreservedAnyways(name) {
    let names = _foreign_helper.JS_EMBEDDED_GLOBAL('=Object', _js_embedded_names.MANGLED_GLOBAL_NAMES);
    return dart.as(_js_helper.JsCache.fetch(names, name), core.String);
  }
  dart.fn(unmangleGlobalNameIfPreservedAnyways, core.String, [core.String]);
  function unmangleAllIdentifiersIfPreservedAnyways(str) {
    return str.replace(/[^<,> ]+/g, function(m) {
      return _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.MANGLED_GLOBAL_NAMES)[m] || m;
    });
  }
  dart.fn(unmangleAllIdentifiersIfPreservedAnyways, core.String, [core.String]);
  // Exports:
  exports.preserveNames = preserveNames;
  exports.computeMangledNames = computeMangledNames;
  exports.computeReflectiveNames = computeReflectiveNames;
  exports.extractKeys = extractKeys;
  exports.unmangleGlobalNameIfPreservedAnyways = unmangleGlobalNameIfPreservedAnyways;
  exports.unmangleAllIdentifiersIfPreservedAnyways = unmangleAllIdentifiersIfPreservedAnyways;
})(_js_names, _foreign_helper, _js_embedded_names, core, _interceptors, _js_helper);
