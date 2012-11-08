// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Investigate common library for file I/O shared between frog and tools.

library file_system_memory;

import 'file_system.dart';

/**
 * [FileSystem] implementation a memory buffer.
 */
class MemoryFileSystem implements FileSystem {
  StringBuffer buffer;

  MemoryFileSystem() : this.buffer = new StringBuffer();

  void writeString(String outfile, String text) {
    buffer.add(text);
  }

  String readAll(String filename) {
    return buffer.toString();
  }

  bool fileExists(String filename) {
    return true;
  }

  void createDirectory(String path, [bool recursive]) {
    // TODO(terry): To be implement.
    throw 'createDirectory() is not implemented by MemoryFileSystem yet.';
  }

  void removeDirectory(String path, [bool recursive]) {
    // TODO(terry): To be implement.
    throw 'removeDirectory() is not implemented by MemoryFileSystem yet.';
  }
}
