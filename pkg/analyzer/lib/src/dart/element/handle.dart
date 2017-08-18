// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.element_handle;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * A handle to a [ClassElement].
 */
class ClassElementHandle extends ElementHandle implements ClassElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ClassElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  List<PropertyAccessorElement> get accessors => actualElement.accessors;

  @override
  ClassElement get actualElement => super.actualElement as ClassElement;

  @override
  List<InterfaceType> get allSupertypes => actualElement.allSupertypes;

  @override
  List<ConstructorElement> get constructors => actualElement.constructors;

  @override
  List<FieldElement> get fields => actualElement.fields;

  @override
  bool get hasNonFinalField => actualElement.hasNonFinalField;

  @override
  bool get hasReferenceToSuper => actualElement.hasReferenceToSuper;

  @override
  bool get hasStaticMember => actualElement.hasStaticMember;

  @override
  List<InterfaceType> get interfaces => actualElement.interfaces;

  @override
  bool get isAbstract => actualElement.isAbstract;

  @override
  bool get isEnum => actualElement.isEnum;

  @override
  bool get isJS => actualElement.isJS;

  @override
  bool get isMixinApplication => actualElement.isMixinApplication;

  @override
  bool get isOrInheritsProxy => actualElement.isOrInheritsProxy;

  @override
  bool get isProxy => actualElement.isProxy;

  @override
  bool get isRequired => actualElement.isRequired;

  @override
  bool get isValidMixin => actualElement.isValidMixin;

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  List<MethodElement> get methods => actualElement.methods;

  @override
  List<InterfaceType> get mixins => actualElement.mixins;

  @override
  InterfaceType get supertype => actualElement.supertype;

  @override
  InterfaceType get type => actualElement.type;

  @override
  List<TypeParameterElement> get typeParameters => actualElement.typeParameters;

  @override
  ConstructorElement get unnamedConstructor => actualElement.unnamedConstructor;

  @override
  NamedCompilationUnitMember computeNode() => super.computeNode();

  @override
  FieldElement getField(String fieldName) => actualElement.getField(fieldName);

  @override
  PropertyAccessorElement getGetter(String getterName) =>
      actualElement.getGetter(getterName);

  @override
  MethodElement getMethod(String methodName) =>
      actualElement.getMethod(methodName);

  @override
  ConstructorElement getNamedConstructor(String name) =>
      actualElement.getNamedConstructor(name);

  @override
  PropertyAccessorElement getSetter(String setterName) =>
      actualElement.getSetter(setterName);

  @override
  bool isSuperConstructorAccessible(ConstructorElement constructor) =>
      actualElement.isSuperConstructorAccessible(constructor);

  @override
  MethodElement lookUpConcreteMethod(
          String methodName, LibraryElement library) =>
      actualElement.lookUpConcreteMethod(methodName, library);

  @override
  PropertyAccessorElement lookUpGetter(
          String getterName, LibraryElement library) =>
      actualElement.lookUpGetter(getterName, library);

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(
          String methodName, LibraryElement library) =>
      actualElement.lookUpInheritedConcreteGetter(methodName, library);

  @override
  MethodElement lookUpInheritedConcreteMethod(
          String methodName, LibraryElement library) =>
      actualElement.lookUpInheritedConcreteMethod(methodName, library);

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(
          String methodName, LibraryElement library) =>
      actualElement.lookUpInheritedConcreteSetter(methodName, library);

  @override
  MethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return actualElement.lookUpInheritedMethod(methodName, library);
  }

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) =>
      actualElement.lookUpMethod(methodName, library);

  @override
  PropertyAccessorElement lookUpSetter(
          String setterName, LibraryElement library) =>
      actualElement.lookUpSetter(setterName, library);
}

/**
 * A handle to a [CompilationUnitElement].
 */
