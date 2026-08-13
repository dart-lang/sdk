// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOfNonClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinOfNonClassTest extends PubPackageResolutionTest {
  test_class_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { ONE }
class A extends Object with E {}
//                          ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_class_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
class B with A {}
//           ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_class_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 7;
class B extends Object with A {}
//                          ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_class_typeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
int B = 7;
class C = A with B;
//               ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_class_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class C with M {}
//           ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_enum_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E1 { v }
enum E2 with E1 { v }
//           ^^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_enum_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
enum E with A { v }
//          ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_enum_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 7;
enum E with A {
//          ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
  v
}
''');
  }

  test_enum_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E with M {
//          ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
  v
}
''');
  }

  test_Never() async {
    await resolveTestCodeWithDiagnostics('''
class A with Never {}
//           ^^^^^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_undefined_ignore_import_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class C with p.M {}
''');
  }

  test_undefined_ignore_import_show_it() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show M;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class C with M {}
''');
  }

  test_undefined_ignore_import_show_other() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show N;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class C with M {}
//           ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_undefined_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';

class C with _$M {}
//           ^^^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';
//   ^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.g.dart'.

class C with _$M {}
''');
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';
//   ^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.g.dart'.

class C with M {}
//           ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.

class C with _$M {}
//           ^^^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.

class C with M {}
//           ^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }

  test_undefined_import_exists_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

class C with p.M {}
//           ^^^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
''');
  }
}
