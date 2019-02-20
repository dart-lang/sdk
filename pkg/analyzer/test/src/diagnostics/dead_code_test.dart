// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UncheckedUseOfNullableValueTest);
  });
}

@reflectiveTest
class UncheckedUseOfNullableValueTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.non_nullable];

  @override
  bool get enableNewAnalysisDriver => true;

  test_nullCoalesce_nonNullable() async {
    await assertErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int x;
  x ?? 1;
}
''', [HintCode.DEAD_CODE]);
  }

  test_nullCoalesce_nullable() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int? x;
  x ?? 1;
}
''');
  }

  test_nullCoalesceAssign_nonNullable() async {
    await assertErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int x;
  x ??= 1;
}
''', [HintCode.DEAD_CODE]);
  }

  test_nullCoalesceAssign_nullable() async {
    await assertNoErrorsInCode(r'''
@pragma('analyzer:non-nullable')
library foo;

m() {
  int? x;
  x ??= 1;
}
''');
  }
}
