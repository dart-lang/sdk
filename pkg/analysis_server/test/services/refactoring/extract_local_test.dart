// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.extract_local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/refactoring/extract_local.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import '../../reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'abstract_refactoring.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ExtractLocalTest);
}


@ReflectiveTestCase()
class ExtractLocalTest extends RefactoringTest {
  ExtractLocalRefactoringImpl refactoring;

  test_checkFinalConditions_sameVariable_after() {
    indexTestUnit('''
main() {
  int a = 1 + 2;
  var res;
}
''');
    _createRefactoringForString('1 + 2');
    // conflicting name
    return refactoring.checkAllConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.WARNING,
          expectedMessage:
              "A variable with name 'res' is already defined in the visible scope.");
    });
  }

  test_checkFinalConditions_sameVariable_before() {
    indexTestUnit('''
main() {
  var res;
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // conflicting name
    return refactoring.checkAllConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.WARNING,
          expectedMessage:
              "A variable with name 'res' is already defined in the visible scope.");
    });
  }

  test_checkInitialConditions_assignmentLeftHandSize() {
    indexTestUnit('''
main() {
  var v = 0;
  v = 1;
}
''');
    _createRefactoringWithSuffix('v', ' = 1;');
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: 'Cannot extract the left-hand side of an assignment.');
    });
  }

  test_checkInitialConditions_methodName_reference() {
    indexTestUnit('''
main() {
  main();
}
''');
    _createRefactoringWithSuffix('main', '();');
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: 'Cannot extract a single method name.');
    });
  }

  test_checkInitialConditions_nameOfProperty_prefixedIdentifier() {
    indexTestUnit('''
main(p) {
  p.value; // marker
}
''');
    _createRefactoringWithSuffix('value', '; // marker');
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: 'Cannot extract name part of a property access.');
    });
  }

  test_checkInitialConditions_nameOfProperty_propertyAccess() {
    indexTestUnit('''
main() {
  foo().length; // marker
}
String foo() => '';
''');
    _createRefactoringWithSuffix('length', '; // marker');
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: 'Cannot extract name part of a property access.');
    });
  }

  test_checkInitialConditions_namePartOfDeclaration_variable() {
    indexTestUnit('''
main() {
  int vvv = 0;
}
''');
    _createRefactoringWithSuffix('vvv', ' = 0;');
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: 'Cannot extract the name part of a declaration.');
    });
  }

  test_checkInitialConditions_notPartOfFunction() {
    indexTestUnit('''
int a = 1 + 2;
''');
    _createRefactoringForString('1 + 2');
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage:
              'Expression inside of function must be selected to activate this refactoring.');
    });
  }

  test_checkInitialConditions_stringSelection_leadingQuote() {
    indexTestUnit('''
main() {
  var vvv = 'abc';
}
''');
    _createRefactoringForString("'a");
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage:
              'Cannot extract only leading or trailing quote of string literal.');
    });
  }

  test_checkInitialConditions_stringSelection_trailingQuote() {
    indexTestUnit('''
main() {
  var vvv = 'abc';
}
''');
    _createRefactoringForString("c'");
    // check conditions
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage:
              'Cannot extract only leading or trailing quote of string literal.');
    });
  }

  test_checkLocalName() {
    indexTestUnit('''
main() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    expect(refactoring.refactoringName, 'Extract Local Variable');
    // null
    refactoring.name = null;
    assertRefactoringStatus(
        refactoring.checkName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Variable name must not be null.");
    // empty
    refactoring.name = '';
    assertRefactoringStatus(
        refactoring.checkName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Variable name must not be empty.");
    // OK
    refactoring.name = 'res';
    assertRefactoringStatusOK(refactoring.checkName());
  }

  test_completeStatementExpression() {
    indexTestUnit('''
main(p) {
  p.toString();
}
''');
    _createRefactoringForString('p.toString()');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main(p) {
  var res = p.toString();
}
''');
  }

  test_const_argument_inConstInstanceCreation() {
    indexTestUnit('''
class A {
  const A(int a, int b);
}
main() {
  const A(1, 2);
}
''');
    _createRefactoringForString('1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  const A(int a, int b);
}
main() {
  const res = 1;
  const A(res, 2);
}
''');
  }

  test_const_inList() {
    indexTestUnit('''
main() {
  const [1, 2];
}
''');
    _createRefactoringForString('1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  const res = 1;
  const [res, 2];
}
''');
  }

  test_const_inList_inBinaryExpression() {
    indexTestUnit('''
main() {
  const [1 + 2, 3];
}
''');
    _createRefactoringForString('1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  const res = 1;
  const [res + 2, 3];
}
''');
  }

  test_const_inList_inConditionalExpression() {
    indexTestUnit('''
main(bool b) {
  const [b ? 1 : 2, 3];
}
''');
    _createRefactoringForString('1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main(bool b) {
  const res = 1;
  const [b ? res : 2, 3];
}
''');
  }

  test_const_inList_inParenthesis() {
    indexTestUnit('''
main() {
  const [(1), 2];
}
''');
    _createRefactoringForString('1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  const res = 1;
  const [(res), 2];
}
''');
  }

  test_const_inList_inPrefixExpression() {
    indexTestUnit('''
main() {
  const [!true, 2];
}
''');
    _createRefactoringForString('true');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  const res = true;
  const [!res, 2];
}
''');
  }

  test_const_inMap_key() {
    indexTestUnit('''
