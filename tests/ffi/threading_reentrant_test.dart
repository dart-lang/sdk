// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests Isolate threading API.
//
// VMOptions=--experimental-shared-data
//
// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:concurrent';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';
import 'threading_utils.dart';

@pragma('vm:shared')
final counter = Uint8List(1);

@pragma('vm:shared')
final dartSetCurrentThreadOwnsIsolate = DynamicLibrary.executable()
    .lookup<NativeFunction<Void Function()>>("Dart_SetCurrentThreadOwnsIsolate")
    .asFunction<void Function()>();

DynamicLibrary get ffiTestFunctions => DynamicLibrary.open(
  "libffi_test_functions.${Platform.isMacOS ? 'dylib' : 'so'}",
);

typedef CallbackReturningIntNativeType = Int32 Function(Int32, Int32);

typedef TwoIntFnNativeType = Int32 Function(Pointer, Int32, Int32);
typedef TwoIntFnType = int Function(Pointer, int, int);
TwoIntFnType get callTwoIntFunction => ffiTestFunctions
    .lookupFunction<TwoIntFnNativeType, TwoIntFnType>("CallTwoIntFunction");

int threadMain(Pointer<Void> data) {
  print('threadMain started');
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound((
        int a,
        int b,
      ) {
        print('threadMain callback $a + $b');
        return a + b;
      }, exceptionalReturn: 1111);
  print('created isolateGroupBound in threadMain and calling it');

  Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));
  callback.close();

  final new_isolate = Isolate.create(debugName: "helper");
  new_isolate.runSync(() {
    dartSetCurrentThreadOwnsIsolate();
  });
  new_isolate.runSync(() {
    print('Hello, new isolate!');
  });
  new_isolate.shutdownSync();
  return 0;
}

Future<void> testRun() async {
  {
    final callback =
        NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound((
          int a,
          int b,
        ) {
          print('testRun callback $a + $b');
          return a + b;
        }, exceptionalReturn: 1111);

    Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));
    callback.close();
  }

  if (Platform.isWindows) {
    return; // pthread is not available on Windows.
  }

  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        threadMain,
        exceptionalReturn: -1,
      );

  final threadInfo = ThreadInfo();
  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  Expect.equals(
    0,
    pthreadCreate(
      threadInfo.ptr_tid,
      threadInfo.ptr_attr,
      callback.nativeFunction,
      threadInfo.ptr_data.cast<Void>(),
    ),
  );

  threadInfo.joinAndDestroy();
}

main(List<String> args, List<SendPort>? message) async {
  if (Platform.isWindows) {
    return; // pthread is not available on Windows.
  }
  asyncStart();
  await testRun();
  asyncEnd();
}
