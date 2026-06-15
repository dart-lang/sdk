// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInheritsFromNotObjectTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinInheritsFromNotObjectTest extends PubPackageResolutionTest {
  test_class_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B extends A {}
//                    ^
// [diag.mixinClassDeclarationExtendsNotObject] The class 'B' can't be declared a mixin because it extends a class other than 'Object'.
class C extends Object with B {}
//                          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_class_extends_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends A {}
class C extends Object with B {}
//                          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_class_extends_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B extends Object {}
class C extends Object with B {}
''');
  }

  test_class_class_extends_Object_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends Object {}
class C extends Object with B {}
''');
  }

  test_class_class_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B extends Object with A {}
//                           ^^^^^^
// [diag.mixinClassDeclarationWithClause] The class 'B' can't be declared a mixin because it has a 'with' clause.
class C extends Object with B {}
//                          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_class_with_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends Object with A {}
class C extends Object with B {}
//                          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_classTypeAlias_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B = Object with A;
class C extends Object with B {}
''');
  }

  test_class_classTypeAlias_with2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B {}
mixin class C = Object with A, B;
//                     ^^^^^^^^^
// [diag.mixinModifierMixinApplicationClassWithMultipleMixins] The mixin application class 'C' can only have a single mixin.
class D extends Object with C {}
//                          ^
// [diag.mixinInheritsFromNotObject] The class 'C' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_classTypeAlias_with2_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B {}
class C = Object with A, B;
class D extends Object with C {}
//                          ^
// [diag.mixinInheritsFromNotObject] The class 'C' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_class_classTypeAlias_with_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B = Object with A;
class C extends Object with B {}
''');
  }

  test_class_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin B on A {}
class C extends A with B {}
''');
  }

  test_classTypeAlias_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B extends A {}
//                    ^
// [diag.mixinClassDeclarationExtendsNotObject] The class 'B' can't be declared a mixin because it extends a class other than 'Object'.
class C = Object with B;
//                    ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_classTypeAlias_class_extends_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends A {}
class C = Object with B;
//                    ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_classTypeAlias_class_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B extends Object with A {}
//                           ^^^^^^
// [diag.mixinClassDeclarationWithClause] The class 'B' can't be declared a mixin because it has a 'with' clause.
class C = Object with B;
//                    ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_classTypeAlias_class_with_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends Object with A {}
class C = Object with B;
//                    ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_classTypeAlias_classAlias_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B = Object with A;
class C = Object with B;
''');
  }

  test_classTypeAlias_classAlias_with2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B {}
mixin class C = Object with A, B;
//                     ^^^^^^^^^
// [diag.mixinModifierMixinApplicationClassWithMultipleMixins] The mixin application class 'C' can only have a single mixin.
class D = Object with C;
//                    ^
// [diag.mixinInheritsFromNotObject] The class 'C' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_classTypeAlias_classAlias_with2_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B {}
class C = Object with A, B;
class D = Object with C;
//                    ^
// [diag.mixinInheritsFromNotObject] The class 'C' can't be used as a mixin because it extends a class other than 'Object'.
''');
  }

  test_classTypeAlias_classAlias_with_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B = Object with A;
class C = Object with B;
''');
  }

  test_classTypeAlias_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin B on A {}
class C = A with B;
''');
  }

  test_enum_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B extends A {}
//                    ^
// [diag.mixinClassDeclarationExtendsNotObject] The class 'B' can't be declared a mixin because it extends a class other than 'Object'.
enum E with B {
//          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
  v
}
''');
  }

  test_enum_class_extends_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends A {}
enum E with B {
//          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
  v
}
''');
  }

  test_enum_class_extends_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B extends Object {}
enum E with B {
  v
}
''');
  }

  test_enum_class_extends_Object_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends Object {}
enum E with B {
  v
}
''');
  }

  test_enum_class_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B extends Object with A {}
//                           ^^^^^^
// [diag.mixinClassDeclarationWithClause] The class 'B' can't be declared a mixin because it has a 'with' clause.
enum E with B {
//          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
  v
}
''');
  }

  test_enum_class_with_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B extends Object with A {}
enum E with B {
//          ^
// [diag.mixinInheritsFromNotObject] The class 'B' can't be used as a mixin because it extends a class other than 'Object'.
  v
}
''');
  }

  test_enum_classTypeAlias_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B = Object with A;
enum E with B {
  v
}
''');
  }

  test_enum_classTypeAlias_with2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B {}
class C = Object with A, B;
enum E with C {
//          ^
// [diag.classUsedAsMixin] The class 'C' can't be used as a mixin because it's neither a mixin class nor a mixin.
  v
}
''');
  }

  test_enum_classTypeAlias_with2_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B {}
class C = Object with A, B;
enum E with C {
//          ^
// [diag.mixinInheritsFromNotObject] The class 'C' can't be used as a mixin because it extends a class other than 'Object'.
  v
}
''');
  }

  test_enum_classTypeAlias_with_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
class A {}
class B = Object with A;
enum E with B {
  v
}
''');
  }

  test_mixinClass_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B extends A {}
//                    ^
// [diag.mixinClassDeclarationExtendsNotObject] The class 'B' can't be declared a mixin because it extends a class other than 'Object'.
''');
  }

  test_mixinClass_class_extends_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A extends Object {}
''');
  }

  test_mixinClass_class_extends_Object_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B extends Object with A {}
//                           ^^^^^^
// [diag.mixinClassDeclarationWithClause] The class 'B' can't be declared a mixin because it has a 'with' clause.
''');
  }

  test_mixinClass_class_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
mixin class A with M {}
//            ^^^^^^
// [diag.mixinClassDeclarationWithClause] The class 'A' can't be declared a mixin because it has a 'with' clause.
''');
  }

  test_mixinClass_classTypeAlias_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B = Object with A;
''');
  }

  test_mixinClass_classTypeAlias_with2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B {}
mixin class C = Object with A, B;
//                     ^^^^^^^^^
// [diag.mixinModifierMixinApplicationClassWithMultipleMixins] The mixin application class 'C' can only have a single mixin.
''');
  }
}
