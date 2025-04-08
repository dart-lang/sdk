// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/exception/exception.dart';
import 'package:logging/logging.dart';

import 'input_converter.dart';
import 'operation.dart';

/// [LogFileInputConverter] converts a log file stream
/// into a series of operations to be sent to the analysis server.
class LogFileInputConverter extends CommonInputConverter {
  static const _connectedMsgFragment = ' <= {"event":"server.connected"';
  static const _receivedFragment = ' <= {';
  static const _sentFragment = ' => {';

  static final _nine = '9'.codeUnitAt(0);
  static final _zero = '0'.codeUnitAt(0);

  LogFileInputConverter(super.tmpSrcDirPath, super.srcPathMap);

  @override
  Operation? convert(String line) {
    try {
      var timeStampString = _parseTimeStamp(line);
      var data = line.substring(timeStampString.length);
      if (data.startsWith(_receivedFragment)) {
        var jsonData = asMap(json.decode(data.substring(4)));
        if (jsonData.containsKey('event')) {
          return convertNotification(jsonData);
        } else {
          return convertResponse(jsonData);
        }
      } else if (data.startsWith(_sentFragment)) {
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
        'Failed to parse line\n  $line',
        CaughtException(e, s),
      );
    }
  }

  /// Determine if the given line is from an instrumentation file.
  /// For example:
  /// `1428347977499 <= {"event":"server.connected","params":{"version":"1.6.0"}}`
  static bool isFormat(String line) {
    var timeStampString = _parseTimeStamp(line);
    var start = timeStampString.length;
    var end = start + _connectedMsgFragment.length;
    return (10 < start && end < line.length) &&
        line.substring(start, end) == _connectedMsgFragment;
  }

  /// Parse the given line and return the millisecond timestamp or `null`
  /// if it cannot be determined.
  static String _parseTimeStamp(String line) {
    var index = 0;
    while (index < line.length) {
      var code = line.codeUnitAt(index);
      if (code < _zero || _nine < code) {
        return line.substring(0, index);
      }
      ++index;
    }
    return line;
  }
}
