// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements X {}
//                                  ^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'dynamic'.
typedef X = dynamic;
''');
  }

  test_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements X {}
//                                  ^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'X'.
typedef X = void Function();
''');
  }

  test_interfaceType_extensionTyp() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements X {}
extension type X(num it) {}
''');
  }

  test_interfaceType_function() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements Function {}
//                                  ^^^^^^^^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'Function'.
''');
  }

  test_interfaceType_futureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements FutureOr<int> {}
//                                  ^^^^^^^^^^^^^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'InvalidType'.
''');
  }

  test_interfaceType_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements X {}
//                                  ^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
typedef X = num?;
''');
  }

  test_interfaceType_num() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements num {}
''');
  }

  test_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements X {}
//                                  ^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'X'.
typedef X = (int, String);
''');
  }

  test_typeParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) implements T {}
//                                     ^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'T'.
''');
  }

  test_voidType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements X {}
//                                  ^
// [diag.extensionTypeImplementsDisallowedType] Extension types can't implement 'void'.
typedef X = void;
''');
  }
}
