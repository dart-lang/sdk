// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidModifierOnConstructorTest);
  });
}

@reflectiveTest
class InvalidModifierOnConstructorTest extends PubPackageResolutionTest {
  test_async() async {
    await assertErrorsInCode(
      r'''
class A {
  A() async {}
}
''',
      [error(diag.invalidModifierOnConstructor, 16, 5)],
    );
  }

  test_asyncStar() async {
    await assertErrorsInCode(
      r'''
class A {
  A() async* {}
}
''',
      [error(diag.invalidModifierOnConstructor, 16, 5)],
    );
  }

  test_syncStar() async {
    await assertErrorsInCode(
      r'''
class A {
  A() sync* {}
}
''',
      [error(diag.invalidModifierOnConstructor, 16, 4)],
    );
  }
}