main() {
  const {1: 2};
}
''');
    _createRefactoringForString('1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  const res = 1;
  const {res: 2};
}
''');
  }

  test_const_inMap_value() {
    indexTestUnit('''
main() {
  const {1: 2};
}
''');
    _createRefactoringForString('2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  const res = 2;
  const {1: res};
}
''');
  }

  test_fragmentExpression() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 4;
}
''');
    _createRefactoringForString('2 + 3');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 2 + 3;
  int a = 1 + res + 4;
}
''');
  }

  test_fragmentExpression_leadingNotWhitespace() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 4;
}
''');
    _createRefactoringForString('+ 2');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_fragmentExpression_leadingPartialSelection() {
    indexTestUnit('''
main() {
  int a = 111 + 2 + 3 + 4;
}
''');
    _createRefactoringForString('11 + 2');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_fragmentExpression_leadingWhitespace() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 4;
}
''');
    _createRefactoringForString(' 2 + 3');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res =  2 + 3;
  int a = 1 +res + 4;
}
''');
  }

  test_fragmentExpression_notAssociativeOperator() {
    indexTestUnit('''
main() {
  int a = 1 - 2 - 3 - 4;
}
''');
    _createRefactoringForString('2 - 3');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_fragmentExpression_trailingNotWhitespace() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 4;
}
''');
    _createRefactoringForString('2 + 3 +');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_fragmentExpression_trailingPartialSelection() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 444;
}
''');
    _createRefactoringForString('2 + 3 + 44');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_fragmentExpression_trailingWhitespace() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 4;
}
''');
    _createRefactoringForString('2 + 3 ');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 2 + 3 ;
  int a = 1 + res+ 4;
}
''');
  }

  test_guessNames_fragmentExpression() {
    indexTestUnit('''
main() {
  var a = 111 + 222 + 333 + 444;
}
''');
    _createRefactoringForString('222 + 333');
    // check guesses
    return refactoring.checkInitialConditions().then((_) {
      expect(refactoring.names, isEmpty);
    });
  }

  test_guessNames_singleExpression() {
    indexTestUnit('''
class TreeItem {}
TreeItem getSelectedItem() => null;
process(my) {}
main() {
  process(getSelectedItem()); // marker
}
''');
    _createRefactoringWithSuffix('getSelectedItem()', '); // marker');
    // check guesses
    return refactoring.checkInitialConditions().then((_) {
      expect(
          refactoring.names,
          unorderedEquals(['selectedItem', 'item', 'my', 'treeItem']));
    });
  }

  test_guessNames_stringPart() {
    indexTestUnit('''
main() {
  var s = 'Hello Bob... welcome to Dart!';
}
''');
    _createRefactoringForString('Hello Bob');
    // check guesses
    return refactoring.checkInitialConditions().then((_) {
      expect(refactoring.names, unorderedEquals(['helloBob', 'bob']));
    });
  }

  test_occurences_disableOccurences() {
    indexTestUnit('''
int foo() => 42;
main() {
  int a = 1 + foo();
  int b = 2 + foo(); // marker
}
''');
    _createRefactoringWithSuffix('foo()', '; // marker');
    refactoring.extractAll = false;
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int foo() => 42;
main() {
  int a = 1 + foo();
  var res = foo();
  int b = 2 + res; // marker
}
''');
  }

  test_occurences_ignore_assignmentLeftHandSize() {
    indexTestUnit('''
main() {
  int v = 1;
  v = 2;
  print(() {v = 2;});
  print(1 + (() {v = 2; return 3;})());
  print(v); // marker
}
''');
    _createRefactoringWithSuffix('v', '); // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  int v = 1;
  v = 2;
  print(() {v = 2;});
  print(1 + (() {v = 2; return 3;})());
  var res = v;
  print(res); // marker
}
''');
  }

  test_occurences_ignore_nameOfVariableDeclariton() {
    indexTestUnit('''
main() {
  int v = 1;
  print(v); // marker
}
''');
    _createRefactoringWithSuffix('v', '); // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  int v = 1;
  var res = v;
  print(res); // marker
}
''');
  }

  test_occurences_singleExpression() {
    indexTestUnit('''
int foo() => 42;
main() {
  int a = 1 + foo();
  int b = 2 +  foo(); // marker
}
''');
    _createRefactoringWithSuffix('foo()', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int foo() => 42;
main() {
  var res = foo();
  int a = 1 + res;
  int b = 2 +  res; // marker
}
''');
  }

  test_occurences_useDominator() {
    indexTestUnit('''
main() {
  if (true) {
    print(42);
  } else {
    print(42);
  }
}
''');
    _createRefactoringForString('42');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 42;
  if (true) {
    print(res);
  } else {
    print(res);
  }
}
''');
  }

  test_occurences_whenComment() {
    indexTestUnit('''
