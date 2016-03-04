// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.fixes;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:plugin/manager.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';
import '../mocks.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(FixesTest);
}

@reflectiveTest
class FixesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    createProject();
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins([server.serverPlugin]);
    handler = new EditDomainHandler(server);
  }

  test_fixUndefinedClass() async {
    addTestFile('''
main() {
  Future<String> x = null;
  print(x);
}
''');
    await waitForTasksFinished();
    List<AnalysisErrorFixes> errorFixes = await _getFixesAt('Future<String>');
    expect(errorFixes, hasLength(1));
    AnalysisError error = errorFixes[0].error;
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    List<SourceChange> fixes = errorFixes[0].fixes;
    expect(fixes, hasLength(3));
    expect(fixes[0].message, matches('Import library'));
    expect(fixes[1].message, matches('Create class'));
    expect(
        fixes[2].message, matches("Ignore error with code 'undefined_class'"));
  }

  test_hasFixes() async {
    addTestFile('''
foo() {
  print(1)
}
bar() {
  print(10) print(20)
}
''');
    await waitForTasksFinished();
    // print(1)
    {
      List<AnalysisErrorFixes> errorFixes = await _getFixesAt('print(1)');
      expect(errorFixes, hasLength(1));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
    }
    // print(10)
    {
      List<AnalysisErrorFixes> errorFixes = await _getFixesAt('print(10)');
      expect(errorFixes, hasLength(2));
      _isSyntacticErrorWithSingleFix(errorFixes[0]);
      _isSyntacticErrorWithSingleFix(errorFixes[1]);
    }
  }

  test_overlayOnlyFile() async {
    // add an overlay-only file
    {
      testCode = '''
main() {
  print(1)
}
''';
      Request request = new AnalysisUpdateContentParams(
          {testFile: new AddContentOverlay(testCode)}).toRequest('0');
      Response response =
          new AnalysisDomainHandler(server).handleRequest(request);
      expect(response, isResponseSuccess('0'));
    }
    // ask for fixes
    await waitForTasksFinished();
    List<AnalysisErrorFixes> errorFixes = await _getFixesAt('print(1)');
    expect(errorFixes, hasLength(1));
    _isSyntacticErrorWithSingleFix(errorFixes[0]);
  }

  Future<List<AnalysisErrorFixes>> _getFixes(int offset) async {
    Request request = new EditGetFixesParams(testFile, offset).toRequest('0');
    Response response = await waitResponse(request);
    var result = new EditGetFixesResult.fromResponse(response);
    return result.fixes;
  }

  Future<List<AnalysisErrorFixes>> _getFixesAt(String search) async {
    int offset = findOffset(search);
    return await _getFixes(offset);
  }

  void _isSyntacticErrorWithSingleFix(AnalysisErrorFixes fixes) {
    AnalysisError error = fixes.error;
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(fixes.fixes, hasLength(1));
  }
}
