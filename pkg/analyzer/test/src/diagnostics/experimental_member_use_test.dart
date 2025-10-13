// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentalExtendTest);
    defineReflectiveTests(ExperimentalImplementTest);
    defineReflectiveTests(ExperimentalInstantiateTest);
    defineReflectiveTests(ExperimentalMemberUseTest);
    defineReflectiveTests(ExperimentalMixinTest);
  });
}

@reflectiveTest
class ExperimentalExtendTest extends _TestBase {
  test_annotatedClass() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
class Bar extends Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 47, 3)],
    );
  }

  test_annotatedClass_indirect() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar extends Foo {}
''',
      code: r'''
class Baz extends Bar {}
''',
    );
  }

  test_annotatedClass_typedef() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''',
      code: r'''
class Bar extends Foo2 {}
''',
    );
  }

  test_annotatedClassTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo = Object with M;
mixin M {}
''',
      code: r'''
class Bar extends Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 47, 3)],
    );
  }

  test_classTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
mixin M {}
class Bar = Foo with M;
''',
      [error(WarningCode.experimentalMemberUse, 52, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar extends Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertNoErrorsInCode2(
      externalCode: r'''
class Foo {}
''',
      code: r'''
class Bar extends Foo {}
''',
    );
  }
}

@reflectiveTest
class ExperimentalImplementTest extends _TestBase {
  test_annotatedClass() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
class Bar implements Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 50, 3)],
    );
  }

  test_annotatedClass_indirect() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar extends Foo {}
''',
      code: r'''
class Baz implements Bar {}
''',
    );
  }

  test_annotatedClass_typedef() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''',
      code: r'''
class Bar implements Foo2 {}
''',
    );
  }

  test_annotatedClassTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo = Object with M;
mixin M {}
''',
      code: r'''
class Bar implements Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 50, 3)],
    );
  }

  test_classTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
mixin M {}
class Bar = Object with M implements Foo;
''',
      [error(WarningCode.experimentalMemberUse, 77, 3)],
    );
  }

  test_enum() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
enum Bar implements Foo { one; }
''',
      [error(WarningCode.experimentalMemberUse, 49, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar implements Foo {}
''');
  }

  test_mixinImplementsClass() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
mixin Bar implements Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 50, 3)],
    );
  }

  test_mixinOnClass() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
mixin Bar on Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 42, 3)],
    );
  }

  test_noAnnotation() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
class Foo {}
''',
      code: r'''
class Bar implements Foo {}
''',
    );
  }
}

@reflectiveTest
class ExperimentalInstantiateTest extends _TestBase {
  test_annotatedClass() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
var x = Foo();
''',
      [error(WarningCode.experimentalMemberUse, 37, 3)],
    );
  }

  test_annotatedClass_tearoff() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''',
      code: r'''
var x = Foo.new;
''',
      [error(WarningCode.experimentalMemberUse, 37, 3)],
    );
  }

  test_annotatedClass_typedef() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''',
      code: r'''
var x = Foo2();
''',
    );
  }

  test_annotatedClass_typedef_tearoff() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''',
      code: r'''
var x = Foo2.new;
''',
    );
  }

  test_annotatedClassTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class Foo = Object with M;
mixin M {}
''',
      code: r'''
var x = Foo();
''',
      [error(WarningCode.experimentalMemberUse, 37, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
@Deprecated.implement()
class Foo {}
var x = Foo();
''');
  }

  test_noAnnotation() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
class Foo {}
''',
      code: r'''
var x = Foo();
''',
    );
  }
}

@reflectiveTest
class ExperimentalMemberUseTest extends _TestBase {
  test_assignmentExpression_compound_experimentalGetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x += 2;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_assignmentExpression_compound_experimentalSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''',
      code: r'''
void f() {
  x += 2;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_assignmentExpression_simple_experimentalGetter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
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

  test_assignmentExpression_simple_experimentalGetterSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  x = 0;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_assignmentExpression_simple_experimentalSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''',
      code: r'''
void f() {
  x = 0;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_call() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  call() {}
}
''',
      code: r'''
void f(A a) {
  a();
}
''',
      [error(WarningCode.experimentalMemberUse, 45, 3)],
    );
  }

  test_class() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''',
      code: r'''
void f(A a) {}
''',
      [error(WarningCode.experimentalMemberUse, 36, 1)],
    );
  }

  test_class_inExperimentalFunctionTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