class CompilationUnitElementHandle extends ElementHandle
    implements CompilationUnitElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  CompilationUnitElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  List<PropertyAccessorElement> get accessors => actualElement.accessors;

  @override
  CompilationUnitElement get actualElement =>
      super.actualElement as CompilationUnitElement;

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  List<ClassElement> get enums => actualElement.enums;

  @override
  List<FunctionElement> get functions => actualElement.functions;

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases =>
      actualElement.functionTypeAliases;

  @override
  bool get hasLoadLibraryFunction => actualElement.hasLoadLibraryFunction;

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  LineInfo get lineInfo => actualElement.lineInfo;

  @override
  Source get source => actualElement.source;

  @override
  List<TopLevelVariableElement> get topLevelVariables =>
      actualElement.topLevelVariables;

  @override
  List<ClassElement> get types => actualElement.types;

  @override
  String get uri => actualElement.uri;

  @override
  int get uriEnd => actualElement.uriEnd;

  @override
  int get uriOffset => actualElement.uriOffset;

  @override
  CompilationUnit computeNode() => actualElement.computeNode();

  @override
  ClassElement getEnum(String enumName) => actualElement.getEnum(enumName);

  @override
  ClassElement getType(String className) => actualElement.getType(className);
}

/**
 * A handle to a [ConstructorElement].
 */
class ConstructorElementHandle extends ExecutableElementHandle
    implements ConstructorElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ConstructorElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ConstructorElement get actualElement =>
      super.actualElement as ConstructorElement;

  @override
  ClassElement get enclosingElement => actualElement.enclosingElement;

  @override
  bool get isConst => actualElement.isConst;

  @override
  bool get isDefaultConstructor => actualElement.isDefaultConstructor;

  @override
  bool get isFactory => actualElement.isFactory;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  int get nameEnd => actualElement.nameEnd;

  @override
  int get periodOffset => actualElement.periodOffset;

  @override
  ConstructorElement get redirectedConstructor =>
      actualElement.redirectedConstructor;

  @override
  ConstructorDeclaration computeNode() => actualElement.computeNode();
}

/**
 * A handle to an [Element].
 */
abstract class ElementHandle implements Element {
  /**
   * The unique integer identifier of this element.
   */
  final int id = 0;

  /**
   * The [ElementResynthesizer] which will be used to resynthesize elements on
   * demand.
   */
  final ElementResynthesizer _resynthesizer;

  /**
   * The location of this element, used to reconstitute the element if it has
   * not yet been resynthesized.
   */
  final ElementLocation _location;

  /**
   * A reference to the element being referenced by this handle, or `null` if
   * the element has not yet been resynthesized.
   */
  Element _elementReference;

  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ElementHandle(this._resynthesizer, this._location);

  /**
   * Return the element being represented by this handle, reconstituting the
   * element if the reference has been set to `null`.
   */
  Element get actualElement {
    if (_elementReference == null) {
      _elementReference = _resynthesizer.getElement(_location);
    }
    return _elementReference;
  }

  @override
  AnalysisContext get context => _resynthesizer.context;

  @override
  String get displayName => actualElement.displayName;

  @override
  String get documentationComment => actualElement.documentationComment;

  @override
  Element get enclosingElement => actualElement.enclosingElement;

  @override
  int get hashCode => _location.hashCode;

  @override
  bool get isDeprecated => actualElement.isDeprecated;

  @override
  bool get isFactory => actualElement.isFactory;

  @override
  bool get isJS => actualElement.isJS;

  @override
  bool get isOverride => actualElement.isOverride;

  @override
  bool get isPrivate => actualElement.isPrivate;

  @override
  bool get isProtected => actualElement.isProtected;

  @override
  bool get isPublic => actualElement.isPublic;

  @override
  bool get isRequired => actualElement.isRequired;

  @override
  bool get isSynthetic => actualElement.isSynthetic;

  @override
  LibraryElement get library =>
      getAncestor((element) => element is LibraryElement);

  @override
  Source get librarySource => actualElement.librarySource;

  @override
  ElementLocation get location => _location;

  @override
  List<ElementAnnotation> get metadata => actualElement.metadata;

  @override
  String get name => actualElement.name;

  @override
  int get nameLength => actualElement.nameLength;

  @override
  int get nameOffset => actualElement.nameOffset;

  @override
  Source get source => actualElement.source;

  @override
  CompilationUnit get unit => actualElement.unit;

  @override
  bool operator ==(Object object) =>
      object is Element && object.location == _location;

  @override
  T accept<T>(ElementVisitor<T> visitor) => actualElement.accept(visitor);

  @override
  String computeDocumentationComment() => documentationComment;

