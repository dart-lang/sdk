// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveInitializerBulkTest);
    defineReflectiveTests(RemoveInitializerTest);
    defineReflectiveTests(RemoveDeadWildcardInitializerTest);
  });
}

@reflectiveTest
class RemoveDeadWildcardInitializerTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeInitializer;

  Future<void> test_deadLateWildcardVariableInitializer() async {
    await resolveTestCode('''
f() {
  late var _ = 0;
}
''');
    await assertHasFix('''
f() {
  late var _;
}
''');
  }
}

@reflectiveTest
class RemoveInitializerBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_init_to_null;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class T {
  int? x = null;
}

class T2 {
  int? x = null;
}
''');
    await assertHasFix('''
class T {
  int? x;
}

class T2 {
  int? x;
}
''');
  }
}

@reflectiveTest
class RemoveInitializerTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeInitializer;

  @override
  String get lintCode => LintNames.avoid_init_to_null;

  Future<void> test_abstract_field_constructor_initializer() async {
    await resolveTestCode('''
abstract class A {
  abstract int x;
  A() : x = 0;
}
''');
    await assertHasFix('''
abstract class A {
  abstract int x;
  A();
}
''');
  }

  Future<void> test_abstract_field_constructor_initializer_first() async {
    await resolveTestCode('''
abstract class A {
  abstract int x;
  int y;
  A() : x = 0, y = 1;
}
''');
    await assertHasFix('''
abstract class A {
  abstract int x;
  int y;
  A() : y = 1;
}
''');
  }

  Future<void> test_abstract_field_constructor_initializer_last() async {
    await resolveTestCode('''
abstract class A {
  int y;
  abstract int x;
  A() : y = 0, x = 1;
}
''');
    await assertHasFix('''
abstract class A {
  int y;
  abstract int x;
  A() : y = 0;
}
''');
  }

  Future<void> test_abstract_field_initializer() async {
    await resolveTestCode('''
abstract class A {
  abstract int x = 0;
}
''');
    await assertHasFix('''
abstract class A {
  abstract int x;
}
''');
  }

  Future<void> test_field() async {
    await resolveTestCode('''
class Test {
  int? x = null;
}
''');
    await assertHasFix('''
class Test {
  int? x;
}
''');
  }

  Future<void> test_field_late() async {
    await resolveTestCode('''
class Test {
  /// field example
  late int? x = null;
}
''');
    await assertHasFix('''
class Test {
  /// field example
  int? x;
}
''');
  }

  Future<void> test_forLoop() async {
    await resolveTestCode('''
void f() {
  for (var i = null; i != null; i++) {
  }
}
''');
    await assertHasFix('''
void f() {
  for (var i; i != null; i++) {
  }
}
''');
  }

  Future<void> test_listOfVariableDeclarations() async {
    await resolveTestCode('''
String? a = 'a', b = null, c = 'c';
''');
    await assertHasFix('''
String? a = 'a', b, c = 'c';
''');
  }

  Future<void> test_parameter_optionalNamed() async {
    await resolveTestCode('''
void f({String? s = null}) {}
''');
    await assertHasFix('''
void f({String? s}) {}
''');
  }

  Future<void> test_parameter_optionalPositional() async {
    await resolveTestCode('''
void f([String? s = null]) {}
''');
    await assertHasFix('''
void f([String? s]) {}
''');
  }

  Future<void> test_parameter_super() async {
    await resolveTestCode('''
class C {
  C({String? s});
}
class D extends C {
  D({super.s = null});
}
''');
    await assertHasFix('''
class C {
  C({String? s});
}
class D extends C {
  D({super.s});
}
''');
  }

  Future<void> test_topLevel() async {
    await resolveTestCode('''
var x = null;
''');
    await assertHasFix('''
var x;
''');
  }
}
