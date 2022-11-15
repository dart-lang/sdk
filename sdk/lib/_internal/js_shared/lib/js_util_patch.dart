// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:_js_helper'
    show convertDartClosureToJS, assertInterop, assertInteropArgs;
import 'dart:collection' show HashMap;
import 'dart:async' show Completer;
import 'dart:js_util';

@patch
dynamic jsify(Object object) {
  if ((object is! Map) && (object is! Iterable)) {
    throw ArgumentError("object must be a Map or Iterable");
  }
  return _convertDataTree(object);
}

Object _convertDataTree(Object data) {
  var _convertedObjects = HashMap.identity();

  Object? _convert(Object? o) {
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
      return o;
    }
  }

  return _convert(data)!;
}

@patch
@pragma('dart2js:tryInline')
Object get globalThis => JS('', 'globalThis');

@patch
T newObject<T>() => JS('=Object', '{}');

@patch
bool hasProperty(Object o, Object name) => JS('bool', '# in #', name, o);

@patch
T getProperty<T>(Object o, Object name) =>
    JS<dynamic>('Object|Null', '#[#]', o, name);

/// Similar to [getProperty] but introduces an unsound implicit cast to `T`.
T _getPropertyTrustType<T>(Object o, Object name) =>
    JS<T>('Object|Null', '#[#]', o, name);

@patch
T setProperty<T>(Object o, Object name, T? value) {
  assertInterop(value);
  return JS('', '#[#]=#', o, name, value);
}

/// Unchecked version of setProperty, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _setPropertyUnchecked<T>(Object o, Object name, T? value) {
  return JS('', '#[#]=#', o, name, value);
}

@patch
T callMethod<T>(Object o, String method, List<Object?> args) {
  assertInteropArgs(args);
  return JS<dynamic>('Object|Null', '#[#].apply(#, #)', o, method, o, args);
}

/// Similar to [callMethod] but introduces an unsound implicit cast to `T`.
T _callMethodTrustType<T>(Object o, String method, List<Object?> args) {
  assertInteropArgs(args);
  return JS<T>('Object|Null', '#[#].apply(#, #)', o, method, o, args);
}

/// Unchecked version for 0 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callMethodUnchecked0<T>(Object o, String method) {
  return JS<dynamic>('Object|Null', '#[#]()', o, method);
}

/// Similar to [_callMethodUnchecked] but introduces an unsound implicit cast
/// to `T`.
@pragma('dart2js:tryInline')
T _callMethodUncheckedTrustType0<T>(Object o, String method) {
  return JS<T>('Object|Null', '#[#]()', o, method);
}

/// Unchecked version for 1 argument, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callMethodUnchecked1<T>(Object o, String method, Object? arg1) {
  return JS<dynamic>('Object|Null', '#[#](#)', o, method, arg1);
}

/// Similar to [_callMethodUnchecked1] but introduces an unsound implicit cast
/// to `T`.
@pragma('dart2js:tryInline')
T _callMethodUncheckedTrustType1<T>(Object o, String method, Object? arg1) {
  return JS<T>('Object|Null', '#[#](#)', o, method, arg1);
}

/// Unchecked version for 2 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callMethodUnchecked2<T>(
    Object o, String method, Object? arg1, Object? arg2) {
  return JS<dynamic>('Object|Null', '#[#](#, #)', o, method, arg1, arg2);
}

/// Similar to [_callMethodUnchecked2] but introduces an unsound implicit cast
/// to `T`.
@pragma('dart2js:tryInline')
T _callMethodUncheckedTrustType2<T>(
    Object o, String method, Object? arg1, Object? arg2) {
  return JS<T>('Object|Null', '#[#](#, #)', o, method, arg1, arg2);
}

/// Unchecked version for 3 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callMethodUnchecked3<T>(
    Object o, String method, Object? arg1, Object? arg2, Object? arg3) {
  return JS<dynamic>(
      'Object|Null', '#[#](#, #, #)', o, method, arg1, arg2, arg3);
}

/// Similar to [_callMethodUnchecked3] but introduces an unsound implicit cast
/// to `T`.
@pragma('dart2js:tryInline')
T _callMethodUncheckedTrustType3<T>(
    Object o, String method, Object? arg1, Object? arg2, Object? arg3) {
  return JS<T>('Object|Null', '#[#](#, #, #)', o, method, arg1, arg2, arg3);
}

/// Unchecked version for 4 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callMethodUnchecked4<T>(Object o, String method, Object? arg1, Object? arg2,
    Object? arg3, Object? arg4) {
  return JS<dynamic>(
      'Object|Null', '#[#](#, #, #, #)', o, method, arg1, arg2, arg3, arg4);
}

