// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixShadowedByLocalDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixShadowedByLocalDeclarationTest extends PubPackageResolutionTest {
  test_function_return_type_not_shadowed_by_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as a;
a.Future? f(int a) {
  return null;
}
''');
  }

  test_local_variable_type_inside_function_with_shadowing_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as a;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
f(int a) {
  a.Future? x = null;
//^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'a' can't be used here because it's shadowed by a local declaration.
  return x;
}
''');
  }

  test_local_variable_type_inside_function_with_shadowing_variable_after() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as a;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
f() {
  a.Future? x = null;
//^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'a' can't be used here because it's shadowed by a local declaration.
// [diag.referencedBeforeDeclaration][context 1] Local variable 'a' can't be referenced before it is declared.
  int a = 0;
//    ^
// [context 1] The declaration of 'a' is here.
  return [x, a];
}
''');
  }

  test_local_variable_type_inside_function_with_shadowing_variable_before() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as a;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
f() {
  int a = 0;
  a.Future? x = null;
//^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'a' can't be used here because it's shadowed by a local declaration.
  return [x, a];
}
''');
  }

  test_shadowedBy_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;
class A {
  core.List foo = 0;
//^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'core' can't be used here because it's shadowed by a local declaration.
  get core => 0;
}
''');
  }

  test_shadowedBy_class_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;
class A {
  core.List foo = 0;
//^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'core' can't be used here because it's shadowed by a local declaration.
  void core() {}
}
''');
  }

  test_shadowedBy_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;
class A {
  core.List foo = 0;
//^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'core' can't be used here because it's shadowed by a local declaration.
  set core(_) {}
}
''');
  }
}
