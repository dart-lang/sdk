// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RefactoringLocationTest);
    defineReflectiveTests(RefactoringStatusTest);
  });
}

@reflectiveTest
class RefactoringLocationTest extends AbstractSingleUnitTest {
  @override
  bool get enableNewAnalysisDriver => false;

  test_createLocation_forElement() async {
    await resolveTestUnit('class MyClass {}');
    Element element = findElement('MyClass');
    // check
    Location location = newLocation_fromElement(element);
    expect(location.file, '/test.dart');
    expect(location.offset, 6);
    expect(location.length, 7);
    expect(location.startLine, 1);
    expect(location.startColumn, 7);
  }

  test_createLocation_forMatch() async {
    await resolveTestUnit('class MyClass {}');
    Element element = findElement('MyClass');
    SourceRange sourceRange = range.elementName(element);
    SearchMatch match = new SearchMatchImpl(
        element.context,
        element.library.source.uri.toString(),
        element.source.uri.toString(),
        null,
        sourceRange,
        true,
        false);
    // check
    Location location = newLocation_fromMatch(match);
    expect(location.file, '/test.dart');
    expect(location.offset, sourceRange.offset);
    expect(location.length, sourceRange.length);
  }

  test_createLocation_forNode() async {
    await resolveTestUnit('''
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

  test_createLocation_forUnit() async {
    await resolveTestUnit('');
    SourceRange sourceRange = new SourceRange(10, 20);
    // check
    Location location = newLocation_fromUnit(testUnit, sourceRange);
    expect(location.file, '/test.dart');
    expect(location.offset, sourceRange.offset);
    expect(location.length, sourceRange.length);
  }
}

@reflectiveTest
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