/// Similar to [_callMethodUnchecked4] but introduces an unsound implicit cast
/// to `T`.
@pragma('dart2js:tryInline')
T _callMethodUncheckedTrustType4<T>(Object o, String method, Object? arg1,
    Object? arg2, Object? arg3, Object? arg4) {
  return JS<T>(
      'Object|Null', '#[#](#, #, #, #)', o, method, arg1, arg2, arg3, arg4);
}

@patch
bool instanceof(Object? o, Object type) =>
    JS('bool', '# instanceof #', o, type);

@patch
T callConstructor<T>(Object constr, List<Object?>? arguments) {
  if (arguments == null) {
    return JS<dynamic>('Object', 'new #()', constr);
  } else {
    assertInteropArgs(arguments);
  }

  if (JS('bool', '# instanceof Array', arguments)) {
    int argumentCount = JS('int', '#.length', arguments);
    switch (argumentCount) {
      case 0:
        return JS<dynamic>('Object', 'new #()', constr);

      case 1:
        var arg0 = JS('', '#[0]', arguments);
        return JS<dynamic>('Object', 'new #(#)', constr, arg0);

      case 2:
        var arg0 = JS('', '#[0]', arguments);
        var arg1 = JS('', '#[1]', arguments);
        return JS<dynamic>('Object', 'new #(#, #)', constr, arg0, arg1);

      case 3:
        var arg0 = JS('', '#[0]', arguments);
        var arg1 = JS('', '#[1]', arguments);
        var arg2 = JS('', '#[2]', arguments);
        return JS<dynamic>(
            'Object', 'new #(#, #, #)', constr, arg0, arg1, arg2);

      case 4:
        var arg0 = JS('', '#[0]', arguments);
        var arg1 = JS('', '#[1]', arguments);
        var arg2 = JS('', '#[2]', arguments);
        var arg3 = JS('', '#[3]', arguments);
        return JS<dynamic>(
            'Object', 'new #(#, #, #, #)', constr, arg0, arg1, arg2, arg3);
    }
  }

  // The following code solves the problem of invoking a JavaScript
  // constructor with an unknown number arguments.
  // First bind the constructor to the argument list using bind.apply().
  // The first argument to bind() is the binding of 't', so add 'null' to
  // the arguments list passed to apply().
  // After that, use the JavaScript 'new' operator which overrides any binding
  // of 'this' with the new instance.
  var args = <dynamic>[null]..addAll(arguments);
  var factoryFunction = JS('', '#.bind.apply(#, #)', constr, constr, args);
  // Without this line, calling factoryFunction as a constructor throws
  JS('String', 'String(#)', factoryFunction);
  // This could return an UnknownJavaScriptObject, or a native
  // object for which there is an interceptor
  return JS<dynamic>('Object', 'new #()', factoryFunction);

  // TODO(sra): Investigate:
  //
  //     var jsObj = JS('', 'Object.create(#.prototype)', constr);
  //     JS('', '#.apply(#, #)', constr, jsObj,
  //         []..addAll(arguments.map(_convertToJS)));
  //     return _wrapToDart(jsObj);
}

/// Unchecked version for 0 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callConstructorUnchecked0<T>(Object constr) {
  return JS<dynamic>('Object', 'new #()', constr);
}

/// Unchecked version for 1 argument, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callConstructorUnchecked1<T>(Object constr, Object? arg1) {
  return JS<dynamic>('Object', 'new #(#)', constr, arg1);
}

/// Unchecked version for 2 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callConstructorUnchecked2<T>(Object constr, Object? arg1, Object? arg2) {
  return JS<dynamic>('Object', 'new #(#, #)', constr, arg1, arg2);
}

/// Unchecked version for 3 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callConstructorUnchecked3<T>(
    Object constr, Object? arg1, Object? arg2, Object? arg3) {
  return JS<dynamic>('Object', 'new #(#, #, #)', constr, arg1, arg2, arg3);
}

/// Unchecked version for 4 arguments, only used in a CFE transformation.
@pragma('dart2js:tryInline')
T _callConstructorUnchecked4<T>(
    Object constr, Object? arg1, Object? arg2, Object? arg3, Object? arg4) {
  return JS<dynamic>(
      'Object', 'new #(#, #, #, #)', constr, arg1, arg2, arg3, arg4);
}

@patch
@pragma('dart2js:tryInline')
T add<T>(Object? first, Object? second) {
  return JS<dynamic>('Object', '# + #', first, second);
}

@patch
@pragma('dart2js:tryInline')
T subtract<T>(Object? first, Object? second) {
  return JS<dynamic>('Object', '# - #', first, second);
}

@patch
@pragma('dart2js:tryInline')
T multiply<T>(Object? first, Object? second) {
  return JS<dynamic>('Object', '# * #', first, second);
}

