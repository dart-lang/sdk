// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:meta/meta.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUse_BasicWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_BazelWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_GnWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_PackageBuildWorkspaceTest);

    defineReflectiveTests(
      DeprecatedMemberUseFromSamePackage_BasicWorkspaceTest,
    );
    defineReflectiveTests(
      DeprecatedMemberUseFromSamePackage_BazelWorkspaceTest,
    );
    defineReflectiveTests(
      DeprecatedMemberUseFromSamePackage_PackageBuildWorkspaceTest,
    );
  });
}

@reflectiveTest
class DeprecatedMemberUse_BasicWorkspaceTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );
  }

  test_export() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
library a;
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode('''
export 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_fieldGet_implicitGetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_fieldSet_implicitSetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_import() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
library a;
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
// ignore:unused_import
import 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 24, 28,
          messageContains: 'package:aaa/a.dart'),
    ]);
  }

  test_methodInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  void foo() {}
}
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_methodInvocation_withMessage() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @Deprecated('0.9')
  void foo() {}
}
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 48, 3),
    ]);
  }

  test_setterInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  set foo(int _) {}
}
''');

    assertBasicWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUse_BazelWorkspaceTest
    extends BazelWorkspaceResolutionTest {
  test_dart() async {
    newFile('$workspaceRootPath/foo/bar/lib/a.dart', content: r'''
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
    newFile('$workspaceThirdPartyDartPath/aaa/lib/a.dart', content: r'''
@deprecated
class A {}
''');

    assertBazelWorkspaceFor(testFilePath);

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

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/my';

  @override
  String get testFilePath => '$myPackageLibPath/my.dart';

  String get workspaceRootPath => '/workspace';

  @override
  void setUp() {
    super.setUp();
    newFolder('$workspaceRootPath/.jiri_root');
  }

  test_differentPackage() async {
    newFile('$workspaceRootPath/my/pubspec.yaml');
    newFile('$workspaceRootPath/my/BUILD.gn');

    newFile('$workspaceRootPath/aaa/pubspec.yaml');
    newFile('$workspaceRootPath/aaa/BUILD.gn');

    _writeWorkspacePackagesFile({
      'aaa': '$workspaceRootPath/aaa/lib',
      'my': myPackageLibPath,
    });

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
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

  test_samePackage() async {
    newFile('$workspaceRootPath/my/pubspec.yaml');
    newFile('$workspaceRootPath/my/BUILD.gn');

    _writeWorkspacePackagesFile({
      'my': myPackageLibPath,
    });

    newFile('$myPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:my/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 36, 1),
    ]);
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertGnWorkspaceFor(testFilePath);
  }

  void _writeWorkspacePackagesFile(Map<String, String> nameToLibPath) {
    var builder = StringBuffer();
    for (var entry in nameToLibPath.entries) {
      builder.writeln('${entry.key}:${toUriStr(entry.value)}');
    }

    var buildDir = 'out/debug-x87_128';
    var genPath = '$workspaceRootPath/$buildDir/dartlang/gen';
    newFile('$genPath/foo.packages', content: builder.toString());
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

    newFile('$testPackageRootPath/pubspec.yaml', content: 'name: test');
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

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
class A {}
''');

    newFile('$testPackageRootPath/pubspec.yaml', content: 'name: test');
    _createTestPackageBuildMarker();

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackage_BasicWorkspaceTest
    extends PubPackageResolutionTest {
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 67, 3),
    ]);
  }

  test_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 77, 6),
    ]);
  }

  test_export() async {
    newFile('$testPackageLibPath/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');
    await assertErrorsInCode('''
export 'deprecated_library.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 60, 1),
    ]);
  }

  test_import() async {
    newFile('$testPackageLibPath/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 67, 4),
    ]);
  }

  test_instanceCreation_namedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A.named(int i) {}
}
f() {
  return new A.named(1);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 65, 7),
    ]);
  }

  test_instanceCreation_unnamedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A(int i) {}
}
f() {
  return new A(1);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_methodInvocation_constant() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  m() {}
  n() {
    m();
  }
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 45, 1),
    ]);
  }

  test_methodInvocation_constructor() async {
    await assertErrorsInCode(r'''
class A {
  @Deprecated('0.9')
  m() {}
  n() {m();}
}
''', [
      error(
          HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE, 47, 1),
    ]);
  }

  test_operator() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  operator+(A a) {}
}
f(A a, A b) {
  return a + b;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 69, 5),
    ]);
  }

  test_parameter_named() async {
    await assertErrorsInCode(r'''
class A {
  m({@deprecated int x}) {}
  n() {m(x: 1);}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 47, 1),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 47, 1),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 60, 1),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 69, 13),
    ]);
  }

  test_superConstructor_unnamedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A() {}
}
class B extends A {
  B() : super() {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 63, 7),
    ]);
  }

  test_topLevelVariable() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

int f() {
  return x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 43, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackage_BazelWorkspaceTest
    extends BazelWorkspaceResolutionTest {
  test_it() async {
    newFile('$myPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackage_PackageBuildWorkspaceTest
    extends _PackageBuildWorkspaceBase {
  test_generated() async {
    newFile('$testPackageRootPath/pubspec.yaml', content: 'name: test');

    _newTestPackageGeneratedFile(
      packageName: 'test',
      pathInLib: 'a.dart',
      content: r'''
@deprecated
class A {}
''',
    );

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }

  test_lib() async {
    newFile('$testPackageRootPath/pubspec.yaml', content: 'name: test');
    _createTestPackageBuildMarker();

    newFile('$testPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }
}

class _PackageBuildWorkspaceBase extends PubPackageResolutionTest {
  String get testPackageGeneratedPath {
    return '$testPackageRootPath/.dart_tool/build/generated';
  }

  @override
  void setUp() {
    super.setUp();
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertPackageBuildWorkspaceFor(testFilePath);
  }

  void _createTestPackageBuildMarker() {
    newFolder(testPackageGeneratedPath);
  }

  void _newTestPackageGeneratedFile({
    @required String packageName,
    @required String pathInLib,
    @required String content,
  }) {
    newFile(
      '$testPackageGeneratedPath/$packageName/lib/$pathInLib',
      content: content,
    );
  }
}
