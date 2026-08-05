// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentalExtendTest);
    defineReflectiveTests(ExperimentalImplementTest);
    defineReflectiveTests(ExperimentalInstantiateTest);
    defineReflectiveTests(ExperimentalMemberUseTest);
    defineReflectiveTests(ExperimentalMixinTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExperimentalExtendTest extends _TestBase {
  test_annotatedClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar extends Foo {}
//                ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_annotatedClass_indirect() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Baz extends Bar {}
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar extends Foo2 {}
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo = Object with M;
mixin M {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar extends Foo {}
//                ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_classTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
mixin M {}
class Bar = Foo with M;
//          ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar extends Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar extends Foo {}
''');
  }
}

@reflectiveTest
class ExperimentalImplementTest extends _TestBase {
  test_annotatedClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar implements Foo {}
//                   ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_annotatedClass_indirect() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Baz implements Bar {}
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar implements Foo2 {}
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo = Object with M;
mixin M {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar implements Foo {}
//                   ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_classTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
mixin M {}
class Bar = Object with M implements Foo;
//                                   ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_enum() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
enum Bar implements Foo { one; }
//                  ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
class Bar implements Foo {}
''');
  }

  test_mixinImplementsClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
mixin Bar implements Foo {}
//                   ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_mixinOnClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
mixin Bar on Foo {}
//           ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_noAnnotation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar implements Foo {}
''');
  }
}

@reflectiveTest
class ExperimentalInstantiateTest extends _TestBase {
  test_annotatedClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = Foo();
//      ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_annotatedClass_tearoff() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = Foo.new;
//      ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = Foo2();
''');
  }

  test_annotatedClass_typedef_tearoff() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = Foo2.new;
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class Foo = Object with M;
mixin M {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = Foo();
//      ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@experimental
class Foo {}
var x = Foo();
''');
  }

  test_noAnnotation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = Foo();
''');
  }
}

@reflectiveTest
class ExperimentalMemberUseTest extends _TestBase {
  test_assignmentExpression_compound_experimentalGetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x += 2;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_assignmentExpression_compound_experimentalSetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x += 2;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_assignmentExpression_simple_experimentalGetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x = 0;
}
''');
  }

  test_assignmentExpression_simple_experimentalGetterSetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x = 0;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_assignmentExpression_simple_experimentalSetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x = 0;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_call() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  call() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(A a) {
  a();
//^^^
// [diag.experimentalMemberUse] 'call' is experimental and could be removed or changed at any time.
}
''');
  }

  test_class() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(A a) {}
//     ^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
''');
  }

  test_class_inExperimentalFunctionTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
typedef A T();
''');
  }

  test_class_inExperimentalGenericTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
typedef T = A Function();
''');
  }

  test_compoundAssignment() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A operator+(A a) { return a; }
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
f(A a, A b) {
  a += b;
//^^^^^^
// [diag.experimentalMemberUse] '+' is experimental and could be removed or changed at any time.
}
''');
  }

  test_dotShorthandConstructorInvocation_experimentalClass_experimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  @experimental
  A();
}

void g(A a) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  g(.new());
//  ^^^^^^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
//   ^^^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_dotShorthandConstructorInvocation_experimentalClass_unexperimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A();
}
void g(A a) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  g(.new());
//  ^^^^^^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_dotShorthandConstructorInvocation_experimentalClass_unexperimentalNamedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A.a();
}
void g(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  g(.a());
//  ^^^^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_dotShorthandConstructorInvocation_namedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A.named(int i) {}
}
void g(A a) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
f() {
  g(.named(1));
//   ^^^^^
// [diag.experimentalMemberUse] 'A.named' is experimental and could be removed or changed at any time.
}
''');
  }

  test_dotShorthandConstructorInvocation_unexperimentalClass_experimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A();
}
void g(A a) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  g(.new());
//   ^^^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_experimentalField_inObjectPattern_explicitName() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class C {
  @experimental
  final int foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
int g(Object s) =>
  switch (s) {
    C(foo: var f) => f,
//    ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
    _ => 7,
  };
''');
  }

  test_experimentalField_inObjectPattern_inferredName() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class C {
  @experimental
  final int foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
int g(Object s) =>
  switch (s) {
    C(:var foo) => foo,
//         ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
    _ => 7,
  };
''');
  }

  test_export() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
library a;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:aaa/a.dart';
// [diag.experimentalMemberUse][column 1][length 28] 'package:aaa/a.dart' is experimental and could be removed or changed at any time.
''');
  }

  test_export_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'package:meta/meta.dart';

