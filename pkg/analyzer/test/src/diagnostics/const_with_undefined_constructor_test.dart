// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithUndefinedConstructorTest);
  });
}

@reflectiveTest
class ConstWithUndefinedConstructorTest extends PubPackageResolutionTest {
  test_class_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}
f() {
  return const A.noSuchConstructor();
//               ^^^^^^^^^^^^^^^^^
// [diag.constWithUndefinedConstructor] The class 'A' doesn't have a constant constructor 'noSuchConstructor'.
}
''');
  }

  test_class_named_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as a;
f() {
  return const a.Future.noSuchConstructor();
//                      ^^^^^^^^^^^^^^^^^
// [diag.constWithUndefinedConstructor] The class 'a.Future' doesn't have a constant constructor 'noSuchConstructor'.
}
''');
  }

  test_class_nonFunctionTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.name();
}
typedef B = A;
f() {
  return const B();
//             ^
// [diag.constWithUndefinedConstructorDefault] The class 'B' doesn't have an unnamed constant constructor.
}
''');
  }

  test_class_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.name();
}
f() {
  return const A();
//             ^
// [diag.constWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constant constructor.
}
''');
  }

  test_class_unnamed_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  const A.name();
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib1;
f() {
  return const lib1.A();
//             ^^^^^^
// [diag.constWithUndefinedConstructorDefault] The class 'lib1.A' doesn't have an unnamed constant constructor.
}
''');
  }

  test_enum_notConstructor_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const E.v();
//        ^
// [diag.constWithUndefinedConstructor] The class 'E' doesn't have a constant constructor 'v'.
}

enum E {
  v
}
''');
  }

  test_enum_notConstructor_method() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const E.foo();
//        ^^^
// [diag.constWithUndefinedConstructor] The class 'E' doesn't have a constant constructor 'foo'.
}

enum E {
  v;
  
  void foo() {}
}
''');
  }

  test_enum_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const E.foo();
//        ^^^
// [diag.constWithUndefinedConstructor] The class 'E' doesn't have a constant constructor 'foo'.
}

enum E {
  v
}
''');
  }
}
