// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../src/dart/resolution/node_text_expectations.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test);
    defineReflectiveTests(StrongModeTypePropagationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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

  @override
  Future<ResolvedUnitResultImpl> resolveFile(File file) async {
    var result = await super.resolveFile(file);
    _initAssertions(result.typeProvider);
    return result;
  }

  test_async_method_propagation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
   ''');

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(
        result.unit,
        "A",
        name,
      );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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
   ''');

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(
        result.unit,
        name,
      );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      class A<T> {
        List<T> map(T a, List<T> mapper(T x)) => mapper(a);
      }

      void main () {
        A<int> a = new A()..map(0, (x) => [x]);
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      }
   ''');
    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
      "main",
    );
    CascadeExpression fetch(int i) {
      var stmt = statements[i] as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      var exp = decl.initializer as CascadeExpression;
      return exp;
    }

    var elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;

    CascadeExpression cascade = fetch(0);
    _isInstantiationOf(_hasElement(elementA))([_isInt])(cascade.typeOrThrow);
    var invoke = cascade.cascadeSections[0] as MethodInvocation;
    var function = invoke.argumentList.arguments[1] as FunctionExpression;
    ExecutableElement f0 = function.declaredFragment!.element;
    _isListOf(_isInt)(f0.type.returnType as InterfaceType);
    expect(f0.type.normalParameterTypes[0], result.typeProvider.intType);
  }

  test_constrainedByBounds1() async {
    // Test that upwards inference with two type variables correctly
    // propagates from the constrained variable to the unconstrained
    // variable if they are ordered left to right.
    var result = await resolveTestCodeWithDiagnostics(r'''
    T f<S, T extends S>(S x) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
    void test() { var x = f(3); }
//                    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    T f<T extends S, S>(S x) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
    void test() { var x = f(3); }
//                    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
      "test",
    );
    var stmt = statements[0] as VariableDeclarationStatement;
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer!;
    _isInt(call.typeOrThrow);
  }

  test_constrainedByBounds3() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
      T f<T extends S, S extends int>(S x) => null;
//                                            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
      void test() { var x = f(3); }
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    T f<S, T extends Func1<S, S>>(S x) => null;
//                                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
    void test() { var x = f(3)(4); }
//                    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    T f<T extends Func1<S, S>, S>(S x) => null;
//                                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
    void test() { var x = f(3)(null); }
//                    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//                        ^
// [diag.couldNotInfer] Couldn't infer type parameter 'T'.\n\nTried to infer 'Object? Function(Never)' for 'T' which doesn't work:\n  Type parameter 'T' is declared to extend 'S Function(S)' producing 'int Function(int)'.\n\nConsider passing explicit type argument(s) to the generic.
//                             ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'Never'.
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(code);
    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      result.unit,
      "A",
      null,
    );
    var assignment = constructor.initializers[0] as ConstructorFieldInitializer;
    Expression exp = assignment.expression;
    _isListOf(_isString)(exp.staticType as InterfaceType);
  }

  test_factoryConstructor_propagation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
      class A<T> {
        factory A() { return new B(); }
      }
      class B<S> extends A<S> {}
//                       ^^^^
// [diag.noGenerativeConstructorsInSuperclass] The class 'B' can't extend 'A' because 'A' only has factory constructors (no generative constructors), and 'B' has at least one generative constructor.
   ''');

    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      result.unit,
      "A",
      null,
    );
    var body = constructor.body as BlockFunctionBody;
    var stmt = body.block.statements[0] as ReturnStatement;
    var exp = stmt.expression as InstanceCreationExpression;
    ClassElement elementB = AstFinder.getClass(
      result.unit,
      "B",
    ).declaredFragment!.element;
    ClassElement elementA = AstFinder.getClass(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(code);

    VariableDeclaration field = AstFinder.getFieldInClass(
      result.unit,
      "A",
      "f0",
    );

    _isListOf(_isString)(field.initializer!.staticType as InterfaceType);
  }

  test_functionDeclaration_body_propagation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
      typedef T Function2<S, T>(S x);

      List<int> test1() => [];

      Function2<int, int> test2 (int x) {
        Function2<String, int> inner() {
//                             ^^^^^
// [diag.unusedElement] The declaration 'inner' isn't referenced.
          return (x) => x.length;
        }
        return (x) => x;
     }
   ''');

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    FunctionDeclaration test1 = AstFinder.getTopLevelFunction(
      result.unit,
      "test1",
    );
    var body = test1.functionExpression.body as ExpressionFunctionBody;
    assertListOfInt(body.expression.staticType as InterfaceType);

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
      "test2",
    );

    FunctionDeclaration inner =
        (statements[0] as FunctionDeclarationStatement).functionDeclaration;
    var body0 = inner.functionExpression.body as BlockFunctionBody;
    var return0 = body0.block.statements[0] as ReturnStatement;
    Expression anon0 = return0.expression!;
    var type0 = anon0.staticType as FunctionType;
    expect(type0.returnType, result.typeProvider.intType);
    expect(type0.normalParameterTypes[0], result.typeProvider.stringType);

    var anon1 =
        (statements[1] as ReturnStatement).expression as FunctionExpression;
    FunctionType type1 = anon1.declaredFragment!.element.type;
    expect(type1.returnType, result.typeProvider.intType);
    expect(type1.normalParameterTypes[0], result.typeProvider.intType);
  }

  test_functionLiteral_assignment_typedArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
        typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (int x) => null;
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                                             ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        Function2<int, String> l1 = (int x) => "hello";
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Function2<int, String> l2 = (String x) => "hello";
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                  ^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String Function(String)' can't be assigned to a variable of type 'Function2<int, String>'.
        Function2<int, String> l3 = (int x) => 3;
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                             ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        Function2<int, String> l4 = (int x) {return 3;};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                                  ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (x) => null;
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                                         ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        Function2<int, String> l1 = (x) => "hello";
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Function2<int, String> l2 = (x) => "hello";
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
        Function2<int, String> l3 = (x) => 3;
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                         ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        Function2<int, String> l4 = (x) {return 3;};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                              ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, List<String>> l0 = (int x) => ["hello"];
//                                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        Function2<int, List<String>> l1 = (String x) => ["hello"];
//                                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
//                                        ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<String> Function(String)' can't be assigned to a variable of type 'Function2<int, List<String>>'.
        Function2<int, List<String>> l2 = (int x) => [3];
//                                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                                    ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
        Function2<int, List<String>> l3 = (int x) {return [3];};
//                                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                                         ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
//                                     ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'F'.
      }

      void main () {
        (new Mapper<int, String>().map)((int x) => null);
//                                                 ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        (new Mapper<int, String>().map)((int x) => "hello");
        (new Mapper<int, String>().map)((String x) => "hello");
//                                      ^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String Function(String)' can't be assigned to the parameter type 'String Function(int)'.
        (new Mapper<int, String>().map)((int x) => 3);
//                                                 ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        (new Mapper<int, String>().map)((int x) {return 3;});
//                                                      ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
//                                     ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'F'.
      }

      void main () {
        (new Mapper<int, String>().map)((x) => null);
//                                             ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => 3);
//                                             ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        (new Mapper<int, String>().map)((x) {return 3;});
//                                                  ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      String map(String mapper(int x)) => mapper(null);
//                                               ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'int'.

      void main () {
        map((int x) => null);
//                     ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        map((int x) => "hello");
        map((String x) => "hello");
//          ^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String Function(String)' can't be assigned to the parameter type 'String Function(int)'.
        map((int x) => 3);
//                     ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        map((int x) {return 3;});
//                          ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      String map(String mapper(int x)) => mapper(null);
//                                               ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'int'.

      void main () {
        map((x) => null);
//                 ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        map((x) => "hello");
        map((x) => "hello");
        map((x) => 3);
//                 ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        map((x) {return 3;});
//                      ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
//                                     ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'F'.
      }

      void main () {
        new Mapper<int, String>().map((int x) => null);
//                                               ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        new Mapper<int, String>().map((int x) => "hello");
        new Mapper<int, String>().map((String x) => "hello");
//                                    ^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String Function(String)' can't be assigned to the parameter type 'String Function(int)'.
        new Mapper<int, String>().map((int x) => 3);
//                                               ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        new Mapper<int, String>().map((int x) {return 3;});
//                                                    ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
//                                     ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'F'.
      }

      void main () {
        new Mapper<int, String>().map((x) => null);
//                                           ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => 3);
//                                           ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        new Mapper<int, String>().map((x) {return 3;});
//                                                ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, int> l0 = (x) => x;
//                          ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        Function2<int, int> l1 = (x) => x+1;
//                          ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Function2<int, String> l2 = (x) => x;
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                         ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
        Function2<int, String> l3 = (x) => x.toLowerCase();
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                           ^^^^^^^^^^^
// [diag.undefinedMethod] The method 'toLowerCase' isn't defined for the type 'int'.
        Function2<String, String> l4 = (x) => x.toLowerCase();
//                                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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

    expect(functionReturnValue(0).staticType, result.typeProvider.intType);
    expect(functionReturnValue(1).staticType, result.typeProvider.intType);
    expect(functionReturnValue(2).staticType, result.typeProvider.intType);
    expect(functionReturnValue(3).staticType, InvalidTypeImpl.instance);
    expect(functionReturnValue(4).staticType, result.typeProvider.stringType);
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
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
//                                    ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'Future<T>'.
    Future<int> test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_downwards2() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
//                                    ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'Future<T>'.
    FutureOr<int> test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_downwards3() async {
    // Test that downwards inference correctly propagates into
    // arguments.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
//                                    ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'Future<T>'.
    Future<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].argumentExpression.staticType
          as InterfaceType,
    );
  }

  test_futureOr_downwards4() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
//                                    ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'Future<T>'.
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].argumentExpression.staticType
          as InterfaceType,
    );
  }

  test_futureOr_downwards5() async {
    // Test that downwards inference correctly pins the type when it
    // comes from a FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
//                                    ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'Future<T>'.
    FutureOr<num> test() => mk(new Future.value(42));
    ''');
    _isFutureOf([_isNum])(invoke.staticType as InterfaceType);
    _isFutureOf([_isNum])(
      invoke.argumentList.arguments[0].argumentExpression.staticType
          as InterfaceType,
    );
  }

  test_futureOr_downwards6() async {
    // Test that downwards inference doesn't decompose FutureOr
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T>(T x) => null;
//                  ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'T'.
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOrOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].argumentExpression.staticType
          as InterfaceType,
    );
  }

  test_futureOr_downwards7() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(r'''
      T mk<T extends Future<int>>(T x) => null;
//                                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'T'.
      FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].argumentExpression.staticType
          as InterfaceType,
    );
  }

  test_futureOr_downwards8() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    // TODO(leafp): I think this should pass once the inference changes
    // that jmesserly is adding are landed.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T extends Future<Object>>(T x) => null;
