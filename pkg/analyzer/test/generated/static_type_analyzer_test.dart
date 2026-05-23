// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeAnalyzerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class StaticTypeAnalyzerTest extends PubPackageResolutionTest {
  test_visitAdjacentStrings() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 'a' 'b';
''');
    expect(
      result.findNode.adjacentStrings("'a' 'b'").staticType,
      same(result.typeProvider.stringType),
    );
  }

  test_visitAsExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  test() => this as B;
}
class B extends A {}
late B b;
''');
    var bType = result.findElement.topVar('b').type;
    expect(result.findNode.as_('this as B').staticType, bType);
  }

  test_visitAwaitExpression_flattened() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Future<Future<int>> e) async => await e;
''');
    InterfaceType futureIntType = result.typeProvider.futureType(
      result.typeProvider.intType,
    );
    expect(
      result.findNode.awaitExpression('await e').staticType,
      futureIntType,
    );
  }

  test_visitAwaitExpression_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Future<int> e) async => await e;
''');
    // await e, where e has type Future<int>
    InterfaceType intType = result.typeProvider.intType;
    expect(result.findNode.awaitExpression('await e').staticType, intType);
  }

  test_visitBooleanLiteral_false() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => false;
''');
    expect(
      result.findNode.booleanLiteral('false').staticType,
      same(result.typeProvider.boolType),
    );
  }

  test_visitBooleanLiteral_true() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => true;
''');
    expect(
      result.findNode.booleanLiteral('true').staticType,
      same(result.typeProvider.boolType),
    );
  }

  test_visitCascadeExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(String a) => a..length;
''');
    expect(
      result.findNode.cascade('a..length').staticType,
      result.typeProvider.stringType,
    );
  }

  test_visitConditionalExpression_differentTypes() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) => b ? 1.0 : 0;
''');
    expect(
      result.findNode.conditionalExpression('b ? 1.0 : 0').staticType,
      result.typeProvider.numType,
    );
  }

  test_visitConditionalExpression_sameTypes() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(bool b) => b ? 1 : 0;
''');
    expect(
      result.findNode.conditionalExpression('b ? 1 : 0').staticType,
      same(result.typeProvider.intType),
    );
  }

  test_visitDoubleLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 4.33;
''');
    expect(
      result.findNode.doubleLiteral('4.33').staticType,
      same(result.typeProvider.doubleType),
    );
  }

  test_visitInstanceCreationExpression_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  C.m();
}
test() => new C.m();
late C c;
''');
    var cType = result.findElement.topVar('c').type;
    expect(result.findNode.instanceCreation('new C.m()').staticType, cType);
  }

  test_visitInstanceCreationExpression_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<E> {}
class I {}
test() => new C<I>();
late I i;
''');
    var iType = result.findElement.topVar('i').type;
    InterfaceType type =
        result.findNode.instanceCreation('new C<I>()').staticType
            as InterfaceType;
    List<DartType> typeArgs = type.typeArguments;
    expect(typeArgs.length, 1);
    expect(typeArgs[0], iType);
  }

  test_visitInstanceCreationExpression_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}
test() => new C();
late C c;
''');
    var cType = result.findElement.topVar('c').type;
    expect(result.findNode.instanceCreation('new C()').staticType, cType);
  }

  test_visitIntegerLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 42;
''');
    var node = result.findNode.integerLiteral('42');
    expect(node.staticType, same(result.typeProvider.intType));
  }

  test_visitIsExpression_negated() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object a) => a is! String;
''');
    expect(
      result.findNode.isExpression('a is! String').staticType,
      same(result.typeProvider.boolType),
    );
  }

  test_visitIsExpression_notNegated() async {
    var result = await resolveTestCodeWithDiagnostics('''
test(Object a) => a is String;
''');
    expect(
      result.findNode.isExpression('a is String').staticType,
      same(result.typeProvider.boolType),
    );
  }

  test_visitMethodInvocation() async {
    await resolveTestCodeWithDiagnostics('''
m() => 0;
test() => m();
''');
  }

  test_visitNullLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => null;
''');
    expect(
      result.findNode.nullLiteral('null').staticType,
      same(result.typeProvider.nullType),
    );
  }

  test_visitParenthesizedExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => (0);
''');
    expect(
      result.findNode.parenthesized('(0)').staticType,
      same(result.typeProvider.intType),
    );
  }

  test_visitSimpleStringLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => 'a';
''');
    expect(
      result.findNode.stringLiteral("'a'").staticType,
      same(result.typeProvider.stringType),
    );
  }

  test_visitStringInterpolation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test() => "a${'b'}c";
''');
    expect(
      result.findNode.stringInterpolation(r'''"a${'b'}c"''').staticType,
      same(result.typeProvider.stringType),
    );
  }

  test_visitSuperExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
class B extends A {
  test() => super.foo;
}
late B b;
''');
    var bType = result.findElement.topVar('b').type;
    expect(result.findNode.super_('super').staticType, bType);
  }

  test_visitSymbolLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => #a;
''');
    expect(
      result.findNode.symbolLiteral('#a').staticType,
      same(result.typeProvider.symbolType),
    );
  }

  test_visitThisExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {
  test() => this;
}
late B b;
''');
    var bType = result.findElement.topVar('b').type;
    expect(result.findNode.this_('this').staticType, bType);
  }

  test_visitThrowExpression_withValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
test() => throw 0;
''');
    var node = result.findNode.throw_('throw 0');
    expect(node.staticType, same(result.typeProvider.bottomType));
  }
}
