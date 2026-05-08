// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSecondaryConstructorClassTest);
    defineReflectiveTests(ConvertToSecondaryConstructorEnumTest);
    defineReflectiveTests(ConvertToSecondaryConstructorExtensionTypeTest);
  });
}

@reflectiveTest
class ConvertToSecondaryConstructorClassTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToSecondaryConstructor;

  Future<void> test_body() async {
    await resolveTestCode('''
class C^() {
  this {
    print('c');
  }
}
''');
    await assertHasAssist('''
class C {
  C() {
    print('c');
  }
}
''');
  }

  Future<void> test_bodyAndAnnotation() async {
    await resolveTestCode('''
class C^() {
  @a
  this {
    print('c');
  }
}

const a = 0;
''');
    await assertHasAssist('''
class C {
  @a
  C() {
    print('c');
  }
}

const a = 0;
''');
  }

  Future<void> test_bodyAndDocComment() async {
    await resolveTestCode('''
class C^() {
  /// c
  this {
    print('c');
  }
}
''');
    await assertHasAssist('''
class C {
  /// c
  C() {
    print('c');
  }
}
''');
  }

  Future<void> test_bodyAndInitializer() async {
    await resolveTestCode('''
class C^(int x) {
  int _x;

  this : _x = x {
    print('c');
  }
}
''');
    await assertHasAssist('''
class C {
  int _x;

  C(int x) : _x = x {
    print('c');
  }
}
''');
  }

  Future<void> test_emptyClassBody() async {
    await resolveTestCode('''
class C^();
''');
    await assertHasAssist('''
class C {
  C();
}
''');
  }

  Future<void> test_initializer() async {
    await resolveTestCode('''
class C^(int x) {
  int _x;

  this : _x = x;
}
''');
    await assertHasAssist('''
class C {
  int _x;

  C(int x) : _x = x;
}
''');
  }

  Future<void> test_keyword_const() async {
    await resolveTestCode('''
class const C^() {}
''');
    await assertHasAssist('''
class C {
  const C();
}
''');
  }

  Future<void> test_namedConstructor_withBody() async {
    await resolveTestCode('''
class C.n^amed() {
  this {
    print('c');
  }
}
''');
    await assertHasAssist('''
class C {
  C.named() {
    print('c');
  }
}
''');
  }

  Future<void> test_namedConstructor_withoutBody() async {
    await resolveTestCode('''
class C.n^amed(final int x) {}
''');
    await assertHasAssist('''
class C {
  final int x;

  C.named(this.x);
}
''');
  }

  Future<void> test_parameter_declaring_optionalNamed_private() async {
    await resolveTestCode('''
class C^({var int _x = 0}) {
  void m() {
    print(_x);
  }
}
''');
    await assertHasAssist('''
class C {
  int _x;

  C({this._x = 0});

  void m() {
    print(_x);
  }
}
''');
  }

  Future<void> test_parameter_declaring_optionalNamed_public() async {
    await resolveTestCode('''
class C^({var int x = 0}) {}
''');
    await assertHasAssist('''
class C {
  int x;

  C({this.x = 0});
}
''');
  }

  Future<void> test_parameter_declaring_optionalPositional_private() async {
    await resolveTestCode('''
class C^([var int _x = 0]) {
  void c() {
    print(_x);
  }
}
''');
    await assertHasAssist('''
class C {
  int _x;

  C([this._x = 0]);

  void c() {
    print(_x);
  }
}
''');
  }

  Future<void> test_parameter_declaring_optionalPositional_public() async {
    await resolveTestCode('''
class C^([var int x = 0]) {}
''');
    await assertHasAssist('''
class C {
  int x;

  C([this.x = 0]);
}
''');
  }

  Future<void> test_parameter_declaring_requiredNamed_private() async {
    await resolveTestCode('''
class C^({required var int _x}) {
  void m() {
    print(_x);
  }
}
''');
    await assertHasAssist('''
class C {
  int _x;

  C({required this._x});

  void m() {
    print(_x);
  }
}
''');
  }

  Future<void> test_parameter_declaring_requiredNamed_public() async {
    await resolveTestCode('''
class C^({required var int x}) {}
''');
    await assertHasAssist('''
class C {
  int x;

  C({required this.x});
}
''');
  }

  Future<void>
  test_parameter_declaring_requiredPositional_functionTyped_private() async {
    await resolveTestCode('''
class C^(var int _x(String)) {
  void c() {
    print(_x);
  }
}
''');
    await assertHasAssist('''
class C {
  int Function(String) _x;

  C(this._x);

  void c() {
    print(_x);
  }
}
''');
  }

  Future<void>
  test_parameter_declaring_requiredPositional_functionTyped_public() async {
    await resolveTestCode('''
class C^(var int x(String)) {}
''');
    await assertHasAssist('''
class C {
  int Function(String) x;

  C(this.x);
}
''');
  }

  Future<void>
  test_parameter_declaring_requiredPositional_simple_private() async {
    await resolveTestCode('''
class C^(var int _x) {
  void c() {
    print(_x);
  }
}
''');
    await assertHasAssist('''
class C {
  int _x;

  C(this._x);

  void c() {
    print(_x);
  }
}
''');
  }

  Future<void>
  test_parameter_declaring_requiredPositional_simple_public() async {
    await resolveTestCode('''
class C^(var int x) {}
''');
    await assertHasAssist('''
class C {
  int x;

  C(this.x);
}
''');
  }

  Future<void>
  test_parameter_declaring_requiredPositional_simple_public_final() async {
    await resolveTestCode('''
class C^(final int x) {}
''');
    await assertHasAssist('''
class C {
  final int x;

  C(this.x);
}
''');
  }

  Future<void> test_parameter_nonDeclaring_optionalNamed() async {
    await resolveTestCode('''
class C^({int x = 0}) {}
''');
    await assertHasAssist('''
class C {
  C({int x = 0});
}
''');
  }

  Future<void> test_parameter_nonDeclaring_optionalPositional() async {
    await resolveTestCode('''
class C^([int x = 0]) {}
''');
    await assertHasAssist('''
class C {
  C([int x = 0]);
}
''');
  }

  Future<void> test_parameter_nonDeclaring_requiredNamed() async {
    await resolveTestCode('''
class C^({required int x}) {}
''');
    await assertHasAssist('''
class C {
  C({required int x});
}
''');
  }

  Future<void>
  test_parameter_nonDeclaring_requiredPositional_fieldFormal() async {
    await resolveTestCode('''
class C^(this.x) {
  int x;
}
''');
    await assertHasAssist('''
class C {
  C(this.x);

  int x;
}
''');
  }

  Future<void>
  test_parameter_nonDeclaring_requiredPositional_functionTyped() async {
    await resolveTestCode('''
class C^(int x(String)) {}
''');
    await assertHasAssist('''
class C {
  C(int x(String));
}
''');
  }

  Future<void>
  test_parameter_nonDeclaring_requiredPositional_simple_private() async {
    await resolveTestCode('''
class C^(int _x) {}
''');
    await assertHasAssist('''
class C {
  C(int _x);
}
''');
  }

  Future<void>
  test_parameter_nonDeclaring_requiredPositional_simple_public() async {
    await resolveTestCode('''
class C^(int x) {}
''');
    await assertHasAssist('''
class C {
  C(int x);
}
''');
  }

  Future<void> test_parameter_nonDeclaring_requiredPositional_super() async {
    await resolveTestCode('''
class C^(super.x) extends B {}

class B {
  B(int x);
}
''');
    await assertHasAssist('''
class C extends B {
  C(super.x);
}

class B {
  B(int x);
}
''');
  }

  Future<void> test_withExistingConstructor() async {
    await resolveTestCode('''
class C^({required var int x, required var int y}) {
  int get sum => x + y;

  C.o() : this(x: 0, y: 0);
}
''');
    await assertHasAssist('''
class C {
  int x;

  int y;

  int get sum => x + y;

  C({required this.x, required this.y});

  C.o() : this(x: 0, y: 0);
}
''');
  }
}

@reflectiveTest
class ConvertToSecondaryConstructorEnumTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToSecondaryConstructor;

  Future<void> test_initializer() async {
    await resolveTestCode('''
enum E^() {
  e;

  this : assert(true, '');
}
''');
    await assertHasAssist('''
enum E {
  e;

  const E() : assert(true, '');
}
''');
  }

  Future<void>
  test_parameter_declaring_requiredPositional_simple_public() async {
    await resolveTestCode('''
enum E^(final int x) {
  e(0);
}
''');
    await assertHasAssist('''
enum E {
  e(0);

  final int x;

  const E(this.x);
}
''');
  }

  Future<void>
  test_parameter_nonDeclaring_requiredPositional_noSemicolon() async {
    await resolveTestCode('''
enum E^(int x) {
  e(0)
}
''');
    await assertHasAssist('''
enum E {
  e(0);

  const E(int x);
}
''');
  }
}

@reflectiveTest
class ConvertToSecondaryConstructorExtensionTypeTest
    extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToSecondaryConstructor;

  Future<void> test_simple() async {
    await resolveTestCode('''
extension type C^(String s) {
}
''');
    await assertNoAssist();
  }
}
