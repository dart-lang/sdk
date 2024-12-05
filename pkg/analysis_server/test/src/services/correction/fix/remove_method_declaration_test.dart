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
    defineReflectiveTests(RemoveMethodDeclarationBulkTest);
    defineReflectiveTests(RemoveMethodDeclarationTest);
    defineReflectiveTests(UnnecessaryOverridesTest);
  });
}

@reflectiveTest
class RemoveMethodDeclarationBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_overrides;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  int foo;
  int bar() => 0;
}

class B extends A {
  @override
  int get foo => super.foo;
  @override
  int bar() => super.bar();
}
''');
    await assertHasFix('''
class A {
  int foo;
  int bar() => 0;
}

class B extends A {
}
''');
  }
}

@reflectiveTest
class RemoveMethodDeclarationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_METHOD_DECLARATION;

  Future<void> test_extensionDeclaresMemberOfObject() async {
    await resolveTestCode('''
extension E on String {
  bool operator==(Object _) => false;
}
''');
    await assertHasFix('''
extension E on String {
}
''');
  }

  Future<void> test_extensionTypeDeclaresMemberOfObject() async {
    await resolveTestCode('''
extension type E(int i) {
  int get hashCode => 0;
}
''');
    await assertHasFix('''
extension type E(int i) {
}
''');
  }
}

@reflectiveTest
class UnnecessaryOverridesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_METHOD_DECLARATION;

  @override
  String get lintCode => LintNames.unnecessary_overrides;

  Future<void> test_getter() async {
    await resolveTestCode('''
class A {
  int foo = 0;
}

class B extends A {
  @override
  int get foo => super.foo;
}
''');
    await assertHasFix('''
class A {
  int foo = 0;
}

class B extends A {
}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}

class B extends A {
  @override
  int foo() => super.foo();
}
''');
    await assertHasFix('''
class A {
  int foo() => 0;
}

class B extends A {
}
''');
  }

  Future<void> test_method_generic() async {
    await resolveTestCode('''
class A<T> {
  T foo() {
    throw 42;
  }
}

class B extends A<int> {
  @override
  int foo() => super.foo();
}
''');
    await assertHasFix('''
class A<T> {
  T foo() {
    throw 42;
  }
}

class B extends A<int> {
}
''');
  }

  Future<void> test_method_toString() async {
    await resolveTestCode('''
class A {
  @override
  String toString() => super.toString();
}
''');
    await assertHasFix('''
class A {
}
''');
  }

  @failingTest
  Future<void> test_setter() async {
    // The lint doesn't catch unnecessary setters.
    await resolveTestCode('''
class A {
  int foo;
}

class B extends A {
  @override
  set foo(int value) {
    super.foo = value;
  }
}
''');
    await assertHasFix('''
class A {
  int foo;
}

class B extends A {
}
''');
  }
}
