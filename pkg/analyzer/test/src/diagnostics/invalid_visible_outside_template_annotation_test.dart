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

  test_invalid_classDeclaration() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
class C {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 50, 23),
    ]);
  }

  test_invalid_classField() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
  int a = 0;

  String b = '';
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 62, 23),
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
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 62, 23),
    ]);
  }

  test_invalid_constructor() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
  C();
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 62, 23),
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
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 66, 23),
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
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 61, 23),
    ]);
  }

  test_invalid_mixinClassDeclaration() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
mixin class M2 {
  int m() => 1;

  int a = 0;
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 50, 23),
    ]);
  }

  test_invalid_mixinClassMember() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

mixin class M2 {
  @visibleOutsideTemplate
  int m() => 1;

  int a = 0;
}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 69, 23),
    ]);
  }

  test_invalid_mixinDeclaration() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
mixin M {
  int m() => 1;

  int a = 0;
}
class C2 with M {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 50, 23),
    ]);
  }

  test_invalid_mixinMember() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

mixin M {
  @visibleOutsideTemplate
  int m() => 1;

  int a = 0;
}
class C2 with M {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 62, 23),
    ]);
  }

  test_invalid_topLevelFunction() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate void foo() {}
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 50, 23),
    ]);
  }

  test_invalid_topLevelVariable() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate final a = 1;
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 50, 23),
    ]);
  }

  test_invalid_topLevelVariable_multi() async {
    await assertErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate var a = 1, b;
''', [
      error(WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION, 50, 23),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C1 {
  @visibleOutsideTemplate
  int a = 0;

  int b = 0;

  String c = '';
}

@visibleForTemplate
enum E1 {
  @visibleOutsideTemplate
  a,
  b,
}

@visibleForTemplate
enum E2 {
  @visibleOutsideTemplate
  a,
  b;
  final int c = 0;
}

@visibleForTemplate
enum E3 {
  v;
  @visibleOutsideTemplate
  void test() {}
}

@visibleForTemplate
mixin M {
  @visibleOutsideTemplate
  int m() => 1;

  int a = 0;
}
class C2 with M {}

@visibleForTemplate
mixin class M2 {
  @visibleOutsideTemplate
  int m() => 1;

  int a = 0;
}
''');
  }
}
