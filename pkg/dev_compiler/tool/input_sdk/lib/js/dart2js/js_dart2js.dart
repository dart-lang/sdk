// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
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

import 'dart:collection' show HashMap, ListMixin;

import 'dart:_interceptors' as _interceptors show JSArray;
import 'dart:_js_helper' show Primitives;
import 'dart:_foreign_helper' show JS;

final _global = JS('', 'dart.global');
final JsObject context = _wrapToDart(_global);

/**
 * Proxies a JavaScript object to Dart.
 *
 * The properties of the JavaScript object are accessible via the `[]` and
 * `[]=` operators. Methods are callable via [callMethod].
 */
class JsObject {
  // The wrapped JS object.
  final dynamic _jsObject;

  // This should only be called from _wrapToDart
  JsObject._fromJs(this._jsObject) {
    assert(_jsObject != null);
  }

  /**
   * Constructs a new JavaScript object from [constructor] and returns a proxy
   * to it.
   */
  factory JsObject(JsFunction constructor, [List arguments]) {
    var ctor = constructor._jsObject;
    if (arguments == null) {
      return _wrapToDart(JS('', 'new #()', ctor));
    }
    var unwrapped = new List.from(arguments.map(_convertToJS));
    return _wrapToDart(JS('', 'new #(...#)', ctor, unwrapped));
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
   * Primitives and other transferable values are directly converted to their
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
        final convertedMap = JS('', '{}');
        _convertedObjects[o] = convertedMap;
        for (var key in o.keys) {
          JS('', '#[#] = #', convertedMap, key, _convert(o[key]));
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
  dynamic operator [](Object property) {
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
  void operator []=(Object property, value) {
    if (property is! String && property is! num) {
      throw new ArgumentError("property is not a String or num");
    }
    JS('', '#[#] = #', _jsObject, property, _convertToJS(value));
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
    if (args != null) args = new List.from(args.map(_convertToJS));
    var fn = JS('', '#[#]', _jsObject, method);
    if (JS('bool', 'typeof(#) !== "function"', fn)) {
      throw new NoSuchMethodError(_jsObject, new Symbol(method), args, {});
    }
    return _convertToDart(JS('', '#.apply(#, #)', fn, _jsObject, args));
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
    return new JsFunction._fromJs(JS(
        '',
        'function(/*...arguments*/) {'
        '  let args = [#(this)];'
        '  for (let arg of arguments) {'
        '    args.push(#(arg));'
        '  }'
        '  return #(#(...args));'
        '}',
        _convertToDart,
        _convertToDart,
        _convertToJS,
        f));
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

// TODO(jmesserly): this is totally unnecessary in dev_compiler.
/** A [List] that proxies a JavaScript array. */
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

  E operator [](Object index) {
    // TODO(justinfagnani): fix the semantics for non-ints
    // dartbug.com/14605
    if (index is num && index == index.toInt()) {
      _checkIndex(index);
    }
    return super[index] as E;
  }

  void operator []=(Object index, value) {
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
    return callMethod('splice', [index, 1])[0] as E;
  }

  E removeLast() {
    if (length == 0) throw new RangeError(-1);
    return callMethod('pop') as E;
  }

  void removeRange(int start, int end) {
    _checkRange(start, end, length);
    callMethod('splice', [start, end - start]);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _checkRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    if (skipCount < 0) throw new ArgumentError(skipCount);
    var args = <Object>[start, length]
      ..addAll(iterable.skip(skipCount).take(length));
    callMethod('splice', args);
  }

  void sort([int compare(E a, E b)]) {
    // Note: arr.sort(null) is a type error in FF
    callMethod('sort', compare == null ? [] : [compare]);
  }
}

// Cross frame objects should not be considered browser types.
// We include the instanceof Object test to filter out cross frame objects
// on FireFox. Surprisingly on FireFox the instanceof Window test succeeds for
// cross frame windows while the instanceof Object test fails.
bool _isBrowserType(o) => JS(
    'bool',
    '# instanceof Object && ('
    '# instanceof Blob || '
    '# instanceof Event || '
    '(window.KeyRange && # instanceof KeyRange) || '
    '(window.IDBKeyRange && # instanceof IDBKeyRange) || '
    '# instanceof ImageData || '
    '# instanceof Node || '
    // Int8Array.__proto__ is TypedArray.
    '(window.Int8Array && # instanceof Int8Array.__proto__) || '
    '# instanceof Window)',
    o,
    o,
    o,
    o,
    o,
    o,
    o,
    o,
    o);

class _DartObject {
  final _dartObj;
  _DartObject(this._dartObj);
}

dynamic _convertToJS(dynamic o) {
  if (o == null || o is String || o is num || o is bool || _isBrowserType(o)) {
    return o;
  } else if (o is DateTime) {
    return Primitives.lazyAsJsDate(o);
  } else if (o is JsObject) {
    return o._jsObject;
  } else if (o is Function) {
    return _putIfAbsent(_jsProxies, o, _wrapDartFunction);
  } else {
    // TODO(jmesserly): for now, we wrap other objects, to keep compatibility
    // with the original dart:js behavior.
    return _putIfAbsent(_jsProxies, o, (o) => new _DartObject(o));
  }
}

dynamic _wrapDartFunction(f) {
  var wrapper = JS(
      '',
      'function(/*...arguments*/) {'
      '  let args = Array.prototype.map.call(arguments, #);'
      '  return #(#(...args));'
      '}',
      _convertToDart,
      _convertToJS,
      f);
  JS('', '#.set(#, #)', _dartProxies, wrapper, f);

  return wrapper;
}

// converts a Dart object to a reference to a native JS object
// which might be a DartObject JS->Dart proxy
Object _convertToDart(o) {
  if (JS('bool', '# == null', o) ||
      JS('bool', 'typeof # == "string"', o) ||
      JS('bool', 'typeof # == "number"', o) ||
      JS('bool', 'typeof # == "boolean"', o) ||
      _isBrowserType(o)) {
    return o;
  } else if (JS('bool', '# instanceof Date', o)) {
    var ms = JS('num', '#.getTime()', o);
    return new DateTime.fromMillisecondsSinceEpoch(ms);
  } else if (o is _DartObject &&
      JS('bool', 'dart.jsobject != dart.getReifiedType(#)', o)) {
    return o._dartObj;
  } else {
    return _wrapToDart(o);
  }
}

Object _wrapToDart(o) => _putIfAbsent(_dartProxies, o, _wrapToDartHelper);

Object _wrapToDartHelper(o) {
  if (JS('bool', 'typeof # == "function"', o)) {
    return new JsFunction._fromJs(o);
  }
  if (JS('bool', '# instanceof Array', o)) {
    return new JsArray._fromJs(o);
  }
  return new JsObject._fromJs(o);
}

final _dartProxies = JS('', 'new WeakMap()');
final _jsProxies = JS('', 'new WeakMap()');

Object _putIfAbsent(weakMap, o, getValue(o)) {
  var value = JS('', '#.get(#)', weakMap, o);
  if (value == null) {
    value = getValue(o);
    JS('', '#.set(#, #)', weakMap, o, value);
  }
  return value;
}

// The allowInterop method is a no-op in Dart Dev Compiler.
// TODO(jacobr): tag methods so we can throw if a Dart method is passed to
// JavaScript using the new interop without calling allowInterop.

/// Returns a wrapper around function [f] that can be called from JavaScript
/// using the package:js Dart-JavaScript interop.
///
/// For performance reasons in Dart2Js, by default Dart functions cannot be
/// passed directly to JavaScript unless this method is called to create
/// a Function compatible with both Dart and JavaScript.
/// Calling this method repeatedly on a function will return the same function.
/// The [Function] returned by this method can be used from both Dart and
/// JavaScript. We may remove the need to call this method completely in the
/// future if Dart2Js is refactored so that its function calling conventions
/// are more compatible with JavaScript.
Function/*=F*/ allowInterop/*<F extends Function>*/(Function/*=F*/ f) => f;

Expando<Function> _interopCaptureThisExpando = new Expando<Function>();

/// Returns a [Function] that when called from JavaScript captures its 'this'
/// binding and calls [f] with the value of this passed as the first argument.
/// When called from Dart, [null] will be passed as the first argument.
///
/// See the documentation for [allowInterop]. This method should only be used
/// with package:js Dart-JavaScript interop.
Function allowInteropCaptureThis(Function f) {
  var ret = _interopCaptureThisExpando[f];
  if (ret == null) {
    ret = JS(
        '',
        'function(/*...arguments*/) {'
        '  let args = [this];'
        '  for (let arg of arguments) {'
        '    args.push(arg);'
        '  }'
        '  return #(...args);'
        '}',
        f);
    _interopCaptureThisExpando[f] = ret;
  }
  return ret;
}
