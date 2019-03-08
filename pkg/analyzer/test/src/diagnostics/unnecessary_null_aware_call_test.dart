// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecesaryNullAwareCallTest);
  });
}

@reflectiveTest
class UnnecesaryNullAwareCallTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.non_nullable];

  @override
  bool get enableNewAnalysisDriver => true;

  test_getter_parenthesized_nonNull() async {
    await assertErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int x;
  (x)?.isEven;
}
''', [HintCode.UNNECESSARY_NULL_AWARE_CALL]);
  }

  test_getter_parenthesized_nullable() async {
    await assertNoErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int? x;
  (x)?.isEven;
}
''');
  }

  test_getter_simple_nonNull() async {
    await assertErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int x;
  x?.isEven;
}
''', [HintCode.UNNECESSARY_NULL_AWARE_CALL]);
  }

  test_getter_simple_nullable() async {
    await assertNoErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int? x;
  x?.isEven;
}
''');
  }

  test_method_parenthesized_nonNull() async {
    await assertErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int x;
  (x)?.round();
}
''', [HintCode.UNNECESSARY_NULL_AWARE_CALL]);
  }

  test_method_parenthesized_nullable() async {
    await assertNoErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int? x;
  (x)?.round();
}
''');
  }

  test_method_simple_nonNull() async {
    await assertErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int x;
  x?.round();
}
''', [HintCode.UNNECESSARY_NULL_AWARE_CALL]);
  }

  test_method_simple_nullable() async {
    await assertNoErrorsInCode('''
@pragma('analyzer:non-nullable')
library foo;

f() {
  int? x;
  x?.round();
}
''');
  }
}
