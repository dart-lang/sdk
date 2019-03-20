// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dylib_utils.dart';
import 'dart:ffi';
import 'dart:io' show Platform;

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

abstract class GCWatcher {
  factory GCWatcher() => _GCWatcherImpl();
  factory GCWatcher.dummy() => _MockGCWatcher();
  factory GCWatcher.ifAvailable() => (Platform.isWindows || Platform.isAndroid)
      ? GCWatcher.dummy()
      : GCWatcher();

  Future<int> size();
  void dispose();
}

// Requires --verbose-gc.
class _GCWatcherImpl implements GCWatcher {
  int _suffix;

  Future<int> size() async {
    return await File("/tmp/captured_stderr_$_suffix").length();
  }

  _GCWatcherImpl() {
    print("Starting...");
    _suffix = ffiTestFunctions
        .lookupFunction<Int32 Function(), int Function()>("RedirectStderr")();
  }

  dispose() {
    try {
      File("/tmp/captured_stderr_$_suffix").deleteSync();
    } catch (e) {
      print("deleting file failed");
    }
  }
}

class _MockGCWatcher implements GCWatcher {
  int _ctr = 0;

  Future<int> size() async => ++_ctr;
  dispose() {}
}
