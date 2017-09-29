// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.dart.element.builder_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/element_search.dart';
import 'package:analyzer/src/generated/testing/node_search.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test.dart';
import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApiElementBuilderTest);
    defineReflectiveTests(ElementBuilderTest);
    defineReflectiveTests(LocalElementBuilderTest);
  });
}

@reflectiveTest
class ApiElementBuilderTest extends _BaseTest with _ApiElementBuilderTestMixin {
  @override
  AstVisitor createElementBuilder(ElementHolder holder) {
    return new ApiElementBuilder(holder, compilationUnitElement);
  }

  void test_api_class_field() {
    List<FieldElement> fields = buildElementsForText(r'''
class C {
  var a = 42;
  var b = () {
    int v = 0;
    localFunction() {}
  };
}
''').types[0].fields;
    expect(fields, hasLength(2));
    {
      FieldElement a = fields[0];
      expect(a.displayName, 'a');
      expect(a.initializer, isNull);
    }
    {
      FieldElement b = fields[1];
      expect(b.displayName, 'b');
      expect(b.initializer, isNull);
    }
  }

  void test_api_class_method_blockBody() {
    MethodElement method = buildElementsForText(r'''
class C {
  void m(int a, {int b: 42}) {
    int v = 0;
    localFunction() {}
  }
}
''').types[0].methods[0];
    {
      expect(method.parameters, hasLength(2));
      expect(method.parameters[0].displayName, 'a');
      expect(method.parameters[0].initializer, isNull);
      expect(method.parameters[1].displayName, 'b');
      expect(method.parameters[1].initializer, isNull);
    }
    expect(
        findDeclaredIdentifiersByName(compilationUnit, 'v')
            .single
            .staticElement,
        isNull);
    expect(
        findDeclaredIdentifiersByName(compilationUnit, 'localFunction')
            .single
            .staticElement,
        isNull);
  }

  void test_api_topLevelFunction_blockBody() {
    FunctionElement topLevelFunction = buildElementsForText(r'''
void topLevelFunction() {
  int v = 0;
  localFunction() {}
}
''').functions[0];
    expect(topLevelFunction, isNotNull);
    expect(topLevelFunction.name, 'topLevelFunction');
    expect(
        findDeclaredIdentifiersByName(compilationUnit, 'v')
            .single
            .staticElement,
        isNull);
    expect(
        findDeclaredIdentifiersByName(compilationUnit, 'localFunction')
            .single
            .staticElement,
        isNull);
  }

  void test_api_topLevelFunction_expressionBody() {
    FunctionElement topLevelFunction = buildElementsForText(r'''
topLevelFunction() => () {
  int localVar = 0;
};
''').functions[0];
    expect(topLevelFunction, isNotNull);
    expect(topLevelFunction.name, 'topLevelFunction');
    expect(
        findDeclaredIdentifiersByName(compilationUnit, 'localVar')
            .single
            .staticElement,
        isNull);
  }

  void test_api_topLevelFunction_parameters() {
    FunctionElement function = buildElementsForText(r'''
void topLevelFunction(int a, int b(double b2), {c: () {int c2; c3() {} }}) {
}
''').functions[0];
    List<ParameterElement> parameters = function.parameters;
    expect(parameters, hasLength(3));
    {
      ParameterElement a = parameters[0];
      expect(a.displayName, 'a');
      expect(a.initializer, isNull);
    }
    {
      ParameterElement b = parameters[1];
      expect(b.displayName, 'b');
      expect(b.initializer, isNull);
      var bTypeElement = b.type.element as GenericFunctionTypeElementImpl;
      expect(bTypeElement.parameters, hasLength(1));
      expect(bTypeElement.parameters[0].displayName, 'b2');
    }
    {
      var c = parameters[2] as DefaultParameterElementImpl;
      expect(c.displayName, 'c');
      expect(c.initializer, isNull);
    }
  }

  void test_api_topLevelVariable() {
    List<TopLevelVariableElement> variables = buildElementsForText(r'''
var A = 42;
var B = () {
  int v = 0;
  localFunction(int _) {}
};
''').topLevelVariables;
    expect(variables, hasLength(2));
    {
      TopLevelVariableElement a = variables[0];
      expect(a.displayName, 'A');
      expect(a.initializer, isNull);
    }
    {
      TopLevelVariableElement b = variables[1];
      expect(b.displayName, 'B');
      expect(b.initializer, isNull);
    }
  }
}