typedef A T();
''');
  }

  test_class_inExperimentalGenericTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
typedef T = A Function();
''');
  }

  test_compoundAssignment() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A operator+(A a) { return a; }
}
''',
      code: r'''
f(A a, A b) {
  a += b;
}
''',
      [error(WarningCode.experimentalMemberUse, 45, 6)],
    );
  }

  test_dotShorthandConstructorInvocation_experimentalClass_experimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  @experimental
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A a = .new();
}
''',
      [
        error(WarningCode.experimentalMemberUse, 43, 1),
        error(WarningCode.unusedLocalVariable, 45, 1),
        error(WarningCode.experimentalMemberUse, 50, 3),
      ],
    );
  }

  test_dotShorthandConstructorInvocation_experimentalClass_unexperimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A a = .new();
}
''',
      [
        error(WarningCode.experimentalMemberUse, 43, 1),
        error(WarningCode.unusedLocalVariable, 45, 1),
      ],
    );
  }

  test_dotShorthandConstructorInvocation_experimentalClass_unexperimentalNamedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A.a();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A a = .a();
}
''',
      [
        error(WarningCode.experimentalMemberUse, 43, 1),
        error(WarningCode.unusedLocalVariable, 45, 1),
      ],
    );
  }

  test_dotShorthandConstructorInvocation_namedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A.named(int i) {}
}
''',
      code: r'''
f() {
  A a = .named(1);
}
''',
      [
        error(WarningCode.unusedLocalVariable, 39, 1),
        error(
          WarningCode.experimentalMemberUse,
          44,
          5,
          messageContains: [
            "'A.named' is experimental and could be removed or changed at any time.",
          ],
        ),
      ],
    );
  }

  test_dotShorthandConstructorInvocation_unexperimentalClass_experimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A a = .new();
}
''',
      [
        error(WarningCode.unusedLocalVariable, 45, 1),
        error(WarningCode.experimentalMemberUse, 50, 3),
      ],
    );
  }

  test_experimentalField_inObjectPattern_explicitName() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class C {
  @experimental
  final int foo = 0;
}
''',
      code: '''
int g(Object s) =>
  switch (s) {
    C(foo: var f) => f,
    _ => 7,
  };
''',
      [error(WarningCode.experimentalMemberUse, 69, 3)],
    );
  }

  test_experimentalField_inObjectPattern_inferredName() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class C {
  @experimental
  final int foo = 0;
}
''',
      code: '''
int g(Object s) =>
  switch (s) {
    C(:var foo) => foo,
    _ => 7,
  };
''',
      [error(WarningCode.experimentalMemberUse, 74, 3)],
    );
  }

  test_export() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
library a;
''');

    await assertErrorsInCode(
      '''
export 'package:aaa/a.dart';
''',
      [error(WarningCode.experimentalMemberUse, 0, 28)],
    );
  }

  test_export_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'package:meta/meta.dart';

@experimental
library a;
''');

    await assertNoErrorsInCode('''
export 'lib2.dart';
''');
  }

  test_extensionOverride() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
extension E on int {
  int get foo => 0;
}
''',
      code: '''
void f() {
  E(0).foo;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_field_implicitGetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int foo = 0;
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo;
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 3)],
    );
  }

  test_field_implicitSetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int foo = 0;
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 3)],
    );
  }

  test_field_inExperimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int x = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class B extends A {
  @experimental
  B() {
    x;
    x = 1;
  }
}
''');
  }

  test_hideCombinator() async {
    newFile(externalLibPath, r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');
    await assertNoErrorsInCode('''
