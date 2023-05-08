// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test for unhandled exception treatment on Windows.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'dylib_utils.dart';

void main(List<String> args) async {
  // Test exercises JIT, Windows-only functionality.
  if (!Platform.isWindows) return;
  if (path.basenameWithoutExtension(Platform.executable) ==
      'dart_precompiled_runtime') return;
  if (args.length == 0) {
    asyncStart();
    final results = await Process.run(
        Platform.resolvedExecutable,
        // Prevent Crashpad from catching the exception.
        environment: {'DART_CRASHPAD_HANDLER': ''},
        [...Platform.executableArguments, Platform.script.toString(), 'run']);
    Expect.notEquals(0, results.exitCode);
    print('exitCode: ${results.exitCode}');
    print('stdout: ${results.stdout}');
    print('stderr: ${results.stderr}');
    Expect.contains('===== CRASH =====', results.stderr);
    asyncEnd();
  } else {
    final d = dlopenPlatformSpecific('ffi_test_functions');
    final induceACrash =
        d.lookupFunction<Void Function(), void Function()>('InduceACrash');
    induceACrash();
  }
}
