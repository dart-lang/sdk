// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
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

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      angularMeta: true,
      meta: true,
    );
  }

  test_invalid_classConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  C();
}
''');
  }

  test_invalid_classDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
// [diag.invalidVisibleOutsideTemplateAnnotation][column 2][length 22] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
class C {}
''');
  }

  test_invalid_classField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  int a = 0;
}
''');
  }

  test_invalid_classMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

class C {
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  void m() {}
}
''');
  }

  test_invalid_enumClassMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

enum E {
  v;
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  void test() {}
}
''');
  }

  test_invalid_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

enum E {
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  a,
  b,
}
''');
  }

  test_invalid_mixinClassDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
// [diag.invalidVisibleOutsideTemplateAnnotation][column 2][length 22] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
mixin class M2 {}
''');
  }

  test_invalid_mixinClassMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

mixin class M2 {
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  int m() => 1;
}
''');
  }

  test_invalid_mixinDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
// [diag.invalidVisibleOutsideTemplateAnnotation][column 2][length 22] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
mixin M {}
class C2 with M {}
''');
  }

  test_invalid_mixinMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

mixin M {
  @visibleOutsideTemplate
// ^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidVisibleOutsideTemplateAnnotation] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
  int m() => 1;
}
class C2 with M {}
''');
  }

  test_invalid_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
// [diag.invalidVisibleOutsideTemplateAnnotation][column 2][length 22] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
void foo() {}
''');
  }

  test_invalid_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
// [diag.invalidVisibleOutsideTemplateAnnotation][column 2][length 22] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
final a = 1;
''');
  }

  test_invalid_topLevelVariable_multi() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleOutsideTemplate
// [diag.invalidVisibleOutsideTemplateAnnotation][column 2][length 22] The annotation 'visibleOutsideTemplate' can only be applied to a member of a class, enum, or mixin that is annotated with 'visibleForTemplate'.
var a = 1, b;
''');
  }

  test_valid_classConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  C();
}
''');
  }

  test_valid_classField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  int a = 0;
}
''');
  }

  test_valid_classMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  void m() {}
}
''');
  }

  test_valid_enumClassMember() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin class M2 {
  @visibleOutsideTemplate
  int m() => 1;
}
''');
  }

  test_valid_mixinMember() async {
    await resolveTestCodeWithDiagnostics(r'''
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
