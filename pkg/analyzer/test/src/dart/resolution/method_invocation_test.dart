// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationResolutionTest);
  });
}

@reflectiveTest
class MethodInvocationResolutionTest extends DriverResolutionTest {
  test_error_abstractSuperMemberReference() async {
    await resolveTestCode(r'''
abstract class A {
  void foo(int _);
}
abstract class B extends A {
  void bar() {
    super.foo(0);
  }

  void foo(int _) {} // does not matter
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_mixin_implements() async {
    await resolveTestCode(r'''
class A {
  void foo(int _) {}
}

mixin M implements A {
  void bar() {
    super.foo(0);
  }
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_mixinHasNoSuchMethod() async {
    await resolveTestCode('''
class A {
  int foo();
  noSuchMethod(im) => 42;
}

class B extends Object with A {
  foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var invocation = findNode.methodInvocation('foo(); // ref');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'int Function()',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_OK_mixinHasConcrete() async {
    await resolveTestCode('''
class A {}

class M {
  void foo(int _) {}
}

class B = A with M;

class C extends B {
  void bar() {
    super.foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'M'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_OK_superHasNoSuchMethod() async {
    await resolveTestCode(r'''
class A {
  int foo();
  noSuchMethod(im) => 42;
}

class B extends A {
  int foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('super.foo(); // ref');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'int Function()',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_OK_superSuperHasConcrete() async {
    await resolveTestCode('''
abstract class A {
  void foo(int _) {}
}

abstract class B extends A {
  void foo(int _);
}

class C extends B {
  void bar() {
    super.foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_ambiguousImport_topFunction() async {
    newFile('/test/lib/a.dart', content: r'''
void foo(int _) {}
''');
    newFile('/test/lib/b.dart', content: r'''
void foo(int _) {}
''');

    await resolveTestCode(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.AMBIGUOUS_IMPORT,
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');
  }

  test_error_ambiguousImport_topFunction_prefixed() async {
    newFile('/test/lib/a.dart', content: r'''
void foo(int _) {}
''');
    newFile('/test/lib/b.dart', content: r'''
void foo(int _) {}
''');

    await resolveTestCode(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.AMBIGUOUS_IMPORT,
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');
  }

  test_error_instanceAccessToStaticMember_method() async {
    await resolveTestCode(r'''
class A {
  static void foo(int _) {}
}

main(A a) {
  a.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
    ]);
    _assertInvalidInvocation(
      'a.foo(0)',
      findElement.method('foo'),
      expectedNameType: '(int) → void',
    );
  }

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    await resolveTestCode(r'''
class C {
  void Function() call;
}

main(C c) {
  c();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'c()',
      findElement.parameter('c'),
    );
  }

  test_error_invocationOfNonFunction_localVariable() async {
    await resolveTestCode(r'''
main() {
  Object foo;
  foo();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.localVar('foo'),
      expectedNameType: 'Object',
    );
  }

  test_error_invocationOfNonFunction_OK_dynamic_localVariable() async {
    await resolveTestCode(r'''
main() {
  var foo;
  foo();
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation('foo();', findElement.localVar('foo'));
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_instance() async {
    await resolveTestCode(r'''
class C {
  var foo;
}

main(C c) {
  c.foo();
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation(
      'c.foo();',
      findElement.getter('foo'),
      expectedMethodNameType: 'dynamic Function()',
    );
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_superClass() async {
    await resolveTestCode(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation(
      'foo();',
      findElement.getter('foo'),
      expectedMethodNameType: 'dynamic Function()',
    );
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_thisClass() async {
    await resolveTestCode(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation(
      'foo();',
      findElement.getter('foo'),
      expectedMethodNameType: 'dynamic Function()',
    );
  }

  test_error_invocationOfNonFunction_OK_Function() async {
    await resolveTestCode(r'''
f(Function foo) {
  foo(1, 2);
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation('foo(1, 2);', findElement.parameter('foo'));
  }

  test_error_invocationOfNonFunction_OK_functionTypeTypeParameter() async {
    await resolveTestCode(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  
  main() {
    foo(0);
  }
}
''');
    assertNoTestErrors();
    assertMethodInvocation(
      findNode.methodInvocation('foo(0)'),
      findElement.getter('foo'),
      'double Function(int)',
      expectedMethodNameType: 'T Function()',
    );
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    await resolveTestCode(r'''
class C {
  static int foo;
}

main() {
  C.foo();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.getter('foo'),
      expectedMethodNameType: 'int Function()',
    );
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    await resolveTestCode(r'''
class C {
  static int foo;
  
  main() {
    foo();
  }
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.getter('foo'),
      expectedMethodNameType: 'int Function()',
    );
  }

  test_error_invocationOfNonFunction_super_getter() async {
    await resolveTestCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.getter('foo'),
      expectedMethodNameType: 'int Function()',
    );
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('/test/lib/a.dart', content: r'''
void foo() {}
''');

    await resolveTestCode(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo();');
    assertMethodInvocation(
      invocation,
      import.topFunction('foo'),
      'void Function()',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_error_prefixIdentifierNotFollowedByDot_deferred() async {
    await resolveTestCode(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_error_prefixIdentifierNotFollowedByDot_invoke() async {
    await resolveTestCode(r'''
import 'dart:math' as foo;

main() {
  foo();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.import('dart:math').prefix,
      dynamicNameType: true,
    );
  }

  test_error_undefinedFunction() async {
    await resolveTestCode(r'''
main() {
  foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_FUNCTION,
    ]);
    _assertUnresolvedMethodInvocation('foo(0)');
  }

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    await resolveTestCode(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_FUNCTION,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedIdentifier_target() async {
    await resolveTestCode(r'''
main() {
  bar.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.UNDEFINED_IDENTIFIER,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class() async {
    await resolveTestCode(r'''
class C {}
main() {
  C.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    await resolveTestCode(r'''
class C {}

int x;
main() {
  C.foo(x);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);

    _assertUnresolvedMethodInvocation('foo(x);');
    assertTopGetRef('x)', 'x');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    await resolveTestCode(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    await resolveTestCode(r'''
class C {}

main() {
  C.foo<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);

    _assertUnresolvedMethodInvocation(
      'foo<int>();',
      expectedTypeArguments: ['int'],
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    await resolveTestCode(r'''
class C<T> {
  static main() => C.T();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('C.T();');
  }

  test_error_undefinedMethod_hasTarget_instance() async {
    await resolveTestCode(r'''
main() {
  42.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    await resolveTestCode(r'''
main() {
  var v = () {};
  v.foo(0);
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_noTarget() async {
    await resolveTestCode(r'''
class C {
  main() {
    foo(0);
  }
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_object_call() async {
    await resolveTestCode(r'''
main(Object o) {
  o.call();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
  }

  test_error_undefinedMethod_OK_null() async {
    await resolveTestCode(r'''
main() {
  null.foo();
}
''');
    assertNoTestErrors();
    _assertUnresolvedMethodInvocation('foo();');
  }

  test_error_undefinedMethod_private() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo(int _) {}
}
''');
    await resolveTestCode(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('_foo(0);');
  }

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    await resolveTestCode(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance methods of Type.
    await resolveTestCode(r'''
class A {}
main() {
  A?.toString();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
  }

  test_error_undefinedSuperMethod() async {
    await resolveTestCode(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
    assertSuperExpression(findNode.super_('super.foo'));
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    await resolveTestCode(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
    ]);

    _assertInvalidInvocation(
      'foo(0)',
      findElement.method('foo'),
      expectedNameType: '(int) → void',
    );
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_prefixed() async {
    await resolveTestCode(r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_show() async {
    await resolveTestCode(r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  test_error_useOfVoidResult_name_getter() async {
    await resolveTestCode(r'''
class C<T>{
  T foo;
}

main(C<void> c) {
  c.foo();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    _assertInvalidInvocation(
      'c.foo()',
      findElement.getter('foo'),
      expectedNameType: 'void',
      expectedMethodNameType: 'void Function()',
    );
  }

  test_error_useOfVoidResult_name_localVariable() async {
    await resolveTestCode(r'''
main() {
  void foo;
  foo();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.localVar('foo'),
      expectedNameType: 'void',
    );
  }

  test_error_useOfVoidResult_name_topFunction() async {
    await resolveTestCode(r'''
void foo() {}

main() {
  foo()();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo()()'),
      findElement.topFunction('foo'),
      'void Function()',
    );
  }

  test_error_useOfVoidResult_name_topVariable() async {
    await resolveTestCode(r'''
void foo;

main() {
  foo();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.topGet('foo'),
      expectedNameType: 'void',
      expectedMethodNameType: 'void Function()',
    );
  }

  test_error_useOfVoidResult_receiver() async {
    await resolveTestCode(r'''
main() {
  void foo;
  foo.toString();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      'String Function()',
    );
  }

  test_error_useOfVoidResult_receiver_cascade() async {
    await resolveTestCode(r'''
main() {
  void foo;
  foo..toString();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      'String Function()',
    );
  }

  test_error_useOfVoidResult_receiver_withNull() async {
    await resolveTestCode(r'''
main() {
  void foo;
  foo?.toString();
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      'String Function()',
    );
  }

  test_error_wrongNumberOfTypeArgumentsMethod_01() async {
    await resolveTestCode(r'''
void foo() {}

main() {
  foo<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      'void Function()',
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    await resolveTestCode(r'''
Map<T, U> foo<T extends num, U>() => null;

main() {
  foo<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      'Map<num, dynamic> Function()',
      expectedTypeArguments: ['num', 'dynamic'],
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_hasReceiver_class_staticGetter() async {
    await resolveTestCode(r'''
class C {
  static double Function(int) get foo => null;
}

main() {
  C.foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
    assertClassRef(invocation.target, findElement.class_('C'));
  }

  test_hasReceiver_class_staticMethod() async {
    await resolveTestCode(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
    assertClassRef(invocation.target, findElement.class_('C'));
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    await resolveTestCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''');
    assertNoTestErrors();

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_functionTyped_call() async {
    await resolveTestCode(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('call(0)');
    assertMethodInvocation(
      invocation,
      null,
      'void Function(int)',
    );
    assertElement(invocation.target, findElement.topFunction('foo'));
    assertType(invocation.target, 'void Function(int)');
  }

  test_hasReceiver_importPrefix_topFunction() async {
    newFile('/test/lib/a.dart', content: r'''
T foo<T extends num>(T a, T b) => a;
''');

    await resolveTestCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(1, 2)');
    assertMethodInvocation(
      invocation,
      import.topFunction('foo'),
      'int Function(int, int)',
      expectedTypeArguments: ['int'],
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_importPrefix_topGetter() async {
    newFile('/test/lib/a.dart', content: r'''
T Function<T>(T a, T b) get foo => null;
''');

    await resolveTestCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(1, 2)');
    assertMethodInvocation(
      invocation,
      import.topGetter('foo'),
      'int Function(int, int)',
      expectedMethodNameType: 'T Function<T>(T, T) Function()',
      expectedTypeArguments: ['int'],
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_instance_Function_call_localVariable() async {
    await resolveTestCode(r'''
void main() {
  Function foo;

  foo.call(0);
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_Function_call_topVariable() async {
    await resolveTestCode(r'''
Function foo;

void main() {
  foo.call(0);
}
''');
    assertNoTestErrors();
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_getter() async {
    await resolveTestCode(r'''
class C {
  double Function(int) get foo => null;
}

main(C c) {
  c.foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
  }

  test_hasReceiver_instance_method() async {
    await resolveTestCode(r'''
class C {
  void foo(int _) {}
}

main(C c) {
  c.foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
      expectedMethodNameType: 'void Function(int)',
    );
    assertTypeArgumentTypes(invocation, []);
  }

  test_hasReceiver_instance_method_generic() async {
    await resolveTestCode(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

main(C c) {
  c.foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'int Function(int)',
      expectedMethodNameType: 'int Function(int)',
      expectedTypeArguments: ['int'],
    );
    assertTypeArgumentTypes(invocation, ['int']);
  }

  test_hasReceiver_instance_method_issue30552() async {
    await resolveTestCode(r'''
abstract class I1 {
  void foo(int i);
}

abstract class I2 {
  void foo(Object o);
}

abstract class C implements I1, I2 {}

class D extends C {
  void foo(Object o) {}
}

void main(C c) {
  c.foo('hi');
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation("foo('hi')");
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'I2'),
      'void Function(Object)',
    );
  }

  test_hasReceiver_instance_typeParameter() async {
    await resolveTestCode(r'''
class A {
  void foo(int _) {}
}

class C<T extends A> {
  T a;
  
  main() {
    a.foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_hasReceiver_prefixed_class_staticGetter() async {
    newFile('/test/lib/a.dart', content: r'''
class C {
  static double Function(int) get foo => null;
}
''');

    await resolveTestCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      import.class_('C').getGetter('foo'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );

    PrefixedIdentifier target = invocation.target;
    assertImportPrefix(target.prefix, import.prefix);
    assertClassRef(target.identifier, import.class_('C'));
  }

  test_hasReceiver_prefixed_class_staticMethod() async {
    newFile('/test/lib/a.dart', content: r'''
class C {
  static void foo(int _) => null;
}
''');

    await resolveTestCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      import.class_('C').getMethod('foo'),
      'void Function(int)',
    );

    PrefixedIdentifier target = invocation.target;
    assertImportPrefix(target.prefix, import.prefix);
    assertClassRef(target.identifier, import.class_('C'));
  }

  test_hasReceiver_super_getter() async {
    await resolveTestCode(r'''
class A {
  double Function(int) get foo => null;
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo', of: 'A'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
    assertSuperExpression(invocation.target);
  }

  test_hasReceiver_super_method() async {
    await resolveTestCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_namedArgument() async {
    await resolveTestCode(r'''
void foo({int a, bool b}) {}

main() {
  foo(b: false, a: 0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(b:');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      'void Function({a: int, b: bool})',
    );
    assertNamedParameterRef('b: false', 'b');
    assertNamedParameterRef('a: 0', 'a');
  }

  test_noReceiver_getter_superClass() async {
    await resolveTestCode(r'''
class A {
  double Function(int) get foo => null;
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
  }

  test_noReceiver_getter_thisClass() async {
    await resolveTestCode(r'''
class C {
  double Function(int) get foo => null;

  void bar() {
    foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
  }

  test_noReceiver_importPrefix() async {
    await resolveTestCode(r'''
import 'dart:math' as math;

main() {
  math();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);
    assertElement(findNode.simple('math()'), findElement.prefix('math'));
  }

  test_noReceiver_localFunction() async {
    await resolveTestCode(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localFunction('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_localVariable() async {
    await resolveTestCode(r'''
main() {
  void Function(int) foo;

  foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localVar('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_localVariable_call() async {
    await resolveTestCode(r'''
class C {
  void call(int _) {}
}

main(C c) {
  c(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('c(0);');
    assertMethodInvocation(
      invocation,
      findElement.parameter('c'),
      'void Function(int)',
    );
  }

  test_noReceiver_localVariable_promoted() async {
    await resolveTestCode(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localVar('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_method_superClass() async {
    await resolveTestCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_method_thisClass() async {
    await resolveTestCode(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_topFunction() async {
    await resolveTestCode(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      'void Function(int)',
      expectedMethodNameType: 'void Function(int)',
    );
  }

  test_noReceiver_topGetter() async {
    await resolveTestCode(r'''
double Function(int) get foo => null;

main() {
  foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topGet('foo'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
  }

  test_noReceiver_topVariable() async {
    await resolveTestCode(r'''
void Function(int) foo;

main() {
  foo(0);
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topGet('foo'),
      'void Function(int)',
      expectedMethodNameType: 'void Function(int) Function()',
    );
  }

  test_objectMethodOnDynamic() async {
    await resolveTestCode(r'''
main() {
  var v;
  v.toString(42);
}
''');
    assertNoTestErrors();
    _assertUnresolvedMethodInvocation('toString(42);');
  }

  test_objectMethodOnFunction() async {
    await resolveTestCode(r'''
void f() {}

main() {
  f.toString();
}
''');
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('toString();');
    assertMethodInvocation(
      invocation,
      typeProvider.objectType.getMethod('toString'),
      'String Function()',
    );
  }

  test_typeArgumentTypes_generic_inferred() async {
    await assertNoErrorsInCode(r'''
U foo<T, U>(T a) => null;

main() {
  bool v = foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertTypeArgumentTypes(invocation, ['int', 'bool']);
  }

  test_typeArgumentTypes_generic_instantiateToBounds() async {
    await assertNoErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo();
}
''');

    var invocation = findNode.methodInvocation('foo();');
    assertTypeArgumentTypes(invocation, ['num']);
  }

  test_typeArgumentTypes_generic_typeArguments_notBounds() async {
    await resolveTestCode(r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
}
''');
    var invocation = findNode.methodInvocation('foo<bool>();');
    assertTypeArgumentTypes(invocation, ['bool']);
  }

  test_typeArgumentTypes_generic_typeArguments_wrongNumber() async {
    await resolveTestCode(r'''
void foo<T>() {}

main() {
  foo<int, double>();
}
''');
    var invocation = findNode.methodInvocation('foo<int, double>();');
    assertTypeArgumentTypes(invocation, ['dynamic']);
  }

  test_typeArgumentTypes_notGeneric() async {
    await assertNoErrorsInCode(r'''
void foo(int a) {}

main() {
  foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertTypeArgumentTypes(invocation, []);
  }

  void _assertInvalidInvocation(String search, Element expectedElement,
      {String expectedMethodNameType,
      String expectedNameType,
      List<String> expectedTypeArguments: const <String>[],
      bool dynamicNameType: false}) {
    var invocation = findNode.methodInvocation(search);
    if (dynamicNameType) {
      assertTypeDynamic(invocation.methodName);
    }
    // TODO(scheglov) I think `invokeType` should be `null`.
    assertMethodInvocation(
      invocation,
      expectedElement,
      'dynamic',
      expectedMethodNameType: expectedMethodNameType,
      expectedNameType: expectedNameType,
      expectedType: 'dynamic',
      expectedTypeArguments: expectedTypeArguments,
    );
    assertTypeArgumentTypes(invocation, expectedTypeArguments);
  }

  void _assertUnresolvedMethodInvocation(
    String search, {
    List<String> expectedTypeArguments: const <String>[],
  }) {
    // TODO(scheglov) clean up
    _assertInvalidInvocation(
      search,
      null,
      expectedTypeArguments: expectedTypeArguments,
    );
//    var invocation = findNode.methodInvocation(search);
//    assertTypeDynamic(invocation.methodName);
//    // TODO(scheglov) I think `invokeType` should be `null`.
//    assertMethodInvocation(
//      invocation,
//      null,
//      'dynamic',
//      expectedType: 'dynamic',
//    );
  }
}
