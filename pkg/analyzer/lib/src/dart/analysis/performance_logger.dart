// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// This class is used to gather and print performance information.
class PerformanceLog<S extends StringSink?> {
  // TODO(dantup): We only ever use `writeln` from the StringSink so this
  //  could be simplified if we just accepted a `void Function(String)` instead
  //  because it would remove the need for the StreamStrinkSink?
  final S sink;

  int _level = 0;

  PerformanceLog(this.sink);

  /// Enter a new execution section, which starts at one point of code, runs
  /// some time, and then ends at the other point of code.
  ///
  /// The client must call [PerformanceLogSection.exit] for every [enter].
  PerformanceLogSection enter(String msg) {
    writeln('+++ $msg.');
    _level++;
    return PerformanceLogSection(this, msg);
  }

  /// Return the result of the function [f] invocation and log the elapsed time.
  ///
  /// Each invocation of [run] creates a new enclosed section in the log,
  /// which begins with printing [msg], then any log output produced during
  /// [f] invocation, and ends with printing [msg] with the elapsed time.
  T run<T>(String msg, T Function() f) {
    Stopwatch timer = Stopwatch()..start();
    try {
      writeln('+++ $msg.');
      _level++;
      return f();
    } finally {
      _level--;
      int ms = timer.elapsedMilliseconds;
      writeln('--- $msg in $ms ms.');
    }
  }

  /// Return the result of the function [f] invocation and log the elapsed time.
  ///
  /// Each invocation of [run] creates a new enclosed section in the log,
  /// which begins with printing [msg], then any log output produced during
  /// [f] invocation, and ends with printing [msg] with the elapsed time.
  Future<T> runAsync<T>(String msg, Future<T> Function() f) async {
    Stopwatch timer = Stopwatch()..start();
    try {
      writeln('+++ $msg.');
      _level++;
      return await f();
    } finally {
      _level--;
      int ms = timer.elapsedMilliseconds;
      writeln('--- $msg in $ms ms.');
    }
  }

  /// Write a new line into the log.
  void writeln(String msg) {
    if (sink case var sink?) {
      String indent = '\t' * _level;
      sink.writeln('$indent$msg');
    }
  }
}

/// The performance measurement section for operations that start and end
/// at different place in code, so cannot be run using [PerformanceLog.run].
///
/// The client must call [exit] for every [PerformanceLog.enter].
class PerformanceLogSection {
  final PerformanceLog _logger;
  final String _msg;
  final Stopwatch _timer = Stopwatch()..start();

  PerformanceLogSection(this._logger, this._msg);

  /// Stop the timer, log the time.
  void exit() {
    _timer.stop();
    _logger._level--;
    int ms = _timer.elapsedMilliseconds;
    _logger.writeln('--- $_msg in $ms ms.');
  }
}