@reflectiveTest
class ElementBuilderTest extends _BaseTest with _ApiElementBuilderTestMixin {
  /**
   * Parse the given [code], pass it through [ElementBuilder], and return the
   * resulting [ElementHolder].
   */
  ElementHolder buildElementsForText(String code) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder, compilationUnitElement);
    _visitAstOfCode(code, builder);
    return holder;
  }

  AstVisitor createElementBuilder(ElementHolder holder) {
    return new ElementBuilder(holder, compilationUnitElement);
  }

  void fail_visitMethodDeclaration_setter_duplicate() {
    // https://github.com/dart-lang/sdk/issues/25601
    String code = r'''
class C {
  set zzz(x) {}
  set zzz(y) {}
}
''';
    ClassElement classElement = buildElementsForText(code).types[0];
    for (PropertyAccessorElement accessor in classElement.accessors) {
      expect(accessor.variable.setter, same(accessor));
    }
  }

  @override
  void setUp() {
    super.setUp();
    compilationUnitElement = new CompilationUnitElementImpl('test.dart');
  }

  void test_metadata_localVariableDeclaration() {
    var code = 'f() { @a int x, y; }';
    buildElementsForText(code);
    var x = findLocalVariable(code, 'x, ');
    var y = findLocalVariable(code, 'x, ');
    checkMetadata(x);
    checkMetadata(y);
    expect(x.metadata, same(y.metadata));
  }

  void test_metadata_visitDeclaredIdentifier() {
    var code = 'f() { for (@a var x in y) {} }';
    buildElementsForText(code);
    var x = findLocalVariable(code, 'x in');
    checkMetadata(x);
  }

  void test_visitCatchClause() {
    var code = 'f() { try {} catch (e, s) {} }';
    buildElementsForText(code);
    var e = findLocalVariable(code, 'e, ');
    var s = findLocalVariable(code, 's) {}');

    expect(e, isNotNull);
    expect(e.name, 'e');
    expect(e.hasImplicitType, isTrue);
    expect(e.isSynthetic, isFalse);
    expect(e.isConst, isFalse);
    expect(e.isFinal, isFalse);
    expect(e.initializer, isNull);
    _assertVisibleRange(e, 13, 28);

    expect(s, isNotNull);
    expect(s.name, 's');
    expect(s.isSynthetic, isFalse);
    expect(s.isConst, isFalse);
    expect(s.isFinal, isFalse);
    expect(s.initializer, isNull);
    _assertVisibleRange(s, 13, 28);
  }

  void test_visitCatchClause_withType() {
    var code = 'f() { try {} on E catch (e) {} }';
    buildElementsForText(code);
    var e = findLocalVariable(code, 'e) {}');
    expect(e, isNotNull);
    expect(e.name, 'e');
    expect(e.hasImplicitType, isFalse);
  }

  void test_visitCompilationUnit_codeRange() {
    TopLevelVariableDeclaration topLevelVariableDeclaration = AstTestFactory
        .topLevelVariableDeclaration(null, AstTestFactory.typeName4('int'),
            [AstTestFactory.variableDeclaration('V')]);
    CompilationUnit unit = astFactory.compilationUnit(
        topLevelVariableDeclaration.beginToken,
        null,
        [],
        [topLevelVariableDeclaration],
        topLevelVariableDeclaration.endToken);
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    unit.beginToken.offset = 10;
    unit.endToken.offset = 40;
    unit.accept(builder);

    assertHasCodeRange(compilationUnitElement, 0, 41);
  }

  void test_visitDeclaredIdentifier_noType() {
    var code = 'f() { for (var i in []) {} }';
    buildElementsForText(code);
    var variable = findLocalVariable(code, 'i in');
    assertHasCodeRange(variable, 11, 5);
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.isConst, isFalse);
    expect(variable.isDeprecated, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isOverride, isFalse);
    expect(variable.isPrivate, isFalse);
    expect(variable.isPublic, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.name, 'i');
  }

  void test_visitDeclaredIdentifier_type() {
    var code = 'f() { for (int i in []) {} }';
    buildElementsForText(code);
    var variable = findLocalVariable(code, 'i in');
    assertHasCodeRange(variable, 11, 5);
    expect(variable.hasImplicitType, isFalse);
    expect(variable.isConst, isFalse);
    expect(variable.isDeprecated, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isOverride, isFalse);
    expect(variable.isPrivate, isFalse);
    expect(variable.isPublic, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.name, 'i');
  }

  void test_visitDefaultFormalParameter_noType() {
    // p = 0
    String parameterName = 'p';
    DefaultFormalParameter formalParameter =
        AstTestFactory.positionalFormalParameter(
            AstTestFactory.simpleFormalParameter3(parameterName),
            AstTestFactory.integer(0));
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(formalParameter);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    assertHasCodeRange(parameter, 50, 31);
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.initializer, isNotNull);
    expect(parameter.initializer.type, isNotNull);
    expect(parameter.initializer.hasImplicitReturnType, isTrue);
    expect(parameter.isConst, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isInitializingFormal, isFalse);
    expect(parameter.isOverride, isFalse);
    expect(parameter.isPrivate, isFalse);
    expect(parameter.isPublic, isTrue);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
  }

  void test_visitDefaultFormalParameter_type() {
    // E p = 0
    String parameterName = 'p';
    DefaultFormalParameter formalParameter =
        AstTestFactory.namedFormalParameter(
            AstTestFactory.simpleFormalParameter4(
                AstTestFactory.typeName4('E'), parameterName),
            AstTestFactory.integer(0));

    ElementHolder holder = buildElementsForAst(formalParameter);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.initializer, isNotNull);
    expect(parameter.initializer.type, isNotNull);
    expect(parameter.initializer.hasImplicitReturnType, isTrue);
    expect(parameter.isConst, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isInitializingFormal, isFalse);
    expect(parameter.isOverride, isFalse);
    expect(parameter.isPrivate, isFalse);
    expect(parameter.isPublic, isTrue);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
  }

  void test_visitFunctionExpression() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    FunctionExpression expression = AstTestFactory.functionExpression2(
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    expression.accept(builder);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(expression.element, same(function));
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionExpression_inBlockBody() {
    buildElementsForText('f() { return () => 42; }');
    FunctionDeclaration f = compilationUnit.declarations[0];
    BlockFunctionBody fBody = f.functionExpression.body;
    ReturnStatement returnStatement = fBody.block.statements[0];
    FunctionExpression closure = returnStatement.expression;
    FunctionElement function = closure.element;
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionExpression_inExpressionBody() {
    buildElementsForText('f() => () => 42;');
    FunctionDeclaration f = compilationUnit.declarations[0];
    ExpressionFunctionBody fBody = f.functionExpression.body;
    FunctionExpression closure = fBody.expression;
    FunctionElement function = closure.element;
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionTypeAlias() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    String parameterName = "E";
    FunctionTypeAlias aliasNode = AstTestFactory.typeAlias(null, aliasName,
        AstTestFactory.typeParameterList([parameterName]), null);
    aliasNode.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    aliasNode.endToken.offset = 80;
    aliasNode.accept(builder);

    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    assertHasCodeRange(alias, 50, 31);
    expect(alias.documentationComment, '/// aaa');
    expect(alias.name, aliasName);
    expect(alias.parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, parameterName);
  }

  void test_visitFunctionTypedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstTestFactory.functionTypedFormalParameter(null, parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitFunctionTypedFormalParameter_covariant() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameterImpl formalParameter =
        AstTestFactory.functionTypedFormalParameter(null, parameterName);
    formalParameter.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElementImpl parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isExplicitlyCovariant, isTrue);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitFunctionTypedFormalParameter_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstTestFactory.functionTypedFormalParameter(null, parameterName);
    formalParameter.typeParameters = AstTestFactory.typeParameterList(['F']);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));

    ParameterElement parameter = parameters[0];
    var typeElement = parameter.type.element as GenericFunctionTypeElementImpl;
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(typeElement.typeParameters, hasLength(1));
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitLabeledStatement() {
    String code = 'f() { l: print(42); }';
    buildElementsForText(code);
    LabelElement label = findLabel(code, 'l:');
    expect(label, isNotNull);
    expect(label.name, 'l');
    expect(label.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_withMembers() {
    var code = 'class C { m(p) { var v; try { l: return; } catch (e) {} } }';
    MethodElement method = buildElementsForText(code).types[0].methods[0];
    String methodName = "m";
    String parameterName = "p";
    String labelName = "l";
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
    List<VariableElement> parameters = method.parameters;
    expect(parameters, hasLength(1));
    VariableElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);

    var v = findLocalVariable(code, 'v;');
    expect(v.name, 'v');

    var e = findLocalVariable(code, 'e) {}');
    expect(e.name, 'e');

    LabelElement label = findLabel(code, 'l:');
    expect(label, isNotNull);
    expect(label.name, labelName);
  }

  void test_visitNamedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    DefaultFormalParameter formalParameter =
        AstTestFactory.namedFormalParameter(
            AstTestFactory.simpleFormalParameter3(parameterName),
            AstTestFactory.identifier3("42"));
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    assertHasCodeRange(parameter, 50, 32);
    expect(parameter.name, parameterName);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.NAMED);
    _assertVisibleRange(parameter, 100, 110);
    expect(parameter.defaultValueCode, "42");
    FunctionElement initializer = parameter.initializer;
    expect(initializer, isNotNull);
    expect(initializer.isSynthetic, isTrue);
    expect(initializer.hasImplicitReturnType, isTrue);
  }

  void test_visitNamedFormalParameter_covariant() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    DefaultFormalParameter formalParameter =
        AstTestFactory.namedFormalParameter(
            AstTestFactory.simpleFormalParameter3(parameterName),
            AstTestFactory.identifier3("42"));
    (formalParameter.parameter as NormalFormalParameterImpl).covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElementImpl parameter = parameters[0];
    expect(parameter, isNotNull);
    assertHasCodeRange(parameter, 50, 32);
    expect(parameter.name, parameterName);
    expect(parameter.isConst, isFalse);
    expect(parameter.isExplicitlyCovariant, isTrue);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.NAMED);
    _assertVisibleRange(parameter, 100, 110);
    expect(parameter.defaultValueCode, "42");
    FunctionElement initializer = parameter.initializer;
    expect(initializer, isNotNull);
    expect(initializer.isSynthetic, isTrue);
    expect(initializer.hasImplicitReturnType, isTrue);
  }

  void test_visitSimpleFormalParameter_noType() {
    // p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter =
        AstTestFactory.simpleFormalParameter3(parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitSimpleFormalParameter_noType_covariant() {
    // p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameterImpl formalParameter =
        AstTestFactory.simpleFormalParameter3(parameterName);
    formalParameter.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElementImpl parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isExplicitlyCovariant, isTrue);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitSimpleFormalParameter_type() {
    // T p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter = AstTestFactory
        .simpleFormalParameter4(AstTestFactory.typeName4('T'), parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    // T p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameterImpl formalParameter = AstTestFactory
        .simpleFormalParameter4(AstTestFactory.typeName4('T'), parameterName);
    formalParameter.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElementImpl parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isExplicitlyCovariant, isTrue);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitVariableDeclaration_field_covariant() {
    // covariant int f;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String fieldName = "f";
    VariableDeclarationImpl variableDeclaration =
        AstTestFactory.variableDeclaration2(fieldName, null);
    FieldDeclarationImpl fieldDeclaration = AstTestFactory.fieldDeclaration(
        false,
        null,
        AstTestFactory.typeName4('int'),
        <VariableDeclaration>[variableDeclaration]);
    fieldDeclaration.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    variableDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElementImpl field = fields[0];
    expect(field, isNotNull);
    PropertyAccessorElementImpl setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.parameters[0].isCovariant, isTrue);
  }

  void test_visitVariableDeclaration_inConstructor() {
    var code = 'class C { C() { var v = 1; } }';
    buildElementsForText(code);
    var v = findLocalVariable(code, 'v =');
    assertHasCodeRange(v, 16, 10);
    expect(v.hasImplicitType, isTrue);
    expect(v.name, 'v');
    _assertVisibleRange(v, 14, 28);
  }

  void test_visitVariableDeclaration_inForEachStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() { for (var v in []) }
    //
    String variableName = "v";
    DeclaredIdentifier variableIdentifier =
        AstTestFactory.declaredIdentifier3('v');
    Statement statement = AstTestFactory.forEachStatement(variableIdentifier,
        AstTestFactory.listLiteral(), AstTestFactory.block());
    _setNodeSourceRange(statement, 100, 110);
    MethodDeclaration method = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 200, 220);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    LocalVariableElement variableElement = variableIdentifier.element;
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_inForStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() { for (T v;;) }
    //
    String variableName = "v";
    VariableDeclaration variableIdentifier =
        AstTestFactory.variableDeclaration('v');
    ForStatement statement = AstTestFactory.forStatement2(
        AstTestFactory.variableDeclarationList(
            null, AstTestFactory.typeName4('T'), [variableIdentifier]),
        null,
        null,
        AstTestFactory.block());
    _setNodeSourceRange(statement, 100, 110);
    MethodDeclaration method = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 200, 220);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    LocalVariableElement variableElement = variableIdentifier.element;
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_inMethod() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() {T v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstTestFactory.variableDeclaration2(variableName, null);
    Statement statement = AstTestFactory.variableDeclarationStatement(
        null, AstTestFactory.typeName4('T'), [variable]);
    MethodDeclaration method = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 100, 110);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    LocalVariableElement variableElement = variable.element;
    expect(variableElement.hasImplicitType, isFalse);
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_localNestedInFunction() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // var f = () {var v;};
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstTestFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstTestFactory.variableDeclarationStatement2(null, [variable]);
    FunctionExpression initializer = AstTestFactory.functionExpression2(
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2([statement]));
    String fieldName = "f";
    VariableDeclaration field =
        AstTestFactory.variableDeclaration2(fieldName, initializer);
    FieldDeclaration fieldDeclaration =
        AstTestFactory.fieldDeclaration2(false, null, [field]);
    fieldDeclaration.accept(builder);

    List<FieldElement> variables = holder.fields;
    expect(variables, hasLength(1));
    FieldElement fieldElement = variables[0];
    expect(fieldElement, isNotNull);
    FunctionElement initializerElement = fieldElement.initializer;
    expect(initializerElement, isNotNull);
    expect(initializerElement.hasImplicitReturnType, isTrue);
    expect(initializer.element, new isInstanceOf<FunctionElement>());
    LocalVariableElement variableElement = variable.element;
    expect(variableElement.hasImplicitType, isTrue);
    expect(variableElement.isConst, isFalse);
    expect(variableElement.isFinal, isFalse);
    expect(variableElement.isSynthetic, isFalse);
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_noInitializer() {
    // var v;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstTestFactory.variableDeclaration2(variableName, null);
    AstTestFactory.variableDeclarationList2(null, [variableDeclaration]);
    variableDeclaration.accept(builder);

    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNotNull);
  }

  void test_visitVariableDeclaration_top() {
    // final a, b;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    VariableDeclaration variableDeclaration1 =
        AstTestFactory.variableDeclaration('a');
    VariableDeclaration variableDeclaration2 =
        AstTestFactory.variableDeclaration('b');
    TopLevelVariableDeclaration topLevelVariableDeclaration = AstTestFactory
        .topLevelVariableDeclaration(
            Keyword.FINAL, null, [variableDeclaration1, variableDeclaration2]);
    topLevelVariableDeclaration.documentationComment = AstTestFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);

    topLevelVariableDeclaration.accept(builder);
    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(2));

    TopLevelVariableElement variable1 = variables[0];
    expect(variable1, isNotNull);
    expect(variable1.documentationComment, '/// aaa');

    TopLevelVariableElement variable2 = variables[1];
    expect(variable2, isNotNull);
    expect(variable2.documentationComment, '/// aaa');
  }

  void test_visitVariableDeclaration_top_const_hasInitializer() {
    // const v = 42;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration = AstTestFactory
        .variableDeclaration2(variableName, AstTestFactory.integer(42));
    AstTestFactory
        .variableDeclarationList2(Keyword.CONST, [variableDeclaration]);
    variableDeclaration.accept(builder);

    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, new isInstanceOf<ConstTopLevelVariableElementImpl>());
    expect(variable.initializer, isNotNull);
    expect(variable.initializer.type, isNotNull);
    expect(variable.initializer.hasImplicitReturnType, isTrue);
    expect(variable.name, variableName);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.isConst, isTrue);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNull);
  }

  void test_visitVariableDeclaration_top_final() {
    // final v;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstTestFactory.variableDeclaration2(variableName, null);
    AstTestFactory
        .variableDeclarationList2(Keyword.FINAL, [variableDeclaration]);
    variableDeclaration.accept(builder);
    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNull);
  }

  ElementBuilder _makeBuilder(ElementHolder holder) =>
      new ElementBuilder(holder, compilationUnitElement);

  void _setBlockBodySourceRange(BlockFunctionBody body, int offset, int end) {
    _setNodeSourceRange(body.block, offset, end);
  }

  void _setNodeSourceRange(AstNode node, int offset, int end) {
    node.beginToken.offset = offset;
    Token endToken = node.endToken;
    endToken.offset = end - endToken.length;
  }

  void _useParameterInMethod(
      FormalParameter formalParameter, int blockOffset, int blockEnd) {
    Block block = AstTestFactory.block();
    block.leftBracket.offset = blockOffset;
    block.rightBracket.offset = blockEnd - 1;
    BlockFunctionBody body = AstTestFactory.blockFunctionBody(block);
    AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("main"),
        AstTestFactory.formalParameterList([formalParameter]),
        body);
  }
}

