// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A string sink that write into a file.
class FileStringSink implements StringSink {
  IOSink _sink;

  FileStringSink(String path) {
    _sink = File(path).openWrite(mode: FileMode.append);
  }

  @override
  void write(Object obj) {
    throw UnimplementedError();
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    throw UnimplementedError();
  }

  @override
  void writeCharCode(int charCode) {
    throw UnimplementedError();
  }

  @override
  void writeln([Object obj = '']) {
    var currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    _sink.writeln('$currentTimeMillis $obj');
  }
}
