// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:io';
import 'dart:async';
import 'dart:utf' as utf;

class DebugLogger {
  static IOSink _sink;

  /**
   * If [path] was null, the DebugLogger will write messages to stdout.
   */
  static init(Path path, {append: false}) {
    if (path != null) {
      var mode = append ? FileMode.APPEND : FileMode.WRITE;
      _sink = new File.fromPath(path).openWrite(mode: mode);
    }
  }

  static void close() {
    if (_sink != null) {
      _sink.close();
      _sink = null;
    }
  }

  static String _formatErrorMessage(String msg, error) {
    if (error == null) return msg;
    msg += ": $error";
    // TODO(floitsch): once the dart-executable that is bundled
    // with the Dart sources is updated, uncomment the following
    // lines.
    // var trace = getAttachedStackTrace(error);
    // if (trace != null) msg += "\nStackTrace: $trace";
    return msg;
  }
  static void info(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("Info: $msg");
  }

  static void warning(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("Warning: $msg");
  }

  static void error(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("Error: $msg");
  }

  static void _print(String msg) {
    if (_sink != null) {
      _sink.writeln(msg);
    } else {
      print(msg);
    }
  }
}

List<int> encodeUtf8(String string) {
  return utf.encodeUtf8(string);
}

// TODO(kustermann,ricow): As soon we have a debug log we should log
// invalid utf8-encoded input to the log.
// Currently invalid bytes will be replaced by a replacement character.
String decodeUtf8(List<int> bytes) {
  return utf.decodeUtf8(bytes);
}

