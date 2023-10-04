// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUse_BasicWorkspaceTest);
    defineReflectiveTests(
      DeprecatedMemberUse_BasicWorkspace_WithoutNullSafetyTest,
    );
    defineReflectiveTests(DeprecatedMemberUse_BlazeWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_GnWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_PackageBuildWorkspaceTest);
  });
}

@reflectiveTest
class DeprecatedMemberUse_BasicWorkspace_WithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, DeprecatedMemberUse_BasicWorkspaceTestCases {}

@reflectiveTest
class DeprecatedMemberUse_BasicWorkspaceTest extends PubPackageResolutionTest
    with DeprecatedMemberUse_BasicWorkspaceTestCases {
  test_deprecatedField_inObjectPattern_explicitName() async {
    await assertErrorsInCode2(externalCode: r'''
class C {
  @Deprecated('')
  final int foo = 0;
}
''', code: '''
int g(Object s) =>
  switch (s) {
    C(foo: var f) => f,
    _ => 7,
  };
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 69, 3),
    ]);
  }

  test_deprecatedField_inObjectPattern_inferredName() async {
    await assertErrorsInCode2(externalCode: r'''
class C {
  @Deprecated('')
  final int foo = 0;
}
''', code: '''
int g(Object s) =>
  switch (s) {
    C(:var foo) => foo,
    _ => 7,
  };
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 74, 3),
    ]);
  }

  test_inDeprecatedDefaultFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {
  const C();
}
''',
      code: r'''
f({@deprecated C? c = const C()}) {}
''',
    );
  }

  test_inDeprecatedEnum() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
@deprecated
enum E {
  one, two;

  void m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedFieldFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
class A {
  Object? o;
  A({@deprecated C? this.o});
}
''',
    );
  }

  test_inDeprecatedFunctionTypedFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
f({@deprecated C? callback()?}) {}
''',
    );
  }

  test_inDeprecatedSimpleFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
f({@deprecated C? c}) {}
''',
    );
  }

  test_inDeprecatedSuperFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
class A {
  A({Object? o});
}
class B extends A {
  B({@deprecated C? super.o});
}
''',
    );
  }

  test_inEnum() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
enum E {
  one, two;

  void m() {
    f();
  }
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 68, 1),
      ],
    );
  }

  test_instanceCreation_deprecatedClass_deprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  @deprecated
  A();
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f() {
  A();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
      // todo(pq): consider deduplicating.
      error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
    ]);
  }

  test_instanceCreation_deprecatedClass_undeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  A();
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f() {
  A();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
    ]);
  }

  test_instanceCreation_deprecatedClass_undeprecatedNamedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  A.a();
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f() {
  A.a();
}
''', [
      // https://github.com/dart-lang/linter/issues/4752
      // Highlights `A`.
      error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
    ]);
  }

  test_instanceCreation_namedParameter_fromLegacy() async {
    noSoundNullSafety = false;
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

void f() {
  A(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 60, 1),
    ]);
  }

  test_instanceCreation_undeprecatedClass_deprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  A();
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f() {
  A();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
    ]);
  }

  test_methodInvocation_namedParameter_ofFunction_fromLegacy() async {
    noSoundNullSafety = false;
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
void foo({@deprecated int a}) {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 62, 1),
    ]);
  }

  test_methodInvocation_namedParameter_ofMethod_fromLegacy() async {
    noSoundNullSafety = false;
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  void foo({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 67, 1),
    ]);
  }

  test_superConstructorInvocation_namedParameter_fromLegacy() async {
    noSoundNullSafety = false;
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

class B extends A {
  B() : super(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 79, 1),
    ]);
  }
}

