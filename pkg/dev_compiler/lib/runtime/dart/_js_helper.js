var _js_helper;
(function(exports) {
  'use strict';
  class NoSideEffects extends core.Object {
    NoSideEffects() {
    }
  }
  class NoThrows extends core.Object {
    NoThrows() {
    }
  }
  class NoInline extends core.Object {
    NoInline() {
    }
  }
  class IrRepresentation extends core.Object {
    IrRepresentation(value) {
      this.value = value;
    }
  }
  class Native extends core.Object {
    Native(name) {
      this.name = name;
    }
  }
  let _$ = Symbol('_');
  let _throwUnmodifiable = Symbol('_throwUnmodifiable');
  let ConstantMap$ = dart.generic(function(K, V) {
    class ConstantMap extends core.Object {
      [_$]() {
      }
      get isEmpty() {
        return this.length == 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      toString() {
        return collection.Maps.mapToString(this);
      }
      [_throwUnmodifiable]() {
        throw new core.UnsupportedError("Cannot modify unmodifiable Map");
      }
      set(key, val) {
        return this[_throwUnmodifiable]();
      }
      putIfAbsent(key, ifAbsent) {
        return dart.as(this[_throwUnmodifiable](), V);
      }
      remove(key) {
        return dart.as(this[_throwUnmodifiable](), V);
      }
      clear() {
        return this[_throwUnmodifiable]();
      }
      addAll(other) {
        return this[_throwUnmodifiable]();
      }
    }
    ConstantMap[dart.implements] = () => [core.Map$(K, V)];
    dart.defineNamedConstructor(ConstantMap, _$);
    return ConstantMap;
  });
  let ConstantMap = ConstantMap$();
  let _jsObject = Symbol('_jsObject');
  let _keys = Symbol('_keys');
  let _fetch = Symbol('_fetch');
  let ConstantStringMap$ = dart.generic(function(K, V) {
    class ConstantStringMap extends ConstantMap$(K, V) {
      [_$](length, jsObject$, keys$) {
        this.length = length;
        this[_jsObject] = jsObject$;
        this[_keys] = keys$;
        super[_$]();
      }
      containsValue(needle) {
        return this.values[core.$any](value => dart.equals(value, needle));
      }
      containsKey(key) {
        if (!(typeof key == 'string'))
          return false;
        if (dart.equals('__proto__', key))
          return false;
        return jsHasOwnProperty(this[_jsObject], dart.as(key, core.String));
      }
      get(key) {
        if (!dart.notNull(this.containsKey(key)))
          return null;
        return dart.as(this[_fetch](key), V);
      }
      [_fetch](key) {
        return jsPropertyAccess(this[_jsObject], dart.as(key, core.String));
      }
      forEach(f) {
        let keys = this[_keys];
        for (let i = 0; core.int['<'](i, dart.dload(keys, 'length')); i = dart.notNull(i) + 1) {
          let key = dart.dindex(keys, i);
          f(dart.as(key, K), dart.as(this[_fetch](key), V));
        }
      }
      get keys() {
        return new (_ConstantMapKeyIterable$(K))(this);
      }
      get values() {
        return new (_internal.MappedIterable$(K, V))(this[_keys], dart.as((key => this[_fetch](key)).bind(this), dart.functionType(V, [K])));
      }
    }
    ConstantStringMap[dart.implements] = () => [_internal.EfficientLength];
    dart.defineNamedConstructor(ConstantStringMap, _$);
    return ConstantStringMap;
  });
  let ConstantStringMap = ConstantStringMap$();
  let _protoValue = Symbol('_protoValue');
  let ConstantProtoMap$ = dart.generic(function(K, V) {
    class ConstantProtoMap extends ConstantStringMap$(K, V) {
      [_$](length, jsObject, keys, protoValue) {
        this[_protoValue] = protoValue;
        super[_$](dart.as(length, core.int), jsObject, dart.as(keys, core.List$(K)));
      }
      containsKey(key) {
        if (!(typeof key == 'string'))
          return false;
        if (dart.equals('__proto__', key))
          return true;
        return jsHasOwnProperty(this[_jsObject], dart.as(key, core.String));
      }
      [_fetch](key) {
        return dart.equals('__proto__', key) ? this[_protoValue] : jsPropertyAccess(this[_jsObject], dart.as(key, core.String));
      }
    }
    dart.defineNamedConstructor(ConstantProtoMap, _$);
    return ConstantProtoMap;
  });
  let ConstantProtoMap = ConstantProtoMap$();
  let _map = Symbol('_map');
  let _ConstantMapKeyIterable$ = dart.generic(function(K) {
    class _ConstantMapKeyIterable extends collection.IterableBase$(K) {
      _ConstantMapKeyIterable(map$) {
        this[_map] = map$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return this[_map][_keys][core.$iterator];
      }
      get [core.$length]() {
        return this[_map][_keys][core.$length];
      }
    }
    return _ConstantMapKeyIterable;
  });
  let _ConstantMapKeyIterable = _ConstantMapKeyIterable$();
  let _jsData = Symbol('_jsData');
  let _getMap = Symbol('_getMap');
  let GeneralConstantMap$ = dart.generic(function(K, V) {
    class GeneralConstantMap extends ConstantMap$(K, V) {
      GeneralConstantMap(jsData) {
        this[_jsData] = jsData;
        super[_$]();
      }
      [_getMap]() {
        if (!this.$map) {
          let backingMap = new (collection.LinkedHashMap$(K, V))();
          this.$map = fillLiteralMap(this[_jsData], backingMap);
        }
        return this.$map;
      }
      containsValue(needle) {
        return this[_getMap]().containsValue(needle);
      }
      containsKey(key) {
        return this[_getMap]().containsKey(key);
      }
      get(key) {
        return this[_getMap]().get(key);
      }
      forEach(f) {
        this[_getMap]().forEach(f);
      }
      get keys() {
        return this[_getMap]().keys;
      }
      get values() {
        return this[_getMap]().values;
      }
      get length() {
        return this[_getMap]().length;
      }
    }
    return GeneralConstantMap;
  });
  let GeneralConstantMap = GeneralConstantMap$();
  // Function contains: (String, String) → bool
  function contains(userAgent, name) {
    return userAgent.indexOf(name) != -1;
  }
  // Function arrayLength: (List<dynamic>) → int
  function arrayLength(array) {
    return array.length;
  }
  // Function arrayGet: (List<dynamic>, int) → dynamic
  function arrayGet(array, index) {
    return array[index];
  }
  // Function arraySet: (List<dynamic>, int, dynamic) → void
  function arraySet(array, index, value) {
    array[index] = value;
  }
  // Function propertyGet: (dynamic, String) → dynamic
  function propertyGet(object, property) {
    return object[property];
  }
  // Function callHasOwnProperty: (dynamic, dynamic, String) → bool
  function callHasOwnProperty(func, object, property) {
    return func.call(object, property);
  }
  // Function propertySet: (dynamic, String, dynamic) → void
  function propertySet(object, property, value) {
    object[property] = value;
  }
  // Function getPropertyFromPrototype: (dynamic, String) → dynamic
  function getPropertyFromPrototype(object, name) {
    return Object.getPrototypeOf(object)[name];
  }
  exports.getTagFunction = null;
  exports.alternateTagFunction = null;
  exports.prototypeForTagFunction = null;
  // Function toStringForNativeObject: (dynamic) → String
  function toStringForNativeObject(obj) {
    let name = exports.getTagFunction == null ? '<Unknown>' : dart.dcall(exports.getTagFunction, obj);
    return `Instance of ${name}`;
  }
  // Function hashCodeForNativeObject: (dynamic) → int
  function hashCodeForNativeObject(object) {
    return Primitives.objectHashCode(object);
  }
  // Function defineProperty: (dynamic, String, dynamic) → void
  function defineProperty(obj, property, value) {
    Object.defineProperty(obj, property, {value: value, enumerable: false, writable: true, configurable: true});
  }
  // Function isDartObject: (dynamic) → bool
  function isDartObject(obj) {
    return obj instanceof _foreign_helper.JS_DART_OBJECT_CONSTRUCTOR();
  }
  dart.copyProperties(exports, {
    get interceptorsByTag() {
      return _foreign_helper.JS_EMBEDDED_GLOBAL('=Object', _js_embedded_names.INTERCEPTORS_BY_TAG);
    },
    get leafTags() {
      return _foreign_helper.JS_EMBEDDED_GLOBAL('=Object', _js_embedded_names.LEAF_TAGS);
    }
  });
  // Function findDispatchTagForInterceptorClass: (dynamic) → String
  function findDispatchTagForInterceptorClass(interceptorClassConstructor) {
    return dart.as(interceptorClassConstructor[_js_embedded_names.NATIVE_SUPERCLASS_TAG_NAME], core.String);
  }
  exports.dispatchRecordsForInstanceTags = null;
  exports.interceptorsForUncacheableTags = null;
  // Function lookupInterceptor: (String) → dynamic
  function lookupInterceptor(tag) {
    return propertyGet(exports.interceptorsByTag, tag);
  }
  let UNCACHED_MARK = '~';
  let INSTANCE_CACHED_MARK = '!';
  let LEAF_MARK = '-';
  let INTERIOR_MARK = '+';
  let DISCRIMINATED_MARK = '*';
  // Function lookupAndCacheInterceptor: (dynamic) → dynamic
  function lookupAndCacheInterceptor(obj) {
    dart.assert(!dart.notNull(isDartObject(obj)));
    let tag = dart.as(dart.dcall(exports.getTagFunction, obj), core.String);
    let record = propertyGet(exports.dispatchRecordsForInstanceTags, tag);
    if (record != null)
      return patchInstance(obj, record);
    let interceptor = propertyGet(exports.interceptorsForUncacheableTags, tag);
    if (interceptor != null)
      return interceptor;
    let interceptorClass = lookupInterceptor(tag);
    if (interceptorClass == null) {
      tag = dart.as(dart.dcall(exports.alternateTagFunction, obj, tag), core.String);
      if (tag != null) {
        record = propertyGet(exports.dispatchRecordsForInstanceTags, tag);
        if (record != null)
          return patchInstance(obj, record);
        interceptor = propertyGet(exports.interceptorsForUncacheableTags, tag);
        if (interceptor != null)
          return interceptor;
        interceptorClass = lookupInterceptor(tag);
      }
    }
    if (interceptorClass == null) {
      return null;
    }
    interceptor = interceptorClass.prototype;
    let mark = tag[0];
    if (dart.equals(mark, INSTANCE_CACHED_MARK)) {
      record = makeLeafDispatchRecord(interceptor);
      propertySet(exports.dispatchRecordsForInstanceTags, tag, record);
      return patchInstance(obj, record);
    }
    if (dart.equals(mark, UNCACHED_MARK)) {
      propertySet(exports.interceptorsForUncacheableTags, tag, interceptor);
      return interceptor;
    }
    if (dart.equals(mark, LEAF_MARK)) {
      return patchProto(obj, makeLeafDispatchRecord(interceptor));
    }
    if (dart.equals(mark, INTERIOR_MARK)) {
      return patchInteriorProto(obj, interceptor);
    }
    if (dart.equals(mark, DISCRIMINATED_MARK)) {
      throw new core.UnimplementedError(tag);
    }
    let isLeaf = exports.leafTags[tag] === true;
    if (isLeaf) {
      return patchProto(obj, makeLeafDispatchRecord(interceptor));
    } else {
      return patchInteriorProto(obj, interceptor);
    }
  }
  // Function patchInstance: (dynamic, dynamic) → dynamic
  function patchInstance(obj, record) {
    _interceptors.setDispatchProperty(obj, record);
    return _interceptors.dispatchRecordInterceptor(record);
  }
  // Function patchProto: (dynamic, dynamic) → dynamic
  function patchProto(obj, record) {
    _interceptors.setDispatchProperty(Object.getPrototypeOf(obj), record);
    return _interceptors.dispatchRecordInterceptor(record);
  }
  // Function patchInteriorProto: (dynamic, dynamic) → dynamic
  function patchInteriorProto(obj, interceptor) {
    let proto = Object.getPrototypeOf(obj);
    let record = _interceptors.makeDispatchRecord(interceptor, proto, null, null);
    _interceptors.setDispatchProperty(proto, record);
    return interceptor;
  }
  // Function makeLeafDispatchRecord: (dynamic) → dynamic
  function makeLeafDispatchRecord(interceptor) {
    let fieldName = _foreign_helper.JS_IS_INDEXABLE_FIELD_NAME();
    let indexability = !!interceptor[fieldName];
    return _interceptors.makeDispatchRecord(interceptor, false, null, indexability);
  }
  // Function makeDefaultDispatchRecord: (dynamic, dynamic, dynamic) → dynamic
  function makeDefaultDispatchRecord(tag, interceptorClass, proto) {
    let interceptor = interceptorClass.prototype;
    let isLeaf = exports.leafTags[tag] === true;
    if (isLeaf) {
      return makeLeafDispatchRecord(interceptor);
    } else {
      return _interceptors.makeDispatchRecord(interceptor, proto, null, null);
    }
  }
  // Function setNativeSubclassDispatchRecord: (dynamic, dynamic) → dynamic
  function setNativeSubclassDispatchRecord(proto, interceptor) {
    _interceptors.setDispatchProperty(proto, makeLeafDispatchRecord(interceptor));
  }
  // Function constructorNameFallback: (dynamic) → String
  function constructorNameFallback(object) {
    return _constructorNameFallback(object);
  }
  exports.initNativeDispatchFlag = null;
  // Function initNativeDispatch: () → void
  function initNativeDispatch() {
    if (dart.equals(true, exports.initNativeDispatchFlag))
      return;
    exports.initNativeDispatchFlag = true;
    initNativeDispatchContinue();
  }
  // Function initNativeDispatchContinue: () → void
  function initNativeDispatchContinue() {
    exports.dispatchRecordsForInstanceTags = Object.create(null);
    exports.interceptorsForUncacheableTags = Object.create(null);
    initHooks();
    let map = exports.interceptorsByTag;
    let tags = Object.getOwnPropertyNames(map);
    if (typeof window != "undefined") {
      let context = window;
      let fun = function() {
      };
      for (let i = 0; core.int['<'](i, dart.dload(tags, 'length')); i = dart.notNull(i) + 1) {
        let tag = dart.dindex(tags, i);
        let proto = dart.dcall(exports.prototypeForTagFunction, tag);
        if (proto != null) {
          let interceptorClass = map[tag];
          let record = makeDefaultDispatchRecord(tag, interceptorClass, proto);
          if (record != null) {
            _interceptors.setDispatchProperty(proto, record);
            fun.prototype = proto;
          }
        }
      }
    }
    for (let i = 0; core.int['<'](i, dart.dload(tags, 'length')); i = dart.notNull(i) + 1) {
      let tag = tags[i];
      if (/^[A-Za-z_]/.test(tag)) {
        let interceptorClass = propertyGet(map, tag);
        propertySet(map, dart.notNull(INSTANCE_CACHED_MARK) + dart.notNull(tag), interceptorClass);
        propertySet(map, dart.notNull(UNCACHED_MARK) + dart.notNull(tag), interceptorClass);
        propertySet(map, dart.notNull(LEAF_MARK) + dart.notNull(tag), interceptorClass);
        propertySet(map, dart.notNull(INTERIOR_MARK) + dart.notNull(tag), interceptorClass);
        propertySet(map, dart.notNull(DISCRIMINATED_MARK) + dart.notNull(tag), interceptorClass);
      }
    }
  }
  // Function initHooks: () → void
  function initHooks() {
    let hooks = _baseHooks();
    let _fallbackConstructorHooksTransformer = _fallbackConstructorHooksTransformerGenerator(_constructorNameFallback);
    hooks = applyHooksTransformer(_fallbackConstructorHooksTransformer, hooks);
    hooks = applyHooksTransformer(_firefoxHooksTransformer, hooks);
    hooks = applyHooksTransformer(_ieHooksTransformer, hooks);
    hooks = applyHooksTransformer(_operaHooksTransformer, hooks);
    hooks = applyHooksTransformer(_safariHooksTransformer, hooks);
    hooks = applyHooksTransformer(_fixDocumentHooksTransformer, hooks);
    hooks = applyHooksTransformer(_dartExperimentalFixupGetTagHooksTransformer, hooks);
    if (typeof dartNativeDispatchHooksTransformer != "undefined") {
      let transformers = dartNativeDispatchHooksTransformer;
      if (typeof transformers == "function") {
        transformers = new core.List.from([transformers]);
      }
      if (transformers.constructor == Array) {
        for (let i = 0; dart.notNull(i) < transformers.length; i = dart.notNull(i) + 1) {
          let transformer = transformers[i];
          if (typeof transformer == "function") {
            hooks = applyHooksTransformer(transformer, hooks);
          }
        }
      }
    }
    let getTag = hooks.getTag;
    let getUnknownTag = hooks.getUnknownTag;
    let prototypeForTag = hooks.prototypeForTag;
    exports.getTagFunction = o => getTag(o);
    exports.alternateTagFunction = (o, tag) => getUnknownTag(o, tag);
    exports.prototypeForTagFunction = tag => prototypeForTag(tag);
  }
  // Function applyHooksTransformer: (dynamic, dynamic) → dynamic
  function applyHooksTransformer(transformer, hooks) {
    let newHooks = transformer(hooks);
    return newHooks || hooks;
  }
  let _baseHooks = new _foreign_helper.JS_CONST('function() {\n  function typeNameInChrome(o) {\n    var constructor = o.constructor;\n    if (constructor) {\n      var name = constructor.name;\n      if (name) return name;\n    }\n    var s = Object.prototype.toString.call(o);\n    return s.substring(8, s.length - 1);\n  }\n  function getUnknownTag(object, tag) {\n    // This code really belongs in [getUnknownTagGenericBrowser] but having it\n    // here allows [getUnknownTag] to be tested on d8.\n    if (/^HTML[A-Z].*Element$/.test(tag)) {\n      // Check that it is not a simple JavaScript object.\n      var name = Object.prototype.toString.call(object);\n      if (name == "[object Object]") return null;\n      return "HTMLElement";\n    }\n  }\n  function getUnknownTagGenericBrowser(object, tag) {\n    if (self.HTMLElement && object instanceof HTMLElement) return "HTMLElement";\n    return getUnknownTag(object, tag);\n  }\n  function prototypeForTag(tag) {\n    if (typeof window == "undefined") return null;\n    if (typeof window[tag] == "undefined") return null;\n    var constructor = window[tag];\n    if (typeof constructor != "function") return null;\n    return constructor.prototype;\n  }\n  function discriminator(tag) { return null; }\n\n  var isBrowser = typeof navigator == "object";\n\n  return {\n    getTag: typeNameInChrome,\n    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,\n    prototypeForTag: prototypeForTag,\n    discriminator: discriminator };\n}');
  let _constructorNameFallback = new _foreign_helper.JS_CONST('function getTagFallback(o) {\n  var constructor = o.constructor;\n  if (typeof constructor == "function") {\n    var name = constructor.name;\n    // If the name is a non-empty string, we use that as the type name of this\n    // object.  There are various cases where that does not work, so we have to\n    // detect them and fall through to the toString() based implementation.\n\n    if (typeof name == "string" &&\n\n        // Sometimes the string is empty.  This test also catches minified\n        // shadow dom polyfil wrapper for Window on Firefox where the faked\n        // constructor name does not \'stick\'.  The shortest real DOM object\n        // names have three characters (e.g. URL, CSS).\n        name.length > 2 &&\n\n        // On Firefox we often get "Object" as the constructor name, even for\n        // more specialized DOM objects.\n        name !== "Object" &&\n\n        // This can happen in Opera.\n        name !== "Function.prototype") {\n      return name;\n    }\n  }\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n}');
  let _fallbackConstructorHooksTransformerGenerator = new _foreign_helper.JS_CONST('function(getTagFallback) {\n  return function(hooks) {\n    // If we are not in a browser, assume we are in d8.\n    // TODO(sra): Recognize jsshell.\n    if (typeof navigator != "object") return hooks;\n\n    var ua = navigator.userAgent;\n    // TODO(antonm): remove a reference to DumpRenderTree.\n    if (ua.indexOf("DumpRenderTree") >= 0) return hooks;\n    if (ua.indexOf("Chrome") >= 0) {\n      // Confirm constructor name is usable for dispatch.\n      function confirm(p) {\n        return typeof window == "object" && window[p] && window[p].name == p;\n      }\n      if (confirm("Window") && confirm("HTMLElement")) return hooks;\n    }\n\n    hooks.getTag = getTagFallback;\n  };\n}');
  let _ieHooksTransformer = new _foreign_helper.JS_CONST('function(hooks) {\n  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";\n  if (userAgent.indexOf("Trident/") == -1) return hooks;\n\n  var getTag = hooks.getTag;\n\n  var quickMap = {\n    "BeforeUnloadEvent": "Event",\n    "DataTransfer": "Clipboard",\n    "HTMLDDElement": "HTMLElement",\n    "HTMLDTElement": "HTMLElement",\n    "HTMLPhraseElement": "HTMLElement",\n    "Position": "Geoposition"\n  };\n\n  function getTagIE(o) {\n    var tag = getTag(o);\n    var newTag = quickMap[tag];\n    if (newTag) return newTag;\n    // Patches for types which report themselves as Objects.\n    if (tag == "Object") {\n      if (window.DataView && (o instanceof window.DataView)) return "DataView";\n    }\n    return tag;\n  }\n\n  function prototypeForTagIE(tag) {\n    var constructor = window[tag];\n    if (constructor == null) return null;\n    return constructor.prototype;\n  }\n\n  hooks.getTag = getTagIE;\n  hooks.prototypeForTag = prototypeForTagIE;\n}');
  let _fixDocumentHooksTransformer = new _foreign_helper.JS_CONST('function(hooks) {\n  var getTag = hooks.getTag;\n  var prototypeForTag = hooks.prototypeForTag;\n  function getTagFixed(o) {\n    var tag = getTag(o);\n    if (tag == "Document") {\n      // Some browsers and the polymer polyfill call both HTML and XML documents\n      // "Document", so we check for the xmlVersion property, which is the empty\n      // string on HTML documents. Since both dart:html classes Document and\n      // HtmlDocument share the same type, we must patch the instances and not\n      // the prototype.\n      if (!!o.xmlVersion) return "!Document";\n      return "!HTMLDocument";\n    }\n    return tag;\n  }\n\n  function prototypeForTagFixed(tag) {\n    if (tag == "Document") return null;  // Do not pre-patch Document.\n    return prototypeForTag(tag);\n  }\n\n  hooks.getTag = getTagFixed;\n  hooks.prototypeForTag = prototypeForTagFixed;\n}');
  let _firefoxHooksTransformer = new _foreign_helper.JS_CONST('function(hooks) {\n  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";\n  if (userAgent.indexOf("Firefox") == -1) return hooks;\n\n  var getTag = hooks.getTag;\n\n  var quickMap = {\n    "BeforeUnloadEvent": "Event",\n    "DataTransfer": "Clipboard",\n    "GeoGeolocation": "Geolocation",\n    "Location": "!Location",               // Fixes issue 18151\n    "WorkerMessageEvent": "MessageEvent",\n    "XMLDocument": "!Document"};\n\n  function getTagFirefox(o) {\n    var tag = getTag(o);\n    return quickMap[tag] || tag;\n  }\n\n  hooks.getTag = getTagFirefox;\n}');
  let _operaHooksTransformer = new _foreign_helper.JS_CONST('function(hooks) { return hooks; }\n');
  let _safariHooksTransformer = new _foreign_helper.JS_CONST('function(hooks) { return hooks; }\n');
  let _dartExperimentalFixupGetTagHooksTransformer = new _foreign_helper.JS_CONST('function(hooks) {\n  if (typeof dartExperimentalFixupGetTag != "function") return hooks;\n  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);\n}');
  let _nativeRegExp = Symbol('_nativeRegExp');
  // Function regExpGetNative: (JSSyntaxRegExp) → dynamic
  function regExpGetNative(regexp) {
    return regexp[_nativeRegExp];
  }
  let _nativeGlobalVersion = Symbol('_nativeGlobalVersion');
  // Function regExpGetGlobalNative: (JSSyntaxRegExp) → dynamic
  function regExpGetGlobalNative(regexp) {
    let nativeRegexp = regexp[_nativeGlobalVersion];
    nativeRegexp.lastIndex = 0;
    return nativeRegexp;
  }
  let _nativeAnchoredVersion = Symbol('_nativeAnchoredVersion');
  // Function regExpCaptureCount: (JSSyntaxRegExp) → int
  function regExpCaptureCount(regexp) {
    let nativeAnchoredRegExp = regexp[_nativeAnchoredVersion];
    let match = nativeAnchoredRegExp.exec('');
    return dart.as(dart.dsend(dart.dload(match, 'length'), '-', 2), core.int);
  }
  let _nativeGlobalRegExp = Symbol('_nativeGlobalRegExp');
  let _nativeAnchoredRegExp = Symbol('_nativeAnchoredRegExp');
  let _isMultiLine = Symbol('_isMultiLine');
  let _isCaseSensitive = Symbol('_isCaseSensitive');
  let _execGlobal = Symbol('_execGlobal');
  let _execAnchored = Symbol('_execAnchored');
  class JSSyntaxRegExp extends core.Object {
    toString() {
      return `RegExp/${this.pattern}/`;
    }
    JSSyntaxRegExp(source, opts) {
      let multiLine = opts && 'multiLine' in opts ? opts.multiLine : false;
      let caseSensitive = opts && 'caseSensitive' in opts ? opts.caseSensitive : true;
      this.pattern = source;
      this[_nativeRegExp] = JSSyntaxRegExp.makeNative(source, multiLine, caseSensitive, false);
      this[_nativeGlobalRegExp] = null;
      this[_nativeAnchoredRegExp] = null;
    }
    get [_nativeGlobalVersion]() {
      if (this[_nativeGlobalRegExp] != null)
        return this[_nativeGlobalRegExp];
      return this[_nativeGlobalRegExp] = JSSyntaxRegExp.makeNative(this.pattern, this[_isMultiLine], this[_isCaseSensitive], true);
    }
    get [_nativeAnchoredVersion]() {
      if (this[_nativeAnchoredRegExp] != null)
        return this[_nativeAnchoredRegExp];
      return this[_nativeAnchoredRegExp] = JSSyntaxRegExp.makeNative(`${this.pattern}|()`, this[_isMultiLine], this[_isCaseSensitive], true);
    }
    get [_isMultiLine]() {
      return this[_nativeRegExp].multiline;
    }
    get [_isCaseSensitive]() {
      return !this[_nativeRegExp].ignoreCase;
    }
    static makeNative(source, multiLine, caseSensitive, global) {
      checkString(source);
      let m = multiLine ? 'm' : '';
      let i = caseSensitive ? '' : 'i';
      let g = global ? 'g' : '';
      let regexp = function() {
        try {
          return new RegExp(source, m + i + g);
        } catch (e) {
          return e;
        }

      }();
      if (regexp instanceof RegExp)
        return regexp;
      let errorMessage = String(regexp);
      throw new core.FormatException(`Illegal RegExp pattern: ${source}, ${errorMessage}`);
    }
    firstMatch(string) {
      let m = dart.as(this[_nativeRegExp].exec(checkString(string)), core.List$(core.String));
      if (m == null)
        return null;
      return new _MatchImplementation(this, m);
    }
    hasMatch(string) {
      return this[_nativeRegExp].test(checkString(string));
    }
    stringMatch(string) {
      let match = this.firstMatch(string);
      if (match != null)
        return match.group(0);
      return null;
    }
    allMatches(string, start) {
      if (start === void 0)
        start = 0;
      checkString(string);
      checkInt(start);
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      return new _AllMatchesIterable(this, string, start);
    }
    [_execGlobal](string, start) {
      let regexp = this[_nativeGlobalVersion];
      regexp.lastIndex = start;
      let match = dart.as(regexp.exec(string), core.List);
      if (match == null)
        return null;
      return new _MatchImplementation(this, dart.as(match, core.List$(core.String)));
    }
    [_execAnchored](string, start) {
      let regexp = this[_nativeAnchoredVersion];
      regexp.lastIndex = start;
      let match = dart.as(regexp.exec(string), core.List);
      if (match == null)
        return null;
      if (match[core.$get](dart.notNull(match[core.$length]) - 1) != null)
        return null;
      match[core.$length] = dart.notNull(match[core.$length]) - 1;
      return new _MatchImplementation(this, dart.as(match, core.List$(core.String)));
    }
    matchAsPrefix(string, start) {
      if (start === void 0)
        start = 0;
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      return this[_execAnchored](string, start);
    }
    get isMultiLine() {
      return this[_isMultiLine];
    }
    get isCaseSensitive() {
      return this[_isCaseSensitive];
    }
  }
  JSSyntaxRegExp[dart.implements] = () => [core.RegExp];
  let _match = Symbol('_match');
  class _MatchImplementation extends core.Object {
    _MatchImplementation(pattern, match$) {
      this.pattern = pattern;
      this[_match] = match$;
      dart.assert(typeof this[_match].input == 'string');
      dart.assert(typeof this[_match].index == 'number');
    }
    get input() {
      return this[_match].input;
    }
    get start() {
      return this[_match].index;
    }
    get end() {
      return dart.notNull(this.start) + dart.notNull(this[_match][core.$get](0).length);
    }
    group(index) {
      return this[_match][core.$get](index);
    }
    get(index) {
      return this.group(index);
    }
    get groupCount() {
      return dart.notNull(this[_match][core.$length]) - 1;
    }
    groups(groups) {
      let out = dart.as(new core.List.from([]), core.List$(core.String));
      for (let i of groups) {
        out[core.$add](this.group(i));
      }
      return out;
    }
  }
  _MatchImplementation[dart.implements] = () => [core.Match];
  let _re = Symbol('_re');
  let _string = Symbol('_string');
  let _start = Symbol('_start');
  class _AllMatchesIterable extends collection.IterableBase$(core.Match) {
    _AllMatchesIterable(re$, string$, start$) {
      this[_re] = re$;
      this[_string] = string$;
      this[_start] = start$;
      super.IterableBase();
    }
    get [core.$iterator]() {
      return new _AllMatchesIterator(this[_re], this[_string], this[_start]);
    }
  }
  let _regExp = Symbol('_regExp');
  let _nextIndex = Symbol('_nextIndex');
  let _current = Symbol('_current');
  class _AllMatchesIterator extends core.Object {
    _AllMatchesIterator(regExp$, string$, nextIndex$) {
      this[_regExp] = regExp$;
      this[_string] = string$;
      this[_nextIndex] = nextIndex$;
      this[_current] = null;
    }
    get current() {
      return this[_current];
    }
    moveNext() {
      if (this[_string] == null)
        return false;
      if (dart.notNull(this[_nextIndex]) <= dart.notNull(this[_string].length)) {
        let match = this[_regExp][_execGlobal](this[_string], this[_nextIndex]);
        if (match != null) {
          this[_current] = match;
          let nextIndex = match.end;
          if (match.start == nextIndex) {
            nextIndex = dart.notNull(nextIndex) + 1;
          }
          this[_nextIndex] = nextIndex;
          return true;
        }
      }
      this[_current] = null;
      this[_string] = null;
      return false;
    }
  }
  _AllMatchesIterator[dart.implements] = () => [core.Iterator$(core.Match)];
  // Function firstMatchAfter: (JSSyntaxRegExp, String, int) → Match
  function firstMatchAfter(regExp, string, start) {
    return regExp[_execGlobal](string, start);
  }
  class StringMatch extends core.Object {
    StringMatch(start, input, pattern) {
      this.start = start;
      this.input = input;
      this.pattern = pattern;
    }
    get end() {
      return dart.notNull(this.start) + dart.notNull(this.pattern.length);
    }
    get(g) {
      return this.group(g);
    }
    get groupCount() {
      return 0;
    }
    group(group_) {
      if (group_ != 0) {
        throw new core.RangeError.value(group_);
      }
      return this.pattern;
    }
    groups(groups_) {
      let result = new (core.List$(core.String))();
      for (let g of groups_) {
        result[core.$add](this.group(g));
      }
      return result;
    }
  }
  StringMatch[dart.implements] = () => [core.Match];
  // Function allMatchesInStringUnchecked: (String, String, int) → List<Match>
  function allMatchesInStringUnchecked(needle, haystack, startIndex) {
    let result = new (core.List$(core.Match))();
    let length = haystack.length;
    let patternLength = needle.length;
    while (true) {
      let position = haystack.indexOf(needle, startIndex);
      if (position == -1) {
        break;
      }
      result[core.$add](new StringMatch(position, haystack, needle));
      let endIndex = dart.notNull(position) + dart.notNull(patternLength);
      if (endIndex == length) {
        break;
      } else if (position == endIndex) {
        startIndex = dart.notNull(startIndex) + 1;
      } else {
        startIndex = endIndex;
      }
    }
    return result;
  }
  // Function stringContainsUnchecked: (dynamic, dynamic, dynamic) → dynamic
  function stringContainsUnchecked(receiver, other, startIndex) {
    if (typeof other == 'string') {
      return !dart.equals(dart.dsend(receiver, 'indexOf', other, startIndex), -1);
    } else if (dart.is(other, JSSyntaxRegExp)) {
      return dart.dsend(other, 'hasMatch', dart.dsend(receiver, 'substring', startIndex));
    } else {
      let substr = dart.dsend(receiver, 'substring', startIndex);
      return dart.dload(dart.dsend(other, 'allMatches', substr), 'isNotEmpty');
    }
  }
  // Function stringReplaceJS: (dynamic, dynamic, dynamic) → dynamic
  function stringReplaceJS(receiver, replacer, to) {
    to = to.replace(/\$/g, "$$$$");
    return receiver.replace(replacer, to);
  }
  // Function stringReplaceFirstRE: (dynamic, dynamic, dynamic, dynamic) → dynamic
  function stringReplaceFirstRE(receiver, regexp, to, startIndex) {
    let match = dart.dsend(regexp, _execGlobal, receiver, startIndex);
    if (match == null)
      return receiver;
    let start = dart.dload(match, 'start');
    let end = dart.dload(match, 'end');
    return `${dart.dsend(receiver, 'substring', 0, start)}${to}${dart.dsend(receiver, 'substring', end)}`;
  }
  let ESCAPE_REGEXP = '[[\\]{}()*+?.\\\\^$|]';
  // Function stringReplaceAllUnchecked: (dynamic, dynamic, dynamic) → dynamic
  function stringReplaceAllUnchecked(receiver, from, to) {
    checkString(to);
    if (typeof from == 'string') {
      if (dart.equals(from, "")) {
        if (dart.equals(receiver, "")) {
          return to;
        } else {
          let result = new core.StringBuffer();
          let length = dart.as(dart.dload(receiver, 'length'), core.int);
          result.write(to);
          for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            result.write(dart.dindex(receiver, i));
            result.write(to);
          }
          return result.toString();
        }
      } else {
        let quoter = new RegExp(ESCAPE_REGEXP, 'g');
        let quoted = from.replace(quoter, "\\$&");
        let replacer = new RegExp(quoted, 'g');
        return stringReplaceJS(receiver, replacer, to);
      }
    } else if (dart.is(from, JSSyntaxRegExp)) {
      let re = regExpGetGlobalNative(dart.as(from, JSSyntaxRegExp));
      return stringReplaceJS(receiver, re, to);
    } else {
      checkNull(from);
      throw "String.replaceAll(Pattern) UNIMPLEMENTED";
    }
  }
  // Function _matchString: (Match) → String
  function _matchString(match) {
    return match.get(0);
  }
  // Function _stringIdentity: (String) → String
  function _stringIdentity(string) {
    return string;
  }
  // Function stringReplaceAllFuncUnchecked: (dynamic, dynamic, dynamic, dynamic) → dynamic
  function stringReplaceAllFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
    if (!dart.is(pattern, core.Pattern)) {
      throw new core.ArgumentError(`${pattern} is not a Pattern`);
    }
    if (onMatch == null)
      onMatch = _matchString;
    if (onNonMatch == null)
      onNonMatch = _stringIdentity;
    if (typeof pattern == 'string') {
      return stringReplaceAllStringFuncUnchecked(receiver, pattern, onMatch, onNonMatch);
    }
    let buffer = new core.StringBuffer();
    let startIndex = 0;
    for (let match of dart.as(dart.dsend(pattern, 'allMatches', receiver), core.Iterable$(core.Match))) {
      buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex, match.start)));
      buffer.write(dart.dcall(onMatch, match));
      startIndex = match.end;
    }
    buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex)));
    return buffer.toString();
  }
  // Function stringReplaceAllEmptyFuncUnchecked: (dynamic, dynamic, dynamic) → dynamic
  function stringReplaceAllEmptyFuncUnchecked(receiver, onMatch, onNonMatch) {
    let buffer = new core.StringBuffer();
    let length = dart.as(dart.dload(receiver, 'length'), core.int);
    let i = 0;
    buffer.write(dart.dcall(onNonMatch, ""));
    while (dart.notNull(i) < dart.notNull(length)) {
      buffer.write(dart.dcall(onMatch, new StringMatch(i, dart.as(receiver, core.String), "")));
      let code = dart.as(dart.dsend(receiver, 'codeUnitAt', i), core.int);
      if ((dart.notNull(code) & ~1023) == 55296 && dart.notNull(length) > dart.notNull(i) + 1) {
        code = dart.as(dart.dsend(receiver, 'codeUnitAt', dart.notNull(i) + 1), core.int);
        if ((dart.notNull(code) & ~1023) == 56320) {
          buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', i, dart.notNull(i) + 2)));
          i = dart.notNull(i) + 2;
          continue;
        }
      }
      buffer.write(dart.dcall(onNonMatch, dart.dindex(receiver, i)));
      i = dart.notNull(i) + 1;
    }
    buffer.write(dart.dcall(onMatch, new StringMatch(i, dart.as(receiver, core.String), "")));
    buffer.write(dart.dcall(onNonMatch, ""));
    return buffer.toString();
  }
  // Function stringReplaceAllStringFuncUnchecked: (dynamic, dynamic, dynamic, dynamic) → dynamic
  function stringReplaceAllStringFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
    let patternLength = dart.as(dart.dload(pattern, 'length'), core.int);
    if (patternLength == 0) {
      return stringReplaceAllEmptyFuncUnchecked(receiver, onMatch, onNonMatch);
    }
    let length = dart.as(dart.dload(receiver, 'length'), core.int);
    let buffer = new core.StringBuffer();
    let startIndex = 0;
    while (dart.notNull(startIndex) < dart.notNull(length)) {
      let position = dart.as(dart.dsend(receiver, 'indexOf', pattern, startIndex), core.int);
      if (position == -1) {
        break;
      }
      buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex, position)));
      buffer.write(dart.dcall(onMatch, new StringMatch(position, dart.as(receiver, core.String), dart.as(pattern, core.String))));
      startIndex = dart.notNull(position) + dart.notNull(patternLength);
    }
    buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex)));
    return buffer.toString();
  }
  // Function stringReplaceFirstUnchecked: (dynamic, dynamic, dynamic, [int]) → dynamic
  function stringReplaceFirstUnchecked(receiver, from, to, startIndex) {
    if (startIndex === void 0)
      startIndex = 0;
    if (typeof from == 'string') {
      let index = dart.dsend(receiver, 'indexOf', from, startIndex);
      if (dart.dsend(index, '<', 0))
        return receiver;
      return `${dart.dsend(receiver, 'substring', 0, index)}${to}` + `${dart.dsend(receiver, 'substring', dart.dsend(index, '+', dart.dload(from, 'length')))}`;
    } else if (dart.is(from, JSSyntaxRegExp)) {
      return startIndex == 0 ? stringReplaceJS(receiver, regExpGetNative(dart.as(from, JSSyntaxRegExp)), to) : stringReplaceFirstRE(receiver, from, to, startIndex);
    } else {
      checkNull(from);
      throw "String.replace(Pattern) UNIMPLEMENTED";
    }
  }
  // Function stringJoinUnchecked: (dynamic, dynamic) → dynamic
  function stringJoinUnchecked(array, separator) {
    return array.join(separator);
  }
  // Function createRuntimeType: (String) → Type
  function createRuntimeType(name) {
    return new TypeImpl(name);
  }
  let _typeName = Symbol('_typeName');
  let _unmangledName = Symbol('_unmangledName');
  class TypeImpl extends core.Object {
    TypeImpl(typeName$) {
      this[_typeName] = typeName$;
      this[_unmangledName] = null;
    }
    toString() {
      if (this[_unmangledName] != null)
        return this[_unmangledName];
      let unmangledName = _js_names.unmangleAllIdentifiersIfPreservedAnyways(this[_typeName]);
      return this[_unmangledName] = unmangledName;
    }
    get hashCode() {
      return this[_typeName].hashCode;
    }
    ['=='](other) {
      return dart.is(other, TypeImpl) && dart.equals(this[_typeName], dart.dload(other, _typeName));
    }
  }
  TypeImpl[dart.implements] = () => [core.Type];
  class TypeVariable extends core.Object {
    TypeVariable(owner, name, bound) {
      this.owner = owner;
      this.name = name;
      this.bound = bound;
    }
  }
  // Function getMangledTypeName: (TypeImpl) → dynamic
  function getMangledTypeName(type) {
    return type[_typeName];
  }
  // Function setRuntimeTypeInfo: (Object, dynamic) → Object
  function setRuntimeTypeInfo(target, typeInfo) {
    dart.assert(dart.notNull(typeInfo == null) || dart.notNull(isJsArray(typeInfo)));
    if (target != null)
      target.$builtinTypeInfo = typeInfo;
    return target;
  }
  // Function getRuntimeTypeInfo: (Object) → dynamic
  function getRuntimeTypeInfo(target) {
    if (target == null)
      return null;
    return target.$builtinTypeInfo;
  }
  // Function getRuntimeTypeArguments: (dynamic, dynamic) → dynamic
  function getRuntimeTypeArguments(target, substitutionName) {
    let substitution = getField(target, `${_foreign_helper.JS_OPERATOR_AS_PREFIX()}${substitutionName}`);
    return substitute(substitution, getRuntimeTypeInfo(target));
  }
  // Function getRuntimeTypeArgument: (Object, String, int) → dynamic
  function getRuntimeTypeArgument(target, substitutionName, index) {
    let arguments$ = getRuntimeTypeArguments(target, substitutionName);
    return arguments$ == null ? null : getIndex(arguments$, index);
  }
  // Function getTypeArgumentByIndex: (Object, int) → dynamic
  function getTypeArgumentByIndex(target, index) {
    let rti = getRuntimeTypeInfo(target);
    return rti == null ? null : getIndex(rti, index);
  }
  // Function copyTypeArguments: (Object, Object) → void
  function copyTypeArguments(source, target) {
    target.$builtinTypeInfo = source.$builtinTypeInfo;
  }
  // Function getClassName: (dynamic) → String
  function getClassName(object) {
    return _interceptors.getInterceptor(object).constructor.builtin$cls;
  }
  // Function getRuntimeTypeAsString: (dynamic, {onTypeVariable: (int) → String}) → String
  function getRuntimeTypeAsString(runtimeType, opts) {
    let onTypeVariable = opts && 'onTypeVariable' in opts ? opts.onTypeVariable : null;
    dart.assert(isJsArray(runtimeType));
    let className = getConstructorName(getIndex(runtimeType, 0));
    return `${className}` + `${joinArguments(runtimeType, 1, {onTypeVariable: onTypeVariable})}`;
  }
  // Function getConstructorName: (dynamic) → String
  function getConstructorName(type) {
    return type.builtin$cls;
  }
  // Function runtimeTypeToString: (dynamic, {onTypeVariable: (int) → String}) → String
  function runtimeTypeToString(type, opts) {
    let onTypeVariable = opts && 'onTypeVariable' in opts ? opts.onTypeVariable : null;
    if (type == null) {
      return 'dynamic';
    } else if (isJsArray(type)) {
      return getRuntimeTypeAsString(type, {onTypeVariable: onTypeVariable});
    } else if (isJsFunction(type)) {
      return getConstructorName(type);
    } else if (typeof type == 'number') {
      if (onTypeVariable == null) {
        return type.toString();
      } else {
        return onTypeVariable(dart.as(type, core.int));
      }
    } else {
      return null;
    }
  }
  // Function joinArguments: (dynamic, int, {onTypeVariable: (int) → String}) → String
  function joinArguments(types, startIndex, opts) {
    let onTypeVariable = opts && 'onTypeVariable' in opts ? opts.onTypeVariable : null;
    if (types == null)
      return '';
    dart.assert(isJsArray(types));
    let firstArgument = true;
    let allDynamic = true;
    let buffer = new core.StringBuffer();
    for (let index = startIndex; dart.notNull(index) < dart.notNull(getLength(types)); index = dart.notNull(index) + 1) {
      if (firstArgument) {
        firstArgument = false;
      } else {
        buffer.write(', ');
      }
      let argument = getIndex(types, index);
      if (argument != null) {
        allDynamic = false;
      }
      buffer.write(runtimeTypeToString(argument, {onTypeVariable: onTypeVariable}));
    }
    return allDynamic ? '' : `<${buffer}>`;
  }
  // Function getRuntimeTypeString: (dynamic) → String
  function getRuntimeTypeString(object) {
    let className = getClassName(object);
    if (object == null)
      return className;
    let typeInfo = object.$builtinTypeInfo;
    return `${className}${joinArguments(typeInfo, 0)}`;
  }
  // Function getRuntimeType: (dynamic) → Type
  function getRuntimeType(object) {
    let type = getRuntimeTypeString(object);
    return new TypeImpl(type);
  }
  // Function substitute: (dynamic, dynamic) → dynamic
  function substitute(substitution, arguments$) {
    dart.assert(dart.notNull(substitution == null) || dart.notNull(isJsFunction(substitution)));
    dart.assert(dart.notNull(arguments$ == null) || dart.notNull(isJsArray(arguments$)));
    if (isJsFunction(substitution)) {
      substitution = invoke(substitution, arguments$);
      if (isJsArray(substitution)) {
        arguments$ = substitution;
      } else if (isJsFunction(substitution)) {
        arguments$ = invoke(substitution, arguments$);
      }
    }
    return arguments$;
  }
  // Function checkSubtype: (Object, String, List<dynamic>, String) → bool
  function checkSubtype(object, isField, checks, asField) {
    if (object == null)
      return false;
    let arguments$ = getRuntimeTypeInfo(object);
    let interceptor = _interceptors.getInterceptor(object);
    let isSubclass = getField(interceptor, isField);
    if (isSubclass == null)
      return false;
    let substitution = getField(interceptor, asField);
    return checkArguments(substitution, arguments$, checks);
  }
  // Function computeTypeName: (String, List<dynamic>) → String
  function computeTypeName(isField, arguments$) {
    let prefixLength = _foreign_helper.JS_OPERATOR_IS_PREFIX().length;
    return Primitives.formatType(isField.substring(prefixLength, isField.length), arguments$);
  }
  // Function subtypeCast: (Object, String, List<dynamic>, String) → Object
  function subtypeCast(object, isField, checks, asField) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtype(object, isField, checks, asField))) {
      let actualType = Primitives.objectTypeName(object);
      let typeName = computeTypeName(isField, checks);
      throw new CastErrorImplementation(actualType, typeName);
    }
    return object;
  }
  // Function assertSubtype: (Object, String, List<dynamic>, String) → Object
  function assertSubtype(object, isField, checks, asField) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtype(object, isField, checks, asField))) {
      let typeName = computeTypeName(isField, checks);
      throw new TypeErrorImplementation(object, typeName);
    }
    return object;
  }
  // Function assertIsSubtype: (dynamic, dynamic, String) → dynamic
  function assertIsSubtype(subtype, supertype, message) {
    if (!dart.notNull(isSubtype(subtype, supertype))) {
      throwTypeError(message);
    }
  }
  // Function throwTypeError: (dynamic) → dynamic
  function throwTypeError(message) {
    throw new TypeErrorImplementation.fromMessage(dart.as(message, core.String));
  }
  // Function checkArguments: (dynamic, dynamic, dynamic) → bool
  function checkArguments(substitution, arguments$, checks) {
    return areSubtypes(substitute(substitution, arguments$), checks);
  }
  // Function areSubtypes: (dynamic, dynamic) → bool
  function areSubtypes(s, t) {
    if (dart.notNull(s == null) || dart.notNull(t == null))
      return true;
    dart.assert(isJsArray(s));
    dart.assert(isJsArray(t));
    dart.assert(getLength(s) == getLength(t));
    let len = getLength(s);
    for (let i = 0; dart.notNull(i) < dart.notNull(len); i = dart.notNull(i) + 1) {
      if (!dart.notNull(isSubtype(getIndex(s, i), getIndex(t, i)))) {
        return false;
      }
    }
    return true;
  }
  // Function computeSignature: (dynamic, dynamic, dynamic) → dynamic
  function computeSignature(signature, context, contextName) {
    let typeArguments = getRuntimeTypeArguments(context, contextName);
    return invokeOn(signature, context, typeArguments);
  }
  // Function isSupertypeOfNull: (dynamic) → bool
  function isSupertypeOfNull(type) {
    return dart.notNull(type == null) || getConstructorName(type) == _foreign_helper.JS_OBJECT_CLASS_NAME() || getConstructorName(type) == _foreign_helper.JS_NULL_CLASS_NAME();
  }
  // Function checkSubtypeOfRuntimeType: (dynamic, dynamic) → bool
  function checkSubtypeOfRuntimeType(o, t) {
    if (o == null)
      return isSupertypeOfNull(t);
    if (t == null)
      return true;
    let rti = getRuntimeTypeInfo(o);
    o = _interceptors.getInterceptor(o);
    let type = o.constructor;
    if (rti != null) {
      rti = rti.slice();
      rti.splice(0, 0, type);
      type = rti;
    } else if (hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`)) {
      let signatureName = `${_foreign_helper.JS_OPERATOR_IS_PREFIX()}_${getField(t, _foreign_helper.JS_FUNCTION_TYPE_TAG())}`;
      if (hasField(o, signatureName))
        return true;
      let targetSignatureFunction = getField(o, `${_foreign_helper.JS_SIGNATURE_NAME()}`);
      if (targetSignatureFunction == null)
        return false;
      type = invokeOn(targetSignatureFunction, o, null);
      return isFunctionSubtype(type, t);
    }
    return isSubtype(type, t);
  }
  // Function subtypeOfRuntimeTypeCast: (Object, dynamic) → Object
  function subtypeOfRuntimeTypeCast(object, type) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtypeOfRuntimeType(object, type))) {
      let actualType = Primitives.objectTypeName(object);
      throw new CastErrorImplementation(actualType, runtimeTypeToString(type));
    }
    return object;
  }
  // Function assertSubtypeOfRuntimeType: (Object, dynamic) → Object
  function assertSubtypeOfRuntimeType(object, type) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtypeOfRuntimeType(object, type))) {
      throw new TypeErrorImplementation(object, runtimeTypeToString(type));
    }
    return object;
  }
  // Function getArguments: (dynamic) → dynamic
  function getArguments(type) {
    return isJsArray(type) ? type.slice(1) : null;
  }
  // Function isSubtype: (dynamic, dynamic) → bool
  function isSubtype(s, t) {
    if (isIdentical(s, t))
      return true;
    if (dart.notNull(s == null) || dart.notNull(t == null))
      return true;
    if (hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`)) {
      return isFunctionSubtype(s, t);
    }
    if (hasField(s, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`)) {
      return getConstructorName(t) == _foreign_helper.JS_FUNCTION_CLASS_NAME();
    }
    let typeOfS = isJsArray(s) ? getIndex(s, 0) : s;
    let typeOfT = isJsArray(t) ? getIndex(t, 0) : t;
    let name = runtimeTypeToString(typeOfT);
    let substitution = null;
    if (isNotIdentical(typeOfT, typeOfS)) {
      let test = `${_foreign_helper.JS_OPERATOR_IS_PREFIX()}${name}`;
      let typeOfSPrototype = typeOfS.prototype;
      if (hasNoField(typeOfSPrototype, test))
        return false;
      let field = `${_foreign_helper.JS_OPERATOR_AS_PREFIX()}${runtimeTypeToString(typeOfT)}`;
      substitution = getField(typeOfSPrototype, field);
    }
    if (!dart.notNull(isJsArray(s)) && dart.notNull(substitution == null) || !dart.notNull(isJsArray(t))) {
      return true;
    }
    return checkArguments(substitution, getArguments(s), getArguments(t));
  }
  // Function isAssignable: (dynamic, dynamic) → bool
  function isAssignable(s, t) {
    return dart.notNull(isSubtype(s, t)) || dart.notNull(isSubtype(t, s));
  }
  // Function areAssignable: (List<dynamic>, List, bool) → bool
  function areAssignable(s, t, allowShorter) {
    if (dart.notNull(t == null) && dart.notNull(s == null))
      return true;
    if (t == null)
      return allowShorter;
    if (s == null)
      return false;
    dart.assert(isJsArray(s));
    dart.assert(isJsArray(t));
    let sLength = getLength(s);
    let tLength = getLength(t);
    if (allowShorter) {
      if (dart.notNull(sLength) < dart.notNull(tLength))
        return false;
    } else {
      if (sLength != tLength)
        return false;
    }
    for (let i = 0; dart.notNull(i) < dart.notNull(tLength); i = dart.notNull(i) + 1) {
      if (!dart.notNull(isAssignable(getIndex(s, i), getIndex(t, i)))) {
        return false;
      }
    }
    return true;
  }
  // Function areAssignableMaps: (dynamic, dynamic) → bool
  function areAssignableMaps(s, t) {
    if (t == null)
      return true;
    if (s == null)
      return false;
    dart.assert(isJsObject(s));
    dart.assert(isJsObject(t));
    let names = _interceptors.JSArray.markFixedList(dart.as(Object.getOwnPropertyNames(t), core.List));
    for (let i = 0; dart.notNull(i) < dart.notNull(names[core.$length]); i = dart.notNull(i) + 1) {
      let name = names[core.$get](i);
      if (!Object.hasOwnProperty.call(s, name)) {
        return false;
      }
      let tType = t[name];
      let sType = s[name];
      if (!dart.notNull(isAssignable(tType, sType)))
        return false;
    }
    return true;
  }
  // Function isFunctionSubtype: (dynamic, dynamic) → bool
  function isFunctionSubtype(s, t) {
    dart.assert(hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`));
    if (hasNoField(s, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`))
      return false;
    if (hasField(s, `${_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()}`)) {
      if (dart.dsend(hasNoField(t, `${_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()}`), '&&', hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}`))) {
        return false;
      }
    } else if (hasNoField(t, `${_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()}`)) {
      let sReturnType = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}`);
      let tReturnType = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}`);
      if (!dart.notNull(isAssignable(sReturnType, tReturnType)))
        return false;
    }
    let sParameterTypes = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()}`);
    let tParameterTypes = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()}`);
    let sOptionalParameterTypes = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()}`);
    let tOptionalParameterTypes = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()}`);
    let sParametersLen = sParameterTypes != null ? getLength(sParameterTypes) : 0;
    let tParametersLen = tParameterTypes != null ? getLength(tParameterTypes) : 0;
    let sOptionalParametersLen = sOptionalParameterTypes != null ? getLength(sOptionalParameterTypes) : 0;
    let tOptionalParametersLen = tOptionalParameterTypes != null ? getLength(tOptionalParameterTypes) : 0;
    if (dart.notNull(sParametersLen) > dart.notNull(tParametersLen)) {
      return false;
    }
    if (dart.notNull(sParametersLen) + dart.notNull(sOptionalParametersLen) < dart.notNull(tParametersLen) + dart.notNull(tOptionalParametersLen)) {
      return false;
    }
    if (sParametersLen == tParametersLen) {
      if (!dart.notNull(areAssignable(dart.as(sParameterTypes, core.List), dart.as(tParameterTypes, core.List), false)))
        return false;
      if (!dart.notNull(areAssignable(dart.as(sOptionalParameterTypes, core.List), dart.as(tOptionalParameterTypes, core.List), true))) {
        return false;
      }
    } else {
      let pos = 0;
      for (; dart.notNull(pos) < dart.notNull(sParametersLen); pos = dart.notNull(pos) + 1) {
        if (!dart.notNull(isAssignable(getIndex(sParameterTypes, pos), getIndex(tParameterTypes, pos)))) {
          return false;
        }
      }
      let sPos = 0;
      let tPos = pos;
      for (; dart.notNull(tPos) < dart.notNull(tParametersLen); sPos = dart.notNull(sPos) + 1, tPos = dart.notNull(tPos) + 1) {
        if (!dart.notNull(isAssignable(getIndex(sOptionalParameterTypes, sPos), getIndex(tParameterTypes, tPos)))) {
          return false;
        }
      }
      tPos = 0;
      for (; dart.notNull(tPos) < dart.notNull(tOptionalParametersLen); sPos = dart.notNull(sPos) + 1, tPos = dart.notNull(tPos) + 1) {
        if (!dart.notNull(isAssignable(getIndex(sOptionalParameterTypes, sPos), getIndex(tOptionalParameterTypes, tPos)))) {
          return false;
        }
      }
    }
    let sNamedParameters = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()}`);
    let tNamedParameters = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()}`);
    return areAssignableMaps(sNamedParameters, tNamedParameters);
  }
  // Function invoke: (dynamic, dynamic) → dynamic
  function invoke(func, arguments$) {
    return invokeOn(func, null, arguments$);
  }
  // Function invokeOn: (dynamic, dynamic, dynamic) → Object
  function invokeOn(func, receiver, arguments$) {
    dart.assert(isJsFunction(func));
    dart.assert(dart.notNull(arguments$ == null) || dart.notNull(isJsArray(arguments$)));
    return func.apply(receiver, arguments$);
  }
  // Function call: (dynamic, String) → dynamic
  function call(object, name) {
    return object[name]();
  }
  // Function getField: (dynamic, String) → dynamic
  function getField(object, name) {
    return object[name];
  }
  // Function getIndex: (dynamic, int) → dynamic
  function getIndex(array, index) {
    dart.assert(isJsArray(array));
    return array[index];
  }
  // Function getLength: (dynamic) → int
  function getLength(array) {
    dart.assert(isJsArray(array));
    return array.length;
  }
  // Function isJsArray: (dynamic) → bool
  function isJsArray(value) {
    return dart.is(value, _interceptors.JSArray);
  }
  // Function hasField: (dynamic, dynamic) → dynamic
  function hasField(object, name) {
    return name in object;
  }
  // Function hasNoField: (dynamic, dynamic) → dynamic
  function hasNoField(object, name) {
    return dart.dsend(hasField(object, name), '!');
  }
  // Function isJsFunction: (dynamic) → bool
  function isJsFunction(o) {
    return typeof o == "function";
  }
  // Function isJsObject: (dynamic) → bool
  function isJsObject(o) {
    return typeof o == 'object';
  }
  // Function isIdentical: (dynamic, dynamic) → bool
  function isIdentical(s, t) {
    return s === t;
  }
  // Function isNotIdentical: (dynamic, dynamic) → bool
  function isNotIdentical(s, t) {
    return s !== t;
  }
  class _Patch extends core.Object {
    _Patch() {
    }
  }
  let patch = new _Patch();
  class InternalMap extends core.Object {}
  // Function requiresPreamble: () → dynamic
  function requiresPreamble() {
  }
  // Function isJsIndexable: (dynamic, dynamic) → bool
  function isJsIndexable(object, record) {
    if (record != null) {
      let result = _interceptors.dispatchRecordIndexability(record);
      if (result != null)
        return dart.as(result, core.bool);
    }
    return dart.is(object, exports.JavaScriptIndexingBehavior);
  }
  // Function S: (dynamic) → String
  function S(value) {
    if (typeof value == 'string')
      return dart.as(value, core.String);
    if (dart.is(value, core.num)) {
      if (!dart.equals(value, 0)) {
        return "" + value;
      }
    } else if (dart.equals(true, value)) {
      return 'true';
    } else if (dart.equals(false, value)) {
      return 'false';
    } else if (value == null) {
      return 'null';
    }
    let res = value.toString();
    if (!(typeof res == 'string'))
      throw new core.ArgumentError(value);
    return res;
  }
  // Function createInvocationMirror: (String, dynamic, dynamic, dynamic, dynamic) → dynamic
  function createInvocationMirror(name, internalName, kind, arguments$, argumentNames) {
    return new JSInvocationMirror(name, dart.as(internalName, core.String), dart.as(kind, core.int), dart.as(arguments$, core.List), dart.as(argumentNames, core.List));
  }
  // Function createUnmangledInvocationMirror: (Symbol, dynamic, dynamic, dynamic, dynamic) → dynamic
  function createUnmangledInvocationMirror(symbol, internalName, kind, arguments$, argumentNames) {
    return new JSInvocationMirror(symbol, dart.as(internalName, core.String), dart.as(kind, core.int), dart.as(arguments$, core.List), dart.as(argumentNames, core.List));
  }
  // Function throwInvalidReflectionError: (String) → void
  function throwInvalidReflectionError(memberName) {
    throw new core.UnsupportedError(`Can't use '${memberName}' in reflection ` + "because it is not included in a @MirrorsUsed annotation.");
  }
  // Function traceHelper: (String) → void
  function traceHelper(method) {
    if (!this.cache) {
      this.cache = Object.create(null);
    }
    if (!this.cache[method]) {
      console.log(method);
      this.cache[method] = true;
    }
  }
  let _memberName = Symbol('_memberName');
  let _internalName = Symbol('_internalName');
  let _kind = Symbol('_kind');
  let _arguments = Symbol('_arguments');
  let _namedArgumentNames = Symbol('_namedArgumentNames');
  let _namedIndices = Symbol('_namedIndices');
  let _getCachedInvocation = Symbol('_getCachedInvocation');
  class JSInvocationMirror extends core.Object {
    JSInvocationMirror(memberName$, internalName$, kind$, arguments$, namedArgumentNames) {
      this[_memberName] = memberName$;
      this[_internalName] = internalName$;
      this[_kind] = kind$;
      this[_arguments] = arguments$;
      this[_namedArgumentNames] = namedArgumentNames;
      this[_namedIndices] = null;
    }
    get memberName() {
      if (dart.is(this[_memberName], core.Symbol))
        return dart.as(this[_memberName], core.Symbol);
      let name = dart.as(this[_memberName], core.String);
      let unmangledName = _js_names.mangledNames.get(name);
      if (unmangledName != null) {
        name = unmangledName.split(':')[core.$get](0);
      } else {
        if (_js_names.mangledNames.get(this[_internalName]) == null) {
          core.print(`Warning: '${name}' is used reflectively but not in MirrorsUsed. ` + "This will break minified code.");
        }
      }
      this[_memberName] = new _internal.Symbol.unvalidated(name);
      return dart.as(this[_memberName], core.Symbol);
    }
    get isMethod() {
      return this[_kind] == JSInvocationMirror.METHOD;
    }
    get isGetter() {
      return this[_kind] == JSInvocationMirror.GETTER;
    }
    get isSetter() {
      return this[_kind] == JSInvocationMirror.SETTER;
    }
    get isAccessor() {
      return this[_kind] != JSInvocationMirror.METHOD;
    }
    get positionalArguments() {
      if (this.isGetter)
        return /* Unimplemented const */new core.List.from([]);
      let argumentCount = dart.notNull(this[_arguments][core.$length]) - dart.notNull(this[_namedArgumentNames][core.$length]);
      if (argumentCount == 0)
        return /* Unimplemented const */new core.List.from([]);
      let list = new core.List.from([]);
      for (let index = 0; dart.notNull(index) < dart.notNull(argumentCount); index = dart.notNull(index) + 1) {
        list[core.$add](this[_arguments][core.$get](index));
      }
      return dart.as(makeLiteralListConst(list), core.List);
    }
    get namedArguments() {
      if (this.isAccessor)
        return dart.map();
      let namedArgumentCount = this[_namedArgumentNames][core.$length];
      let namedArgumentsStartIndex = dart.notNull(this[_arguments][core.$length]) - dart.notNull(namedArgumentCount);
      if (namedArgumentCount == 0)
        return dart.map();
      let map = new (core.Map$(core.Symbol, dart.dynamic))();
      for (let i = 0; dart.notNull(i) < dart.notNull(namedArgumentCount); i = dart.notNull(i) + 1) {
        map.set(new _internal.Symbol.unvalidated(dart.as(this[_namedArgumentNames][core.$get](i), core.String)), this[_arguments][core.$get](dart.notNull(namedArgumentsStartIndex) + dart.notNull(i)));
      }
      return map;
    }
    [_getCachedInvocation](object) {
      let interceptor = _interceptors.getInterceptor(object);
      let receiver = object;
      let name = this[_internalName];
      let arguments$ = this[_arguments];
      let interceptedNames = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.INTERCEPTED_NAMES);
      let isIntercepted = Object.prototype.hasOwnProperty.call(interceptedNames, name);
      if (isIntercepted) {
        receiver = interceptor;
        if (object === interceptor) {
          interceptor = null;
        }
      } else {
        interceptor = null;
      }
      let isCatchAll = false;
      let method = receiver[name];
      if (typeof method != "function") {
        let baseName = _internal.Symbol.getName(dart.as(this.memberName, _internal.Symbol));
        method = receiver[baseName + "*"];
        if (method == null) {
          interceptor = _interceptors.getInterceptor(object);
          method = interceptor[baseName + "*"];
          if (method != null) {
            isIntercepted = true;
            receiver = interceptor;
          } else {
            interceptor = null;
          }
        }
        isCatchAll = true;
      }
      if (typeof method == "function") {
        if (isCatchAll) {
          return new CachedCatchAllInvocation(name, method, isIntercepted, dart.as(interceptor, _interceptors.Interceptor));
        } else {
          return new CachedInvocation(name, method, isIntercepted, dart.as(interceptor, _interceptors.Interceptor));
        }
      } else {
        return new CachedNoSuchMethodInvocation(interceptor);
      }
    }
    static invokeFromMirror(invocation, victim) {
      let cached = invocation[_getCachedInvocation](victim);
      if (dart.dload(cached, 'isNoSuchMethod')) {
        return dart.dsend(cached, 'invokeOn', victim, invocation);
      } else {
        return dart.dsend(cached, 'invokeOn', victim, invocation[_arguments]);
      }
    }
    static getCachedInvocation(invocation, victim) {
      return invocation[_getCachedInvocation](victim);
    }
  }
  JSInvocationMirror[dart.implements] = () => [core.Invocation];
  JSInvocationMirror.METHOD = 0;
  JSInvocationMirror.GETTER = 1;
  JSInvocationMirror.SETTER = 2;
  class CachedInvocation extends core.Object {
    CachedInvocation(mangledName, jsFunction, isIntercepted, cachedInterceptor) {
      this.mangledName = mangledName;
      this.jsFunction = jsFunction;
      this.isIntercepted = isIntercepted;
      this.cachedInterceptor = cachedInterceptor;
    }
    get isNoSuchMethod() {
      return false;
    }
    get isGetterStub() {
      return !!this.jsFunction.$getterStub;
    }
    invokeOn(victim, arguments$) {
      let receiver = victim;
      if (!dart.notNull(this.isIntercepted)) {
        if (!dart.is(arguments$, _interceptors.JSArray))
          arguments$ = new core.List.from(arguments$);
      } else {
        let _$ = new core.List.from([victim]);
        _$[core.$addAll](arguments$);
        arguments$ = _$;
        if (this.cachedInterceptor != null)
          receiver = this.cachedInterceptor;
      }
      return this.jsFunction.apply(receiver, arguments$);
    }
  }
  class CachedCatchAllInvocation extends CachedInvocation {
    CachedCatchAllInvocation(name, jsFunction, isIntercepted, cachedInterceptor) {
      this.info = new ReflectionInfo(jsFunction);
      super.CachedInvocation(name, jsFunction, isIntercepted, cachedInterceptor);
    }
    get isGetterStub() {
      return false;
    }
    invokeOn(victim, arguments$) {
      let receiver = victim;
      let providedArgumentCount = null;
      let fullParameterCount = dart.notNull(this.info.requiredParameterCount) + dart.notNull(this.info.optionalParameterCount);
      if (!dart.notNull(this.isIntercepted)) {
        if (dart.is(arguments$, _interceptors.JSArray)) {
          providedArgumentCount = arguments$[core.$length];
          if (dart.notNull(providedArgumentCount) < dart.notNull(fullParameterCount)) {
            arguments$ = new core.List.from(arguments$);
          }
        } else {
          arguments$ = new core.List.from(arguments$);
          providedArgumentCount = arguments$[core.$length];
        }
      } else {
        let _$ = new core.List.from([victim]);
        _$[core.$addAll](arguments$);
        arguments$ = _$;
        if (this.cachedInterceptor != null)
          receiver = this.cachedInterceptor;
        providedArgumentCount = dart.notNull(arguments$[core.$length]) - 1;
      }
      if (dart.notNull(this.info.areOptionalParametersNamed) && dart.notNull(providedArgumentCount) > dart.notNull(this.info.requiredParameterCount)) {
        throw new UnimplementedNoSuchMethodError(`Invocation of unstubbed method '${this.info.reflectionName}'` + ` with ${arguments$[core.$length]} arguments.`);
      } else if (dart.notNull(providedArgumentCount) < dart.notNull(this.info.requiredParameterCount)) {
        throw new UnimplementedNoSuchMethodError(`Invocation of unstubbed method '${this.info.reflectionName}'` + ` with ${providedArgumentCount} arguments (too few).`);
      } else if (dart.notNull(providedArgumentCount) > dart.notNull(fullParameterCount)) {
        throw new UnimplementedNoSuchMethodError(`Invocation of unstubbed method '${this.info.reflectionName}'` + ` with ${providedArgumentCount} arguments (too many).`);
      }
      for (let i = providedArgumentCount; dart.notNull(i) < dart.notNull(fullParameterCount); i = dart.notNull(i) + 1) {
        arguments$[core.$add](getMetadata(this.info.defaultValue(i)));
      }
      return this.jsFunction.apply(receiver, arguments$);
    }
  }
  class CachedNoSuchMethodInvocation extends core.Object {
    CachedNoSuchMethodInvocation(interceptor) {
      this.interceptor = interceptor;
    }
    get isNoSuchMethod() {
      return true;
    }
    get isGetterStub() {
      return false;
    }
    invokeOn(victim, invocation) {
      let receiver = this.interceptor == null ? victim : this.interceptor;
      return dart.dsend(receiver, 'noSuchMethod', invocation);
    }
  }
  class ReflectionInfo extends core.Object {
    internal(jsFunction, data, isAccessor, requiredParameterCount, optionalParameterCount, areOptionalParametersNamed, functionType) {
      this.jsFunction = jsFunction;
      this.data = data;
      this.isAccessor = isAccessor;
      this.requiredParameterCount = requiredParameterCount;
      this.optionalParameterCount = optionalParameterCount;
      this.areOptionalParametersNamed = areOptionalParametersNamed;
      this.functionType = functionType;
      this.cachedSortedIndices = null;
    }
    ReflectionInfo(jsFunction) {
      let data = dart.as(jsFunction.$reflectionInfo, core.List);
      if (data == null)
        return null;
      data = _interceptors.JSArray.markFixedList(data);
      let requiredParametersInfo = data[ReflectionInfo.REQUIRED_PARAMETERS_INFO];
      let requiredParameterCount = requiredParametersInfo >> 1;
      let isAccessor = (dart.notNull(requiredParametersInfo) & 1) == 1;
      let optionalParametersInfo = data[ReflectionInfo.OPTIONAL_PARAMETERS_INFO];
      let optionalParameterCount = optionalParametersInfo >> 1;
      let areOptionalParametersNamed = (dart.notNull(optionalParametersInfo) & 1) == 1;
      let functionType = data[ReflectionInfo.FUNCTION_TYPE_INDEX];
      return new ReflectionInfo.internal(jsFunction, data, isAccessor, requiredParameterCount, optionalParameterCount, areOptionalParametersNamed, functionType);
    }
    parameterName(parameter) {
      let metadataIndex = null;
      if (_foreign_helper.JS_GET_FLAG('MUST_RETAIN_METADATA')) {
        metadataIndex = this.data[2 * parameter + this.optionalParameterCount + ReflectionInfo.FIRST_DEFAULT_ARGUMENT];
      } else {
        metadataIndex = this.data[parameter + this.optionalParameterCount + ReflectionInfo.FIRST_DEFAULT_ARGUMENT];
      }
      let metadata = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.METADATA);
      return metadata[metadataIndex];
    }
    parameterMetadataAnnotations(parameter) {
      if (!dart.notNull(_foreign_helper.JS_GET_FLAG('MUST_RETAIN_METADATA'))) {
        throw new core.StateError('metadata has not been preserved');
      } else {
        return dart.as(this.data[2 * parameter + this.optionalParameterCount + ReflectionInfo.FIRST_DEFAULT_ARGUMENT + 1], core.List$(core.int));
      }
    }
    defaultValue(parameter) {
      if (dart.notNull(parameter) < dart.notNull(this.requiredParameterCount))
        return null;
      return this.data[ReflectionInfo.FIRST_DEFAULT_ARGUMENT + parameter - this.requiredParameterCount];
    }
    defaultValueInOrder(parameter) {
      if (dart.notNull(parameter) < dart.notNull(this.requiredParameterCount))
        return null;
      if (!dart.notNull(this.areOptionalParametersNamed) || this.optionalParameterCount == 1) {
        return this.defaultValue(parameter);
      }
      let index = this.sortedIndex(dart.notNull(parameter) - dart.notNull(this.requiredParameterCount));
      return this.defaultValue(index);
    }
    parameterNameInOrder(parameter) {
      if (dart.notNull(parameter) < dart.notNull(this.requiredParameterCount))
        return null;
      if (!dart.notNull(this.areOptionalParametersNamed) || this.optionalParameterCount == 1) {
        return this.parameterName(parameter);
      }
      let index = this.sortedIndex(dart.notNull(parameter) - dart.notNull(this.requiredParameterCount));
      return this.parameterName(index);
    }
    sortedIndex(unsortedIndex) {
      if (this.cachedSortedIndices == null) {
        this.cachedSortedIndices = new core.List(this.optionalParameterCount);
        let positions = dart.map();
        for (let i = 0; dart.notNull(i) < dart.notNull(this.optionalParameterCount); i = dart.notNull(i) + 1) {
          let index = dart.notNull(this.requiredParameterCount) + dart.notNull(i);
          positions.set(this.parameterName(index), index);
        }
        let index = 0;
        (() => {
          let _$ = positions.keys[core.$toList]();
          _$[core.$sort]();
          return _$;
        })()[core.$forEach]((name => {
          this.cachedSortedIndices[core.$set]((() => {
            let x$ = index;
            index = dart.notNull(x$) + 1;
            return x$;
          })(), positions.get(name));
        }).bind(this));
      }
      return dart.as(this.cachedSortedIndices[core.$get](unsortedIndex), core.int);
    }
    computeFunctionRti(jsConstructor) {
      if (typeof this.functionType == "number") {
        return getMetadata(dart.as(this.functionType, core.int));
      } else if (typeof this.functionType == "function") {
        let fakeInstance = new jsConstructor();
        setRuntimeTypeInfo(fakeInstance, fakeInstance["<>"]);
        return this.functionType.apply({$receiver: fakeInstance});
      } else {
        throw new RuntimeError('Unexpected function type');
      }
    }
    get reflectionName() {
      return this.jsFunction.$reflectionName;
    }
  }
  dart.defineNamedConstructor(ReflectionInfo, 'internal');
  ReflectionInfo.REQUIRED_PARAMETERS_INFO = 0;
  ReflectionInfo.OPTIONAL_PARAMETERS_INFO = 1;
  ReflectionInfo.FUNCTION_TYPE_INDEX = 2;
  ReflectionInfo.FIRST_DEFAULT_ARGUMENT = 3;
  // Function getMetadata: (int) → dynamic
  function getMetadata(index) {
    let metadata = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.METADATA);
    return metadata[index];
  }
  let _throwFormatException = Symbol('_throwFormatException');
  let _fromCharCodeApply = Symbol('_fromCharCodeApply');
  let _mangledNameMatchesType = Symbol('_mangledNameMatchesType');
  class Primitives extends core.Object {
    static initializeStatics(id) {
      Primitives.mirrorFunctionCacheName = dart.notNull(Primitives.mirrorFunctionCacheName) + `_${id}`;
      Primitives.mirrorInvokeCacheName = dart.notNull(Primitives.mirrorInvokeCacheName) + `_${id}`;
    }
    static objectHashCode(object) {
      let hash = dart.as(object.$identityHash, core.int);
      if (hash == null) {
        hash = Math.random() * 0x3fffffff | 0;
        object.$identityHash = hash;
      }
      return hash;
    }
    static [_throwFormatException](string) {
      throw new core.FormatException(string);
    }
    static parseInt(source, radix, handleError) {
      if (handleError == null)
        handleError = dart.as(Primitives[_throwFormatException], dart.functionType(core.int, [core.String]));
      checkString(source);
      let match = /^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(source);
      let digitsIndex = 1;
      let hexIndex = 2;
      let decimalIndex = 3;
      let nonDecimalHexIndex = 4;
      if (radix == null) {
        radix = 10;
        if (match != null) {
          if (dart.dindex(match, hexIndex) != null) {
            return parseInt(source, 16);
          }
          if (dart.dindex(match, decimalIndex) != null) {
            return parseInt(source, 10);
          }
          return handleError(source);
        }
      } else {
        if (!(typeof radix == 'number'))
          throw new core.ArgumentError("Radix is not an integer");
        if (dart.notNull(radix) < 2 || dart.notNull(radix) > 36) {
          throw new core.RangeError(`Radix ${radix} not in range 2..36`);
        }
        if (match != null) {
          if (radix == 10 && dart.notNull(dart.dindex(match, decimalIndex) != null)) {
            return parseInt(source, 10);
          }
          if (dart.notNull(radix) < 10 || dart.notNull(dart.dindex(match, decimalIndex) == null)) {
            let maxCharCode = null;
            if (dart.notNull(radix) <= 10) {
              maxCharCode = 48 + dart.notNull(radix) - 1;
            } else {
              maxCharCode = 97 + dart.notNull(radix) - 10 - 1;
            }
            let digitsPart = dart.as(dart.dindex(match, digitsIndex), core.String);
            for (let i = 0; dart.notNull(i) < dart.notNull(digitsPart.length); i = dart.notNull(i) + 1) {
              let characterCode = dart.notNull(digitsPart.codeUnitAt(0)) | 32;
              if (dart.notNull(digitsPart.codeUnitAt(i)) > dart.notNull(maxCharCode)) {
                return handleError(source);
              }
            }
          }
        }
      }
      if (match == null)
        return handleError(source);
      return parseInt(source, radix);
    }
    static parseDouble(source, handleError) {
      checkString(source);
      if (handleError == null)
        handleError = dart.as(Primitives[_throwFormatException], dart.functionType(core.double, [core.String]));
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(source)) {
        return handleError(source);
      }
      let result = parseFloat(source);
      if (result.isNaN) {
        let trimmed = source.trim();
        if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
          return result;
        }
        return handleError(source);
      }
      return result;
    }
    static formatType(className, typeArguments) {
      return _js_names.unmangleAllIdentifiersIfPreservedAnyways(`${className}${joinArguments(typeArguments, 0)}`);
    }
    static objectTypeName(object) {
      let name = constructorNameFallback(_interceptors.getInterceptor(object));
      if (name == 'Object') {
        let decompiled = String(object.constructor).match(/^\s*function\s*(\S*)\s*\(/)[1];
        if (typeof decompiled == 'string')
          if (/^\w+$/.test(decompiled))
            name = dart.as(decompiled, core.String);
      }
      if (dart.notNull(name.length) > 1 && dart.notNull(core.identical(name.codeUnitAt(0), Primitives.DOLLAR_CHAR_VALUE))) {
        name = name.substring(1);
      }
      return Primitives.formatType(name, dart.as(getRuntimeTypeInfo(object), core.List));
    }
    static objectToString(object) {
      let name = Primitives.objectTypeName(object);
      return `Instance of '${name}'`;
    }
    static dateNow() {
      return Date.now();
    }
    static initTicker() {
      if (Primitives.timerFrequency != null)
        return;
      Primitives.timerFrequency = 1000;
      Primitives.timerTicks = Primitives.dateNow;
      if (typeof window == "undefined")
        return;
      let window = window;
      if (window == null)
        return;
      let performance = window.performance;
      if (performance == null)
        return;
      if (typeof performance.now != "function")
        return;
      Primitives.timerFrequency = 1000000;
      Primitives.timerTicks = () => (1000 * performance.now()).floor();
    }
    static get isD8() {
      return typeof version == "function" && typeof os == "object" && "system" in os;
    }
    static get isJsshell() {
      return typeof version == "function" && typeof system == "function";
    }
    static currentUri() {
      requiresPreamble();
      if (!!self.location) {
        return self.location.href;
      }
      return null;
    }
    static [_fromCharCodeApply](array) {
      let result = "";
      let kMaxApply = 500;
      let end = array[core.$length];
      for (let i = 0; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + dart.notNull(kMaxApply)) {
        let subarray = null;
        if (dart.notNull(end) <= dart.notNull(kMaxApply)) {
          subarray = array;
        } else {
          subarray = array.slice(i, dart.notNull(i) + dart.notNull(kMaxApply) < dart.notNull(end) ? dart.notNull(i) + dart.notNull(kMaxApply) : end);
        }
        result = result + String.fromCharCode.apply(null, subarray);
      }
      return result;
    }
    static stringFromCodePoints(codePoints) {
      let a = new core.List$(core.int).from([]);
      for (let i of dart.as(codePoints, core.Iterable)) {
        if (!(typeof i == 'number'))
          throw new core.ArgumentError(i);
        if (dart.dsend(i, '<=', 65535)) {
          a[core.$add](dart.as(i, core.int));
        } else if (dart.dsend(i, '<=', 1114111)) {
          a[core.$add](core.int['+'](55296, dart.dsend(dart.dsend(dart.dsend(i, '-', 65536), '>>', 10), '&', 1023)));
          a[core.$add](core.int['+'](56320, dart.dsend(i, '&', 1023)));
        } else {
          throw new core.ArgumentError(i);
        }
      }
      return Primitives[_fromCharCodeApply](a);
    }
    static stringFromCharCodes(charCodes) {
      for (let i of dart.as(charCodes, core.Iterable)) {
        if (!(typeof i == 'number'))
          throw new core.ArgumentError(i);
        if (dart.dsend(i, '<', 0))
          throw new core.ArgumentError(i);
        if (dart.dsend(i, '>', 65535))
          return Primitives.stringFromCodePoints(charCodes);
      }
      return Primitives[_fromCharCodeApply](dart.as(charCodes, core.List$(core.int)));
    }
    static stringFromCharCode(charCode) {
      if (core.int['<='](0, charCode)) {
        if (dart.dsend(charCode, '<=', 65535)) {
          return String.fromCharCode(charCode);
        }
        if (dart.dsend(charCode, '<=', 1114111)) {
          let bits = dart.dsend(charCode, '-', 65536);
          let low = core.int['|'](56320, dart.dsend(bits, '&', 1023));
          let high = core.int['|'](55296, dart.dsend(bits, '>>', 10));
          return String.fromCharCode(high, low);
        }
      }
      throw new core.RangeError.range(dart.as(charCode, core.num), 0, 1114111);
    }
    static stringConcatUnchecked(string1, string2) {
      return _foreign_helper.JS_STRING_CONCAT(string1, string2);
    }
    static flattenString(str) {
      return str.charCodeAt(0) == 0 ? str : str;
    }
    static getTimeZoneName(receiver) {
      let d = Primitives.lazyAsJsDate(receiver);
      let match = dart.as(/\((.*)\)/.exec(d.toString()), core.List);
      if (match != null)
        return dart.as(match[core.$get](1), core.String);
      match = dart.as(/^[A-Z,a-z]{3}\s[A-Z,a-z]{3}\s\d+\s\d{2}:\d{2}:\d{2}\s([A-Z]{3,5})\s\d{4}$/.exec(d.toString()), core.List);
      if (match != null)
        return dart.as(match[core.$get](1), core.String);
      match = dart.as(/(?:GMT|UTC)[+-]\d{4}/.exec(d.toString()), core.List);
      if (match != null)
        return dart.as(match[core.$get](0), core.String);
      return "";
    }
    static getTimeZoneOffsetInMinutes(receiver) {
      return -Primitives.lazyAsJsDate(receiver).getTimezoneOffset();
    }
    static valueFromDecomposedDate(years, month, day, hours, minutes, seconds, milliseconds, isUtc) {
      let MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
      checkInt(years);
      checkInt(month);
      checkInt(day);
      checkInt(hours);
      checkInt(minutes);
      checkInt(seconds);
      checkInt(milliseconds);
      checkBool(isUtc);
      let jsMonth = dart.dsend(month, '-', 1);
      let value = null;
      if (isUtc) {
        value = Date.UTC(years, jsMonth, day, hours, minutes, seconds, milliseconds);
      } else {
        value = new Date(years, jsMonth, day, hours, minutes, seconds, milliseconds).valueOf();
      }
      if (core.bool['||'](dart.dsend(dart.dload(value, 'isNaN'), '||', dart.dsend(value, '<', -dart.notNull(MAX_MILLISECONDS_SINCE_EPOCH))), dart.dsend(value, '>', MAX_MILLISECONDS_SINCE_EPOCH))) {
        return null;
      }
      if (dart.dsend(dart.dsend(years, '<=', 0), '||', dart.dsend(years, '<', 100)))
        return Primitives.patchUpY2K(value, years, isUtc);
      return value;
    }
    static patchUpY2K(value, years, isUtc) {
      let date = new Date(value);
      if (isUtc) {
        date.setUTCFullYear(years);
      } else {
        date.setFullYear(years);
      }
      return date.valueOf();
    }
    static lazyAsJsDate(receiver) {
      if (receiver.date === void 0) {
        receiver.date = new Date(dart.dload(receiver, 'millisecondsSinceEpoch'));
      }
      return receiver.date;
    }
    static getYear(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCFullYear() + 0 : Primitives.lazyAsJsDate(receiver).getFullYear() + 0;
    }
    static getMonth(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCMonth() + 1 : Primitives.lazyAsJsDate(receiver).getMonth() + 1;
    }
    static getDay(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCDate() + 0 : Primitives.lazyAsJsDate(receiver).getDate() + 0;
    }
    static getHours(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCHours() + 0 : Primitives.lazyAsJsDate(receiver).getHours() + 0;
    }
    static getMinutes(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCMinutes() + 0 : Primitives.lazyAsJsDate(receiver).getMinutes() + 0;
    }
    static getSeconds(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCSeconds() + 0 : Primitives.lazyAsJsDate(receiver).getSeconds() + 0;
    }
    static getMilliseconds(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCMilliseconds() + 0 : Primitives.lazyAsJsDate(receiver).getMilliseconds() + 0;
    }
    static getWeekday(receiver) {
      let weekday = dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCDay() + 0 : Primitives.lazyAsJsDate(receiver).getDay() + 0;
      return (dart.notNull(weekday) + 6) % 7 + 1;
    }
    static valueFromDateString(str) {
      if (!(typeof str == 'string'))
        throw new core.ArgumentError(str);
      let value = Date.parse(str);
      if (value.isNaN)
        throw new core.ArgumentError(str);
      return value;
    }
    static getProperty(object, key) {
      if (dart.notNull(object == null) || typeof object == 'boolean' || dart.is(object, core.num) || typeof object == 'string') {
        throw new core.ArgumentError(object);
      }
      return object[key];
    }
    static setProperty(object, key, value) {
      if (dart.notNull(object == null) || typeof object == 'boolean' || dart.is(object, core.num) || typeof object == 'string') {
        throw new core.ArgumentError(object);
      }
      object[key] = value;
    }
    static functionNoSuchMethod(func, positionalArguments, namedArguments) {
      let argumentCount = 0;
      let arguments$ = new core.List.from([]);
      let namedArgumentList = new core.List.from([]);
      if (positionalArguments != null) {
        argumentCount = dart.notNull(argumentCount) + dart.notNull(positionalArguments[core.$length]);
        arguments$[core.$addAll](positionalArguments);
      }
      let names = '';
      if (dart.notNull(namedArguments != null) && !dart.notNull(namedArguments.isEmpty)) {
        namedArguments.forEach((name, argument) => {
          names = `${names}$${name}`;
          namedArgumentList[core.$add](name);
          arguments$[core.$add](argument);
          argumentCount = dart.notNull(argumentCount) + 1;
        });
      }
      let selectorName = `${_foreign_helper.JS_GET_NAME("CALL_PREFIX")}$${argumentCount}${names}`;
      return dart.dsend(func, 'noSuchMethod', createUnmangledInvocationMirror(dart.throw_("Unimplemented SymbolLiteral: #call"), selectorName, JSInvocationMirror.METHOD, arguments$, namedArgumentList));
    }
    static applyFunction(func, positionalArguments, namedArguments) {
      return namedArguments == null ? Primitives.applyFunctionWithPositionalArguments(func, positionalArguments) : Primitives.applyFunctionWithNamedArguments(func, positionalArguments, namedArguments);
    }
    static applyFunctionWithPositionalArguments(func, positionalArguments) {
      let argumentCount = 0;
      let arguments$ = null;
      if (positionalArguments != null) {
        if (positionalArguments instanceof Array) {
          arguments$ = positionalArguments;
        } else {
          arguments$ = new core.List.from(positionalArguments);
        }
        argumentCount = arguments$.length;
      } else {
        arguments$ = new core.List.from([]);
      }
      let selectorName = `${_foreign_helper.JS_GET_NAME("CALL_PREFIX")}$${argumentCount}`;
      let jsFunction = func[selectorName];
      if (jsFunction == null) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, null);
      }
      return jsFunction.apply(func, arguments$);
    }
    static applyFunctionWithNamedArguments(func, positionalArguments, namedArguments) {
      if (namedArguments.isEmpty) {
        return Primitives.applyFunctionWithPositionalArguments(func, positionalArguments);
      }
      let interceptor = _interceptors.getInterceptor(func);
      let jsFunction = interceptor["call*"];
      if (jsFunction == null) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      let info = new ReflectionInfo(jsFunction);
      if (dart.notNull(info == null) || !dart.notNull(info.areOptionalParametersNamed)) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      if (positionalArguments != null) {
        positionalArguments = new core.List.from(positionalArguments);
      } else {
        positionalArguments = new core.List.from([]);
      }
      if (info.requiredParameterCount != positionalArguments[core.$length]) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      let defaultArguments = new core.Map();
      for (let i = 0; dart.notNull(i) < dart.notNull(info.optionalParameterCount); i = dart.notNull(i) + 1) {
        let index = dart.notNull(i) + dart.notNull(info.requiredParameterCount);
        let parameterName = info.parameterNameInOrder(index);
        let value = info.defaultValueInOrder(index);
        let defaultValue = getMetadata(value);
        defaultArguments.set(parameterName, defaultValue);
      }
      let bad = false;
      namedArguments.forEach((parameter, value) => {
        if (defaultArguments.containsKey(parameter)) {
          defaultArguments.set(parameter, value);
        } else {
          bad = true;
        }
      });
      if (bad) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      positionalArguments[core.$addAll](defaultArguments.values);
      return jsFunction.apply(func, positionalArguments);
    }
    static [_mangledNameMatchesType](mangledName, type) {
      return mangledName == type[_typeName];
    }
    static identicalImplementation(a, b) {
      return a == null ? b == null : a === b;
    }
    static extractStackTrace(error) {
      return getTraceFromException(error.$thrownJsError);
    }
  }
  Primitives.mirrorFunctionCacheName = '$cachedFunction';
  Primitives.mirrorInvokeCacheName = '$cachedInvocation';
  Primitives.DOLLAR_CHAR_VALUE = 36;
  Primitives.timerFrequency = null;
  Primitives.timerTicks = null;
  class JsCache extends core.Object {
    static allocate() {
      let result = Object.create(null);
      result.x = 0;
      delete result.x;
      return result;
    }
    static fetch(cache, key) {
      return cache[key];
    }
    static update(cache, key, value) {
      cache[key] = value;
    }
  }
  // Function iae: (dynamic) → dynamic
  function iae(argument) {
    throw new core.ArgumentError(argument);
  }
  // Function ioore: (dynamic, dynamic) → dynamic
  function ioore(receiver, index) {
    if (receiver == null)
      dart.dload(receiver, 'length');
    if (!(typeof index == 'number'))
      iae(index);
    throw new core.RangeError.value(dart.as(index, core.num));
  }
  // Function stringLastIndexOfUnchecked: (dynamic, dynamic, dynamic) → dynamic
  function stringLastIndexOfUnchecked(receiver, element, start) {
    return receiver.lastIndexOf(element, start);
  }
  // Function checkNull: (dynamic) → dynamic
  function checkNull(object) {
    if (object == null)
      throw new core.ArgumentError(null);
    return object;
  }
  // Function checkNum: (dynamic) → dynamic
  function checkNum(value) {
    if (!dart.is(value, core.num)) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  // Function checkInt: (dynamic) → dynamic
  function checkInt(value) {
    if (!(typeof value == 'number')) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  // Function checkBool: (dynamic) → dynamic
  function checkBool(value) {
    if (!(typeof value == 'boolean')) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  // Function checkString: (dynamic) → dynamic
  function checkString(value) {
    if (!(typeof value == 'string')) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  // Function wrapException: (dynamic) → dynamic
  function wrapException(ex) {
    if (ex == null)
      ex = new core.NullThrownError();
    let wrapper = new Error();
    wrapper.dartException = ex;
    if ("defineProperty" in Object) {
      Object.defineProperty(wrapper, "message", {get: _foreign_helper.DART_CLOSURE_TO_JS(toStringWrapper)});
      wrapper.name = "";
    } else {
      wrapper.toString = _foreign_helper.DART_CLOSURE_TO_JS(toStringWrapper);
    }
    return wrapper;
  }
  // Function toStringWrapper: () → dynamic
  function toStringWrapper() {
    return this.dartException.toString();
  }
  // Function throwExpression: (dynamic) → dynamic
  function throwExpression(ex) {
    throw wrapException(ex);
  }
  // Function makeLiteralListConst: (dynamic) → dynamic
  function makeLiteralListConst(list) {
    list.immutable$list = true;
    list.fixed$length = true;
    return list;
  }
  // Function throwRuntimeError: (dynamic) → dynamic
  function throwRuntimeError(message) {
    throw new RuntimeError(message);
  }
  // Function throwAbstractClassInstantiationError: (dynamic) → dynamic
  function throwAbstractClassInstantiationError(className) {
    throw new core.AbstractClassInstantiationError(dart.as(className, core.String));
  }
  let _argumentsExpr = Symbol('_argumentsExpr');
  let _expr = Symbol('_expr');
  let _method = Symbol('_method');
  let _receiver = Symbol('_receiver');
  let _pattern = Symbol('_pattern');
  class TypeErrorDecoder extends core.Object {
    TypeErrorDecoder(arguments$, argumentsExpr$, expr$, method$, receiver$, pattern$) {
      this[_arguments] = arguments$;
      this[_argumentsExpr] = argumentsExpr$;
      this[_expr] = expr$;
      this[_method] = method$;
      this[_receiver] = receiver$;
      this[_pattern] = pattern$;
    }
    matchTypeError(message) {
      let match = new RegExp(this[_pattern]).exec(message);
      if (match == null)
        return null;
      let result = Object.create(null);
      if (this[_arguments] != -1) {
        result.arguments = match[this[_arguments] + 1];
      }
      if (this[_argumentsExpr] != -1) {
        result.argumentsExpr = match[this[_argumentsExpr] + 1];
      }
      if (this[_expr] != -1) {
        result.expr = match[this[_expr] + 1];
      }
      if (this[_method] != -1) {
        result.method = match[this[_method] + 1];
      }
      if (this[_receiver] != -1) {
        result.receiver = match[this[_receiver] + 1];
      }
      return result;
    }
    static buildJavaScriptObject() {
      return {
        toString: function() {
          return "$receiver$";
        }
      };
    }
    static buildJavaScriptObjectWithNonClosure() {
      return {
        $method$: null,
        toString: function() {
          return "$receiver$";
        }
      };
    }
    static extractPattern(message) {
      message = message.replace(String({}), '$receiver$');
      message = message.replace(new RegExp(ESCAPE_REGEXP, 'g'), '\\$&');
      let match = dart.as(message.match(/\\\$[a-zA-Z]+\\\$/g), core.List$(core.String));
      if (match == null)
        match = dart.as(new core.List.from([]), core.List$(core.String));
      let arguments$ = match.indexOf('\\$arguments\\$');
      let argumentsExpr = match.indexOf('\\$argumentsExpr\\$');
      let expr = match.indexOf('\\$expr\\$');
      let method = match.indexOf('\\$method\\$');
      let receiver = match.indexOf('\\$receiver\\$');
      let pattern = message.replace('\\$arguments\\$', '((?:x|[^x])*)').replace('\\$argumentsExpr\\$', '((?:x|[^x])*)').replace('\\$expr\\$', '((?:x|[^x])*)').replace('\\$method\\$', '((?:x|[^x])*)').replace('\\$receiver\\$', '((?:x|[^x])*)');
      return new TypeErrorDecoder(arguments$, argumentsExpr, expr, method, receiver, pattern);
    }
    static provokeCallErrorOn(expression) {
      let func = function($expr$) {
        var $argumentsExpr$ = '$arguments$';
        try {
          $expr$.$method$($argumentsExpr$);
        } catch (e) {
          return e.message;
        }

      };
      return func(expression);
    }
    static provokeCallErrorOnNull() {
      let func = function() {
        var $argumentsExpr$ = '$arguments$';
        try {
          null.$method$($argumentsExpr$);
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
    static provokeCallErrorOnUndefined() {
      let func = function() {
        var $argumentsExpr$ = '$arguments$';
        try {
          (void 0).$method$($argumentsExpr$);
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
    static provokePropertyErrorOn(expression) {
      let func = function($expr$) {
        try {
          $expr$.$method$;
        } catch (e) {
          return e.message;
        }

      };
      return func(expression);
    }
    static provokePropertyErrorOnNull() {
      let func = function() {
        try {
          null.$method$;
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
    static provokePropertyErrorOnUndefined() {
      let func = function() {
        try {
          (void 0).$method$;
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
  }
  dart.defineLazyProperties(TypeErrorDecoder, {
    get noSuchMethodPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(TypeErrorDecoder.buildJavaScriptObject())), TypeErrorDecoder);
    },
    get notClosurePattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(TypeErrorDecoder.buildJavaScriptObjectWithNonClosure())), TypeErrorDecoder);
    },
    get nullCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(null)), TypeErrorDecoder);
    },
    get nullLiteralCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOnNull()), TypeErrorDecoder);
    },
    get undefinedCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(void 0)), TypeErrorDecoder);
    },
    get undefinedLiteralCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOnUndefined()), TypeErrorDecoder);
    },
    get nullPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOn(null)), TypeErrorDecoder);
    },
    get nullLiteralPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOnNull()), TypeErrorDecoder);
    },
    get undefinedPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOn(void 0)), TypeErrorDecoder);
    },
    get undefinedLiteralPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOnUndefined()), TypeErrorDecoder);
    }
  });
  let _message = Symbol('_message');
  class NullError extends core.Error {
    NullError(message$, match) {
      this[_message] = message$;
      this[_method] = dart.as(match == null ? null : match.method, core.String);
      super.Error();
    }
    toString() {
      if (this[_method] == null)
        return `NullError: ${this[_message]}`;
      return `NullError: Cannot call "${this[_method]}" on null`;
    }
  }
  NullError[dart.implements] = () => [core.NoSuchMethodError];
  class JsNoSuchMethodError extends core.Error {
    JsNoSuchMethodError(message$, match) {
      this[_message] = message$;
      this[_method] = dart.as(match == null ? null : match.method, core.String);
      this[_receiver] = dart.as(match == null ? null : match.receiver, core.String);
      super.Error();
    }
    toString() {
      if (this[_method] == null)
        return `NoSuchMethodError: ${this[_message]}`;
      if (this[_receiver] == null) {
        return `NoSuchMethodError: Cannot call "${this[_method]}" (${this[_message]})`;
      }
      return `NoSuchMethodError: Cannot call "${this[_method]}" on "${this[_receiver]}" ` + `(${this[_message]})`;
    }
  }
  JsNoSuchMethodError[dart.implements] = () => [core.NoSuchMethodError];
  class UnknownJsTypeError extends core.Error {
    UnknownJsTypeError(message$) {
      this[_message] = message$;
      super.Error();
    }
    toString() {
      return this[_message].isEmpty ? 'Error' : `Error: ${this[_message]}`;
    }
  }
  // Function unwrapException: (dynamic) → dynamic
  function unwrapException(ex) {
    // Function saveStackTrace: (dynamic) → dynamic
    function saveStackTrace(error) {
      if (dart.is(error, core.Error)) {
        let thrownStackTrace = error.$thrownJsError;
        if (thrownStackTrace == null) {
          error.$thrownJsError = ex;
        }
      }
      return error;
    }
    if (ex == null)
      return null;
    if (typeof ex !== "object")
      return ex;
    if ("dartException" in ex) {
      return saveStackTrace(ex.dartException);
    } else if (!("message" in ex)) {
      return ex;
    }
    let message = ex.message;
    if ("number" in ex && typeof ex.number == "number") {
      let number = ex.number;
      let ieErrorCode = dart.notNull(number) & 65535;
      let ieFacilityNumber = dart.notNull(number) >> 16 & 8191;
      if (ieFacilityNumber == 10) {
        switch (ieErrorCode) {
          case 438:
          {
            return saveStackTrace(new JsNoSuchMethodError(`${message} (Error ${ieErrorCode})`, null));
          }
          case 445:
          case 5007:
          {
            return saveStackTrace(new NullError(`${message} (Error ${ieErrorCode})`, null));
          }
        }
      }
    }
    if (ex instanceof TypeError) {
      let match = null;
      let nsme = TypeErrorDecoder.noSuchMethodPattern;
      let notClosure = TypeErrorDecoder.notClosurePattern;
      let nullCall = TypeErrorDecoder.nullCallPattern;
      let nullLiteralCall = TypeErrorDecoder.nullLiteralCallPattern;
      let undefCall = TypeErrorDecoder.undefinedCallPattern;
      let undefLiteralCall = TypeErrorDecoder.undefinedLiteralCallPattern;
      let nullProperty = TypeErrorDecoder.nullPropertyPattern;
      let nullLiteralProperty = TypeErrorDecoder.nullLiteralPropertyPattern;
      let undefProperty = TypeErrorDecoder.undefinedPropertyPattern;
      let undefLiteralProperty = TypeErrorDecoder.undefinedLiteralPropertyPattern;
      if ((match = dart.dsend(nsme, 'matchTypeError', message)) != null) {
        return saveStackTrace(new JsNoSuchMethodError(dart.as(message, core.String), match));
      } else if ((match = dart.dsend(notClosure, 'matchTypeError', message)) != null) {
        match.method = "call";
        return saveStackTrace(new JsNoSuchMethodError(dart.as(message, core.String), match));
      } else if (dart.notNull((match = dart.dsend(nullCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(nullLiteralCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefLiteralCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(nullProperty, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(nullLiteralCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefProperty, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefLiteralProperty, 'matchTypeError', message)) != null)) {
        return saveStackTrace(new NullError(dart.as(message, core.String), match));
      }
      return saveStackTrace(new UnknownJsTypeError(dart.as(typeof message == 'string' ? message : '', core.String)));
    }
    if (ex instanceof RangeError) {
      if (typeof message == 'string' && dart.notNull(contains(dart.as(message, core.String), 'call stack'))) {
        return new core.StackOverflowError();
      }
      return saveStackTrace(new core.ArgumentError());
    }
    if (typeof InternalError == "function" && ex instanceof InternalError) {
      if (typeof message == 'string' && dart.notNull(dart.equals(message, 'too much recursion'))) {
        return new core.StackOverflowError();
      }
    }
    return ex;
  }
  // Function getTraceFromException: (dynamic) → StackTrace
  function getTraceFromException(exception) {
    return new _StackTrace(exception);
  }
  let _exception = Symbol('_exception');
  let _trace = Symbol('_trace');
  class _StackTrace extends core.Object {
    _StackTrace(exception$) {
      this[_exception] = exception$;
      this[_trace] = null;
    }
    toString() {
      if (this[_trace] != null)
        return this[_trace];
      let trace = null;
      if (typeof this[_exception] === "object") {
        trace = dart.as(this[_exception].stack, core.String);
      }
      return this[_trace] = trace == null ? '' : trace;
    }
  }
  _StackTrace[dart.implements] = () => [core.StackTrace];
  // Function objectHashCode: (dynamic) → int
  function objectHashCode(object) {
    if (dart.notNull(object == null) || typeof object != 'object') {
      return object.hashCode;
    } else {
      return Primitives.objectHashCode(object);
    }
  }
  // Function fillLiteralMap: (dynamic, Map<dynamic, dynamic>) → dynamic
  function fillLiteralMap(keyValuePairs, result) {
    let index = 0;
    let length = getLength(keyValuePairs);
    while (dart.notNull(index) < dart.notNull(length)) {
      let key = getIndex(keyValuePairs, (() => {
        let x$ = index;
        index = dart.notNull(x$) + 1;
        return x$;
      })());
      let value = getIndex(keyValuePairs, (() => {
        let x$ = index;
        index = dart.notNull(x$) + 1;
        return x$;
      })());
      result.set(key, value);
    }
    return result;
  }
  // Function invokeClosure: (Function, dynamic, int, dynamic, dynamic, dynamic, dynamic) → dynamic
  function invokeClosure(closure, isolate, numberOfArguments, arg1, arg2, arg3, arg4) {
    if (numberOfArguments == 0) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, () => dart.dcall(closure));
    } else if (numberOfArguments == 1) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, () => dart.dcall(closure, arg1));
    } else if (numberOfArguments == 2) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, () => dart.dcall(closure, arg1, arg2));
    } else if (numberOfArguments == 3) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, () => dart.dcall(closure, arg1, arg2, arg3));
    } else if (numberOfArguments == 4) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, () => dart.dcall(closure, arg1, arg2, arg3, arg4));
    } else {
      throw new core.Exception('Unsupported number of arguments for wrapped closure');
    }
  }
  // Function convertDartClosureToJS: (dynamic, int) → dynamic
  function convertDartClosureToJS(closure, arity) {
    if (closure == null)
      return null;
    let func = closure.$identity;
    if (!!func)
      return func;
    func = function(closure, arity, context, invoke) {
      return function(a1, a2, a3, a4) {
        return invoke(closure, context, arity, a1, a2, a3, a4);
      };
    }(closure, arity, _foreign_helper.JS_CURRENT_ISOLATE_CONTEXT(), _foreign_helper.DART_CLOSURE_TO_JS(invokeClosure));
    closure.$identity = func;
    return func;
  }
  class Closure extends core.Object {
    Closure() {
    }
    static fromTearOff(receiver, functions, reflectionInfo, isStatic, jsArguments, propertyName) {
      _foreign_helper.JS_EFFECT(() => {
        BoundClosure.receiverOf(dart.as(void 0, BoundClosure));
        BoundClosure.selfOf(dart.as(void 0, BoundClosure));
      });
      let func = functions[0];
      let name = dart.as(func.$stubName, core.String);
      let callName = dart.as(func.$callName, core.String);
      func.$reflectionInfo = reflectionInfo;
      let info = new ReflectionInfo(func);
      let functionType = info.functionType;
      let prototype = isStatic ? Object.create(new TearOffClosure().constructor.prototype) : Object.create(new BoundClosure(null, null, null, null).constructor.prototype);
      prototype.$initialize = prototype.constructor;
      let constructor = isStatic ? function() {
        this.$initialize();
      } : Closure.isCsp ? function(a, b, c, d) {
        this.$initialize(a, b, c, d);
      } : new Function("a", "b", "c", "d", "this.$initialize(a,b,c,d);" + (() => {
        let x$ = Closure.functionCounter;
        Closure.functionCounter = dart.notNull(x$) + 1;
        return x$;
      })());
      prototype.constructor = constructor;
      constructor.prototype = prototype;
      let trampoline = func;
      let isIntercepted = false;
      if (!dart.notNull(isStatic)) {
        if (jsArguments.length == 1) {
          isIntercepted = true;
        }
        trampoline = Closure.forwardCallTo(receiver, func, isIntercepted);
        trampoline.$reflectionInfo = reflectionInfo;
      } else {
        prototype.$name = propertyName;
      }
      let signatureFunction = null;
      if (typeof functionType == "number") {
        let metadata = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.METADATA);
        signatureFunction = function(s) {
          return function() {
            return metadata[s];
          };
        }(functionType);
      } else if (!dart.notNull(isStatic) && typeof functionType == "function") {
        let getReceiver = isIntercepted ? _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.receiverOf) : _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
        signatureFunction = function(f, r) {
          return function() {
            return f.apply({$receiver: r(this)}, arguments$);
          };
        }(functionType, getReceiver);
      } else {
        throw 'Error in reflectionInfo.';
      }
      prototype[_foreign_helper.JS_SIGNATURE_NAME()] = signatureFunction;
      prototype[callName] = trampoline;
      for (let i = 1; dart.notNull(i) < dart.notNull(functions[core.$length]); i = dart.notNull(i) + 1) {
        let stub = functions[core.$get](i);
        let stubCallName = stub.$callName;
        if (stubCallName != null) {
          prototype[stubCallName] = isStatic ? stub : Closure.forwardCallTo(receiver, stub, isIntercepted);
        }
      }
      prototype["call*"] = trampoline;
      return constructor;
    }
    static cspForwardCall(arity, isSuperCall, stubName, func) {
      let getSelf = _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
      if (isSuperCall)
        arity = -1;
      switch (arity) {
        case 0:
        {
          return function(n, S) {
            return function() {
              return S(this)[n]();
            };
          }(stubName, getSelf);
        }
        case 1:
        {
          return function(n, S) {
            return function(a) {
              return S(this)[n](a);
            };
          }(stubName, getSelf);
        }
        case 2:
        {
          return function(n, S) {
            return function(a, b) {
              return S(this)[n](a, b);
            };
          }(stubName, getSelf);
        }
        case 3:
        {
          return function(n, S) {
            return function(a, b, c) {
              return S(this)[n](a, b, c);
            };
          }(stubName, getSelf);
        }
        case 4:
        {
          return function(n, S) {
            return function(a, b, c, d) {
              return S(this)[n](a, b, c, d);
            };
          }(stubName, getSelf);
        }
        case 5:
        {
          return function(n, S) {
            return function(a, b, c, d, e) {
              return S(this)[n](a, b, c, d, e);
            };
          }(stubName, getSelf);
        }
        default:
        {
          return function(f, s) {
            return function() {
              return f.apply(s(this), arguments$);
            };
          }(func, getSelf);
        }
      }
    }
    static get isCsp() {
      return typeof dart_precompiled == "function";
    }
    static forwardCallTo(receiver, func, isIntercepted) {
      if (isIntercepted)
        return Closure.forwardInterceptedCallTo(receiver, func);
      let stubName = dart.as(func.$stubName, core.String);
      let arity = func.length;
      let lookedUpFunction = receiver[stubName];
      let isSuperCall = !dart.notNull(core.identical(func, lookedUpFunction));
      if (dart.notNull(Closure.isCsp) || dart.notNull(isSuperCall) || dart.notNull(arity) >= 27) {
        return Closure.cspForwardCall(arity, isSuperCall, stubName, func);
      }
      if (arity == 0) {
        return new Function('return function(){' + `return this.${BoundClosure.selfFieldName()}.${stubName}();` + `${(() => {
          let x$ = Closure.functionCounter;
          Closure.functionCounter = dart.notNull(x$) + 1;
          return x$;
        })()}` + '}')();
      }
      dart.assert(1 <= dart.notNull(arity) && dart.notNull(arity) < 27);
      let arguments$ = "abcdefghijklmnopqrstuvwxyz".split("").splice(0, arity).join(",");
      return new Function(`return function(${arguments$}){` + `return this.${BoundClosure.selfFieldName()}.${stubName}(${arguments$});` + `${(() => {
        let x$ = Closure.functionCounter;
        Closure.functionCounter = dart.notNull(x$) + 1;
        return x$;
      })()}` + '}')();
    }
    static cspForwardInterceptedCall(arity, isSuperCall, name, func) {
      let getSelf = _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
      let getReceiver = _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.receiverOf);
      if (isSuperCall)
        arity = -1;
      switch (arity) {
        case 0:
        {
          throw new RuntimeError('Intercepted function with no arguments.');
        }
        case 1:
        {
          return function(n, s, r) {
            return function() {
              return s(this)[n](r(this));
            };
          }(name, getSelf, getReceiver);
        }
        case 2:
        {
          return function(n, s, r) {
            return function(a) {
              return s(this)[n](r(this), a);
            };
          }(name, getSelf, getReceiver);
        }
        case 3:
        {
          return function(n, s, r) {
            return function(a, b) {
              return s(this)[n](r(this), a, b);
            };
          }(name, getSelf, getReceiver);
        }
        case 4:
        {
          return function(n, s, r) {
            return function(a, b, c) {
              return s(this)[n](r(this), a, b, c);
            };
          }(name, getSelf, getReceiver);
        }
        case 5:
        {
          return function(n, s, r) {
            return function(a, b, c, d) {
              return s(this)[n](r(this), a, b, c, d);
            };
          }(name, getSelf, getReceiver);
        }
        case 6:
        {
          return function(n, s, r) {
            return function(a, b, c, d, e) {
              return s(this)[n](r(this), a, b, c, d, e);
            };
          }(name, getSelf, getReceiver);
        }
        default:
        {
          return function(f, s, r, a) {
            return function() {
              a = [r(this)];
              Array.prototype.push.apply(a, arguments$);
              return f.apply(s(this), a);
            };
          }(func, getSelf, getReceiver);
        }
      }
    }
    static forwardInterceptedCallTo(receiver, func) {
      let selfField = BoundClosure.selfFieldName();
      let receiverField = BoundClosure.receiverFieldName();
      let stubName = dart.as(func.$stubName, core.String);
      let arity = func.length;
      let isCsp = typeof dart_precompiled == "function";
      let lookedUpFunction = receiver[stubName];
      let isSuperCall = !dart.notNull(core.identical(func, lookedUpFunction));
      if (dart.notNull(isCsp) || dart.notNull(isSuperCall) || dart.notNull(arity) >= 28) {
        return Closure.cspForwardInterceptedCall(arity, isSuperCall, stubName, func);
      }
      if (arity == 1) {
        return new Function('return function(){' + `return this.${selfField}.${stubName}(this.${receiverField});` + `${(() => {
          let x$ = Closure.functionCounter;
          Closure.functionCounter = dart.notNull(x$) + 1;
          return x$;
        })()}` + '}')();
      }
      dart.assert(1 < dart.notNull(arity) && dart.notNull(arity) < 28);
      let arguments$ = "abcdefghijklmnopqrstuvwxyz".split("").splice(0, dart.notNull(arity) - 1).join(",");
      return new Function(`return function(${arguments$}){` + `return this.${selfField}.${stubName}(this.${receiverField}, ${arguments$});` + `${(() => {
        let x$ = Closure.functionCounter;
        Closure.functionCounter = dart.notNull(x$) + 1;
        return x$;
      })()}` + '}')();
    }
    toString() {
      return "Closure";
    }
  }
  Closure[dart.implements] = () => [core.Function];
  Closure.FUNCTION_INDEX = 0;
  Closure.NAME_INDEX = 1;
  Closure.CALL_NAME_INDEX = 2;
  Closure.REQUIRED_PARAMETER_INDEX = 3;
  Closure.OPTIONAL_PARAMETER_INDEX = 4;
  Closure.DEFAULT_ARGUMENTS_INDEX = 5;
  Closure.functionCounter = 0;
  // Function closureFromTearOff: (dynamic, dynamic, dynamic, dynamic, dynamic, dynamic) → dynamic
  function closureFromTearOff(receiver, functions, reflectionInfo, isStatic, jsArguments, name) {
    return Closure.fromTearOff(receiver, _interceptors.JSArray.markFixedList(dart.as(functions, core.List)), _interceptors.JSArray.markFixedList(dart.as(reflectionInfo, core.List)), !!isStatic, jsArguments, name);
  }
  class TearOffClosure extends Closure {}
  let _self = Symbol('_self');
  let _target = Symbol('_target');
  let _name = Symbol('_name');
  class BoundClosure extends TearOffClosure {
    BoundClosure(self$, target$, receiver$, name$) {
      this[_self] = self$;
      this[_target] = target$;
      this[_receiver] = receiver$;
      this[_name] = name$;
      super.TearOffClosure();
    }
    ['=='](other) {
      if (core.identical(this, other))
        return true;
      if (!dart.is(other, BoundClosure))
        return false;
      return this[_self] === dart.dload(other, _self) && this[_target] === dart.dload(other, _target) && this[_receiver] === dart.dload(other, _receiver);
    }
    get hashCode() {
      let receiverHashCode = null;
      if (this[_receiver] == null) {
        receiverHashCode = Primitives.objectHashCode(this[_self]);
      } else if (typeof this[_receiver] != 'object') {
        receiverHashCode = this[_receiver].hashCode;
      } else {
        receiverHashCode = Primitives.objectHashCode(this[_receiver]);
      }
      return dart.notNull(receiverHashCode) ^ dart.notNull(Primitives.objectHashCode(this[_target]));
    }
    static selfOf(closure) {
      return closure[_self];
    }
    static targetOf(closure) {
      return closure[_target];
    }
    static receiverOf(closure) {
      return closure[_receiver];
    }
    static nameOf(closure) {
      return closure[_name];
    }
    static selfFieldName() {
      if (BoundClosure.selfFieldNameCache == null) {
        BoundClosure.selfFieldNameCache = BoundClosure.computeFieldNamed('self');
      }
      return BoundClosure.selfFieldNameCache;
    }
    static receiverFieldName() {
      if (BoundClosure.receiverFieldNameCache == null) {
        BoundClosure.receiverFieldNameCache = BoundClosure.computeFieldNamed('receiver');
      }
      return BoundClosure.receiverFieldNameCache;
    }
    static computeFieldNamed(fieldName) {
      let template = new BoundClosure('self', 'target', 'receiver', 'name');
      let names = _interceptors.JSArray.markFixedList(dart.as(Object.getOwnPropertyNames(template), core.List));
      for (let i = 0; dart.notNull(i) < dart.notNull(names[core.$length]); i = dart.notNull(i) + 1) {
        let name = names[core.$get](i);
        if (template[name] === fieldName) {
          return name;
        }
      }
    }
  }
  BoundClosure.selfFieldNameCache = null;
  BoundClosure.receiverFieldNameCache = null;
  // Function jsHasOwnProperty: (dynamic, String) → bool
  function jsHasOwnProperty(jsObject, property) {
    return jsObject.hasOwnProperty(property);
  }
  // Function jsPropertyAccess: (dynamic, String) → dynamic
  function jsPropertyAccess(jsObject, property) {
    return jsObject[property];
  }
  // Function getFallThroughError: () → dynamic
  function getFallThroughError() {
    return new FallThroughErrorImplementation();
  }
  class Creates extends core.Object {
    Creates(types) {
      this.types = types;
    }
  }
  class Returns extends core.Object {
    Returns(types) {
      this.types = types;
    }
  }
  class JSName extends core.Object {
    JSName(name) {
      this.name = name;
    }
  }
  // Function boolConversionCheck: (dynamic) → dynamic
  function boolConversionCheck(value) {
    if (typeof value == 'boolean')
      return value;
    boolTypeCheck(value);
    dart.assert(value != null);
    return false;
  }
  // Function stringTypeCheck: (dynamic) → dynamic
  function stringTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    throw new TypeErrorImplementation(value, 'String');
  }
  // Function stringTypeCast: (dynamic) → dynamic
  function stringTypeCast(value) {
    if (typeof value == 'string' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'String');
  }
  // Function doubleTypeCheck: (dynamic) → dynamic
  function doubleTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'number')
      return value;
    throw new TypeErrorImplementation(value, 'double');
  }
  // Function doubleTypeCast: (dynamic) → dynamic
  function doubleTypeCast(value) {
    if (typeof value == 'number' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'double');
  }
  // Function numTypeCheck: (dynamic) → dynamic
  function numTypeCheck(value) {
    if (value == null)
      return value;
    if (dart.is(value, core.num))
      return value;
    throw new TypeErrorImplementation(value, 'num');
  }
  // Function numTypeCast: (dynamic) → dynamic
  function numTypeCast(value) {
    if (dart.is(value, core.num) || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'num');
  }
  // Function boolTypeCheck: (dynamic) → dynamic
  function boolTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'boolean')
      return value;
    throw new TypeErrorImplementation(value, 'bool');
  }
  // Function boolTypeCast: (dynamic) → dynamic
  function boolTypeCast(value) {
    if (typeof value == 'boolean' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'bool');
  }
  // Function intTypeCheck: (dynamic) → dynamic
  function intTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'number')
      return value;
    throw new TypeErrorImplementation(value, 'int');
  }
  // Function intTypeCast: (dynamic) → dynamic
  function intTypeCast(value) {
    if (typeof value == 'number' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'int');
  }
  // Function propertyTypeError: (dynamic, dynamic) → void
  function propertyTypeError(value, property) {
    let name = dart.as(dart.dsend(property, 'substring', 3, dart.dload(property, 'length')), core.String);
    throw new TypeErrorImplementation(value, name);
  }
  // Function propertyTypeCastError: (dynamic, dynamic) → void
  function propertyTypeCastError(value, property) {
    let actualType = Primitives.objectTypeName(value);
    let expectedType = dart.as(dart.dsend(property, 'substring', 3, dart.dload(property, 'length')), core.String);
    throw new CastErrorImplementation(actualType, expectedType);
  }
  // Function propertyTypeCheck: (dynamic, dynamic) → dynamic
  function propertyTypeCheck(value, property) {
    if (value == null)
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function propertyTypeCast: (dynamic, dynamic) → dynamic
  function propertyTypeCast(value, property) {
    if (dart.notNull(value == null) || !!value[property])
      return value;
    propertyTypeCastError(value, property);
  }
  // Function interceptedTypeCheck: (dynamic, dynamic) → dynamic
  function interceptedTypeCheck(value, property) {
    if (value == null)
      return value;
    if (dart.notNull(core.identical(typeof value, 'object')) && _interceptors.getInterceptor(value)[property]) {
      return value;
    }
    propertyTypeError(value, property);
  }
  // Function interceptedTypeCast: (dynamic, dynamic) → dynamic
  function interceptedTypeCast(value, property) {
    if (dart.notNull(value == null) || typeof value === "object" && _interceptors.getInterceptor(value)[property]) {
      return value;
    }
    propertyTypeCastError(value, property);
  }
  // Function numberOrStringSuperTypeCheck: (dynamic, dynamic) → dynamic
  function numberOrStringSuperTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function numberOrStringSuperTypeCast: (dynamic, dynamic) → dynamic
  function numberOrStringSuperTypeCast(value, property) {
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    return propertyTypeCast(value, property);
  }
  // Function numberOrStringSuperNativeTypeCheck: (dynamic, dynamic) → dynamic
  function numberOrStringSuperNativeTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function numberOrStringSuperNativeTypeCast: (dynamic, dynamic) → dynamic
  function numberOrStringSuperNativeTypeCast(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeCastError(value, property);
  }
  // Function stringSuperTypeCheck: (dynamic, dynamic) → dynamic
  function stringSuperTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function stringSuperTypeCast: (dynamic, dynamic) → dynamic
  function stringSuperTypeCast(value, property) {
    if (typeof value == 'string')
      return value;
    return propertyTypeCast(value, property);
  }
  // Function stringSuperNativeTypeCheck: (dynamic, dynamic) → dynamic
  function stringSuperNativeTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function stringSuperNativeTypeCast: (dynamic, dynamic) → dynamic
  function stringSuperNativeTypeCast(value, property) {
    if (typeof value == 'string' || dart.notNull(value == null))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeCastError(value, property);
  }
  // Function listTypeCheck: (dynamic) → dynamic
  function listTypeCheck(value) {
    if (value == null)
      return value;
    if (dart.is(value, core.List))
      return value;
    throw new TypeErrorImplementation(value, 'List');
  }
  // Function listTypeCast: (dynamic) → dynamic
  function listTypeCast(value) {
    if (dart.is(value, core.List) || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'List');
  }
  // Function listSuperTypeCheck: (dynamic, dynamic) → dynamic
  function listSuperTypeCheck(value, property) {
    if (value == null)
      return value;
    if (dart.is(value, core.List))
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function listSuperTypeCast: (dynamic, dynamic) → dynamic
  function listSuperTypeCast(value, property) {
    if (dart.is(value, core.List))
      return value;
    return propertyTypeCast(value, property);
  }
  // Function listSuperNativeTypeCheck: (dynamic, dynamic) → dynamic
  function listSuperNativeTypeCheck(value, property) {
    if (value == null)
      return value;
    if (dart.is(value, core.List))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeError(value, property);
  }
  // Function listSuperNativeTypeCast: (dynamic, dynamic) → dynamic
  function listSuperNativeTypeCast(value, property) {
    if (dart.is(value, core.List) || dart.notNull(value == null))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeCastError(value, property);
  }
  // Function voidTypeCheck: (dynamic) → dynamic
  function voidTypeCheck(value) {
    if (value == null)
      return value;
    throw new TypeErrorImplementation(value, 'void');
  }
  // Function checkMalformedType: (dynamic, dynamic) → dynamic
  function checkMalformedType(value, message) {
    if (value == null)
      return value;
    throw new TypeErrorImplementation.fromMessage(dart.as(message, core.String));
  }
  // Function checkDeferredIsLoaded: (String, String) → void
  function checkDeferredIsLoaded(loadId, uri) {
    if (!dart.notNull(exports._loadedLibraries[core.$contains](loadId))) {
      throw new DeferredNotLoadedError(uri);
    }
  }
  dart.defineLazyClass(exports, {
    get JavaScriptIndexingBehavior() {
      class JavaScriptIndexingBehavior extends _interceptors.JSMutableIndexable {}
      return JavaScriptIndexingBehavior;
    }
  });
  class TypeErrorImplementation extends core.Error {
    TypeErrorImplementation(value, type) {
      this.message = `type '${Primitives.objectTypeName(value)}' is not a subtype ` + `of type '${type}'`;
      super.Error();
    }
    fromMessage(message) {
      this.message = message;
      super.Error();
    }
    toString() {
      return this.message;
    }
  }
  TypeErrorImplementation[dart.implements] = () => [core.TypeError];
  dart.defineNamedConstructor(TypeErrorImplementation, 'fromMessage');
  class CastErrorImplementation extends core.Error {
    CastErrorImplementation(actualType, expectedType) {
      this.message = `CastError: Casting value of type ${actualType} to` + ` incompatible type ${expectedType}`;
      super.Error();
    }
    toString() {
      return this.message;
    }
  }
  CastErrorImplementation[dart.implements] = () => [core.CastError];
  class FallThroughErrorImplementation extends core.FallThroughError {
    FallThroughErrorImplementation() {
      super.FallThroughError();
    }
    toString() {
      return "Switch case fall-through.";
    }
  }
  // Function assertHelper: (dynamic) → void
  function assertHelper(condition) {
    if (!(typeof condition == 'boolean')) {
      if (dart.is(condition, core.Function))
        condition = dart.dcall(condition);
      if (!(typeof condition == 'boolean')) {
        throw new TypeErrorImplementation(condition, 'bool');
      }
    }
    if (!dart.equals(true, condition))
      throw new core.AssertionError();
  }
  // Function throwNoSuchMethod: (dynamic, dynamic, dynamic, dynamic) → void
  function throwNoSuchMethod(obj, name, arguments$, expectedArgumentNames) {
    let memberName = new _internal.Symbol.unvalidated(dart.as(name, core.String));
    throw new core.NoSuchMethodError(obj, memberName, dart.as(arguments$, core.List), new (core.Map$(core.Symbol, dart.dynamic))(), dart.as(expectedArgumentNames, core.List));
  }
  // Function throwCyclicInit: (String) → void
  function throwCyclicInit(staticName) {
    throw new core.CyclicInitializationError(`Cyclic initialization for static ${staticName}`);
  }
  class RuntimeError extends core.Error {
    RuntimeError(message) {
      this.message = message;
      super.Error();
    }
    toString() {
      return `RuntimeError: ${this.message}`;
    }
  }
  class DeferredNotLoadedError extends core.Error {
    DeferredNotLoadedError(libraryName) {
      this.libraryName = libraryName;
      super.Error();
    }
    toString() {
      return `Deferred library ${this.libraryName} was not loaded.`;
    }
  }
  DeferredNotLoadedError[dart.implements] = () => [core.NoSuchMethodError];
  class RuntimeType extends core.Object {
    RuntimeType() {
    }
  }
  let _isTest = Symbol('_isTest');
  let _extractFunctionTypeObjectFrom = Symbol('_extractFunctionTypeObjectFrom');
  let _asCheck = Symbol('_asCheck');
  let _check = Symbol('_check');
  let _assertCheck = Symbol('_assertCheck');
  class RuntimeFunctionType extends RuntimeType {
    RuntimeFunctionType(returnType, parameterTypes, optionalParameterTypes, namedParameters) {
      this.returnType = returnType;
      this.parameterTypes = parameterTypes;
      this.optionalParameterTypes = optionalParameterTypes;
      this.namedParameters = namedParameters;
      super.RuntimeType();
    }
    get isVoid() {
      return dart.is(this.returnType, VoidRuntimeType);
    }
    [_isTest](expression) {
      let functionTypeObject = this[_extractFunctionTypeObjectFrom](expression);
      return functionTypeObject == null ? false : isFunctionSubtype(functionTypeObject, this.toRti());
    }
    [_asCheck](expression) {
      return this[_check](expression, true);
    }
    [_assertCheck](expression) {
      if (RuntimeFunctionType.inAssert)
        return null;
      RuntimeFunctionType.inAssert = true;
      try {
        return this[_check](expression, false);
      } finally {
        RuntimeFunctionType.inAssert = false;
      }
    }
    [_check](expression, isCast) {
      if (expression == null)
        return null;
      if (this[_isTest](expression))
        return expression;
      let self = new FunctionTypeInfoDecoderRing(this.toRti()).toString();
      if (isCast) {
        let functionTypeObject = this[_extractFunctionTypeObjectFrom](expression);
        let pretty = null;
        if (functionTypeObject != null) {
          pretty = new FunctionTypeInfoDecoderRing(functionTypeObject).toString();
        } else {
          pretty = Primitives.objectTypeName(expression);
        }
        throw new CastErrorImplementation(pretty, self);
      } else {
        throw new TypeErrorImplementation(expression, self);
      }
    }
    [_extractFunctionTypeObjectFrom](o) {
      let interceptor = _interceptors.getInterceptor(o);
      return _foreign_helper.JS_SIGNATURE_NAME() in interceptor ? interceptor[_foreign_helper.JS_SIGNATURE_NAME()]() : null;
    }
    toRti() {
      let result = {[_foreign_helper.JS_FUNCTION_TYPE_TAG()]: "dynafunc"};
      if (this.isVoid) {
        result[_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()] = true;
      } else {
        if (!dart.is(this.returnType, DynamicRuntimeType)) {
          result[_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()] = this.returnType.toRti();
        }
      }
      if (dart.notNull(this.parameterTypes != null) && !dart.notNull(this.parameterTypes[core.$isEmpty])) {
        result[_foreign_helper.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()] = RuntimeFunctionType.listToRti(this.parameterTypes);
      }
      if (dart.notNull(this.optionalParameterTypes != null) && !dart.notNull(this.optionalParameterTypes[core.$isEmpty])) {
        result[_foreign_helper.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()] = RuntimeFunctionType.listToRti(this.optionalParameterTypes);
      }
      if (this.namedParameters != null) {
        let namedRti = Object.create(null);
        let keys = _js_names.extractKeys(this.namedParameters);
        for (let i = 0; dart.notNull(i) < dart.notNull(keys[core.$length]); i = dart.notNull(i) + 1) {
          let name = keys[core.$get](i);
          let rti = dart.dsend(this.namedParameters[name], 'toRti');
          namedRti[name] = rti;
        }
        result[_foreign_helper.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()] = namedRti;
      }
      return result;
    }
    static listToRti(list) {
      list = list;
      let result = [];
      for (let i = 0; core.int['<'](i, dart.dload(list, 'length')); i = dart.notNull(i) + 1) {
        result.push(dart.dsend(dart.dindex(list, i), 'toRti'));
      }
      return result;
    }
    toString() {
      let result = '(';
      let needsComma = false;
      if (this.parameterTypes != null) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this.parameterTypes[core.$length]); i = dart.notNull(i) + 1) {
          let type = this.parameterTypes[core.$get](i);
          if (needsComma) {
            result = dart.notNull(result) + ', ';
          }
          result = dart.notNull(result) + `${type}`;
          needsComma = true;
        }
      }
      if (dart.notNull(this.optionalParameterTypes != null) && !dart.notNull(this.optionalParameterTypes[core.$isEmpty])) {
        if (needsComma) {
          result = dart.notNull(result) + ', ';
        }
        needsComma = false;
        result = dart.notNull(result) + '[';
        for (let i = 0; dart.notNull(i) < dart.notNull(this.optionalParameterTypes[core.$length]); i = dart.notNull(i) + 1) {
          let type = this.optionalParameterTypes[core.$get](i);
          if (needsComma) {
            result = dart.notNull(result) + ', ';
          }
          result = dart.notNull(result) + `${type}`;
          needsComma = true;
        }
        result = dart.notNull(result) + ']';
      } else if (this.namedParameters != null) {
        if (needsComma) {
          result = dart.notNull(result) + ', ';
        }
        needsComma = false;
        result = dart.notNull(result) + '{';
        let keys = _js_names.extractKeys(this.namedParameters);
        for (let i = 0; dart.notNull(i) < dart.notNull(keys[core.$length]); i = dart.notNull(i) + 1) {
          let name = keys[core.$get](i);
          if (needsComma) {
            result = dart.notNull(result) + ', ';
          }
          let rti = dart.dsend(this.namedParameters[name], 'toRti');
          result = dart.notNull(result) + `${rti} ${name}`;
          needsComma = true;
        }
        result = dart.notNull(result) + '}';
      }
      result = dart.notNull(result) + `) -> ${this.returnType}`;
      return result;
    }
  }
  RuntimeFunctionType.inAssert = false;
  // Function buildFunctionType: (dynamic, dynamic, dynamic) → RuntimeFunctionType
  function buildFunctionType(returnType, parameterTypes, optionalParameterTypes) {
    return new RuntimeFunctionType(dart.as(returnType, RuntimeType), dart.as(parameterTypes, core.List$(RuntimeType)), dart.as(optionalParameterTypes, core.List$(RuntimeType)), null);
  }
  // Function buildNamedFunctionType: (dynamic, dynamic, dynamic) → RuntimeFunctionType
  function buildNamedFunctionType(returnType, parameterTypes, namedParameters) {
    return new RuntimeFunctionType(dart.as(returnType, RuntimeType), dart.as(parameterTypes, core.List$(RuntimeType)), null, namedParameters);
  }
  // Function buildInterfaceType: (dynamic, dynamic) → RuntimeType
  function buildInterfaceType(rti, typeArguments) {
    let name = dart.as(rti.name, core.String);
    if (core.bool['||'](typeArguments == null, dart.dload(typeArguments, 'isEmpty'))) {
      return new RuntimeTypePlain(name);
    }
    return new RuntimeTypeGeneric(name, dart.as(typeArguments, core.List$(RuntimeType)), null);
  }
  class DynamicRuntimeType extends RuntimeType {
    DynamicRuntimeType() {
      super.RuntimeType();
    }
    toString() {
      return 'dynamic';
    }
    toRti() {
      return null;
    }
  }
  // Function getDynamicRuntimeType: () → RuntimeType
  function getDynamicRuntimeType() {
    return new DynamicRuntimeType();
  }
  class VoidRuntimeType extends RuntimeType {
    VoidRuntimeType() {
      super.RuntimeType();
    }
    toString() {
      return 'void';
    }
    toRti() {
      return dart.throw_('internal error');
    }
  }
  // Function getVoidRuntimeType: () → RuntimeType
  function getVoidRuntimeType() {
    return new VoidRuntimeType();
  }
  // Function functionTypeTestMetaHelper: () → dynamic
  function functionTypeTestMetaHelper() {
    let dyn = x;
    let dyn2 = x;
    let fixedListOrNull = dart.as(x, core.List);
    let fixedListOrNull2 = dart.as(x, core.List);
    let fixedList = dart.as(x, core.List);
    let jsObject = x;
    buildFunctionType(dyn, fixedListOrNull, fixedListOrNull2);
    buildNamedFunctionType(dyn, fixedList, jsObject);
    buildInterfaceType(dyn, fixedListOrNull);
    getDynamicRuntimeType();
    getVoidRuntimeType();
    convertRtiToRuntimeType(dyn);
    dart.dsend(dyn, _isTest, dyn2);
    dart.dsend(dyn, _asCheck, dyn2);
    dart.dsend(dyn, _assertCheck, dyn2);
  }
  // Function convertRtiToRuntimeType: (dynamic) → RuntimeType
  function convertRtiToRuntimeType(rti) {
    if (rti == null) {
      return getDynamicRuntimeType();
    } else if (typeof rti == "function") {
      return new RuntimeTypePlain(rti.name);
    } else if (rti.constructor == Array) {
      let list = dart.as(rti, core.List);
      let name = list[core.$get](0).name;
      let arguments$ = new core.List.from([]);
      for (let i = 1; dart.notNull(i) < dart.notNull(list[core.$length]); i = dart.notNull(i) + 1) {
        arguments$[core.$add](convertRtiToRuntimeType(list[core.$get](i)));
      }
      return new RuntimeTypeGeneric(name, dart.as(arguments$, core.List$(RuntimeType)), rti);
    } else if ("func" in rti) {
      return new FunctionTypeInfoDecoderRing(rti).toRuntimeType();
    } else {
      throw new RuntimeError("Cannot convert " + `'${JSON.stringify(rti)}' to RuntimeType.`);
    }
  }
  class RuntimeTypePlain extends RuntimeType {
    RuntimeTypePlain(name) {
      this.name = name;
      super.RuntimeType();
    }
    toRti() {
      let allClasses = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.ALL_CLASSES);
      let rti = allClasses[this.name];
      if (rti == null)
        throw `no type for '${this.name}'`;
      return rti;
    }
    toString() {
      return this.name;
    }
  }
  class RuntimeTypeGeneric extends RuntimeType {
    RuntimeTypeGeneric(name, arguments$, rti) {
      this.name = name;
      this.arguments = arguments$;
      this.rti = rti;
      super.RuntimeType();
    }
    toRti() {
      if (this.rti != null)
        return this.rti;
      let allClasses = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.ALL_CLASSES);
      let result = [allClasses[this.name]];
      if (dart.dindex(result, 0) == null) {
        throw `no type for '${this.name}<...>'`;
      }
      for (let argument of this.arguments) {
        result.push(argument.toRti());
      }
      return this.rti = result;
    }
    toString() {
      return `${this.name}<${this.arguments[core.$join](", ")}>`;
    }
  }
  let _typeData = Symbol('_typeData');
  let _cachedToString = Symbol('_cachedToString');
  let _hasReturnType = Symbol('_hasReturnType');
  let _returnType = Symbol('_returnType');
  let _isVoid = Symbol('_isVoid');
  let _hasArguments = Symbol('_hasArguments');
  let _hasOptionalArguments = Symbol('_hasOptionalArguments');
  let _optionalArguments = Symbol('_optionalArguments');
  let _hasNamedArguments = Symbol('_hasNamedArguments');
  let _namedArguments = Symbol('_namedArguments');
  let _convert = Symbol('_convert');
  class FunctionTypeInfoDecoderRing extends core.Object {
    FunctionTypeInfoDecoderRing(typeData) {
      this[_typeData] = typeData;
      this[_cachedToString] = null;
    }
    get [_hasReturnType]() {
      return "ret" in this[_typeData];
    }
    get [_returnType]() {
      return this[_typeData].ret;
    }
    get [_isVoid]() {
      return !!this[_typeData].void;
    }
    get [_hasArguments]() {
      return "args" in this[_typeData];
    }
    get [_arguments]() {
      return dart.as(this[_typeData].args, core.List);
    }
    get [_hasOptionalArguments]() {
      return "opt" in this[_typeData];
    }
    get [_optionalArguments]() {
      return dart.as(this[_typeData].opt, core.List);
    }
    get [_hasNamedArguments]() {
      return "named" in this[_typeData];
    }
    get [_namedArguments]() {
      return this[_typeData].named;
    }
    toRuntimeType() {
      return new DynamicRuntimeType();
    }
    [_convert](type) {
      let result = runtimeTypeToString(type);
      if (result != null)
        return result;
      if ("func" in type) {
        return new FunctionTypeInfoDecoderRing(type).toString();
      } else {
        throw 'bad type';
      }
    }
    toString() {
      if (this[_cachedToString] != null)
        return this[_cachedToString];
      let s = "(";
      let sep = '';
      if (this[_hasArguments]) {
        for (let argument of this[_arguments]) {
          s = dart.notNull(s) + dart.notNull(sep);
          s = dart.notNull(s) + dart.notNull(this[_convert](argument));
          sep = ', ';
        }
      }
      if (this[_hasOptionalArguments]) {
        s = dart.notNull(s) + `${sep}[`;
        sep = '';
        for (let argument of this[_optionalArguments]) {
          s = dart.notNull(s) + dart.notNull(sep);
          s = dart.notNull(s) + dart.notNull(this[_convert](argument));
          sep = ', ';
        }
        s = dart.notNull(s) + ']';
      }
      if (this[_hasNamedArguments]) {
        s = dart.notNull(s) + `${sep}{`;
        sep = '';
        for (let name of _js_names.extractKeys(this[_namedArguments])) {
          s = dart.notNull(s) + dart.notNull(sep);
          s = dart.notNull(s) + `${name}: `;
          s = dart.notNull(s) + dart.notNull(this[_convert](this[_namedArguments][name]));
          sep = ', ';
        }
        s = dart.notNull(s) + '}';
      }
      s = dart.notNull(s) + ') -> ';
      if (this[_isVoid]) {
        s = dart.notNull(s) + 'void';
      } else if (this[_hasReturnType]) {
        s = dart.notNull(s) + dart.notNull(this[_convert](this[_returnType]));
      } else {
        s = dart.notNull(s) + 'dynamic';
      }
      return this[_cachedToString] = `${s}`;
    }
  }
  class UnimplementedNoSuchMethodError extends core.Error {
    UnimplementedNoSuchMethodError(message$) {
      this[_message] = message$;
      super.Error();
    }
    toString() {
      return `Unsupported operation: ${this[_message]}`;
    }
  }
  UnimplementedNoSuchMethodError[dart.implements] = () => [core.NoSuchMethodError];
  // Function random64: () → int
  function random64() {
    let int32a = Math.random() * 0x100000000 >>> 0;
    let int32b = Math.random() * 0x100000000 >>> 0;
    return dart.notNull(int32a) + dart.notNull(int32b) * 4294967296;
  }
  // Function jsonEncodeNative: (String) → String
  function jsonEncodeNative(string) {
    return JSON.stringify(string);
  }
  // Function getIsolateAffinityTag: (String) → String
  function getIsolateAffinityTag(name) {
    let isolateTagGetter = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.GET_ISOLATE_TAG);
    return isolateTagGetter(name);
  }
  let LoadLibraryFunctionType = dart.typedef('LoadLibraryFunctionType', () => dart.functionType(async.Future$(core.Null), []));
  // Function _loadLibraryWrapper: (String) → () → Future<Null>
  function _loadLibraryWrapper(loadId) {
    return () => loadDeferredLibrary(loadId);
  }
  dart.defineLazyProperties(exports, {
    get _loadingLibraries() {
      return dart.map();
    },
    get _loadedLibraries() {
      return new (core.Set$(core.String))();
    }
  });
  let DeferredLoadCallback = dart.typedef('DeferredLoadCallback', () => dart.functionType(dart.void, []));
  exports.deferredLoadHook = null;
  // Function loadDeferredLibrary: (String) → Future<Null>
  function loadDeferredLibrary(loadId) {
    let urisMap = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.DEFERRED_LIBRARY_URIS);
    let uris = dart.as(urisMap[loadId], core.List$(core.String));
    let hashesMap = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.DEFERRED_LIBRARY_HASHES);
    let hashes = dart.as(hashesMap[loadId], core.List$(core.String));
    if (uris == null)
      return dart.as(new async.Future.value(null), async.Future$(core.Null));
    let indices = dart.as(new core.List.generate(uris[core.$length], dart.as(i => i, dart.functionType(dart.dynamic, [core.int]))), core.List$(core.int));
    let isHunkLoaded = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.IS_HUNK_LOADED);
    let isHunkInitialized = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.IS_HUNK_INITIALIZED);
    let indicesToLoad = indices[core.$where](i => !isHunkLoaded(hashes[core.$get](i)))[core.$toList]();
    return dart.as(async.Future.wait(dart.as(indicesToLoad[core.$map](i => _loadHunk(uris[core.$get](i))), core.Iterable$(async.Future))).then(dart.as(_ => {
      let indicesToInitialize = indices[core.$where](i => !isHunkInitialized(hashes[core.$get](i)))[core.$toList]();
      for (let i of indicesToInitialize) {
        let initializer = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.INITIALIZE_LOADED_HUNK);
        initializer(hashes[core.$get](i));
      }
      let updated = exports._loadedLibraries.add(loadId);
      if (dart.notNull(updated) && dart.notNull(exports.deferredLoadHook != null)) {
        exports.deferredLoadHook();
      }
    }, dart.functionType(dart.dynamic, [core.List]))), async.Future$(core.Null));
  }
  // Function _loadHunk: (String) → Future<Null>
  function _loadHunk(hunkName) {
    let future = exports._loadingLibraries.get(hunkName);
    if (future != null) {
      return dart.as(future.then(dart.as(_ => null, dart.functionType(dart.dynamic, [core.Null]))), async.Future$(core.Null));
    }
    let uri = _isolate_helper.IsolateNatives.thisScript;
    let index = uri.lastIndexOf('/');
    uri = `${uri.substring(0, dart.notNull(index) + 1)}${hunkName}`;
    if (dart.notNull(Primitives.isJsshell) || dart.notNull(Primitives.isD8)) {
      return exports._loadingLibraries.set(hunkName, new (async.Future$(core.Null))(() => {
        try {
          new Function(`load("${uri}")`)();
        } catch (error) {
          let stackTrace = dart.stackTrace(error);
          throw new async.DeferredLoadException(`Loading ${uri} failed.`);
        }

        return null;
      }));
    } else if (_isolate_helper.isWorker()) {
      return exports._loadingLibraries.set(hunkName, new (async.Future$(core.Null))(() => {
        let completer = new (async.Completer$(core.Null))();
        _isolate_helper.enterJsAsync();
        let leavingFuture = dart.as(completer.future.whenComplete(() => {
          _isolate_helper.leaveJsAsync();
        }), async.Future$(core.Null));
        let index = uri.lastIndexOf('/');
        uri = `${uri.substring(0, dart.notNull(index) + 1)}${hunkName}`;
        let xhr = new XMLHttpRequest();
        xhr.open("GET", uri);
        xhr.addEventListener("load", convertDartClosureToJS(event => {
          if (xhr.status != 200) {
            completer.completeError(new async.DeferredLoadException(`Loading ${uri} failed.`));
            return;
          }
          let code = xhr.responseText;
          try {
            new Function(code)();
          } catch (error) {
            let stackTrace = dart.stackTrace(error);
            completer.completeError(new async.DeferredLoadException(`Evaluating ${uri} failed.`));
            return;
          }

          completer.complete(null);
        }, 1), false);
        let fail = convertDartClosureToJS(event => {
          new async.DeferredLoadException(`Loading ${uri} failed.`);
        }, 1);
        xhr.addEventListener("error", fail, false);
        xhr.addEventListener("abort", fail, false);
        xhr.send();
        return leavingFuture;
      }));
    }
    return exports._loadingLibraries.set(hunkName, new (async.Future$(core.Null))(() => {
      let completer = new (async.Completer$(core.Null))();
      let script = document.createElement("script");
      script.type = "text/javascript";
      script.src = uri;
      script.addEventListener("load", convertDartClosureToJS(event => {
        completer.complete(null);
      }, 1), false);
      script.addEventListener("error", convertDartClosureToJS(event => {
        completer.completeError(new async.DeferredLoadException(`Loading ${uri} failed.`));
      }, 1), false);
      document.body.appendChild(script);
      return completer.future;
    }));
  }
  class MainError extends core.Error {
    MainError(message$) {
      this[_message] = message$;
      super.Error();
    }
    toString() {
      return `NoSuchMethodError: ${this[_message]}`;
    }
  }
  MainError[dart.implements] = () => [core.NoSuchMethodError];
  // Function missingMain: () → void
  function missingMain() {
    throw new MainError("No top-level function named 'main'.");
  }
  // Function badMain: () → void
  function badMain() {
    throw new MainError("'main' is not a function.");
  }
  // Function mainHasTooManyParameters: () → void
  function mainHasTooManyParameters() {
    throw new MainError("'main' expects too many parameters.");
  }
  // Exports:
  exports.NoSideEffects = NoSideEffects;
  exports.NoThrows = NoThrows;
  exports.NoInline = NoInline;
  exports.IrRepresentation = IrRepresentation;
  exports.Native = Native;
  exports.ConstantMap$ = ConstantMap$;
  exports.ConstantMap = ConstantMap;
  exports.ConstantStringMap$ = ConstantStringMap$;
  exports.ConstantStringMap = ConstantStringMap;
  exports.ConstantProtoMap$ = ConstantProtoMap$;
  exports.ConstantProtoMap = ConstantProtoMap;
  exports.GeneralConstantMap$ = GeneralConstantMap$;
  exports.GeneralConstantMap = GeneralConstantMap;
  exports.contains = contains;
  exports.arrayLength = arrayLength;
  exports.arrayGet = arrayGet;
  exports.arraySet = arraySet;
  exports.propertyGet = propertyGet;
  exports.callHasOwnProperty = callHasOwnProperty;
  exports.propertySet = propertySet;
  exports.getPropertyFromPrototype = getPropertyFromPrototype;
  exports.toStringForNativeObject = toStringForNativeObject;
  exports.hashCodeForNativeObject = hashCodeForNativeObject;
  exports.defineProperty = defineProperty;
  exports.isDartObject = isDartObject;
  exports.findDispatchTagForInterceptorClass = findDispatchTagForInterceptorClass;
  exports.lookupInterceptor = lookupInterceptor;
  exports.UNCACHED_MARK = UNCACHED_MARK;
  exports.INSTANCE_CACHED_MARK = INSTANCE_CACHED_MARK;
  exports.LEAF_MARK = LEAF_MARK;
  exports.INTERIOR_MARK = INTERIOR_MARK;
  exports.DISCRIMINATED_MARK = DISCRIMINATED_MARK;
  exports.lookupAndCacheInterceptor = lookupAndCacheInterceptor;
  exports.patchInstance = patchInstance;
  exports.patchProto = patchProto;
  exports.patchInteriorProto = patchInteriorProto;
  exports.makeLeafDispatchRecord = makeLeafDispatchRecord;
  exports.makeDefaultDispatchRecord = makeDefaultDispatchRecord;
  exports.setNativeSubclassDispatchRecord = setNativeSubclassDispatchRecord;
  exports.constructorNameFallback = constructorNameFallback;
  exports.initNativeDispatch = initNativeDispatch;
  exports.initNativeDispatchContinue = initNativeDispatchContinue;
  exports.initHooks = initHooks;
  exports.applyHooksTransformer = applyHooksTransformer;
  exports.regExpGetNative = regExpGetNative;
  exports.regExpGetGlobalNative = regExpGetGlobalNative;
  exports.regExpCaptureCount = regExpCaptureCount;
  exports.JSSyntaxRegExp = JSSyntaxRegExp;
  exports.firstMatchAfter = firstMatchAfter;
  exports.StringMatch = StringMatch;
  exports.allMatchesInStringUnchecked = allMatchesInStringUnchecked;
  exports.stringContainsUnchecked = stringContainsUnchecked;
  exports.stringReplaceJS = stringReplaceJS;
  exports.stringReplaceFirstRE = stringReplaceFirstRE;
  exports.ESCAPE_REGEXP = ESCAPE_REGEXP;
  exports.stringReplaceAllUnchecked = stringReplaceAllUnchecked;
  exports.stringReplaceAllFuncUnchecked = stringReplaceAllFuncUnchecked;
  exports.stringReplaceAllEmptyFuncUnchecked = stringReplaceAllEmptyFuncUnchecked;
  exports.stringReplaceAllStringFuncUnchecked = stringReplaceAllStringFuncUnchecked;
  exports.stringReplaceFirstUnchecked = stringReplaceFirstUnchecked;
  exports.stringJoinUnchecked = stringJoinUnchecked;
  exports.createRuntimeType = createRuntimeType;
  exports.TypeImpl = TypeImpl;
  exports.TypeVariable = TypeVariable;
  exports.getMangledTypeName = getMangledTypeName;
  exports.setRuntimeTypeInfo = setRuntimeTypeInfo;
  exports.getRuntimeTypeInfo = getRuntimeTypeInfo;
  exports.getRuntimeTypeArguments = getRuntimeTypeArguments;
  exports.getRuntimeTypeArgument = getRuntimeTypeArgument;
  exports.getTypeArgumentByIndex = getTypeArgumentByIndex;
  exports.copyTypeArguments = copyTypeArguments;
  exports.getClassName = getClassName;
  exports.getRuntimeTypeAsString = getRuntimeTypeAsString;
  exports.getConstructorName = getConstructorName;
  exports.runtimeTypeToString = runtimeTypeToString;
  exports.joinArguments = joinArguments;
  exports.getRuntimeTypeString = getRuntimeTypeString;
  exports.getRuntimeType = getRuntimeType;
  exports.substitute = substitute;
  exports.checkSubtype = checkSubtype;
  exports.computeTypeName = computeTypeName;
  exports.subtypeCast = subtypeCast;
  exports.assertSubtype = assertSubtype;
  exports.assertIsSubtype = assertIsSubtype;
  exports.throwTypeError = throwTypeError;
  exports.checkArguments = checkArguments;
  exports.areSubtypes = areSubtypes;
  exports.computeSignature = computeSignature;
  exports.isSupertypeOfNull = isSupertypeOfNull;
  exports.checkSubtypeOfRuntimeType = checkSubtypeOfRuntimeType;
  exports.subtypeOfRuntimeTypeCast = subtypeOfRuntimeTypeCast;
  exports.assertSubtypeOfRuntimeType = assertSubtypeOfRuntimeType;
  exports.getArguments = getArguments;
  exports.isSubtype = isSubtype;
  exports.isAssignable = isAssignable;
  exports.areAssignable = areAssignable;
  exports.areAssignableMaps = areAssignableMaps;
  exports.isFunctionSubtype = isFunctionSubtype;
  exports.invoke = invoke;
  exports.invokeOn = invokeOn;
  exports.call = call;
  exports.getField = getField;
  exports.getIndex = getIndex;
  exports.getLength = getLength;
  exports.isJsArray = isJsArray;
  exports.hasField = hasField;
  exports.hasNoField = hasNoField;
  exports.isJsFunction = isJsFunction;
  exports.isJsObject = isJsObject;
  exports.isIdentical = isIdentical;
  exports.isNotIdentical = isNotIdentical;
  exports.patch = patch;
  exports.InternalMap = InternalMap;
  exports.requiresPreamble = requiresPreamble;
  exports.isJsIndexable = isJsIndexable;
  exports.S = S;
  exports.createInvocationMirror = createInvocationMirror;
  exports.createUnmangledInvocationMirror = createUnmangledInvocationMirror;
  exports.throwInvalidReflectionError = throwInvalidReflectionError;
  exports.traceHelper = traceHelper;
  exports.JSInvocationMirror = JSInvocationMirror;
  exports.CachedInvocation = CachedInvocation;
  exports.CachedCatchAllInvocation = CachedCatchAllInvocation;
  exports.CachedNoSuchMethodInvocation = CachedNoSuchMethodInvocation;
  exports.ReflectionInfo = ReflectionInfo;
  exports.getMetadata = getMetadata;
  exports.Primitives = Primitives;
  exports.JsCache = JsCache;
  exports.iae = iae;
  exports.ioore = ioore;
  exports.stringLastIndexOfUnchecked = stringLastIndexOfUnchecked;
  exports.checkNull = checkNull;
  exports.checkNum = checkNum;
  exports.checkInt = checkInt;
  exports.checkBool = checkBool;
  exports.checkString = checkString;
  exports.wrapException = wrapException;
  exports.toStringWrapper = toStringWrapper;
  exports.throwExpression = throwExpression;
  exports.makeLiteralListConst = makeLiteralListConst;
  exports.throwRuntimeError = throwRuntimeError;
  exports.throwAbstractClassInstantiationError = throwAbstractClassInstantiationError;
  exports.TypeErrorDecoder = TypeErrorDecoder;
  exports.NullError = NullError;
  exports.JsNoSuchMethodError = JsNoSuchMethodError;
  exports.UnknownJsTypeError = UnknownJsTypeError;
  exports.unwrapException = unwrapException;
  exports.getTraceFromException = getTraceFromException;
  exports.objectHashCode = objectHashCode;
  exports.fillLiteralMap = fillLiteralMap;
  exports.invokeClosure = invokeClosure;
  exports.convertDartClosureToJS = convertDartClosureToJS;
  exports.Closure = Closure;
  exports.closureFromTearOff = closureFromTearOff;
  exports.TearOffClosure = TearOffClosure;
  exports.BoundClosure = BoundClosure;
  exports.jsHasOwnProperty = jsHasOwnProperty;
  exports.jsPropertyAccess = jsPropertyAccess;
  exports.getFallThroughError = getFallThroughError;
  exports.Creates = Creates;
  exports.Returns = Returns;
  exports.JSName = JSName;
  exports.boolConversionCheck = boolConversionCheck;
  exports.stringTypeCheck = stringTypeCheck;
  exports.stringTypeCast = stringTypeCast;
  exports.doubleTypeCheck = doubleTypeCheck;
  exports.doubleTypeCast = doubleTypeCast;
  exports.numTypeCheck = numTypeCheck;
  exports.numTypeCast = numTypeCast;
  exports.boolTypeCheck = boolTypeCheck;
  exports.boolTypeCast = boolTypeCast;
  exports.intTypeCheck = intTypeCheck;
  exports.intTypeCast = intTypeCast;
  exports.propertyTypeError = propertyTypeError;
  exports.propertyTypeCastError = propertyTypeCastError;
  exports.propertyTypeCheck = propertyTypeCheck;
  exports.propertyTypeCast = propertyTypeCast;
  exports.interceptedTypeCheck = interceptedTypeCheck;
  exports.interceptedTypeCast = interceptedTypeCast;
  exports.numberOrStringSuperTypeCheck = numberOrStringSuperTypeCheck;
  exports.numberOrStringSuperTypeCast = numberOrStringSuperTypeCast;
  exports.numberOrStringSuperNativeTypeCheck = numberOrStringSuperNativeTypeCheck;
  exports.numberOrStringSuperNativeTypeCast = numberOrStringSuperNativeTypeCast;
  exports.stringSuperTypeCheck = stringSuperTypeCheck;
  exports.stringSuperTypeCast = stringSuperTypeCast;
  exports.stringSuperNativeTypeCheck = stringSuperNativeTypeCheck;
  exports.stringSuperNativeTypeCast = stringSuperNativeTypeCast;
  exports.listTypeCheck = listTypeCheck;
  exports.listTypeCast = listTypeCast;
  exports.listSuperTypeCheck = listSuperTypeCheck;
  exports.listSuperTypeCast = listSuperTypeCast;
  exports.listSuperNativeTypeCheck = listSuperNativeTypeCheck;
  exports.listSuperNativeTypeCast = listSuperNativeTypeCast;
  exports.voidTypeCheck = voidTypeCheck;
  exports.checkMalformedType = checkMalformedType;
  exports.checkDeferredIsLoaded = checkDeferredIsLoaded;
  exports.TypeErrorImplementation = TypeErrorImplementation;
  exports.CastErrorImplementation = CastErrorImplementation;
  exports.FallThroughErrorImplementation = FallThroughErrorImplementation;
  exports.assertHelper = assertHelper;
  exports.throwNoSuchMethod = throwNoSuchMethod;
  exports.throwCyclicInit = throwCyclicInit;
  exports.RuntimeError = RuntimeError;
  exports.DeferredNotLoadedError = DeferredNotLoadedError;
  exports.RuntimeType = RuntimeType;
  exports.RuntimeFunctionType = RuntimeFunctionType;
  exports.buildFunctionType = buildFunctionType;
  exports.buildNamedFunctionType = buildNamedFunctionType;
  exports.buildInterfaceType = buildInterfaceType;
  exports.DynamicRuntimeType = DynamicRuntimeType;
  exports.getDynamicRuntimeType = getDynamicRuntimeType;
  exports.VoidRuntimeType = VoidRuntimeType;
  exports.getVoidRuntimeType = getVoidRuntimeType;
  exports.functionTypeTestMetaHelper = functionTypeTestMetaHelper;
  exports.convertRtiToRuntimeType = convertRtiToRuntimeType;
  exports.RuntimeTypePlain = RuntimeTypePlain;
  exports.RuntimeTypeGeneric = RuntimeTypeGeneric;
  exports.FunctionTypeInfoDecoderRing = FunctionTypeInfoDecoderRing;
  exports.UnimplementedNoSuchMethodError = UnimplementedNoSuchMethodError;
  exports.random64 = random64;
  exports.jsonEncodeNative = jsonEncodeNative;
  exports.getIsolateAffinityTag = getIsolateAffinityTag;
  exports.LoadLibraryFunctionType = LoadLibraryFunctionType;
  exports.DeferredLoadCallback = DeferredLoadCallback;
  exports.loadDeferredLibrary = loadDeferredLibrary;
  exports.MainError = MainError;
  exports.missingMain = missingMain;
  exports.badMain = badMain;
  exports.mainHasTooManyParameters = mainHasTooManyParameters;
})(_js_helper || (_js_helper = {}));
