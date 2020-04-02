// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/exception/exception.dart';
import 'package:logging/logging.dart';

import 'input_converter.dart';
import 'operation.dart';

const CONNECTED_MSG_FRAGMENT = ' <= {"event":"server.connected"';
const RECEIVED_FRAGMENT = ' <= {';
const SENT_FRAGMENT = ' => {';
final int NINE = '9'.codeUnitAt(0);
final int ZERO = '0'.codeUnitAt(0);

/// [LogFileInputConverter] converts a log file stream
/// into a series of operations to be sent to the analysis server.
class LogFileInputConverter extends CommonInputConverter {
  LogFileInputConverter(String tmpSrcDirPath, PathMap srcPathMap)
      : super(tmpSrcDirPath, srcPathMap);

  @override
  Operation convert(String line) {
    try {
      var timeStampString = _parseTimeStamp(line);
      var data = line.substring(timeStampString.length);
      if (data.startsWith(RECEIVED_FRAGMENT)) {
        var jsonData = asMap(json.decode(data.substring(4)));
        if (jsonData.containsKey('event')) {
          return convertNotification(jsonData);
        } else {
          return convertResponse(jsonData);
        }
      } else if (data.startsWith(SENT_FRAGMENT)) {
        var jsonData = asMap(json.decode(data.substring(4)));
        if (jsonData.containsKey('method')) {
          return convertRequest(jsonData);
        }
        return null;
      }
      logger.log(Level.INFO, 'unknown input line: $line');
      return null;
    } catch (e, s) {
      throw AnalysisException(
          'Failed to parse line\n  $line', CaughtException(e, s));
    }
  }

  /// Determine if the given line is from an instrumentation file.
  /// For example:
  /// `1428347977499 <= {"event":"server.connected","params":{"version":"1.6.0"}}`
  static bool isFormat(String line) {
    var timeStampString = _parseTimeStamp(line);
    var start = timeStampString.length;
    var end = start + CONNECTED_MSG_FRAGMENT.length;
    return (10 < start && end < line.length) &&
        line.substring(start, end) == CONNECTED_MSG_FRAGMENT;
  }

  /// Parse the given line and return the millisecond timestamp or `null`
  /// if it cannot be determined.
  static String _parseTimeStamp(String line) {
    var index = 0;
    while (index < line.length) {
      var code = line.codeUnitAt(index);
      if (code < ZERO || NINE < code) {
        return line.substring(0, index);
      }
      ++index;
    }
    return line;
  }
}