mixin DeprecatedMemberUse_BasicWorkspaceTestCases on PubPackageResolutionTest {
  String get externalLibPath => '$workspaceRootPath/aaa/lib/a.dart';

  String get externalLibUri => 'package:aaa/a.dart';

  Future<void> assertErrorsInCode2(
    List<ExpectedError> expectedErrors, {
    required String externalCode,
    required String code,
  }) async {
    newFile(externalLibPath, externalCode);

    await assertErrorsInCode('''
import '$externalLibUri';
$code
''', expectedErrors);
  }

  Future<void> assertNoErrorsInCode2({
    required String externalCode,
    required String code,
  }) async {
    newFile(externalLibPath, externalCode);

    await assertNoErrorsInCode('''
import '$externalLibUri';
$code
''');
  }

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );
  }

  test_assignmentExpression_compound_deprecatedGetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x += 2;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_assignmentExpression_compound_deprecatedSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  x += 2;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_assignmentExpression_simple_deprecatedGetter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x = 0;
}
''',
    );
  }

  test_assignmentExpression_simple_deprecatedGetterSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  x = 0;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_assignmentExpression_simple_deprecatedSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  x = 0;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_call() async {
    await assertErrorsInCode2(externalCode: r'''
class A {
  @deprecated
  call() {}
}
''', code: r'''
void f(A a) {
  a();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 45, 3),
    ]);
  }

  test_class() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
class A {}
''',
      code: r'''
void f(A a) {}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 36, 1),
      ],
    );
  }

  test_class_inDeprecatedFunctionTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

@deprecated
typedef A T();
''');
  }

  test_class_inDeprecatedGenericTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

@deprecated
typedef T = A Function();
''');
  }

  test_compoundAssignment() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
''',
      code: r'''
f(A a, A b) {
  a += b;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 45, 6),
      ],
    );
  }

  test_export() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
library a;
''');

    await assertErrorsInCode('''
export 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_export_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
@deprecated
library a;
''');

    await assertErrorsInCode('''
export 'lib2.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 19),
    ]);
  }

  test_extensionOverride() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
extension E on int {
  int get foo => 0;
}
''',
      code: '''
void f() {
  E(0).foo;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_field_implicitGetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_field_implicitSetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_field_inDeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  int x = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

class B extends A {
  @deprecated
  B() {
    x;
    x = 1;
  }
}
''');
  }

  test_hideCombinator() async {
    newFile(externalLibPath, r'''
@deprecated
class A {}
''');
    await assertNoErrorsInCode('''
// ignore: unused_import
import '$externalLibUri' hide A;
''');
  }

  test_import() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
library a;
''');

    await assertErrorsInCode(r'''
// ignore:unused_import
import 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 24, 28,
          messageContains: ['package:aaa/a.dart']),
    ]);
  }

  test_inDeprecatedClass() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: r'''
@deprecated
class C {
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedExtension() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
@deprecated
extension E on int {
  void m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedField() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
class X {
  @deprecated
  C f;
  X(this.f);
}
''',
    );
  }

  test_inDeprecatedFunction() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
g() {
  f();
}
''',
    );
  }

  test_inDeprecatedLibrary() async {
    newFile(externalLibPath, r'''
@deprecated
f() {}
''');
    await assertNoErrorsInCode('''
@deprecated
library lib;
import '$externalLibUri';

class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
class C {
  @deprecated
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedMethod_inDeprecatedClass() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
class C {
  @deprecated
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedMixin() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
mixin M {
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedTopLevelVariable() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {}
var x = C();
''',
      code: r'''
@deprecated
C v = x;
''',
    );
  }

  test_indexExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  operator[](int i) {}
}
''',
      code: r'''
void f(A a) {
  return a[1];
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 52, 4),
      ],
    );
  }

  test_inExtension() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
extension E on int {
  void m() {
    f();
  }
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 67, 1),
      ],
    );
  }

  test_instanceCreation_namedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  A.named(int i) {}
}
''',
      code: r'''
f() {
  return new A.named(1);
}
''',
      [
        error(
          HintCode.DEPRECATED_MEMBER_USE,
          48,
          7,
          messageContains: ["'A.named' is deprecated and shouldn't be used."],
        ),
      ],
    );
  }

  test_instanceCreation_unnamedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  A(int i) {}
}
''',
      code: r'''
f() {
  return new A(1);
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 48, 1),
      ],
    );
  }

  test_methodInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_methodInvocation_constantAnnotation() async {
    await assertErrorsInCode2(externalCode: r'''
