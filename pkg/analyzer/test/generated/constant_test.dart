// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.constant_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'engine_test.dart';
import 'resolver_test.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ConstantEvaluatorTest);
  runReflectiveTests(ConstantFinderTest);
  runReflectiveTests(ConstantValueComputerTest);
  runReflectiveTests(ConstantVisitorTest);
  runReflectiveTests(ReferenceFinderTest);
}

/**
 * Implementation of [ConstantEvaluationValidator] used during unit tests;
 * verifies that any nodes referenced during constant evaluation are present in
 * the dependency graph.
 */
class ConstantEvaluationValidator_ForTest
    implements ConstantEvaluationValidator {
  final InternalAnalysisContext context;
  ConstantValueComputer computer;
  ConstantEvaluationTarget _nodeBeingEvaluated;

  ConstantEvaluationValidator_ForTest(this.context);

  @override
  void beforeComputeValue(ConstantEvaluationTarget constant) {
    _nodeBeingEvaluated = constant;
  }

  @override
  void beforeGetConstantInitializers(ConstructorElement constructor) =>
      _checkPathTo(constructor);

  @override
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant) =>
      _checkPathTo(constant);

  @override
  void beforeGetFieldEvaluationResult(FieldElementImpl field) =>
      _checkPathTo(field);

  @override
  void beforeGetParameterDefault(ParameterElement parameter) =>
      _checkPathTo(parameter);

  void _checkPathTo(ConstantEvaluationTarget target) {
    if (computer.referenceGraph.containsPath(_nodeBeingEvaluated, target)) {
      return; // pass
    }
    // print a nice error message on failure
    StringBuffer out = new StringBuffer();
    out.writeln("missing path in constant dependency graph");
    out.writeln("from $_nodeBeingEvaluated to $target");
    for (var s in context.analysisCache.sources) {
      String text = context.getContents(s).data;
      if (text != "") {
        out.writeln('''
=== ${s.shortName}
$text''');
      }
    }
    fail(out.toString());
  }
}

@reflectiveTest
class ConstantEvaluatorTest extends ResolverTestCase {
  void fail_constructor() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_class() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_function() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_static() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_staticMethod() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_topLevel() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_typeParameter() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void test_bitAnd_int_int() {
    _assertValue3(74 & 42, "74 & 42");
  }

  void test_bitNot() {
    _assertValue3(~42, "~42");
  }

  void test_bitOr_int_int() {
    _assertValue3(74 | 42, "74 | 42");
  }

  void test_bitXor_int_int() {
    _assertValue3(74 ^ 42, "74 ^ 42");
  }

  void test_divide_double_double() {
    _assertValue2(3.2 / 2.3, "3.2 / 2.3");
  }

  void test_divide_double_double_byZero() {
    EvaluationResult result = _getExpressionValue("3.2 / 0.0");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.toDoubleValue().isInfinite, isTrue);
  }

  void test_divide_int_int() {
    _assertValue2(1.5, "3 / 2");
  }

  void test_divide_int_int_byZero() {
    EvaluationResult result = _getExpressionValue("3 / 0");
    expect(result.isValid, isTrue);
  }

  void test_equal_boolean_boolean() {
    _assertValue(false, "true == false");
  }

  void test_equal_int_int() {
    _assertValue(false, "2 == 3");
  }

  void test_equal_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a == 3");
    expect(result.isValid, isFalse);
  }

  void test_equal_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 == a");
    expect(result.isValid, isFalse);
  }

  void test_equal_string_string() {
    _assertValue(false, "'a' == 'b'");
  }

  void test_greaterThan_int_int() {
    _assertValue(false, "2 > 3");
  }

  void test_greaterThanOrEqual_int_int() {
    _assertValue(false, "2 >= 3");
  }

  void test_leftShift_int_int() {
    _assertValue3(64, "16 << 2");
  }

  void test_lessThan_int_int() {
    _assertValue(true, "2 < 3");
  }

  void test_lessThanOrEqual_int_int() {
    _assertValue(true, "2 <= 3");
  }

  void test_literal_boolean_false() {
    _assertValue(false, "false");
  }

  void test_literal_boolean_true() {
    _assertValue(true, "true");
  }

  void test_literal_list() {
    EvaluationResult result = _getExpressionValue("const ['a', 'b', 'c']");
    expect(result.isValid, isTrue);
  }

  void test_literal_map() {
    EvaluationResult result =
        _getExpressionValue("const {'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    expect(result.isValid, isTrue);
  }

  void test_literal_null() {
    EvaluationResult result = _getExpressionValue("null");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.isNull, isTrue);
  }

  void test_literal_number_double() {
    _assertValue2(3.45, "3.45");
  }

  void test_literal_number_integer() {
    _assertValue3(42, "42");
  }

  void test_literal_string_adjacent() {
    _assertValue4("abcdef", "'abc' 'def'");
  }

  void test_literal_string_interpolation_invalid() {
    EvaluationResult result = _getExpressionValue("'a\${f()}c'");
    expect(result.isValid, isFalse);
  }

  void test_literal_string_interpolation_valid() {
    _assertValue4("a3c", "'a\${3}c'");
  }

  void test_literal_string_simple() {
    _assertValue4("abc", "'abc'");
  }

  void test_logicalAnd() {
    _assertValue(false, "true && false");
  }

  void test_logicalNot() {
    _assertValue(false, "!true");
  }

  void test_logicalOr() {
    _assertValue(true, "true || false");
  }

  void test_minus_double_double() {
    _assertValue2(3.2 - 2.3, "3.2 - 2.3");
  }

  void test_minus_int_int() {
    _assertValue3(1, "3 - 2");
  }

  void test_negated_boolean() {
    EvaluationResult result = _getExpressionValue("-true");
    expect(result.isValid, isFalse);
  }

  void test_negated_double() {
    _assertValue2(-42.3, "-42.3");
  }

  void test_negated_integer() {
    _assertValue3(-42, "-42");
  }

  void test_notEqual_boolean_boolean() {
    _assertValue(true, "true != false");
  }

  void test_notEqual_int_int() {
    _assertValue(true, "2 != 3");
  }

  void test_notEqual_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a != 3");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 != a");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_string_string() {
    _assertValue(true, "'a' != 'b'");
  }

  void test_parenthesizedExpression() {
    _assertValue4("a", "('a')");
  }

  void test_plus_double_double() {
    _assertValue2(2.3 + 3.2, "2.3 + 3.2");
  }

  void test_plus_int_int() {
    _assertValue3(5, "2 + 3");
  }

  void test_plus_string_string() {
    _assertValue4("ab", "'a' + 'b'");
  }

  void test_remainder_double_double() {
    _assertValue2(3.2 % 2.3, "3.2 % 2.3");
  }

  void test_remainder_int_int() {
    _assertValue3(2, "8 % 3");
  }

  void test_rightShift() {
    _assertValue3(16, "64 >> 2");
  }

  void test_stringLength_complex() {
    _assertValue3(6, "('qwe' + 'rty').length");
  }

  void test_stringLength_simple() {
    _assertValue3(6, "'Dvorak'.length");
  }

  void test_times_double_double() {
    _assertValue2(2.3 * 3.2, "2.3 * 3.2");
  }

  void test_times_int_int() {
    _assertValue3(6, "2 * 3");
  }

  void test_truncatingDivide_double_double() {
    _assertValue3(1, "3.2 ~/ 2.3");
  }

  void test_truncatingDivide_int_int() {
    _assertValue3(3, "10 ~/ 3");
  }

  void _assertValue(bool expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value.type.name, "bool");
    expect(value.toBoolValue(), expectedValue);
  }

  void _assertValue2(double expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.toDoubleValue(), expectedValue);
  }

  void _assertValue3(int expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "int");
    expect(value.toIntValue(), expectedValue);
  }

  void _assertValue4(String expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value, isNotNull);
    ParameterizedType type = value.type;
    expect(type, isNotNull);
    expect(type.name, "String");
    expect(value.toStringValue(), expectedValue);
  }

  EvaluationResult _getExpressionValue(String contents) {
    Source source = addSource("var x = $contents;");
    LibraryElement library = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember declaration = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, declaration);
    NodeList<VariableDeclaration> variables =
        (declaration as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    ConstantEvaluator evaluator = new ConstantEvaluator(
        source, analysisContext.typeProvider,
        typeSystem: analysisContext.typeSystem);
    return evaluator.evaluate(variables[0].initializer);
  }
}

