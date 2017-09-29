// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.testing.element_factory;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart';

/**
 * The class `ElementFactory` defines utility methods used to create elements for testing
 * purposes. The elements that are created are complete in the sense that as much of the element
 * model as can be created, given the provided information, has been created.
 */
class ElementFactory {
  /**
   * The element representing the class 'Object'.
   */
  static ClassElementImpl _objectElement;

  static ClassElementImpl get object {
    if (_objectElement == null) {
      _objectElement = classElement("Object", null);
    }
    return _objectElement;
  }

  static InterfaceType get objectType => object.type;

  static ClassElementImpl classElement(
      String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element = new ClassElementImpl(typeName, 0);
    element.constructors = const <ConstructorElement>[];
    element.supertype = superclassType;
    if (parameterNames != null) {
      element.typeParameters = typeParameters(parameterNames);
    }
    return element;
  }

  static ClassElementImpl classElement2(String typeName,
          [List<String> parameterNames]) =>
      classElement(typeName, objectType, parameterNames);

  static classTypeAlias(String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element =
        classElement(typeName, superclassType, parameterNames);
    element.mixinApplication = true;
    return element;
  }

  static ClassElementImpl classTypeAlias2(String typeName,
          [List<String> parameterNames]) =>
      classTypeAlias(typeName, objectType, parameterNames);

  static CompilationUnitElementImpl compilationUnit(String fileName,
      [Source librarySource]) {
    Source source =
        new NonExistingSource(fileName, toUri(fileName), UriKind.FILE_URI);
    CompilationUnitElementImpl unit = new CompilationUnitElementImpl(fileName);
    unit.source = source;
    if (librarySource == null) {
      librarySource = source;
    }
    unit.librarySource = librarySource;
    return unit;
  }

  static ConstLocalVariableElementImpl constLocalVariableElement(String name) =>
      new ConstLocalVariableElementImpl(name, 0);

  static ConstructorElementImpl constructorElement(
      ClassElement definingClass, String name, bool isConst,
      [List<DartType> argumentTypes]) {
    ConstructorElementImpl constructor = name == null
        ? new ConstructorElementImpl("", -1)
        : new ConstructorElementImpl(name, 0);
    if (name != null) {
      if (name.isEmpty) {
        constructor.nameEnd = definingClass.name.length;
      } else {
        constructor.periodOffset = definingClass.name.length;
        constructor.nameEnd = definingClass.name.length + name.length + 1;
      }
    }
    constructor.isSynthetic = name == null;
    constructor.isConst = isConst;
    if (argumentTypes != null) {
      int count = argumentTypes.length;
      List<ParameterElement> parameters = new List<ParameterElement>(count);
      for (int i = 0; i < count; i++) {
        ParameterElementImpl parameter = new ParameterElementImpl("a$i", i);
        parameter.type = argumentTypes[i];
        parameter.parameterKind = ParameterKind.REQUIRED;
        parameters[i] = parameter;
      }
      constructor.parameters = parameters;
    } else {
      constructor.parameters = <ParameterElement>[];
    }
    constructor.enclosingElement = definingClass;
    if (!constructor.isSynthetic) {
      constructor.constantInitializers = <ConstructorInitializer>[];
    }
    return constructor;
  }

  static ConstructorElementImpl constructorElement2(
          ClassElement definingClass, String name,
          [List<DartType> argumentTypes]) =>
      constructorElement(definingClass, name, false, argumentTypes);

