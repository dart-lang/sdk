// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.error;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../mocks.dart';
import '../reflective_tests.dart';



main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisErrorTest);
}


class AnalysisErrorMock extends TypedMock implements engine.AnalysisError {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


@ReflectiveTestCase()
class AnalysisErrorTest {
  Source source = new MockSource();
  LineInfo lineInfo;
  engine.AnalysisError engineError = new AnalysisErrorMock();

  void setUp() {
    // prepare Source
    when(source.fullName).thenReturn('foo.dart');
    // prepare LineInfo
    lineInfo = new LineInfo([0, 5, 9, 20]);
    // prepare AnalysisError
    when(engineError.source).thenReturn(source);
    when(
        engineError.errorCode).thenReturn(engine.CompileTimeErrorCode.AMBIGUOUS_EXPORT);
    when(engineError.message).thenReturn('my message');
    when(engineError.offset).thenReturn(10);
    when(engineError.length).thenReturn(20);
  }

  void tearDown() {
    source = null;
    engineError = null;
  }

  void test_fromEngine_hasCorrection() {
    when(engineError.correction).thenReturn('my correction');
    AnalysisError error = newAnalysisError_fromEngine(lineInfo, engineError);
    expect(error.toJson(), {
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

  void test_fromEngine_noCorrection() {
    when(engineError.correction).thenReturn(null);
    AnalysisError error = newAnalysisError_fromEngine(lineInfo, engineError);
    expect(error.toJson(), {
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

  void test_fromEngine_noLineInfo() {
    when(engineError.correction).thenReturn(null);
    AnalysisError error = newAnalysisError_fromEngine(null, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: -1,
        START_COLUMN: -1
      },
      MESSAGE: 'my message'
    });
  }
}
