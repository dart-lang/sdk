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
  group('ErrorFixes', () {
    runReflectiveTests(ErrorFixesTest);
  });
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

  void test_fromJson() {
    var json = {
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
          LINKED_POSITION_GROUPS: []
        }]
    };
    ErrorFixes errorFixes = ErrorFixes.fromJson(json);
    {
      AnalysisError error = errorFixes.error;
      expect(error.severity, 'ERROR');
      expect(error.type, 'SYNTACTIC_ERROR');
      expect(error.message, "Expected to find ';'");
      {
        Location location = error.location;
        expect(location.file, testFile);
        expect(location.offset, 19);
        expect(location.length, 1);
        expect(location.startLine, 2);
        expect(location.startColumn, 11);
      }
    }
    expect(errorFixes.fixes, hasLength(1));
    {
      Change change = errorFixes.fixes[0];
      expect(change.message, "Insert ';'");
      expect(change.edits, hasLength(1));
      {
        FileEdit fileEdit = change.edits[0];
        expect(fileEdit.file, testFile);
        expect(
            fileEdit.edits.toString(),
            "[Edit(offset=20, length=0, replacement=:>;<:)]");
      }
    }
    expect(
        errorFixes.toString(),
        'ErrorFixes(error=AnalysisError('
            'location=Location(file=/test.dart; offset=19; length=1; '
            'startLine=2; startColumn=11) message=Expected to find \';\'; '
            'severity=ERROR; type=SYNTACTIC_ERROR; correction=null, '
            'fixes=[Change(message=Insert \';\', '
            'edits=[FileEdit(file=/test.dart, edits=[Edit(offset=20, length=0, '
            'replacement=:>;<:)])], linkedPositionGroups=[])])');
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
        services.computeFixes(searchEngine, testFile, testUnit, engineError);
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
          LINKED_POSITION_GROUPS: []
        }]
    });
  }
}
