// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfInternalMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfInternalMemberTest extends PubPackageResolutionTest {
  String get fooPackageRootPath => '$workspaceRootPath/foo';

  @override
  String get testPackageRootPath => '/home/my';

  @override
  void setUp() {
    super.setUp();
    newAnalysisOptionsYamlFile(
      fooPackageRootPath,
      analysisOptionsContent(experiments: experiments),
    );
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder(fooPackageRootPath)),
      meta: true,
    );
  }

  test_insidePackage() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    var a = getFile('$fooPackageRootPath/lib/a.dart');
    await resolveFileWithDiagnostics(a, '''
import 'src/a.dart';

A a = A();
''');
  }

  test_insidePackage_extensionType() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
extension type E(int i) {}
''');

    var a = getFile('$fooPackageRootPath/lib/a.dart');
    await resolveFileWithDiagnostics(a, '''
import 'src/a.dart';

E e = E(1);
''');
  }

  test_outsidePackage_class() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

A a = A();
// [diag.invalidUseOfInternalMember][column 1][length 1] The member 'A' can only be used within its package.
''');
  }

  test_outsidePackage_class_inAsExpression() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

void f(Object o) {
  o as A;
//     ^
// [diag.invalidUseOfInternalMember] The member 'A' can only be used within its package.
}
''');
  }

  test_outsidePackage_class_inCastPattern() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

void f(Object a, Object b) {
  (b as A, ) = (a, );
//      ^
// [diag.invalidUseOfInternalMember] The member 'A' can only be used within its package.
}
''');
  }

  test_outsidePackage_class_inIsExpression() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

void f(Object o) {
  o is A;
//     ^
// [diag.invalidUseOfInternalMember] The member 'A' can only be used within its package.
}
''');
  }

  test_outsidePackage_class_inObjectPattern() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

void f(Object a, Object b) {
  switch (a) {
    case A(): print('yes');
//       ^
// [diag.invalidUseOfInternalMember] The member 'A' can only be used within its package.
  }
}
''');
  }

  test_outsidePackage_class_inVariableDeclarationType() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

A? a;
// [diag.invalidUseOfInternalMember][column 1][length 1] The member 'A' can only be used within its package.
''');
  }

  test_outsidePackage_constructor_named() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  C.named();
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

C a = C.named();
//    ^^^^^^^
// [diag.invalidUseOfInternalMember] The member 'C.named' can only be used within its package.
''');
  }

  test_outsidePackage_constructor_primary() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C() {
  @internal
  this;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

C a = C();
//    ^
// [diag.invalidUseOfInternalMember] The member 'C' can only be used within its package.
''');
  }

  test_outsidePackage_constructor_unnamed() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  C();
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

C a = C();
//    ^
// [diag.invalidUseOfInternalMember] The member 'C' can only be used within its package.
''');
  }

  test_outsidePackage_enum() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
enum E {one}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

void f(E value) {}
//     ^
// [diag.invalidUseOfInternalMember] The member 'E' can only be used within its package.
''');
  }

  test_outsidePackage_enumValue() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
enum E {@internal one}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

E f() => E.one;
//         ^^^
// [diag.invalidUseOfInternalMember] The member 'one' can only be used within its package.
''');
  }

  test_outsidePackage_extensionMethod() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
extension E on String {
  @internal
  int f() => 1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = 'hello'.f();
//              ^
// [diag.invalidUseOfInternalMember] The member 'f' can only be used within its package.
''');
  }

  test_outsidePackage_extensionType() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
extension type E(int i) {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

E e = E(1);
// [diag.invalidUseOfInternalMember][column 1][length 1] The member 'E' can only be used within its package.
''');
  }

  test_outsidePackage_field() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class A {
  @internal
  int a = 42;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

var a = A().a;
//          ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_field_inObjectPattern() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class A {
  @internal
  int get a => 42;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

void f(Object o) {
  switch (o) {
    case A(a: 7): print('yes');
//         ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
  }
}
''');
  }

  test_outsidePackage_field_originPrimaryConstructor() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class A(@internal final int a);
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

var a = A(7).a;
//           ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_function() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a() => 1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int b = a() + 1;
//      ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_function_generic() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a<T>() => 1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int b = a<void>() + 1;
//      ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_function_generic_tearoff() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a<T>() => 1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int Function() b = a;
//                 ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_function_tearoff() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a() => 1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int Function() b = a;
//                 ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_functionLiteralForInternalTypedef() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
@internal
typedef IntFunc = int Function(int);
int foo(IntFunc f, int x) => f(x);
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int g() => foo((x) => 2*x, 7);
''');
  }

  test_outsidePackage_inCommentReference() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int get a => 1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

