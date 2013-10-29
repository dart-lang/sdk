// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;


// TODO(ngeoffray): stop using this method once our optimizers can
// change str1.contains(str2) into str1.indexOf(str2) != -1.
bool contains(String userAgent, String name) {
  return JS('int', '#.indexOf(#)', userAgent, name) != -1;
}

int arrayLength(List array) {
  return JS('int', '#.length', array);
}

arrayGet(List array, int index) {
  return JS('var', '#[#]', array, index);
}

void arraySet(List array, int index, var value) {
  JS('var', '#[#] = #', array, index, value);
}

propertyGet(var object, String property) {
  return JS('var', '#[#]', object, property);
}

bool callHasOwnProperty(var function, var object, String property) {
  return JS('bool', '#.call(#, #)', function, object, property);
}

void propertySet(var object, String property, var value) {
  JS('var', '#[#] = #', object, property, value);
}

getPropertyFromPrototype(var object, String name) {
  return JS('var', 'Object.getPrototypeOf(#)[#]', object, name);
}

newJsObject() {
  return JS('var', '{}');
}

/**
 * Returns a String tag identifying the type of the native object, or `null`.
 * The tag is not the name of the type.
 */
Function getTagFunction;

/**
 * If a lookup via [getTagFunction] an object [object] that has [tag] fails,
 * this function is called to provide an alternate tag.  This allows us to fail
 * gracefully if we can make a good guess, for example, when browsers add novel
 * kinds of HTMLElement that we have never heard of.
 */
Function alternateTagFunction;


String toStringForNativeObject(var obj) {
  // TODO(sra): Is this code dead?
  // getTagFunction might be uninitialized, but in usual usage, toString has been
  String name = getTagFunction == null
      ? '<Unknown>'
      : JS('String', '#', getTagFunction(obj));
  return 'Instance of $name';
}

int hashCodeForNativeObject(object) => Primitives.objectHashCode(object);

/**
 * Sets a JavaScript property on an object.
 */
void defineProperty(var obj, String property, var value) {
  JS('void',
      'Object.defineProperty(#, #, '
          '{value: #, enumerable: false, writable: true, configurable: true})',
      obj,
      property,
      value);
}


// Is [obj] an instance of a Dart-defined class?
bool isDartObject(obj) {
  // Some of the extra parens here are necessary.
  return JS('bool', '((#) instanceof (#))', obj, JS_DART_OBJECT_CONSTRUCTOR());
}

/**
 * A JavaScript object mapping tags to the constructors of interceptors.
 *
 * Example: 'HTMLImageElement' maps to the ImageElement class constructor.
 */
get interceptorsByTag => JS('=Object', 'init.interceptorsByTag');

/**
 * A JavaScript object mapping tags to `true` or `false`.
 *
 * Example: 'HTMLImageElement' maps to `true` since, as there are no subclasses
 * of ImageElement, it is a leaf class in the native class hierarchy.
 */
get leafTags => JS('=Object', 'init.leafTags');

String findDispatchTagForInterceptorClass(interceptorClassConstructor) {
  return JS('', r'#.$nativeSuperclassTag', interceptorClassConstructor);
}

lookupInterceptor(var hasOwnPropertyFunction, String tag) {
  var map = interceptorsByTag;
  if (map == null) return null;
  return callHasOwnProperty(hasOwnPropertyFunction, map, tag)
      ? propertyGet(map, tag)
      : null;
}

lookupDispatchRecord(obj) {
  var hasOwnPropertyFunction = JS('var', 'Object.prototype.hasOwnProperty');
  var interceptorClass = null;
  assert(!isDartObject(obj));
  String tag = getTagFunction(obj);

  interceptorClass = lookupInterceptor(hasOwnPropertyFunction, tag);
  if (interceptorClass == null) {
    String secondTag = alternateTagFunction(obj, tag);
    if (secondTag != null) {
      interceptorClass = lookupInterceptor(hasOwnPropertyFunction, secondTag);
    }
  }
  if (interceptorClass == null) {
    // This object is not known to Dart.  There could be several
    // reasons for that, including (but not limited to):
    // * A bug in native code (hopefully this is caught during development).
    // * An unknown DOM object encountered.
    // * JavaScript code running in an unexpected context.  For
    //   example, on node.js.
    return null;
  }
  var interceptor = JS('', '#.prototype', interceptorClass);
  var isLeaf = JS('bool', '(#[#]) === true', leafTags, tag);
  if (isLeaf) {
    return makeLeafDispatchRecord(interceptor);
  } else {
    var proto = JS('', 'Object.getPrototypeOf(#)', obj);
    return makeDispatchRecord(interceptor, proto, null, null);
  }
}

makeLeafDispatchRecord(interceptor) {
  var fieldName = JS_IS_INDEXABLE_FIELD_NAME();
  bool indexability = JS('bool', r'!!#[#]', interceptor, fieldName);
  return makeDispatchRecord(interceptor, false, null, indexability);
}

