// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_error_resolver_test.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest_Driver);
    defineReflectiveTests(NonConstantValueInInitializer);
  });
}

@reflectiveTest
class NonConstantValueInInitializer extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.constant_update_2018];

  @override
  bool get enableNewAnalysisDriver => true;

  test_intLiteralInDoubleContext_const_exact() async {
    Source source = addSource(r'''
const double x = 0;
class C {
  const C(double y) : assert(y is double), assert(x is double);
}
@C(0)
@C(-0)
@C(0x0)
@C(-0x0)
void main() {
  const C(0);
  const C(-0);
  const C(0x0);
  const C(-0x0);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_isCheckInConstAssert() async {
    Source source = addSource(r'''
class C {
  const C() : assert(1 is int);
}

void main() {
  const C();
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }
}

@reflectiveTest
class NonErrorResolverTest_Driver extends NonErrorResolverTestBase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  @failingTest
  test_null_callOperator() {
    return super.test_null_callOperator();
  }
}
