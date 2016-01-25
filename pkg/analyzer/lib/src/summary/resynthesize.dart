// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library summary_resynthesizer;

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/element_handle.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Implementation of [ElementResynthesizer] used when resynthesizing an element
 * model from summaries.
 */
abstract class SummaryResynthesizer extends ElementResynthesizer {
  /**
   * The parent [SummaryResynthesizer] which is asked to resynthesize elements
   * and get summaries before this resynthesizer attempts to do this.
   * Can be `null`.
   */
  final SummaryResynthesizer parent;

  /**
   * Source factory used to convert URIs to [Source] objects.
   */
  final SourceFactory sourceFactory;

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  /**
   * The [TypeProvider] used to obtain core types (such as Object, int, List,
   * and dynamic) during resynthesis.
   */
  final TypeProvider typeProvider;

  /**
   * Indicates whether the summary should be resynthesized assuming strong mode
   * semantics.
   */
  final bool strongMode;

  /**
   * Map of top level elements resynthesized from summaries.  The three map
   * keys are the first three elements of the element's location (the library
   * URI, the compilation unit URI, and the name of the top level declaration).
   */
  final Map<String, Map<String, Map<String, Element>>> _resynthesizedElements =
      <String, Map<String, Map<String, Element>>>{};

  /**
   * Map of libraries which have been resynthesized from summaries.  The map
   * key is the library URI.
   */
  final Map<String, LibraryElement> _resynthesizedLibraries =
      <String, LibraryElement>{};

  SummaryResynthesizer(this.parent, AnalysisContext context, this.typeProvider,
      this.sourceFactory, this.strongMode)
      : super(context);

  /**
   * Number of libraries that have been resynthesized so far.
   */
  int get resynthesisCount => _resynthesizedLibraries.length;

  /**
   * Perform delayed finalization of the `dart:core` and `dart:async` libraries.
   */
  void finalizeCoreAsyncLibraries() {
    (_resynthesizedLibraries['dart:core'] as LibraryElementImpl)
        .createLoadLibraryFunction(typeProvider);
    (_resynthesizedLibraries['dart:async'] as LibraryElementImpl)
        .createLoadLibraryFunction(typeProvider);
  }

  @override
  Element getElement(ElementLocation location) {
    List<String> components = location.components;
    String libraryUri = components[0];
    // Ask the parent resynthesizer.
    if (parent != null && parent._hasLibrarySummary(libraryUri)) {
      return parent.getElement(location);
    }
    // Resynthesize locally.
    if (components.length == 1) {
      return getLibraryElement(libraryUri);
    } else if (components.length == 3) {
      Map<String, Map<String, Element>> libraryMap =
          _resynthesizedElements[libraryUri];
      if (libraryMap == null) {
        getLibraryElement(libraryUri);
        libraryMap = _resynthesizedElements[libraryUri];
        assert(libraryMap != null);
      }
      Map<String, Element> compilationUnitElements = libraryMap[components[1]];
      if (compilationUnitElements != null) {
        Element element = compilationUnitElements[components[2]];
        if (element != null) {
          return element;
        }
      }
      throw new Exception('Element not found in summary: $location');
    } else {
      throw new UnimplementedError(location.toString());
    }
  }

  /**
   * Get the [LibraryElement] for the given [uri], resynthesizing it if it
   * hasn't been resynthesized already.
   */
  LibraryElement getLibraryElement(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return parent.getLibraryElement(uri);
    }
    return _resynthesizedLibraries.putIfAbsent(uri, () {
      LinkedLibrary serializedLibrary = _getLinkedSummaryOrThrow(uri);
      List<UnlinkedUnit> serializedUnits = <UnlinkedUnit>[
        _getUnlinkedSummaryOrThrow(uri)
      ];
      Source librarySource = _getSource(uri);
      for (String part in serializedUnits[0].publicNamespace.parts) {
        Source partSource = sourceFactory.resolveUri(librarySource, part);
        String partAbsUri = partSource.uri.toString();
        serializedUnits.add(_getUnlinkedSummaryOrThrow(partAbsUri));
      }
      _LibraryResynthesizer libraryResynthesizer = new _LibraryResynthesizer(
          this, serializedLibrary, serializedUnits, librarySource);
      LibraryElement library = libraryResynthesizer.buildLibrary();
      _resynthesizedElements[uri] = libraryResynthesizer.resummarizedElements;
      return library;
    });
  }

  /**
   * Return the [LinkedLibrary] for the given [uri] or `null` if it could not
   * be found.  Caller has already checked that `parent.hasLibrarySummary(uri)`
   * returns `false`.
   */
  LinkedLibrary getLinkedSummary(String uri);

  /**
   * Return the [UnlinkedUnit] for the given [uri] or `null` if it could not
   * be found.  Caller has already checked that `parent.hasLibrarySummary(uri)`
   * returns `false`.
   */
  UnlinkedUnit getUnlinkedSummary(String uri);

  /**
   * Return `true` if this resynthesizer can provide summaries of the libraries
   * with the given [uri].  Caller has already checked that
   * `parent.hasLibrarySummary(uri)` returns `false`.
   */
  bool hasLibrarySummary(String uri);

  /**
   * Return the [LinkedLibrary] for the given [uri] or throw [StateError] if it
   * could not be found.
   */
  LinkedLibrary _getLinkedSummaryOrThrow(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return parent._getLinkedSummaryOrThrow(uri);
    }
    LinkedLibrary summary = getLinkedSummary(uri);
    if (summary != null) {
      return summary;
    }
    throw new StateError('Unable to find linked summary: $uri');
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(uri, () => sourceFactory.forUri(uri));
  }

  /**
   * Return the [UnlinkedUnit] for the given [uri] or throw [StateError] if it
   * could not be found.
   */
  UnlinkedUnit _getUnlinkedSummaryOrThrow(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return parent._getUnlinkedSummaryOrThrow(uri);
    }
    UnlinkedUnit summary = getUnlinkedSummary(uri);
    if (summary != null) {
      return summary;
    }
    throw new StateError('Unable to find unlinked summary: $uri');
  }

  /**
   * Return `true` if this resynthesizer can provide summaries of the libraries
   * with the given [uri].
   */
  bool _hasLibrarySummary(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return true;
    }
    return hasLibrarySummary(uri);
  }
}

