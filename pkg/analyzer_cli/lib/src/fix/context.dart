// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

/// The context for dartfix.
class Context {
  StringSink get stdout => io.stdout;
  StringSink get stderr => io.stderr;

  String get workingDir => io.Directory.current.path;

  bool exists(String filePath) =>
      io.FileSystemEntity.typeSync(filePath) !=
      io.FileSystemEntityType.notFound;

  void exit(int code) {
    io.exit(code);
  }

  bool isDirectory(String filePath) =>
      io.FileSystemEntity.typeSync(filePath) ==
      io.FileSystemEntityType.directory;

  void print([String text = '']) {
    stdout.writeln(text);
  }
}
