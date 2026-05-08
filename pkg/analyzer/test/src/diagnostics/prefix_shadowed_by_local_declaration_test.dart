// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixShadowedByLocalDeclarationTest);
  });
}

@reflectiveTest
class PrefixShadowedByLocalDeclarationTest extends PubPackageResolutionTest {
  test_function_return_type_not_shadowed_by_parameter() async {
    await assertNoErrorsInCode('''
import 'dart:async' as a;
a.Future? f(int a) {
  return null;
}
''');
  }

  test_local_variable_type_inside_function_with_shadowing_parameter() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as a;
f(int a) {
  a.Future? x = null;
  return x;
}
''',
      [
        error(diag.unusedImport, 7, 12),
        error(diag.prefixShadowedByLocalDeclaration, 39, 1),
      ],
    );
  }

  test_local_variable_type_inside_function_with_shadowing_variable_after() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as a;
f() {
  a.Future? x = null;
  int a = 0;
  return [x, a];
}
''',
      [
        error(diag.unusedImport, 7, 12),
        error(
          diag.referencedBeforeDeclaration,
          34,
          1,
          contextMessages: [message(testFile, 60, 1)],
        ),
        error(diag.prefixShadowedByLocalDeclaration, 34, 1),
      ],
    );
  }

  test_local_variable_type_inside_function_with_shadowing_variable_before() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as a;
f() {
  int a = 0;
  a.Future? x = null;
  return [x, a];
}
''',
      [
        error(diag.unusedImport, 7, 12),
        error(diag.prefixShadowedByLocalDeclaration, 47, 1),
      ],
    );
  }

  test_shadowedBy_class_getter() async {
    await assertErrorsInCode(
      '''
import 'dart:core' as core;
class A {
  core.List foo = 0;
  get core => 0;
}
''',
      [error(diag.prefixShadowedByLocalDeclaration, 40, 4)],
    );
  }

  test_shadowedBy_class_method() async {
    await assertErrorsInCode(
      '''
import 'dart:core' as core;
class A {
  core.List foo = 0;
  void core() {}
}
''',
      [error(diag.prefixShadowedByLocalDeclaration, 40, 4)],
    );
  }

  test_shadowedBy_class_setter() async {
    await assertErrorsInCode(
      '''
import 'dart:core' as core;
class A {
  core.List foo = 0;
  set core(_) {}
}
''',
      [error(diag.prefixShadowedByLocalDeclaration, 40, 4)],
    );
  }
}