@experimental
library a;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'lib2.dart';
''');
  }

  test_extensionOverride() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
extension E on int {
  int get foo => 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  E(0).foo;
//^
// [diag.experimentalMemberUse] 'E' is experimental and could be removed or changed at any time.
}
''');
  }

  test_field_implicitGetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo;
//  ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
}
''');
  }

  test_field_implicitSetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
//  ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
}
''');
  }

  test_field_inExperimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int x = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
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
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'package:aaa/a.dart' hide A;
''');
  }

  test_import() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
library a;
''');

    await resolveTestCodeWithDiagnostics(r'''
// ignore:unused_import
import 'package:aaa/a.dart';
// [diag.experimentalMemberUse][column 1][length 28] 'package:aaa/a.dart' is experimental and could be removed or changed at any time.
''');
  }

  test_incorrectlyNestedNamedParameterDeclaration() async {
    // This is a regression test; previously this code would cause an analyzer
    // crash in ExperimentalMemberUseVerifier.
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String x;
  final bool y;

  const C({
//      ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'y' isn't.
    required this.x,
    {this.y = false}
//  ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '}'.
  });
}

const z = C(x: '');
''');
  }

  test_indexExpression() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  operator[](int i) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(A a) {
  return a[1];
//       ^^^^
// [diag.experimentalMemberUse] '[]' is experimental and could be removed or changed at any time.
}
''');
  }

  test_inEnum() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
enum E {
  one, two;

  void m() {
    f();
//  ^
// [diag.experimentalMemberUse] 'f' is experimental and could be removed or changed at any time.
  }
}
''');
  }

  test_inExperimentalClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
class C {
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalDefaultFormalParameter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {
  const C();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

f({@experimental C? c = const C()}) {}
''');
  }

  test_inExperimentalEnum() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
enum E {
  one, two;

  void m() {
    f();
  }
}
''');
  }

  test_inExperimentalExtension() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
extension E on int {
  void m() {
    f();
  }
}
''');
  }

  test_inExperimentalExtensionType() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
extension type E(int i) {
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalField() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class X {
  @experimental
  C f;
  X(this.f);
}
''');
  }

  test_inExperimentalFieldFormalParameter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class A {
  Object? o;
  A({@experimental C? this.o});
}
''');
  }

  test_inExperimentalFunction() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
g() {
  f();
}
''');
  }

  test_inExperimentalFunctionTypedFormalParameter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

f({@experimental C? callback()?}) {}
''');
  }

  test_inExperimentalLibrary() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
@experimental
library lib;
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class C {
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalMethod() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class C {
  @experimental
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalMethod_inExperimentalClass() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
class C {
  @experimental
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalMixin() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
mixin M {
  m() {
    f();
  }
}
''');
  }

  test_inExperimentalSimpleFormalParameter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

f({@experimental C? c}) {}
''');
  }

  test_inExperimentalSuperFormalParameter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class A {
  A({Object? o});
}
class B extends A {
  B({@experimental C? super.o});
}
''');
  }

  test_inExperimentalTopLevelVariable() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class C {}
var x = C();
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
C v = x;
''');
  }

  test_inExtension() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
void f() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
extension E on int {
  void m() {
    f();
//  ^
// [diag.experimentalMemberUse] 'f' is experimental and could be removed or changed at any time.
  }
}
''');
  }

  test_instanceCreation_experimentalClass_experimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  @experimental
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_instanceCreation_experimentalClass_unexperimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_instanceCreation_experimentalClass_unexperimentalNamedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  A.a();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A.a();
//^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_instanceCreation_namedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A.named(int i) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var a = A.named(1);
//      ^^^^^^^
// [diag.experimentalMemberUse] 'A.named' is experimental and could be removed or changed at any time.
''');
  }

  test_instanceCreation_namedConstructor_primary() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A.named() {
  @experimental
  this;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var a = A.named();
//      ^^^^^^^
// [diag.experimentalMemberUse] 'A.named' is experimental and could be removed or changed at any time.
''');
  }

  test_instanceCreation_unexperimentalClass_experimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_instanceCreation_unnamedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A(int i) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

f() {
  return new A(1);
//           ^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_methodInvocation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
//  ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
}
''');
  }

  test_methodInvocation_constantAnnotation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int f() => 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = f();
