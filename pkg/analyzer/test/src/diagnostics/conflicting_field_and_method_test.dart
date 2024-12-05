// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingFieldAndMethodTest);
  });
}

@reflectiveTest
class ConflictingFieldAndMethodTest extends PubPackageResolutionTest {
  test_class_inSuper_field() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_class_inSuper_getter() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_class_inSuper_getter_withAugmentation_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}

class B extends A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B {
  int get foo => 0;
}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 47, 3),
    ]);
  }

  test_class_inSuper_getter_withAugmentation_inDeclaration() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}

class B {
  int get foo => 0;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B extends A {}
''');

    await assertErrorsInFile2(a, [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 65, 3),
    ]);

    await assertErrorsInFile2(b, []);
  }

  test_class_inSuper_setter() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_enum_inMixin_field() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 62, 3),
    ]);
  }

  test_enum_inMixin_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 60, 3),
    ]);
  }

  test_enum_inMixin_getter_withAugmentation_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

mixin M {
  void foo() {}
}

enum E with M {v}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment enum E {;
  int get foo => 0;
}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 47, 3),
    ]);
  }

  test_enum_inMixin_getter_withAugmentation_inDeclaration() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

mixin M {
  void foo() {}
}

enum E {
  v;
  int get foo => 0;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment enum E with M {}
''');

    await assertErrorsInFile2(a, [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 69, 3),
    ]);

    await assertErrorsInFile2(b, []);
  }

  test_enum_inMixin_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 56, 3),
    ]);
  }

  test_extensionType_getter() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  int get foo => 0;
}
''');
  }

  test_extensionType_setter() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  set foo(int _) {}
}
''');
  }

  test_mixin_inSuper_getter_withAugmentation_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}

mixin B on A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment mixin B {
  int get foo => 0;
}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 47, 3),
    ]);
  }

  test_mixin_inSuper_getter_withAugmentation_inDeclaration() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}

mixin B {
  int get foo => 0;
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment mixin B on A {}
''');

    await assertErrorsInFile2(a, [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 65, 3),
    ]);

    await assertErrorsInFile2(b, []);
  }
}
