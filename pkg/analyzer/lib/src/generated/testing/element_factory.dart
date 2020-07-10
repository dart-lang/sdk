// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

/// The class `ElementFactory` defines utility methods used to create elements
/// for testing purposes. The elements that are created are complete in the
/// sense that as much of the element model as can be created, given the
/// provided information, has been created.
class ElementFactory {
  /// The element representing the class 'Object'.
  static ClassElementImpl _objectElement;
  static InterfaceType _objectType;

  static ClassElementImpl get object {
    return _objectElement ??= classElement("Object", null);
  }

  static InterfaceType get objectType {
    return _objectType ??= object.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  static ClassElementImpl classElement(
      String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element = ClassElementImpl(typeName, 0);
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

  static ClassElementImpl classElement3({
    @required String name,
    List<TypeParameterElement> typeParameters,
    List<String> typeParameterNames = const [],
    InterfaceType supertype,
    List<InterfaceType> mixins = const [],
    List<InterfaceType> interfaces = const [],
  }) {
    typeParameters ??= ElementFactory.typeParameters(typeParameterNames);
    supertype ??= objectType;

    var element = ClassElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.supertype = supertype;
    element.mixins = mixins;
    element.interfaces = interfaces;
    element.constructors = const <ConstructorElement>[];
    return element;
  }

  static ClassElementImpl classTypeAlias(
      String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element =
        classElement(typeName, superclassType, parameterNames);
    element.isMixinApplication = true;
    return element;
  }

  static ClassElementImpl classTypeAlias2(String typeName,
          [List<String> parameterNames]) =>
      classTypeAlias(typeName, objectType, parameterNames);

  static CompilationUnitElementImpl compilationUnit(String fileName,
      [Source librarySource]) {
    Source source =
        NonExistingSource(fileName, toUri(fileName), UriKind.FILE_URI);
    CompilationUnitElementImpl unit = CompilationUnitElementImpl();
    unit.source = source;
    librarySource ??= source;
    unit.librarySource = librarySource;
    return unit;
  }

  static ConstLocalVariableElementImpl constLocalVariableElement(String name) =>
      ConstLocalVariableElementImpl(name, 0);

  static ConstructorElementImpl constructorElement(
      ClassElement definingClass, String name, bool isConst,
      [List<DartType> argumentTypes]) {
    ConstructorElementImpl constructor = name == null
        ? ConstructorElementImpl("", -1)
        : ConstructorElementImpl(name, 0);
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
      List<ParameterElement> parameters = List<ParameterElement>(count);
      for (int i = 0; i < count; i++) {
        ParameterElementImpl parameter = ParameterElementImpl("a$i", i);
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

  @deprecated
  static EnumElementImpl enumElement(TypeProvider typeProvider, String enumName,
      [List<String> constantNames]) {
    var typeSystem = TypeSystemImpl(
      implicitCasts: false,
      isNonNullableByDefault: false,
      strictInference: false,
      typeProvider: typeProvider,
    );
    //
    // Build the enum.
    //
    EnumElementImpl enumElement = EnumElementImpl(enumName, -1);
    InterfaceTypeImpl enumType = enumElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    //
    // Populate the fields.
    //
    List<FieldElement> fields = <FieldElement>[];
    InterfaceType intType = typeProvider.intType;
    InterfaceType stringType = typeProvider.stringType;
    String indexFieldName = "index";
    FieldElementImpl indexField = FieldElementImpl(indexFieldName, -1);
    indexField.isFinal = true;
    indexField.type = intType;
    fields.add(indexField);
    String nameFieldName = "_name";
    FieldElementImpl nameField = FieldElementImpl(nameFieldName, -1);
    nameField.isFinal = true;
    nameField.type = stringType;
    fields.add(nameField);
    FieldElementImpl valuesField = FieldElementImpl("values", -1);
    valuesField.isStatic = true;
    valuesField.isConst = true;
    valuesField.type = typeProvider.listType2(enumType);
    fields.add(valuesField);
    //
    // Build the enum constants.
    //
    if (constantNames != null) {
      int constantCount = constantNames.length;
      for (int i = 0; i < constantCount; i++) {
        String constantName = constantNames[i];
        FieldElementImpl constantElement =
            ConstFieldElementImpl(constantName, -1);
        constantElement.isStatic = true;
        constantElement.isConst = true;
        constantElement.type = enumType;
        Map<String, DartObjectImpl> fieldMap =
            HashMap<String, DartObjectImpl>();
        fieldMap[indexFieldName] =
            DartObjectImpl(typeSystem, intType, IntState(i));
        fieldMap[nameFieldName] =
            DartObjectImpl(typeSystem, stringType, StringState(constantName));
        DartObjectImpl value =
            DartObjectImpl(typeSystem, enumType, GenericState(fieldMap));
        constantElement.evaluationResult = EvaluationResultImpl(value);
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
      [List<NamespaceCombinator> combinators = const <NamespaceCombinator>[]]) {
    ExportElementImpl spec = ExportElementImpl(-1);
    spec.exportedLibrary = exportedLibrary;
    spec.combinators = combinators;
    return spec;
  }

  static ExtensionElementImpl extensionElement(
          [String name, DartType extendedType]) =>
      ExtensionElementImpl(name, -1)..extendedType = extendedType;

  static FieldElementImpl fieldElement(
      String name, bool isStatic, bool isFinal, bool isConst, DartType type,
      {Expression initializer}) {
    FieldElementImpl field =
        isConst ? ConstFieldElementImpl(name, 0) : FieldElementImpl(name, 0);
    field.isConst = isConst;
    field.isFinal = isFinal;
    field.isStatic = isStatic;
    field.type = type;
    if (isConst) {
      (field as ConstFieldElementImpl).constantInitializer = initializer;
    }
    PropertyAccessorElementImpl_ImplicitGetter(field);
    if (!isConst && !isFinal) {
      PropertyAccessorElementImpl_ImplicitSetter(field);
    }
    return field;
  }

  static FieldFormalParameterElementImpl fieldFormalParameter(
          Identifier name) =>
      FieldFormalParameterElementImpl(name.name, name.offset);

  /// Destroy any static state retained by [ElementFactory].  This should be
  /// called from the `setUp` method of any tests that use [ElementFactory], in
  /// order to ensure that state is not shared between multiple tests.
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
    FunctionElementImpl functionElement = FunctionElementImpl(functionName, 0);
    functionElement.returnType = returnType ?? VoidTypeImpl.instance;
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int optionalCount =
        optionalParameters == null ? 0 : optionalParameters.length;
    int totalCount = normalCount + optionalCount;
    List<ParameterElement> parameters = List<ParameterElement>(totalCount);
    for (int i = 0; i < totalCount; i++) {
      ParameterElementImpl parameter = ParameterElementImpl("a$i", i);
      if (i < normalCount) {
        parameter.type = _typeDefiningElementType(normalParameters[i]);
        parameter.parameterKind = ParameterKind.REQUIRED;
      } else {
        parameter.type =
            _typeDefiningElementType(optionalParameters[i - normalCount]);
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
    FunctionElementImpl functionElement = FunctionElementImpl(functionName, 0);
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int nameCount = names == null ? 0 : names.length;
    int typeCount = namedParameters == null ? 0 : namedParameters.length;
    if (names != null && nameCount != typeCount) {
      throw StateError(
          "The passed String[] and ClassElement[] arrays had different lengths.");
    }
    int totalCount = normalCount + nameCount;
    List<ParameterElement> parameters = List<ParameterElement>(totalCount);
    for (int i = 0; i < totalCount; i++) {
      if (i < normalCount) {
        ParameterElementImpl parameter = ParameterElementImpl("a$i", i);
        parameter.type = _typeDefiningElementType(normalParameters[i]);
        parameter.parameterKind = ParameterKind.REQUIRED;
        parameters[i] = parameter;
      } else {
        ParameterElementImpl parameter =
            ParameterElementImpl(names[i - normalCount], i);
        parameter.type =
            _typeDefiningElementType(namedParameters[i - normalCount]);
        parameter.parameterKind = ParameterKind.NAMED;
        parameters[i] = parameter;
      }
    }
    functionElement.parameters = parameters;
    // return type
    if (returnElement == null) {
      functionElement.returnType = VoidTypeImpl.instance;
    } else {
      functionElement.returnType = _typeDefiningElementType(returnElement);
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
    List<ParameterElement> parameterElements = <ParameterElement>[];
    for (int i = 0; i < parameters.length; i++) {
      ParameterElementImpl parameterElement = ParameterElementImpl("a$i", i);
      parameterElement.type = parameters[i];
      parameterElement.parameterKind = ParameterKind.REQUIRED;
      parameterElements.add(parameterElement);
    }
    if (optional != null) {
      int j = parameters.length;
      for (int i = 0; i < optional.length; i++) {
        ParameterElementImpl parameterElement = ParameterElementImpl("o$i", j);
        parameterElement.type = optional[i];
        parameterElement.parameterKind = ParameterKind.POSITIONAL;
        parameterElements.add(parameterElement);
        j++;
      }
    } else if (named != null) {
      int j = parameters.length;
      for (String s in named.keys) {
        ParameterElementImpl parameterElement = ParameterElementImpl(s, j);
        parameterElement.type = named[s];
        parameterElement.parameterKind = ParameterKind.NAMED;
        parameterElements.add(parameterElement);
      }
    }

    return functionElementWithParameters("f", returnType, parameterElements);
  }

  static FunctionElementImpl functionElementWithParameters(String functionName,
      DartType returnType, List<ParameterElement> parameters) {
    FunctionElementImpl functionElement = FunctionElementImpl(functionName, 0);
    functionElement.returnType = returnType ?? VoidTypeImpl.instance;
    functionElement.parameters = parameters;
    return functionElement;
  }

  static GenericTypeAliasElementImpl genericTypeAliasElement(String name,
      {List<ParameterElement> parameters = const [], DartType returnType}) {
    var element = GenericTypeAliasElementImpl(name, -1);
    element.function = GenericFunctionTypeElementImpl.forOffset(-1)
      ..parameters = parameters
      ..returnType = returnType ?? DynamicTypeImpl.instance;
    return element;
  }

  static PropertyAccessorElementImpl getterElement(
      String name, bool isStatic, DartType type) {
    FieldElementImpl field = FieldElementImpl(name, -1);
    field.isStatic = isStatic;
    field.isSynthetic = true;
    field.type = type;
    field.isFinal = true;
    PropertyAccessorElementImpl getter = PropertyAccessorElementImpl(name, 0);
    getter.isSynthetic = false;
    getter.isGetter = true;
    getter.variable = field;
    getter.returnType = type;
    getter.isStatic = isStatic;
    field.getter = getter;
    return getter;
  }

  static ImportElementImpl importFor(
      LibraryElement importedLibrary, PrefixElement prefix,
      [List<NamespaceCombinator> combinators = const <NamespaceCombinator>[]]) {
    ImportElementImpl spec = ImportElementImpl(0);
    spec.importedLibrary = importedLibrary;
    spec.prefix = prefix;
    spec.combinators = combinators;
    return spec;
  }

  static LibraryElementImpl library(AnalysisContext context, String libraryName,
      {bool isNonNullableByDefault = true}) {
    String fileName = "/$libraryName.dart";
    CompilationUnitElementImpl unit = compilationUnit(fileName);
    LibraryElementImpl library = LibraryElementImpl(
        context,
        AnalysisSessionImpl(null),
        libraryName,
        0,
        libraryName.length,
        isNonNullableByDefault);
    library.definingCompilationUnit = unit;
    return library;
  }

  static LocalVariableElementImpl localVariableElement(Identifier name) =>
      LocalVariableElementImpl(name.name, name.offset);

  static LocalVariableElementImpl localVariableElement2(String name) =>
      LocalVariableElementImpl(name, 0);

  static MethodElementImpl methodElement(String methodName, DartType returnType,
      [List<DartType> argumentTypes]) {
    MethodElementImpl method = MethodElementImpl(methodName, 0);
    if (argumentTypes == null) {
      method.parameters = const <ParameterElement>[];
    } else {
      int count = argumentTypes.length;
      List<ParameterElement> parameters = List<ParameterElement>(count);
      for (int i = 0; i < count; i++) {
        ParameterElementImpl parameter = ParameterElementImpl("a$i", i);
        parameter.type = argumentTypes[i];
        parameter.parameterKind = ParameterKind.REQUIRED;
        parameters[i] = parameter;
      }
      method.parameters = parameters;
    }
    method.returnType = returnType;
    return method;
  }

  static MethodElementImpl methodElementWithParameters(
      ClassElement enclosingElement,
      String methodName,
      DartType returnType,
      List<ParameterElement> parameters) {
    MethodElementImpl method = MethodElementImpl(methodName, 0);
    method.enclosingElement = enclosingElement;
    method.parameters = parameters;
    method.returnType = returnType;
    return method;
  }

  static MixinElementImpl mixinElement({
    @required String name,
    List<TypeParameterElement> typeParameters,
    List<String> typeParameterNames = const [],
    List<InterfaceType> constraints = const [],
    List<InterfaceType> interfaces = const [],
  }) {
    typeParameters ??= ElementFactory.typeParameters(typeParameterNames);

    if (constraints.isEmpty) {
      constraints = [objectType];
    }

    var element = MixinElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.superclassConstraints = constraints;
    element.interfaces = interfaces;
    element.constructors = const <ConstructorElement>[];
    return element;
  }

  static ParameterElementImpl namedParameter(String name) {
    ParameterElementImpl parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    return parameter;
  }

  static ParameterElementImpl namedParameter2(String name, DartType type) {
    ParameterElementImpl parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    return parameter;
  }

  static ParameterElementImpl namedParameter3(String name,
      {DartType type, Expression initializer, String initializerCode}) {
    DefaultParameterElementImpl parameter =
        DefaultParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    parameter.constantInitializer = initializer;
    parameter.defaultValueCode = initializerCode;
    return parameter;
  }

  static ParameterElementImpl positionalParameter(String name) {
    ParameterElementImpl parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    return parameter;
  }

  static ParameterElementImpl positionalParameter2(String name, DartType type) {
    ParameterElementImpl parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    parameter.type = type;
    return parameter;
  }

  static PrefixElementImpl prefix(String name) => PrefixElementImpl(name, 0);

  static ParameterElementImpl requiredParameter(String name) {
    ParameterElementImpl parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    return parameter;
  }

  static ParameterElementImpl requiredParameter2(String name, DartType type) {
    ParameterElementImpl parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  static PropertyAccessorElementImpl setterElement(
      String name, bool isStatic, DartType type) {
    FieldElementImpl field = FieldElementImpl(name, -1);
    field.isStatic = isStatic;
    field.isSynthetic = true;
    field.type = type;
    PropertyAccessorElementImpl getter = PropertyAccessorElementImpl(name, -1);
    getter.isGetter = true;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    ParameterElementImpl parameter = requiredParameter2("a", type);
    PropertyAccessorElementImpl setter = PropertyAccessorElementImpl(name, -1);
    setter.isSetter = true;
    setter.isSynthetic = true;
    setter.variable = field;
    setter.parameters = <ParameterElement>[parameter];
    setter.returnType = VoidTypeImpl.instance;
    setter.isStatic = isStatic;
    field.setter = setter;
    return setter;
  }

  static TopLevelVariableElementImpl topLevelVariableElement(Identifier name) =>
      TopLevelVariableElementImpl(name.name, name.offset);

  static TopLevelVariableElementImpl topLevelVariableElement2(String name) =>
      topLevelVariableElement3(name, false, false, null);

  static TopLevelVariableElementImpl topLevelVariableElement3(
      String name, bool isConst, bool isFinal, DartType type) {
    TopLevelVariableElementImpl variable;
    if (isConst) {
      ConstTopLevelVariableElementImpl constant =
          ConstTopLevelVariableElementImpl(name, -1);
      InstanceCreationExpression initializer =
          AstTestFactory.instanceCreationExpression2(
              Keyword.CONST, AstTestFactory.typeName(type.element));
      if (type is InterfaceType) {
        ConstructorElement element = type.element.unnamedConstructor;
        initializer.constructorName.staticElement = element;
      }
      constant.constantInitializer = initializer;
      variable = constant;
    } else {
      variable = TopLevelVariableElementImpl(name, -1);
    }
    variable.isConst = isConst;
    variable.isFinal = isFinal;
    variable.isSynthetic = false;
    variable.type = type;
    PropertyAccessorElementImpl_ImplicitGetter(variable);
    if (!isConst && !isFinal) {
      PropertyAccessorElementImpl_ImplicitSetter(variable);
    }
    return variable;
  }

  static TypeParameterElementImpl typeParameterElement(String name) {
    return TypeParameterElementImpl(name, 0);
  }

  static List<TypeParameterElement> typeParameters(List<String> names) {
    int count = names.length;
    if (count == 0) {
      return const <TypeParameterElement>[];
    }
    List<TypeParameterElementImpl> typeParameters =
        List<TypeParameterElementImpl>(count);
    for (int i = 0; i < count; i++) {
      typeParameters[i] = typeParameterWithType(names[i]);
    }
    return typeParameters;
  }

  static TypeParameterElementImpl typeParameterWithType(String name,
      [DartType bound, Variance variance]) {
    TypeParameterElementImpl typeParameter = typeParameterElement(name);
    typeParameter.bound = bound;
    typeParameter.variance = variance;
    return typeParameter;
  }

  static DartType _typeDefiningElementType(TypeDefiningElement element) {
    if (element is ClassElement) {
      return element.instantiate(
        typeArguments: List.filled(
          element.typeParameters.length,
          DynamicTypeImpl.instance,
        ),
        nullabilitySuffix: NullabilitySuffix.star,
      );
    }
    throw ArgumentError('element: (${element.runtimeType}) $element');
  }
}