@deprecated
int f() => 0;
''', code: r'''
var x = f();
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }

  test_methodInvocation_constructorAnnotation() async {
    await assertErrorsInCode2(
      externalCode: r'''
@Deprecated('0.9')
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 37, 1,
            text: "'f' is deprecated and shouldn't be used. 0.9."),
      ],
    );
  }

  test_methodInvocation_constructorAnnotation_dot() async {
    await assertErrorsInCode2(
      externalCode: r'''
@Deprecated('0.9.')
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 37, 1,
            text: "'f' is deprecated and shouldn't be used. 0.9."),
      ],
    );
  }

  test_methodInvocation_constructorAnnotation_exclamationMark() async {
    await assertErrorsInCode2(
      externalCode: r'''
@Deprecated(' Really! ')
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 37, 1,
            text: "'f' is deprecated and shouldn't be used. Really!"),
      ],
    );
  }

  test_methodInvocation_constructorAnnotation_onlyDot() async {
    await assertErrorsInCode2(
      externalCode: r'''
@Deprecated('.')
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 37, 1,
            text: "'f' is deprecated and shouldn't be used."),
      ],
    );
  }

  test_methodInvocation_constructorAnnotation_questionMark() async {
    await assertErrorsInCode2(
      externalCode: r'''
@Deprecated('Are you sure?')
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 37, 1,
            text: "'f' is deprecated and shouldn't be used. Are you sure?"),
      ],
    );
  }

  test_methodInvocation_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
class A {
  @deprecated
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
import 'lib2.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 39, 3),
    ]);
  }

  test_methodInvocation_inDeprecatedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  @deprecated
  A() {
    foo();
  }

  @deprecated
  void foo() {}
}
''');
  }

  test_methodInvocation_withMessage() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @Deprecated('0.9')
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 48, 3,
          text: "'foo' is deprecated and shouldn't be used. 0.9."),
    ]);
  }

  test_mixin_inDeprecatedClassTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
mixin A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

@deprecated
class B = Object with A;
''');
  }

  test_operator() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  operator+(A a) {}
}
''',
      code: r'''
f(A a, A b) {
  return a + b;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 52, 5),
      ],
    );
  }

  test_parameter_named() async {
    await assertErrorsInCode2(
      externalCode: r'''
void f({@deprecated int x = 0}) {}
''',
      code: r'''
void g() => f(x: 1);
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
      ],
    );
  }

  test_parameter_named_inDefiningConstructor_asFieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C({@deprecated this.x = 0});
}
''');
  }

  test_parameter_named_inDefiningConstructor_assertInitializer() async {
    await assertNoErrorsInCode(r'''
class C {
  C({@deprecated int y = 0}) : assert(y > 0);
}
''');
  }

  test_parameter_named_inDefiningConstructor_fieldInitializer() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C({@deprecated int y = 0}) : x = y;
}
''');
  }

  test_parameter_named_inDefiningConstructor_inFieldFormalParameter_notName() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {}

@deprecated
class B extends A {
  const B();
}

const B instance = const B();
''',
      code: r'''
class C {
  final A a;
  C({B this.a = instance});
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 57, 1),
      ],
    );
  }

  test_parameter_named_inDefiningFunction() async {
    await assertNoErrorsInCode(r'''
f({@deprecated int x = 0}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    await assertNoErrorsInCode(r'''
class C {
  m() {
    f({@deprecated int x = 0}) {
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
  m({@deprecated int x = 0}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    await assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x = 0}) {
    f() {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_ofFunction() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
void foo({@deprecated int a}) {}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 47, 1),
    ]);
  }

  test_parameter_named_ofMethod() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  void foo({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 52, 1),
    ]);
  }

  test_parameter_positionalOptional() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  void foo([@deprecated int x = 0]) {}
}
''',
      code: '''
void f(A a) {
  a.foo(0);
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 51, 1),
      ],
    );
  }

  test_parameter_positionalOptional_inDeprecatedConstructor() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
void foo([@deprecated int x = 0]) {}
''',
      code: r'''
class A {
  @deprecated
  A() {
    foo(0);
  }
}
''',
    );
  }

  test_parameter_positionalOptional_inDeprecatedFunction() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
class A {
  void foo([@deprecated int x = 0]) {}
}
''',
      code: r'''
@deprecated
void f(A a) {
  a.foo(0);
}
''',
    );
  }

  test_parameter_positionalRequired() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
