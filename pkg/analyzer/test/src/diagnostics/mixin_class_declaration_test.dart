// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinClassDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinClassDeclarationTest extends PubPackageResolutionTest {
  test_class_extends_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B extends A {}
//                    ^
// [diag.mixinClassDeclarationExtendsNotObject] The class 'B' can't be declared a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_extends_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A extends Object {}
''');
  }

  test_class_extends_Object_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
mixin class A extends Object with M {}
//                           ^^^^^^
// [diag.mixinClassDeclarationWithClause] The class 'A' can't be declared a mixin because it has a 'with' clause.
''');
  }

  test_classTypeAlias_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
mixin class A = Object with M;
''');
  }

  test_classTypeAlias_with2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {}
mixin M2 {}
mixin class A = Object with M1, M2;
//                     ^^^^^^^^^^^
// [diag.mixinModifierMixinApplicationClassWithMultipleMixins] The mixin application class 'A' can only have a single mixin.
''');
  }
}
