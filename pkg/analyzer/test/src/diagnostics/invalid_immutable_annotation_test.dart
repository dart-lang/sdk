// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidImmutableAnnotationTest);
  });
}

@reflectiveTest
class InvalidImmutableAnnotationTest extends DriverResolutionTest
    with PackageMixin {
  test_method() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @immutable
  void m() {}
}
''', [HintCode.INVALID_IMMUTABLE_ANNOTATION]);
  }

  test_class() async {
    addMetaPackage();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
''');
  }
}
