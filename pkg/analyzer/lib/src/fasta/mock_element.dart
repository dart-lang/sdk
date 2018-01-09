// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_element;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/builder/builder.dart' show Builder;

import 'package:front_end/src/fasta/problems.dart' show unsupported;

abstract class MockElement extends Builder implements Element, LocalElement {
  @override
  final ElementKind kind;

  MockElement(this.kind) : super(null, -1, null);

  @override
  get librarySource => unsupported("librarySource", charOffset, fileUri);

  @override
  get source => unsupported("source", charOffset, fileUri);

  @override
  get context => unsupported("context", charOffset, fileUri);

  @override
  String get displayName => unsupported("displayName", charOffset, fileUri);

  @override
  String get documentationComment =>
      unsupported("documentationComment", charOffset, fileUri);

  @override
  Element get enclosingElement =>
      unsupported("enclosingElement", charOffset, fileUri);

  @override
  int get id => unsupported("id", charOffset, fileUri);

  @override
  bool get isDeprecated => unsupported("isDeprecated", charOffset, fileUri);

  @override
  bool get isFactory => unsupported("isFactory", charOffset, fileUri);

  @override
  bool get isJS => unsupported("isJS", charOffset, fileUri);

  @override
  bool get isOverride => unsupported("isOverride", charOffset, fileUri);

  @override
  bool get isPrivate => unsupported("isPrivate", charOffset, fileUri);

  @override
  bool get isProtected => unsupported("isProtected", charOffset, fileUri);

  @override
  bool get isPublic => unsupported("isPublic", charOffset, fileUri);

  @override
  bool get isRequired => unsupported("isRequired", charOffset, fileUri);

  @override
  bool get isSynthetic => unsupported("isSynthetic", charOffset, fileUri);

  @override
  LibraryElement get library => unsupported("library", charOffset, fileUri);

  @override
  get location => unsupported("location", charOffset, fileUri);

  @override
  get metadata => unsupported("metadata", charOffset, fileUri);

  @override
  String get name => unsupported("name", charOffset, fileUri);

  @override
  String get fullNameForErrors => name;

  @override
  int get nameLength => unsupported("nameLength", charOffset, fileUri);

  @override
  int get nameOffset => -1;

  @override
  get unit => unsupported("unit", charOffset, fileUri);

  @override
  accept<T>(visitor) => unsupported("accept", charOffset, fileUri);

  @override
  String computeDocumentationComment() =>
      unsupported("computeDocumentationComment", charOffset, fileUri);

  @override
  computeNode() => unsupported("computeNode", charOffset, fileUri);

  @override
  getAncestor<E extends Element>(predicate) =>
      unsupported("getAncestor", charOffset, fileUri);

  @override
  String getExtendedDisplayName(String shortName) {
    return unsupported("getExtendedDisplayName", charOffset, fileUri);
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    return unsupported("isAccessibleIn", charOffset, fileUri);
  }

  @override
  void visitChildren(visitor) =>
      unsupported("visitChildren", charOffset, fileUri);

  String get uri => unsupported("uri", charOffset, fileUri);

  int get uriEnd => unsupported("uriEnd", charOffset, fileUri);

  int get uriOffset => unsupported("uriOffset", charOffset, fileUri);

  List<ParameterElement> get parameters =>
      unsupported("parameters", charOffset, fileUri);

  List<FunctionElement> get functions =>
      unsupported("functions", charOffset, fileUri);

  bool get hasImplicitReturnType =>
      unsupported("hasImplicitReturnType", charOffset, fileUri);

  bool get isAbstract => unsupported("isAbstract", charOffset, fileUri);

  bool get isAsynchronous => unsupported("isAsynchronous", charOffset, fileUri);

  bool get isExternal => unsupported("isExternal", charOffset, fileUri);

  bool get isGenerator => unsupported("isGenerator", charOffset, fileUri);

  bool get isOperator => unsupported("isOperator", charOffset, fileUri);

  @override
  bool get isStatic => unsupported("isStatic", charOffset, fileUri);

  bool get isSynchronous => unsupported("isSynchronous", charOffset, fileUri);

  @override
  get visibleRange => unsupported("visibleRange", charOffset, fileUri);

  bool get hasImplicitType =>
      unsupported("hasImplicitType", charOffset, fileUri);

  FunctionElement get initializer =>
      unsupported("initializer", charOffset, fileUri);

  @override
  bool get isConst => unsupported("isConst", charOffset, fileUri);

  @override
  bool get isFinal => unsupported("isFinal", charOffset, fileUri);

  bool get isPotentiallyMutatedInClosure =>
      unsupported("isPotentiallyMutatedInClosure", charOffset, fileUri);

  bool get isPotentiallyMutatedInScope =>
      unsupported("isPotentiallyMutatedInScope", charOffset, fileUri);
}

