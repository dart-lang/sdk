// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithUndefinedConstructorTest);
  });
}

@reflectiveTest
class NewWithUndefinedConstructorTest extends PubPackageResolutionTest {
  test_default() async {
    await assertErrorsInCode('''
class A {
  A.name() {}
}
f() {
  new A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 38, 1),
    ]);
  }

  test_defined_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A.name() {}
}
f() {
  new A.name();
}
''');
  }

  test_defined_unnamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
f() {
  new A();
}
''');
  }

  test_named() async {
    await assertErrorsInCode('''
class A {
  A() {}
}
f() {
  new A.name();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 35, 4),
    ]);
  }

  test_private_named() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  A._named() {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';
void f() {
  new A._named();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 36, 6),
    ]);
  }

  test_private_named_genericClass_noTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A._named() {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';
void f() {
  new A._named();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 36, 6),
    ]);
  }

  test_private_named_genericClass_withTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A._named() {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';
void f() {
  new A<int>._named();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 41, 6),
    ]);
  }
}
