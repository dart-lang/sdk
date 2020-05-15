// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationResolutionTest);
    defineReflectiveTests(MethodInvocationResolutionWithNnbdTest);
  });
}

@reflectiveTest
class MethodInvocationResolutionTest extends DriverResolutionTest {
  test_error_ambiguousImport_topFunction() async {
    newFile('/test/lib/a.dart', content: r'''
void foo(int _) {}
''');
    newFile('/test/lib/b.dart', content: r'''
void foo(int _) {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 46, 3),
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

    await assertErrorsInCode(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 58, 3),
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');
  }

  test_error_instanceAccessToStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

main(A a) {
  a.foo(0);
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 57, 3),
    ]);
    assertMethodInvocation2(
      findNode.methodInvocation('a.foo(0)'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'void Function(int)',
      type: 'void',
    );
  }

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    await assertErrorsInCode(r'''
class C {
  void Function() call;
}

main(C c) {
  c();
}
''', [
      error(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 51, 1),
    ]);

    var invocation = findNode.functionExpressionInvocation('c();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var cRef = invocation.function as SimpleIdentifier;
    assertElement(cRef, findElement.parameter('c'));
    assertType(cRef, 'C');
  }

  test_error_invocationOfNonFunction_localVariable() async {
    await assertErrorsInCode(r'''
main() {
  Object foo;
  foo();
}
''', [
      error(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 25, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertType(foo, 'Object');
  }

  test_error_invocationOfNonFunction_OK_dynamic_localVariable() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo;
  foo();
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertTypeDynamic(foo);
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_instance() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;
}

main(C c) {
  c.foo();
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertTypeDynamic(foo);
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertTypeDynamic(foo.propertyName);
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertTypeDynamic(foo);
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertTypeDynamic(foo);
  }

  test_error_invocationOfNonFunction_OK_Function() async {
    await assertNoErrorsInCode(r'''
f(Function foo) {
  foo(1, 2);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(1, 2);');
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.parameter('foo'));
    assertType(foo, 'Function');
  }

  test_error_invocationOfNonFunction_OK_functionTypeTypeParameter() async {
    await assertNoErrorsInCode(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  
  main() {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo;
}

main() {
  C.foo();
}
''', [
      error(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 42, 5),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'int');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'int');
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo;
  
  main() {
    foo();
  }
}
''', [
      error(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 46, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'int');
  }

  test_error_invocationOfNonFunction_super_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''', [
      error(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 68, 9),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'int');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'int');

    assertSuperExpression(foo.target);
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('/test/lib/a.dart', content: r'''
void foo() {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 6),
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
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 49, 4),
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
    await assertErrorsInCode(r'''
import 'dart:math' as foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 3),
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.import('dart:math').prefix,
      dynamicNameType: true,
    );
  }

  test_error_undefinedFunction() async {
    await assertErrorsInCode(r'''
main() {
  foo(0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_FUNCTION, 11, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0)');
  }

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_FUNCTION, 45, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedIdentifier_target() async {
    await assertErrorsInCode(r'''
main() {
  bar.foo(0);
}
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 11, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class() async {
    await assertErrorsInCode(r'''
class C {}
main() {
  C.foo(0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 24, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    await assertErrorsInCode(r'''
class C {}

int x;
main() {
  C.foo(x);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 32, 3),
    ]);

    _assertUnresolvedMethodInvocation('foo(x);');
    assertTopGetRef('x)', 'x');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    await assertErrorsInCode(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 76, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    await assertErrorsInCode(r'''
class C {}

main() {
  C.foo<int>();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 25, 3),
    ]);

    _assertUnresolvedMethodInvocation(
      'foo<int>();',
      expectedTypeArguments: ['int'],
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  static main() => C.T();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 34, 1),
    ]);
    _assertUnresolvedMethodInvocation('C.T();');
  }

  test_error_undefinedMethod_hasTarget_instance() async {
    await assertErrorsInCode(r'''
main() {
  42.foo(0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 14, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    await assertErrorsInCode(r'''
main() {
  var v = () {};
  v.foo(0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 30, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  main() {
    foo(0);
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 25, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_null() async {
    await assertErrorsInCode(r'''
main() {
  null.foo();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 16, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo();');
  }

  test_error_undefinedMethod_object_call() async {
    await assertErrorsInCode(r'''
main(Object o) {
  o.call();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 21, 4),
    ]);
  }

  test_error_undefinedMethod_private() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo(int _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 53, 4),
    ]);
    _assertUnresolvedMethodInvocation('_foo(0);');
  }

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 50, 3),
    ]);
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance methods of Type.
    await assertErrorsInCode(r'''
class A {}
main() {
  A?.toString();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 25, 8),
    ]);
  }

  test_error_undefinedSuperMethod() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SUPER_METHOD, 62, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
    assertSuperExpression(findNode.super_('super.foo'));
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          71,
          3),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 74, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('foo(0)'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_prefixed() async {
    await assertErrorsInCode(r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_show() async {
    await assertErrorsInCode(r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  test_error_useOfVoidResult_name_getter() async {
    await assertErrorsInCode(r'''
class C<T>{
  T foo;
}

main(C<void> c) {
  c.foo();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 44, 5),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'void');
    assertMember(foo.propertyName, findElement.getter('foo'), {'T': 'void'});
    assertType(foo.propertyName, 'void');
  }

