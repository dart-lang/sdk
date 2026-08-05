// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTestingMemberTest);
    defineReflectiveTests(
      InvalidUseOfVisibleForTestingMemberWithTestInAncestorPathTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTestingMemberTest extends PubPackageResolutionTest {
  @override
  String get testPackageRootPath => '/home/my';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constructor_primary() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A.named() {
  @visibleForTesting
  this;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  A.named();
//^^^^^^^
// [diag.invalidUseOfVisibleForTestingMember] The member 'A.named' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_export_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'a.dart' hide A;
''');
  }

  test_export_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'a.dart' show A;
''');
  }

  test_fromIntegrationTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    var file = getFile('$testPackageRootPath/integration_test/test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');
  }

  test_fromTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    var file = getFile('$testPackageRootPath/test/test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');
  }

  test_fromTestDriverDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    var file = getFile('$testPackageRootPath/test_driver/test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');
  }

  test_fromTestingDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    var lib2 = getFile('$testPackageRootPath/testing/lib2.dart');
    await resolveFileWithDiagnostics(lib2, r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');
  }

  test_functionInExtension() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  E([]).m();
//      ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'm' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_functionInExtension_fromTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');

    var file = getFile('$testPackageRootPath/test/test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:test/lib1.dart';
void f() {
  E([]).m();
}
''');
  }

  test_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  A().a;
//    ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'a' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_getter_inObjectPattern() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get g => 7;
}
''');

    var lib2 = getFile('$testPackageLibPath/lib2.dart');
    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
void f(Object o) {
  switch (o) {
    case A(g: 7): print('yes');
//         ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'g' can only be used within 'package:test/lib1.dart' or a test.
  }
}
''');
  }

  test_import_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' hide A;

void f(B _) {}
''');
  }

  test_import_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show A;
//                   ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'A' can only be used within 'package:test/a.dart' or a test.

void f(A _) {}
//     ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'A' can only be used within 'package:test/a.dart' or a test.
''');
  }

  test_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() => A().a();
//              ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'a' can only be used within 'package:test/lib1.dart' or a test.
''');
  }

  test_method_fromOverride_visibleForOverriding() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForOverriding
  @visibleForTesting
  void a() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
class B extends A {
  void a() => super.a();
}
''');
  }

  test_methodInExtensionType() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @visibleForTesting
  int m() => 1;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  E(1).m();
//     ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'm' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_methodInExtensionType_fromTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @visibleForTesting
  int m() => 1;
}
''');

    var file = getFile('$testPackageRootPath/test/test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:test/lib1.dart';
void f() {
  E(1).m();
}
''');
  }

  test_mixin() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
mixin A {
  @visibleForTesting
  int m() => 1;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f(A a) {
  a.m();
//  ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'm' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_namedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  A.forTesting();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  A.forTesting();
//^^^^^^^^^^^^
// [diag.invalidUseOfVisibleForTestingMember] The member 'A.forTesting' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_protectedAndForTesting_usedAsProtected() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
class B extends A {
  void b() => A().a();
}
''');
  }

  test_protectedAndForTesting_usedAsTesting() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a() {}
}
''');

    var file = getFile('$testPackageRootPath/test/test.dart');
    await resolveFileWithDiagnostics(file, r'''
import 'package:test/lib1.dart';
void f() {
  A().a();
}
''');
  }

  test_setter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  set b(_) => 7;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  A().b = 6;
//    ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'b' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_topLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int f() => 1;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void g() {
  f();
//^
// [diag.invalidUseOfVisibleForTestingMember] The member 'f' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int a = 7;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  a;
//^
// [diag.invalidUseOfVisibleForTestingMember] The member 'a' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }

  test_unnamedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() {
  A();
//^
// [diag.invalidUseOfVisibleForTestingMember] The member 'A' can only be used within 'package:test/lib1.dart' or a test.
}
''');
  }
}

@reflectiveTest
class InvalidUseOfVisibleForTestingMemberWithTestInAncestorPathTest
    extends PubPackageResolutionTest {
  @override
  String get testPackageRootPath => '/home/test/my';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_method_inAncestorTestDir() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart';
void f() => A().a();
//              ^
// [diag.invalidUseOfVisibleForTestingMember] The member 'a' can only be used within 'package:test/lib1.dart' or a test.
''');
  }
}
