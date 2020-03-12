// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceAccessToStaticMemberTest);
  });
}

@reflectiveTest
class InstanceAccessToStaticMemberTest extends DriverResolutionTest {
  test_extension_getter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static int get a => 0;
}

C g(C c) => null;
f(C c) {
  g(c).a;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 93, 1),
    ]);
    assertElement(
      findNode.simple('a;'),
      findElement.getter('a'),
    );
  }

  test_extension_method() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 68, 1),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_extension_setter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static set a(v) {}
}

f(C c) {
  c.a = 2;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 68, 1),
    ]);
    assertElement(
      findNode.simple('a = 2;'),
      findElement.setter('a'),
    );
  }
}
