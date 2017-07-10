// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_element;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/builder/builder.dart' show Builder;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_internalProblem;

abstract class MockElement extends Builder implements Element, LocalElement {
  @override
  final ElementKind kind;

  MockElement(this.kind) : super(null, -1, null);

  @override
  get librarySource => deprecated_internalProblem("not supported.");

  @override
  get source => deprecated_internalProblem("not supported.");

  @override
  get context => deprecated_internalProblem("not supported.");

  @override
  String get displayName => deprecated_internalProblem("not supported.");

  @override
  String get documentationComment =>
      deprecated_internalProblem("not supported.");

  @override
  Element get enclosingElement => deprecated_internalProblem("not supported.");

  @override
  int get id => deprecated_internalProblem("not supported.");

  @override
  bool get isDeprecated => deprecated_internalProblem("not supported.");

  @override
  bool get isFactory => deprecated_internalProblem("not supported.");

  @override
  bool get isJS => deprecated_internalProblem("not supported.");

  @override
  bool get isOverride => deprecated_internalProblem("not supported.");

  @override
  bool get isPrivate => deprecated_internalProblem("not supported.");

  @override
  bool get isProtected => deprecated_internalProblem("not supported.");

  @override
  bool get isPublic => deprecated_internalProblem("not supported.");

  @override
  bool get isRequired => deprecated_internalProblem("not supported.");

  @override
  bool get isSynthetic => deprecated_internalProblem("not supported.");

  @override
  LibraryElement get library => deprecated_internalProblem("not supported.");

  @override
  get location => deprecated_internalProblem("not supported.");

  @override
  get metadata => deprecated_internalProblem("not supported.");

  @override
  String get name => deprecated_internalProblem("not supported.");

  @override
  String get fullNameForErrors => name;

  @override
  int get nameLength => deprecated_internalProblem("not supported.");

  @override
  int get nameOffset => -1;

  @override
  get unit => deprecated_internalProblem("not supported.");

  @override
  accept<T>(visitor) => deprecated_internalProblem("not supported.");

  @override
  String computeDocumentationComment() =>
      deprecated_internalProblem("not supported.");

  @override
  computeNode() => deprecated_internalProblem("not supported.");

  @override
  getAncestor<E>(predicate) => deprecated_internalProblem("not supported.");

  @override
  String getExtendedDisplayName(String shortName) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  void visitChildren(visitor) => deprecated_internalProblem("not supported.");

  String get uri => deprecated_internalProblem("not supported.");

  int get uriEnd => deprecated_internalProblem("not supported.");

  int get uriOffset => deprecated_internalProblem("not supported.");

  List<ParameterElement> get parameters =>
      deprecated_internalProblem("not supported.");

  List<FunctionElement> get functions =>
      deprecated_internalProblem("not supported.");

  bool get hasImplicitReturnType =>
      deprecated_internalProblem("not supported.");

  bool get isAbstract => deprecated_internalProblem("not supported.");

  bool get isAsynchronous => deprecated_internalProblem("not supported.");

  bool get isExternal => deprecated_internalProblem("not supported.");

  bool get isGenerator => deprecated_internalProblem("not supported.");

  bool get isOperator => deprecated_internalProblem("not supported.");

  @override
  bool get isStatic => deprecated_internalProblem("not supported.");

  bool get isSynchronous => deprecated_internalProblem("not supported.");

  @override
  get visibleRange => deprecated_internalProblem("not supported.");

  bool get hasImplicitType => deprecated_internalProblem("not supported.");

  FunctionElement get initializer =>
      deprecated_internalProblem("not supported.");

  @override
  bool get isConst => deprecated_internalProblem("not supported.");

  @override
  bool get isFinal => deprecated_internalProblem("not supported.");

  bool get isPotentiallyMutatedInClosure =>
      deprecated_internalProblem("not supported.");

  bool get isPotentiallyMutatedInScope =>
      deprecated_internalProblem("not supported.");
}

