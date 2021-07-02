// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceResolutionTest);
  });
}

@reflectiveTest
class FunctionReferenceResolutionTest extends PubPackageResolutionTest {
  test_explicitReceiver_unknown() async {
    await assertErrorsInCode('''
bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertType(reference, 'dynamic');
  }

  test_instanceGetter_explicitReceiver() async {
    // This test is here to assert that the resolver does not throw, but in the
    // future, an error should be reported here as well.
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

bar(A a) {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertType(reference, 'dynamic');
  }

  test_instanceMethod() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_field() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B {
  A a;
  B(this.a);
  bar() {
    a.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_super() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
class B extends A {
  bar() {
    super.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_super_noMethod() async {
    await assertErrorsInCode('''
class A {
  bar() {
    super.foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 30, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertType(reference, 'dynamic');
  }

  test_instanceMethod_explicitReceiver_super_noSuper() async {
    await assertErrorsInCode('''
bar() {
  super.foo<int>;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 10, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertType(reference, 'dynamic');
  }

  test_instanceMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_variable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B {
  bar(A a) {
    a.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_localFunction() async {
    await assertNoErrorsInCode('''
void bar() {
  void foo<T>(T a) {}

  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.localFunction('foo'), 'void Function(int)');
  }

  test_localVariable() async {
    await assertNoErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.parameter('foo'), 'void Function(int)');
  }

  test_nonGenericFunction() async {
    await assertErrorsInCode('''
class A {
  void foo() {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 44, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function()');
  }

  test_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  @FailingTest(reason: 'Unresolved TODO in FunctionReferenceResolver')
  test_staticMethod_explicitReceiver() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}

  bar() {
    A.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertElement(reference, findElement.method('foo'));
    assertType(reference, 'void Function(int)');
  }

  @FailingTest(reason: 'Unresolved TODO in FunctionReferenceResolver')
  test_staticMethod_explicitReceiver_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

bar() {
  a.A.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertElement(reference, findElement.method('foo'));
    assertType(reference, 'void Function(int)');
  }

  test_tooFewTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T, U>(T a, U b) {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 58, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(reference, findElement.method('foo'),
        'void Function(dynamic, dynamic)');
  }

  test_tooManyTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int, int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 50, 10),
    ]);

    var reference = findNode.functionReference('foo<int, int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(dynamic)');
  }

  test_topLevelFunction() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.topFunction('foo'), 'void Function(int)');
  }

  test_topLevelFunction_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
      reference,
      findElement.importFind('package:test/a.dart').topFunction('foo'),
      'void Function(int)',
    );
  }

  test_unknownIdentifier() async {
    await assertErrorsInCode('''
void bar() {
  foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 3),
    ]);
  }

  test_unknownIdentifier_explicitReceiver() async {
    await assertErrorsInCode('''
class A {}

class B {
  bar(A a) {
    a.foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 3),
    ]);
  }

  test_unknownIdentifier_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '');
    await assertErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 40, 3),
    ]);
  }
}