@reflectiveTest
class LocalElementBuilderTest extends _BaseTest {
  @override
  AstVisitor createElementBuilder(ElementHolder holder) {
    return new LocalElementBuilder(holder, compilationUnitElement);
  }

  void test_buildLocalElements() {
    var code = r'''
main() {
  int v1;
  f1() {
    int v2;
    f2() {
      int v3;
    }
  }
}
''';
    _compilationUnit = parseCompilationUnit(code);
    var mainAst = _compilationUnit.declarations.single as FunctionDeclaration;

    // Build API elements.
    FunctionElementImpl main;
    {
      ElementHolder holder = new ElementHolder();
      _compilationUnit
          .accept(new ApiElementBuilder(holder, compilationUnitElement));
      main = holder.functions.single as FunctionElementImpl;
    }

    // Build local elements in body.
    ElementHolder holder = new ElementHolder();
    FunctionBody mainBody = mainAst.functionExpression.body;
    mainBody.accept(new LocalElementBuilder(holder, compilationUnitElement));
    main.encloseElements(holder.functions);
    main.encloseElements(holder.localVariables);

    var f1 = findLocalFunction(code, 'f1() {');
    var f2 = findLocalFunction(code, 'f2() {');
    var v1 = findLocalVariable(code, 'v1;');
    var v2 = findLocalVariable(code, 'v2;');
    var v3 = findLocalVariable(code, 'v3;');

    expect(v1.enclosingElement, main);
    {
      expect(f1.name, 'f1');
      expect(v2.enclosingElement, f1);
      {
        expect(f2.name, 'f2');
        expect(v3.enclosingElement, f2);
      }
    }
  }

