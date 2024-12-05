// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingMethodAndFieldTest);
  });
}

@reflectiveTest
class ConflictingMethodAndFieldTest extends PubPackageResolutionTest {
  test_class_inSuper_field() async {
    await assertErrorsInCode(r'''
class A {
  int foo = 0;
}
class B extends A {
  foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 49, 3),
    ]);
  }

  test_class_inSuper_getter() async {
    await assertErrorsInCode(r'''
class A {
  get foo => 0;
}
class B extends A {
  foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 50, 3),
    ]);
  }

  test_class_inSuper_getter_hasAugmentation_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  int get foo => 0;
}

class B extends A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B {
  void foo() {}
}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 44, 3),
    ]);
  }

  test_class_inSuper_getter_hasAugmentation_inDeclaration() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  int get foo => 0;
}

class B extends A {
  void foo() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B {}
''');

    await assertErrorsInFile2(a, [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 76, 3),
    ]);

    await assertErrorsInFile2(b, []);
  }

  test_class_inSuper_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 50, 3),
    ]);
  }

  test_enum_inMixin_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 61, 3),
    ]);
  }

  test_enum_inMixin_getter_hasAugmentation_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

mixin M {
  int get foo => 0;
}

enum E with M {v}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment enum E {;
  void foo() {}
}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 44, 3),
    ]);
  }

  test_enum_inMixin_getter_hasAugmentation_inDeclaration() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  void foo() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment enum E {}
''');

    await assertErrorsInFile2(a, [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 77, 3),
    ]);

    await assertErrorsInFile2(b, []);
  }

  test_enum_inMixin_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 61, 3),
    ]);
  }

  test_extensionType_field_external() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  external int foo;
}

extension type B(int it) implements A {
  void foo() {}
}
''');
  }

  test_extensionType_getter() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  void foo() {}
}
''');
  }

  test_extensionType_setter() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  set foo(int _) {}
}

extension type B(int it) implements A {
  void foo() {}
}
''');
  }
}
