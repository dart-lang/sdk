// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullAssertPatternTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryNullAssertPatternTest extends PubPackageResolutionTest {
  Future<void> test_interfaceType_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(int x) {
  if (x case var a!) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                ^
// [diag.unnecessaryNullAssertPattern] The null-assert pattern will have no effect because the matched type isn't nullable.
}
''');
  }

  Future<void> test_interfaceType_nullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(int? x) {
  if (x case var a!) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  Future<void> test_invalidType_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
UnknownType getValue() => UnknownType();
// [diag.undefinedClass][column 1][length 11] Undefined class 'UnknownType'.
//                        ^^^^^^^^^^^
// [diag.undefinedFunction] The function 'UnknownType' isn't defined.
void f() {
  if (getValue() case final valueX!) {
    print(valueX);
  }
}
''');
  }

  Future<void> test_invalidType_nullable() async {
    await resolveTestCodeWithDiagnostics('''
UnknownType? getValue() => null;
// [diag.undefinedClass][column 1][length 11] Undefined class 'UnknownType'.
void f() {
  if (getValue() case final valueX!) {
    print(valueX);
  }
}
''');
  }

  Future<void> test_typeParameter_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A<T extends num> {
  void f(T x) {
    if (x case var a!) {}
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                  ^
// [diag.unnecessaryNullAssertPattern] The null-assert pattern will have no effect because the matched type isn't nullable.
  }
}
''');
  }

  Future<void> test_typeParameter_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  void f(T x) {
    if (x case var a!) {}
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }
}
