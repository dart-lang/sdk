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
    _jsFunction = JS('=Object', r'''
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
  final dynamic _jsObject;

  JsObject._fromJs(this._jsObject) {
    // remember this proxy for the JS object
    _getDartProxy(_jsObject, _DART_OBJECT_PROPERTY_NAME, (o) => this);
  }

  // TODO(vsm): Type constructor as Serializable<JsFunction> when
  // dartbug.com/11854 is fixed.
  factory JsObject(var constructor, [List arguments]) {
    final constr = _convertToJS(constructor);
    if (arguments == null) {
      return new JsObject._fromJs(JS('=Object', 'new #()', constr));
    }
    final args = arguments.map(_convertToJS).toList();
    switch (args.length) {
      case 0:
        return new JsObject._fromJs(JS('=Object', 'new #()', constr));
      case 1:
        return new JsObject._fromJs(JS('=Object', 'new #(#)', constr, args[0]));
      case 2:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#)', constr, args[0],
            args[1]));
      case 3:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#)', constr,
            args[0], args[1], args[2]));
      case 4:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#)', constr,
            args[0], args[1], args[2], args[3]));
      case 5:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#,#)', constr,
            args[0], args[1], args[2], args[3], args[4]));
      case 6:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#,#,#)', constr,
            args[0], args[1], args[2], args[3], args[4], args[5]));
      case 7:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#,#,#,#)',
            constr, args[0], args[1], args[2], args[3], args[4], args[5],
            args[6]));
      case 8:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#,#,#,#,#)',
            constr, args[0], args[1], args[2], args[3], args[4], args[5],
            args[6], args[7]));
      case 9:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#,#,#,#,#,#)',
            constr, args[0], args[1], args[2], args[3], args[4], args[5],
            args[6], args[7], args[8]));
      case 10:
        return new JsObject._fromJs(JS('=Object', 'new #(#,#,#,#,#,#,#,#,#,#)',
            constr, args[0], args[1], args[2], args[3], args[4], args[5],
            args[6], args[7], args[8], args[9]));
    }
    return new JsObject._fromJs(JS('=Object', r'''(function(){
var Type = function(){};
Type.prototype = #.prototype;
var instance = new Type();
ret = #.apply(instance, #);
ret = Object(ret) === ret ? ret : instance;
return ret;
})()''', constr, constr, args));
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

  operator[](key) =>
      _convertToDart(JS('=Object', '#[#]', _convertToJS(this), key));

  operator[]=(key, value) => JS('void', '#[#]=#', _convertToJS(this), key,
      _convertToJS(value));

  int get hashCode => 0;

  operator==(other) => other is JsObject &&
      JS('bool', '# === #', _convertToJS(this), _convertToJS(other));

  bool hasProperty(String property) => JS('bool', '# in #', property,
      _convertToJS(this));

  void deleteProperty(String name) {
    JS('void', 'delete #[#]', _convertToJS(this), name);
  }

  // TODO(vsm): Type type as Serializable<JsFunction> when
  // dartbug.com/11854 is fixed.
  bool instanceof(var type) =>
      JS('bool', '# instanceof #', _convertToJS(this), _convertToJS(type));

  String toString() {
    try {
      return JS('String', '#.toString()', _convertToJS(this));
    } catch(e) {
      return super.toString();
    }
  }

  callMethod(String name, [List args]) =>
      _convertToDart(JS('=Object', '#[#].apply(#, #)', _convertToJS(this), name,
          _convertToJS(this),
          args == null ? null : args.map(_convertToJS).toList()));
}

class JsFunction extends JsObject implements Serializable<JsFunction> {
  JsFunction._fromJs(jsObject) : super._fromJs(jsObject);
  apply(thisArg, [List args]) =>
      _convertToDart(JS('=Object', '#.apply(#, #)', _convertToJS(this),
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

_defineProperty(o, String name, value) =>
    JS('void', 'Object.defineProperty(#, #, { value: #})', o, name, value);

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

dynamic _getJsProxy(o, String propertyName, createProxy(o)) {
  var jsProxy = JS('', '#[#]', o, propertyName);
  if (jsProxy == null) {
    jsProxy = createProxy(o);
    _defineProperty(o, propertyName, jsProxy);
  }
  return jsProxy;
}

// converts a Dart object to a reference to a native JS object
// which might be a DartObject JS->Dart proxy
dynamic _convertToDart(dynamic o) {
  if (JS('bool', '# == null', o)) {
    return null;
  } else if (JS('bool', 'typeof # == "string" || # instanceof String', o, o) ||
      JS('bool', 'typeof # == "number" || # instanceof Number', o, o) ||
      JS('bool', 'typeof # == "boolean" || # instanceof Boolean', o, o)) {
    return o;
  } else if (JS('bool', '# instanceof Function', o)) {
    return _getDartProxy(o, _DART_CLOSURE_PROPERTY_NAME,
        (o) => new JsFunction._fromJs(o));
  } else if (JS('bool', '# instanceof DartObject', o)) {
    return JS('var', '#.o', o);
  } else {
    return _getDartProxy(o, _DART_OBJECT_PROPERTY_NAME,
        (o) => new JsObject._fromJs(o));
  }
}

dynamic _getDartProxy(o, String propertyName, createProxy(o)) {
  var dartProxy = JS('', '#[#]', o, propertyName);
  if (dartProxy == null) {
    dartProxy = createProxy(o);
    _defineProperty(o, propertyName, dartProxy);
  }
  return dartProxy;
}
