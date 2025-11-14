// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analyzer/file_system/file_system.dart';

/// The content of a log file.
class Log {
  /// The entries in the log.
  final List<LogEntry> entries;

  /// Creates a log by reading the content of the [file] and decoding it as a
  /// list of entries.
  factory Log.fromFile(File file) {
    return Log.fromString(file.readAsStringSync());
  }

  /// Creates a log by decoding the [logContent] as a list of entries.
  ///
  /// The [logContent] should not include the opening and closing delimiters
  /// for a Json array ('[' and ']'), but otherwise should be a comma-separated
  /// list of json-encoded log entries.
  factory Log.fromString(String logContent) {
    logContent = logContent.trim();
    if (logContent.endsWith(',')) {
      logContent = logContent.substring(0, logContent.length - 1);
    }
    var list = json.decode('[$logContent]') as List<dynamic>;
    return Log._(list.cast<LogEntry>().toList());
  }

  Log._(this.entries);
}