abstract class MockLibraryElement extends MockElement
    implements LibraryElement {
  MockLibraryElement() : super(ElementKind.LIBRARY);

  @override
  CompilationUnitElement get definingCompilationUnit {
    return unsupported("definingCompilationUnit", charOffset, fileUri);
  }

  @override
  FunctionElement get entryPoint =>
      unsupported("entryPoint", charOffset, fileUri);

  @override
  List<LibraryElement> get exportedLibraries {
    return unsupported("exportedLibraries", charOffset, fileUri);
  }

  @override
  get exportNamespace => unsupported("exportNamespace", charOffset, fileUri);

  @override
  get exports => unsupported("exports", charOffset, fileUri);

  @override
  bool get hasExtUri => unsupported("hasExtUri", charOffset, fileUri);

  @override
  bool get hasLoadLibraryFunction =>
      unsupported("hasLoadLibraryFunction", charOffset, fileUri);

  @override
  String get identifier => unsupported("identifier", charOffset, fileUri);

  @override
  List<LibraryElement> get importedLibraries {
    return unsupported("importedLibraries", charOffset, fileUri);
  }

  @override
  get imports => unsupported("imports", charOffset, fileUri);

  @override
  bool get isBrowserApplication =>
      unsupported("isBrowserApplication", charOffset, fileUri);

  @override
  bool get isDartAsync => unsupported("isDartAsync", charOffset, fileUri);

  @override
  bool get isDartCore => unsupported("isDartCore", charOffset, fileUri);

  @override
  bool get isInSdk => unsupported("isInSdk", charOffset, fileUri);

  @override
  List<LibraryElement> get libraryCycle =>
      unsupported("libraryCycle", charOffset, fileUri);

  @override
  FunctionElement get loadLibraryFunction =>
      unsupported("loadLibraryFunction", charOffset, fileUri);

  @override
  List<CompilationUnitElement> get parts =>
      unsupported("parts", charOffset, fileUri);

  @override
  List<PrefixElement> get prefixes =>
      unsupported("prefixes", charOffset, fileUri);

  @override
  get publicNamespace => unsupported("publicNamespace", charOffset, fileUri);

  @override
  List<CompilationUnitElement> get units =>
      unsupported("units", charOffset, fileUri);

  @override
  getImportsWithPrefix(PrefixElement prefix) {
    return unsupported("getImportsWithPrefix", charOffset, fileUri);
  }

  @override
  ClassElement getType(String className) =>
      unsupported("getType", charOffset, fileUri);
}

abstract class MockCompilationUnitElement extends MockElement
    implements CompilationUnitElement {
  MockCompilationUnitElement() : super(ElementKind.COMPILATION_UNIT);

  @override
  List<PropertyAccessorElement> get accessors {
    return unsupported("accessors", charOffset, fileUri);
  }

  @override
  LibraryElement get enclosingElement =>
      unsupported("enclosingElement", charOffset, fileUri);

  @override
  List<ClassElement> get enums => unsupported("enums", charOffset, fileUri);

  @override
  List<FunctionElement> get functions =>
      unsupported("functions", charOffset, fileUri);

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases {
    return unsupported("functionTypeAliases", charOffset, fileUri);
  }

  @override
  bool get hasLoadLibraryFunction =>
      unsupported("hasLoadLibraryFunction", charOffset, fileUri);

  @override
  LineInfo get lineInfo => unsupported("lineInfo", charOffset, fileUri);

  @override
  List<TopLevelVariableElement> get topLevelVariables {
    return unsupported("topLevelVariables", charOffset, fileUri);
  }

  @override
  List<ClassElement> get types => unsupported("types", charOffset, fileUri);

  @override
  ClassElement getEnum(String name) =>
      unsupported("getEnum", charOffset, fileUri);

  @override
  ClassElement getType(String name) =>
      unsupported("getType", charOffset, fileUri);

  @override
  CompilationUnit computeNode() =>
      unsupported("computeNode", charOffset, fileUri);
}

abstract class MockClassElement extends MockElement implements ClassElement {
  MockClassElement() : super(ElementKind.CLASS);

  List<PropertyAccessorElement> get accessors {
    return unsupported("accessors", charOffset, fileUri);
  }

  @override
  get allSupertypes => unsupported("allSupertypes", charOffset, fileUri);

  @override
  List<ConstructorElement> get constructors =>
      unsupported("constructors", charOffset, fileUri);

  @override
  List<FieldElement> get fields => unsupported("fields", charOffset, fileUri);

  @override
  bool get hasNonFinalField =>
      unsupported("hasNonFinalField", charOffset, fileUri);

  @override
  bool get hasReferenceToSuper =>
      unsupported("hasReferenceToSuper", charOffset, fileUri);

  @override
  bool get hasStaticMember =>
      unsupported("hasStaticMember", charOffset, fileUri);

  @override
  get interfaces => unsupported("interfaces", charOffset, fileUri);

  @override
  bool get isAbstract => unsupported("isAbstract", charOffset, fileUri);

  @override
  bool get isEnum => unsupported("isEnum", charOffset, fileUri);

