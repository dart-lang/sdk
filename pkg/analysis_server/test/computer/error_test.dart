// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.error;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;
import 'package:unittest/unittest.dart';



main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisErrorTest);
}


@ReflectiveTestCase()
class AnalysisErrorTest extends AbstractSingleUnitTest {
  void test_fromEngine() {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  print(42)
}
''');
    engine.AnalysisErrorInfo errors = context.getErrors(testSource);
    engine.AnalysisError engineError = errors.errors[0];
    AnalysisError error =
        new AnalysisError.fromEngine(errors.lineInfo, engineError);
    {
      Location location = error.location;
      expect(location.file, testFile);
      expect(location.offset, 19);
      expect(location.length, 1);
      expect(location.startLine, 2);
      expect(location.startColumn, 11);
    }
    expect(error.message, "Expected to find ';'");
    expect(error.severity, "ERROR");
    expect(error.type, "SYNTACTIC_ERROR");
    expect(
        error.toString(),
        'AnalysisError(location=Location(file=/test.dart; offset=19; '
            'length=1; startLine=2; startColumn=11) '
            'message=Expected to find \';\'; severity=ERROR; '
            'type=SYNTACTIC_ERROR; correction=null');
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
      MESSAGE: 'Expected to find \';\''
    };
    AnalysisError error = AnalysisError.fromJson(json);
    {
      Location location = error.location;
      expect(location.file, testFile);
      expect(location.offset, 19);
      expect(location.length, 1);
      expect(location.startLine, 2);
      expect(location.startColumn, 11);
    }
    expect(error.message, "Expected to find ';'");
    expect(error.severity, "ERROR");
    expect(error.type, "SYNTACTIC_ERROR");
  }

  void test_toJson() {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  print(42)
}
''');
    engine.AnalysisErrorInfo errors = context.getErrors(testSource);
    engine.AnalysisError engineError = errors.errors[0];
    AnalysisError error =
        new AnalysisError.fromEngine(errors.lineInfo, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'SYNTACTIC_ERROR',
      LOCATION: {
        FILE: '/test.dart',
        OFFSET: 19,
        LENGTH: 1,
        START_LINE: 2,
        START_COLUMN: 11
      },
      MESSAGE: 'Expected to find \';\''
    });
  }
}
