// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file_instrumentation;

import 'dart:io';

import 'package:analyzer/instrumentation/instrumentation.dart';

/**
 * An [InstrumentationServer] that writes to a file.
 */
class FileInstrumentationServer implements InstrumentationServer {
  IOSink _sink;

  FileInstrumentationServer(String path) {
    File file = new File(path);
    _sink = file.openWrite();
  }

  @override
  void log(String message) {
    _sink.writeln(message);
  }

  @override
  void logWithPriority(String message) {
    log(message);
  }

  @override
  void shutdown() {
    _sink.close();
    _sink = null;
  }
}
