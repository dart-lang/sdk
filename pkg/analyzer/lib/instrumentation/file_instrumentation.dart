// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/instrumentation/instrumentation.dart';

/**
 * An [InstrumentationServer] that writes to a file.
 */
class FileInstrumentationServer implements InstrumentationServer {
  final String filePath;
  IOSink _sink;

  FileInstrumentationServer(this.filePath) {
    File file = new File(filePath);
    _sink = file.openWrite();
  }

  @override
  String get describe => "file: $filePath";

  @override
  String get sessionId => '';

  @override
  void log(String message) {
    _sink.writeln(message);
  }

  @override
  void logWithPriority(String message) {
    log(message);
  }

  @override
  Future shutdown() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    await _sink.close();
    _sink = null;
  }
}
