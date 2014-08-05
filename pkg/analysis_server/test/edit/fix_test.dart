// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.fix;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_server/src/edit/fix.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/fix.dart' as services;
import 'package:analysis_services/index/index.dart' hide Location;
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;
import 'package:unittest/unittest.dart' hide ERROR;



main() {
  groupSep = ' | ';
  runReflectiveTests(ErrorFixesTest);
}


@ReflectiveTestCase()
class ErrorFixesTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    verifyNoTestUnitErrors = false;
  }

  void test_fromService() {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  print(42)
}
''');
    engine.AnalysisErrorInfo errors = context.getErrors(testSource);
    engine.AnalysisError engineError = errors.errors[0];
    List<services.Fix> servicesFixes =
        services.computeFixes(searchEngine, testUnit, engineError);
    AnalysisError error =
        new AnalysisError.fromEngine(errors.lineInfo, engineError);
    ErrorFixes fixes = new ErrorFixes(error);
    servicesFixes.forEach((fix) => fixes.addFix(fix));
    expect(fixes.toJson(), {
      ERROR: {
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
      },
      FIXES: [{
          MESSAGE: 'Insert \';\'',
          EDITS: [{
              FILE: '/test.dart',
              EDITS: [{
                  OFFSET: 20,
                  LENGTH: 0,
                  REPLACEMENT: ';'
                }]
            }],
          LINKED_EDIT_GROUPS: []
        }]
    });
  }
}