/**
 * An instance of [_LibraryResynthesizer] is responsible for resynthesizing the
 * elements in a single library from that library's summary.
 */
class _LibraryResynthesizer {
  /**
   * The [SummaryResynthesizer] which is being used to obtain summaries.
   */
  final SummaryResynthesizer summaryResynthesizer;

  /**
   * Linked summary of the library to be resynthesized.
   */
  final LinkedLibrary linkedLibrary;

  /**
   * Unlinked compilation units constituting the library to be resynthesized.
   */
  final List<UnlinkedUnit> unlinkedUnits;

  /**
   * [Source] object for the library to be resynthesized.
   */
  final Source librarySource;

  /**
   * Indicates whether [librarySource] is the `dart:core` library.
   */
  bool isCoreLibrary;

  /**
   * Classes which should have their supertype set to "object" once
   * resynthesis is complete.  Only used if [isCoreLibrary] is `true`.
   */
  List<ClassElementImpl> delayedObjectSubclasses = <ClassElementImpl>[];

  /**
   * [ElementHolder] into which resynthesized elements should be placed.  This
   * object is recreated afresh for each unit in the library, and is used to
   * populate the [CompilationUnitElement].
   */
  ElementHolder unitHolder;

  /**
   * The [LinkedUnit] from which elements are currently being resynthesized.
   */
  LinkedUnit linkedUnit;

  /**
   * The [UnlinkedUnit] from which elements are currently being resynthesized.
   */
  UnlinkedUnit unlinkedUnit;

  /**
   * Map from slot id to the corresponding [EntityRef] object for linked types
   * (i.e. propagated and inferred types).
   */
  Map<int, EntityRef> linkedTypeMap;

  /**
   * Map of top level elements that have been resynthesized so far.  The first
   * key is the URI of the compilation unit; the second is the name of the top
   * level element.
   */
  final Map<String, Map<String, Element>> resummarizedElements =
      <String, Map<String, Element>>{};

  /**
   * Type parameters for the generic class, typedef, or executable currently
   * being resynthesized, if any.  If multiple entities with type parameters
   * are nested (e.g. a generic executable inside a generic class), this is the
   * concatenation of all type parameters from all declarations currently in
   * force, with the outermost declaration appearing first.  If there are no
   * type parameters, or we are not currently resynthesizing a class, typedef,
   * or executable, then this is an empty list.
   */
  List<TypeParameterElement> currentTypeParameters = <TypeParameterElement>[];

  /**
   * If a class is currently being resynthesized, map from field name to the
   * corresponding field element.  This is used when resynthesizing
   * initializing formal parameters.
   */
  Map<String, FieldElementImpl> fields;

  _LibraryResynthesizer(this.summaryResynthesizer, this.linkedLibrary,
      this.unlinkedUnits, this.librarySource) {
    isCoreLibrary = librarySource.uri.toString() == 'dart:core';
  }

  /**
   * Return a list of type arguments corresponding to [currentTypeParameters].
   */
  List<TypeParameterType> get currentTypeArguments => currentTypeParameters
      ?.map((TypeParameterElement param) => param.type)
      ?.toList();

  /**
   * Resynthesize a [ClassElement] and place it in [unitHolder].
   */
  void buildClass(UnlinkedClass serializedClass) {
    try {
      currentTypeParameters =
          serializedClass.typeParameters.map(buildTypeParameter).toList();
      for (int i = 0; i < serializedClass.typeParameters.length; i++) {
        finishTypeParameter(
            serializedClass.typeParameters[i], currentTypeParameters[i]);
      }
      ClassElementImpl classElement = new ClassElementImpl(
          serializedClass.name, serializedClass.nameOffset);
      classElement.abstract = serializedClass.isAbstract;
      classElement.mixinApplication = serializedClass.isMixinApplication;
      InterfaceTypeImpl correspondingType = new InterfaceTypeImpl(classElement);
      if (serializedClass.supertype != null) {
        classElement.supertype = buildType(serializedClass.supertype);
      } else if (!serializedClass.hasNoSupertype) {
        if (isCoreLibrary) {
          delayedObjectSubclasses.add(classElement);
        } else {
          classElement.supertype = summaryResynthesizer.typeProvider.objectType;
        }
      }
      classElement.interfaces =
          serializedClass.interfaces.map(buildType).toList();
      classElement.mixins = serializedClass.mixins.map(buildType).toList();
      classElement.typeParameters = currentTypeParameters;
      ElementHolder memberHolder = new ElementHolder();
      fields = <String, FieldElementImpl>{};
      for (UnlinkedVariable serializedVariable in serializedClass.fields) {
        buildVariable(serializedVariable, memberHolder);
      }
      bool constructorFound = false;
      for (UnlinkedExecutable serializedExecutable
          in serializedClass.executables) {
        switch (serializedExecutable.kind) {
          case UnlinkedExecutableKind.constructor:
            constructorFound = true;
            buildConstructor(
                serializedExecutable, memberHolder, correspondingType);
            break;
          case UnlinkedExecutableKind.functionOrMethod:
          case UnlinkedExecutableKind.getter:
          case UnlinkedExecutableKind.setter:
            buildExecutable(serializedExecutable, memberHolder);
            break;
        }
      }
      if (!serializedClass.isMixinApplication) {
        if (!constructorFound) {
          // Synthesize implicit constructors.
          ConstructorElementImpl constructor =
              new ConstructorElementImpl('', -1);
          constructor.synthetic = true;
          constructor.returnType = correspondingType;
          constructor.type = new FunctionTypeImpl.elementWithNameAndArgs(
              constructor, null, currentTypeArguments, false);
          memberHolder.addConstructor(constructor);
        }
        classElement.constructors = memberHolder.constructors;
      }
      classElement.accessors = memberHolder.accessors;
      classElement.fields = memberHolder.fields;
      classElement.methods = memberHolder.methods;
      correspondingType.typeArguments = currentTypeArguments;
      classElement.type = correspondingType;
      buildDocumentation(classElement, serializedClass.documentationComment);
      unitHolder.addType(classElement);
    } finally {
      currentTypeParameters = <TypeParameterElement>[];
      fields = null;
    }
  }

