// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Used to write information about a performance to a log.
class PerformanceLogger {
  /// The sink to which entries are to be written, or `null` if logging is not
  /// to be done at this point.
  late final IOSink _sink;

  PerformanceLogger(String filePath) {
    _sink = File(filePath).openWrite();
  }

  /// Write the given [data] to the log file.
  void logMap(Map<String, Object?> data) {
    _sink.writeln(json.encode(data));
  }

  /// Shuts down the logger.
  Future<void> shutdown() async {
    await _sink.flush();
    await _sink.close();
  }
}
