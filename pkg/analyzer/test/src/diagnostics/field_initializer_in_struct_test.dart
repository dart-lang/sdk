// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerInStructTest);
  });
}

@reflectiveTest
class FieldInitializerInStructTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_superInitializer() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';
class C extends Struct {
  @Int32() int f;
  C() : super();
}
''');
  }
}
