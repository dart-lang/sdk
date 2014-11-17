// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.element_handle;

import 'ast.dart';
import 'element.dart';
import 'engine.dart';
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart';
import 'utilities_dart.dart';

/**
 * Instances of the class `ClassElementHandle` implement a handle to a `ClassElement`.
 */
class ClassElementHandle extends ElementHandle implements ClassElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ClassElementHandle(ClassElement element) : super(element);

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
  bool get isOrInheritsProxy => actualElement.isOrInheritsProxy;

  @override
  bool get isProxy => actualElement.isProxy;

  @override
  bool get isTypedef => actualElement.isTypedef;

  @override
  bool get isValidMixin => actualElement.isValidMixin;

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  List<MethodElement> get methods => actualElement.methods;

  @override
  List<InterfaceType> get mixins => actualElement.mixins;

  @override
  ClassDeclaration get node => actualElement.node;

  @override
  InterfaceType get supertype => actualElement.supertype;

  @override
  List<ToolkitObjectElement> get toolkitObjects => actualElement.toolkitObjects;

  @override
  InterfaceType get type => actualElement.type;

  @override
  List<TypeParameterElement> get typeParameters => actualElement.typeParameters;

  @override
  ConstructorElement get unnamedConstructor => actualElement.unnamedConstructor;

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
  MethodElement lookUpConcreteMethod(String methodName,
      LibraryElement library) =>
      actualElement.lookUpConcreteMethod(methodName, library);

  @override
  PropertyAccessorElement lookUpGetter(String getterName,
      LibraryElement library) =>
      actualElement.lookUpGetter(getterName, library);

  @override
  PropertyAccessorElement lookUpInheritedConcreteGetter(String methodName,
      LibraryElement library) =>
      actualElement.lookUpInheritedConcreteGetter(methodName, library);

  @override
  MethodElement lookUpInheritedConcreteMethod(String methodName,
      LibraryElement library) =>
      actualElement.lookUpInheritedConcreteMethod(methodName, library);

  @override
  PropertyAccessorElement lookUpInheritedConcreteSetter(String methodName,
      LibraryElement library) =>
      actualElement.lookUpInheritedConcreteSetter(methodName, library);

  @override
  MethodElement lookUpInheritedMethod(String methodName,
      LibraryElement library) =>
      actualElement.lookUpInheritedMethod(methodName, library);

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) =>
      actualElement.lookUpMethod(methodName, library);

  @override
  PropertyAccessorElement lookUpSetter(String setterName,
      LibraryElement library) =>
      actualElement.lookUpSetter(setterName, library);
}

/**
 * Instances of the class `CompilationUnitElementHandle` implements a handle to a
 * [CompilationUnitElement].
 */
class CompilationUnitElementHandle extends ElementHandle implements
    CompilationUnitElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  CompilationUnitElementHandle(CompilationUnitElement element) : super(element);

  @override
  List<PropertyAccessorElement> get accessors => actualElement.accessors;

  @override
  CompilationUnitElement get actualElement =>
      super.actualElement as CompilationUnitElement;

  @override
  List<AngularViewElement> get angularViews => actualElement.angularViews;

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
  CompilationUnit get node => actualElement.node;

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
  ClassElement getEnum(String enumName) => actualElement.getEnum(enumName);

  @override
  ClassElement getType(String className) => actualElement.getType(className);
}

/**
 * Instances of the class `ConstructorElementHandle` implement a handle to a
 * `ConstructorElement`.
 */
class ConstructorElementHandle extends ExecutableElementHandle implements
    ConstructorElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ConstructorElementHandle(ConstructorElement element) : super(element);

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
  ConstructorDeclaration get node => actualElement.node;

  @override
  ConstructorElement get redirectedConstructor =>
      actualElement.redirectedConstructor;
}

/**
 * The abstract class `ElementHandle` implements the behavior common to objects that implement
 * a handle to an [Element].
 */
