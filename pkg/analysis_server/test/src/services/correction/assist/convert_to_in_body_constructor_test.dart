// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToInBodyConstructorClassTest);
    defineReflectiveTests(ConvertToInBodyConstructorEnumTest);
    defineReflectiveTests(ConvertToInBodyConstructorExtensionTypeTest);
  });
}

@reflectiveTest
class ConvertToInBodyConstructorClassTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInBodyConstructor;

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
  new() {
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
  new() {
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
  new() {
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

  new(int x) : _x = x {
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
  new();
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

  new(int x) : _x = x;
}
''');
  }

  Future<void> test_keyword_const() async {
    await resolveTestCode('''
class const C^() {}
''');
    await assertHasAssist('''
class C {
  const new();
}
''');
  }

  Future<void> test_lint_noLint_defaultBehavior() async {
    await resolveTestCode('''
class C^(int x) {
  new named() : this(0);
}
''');
    await assertHasAssist('''
class C {
  new(int x);

  new named() : this(0);
}
''');
  }

  Future<void> test_lint_sortConstructorsFirst_unnamedPrimary() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);
    await resolveTestCode('''
class C^(int x) {
  new named() : this(0);
}
''');
    await assertHasAssist('''
class C {
  new named() : this(0);

  new(int x);
}
''');
  }

  Future<void>
  test_lint_sortConstructorsFirst_unnamedPrimary_noConflict() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);
    await resolveTestCode('''
class C^(var int x) {
  void m() {}
}
''');
    await assertHasAssist('''
class C {
  new(this.x);
  int x;


  void m() {}
}
''');
  }

  Future<void> test_lint_sortUnnamedConstructorsFirst_namedPrimary() async {
    createAnalysisOptionsFile(
      lints: [LintNames.sort_unnamed_constructors_first],
    );
    await resolveTestCode('''
class C.n^amed(int x) {
  new() : this.named(0);
}
''');
    await assertHasAssist('''
class C {
  new() : this.named(0);

  new named(int x);
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
  new named() {
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

  new named(this.x);
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

  new({this._x = 0});

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

  new({this.x = 0});
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

  new([this._x = 0]);

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

  new([this.x = 0]);
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

  new({required this._x});

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

  new({required this.x});
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

  new(this._x);

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

  new(this.x);
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

  new(this._x);

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

  new(this.x);
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

  new(this.x);
}
''');
  }

  Future<void> test_parameter_nonDeclaring_optionalNamed() async {
    await resolveTestCode('''
class C^({int x = 0}) {}
''');
    await assertHasAssist('''
class C {
  new({int x = 0});
}
''');
  }

  Future<void> test_parameter_nonDeclaring_optionalPositional() async {
    await resolveTestCode('''
class C^([int x = 0]) {}
''');
    await assertHasAssist('''
class C {
  new([int x = 0]);
}
''');
  }

  Future<void> test_parameter_nonDeclaring_referencedInInitializer() async {
    await resolveTestCode('''
class C^(int x) {
  final int y = x;
}
''');
    await assertHasAssist('''
class C {
  new(int x) : y = x;

  final int y;
}
''');
  }

  Future<void> test_parameter_nonDeclaring_requiredNamed() async {
    await resolveTestCode('''
class C^({required int x}) {}
''');
    await assertHasAssist('''
class C {
  new({required int x});
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
  new(this.x);

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
  new(int x(String));
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
  new(int _x);
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
  new(int x);
}
''');
  }

  Future<void> test_parameter_nonDeclaring_requiredPositional_super() async {
    await resolveTestCode('''
class C^(super.x) extends B {}

class B {
  new(int x);
}
''');
    await assertHasAssist('''
class C extends B {
  new(super.x);
}

class B {
  new(int x);
}
''');
  }

  Future<void> test_withExistingConstructor() async {
    await resolveTestCode('''
class C^({required var int x, required var int y}) {
  int get sum => x + y;

  new o() : this(x: 0, y: 0);
}
''');
    await assertHasAssist('''
class C {
  int x;

  int y;

  int get sum => x + y;

  new({required this.x, required this.y});

  new o() : this(x: 0, y: 0);
}
''');
  }
}

@reflectiveTest
class ConvertToInBodyConstructorEnumTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInBodyConstructor;

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

  new() : assert(true, '');
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

  new(this.x);
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

  new(int x);
}
''');
  }
}

@reflectiveTest
class ConvertToInBodyConstructorExtensionTypeTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInBodyConstructor;

  Future<void> test_simple() async {
    await resolveTestCode('''
extension type C^(String s) {
}
''');
    await assertNoAssist();
  }
}
