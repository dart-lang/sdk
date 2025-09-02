// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../utils.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test);
    defineReflectiveTests(StrongModeTypePropagationTest);
  });
}

/// Strong mode static analyzer local type inference tests.
@reflectiveTest
class StrongModeLocalInferenceTest extends PubPackageResolutionTest {
  TypeAssertions? _assertions;

  late final Asserter<DartType> _isDynamic;
  late final Asserter<DartType> _isInvalidType;
  late final Asserter<InterfaceType> _isFutureOfDynamic;
  late final Asserter<InterfaceType> _isFutureOfInt;
  late final Asserter<InterfaceType> _isFutureOfNull;
  late final Asserter<InterfaceType> _isFutureOrOfInt;
  late final Asserter<DartType> _isInt;
  late final Asserter<DartType> _isNever;
  late final Asserter<DartType> _isNull;
  late final Asserter<DartType> _isNum;
  late final Asserter<DartType> _isObject;
  late final Asserter<DartType> _isString;

  late final AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, DartType>
  _isFunction2Of;
  late final AsserterBuilder<List<Asserter<DartType>>, InterfaceType>
  _isFutureOf;
  late final AsserterBuilder<List<Asserter<DartType>>, InterfaceType>
  _isFutureOrOf;
  late final AsserterBuilderBuilder<
    Asserter<DartType>,
    List<Asserter<DartType>>,
    DartType
  >
  _isInstantiationOf;
  late final AsserterBuilder<Asserter<DartType>, InterfaceType> _isListOf;
  late final AsserterBuilder2<
    Asserter<DartType>,
    Asserter<DartType>,
    InterfaceType
  >
  _isMapOf;
  late final AsserterBuilder<DartType, DartType> _isType;

  late final AsserterBuilder<Element, DartType> _hasElement;

  CompilationUnit get unit => result.unit;

  @override
  Future<void> resolveTestFile() async {
    var result = await super.resolveTestFile();

    var assertions = _assertions;
    if (assertions == null) {
      assertions = _assertions = TypeAssertions(typeProvider);
      _isType = assertions.isType;
      _hasElement = assertions.hasElement;
      _isInstantiationOf = assertions.isInstantiationOf;
      _isInt = assertions.isInt;
      _isNever = assertions.isNever;
      _isNull = assertions.isNull;
      _isNum = assertions.isNum;
      _isObject = assertions.isObject;
      _isString = assertions.isString;
      _isDynamic = assertions.isDynamic;
      _isInvalidType = assertions.isInvalidType;
      _isListOf = assertions.isListOf;
      _isMapOf = assertions.isMapOf;
      _isFunction2Of = assertions.isFunction2Of;
      _isFutureOf = _isInstantiationOf(_hasElement(typeProvider.futureElement));
      _isFutureOrOf = _isInstantiationOf(
        _hasElement(typeProvider.futureOrElement),
      );
      _isFutureOfDynamic = _isFutureOf([_isDynamic]);
      _isFutureOfInt = _isFutureOf([_isInt]);
      _isFutureOfNull = _isFutureOf([_isNull]);
      _isFutureOrOfInt = _isFutureOrOf([_isInt]);
    }

    return result;
  }

  test_async_method_propagation() async {
    String code = r'''
      class A {
        Future f0() => new Future.value(3);
        Future f1() async => new Future.value(3);
        Future f2() async => await new Future.value(3);

        Future<int> f3() => new Future.value(3);
        Future<int> f4() async => new Future.value(3);
        Future<int> f5() async => await new Future.value(3);

        Future g0() { return new Future.value(3); }
        Future g1() async { return new Future.value(3); }
        Future g2() async { return await new Future.value(3); }

        Future<int> g3() { return new Future.value(3); }
        Future<int> g4() async { return new Future.value(3); }
        Future<int> g5() async { return await new Future.value(3); }
      }
   ''';
    await resolveTestCode(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      FunctionBody body = test.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        var stmt =
            (body as BlockFunctionBody).block.statements[0] as ReturnStatement;
        returnExp = stmt.expression!;
      }
      DartType type = returnExp.typeOrThrow;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.typeOrThrow;
      }
      typeTest(type as InterfaceType);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    check("f4", _isFutureOfInt);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    check("g4", _isFutureOfInt);
    check("g5", _isFutureOfInt);
  }

  test_async_propagation() async {
    String code = r'''
      Future f0() => new Future.value(3);
      Future f1() async => new Future.value(3);
      Future f2() async => await new Future.value(3);

      Future<int> f3() => new Future.value(3);
      Future<int> f4() async => new Future.value(3);
      Future<int> f5() async => await new Future.value(3);

      Future g0() { return new Future.value(3); }
      Future g1() async { return new Future.value(3); }
      Future g2() async { return await new Future.value(3); }

      Future<int> g3() { return new Future.value(3); }
      Future<int> g4() async { return new Future.value(3); }
      Future<int> g5() async { return await new Future.value(3); }
   ''';
    await resolveTestCode(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      var body = test.functionExpression.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        var stmt =
            (body as BlockFunctionBody).block.statements[0] as ReturnStatement;
        returnExp = stmt.expression!;
      }
      DartType type = returnExp.typeOrThrow;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.typeOrThrow;
      }
      typeTest(type as InterfaceType);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    check("f4", _isFutureOfInt);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    check("g4", _isFutureOfInt);
    check("g5", _isFutureOfInt);
  }

  test_cascadeExpression() async {
    String code = r'''
      class A<T> {
        List<T> map(T a, List<T> mapper(T x)) => mapper(a);
      }

      void main () {
        A<int> a = new A()..map(0, (x) => [x]);
     }
   ''';
    await resolveTestCode(code);
    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    CascadeExpression fetch(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as CascadeExpression;
      return exp;
    }

    var elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;

    CascadeExpression cascade = fetch(0);
    _isInstantiationOf(_hasElement(elementA))([_isInt])(cascade.typeOrThrow);
    var invoke = cascade.cascadeSections[0] as MethodInvocation;
    var function = invoke.argumentList.arguments[1] as FunctionExpression;
    ExecutableElement f0 = function.declaredFragment!.element;
    _isListOf(_isInt)(f0.type.returnType as InterfaceType);
    expect(f0.type.normalParameterTypes[0], typeProvider.intType);
  }

  test_constrainedByBounds1() async {
    // Test that upwards inference with two type variables correctly
    // propagates from the constrained variable to the unconstrained
    // variable if they are ordered left to right.
    String code = r'''
    T f<S, T extends S>(S x) => null;
    void test() { var x = f(3); }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 32, 4),
      error(WarningCode.unusedLocalVariable, 60, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test",
    );
    var stmt = statements[0] as VariableDeclarationStatement;
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer!;
    _isInt(call.typeOrThrow);
  }

  test_constrainedByBounds2() async {
    // Test that upwards inference with two type variables does
    // propagate from the constrained variable to the unconstrained
    // variable if they are ordered right to left.
    String code = r'''
    T f<T extends S, S>(S x) => null;
    void test() { var x = f(3); }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 32, 4),
      error(WarningCode.unusedLocalVariable, 60, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test",
    );
    var stmt = statements[0] as VariableDeclarationStatement;
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer!;
    _isInt(call.typeOrThrow);
  }

  test_constrainedByBounds3() async {
    var code = r'''
      T f<T extends S, S extends int>(S x) => null;
      void test() { var x = f(3); }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 46, 4),
      error(WarningCode.unusedLocalVariable, 76, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test",
    );
    var stmt = statements[0] as VariableDeclarationStatement;
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer!;
    _isInt(call.typeOrThrow);
  }

  test_constrainedByBounds4() async {
    // Test that upwards inference with two type variables correctly
    // propagates from the constrained variable to the unconstrained
    // variable if they are ordered left to right, when the variable
    // appears co and contra variantly
    String code = r'''
    typedef To Func1<From, To>(From x);
    T f<S, T extends Func1<S, S>>(S x) => null;
    void test() { var x = f(3)(4); }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 82, 4),
      error(WarningCode.unusedLocalVariable, 110, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test",
    );
    var stmt = statements[0] as VariableDeclarationStatement;
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer!;
    _isInt(call.typeOrThrow);
  }

  test_constrainedByBounds5() async {
    // Test that upwards inference with two type variables does not
    // propagate from the constrained variable to the unconstrained
    // variable if they are ordered right to left, when the variable
    // appears co- and contra-variantly, and that an error is issued
    // for the non-matching bound.
    String code = r'''
    typedef To Func1<From, To>(From x);
    T f<T extends Func1<S, S>, S>(S x) => null;
    void test() { var x = f(3)(null); }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 82, 4),
      error(WarningCode.unusedLocalVariable, 110, 1),
      error(CompileTimeErrorCode.couldNotInfer, 114, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 119, 4),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test",
    );
    var stmt = statements[0] as VariableDeclarationStatement;
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer!;
    _isType(call.typeOrThrow);
  }

  test_constructorInitializer_propagation() async {
    String code = r'''
      class A {
        List<String> x;
        A() : this.x = [];
      }
   ''';
    await assertNoErrorsInCode(code);
    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      unit,
      "A",
      null,
    );
    var assignment = constructor.initializers[0] as ConstructorFieldInitializer;
    Expression exp = assignment.expression;
    _isListOf(_isString)(exp.staticType as InterfaceType);
  }

  test_factoryConstructor_propagation() async {
    String code = r'''
      class A<T> {
        factory A() { return new B(); }
      }
      class B<S> extends A<S> {}
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.noGenerativeConstructorsInSuperclass, 92, 4),
    ]);

    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      unit,
      "A",
      null,
    );
    var body = constructor.body as BlockFunctionBody;
    var stmt = body.block.statements[0] as ReturnStatement;
    var exp = stmt.expression as InstanceCreationExpression;
    ClassElement elementB = AstFinder.getClass(
      unit,
      "B",
    ).declaredFragment!.element;
    ClassElement elementA = AstFinder.getClass(
      unit,
      "A",
    ).declaredFragment!.element;
    var type = exp.constructorName.type.typeOrThrow as InterfaceType;
    expect(type.element, elementB);
    _isInstantiationOf(_hasElement(elementB))([
      _isType(
        elementA.typeParameters[0].instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      ),
    ])(exp.typeOrThrow);
  }

  test_fieldDeclaration_propagation() async {
    String code = r'''
      class A {
        List<String> f0 = ["hello"];
      }
   ''';
    await assertNoErrorsInCode(code);

    VariableDeclaration field = AstFinder.getFieldInClass(unit, "A", "f0");

    _isListOf(_isString)(field.initializer!.staticType as InterfaceType);
  }

  test_functionDeclaration_body_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      List<int> test1() => [];

      Function2<int, int> test2 (int x) {
        Function2<String, int> inner() {
          return (x) => x.length;
        }
        return (x) => x;
     }
   ''';
    await assertErrorsInCode(code, [error(WarningCode.unusedElement, 144, 5)]);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    FunctionDeclaration test1 = AstFinder.getTopLevelFunction(unit, "test1");
    var body = test1.functionExpression.body as ExpressionFunctionBody;
    assertListOfInt(body.expression.staticType as InterfaceType);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test2",
    );

    FunctionDeclaration inner =
        (statements[0] as FunctionDeclarationStatement).functionDeclaration;
    var body0 = inner.functionExpression.body as BlockFunctionBody;
    var return0 = body0.block.statements[0] as ReturnStatement;
    Expression anon0 = return0.expression!;
    var type0 = anon0.staticType as FunctionType;
    expect(type0.returnType, typeProvider.intType);
    expect(type0.normalParameterTypes[0], typeProvider.stringType);

    var anon1 =
        (statements[1] as ReturnStatement).expression as FunctionExpression;
    FunctionType type1 = anon1.declaredFragment!.element.type;
    expect(type1.returnType, typeProvider.intType);
    expect(type1.normalParameterTypes[0], typeProvider.intType);
  }

  test_functionLiteral_assignment_typedArguments() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (int x) => null;
        Function2<int, String> l1 = (int x) => "hello";
        Function2<int, String> l2 = (String x) => "hello";
        Function2<int, String> l3 = (int x) => 3;
        Function2<int, String> l4 = (int x) {return 3;};
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 91, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 107, 4),
      error(WarningCode.unusedLocalVariable, 144, 2),
      error(WarningCode.unusedLocalVariable, 200, 2),
      error(CompileTimeErrorCode.invalidAssignment, 205, 21),
      error(WarningCode.unusedLocalVariable, 259, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 275, 1),
      error(WarningCode.unusedLocalVariable, 309, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 330, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_assignment_unTypedArguments() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (x) => null;
        Function2<int, String> l1 = (x) => "hello";
        Function2<int, String> l2 = (x) => "hello";
        Function2<int, String> l3 = (x) => 3;
        Function2<int, String> l4 = (x) {return 3;};
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 91, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 103, 4),
      error(WarningCode.unusedLocalVariable, 140, 2),
      error(WarningCode.unusedLocalVariable, 192, 2),
      error(WarningCode.unusedLocalVariable, 244, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 256, 1),
      error(WarningCode.unusedLocalVariable, 290, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 307, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_body_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, List<String>> l0 = (int x) => ["hello"];
        Function2<int, List<String>> l1 = (String x) => ["hello"];
        Function2<int, List<String>> l2 = (int x) => [3];
        Function2<int, List<String>> l3 = (int x) {return [3];};
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 97, 2),
      error(WarningCode.unusedLocalVariable, 161, 2),
      error(CompileTimeErrorCode.invalidAssignment, 166, 23),
      error(WarningCode.unusedLocalVariable, 228, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 245, 1),
      error(WarningCode.unusedLocalVariable, 286, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 308, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    Expression functionReturnValue(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as FunctionExpression;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression!;
      }
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(functionReturnValue(0).staticType as InterfaceType);
    assertListOfString(functionReturnValue(1).staticType as InterfaceType);
    assertListOfString(functionReturnValue(2).staticType as InterfaceType);
    assertListOfString(functionReturnValue(3).staticType as InterfaceType);
  }

  test_functionLiteral_functionExpressionInvocation_typedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        (new Mapper<int, String>().map)((int x) => null);
        (new Mapper<int, String>().map)((int x) => "hello");
        (new Mapper<int, String>().map)((String x) => "hello");
        (new Mapper<int, String>().map)((int x) => 3);
        (new Mapper<int, String>().map)((int x) {return 3;});
     }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 66, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 154, 4),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 262, 21),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 337, 1),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 397, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as ExpressionStatement;
      var invk = stmt.expression as FunctionExpressionInvocation;
      var exp = invk.argumentList.arguments[0] as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionExpressionInvocation_unTypedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        (new Mapper<int, String>().map)((x) => null);
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => 3);
        (new Mapper<int, String>().map)((x) {return 3;});
     }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 66, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 150, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 318, 1),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 374, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as ExpressionStatement;
      var invk = stmt.expression as FunctionExpressionInvocation;
      var exp = invk.argumentList.arguments[0] as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionInvocation_typedArguments() async {
    String code = r'''
      String map(String mapper(int x)) => mapper(null);

      void main () {
        map((int x) => null);
        map((int x) => "hello");
        map((String x) => "hello");
        map((int x) => 3);
        map((int x) {return 3;});
     }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 49, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 101, 4),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 153, 21),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 200, 1),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 232, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as ExpressionStatement;
      var invk = stmt.expression as MethodInvocation;
      var exp = invk.argumentList.arguments[0] as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionInvocation_unTypedArguments() async {
    String code = r'''
      String map(String mapper(int x)) => mapper(null);

      void main () {
        map((x) => null);
        map((x) => "hello");
        map((x) => "hello");
        map((x) => 3);
        map((x) {return 3;});
     }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 49, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 97, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 181, 1),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 209, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as ExpressionStatement;
      var invk = stmt.expression as MethodInvocation;
      var exp = invk.argumentList.arguments[0] as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_methodInvocation_typedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        new Mapper<int, String>().map((int x) => null);
        new Mapper<int, String>().map((int x) => "hello");
        new Mapper<int, String>().map((String x) => "hello");
        new Mapper<int, String>().map((int x) => 3);
        new Mapper<int, String>().map((int x) {return 3;});
     }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 66, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 152, 4),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 256, 21),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 329, 1),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 387, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as ExpressionStatement;
      var invk = stmt.expression as MethodInvocation;
      var exp = invk.argumentList.arguments[0] as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_methodInvocation_unTypedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        new Mapper<int, String>().map((x) => null);
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => 3);
        new Mapper<int, String>().map((x) {return 3;});
     }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 66, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 148, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 310, 1),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 364, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as ExpressionStatement;
      var invk = stmt.expression as MethodInvocation;
      var exp = invk.argumentList.arguments[0] as FunctionExpression;
      return exp.declaredFragment!.element.type;
    }

    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_unTypedArgument_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, int> l0 = (x) => x;
        Function2<int, int> l1 = (x) => x+1;
        Function2<int, String> l2 = (x) => x;
        Function2<int, String> l3 = (x) => x.toLowerCase();
        Function2<String, String> l4 = (x) => x.toLowerCase();
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 88, 2),
      error(WarningCode.unusedLocalVariable, 131, 2),
      error(WarningCode.unusedLocalVariable, 179, 2),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromClosure, 191, 1),
      error(WarningCode.unusedLocalVariable, 225, 2),
      error(CompileTimeErrorCode.undefinedMethod, 239, 11),
      error(WarningCode.unusedLocalVariable, 288, 2),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    Expression functionReturnValue(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as FunctionExpression;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression!;
      }
    }

    expect(functionReturnValue(0).staticType, typeProvider.intType);
    expect(functionReturnValue(1).staticType, typeProvider.intType);
    expect(functionReturnValue(2).staticType, typeProvider.intType);
    expect(functionReturnValue(3).staticType, InvalidTypeImpl.instance);
    expect(functionReturnValue(4).staticType, typeProvider.stringType);
  }

  test_futureOr_assignFromFuture() async {
    // Test a Future<T> can be assigned to FutureOr<T>.
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOrOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_assignFromValue() async {
    // Test a T can be assigned to FutureOr<T>.
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(T x) => x;
    test() => mk(42);
    ''');
    _isFutureOrOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_asyncExpressionBody() async {
    // A FutureOr<T> can be used as the expression body for an async function
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async => x;
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_asyncReturn() async {
    // A FutureOr<T> can be used as the return value for an async function
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async { return x; }
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_await() async {
    // Test a FutureOr<T> can be awaited.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async => await x;
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_downwards1() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters.
    MethodInvocation invoke = await _testFutureOr(
      r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    Future<int> test() => mk(new Future<int>.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 60, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_downwards2() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(
      r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<int> test() => mk(new Future<int>.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 60, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_downwards3() async {
    // Test that downwards inference correctly propagates into
    // arguments.
    MethodInvocation invoke = await _testFutureOr(
      r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    Future<int> test() => mk(new Future.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 60, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].staticType as InterfaceType,
    );
  }

  test_futureOr_downwards4() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(
      r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 60, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].staticType as InterfaceType,
    );
  }

  test_futureOr_downwards5() async {
    // Test that downwards inference correctly pins the type when it
    // comes from a FutureOr
    MethodInvocation invoke = await _testFutureOr(
      r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<num> test() => mk(new Future.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 60, 4),
      ],
    );
    _isFutureOf([_isNum])(invoke.staticType as InterfaceType);
    _isFutureOf([_isNum])(
      invoke.argumentList.arguments[0].staticType as InterfaceType,
    );
  }

  test_futureOr_downwards6() async {
    // Test that downwards inference doesn't decompose FutureOr
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(
      r'''
    T mk<T>(T x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 42, 4),
      ],
    );
    _isFutureOrOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].staticType as InterfaceType,
    );
  }

  test_futureOr_downwards7() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(
      r'''
      T mk<T extends Future<int>>(T x) => null;
      FutureOr<int> test() => mk(new Future.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 64, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].staticType as InterfaceType,
    );
  }

  test_futureOr_downwards8() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    // TODO(leafp): I think this should pass once the inference changes
    // that jmesserly is adding are landed.
    MethodInvocation invoke = await _testFutureOr(
      r'''
    T mk<T extends Future<Object>>(T x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 65, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].staticType as InterfaceType,
    );
  }

  test_futureOr_downwards9() async {
    // Test that downwards inference decomposes correctly with
    // other composite types
    MethodInvocation invoke = await _testFutureOr(
      r'''
    List<T> mk<T>(T x) => null;
    FutureOr<List<int>> test() => mk(3);
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 48, 4),
      ],
    );
    _isListOf(_isInt)(invoke.staticType as InterfaceType);
    _isInt(invoke.argumentList.arguments[0].typeOrThrow);
  }

  test_futureOr_methods1() async {
    // Test that FutureOr has the Object methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.toString();
    ''');
    _isString(invoke.typeOrThrow);
  }

  test_futureOr_methods2() async {
    // Test that FutureOr does not have the constituent type methods
    MethodInvocation invoke = await _testFutureOr(
      r'''
    dynamic test(FutureOr<int> x) => x.abs();
    ''',
      expectedErrors: [error(CompileTimeErrorCode.undefinedMethod, 61, 3)],
    );
    _isInvalidType(invoke.typeOrThrow);
  }

  test_futureOr_methods3() async {
    // Test that FutureOr does not have the Future type methods
    MethodInvocation invoke = await _testFutureOr(
      r'''
    dynamic test(FutureOr<int> x) => x.then((x) => x);
    ''',
      expectedErrors: [error(CompileTimeErrorCode.undefinedMethod, 61, 4)],
    );
    _isInvalidType(invoke.typeOrThrow);
  }

  test_futureOr_methods4() async {
    // Test that FutureOr<dynamic> does not have all methods
    MethodInvocation invoke = await _testFutureOr(
      r'''
    dynamic test(FutureOr<dynamic> x) => x.abs();
    ''',
      expectedErrors: [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          65,
          3,
        ),
      ],
    );
    _isInvalidType(invoke.typeOrThrow);
  }

  test_futureOr_no_return() async {
    MethodInvocation invoke = await _testFutureOr(
      r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {});
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 79, 1),
      ],
    );
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOr_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(
      r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {return;});
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 79, 1),
      ],
    );
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOr_return_null() async {
    MethodInvocation invoke = await _testFutureOr(
      r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {return null;});
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 79, 1),
      ],
    );
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOr_upwards1() async {
    // Test that upwards inference correctly prefers to instantiate type
    // variables with the "smaller" solution when both are possible.
    MethodInvocation invoke = await _testFutureOr(
      r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    dynamic test() => mk(new Future<int>.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 60, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_upwards2() async {
    // Test that upwards inference fails when the solution doesn't
    // match the bound.
    MethodInvocation invoke = await _testFutureOr(
      r'''
    T mk<T extends Future<Object>>(FutureOr<T> x) => null;
    dynamic test() => mk(new Future<int>.value(42));
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 75, 4),
      ],
    );
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOrNull_no_return() async {
    MethodInvocation invoke = await _testFutureOr(
      r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) {});
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 79, 1),
      ],
    );
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOrNull_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(
      r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) {return;});
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 79, 1),
      ],
    );
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOrNull_return_null() async {
    MethodInvocation invoke = await _testFutureOr(
      r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) { return null;});
    ''',
      expectedErrors: [
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 79, 1),
      ],
    );
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_generic_partial() async {
    // Test that upward and downward type inference handles partial
    // type schemas correctly.  Downwards inference in a partial context
    // (e.g. Map<String, ?>) should still allow upwards inference to fill
    // in the missing information.
    String code = r'''
