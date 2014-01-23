// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.logger;

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

  @override
  void logError(String message) {
    baseLogger.severe(message);
  }

  @override
  void logError2(String message, Exception exception) {
    baseLogger.severe(message, exception);
  }

  @override
  void logError3(Exception exception) {
    baseLogger.severe("Exception", exception);
  }

  @override
  void logInformation(String message) {
    baseLogger.info(message);
  }

  @override
  void logInformation2(String message, Exception exception) {
    baseLogger.info(message, exception);
  }

  @override
  void logInformation3(String message, Exception exception) {
    baseLogger.info(message, exception);
  }
}