class A {
  void foo(@deprecated int x) {}
}
''',
      code: r'''
void f(A a) {
  a.foo(0);
}
''',
    );
  }

  test_postfixExpression_deprecatedGetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x++;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_postfixExpression_deprecatedNothing() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x++;
}
''',
    );
  }

  test_postfixExpression_deprecatedSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  x++;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_prefixedIdentifier_identifier() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  static const foo = 0;
}
''',
      code: r'''
void f() {
  A.foo;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 44, 3),
      ],
    );
  }

  test_prefixedIdentifier_prefix() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
class A {
  static const foo = 0;
}
''',
      code: r'''
void f() {
  A.foo;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_prefixExpression_deprecatedGetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  ++x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 44, 1),
      ],
    );
  }

  test_prefixExpression_deprecatedSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  ++x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 44, 1),
      ],
    );
  }

  test_propertyAccess_super() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  int get foo => 0;
}
''',
      code: r'''
class B extends A {
  void bar() {
    super.foo;
  }
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 74, 3),
      ],
    );
  }

  test_redirectingConstructorInvocation_namedParameter() async {
    await assertErrorsInCode(r'''
class A {
  A({@deprecated int a = 0}) {}
  A.named() : this(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 61, 1),
    ]);
  }

  test_setterInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  set foo(int _) {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_showCombinator() async {
    newFile(externalLibPath, r'''
@deprecated
class A {}
''');
    await assertErrorsInCode('''
// ignore: unused_import
import '$externalLibUri' show A;
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 58, 1),
    ]);
  }

  test_superConstructor_namedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  A.named() {}
}
''',
      code: r'''
class B extends A {
  B() : super.named() {}
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 57, 13,
            text: "'A.named' is deprecated and shouldn't be used."),
      ],
    );
  }

  test_superConstructor_unnamedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
class A {
  @deprecated
  A() {}
}
''',
      code: r'''
class B extends A {
  B() : super() {}
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 57, 7,
            text: "'A.new' is deprecated and shouldn't be used."),
      ],
    );
  }

  test_topLevelVariable_argument() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  print(x);
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 48, 1),
      ],
    );
  }

  test_topLevelVariable_assignment_right() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f(int a) {
  a = x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 51, 1),
      ],
    );
  }

  test_topLevelVariable_binaryExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  x + 1;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_topLevelVariable_constructorFieldInitializer() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
const int x = 1;
''',
      code: r'''
class A {
  final int f;
  A() : f = x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 66, 1),
      ],
    );
  }

  test_topLevelVariable_expressionFunctionBody() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
int f() => x;
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 40, 1),
      ],
    );
  }

  test_topLevelVariable_expressionStatement() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 42, 1),
      ],
    );
  }

  test_topLevelVariable_forElement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  [for (;x;) 0];
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 49, 1),
      ],
    );
  }

  test_topLevelVariable_forStatement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  for (;x;) {}
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 48, 1),
      ],
    );
  }

  test_topLevelVariable_ifElement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  [if (x) 0];
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 47, 1),
      ],
    );
  }

  test_topLevelVariable_ifStatement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  if (x) {}
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 46, 1),
      ],
    );
  }

  test_topLevelVariable_listLiteral() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  [x];
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
      ],
    );
  }

  test_topLevelVariable_mapLiteralEntry() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  ({0: x, x: 0});
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 47, 1),
        error(HintCode.DEPRECATED_MEMBER_USE, 50, 1),
      ],
    );
  }

  test_topLevelVariable_namedExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void g({int a = 0}) {}
void f() {
  g(a: x);
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 70, 1),
      ],
    );
  }

  test_topLevelVariable_returnStatement() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
int f() {
  return x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 48, 1),
      ],
    );
  }

  test_topLevelVariable_setLiteral() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  ({x});
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 44, 1),
      ],
    );
  }

  test_topLevelVariable_spreadElement() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = [0];
''',
      code: r'''
void f() {
  [...x];
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 46, 1),
      ],
    );
  }

  test_topLevelVariable_switchCase() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
const int x = 1;
''',
      code: r'''