class A<T> {
  A(T x);
  A.fromA(A<T> a) {}
  A.fromMap(Map<String, T> m) {}
  A.fromList(List<T> m) {}
  A.fromT(T t) {}
  A.fromB(B<T, String> a) {}
}

class B<S, T> {
  B(S s);
}

void test() {
    var a0 = new A.fromA(new A(3));
    var a1 = new A.fromMap({'hello' : 3});
    var a2 = new A.fromList([3]);
    var a3 = new A.fromT(3);
    var a4 = new A.fromB(new B(3));
}
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 205, 2),
      error(WarningCode.unusedLocalVariable, 241, 2),
      error(WarningCode.unusedLocalVariable, 284, 2),
      error(WarningCode.unusedLocalVariable, 318, 2),
      error(WarningCode.unusedLocalVariable, 347, 2),
    ]);

    Element elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;
    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "test",
    );
    void check(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression init = decl.initializer!;
      _isInstantiationOf(_hasElement(elementA))([_isInt])(init.typeOrThrow);
    }

    for (var i = 0; i < 5; i++) {
      check(i);
    }
  }

  test_inferConstructor_unknownTypeLowerBound() async {
    var code = r'''
        class C<T> {
          C(void callback(List<T> a));
        }
        test() {
          // downwards inference pushes List<?> and in parameter position this
          // becomes inferred as List<Null>.
          var c = new C((items) {});
        }
        ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 225, 1),
    ]);

    DartType cType = findElement2.localVar('c').type;
    Element elementC = AstFinder.getClass(unit, "C").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementC))([_isType])(cType);
  }

  test_inference_error_arguments() async {
    var code = r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(F<T, T> f) => (x) => f(f(x));

test() {
  var h = g((int x) => 42.0);
}
 ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 84, 1),
      error(CompileTimeErrorCode.couldNotInfer, 88, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 90, 15),
    ]);
    _expectInferenceError(r'''
Couldn't infer type parameter 'T'.

Tried to infer 'double' for 'T' which doesn't work:
  Parameter 'f' declared as     'T Function(T)'
                but argument is 'double Function(int)'.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_arguments2() async {
    var code = r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(F<T, T> a, F<T, T> b) => (x) => a(b(x));

test() {
  var h = g((int x) => 42.0, (double x) => 42);
}
 ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 95, 1),
      error(CompileTimeErrorCode.couldNotInfer, 99, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 101, 15),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 118, 16),
    ]);
    _expectInferenceError(r'''
Couldn't infer type parameter 'T'.

Tried to infer 'num' for 'T' which doesn't work:
  Parameter 'a' declared as     'T Function(T)'
                but argument is 'double Function(int)'.
  Parameter 'b' declared as     'T Function(T)'
                but argument is 'int Function(double)'.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_extendsFromReturn() async {
    // This is not an inference error because we successfully infer Null.
    var code = r'''
T max<T extends num>(T x, T y) => x;

test() {
  String hello = max(1, 2);
}
 ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 56, 5),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 68, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 71, 1),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: max
    element: <testLibrary>::@function::max
    staticType: T Function<T extends num>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::max::@formalParameter::x
          substitution: {T: Never}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::max::@formalParameter::y
          substitution: {T: Never}
        staticType: int
    rightParenthesis: )
  staticInvokeType: Never Function(Never, Never)
  staticType: Never
  typeArgumentTypes
    Never
