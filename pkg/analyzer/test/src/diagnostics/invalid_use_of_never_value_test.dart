// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNeverTest);
    defineReflectiveTests(InvalidUseOfNeverTest_Legacy);
  });
}

@reflectiveTest
class InvalidUseOfNeverTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_local_invoked() async {
    await assertErrorsInCode(r'''
void main(Never x) {
  x();
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 23, 1),
    ]);
  }

  @failingTest
  test_local_neverQuestion_getter_hashCode() async {
    // reports undefined getter
    await assertNoErrorsInCode(r'''
void main(Never? neverQ) {
  neverQ.hashCode;
}
''');
  }

  @failingTest
  test_local_neverQuestion_getter_toString() async {
    // reports undefined getter
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').toString;
}
''');
  }

  test_local_neverQuestion_methodCall_toString() async {
    await assertNoErrorsInCode(r'''
void main(Never? neverQ) {
  neverQ.toString();
}
''');
  }

  @failingTest
  test_local_neverQuestion_operator_equals() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main(Never? neverQ) {
  neverQ == 0;
}
''');
  }

  @failingTest
  test_local_operator_plusPlus_prefix() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void main(Never x) {
  ++x;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @failingTest
  test_local_operator_plusPlus_suffix() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void main(Never x) {
  x++;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  test_member_invoked() async {
    await assertErrorsInCode(r'''
class C {
  Never get x => throw '';
}

void main() {
  C c = C();
  c.x();
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 71, 1),
    ]);
  }

  @failingTest
  test_throw_getter_foo() async {
    // Reports undefined getter.
    await assertErrorsInCode(r'''
void main() {
  (throw '').foo;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @failingTest
  test_throw_getter_hashCode() async {
    // Reports undefined getter.
    await assertErrorsInCode(r'''
void main() {
  (throw '').hashCode;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  @failingTest
  test_throw_getter_toString() async {
    // Reports undefined getter (it seems to get confused by the tear-off).
    await assertErrorsInCode(r'''
void main() {
  (throw '').toString;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  test_throw_invoked() async {
    await assertErrorsInCode(r'''
void main() {
  (throw '')();
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 16, 10),
    ]);
  }

  test_throw_methodCall_foo() async {
    await assertErrorsInCode(r'''
void main() {
  (throw '').foo();
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 16, 10),
    ]);
  }

  test_throw_methodCall_toString() async {
    await assertErrorsInCode(r'''
void main() {
  (throw '').toString();
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 16, 10),
    ]);
  }

  @failingTest
  test_throw_operator_equals() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main() {
  (throw '') == 0;
}
''');
  }

  @failingTest
  test_throw_operator_plus_lhs() async {
    // Currently reports "no such operator"
    await assertErrorsInCode(r'''
void main() {
  (throw '') + 0;
}
''', [
      error(StaticWarningCode.INVALID_USE_OF_NEVER_VALUE, 70, 1),
    ]);
  }

  test_throw_operator_plus_rhs() async {
    await assertNoErrorsInCode(r'''
void main() {
  0 + (throw '');
}
''');
  }

  test_throw_operator_ternary_falseBranch() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  c ? 0 : (throw '');
}
''');
  }

  test_throw_operator_ternary_trueBranch() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  c ? (throw '') : 0;
}
''');
  }

  test_throw_param() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  f(throw '');
}
''');
  }
}

/// Construct Never* by using throw expressions and assert no errors.
@reflectiveTest
class InvalidUseOfNeverTest_Legacy extends DriverResolutionTest {
  @failingTest
  test_throw_getter_hashCode() async {
    // Reports undefined getter.
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').hashCode;
}
''');
  }

  @failingTest
  test_throw_getter_toString() async {
    // Reports undefined getter (it seems to get confused by the tear-off).
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').toString;
}
''');
  }

  test_throw_methodCall_toString() async {
    await assertNoErrorsInCode(r'''
void main() {
  (throw '').toString();
}
''');
  }

  @failingTest
  test_throw_operator_equals() async {
    // We report this as an error even though CFE does not.
    await assertNoErrorsInCode(r'''
void main() {
  (throw '') == 0;
}
''');
  }
}
