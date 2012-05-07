// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String typeNameInChrome(obj) {
  String name = JS('String', "#.constructor.name", obj);
  if (name == 'Window') return 'DOMWindow';
  if (name == 'CanvasPixelArray') return 'Uint8ClampedArray';
  return name;
}

String typeNameInFirefox(obj) {
  String name = constructorNameFallback(obj);
  if (name == 'Window') return 'DOMWindow';
  if (name == 'Document') return 'HTMLDocument';
  if (name == 'XMLDocument') return 'Document';
  if (name == 'WorkerMessageEvent') return 'MessageEvent';
  return name;
}

String typeNameInIE(obj) {
  String name = constructorNameFallback(obj);
  if (name == 'Window') return 'DOMWindow';
  if (name == 'Document') {
    // IE calls both HTML and XML documents 'Document', so we check for the
    // xmlVersion property, which is the empty string on HTML documents.
    if (JS('bool', '!!#.xmlVersion', obj)) return 'Document';
    return 'HTMLDocument';
  }
  if (name == 'HTMLTableDataCellElement') return 'HTMLTableCellElement';
  if (name == 'HTMLTableHeaderCellElement') return 'HTMLTableCellElement';
  if (name == 'MSStyleCSSProperties') return 'CSSStyleDeclaration';
  if (name == 'CanvasPixelArray') return 'Uint8ClampedArray';
  if (name == 'HTMLPhraseElement') return 'HTMLElement';
  return name;
}

String constructorNameFallback(obj) {
  var constructor = JS('var', "#.constructor", obj);
  if (JS('String', "typeof(#)", constructor) === 'function') {
    // The constructor isn't null or undefined at this point. Try
    // to grab hold of its name.
    var name = JS('var', '#.name', constructor);
    // If the name is a non-empty string, we use that as the type
    // name of this object. On Firefox, we often get 'Object' as
    // the constructor name even for more specialized objects so
    // we have to fall through to the toString() based implementation
    // below in that case.
    if (JS('String', "typeof(#)", name) === 'string'
        && !name.isEmpty()
        && name !== 'Object') {
      return name;
    }
  }
  String string = JS('String', 'Object.prototype.toString.call(#)', obj);
  return string.substring(8, string.length - 1);
}


/**
 * Returns the function to use to get the type name of an object.
 */
Function getFunctionForTypeNameOf() {
  // If we're not in the browser, we're almost certainly running on v8.
  if (JS('String', 'typeof(navigator)') !== 'object') return typeNameInChrome;

  String userAgent = JS('String', "navigator.userAgent");
  if (userAgent.contains(const RegExp('Chrome|DumpRenderTree'))) {
    return typeNameInChrome;
  } else if (userAgent.contains('Firefox')) {
    return typeNameInFirefox;
  } else if (userAgent.contains('MSIE')) {
    return typeNameInIE;
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
  if (_getTypeNameOf === null) _getTypeNameOf = getFunctionForTypeNameOf();
  return _getTypeNameOf(obj);
}

String toStringForNativeObject(var obj) {
  return 'Instance of ${getTypeNameOf(obj)}';
}

/**
 * Sets a JavaScript property on an object.
 */
void defineProperty(var obj, String property, var value) {
  JS('void', """Object.defineProperty(#, #,
      {value: #, enumerable: false, writable: false, configurable: true});""",
      obj,
      property,
      value);
}

/**
 * Helper method to throw a [NoSuchMethodException] for a invalid call
 * on a native object.
 */
void throwNoSuchMethod(obj, name, arguments) {
  throw new NoSuchMethodException(obj, name, arguments);
}

/**
 * This method looks up the type name of [obj] in [methods]. [methods]
 * is a Javascript object. If it cannot find it, it looks into the
 * [_dynamicMetadata] array. If the method can still not be found, it
 * creates a method that will throw a [NoSuchMethodException].
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

  if (method === null && _dynamicMetadata !== null) {
    for (int i = 0; i < _dynamicMetadata.length; i++) {
      MetaInfo entry = _dynamicMetadata[i];
      if (entry.set.contains(tag)) {
        method = JS('var', '#[#]', methods, entry.tag);
        if (method !== null) break;
      }
    }
  }

  if (method === null) {
    method = JS('var', "#['Object']", methods);
  }

  var proto = JS('var', 'Object.getPrototypeOf(#)', obj);
  if (method === null) {
    // If the method cannot be found, we use a trampoline method that
    // will throw a [NoSuchMethodException] if the object is of the
    // exact prototype, or will call [dynamicBind] again if the object
    // is a subclass.
    method = JS('var',
        'function () {'
          'if (Object.getPrototypeOf(this) === #) {'
            '#(this, #, Array.prototype.slice.call(arguments));'
          '} else {'
            'return Object.prototype[#].apply(this, arguments);'
          '}'
        '}',
      proto, DART_CLOSURE_TO_JS(throwNoSuchMethod), name, name);
  }

  var nullCheckMethod = JS('var',
      'function() {'
        'var res = #.apply(this, Array.prototype.slice.call(arguments));'
        'return res === null ? (void 0) : res;'
      '}',
    method);

  if (JS('bool', '!#.hasOwnProperty(#)', proto, name)) {
    defineProperty(proto, name, nullCheckMethod);
  }

  return JS('var', '#.apply(#, #)', nullCheckMethod, obj, arguments);
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
  if (f !== null && JS('bool', '!!#.methods', f)) {
    return JS('var', '#.methods', f);
  }

  // TODO(ngeoffray): We could make this a map if the code we
  // generate plays well with a Dart map.
  var methods = JS('var', '{}');
  // If there is a method attached to the Dart Object class, use it as
  // the method to call in case no method is registered for that type.
  var dartMethod = JS('var', 'Object.getPrototypeOf(#)[#]', const Object(), name);
  if (dartMethod !== null) JS('void', "#['Object'] = #", methods, dartMethod);

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
  String tag;

  /**
   * A string containing the names of subtypes of [tag], separated by
   * '|'.
   */
  String tags;

  /**
   * A list of names of subtypes of [tag].
   */
  Set<String> set;

  MetaInfo(this.tag, this.tags, this.set);
}

List<MetaInfo> get _dynamicMetadata() {
  // Because [dynamicMetadata] has to be shared with multiple isolates
  // that access native classes (eg multiple DOM isolates),
  // [_dynamicMetadata] cannot be a field, otherwise all non-main
  // isolates would not have any value for it.
  if (JS('var', 'typeof(\$dynamicMetadata)') === 'undefined') {
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
  for (int i = 0; i < inputTable.length; i++) {
    String tag = inputTable[i][0];
    String tags = inputTable[i][1];
    Set<String> set = new Set<String>();
    List<String> tagNames = tags.split('|');
    for (int j = 0; j < tagNames.length; j++) {
      set.add(tagNames[j]);
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