//      ^
// [diag.experimentalMemberUse] 'f' is experimental and could be removed or changed at any time.
''');
  }

  test_methodInvocation_constructorAnnotation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int f() => 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
var x = f();
//      ^
// [diag.experimentalMemberUse] 'f' is experimental and could be removed or changed at any time.
''');
  }

  test_methodInvocation_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib2.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_methodInvocation_inExperimentalConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
mixin A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
class B = Object with A;
''');
  }

  test_namedParameterMissingName() async {
    // This is a regression test; previously this code would cause an analyzer
    // crash in ExperimentalMemberUseVerifier.
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C({this.});
//         ^^^^^
// [diag.initializingFormalForNonExistentField] '' isn't a field in the enclosing class.
//              ^
// [diag.missingIdentifier] Expected an identifier.
}
var z = C(x: '');
//        ^
// [diag.undefinedNamedParameter] The named parameter 'x' isn't defined.
''');
  }

  test_operator() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  operator+(A a) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
f(A a, A b) {
  return a + b;
//       ^^^^^
// [diag.experimentalMemberUse] '+' is experimental and could be removed or changed at any time.
}
''');
  }

  test_parameter_named() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

void f({@experimental int x = 0}) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void g() => f(x: 1);
//            ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
''');
  }

  test_parameter_named_inDefiningConstructor_asFieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  int x;
  C({@experimental this.x = 0});
}
''');
  }

  test_parameter_named_inDefiningConstructor_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  C({@experimental int y = 0}) : assert(y > 0);
}
''');
  }

  test_parameter_named_inDefiningConstructor_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  int x;
  C({@experimental int y = 0}) : x = y;
}
''');
  }

  test_parameter_named_inDefiningConstructor_inFieldFormalParameter_notName() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {}

@experimental
class B extends A {
  const B();
}

const B instance = const B();
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class C {
  final A a;
  C({B this.a = instance});
//   ^
// [diag.experimentalMemberUse] 'B' is experimental and could be removed or changed at any time.
}
''');
  }

  test_parameter_named_inDefiningFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

f({@experimental int x = 0}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  m({@experimental int x = 0}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
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

  test_parameter_named_inPrimaryConstructor_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C({@experimental int y = 0}) {
  this : assert(y > 0);
}
''');
  }

  test_parameter_named_ofFunction() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

void foo({@experimental int a}) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
//    ^
// [diag.experimentalMemberUse] 'a' is experimental and could be removed or changed at any time.
}
''');
  }

  test_parameter_named_ofMethod() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void foo({@experimental int a}) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
//      ^
// [diag.experimentalMemberUse] 'a' is experimental and could be removed or changed at any time.
}
''');
  }

  test_parameter_positionalOptional() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void foo([@experimental int x = 0]) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(A a) {
  a.foo(0);
//      ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_parameter_positionalOptional_inExperimentalConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

void foo([@experimental int x = 0]) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class A {
  @experimental
  A() {
    foo(0);
  }
}
''');
  }

  test_parameter_positionalOptional_inExperimentalFunction() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void foo([@experimental int x = 0]) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

@experimental
void f(A a) {
  a.foo(0);
}
''');
  }

  test_parameter_positionalOptional_inExperimentalPrimaryConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

void foo([@experimental int x = 0]) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'package:aaa/a.dart';

class A() {
  @experimental
  this {
    foo(0);
  }
}
''');
  }

  test_parameter_positionalRequired() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void foo(@experimental int x) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(A a) {
  a.foo(0);
}
''');
  }

  test_postfixExpression_experimentalGetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x++;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_postfixExpression_experimentalNothing() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
int get x => 0;

set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x++;
}
''');
  }

  test_postfixExpression_experimentalSetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x++;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_prefixedIdentifier_identifier() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  static const foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  A.foo;
