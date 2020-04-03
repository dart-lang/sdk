// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

/// The context for dartfix.
class Context {
  String get workingDir => io.Directory.current.path;

  bool exists(String filePath) {
    return io.FileSystemEntity.typeSync(filePath) !=
        io.FileSystemEntityType.notFound;
  }

  void exit(int code) {
    io.exit(code);
  }

  bool isDirectory(String filePath) {
    return io.FileSystemEntity.typeSync(filePath) ==
        io.FileSystemEntityType.directory;
  }
}
