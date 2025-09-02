// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInheritsFromNotObjectTest);
  });
}

@reflectiveTest
class MixinInheritsFromNotObjectTest extends PubPackageResolutionTest {
  test_class_class_extends() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin class B extends A {}
class C extends Object with B {}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          33,
          1,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 66, 1),
      ],
    );
  }

  test_class_class_extends_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B extends A {}
class C extends Object with B {}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 74, 1)],
    );
  }

  test_class_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin class B extends Object {}
class C extends Object with B {}
''');
  }

  test_class_class_extends_Object_language219() async {
    await assertNoErrorsInCode(r'''
// @dart=2.19
class A {}
class B extends Object {}
class C extends Object with B {}
''');
  }

  test_class_class_with() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B extends Object with A {}
class C extends Object with B {}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          46,
          6,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 84, 1),
      ],
    );
  }

  test_class_class_with_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B extends Object with A {}
class C extends Object with B {}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 86, 1)],
    );
  }

  test_class_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin class A {}
mixin class B = Object with A;
class C extends Object with B {}
''');
  }

  test_class_classTypeAlias_with2() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B {}
mixin class C = Object with A, B;
class D extends Object with C {}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          57,
          9,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 96, 1),
      ],
    );
  }

  test_class_classTypeAlias_with2_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B {}
class C = Object with A, B;
class D extends Object with C {}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 92, 1)],
    );
  }

  test_class_classTypeAlias_with_language219() async {
    await assertNoErrorsInCode(r'''
// @dart=2.19
class A {}
class B = Object with A;
class C extends Object with B {}
''');
  }

  test_class_mixin() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C extends A with B {}
''');
  }

  test_classTypeAlias_class_extends() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin class B extends A {}
class C = Object with B;
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          33,
          1,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 60, 1),
      ],
    );
  }

  test_classTypeAlias_class_extends_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B extends A {}
class C = Object with B;
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 68, 1)],
    );
  }

  test_classTypeAlias_class_with() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B extends Object with A {}
class C = Object with B;
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          46,
          6,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 78, 1),
      ],
    );
  }

  test_classTypeAlias_class_with_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B extends Object with A {}
class C = Object with B;
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 80, 1)],
    );
  }

  test_classTypeAlias_classAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin class A {}
mixin class B = Object with A;
class C = Object with B;
''');
  }

  test_classTypeAlias_classAlias_with2() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B {}
mixin class C = Object with A, B;
class D = Object with C;
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          57,
          9,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 90, 1),
      ],
    );
  }

  test_classTypeAlias_classAlias_with2_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B {}
class C = Object with A, B;
class D = Object with C;
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 86, 1)],
    );
  }

  test_classTypeAlias_classAlias_with_language219() async {
    await assertNoErrorsInCode(r'''
// @dart=2.19
class A {}
class B = Object with A;
class C = Object with B;
''');
  }

  test_classTypeAlias_mixin() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C = A with B;
''');
  }

  test_enum_class_extends() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin class B extends A {}
enum E with B {
  v
}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          33,
          1,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 50, 1),
      ],
    );
  }

  test_enum_class_extends_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B extends A {}
enum E with B {
  v
}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 58, 1)],
    );
  }

  test_enum_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin class B extends Object {}
enum E with B {
  v
}
''');
  }

  test_enum_class_extends_Object_language219() async {
    await assertNoErrorsInCode(r'''
// @dart=2.19
class A {}
class B extends Object {}
enum E with B {
  v
}
''');
  }

  test_enum_class_with() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B extends Object with A {}
enum E with B {
  v
}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          46,
          6,
        ),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 68, 1),
      ],
    );
  }

  test_enum_class_with_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B extends Object with A {}
enum E with B {
  v
}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 70, 1)],
    );
  }

  test_enum_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin class A {}
mixin class B = Object with A;
enum E with B {
  v
}
''');
  }

  test_enum_classTypeAlias_with2() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B {}
class C = Object with A, B;
enum E with C {
  v
}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 74, 1)],
    );
  }

  test_enum_classTypeAlias_with2_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
class A {}
class B {}
class C = Object with A, B;
enum E with C {
  v
}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 76, 1)],
    );
  }

  test_enum_classTypeAlias_with_language219() async {
    await assertNoErrorsInCode(r'''
// @dart=2.19
class A {}
class B = Object with A;
enum E with B {
  v
}
''');
  }

  test_mixinClass_class_extends() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B extends A {}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          39,
          1,
        ),
      ],
    );
  }

  test_mixinClass_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
mixin class A extends Object {}
''');
  }

  test_mixinClass_class_extends_Object_with() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B extends Object with A {}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          46,
          6,
        ),
      ],
    );
  }

  test_mixinClass_class_with() async {
    await assertErrorsInCode(
      r'''
mixin M {}
mixin class A with M {}
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          25,
          6,
        ),
      ],
    );
  }

  test_mixinClass_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin class A {}
mixin class B = Object with A;
''');
  }

  test_mixinClass_classTypeAlias_with2() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B {}
mixin class C = Object with A, B;
''',
      [
        error(
          CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
          57,
          9,
        ),
      ],
    );
  }
}
