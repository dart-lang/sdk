// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_element;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/builder/builder.dart' show Builder;
import 'package:front_end/src/fasta/errors.dart' show internalError;

abstract class MockElement extends Builder implements Element, LocalElement {
  @override
  final ElementKind kind;

  MockElement(this.kind) : super(null, -1, null);

  @override
  get librarySource => internalError("not supported.");

  @override
  get source => internalError("not supported.");

  @override
  get context => internalError("not supported.");

  @override
  String get displayName => internalError("not supported.");

  @override
  String get documentationComment => internalError("not supported.");

  @override
  Element get enclosingElement => internalError("not supported.");

  @override
  int get id => internalError("not supported.");

  @override
  bool get isDeprecated => internalError("not supported.");

  @override
  bool get isFactory => internalError("not supported.");

  @override
  bool get isJS => internalError("not supported.");

  @override
  bool get isOverride => internalError("not supported.");

  @override
  bool get isPrivate => internalError("not supported.");

  @override
  bool get isProtected => internalError("not supported.");

  @override
  bool get isPublic => internalError("not supported.");

  @override
  bool get isRequired => internalError("not supported.");

  @override
  bool get isSynthetic => internalError("not supported.");

  @override
  LibraryElement get library => internalError("not supported.");

  @override
  get location => internalError("not supported.");

  @override
  get metadata => internalError("not supported.");

  @override
  String get name => internalError("not supported.");

  @override
  String get fullNameForErrors => name;

  @override
  int get nameLength => internalError("not supported.");

  @override
  int get nameOffset => -1;

  @override
  get unit => internalError("not supported.");

  @override
  accept<T>(visitor) => internalError("not supported.");

  @override
  String computeDocumentationComment() => internalError("not supported.");

  @override
  computeNode() => internalError("not supported.");

  @override
  getAncestor<E>(predicate) => internalError("not supported.");

  @override
  String getExtendedDisplayName(String shortName) {
    return internalError("not supported.");
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  void visitChildren(visitor) => internalError("not supported.");

  String get uri => internalError("not supported.");

  int get uriEnd => internalError("not supported.");

  int get uriOffset => internalError("not supported.");

  List<ParameterElement> get parameters => internalError("not supported.");

  List<FunctionElement> get functions => internalError("not supported.");

  bool get hasImplicitReturnType => internalError("not supported.");

  bool get isAbstract => internalError("not supported.");

  bool get isAsynchronous => internalError("not supported.");

  bool get isExternal => internalError("not supported.");

  bool get isGenerator => internalError("not supported.");

  bool get isOperator => internalError("not supported.");

  @override
  bool get isStatic => internalError("not supported.");

  bool get isSynchronous => internalError("not supported.");

  @override
  get visibleRange => internalError("not supported.");

  bool get hasImplicitType => internalError("not supported.");

  FunctionElement get initializer => internalError("not supported.");

  @override
  bool get isConst => internalError("not supported.");

  @override
  bool get isFinal => internalError("not supported.");

  bool get isPotentiallyMutatedInClosure => internalError("not supported.");

  bool get isPotentiallyMutatedInScope => internalError("not supported.");
}

abstract class MockLibraryElement extends MockElement
    implements LibraryElement {
  MockLibraryElement() : super(ElementKind.LIBRARY);

  @override
  CompilationUnitElement get definingCompilationUnit {
    return internalError("not supported.");
  }

  @override
  FunctionElement get entryPoint => internalError("not supported.");

  @override
  List<LibraryElement> get exportedLibraries {
    return internalError("not supported.");
  }

  @override
  get exportNamespace => internalError("not supported.");

  @override
  get exports => internalError("not supported.");

  @override
  bool get hasExtUri => internalError("not supported.");

  @override
  bool get hasLoadLibraryFunction => internalError("not supported.");

  @override
  String get identifier => internalError("not supported.");

  @override
  List<LibraryElement> get importedLibraries {
    return internalError("not supported.");
  }

  @override
  get imports => internalError("not supported.");

  @override
  bool get isBrowserApplication => internalError("not supported.");

  @override
  bool get isDartAsync => internalError("not supported.");

  @override
  bool get isDartCore => internalError("not supported.");

  @override
  bool get isInSdk => internalError("not supported.");

  @override
  List<LibraryElement> get libraryCycle => internalError("not supported.");

  @override
  FunctionElement get loadLibraryFunction => internalError("not supported.");

  @override
  List<CompilationUnitElement> get parts => internalError("not supported.");

  @override
  List<PrefixElement> get prefixes => internalError("not supported.");

  @override
  get publicNamespace => internalError("not supported.");

  @override
  List<CompilationUnitElement> get units => internalError("not supported.");

  @override
  getImportsWithPrefix(PrefixElement prefix) {
    return internalError("not supported.");
  }

  @override
  ClassElement getType(String className) => internalError("not supported.");
}

abstract class MockCompilationUnitElement extends MockElement
    implements CompilationUnitElement {
  MockCompilationUnitElement() : super(ElementKind.COMPILATION_UNIT);

  @override
  List<PropertyAccessorElement> get accessors {
    return internalError("not supported.");
  }

  @override
  LibraryElement get enclosingElement => internalError("not supported.");

  @override
  List<ClassElement> get enums => internalError("not supported.");

  @override
  List<FunctionElement> get functions => internalError("not supported.");

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases {
    return internalError("not supported.");
  }

  @override
  bool get hasLoadLibraryFunction => internalError("not supported.");

  @override
  LineInfo get lineInfo => internalError("not supported.");

  @override
  List<TopLevelVariableElement> get topLevelVariables {
    return internalError("not supported.");
  }

  @override
  List<ClassElement> get types => internalError("not supported.");

  @override
  ClassElement getEnum(String name) => internalError("not supported.");

  @override
  ClassElement getType(String name) => internalError("not supported.");

  @override
  CompilationUnit computeNode() => internalError("not supported.");
}

abstract class MockClassElement extends MockElement implements ClassElement {
  MockClassElement() : super(ElementKind.CLASS);

