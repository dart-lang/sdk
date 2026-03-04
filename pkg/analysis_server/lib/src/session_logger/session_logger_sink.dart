// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:language_server_protocol/protocol_special.dart' show Either2;

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
    _sink.writeln(json.encode(entry));
  }
}

/// A sink for a session logger that will write entries to an in-memory buffer.
///
/// This class has been designed to allow a user to enable the capturing of log
/// entries at an arbitrary time, and then retrieve the captured entries at some
/// future time. To support this, the sink caches entries related to
/// - server initialization,
/// - workspace configuration, and
/// - text documents
/// until capturing is enabled.
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

  /// The buffer in which workspace configuration related entries are stored.
  ///
  /// This buffer is cleared every time a new workspace configuration is
  /// requested.
  final List<LogEntry> _configurationBuffer = [];

  /// The buffer in which text document related entries are stored.
  final List<LogEntry> _textDocumentBuffer = [];

  /// The buffer in which normal entries are stored.
  final List<LogEntry> _sessionBuffer = [];

  /// Initialize a newly created sink to store up to [maxBufferLength] entries.
  SessionLoggerInMemorySink({required this.maxBufferLength});

  /// Returns a list of the entries that have been captured.
  ///
  /// The list includes necessary initialization entries that might have
  /// occurred before the capture was started.
  List<LogEntry> get capturedEntries {
    return [
      ..._initializationBuffer,
      ..._configurationBuffer,
      ..._textDocumentBuffer,
      ..._sessionBuffer,
    ];
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
      if (_isConfigurationEntry(logEntry)) {
        _configurationBuffer.add(logEntry);
      } else if (_isTextDocumentEntry(logEntry)) {
        _textDocumentBuffer.add(logEntry);
      }
    }
  }

  /// Returns the request ids of the messages in the given list of [entries].
  ///
  /// This assumes that the entries are all from the same process. If that isn't
  /// true, then the returned list may contain duplicate ids.
  List<Either2<int, String>> _getRequestIds(List<LogEntry> entries) {
    return entries
        .where((entry) => entry.isMessage)
        .map((entry) => entry.message.id)
        .nonNulls
        .toList();
  }

  /// Returns whether the [entry] is a configuration entry.
  ///
  /// A configuration entry is defined as an entry that records the
  /// configuration of the workspace.
  ///
  /// Configuration entries are captured even when [captureEntries] is `false`.
  bool _isConfigurationEntry(LogEntry entry) {
    // TODO(brianwilkerson): Make this method support the legacy protocol.
    if (entry.isMessage) {
      var message = entry.message;
      if (message.isWorkspaceConfiguration) {
        return true;
      }
      for (var requestId in _getRequestIds(_configurationBuffer)) {
        if (message.isResponseTo(requestId)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns whether the [entry] is an initialization entry.
  ///
  /// An initialization entry is defined as an entry that records the
  /// initialization process.
  ///
  /// Initialization entries are captured even when [captureEntries] is `false`.
  bool _isInitializationEntry(LogEntry entry) {
    // TODO(brianwilkerson): Make this method support the legacy protocol.
    if (entry.isCommandLine) return true;
    if (entry.isMessage) {
      var message = entry.message;
      if (message.isInitializeRequest || message.isInitialized) {
        return true;
      }
      for (var requestId in _getRequestIds(_initializationBuffer)) {
        if (message.isResponseTo(requestId)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns whether the [entry] is a text document entry.
  ///
  /// A text document entry is defined as an entry that records an operation
  /// on a text document.
  ///
  /// Text document entries are captured even when [captureEntries] is `false`.
  bool _isTextDocumentEntry(LogEntry entry) {
    if (entry.isMessage) {
      var message = entry.message;
      return message.isDidChange || message.isDidClose || message.isDidOpen;
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
