// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analyzer/file_system/file_system.dart';

/// The content of a log file.
class Log {
  /// The entries in the log.
  final List<LogEntry> entries;

  /// Creates a log by reading the content of the [file] and decoding it as a
  /// list of entries.
  factory Log.fromFile(File file, Map<String, String> replacements) {
    return Log.fromString(file.readAsStringSync(), replacements);
  }

  /// Creates a log by decoding the [logContent] as a list of entries.
  ///
  /// The [logContent] should be a newline separated list of encoded [LogEntry]
  /// objects matching typical stdio communication patterns.
  ///
  /// Each entry in [replacements] is all occurences of the key replaced with
  /// the value.
  factory Log.fromString(String logContent, Map<String, String> replacements) {
    for (var entry in replacements.entries) {
      logContent = logContent.replaceAll(entry.key, entry.value);
    }
    var lines = const LineSplitter().convert(logContent);
    return Log._([
      for (var line in lines) LogEntry(json.decode(line) as JsonMap),
    ]);
  }

  Log._(this.entries);
}
