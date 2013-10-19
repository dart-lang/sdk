// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js;

import 'dart:html' show Blob, ImageData, Node;
import 'dart:collection' show HashMap;
import 'dart:indexed_db' show KeyRange;
import 'dart:typed_data' show TypedData;

import 'dart:_foreign_helper' show JS, DART_CLOSURE_TO_JS;
import 'dart:_interceptors' show JavaScriptObject, UnknownJavaScriptObject;
import 'dart:_js_helper' show Primitives, convertDartClosureToJS;

final JsObject context = new JsObject._fromJs(Primitives.computeGlobalThis());

_convertDartFunction(Function f, {bool captureThis: false}) {
  return JS('',
    'function(_call, f, captureThis) {'
      'return function() {'
        'return _call(f, captureThis, this, '
            'Array.prototype.slice.apply(arguments));'
      '}'
    '}(#, #, #)', DART_CLOSURE_TO_JS(_callDartFunction), f, captureThis);
}

_callDartFunction(callback, bool captureThis, self, List arguments) {
  if (captureThis) {
    arguments = [self]..addAll(arguments);
  }
  var dartArgs = arguments.map(_convertToDart).toList();
  return _convertToJS(Function.apply(callback, dartArgs));
}


class JsObject {
  // The wrapped JS object.
  final dynamic _jsObject;

  JsObject._fromJs(this._jsObject) {
    assert(_jsObject != null);
    // Remember this proxy for the JS object
    _getDartProxy(_jsObject, _DART_OBJECT_PROPERTY_NAME, (o) => this);
  }

  /**
   * Expert use only:
   *
   * Use this constructor only if you wish to get access to JS properties
   * attached to a browser host object such as a Node or Blob. This constructor
   * will return a JsObject proxy on [object], even though the object would
   * normally be returned as a native Dart object.
   * 
   * An exception will be thrown if [object] is a primitive type or null.
   */
  factory JsObject.fromBrowserObject(Object object) {
    if (object is num || object is String || object is bool || object == null) {
      throw new ArgumentError(
        "object cannot be a num, string, bool, or null");
    }
    return new JsObject._fromJs(_convertToJS(object));
  }

  /**
   * Converts a json-like [data] to a JavaScript map or array and return a
   * [JsObject] to it.
   */
  factory JsObject.jsify(Object object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw new ArgumentError("object must be a Map or Iterable");
    }
    return new JsObject._fromJs(_convertDataTree(object));
  }

  factory JsObject(JsFunction constructor, [List arguments]) {
    var constr = _convertToJS(constructor);
    if (arguments == null) {
      return new JsObject._fromJs(JS('', 'new #()', constr));
    }
    // The following code solves the problem of invoking a JavaScript
    // constructor with an unknown number arguments.
    // First bind the constructor to the argument list using bind.apply().
    // The first argument to bind() is the binding of 'this', so add 'null' to
    // the arguments list passed to apply().
    // After that, use the JavaScript 'new' operator which overrides any binding
    // of 'this' with the new instance.
    var args = [null]..addAll(arguments.map(_convertToJS));
    var factoryFunction = JS('', '#.bind.apply(#, #)', constr, constr, args);
    // Without this line, calling factoryFunction as a constructor throws
    JS('String', 'String(#)', factoryFunction);
    // This could return an UnknownJavaScriptObject, or a native
    // object for which there is an interceptor
    var jsObj = JS('JavaScriptObject', 'new #()', factoryFunction);
    return new JsObject._fromJs(jsObj);
  }

  // TODO: handle cycles
  static _convertDataTree(data) {
    var _convertedObjects = new HashMap.identity();

    _convert(o) {
      if (_convertedObjects.containsKey(o)) {
        return _convertedObjects[o];
      }
      if (o is Map) {
        final convertedMap = JS('=Object', '{}');
        _convertedObjects[o] = convertedMap;
        for (var key in o.keys) {
          JS('=Object', '#[#]=#', convertedMap, key, _convert(o[key]));
        }
        return convertedMap;
      } else if (o is Iterable) {
        var convertedList = [];
        _convertedObjects[o] = convertedList;
        convertedList.addAll(o.map(_convert));
        return convertedList;
      } else {
        return _convertToJS(o);
      }
    }

    return _convert(data);
  }

  /**
   * Returns the value associated with [key] from the proxied JavaScript
   * object.
   *
   * [key] must either be a [String] or [num].
   */
  // TODO(justinfagnani): rename key/name to property
  dynamic operator[](key) {
    if (key is! String && key is! num) {
      throw new ArgumentError("key is not a String or num");
    }
    return _convertToDart(JS('', '#[#]', _jsObject, key));
  }
  
  /**
   * Sets the value associated with [key] from the proxied JavaScript
   * object.
   *
   * [key] must either be a [String] or [num].
   */
  operator[]=(key, value) {
    if (key is! String && key is! num) {
      throw new ArgumentError("key is not a String or num");
    }
    JS('', '#[#]=#', _jsObject, key, _convertToJS(value));
  }

  int get hashCode => 0;

  bool operator==(other) => other is JsObject &&
      JS('bool', '# === #', _jsObject, other._jsObject);

  bool hasProperty(name) {
    if (name is! String && name is! num) {
      throw new ArgumentError("name is not a String or num");
    }
    return JS('bool', '# in #', name, _jsObject);
  }

  void deleteProperty(name) {
    if (name is! String && name is! num) {
      throw new ArgumentError("name is not a String or num");
    }
    JS('bool', 'delete #[#]', _jsObject, name);
  }

  bool instanceof(type) {
    return JS('bool', '# instanceof #', _jsObject, _convertToJS(type));
  }

  String toString() {
    try {
      return JS('String', 'String(#)', _jsObject);
    } catch(e) {
      return super.toString();
    }
  }

  dynamic callMethod(name, [List args]) {
    if (name is! String && name is! num) {
      throw new ArgumentError("name is not a String or num");
    }
    return _convertToDart(JS('', '#[#].apply(#, #)', _jsObject, name,
        _jsObject,
        args == null ? null : args.map(_convertToJS).toList()));
  }
}

