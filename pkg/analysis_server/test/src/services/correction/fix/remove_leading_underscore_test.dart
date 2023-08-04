// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLeadingUnderscoreBulkTest);
    defineReflectiveTests(RemoveLeadingUnderscoreForLibraryPrefixesTest);
    defineReflectiveTests(RemoveLeadingUnderscoreForLocalVariablesTest);
  });
}

@reflectiveTest
class RemoveLeadingUnderscoreBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.no_leading_underscores_for_local_identifiers;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  int _foo = 42;
  print(_foo);
  [0, 1, 2].forEach((_bar) {
    print(_bar);
  });
}
''');
    await assertHasFix('''
void f() {
  int foo = 42;
  print(foo);
  [0, 1, 2].forEach((bar) {
    print(bar);
  });
}
''');
  }
}

@reflectiveTest
class RemoveLeadingUnderscoreForLibraryPrefixesTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_LEADING_UNDERSCORE;

  @override
  String get lintCode => LintNames.no_leading_underscores_for_library_prefixes;

  Future<void> test_importPrefix() async {
    await resolveTestCode('''
import 'dart:core' as _core;
_core.int i = 1;
''');
    await assertHasFix('''
import 'dart:core' as core;
core.int i = 1;
''');
  }
}

@reflectiveTest
class RemoveLeadingUnderscoreForLocalVariablesTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_LEADING_UNDERSCORE;

  @override
  String get lintCode => LintNames.no_leading_underscores_for_local_identifiers;

  Future<void> test_listPatternAssignment() async {
    await resolveTestCode(r'''
f() {
  var [_a] = [1];
  print(_a);
}
''');
    await assertHasFix(r'''
f() {
  var [a] = [1];
  print(a);
}
''');
  }

  Future<void> test_localFunction() async {
    await resolveTestCode(r'''
void f() {
  int _foo() => 1;
  print(_foo());
}
''');
    await assertHasFix('''
void f() {
  int foo() => 1;
  print(foo());
}
''');
  }

  Future<void> test_localVariable() async {
    await resolveTestCode('''
void f() {
  var _foo = 1;
  print(_foo);
}
''');
    await assertHasFix('''
void f() {
  var foo = 1;
  print(foo);
}
''');
  }

  Future<void> test_localVariable_conflictWithParameter() async {
    await resolveTestCode('''
class A {
  void m({int? foo}) {
    var _foo = 1;
    print(foo);
    print(_foo);
  }
}
''');
    await assertHasFix('''
class A {
  void m({int? foo}) {
    var foo0 = 1;
    print(foo);
    print(foo0);
  }
}
''');
  }

  Future<void> test_localVariable_conflictWithVariable() async {
    await resolveTestCode('''
void f() {
  var _foo = 1;
  var foo = true;
  print(_foo);
  print(foo);
}
''');
    await assertHasFix('''
void f() {
  var foo0 = 1;
  var foo = true;
  print(foo0);
  print(foo);
}
''');
  }

  Future<void> test_localVariable_conflictWithVariable_existing() async {
    await resolveTestCode('''
void f() {
  var _foo = 1;
  var foo = true;
  var foo0 = true;
  print(_foo);
  print(foo);
  print(foo0);
}
''');
    await assertHasFix('''
void f() {
  var foo1 = 1;
  var foo = true;
  var foo0 = true;
  print(foo1);
  print(foo);
  print(foo0);
}
''');
  }

  Future<void> test_objectPatternAssignment() async {
    await resolveTestCode(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: int _b) = A(1);
  print(_b);
}
''');
    await assertHasFix(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: int b) = A(1);
  print(b);
}
''');
  }

  Future<void> test_parameter_closure() async {
    await resolveTestCode('''
void f() {
  [0, 1, 2].forEach((_foo) {
    print(_foo);
  });
}
''');
    await assertHasFix('''
void f() {
  [0, 1, 2].forEach((foo) {
    print(foo);
  });
}
''');
  }

  Future<void> test_parameter_constructor() async {
    await resolveTestCode('''
class A {
  A(int _foo) {
    print(_foo);
  }
}
''');
    await assertHasFix('''
class A {
  A(int foo) {
    print(foo);
  }
}
''');
  }

  Future<void> test_parameter_function() async {
    await resolveTestCode('''
void f(int _foo) {
  print(_foo);
}
''');
    await assertHasFix('''
void f(int foo) {
  print(foo);
}
''');
  }

  Future<void> test_parameter_method() async {
    await resolveTestCode('''
class A {
  void f(int _foo) {
    print(_foo);
  }
}
''');
    await assertHasFix('''
class A {
  void f(int foo) {
    print(foo);
  }
}
''');
  }

  Future<void> test_parameter_optionalNamed() async {
    await resolveTestCode('''
void f({int? _foo}) {
  print(_foo);
}
''');
    await assertNoFix();
  }

  Future<void> test_parameter_optionalPositional() async {
    await resolveTestCode('''
void f([int? _foo]) {
  print(_foo);
}
''');
    await assertHasFix('''
void f([int? foo]) {
  print(foo);
}
''');
  }

  Future<void> test_recordPatternAssignment() async {
    await resolveTestCode(r'''
f() {
  var (_a, b) = (1, 2);
  print('$_a$b');
}
''');
    await assertHasFix(r'''
f() {
  var (a, b) = (1, 2);
  print('$a$b');
}
''');
  }
}
