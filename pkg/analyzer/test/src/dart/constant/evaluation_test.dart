// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/resolver_test_case.dart';
import '../../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantVisitorTest);
  });
}

@reflectiveTest
class ConstantVisitorTest extends ResolverTestCase {
  test_visitAsExpression_instanceOfSameClass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a as A;
class A {
  const A();
}
''');
    DartObjectImpl resultA = _evaluateConstant(compilationUnit, 'a',
        experiments: [Experiments.constantUpdate2018Name]);
    DartObjectImpl resultB = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(resultB, resultA);
  }

  test_visitAsExpression_instanceOfSubclass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const B();
const b = a as A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl resultA = _evaluateConstant(compilationUnit, 'a',
        experiments: [Experiments.constantUpdate2018Name]);
    DartObjectImpl resultB = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(resultB, resultA);
  }

  test_visitAsExpression_instanceOfSuperclass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION],
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result, isNull);
  }

  test_visitAsExpression_instanceOfUnrelatedClass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION],
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result, isNull);
  }

  test_visitAsExpression_null() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = null;
const b = a as A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.nullType);
  }

  test_visitBinaryExpression_and_bool() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = false & true;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'c',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_and_int() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = 3 & 5;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'c',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.intType);
  }

  test_visitBinaryExpression_and_mixed() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = 3 & false;
''');
    _evaluateConstant(compilationUnit, 'c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT],
        experiments: [Experiments.constantUpdate2018Name]);
  }

  test_visitBinaryExpression_or_bool() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = false | true;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'c',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_or_int() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = 3 | 5;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'c',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.intType);
  }

  test_visitBinaryExpression_or_mixed() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = 3 | false;
''');
    _evaluateConstant(compilationUnit, 'c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT],
        experiments: [Experiments.constantUpdate2018Name]);
  }

  test_visitBinaryExpression_questionQuestion_notNull_notNull() async {
    Expression left = AstTestFactory.string2('a');
    Expression right = AstTestFactory.string2('b');
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'a');
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_questionQuestion_null_notNull() async {
    Expression left = AstTestFactory.nullLiteral();
    Expression right = AstTestFactory.string2('b');
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'b');
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_questionQuestion_null_null() async {
    Expression left = AstTestFactory.nullLiteral();
    Expression right = AstTestFactory.nullLiteral();
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isTrue);
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_xor_bool() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = false ^ true;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'c',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_xor_int() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = 3 ^ 5;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'c',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.intType);
  }

  test_visitBinaryExpression_xor_mixed() async {
    CompilationUnit compilationUnit = await resolveSource('''
const c = 3 ^ false;
''');
    _evaluateConstant(compilationUnit, 'c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT],
        experiments: [Experiments.constantUpdate2018Name]);
  }

  test_visitConditionalExpression_false() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(false), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(0, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  test_visitConditionalExpression_nonBooleanCondition() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    NullLiteral conditionExpression = AstTestFactory.nullLiteral();
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        conditionExpression, thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  test_visitConditionalExpression_nonConstantElse() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.identifier3("x");
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_nonConstantThen() async {
    Expression thenExpression = AstTestFactory.identifier3("x");
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_true() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(1, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  test_visitIsExpression_is_instanceOfSameClass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a is A;
class A {
  const A();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_instanceOfSubclass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const B();
const b = a is A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_instanceOfSuperclass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_is_instanceOfUnrelatedClass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_is_null() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = null;
const b = a is A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_is_null_dynamic() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = null;
const b = a is dynamic;
class A {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_null_null() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = null;
const b = a is Null;
class A {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_null_object() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = null;
const b = a is Object;
class A {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_isNot_instanceOfSameClass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a is! A;
class A {
  const A();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_isNot_instanceOfSubclass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const B();
const b = a is! A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_isNot_instanceOfSuperclass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_isNot_instanceOfUnrelatedClass() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_isNot_null() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = null;
const b = a is! A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'b',
        experiments: [Experiments.constantUpdate2018Name]);
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitSimpleIdentifier_className() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = C;
class C {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a');
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue().name, 'C');
  }

  test_visitSimpleIdentifier_dynamic() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = dynamic;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a');
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue(), typeProvider.dynamicType);
  }

  test_visitSimpleIdentifier_inEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["b"] = six;
    _assertValue(
        6,
        _evaluateConstant(compilationUnit, "a",
            lexicalEnvironment: environment));
  }

  test_visitSimpleIdentifier_notInEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["c"] = six;
    _assertValue(
        3,
        _evaluateConstant(compilationUnit, "a",
            lexicalEnvironment: environment));
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    _assertValue(3, _evaluateConstant(compilationUnit, "a"));
  }

  void _assertValue(int expectedValue, DartObjectImpl result) {
    expect(result, isNotNull);
    expect(result.type.name, "int");
    expect(result.toIntValue(), expectedValue);
  }

  NonExistingSource _dummySource() {
    String path = '/test.dart';
    return new NonExistingSource(path, toUri(path), UriKind.FILE_URI);
  }

  DartObjectImpl _evaluate(Expression expression, ErrorReporter errorReporter) {
    TestTypeProvider typeProvider = new TestTypeProvider();
    return expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            typeSystem: new StrongTypeSystemImpl(typeProvider)),
        errorReporter));
  }

  DartObjectImpl _evaluateConstant(CompilationUnit compilationUnit, String name,
      {List<ErrorCode> errorCodes,
      List<String> experiments,
      Map<String, DartObjectImpl> lexicalEnvironment}) {
    Source source =
        resolutionMap.elementDeclaredByCompilationUnit(compilationUnit).source;
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);

    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    if (experiments != null) {
      options..enabledExperiments = experiments;
    }

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);

    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            experiments: new Experiments(options), typeSystem: typeSystem),
        errorReporter,
        lexicalEnvironment: lexicalEnvironment));
    if (errorCodes == null) {
      errorListener.assertNoErrors();
    } else {
      errorListener.assertErrorsWithCodes(errorCodes);
    }
    return result;
  }
}
