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
List<Map<String, Object>> engineErrorsToJson(engine.LineInfo lineInfo,
    List<engine.AnalysisError> errors) {
  return errors.map((engine.AnalysisError error) {
    return new AnalysisError.fromEngine(lineInfo, error).toJson();
  }).toList();
}
