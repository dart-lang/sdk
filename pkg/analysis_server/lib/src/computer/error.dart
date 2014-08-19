// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.error;

import 'package:analysis_server/src/protocol2.dart';
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
    return analysisErrorFromEngine(lineInfo, error).toJson();
  }).toList();
}


AnalysisError analysisErrorFromEngine(engine.LineInfo lineInfo,
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
  var severity = new ErrorSeverity(errorCode.errorSeverity.name);
  var type = new ErrorType(errorCode.type.name);
  String message = error.message;
  String correction = error.correction;
  return new AnalysisError(severity, type, location, message,
      correction: correction);
}