//                                         ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'T'.
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
    _isFutureOfInt(
      invoke.argumentList.arguments[0].argumentExpression.staticType
          as InterfaceType,
    );
  }

  test_futureOr_downwards9() async {
    // Test that downwards inference decomposes correctly with
    // other composite types
    MethodInvocation invoke = await _testFutureOr(r'''
    List<T> mk<T>(T x) => null;
//                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'List<T>'.
    FutureOr<List<int>> test() => mk(3);
    ''');
    _isListOf(_isInt)(invoke.staticType as InterfaceType);
    _isInt(invoke.argumentList.arguments[0].argumentExpression.typeOrThrow);
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
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.abs();
//                                     ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'FutureOr'.
    ''');
    _isInvalidType(invoke.typeOrThrow);
  }

  test_futureOr_methods3() async {
    // Test that FutureOr does not have the Future type methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.then((x) => x);
//                                     ^^^^
// [diag.undefinedMethod] The method 'then' isn't defined for the type 'FutureOr'.
    ''');
    _isInvalidType(invoke.typeOrThrow);
  }

  test_futureOr_methods4() async {
    // Test that FutureOr<dynamic> does not have all methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<dynamic> x) => x.abs();
//                                         ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'abs' can't be unconditionally invoked because the receiver can be 'null'.
    ''');
    _isInvalidType(invoke.typeOrThrow);
  }

  test_futureOr_no_return() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
//              ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
    test() => f.then((int x) {});
    ''');
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].argumentExpression.typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOr_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
//              ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
    test() => f.then((int x) {return;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].argumentExpression.typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOr_return_null() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
//              ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
    test() => f.then((int x) {return null;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].argumentExpression.typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOr_upwards1() async {
    // Test that upwards inference correctly prefers to instantiate type
    // variables with the "smaller" solution when both are possible.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
//                                    ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'Future<T>'.
    dynamic test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOr_upwards2() async {
    // Test that upwards inference fails when the solution doesn't
    // match the bound.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T extends Future<Object>>(FutureOr<T> x) => null;
//                                                   ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'mk' because it has a return type of 'T'.
    dynamic test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType as InterfaceType);
  }

  test_futureOrNull_no_return() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
//              ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
    test() => f.then<Null>((int x) {});
    ''');
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].argumentExpression.typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOrNull_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
//              ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
    test() => f.then<Null>((int x) {return;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].argumentExpression.typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_futureOrNull_return_null() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
//              ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
    test() => f.then<Null>((int x) { return null;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
      invoke.argumentList.arguments[0].argumentExpression.typeOrThrow,
    );
    _isFutureOfNull(invoke.staticType as InterfaceType);
  }

  test_generic_partial() async {
    // Test that upward and downward type inference handles partial
    // type schemas correctly.  Downwards inference in a partial context
    // (e.g. Map<String, ?>) should still allow upwards inference to fill
    // in the missing information.
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//      ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
    var a1 = new A.fromMap({'hello' : 3});
//      ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
    var a2 = new A.fromList([3]);
//      ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
    var a3 = new A.fromT(3);
//      ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
    var a4 = new A.fromB(new B(3));
//      ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
}
   ''');

    Element elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;
    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
        class C<T> {
          C(void callback(List<T> a));
        }
        test() {
          // downwards inference pushes List<?> and in parameter position this
          // becomes inferred as List<Null>.
          var c = new C((items) {});
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
        }
        ''');

    DartType cType = result.findElement.localVar('c').type;
    Element elementC = AstFinder.getClass(
      result.unit,
      "C",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementC))([_isType])(cType);
  }

  test_inference_error_arguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(F<T, T> f) => (x) => f(f(x));

test() {
  var h = g((int x) => 42.0);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//        ^
// [diag.couldNotInfer] Couldn't infer type parameter 'T'.\n\nTried to infer 'double' for 'T' which doesn't work:\n  Parameter 'f' declared as     'T Function(T)'\n                but argument is 'double Function(int)'.\n\nConsider passing explicit type argument(s) to the generic.
//          ^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'double Function(int)' can't be assigned to the parameter type 'F<double, double>'.
}
 ''');
    _expectInferenceError(result, r'''
Couldn't infer type parameter 'T'.

Tried to infer 'double' for 'T' which doesn't work:
  Parameter 'f' declared as     'T Function(T)'
                but argument is 'double Function(int)'.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_arguments2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(F<T, T> a, F<T, T> b) => (x) => a(b(x));

test() {
  var h = g((int x) => 42.0, (double x) => 42);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//        ^
// [diag.couldNotInfer] Couldn't infer type parameter 'T'.\n\nTried to infer 'num' for 'T' which doesn't work:\n  Parameter 'a' declared as     'T Function(T)'\n                but argument is 'double Function(int)'.\n  Parameter 'b' declared as     'T Function(T)'\n                but argument is 'int Function(double)'.\n\nConsider passing explicit type argument(s) to the generic.
//          ^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'double Function(int)' can't be assigned to the parameter type 'F<num, num>'.
//                           ^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'int Function(double)' can't be assigned to the parameter type 'F<num, num>'.
}
 ''');
    _expectInferenceError(result, r'''
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
    var result = await resolveTestCodeWithDiagnostics(r'''
T max<T extends num>(T x, T y) => x;

test() {
  String hello = max(1, 2);
//       ^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'hello' isn't used.
//                   ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'Never'.
//                      ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'Never'.
}
 ''');

    var node = result.findNode.singleMethodInvocation;
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::max::@formalParameter::x
          substitution: {T: Never}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    await resolveTestCodeWithDiagnostics(r'''
typedef R F<T, R>(T t);
F<T, T> g<T extends num>() => (y) => y;

test() {
  F<String, String> hello = g();
//                  ^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'hello' isn't used.
//                          ^^^
// [diag.invalidAssignment] A value of type 'F<num, num>' can't be assigned to a variable of type 'F<String, String>'.
}
 ''');
  }

  test_inference_error_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
T max<T extends num>(T x, T y) => x < y ? y : x;
abstract class Iterable<T> {
  T get first;
  S fold<S>(S s, S f(S s, T t));
}
test(Iterable values) {
  num n = values.fold(values.first as num, max);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'n' isn't used.
//                                         ^^^
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'num Function(num, dynamic)'.
}
 ''');
  }

  test_inference_error_returnContext() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(T t) => (x) => t;

test() {
  F<num, int> h = g(42);
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//                ^
// [diag.couldNotInfer] Couldn't infer type parameter 'T'.\n\nTried to infer 'num' for 'T' which doesn't work:\n  Return type declared as 'T Function(T)'\n              used where  'int Function(num)' is required.\n\nConsider passing explicit type argument(s) to the generic.
//                ^^^^^
// [diag.invalidAssignment] A value of type 'F<num, num>' can't be assigned to a variable of type 'F<num, int>'.
}
 ''');
    _expectInferenceError(result, r'''
Couldn't infer type parameter 'T'.

