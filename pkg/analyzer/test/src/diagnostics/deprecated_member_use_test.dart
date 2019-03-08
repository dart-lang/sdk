// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUseFromSamePackageTest);
    defineReflectiveTests(DeprecatedMemberUseTest);
  });
}

@reflectiveTest
class DeprecatedMemberUseTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  /// Write a pubspec file at [root], so that BestPracticesVerifier can see that
  /// [root] is the root of a PubWorkspace, and a PubWorkspacePackage.
  void newPubPackage(String root) {
    newFile('$root/pubspec.yaml');
  }

  test_methodInvocation_contructor() async {
    resetWithFooLibrary(r'''
class A {
  @Deprecated('0.9')
  m() {}
}
''');

    newPubPackage('/pkg1');
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

    newPubPackage('/pkg1');
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

    newPubPackage('/pkg1');
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

    newPubPackage('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
import 'package:foo/foo.dart';
f(A a) {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    this.verify([source]);
    TestAnalysisResult result = analysisResults[source];
    expect(result.errors[0].message, contains('package:foo/foo.dart'));
  }

  test_basicWorkspace() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
f(A a) {}
''', // This is a cross-package deprecated member usage.
        [HintCode.DEPRECATED_MEMBER_USE],
        sourceName: '/workspace/project/lib/lib1.dart');
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

    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
f(A a) {}
''', // This is a cross-package deprecated member usage.
        [HintCode.DEPRECATED_MEMBER_USE],
        sourceName: '/workspace/project/lib/lib1.dart');
  }

  test_bazelWorkspace_sameWorkspace() async {
    newFile('/workspace/WORKSPACE');
    newFile('/workspace/project_a/BUILD');
    newFile('/workspace/project_b/BUILD');
    newFolder('/workspace/bazel-genfiles');

    addNamedSource('/workspace/project_a/lib/deprecated_library.dart', r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import '../../project_a/lib/deprecated_library.dart';
f(A a) {}
''', // This is a same-workspace, cross-package deprecated member usage.
        [HintCode.DEPRECATED_MEMBER_USE],
        sourceName: '/workspace/project_b/lib/lib1.dart');
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
    newFile('/workspace/.config',
        content: 'FOO=foo\n'
            'FUCHSIA_BUILD_DIR=$buildDir\n'
            'BAR=bar\n');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/project/foo.packages');

    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
f(A a) {}
''', // This is a cross-package deprecated member usage.
        [HintCode.DEPRECATED_MEMBER_USE],
        sourceName: '/workspace/project/lib/lib1.dart');
  }

  test_gnWorkspace_sameWorkspace() async {
    newFolder('/workspace/.jiri_root');
    newFile('/workspace/project_a/pubspec.yaml');
    newFile('/workspace/project_b/pubspec.yaml');
    newFile('/workspace/project_a/BUILD.gn');
    newFile('/workspace/project_b/BUILD.gn');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config',
        content: 'FOO=foo\n'
            'FUCHSIA_BUILD_DIR=$buildDir\n');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/project_a/foo.packages');

    addNamedSource('/workspace/project_a/lib/deprecated_library.dart', r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import '../../project_a/lib/deprecated_library.dart';
f(A a) {}
''', // This is a same-workspace, cross-package deprecated member usage.
        [HintCode.DEPRECATED_MEMBER_USE],
        sourceName: '/workspace/project_b/lib/lib1.dart');
  }

  test_packageBuildWorkspace() async {
    resetWithFooLibrary(r'''
@deprecated
library deprecated_library;
class A {}
''');

    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    assertErrorsInCode(r'''
import 'package:foo/foo.dart';
f(A a) {}
''', // This is a cross-package deprecated member usage.
        [HintCode.DEPRECATED_MEMBER_USE],
        sourceName: '/workspace/package/lib/lib1.dart');
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackageTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

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

  test_basicWorkspace() async {
    addNamedSource('/workspace/lib/deprecated_library.dart', r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE],
        sourceName: '/workspace/lib/lib1.dart');
  }

  test_bazelWorkspace() async {
    newFile('/workspace/WORKSPACE');
    newFile('/workspace/project/BUILD');
    newFolder('/workspace/bazel-genfiles');

    addNamedSource('/workspace/project/lib/deprecated_library.dart', r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE],
        sourceName: '/workspace/project/lib/lib1.dart');
  }

  test_gnWorkspace() async {
    newFolder('/workspace/.jiri_root');
    newFile('/workspace/project/pubspec.yaml');
    newFile('/workspace/project/BUILD.gn');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config',
        content: 'FOO=foo\n'
            'FUCHSIA_BUILD_DIR=$buildDir\n');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/project/foo.packages');

    addNamedSource('/workspace/project/lib/deprecated_library.dart', r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE],
        sourceName: '/workspace/project/lib/lib1.dart');
  }

  test_packageBuildWorkspace() async {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    newFileWithBytes('/workspace/.packages', 'project:lib/'.codeUnits);

    addNamedSource('/workspace/lib/deprecated_library.dart', r'''
@deprecated
library deprecated_library;
class A {}
''');

    assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE],
        sourceName: '/workspace/lib/lib1.dart');
  }
}