@reflectiveTest
class ConstantFinderTest {
  AstNode _node;
  TypeProvider _typeProvider;
  AnalysisContext _context;
  Source _source;

  void setUp() {
    _typeProvider = new TestTypeProvider();
    _context = new _TestAnalysisContext();
    _source = new TestSource();
  }

  /**
   * Test an annotation that consists solely of an identifier (and hence
   * represents a reference to a compile-time constant variable).
   */
  void test_visitAnnotation_constantVariable() {
    _node = AstFactory.annotation(AstFactory.identifier3('x'));
    expect(_findAnnotations(), contains(_node));
  }

  /**
   * Test an annotation that represents the invocation of a constant
   * constructor.
   */
  void test_visitAnnotation_invocation() {
    _node = AstFactory.annotation2(
        AstFactory.identifier3('A'), null, AstFactory.argumentList());
    expect(_findAnnotations(), contains(_node));
  }

  void test_visitConstructorDeclaration_const() {
    ConstructorElement element = _setupConstructorDeclaration("A", true);
    expect(_findConstants(), contains(element));
  }

  void test_visitConstructorDeclaration_nonConst() {
    _setupConstructorDeclaration("A", false);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_const() {
    VariableElement element = _setupVariableDeclaration("v", true, true);
    expect(_findConstants(), contains(element));
  }

  void test_visitVariableDeclaration_final_inClass() {
    _setupFieldDeclaration('C', 'f', Keyword.FINAL);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        hasConstConstructor: true);
    expect(_findConstants(), contains(field.element));
  }

