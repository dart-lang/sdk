// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidInternalAnnotationTest);
  });
}

@reflectiveTest
class InvalidInternalAnnotationTest extends PubPackageResolutionTest {
  String get testPackageImplementationFilePath =>
      '$testPackageLibPath/src/foo.dart';

  @override
  void setUp() async {
    super.setUp();
    writeTestPackageConfigWithMeta();
    newFile('$testPackageRootPath/pubspec.yaml', content: r'''
name: test
version: 0.0.1
''');
  }

  void test_annotationInLib() async {
    newFile('$testPackageLibPath/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageLibPath/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_annotationInLib_onLibrary() async {
    newFile('$testPackageLibPath/foo.dart', content: r'''
@internal
library foo;
import 'package:meta/meta.dart';
''');
    await resolveFile2('$testPackageLibPath/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 0, 9),
    ]);
  }

  void test_annotationInLibSrc() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_annotationInLibSrcSubdirectory() async {
    newFile('$testPackageLibPath/src/foo/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageLibPath/src/foo/foo.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_annotationInLibSubdirectory() async {
    newFile('$testPackageLibPath/foo/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageLibPath/foo/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_annotationInTest() async {
    newFile('$testPackageRootPath/test/foo_test.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageRootPath/test/foo_test.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_privateClass() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class _One {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 49, 4),
    ]);
  }

  void test_privateClassConstructor_named() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C.named();
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.UNUSED_ELEMENT, 39, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 46, 9),
    ]);
  }

  void test_privateClassConstructor_unnamed() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C();
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.UNUSED_ELEMENT, 39, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 46, 9),
    ]);
  }

  void test_privateConstructor() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class C {
  @internal C._f();
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
    ]);
  }

  void test_privateEnum() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal enum _E {one}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 48, 2),
      error(HintCode.UNUSED_FIELD, 52, 3),
    ]);
  }

  void test_privateEnumValue() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
enum E {@internal _one}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 41, 9),
      error(HintCode.UNUSED_FIELD, 51, 4),
    ]);
  }

  void test_privateExtension() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal extension _One on String {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_privateExtension_unnamed() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal extension on String {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_privateField_instance() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class C {
  @internal int _i = 0;
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.UNUSED_FIELD, 59, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 59, 6),
    ]);
  }

  void test_privateField_static() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class C {
  @internal static int _i = 0;
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.UNUSED_FIELD, 66, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 66, 6),
    ]);
  }

  void test_privateGetter() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class C {
  @internal int get _i => 0;
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
      error(HintCode.UNUSED_ELEMENT, 63, 2),
    ]);
  }

  void test_privateMethod_instance() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
class C {
  @internal void _f() {}
}
''');
    await resolveFile2(testPackageImplementationFilePath);

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
      error(HintCode.UNUSED_ELEMENT, 60, 2),
    ]);
  }

  void test_privateMethod_static() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
class C {
  @internal static void _f() {}
}
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
      error(HintCode.UNUSED_ELEMENT, 67, 2),
    ]);
  }

  void test_privateMixin() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal mixin _One {}
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 49, 4),
    ]);
  }

  void test_privateTopLevelFunction() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal void _f() {}
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 48, 2),
    ]);
  }

  void test_privateTopLevelVariable() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal int _i = 1;
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 47, 6),
      error(HintCode.UNUSED_ELEMENT, 47, 2),
    ]);
  }

  void test_privateTypedef() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal typedef _T = void Function();
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 51, 2),
    ]);
  }

  void test_publicMethod_privateClass() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
class _C {
  @internal void f() {}
}
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.UNUSED_ELEMENT, 39, 2),
    ]);
  }

  void test_publicMethod_privateClass_static() async {
    newFile('$testPackageLibPath/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
class _C {
  @internal static void f() {}
}
''');
    await resolveFile2('$testPackageLibPath/src/foo.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.UNUSED_ELEMENT, 39, 2),
      error(HintCode.UNUSED_ELEMENT, 68, 1),
    ]);
  }
}
