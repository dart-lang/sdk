// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveEmptyConstructorBodyBulkTest);
    defineReflectiveTests(RemoveEmptyConstructorBodyTest);
  });
}

@reflectiveTest
class RemoveEmptyConstructorBodyBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.empty_constructor_bodies;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  C() {}
}

class D {
  D() {}
}
''');
    await assertHasFix('''
class C {
  C();
}

class D {
  D();
}
''');
  }
}

@reflectiveTest
class RemoveEmptyConstructorBodyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeEmptyConstructorBody;

  @override
  String get lintCode => LintNames.empty_constructor_bodies;

  Future<void> test_empty() async {
    await resolveTestCode('''
class C {
  C() {}
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_incompleteComment() async {
    await resolveTestCode(r'''
class A {
  A() {/*
''');
    await assertNoFix(filter: _isInterestingError);
  }

  Future<void> test_noPrimaryConstructor() async {
    await resolveTestCode('''
class C {
  this {}
}
''');
    await assertHasFix('''
class C {
  this;
}
''', filter: _isInterestingError);
  }

  Future<void> test_primaryConstructor_class() async {
    await resolveTestCode('''
class C(int x) {
  this {}
}
''');
    await assertHasFix('''
class C(int x) {
  this;
}
''');
  }

  Future<void> test_primaryConstructor_enum() async {
    await resolveTestCode('''
enum E(int x) {
  c(1);

  this {}
}
''');
    await assertHasFix('''
enum E(int x) {
  c(1);

  this;
}
''', filter: _isInterestingError);
  }

  Future<void> test_primaryConstructor_enum_withInitializer() async {
    await resolveTestCode('''
enum E(int x) {
  c(1);

  this : assert(x > 0) {}
}
''');
    await assertHasFix('''
enum E(int x) {
  c(1);

  this : assert(x > 0);
}
''', filter: _isInterestingError);
  }

  Future<void> test_primaryConstructor_extensionType() async {
    await resolveTestCode('''
extension type E(int x) {
  this {}
}
''');
    await assertHasFix('''
extension type E(int x) {
  this;
}
''');
  }

  Future<void> test_primaryConstructor_extensionType_withInitializer() async {
    await resolveTestCode('''
extension type E(int x) {
  this : assert(x > 0) {}
}
''');
    await assertHasFix('''
extension type E(int x) {
  this : assert(x > 0);
}
''');
  }

  Future<void> test_primaryConstructor_mixinClass() async {
    await resolveTestCode('''
mixin class M(int x) {
  this {}
}
''');
    await assertHasFix('''
mixin class M(int x) {
  this;
}
''', filter: _isInterestingError);
  }

  Future<void> test_primaryConstructor_mixinClass_withInitializer() async {
    await resolveTestCode('''
mixin class M(int x) {
  this : assert(x > 0) {}
}
''');
    await assertHasFix('''
mixin class M(int x) {
  this : assert(x > 0);
}
''', filter: _isInterestingError);
  }

  static bool _isInterestingError(Diagnostic e) {
    return e.diagnosticCode.lowerCaseName == LintNames.empty_constructor_bodies;
  }
}
