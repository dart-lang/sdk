// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RefactoringLocationTest);
    defineReflectiveTests(RefactoringStatusTest);
  });
}

@reflectiveTest
class RefactoringLocationTest extends AbstractSingleUnitTest {
  Future<void> test_createLocation_forElement() async {
    await resolveTestCode('class MyClass {}');
    var element = findElement('MyClass');
    // check
    var location = newLocation_fromElement(element);
    expect(location.file, testFile);
    expect(location.offset, 6);
    expect(location.length, 7);
    expect(location.startLine, 1);
    expect(location.startColumn, 7);
  }

  Future<void> test_createLocation_forMatch() async {
    await resolveTestCode('class MyClass {}');
    var element = findElement('MyClass');
    var sourceRange = range.elementName(element);
    SearchMatch match = SearchMatchImpl(
        element.source.fullName,
        element.library.source,
        element.source,
        element.library,
        element,
        true,
        false,
        MatchKind.DECLARATION,
        sourceRange);
    // check
    var location = newLocation_fromMatch(match);
    expect(location.file, testFile);
    expect(location.offset, sourceRange.offset);
    expect(location.length, sourceRange.length);
  }

  Future<void> test_createLocation_forNode() async {
    await resolveTestCode('''
main() {
}
''');
    var node = findNodeAtString('main');
    // check
    var location = newLocation_fromNode(node);
    expect(location.file, testFile);
    expect(location.offset, node.offset);
    expect(location.length, node.length);
  }

  Future<void> test_createLocation_forUnit() async {
    await resolveTestCode('');
    var sourceRange = SourceRange(10, 20);
    // check
    var location = newLocation_fromUnit(testUnit, sourceRange);
    expect(location.file, testFile);
    expect(location.offset, sourceRange.offset);
    expect(location.length, sourceRange.length);
  }
}

@reflectiveTest
class RefactoringStatusTest {
  void test_addError() {
    var refactoringStatus = RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add ERROR
    refactoringStatus.addError('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isFalse);
    expect(refactoringStatus.hasError, isTrue);
    // problems
    var problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
  }

  void test_addFatalError_withLocation() {
    var location = Location('/test.dart', 1, 2, 3, 4);
    var refactoringStatus = RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add FATAL
    refactoringStatus.addFatalError('msg', location);
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isTrue);
    expect(refactoringStatus.hasError, isTrue);
    // problems
    var problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
    expect(problems[0].location.file, '/test.dart');
    expect(problems[0].location.offset, 1);
    expect(problems[0].location.length, 2);
    // add WARNING, resulting severity is still FATAL
    refactoringStatus.addWarning('warning');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
  }

  void test_addFatalError_withoutContext() {
    var refactoringStatus = RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, null);
    // add FATAL
    refactoringStatus.addFatalError('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isTrue);
    expect(refactoringStatus.hasError, isTrue);
    // problems
    var problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
    expect(problems[0].location, isNull);
  }

  void test_addStatus_Error_withWarning() {
    var refactoringStatus = RefactoringStatus();
    refactoringStatus.addError('err');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    // merge with OK
    {
      var other = RefactoringStatus();
      other.addWarning('warn');
      refactoringStatus.addStatus(other);
    }
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.message, 'err');
  }

  void test_addStatus_Warning_null() {
    var refactoringStatus = RefactoringStatus();
    refactoringStatus.addWarning('warn');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    // merge with "null"
    refactoringStatus.addStatus(null);
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
  }

  void test_addStatus_Warning_withError() {
    var refactoringStatus = RefactoringStatus();
    refactoringStatus.addWarning('warn');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    // merge with OK
    {
      var other = RefactoringStatus();
      other.addError('err');
      refactoringStatus.addStatus(other);
    }
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.message, 'err');
  }

  void test_addWarning() {
    var refactoringStatus = RefactoringStatus();
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
    var problems = refactoringStatus.problems;
    expect(problems, hasLength(1));
    expect(problems[0].message, 'msg');
  }

  void test_get_problem() {
    var refactoringStatus = RefactoringStatus();
    // no entries
    expect(refactoringStatus.problem, isNull);
    expect(refactoringStatus.message, isNull);
    // add entries
    refactoringStatus.addError('msgError');
    refactoringStatus.addWarning('msgWarning');
    refactoringStatus.addFatalError('msgFatalError');
    // get entry
    {
      var problem = refactoringStatus.problem;
      expect(problem.severity, RefactoringProblemSeverity.FATAL);
      expect(problem.message, 'msgFatalError');
    }
    // get message
    expect(refactoringStatus.problem.message, 'msgFatalError');
  }

  void test_newError() {
    var location = Location('/test.dart', 1, 2, 3, 4);
    var refactoringStatus = RefactoringStatus.error('msg', location);
    expect(refactoringStatus.severity, RefactoringProblemSeverity.ERROR);
    expect(refactoringStatus.problem.message, 'msg');
    expect(refactoringStatus.problem.location.file, '/test.dart');
  }

  void test_newFatalError() {
    var refactoringStatus = RefactoringStatus.fatal('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.FATAL);
    expect(refactoringStatus.message, 'msg');
  }

  void test_newWarning() {
    var refactoringStatus = RefactoringStatus.warning('msg');
    expect(refactoringStatus.severity, RefactoringProblemSeverity.WARNING);
    expect(refactoringStatus.message, 'msg');
  }
}
