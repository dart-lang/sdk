// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_logger;


/**
 * The shared instance of [Logger] used by several incremental resolution
 * classes. It is initialized externally by the Analysis Engine client.
 */
Logger logger = new NullLogger();


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
}


/**
 * A [Logger] that does nothing.
 */
class NullLogger implements Logger {
  @override
  void enter(String name) {
  }

  @override
  void exit() {
  }

  @override
  void log(Object obj) {
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

  String _getObjectString(Object obj) {
    if (obj == null) {
      return 'null';
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
