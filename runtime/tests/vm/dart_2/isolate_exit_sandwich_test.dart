// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Checks that Kill message (generated for example by Isolate.exit) prevents
// any more dart code being executed - in particular when dart code with
// Isolate.exit() is invoked from native code, which in turns is invoked
// from dart code(hence "sandwich"-test).

// @dart = 2.9

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";
import '../../../../tests/ffi/dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

final lookupAndCallWorkerThatCallsIsolateExit =
    ffiTestFunctions.lookupFunction<Void Function(Int64), void Function(int)>(
        'IsolateExitTest_LookupAndCallIsolateExit');

@pragma('vm:entry-point')
void recurseLookupAndCallWorker(int i) {
  lookupAndCallWorkerThatCallsIsolateExit(i);
  print(
      'coming back after $i invocation of lookupAndCallWorkerThatCallsIsolateExit');
}

// This method is looked up and called by ffi method that ignores unwinding
// error raised by 'Isolate.exit'.
@pragma('vm:entry-point')
Never callIsolateExit() {
  Isolate.exit();
}

main(List<String> args) async {
  if (args.length > 0) {
    lookupAndCallWorkerThatCallsIsolateExit(4);
    print('got back');
    return;
  }
  ProcessResult result = await Process.run(
      Platform.executable, <String>[Platform.script.toString(), 'worker']);
  Expect.isTrue(result.exitCode != 0);
  // The child process should be terminated before it had a chance
  // to print "got back".
  Expect.isFalse(result.stdout.contains('got back'));
}
