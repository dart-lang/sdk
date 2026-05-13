// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidConstructorNameTest);
  });
}

@reflectiveTest
class InvalidConstructorNameTest extends PubPackageResolutionTest {
  test_class_notEnclosingClassName_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B() : super();
//^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
}
class B {}
''');
  }

  test_class_notEnclosingClassName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {
  A.foo();
//^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
  B.foo();
}
''');
  }

  test_class_notEnclosingClassName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B {
  A.new();
//^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
  B();
}
''');
  }

  test_class_notEnclosingClassName_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B() : super();
//^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
}
''');
  }

  test_enum_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

enum E {
  v.foo();
  const A.foo();
//      ^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
  const E.foo();
//        ^^^
// [diag.unusedElement] The declaration 'E.foo' isn't referenced.
}
''');
  }
}
