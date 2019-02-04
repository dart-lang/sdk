// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedGetterTest);
  });
}

@reflectiveTest
class UndefinedGetterTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_promotedTypeParameter_regress35305() async {
    await assertErrorsInCode(r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_GETTER], verify: false);
  }
}
