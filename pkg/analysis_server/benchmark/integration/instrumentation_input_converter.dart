// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:logging/logging.dart';

import 'input_converter.dart';
import 'operation.dart';

final int COLON = ':'.codeUnitAt(0);

/**
 * [InstrumentationInputConverter] converts an instrumentation stream
 * into a series of operations to be sent to the analysis server.
 */
class InstrumentationInputConverter extends CommonInputConverter {
  final Set<String> codesSeen = new Set<String>();

  /**
   * [readBuffer] holds the contents of the file being read from disk
   * as recorded in the instrumentation log
   * or `null` if not converting a "Read" entry.
   */
  StringBuffer readBuffer = null;

  InstrumentationInputConverter(String tmpSrcDirPath, PathMap srcPathMap)
      : super(tmpSrcDirPath, srcPathMap);

  @override
  Operation convert(String line) {
    List<String> fields;
    try {
      fields = _parseFields(line);
      if (fields.length < 2) {
        if (readBuffer != null) {
          readBuffer.writeln(fields.length == 1 ? fields[0] : '');
          return null;
        }
        throw 'Failed to process line:\n$line';
      }
      if (readBuffer != null) {
        readBuffer = null;
      }
    } catch (e, s) {
      throw new AnalysisException(
          'Failed to parse line\n$line', new CaughtException(e, s));
    }
    // int timeStamp = int.parse(fields[0], onError: (_) => -1);
    String opCode = fields[1];
    if (opCode == InstrumentationService.TAG_NOTIFICATION) {
      return convertNotification(decodeJson(line, fields[2]));
    } else if (opCode == 'Read') {
      // 1434096943209:Read:/some/file/path:1434095535000:<file content>
      //String filePath = fields[2];
      readBuffer = new StringBuffer(fields.length > 4 ? fields[4] : '');
      return null;
    } else if (opCode == InstrumentationService.TAG_REQUEST) {
      return convertRequest(decodeJson(line, fields[2]));
    } else if (opCode == InstrumentationService.TAG_RESPONSE) {
      // 1434096937454:Res:{"id"::"0","result"::{"version"::"1.7.0"}}
      return convertResponse(decodeJson(line, fields[2]));
    } else if (opCode == InstrumentationService.TAG_ANALYSIS_TASK) {
      // 1434096943208:Task:/Users/
      return null;
    } else if (opCode == InstrumentationService.TAG_LOG_ENTRY) {
      // 1434096937454:Res:{"id"::"0","result"::{"version"::"1.7.0"}}
      return null;
    } else if (opCode == InstrumentationService.TAG_PERFORMANCE) {
      //1434096960092:Perf:analysis_full:16884:context_id=0
      return null;
    } else if (opCode == InstrumentationService.TAG_SUBPROCESS_START) {
      // 1434096938634:SPStart:0:/Users/da
      return null;
    } else if (opCode == InstrumentationService.TAG_SUBPROCESS_RESULT) {
      // 1434096939068:SPResult:0:0:"{\"packages\"::{\"rpi_lidar\"::\"/Users
      return null;
    } else if (opCode == InstrumentationService.TAG_VERSION) {
      // 1434096937358:Ver:1421765742287333878467:org.dartlang.dartplugin
      return null;
    } else if (opCode == InstrumentationService.TAG_WATCH_EVENT) {
      // 1434097460414:Watch:/some/file/path
      return null;
    }
    if (codesSeen.add(opCode)) {
      logger.log(
          Level.WARNING, 'Ignored instrumentation op code: $opCode\n  $line');
    }
    return null;
  }

  Map<String, dynamic> decodeJson(String line, String text) {
    try {
      return asMap(JSON.decode(text));
    } catch (e, s) {
      throw new AnalysisException(
          'Failed to decode JSON: $text\n$line', new CaughtException(e, s));
    }
  }

  /**
   * Determine if the given line is from an instrumentation file.
   * For example:
   * `1433175833005:Ver:1421765742287333878467:org.dartlang.dartplugin:0.0.0:1.6.2:1.11.0-edge.131698`
   */
  static bool isFormat(String line) {
    List<String> fields = _parseFields(line);
    if (fields.length < 2) return false;
    int timeStamp = int.parse(fields[0], onError: (_) => -1);
    String opCode = fields[1];
    return timeStamp > 0 && opCode == 'Ver';
  }

  /**
   * Extract fields from the given [line].
   */
  static List<String> _parseFields(String line) {
    List<String> fields = new List<String>();
    int index = 0;
    StringBuffer sb = new StringBuffer();
    while (index < line.length) {
      int code = line.codeUnitAt(index);
      if (code == COLON) {
        // Embedded colons are doubled
        int next = index + 1;
        if (next < line.length && line.codeUnitAt(next) == COLON) {
          sb.write(':');
          ++index;
        } else {
          fields.add(sb.toString());
          sb.clear();
        }
      } else {
        sb.writeCharCode(code);
      }
      ++index;
    }
    if (sb.isNotEmpty) {
      fields.add(sb.toString());
    }
    return fields;
  }
}