  List<PropertyAccessorElement> get accessors {
    return internalError("not supported.");
  }

  @override
  get allSupertypes => internalError("not supported.");

  @override
  List<ConstructorElement> get constructors => internalError("not supported.");

  @override
  List<FieldElement> get fields => internalError("not supported.");

  @override
  bool get hasNonFinalField => internalError("not supported.");

  @override
  bool get hasReferenceToSuper => internalError("not supported.");

  @override
  bool get hasStaticMember => internalError("not supported.");

  @override
  get interfaces => internalError("not supported.");

  @override
  bool get isAbstract => internalError("not supported.");

  @override
  bool get isEnum => internalError("not supported.");

  @override
  bool get isMixinApplication => internalError("not supported.");

  @override
  bool get isOrInheritsProxy => internalError("not supported.");

  @override
  bool get isProxy => internalError("not supported.");

  @override
  bool get isValidMixin => internalError("not supported.");

  @override
  get typeParameters => internalError("not supported.");

  @override
  List<MethodElement> get methods => internalError("not supported.");

  @override
  get mixins => internalError("not supported.");

  @override
  get supertype => internalError("not supported.");

  @override
  ConstructorElement get unnamedConstructor => internalError("not supported.");

  @override
  FieldElement getField(String name) => internalError("not supported.");

  @override
  PropertyAccessorElement getGetter(String name) {
    return internalError("not supported.");
  }

  @override
  MethodElement getMethod(String name) => internalError("not supported.");

  @override
  ConstructorElement getNamedConstructor(String name) {
    return internalError("not supported.");
  }

  @override
  PropertyAccessorElement getSetter(String name) {
    return internalError("not supported.");
  }

  @override
  bool isSuperConstructorAccessible(ConstructorElement constructor) {
    return internalError("not supported.");
  }

  @override
  MethodElement lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  MethodElement lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  MethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library) {
    return internalError("not supported.");
  }

  @override
  NamedCompilationUnitMember computeNode() => internalError("not supported.");

  @override
  InterfaceType get type => internalError("not supported.");
}

abstract class MockFunctionElement extends MockElement
    implements FunctionElement {
  MockFunctionElement() : super(ElementKind.FUNCTION);

  @override
  bool get isEntryPoint => internalError("not supported.");

  @override
  get typeParameters => internalError("not supported.");

  @override
  FunctionType get type => internalError("not supported.");

  @override
  DartType get returnType => internalError("not supported.");

  @override
  FunctionDeclaration computeNode() => internalError("not supported.");
}

abstract class MockFunctionTypeAliasElement extends MockElement
    implements FunctionTypeAliasElement {
  MockFunctionTypeAliasElement() : super(ElementKind.FUNCTION_TYPE_ALIAS);

  @override
  CompilationUnitElement get enclosingElement {
    return internalError("not supported.");
  }

  @override
  TypeAlias computeNode() => internalError("not supported.");
}

abstract class MockParameterElement extends MockElement
    implements ParameterElement {
  MockParameterElement() : super(ElementKind.PARAMETER);

  @override
  String get defaultValueCode => internalError("not supported.");

  @override
  bool get isCovariant => internalError("not supported.");

  @override
  bool get isInitializingFormal => internalError("not supported.");

  @override
  get parameterKind => internalError("not supported.");

  @override
  List<ParameterElement> get parameters => internalError("not supported.");

  @override
  get type => null;

  @override
  get typeParameters => internalError("not supported.");

  @override
  get constantValue => internalError("not supported.");

  @override
  computeConstantValue() => internalError("not supported.");

  @override
  void appendToWithoutDelimiters(StringBuffer buffer) {
    return internalError("not supported.");
  }

  @override
  FormalParameter computeNode() => internalError("not supported.");
}
