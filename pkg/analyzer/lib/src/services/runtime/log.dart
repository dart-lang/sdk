// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Simple wrapper for [Logger] library.
library runtime.log;

import "package:logging/logging.dart";

/** Log message at level [Level.FINEST]. */
void finest(String message) => _logger.log(Level.FINEST, message);

/** Log message at level [Level.FINER]. */
void finer(String message) => _logger.log(Level.FINER, message);

/** Log message at level [Level.FINE]. */
void fine(String message) => _logger.log(Level.FINE, message);

/** Log message at level [Level.CONFIG]. */
void config(String message) => _logger.log(Level.CONFIG, message);

/** Log message at level [Level.INFO]. */
void info(String message) => _logger.log(Level.INFO, message);

/** Log message at level [Level.WARNING]. */
void warning(String message) => _logger.log(Level.WARNING, message);

/** Log message at level [Level.SEVERE]. */
void severe(String message) => _logger.log(Level.SEVERE, message);

/** Log message at level [Level.SHOUT]. */
void shout(String message) => _logger.log(Level.SHOUT, message);

/// Specifies that all log records should be logged.
void everything() {
  _logger.level = Level.ALL;
}

/// Sends all log record to the console.
void toConsole() {
  _logger.onRecord.listen((LogRecord record) {
    String levelString = record.level.toString();
    while (levelString.length < 6) levelString += ' ';
    print('${record.time}: $levelString ${record.message}');
  });
}

/// The root [Logger].
final Logger _logger = Logger.root;
