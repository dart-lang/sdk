// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:_wasm';

import 'package:expect/expect.dart';

// Catch JS exceptions in try-catch and try-finally, in sync and async
// functions. Also in `await`.
void main() async {
  defineThrowJSException();

  jsExceptionCatch();
  jsExceptionFinally();
  jsExceptionCatchAsync();
  jsExceptionFinallyAsync();
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