Tried to infer 'num' for 'T' which doesn't work:
  Return type declared as 'T Function(T)'
              used where  'int Function(num)' is required.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_hints() async {
    await resolveTestCodeWithDiagnostics(r'''
      void main () {
        var x = 3;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
        List<int> l0 = [];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
     }
   ''');
  }

  test_inference_simplePolymorphicRecursion_function() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with a function type
    var result = await resolveTestCodeWithDiagnostics(r'''
void _mergeSort<T>(T Function(T) list, int compare(T a, T b), T Function(T) target) {
//   ^^^^^^^^^^
// [diag.unusedElement] The declaration '_mergeSort' isn't referenced.
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''');

    var node = result.findNode.singleBlock;
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T Function(T)
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void _mergeSort<T>(List<T> list, int compare(T a, T b), List<T> target) {
//   ^^^^^^^^^^
// [diag.unusedElement] The declaration '_mergeSort' isn't referenced.
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''');

    var node = result.findNode.singleBlock;
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: List<T>
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void _mergeSort<T>(T list, int compare(T a, T b), T target) {
//   ^^^^^^^^^^
// [diag.unusedElement] The declaration '_mergeSort' isn't referenced.
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''');

    var node = result.findNode.singleBlock;
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::list
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: target
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::list
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::target
              staticType: T
            SimpleIdentifier
              token: compare
              correspondingParameter: SubstitutedFormalParameterElementImpl
                baseElement: <testLibrary>::@function::_mergeSort::@formalParameter::compare
                substitution: {T: T}
              element: <testLibrary>::@function::_mergeSort::@formalParameter::compare
              staticType: int Function(T, T)
            SimpleIdentifier
              token: list
              correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>(T x(T t)) => x(null);
