// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library summary_resynthesizer;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/element_handle.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Callback used by [SummaryResynthesizer] to obtain the prelinked summary for
 * a given URI.
 */
typedef PrelinkedLibrary GetPrelinkedSummaryCallback(String uri);

/**
 * Callback used by [SummaryResynthesizer] to obtain the unlinked summary for a
 * given URI.
 */
typedef UnlinkedUnit GetUnlinkedSummaryCallback(String uri);

/**
 * Implementation of [ElementResynthesizer] used when resynthesizing an element
 * model from summaries.
 */
class SummaryResynthesizer extends ElementResynthesizer {
  /**
   * Callback used to obtain the prelinked summary for a given URI.
   */
  final GetPrelinkedSummaryCallback getPrelinkedSummary;

  /**
   * Callback used to obtain the unlinked summary for a given URI.
   */
  final GetUnlinkedSummaryCallback getUnlinkedSummary;

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

  SummaryResynthesizer(AnalysisContext context, this.typeProvider,
      this.getPrelinkedSummary, this.getUnlinkedSummary, this.sourceFactory)
      : super(context);

  /**
   * Number of libraries that have been resynthesized so far.
   */
  int get resynthesisCount => _resynthesizedLibraries.length;

  @override
  Element getElement(ElementLocation location) {
    if (location.components.length == 1) {
      return getLibraryElement(location.components[0]);
    } else if (location.components.length == 3) {
      String uri = location.components[0];
      Map<String, Map<String, Element>> libraryMap =
          _resynthesizedElements[uri];
      if (libraryMap == null) {
        getLibraryElement(uri);
        libraryMap = _resynthesizedElements[uri];
        assert(libraryMap != null);
      }
      Map<String, Element> compilationUnitElements =
          libraryMap[location.components[1]];
      if (compilationUnitElements != null) {
        Element element = compilationUnitElements[location.components[2]];
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
    return _resynthesizedLibraries.putIfAbsent(uri, () {
      PrelinkedLibrary serializedLibrary = getPrelinkedSummary(uri);
      List<UnlinkedUnit> serializedUnits = <UnlinkedUnit>[
        getUnlinkedSummary(uri)
      ];
      Source librarySource = _getSource(uri);
      for (String part in serializedUnits[0].publicNamespace.parts) {
        Source partSource = sourceFactory.resolveUri(librarySource, part);
        String partAbsUri = partSource.uri.toString();
        serializedUnits.add(getUnlinkedSummary(partAbsUri));
      }
      _LibraryResynthesizer libraryResynthesizer = new _LibraryResynthesizer(
          this, serializedLibrary, serializedUnits, librarySource);
      LibraryElement library = libraryResynthesizer.buildLibrary();
      _resynthesizedElements[uri] = libraryResynthesizer.resummarizedElements;
      return library;
    });
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(uri, () => sourceFactory.forUri(uri));
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
   * Prelinked summary of the library to be resynthesized.
   */
  final PrelinkedLibrary prelinkedLibrary;

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
   * The [PrelinkedUnit] from which elements are currently being resynthesized.
   */
  PrelinkedUnit prelinkedUnit;

  /**
   * The [UnlinkedUnit] from which elements are currently being resynthesized.
   */
  UnlinkedUnit unlinkedUnit;

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

  _LibraryResynthesizer(this.summaryResynthesizer, this.prelinkedLibrary,
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
      for (UnlinkedVariable serializedVariable in serializedClass.fields) {
        buildVariable(serializedVariable, memberHolder);
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
    if (serializedExecutable.returnType != null) {
      executableElement.returnType = buildType(serializedExecutable.returnType);
    } else if (serializedExecutable.kind ==
        UnlinkedExecutableKind.constructor) {
      // Return type was set by the caller.
    } else {
      executableElement.returnType = VoidTypeImpl.instance;
    }
    executableElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
        executableElement, null, oldTypeArguments, false);
    executableElement.hasImplicitReturnType =
        serializedExecutable.hasImplicitReturnType;
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
        .resolveUri(
            librarySource, prelinkedLibrary.dependencies[dependency].uri)
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
    }
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
    LibraryElementImpl libraryElement = new LibraryElementImpl(
        summaryResynthesizer.context,
        unlinkedUnits[0].libraryName,
        hasName ? unlinkedUnits[0].libraryNameOffset : -1,
        unlinkedUnits[0].libraryNameLength);
    buildDocumentation(
        libraryElement, unlinkedUnits[0].libraryDocumentationComment);
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl(librarySource.shortName);
    libraryElement.definingCompilationUnit = definingCompilationUnit;
    definingCompilationUnit.source = librarySource;
    definingCompilationUnit.librarySource = librarySource;
    List<CompilationUnitElement> parts = <CompilationUnitElement>[];
    UnlinkedUnit unlinkedDefiningUnit = unlinkedUnits[0];
    assert(unlinkedDefiningUnit.publicNamespace.parts.length + 1 ==
        prelinkedLibrary.units.length);
    for (int i = 1; i < prelinkedLibrary.units.length; i++) {
      CompilationUnitElementImpl part = buildPart(
          unlinkedDefiningUnit.publicNamespace.parts[i - 1],
          unlinkedDefiningUnit.parts[i - 1],
          unlinkedUnits[i]);
      parts.add(part);
    }
    libraryElement.parts = parts;
    List<ImportElement> imports = <ImportElement>[];
    for (int i = 0; i < unlinkedDefiningUnit.imports.length; i++) {
      imports.add(buildImport(unlinkedDefiningUnit.imports[i],
          prelinkedLibrary.importDependencies[i]));
    }
    libraryElement.imports = imports;
    List<ExportElement> exports = <ExportElement>[];
    assert(unlinkedDefiningUnit.exports.length ==
        unlinkedDefiningUnit.publicNamespace.exports.length);
    for (int i = 0; i < unlinkedDefiningUnit.exports.length; i++) {
      exports.add(buildExport(unlinkedDefiningUnit.publicNamespace.exports[i],
          unlinkedDefiningUnit.exports[i]));
    }
    libraryElement.exports = exports;
    FunctionElement entryPoint = populateUnit(definingCompilationUnit, 0);
    for (int i = 0; i < parts.length; i++) {
      FunctionElement unitEntryPoint = populateUnit(parts[i], i + 1);
      if (entryPoint == null) {
        entryPoint = unitEntryPoint;
      }
    }
    // TODO(paulberry): also look for entry points in exports.
    libraryElement.entryPoint = entryPoint;
    if (isCoreLibrary) {
      ClassElement objectElement = libraryElement.getType('Object');
      assert(objectElement != null);
      for (ClassElementImpl classElement in delayedObjectSubclasses) {
        classElement.supertype = objectElement.type;
      }
    }
    // Compute public namespace.
    libraryElement.publicNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(libraryElement);
    // Done.
    return libraryElement;
  }

  /**
   * Resynthesize a [ParameterElement].
   */
  ParameterElement buildParameter(UnlinkedParam serializedParameter) {
    ParameterElementImpl parameterElement = new ParameterElementImpl(
        serializedParameter.name, serializedParameter.nameOffset);
    if (serializedParameter.isFunctionTyped) {
      FunctionElementImpl parameterTypeElement =
          new FunctionElementImpl('', -1);
      parameterTypeElement.synthetic = true;
      parameterElement.parameters =
          serializedParameter.parameters.map(buildParameter).toList();
      parameterTypeElement.enclosingElement = parameterElement;
      parameterTypeElement.shareParameters(parameterElement.parameters);
      if (serializedParameter.type != null) {
        parameterTypeElement.returnType = buildType(serializedParameter.type);
      } else {
        parameterTypeElement.returnType = VoidTypeImpl.instance;
      }
      parameterElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
          parameterTypeElement, null, currentTypeArguments, false);
    } else {
      parameterElement.type = buildType(serializedParameter.type);
      parameterElement.hasImplicitType = serializedParameter.hasImplicitType;
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
   * Build a [DartType] object based on an [UnlinkedTypeRef].  This [DartType]
   * may refer to elements in other libraries than the library being
   * deserialized, so handles are used to avoid having to deserialize other
   * libraries in the process.
   */
  DartType buildType(UnlinkedTypeRef type) {
    if (type.paramReference != 0) {
      // TODO(paulberry): make this work for generic methods.
      return currentTypeParameters[
              currentTypeParameters.length - type.paramReference]
          .type;
    } else {
      // TODO(paulberry): handle references to things other than classes (note:
      // this should only occur in the case of erroneous code).
      // TODO(paulberry): test reference to something inside a part.
      // TODO(paulberry): test reference to something inside a part of the
      // current lib.
      UnlinkedReference reference = unlinkedUnit.references[type.reference];
      PrelinkedReference referenceResolution =
          prelinkedUnit.references[type.reference];
      String referencedLibraryUri;
      String partUri;
      if (referenceResolution.dependency != 0) {
        PrelinkedDependency dependency =
            prelinkedLibrary.dependencies[referenceResolution.dependency];
        Source referencedLibrarySource = summaryResynthesizer.sourceFactory
            .resolveUri(librarySource, dependency.uri);
        referencedLibraryUri = referencedLibrarySource.uri.toString();
        // TODO(paulberry): consider changing Location format so that this is
        // not necessary (2nd string in location should just be the unit
        // number).
        if (referenceResolution.unit != 0) {
          UnlinkedUnit referencedLibraryDefiningUnit =
              summaryResynthesizer.getUnlinkedSummary(referencedLibraryUri);
          String uri = referencedLibraryDefiningUnit.publicNamespace.parts[
              referenceResolution.unit - 1];
          Source partSource = summaryResynthesizer.sourceFactory
              .resolveUri(referencedLibrarySource, uri);
          partUri = partSource.uri.toString();
        } else {
          partUri = referencedLibraryUri;
        }
      } else if (referenceResolution.kind ==
          PrelinkedReferenceKind.unresolved) {
        return summaryResynthesizer.typeProvider.undefinedType;
      } else if (reference.name.isEmpty) {
        return summaryResynthesizer.typeProvider.dynamicType;
      } else {
        referencedLibraryUri = librarySource.uri.toString();
        if (referenceResolution.unit != 0) {
          String uri = unlinkedUnits[0].publicNamespace.parts[
              referenceResolution.unit - 1];
          Source partSource =
              summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
          partUri = partSource.uri.toString();
        } else {
          partUri = referencedLibraryUri;
        }
      }
      ElementLocationImpl location = new ElementLocationImpl.con3(
          <String>[referencedLibraryUri, partUri, reference.name]);
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
        case PrelinkedReferenceKind.classOrEnum:
          return new InterfaceTypeImpl.elementWithNameAndArgs(
              new ClassElementHandle(summaryResynthesizer, location),
              reference.name,
              typeArguments);
        case PrelinkedReferenceKind.typedef:
          return new FunctionTypeImpl.elementWithNameAndArgs(
              new FunctionTypeAliasElementHandle(
                  summaryResynthesizer, location),
              reference.name,
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
      if (serializedTypedef.returnType != null) {
        functionTypeAliasElement.returnType =
            buildType(serializedTypedef.returnType);
      } else {
        functionTypeAliasElement.returnType = VoidTypeImpl.instance;
      }
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
    }
  }

  /**
   * Handle the parts that are common to top level variables and fields.
   */
  void buildVariableCommonParts(PropertyInducingElementImpl element,
      UnlinkedVariable serializedVariable) {
    element.type = buildType(serializedVariable.type);
    element.const3 = serializedVariable.isConst;
    element.hasImplicitType = serializedVariable.hasImplicitType;
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
   * Populate a [CompilationUnitElement] by deserializing all the elements
   * contained in it.
   *
   * If the compilation unit has an entry point, it is returned.
   */
  FunctionElement populateUnit(CompilationUnitElementImpl unit, int unitNum) {
    prelinkedUnit = prelinkedLibrary.units[unitNum];
    unlinkedUnit = unlinkedUnits[unitNum];
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
    FunctionElement entryPoint = null;
    for (FunctionElement function in unit.functions) {
      if (function.isEntryPoint) {
        entryPoint = function;
        break;
      }
    }
    resummarizedElements[absoluteUri] = elementMap;
    unitHolder = null;
    prelinkedUnit = null;
    unlinkedUnit = null;
    return entryPoint;
  }
}
