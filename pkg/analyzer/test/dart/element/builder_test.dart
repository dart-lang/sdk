// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.dart.element.builder_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test.dart';
import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementBuilderTest);
  });
}

@reflectiveTest
class ElementBuilderTest extends ParserTestCase {
  CompilationUnitElement compilationUnitElement;
  CompilationUnit compilationUnit;

  /**
   * Parse the given [code], pass it through [ElementBuilder], and return the
   * resulting [ElementHolder].
   */
  ElementHolder buildElementsForText(String code) {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    try {
      compilationUnit = ParserTestCase.parseCompilationUnit(code);
      ElementHolder holder = new ElementHolder();
      ElementBuilder builder =
          new ElementBuilder(holder, compilationUnitElement);
      compilationUnit.accept(builder);
      return holder;
    } finally {
      expect(logger.log, hasLength(0));
      AnalysisEngine.instance.logger = Logger.NULL;
    }
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

  void test_metadata_fieldDeclaration() {
    List<FieldElement> fields =
        buildElementsForText('class C { @a int x, y; }').types[0].fields;
    checkMetadata(fields[0]);
    checkMetadata(fields[1]);
    expect(fields[0].metadata, same(fields[1].metadata));
  }

  void test_metadata_localVariableDeclaration() {
    List<LocalVariableElement> localVariables =
        buildElementsForText('f() { @a int x, y; }')
            .functions[0]
            .localVariables;
    checkMetadata(localVariables[0]);
    checkMetadata(localVariables[1]);
    expect(localVariables[0].metadata, same(localVariables[1].metadata));
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

  void test_metadata_visitDeclaredIdentifier() {
    LocalVariableElement localVariableElement =
        buildElementsForText('f() { for (@a var x in y) {} }')
            .functions[0]
            .localVariables[0];
    checkMetadata(localVariableElement);
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
        buildElementsForText('f([@a g() = null]) {}').functions[0].parameters[
            0];
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

  void test_visitCatchClause() {
    List<LocalVariableElement> variables =
        buildElementsForText('f() { try {} catch (e, s) {} }')
            .functions[0]
            .localVariables;
    String exceptionParameterName = "e";
    String stackParameterName = "s";
    expect(variables, hasLength(2));

    LocalVariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.hasImplicitType, isTrue);
    expect(exceptionVariable.isSynthetic, isFalse);
    expect(exceptionVariable.isConst, isFalse);
    expect(exceptionVariable.isFinal, isFalse);
    expect(exceptionVariable.initializer, isNull);
    _assertVisibleRange(exceptionVariable, 13, 28);

    LocalVariableElement stackVariable = variables[1];
    expect(stackVariable, isNotNull);
    expect(stackVariable.name, stackParameterName);
    expect(stackVariable.isSynthetic, isFalse);
    expect(stackVariable.isConst, isFalse);
    expect(stackVariable.isFinal, isFalse);
    expect(stackVariable.initializer, isNull);
    _assertVisibleRange(stackVariable, 13, 28);
  }

  void test_visitCatchClause_withType() {
    List<LocalVariableElement> variables =
        buildElementsForText('f() { try {} on E catch (e) {} }')
            .functions[0]
            .localVariables;
    String exceptionParameterName = "e";
    expect(variables, hasLength(1));
    VariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.hasImplicitType, isFalse);
  }

  void test_visitClassDeclaration_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        Keyword.ABSTRACT, className, null, null, null, null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
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
    expect(methodM.functions, isEmpty);
  }

