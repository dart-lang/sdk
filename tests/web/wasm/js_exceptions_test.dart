// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

// Catch JS exceptions in try-catch and try-finally, in sync and async
// functions. Also in `await`.
void main() async {
  asyncStart();

  defineJSFunctions();

  jsExceptionCatch();
  jsExceptionFinally();
  jsExceptionGuardTypeTest();
  jsExceptionRuntimeTypeTest();

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
external void throwString();

@JS()
external void throwError();

@JS()
external void throwObject();

@JS()
external JSAny getThrownJSObject();

bool runtimeTrue() => int.parse('1') == 1;

void defineJSFunctions() {
  eval(r'''
      self.thrownJSObject = undefined;

      self.getThrownJSObject = function() {
        return self.thrownJSObject;
      }

      self.throwString = function() {
        self.thrownJSObject =  "Hi from JS";
        throw self.thrownJSObject;
      }

      self.throwError = function() {
        self.thrownJSObject = new Error("Hi from JS");
        throw self.thrownJSObject;
      }

      self.throwObject = function() {
        self.thrownJSObject = new Object();
        throw self.thrownJSObject;
      }
    ''');
}

void throwDart() {
  if (runtimeTrue()) {
    throw "Hi from Dart";
  }
}

// Catch a JS exception in `catch`.
void jsExceptionCatch() {
  try {
    throwString();
  } catch (e) {
    return;
  }
  Expect.fail("Exception not caught");
}

// Catch a JS exception in `finally`.
void jsExceptionFinally() {
  if (runtimeTrue()) {
    try {
      throwString();
    } finally {
      return;
    }
  }
  Expect.fail("Exception not caught");
}

Future<void> throwJSExceptionAsync() async {
  return throwString();
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
    throwString();
  } catch (e) {
    return;
  }
  Expect.fail("Exception not caught");
}

// Catch a JS exception thrown without `await` in `finally`.
Future<void> jsExceptionFinallyAsyncDirect() async {
  if (runtimeTrue()) {
    try {
      throwString();
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

// Check that the finally blocks rethrow JS exceptions, when a function directly
// throws (no `await`).
Future<void> jsExceptionFinallyPropagateAsyncDirect() async {
  int i = 0;
  try {
    if (runtimeTrue()) {
      try {
        throwString();
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
  bool objectCaught = false;
  try {
    await yield_();
    if (runtimeTrue()) {
      try {
        await yield_();
        throwString();
        await yield_();
      } on Exception catch (_) {
        await yield_();
        exceptionCaught = true;
        await yield_();
      } on Error catch (_) {
        await yield_();
        errorCaught = true;
        await yield_();
      } catch (_) {
        objectCaught = true;
        await yield_();
      }
    }
  } catch (_) {
    await yield_();
  }
  Expect.equals(exceptionCaught, false);
  Expect.equals(errorCaught, false);
  Expect.equals(objectCaught, true);
}

// Similar to `jsExceptionTypeTest1`, but the type test should succeed in a
// parent try-catch.
Future<void> jsExceptionTypeTest2() async {
  bool exceptionCaughtInner = false;
  bool errorCaughtInner = false;
  bool objectCaughtInner = false;

  bool exceptionCaughtOuter = false;
  bool errorCaughtOuter = false;
  bool objectCaughtOuter = false;
  try {
    await yield_();
    if (runtimeTrue()) {
      try {
        await yield_();
        throwString();
        await yield_();
      } on Exception catch (_) {
        await yield_();
        exceptionCaughtInner = true;
        await yield_();
        rethrow;
      } on Error catch (_) {
        await yield_();
        errorCaughtInner = true;
        await yield_();
        rethrow;
      } catch (_) {
        await yield_();
        objectCaughtInner = true;
        await yield_();
        rethrow;
      }
    }
  } on Exception catch (_) {
    await yield_();
    exceptionCaughtOuter = true;
    await yield_();
  } on Error catch (_) {
    await yield_();
    errorCaughtOuter = true;
    await yield_();
  } catch (_) {
    await yield_();
    objectCaughtOuter = true;
    await yield_();
  }
  Expect.equals(exceptionCaughtInner, false);
  Expect.equals(errorCaughtInner, false);
  Expect.equals(objectCaughtInner, true);
  Expect.equals(exceptionCaughtOuter, false);
  Expect.equals(errorCaughtOuter, false);
  Expect.equals(objectCaughtOuter, true);
}

/// Test that JS exceptions are caught correctly based on the `on` guard types.
void jsExceptionGuardTypeTest() {
  // Catch a JS object as `Object`.
  {
    var caught = false;
    try {
      throwObject();
    } on Object catch (e) {
      caught = e.isA<JSObject>();
    }
    Expect.equals(caught, true);
  }

  // Catch a JS object as `dynamic`.
  {
    var caught = false;
    try {
      throwObject();
    } on dynamic catch (e) {
      caught = e is JSObject;
    }
    Expect.equals(caught, true);
  }

  // Catch a JS object as `Object?`.
  {
    var caught = false;
    try {
      throwObject();
    } on Object? catch (e) {
      caught = e.isA<JSObject>();
    }
    Expect.equals(caught, true);
  }

  // Catch a JS object as JS string.
  //
  // We don't try to distinguish JS types when catching as they'll all be
  // `JSValue` wrappers.
  {
    var caught = false;
    try {
      throwString();
    } on JSObject catch (e) {
      caught = e.isA<JSString>();
    }
    Expect.equals(caught, true);
  }

  // Don't catch a Dart object as JS.
  {
    var caughtObject = false;
    try {
      var caughtJSAny = false;
      try {
        throwDart();
      } on JSAny {
        caughtJSAny = true;
      }
      Expect.equals(caughtJSAny, false);
    } catch (e) {
      caughtObject = true;
    }
    Expect.equals(caughtObject, true);
  }

  // Same as above, but a single Dart `try` catches both JS and Dart objects.
  {
    var caughtObject = false;
    var caughtJSAny = false;
    try {
      throwDart();
    } on JSAny {
      caughtJSAny = true;
    } on Object {
      caughtObject = true;
    }
    Expect.equals(caughtJSAny, false);
    Expect.equals(caughtObject, true);
  }
}

/// Test that JS exceptions have the right runtime types.
void jsExceptionRuntimeTypeTest() {
  for (final f in [
    () => throwString(),
    () => throwError(),
    () => throwObject(),
  ]) {
    dynamic caughtObject;
    try {
      f();
    } catch (e) {
      caughtObject = e;
    }
    Expect.equals(caughtObject.runtimeType, JSAny);
  }

  dynamic caughtObject;
  try {
    throwDart();
  } catch (e) {
    caughtObject = e;
  }
  Expect.notEquals(caughtObject.runtimeType, JSAny);
}

/// Test that we wrap the right JS objects when catching JS exceptions.
void jsExceptionIdentityTest() {
  for (final f in [
    () => throwString(),
    () => throwError(),
    () => throwObject(),
  ]) {
    dynamic caughtObject;
    try {
      f();
    } on JSAny catch (e) {
      caughtObject = e;
    }
    Expect.equals(caughtObject.strictEquals(getThrownJSObject()), true);
  }
}
