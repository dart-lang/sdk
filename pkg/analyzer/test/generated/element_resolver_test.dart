// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.element_resolver_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'analysis_context_factory.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ElementResolverTest);
}

@reflectiveTest
class ElementResolverTest extends EngineTestCase {
  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library containing the code being resolved.
   */
  LibraryElementImpl _definingLibrary;

  /**
   * The resolver visitor that maintains the state for the resolver.
   */
  ResolverVisitor _visitor;

  /**
   * The resolver being used to resolve the test cases.
   */
  ElementResolver _resolver;

  void fail_visitExportDirective_combinators() {
    fail("Not yet tested");
    // Need to set up the exported library so that the identifier can be
    // resolved.
    ExportDirective directive = AstFactory.exportDirective2(null, [
      AstFactory.hideCombinator2(["A"])
    ]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitFunctionExpressionInvocation() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitImportDirective_combinators_noPrefix() {
    fail("Not yet tested");
    // Need to set up the imported library so that the identifier can be
    // resolved.
    ImportDirective directive = AstFactory.importDirective3(null, null, [
      AstFactory.showCombinator2(["A"])
    ]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitImportDirective_combinators_prefix() {
    fail("Not yet tested");
    // Need to set up the imported library so that the identifiers can be
    // resolved.
    String prefixName = "p";
    _definingLibrary.imports = <ImportElement>[
      ElementFactory.importFor(null, ElementFactory.prefix(prefixName))
    ];
    ImportDirective directive = AstFactory.importDirective3(null, prefixName, [
      AstFactory.showCombinator2(["A"]),
      AstFactory.hideCombinator2(["B"])
    ]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitRedirectingConstructorInvocation() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  @override
  void setUp() {
    super.setUp();
    _listener = new GatheringErrorListener();
    _typeProvider = new TestTypeProvider();
    _resolver = _createResolver();
  }

  void test_lookUpMethodInInterfaces() {
    InterfaceType intType = _typeProvider.intType;
    //
    // abstract class A { int operator[](int index); }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    MethodElement operator =
        ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement>[operator];
    //
    // class B implements A {}
    //
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    //
    // class C extends Object with B {}
    //
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[classB.type];
    //
    // class D extends C {}
    //
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type);
    //
    // D a;
    // a[i];
    //
    SimpleIdentifier array = AstFactory.identifier3("a");
    array.staticType = classD.type;
    IndexExpression expression =
        AstFactory.indexExpression(array, AstFactory.identifier3("i"));
    expect(_resolveIndexExpression(expression), same(operator));
    _listener.assertNoErrors();
  }

  void test_visitAssignmentExpression_compound() {
    InterfaceType intType = _typeProvider.intType;
    SimpleIdentifier leftHandSide = AstFactory.identifier3("a");
    leftHandSide.staticType = intType;
    AssignmentExpression assignment = AstFactory.assignmentExpression(
        leftHandSide, TokenType.PLUS_EQ, AstFactory.integer(1));
    _resolveNode(assignment);
    expect(
        assignment.staticElement, same(getMethod(_typeProvider.numType, "+")));
    _listener.assertNoErrors();
  }

  void test_visitAssignmentExpression_simple() {
    AssignmentExpression expression = AstFactory.assignmentExpression(
        AstFactory.identifier3("x"), TokenType.EQ, AstFactory.integer(0));
    _resolveNode(expression);
    expect(expression.staticElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_bangEq() {
    // String i;
    // var j;
    // i == j
    InterfaceType stringType = _typeProvider.stringType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = stringType;
    BinaryExpression expression = AstFactory.binaryExpression(
        left, TokenType.BANG_EQ, AstFactory.identifier3("j"));
    _resolveNode(expression);
    var stringElement = stringType.element;
    expect(expression.staticElement, isNotNull);
    expect(
        expression.staticElement,
        stringElement.lookUpMethod(
            TokenType.EQ_EQ.lexeme, stringElement.library));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_eq() {
    // String i;
    // var j;
    // i == j
    InterfaceType stringType = _typeProvider.stringType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = stringType;
    BinaryExpression expression = AstFactory.binaryExpression(
        left, TokenType.EQ_EQ, AstFactory.identifier3("j"));
    _resolveNode(expression);
    var stringElement = stringType.element;
    expect(
        expression.staticElement,
        stringElement.lookUpMethod(
            TokenType.EQ_EQ.lexeme, stringElement.library));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_plus() {
    // num i;
    // var j;
    // i + j
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = numType;
    BinaryExpression expression = AstFactory.binaryExpression(
        left, TokenType.PLUS, AstFactory.identifier3("j"));
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_plus_propagatedElement() {
    // var i = 1;
    // var j;
    // i + j
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.propagatedType = numType;
    BinaryExpression expression = AstFactory.binaryExpression(
        left, TokenType.PLUS, AstFactory.identifier3("j"));
    _resolveNode(expression);
    expect(expression.staticElement, isNull);
    expect(expression.propagatedElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  void test_visitBreakStatement_withLabel() {
    // loop: while (true) {
    //   break loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement = new LabelElementImpl.forNode(
        AstFactory.identifier3(label), false, false);
    BreakStatement breakStatement = AstFactory.breakStatement2(label);
    Expression condition = AstFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstFactory.whileStatement(condition, breakStatement);
    expect(_resolveBreak(breakStatement, labelElement, whileStatement),
        same(labelElement));
    expect(breakStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  void test_visitBreakStatement_withoutLabel() {
    BreakStatement statement = AstFactory.breakStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  void test_visitCommentReference_prefixedIdentifier_class_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "p";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // set name scope
    _visitor.nameScope = new EnclosedScope(null)
      ..defineNameWithoutChecking('A', classA);
    // prepare "A.p"
    PrefixedIdentifier prefixed = AstFactory.identifier5('A', 'p');
    CommentReference commentReference = new CommentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, getter);
    _listener.assertNoErrors();
  }

  void test_visitCommentReference_prefixedIdentifier_class_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set method
    MethodElement method =
        ElementFactory.methodElement("m", _typeProvider.intType);
    classA.methods = <MethodElement>[method];
    // set name scope
    _visitor.nameScope = new EnclosedScope(null)
      ..defineNameWithoutChecking('A', classA);
    // prepare "A.m"
    PrefixedIdentifier prefixed = AstFactory.identifier5('A', 'm');
    CommentReference commentReference = new CommentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, method);
    _listener.assertNoErrors();
  }

  void test_visitConstructorName_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstFactory.constructorName(
        AstFactory.typeName(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitConstructorName_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstFactory.constructorName(
        AstFactory.typeName(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitContinueStatement_withLabel() {
    // loop: while (true) {
    //   continue loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement = new LabelElementImpl.forNode(
        AstFactory.identifier3(label), false, false);
    ContinueStatement continueStatement = AstFactory.continueStatement(label);
    Expression condition = AstFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstFactory.whileStatement(condition, continueStatement);
    expect(_resolveContinue(continueStatement, labelElement, whileStatement),
        same(labelElement));
    expect(continueStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  void test_visitContinueStatement_withoutLabel() {
    ContinueStatement statement = AstFactory.continueStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  void test_visitEnumDeclaration() {
    CompilationUnitElementImpl compilationUnitElement =
        ElementFactory.compilationUnit('foo.dart');
    EnumElementImpl enumElement =
        ElementFactory.enumElement(_typeProvider, ('E'));
    compilationUnitElement.enums = <ClassElement>[enumElement];
    EnumDeclaration enumNode = AstFactory.enumDeclaration2('E', []);
    Annotation annotationNode =
        AstFactory.annotation(AstFactory.identifier3('a'));
    annotationNode.element = ElementFactory.classElement2('A');
    annotationNode.elementAnnotation =
        new ElementAnnotationImpl(compilationUnitElement);
    enumNode.metadata.add(annotationNode);
    enumNode.name.staticElement = enumElement;
    List<ElementAnnotation> metadata = <ElementAnnotation>[
      annotationNode.elementAnnotation
    ];
    _resolveNode(enumNode);
    expect(metadata[0].element, annotationNode.element);
  }

  void test_visitExportDirective_noCombinators() {
    ExportDirective directive = AstFactory.exportDirective2(null);
    directive.element = ElementFactory
        .exportFor(ElementFactory.library(_definingLibrary.context, "lib"));
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void test_visitFieldFormalParameter() {
    String fieldName = "f";
    InterfaceType intType = _typeProvider.intType;
    FieldElementImpl fieldElement =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[fieldElement];
    FieldFormalParameter parameter =
        AstFactory.fieldFormalParameter2(fieldName);
    FieldFormalParameterElementImpl parameterElement =
        ElementFactory.fieldFormalParameter(parameter.identifier);
    parameterElement.field = fieldElement;
    parameterElement.type = intType;
    parameter.identifier.staticElement = parameterElement;
    _resolveInClass(parameter, classA);
    expect(parameter.element.type, same(intType));
  }

  void test_visitImportDirective_noCombinators_noPrefix() {
    ImportDirective directive = AstFactory.importDirective3(null, null);
    directive.element = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"), null);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void test_visitImportDirective_noCombinators_prefix() {
    String prefixName = "p";
    ImportElement importElement = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"),
        ElementFactory.prefix(prefixName));
    _definingLibrary.imports = <ImportElement>[importElement];
    ImportDirective directive = AstFactory.importDirective3(null, prefixName);
    directive.element = importElement;
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void test_visitImportDirective_withCombinators() {
    ShowCombinator combinator = AstFactory.showCombinator2(["A", "B", "C"]);
    ImportDirective directive =
        AstFactory.importDirective3(null, null, [combinator]);
    LibraryElementImpl library =
        ElementFactory.library(_definingLibrary.context, "lib");
    TopLevelVariableElementImpl varA =
        ElementFactory.topLevelVariableElement2("A");
    TopLevelVariableElementImpl varB =
        ElementFactory.topLevelVariableElement2("B");
    TopLevelVariableElementImpl varC =
        ElementFactory.topLevelVariableElement2("C");
    CompilationUnitElementImpl unit =
        library.definingCompilationUnit as CompilationUnitElementImpl;
    unit.accessors = <PropertyAccessorElement>[
      varA.getter,
      varA.setter,
      varB.getter,
      varC.setter
    ];
    unit.topLevelVariables = <TopLevelVariableElement>[varA, varB, varC];
    directive.element = ElementFactory.importFor(library, null);
    _resolveNode(directive);
    expect(combinator.shownNames[0].staticElement, same(varA));
    expect(combinator.shownNames[1].staticElement, same(varB));
    expect(combinator.shownNames[2].staticElement, same(varC));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_get() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType intType = _typeProvider.intType;
    MethodElement getter =
        ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement>[getter];
    SimpleIdentifier array = AstFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression =
        AstFactory.indexExpression(array, AstFactory.identifier3("i"));
    expect(_resolveIndexExpression(expression), same(getter));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_set() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType intType = _typeProvider.intType;
    MethodElement setter =
        ElementFactory.methodElement("[]=", intType, [intType]);
    classA.methods = <MethodElement>[setter];
    SimpleIdentifier array = AstFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression =
        AstFactory.indexExpression(array, AstFactory.identifier3("i"));
    AstFactory.assignmentExpression(
        expression, TokenType.EQ, AstFactory.integer(0));
    expect(_resolveIndexExpression(expression), same(setter));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstFactory.constructorName(
        AstFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstFactory.constructorName(
        AstFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_unnamed_namedParameter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    String parameterName = "a";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    constructor.parameters = <ParameterElement>[parameter];
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstFactory.constructorName(
        AstFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation = AstFactory.instanceCreationExpression(
        Keyword.NEW,
        name,
        [AstFactory.namedExpression2(parameterName, AstFactory.integer(0))]);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    expect(
        (creation.argumentList.arguments[0] as NamedExpression)
            .name
            .label
            .staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  void test_visitMethodInvocation() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = numType;
    String methodName = "abs";
    MethodInvocation invocation = AstFactory.methodInvocation(left, methodName);
    _resolveNode(invocation);
    expect(invocation.methodName.staticElement,
        same(getMethod(numType, methodName)));
    _listener.assertNoErrors();
  }

  void test_visitMethodInvocation_namedParameter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    String parameterName = "p";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    method.parameters = <ParameterElement>[parameter];
    classA.methods = <MethodElement>[method];
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = classA.type;
    MethodInvocation invocation = AstFactory.methodInvocation(left, methodName,
        [AstFactory.namedExpression2(parameterName, AstFactory.integer(0))]);
    _resolveNode(invocation);
    expect(invocation.methodName.staticElement, same(method));
    expect(
        (invocation.argumentList.arguments[0] as NamedExpression)
            .name
            .label
            .staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  void test_visitPostfixExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = AstFactory.identifier3("i");
    operand.staticType = numType;
    PostfixExpression expression =
        AstFactory.postfixExpression(operand, TokenType.PLUS_PLUS);
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_dynamic() {
    DartType dynamicType = _typeProvider.dynamicType;
    SimpleIdentifier target = AstFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = dynamicType;
    target.staticElement = variable;
    target.staticType = dynamicType;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3("b"));
    _resolveNode(identifier);
    expect(identifier.staticElement, isNull);
    expect(identifier.identifier.staticElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_nonDynamic() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SimpleIdentifier target = AstFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = classA.type;
    target.staticElement = variable;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(getterName));
    _resolveNode(identifier);
    expect(identifier.staticElement, same(getter));
    expect(identifier.identifier.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_staticClassMember_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.m"
    SimpleIdentifier target = AstFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(propName));
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(getter));
    expect(identifier.identifier.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_staticClassMember_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set methods
    String propName = "m";
    MethodElement method =
        ElementFactory.methodElement("m", _typeProvider.intType);
    classA.methods = <MethodElement>[method];
    // prepare "A.m"
    SimpleIdentifier target = AstFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(propName));
    AstFactory.assignmentExpression(
        identifier, TokenType.EQ, AstFactory.nullLiteral());
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(method));
    expect(identifier.identifier.staticElement, same(method));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_staticClassMember_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.b = null"
    SimpleIdentifier target = AstFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(propName));
    AstFactory.assignmentExpression(
        identifier, TokenType.EQ, AstFactory.nullLiteral());
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(setter));
    expect(identifier.identifier.staticElement, same(setter));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = AstFactory.identifier3("i");
    operand.staticType = numType;
    PrefixExpression expression =
        AstFactory.prefixExpression(TokenType.PLUS_PLUS, operand);
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_getter_identifier() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SimpleIdentifier target = AstFactory.identifier3("a");
    target.staticType = classA.type;
    PropertyAccess access = AstFactory.propertyAccess2(target, getterName);
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_getter_super() {
    //
    // class A {
    //  int get b;
    // }
    // class B {
    //   ... super.m ...
    // }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SuperExpression target = AstFactory.superExpression();
    target.staticType = ElementFactory.classElement("B", classA.type).type;
    PropertyAccess access = AstFactory.propertyAccess2(target, getterName);
    AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.expressionFunctionBody(access));
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_setter_this() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "b";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setter];
    ThisExpression target = AstFactory.thisExpression();
    target.staticType = classA.type;
    PropertyAccess access = AstFactory.propertyAccess2(target, setterName);
    AstFactory.assignmentExpression(
        access, TokenType.EQ, AstFactory.integer(0));
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(setter));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_classScope() {
    InterfaceType doubleType = _typeProvider.doubleType;
    String fieldName = "NAN";
    SimpleIdentifier node = AstFactory.identifier3(fieldName);
    _resolveInClass(node, doubleType.element);
    expect(node.staticElement, getGetter(doubleType, fieldName));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_dynamic() {
    SimpleIdentifier node = AstFactory.identifier3("dynamic");
    _resolveIdentifier(node);
    expect(node.staticElement, same(_typeProvider.dynamicType.element));
    expect(node.staticType, same(_typeProvider.typeType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_lexicalScope() {
    SimpleIdentifier node = AstFactory.identifier3("i");
    VariableElementImpl element = ElementFactory.localVariableElement(node);
    expect(_resolveIdentifier(node, [element]), same(element));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_lexicalScope_field_setter() {
    InterfaceType intType = _typeProvider.intType;
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String fieldName = "a";
    FieldElement field =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    classA.fields = <FieldElement>[field];
    classA.accessors = <PropertyAccessorElement>[field.getter, field.setter];
    SimpleIdentifier node = AstFactory.identifier3(fieldName);
    AstFactory.assignmentExpression(node, TokenType.EQ, AstFactory.integer(0));
    _resolveInClass(node, classA);
    Element element = node.staticElement;
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement, element);
    expect((element as PropertyAccessorElement).isSetter, isTrue);
    _listener.assertNoErrors();
  }

  void test_visitSuperConstructorInvocation() {
    ClassElementImpl superclass = ElementFactory.classElement2("A");
    ConstructorElementImpl superConstructor =
        ElementFactory.constructorElement2(superclass, null);
    superclass.constructors = <ConstructorElement>[superConstructor];
    ClassElementImpl subclass =
        ElementFactory.classElement("B", superclass.type);
    ConstructorElementImpl subConstructor =
        ElementFactory.constructorElement2(subclass, null);
    subclass.constructors = <ConstructorElement>[subConstructor];
    SuperConstructorInvocation invocation =
        AstFactory.superConstructorInvocation();
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    _listener.assertNoErrors();
  }

  void test_visitSuperConstructorInvocation_namedParameter() {
    ClassElementImpl superclass = ElementFactory.classElement2("A");
    ConstructorElementImpl superConstructor =
        ElementFactory.constructorElement2(superclass, null);
    String parameterName = "p";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    superConstructor.parameters = <ParameterElement>[parameter];
    superclass.constructors = <ConstructorElement>[superConstructor];
    ClassElementImpl subclass =
        ElementFactory.classElement("B", superclass.type);
    ConstructorElementImpl subConstructor =
        ElementFactory.constructorElement2(subclass, null);
    subclass.constructors = <ConstructorElement>[subConstructor];
    SuperConstructorInvocation invocation = AstFactory
        .superConstructorInvocation([
      AstFactory.namedExpression2(parameterName, AstFactory.integer(0))
    ]);
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    expect(
        (invocation.argumentList.arguments[0] as NamedExpression)
            .name
            .label
            .staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  /**
   * Create the resolver used by the tests.
   *
   * @return the resolver that was created
   */
  ElementResolver _createResolver() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    FileBasedSource source =
        new FileBasedSource(FileUtilities2.createFile("/test.dart"));
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl("test.dart");
    definingCompilationUnit.librarySource =
        definingCompilationUnit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;
    _visitor = new ResolverVisitor(
        _definingLibrary, source, _typeProvider, _listener,
        nameScope: new LibraryScope(_definingLibrary, _listener));
    try {
      return _visitor.elementResolver;
    } catch (exception) {
      throw new IllegalArgumentException(
          "Could not create resolver", exception);
    }
  }

  /**
   * Return the element associated with the label of [statement] after the
   * resolver has resolved it.  [labelElement] is the label element to be
   * defined in the statement's label scope, and [labelTarget] is the statement
   * the label resolves to.
   */
  Element _resolveBreak(BreakStatement statement, LabelElementImpl labelElement,
      Statement labelTarget) {
    _resolveStatement(statement, labelElement, labelTarget);
    return statement.label.staticElement;
  }

  /**
   * Return the element associated with the label [statement] after the
   * resolver has resolved it.  [labelElement] is the label element to be
   * defined in the statement's label scope, and [labelTarget] is the AST node
   * the label resolves to.
   *
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  Element _resolveContinue(ContinueStatement statement,
      LabelElementImpl labelElement, AstNode labelTarget) {
    _resolveStatement(statement, labelElement, labelTarget);
    return statement.label.staticElement;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  Element _resolveIdentifier(Identifier node, [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    return node.staticElement;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param enclosingClass the element representing the class enclosing the identifier
   * @return the element to which the expression was resolved
   */
  void _resolveInClass(AstNode node, ClassElement enclosingClass) {
    try {
      Scope outerScope = _visitor.nameScope;
      try {
        _visitor.enclosingClass = enclosingClass;
        EnclosedScope innerScope = new ClassScope(
            new TypeParameterScope(outerScope, enclosingClass), enclosingClass);
        _visitor.nameScope = innerScope;
        node.accept(_resolver);
      } finally {
        _visitor.enclosingClass = null;
        _visitor.nameScope = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }

  /**
   * Return the element associated with the given expression after the resolver has resolved the
   * expression.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  Element _resolveIndexExpression(IndexExpression node,
      [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    return node.staticElement;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  void _resolveNode(AstNode node, [List<Element> definedElements]) {
    try {
      Scope outerScope = _visitor.nameScope;
      try {
        EnclosedScope innerScope = new EnclosedScope(outerScope);
        if (definedElements != null) {
          for (Element element in definedElements) {
            innerScope.define(element);
          }
        }
        _visitor.nameScope = innerScope;
        node.accept(_resolver);
      } finally {
        _visitor.nameScope = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }

  /**
   * Return the element associated with the label of the given statement after the resolver has
   * resolved the statement.
   *
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  void _resolveStatement(
      Statement statement, LabelElementImpl labelElement, AstNode labelTarget) {
    try {
      LabelScope outerScope = _visitor.labelScope;
      try {
        LabelScope innerScope;
        if (labelElement == null) {
          innerScope = outerScope;
        } else {
          innerScope = new LabelScope(
              outerScope, labelElement.name, labelTarget, labelElement);
        }
        _visitor.labelScope = innerScope;
        statement.accept(_resolver);
      } finally {
        _visitor.labelScope = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }
}
