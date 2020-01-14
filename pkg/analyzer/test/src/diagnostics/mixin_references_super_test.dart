// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinReferencesSuperTest);
  });
}

@reflectiveTest
class MixinReferencesSuperTest extends DriverResolutionTest {
  test_mixin_references_super() async {
    await assertErrorsInCode(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}
''', [
      error(CompileTimeErrorCode.MIXIN_REFERENCES_SUPER, 74, 1),
    ]);
  }

  test_mixin_unconstrained_references_super() async {
    await assertNoErrorsInCode(r'''
mixin A {
  toString() => super.toString();
}
class B extends Object with A {}
''');
  }
}