  void test_buildParameterInitializer() {
    CompilationUnit unit = parseCompilationUnit('f({p: 42}) {}');
    var function = unit.declarations.single as FunctionDeclaration;
    var parameter = function.functionExpression.parameters.parameters.single
        as DefaultFormalParameter;
    // Build API elements.
    {
      ElementHolder holder = new ElementHolder();
      unit.accept(new ApiElementBuilder(holder, compilationUnitElement));
    }
    // Validate the parameter element.
    var parameterElement = parameter.element as ParameterElementImpl;
    expect(parameterElement, isNotNull);
    expect(parameterElement.initializer, isNull);
    // Build the initializer element.
    new LocalElementBuilder(new ElementHolder(), compilationUnitElement)
        .buildParameterInitializer(parameterElement, parameter.defaultValue);
    expect(parameterElement.initializer, isNotNull);
  }

  void test_buildVariableInitializer() {
    CompilationUnit unit = parseCompilationUnit('var V = 42;');
    TopLevelVariableDeclaration topLevelDecl =
        unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclaration variable = topLevelDecl.variables.variables.single;
    // Build the variable element.
    {
      ElementHolder holder = new ElementHolder();
      unit.accept(new ApiElementBuilder(holder, compilationUnitElement));
    }
    // Validate the variable element.
    var variableElement = variable.element as VariableElementImpl;
    expect(variableElement, isNotNull);
    expect(variableElement.initializer, isNull);
    // Build the initializer element.
    new LocalElementBuilder(new ElementHolder(), compilationUnitElement)
        .buildVariableInitializer(variableElement, variable.initializer);
    expect(variableElement.initializer, isNotNull);
  }

  void test_genericFunction_isExpression() {
    buildElementsForText('main(p) { p is Function(int a, String); }');
    var main = compilationUnit.declarations[0] as FunctionDeclaration;
    var body = main.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IsExpression;
    var typeNode = expression.type as GenericFunctionType;
    var typeElement = typeNode.type.element as GenericFunctionTypeElementImpl;
    expect(typeElement.parameters, hasLength(2));
    expect(typeElement.parameters[0].name, 'a');
    expect(typeElement.parameters[1].name, '');
  }

  void test_visitDefaultFormalParameter_local() {
    CompilationUnit unit = parseCompilationUnit('''
main() {
  f({bool b: false}) {}
}
''');
    var mainAst = unit.declarations.single as FunctionDeclaration;
    // Build API elements.
    FunctionElementImpl main;
    {
      ElementHolder holder = new ElementHolder();
      unit.accept(new ApiElementBuilder(holder, compilationUnitElement));
      main = holder.functions.single as FunctionElementImpl;
    }
    // Build local elements in body.
    ElementHolder holder = new ElementHolder();
    FunctionBody mainBody = mainAst.functionExpression.body;
    mainBody.accept(new LocalElementBuilder(holder, compilationUnitElement));

    List<FunctionElement> functions = holder.functions;
    main.encloseElements(functions);

    FunctionElement f = findElementsByName(unit, 'f').single;
    expect(f.parameters, hasLength(1));
    expect(f.parameters[0].initializer, isNotNull);
  }

