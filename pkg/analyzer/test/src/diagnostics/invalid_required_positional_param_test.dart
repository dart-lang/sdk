// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidRequiredPositionalParamTest);
  });
}

@reflectiveTest
class InvalidRequiredPositionalParamTest extends DriverResolutionTest
    with PackageMixin {
  @override
  void setUp() {
    super.setUp();
    addMetaPackage();
  }

  test_requiredPositionalParameter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m(@required a) => null;
''', [
      error(HintCode.INVALID_REQUIRED_POSITIONAL_PARAM, 36, 11),
    ]);
  }

  test_requiredPositionalParameter_asSecond() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m(a, @required b) => null;
''', [
      error(HintCode.INVALID_REQUIRED_POSITIONAL_PARAM, 39, 11),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
m1() => null;
m2(a) => null;
m3(a, b) => null;
''');
  }
}
