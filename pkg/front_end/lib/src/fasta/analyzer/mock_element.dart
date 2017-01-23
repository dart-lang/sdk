// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_element;

import 'package:analyzer/dart/element/element.dart';

import '../errors.dart' show
    internalError;

abstract class MockElement implements Element {
  final ElementKind kind;

  MockElement(this.kind);

  get librarySource => internalError("not supported.");

  get source => internalError("not supported.");

  get context => internalError("not supported.");

  String get displayName => internalError("not supported.");

  String get documentationComment => internalError("not supported.");

  Element get enclosingElement => internalError("not supported.");

  int get id => internalError("not supported.");

  bool get isDeprecated => internalError("not supported.");

  bool get isFactory => internalError("not supported.");

  bool get isJS => internalError("not supported.");

  bool get isOverride => internalError("not supported.");

  bool get isPrivate => internalError("not supported.");

  bool get isProtected => internalError("not supported.");

  bool get isPublic => internalError("not supported.");

  bool get isRequired => internalError("not supported.");

  bool get isSynthetic => internalError("not supported.");

  LibraryElement get library => internalError("not supported.");

  get location => internalError("not supported.");

  get metadata => internalError("not supported.");

  String get name => internalError("not supported.");

  int get nameLength => internalError("not supported.");

  int get nameOffset => -1;

  get unit => internalError("not supported.");

  accept(visitor) => internalError("not supported.");

  String computeDocumentationComment() => internalError("not supported.");

  computeNode() => internalError("not supported.");

  Element getAncestor(predicate) => internalError("not supported.");

  String getExtendedDisplayName(String shortName) {
    return internalError("not supported.");
  }

  bool isAccessibleIn(LibraryElement library) {
    return internalError("not supported.");
  }

  void visitChildren(visitor) => internalError("not supported.");

  String get uri => internalError("not supported.");

  int get uriEnd => internalError("not supported.");

  int get uriOffset => internalError("not supported.");

  get type => null;

  get typeParameters => internalError("not supported.");

  List<ParameterElement> get parameters => internalError("not supported.");

  get returnType => internalError("not supported.");

  List<FunctionElement> get functions => internalError("not supported.");

  bool get hasImplicitReturnType => internalError("not supported.");

  bool get isAbstract => internalError("not supported.");

  bool get isAsynchronous => internalError("not supported.");

  bool get isExternal => internalError("not supported.");

  bool get isGenerator => internalError("not supported.");

  bool get isOperator => internalError("not supported.");

  bool get isStatic => internalError("not supported.");

  bool get isSynchronous => internalError("not supported.");

  List<LabelElement> get labels => internalError("not supported.");

  List<LocalVariableElement> get localVariables {
    return internalError("not supported.");
  }

  get visibleRange => internalError("not supported.");

  get constantValue => internalError("not supported.");

  bool get hasImplicitType => internalError("not supported.");

  FunctionElement get initializer => internalError("not supported.");

  bool get isConst => internalError("not supported.");

  bool get isFinal => internalError("not supported.");

  bool get isPotentiallyMutatedInClosure => internalError("not supported.");

  bool get isPotentiallyMutatedInScope => internalError("not supported.");

  computeConstantValue() => internalError("not supported.");
}

abstract class MockLibraryElement extends MockElement
    implements LibraryElement {
  MockLibraryElement()
      : super(ElementKind.LIBRARY);

  CompilationUnitElement get definingCompilationUnit {
    return internalError("not supported.");
  }

  FunctionElement get entryPoint => internalError("not supported.");

  List<LibraryElement> get exportedLibraries {
    return internalError("not supported.");
  }

  get exportNamespace => internalError("not supported.");

  get exports => internalError("not supported.");

  bool get hasExtUri => internalError("not supported.");

  bool get hasLoadLibraryFunction => internalError("not supported.");

  String get identifier => internalError("not supported.");

  List<LibraryElement> get importedLibraries {
    return internalError("not supported.");
  }

  get imports => internalError("not supported.");

  bool get isBrowserApplication => internalError("not supported.");

  bool get isDartAsync => internalError("not supported.");

  bool get isDartCore => internalError("not supported.");

  bool get isInSdk => internalError("not supported.");

  List<LibraryElement> get libraryCycle => internalError("not supported.");

  FunctionElement get loadLibraryFunction => internalError("not supported.");

  List<CompilationUnitElement> get parts => internalError("not supported.");

  List<PrefixElement> get prefixes => internalError("not supported.");

  get publicNamespace => internalError("not supported.");

  List<CompilationUnitElement> get units => internalError("not supported.");

  getImportsWithPrefix(PrefixElement prefix) {
    return internalError("not supported.");
  }

  ClassElement getType(String className) => internalError("not supported.");
}

