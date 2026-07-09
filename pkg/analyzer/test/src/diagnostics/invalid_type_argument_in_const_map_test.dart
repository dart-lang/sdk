// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidTypeArgumentInConstMapTest);
  });
}

@reflectiveTest
class InvalidTypeArgumentInConstMapTest extends PubPackageResolutionTest {
  test_asDefaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  final Map<String, List<E Function()>> x;
  const A([this.x = const <String, List<E Function()>>{}]);
//                                      ^
// [diag.invalidTypeArgumentInConstMap] Constant map literals can't use a type parameter in a type argument, such as 'E'.
}
''');
  }

  test_nonConst() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    <String, E>{};
  }
}
''');
  }

  test_typeParameter_inKey() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <E, String>{};
//         ^
// [diag.invalidTypeArgumentInConstMap] Constant map literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_inKey_deepInside() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <void Function(List<E>), String>{};
//                            ^
// [diag.invalidTypeArgumentInConstMap] Constant map literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_inValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <String, E>{};
//                 ^
// [diag.invalidTypeArgumentInConstMap] Constant map literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }

  test_typeParameter_inValue_deepInside() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  void m() {
    const <String, List<E Function()>>{};
//                      ^
// [diag.invalidTypeArgumentInConstMap] Constant map literals can't use a type parameter in a type argument, such as 'E'.
  }
}
''');
  }
}