  void test_visitFieldFormalParameter() {
    CompilationUnit unit = parseCompilationUnit(r'''
main() {
  f(a, this.b) {}
}
''', [ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    var main = unit.declarations[0] as FunctionDeclaration;
    var mainBody = main.functionExpression.body as BlockFunctionBody;
    var mainBlock = mainBody.block;
    var statement = mainBlock.statements[0] as FunctionDeclarationStatement;
    FunctionDeclaration f = statement.functionDeclaration;

    // Build API elements.
    {
      ElementHolder holder = new ElementHolder();
      unit.accept(new ApiElementBuilder(holder, compilationUnitElement));
    }

    // Build local elements.
    ElementHolder holder = new ElementHolder();
    var builder = new LocalElementBuilder(holder, compilationUnitElement);
    f.accept(builder);

    List<FormalParameter> parameters =
        f.functionExpression.parameters.parameters;

    ParameterElement a = parameters[0].element;
    expect(a, isNotNull);
    expect(a.name, 'a');

    ParameterElement b = parameters[1].element;
    expect(b, isNotNull);
    expect(b.name, 'b');
  }

  void test_visitVariableDeclaration_local() {
    var code = 'class C { m() { T v = null; } }';
    buildElementsForText(code);
    LocalVariableElement element = findIdentifier(code, 'v =').staticElement;
    expect(element.hasImplicitType, isFalse);
    expect(element.name, 'v');
    expect(element.initializer, isNotNull);
    _assertVisibleRange(element, 14, 29);
  }
}

/**
 * Mixin with test methods for testing element building in [ApiElementBuilder].
 * It is used to test the [ApiElementBuilder] itself, and its usage by
 * [ElementBuilder].
 */
abstract class _ApiElementBuilderTestMixin {
  CompilationUnit get compilationUnit;

  void assertHasCodeRange(Element element, int offset, int length);

  /**
   * Build elements using [ApiElementBuilder].
   */
  ElementHolder buildElementsForAst(AstNode node);

  /**
   * Parse the given [code], and build elements using [ApiElementBuilder].
   */
  ElementHolder buildElementsForText(String code);

  /**
   * Verify that the given [metadata] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved.
   */
  void checkAnnotation(NodeList<Annotation> metadata);

  /**
   * Verify that the given [element] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved.
   */
  void checkMetadata(Element element);

  void test_genericFunction_asTopLevelVariableType() {
    buildElementsForText('int Function(int a, String) v;');
    var v = compilationUnit.declarations[0] as TopLevelVariableDeclaration;
    var typeNode = v.variables.type as GenericFunctionType;
    var typeElement = typeNode.type.element as GenericFunctionTypeElementImpl;
    expect(typeElement.parameters, hasLength(2));
    expect(typeElement.parameters[0].name, 'a');
    expect(typeElement.parameters[1].name, '');
  }

  void test_metadata_fieldDeclaration() {
    List<FieldElement> fields =
        buildElementsForText('class C { @a int x, y; }').types[0].fields;
    checkMetadata(fields[0]);
    checkMetadata(fields[1]);
    expect(fields[0].metadata, same(fields[1].metadata));
  }

  void test_metadata_topLevelVariableDeclaration() {
    List<TopLevelVariableElement> topLevelVariables =
        buildElementsForText('@a int x, y;').topLevelVariables;
    checkMetadata(topLevelVariables[0]);
    checkMetadata(topLevelVariables[1]);
    expect(topLevelVariables[0].metadata, same(topLevelVariables[1].metadata));
  }

  void test_metadata_visitClassDeclaration() {
    ClassElement classElement = buildElementsForText('@a class C {}').types[0];
    checkMetadata(classElement);
  }

  void test_metadata_visitClassTypeAlias() {
    ClassElement classElement =
        buildElementsForText('@a class C = D with E;').types[0];
    checkMetadata(classElement);
  }

  void test_metadata_visitConstructorDeclaration() {
    ConstructorElement constructorElement =
        buildElementsForText('class C { @a C(); }').types[0].constructors[0];
    checkMetadata(constructorElement);
  }

  void test_metadata_visitDefaultFormalParameter_fieldFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('class C { var x; C([@a this.x = null]); }')
            .types[0]
            .constructors[0]
            .parameters[0];
    checkMetadata(parameterElement);
  }

  void
      test_metadata_visitDefaultFormalParameter_functionTypedFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f([@a g() = null]) {}')
            .functions[0]
            .parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitDefaultFormalParameter_simpleFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f([@a gx = null]) {}').functions[0].parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitEnumDeclaration() {
    ClassElement classElement =
        buildElementsForText('@a enum E { v }').enums[0];
    checkMetadata(classElement);
  }

  void test_metadata_visitExportDirective() {
    buildElementsForText('@a export "foo.dart";');
    expect(compilationUnit.directives[0], new isInstanceOf<ExportDirective>());
    ExportDirective exportDirective = compilationUnit.directives[0];
    checkAnnotation(exportDirective.metadata);
  }

  void test_metadata_visitFieldFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('class C { var x; C(@a this.x); }')
            .types[0]
            .constructors[0]
            .parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitFunctionDeclaration_function() {
    FunctionElement functionElement =
        buildElementsForText('@a f() {}').functions[0];
    checkMetadata(functionElement);
  }

  void test_metadata_visitFunctionDeclaration_getter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('@a get f => null;').accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitFunctionDeclaration_setter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('@a set f(value) {}').accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitFunctionTypeAlias() {
    FunctionTypeAliasElement functionTypeAliasElement =
        buildElementsForText('@a typedef F();').typeAliases[0];
    checkMetadata(functionTypeAliasElement);
  }