void f(int a) {
  switch (a) {
    case x:
      break;
  }
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 69, 1),
      ],
    );
  }

  test_topLevelVariable_switchCase_language219() async {
    newFile(externalLibPath, r'''
@deprecated
const int x = 1;
''');
    await assertErrorsInCode('''
// @dart = 2.19
import '$externalLibUri';
void f(int a) {
  switch (a) {
    case x:
      break;
  }
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 85, 1),
    ]);
  }

  test_topLevelVariable_switchStatement() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  switch (x) {}
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 50, 1),
      ],
    );
  }

  test_topLevelVariable_switchStatement_language219() async {
    newFile(externalLibPath, r'''
@deprecated
int x = 1;
''');
    await assertErrorsInCode('''
// @dart = 2.19
import '$externalLibUri';
void f() {
  switch (x) {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 66, 1),
    ]);
  }

  test_topLevelVariable_unaryExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  -x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 43, 1),
      ],
    );
  }

  test_topLevelVariable_variableDeclaration_initializer() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = 1;
''',
      code: r'''
void f() {
  // ignore: unused_local_variable
  var v = x;
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 85, 1),
      ],
    );
  }

  test_topLevelVariable_whileStatement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  while (x) {}
}
''',
      [
        error(HintCode.DEPRECATED_MEMBER_USE, 49, 1),
      ],
    );
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertBasicWorkspaceFor(testFile);
  }
}

@reflectiveTest
class DeprecatedMemberUse_BlazeWorkspaceTest
    extends BlazeWorkspaceResolutionTest {
  test_dart() async {
    newFile('$workspaceRootPath/foo/bar/lib/a.dart', r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:foo.bar/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 41, 1),
    ]);
  }

  test_thirdPartyDart() async {
    newFile('$workspaceThirdPartyDartPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    assertBlazeWorkspaceFor(testFile);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUse_GnWorkspaceTest extends ContextResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  String get genPath => '$outPath/dartlang/gen';

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/my';

  Folder get outFolder => getFolder(outPath);

  String get outPath => '$workspaceRootPath/out/default';

  @override
  File get testFile => getFile('$myPackageLibPath/my.dart');

  String get workspaceRootPath => '/workspace';

  @override
  void setUp() {
    super.setUp();
    newFolder('$workspaceRootPath/.jiri_root');

    newFile('$workspaceRootPath/.fx-build-dir', '''
${outFolder.path}
''');

    newBuildGnFile(myPackageRootPath, '');
  }

  test_differentPackage() async {
    newBuildGnFile('$workspaceRootPath/aaa', '');

    var myPackageConfig = getFile('$genPath/my/my_package_config.json');
    _writeWorkspacePackagesFile(myPackageConfig, {
      'aaa': '$workspaceRootPath/aaa/lib',
      'my': myPackageLibPath,
    });

    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertGnWorkspaceFor(testFile);
  }

  void _writeWorkspacePackagesFile(
      File file, Map<String, String> nameToLibPath) {
    var packages = nameToLibPath.entries.map((entry) => '''{
    "languageVersion": "2.2",
    "name": "${entry.key}",
    "packageUri": ".",
    "rootUri": "${toUriStr(entry.value)}"
  }''');

    newFile(file.path, '''{
  "configVersion": 2,
  "packages": [ ${packages.join(', ')} ]
}''');
  }
}

@reflectiveTest
class DeprecatedMemberUse_PackageBuildWorkspaceTest
    extends _PackageBuildWorkspaceBase {
  test_generated() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _newTestPackageGeneratedFile(
      packageName: 'aaa',
      pathInLib: 'a.dart',
      content: r'''
@deprecated
class A {}
''',
    );

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }

  test_lib() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _createTestPackageBuildMarker();

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }
}

class _PackageBuildWorkspaceBase extends PubPackageResolutionTest {
  String get testPackageGeneratedPath {
    return '$testPackageRootPath/.dart_tool/build/generated';
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertPackageBuildWorkspaceFor(testFile);
  }

  void _createTestPackageBuildMarker() {
    newFolder(testPackageGeneratedPath);
  }

  void _newTestPackageGeneratedFile({
    required String packageName,
    required String pathInLib,
    required String content,
  }) {
    newFile(
      '$testPackageGeneratedPath/$packageName/lib/$pathInLib',
      content,
    );
  }
}
