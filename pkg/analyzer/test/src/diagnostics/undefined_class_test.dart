// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedClassTest);
  });
}

@reflectiveTest
class UndefinedClassTest extends PubPackageResolutionTest {
  test_const() async {
    await assertErrorsInCode(
      r'''
f() {
  return const A();
}
''',
      [error(CompileTimeErrorCode.constWithNonType, 21, 1)],
    );
  }

  test_dynamic_coreWithPrefix() async {
    await assertErrorsInCode(
      '''
import 'dart:core' as core;

dynamic x;
''',
      [error(CompileTimeErrorCode.undefinedClass, 29, 7)],
    );
  }

  test_ignore_libraryImport_prefix() async {
    await assertErrorsInCode(
      r'''
import 'a.dart' as p;

p.A a;
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 8)],
    );
  }

  test_ignore_libraryImport_show_it() async {
    await assertErrorsInCode(
      r'''
import 'a.dart' show A;

A a;
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 8)],
    );
  }

  test_ignore_libraryImport_show_other() async {
    await assertErrorsInCode(
      r'''
import 'a.dart' show B;

A a;
''',
      [
        error(CompileTimeErrorCode.uriDoesNotExist, 7, 8),
        error(CompileTimeErrorCode.undefinedClass, 25, 1),
      ],
    );
  }

  test_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(
      r'''
part 'a.g.dart';

_$A a;
''',
      [error(CompileTimeErrorCode.undefinedClass, 18, 3)],
    );
  }

  test_ignore_part_notExist_uriGenerated2_nameIgnorable() async {
    await assertErrorsInCode(
      r'''
part 'a.template.dart';

_$A a;
''',
      [error(CompileTimeErrorCode.uriHasNotBeenGenerated, 5, 17)],
    );
  }

  test_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await assertErrorsInCode(
      r'''
part 'a.g.dart';

_$A a;
''',
      [error(CompileTimeErrorCode.uriHasNotBeenGenerated, 5, 10)],
    );
  }

  test_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(
      r'''
part 'a.g.dart';

A a;
''',
      [
        error(CompileTimeErrorCode.uriHasNotBeenGenerated, 5, 10),
        error(CompileTimeErrorCode.undefinedClass, 18, 1),
      ],
    );
  }

  test_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await assertErrorsInCode(
      r'''
part 'a.dart';

_$A a;
''',
      [
        error(CompileTimeErrorCode.uriDoesNotExist, 5, 8),
        error(CompileTimeErrorCode.undefinedClass, 16, 3),
      ],
    );
  }

  test_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(
      r'''
part 'a.dart';

A a;
''',
      [
        error(CompileTimeErrorCode.uriDoesNotExist, 5, 8),
        error(CompileTimeErrorCode.undefinedClass, 16, 1),
      ],
    );
  }

  test_import_exists_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as p;

p.A a;
''',
      [error(CompileTimeErrorCode.undefinedClass, 26, 3)],
    );
  }

  test_instanceCreation() async {
    await assertErrorsInCode(
      '''
f() { new C(); }
''',
      [error(CompileTimeErrorCode.newWithNonType, 10, 1)],
    );
  }

  test_Record() async {
    await assertNoErrorsInCode('''
void f(Record r) {}
''');
  }

  test_Record_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
void f(Record r) {}
''',
      [error(CompileTimeErrorCode.undefinedClass, 23, 6)],
    );
  }

  test_Record_language219_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
export 'dart:core' show Record;
''');

    await assertNoErrorsInCode('''
// @dart = 2.19
import 'a.dart';
void f(Record r) {}
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(
      '''
f() { C c; }
''',
      [
        error(CompileTimeErrorCode.undefinedClass, 6, 1),
        error(WarningCode.unusedLocalVariable, 8, 1),
      ],
    );
  }
}