abstract class ElementHandle implements Element {
  /**
   * The context in which the element is defined.
   */
  AnalysisContext _context;

  /**
   * The location of this element, used to reconstitute the element if it has been garbage
   * collected.
   */
  ElementLocation _location;

  /**
   * A reference to the element being referenced by this handle, or `null` if the element has
   * been garbage collected.
   */
  WeakReference<Element> _elementReference;

  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ElementHandle(Element element) {
    _context = element.context;
    _location = element.location;
    _elementReference = new WeakReference<Element>(element);
  }

  /**
   * Return the element being represented by this handle, reconstituting the element if the
   * reference has been set to `null`.
   *
   * @return the element being represented by this handle
   */
  Element get actualElement {
    Element element = _elementReference.get();
    if (element == null) {
      element = _context.getElement(_location);
      _elementReference = new WeakReference<Element>(element);
    }
    return element;
  }

  @override
  AnalysisContext get context => _context;

  @override
  String get displayName => actualElement.displayName;

  @override
  Element get enclosingElement => actualElement.enclosingElement;

  @override
  int get hashCode => _location.hashCode;

  @override
  bool get isDeprecated => actualElement.isDeprecated;

  @override
  bool get isOverride => actualElement.isOverride;

  @override
  bool get isPrivate => actualElement.isPrivate;

  @override
  bool get isPublic => actualElement.isPublic;

  @override
  bool get isSynthetic => actualElement.isSynthetic;

  @override
  LibraryElement get library =>
      getAncestor((element) => element is LibraryElement);

  @override
  ElementLocation get location => _location;

  @override
  List<ElementAnnotation> get metadata => actualElement.metadata;

  @override
  String get name => actualElement.name;

  @override
  int get nameOffset => actualElement.nameOffset;

  @override
  AstNode get node => actualElement.node;

  @override
  Source get source => actualElement.source;

  @override
  CompilationUnit get unit => actualElement.unit;

  @override
  bool operator ==(Object object) =>
      object is Element && object.location == _location;

  @override
  accept(ElementVisitor visitor) => actualElement.accept(visitor);

  @override
  String computeDocumentationComment() =>
      actualElement.computeDocumentationComment();

  @override
  Element getAncestor(Predicate<Element> predicate) =>
      actualElement.getAncestor(predicate);

  @override
  String getExtendedDisplayName(String shortName) =>
      actualElement.getExtendedDisplayName(shortName);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      actualElement.isAccessibleIn(library);

  @override
  void visitChildren(ElementVisitor visitor) {
    actualElement.visitChildren(visitor);
  }

  /**
   * Return a handle on the given element. If the element is already a handle, then it will be
   * returned directly, otherwise a handle of the appropriate class will be constructed.
   *
   * @param element the element for which a handle is to be constructed
   * @return a handle on the given element
   */
  static Element forElement(Element element) {
    if (element is ElementHandle) {
      return element;
    }
    while (true) {
      if (element.kind == ElementKind.CLASS) {
        return new ClassElementHandle(element as ClassElement);
      } else if (element.kind == ElementKind.COMPILATION_UNIT) {
        return new CompilationUnitElementHandle(
            element as CompilationUnitElement);
      } else if (element.kind == ElementKind.CONSTRUCTOR) {
        return new ConstructorElementHandle(element as ConstructorElement);
      } else if (element.kind == ElementKind.EXPORT) {
        return new ExportElementHandle(element as ExportElement);
      } else if (element.kind == ElementKind.FIELD) {
        return new FieldElementHandle(element as FieldElement);
      } else if (element.kind == ElementKind.FUNCTION) {
        return new FunctionElementHandle(element as FunctionElement);
      } else if (element.kind == ElementKind.GETTER) {
        return new PropertyAccessorElementHandle(
            element as PropertyAccessorElement);
      } else if (element.kind == ElementKind.IMPORT) {
        return new ImportElementHandle(element as ImportElement);
      } else if (element.kind == ElementKind.LABEL) {
        return new LabelElementHandle(element as LabelElement);
      } else if (element.kind == ElementKind.LIBRARY) {
        return new LibraryElementHandle(element as LibraryElement);
      } else if (element.kind == ElementKind.LOCAL_VARIABLE) {
        return new LocalVariableElementHandle(element as LocalVariableElement);
      } else if (element.kind == ElementKind.METHOD) {
        return new MethodElementHandle(element as MethodElement);
      } else if (element.kind == ElementKind.PARAMETER) {
        return new ParameterElementHandle(element as ParameterElement);
      } else if (element.kind == ElementKind.PREFIX) {
        return new PrefixElementHandle(element as PrefixElement);
      } else if (element.kind == ElementKind.SETTER) {
        return new PropertyAccessorElementHandle(
            element as PropertyAccessorElement);
      } else if (element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
        return new TopLevelVariableElementHandle(
            element as TopLevelVariableElement);
      } else if (element.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
        return new FunctionTypeAliasElementHandle(
            element as FunctionTypeAliasElement);
      } else if (element.kind == ElementKind.TYPE_PARAMETER) {
        return new TypeParameterElementHandle(element as TypeParameterElement);
      } else {
        throw new UnsupportedOperationException();
      }
      break;
    }
  }

