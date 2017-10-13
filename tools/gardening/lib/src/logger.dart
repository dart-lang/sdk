// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

enum Level { debug, info, warning, error }

abstract class Logger {
  Level level;

  Logger(this.level);

  void info(String msg, [error, StackTrace stackTrace]);
  void warning(String msg, [error, StackTrace stackTrace]);
  void error(String msg, [error, StackTrace stackTrace]);
  void debug(String msg, [error, StackTrace stackTrace]);

  void destroy();
}

String _formatErrorMessage(String msg, error, [StackTrace stackTrace]) {
  if (error == null) return msg;
  if (stackTrace == null) return msg + ": $error";
  return msg + ": $error\n$stackTrace";
}

class StdOutLogger extends Logger {
  StdOutLogger(Level level) : super(level);

  @override
  void info(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.info, "$_datetime Info: $msg");
  }

  @override
  void warning(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.warning, "$_datetime Warning: $msg");
  }

  @override
  void error(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.error, "$_datetime Error: $msg");
  }

  @override
  void debug(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.debug, "$_datetime Debug: $msg");
  }

  void _print(Level logLevel, String msg) {
    if (logLevel.index >= level.index) {
      print(msg);
    }
  }

  @override
  void destroy() {
    // nothing to do
  }

  String get _datetime => "${new DateTime.now()}";
}

class FileLogger extends Logger {
  IOSink _sink;

  FileLogger(String fileName, Level level, {bool append: false})
      : super(level) {
    var mode = append ? FileMode.APPEND : FileMode.WRITE;
    _sink = new File(path.absolute(fileName)).openWrite(mode: mode);
  }

  @override
  void destroy() {
    if (_sink != null) {
      _sink.close();
      _sink = null;
    }
  }

  @override
  void info(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.info, "$_datetime Info: $msg");
  }

  @override
  void warning(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.warning, "$_datetime Warning: $msg");
  }

  @override
  void error(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.error, "$_datetime Error: $msg");
  }

  @override
  void debug(String msg, [error, stackTrace]) {
    msg = _formatErrorMessage(msg, error, stackTrace);
    _print(Level.debug, "$_datetime Debug: $msg");
  }

  void _print(Level logLevel, String msg) {
    if (logLevel.index >= level.index && _sink != null) _sink.writeln(msg);
  }

  static String get _datetime => "${new DateTime.now()}";
}
