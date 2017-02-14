// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.element_resolver_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_context_factory.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementResolverCodeTest);
    defineReflectiveTests(ElementResolverTest);
  });
}

@reflectiveTest
class ElementResolverCodeTest extends ResolverTestCase {
  test_annotation_class_namedConstructor() async {
    addNamedSource(
        '/a.dart',
        r'''
class A {
  const A.named();
}
''');
    await _validateAnnotation('', '@A.named()', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<ClassElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'A');
      expect(name2, isNotNull);
      expect(name2.staticElement, new isInstanceOf<ConstructorElement>());
      expect(
          resolutionMap.staticElementForIdentifier(name2).displayName, 'named');
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'named');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_class_prefixed_namedConstructor() async {
    addNamedSource(
        '/a.dart',
        r'''
class A {
  const A.named();
}
''');
    await _validateAnnotation('as p', '@p.A.named()', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<PrefixElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'p');
      expect(name2, isNotNull);
      expect(name2.staticElement, new isInstanceOf<ClassElement>());
      expect(resolutionMap.staticElementForIdentifier(name2).displayName, 'A');
      expect(name3, isNotNull);
      expect(name3.staticElement, new isInstanceOf<ConstructorElement>());
      expect(
          resolutionMap.staticElementForIdentifier(name3).displayName, 'named');
      if (annotationElement is ConstructorElement) {
        expect(annotationElement, same(name3.staticElement));
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'named');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_class_prefixed_staticConstField() async {
    addNamedSource(
        '/a.dart',
        r'''
class A {
  static const V = 0;
}
''');
    await _validateAnnotation('as p', '@p.A.V', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<PrefixElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'p');
      expect(name2, isNotNull);
      expect(name2.staticElement, new isInstanceOf<ClassElement>());
      expect(resolutionMap.staticElementForIdentifier(name2).displayName, 'A');
      expect(name3, isNotNull);
      expect(name3.staticElement, new isInstanceOf<PropertyAccessorElement>());
      expect(resolutionMap.staticElementForIdentifier(name3).displayName, 'V');
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name3.staticElement));
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_class_prefixed_unnamedConstructor() async {
    addNamedSource(
        '/a.dart',
        r'''
class A {
  const A();
}
''');
    await _validateAnnotation('as p', '@p.A', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<PrefixElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'p');
      expect(name2, isNotNull);
      expect(name2.staticElement, new isInstanceOf<ClassElement>());
      expect(resolutionMap.staticElementForIdentifier(name2).displayName, 'A');
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, '');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_class_staticConstField() async {
    addNamedSource(
        '/a.dart',
        r'''
class A {
  static const V = 0;
}
''');
    await _validateAnnotation('', '@A.V', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<ClassElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'A');
      expect(name2, isNotNull);
      expect(name2.staticElement, new isInstanceOf<PropertyAccessorElement>());
      expect(resolutionMap.staticElementForIdentifier(name2).displayName, 'V');
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_class_unnamedConstructor() async {
    addNamedSource(
        '/a.dart',
        r'''
class A {
  const A();
}
''');
    await _validateAnnotation('', '@A', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<ClassElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'A');
      expect(name2, isNull);
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, '');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_topLevelVariable() async {
    addNamedSource(
        '/a.dart',
        r'''
const V = 0;
''');
    await _validateAnnotation('', '@V', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<PropertyAccessorElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'V');
      expect(name2, isNull);
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name1.staticElement));
        expect(annotationElement.enclosingElement,
            new isInstanceOf<CompilationUnitElement>());
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_annotation_topLevelVariable_prefixed() async {
    addNamedSource(
        '/a.dart',
        r'''
const V = 0;
''');
    await _validateAnnotation('as p', '@p.V', (SimpleIdentifier name1,
        SimpleIdentifier name2,
        SimpleIdentifier name3,
        Element annotationElement) {
      expect(name1, isNotNull);
      expect(name1.staticElement, new isInstanceOf<PrefixElement>());
      expect(resolutionMap.staticElementForIdentifier(name1).displayName, 'p');
      expect(name2, isNotNull);
      expect(name2.staticElement, new isInstanceOf<PropertyAccessorElement>());
      expect(resolutionMap.staticElementForIdentifier(name2).displayName, 'V');
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement,
            new isInstanceOf<CompilationUnitElement>());
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement?.runtimeType}) $annotationElement found.');
      }
    });
  }

  Future<Null> _validateAnnotation(
      String annotationPrefix,
      String annotationText,
      validator(SimpleIdentifier name1, SimpleIdentifier name2,
          SimpleIdentifier name3, Element annotationElement)) async {
    CompilationUnit unit = await resolveSource('''
import 'a.dart' $annotationPrefix;
$annotationText
class C {}
''');
    var clazz = unit.declarations.single as ClassDeclaration;
    Annotation annotation = clazz.metadata.single;
    Identifier name = annotation.name;
    Element annotationElement = annotation.element;
    if (name is SimpleIdentifier) {
      validator(name, null, annotation.constructorName, annotationElement);
    } else if (name is PrefixedIdentifier) {
      validator(name.prefix, name.identifier, annotation.constructorName,
          annotationElement);
    } else {
      fail('Uknown "name": ${name?.runtimeType} $name');
    }
  }
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
    ExportDirective directive = AstTestFactory.exportDirective2(null, [
      AstTestFactory.hideCombinator2(["A"])
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
    ImportDirective directive = AstTestFactory.importDirective3(null, null, [
      AstTestFactory.showCombinator2(["A"])
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
    ImportDirective directive =
        AstTestFactory.importDirective3(null, prefixName, [
      AstTestFactory.showCombinator2(["A"]),
      AstTestFactory.hideCombinator2(["B"])
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

  test_lookUpMethodInInterfaces() async {
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
    SimpleIdentifier array = AstTestFactory.identifier3("a");
    array.staticType = classD.type;
    IndexExpression expression =
        AstTestFactory.indexExpression(array, AstTestFactory.identifier3("i"));
    expect(_resolveIndexExpression(expression), same(operator));
    _listener.assertNoErrors();
  }

  test_visitAssignmentExpression_compound() async {
    InterfaceType intType = _typeProvider.intType;
    SimpleIdentifier leftHandSide = AstTestFactory.identifier3("a");
    leftHandSide.staticType = intType;
    AssignmentExpression assignment = AstTestFactory.assignmentExpression(
        leftHandSide, TokenType.PLUS_EQ, AstTestFactory.integer(1));
    _resolveNode(assignment);
    expect(
        assignment.staticElement, same(getMethod(_typeProvider.numType, "+")));
    _listener.assertNoErrors();
  }

  test_visitAssignmentExpression_simple() async {
    AssignmentExpression expression = AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("x"),
        TokenType.EQ,
        AstTestFactory.integer(0));
    _resolveNode(expression);
    expect(expression.staticElement, isNull);
    _listener.assertNoErrors();
  }

  test_visitBinaryExpression_bangEq() async {
    // String i;
    // var j;
    // i == j
    InterfaceType stringType = _typeProvider.stringType;
    SimpleIdentifier left = AstTestFactory.identifier3("i");
    left.staticType = stringType;
    BinaryExpression expression = AstTestFactory.binaryExpression(
        left, TokenType.BANG_EQ, AstTestFactory.identifier3("j"));
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

  test_visitBinaryExpression_eq() async {
    // String i;
    // var j;
    // i == j
    InterfaceType stringType = _typeProvider.stringType;
    SimpleIdentifier left = AstTestFactory.identifier3("i");
    left.staticType = stringType;
    BinaryExpression expression = AstTestFactory.binaryExpression(
        left, TokenType.EQ_EQ, AstTestFactory.identifier3("j"));
    _resolveNode(expression);
    var stringElement = stringType.element;
    expect(
        expression.staticElement,
        stringElement.lookUpMethod(
            TokenType.EQ_EQ.lexeme, stringElement.library));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  test_visitBinaryExpression_plus() async {
    // num i;
    // var j;
    // i + j
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstTestFactory.identifier3("i");
    left.staticType = numType;
    BinaryExpression expression = AstTestFactory.binaryExpression(
        left, TokenType.PLUS, AstTestFactory.identifier3("j"));
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  test_visitBinaryExpression_plus_propagatedElement() async {
    // var i = 1;
    // var j;
    // i + j
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstTestFactory.identifier3("i");
    left.propagatedType = numType;
    BinaryExpression expression = AstTestFactory.binaryExpression(
        left, TokenType.PLUS, AstTestFactory.identifier3("j"));
    _resolveNode(expression);
    expect(expression.staticElement, isNull);
    expect(expression.propagatedElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  test_visitBreakStatement_withLabel() async {
    // loop: while (true) {
    //   break loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement = new LabelElementImpl.forNode(
        AstTestFactory.identifier3(label), false, false);
    BreakStatement breakStatement = AstTestFactory.breakStatement2(label);
    Expression condition = AstTestFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstTestFactory.whileStatement(condition, breakStatement);
    expect(_resolveBreak(breakStatement, labelElement, whileStatement),
        same(labelElement));
    expect(breakStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  test_visitBreakStatement_withoutLabel() async {
    BreakStatement statement = AstTestFactory.breakStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  test_visitCommentReference_prefixedIdentifier_class_getter() async {
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
    PrefixedIdentifier prefixed = AstTestFactory.identifier5('A', 'p');
    CommentReference commentReference =
        astFactory.commentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, getter);
    _listener.assertNoErrors();
  }

  test_visitCommentReference_prefixedIdentifier_class_method() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set method
    MethodElement method =
        ElementFactory.methodElement("m", _typeProvider.intType);
    classA.methods = <MethodElement>[method];
    // set name scope
    _visitor.nameScope = new EnclosedScope(null)
      ..defineNameWithoutChecking('A', classA);
    // prepare "A.m"
    PrefixedIdentifier prefixed = AstTestFactory.identifier5('A', 'm');
    CommentReference commentReference =
        astFactory.commentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, method);
    _listener.assertNoErrors();
  }

  test_visitCommentReference_prefixedIdentifier_class_operator() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set method
    MethodElement method =
        ElementFactory.methodElement("==", _typeProvider.boolType);
    classA.methods = <MethodElement>[method];
    // set name scope
    _visitor.nameScope = new EnclosedScope(null)
      ..defineNameWithoutChecking('A', classA);
    // prepare "A.=="
    PrefixedIdentifier prefixed = AstTestFactory.identifier5('A', '==');
    CommentReference commentReference =
        astFactory.commentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, method);
    _listener.assertNoErrors();
  }

  test_visitConstructorName_named() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.typeName(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  test_visitConstructorName_unnamed() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.typeName(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  test_visitContinueStatement_withLabel() async {
    // loop: while (true) {
    //   continue loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement = new LabelElementImpl.forNode(
        AstTestFactory.identifier3(label), false, false);
    ContinueStatement continueStatement =
        AstTestFactory.continueStatement(label);
    Expression condition = AstTestFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstTestFactory.whileStatement(condition, continueStatement);
    expect(_resolveContinue(continueStatement, labelElement, whileStatement),
        same(labelElement));
    expect(continueStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  test_visitContinueStatement_withoutLabel() async {
    ContinueStatement statement = AstTestFactory.continueStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  test_visitEnumDeclaration() async {
    CompilationUnitElementImpl compilationUnitElement =
        ElementFactory.compilationUnit('foo.dart');
    EnumElementImpl enumElement =
        ElementFactory.enumElement(_typeProvider, ('E'));
    compilationUnitElement.enums = <ClassElement>[enumElement];
    EnumDeclaration enumNode = AstTestFactory.enumDeclaration2('E', []);
    Annotation annotationNode =
        AstTestFactory.annotation(AstTestFactory.identifier3('a'));
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

  test_visitExportDirective_noCombinators() async {
    ExportDirective directive = AstTestFactory.exportDirective2(null);
    directive.element = ElementFactory
        .exportFor(ElementFactory.library(_definingLibrary.context, "lib"));
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  test_visitFieldFormalParameter() async {
    String fieldName = "f";
    InterfaceType intType = _typeProvider.intType;
    FieldElementImpl fieldElement =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[fieldElement];
    FieldFormalParameter parameter =
        AstTestFactory.fieldFormalParameter2(fieldName);
    FieldFormalParameterElementImpl parameterElement =
        ElementFactory.fieldFormalParameter(parameter.identifier);
    parameterElement.field = fieldElement;
    parameterElement.type = intType;
    parameter.identifier.staticElement = parameterElement;
    _resolveInClass(parameter, classA);
    expect(resolutionMap.elementDeclaredByFormalParameter(parameter).type,
        same(intType));
  }

  test_visitImportDirective_noCombinators_noPrefix() async {
    ImportDirective directive = AstTestFactory.importDirective3(null, null);
    directive.element = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"), null);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  test_visitImportDirective_noCombinators_prefix() async {
    String prefixName = "p";
    ImportElement importElement = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"),
        ElementFactory.prefix(prefixName));
    _definingLibrary.imports = <ImportElement>[importElement];
    ImportDirective directive =
        AstTestFactory.importDirective3(null, prefixName);
    directive.element = importElement;
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  test_visitImportDirective_withCombinators() async {
    ShowCombinator combinator = AstTestFactory.showCombinator2(["A", "B", "C"]);
    ImportDirective directive =
        AstTestFactory.importDirective3(null, null, [combinator]);
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

  test_visitIndexExpression_get() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType intType = _typeProvider.intType;
    MethodElement getter =
        ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement>[getter];
    SimpleIdentifier array = AstTestFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression =
        AstTestFactory.indexExpression(array, AstTestFactory.identifier3("i"));
    expect(_resolveIndexExpression(expression), same(getter));
    _listener.assertNoErrors();
  }

  test_visitIndexExpression_set() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType intType = _typeProvider.intType;
    MethodElement setter =
        ElementFactory.methodElement("[]=", intType, [intType]);
    classA.methods = <MethodElement>[setter];
    SimpleIdentifier array = AstTestFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression =
        AstTestFactory.indexExpression(array, AstTestFactory.identifier3("i"));
    AstTestFactory.assignmentExpression(
        expression, TokenType.EQ, AstTestFactory.integer(0));
    expect(_resolveIndexExpression(expression), same(setter));
    _listener.assertNoErrors();
  }

  test_visitInstanceCreationExpression_named() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  test_visitInstanceCreationExpression_unnamed() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  test_visitInstanceCreationExpression_unnamed_namedParameter() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    String parameterName = "a";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    constructor.parameters = <ParameterElement>[parameter];
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation = AstTestFactory
        .instanceCreationExpression(Keyword.NEW, name, [
      AstTestFactory.namedExpression2(parameterName, AstTestFactory.integer(0))
    ]);
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

  test_visitMethodInvocation() async {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstTestFactory.identifier3("i");
    left.staticType = numType;
    String methodName = "abs";
    MethodInvocation invocation =
        AstTestFactory.methodInvocation(left, methodName);
    _resolveNode(invocation);
    expect(invocation.methodName.staticElement,
        same(getMethod(numType, methodName)));
    _listener.assertNoErrors();
  }

  test_visitMethodInvocation_namedParameter() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    String parameterName = "p";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    method.parameters = <ParameterElement>[parameter];
    classA.methods = <MethodElement>[method];
    SimpleIdentifier left = AstTestFactory.identifier3("i");
    left.staticType = classA.type;
    MethodInvocation invocation = AstTestFactory.methodInvocation(
        left, methodName, [
      AstTestFactory.namedExpression2(parameterName, AstTestFactory.integer(0))
    ]);
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

  test_visitPostfixExpression() async {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = AstTestFactory.identifier3("i");
    operand.staticType = numType;
    PostfixExpression expression =
        AstTestFactory.postfixExpression(operand, TokenType.PLUS_PLUS);
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  test_visitPrefixedIdentifier_dynamic() async {
    DartType dynamicType = _typeProvider.dynamicType;
    SimpleIdentifier target = AstTestFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = dynamicType;
    target.staticElement = variable;
    target.staticType = dynamicType;
    PrefixedIdentifier identifier =
        AstTestFactory.identifier(target, AstTestFactory.identifier3("b"));
    _resolveNode(identifier);
    expect(identifier.staticElement, isNull);
    expect(identifier.identifier.staticElement, isNull);
    _listener.assertNoErrors();
  }

  test_visitPrefixedIdentifier_nonDynamic() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SimpleIdentifier target = AstTestFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = classA.type;
    target.staticElement = variable;
    target.staticType = classA.type;
    PrefixedIdentifier identifier = AstTestFactory.identifier(
        target, AstTestFactory.identifier3(getterName));
    _resolveNode(identifier);
    expect(identifier.staticElement, same(getter));
    expect(identifier.identifier.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  test_visitPrefixedIdentifier_staticClassMember_getter() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.m"
    SimpleIdentifier target = AstTestFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstTestFactory.identifier(target, AstTestFactory.identifier3(propName));
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(getter));
    expect(identifier.identifier.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  test_visitPrefixedIdentifier_staticClassMember_method() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set methods
    String propName = "m";
    MethodElement method =
        ElementFactory.methodElement("m", _typeProvider.intType);
    classA.methods = <MethodElement>[method];
    // prepare "A.m"
    SimpleIdentifier target = AstTestFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstTestFactory.identifier(target, AstTestFactory.identifier3(propName));
    AstTestFactory.assignmentExpression(
        identifier, TokenType.EQ, AstTestFactory.nullLiteral());
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(method));
    expect(identifier.identifier.staticElement, same(method));
    _listener.assertNoErrors();
  }

  test_visitPrefixedIdentifier_staticClassMember_setter() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.b = null"
    SimpleIdentifier target = AstTestFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstTestFactory.identifier(target, AstTestFactory.identifier3(propName));
    AstTestFactory.assignmentExpression(
        identifier, TokenType.EQ, AstTestFactory.nullLiteral());
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(setter));
    expect(identifier.identifier.staticElement, same(setter));
    _listener.assertNoErrors();
  }

  test_visitPrefixExpression() async {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = AstTestFactory.identifier3("i");
    operand.staticType = numType;
    PrefixExpression expression =
        AstTestFactory.prefixExpression(TokenType.PLUS_PLUS, operand);
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  test_visitPropertyAccess_getter_identifier() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SimpleIdentifier target = AstTestFactory.identifier3("a");
    target.staticType = classA.type;
    PropertyAccess access = AstTestFactory.propertyAccess2(target, getterName);
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  test_visitPropertyAccess_getter_super() async {
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
    SuperExpression target = AstTestFactory.superExpression();
    target.staticType = ElementFactory.classElement("B", classA.type).type;
    PropertyAccess access = AstTestFactory.propertyAccess2(target, getterName);
    AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.expressionFunctionBody(access));
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  test_visitPropertyAccess_setter_this() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "b";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setter];
    ThisExpression target = AstTestFactory.thisExpression();
    target.staticType = classA.type;
    PropertyAccess access = AstTestFactory.propertyAccess2(target, setterName);
    AstTestFactory.assignmentExpression(
        access, TokenType.EQ, AstTestFactory.integer(0));
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(setter));
    _listener.assertNoErrors();
  }

  test_visitSimpleIdentifier_classScope() async {
    InterfaceType doubleType = _typeProvider.doubleType;
    String fieldName = "NAN";
    SimpleIdentifier node = AstTestFactory.identifier3(fieldName);
    _resolveInClass(node, doubleType.element);
    expect(node.staticElement, getGetter(doubleType, fieldName));
    _listener.assertNoErrors();
  }

  test_visitSimpleIdentifier_dynamic() async {
    SimpleIdentifier node = AstTestFactory.identifier3("dynamic");
    _resolveIdentifier(node);
    expect(node.staticElement, same(_typeProvider.dynamicType.element));
    expect(node.staticType, same(_typeProvider.typeType));
    _listener.assertNoErrors();
  }

  test_visitSimpleIdentifier_lexicalScope() async {
    SimpleIdentifier node = AstTestFactory.identifier3("i");
    VariableElementImpl element = ElementFactory.localVariableElement(node);
    expect(_resolveIdentifier(node, [element]), same(element));
    _listener.assertNoErrors();
  }

  test_visitSimpleIdentifier_lexicalScope_field_setter() async {
    InterfaceType intType = _typeProvider.intType;
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String fieldName = "a";
    FieldElement field =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    classA.fields = <FieldElement>[field];
    classA.accessors = <PropertyAccessorElement>[field.getter, field.setter];
    SimpleIdentifier node = AstTestFactory.identifier3(fieldName);
    AstTestFactory.assignmentExpression(
        node, TokenType.EQ, AstTestFactory.integer(0));
    _resolveInClass(node, classA);
    Element element = node.staticElement;
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement, element);
    expect((element as PropertyAccessorElement).isSetter, isTrue);
    _listener.assertNoErrors();
  }

  test_visitSuperConstructorInvocation() async {
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
        AstTestFactory.superConstructorInvocation();
    AstTestFactory.classDeclaration(null, 'C', null, null, null, null, [
      AstTestFactory.constructorDeclaration(null, 'C', null, [invocation])
    ]);
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    _listener.assertNoErrors();
  }

  test_visitSuperConstructorInvocation_namedParameter() async {
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
    SuperConstructorInvocation invocation = AstTestFactory
        .superConstructorInvocation([
      AstTestFactory.namedExpression2(parameterName, AstTestFactory.integer(0))
    ]);
    AstTestFactory.classDeclaration(null, 'C', null, null, null, null, [
      AstTestFactory.constructorDeclaration(null, 'C', null, [invocation])
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
   * Create and return the resolver used by the tests.
   */
  ElementResolver _createResolver() {
    MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore(
        resourceProvider: resourceProvider);
    Source source = new FileSource(resourceProvider.getFile("/test.dart"));
    CompilationUnitElementImpl unit =
        new CompilationUnitElementImpl("test.dart");
    unit.librarySource = unit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = unit;
    _visitor = new ResolverVisitor(
        _definingLibrary, source, _typeProvider, _listener,
        nameScope: new LibraryScope(_definingLibrary));
    return _visitor.elementResolver;
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
  }
}
