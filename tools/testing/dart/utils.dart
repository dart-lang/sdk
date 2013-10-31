// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:io';
import 'dart:math' show min;
import 'dart:convert';

part 'legacy_path.dart';

class DebugLogger {
  static IOSink _sink;

  /**
   * If [path] was null, the DebugLogger will write messages to stdout.
   */
  static init(Path path, {append: false}) {
    if (path != null) {
      var mode = append ? FileMode.APPEND : FileMode.WRITE;
      _sink = new File(path.toNativePath()).openWrite(mode: mode);
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
    // with the Dart sources is updated, pass a trace parameter too and do:
    // if (trace != null) msg += "\nStackTrace: $trace";
    return msg;
  }
  static void info(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("$_datetime Info: $msg");
  }

  static void warning(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("$_datetime Warning: $msg");
  }

  static void error(String msg, [error]) {
    msg = _formatErrorMessage(msg, error);
    _print("$_datetime Error: $msg");
  }

  static void _print(String msg) {
    if (_sink != null) {
      _sink.writeln(msg);
    } else {
      print(msg);
    }
  }

  static String get _datetime => "${new DateTime.now()}";
}


/**
 * [areByteArraysEqual] compares a range of bytes from [buffer1] with a
 * range of bytes from [buffer2].
 *
 * Returns [true] if the [count] bytes in [buffer1] (starting at
 * [offset1]) match the [count] bytes in [buffer2] (starting at
 * [offset2]).
 * Otherwise [false] is returned.
 */
bool areByteArraysEqual(List<int> buffer1, int offset1,
                        List<int> buffer2, int offset2,
                        int count) {
  if ((offset1 + count) > buffer1.length ||
      (offset2 + count) > buffer2.length) {
    return false;
  }

  for (var i = 0; i < count; i++) {
    if (buffer1[offset1 + i] != buffer2[offset2 + i]) {
      return false;
    }
  }
  return true;
}

/**
 * [findBytes] searches for [pattern] in [data] beginning at [startPos].
 *
 * Returns [true] if [pattern] was found in [data].
 * Otherwise [false] is returned.
 */
int findBytes(List<int> data, List<int> pattern, [int startPos=0]) {
  // TODO(kustermann): Use one of the fast string-matching algorithms!
  for (int i = startPos; i < (data.length - pattern.length); i++) {
    bool found = true;
    for (int j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        found = false;
        break;
      }
    }
    if (found) {
      return i;
    }
  }
  return -1;
}

List<int> encodeUtf8(String string) {
  return UTF8.encode(string);
}

// TODO(kustermann,ricow): As soon we have a debug log we should log
// invalid utf8-encoded input to the log.
// Currently invalid bytes will be replaced by a replacement character.
String decodeUtf8(List<int> bytes) {
  return UTF8.decode(bytes, allowMalformed: true);
}

class Locations {
  static String getDartiumLocation(Map globalConfiguration) {
    var dartium = globalConfiguration['dartium'];
    if (dartium != null && dartium != '') {
      return dartium;
    }
    if (Platform.operatingSystem == 'macos') {
      return new Path('client/tests/dartium/Chromium.app/Contents/'
          'MacOS/Chromium').toNativePath();
    }
    return new Path('client/tests/dartium/chrome').toNativePath();
  }
}

// This function is pretty stupid and only puts quotes around an argument if
// it the argument contains a space.
String escapeCommandLineArgument(String argument) {
  if (argument.contains(' ')) {
    return '"$argument"';
  }
  return argument;
}

class HashCodeBuilder {
  int _value = 0;

  void add(Object object) {
    _value = ((_value * 31) ^ object.hashCode)  & 0x3FFFFFFF;
  }

  int get value => _value;
}

class UniqueObject {
  static int _nextId = 1;
  final int _hashCode;

  int get hashCode => _hashCode;
  operator==(other) => other is UniqueObject && _hashCode == other._hashCode;

  UniqueObject() : _hashCode = ++_nextId;
}