''');
  }

  test_inference_error_extendsFromReturn2() async {
    var code = r'''
typedef R F<T, R>(T t);
F<T, T> g<T extends num>() => (y) => y;

test() {
  F<String, String> hello = g();
}
 ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 94, 5),
      error(CompileTimeErrorCode.invalidAssignment, 102, 3),
    ]);
  }

  test_inference_error_genericFunction() async {
    var code = r'''
T max<T extends num>(T x, T y) => x < y ? y : x;
abstract class Iterable<T> {
  T get first;
  S fold<S>(S s, S f(S s, T t));
}
test(Iterable values) {
  num n = values.fold(values.first as num, max);
}
 ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 158, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 195, 3),
    ]);
  }

  test_inference_error_returnContext() async {
    var code = r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(T t) => (x) => t;

test() {
  F<num, int> h = g(42);
}
 ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 80, 1),
      error(CompileTimeErrorCode.couldNotInfer, 84, 1),
      error(CompileTimeErrorCode.invalidAssignment, 84, 5),
    ]);
    _expectInferenceError(r'''
Couldn't infer type parameter 'T'.

Tried to infer 'num' for 'T' which doesn't work:
  Return type declared as 'T Function(T)'
              used where  'int Function(num)' is required.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_hints() async {
    var code = r'''
      void main () {
        var x = 3;
        List<int> l0 = [];
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 33, 1),
      error(WarningCode.unusedLocalVariable, 58, 2),
    ]);
  }

  test_inference_simplePolymorphicRecursion_function() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with a function type
    var code = r'''
void _mergeSort<T>(T Function(T) list, int compare(T a, T b), T Function(T) target) {
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''';
    await assertErrorsInCode(code, [error(WarningCode.unusedElement, 5, 10)]);

    var node = findNode.singleBlock;
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T Function(T), int Function(T, T), T Function(T))
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T Function(T)
          rightParenthesis: )
        staticInvokeType: void Function(T Function(T), int Function(T, T), T Function(T))
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T Function(T), int Function(T, T), T Function(T))
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T Function(T)
          rightParenthesis: )
        staticInvokeType: void Function(T Function(T), int Function(T, T), T Function(T))
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T Function(T), int Function(T, T), T Function(T))
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T Function(T)
          rightParenthesis: )
        staticInvokeType: void Function(T Function(T), int Function(T, T), T Function(T))
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T Function(T), int Function(T, T), T Function(T))
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T Function(T)
          rightParenthesis: )
        staticInvokeType: void Function(T Function(T), int Function(T, T), T Function(T))
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
  rightBracket: }
''');
  }

  test_inference_simplePolymorphicRecursion_interface() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with an interface type
    var code = r'''
void _mergeSort<T>(List<T> list, int compare(T a, T b), List<T> target) {
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''';
    await assertErrorsInCode(code, [error(WarningCode.unusedElement, 5, 10)]);

    var node = findNode.singleBlock;
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(List<T>, int Function(T, T), List<T>)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: List<T>
          rightParenthesis: )
        staticInvokeType: void Function(List<T>, int Function(T, T), List<T>)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(List<T>, int Function(T, T), List<T>)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: List<T>
          rightParenthesis: )
        staticInvokeType: void Function(List<T>, int Function(T, T), List<T>)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(List<T>, int Function(T, T), List<T>)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: List<T>
          rightParenthesis: )
        staticInvokeType: void Function(List<T>, int Function(T, T), List<T>)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(List<T>, int Function(T, T), List<T>)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: List<T>
          rightParenthesis: )
        staticInvokeType: void Function(List<T>, int Function(T, T), List<T>)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
  rightBracket: }
''');
  }

  test_inference_simplePolymorphicRecursion_simple() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with a simple type parameter
    var code = r'''