  test_error_useOfVoidResult_name_localVariable() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertType(foo, 'void');
  }

  test_error_useOfVoidResult_name_topFunction() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo()();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 3),
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo()()'),
      findElement.topFunction('foo'),
      'void Function()',
    );
  }

  test_error_useOfVoidResult_name_topVariable() async {
    await assertErrorsInCode(r'''
void foo;

main() {
  foo();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 22, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.topGet('foo'));
    assertType(foo, 'void');
  }

  test_error_useOfVoidResult_receiver() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo.toString();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 23, 3),
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      'String Function()',
    );
  }

  test_error_useOfVoidResult_receiver_cascade() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo..toString();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 23, 3),
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      'String Function()',
    );
  }

  test_error_useOfVoidResult_receiver_withNull() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo?.toString();
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 23, 3),
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      'String Function()',
    );
  }

  test_error_wrongNumberOfTypeArgumentsMethod_01() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo<int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 29, 5),
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      'void Function()',
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    await assertErrorsInCode(r'''
Map<T, U> foo<T extends num, U>() => null;

main() {
  foo<int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 58, 5),
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      'Map<dynamic, dynamic> Function()',
      expectedTypeArguments: ['dynamic', 'dynamic'],
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_hasReceiver_class_staticGetter() async {
    await assertNoErrorsInCode(r'''
class C {
  static double Function(int) get foo => null;
}

main() {
  C.foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertClassRef(foo.target, findElement.class_('C'));
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'double Function(int)');
  }

  test_hasReceiver_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
    assertClassRef(invocation.target, findElement.class_('C'));
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''');

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertImportPrefix(invocation.target, import.prefix);

    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
    );
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary_extraArgument() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary(1 + 2);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 65, 7),
    ]);

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary(1 + 2)');
    assertImportPrefix(invocation.target, import.prefix);

    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
    );

    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_hasReceiver_functionTyped() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');

    var invocation = findNode.methodInvocation('call(0)');
    assertMethodInvocation(
      invocation,
      null,
      'void Function(int)',
    );
    assertElement(invocation.target, findElement.topFunction('foo'));
    assertType(invocation.target, 'void Function(int)');
  }

  test_hasReceiver_functionTyped_generic() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T _) {}

main() {
  foo.call(0);
}
''');

    var invocation = findNode.methodInvocation('call(0)');
    assertMethodInvocation(
      invocation,
      null,
      'void Function(int)',
      expectedTypeArguments: ['int'],
    );
    assertElement(invocation.target, findElement.topFunction('foo'));
    assertType(invocation.target, 'void Function<T>(T)');
  }

  test_hasReceiver_importPrefix_topFunction() async {
    newFile('/test/lib/a.dart', content: r'''
