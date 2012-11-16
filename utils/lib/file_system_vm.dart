// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Investigate common library for file I/O shared between frog and tools.

library file_system_vm;
import 'dart:io';
import 'file_system.dart';
import 'dart:utf';

/** File system implementation using the vm api's. */
class VMFileSystem implements FileSystem {
  void writeString(String path, String text) {
    var file = new File(path).openSync(FileMode.WRITE);
    file.writeStringSync(text);
    file.closeSync();
  }

  String readAll(String filename) {
    var file = (new File(filename)).openSync();
    var length = file.lengthSync();
    var buffer = new List<int>(length);
    var bytes = file.readListSync(buffer, 0, length);
    file.closeSync();
    return new String.fromCharCodes(new Utf8Decoder(buffer).decodeRest());
  }

  bool fileExists(String filename) {
    return new File(filename).existsSync();
  }

  void createDirectory(String path, [bool recursive = false]) {
    // TODO(rnystrom): Implement.
    throw 'createDirectory() is not implemented by VMFileSystem yet.';
  }

  void removeDirectory(String path, [bool recursive = false]) {
    // TODO(rnystrom): Implement.
    throw 'removeDirectory() is not implemented by VMFileSystem yet.';
  }
}
