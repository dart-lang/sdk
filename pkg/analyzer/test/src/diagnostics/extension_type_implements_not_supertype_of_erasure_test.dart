// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeImplementsNotSupertypeTest);
  });
}

@reflectiveTest
class ExtensionTypeImplementsNotSupertypeTest extends PubPackageResolutionTest {
  test_notSupertype_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
extension type B(A it) implements num {}
//                                ^^^
// [diag.extensionTypeImplementsNotSupertype] 'num' is not a supertype of 'A', the representation type.
''');
  }

  test_notSupertype_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements String {}
//                                  ^^^^^^
// [diag.extensionTypeImplementsNotSupertype] 'String' is not a supertype of 'int', the representation type.
''');
  }

  test_supertype() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements num {}
''');
  }

  test_supertype2() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(S3 it) implements S1 {}
class S1 {}
class S2 extends S1 {}
class S3 extends S2 {}
''');
  }
}
