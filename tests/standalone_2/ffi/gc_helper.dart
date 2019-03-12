// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dylib_utils.dart';
import 'dart:ffi';

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

// Requires --verbose-gc.
class GCWatcher {
  int _suffix;

  Future<int> size() async {
    return await File("/tmp/captured_stderr_$_suffix").length();
  }

  GCWatcher() {
    print("Starting...");
    _suffix = ffiTestFunctions
        .lookupFunction<Int32 Function(), int Function()>("RedirectStderr")();
  }

  dispose() => File("/tmp/captured_stderr_$_suffix").deleteSync();
}
