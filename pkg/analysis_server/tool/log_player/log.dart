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
  ///
  /// [denormalizer] will be called on the content to reverse any normalization
  /// that was applied to the log.
  factory Log.fromFile(File file, String Function(String) denormalizer) {
    return Log.fromString(file.readAsStringSync(), denormalizer);
  }

  /// Creates a log by decoding the [logContent] as a list of entries.
  ///
  /// The [logContent] should be a newline separated list of encoded [LogEntry]
  /// objects matching typical stdio communication patterns.
  ///
  /// [denormalizer] will be called on the content to reverse any normalization
  /// that was applied to the log.
  factory Log.fromString(
    String logContent, [
    String Function(String)? denormalizer,
  ]) {
    if (denormalizer != null) {
      logContent = denormalizer(logContent);
    }
    var lines = const LineSplitter().convert(logContent);
    return Log._([
      for (var line in lines) LogEntry(json.decode(line) as JsonMap),
    ]);
  }

  Log._(this.entries);
}
