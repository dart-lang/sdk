// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalNoSetterTest);
  });
}

@reflectiveTest
class AssignmentToFinalNoSetterTest extends PubPackageResolutionTest {
  test_prefixedIdentifier_class_instanceGetter() async {
    await assertErrorsInCode(
      '''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''',
      [
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 49, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 60, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 74, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 81, 1),
      ],
    );
  }

  test_propertyAccess_class_instanceGetter() async {
    await assertErrorsInCode(
      '''
class A {
  int get x => 0;
}

void f(A a) {
  (a).x = 0;
  (a).x += 0;
  ++(a).x;
  (a).x++;
}
''',
      [
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 51, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 64, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 80, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 89, 1),
      ],
    );
  }

  test_propertyAccess_extension_instanceGetter() async {
    await assertErrorsInCode(
      '''
extension E on int {
  int get x => 0;
}

void f() {
  0.x = 0;
  0.x += 0;
  ++0.x;
  0.x++;
}
''',
      [
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 57, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 68, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 82, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 89, 1),
      ],
    );
  }

  test_simpleIdentifier_class_instanceGetter() async {
    await assertErrorsInCode(
      '''
class A {
  int get x => 0;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''',
      [
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 46, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 57, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 71, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 78, 1),
      ],
    );
  }

  test_simpleIdentifier_class_staticGetter() async {
    await assertErrorsInCode(
      '''
class A {
  static int get x => 0;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''',
      [
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 53, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 64, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 78, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 85, 1),
      ],
    );
  }
}
