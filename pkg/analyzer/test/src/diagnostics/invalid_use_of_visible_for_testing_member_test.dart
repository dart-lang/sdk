// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTestingMemberTest);
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

  test_export_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    await assertNoErrorsInCode(r'''
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

    await assertNoErrorsInCode(r'''
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
    var test = newFile('$testPackageRootPath/integration_test/test.dart', r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');

    await assertErrorsInFile2(test, []);
  }

  test_fromTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');

    await assertErrorsInFile2(test, []);
  }

  test_fromTestDriverDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');
    var test = newFile('$testPackageRootPath/test_driver/test.dart', r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');

    await assertErrorsInFile2(test, []);
  }

  test_fromTestingDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');
    var lib2 = newFile('$testPackageRootPath/testing/lib2.dart', r'''
import 'package:test/lib1.dart';
void f() => A().a();
''');

    await assertErrorsInFile2(lib2, []);
  }

  test_functionInExtension() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  E([]).m();
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 39, 1)],
    );
  }

  test_functionInExtension_fromTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import 'package:test/lib1.dart';
void f() {
  E([]).m();
}
''');

    await assertErrorsInFile2(test, []);
  }

  test_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;
}
''');
    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  A().a;
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 37, 1)],
    );
  }

  test_getter_inObjectPattern() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get g => 7;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
void f(Object o) {
  switch (o) {
    case A(g: 7): print('yes');
  }
}
''');

    await assertErrorsInFile2(lib2, [
      error(WarningCode.invalidUseOfVisibleForTestingMember, 65, 1),
    ]);
  }

  test_import_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    await assertNoErrorsInCode(r'''
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

    await assertErrorsInCode(
      r'''
import 'a.dart' show A;

void f(A _) {}
''',
      [
        error(WarningCode.invalidUseOfVisibleForTestingMember, 21, 1),
        error(WarningCode.invalidUseOfVisibleForTestingMember, 32, 1),
      ],
    );
  }

  test_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a() {}
}
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() => A().a();
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 36, 1)],
    );
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

    await assertNoErrorsInCode(r'''
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

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  E(1).m();
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 38, 1)],
    );
  }

  test_methodInExtensionType_fromTestDirectory() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @visibleForTesting
  int m() => 1;
}
''');

    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import 'package:test/lib1.dart';
void f() {
  E(1).m();
}
''');

    await assertErrorsInFile2(test, []);
  }

  test_mixin() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
mixin A {
  @visibleForTesting
  int m() => 1;
}
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f(A a) {
  a.m();
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 38, 1)],
    );
  }

  test_namedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  A.forTesting();
}
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  A.forTesting();
}
''',
      [
        error(
          WarningCode.invalidUseOfVisibleForTestingMember,
          33,
          12,
          messageContains: ['A.forTesting'],
        ),
      ],
    );
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

    await assertNoErrorsInCode(r'''
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

    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import 'package:test/lib1.dart';
void f() {
  A().a();
}
''');

    await assertErrorsInFile2(test, []);
  }

  test_setter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  set b(_) => 7;
}
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  A().b = 6;
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 37, 1)],
    );
  }

  test_topLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int f() => 1;
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void g() {
  f();
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 33, 1)],
    );
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int a = 7;
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  a;
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 33, 1)],
    );
  }

  test_unnamedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  A();
}
''');

    await assertErrorsInCode(
      r'''
import 'lib1.dart';
void f() {
  A();
}
''',
      [error(WarningCode.invalidUseOfVisibleForTestingMember, 33, 1)],
    );
  }
}
