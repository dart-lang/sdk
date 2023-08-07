// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeImplementsDisallowedTypeTest);
  });
}

@reflectiveTest
class ExtensionTypeImplementsDisallowedTypeTest
    extends PubPackageResolutionTest {
  test_dynamicType() async {
    await assertErrorsInCode('''
extension type A(int it) implements X {}
typedef X = dynamic;
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 36,
          1),
    ]);
  }

  test_functionType() async {
    await assertErrorsInCode('''
extension type A(int it) implements X {}
typedef X = void Function();
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 36,
          1),
    ]);
  }

  test_interfaceType_extensionTyp() async {
    await assertNoErrorsInCode('''
extension type A(int it) implements X {}
extension type X(num it) {}
''');
  }

  test_interfaceType_function() async {
    await assertErrorsInCode('''
extension type A(int it) implements Function {}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 36,
          8),
    ]);
  }

  test_interfaceType_futureOr() async {
    await assertErrorsInCode('''
extension type A(int it) implements FutureOr<int> {}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 36,
          13),
    ]);
  }

  test_interfaceType_nullable() async {
    await assertErrorsInCode('''
extension type A(int it) implements X {}
typedef X = num?;
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE, 36, 1),
    ]);
  }

  test_interfaceType_num() async {
    await assertNoErrorsInCode('''
extension type A(int it) implements num {}
''');
  }

  test_recordType() async {
    await assertErrorsInCode('''
extension type A(int it) implements X {}
typedef X = (int, String);
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 36,
          1),
    ]);
  }

  test_typeParameterType() async {
    await assertErrorsInCode('''
extension type A<T>(int it) implements T {}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 39,
          1),
    ]);
  }

  test_voidType() async {
    await assertErrorsInCode('''
extension type A(int it) implements X {}
typedef X = void;
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE, 36,
          1),
    ]);
  }
}
