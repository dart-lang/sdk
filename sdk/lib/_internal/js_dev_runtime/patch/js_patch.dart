// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:js library.
library dart.js;

import 'dart:collection' show HashMap, ListMixin;

import 'dart:_js_helper' show patch, NoReifyGeneric, Primitives;
import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

@patch
JsObject get context => _context;

final JsObject _context = _wrapToDart(dart.global_);

@patch
class JsObject {
  // The wrapped JS object.
  final Object _jsObject;

  // This should only be called from _wrapToDart
  JsObject._fromJs(this._jsObject) {
    assert(_jsObject != null);
  }

  @patch
  factory JsObject(JsFunction constructor, [List? arguments]) {
    var ctor = constructor._jsObject;
    if (arguments == null) {
      return _wrapToDart(JS('', 'new #()', ctor));
    }
    var unwrapped = List.from(arguments.map(_convertToJS));
    return _wrapToDart(JS('', 'new #(...#)', ctor, unwrapped));
  }

  @patch
  factory JsObject.fromBrowserObject(Object object) {
    if (object is num || object is String || object is bool || object == null) {
      throw ArgumentError("object cannot be a num, string, bool, or null");
    }
    return _wrapToDart(_convertToJS(object)!);
  }

  @patch
  factory JsObject.jsify(Object object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw ArgumentError("object must be a Map or Iterable");
    }
    return _wrapToDart(_convertDataTree(object));
  }

  static _convertDataTree(Object data) {
    var _convertedObjects = HashMap.identity();

    _convert(Object? o) {
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

  @patch
  dynamic operator [](Object property) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    return _convertToDart(JS('', '#[#]', _jsObject, property));
  }

  @patch
  void operator []=(Object property, Object? value) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    JS('', '#[#] = #', _jsObject, property, _convertToJS(value));
  }

  @patch
  bool operator ==(Object other) =>
      other is JsObject && JS<bool>('!', '# === #', _jsObject, other._jsObject);

  @patch
  bool hasProperty(Object property) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    return JS<bool>('!', '# in #', property, _jsObject);
  }

  @patch
  void deleteProperty(Object property) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    JS<bool>('!', 'delete #[#]', _jsObject, property);
  }

  @patch
  bool instanceof(JsFunction type) {
    return JS<bool>('!', '# instanceof #', _jsObject, _convertToJS(type));
  }

  @patch
  String toString() {
    try {
      return JS<String>('!', 'String(#)', _jsObject);
    } catch (e) {
      return super.toString();
    }
  }

  @patch
  dynamic callMethod(Object method, [List? args]) {
    if (method is! String && method is! num) {
      throw ArgumentError("method is not a String or num");
    }
    if (args != null) args = List.from(args.map(_convertToJS));
    var fn = JS('', '#[#]', _jsObject, method);
    if (JS<bool>('!', 'typeof(#) !== "function"', fn)) {
      throw NoSuchMethodError(_jsObject, Symbol('$method'), args, {});
    }
    return _convertToDart(JS('', '#.apply(#, #)', fn, _jsObject, args));
  }
}