  void test_visitVariableDeclaration_final_outsideClass() {
    _setupVariableDeclaration('v', false, true, isFinal: true);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_noInitializer() {
    _setupVariableDeclaration("v", true, false);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_nonConst() {
    _setupVariableDeclaration("v", false, true);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_static_const_inClass() {
    VariableDeclaration field =
        _setupFieldDeclaration('C', 'f', Keyword.CONST, isStatic: true);
    expect(_findConstants(), contains(field.element));
  }

  void
      test_visitVariableDeclaration_static_const_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.CONST,
        isStatic: true, hasConstConstructor: true);
    expect(_findConstants(), contains(field.element));
  }

  void
      test_visitVariableDeclaration_static_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        isStatic: true, hasConstConstructor: true);
    expect(_findConstants(), isNot(contains(field.element)));
  }

  void
      test_visitVariableDeclaration_uninitialized_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        isInitialized: false, hasConstConstructor: true);
    expect(_findConstants(), isNot(contains(field.element)));
  }

  void test_visitVariableDeclaration_uninitialized_static_const_inClass() {
    _setupFieldDeclaration('C', 'f', Keyword.CONST,
        isStatic: true, isInitialized: false);
    expect(_findConstants(), isEmpty);
  }

  List<Annotation> _findAnnotations() {
    Set<Annotation> annotations = new Set<Annotation>();
    for (ConstantEvaluationTarget target in _findConstants()) {
      if (target is ConstantEvaluationTarget_Annotation) {
        expect(target.context, same(_context));
        expect(target.source, same(_source));
        annotations.add(target.annotation);
      }
    }
    return new List<Annotation>.from(annotations);
  }

  Set<ConstantEvaluationTarget> _findConstants() {
    ConstantFinder finder = new ConstantFinder(_context, _source, _source);
    _node.accept(finder);
    Set<ConstantEvaluationTarget> constants = finder.constantsToCompute;
    expect(constants, isNotNull);
    return constants;
  }

  ConstructorElement _setupConstructorDeclaration(String name, bool isConst) {
    Keyword constKeyword = isConst ? Keyword.CONST : null;
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            constKeyword,
            null,
            null,
            name,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    ClassElement classElement = ElementFactory.classElement2(name);
    ConstructorElement element =
        ElementFactory.constructorElement(classElement, name, isConst);
    constructorDeclaration.element = element;
    _node = constructorDeclaration;
    return element;
  }

  VariableDeclaration _setupFieldDeclaration(
      String className, String fieldName, Keyword keyword,
      {bool isInitialized: true,
      bool isStatic: false,
      bool hasConstConstructor: false}) {
    VariableDeclaration variableDeclaration = isInitialized
        ? AstFactory.variableDeclaration2(fieldName, AstFactory.integer(0))
        : AstFactory.variableDeclaration(fieldName);
    VariableElement fieldElement = ElementFactory.fieldElement(
        fieldName,
        isStatic,
        keyword == Keyword.FINAL,
        keyword == Keyword.CONST,
        _typeProvider.intType);
    variableDeclaration.name.staticElement = fieldElement;
    FieldDeclaration fieldDeclaration = AstFactory.fieldDeclaration2(
        isStatic, keyword, <VariableDeclaration>[variableDeclaration]);
    ClassDeclaration classDeclaration =
        AstFactory.classDeclaration(null, className, null, null, null, null);
    classDeclaration.members.add(fieldDeclaration);
    _node = classDeclaration;
    ClassElementImpl classElement = ElementFactory.classElement2(className);
    classElement.fields = <FieldElement>[fieldElement];
    classDeclaration.name.staticElement = classElement;
    if (hasConstConstructor) {
      ConstructorDeclaration constructorDeclaration =
          AstFactory.constructorDeclaration2(
              Keyword.CONST,
              null,
              AstFactory.identifier3(className),
              null,
              AstFactory.formalParameterList(),
              null,
              AstFactory.blockFunctionBody2());
      classDeclaration.members.add(constructorDeclaration);
      ConstructorElement constructorElement =
          ElementFactory.constructorElement(classElement, '', true);
      constructorDeclaration.element = constructorElement;
      classElement.constructors = <ConstructorElement>[constructorElement];
    } else {
      classElement.constructors = ConstructorElement.EMPTY_LIST;
    }
    return variableDeclaration;
  }

  VariableElement _setupVariableDeclaration(
      String name, bool isConst, bool isInitialized,
      {isFinal: false}) {
    VariableDeclaration variableDeclaration = isInitialized
        ? AstFactory.variableDeclaration2(name, AstFactory.integer(0))
        : AstFactory.variableDeclaration(name);
    SimpleIdentifier identifier = variableDeclaration.name;
    VariableElement element = ElementFactory.localVariableElement(identifier);
    identifier.staticElement = element;
    Keyword keyword = isConst ? Keyword.CONST : isFinal ? Keyword.FINAL : null;
    AstFactory.variableDeclarationList2(keyword, [variableDeclaration]);
    _node = variableDeclaration;
    return element;
  }
}

@reflectiveTest
class ConstantValueComputerTest extends ResolverTestCase {
  void test_annotation_constConstructor() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    Map<String, DartObjectImpl> annotationFields = _assertType(result, 'A');
    _assertIntField(annotationFields, 'i', 5);
  }

  void test_annotation_constConstructor_named() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A.named(this.i);
}

class C {
  @A.named(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    Map<String, DartObjectImpl> annotationFields = _assertType(result, 'A');
    _assertIntField(annotationFields, 'i', 5);
  }

