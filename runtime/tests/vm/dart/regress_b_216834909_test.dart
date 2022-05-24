// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// Regression test for b/216834909.
//
// Check that subprocess spawning implementation uses _exit rather than exit on
// paths which terminate fork child without exec-ing.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";
import '../../../../tests/ffi/dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

final setAtExit =
    ffiTestFunctions.lookupFunction<Void Function(Int64), void Function(int)>(
        'Regress216834909_SetAtExit');

main(List<String> args) async {
  // We only care about platforms which use fork/exec.
  if (!Platform.isLinux && !Platform.isAndroid && !Platform.isMacOS) {
    return;
  }
  setAtExit(1); // Install at exit handler.
  await Process.start('true', [], mode: ProcessStartMode.detached);
  setAtExit(0); // Clear at exit handler.
}
