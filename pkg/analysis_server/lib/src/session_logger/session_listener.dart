// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/process_id.dart';

/// A listener that will receive information about the analysis server session.
abstract class SessionListener {
  /// Adds normalization replacements for the package roots.
  ///
  /// The [packageRoots] maps package names to package root paths.
  void addPackageRoots({
    required int index,
    required Map<String, Uri> packageRoots,
  });

  /// Log that the given [arguments] were included on the command-line.
  void logCommandLine({required List<String> arguments});

  /// Log that the given [arguments] were included on the command-line.
  void logException({
    required Object exception,
    StackTrace? stackTrace,
    List<Object>? attachments,
  });

  /// Log unstructured text information for debugging purposes.
  void logInfo(String message);

  /// Logs that the given [message] was sent [from] one process [to] another.
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  });

  /// Shuts down the listener.
  Future<void> shutdown();
}