  void test_annotation_constConstructor_noArgs() {
    // Failing to pass arguments to an annotation which is a constant
    // constructor is illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_constConstructor_noArgs_named() {
    // Failing to pass arguments to an annotation which is a constant
    // constructor is illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  const A.named(this.i);
}

class C {
  @A.named
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_nonConstConstructor() {
    // Calling a non-const constructor from an annotation that is illegal, but
    // shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  final int i;
  A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_staticConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
class C {
  static const int i = 5;

  @i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  void test_annotation_staticConst_args() {
    // Applying arguments to an annotation that is a static const is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class C {
  static const int i = 5;

  @i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_staticConst_otherClass() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  static const int i = 5;
}

class C {
  @A.i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  void test_annotation_staticConst_otherClass_args() {
    // Applying arguments to an annotation that is a static const is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  static const int i = 5;
}

class C {
  @A.i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_annotation_toplevelVariable() {
    CompilationUnit compilationUnit = resolveSource(r'''
const int i = 5;
class C {
  @i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  void test_annotation_toplevelVariable_args() {
    // Applying arguments to an annotation that is a toplevel variable is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = resolveSource(r'''
const int i = 5;
class C {
  @i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  void test_computeValues_cycle() {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    try {
      Source source = addSource(r'''
  const int a = c;
  const int b = a;
  const int c = b;''');
      LibraryElement libraryElement = resolve2(source);
      CompilationUnit unit =
          analysisContext.resolveCompilationUnit(source, libraryElement);
      analysisContext.computeErrors(source);
      expect(unit, isNotNull);
      ConstantValueComputer computer = _makeConstantValueComputer();
      computer.add(unit, source, source);
      computer.computeValues();
      NodeList<CompilationUnitMember> members = unit.declarations;
      expect(members, hasLength(3));
      _validate(false, (members[0] as TopLevelVariableDeclaration).variables);
      _validate(false, (members[1] as TopLevelVariableDeclaration).variables);
      _validate(false, (members[2] as TopLevelVariableDeclaration).variables);
    } finally {
      AnalysisEngine.instance.logger = Logger.NULL;
    }
  }

  void test_computeValues_dependentVariables() {
    Source source = addSource(r'''
const int b = a;
const int a = 0;''');
    LibraryElement libraryElement = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, source, source);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(2));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (members[1] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_empty() {
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.computeValues();
  }

  void test_computeValues_multipleSources() {
    Source librarySource = addNamedSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
const int c = b;
const int a = 0;''');
    Source partSource = addNamedSource(
        "/part.dart",
        r'''
part of lib;
const int b = a;
const int d = c;''');
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit libraryUnit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(libraryUnit, isNotNull);
    CompilationUnit partUnit =
        analysisContext.resolveCompilationUnit(partSource, libraryElement);
    expect(partUnit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(libraryUnit, librarySource, librarySource);
    computer.add(partUnit, partSource, librarySource);
    computer.computeValues();
    NodeList<CompilationUnitMember> libraryMembers = libraryUnit.declarations;
    expect(libraryMembers, hasLength(2));
    _validate(
        true, (libraryMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(
        true, (libraryMembers[1] as TopLevelVariableDeclaration).variables);
    NodeList<CompilationUnitMember> partMembers = libraryUnit.declarations;
    expect(partMembers, hasLength(2));
    _validate(true, (partMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (partMembers[1] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_singleVariable() {
    Source source = addSource("const int a = 0;");
    LibraryElement libraryElement = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, source, source);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(1));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
  }

  void test_computeValues_value_depends_on_enum() {
    Source source = addSource('''
enum E { id0, id1 }
const E e = E.id0;
''');
    LibraryElement libraryElement = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, source, source);
    computer.computeValues();
    TopLevelVariableDeclaration declaration = unit.declarations
        .firstWhere((member) => member is TopLevelVariableDeclaration);
    _validate(true, declaration.variables);
  }

  void test_dependencyOnConstructor() {
    // x depends on "const A()"
    _assertProperDependencies(r'''
class A {
  const A();
}
const x = const A();''');
  }

  void test_dependencyOnConstructorArgument() {
    // "const A(x)" depends on x
    _assertProperDependencies(r'''
class A {
  const A(this.next);
  final A next;
}
const A x = const A(null);
const A y = const A(x);''');
  }

  void test_dependencyOnConstructorArgument_unresolvedConstructor() {
    // "const A.a(x)" depends on x even if the constructor A.a can't be found.
    _assertProperDependencies(
        r'''
class A {
}
const int x = 1;
const A y = const A.a(x);''',
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
  }

  void test_dependencyOnConstructorInitializer() {
    // "const A()" depends on x
    _assertProperDependencies(r'''
const int x = 1;
class A {
  const A() : v = x;
  final int v;
}''');
  }

  void test_dependencyOnExplicitSuperConstructor() {
    // b depends on B() depends on A()
    _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(5);
}
const B b = const B();''');
  }

  void test_dependencyOnExplicitSuperConstructorParameters() {
    // b depends on B() depends on i
    _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(i);
}
const B b = const B();
const int i = 5;''');
  }

  void test_dependencyOnFactoryRedirect() {
    // a depends on A.foo() depends on A.bar()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  factory const A.foo() = A.bar;
  const A.bar();
}''');
  }

  void test_dependencyOnFactoryRedirectWithTypeParams() {
    _assertProperDependencies(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
  }

  void test_dependencyOnImplicitSuperConstructor() {
    // b depends on B() depends on A()
    _assertProperDependencies(r'''
class A {
  const A() : x = 5;
  final int x;
}
class B extends A {
  const B();
}
const B b = const B();''');
  }

  void test_dependencyOnInitializedFinal() {
    // a depends on A() depends on A.x
    _assertProperDependencies('''
class A {
  const A();
  final int x = 1;
}
const A a = const A();
''');
  }

  void test_dependencyOnInitializedNonStaticConst() {
    // Even though non-static consts are not allowed by the language, we need
    // to handle them for error recovery purposes.
    // a depends on A() depends on A.x
    _assertProperDependencies(
        '''
class A {
  const A();
  const int x = 1;
}
const A a = const A();
''',
        [CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
  }

  void test_dependencyOnNonFactoryRedirect() {
    // a depends on A.foo() depends on A.bar()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  const A.bar();
}''');
  }

  void test_dependencyOnNonFactoryRedirect_arg() {
    // a depends on A.foo() depends on b
    _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar(b);
  const A.bar(x) : y = x;
  final int y;
}''');
  }

  void test_dependencyOnNonFactoryRedirect_defaultValue() {
    // a depends on A.foo() depends on A.bar() depends on b
    _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar();
  const A.bar([x = b]) : y = x;
  final int y;
}''');
  }

  void test_dependencyOnNonFactoryRedirect_toMissing() {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // missing.
    _assertProperDependencies(
        r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
}''',
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR]);
  }

  void test_dependencyOnNonFactoryRedirect_toNonConst() {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // non-const.
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  A.bar();
}''');
  }

  void test_dependencyOnNonFactoryRedirect_unnamed() {
    // a depends on A.foo() depends on A()
    _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this();
  const A();
}''');
  }

  void test_dependencyOnOptionalParameterDefault() {
    // a depends on A() depends on B()
    _assertProperDependencies(r'''
class A {
  const A([x = const B()]) : b = x;
  final B b;
}
class B {
  const B();
}
const A a = const A();''');
  }

  void test_dependencyOnVariable() {
    // x depends on y
    _assertProperDependencies(r'''
const x = y + 1;
const y = 2;''');
  }

