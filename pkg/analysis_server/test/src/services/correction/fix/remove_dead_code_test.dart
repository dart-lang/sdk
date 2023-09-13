// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDeadCodeTest);
  });
}

@reflectiveTest
class RemoveDeadCodeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_DEAD_CODE;

  Future<void> test_catch_afterCatchAll_catch() async {
    await resolveTestCode('''
void f() {
  try {
  } catch (e) {
    print('a');
  } catch (e) {
    print('b');
  }
}
''');
    await assertHasFix('''
void f() {
  try {
  } catch (e) {
    print('a');
  }
}
''');
  }

  Future<void> test_catch_afterCatchAll_on() async {
    await resolveTestCode('''
void f() {
  try {
  } on Object {
    print('a');
  } catch (e) {
    print('b');
  }
}
''');
    await assertHasFix('''
void f() {
  try {
  } on Object {
    print('a');
  }
}
''');
  }

  Future<void> test_catch_subtype() async {
    await resolveTestCode('''
class A {}
class B extends A {}
void f() {
  try {
  } on A {
    print('a');
  } on B {
    print('b');
  }
}
''');
    await assertHasFix('''
class A {}
class B extends A {}
void f() {
  try {
  } on A {
    print('a');
  }
}
''');
  }

  Future<void> test_condition() async {
    await resolveTestCode('''
void f(int p) {
  if (true || p > 5) {
    print(1);
  }
}
''');
    await assertHasFix('''
void f(int p) {
  if (true) {
    print(1);
  }
}
''');
  }

  Future<void> test_do_returnInBody() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
    print(c);
    return;
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_doWhile_atDo() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
    print(c);
    return;
}
''', errorFilter: (err) => err.problemMessage.length == 4);
  }

  Future<void> test_doWhile_atDo_followed() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
  print('');
}
''');
    await assertHasFix('''
void f(bool c) {
    print(c);
    return;
  print('');
}
''', errorFilter: (err) => err.problemMessage.length == 4);
  }

  Future<void> test_doWhile_atDo_noBrackets() async {
    await resolveTestCode('''
void f(bool c) {
  do
    return;
  while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
  return;
}
''', errorFilter: (err) => err.problemMessage.length == 2);
  }

  Future<void> test_doWhile_atDo_noBrackets_followed() async {
    await resolveTestCode('''
void f(bool c) {
  do
    return;
  while (c);
  print('');
}
''');
    await assertHasFix('''
void f(bool c) {
  return;
  print('');
}
''', errorFilter: (err) => err.problemMessage.length == 2);
  }

  Future<void> test_doWhile_atWhile() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
    print(c);
    return;
}
''', errorFilter: (err) => err.problemMessage.length == 12);
  }

  Future<void> test_doWhile_atWhile_noBrackets() async {
    await resolveTestCode('''
void f(bool c) {
  do
    return;
  while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
  return;
}
''', errorFilter: (err) => err.problemMessage.length == 10);
  }

  Future<void> test_doWhile_break() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    if (c) {
     break;
    }
    return;
  } while (c);
  print('');
}
''');
    await assertNoFix(errorFilter: (error) => error.length == 4);
  }

  Future<void> test_doWhile_break_doLabel() async {
    await resolveTestCode('''
void f(bool c) {
  label:
  do {
    if (c) {
      break label;
    }
    return;
  } while (c);
  print('');
}
''');
    await assertNoFix(errorFilter: (error) => error.length == 4);
  }

  Future<void> test_doWhile_break_inner() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    while (c) {
      break;
    }
    return;
  } while (c);
  print('');
}
''');
    await assertHasFix('''
void f(bool c) {
    while (c) {
      break;
    }
    return;
  print('');
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_doWhile_break_outerDoLabel() async {
    await resolveTestCode('''
void f(bool c) {
  label:
  do {
    do {
      if (c) {
        break label;
      }
      return;
    } while (c);
    print('');
  } while (c);
  print('');
}
''');
    await assertHasFix('''
void f(bool c) {
  label:
  do {
      if (c) {
        break label;
      }
      return;
    print('');
  } while (c);
  print('');
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_doWhile_break_outerLabel() async {
    await resolveTestCode('''
void f(bool c) {
  label: {
    do {
      if (c) {
       break label;
      }
      return;
    } while (c);
    print('');
  }
}
''');
    await assertHasFix('''
void f(bool c) {
  label: {
      if (c) {
       break label;
      }
      return;
    print('');
  }
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_emptyStatement() async {
    await resolveTestCode('''
void f() {
  for (; false;);
}
''');
    await assertNoFix();
  }

  Future<void> test_for_returnInBody() async {
    await resolveTestCode('''
void f() {
  for (var i = 0; i < 2; i++) {
    print(i);
    return;
  }
}
''');
    await assertHasFix('''
void f() {
  for (var i = 0; i < 2; ) {
    print(i);
    return;
  }
}
''');
  }

  Future<void> test_forParts_updaters_multiple() async {
    await resolveTestCode('''
void f() {
  for (; false; 1, 2) {}
}
''');
    await assertHasFix('''
void f() {
  for (; false; ) {}
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_forParts_updaters_multiple_comma() async {
    await resolveTestCode('''
void f() {
  for (; false; 1, 2,) {}
}
''');
    await assertHasFix('''
void f() {
  for (; false; ) {}
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_forParts_updaters_throw() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1) {}
}
''');
  }

  Future<void> test_forParts_updaters_throw_comma() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2,) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1,) {}
}
''');
  }

  Future<void> test_forParts_updaters_throw_multiple() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2, 3) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1) {}
}
''');
  }

  Future<void> test_forParts_updaters_throw_multiple_comma() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2, 3,) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1,) {}
}
''');
  }

  Future<void> test_statements_one() async {
    await resolveTestCode('''
int f() {
  print(0);
  return 42;
  print(1);
}
''');
    await assertHasFix('''
int f() {
  print(0);
  return 42;
}
''');
  }

  Future<void> test_statements_two() async {
    await resolveTestCode('''
int f() {
  print(0);
  return 42;
  print(1);
  print(2);
}
''');
    await assertHasFix('''
int f() {
  print(0);
  return 42;
}
''');
  }

  Future<void> test_switchCase_sharedStatements() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    case 5:
    case 5:
    case 3: break;
  }
}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    case 5:
    case 3: break;
  }
}
''');
  }

  Future<void> test_switchCase_uniqueStatements() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    case 5: print('');
    case 5: print('a');
    case 3: break;
  }
}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    case 5: print('');
    case 3: break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50950')
  Future<void> test_switchExpression() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    5 => '',
    5 => 'a',
    3 => 'b'
}

}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    5 => '',
    3 => 'b'
}

  }
}
''');
  }
}