  @override
  AstNode computeNode() => actualElement.computeNode();

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) =>
      actualElement.getAncestor(predicate);

  @override
  String getExtendedDisplayName(String shortName) =>
      actualElement.getExtendedDisplayName(shortName);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      actualElement.isAccessibleIn(library);

  @override
  String toString() => actualElement.toString();

  @override
  void visitChildren(ElementVisitor visitor) {
    actualElement.visitChildren(visitor);
  }
}

/**
 * Interface which allows an [Element] handle to be resynthesized based on an
 * [ElementLocation].  The concrete classes implementing element handles use
 * this interface to retrieve the underlying elements when queried.
 */
abstract class ElementResynthesizer {
  /**
   * The context that owns the element to be resynthesized.
   */
  final AnalysisContext context;

  /**
   * Initialize a newly created resynthesizer to resynthesize elements in the
   * given [context].
   */
  ElementResynthesizer(this.context);

  /**
   * Return the element referenced by the given [location].
   */
  Element getElement(ElementLocation location);
}

/**
 * A handle to an [ExecutableElement].
 */
abstract class ExecutableElementHandle extends ElementHandle
    implements ExecutableElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ExecutableElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ExecutableElement get actualElement =>
      super.actualElement as ExecutableElement;

  @override
  List<FunctionElement> get functions => actualElement.functions;

  @override
  bool get hasImplicitReturnType => actualElement.hasImplicitReturnType;

  @override
  bool get isAbstract => actualElement.isAbstract;

  @override
  bool get isAsynchronous => actualElement.isAsynchronous;

  @override
  bool get isExternal => actualElement.isExternal;

  @override
  bool get isGenerator => actualElement.isGenerator;

  @override
  bool get isOperator => actualElement.isOperator;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  bool get isSynchronous => actualElement.isSynchronous;

  @override
  List<ParameterElement> get parameters => actualElement.parameters;

  @override
  DartType get returnType => actualElement.returnType;

  @override
  FunctionType get type => actualElement.type;

  @override
  List<TypeParameterElement> get typeParameters => actualElement.typeParameters;
}

/**
 * A handle to an [ExportElement].
 */
class ExportElementHandle extends ElementHandle implements ExportElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ExportElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ExportElement get actualElement => super.actualElement as ExportElement;

  @override
  List<NamespaceCombinator> get combinators => actualElement.combinators;

  @override
  LibraryElement get exportedLibrary => actualElement.exportedLibrary;

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  String get uri => actualElement.uri;

  @override
  int get uriEnd => actualElement.uriEnd;

  @override
  int get uriOffset => actualElement.uriOffset;
}

/**
 * A handle to a [FieldElement].
 */
class FieldElementHandle extends PropertyInducingElementHandle
    implements FieldElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  FieldElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  FieldElement get actualElement => super.actualElement as FieldElement;

  @override
  ClassElement get enclosingElement => actualElement.enclosingElement;

  @override
  bool get isEnumConstant => actualElement.isEnumConstant;

  @override
  bool get isVirtual => actualElement.isVirtual;

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  VariableDeclaration computeNode() => actualElement.computeNode();
}

/**
 * A handle to a [FunctionElement].
 */
class FunctionElementHandle extends ExecutableElementHandle
    implements FunctionElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  FunctionElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  FunctionElement get actualElement => super.actualElement as FunctionElement;

  @override
  bool get isEntryPoint => actualElement.isEntryPoint;

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  SourceRange get visibleRange => actualElement.visibleRange;

  @override
  FunctionDeclaration computeNode() => actualElement.computeNode();
}

/**
 * A handle to a [FunctionTypeAliasElement].
 */
class FunctionTypeAliasElementHandle extends ElementHandle
    implements FunctionTypeAliasElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  FunctionTypeAliasElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  FunctionTypeAliasElement get actualElement =>
      super.actualElement as FunctionTypeAliasElement;

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  @override
  List<ParameterElement> get parameters => actualElement.parameters;

  @override
  DartType get returnType => actualElement.returnType;

  @override
  FunctionType get type => actualElement.type;

  @override
  List<TypeParameterElement> get typeParameters => actualElement.typeParameters;

  @override
  FunctionTypeAlias computeNode() => actualElement.computeNode();
}

/**
 * A handle to a [GenericTypeAliasElement].
 */