// ignore: unused_import
import '$externalLibUri' hide A;
''');
  }

  test_import() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
library a;
''');

    await assertErrorsInCode(
      r'''
// ignore:unused_import
import 'package:aaa/a.dart';
''',
      [
        error(
          WarningCode.experimentalMemberUse,
          24,
          28,
          messageContains: ['package:aaa/a.dart'],
        ),
      ],
    );
  }

  test_incorrectlyNestedNamedParameterDeclaration() async {
    // This is a regression test; previously this code would cause an analyzer
    // crash in ExperimentalMemberUseVerifier.
    await assertErrorsInCode(
      r'''
class C {
  final String x;
  final bool y;

  const C({
    required this.x,
    {this.y = false}
  });
}

const z = C(x: '');
''',
      [
        error(CompileTimeErrorCode.finalNotInitializedConstructor1, 53, 1),
        error(ParserErrorCode.missingIdentifier, 82, 1),
        error(ParserErrorCode.expectedToken, 82, 1),
      ],
    );
  }

  test_indexExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  operator[](int i) {}
}
''',
      code: r'''
void f(A a) {
  return a[1];
}
''',
      [error(WarningCode.experimentalMemberUse, 52, 4)],
    );
  }

  test_inEnum() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
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
      [error(WarningCode.experimentalMemberUse, 68, 1)],
    );
  }

  test_inExperimentalClass() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''',
      code: r'''
import 'package:meta/meta.dart';

@experimental
class C {
  m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalDefaultFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {
  const C();
}
''',
      code: r'''
import 'package:meta/meta.dart';

f({@experimental C? c = const C()}) {}
''',
    );
  }

  test_inExperimentalEnum() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''',
      code: r'''
import 'package:meta/meta.dart';

@experimental
enum E {
  one, two;

  void m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalExtension() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''',
      code: r'''
import 'package:meta/meta.dart';

@experimental
extension E on int {
  void m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalExtensionType() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''',
      code: '''
import 'package:meta/meta.dart';

@experimental
extension type E(int i) {
  m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalField() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''',
      code: r'''
import 'package:meta/meta.dart';

class X {
  @experimental
  C f;
  X(this.f);
}
''',
    );
  }

  test_inExperimentalFieldFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''',
      code: r'''
import 'package:meta/meta.dart';

class A {
  Object? o;
  A({@experimental C? this.o});
}
''',
    );
  }

  test_inExperimentalFunction() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''',
      code: '''
import 'package:meta/meta.dart';

@experimental
g() {
  f();
}
''',
    );
  }

  test_inExperimentalFunctionTypedFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''',
      code: r'''
import 'package:meta/meta.dart';

f({@experimental C? callback()?}) {}
''',
    );
  }

  test_inExperimentalLibrary() async {
    newFile(externalLibPath, r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');
    await assertNoErrorsInCode('''
@experimental
library lib;
import 'package:meta/meta.dart';
import '$externalLibUri';

class C {
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalMethod() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''',
      code: '''
import 'package:meta/meta.dart';

class C {
  @experimental
  m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalMethod_inExperimentalClass() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''',
      code: '''
import 'package:meta/meta.dart';

@experimental
class C {
  @experimental
  m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalMixin() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''',
      code: '''
import 'package:meta/meta.dart';

@experimental
mixin M {
  m() {
    f();
  }
}
''',
    );
  }

  test_inExperimentalSimpleFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''',
      code: r'''
import 'package:meta/meta.dart';

f({@experimental C? c}) {}
''',
    );
  }

  test_inExperimentalSuperFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''',
      code: r'''
import 'package:meta/meta.dart';

class A {
  A({Object? o});
}
class B extends A {
  B({@experimental C? super.o});
}
''',
    );
  }

  test_inExperimentalTopLevelVariable() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class C {}
var x = C();
''',
      code: r'''
import 'package:meta/meta.dart';

@experimental
C v = x;
''',
    );
  }

  test_inExtension() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''',
      code: r'''
extension E on int {
  void m() {
    f();
  }
}
''',
      [error(WarningCode.experimentalMemberUse, 67, 1)],
    );
  }

  test_instanceCreation_experimentalClass_experimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  @experimental
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A();
}
''',
      [error(WarningCode.experimentalMemberUse, 43, 1)],
    );
  }

  test_instanceCreation_experimentalClass_unexperimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A();
}
''',
      [error(WarningCode.experimentalMemberUse, 43, 1)],
    );
  }

  test_instanceCreation_experimentalClass_unexperimentalNamedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A.a();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A.a();
}
''',
      [
        // https://github.com/dart-lang/linter/issues/4752
        // Highlights `A`.
        error(WarningCode.experimentalMemberUse, 43, 1),
      ],
    );
  }

  test_instanceCreation_namedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
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
          WarningCode.experimentalMemberUse,
          48,
          7,
          messageContains: [
            "'A.named' is experimental and could be removed or changed at any time.",
          ],
        ),
      ],
    );
  }

  test_instanceCreation_unexperimentalClass_experimentalConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  A();
}
''',
      [error(WarningCode.experimentalMemberUse, 43, 1)],
    );
  }

  test_instanceCreation_unnamedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A(int i) {}
}
''',
      code: r'''