makeDefaultDispatchRecord(tag, interceptorClass, proto) {
  var interceptor = JS('', '#.prototype', interceptorClass);
  var isLeaf = JS('bool', '(#[#]) === true', leafTags, tag);
  if (isLeaf) {
    return makeLeafDispatchRecord(interceptor);
  } else {
    return makeDispatchRecord(interceptor, proto, null, null);
  }
}

/**
 * [proto] should have no shadowing prototypes that are not also assigned a
 * dispatch rescord.
 */
setNativeSubclassDispatchRecord(proto, interceptor) {
  setDispatchProperty(proto, makeLeafDispatchRecord(interceptor));
}

String constructorNameFallback(object) {
  return JS('String', '#(#)', _constructorNameFallback, object);
}


var initNativeDispatchFlag;  // null or true

void initNativeDispatch() {
  if (true == initNativeDispatchFlag) return;
  initNativeDispatchFlag = true;

  initHooks();

  // Try to pro-actively patch prototypes of DOM objects.  For each of our known
  // tags `TAG`, if `window.TAG` is a (constructor) function, set the dispatch
  // property if the function's prototype to a dispatch record.
  if (JS('bool', 'typeof window != "undefined"')) {
    var context = JS('=Object', 'window');
    var map = interceptorsByTag;
    var tags = JS('JSMutableArray', 'Object.getOwnPropertyNames(#)', map);
    for (int i = 0; i < tags.length; i++) {
      var tag = tags[i];
      if (JS('bool', 'typeof (#[#]) == "function"', context, tag)) {
        var constructor = JS('', '#[#]', context, tag);
        var proto = JS('', '#.prototype', constructor);
        if (proto != null) {  // E.g. window.mozRTCIceCandidate.prototype
          var interceptorClass = JS('', '#[#]', map, tag);
          var record = makeDefaultDispatchRecord(tag, interceptorClass, proto);
          if (record != null) {
            setDispatchProperty(proto, record);
          }
        }
      }
    }
  }
}


/**
 * Initializes [getTagFunction] and [alternateTagFunction].
 *
 * These functions are 'hook functions', collectively 'hooks'.  They initialized
 * by applying a series of hooks transformers.  Built-in hooks transformers deal
 * with various known browser behaviours.
 *
 * Each hook tranformer takes a 'hooks' input a JavaScript object containing the
 * hook functions, and returns the same or a new object with replacements.  The
 * replacements can wrap the originals to provide alternate or modified
 * behaviour.
 *
 *     { getTag: function(obj) {...},
 *       getUnknownTag: function(obj, tag) {...},
 *       discriminator: function(tag) {...},
 *      }
 *
 * * getTag(obj) returns the dispatch tag, or `null`.
 * * getUnknownTag(obj, tag) returns a tag when [getTag] fails.
 * * discriminator returns a function TBD.
 *
 * The web site can adapt a dart2js application by loading code ahead of the
 * dart2js application that defines hook transformers to be after the built in
 * ones.  Code defining a transformer HT should use the following pattern to
 * ensure multiple transformers can be composed:
 *
 *     (dartNativeDispatchHooksTransformer =
 *      window.dartNativeDispatchHooksTransformer || []).push(HT);
 *
 *
 * TODO: Implement and describe dispatch tags and their caching methods.
 */
void initHooks() {
  // The initial simple hooks:
  var hooks = JS('', '#()', _baseHooks);

  // Csutomize for browsers where `object.constructor.name` fails:
  var _fallbackConstructorHooksTransformer =
      JS('', '#(#)', _fallbackConstructorHooksTransformerGenerator,
          _constructorNameFallback);
  hooks = applyHooksTransformer(_fallbackConstructorHooksTransformer, hooks);

  // Customize for browsers:
  hooks = applyHooksTransformer(_firefoxHooksTransformer, hooks);
  hooks = applyHooksTransformer(_ieHooksTransformer, hooks);
  hooks = applyHooksTransformer(_operaHooksTransformer, hooks);
  hooks = applyHooksTransformer(_safariHooksTransformer, hooks);

  // TODO(sra): Update ShadowDOM polyfil to use
  // [dartNativeDispatchHooksTransformer] and remove this hook.
  hooks = applyHooksTransformer(_dartExperimentalFixupGetTagHooksTransformer,
      hooks);

  // Apply global hooks.
  //
  // If defined, dartNativeDispatchHookdTransformer should be a JavaScript Array
  // of functions.  We will permit a function.

  if (JS('bool', 'typeof dartNativeDispatchHooksTransformer != "undefined"')) {
    var transformers = JS('', 'dartNativeDispatchHooksTransformer');
    if (JS('bool', 'typeof # == "function"', transformers)) {
      transformers = [transformers];
    }
    if (JS('bool', '#.constructor == Array', transformers)) {
      for (int i = 0; i < JS('int', '#.length', transformers); i++) {
        var transformer = JS('', '#[#]', transformers, i);
        if (JS('bool', 'typeof # == "function"', transformer)) {
          hooks = applyHooksTransformer(transformer, hooks);
        }
      }
    }
  }

  var getTag = JS('', '#.getTag', hooks);
  var getUnknownTag = JS('', '#.getUnknownTag', hooks);

  getTagFunction = (o) => JS('String|Null', '#(#)', getTag, o);
  alternateTagFunction =
      (o, String tag) => JS('String|Null', '#(#, #)', getUnknownTag, o, tag);
}

