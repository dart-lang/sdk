// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.fix;

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/fix.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:unittest/unittest.dart';

import '../index/abstract_single_unit.dart';


main() {
  groupSep = ' | ';
  group('FixProcessorTest', () {
    runReflectiveTests(FixProcessorTest);
  });
}


@ReflectiveTestCase()
class FixProcessorTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  void assertHasFix(FixKind kind, String expected) {
    AnalysisError error = _findErrorToFix();
    Fix fix = _computeFix(kind, error);
    // apply to "file"
    List<FileEdit> fileEdits = fix.change.edits;
    expect(fileEdits, hasLength(1));
    String actualCode = _applyEdits(testCode, fix.change.edits[0].edits);
    // verify
    expect(expected, actualCode);
  }

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    verifyNoTestUnitErrors = false;
  }

  void test_boolean() {
    _indexTestUnit('''
main() {
  boolean v;
}
''');
    assertHasFix(FixKind.REPLACE_BOOLEAN_WITH_BOOL, '''
main() {
  bool v;
}
''');
  }

  String _applyEdits(String code, List<Edit> edits) {
    edits.sort((a, b) => b.offset - a.offset);
    edits.forEach((Edit edit) {
      code = code.substring(0, edit.offset) +
          edit.replacement +
          code.substring(edit.end);
    });
    return code;
  }

  Fix _computeFix(FixKind kind, AnalysisError error) {
    List<Fix> fixes = computeFixes(searchEngine, testFile, testUnit, error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        return fix;
      }
    }
    throw fail('Expected to find fix $kind in\n${fixes.join('\n')}');
  }

  AnalysisError _findErrorToFix() {
    List<AnalysisError> errors = context.getErrors(testSource).errors;
    expect(
        errors,
        hasLength(1),
        reason: 'Exactly 1 error expected, but ${errors.length} found:\n' +
            errors.join('\n'));
    return errors[0];
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }
}
