// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'filesystem_base.dart';

class WasmCompilerFileSystem extends WasmCompilerFileSystemBase {
  @override
  Uint8List? tryReadBytesSync(String relativePath) {
    try {
      return File(relativePath).readAsBytesSync();
    } catch (_) {
      print('-> failed to load $relativePath');
      return null;
    }
  }

  @override
  void writeBytesSync(String filename, Uint8List bytes) {
    File(filename).writeAsBytesSync(bytes);
  }
}
