// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceEmptyMapPatternWithAnyTest);
    defineReflectiveTests(ReplaceEmptyMapPatternWithEmptyTest);
  });
}

@reflectiveTest
class ReplaceEmptyMapPatternWithAnyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MATCH_ANY_MAP;

  Future<void> test_ifCase_withoutTypeArgs() async {
    await resolveTestCode('''
void f(Object x) {
  if (x case {}) {
    return;
  }
}
''');
    await assertHasFix('''
void f(Object x) {
  if (x case Map()) {
    return;
  }
}
''');
  }

  Future<void> test_ifCase_withTypeArgs() async {
    await resolveTestCode('''
void f(Object x) {
  if (x case <int, int>{}) {
    return;
  }
}
''');
    await assertHasFix('''
void f(Object x) {
  if (x case Map<int, int>()) {
    return;
  }
}
''');
  }

  Future<void> test_switchStatement() async {
    await resolveTestCode('''
void f(Object x) {
  switch (x) {
    case {}: return;
  }
}
''');
    await assertHasFix('''
void f(Object x) {
  switch (x) {
    case Map(): return;
  }
}
''');
  }
}

@reflectiveTest
class ReplaceEmptyMapPatternWithEmptyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MATCH_EMPTY_MAP;

  Future<void> test_ifCase() async {
    await resolveTestCode('''
void f(Object x) {
  if (x case {}) {
    return;
  }
}
''');
    await assertHasFix('''
void f(Object x) {
  if (x case Map(isEmpty: true)) {
    return;
  }
}
''');
  }

  Future<void> test_switchStatement_withoutTypeArgs() async {
    await resolveTestCode('''
void f(Object x) {
  switch (x) {
    case {}: return;
  }
}
''');
    await assertHasFix('''
void f(Object x) {
  switch (x) {
    case Map(isEmpty: true): return;
  }
}
''');
  }

  Future<void> test_switchStatement_withTypeArgs() async {
    await resolveTestCode('''
void f(Object x) {
  switch (x) {
    case <int, int>{}: return;
  }
}
''');
    await assertHasFix('''
void f(Object x) {
  switch (x) {
    case Map<int, int>(isEmpty: true): return;
  }
}
''');
  }
}
