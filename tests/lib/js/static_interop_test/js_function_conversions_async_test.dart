// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=checked-implicit-downcasts

// Test that Function.toJS properly converts async functions
// returning Future<T>.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS('usePromise')
external JSPromise<JSAny?> usePromise(JSFunction f, [JSAny? arg]);

JSObject? asyncObj;

Future<JSObject> doThing() async {
  asyncObj = JSObject()..['key'] = 3.toJS;
  return asyncObj!;
}

class AsyncClass {
  Future<JSObject> doThing() async {
    asyncObj = JSObject()..['key'] = 3.toJS;
    return asyncObj!;
  }
}

Future<T> asyncFoo<T>(T x) async {
  return x;
}

Future<void> doVoidThing() async {
  asyncObj = JSObject()..['key'] = 3.toJS;
}

void main() {
  asyncTest(() async {
    eval('''
      globalThis.usePromise = function (promise, arg) {
        return promise(arg);
      }
    ''');
    // Top-level async function tear-off returning Future<JSObject>
    final f = doThing.toJS;
    asyncObj = null;
    final resF = await usePromise(f).toDart;
    Expect.isNotNull(asyncObj);
    final valF = ((resF as JSObject)['key'] as JSNumber).toDartInt;
    Expect.equals(3, valF);

    // Instance method async tear-off returning Future<JSObject>
    final g = AsyncClass().doThing.toJS;
    asyncObj = null;
    final resG = await usePromise(g).toDart;
    Expect.isNotNull(asyncObj);
    final valG = ((resG as JSObject)['key'] as JSNumber).toDartInt;
    Expect.equals(3, valG);

    // Anonymous async closure returning Future<JSObject>
    final h = (() async => Future<JSObject>.value(
      JSObject()..['key'] = 3.toJS,
    )).toJS;
    final resH = await usePromise(h).toDart;
    final valH = ((resH as JSObject)['key'] as JSNumber).toDartInt;
    Expect.equals(3, valH);

    // Generic async function tear-off with arguments
    final i = asyncFoo<JSNumber>.toJS;
    final resI = await usePromise(i, 42.toJS).toDart;
    final valI = (resI as JSNumber).toDartInt;
    Expect.equals(42, valI);

    // Async function returning Future<void>
    final j = doVoidThing.toJS;
    asyncObj = null;
    await usePromise(j).toDart;
    Expect.isNotNull(asyncObj);
  });

  asyncTest(() async {
    eval('''
      globalThis.usePromise = function (promise, arg) {
        return promise(arg);
      }
    ''');
    // Top-level async function tear-off returning Future<JSObject>
    final f = doThing.toJSCaptureThis;
    asyncObj = null;
    final resF = await usePromise(f).toDart;
    Expect.isNotNull(asyncObj);
    final valF = ((resF as JSObject)['key'] as JSNumber).toDartInt;
    Expect.equals(3, valF);

    // Instance method async tear-off returning Future<JSObject>
    final g = AsyncClass().doThing.toJSCaptureThis;
    asyncObj = null;
    final resG = await usePromise(g).toDart;
    Expect.isNotNull(asyncObj);
    final valG = ((resG as JSObject)['key'] as JSNumber).toDartInt;
    Expect.equals(3, valG);

    // Anonymous async closure returning Future<JSObject>
    final h = (() async => Future<JSObject>.value(
      JSObject()..['key'] = 3.toJS,
    )).toJSCaptureThis;
    final resH = await usePromise(h).toDart;
    final valH = ((resH as JSObject)['key'] as JSNumber).toDartInt;
    Expect.equals(3, valH);

    // Generic async function tear-off with arguments
    final i = asyncFoo<JSNumber>.toJSCaptureThis;
    final resI = await usePromise(i, 42.toJS).toDart;
    final valI = (resI as JSNumber).toDartInt;
    Expect.equals(42, valI);

    // Async function returning Future<void>
    final j = doVoidThing.toJSCaptureThis;
    asyncObj = null;
    await usePromise(j).toDart;
    Expect.isNotNull(asyncObj);
  });
}
