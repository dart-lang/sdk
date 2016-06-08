// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.strong_mode_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(StrongModeDownwardsInferenceTest);
  runReflectiveTests(StrongModeStaticTypeAnalyzer2Test);
  runReflectiveTests(StrongModeTypePropagationTest);
}

/**
 * Strong mode static analyzer downwards inference tests
 */
@reflectiveTest
class StrongModeDownwardsInferenceTest extends ResolverTestCase {
  TypeAssertions _assertions;

  Asserter<DartType> _isDynamic;
  Asserter<InterfaceType> _isFutureOfDynamic;
  Asserter<InterfaceType> _isFutureOfInt;
  Asserter<DartType> _isInt;
  Asserter<DartType> _isNum;
  Asserter<DartType> _isString;

  AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, DartType>
      _isFunction2Of;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isFutureOf;
  AsserterBuilderBuilder<Asserter<DartType>, List<Asserter<DartType>>, DartType>
      _isInstantiationOf;
  AsserterBuilder<Asserter<DartType>, InterfaceType> _isListOf;
  AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, InterfaceType>
      _isMapOf;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isStreamOf;
  AsserterBuilder<DartType, DartType> _isType;

  AsserterBuilder<Element, DartType> _hasElement;
  AsserterBuilder<DartType, DartType> _sameElement;

  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWithOptions(options);
    _assertions = new TypeAssertions(typeProvider);
    _isType = _assertions.isType;
    _hasElement = _assertions.hasElement;
    _isInstantiationOf = _assertions.isInstantiationOf;
    _isInt = _assertions.isInt;
    _isNum = _assertions.isNum;
    _isString = _assertions.isString;
    _isDynamic = _assertions.isDynamic;
    _isListOf = _assertions.isListOf;
    _isMapOf = _assertions.isMapOf;
    _isFunction2Of = _assertions.isFunction2Of;
    _sameElement = _assertions.sameElement;
    _isFutureOf = _isInstantiationOf(_sameElement(typeProvider.futureType));
    _isFutureOfDynamic = _isFutureOf([_isDynamic]);
    _isFutureOfInt = _isFutureOf([_isInt]);
    _isStreamOf = _isInstantiationOf(_sameElement(typeProvider.streamType));
  }

  void test_async_method_propagation() {
    String code = r'''
      import "dart:async";
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
    CompilationUnit unit = resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      FunctionBody body = test.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        ReturnStatement stmt = (body as BlockFunctionBody).block.statements[0];
        returnExp = stmt.expression;
      }
      DartType type = returnExp.staticType;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.staticType;
      }
      typeTest(type);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    // This should be int when we handle the implicit Future<T> | T union
    // https://github.com/dart-lang/sdk/issues/25322
    check("f4", _isFutureOfDynamic);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    // This should be int when we handle the implicit Future<T> | T union
    // https://github.com/dart-lang/sdk/issues/25322
    check("g4", _isFutureOfDynamic);
    check("g5", _isFutureOfInt);
  }

  void test_async_propagation() {
    String code = r'''
      import "dart:async";

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
    CompilationUnit unit = resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      FunctionBody body = test.functionExpression.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        ReturnStatement stmt = (body as BlockFunctionBody).block.statements[0];
        returnExp = stmt.expression;
      }
      DartType type = returnExp.staticType;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.staticType;
      }
      typeTest(type);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    // This should be int when we handle the implicit Future<T> | T union
    // https://github.com/dart-lang/sdk/issues/25322
    check("f4", _isFutureOfDynamic);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    // This should be int when we handle the implicit Future<T> | T union
    // https://github.com/dart-lang/sdk/issues/25322
    check("g4", _isFutureOfDynamic);
    check("g5", _isFutureOfInt);
  }

  void test_async_star_method_propagation() {
    String code = r'''
      import "dart:async";
      class A {
        Stream g0() async* { yield []; }
        Stream g1() async* { yield* new Stream(); }

        Stream<List<int>> g2() async* { yield []; }
        Stream<List<int>> g3() async* { yield* new Stream(); }
      }
    ''';
    CompilationUnit unit = resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      BlockFunctionBody body = test.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("g0", _isListOf(_isDynamic));
    check("g1", _isStreamOf([_isDynamic]));

    check("g2", _isListOf(_isInt));
    check("g3", _isStreamOf([_isListOf(_isInt)]));
  }

  void test_async_star_propagation() {
    String code = r'''
      import "dart:async";

      Stream g0() async* { yield []; }
      Stream g1() async* { yield* new Stream(); }

      Stream<List<int>> g2() async* { yield []; }
      Stream<List<int>> g3() async* { yield* new Stream(); }
   ''';
    CompilationUnit unit = resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      BlockFunctionBody body = test.functionExpression.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("g0", _isListOf(_isDynamic));
    check("g1", _isStreamOf([_isDynamic]));

    check("g2", _isListOf(_isInt));
    check("g3", _isStreamOf([_isListOf(_isInt)]));
  }

  void test_cascadeExpression() {
    String code = r'''
      class A<T> {
        List<T> map(T a, List<T> mapper(T x)) => mapper(a);
      }

      void main () {
        A<int> a = new A()..map(0, (x) => [x]);
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    CascadeExpression fetch(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      CascadeExpression exp = decl.initializer;
      return exp;
    }
    Element elementA = AstFinder.getClass(unit, "A").element;

    CascadeExpression cascade = fetch(0);
    _isInstantiationOf(_hasElement(elementA))([_isInt])(cascade.staticType);
    MethodInvocation invoke = cascade.cascadeSections[0];
    FunctionExpression function = invoke.argumentList.arguments[1];
    ExecutableElement f0 = function.element;
    _isListOf(_isInt)(f0.type.returnType);
    expect(f0.type.normalParameterTypes[0], typeProvider.intType);
  }

  void test_constructorInitializer_propagation() {
    String code = r'''
      class A {
        List<String> x;
        A() : this.x = [];
      }
   ''';
    CompilationUnit unit = resolveSource(code);
    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    ConstructorFieldInitializer assignment = constructor.initializers[0];
    Expression exp = assignment.expression;
    _isListOf(_isString)(exp.staticType);
  }

  void test_factoryConstructor_propagation() {
    String code = r'''
      class A<T> {
        factory A() { return new B(); }
      }
      class B<S> extends A<S> {}
   ''';
    CompilationUnit unit = resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    BlockFunctionBody body = constructor.body;
    ReturnStatement stmt = body.block.statements[0];
    InstanceCreationExpression exp = stmt.expression;
    ClassElement elementB = AstFinder.getClass(unit, "B").element;
    ClassElement elementA = AstFinder.getClass(unit, "A").element;
    expect(exp.constructorName.type.type.element, elementB);
    _isInstantiationOf(_hasElement(elementB))(
        [_isType(elementA.typeParameters[0].type)])(exp.staticType);
  }

  void test_fieldDeclaration_propagation() {
    String code = r'''
      class A {
        List<String> f0 = ["hello"];
      }
   ''';
    CompilationUnit unit = resolveSource(code);

    VariableDeclaration field = AstFinder.getFieldInClass(unit, "A", "f0");

    _isListOf(_isString)(field.initializer.staticType);
  }

  void test_functionDeclaration_body_propagation() {
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
    CompilationUnit unit = resolveSource(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    FunctionDeclaration test1 = AstFinder.getTopLevelFunction(unit, "test1");
    ExpressionFunctionBody body = test1.functionExpression.body;
    assertListOfInt(body.expression.staticType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test2");

    FunctionDeclaration inner =
        (statements[0] as FunctionDeclarationStatement).functionDeclaration;
    BlockFunctionBody body0 = inner.functionExpression.body;
    ReturnStatement return0 = body0.block.statements[0];
    Expression anon0 = return0.expression;
    FunctionType type0 = anon0.staticType;
    expect(type0.returnType, typeProvider.intType);
    expect(type0.normalParameterTypes[0], typeProvider.stringType);

    FunctionExpression anon1 = (statements[1] as ReturnStatement).expression;
    FunctionType type1 = anon1.element.type;
    expect(type1.returnType, typeProvider.intType);
    expect(type1.normalParameterTypes[0], typeProvider.intType);
  }

  void test_functionLiteral_assignment_typedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_assignment_unTypedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_body_propagation() {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, List<String>> l0 = (int x) => ["hello"];
        Function2<int, List<String>> l1 = (String x) => ["hello"];
        Function2<int, List<String>> l2 = (int x) => [3];
        Function2<int, List<String>> l3 = (int x) {return [3];};
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    Expression functionReturnValue(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }
    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(functionReturnValue(0).staticType);
    assertListOfString(functionReturnValue(1).staticType);
    assertListOfString(functionReturnValue(2).staticType);
    assertListOfString(functionReturnValue(3).staticType);
  }

  void test_functionLiteral_functionExpressionInvocation_typedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      FunctionExpressionInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_functionExpressionInvocation_unTypedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      FunctionExpressionInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_functionInvocation_typedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_functionInvocation_unTypedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_methodInvocation_typedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_methodInvocation_unTypedArguments() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.element.type;
    }
    _isFunction2Of(_isInt, _isString)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isInt)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  void test_functionLiteral_unTypedArgument_propagation() {
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
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    Expression functionReturnValue(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }
    expect(functionReturnValue(0).staticType, typeProvider.intType);
    expect(functionReturnValue(1).staticType, typeProvider.intType);
    expect(functionReturnValue(2).staticType, typeProvider.intType);
    expect(functionReturnValue(3).staticType, typeProvider.dynamicType);
    expect(functionReturnValue(4).staticType, typeProvider.stringType);
  }

  void test_inference_hints() {
    Source source = addSource(r'''
      void main () {
        var x = 3;
        List<int> l0 = [];
     }
   ''');
    resolve2(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inferredFieldDeclaration_propagation() {
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
    CompilationUnit unit = resolveSource(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertMapOfIntToListOfInt =
        _isMapOf(_isInt, assertListOfInt);

    VariableDeclaration mapB = AstFinder.getFieldInClass(unit, "B", "map");
    MethodDeclaration mapC = AstFinder.getMethodInClass(unit, "C", "map");
    assertMapOfIntToListOfInt(mapB.element.type);
    assertMapOfIntToListOfInt(mapC.element.returnType);

    MapLiteral mapLiteralB = mapB.initializer;
    MapLiteral mapLiteralC = (mapC.body as ExpressionFunctionBody).expression;
    assertMapOfIntToListOfInt(mapLiteralB.staticType);
    assertMapOfIntToListOfInt(mapLiteralC.staticType);

    ListLiteral listLiteralB = mapLiteralB.entries[0].value;
    ListLiteral listLiteralC = mapLiteralC.entries[0].value;
    assertListOfInt(listLiteralB.staticType);
    assertListOfInt(listLiteralC.staticType);
  }

  void test_instanceCreation() {
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
        // Currently we only allow variable constraints.  Test that we reject.
        A<C<int>, String> a0 = new E("hello");
      }
      void test9() { // Check named and optional arguments
        A<int, String> a0 = new F(3, "hello", a: [3], b: ["hello"]);
        A<int, String> a1 = new F(3, "hello", a: ["hello"], b:[3]);
        A<int, String> a2 = new F.named(3, "hello", 3, "hello");
        A<int, String> a3 = new F.named(3, "hello");
        A<int, String> a4 = new F.named(3, "hello", "hello", 3);
        A<int, String> a5 = new F.named(3, "hello", "hello");
      }
    }''';
    CompilationUnit unit = resolveSource(code);

    Expression rhs(VariableDeclarationStatement stmt) {
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression exp = decl.initializer;
      return exp;
    }

    void hasType(Asserter<DartType> assertion, Expression exp) =>
        assertion(exp.staticType);

    Element elementA = AstFinder.getClass(unit, "A").element;
    Element elementB = AstFinder.getClass(unit, "B").element;
    Element elementC = AstFinder.getClass(unit, "C").element;
    Element elementD = AstFinder.getClass(unit, "D").element;
    Element elementE = AstFinder.getClass(unit, "E").element;
    Element elementF = AstFinder.getClass(unit, "F").element;

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
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test0");

      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertAOf([_isInt, _isDynamic]), rhs(statements[4]));
      hasType(assertAOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test1");
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test2");
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[2]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[3]));
      hasType(assertBOf([_isString, _isDynamic]), rhs(statements[4]));
      hasType(assertBOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test3");
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test4");
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
      hasType(assertCOf([_isInt]), rhs(statements[2]));
      hasType(assertCOf([_isInt]), rhs(statements[3]));
      hasType(assertCOf([_isDynamic]), rhs(statements[4]));
      hasType(assertCOf([_isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test5");
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
    }

    {
      // The first type parameter is not constrained by the
      // context.  We could choose a tighter type, but currently
      // we just use dynamic.
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test6");
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
      hasType(assertDOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertDOf([_isString, _isString]), rhs(statements[3]));
      hasType(assertDOf([_isNum, _isDynamic]), rhs(statements[4]));
      hasType(assertDOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test7");
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test8");
      hasType(assertEOf([_isDynamic, _isDynamic]), rhs(statements[0]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test9");
      hasType(assertFOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[4]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[5]));
    }
  }

  void test_listLiteral_nested() {
    String code = r'''
      void main () {
        List<List<int>> l0 = [[]];
        Iterable<List<int>> l1 = [[3]];
        Iterable<List<int>> l2 = [[3], [4]];
        List<List<int>> l3 = [["hello", 3], []];
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    ListLiteral literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertListOfListOfInt = _isListOf(assertListOfInt);

    assertListOfListOfInt(literal(0).staticType);
    assertListOfListOfInt(literal(1).staticType);
    assertListOfListOfInt(literal(2).staticType);
    assertListOfListOfInt(literal(3).staticType);

    assertListOfInt(literal(1).elements[0].staticType);
    assertListOfInt(literal(2).elements[0].staticType);
    assertListOfInt(literal(3).elements[0].staticType);
  }

  void test_listLiteral_simple() {
    String code = r'''
      void main () {
        List<int> l0 = [];
        List<int> l1 = [3];
        List<int> l2 = ["hello"];
        List<int> l3 = ["hello", 3];
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  void test_listLiteral_simple_const() {
    String code = r'''
      void main () {
        const List<int> c0 = const [];
        const List<int> c1 = const [3];
        const List<int> c2 = const ["hello"];
        const List<int> c3 = const ["hello", 3];
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  void test_listLiteral_simple_disabled() {
    String code = r'''
      void main () {
        List<int> l0 = <num>[];
        List<int> l1 = <num>[3];
        List<int> l2 = <String>["hello"];
        List<int> l3 = <dynamic>["hello", 3];
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    _isListOf(_isNum)(literal(0));
    _isListOf(_isNum)(literal(1));
    _isListOf(_isString)(literal(2));
    _isListOf(_isDynamic)(literal(3));
  }

  void test_listLiteral_simple_subtype() {
    String code = r'''
      void main () {
        Iterable<int> l0 = [];
        Iterable<int> l1 = [3];
        Iterable<int> l2 = ["hello"];
        Iterable<int> l3 = ["hello", 3];
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  void test_mapLiteral_nested() {
    String code = r'''
      void main () {
        Map<int, List<String>> l0 = {};
        Map<int, List<String>> l1 = {3: ["hello"]};
        Map<int, List<String>> l2 = {"hello": ["hello"]};
        Map<int, List<String>> l3 = {3: [3]};
        Map<int, List<String>> l4 = {3:["hello"], "hello": [3]};
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    MapLiteral literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      MapLiteral exp = decl.initializer;
      return exp;
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    Asserter<InterfaceType> assertMapOfIntToListOfString =
        _isMapOf(_isInt, assertListOfString);

    assertMapOfIntToListOfString(literal(0).staticType);
    assertMapOfIntToListOfString(literal(1).staticType);
    assertMapOfIntToListOfString(literal(2).staticType);
    assertMapOfIntToListOfString(literal(3).staticType);
    assertMapOfIntToListOfString(literal(4).staticType);

    assertListOfString(literal(1).entries[0].value.staticType);
    assertListOfString(literal(2).entries[0].value.staticType);
    assertListOfString(literal(3).entries[0].value.staticType);
    assertListOfString(literal(4).entries[0].value.staticType);
  }

  void test_mapLiteral_simple() {
    String code = r'''
      void main () {
        Map<int, String> l0 = {};
        Map<int, String> l1 = {3: "hello"};
        Map<int, String> l2 = {"hello": "hello"};
        Map<int, String> l3 = {3: 3};
        Map<int, String> l4 = {3:"hello", "hello": 3};
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      MapLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertMapOfIntToString =
        _isMapOf(_isInt, _isString);

    assertMapOfIntToString(literal(0));
    assertMapOfIntToString(literal(1));
    assertMapOfIntToString(literal(2));
    assertMapOfIntToString(literal(3));
  }

  void test_mapLiteral_simple_disabled() {
    String code = r'''
      void main () {
        Map<int, String> l0 = <int, dynamic>{};
        Map<int, String> l1 = <int, dynamic>{3: "hello"};
        Map<int, String> l2 = <int, dynamic>{"hello": "hello"};
        Map<int, String> l3 = <int, dynamic>{3: 3};
     }
   ''';
    CompilationUnit unit = resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      MapLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertMapOfIntToDynamic =
        _isMapOf(_isInt, _isDynamic);

    assertMapOfIntToDynamic(literal(0));
    assertMapOfIntToDynamic(literal(1));
    assertMapOfIntToDynamic(literal(2));
    assertMapOfIntToDynamic(literal(3));
  }

  void test_methodDeclaration_body_propagation() {
    String code = r'''
      class A {
        List<String> m0(int x) => ["hello"];
        List<String> m1(int x) {return [3];};
      }
   ''';
    CompilationUnit unit = resolveSource(code);
    Expression methodReturnValue(String methodName) {
      MethodDeclaration method =
          AstFinder.getMethodInClass(unit, "A", methodName);
      FunctionBody body = method.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }
    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(methodReturnValue("m0").staticType);
    assertListOfString(methodReturnValue("m1").staticType);
  }

  void test_redirectingConstructor_propagation() {
    String code = r'''
      class A {
        A() : this.named([]);
        A.named(List<String> x);
      }
   ''';
    CompilationUnit unit = resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    RedirectingConstructorInvocation invocation = constructor.initializers[0];
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType);
  }

  void test_superConstructorInvocation_propagation() {
    String code = r'''
      class B {
        B(List<String>);
      }
      class A extends B {
        A() : super([]);
      }
   ''';
    CompilationUnit unit = resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    SuperConstructorInvocation invocation = constructor.initializers[0];
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType);
  }

  void test_sync_star_method_propagation() {
    String code = r'''
      import "dart:async";
      class A {
        Iterable f0() sync* { yield []; }
        Iterable f1() sync* { yield* new List(); }

        Iterable<List<int>> f2() sync* { yield []; }
        Iterable<List<int>> f3() sync* { yield* new List(); }
      }
   ''';
    CompilationUnit unit = resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      BlockFunctionBody body = test.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("f0", _isListOf(_isDynamic));
    check("f1", _isListOf(_isDynamic));

    check("f2", _isListOf(_isInt));
    check("f3", _isListOf(_isListOf(_isInt)));
  }

  void test_sync_star_propagation() {
    String code = r'''
      import "dart:async";

      Iterable f0() sync* { yield []; }
      Iterable f1() sync* { yield* new List(); }

      Iterable<List<int>> f2() sync* { yield []; }
      Iterable<List<int>> f3() sync* { yield* new List(); }
   ''';
    CompilationUnit unit = resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      BlockFunctionBody body = test.functionExpression.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("f0", _isListOf(_isDynamic));
    check("f1", _isListOf(_isDynamic));

    check("f2", _isListOf(_isInt));
    check("f3", _isListOf(_isListOf(_isInt)));
  }
}

/**
 * Strong mode static analyzer end to end tests
 */
@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test extends StaticTypeAnalyzer2TestShared {
  void fail_genericMethod_tearoff_instantiated() {
    resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(E e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodTearOffInst = c.f/*<int>*/;
  var staticTearOffInst = C.g/*<int>*/;
  var staticFieldTearOffInst = C.h/*<int>*/;
  var topFunTearOffInst = topF/*<int>*/;
  var topFieldTearOffInst = topG/*<int>*/;
  var localTearOffInst = lf/*<int>*/;
  var paramTearOffInst = pf/*<int>*/;
}
''');
    expectIdentifierType('methodTearOffInst', "(int) → int");
    expectIdentifierType('staticTearOffInst', "(int) → int");
    expectIdentifierType('staticFieldTearOffInst', "(int) → int");
    expectIdentifierType('topFunTearOffInst', "(int) → int");
    expectIdentifierType('topFieldTearOffInst', "(int) → int");
    expectIdentifierType('localTearOffInst', "(int) → int");
    expectIdentifierType('paramTearOffInst', "(int) → int");
  }

  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWithOptions(options);
  }

  void test_dynamicObjectGetter_hashCode() {
    String code = r'''
main() {
  dynamic a = null;
  var foo = a.hashCode;
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  void test_dynamicObjectMethod_toString() {
    String code = r'''
main() {
  dynamic a = null;
  var foo = a.toString();
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'String', isNull);
  }

  void test_genericFunction() {
    resolveTestUnit(r'/*=T*/ f/*<T>*/(/*=T*/ x) => null;');
    expectFunctionType('f', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findIdentifier('f');
    FunctionElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  void test_genericFunction_bounds() {
    resolveTestUnit(r'/*=T*/ f/*<T extends num>*/(/*=T*/ x) => null;');
    expectFunctionType('f', '<T extends num>(T) → T',
        elementTypeParams: '[T extends num]', typeFormals: '[T extends num]');
  }

  void test_genericFunction_parameter() {
    resolveTestUnit(r'''
void g(/*=T*/ f/*<T>*/(/*=T*/ x)) {}
''');
    expectFunctionType('f', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findIdentifier('f');
    ParameterElementImpl e = f.staticElement;
    FunctionType type = e.type;
    FunctionType ft = type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  void test_genericFunction_static() {
    resolveTestUnit(r'''
class C<E> {
  static /*=T*/ f/*<T>*/(/*=T*/ x) => null;
}
''');
    expectFunctionType('f', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findIdentifier('f');
    MethodElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  void test_genericFunction_typedef() {
    String code = r'''
typedef T F<T>(T x);
F f0;

class C {
  static F f1;
  F f2;
  void g(F f3) {
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
  void g(F f3) {
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}
''';
    resolveTestUnit(code);

    checkBody(String className) {
      List<Statement> statements =
          AstFinder.getStatementsInMethod(testUnit, className, "g");

      for (int i = 1; i <= 5; i++) {
        Expression exp = (statements[i] as ExpressionStatement).expression;
        expect(exp.staticType, typeProvider.dynamicType);
      }
    }

    checkBody("C");
    checkBody("D");
  }

  void test_genericMethod() {
    resolveTestUnit(r'''
class C<E> {
  List/*<T>*/ f/*<T>*/(E e) => null;
}
main() {
  C<String> cOfString;
}
''');
    expectFunctionType('f', '<T>(E) → List<T>',
        elementTypeParams: '[T]',
        typeParams: '[E]',
        typeArgs: '[E]',
        typeFormals: '[T]');
    SimpleIdentifier c = findIdentifier('cOfString');
    FunctionType ft = (c.staticType as InterfaceType).getMethod('f').type;
    expect(ft.toString(), '<T>(String) → List<T>');
    ft = ft.instantiate([typeProvider.intType]);
    expect(ft.toString(), '(String) → List<int>');
    expect('${ft.typeArguments}/${ft.typeParameters}', '[String, int]/[E, T]');
  }

  void test_genericMethod_explicitTypeParams() {
    resolveTestUnit(r'''
class C<E> {
  List/*<T>*/ f/*<T>*/(E e) => null;
}
main() {
  C<String> cOfString;
  var x = cOfString.f/*<int>*/('hi');
}
''');
    MethodInvocation f = findIdentifier('f/*<int>*/').parent;
    FunctionType ft = f.staticInvokeType;
    expect(ft.toString(), '(String) → List<int>');
    expect('${ft.typeArguments}/${ft.typeParameters}', '[String, int]/[E, T]');

    SimpleIdentifier x = findIdentifier('x');
    expect(x.staticType,
        typeProvider.listType.instantiate([typeProvider.intType]));
  }

  void test_genericMethod_functionExpressionInvocation_explicit() {
    resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;

  var lambdaCall = (/*<E>*/(/*=E*/ e) => e)/*<int>*/(3);
  var methodCall = (c.f)/*<int>*/(3);
  var staticCall = (C.g)/*<int>*/(3);
  var staticFieldCall = (C.h)/*<int>*/(3);
  var topFunCall = (topF)/*<int>*/(3);
  var topFieldCall = (topG)/*<int>*/(3);
  var localCall = (lf)/*<int>*/(3);
  var paramCall = (pf)/*<int>*/(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
    expectIdentifierType('lambdaCall', "int");
  }

  void test_genericMethod_functionExpressionInvocation_inferred() {
    resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;

  var lambdaCall = (/*<E>*/(/*=E*/ e) => e)(3);
  var methodCall = (c.f)(3);
  var staticCall = (C.g)(3);
  var staticFieldCall = (C.h)(3);
  var topFunCall = (topF)(3);
  var topFieldCall = (topG)(3);
  var localCall = (lf)(3);
  var paramCall = (pf)(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
    expectIdentifierType('lambdaCall', "int");
  }

  void test_genericMethod_functionInvocation_explicit() {
    resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodCall = c.f/*<int>*/(3);
  var staticCall = C.g/*<int>*/(3);
  var staticFieldCall = C.h/*<int>*/(3);
  var topFunCall = topF/*<int>*/(3);
  var topFieldCall = topG/*<int>*/(3);
  var localCall = lf/*<int>*/(3);
  var paramCall = pf/*<int>*/(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
  }

  void test_genericMethod_functionInvocation_inferred() {
    resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(/*=T*/ e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodCall = c.f(3);
  var staticCall = C.g(3);
  var staticFieldCall = C.h(3);
  var topFunCall = topF(3);
  var topFieldCall = topG(3);
  var localCall = lf(3);
  var paramCall = pf(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
  }

  void test_genericMethod_functionTypedParameter() {
    resolveTestUnit(r'''
class C<E> {
  List/*<T>*/ f/*<T>*/(/*=T*/ f(E e)) => null;
}
main() {
  C<String> cOfString;
}
''');
    expectFunctionType('f', '<T>((E) → T) → List<T>',
        elementTypeParams: '[T]',
        typeParams: '[E]',
        typeArgs: '[E]',
        typeFormals: '[T]');

    SimpleIdentifier c = findIdentifier('cOfString');
    FunctionType ft = (c.staticType as InterfaceType).getMethod('f').type;
    expect(ft.toString(), '<T>((String) → T) → List<T>');
    ft = ft.instantiate([typeProvider.intType]);
    expect(ft.toString(), '((String) → int) → List<int>');
  }

  void test_genericMethod_implicitDynamic() {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25100#issuecomment-162047588
    // These should not cause any hints or warnings.
    resolveTestUnit(r'''
class List<E> {
  /*=T*/ map/*<T>*/(/*=T*/ f(E e)) => null;
}
void foo() {
  List list = null;
  list.map((e) => e);
  list.map((e) => 3);
}''');
    expectIdentifierType('map((e) => e);', '<T>((dynamic) → T) → T', isNull);
    expectIdentifierType('map((e) => 3);', '<T>((dynamic) → T) → T', isNull);

    MethodInvocation m1 = findIdentifier('map((e) => e);').parent;
    expect(m1.staticInvokeType.toString(), '((dynamic) → dynamic) → dynamic');
    MethodInvocation m2 = findIdentifier('map((e) => 3);').parent;
    expect(m2.staticInvokeType.toString(), '((dynamic) → int) → int');
  }

  void test_genericMethod_max_doubleDouble() {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2.0);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'double', isNull);
  }

  void test_genericMethod_max_doubleDouble_prefixed() {
    String code = r'''
import 'dart:math' as math;
main() {
  var foo = math.max(1.0, 2.0);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'double', isNull);
  }

  void test_genericMethod_max_doubleInt() {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'num', isNull);
  }

  void test_genericMethod_max_intDouble() {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1, 2.0);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'num', isNull);
  }

  void test_genericMethod_max_intInt() {
    String code = r'''
import 'dart:math';
main() {
  var foo = max(1, 2);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  void test_genericMethod_nestedBound() {
    String code = r'''
class Foo<T extends num> {
  void method/*<U extends T>*/(dynamic/*=U*/ u) {
    u.abs();
  }
}
''';
    // Just validate that there is no warning on the call to `.abs()`.
    resolveTestUnit(code);
  }

  void test_genericMethod_nestedCapture() {
    resolveTestUnit(r'''
class C<T> {
  /*=T*/ f/*<S>*/(/*=S*/ x) {
    new C<S>().f/*<int>*/(3);
    new C<S>().f; // tear-off
    return null;
  }
}
''');
    MethodInvocation f = findIdentifier('f/*<int>*/(3);').parent;
    expect(f.staticInvokeType.toString(), '(int) → S');
    FunctionType ft = f.staticInvokeType;
    expect('${ft.typeArguments}/${ft.typeParameters}', '[S, int]/[T, S]');

    expectIdentifierType('f;', '<S₀>(S₀) → S');
  }

  void test_genericMethod_nestedFunctions() {
    resolveTestUnit(r'''
/*=S*/ f/*<S>*/(/*=S*/ x) {
  g/*<S>*/(/*=S*/ x) => f;
  return null;
}
''');
    expectIdentifierType('f', '<S>(S) → S');
    expectIdentifierType('g', '<S>(S) → dynamic');
  }

  void test_genericMethod_override() {
    resolveTestUnit(r'''
class C {
  /*=T*/ f/*<T>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=T*/ f/*<T>*/(/*=T*/ x) => null; // from D
}
''');
    expectFunctionType('f/*<T>*/(/*=T*/ x) => null; // from D', '<T>(T) → T',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f =
        findIdentifier('f/*<T>*/(/*=T*/ x) => null; // from D');
    MethodElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), '(String) → String');
  }

  void test_genericMethod_override_bounds() {
    resolveTestUnit(r'''
class A {}
class B extends A {}
class C {
  /*=T*/ f/*<T extends B>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=T*/ f/*<T extends A>*/(/*=T*/ x) => null;
}
''');
  }

  void test_genericMethod_override_invalidReturnType() {
    Source source = addSource(r'''
class C {
  Iterable/*<T>*/ f/*<T>*/(/*=T*/ x) => null;
}
class D extends C {
  String f/*<S>*/(/*=S*/ x) => null;
}''');
    // TODO(jmesserly): we can't use assertErrors because STRONG_MODE_* errors
    // from CodeChecker don't have working equality.
    List<AnalysisError> errors = analysisContext2.computeErrors(source);

    // Sort errors by name.
    errors.sort((AnalysisError e1, AnalysisError e2) =>
        e1.errorCode.name.compareTo(e2.errorCode.name));

    expect(
        errors.map((e) => e.errorCode.name),
        unorderedEquals([
          'INVALID_METHOD_OVERRIDE_RETURN_TYPE',
          'STRONG_MODE_INVALID_METHOD_OVERRIDE'
        ]));
    expect(errors[0].message, contains('Iterable<S>'),
        reason: 'errors should be in terms of the type parameters '
            'at the error location');
    verify([source]);
  }

  void test_genericMethod_override_invalidTypeParamBounds() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C {
  /*=T*/ f/*<T extends A>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=T*/ f/*<T extends B>*/(/*=T*/ x) => null;
}''');
    // TODO(jmesserly): this is modified code from assertErrors, which we can't
    // use directly because STRONG_MODE_* errors don't have working equality.
    List<AnalysisError> errors = analysisContext2.computeErrors(source);
    expect(
        errors.map((e) => e.errorCode.name),
        unorderedEquals([
          'INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND',
          'STRONG_MODE_INVALID_METHOD_OVERRIDE'
        ]));
    verify([source]);
  }

  void test_genericMethod_override_invalidTypeParamCount() {
    Source source = addSource(r'''
class C {
  /*=T*/ f/*<T>*/(/*=T*/ x) => null;
}
class D extends C {
  /*=S*/ f/*<T, S>*/(/*=T*/ x) => null;
}''');
    // TODO(jmesserly): we can't use assertErrors because STRONG_MODE_* errors
    // from CodeChecker don't have working equality.
    List<AnalysisError> errors = analysisContext2.computeErrors(source);
    expect(
        errors.map((e) => e.errorCode.name),
        unorderedEquals([
          'STRONG_MODE_INVALID_METHOD_OVERRIDE',
          'INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS'
        ]));
    verify([source]);
  }

  void test_genericMethod_propagatedType_promotion() {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340

    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // example won't work, as we now compute a static type and therefore discard
    // the propagated type. So a new test was created that doesn't run under
    // strong mode.
    resolveTestUnit(r'''
abstract class Iter {
  List/*<S>*/ map/*<S>*/(/*=S*/ f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
  }
  return null;
}''');
    expectIdentifierType('y = ', 'List<C>', isNull);
  }

  void test_genericMethod_tearoff() {
    resolveTestUnit(r'''
class C<E> {
  /*=T*/ f/*<T>*/(E e) => null;
  static /*=T*/ g/*<T>*/(/*=T*/ e) => null;
  static final h = g;
}

/*=T*/ topF/*<T>*/(/*=T*/ e) => null;
var topG = topF;
void test/*<S>*/(/*=T*/ pf/*<T>*/(/*=T*/ e)) {
  var c = new C<int>();
  /*=T*/ lf/*<T>*/(/*=T*/ e) => null;
  var methodTearOff = c.f;
  var staticTearOff = C.g;
  var staticFieldTearOff = C.h;
  var topFunTearOff = topF;
  var topFieldTearOff = topG;
  var localTearOff = lf;
  var paramTearOff = pf;
}
''');
    expectIdentifierType('methodTearOff', "<T>(int) → T");
    expectIdentifierType('staticTearOff', "<T>(T) → T");
    expectIdentifierType('staticFieldTearOff', "<T>(T) → T");
    expectIdentifierType('topFunTearOff', "<T>(T) → T");
    expectIdentifierType('topFieldTearOff', "<T>(T) → T");
    expectIdentifierType('localTearOff', "<T>(T) → T");
    expectIdentifierType('paramTearOff', "<T>(T) → T");
  }

  void test_genericMethod_then() {
    String code = r'''
import 'dart:async';
String toString(int x) => x.toString();
main() {
  Future<int> bar = null;
  var foo = bar.then(toString);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'Future<String>', isNull);
  }

  void test_genericMethod_then_prefixed() {
    String code = r'''
import 'dart:async' as async;
String toString(int x) => x.toString();
main() {
  async.Future<int> bar = null;
  var foo = bar.then(toString);
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'Future<String>', isNull);
  }

  void test_genericMethod_then_propagatedType() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25482.
    String code = r'''
import 'dart:async';
void main() {
  Future<String> p;
  var foo = p.then((r) => new Future<String>.value(3));
}
''';
    // This should produce no hints or warnings.
    resolveTestUnit(code);
    expectInitializerType('foo', 'Future<String>', isNull);
  }

  void test_implicitBounds() {
    String code = r'''
class A<T> {}

class B<T extends num> {}

class C<S extends int, T extends B<S>, U extends B> {}

void test() {
//
  A ai;
  B bi;
  C ci;
  var aa = new A();
  var bb = new B();
  var cc = new C();
}
''';
    resolveTestUnit(code);
    expectIdentifierType('ai', "A<dynamic>");
    expectIdentifierType('bi', "B<num>");
    expectIdentifierType('ci', "C<int, B<int>, B<dynamic>>");
    expectIdentifierType('aa', "A<dynamic>");
    expectIdentifierType('bb', "B<num>");
    expectIdentifierType('cc', "C<int, B<int>, B<dynamic>>");
  }

  void test_setterWithDynamicTypeIsError() {
    Source source = addSource(r'''
class A {
  dynamic set f(String s) => null;
}
dynamic set g(int x) => null;
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER,
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER
    ]);
    verify([source]);
  }

  void test_setterWithExplicitVoidType_returningVoid() {
    Source source = addSource(r'''
void returnsVoid() {}
class A {
  void set f(String s) => returnsVoid();
}
void set g(int x) => returnsVoid();
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_setterWithNoVoidType() {
    Source source = addSource(r'''
class A {
  set f(String s) {
    return '42';
  }
}
set g(int x) => 42;
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,]);
    verify([source]);
  }

  void test_setterWithNoVoidType_returningVoid() {
    Source source = addSource(r'''
void returnsVoid() {}
class A {
  set f(String s) => returnsVoid();
}
set g(int x) => returnsVoid();
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_setterWithOtherTypeIsError() {
    Source source = addSource(r'''
class A {
  String set f(String s) => null;
}
Object set g(x) => null;
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER,
      StaticWarningCode.NON_VOID_RETURN_FOR_SETTER
    ]);
    verify([source]);
  }

  void test_ternaryOperator_null_left() {
    String code = r'''
main() {
  var foo = (true) ? null : 3;
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }

  void test_ternaryOperator_null_right() {
    String code = r'''
main() {
  var foo = (true) ? 3 : null;
}
''';
    resolveTestUnit(code);
    expectInitializerType('foo', 'int', isNull);
  }
}

@reflectiveTest
class StrongModeTypePropagationTest extends ResolverTestCase {
  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWithOptions(options);
  }

  void test_foreachInference_dynamic_disabled() {
    String code = r'''
main() {
  var list = <int>[];
  for (dynamic v in list) {
    v; // marker
  }
}''';
    assertPropagatedIterationType(
        code, typeProvider.dynamicType, typeProvider.intType);
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_foreachInference_reusedVar_disabled() {
    String code = r'''
main() {
  var list = <int>[];
  var v;
  for (v in list) {
    v; // marker
  }
}''';
    assertPropagatedIterationType(
        code, typeProvider.dynamicType, typeProvider.intType);
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_foreachInference_var() {
    String code = r'''
main() {
  var list = <int>[];
  for (var v in list) {
    v; // marker
  }
}''';
    assertPropagatedIterationType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_foreachInference_var_iterable() {
    String code = r'''
main() {
  Iterable<int> list = <int>[];
  for (var v in list) {
    v; // marker
  }
}''';
    assertPropagatedIterationType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_foreachInference_var_stream() {
    String code = r'''
import 'dart:async';
main() async {
  Stream<int> stream = null;
  await for (var v in stream) {
    v; // marker
  }
}''';
    assertPropagatedIterationType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_bottom_disabled() {
    String code = r'''
main() {
  var v = null;
  v; // marker
}''';
    assertPropagatedAssignedType(code, typeProvider.dynamicType, null);
    assertTypeOfMarkedExpression(code, typeProvider.dynamicType, null);
  }

  void test_localVariableInference_constant() {
    String code = r'''
main() {
  var v = 3;
  v; // marker
}''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_declaredType_disabled() {
    String code = r'''
main() {
  dynamic v = 3;
  v; // marker
}''';
    assertPropagatedAssignedType(
        code, typeProvider.dynamicType, typeProvider.intType);
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_localVariableInference_noInitializer_disabled() {
    String code = r'''
main() {
  var v;
  v = 3;
  v; // marker
}''';
    assertPropagatedAssignedType(
        code, typeProvider.dynamicType, typeProvider.intType);
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_localVariableInference_transitive_field_inferred_lexical() {
    String code = r'''
class A {
  final x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_field_inferred_reversed() {
    String code = r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  final x = 3;
}
main() {
}
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_field_lexical() {
    String code = r'''
class A {
  int x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_field_reversed() {
    String code = r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  int x = 3;
}
main() {
}
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_list_local() {
    String code = r'''
main() {
  var x = <int>[3];
  var v = x[0];
  v; // marker
}''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_local() {
    String code = r'''
main() {
  var x = 3;
  var v = x;
  v; // marker
}''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_toplevel_inferred_lexical() {
    String code = r'''
final x = 3;
main() {
  var v = x;
  v; // marker
}
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_toplevel_inferred_reversed() {
    String code = r'''
main() {
  var v = x;
  v; // marker
}
final x = 3;
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_toplevel_lexical() {
    String code = r'''
int x = 3;
main() {
  var v = x;
  v; // marker
}
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }

  void test_localVariableInference_transitive_toplevel_reversed() {
    String code = r'''
main() {
  var v = x;
  v; // marker
}
int x = 3;
''';
    assertPropagatedAssignedType(code, typeProvider.intType, null);
    assertTypeOfMarkedExpression(code, typeProvider.intType, null);
  }
}
