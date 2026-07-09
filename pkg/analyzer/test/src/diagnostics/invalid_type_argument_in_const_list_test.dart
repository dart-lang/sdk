// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidTypeArgumentInConstListTest);
  });
}

@reflectiveTest
class InvalidTypeArgumentInConstListTest extends PubPackageResolutionTest {
  test_nonConst() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    <E>[];
  }
}
''');
  }

  test_typeParameter_asTypeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <E>[];
//         ^
// [diag.invalidTypeArgumentInConstList] Constant list literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_deepInTypeArgument_functionType_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <void Function(E)>[];
//                       ^
// [diag.invalidTypeArgumentInConstList] Constant list literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_deepInTypeArgument_functionType_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <E Function()>[];
//         ^
// [diag.invalidTypeArgumentInConstList] Constant list literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_deepInTypeArgument_namedType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <List<E>>[];
//              ^
// [diag.invalidTypeArgumentInConstList] Constant list literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_deepInTypeArgument_recordType_fieldType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <(E a, int b)>[];
//          ^
// [diag.invalidTypeArgumentInConstList] Constant list literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }
}
