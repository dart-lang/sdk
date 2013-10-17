// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js;

import 'dart:_foreign_helper' show JS, DART_CLOSURE_TO_JS;
import 'dart:_js_helper' show Primitives, convertDartClosureToJS;

final JsObject context = new JsObject._fromJs(Primitives.computeGlobalThis());

JsObject jsify(dynamic data) => data == null ? null : new JsObject._json(data);

class Callback implements Serializable<JsFunction> {
  final Function _f; // here to allow capture in closure
  final bool _withThis; // here to allow capture in closure
  dynamic _jsFunction;

  Callback._(this._f, this._withThis) {
    _jsFunction = JS('', r'''
(function(){
  var f = #;
  return function(){
    return f(this, Array.prototype.slice.apply(arguments));
  };
}).apply(this)''', convertDartClosureToJS(_call, 2));
  }

  factory Callback(Function f) => new Callback._(f, false);
  factory Callback.withThis(Function f) => new Callback._(f, true);

  _call(thisArg, List args) {
    final arguments = new List.from(args);
    if (_withThis) arguments.insert(0, thisArg);
    final dartArgs = arguments.map(_convertToDart).toList();
    return _convertToJS(Function.apply(_f, dartArgs));
  }

  JsFunction toJs() => new JsFunction._fromJs(_jsFunction);
}

/*
 * TODO(justinfagnani): add tests and make public when we remove Callback.
 *
 * Returns a [JsFunction] that captures its 'this' binding and calls [f]
 * with the value of this passed as the first argument.
 */
JsFunction _captureThis(Function f) => 
  new JsFunction._fromJs(_convertDartFunction(f, captureThis: true));

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


class JsObject implements Serializable<JsObject> {
  // The wrapped JS object.
  final dynamic _jsObject;

  JsObject._fromJs(this._jsObject) {
    // Remember this proxy for the JS object
    _getDartProxy(_jsObject, _DART_OBJECT_PROPERTY_NAME, (o) => this);
  }

  // TODO(vsm): Type constructor as Serializable<JsFunction> when
  // dartbug.com/11854 is fixed.
  factory JsObject(constructor, [List arguments]) {
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
    return new JsObject._fromJs(JS('', 'new #()', factoryFunction));
  }

  factory JsObject._json(data) => new JsObject._fromJs(_convertDataTree(data));

  static _convertDataTree(data) {
    if (data is Map) {
      final convertedData = JS('=Object', '{}');
      for (var key in data.keys) {
        JS('=Object', '#[#]=#', convertedData, key,
            _convertDataTree(data[key]));
      }
      return convertedData;
    } else if (data is Iterable) {
      return data.map(_convertDataTree).toList();
    } else {
      return _convertToJS(data);
    }
  }

  JsObject toJs() => this;

  /**
   * Returns the value associated with [key] from the proxied JavaScript
   * object.
   *
   * [key] must either be a [String] or [int].
   */
  // TODO(justinfagnani): rename key/name to property
  dynamic operator[](key) {
    if (key is! String && key is! int) {
      throw new ArgumentError("key is not a String or int");
    }
    return _convertToDart(JS('', '#[#]', _jsObject, key));
  }
  
  /**
   * Sets the value associated with [key] from the proxied JavaScript
   * object.
   *
   * [key] must either be a [String] or [int].
   */
  operator[]=(key, value) {
    if (key is! String && key is! int) {
      throw new ArgumentError("key is not a String or int");
    }
    JS('', '#[#]=#', _jsObject, key, _convertToJS(value));
  }

  int get hashCode => 0;

  bool operator==(other) => other is JsObject &&
      JS('bool', '# === #', _jsObject, other._jsObject);

  bool hasProperty(name) {
    if (name is! String && name is! int) {
      throw new ArgumentError("name is not a String or int");
    }
    return JS('bool', '# in #', name, _jsObject);
  }

  void deleteProperty(name) {
    if (name is! String && name is! int) {
      throw new ArgumentError("name is not a String or int");
    }
    JS('bool', 'delete #[#]', _jsObject, name);
  }

  // TODO(vsm): Type type as Serializable<JsFunction> when
  // dartbug.com/11854 is fixed.
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
    if (name is! String && name is! int) {
      throw new ArgumentError("name is not a String or int");
    }
    return _convertToDart(JS('', '#[#].apply(#, #)', _jsObject, name,
        _jsObject,
        args == null ? null : args.map(_convertToJS).toList()));
  }
}

class JsFunction extends JsObject implements Serializable<JsFunction> {

  JsFunction._fromJs(jsObject) : super._fromJs(jsObject);

  dynamic apply(thisArg, [List args]) =>
      _convertToDart(JS('', '#.apply(#, #)', _jsObject,
          _convertToJS(thisArg),
          args == null ? null : args.map(_convertToJS).toList()));
}

abstract class Serializable<T> {
  T toJs();
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
  } else if (o is String || o is num || o is bool) {
    return o;
  } else if (o is JsObject) {
    return o._jsObject;
  } else if (o is Serializable) {
    return _convertToJS(o.toJs());
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
