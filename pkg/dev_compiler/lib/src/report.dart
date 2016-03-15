// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/error.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'utils.dart';

final _checkerLogger = new Logger('dev_compiler.checker');

/// Collects errors, and then sorts them and sends them
class ErrorCollector implements AnalysisErrorListener {
  final AnalysisErrorListener listener;
  final List<AnalysisError> _errors = [];

  ErrorCollector(this.listener);

  /// Flushes errors to the log. Until this is called, errors are buffered.
  void flush() {
    // TODO(jmesserly): this code was taken from analyzer_cli.
    // sort errors
    _errors.sort((AnalysisError error1, AnalysisError error2) {
      // severity
      var severity1 = _strongModeErrorSeverity(error1);
      var severity2 = _strongModeErrorSeverity(error2);
      int compare = severity2.compareTo(severity1);
      if (compare != 0) return compare;

      // path
      compare = Comparable.compare(error1.source.fullName.toLowerCase(),
          error2.source.fullName.toLowerCase());
      if (compare != 0) return compare;

      // offset
      compare = error1.offset - error2.offset;
      if (compare != 0) return compare;

      // compare message, in worst case.
      return error1.message.compareTo(error2.message);
    });

    _errors.forEach(listener.onError);
    _errors.clear();
  }

  void onError(AnalysisError error) {
    _errors.add(error);
  }
}

ErrorSeverity _strongModeErrorSeverity(AnalysisError error) {
  // Upgrade analyzer warnings to errors.
  // TODO(jmesserly: reconcile this with analyzer_cli
  var severity = error.errorCode.errorSeverity;
  if (!isStrongModeError(error.errorCode) &&
      severity == ErrorSeverity.WARNING) {
    return ErrorSeverity.ERROR;
  }
  return severity;
}

/// Simple reporter that logs checker messages as they are seen.
class LogReporter implements AnalysisErrorListener {
  final AnalysisContext _context;
  final bool useColors;
  final List<AnalysisError> _errors = [];

  LogReporter(this._context, {this.useColors: false});

  void onError(AnalysisError error) {
    var level = _severityToLevel[_strongModeErrorSeverity(error)];

    // TODO(jmesserly): figure out what to do with the error's name.
    var lineInfo = _context.computeLineInfo(error.source);
    var location = lineInfo.getLocation(error.offset);

    // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
    var text = new StringBuffer()
      ..write('[${errorCodeName(error.errorCode)}] ')
      ..write(error.message)
      ..write(' (${path.prettyUri(error.source.uri)}')
      ..write(', line ${location.lineNumber}, col ${location.columnNumber})');

    // TODO(jmesserly): just print these instead of sending through logger?
    _checkerLogger.log(level, text);
  }
}

// TODO(jmesserly): remove log levels, instead just use severity.
const _severityToLevel = const {
  ErrorSeverity.ERROR: Level.SEVERE,
  ErrorSeverity.WARNING: Level.WARNING,
  ErrorSeverity.INFO: Level.INFO
};