  void test_visitClassDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration =
        AstFactory.classDeclaration(null, className, null, null, null, null);
    classDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    classDeclaration.endToken.offset = 80;
    classDeclaration.accept(builder);
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
    _assertHasCodeRange(type, 50, 31);
  }

  void test_visitClassDeclaration_parameterized() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    String firstVariableName = "E";
    String secondVariableName = "F";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([firstVariableName, secondVariableName]),
        null,
        null,
        null);
    classDeclaration.accept(builder);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    String typeParameterName = "E";
    String fieldName = "f";
    String methodName = "m";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([typeParameterName]),
        null,
        null,
        null, [
      AstFactory.fieldDeclaration2(
          false, null, [AstFactory.variableDeclaration(fieldName)]),
      AstFactory.methodDeclaration2(
          null,
          null,
          null,
          null,
          AstFactory.identifier3(methodName),
          AstFactory.formalParameterList(),
          AstFactory.blockFunctionBody2())
    ]);
    classDeclaration.accept(builder);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C', null, null, AstFactory.typeName(classB, []), withClause, null);
    alias.accept(builder);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias('C', null,
        Keyword.ABSTRACT, AstFactory.typeName(classB, []), withClause, null);
    classCAst.accept(builder);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElementImpl classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias(
        'C',
        AstFactory.typeParameterList(['T']),
        null,
        AstFactory.typeName(classB, []),
        withClause,
        null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.typeParameters, hasLength(1));
    expect(type.typeParameters[0].name, equals('T'));
  }

  void test_visitCompilationUnit_codeRange() {
    TopLevelVariableDeclaration topLevelVariableDeclaration = AstFactory
        .topLevelVariableDeclaration(null, AstFactory.typeName4('int'),
            [AstFactory.variableDeclaration('V')]);
    CompilationUnit unit = new CompilationUnit(
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

    CompilationUnitElement element = builder.compilationUnitElement;
    _assertHasCodeRange(element, 0, 41);
  }

  void test_visitConstructorDeclaration_external() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isTrue);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_factory() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            Keyword.FACTORY,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isTrue);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.documentationComment = AstFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    constructorDeclaration.endToken.offset = 80;
    constructorDeclaration.accept(builder);

    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    _assertHasCodeRange(constructor, 50, 31);
    expect(constructor.documentationComment, '/// aaa');
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_named() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            constructorName,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, constructorName);
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.name.staticElement, same(constructor));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitConstructorDeclaration_unnamed() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitDeclaredIdentifier_noType() {
    LocalVariableElement variable =
        buildElementsForText('f() { for (var i in []) {} }')
            .functions[0]
            .localVariables[0];
    _assertHasCodeRange(variable, 11, 5);
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
    LocalVariableElement variable =
        buildElementsForText('f() { for (int i in []) {} }')
            .functions[0]
            .localVariables[0];
    _assertHasCodeRange(variable, 11, 5);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = 'p';
    DefaultFormalParameter formalParameter =
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter3(parameterName),
            AstFactory.integer(0));
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);

    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    _assertHasCodeRange(parameter, 50, 31);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = 'p';
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter4(
            AstFactory.typeName4('E'), parameterName),
        AstFactory.integer(0));
    formalParameter.accept(builder);

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

  void test_visitEnumDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String enumName = "E";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2(enumName, ["ONE"]);
    enumDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    enumDeclaration.endToken.offset = 80;
    enumDeclaration.accept(builder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    ClassElement enumElement = enums[0];
    expect(enumElement, isNotNull);
    _assertHasCodeRange(enumElement, 50, 31);
    expect(enumElement.documentationComment, '/// aaa');
    expect(enumElement.name, enumName);
  }

  void test_visitFieldDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String firstFieldName = "x";
    String secondFieldName = "y";
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [
      AstFactory.variableDeclaration(firstFieldName),
      AstFactory.variableDeclaration(secondFieldName)
    ]);
    fieldDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    fieldDeclaration.endToken.offset = 110;
    fieldDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(2));

    FieldElement firstField = fields[0];
    expect(firstField, isNotNull);
    _assertHasCodeRange(firstField, 50, 61);
    expect(firstField.documentationComment, '/// aaa');
    expect(firstField.name, firstFieldName);
    expect(firstField.initializer, isNull);
    expect(firstField.isConst, isFalse);
    expect(firstField.isFinal, isFalse);
    expect(firstField.isSynthetic, isFalse);

    FieldElement secondField = fields[1];
    expect(secondField, isNotNull);
    _assertHasCodeRange(secondField, 50, 61);
    expect(secondField.documentationComment, '/// aaa');
    expect(secondField.name, secondFieldName);
    expect(secondField.initializer, isNull);
    expect(secondField.isConst, isFalse);
    expect(secondField.isFinal, isFalse);
    expect(secondField.isSynthetic, isFalse);
  }

  void test_visitFieldFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter =
        AstFactory.fieldFormalParameter(null, null, parameterName);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    _assertHasCodeRange(parameter, 50, 31);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(0));
  }

  void test_visitFieldFormalParameter_functionTyped() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter = AstFactory.fieldFormalParameter(
        null,
        null,
        parameterName,
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("a")]));
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
    expect(parameter.parameters, hasLength(1));
  }

  void test_visitFormalParameterList() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String firstParameterName = "a";
    String secondParameterName = "b";
    FormalParameterList parameterList = AstFactory.formalParameterList([
      AstFactory.simpleFormalParameter3(firstParameterName),
      AstFactory.simpleFormalParameter3(secondParameterName)
    ]);
    parameterList.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
  }

  void test_visitFunctionDeclaration_external() {
    // external f();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.emptyFunctionBody()));
    declaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    declaration.accept(builder);

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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.GET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;
    declaration.accept(builder);

    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    _assertHasCodeRange(accessor, 50, 31);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('T'),
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    _assertHasCodeRange(function, 50, 31);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.SET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;
    declaration.accept(builder);

    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    _assertHasCodeRange(accessor, 50, 31);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = 'f';
    String typeParameterName = 'E';
    FunctionExpression expression = AstFactory.functionExpression3(
        AstFactory.typeParameterList([typeParameterName]),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    FunctionDeclaration declaration =
        AstFactory.functionDeclaration(null, null, functionName, expression);
    declaration.accept(builder);

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

  void test_visitFunctionExpression() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    FunctionExpression expression = AstFactory.functionExpression2(
        AstFactory.formalParameterList(), AstFactory.blockFunctionBody2());
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
    List<FunctionElement> functions =
        buildElementsForText('f() { return () => 42; }').functions[0].functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionExpression_inExpressionBody() {
    List<FunctionElement> functions =
        buildElementsForText('f() => () => 42;').functions[0].functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
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
    FunctionTypeAlias aliasNode = AstFactory.typeAlias(
        null, aliasName, AstFactory.typeParameterList([parameterName]), null);
    aliasNode.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    aliasNode.endToken.offset = 80;
    aliasNode.accept(builder);

    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    _assertHasCodeRange(alias, 50, 31);
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
        AstFactory.functionTypedFormalParameter(null, parameterName);
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

  void test_visitFunctionTypedFormalParameter_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstFactory.functionTypedFormalParameter(null, parameterName);
    formalParameter.typeParameters = AstFactory.typeParameterList(['F']);
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
    expect(parameter.typeParameters, hasLength(1));
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitLabeledStatement() {
    List<LabelElement> labels =
        buildElementsForText('f() { l: print(42); }').functions[0].labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, 'l');
    expect(label.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_abstract() {
    // m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isTrue);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_getter() {
    // get m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    _assertHasCodeRange(getter, 50, 31);
    expect(getter.documentationComment, '/// aaa');
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_abstract() {
    // get m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

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
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_external() {
    // external get m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

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
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_minimal() {
    // T m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        AstFactory.typeName4('T'),
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    _assertHasCodeRange(method, 50, 31);
    expect(method.documentationComment, '/// aaa');
    expect(method.hasImplicitReturnType, isFalse);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_operator() {
    // operator +(addend) {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "+";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        Keyword.OPERATOR,
        AstFactory.identifier3(methodName),
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("addend")]),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(1));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_setter() {
    // set m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);

    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    _assertHasCodeRange(setter, 50, 31);
    expect(setter.documentationComment, '/// aaa');
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_abstract() {
    // set m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

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
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_external() {
    // external m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

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
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_static() {
    // static m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        Keyword.STATIC,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isTrue);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_typeParameters() {
    // m<E>() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.typeParameters = AstFactory.typeParameterList(['E']);
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(1));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_withMembers() {
    MethodElement method = buildElementsForText(
            'class C { m(p) { var v; try { l: return; } catch (e) {} } }')
        .types[0]
        .methods[0];
    String methodName = "m";
    String parameterName = "p";
    String localVariableName = "v";
    String labelName = "l";
    String exceptionParameterName = "e";
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
    List<VariableElement> localVariables = method.localVariables;
    expect(localVariables, hasLength(2));
    VariableElement firstVariable = localVariables[0];
    VariableElement secondVariable = localVariables[1];
    expect(firstVariable, isNotNull);
    expect(secondVariable, isNotNull);
    expect(
        (firstVariable.name == localVariableName &&
                secondVariable.name == exceptionParameterName) ||
            (firstVariable.name == exceptionParameterName &&
                secondVariable.name == localVariableName),
        isTrue);
    List<LabelElement> labels = method.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
  }

  void test_visitNamedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3(parameterName),
        AstFactory.identifier3("42"));
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    _assertHasCodeRange(parameter, 50, 32);
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

  void test_visitSimpleFormalParameter_noType() {
    // p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter =
        AstFactory.simpleFormalParameter3(parameterName);
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

  void test_visitSimpleFormalParameter_type() {
    // T p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter = AstFactory.simpleFormalParameter4(
        AstFactory.typeName4('T'), parameterName);
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

  void test_visitTypeAlias_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, null, null);
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
  }

  void test_visitTypeAlias_withFormalParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    String firstParameterName = "x";
    String secondParameterName = "y";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(),
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3(firstParameterName),
          AstFactory.simpleFormalParameter3(secondParameterName)
        ]));
    typeAlias.beginToken.offset = 50;
    typeAlias.endToken.offset = 80;
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    _assertHasCodeRange(alias, 50, 31);
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    String firstTypeParameterName = "A";
    String secondTypeParameterName = "B";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(
            [firstTypeParameterName, secondTypeParameterName]),
        AstFactory.formalParameterList());
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
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
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "E";
    TypeParameter typeParameter = AstFactory.typeParameter(parameterName);
    typeParameter.beginToken.offset = 50;
    typeParameter.accept(builder);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameterElement = typeParameters[0];
    expect(typeParameterElement, isNotNull);
    _assertHasCodeRange(typeParameterElement, 50, 1);
    expect(typeParameterElement.name, parameterName);
    expect(typeParameterElement.bound, isNull);
    expect(typeParameterElement.isSynthetic, isFalse);
  }

  void test_visitVariableDeclaration_inConstructor() {
    List<ConstructorElement> constructors =
        buildElementsForText('class C { C() { var v = 1; } }')
            .types[0]
            .constructors;
    expect(constructors, hasLength(1));
    List<LocalVariableElement> variableElements =
        constructors[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    _assertHasCodeRange(variableElement, 16, 10);
    expect(variableElement.hasImplicitType, isTrue);
    expect(variableElement.name, 'v');
    _assertVisibleRange(variableElement, 14, 28);
  }

  void test_visitVariableDeclaration_inForEachStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() { for (var v in []) }
    //
    String variableName = "v";
    Statement statement = AstFactory.forEachStatement(
        AstFactory.declaredIdentifier3('v'),
        AstFactory.listLiteral(),
        AstFactory.block());
    _setNodeSourceRange(statement, 100, 110);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 200, 220);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
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
    ForStatement statement = AstFactory.forStatement2(
        AstFactory.variableDeclarationList(null, AstFactory.typeName4('T'),
            [AstFactory.variableDeclaration('v')]),
        null,
        null,
        AstFactory.block());
    _setNodeSourceRange(statement, 100, 110);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 200, 220);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
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
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement = AstFactory.variableDeclarationStatement(
        null, AstFactory.typeName4('T'), [variable]);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 100, 110);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
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
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    Expression initializer = AstFactory.functionExpression2(
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    String fieldName = "f";
    VariableDeclaration field =
        AstFactory.variableDeclaration2(fieldName, initializer);
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [field]);
    fieldDeclaration.accept(builder);

    List<FieldElement> variables = holder.fields;
    expect(variables, hasLength(1));
    FieldElement fieldElement = variables[0];
    expect(fieldElement, isNotNull);
    FunctionElement initializerElement = fieldElement.initializer;
    expect(initializerElement, isNotNull);
    expect(initializerElement.hasImplicitReturnType, isTrue);
    List<FunctionElement> functionElements = initializerElement.functions;
    expect(functionElements, hasLength(1));
    List<LocalVariableElement> variableElements =
        functionElements[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
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
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(null, [variableDeclaration]);
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
        AstFactory.variableDeclaration('a');
    VariableDeclaration variableDeclaration2 =
        AstFactory.variableDeclaration('b');
    TopLevelVariableDeclaration topLevelVariableDeclaration = AstFactory
        .topLevelVariableDeclaration(
            Keyword.FINAL, null, [variableDeclaration1, variableDeclaration2]);
    topLevelVariableDeclaration.documentationComment = AstFactory
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
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, AstFactory.integer(42));
    AstFactory.variableDeclarationList2(Keyword.CONST, [variableDeclaration]);
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
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(Keyword.FINAL, [variableDeclaration]);
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

  void _assertHasCodeRange(Element element, int offset, int length) {
    ElementImpl elementImpl = element;
    expect(elementImpl.codeOffset, offset);
    expect(elementImpl.codeLength, length);
  }

  void _assertVisibleRange(LocalElement element, int offset, int end) {
    SourceRange visibleRange = element.visibleRange;
    expect(visibleRange.offset, offset);
    expect(visibleRange.end, end);
  }

  ElementBuilder _makeBuilder(ElementHolder holder) =>
      new ElementBuilder(holder, new CompilationUnitElementImpl('test.dart'));

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
    Block block = AstFactory.block();
    block.leftBracket.offset = blockOffset;
    block.rightBracket.offset = blockEnd - 1;
    BlockFunctionBody body = AstFactory.blockFunctionBody(block);
    AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("main"),
        AstFactory.formalParameterList([formalParameter]),
        body);
  }
}
