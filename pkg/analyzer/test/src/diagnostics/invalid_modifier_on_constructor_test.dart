// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() async {}
//    ^^^^^
// [diag.invalidModifierOnConstructor] The modifier 'async' can't be applied to the body of a constructor.
}
''');
  }

  test_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() async* {}
//    ^^^^^
// [diag.invalidModifierOnConstructor] The modifier 'async' can't be applied to the body of a constructor.
}
''');
  }

  test_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() sync* {}
//    ^^^^
// [diag.invalidModifierOnConstructor] The modifier 'sync' can't be applied to the body of a constructor.
}
''');
  }
}
