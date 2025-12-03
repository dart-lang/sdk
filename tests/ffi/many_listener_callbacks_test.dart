// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that interleaved creation and calling of many NativeCallable.listener
// callbacks does not deadlock.
// Regression test for https://github.com/dart-lang/sdk/issues/61272
//
// VMOptions=
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--test_il_serialization
// SharedObjects=ffi_test_functions

// No profiler for this test. TSAN's vector clocks become more expensive as the
// number of threads that touch a variable increases. This test creates many
// threads, and the Mac/Windows/Fuchsia profilers will sample them from another
// thread.

import 'dart:async';
import 'dart:ffi';

import 'dylib_utils.dart';

typedef FnStartNativeType = Pointer Function(Pointer);
typedef FnStartType = Pointer Function(Pointer);
typedef FnStopNativeType = Void Function(Pointer);
typedef FnStopType = void Function(Pointer);

late final FnStartType callFunctionOnNewThreadRepeatedly;
late final FnStopType callFunctionOnNewThreadStop;

void main() async {
  final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');
  callFunctionOnNewThreadRepeatedly = ffiTestFunctions
      .lookupFunction<FnStartNativeType, FnStartType>(
        'CallFunctionOnNewThreadRepeatedly',
      );
  callFunctionOnNewThreadStop = ffiTestFunctions
      .lookupFunction<FnStopNativeType, FnStopType>(
        'CallFunctionOnNewThreadStop',
      );

  final repeaters = <(Pointer, NativeCallable)>[];
  void spawn(void Function(int) callback) {
    final listener = NativeCallable<Void Function(Int32)>.listener(callback);
    final repeater = callFunctionOnNewThreadRepeatedly(listener.nativeFunction);
    repeaters.add((repeater, listener));
  }

  // Spawn one repeater, wait for it to start running, then spawn 30 more.
  final firstIsRunning = Completer<void>();
  spawn((int n) {
    if (n == 10) firstIsRunning.complete();
  });

  await firstIsRunning.future;

  for (var i = 0; i < 10; ++i) {
    spawn((int n) {});
  }

  await Future.delayed(Duration(seconds: 3));

  for (final (repeater, listener) in repeaters) {
    callFunctionOnNewThreadStop(repeater);
    listener.close();
  }
}