abstract class MockCompilationUnitElement extends MockElement
    implements CompilationUnitElement {
  MockCompilationUnitElement()
      : super(ElementKind.COMPILATION_UNIT);

  List<PropertyAccessorElement> get accessors {
    return internalError("not supported.");
  }

  List<ClassElement> get enums => internalError("not supported.");

  List<FunctionElement> get functions => internalError("not supported.");

  List<FunctionTypeAliasElement> get functionTypeAliases {
    return internalError("not supported.");
  }

  bool get hasLoadLibraryFunction => internalError("not supported.");

  List<TopLevelVariableElement> get topLevelVariables {
    return internalError("not supported.");
  }

  List<ClassElement> get types => internalError("not supported.");

  Element getElementAt(int offset) => internalError("not supported.");

  ClassElement getEnum(String name) => internalError("not supported.");

  ClassElement getType(String name) => internalError("not supported.");
}

abstract class MockClassElement extends MockElement implements ClassElement {
  MockClassElement()
      : super(ElementKind.CLASS);

  List<PropertyAccessorElement> get accessors {
    return internalError("not supported.");
  }

  get allSupertypes => internalError("not supported.");

  List<ConstructorElement> get constructors => internalError("not supported.");

  List<FieldElement> get fields => internalError("not supported.");

  bool get hasNonFinalField => internalError("not supported.");

  bool get hasReferenceToSuper => internalError("not supported.");

  bool get hasStaticMember => internalError("not supported.");

  get interfaces => internalError("not supported.");

  bool get isAbstract => internalError("not supported.");

  bool get isEnum => internalError("not supported.");

  bool get isMixinApplication => internalError("not supported.");

  bool get isOrInheritsProxy => internalError("not supported.");

  bool get isProxy => internalError("not supported.");

  bool get isValidMixin => internalError("not supported.");

  List<MethodElement> get methods => internalError("not supported.");

  get mixins => internalError("not supported.");

  get supertype => internalError("not supported.");

  ConstructorElement get unnamedConstructor => internalError("not supported.");

  FieldElement getField(String name) => internalError("not supported.");

  PropertyAccessorElement getGetter(String name) {
    return internalError("not supported.");
  }

  MethodElement getMethod(String name) => internalError("not supported.");

  ConstructorElement getNamedConstructor(String name) {
    return internalError("not supported.");
  }

  PropertyAccessorElement getSetter(String name) {
    return internalError("not supported.");
  }

  bool isSuperConstructorAccessible(ConstructorElement constructor) {
    return internalError("not supported.");
  }

  MethodElement lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library) {
    return internalError("not supported.");
  }

  PropertyAccessorElement lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library) {
    return internalError("not supported.");
  }

  MethodElement lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  PropertyAccessorElement lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return internalError("not supported.");
  }

  MethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library) {
    return internalError("not supported.");
  }
}

abstract class MockFunctionElement extends MockElement
    implements FunctionElement {
  MockFunctionElement()
      : super(ElementKind.FUNCTION);

  bool get isEntryPoint => internalError("not supported.");
}

abstract class MockParameterElement extends MockElement
    implements ParameterElement {
  MockParameterElement()
      : super(ElementKind.PARAMETER);

  String get defaultValueCode => internalError("not supported.");

  bool get isCovariant => internalError("not supported.");

  bool get isInitializingFormal => internalError("not supported.");

  get parameterKind => internalError("not supported.");

  List<ParameterElement> get parameters => internalError("not supported.");

  List<TypeParameterElement> get typeParameters {
    return internalError("not supported.");
  }

  void appendToWithoutDelimiters(StringBuffer buffer) {
    return internalError("not supported.");
  }
}
