// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

String typeNameInChrome(obj) {
  String name = JS('String', "#.constructor.name", obj);
  return typeNameInWebKitCommon(name);
}

String typeNameInSafari(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  // Safari is very similar to Chrome.
  return typeNameInWebKitCommon(name);
}

String typeNameInWebKitCommon(tag) {
  String name = JS('String', '#', tag);
  return name;
}

String typeNameInOpera(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  return name;
}

String typeNameInFirefox(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'BeforeUnloadEvent') return 'Event';
  if (name == 'DataTransfer') return 'Clipboard';
  if (name == 'GeoGeolocation') return 'Geolocation';
  if (name == 'WorkerMessageEvent') return 'MessageEvent';
  if (name == 'XMLDocument') return 'Document';
  return name;
}

String typeNameInIE(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'Document') {
    // IE calls both HTML and XML documents 'Document', so we check for the
    // xmlVersion property, which is the empty string on HTML documents.
    if (JS('bool', '!!#.xmlVersion', obj)) return 'Document';
    return 'HTMLDocument';
  }
  if (name == 'BeforeUnloadEvent') return 'Event';
  if (name == 'DataTransfer') return 'Clipboard';
  if (name == 'HTMLDDElement') return 'HTMLElement';
  if (name == 'HTMLDTElement') return 'HTMLElement';
  if (name == 'HTMLPhraseElement') return 'HTMLElement';
  if (name == 'Position') return 'Geoposition';

  // Patches for types which report themselves as Objects.
  if (name == 'Object') {
    if (JS('bool', 'window.DataView && (# instanceof window.DataView)', obj)) {
      return 'DataView';
    }
  }
  return name;
}

String constructorNameFallback(object) {
  if (object == null) return 'Null';
  var constructor = JS('var', "#.constructor", object);
  if (identical(JS('String', "typeof(#)", constructor), 'function')) {
    var name = JS('var', r'#.builtin$cls', constructor);
    if (name != null) return name;
    // The constructor isn't null or undefined at this point. Try
    // to grab hold of its name.
    name = JS('var', '#.name', constructor);
    // If the name is a non-empty string, we use that as the type
    // name of this object. On Firefox, we often get 'Object' as
    // the constructor name even for more specialized objects so
    // we have to fall through to the toString() based implementation
    // below in that case.
    if (name is String
        && !identical(name, '')
        && !identical(name, 'Object')
        && !identical(name, 'Function.prototype')) {  // Can happen in Opera.
      return name;
    }
  }
  String string = JS('String', 'Object.prototype.toString.call(#)', object);
  return JS('String', '#.substring(8, # - 1)', string, string.length);
}

/**
 * If a lookup on an object [object] that has [tag] fails, this function is
 * called to provide an alternate tag.  This allows us to fail gracefully if we
 * can make a good guess, for example, when browsers add novel kinds of
 * HTMLElement that we have never heard of.
 */
String alternateTag(object, String tag) {
  // Does it smell like some kind of HTML element?
  if (JS('bool', r'!!/^HTML[A-Z].*Element$/.test(#)', tag)) {
    // Check that it is not a simple JavaScript object.
    String string = JS('String', 'Object.prototype.toString.call(#)', object);
    if (string == '[object Object]') return null;
    return 'HTMLElement';
  }
  return null;
}

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

Function getTypeNameOf = getFunctionForTypeNameOf();

/**
 * Returns the function to use to get the type name (i.e. dispatch tag) of an
 * object.
 */
Function getFunctionForTypeNameOf() {
  var getTagFunction = getBaseFunctionForTypeNameOf();
  if (JS('bool', 'typeof dartExperimentalFixupGetTag == "function"')) {
    return applyExperimentalFixup(
        JS('', 'dartExperimentalFixupGetTag'), getTagFunction);
  }
  return getTagFunction;
}

/// Don't call directly, use [getFunctionForTypeNameOf] instead.
Function getBaseFunctionForTypeNameOf() {
  // If we're not in the browser, we're almost certainly running on v8.
  if (!identical(JS('String', 'typeof(navigator)'), 'object')) {
    return typeNameInChrome;
  }

  String userAgent = JS('String', "navigator.userAgent");
  // TODO(antonm): remove a reference to DumpRenderTree.
  if (contains(userAgent, 'Chrome') || contains(userAgent, 'DumpRenderTree')) {
    return typeNameInChrome;
  } else if (contains(userAgent, 'Firefox')) {
    return typeNameInFirefox;
  } else if (contains(userAgent, 'Trident/')) {
    return typeNameInIE;
  } else if (contains(userAgent, 'Opera')) {
    return typeNameInOpera;
  } else if (contains(userAgent, 'AppleWebKit')) {
    // Chrome matches 'AppleWebKit' too, but we test for Chrome first, so this
    // is not a problem.
    // Note: Just testing for "Safari" doesn't work when the page is embedded
    // in a UIWebView on iOS 6.
    return typeNameInSafari;
  } else {
    return constructorNameFallback;
  }
}

Function applyExperimentalFixup(fixupJSFunction,
                                Function originalGetTagDartFunction) {
  var originalGetTagJSFunction =
      convertDartClosure1ArgToJSNoDataConversions(
          originalGetTagDartFunction);

  var newGetTagJSFunction =
      JS('', '#(#)', fixupJSFunction, originalGetTagJSFunction);

  String newGetTagDartFunction(object) =>
      JS('', '#(#)', newGetTagJSFunction, object);

  return newGetTagDartFunction;
}

callDartFunctionWith1Arg(fn, arg) => fn(arg);

convertDartClosure1ArgToJSNoDataConversions(dartClosure) {
  return JS('',
      '(function(invoke, closure){'
        'return function(arg){ return invoke(closure, arg); };'
      '})(#, #)',
      DART_CLOSURE_TO_JS(callDartFunctionWith1Arg), dartClosure);
}


String toStringForNativeObject(var obj) {
  String name = JS('String', '#', getTypeNameOf(obj));
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
 * Example: 'HTMLImageElement' maps to the ImageElement native class
 * constructor.
 */
get interceptorsByTag => JS('=Object', 'init.interceptorsByTag');

/**
 * A JavaScript object mapping tags to `true` or `false`.
 *
 * Example: 'HTMLImageElement' maps to `true` since, as since there are no
 * subclasses of ImageElement, it is a leaf class in the native class hierarchy.
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
  String tag = getTypeNameOf(obj);

  interceptorClass = lookupInterceptor(hasOwnPropertyFunction, tag);
  if (interceptorClass == null) {
    String secondTag = alternateTag(obj, tag);
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

var initNativeDispatchFlag;  // null or true

void initNativeDispatch() {
  initNativeDispatchFlag = true;

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
 * [proto] should have no shadowing prototypes that are not also assigned a
 * dispatch rescord.
 */
setNativeSubclassDispatchRecord(proto, interceptor) {
  setDispatchProperty(proto, makeLeafDispatchRecord(interceptor));
}
