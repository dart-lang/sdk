// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/session_logger/process_id.dart';

/// A sink for a session logger that will write entries to a file.
class SessionLoggerFileSink extends SessionLoggerSink {
  /// The sink used to write to the file.
  late final IOSink _sink;

  /// Initialize a newly created sink to write to the file at the given
  /// [filePath].
  SessionLoggerFileSink(String filePath) {
    File file = File(filePath);
    _sink = file.openWrite();
  }

  @override
  Future<void> close() async {
    await _sink.close();
  }

  @override
  void writeLogEntry(JsonMap entry) {
    var logEntry = json.encode(entry);
    _sink.writeln('$logEntry,');
  }
}

/// A sink for a session logger that will write entries to an in-memory buffer.
class SessionLoggerMemorySink extends SessionLoggerSink {
  /// The maximum number of entries stored in the [buffer].
  int maxBufferLength;

  /// The buffer in which entries are stored.
  List<JsonMap> buffer = [];

  /// Initialize a newly created sink to store up to [maxBufferLength] entries.
  SessionLoggerMemorySink(this.maxBufferLength);

  @override
  Future<void> close() async {
    // There's nothing to do in this case.
  }

  @override
  void writeLogEntry(JsonMap entry) {
    if (buffer.length > maxBufferLength) {
      buffer.removeAt(0);
    }
    buffer.add(entry);
  }
}

/// Used to write information about a session to a log.
sealed class SessionLoggerSink {
  /// Close any resources being held by this sink.
  Future<void> close();

  /// Write the given log [entry] to this sink.
  void writeLogEntry(JsonMap entry);
}