f() {
  return new A(1);
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 1)],
    );
  }

  test_methodInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  void foo() {}
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 3)],
    );
  }

  test_methodInvocation_constantAnnotation() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [error(WarningCode.experimentalMemberUse, 37, 1)],
    );
  }

  test_methodInvocation_constructorAnnotation() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int f() => 0;
''',
      code: r'''
var x = f();
''',
      [
        error(
          WarningCode.experimentalMemberUse,
          37,
          1,
          text:
              "'f' is experimental and could be removed or changed at any time.",
        ),
      ],
    );
  }

  test_methodInvocation_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
import 'lib2.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_methodInvocation_inExperimentalConstructor() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A() {
    foo();
  }

  @experimental
  void foo() {}
}
''');
  }

  test_mixin_inExperimentalClassTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
mixin A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
class B = Object with A;
''');
  }

  test_namedParameterMissingName() async {
    // This is a regression test; previously this code would cause an analyzer
    // crash in ExperimentalMemberUseVerifier.
    await assertErrorsInCode(
      r'''
class C {
  const C({this.});
}
var z = C(x: '');
''',
      [
        error(
          CompileTimeErrorCode.initializingFormalForNonExistentField,
          21,
          5,
        ),
        error(ParserErrorCode.missingIdentifier, 26, 1),
        error(CompileTimeErrorCode.undefinedNamedParameter, 42, 1),
      ],
    );
  }

  test_operator() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  operator+(A a) {}
}
''',
      code: r'''
f(A a, A b) {
  return a + b;
}
''',
      [error(WarningCode.experimentalMemberUse, 52, 5)],
    );
  }

  test_parameter_named() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

void f({@experimental int x = 0}) {}
''',
      code: r'''
void g() => f(x: 1);
''',
      [error(WarningCode.experimentalMemberUse, 43, 1)],
    );
  }

  test_parameter_named_inDefiningConstructor_asFieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  int x;
  C({@experimental this.x = 0});
}
''');
  }

  test_parameter_named_inDefiningConstructor_assertInitializer() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@experimental int y = 0}) : assert(y > 0);
}
''');
  }

  test_parameter_named_inDefiningConstructor_fieldInitializer() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  int x;
  C({@experimental int y = 0}) : x = y;
}
''');
  }

  test_parameter_named_inDefiningConstructor_inFieldFormalParameter_notName() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {}

@experimental
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
      [error(WarningCode.experimentalMemberUse, 57, 1)],
    );
  }

  test_parameter_named_inDefiningFunction() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

f({@experimental int x = 0}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  m() {
    f({@experimental int x = 0}) {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_inDefiningMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  m({@experimental int x = 0}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  m({@experimental int x = 0}) {
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
import 'package:meta/meta.dart';

void foo({@experimental int a}) {}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
}
''',
      [error(WarningCode.experimentalMemberUse, 47, 1)],
    );
  }

  test_parameter_named_ofMethod() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void foo({@experimental int a}) {}
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
}
''',
      [error(WarningCode.experimentalMemberUse, 52, 1)],
    );
  }

  test_parameter_positionalOptional() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  void foo([@experimental int x = 0]) {}
}
''',
      code: '''
void f(A a) {
  a.foo(0);
}
''',
      [error(WarningCode.experimentalMemberUse, 51, 1)],
    );
  }

  test_parameter_positionalOptional_inExperimentalConstructor() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

void foo([@experimental int x = 0]) {}
''',
      code: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A() {
    foo(0);
  }
}
''',
    );
  }

  test_parameter_positionalOptional_inExperimentalFunction() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  void foo([@experimental int x = 0]) {}
}
''',
      code: r'''
import 'package:meta/meta.dart';

@experimental
void f(A a) {
  a.foo(0);
}
''',
    );
  }

  test_parameter_positionalRequired() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  void foo(@experimental int x) {}
}
''',
      code: r'''
