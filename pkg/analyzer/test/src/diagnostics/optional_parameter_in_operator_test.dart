// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionalParameterInOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class OptionalParameterInOperatorTest extends PubPackageResolutionTest {
  test_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +({Object? other}) => 0;
//                ^^^^^^^^^^^^^
// [diag.optionalParameterInOperator] Optional parameters aren't allowed when defining an operator.
}
''');
  }

  test_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +([Object? other]) => 0;
//                ^^^^^^^^^^^^^
// [diag.optionalParameterInOperator] Optional parameters aren't allowed when defining an operator.
}
''');
  }

  test_requiredNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +({required Object other}) => 0;
//                ^^^^^^^^^^^^^^^^^^^^^
// [diag.optionalParameterInOperator] Optional parameters aren't allowed when defining an operator.
}
''');
  }

  test_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +(Object other) => 0;
}
''');
  }
}