int foo() => 42;
main() {
  /*int a = 1 + foo();*/
  int b = 2 + foo(); // marker
}
''');
    _createRefactoringWithSuffix('foo()', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int foo() => 42;
main() {
  /*int a = 1 + foo();*/
  var res = foo();
  int b = 2 + res; // marker
}
''');
  }

  test_occurences_withSpace() {
    indexTestUnit('''
int foo(String s) => 42;
main() {
  int a = 1 + foo('has space');
  int b = 2 + foo('has space'); // marker
}
''');
    _createRefactoringWithSuffix("foo('has space')", '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int foo(String s) => 42;
main() {
  var res = foo('has space');
  int a = 1 + res;
  int b = 2 + res; // marker
}
''');
  }

  test_offsets_lengths() {
    indexTestUnit('''
int foo() => 42;
main() {
  int a = 1 + foo(); // marker
  int b = 2 + foo( );
}
''');
    _createRefactoringWithSuffix('foo()', '; // marker');
    // apply refactoring
    return refactoring.checkInitialConditions().then((_) {
      expect(
          refactoring.offsets,
          unorderedEquals([findOffset('foo();'), findOffset('foo( );')]));
      expect(refactoring.lengths, unorderedEquals([5, 6]));
    });
  }

  test_singleExpression() {
    indexTestUnit('''
main() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 1 + 2;
  int a = res;
}
''');
  }

  test_singleExpression_getter() {
    indexTestUnit('''
class A {
  int get foo => 42;
}
main() {
  A a = new A();
  int b = 1 + a.foo; // marker
}
''');
    _createRefactoringWithSuffix('a.foo', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  int get foo => 42;
}
main() {
  A a = new A();
  var res = a.foo;
  int b = 1 + res; // marker
}
''');
  }

  test_singleExpression_inMethod() {
    indexTestUnit('''
class A {
  main() {
    print(1 + 2);
  }
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  main() {
    var res = 1 + 2;
    print(res);
  }
}
''');
  }

  test_singleExpression_leadingNotWhitespace() {
    indexTestUnit('''
main() {
  int a = 12 + 345;
}
''');
    _createRefactoringForString('+ 345');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_singleExpression_leadingWhitespace() {
    indexTestUnit('''
main() {
  int a = 12 /*abc*/ + 345;
}
''');
    _createRefactoringForString('12 /*abc*/');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 12 /*abc*/;
  int a = res + 345;
}
''');
  }

  /**
   * Here we use knowledge how exactly `1 + 2 + 3 + 41 is parsed. We know that
   * `1 + 2` will be a separate and complete binary expression, so it can be
   * handled as a single expression.
   */
  test_singleExpression_partOfBinaryExpression() {
    indexTestUnit('''
main() {
  int a = 1 + 2 + 3 + 4;
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 1 + 2;
  int a = res + 3 + 4;
}
''');
  }

  test_singleExpression_trailingComment() {
    indexTestUnit('''
main() {
  int a =  1 + 2;
}
''');
    _createRefactoringForString(' 1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res =  1 + 2;
  int a = res;
}
''');
  }

  test_singleExpression_trailingNotWhitespace() {
    indexTestUnit('''
main() {
  int a = 12 + 345;
}
''');
    _createRefactoringForString('12 +');
    // check conditions
    return _assertInitialConditions_fatal_selection();
  }

  test_singleExpression_trailingWhitespace() {
    indexTestUnit('''
main() {
  int a = 1 + 2 ;
}
''');
    _createRefactoringForString('1 + 2 ');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 1 + 2 ;
  int a = res;
}
''');
  }

  test_stringLiteral_part() {
    indexTestUnit('''