void f(A a) {
  a.foo(0);
}
''',
    );
  }

  test_postfixExpression_experimentalGetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x++;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_postfixExpression_experimentalNothing() async {
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

  test_postfixExpression_experimentalSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''',
      code: r'''
void f() {
  x++;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_prefixedIdentifier_identifier() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  static const foo = 0;
}
''',
      code: r'''
void f() {
  A.foo;
}
''',
      [error(WarningCode.experimentalMemberUse, 44, 3)],
    );
  }

  test_prefixedIdentifier_prefix() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
class A {
  static const foo = 0;
}
''',
      code: r'''
void f() {
  A.foo;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_prefixExpression_experimentalGetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  ++x;
}
''',
      [error(WarningCode.experimentalMemberUse, 44, 1)],
    );
  }

  test_prefixExpression_experimentalSetter() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''',
      code: r'''
void f() {
  ++x;
}
''',
      [error(WarningCode.experimentalMemberUse, 44, 1)],
    );
  }

  test_propertyAccess_super() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
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
      [error(WarningCode.experimentalMemberUse, 74, 3)],
    );
  }

  test_redirectingConstructorInvocation_namedParameter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  A({@experimental int a = 0}) {}
  A.named() : this(a: 0);
}
''');
  }

  test_setterInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  set foo(int _) {}
}
''');

    await assertErrorsInCode(
      r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 3)],
    );
  }

  test_showCombinator() async {
    newFile(externalLibPath, r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');
    await assertErrorsInCode(
      '''
// ignore: unused_import
import '$externalLibUri' show A;
''',
      [error(WarningCode.experimentalMemberUse, 58, 1)],
    );
  }

  test_superConstructor_namedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A.named() {}
}
''',
      code: r'''
class B extends A {
  B() : super.named() {}
}
''',
      [
        error(
          WarningCode.experimentalMemberUse,
          57,
          13,
          text:
              "'A.named' is experimental and could be removed or changed at any time.",
        ),
      ],
    );
  }

  test_superConstructor_unnamedConstructor() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A() {}
}
''',
      code: r'''
class B extends A {
  B() : super() {}
}
''',
      [
        error(
          WarningCode.experimentalMemberUse,
          57,
          7,
          text:
              "'A' is experimental and could be removed or changed at any time.",
        ),
      ],
    );
  }

  test_topLevelVariable_argument() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  print(x);
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 1)],
    );
  }

  test_topLevelVariable_assignment_right() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f(int a) {
  a = x;
}
''',
      [error(WarningCode.experimentalMemberUse, 51, 1)],
    );
  }

  test_topLevelVariable_binaryExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  x + 1;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_topLevelVariable_constructorFieldInitializer() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
const int x = 1;
''',
      code: r'''
class A {
  final int f;
  A() : f = x;
}
''',
      [error(WarningCode.experimentalMemberUse, 66, 1)],
    );
  }

  test_topLevelVariable_expressionFunctionBody() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
int f() => x;
''',
      [error(WarningCode.experimentalMemberUse, 40, 1)],
    );
  }

  test_topLevelVariable_expressionStatement() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  x;
}
''',
      [error(WarningCode.experimentalMemberUse, 42, 1)],
    );
  }

  test_topLevelVariable_forElement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''',
      code: r'''
void f() {
  [for (;x;) 0];
}
''',
      [error(WarningCode.experimentalMemberUse, 49, 1)],
    );
  }

  test_topLevelVariable_forStatement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''',
      code: r'''
void f() {
  for (;x;) {}
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 1)],
    );
  }

  test_topLevelVariable_ifElement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''',
      code: r'''
void f() {
  [if (x) 0];
}
''',
      [error(WarningCode.experimentalMemberUse, 47, 1)],
    );
  }

  test_topLevelVariable_ifStatement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''',
      code: r'''