void _mergeSort<T>(T list, int compare(T a, T b), T target) {
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''';
    await assertErrorsInCode(code, [error(WarningCode.unusedElement, 5, 10)]);

    var node = findNode.singleBlock;
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T, int Function(T, T), T)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T
          rightParenthesis: )
        staticInvokeType: void Function(T, int Function(T, T), T)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T, int Function(T, T), T)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T
          rightParenthesis: )
        staticInvokeType: void Function(T, int Function(T, T), T)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T, int Function(T, T), T)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T
          rightParenthesis: )
        staticInvokeType: void Function(T, int Function(T, T), T)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: _mergeSort
          element: <testLibrary>::@function::_mergeSort
          staticType: void Function<T>(T, int Function(T, T), T)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: target
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: ParameterMember
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::target
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T
          rightParenthesis: )
        staticInvokeType: void Function(T, int Function(T, T), T)
        staticType: void
        typeArgumentTypes
          T
      semicolon: ;
  rightBracket: }
''');
  }

  test_inferGenericInstantiation() async {
    // Verify that we don't infer '?` when we instantiate a generic function.
    var code = r'''
T f<T>(T x(T t)) => x(null);
S g<S>(S s) => s;
test() {
 var h = f(g);
}
    ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 22, 4),
      error(WarningCode.unusedLocalVariable, 61, 1),
    ]);

    var node = findNode.methodInvocation('f(g)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>(T Function(T))
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      FunctionReference
        function: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: S Function<S>(S)
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::f::@formalParameter::x
          substitution: {T: dynamic}
        staticType: dynamic Function(dynamic)
        typeArgumentTypes
          dynamic
    rightParenthesis: )
  staticInvokeType: dynamic Function(dynamic Function(dynamic))
  staticType: dynamic
  typeArgumentTypes
    dynamic
''');
  }

  test_inferGenericInstantiation2() async {
    // Verify the behavior when we cannot infer an instantiation due to invalid
    // constraints from an outer generic method.
    var code = r'''
T max<T extends num>(T x, T y) => x < y ? y : x;
abstract class Iterable<T> {
  T get first;
  S fold<S>(S s, S f(S s, T t));
}
num test(Iterable values) => values.fold(values.first as num, max);
    ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 190, 3),
    ]);

    var node = findNode.methodInvocation('values.fold');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: values
    element: <testLibrary>::@function::test::@formalParameter::values
    staticType: Iterable<dynamic>
  operator: .
  methodName: SimpleIdentifier
    token: fold
    element: MethodMember
      baseElement: <testLibrary>::@class::Iterable::@method::fold
      substitution: {T: dynamic, S: S}
    staticType: S Function<S>(S, S Function(S, dynamic))
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      AsExpression
        expression: PrefixedIdentifier
          prefix: SimpleIdentifier
            token: values
            element: <testLibrary>::@function::test::@formalParameter::values
            staticType: Iterable<dynamic>
          period: .
          identifier: SimpleIdentifier
            token: first
            element: GetterMember
              baseElement: <testLibrary>::@class::Iterable::@getter::first
              substitution: {T: dynamic}
            staticType: dynamic
          element: GetterMember
            baseElement: <testLibrary>::@class::Iterable::@getter::first
            substitution: {T: dynamic}
          staticType: dynamic
        asOperator: as
        type: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        correspondingParameter: ParameterMember
          baseElement: s@null
          substitution: {S: num}
        staticType: num
      FunctionReference
        function: SimpleIdentifier
          token: max
          element: <testLibrary>::@function::max
          staticType: T Function<T extends num>(T, T)
        correspondingParameter: ParameterMember
          baseElement: f@null
          substitution: {S: num}
        staticType: num Function(num, num)
        typeArgumentTypes
          num
    rightParenthesis: )
  staticInvokeType: num Function(num, num Function(num, dynamic))
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_inferredFieldDeclaration_propagation() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25546
    String code = r'''
      abstract class A {
        Map<int, List<int>> get map;
      }
      class B extends A {
        var map = { 42: [] };
      }
      class C extends A {
        get map => { 43: [] };
      }
   ''';
    await assertNoErrorsInCode(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertMapOfIntToListOfInt = _isMapOf(
      _isInt,
      (DartType type) => assertListOfInt(type as InterfaceType),
    );

    VariableDeclaration mapB = AstFinder.getFieldInClass(unit, "B", "map");
    MethodDeclaration mapC = AstFinder.getMethodInClass(unit, "C", "map");
    assertMapOfIntToListOfInt(
      mapB.declaredFragment!.element.type as InterfaceType,
    );
    assertMapOfIntToListOfInt(
      mapC.declaredFragment!.element.returnType as InterfaceType,
    );

    var mapLiteralB = mapB.initializer as SetOrMapLiteral;
    var mapLiteralC =
        (mapC.body as ExpressionFunctionBody).expression as SetOrMapLiteral;
    assertMapOfIntToListOfInt(mapLiteralB.staticType as InterfaceType);
    assertMapOfIntToListOfInt(mapLiteralC.staticType as InterfaceType);

    var listLiteralB =
        (mapLiteralB.elements[0] as MapLiteralEntry).value as ListLiteral;
    var listLiteralC =
        (mapLiteralC.elements[0] as MapLiteralEntry).value as ListLiteral;
    assertListOfInt(listLiteralB.staticType as InterfaceType);
    assertListOfInt(listLiteralC.staticType as InterfaceType);
  }

  test_instanceCreation() async {
    String code = r'''
      class A<S, T> {
        S x;
        T y;
        A(this.x, this.y);
        A.named(this.x, this.y);
      }

      class B<S, T> extends A<T, S> {
        B(S y, T x) : super(x, y);
        B.named(S y, T x) : super.named(x, y);
      }

      class C<S> extends B<S, S> {
        C(S a) : super(a, a);
        C.named(S a) : super.named(a, a);
      }

      class D<S, T> extends B<T, int> {
        D(T a) : super(a, 3);
        D.named(T a) : super.named(a, 3);
      }

      class E<S, T> extends A<C<S>, T> {
        E(T a) : super(null, a);
      }

      class F<S, T> extends A<S, T> {
        F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
        F.named(S x, T y, [S a, T b]) : super(a, b);
      }

      void test0() {
        A<int, String> a0 = new A(3, "hello");
        A<int, String> a1 = new A.named(3, "hello");
        A<int, String> a2 = new A<int, String>(3, "hello");
        A<int, String> a3 = new A<int, String>.named(3, "hello");
        A<int, String> a4 = new A<int, dynamic>(3, "hello");
        A<int, String> a5 = new A<dynamic, dynamic>.named(3, "hello");
      }
      void test1()  {
        A<int, String> a0 = new A("hello", 3);
        A<int, String> a1 = new A.named("hello", 3);
      }
      void test2() {
        A<int, String> a0 = new B("hello", 3);
        A<int, String> a1 = new B.named("hello", 3);
        A<int, String> a2 = new B<String, int>("hello", 3);
        A<int, String> a3 = new B<String, int>.named("hello", 3);
        A<int, String> a4 = new B<String, dynamic>("hello", 3);
        A<int, String> a5 = new B<dynamic, dynamic>.named("hello", 3);
      }
      void test3() {
        A<int, String> a0 = new B(3, "hello");
        A<int, String> a1 = new B.named(3, "hello");
      }
      void test4() {
        A<int, int> a0 = new C(3);
        A<int, int> a1 = new C.named(3);
        A<int, int> a2 = new C<int>(3);
        A<int, int> a3 = new C<int>.named(3);
        A<int, int> a4 = new C<dynamic>(3);
        A<int, int> a5 = new C<dynamic>.named(3);
      }
      void test5() {
        A<int, int> a0 = new C("hello");
        A<int, int> a1 = new C.named("hello");
      }
      void test6()  {
        A<int, String> a0 = new D("hello");
        A<int, String> a1 = new D.named("hello");
        A<int, String> a2 = new D<int, String>("hello");
        A<int, String> a3 = new D<String, String>.named("hello");
        A<int, String> a4 = new D<num, dynamic>("hello");
        A<int, String> a5 = new D<dynamic, dynamic>.named("hello");
      }
      void test7() {
        A<int, String> a0 = new D(3);
        A<int, String> a1 = new D.named(3);
      }
      void test8() {
        A<C<int>, String> a0 = new E("hello");
      }
      void test9() { // Check named and optional arguments
        A<int, String> a0 = new F(3, "hello", a: [3], b: ["hello"]);
        A<int, String> a1 = new F(3, "hello", a: ["hello"], b:[3]);
        A<int, String> a2 = new F.named(3, "hello", 3, "hello");
        A<int, String> a3 = new F.named(3, "hello");
        A<int, String> a4 = new F.named(3, "hello", "hello", 3);
        A<int, String> a5 = new F.named(3, "hello", "hello");
      }''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 547, 4),
      error(CompileTimeErrorCode.missingDefaultValueForParameter, 633, 1),
      error(CompileTimeErrorCode.missingDefaultValueForParameter, 644, 1),
      error(
        CompileTimeErrorCode.missingDefaultValueForParameterPositional,
        692,
        1,
      ),
      error(
        CompileTimeErrorCode.missingDefaultValueForParameterPositional,
        697,
        1,
      ),
      error(WarningCode.unusedLocalVariable, 769, 2),
      error(WarningCode.unusedLocalVariable, 816, 2),
      error(WarningCode.unusedLocalVariable, 869, 2),
      error(WarningCode.unusedLocalVariable, 929, 2),
      error(WarningCode.unusedLocalVariable, 995, 2),
      error(CompileTimeErrorCode.invalidAssignment, 1000, 31),
      error(WarningCode.unusedLocalVariable, 1056, 2),
      error(CompileTimeErrorCode.invalidAssignment, 1061, 41),
      error(WarningCode.unusedLocalVariable, 1157, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1168, 7),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1177, 1),
      error(WarningCode.unusedLocalVariable, 1204, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1221, 7),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1230, 1),
      error(WarningCode.unusedLocalVariable, 1286, 2),
      error(WarningCode.unusedLocalVariable, 1333, 2),
      error(WarningCode.unusedLocalVariable, 1386, 2),
      error(WarningCode.unusedLocalVariable, 1446, 2),
      error(WarningCode.unusedLocalVariable, 1512, 2),
      error(CompileTimeErrorCode.invalidAssignment, 1517, 34),
      error(WarningCode.unusedLocalVariable, 1576, 2),
      error(CompileTimeErrorCode.invalidAssignment, 1581, 41),
      error(WarningCode.unusedLocalVariable, 1676, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1687, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1690, 7),
      error(WarningCode.unusedLocalVariable, 1723, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1740, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 1743, 7),
      error(WarningCode.unusedLocalVariable, 1802, 2),
      error(WarningCode.unusedLocalVariable, 1837, 2),
      error(WarningCode.unusedLocalVariable, 1878, 2),
      error(WarningCode.unusedLocalVariable, 1918, 2),
      error(WarningCode.unusedLocalVariable, 1964, 2),
      error(CompileTimeErrorCode.invalidAssignment, 1969, 17),
      error(WarningCode.unusedLocalVariable, 2008, 2),
      error(CompileTimeErrorCode.invalidAssignment, 2013, 23),
      error(WarningCode.unusedLocalVariable, 2087, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 2098, 7),
      error(WarningCode.unusedLocalVariable, 2128, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 2145, 7),
      error(WarningCode.unusedLocalVariable, 2208, 2),
      error(WarningCode.unusedLocalVariable, 2252, 2),
      error(WarningCode.unusedLocalVariable, 2302, 2),
      error(WarningCode.unusedLocalVariable, 2359, 2),
      error(WarningCode.unusedLocalVariable, 2425, 2),
      error(CompileTimeErrorCode.invalidAssignment, 2430, 28),
      error(WarningCode.unusedLocalVariable, 2483, 2),
      error(CompileTimeErrorCode.invalidAssignment, 2488, 38),
      error(WarningCode.unusedLocalVariable, 2580, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 2591, 1),
      error(WarningCode.unusedLocalVariable, 2618, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 2635, 1),
      error(WarningCode.unusedLocalVariable, 2694, 2),
      error(WarningCode.unusedLocalVariable, 2805, 2),
      error(WarningCode.unusedLocalVariable, 2874, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 2901, 7),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 2914, 1),
      error(WarningCode.unusedLocalVariable, 2942, 2),
      error(WarningCode.unusedLocalVariable, 3007, 2),
      error(WarningCode.unusedLocalVariable, 3060, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 3089, 7),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 3098, 1),
      error(WarningCode.unusedLocalVariable, 3125, 2),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 3154, 7),
    ]);

    Expression rhs(AstNode stmt) {
      stmt as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression exp = decl.initializer!;
      return exp;
    }

    void hasType(Asserter<DartType> assertion, Expression exp) =>
        assertion(exp.typeOrThrow);

    Element elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;
    Element elementB = AstFinder.getClass(unit, "B").declaredFragment!.element;
    Element elementC = AstFinder.getClass(unit, "C").declaredFragment!.element;
    Element elementD = AstFinder.getClass(unit, "D").declaredFragment!.element;
    Element elementE = AstFinder.getClass(unit, "E").declaredFragment!.element;
    Element elementF = AstFinder.getClass(unit, "F").declaredFragment!.element;

    AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf =
        _isInstantiationOf(_hasElement(elementA));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf =
        _isInstantiationOf(_hasElement(elementB));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertCOf =
        _isInstantiationOf(_hasElement(elementC));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertDOf =
        _isInstantiationOf(_hasElement(elementD));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf =
        _isInstantiationOf(_hasElement(elementE));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertFOf =
        _isInstantiationOf(_hasElement(elementF));

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test0",
      ).cast<VariableDeclarationStatement>();

      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertAOf([_isInt, _isDynamic]), rhs(statements[4]));
      hasType(assertAOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test1",
      ).cast<VariableDeclarationStatement>();
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test2",
      ).cast<VariableDeclarationStatement>();
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[2]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[3]));
      hasType(assertBOf([_isString, _isDynamic]), rhs(statements[4]));
      hasType(assertBOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test3",
      ).cast<VariableDeclarationStatement>();
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test4",
      ).cast<VariableDeclarationStatement>();
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
      hasType(assertCOf([_isInt]), rhs(statements[2]));
      hasType(assertCOf([_isInt]), rhs(statements[3]));
      hasType(assertCOf([_isDynamic]), rhs(statements[4]));
      hasType(assertCOf([_isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test5",
      ).cast<VariableDeclarationStatement>();
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
    }

    {
      // The first type parameter is not constrained by the
      // context.  We could choose a tighter type, but currently
      // we just use dynamic.
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test6",
      ).cast<VariableDeclarationStatement>();
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
      hasType(assertDOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertDOf([_isString, _isString]), rhs(statements[3]));
      hasType(assertDOf([_isNum, _isDynamic]), rhs(statements[4]));
      hasType(assertDOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test7",
      ).cast<VariableDeclarationStatement>();
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test8",
      ).cast<VariableDeclarationStatement>();
      hasType(assertEOf([_isInt, _isString]), rhs(statements[0]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        unit,
        "test9",
      ).cast<VariableDeclarationStatement>();
      hasType(assertFOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[4]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[5]));
    }
  }

  test_listLiteral_nested() async {
    String code = r'''
      void main () {
        List<List<int>> l0 = [[]];
        Iterable<List<int>> l1 = [[3]];
        Iterable<List<int>> l2 = [[3], [4]];
        List<List<int>> l3 = [["hello", 3], []];
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 45, 2),
      error(WarningCode.unusedLocalVariable, 84, 2),
      error(WarningCode.unusedLocalVariable, 124, 2),
      error(WarningCode.unusedLocalVariable, 165, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 172, 7),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    ListLiteral literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as ListLiteral;
      return exp;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertListOfListOfInt = _isListOf(
      (DartType type) => assertListOfInt(type as InterfaceType),
    );

    assertListOfListOfInt(literal(0).staticType as InterfaceType);
    assertListOfListOfInt(literal(1).staticType as InterfaceType);
    assertListOfListOfInt(literal(2).staticType as InterfaceType);
    assertListOfListOfInt(literal(3).staticType as InterfaceType);

    assertListOfInt(
      (literal(1).elements[0] as Expression).staticType as InterfaceType,
    );
    assertListOfInt(
      (literal(2).elements[0] as Expression).staticType as InterfaceType,
    );
    assertListOfInt(
      (literal(3).elements[0] as Expression).staticType as InterfaceType,
    );
  }

  test_listLiteral_simple() async {
    String code = r'''
      void main () {
        List<int> l0 = [];
        List<int> l1 = [3];
        List<int> l2 = ["hello"];
        List<int> l3 = ["hello", 3];
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 39, 2),
      error(WarningCode.unusedLocalVariable, 66, 2),
      error(WarningCode.unusedLocalVariable, 94, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 100, 7),
      error(WarningCode.unusedLocalVariable, 128, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 134, 7),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as ListLiteral;
      return exp.typeOrThrow;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0) as InterfaceType);
    assertListOfInt(literal(1) as InterfaceType);
    assertListOfInt(literal(2) as InterfaceType);
    assertListOfInt(literal(3) as InterfaceType);
  }

  test_listLiteral_simple_const() async {
    String code = r'''
      void main () {
        const List<int> c0 = const [];
        const List<int> c1 = const [3];
        const List<int> c2 = const ["hello"];
        const List<int> c3 = const ["hello", 3];
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 45, 2),
      error(WarningCode.unusedLocalVariable, 84, 2),
      error(WarningCode.unusedLocalVariable, 124, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 136, 7),
      error(WarningCode.unusedLocalVariable, 170, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 182, 7),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as ListLiteral;
      return exp.typeOrThrow;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0) as InterfaceType);
    assertListOfInt(literal(1) as InterfaceType);
    assertListOfInt(literal(2) as InterfaceType);
    assertListOfInt(literal(3) as InterfaceType);
  }

  test_listLiteral_simple_disabled() async {
    String code = r'''
      void main () {
        List<int> l0 = <num>[];
        List<int> l1 = <num>[3];
        List<int> l2 = <String>["hello"];
        List<int> l3 = <dynamic>["hello", 3];
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 39, 2),
      error(CompileTimeErrorCode.invalidAssignment, 44, 7),
      error(WarningCode.unusedLocalVariable, 71, 2),
      error(CompileTimeErrorCode.invalidAssignment, 76, 8),
      error(WarningCode.unusedLocalVariable, 104, 2),
      error(CompileTimeErrorCode.invalidAssignment, 109, 17),
      error(WarningCode.unusedLocalVariable, 146, 2),
      error(CompileTimeErrorCode.invalidAssignment, 151, 21),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    DartType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as ListLiteral;
      return exp.typeOrThrow;
    }

    _isListOf(_isNum)(literal(0) as InterfaceType);
    _isListOf(_isNum)(literal(1) as InterfaceType);
    _isListOf(_isString)(literal(2) as InterfaceType);
    _isListOf(_isDynamic)(literal(3) as InterfaceType);
  }

  test_listLiteral_simple_subtype() async {
    String code = r'''
      void main () {
        Iterable<int> l0 = [];
        Iterable<int> l1 = [3];
        Iterable<int> l2 = ["hello"];
        Iterable<int> l3 = ["hello", 3];
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 43, 2),
      error(WarningCode.unusedLocalVariable, 74, 2),
      error(WarningCode.unusedLocalVariable, 106, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 112, 7),
      error(WarningCode.unusedLocalVariable, 144, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 150, 7),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    InterfaceType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as ListLiteral;
      return exp.staticType as InterfaceType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_mapLiteral_nested() async {
    String code = r'''
      void main () {
        Map<int, List<String>> l0 = {};
        Map<int, List<String>> l1 = {3: ["hello"]};
        Map<int, List<String>> l2 = {"hello": ["hello"]};
        Map<int, List<String>> l3 = {3: [3]};
        Map<int, List<String>> l4 = {3:["hello"], "hello": [3]};
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 52, 2),
      error(WarningCode.unusedLocalVariable, 92, 2),
      error(WarningCode.unusedLocalVariable, 144, 2),
      error(CompileTimeErrorCode.mapKeyTypeNotAssignable, 150, 7),
      error(WarningCode.unusedLocalVariable, 202, 2),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 212, 1),
      error(WarningCode.unusedLocalVariable, 248, 2),
      error(CompileTimeErrorCode.mapKeyTypeNotAssignable, 267, 7),
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 277, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    SetOrMapLiteral literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as SetOrMapLiteral;
      return exp;
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    Asserter<InterfaceType> assertMapOfIntToListOfString = _isMapOf(
      _isInt,
      (DartType type) => assertListOfString(type as InterfaceType),
    );

    assertMapOfIntToListOfString(literal(0).staticType as InterfaceType);
    assertMapOfIntToListOfString(literal(1).staticType as InterfaceType);
    assertMapOfIntToListOfString(literal(2).staticType as InterfaceType);
    assertMapOfIntToListOfString(literal(3).staticType as InterfaceType);
    assertMapOfIntToListOfString(literal(4).staticType as InterfaceType);

    assertListOfString(
      (literal(1).elements[0] as MapLiteralEntry).value.staticType
          as InterfaceType,
    );
    assertListOfString(
      (literal(2).elements[0] as MapLiteralEntry).value.staticType
          as InterfaceType,
    );
    assertListOfString(
      (literal(3).elements[0] as MapLiteralEntry).value.staticType
          as InterfaceType,
    );
    assertListOfString(
      (literal(4).elements[0] as MapLiteralEntry).value.staticType
          as InterfaceType,
    );
  }

  test_mapLiteral_simple() async {
    String code = r'''
      void main () {
        Map<int, String> l0 = {};
        Map<int, String> l1 = {3: "hello"};
        Map<int, String> l2 = {"hello": "hello"};
        Map<int, String> l3 = {3: 3};
        Map<int, String> l4 = {3:"hello", "hello": 3};
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 46, 2),
      error(WarningCode.unusedLocalVariable, 80, 2),
      error(WarningCode.unusedLocalVariable, 124, 2),
      error(CompileTimeErrorCode.mapKeyTypeNotAssignable, 130, 7),
      error(WarningCode.unusedLocalVariable, 174, 2),
      error(CompileTimeErrorCode.mapValueTypeNotAssignable, 183, 1),
      error(WarningCode.unusedLocalVariable, 212, 2),
      error(CompileTimeErrorCode.mapKeyTypeNotAssignable, 229, 7),
      error(CompileTimeErrorCode.mapValueTypeNotAssignable, 238, 1),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    InterfaceType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as SetOrMapLiteral;
      return exp.staticType as InterfaceType;
    }

    Asserter<InterfaceType> assertMapOfIntToString = _isMapOf(
      _isInt,
      _isString,
    );

    assertMapOfIntToString(literal(0));
    assertMapOfIntToString(literal(1));
    assertMapOfIntToString(literal(2));
    assertMapOfIntToString(literal(3));
  }

  test_mapLiteral_simple_disabled() async {
    String code = r'''
      void main () {
        Map<int, String> l0 = <int, dynamic>{};
        Map<int, String> l1 = <int, dynamic>{3: "hello"};
        Map<int, String> l2 = <int, dynamic>{"hello": "hello"};
        Map<int, String> l3 = <int, dynamic>{3: 3};
     }
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unusedLocalVariable, 46, 2),
      error(CompileTimeErrorCode.invalidAssignment, 51, 16),
      error(WarningCode.unusedLocalVariable, 94, 2),
      error(CompileTimeErrorCode.invalidAssignment, 99, 26),
      error(WarningCode.unusedLocalVariable, 152, 2),
      error(CompileTimeErrorCode.invalidAssignment, 157, 32),
      error(CompileTimeErrorCode.mapKeyTypeNotAssignable, 172, 7),
      error(WarningCode.unusedLocalVariable, 216, 2),
      error(CompileTimeErrorCode.invalidAssignment, 221, 20),
    ]);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      unit,
      "main",
    );
    InterfaceType literal(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as SetOrMapLiteral;
      return exp.staticType as InterfaceType;
    }

    Asserter<InterfaceType> assertMapOfIntToDynamic = _isMapOf(
      _isInt,
      _isDynamic,
    );

    assertMapOfIntToDynamic(literal(0));
    assertMapOfIntToDynamic(literal(1));
    assertMapOfIntToDynamic(literal(2));
    assertMapOfIntToDynamic(literal(3));
  }

  test_methodDeclaration_body_propagation() async {
    String code = r'''
      class A {
        List<String> m0(int x) => ["hello"];
        List<String> m1(int x) {return [3];}
      }
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.listElementTypeNotAssignable, 101, 1),
    ]);

    Expression methodReturnValue(String methodName) {
      MethodDeclaration method = AstFinder.getMethodInClass(
        unit,
        "A",
        methodName,
      );
      FunctionBody body = method.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression!;
      }
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(methodReturnValue("m0").staticType as InterfaceType);
    assertListOfString(methodReturnValue("m1").staticType as InterfaceType);
  }

  test_partialTypes1() async {
    // Test that downwards inference with a partial type
    // correctly uses the partial information to fill in subterm
    // types
    String code = r'''
    typedef To Func1<From, To>(From x);
    S f<S, T>(Func1<S, T> g) => null;
    String test() => f((l) => l.length);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 72, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    _isString(body.expression.typeOrThrow);
    var invoke = body.expression as MethodInvocation;
    var function = invoke.argumentList.arguments[0] as FunctionExpression;
    ExecutableElement f0 = function.declaredFragment!.element;
    FunctionType type = f0.type;
    _isFunction2Of(_isString, _isInt)(type);
  }

  test_pinning_multipleConstraints1() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, String> test() => new B(3);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 126, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(unit, "B").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isNever])(type);
  }

  test_pinning_multipleConstraints2() async {
    // Test that downwards inference with two identical downwards covariant
    // constraints on the same parameter correctly infers and pins the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<num, num> test() => new B(3);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(unit, "B").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isNum])(type);
  }

  test_pinning_multipleConstraints3() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype, but do share a common supertype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, double> test() => new B(3);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
      error(CompileTimeErrorCode.argumentTypeNotAssignable, 126, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(unit, "B").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isNever])(type);
  }

  test_pinning_multipleConstraints4() async {
    // Test that downwards inference with two subtype related downwards
    // covariant constraints on the same parameter correctly infers and pins
    // the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    A<int, num> test() => new B();
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(unit, "B").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isInt])(type);
  }

  test_pinning_multipleConstraints_contravariant1() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter chooses the upper bound
    // when the only supertype is Object
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, String>> test() => mkA();
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isObject, _isObject])(type);
  }

  test_pinning_multipleConstraints_contravariant2() async {
    // Test that downwards inference with two identical downwards contravariant
    // constraints on the same parameter correctly pins the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<num, num>> test() => mkA();
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant3() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when they share a common supertype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, double>> test() => mkA();
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant4() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when one is a subtype of the other
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, num>> test() => mkA();
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 28, 1),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 39, 1),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_redirectedConstructor_named() async {
    var code = r'''
class A<T, U> implements B<T, U> {
  A.named();
}

class B<T2, U2> {
  factory B() = A.named;
}
   ''';
    await assertNoErrorsInCode(code);

    var b = unit.declarations[1] as ClassDeclaration;
    var bConstructor = b.members[0] as ConstructorDeclaration;
    var redirected = bConstructor.redirectedConstructor as ConstructorName;

    var typeName = redirected.type;
    assertType(typeName.type, 'A<T2, U2>');
    assertType(typeName.type, 'A<T2, U2>');

    var constructorMember = redirected.element!;
    expect(constructorMember.displayString(), 'A<T2, U2>.named()');
    expect(redirected.name!.element, constructorMember);
  }

  test_redirectedConstructor_self() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A();
  factory A.redirected() = A;
}
''');
  }

  test_redirectedConstructor_unnamed() async {
    await assertNoErrorsInCode(r'''
