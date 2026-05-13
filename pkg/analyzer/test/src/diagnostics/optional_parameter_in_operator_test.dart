// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionalParameterInOperatorTest);
  });
}

@reflectiveTest
class OptionalParameterInOperatorTest extends PubPackageResolutionTest {
  test_optionalNamed() async {
    await assertErrorsInCode(
      r'''
class A {
  int operator +({Object? other}) => 0;
}
''',
      [error(diag.optionalParameterInOperator, 28, 13)],
    );
  }

  test_optionalPositional() async {
    await assertErrorsInCode(
      r'''
class A {
  int operator +([Object? other]) => 0;
}
''',
      [error(diag.optionalParameterInOperator, 28, 13)],
    );
  }

  test_requiredNamed() async {
    await assertErrorsInCode(
      r'''
class A {
  int operator +({required Object other}) => 0;
}
''',
      [error(diag.optionalParameterInOperator, 28, 21)],
    );
  }

  test_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator +(Object other) => 0;
}
''');
  }
}