class JsFunction extends JsObject {

  /**
   * Returns a [JsFunction] that captures its 'this' binding and calls [f]
   * with the value of this passed as the first argument.
   */
  factory JsFunction.withThis(Function f) {
    var jsFunc = _convertDartFunction(f, captureThis: true);
    return new JsFunction._fromJs(jsFunc);
  }

  JsFunction._fromJs(jsObject) : super._fromJs(jsObject);

  dynamic apply(List args, { thisArg }) =>
      _convertToDart(JS('', '#.apply(#, #)', _jsObject,
          _convertToJS(thisArg),
          args == null ? null : args.map(_convertToJS).toList()));
}

// property added to a Dart object referencing its JS-side DartObject proxy
const _DART_OBJECT_PROPERTY_NAME = r'_$dart_dartObject';
const _DART_CLOSURE_PROPERTY_NAME = r'_$dart_dartClosure';

// property added to a JS object referencing its Dart-side JsObject proxy
const _JS_OBJECT_PROPERTY_NAME = r'_$dart_jsObject';
const _JS_FUNCTION_PROPERTY_NAME = r'$dart_jsFunction';

bool _defineProperty(o, String name, value) {
  if (JS('bool', 'Object.isExtensible(#)', o)) {
    try {
      JS('void', 'Object.defineProperty(#, #, { value: #})', o, name, value);
      return true;
    } catch(e) {
      // object is native and lies about being extensible
      // see https://bugzilla.mozilla.org/show_bug.cgi?id=775185
    }
  }
  return false;
}

dynamic _convertToJS(dynamic o) {
  if (o == null) {
    return null;
  } else if (o is String || o is num || o is bool
    || o is Blob || o is KeyRange || o is ImageData || o is Node 
    || o is TypedData) {
    return o;
  } else if (o is DateTime) {
    return Primitives.lazyAsJsDate(o);
  } else if (o is JsObject) {
    return o._jsObject;
  } else if (o is Function) {
    return _getJsProxy(o, _JS_FUNCTION_PROPERTY_NAME, (o) {
      var jsFunction = _convertDartFunction(o);
      // set a property on the JS closure referencing the Dart closure
      _defineProperty(jsFunction, _DART_CLOSURE_PROPERTY_NAME, o);
      return jsFunction;
    });
  } else {
    return _getJsProxy(o, _JS_OBJECT_PROPERTY_NAME,
        (o) => JS('', 'new DartObject(#)', o));
  }
}

Object _getJsProxy(o, String propertyName, createProxy(o)) {
  var jsProxy = JS('', '#[#]', o, propertyName);
  if (jsProxy == null) {
    jsProxy = createProxy(o);
    _defineProperty(o, propertyName, jsProxy);
  }
  return jsProxy;
}

// converts a Dart object to a reference to a native JS object
// which might be a DartObject JS->Dart proxy
Object _convertToDart(o) {
  if (JS('bool', '# == null', o) ||
      JS('bool', 'typeof # == "string"', o) ||
      JS('bool', 'typeof # == "number"', o) ||
      JS('bool', 'typeof # == "boolean"', o)) {
    return o;
  } else if (o is Blob || o is DateTime || o is KeyRange 
      || o is ImageData || o is Node || o is TypedData) {
    return JS('Blob|DateTime|KeyRange|ImageData|Node|TypedData', '#', o);
  } else if (JS('bool', 'typeof # == "function"', o)) {
    return _getDartProxy(o, _DART_CLOSURE_PROPERTY_NAME,
        (o) => new JsFunction._fromJs(o));
  } else if (JS('bool', '#.constructor === DartObject', o)) {
    return JS('', '#.o', o);
  } else {
    return _getDartProxy(o, _DART_OBJECT_PROPERTY_NAME,
        (o) => new JsObject._fromJs(o));
  }
}

Object _getDartProxy(o, String propertyName, createProxy(o)) {
  var dartProxy = JS('', '#[#]', o, propertyName);
  if (dartProxy == null) {
    dartProxy = createProxy(o);
    _defineProperty(o, propertyName, dartProxy);
  }
  return dartProxy;
}
