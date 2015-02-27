var _js_names;
(function(_js_names) {
  'use strict';
  // Function preserveNames: () → dynamic
  function preserveNames() {
  }
  dart.defineLazyProperties(_js_names, {
    get mangledNames() {
      return computeMangledNames(_foreign_helper.JS_EMBEDDED_GLOBAL('=Object', dart.as(_js_embedded_names.MANGLED_NAMES, core.String)), false);
    },
    get reflectiveNames() {
      return computeReflectiveNames(_js_names.mangledNames);
    },
    get mangledGlobalNames() {
      return computeMangledNames(_foreign_helper.JS_EMBEDDED_GLOBAL('=Object', dart.as(_js_embedded_names.MANGLED_GLOBAL_NAMES, core.String)), true);
    },
    get reflectiveGlobalNames() {
      return computeReflectiveNames(_js_names.mangledGlobalNames);
    }
  });
  // Function computeMangledNames: (dynamic, bool) → Map<String, String>
  function computeMangledNames(jsMangledNames, isGlobal) {
    preserveNames();
    let keys = extractKeys(jsMangledNames);
    let result = dart.map();
    let getterPrefix = _foreign_helper.JS_GET_NAME('GETTER_PREFIX');
    let getterPrefixLength = getterPrefix.length;
    let setterPrefix = _foreign_helper.JS_GET_NAME('SETTER_PREFIX');
    for (let key of keys) {
      let value = dart.as(_foreign_helper.JS('String', '#[#]', jsMangledNames, key), core.String);
      result.set(key, value);
      if (!dart.notNull(isGlobal)) {
        if (key.startsWith(getterPrefix)) {
          result.set(`${setterPrefix}${key.substring(getterPrefixLength)}`, `${value}=`);
        }
      }
    }
    return result;
  }
  // Function computeReflectiveNames: (Map<String, String>) → Map
  function computeReflectiveNames(map) {
    preserveNames();
    let result = dart.map();
    map.forEach((mangledName, reflectiveName) => {
      result.set(reflectiveName, mangledName);
    });
    return result;
  }
  // Function extractKeys: (dynamic) → List<dynamic>
  function extractKeys(victim) {
    let result = _foreign_helper.JS('', '\n(function(victim, hasOwnProperty) {\n  var result = [];\n  for (var key in victim) {\n    if (hasOwnProperty.call(victim, key)) result.push(key);\n  }\n  return result;\n})(#, Object.prototype.hasOwnProperty)', victim);
    return new _interceptors.JSArray.markFixed(result);
  }
  // Function unmangleGlobalNameIfPreservedAnyways: (String) → String
  function unmangleGlobalNameIfPreservedAnyways(name) {
    let names = _foreign_helper.JS_EMBEDDED_GLOBAL('=Object', dart.as(_js_embedded_names.MANGLED_GLOBAL_NAMES, core.String));
    return dart.as(_js_helper.JsCache.fetch(names, name), core.String);
  }
  // Function unmangleAllIdentifiersIfPreservedAnyways: (String) → String
  function unmangleAllIdentifiersIfPreservedAnyways(str) {
    return dart.as(_foreign_helper.JS("String", "(#).replace(/[^<,> ]+/g," + "function(m) { return #[m] || m; })", str, _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.MANGLED_GLOBAL_NAMES, core.String))), core.String);
  }
  // Exports:
  _js_names.preserveNames = preserveNames;
  _js_names.computeMangledNames = computeMangledNames;
  _js_names.computeReflectiveNames = computeReflectiveNames;
  _js_names.extractKeys = extractKeys;
  _js_names.unmangleGlobalNameIfPreservedAnyways = unmangleGlobalNameIfPreservedAnyways;
  _js_names.unmangleAllIdentifiersIfPreservedAnyways = unmangleAllIdentifiersIfPreservedAnyways;
})(_js_names || (_js_names = {}));