  void test_final_initialized_at_declaration() {
    CompilationUnit compilationUnit = resolveSource('''
class A {
  final int i = 123;
  const A();
}

const A a = const A();
''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, 'a');
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "i", 123);
  }

  void test_fromEnvironment_bool_default_false() {
    expect(_assertValidBool(_check_fromEnvironment_bool(null, "false")), false);
  }

  void test_fromEnvironment_bool_default_overridden() {
    expect(
        _assertValidBool(_check_fromEnvironment_bool("false", "true")), false);
  }

  void test_fromEnvironment_bool_default_parseError() {
    expect(_assertValidBool(_check_fromEnvironment_bool("parseError", "true")),
        true);
  }

  void test_fromEnvironment_bool_default_true() {
    expect(_assertValidBool(_check_fromEnvironment_bool(null, "true")), true);
  }

  void test_fromEnvironment_bool_false() {
    expect(_assertValidBool(_check_fromEnvironment_bool("false", null)), false);
  }

  void test_fromEnvironment_bool_parseError() {
    expect(_assertValidBool(_check_fromEnvironment_bool("parseError", null)),
        false);
  }

  void test_fromEnvironment_bool_true() {
    expect(_assertValidBool(_check_fromEnvironment_bool("true", null)), true);
  }

  void test_fromEnvironment_bool_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_bool(null, null));
  }

  void test_fromEnvironment_int_default_overridden() {
    expect(_assertValidInt(_check_fromEnvironment_int("234", "123")), 234);
  }

  void test_fromEnvironment_int_default_parseError() {
    expect(
        _assertValidInt(_check_fromEnvironment_int("parseError", "123")), 123);
  }

  void test_fromEnvironment_int_default_undeclared() {
    expect(_assertValidInt(_check_fromEnvironment_int(null, "123")), 123);
  }

  void test_fromEnvironment_int_ok() {
    expect(_assertValidInt(_check_fromEnvironment_int("234", null)), 234);
  }

  void test_fromEnvironment_int_parseError() {
    _assertValidNull(_check_fromEnvironment_int("parseError", null));
  }

  void test_fromEnvironment_int_parseError_nullDefault() {
    _assertValidNull(_check_fromEnvironment_int("parseError", "null"));
  }

  void test_fromEnvironment_int_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_int(null, null));
  }

  void test_fromEnvironment_int_undeclared_nullDefault() {
    _assertValidNull(_check_fromEnvironment_int(null, "null"));
  }

  void test_fromEnvironment_string_default_overridden() {
    expect(_assertValidString(_check_fromEnvironment_string("abc", "'def'")),
        "abc");
  }

  void test_fromEnvironment_string_default_undeclared() {
    expect(_assertValidString(_check_fromEnvironment_string(null, "'def'")),
        "def");
  }

  void test_fromEnvironment_string_empty() {
    expect(_assertValidString(_check_fromEnvironment_string("", null)), "");
  }

  void test_fromEnvironment_string_ok() {
    expect(
        _assertValidString(_check_fromEnvironment_string("abc", null)), "abc");
  }

  void test_fromEnvironment_string_undeclared() {
    _assertValidUnknown(_check_fromEnvironment_string(null, null));
  }

  void test_fromEnvironment_string_undeclared_nullDefault() {
    _assertValidNull(_check_fromEnvironment_string(null, "null"));
  }

  void test_instanceCreationExpression_computedField() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(4, 5);
class A {
  const A(int i, int j) : k = 2 * i + j;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 13);
  }

  void
      test_instanceCreationExpression_computedField_namedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(false, true, true);
  }

  void
      test_instanceCreationExpression_computedField_namedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(false, true, false);
  }

  void
      test_instanceCreationExpression_computedField_unnamedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(false, false, true);
  }

  void
      test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(false, false, false);
  }

  void test_instanceCreationExpression_computedField_usesConstConstructor() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : b = const B(4);
  final int b;
}
class B {
  const B(this.k);
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fieldsOfA = _assertType(result, "A");
    expect(fieldsOfA, hasLength(1));
    Map<String, DartObjectImpl> fieldsOfB =
        _assertFieldType(fieldsOfA, "b", "B");
    expect(fieldsOfB, hasLength(1));
    _assertIntField(fieldsOfB, "k", 4);
  }

  void test_instanceCreationExpression_computedField_usesStaticConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : k = i + B.bar;
  final int k;
}
class B {
  static const bar = 4;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  void test_instanceCreationExpression_computedField_usesToplevelConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(3);
const bar = 4;
class A {
  const A(int i) : k = i + bar;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  void test_instanceCreationExpression_explicitSuper() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const B(4, 5);
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B(int x, this.y) : super(x * 2);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 5);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 8);
  }

  void test_instanceCreationExpression_fieldFormalParameter() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A(42);
class A {
  int x;
  const A(this.x)
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 42);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(true, true, true);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(true, true, false);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault() {
    _checkInstanceCreationOptionalParams(true, false, true);
  }

  void
      test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault() {
    _checkInstanceCreationOptionalParams(true, false, false);
  }

  void test_instanceCreationExpression_implicitSuper() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const B(4);
class A {
  const A() : x = 3;
  final int x;
}
class B extends A {
  const B(this.y);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 4);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 3);
  }

  void test_instanceCreationExpression_nonFactoryRedirect() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'x', 5);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_arg() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1(1);
class A {
  const A.a1(x) : this.a2(x + 100);
  const A.a2(x) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'y', 111);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_cycle() {
    // It is an error to have a cycle in non-factory redirects; however, we
    // need to make sure that even if the error occurs, attempting to evaluate
    // the constant will terminate.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const A() : this.b();
  const A.b() : this();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_nonFactoryRedirect_defaultArg() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2([x = 100]) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'y', 110);
  }

  void test_instanceCreationExpression_nonFactoryRedirect_toMissing() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
  }

  void test_instanceCreationExpression_nonFactoryRedirect_toNonConst() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  A.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
  }

  void test_instanceCreationExpression_nonFactoryRedirect_unnamed() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this();
  const A() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'x', 5);
  }

  void test_instanceCreationExpression_redirect() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = B;
}
class B implements A {
  const B();
}''');
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "B");
  }

