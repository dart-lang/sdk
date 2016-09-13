// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.logger;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:logging/logging.dart' as logging;

/**
 * Instances of the class [AnalysisLogger] translate from the analysis engine's
 * API to the logging package's API.
 */
class AnalysisLogger implements Logger {
  /**
   * The underlying logger that is being wrapped.
   */
  final logging.Logger baseLogger = new logging.Logger('analysis.server');

  /**
   * The analysis server that is using this logger.
   */
  final AnalysisServer server;

  AnalysisLogger(this.server) {
    assert(server != null);
    logging.Logger.root.onRecord.listen((logging.LogRecord record) {
      AnalysisEngine.instance.instrumentationService.logLogEntry(
          record.level.name,
          record.time,
          record.message,
          record.error,
          record.stackTrace);
    });
  }

  @override
  void logError(String message, [CaughtException exception]) {
    if (exception == null) {
      baseLogger.severe(message);
    } else {
      baseLogger.severe(message, exception.exception, exception.stackTrace);
    }
    server.sendServerErrorNotification(message, exception, null);
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    if (exception == null) {
      baseLogger.info(message);
    } else {
      baseLogger.info(message, exception.exception, exception.stackTrace);
    }
  }
}