  /**
   * Resynthesize a [NamespaceCombinator].
   */
  NamespaceCombinator buildCombinator(UnlinkedCombinator serializedCombinator) {
    if (serializedCombinator.shows.isNotEmpty) {
      ShowElementCombinatorImpl combinator = new ShowElementCombinatorImpl();
      // Note: we call toList() so that we don't retain a reference to the
      // deserialized data structure.
      combinator.shownNames = serializedCombinator.shows.toList();
      return combinator;
    } else {
      HideElementCombinatorImpl combinator = new HideElementCombinatorImpl();
      // Note: we call toList() so that we don't retain a reference to the
      // deserialized data structure.
      combinator.hiddenNames = serializedCombinator.hides.toList();
      return combinator;
    }
  }

  /**
   * Resynthesize a [ConstructorElement] and place it in the given [holder].
   * [classType] is the type of the class for which this element is a
   * constructor.
   */
  void buildConstructor(UnlinkedExecutable serializedExecutable,
      ElementHolder holder, InterfaceType classType) {
    assert(serializedExecutable.kind == UnlinkedExecutableKind.constructor);
    ConstructorElementImpl constructorElement = new ConstructorElementImpl(
        serializedExecutable.name, serializedExecutable.nameOffset);
    constructorElement.returnType = classType;
    buildExecutableCommonParts(constructorElement, serializedExecutable);
    constructorElement.factory = serializedExecutable.isFactory;
    constructorElement.const2 = serializedExecutable.isConst;
    holder.addConstructor(constructorElement);
  }

  /**
   * Build the documentation for the given [element].  Does nothing if
   * [serializedDocumentationComment] is `null`.
   */
  void buildDocumentation(ElementImpl element,
      UnlinkedDocumentationComment serializedDocumentationComment) {
    if (serializedDocumentationComment != null) {
      element.documentationComment = serializedDocumentationComment.text;
      element.setDocRange(serializedDocumentationComment.offset,
          serializedDocumentationComment.length);
    }
  }

  /**
   * Resynthesize the [ClassElement] corresponding to an enum, along with the
   * associated fields and implicit accessors.
   */
  void buildEnum(UnlinkedEnum serializedEnum) {
    assert(!isCoreLibrary);
    // TODO(paulberry): add offset support (for this element type and others)
    ClassElementImpl classElement =
        new ClassElementImpl(serializedEnum.name, serializedEnum.nameOffset);
    classElement.enum2 = true;
    InterfaceType enumType = new InterfaceTypeImpl(classElement);
    classElement.type = enumType;
    classElement.supertype = summaryResynthesizer.typeProvider.objectType;
    buildDocumentation(classElement, serializedEnum.documentationComment);
    ElementHolder memberHolder = new ElementHolder();
    FieldElementImpl indexField = new FieldElementImpl('index', -1);
    indexField.final2 = true;
    indexField.synthetic = true;
    indexField.type = summaryResynthesizer.typeProvider.intType;
    memberHolder.addField(indexField);
    buildImplicitAccessors(indexField, memberHolder);
    FieldElementImpl valuesField = new ConstFieldElementImpl('values', -1);
    valuesField.synthetic = true;
    valuesField.const3 = true;
    valuesField.static = true;
    valuesField.type = summaryResynthesizer.typeProvider.listType
        .substitute4(<DartType>[enumType]);
    memberHolder.addField(valuesField);
    buildImplicitAccessors(valuesField, memberHolder);
    for (UnlinkedEnumValue serializedEnumValue in serializedEnum.values) {
      ConstFieldElementImpl valueField = new ConstFieldElementImpl(
          serializedEnumValue.name, serializedEnumValue.nameOffset);
      valueField.const3 = true;
      valueField.static = true;
      valueField.type = enumType;
      memberHolder.addField(valueField);
      buildImplicitAccessors(valueField, memberHolder);
    }
    classElement.fields = memberHolder.fields;
    classElement.accessors = memberHolder.accessors;
    classElement.constructors = <ConstructorElement>[];
    unitHolder.addEnum(classElement);
  }

