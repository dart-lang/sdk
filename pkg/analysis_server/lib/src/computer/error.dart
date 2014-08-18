// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.error;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/services/constants.dart';
import 'package:analysis_server/src/services/json.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;


/**
 * Returns a JSON correponding to the given list of Engine errors.
 */
List<Map<String, Object>> engineErrorInfoToJson(engine.AnalysisErrorInfo info) {
  return engineErrorsToJson(info.lineInfo, info.errors);
}


/**
 * Returns a JSON correponding to the given list of Engine errors.
 */
List<Map<String, Object>> engineErrorsToJson(engine.LineInfo lineInfo,
    List<engine.AnalysisError> errors) {
  return errors.map((engine.AnalysisError error) {
    return new AnalysisError.fromEngine(lineInfo, error).toJson();
  }).toList();
}


/**
 * An indication of an error, warning, or hint that was produced by the
 * analysis. 
 */
class AnalysisError implements HasToJson {
  final String severity;
  final String type;
  final Location location;
  final String message;
  final String correction;

  AnalysisError(this.severity, this.type, this.location, this.message,
      this.correction);

  factory AnalysisError.fromEngine(engine.LineInfo lineInfo,
      engine.AnalysisError error) {
    engine.ErrorCode errorCode = error.errorCode;
    // prepare location
    Location location;
    {
      String file = error.source.fullName;
      int offset = error.offset;
      int length = error.length;
      int startLine = -1;
      int startColumn = -1;
      if (lineInfo != null) {
        engine.LineInfo_Location lineLocation = lineInfo.getLocation(offset);
        if (lineLocation != null) {
          startLine = lineLocation.lineNumber;
          startColumn = lineLocation.columnNumber;
        }
      }
      location = new Location(file, offset, length, startLine, startColumn);
    }
    // done
    String severity = errorCode.errorSeverity.toString();
    String type = errorCode.type.toString();
    String message = error.message;
    String correction = error.correction;
    return new AnalysisError(severity, type, location, message, correction);
  }

  @override
  Map<String, Object> toJson() {
    Map<String, Object> json = {
      SEVERITY: severity,
      TYPE: type,
      LOCATION: location.toJson(),
      MESSAGE: message
    };
    if (correction != null) {
      json[CORRECTION] = correction;
    }
    return json;
  }

  @override
  String toString() {
    return 'AnalysisError(location=$location message=$message; '
        'severity=$severity; type=$type; correction=$correction';
  }

  static AnalysisError fromJson(Map<String, Object> json) {
    return new AnalysisError(
        json[SEVERITY],
        json[TYPE],
        new Location.fromJson(json[LOCATION]),
        json[MESSAGE],
        json[CORRECTION]);
  }
}