void f() {
  if (x) {}
}
''',
      [error(WarningCode.experimentalMemberUse, 46, 1)],
    );
  }

  test_topLevelVariable_listLiteral() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  [x];
}
''',
      [error(WarningCode.experimentalMemberUse, 43, 1)],
    );
  }

  test_topLevelVariable_mapLiteralEntry() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  ({0: x, x: 0});
}
''',
      [
        error(WarningCode.experimentalMemberUse, 47, 1),
        error(WarningCode.experimentalMemberUse, 50, 1),
      ],
    );
  }

  test_topLevelVariable_namedExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void g({int a = 0}) {}
void f() {
  g(a: x);
}
''',
      [error(WarningCode.experimentalMemberUse, 70, 1)],
    );
  }

  test_topLevelVariable_returnStatement() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
int f() {
  return x;
}
''',
      [error(WarningCode.experimentalMemberUse, 48, 1)],
    );
  }

  test_topLevelVariable_setLiteral() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  ({x});
}
''',
      [error(WarningCode.experimentalMemberUse, 44, 1)],
    );
  }

  test_topLevelVariable_spreadElement() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = [0];
''',
      code: r'''
void f() {
  [...x];
}
''',
      [error(WarningCode.experimentalMemberUse, 46, 1)],
    );
  }

  test_topLevelVariable_switchCase() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
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
      [error(WarningCode.experimentalMemberUse, 69, 1)],
    );
  }

  test_topLevelVariable_switchCase_language219() async {
    newFile(externalLibPath, r'''
import 'package:meta/meta.dart';

@experimental
const int x = 1;
''');
    await assertErrorsInCode(
      '''
// @dart = 2.19
import '$externalLibUri';
void f(int a) {
  switch (a) {
    case x:
      break;
  }
}
''',
      [error(WarningCode.experimentalMemberUse, 85, 1)],
    );
  }

  test_topLevelVariable_switchStatement() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  switch (x) {}
}
''',
      [error(WarningCode.experimentalMemberUse, 50, 1)],
    );
  }

  test_topLevelVariable_switchStatement_language219() async {
    newFile(externalLibPath, r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');
    await assertErrorsInCode(
      '''
// @dart = 2.19
import '$externalLibUri';
void f() {
  switch (x) {}
}
''',
      [error(WarningCode.experimentalMemberUse, 66, 1)],
    );
  }

  test_topLevelVariable_unaryExpression() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''',
      code: r'''
void f() {
  -x;
}
''',
      [error(WarningCode.experimentalMemberUse, 43, 1)],
    );
  }

  test_topLevelVariable_variableDeclaration_initializer() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = 1;
''',
      code: r'''
void f() {
  // ignore: unused_local_variable
  var v = x;
}
''',
      [error(WarningCode.experimentalMemberUse, 85, 1)],
    );
  }

  test_topLevelVariable_whileStatement_condition() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''',
      code: r'''
void f() {
  while (x) {}
}
''',
      [error(WarningCode.experimentalMemberUse, 49, 1)],
    );
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertPackageConfigWorkspaceFor(testFile);
  }
}

@reflectiveTest
class ExperimentalMixinTest extends _TestBase {
  test_annotatedClass_typedef() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
typedef Foo2 = Foo;
''',
      code: r'''
class Bar with Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 44, 3)],
    );
  }

  test_annotatedClassTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
mixin M {}
import 'package:meta/meta.dart';

@experimental
mixin class Foo = Object with M;
''',
      code: r'''
class Bar with Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 44, 3)],
    );
  }

  test_class() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
''',
      code: r'''
class Bar with Foo {}
''',
      [error(WarningCode.experimentalMemberUse, 44, 3)],
    );
  }

  test_classTypeAlias() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
''',
      code: r'''
class Bar = Object with Foo;
''',
      [error(WarningCode.experimentalMemberUse, 53, 3)],
    );
  }

  test_enum() async {
    await assertErrorsInCode2(
      externalCode: r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
''',
      code: r'''
enum Bar with Foo {
  one, two;
}
''',
      [error(WarningCode.experimentalMemberUse, 43, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
class Bar with Foo {}
''');
  }

  test_noAnnotation() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
mixin class Foo {}
''',
      code: r'''
class Bar with Foo {}
''',
    );
  }
}

class _TestBase extends PubPackageResolutionTest {
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
      meta: true,
    );
  }
}
