// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/dependency/library_builder.dart'
    hide buildLibrary;
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferenceCollectorTest);
    defineReflectiveTests(ExpressionReferenceCollectorTest);
    defineReflectiveTests(StatementReferenceCollectorTest);
  });
}

final dartCoreUri = Uri.parse('dart:core');

@reflectiveTest
class ExpressionReferenceCollectorTest extends _Base {
  test_adjacentStrings() async {
    var library = await buildTestLibrary(a, r'''
test() {
  'foo' '$x' 'bar';
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_asExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x as Y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['Y', 'x']);
  }

  test_assignmentExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x = y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_assignmentExpression_compound() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator+(_) {}
}

class B extends A {}

B x, y;

test() {
  x += y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', '+')]);
  }

  test_assignmentExpression_nullAware() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x ??= y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_awaitExpression() async {
    var library = await buildTestLibrary(a, r'''
test() async {
  await x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_binaryExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator+(_) {}
}

class B extends A {}

B x, y;

test() {
  x + y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', '+')]);
  }

  test_binaryExpression_int() async {
    var library = await buildTestLibrary(a, r'''
class A {
  int operator+(_) {}
}

A x;

test() {
  x + 1 + 2;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'A', '+'),
      _ExpectedClassMember(dartCoreUri, 'int', '+'),
    ]);
  }

  test_binaryExpression_sort() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator*(_) {}
}

class B {
  operator+(_) {}
}

A a;
B b;

test() {
  (b + 1) + a * 2;
}
''');
    _assertImpl(
      library,
      'test',
      NodeKind.FUNCTION,
      unprefixed: ['a', 'b'],
      expectedMembers: [
        _ExpectedClassMember(aUri, 'A', '*'),
        _ExpectedClassMember(aUri, 'B', '+'),
      ],
    );
  }

  test_binaryExpression_unique() async {
    var library = await buildTestLibrary(a, r'''
class A {
  A operator+(_) => null;
}

A x;

test() {
  x + 1 + 2 + 3;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '+')]);
  }

  test_binaryExpression_unresolvedOperator() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x, y;

test() {
  x + y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '+')]);
  }

  test_binaryExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x + y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_booleanLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  true;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_cascadeExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x
    ..foo(y)
    ..bar = z;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x',
      'y',
      'z'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'A', 'bar'),
      _ExpectedClassMember(aUri, 'A', 'foo'),
    ]);
    // TODO(scheglov) should be `bar=`
  }

  test_conditionalExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x ? y : z;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z']);
  }

  test_doubleLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  1.2;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_functionExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <T extends A, U extends T>(B b, C c, T t, U u) {
    T;
    U;
    x;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'x']);
  }

  test_functionExpressionInvocation() async {
    var library = await buildTestLibrary(a, r'''
test() {
  (x)<T>(y, z);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['T', 'x', 'y', 'z']);
  }

  test_indexExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x[y];
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_instanceCreationExpression_explicitNew_named() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  new A<T>.named(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'named')]);
  }

  test_instanceCreationExpression_explicitNew_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  new A<T>(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '')]);
  }

  test_instanceCreationExpression_explicitNew_unresolvedClass() async {
    var library = await buildTestLibrary(a, r'''
test() {
  new A<T>.named(x);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x']);
  }

  test_instanceCreationExpression_implicitNew_named() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  A<T>.named(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'named')]);
  }

  test_instanceCreationExpression_implicitNew_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  A<T>(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '')]);
  }

  test_instanceCreationExpression_implicitNew_unresolvedClass_named() async {
    var library = await buildTestLibrary(a, r'''
test() {
  A<T>.named(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y']);
  }

  test_integerLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  0;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_isExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x is Y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['Y', 'x']);
  }

  test_listLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <A>[x, y];
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y']);
  }

  test_mapLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <A, B>{x: y, v: w};
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'v', 'w', 'x', 'y']);
  }

  test_methodInvocation_instance_withoutTarget_function() async {
    var library = await buildTestLibrary(a, r'''
void foo(a, {b}) {}

test() {
  foo(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['foo', 'x', 'y']);
  }

  test_methodInvocation_instance_withoutTarget_method() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void foo(a, {b}) {}

  test() {
    foo(x, b: y);
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['foo', 'x', 'y']);
  }

  test_methodInvocation_instance_withTarget() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x.foo<T>(y, b: z);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['T', 'x', 'y', 'z'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'foo')]);
  }

  test_methodInvocation_instance_withTarget_super() async {
    var library = await buildTestLibrary(a, r'''
class A {
  void foo(a, b) {}
}

class B extends A {
  test() {
    super.foo(x, y);
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'B', unprefixed: ['x', 'y'], superPrefixed: ['foo']);
  }

  test_methodInvocation_static_withTarget() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  A.foo<T>(x);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'foo')]);
  }

  test_nullLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  null;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_parenthesizedExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  ((x));
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_postfixExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {}
class B extend A {}

