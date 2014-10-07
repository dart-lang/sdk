// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.status;

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(RefactoringLocationTest);
  runReflectiveTests(RefactoringStatusTest);
}


@ReflectiveTestCase()
class RefactoringLocationTest extends AbstractSingleUnitTest {
  void test_createLocation_forElement() {
    resolveTestUnit('class MyClass {}');
    Element element = findElement('MyClass');
    // check
    Location location = newLocation_fromElement(element);
    expect(location.file, '/test.dart');
    expect(location.offset, 6);
    expect(location.length, 7);
    expect(location.startLine, 1);
    expect(location.startColumn, 7);
  }

  void test_createLocation_forMatch() {
    resolveTestUnit('class MyClass {}');
    Element element = findElement('MyClass');
    SourceRange range = rangeElementName(element);
    SearchMatch match = new SearchMatch(null, element, range, true, false);
    // check
    Location location = newLocation_fromMatch(match);
    expect(location.file, '/test.dart');
    expect(location.offset, range.offset);
    expect(location.length, range.length);
  }

  void test_createLocation_forNode() {
    resolveTestUnit('''
main() {
}
''');
    AstNode node = findNodeAtString('main');
    // check
    Location location = newLocation_fromNode(node);
    expect(location.file, '/test.dart');
    expect(location.offset, node.offset);
    expect(location.length, node.length);
  }

  void test_createLocation_forUnit() {
    resolveTestUnit('');
    SourceRange range = rangeStartLength(10, 20);
    // check
    Location location = newLocation_fromUnit(testUnit, range);
    expect(location.file, '/test.dart');
    expect(location.offset, range.offset);
    expect(location.length, range.length);
  }
}


@ReflectiveTestCase()
class RefactoringStatusTest {
  void test_addError() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add ERROR
    refactoringStatus.addError('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isFalse);
    expect(refactoringStatus.hasError, isTrue);
    // problems
    List<RefactoringProblem> problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
  }

  void test_addFatalError_withLocation() {
    Location location = new Location('/test.dart', 1, 2, 3, 4);
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add FATAL
    refactoringStatus.addFatalError('msg', location);
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isTrue);
    expect(refactoringStatus.hasError, isTrue);
    // problems
    List<RefactoringProblem> problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
    expect(problems[0].location.file, '/test.dart');
    expect(problems[0].location.offset, 1);
    expect(problems[0].location.length, 2);
    // add WARNING, resulting severity is still FATAL
    refactoringStatus.addWarning("warning");
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
  }

  void test_addFatalError_withoutContext() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add FATAL
    refactoringStatus.addFatalError('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isTrue);
    expect(refactoringStatus.hasError, isTrue);
    // problems
    List<RefactoringProblem> problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
    expect(problems[0].location, isNull);
  }

  void test_addStatus_Error_withWarning() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    refactoringStatus.addError("err");
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    // merge with OK
    {
      RefactoringStatus other = new RefactoringStatus();
      other.addWarning("warn");
      refactoringStatus.addStatus(other);
    }
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.message, 'err');
  }

  void test_addStatus_Warning_null() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    refactoringStatus.addWarning("warn");
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    // merge with "null"
    refactoringStatus.addStatus(null);
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
  }

  void test_addStatus_Warning_withError() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    refactoringStatus.addWarning("warn");
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    // merge with OK
    {
      RefactoringStatus other = new RefactoringStatus();
      other.addError("err");
      refactoringStatus.addStatus(other);
    }
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.message, 'err');
  }

  void test_addWarning() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add WARNING
    refactoringStatus.addWarning('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isFalse);
    expect(refactoringStatus.hasError, isFalse);
    expect(refactoringStatus.hasWarning, isTrue);
    // problems
    List<RefactoringProblem> problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
  }

  void test_get_problem() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // no entries
    expect(refactoringStatus.problem, isNull);
    expect(refactoringStatus.message, isNull);
    // add entries
    refactoringStatus.addError('msgError');
    refactoringStatus.addWarning('msgWarning');
    refactoringStatus.addFatalError('msgFatalError');
    // get entry
    {
      RefactoringProblem problem = refactoringStatus.problem;
      expect(problem.severity, RefactoringProblemSeverity.FATAL);
      expect(problem.message, 'msgFatalError');
    }
    // get message
    expect(refactoringStatus.problem.message, 'msgFatalError');
  }

  void test_newError() {
    Location location = new Location('/test.dart', 1, 2, 3, 4);
    RefactoringStatus refactoringStatus =
        new RefactoringStatus.error('msg', location);
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.problem.message, 'msg');
    expect(refactoringStatus.problem.location.file, '/test.dart');
  }

  void test_newFatalError() {
    RefactoringStatus refactoringStatus = new RefactoringStatus.fatal('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
    expect(refactoringStatus.message, 'msg');
  }

  void test_newWarning() {
    RefactoringStatus refactoringStatus = new RefactoringStatus.warning('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    expect(refactoringStatus.message, 'msg');
  }
}