  /**
   * Return an array of the same size as the given array where each element of the returned array is
   * a handle for the corresponding element of the given array.
   *
   * @param elements the elements for which handles are to be created
   * @return an array of handles to the given elements
   */
  static List<Element> forElements(List<Element> elements) {
    int length = elements.length;
    List<Element> handles = new List<Element>.from(elements);
    for (int i = 0; i < length; i++) {
      handles[i] = forElement(elements[i]);
    }
    return handles;
  }
}

/**
 * The abstract class `ExecutableElementHandle` implements the behavior common to objects that
 * implement a handle to an [ExecutableElement].
 */
abstract class ExecutableElementHandle extends ElementHandle implements
    ExecutableElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ExecutableElementHandle(ExecutableElement element) : super(element);

  @override
  ExecutableElement get actualElement =>
      super.actualElement as ExecutableElement;

  @override
  List<FunctionElement> get functions => actualElement.functions;

  @override
  bool get isAsynchronous => actualElement.isAsynchronous;

  @override
  bool get isGenerator => actualElement.isGenerator;

  @override
  bool get isOperator => actualElement.isOperator;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  bool get isSynchronous => actualElement.isSynchronous;

  @override
  List<LabelElement> get labels => actualElement.labels;

  @override
  List<LocalVariableElement> get localVariables => actualElement.localVariables;

  @override
  List<ParameterElement> get parameters => actualElement.parameters;

  @override
  DartType get returnType => actualElement.returnType;

  @override
  FunctionType get type => actualElement.type;
}

/**
 * Instances of the class `ExportElementHandle` implement a handle to an `ExportElement`
 * .
 */
class ExportElementHandle extends ElementHandle implements ExportElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ExportElementHandle(ExportElement element) : super(element);

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
 * Instances of the class `FieldElementHandle` implement a handle to a `FieldElement`.
 */
class FieldElementHandle extends PropertyInducingElementHandle implements
    FieldElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  FieldElementHandle(FieldElement element) : super(element);

  @override
  FieldElement get actualElement => super.actualElement as FieldElement;

  @override
  ClassElement get enclosingElement => actualElement.enclosingElement;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  ElementKind get kind => ElementKind.FIELD;
}

/**
 * Instances of the class `FunctionElementHandle` implement a handle to a
 * `FunctionElement`.
 */
class FunctionElementHandle extends ExecutableElementHandle implements
    FunctionElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  FunctionElementHandle(FunctionElement element) : super(element);

  @override
  FunctionElement get actualElement => super.actualElement as FunctionElement;

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  FunctionDeclaration get node => actualElement.node;

  @override
  SourceRange get visibleRange => actualElement.visibleRange;
}

