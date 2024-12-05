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
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart' hide A;
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_export_show() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart' show A;
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_fromIntegrationTestDirectory() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    var test = newFile('$testPackageRootPath/integration_test/test.dart', r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(test, []);
  }

  test_fromTestDirectory() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(test, []);
  }

  test_fromTestDriverDirectory() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    var test = newFile('$testPackageRootPath/test_driver/test.dart', r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(test, []);
  }

  test_fromTestingDirectory() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    var lib2 = newFile('$testPackageRootPath/testing/lib2.dart', r'''
import '../lib1.dart';
class C {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_functionInExtension() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  E([]).m();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 42, 1),
    ]);
  }

  test_functionInExtension_fromTestDirectory() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import '../lib1.dart';
void main() {
  E([]).m();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(test, []);
  }

  test_getter() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A().a;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 44, 1),
    ]);
  }

  test_getter_inObjectPattern() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get g => 7;
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void f(Object o) {
  switch (o) {
    case A(g: 7): print('yes');
  }
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 65, 1),
    ]);
  }

  test_import_hide() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' hide A;

void f(B _) {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_import_show() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' show A;

void f(A _) {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 21, 1),
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 32, 1),
    ]);
  }

  test_method() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 52, 1),
    ]);
  }

  test_method_fromOverride_visibleForOverriding() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForOverriding
  @visibleForTesting
  void a(){ }
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
class B extends A {
  void a() => super.a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_methodInExtensionType() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @visibleForTesting
  int m() => 1;
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  E(1).m();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 41, 1),
    ]);
  }

  test_methodInExtensionType_fromTestDirectory() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @visibleForTesting
  int m() => 1;
}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
import '../lib1.dart';
void main() {
  E(1).m();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(test, []);
  }

  test_mixin() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
mixin M {
  @visibleForTesting
  int m() => 1;
}
class C with M {}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  C().m();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 1),
    ]);
  }

  test_namedConstructor() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A.forTesting(this._x);
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A.forTesting(0);
}
''');

    await assertErrorsInFile2(lib1, [
      error(WarningCode.UNUSED_FIELD, 49, 2),
    ]);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 12,
          messageContains: ['A.forTesting']),
    ]);
  }

  test_protectedAndForTesting_usedAsProtected() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
class B extends A {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_protectedAndForTesting_usedAsTesting() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    var test1 = newFile('$testPackageRootPath/test/test1.dart', r'''
import '../lib1.dart';
void main() {
  new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(test1, []);
  }

  test_setter() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  set b(_) => 7;
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A().b = 6;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 44, 1),
    ]);
  }

  test_topLevelFunction() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int fn0() => 1;
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  fn0();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 36, 3),
    ]);
  }

  test_topLevelVariable() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int a = 7;
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  a;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 36, 1),
    ]);
  }

  test_unnamedConstructor() async {
    var lib1 = newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A(this._x);
}
''');
    var lib2 = newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A(0);
}
''');

    await assertErrorsInFile2(lib1, [
      error(WarningCode.UNUSED_FIELD, 49, 2),
    ]);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 1),
    ]);
  }
}
