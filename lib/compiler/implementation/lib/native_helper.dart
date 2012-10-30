// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String typeNameInChrome(obj) {
  String name = JS('String', "#.constructor.name", obj);
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
  return name;
}

String typeNameInSafari(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  // Safari is very similar to Chrome.
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
  return name;
}

String typeNameInOpera(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'Window') return 'DOMWindow';
  return name;
}

String typeNameInFirefox(obj) {
  String name = JS('String', '#', constructorNameFallback(obj));
  if (name == 'Window') return 'DOMWindow';
  if (name == 'Document') return 'HTMLDocument';
  if (name == 'XMLDocument') return 'Document';
  if (name == 'WorkerMessageEvent') return 'MessageEvent';
  if (name == 'DragEvent') return 'MouseEvent';
  if (name == 'DataTransfer') return 'Clipboard';
  if (name == 'MouseScrollEvent') return 'WheelEvent';
  if (name == 'OfflineResourceList') return 'DOMApplicationCache';
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

void propertySet(var object, String property, var value) {
  JS('var', '#[#] = #', object, property, value);
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

String hashCodeForNativeObject(object) => Primitives.objectHashCode(object);

/**
 * Sets a JavaScript property on an object.
 */
void defineProperty(var obj, String property, var value) {
  JS('void', """Object.defineProperty(#, #,
      {value: #, enumerable: false, writable: true, configurable: true})""",
      obj,
      property,
      value);
}

/**
 * This method looks up the type name of [obj] in [methods]. [methods]
 * is a Javascript object. If it cannot find it, it looks into the
 * [_dynamicMetadata] array. If the method can still not be found, it
 * creates a method that will throw a [NoSuchMethodError].
 *
 * Once it has a method, the prototype of [obj] is patched with that
 * method, on the property [name]. The method is then invoked.
 *
 * This method returns the result of invoking the found method.
 */
dynamicBind(var obj,
            String name,
            var methods,
            List arguments) {
  String tag = getTypeNameOf(obj);
  var method = JS('var', '#[#]', methods, tag);

  if (method == null && _dynamicMetadata != null) {
    for (int i = 0; i < arrayLength(_dynamicMetadata); i++) {
      MetaInfo entry = arrayGet(_dynamicMetadata, i);
      if (JS('bool', '#', propertyGet(entry._set, tag))) {
        method = propertyGet(methods, entry._tag);
        if (method != null) break;
      }
    }
  }

  if (method == null) {
    method = propertyGet(methods, 'Object');
  }

  var proto = JS('var', 'Object.getPrototypeOf(#)', obj);
  if (method == null) {
    // If the method cannot be found, we use a trampoline method that
    // will throw a [NoSuchMethodError] if the object is of the
    // exact prototype, or will call [dynamicBind] again if the object
    // is a subclass.
    method = JS('var',
        'function () {'
          'if (Object.getPrototypeOf(this) === #) {'
            'throw new TypeError(# + " is not a function");'
          '} else {'
            'return Object.prototype[#].apply(this, arguments);'
          '}'
        '}',
      proto, name, name);
  }

  if (JS('bool', '!#.hasOwnProperty(#)', proto, name)) {
    defineProperty(proto, name, method);
  }

  return JS('var', '#.apply(#, #)', method, obj, arguments);
}

/**
 * Code for doing the dynamic dispatch on JavaScript prototypes that are not
 * available at compile-time. Each property of a native Dart class
 * is registered through this function, which is called with the
 * following pattern:
 *
 * dynamicFunction('propertyName').prototypeName = // JS code
 *
 * What this function does is:
 * - Creates a map of { prototypeName: JS code }.
 * - Attaches 'propertyName' to the JS Object prototype that will
 *   intercept at runtime all calls to propertyName.
 * - Sets the value of 'propertyName' to the returned method from
 *   [dynamicBind].
 *
 */
dynamicFunction(name) {
  var f = JS('var', 'Object.prototype[#]', name);
  if (f != null && JS('bool', '!!#.methods', f)) {
    return JS('var', '#.methods', f);
  }

  // TODO(ngeoffray): We could make this a map if the code we
  // generate plays well with a Dart map.
  var methods = JS('var', '{}');
  // If there is a method attached to the Dart Object class, use it as
  // the method to call in case no method is registered for that type.
  var dartMethod = JS('var', 'Object.getPrototypeOf(#)[#]', const Object(), name);
  if (dartMethod != null) propertySet(methods, 'Object', dartMethod);

  var bind = JS('var',
      'function() {'
        'return #(this, #, #, Array.prototype.slice.call(arguments));'
      '}',
    DART_CLOSURE_TO_JS(dynamicBind), name, methods);

  JS('void', '#.methods = #', bind, methods);
  defineProperty(JS('var', 'Object.prototype'), name, bind);
  return methods;
}

/**
 * This class encodes the class hierarchy when we need it for dynamic
 * dispatch.
 */
class MetaInfo {
  /**
   * The type name this [MetaInfo] relates to.
   */
  String _tag;

  /**
   * A string containing the names of subtypes of [tag], separated by
   * '|'.
   */
  String _tags;

  /**
   * A list of names of subtypes of [tag].
   */
  Object _set;

  MetaInfo(this._tag, this._tags, this._set);
}

List<MetaInfo> get _dynamicMetadata {
  // Because [dynamicMetadata] has to be shared with multiple isolates
  // that access native classes (eg multiple DOM isolates),
  // [_dynamicMetadata] cannot be a field, otherwise all non-main
  // isolates would not have any value for it.
  if (identical(JS('var', 'typeof(\$dynamicMetadata)'), 'undefined')) {
    _dynamicMetadata = <MetaInfo>[];
  }
  return JS('var', '\$dynamicMetadata');
}

void set _dynamicMetadata(List<MetaInfo> table) {
  JS('void', '\$dynamicMetadata = #', table);
}

/**
 * Builds the metadata used for encoding the class hierarchy of native
 * classes. The following example:
 *
 * class A native "*A" {}
 * class B extends A native "*B" {}
 *
 * Will generate:
 * ['A', 'A|B']
 *
 * This method returns a list of [MetaInfo] objects.
 */
List <MetaInfo> buildDynamicMetadata(List<List<String>> inputTable) {
  List<MetaInfo> result = <MetaInfo>[];
  for (int i = 0; i < arrayLength(inputTable); i++) {
    String tag = JS('String', '#', arrayGet(arrayGet(inputTable, i), 0));
    String tags = JS('String', '#', arrayGet(arrayGet(inputTable, i), 1));
    var set = newJsObject();
    List<String> tagNames = tags.split('|');
    for (int j = 0; j < arrayLength(tagNames); j++) {
      propertySet(set, arrayGet(tagNames, j), true);
    }
    result.add(new MetaInfo(tag, tags, set));
  }
  return result;
}

/**
 * Called by the compiler to setup [_dynamicMetadata].
 */
void dynamicSetMetadata(List<List<String>> inputTable) {
  _dynamicMetadata = buildDynamicMetadata(inputTable);
}
