// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/entry_keys.dart' as key;
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';

/// Used to write information about a session to a log.
class SessionLogger {
  /// The normalizer used to normalize paths in log entries.
  final LogNormalizer normalizer;

  /// The sink to which entries are to be written, or `null` if logging is not
  /// to be done at this point.
  final SessionLoggerSink? sink;

  /// Instantiates a [SessionLogger] which writes log entries to a
  /// [SessionLoggerInMemorySink].
  ///
  /// If [filePath] is non-`null`, it also writes log entries to a file at
  /// [filePath].
  factory SessionLogger({String? filePath}) {
    var normalizer = LogNormalizer();
    var sink = SessionLoggerInMemorySink(
      maxBufferLength: 1024,
      normalizer: normalizer,
      filePath: filePath,
    );
    return SessionLogger._(sink: sink, normalizer: normalizer);
  }

  SessionLogger._({required this.sink, required this.normalizer});

  /// Adds normalization replacements for the package roots.
  ///
  /// The [packageRoots] maps package names to package root paths.
  void addPackageRoots({
    required int index,
    required Map<String, String> packageRoots,
  }) {
    for (var MapEntry(key: packageName, value: path) in packageRoots.entries) {
      normalizer.addReplacement(
        path,
        '{{context-$index:package-root:$packageName}}',
      );
    }
  }

  /// Log that the given [arguments] were included on the command-line.
  void logCommandLine({required List<String> arguments}) {
    sink?.writeLogEntry({
      key.time: DateTime.now().millisecondsSinceEpoch,
      key.kind: EntryKind.commandLine.name,
      key.argList: arguments,
    });
  }

  /// Logs that the given [message] was sent [from] one process [to] another.
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  }) {
    if (from == ProcessId.ide && to == ProcessId.server) {
      var msg = Message(message);
      if (msg.isInitializeRequest) {
        normalizer.addWorkspaceFolderReplacements(msg);
      }
    }
    sink?.writeLogEntry({
      key.time: DateTime.now().millisecondsSinceEpoch,
      key.kind: EntryKind.message.name,
      key.sender: from.name,
      key.receiver: to.name,
      key.message: message,
    });
  }

  /// Shuts down the logger.
  Future<void> shutdown() async {
    await sink?.close();
  }
}