abstract class MockLibraryElement extends MockElement
    implements LibraryElement {
  MockLibraryElement() : super(ElementKind.LIBRARY);

  @override
  CompilationUnitElement get definingCompilationUnit {
    return deprecated_internalProblem("not supported.");
  }

  @override
  FunctionElement get entryPoint =>
      deprecated_internalProblem("not supported.");

  @override
  List<LibraryElement> get exportedLibraries {
    return deprecated_internalProblem("not supported.");
  }

  @override
  get exportNamespace => deprecated_internalProblem("not supported.");

  @override
  get exports => deprecated_internalProblem("not supported.");

  @override
  bool get hasExtUri => deprecated_internalProblem("not supported.");

  @override
  bool get hasLoadLibraryFunction =>
      deprecated_internalProblem("not supported.");

  @override
  String get identifier => deprecated_internalProblem("not supported.");

  @override
  List<LibraryElement> get importedLibraries {
    return deprecated_internalProblem("not supported.");
  }

  @override
  get imports => deprecated_internalProblem("not supported.");

  @override
  bool get isBrowserApplication => deprecated_internalProblem("not supported.");

  @override
  bool get isDartAsync => deprecated_internalProblem("not supported.");

  @override
  bool get isDartCore => deprecated_internalProblem("not supported.");

  @override
  bool get isInSdk => deprecated_internalProblem("not supported.");

  @override
  List<LibraryElement> get libraryCycle =>
      deprecated_internalProblem("not supported.");

  @override
  FunctionElement get loadLibraryFunction =>
      deprecated_internalProblem("not supported.");

  @override
  List<CompilationUnitElement> get parts =>
      deprecated_internalProblem("not supported.");

  @override
  List<PrefixElement> get prefixes =>
      deprecated_internalProblem("not supported.");

  @override
  get publicNamespace => deprecated_internalProblem("not supported.");

  @override
  List<CompilationUnitElement> get units =>
      deprecated_internalProblem("not supported.");

  @override
  getImportsWithPrefix(PrefixElement prefix) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  ClassElement getType(String className) =>
      deprecated_internalProblem("not supported.");
}

abstract class MockCompilationUnitElement extends MockElement
    implements CompilationUnitElement {
  MockCompilationUnitElement() : super(ElementKind.COMPILATION_UNIT);

  @override
  List<PropertyAccessorElement> get accessors {
    return deprecated_internalProblem("not supported.");
  }

  @override
  LibraryElement get enclosingElement =>
      deprecated_internalProblem("not supported.");

  @override
  List<ClassElement> get enums => deprecated_internalProblem("not supported.");

  @override
  List<FunctionElement> get functions =>
      deprecated_internalProblem("not supported.");

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases {
    return deprecated_internalProblem("not supported.");
  }

  @override
  bool get hasLoadLibraryFunction =>
      deprecated_internalProblem("not supported.");

  @override
  LineInfo get lineInfo => deprecated_internalProblem("not supported.");

  @override
  List<TopLevelVariableElement> get topLevelVariables {
    return deprecated_internalProblem("not supported.");
  }

  @override
  List<ClassElement> get types => deprecated_internalProblem("not supported.");

  @override
  ClassElement getEnum(String name) =>
      deprecated_internalProblem("not supported.");

  @override
  ClassElement getType(String name) =>
      deprecated_internalProblem("not supported.");

  @override
  CompilationUnit computeNode() => deprecated_internalProblem("not supported.");
}

abstract class MockClassElement extends MockElement implements ClassElement {
  MockClassElement() : super(ElementKind.CLASS);

  List<PropertyAccessorElement> get accessors {
    return deprecated_internalProblem("not supported.");
  }

  @override
  get allSupertypes => deprecated_internalProblem("not supported.");

  @override
  List<ConstructorElement> get constructors =>
      deprecated_internalProblem("not supported.");

  @override
  List<FieldElement> get fields => deprecated_internalProblem("not supported.");