  static EnumElementImpl enumElement(TypeProvider typeProvider, String enumName,
      [List<String> constantNames]) {
    //
    // Build the enum.
    //
    EnumElementImpl enumElement = new EnumElementImpl(enumName, -1);
    InterfaceTypeImpl enumType = enumElement.type;
    //
    // Populate the fields.
    //
    List<FieldElement> fields = new List<FieldElement>();
    InterfaceType intType = typeProvider.intType;
    InterfaceType stringType = typeProvider.stringType;
    String indexFieldName = "index";
    FieldElementImpl indexField = new FieldElementImpl(indexFieldName, -1);
    indexField.isFinal = true;
    indexField.type = intType;
    fields.add(indexField);
    String nameFieldName = "_name";
    FieldElementImpl nameField = new FieldElementImpl(nameFieldName, -1);
    nameField.isFinal = true;
    nameField.type = stringType;
    fields.add(nameField);
    FieldElementImpl valuesField = new FieldElementImpl("values", -1);
    valuesField.isStatic = true;
    valuesField.isConst = true;
    valuesField.type = typeProvider.listType.instantiate(<DartType>[enumType]);
    fields.add(valuesField);
    //
    // Build the enum constants.
    //
    if (constantNames != null) {
      int constantCount = constantNames.length;
      for (int i = 0; i < constantCount; i++) {
        String constantName = constantNames[i];
        FieldElementImpl constantElement =
            new ConstFieldElementImpl(constantName, -1);
        constantElement.isStatic = true;
        constantElement.isConst = true;
        constantElement.type = enumType;
        HashMap<String, DartObjectImpl> fieldMap =
            new HashMap<String, DartObjectImpl>();
        fieldMap[indexFieldName] = new DartObjectImpl(intType, new IntState(i));
        fieldMap[nameFieldName] =
            new DartObjectImpl(stringType, new StringState(constantName));
        DartObjectImpl value =
            new DartObjectImpl(enumType, new GenericState(fieldMap));
        constantElement.evaluationResult = new EvaluationResultImpl(value);
        fields.add(constantElement);
      }
    }
    //
    // Finish building the enum.
    //
    enumElement.fields = fields;
    // Client code isn't allowed to invoke the constructor, so we do not model it.
    return enumElement;
  }

  static ExportElementImpl exportFor(LibraryElement exportedLibrary,
      [List<NamespaceCombinator> combinators =
          NamespaceCombinator.EMPTY_LIST]) {
    ExportElementImpl spec = new ExportElementImpl(-1);
    spec.exportedLibrary = exportedLibrary;
    spec.combinators = combinators;
    return spec;
  }

  static FieldElementImpl fieldElement(
      String name, bool isStatic, bool isFinal, bool isConst, DartType type,
      {Expression initializer}) {
    FieldElementImpl field = isConst
        ? new ConstFieldElementImpl(name, 0)
        : new FieldElementImpl(name, 0);
    field.isConst = isConst;
    field.isFinal = isFinal;
    field.isStatic = isStatic;
    field.type = type;
    if (isConst) {
      (field as ConstFieldElementImpl).constantInitializer = initializer;
    }
    new PropertyAccessorElementImpl_ImplicitGetter(field);
    if (!isConst && !isFinal) {
      new PropertyAccessorElementImpl_ImplicitSetter(field);
    }
    return field;
  }

  static FieldFormalParameterElementImpl fieldFormalParameter(
          Identifier name) =>
      new FieldFormalParameterElementImpl.forNode(name);

  /**
   * Destroy any static state retained by [ElementFactory].  This should be
   * called from the `setUp` method of any tests that use [ElementFactory], in
   * order to ensure that state is not shared between multiple tests.
   */
  static void flushStaticState() {
    _objectElement = null;
  }

  static FunctionElementImpl functionElement(String functionName) =>
      functionElement4(functionName, null, null, null, null);

  static FunctionElementImpl functionElement2(
          String functionName, DartType returnType) =>
      functionElement3(functionName, returnType, null, null);

  static FunctionElementImpl functionElement3(
      String functionName,
      DartType returnType,
      List<TypeDefiningElement> normalParameters,
      List<TypeDefiningElement> optionalParameters) {
    // We don't create parameter elements because we don't have parameter names
    FunctionElementImpl functionElement =
        new FunctionElementImpl(functionName, 0);
    FunctionTypeImpl functionType = new FunctionTypeImpl(functionElement);
    functionElement.type = functionType;
    functionElement.returnType = returnType ?? VoidTypeImpl.instance;
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int optionalCount =
        optionalParameters == null ? 0 : optionalParameters.length;
    int totalCount = normalCount + optionalCount;
    List<ParameterElement> parameters = new List<ParameterElement>(totalCount);
    for (int i = 0; i < totalCount; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl("a$i", i);
      if (i < normalCount) {
        parameter.type = normalParameters[i].type;
        parameter.parameterKind = ParameterKind.REQUIRED;
      } else {
        parameter.type = optionalParameters[i - normalCount].type;
        parameter.parameterKind = ParameterKind.POSITIONAL;
      }
      parameters[i] = parameter;
    }
    functionElement.parameters = parameters;
    // done
    return functionElement;
  }

