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
    var result = await resolveFileCode('$testPackageLibPath/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
    ]);
  }

  void test_annotationInLib_onLibrary() async {
    var result = await resolveFileCode('$testPackageLibPath/foo.dart', r'''
@internal
library foo;
import 'package:meta/meta.dart';
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 1, 8),
    ]);
  }

  void test_annotationInLibSrc() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInTestResult(result);
  }

  void test_annotationInLibSrcSubdirectory() async {
    var result = await resolveFileCode(
      '$testPackageLibPath/src/foo/foo.dart',
      r'''
import 'package:meta/meta.dart';
@internal class One {}
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_annotationInLibSubdirectory() async {
    var result = await resolveFileCode('$testPackageLibPath/foo/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
    ]);
  }

  void test_annotationInTest() async {
    var result = await resolveFileCode(
      '$testPackageRootPath/test/foo_test.dart',
      r'''
import 'package:meta/meta.dart';
@internal class One {}
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_annotationInTest_extensionType() async {
    var result = await resolveFileCode(
      '$testPackageRootPath/test/foo_test.dart',
      r'''
import 'package:meta/meta.dart';
@internal extension type E(int i) {}
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_privateClass() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal class _One {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 49, 4),
    ]);
  }

  void test_privateConstructor() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal C._f();
}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 46, 8),
    ]);
  }

  void test_privateEnum() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal enum _E {one}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 48, 2),
      error(diag.unusedField, 52, 3),
    ]);
  }

  void test_privateEnumValue() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
enum E {@internal _one}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 42, 8),
      error(diag.unusedField, 51, 4),
    ]);
  }

  void test_privateExtension() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension _One on String {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
    ]);
  }

  void test_privateExtension_unnamed() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension on String {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
    ]);
  }

  void test_privateExtensionType() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension type _E(int i) {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 58, 2),
    ]);
  }

  void test_privateField_instance() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal int _i = 0;
}
''');

    assertErrorsInTestResult(result, [
      error(diag.unusedField, 59, 2),
      error(diag.invalidInternalAnnotation, 59, 6),
    ]);
  }

  void test_privateField_static() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal static int _i = 0;
}
''');

    assertErrorsInTestResult(result, [
      error(diag.unusedField, 66, 2),
      error(diag.invalidInternalAnnotation, 66, 6),
    ]);
  }

  void test_privateGetter() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal int get _i => 0;
}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 46, 8),
      error(diag.unusedElement, 63, 2),
    ]);
  }

  void test_privateMethod_instance() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal void _f() {}
}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 46, 8),
      error(diag.unusedElement, 60, 2),
    ]);
  }

  void test_privateMethod_static() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal static void _f() {}
}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 46, 8),
      error(diag.unusedElement, 67, 2),
    ]);
  }

  void test_privateMixin() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal mixin _One {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 49, 4),
    ]);
  }

  void test_privateTopLevelFunction() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal void _f() {}
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 48, 2),
    ]);
  }

  void test_privateTopLevelVariable() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal int _i = 1;
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 47, 6),
      error(diag.unusedElement, 47, 2),
    ]);
  }

  void test_privateTypedef() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef _T = void Function();
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidInternalAnnotation, 34, 8),
      error(diag.unusedElement, 51, 2),
    ]);
  }

  void test_publicConstructor_named_privateClass() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C.named();
}
''');

    assertErrorsInTestResult(result, [
      error(diag.unusedElement, 39, 2),
      error(diag.invalidInternalAnnotation, 47, 8),
    ]);
  }

  void test_publicConstructor_primary_privateClass() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C() {
  @internal
  this;
}
''');

    assertErrorsInTestResult(result, [
      error(diag.unusedElement, 39, 2),
      error(diag.invalidInternalAnnotation, 49, 8),
    ]);
  }

  void test_publicConstructor_unnamed_privateClass() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C();
}
''');

    assertErrorsInTestResult(result, [
      error(diag.unusedElement, 39, 2),
      error(diag.invalidInternalAnnotation, 47, 8),
    ]);
  }

  void test_publicMethod_privateClass() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal void f() {}
}
''');

    assertErrorsInTestResult(result, [error(diag.unusedElement, 39, 2)]);
  }

  void test_publicMethod_privateClass_static() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal static void f() {}
}
''');

    assertErrorsInTestResult(result, [
      error(diag.unusedElement, 39, 2),
      error(diag.unusedElement, 68, 1),
    ]);
  }

  void test_publicMethod_privateExtensionType() async {
    var result = await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
extension type _E(int i) {
  @internal void f() {}
}
''');

    assertErrorsInTestResult(result, [error(diag.unusedElement, 48, 2)]);
  }
}
