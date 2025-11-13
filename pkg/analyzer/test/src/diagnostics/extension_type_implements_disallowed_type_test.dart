// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
extension type A(int it) implements X {}
typedef X = dynamic;
''',
      [error(diag.extensionTypeImplementsDisallowedType, 36, 1)],
    );
  }

  test_functionType() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements X {}
typedef X = void Function();
''',
      [error(diag.extensionTypeImplementsDisallowedType, 36, 1)],
    );
  }

  test_interfaceType_extensionTyp() async {
    await assertNoErrorsInCode('''
extension type A(int it) implements X {}
extension type X(num it) {}
''');
  }

  test_interfaceType_function() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements Function {}
''',
      [error(diag.extensionTypeImplementsDisallowedType, 36, 8)],
    );
  }

  test_interfaceType_futureOr() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements FutureOr<int> {}
''',
      [error(diag.extensionTypeImplementsDisallowedType, 36, 13)],
    );
  }

  test_interfaceType_nullable() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements X {}
typedef X = num?;
''',
      [error(diag.nullableTypeInImplementsClause, 36, 1)],
    );
  }

  test_interfaceType_num() async {
    await assertNoErrorsInCode('''
extension type A(int it) implements num {}
''');
  }

  test_recordType() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements X {}
typedef X = (int, String);
''',
      [error(diag.extensionTypeImplementsDisallowedType, 36, 1)],
    );
  }

  test_typeParameterType() async {
    await assertErrorsInCode(
      '''
extension type A<T>(int it) implements T {}
''',
      [error(diag.extensionTypeImplementsDisallowedType, 39, 1)],
    );
  }

  test_voidType() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements X {}
typedef X = void;
''',
      [error(diag.extensionTypeImplementsDisallowedType, 36, 1)],
    );
  }
}