//  ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
}
''');
  }

  test_prefixedIdentifier_prefix() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {
  static const foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  A.foo;
//^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_prefixExpression_experimentalGetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int get x => 0;

set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  ++x;
//  ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_prefixExpression_experimentalSetter() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

int get x => 0;

@experimental
set x(int _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  ++x;
//  ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_propertyAccess_super() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  int get foo => 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class B extends A {
  void bar() {
    super.foo;
//        ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
  }
}
''');
  }

  test_redirectingConstructorInvocation_namedParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  A({@experimental int a = 0}) {}
  A.named() : this(a: 0);
}
''');
  }

  test_setterInvocation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  set foo(int _) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(A a) {
  a.foo = 0;
//  ^^^
// [diag.experimentalMemberUse] 'foo' is experimental and could be removed or changed at any time.
}
''');
  }

  test_showCombinator() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'package:aaa/a.dart' show A;
//                               ^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
''');
  }

  test_superConstructor_namedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A.named() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class B extends A {
  B() : super.named() {}
//      ^^^^^^^^^^^^^
// [diag.experimentalMemberUse] 'A.named' is experimental and could be removed or changed at any time.
}
''');
  }

  test_superConstructor_unnamedConstructor() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @experimental
  A() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class B extends A {
  B() : super() {}
//      ^^^^^^^
// [diag.experimentalMemberUse] 'A' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_argument() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  print(x);
//      ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_assignment_right() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(int a) {
  a = x;
//    ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_binaryExpression() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x + 1;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_constructorFieldInitializer() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
const int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class A {
  final int f;
  A() : f = x;
//          ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_expressionFunctionBody() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
int f() => x;
//         ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
''');
  }

  test_topLevelVariable_expressionStatement() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  x;
//^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_forElement_condition() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  [for (;x;) 0];
//       ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_forStatement_condition() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  for (;x;) {}
//      ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_ifElement_condition() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  [if (x) 0];
//     ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_ifStatement_condition() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  if (x) {}
//    ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_listLiteral() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  [x];
// ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_mapLiteralEntry() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  ({0: x, x: 0});
//     ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
//        ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_namedExpression() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void g({int a = 0}) {}
void f() {
  g(a: x);
//     ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_returnStatement() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
int f() {
  return x;
//       ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_setLiteral() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  ({x});
//  ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_spreadElement() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = [0];
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  [...x];
//    ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_switchCase() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
const int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f(int a) {
  switch (a) {
    case x:
//       ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
      break;
  }
}
''');
  }

  test_topLevelVariable_switchCase_language219() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
const int x = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
import 'package:aaa/a.dart';
void f(int a) {
  switch (a) {
    case x:
//       ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
      break;
  }
}
''');
  }

  test_topLevelVariable_switchStatement() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  switch (x) {}
//        ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_switchStatement_language219() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
import 'package:aaa/a.dart';
void f() {
  switch (x) {}
//        ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_unaryExpression() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
int x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  -x;
// ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_variableDeclaration_initializer() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  // ignore: unused_local_variable
  var v = x;
//        ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
  }

  test_topLevelVariable_whileStatement_condition() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
var x = true;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
void f() {
  while (x) {}
//       ^
// [diag.experimentalMemberUse] 'x' is experimental and could be removed or changed at any time.
}
''');
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
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar with Foo {}
//             ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
mixin M {}
import 'package:meta/meta.dart';

@experimental
mixin class Foo = Object with M;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar with Foo {}
//             ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_class() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar with Foo {}
//             ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_classTypeAlias() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar = Object with Foo;
//                      ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
''');
  }

  test_enum() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
enum Bar with Foo {
//            ^^^
// [diag.experimentalMemberUse] 'Foo' is experimental and could be removed or changed at any time.
  one, two;
}
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@experimental
mixin class Foo {}
class Bar with Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$aaaPackageRootPath/lib/a.dart', r'''
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';
class Bar with Foo {}
''');
  }
}

class _TestBase extends PubPackageResolutionTest {
  String get aaaPackageRootPath => '$workspaceRootPath/aaa';

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(aaaPackageRootPath)),
      meta: true,
    );
  }
}
