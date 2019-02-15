// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelInstanceGetterTest);
  });
}

@reflectiveTest
class TopLevelInstanceGetterTest extends DriverResolutionTest {
  test_call() async {
    await assertNoErrorsInCode('''
class A {
  int Function() get g => () => 0;
}
var a = new A();
var b = a.g();
''');
    TopLevelVariableDeclaration b = result.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
  }

  test_field() async {
    await assertNoErrorsInCode('''
class A {
  int g;
}
var b = new A().g;
''');
    TopLevelVariableDeclaration b = result.unit.declarations[1];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
  }

  test_field_call() async {
    await assertNoErrorsInCode('''
class A {
  int Function() g;
}
var a = new A();
var b = a.g();
''');
    TopLevelVariableDeclaration b = result.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
  }

  test_field_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class A {
  int g;
}
var a = new A();
var b = a.g;
''');
    TopLevelVariableDeclaration b = result.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
  }

  test_getter() async {
    await assertNoErrorsInCode('''
class A {
  int get g => 0;
}
var b = new A().g;
''');
    TopLevelVariableDeclaration b = result.unit.declarations[1];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
  }

  test_implicitlyTyped() async {
    await assertErrorsInCode('''
class A {
  get g => 0;
}
var b = new A().g;
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_call() async {
    await assertErrorsInCode('''
class A {
  get g => () => 0;
}
var a = new A();
var b = a.g();
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_field() async {
    await assertErrorsInCode('''
class A {
  var g = 0;
}
var b = new A().g;
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_field_call() async {
    await assertErrorsInCode('''
class A {
  var g = () => 0;
}
var a = new A();
var b = a.g();
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_field_prefixedIdentifier() async {
    await assertErrorsInCode('''
class A {
  var g = 0;
}
var a = new A();
var b = a.g;
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_fn() async {
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because f is
    // generic, so the type of a.x might affect the type of b.
    await assertErrorsInCode('''
class A {
  var x = 0;
}
int f<T>(x) => 0;
var a = new A();
var b = f(a.x);
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_fn_explicit_type_params() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
int f<T>(x) => 0;
var a = new A();
var b = f<int>(a.x);
''');
  }

  test_implicitlyTyped_fn_not_generic() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
int f(x) => 0;
var a = new A();
var b = f(a.x);
''');
  }

  test_implicitlyTyped_indexExpression() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int operator[](int value) => 0;
}
var a = new A();
var b = a[a.x];
''');
  }

  test_implicitlyTyped_invoke() async {
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because the
    // closure is generic, so the type of a.x might affect the type of b.
    await assertErrorsInCode('''
class A {
  var x = 0;
}
var a = new A();
var b = (<T>(y) => 0)(a.x);
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_invoke_explicit_type_params() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
var a = new A();
var b = (<T>(y) => 0)<int>(a.x);
''');
  }

  test_implicitlyTyped_invoke_not_generic() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
var a = new A();
var b = ((y) => 0)(a.x);
''');
  }

  test_implicitlyTyped_method() async {
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because f is
    // generic, so the type of a.x might affect the type of b.
    await assertErrorsInCode('''
class A {
  var x = 0;
  int f<T>(int x) => 0;
}
var a = new A();
var b = a.f(a.x);
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_method_explicit_type_params() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int f<T>(x) => 0;
}
var a = new A();
var b = a.f<int>(a.x);
''');
  }

  test_implicitlyTyped_method_not_generic() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int f(x) => 0;
}
var a = new A();
var b = a.f(a.x);
''');
  }

  test_implicitlyTyped_new() async {
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because B is
    // generic, so the type of a.x might affect the type of b.
    await assertErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B(x);
}
var a = new A();
var b = new B(a.x);
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_new_explicit_type_params() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B(x);
}
var a = new A();
var b = new B<int>(a.x);
''');
  }

  test_implicitlyTyped_new_explicit_type_params_named() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B.named(x);
}
var a = new A();
var b = new B<int>.named(a.x);
''');
  }

  test_implicitlyTyped_new_explicit_type_params_prefixed() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    newFile('/test/lib/lib1.dart', content: '''
class B<T> {
  B(x);
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B<int>(a.x);
''');
  }

  test_implicitlyTyped_new_named() async {
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because B is
    // generic, so the type of a.x might affect the type of b.
    await assertErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B.named(x);
}
var a = new A();
var b = new B.named(a.x);
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_new_not_generic() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B {
  B(x);
}
var a = new A();
var b = new B(a.x);
''');
  }

  test_implicitlyTyped_new_not_generic_named() async {
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B {
  B.named(x);
}
var a = new A();
var b = new B.named(a.x);
''');
  }

  test_implicitlyTyped_new_not_generic_prefixed() async {
    newFile('/test/lib/lib1.dart', content: '''
class B {
  B(x);
}
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await assertNoErrorsInCode('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B(a.x);
''');
  }

  test_implicitlyTyped_new_prefixed() async {
    newFile('/test/lib/lib1.dart', content: '''
class B<T> {
  B(x);
}
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because B is
    // generic, so the type of a.x might affect the type of b.
    await assertErrorsInCode('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B(a.x);
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_prefixedIdentifier() async {
    await assertErrorsInCode('''
class A {
  get g => 0;
}
var a = new A();
var b = a.g;
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_implicitlyTyped_propertyAccessLhs() async {
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because the type
    // of a.x affects the lookup of y, which in turn affects the type of b.
    await assertErrorsInCode('''
class A {
  var x = new B();
  int operator[](int value) => 0;
}
class B {
  int y;
}
var a = new A();
var b = (a.x).y;
''', [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class A {
  int get g => 0;
}
var a = new A();
var b = a.g;
''');
    TopLevelVariableDeclaration b = result.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
  }
}
