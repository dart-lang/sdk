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
  if (name == 'Window') return 'DOMWindow';
  if (name == 'CanvasPixelArray') return 'Uint8ClampedArray';
  if (name == 'WebKitMutationObserver') return 'MutationObserver';
  if (name == 'AudioChannelMerger') return 'ChannelMergerNode';
  if (name == 'AudioChannelSplitter') return 'ChannelSplitterNode';
  if (name == 'AudioGainNode') return 'GainNode';
  if (name == 'AudioPannerNode') return 'PannerNode';
  if (name == 'JavaScriptAudioNode') return 'ScriptProcessorNode';
  if (name == 'Oscillator') return 'OscillatorNode';
  if (name == 'RealtimeAnalyserNode') return 'AnalyserNode';
  if (name == 'IDBVersionChangeRequest') return 'IDBOpenDBRequest';
  return name;
}

String typeNameInOpera(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'Window') return 'DOMWindow';
  if (name == 'ApplicationCache') return 'DOMApplicationCache';
  return name;
}

String typeNameInFirefox(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'Window') return 'DOMWindow';
  if (name == 'BeforeUnloadEvent') return 'Event';
  if (name == 'CSS2Properties') return 'CSSStyleDeclaration';
  if (name == 'DataTransfer') return 'Clipboard';
  if (name == 'DragEvent') return 'MouseEvent';
  if (name == 'GeoGeolocation') return 'Geolocation';
  if (name == 'MouseScrollEvent') return 'WheelEvent';
  if (name == 'OfflineResourceList') return 'DOMApplicationCache';
  if (name == 'WorkerMessageEvent') return 'MessageEvent';
  if (name == 'XMLDocument') return 'Document';
  return name;
}

String typeNameInIE(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'Window') return 'DOMWindow';
  if (name == 'Document') {
    // IE calls both HTML and XML documents 'Document', so we check for the
    // xmlVersion property, which is the empty string on HTML documents.
    if (JS('bool', '!!#.xmlVersion', obj)) return 'Document';
    return 'HTMLDocument';
  }
  if (name == 'ApplicationCache') return 'DOMApplicationCache';
  if (name == 'BeforeUnloadEvent') return 'Event';
  if (name == 'CanvasPixelArray') return 'Uint8ClampedArray';
  if (name == 'DataTransfer') return 'Clipboard';
  if (name == 'DragEvent') return 'MouseEvent';
  if (name == 'HTMLDDElement') return 'HTMLElement';
  if (name == 'HTMLDTElement') return 'HTMLElement';
  if (name == 'HTMLTableDataCellElement') return 'HTMLTableCellElement';
  if (name == 'HTMLTableHeaderCellElement') return 'HTMLTableCellElement';
  if (name == 'HTMLPhraseElement') return 'HTMLElement';
  if (name == 'MSStyleCSSProperties') return 'CSSStyleDeclaration';
  if (name == 'MouseWheelEvent') return 'WheelEvent';
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
    // The constructor isn't null or undefined at this point. Try
    // to grab hold of its name.
    var name = JS('var', '#.name', constructor);
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

/**
 * Returns the function to use to get the type name of an object.
 */
Function getFunctionForTypeNameOf() {
  // If we're not in the browser, we're almost certainly running on v8.
  if (!identical(JS('String', 'typeof(navigator)'), 'object')) return typeNameInChrome;

  String userAgent = JS('String', "navigator.userAgent");
  if (contains(userAgent, 'Chrome') || contains(userAgent, 'DumpRenderTree')) {
    return typeNameInChrome;
  } else if (contains(userAgent, 'Firefox')) {
    return typeNameInFirefox;
  } else if (contains(userAgent, 'MSIE')) {
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


/**
 * Cached value for the function to use to get the type name of an
 * object.
 */
Function _getTypeNameOf;

/**
 * Returns the type name of [obj].
 */
String getTypeNameOf(var obj) {
  if (_getTypeNameOf == null) _getTypeNameOf = getFunctionForTypeNameOf();
  return _getTypeNameOf(obj);
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

/// A JavaScript object mapping tags to interceptors.
var interceptorsByTag;

/// A JavaScript object mapping tags to `true` or `false`.
var leafTags;

/**
 * Associates tags with an interceptor.  Called from generated code.  The tags
 * are all 'leaf' tags representing classes that have no subclasses with
 * different behaviour.
 *
 * [tags] is a string of `|`-separated tags.
 */
void defineNativeMethods(String tags, interceptorClass) {
  defineNativeMethodsCommon(tags, interceptorClass, true);
}

/**
 * Associates tags with an interceptor.  Called from generated code.  The tags
 * are all non-'leaf' tags, representing classes that have a subclass with
 * different behaviour.
 */
void defineNativeMethodsNonleaf(String tags, interceptorClass) {
  defineNativeMethodsCommon(tags, interceptorClass, false);
}

void defineNativeMethodsCommon(String tags, var interceptorClass, bool isLeaf) {
  var methods = JS('', '#.prototype', interceptorClass);
  if (interceptorsByTag == null) interceptorsByTag = JS('=Object', '{}');
  if (leafTags == null) leafTags = JS('=Object', '{}');

  var tagsList = JS('=List', '#.split("|")', tags);
  for (int i = 0; i < tagsList.length; i++) {
    var tag = tagsList[i];
    JS('void', '#[#] = #', interceptorsByTag, tag, methods);
    JS('void', '#[#] = #', leafTags, tag, isLeaf);
  }
}

void defineNativeMethodsFinish() {
  // TODO(sra): Investigate placing a dispatch record on Object.prototype that
  // returns an interceptor for JavaScript objects.  This avoids needing a test
  // in every interceptor, and prioritizes the performance of known native
  // classes over unknown.
}

lookupInterceptor(var hasOwnPropertyFunction, String tag) {
  var map = interceptorsByTag;
  return callHasOwnProperty(hasOwnPropertyFunction, map, tag)
      ? propertyGet(map, tag)
      : null;
}

lookupDispatchRecord(obj) {
  var hasOwnPropertyFunction = JS('var', 'Object.prototype.hasOwnProperty');
  var interceptor = null;
  assert(!isDartObject(obj));
  String tag = getTypeNameOf(obj);

  interceptor = lookupInterceptor(hasOwnPropertyFunction, tag);
  if (interceptor == null) {
    String secondTag = alternateTag(obj, tag);
    if (secondTag != null) {
      interceptor = lookupInterceptor(hasOwnPropertyFunction, secondTag);
    }
  }
  if (interceptor == null) {
    // TODO(sra): Think about the error case.
    interceptor = JS('', '{__what: "interceptor not found", __tag: #}', tag);
  }
  var isLeaf = JS('', '#[#]', leafTags, tag);
  if (true == isLeaf) {
    return makeDispatchRecord(interceptor, false, null);
  } else {
    var proto = JS('', 'Object.getPrototypeOf(#)', obj);
    return makeDispatchRecord(interceptor, proto, null);
  }
}