  void test_instanceCreationExpression_redirect_cycle() {
    // It is an error to have a cycle in factory redirects; however, we need
    // to make sure that even if the error occurs, attempting to evaluate the
    // constant will terminate.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  const factory A.b() = A;
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirect_extern() {
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  external const factory A();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirect_nonConst() {
    // It is an error for a const factory constructor redirect to a non-const
    // constructor; however, we need to make sure that even if the error
    // attempting to evaluate the constant won't cause a crash.
    CompilationUnit compilationUnit = resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  A.b();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  void test_instanceCreationExpression_redirectWithTypeParams() {
    CompilationUnit compilationUnit = resolveSource(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  void test_instanceCreationExpression_redirectWithTypeSubstitution() {
    // To evaluate the redirection of A<int>,
    // A's template argument (T=int) must be substituted
    // into B's template argument (B<U> where U=T) to get B<int>.
    CompilationUnit compilationUnit = resolveSource(r'''
class A<T> {
  const factory A(var a) = B<T>;
}

class B<U> implements A {
  final U x;
  const B(this.x);
}

const A<int> a = const A<int>(10);''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  void test_instanceCreationExpression_symbol() {
    CompilationUnit compilationUnit =
        resolveSource("const foo = const Symbol('a');");
    EvaluationResultImpl evaluationResult =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    expect(evaluationResult.value, isNotNull);
    DartObjectImpl value = evaluationResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.toSymbolValue(), "a");
  }

  void test_instanceCreationExpression_withSupertypeParams_explicit() {
    _checkInstanceCreation_withSupertypeParams(true);
  }

  void test_instanceCreationExpression_withSupertypeParams_implicit() {
    _checkInstanceCreation_withSupertypeParams(false);
  }

  void test_instanceCreationExpression_withTypeParams() {
    CompilationUnit compilationUnit = resolveSource(r'''
class C<E> {
  const C();
}
const c_int = const C<int>();
const c_num = const C<num>();''');
    EvaluationResultImpl c_int =
        _evaluateTopLevelVariable(compilationUnit, "c_int");
    _assertType(c_int, "C<int>");
    DartObjectImpl c_int_value = c_int.value;
    EvaluationResultImpl c_num =
        _evaluateTopLevelVariable(compilationUnit, "c_num");
    _assertType(c_num, "C<num>");
    DartObjectImpl c_num_value = c_num.value;
    expect(c_int_value == c_num_value, isFalse);
  }

  void test_isValidSymbol() {
    expect(ConstantEvaluationEngine.isValidPublicSymbol(""), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.bar"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo\$"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo\$bar"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("iff"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("gif"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if\$"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("\$if"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo="), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.bar="), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.+"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("void"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("_foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("_foo.bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo._bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.if"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo=.bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo."), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("+.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("void.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.void"), isFalse);
  }

  void test_length_of_improperly_typed_string_expression() {
    // Since type annotations are ignored in unchecked mode, the improper
    // types on s1 and s2 shouldn't prevent us from evaluating i to
    // 'alpha'.length.
    CompilationUnit compilationUnit = resolveSource('''
const int s1 = 'alpha';
const int s2 = 'beta';
const int i = (true ? s1 : s2).length;
''');
    ConstTopLevelVariableElementImpl element =
        findTopLevelDeclaration(compilationUnit, 'i').element;
    EvaluationResultImpl result = element.evaluationResult;
    expect(_assertValidInt(result), 5);
  }

  void test_length_of_improperly_typed_string_identifier() {
    // Since type annotations are ignored in unchecked mode, the improper type
    // on s shouldn't prevent us from evaluating i to 'alpha'.length.
    CompilationUnit compilationUnit = resolveSource('''
const int s = 'alpha';
const int i = s.length;
''');
    ConstTopLevelVariableElementImpl element =
        findTopLevelDeclaration(compilationUnit, 'i').element;
    EvaluationResultImpl result = element.evaluationResult;
    expect(_assertValidInt(result), 5);
  }

  void test_non_static_const_initialized_at_declaration() {
    // Even though non-static consts are not allowed by the language, we need
    // to handle them for error recovery purposes.
    CompilationUnit compilationUnit = resolveSource('''
class A {
  const int i = 123;
  const A();
}

const A a = const A();
''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, 'a');
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "i", 123);
  }

  void test_symbolLiteral_void() {
    CompilationUnit compilationUnit =
        resolveSource("const voidSymbol = #void;");
    VariableDeclaration voidSymbol =
        findTopLevelDeclaration(compilationUnit, "voidSymbol");
    EvaluationResultImpl voidSymbolResult =
        (voidSymbol.element as VariableElementImpl).evaluationResult;
    DartObjectImpl value = voidSymbolResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.toSymbolValue(), "void");
  }

  Map<String, DartObjectImpl> _assertFieldType(
      Map<String, DartObjectImpl> fields,
      String fieldName,
      String expectedType) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.displayName, expectedType);
    return field.fields;
  }

  void _assertIntField(
      Map<String, DartObjectImpl> fields, String fieldName, int expectedValue) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.name, "int");
    expect(field.toIntValue(), expectedValue);
  }

  void _assertNullField(Map<String, DartObjectImpl> fields, String fieldName) {
    DartObjectImpl field = fields[fieldName];
    expect(field.isNull, isTrue);
  }

  void _assertProperDependencies(String sourceText,
      [List<ErrorCode> expectedErrorCodes = ErrorCode.EMPTY_LIST]) {
    Source source = addSource(sourceText);
    LibraryElement element = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, element);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit, source, source);
    computer.computeValues();
    assertErrors(source, expectedErrorCodes);
  }

  Map<String, DartObjectImpl> _assertType(
      EvaluationResultImpl result, String typeName) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type.displayName, typeName);
    return value.fields;
  }

  bool _assertValidBool(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.boolType);
    bool boolValue = value.toBoolValue();
    expect(boolValue, isNotNull);
    return boolValue;
  }

  int _assertValidInt(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.intType);
    return value.toIntValue();
  }

  void _assertValidNull(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.nullType);
  }

  String _assertValidString(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.stringType);
    return value.toStringValue();
  }

  void _assertValidUnknown(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.isUnknown, isTrue);
  }

  EvaluationResultImpl _check_fromEnvironment_bool(
      String valueInEnvironment, String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
        "const $varName = const bool.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  EvaluationResultImpl _check_fromEnvironment_int(
      String valueInEnvironment, String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
        "const $varName = const int.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  EvaluationResultImpl _check_fromEnvironment_string(
      String valueInEnvironment, String defaultExpr) {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      analysisContext2.declaredVariables.define(envVarName, valueInEnvironment);
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = resolveSource(
        "const $varName = const String.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  void _checkInstanceCreation_withSupertypeParams(bool isExplicit) {
    String superCall = isExplicit ? " : super()" : "";
    CompilationUnit compilationUnit = resolveSource("""
class A<T> {
  const A();
}
class B<T, U> extends A<T> {
  const B()$superCall;
}
class C<T, U> extends A<U> {
  const C()$superCall;
}
const b_int_num = const B<int, num>();
const c_int_num = const C<int, num>();""");
    EvaluationResultImpl b_int_num =
        _evaluateTopLevelVariable(compilationUnit, "b_int_num");
    Map<String, DartObjectImpl> b_int_num_fields =
        _assertType(b_int_num, "B<int, num>");
    _assertFieldType(b_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<int>");
    EvaluationResultImpl c_int_num =
        _evaluateTopLevelVariable(compilationUnit, "c_int_num");
    Map<String, DartObjectImpl> c_int_num_fields =
        _assertType(c_int_num, "C<int, num>");
    _assertFieldType(c_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<num>");
  }

  void _checkInstanceCreationOptionalParams(
      bool isFieldFormal, bool isNamed, bool hasDefault) {
    String fieldName = "j";
    String paramName = isFieldFormal ? fieldName : "i";
    String formalParam =
        "${isFieldFormal ? "this." : "int "}$paramName${hasDefault ? " = 3" : ""}";
    CompilationUnit compilationUnit = resolveSource("""
const x = const A();
const y = const A(${isNamed ? '$paramName: ' : ''}10);
class A {
  const A(${isNamed ? "{$formalParam}" : "[$formalParam]"})${isFieldFormal ? "" : " : $fieldName = $paramName"};
  final int $fieldName;
}""");
    EvaluationResultImpl x = _evaluateTopLevelVariable(compilationUnit, "x");
    Map<String, DartObjectImpl> fieldsOfX = _assertType(x, "A");
    expect(fieldsOfX, hasLength(1));
    if (hasDefault) {
      _assertIntField(fieldsOfX, fieldName, 3);
    } else {
      _assertNullField(fieldsOfX, fieldName);
    }
    EvaluationResultImpl y = _evaluateTopLevelVariable(compilationUnit, "y");
    Map<String, DartObjectImpl> fieldsOfY = _assertType(y, "A");
    expect(fieldsOfY, hasLength(1));
    _assertIntField(fieldsOfY, fieldName, 10);
  }

  /**
   * Search [compilationUnit] for a class named [className], containing a
   * method [methodName], with exactly one annotation.  Return the constant
   * value of the annotation.
   */
  EvaluationResultImpl _evaluateAnnotation(
      CompilationUnit compilationUnit, String className, String memberName) {
    for (CompilationUnitMember member in compilationUnit.declarations) {
      if (member is ClassDeclaration && member.name.name == className) {
        for (ClassMember classMember in member.members) {
          if (classMember is MethodDeclaration &&
              classMember.name.name == memberName) {
            expect(classMember.metadata, hasLength(1));
            ElementAnnotationImpl elementAnnotation =
                classMember.metadata[0].elementAnnotation;
            return elementAnnotation.evaluationResult;
          }
        }
      }
    }
    fail('Class member not found');
    return null;
  }

  EvaluationResultImpl _evaluateTopLevelVariable(
      CompilationUnit compilationUnit, String name) {
    VariableDeclaration varDecl =
        findTopLevelDeclaration(compilationUnit, name);
    ConstTopLevelVariableElementImpl varElement = varDecl.element;
    return varElement.evaluationResult;
  }

  ConstantValueComputer _makeConstantValueComputer() {
    ConstantEvaluationValidator_ForTest validator =
        new ConstantEvaluationValidator_ForTest(analysisContext2);
    validator.computer = new ConstantValueComputer(
        analysisContext2,
        analysisContext2.typeProvider,
        analysisContext2.declaredVariables,
        validator,
        analysisContext2.typeSystem);
    return validator.computer;
  }

  void _validate(bool shouldBeValid, VariableDeclarationList declarationList) {
    for (VariableDeclaration declaration in declarationList.variables) {
      VariableElementImpl element = declaration.element as VariableElementImpl;
      expect(element, isNotNull);
      EvaluationResultImpl result = element.evaluationResult;
      if (shouldBeValid) {
        expect(result.value, isNotNull);
      } else {
        expect(result.value, isNull);
      }
    }
  }
}

@reflectiveTest
class ConstantVisitorTest extends ResolverTestCase {
  void test_visitBinaryExpression_questionQuestion_notNull_notNull() {
    Expression left = AstFactory.string2('a');
    Expression right = AstFactory.string2('b');
    Expression expression =
        AstFactory.binaryExpression(left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'a');
    errorListener.assertNoErrors();
  }

  void test_visitBinaryExpression_questionQuestion_null_notNull() {
    Expression left = AstFactory.nullLiteral();
    Expression right = AstFactory.string2('b');
    Expression expression =
        AstFactory.binaryExpression(left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'b');
    errorListener.assertNoErrors();
  }

  void test_visitBinaryExpression_questionQuestion_null_null() {
    Expression left = AstFactory.nullLiteral();
    Expression right = AstFactory.nullLiteral();
    Expression expression =
        AstFactory.binaryExpression(left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isTrue);
    errorListener.assertNoErrors();
  }

  void test_visitConditionalExpression_false() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(false), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(0, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  void test_visitConditionalExpression_nonBooleanCondition() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    NullLiteral conditionExpression = AstFactory.nullLiteral();
    ConditionalExpression expression = AstFactory.conditionalExpression(
        conditionExpression, thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  void test_visitConditionalExpression_nonConstantElse() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.identifier3("x");
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_nonConstantThen() {
    Expression thenExpression = AstFactory.identifier3("x");
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  void test_visitConditionalExpression_true() {
    Expression thenExpression = AstFactory.integer(1);
    Expression elseExpression = AstFactory.integer(0);
    ConditionalExpression expression = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(1, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_className() {
    CompilationUnit compilationUnit = resolveSource('''
const a = C;
class C {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue().name, 'C');
  }

  void test_visitSimpleIdentifier_dynamic() {
    CompilationUnit compilationUnit = resolveSource('''
const a = dynamic;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue(), typeProvider.dynamicType);
  }

  void test_visitSimpleIdentifier_inEnvironment() {
    CompilationUnit compilationUnit = resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["b"] = six;
    _assertValue(6, _evaluateConstant(compilationUnit, "a", environment));
  }

  void test_visitSimpleIdentifier_notInEnvironment() {
    CompilationUnit compilationUnit = resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["c"] = six;
    _assertValue(3, _evaluateConstant(compilationUnit, "a", environment));
  }

  void test_visitSimpleIdentifier_withoutEnvironment() {
    CompilationUnit compilationUnit = resolveSource(r'''
const a = b;
const b = 3;''');
    _assertValue(3, _evaluateConstant(compilationUnit, "a", null));
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
    return expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(
            new TestTypeProvider(), new DeclaredVariables(),
            typeSystem: new TypeSystemImpl()),
        errorReporter));
  }

  DartObjectImpl _evaluateConstant(CompilationUnit compilationUnit, String name,
      Map<String, DartObjectImpl> lexicalEnvironment) {
    Source source = compilationUnit.element.source;
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            typeSystem: typeSystem),
        errorReporter,
        lexicalEnvironment: lexicalEnvironment));
    errorListener.assertNoErrors();
    return result;
  }
}

@reflectiveTest
class ReferenceFinderTest {
  DirectedGraph<ConstantEvaluationTarget> _referenceGraph;
  VariableElement _head;
  Element _tail;

  void setUp() {
    _referenceGraph = new DirectedGraph<ConstantEvaluationTarget>();
    _head = ElementFactory.topLevelVariableElement2("v1");
  }

  void test_visitSimpleIdentifier_const() {
    _visitNode(_makeTailVariable("v2", true));
    _assertOneArc(_tail);
  }

  void test_visitSimpleIdentifier_nonConst() {
    _visitNode(_makeTailVariable("v2", false));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_const() {
    _visitNode(_makeTailSuperConstructorInvocation("A", true));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_nonConst() {
    _visitNode(_makeTailSuperConstructorInvocation("A", false));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_unresolved() {
    SuperConstructorInvocation superConstructorInvocation =
        AstFactory.superConstructorInvocation();
    _visitNode(superConstructorInvocation);
    _assertNoArcs();
  }

  void _assertNoArcs() {
    Set<ConstantEvaluationTarget> tails = _referenceGraph.getTails(_head);
    expect(tails, hasLength(0));
  }

  void _assertOneArc(Element tail) {
    Set<ConstantEvaluationTarget> tails = _referenceGraph.getTails(_head);
    expect(tails, hasLength(1));
    expect(tails.first, same(tail));
  }

  ReferenceFinder _createReferenceFinder(ConstantEvaluationTarget source) =>
      new ReferenceFinder((ConstantEvaluationTarget dependency) {
        _referenceGraph.addEdge(source, dependency);
      });
  SuperConstructorInvocation _makeTailSuperConstructorInvocation(
      String name, bool isConst) {
    List<ConstructorInitializer> initializers =
        new List<ConstructorInitializer>();
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration(AstFactory.identifier3(name), null,
            AstFactory.formalParameterList(), initializers);
    if (isConst) {
      constructorDeclaration.constKeyword = new KeywordToken(Keyword.CONST, 0);
    }
    ClassElementImpl classElement = ElementFactory.classElement2(name);
    SuperConstructorInvocation superConstructorInvocation =
        AstFactory.superConstructorInvocation();
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(classElement, name, isConst);
    _tail = constructorElement;
    superConstructorInvocation.staticElement = constructorElement;
    return superConstructorInvocation;
  }

  SimpleIdentifier _makeTailVariable(String name, bool isConst) {
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration(name);
    ConstLocalVariableElementImpl variableElement =
        ElementFactory.constLocalVariableElement(name);
    _tail = variableElement;
    variableElement.const3 = isConst;
    AstFactory.variableDeclarationList2(
        isConst ? Keyword.CONST : Keyword.VAR, [variableDeclaration]);
    SimpleIdentifier identifier = AstFactory.identifier3(name);
    identifier.staticElement = variableElement;
    return identifier;
  }

  void _visitNode(AstNode node) {
    node.accept(_createReferenceFinder(_head));
  }
}

class _TestAnalysisContext extends TestAnalysisContext {
  @override
  InternalAnalysisContext getContextFor(Source source) => this;
}
