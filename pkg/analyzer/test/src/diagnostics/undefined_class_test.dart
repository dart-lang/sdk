// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedClassTest extends PubPackageResolutionTest {
  test_const() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  return const A();
//             ^
// [diag.constWithNonType] The name 'A' isn't a class.
}
''');
  }

  test_dynamic_coreWithPrefix() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:core' as core;

dynamic x;
// [diag.undefinedClass][column 1][length 7] Undefined class 'dynamic'.
''');
  }

  test_ignore_libraryImport_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

p.A a;
''');
  }

  test_ignore_libraryImport_show_it() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show A;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

A a;
''');
  }

  test_ignore_libraryImport_show_other() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show B;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

A a;
// [diag.undefinedClass][column 1][length 1] Undefined class 'A'.
''');
  }

  test_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';

_$A a;
// [diag.undefinedClass][column 1][length 3] Undefined class '_$A'.
''');
  }

  test_ignore_part_notExist_uriGenerated2_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.template.dart';
//   ^^^^^^^^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.template.dart'.

_$A a;
''');
  }

  test_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';
//   ^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.g.dart'.

_$A a;
''');
  }

  test_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';
//   ^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.g.dart'.

A a;
// [diag.undefinedClass][column 1][length 1] Undefined class 'A'.
''');
  }

  test_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.

_$A a;
// [diag.undefinedClass][column 1][length 3] Undefined class '_$A'.
''');
  }

  test_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.

A a;
// [diag.undefinedClass][column 1][length 1] Undefined class 'A'.
''');
  }

  test_import_exists_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

p.A a;
// [diag.undefinedClass][column 1][length 3] Undefined class 'A'.
''');
  }

  test_instanceCreation() async {
    await resolveTestCodeWithDiagnostics('''
f() { new C(); }
//        ^
// [diag.newWithNonType] The name 'C' isn't a class.
''');
  }

  test_Record() async {
    await resolveTestCodeWithDiagnostics('''
void f(Record r) {}
''');
  }

  test_Record_language219() async {
    await resolveTestCodeWithDiagnostics('''
// @dart = 2.19
void f(Record r) {}
//     ^^^^^^
// [diag.undefinedClass] Undefined class 'Record'.
''');
  }

  test_Record_language219_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
export 'dart:core' show Record;
''');

    await resolveTestCodeWithDiagnostics('''
// @dart = 2.19
import 'a.dart';
void f(Record r) {}
''');
  }

  test_variableDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
f() { C c; }
//    ^
// [diag.undefinedClass] Undefined class 'C'.
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
''');
  }
}
