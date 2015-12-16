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
 * Callback used by [SummaryResynthesizer] to obtain the summary for a given
 * URI.
 */
typedef PrelinkedLibrary GetSummaryCallback(String uri);

/**
 * Specialization of [FunctionTypeImpl] used for function types resynthesized
 * from summaries.
 */
class ResynthesizedFunctionTypeImpl extends FunctionTypeImpl
    with ResynthesizedType {
  final SummaryResynthesizer summaryResynthesizer;

  ResynthesizedFunctionTypeImpl(
      FunctionTypeAliasElement element, String name, this.summaryResynthesizer)
      : super.elementWithName(element, name);

  int get _numTypeParameters {
    FunctionTypeAliasElement element = this.element;
    return element.typeParameters.length;
  }
}

/**
 * Specialization of [InterfaceTypeImpl] used for interface types resynthesized
 * from summaries.
 */
class ResynthesizedInterfaceTypeImpl extends InterfaceTypeImpl
    with ResynthesizedType {
  final SummaryResynthesizer summaryResynthesizer;

  ResynthesizedInterfaceTypeImpl(
      ClassElement element, String name, this.summaryResynthesizer)
      : super.elementWithName(element, name);

  int get _numTypeParameters => element.typeParameters.length;
}

/**
 * Common code for types resynthesized from summaries.  This code takes care of
 * filling in the appropriate number of copies of `dynamic` when it is queried
 * for type parameters on a bare type reference (i.e. it converts `List` to
 * `List<dynamic>`).
 */
abstract class ResynthesizedType implements DartType {
  /**
   * The type arguments, if known.  Otherwise `null`.
   */
  List<DartType> _typeArguments;

  SummaryResynthesizer get summaryResynthesizer;

  List<DartType> get typeArguments {
    if (_typeArguments == null) {
      // Default to replicating "dynamic" as many times as the class element
      // requires.
      _typeArguments = new List<DartType>.filled(
          _numTypeParameters, summaryResynthesizer.typeProvider.dynamicType);
    }
    return _typeArguments;
  }

  int get _numTypeParameters;
}

/**
 * Implementation of [ElementResynthesizer] used when resynthesizing an element
 * model from summaries.
 */
class SummaryResynthesizer extends ElementResynthesizer {
  /**
   * Callback used to obtain the summary for a given URI.
   */
  final GetSummaryCallback getSummary;

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
   *
   * TODO(paulberry): will this create a chicken-and-egg problem when trying to
   * resynthesize the core library from summaries?
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

  SummaryResynthesizer(
      AnalysisContext context, this.getSummary, this.sourceFactory)
      : super(context),
        typeProvider = context.typeProvider;

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
      PrelinkedLibrary serializedLibrary = getSummary(uri);
      _LibraryResynthesizer libraryResynthesizer =
          new _LibraryResynthesizer(this, serializedLibrary, _getSource(uri));
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
   * The library to be resynthesized.
   */
  final PrelinkedLibrary prelinkedLibrary;

  /**
   * [Source] object for the library to be resynthesized.
   */
  final Source librarySource;

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
   * Map of top level elements that have been resynthesized so far.  The first
   * key is the URI of the compilation unit; the second is the name of the top
   * level element.
   */
  final Map<String, Map<String, Element>> resummarizedElements =
      <String, Map<String, Element>>{};

  /**
   * Type parameters for the class or typedef currently being resynthesized.
   *
   * TODO(paulberry): extend this to do the right thing for generic methods.
   */
  List<TypeParameterElement> currentTypeParameters;