class GenericTypeAliasElementHandle extends ElementHandle
    implements GenericTypeAliasElement {
  GenericTypeAliasElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  GenericTypeAliasElement get actualElement =>
      super.actualElement as GenericTypeAliasElement;

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  GenericFunctionTypeElement get function => actualElement.function;

  @override
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  @override
  List<ParameterElement> get parameters => actualElement.parameters;

  @override
  DartType get returnType => actualElement.returnType;

  @override
  FunctionType get type => actualElement.type;

  @override
  List<TypeParameterElement> get typeParameters => actualElement.typeParameters;

  @override
  FunctionTypeAlias computeNode() => actualElement.computeNode();
}

/**
 * A handle to an [ImportElement].
 */
class ImportElementHandle extends ElementHandle implements ImportElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ImportElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ImportElement get actualElement => super.actualElement as ImportElement;

  @override
  List<NamespaceCombinator> get combinators => actualElement.combinators;

  @override
  LibraryElement get importedLibrary => actualElement.importedLibrary;

  @override
  bool get isDeferred => actualElement.isDeferred;

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  PrefixElement get prefix => actualElement.prefix;

  @override
  int get prefixOffset => actualElement.prefixOffset;

  @override
  String get uri => actualElement.uri;

  @override
  int get uriEnd => actualElement.uriEnd;

  @override
  int get uriOffset => actualElement.uriOffset;
}

/**
 * A handle to a [LabelElement].
 */
class LabelElementHandle extends ElementHandle implements LabelElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  LabelElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

  @override
  ElementKind get kind => ElementKind.LABEL;
}

/**
 * A handle to a [LibraryElement].
 */
class LibraryElementHandle extends ElementHandle implements LibraryElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  LibraryElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  LibraryElement get actualElement => super.actualElement as LibraryElement;

  @override
  CompilationUnitElement get definingCompilationUnit =>
      actualElement.definingCompilationUnit;

  @override
  FunctionElement get entryPoint => actualElement.entryPoint;

  @override
  List<LibraryElement> get exportedLibraries => actualElement.exportedLibraries;

  @override
  Namespace get exportNamespace => actualElement.exportNamespace;

  @override
  List<ExportElement> get exports => actualElement.exports;

  @override
  bool get hasExtUri => actualElement.hasExtUri;

  @override
  bool get hasLoadLibraryFunction => actualElement.hasLoadLibraryFunction;

  @override
  String get identifier => location.components.last;

  @override
  List<LibraryElement> get importedLibraries => actualElement.importedLibraries;

  @override
  List<ImportElement> get imports => actualElement.imports;

  @override
  bool get isBrowserApplication => actualElement.isBrowserApplication;

  @override
  bool get isDartAsync => actualElement.isDartAsync;

  @override
  bool get isDartCore => actualElement.isDartCore;

  @override
  bool get isInSdk => actualElement.isInSdk;

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  List<LibraryElement> get libraryCycle => actualElement.libraryCycle;

  @override
  FunctionElement get loadLibraryFunction => actualElement.loadLibraryFunction;

  @override
  List<CompilationUnitElement> get parts => actualElement.parts;

  @override
  List<PrefixElement> get prefixes => actualElement.prefixes;

  @override
  Namespace get publicNamespace => actualElement.publicNamespace;

  @override
  List<CompilationUnitElement> get units => actualElement.units;

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) =>
      actualElement.getImportsWithPrefix(prefixElement);

  @override
  ClassElement getType(String className) => actualElement.getType(className);
}

/**
 * A handle to a [LocalVariableElement].
 */
class LocalVariableElementHandle extends VariableElementHandle
    implements LocalVariableElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  LocalVariableElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  LocalVariableElement get actualElement =>
      super.actualElement as LocalVariableElement;

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  SourceRange get visibleRange => actualElement.visibleRange;

  @override
  VariableDeclaration computeNode() => actualElement.computeNode();
}

/**
 * A handle to a [MethodElement].
 */
class MethodElementHandle extends ExecutableElementHandle
    implements MethodElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  MethodElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  MethodElement get actualElement => super.actualElement as MethodElement;

  @override
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  MethodDeclaration computeNode() => actualElement.computeNode();

  @override
  FunctionType getReifiedType(DartType objectType) =>
      actualElement.getReifiedType(objectType);
}

/**
 * A handle to a [ParameterElement].
 */