  static FunctionElementImpl functionElement4(
      String functionName,
      ClassElement returnElement,
      List<ClassElement> normalParameters,
      List<String> names,
      List<ClassElement> namedParameters) {
    FunctionElementImpl functionElement =
        new FunctionElementImpl(functionName, 0);
    FunctionTypeImpl functionType = new FunctionTypeImpl(functionElement);
    functionElement.type = functionType;
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int nameCount = names == null ? 0 : names.length;
    int typeCount = namedParameters == null ? 0 : namedParameters.length;
    if (names != null && nameCount != typeCount) {
      throw new StateError(
          "The passed String[] and ClassElement[] arrays had different lengths.");
    }
    int totalCount = normalCount + nameCount;
    List<ParameterElement> parameters = new List<ParameterElement>(totalCount);
    for (int i = 0; i < totalCount; i++) {
      if (i < normalCount) {
        ParameterElementImpl parameter = new ParameterElementImpl("a$i", i);
        parameter.type = normalParameters[i].type;
        parameter.parameterKind = ParameterKind.REQUIRED;
        parameters[i] = parameter;
      } else {
        ParameterElementImpl parameter =
            new ParameterElementImpl(names[i - normalCount], i);
        parameter.type = namedParameters[i - normalCount].type;
        parameter.parameterKind = ParameterKind.NAMED;
        parameters[i] = parameter;
      }
    }
    functionElement.parameters = parameters;
    // return type
    if (returnElement == null) {
      functionElement.returnType = VoidTypeImpl.instance;
    } else {
      functionElement.returnType = returnElement.type;
    }
    return functionElement;
  }

  static FunctionElementImpl functionElement5(
          String functionName, List<ClassElement> normalParameters) =>
      functionElement3(functionName, null, normalParameters, null);

  static FunctionElementImpl functionElement6(
          String functionName,
          List<ClassElement> normalParameters,
          List<ClassElement> optionalParameters) =>
      functionElement3(
          functionName, null, normalParameters, optionalParameters);

  static FunctionElementImpl functionElement7(
          String functionName,
          List<ClassElement> normalParameters,
          List<String> names,
          List<ClassElement> namedParameters) =>
      functionElement4(
          functionName, null, normalParameters, names, namedParameters);

  static FunctionElementImpl functionElement8(
      List<DartType> parameters, DartType returnType,
      {List<DartType> optional, Map<String, DartType> named}) {
    List<ParameterElement> parameterElements = new List<ParameterElement>();
    for (int i = 0; i < parameters.length; i++) {
      ParameterElementImpl parameterElement =
          new ParameterElementImpl("a$i", i);
      parameterElement.type = parameters[i];
      parameterElement.parameterKind = ParameterKind.REQUIRED;
      parameterElements.add(parameterElement);
    }
    if (optional != null) {
      int j = parameters.length;
      for (int i = 0; i < optional.length; i++) {
        ParameterElementImpl parameterElement =
            new ParameterElementImpl("o$i", j);
        parameterElement.type = optional[i];
        parameterElement.parameterKind = ParameterKind.POSITIONAL;
        parameterElements.add(parameterElement);
        j++;
      }
    } else if (named != null) {
      int j = parameters.length;
      for (String s in named.keys) {
        ParameterElementImpl parameterElement = new ParameterElementImpl(s, j);
        parameterElement.type = named[s];
        parameterElement.parameterKind = ParameterKind.NAMED;
        parameterElements.add(parameterElement);
      }
    }

    return functionElementWithParameters("f", returnType, parameterElements);
  }

