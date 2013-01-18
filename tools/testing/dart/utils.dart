// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:io';
import 'dart:utf' as utf;

class DebugLogger {
  static OutputStream _stream;

  /**
   * If [path] was null, the DebugLogger will write messages to stdout.
   */
  static init(Path path, {append: false}) {
    if (path != null) {
      var mode = append ? FileMode.APPEND : FileMode.WRITE;
      _stream = new File.fromPath(path).openOutputStream(mode);
    }
  }

  static void close() {
    if (_stream != null) {
      _stream.close();
      _stream = null;
    }
  }

  static void info(String msg) {
    _print("Info: $msg");
  }

  static void warning(String msg) {
    _print("Warning: $msg");
  }

  static void error(String msg) {
    _print("Error: $msg");
  }

  static void _print(String msg) {
    if (_stream != null) {
      _stream.write(encodeUtf8(msg));
      _stream.write([0x0a]);
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

