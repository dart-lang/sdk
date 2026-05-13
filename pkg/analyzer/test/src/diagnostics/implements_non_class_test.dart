// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsNonClassTest);
  });
}

@reflectiveTest
class ImplementsNonClassTest extends PubPackageResolutionTest {
  test_inClass_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements dynamic {}
//                 ^^^^^^^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_inClass_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { ONE }
class A implements E {}
//                 ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_inClass_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
class B implements A {}
//                 ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_inClass_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 7;
class B implements A {}
//                 ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_inClassTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M {}
int B = 7;
class C = A with M implements B;
//                            ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_inEnum_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 7;
enum E implements A {
//                ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
  v
}
''');
  }

  test_inMixin_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M implements dynamic {}
//                 ^^^^^^^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_inMixin_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
mixin M implements A {}
//                 ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }

  test_Never() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements Never {}
//                 ^^^^^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
''');
  }
}
