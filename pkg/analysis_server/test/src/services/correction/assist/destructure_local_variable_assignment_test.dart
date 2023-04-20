// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DestructureLocalVariableAssignmentObjectTest);
    defineReflectiveTests(DestructureLocalVariableAssignmentRecordTest);
  });
}

@reflectiveTest
class DestructureLocalVariableAssignmentObjectTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.DESTRUCTURE_LOCAL_VARIABLE_ASSIGNMENT;

  Future<void> test_object() async {
    await resolveTestCode('''
class A { }

A f() => A();

m() {
  var obj = f();
}
''');
    await assertHasAssistAt('obj', r'''
class A { }

A f() => A();

m() {
  var A() = f();
}
''');
  }

  Future<void> test_object_propertyAssigned_noAssist() async {
    await resolveTestCode('''
class A { 
  set a(int a) {}
}

A f() => A();

m() {
  var obj = f();
  obj.a = 1;
}
''');
    await assertNoAssistAt('obj');
  }

  Future<void> test_object_propertyPostIncremented_noAssist() async {
    await resolveTestCode('''
class A { 
  int a = 1;
}

A f() => A();

m() {
  var obj = f();
  obj.a++;
}
''');
    await assertNoAssistAt('obj');
  }

  Future<void> test_object_propertyPreIncremented_noAssist() async {
    await resolveTestCode('''
class A { 
  int a = 1;
}

A f() => A();

m() {
  var obj = f();
  ++obj.a;
}
''');
    await assertNoAssistAt('obj');
  }

  Future<void> test_object_reassigned_noAssist() async {
    await resolveTestCode('''
class A { }

A f() => A();

m() {
  var obj = f();
  obj = A();
}
''');
    await assertNoAssistAt('obj');
  }

  Future<void> test_object_referenced() async {
    await resolveTestCode('''
class A { 
  String get a => '';
  String get b => '';
  String get c => '';
}

A f() => A();

m(var c) {
  var obj = f();
  var b = 0;
  print(obj.a);
  print(obj.b);
  print(obj.c);
  print(obj.c);
}
''');
    await assertHasAssistAt('obj', r'''
class A { 
  String get a => '';
  String get b => '';
  String get c => '';
}

A f() => A();

m(var c) {
  var A(:a, b: b2, c: c2) = f();
  var b = 0;
  print(a);
  print(b2);
  print(c2);
  print(c2);
}
''');
  }

  Future<void> test_object_referenced_noAssist() async {
    await resolveTestCode('''
class A { }

A f() => A();

m() {
  var obj = f();
  print(obj);
}
''');
    await assertNoAssistAt('obj');
  }
}

@reflectiveTest
class DestructureLocalVariableAssignmentRecordTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.DESTRUCTURE_LOCAL_VARIABLE_ASSIGNMENT;

  Future<void> test_namedFields() async {
    await resolveTestCode('''
({int n, String s}) f() => (n: 1, s: '');

m() {
  var rec = f();
}
''');
    await assertHasAssistAt('rec', r'''
({int n, String s}) f() => (n: 1, s: '');

m() {
  var (:n, :s) = f();
}
''');
  }

  Future<void> test_namedFields_nameConflict() async {
    await resolveTestCode('''
({int n, String s}) f() => (n: 1, s: '');

m(int n) {
  var rec = f();
}
''');
    await assertHasAssistAt('rec', r'''
({int n, String s}) f() => (n: 1, s: '');

m(int n) {
  var (n: n2, :s) = f();
}
''');

    assertLinkedGroup(
        0,
        ['n2'],
        expectedSuggestions(
          LinkedEditSuggestionKind.VARIABLE,
          ['n2', '_'],
        ));
  }

  Future<void> test_positionalAndNamedFields() async {
    await resolveTestCode('''
(bool, {int n, String s}) f() => (false, n: 1, s: '');

m() {
  var rec = f();
}
''');
    await assertHasAssistAt('rec', r'''
(bool, {int n, String s}) f() => (false, n: 1, s: '');

m() {
  var ($1, :n, :s) = f();
}
''');

    assertLinkedGroup(
        1,
        [':n'],
        expectedSuggestions(
          LinkedEditSuggestionKind.VARIABLE,
          [':n', 'n: _'],
        ));
  }

  Future<void> test_positionalFields() async {
    await resolveTestCode('''
(int, String name) f() => (1, '');

m() {
  var rec = f();
}
''');
    await assertHasAssistAt('rec', r'''
(int, String name) f() => (1, '');

m() {
  var ($1, $2) = f();
}
''');
    assertLinkedGroup(
        0,
        [r'$1'],
        expectedSuggestions(
          LinkedEditSuggestionKind.VARIABLE,
          [r'$1', '_'],
        ));
  }

  Future<void> test_positionalFields_nameConflict() async {
    await resolveTestCode(r'''
(int, String) f() => (1, '');

m(var $1) {
  var rec = f();
}
''');
    await assertHasAssistAt('rec', r'''
(int, String) f() => (1, '');

m(var $1) {
  var ($1a, $2) = f();
}
''');
  }
}