//                    ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'T'.
S g<S>(S s) => s;
test() {
 var h = f(g);
//   ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
}
    ''');

    var node = result.findNode.methodInvocation('f(g)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
T max<T extends num>(T x, T y) => x < y ? y : x;
abstract class Iterable<T> {
  T get first;
  S fold<S>(S s, S f(S s, T t));
}
num test(Iterable values) => values.fold(values.first as num, max);
//                                                            ^^^
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'num Function(num, dynamic)'.
    ''');

    var node = result.findNode.methodInvocation('values.fold');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: values
    element: <testLibrary>::@function::test::@formalParameter::values
    staticType: Iterable<dynamic>
  operator: .
  methodName: SimpleIdentifier
    token: fold
    element: SubstitutedMethodElementImpl
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
            element: SubstitutedGetterElementImpl
              baseElement: <testLibrary>::@class::Iterable::@getter::first
              substitution: {T: dynamic}
            staticType: dynamic
          element: SubstitutedGetterElementImpl
            baseElement: <testLibrary>::@class::Iterable::@getter::first
            substitution: {T: dynamic}
          staticType: dynamic
        asOperator: as
        type: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: s@null
          substitution: {S: num}
        staticType: num
      FunctionReference
        function: SimpleIdentifier
          token: max
          element: <testLibrary>::@function::max
          staticType: T Function<T extends num>(T, T)
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertMapOfIntToListOfInt = _isMapOf(
      _isInt,
      (DartType type) => assertListOfInt(type as InterfaceType),
    );

    VariableDeclaration mapB = AstFinder.getFieldInClass(
      result.unit,
      "B",
      "map",
    );
    MethodDeclaration mapC = AstFinder.getMethodInClass(
      result.unit,
      "C",
      "map",
    );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//                     ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'C<S>'.
      }

      class F<S, T> extends A<S, T> {
        F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
//                           ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                                      ^
// [diag.missingDefaultValueForParameter] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
        F.named(S x, T y, [S a, T b]) : super(a, b);
//                           ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                                ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
      }

      void test0() {
        A<int, String> a0 = new A(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
        A<int, String> a1 = new A.named(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
        A<int, String> a2 = new A<int, String>(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
        A<int, String> a3 = new A<int, String>.named(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
        A<int, String> a4 = new A<int, dynamic>(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'A<int, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
        A<int, String> a5 = new A<dynamic, dynamic>.named(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'A<dynamic, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
      }
      void test1()  {
        A<int, String> a0 = new A("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                                ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                                         ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
        A<int, String> a1 = new A.named("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                      ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                                               ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
      }
      void test2() {
        A<int, String> a0 = new B("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
        A<int, String> a1 = new B.named("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
        A<int, String> a2 = new B<String, int>("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
        A<int, String> a3 = new B<String, int>.named("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
        A<int, String> a4 = new B<String, dynamic>("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'B<String, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
        A<int, String> a5 = new B<dynamic, dynamic>.named("hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'B<dynamic, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
      }
      void test3() {
        A<int, String> a0 = new B(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                                ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
//                                   ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
        A<int, String> a1 = new B.named(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                      ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
//                                         ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
      }
      void test4() {
        A<int, int> a0 = new C(3);
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
        A<int, int> a1 = new C.named(3);
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
        A<int, int> a2 = new C<int>(3);
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
        A<int, int> a3 = new C<int>.named(3);
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
        A<int, int> a4 = new C<dynamic>(3);
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                       ^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'C<dynamic>' can't be assigned to a variable of type 'A<int, int>'.
        A<int, int> a5 = new C<dynamic>.named(3);
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                       ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'C<dynamic>' can't be assigned to a variable of type 'A<int, int>'.
      }
      void test5() {
        A<int, int> a0 = new C("hello");
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                             ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
        A<int, int> a1 = new C.named("hello");
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                   ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
      }
      void test6()  {
        A<int, String> a0 = new D("hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
        A<int, String> a1 = new D.named("hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
        A<int, String> a2 = new D<int, String>("hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
        A<int, String> a3 = new D<String, String>.named("hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
        A<int, String> a4 = new D<num, dynamic>("hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'D<num, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
        A<int, String> a5 = new D<dynamic, dynamic>.named("hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'D<dynamic, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
      }
      void test7() {
        A<int, String> a0 = new D(3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                                ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
        A<int, String> a1 = new D.named(3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                      ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
      }
      void test8() {
        A<C<int>, String> a0 = new E("hello");
//                        ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
      }
      void test9() { // Check named and optional arguments
        A<int, String> a0 = new F(3, "hello", a: [3], b: ["hello"]);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
        A<int, String> a1 = new F(3, "hello", a: ["hello"], b:[3]);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                                ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
//                                                             ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
        A<int, String> a2 = new F.named(3, "hello", 3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
        A<int, String> a3 = new F.named(3, "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
        A<int, String> a4 = new F.named(3, "hello", "hello", 3);
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                                                  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                                                           ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
        A<int, String> a5 = new F.named(3, "hello", "hello");
//                     ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                                                  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
      }''');

    Expression rhs(AstNode stmt) {
      stmt as VariableDeclarationStatement;
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression exp = decl.initializer!;
      return exp;
    }

    void hasType(Asserter<DartType> assertion, Expression exp) =>
        assertion(exp.typeOrThrow);

    Element elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;
    Element elementB = AstFinder.getClass(
      result.unit,
      "B",
    ).declaredFragment!.element;
    Element elementC = AstFinder.getClass(
      result.unit,
      "C",
    ).declaredFragment!.element;
    Element elementD = AstFinder.getClass(
      result.unit,
      "D",
    ).declaredFragment!.element;
    Element elementE = AstFinder.getClass(
      result.unit,
      "E",
    ).declaredFragment!.element;
    Element elementF = AstFinder.getClass(
      result.unit,
      "F",
    ).declaredFragment!.element;

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
        result.unit,
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
        result.unit,
        "test1",
      ).cast<VariableDeclarationStatement>();
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        result.unit,
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
        result.unit,
        "test3",
      ).cast<VariableDeclarationStatement>();
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        result.unit,
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
        result.unit,
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
        result.unit,
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
        result.unit,
        "test7",
      ).cast<VariableDeclarationStatement>();
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        result.unit,
        "test8",
      ).cast<VariableDeclarationStatement>();
      hasType(assertEOf([_isInt, _isString]), rhs(statements[0]));
    }

    {
      List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
        result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        List<List<int>> l0 = [[]];
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        Iterable<List<int>> l1 = [[3]];
//                          ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Iterable<List<int>> l2 = [[3], [4]];
//                          ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
        List<List<int>> l3 = [["hello", 3], []];
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                             ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        List<int> l0 = [];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        List<int> l1 = [3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        List<int> l2 = ["hello"];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                      ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
        List<int> l3 = ["hello", 3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                      ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        const List<int> c0 = const [];
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'c0' isn't used.
        const List<int> c1 = const [3];
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'c1' isn't used.
        const List<int> c2 = const ["hello"];
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'c2' isn't used.
//                                  ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
        const List<int> c3 = const ["hello", 3];
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'c3' isn't used.
//                                  ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        List<int> l0 = <num>[];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                     ^^^^^^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
        List<int> l1 = <num>[3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
//                     ^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
        List<int> l2 = <String>["hello"];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                     ^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<String>' can't be assigned to a variable of type 'List<int>'.
        List<int> l3 = <dynamic>["hello", 3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                     ^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<dynamic>' can't be assigned to a variable of type 'List<int>'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        Iterable<int> l0 = [];
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        Iterable<int> l1 = [3];
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Iterable<int> l2 = ["hello"];
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                          ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
        Iterable<int> l3 = ["hello", 3];
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                          ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        Map<int, List<String>> l0 = {};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        Map<int, List<String>> l1 = {3: ["hello"]};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Map<int, List<String>> l2 = {"hello": ["hello"]};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                   ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
        Map<int, List<String>> l3 = {3: [3]};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                       ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
        Map<int, List<String>> l4 = {3:["hello"], "hello": [3]};
//                             ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                                ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
//                                                          ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        Map<int, String> l0 = {};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
        Map<int, String> l1 = {3: "hello"};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
        Map<int, String> l2 = {"hello": "hello"};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                             ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
        Map<int, String> l3 = {3: 3};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
        Map<int, String> l4 = {3:"hello", "hello": 3};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                        ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
//                                                 ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      void main () {
        Map<int, String> l0 = <int, dynamic>{};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                            ^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<int, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
        Map<int, String> l1 = <int, dynamic>{3: "hello"};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<int, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
        Map<int, String> l2 = <int, dynamic>{"hello": "hello"};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<int, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
//                                           ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
        Map<int, String> l3 = <int, dynamic>{3: 3};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                            ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<int, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
     }
   ''');

    List<Statement> statements = AstFinder.getStatementsInTopLevelFunction(
      result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
      class A {
        List<String> m0(int x) => ["hello"];
        List<String> m1(int x) {return [3];}
//                                      ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
      }
   ''');

    Expression methodReturnValue(String methodName) {
      MethodDeclaration method = AstFinder.getMethodInClass(
        result.unit,
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    S f<S, T>(Func1<S, T> g) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'S'.
    String test() => f((l) => l.length);
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, String> test() => new B(3);
//                                 ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'Never'.
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(
      result.unit,
      "B",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isNever])(type);
  }

  test_pinning_multipleConstraints2() async {
    // Test that downwards inference with two identical downwards covariant
    // constraints on the same parameter correctly infers and pins the type
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> { B(S s); }
    A<num, num> test() => new B(3);
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(
      result.unit,
      "B",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isNum])(type);
  }

  test_pinning_multipleConstraints3() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype, but do share a common supertype
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, double> test() => new B(3);
//                                 ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'Never'.
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(
      result.unit,
      "B",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isNever])(type);
  }

  test_pinning_multipleConstraints4() async {
    // Test that downwards inference with two subtype related downwards
    // covariant constraints on the same parameter correctly infers and pins
    // the type
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> {}
    A<int, num> test() => new B();
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    DartType type = body.expression.typeOrThrow;

    Element elementB = AstFinder.getClass(
      result.unit,
      "B",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementB))([_isInt])(type);
  }

  test_pinning_multipleConstraints_contravariant1() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter chooses the upper bound
    // when the only supertype is Object
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, String>> test() => mkA();
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isObject, _isObject])(type);
  }

  test_pinning_multipleConstraints_contravariant2() async {
    // Test that downwards inference with two identical downwards contravariant
    // constraints on the same parameter correctly pins the type
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<num, num>> test() => mkA();
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant3() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when they share a common supertype
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, double>> test() => mkA();
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant4() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when one is a subtype of the other
    var result = await resolveTestCodeWithDiagnostics(r'''
    class A<S, T> {
      S s;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 's' must be initialized.
      T t;
//      ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 't' must be initialized.
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, num>> test() => mkA();
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(
      result.unit,
      "A",
    ).declaredFragment!.element;

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
    var result = await resolveTestCodeWithDiagnostics(code);

    var b = result.unit.declarations[1] as ClassDeclaration;
    var classBody = b.body as BlockClassBody;
    var bConstructor = classBody.members[0] as ConstructorDeclaration;
    var redirected = bConstructor.redirectedConstructor as ConstructorName;

    var typeName = redirected.type;
    assertType(typeName.type, 'A<T2, U2>');
    assertType(typeName.type, 'A<T2, U2>');

    var constructorMember = redirected.element!;
    expect(constructorMember.displayString(), 'A<T2, U2>.named()');
    expect(redirected.name!.element, constructorMember);
  }

  test_redirectedConstructor_self() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A();
  factory A.redirected() = A;
}
''');
  }

  test_redirectedConstructor_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> implements B<T, U> {
  A();
}

class B<T2, U2> {
  factory B() = A;
}
''');

    var b = result.unit.declarations[1] as ClassDeclaration;
    var classBody = b.body as BlockClassBody;
    var bConstructor = classBody.members[0] as ConstructorDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(code);

    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      result.unit,
      "A",
      null,
    );
    var invocation =
        constructor.initializers[0] as RedirectingConstructorInvocation;
    var exp = invocation.argumentList.arguments[0].argumentExpression;
    _isListOf(_isString)(exp.staticType as InterfaceType);
  }

  test_returnType_variance1() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a contravariant position
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
//                                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'Func1<T, String>'.
    Func1<num, String> test() => f(42);
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var invoke = body.expression as MethodInvocation;
    _isFunction2Of(_isNum, _isFunction2Of(_isNum, _isString))(
      invoke.staticInvokeType!,
    );
  }

  test_returnType_variance2() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a covariant position
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
//                                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'Func1<String, T>'.
    Func1<String, num> test() => f(42);
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x, g(T x)) => null;
//                                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'Func1<T, String>'.
    dynamic test() => f(42, (num x) => x);
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.normalParameterTypes[0];
    _isInt(type);
  }

  test_returnType_variance4() async {
    // Check that the variance heuristic chooses the more precise type
    // when the return type uses the variable in a covariant position
    // and there is no downwards constraint
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x, g(T x)) => null;
//                                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'Func1<String, T>'.
    dynamic test() => f(42, (num x) => x);
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    var functionType = body.expression.staticType as FunctionType;
    DartType type = functionType.returnType;
    _isInt(type);
  }

  test_returnType_variance5() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a contravariant position
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
//                                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'Func1<T, String>'.
    T g<T, S>(Func1<T, S> f) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'T'.
    num test() => g(f(3));
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
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
    var result = await resolveTestCodeWithDiagnostics(r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
//                                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'Func1<String, T>'.
    T g<T, S>(Func1<S, T> f) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'T'.
    num test() => g(f(3));
   ''');

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
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
    var result = await resolveTestCodeWithDiagnostics(code);

    ConstructorDeclaration constructor = AstFinder.getConstructorInClass(
      result.unit,
      "A",
      null,
    );
    var invocation = constructor.initializers[0] as SuperConstructorInvocation;
    var exp = invocation.argumentList.arguments[0].argumentExpression;
    _isListOf(_isString)(exp.staticType as InterfaceType);
  }

  /// Verifies the result has a `could_not_infer` diagnostic with
  /// the expected [errorMessage].
  void _expectInferenceError(
    TestResolvedUnitResult result,
    String errorMessage,
  ) {
    var errors = result.diagnostics
        .where((e) => e.diagnosticCode.lowerCaseUniqueName == 'could_not_infer')
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

  void _initAssertions(TypeProvider typeProvider) {
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
  }

  /// Helper method for testing `FutureOr<T>`.
  ///
  /// Validates that [code] defines a function "test", whose body is an
  /// expression that invokes a method. Returns that invocation.
  Future<MethodInvocation> _testFutureOr(String code) async {
    var fullCode =
        """
import "dart:async";

$code
""";
    var result = await resolveTestCodeWithDiagnostics(fullCode);

    FunctionDeclaration test = AstFinder.getTopLevelFunction(
      result.unit,
      "test",
    );
    var body = test.functionExpression.body as ExpressionFunctionBody;
    return body.expression as MethodInvocation;
  }
}

@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test extends StaticTypeAnalyzer2TestShared {
  test_dynamicObjectGetter_hashCode() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  dynamic a = null;
  var foo = a.hashCode;
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'int');
  }

  test_futureOr_promotion1() async {
    // Test that promotion from FutureOr<T> to T works for concrete types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is int) && (x.abs() == 0);
   ''';
    await resolveTestCodeWithDiagnostics(code);
  }

  test_futureOr_promotion2() async {
    // Test that promotion from FutureOr<T> to Future<T> works for concrete
    // types
    await resolveTestCodeWithDiagnostics(r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is Future<int>) &&
                                     (x.then((x) => x) == null);
//                                                     ^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullFalse] The operand can't be 'null', so the condition is always 'false'.
   ''');
  }

  test_futureOr_promotion3() async {
    // Test that promotion from FutureOr<T> to T works for type
    // parameters T
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is T) &&
                                                  (x.abs() == 0);
   ''';
    await resolveTestCodeWithDiagnostics(code);
  }

  test_futureOr_promotion4() async {
    // Test that promotion from FutureOr<T> to Future<T> works for type
    // parameters T
    await resolveTestCodeWithDiagnostics(r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is Future<T>) &&
                                                  (x.then((x) => x) == null);
//                                                                  ^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullFalse] The operand can't be 'null', so the condition is always 'false'.
   ''');
  }

  test_generalizedVoid_assignToVoidOk() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  void x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = 42;
}
''');
  }

  test_genericFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>(T x) => null;
//             ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
''');

    var node = result.findNode.functionDeclaration('f<T>');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: T
    element: #E0 T
    type: T
  name: f
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@4
            defaultType: dynamic
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: T
          element: #E0 T
          type: T
        name: x
        declaredFragment: <testLibraryFragment> x@9
          element: isPublic
            type: T
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: NullLiteral
        literal: null
        staticType: Null
      semicolon: ;
    declaredFragment: <testLibraryFragment> f@2
      element: <testLibrary>::@function::f
        type: T Function<T>(T)
    staticType: T Function<T>(T)
  declaredFragment: <testLibraryFragment> f@2
    element: <testLibrary>::@function::f
      type: T Function<T>(T)
''');
  }

  test_genericFunction_bounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T extends num>(T x) => null;
//                         ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
''');

    var node = result.findNode.functionDeclaration('f<T');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: T
    element: #E0 T
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
            element: dart:core::@class::num
            type: num
          declaredFragment: <testLibraryFragment> T@4
            defaultType: num
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: T
          element: #E0 T
          type: T
        name: x
        declaredFragment: <testLibraryFragment> x@21
          element: isPublic
            type: T
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: NullLiteral
        literal: null
        staticType: Null
      semicolon: ;
    declaredFragment: <testLibraryFragment> f@2
      element: <testLibrary>::@function::f
        type: T Function<T extends num>(T)
    staticType: T Function<T extends num>(T)
  declaredFragment: <testLibraryFragment> f@2
    element: <testLibrary>::@function::f
      type: T Function<T extends num>(T)
''');
  }

  test_genericFunction_parameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void g(T f<T>(T x)) {}
''');

    var fType = result.findElement.parameter('f').type;
    fType as FunctionType;
    assertType(fType, 'T Function<T>(T)');
  }

  test_genericFunction_static() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  static T f<T>(T x) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
''');

    var node = result.findNode.methodDeclaration('f<T>');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: T
    element: #E0 T
    type: T
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@26
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: T
        element: #E0 T
        type: T
      name: x
      declaredFragment: <testLibraryFragment> x@31
        element: isPublic
          type: T
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
      staticType: Null
    semicolon: ;
  declaredFragment: <testLibraryFragment> f@24
    element: <testLibrary>::@class::C::@method::f
      type: T Function<T>(T)
''');
  }

  test_genericFunction_typedef() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef T F<T>(T x);
F f0;
//^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f0' must be initialized.

class C {
  static F f1;
//         ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f1' must be initialized.
  F f2;
//  ^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'f2' must be initialized.
  void g(F f3) { // C
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f4' must be assigned before it can be used.
  }
}

class D<S> {
  static F f1;
//         ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f1' must be initialized.
  F f2;
//  ^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'f2' must be initialized.
  void g(F f3) { // D
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f4' must be assigned before it can be used.
  }
}
''');

    checkBody(String className) {
      var statements = result.findNode.block('{ // $className').statements;

      for (int i = 1; i <= 5; i++) {
        Expression exp = (statements[i] as ExpressionStatement).expression;
        expect(exp.staticType, result.typeProvider.dynamicType);
      }
    }

    checkBody("C");
    checkBody("D");
  }

  test_genericFunction_upwardsAndDownwards() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27586.
    var result = await resolveTestCodeWithDiagnostics(r'List<num> x = [1, 2];');
    expectInitializerType(result, 'x =', 'List<num>');
  }

  test_genericFunction_upwardsAndDownwards_Object() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27625.
    var result = await resolveTestCodeWithDiagnostics(r'''
List<Object> aaa = [];
List<Object> bbb = [1, 2, 3];
List<Object> ccc = [null];
//                  ^^^^
// [diag.listElementTypeNotAssignableNullability] The element type 'Null' can't be assigned to the list type 'Object'.
List<Object> ddd = [1 as dynamic];
List<Object> eee = [new Object()];
''');
    expectInitializerType(result, 'aaa =', 'List<Object>');
    expectInitializerType(result, 'bbb =', 'List<Object>');
    expectInitializerType(result, 'ccc =', 'List<Object>');
    expectInitializerType(result, 'ddd =', 'List<Object>');
    expectInitializerType(result, 'eee =', 'List<Object>');
  }

  test_genericMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  List<T> f<T>(E e) => null;
//                     ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'List<T>'.
}
main() {
  C<String> cOfString;
//          ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'cOfString' isn't used.
}
''');
    assertType(result.findElement.method('f').type, 'List<T> Function<T>(E)');

    var cOfString = result.findElement.localVar('cOfString');
    var ft = result.inheritanceManager
        .getMember3(cOfString.type as InterfaceType, Name(null, 'f'))!
        .type;
    assertType(ft, 'List<T> Function<T>(String)');
    assertType(
      ft.instantiate([result.typeProvider.intType]),
      'List<int> Function(String)',
    );
  }

  test_genericMethod_explicitTypeParams() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  List<T> f<T>(E e) => null;
//                     ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'List<T>'.
}
main() {
  C<String> cOfString;
  var x = cOfString.f<int>('hi');
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//        ^^^^^^^^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'cOfString' must be assigned before it can be used.
}
''');
    var f = result.findNode.simple('f<int>').parent as MethodInvocation;
    var ft = f.staticInvokeType as FunctionType;
    assertType(ft, 'List<int> Function(String)');

    var x = result.findElement.localVar('x');
    expect(x.type, result.typeProvider.listType(result.typeProvider.intType));
  }

  test_genericMethod_functionExpressionInvocation_explicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  T f<T>(T e) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static T Function<T>(T) h = null;
//                            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T Function<T>(T)'.
}

T topF<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'topF' because it has a return type of 'T'.
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'lf' because it has a return type of 'T'.

  var lambdaCall = (<E>(E e) => e)<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'lambdaCall' isn't used.
  var methodCall = (c.f)<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'methodCall' isn't used.
  var staticCall = (C.g)<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticCall' isn't used.
  var staticFieldCall = (C.h)<int>(3);
//    ^^^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticFieldCall' isn't used.
  var topFunCall = (topF)<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFunCall' isn't used.
  var topFieldCall = (topG)<int>(3);
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFieldCall' isn't used.
  var localCall = (lf)<int>(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'localCall' isn't used.
  var paramCall = (pf)<int>(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'lambdaCall', "int");
    _assertLocalVarType(result, 'methodCall', "int");
    _assertLocalVarType(result, 'staticCall', "int");
    _assertLocalVarType(result, 'staticFieldCall', "int");
    _assertLocalVarType(result, 'topFunCall', "int");
    _assertLocalVarType(result, 'topFieldCall', "int");
    _assertLocalVarType(result, 'localCall', "int");
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = (pf)<int>(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = (pf)(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_inferred() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  T f<T>(T e) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static T Function<T>(T) h = null;
//                            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T Function<T>(T)'.
}

T topF<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'topF' because it has a return type of 'T'.
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'lf' because it has a return type of 'T'.

  var lambdaCall = (<E>(E e) => e)(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'lambdaCall' isn't used.
  var methodCall = (c.f)(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'methodCall' isn't used.
  var staticCall = (C.g)(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticCall' isn't used.
  var staticFieldCall = (C.h)(3);
//    ^^^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticFieldCall' isn't used.
  var topFunCall = (topF)(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFunCall' isn't used.
  var topFieldCall = (topG)(3);
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFieldCall' isn't used.
  var localCall = (lf)(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'localCall' isn't used.
  var paramCall = (pf)(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'lambdaCall', "int");
    _assertLocalVarType(result, 'methodCall', "int");
    _assertLocalVarType(result, 'staticCall', "int");
    _assertLocalVarType(result, 'staticFieldCall', "int");
    _assertLocalVarType(result, 'topFunCall', "int");
    _assertLocalVarType(result, 'topFieldCall', "int");
    _assertLocalVarType(result, 'localCall', "int");
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionInvocation_explicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  T f<T>(T e) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static T Function<T>(T) h = null;
//                            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T Function<T>(T)'.
}

T topF<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'topF' because it has a return type of 'T'.
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'lf' because it has a return type of 'T'.
  var methodCall = c.f<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'methodCall' isn't used.
  var staticCall = C.g<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticCall' isn't used.
  var staticFieldCall = C.h<int>(3);
//    ^^^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticFieldCall' isn't used.
  var topFunCall = topF<int>(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFunCall' isn't used.
  var topFieldCall = topG<int>(3);
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFieldCall' isn't used.
  var localCall = lf<int>(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'localCall' isn't used.
  var paramCall = pf<int>(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'methodCall', "int");
    _assertLocalVarType(result, 'staticCall', "int");
    _assertLocalVarType(result, 'staticFieldCall', "int");
    _assertLocalVarType(result, 'topFunCall', "int");
    _assertLocalVarType(result, 'topFieldCall', "int");
    _assertLocalVarType(result, 'localCall', "int");
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionInvocation_functionTypedParameter_explicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = pf<int>(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionInvocation_functionTypedParameter_inferred() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = pf(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionInvocation_inferred() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  T f<T>(T e) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static T Function<T>(T) h = null;
//                            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T Function<T>(T)'.
}

T topF<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'topF' because it has a return type of 'T'.
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'lf' because it has a return type of 'T'.
  var methodCall = c.f(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'methodCall' isn't used.
  var staticCall = C.g(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticCall' isn't used.
  var staticFieldCall = C.h(3);
//    ^^^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticFieldCall' isn't used.
  var topFunCall = topF(3);
//    ^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFunCall' isn't used.
  var topFieldCall = topG(3);
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFieldCall' isn't used.
  var localCall = lf(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'localCall' isn't used.
  var paramCall = pf(3);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramCall' isn't used.
}
''');
    _assertLocalVarType(result, 'methodCall', "int");
    _assertLocalVarType(result, 'staticCall', "int");
    _assertLocalVarType(result, 'staticFieldCall', "int");
    _assertLocalVarType(result, 'topFunCall', "int");
    _assertLocalVarType(result, 'topFieldCall', "int");
    _assertLocalVarType(result, 'localCall', "int");
    _assertLocalVarType(result, 'paramCall', "int");
  }

  test_genericMethod_functionTypedParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  List<T> f<T>(T f(E e)) => null;
//                          ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'List<T>'.
}
main() {
  C<String> cOfString;
//          ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'cOfString' isn't used.
}
''');
    assertType(
      result.findElement.method('f').type,
      'List<T> Function<T>(T Function(E))',
    );

    var cOfString = result.findElement.localVar('cOfString');
    var ft = result.inheritanceManager
        .getMember3(cOfString.type as InterfaceType, Name(null, 'f'))!
        .type;
    assertType(ft, 'List<T> Function<T>(T Function(String))');
    assertType(
      ft.instantiate([result.typeProvider.intType]),
      'List<int> Function(int Function(String))',
    );
  }

  test_genericMethod_functionTypedParameter_tearoff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void test<S>(T pf<T>(T e)) {
  var paramTearOff = pf;
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramTearOff' isn't used.
}
''');
    _assertLocalVarType(result, 'paramTearOff', "T Function<T>(T)");
  }

  test_genericMethod_implicitDynamic() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25100#issuecomment-162047588
    // These should not cause any hints or warnings.
    var result = await resolveTestCodeWithDiagnostics(r'''
class List<E> {
  T map<T>(T f(E e)) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'map' because it has a return type of 'T'.
}
void foo() {
  List list = null;
//            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'List<dynamic>'.
  list.map((e) => e);
  list.map((e) => 3);
}''');

    var node1 = result.findNode.methodInvocation('map((e) => e);');
    assertResolvedNodeText(node1, r'''
MethodInvocation
  target: SimpleIdentifier
    token: list
    element: list@68
    staticType: List<dynamic>
  operator: .
  methodName: SimpleIdentifier
    token: map
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::List::@method::map
      substitution: {E: dynamic, T: T}
    staticType: T Function<T>(T Function(dynamic))
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: e
            declaredFragment: <testLibraryFragment> e@93
              element: hasImplicitType isPublic
                type: dynamic
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SimpleIdentifier
            token: e
            element: e@93
            staticType: dynamic
        declaredFragment: <testLibraryFragment> null@null
          element: null@null
            type: dynamic Function(dynamic)
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: f@null
          substitution: {T: dynamic}
        staticType: dynamic Function(dynamic)
    rightParenthesis: )
  staticInvokeType: dynamic Function(dynamic Function(dynamic))
  staticType: dynamic
  typeArgumentTypes
    dynamic
''');

    var node2 = result.findNode.methodInvocation('map((e) => 3);');
    assertResolvedNodeText(node2, r'''
MethodInvocation
  target: SimpleIdentifier
    token: list
    element: list@68
    staticType: List<dynamic>
  operator: .
  methodName: SimpleIdentifier
    token: map
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::List::@method::map
      substitution: {E: dynamic, T: T}
    staticType: T Function<T>(T Function(dynamic))
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: e
            declaredFragment: <testLibraryFragment> e@115
              element: hasImplicitType isPublic
                type: dynamic
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 3
            staticType: int
        declaredFragment: <testLibraryFragment> null@null
          element: null@null
            type: int Function(dynamic)
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2.0);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'double');
  }

  test_genericMethod_max_doubleDouble_prefixed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;
main() {
  var foo = math.max(1.0, 2.0);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'double');
  }

  test_genericMethod_max_doubleInt() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'num');
  }

  test_genericMethod_max_intDouble() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math';
main() {
  var foo = max(1, 2.0);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'num');
  }

  test_genericMethod_max_intInt() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math';
main() {
  var foo = max(1, 2);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'int');
  }

  test_genericMethod_nestedBound() async {
    // Just validate that there is no warning on the call to `.abs()`.
    await resolveTestCodeWithDiagnostics(r'''
class Foo<T extends num> {
  void method<U extends T>(U u) {
    u.abs();
  }
}
''');
  }

  test_genericMethod_nestedCapture() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T f<S>(S x) {
    new C<S>().f<int>(3);
    new C<S>().f; // tear-off
    return null;
//         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  }
}
''');

    var node1 = result.findNode.methodInvocation('f<int>(3);');
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
              element: #E0 S
              type: S
          rightBracket: >
        element: <testLibrary>::@class::C
        type: C<S>
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::C::@constructor::new
        substitution: {T: S}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C<S>
  operator: .
  methodName: SimpleIdentifier
    token: f
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::C::@method::f
      substitution: {T: S, S: S}
    staticType: S Function<S₀>(S₀)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T f<S extends T>(S x) {
    new C<S>().f<int>(3);
//               ^^^
// [diag.typeArgumentNotMatchingBounds] 'int' doesn't conform to the bound 'S' of the type parameter 'S'.
    new C<S>().f; // tear-off
    return null;
//         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  }
}
''');

    var node1 = result.findNode.methodInvocation('f<int>(3);');
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
              element: #E0 S
              type: S
          rightBracket: >
        element: <testLibrary>::@class::C
        type: C<S>
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::C::@constructor::new
        substitution: {T: S}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C<S>
  operator: .
  methodName: SimpleIdentifier
    token: f
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::C::@method::f
      substitution: {T: S, S: S}
    staticType: S Function<S₀ extends S>(S₀)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: x@null
          substitution: {S: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: S Function(int)
  staticType: S
  typeArgumentTypes
    int
''');

    var node2 = result.findNode.simple('f;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: f
  element: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::C::@method::f
    substitution: {T: S, S: S}
  staticType: S Function<S₀ extends S>(S₀)
''');
  }

  test_genericMethod_nestedFunctions() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
S f<S>(S x) {
  g<S>(S x) => f;
//^
// [diag.unusedElement] The declaration 'g' isn't referenced.
  return null;
//       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'S'.
}
''');
    assertType(result.findElement.topFunction('f').type, 'S Function<S>(S)');
    assertType(
      result.findElement.localFunction('g').type,
      'S Function<S>(S) Function<S₀>(S₀)',
    );
  }

  test_genericMethod_override() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  T f<T>(T x) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
class D extends C {
  T f<T>(T y) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
''');

    var node = result.findNode.methodDeclaration('f<T>(T y)');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: T
    element: #E0 T
    type: T
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@61
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: T
        element: #E0 T
        type: T
      name: y
      declaredFragment: <testLibraryFragment> y@66
        element: isPublic
          type: T
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
      staticType: Null
    semicolon: ;
  declaredFragment: <testLibraryFragment> f@59
    element: <testLibrary>::@class::D::@method::f
      type: T Function<T>(T)
''');
  }

  test_genericMethod_override_bounds() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {
  T f<T extends A>(T x) => null;
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
// override with the same bound is OK
class C extends B {
  T f<T extends A>(T x) => null;
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
// override with new name and the same bound is OK
class D extends B {
  Q f<Q extends A>(Q x) => null;
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'Q'.
}
''');
  }

  test_genericMethod_override_covariant_field() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  num get x;
  set x(covariant num _);
}

