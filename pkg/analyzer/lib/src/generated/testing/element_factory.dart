// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.testing.element_factory;

import 'dart:collection';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';

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

  static ClassElementImpl classElement(String typeName, InterfaceType superclassType, List<String> parameterNames) {
    ClassElementImpl element = new ClassElementImpl(typeName, 0);
    element.supertype = superclassType;
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(element);
    element.type = type;
    int count = parameterNames.length;
    if (count > 0) {
      List<TypeParameterElementImpl> typeParameters = new List<TypeParameterElementImpl>(count);
      List<TypeParameterTypeImpl> typeParameterTypes = new List<TypeParameterTypeImpl>(count);
      for (int i = 0; i < count; i++) {
        TypeParameterElementImpl typeParameter = new TypeParameterElementImpl(parameterNames[i], 0);
        typeParameters[i] = typeParameter;
        typeParameterTypes[i] = new TypeParameterTypeImpl(typeParameter);
        typeParameter.type = typeParameterTypes[i];
      }
      element.typeParameters = typeParameters;
      type.typeArguments = typeParameterTypes;
    }
    return element;
  }

  static ClassElementImpl classElement2(String typeName, List<String> parameterNames) => classElement(typeName, objectType, parameterNames);

  static CompilationUnitElementImpl compilationUnit(String fileName) {
    Source source = new NonExistingSource(fileName, UriKind.FILE_URI);
    CompilationUnitElementImpl unit = new CompilationUnitElementImpl(fileName);
    unit.source = source;
    return unit;
  }

  static ConstructorElementImpl constructorElement(ClassElement definingClass, String name, bool isConst, List<DartType> argumentTypes) {
    DartType type = definingClass.type;
    ConstructorElementImpl constructor = name == null ? new ConstructorElementImpl("", -1) : new ConstructorElementImpl(name, 0);
    constructor.const2 = isConst;
    int count = argumentTypes.length;
    List<ParameterElement> parameters = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl("a$i", i);
      parameter.type = argumentTypes[i];
      parameter.parameterKind = ParameterKind.REQUIRED;
      parameters[i] = parameter;
    }
    constructor.parameters = parameters;
    constructor.returnType = type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    return constructor;
  }

  static ConstructorElementImpl constructorElement2(ClassElement definingClass, String name, List<DartType> argumentTypes) => constructorElement(definingClass, name, false, argumentTypes);

  static ClassElementImpl enumElement(TypeProvider typeProvider, String enumName, List<String> constantNames) {
    //
    // Build the enum.
    //
    ClassElementImpl enumElement = new ClassElementImpl(enumName, -1);
    InterfaceTypeImpl enumType = new InterfaceTypeImpl.con1(enumElement);
    enumElement.type = enumType;
    enumElement.supertype = objectType;
    //
    // Populate the fields.
    //
    List<FieldElement> fields = new List<FieldElement>();
    InterfaceType intType = typeProvider.intType;
    InterfaceType stringType = typeProvider.stringType;
    String indexFieldName = "index";
    FieldElementImpl indexField = new FieldElementImpl(indexFieldName, -1);
    indexField.final2 = true;
    indexField.type = intType;
    fields.add(indexField);
    String nameFieldName = "_name";
    FieldElementImpl nameField = new FieldElementImpl(nameFieldName, -1);
    nameField.final2 = true;
    nameField.type = stringType;
    fields.add(nameField);
    FieldElementImpl valuesField = new FieldElementImpl("values", -1);
    valuesField.static = true;
    valuesField.const3 = true;
    valuesField.type = typeProvider.listType.substitute4(<DartType> [enumType]);
    fields.add(valuesField);
    //
    // Build the enum constants.
    //
    int constantCount = constantNames.length;
    for (int i = 0; i < constantCount; i++) {
      String constantName = constantNames[i];
      FieldElementImpl constantElement = new ConstFieldElementImpl.con2(constantName, -1);
      constantElement.static = true;
      constantElement.const3 = true;
      constantElement.type = enumType;
      HashMap<String, DartObjectImpl> fieldMap = new HashMap<String, DartObjectImpl>();
      fieldMap[indexFieldName] = new DartObjectImpl(intType, new IntState(i));
      fieldMap[nameFieldName] = new DartObjectImpl(stringType, new StringState(constantName));
      DartObjectImpl value = new DartObjectImpl(enumType, new GenericState(fieldMap));
      constantElement.evaluationResult = new EvaluationResultImpl.con1(value);
      fields.add(constantElement);
    }
    //
    // Finish building the enum.
    //
    enumElement.fields = fields;
    // Client code isn't allowed to invoke the constructor, so we do not model it.
    return enumElement;
  }

  static ExportElementImpl exportFor(LibraryElement exportedLibrary, List<NamespaceCombinator> combinators) {
    ExportElementImpl spec = new ExportElementImpl();
    spec.exportedLibrary = exportedLibrary;
    spec.combinators = combinators;
    return spec;
  }

  static FieldElementImpl fieldElement(String name, bool isStatic, bool isFinal, bool isConst, DartType type) {
    FieldElementImpl field = new FieldElementImpl(name, 0);
    field.const3 = isConst;
    field.final2 = isFinal;
    field.static = isStatic;
    field.type = type;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.forVariable(field);
    getter.getter = true;
    getter.synthetic = true;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    if (!isConst && !isFinal) {
      PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.forVariable(field);
      setter.setter = true;
      setter.synthetic = true;
      setter.variable = field;
      setter.parameters = <ParameterElement> [requiredParameter2("_$name", type)];
      setter.returnType = VoidTypeImpl.instance;
      setter.type = new FunctionTypeImpl.con1(setter);
      field.setter = setter;
    }
    return field;
  }

  static FieldFormalParameterElementImpl fieldFormalParameter(Identifier name) => new FieldFormalParameterElementImpl(name);

  static FunctionElementImpl functionElement(String functionName) => functionElement4(functionName, null, null, null, null);

  static FunctionElementImpl functionElement2(String functionName, ClassElement returnElement) => functionElement3(functionName, returnElement, null, null);

  static FunctionElementImpl functionElement3(String functionName, ClassElement returnElement, List<ClassElement> normalParameters, List<ClassElement> optionalParameters) {
    // We don't create parameter elements because we don't have parameter names
    FunctionElementImpl functionElement = new FunctionElementImpl(functionName, 0);
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    // return type
    if (returnElement == null) {
      functionElement.returnType = VoidTypeImpl.instance;
    } else {
      functionElement.returnType = returnElement.type;
    }
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int optionalCount = optionalParameters == null ? 0 : optionalParameters.length;
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

  static FunctionElementImpl functionElement4(String functionName, ClassElement returnElement, List<ClassElement> normalParameters, List<String> names, List<ClassElement> namedParameters) {
    FunctionElementImpl functionElement = new FunctionElementImpl(functionName, 0);
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int nameCount = names == null ? 0 : names.length;
    int typeCount = namedParameters == null ? 0 : namedParameters.length;
    if (names != null && nameCount != typeCount) {
      throw new IllegalStateException("The passed String[] and ClassElement[] arrays had different lengths.");
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
        ParameterElementImpl parameter = new ParameterElementImpl(names[i - normalCount], i);
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

  static FunctionElementImpl functionElement5(String functionName, List<ClassElement> normalParameters) => functionElement3(functionName, null, normalParameters, null);

  static FunctionElementImpl functionElement6(String functionName, List<ClassElement> normalParameters, List<ClassElement> optionalParameters) => functionElement3(functionName, null, normalParameters, optionalParameters);

  static FunctionElementImpl functionElement7(String functionName, List<ClassElement> normalParameters, List<String> names, List<ClassElement> namedParameters) => functionElement4(functionName, null, normalParameters, names, namedParameters);

  static FunctionElementImpl functionElementWithParameters(String functionName, DartType returnType, List<ParameterElement> parameters) {
    FunctionElementImpl functionElement = new FunctionElementImpl(functionName, 0);
    functionElement.returnType = returnType == null ? VoidTypeImpl.instance : returnType;
    functionElement.parameters = parameters;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    return functionElement;
  }

  static ClassElementImpl get object {
    if (_objectElement == null) {
      _objectElement = classElement("Object", null, []);
    }
    return _objectElement;
  }

  static InterfaceType get objectType => object.type;

  static PropertyAccessorElementImpl getterElement(String name, bool isStatic, DartType type) {
    FieldElementImpl field = new FieldElementImpl(name, -1);
    field.static = isStatic;
    field.synthetic = true;
    field.type = type;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.forVariable(field);
    getter.getter = true;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    return getter;
  }

  static HtmlElementImpl htmlUnit(AnalysisContext context, String fileName) {
    Source source = new NonExistingSource(fileName, UriKind.FILE_URI);
    HtmlElementImpl unit = new HtmlElementImpl(context, fileName);
    unit.source = source;
    return unit;
  }

  static ImportElementImpl importFor(LibraryElement importedLibrary, PrefixElement prefix, List<NamespaceCombinator> combinators) {
    ImportElementImpl spec = new ImportElementImpl(0);
    spec.importedLibrary = importedLibrary;
    spec.prefix = prefix;
    spec.combinators = combinators;
    return spec;
  }

  static LibraryElementImpl library(AnalysisContext context, String libraryName) {
    String fileName = "/$libraryName.dart";
    CompilationUnitElementImpl unit = compilationUnit(fileName);
    LibraryElementImpl library = new LibraryElementImpl(context, libraryName, 0);
    library.definingCompilationUnit = unit;
    return library;
  }

  static LocalVariableElementImpl localVariableElement(Identifier name) => new LocalVariableElementImpl.forNode(name);

  static LocalVariableElementImpl localVariableElement2(String name) => new LocalVariableElementImpl(name, 0);

  static MethodElementImpl methodElement(String methodName, DartType returnType, List<DartType> argumentTypes) {
    MethodElementImpl method = new MethodElementImpl(methodName, 0);
    int count = argumentTypes.length;
    List<ParameterElement> parameters = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl("a$i", i);
      parameter.type = argumentTypes[i];
      parameter.parameterKind = ParameterKind.REQUIRED;
      parameters[i] = parameter;
    }
    method.parameters = parameters;
    method.returnType = returnType;
    FunctionTypeImpl methodType = new FunctionTypeImpl.con1(method);
    method.type = methodType;
    return method;
  }

  static MethodElementImpl methodElementWithParameters(String methodName, List<DartType> typeArguments, DartType returnType, List<ParameterElement> parameters) {
    MethodElementImpl method = new MethodElementImpl(methodName, 0);
    method.parameters = parameters;
    method.returnType = returnType;
    FunctionTypeImpl methodType = new FunctionTypeImpl.con1(method);
    methodType.typeArguments = typeArguments;
    method.type = methodType;
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

  static PrefixElementImpl prefix(String name) => new PrefixElementImpl(name, 0);

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

  static PropertyAccessorElementImpl setterElement(String name, bool isStatic, DartType type) {
    FieldElementImpl field = new FieldElementImpl(name, -1);
    field.static = isStatic;
    field.synthetic = true;
    field.type = type;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.forVariable(field);
    getter.getter = true;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    ParameterElementImpl parameter = requiredParameter2("a", type);
    PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.forVariable(field);
    setter.setter = true;
    setter.synthetic = true;
    setter.variable = field;
    setter.parameters = <ParameterElement> [parameter];
    setter.returnType = VoidTypeImpl.instance;
    setter.type = new FunctionTypeImpl.con1(setter);
    field.setter = setter;
    return setter;
  }

  static TopLevelVariableElementImpl topLevelVariableElement(Identifier name) => new TopLevelVariableElementImpl.forNode(name);

  static TopLevelVariableElementImpl topLevelVariableElement2(String name) => topLevelVariableElement3(name, false, false, null);

  static TopLevelVariableElementImpl topLevelVariableElement3(String name, bool isConst, bool isFinal, DartType type) {
    TopLevelVariableElementImpl variable = new TopLevelVariableElementImpl(name, -1);
    variable.const3 = isConst;
    variable.final2 = isFinal;
    variable.synthetic = true;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.forVariable(variable);
    getter.getter = true;
    getter.synthetic = true;
    getter.variable = variable;
    getter.returnType = type;
    variable.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    if (!isFinal) {
      PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.forVariable(variable);
      setter.setter = true;
      setter.static = true;
      setter.synthetic = true;
      setter.variable = variable;
      setter.parameters = <ParameterElement> [requiredParameter2("_$name", type)];
      setter.returnType = VoidTypeImpl.instance;
      setter.type = new FunctionTypeImpl.con1(setter);
      variable.setter = setter;
    }
    return variable;
  }
}