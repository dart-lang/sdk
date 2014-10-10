// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:io';
import 'dart:math' show min;
import 'dart:convert';

part 'legacy_path.dart';

// This is the maximum time we expect stdout/stderr of subprocesses to deliver
// data after we've got the exitCode.
const Duration MAX_STDIO_DELAY = const Duration(seconds: 30);

String MAX_STDIO_DELAY_PASSED_MESSAGE =
"""Not waiting for stdout/stderr from subprocess anymore 
($MAX_STDIO_DELAY passed). Please note that this could be an indicator 
that there is a hanging process which we were unable to kill.""";

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

String prettifyJson(Object json, {int startIndentation: 0, int shiftWidth: 6}) {
  int currentIndentation = startIndentation;
  var buffer = new StringBuffer();

  String indentationString() {
    return new List.filled(currentIndentation, ' ').join('');
  }

  addString(String s, {bool indentation: true, bool newLine: true}) {
    if (indentation) {
      buffer.write(indentationString());
    }
    buffer.write(s.replaceAll("\n", "\n${indentationString()}"));
    if (newLine) buffer.write("\n");
  }

  prettifyJsonInternal(
      Object obj, {bool indentation: true, bool newLine: true}) {
    if (obj is List) {
      addString("[", indentation: indentation);
      currentIndentation += shiftWidth;
      for (var item in obj) {

        prettifyJsonInternal(item, indentation: indentation, newLine: false);
        addString(",", indentation: false);
      }
      currentIndentation -= shiftWidth;
      addString("]", indentation: indentation);
    } else if (obj is Map) {
      addString("{", indentation: indentation);
      currentIndentation += shiftWidth;
      for (var key in obj.keys) {
        addString("$key: ", indentation: indentation, newLine: false);
        currentIndentation += shiftWidth;
        prettifyJsonInternal(obj[key], indentation: false);
        currentIndentation -= shiftWidth;
      }
      currentIndentation -= shiftWidth;
      addString("}", indentation: indentation, newLine: newLine);
    } else {
      addString("$obj", indentation: indentation, newLine: newLine);
    }
  }
  prettifyJsonInternal(json);
  return buffer.toString();
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
  static String getBrowserLocation(String browserName,
                                   Map globalConfiguration) {
    var location = globalConfiguration[browserName];
    if (location != null && location != '') {
      return location;
    }
    var browserLocations = {
        'firefox': const {
          'windows': 'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe',
          'linux': 'firefox',
          'macos': '/Applications/Firefox.app/Contents/MacOS/firefox'
        },
        'chrome': const {
          'windows':
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
          'macos':
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
          'linux': 'google-chrome'
        },
        'dartium': const {
          'windows': 'client\\tests\\dartium\\chrome.exe',
          'macos': 'client/tests/dartium/Chromium.app/Contents/MacOS/Chromium',
          'linux': 'client/tests/dartium/chrome'
        },
        'safari': const {
          'macos': '/Applications/Safari.app/Contents/MacOS/Safari'
        },
        'safarimobilesim': const {
          'macos': '/Applications/Xcode.app/Contents/Developer/Platforms/'
                   'iPhoneSimulator.platform/Developer/Applications/'
                   'iPhone Simulator.app/Contents/MacOS/iPhone Simulator'
        },
        'ie9': const {
          'windows': 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
        },
        'ie10': const {
          'windows': 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
        },
        'ie11': const {
          'windows': 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
        }};
    browserLocations['ff'] = browserLocations['firefox'];

    assert(browserLocations[browserName] != null);
    location = browserLocations[browserName][Platform.operatingSystem];
    if (location != null) {
      return location;
    } else {
      throw '$browserName not supported on ${Platform.operatingSystem}';
    }
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

  void addJson(Object object) {
    if (object == null || object is num || object is String ||
                  object is Uri || object is bool) {
      add(object);
    } else if (object is List) {
      object.forEach(addJson);
    } else if (object is Map) {
      for (var key in object.keys.toList()..sort()) {
        addJson(key);
        addJson(object[key]);
      }
    } else {
      throw new Exception("Can't build hashcode for non json-like object "
          "(${object.runtimeType})");
    }
  }

  int get value => _value;
}

bool deepJsonCompare(Object a, Object b) {
  if (a == null || a is num || a is String) {
    return a == b;
  } else if (a is List) {
    if (b is List) {
      if (a.length != b.length) return false;

      for (int i = 0; i < a.length; i++) {
        if (!deepJsonCompare(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
  } else if (a is Map) {
    if (b is Map) {
      if (a.length != b.length) return false;

      for (var key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!deepJsonCompare(a[key], b[key])) return false;
      }
      return true;
    }
    return false;
  } else {
    throw new Exception("Can't compare two non json-like objects "
        "(a: ${a.runtimeType}, b: ${b.runtimeType})");
  }
}

class UniqueObject {
  static int _nextId = 1;
  final int _hashCode;

  int get hashCode => _hashCode;
  operator==(other) => other is UniqueObject && _hashCode == other._hashCode;

  UniqueObject() : _hashCode = ++_nextId;
}
