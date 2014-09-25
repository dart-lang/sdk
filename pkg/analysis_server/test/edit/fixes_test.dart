// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.fixes;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(FixesTest);
}


@ReflectiveTestCase()
class FixesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new EditDomainHandler(server);
  }

  Future test_fixUndefinedClass() {
    addTestFile('''
main() {
  Future<String> x = null;
}
''');
    return waitForTasksFinished().then((_) {
      List<AnalysisErrorFixes> errorFixes = _getFixesAt('Future<String>');
      expect(errorFixes, hasLength(1));
      AnalysisError error = errorFixes[0].error;
      expect(error.severity, AnalysisErrorSeverity.WARNING);
      expect(error.type, AnalysisErrorType.STATIC_WARNING);
      List<SourceChange> fixes = errorFixes[0].fixes;
      expect(fixes, hasLength(2));
      expect(fixes[0].message, matches('Import library'));
      expect(fixes[1].message, matches('Create class'));
    });
  }

  Future test_hasFixes() {
    addTestFile('''
foo() {
  print(1)
}
bar() {
  print(10) print(20)
}
''');
    return waitForTasksFinished().then((_) {
      // print(1)
      {
        List<AnalysisErrorFixes> errorFixes = _getFixesAt('print(1)');
        expect(errorFixes, hasLength(1));
        _isSyntacticErrorWithSingleFix(errorFixes[0]);
      }
      // print(10)
      {
        List<AnalysisErrorFixes> errorFixes = _getFixesAt('print(10)');
        expect(errorFixes, hasLength(2));
        _isSyntacticErrorWithSingleFix(errorFixes[0]);
        _isSyntacticErrorWithSingleFix(errorFixes[1]);
      }
    });
  }

  List<AnalysisErrorFixes> _getFixes(int offset) {
    Request request = new EditGetFixesParams(testFile, offset).toRequest('0');
    Response response = handleSuccessfulRequest(request);
    var result = new EditGetFixesResult.fromResponse(response);
    return result.fixes;
  }

  List<AnalysisErrorFixes> _getFixesAt(String search) {
    int offset = findOffset(search);
    return _getFixes(offset);
  }


  void _isSyntacticErrorWithSingleFix(AnalysisErrorFixes fixes) {
    AnalysisError error = fixes.error;
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(fixes.fixes, hasLength(1));
  }
}