T foo<T extends num>(T a, T b) => a;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

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

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.functionExpressionInvocation('foo(1, 2);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'int Function(int, int)');
    assertType(invocation, 'int');

    var foo = invocation.function as PrefixedIdentifier;
    assertType(foo, 'T Function<T>(T, T)');
    assertElement(foo.identifier, import.topGet('foo'));
    assertType(foo.identifier, 'T Function<T>(T, T)');

    assertImportPrefix(foo.prefix, import.prefix);
  }

  test_hasReceiver_instance_Function_call_localVariable() async {
    await assertNoErrorsInCode(r'''
void main() {
  Function foo;

  foo.call(0);
}
''');
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_Function_call_topVariable() async {
    await assertNoErrorsInCode(r'''
Function foo;

void main() {
  foo.call(0);
}
''');
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => null;
}

main(C c) {
  c.foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'double Function(int)');
  }

  test_hasReceiver_instance_method() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}
}

main(C c) {
  c.foo(0);
}
''');

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
    await assertNoErrorsInCode(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

main(C c) {
  c.foo(0);
}
''');

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
    await assertNoErrorsInCode(r'''
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

    var invocation = findNode.methodInvocation("foo('hi')");
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'I2'),
      'void Function(Object)',
    );
  }

  test_hasReceiver_instance_typeParameter() async {
    await assertNoErrorsInCode(r'''
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

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, import.class_('C').getGetter('foo'));
    assertType(foo.propertyName, 'double Function(int)');

    PrefixedIdentifier target = foo.target;
    assertImportPrefix(target.prefix, import.prefix);
    assertClassRef(target.identifier, import.class_('C'));
  }

  test_hasReceiver_prefixed_class_staticMethod() async {
    newFile('/test/lib/a.dart', content: r'''
class C {
  static void foo(int _) => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

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
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => null;
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'double Function(int)');

    assertSuperExpression(foo.target);
  }

  test_hasReceiver_super_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_namedArgument() async {
    await assertNoErrorsInCode(r'''
void foo({int a, bool b}) {}

main() {
  foo(b: false, a: 0);
}
''');

    var invocation = findNode.methodInvocation('foo(b:');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      'void Function({int a, bool b})',
    );
    assertNamedParameterRef('b: false', 'b');
    assertNamedParameterRef('a: 0', 'a');
  }

  test_noReceiver_getter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => null;
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_noReceiver_getter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => null;

  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_noReceiver_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 40, 4),
    ]);
    assertElement(findNode.simple('math()'), findElement.prefix('math'));
  }

  test_noReceiver_localFunction() async {
    await assertNoErrorsInCode(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localFunction('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_localVariable() async {
    await assertNoErrorsInCode(r'''
main() {
  void Function(int) foo;

  foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertType(foo, 'void Function(int)');
  }

  test_noReceiver_localVariable_call() async {
    await assertNoErrorsInCode(r'''
class C {
  void call(int _) {}
}

main(C c) {
  c(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('c(0);');
    assertElement(invocation, findElement.method('call', of: 'C'));
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var cRef = invocation.function as SimpleIdentifier;
    assertElement(cRef, findElement.parameter('c'));
    assertType(cRef, 'C');
  }

  test_noReceiver_localVariable_promoted() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertType(foo, 'void Function(int)');
  }

  test_noReceiver_method_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_method_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_parameter_call_nullAware() async {
    await assertNoErrorsInCode(r'''
double Function(int) foo;

main() {
  foo?.call(1);
}
    ''');

    var invocation = findNode.methodInvocation('call(1)');
    assertTypeLegacy(invocation.target);
  }

  test_noReceiver_topFunction() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      'void Function(int)',
      expectedMethodNameType: 'void Function(int)',
    );
  }

  test_noReceiver_topGetter() async {
    await assertNoErrorsInCode(r'''
double Function(int) get foo => null;

main() {
  foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.topGet('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_noReceiver_topVariable() async {
    await assertNoErrorsInCode(r'''
void Function(int) foo;

main() {
  foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.topGet('foo'));
    assertType(foo, 'void Function(int)');
  }

  test_objectMethodOnDynamic() async {
    await assertNoErrorsInCode(r'''
main() {
  var v;
  v.toString(42);
}
''');
    _assertUnresolvedMethodInvocation('toString(42);');
  }

  test_objectMethodOnFunction() async {
    await assertNoErrorsInCode(r'''
void f() {}

main() {
  f.toString();
}
''');

    var invocation = findNode.methodInvocation('toString();');
    assertMethodInvocation(
      invocation,
      typeProvider.objectType.getMethod('toString'),
      'String Function()',
    );
  }

  test_syntheticName() async {
    // This code is invalid, and the constructor initializer has a method
    // invocation with a synthetic name. But we should still resolve the
    // invocation, and resolve all its arguments.
    await assertErrorsInCode(r'''
class A {
  A() : B(1 + 2, [0]);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 18, 1),
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 13),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation(');'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );

    assertType(findNode.binary('1 + 2'), 'int');
    assertType(findNode.listLiteral('[0]'), 'List<int>');
  }

  test_typeArgumentTypes_generic_inferred() async {
    await assertErrorsInCode(r'''
U foo<T, U>(T a) => null;

main() {
  bool v = foo(0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
    ]);

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
    await assertErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 45, 4),
    ]);
    var invocation = findNode.methodInvocation('foo<bool>();');
    assertTypeArgumentTypes(invocation, ['bool']);
  }

  test_typeArgumentTypes_generic_typeArguments_wrongNumber() async {
    await assertErrorsInCode(r'''
void foo<T>() {}

main() {
  foo<int, double>();
}
''', [
      error(
          StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 32, 13),
    ]);
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
      List<String> expectedTypeArguments = const <String>[],
      bool dynamicNameType = false}) {
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
    List<String> expectedTypeArguments = const <String>[],
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

@reflectiveTest
class MethodInvocationResolutionWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  @override
  bool get typeToStringWithNullability => true;

  test_hasReceiver_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary();
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertImportPrefix(invocation.target, import.prefix);

    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic>* Function()*',
    );
  }

  test_hasReceiver_interfaceQ_Function_call_checked() async {
    await assertNoErrorsInCode(r'''
void main(Function? foo) {
  foo?.call();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('foo?.call()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceQ_Function_call_unchecked() async {
    await assertErrorsInCode(r'''
void main(Function? foo) {
  foo.call();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 29, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('foo.call()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceQ_nullShorting() async {
    await assertNoErrorsInCode(r'''
class C {
  C foo() => throw 0;
  C bar() => throw 0;
}

void testShort(C? c) {
  c?.foo().bar();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('c?.foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'C Function()',
      type: 'C',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('bar();'),
      element: findElement.method('bar'),
      typeArgumentTypes: [],
      invokeType: 'C Function()',
      type: 'C?',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

main(A? a) {
  a.foo();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 44, 1),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'A'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined_extension() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A {
  void foo() {}
}

main(A? a) {
  a.foo();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 82, 1),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'A'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A? {
  void foo() {}
}

main(A? a) {
  a.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'E'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ2() async {
    await assertNoErrorsInCode(r'''
extension E<T> on T? {
  T foo() => throw 0;
}

main(int? a) {
  a.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: elementMatcher(
        findElement.method('foo', of: 'E'),
        substitution: {'T': 'int'},
      ),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );
  }

  test_hasReceiver_interfaceTypeQ_notDefined() async {
    await assertErrorsInCode(r'''
class A {}

main(A? a) {
  a.foo();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 27, 1),
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 29, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extension() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void foo() {}
}

main(A? a) {
  a.foo();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 65, 1),
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 67, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A? {
  void foo() {}
}

main(A? a) {
  a.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'E'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_nullShorting_cascade_firstMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
  int bar() => 0;
}

main(A? a) {
  a?..foo()..bar();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('..foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('..bar()'),
      element: findElement.method('bar'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_nullShorting_cascade_firstPropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
  int bar() => 0;
}

main(A? a) {
  a?..foo..bar();
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('..foo'),
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('..bar()'),
      element: findElement.method('bar'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_nullShorting_cascade_nullAwareInside() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() => 0;
}

main() {
  A a = A()..foo()?.abs();
  a;
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('..foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'int? Function()',
      type: 'int?',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('.abs()'),
      element: intElement.getMethod('abs'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertType(findNode.cascade('A()'), 'A');
  }
}