/**
 * Instances of the class `FunctionTypeAliasElementHandle` implement a handle to a
 * `FunctionTypeAliasElement`.
 */
class FunctionTypeAliasElementHandle extends ElementHandle implements
    FunctionTypeAliasElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  FunctionTypeAliasElementHandle(FunctionTypeAliasElement element)
      : super(element);

  @override
  FunctionTypeAliasElement get actualElement =>
      super.actualElement as FunctionTypeAliasElement;

  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement as CompilationUnitElement;

  @override
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  @override
  FunctionTypeAlias get node => actualElement.node;

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
 * Instances of the class `ImportElementHandle` implement a handle to an `ImportElement`
 * .
 */
class ImportElementHandle extends ElementHandle implements ImportElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ImportElementHandle(ImportElement element) : super(element);

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
 * Instances of the class `LabelElementHandle` implement a handle to a `LabelElement`.
 */
class LabelElementHandle extends ElementHandle implements LabelElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  LabelElementHandle(LabelElement element) : super(element);

  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement as ExecutableElement;

  @override
  ElementKind get kind => ElementKind.LABEL;
}

/**
 * Instances of the class `LibraryElementHandle` implement a handle to a
 * `LibraryElement`.
 */
class LibraryElementHandle extends ElementHandle implements LibraryElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  LibraryElementHandle(LibraryElement element) : super(element);

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
  List<ExportElement> get exports => actualElement.exports;

  @override
  bool get hasExtUri => actualElement.hasExtUri;

  @override
  bool get hasLoadLibraryFunction => actualElement.hasLoadLibraryFunction;

  @override
  List<LibraryElement> get importedLibraries => actualElement.importedLibraries;

  @override
  List<ImportElement> get imports => actualElement.imports;

  @override
  bool get isAngularHtml => actualElement.isAngularHtml;

  @override
  bool get isBrowserApplication => actualElement.isBrowserApplication;

  @override
  bool get isDartCore => actualElement.isDartCore;

  @override
  bool get isInSdk => actualElement.isInSdk;

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  FunctionElement get loadLibraryFunction => actualElement.loadLibraryFunction;

  @override
  List<CompilationUnitElement> get parts => actualElement.parts;

  @override
  List<PrefixElement> get prefixes => actualElement.prefixes;

  @override
  List<CompilationUnitElement> get units => actualElement.units;

  @override
  List<LibraryElement> get visibleLibraries => actualElement.visibleLibraries;

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) =>
      actualElement.getImportsWithPrefix(prefixElement);

  @override
  ClassElement getType(String className) => actualElement.getType(className);

  @override
  bool isUpToDate(int timeStamp) => actualElement.isUpToDate(timeStamp);
}

/**
 * Instances of the class `LocalVariableElementHandle` implement a handle to a
 * `LocalVariableElement`.
 */
class LocalVariableElementHandle extends VariableElementHandle implements
    LocalVariableElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  LocalVariableElementHandle(LocalVariableElement element) : super(element);

  @override
  LocalVariableElement get actualElement =>
      super.actualElement as LocalVariableElement;

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  List<ToolkitObjectElement> get toolkitObjects => actualElement.toolkitObjects;

  @override
  SourceRange get visibleRange => actualElement.visibleRange;
}

/**
 * Instances of the class `MethodElementHandle` implement a handle to a `MethodElement`.
 */
class MethodElementHandle extends ExecutableElementHandle implements
    MethodElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  MethodElementHandle(MethodElement element) : super(element);

  @override
  MethodElement get actualElement => super.actualElement as MethodElement;

  @override
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  @override
  bool get isAbstract => actualElement.isAbstract;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  MethodDeclaration get node => actualElement.node;
}

/**
 * Instances of the class `ParameterElementHandle` implement a handle to a
 * `ParameterElement`.
 */