  static FunctionElementImpl functionElementWithParameters(String functionName,
      DartType returnType, List<ParameterElement> parameters) {
    FunctionElementImpl functionElement =
        new FunctionElementImpl(functionName, 0);
    functionElement.returnType =
        returnType == null ? VoidTypeImpl.instance : returnType;
    functionElement.parameters = parameters;
    FunctionTypeImpl functionType = new FunctionTypeImpl(functionElement);
    functionElement.type = functionType;
    return functionElement;
  }

  static GenericTypeAliasElementImpl genericTypeAliasElement(String name,
      {List<ParameterElement> parameters: const [], DartType returnType}) {
    var element = new GenericTypeAliasElementImpl(name, -1);
    element.function = new GenericFunctionTypeElementImpl.forOffset(-1)
      ..parameters = parameters
      ..returnType = returnType ?? DynamicTypeImpl.instance;
    element.type = new FunctionTypeImpl.forTypedef(element);
    return element;
  }

  static PropertyAccessorElementImpl getterElement(
      String name, bool isStatic, DartType type) {
    FieldElementImpl field = new FieldElementImpl(name, -1);
    field.isStatic = isStatic;
    field.isSynthetic = true;
    field.type = type;
    field.isFinal = true;
    PropertyAccessorElementImpl getter =
        new PropertyAccessorElementImpl(name, 0);
    getter.isSynthetic = false;
    getter.getter = true;
    getter.variable = field;
    getter.returnType = type;
    getter.isStatic = isStatic;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl(getter);
    getter.type = getterType;
    return getter;
  }

  static ImportElementImpl importFor(
      LibraryElement importedLibrary, PrefixElement prefix,
      [List<NamespaceCombinator> combinators =
          NamespaceCombinator.EMPTY_LIST]) {
    ImportElementImpl spec = new ImportElementImpl(0);
    spec.importedLibrary = importedLibrary;
    spec.prefix = prefix;
    spec.combinators = combinators;
    return spec;
  }

  static LibraryElementImpl library(
      AnalysisContext context, String libraryName) {
    String fileName = "/$libraryName.dart";
    CompilationUnitElementImpl unit = compilationUnit(fileName);
    LibraryElementImpl library =
        new LibraryElementImpl(context, libraryName, 0, libraryName.length);
    library.definingCompilationUnit = unit;
    return library;
  }

  static LocalVariableElementImpl localVariableElement(Identifier name) =>
      new LocalVariableElementImpl.forNode(name);

  static LocalVariableElementImpl localVariableElement2(String name) =>
      new LocalVariableElementImpl(name, 0);

  static MethodElementImpl methodElement(String methodName, DartType returnType,
      [List<DartType> argumentTypes]) {
    MethodElementImpl method = new MethodElementImpl(methodName, 0);
    if (argumentTypes == null) {
      method.parameters = ParameterElement.EMPTY_LIST;
    } else {
      int count = argumentTypes.length;
      List<ParameterElement> parameters = new List<ParameterElement>(count);
      for (int i = 0; i < count; i++) {
        ParameterElementImpl parameter = new ParameterElementImpl("a$i", i);
        parameter.type = argumentTypes[i];
        parameter.parameterKind = ParameterKind.REQUIRED;
        parameters[i] = parameter;
      }
      method.parameters = parameters;
    }
    method.returnType = returnType;
    FunctionTypeImpl methodType = new FunctionTypeImpl(method);
    method.type = methodType;
    return method;
  }

  static MethodElementImpl methodElementWithParameters(
      ClassElement enclosingElement,
      String methodName,
      DartType returnType,
      List<ParameterElement> parameters) {
    MethodElementImpl method = new MethodElementImpl(methodName, 0);
    method.enclosingElement = enclosingElement;
    method.parameters = parameters;
    method.returnType = returnType;
    method.type = new FunctionTypeImpl(method);
    return method;
  }