main() {
  print('abcdefgh');
}
''');
    _createRefactoringForString('cde');
    // apply refactoring
    return _assertSuccessfulRefactoring(r'''
main() {
  var res = 'cde';
  print('ab${res}fgh');
}
''');
  }

  test_stringLiteral_whole() {
    indexTestUnit('''
main() {
  print('abc');
}
''');
    _createRefactoringForString("'abc'");
    // apply refactoring
    return _assertSuccessfulRefactoring('''
main() {
  var res = 'abc';
  print(res);
}
''');
  }

  Future _assertInitialConditions_fatal_selection() {
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.FATAL,
          expectedMessage: 'Expression must be selected to activate this refactoring.');
    });
  }

  /**
   * Checks that all conditions are OK and the result of applying the [Change]
   * to [testUnit] is [expectedCode].
   */
  Future _assertSuccessfulRefactoring(String expectedCode) {
    return assertRefactoringConditionsOK().then((_) {
      return refactoring.createChange().then((SourceChange refactoringChange) {
        this.refactoringChange = refactoringChange;
        assertTestChangeResult(expectedCode);
      });
    });
  }

  void _createRefactoring(int offset, int length) {
    refactoring = new ExtractLocalRefactoring(testUnit, offset, length);
    refactoring.name = 'res';
  }

  /**
   * Creates a new refactoring in [refactoring] for the selection range of the
   * given [search] pattern.
   */
  void _createRefactoringForString(String search) {
    int offset = findOffset(search);
    int length = search.length;
    _createRefactoring(offset, length);
  }

  void _createRefactoringWithSuffix(String selectionSearch, String suffix) {
    int offset = findOffset(selectionSearch + suffix);
    int length = selectionSearch.length;
    _createRefactoring(offset, length);
  }
}