class ParameterElementHandle extends VariableElementHandle
    with ParameterElementMixin
    implements ParameterElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  ParameterElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ParameterElement get actualElement => super.actualElement as ParameterElement;

  @override
  String get defaultValueCode => actualElement.defaultValueCode;

  @override
  bool get isCovariant => actualElement.isCovariant;

  @override
  bool get isInitializingFormal => actualElement.isInitializingFormal;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  ParameterKind get parameterKind => actualElement.parameterKind;

  @override
  List<ParameterElement> get parameters => actualElement.parameters;

  @override
  List<TypeParameterElement> get typeParameters => actualElement.typeParameters;

  @override
  SourceRange get visibleRange => actualElement.visibleRange;

  @override
  FormalParameter computeNode() => super.computeNode();
}

/**
 * A handle to a [PrefixElement].
 */
class PrefixElementHandle extends ElementHandle implements PrefixElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  PrefixElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  PrefixElement get actualElement => super.actualElement as PrefixElement;

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  List<LibraryElement> get importedLibraries => LibraryElement.EMPTY_LIST;

  @override
  ElementKind get kind => ElementKind.PREFIX;
}

/**
 * A handle to a [PropertyAccessorElement].
 */
class PropertyAccessorElementHandle extends ExecutableElementHandle
    implements PropertyAccessorElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  PropertyAccessorElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  PropertyAccessorElement get actualElement =>
      super.actualElement as PropertyAccessorElement;

  @override
  PropertyAccessorElement get correspondingGetter =>
      actualElement.correspondingGetter;

  @override
  PropertyAccessorElement get correspondingSetter =>
      actualElement.correspondingSetter;

  @override
  bool get isGetter => !isSetter;

  @override
  bool get isSetter => location.components.last.endsWith('=');

  @override
  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    } else {
      return ElementKind.SETTER;
    }
  }

  @override
  PropertyInducingElement get variable => actualElement.variable;
}

/**
 * A handle to an [PropertyInducingElement].
 */
abstract class PropertyInducingElementHandle extends VariableElementHandle
    implements PropertyInducingElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  PropertyInducingElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  PropertyInducingElement get actualElement =>
      super.actualElement as PropertyInducingElement;

  @override
  PropertyAccessorElement get getter => actualElement.getter;

  @override
  DartType get propagatedType => actualElement.propagatedType;

  @override
  PropertyAccessorElement get setter => actualElement.setter;
}

/**
 * A handle to a [TopLevelVariableElement].
 */
class TopLevelVariableElementHandle extends PropertyInducingElementHandle
    implements TopLevelVariableElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  TopLevelVariableElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  VariableDeclaration computeNode() => super.computeNode();
}

/**
 * A handle to a [TypeParameterElement].
 */
class TypeParameterElementHandle extends ElementHandle
    implements TypeParameterElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  TypeParameterElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  TypeParameterElement get actualElement =>
      super.actualElement as TypeParameterElement;

  @override
  DartType get bound => actualElement.bound;

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  TypeParameterType get type => actualElement.type;
}

/**
 * A handle to an [VariableElement].
 */
abstract class VariableElementHandle extends ElementHandle
    implements VariableElement {
  /**
   * Initialize a newly created element handle to represent the element at the
   * given [_location]. The [_resynthesizer] will be used to resynthesize the
   * element when needed.
   */
  VariableElementHandle(
      ElementResynthesizer resynthesizer, ElementLocation location)
      : super(resynthesizer, location);

  @override
  VariableElement get actualElement => super.actualElement as VariableElement;

  @override
  DartObject get constantValue => actualElement.constantValue;

  @override
  bool get hasImplicitType => actualElement.hasImplicitType;

  @override
  FunctionElement get initializer => actualElement.initializer;

  @override
  bool get isConst => actualElement.isConst;

  @override
  bool get isFinal => actualElement.isFinal;

  @deprecated
  @override
  bool get isPotentiallyMutatedInClosure =>
      actualElement.isPotentiallyMutatedInClosure;

  @deprecated
  @override
  bool get isPotentiallyMutatedInScope =>
      actualElement.isPotentiallyMutatedInScope;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  DartType get type => actualElement.type;

  @override
  DartObject computeConstantValue() => actualElement.computeConstantValue();
}
