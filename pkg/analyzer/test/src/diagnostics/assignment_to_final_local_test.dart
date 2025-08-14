// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalLocalTest);
  });
}

@reflectiveTest
class AssignmentToFinalLocalTest extends PubPackageResolutionTest {
  test_localVariable() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  x = 1;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 23, 1),
      ],
    );
  }

  test_localVariable_forEach() async {
    await assertErrorsInCode(
      '''
f() {
  final i;
  for (i in [1, 2, 3]) {
    print(i);
  }
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 24, 1)],
    );
  }

  test_localVariable_inForEach() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  for (x in <int>[1, 2]) {
    print(x);
  }
}''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 28, 1)],
    );
  }

  test_localVariable_plusEq() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  x += 1;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 23, 1),
      ],
    );
  }

  test_parameter() async {
    await assertErrorsInCode(
      '''
f(final x) {
  x = 1;
}''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 15, 1)],
    );
  }

  /// See `10.6.1 Generative Constructors`.
  ///
  /// Each initializing formal in the formal parameter list introduces a final
  /// local variable into the formal parameter initializer scope, but not into
  /// the formal parameter scope; every other formal parameter introduces a
  /// local variable into both the formal parameter scope and the formal
  /// parameter initializer scope.
  ///
  /// Note that it says 'final local variable', regardless whether the instance
  /// variable is final.
  test_parameter_fieldFormal() async {
    await assertErrorsInCode(
      '''
class A {
  int x;
  final Object y;
  A(this.x) : y = (() {
    x = 0;
  });
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 65, 1)],
    );
  }

  test_parameter_superFormal() async {
    await assertErrorsInCode(
      '''
class A {
  A(int a);
}
class B extends A {
  var x;
  B(super.a) : x = (() { a = 0; });
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 78, 1)],
    );
  }

  test_patternVariable_final() async {
    await assertErrorsInCode(
      '''
void f() {
  final (a) = 0;
  a = 1;
  a;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 30, 1)],
    );
  }

  test_postfixMinusMinus() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  x--;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 23, 1),
      ],
    );
  }

  test_postfixPlusPlus() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  x++;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 23, 1),
      ],
    );
  }

  test_prefixMinusMinus() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  --x;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 25, 1),
      ],
    );
  }

  test_prefixPlusPlus() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  ++x;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 25, 1),
      ],
    );
  }

  test_suffixMinusMinus() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  x--;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 23, 1),
      ],
    );
  }

  test_suffixPlusPlus() async {
    await assertErrorsInCode(
      '''
f() {
  final x = 0;
  x++;
}''',
      [
        error(WarningCode.unusedLocalVariable, 14, 1),
        error(CompileTimeErrorCode.assignmentToFinalLocal, 23, 1),
      ],
    );
  }
}
