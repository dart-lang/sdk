// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidModifierOnSetterTest);
  });
}

@reflectiveTest
class InvalidModifierOnSetterTest extends PubPackageResolutionTest {
  test_member_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(v) async {}
//         ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
}
''');
  }

  test_member_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(v) async* {}
//         ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
}
''');
  }

  test_member_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(v) sync* {}
//         ^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
}
''');
  }

  test_topLevel_async() async {
    await resolveTestCodeWithDiagnostics(r'''
set x(v) async {}
//       ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
''');
  }

  test_topLevel_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
set x(v) async* {}
//       ^^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
''');
  }

  test_topLevel_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
set x(v) sync* {}
//       ^^^^
// [diag.invalidModifierOnSetter] Setters can't use 'async', 'async*', or 'sync*'.
''');
  }
}
