// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToPrimaryConstructorClassTest);
    defineReflectiveTests(ConvertToPrimaryConstructorEnumTest);
  });
}

@reflectiveTest
class ConvertToPrimaryConstructorClassTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToPrimaryConstructor;

  @override
  String get lintCode => LintNames.use_primary_constructors;

  Future<void> test_noParameters_noBody_named() async {
    await resolveTestCode('''
class C {
  C.n();
}
''');
    await assertHasFix('''
class C.n();
''');
  }

  Future<void> test_noParameters_noBody_unnamed() async {
    await resolveTestCode('''
class C {
  C();
}
''');
    await assertHasFix('''
class C();
''');
  }

  Future<void> test_noParameters_withBody() async {
    await resolveTestCode('''
class C {
  C() {
    print('c');
  }
}
''');
    await assertHasFix('''
class C() {
  this {
    print('c');
  }
}
''');
  }

  Future<void> test_noParameters_withBodyAndInitializer() async {
    await resolveTestCode('''
class C {
  int _x; // ignore: unused_field

  C() : _x = 0 {
    print('c');
  }
}
''');
    await assertHasFix('''
class C() {
  int _x; // ignore: unused_field

  this : _x = 0 {
    print('c');
  }
}
''');
  }

  Future<void> test_noParameters_withInitializer() async {
    await resolveTestCode('''
class C {
  int _x; // ignore: unused_field

  C() : _x = 0;
}
''');
    await assertHasFix('''
class C() {
  int _x; // ignore: unused_field

  this : _x = 0;
}
''');
  }

  Future<void> test_noParameters_withKeyword_const() async {
    await resolveTestCode('''
class C {
  const C();
}
''');
    await assertHasFix('''
class const C();
''');
  }

  Future<void> test_withAnnotation() async {
    await resolveTestCode('''
class C {
  @a
  C();
}

const a = 0;
''');
    await assertHasFix('''
class C() {
  @a
  this;
}

const a = 0;
''');
  }

  Future<void> test_withConstructor_factory() async {
    await resolveTestCode('''
class C {
  C();

  factory C.c() => C();
}
''');
    await assertHasFix('''
class C() {
  factory C.c() => C();
}
''');
  }

  Future<void> test_withConstructor_redirectingGenerative() async {
    await resolveTestCode('''
class C {
  C();

  C.c() : this();
}
''');
    await assertHasFix('''
class C() {
  C.c() : this();
}
''');
  }

  Future<void> test_withDocComment() async {
    await resolveTestCode('''
class C {
  /// C
  C();
}

const a = 0;
''');
    await assertHasFix('''
class C() {
  /// C
  this;
}

const a = 0;
''');
  }

  Future<void> test_withParameters_optionalNamed_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C({this.x = 0});
}
''');
    await assertHasFix('''
class C({this.x = 0}) {
  int x;
}
''');
  }

  Future<void> test_withParameters_optionalNamed_simple() async {
    await resolveTestCode('''
class C {
  int _x; // ignore: unused_field

  C({int x = 0}) : _x = x;
}
''');
    await assertHasFix('''
class C({int x = 0}) {
  int _x; // ignore: unused_field

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_optionalNamed_super() async {
    await resolveTestCode('''
class C extends B {
  C({super.x = 0});
}

class B({required this.x}) {
  int x;
}
''');
    await assertHasFix('''
class C({super.x = 0}) extends B;

class B({required this.x}) {
  int x;
}
''');
  }

  Future<void> test_withParameters_optionalPositional_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C([this.x = 0]);
}
''');
    await assertHasFix('''
class C([this.x = 0]) {
  int x;
}
''');
  }

  Future<void> test_withParameters_optionalPositional_simple() async {
    await resolveTestCode('''
class C {
  int _x; // ignore: unused_field

  C([int x = 0]) : _x = x;
}
''');
    await assertHasFix('''
class C([int x = 0]) {
  int _x; // ignore: unused_field

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_optionalPositional_super() async {
    await resolveTestCode('''
class C extends B {
  C([super.x = 0]);
}

class B(this.x) {
  int x;
}
''');
    await assertHasFix('''
class C([super.x = 0]) extends B;

class B(this.x) {
  int x;
}
''');
  }

  Future<void> test_withParameters_requiredNamed_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C({required this.x});
}
''');
    await assertHasFix('''
class C({required this.x}) {
  int x;
}
''');
  }

  Future<void> test_withParameters_requiredNamed_simple() async {
    await resolveTestCode('''
class C {
  int _x; // ignore: unused_field

  C({required int x}) : _x = x;
}
''');
    await assertHasFix('''
class C({required int x}) {
  int _x; // ignore: unused_field

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_requiredNamed_super() async {
    await resolveTestCode('''
class C extends B {
  C({required super.x});
}

class B({required this.x}) {
  int x;
}
''');
    await assertHasFix('''
class C({required super.x}) extends B;

class B({required this.x}) {
  int x;
}
''');
  }

  Future<void> test_withParameters_requiredPositional_fieldFormal() async {
    await resolveTestCode('''
class C {
  int x;

  C(this.x);
}
''');
    await assertHasFix('''
class C(this.x) {
  int x;
}
''');
  }

  Future<void> test_withParameters_requiredPositional_simple() async {
    await resolveTestCode('''
class C {
  int _x; // ignore: unused_field

  C(int x) : _x = x;
}
''');
    await assertHasFix('''
class C(int x) {
  int _x; // ignore: unused_field

  this : _x = x;
}
''');
  }

  Future<void> test_withParameters_requiredPositional_super() async {
    await resolveTestCode('''
class C extends B {
  C(super.x);
}

class B(this.x) {
  int x;
}
''');
    await assertHasFix('''
class C(super.x) extends B;

class B(this.x) {
  int x;
}
''');
  }
}

@reflectiveTest
class ConvertToPrimaryConstructorEnumTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToPrimaryConstructor;

  @override
  String get lintCode => LintNames.use_primary_constructors;

  Future<void> test_noParameters_noBody() async {
    await resolveTestCode('''
enum E {
  a, b;

  const E();
}
''');
    await assertHasFix('''
enum E() {
  a, b
}
''');
  }

  Future<void> test_noParameters_withInitializer() async {
    await resolveTestCode('''
enum E {
  a(1), b(2);

  final int x;

  const E(this.x) : assert(x > 0);
}
''');
    await assertHasFix('''
enum E(this.x) {
  a(1), b(2);

  final int x;

  this : assert(x > 0);
}
''');
  }

  Future<void> test_withParameters_requiredPositional_simple() async {
    await resolveTestCode('''
enum E {
  a(1), b(2);

  final int _x; // ignore: unused_field

  const E(int x) : _x = x;
}
''');
    await assertHasFix('''
enum E(int x) {
  a(1), b(2);

  final int _x; // ignore: unused_field

  this : _x = x;
}
''');
  }
}
