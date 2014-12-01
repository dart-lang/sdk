// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.logger;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
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

  @override
  void logError(String message, [CaughtException exception]) {
    if (exception == null) {
      baseLogger.severe(message);
    } else {
      baseLogger.severe(message, exception.exception, exception.stackTrace);
    }
  }

  @override
  void logError2(String message, Object exception) {
    baseLogger.severe(message, exception);
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    if (exception == null) {
      baseLogger.info(message);
    } else {
      baseLogger.info(message, exception.exception, exception.stackTrace);
    }
  }

  @override
  void logInformation2(String message, Object exception) {
    baseLogger.info(message, exception);
  }
}
