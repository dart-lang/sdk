// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `allowInterop` and `allowInteropCaptureThis` should be idempotent
// when given wrapped functions, JS functions, or Dart functions that were
// wrapped by a previous call.

import 'package:expect/expect.dart';
import 'package:js/js.dart';

const isDart2JS = const bool.fromEnvironment('dart.tool.dart2js');

@JS()
external void eval(String code);

@JS()
external Function get jsFunction;

void main() {
  eval('''
    self.jsFunction = function() {};
  ''');
  final dartFunction = (_) {};
  final wrappedFunction = allowInterop(dartFunction);
  final wrappedFunctionCaptureThis = allowInteropCaptureThis(dartFunction);
  // Should add a wrapper that's unique to the function.
  Expect.notEquals(dartFunction, wrappedFunction);
  Expect.notEquals(dartFunction, wrappedFunctionCaptureThis);
  Expect.notEquals(wrappedFunction, wrappedFunctionCaptureThis);
  // Should return the same value if the value is already a wrapped function.
  Expect.equals(wrappedFunction, allowInterop(wrappedFunction));
  Expect.equals(
      wrappedFunctionCaptureThis, allowInterop(wrappedFunctionCaptureThis));
  // Passing a non-Dart function to `allowInteropCaptureThis` throws in dart2js,
  // so for now, capture the existing semantics. We may want to update DDC to
  // match this.
  if (isDart2JS) {
    Expect.throws(() => allowInteropCaptureThis(wrappedFunction));
    Expect.throws(() => allowInteropCaptureThis(wrappedFunctionCaptureThis));
  } else {
    Expect.equals(wrappedFunction, allowInteropCaptureThis(wrappedFunction));
    Expect.equals(wrappedFunctionCaptureThis,
        allowInteropCaptureThis(wrappedFunctionCaptureThis));
  }
  // Should directly return JS functions without doing anything.
  Expect.equals(jsFunction, allowInterop(jsFunction));
  if (isDart2JS) {
    Expect.throws(() => allowInteropCaptureThis(jsFunction));
  } else {
    Expect.equals(jsFunction, allowInteropCaptureThis(jsFunction));
  }
  // If `allowInterop`/`allowInteropCaptureThis` is called again on the same
  // Dart value, should return the previously wrapped function.
  Expect.equals(wrappedFunction, allowInterop(dartFunction));
  Expect.equals(
      wrappedFunctionCaptureThis, allowInteropCaptureThis(dartFunction));
}
