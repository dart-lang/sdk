// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.inline_local;

import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/inline_local.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'abstract_refactoring.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(InlineLocalTest);
}


@ReflectiveTestCase()
class InlineLocalTest extends RefactoringTest {
  InlineLocalRefactoringImpl refactoring;

  test_OK_cascade_intoCascade() {
    indexTestUnit(r'''
class A {
  foo() {}
  bar() {}
}
main() {
  A test = new A()..foo();
  test..bar();
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring(r'''
class A {
  foo() {}
  bar() {}
}
main() {
  new A()..foo()..bar();
}
''');
  }

  test_OK_cascade_intoNotCascade() {
    indexTestUnit(r'''
class A {
  foo() {}
  bar() {}
}
main() {
  A test = new A()..foo();
  test.bar();
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring(r'''
class A {
  foo() {}
  bar() {}
}
main() {
  (new A()..foo()).bar();
}
''');
  }

  test_OK_intoStringInterpolation() {
    indexTestUnit(r'''
main() {
  int test = 1 + 2;
  print('test = $test');
  print('test = ${test}');
  print('test = ${process(test)}');
}
process(x) {}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  print('test = ${1 + 2}');
  print('test = ${1 + 2}');
  print('test = ${process(1 + 2)}');
}
process(x) {}
''');
  }

  /**
   * <p>
   * https://code.google.com/p/dart/issues/detail?id=18587
   */
  test_OK_keepNextCommentedLine() {
    indexTestUnit('''
main() {
  int test = 1 + 2;
  // foo
  print(test);
  // bar
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  // foo
  print(1 + 2);
  // bar
}
''');
  }

  test_OK_noUsages_1() {
    indexTestUnit('''
main() {
  int test = 1 + 2;
  print(0);
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  print(0);
}
''');
  }

  test_OK_noUsages_2() {
    indexTestUnit('''
main() {
  int test = 1 + 2;
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
}
''');
  }

  test_OK_oneUsage() {
    indexTestUnit('''
main() {
  int test = 1 + 2;
  print(test);
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  print(1 + 2);
}
''');
  }

  test_OK_twoUsages() {
    indexTestUnit('''
main() {
  int test = 1 + 2;
  print(test);
  print(test);
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  print(1 + 2);
  print(1 + 2);
}
''');
  }

  test_access() {
    indexTestUnit('''
main() {
  int test = 1 + 2;
  print(test);
  print(test);
}
''');
    _createRefactoring('test =');
    expect(refactoring.refactoringName, 'Inline Local Variable');
    // check initial conditions and access
    return refactoring.checkInitialConditions().then((_) {
      expect(refactoring.referenceCount, 2);
    });
  }

  test_bad_selectionMethod() {
    indexTestUnit(r'''
main() {
}
''');
    _createRefactoring('main() {');
    return refactoring.checkInitialConditions().then((status) {
      _assert_fatalError_selection(status);
    });
  }

  test_bad_selectionParameter() {
    indexTestUnit(r'''
main(int test) {
}
''');
    _createRefactoring('test) {');
    return refactoring.checkInitialConditions().then((status) {
      _assert_fatalError_selection(status);
    });
  }

  test_bad_selectionVariable_hasAssignments_1() {
    indexTestUnit(r'''
main() {
  int test = 0;
  test = 1;
}
''');
    _createRefactoring('test = 0');
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedContextSearch: 'test = 1');
    });
  }

  test_bad_selectionVariable_hasAssignments_2() {
    indexTestUnit(r'''
main() {
  int test = 0;
  test += 1;
}
''');
    _createRefactoring('test = 0');
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedContextSearch: 'test += 1');
    });
  }

  test_bad_selectionVariable_notInBlock() {
    indexTestUnit(r'''
main() {
  if (true)
    int test = 0;
}
''');
    _createRefactoring('test = 0');
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
    });
  }

  test_bad_selectionVariable_notInitialized() {
    indexTestUnit(r'''
main() {
  int test;
}
''');
    _createRefactoring('test;');
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
    });
  }

  void _assert_fatalError_selection(RefactoringStatus status) {
    assertRefactoringStatus(
        status,
        RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Local variable declaration or reference must be '
            'selected to activate this refactoring.');
  }

  void _createRefactoring(String search) {
    int offset = findOffset(search);
    refactoring = new InlineLocalRefactoring(searchEngine, testUnit, offset);
  }
}