  static ParameterElementImpl namedParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    return parameter;
  }

  static ParameterElementImpl namedParameter2(String name, DartType type) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    return parameter;
  }

  static ParameterElementImpl namedParameter3(String name,
      {DartType type, Expression initializer, String initializerCode}) {
    DefaultParameterElementImpl parameter =
        new DefaultParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    parameter.constantInitializer = initializer;
    parameter.defaultValueCode = initializerCode;
    return parameter;
  }

  static ParameterElementImpl positionalParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    return parameter;
  }

  static ParameterElementImpl positionalParameter2(String name, DartType type) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    parameter.type = type;
    return parameter;
  }

  static PrefixElementImpl prefix(String name) =>
      new PrefixElementImpl(name, 0);

  static ParameterElementImpl requiredParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    return parameter;
  }

  static ParameterElementImpl requiredParameter2(String name, DartType type) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  static PropertyAccessorElementImpl setterElement(
      String name, bool isStatic, DartType type) {
    FieldElementImpl field = new FieldElementImpl(name, -1);
    field.isStatic = isStatic;
    field.isSynthetic = true;
    field.type = type;
    PropertyAccessorElementImpl getter =
        new PropertyAccessorElementImpl(name, -1);
    getter.getter = true;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl(getter);
    getter.type = getterType;
    ParameterElementImpl parameter = requiredParameter2("a", type);
    PropertyAccessorElementImpl setter =
        new PropertyAccessorElementImpl(name, -1);
    setter.setter = true;
    setter.isSynthetic = true;
    setter.variable = field;
    setter.parameters = <ParameterElement>[parameter];
    setter.returnType = VoidTypeImpl.instance;
    setter.type = new FunctionTypeImpl(setter);
    field.setter = setter;
    return setter;
  }

  static TopLevelVariableElementImpl topLevelVariableElement(Identifier name) =>
      new TopLevelVariableElementImpl.forNode(name);

  static TopLevelVariableElementImpl topLevelVariableElement2(String name) =>
      topLevelVariableElement3(name, false, false, null);

  static TopLevelVariableElementImpl topLevelVariableElement3(
      String name, bool isConst, bool isFinal, DartType type) {
    TopLevelVariableElementImpl variable;
    if (isConst) {
      ConstTopLevelVariableElementImpl constant =
          new ConstTopLevelVariableElementImpl.forNode(
              AstTestFactory.identifier3(name));
      InstanceCreationExpression initializer =
          AstTestFactory.instanceCreationExpression2(
              Keyword.CONST, AstTestFactory.typeName(type.element));
      if (type is InterfaceType) {
        ConstructorElement element = type.element.unnamedConstructor;
        initializer.staticElement = element;
        initializer.constructorName.staticElement = element;
      }
      constant.constantInitializer = initializer;
      variable = constant;
    } else {
      variable = new TopLevelVariableElementImpl(name, -1);
    }
    variable.isConst = isConst;
    variable.isFinal = isFinal;
    variable.isSynthetic = false;
    variable.type = type;
    new PropertyAccessorElementImpl_ImplicitGetter(variable);
    if (!isConst && !isFinal) {
      new PropertyAccessorElementImpl_ImplicitSetter(variable);
    }
    return variable;
  }

  static TypeParameterElementImpl typeParameterElement(String name) {
    TypeParameterElementImpl element = new TypeParameterElementImpl(name, 0);
    element.type = new TypeParameterTypeImpl(element);
    return element;
  }

  static List<TypeParameterElement> typeParameters(List<String> names) {
    int count = names.length;
    if (count == 0) {
      return TypeParameterElement.EMPTY_LIST;
    }
    List<TypeParameterElementImpl> typeParameters =
        new List<TypeParameterElementImpl>(count);
    for (int i = 0; i < count; i++) {
      typeParameters[i] = typeParameterWithType(names[i]);
    }
    return typeParameters;
  }

  static TypeParameterElementImpl typeParameterWithType(String name,
      [DartType bound]) {
    TypeParameterElementImpl typeParameter = typeParameterElement(name);
    typeParameter.type = new TypeParameterTypeImpl(typeParameter);
    typeParameter.bound = bound;
    return typeParameter;
  }
}
