// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/services/refactoring/convert_selected_formal_parameters_to_named.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertSelectedFormalParametersToNamedTest);
  });
}

@reflectiveTest
class ConvertSelectedFormalParametersToNamedTest extends RefactoringTest {
  @override
  String get refactoringName =>
      ConvertSelectedFormalParametersToNamed.commandName;

  Future<void> test_constructor_factoryKeyword() async {
    addTestSource(r'''
class A {
  new _();
  factory(int ^a, {int? b}) => A._();
}

void f() {
  A(0, b: 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A {
  new _();
  factory({int? b, required int a}) => A._();
}

void f() {
  A(b: 1, a: 0);
}
''');
  }

  Future<void> test_constructor_named_factoryKeyword() async {
    addTestSource(r'''
class A {
  new();
  factory named(int ^a, {int? b}) => A();
}

void f() {
  A.named(0, b: 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A {
  new();
  factory named({int? b, required int a}) => A();
}

void f() {
  A.named(b: 1, a: 0);
}
''');
  }

  Future<void> test_constructor_named_newKeyword() async {
    addTestSource(r'''
class A {
  new named(int ^a, {int? b});
}

void f() {
  A.named(0, b: 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A {
  new named({int? b, required int a});
}

void f() {
  A.named(b: 1, a: 0);
}
''');
  }

  Future<void> test_constructor_newKeyword() async {
    addTestSource(r'''
class A {
  new(int ^a, {int? b});
}

void f() {
  A(0, b: 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A {
  new({int? b, required int a});
}

void f() {
  A(b: 1, a: 0);
}
''');
  }

  Future<void> test_multiple_optionalNamed_12of4() async {
    addTestSource(r'''
void test({int a, [!int b, int c!], int d}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({int a, required int b, required int c, int d}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');
  }

  Future<void> test_multiple_optionalPositional_01of2() async {
    addTestSource(r'''
void test(int a, [[!int b, int c!]]) {}

void f() {
  test(0, 1, 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, {required int b, required int c}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');
  }

  Future<void> test_multiple_optionalPositional_01of3() async {
    addTestSource(r'''
void test([[!int a, int b!], int c]) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_multiple_requiredNamed_12of4() async {
    addTestSource(r'''
void test({
  required int a,
  [!required int b,
  required int c!],
  required int d,
}) {}

void f() {
  test(a: 0, b: 1, c: 2, d: 3);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_multiple_requiredPositional_12of4() async {
    addTestSource(r'''
void test(int a, [!int b, int c!], int d) {}

void f() {
  test(0, 1, 2, 3);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, int d, {required int b, required int c}) {}

void f() {
  test(0, 3, b: 1, c: 2);
}
''');
  }

  Future<void> test_primaryConstructor() async {
    addTestSource(r'''
class A(int ^a, {int? b}) {
  this {
    A(0, b: 1);
  }
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A({int? b, required int a}) {
  this {
    A(b: 1, a: 0);
  }
}
''');
  }

  Future<void> test_primaryConstructor_declaringParameter() async {
    addTestSource(r'''
class A(int a, [!final int b, int c!], {int? d}) {
  this {
    A(0, 1, 2, d: 1);
  }
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A(int a, {int? d, required final int b, required int c}) {
  this {
    A(0, d: 1, b: 1, c: 2);
  }
}
''');
  }

  Future<void> test_primaryConstructor_named() async {
    addTestSource(r'''
class A.named(int ^a, {int? b}) {
  this {
    A.named(0, b: 1);
  }
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class A.named({int? b, required int a}) {
  this {
    A.named(b: 1, a: 0);
  }
}
''');
  }

  Future<void> test_private_primaryConstructor() async {
    addTestSource(r'''
class C(this.^_a, {this._b}) {
  this {
    C(0, b: 1);
  }
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class C({this._b, required this._a}) {
  this {
    C(a: 0, b: 1);
  }
}
''');
  }

  Future<void> test_privateInitializingFormal() async {
    addTestSource(r'''
class C {
  int _a;

  C([!this._a!]);
}

void f() {
  C(0);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
class C {
  int _a;

  C({required this._a});
}

void f() {
  C(a: 0);
}
''');
  }

  Future<void> test_privateInitializingFormal_unsupported() async {
    addTestSource(r'''
// @dart=3.10
class C {
  int _a;

  C([!this._a!]);
}

void f() {
  C(0);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_optionalNamed_0of1() async {
    addTestSource(r'''
void test(int a, {int ^b}) {}

void f() {
  test(0, b: 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, {required int b}) {}

void f() {
  test(0, b: 1);
}
''');
  }

  Future<void> test_single_optionalNamed_0of2() async {
    addTestSource(r'''
void test(int a, {int ^b, int c}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, {required int b, int c}) {}

void f() {
  test(0, b: 1, c: 2);
}
''');
  }

  Future<void> test_single_optionalPositional_0of1() async {
    addTestSource(r'''
void test(int a, [int? ^b]) {}

void f() {
  test(0, 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, {required int? b}) {}

void f() {
  test(0, b: 1);
}
''');
  }

  Future<void> test_single_optionalPositional_0of2() async {
    addTestSource(r'''
void test(int a, [int? ^b, int c]) {}

void f() {
  test(0, 1, 2);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredNamed() async {
    addTestSource(r'''
void test(int a, {required int ^b}) {}

void f() {
  test(0, b: 1);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> test_single_requiredPositional_0of2() async {
    addTestSource(r'''
void test(int ^a, int b) {}

void f() {
  test(0, 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int b, {required int a}) {}

void f() {
  test(1, a: 0);
}
''');
  }

  Future<void> test_single_requiredPositional_1of2() async {
    addTestSource(r'''
void test(int a, int ^b) {}

void f() {
  test(0, 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, {required int b}) {}

void f() {
  test(0, b: 1);
}
''');
  }

  Future<void> test_single_requiredPositional_1of3() async {
    addTestSource(r'''
void test(int a, int ^b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test(int a, int c, {required int b}) {}

void f() {
  test(0, 2, b: 1);
}
''');
  }

  Future<void> test_single_requiredPositional_hasNamed() async {
    addTestSource(r'''
void test(int ^a, {
  required int b,
}) {}

void f() {
  test(0, b: 1);
}
''');

    await verifyRefactoring(r'''
>>>>>>>>>> lib/main.dart
void test({required int b, required int a}) {}

void f() {
  test(b: 1, a: 0);
}
''');
  }

  Future<void> test_single_requiredPositional_hasOptionalPositional() async {
    addTestSource(r'''
void test(int ^a, [int? b]) {}

void f() {
  test(0, 1);
}
''');

    await _assertNoRefactoring();
  }

  Future<void> verifyRefactoring(String expected) async {
    await initializeServer();

    var codeAction = await expectCodeActionWithTitle(
      ConvertSelectedFormalParametersToNamed.constTitle,
    );

    await verifyCommandEdits(codeAction.command!, expected);
  }

  Future<void> _assertNoRefactoring() async {
    await initializeServer();

    await expectNoCodeActionWithTitle(
      ConvertSelectedFormalParametersToNamed.constTitle,
    );
  }
}