@patch
class JsFunction extends JsObject {
  @patch
  factory JsFunction.withThis(Function f) {
    return JsFunction._fromJs(JS(
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

  JsFunction._fromJs(Object jsObject) : super._fromJs(jsObject);

  @patch
  dynamic apply(List args, {thisArg}) => _convertToDart(JS(
      '',
      '#.apply(#, #)',
      _jsObject,
      _convertToJS(thisArg),
      args == null ? null : List.from(args.map(_convertToJS))));
}

// TODO(jmesserly): this is totally unnecessary in dev_compiler.
@patch
class JsArray<E> extends JsObject with ListMixin<E> {
  @patch
  factory JsArray() => JsArray<E>._fromJs([]);

  @patch
  factory JsArray.from(Iterable<E> other) =>
      JsArray<E>._fromJs([]..addAll(other.map(_convertToJS)));

  JsArray._fromJs(Object jsObject) : super._fromJs(jsObject);

  _checkIndex(int index) {
    if (index < 0 || index >= length) {
      throw RangeError.range(index, 0, length);
    }
  }

  _checkInsertIndex(int index) {
    if (index < 0 || index >= length + 1) {
      throw RangeError.range(index, 0, length);
    }
  }

  static _checkRange(int start, int end, int length) {
    if (start < 0 || start > length) {
      throw RangeError.range(start, 0, length);
    }
    if (end < start || end > length) {
      throw RangeError.range(end, start, length);
    }
  }

  @patch
  E operator [](Object index) {
    if (index is int) {
      _checkIndex(index);
    }
    return super[index] as E;
  }

  @patch
  void operator []=(Object index, value) {
    if (index is int) {
      _checkIndex(index);
    }
    super[index] = value;
  }

  @patch
  int get length {
    // Check the length honours the List contract.
    var len = JS('', '#.length', _jsObject);
    // JavaScript arrays have lengths which are unsigned 32-bit integers.
    if (JS<bool>(
        '!', 'typeof # === "number" && (# >>> 0) === #', len, len, len)) {
      return JS<int>('!', '#', len);
    }
    throw StateError('Bad JsArray length');
  }

  @patch
  void set length(int length) {
    super['length'] = length;
  }

  @patch
  void add(E value) {
    callMethod('push', [value]);
  }

  @patch
  void addAll(Iterable<E> iterable) {
    var list = (JS<bool>('!', '# instanceof Array', iterable))
        ? JS<List>('', '#', iterable)
        : List.from(iterable);
    callMethod('push', list);
  }

  @patch
  void insert(int index, E element) {
    _checkInsertIndex(index);
    callMethod('splice', [index, 0, element]);
  }

  @patch
  E removeAt(int index) {
    _checkIndex(index);
    return callMethod('splice', [index, 1])[0] as E;
  }

  @patch
  E removeLast() {
    if (length == 0) throw RangeError(-1);
    return callMethod('pop') as E;
  }

  @patch
  void removeRange(int start, int end) {
    _checkRange(start, end, length);
    callMethod('splice', [start, end - start]);
  }

  @patch
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _checkRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    if (skipCount < 0) throw ArgumentError(skipCount);
    var args = <Object?>[start, length]
      ..addAll(iterable.skip(skipCount).take(length));
    callMethod('splice', args);
  }

  @patch
  void sort([int compare(E a, E b)?]) {
    // Note: arr.sort(null) is a type error in FF
    callMethod('sort', compare == null ? [] : [compare]);
  }
}

// Cross frame objects should not be considered browser types.
// We include the instanceof Object test to filter out cross frame objects
// on FireFox. Surprisingly on FireFox the instanceof Window test succeeds for
// cross frame windows while the instanceof Object test fails.
bool _isBrowserType(Object o) => JS(
    'bool',
    '# instanceof Object && ('
        '# instanceof Blob || '
        '# instanceof Event || '
        '(window.KeyRange && # instanceof KeyRange) || '
        '(window.IDBKeyRange && # instanceof IDBKeyRange) || '
        '# instanceof ImageData || '
        '# instanceof Node || '
        '(window.DataView && # instanceof DataView) || '
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
    o,
    o);

class _DartObject {
  final Object _dartObj;
  _DartObject(this._dartObj);
}

Object? _convertToJS(Object? o) {
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
    return _putIfAbsent(_jsProxies, o, (o) => _DartObject(o));
  }
}

Object _wrapDartFunction(Object f) {
  var wrapper = JS<Object>(
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
Object? _convertToDart(Object? o) {
  if (o == null || o is String || o is num || o is bool || _isBrowserType(o)) {
    return o;
  } else if (JS('!', '# instanceof Date', o)) {
    int ms = JS('!', '#.getTime()', o);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  } else if (o is _DartObject &&
      !identical(dart.getReifiedType(o), dart.jsobject)) {
    return o._dartObj;
  } else {
    return _wrapToDart(o);
  }
}

JsObject _wrapToDart(Object o) =>
    _putIfAbsent(_dartProxies, o, _wrapToDartHelper);

JsObject _wrapToDartHelper(Object o) {
  if (JS<bool>('!', 'typeof # == "function"', o)) {
    return JsFunction._fromJs(o);
  }
  if (JS<bool>('!', '# instanceof Array', o)) {
    return JsArray._fromJs(o);
  }
  return JsObject._fromJs(o);
}

final Object _dartProxies = JS('', 'new WeakMap()');
final Object _jsProxies = JS('', 'new WeakMap()');

@NoReifyGeneric()
T _putIfAbsent<T>(Object weakMap, Object o, T getValue(Object o)) {
  T? value = JS('', '#.get(#)', weakMap, o);
  if (value == null) {
    value = getValue(o);
    JS('', '#.set(#, #)', weakMap, o, value);
  }
  // TODO(vsm): Static cast.  Unnecessary?
  return JS('', '#', value);
}

Expando<Function> _interopExpando = Expando<Function>();

@patch
F allowInterop<F extends Function>(F f) {
  if (!dart.isDartFunction(f)) return f;
  var ret = _interopExpando[f] as F?;
  if (ret == null) {
    ret = JS<F>(
        '',
        'function (...args) {'
            ' return #(#, args);'
            '}',
        dart.dcall,
        f);
    _interopExpando[f] = ret;
  }
  return ret;
}

Expando<Function> _interopCaptureThisExpando = Expando<Function>();

@patch
Function allowInteropCaptureThis(Function f) {
  if (!dart.isDartFunction(f)) return f;
  var ret = _interopCaptureThisExpando[f];
  if (ret == null) {
    ret = JS<Function>(
        '',
        'function(...arguments) {'
            '  let args = [this];'
            '  args.push.apply(args, arguments);'
            '  return #(#, args);'
            '}',
        dart.dcall,
        f);
    _interopCaptureThisExpando[f] = ret;
  }
  return ret;
}