  _LibraryResynthesizer(this.summaryResynthesizer,
      PrelinkedLibrary serializedLibrary, this.librarySource)
      : prelinkedLibrary = serializedLibrary;

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
      ClassElementImpl classElement =
          new ClassElementImpl(serializedClass.name, -1);
      classElement.mixinApplication = serializedClass.isMixinApplication;
      InterfaceTypeImpl correspondingType = new InterfaceTypeImpl(classElement);
      if (serializedClass.supertype != null) {
        classElement.supertype = buildType(serializedClass.supertype);
      } else {
        // TODO(paulberry): don't make Object point to itself.
        classElement.supertype = summaryResynthesizer.typeProvider.objectType;
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
            buildConstructor(serializedExecutable, memberHolder);
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
          constructor.type = new FunctionTypeImpl(constructor);
          memberHolder.addConstructor(constructor);
        }
        classElement.constructors = memberHolder.constructors;
      }
      classElement.accessors = memberHolder.accessors;
      classElement.fields = memberHolder.fields;
      classElement.methods = memberHolder.methods;
      correspondingType.typeArguments =
          currentTypeParameters.map((param) => param.type).toList();
      classElement.type = correspondingType;
      unitHolder.addType(classElement);
    } finally {
      currentTypeParameters = null;
    }
  }

  /**
   * Resynthesize a [NamespaceCombinator].
   */
  NamespaceCombinator buildCombinator(UnlinkedCombinator serializedCombinator) {
    if (serializedCombinator.shows.isNotEmpty) {
      ShowElementCombinatorImpl combinator = new ShowElementCombinatorImpl();
      combinator.shownNames = serializedCombinator.shows
          .map((UnlinkedCombinatorName n) => n.name)
          .toList();
      return combinator;
    } else {
      HideElementCombinatorImpl combinator = new HideElementCombinatorImpl();
      combinator.hiddenNames = serializedCombinator.hides
          .map((UnlinkedCombinatorName n) => n.name)
          .toList();
      return combinator;
    }
  }

  /**
   * Resynthesize a [ConstructorElement] and place it in the given [holder].
   */
  void buildConstructor(
      UnlinkedExecutable serializedExecutable, ElementHolder holder) {
    assert(serializedExecutable.kind == UnlinkedExecutableKind.constructor);
    ConstructorElementImpl constructorElement =
        new ConstructorElementImpl(serializedExecutable.name, -1);
    buildExecutableCommonParts(constructorElement, serializedExecutable);
    constructorElement.factory = serializedExecutable.isFactory;
    constructorElement.const2 = serializedExecutable.isConst;
    holder.addConstructor(constructorElement);
  }

  /**
   * Resynthesize the [ClassElement] corresponding to an enum, along with the
   * associated fields and implicit accessors.
   */
  void buildEnum(UnlinkedEnum serializedEnum) {
    // TODO(paulberry): add offset support (for this element type and others)
    ClassElementImpl classElement =
        new ClassElementImpl(serializedEnum.name, -1);
    classElement.enum2 = true;
    InterfaceType enumType = new InterfaceTypeImpl(classElement);
    classElement.type = enumType;
    classElement.supertype = summaryResynthesizer.typeProvider.objectType;
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
      ConstFieldElementImpl valueField =
          new ConstFieldElementImpl(serializedEnumValue.name, -1);
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
    String name = serializedExecutable.name;
    if (name.endsWith('=') && name != '[]=') {
      name = name.substring(0, name.length - 1);
    }
    UnlinkedExecutableKind kind = serializedExecutable.kind;
    switch (kind) {
      case UnlinkedExecutableKind.functionOrMethod:
        if (isTopLevel) {
          FunctionElementImpl executableElement =
              new FunctionElementImpl(name, -1);
          buildExecutableCommonParts(executableElement, serializedExecutable);
          holder.addFunction(executableElement);
        } else {
          MethodElementImpl executableElement = new MethodElementImpl(name, -1);
          buildExecutableCommonParts(executableElement, serializedExecutable);
          executableElement.static = serializedExecutable.isStatic;
          holder.addMethod(executableElement);
        }
        break;
      case UnlinkedExecutableKind.getter:
      case UnlinkedExecutableKind.setter:
        PropertyAccessorElementImpl executableElement =
            new PropertyAccessorElementImpl(name, -1);
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
    executableElement.parameters =
        serializedExecutable.parameters.map(buildParameter).toList();
    if (serializedExecutable.returnType != null) {
      executableElement.returnType = buildType(serializedExecutable.returnType);
    } else {
      executableElement.returnType = VoidTypeImpl.instance;
    }
    executableElement.type = new FunctionTypeImpl(executableElement);
    executableElement.hasImplicitReturnType =
        serializedExecutable.hasImplicitReturnType;
  }

  /**
   * Resynthesize an [ExportElement],
   */
  ExportElement buildExport(UnlinkedExport serializedExport) {
    ExportElementImpl exportElement = new ExportElementImpl(0);
    String exportedLibraryUri = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, serializedExport.uri)
        .uri
        .toString();
    exportElement.exportedLibrary = new LibraryElementHandle(
        summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[exportedLibraryUri]));
    exportElement.uri = serializedExport.uri;
    exportElement.combinators =
        serializedExport.combinators.map(buildCombinator).toList();
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
        new PropertyAccessorElementImpl(name, -1);
    getter.getter = true;
    getter.static = element.isStatic;
    getter.synthetic = true;
    getter.returnType = type;
    getter.type = new FunctionTypeImpl(getter);
    getter.variable = element;
    holder.addAccessor(getter);
    element.getter = getter;
    if (!(element.isConst || element.isFinal)) {
      PropertyAccessorElementImpl setter =
          new PropertyAccessorElementImpl(name, -1);
      setter.setter = true;
      setter.static = element.isStatic;
      setter.synthetic = true;
      setter.parameters = <ParameterElement>[
        new ParameterElementImpl('_$name', -1)
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
    if (holder.getField(name) == null) {
      FieldElementImpl field = new FieldElementImpl(name, -1);
      field.synthetic = true;
      field.final2 = kind == UnlinkedExecutableKind.getter;
      field.type = type;
      holder.addField(field);
      return field;
    } else {
      // TODO(paulberry): if adding a setter where there was previously
      // only a getter, remove "final" modifier.
      // TODO(paulberry): what if the getter and setter have a type mismatch?
      throw new UnimplementedError();
    }
  }

  /**
   * Build the implicit top level variable associated with a getter or setter,
   * and place it in [holder].
   */
  PropertyInducingElementImpl buildImplicitTopLevelVariable(
      String name, UnlinkedExecutableKind kind, ElementHolder holder) {
    if (holder.getTopLevelVariable(name) == null) {
      TopLevelVariableElementImpl variable =
          new TopLevelVariableElementImpl(name, -1);
      variable.synthetic = true;
      variable.final2 = kind == UnlinkedExecutableKind.getter;
      holder.addTopLevelVariable(variable);
      return variable;
    } else {
      // TODO(paulberry): if adding a setter where there was previously
      // only a getter, remove "final" modifier.
      // TODO(paulberry): what if the getter and setter have a type mismatch?
      throw new UnimplementedError();
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
    }
    if (serializedImport.prefixReference != 0) {
      UnlinkedReference serializedPrefix = prelinkedLibrary.units[0]
          .unlinked
          .references[serializedImport.prefixReference];
      importElement.prefix = new PrefixElementImpl(serializedPrefix.name, -1);
    }
    importElement.combinators =
        serializedImport.combinators.map(buildCombinator).toList();
    return importElement;
  }

  /**
   * Main entry point.  Resynthesize the [LibraryElement] and return it.
   */
  LibraryElement buildLibrary() {
    // TODO(paulberry): is it ok to pass -1 for offset and nameLength?
    LibraryElementImpl libraryElement = new LibraryElementImpl(
        summaryResynthesizer.context,
        prelinkedLibrary.units[0].unlinked.libraryName,
        -1,
        -1);
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl(librarySource.shortName);
    libraryElement.definingCompilationUnit = definingCompilationUnit;
    definingCompilationUnit.source = librarySource;
    definingCompilationUnit.librarySource = librarySource;
    List<CompilationUnitElement> parts = <CompilationUnitElement>[];
    UnlinkedUnit unlinkedDefiningUnit = prelinkedLibrary.units[0].unlinked;
    assert(
        unlinkedDefiningUnit.parts.length + 1 == prelinkedLibrary.units.length);
    for (int i = 1; i < prelinkedLibrary.units.length; i++) {
      CompilationUnitElementImpl part = buildPart(
          unlinkedDefiningUnit.parts[i - 1].uri,
          prelinkedLibrary.units[i].unlinked);
      parts.add(part);
    }
    libraryElement.parts = parts;
    List<ImportElement> imports = <ImportElement>[];
    for (int i = 0; i < unlinkedDefiningUnit.imports.length; i++) {
      imports.add(buildImport(unlinkedDefiningUnit.imports[i],
          prelinkedLibrary.importDependencies[i]));
    }
    libraryElement.imports = imports;
    libraryElement.exports =
        unlinkedDefiningUnit.exports.map(buildExport).toList();
    populateUnit(definingCompilationUnit, 0);
    for (int i = 0; i < parts.length; i++) {
      populateUnit(parts[i], i + 1);
    }
    return libraryElement;
  }

  /**
   * Resynthesize a [ParameterElement].
   */
  ParameterElement buildParameter(UnlinkedParam serializedParameter) {
    ParameterElementImpl parameterElement =
        new ParameterElementImpl(serializedParameter.name, -1);
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
      parameterElement.type = new FunctionTypeImpl(parameterTypeElement);
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
      String uri, UnlinkedUnit serializedPart) {
    Source unitSource =
        summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
    CompilationUnitElementImpl partUnit =
        new CompilationUnitElementImpl(unitSource.shortName);
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
          currentTypeParameters.length - type.paramReference].type;
    } else {
      // TODO(paulberry): handle references to things other than classes (note:
      // this should only occur in the case of erroneous code).
      // TODO(paulberry): test reference to something inside a part.
      // TODO(paulberry): test reference to something inside a part of the
      // current lib.
      UnlinkedReference reference =
          prelinkedUnit.unlinked.references[type.reference];
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
        PrelinkedLibrary referencedLibrary =
            summaryResynthesizer.getSummary(referencedLibraryUri);
        // TODO(paulberry): consider changing Location format so that this is
        // not necessary (2nd string in location should just be the unit
        // number).
        if (referenceResolution.unit != 0) {
          String uri = referencedLibrary.units[0].unlinked.parts[0].uri;
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
          String uri = prelinkedLibrary.units[0].unlinked.parts[
              referenceResolution.unit - 1].uri;
          Source partSource =
              summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
          partUri = partSource.uri.toString();
        } else {
          partUri = referencedLibraryUri;
        }
      }
      ResynthesizedType resynthesizedType;
      ElementLocationImpl location = new ElementLocationImpl.con3(
          <String>[referencedLibraryUri, partUri, reference.name]);
      switch (referenceResolution.kind) {
        case PrelinkedReferenceKind.classOrEnum:
          resynthesizedType = new ResynthesizedInterfaceTypeImpl(
              new ClassElementHandle(summaryResynthesizer, location),
              reference.name,
              summaryResynthesizer);
          break;
        case PrelinkedReferenceKind.typedef:
          resynthesizedType = new ResynthesizedFunctionTypeImpl(
              new FunctionTypeAliasElementHandle(
                  summaryResynthesizer, location),
              reference.name,
              summaryResynthesizer);
          break;
        default:
          // TODO(paulberry): figure out how to handle this case (which should
          // only occur in the event of erroneous code).
          throw new UnimplementedError();
      }
      if (type.typeArguments.isNotEmpty) {
        resynthesizedType._typeArguments =
            type.typeArguments.map(buildType).toList();
      }
      return resynthesizedType;
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
          new FunctionTypeAliasElementImpl(serializedTypedef.name, -1);
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
      unitHolder.addTypeAlias(functionTypeAliasElement);
    } finally {
      currentTypeParameters = null;
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
        new TypeParameterElementImpl(serializedTypeParameter.name, -1);
    typeParameterElement.type = new TypeParameterTypeImpl(typeParameterElement);
    return typeParameterElement;
  }

  /**
   * Resynthesize a [TopLevelVariableElement] or [FieldElement].
   */
  void buildVariable(UnlinkedVariable serializedVariable,
      [ElementHolder holder]) {
    if (holder == null) {
      TopLevelVariableElementImpl element =
          new TopLevelVariableElementImpl(serializedVariable.name, -1);
      buildVariableCommonParts(element, serializedVariable);
      unitHolder.addTopLevelVariable(element);
      buildImplicitAccessors(element, unitHolder);
    } else {
      FieldElementImpl element =
          new FieldElementImpl(serializedVariable.name, -1);
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
   */
  void populateUnit(CompilationUnitElementImpl unit, int unitNum) {
    prelinkedUnit = prelinkedLibrary.units[unitNum];
    unitHolder = new ElementHolder();
    UnlinkedUnit unlinkedUnit = prelinkedUnit.unlinked;
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
    resummarizedElements[absoluteUri] = elementMap;
    unitHolder = null;
    prelinkedUnit = null;
  }
}
