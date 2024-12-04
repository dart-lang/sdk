// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library used by dynamic module tests to simulate the loading process and
/// provide information to the test harness.
library;

import 'dart:typed_data' show Uint8List;

import 'package:dynamic_modules/dynamic_modules.dart';

import 'read_bytes.dart' if (dart.library.io) 'read_bytes_aot.dart';

/// Load a module and invoke it's entrypoint.
///
/// The module is identified by the name of its entrypoint file within the
/// `modules/` subfolder.
///
/// Optional [transformBytes] callback can be used to tweak dynamic modules
/// bytes if underlying implementation loads dynamic modules from bytes.
Future<Object?> load(String moduleName,
    {Uint8List Function(Uint8List)? transformBytes}) {
  if (const bool.fromEnvironment('dart.library.html')) {
    // DDC implementation
    return loadModuleFromUri(Uri(scheme: '', path: moduleName));
  }
  if (const bool.fromEnvironment('dart.library.io')) {
    var bytes = readBytes('modules/$moduleName.bytecode');
    if (transformBytes != null) {
      bytes = transformBytes(bytes);
    }
    return loadModuleFromBytes(bytes);
  }
  throw "load is not implemented for dart2wasm";
}

/// Notify the test harness that the test has run to completion.
void done() {
  print(successToken);
}

/// Token used by the tests to ensure they are run to completion. This mimics
/// a similar 'unit-test-done` token used by the langugage test framework.
///
/// Unit tests should call [done]. This constant is public only to ensure the
/// token is shared with the test runner, but it is not meant to be used
/// directly by tests.
const successToken = 'TOKEN!**ALL TEST EXECUTED**!!';
