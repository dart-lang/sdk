// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUseFromSamePackageTest);
    defineReflectiveTests(DeprecatedMemberUseFromSamePackageTest_Driver);
    defineReflectiveTests(DeprecatedMemberUseTest);
    defineReflectiveTests(DeprecatedMemberUseTest_Driver);
  });
}

@reflectiveTest
class DeprecatedMemberUseTest extends ResolverTestCase {
  /// Write a pubspec file at [root], so that BestPracticesVerifier can see that
  /// [root] is the root of a BasicWorkspace, and a BasicWorkspacePackage.
  void newBasicPackage(String root) {
    newFile('$root/pubspec.yaml');
  }

  test_methodInvocation_contructor() async {
    resetWithFooLibrary(r'''
class A {
  @Deprecated('0.9')
  m() {}
}
''');

    newBasicPackage('/pkg1');
    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
void main() => A().m();
''', [HintCode.DEPRECATED_MEMBER_USE], sourceName: '/pkg1/lib/lib1.dart');
  }

  test_methodInvocation_constant() async {
    resetWithFooLibrary(r'''
class A {
  @deprecated
  m() {}
}
''');

    newBasicPackage('/pkg1');
    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
void main() => A().m();
''', [HintCode.DEPRECATED_MEMBER_USE], sourceName: '/pkg1/lib/lib1.dart');
  }

  void resetWithFooLibrary(String source) {
    super.resetWith(packages: [
      ['foo', source]
    ]);
  }

  test_export() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newBasicPackage('/pkg1');
    assertErrorsInCode('''
export 'package:foo/foo.dart';
''', [HintCode.DEPRECATED_MEMBER_USE], sourceName: '/pkg1/lib/lib1.dart');
  }

  test_import() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newBasicPackage('/pkg1');
    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE], sourceName: '/pkg1/lib/lib1.dart');
  }
}

@reflectiveTest
class DeprecatedMemberUseTest_Driver extends DeprecatedMemberUseTest {
  @override
  bool get enableNewAnalysisDriver => true;
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackageTest extends ResolverTestCase {
  test_methodInvocation_contructor() async {
    assertErrorsInCode(r'''
class A {
  @Deprecated('0.9')
  m() {}
  n() {m();}
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_call() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  call() {}
  m() {
    A a = new A();
    a();
  }
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_compoundAssignment() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
f(A a) {
  A b;
  a += b;
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_export() async {
    addNamedSource("/deprecated_library.dart", r'''
@deprecated
library deprecated_library;
class A {}
''');
    await assertErrorsInCode('''
export 'deprecated_library.dart';
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_field() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  int x = 1;
}
f(A a) {
  return a.x;
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_getter() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  get m => 1;
}
f(A a) {
  return a.m;
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_import() async {
    addNamedSource("/deprecated_library.dart", r'''
@deprecated
library deprecated_library;
class A {}
''');
    await assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_inDeprecatedClass() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedField() async {
    await assertNoErrorsInCode(r'''
@deprecated
class C {}

class X {
  @deprecated
  C f;
}
''');
  }

  test_inDeprecatedFunction() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
g() {
  f();
}
''');
  }

  test_inDeprecatedLibrary() async {
    await assertNoErrorsInCode(r'''
@deprecated
library lib;

@deprecated
f() {}

class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

class C {
  @deprecated
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod_inDeprecatedClass() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
class C {
  @deprecated
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMixin() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
mixin M {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedTopLevelVariable() async {
    await assertNoErrorsInCode(r'''
@deprecated
class C {}

@deprecated
C v;
''');
  }

  test_indexExpression() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  operator[](int i) {}
}
f(A a) {
  return a[1];
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_instanceCreation_defaultConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A(int i) {}
}
f() {
  A a = new A(1);
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_instanceCreation_namedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A.named(int i) {}
}
f() {
  A a = new A.named(1);
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_methodInvocation_constant() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  m() {}
  n() {m();}
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_operator() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  operator+(A a) {}
}
f(A a) {
  A b;
  return a + b;
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_parameter_named() async {
    await assertErrorsInCode(r'''
class A {
  m({@deprecated int x}) {}
  n() {m(x: 1);}
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_parameter_named_inDefiningFunction() async {
    await assertNoErrorsInCode(r'''
f({@deprecated int x}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    await assertNoErrorsInCode(r'''
class C {
  m() {
    f({@deprecated int x}) {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_inDefiningMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    await assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x}) {
    f() {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_positional() async {
    await assertErrorsInCode(r'''
class A {
  m([@deprecated int x]) {}
  n() {m(1);}
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_setter() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  set s(v) {}
}
f(A a) {
  return a.s = 1;
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_superConstructor_defaultConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A() {}
}
class B extends A {
  B() : super() {}
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }

  test_superConstructor_namedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A.named() {}
}
class B extends A {
  B() : super.named() {}
}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackageTest_Driver
    extends DeprecatedMemberUseFromSamePackageTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
