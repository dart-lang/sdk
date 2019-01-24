// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfVoidResultTest_Driver);
  });
}

abstract class UseOfVoidResultTest extends ResolverTestCase {
  test_implicitReturnValue() async {
    await assertNoErrorsInCode(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}
''');
  }

  test_nonVoidReturnValue() async {
    await assertNoErrorsInCode(r'''
int f() => 1;
g() {
  var a = f();
}
''');
  }
}

@reflectiveTest
class UseOfVoidResultTest_Driver extends UseOfVoidResultTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
