// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUseFromSamePackageTest);
    defineReflectiveTests(DeprecatedMemberUseTest);
  });
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackageTest extends DriverResolutionTest {
  test_basicWorkspace() async {
    configureWorkspace(root: '/workspace');

    newFile('/workspace/lib/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInFile('/workspace/lib/test.dart', r'''
import 'deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
  }

  test_bazelWorkspace() async {
    configureWorkspace(root: '/workspace');

    newFile('/workspace/WORKSPACE');
    newFile('/workspace/project/BUILD');
    newFolder('/workspace/bazel-genfiles');

    newFile('/workspace/project/lib/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInFile('/workspace/project/lib/lib1.dart', r'''
import 'deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
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
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 67, 3),
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
    newFile("/test/lib/deprecated_library.dart", content: r'''
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

  test_gnWorkspace() async {
    configureWorkspace(root: '/workspace');

    newFolder('/workspace/.jiri_root');
    newFile('/workspace/project/pubspec.yaml');
    newFile('/workspace/project/BUILD.gn');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config', content: '''
FOO=foo
FUCHSIA_BUILD_DIR=$buildDir
''');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/project/foo.packages');

    newFile('/workspace/project/lib/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInFile('/workspace/project/lib/lib1.dart', r'''
import 'deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
  }

  test_import() async {
    newFile("/test/lib/deprecated_library.dart", content: r'''
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

  test_packageBuildWorkspace() async {
    configureWorkspace(root: '/workspace');

    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    newFileWithBytes('/workspace/.packages', 'project:lib/'.codeUnits);

    newFile('/workspace/lib/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInFile('/workspace/lib/lib1.dart', r'''
import 'deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
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
}

@reflectiveTest
class DeprecatedMemberUseTest extends DriverResolutionTest {
  /// Write a pubspec file at [root], so that BestPracticesVerifier can see that
  /// [root] is the root of a PubWorkspace, and a PubWorkspacePackage.
  void newPubPackage(String root) {
    newFile('$root/pubspec.yaml');
  }

  void resetWithFooLibrary(String content) {
    newFile('/aaa/lib/a.dart', content: content);
  }

  test_basicWorkspace() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_bazelWorkspace() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newFile('/workspace/WORKSPACE');
    newFile('/workspace/project/BUILD');
    newFolder('/workspace/bazel-genfiles');

    await assertErrorsInFile('/workspace/project/lib/lib1.dart', r'''
import 'package:aaa/a.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_bazelWorkspace_sameWorkspace() async {
    newFile('/workspace/WORKSPACE');
    newFile('/workspace/project_a/BUILD');
    newFile('/workspace/project_b/BUILD');
    newFolder('/workspace/bazel-genfiles');

    newFile('/workspace/project_a/lib/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInFile('/workspace/project_b/lib/lib1.dart', r'''
import '../../project_a/lib/deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 53),
    ]);
  }

  test_export() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newPubPackage('/pkg1');
    await assertErrorsInFile('/pkg1/lib/lib1.dart', '''
export 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_fieldGet_implicitGetter() async {
    resetWithFooLibrary(r'''
class A {
  @Deprecated('0.9')
  bool bob = true;
}
''');

    newPubPackage('/pkg1');
    await assertErrorsInFile('/pkg1/lib/lib1.dart', r'''
import 'package:aaa/a.dart';
void main() { A().bob; }
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 47, 3),
    ]);
  }

  test_fieldSet_implicitSetter() async {
    resetWithFooLibrary(r'''
class A {
  @Deprecated('0.9')
  bool bob = true;
}
''');

    newPubPackage('/pkg1');
    await assertErrorsInFile('/pkg1/lib/lib1.dart', r'''
import 'package:aaa/a.dart';
void main() { A().bob = false; }
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 47, 3),
    ]);
  }

  test_gnWorkspace() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newFolder('/workspace/.jiri_root');
    newFile('/workspace/project/pubspec.yaml');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config', content: '''
FOO=foo
FUCHSIA_BUILD_DIR=$buildDir
BAR=bar
''');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/project/foo.packages');

    await assertErrorsInFile('/workspace/project/lib/lib1.dart', r'''
import 'package:aaa/a.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_gnWorkspace_sameWorkspace() async {
    newFolder('/workspace/.jiri_root');
    newFile('/workspace/project_a/pubspec.yaml');
    newFile('/workspace/project_b/pubspec.yaml');
    newFile('/workspace/project_a/BUILD.gn');
    newFile('/workspace/project_b/BUILD.gn');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config', content: '''
FOO=foo
FUCHSIA_BUILD_DIR=$buildDir
''');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/project_a/foo.packages');

    newFile('/workspace/project_a/lib/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInFile('/workspace/project_b/lib/lib1.dart', r'''
import '../../project_a/lib/deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 53),
    ]);
  }

  test_import() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    await resolveTestCode(r'''
import 'package:aaa/a.dart';
f(A a) {}
''');
    expect(result.errors[0].message, contains('package:aaa/a.dart'));
  }

  test_methodInvocation_constant() async {
    resetWithFooLibrary(r'''
class A {
  @deprecated
  m() {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';
void main() => A().m();
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 1),
    ]);
  }

  test_methodInvocation_constructor() async {
    resetWithFooLibrary(r'''
class A {
  @Deprecated('0.9')
  m() {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';
void main() => A().m();
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 48, 1),
    ]);
  }

  test_packageBuildWorkspace() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);

    await assertErrorsInFile('/workspace/package/lib/lib1.dart', r'''
import 'package:aaa/a.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_setterInvocation_constructor() async {
    resetWithFooLibrary(r'''
class A {
  @Deprecated('0.9')
  set bob(bool b) { }
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';
void main() { A().bob = false; }
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 47, 3),
    ]);
  }
}
