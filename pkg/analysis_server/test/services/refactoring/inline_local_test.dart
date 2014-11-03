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
      expect(refactoring.variableName, 'test');
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

  test_OK_intoStringInterpolation_binaryExpression() {
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

  test_OK_intoStringInterpolation_simpleIdentifier() {
    indexTestUnit(r'''
main() {
  int foo = 1 + 2;
  int test = foo;
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
  int foo = 1 + 2;
  print('test = $foo');
  print('test = ${foo}');
  print('test = ${process(foo)}');
}
process(x) {}
''');
  }

  test_OK_intoStringInterpolation_string_differentQuotes() {
    indexTestUnit(r'''
main() {
  String a = "aaa";
  String b = '$a bbb';
}
''');
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  String b = '${"aaa"} bbb';
}
''');
  }

  test_OK_intoStringInterpolation_string_doubleQuotes() {
    indexTestUnit(r'''
main() {
  String a = "aaa";
  String b = "$a bbb";
}
''');
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  String b = "aaa bbb";
}
''');
  }

  test_OK_intoStringInterpolation_string_multiLineIntoMulti_unixEOL() {
    indexTestUnit(r"""
main() {
  String a = '''
a
a
a''';
  String b = '''
$a
bbb''';
}
""");
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r"""
main() {
  String b = '''
a
a
a
bbb''';
}
""");
  }

  test_OK_intoStringInterpolation_string_multiLineIntoMulti_windowsEOL() {
    indexTestUnit(r"""
main() {
  String a = '''
a
a
a''';
  String b = '''
$a
bbb''';
}
""".replaceAll('\n', '\r\n'));
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r"""
main() {
  String b = '''
a
a
a
bbb''';
}
""".replaceAll('\n', '\r\n'));
  }

  test_OK_intoStringInterpolation_string_multiLineIntoSingle() {
    indexTestUnit(r'''
main() {
  String a = """aaa""";
  String b = "$a bbb";
}
''');
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  String b = "${"""aaa"""} bbb";
}
''');
  }

  test_OK_intoStringInterpolation_string_raw() {
    indexTestUnit(r'''
main() {
  String a = r'an $ignored interpolation';
  String b = '$a bbb';
}
''');
    _createRefactoring('a =');
    // we don't unwrap raw strings
    return assertSuccessfulRefactoring(r'''
main() {
  String b = '${r'an $ignored interpolation'} bbb';
}
''');
  }

  test_OK_intoStringInterpolation_string_singleLineIntoMulti_doubleQuotes() {
    indexTestUnit(r'''
main() {
  String a = "aaa";
  String b = """$a bbb""";
}
''');
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  String b = """aaa bbb""";
}
''');
  }

  test_OK_intoStringInterpolation_string_singleLineIntoMulti_singleQuotes() {
    indexTestUnit(r"""
main() {
  String a = 'aaa';
  String b = '''$a bbb''';
}
""");
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r"""
main() {
  String b = '''aaa bbb''';
}
""");
  }

  test_OK_intoStringInterpolation_string_singleQuotes() {
    indexTestUnit(r'''
main() {
  String a = 'aaa';
  String b = '$a bbb';
}
''');
    _createRefactoring('a =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  String b = 'aaa bbb';
}
''');
  }

  test_OK_intoStringInterpolation_stringInterpolation() {
    indexTestUnit(r'''
main() {
  String a = 'aaa';
  String b = '$a bbb';
  String c = '$b ccc';
}
''');
    _createRefactoring('b =');
    // validate change
    return assertSuccessfulRefactoring(r'''
main() {
  String a = 'aaa';
  String c = '$a bbb ccc';
}
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

  test_OK_parenthesis_decrement_intoNegate() {
    indexTestUnit('''
main() {
  var a = 1;
  var test = --a;
  var b = -test;
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  var a = 1;
  var b = -(--a);
}
''');
  }

  test_OK_parenthesis_instanceCreation_intoList() {
    indexTestUnit('''
class A {}
main() {
  var test = new A();
  var list = [test];
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
class A {}
main() {
  var list = [new A()];
}
''');
  }

  test_OK_parenthesis_negate_intoNegate() {
    indexTestUnit('''
main() {
  var a = 1;
  var test = -a;
  var b = -test;
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  var a = 1;
  var b = -(-a);
}
''');
  }

  test_OK_parenthesis_plus_intoMultiply() {
    indexTestUnit('''
main() {
  var test = 1 + 2;
  print(test * 3);
}
''');
    _createRefactoring('test =');
    // validate change
    return assertSuccessfulRefactoring('''
main() {
  print((1 + 2) * 3);
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

  void _assert_fatalError_selection(RefactoringStatus status) {
    expect(refactoring.variableName, isNull);
    expect(refactoring.referenceCount, 0);
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
