// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:js_util library.

import 'dart:_foreign_helper' show JS, DART_CLOSURE_TO_JS;
import 'dart:_interceptors' show DART_CLOSURE_PROPERTY_NAME;
import 'dart:_internal' show patch;
import 'dart:_js_helper'
    show
        isJSFunction,
        JS_FUNCTION_PROPERTY_NAME,
        JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS;

_convertDartFunctionFast(Function f) {
  var existing = JS('', '#.#', f, JS_FUNCTION_PROPERTY_NAME);
  if (existing != null) return existing;
  var ret = JS(
      'JavaScriptFunction',
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
  JS('', '#.# = #', f, JS_FUNCTION_PROPERTY_NAME, ret);
  return ret;
}

_convertDartFunctionFastCaptureThis(Function f) {
  var existing = JS('', '#.#', f, JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS);
  if (existing != null) return existing;
  var ret = JS(
      'JavaScriptFunction',
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
  JS('', '#.# = #', f, JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS, ret);
  return ret;
}

_callDartFunctionFast(callback, List arguments) {
  return Function.apply(callback, arguments);
}

_callDartFunctionFastCaptureThis(callback, self, List arguments) {
  return Function.apply(callback, [self]..addAll(arguments));
}

@patch
F allowInterop<F extends Function>(F f) {
  if (isJSFunction(f)) {
    // Already supports interop, just use the existing function.
    return f;
  } else {
    return _convertDartFunctionFast(f);
  }
}

@patch
Function allowInteropCaptureThis(Function f) {
  if (isJSFunction(f)) {
    // Behavior when the function is already a JS function is unspecified.
    throw ArgumentError(
        "Function is already a JS function so cannot capture this.");
    return f;
  } else {
    return _convertDartFunctionFastCaptureThis(f);
  }
}
