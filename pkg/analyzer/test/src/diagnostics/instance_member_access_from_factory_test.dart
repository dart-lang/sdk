// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberAccessFromFactoryTest);
  });
}

@reflectiveTest
class InstanceMemberAccessFromFactoryTest extends PubPackageResolutionTest {
  test_named_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;

  factory A.make() {
    foo;
//  ^^^
// [diag.instanceMemberAccessFromFactory] Instance members can't be accessed from a factory constructor.
    throw 0;
  }
}
''');
  }

  test_named_getter_localFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;

  factory A.make() {
    void f() {
      foo;
//    ^^^
// [diag.instanceMemberAccessFromFactory] Instance members can't be accessed from a factory constructor.
    }
    f();
    throw 0;
  }
}
''');
  }

  test_named_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}

  factory A.make() {
    foo();
//  ^^^
// [diag.instanceMemberAccessFromFactory] Instance members can't be accessed from a factory constructor.
    throw 0;
  }
}
''');
  }

  test_named_method_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}

  factory A.make() {
    () => foo();
//        ^^^
// [diag.instanceMemberAccessFromFactory] Instance members can't be accessed from a factory constructor.
    throw 0;
  }
}
''');
  }

  test_named_method_functionExpression_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}

  factory A.make() {
    // ignore:unused_local_variable
    var x = () => foo();
//                ^^^
// [diag.instanceMemberAccessFromFactory] Instance members can't be accessed from a factory constructor.
    throw 0;
  }
}
''');
  }

  test_unnamed_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}

  factory A() {
    foo();
//  ^^^
// [diag.instanceMemberAccessFromFactory] Instance members can't be accessed from a factory constructor.
    throw 0;
  }
}
''');
  }
}