class B extends A {
  int x;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'x' must be initialized.
}
''');
  }

  test_genericMethod_override_differentContextsSameBounds() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class C {
  T f<T extends A>(T x) => null;
//  ^
// [context 1] The member being overridden.
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
class D extends C {
  T f<T extends B>(T x) => null;
//  ^
// [diag.invalidOverride][context 1] 'D.f' ('T Function<T extends B>(T)') isn't a valid override of 'C.f' ('T Function<T extends A>(T)').
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}''');
  }

  test_genericMethod_override_invalidCovariantTypeParamBounds() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class C {
  T f<T extends B>(T x) => null;
//  ^
// [context 1] The member being overridden.
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
class D extends C {
  T f<T extends A>(T x) => null;
//  ^
// [diag.invalidOverride][context 1] 'D.f' ('T Function<T extends A>(T)') isn't a valid override of 'C.f' ('T Function<T extends B>(T)').
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}''');
  }

  test_genericMethod_override_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  Iterable<T> f<T>(T x) => null;
//            ^
// [context 1] The member being overridden.
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'Iterable<T>'.
}
class D extends C {
  String f<S>(S x) => null;
//       ^
// [diag.invalidOverride][context 1] 'D.f' ('String Function<S>(S)') isn't a valid override of 'C.f' ('Iterable<T> Function<T>(T)').
//                    ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'String'.
}''');
  }

  test_genericMethod_override_invalidTypeParamCount() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T f<T>(T x) => null;
