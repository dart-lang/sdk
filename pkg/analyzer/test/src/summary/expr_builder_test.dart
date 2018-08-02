// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/summary/expr_builder.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../abstract_single_unit.dart';
import 'resynthesize_ast_test.dart';
import 'resynthesize_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExprBuilderTest);
  });
}

@reflectiveTest
class ExprBuilderTest extends AbstractSingleUnitTest
    with AstSerializeTestMixin {
  @override
  bool get allowMissingFiles => false;

  Expression buildConstructorInitializer(String sourceText,
      {String className: 'C',
      String initializerName: 'x',
      bool requireValidConst: false}) {
    var resynthesizer = encodeSource(sourceText);
    var library = resynthesizer.getLibraryElement(testSource.uri.toString());
    var c = library.getType(className);
    var constructor = c.unnamedConstructor as ConstructorElementImpl;
    var serializedExecutable = constructor.serializedExecutable;
    var x = serializedExecutable.constantInitializers
        .singleWhere((i) => i.name == initializerName);
    return buildExpression(resynthesizer, constructor, x.expression,
        serializedExecutable.localFunctions,
        requireValidConst: requireValidConst);
  }

  Expression buildExpression(
      TestSummaryResynthesizer resynthesizer,
      ElementImpl context,
      UnlinkedExpr unlinkedExpr,
      List<UnlinkedExecutable> localFunctions,
      {bool requireValidConst: false}) {
    var library = resynthesizer.getLibraryElement(testSource.uri.toString());
    var unit = library.definingCompilationUnit as CompilationUnitElementImpl;
    var unitResynthesizerContext =
        unit.resynthesizerContext as SummaryResynthesizerContext;
    var unitResynthesizer = unitResynthesizerContext.unitResynthesizer;
    var exprBuilder = new ExprBuilder(unitResynthesizer, context, unlinkedExpr,
        requireValidConst: requireValidConst, localFunctions: localFunctions);
    return exprBuilder.build();
  }

  Expression buildTopLevelVariable(String sourceText,
      {String variableName: 'x', bool requireValidConst: false}) {
    var resynthesizer = encodeSource(sourceText);
    var library = resynthesizer.getLibraryElement(testSource.uri.toString());
    var unit = library.definingCompilationUnit as CompilationUnitElementImpl;
    TopLevelVariableElementImpl x =
        unit.topLevelVariables.singleWhere((e) => e.name == variableName);
    return buildExpression(
        resynthesizer,
        x,
        x.unlinkedVariableForTesting.initializer.bodyExpr,
        x.unlinkedVariableForTesting.initializer.localFunctions,
        requireValidConst: requireValidConst);
  }

  void checkCompoundAssignment(String exprText) {
    checkSimpleExpression(exprText, extraDeclarations: 'var y;');
  }

  void checkConstructorInitializer(String sourceText, String expectedText,
      {String className: 'C',
      String initializerName: 'x',
      bool requireValidConst: false}) {
    Expression expr = buildConstructorInitializer(sourceText,
        className: className,
        initializerName: initializerName,
        requireValidConst: requireValidConst);
    expect(expr.toString(), expectedText);
  }

  void checkInvalidConst(String expressionText) {
    checkTopLevelVariable('var x = $expressionText;', 'null',
        requireValidConst: true);
  }

  Expression checkSimpleExpression(String expressionText,
      {String expectedText,
      String extraDeclarations: '',
      bool requireValidConst: false}) {
    return checkTopLevelVariable('var x = $expressionText;\n$extraDeclarations',
        expectedText ?? expressionText,
        requireValidConst: requireValidConst);
  }

  Expression checkTopLevelVariable(String sourceText, String expectedText,
      {String variableName: 'x', bool requireValidConst: false}) {
    Expression expr = buildTopLevelVariable(sourceText,
        variableName: variableName, requireValidConst: requireValidConst);
    expect(expr.toString(), expectedText);
    return expr;
  }

  TestSummaryResynthesizer encodeSource(String text) {
    var source = addTestSource(text);
    return encodeLibrary(source);
  }

  void test_add() {
    checkSimpleExpression('0 + 1');
  }

  void test_and() {
    checkSimpleExpression('false && true');
  }

  void test_assignToIndex() {
    checkSimpleExpression('items[0] = 1',
        extraDeclarations: 'var items = [0, 1, 2]');
  }

  void test_assignToIndex_compound_multiply() {
    checkSimpleExpression('items[0] *= 1',
        extraDeclarations: 'var items = [0, 1, 2]');
  }

  void test_assignToProperty() {
    checkSimpleExpression('new A().f = 1', extraDeclarations: r'''
class A {
  int f = 0;
}
''');
  }

  void test_assignToProperty_compound_plus() {
    checkSimpleExpression('new A().f += 1', extraDeclarations: r'''
class A {
  int f = 0;
}
''');
  }

  void test_assignToProperty_compound_suffixIncrement() {
    checkSimpleExpression('new A().f++', extraDeclarations: r'''
class A {
  int f = 0;
}
''');
  }

  void test_assignToRef() {
    checkSimpleExpression('y = 0', extraDeclarations: 'var y;');
  }

  void test_await() {
    checkSimpleExpression('() async => await 0');
  }

  void test_bitAnd() {
    checkSimpleExpression('0 & 1');
  }

  void test_bitOr() {
    checkSimpleExpression('0 | 1');
  }

  void test_bitShiftLeft() {
    checkSimpleExpression('0 << 1');
  }

  void test_bitShiftRight() {
    checkSimpleExpression('0 >> 1');
  }

  void test_bitXor() {
    checkSimpleExpression('0 ^ 1');
  }

  void test_cascade() {
    // Cascade sections don't matter for type inference.
    // The type of a cascade is the type of the target.
    checkSimpleExpression('new C()..f1 = 1..m(2, 3)..f2 = 4',
        extraDeclarations: r'''
class C {
  int f1;
  int f2;
  int m(int a, int b) => 0;
}
''',
        expectedText: 'new C()');
  }

  void test_closure_invalid_const() {
    checkInvalidConst('() => 0');
  }

  void test_complement() {
    checkSimpleExpression('~0');
  }

  void test_compoundAssignment_bitAnd() {
    checkCompoundAssignment('y &= 0');
  }

  void test_compoundAssignment_bitOr() {
    checkCompoundAssignment('y |= 0');
  }

  void test_compoundAssignment_bitXor() {
    checkCompoundAssignment('y ^= 0');
  }

  void test_compoundAssignment_divide() {
    checkCompoundAssignment('y /= 0');
  }

  void test_compoundAssignment_floorDivide() {
    checkCompoundAssignment('y ~/= 0');
  }

  void test_compoundAssignment_ifNull() {
    checkCompoundAssignment('y ??= 0');
  }

  void test_compoundAssignment_minus() {
    checkCompoundAssignment('y -= 0');
  }

  void test_compoundAssignment_modulo() {
    checkCompoundAssignment('y %= 0');
  }

  void test_compoundAssignment_multiply() {
    checkCompoundAssignment('y *= 0');
  }

  void test_compoundAssignment_plus() {
    checkCompoundAssignment('y += 0');
  }

  void test_compoundAssignment_postfixDecrement() {
    checkCompoundAssignment('y--');
  }

  void test_compoundAssignment_postfixIncrement() {
    checkCompoundAssignment('y++');
  }

  void test_compoundAssignment_prefixDecrement() {
    checkCompoundAssignment('--y');
  }

  void test_compoundAssignment_prefixIncrement() {
    checkCompoundAssignment('++y');
  }

  void test_compoundAssignment_shiftLeft() {
    checkCompoundAssignment('y <<= 0');
  }

  void test_compoundAssignment_shiftRight() {
    checkCompoundAssignment('y >>= 0');
  }

  void test_concatenate() {
    var expr = buildTopLevelVariable(r'var x = "${0}";') as StringInterpolation;
    expect(expr.elements, hasLength(3));
    expect((expr.elements[0] as InterpolationString).value, '');
    expect((expr.elements[1] as InterpolationExpression).expression.toString(),
        '0');
    expect((expr.elements[2] as InterpolationString).value, '');
  }

  void test_conditional() {
    checkSimpleExpression('false ? 0 : 1');
  }

  void test_divide() {
    checkSimpleExpression('0 / 1');
  }

  void test_equal() {
    checkSimpleExpression('0 == 1');
  }

  void test_extractIndex() {
    checkSimpleExpression('items[0]',
        extraDeclarations: 'var items = [0, 1, 2]');
  }

  void test_extractProperty() {
    checkSimpleExpression("'x'.length");
  }

  void test_floorDivide() {
    checkSimpleExpression('0 ~/ 1');
  }

  void test_greater() {
    checkSimpleExpression('0 > 1');
  }

  void test_greaterEqual() {
    checkSimpleExpression('0 >= 1');
  }

  void test_ifNull() {
    checkSimpleExpression('0 ?? 1');
  }

  void test_invokeConstructor_const() {
    checkSimpleExpression('const C()',
        extraDeclarations: '''
class C {
  const C();
}
''',
        requireValidConst: true);
  }

  void test_invokeConstructor_generic_hasTypeArguments() {
    checkSimpleExpression('new Map<int, List<String>>()');
  }

  void test_invokeConstructor_generic_noTypeArguments() {
    checkSimpleExpression('new Map()');
  }

  void test_invokeMethod() {
    checkSimpleExpression('new C().foo(1, 2)', extraDeclarations: r'''
class C {
  int foo(int a, int b) => 0;
}
''');
  }

  void test_invokeMethod_namedArguments() {
    checkSimpleExpression('new C().foo(a: 1, c: 3)', extraDeclarations: r'''
class C {
  int foo({int a, int b, int c}) => 0;
}
''');
  }

  void test_invokeMethod_typeArguments() {
    checkSimpleExpression('new C().foo<int, double>(1, 2.3)',
        extraDeclarations: r'''
class C {
  int foo<T, U>(T a, U b) => 0;
}
''',
        expectedText: 'new C().foo<int, double>()');
  }

  void test_invokeMethodRef() {
    checkSimpleExpression('identical(0, 0)');
  }

  void test_less() {
    checkSimpleExpression('0 < 1');
  }

  void test_lessEqual() {
    checkSimpleExpression('0 <= 1');
  }

  void test_makeSymbol() {
    checkSimpleExpression('#foo');
  }

  void test_makeTypedList_const() {
    checkSimpleExpression('const <int> []');
  }

  void test_makeTypedMap_const() {
    checkSimpleExpression('const <int, bool> {}');
  }

  void test_makeUntypedList_const() {
    checkSimpleExpression('const [0]');
  }

  void test_makeUntypedMap_const() {
    checkSimpleExpression('const {0 : false}');
  }

  void test_modulo() {
    checkSimpleExpression('0 % 1');
  }

  void test_multiply() {
    checkSimpleExpression('0 * 1');
  }

  void test_negate() {
    checkSimpleExpression('-1');
  }

  void test_not() {
    checkSimpleExpression('!true');
  }

  void test_notEqual() {
    checkSimpleExpression('0 != 1');
  }

  void test_or() {
    checkSimpleExpression('false || true');
  }

  void test_pushDouble() {
    checkSimpleExpression('0.5');
  }

  void test_pushFalse() {
    checkSimpleExpression('false');
  }

  void test_pushInt() {
    checkSimpleExpression('0');
  }

  void test_pushLocalFunctionReference() {
    checkSimpleExpression('() => 0');
  }

  void test_pushLocalFunctionReference_async() {
    checkSimpleExpression('() async => 0');
  }

  void test_pushLocalFunctionReference_block() {
    checkSimpleExpression('() {}');
  }

  void test_pushLocalFunctionReference_namedParam_untyped() {
    checkSimpleExpression('({x}) => 0');
  }

  void test_pushLocalFunctionReference_positionalParam_untyped() {
    checkSimpleExpression('([x]) => 0');
  }

  void test_pushLocalFunctionReference_requiredParam_typed() {
    var expr = checkSimpleExpression('(int x) => 0', expectedText: '(x) => 0')
        as FunctionExpression;
    var functionElement = expr.declaredElement;
    var xElement = functionElement.parameters[0] as ParameterElementImpl;
    expect(xElement.type.toString(), 'int');
  }

  void test_pushLocalFunctionReference_requiredParam_untyped() {
    checkSimpleExpression('(x) => 0');
  }

  void test_pushLongInt() {
    checkSimpleExpression('4294967296');
  }

  void test_pushNull() {
    checkSimpleExpression('null');
  }

  void test_pushParameter() {
    checkConstructorInitializer('''
class C {
  int x;
  const C(int p) : x = p;
}
''', 'p');
  }

  void test_pushReference() {
    checkSimpleExpression('int');
  }

  void test_pushReference_sequence() {
    checkSimpleExpression('a.b.f', extraDeclarations: r'''
var a = new A();
class A {
  B b = new B();
}
class B {
  int f = 0;
}
''');
  }

  void test_pushString() {
    checkSimpleExpression("'foo'");
  }

  void test_pushTrue() {
    checkSimpleExpression('true');
  }

  void test_subtract() {
    checkSimpleExpression('0 - 1');
  }

  void test_throwException() {
    checkSimpleExpression('throw 0');
  }

  void test_typeCast() {
    checkSimpleExpression('0 as num');
  }

  void test_typeCheck() {
    checkSimpleExpression('0 is num');
  }

  void test_typeCheck_negated() {
    checkSimpleExpression('0 is! num', expectedText: '!(0 is num)');
  }

  void xtest_pushLocalFunctionReference_nested() {
    // TODO(devoncarew): This test fails when run in strong mode.
    // Failed assertion: line 5116 pos 16:
    //   'Linker._initializerTypeInferenceCycle == null': is not true.
    prepareAnalysisContext(new AnalysisOptionsImpl()..previewDart2 = false);
    var expr =
        checkSimpleExpression('(x) => (y) => x + y') as FunctionExpression;
    var outerFunctionElement = expr.declaredElement;
    var xElement = outerFunctionElement.parameters[0];
    var x = expr.parameters.parameters[0];
    expect(x.declaredElement, same(xElement));
    var outerBody = expr.body as ExpressionFunctionBody;
    var outerBodyExpr = outerBody.expression as FunctionExpression;
    var innerFunctionElement = outerBodyExpr.declaredElement;
    var yElement = innerFunctionElement.parameters[0];
    var y = outerBodyExpr.parameters.parameters[0];
    expect(y.declaredElement, same(yElement));
    var innerBody = outerBodyExpr.body as ExpressionFunctionBody;
    var innerBodyExpr = innerBody.expression as BinaryExpression;
    var xRef = innerBodyExpr.leftOperand as SimpleIdentifier;
    var yRef = innerBodyExpr.rightOperand as SimpleIdentifier;
    expect(xRef.staticElement, same(xElement));
    expect(yRef.staticElement, same(yElement));
  }

  void xtest_pushLocalFunctionReference_paramReference() {
    // TODO(devoncarew): This test fails when run in strong mode.
    prepareAnalysisContext(new AnalysisOptionsImpl()..previewDart2 = false);
    var expr = checkSimpleExpression('(x, y) => x + y') as FunctionExpression;
    var localFunctionElement = expr.declaredElement;
    var xElement = localFunctionElement.parameters[0];
    var yElement = localFunctionElement.parameters[1];
    var x = expr.parameters.parameters[0];
    var y = expr.parameters.parameters[1];
    expect(x.declaredElement, same(xElement));
    expect(y.declaredElement, same(yElement));
    var body = expr.body as ExpressionFunctionBody;
    var bodyExpr = body.expression as BinaryExpression;
    var xRef = bodyExpr.leftOperand as SimpleIdentifier;
    var yRef = bodyExpr.rightOperand as SimpleIdentifier;
    expect(xRef.staticElement, same(xElement));
    expect(yRef.staticElement, same(yElement));
  }
}
