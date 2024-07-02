// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidVisibleOutsideTemplateAnnotationTest);
  });
}

@reflectiveTest
class InvalidVisibleOutsideTemplateAnnotationTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(PackageConfigFileBuilder(),
        angularMeta: true, meta: true);
  }

  test_invalid_classConstructor() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
  C();
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 63, 22),
    ]);
  }

  test_invalid_classDeclaration() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
class C {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 51, 22),
    ]);
  }

  test_invalid_classField() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
  int a = 0;
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 63, 22),
    ]);
  }

  test_invalid_classMethod() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
  void m() {}
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 63, 22),
    ]);
  }

  test_invalid_enumClassMember() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

enum E {
  v;
  @visibleOutsideTemplate
  void test() {}
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 67, 22),
    ]);
  }

  test_invalid_enumConstant() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

enum E {
  @visibleOutsideTemplate
  a,
  b,
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 62, 22),
    ]);
  }

  test_invalid_mixinClassDeclaration() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
mixin class M2 {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 51, 22),
    ]);
  }

  test_invalid_mixinClassMember() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

mixin class M2 {
  @visibleOutsideTemplate
  int m() => 1;
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 70, 22),
    ]);
  }

  test_invalid_mixinDeclaration() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
mixin M {}
class C2 with M {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 51, 22),
    ]);
  }

  test_invalid_mixinMember() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

mixin M {
  @visibleOutsideTemplate
  int m() => 1;
}
class C2 with M {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 63, 22),
    ]);
  }

  test_invalid_topLevelFunction() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
void foo() {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 51, 22),
    ]);
  }

  test_invalid_topLevelVariable() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
final a = 1;
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 51, 22),
    ]);
  }

  test_invalid_topLevelVariable_multi() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
var a = 1, b;
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 51, 22),
    ]);
  }

  test_valid_classConstructor() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  C();
}
''');
  }

  test_valid_classField() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  int a = 0;
}
''');
  }

  test_valid_classMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  void m() {}
}
''');
  }

  test_valid_enumClassMember() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  v;
  @visibleOutsideTemplate
  void test() {}
}
''');
  }

  test_valid_enumConstant() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  @visibleOutsideTemplate
  a,
  b,
}
''');
  }

  test_valid_mixinClassMember() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin class M2 {
  @visibleOutsideTemplate
  int m() => 1;
}
''');
  }

  test_valid_mixinMember() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  @visibleOutsideTemplate
  int m() => 1;
}
class C2 with M {}
''');
  }
}