  @override
  bool get hasNonFinalField => deprecated_internalProblem("not supported.");

  @override
  bool get hasReferenceToSuper => deprecated_internalProblem("not supported.");

  @override
  bool get hasStaticMember => deprecated_internalProblem("not supported.");

  @override
  get interfaces => deprecated_internalProblem("not supported.");

  @override
  bool get isAbstract => deprecated_internalProblem("not supported.");

  @override
  bool get isEnum => deprecated_internalProblem("not supported.");

  @override
  bool get isMixinApplication => deprecated_internalProblem("not supported.");

  @override
  bool get isOrInheritsProxy => deprecated_internalProblem("not supported.");

  @override
  bool get isProxy => deprecated_internalProblem("not supported.");

  @override
  bool get isValidMixin => deprecated_internalProblem("not supported.");

  @override
  get typeParameters => deprecated_internalProblem("not supported.");

  @override
  List<MethodElement> get methods =>
      deprecated_internalProblem("not supported.");

  @override
  get mixins => deprecated_internalProblem("not supported.");

  @override
  get supertype => deprecated_internalProblem("not supported.");

  @override
  ConstructorElement get unnamedConstructor =>
      deprecated_internalProblem("not supported.");

  @override
  FieldElement getField(String name) =>
      deprecated_internalProblem("not supported.");

  @override
  PropertyAccessorElement getGetter(String name) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  MethodElement getMethod(String name) =>
      deprecated_internalProblem("not supported.");

  @override
  ConstructorElement getNamedConstructor(String name) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  PropertyAccessorElement getSetter(String name) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  bool isSuperConstructorAccessible(ConstructorElement constructor) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  MethodElement lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  MethodElement lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  MethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  NamedCompilationUnitMember computeNode() =>
      deprecated_internalProblem("not supported.");

  @override
  InterfaceType get type => deprecated_internalProblem("not supported.");
}

abstract class MockFunctionElement extends MockElement
    implements FunctionElement {
  MockFunctionElement() : super(ElementKind.FUNCTION);

  @override
  bool get isEntryPoint => deprecated_internalProblem("not supported.");

  @override
  get typeParameters => deprecated_internalProblem("not supported.");

  @override
  FunctionType get type => deprecated_internalProblem("not supported.");

  @override
  DartType get returnType => deprecated_internalProblem("not supported.");

  @override
  FunctionDeclaration computeNode() =>
      deprecated_internalProblem("not supported.");
}

abstract class MockFunctionTypeAliasElement extends MockElement
    implements FunctionTypeAliasElement {
  MockFunctionTypeAliasElement() : super(ElementKind.FUNCTION_TYPE_ALIAS);

  @override
  CompilationUnitElement get enclosingElement {
    return deprecated_internalProblem("not supported.");
  }

  @override
  TypeAlias computeNode() => deprecated_internalProblem("not supported.");
}

abstract class MockParameterElement extends MockElement
    implements ParameterElement {
  MockParameterElement() : super(ElementKind.PARAMETER);

  @override
  String get defaultValueCode => deprecated_internalProblem("not supported.");

  @override
  bool get isCovariant => deprecated_internalProblem("not supported.");

  @override
  bool get isInitializingFormal => deprecated_internalProblem("not supported.");

  @override
  get parameterKind => deprecated_internalProblem("not supported.");

  @override
  List<ParameterElement> get parameters =>
      deprecated_internalProblem("not supported.");

  @override
  get type => null;

  @override
  get typeParameters => deprecated_internalProblem("not supported.");

  @override
  get constantValue => deprecated_internalProblem("not supported.");

  @override
  computeConstantValue() => deprecated_internalProblem("not supported.");

  @override
  void appendToWithoutDelimiters(StringBuffer buffer) {
    return deprecated_internalProblem("not supported.");
  }

  @override
  FormalParameter computeNode() => deprecated_internalProblem("not supported.");
}
