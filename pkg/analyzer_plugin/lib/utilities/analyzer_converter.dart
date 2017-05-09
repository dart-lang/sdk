// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * An object used to convert between objects defined by the 'analyzer' package
 * and those defined by the plugin protocol.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyzerConverter {
  /**
   * Convert the analysis [error] from the 'analyzer' package to an analysis
   * error defined by the plugin API. If a [lineInfo] is provided then the
   * error's location will have a start line and start column. If a [severity]
   * is provided, then it will override the severity defined by the error.
   */
  plugin.AnalysisError convertAnalysisError(analyzer.AnalysisError error,
      {analyzer.LineInfo lineInfo, analyzer.ErrorSeverity severity}) {
    analyzer.ErrorCode errorCode = error.errorCode;
    severity ??= errorCode.errorSeverity;
    int offset = error.offset;
    int startLine = -1;
    int startColumn = -1;
    if (lineInfo != null) {
      analyzer.LineInfo_Location lineLocation = lineInfo.getLocation(offset);
      if (lineLocation != null) {
        startLine = lineLocation.lineNumber;
        startColumn = lineLocation.columnNumber;
      }
    }
    return new plugin.AnalysisError(
        convertErrorSeverity(severity),
        convertErrorType(errorCode.type),
        new plugin.Location(error.source.fullName, offset, error.length,
            startLine, startColumn),
        error.message,
        errorCode.name.toLowerCase(),
        correction: error.correction,
        hasFix: true);
  }

  /**
   * Convert the list of analysis [errors] from the 'analyzer' package to a list
   * of analysis errors defined by the plugin API. If a [lineInfo] is provided
   * then the resulting errors locations will have a start line and start column.
   * If an analysis [options] is provided then the severities of the errors will
   * be altered based on those options.
   */
  List<plugin.AnalysisError> convertAnalysisErrors(
      List<analyzer.AnalysisError> errors,
      {analyzer.LineInfo lineInfo,
      analyzer.AnalysisOptions options}) {
    List<plugin.AnalysisError> serverErrors = <plugin.AnalysisError>[];
    for (analyzer.AnalysisError error in errors) {
      analyzer.ErrorProcessor processor =
          analyzer.ErrorProcessor.getProcessor(options, error);
      if (processor != null) {
        analyzer.ErrorSeverity severity = processor.severity;
        // Errors with null severity are filtered out.
        if (severity != null) {
          // Specified severities override.
          serverErrors.add(convertAnalysisError(error,
              lineInfo: lineInfo, severity: severity));
        }
      } else {
        serverErrors.add(convertAnalysisError(error, lineInfo: lineInfo));
      }
    }
    return serverErrors;
  }

  /**
   * Convert the error [severity] from the 'analyzer' package to an analysis
   * error severity defined by the plugin API.
   */
  plugin.AnalysisErrorSeverity convertErrorSeverity(
          analyzer.ErrorSeverity severity) =>
      new plugin.AnalysisErrorSeverity(severity.name);

  /**
   *Convert the error [type] from the 'analyzer' package to an analysis error
   * type defined by the plugin API.
   */
  plugin.AnalysisErrorType convertErrorType(analyzer.ErrorType type) =>
      new plugin.AnalysisErrorType(type.name);
}
