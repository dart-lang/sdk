// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/entry_keys.dart' as key;
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analysis_server/src/session_logger/session_listener.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/// Used to write information about a session to a log.
class SessionLogger implements SessionListener {
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
  factory({String? filePath}) {
    var normalizer = LogNormalizer();
    var sink = SessionLoggerInMemorySink(
      maxBufferLength: 1024,
      normalizer: normalizer,
      sessionLogFilePath: filePath,
    );
    return SessionLogger._(sink: sink, normalizer: normalizer);
  }

  new _({required this.sink, required this.normalizer});

  @override
  void addPackageRoots({
    required int index,
    required Map<String, Uri> packageRoots,
  }) {
    for (var MapEntry(key: packageName, value: uri) in packageRoots.entries) {
      normalizer.addReplacementsForUri(
        uri,
        'context-$index:package-root:$packageName',
      );
    }
  }

  @override
  void logCommandLine({required List<String> arguments}) {
    sink?.writeLogEntry({
      key.time: DateTime.now().millisecondsSinceEpoch,
      key.kind: EntryKind.commandLine.name,
      key.argList: arguments,
    });
  }

  @override
  void logException({
    required Object exception,
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  }) {
    // TODO(brianwilkerson): `InstrumentationService` is defined in the
    //  `analyzer` package and is used in several places to report exceptions.
    //  Those eceptions are not currently being recorded. There are two possible
    //  paths:
    //  - move `SessionLogger` to the analyzer package
    //  - pass in an `InstrumentationService` that forwards exceptions to a
    //    session logger
    sink?.writeLogEntry({
      key.time: DateTime.now().millisecondsSinceEpoch,
      key.kind: EntryKind.exception.name,
      key.message: exception.toString(),
      key.stackTrace: ?stackTrace?.toString(),
      key.attachments: ?attachments
          ?.map(
            (attachment) => {
              'id': attachment.id,
              'stringValue': attachment.stringValue,
            },
          )
          .toList(),
      key.nestedException: ?_nestedException(exception),
    });
  }

  @override
  void logInfo(String message) {
    sink?.writeLogEntry({
      key.time: DateTime.now().millisecondsSinceEpoch,
      key.kind: EntryKind.info.name,
      key.message: message,
    });
  }

  @override
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  }) {
    if (from == ProcessId.ide && to == ProcessId.server) {
      var msg = Message(message);
      if (msg.isInitializeRequest) {
        normalizer.addLspWorkspaceReplacements(msg);
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

  @override
  Future<void> shutdown() async {
    await sink?.close();
  }

  /// Returns a map representing the exception nested inside the [exception]
  /// when the [exception] is a [CaughtException].
  Map<String, Object>? _nestedException(Object exception) {
    if (exception is CaughtException) {
      var nestedException = exception.exception;
      var stackTrace = nestedException is CaughtException
          ? nestedException.stackTrace
          : null;
      return {
        key.message: nestedException.toString(),
        key.stackTrace: ?stackTrace?.toString(),
        key.nestedException: ?_nestedException(nestedException),
      };
    }
    return null;
  }
}