@patch
@pragma('dart2js:tryInline')
T divide<T>(Object? first, Object? second) {
  return JS<dynamic>('Object', '# / #', first, second);
}

@patch
@pragma('dart2js:tryInline')
T exponentiate<T>(Object? first, Object? second) {
  return JS<dynamic>('Object', '# ** #', first, second);
}

@patch
@pragma('dart2js:tryInline')
T modulo<T>(Object? first, Object? second) {
  return JS<dynamic>('Object', '# % #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool equal<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# == #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool strictEqual<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# === #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool notEqual<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# != #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool strictNotEqual<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# !== #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool greaterThan<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# > #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool greaterThanOrEqual<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# >= #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool lessThan<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# < #', first, second);
}

@patch
@pragma('dart2js:tryInline')
bool lessThanOrEqual<T>(Object? first, Object? second) {
  return JS<bool>('bool', '# <= #', first, second);
}

@patch
Future<T> promiseToFuture<T>(Object jsPromise) {
  final completer = Completer<T>();

  final success = convertDartClosureToJS((r) => completer.complete(r), 1);
  final error = convertDartClosureToJS((e) {
    // Note that `completeError` expects a non-nullable error regardless of
    // whether null-safety is enabled, so a `NullRejectionException` is always
    // provided if the error is `null` or `undefined`.
    if (e == null) {
      return completer.completeError(
          NullRejectionException._(JS('bool', '# === undefined', e)));
    }
    return completer.completeError(e);
  }, 1);

  JS('', '#.then(#, #)', jsPromise, success, error);
  return completer.future;
}

@patch
Object? objectGetPrototypeOf(Object? object) =>
    JS('', 'Object.getPrototypeOf(#)', object);

@patch
Object? get objectPrototype => JS('', 'Object.prototype');

@patch
List<Object?> objectKeys(Object? object) => JS('', 'Object.keys(#)', object);

// TODO(joshualitt): Move these `is` checks to a helper library to help
// declutter this patch file.
bool _isJavaScriptDate(value) => JS('bool', '# instanceof Date', value);
bool _isJavaScriptRegExp(value) => JS('bool', '# instanceof RegExp', value);

@patch
bool isJavaScriptArray(value) => JS('bool', '# instanceof Array', value);

// Although it may be tempting to try and rewrite [isJavaScriptSimpleObject]
// using `js_util` calls, it turns out this can be fragile on some browsers
// under some situations.
@patch
bool isJavaScriptSimpleObject(value) {
  var proto = JS('', 'Object.getPrototypeOf(#)', value);
  return JS('bool', '# === Object.prototype', proto) ||
      JS('bool', '# === null', proto);
}

bool _isJavaScriptPromise(value) =>
    JS('bool', r'typeof Promise != "undefined" && # instanceof Promise', value);

DateTime _dateToDateTime(date) {
  int millisSinceEpoch = JS('int', '#.getTime()', date);
  return new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true);
}

@patch
Object? dartify(Object? o) {
  var _convertedObjects = HashMap.identity();
  Object? convert(Object? o) {
    if (_convertedObjects.containsKey(o)) {
      return _convertedObjects[o];
    }
    if (o == null || o is bool || o is num || o is String) return o;

    if (_isJavaScriptDate(o)) {
      return _dateToDateTime(o);
    }

    if (_isJavaScriptRegExp(o)) {
      // TODO(joshualitt): Consider investigating if there is a way to convert
      // from `JSRegExp` to `RegExp`.
      throw new ArgumentError('structured clone of RegExp');
    }

    if (_isJavaScriptPromise(o)) {
      return promiseToFuture(o);
    }

    if (isJavaScriptSimpleObject(o)) {
      Map<Object?, Object?> dartObject = {};
      _convertedObjects[o] = dartObject;
      List<Object?> originalKeys = objectKeys(o);
      List<Object?> dartKeys = [];
      for (Object? key in originalKeys) {
        dartKeys.add(dartify(key));
      }
      for (int i = 0; i < originalKeys.length; i++) {
        Object? jsKey = originalKeys[i];
        Object? dartKey = dartKeys[i];
        if (jsKey != null) {
          dartObject[dartKey] = convert(getProperty(o, jsKey));
        }
      }
      return dartObject;
    }

    if (isJavaScriptArray(o)) {
      var l = JS<List>('returns:List;creates:;', '#', o);
      List<Object?> dartObject = [];
      _convertedObjects[o] = dartObject;
      int length = getProperty(o, 'length');
      for (int i = 0; i < length; i++) {
        dartObject.add(convert(l[i]));
      }
      return dartObject;
    }

    // Assume anything else is already a valid Dart object, either by having
    // already been processed, or e.g. a cloneable native class.
    return o;
  }

  return convert(o);
}
