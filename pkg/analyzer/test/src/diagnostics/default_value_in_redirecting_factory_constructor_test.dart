// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInRedirectingFactoryConstructorTest);
  });
}

@reflectiveTest
class DefaultValueInRedirectingFactoryConstructorTest
    extends PubPackageResolutionTest {
  test_default_value() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A([int x = 0]) = B;
}

class B implements A {
  B([int x = 1]) {}
}
''',
      [error(diag.defaultValueInRedirectingFactoryConstructor, 27, 1)],
    );
  }
}