  @override
  bool get isMixinApplication =>
      unsupported("isMixinApplication", charOffset, fileUri);

  @override
  bool get isOrInheritsProxy =>
      unsupported("isOrInheritsProxy", charOffset, fileUri);

  @override
  bool get isProxy => unsupported("isProxy", charOffset, fileUri);

  @override
  bool get isValidMixin => unsupported("isValidMixin", charOffset, fileUri);

  @override
  get typeParameters => unsupported("typeParameters", charOffset, fileUri);

  @override
  List<MethodElement> get methods =>
      unsupported("methods", charOffset, fileUri);

  @override
  get mixins => unsupported("mixins", charOffset, fileUri);

  @override
  get supertype => unsupported("supertype", charOffset, fileUri);

  @override
  ConstructorElement get unnamedConstructor =>
      unsupported("unnamedConstructor", charOffset, fileUri);

  @override
  FieldElement getField(String name) =>
      unsupported("getField", charOffset, fileUri);

  @override
  PropertyAccessorElement getGetter(String name) {
    return unsupported("getGetter", charOffset, fileUri);
  }

  @override
  MethodElement getMethod(String name) =>
      unsupported("getMethod", charOffset, fileUri);

  @override
  ConstructorElement getNamedConstructor(String name) {
    return unsupported("getNamedConstructor", charOffset, fileUri);
  }

  @override
  PropertyAccessorElement getSetter(String name) {
    return unsupported("getSetter", charOffset, fileUri);
  }

  @override
  bool isSuperConstructorAccessible(ConstructorElement constructor) {
    return unsupported("isSuperConstructorAccessible", charOffset, fileUri);
  }

  @override
  MethodElement lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    return unsupported("lookUpConcreteMethod", charOffset, fileUri);
  }

  @override
  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library) {
    return unsupported("lookUpGetter", charOffset, fileUri);
  }

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library) {
    return unsupported("lookUpInheritedConcreteGetter", charOffset, fileUri);
  }

  @override
  MethodElement lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library) {
    return unsupported("lookUpInheritedConcreteMethod", charOffset, fileUri);
  }

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return unsupported("lookUpInheritedConcreteSetter", charOffset, fileUri);
  }

  @override
  MethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return unsupported("lookUpInheritedMethod", charOffset, fileUri);
  }

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    return unsupported("lookUpMethod", charOffset, fileUri);
  }

  @override
  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library) {
    return unsupported("lookUpSetter", charOffset, fileUri);
  }

  @override
  NamedCompilationUnitMember computeNode() =>
      unsupported("computeNode", charOffset, fileUri);

  @override
  InterfaceType get type => unsupported("type", charOffset, fileUri);
}

abstract class MockFunctionElement extends MockElement
    implements FunctionElement {
  MockFunctionElement() : super(ElementKind.FUNCTION);

  @override
  bool get isEntryPoint => unsupported("isEntryPoint", charOffset, fileUri);

  @override
  get typeParameters => unsupported("typeParameters", charOffset, fileUri);

  @override
  FunctionType get type => unsupported("type", charOffset, fileUri);

  @override
  DartType get returnType => unsupported("returnType", charOffset, fileUri);

  @override
  FunctionDeclaration computeNode() =>
      unsupported("computeNode", charOffset, fileUri);
}

abstract class MockFunctionTypeAliasElement extends MockElement
    implements FunctionTypeAliasElement {
  MockFunctionTypeAliasElement() : super(ElementKind.FUNCTION_TYPE_ALIAS);

  @override
  CompilationUnitElement get enclosingElement {
    return unsupported("enclosingElement", charOffset, fileUri);
  }

  @override
  TypeAlias computeNode() => unsupported("computeNode", charOffset, fileUri);
}

abstract class MockParameterElement extends MockElement
    implements ParameterElement {
  MockParameterElement() : super(ElementKind.PARAMETER);

  @override
  String get defaultValueCode =>
      unsupported("defaultValueCode", charOffset, fileUri);

  @override
  bool get isCovariant => unsupported("isCovariant", charOffset, fileUri);

  @override
  bool get isInitializingFormal =>
      unsupported("isInitializingFormal", charOffset, fileUri);

  @override
  get parameterKind => unsupported("parameterKind", charOffset, fileUri);

  @override
  List<ParameterElement> get parameters =>
      unsupported("parameters", charOffset, fileUri);

  @override
  get type => null;

  @override
  get typeParameters => unsupported("typeParameters", charOffset, fileUri);

  @override
  get constantValue => unsupported("constantValue", charOffset, fileUri);

  @override
  computeConstantValue() =>
      unsupported("computeConstantValue", charOffset, fileUri);

  @override
  void appendToWithoutDelimiters(StringBuffer buffer) {
    return unsupported("appendToWithoutDelimiters", charOffset, fileUri);
  }

  @override
  FormalParameter computeNode() =>
      unsupported("computeNode", charOffset, fileUri);
}
