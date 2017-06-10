// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interoperating with JavaScript.
 *
 * This library provides access to JavaScript objects from Dart, allowing
 * Dart code to get and set properties, and call methods of JavaScript objects
 * and invoke JavaScript functions. The library takes care of converting
 * between Dart and JavaScript objects where possible, or providing proxies if
 * conversion isn't possible.
 *
 * This library does not yet make Dart objects usable from JavaScript, their
 * methods and proeprties are not accessible, though it does allow Dart
 * functions to be passed into and called from JavaScript.
 *
 * [JsObject] is the core type and represents a proxy of a JavaScript object.
 * JsObject gives access to the underlying JavaScript objects properties and
 * methods. `JsObject`s can be acquired by calls to JavaScript, or they can be
 * created from proxies to JavaScript constructors.
 *
 * The top-level getter [context] provides a [JsObject] that represents the
 * global object in JavaScript, usually `window`.
 *
 * The following example shows an alert dialog via a JavaScript call to the
 * global function `alert()`:
 *
 *     import 'dart:js';
 *
 *     main() => context.callMethod('alert', ['Hello from Dart!']);
 *
 * This example shows how to create a [JsObject] from a JavaScript constructor
 * and access its properties:
 *
 *     import 'dart:js';
 *
 *     main() {
 *       var object = new JsObject(context['Object']);
 *       object['greeting'] = 'Hello';
 *       object['greet'] = (name) => "${object['greeting']} $name";
 *       var message = object.callMethod('greet', ['JavaScript']);
 *       context['console'].callMethod('log', [message]);
 *     }
 *
 * ## Proxying and automatic conversion
 *
 * When setting properties on a JsObject or passing arguments to a Javascript
 * method or function, Dart objects are automatically converted or proxied to
 * JavaScript objects. When accessing JavaScript properties, or when a Dart
 * closure is invoked from JavaScript, the JavaScript objects are also
 * converted to Dart.
 *
 * Functions and closures are proxied in such a way that they are callable. A
 * Dart closure assigned to a JavaScript property is proxied by a function in
 * JavaScript. A JavaScript function accessed from Dart is proxied by a
 * [JsFunction], which has a [apply] method to invoke it.
 *
 * The following types are transferred directly and not proxied:
 *
 * * "Basic" types: `null`, `bool`, `num`, `String`, `DateTime`
 * * `Blob`
 * * `Event`
 * * `HtmlCollection`
 * * `ImageData`
 * * `KeyRange`
 * * `Node`
 * * `NodeList`
 * * `TypedData`, including its subclasses like `Int32List`, but _not_
 *   `ByteBuffer`
 * * `Window`
 *
 * ## Converting collections with JsObject.jsify()
 *
 * To create a JavaScript collection from a Dart collection use the
 * [JsObject.jsify] constructor, which converts Dart [Map]s and [Iterable]s
 * into JavaScript Objects and Arrays.
 *
 * The following expression creates a new JavaScript object with the properties
 * `a` and `b` defined:
 *
 *     var jsMap = new JsObject.jsify({'a': 1, 'b': 2});
 *
 * This expression creates a JavaScript array:
 *
 *     var jsArray = new JsObject.jsify([1, 2, 3]);
 */
library dart.js;

import 'dart:html' show Blob, Event, ImageData, Node, Window;
import 'dart:collection' show HashMap, ListMixin;
import 'dart:indexed_db' show KeyRange;
import 'dart:typed_data' show TypedData;

import 'dart:_foreign_helper' show JS, JS_CONST, DART_CLOSURE_TO_JS;
import 'dart:_interceptors'
    show JavaScriptObject, UnknownJavaScriptObject, DART_CLOSURE_PROPERTY_NAME;
import 'dart:_js_helper'
    show Primitives, convertDartClosureToJS, getIsolateAffinityTag;

export 'dart:_interceptors' show JavaScriptObject;

final JsObject context = _wrapToDart(JS('', 'self'));