class ParameterElementHandle extends VariableElementHandle implements
    ParameterElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  ParameterElementHandle(ParameterElement element) : super(element);

  @override
  ParameterElement get actualElement => super.actualElement as ParameterElement;

  @override
  String get defaultValueCode => actualElement.defaultValueCode;

  @override
  bool get isInitializingFormal => actualElement.isInitializingFormal;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  ParameterKind get parameterKind => actualElement.parameterKind;

  @override
  List<ParameterElement> get parameters => actualElement.parameters;

  @override
  SourceRange get visibleRange => actualElement.visibleRange;
}

/**
 * Instances of the class `PrefixElementHandle` implement a handle to a `PrefixElement`.
 */
class PrefixElementHandle extends ElementHandle implements PrefixElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  PrefixElementHandle(PrefixElement element) : super(element);

  @override
  PrefixElement get actualElement => super.actualElement as PrefixElement;

  @override
  LibraryElement get enclosingElement =>
      super.enclosingElement as LibraryElement;

  @override
  List<LibraryElement> get importedLibraries => actualElement.importedLibraries;

  @override
  ElementKind get kind => ElementKind.PREFIX;
}

/**
 * Instances of the class `PropertyAccessorElementHandle` implement a handle to a
 * `PropertyAccessorElement`.
 */
class PropertyAccessorElementHandle extends ExecutableElementHandle implements
    PropertyAccessorElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  PropertyAccessorElementHandle(PropertyAccessorElement element)
      : super(element);

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
  bool get isAbstract => actualElement.isAbstract;

  @override
  bool get isGetter => actualElement.isGetter;

  @override
  bool get isSetter => actualElement.isSetter;

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
 * The abstract class `PropertyInducingElementHandle` implements the behavior common to
 * objects that implement a handle to an `PropertyInducingElement`.
 */
abstract class PropertyInducingElementHandle extends VariableElementHandle
    implements PropertyInducingElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  PropertyInducingElementHandle(PropertyInducingElement element)
      : super(element);

  @override
  PropertyInducingElement get actualElement =>
      super.actualElement as PropertyInducingElement;

  @override
  PropertyAccessorElement get getter => actualElement.getter;

  @override
  bool get isStatic => actualElement.isStatic;

  @override
  DartType get propagatedType => actualElement.propagatedType;

  @override
  PropertyAccessorElement get setter => actualElement.setter;
}

/**
 * Instances of the class `TopLevelVariableElementHandle` implement a handle to a
 * `TopLevelVariableElement`.
 */
class TopLevelVariableElementHandle extends PropertyInducingElementHandle
    implements TopLevelVariableElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  TopLevelVariableElementHandle(TopLevelVariableElement element)
      : super(element);

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;
}

/**
 * Instances of the class `TypeParameterElementHandle` implement a handle to a
 * [TypeParameterElement].
 */
class TypeParameterElementHandle extends ElementHandle implements
    TypeParameterElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  TypeParameterElementHandle(TypeParameterElement element) : super(element);

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
 * The abstract class `VariableElementHandle` implements the behavior common to objects that
 * implement a handle to an `VariableElement`.
 */
abstract class VariableElementHandle extends ElementHandle implements
    VariableElement {
  /**
   * Initialize a newly created element handle to represent the given element.
   *
   * @param element the element being represented
   */
  VariableElementHandle(VariableElement element) : super(element);

  @override
  VariableElement get actualElement => super.actualElement as VariableElement;

  @override
  FunctionElement get initializer => actualElement.initializer;

  @override
  bool get isConst => actualElement.isConst;

  @override
  bool get isFinal => actualElement.isFinal;

  @override
  VariableDeclaration get node => actualElement.node;

  @override
  DartType get type => actualElement.type;
}
/**
 * TODO(scheglov) invalid implementation
 */
class WeakReference<T> {
  final T value;
  WeakReference(this.value);
  T get() => value;
}
