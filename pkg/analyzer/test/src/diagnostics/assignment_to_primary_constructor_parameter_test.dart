// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToPrimaryConstructorParameterTest);
  });
}

@reflectiveTest
class AssignmentToPrimaryConstructorParameterTest
    extends PubPackageResolutionTest {
  test_fieldInitializer_late() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  late int y = x = 0;
}
''',
      [error(diag.undefinedIdentifier, 32, 1)],
    );
  }

  test_fieldInitializer_notLate() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y = x = 0;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 27, 1)],
    );
  }

  test_fieldInitializer_notLate_closure() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  var f = () {
    x = 0;
  };
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 36, 1)],
    );
  }

  test_fieldInitializer_notLate_nullAware() async {
    await assertErrorsInCode(
      '''
class A(int? x) {
  int y = x ??= 0;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 28, 1)],
    );
  }

  test_fieldInitializer_notLate_plusEq() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y = x += 1;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 27, 1)],
    );
  }

  test_fieldInitializer_notLate_postfix() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y = x++;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 27, 1)],
    );
  }

  test_fieldInitializer_notLate_prefix() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y = ++x;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 29, 1)],
    );
  }

  test_primaryConstructor_body() async {
    await assertNoErrorsInCode('''
class A(int x) {
  this {
    x = 0;
  }
}
''');
  }

  test_primaryConstructor_initializer() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y;
  this : y = x = 0;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 39, 1)],
    );
  }

  test_primaryConstructor_initializer_closure() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  var f;
  this : f = (() {
    x = 0;
  });
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 49, 1)],
    );
  }

  test_primaryConstructor_initializer_nullAware() async {
    await assertErrorsInCode(
      '''
class A(int? x) {
  int y;
  this : y = x ??= 0;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 40, 1)],
    );
  }

  test_primaryConstructor_initializer_plusEq() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y;
  this : y = x += 1;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 39, 1)],
    );
  }

  test_primaryConstructor_initializer_postfix() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y;
  this : y = x++;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 39, 1)],
    );
  }

  test_primaryConstructor_initializer_prefix() async {
    await assertErrorsInCode(
      '''
class A(int x) {
  int y;
  this : y = ++x;
}
''',
      [error(diag.assignmentToPrimaryConstructorParameter, 41, 1)],
    );
  }
}