class A<T, U> implements B<T, U> {
  A();
}

class B<T2, U2> {
  factory B() = A;
}
''');

    var b = result.unit.declarations[1] as ClassDeclaration;
    var bConstructor = b.members[0] as ConstructorDeclaration;
    var redirected = bConstructor.redirectedConstructor as ConstructorName;

    var typeName = redirected.type;
    assertType(typeName.type, 'A<T2, U2>');
    assertType(typeName.type, 'A<T2, U2>');

    expect(redirected.name, isNull);
    expect(redirected.element!.displayString(), 'A<T2, U2>()');
  }

  test_redirectingConstructor_propagation() async {
    String code = r'''
      class A {
        A() : this.named([]);
        A.named(List<String> x);
      }
   ''';
    await assertNoErrorsInCode(code);

    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      unit,
      "A",
      null,
    );
    var invocation =
        constructor.initializers[0] as RedirectingConstructorInvocation;
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType as InterfaceType);
  }

  test_returnType_variance1() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a contravariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
    Func1<num, String> test() => f(42);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 74, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var invoke = body.expression as MethodInvocation;
    _isFunction2Of(_isNum, _isFunction2Of(_isNum, _isString))(
      invoke.staticInvokeType!,
    );
  }

  test_returnType_variance2() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a covariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
    Func1<String, num> test() => f(42);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 74, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var invoke = body.expression as MethodInvocation;
    _isFunction2Of(_isNum, _isFunction2Of(_isString, _isNum))(
      invoke.staticInvokeType!,
    );
  }

  test_returnType_variance3() async {
    // Check that the variance heuristic chooses the most precise type
    // when the return type uses the variable in a contravariant position
    // and there is no downwards constraint.
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x, g(T x)) => null;
    dynamic test() => f(42, (num x) => x);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 82, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];
    _isInt(type);
  }

  test_returnType_variance4() async {
    // Check that the variance heuristic chooses the more precise type
    // when the return type uses the variable in a covariant position
    // and there is no downwards constraint
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x, g(T x)) => null;
    dynamic test() => f(42, (num x) => x);
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 82, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.returnType;
    _isInt(type);
  }

  test_returnType_variance5() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a contravariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
    T g<T, S>(Func1<T, S> f) => null;
    num test() => g(f(3));
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 74, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 112, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var call = body.expression as MethodInvocation;
    _isNum(call.typeOrThrow);
    _isFunction2Of(_isFunction2Of(_isNum, _isString), _isNum)(
      call.staticInvokeType!,
    );
  }

  test_returnType_variance6() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a covariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
    T g<T, S>(Func1<S, T> f) => null;
    num test() => g(f(3));
   ''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 74, 4),
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 112, 4),
    ]);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var call = body.expression as MethodInvocation;
    _isNum(call.typeOrThrow);
    _isFunction2Of(_isFunction2Of(_isString, _isNum), _isNum)(
      call.staticInvokeType!,
    );
  }

  test_superConstructorInvocation_propagation() async {
    String code = r'''
      class B {
        B(List<String> p);
      }
      class A extends B {
        A() : super([]);
      }
   ''';
    await assertNoErrorsInCode(code);

    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      unit,
      "A",
      null,
    );
    var invocation = constructor.initializers[0] as SuperConstructorInvocation;
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType as InterfaceType);
  }

  /// Verifies the result has [CompileTimeErrorCode.couldNotInfer] with
  /// the expected [errorMessage].
  void _expectInferenceError(String errorMessage) {
    var errors = result.diagnostics
        .where((e) => e.diagnosticCode == CompileTimeErrorCode.couldNotInfer)
        .map((e) => e.message)
        .toList();
    expect(errors.length, 1);
    var actual = errors[0];
    expect(
      actual,
      errorMessage, // Print the literal error message for easy copy+paste:
      reason: 'Actual error did not match expected error:\n$actual',
    );
  }

  /// Helper method for testing `FutureOr<T>`.
  ///
  /// Validates that [code] produces [expectedErrors]. It should define a
  /// function "test", whose body is an expression that invokes a method.
  /// Returns that invocation.
  Future<MethodInvocation> _testFutureOr(
    String code, {
    List<ExpectedError> expectedErrors = const [],
  }) async {
    var fullCode =
        """
import "dart:async";

$code
""";
    await assertErrorsInCode(fullCode, expectedErrors);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    var body = test.functionExpression.body as ExpressionFunctionBody;
    return body.expression as MethodInvocation;
  }
}

@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test extends StaticTypeAnalyzer2TestShared {
  test_dynamicObjectGetter_hashCode() async {
    await assertErrorsInCode(
      r'''
main() {
  dynamic a = null;
  var foo = a.hashCode;
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 3)],
    );
    expectInitializerType('foo', 'int');
  }

  test_futureOr_promotion1() async {
    // Test that promotion from FutureOr<T> to T works for concrete types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is int) && (x.abs() == 0);
   ''';
    await assertNoErrorsInCode(code);
  }

  test_futureOr_promotion2() async {
    // Test that promotion from FutureOr<T> to Future<T> works for concrete
    // types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is Future<int>) &&
                                     (x.then((x) => x) == null);
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unnecessaryNullComparisonNeverNullFalse, 139, 7),
    ]);
  }

  test_futureOr_promotion3() async {
    // Test that promotion from FutureOr<T> to T works for type
    // parameters T
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is T) &&
                                                  (x.abs() == 0);
   ''';
    await assertNoErrorsInCode(code);
  }

  test_futureOr_promotion4() async {
    // Test that promotion from FutureOr<T> to Future<T> works for type
    // parameters T
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is Future<T>) &&
                                                  (x.then((x) => x) == null);
   ''';
    await assertErrorsInCode(code, [
      error(WarningCode.unnecessaryNullComparisonNeverNullFalse, 163, 7),
    ]);
  }

  test_generalizedVoid_assignToVoidOk() async {
    await assertErrorsInCode(
      r'''
void main() {
  void x;
  x = 42;
}
''',
      [error(WarningCode.unusedLocalVariable, 21, 1)],
    );
  }

  test_genericFunction() async {
    await assertErrorsInCode(r'T f<T>(T x) => null;', [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 15, 4),
    ]);

    var node = findNode.functionDeclaration('f<T>');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: T
    element2: #E0 T
    type: T
  name: f
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredElement: <testLibraryFragment> T@4
            defaultType: dynamic
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: T
          element2: #E0 T
          type: T
        name: x
        declaredElement: <testLibraryFragment> x@9
          element: isPublic
            type: T
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: NullLiteral
        literal: null
        staticType: Null
      semicolon: ;
    declaredElement: <testLibraryFragment> f@2
      element: <testLibrary>::@function::f
        type: T Function<T>(T)
    staticType: T Function<T>(T)
  declaredElement: <testLibraryFragment> f@2
    element: <testLibrary>::@function::f
      type: T Function<T>(T)
''');
  }

  test_genericFunction_bounds() async {
    await assertErrorsInCode(r'T f<T extends num>(T x) => null;', [
      error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 27, 4),
    ]);

    var node = findNode.functionDeclaration('f<T');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: T
    element2: #E0 T
    type: T
  name: f
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: num
            element2: dart:core::@class::num
            type: num
          declaredElement: <testLibraryFragment> T@4
            defaultType: num
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: T
          element2: #E0 T
          type: T
        name: x
        declaredElement: <testLibraryFragment> x@21
          element: isPublic
            type: T
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: NullLiteral
        literal: null
        staticType: Null
      semicolon: ;
    declaredElement: <testLibraryFragment> f@2
      element: <testLibrary>::@function::f
        type: T Function<T extends num>(T)
    staticType: T Function<T extends num>(T)
  declaredElement: <testLibraryFragment> f@2
    element: <testLibrary>::@function::f
      type: T Function<T extends num>(T)
''');
  }

  test_genericFunction_parameter() async {
    await assertNoErrorsInCode(r'''