//  ^
// [context 1] The member being overridden.
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
class D extends C {
  S f<T, S>(T x) => null;
//  ^
// [diag.invalidOverride][context 1] 'D.f' ('S Function<T, S>(T)') isn't a valid override of 'C.f' ('T Function<T>(T)').
//                  ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'S'.
}''');
  }

  test_genericMethod_propagatedType_promotion() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340

    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // example won't work, as we now compute a static type and therefore discard
    // the propagated type. So a new test was created that doesn't run under
    // strong mode.
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class Iter {
  List<S> map<S>(S f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }
  return null;
//       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'toSpan' because it has a return type of 'C'.
}
''');
    _assertLocalVarType(result, 'y', 'List<C>');
  }

  test_genericMethod_tearoff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  T f<T>(E e) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static T Function<T>(T) h = null;
//                            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T Function<T>(T)'.
}

T topF<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'topF' because it has a return type of 'T'.
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'lf' because it has a return type of 'T'.
  var methodTearOff = c.f;
//    ^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'methodTearOff' isn't used.
  var staticTearOff = C.g;
//    ^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticTearOff' isn't used.
  var staticFieldTearOff = C.h;
//    ^^^^^^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'staticFieldTearOff' isn't used.
  var topFunTearOff = topF;
//    ^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFunTearOff' isn't used.
  var topFieldTearOff = topG;
