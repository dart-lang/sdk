// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalLocalTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToFinalLocalTest extends PubPackageResolutionTest {
  test_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_localVariable_forEach() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final i;
  for (i in [1, 2, 3]) {
//     ^
// [diag.assignmentToFinalLocal] The final variable 'i' can only be set once.
    print(i);
  }
}
''');
  }

  test_localVariable_inForEach() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
  for (x in <int>[1, 2]) {
//     ^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
    print(x);
  }
}''');
  }

  test_localVariable_plusEq() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x += 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
f(final x) {
  x = 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  final Object y;
  A(this.x) : y = (() {
    x = 0;
//  ^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
  });
}
''');
  }

  test_parameter_superFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a);
}
class B extends A {
  var x;
  B(super.a) : x = (() { a = 0; });
//                       ^
// [diag.assignmentToFinalLocal] The final variable 'a' can only be set once.
}
''');
  }

  test_patternVariable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final (a) = 0;
  a = 1;
//^
// [diag.assignmentToFinalLocal] The final variable 'a' can only be set once.
  a;
}
''');
  }

  test_postfixMinusMinus() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x--;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_postfixPlusPlus() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x++;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_prefixMinusMinus() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  --x;
//  ^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_prefixPlusPlus() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  ++x;
//  ^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_suffixMinusMinus() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x--;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }

  test_suffixPlusPlus() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  final x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x++;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}''');
  }
}
