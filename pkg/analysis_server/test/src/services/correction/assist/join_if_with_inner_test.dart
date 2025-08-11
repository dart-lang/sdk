// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JoinIfWithInnerTest);
  });
}

@reflectiveTest
class JoinIfWithInnerTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.joinIfWithInner;

  Future<void> test_bothOuterAndInnerAreIfCase() async {
    await resolveTestCode('''
void f(Object? p) {
  ^if (p case final v?) {
    if (v case final int x) {
      print(0);
    }
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_conditionAndOr() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    if (2 == 2 || 3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1 && (2 == 2 || 3 == 3)) {
    print(0);
  }
}
''');
  }

  Future<void> test_conditionInvocation() async {
    await resolveTestCode('''
void f() {
  ^if (isCheck()) {
    if (2 == 2) {
      print(0);
    }
  }
}
bool isCheck() => false;
''');
    await assertHasAssist('''
void f() {
  if (isCheck() && 2 == 2) {
    print(0);
  }
}
bool isCheck() => false;
''');
  }

  Future<void> test_conditionOrAnd() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1 || 2 == 2) {
    if (3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if ((1 == 1 || 2 == 2) && 3 == 3) {
    print(0);
  }
}
''');
  }

  Future<void> test_ifCaseAddWhen() async {
    await resolveTestCode('''
void f(Object? p) {
  i^f (p case final int v) {
    if (v == 5) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f(Object? p) {
  if (p case final int v when v == 5) {
    print(0);
  }
}
''');
  }

  Future<void> test_ifCaseAddWhenUnrelated() async {
    await resolveTestCode('''
void f(Object? p, Object? q) {
  ^if (p case final int v) {
    if (q != null) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f(Object? p, Object? q) {
  if (p case final int v when q != null) {
    print(0);
  }
}
''');
  }

  Future<void> test_ifCaseAppendWhen() async {
    await resolveTestCode('''
void f(Object? p) {
  if^ (p case final int v when v.isOdd) {
    if (v == 5) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f(Object? p) {
  if (p case final int v when v.isOdd && v == 5) {
    print(0);
  }
}
''');
  }

  Future<void> test_ifCaseAppendWhenWithParenthesisBoth() async {
    await resolveTestCode('''
void f(Object? p) {
  i^f (p case final int v when v.isOdd || v > 3) {
    if (v == 5 || v != 6) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f(Object? p) {
  if (p case final int v when (v.isOdd || v > 3) && (v == 5 || v != 6)) {
    print(0);
  }
}
''');
  }

  Future<void> test_ifCaseAppendWhenWithParenthesisInner() async {
    await resolveTestCode('''
void f(Object? p) {
  i^f (p case final int v when v.isOdd) {
    if (v == 5 || v != 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f(Object? p) {
  if (p case final int v when v.isOdd && (v == 5 || v != 3)) {
    print(0);
  }
}
''');
  }

  Future<void> test_ifCaseAppendWhenWithParenthesisOuter() async {
    await resolveTestCode('''
void f(Object? p) {
  i^f (p case final int v when v.isOdd || v != 3) {
    if (v == 5) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f(Object? p) {
  if (p case final int v when (v.isOdd || v != 3) && v == 5) {
    print(0);
  }
}
''');
  }

  Future<void> test_innerNotIf() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_innerWithElse() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    if (2 == 2) {
      print(0);
    } else {
      print(1);
    }
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_onCondition() async {
    await resolveTestCode('''
void f() {
  if (^1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_simpleConditions_block_block() async {
    await resolveTestCode('''
void f() {
  if^ (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_simpleConditions_block_single() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_simpleConditions_single_blockMulti() async {
    await resolveTestCode('''
void f() {
  if^ (1 == 1) {
    if (2 == 2) {
      print(1);
      print(2);
      print(3);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1 && 2 == 2) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  Future<void> test_simpleConditions_single_blockOne() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1)
    if (2 == 2) {
      print(0);
    }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_statementAfterInner() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    if (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_statementBeforeInner() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    print(1);
    if (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_targetNotIf() async {
    await resolveTestCode('''
void f() {
  pri^nt(0);
}
''');
    await assertNoAssist();
  }

  Future<void> test_targetWithElse() async {
    await resolveTestCode('''
void f() {
  if^ (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  } else {
    print(1);
  }
}
''');
    await assertNoAssist();
  }
}
