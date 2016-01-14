// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.incremental_logger;

/**
 * The shared instance of [Logger] used by several incremental resolution
 * classes. It is initialized externally by the Analysis Engine client.
 */
Logger logger = NULL_LOGGER;

/**
 * An instance of [Logger] that does not print anything.
 */
final Logger NULL_LOGGER = new _NullLogger();

/**
 * An instance of [Logger] that uses `print` for output.
 */
final Logger PRINT_LOGGER = new StringSinkLogger(new _PrintStringSink());

/**
 * A simple hierarchical logger.
 */
abstract class Logger {
  /**
   * Mark an enter to a new section with the given [name].
   */
  void enter(String name);

  /**
   * Mark an exit from the current sections, logs the duration.
   */
  void exit();

  /**
   * Logs the given [obj].
   */
  void log(Object obj);

  /**
   * Logs the given [exception] and [stackTrace].
   */
  void logException(Object exception, [Object stackTrace]);

  /**
   * Starts a new timer.
   */
  LoggingTimer startTimer();
}

/**
 * The handle of a timer.
 */
class LoggingTimer {
  final Logger _logger;
  final Stopwatch _stopwatch = new Stopwatch();

  LoggingTimer(this._logger) {
    _stopwatch.start();
  }

  /**
   * This methods stop the timer and logs the elapsed time.
   */
  void stop(String message) {
    _stopwatch.stop();
    _logger.log('$message in ${_stopwatch.elapsedMilliseconds} ms');
  }
}

/**
 * A [Logger] that writes to a [StringSink].
 */
class StringSinkLogger implements Logger {
  static const int _MAX_LINE_LENGTH = 512;
  final StringSink _sink;
  final List<_LoggerSection> _sectionStack = <_LoggerSection>[];
  _LoggerSection _section = new _LoggerSection('', 'ROOT');

  StringSinkLogger(this._sink);

  @override
  void enter(String name) {
    log('+++ $name');
    _sectionStack.add(_section);
    _section = new _LoggerSection(_section.indent + '\t', name);
  }

  @override
  void exit() {
    DateTime now = new DateTime.now();
    Duration duration = now.difference(_section.start);
    String message = '--- ${_section.name} in ${duration.inMilliseconds} ms';
    _section = _sectionStack.removeLast();
    log(message);
  }

  @override
  void log(Object obj) {
    DateTime now = new DateTime.now();
    String indent = _section.indent;
    String objStr = _getObjectString(obj);
    String line = '[$now] $indent$objStr';
    _sink.writeln(line);
  }

  @override
  void logException(Object exception, [Object stackTrace]) {
    if (exception != null) {
      log(exception);
    }
    if (stackTrace != null) {
      log(stackTrace);
    }
  }

  @override
  LoggingTimer startTimer() {
    return new LoggingTimer(this);
  }

  String _getObjectString(Object obj) {
    if (obj == null) {
      return 'null';
    }
    if (obj is Function) {
      obj = obj();
    }
    String str = obj.toString();
    if (str.length < _MAX_LINE_LENGTH) {
      return str;
    }
    return str.split('\n').map((String line) {
      if (line.length > _MAX_LINE_LENGTH) {
        line = line.substring(0, _MAX_LINE_LENGTH) + '...';
      }
      return line;
    }).join('\n');
  }
}

class _LoggerSection {
  final DateTime start = new DateTime.now();
  final String indent;
  final String name;
  _LoggerSection(this.indent, this.name);
}

/**
 * A [Logger] that does nothing.
 */
class _NullLogger implements Logger {
  @override
  void enter(String name) {}

  @override
  void exit() {}

  @override
  void log(Object obj) {}

  @override
  void logException(Object exception, [Object stackTrace]) {}

  @override
  LoggingTimer startTimer() {
    return new LoggingTimer(this);
  }
}

/**
 * A [StringSink] implementation that uses `print`.
 */
class _PrintStringSink implements StringSink {
  String _line = '';

  @override
  void write(Object obj) {
    if (obj == null) {
      _line += 'null';
    } else {
      _line += obj.toString();
    }
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    _line += objects.join(separator);
  }

  @override
  void writeCharCode(int charCode) {
    _line += new String.fromCharCode(charCode);
  }

  @override
  void writeln([Object obj = '']) {
    _line += obj;
    print(_line);
    _line = '';
  }
}