  void test_metadata_visitFunctionTypedFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f(@a g()) {}').functions[0].parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitImportDirective() {
    buildElementsForText('@a import "foo.dart";');
    expect(compilationUnit.directives[0], new isInstanceOf<ImportDirective>());
    ImportDirective importDirective = compilationUnit.directives[0];
    checkAnnotation(importDirective.metadata);
  }

  void test_metadata_visitLibraryDirective() {
    buildElementsForText('@a library L;');
    expect(compilationUnit.directives[0], new isInstanceOf<LibraryDirective>());
    LibraryDirective libraryDirective = compilationUnit.directives[0];
    checkAnnotation(libraryDirective.metadata);
  }

  void test_metadata_visitMethodDeclaration_getter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('class C { @a get m => null; }')
            .types[0]
            .accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitMethodDeclaration_method() {
    MethodElement methodElement =
        buildElementsForText('class C { @a m() {} }').types[0].methods[0];
    checkMetadata(methodElement);
  }

  void test_metadata_visitMethodDeclaration_setter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('class C { @a set f(value) {} }')
            .types[0]
            .accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitPartDirective() {
    buildElementsForText('@a part "foo.dart";');
    expect(compilationUnit.directives[0], new isInstanceOf<PartDirective>());
    PartDirective partDirective = compilationUnit.directives[0];
    checkAnnotation(partDirective.metadata);
  }

  void test_metadata_visitPartOfDirective() {
    // We don't build ElementAnnotation objects for `part of` directives, since
    // analyzer ignores them in favor of annotations on the library directive.
    buildElementsForText('@a part of L;');
    expect(compilationUnit.directives[0], new isInstanceOf<PartOfDirective>());
    PartOfDirective partOfDirective = compilationUnit.directives[0];
    expect(partOfDirective.metadata, hasLength(1));
    expect(partOfDirective.metadata[0].elementAnnotation, isNull);
  }

  void test_metadata_visitSimpleFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f(@a x) {}').functions[0].parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitTypeParameter() {
    TypeParameterElement typeParameterElement =
        buildElementsForText('class C<@a T> {}').types[0].typeParameters[0];
    checkMetadata(typeParameterElement);
  }

  void test_visitClassDeclaration_abstract() {
    List<ClassElement> types =
        buildElementsForText('abstract class C {}').types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, 'C');
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isTrue);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_invalidFunctionInAnnotation_class() {
    // https://github.com/dart-lang/sdk/issues/25696
    String code = r'''
class A {
  const A({f});
}

@A(f: () {})
class C {}
''';
    buildElementsForText(code);
  }

  void test_visitClassDeclaration_invalidFunctionInAnnotation_method() {
    String code = r'''
class A {
  const A({f});
}

class C {
  @A(f: () {})
  void m() {}
}
''';
    ElementHolder holder = buildElementsForText(code);
    ClassElement elementC = holder.types[1];
    expect(elementC, isNotNull);
    MethodElement methodM = elementC.methods[0];
    expect(methodM, isNotNull);
  }

  void test_visitClassDeclaration_minimal() {
    String className = "C";
    ClassDeclaration classDeclaration = AstTestFactory.classDeclaration(
        null, className, null, null, null, null);
    classDeclaration.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    classDeclaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(classDeclaration);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
    expect(type.documentationComment, '/// aaa');
    assertHasCodeRange(type, 50, 31);
  }

  void test_visitClassDeclaration_parameterized() {
    String className = "C";
    String firstVariableName = "E";
    String secondVariableName = "F";
    ClassDeclaration classDeclaration = AstTestFactory.classDeclaration(
        null,
        className,
        AstTestFactory
            .typeParameterList([firstVariableName, secondVariableName]),
        null,
        null,
        null);

    ElementHolder holder = buildElementsForAst(classDeclaration);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstVariableName);
    expect(typeParameters[1].name, secondVariableName);
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_withMembers() {
    String className = "C";
    String typeParameterName = "E";
    String fieldName = "f";
    String methodName = "m";
    ClassDeclaration classDeclaration = AstTestFactory.classDeclaration(
        null,
        className,
        AstTestFactory.typeParameterList([typeParameterName]),
        null,
        null,
        null, [
      AstTestFactory.fieldDeclaration2(
          false, null, [AstTestFactory.variableDeclaration(fieldName)]),
      AstTestFactory.methodDeclaration2(
          null,
          null,
          null,
          null,
          AstTestFactory.identifier3(methodName),
          AstTestFactory.formalParameterList(),
          AstTestFactory.blockFunctionBody2())
    ]);

    ElementHolder holder = buildElementsForAst(classDeclaration);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
    List<FieldElement> fields = type.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, fieldName);
    List<MethodElement> methods = type.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
  }

  void test_visitClassTypeAlias() {
    // class B {}
    // class M {}
    // class C = B with M
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstTestFactory.withClause([AstTestFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstTestFactory.classTypeAlias(
        'C', null, null, AstTestFactory.typeName(classB, []), withClause, null);

    ElementHolder holder = buildElementsForAst(alias);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(alias.element, same(type));
    expect(type.name, equals('C'));
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isTrue);
    expect(type.isSynthetic, isFalse);
    expect(type.typeParameters, isEmpty);
    expect(type.fields, isEmpty);
    expect(type.methods, isEmpty);
  }

  void test_visitClassTypeAlias_abstract() {
    // class B {}
    // class M {}
    // abstract class C = B with M
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstTestFactory.withClause([AstTestFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstTestFactory.classTypeAlias(
        'C',
        null,
        Keyword.ABSTRACT,
        AstTestFactory.typeName(classB, []),
        withClause,
        null);

    ElementHolder holder = buildElementsForAst(alias);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.isAbstract, isTrue);
    expect(type.isMixinApplication, isTrue);
  }

  void test_visitClassTypeAlias_typeParams() {
    // class B {}
    // class M {}
    // class C<T> = B with M
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElementImpl classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstTestFactory.withClause([AstTestFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstTestFactory.classTypeAlias(
        'C',
        AstTestFactory.typeParameterList(['T']),
        null,
        AstTestFactory.typeName(classB, []),
        withClause,
        null);

    ElementHolder holder = buildElementsForAst(alias);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.typeParameters, hasLength(1));
    expect(type.typeParameters[0].name, equals('T'));
  }

  void test_visitConstructorDeclaration_external() {
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3(className),
            null,
            AstTestFactory.formalParameterList(),
            null,
            AstTestFactory.blockFunctionBody2());
    constructorDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);

    ElementHolder holder = buildElementsForAst(constructorDeclaration);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isTrue);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_factory() {
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstTestFactory.constructorDeclaration2(
            null,
            Keyword.FACTORY,
            AstTestFactory.identifier3(className),
            null,
            AstTestFactory.formalParameterList(),
            null,
            AstTestFactory.blockFunctionBody2());

    ElementHolder holder = buildElementsForAst(constructorDeclaration);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isTrue);
    expect(constructor.name, "");
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_minimal() {
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3(className),
            null,
            AstTestFactory.formalParameterList(),
            null,
            AstTestFactory.blockFunctionBody2());
    constructorDeclaration.documentationComment = AstTestFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    constructorDeclaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(constructorDeclaration);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    assertHasCodeRange(constructor, 50, 31);
    expect(constructor.documentationComment, '/// aaa');
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_named() {
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration constructorDeclaration =
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3(className),
            constructorName,
            AstTestFactory.formalParameterList(),
            null,
            AstTestFactory.blockFunctionBody2());

    ElementHolder holder = buildElementsForAst(constructorDeclaration);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, constructorName);
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.name.staticElement, same(constructor));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitConstructorDeclaration_unnamed() {
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3(className),
            null,
            AstTestFactory.formalParameterList(),
            null,
            AstTestFactory.blockFunctionBody2());

    ElementHolder holder = buildElementsForAst(constructorDeclaration);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitEnumDeclaration() {
    String enumName = "E";
    EnumDeclaration enumDeclaration =
        AstTestFactory.enumDeclaration2(enumName, ["ONE"]);
    enumDeclaration.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    enumDeclaration.endToken.offset = 80;
    ElementHolder holder = buildElementsForAst(enumDeclaration);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    ClassElement enumElement = enums[0];
    expect(enumElement, isNotNull);
    assertHasCodeRange(enumElement, 50, 31);
    expect(enumElement.documentationComment, '/// aaa');
    expect(enumElement.name, enumName);
  }

  void test_visitFieldDeclaration() {
    String firstFieldName = "x";
    String secondFieldName = "y";
    FieldDeclaration fieldDeclaration =
        AstTestFactory.fieldDeclaration2(false, null, [
      AstTestFactory.variableDeclaration(firstFieldName),
      AstTestFactory.variableDeclaration(secondFieldName)
    ]);
    fieldDeclaration.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    fieldDeclaration.endToken.offset = 110;

    ElementHolder holder = buildElementsForAst(fieldDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(2));

    FieldElement firstField = fields[0];
    expect(firstField, isNotNull);
    assertHasCodeRange(firstField, 50, 61);
    expect(firstField.documentationComment, '/// aaa');
    expect(firstField.name, firstFieldName);
    expect(firstField.initializer, isNull);
    expect(firstField.isConst, isFalse);
    expect(firstField.isFinal, isFalse);
    expect(firstField.isSynthetic, isFalse);

    FieldElement secondField = fields[1];
    expect(secondField, isNotNull);
    assertHasCodeRange(secondField, 50, 61);
    expect(secondField.documentationComment, '/// aaa');
    expect(secondField.name, secondFieldName);
    expect(secondField.initializer, isNull);
    expect(secondField.isConst, isFalse);
    expect(secondField.isFinal, isFalse);
    expect(secondField.isSynthetic, isFalse);
  }

  void test_visitFieldFormalParameter() {
    String parameterName = "p";
    FieldFormalParameter formalParameter =
        AstTestFactory.fieldFormalParameter(null, null, parameterName);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    ElementHolder holder = buildElementsForAst(formalParameter);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    assertHasCodeRange(parameter, 50, 31);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(0));
  }

  void test_visitFieldFormalParameter_functionTyped() {
    String parameterName = "p";
    FieldFormalParameter formalParameter = AstTestFactory.fieldFormalParameter(
        null,
        null,
        parameterName,
        AstTestFactory
            .formalParameterList([AstTestFactory.simpleFormalParameter3("a")]));
    ElementHolder holder = buildElementsForAst(formalParameter);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));

    ParameterElement parameter = parameters[0];
    var typeElement = parameter.type.element as GenericFunctionTypeElementImpl;
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(typeElement.parameters, hasLength(1));
  }

  void test_visitFormalParameterList() {
    String firstParameterName = "a";
    String secondParameterName = "b";
    FormalParameterList parameterList = AstTestFactory.formalParameterList([
      AstTestFactory.simpleFormalParameter3(firstParameterName),
      AstTestFactory.simpleFormalParameter3(secondParameterName)
    ]);
    ElementHolder holder = buildElementsForAst(parameterList);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
  }

  void test_visitFunctionDeclaration_external() {
    // external f();
    String functionName = "f";
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.emptyFunctionBody()));
    declaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);

    ElementHolder holder = buildElementsForAst(declaration);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isExternal, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionDeclaration_getter() {
    // get f() {}
    String functionName = "f";
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        null,
        Keyword.GET,
        functionName,
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
    declaration.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(declaration);
    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    assertHasCodeRange(accessor, 50, 31);
    expect(accessor.documentationComment, '/// aaa');
    expect(accessor.name, functionName);
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.hasImplicitReturnType, isTrue);
    expect(accessor.isGetter, isTrue);
    expect(accessor.isExternal, isFalse);
    expect(accessor.isSetter, isFalse);
    expect(accessor.isSynthetic, isFalse);
    expect(accessor.typeParameters, hasLength(0));
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_plain() {
    // T f() {}
    String functionName = "f";
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        AstTestFactory.typeName4('T'),
        null,
        functionName,
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
    declaration.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(declaration);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    assertHasCodeRange(function, 50, 31);
    expect(function.documentationComment, '/// aaa');
    expect(function.hasImplicitReturnType, isFalse);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.isExternal, isFalse);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionDeclaration_setter() {
    // set f() {}
    String functionName = "f";
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        null,
        Keyword.SET,
        functionName,
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
    declaration.documentationComment = AstTestFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(declaration);
    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    assertHasCodeRange(accessor, 50, 31);
    expect(accessor.documentationComment, '/// aaa');
    expect(accessor.hasImplicitReturnType, isTrue);
    expect(accessor.name, "$functionName=");
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.isGetter, isFalse);
    expect(accessor.isExternal, isFalse);
    expect(accessor.isSetter, isTrue);
    expect(accessor.isSynthetic, isFalse);
    expect(accessor.typeParameters, hasLength(0));
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_typeParameters() {
    // f<E>() {}
    String functionName = 'f';
    String typeParameterName = 'E';
    FunctionExpression expression = AstTestFactory.functionExpression3(
        AstTestFactory.typeParameterList([typeParameterName]),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        null, null, functionName, expression);

    ElementHolder holder = buildElementsForAst(declaration);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.name, functionName);
    expect(function.isExternal, isFalse);
    expect(function.isSynthetic, isFalse);
    expect(declaration.element, same(function));
    expect(expression.element, same(function));
    List<TypeParameterElement> typeParameters = function.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
  }

  void test_visitMethodDeclaration_abstract() {
    // m();
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.emptyFunctionBody());

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isTrue);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_duplicateField_synthetic() {
    buildElementsForText(r'''
class A {
  int f;
  int get f => 42;
}
''');
    ClassDeclaration classNode = compilationUnit.declarations.single;
    // ClassElement
    ClassElement classElement = classNode.element;
    expect(classElement.fields, hasLength(2));
    expect(classElement.accessors, hasLength(3));
    FieldElement notSyntheticFieldElement = classElement.fields
        .singleWhere((f) => f.displayName == 'f' && !f.isSynthetic);
    FieldElement syntheticFieldElement = classElement.fields
        .singleWhere((f) => f.displayName == 'f' && f.isSynthetic);
    PropertyAccessorElement syntheticGetterElement = classElement.accessors
        .singleWhere(
            (a) => a.displayName == 'f' && a.isGetter && a.isSynthetic);
    PropertyAccessorElement syntheticSetterElement = classElement.accessors
        .singleWhere(
            (a) => a.displayName == 'f' && a.isSetter && a.isSynthetic);
    PropertyAccessorElement notSyntheticGetterElement = classElement.accessors
        .singleWhere(
            (a) => a.displayName == 'f' && a.isGetter && !a.isSynthetic);
    expect(notSyntheticFieldElement.getter, same(syntheticGetterElement));
    expect(notSyntheticFieldElement.setter, same(syntheticSetterElement));
    expect(syntheticFieldElement.getter, same(notSyntheticGetterElement));
    expect(syntheticFieldElement.setter, isNull);
    // class members nodes and their elements
    FieldDeclaration fieldDeclNode = classNode.members[0];
    VariableDeclaration fieldNode = fieldDeclNode.fields.variables.single;
    MethodDeclaration getterNode = classNode.members[1];
    expect(fieldNode.element, notSyntheticFieldElement);
    expect(getterNode.element, notSyntheticGetterElement);
  }

  void test_visitMethodDeclaration_external() {
    // external m();
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.emptyFunctionBody());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isTrue);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_getter() {
    // get m() {}
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstTestFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    assertHasCodeRange(getter, 50, 31);
    expect(getter.documentationComment, '/// aaa');
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_abstract() {
    // get m();
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.emptyFunctionBody());

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isTrue);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_external() {
    // external get m();
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration(
        null,
        null,
        Keyword.GET,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isTrue);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_minimal() {
    // T m() {}
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        AstTestFactory.typeName4('T'),
        null,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstTestFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    assertHasCodeRange(method, 50, 31);
    expect(method.documentationComment, '/// aaa');
    expect(method.hasImplicitReturnType, isFalse);
    expect(method.name, methodName);
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_operator() {
    // operator +(addend) {}
    String methodName = "+";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        Keyword.OPERATOR,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(
            [AstTestFactory.simpleFormalParameter3("addend")]),
        AstTestFactory.blockFunctionBody2());

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.parameters, hasLength(1));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_setter() {
    // set m() {}
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstTestFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);

    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    assertHasCodeRange(setter, 50, 31);
    expect(setter.documentationComment, '/// aaa');
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_abstract() {
    // set m();
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.emptyFunctionBody());

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isTrue);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_external() {
    // external m();
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration(
        null,
        null,
        Keyword.SET,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isTrue);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_static() {
    // static m() {}
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        Keyword.STATIC,
        null,
        null,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isTrue);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_typeParameters() {
    // m<E>() {}
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    methodDeclaration.typeParameters = AstTestFactory.typeParameterList(['E']);

    ElementHolder holder = buildElementsForAst(methodDeclaration);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(1));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitTypeAlias_minimal() {
    String aliasName = "F";
    TypeAlias typeAlias = AstTestFactory.typeAlias(null, aliasName, null, null);
    ElementHolder holder = buildElementsForAst(typeAlias);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
  }

  void test_visitTypeAlias_withFormalParameters() {
    String aliasName = "F";
    String firstParameterName = "x";
    String secondParameterName = "y";
    TypeAlias typeAlias = AstTestFactory.typeAlias(
        null,
        aliasName,
        AstTestFactory.typeParameterList(),
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3(firstParameterName),
          AstTestFactory.simpleFormalParameter3(secondParameterName)
        ]));
    typeAlias.beginToken.offset = 50;
    typeAlias.endToken.offset = 80;
    ElementHolder holder = buildElementsForAst(typeAlias);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    GenericTypeAliasElementImpl alias = aliases[0];
    expect(alias, isNotNull);
    assertHasCodeRange(alias, 50, 31);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters, hasLength(0));
  }

  void test_visitTypeAlias_withTypeParameters() {
    String aliasName = "F";
    String firstTypeParameterName = "A";
    String secondTypeParameterName = "B";
    TypeAlias typeAlias = AstTestFactory.typeAlias(
        null,
        aliasName,
        AstTestFactory.typeParameterList(
            [firstTypeParameterName, secondTypeParameterName]),
        AstTestFactory.formalParameterList());
    ElementHolder holder = buildElementsForAst(typeAlias);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    GenericTypeAliasElementImpl alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, isNotNull);
    expect(parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstTypeParameterName);
    expect(typeParameters[1].name, secondTypeParameterName);
  }

  void test_visitTypeParameter() {
    String parameterName = "E";
    TypeParameter typeParameter = AstTestFactory.typeParameter(parameterName);
    typeParameter.beginToken.offset = 50;
    ElementHolder holder = buildElementsForAst(typeParameter);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameterElement = typeParameters[0];
    expect(typeParameterElement, isNotNull);
    assertHasCodeRange(typeParameterElement, 50, 1);
    expect(typeParameterElement.name, parameterName);
    expect(typeParameterElement.bound, isNull);
    expect(typeParameterElement.isSynthetic, isFalse);
  }
}

