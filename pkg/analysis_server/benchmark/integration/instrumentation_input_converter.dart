// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:logging/logging.dart';

import 'input_converter.dart';
import 'operation.dart';

/// [InstrumentationInputConverter] converts an instrumentation stream
/// into a series of operations to be sent to the analysis server.
class InstrumentationInputConverter extends CommonInputConverter {
  static final _colon = ':'.codeUnitAt(0);

  final Set<String> codesSeen = <String>{};

  /// [readBuffer] holds the contents of the file being read from disk
  /// as recorded in the instrumentation log
  /// or `null` if not converting a "Read" entry.
  StringBuffer? readBuffer;

  InstrumentationInputConverter(super.tmpSrcDirPath, super.srcPathMap);

  @override
  Operation? convert(String line) {
    List<String> fields;
    try {
      fields = _parseFields(line);
      if (fields.length < 2) {
        var readBuffer = this.readBuffer;
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
      throw AnalysisException(
        'Failed to parse line\n$line',
        CaughtException(e, s),
      );
    }
    // int timeStamp = int.parse(fields[0], onError: (_) => -1);
    var opCode = fields[1];
    if (opCode == InstrumentationLogAdapter.TAG_NOTIFICATION) {
      return convertNotification(decodeJson(line, fields[2]));
    } else if (opCode == 'Read') {
      // 1434096943209:Read:/some/file/path:1434095535000:<file content>
      //String filePath = fields[2];
      readBuffer = StringBuffer(fields.length > 4 ? fields[4] : '');
      return null;
    } else if (opCode == InstrumentationLogAdapter.TAG_REQUEST) {
      return convertRequest(decodeJson(line, fields[2]));
    } else if (opCode == InstrumentationLogAdapter.TAG_RESPONSE) {
      // 1434096937454:Res:{"id"::"0","result"::{"version"::"1.7.0"}}
      return convertResponse(decodeJson(line, fields[2]));
    } else if (opCode == InstrumentationLogAdapter.TAG_LOG_ENTRY) {
      // 1434096937454:Res:{"id"::"0","result"::{"version"::"1.7.0"}}
      return null;
    } else if (opCode == InstrumentationLogAdapter.TAG_VERSION) {
      // 1434096937358:Ver:1421765742287333878467:org.dartlang.dartplugin
      return null;
    } else if (opCode == InstrumentationLogAdapter.TAG_WATCH_EVENT) {
      // 1434097460414:Watch:/some/file/path
      return null;
    }
    if (codesSeen.add(opCode)) {
      logger.log(
        Level.WARNING,
        'Ignored instrumentation op code: $opCode\n  $line',
      );
    }
    return null;
  }

  Map<String, Object?> decodeJson(String line, String text) {
    try {
      return asMap(json.decode(text));
    } catch (e, s) {
      throw AnalysisException(
        'Failed to decode JSON: $text\n$line',
        CaughtException(e, s),
      );
    }
  }

  /// Determine if the given line is from an instrumentation file.
  /// For example:
  /// `1433175833005:Ver:1421765742287333878467:org.dartlang.dartplugin:0.0.0:1.6.2:1.11.0-edge.131698`
  static bool isFormat(String line) {
    var fields = _parseFields(line);
    if (fields.length < 2) return false;
    var timeStamp = int.tryParse(fields[0]) ?? -1;
    var opCode = fields[1];
    return timeStamp > 0 && opCode == 'Ver';
  }

  /// Extract fields from the given [line].
  static List<String> _parseFields(String line) {
    var fields = <String>[];
    var index = 0;
    var sb = StringBuffer();
    while (index < line.length) {
      var code = line.codeUnitAt(index);
      if (code == _colon) {
        // Embedded colons are doubled
        var next = index + 1;
        if (next < line.length && line.codeUnitAt(next) == _colon) {
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
