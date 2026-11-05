// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

// libobjc is linked into the Dart binary on macOS and iOS.
@Native<Pointer<Void> Function(Pointer<Char>)>(symbol: 'objc_getClass')
external Pointer<Void> objcGetClass(Pointer<Char> name);

@Native<Pointer<Void> Function(Pointer<Char>)>(symbol: 'sel_registerName')
external Pointer<Void> selRegisterName(Pointer<Char> name);

@Native<Pointer<Void> Function(Pointer<Void>, Pointer<Void>)>(
  symbol: 'objc_msgSend',
)
external Pointer<Void> objcMsgSend(Pointer<Void> receiver, Pointer<Void> op);

@Native<Pointer<Void> Function(Pointer<Pointer<Void>>, Pointer<Void>)>(
  symbol: 'objc_initWeak',
)
external Pointer<Void> objcInitWeak(
  Pointer<Pointer<Void>> location,
  Pointer<Void> val,
);

@Native<Pointer<Void> Function(Pointer<Pointer<Void>>)>(symbol: 'objc_loadWeak')
external Pointer<Void> objcLoadWeak(Pointer<Pointer<Void>> location);

@Native<Void Function(Pointer<Pointer<Void>>)>(symbol: 'objc_destroyWeak')
external void objcDestroyWeak(Pointer<Pointer<Void>> location);

Pointer<Void> getSelector(String name) {
  final namePtr = name.toNativeUtf8();
  final sel = selRegisterName(namePtr.cast());
  calloc.free(namePtr);
  return sel;
}

Pointer<Void> getClass(String name) {
  final namePtr = name.toNativeUtf8();
  final cls = objcGetClass(namePtr.cast());
  calloc.free(namePtr);
  return cls;
}

Future<void> testAutoreleasePool() async {
  final nsObjectClass = getClass('NSObject');
  final allocSel = getSelector('alloc');
  final initSel = getSelector('init');
  final autoreleaseSel = getSelector('autorelease');

  // [[NSObject alloc] init]
  final obj = objcMsgSend(objcMsgSend(nsObjectClass, allocSel), initSel);
  Expect.notEquals(nullptr, obj);

  final weakLocation = calloc<Pointer<Void>>();
  objcInitWeak(weakLocation, obj);

  // [obj autorelease]
  objcMsgSend(obj, autoreleaseSel);

  // Assert objc_loadWeak(weakLocation) == obj (alive in current turn).
  Expect.equals(obj, objcLoadWeak(weakLocation));

  // Test across microtask: microtasks run within the same event loop turn.
  await Future.microtask(() {});
  Expect.equals(obj, objcLoadWeak(weakLocation));

  // Test across isolate message loop boundary: AutoreleasePoolScope pops.
  await Future<void>.delayed(Duration.zero);

  // Assert objc_loadWeak(weakLocation) == nullptr.
  Expect.equals(nullptr, objcLoadWeak(weakLocation));

  // Clean up.
  objcDestroyWeak(weakLocation);
  calloc.free(weakLocation);
}

void main() async {
  if (!Platform.isMacOS && !Platform.isIOS) return;

  asyncStart();

  // Test on main isolate.
  await testAutoreleasePool();

  // Test on helper isolate.
  await Isolate.run(testAutoreleasePool);

  asyncEnd();
}