  /**
   * Resynthesize an [ExecutableElement] and place it in the given [holder].
   */
  void buildExecutable(UnlinkedExecutable serializedExecutable,
      [ElementHolder holder]) {
    bool isTopLevel = holder == null;
    if (holder == null) {
      holder = unitHolder;
    }
    UnlinkedExecutableKind kind = serializedExecutable.kind;
    String name = serializedExecutable.name;
    if (kind == UnlinkedExecutableKind.setter) {
      assert(name.endsWith('='));
      name = name.substring(0, name.length - 1);
    }
    switch (kind) {
      case UnlinkedExecutableKind.functionOrMethod:
        if (isTopLevel) {
          FunctionElementImpl executableElement =
              new FunctionElementImpl(name, serializedExecutable.nameOffset);
          buildExecutableCommonParts(executableElement, serializedExecutable);
          holder.addFunction(executableElement);
        } else {
          MethodElementImpl executableElement =
              new MethodElementImpl(name, serializedExecutable.nameOffset);
          executableElement.abstract = serializedExecutable.isAbstract;
          buildExecutableCommonParts(executableElement, serializedExecutable);
          executableElement.static = serializedExecutable.isStatic;
          holder.addMethod(executableElement);
        }
        break;
      case UnlinkedExecutableKind.getter:
      case UnlinkedExecutableKind.setter:
        PropertyAccessorElementImpl executableElement =
            new PropertyAccessorElementImpl(
                name, serializedExecutable.nameOffset);
        if (isTopLevel) {
          executableElement.static = true;
        } else {
          executableElement.static = serializedExecutable.isStatic;
          executableElement.abstract = serializedExecutable.isAbstract;
        }
        buildExecutableCommonParts(executableElement, serializedExecutable);
        DartType type;
        if (kind == UnlinkedExecutableKind.getter) {
          executableElement.getter = true;
          type = executableElement.returnType;
        } else {
          executableElement.setter = true;
          type = executableElement.parameters[0].type;
        }
        holder.addAccessor(executableElement);
        // TODO(paulberry): consider removing implicit variables from the
        // element model; the spec doesn't call for them, and they cause
        // trouble when getters/setters exist in different parts.
        PropertyInducingElementImpl implicitVariable;
        if (isTopLevel) {
          implicitVariable = buildImplicitTopLevelVariable(name, kind, holder);
        } else {
          FieldElementImpl field = buildImplicitField(name, type, kind, holder);
          field.static = serializedExecutable.isStatic;
          implicitVariable = field;
        }
        executableElement.variable = implicitVariable;
        if (kind == UnlinkedExecutableKind.getter) {
          implicitVariable.getter = executableElement;
        } else {
          implicitVariable.setter = executableElement;
        }
        // TODO(paulberry): do the right thing when getter and setter are in
        // different units.
        break;
      default:
        // The only other executable type is a constructor, and that is handled
        // separately (in [buildConstructor].  So this code should be
        // unreachable.
        assert(false);
    }
  }

