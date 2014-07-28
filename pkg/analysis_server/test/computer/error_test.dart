// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.error;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_testing/mocks.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';



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
    AnalysisError error = new AnalysisError.fromEngine(lineInfo, engineError);
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
    AnalysisError error = new AnalysisError.fromEngine(lineInfo, engineError);
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
    AnalysisError error = new AnalysisError.fromEngine(null, engineError);
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

  void test_fromJson() {
    var json = {
      SEVERITY: 'ERROR',
      TYPE: 'SYNTACTIC_ERROR',
      LOCATION: {
        FILE: '/test.dart',
        OFFSET: 19,
        LENGTH: 1,
        START_LINE: 2,
        START_COLUMN: 11
      },
      MESSAGE: 'Expected to find \';\'',
      CORRECTION: 'my correction'
    };
    AnalysisError error = AnalysisError.fromJson(json);
    {
      Location location = error.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 19);
      expect(location.length, 1);
      expect(location.startLine, 2);
      expect(location.startColumn, 11);
    }
    expect(error.message, "Expected to find ';'");
    expect(error.severity, 'ERROR');
    expect(error.type, 'SYNTACTIC_ERROR');
    expect(error.correction, "my correction");
  }

  void test_engineErrorsToJson() {
    var json = engineErrorsToJson(lineInfo, [engineError]);
    expect(json, unorderedEquals([{
        'severity': 'ERROR',
        'type': 'COMPILE_TIME_ERROR',
        'location': {
          'file': 'foo.dart',
          'offset': 10,
          'length': 20,
          'startLine': 3,
          'startColumn': 2
        },
        'message': 'my message'
      }]));
  }
}
