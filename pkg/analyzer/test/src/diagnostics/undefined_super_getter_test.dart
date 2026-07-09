// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperGetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedSuperGetterTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  get g {
    return super.g;
//               ^
// [diag.undefinedSuperGetter] The getter 'g' isn't defined in a superclass of 'B'.
  }
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperGetter] The getter 'foo' isn't defined in a superclass of 'E'.
  }
}
''');
  }

  test_enum_OK() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  void f() {
    super.foo;
  }
}
''');
  }
}