  /**
   * Handle the parts of an executable element that are common to constructors,
   * functions, methods, getters, and setters.
   */
  void buildExecutableCommonParts(ExecutableElementImpl executableElement,
      UnlinkedExecutable serializedExecutable) {
    List<TypeParameterType> oldTypeArguments = currentTypeArguments;
    int oldTypeParametersLength = currentTypeParameters.length;
    if (serializedExecutable.typeParameters.isNotEmpty) {
      executableElement.typeParameters =
          serializedExecutable.typeParameters.map(buildTypeParameter).toList();
      currentTypeParameters.addAll(executableElement.typeParameters);
    }
    executableElement.parameters =
        serializedExecutable.parameters.map(buildParameter).toList();
    if (serializedExecutable.kind == UnlinkedExecutableKind.constructor) {
      // Caller handles setting the return type.
      assert(serializedExecutable.returnType == null);
    } else {
      bool isSetter =
          serializedExecutable.kind == UnlinkedExecutableKind.setter;
      executableElement.returnType =
          buildLinkedType(serializedExecutable.inferredReturnTypeSlot) ??
              buildType(serializedExecutable.returnType,
                  defaultVoid: isSetter && summaryResynthesizer.strongMode);
      executableElement.hasImplicitReturnType =
          serializedExecutable.returnType == null;
    }
    executableElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
        executableElement, null, oldTypeArguments, false);
    executableElement.external = serializedExecutable.isExternal;
    currentTypeParameters.removeRange(
        oldTypeParametersLength, currentTypeParameters.length);
    buildDocumentation(
        executableElement, serializedExecutable.documentationComment);
  }

  /**
   * Resynthesize an [ExportElement],
   */
  ExportElement buildExport(UnlinkedExportPublic serializedExportPublic,
      UnlinkedExportNonPublic serializedExportNonPublic) {
    ExportElementImpl exportElement =
        new ExportElementImpl(serializedExportNonPublic.offset);
    String exportedLibraryUri = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, serializedExportPublic.uri)
        .uri
        .toString();
    exportElement.exportedLibrary = new LibraryElementHandle(
        summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[exportedLibraryUri]));
    exportElement.uri = serializedExportPublic.uri;
    exportElement.combinators =
        serializedExportPublic.combinators.map(buildCombinator).toList();
    exportElement.uriOffset = serializedExportNonPublic.uriOffset;
    exportElement.uriEnd = serializedExportNonPublic.uriEnd;
    return exportElement;
  }

  /**
   * Build an [ElementHandle] referring to the entity referred to by the given
   * [exportName].
   */
  ElementHandle buildExportName(LinkedExportName exportName) {
    String name = exportName.name;
    if (exportName.kind == ReferenceKind.topLevelPropertyAccessor &&
        !name.endsWith('=')) {
      name += '?';
    }
    ElementLocationImpl location = getReferencedLocation(
        linkedLibrary.dependencies[exportName.dependency],
        exportName.unit,
        name);
    switch (exportName.kind) {
      case ReferenceKind.classOrEnum:
        return new ClassElementHandle(summaryResynthesizer, location);
      case ReferenceKind.typedef:
        return new FunctionTypeAliasElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.topLevelFunction:
        return new FunctionElementHandle(summaryResynthesizer, location);
      case ReferenceKind.topLevelPropertyAccessor:
        return new PropertyAccessorElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.constructor:
      case ReferenceKind.staticMethod:
      case ReferenceKind.prefix:
      case ReferenceKind.unresolved:
        // Should never happen.  Exported names never refer to import prefixes,
        // and they always refer to defined top-level entities.
        throw new StateError('Unexpected export name kind: ${exportName.kind}');
    }
  }

  /**
   * Build the export namespace for the library by aggregating together its
   * [publicNamespace] and [exportNames].
   */
  Namespace buildExportNamespace(
      Namespace publicNamespace, List<LinkedExportName> exportNames) {
    HashMap<String, Element> definedNames = new HashMap<String, Element>();
    // Start by populating all the public names from [publicNamespace].
    publicNamespace.definedNames.forEach((String name, Element element) {
      definedNames[name] = element;
    });
    // Add all the names from [exportNames].
    for (LinkedExportName exportName in exportNames) {
      definedNames.putIfAbsent(
          exportName.name, () => buildExportName(exportName));
    }
    return new Namespace(definedNames);
  }

  /**
   * Resynthesize a [FieldElement].
   */
  FieldElement buildField(UnlinkedVariable serializedField) {
    FieldElementImpl fieldElement =
        new FieldElementImpl(serializedField.name, -1);
    fieldElement.type = buildType(serializedField.type);
    fieldElement.const3 = serializedField.isConst;
    return fieldElement;
  }

  /**
   * Build the implicit getter and setter associated with [element], and place
   * them in [holder].
   */
  void buildImplicitAccessors(
      PropertyInducingElementImpl element, ElementHolder holder) {
    String name = element.name;
    DartType type = element.type;
    PropertyAccessorElementImpl getter =
        new PropertyAccessorElementImpl(name, element.nameOffset);
    getter.getter = true;
    getter.static = element.isStatic;
    getter.synthetic = true;
    getter.returnType = type;
    getter.type = new FunctionTypeImpl(getter);
    getter.variable = element;
    getter.hasImplicitReturnType = element.hasImplicitType;
    holder.addAccessor(getter);
    element.getter = getter;
    if (!(element.isConst || element.isFinal)) {
      PropertyAccessorElementImpl setter =
          new PropertyAccessorElementImpl(name, element.nameOffset);
      setter.setter = true;
      setter.static = element.isStatic;
      setter.synthetic = true;
      setter.parameters = <ParameterElement>[
        new ParameterElementImpl('_$name', element.nameOffset)
          ..synthetic = true
          ..type = type
          ..parameterKind = ParameterKind.REQUIRED
      ];
      setter.returnType = VoidTypeImpl.instance;
      setter.type = new FunctionTypeImpl(setter);
      setter.variable = element;
      holder.addAccessor(setter);
      element.setter = setter;
    }
  }

  /**
   * Build the implicit field associated with a getter or setter, and place it
   * in [holder].
   */
  FieldElementImpl buildImplicitField(String name, DartType type,
      UnlinkedExecutableKind kind, ElementHolder holder) {
    FieldElementImpl field = holder.getField(name);
    if (field == null) {
      field = new FieldElementImpl(name, -1);
      field.synthetic = true;
      field.final2 = kind == UnlinkedExecutableKind.getter;
      field.type = type;
      holder.addField(field);
      return field;
    } else {
      // TODO(paulberry): what if the getter and setter have a type mismatch?
      field.final2 = false;
      return field;
    }
  }

  /**
   * Build the implicit top level variable associated with a getter or setter,
   * and place it in [holder].
   */
  PropertyInducingElementImpl buildImplicitTopLevelVariable(
      String name, UnlinkedExecutableKind kind, ElementHolder holder) {
    TopLevelVariableElementImpl variable = holder.getTopLevelVariable(name);
    if (variable == null) {
      variable = new TopLevelVariableElementImpl(name, -1);
      variable.synthetic = true;
      variable.final2 = kind == UnlinkedExecutableKind.getter;
      holder.addTopLevelVariable(variable);
      return variable;
    } else {
      // TODO(paulberry): what if the getter and setter have a type mismatch?
      variable.final2 = false;
      return variable;
    }
  }

  /**
   * Resynthesize an [ImportElement].
   */
  ImportElement buildImport(UnlinkedImport serializedImport, int dependency) {
    bool isSynthetic = serializedImport.isImplicit;
    // TODO(paulberry): it seems problematic for the offset to be 0 for
    // non-synthetic imports, since it is used to disambiguate location.
    ImportElementImpl importElement =
        new ImportElementImpl(isSynthetic ? -1 : serializedImport.offset);
    String absoluteUri = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, linkedLibrary.dependencies[dependency].uri)
        .uri
        .toString();
    importElement.importedLibrary = new LibraryElementHandle(
        summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[absoluteUri]));
    if (isSynthetic) {
      importElement.synthetic = true;
    } else {
      importElement.uri = serializedImport.uri;
      importElement.uriOffset = serializedImport.uriOffset;
      importElement.uriEnd = serializedImport.uriEnd;
      importElement.deferred = serializedImport.isDeferred;
    }
    importElement.prefixOffset = serializedImport.prefixOffset;
    if (serializedImport.prefixReference != 0) {
      UnlinkedReference serializedPrefix =
          unlinkedUnits[0].references[serializedImport.prefixReference];
      importElement.prefix = new PrefixElementImpl(
          serializedPrefix.name, serializedImport.prefixOffset);
    }
    importElement.combinators =
        serializedImport.combinators.map(buildCombinator).toList();
    return importElement;
  }

  /**
   * Main entry point.  Resynthesize the [LibraryElement] and return it.
   */
  LibraryElement buildLibrary() {
    bool hasName = unlinkedUnits[0].libraryName.isNotEmpty;
    LibraryElementImpl library = new LibraryElementImpl(
        summaryResynthesizer.context,
        unlinkedUnits[0].libraryName,
        hasName ? unlinkedUnits[0].libraryNameOffset : -1,
        unlinkedUnits[0].libraryNameLength);
    buildDocumentation(library, unlinkedUnits[0].libraryDocumentationComment);
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl(librarySource.shortName);
    library.definingCompilationUnit = definingCompilationUnit;
    definingCompilationUnit.source = librarySource;
    definingCompilationUnit.librarySource = librarySource;
    List<CompilationUnitElement> parts = <CompilationUnitElement>[];
    UnlinkedUnit unlinkedDefiningUnit = unlinkedUnits[0];
    assert(unlinkedDefiningUnit.publicNamespace.parts.length + 1 ==
        linkedLibrary.units.length);
    for (int i = 1; i < linkedLibrary.units.length; i++) {
      CompilationUnitElementImpl part = buildPart(
          unlinkedDefiningUnit.publicNamespace.parts[i - 1],
          unlinkedDefiningUnit.parts[i - 1],
          unlinkedUnits[i]);
      parts.add(part);
    }
    library.parts = parts;
    List<ImportElement> imports = <ImportElement>[];
    for (int i = 0; i < unlinkedDefiningUnit.imports.length; i++) {
      imports.add(buildImport(unlinkedDefiningUnit.imports[i],
          linkedLibrary.importDependencies[i]));
    }
    library.imports = imports;
    List<ExportElement> exports = <ExportElement>[];
    assert(unlinkedDefiningUnit.exports.length ==
        unlinkedDefiningUnit.publicNamespace.exports.length);
    for (int i = 0; i < unlinkedDefiningUnit.exports.length; i++) {
      exports.add(buildExport(unlinkedDefiningUnit.publicNamespace.exports[i],
          unlinkedDefiningUnit.exports[i]));
    }
    library.exports = exports;
    populateUnit(definingCompilationUnit, 0);
    for (int i = 0; i < parts.length; i++) {
      populateUnit(parts[i], i + 1);
    }
    BuildLibraryElementUtils.patchTopLevelAccessors(library);
    // Update delayed Object class references.
    if (isCoreLibrary) {
      ClassElement objectElement = library.getType('Object');
      assert(objectElement != null);
      for (ClassElementImpl classElement in delayedObjectSubclasses) {
        classElement.supertype = objectElement.type;
      }
    }
    // Compute namespaces.
    library.publicNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(library);
    library.exportNamespace = buildExportNamespace(
        library.publicNamespace, linkedLibrary.exportNames);
    // Find the entry point.  Note: we can't use element.isEntryPoint because
    // that will trigger resynthesis of exported libraries.
    Element entryPoint =
        library.exportNamespace.get(FunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is FunctionElement) {
      library.entryPoint = entryPoint;
    }
    // Create the synthetic element for `loadLibrary`.
    // Until the client received dart:core and dart:async, we cannot do this,
    // because the TypeProvider is not fully initialized. So, it is up to the
    // Dart SDK client to initialize TypeProvider and finish the dart:core and
    // dart:async libraries creation.
    if (library.name != 'dart.core' && library.name != 'dart.async') {
      library.createLoadLibraryFunction(summaryResynthesizer.typeProvider);
    }
    // Done.
    return library;
  }

  /**
   * Build the appropriate [DartType] object corresponding to a slot id in the
   * [LinkedUnit.types] table.
   */
  DartType buildLinkedType(int slot) {
    if (slot == 0) {
      // A slot id of 0 means there is no [DartType] object to build.
      return null;
    }
    EntityRef type = linkedTypeMap[slot];
    if (type == null) {
      // A missing entry in [LinkedUnit.types] means there is no [DartType]
      // stored in this slot.
      return null;
    }
    return buildType(type);
  }

  /**
   * Resynthesize a [ParameterElement].
   */
  ParameterElement buildParameter(UnlinkedParam serializedParameter) {
    ParameterElementImpl parameterElement;
    if (serializedParameter.isInitializingFormal) {
      parameterElement = new FieldFormalParameterElementImpl.forNameAndOffset(
          serializedParameter.name, serializedParameter.nameOffset)
        ..field = fields[serializedParameter.name];
    } else {
      parameterElement = new ParameterElementImpl(
          serializedParameter.name, serializedParameter.nameOffset);
    }
    if (serializedParameter.isFunctionTyped) {
      FunctionElementImpl parameterTypeElement =
          new FunctionElementImpl('', -1);
      parameterTypeElement.synthetic = true;
      parameterElement.parameters =
          serializedParameter.parameters.map(buildParameter).toList();
      parameterTypeElement.enclosingElement = parameterElement;
      parameterTypeElement.shareParameters(parameterElement.parameters);
      parameterTypeElement.returnType = buildType(serializedParameter.type);
      parameterElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
          parameterTypeElement, null, currentTypeArguments, false);
    } else {
      if (serializedParameter.isInitializingFormal &&
          serializedParameter.type == null) {
        // The type is inherited from the matching field.
        parameterElement.type = fields[serializedParameter.name]?.type ??
            summaryResynthesizer.typeProvider.dynamicType;
      } else {
        parameterElement.type =
            buildLinkedType(serializedParameter.inferredTypeSlot) ??
                buildType(serializedParameter.type);
      }
      parameterElement.hasImplicitType = serializedParameter.type == null;
    }
    switch (serializedParameter.kind) {
      case UnlinkedParamKind.named:
        parameterElement.parameterKind = ParameterKind.NAMED;
        break;
      case UnlinkedParamKind.positional:
        parameterElement.parameterKind = ParameterKind.POSITIONAL;
        break;
      case UnlinkedParamKind.required:
        parameterElement.parameterKind = ParameterKind.REQUIRED;
        break;
    }
    return parameterElement;
  }

  /**
   * Create, but do not populate, the [CompilationUnitElement] for a part other
   * than the defining compilation unit.
   */
  CompilationUnitElementImpl buildPart(
      String uri, UnlinkedPart partDecl, UnlinkedUnit serializedPart) {
    Source unitSource =
        summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
    CompilationUnitElementImpl partUnit =
        new CompilationUnitElementImpl(unitSource.shortName);
    partUnit.uriOffset = partDecl.uriOffset;
    partUnit.uriEnd = partDecl.uriEnd;
    partUnit.source = unitSource;
    partUnit.librarySource = librarySource;
    partUnit.uri = uri;
    return partUnit;
  }

  /**
   * Build a [DartType] object based on a [EntityRef].  This [DartType]
   * may refer to elements in other libraries than the library being
   * deserialized, so handles are used to avoid having to deserialize other
   * libraries in the process.
   */
  DartType buildType(EntityRef type, {bool defaultVoid: false}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return summaryResynthesizer.typeProvider.dynamicType;
      }
    }
    if (type.paramReference != 0) {
      // TODO(paulberry): make this work for generic methods.
      return currentTypeParameters[
          currentTypeParameters.length - type.paramReference].type;
    } else {
      // TODO(paulberry): handle references to things other than classes (note:
      // this should only occur in the case of erroneous code).
      // TODO(paulberry): test reference to something inside a part.
      // TODO(paulberry): test reference to something inside a part of the
      // current lib.
      LinkedReference referenceResolution =
          linkedUnit.references[type.reference];
      String name;
      if (type.reference < unlinkedUnit.references.length) {
        name = unlinkedUnit.references[type.reference].name;
      } else {
        name = referenceResolution.name;
      }
      ElementLocationImpl location;
      if (referenceResolution.dependency != 0) {
        location = getReferencedLocation(
            linkedLibrary.dependencies[referenceResolution.dependency],
            referenceResolution.unit,
            name);
      } else if (referenceResolution.kind == ReferenceKind.unresolved) {
        return summaryResynthesizer.typeProvider.undefinedType;
      } else if (name == 'dynamic') {
        return summaryResynthesizer.typeProvider.dynamicType;
      } else if (name == 'void') {
        return VoidTypeImpl.instance;
      } else {
        String referencedLibraryUri = librarySource.uri.toString();
        String partUri;
        if (referenceResolution.unit != 0) {
          String uri = unlinkedUnits[0].publicNamespace.parts[
              referenceResolution.unit - 1];
          Source partSource =
              summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
          partUri = partSource.uri.toString();
        } else {
          partUri = referencedLibraryUri;
        }
        location = new ElementLocationImpl.con3(
            <String>[referencedLibraryUri, partUri, name]);
      }
      List<DartType> typeArguments = const <DartType>[];
      if (referenceResolution.numTypeParameters != 0) {
        typeArguments = <DartType>[];
        for (int i = 0; i < referenceResolution.numTypeParameters; i++) {
          if (i < type.typeArguments.length) {
            typeArguments.add(buildType(type.typeArguments[i]));
          } else {
            typeArguments.add(summaryResynthesizer.typeProvider.dynamicType);
          }
        }
      }
      switch (referenceResolution.kind) {
        case ReferenceKind.classOrEnum:
          return new InterfaceTypeImpl.elementWithNameAndArgs(
              new ClassElementHandle(summaryResynthesizer, location),
              name,
              typeArguments);
        case ReferenceKind.typedef:
          return new FunctionTypeImpl.elementWithNameAndArgs(
              new FunctionTypeAliasElementHandle(
                  summaryResynthesizer, location),
              name,
              typeArguments,
              typeArguments.isNotEmpty);
        default:
          // TODO(paulberry): figure out how to handle this case (which should
          // only occur in the event of erroneous code).
          throw new UnimplementedError();
      }
    }
  }

  /**
   * Resynthesize a [FunctionTypeAliasElement] and place it in the
   * [unitHolder].
   */
  void buildTypedef(UnlinkedTypedef serializedTypedef) {
    try {
      currentTypeParameters =
          serializedTypedef.typeParameters.map(buildTypeParameter).toList();
      for (int i = 0; i < serializedTypedef.typeParameters.length; i++) {
        finishTypeParameter(
            serializedTypedef.typeParameters[i], currentTypeParameters[i]);
      }
      FunctionTypeAliasElementImpl functionTypeAliasElement =
          new FunctionTypeAliasElementImpl(
              serializedTypedef.name, serializedTypedef.nameOffset);
      functionTypeAliasElement.parameters =
          serializedTypedef.parameters.map(buildParameter).toList();
      functionTypeAliasElement.returnType =
          buildType(serializedTypedef.returnType);
      functionTypeAliasElement.type =
          new FunctionTypeImpl.forTypedef(functionTypeAliasElement);
      functionTypeAliasElement.typeParameters = currentTypeParameters;
      buildDocumentation(
          functionTypeAliasElement, serializedTypedef.documentationComment);
      unitHolder.addTypeAlias(functionTypeAliasElement);
    } finally {
      currentTypeParameters = <TypeParameterElement>[];
    }
  }

  /**
   * Resynthesize a [TypeParameterElement], handling all parts of its except
   * its bound.
   *
   * The bound is deferred until later since it may refer to other type
   * parameters that have not been resynthesized yet.  To handle the bound,
   * call [finishTypeParameter].
   */
  TypeParameterElement buildTypeParameter(
      UnlinkedTypeParam serializedTypeParameter) {
    TypeParameterElementImpl typeParameterElement =
        new TypeParameterElementImpl(
            serializedTypeParameter.name, serializedTypeParameter.nameOffset);
    typeParameterElement.type = new TypeParameterTypeImpl(typeParameterElement);
    return typeParameterElement;
  }

  /**
   * Resynthesize a [TopLevelVariableElement] or [FieldElement].
   */
  void buildVariable(UnlinkedVariable serializedVariable,
      [ElementHolder holder]) {
    if (holder == null) {
      TopLevelVariableElementImpl element = new TopLevelVariableElementImpl(
          serializedVariable.name, serializedVariable.nameOffset);
      buildVariableCommonParts(element, serializedVariable);
      unitHolder.addTopLevelVariable(element);
      buildImplicitAccessors(element, unitHolder);
    } else {
      FieldElementImpl element = new FieldElementImpl(
          serializedVariable.name, serializedVariable.nameOffset);
      buildVariableCommonParts(element, serializedVariable);
      element.static = serializedVariable.isStatic;
      holder.addField(element);
      buildImplicitAccessors(element, holder);
      fields[element.name] = element;
    }
  }

  /**
   * Handle the parts that are common to top level variables and fields.
   */
  void buildVariableCommonParts(PropertyInducingElementImpl element,
      UnlinkedVariable serializedVariable) {
    element.type = buildLinkedType(serializedVariable.inferredTypeSlot) ??
        buildType(serializedVariable.type);
    element.const3 = serializedVariable.isConst;
    element.final2 = serializedVariable.isFinal;
    element.hasImplicitType = serializedVariable.type == null;
    element.propagatedType =
        buildLinkedType(serializedVariable.propagatedTypeSlot);
    buildDocumentation(element, serializedVariable.documentationComment);
  }

  /**
   * Finish creating a [TypeParameterElement] by deserializing its bound.
   */
  void finishTypeParameter(UnlinkedTypeParam serializedTypeParameter,
      TypeParameterElementImpl typeParameterElement) {
    if (serializedTypeParameter.bound != null) {
      typeParameterElement.bound = buildType(serializedTypeParameter.bound);
    }
  }

  /**
   * Build an [ElementLocationImpl] for the entity in the given [unit] of the
   * given [dependency], having the given [name].
   */
  ElementLocationImpl getReferencedLocation(
      LinkedDependency dependency, int unit, String name) {
    Source referencedLibrarySource = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, dependency.uri);
    String referencedLibraryUri = referencedLibrarySource.uri.toString();
    // TODO(paulberry): consider changing Location format so that this is
    // not necessary (2nd string in location should just be the unit
    // number).
    String partUri;
    if (unit != 0) {
      UnlinkedUnit referencedLibraryDefiningUnit =
          summaryResynthesizer._getUnlinkedSummaryOrThrow(referencedLibraryUri);
      String uri =
          referencedLibraryDefiningUnit.publicNamespace.parts[unit - 1];
      Source partSource = summaryResynthesizer.sourceFactory
          .resolveUri(referencedLibrarySource, uri);
      partUri = partSource.uri.toString();
    } else {
      partUri = referencedLibraryUri;
    }
    return new ElementLocationImpl.con3(
        <String>[referencedLibraryUri, partUri, name]);
  }

  /**
   * Populate a [CompilationUnitElement] by deserializing all the elements
   * contained in it.
   */
  void populateUnit(CompilationUnitElementImpl unit, int unitNum) {
    linkedUnit = linkedLibrary.units[unitNum];
    unlinkedUnit = unlinkedUnits[unitNum];
    linkedTypeMap = <int, EntityRef>{};
    for (EntityRef t in linkedUnit.types) {
      linkedTypeMap[t.slot] = t;
    }
    unitHolder = new ElementHolder();
    unlinkedUnit.classes.forEach(buildClass);
    unlinkedUnit.enums.forEach(buildEnum);
    unlinkedUnit.executables.forEach(buildExecutable);
    unlinkedUnit.typedefs.forEach(buildTypedef);
    unlinkedUnit.variables.forEach(buildVariable);
    String absoluteUri = unit.source.uri.toString();
    unit.accessors = unitHolder.accessors;
    unit.enums = unitHolder.enums;
    unit.functions = unitHolder.functions;
    List<FunctionTypeAliasElement> typeAliases = unitHolder.typeAliases;
    for (FunctionTypeAliasElementImpl typeAlias in typeAliases) {
      if (typeAlias.isSynthetic) {
        typeAlias.enclosingElement = unit;
      }
    }
    unit.typeAliases = typeAliases.where((e) => !e.isSynthetic).toList();
    unit.types = unitHolder.types;
    unit.topLevelVariables = unitHolder.topLevelVariables;
    Map<String, Element> elementMap = <String, Element>{};
    for (ClassElement cls in unit.types) {
      elementMap[cls.name] = cls;
    }
    for (ClassElement cls in unit.enums) {
      elementMap[cls.name] = cls;
    }
    for (FunctionTypeAliasElement typeAlias in unit.functionTypeAliases) {
      elementMap[typeAlias.name] = typeAlias;
    }
    for (FunctionElement function in unit.functions) {
      elementMap[function.name] = function;
    }
    for (PropertyAccessorElementImpl accessor in unit.accessors) {
      elementMap[accessor.identifier] = accessor;
    }
    resummarizedElements[absoluteUri] = elementMap;
    unitHolder = null;
    linkedUnit = null;
    unlinkedUnit = null;
    linkedTypeMap = null;
  }
}
