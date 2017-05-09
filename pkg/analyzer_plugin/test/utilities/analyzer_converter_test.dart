// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/error_processor.dart' as analyzer;
import 'package:analyzer/src/error/codes.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/generated/source.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(AnalyzerConverterTest);
}

@reflectiveTest
class AnalyzerConverterTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  AnalyzerConverter converter = new AnalyzerConverter();
  analyzer.Source source;

  /**
   * Assert that the given [pluginError] matches the given [analyzerError].
   */
  void assertError(
      plugin.AnalysisError pluginError, analyzer.AnalysisError analyzerError,
      {analyzer.ErrorSeverity severity,
      int startColumn: -1,
      int startLine: -1}) {
    analyzer.ErrorCode errorCode = analyzerError.errorCode;
    expect(pluginError, isNotNull);
    plugin.Location location = pluginError.location;
    expect(pluginError.code, errorCode.name.toLowerCase());
    expect(pluginError.correction, errorCode.correction);
    expect(location, isNotNull);
    expect(location.file, analyzerError.source.fullName);
    expect(location.length, analyzerError.length);
    expect(location.offset, analyzerError.offset);
    expect(location.startColumn, startColumn);
    expect(location.startLine, startLine);
    expect(pluginError.message, errorCode.message);
    expect(pluginError.severity,
        converter.convertErrorSeverity(severity ?? errorCode.errorSeverity));
    expect(pluginError.type, converter.convertErrorType(errorCode.type));
  }

  analyzer.AnalysisError createError(int offset) => new analyzer.AnalysisError(
      source, offset, 5, analyzer.CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT);

  void setUp() {
    source = resourceProvider
        .newFile(resourceProvider.convertPath('/foo/bar.dart'), '')
        .createSource();
  }

  test_convertAnalysisError_lineInfo_noSeverity() {
    analyzer.AnalysisError analyzerError = createError(13);
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);

    assertError(
        converter.convertAnalysisError(analyzerError, lineInfo: lineInfo),
        analyzerError,
        startColumn: 4,
        startLine: 2);
  }

  test_convertAnalysisError_lineInfo_severity() {
    analyzer.AnalysisError analyzerError = createError(13);
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;

    assertError(
        converter.convertAnalysisError(analyzerError,
            lineInfo: lineInfo, severity: severity),
        analyzerError,
        startColumn: 4,
        startLine: 2,
        severity: severity);
  }

  test_convertAnalysisError_noLineInfo_noSeverity() {
    analyzer.AnalysisError analyzerError = createError(11);

    assertError(converter.convertAnalysisError(analyzerError), analyzerError);
  }

  test_convertAnalysisError_noLineInfo_severity() {
    analyzer.AnalysisError analyzerError = createError(11);
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;

    assertError(
        converter.convertAnalysisError(analyzerError, severity: severity),
        analyzerError,
        severity: severity);
  }

  test_convertAnalysisErrors_lineInfo_noOptions() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);

    List<plugin.AnalysisError> pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors, lineInfo: lineInfo);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0],
        startColumn: 4, startLine: 2);
    assertError(pluginErrors[1], analyzerErrors[1],
        startColumn: 6, startLine: 3);
  }

  test_convertAnalysisErrors_lineInfo_options() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    analyzer.LineInfo lineInfo = new analyzer.LineInfo([0, 10, 20]);
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;
    analyzer.AnalysisOptionsImpl options = new analyzer.AnalysisOptionsImpl();
    options.errorProcessors = [
      new analyzer.ErrorProcessor(analyzerErrors[0].errorCode.name, severity)
    ];

    List<plugin.AnalysisError> pluginErrors = converter.convertAnalysisErrors(
        analyzerErrors,
        lineInfo: lineInfo,
        options: options);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0],
        startColumn: 4, startLine: 2, severity: severity);
    assertError(pluginErrors[1], analyzerErrors[1],
        startColumn: 6, startLine: 3, severity: severity);
  }

  test_convertAnalysisErrors_noLineInfo_noOptions() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(11),
      createError(25)
    ];

    List<plugin.AnalysisError> pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0]);
    assertError(pluginErrors[1], analyzerErrors[1]);
  }

  test_convertAnalysisErrors_noLineInfo_options() {
    List<analyzer.AnalysisError> analyzerErrors = <analyzer.AnalysisError>[
      createError(13),
      createError(25)
    ];
    analyzer.ErrorSeverity severity = analyzer.ErrorSeverity.WARNING;
    analyzer.AnalysisOptionsImpl options = new analyzer.AnalysisOptionsImpl();
    options.errorProcessors = [
      new analyzer.ErrorProcessor(analyzerErrors[0].errorCode.name, severity)
    ];

    List<plugin.AnalysisError> pluginErrors =
        converter.convertAnalysisErrors(analyzerErrors, options: options);
    expect(pluginErrors, hasLength(analyzerErrors.length));
    assertError(pluginErrors[0], analyzerErrors[0], severity: severity);
    assertError(pluginErrors[1], analyzerErrors[1], severity: severity);
  }

  test_convertErrorSeverity() {
    for (analyzer.ErrorSeverity severity in analyzer.ErrorSeverity.values) {
      if (severity != analyzer.ErrorSeverity.NONE) {
        expect(converter.convertErrorSeverity(severity), isNotNull,
            reason: severity.name);
      }
    }
  }

  test_convertErrorType() {
    for (analyzer.ErrorType type in analyzer.ErrorType.values) {
      expect(converter.convertErrorType(type), isNotNull, reason: type.name);
    }
  }
}
