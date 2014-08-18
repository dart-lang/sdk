// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.status;

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(RefactoringStatusContextTest);
  runReflectiveTests(RefactoringStatusEntryTest);
  runReflectiveTests(RefactoringStatusTest);
}


@ReflectiveTestCase()
class RefactoringStatusContextTest extends AbstractSingleUnitTest {
  void test_new_forElement() {
    resolveTestUnit('class MyClass {}');
    Element element = findElement('MyClass');
    var statusContext = new RefactoringStatusContext.forElement(element);
    // access
    expect(statusContext.context, context);
    expect(statusContext.source, testSource);
    expect(
        statusContext.range,
        rangeStartLength(element.nameOffset, 'MyClass'.length));
  }

  void test_new_forMatch() {
    resolveTestUnit('class MyClass {}');
    Element element = findElement('MyClass');
    SourceRange range = rangeElementName(element);
    SearchMatch match = new SearchMatch(null, element, range, true, false);
    var statusContext = new RefactoringStatusContext.forMatch(match);
    // access
    expect(statusContext.context, context);
    expect(statusContext.source, testSource);
    expect(statusContext.range, range);
  }

  void test_new_forNode() {
    resolveTestUnit('''
main() {
}
''');
    AstNode node = findNodeAtString('main');
    var statusContext = new RefactoringStatusContext.forNode(node);
    // access
    expect(statusContext.context, context);
    expect(statusContext.source, testSource);
    expect(statusContext.range, rangeNode(node));
  }

  void test_new_forUnit() {
    resolveTestUnit('');
    SourceRange range = rangeStartLength(10, 20);
    var statusContext = new RefactoringStatusContext.forUnit(testUnit, range);
    // access
    expect(statusContext.context, context);
    expect(statusContext.source, testSource);
    expect(statusContext.range, range);
  }
}


@ReflectiveTestCase()
class RefactoringStatusEntryTest {
  void test_new_withContext() {
    RefactoringStatusContext context = new _MockRefactoringStatusContext();
    RefactoringStatusEntry entry =
        new RefactoringStatusEntry(
            RefactoringStatusSeverity.ERROR,
            "my message",
            context);
    // access
    expect(entry.severity, RefactoringStatusSeverity.ERROR);
    expect(entry.message, 'my message');
    expect(entry.context, context);
  }

  void test_new_withoutContext() {
    RefactoringStatusEntry entry =
        new RefactoringStatusEntry(RefactoringStatusSeverity.ERROR, "my message");
    // access
    expect(entry.severity, RefactoringStatusSeverity.ERROR);
    expect(entry.message, 'my message');
    expect(entry.context, isNull);
    // isX
    expect(entry.isFatalError, isFalse);
    expect(entry.isError, isTrue);
    expect(entry.isWarning, isFalse);
  }
}