void g(T f<T>(T x)) {}
''');

    var fType = findElement2.parameter('f').type;
    fType as FunctionType;
    assertType(fType, 'T Function<T>(T)');
  }

  test_genericFunction_static() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  static T f<T>(T x) => null;
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 37, 4)],
    );

    var node = findNode.methodDeclaration('f<T>');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: T
    element2: #E0 T
    type: T
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: <testLibraryFragment> T@26
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element2: #E0 T
        type: T
      name: x
      declaredElement: <testLibraryFragment> x@31
        element: isPublic
          type: T
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
      staticType: Null
    semicolon: ;
  declaredElement: <testLibraryFragment> f@24
    element: <testLibrary>::@class::C::@method::f
      type: T Function<T>(T)
''');
  }

  test_genericFunction_typedef() async {
    String code = r'''
typedef T F<T>(T x);
F f0;

class C {
  static F f1;
  F f2;
  void g(F f3) { // C
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}

class D<S> {
  static F f1;
  F f2;
  void g(F f3) { // D
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}
''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.notInitializedNonNullableVariable, 23, 2),
      error(CompileTimeErrorCode.notInitializedNonNullableVariable, 49, 2),
      error(CompileTimeErrorCode.notInitializedNonNullableInstanceField, 57, 2),
      error(
        CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
        141,
        2,
      ),
      error(CompileTimeErrorCode.notInitializedNonNullableVariable, 179, 2),
      error(
        CompileTimeErrorCode.notInitializedNonNullableInstanceField,
        187,
        2,
      ),
      error(
        CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
        271,
        2,
      ),
    ]);

    checkBody(String className) {
      var statements = findNode.block('{ // $className').statements;

      for (int i = 1; i <= 5; i++) {
        Expression exp = (statements[i] as ExpressionStatement).expression;
        expect(exp.staticType, typeProvider.dynamicType);
      }
    }

    checkBody("C");
    checkBody("D");
  }

  test_genericFunction_upwardsAndDownwards() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27586.
    await assertNoErrorsInCode(r'List<num> x = [1, 2];');
    expectInitializerType('x', 'List<num>');
  }

  test_genericFunction_upwardsAndDownwards_Object() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27625.
    await assertErrorsInCode(
      r'''
List<Object> aaa = [];
List<Object> bbb = [1, 2, 3];
List<Object> ccc = [null];
List<Object> ddd = [1 as dynamic];
List<Object> eee = [new Object()];
''',
      [
        error(
          CompileTimeErrorCode.listElementTypeNotAssignableNullability,
          73,
          4,
        ),
      ],
    );
    expectInitializerType('aaa', 'List<Object>');
    expectInitializerType('bbb', 'List<Object>');
    expectInitializerType('ccc', 'List<Object>');
    expectInitializerType('ddd', 'List<Object>');
    expectInitializerType('eee', 'List<Object>');
  }

  test_genericMethod() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  List<T> f<T>(E e) => null;
}
main() {
  C<String> cOfString;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 36, 4),
        error(WarningCode.unusedLocalVariable, 65, 9),
      ],
    );
    assertType(findElement2.method('f').type, 'List<T> Function<T>(E)');

    var cOfString = findElement2.localVar('cOfString');
    var ft = inheritanceManager
        .getMember3(cOfString.type as InterfaceType, Name(null, 'f'))!
        .type;
    assertType(ft, 'List<T> Function<T>(String)');
    assertType(
      ft.instantiate([typeProvider.intType]),
      'List<int> Function(String)',
    );
  }

  test_genericMethod_explicitTypeParams() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  List<T> f<T>(E e) => null;
}
main() {
  C<String> cOfString;
  var x = cOfString.f<int>('hi');
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 36, 4),
        error(WarningCode.unusedLocalVariable, 82, 1),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          86,
          9,
        ),
      ],
    );
    var f = findNode.simple('f<int>').parent as MethodInvocation;
    var ft = f.staticInvokeType as FunctionType;
    assertType(ft, 'List<int> Function(String)');

    var x = findElement2.localVar('x');
    expect(x.type, typeProvider.listType(typeProvider.intType));
  }

  test_genericMethod_functionExpressionInvocation_explicit() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;

  var lambdaCall = (<E>(E e) => e)<int>(3);
  var methodCall = (c.f)<int>(3);
  var staticCall = (C.g)<int>(3);
  var staticFieldCall = (C.h)<int>(3);
  var topFunCall = (topF)<int>(3);
  var topFieldCall = (topG)<int>(3);
  var localCall = (lf)<int>(3);
  var paramCall = (pf)<int>(3);
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 30, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 60, 4),
        error(CompileTimeErrorCode.invalidAssignment, 96, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 123, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 224, 4),
        error(WarningCode.unusedLocalVariable, 237, 10),
        error(WarningCode.unusedLocalVariable, 281, 10),
        error(WarningCode.unusedLocalVariable, 315, 10),
        error(WarningCode.unusedLocalVariable, 349, 15),
        error(WarningCode.unusedLocalVariable, 388, 10),
        error(WarningCode.unusedLocalVariable, 423, 12),
        error(WarningCode.unusedLocalVariable, 460, 9),
        error(WarningCode.unusedLocalVariable, 492, 9),
      ],
    );
    _assertLocalVarType('lambdaCall', "int");
    _assertLocalVarType('methodCall', "int");
    _assertLocalVarType('staticCall', "int");
    _assertLocalVarType('staticFieldCall', "int");
    _assertLocalVarType('topFunCall', "int");
    _assertLocalVarType('topFieldCall', "int");
    _assertLocalVarType('localCall', "int");
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit() async {
    await assertErrorsInCode(
      r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = (pf)<int>(3);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 9)],
    );
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred() async {
    await assertErrorsInCode(
      r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = (pf)(3);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 9)],
    );
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_inferred() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;

  var lambdaCall = (<E>(E e) => e)(3);
  var methodCall = (c.f)(3);
  var staticCall = (C.g)(3);
  var staticFieldCall = (C.h)(3);
  var topFunCall = (topF)(3);
  var topFieldCall = (topG)(3);
  var localCall = (lf)(3);
  var paramCall = (pf)(3);
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 30, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 60, 4),
        error(CompileTimeErrorCode.invalidAssignment, 96, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 123, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 224, 4),
        error(WarningCode.unusedLocalVariable, 237, 10),
        error(WarningCode.unusedLocalVariable, 276, 10),
        error(WarningCode.unusedLocalVariable, 305, 10),
        error(WarningCode.unusedLocalVariable, 334, 15),
        error(WarningCode.unusedLocalVariable, 368, 10),
        error(WarningCode.unusedLocalVariable, 398, 12),
        error(WarningCode.unusedLocalVariable, 430, 9),
        error(WarningCode.unusedLocalVariable, 457, 9),
      ],
    );
    _assertLocalVarType('lambdaCall', "int");
    _assertLocalVarType('methodCall', "int");
    _assertLocalVarType('staticCall', "int");
    _assertLocalVarType('staticFieldCall', "int");
    _assertLocalVarType('topFunCall', "int");
    _assertLocalVarType('topFieldCall', "int");
    _assertLocalVarType('localCall', "int");
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_explicit() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodCall = c.f<int>(3);
  var staticCall = C.g<int>(3);
  var staticFieldCall = C.h<int>(3);
  var topFunCall = topF<int>(3);
  var topFieldCall = topG<int>(3);
  var localCall = lf<int>(3);
  var paramCall = pf<int>(3);
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 30, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 60, 4),
        error(CompileTimeErrorCode.invalidAssignment, 96, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 123, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 224, 4),
        error(WarningCode.unusedLocalVariable, 236, 10),
        error(WarningCode.unusedLocalVariable, 268, 10),
        error(WarningCode.unusedLocalVariable, 300, 15),
        error(WarningCode.unusedLocalVariable, 337, 10),
        error(WarningCode.unusedLocalVariable, 370, 12),
        error(WarningCode.unusedLocalVariable, 405, 9),
        error(WarningCode.unusedLocalVariable, 435, 9),
      ],
    );
    _assertLocalVarType('methodCall', "int");
    _assertLocalVarType('staticCall', "int");
    _assertLocalVarType('staticFieldCall', "int");
    _assertLocalVarType('topFunCall', "int");
    _assertLocalVarType('topFieldCall', "int");
    _assertLocalVarType('localCall', "int");
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_functionTypedParameter_explicit() async {
    await assertErrorsInCode(
      r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = pf<int>(3);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 9)],
    );
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_functionTypedParameter_inferred() async {
    await assertErrorsInCode(
      r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = pf(3);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 9)],
    );
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_inferred() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodCall = c.f(3);
  var staticCall = C.g(3);
  var staticFieldCall = C.h(3);
  var topFunCall = topF(3);
  var topFieldCall = topG(3);
  var localCall = lf(3);
  var paramCall = pf(3);
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 30, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 60, 4),
        error(CompileTimeErrorCode.invalidAssignment, 96, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 123, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 224, 4),
        error(WarningCode.unusedLocalVariable, 236, 10),
        error(WarningCode.unusedLocalVariable, 263, 10),
        error(WarningCode.unusedLocalVariable, 290, 15),
        error(WarningCode.unusedLocalVariable, 322, 10),
        error(WarningCode.unusedLocalVariable, 350, 12),
        error(WarningCode.unusedLocalVariable, 380, 9),
        error(WarningCode.unusedLocalVariable, 405, 9),
      ],
    );
    _assertLocalVarType('methodCall', "int");
    _assertLocalVarType('staticCall', "int");
    _assertLocalVarType('staticFieldCall', "int");
    _assertLocalVarType('topFunCall', "int");
    _assertLocalVarType('topFieldCall', "int");
    _assertLocalVarType('localCall', "int");
    _assertLocalVarType('paramCall', "int");
  }

  test_genericMethod_functionTypedParameter() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  List<T> f<T>(T f(E e)) => null;
}
main() {
  C<String> cOfString;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 41, 4),
        error(WarningCode.unusedLocalVariable, 70, 9),
      ],
    );
    assertType(
      findElement2.method('f').type,
      'List<T> Function<T>(T Function(E))',
    );

    var cOfString = findElement2.localVar('cOfString');
    var ft = inheritanceManager
        .getMember3(cOfString.type as InterfaceType, Name(null, 'f'))!
        .type;
    assertType(ft, 'List<T> Function<T>(T Function(String))');
    assertType(
      ft.instantiate([typeProvider.intType]),
      'List<int> Function(int Function(String))',
    );
  }

  test_genericMethod_functionTypedParameter_tearoff() async {
    await assertErrorsInCode(
      r'''
void test<S>(T pf<T>(T e)) {
  var paramTearOff = pf;
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 12)],
    );
    _assertLocalVarType('paramTearOff', "T Function<T>(T)");
  }

  test_genericMethod_implicitDynamic() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25100#issuecomment-162047588
    // These should not cause any hints or warnings.
    await assertErrorsInCode(
      r'''
class List<E> {
  T map<T>(T f(E e)) => null;
}
void foo() {
  List list = null;
  list.map((e) => e);
  list.map((e) => 3);
}''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 40, 4),
        error(CompileTimeErrorCode.invalidAssignment, 75, 4),
      ],
    );

    var node1 = findNode.methodInvocation('map((e) => e);');
    assertResolvedNodeText(node1, r'''
MethodInvocation
  target: SimpleIdentifier
    token: list
    element: list@68
    staticType: List<dynamic>
  operator: .
  methodName: SimpleIdentifier
    token: map
    element: MethodMember
      baseElement: <testLibrary>::@class::List::@method::map
      substitution: {E: dynamic, T: T}
    staticType: T Function<T>(T Function(dynamic))
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: e
            declaredElement: <testLibraryFragment> e@93
              element: hasImplicitType isPublic
                type: dynamic
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SimpleIdentifier
            token: e
            element: e@93
            staticType: dynamic
        declaredElement: <testLibraryFragment> null@null
          element: null@null
            type: dynamic Function(dynamic)
        correspondingParameter: ParameterMember
          baseElement: f@null
          substitution: {T: dynamic}
        staticType: dynamic Function(dynamic)
    rightParenthesis: )
  staticInvokeType: dynamic Function(dynamic Function(dynamic))
  staticType: dynamic
  typeArgumentTypes
    dynamic
''');

    var node2 = findNode.methodInvocation('map((e) => 3);');
    assertResolvedNodeText(node2, r'''
MethodInvocation
  target: SimpleIdentifier
    token: list
    element: list@68
    staticType: List<dynamic>
  operator: .
  methodName: SimpleIdentifier
    token: map
    element: MethodMember
      baseElement: <testLibrary>::@class::List::@method::map
      substitution: {E: dynamic, T: T}
    staticType: T Function<T>(T Function(dynamic))
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: e
            declaredElement: <testLibraryFragment> e@115
              element: hasImplicitType isPublic
                type: dynamic
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 3
            staticType: int
        declaredElement: <testLibraryFragment> null@null
          element: null@null
            type: int Function(dynamic)
        correspondingParameter: ParameterMember
          baseElement: f@null
          substitution: {T: int}
        staticType: int Function(dynamic)
    rightParenthesis: )
  staticInvokeType: int Function(int Function(dynamic))
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_genericMethod_max_doubleDouble() async {
    await assertErrorsInCode(
      r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2.0);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 3)],
    );
    expectInitializerType('foo', 'double');
  }

  test_genericMethod_max_doubleDouble_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as math;
main() {
  var foo = math.max(1.0, 2.0);
}
''',
      [error(WarningCode.unusedLocalVariable, 43, 3)],
    );
    expectInitializerType('foo', 'double');
  }

  test_genericMethod_max_doubleInt() async {
    await assertErrorsInCode(
      r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 3)],
    );
    expectInitializerType('foo', 'num');
  }

  test_genericMethod_max_intDouble() async {
    await assertErrorsInCode(
      r'''