applyHooksTransformer(transformer, hooks) {
  var newHooks = JS('=Object|Null', '#(#)', transformer, hooks);
  return JS('', '# || #', newHooks, hooks);
}


// JavaScript code fragments.
//
// This is a temporary place for the JavaScript code.
//
// TODO(sra): These code fragments are not minified.  They could be generated by
// the code emitter, or JS_CONST could be improved to parse entire functions and
// take care of the minification.

const _baseHooks = const JS_CONST(r"""
function() {
  function typeNameInChrome(obj) { return obj.constructor.name; }
  function getUnknownTag(object, tag) {
    // This code really belongs in [getUnknownTagGenericBrowser] but having it
    // here allows [getUnknownTag] to be tested on d8.
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      // Check that it is not a simple JavaScript object.
      var name = Object.prototype.toString.call(object);
      if (name == '[object Object]') return null;
      return 'HTMLElement';
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function discriminator(tag) { return null; }

  var isBrowser = typeof navigator == "object";

  return {
    getTag: typeNameInChrome,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    discriminator: discriminator };
}""");


/**
 * Returns the name of the constructor function for browsers where
 * `object.constructor.name` is not reliable.
 *
 * This function is split out of [_fallbackConstructorHooksTransformerGenerator]
 * as it is called from both the dispatch hooks and via
 * [constructorNameFallback] from objectToString.
 */
const _constructorNameFallback = const JS_CONST(r"""
function getTagFallback(o) {
  if (o == null) return "Null";
  var constructor = o.constructor;
  if (typeof constructor == "function") {
    var name = constructor.builtin$cls;
    if (typeof name == "string") return name;
    // The constructor isn't null or undefined at this point. Try
    // to grab hold of its name.
    name = constructor.name;
    // If the name is a non-empty string, we use that as the type name of this
    // object. On Firefox, we often get 'Object' as the constructor name even
    // for more specialized objects so we have to fall through to the toString()
    // based implementation below in that case.
    if (typeof name == "string"
        && name !== ""
        && name !== "Object"
        && name !== Function.prototype) {  // Can happen in Opera.
      return name;
    }
  }
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}""");


const _fallbackConstructorHooksTransformerGenerator = const JS_CONST(r"""
function(getTagFallback) {
  return function(hooks) {
    // If we are not in a browser, assume we are in d8.
    // TODO(sra): Recognize jsshell.
    if (typeof navigator != "object") return hooks;

    var userAgent = navigator.userAgent;
    // TODO(antonm): remove a reference to DumpRenderTree.
    if (userAgent.indexOf("Chrome") >= 0 ||
        userAgent.indexOf("DumpRenderTree") >= 0) {
      return hooks;
    }

    hooks.getTag = getTagFallback;
  };
}""");


const _ieHooksTransformer = const JS_CONST(r"""
function(hooks) {
  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";
  if (userAgent.indexOf("Trident/") == -1) return hooks;

  var getTag = hooks.getTag;

  function getTagIE(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      // IE calls both HTML and XML documents "Document", so we check for the
      // xmlVersion property, which is the empty string on HTML documents.
      if (!!o.xmlVersion) "Document";
      return "HTMLDocument";
    }
    if (tag == "BeforeUnloadEvent") return "Event";
    if (tag == "DataTransfer") return "Clipboard";
    if (tag == "HTMLDDElement") return "HTMLElement";
    if (tag == "HTMLDTElement") return "HTMLElement";
    if (tag == "HTMLPhraseElement") return "HTMLElement";
    if (tag == "Position") return "Geoposition";

    // Patches for types which report themselves as Objects.
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag
  }

  hooks.getTag = getTagIE;
}""");


const _firefoxHooksTransformer = const JS_CONST(r"""
function(hooks) {
  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";
  if (userAgent.indexOf("Firefox") == -1) return hooks;

  var getTag = hooks.getTag;

  function getTagFirefox(o) {
    var tag = getTag(o);
    if (tag == 'BeforeUnloadEvent') return 'Event';
    if (tag == 'DataTransfer') return 'Clipboard';
    if (tag == 'GeoGeolocation') return 'Geolocation';
    if (tag == 'WorkerMessageEvent') return 'MessageEvent';
    if (tag == 'XMLDocument') return 'Document';
    return tag;
  }

  hooks.getTag = getTagFirefox;
}""");


const _operaHooksTransformer = const JS_CONST(r"""
function(hooks) { return hooks; }
""");


const _safariHooksTransformer = const JS_CONST(r"""
function(hooks) { return hooks; }
""");


const _dartExperimentalFixupGetTagHooksTransformer = const JS_CONST(r"""
function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}""");