@ReflectiveTestCase()
class RefactoringStatusTest {
  void test_addError() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, RefactoringStatusSeverity.OK);
    // add ERROR
    refactoringStatus.addError('msg');
    expect(refactoringStatus.severity, RefactoringStatusSeverity.ERROR);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isFalse);
    expect(refactoringStatus.hasError, isTrue);
    // entries
    List<RefactoringStatusEntry> entries = refactoringStatus.entries;
    expect(entries, hasLength(1));
    expect(entries[0].message, 'msg');
  }

  void test_addFatalError_withContext() {
    RefactoringStatusContext context = new _MockRefactoringStatusContext();
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, RefactoringStatusSeverity.OK);
    // add FATAL
    refactoringStatus.addFatalError('msg', context);
    expect(refactoringStatus.severity, RefactoringStatusSeverity.FATAL);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isTrue);
    expect(refactoringStatus.hasError, isTrue);
    // entries
    List<RefactoringStatusEntry> entries = refactoringStatus.entries;
    expect(entries, hasLength(1));
    expect(entries[0].message, 'msg');
    expect(entries[0].context, context);
    // add WARNING, resulting severity is still FATAL
    refactoringStatus.addWarning("warning");
    expect(refactoringStatus.severity, RefactoringStatusSeverity.FATAL);
  }

  void test_addFatalError_withoutContext() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, RefactoringStatusSeverity.OK);
    // add FATAL
    refactoringStatus.addFatalError('msg');
    expect(refactoringStatus.severity, RefactoringStatusSeverity.FATAL);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isTrue);
    expect(refactoringStatus.hasError, isTrue);
    // entries
    List<RefactoringStatusEntry> entries = refactoringStatus.entries;
    expect(entries, hasLength(1));
    expect(entries[0].message, 'msg');
    expect(entries[0].context, isNull);
  }

  void test_addStatus_Error_withWarning() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    refactoringStatus.addError("err");
    expect(refactoringStatus.severity, RefactoringStatusSeverity.ERROR);
    // merge with OK
    {
      RefactoringStatus other = new RefactoringStatus();
      other.addWarning("warn");
      refactoringStatus.addStatus(other);
    }
    expect(refactoringStatus.severity, RefactoringStatusSeverity.ERROR);
    expect(refactoringStatus.message, 'err');
  }

  void test_addStatus_Warning_null() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    refactoringStatus.addWarning("warn");
    expect(refactoringStatus.severity, RefactoringStatusSeverity.WARNING);
    // merge with "null"
    refactoringStatus.addStatus(null);
    expect(refactoringStatus.severity, RefactoringStatusSeverity.WARNING);
  }

  void test_addStatus_Warning_withError() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    refactoringStatus.addWarning("warn");
    expect(refactoringStatus.severity, RefactoringStatusSeverity.WARNING);
    // merge with OK
    {
      RefactoringStatus other = new RefactoringStatus();
      other.addError("err");
      refactoringStatus.addStatus(other);
    }
    expect(refactoringStatus.severity, RefactoringStatusSeverity.ERROR);
    expect(refactoringStatus.message, 'err');
  }

  void test_addWarning() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // initial state
    expect(refactoringStatus.severity, RefactoringStatusSeverity.OK);
    // add WARNING
    refactoringStatus.addWarning('msg');
    expect(refactoringStatus.severity, RefactoringStatusSeverity.WARNING);
    expect(refactoringStatus.isOK, isFalse);
    expect(refactoringStatus.hasFatalError, isFalse);
    expect(refactoringStatus.hasError, isFalse);
    expect(refactoringStatus.hasWarning, isTrue);
    // entries
    List<RefactoringStatusEntry> entries = refactoringStatus.entries;
    expect(entries, hasLength(1));
    expect(entries[0].message, 'msg');
  }

  void test_escalateErrorToFatal() {
    RefactoringStatus refactoringStatus = new RefactoringStatus.error('msg');
    expect(refactoringStatus.severity, RefactoringStatusSeverity.ERROR);
    // escalated
    RefactoringStatus escalated = refactoringStatus.escalateErrorToFatal();
    expect(escalated.severity, RefactoringStatusSeverity.FATAL);
  }

  void test_get_entryWithHighestSeverity() {
    RefactoringStatus refactoringStatus = new RefactoringStatus();
    // no entries
    expect(refactoringStatus.entryWithHighestSeverity, isNull);
    expect(refactoringStatus.message, isNull);
    // add entries
    refactoringStatus.addError('msgError');
    refactoringStatus.addWarning('msgWarning');
    refactoringStatus.addFatalError('msgFatalError');
    // get entry
    {
      RefactoringStatusEntry entry = refactoringStatus.entryWithHighestSeverity;
      expect(entry.severity, RefactoringStatusSeverity.FATAL);
      expect(entry.message, 'msgFatalError');
    }
    // get message
    expect(refactoringStatus.message, 'msgFatalError');
  }

  void test_newError() {
    RefactoringStatusContext context = new _MockRefactoringStatusContext();
    RefactoringStatus refactoringStatus =
        new RefactoringStatus.error('msg', context);
    expect(refactoringStatus.severity, RefactoringStatusSeverity.ERROR);
    expect(refactoringStatus.message, 'msg');
    expect(refactoringStatus.entryWithHighestSeverity.context, context);
  }

  void test_newFatalError() {
    RefactoringStatus refactoringStatus = new RefactoringStatus.fatal('msg');
    expect(refactoringStatus.severity, RefactoringStatusSeverity.FATAL);
    expect(refactoringStatus.message, 'msg');
  }

  void test_newWarning() {
    RefactoringStatus refactoringStatus = new RefactoringStatus.warning('msg');
    expect(refactoringStatus.severity, RefactoringStatusSeverity.WARNING);
    expect(refactoringStatus.message, 'msg');
  }
}


class _MockRefactoringStatusContext extends TypedMock implements
    RefactoringStatusContext {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