/// This is quite similar to [a].
int b = 1;
''');
  }

  test_outsidePackage_library() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
@internal
library a;
import 'package:meta/meta.dart';
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';
// [diag.invalidUseOfInternalMember][column 1][length 32] The member 'package:foo/src/a.dart' can only be used within its package.
//     ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'package:foo/src/a.dart'.
''');
  }

  test_outsidePackage_method() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  int m() => 1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = C().m();
//          ^
// [diag.invalidUseOfInternalMember] The member 'm' can only be used within its package.
''');
  }

  test_outsidePackage_method_generic() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  int m<T>() => 1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = C().m<void>();
//          ^
// [diag.invalidUseOfInternalMember] The member 'm' can only be used within its package.
''');
  }

  test_outsidePackage_method_subclassed() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal int f() => 1;
}

class D extends C {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = D().f();
//          ^
// [diag.invalidUseOfInternalMember] The member 'f' can only be used within its package.
''');
  }

  test_outsidePackage_method_subclassed_overridden() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal int f() => 1;
}

class D extends C {
  int f() => 2;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = D().f();
''');
  }

  test_outsidePackage_method_tearoff() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  int m() => 1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int Function() a = C().m;
//                     ^
// [diag.invalidUseOfInternalMember] The member 'm' can only be used within its package.
''');
  }

  test_outsidePackage_methodParameter_named() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int m({@internal int a = 0}) => 1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = C().m(a: 5);
//            ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/28066')
  test_outsidePackage_methodParameter_positional() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int m([@internal int a = 0]) => 1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int a = C().m(5);
//            ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_mixin() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
mixin A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

class C with A {}
//           ^
// [diag.invalidUseOfInternalMember] The member 'A' can only be used within its package.
''');
  }

  test_outsidePackage_pairedWithProtected() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  @protected
  void f() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

class D extends C {
  void g() => f();
//            ^
// [diag.invalidUseOfInternalMember] The member 'f' can only be used within its package.
}
''');
  }

  test_outsidePackage_parameter_inPrimaryConstructor() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C({@internal final int a = 0});
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

var a = C(a: 7);
//        ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_redirectingFactoryConstructor() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
import 'package:test/test.dart';
class D implements C {
  @internal D();
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

class C {
  factory C() = D;
//              ^
// [diag.invalidUseOfInternalMember] The member 'D' can only be used within its package.
}
''');
  }

  test_outsidePackage_setter() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  set s(int value) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

f() {
  C().s = 7;
//    ^
// [diag.invalidUseOfInternalMember] The member 's' can only be used within its package.
}
''');
  }

  test_outsidePackage_setter_compound() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int get s() => 1;

  @internal
  set s(int value) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

f() {
  C().s += 7;
//    ^
// [diag.invalidUseOfInternalMember] The member 's' can only be used within its package.
}
''');
  }

  test_outsidePackage_setter_questionQuestion() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int? get s() => 1;

  @internal
  set s(int value) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

f() {
  C().s ??= 7;
//    ^
// [diag.invalidUseOfInternalMember] The member 's' can only be used within its package.
}
''');
  }

  test_outsidePackage_superConstructor() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal C();
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

class D extends C {
  D() : super();
//      ^^^^^^^
// [diag.invalidUseOfInternalMember] The member 'new' can only be used within its package.
}
''');
  }

  test_outsidePackage_superConstructor_named() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal C.named();
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

class D extends C {
  D() : super.named();
//            ^^^^^
// [diag.invalidUseOfInternalMember] The member 'named' can only be used within its package.
}
''');
  }

  test_outsidePackage_topLevelGetter() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int get a => 1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

int b = a + 1;
//      ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_typedef() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
typedef t = void Function();
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:foo/src/a.dart';

t func = () {};
// [diag.invalidUseOfInternalMember][column 1][length 1] The member 't' can only be used within its package.
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/28066')
  test_outsidePackage_typedefParameter() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
typedef T = void Function({@internal int a = 1});
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/src/a.dart';

void f(T t) => t(a: 5);
//               ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_variable() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/src/a.dart';

int b = a + 1;
//      ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }

  test_outsidePackage_variable_prefixed() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a = 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/src/a.dart' as foo;

int b = foo.a + 1;
//          ^
// [diag.invalidUseOfInternalMember] The member 'a' can only be used within its package.
''');
  }
}
