// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidInternalAnnotationTest);
  });
}

@reflectiveTest
class InvalidInternalAnnotationTest extends PubPackageResolutionTest {
  String get testPackageLibSrcFilePath => '$testPackageLibPath/src/foo.dart';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
    newPubspecYamlFile(testPackageRootPath, r'''
name: test
version: 0.0.1
''');
  }

  void test_annotationInLib() async {
    await resolveFileCode('$testPackageLibPath/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertErrorsInResult([error(diag.invalidInternalAnnotation, 34, 8)]);
  }

  void test_annotationInLib_onLibrary() async {
    await resolveFileCode('$testPackageLibPath/foo.dart', r'''
@internal
library foo;
import 'package:meta/meta.dart';
''');

    assertErrorsInResult([error(diag.invalidInternalAnnotation, 1, 8)]);
  }

  void test_annotationInLibSrc() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInResult();
  }

  void test_annotationInLibSrcSubdirectory() async {
    await resolveFileCode('$testPackageLibPath/src/foo/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInResult();
  }

  void test_annotationInLibSubdirectory() async {
    await resolveFileCode('$testPackageLibPath/foo/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertErrorsInResult([error(diag.invalidInternalAnnotation, 34, 8)]);
  }

  void test_annotationInTest() async {
    await resolveFileCode('$testPackageRootPath/test/foo_test.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInResult();
  }

  void test_annotationInTest_extensionType() async {
    await resolveFileCode('$testPackageRootPath/test/foo_test.dart', r'''
import 'package:meta/meta.dart';
@internal extension type E(int i) {}
''');

    assertNoErrorsInResult();
  }

  void test_privateClass() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal class _One {}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 49, 4),
    ]);
  }

  void test_privateClassConstructor_named() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C.named();
}
''');

    assertErrorsInResult([
      error(diag.unusedElement, 39, 2),
      error(diag.invalidInternalAnnotation, 47, 8),
    ]);
  }

  void test_privateClassConstructor_unnamed() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C();
}
''');

    assertErrorsInResult([
      error(diag.unusedElement, 39, 2),
      error(diag.invalidInternalAnnotation, 47, 8),
    ]);
  }

  void test_privateConstructor() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal C._f();
}
''');

    assertErrorsInResult([error(diag.invalidInternalAnnotation, 46, 8)]);
  }

  void test_privateEnum() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal enum _E {one}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 48, 2),
      error(diag.unusedField, 52, 3),
    ]);
  }

  void test_privateEnumValue() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
enum E {@internal _one}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 42, 8),
      error(diag.unusedField, 51, 4),
    ]);
  }

  void test_privateExtension() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension _One on String {}
''');

    assertErrorsInResult([error(diag.invalidInternalAnnotation, 34, 8)]);
  }

  void test_privateExtension_unnamed() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension on String {}
''');

    assertErrorsInResult([error(diag.invalidInternalAnnotation, 34, 8)]);
  }

  void test_privateExtensionType() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension type _E(int i) {}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 58, 2),
    ]);
  }

  void test_privateField_instance() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal int _i = 0;
}
''');

    assertErrorsInResult([
      error(diag.unusedField, 59, 2),
      error(diag.invalidInternalAnnotation, 59, 6),
    ]);
  }

  void test_privateField_static() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal static int _i = 0;
}
''');

    assertErrorsInResult([
      error(diag.unusedField, 66, 2),
      error(diag.invalidInternalAnnotation, 66, 6),
    ]);
  }

  void test_privateGetter() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal int get _i => 0;
}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 46, 8),
      error(diag.unusedElement, 63, 2),
    ]);
  }

  void test_privateMethod_instance() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal void _f() {}
}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 46, 8),
      error(diag.unusedElement, 60, 2),
    ]);
  }

  void test_privateMethod_static() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal static void _f() {}
}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 46, 8),
      error(diag.unusedElement, 67, 2),
    ]);
  }

  void test_privateMixin() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal mixin _One {}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 49, 4),
    ]);
  }

  void test_privateTopLevelFunction() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal void _f() {}
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 48, 2),
    ]);
  }

  void test_privateTopLevelVariable() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal int _i = 1;
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 47, 6),
      error(diag.unusedElement, 47, 2),
    ]);
  }

  void test_privateTypedef() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef _T = void Function();
''');

    assertErrorsInResult([
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 51, 2),
    ]);
  }

  void test_publicMethod_privateClass() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal void f() {}
}
''');

    assertErrorsInResult([error(diag.unusedElement, 39, 2)]);
  }

  void test_publicMethod_privateClass_static() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal static void f() {}
}
''');

    assertErrorsInResult([
      error(diag.unusedElement, 39, 2),
      error(diag.unusedElement, 68, 1),
    ]);
  }

  void test_publicMethod_privateExtensionType() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
extension type _E(int i) {
  @internal void f() {}
}
''');

    assertErrorsInResult([error(diag.unusedElement, 48, 2)]);
  }
}
