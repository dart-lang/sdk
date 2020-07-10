// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to manipulate `package:js` annotated JavaScript interop
/// objects in cases where the name to call is not known at runtime.
///
/// You should only use these methods when the same effect cannot be achieved
/// with `@JS()` annotations.
///
/// {@category Web}
library dart.js_util;

import 'dart:_foreign_helper' show JS;
import 'dart:collection' show HashMap;
import 'dart:async' show Completer;
import 'dart:_js_helper' show convertDartClosureToJS;

/// Recursively converts a JSON-like collection to JavaScript compatible
/// representation.
///
/// WARNING: performance of this method is much worse than other util
/// methods in this library. Only use this method as a last resort. Prefer
/// instead to use `@anonymous` `@JS()` annotated classes to create map-like
/// objects for JS interop.
///
/// The argument must be a [Map] or [Iterable], the contents of which are also
/// deeply converted. Maps are converted into JavaScript objects. Iterables are
/// converted into arrays. Strings, numbers, bools, and `@JS()` annotated
/// objects are passed through unmodified. Dart objects are also passed through
/// unmodified, but their members aren't usable from JavaScript.
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

dynamic newObject() => JS('=Object', '{}');

bool hasProperty(Object o, Object name) => JS('bool', '# in #', name, o);

dynamic getProperty(Object o, Object name) =>
    JS('Object|Null', '#[#]', o, name);

dynamic setProperty(Object o, Object name, Object? value) =>
    JS('', '#[#]=#', o, name, value);

dynamic callMethod(Object o, String method, List<Object?> args) =>
    JS('Object|Null', '#[#].apply(#, #)', o, method, o, args);

/// Check whether [o] is an instance of [type].
///
/// The value in [type] is expected to be a JS-interop object that
/// represents a valid JavaScript constructor function.
bool instanceof(Object? o, Object type) =>
    JS('bool', '# instanceof #', o, type);

dynamic callConstructor(Object constr, List<Object?> arguments) {
  if (arguments == null) {
    return JS('Object', 'new #()', constr);
  }

  if (JS('bool', '# instanceof Array', arguments)) {
    int argumentCount = JS('int', '#.length', arguments);
    switch (argumentCount) {
      case 0:
        return JS('Object', 'new #()', constr);

      case 1:
        var arg0 = JS('', '#[0]', arguments);
        return JS('Object', 'new #(#)', constr, arg0);

      case 2:
        var arg0 = JS('', '#[0]', arguments);
        var arg1 = JS('', '#[1]', arguments);
        return JS('Object', 'new #(#, #)', constr, arg0, arg1);

      case 3:
        var arg0 = JS('', '#[0]', arguments);
        var arg1 = JS('', '#[1]', arguments);
        var arg2 = JS('', '#[2]', arguments);
        return JS('Object', 'new #(#, #, #)', constr, arg0, arg1, arg2);

      case 4:
        var arg0 = JS('', '#[0]', arguments);
        var arg1 = JS('', '#[1]', arguments);
        var arg2 = JS('', '#[2]', arguments);
        var arg3 = JS('', '#[3]', arguments);
        return JS(
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
  return JS('Object', 'new #()', factoryFunction);

  // TODO(sra): Investigate:
  //
  //     var jsObj = JS('', 'Object.create(#.prototype)', constr);
  //     JS('', '#.apply(#, #)', constr, jsObj,
  //         []..addAll(arguments.map(_convertToJS)));
  //     return _wrapToDart(jsObj);
}

/// Converts a JavaScript Promise to a Dart [Future].
///
/// ```dart
/// @JS()
/// external Promise<num> get threePromise; // Resolves to 3
///
/// final Future<num> threeFuture = promiseToFuture(threePromise);
///
/// final three = await threeFuture; // == 3
/// ```
Future<T> promiseToFuture<T>(Object jsPromise) {
  final completer = Completer<T>();

  final success = convertDartClosureToJS((r) => completer.complete(r), 1);
  final error = convertDartClosureToJS((e) => completer.completeError(e), 1);

  JS('', '#.then(#, #)', jsPromise, success, error);
  return completer.future;
}