import 'dart:math';
main() {
  var foo = max(1, 2.0);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 3)],
    );
    expectInitializerType('foo', 'num');
  }

  test_genericMethod_max_intInt() async {
    await assertErrorsInCode(
      r'''
import 'dart:math';
main() {
  var foo = max(1, 2);
}
''',
      [error(WarningCode.unusedLocalVariable, 35, 3)],
    );
    expectInitializerType('foo', 'int');
  }

  test_genericMethod_nestedBound() async {
    // Just validate that there is no warning on the call to `.abs()`.
    await assertNoErrorsInCode(r'''
class Foo<T extends num> {
  void method<U extends T>(U u) {
    u.abs();
  }
}
''');
  }

  test_genericMethod_nestedCapture() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  T f<S>(S x) {
    new C<S>().f<int>(3);
    new C<S>().f; // tear-off
    return null;
  }
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 96, 4)],
    );

    var node1 = findNode.methodInvocation('f<int>(3);');
    assertResolvedNodeText(node1, r'''
MethodInvocation
  target: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: C
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: S
              element2: #E0 S
              type: S
          rightBracket: >
        element2: <testLibrary>::@class::C
        type: C<S>
      element: ConstructorMember
        baseElement: <testLibrary>::@class::C::@constructor::new
        substitution: {T: S}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C<S>
  operator: .
  methodName: SimpleIdentifier
    token: f
    element: MethodMember
      baseElement: <testLibrary>::@class::C::@method::f
      substitution: {T: S, S: S}
    staticType: S Function<S₀>(S₀)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        correspondingParameter: ParameterMember
          baseElement: x@null
          substitution: {S: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: S Function(int)
  staticType: S
  typeArgumentTypes
    int
''');
  }

  test_genericMethod_nestedCaptureBounds() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  T f<S extends T>(S x) {
    new C<S>().f<int>(3);
    new C<S>().f; // tear-off
    return null;
  }
}
''',
      [
        error(CompileTimeErrorCode.typeArgumentNotMatchingBounds, 56, 3),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 106, 4),
      ],
    );

    var node1 = findNode.methodInvocation('f<int>(3);');
    assertResolvedNodeText(node1, r'''
MethodInvocation
  target: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: C
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: S
              element2: #E0 S
              type: S
          rightBracket: >
        element2: <testLibrary>::@class::C
        type: C<S>
      element: ConstructorMember
        baseElement: <testLibrary>::@class::C::@constructor::new
        substitution: {T: S}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C<S>
  operator: .
  methodName: SimpleIdentifier
    token: f
    element: MethodMember
      baseElement: <testLibrary>::@class::C::@method::f
      substitution: {T: S, S: S}
    staticType: S Function<S₀ extends S>(S₀)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        correspondingParameter: ParameterMember
          baseElement: x@null
          substitution: {S: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: S Function(int)
  staticType: S
  typeArgumentTypes
    int
''');

    var node2 = findNode.simple('f;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: f
  element: MethodMember
    baseElement: <testLibrary>::@class::C::@method::f
    substitution: {T: S, S: S}
  staticType: S Function<S₀ extends S>(S₀)
''');
  }

  test_genericMethod_nestedFunctions() async {
    await assertErrorsInCode(
      r'''
S f<S>(S x) {
  g<S>(S x) => f;
  return null;
}
''',
      [
        error(WarningCode.unusedElement, 16, 1),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 41, 4),
      ],
    );
    assertType(findElement2.topFunction('f').type, 'S Function<S>(S)');
    assertType(
      findElement2.localFunction('g').type,
      'S Function<S>(S) Function<S₀>(S₀)',
    );
  }

  test_genericMethod_override() async {
    await assertErrorsInCode(
      r'''
class C {
  T f<T>(T x) => null;
}
class D extends C {
  T f<T>(T y) => null;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 27, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 72, 4),
      ],
    );

    var node = findNode.methodDeclaration('f<T>(T y)');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: T
    element2: #E0 T
    type: T
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: <testLibraryFragment> T@61
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element2: #E0 T
        type: T
      name: y
      declaredElement: <testLibraryFragment> y@66
        element: isPublic
          type: T
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
      staticType: Null
    semicolon: ;
  declaredElement: <testLibraryFragment> f@59
    element: <testLibrary>::@class::D::@method::f
      type: T Function<T>(T)
''');
  }

  test_genericMethod_override_bounds() async {
    await assertErrorsInCode(
      r'''
class A {}
class B {
  T f<T extends A>(T x) => null;
}
// override with the same bound is OK
class C extends B {
  T f<T extends A>(T x) => null;
}
// override with new name and the same bound is OK
class D extends B {
  Q f<Q extends A>(Q x) => null;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 48, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 141, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 247, 4),
      ],
    );
  }

  test_genericMethod_override_covariant_field() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  num get x;
  set x(covariant num _);
}

class B extends A {
  int x;
}
''',
      [
        error(
          CompileTimeErrorCode.notInitializedNonNullableInstanceField,
          87,
          1,
        ),
      ],
    );
  }

  test_genericMethod_override_differentContextsSameBounds() async {
    await assertNoErrorsInCode(r'''
        class GenericMethodBounds<T> {
  Type get t => T;
  GenericMethodBounds<E> foo<E extends T>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(T)>() =>
      new GenericMethodBounds<E>();
}

class GenericMethodBoundsDerived extends GenericMethodBounds<num> {
  GenericMethodBounds<E> foo<E extends num>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(num)>() =>
      new GenericMethodBounds<E>();
}
''');
  }

  test_genericMethod_override_invalidContravariantTypeParamBounds() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {}
class C {
  T f<T extends A>(T x) => null;
}
class D extends C {
  T f<T extends B>(T x) => null;
}''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 69, 4),
        error(
          CompileTimeErrorCode.invalidOverride,
          101,
          1,
          contextMessages: [message(testFile, 46, 1)],
        ),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 124, 4),
      ],
    );
  }

  test_genericMethod_override_invalidCovariantTypeParamBounds() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {}
class C {
  T f<T extends B>(T x) => null;
}
class D extends C {
  T f<T extends A>(T x) => null;
}''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 69, 4),
        error(
          CompileTimeErrorCode.invalidOverride,
          101,
          1,
          contextMessages: [message(testFile, 46, 1)],
        ),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 124, 4),
      ],
    );
  }

  test_genericMethod_override_invalidReturnType() async {
    await assertErrorsInCode(
      r'''
class C {
  Iterable<T> f<T>(T x) => null;
}
class D extends C {
  String f<S>(S x) => null;
}''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 37, 4),
        error(
          CompileTimeErrorCode.invalidOverride,
          74,
          1,
          contextMessages: [message(testFile, 24, 1)],
        ),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 87, 4),
      ],
    );
  }

  test_genericMethod_override_invalidTypeParamCount() async {
    await assertErrorsInCode(
      r'''
class C {
  T f<T>(T x) => null;
}
class D extends C {
  S f<T, S>(T x) => null;
}''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 27, 4),
        error(
          CompileTimeErrorCode.invalidOverride,
          59,
          1,
          contextMessages: [message(testFile, 14, 1)],
        ),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 75, 4),
      ],
    );
  }

  test_genericMethod_propagatedType_promotion() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340

    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // example won't work, as we now compute a static type and therefore discard
    // the propagated type. So a new test was created that doesn't run under
    // strong mode.
    await assertErrorsInCode(
      r'''
abstract class Iter {
  List<S> map<S>(S f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
  }
  return null;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 122, 1),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 160, 4),
      ],
    );
    _assertLocalVarType('y', 'List<C>');
  }

  test_genericMethod_tearoff() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  T f<T>(E e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodTearOff = c.f;
  var staticTearOff = C.g;
  var staticFieldTearOff = C.h;
  var topFunTearOff = topF;
  var topFieldTearOff = topG;
  var localTearOff = lf;
  var paramTearOff = pf;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 30, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 60, 4),
        error(CompileTimeErrorCode.invalidAssignment, 96, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 123, 4),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 224, 4),
        error(WarningCode.unusedLocalVariable, 236, 13),
        error(WarningCode.unusedLocalVariable, 263, 13),
        error(WarningCode.unusedLocalVariable, 290, 18),
        error(WarningCode.unusedLocalVariable, 322, 13),
        error(WarningCode.unusedLocalVariable, 350, 15),
        error(WarningCode.unusedLocalVariable, 380, 12),
        error(WarningCode.unusedLocalVariable, 405, 12),
      ],
    );
    _assertLocalVarType('methodTearOff', "T Function<T>(int)");
    _assertLocalVarType('staticTearOff', "T Function<T>(T)");
    _assertLocalVarType('staticFieldTearOff', "T Function<T>(T)");
    _assertLocalVarType('topFunTearOff', "T Function<T>(T)");
    _assertLocalVarType('topFieldTearOff', "T Function<T>(T)");
    _assertLocalVarType('localTearOff', "T Function<T>(T)");
    _assertLocalVarType('paramTearOff', "T Function<T>(T)");
  }

  @failingTest
  test_genericMethod_tearoff_instantiated() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(E e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T pf<T>(T e)) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodTearOffInst = c.f<int>;
  var staticTearOffInst = C.g<int>;
  var staticFieldTearOffInst = C.h<int>;
  var topFunTearOffInst = topF<int>;
  var topFieldTearOffInst = topG<int>;
  var localTearOffInst = lf<int>;
  var paramTearOffInst = pf<int>;
}
''');
    expectIdentifierType('methodTearOffInst', "int Function(int)");
    expectIdentifierType('staticTearOffInst', "int Function(int)");
    expectIdentifierType('staticFieldTearOffInst', "int Function(int)");
    expectIdentifierType('topFunTearOffInst', "int Function(int)");
    expectIdentifierType('topFieldTearOffInst', "int Function(int)");
    expectIdentifierType('localTearOffInst', "int Function(int)");
    expectIdentifierType('paramTearOffInst', "int Function(int)");
  }

  test_genericMethod_then() async {
    await assertErrorsInCode(
      r'''
String toString(int x) => x.toString();
main() {
  Future<int> bar = null;
  var foo = bar.then(toString);
}
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 69, 4),
        error(WarningCode.unusedLocalVariable, 81, 3),
      ],
    );

    expectInitializerType('foo', 'Future<String>');
  }

  test_genericMethod_then_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'dart:async' as async;
String toString(int x) => x.toString();
main() {
  async.Future<int> bar = null;
  var foo = bar.then(toString);
}
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 105, 4),
        error(WarningCode.unusedLocalVariable, 117, 3),
      ],
    );
    expectInitializerType('foo', 'Future<String>');
  }

  test_genericMethod_then_propagatedType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25482.
    await assertErrorsInCode(
      r'''
void main() {
  Future<String> p;
  var foo = p.then((r) => new Future<String>.value(3));
}
''',
      [
        error(WarningCode.unusedLocalVariable, 40, 3),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          46,
          1,
        ),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 85, 1),
      ],
    );
    // Note: this correctly reports the error
    // CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE when run with the driver;
    // when run without the driver, it reports no errors.  So we don't bother
    // checking whether the correct errors were reported.
    expectInitializerType('foo', 'Future<String>');
  }

  test_genericMethod_toplevel_field_staticTearoff() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

void test() {
  var fieldRead = C.h;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 37, 4),
        error(CompileTimeErrorCode.invalidAssignment, 73, 4),
        error(WarningCode.unusedLocalVariable, 102, 9),
      ],
    );
    _assertLocalVarType('fieldRead', "T Function<T>(T)");
  }

  test_implicitBounds() async {
    await assertErrorsInCode(
      r'''
class A<T> {}

class B<T extends num> {}

class C<S extends int, T extends B<S>, U extends A> {}

void test() {
  A ai;
  B bi;
  C ci;
  var aa = new A();
  var bb = new B();
  var cc = new C();
}
''',
      [
        error(WarningCode.unusedLocalVariable, 116, 2),
        error(WarningCode.unusedLocalVariable, 124, 2),
        error(WarningCode.unusedLocalVariable, 132, 2),
        error(WarningCode.unusedLocalVariable, 142, 2),
        error(WarningCode.unusedLocalVariable, 162, 2),
        error(WarningCode.unusedLocalVariable, 182, 2),
      ],
    );
    _assertLocalVarType('ai', "A<dynamic>");
    _assertLocalVarType('bi', "B<num>");
    _assertLocalVarType('ci', "C<int, B<int>, A<dynamic>>");
    _assertLocalVarType('aa', "A<dynamic>");
    _assertLocalVarType('bb', "B<num>");
    _assertLocalVarType('cc', "C<int, B<int>, A<dynamic>>");
  }

  test_instantiateToBounds_class_error_extension_malbounded() async {
    // Test that superclasses are strictly checked for malbounded default
    // types
    await assertErrorsInCode(
      r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
class D extends C {}
''',
      [
        error(
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          69,
          1,
          contextMessages: [message(testFile, 69, 1)],
        ),
        error(
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          69,
          1,
          contextMessages: [message(testFile, 69, 1)],
        ),
      ],
    );
  }

  test_instantiateToBounds_class_error_instantiation_malbounded() async {
    // Test that instance creations are strictly checked for malbounded default
    // types
    await assertErrorsInCode(
      r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
void test() {
  var c = new C();
}
''',
      [
        error(WarningCode.unusedLocalVariable, 73, 1),
        error(CompileTimeErrorCode.couldNotInfer, 81, 1),
        error(
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          81,
          1,
          contextMessages: [message(testFile, 81, 1)],
        ),
      ],
    );
    _assertLocalVarType('c', 'C<List<Object?>, List<List<Object?>>>');
  }

  test_instantiateToBounds_class_error_recursion() async {
    await assertErrorsInCode(
      r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 55, 1)],
    );
    _assertTopVarType('c', 'C<List<dynamic>, List<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self() async {
    await assertErrorsInCode(
      r'''
class C<T extends C<T>> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 29, 1)],
    );
    _assertTopVarType('c', 'C<C<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self2() async {
    await assertErrorsInCode(
      r'''
class A<E> {}
class C<T extends A<T>> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 43, 1)],
    );
    _assertTopVarType('c', 'C<A<dynamic>>');
  }

  test_instantiateToBounds_class_error_typedef() async {
    await assertErrorsInCode(
      r'''
typedef T F<T>(T x);
class C<T extends F<T>> {}
C c;
''',
      [
        error(
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          48,
          1,
          contextMessages: [message(testFile, 48, 1), message(testFile, 48, 1)],
        ),
        error(CompileTimeErrorCode.notInitializedNonNullableVariable, 50, 1),
      ],
    );
    _assertTopVarType('c', 'C<dynamic Function(dynamic)>');
  }

  test_instantiateToBounds_class_ok_implicitDynamic_multi() async {
    await assertErrorsInCode(
      r'''
class C<T0 extends Map<T1, T2>, T1 extends List, T2 extends int> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 70, 1)],
    );
    _assertTopVarType('c', 'C<Map<List<dynamic>, int>, List<dynamic>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after() async {
    await assertErrorsInCode(
      r'''
class C<T0 extends T1, T1 extends int> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 44, 1)],
    );
    _assertTopVarType('c', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after2() async {
    await assertErrorsInCode(
      r'''
class C<T0 extends Map<T1, T1>, T1 extends int> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 53, 1)],
    );
    _assertTopVarType('c', 'C<Map<int, int>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_before() async {
    await assertErrorsInCode(
      r'''
class C<T0 extends int, T1 extends T0> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 44, 1)],
    );
    _assertTopVarType('c', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_multi() async {
    await assertErrorsInCode(
      r'''
class C<T0 extends Map<T1, T2>, T1 extends List<T2>, T2 extends int> {}
C c;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 74, 1)],
    );
    _assertTopVarType('c', 'C<Map<List<int>, int>, List<int>, int>');
  }

  test_instantiateToBounds_class_ok_simpleBounds() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
