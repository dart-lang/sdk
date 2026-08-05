// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForOverridingMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForOverridingMemberTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_differentLibrary_invalid() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class Child extends Parent {
  Child() {
    foo();
//  ^^^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'foo' can only be used for overriding.
  }
}
''');
  }

  test_differentLibrary_valid_onlyOverride() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class Child extends Parent {
  @override
  void foo() {}
}
''');
  }

  test_differentLibrary_valid_overrideAndUse() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class Child extends Parent {
  @override
  void foo() {}

  void bar() {
    foo();
  }
}
''');
  }

  test_field() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  int g = 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

int m(A a) {
  return a.g;
//         ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'g' can only be used for overriding.
}
''');
  }

  test_field_originPrimaryConstructor() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A(@visibleForOverriding var int g);
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

int m(A a) {
  return a.g;
//         ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'g' can only be used for overriding.
}
''');
  }

  test_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  int get g => 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B {
  int m(A a) {
    return a.g;
//           ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'g' can only be used for overriding.
  }
}
''');
  }

  test_getter_inObjectPattern() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  int get g => 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

void f(Object o) {
  switch (o) {
    case A(g: 7): print('yes');
//         ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'g' can only be used for overriding.
  }
}
''');
  }

  test_operator() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  operator >(A other) => true;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B {
  void m(A a) => a > A();
//                 ^
// [diag.invalidUseOfVisibleForOverridingMember] The member '>' can only be used for overriding.
}
''');
  }

  test_overriding_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  int get g => 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  @override
  int get g => super.g + 1;

  int get x => super.g + 1;
//                   ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'g' can only be used for overriding.
}
''');
  }

  test_overriding_methodInvocation() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  void m() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  @override
  void m() => super.m();

  void x() => super.m();
//                  ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 'm' can only be used for overriding.
}
''');
  }

  test_overriding_operator() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  operator >(A other) => true;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  @override
  operator >(A other) => super > other;

  void m() => super > A();
//                  ^
// [diag.invalidUseOfVisibleForOverridingMember] The member '>' can only be used for overriding.
}
''');
  }

  test_overriding_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  set s(int i) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  @override
  set s(int i) => super.s = i;

  set x(int i) => super.s = i;
//                      ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 's' can only be used for overriding.
}
''');
  }

  test_sameLibrary() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}

class Child extends Parent {
  Child() {
    foo();
  }
}
''');
  }

  test_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  set s(int i) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B {
  void m(A a) {
    a.s = 1;
//    ^
// [diag.invalidUseOfVisibleForOverridingMember] The member 's' can only be used for overriding.
  }
}
''');
  }
}
