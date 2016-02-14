// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.constant_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
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
  runReflectiveTests(DartObjectImplTest);
  runReflectiveTests(DeclaredVariablesTest);
  runReflectiveTests(ReferenceFinderTest);
}

const int LONG_MAX_VALUE = 0x7fffffffffffffff;

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
    Map<DartObject, DartObject> map = result.value.toMapValue();
    expect(map.keys.map((k) => k.toStringValue()), ['a', 'b', 'c']);
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
    CompilationUnitElement compilationUnitElement =
        ElementFactory.compilationUnit('/test.dart', _source)..source = _source;
    ElementFactory.library(_context, 'L').definingCompilationUnit =
        compilationUnitElement;
    ElementAnnotationImpl elementAnnotation =
        new ElementAnnotationImpl(compilationUnitElement);
    _node = elementAnnotation.annotationAst = AstFactory.annotation(
        AstFactory.identifier3('x'))..elementAnnotation = elementAnnotation;
    expect(_findAnnotations(), contains(_node));
  }

  /**
   * Test an annotation that represents the invocation of a constant
   * constructor.
   */
  void test_visitAnnotation_invocation() {
    CompilationUnitElement compilationUnitElement =
        ElementFactory.compilationUnit('/test.dart', _source)..source = _source;
    ElementFactory.library(_context, 'L').definingCompilationUnit =
        compilationUnitElement;
    ElementAnnotationImpl elementAnnotation =
        new ElementAnnotationImpl(compilationUnitElement);
    _node = elementAnnotation.annotationAst = AstFactory.annotation2(
        AstFactory.identifier3('A'), null, AstFactory.argumentList())
      ..elementAnnotation = elementAnnotation;
    expect(_findAnnotations(), contains(_node));
  }

  void test_visitAnnotation_partOf() {
    // Analyzer ignores annotations on "part of" directives.
    Annotation annotation = AstFactory.annotation2(
        AstFactory.identifier3('A'), null, AstFactory.argumentList());
    _node = AstFactory.partOfDirective2(
        <Annotation>[annotation], AstFactory.libraryIdentifier2(<String>['L']));
    expect(_findConstants(), isEmpty);
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
      if (target is ElementAnnotationImpl) {
        expect(target.context, same(_context));
        expect(target.source, same(_source));
        annotations.add(target.annotationAst);
      }
    }
    return new List<Annotation>.from(annotations);
  }

  List<ConstantEvaluationTarget> _findConstants() {
    ConstantFinder finder = new ConstantFinder(_context, _source, _source);
    _node.accept(finder);
    List<ConstantEvaluationTarget> constants = finder.constantsToCompute;
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

  void test_annotation_topLevelVariable() {
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

  void test_annotation_topLevelVariable_args() {
    // Applying arguments to an annotation that is a top-level variable is
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

  void test_instanceCreationExpression_computedField_usesTopLevelConst() {
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

  void test_instanceCreationExpression_redirect_external() {
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
    expect(result, isNotNull);
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
class DartObjectImplTest extends EngineTestCase {
  TypeProvider _typeProvider = new TestTypeProvider();

  void test_add_knownDouble_knownDouble() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_add_knownDouble_knownInt() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _intValue(2));
  }

  void test_add_knownDouble_unknownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_add_knownDouble_unknownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_add_knownInt_knownInt() {
    _assertAdd(_intValue(3), _intValue(1), _intValue(2));
  }

  void test_add_knownInt_knownString() {
    _assertAdd(null, _intValue(1), _stringValue("2"));
  }

  void test_add_knownInt_unknownDouble() {
    _assertAdd(_doubleValue(null), _intValue(1), _doubleValue(null));
  }

  void test_add_knownInt_unknownInt() {
    _assertAdd(_intValue(null), _intValue(1), _intValue(null));
  }

  void test_add_knownString_knownInt() {
    _assertAdd(null, _stringValue("1"), _intValue(2));
  }

  void test_add_knownString_knownString() {
    _assertAdd(_stringValue("ab"), _stringValue("a"), _stringValue("b"));
  }

  void test_add_knownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue("a"), _stringValue(null));
  }

  void test_add_unknownDouble_knownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_add_unknownDouble_knownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_add_unknownInt_knownDouble() {
    _assertAdd(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_add_unknownInt_knownInt() {
    _assertAdd(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_add_unknownString_knownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue("b"));
  }

  void test_add_unknownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue(null));
  }

  void test_bitAnd_knownInt_knownInt() {
    _assertBitAnd(_intValue(2), _intValue(6), _intValue(3));
  }

  void test_bitAnd_knownInt_knownString() {
    _assertBitAnd(null, _intValue(6), _stringValue("3"));
  }

  void test_bitAnd_knownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitAnd_knownString_knownInt() {
    _assertBitAnd(null, _stringValue("6"), _intValue(3));
  }

  void test_bitAnd_unknownInt_knownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitAnd_unknownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitNot_knownInt() {
    _assertBitNot(_intValue(-4), _intValue(3));
  }

  void test_bitNot_knownString() {
    _assertBitNot(null, _stringValue("6"));
  }

  void test_bitNot_unknownInt() {
    _assertBitNot(_intValue(null), _intValue(null));
  }

  void test_bitOr_knownInt_knownInt() {
    _assertBitOr(_intValue(7), _intValue(6), _intValue(3));
  }

  void test_bitOr_knownInt_knownString() {
    _assertBitOr(null, _intValue(6), _stringValue("3"));
  }

  void test_bitOr_knownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitOr_knownString_knownInt() {
    _assertBitOr(null, _stringValue("6"), _intValue(3));
  }

  void test_bitOr_unknownInt_knownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitOr_unknownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitXor_knownInt_knownInt() {
    _assertBitXor(_intValue(5), _intValue(6), _intValue(3));
  }

  void test_bitXor_knownInt_knownString() {
    _assertBitXor(null, _intValue(6), _stringValue("3"));
  }

  void test_bitXor_knownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitXor_knownString_knownInt() {
    _assertBitXor(null, _stringValue("6"), _intValue(3));
  }

  void test_bitXor_unknownInt_knownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitXor_unknownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_concatenate_knownInt_knownString() {
    _assertConcatenate(null, _intValue(2), _stringValue("def"));
  }

  void test_concatenate_knownString_knownInt() {
    _assertConcatenate(null, _stringValue("abc"), _intValue(3));
  }

  void test_concatenate_knownString_knownString() {
    _assertConcatenate(
        _stringValue("abcdef"), _stringValue("abc"), _stringValue("def"));
  }

  void test_concatenate_knownString_unknownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue("abc"), _stringValue(null));
  }

  void test_concatenate_unknownString_knownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_divide_knownDouble_knownDouble() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_divide_knownDouble_knownInt() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _intValue(2));
  }

  void test_divide_knownDouble_unknownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_divide_knownDouble_unknownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_divide_knownInt_knownInt() {
    _assertDivide(_doubleValue(3.0), _intValue(6), _intValue(2));
  }

  void test_divide_knownInt_knownString() {
    _assertDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_divide_knownInt_unknownDouble() {
    _assertDivide(_doubleValue(null), _intValue(6), _doubleValue(null));
  }

  void test_divide_knownInt_unknownInt() {
    _assertDivide(_doubleValue(null), _intValue(6), _intValue(null));
  }

  void test_divide_knownString_knownInt() {
    _assertDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_divide_unknownDouble_knownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownDouble_knownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_divide_unknownInt_knownDouble() {
    _assertDivide(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownInt_knownInt() {
    _assertDivide(_doubleValue(null), _intValue(null), _intValue(2));
  }

  void test_equalEqual_bool_false() {
    _assertEqualEqual(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_equalEqual_bool_true() {
    _assertEqualEqual(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_equalEqual_bool_unknown() {
    _assertEqualEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_equalEqual_double_false() {
    _assertEqualEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_equalEqual_double_true() {
    _assertEqualEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_equalEqual_double_unknown() {
    _assertEqualEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_equalEqual_int_false() {
    _assertEqualEqual(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_equalEqual_int_true() {
    _assertEqualEqual(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_equalEqual_int_unknown() {
    _assertEqualEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_equalEqual_list_empty() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_list_false() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_map_empty() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_map_false() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_null() {
    _assertEqualEqual(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_equalEqual_string_false() {
    _assertEqualEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_equalEqual_string_true() {
    _assertEqualEqual(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_equalEqual_string_unknown() {
    _assertEqualEqual(
        _boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_equals_list_false_differentSizes() {
    expect(
        _listValue([_boolValue(true)]) ==
            _listValue([_boolValue(true), _boolValue(false)]),
        isFalse);
  }

  void test_equals_list_false_sameSize() {
    expect(_listValue([_boolValue(true)]) == _listValue([_boolValue(false)]),
        isFalse);
  }

  void test_equals_list_true_empty() {
    expect(_listValue(), _listValue());
  }

  void test_equals_list_true_nonEmpty() {
    expect(_listValue([_boolValue(true)]), _listValue([_boolValue(true)]));
  }

  void test_equals_map_true_empty() {
    expect(_mapValue(), _mapValue());
  }

  void test_equals_symbol_false() {
    expect(_symbolValue("a") == _symbolValue("b"), isFalse);
  }

  void test_equals_symbol_true() {
    expect(_symbolValue("a"), _symbolValue("a"));
  }

  void test_getValue_bool_false() {
    expect(_boolValue(false).toBoolValue(), false);
  }

  void test_getValue_bool_true() {
    expect(_boolValue(true).toBoolValue(), true);
  }

  void test_getValue_bool_unknown() {
    expect(_boolValue(null).toBoolValue(), isNull);
  }

  void test_getValue_double_known() {
    double value = 2.3;
    expect(_doubleValue(value).toDoubleValue(), value);
  }

  void test_getValue_double_unknown() {
    expect(_doubleValue(null).toDoubleValue(), isNull);
  }

  void test_getValue_int_known() {
    int value = 23;
    expect(_intValue(value).toIntValue(), value);
  }

  void test_getValue_int_unknown() {
    expect(_intValue(null).toIntValue(), isNull);
  }

  void test_getValue_list_empty() {
    Object result = _listValue().toListValue();
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(0));
  }

  void test_getValue_list_valid() {
    Object result = _listValue([_intValue(23)]).toListValue();
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(1));
  }

  void test_getValue_map_empty() {
    Object result = _mapValue().toMapValue();
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(0));
  }

  void test_getValue_map_valid() {
    Object result =
        _mapValue([_stringValue("key"), _stringValue("value")]).toMapValue();
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(1));
  }

  void test_getValue_null() {
    expect(_nullValue().isNull, isTrue);
  }

  void test_getValue_string_known() {
    String value = "twenty-three";
    expect(_stringValue(value).toStringValue(), value);
  }

  void test_getValue_string_unknown() {
    expect(_stringValue(null).toStringValue(), isNull);
  }

  void test_greaterThan_knownDouble_knownDouble_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThan_knownDouble_knownDouble_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThan_knownDouble_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThan_knownDouble_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThan_knownDouble_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThan_knownDouble_unknownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThan_knownInt_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThan_knownInt_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _intValue(2), _intValue(1));
  }

  void test_greaterThan_knownInt_knownString() {
    _assertGreaterThan(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThan_knownInt_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThan_knownInt_unknownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThan_knownString_knownInt() {
    _assertGreaterThan(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThan_unknownDouble_knownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownDouble_knownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThan_unknownInt_knownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownInt_knownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThanOrEqual_knownDouble_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownDouble_unknownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_false() {
    _assertGreaterThanOrEqual(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_true() {
    _assertGreaterThanOrEqual(_boolValue(true), _intValue(2), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownString() {
    _assertGreaterThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThanOrEqual_knownInt_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownInt_unknownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThanOrEqual_knownString_knownInt() {
    _assertGreaterThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownDouble_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownDouble_knownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownInt_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownInt_knownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_hasKnownValue_bool_false() {
    expect(_boolValue(false).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_bool_true() {
    expect(_boolValue(true).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_bool_unknown() {
    expect(_boolValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_double_known() {
    expect(_doubleValue(2.3).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_double_unknown() {
    expect(_doubleValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_dynamic() {
    expect(_dynamicValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_int_known() {
    expect(_intValue(23).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_int_unknown() {
    expect(_intValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_list_empty() {
    expect(_listValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_list_invalidElement() {
    expect(_listValue([_dynamicValue]).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_list_valid() {
    expect(_listValue([_intValue(23)]).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_map_empty() {
    expect(_mapValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_map_invalidKey() {
    expect(_mapValue([_dynamicValue(), _stringValue("value")]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_map_invalidValue() {
    expect(_mapValue([_stringValue("key"), _dynamicValue()]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_map_valid() {
    expect(
        _mapValue([_stringValue("key"), _stringValue("value")]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_null() {
    expect(_nullValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_num() {
    expect(_numValue().hasKnownValue, isFalse);
  }

  void test_hasKnownValue_string_known() {
    expect(_stringValue("twenty-three").hasKnownValue, isTrue);
  }

  void test_hasKnownValue_string_unknown() {
    expect(_stringValue(null).hasKnownValue, isFalse);
  }

  void test_identical_bool_false() {
    _assertIdentical(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_identical_bool_true() {
    _assertIdentical(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_identical_bool_unknown() {
    _assertIdentical(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_identical_double_false() {
    _assertIdentical(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_identical_double_true() {
    _assertIdentical(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_identical_double_unknown() {
    _assertIdentical(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_identical_int_false() {
    _assertIdentical(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_identical_int_true() {
    _assertIdentical(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_identical_int_unknown() {
    _assertIdentical(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_identical_list_empty() {
    _assertIdentical(_boolValue(true), _listValue(), _listValue());
  }

  void test_identical_list_false() {
    _assertIdentical(
        _boolValue(false), _listValue(), _listValue([_intValue(3)]));
  }

  void test_identical_map_empty() {
    _assertIdentical(_boolValue(true), _mapValue(), _mapValue());
  }

  void test_identical_map_false() {
    _assertIdentical(_boolValue(false), _mapValue(),
        _mapValue([_intValue(1), _intValue(2)]));
  }

  void test_identical_null() {
    _assertIdentical(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_identical_string_false() {
    _assertIdentical(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_identical_string_true() {
    _assertIdentical(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_identical_string_unknown() {
    _assertIdentical(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_integerDivide_knownDouble_knownDouble() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_integerDivide_knownDouble_knownInt() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _intValue(2));
  }

  void test_integerDivide_knownDouble_unknownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_integerDivide_knownDouble_unknownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_integerDivide_knownInt_knownInt() {
    _assertIntegerDivide(_intValue(3), _intValue(6), _intValue(2));
  }

  void test_integerDivide_knownInt_knownString() {
    _assertIntegerDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_integerDivide_knownInt_unknownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _doubleValue(null));
  }

  void test_integerDivide_knownInt_unknownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_integerDivide_knownString_knownInt() {
    _assertIntegerDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_integerDivide_unknownDouble_knownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownDouble_knownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(null), _intValue(2));
  }

  void test_integerDivide_unknownInt_knownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownInt_knownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_isBoolNumStringOrNull_bool_false() {
    expect(_boolValue(false).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_true() {
    expect(_boolValue(true).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_unknown() {
    expect(_boolValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_known() {
    expect(_doubleValue(2.3).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_unknown() {
    expect(_doubleValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_dynamic() {
    expect(_dynamicValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_known() {
    expect(_intValue(23).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_unknown() {
    expect(_intValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_list() {
    expect(_listValue().isBoolNumStringOrNull, isFalse);
  }

  void test_isBoolNumStringOrNull_null() {
    expect(_nullValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_num() {
    expect(_numValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_known() {
    expect(_stringValue("twenty-three").isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_unknown() {
    expect(_stringValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_lessThan_knownDouble_knownDouble_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThan_knownDouble_knownDouble_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThan_knownDouble_knownInt_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThan_knownDouble_knownInt_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThan_knownDouble_unknownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThan_knownDouble_unknownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThan_knownInt_knownInt_false() {
    _assertLessThan(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThan_knownInt_knownInt_true() {
    _assertLessThan(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThan_knownInt_knownString() {
    _assertLessThan(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThan_knownInt_unknownDouble() {
    _assertLessThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThan_knownInt_unknownInt() {
    _assertLessThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThan_knownString_knownInt() {
    _assertLessThan(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThan_unknownDouble_knownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownDouble_knownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThan_unknownInt_knownDouble() {
    _assertLessThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownInt_knownInt() {
    _assertLessThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_false() {
    _assertLessThanOrEqual(
        _boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_true() {
    _assertLessThanOrEqual(
        _boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_unknownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownDouble_unknownInt() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThanOrEqual_knownInt_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThanOrEqual_knownInt_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThanOrEqual_knownInt_knownString() {
    _assertLessThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThanOrEqual_knownInt_unknownDouble() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownInt_unknownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThanOrEqual_knownString_knownInt() {
    _assertLessThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThanOrEqual_unknownDouble_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownDouble_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_unknownInt_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownInt_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_logicalAnd_false_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalAnd_false_null() {
    try {
      _assertLogicalAnd(_boolValue(false), _boolValue(false), _nullValue());
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_false_string() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _boolValue(false), _stringValue("false"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_false_true() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_logicalAnd_null_false() {
    try {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_null_true() {
    try {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_string_false() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _stringValue("true"), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_string_true() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _stringValue("false"), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_true_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(true), _boolValue(false));
  }

  void test_logicalAnd_true_null() {
    _assertLogicalAnd(null, _boolValue(true), _nullValue());
  }

  void test_logicalAnd_true_string() {
    try {
      _assertLogicalAnd(
          _boolValue(false), _boolValue(true), _stringValue("true"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalAnd_true_true() {
    _assertLogicalAnd(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_logicalNot_false() {
    _assertLogicalNot(_boolValue(true), _boolValue(false));
  }

  void test_logicalNot_null() {
    _assertLogicalNot(null, _nullValue());
  }

  void test_logicalNot_string() {
    try {
      _assertLogicalNot(_boolValue(true), _stringValue(null));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalNot_true() {
    _assertLogicalNot(_boolValue(false), _boolValue(true));
  }

  void test_logicalNot_unknown() {
    _assertLogicalNot(_boolValue(null), _boolValue(null));
  }

  void test_logicalOr_false_false() {
    _assertLogicalOr(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalOr_false_null() {
    _assertLogicalOr(null, _boolValue(false), _nullValue());
  }

  void test_logicalOr_false_string() {
    try {
      _assertLogicalOr(
          _boolValue(false), _boolValue(false), _stringValue("false"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_false_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_logicalOr_null_false() {
    try {
      _assertLogicalOr(_boolValue(false), _nullValue(), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_null_true() {
    try {
      _assertLogicalOr(_boolValue(true), _nullValue(), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_string_false() {
    try {
      _assertLogicalOr(
          _boolValue(false), _stringValue("true"), _boolValue(false));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_string_true() {
    try {
      _assertLogicalOr(
          _boolValue(true), _stringValue("false"), _boolValue(true));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_true_false() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(false));
  }

  void test_logicalOr_true_null() {
    try {
      _assertLogicalOr(_boolValue(true), _boolValue(true), _nullValue());
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_true_string() {
    try {
      _assertLogicalOr(
          _boolValue(true), _boolValue(true), _stringValue("true"));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_logicalOr_true_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_minus_knownDouble_knownDouble() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _doubleValue(3.0));
  }

  void test_minus_knownDouble_knownInt() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _intValue(3));
  }

  void test_minus_knownDouble_unknownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _doubleValue(null));
  }

  void test_minus_knownDouble_unknownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _intValue(null));
  }

  void test_minus_knownInt_knownInt() {
    _assertMinus(_intValue(1), _intValue(4), _intValue(3));
  }

  void test_minus_knownInt_knownString() {
    _assertMinus(null, _intValue(4), _stringValue("3"));
  }

  void test_minus_knownInt_unknownDouble() {
    _assertMinus(_doubleValue(null), _intValue(4), _doubleValue(null));
  }

  void test_minus_knownInt_unknownInt() {
    _assertMinus(_intValue(null), _intValue(4), _intValue(null));
  }

  void test_minus_knownString_knownInt() {
    _assertMinus(null, _stringValue("4"), _intValue(3));
  }

  void test_minus_unknownDouble_knownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownDouble_knownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_minus_unknownInt_knownDouble() {
    _assertMinus(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownInt_knownInt() {
    _assertMinus(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_negated_double_known() {
    _assertNegated(_doubleValue(2.0), _doubleValue(-2.0));
  }

  void test_negated_double_unknown() {
    _assertNegated(_doubleValue(null), _doubleValue(null));
  }

  void test_negated_int_known() {
    _assertNegated(_intValue(-3), _intValue(3));
  }

  void test_negated_int_unknown() {
    _assertNegated(_intValue(null), _intValue(null));
  }

  void test_negated_string() {
    _assertNegated(null, _stringValue(null));
  }

  void test_notEqual_bool_false() {
    _assertNotEqual(_boolValue(false), _boolValue(true), _boolValue(true));
  }

  void test_notEqual_bool_true() {
    _assertNotEqual(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_notEqual_bool_unknown() {
    _assertNotEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_notEqual_double_false() {
    _assertNotEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_notEqual_double_true() {
    _assertNotEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_notEqual_double_unknown() {
    _assertNotEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_notEqual_int_false() {
    _assertNotEqual(_boolValue(false), _intValue(5), _intValue(5));
  }

  void test_notEqual_int_true() {
    _assertNotEqual(_boolValue(true), _intValue(-5), _intValue(5));
  }

  void test_notEqual_int_unknown() {
    _assertNotEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_notEqual_null() {
    _assertNotEqual(_boolValue(false), _nullValue(), _nullValue());
  }

  void test_notEqual_string_false() {
    _assertNotEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("abc"));
  }

  void test_notEqual_string_true() {
    _assertNotEqual(_boolValue(true), _stringValue("abc"), _stringValue("def"));
  }

  void test_notEqual_string_unknown() {
    _assertNotEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_performToString_bool_false() {
    _assertPerformToString(_stringValue("false"), _boolValue(false));
  }

  void test_performToString_bool_true() {
    _assertPerformToString(_stringValue("true"), _boolValue(true));
  }

  void test_performToString_bool_unknown() {
    _assertPerformToString(_stringValue(null), _boolValue(null));
  }

  void test_performToString_double_known() {
    _assertPerformToString(_stringValue("2.0"), _doubleValue(2.0));
  }

  void test_performToString_double_unknown() {
    _assertPerformToString(_stringValue(null), _doubleValue(null));
  }

  void test_performToString_int_known() {
    _assertPerformToString(_stringValue("5"), _intValue(5));
  }

  void test_performToString_int_unknown() {
    _assertPerformToString(_stringValue(null), _intValue(null));
  }

  void test_performToString_null() {
    _assertPerformToString(_stringValue("null"), _nullValue());
  }

  void test_performToString_string_known() {
    _assertPerformToString(_stringValue("abc"), _stringValue("abc"));
  }

  void test_performToString_string_unknown() {
    _assertPerformToString(_stringValue(null), _stringValue(null));
  }

  void test_remainder_knownDouble_knownDouble() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _doubleValue(2.0));
  }

  void test_remainder_knownDouble_knownInt() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _intValue(2));
  }

  void test_remainder_knownDouble_unknownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(7.0), _doubleValue(null));
  }

  void test_remainder_knownDouble_unknownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_remainder_knownInt_knownInt() {
    _assertRemainder(_intValue(1), _intValue(7), _intValue(2));
  }

  void test_remainder_knownInt_knownString() {
    _assertRemainder(null, _intValue(7), _stringValue("2"));
  }

  void test_remainder_knownInt_unknownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(7), _doubleValue(null));
  }

  void test_remainder_knownInt_unknownInt() {
    _assertRemainder(_intValue(null), _intValue(7), _intValue(null));
  }

  void test_remainder_knownString_knownInt() {
    _assertRemainder(null, _stringValue("7"), _intValue(2));
  }

  void test_remainder_unknownDouble_knownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownDouble_knownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_remainder_unknownInt_knownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownInt_knownInt() {
    _assertRemainder(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_shiftLeft_knownInt_knownInt() {
    _assertShiftLeft(_intValue(48), _intValue(6), _intValue(3));
  }

  void test_shiftLeft_knownInt_knownString() {
    _assertShiftLeft(null, _intValue(6), _stringValue(null));
  }

  void test_shiftLeft_knownInt_tooLarge() {
    _assertShiftLeft(
        _intValue(null),
        _intValue(6),
        new DartObjectImpl(
            _typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftLeft_knownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_shiftLeft_knownString_knownInt() {
    _assertShiftLeft(null, _stringValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_knownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_shiftRight_knownInt_knownInt() {
    _assertShiftRight(_intValue(6), _intValue(48), _intValue(3));
  }

  void test_shiftRight_knownInt_knownString() {
    _assertShiftRight(null, _intValue(48), _stringValue(null));
  }

  void test_shiftRight_knownInt_tooLarge() {
    _assertShiftRight(
        _intValue(null),
        _intValue(48),
        new DartObjectImpl(
            _typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftRight_knownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(48), _intValue(null));
  }

  void test_shiftRight_knownString_knownInt() {
    _assertShiftRight(null, _stringValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_knownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_stringLength_int() {
    try {
      _assertStringLength(_intValue(null), _intValue(0));
      fail("Expected EvaluationException");
    } on EvaluationException {}
  }

  void test_stringLength_knownString() {
    _assertStringLength(_intValue(3), _stringValue("abc"));
  }

  void test_stringLength_unknownString() {
    _assertStringLength(_intValue(null), _stringValue(null));
  }

  void test_times_knownDouble_knownDouble() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _doubleValue(3.0));
  }

  void test_times_knownDouble_knownInt() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _intValue(3));
  }

  void test_times_knownDouble_unknownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _doubleValue(null));
  }

  void test_times_knownDouble_unknownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _intValue(null));
  }

  void test_times_knownInt_knownInt() {
    _assertTimes(_intValue(6), _intValue(2), _intValue(3));
  }

  void test_times_knownInt_knownString() {
    _assertTimes(null, _intValue(2), _stringValue("3"));
  }

  void test_times_knownInt_unknownDouble() {
    _assertTimes(_doubleValue(null), _intValue(2), _doubleValue(null));
  }

  void test_times_knownInt_unknownInt() {
    _assertTimes(_intValue(null), _intValue(2), _intValue(null));
  }

  void test_times_knownString_knownInt() {
    _assertTimes(null, _stringValue("2"), _intValue(3));
  }

  void test_times_unknownDouble_knownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_times_unknownDouble_knownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_times_unknownInt_knownDouble() {
    _assertTimes(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_times_unknownInt_knownInt() {
    _assertTimes(_intValue(null), _intValue(null), _intValue(3));
  }

  /**
   * Assert that the result of adding the left and right operands is the expected value, or that the
   * operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertAdd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.add(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.add(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-anding the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitAnd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitAnd(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.bitAnd(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the bit-not of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.bitNot(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.bitNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-oring the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitOr(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitOr(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.bitOr(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-xoring the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertBitXor(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.bitXor(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.bitXor(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of concatenating the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertConcatenate(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.concatenate(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.concatenate(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of dividing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertDivide(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.divide(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.divide(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands for equality is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertEqualEqual(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.equalEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.equalEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertGreaterThan(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.greaterThan(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.greaterThan(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertGreaterThanOrEqual(DartObjectImpl expected,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.greaterThanOrEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands using
   * identical() is the expected value.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   */
  void _assertIdentical(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    DartObjectImpl result =
        leftOperand.isIdentical(_typeProvider, rightOperand);
    expect(result, isNotNull);
    expect(result, expected);
  }

  void _assertInstanceOfObjectArray(Object result) {
    // TODO(scheglov) implement
  }

  /**
   * Assert that the result of dividing the left and right operands as integers is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertIntegerDivide(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.integerDivide(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.integerDivide(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLessThan(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.lessThan(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.lessThan(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands is the expected value, or that
   * the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLessThanOrEqual(DartObjectImpl expected,
      DartObjectImpl leftOperand, DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.lessThanOrEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-anding the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalAnd(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.logicalAnd(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.logicalAnd(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the logical-not of the operand is the expected value, or that the operation throws
   * an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.logicalNot(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.logicalNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-oring the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertLogicalOr(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.logicalOr(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.logicalOr(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of subtracting the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertMinus(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.minus(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.minus(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the negation of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertNegated(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.negated(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.negated(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the left and right operands for inequality is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertNotEqual(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.notEqual(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.notEqual(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that converting the operand to a string is the expected value, or that the operation
   * throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertPerformToString(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.performToString(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.performToString(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of taking the remainder of the left and right operands is the expected
   * value, or that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertRemainder(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.remainder(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.remainder(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertShiftLeft(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.shiftLeft(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.shiftLeft(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the right operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertShiftRight(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.shiftRight(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result =
          leftOperand.shiftRight(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the length of the operand is the expected value, or that the operation throws an
   * exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param operand the operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertStringLength(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      try {
        operand.stringLength(_typeProvider);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = operand.stringLength(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the left and right operands is the expected value, or
   * that the operation throws an exception if the expected value is `null`.
   *
   * @param expected the expected result of the operation
   * @param leftOperand the left operand to the operation
   * @param rightOperand the left operand to the operation
   * @throws EvaluationException if the result is an exception when it should not be
   */
  void _assertTimes(DartObjectImpl expected, DartObjectImpl leftOperand,
      DartObjectImpl rightOperand) {
    if (expected == null) {
      try {
        leftOperand.times(_typeProvider, rightOperand);
        fail("Expected an EvaluationException");
      } on EvaluationException {}
    } else {
      DartObjectImpl result = leftOperand.times(_typeProvider, rightOperand);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  DartObjectImpl _boolValue(bool value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.boolType, BoolState.UNKNOWN_VALUE);
    } else if (identical(value, false)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.FALSE_STATE);
    } else if (identical(value, true)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.TRUE_STATE);
    }
    fail("Invalid boolean value used in test");
    return null;
  }

  DartObjectImpl _doubleValue(double value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.doubleType, new DoubleState(value));
    }
  }

  DartObjectImpl _dynamicValue() {
    return new DartObjectImpl(
        _typeProvider.nullType, DynamicState.DYNAMIC_STATE);
  }

  DartObjectImpl _intValue(int value) {
    if (value == null) {
      return new DartObjectImpl(_typeProvider.intType, IntState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(_typeProvider.intType, new IntState(value));
    }
  }

  DartObjectImpl _listValue(
      [List<DartObjectImpl> elements = DartObjectImpl.EMPTY_LIST]) {
    return new DartObjectImpl(_typeProvider.listType, new ListState(elements));
  }

  DartObjectImpl _mapValue(
      [List<DartObjectImpl> keyElementPairs = DartObjectImpl.EMPTY_LIST]) {
    Map<DartObjectImpl, DartObjectImpl> map =
        new Map<DartObjectImpl, DartObjectImpl>();
    int count = keyElementPairs.length;
    for (int i = 0; i < count;) {
      map[keyElementPairs[i++]] = keyElementPairs[i++];
    }
    return new DartObjectImpl(_typeProvider.mapType, new MapState(map));
  }

  DartObjectImpl _nullValue() {
    return new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
  }

  DartObjectImpl _numValue() {
    return new DartObjectImpl(_typeProvider.nullType, NumState.UNKNOWN_VALUE);
  }

  DartObjectImpl _stringValue(String value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.stringType, StringState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.stringType, new StringState(value));
    }
  }

  DartObjectImpl _symbolValue(String value) {
    return new DartObjectImpl(_typeProvider.symbolType, new SymbolState(value));
  }
}

@reflectiveTest
class DeclaredVariablesTest extends EngineTestCase {
  void test_getBool_false() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "false");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toBoolValue(), false);
  }

  void test_getBool_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "not true");
    _assertNullDartObject(
        typeProvider, variables.getBool(typeProvider, variableName));
  }

  void test_getBool_true() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "true");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toBoolValue(), true);
  }

  void test_getBool_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(
        typeProvider.boolType, variables.getBool(typeProvider, variableName));
  }

  void test_getInt_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "four score and seven years");
    _assertNullDartObject(
        typeProvider, variables.getInt(typeProvider, variableName));
  }

  void test_getInt_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(
        typeProvider.intType, variables.getInt(typeProvider, variableName));
  }

  void test_getInt_valid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "23");
    DartObject object = variables.getInt(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toIntValue(), 23);
  }

  void test_getString_defined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    String value = "value";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, value);
    DartObject object = variables.getString(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toStringValue(), value);
  }

  void test_getString_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(typeProvider.stringType,
        variables.getString(typeProvider, variableName));
  }

  void _assertNullDartObject(TestTypeProvider typeProvider, DartObject result) {
    expect(result.type, typeProvider.nullType);
  }

  void _assertUnknownDartObject(
      ParameterizedType expectedType, DartObject result) {
    expect((result as DartObjectImpl).isUnknown, isTrue);
    expect(result.type, expectedType);
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