abstract class _BaseTest extends ParserTestCase {
  CompilationUnitElement compilationUnitElement;
  CompilationUnit _compilationUnit;

  CompilationUnit get compilationUnit => _compilationUnit;

  void assertHasCodeRange(Element element, int offset, int length) {
    ElementImpl elementImpl = element;
    expect(elementImpl.codeOffset, offset);
    expect(elementImpl.codeLength, length);
  }

  /**
   * Build elements using [ApiElementBuilder].
   */
  ElementHolder buildElementsForAst(AstNode node) {
    ElementHolder holder = new ElementHolder();
    AstVisitor builder = createElementBuilder(holder);
    node.accept(builder);
    return holder;
  }

  /**
   * Parse the given [code], and build elements using [ApiElementBuilder].
   */
  ElementHolder buildElementsForText(String code) {
    ElementHolder holder = new ElementHolder();
    AstVisitor builder = createElementBuilder(holder);
    _visitAstOfCode(code, builder);
    return holder;
  }

  /**
   * Verify that the given [metadata] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved.
   */
  void checkAnnotation(NodeList<Annotation> metadata) {
    expect(metadata, hasLength(1));
    expect(metadata[0], new isInstanceOf<AnnotationImpl>());
    AnnotationImpl annotation = metadata[0];
    expect(annotation.elementAnnotation,
        new isInstanceOf<ElementAnnotationImpl>());
    ElementAnnotationImpl elementAnnotation = annotation.elementAnnotation;
    expect(elementAnnotation.element, isNull); // Not yet resolved
    expect(elementAnnotation.compilationUnit, isNotNull);
    expect(elementAnnotation.compilationUnit, compilationUnitElement);
  }