//    ^^^^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'topFieldTearOff' isn't used.
  var localTearOff = lf;
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'localTearOff' isn't used.
  var paramTearOff = pf;
//    ^^^^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'paramTearOff' isn't used.
}
''');
    _assertLocalVarType(result, 'methodTearOff', "T Function<T>(int)");
    _assertLocalVarType(result, 'staticTearOff', "T Function<T>(T)");
    _assertLocalVarType(result, 'staticFieldTearOff', "T Function<T>(T)");
    _assertLocalVarType(result, 'topFunTearOff', "T Function<T>(T)");
    _assertLocalVarType(result, 'topFieldTearOff', "T Function<T>(T)");
    _assertLocalVarType(result, 'localTearOff', "T Function<T>(T)");
    _assertLocalVarType(result, 'paramTearOff', "T Function<T>(T)");
  }

  @FailingTest() // TODO(scheglov): fix it
  test_genericMethod_tearoff_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    expectIdentifierType(result, 'methodTearOffInst', "int Function(int)");
    expectIdentifierType(result, 'staticTearOffInst', "int Function(int)");
    expectIdentifierType(result, 'staticFieldTearOffInst', "int Function(int)");
    expectIdentifierType(result, 'topFunTearOffInst', "int Function(int)");
    expectIdentifierType(result, 'topFieldTearOffInst', "int Function(int)");
    expectIdentifierType(result, 'localTearOffInst', "int Function(int)");
    expectIdentifierType(result, 'paramTearOffInst', "int Function(int)");
  }

  test_genericMethod_then() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
String toString(int x) => x.toString();
main() {
  Future<int> bar = null;
//                  ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Future<int>'.
  var foo = bar.then(toString);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');

    expectInitializerType(result, 'foo =', 'Future<String>');
  }

  test_genericMethod_then_prefixed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as async;
String toString(int x) => x.toString();
main() {
  async.Future<int> bar = null;
//                        ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Future<int>'.
  var foo = bar.then(toString);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    expectInitializerType(result, 'foo =', 'Future<String>');
  }

  test_genericMethod_then_propagatedType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25482.
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() {
  Future<String> p;
  var foo = p.then((r) => new Future<String>.value(3));
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'p' must be assigned before it can be used.
//                                                 ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'FutureOr<String>?'.
}
''');
    // Note: this correctly reports the error
    // CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE when run with the driver;
    // when run without the driver, it reports no errors.  So we don't bother
    // checking whether the correct errors were reported.
    expectInitializerType(result, 'foo =', 'Future<String>');
  }

  test_genericMethod_toplevel_field_staticTearoff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static T Function<T>(T) h = null;
//                            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T Function<T>(T)'.
}

void test() {
  var fieldRead = C.h;
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'fieldRead' isn't used.
}
''');
    _assertLocalVarType(result, 'fieldRead', "T Function<T>(T)");
  }

  test_implicitBounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

class B<T extends num> {}

class C<S extends int, T extends B<S>, U extends A> {}

void test() {
  A ai;
//  ^^
// [diag.unusedLocalVariable] The value of the local variable 'ai' isn't used.
  B bi;
//  ^^
// [diag.unusedLocalVariable] The value of the local variable 'bi' isn't used.
  C ci;
//  ^^
// [diag.unusedLocalVariable] The value of the local variable 'ci' isn't used.
  var aa = new A();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'aa' isn't used.
  var bb = new B();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'bb' isn't used.
  var cc = new C();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'cc' isn't used.
}
''');
    _assertLocalVarType(result, 'ai', "A<dynamic>");
    _assertLocalVarType(result, 'bi', "B<num>");
    _assertLocalVarType(result, 'ci', "C<int, B<int>, A<dynamic>>");
    _assertLocalVarType(result, 'aa', "A<dynamic>");
    _assertLocalVarType(result, 'bb', "B<num>");
    _assertLocalVarType(result, 'cc', "C<int, B<int>, A<dynamic>>");
  }

  test_instantiateToBounds_class_error_extension_malbounded() async {
    // Test that superclasses are strictly checked for malbounded default
    // types
    await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
class D extends C {}
//              ^
// [context 1] The raw type was instantiated as 'C<List<dynamic>, List<dynamic>>', and is not regular-bounded.
// [context 2] The raw type was instantiated as 'C<List<dynamic>, List<dynamic>>', and is not regular-bounded.
// [diag.typeArgumentNotMatchingBounds][context 1] 'List<dynamic>' doesn't conform to the bound 'List<List<dynamic>>' of the type parameter 'T0'.
// [diag.typeArgumentNotMatchingBounds][context 2] 'List<dynamic>' doesn't conform to the bound 'List<List<dynamic>>' of the type parameter 'T1'.
''');
  }

  test_instantiateToBounds_class_error_instantiation_malbounded() async {
    // Test that instance creations are strictly checked for malbounded default
    // types
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
void test() {
  var c = new C();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//            ^
// [context 1] The raw type was instantiated as 'C<List<Object?>, List<List<Object?>>>', and is not regular-bounded.
// [diag.couldNotInfer] Couldn't infer type parameter 'T0'.\n\nTried to infer 'List<Object?>' for 'T0' which doesn't work:\n  Type parameter 'T0' is declared to extend 'List<T1>' producing 'List<List<List<Object?>>>'.\n\nConsider passing explicit type argument(s) to the generic.
// [diag.typeArgumentNotMatchingBounds][context 1] 'List<Object?>' doesn't conform to the bound 'List<List<List<Object?>>>' of the type parameter 'T0'.
}
''');
    _assertLocalVarType(result, 'c', 'C<List<Object?>, List<List<Object?>>>');
  }

  test_instantiateToBounds_class_error_recursion() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<List<dynamic>, List<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T extends C<T>> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<C<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<E> {}
class C<T extends A<T>> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<A<dynamic>>');
  }

  test_instantiateToBounds_class_error_typedef() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef T F<T>(T x);
class C<T extends F<T>> {}
C c;
// [context 1][column 1][length 1] The raw type was instantiated as 'C<dynamic Function(dynamic)>', and is not regular-bounded.
// [context 2][column 1][length 1] The inverted type 'C<Never Function(Never)>' is also not regular-bounded, so the type is not well-bounded.
// [diag.typeArgumentNotMatchingBounds][column 1][length 1][context 1][context 2] 'F<Never>' doesn't conform to the bound 'F<F<Never>>' of the type parameter 'T'.
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<dynamic Function(dynamic)>');
  }

  test_instantiateToBounds_class_ok_implicitDynamic_multi() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends Map<T1, T2>, T1 extends List, T2 extends int> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(
      result,
      'c',
      'C<Map<List<dynamic>, int>, List<dynamic>, int>',
    );
  }

  test_instantiateToBounds_class_ok_referenceOther_after() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends T1, T1 extends int> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends Map<T1, T1>, T1 extends int> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<Map<int, int>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_before() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends int, T1 extends T0> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_multi() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T0 extends Map<T1, T2>, T1 extends List<T2>, T2 extends int> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
