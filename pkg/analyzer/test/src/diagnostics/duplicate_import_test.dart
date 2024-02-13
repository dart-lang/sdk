// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateExportTest);
    defineReflectiveTests(DuplicateImportTest);
  });
}

@reflectiveTest
class DuplicateExportTest extends PubPackageResolutionTest {
  test_duplicateExport() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode('''
export 'lib1.dart';
export 'lib1.dart';
''', [
      error(WarningCode.DUPLICATE_EXPORT, 27, 11),
    ]);
  }

  test_duplicateExport_differentShow() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertNoErrorsInCode('''
export 'lib1.dart' show A;
export 'lib1.dart' show B;
''');
  }

  test_duplicateExport_sameShow() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode('''
export 'lib1.dart' show A;
export 'lib1.dart' show A;
''', [
      error(WarningCode.DUPLICATE_EXPORT, 34, 11),
    ]);
  }
}

@reflectiveTest
class DuplicateImportTest extends PubPackageResolutionTest {
  test_duplicateImport_absolute_absolute() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:test/a.dart';
import 'package:test/a.dart';

final a = A();
''', [
      error(WarningCode.DUPLICATE_IMPORT, 37, 21),
    ]);
  }

  test_duplicateImport_relative_absolute() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
import 'package:test/a.dart';

final a = A();
''', [
      error(WarningCode.DUPLICATE_IMPORT, 24, 21),
    ]);
  }

  test_duplicateImport_relative_relative() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
import 'a.dart';

final a = A();
''', [
      error(WarningCode.DUPLICATE_IMPORT, 24, 8),
    ]);
  }

  test_importsHaveIdenticalShowHide() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
library lib1;
class A {}
class B {}
''');

    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a = M.A();
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.DUPLICATE_IMPORT, 57, 11),
    ]);
  }

  test_oneImportHasHide() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
library lib1;
class A {}
class B {}''');

    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
B b = B();
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_oneImportHasShow() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
library lib1;
class A {}
class B {}
''');

    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
library L;
import 'lib1.dart';
import 'lib1.dart' show A; // ignore: unnecessary_import
A a = A();
B b = B();
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_oneImportUsesAs() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
library lib1;
class A {}''');

    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
A a = A();
one.A a2 = one.A();
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_twoDuplicateImports() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
library lib1;
class A {}''');

    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a = A();
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.DUPLICATE_IMPORT, 38, 11),
      error(WarningCode.DUPLICATE_IMPORT, 58, 11),
    ]);
  }
}
