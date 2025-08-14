// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithUndefinedConstructorTest);
    defineReflectiveTests(
      NewWithUndefinedConstructorWithoutConstructorTearoffsTest,
    );
  });
}

@reflectiveTest
class NewWithUndefinedConstructorTest extends PubPackageResolutionTest
    with NewWithUndefinedConstructorTestCases {}

mixin NewWithUndefinedConstructorTestCases on PubPackageResolutionTest {
  test_default() async {
    await assertErrorsInCode(
      '''
class A {
  A.name() {}
}
f() {
  new A();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithUndefinedConstructorDefault,
          38,
          1,
          messageContains: ["'A'"],
        ),
      ],
    );
  }

  test_default_noKeyword() async {
    await assertErrorsInCode(
      '''
class A {
  A.name() {}
}
f() {
  A();
}
''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructorDefault, 34, 1)],
    );
  }

  test_default_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A.name() {}
}
''');
    await assertErrorsInCode(
      '''
import 'lib1.dart' as lib1;

f() {
  new lib1.A();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithUndefinedConstructorDefault,
          41,
          6,
          messageContains: ["'lib1.A'"],
        ),
      ],
    );
  }

  test_default_unnamedViaNew() async {
    await assertErrorsInCode(
      '''
class A {
  A.name() {}
}
f() {
  A.new();
}
''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructorDefault, 36, 3)],
    );
  }

  test_defaultViaNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new() {}
}
f() {
  A();
}
''');
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
    await assertErrorsInCode(
      '''
class A {
  A() {}
}
f() {
  new A.name();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithUndefinedConstructor,
          35,
          4,
          messageContains: ["class 'A'", "named 'name'"],
        ),
      ],
    );
  }

  test_named_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A() {}
}
''');
    await assertErrorsInCode(
      '''
import 'lib1.dart' as lib1;
f() {
  new lib1.A.name();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithUndefinedConstructor,
          47,
          4,
          messageContains: ["class 'lib1.A'", "named 'name'"],
        ),
      ],
    );
  }

  test_private_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A._named() {}
}
''');
    await assertErrorsInCode(
      r'''
import 'a.dart';
void f() {
  new A._named();
}
''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructor, 36, 6)],
    );
  }

  test_private_named_genericClass_noTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A._named() {}
}
''');
    await assertErrorsInCode(
      r'''
import 'a.dart';
void f() {
  new A._named();
}
''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructor, 36, 6)],
    );
  }

  test_private_named_genericClass_withTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A._named() {}
}
''');
    await assertErrorsInCode(
      r'''
import 'a.dart';
void f() {
  new A<int>._named();
}
''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructor, 41, 6)],
    );
  }
}

@reflectiveTest
class NewWithUndefinedConstructorWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_defaultViaNew() async {
    await assertErrorsInCode(
      '''
class A {
  A.new() {}
}
f() {
  A();
}
''',
      [error(ParserErrorCode.experimentNotEnabled, 14, 3)],
    );
  }

  test_unnamedViaNew() async {
    await assertErrorsInCode(
      '''
class A {
  A.named() {}
}
f() {
  A.new();
}
''',
      [error(ParserErrorCode.experimentNotEnabled, 37, 3)],
    );
  }
}
