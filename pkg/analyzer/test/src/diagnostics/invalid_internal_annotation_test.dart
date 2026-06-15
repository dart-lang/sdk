// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidInternalAnnotationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidInternalAnnotationTest extends PubPackageResolutionTest {
  File get testPackageLibSrcFile => getFile('$testPackageLibPath/src/foo.dart');

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
    var file = getFile('$testPackageLibPath/foo.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:meta/meta.dart';
@internal class One {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
''');
  }

  void test_annotationInLib_onLibrary() async {
    var file = getFile('$testPackageLibPath/foo.dart');
    await resolveFileWithDiagnostics(file, r'''
@internal
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
library foo;
import 'package:meta/meta.dart';
''');
  }

  void test_annotationInLibSrc() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
  }

  void test_annotationInLibSrcSubdirectory() async {
    var file = getFile('$testPackageLibPath/src/foo/foo.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
  }

  void test_annotationInLibSubdirectory() async {
    var file = getFile('$testPackageLibPath/foo/foo.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:meta/meta.dart';
@internal class One {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
''');
  }

  void test_annotationInTest() async {
    var file = getFile('$testPackageRootPath/test/foo_test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
  }

  void test_annotationInTest_extensionType() async {
    var file = getFile('$testPackageRootPath/test/foo_test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:meta/meta.dart';
@internal extension type E(int i) {}
''');
  }

  void test_privateClass() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal class _One {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
//              ^^^^
// [diag.unusedElement] The declaration '_One' isn't referenced.
''');
  }

  void test_privateConstructor() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class C {
  @internal C._f();
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
}
''');
  }

  void test_privateEnum() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal enum _E {one}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
//             ^^
// [diag.unusedElement] The declaration '_E' isn't referenced.
//                 ^^^
// [diag.unusedField] The value of the field 'one' isn't used.
''');
  }

  void test_privateEnumValue() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
enum E {@internal _one}
//       ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//                ^^^^
// [diag.unusedField] The value of the field '_one' isn't used.
''');
  }

  void test_privateExtension() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal extension _One on String {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
''');
  }

  void test_privateExtension_unnamed() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal extension on String {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
''');
  }

  void test_privateExtensionType() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal extension type _E(int i) {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
//                       ^^
// [diag.unusedElement] The declaration '_E' isn't referenced.
''');
  }

  void test_privateField_instance() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class C {
  @internal int _i = 0;
//              ^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//              ^^
// [diag.unusedField] The value of the field '_i' isn't used.
}
''');
  }

  void test_privateField_static() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class C {
  @internal static int _i = 0;
//                     ^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//                     ^^
// [diag.unusedField] The value of the field '_i' isn't used.
}
''');
  }

  void test_privateGetter() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class C {
  @internal int get _i => 0;
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//                  ^^
// [diag.unusedElement] The declaration '_i' isn't referenced.
}
''');
  }

  void test_privateMethod_instance() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class C {
  @internal void _f() {}
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//               ^^
// [diag.unusedElement] The declaration '_f' isn't referenced.
}
''');
  }

  void test_privateMethod_static() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class C {
  @internal static void _f() {}
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//                      ^^
// [diag.unusedElement] The declaration '_f' isn't referenced.
}
''');
  }

  void test_privateMixin() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal mixin _One {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
//              ^^^^
// [diag.unusedElement] The declaration '_One' isn't referenced.
''');
  }

  void test_privateTopLevelFunction() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal void _f() {}
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
//             ^^
// [diag.unusedElement] The declaration '_f' isn't referenced.
''');
  }

  void test_privateTopLevelVariable() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal int _i = 1;
//            ^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
//            ^^
// [diag.unusedElement] The declaration '_i' isn't referenced.
''');
  }

  void test_privateTypedef() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
@internal typedef _T = void Function();
// [diag.invalidInternalAnnotation][column 2][length 8] Only public elements in a package's private API can be annotated as being internal.
//                ^^
// [diag.unusedElement] The declaration '_T' isn't referenced.
''');
  }

  void test_publicConstructor_named_privateClass() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class _C {
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
  @internal _C.named();
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
}
''');
  }

  void test_publicConstructor_primary_privateClass() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class _C() {
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
  @internal
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
  this;
}
''');
  }

  void test_publicConstructor_unnamed_privateClass() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class _C {
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
  @internal _C();
// ^^^^^^^^
// [diag.invalidInternalAnnotation] Only public elements in a package's private API can be annotated as being internal.
}
''');
  }

  void test_publicMethod_privateClass() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class _C {
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
  @internal void f() {}
}
''');
  }

  void test_publicMethod_privateClass_static() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
class _C {
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
  @internal static void f() {}
//                      ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
}
''');
  }

  void test_publicMethod_privateExtensionType() async {
    await resolveFileWithDiagnostics(testPackageLibSrcFile, r'''
import 'package:meta/meta.dart';
extension type _E(int i) {
//             ^^
// [diag.unusedElement] The declaration '_E' isn't referenced.
  @internal void f() {}
}
''');
  }
}
