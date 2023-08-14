// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LabelTest1);
    defineReflectiveTests(LabelTest2);
  });
}

@reflectiveTest
class LabelTest1 extends AbstractCompletionDriverTest with LabelTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LabelTest2 extends AbstractCompletionDriverTest with LabelTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin LabelTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_break_ignoresLabelsOnUnrelatedStatements() async {
    await computeSuggestions('''
void f() {
  f0: while (true) {}
  while (true) { break ^ }
  b0: while (true) {}
}
''');
    // The scope of the label defined by a labeled statement is just the
    // statement itself, so neither "f0" nor "b0" are in scope at the caret
    // position.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_break_ignoresLabelsOutsideClosure() async {
    await computeSuggestions('''
void g() {
  f0: while (true) {
    var f = () {
      b0: while (true) { break ^ }
    };
  }
}
''');
    // The purpose of this test is to ensure that `f0` is not suggested.
    assertResponse(r'''
suggestions
  b0
    kind: label
''');
  }

  Future<void> test_break_ignoresLabelsOutsideLocalFunction() async {
    await computeSuggestions('''
void g() {
  f0: while (true) {
    void f() {
      b0: while (true) { break ^ }
    };
  }
}
''');
    // The purpose of this test is to ensure that `f0` is not suggested.
    assertResponse(r'''
suggestions
  b0
    kind: label
''');
  }

  Future<void> test_break_ignoresToplevelVariables() async {
    await computeSuggestions('''
int x0;
void f() {
  while (true) {
    break ^
  }
}
''');
    // The purpose of this test is to ensure that `x0` is not suggested.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_break_inNestedLoop() async {
    await computeSuggestions('''
void f() {
  f0: while (true) {
    b0: while (true) {
      break ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: label
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromCaseLabels_after() async {
    await computeSuggestions('''
void f() {
  switch (x) {
    case 1:
      break;
    case 2:
      continue ^;
    f0: case 3:
      break;
''');
    assertResponse(r'''
suggestions
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromCaseLabels_all() async {
    await computeSuggestions('''
void f() {
  switch (x) {
    f0: case 1:
      break;
    b0: case 2:
      while (true) {
        continue ^;
      }
      break;
    b1: case 3:
      break;
  }
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: label
  b1
    kind: label
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromCaseLabels_before() async {
    await computeSuggestions('''
void f() {
  switch (x) {
    f0: case 1:
      break;
    case 2:
      continue ^;
    case 3:
      break;
''');
    assertResponse(r'''
suggestions
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromCaseLabels_same() async {
    await computeSuggestions('''
void f() {
  switch (x) {
    case 1:
      break;
    f0: case 2:
      continue ^;
    case 3:
      break;
''');
    assertResponse(r'''
suggestions
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromEnclosingSwitch() async {
    await computeSuggestions('''
void f() {
  switch (x) {
    f0: case 1:
      break;
    b0: case 2:
      switch (y) {
        case 1:
          continue ^;
      }
      break;
    b1: case 3:
      break;
  }
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: label
  b1
    kind: label
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromOuterLoop() async {
    await computeSuggestions('''
void f() {
  f0: while (true) {
    switch (x) {
      case 1:
        continue ^;
    }
  }
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: label
''');
  }

  Future<void> test_continue_fromOuterLoop2() async {
    await computeSuggestions('''
void f() {
  f0: while (true) {
    b0: while (true) {
      continue ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: label
  f0
    kind: label
''');
  }

  Future<void> test_continue_ignoresLabelsOnUnrelatedStatements() async {
    await computeSuggestions('''
void f() {
  f0: while (true) {}
  while (true) { continue ^ }
  b0: while (true) {}
}
''');
    // The scope of the label defined by a labeled statement is just the
    // statement itself, so neither "f0" nor "b0" are in scope at the caret
    // position.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_continue_ignoresLabelsOutsideClosure() async {
    await computeSuggestions('''
void f() {
  f0: while (true) {
    var f = () {
      b0: while (true) { continue ^ }
    };
  }
}
''');
    // The purpose of this test is to ensure that `f0` is not suggested.
    assertResponse(r'''
suggestions
  b0
    kind: label
''');
  }

  Future<void> test_continue_ignoresLabelsOutsideClosure2() async {
    await computeSuggestions('''
void g() {
  switch (x) {
    f0: case 1:
      var f = () {
        b0: while (true) { continue ^ }
      };
  }
}
''');
    // The purpose of this test is to ensure that `f0` is not suggested.
    assertResponse(r'''
suggestions
  b0
    kind: label
''');
  }

  Future<void> test_continue_ignoresLabelsOutsideLocalFunction() async {
    await computeSuggestions('''
void g() {
  f0: while (true) {
    void f() {
      b0: while (true) { continue ^ }
    };
  }
}
''');
    // The purpose of this test is to ensure that `f0` is not suggested.
    assertResponse(r'''
suggestions
  b0
    kind: label
''');
  }

  Future<void> test_continue_ignoresLabelsOutsideLocalFunction2() async {
    await computeSuggestions('''
void g() {
  switch (x) {
    f0: case 1:
      void f() {
        b0: while (true) { continue ^ }
      };
  }
}
''');
    // The purpose of this test is to ensure that `f0` is not suggested.
    assertResponse(r'''
suggestions
  b0
    kind: label
''');
  }
}
