// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:js_interop';
import 'dart:_wasm';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Catch JS exceptions in try-catch and try-finally, in sync and async
// functions. Also in `await`.
void main() async {
  asyncStart();

  defineThrowJSException();

  jsExceptionCatch();
  jsExceptionFinally();

  await jsExceptionCatchAsync();
  await jsExceptionFinallyAsync();
  await jsExceptionCatchAsyncDirect();
  await jsExceptionFinallyAsyncDirect();
  await jsExceptionFinallyPropagateAsync();
  await jsExceptionFinallyPropagateAsyncDirect();
  await jsExceptionTypeTest1();
  await jsExceptionTypeTest2();

  asyncEnd();
}

@JS()
external void eval(String code);

@JS()
external void throwJSException();

bool runtimeTrue() => int.parse('1') == 1;

void defineThrowJSException() {
  eval(r'''
      globalThis.throwJSException = function() {
        throw "Hi from JS";
      }
    ''');
}

// Catch a JS exception in `catch`.
void jsExceptionCatch() {
  try {
    throwJSException();
  } catch (e) {
    return;
  }
  Expect.fail("Exception not caught");
}

// Catch a JS exception in `finally`.
void jsExceptionFinally() {
  if (runtimeTrue()) {
    try {
      throwJSException();
    } finally {
      return;
    }
  }
  Expect.fail("Exception not caught");
}

Future<void> throwJSExceptionAsync() async {
  return throwJSException();
}

// A simple async function used to create suspension points.
Future<int> yield_() async => runtimeTrue() ? 1 : throw '';

// Catch a JS exception throw by `await` in `catch`.
Future<void> jsExceptionCatchAsync() async {
  try {
    await throwJSExceptionAsync();
  } catch (e) {
    return;
  }
  Expect.fail("Exception not caught");
}

// Catch a JS exception thrown by `await` in `finally`.
Future<void> jsExceptionFinallyAsync() async {
  if (runtimeTrue()) {
    try {
      await throwJSExceptionAsync();
    } finally {
      return;
    }
  }
  Expect.fail("Exception not caught");
}

// Catch a JS exception thrown without `await` in `catch`.
Future<void> jsExceptionCatchAsyncDirect() async {
  try {
    throwJSException();
  } catch (e) {
    return;
  }
  Expect.fail("Exception not caught");
}

// Catch a JS exception thrown without `await` in `finally`.
Future<void> jsExceptionFinallyAsyncDirect() async {
  if (runtimeTrue()) {
    try {
      throwJSException();
    } finally {
      return;
    }
  }
  Expect.fail("Exception not caught");
}

// Check that the finally blocks rethrow JS exceptions, when `await` throws.
Future<void> jsExceptionFinallyPropagateAsync() async {
  int i = 0;
  try {
    if (runtimeTrue()) {
      try {
        await throwJSExceptionAsync();
      } finally {
        i += 1;
      }
    }
  } catch (e) {
    i += 1;
  }
  Expect.equals(i, 2);
}

// Check that the finally blocks rethrow JS exceptions, when a function directly throws (no `await`).
Future<void> jsExceptionFinallyPropagateAsyncDirect() async {
  int i = 0;
  try {
    if (runtimeTrue()) {
      try {
        throwJSException();
      } finally {
        i += 1;
      }
    }
  } catch (e) {
    i += 1;
  }
  Expect.equals(i, 2);
}

// Catch JS exception and run type tests. Dummy `await` statements to generate
// suspension points before and after every statement. Type test should succeed
// in the same try-catch statement.
Future<void> jsExceptionTypeTest1() async {
  bool exceptionCaught = false;
  bool errorCaught = false;
  try {
    await yield_();
    if (runtimeTrue()) {
      try {
        await yield_();
        throwJSException();
        await yield_();
      } on Exception catch (_) {
        await yield_();
        exceptionCaught = true;
        await yield_();
      } on Error catch (_) {
        await yield_();
        errorCaught = true;
        await yield_();
      }
    }
  } catch (_) {
    await yield_();
  }
  Expect.equals(exceptionCaught, false);
  Expect.equals(errorCaught, true);
}

// Similar to `jsExceptionTypeTest1`, but the type test should succeed in a
// parent try-catch.
Future<void> jsExceptionTypeTest2() async {
  bool exceptionCaught = false;
  bool errorCaught = false;
  try {
    await yield_();
    if (runtimeTrue()) {
      try {
        await yield_();
        throwJSException();
        await yield_();
      } on Exception catch (_) {
        await yield_();
        exceptionCaught = true;
        await yield_();
      }
    }
  } on Exception catch (_) {
    await yield_();
    exceptionCaught = true;
    await yield_();
  } on Error catch (_) {
    await yield_();
    errorCaught = true;
    await yield_();
  }
  Expect.equals(exceptionCaught, false);
  Expect.equals(errorCaught, true);
}
