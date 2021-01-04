// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateFieldFormalParameterTest);
  });
}

@reflectiveTest
class DuplicateFieldFormalParameterTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_optional_named() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A({this.a = 0, this.a = 1});
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 41, 1),
    ]);
  }

  test_optional_positional() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A([this.a = 0, this.a = 1]);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 41, 1),
    ]);
  }

  test_required_named() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A({required this.a, required this.a});
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 55, 1),
    ]);
  }

  test_required_positional() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A(this.a, this.a);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER, 36, 1),
    ]);
  }
}
