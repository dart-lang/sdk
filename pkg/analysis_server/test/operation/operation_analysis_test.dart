// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation.analysis;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../typed_mocks.dart';

main() {
  groupSep = ' | ';

  group('errorToJson', () {
    runReflectiveTests(Test_errorToJson);
  });
}


class AnalysisErrorMock extends TypedMock implements AnalysisError {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


@ReflectiveTestCase()
class Test_errorToJson {
  Source source = new SourceMock();
  LineInfo lineInfo;
  AnalysisError analysisError = new AnalysisErrorMock();

  void setUp() {
    // prepare Source
    when(source.fullName).thenReturn('foo.dart');
    // prepare LineInfo
    lineInfo = new LineInfo([0, 5, 9, 20]);
    // prepare AnalysisError
    when(analysisError.source).thenReturn(source);
    when(analysisError.errorCode).thenReturn(
        CompileTimeErrorCode.AMBIGUOUS_EXPORT);
    when(analysisError.message).thenReturn('my message');
    when(analysisError.offset).thenReturn(10);
    when(analysisError.length).thenReturn(20);
  }

  void tearDown() {
    source = null;
    analysisError = null;
  }

  void test_noCorrection() {
    Map<String, Object> json = errorToJson(lineInfo, analysisError);
    expect(json, {
      ERROR_CODE: 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message'
    });
  }

  void test_noLineInfo() {
    Map<String, Object> json = errorToJson(null, analysisError);
    expect(json, {
      ERROR_CODE: 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20
      },
      MESSAGE: 'my message'
    });
  }

  void test_withCorrection() {
    when(analysisError.correction).thenReturn('my correction');
    Map<String, Object> json = errorToJson(lineInfo, analysisError);
    expect(json, {
      ERROR_CODE: 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message',
      CORRECTION: 'my correction'
    });
  }
}
