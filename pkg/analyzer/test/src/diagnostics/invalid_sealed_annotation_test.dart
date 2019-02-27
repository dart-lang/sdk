// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidLiteralAnnotationTest);
  });
}

@reflectiveTest
class InvalidLiteralAnnotationTest extends DriverResolutionTest
    with PackageMixin {
  setUp() {
    super.setUp();
    addMetaPackage();
  }

  test_class() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@sealed class A {}
''');
  }

  test_mixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@sealed mixin M {}
''', [HintCode.INVALID_SEALED_ANNOTATION]);
  }

  test_mixinApplication() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

abstract class A {}

abstract class B {}

@sealed abstract class M = A with B;
''');
  }

  test_nonClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@sealed m({a = 1}) => null;
''', [HintCode.INVALID_SEALED_ANNOTATION]);
  }
}
