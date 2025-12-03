// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/session_logger/log_entry.dart';
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
class SessionLoggerInMemorySink extends SessionLoggerSink {
  /// The maximum number of entries stored in the [_sessionBuffer].
  int maxBufferLength;

  /// Whether entries should be captured in the buffer.
  bool _capturingEntries = false;

  /// A session logger to which requests should be forwarded, or `null` if there
  /// is no logger to forward requests to.
  SessionLoggerSink? nextLogger;

  /// The buffer in which initialization related entries are stored.
  final List<LogEntry> _initializationBuffer = [];

  /// The buffer in which normal entries are stored.
  final List<LogEntry> _sessionBuffer = [];

  /// Initialize a newly created sink to store up to [maxBufferLength] entries.
  SessionLoggerInMemorySink({required this.maxBufferLength});

  /// Returns a list of the entries that have been captured.
  ///
  /// The list includes necessary initialization entries that might have
  /// occurred before the capture was started.
  List<LogEntry> get capturedEntries {
    return [..._initializationBuffer, ..._sessionBuffer];
  }

  /// Whether entries are currently being captured in the buffer.
  bool get isCapturingEntries => _capturingEntries;

  @override
  Future<void> close() async {
    await nextLogger?.close();
  }

  /// Stops the capturing of entries.
  void startCapture() {
    _sessionBuffer.clear();
    _capturingEntries = true;
  }

  /// Stops the capturing of entries.
  void stopCapture() {
    _capturingEntries = false;
  }

  @override
  void writeLogEntry(JsonMap entry) {
    nextLogger?.writeLogEntry(entry);
    var logEntry = LogEntry(entry);
    if (_isInitializationEntry(logEntry)) {
      _initializationBuffer.add(logEntry);
      return;
    }
    if (_capturingEntries) {
      if (_sessionBuffer.length > maxBufferLength) {
        _sessionBuffer.removeAt(0);
      }
      _sessionBuffer.add(logEntry);
    } else {
      // TODO(brianwilkerson): We also need to collect the most recent messages
      //  related to which directories are open in the workspace and which files
      //  are priority files. These should be in separate lists so that we can
      //  flush messages that are no longer required in order to reproduce the
      //  captured messages.
    }
  }

  /// Returns whether the [entry] is an initialization entry.
  ///
  /// An initialization entry is defined as an entry that would need to be
  /// replayed in order to make the captured entries make sense.
  ///
  /// Initialization entries are captured even when [captureEntries] is `false`.
  bool _isInitializationEntry(LogEntry entry) {
    if (entry.isCommandLine) return true;
    if (entry.isMessage) {
      // TODO(brianwilkerson): This list is incomplete in two ways.
      //  1. It does not support the legacy protocol.
      //  2. It does not capture entries that indicate the state of either the
      //     workspace or the priority files.
      var message = entry.message;
      return message.isInitialize || message.isInitialized;
    }
    return false;
  }
}

/// Used to write information about a session to a log.
sealed class SessionLoggerSink {
  /// Close any resources being held by this sink.
  Future<void> close();

  /// Write the given log [entry] to this sink.
  void writeLogEntry(JsonMap entry);
}
