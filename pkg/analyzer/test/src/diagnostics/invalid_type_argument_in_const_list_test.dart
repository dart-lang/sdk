// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertNoErrorsInCode(r'''
class A<E> {
  void m() {
    <E>[];
  }
}
''');
  }

  test_typeParameter_asTypeArgument() async {
    await assertErrorsInCode(
      r'''
class A<E> {
  void m() {
    const <E>[];
  }
}
''',
      [
        error(
          diag.invalidTypeArgumentInConstList,
          37,
          1,
          messageContains: ["'E'"],
        ),
      ],
    );
  }

  test_typeParameter_deepInTypeArgument_functionType_parameter() async {
    await assertErrorsInCode(
      r'''
class A<E> {
  void m() {
    const <void Function(E)>[];
  }
}
''',
      [
        error(
          diag.invalidTypeArgumentInConstList,
          51,
          1,
          messageContains: ["'E'"],
        ),
      ],
    );
  }

  test_typeParameter_deepInTypeArgument_functionType_returnType() async {
    await assertErrorsInCode(
      r'''
class A<E> {
  void m() {
    const <E Function()>[];
  }
}
''',
      [
        error(
          diag.invalidTypeArgumentInConstList,
          37,
          1,
          messageContains: ["'E'"],
        ),
      ],
    );
  }

  test_typeParameter_deepInTypeArgument_namedType() async {
    await assertErrorsInCode(
      r'''
class A<E> {
  void m() {
    const <List<E>>[];
  }
}
''',
      [
        error(
          diag.invalidTypeArgumentInConstList,
          42,
          1,
          messageContains: ["'E'"],
        ),
      ],
    );
  }

  test_typeParameter_deepInTypeArgument_recordType_fieldType() async {
    await assertErrorsInCode(
      r'''
class A<E> {
  void m() {
    const <(E a, int b)>[];
  }
}
''',
      [
        error(
          diag.invalidTypeArgumentInConstList,
          38,
          1,
          messageContains: ["'E'"],
        ),
      ],
    );
  }
}
