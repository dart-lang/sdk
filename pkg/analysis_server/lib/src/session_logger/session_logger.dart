// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/entry_keys.dart' as key;
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';

/// Used to write information about a session to a log.
class SessionLogger {
  /// The sink to which entries are to be written, or `null` if logging is not
  /// to be done at this point.
  SessionLoggerSink? sink;

  /// Log that the given [arguments] were included on the command-line.
  void logCommandLine({required List<String> arguments}) {
    sink?.writeLogEntry({
      key.time: DateTime.now().millisecondsSinceEpoch,
      key.kind: EntryKind.commandLine.name,
      key.argList: arguments,
    });
  }

  /// Log that the given [message] was sent [from] one process [to] another.
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  }) {
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