class B<T extends num> {}
class C<T extends List<int>> {}
class D<T extends A> {}
void main() {
  A a;
  B b;
  C c;
  D d;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 114, 1),
        error(WarningCode.unusedLocalVariable, 121, 1),
        error(WarningCode.unusedLocalVariable, 128, 1),
        error(WarningCode.unusedLocalVariable, 135, 1),
      ],
    );
    _assertLocalVarType('a', 'A<dynamic>');
    _assertLocalVarType('b', 'B<num>');
    _assertLocalVarType('c', 'C<List<int>>');
    _assertLocalVarType('d', 'D<A<dynamic>>');
  }

  test_instantiateToBounds_generic_function_error_malbounded() async {
    // Test that generic methods are strictly checked for malbounded default
    // types
    await assertErrorsInCode(
      r'''
T0 f<T0 extends List<T1>, T1 extends List<T0>>() {}
void g() {
  var c = f();
  return;
}
''',
      [
        error(CompileTimeErrorCode.bodyMightCompleteNormally, 3, 1),
        error(WarningCode.unusedLocalVariable, 69, 1),
        error(CompileTimeErrorCode.couldNotInfer, 73, 1),
      ],
    );
    _assertLocalVarType('c', 'List<Object?>');
  }

  test_instantiateToBounds_method_ok_referenceOther_before() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  void m<S0 extends T, S1 extends List<S0>>(S0 p0, S1 p1) {}

  void main() {
    m(null, null);
  }
}
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 97, 4),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 103, 4),
      ],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@class::C::@method::m
    staticType: void Function<S0 extends T, S1 extends List<S0>>(S0, S1)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::C::@method::m::@formalParameter::p0
          substitution: {S0: T, S1: List<T>}
        staticType: Null
      NullLiteral
        literal: null
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::C::@method::m::@formalParameter::p1
          substitution: {S0: T, S1: List<T>}
        staticType: Null
    rightParenthesis: )
  staticInvokeType: void Function(T, List<T>)
  staticType: void
  typeArgumentTypes
    T
    List<T>
''');
  }

  test_instantiateToBounds_method_ok_referenceOther_before2() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  Map<S0, S1> m<S0 extends T, S1 extends List<S0>>() => null;

  void main() {
    m();
  }
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 69, 4)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@class::C::@method::m
    staticType: Map<S0, S1> Function<S0 extends T, S1 extends List<S0>>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Map<T, List<T>> Function()
  staticType: Map<T, List<T>>
  typeArgumentTypes
    T
    List<T>
''');
  }

  test_instantiateToBounds_method_ok_simpleBounds() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  void m<S extends T>(S p0) {}

  void main() {
    m(null);
  }
}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 67, 4)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@class::C::@method::m
    staticType: void Function<S extends T>(S)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::C::@method::m::@formalParameter::p0
          substitution: {S: T}
        staticType: Null
    rightParenthesis: )
  staticInvokeType: void Function(T)
  staticType: void
  typeArgumentTypes
    T
''');
  }

  test_instantiateToBounds_method_ok_simpleBounds2() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  S m<S extends T>() => null;

  void main() {
    m();
  }
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 37, 4)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@class::C::@method::m
    staticType: S Function<S extends T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: T Function()
  staticType: T
  typeArgumentTypes
    T
''');
  }

  test_issue32396() async {
    await assertErrorsInCode(
      r'''
class C<E> {
  static T g<T>(T e) => null;
  static final h = g;
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromMethod, 37, 4)],
    );
  }

  test_objectMethodOnFunctions_Anonymous() async {
    await _objectMethodOnFunctions_helper2(
      r'''
void main() {
  var f = (x) => 3;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 69, 2),
        error(WarningCode.unusedLocalVariable, 94, 2),
        error(WarningCode.unusedLocalVariable, 117, 2),
        error(WarningCode.unusedLocalVariable, 183, 2),
        error(WarningCode.unusedLocalVariable, 210, 2),
        error(WarningCode.unusedLocalVariable, 235, 2),
      ],
    );
  }

  test_objectMethodOnFunctions_Function() async {
    await _objectMethodOnFunctions_helper2(
      r'''
void main() {
  Function f;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 63, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          68,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 88, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          93,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 111, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          116,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 177, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          183,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 204, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          210,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 229, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          235,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          276,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          293,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          308,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          361,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          380,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          397,
          1,
        ),
      ],
    );
  }

  test_objectMethodOnFunctions_Static() async {
    await _objectMethodOnFunctions_helper2(
      r'''
int f(int x) => null;
void main() {
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}
''',
      [
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 16, 4),
        error(WarningCode.unusedLocalVariable, 71, 2),
        error(WarningCode.unusedLocalVariable, 96, 2),
        error(WarningCode.unusedLocalVariable, 119, 2),
        error(WarningCode.unusedLocalVariable, 185, 2),
        error(WarningCode.unusedLocalVariable, 212, 2),
        error(WarningCode.unusedLocalVariable, 237, 2),
      ],
    );
  }

  test_objectMethodOnFunctions_Typedef() async {
    await _objectMethodOnFunctions_helper2(
      r'''
typedef bool Predicate<T>(T object);

void main() {
  Predicate<int> f;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 107, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          112,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 132, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          137,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 155, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          160,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 221, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          227,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 248, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          254,
          1,
        ),
        error(WarningCode.unusedLocalVariable, 273, 2),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          279,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          320,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          337,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          352,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          405,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          424,
          1,
        ),
        error(
          CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
          441,
          1,
        ),
      ],
    );
  }

  test_returnOfInvalidType_object_void() async {
    await assertErrorsInCode(
      "Object f() { void voidFn() => null; return voidFn(); }",
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 43, 8)],
    );
  }

  test_setterWithDynamicTypeIsError() async {
    await assertErrorsInCode(
      r'''
class A {
  dynamic set f(String s) => null;
}
dynamic set g(int x) => null;
''',
      [
        error(CompileTimeErrorCode.nonVoidReturnForSetter, 12, 7),
        error(CompileTimeErrorCode.nonVoidReturnForSetter, 47, 7),
      ],
    );
  }

  test_setterWithExplicitVoidType_returningVoid() async {
    await assertNoErrorsInCode(r'''
void returnsVoid() {}
class A {
  void set f(String s) => returnsVoid();
}
void set g(int x) => returnsVoid();
''');
  }

  test_setterWithNoVoidType() async {
    await assertErrorsInCode(
      r'''
class A {
  set f(String s) {
    return '42';
  }
}
set g(int x) => 42;
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 41, 4)],
    );
  }

  test_setterWithNoVoidType_returningVoid() async {
    await assertNoErrorsInCode(r'''
void returnsVoid() {}
class A {
  set f(String s) => returnsVoid();
}
set g(int x) => returnsVoid();
''');
  }

  test_setterWithOtherTypeIsError() async {
    await assertErrorsInCode(
      r'''
class A {
  String set f(String s) => null;
}
Object set g(x) => null;
''',
      [
        error(CompileTimeErrorCode.nonVoidReturnForSetter, 12, 6),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 38, 4),
        error(CompileTimeErrorCode.nonVoidReturnForSetter, 46, 6),
        error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 65, 4),
      ],
    );
  }

  test_ternaryOperator_null_left() async {
    await assertErrorsInCode(
      r'''
main() {
  var foo = (true) ? null : 3;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 15, 3),
        error(WarningCode.deadCode, 37, 1),
      ],
    );
    expectInitializerType('foo', 'int?');
  }

  test_ternaryOperator_null_right() async {
    await assertErrorsInCode(
      r'''
main() {
  var foo = (true) ? 3 : null;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 15, 3),
        error(WarningCode.deadCode, 34, 4),
      ],
    );
    expectInitializerType('foo', 'int?');
  }

  void _assertLocalVarType(String name, String expectedType) {
    var element = findElement2.localVar(name);
    assertType(element.type, expectedType);
  }

  void _assertTopVarType(String name, String expectedType) {
    var element = findElement2.topVar(name);
    assertType(element.type, expectedType);
  }

  Future<void> _objectMethodOnFunctions_helper2(
    String code,
    List<ExpectedError> expectedErrors,
  ) async {
    await assertErrorsInCode(code, expectedErrors);
    _assertLocalVarType('t0', "String");
    _assertLocalVarType('t1', "String Function()");
    _assertLocalVarType('t2', "int");
    _assertLocalVarType('t3', "String");
    _assertLocalVarType('t4', "String Function()");
    _assertLocalVarType('t5', "int");
  }
}

@reflectiveTest
class StrongModeTypePropagationTest extends PubPackageResolutionTest {
  test_inconsistentMethodInheritance_inferFunctionTypeFromTypedef() async {
    await assertNoErrorsInCode(r'''
typedef bool F<E>(E argument);

abstract class Base {
  f<E extends int>(F<int> x);
}

abstract class BaseCopy extends Base {
}

abstract class Override implements Base, BaseCopy {
  f<E extends int>(x) => null;
}

class C extends Override implements Base {}
''');
  }

  test_localVariableInference_bottom_disabled() async {
    await resolveTestCode(r'''
main() {
  var v = null;
  v; // marker
}''');
    assertTypeDynamic(findElement2.localVar('v').type);
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_localVariableInference_constant() async {
    await resolveTestCode(r'''
main() {
  var v = 3;
  v; // marker
}''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_declaredType_disabled() async {
    await resolveTestCode(r'''
main() {
  dynamic v = 3;
  v; // marker
}''');
    assertTypeDynamic(findElement2.localVar('v').type);
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_localVariableInference_noInitializer_disabled() async {
    await resolveTestCode(r'''
main() {
  var v;
  v = 3;
  v; // marker
}''');
    assertResolvedNodeText(findNode.assignment('= 3'), r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: v
    element: v@15
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: v@15
  writeType: dynamic
  element: <null>
  staticType: int
''');
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_localVariableInference_transitive_field_inferred_lexical() async {
    await resolveTestCode(r'''
class A {
  final x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_inferred_reversed() async {
    await resolveTestCode(r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  final x = 3;
}
main() {
}
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_lexical() async {
    await resolveTestCode(r'''
class A {
  int x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_reversed() async {
    await resolveTestCode(r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  int x = 3;
}
main() {
}
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_list_local() async {
    await resolveTestCode(r'''
main() {
  var x = <int>[3];
  var v = x[0];
  v; // marker
}''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_local() async {
    await resolveTestCode(r'''
main() {
  var x = 3;
  var v = x;
  v; // marker
}''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_inferred_lexical() async {
    await resolveTestCode(r'''
final x = 3;
main() {
  var v = x;
  v; // marker
}
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_toplevel_inferred_reversed() async {
    await resolveTestCode(r'''
main() {
  var v = x;
  v; // marker
}
final x = 3;
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_lexical() async {
    await resolveTestCode(r'''
int x = 3;
main() {
  var v = x;
  v; // marker
}
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_reversed() async {
    await resolveTestCode(r'''
main() {
  var v = x;
  v; // marker
}
int x = 3;
''');
    assertType(findElement2.localVar('v').type, 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }
}
