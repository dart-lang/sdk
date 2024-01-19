// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractClassMemberTest);
  });
}

@reflectiveTest
class AbstractClassMemberTest extends PubPackageResolutionTest {
  test_abstract_field_dynamic() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract dynamic x;
}
''');
  }

  test_abstract_field_untyped() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract var x;
}
''');
  }

  test_abstract_field_untyped_covariant() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract covariant var x;
}
''');
  }
}