_convertDartFunction(Function f, {bool captureThis: false}) {
  return JS(
      '',
      '''
        function(_call, f, captureThis) {
          return function() {
            return _call(f, captureThis, this,
                Array.prototype.slice.apply(arguments));
          }
        }(#, #, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunction),
      f,
      captureThis);
}

_callDartFunction(callback, bool captureThis, self, List arguments) {
  if (captureThis) {
    arguments = [self]..addAll(arguments);
  }
  var dartArgs = new List.from(arguments.map(_convertToDart));
  return _convertToJS(Function.apply(callback, dartArgs));
}

/**
 * Proxies a JavaScript object to Dart.
 *
 * The properties of the JavaScript object are accessible via the `[]` and
 * `[]=` operators. Methods are callable via [callMethod].
 */
class JsObject {
  // The wrapped JS object.
  final dynamic _jsObject;

  // This shoud only be called from _wrapToDart
  JsObject._fromJs(this._jsObject) {
    assert(_jsObject != null);
  }

  /**
   * Constructs a new JavaScript object from [constructor] and returns a proxy
   * to it.
   */
  factory JsObject(JsFunction constructor, [List arguments]) {
    var constr = _convertToJS(constructor);
    if (arguments == null) {
      return _wrapToDart(JS('', 'new #()', constr));
    }

    if (JS('bool', '# instanceof Array', arguments)) {
      int argumentCount = JS('int', '#.length', arguments);
      switch (argumentCount) {
        case 0:
          return _wrapToDart(JS('', 'new #()', constr));

        case 1:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          return _wrapToDart(JS('', 'new #(#)', constr, arg0));

        case 2:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          var arg1 = _convertToJS(JS('', '#[1]', arguments));
          return _wrapToDart(JS('', 'new #(#, #)', constr, arg0, arg1));

        case 3:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          var arg1 = _convertToJS(JS('', '#[1]', arguments));
          var arg2 = _convertToJS(JS('', '#[2]', arguments));
          return _wrapToDart(
              JS('', 'new #(#, #, #)', constr, arg0, arg1, arg2));

        case 4:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          var arg1 = _convertToJS(JS('', '#[1]', arguments));
          var arg2 = _convertToJS(JS('', '#[2]', arguments));
          var arg3 = _convertToJS(JS('', '#[3]', arguments));
          return _wrapToDart(
              JS('', 'new #(#, #, #, #)', constr, arg0, arg1, arg2, arg3));
      }
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
    var jsObj = JS('', 'new #()', factoryFunction);

    return _wrapToDart(jsObj);

    // TODO(sra): Investigate:
    //
    //     var jsObj = JS('', 'Object.create(#.prototype)', constr);
    //     JS('', '#.apply(#, #)', constr, jsObj,
    //         []..addAll(arguments.map(_convertToJS)));
    //     return _wrapToDart(jsObj);
  }

  /**
   * Constructs a [JsObject] that proxies a native Dart object; _for expert use
   * only_.
   *
   * Use this constructor only if you wish to get access to JavaScript
   * properties attached to a browser host object, such as a Node or Blob, that
   * is normally automatically converted into a native Dart object.
   *
   * An exception will be thrown if [object] either is `null` or has the type
   * `bool`, `num`, or `String`.
   */
  factory JsObject.fromBrowserObject(object) {
    if (object is num || object is String || object is bool || object == null) {
      throw new ArgumentError("object cannot be a num, string, bool, or null");
    }
    return _wrapToDart(_convertToJS(object));
  }

  /**
   * Recursively converts a JSON-like collection of Dart objects to a
   * collection of JavaScript objects and returns a [JsObject] proxy to it.
   *
   * [object] must be a [Map] or [Iterable], the contents of which are also
   * converted. Maps and Iterables are copied to a new JavaScript object.
   * Primitives and other transferrable values are directly converted to their
   * JavaScript type, and all other objects are proxied.
   */
  factory JsObject.jsify(object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw new ArgumentError("object must be a Map or Iterable");
    }
    return _wrapToDart(_convertDataTree(object));
  }

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
   * Returns the value associated with [property] from the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  dynamic operator [](property) {
    if (property is! String && property is! num) {
      throw new ArgumentError("property is not a String or num");
    }
    return _convertToDart(JS('', '#[#]', _jsObject, property));
  }

  /**
   * Sets the value associated with [property] on the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator []=(property, value) {
    if (property is! String && property is! num) {
      throw new ArgumentError("property is not a String or num");
    }
    JS('', '#[#]=#', _jsObject, property, _convertToJS(value));
  }

  int get hashCode => 0;

  bool operator ==(other) =>
      other is JsObject && JS('bool', '# === #', _jsObject, other._jsObject);

  /**
   * Returns `true` if the JavaScript object contains the specified property
   * either directly or though its prototype chain.
   *
   * This is the equivalent of the `in` operator in JavaScript.
   */
  bool hasProperty(property) {
    if (property is! String && property is! num) {
      throw new ArgumentError("property is not a String or num");
    }
    return JS('bool', '# in #', property, _jsObject);
  }

  /**
   * Removes [property] from the JavaScript object.
   *
   * This is the equivalent of the `delete` operator in JavaScript.
   */
  void deleteProperty(property) {
    if (property is! String && property is! num) {
      throw new ArgumentError("property is not a String or num");
    }
    JS('bool', 'delete #[#]', _jsObject, property);
  }

  /**
   * Returns `true` if the JavaScript object has [type] in its prototype chain.
   *
   * This is the equivalent of the `instanceof` operator in JavaScript.
   */
  bool instanceof(JsFunction type) {
    return JS('bool', '# instanceof #', _jsObject, _convertToJS(type));
  }

  /**
   * Returns the result of the JavaScript objects `toString` method.
   */
  String toString() {
    try {
      return JS('String', 'String(#)', _jsObject);
    } catch (e) {
      return super.toString();
    }
  }

  /**
   * Calls [method] on the JavaScript object with the arguments [args] and
   * returns the result.
   *
   * The type of [method] must be either [String] or [num].
   */
  dynamic callMethod(method, [List args]) {
    if (method is! String && method is! num) {
      throw new ArgumentError("method is not a String or num");
    }
    return _convertToDart(JS(
        '',
        '#[#].apply(#, #)',
        _jsObject,
        method,
        _jsObject,
        args == null ? null : new List.from(args.map(_convertToJS))));
  }
}

/**
 * Proxies a JavaScript Function object.
 */
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

  /**
   * Invokes the JavaScript function with arguments [args]. If [thisArg] is
   * supplied it is the value of `this` for the invocation.
   */
  dynamic apply(List args, {thisArg}) => _convertToDart(JS(
      '',
      '#.apply(#, #)',
      _jsObject,
      _convertToJS(thisArg),
      args == null ? null : new List.from(args.map(_convertToJS))));
}

/**
 * A [List] that proxies a JavaScript array.
 */
class JsArray<E> extends JsObject with ListMixin<E> {
  /**
   * Creates a new JavaScript array.
   */
  JsArray() : super._fromJs([]);

  /**
   * Creates a new JavaScript array and initializes it to the contents of
   * [other].
   */
  JsArray.from(Iterable<E> other)
      : super._fromJs([]..addAll(other.map(_convertToJS)));

  JsArray._fromJs(jsObject) : super._fromJs(jsObject);

  _checkIndex(int index) {
    if (index is int && (index < 0 || index >= length)) {
      throw new RangeError.range(index, 0, length);
    }
  }

  _checkInsertIndex(int index) {
    if (index is int && (index < 0 || index >= length + 1)) {
      throw new RangeError.range(index, 0, length);
    }
  }

  static _checkRange(int start, int end, int length) {
    if (start < 0 || start > length) {
      throw new RangeError.range(start, 0, length);
    }
    if (end < start || end > length) {
      throw new RangeError.range(end, start, length);
    }
  }

  // Methods required by ListMixin

  E operator [](index) {
    // TODO(justinfagnani): fix the semantics for non-ints
    // dartbug.com/14605
    if (index is num && index == index.toInt()) {
      _checkIndex(index);
    }
    return super[index];
  }

  void operator []=(index, E value) {
    // TODO(justinfagnani): fix the semantics for non-ints
    // dartbug.com/14605
    if (index is num && index == index.toInt()) {
      _checkIndex(index);
    }
    super[index] = value;
  }

  int get length {
    // Check the length honours the List contract.
    var len = JS('', '#.length', _jsObject);
    // JavaScript arrays have lengths which are unsigned 32-bit integers.
    if (JS('bool', 'typeof # === "number" && (# >>> 0) === #', len, len, len)) {
      return JS('int', '#', len);
    }
    throw new StateError('Bad JsArray length');
  }

  void set length(int length) {
    super['length'] = length;
  }

  // Methods overridden for better performance

  void add(E value) {
    callMethod('push', [value]);
  }

  void addAll(Iterable<E> iterable) {
    var list = (JS('bool', '# instanceof Array', iterable))
        ? iterable
        : new List.from(iterable);
    callMethod('push', list);
  }

  void insert(int index, E element) {
    _checkInsertIndex(index);
    callMethod('splice', [index, 0, element]);
  }

  E removeAt(int index) {
    _checkIndex(index);
    return callMethod('splice', [index, 1])[0];
  }

  E removeLast() {
    if (length == 0) throw new RangeError(-1);
    return callMethod('pop');
  }

  void removeRange(int start, int end) {
    _checkRange(start, end, length);
    callMethod('splice', [start, end - start]);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _checkRange(start, end, length);
    length = end - start;
    if (length == 0) return;
    if (skipCount < 0) throw new ArgumentError(skipCount);
    var args = [start, length]..addAll(iterable.skip(skipCount).take(length));
    callMethod('splice', args);
  }

  void sort([int compare(E a, E b)]) {
    // Note: arr.sort(null) is a type error in FF
    callMethod('sort', compare == null ? [] : [compare]);
  }
}

// property added to a Dart object referencing its JS-side DartObject proxy
final String _DART_OBJECT_PROPERTY_NAME =
    getIsolateAffinityTag(r'_$dart_dartObject');

// property added to a JS object referencing its Dart-side JsObject proxy
const _JS_OBJECT_PROPERTY_NAME = r'_$dart_jsObject';
const _JS_FUNCTION_PROPERTY_NAME = r'$dart_jsFunction';
const _JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS = r'_$dart_jsFunctionCaptureThis';

bool _defineProperty(o, String name, value) {
  try {
    if (_isExtensible(o) &&
        // TODO(ahe): Calling _hasOwnProperty to work around
        // https://code.google.com/p/dart/issues/detail?id=21331.
        !_hasOwnProperty(o, name)) {
      JS('void', 'Object.defineProperty(#, #, { value: #})', o, name, value);
      return true;
    }
  } catch (e) {
    // object is native and lies about being extensible
    // see https://bugzilla.mozilla.org/show_bug.cgi?id=775185
    // Or, isExtensible throws for this object.
  }
  return false;
}

bool _hasOwnProperty(o, String name) {
  return JS('bool', 'Object.prototype.hasOwnProperty.call(#, #)', o, name);
}

bool _isExtensible(o) => JS('bool', 'Object.isExtensible(#)', o);

Object _getOwnProperty(o, String name) {
  if (_hasOwnProperty(o, name)) {
    return JS('', '#[#]', o, name);
  }
  return null;
}

bool _isLocalObject(o) => JS('bool', '# instanceof Object', o);

// The shared constructor function for proxies to Dart objects in JavaScript.
final _dartProxyCtor = JS('', 'function DartObject(o) { this.o = o; }');

dynamic _convertToJS(dynamic o) {
  // Note: we don't write `if (o == null) return null;` to make sure dart2js
  // doesn't convert `return null;` into `return;` (which would make `null` be
  // `undefined` in Javascprit). See dartbug.com/20305 for details.
  if (o == null || o is String || o is num || o is bool) {
    return o;
  }
  if (o is JsObject) {
    return o._jsObject;
  }
  if (o is Blob ||
      o is Event ||
      o is KeyRange ||
      o is ImageData ||
      o is Node ||
      o is TypedData ||
      o is Window) {
    return o;
  }
  if (o is DateTime) {
    return Primitives.lazyAsJsDate(o);
  }
  if (o is Function) {
    return _getJsProxy(o, _JS_FUNCTION_PROPERTY_NAME, (o) {
      var jsFunction = _convertDartFunction(o);
      // set a property on the JS closure referencing the Dart closure
      _defineProperty(jsFunction, DART_CLOSURE_PROPERTY_NAME, o);
      return jsFunction;
    });
  }
  var ctor = _dartProxyCtor;
  return _getJsProxy(
      o, _JS_OBJECT_PROPERTY_NAME, (o) => JS('', 'new #(#)', ctor, o));
}

Object _getJsProxy(o, String propertyName, createProxy(o)) {
  var jsProxy = _getOwnProperty(o, propertyName);
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
  } else if (_isLocalObject(o) &&
      (o is Blob ||
          o is Event ||
          o is KeyRange ||
          o is ImageData ||
          o is Node ||
          o is TypedData ||
          o is Window)) {
    // long line: dart2js doesn't allow string concatenation in the JS() form
    return JS('Blob|Event|KeyRange|ImageData|Node|TypedData|Window', '#', o);
  } else if (JS('bool', '# instanceof Date', o)) {
    var ms = JS('num', '#.getTime()', o);
    return new DateTime.fromMillisecondsSinceEpoch(ms);
  } else if (JS('bool', '#.constructor === #', o, _dartProxyCtor)) {
    return JS('', '#.o', o);
  } else {
    return _wrapToDart(o);
  }
}

Object _wrapToDart(o) {
  if (JS('bool', 'typeof # == "function"', o)) {
    return _getDartProxy(
        o, DART_CLOSURE_PROPERTY_NAME, (o) => new JsFunction._fromJs(o));
  }
  if (JS('bool', '# instanceof Array', o)) {
    return _getDartProxy(
        o, _DART_OBJECT_PROPERTY_NAME, (o) => new JsArray._fromJs(o));
  }
  return _getDartProxy(
      o, _DART_OBJECT_PROPERTY_NAME, (o) => new JsObject._fromJs(o));
}

Object _getDartProxy(o, String propertyName, createProxy(o)) {
  var dartProxy = _getOwnProperty(o, propertyName);
  // Temporary fix for dartbug.com/15193
  // In some cases it's possible to see a JavaScript object that
  // came from a different context and was previously proxied to
  // Dart in that context. The JS object will have a cached proxy
  // but it won't be a valid Dart object in this context.
  // For now we throw away the cached proxy, but we should be able
  // to cache proxies from multiple JS contexts and Dart isolates.
  if (dartProxy == null || !_isLocalObject(o)) {
    dartProxy = createProxy(o);
    _defineProperty(o, propertyName, dartProxy);
  }
  return dartProxy;
}

// ---------------------------------------------------------------------------
// Start of methods for new style Dart-JS interop.

_convertDartFunctionFast(Function f) {
  var existing = JS('', '#.#', f, _JS_FUNCTION_PROPERTY_NAME);
  if (existing != null) return existing;
  var ret = JS(
      '',
      '''
        function(_call, f) {
          return function() {
            return _call(f, Array.prototype.slice.apply(arguments));
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast),
      f);
  JS('', '#.# = #', ret, DART_CLOSURE_PROPERTY_NAME, f);
  JS('', '#.# = #', f, _JS_FUNCTION_PROPERTY_NAME, ret);
  return ret;
}

_convertDartFunctionFastCaptureThis(Function f) {
  var existing = JS('', '#.#', f, _JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS);
  if (existing != null) return existing;
  var ret = JS(
      '',
      '''
        function(_call, f) {
          return function() {
            return _call(f, this,Array.prototype.slice.apply(arguments));
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFastCaptureThis),
      f);
  JS('', '#.# = #', ret, DART_CLOSURE_PROPERTY_NAME, f);
  JS('', '#.# = #', f, _JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS, ret);
  return ret;
}

_callDartFunctionFast(callback, List arguments) {
  return Function.apply(callback, arguments);
}

_callDartFunctionFastCaptureThis(callback, self, List arguments) {
  return Function.apply(callback, [self]..addAll(arguments));
}

Function/*=F*/ allowInterop/*<F extends Function>*/(Function/*=F*/ f) {
  if (JS('bool', 'typeof(#) == "function"', f)) {
    // Already supports interop, just use the existing function.
    return f;
  } else {
    return _convertDartFunctionFast(f);
  }
}

Function allowInteropCaptureThis(Function f) {
  if (JS('bool', 'typeof(#) == "function"', f)) {
    // Behavior when the function is already a JS function is unspecified.
    throw new ArgumentError(
        "Function is already a JS function so cannot capture this.");
    return f;
  } else {
    return _convertDartFunctionFastCaptureThis(f);
  }
}