''');
    _assertTopVarType(result, 'c', 'C<Map<List<int>, int>, List<int>, int>');
  }

  test_instantiateToBounds_class_ok_simpleBounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
class B<T extends num> {}
class C<T extends List<int>> {}
class D<T extends A> {}
void main() {
  A a;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  B b;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  C c;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
  D d;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
}
''');
    _assertLocalVarType(result, 'a', 'A<dynamic>');
    _assertLocalVarType(result, 'b', 'B<num>');
    _assertLocalVarType(result, 'c', 'C<List<int>>');
    _assertLocalVarType(result, 'd', 'D<A<dynamic>>');
  }

  test_instantiateToBounds_generic_function_error_malbounded() async {
    // Test that generic methods are strictly checked for malbounded default
    // types
    var result = await resolveTestCodeWithDiagnostics(r'''
T0 f<T0 extends List<T1>, T1 extends List<T0>>() {}
// ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'T0', is a potentially non-nullable type.
void g() {
  var c = f();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//        ^
// [diag.couldNotInfer] Couldn't infer type parameter 'T0'.\n\nTried to infer 'List<Object?>' for 'T0' which doesn't work:\n  Type parameter 'T0' is declared to extend 'List<T1>' producing 'List<List<List<Object?>>>'.\n\nConsider passing explicit type argument(s) to the generic.
  return;
}
''');
    _assertLocalVarType(result, 'c', 'List<Object?>');
  }

  test_instantiateToBounds_method_ok_referenceOther_before() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  void m<S0 extends T, S1 extends List<S0>>(S0 p0, S1 p1) {}

  void main() {
    m(null, null);
//    ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'T'.
//          ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'List<T>'.
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::C::@method::m
      substitution: {T: T, S0: S0, S1: S1}
    staticType: void Function<S0 extends T, S1 extends List<S0>>(S0, S1)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: p0@null
          substitution: {S0: T, S1: List<T>}
        staticType: Null
      NullLiteral
        literal: null
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: p1@null
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  Map<S0, S1> m<S0 extends T, S1 extends List<S0>>() => null;
//                                                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'Map<S0, S1>'.

  void main() {
    m();
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::C::@method::m
      substitution: {T: T, S0: S0, S1: S1}
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  void m<S extends T>(S p0) {}

  void main() {
    m(null);
//    ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'T'.
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::C::@method::m
      substitution: {T: T, S: S}
    staticType: void Function<S extends T>(S)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: p0@null
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  S m<S extends T>() => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'S'.

  void main() {
    m();
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::C::@method::m
      substitution: {T: T, S: S}
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
    await resolveTestCodeWithDiagnostics(r'''
class C<E> {
  static T g<T>(T e) => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'g' because it has a return type of 'T'.
  static final h = g;
}
''');
  }

  test_objectMethodOnFunctions_Anonymous() async {
    await _objectMethodOnFunctions_helper2(r'''
void main() {
  var f = (x) => 3;
  // No errors, correct type
  var t0 = f.toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't0' isn't used.
  var t1 = f.toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't1' isn't used.
  var t2 = f.hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't2' isn't used.

  // Expressions, no errors, correct type
  var t3 = (f).toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't3' isn't used.
  var t4 = (f).toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't4' isn't used.
  var t5 = (f).hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't5' isn't used.

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}
''');
  }

  test_objectMethodOnFunctions_Function() async {
    await _objectMethodOnFunctions_helper2(r'''
void main() {
  Function f;
  // No errors, correct type
  var t0 = f.toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't0' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t1 = f.toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't1' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t2 = f.hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't2' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.

  // Expressions, no errors, correct type
  var t3 = (f).toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't3' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t4 = (f).toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't4' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t5 = (f).hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't5' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.

  // Cascades, no errors
  f..toString();
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  f..toString;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  f..hashCode;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.

  // Expression cascades, no errors
  (f)..toString();
// ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  (f)..toString;
// ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  (f)..hashCode;
// ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
}
''');
  }

  test_objectMethodOnFunctions_Static() async {
    await _objectMethodOnFunctions_helper2(r'''
int f(int x) => null;
//              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'int'.
void main() {
  // No errors, correct type
  var t0 = f.toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't0' isn't used.
  var t1 = f.toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't1' isn't used.
  var t2 = f.hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't2' isn't used.

  // Expressions, no errors, correct type
  var t3 = (f).toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't3' isn't used.
  var t4 = (f).toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't4' isn't used.
  var t5 = (f).hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't5' isn't used.

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}
''');
  }

  test_objectMethodOnFunctions_Typedef() async {
    await _objectMethodOnFunctions_helper2(r'''
typedef bool Predicate<T>(T object);

void main() {
  Predicate<int> f;
  // No errors, correct type
  var t0 = f.toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't0' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t1 = f.toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't1' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t2 = f.hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't2' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.

  // Expressions, no errors, correct type
  var t3 = (f).toString();
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't3' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t4 = (f).toString;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't4' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  var t5 = (f).hashCode;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 't5' isn't used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.

  // Cascades, no errors
  f..toString();
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  f..toString;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  f..hashCode;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.

  // Expression cascades, no errors
  (f)..toString();
// ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  (f)..toString;
// ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
  (f)..hashCode;
// ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'f' must be assigned before it can be used.
}
''');
  }

  test_returnOfInvalidType_object_void() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f() { void voidFn() => null; return voidFn(); }
//                                         ^^^^^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'void' can't be returned from the function 'f' because it has a return type of 'Object'.
''');
  }

  test_setterWithDynamicTypeIsError() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  dynamic set f(String s) => null;
//^^^^^^^
// [diag.nonVoidReturnForSetter] The return type of the setter must be 'void' or absent.
}
dynamic set g(int x) => null;
// [diag.nonVoidReturnForSetter][column 1][length 7] The return type of the setter must be 'void' or absent.
''');
  }

  test_setterWithExplicitVoidType_returningVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void returnsVoid() {}
class A {
  void set f(String s) => returnsVoid();
}
void set g(int x) => returnsVoid();
''');
  }

  test_setterWithNoVoidType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set f(String s) {
    return '42';
//         ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'f' because it has a return type of 'void'.
  }
}
set g(int x) => 42;
''');
  }

  test_setterWithNoVoidType_returningVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void returnsVoid() {}
class A {
  set f(String s) => returnsVoid();
}
set g(int x) => returnsVoid();
''');
  }

  test_setterWithOtherTypeIsError() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String set f(String s) => null;
//^^^^^^
// [diag.nonVoidReturnForSetter] The return type of the setter must be 'void' or absent.
//                          ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'String'.
}
Object set g(x) => null;
// [diag.nonVoidReturnForSetter][column 1][length 6] The return type of the setter must be 'void' or absent.
//                 ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'Object'.
''');
  }

  test_ternaryOperator_null_left() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var foo = (true) ? null : 3;
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
//                          ^
// [diag.deadCode] Dead code.
}
''');
    expectInitializerType(result, 'foo =', 'int?');
  }

  test_ternaryOperator_null_right() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var foo = (true) ? 3 : null;
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
//                       ^^^^
// [diag.deadCode] Dead code.
}
''');
    expectInitializerType(result, 'foo =', 'int?');
  }

  void _assertLocalVarType(
    TestResolvedUnitResult result,
    String name,
    String expectedType,
  ) {
    var element = result.findElement.localVar(name);
    assertType(element.type, expectedType);
  }

  void _assertTopVarType(
    TestResolvedUnitResult result,
    String name,
    String expectedType,
  ) {
    var element = result.findElement.topVar(name);
    assertType(element.type, expectedType);
  }

  Future<void> _objectMethodOnFunctions_helper2(String code) async {
    var result = await resolveTestCodeWithDiagnostics(code);
    _assertLocalVarType(result, 't0', "String");
    _assertLocalVarType(result, 't1', "String Function()");
    _assertLocalVarType(result, 't2', "int");
    _assertLocalVarType(result, 't3', "String");
    _assertLocalVarType(result, 't4', "String Function()");
    _assertLocalVarType(result, 't5', "int");
  }
}

@reflectiveTest
class StrongModeTypePropagationTest extends PubPackageResolutionTest {
  test_inconsistentMethodInheritance_inferFunctionTypeFromTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = null;
  v; // marker
}''');
    assertTypeDynamic(result.findElement.localVar('v').type);
    assertTypeDynamic(result.findNode.simple('v; // marker'));
  }

  test_localVariableInference_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = 3;
  v; // marker
}''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_declaredType_disabled() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  dynamic v = 3;
  v; // marker
}''');
    assertTypeDynamic(result.findElement.localVar('v').type);
    assertTypeDynamic(result.findNode.simple('v; // marker'));
  }

  test_localVariableInference_noInitializer_disabled() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v;
  v = 3;
  v; // marker
}''');
    var node = result.findNode.assignment('= 3');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: v@15
  writeType: dynamic
  element: <null>
  staticType: int
''');
    assertTypeDynamic(result.findNode.simple('v; // marker'));
  }

  test_localVariableInference_transitive_field_inferred_lexical() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_inferred_reversed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_lexical() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_reversed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_list_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var x = <int>[3];
  var v = x[0];
  v; // marker
}''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var x = 3;
  var v = x;
  v; // marker
}''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_inferred_lexical() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final x = 3;
main() {
  var v = x;
  v; // marker
}
''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_toplevel_inferred_reversed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = x;
  v; // marker
}
final x = 3;
''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_lexical() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int x = 3;
main() {
  var v = x;
  v; // marker
}
''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_reversed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = x;
  v; // marker
}
int x = 3;
''');
    assertType(result.findElement.localVar('v').type, 'int');
    assertType(result.findNode.simple('v; // marker'), 'int');
  }
}