B x, y;

test() {
  x++;
  y--;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x',
      'y'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'B', '+'),
      _ExpectedClassMember(aUri, 'B', '-')
    ]);
  }

  test_postfixExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x++;
  y--;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_prefixedIdentifier_importPrefix() async {
    newFile(b, content: 'var b = 0;');
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as pb;

test() {
  pb.b;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, prefixed: {
      'pb': ['b']
    });
  }

  test_prefixedIdentifier_importPrefix_unresolvedIdentifier() async {
    newFile(b, content: '');
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as pb;

test() {
  pb.b;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, prefixed: {
      'pb': ['b']
    });
  }

  test_prefixedIdentifier_interfaceProperty() async {
    var library = await buildTestLibrary(a, r'''
class A {
  int get y => 0;
}

class B extends A {}

B x;
test() {
  x.y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'y')]);
  }

  test_prefixedIdentifier_static() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class B extends A {}

test() {
  B.x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['B'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'x')]);
  }

  test_prefixedIdentifier_unresolvedPrefix() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x.y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_prefixExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator-() {}
}

class B extend A {}

B x;

test() {
  -x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'unary-')]);
  }

  test_prefixExpression_unresolvedOperator() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  -x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'unary-')]);
  }

  test_prefixExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  -x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_propertyAccess() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class B extends A {}

B x;

test() {
  (x).foo;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'foo')]);
  }

  test_propertyAccess_super() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super.foo;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', superPrefixed: ['foo']);
  }

  test_setLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <A>{x, y, z};
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y', 'z']);
  }

  test_simpleIdentifier() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_simpleIdentifier_sort() async {
    var library = await buildTestLibrary(a, r'''
test() {
  d; c; a; b; e;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['a', 'b', 'c', 'd', 'e']);
  }

  test_simpleIdentifier_synthetic() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x +;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_simpleIdentifier_unique() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x; x; y; x; y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_simpleStringLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  '';
  """""";
  r"""""";
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_stringInterpolation() async {
    var library = await buildTestLibrary(a, r'''
test() {
  '$x ${y}';
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_thisExpression() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    this;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD, memberOf: 'C');
  }

  test_throwExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  throw x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }
}

@reflectiveTest
class ReferenceCollectorTest extends _Base {
  test_unit_function_api_parameter_named_simple_interface() async {
    var library = await buildTestLibrary(a, r'''
void test({A a, B b}) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_api_parameter_positional_simple_interface() async {
    var library = await buildTestLibrary(a, r'''
void test([A a, B b]) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_api_parameter_required_functionTyped() async {
    var library = await buildTestLibrary(a, r'''
void test(A a(B b, C c)) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B', 'C']);
  }

  test_unit_function_api_parameter_required_simple_function() async {
    var library = await buildTestLibrary(a, r'''
void test(A Function(B) a) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_api_parameter_required_simple_interface() async {
    var library = await buildTestLibrary(a, r'''
void test(A a, B b) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_api_returnType_absent() async {
    var library = await buildTestLibrary(a, r'''
test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_function_api_returnType_dynamic() async {
    var library = await buildTestLibrary(a, r'''
dynamic test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_function_api_returnType_function() async {
    var library = await buildTestLibrary(a, r'''
A Function<T, U extends B>(T t, C c, D<T> d, E e) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'D', 'E']);
  }

  test_unit_function_api_returnType_function_nested() async {
    var library = await buildTestLibrary(a, r'''
A Function<T>(B Function<U>(U, C, T) f, D) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'D']);
  }

  test_unit_function_api_returnType_function_parameter_named() async {
    var library = await buildTestLibrary(a, r'''
A Function({B, C}) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B', 'C']);
  }

  test_unit_function_api_returnType_function_parameter_positional() async {
    var library = await buildTestLibrary(a, r'''
A Function([B, C]) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B', 'C']);
  }

  test_unit_function_api_returnType_function_shadow_typeParameters() async {
    var library = await buildTestLibrary(a, r'''
A Function<T extends U, U>(B) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_api_returnType_interface_argument() async {
    var library = await buildTestLibrary(a, r'''
A<B, C<D>> test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'D']);
  }

  test_unit_function_api_returnType_interface_prefixed() async {
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as pb;
import 'c.dart' as pc;
A<pb.B2, pc.C2, pb.B1, pc.C1, pc.C3> test() {}
''');
    _assertApi(
      library,
      'test',
      NodeKind.FUNCTION,
      unprefixed: ['A'],
      prefixed: {
        'pb': ['B1', 'B2'],
        'pc': ['C1', 'C2', 'C3']
      },
    );
  }

  test_unit_function_api_returnType_interface_simple() async {
    var library = await buildTestLibrary(a, r'''
int test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['int']);
  }

  test_unit_function_api_returnType_void() async {
    var library = await buildTestLibrary(a, r'''
void test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_variable_api_hasType() async {
    var library = await buildTestLibrary(a, r'''
int test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int']);
  }

  test_unit_variable_api_hasType_const() async {
    var library = await buildTestLibrary(a, r'''
const int test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int', 'x']);
  }

  test_unit_variable_api_hasType_final() async {
    var library = await buildTestLibrary(a, r'''
final int test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int']);
  }

  test_unit_variable_api_noType() async {
    var library = await buildTestLibrary(a, r'''
var test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['x']);
  }

  test_unit_variable_api_noType_final() async {
    var library = await buildTestLibrary(a, r'''
final test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['x']);
  }
}

@reflectiveTest
class StatementReferenceCollectorTest extends _Base {
  test_assertStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  assert(x, y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_block_localScope() async {
    var library = await buildTestLibrary(a, r'''
test() {
  var x = 0;
  {
    var y = 0;
    {
      x;
      y;
    }
    x;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_breakStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (true) {
    break;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_continueStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (true) {
    continue;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_doStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  do {
    x;
  } while (y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_emptyStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (true);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_forEachStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (A a in x) {
    a;
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y']);
  }

  test_forEachStatement_body_singleStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (var a in x) a;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_forEachStatement_iterableAsLoopVariable() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (A x in x) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y']);
  }

  test_forEachStatement_loopIdentifier() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (x in y) {
    z;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z']);
  }

  test_forStatement_initialization() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (x; y; z) {
    z2;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z', 'z2']);
  }

  test_forStatement_variables() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (A a = x, b = y, c = a; z; a, b, z2) {
    z3;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y', 'z', 'z2', 'z3']);
  }

  test_functionDeclarationStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  A foo(B b) {
    x;
    C;
    b;
    foo();
  }
  foo();
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'x']);
  }

  test_ifStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  if (x) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_ifStatement_else() async {
    var library = await buildTestLibrary(a, r'''
test() {
  if (x) {
    y;
  } else {
    z;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z']);
  }

  test_labeledStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  label: x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_returnStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  return x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_tryStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  try {
    var local1 = 1;
    x;
    local1;
  } finally {
    var local2 = 2;
    y;
    local2;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_variableDeclarationStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  var a = x, b = y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_whileStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (x) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_yieldStatement() async {
    var library = await buildTestLibrary(a, r'''
test() sync* {
  yield x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }
}

class _Base extends BaseDependencyTest {
  void _assertApi(Library library, String name, NodeKind kind,
      {List<String> unprefixed: const [],
      Map<String, List<String>> prefixed: const {},
      List<String> superPrefixed: const [],
      List<_ExpectedClassMember> expectedMembers: const []}) {
    var node = getNode(library, name: name, kind: kind);
    _assertDependencies(
      node.api,
      unprefixed: unprefixed,
      prefixed: prefixed,
      superPrefixed: superPrefixed,
      expectedMembers: expectedMembers,
    );
  }

  void _assertDependencies(Dependencies dependencies,
      {List<String> unprefixed: const [],
      Map<String, List<String>> prefixed: const {},
      List<String> superPrefixed: const [],
      List<_ExpectedClassMember> expectedMembers: const []}) {
    expect(dependencies.unprefixedReferencedNames, unprefixed);
    expect(dependencies.importPrefixes, prefixed.keys);
    expect(dependencies.importPrefixedReferencedNames, prefixed.values);
    expect(dependencies.superReferencedNames, superPrefixed);

    var actualMembers = dependencies.classMemberReferences;
    if (actualMembers.length != expectedMembers.length) {
      fail('Expected: $expectedMembers\nActual: $actualMembers');
    }
    expect(actualMembers, hasLength(expectedMembers.length));
    for (var i = 0; i < actualMembers.length; i++) {
      var actualMember = actualMembers[i];
      var expectedMember = expectedMembers[i];
      if (actualMember.target.libraryUri != expectedMember.targetUri ||
          actualMember.target.name != expectedMember.targetName ||
          actualMember.name != expectedMember.name) {
        fail('Expected: $expectedMember\nActual: $actualMember');
      }
    }
  }

  void _assertImpl(Library library, String name, NodeKind kind,
      {String memberOf,
      List<String> unprefixed: const [],
      Map<String, List<String>> prefixed: const {},
      List<String> superPrefixed: const [],
      List<_ExpectedClassMember> expectedMembers: const []}) {
    var node = getNode(library, name: name, kind: kind, memberOf: memberOf);
    _assertDependencies(
      node.impl,
      unprefixed: unprefixed,
      prefixed: prefixed,
      superPrefixed: superPrefixed,
      expectedMembers: expectedMembers,
    );
  }
}

class _ExpectedClassMember {
  final Uri targetUri;
  final String targetName;
  final String name;

  _ExpectedClassMember(
    this.targetUri,
    this.targetName,
    this.name,
  );

  @override
  String toString() {
    return '($targetUri, $targetName, $name)';
  }
}
