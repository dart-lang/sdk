// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

String getSourceMapFilePath(String testName, int moduleId) {
  final compilationDir = const String.fromEnvironment('TEST_COMPILATION_DIR');
  if (moduleId == 0) {
    return '$compilationDir/${testName}_test.wasm.map';
  } else {
    return '$compilationDir/${testName}_test_module$moduleId.wasm.map';
  }
}

/// Read the file at the given [path].
///
/// This relies on the `readbuffer` function provided by d8.
@JS()
external JSArrayBuffer readbuffer(JSString path);

/// Read the file at the given [path].
Uint8List readfile(String path) => Uint8List.view(readbuffer(path.toJS).toDart);
