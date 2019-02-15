// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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
    addTestFile(r'''
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
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      '(int) → void',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_mixin_implements() async {
    addTestFile(r'''
class A {
  void foo(int _) {}
}

mixin M implements A {
  void bar() {
    super.foo(0);
  }
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      '(int) → void',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_mixinHasNoSuchMethod() async {
    addTestFile('''
class A {
  int foo();
  noSuchMethod(im) => 42;
}

class B extends Object with A {
  foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var invocation = findNode.methodInvocation('foo(); // ref');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      '() → int',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_OK_mixinHasConcrete() async {
    addTestFile('''
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
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'M'),
      '(int) → void',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_OK_superHasNoSuchMethod() async {
    addTestFile(r'''
class A {
  int foo();
  noSuchMethod(im) => 42;
}

class B extends A {
  int foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('super.foo(); // ref');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      '() → int',
    );
    assertSuperExpression(invocation.target);
  }

  test_error_abstractSuperMemberReference_OK_superSuperHasConcrete() async {
    addTestFile('''
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
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      '(int) → void',
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

    addTestFile(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.AMBIGUOUS_IMPORT,
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, '(int) → void');
    assertType(invocation, 'void');
  }

  test_error_ambiguousImport_topFunction_prefixed() async {
    newFile('/test/lib/a.dart', content: r'''
void foo(int _) {}
''');
    newFile('/test/lib/b.dart', content: r'''
void foo(int _) {}
''');

    addTestFile(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.AMBIGUOUS_IMPORT,
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, '(int) → void');
    assertType(invocation, 'void');
  }

  test_error_instanceAccessToStaticMember_method() async {
    addTestFile(r'''
class A {
  static void foo(int _) {}
}

main(A a) {
  a.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
    ]);
    _assertInvalidInvocation(
      'a.foo(0)',
      findElement.method('foo'),
      expectedNameType: '(int) → void',
    );
  }

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    addTestFile(r'''
class C {
  void Function() call;
}

main(C c) {
  c();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'c()',
      findElement.parameter('c'),
    );
  }

  test_error_invocationOfNonFunction_localVariable() async {
    addTestFile(r'''
main() {
  Object foo;
  foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.localVar('foo'),
      expectedNameType: 'Object',
    );
  }

  test_error_invocationOfNonFunction_OK_dynamic_localVariable() async {
    addTestFile(r'''
main() {
  var foo;
  foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation('foo();', findElement.localVar('foo'));
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_instance() async {
    addTestFile(r'''
class C {
  var foo;
}

main(C c) {
  c.foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation(
      'c.foo();',
      findElement.getter('foo'),
      expectedMethodNameType: '() → dynamic',
    );
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_superClass() async {
    addTestFile(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation(
      'foo();',
      findElement.getter('foo'),
      expectedMethodNameType: '() → dynamic',
    );
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_thisClass() async {
    addTestFile(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation(
      'foo();',
      findElement.getter('foo'),
      expectedMethodNameType: '() → dynamic',
    );
  }

  test_error_invocationOfNonFunction_OK_Function() async {
    addTestFile(r'''
f(Function foo) {
  foo(1, 2);
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation('foo(1, 2);', findElement.parameter('foo'));
  }

  test_error_invocationOfNonFunction_OK_functionTypeTypeParameter() async {
    addTestFile(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  
  main() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertMethodInvocation(
      findNode.methodInvocation('foo(0)'),
      findElement.getter('foo'),
      '(int) → double',
      expectedMethodNameType: '() → T',
    );
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    addTestFile(r'''
class C {
  static int foo;
}

main() {
  C.foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.getter('foo'),
      expectedMethodNameType: '() → int',
    );
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    addTestFile(r'''
class C {
  static int foo;
  
  main() {
    foo();
  }
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.getter('foo'),
      expectedMethodNameType: '() → int',
    );
  }

  test_error_invocationOfNonFunction_super_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.getter('foo'),
      expectedMethodNameType: '() → int',
    );
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('/test/lib/a.dart', content: r'''
void foo() {}
''');

    addTestFile(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo();');
    assertMethodInvocation(
      invocation,
      import.topFunction('foo'),
      '() → void',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_error_prefixIdentifierNotFollowedByDot_deferred() async {
    addTestFile(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      '() → Future<dynamic>',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_error_prefixIdentifierNotFollowedByDot_invoke() async {
    addTestFile(r'''
import 'dart:math' as foo;

main() {
  foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.import('dart:math').prefix,
      dynamicNameType: true,
    );
  }

  test_error_undefinedFunction() async {
    addTestFile(r'''
main() {
  foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_FUNCTION,
    ]);
    _assertUnresolvedMethodInvocation('foo(0)');
  }

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    addTestFile(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_FUNCTION,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedIdentifier_target() async {
    addTestFile(r'''
main() {
  bar.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.UNDEFINED_IDENTIFIER,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class() async {
    addTestFile(r'''
class C {}
main() {
  C.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    addTestFile(r'''
class C {}

int x;
main() {
  C.foo(x);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);

    _assertUnresolvedMethodInvocation('foo(x);');
    assertTopGetRef('x)', 'x');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    addTestFile(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    addTestFile(r'''
class C {}

main() {
  C.foo<int>();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);

    _assertUnresolvedMethodInvocation('foo<int>();');
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    addTestFile(r'''
class C<T> {
  static main() => C.T();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('C.T();');
  }

  test_error_undefinedMethod_hasTarget_instance() async {
    addTestFile(r'''
main() {
  42.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    addTestFile(r'''
main() {
  var v = () {};
  v.foo(0);
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_noTarget() async {
    addTestFile(r'''
class C {
  main() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_object_call() async {
    addTestFile(r'''
main(Object o) {
  o.call();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
  }

  test_error_undefinedMethod_OK_null() async {
    addTestFile(r'''
main() {
  null.foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertUnresolvedMethodInvocation('foo();');
  }

  test_error_undefinedMethod_private() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo(int _) {}
}
''');
    addTestFile(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('_foo(0);');
  }

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    addTestFile(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance methods of Type.
    addTestFile(r'''
class A {}
main() {
  A?.toString();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_METHOD,
    ]);
  }

  test_error_undefinedSuperMethod() async {
    addTestFile(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
    assertSuperExpression(findNode.super_('super.foo'));
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    addTestFile(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertTestErrors([
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
    addTestFile(r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_show() async {
    addTestFile(r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  test_error_useOfVoidResult_name_getter() async {
    addTestFile(r'''
class C<T>{
  T foo;
}

main(C<void> c) {
  c.foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    _assertInvalidInvocation(
      'c.foo()',
      findElement.getter('foo'),
      expectedNameType: 'void',
      expectedMethodNameType: '() → void',
    );
  }

  test_error_useOfVoidResult_name_localVariable() async {
    addTestFile(r'''
main() {
  void foo;
  foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.localVar('foo'),
      expectedNameType: 'void',
    );
  }

  test_error_useOfVoidResult_name_topFunction() async {
    addTestFile(r'''
void foo() {}

main() {
  foo()();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo()()'),
      findElement.topFunction('foo'),
      '() → void',
    );
  }

  test_error_useOfVoidResult_name_topVariable() async {
    addTestFile(r'''
void foo;

main() {
  foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.topGet('foo'),
      expectedNameType: 'void',
      expectedMethodNameType: '() → void',
    );
  }

  test_error_useOfVoidResult_receiver() async {
    addTestFile(r'''
main() {
  void foo;
  foo.toString();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      '() → String',
    );
  }

  test_error_useOfVoidResult_receiver_cascade() async {
    addTestFile(r'''
main() {
  void foo;
  foo..toString();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      '() → String',
    );
  }

  test_error_useOfVoidResult_receiver_withNull() async {
    addTestFile(r'''
main() {
  void foo;
  foo?.toString();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.USE_OF_VOID_RESULT,
    ]);
    // TODO(scheglov) Resolve fully, or don't resolve at all.
    assertMethodInvocation(
      findNode.methodInvocation('toString()'),
      null,
      '() → String',
    );
  }

  test_error_wrongNumberOfTypeArgumentsMethod_01() async {
    addTestFile(r'''
void foo() {}

main() {
  foo<int>();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      '() → void',
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    addTestFile(r'''
Map<T, U> foo<T extends num, U>() => null;

main() {
  foo<int>();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      '() → Map<num, dynamic>',
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_hasReceiver_class_staticGetter() async {
    addTestFile(r'''
class C {
  static double Function(int) get foo => null;
}

main() {
  C.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
    );
    assertClassRef(invocation.target, findElement.class_('C'));
  }

  test_hasReceiver_class_staticMethod() async {
    addTestFile(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      '(int) → void',
    );
    assertClassRef(invocation.target, findElement.class_('C'));
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    addTestFile(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      '() → Future<dynamic>',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_functionTyped_call() async {
    addTestFile(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('call(0)');
    assertMethodInvocation(
      invocation,
      null,
      '(int) → void',
    );
    assertElement(invocation.target, findElement.topFunction('foo'));
    assertType(invocation.target, '(int) → void');
  }

  test_hasReceiver_importPrefix_topFunction() async {
    newFile('/test/lib/a.dart', content: r'''
T foo<T extends num>(T a, T b) => a;
''');

    addTestFile(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(1, 2)');
    assertMethodInvocation(
      invocation,
      import.topFunction('foo'),
      '(int, int) → int',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_importPrefix_topGetter() async {
    newFile('/test/lib/a.dart', content: r'''
T Function<T>(T a, T b) get foo => null;
''');

    addTestFile(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(1, 2)');
    assertMethodInvocation(
      invocation,
      import.topGetter('foo'),
      '(int, int) → int',
      expectedMethodNameType: '() → <T>(T, T) → T',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_instance_Function_call_localVariable() async {
    addTestFile(r'''
void main() {
  Function foo;

  foo.call(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_Function_call_topVariable() async {
    addTestFile(r'''
Function foo;

void main() {
  foo.call(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_getter() async {
    addTestFile(r'''
class C {
  double Function(int) get foo => null;
}

main(C c) {
  c.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
    );
  }

  test_hasReceiver_instance_method() async {
    addTestFile(r'''
class C {
  void foo(int _) {}
}

main(C c) {
  c.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      '(int) → void',
      expectedMethodNameType: '(int) → void',
    );
  }

  test_hasReceiver_instance_method_generic() async {
    addTestFile(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

main(C c) {
  c.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      '(int) → int',
      expectedMethodNameType: '(int) → int',
    );
  }

  test_hasReceiver_instance_method_issue30552() async {
    addTestFile(r'''
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
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation("foo('hi')");
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'I2'),
      '(Object) → void',
    );
  }

  test_hasReceiver_instance_typeParameter() async {
    addTestFile(r'''
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
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      '(int) → void',
    );
  }

  test_hasReceiver_prefixed_class_staticGetter() async {
    newFile('/test/lib/a.dart', content: r'''
class C {
  static double Function(int) get foo => null;
}
''');

    addTestFile(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      import.class_('C').getGetter('foo'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
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

    addTestFile(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      import.class_('C').getMethod('foo'),
      '(int) → void',
    );

    PrefixedIdentifier target = invocation.target;
    assertImportPrefix(target.prefix, import.prefix);
    assertClassRef(target.identifier, import.class_('C'));
  }

  test_hasReceiver_super_getter() async {
    addTestFile(r'''
class A {
  double Function(int) get foo => null;
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo', of: 'A'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
    );
    assertSuperExpression(invocation.target);
  }

  test_hasReceiver_super_method() async {
    addTestFile(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      '(int) → void',
    );
    assertSuperExpression(invocation.target);
  }

  test_namedArgument() async {
    addTestFile(r'''
void foo({int a, bool b}) {}

main() {
  foo(b: false, a: 0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(b:');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      '({a: int, b: bool}) → void',
    );
    assertNamedParameterRef('b: false', 'b');
    assertNamedParameterRef('a: 0', 'a');
  }

  test_noReceiver_getter_superClass() async {
    addTestFile(r'''
class A {
  double Function(int) get foo => null;
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
    );
  }

  test_noReceiver_getter_thisClass() async {
    addTestFile(r'''
class C {
  double Function(int) get foo => null;

  void bar() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.getter('foo'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
    );
  }

  test_noReceiver_importPrefix() async {
    addTestFile(r'''
import 'dart:math' as math;

main() {
  math();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    ]);
    assertElement(findNode.simple('math()'), findElement.prefix('math'));
  }

  test_noReceiver_localFunction() async {
    addTestFile(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localFunction('foo'),
      '(int) → void',
    );
  }

  test_noReceiver_localVariable() async {
    addTestFile(r'''
main() {
  void Function(int) foo;

  foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localVar('foo'),
      '(int) → void',
    );
  }

  test_noReceiver_localVariable_call() async {
    addTestFile(r'''
class C {
  void call(int _) {}
}

main(C c) {
  c(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('c(0);');
    assertMethodInvocation(
      invocation,
      findElement.parameter('c'),
      '(int) → void',
    );
  }

  test_noReceiver_localVariable_promoted() async {
    addTestFile(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localVar('foo'),
      '(int) → void',
    );
  }

  test_noReceiver_method_superClass() async {
    addTestFile(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      '(int) → void',
    );
  }

  test_noReceiver_method_thisClass() async {
    addTestFile(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      '(int) → void',
    );
  }

  test_noReceiver_topFunction() async {
    addTestFile(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      '(int) → void',
      expectedMethodNameType: '(int) → void',
    );
  }

  test_noReceiver_topGetter() async {
    addTestFile(r'''
double Function(int) get foo => null;

main() {
  foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topGet('foo'),
      '(int) → double',
      expectedMethodNameType: '() → (int) → double',
    );
  }

  test_noReceiver_topVariable() async {
    addTestFile(r'''
void Function(int) foo;

main() {
  foo(0);
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topGet('foo'),
      '(int) → void',
      expectedMethodNameType: '() → (int) → void',
    );
  }

  test_objectMethodOnDynamic() async {
    addTestFile(r'''
main() {
  var v;
  v.toString(42);
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    _assertUnresolvedMethodInvocation('toString(42);');
  }

  test_objectMethodOnFunction() async {
    addTestFile(r'''
void f() {}

main() {
  f.toString();
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('toString();');
    assertMethodInvocation(
      invocation,
      typeProvider.objectType.getMethod('toString'),
      '() → String',
    );
  }

  void _assertInvalidInvocation(String search, Element expectedElement,
      {String expectedMethodNameType,
      String expectedNameType,
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
    );
  }

  void _assertUnresolvedMethodInvocation(String search) {
    // TODO(scheglov) clean up
    _assertInvalidInvocation(search, null);
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