  /**
   * Verify that the given [element] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved.
   */
  void checkMetadata(Element element) {
    expect(element.metadata, hasLength(1));
    expect(element.metadata[0], new isInstanceOf<ElementAnnotationImpl>());
    ElementAnnotationImpl elementAnnotation = element.metadata[0];
    expect(elementAnnotation.element, isNull); // Not yet resolved
    expect(elementAnnotation.compilationUnit, isNotNull);
    expect(elementAnnotation.compilationUnit, compilationUnitElement);
  }

  AstVisitor createElementBuilder(ElementHolder holder);

  SimpleIdentifier findIdentifier(String code, String prefix) {
    return EngineTestCase.findSimpleIdentifier(compilationUnit, code, prefix);
  }

  LabelElement findLabel(String code, String prefix) {
    return findIdentifier(code, prefix).staticElement;
  }

  FunctionElement findLocalFunction(String code, String prefix) {
    return findIdentifier(code, prefix).staticElement;
  }

  LocalVariableElement findLocalVariable(String code, String prefix) {
    return findIdentifier(code, prefix).staticElement;
  }

  void setUp() {
    compilationUnitElement = new CompilationUnitElementImpl('test.dart');
  }

  void _assertVisibleRange(LocalElement element, int offset, int end) {
    SourceRange visibleRange = element.visibleRange;
    expect(visibleRange.offset, offset);
    expect(visibleRange.end, end);
  }

  /**
   * Parse the given [code], and visit it with the given [visitor].
   * Fail if any error is logged.
   */
  void _visitAstOfCode(String code, AstVisitor visitor) {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    try {
      _compilationUnit = parseCompilationUnit(code);
      compilationUnit.accept(visitor);
    } finally {
      expect(logger.log, hasLength(0));
      AnalysisEngine.instance.logger = Logger.NULL;
    }
  }
}
