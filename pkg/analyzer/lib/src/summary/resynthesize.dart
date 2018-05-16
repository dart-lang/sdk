// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library summary_resynthesizer;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/expr_builder.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';

/**
 * Expando for marking types with implicit type arguments, which are the same as
 * type parameter bounds (in strong mode), or `dynamic` (in spec mode).
 *
 * If a type is associated with a non-null value in this expando, then it has
 * implicit type arguments.
 */
final _typesWithImplicitTypeArguments = new Expando();

/// An instance of [LibraryResynthesizer] is responsible for resynthesizing the
/// elements in a single library from that library's summary.
abstract class LibraryResynthesizer {
  /// Builds the export namespace for the library by aggregating together its
  /// public namespace and export names.
  Namespace buildExportNamespace();

  /// Builds the public namespace for the library.
  Namespace buildPublicNamespace();
}

/// [LibraryResynthesizerContextMixin] contains methods useful for implementing
/// the [LibraryResynthesizerContext] interface.
abstract class LibraryResynthesizerContextMixin
    implements LibraryResynthesizerContext {
  /// Gets the associated [LibraryResynthesizer].
  LibraryResynthesizer get resynthesizer;

  @override
  Namespace buildExportNamespace() => resynthesizer.buildExportNamespace();

  @override
  Namespace buildPublicNamespace() => resynthesizer.buildPublicNamespace();
}

/// [LibraryResynthesizerMixin] contains methods useful for implementing the
/// [LibraryResynthesizer] interface.
abstract class LibraryResynthesizerMixin implements LibraryResynthesizer {
  /// Gets the library element being resynthesized.
  LibraryElement get library;

  /// Gets the list of export names created during summary linking.
  List<LinkedExportName> get linkedExportNames;

  /// Builds or retrieves an [Element] for the entity referred to by the given
  /// [exportName].
  Element buildExportName(LinkedExportName exportName);

  @override
  Namespace buildExportNamespace() {
    Namespace publicNamespace = library.publicNamespace;
    List<LinkedExportName> exportNames = linkedExportNames;
    Map<String, Element> definedNames = new HashMap<String, Element>();
    // Start by populating all the public names from [publicNamespace].
    publicNamespace.definedNames.forEach((String name, Element element) {
      definedNames[name] = element;
    });
    // Add all the names from [exportNames].
    for (LinkedExportName exportName in exportNames) {
      String name = exportName.name;
      if (!definedNames.containsKey(name)) {
        definedNames[name] = buildExportName(exportName);
      }
    }
    return new Namespace(definedNames);
  }

  @override
  Namespace buildPublicNamespace() =>
      new NamespaceBuilder().createPublicNamespaceForLibrary(library);
}

/// Data structure used during resynthesis to record all the information that is
/// known about how to resynthesize a single entry in [LinkedUnit.references]
/// (and its associated entry in [UnlinkedUnit.references], if it exists).
abstract class ReferenceInfo {
  /// The element referred to by this reference, or `null` if there is no
  /// associated element (e.g. because it is a reference to an undefined
  /// entity).
  Element get element;

  /// The enclosing [_ReferenceInfo], or `null` for top-level elements.
  ReferenceInfo get enclosing;

  /// Indicates whether the thing being referenced has at least one type
  /// parameter.
  bool get hasTypeParameters;

  /// The name of the entity referred to by this reference.
  String get name;

  /// If this reference refers to a non-generic type, the type it refers to.
  /// Otherwise `null`.
  DartType get type;
}

/**
 * Implementation of [ElementResynthesizer] used when resynthesizing an element
 * model from summaries.
 */
abstract class SummaryResynthesizer extends ElementResynthesizer {
  /**
   * Source factory used to convert URIs to [Source] objects.
   */
  final SourceFactory sourceFactory;

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  /**
   * The `dart:core` library for the context.
   */
  LibraryElementImpl _coreLibrary;

  /**
   * The `dart:async` library for the context.
   */
  LibraryElementImpl _asyncLibrary;

  /**
   * The [TypeProvider] used to obtain SDK types during resynthesis.
   */
  TypeProvider _typeProvider;

  /**
   * Indicates whether the summary should be resynthesized assuming strong mode
   * semantics.
   */
  final bool strongMode;

  /**
   * Map of compilation units resynthesized from summaries.  The two map keys
   * are the first two elements of the element's location (the library URI and
   * the compilation unit URI).
   */
  final Map<String, Map<String, CompilationUnitElementImpl>>
      _resynthesizedUnits = <String, Map<String, CompilationUnitElementImpl>>{};

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
      AnalysisContext context, this.sourceFactory, this.strongMode)
      : super(context) {
    _buildTypeProvider();
  }

  /**
   * Number of libraries that have been resynthesized so far.
   */
  int get resynthesisCount => _resynthesizedLibraries.length;

  /**
   * The [TypeProvider] used to obtain SDK types during resynthesis.
   */
  TypeProvider get typeProvider => _typeProvider;

  /**
   * The client installed this resynthesizer into the context, and set its
   * type provider, so it is not safe to access type provider to create
   * additional types.
   */
  void finishCoreAsyncLibraries() {
    _coreLibrary.createLoadLibraryFunction(_typeProvider);
    _asyncLibrary.createLoadLibraryFunction(_typeProvider);
  }

  @override
  Element getElement(ElementLocation location) {
    List<String> components = location.components;
    String libraryUri = components[0];
    // Resynthesize locally.
    if (components.length == 1) {
      return getLibraryElement(libraryUri);
    } else if (components.length == 2) {
      LibraryElement libraryElement = getLibraryElement(libraryUri);
      // Try to find the unit element.
      {
        Map<String, CompilationUnitElement> libraryMap =
            _resynthesizedUnits[libraryUri];
        assert(libraryMap != null);
        String unitUri = components[1];
        CompilationUnitElement unitElement = libraryMap[unitUri];
        if (unitElement != null) {
          return unitElement;
        }
      }
      // Try to find the prefix element.
      {
        String name = components[1];
        for (PrefixElement prefix in libraryElement.prefixes) {
          if (prefix.name == name) {
            return prefix;
          }
        }
      }
      // Fail.
      throw new Exception('The element not found in summary: $location');
    } else if (components.length == 3 || components.length == 4) {
      String unitUri = components[1];
      // Prepare elements-in-units in the library.
      Map<String, Map<String, Element>> unitsInLibrary =
          _resynthesizedElements[libraryUri];
      if (unitsInLibrary == null) {
        unitsInLibrary = new HashMap<String, Map<String, Element>>();
        _resynthesizedElements[libraryUri] = unitsInLibrary;
      }
      // Prepare elements in the unit.
      Map<String, Element> elementsInUnit = unitsInLibrary[unitUri];
      if (elementsInUnit == null) {
        // Prepare the CompilationUnitElementImpl.
        Map<String, CompilationUnitElementImpl> libraryMap =
            _resynthesizedUnits[libraryUri];
        if (libraryMap == null) {
          getLibraryElement(libraryUri);
          libraryMap = _resynthesizedUnits[libraryUri];
          assert(libraryMap != null);
        }
        CompilationUnitElementImpl unitElement = libraryMap[unitUri];
        // Fill elements in the unit map.
        if (unitElement != null) {
          elementsInUnit = new HashMap<String, Element>();
          void putElement(Element e) {
            String id =
                e is PropertyAccessorElementImpl ? e.identifier : e.name;
            elementsInUnit[id] = e;
          }

          unitElement.accessors.forEach(putElement);
          unitElement.enums.forEach(putElement);
          unitElement.functions.forEach(putElement);
          unitElement.functionTypeAliases.forEach(putElement);
          unitElement.topLevelVariables.forEach(putElement);
          unitElement.types.forEach(putElement);
          unitsInLibrary[unitUri] = elementsInUnit;
        }
      }
      // Get the element.
      Element element = elementsInUnit[components[2]];
      if (element != null && components.length == 4) {
        String name = components[3];
        Element parentElement = element;
        if (parentElement is ClassElement) {
          if (name.endsWith('?')) {
            element =
                parentElement.getGetter(name.substring(0, name.length - 1));
          } else if (name.endsWith('=')) {
            element =
                parentElement.getSetter(name.substring(0, name.length - 1));
          } else if (name.isEmpty) {
            element = parentElement.unnamedConstructor;
          } else {
            element = parentElement.getField(name) ??
                parentElement.getMethod(name) ??
                parentElement.getNamedConstructor(name);
          }
        } else {
          // The only elements that are currently retrieved using 4-component
          // locations are class members.
          throw new StateError(
              '4-element locations not supported for ${element.runtimeType}');
        }
      }
      if (element == null) {
        throw new Exception('Element not found in summary: $location');
      }
      return element;
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
      LinkedLibrary serializedLibrary = getLinkedSummary(uri);
      Source librarySource = _getSource(uri);
      if (serializedLibrary == null) {
        LibraryElementImpl libraryElement =
            new LibraryElementImpl(context, '', -1, 0);
        libraryElement.isSynthetic = true;
        CompilationUnitElementImpl unitElement =
            new CompilationUnitElementImpl(librarySource.shortName);
        libraryElement.definingCompilationUnit = unitElement;
        unitElement.source = librarySource;
        unitElement.librarySource = librarySource;
        libraryElement.createLoadLibraryFunction(typeProvider);
        libraryElement.publicNamespace = new Namespace({});
        libraryElement.exportNamespace = new Namespace({});
        return libraryElement;
      }
      UnlinkedUnit unlinkedSummary = getUnlinkedSummary(uri);
      if (unlinkedSummary == null) {
        throw new StateError('Unable to find unlinked summary: $uri');
      }
      List<UnlinkedUnit> serializedUnits = <UnlinkedUnit>[unlinkedSummary];
      for (String part in serializedUnits[0].publicNamespace.parts) {
        Source partSource = sourceFactory.resolveUri(librarySource, part);
        UnlinkedUnit partUnlinkedUnit;
        if (partSource != null) {
          String partAbsUri = partSource.uri.toString();
          partUnlinkedUnit = getUnlinkedSummary(partAbsUri);
        }
        serializedUnits.add(partUnlinkedUnit ??
            new UnlinkedUnitBuilder(codeRange: new CodeRangeBuilder()));
      }
      _LibraryResynthesizer libraryResynthesizer = new _LibraryResynthesizer(
          this, serializedLibrary, serializedUnits, librarySource);
      LibraryElement library = libraryResynthesizer.buildLibrary();
      _resynthesizedUnits[uri] = libraryResynthesizer.resynthesizedUnits;
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

  void _buildTypeProvider() {
    _coreLibrary = getLibraryElement('dart:core') as LibraryElementImpl;
    _asyncLibrary = getLibraryElement('dart:async') as LibraryElementImpl;
    SummaryTypeProvider summaryTypeProvider = new SummaryTypeProvider();
    summaryTypeProvider.initializeCore(_coreLibrary);
    summaryTypeProvider.initializeAsync(_asyncLibrary);
    _typeProvider = summaryTypeProvider;
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(uri, () => sourceFactory.forUri(uri));
  }
}

class SummaryResynthesizerContext implements ResynthesizerContext {
  final _UnitResynthesizer unitResynthesizer;

  SummaryResynthesizerContext(this.unitResynthesizer);

  @override
  bool get isStrongMode => unitResynthesizer.summaryResynthesizer.strongMode;

  @override
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedExpr uc) {
    return unitResynthesizer.buildAnnotation(context, uc);
  }

  @override
  Expression buildExpression(ElementImpl context, UnlinkedExpr uc) {
    return unitResynthesizer._buildConstExpression(context, uc);
  }

  @override
  UnitExplicitTopLevelAccessors buildTopLevelAccessors() {
    return unitResynthesizer.buildUnitExplicitTopLevelAccessors();
  }

  @override
  UnitExplicitTopLevelVariables buildTopLevelVariables() {
    return unitResynthesizer.buildUnitExplicitTopLevelVariables();
  }

  @override
  TopLevelInferenceError getTypeInferenceError(int slot) {
    return unitResynthesizer.getTypeInferenceError(slot);
  }

  @override
  bool inheritsCovariant(int slot) {
    return unitResynthesizer.parametersInheritingCovariant.contains(slot);
  }

  @override
  bool isInConstCycle(int slot) {
    return unitResynthesizer.constCycles.contains(slot);
  }

  @override
  ConstructorElement resolveConstructorRef(
      ElementImpl context, EntityRef entry) {
    return unitResynthesizer._getConstructorForEntry(context, entry);
  }

  @override
  DartType resolveLinkedType(ElementImpl context, int slot) {
    return unitResynthesizer.buildLinkedType(context, slot);
  }

  @override
  DartType resolveTypeRef(ElementImpl context, EntityRef type,
      {bool defaultVoid: false,
      bool instantiateToBoundsAllowed: true,
      bool declaredType: false}) {
    return unitResynthesizer.buildType(context, type,
        defaultVoid: defaultVoid,
        instantiateToBoundsAllowed: instantiateToBoundsAllowed,
        declaredType: declaredType);
  }
}

/// An instance of [_UnitResynthesizer] is responsible for resynthesizing the
/// elements in a single unit from that unit's summary.
abstract class UnitResynthesizer {
  /// Gets the [TypeProvider], which may be used to create core types.
  TypeProvider get typeProvider;

  /// Builds a [DartType] object based on a [EntityRef].  This [DartType]
  /// may refer to elements in other libraries than the library being
  /// deserialized, so handles may be used to avoid having to deserialize other
  /// libraries in the process.
  DartType buildType(ElementImpl context, EntityRef type);

  /// Builds a [DartType] object based on [ReferenceInfo], which should refer to
  /// a class, by filling in the type arguments as appropriate, and performing
  /// instantiate to bounds if necessary.
  DartType buildTypeForClassInfo(ReferenceInfo info, int numTypeArguments,
      DartType getTypeArgument(int i));

  /// Returns the defining type for a [ConstructorElement] by applying
  /// [typeArgumentRefs] to the given linked [info].  Returns [DynamicTypeImpl]
  /// if the [info] is unresolved.
  DartType createConstructorDefiningType(ElementImpl context,
      ReferenceInfo info, List<EntityRef> typeArgumentRefs);

  /// Determines if the given [type] has implicit type arguments.
  bool doesTypeHaveImplicitArguments(ParameterizedType type);

  /// Returns the [ConstructorElement] corresponding to the given linked [info],
  /// using the [classType] which has already been computed (e.g. by
  /// [createConstructorDefiningType]).  Both cases when [info] is a
  /// [ClassElement] and [ConstructorElement] are supported.
  ConstructorElement getConstructorForInfo(
      InterfaceType classType, ReferenceInfo info);

  /// Returns the [ReferenceInfo] with the given [index].
  ReferenceInfo getReferenceInfo(int index);
}

/// [UnitResynthesizerMixin] contains methods useful for implementing the
/// [UnitResynthesizer] interface.
abstract class UnitResynthesizerMixin implements UnitResynthesizer {
  @override
  DartType createConstructorDefiningType(ElementImpl context,
      ReferenceInfo info, List<EntityRef> typeArgumentRefs) {
    bool isClass = info.element is ClassElement;
    ReferenceInfo classInfo = isClass ? info : info.enclosing;
    if (classInfo == null) {
      return DynamicTypeImpl.instance;
    }
    List<DartType> typeArguments =
        typeArgumentRefs.map((t) => buildType(context, t)).toList();
    return buildTypeForClassInfo(classInfo, typeArguments.length, (i) {
      if (i < typeArguments.length) {
        return typeArguments[i];
      } else {
        return DynamicTypeImpl.instance;
      }
    });
  }

  @override
  ConstructorElement getConstructorForInfo(
      InterfaceType classType, ReferenceInfo info) {
    ConstructorElement element;
    Element infoElement = info.element;
    if (infoElement is ConstructorElement) {
      element = infoElement;
    } else if (infoElement is ClassElement) {
      element = infoElement.unnamedConstructor;
    }
    if (element != null && info.hasTypeParameters) {
      return new ConstructorMember(element, classType);
    }
    return element;
  }
}

/**
 * Local function element representing the initializer for a variable that has
 * been resynthesized from a summary.  The actual element won't be constructed
 * until it is requested.  But properties [context] and [enclosingElement] can
 * be used without creating the actual element.
 */
class _DeferredInitializerElement extends FunctionElementHandle {
  /**
   * The variable element containing this element.
   */
  @override
  final VariableElement enclosingElement;

  _DeferredInitializerElement(this.enclosingElement) : super(null, null);

  @override
  FunctionElement get actualElement => enclosingElement.initializer;

  @override
  AnalysisContext get context => enclosingElement.context;

  @override
  ElementLocation get location => actualElement.location;
}

/// Specialization of [LibraryResynthesizer] for resynthesis from linked
/// summaries.
class _LibraryResynthesizer extends LibraryResynthesizerMixin {
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
   * The URI of [librarySource].
   */
  Uri libraryUri;

  /**
   * The URI of [librarySource].
   */
  String libraryUriStr;

  /**
   * Indicates whether [librarySource] is the `dart:core` library.
   */
  bool isCoreLibrary;

  /**
   * The resynthesized library.
   */
  LibraryElementImpl library;

  /**
   * Map of compilation unit elements that have been resynthesized so far.  The
   * key is the URI of the compilation unit.
   */
  final Map<String, CompilationUnitElementImpl> resynthesizedUnits =
      <String, CompilationUnitElementImpl>{};

  _LibraryResynthesizer(this.summaryResynthesizer, this.linkedLibrary,
      this.unlinkedUnits, this.librarySource) {
    libraryUri = librarySource.uri;
    libraryUriStr = libraryUri.toString();
    isCoreLibrary = libraryUriStr == 'dart:core';
  }

  @override
  List<LinkedExportName> get linkedExportNames => linkedLibrary.exportNames;

  /**
   * Resynthesize a [NamespaceCombinator].
   */
  NamespaceCombinator buildCombinator(UnlinkedCombinator serializedCombinator) {
    if (serializedCombinator.shows.isNotEmpty) {
      return new ShowElementCombinatorImpl.forSerialized(serializedCombinator);
    } else {
      return new HideElementCombinatorImpl.forSerialized(serializedCombinator);
    }
  }

  @override
  ElementHandle buildExportName(LinkedExportName exportName) {
    String name = exportName.name;
    if (exportName.kind == ReferenceKind.topLevelPropertyAccessor &&
        !name.endsWith('=')) {
      name += '?';
    }
    ElementLocationImpl location = new ElementLocationImpl.con3(
        getReferencedLocationComponents(
            exportName.dependency, exportName.unit, name));
    switch (exportName.kind) {
      case ReferenceKind.classOrEnum:
        return new ClassElementHandle(summaryResynthesizer, location);
      case ReferenceKind.typedef:
        return new FunctionTypeAliasElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.genericFunctionTypedef:
        return new GenericTypeAliasElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.topLevelFunction:
        return new FunctionElementHandle(summaryResynthesizer, location);
      case ReferenceKind.topLevelPropertyAccessor:
        return new PropertyAccessorElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.constructor:
      case ReferenceKind.function:
      case ReferenceKind.propertyAccessor:
      case ReferenceKind.method:
      case ReferenceKind.prefix:
      case ReferenceKind.unresolved:
      case ReferenceKind.variable:
        // Should never happen.  Exported names never refer to import prefixes,
        // and they always refer to defined top-level entities.
        throw new StateError('Unexpected export name kind: ${exportName.kind}');
    }
    return null;
  }

  /**
   * Main entry point.  Resynthesize the [LibraryElement] and return it.
   */
  LibraryElement buildLibrary() {
    // Create LibraryElementImpl.
    bool hasName = unlinkedUnits[0].libraryName.isNotEmpty;
    library = new LibraryElementImpl.forSerialized(
        summaryResynthesizer.context,
        unlinkedUnits[0].libraryName,
        hasName ? unlinkedUnits[0].libraryNameOffset : -1,
        unlinkedUnits[0].libraryNameLength,
        new _LibraryResynthesizerContext(this),
        unlinkedUnits[0]);
    // Create the defining unit.
    _UnitResynthesizer definingUnitResynthesizer =
        createUnitResynthesizer(0, librarySource, null);
    CompilationUnitElementImpl definingUnit = definingUnitResynthesizer.unit;
    library.definingCompilationUnit = definingUnit;
    definingUnit.source = librarySource;
    definingUnit.librarySource = librarySource;
    // Create parts.
    List<_UnitResynthesizer> partResynthesizers = <_UnitResynthesizer>[];
    UnlinkedUnit unlinkedDefiningUnit = unlinkedUnits[0];
    assert(unlinkedDefiningUnit.publicNamespace.parts.length + 1 ==
        linkedLibrary.units.length);
    for (int i = 1; i < linkedLibrary.units.length; i++) {
      _UnitResynthesizer partResynthesizer = buildPart(
          definingUnitResynthesizer,
          unlinkedDefiningUnit.publicNamespace.parts[i - 1],
          unlinkedDefiningUnit.parts[i - 1],
          i);
      if (partResynthesizer != null) {
        partResynthesizers.add(partResynthesizer);
      }
    }
    library.parts = partResynthesizers.map((r) => r.unit).toList();
    // Populate units.
    rememberUriToUnit(definingUnitResynthesizer);
    for (_UnitResynthesizer partResynthesizer in partResynthesizers) {
      rememberUriToUnit(partResynthesizer);
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
   * Create a [_UnitResynthesizer] that will resynthesize the part with the
   * given [uri]. Return `null` if the [uri] is invalid.
   */
  _UnitResynthesizer buildPart(_UnitResynthesizer definingUnitResynthesizer,
      String uri, UnlinkedPart partDecl, int unitNum) {
    Source unitSource =
        summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
    _UnitResynthesizer partResynthesizer =
        createUnitResynthesizer(unitNum, unitSource, partDecl);
    CompilationUnitElementImpl partUnit = partResynthesizer.unit;
    partUnit.uriOffset = partDecl.uriOffset;
    partUnit.uriEnd = partDecl.uriEnd;
    partUnit.source = unitSource;
    partUnit.librarySource = librarySource;
    partUnit.uri = uri;
    return partResynthesizer;
  }

  /**
   * Set up data structures for deserializing a compilation unit.
   */
  _UnitResynthesizer createUnitResynthesizer(
      int unitNum, Source unitSource, UnlinkedPart unlinkedPart) {
    LinkedUnit linkedUnit = linkedLibrary.units[unitNum];
    UnlinkedUnit unlinkedUnit = unlinkedUnits[unitNum];
    return new _UnitResynthesizer(
        this, unlinkedUnit, linkedUnit, unitSource, unlinkedPart);
  }

  /**
   * Build the components of an [ElementLocationImpl] for the entity in the
   * given [unit] of the dependency located at [dependencyIndex], and having
   * the given [name].
   */
  List<String> getReferencedLocationComponents(
      int dependencyIndex, int unit, String name) {
    if (dependencyIndex == 0) {
      String partUri;
      if (unit != 0) {
        String uri = unlinkedUnits[0].publicNamespace.parts[unit - 1];
        partUri = _resolveRelativeUri(uri);
      } else {
        partUri = libraryUriStr;
      }
      return <String>[libraryUriStr, partUri, name];
    }

    LinkedDependency dependency = linkedLibrary.dependencies[dependencyIndex];
    String referencedLibraryUri = _resolveRelativeUri(dependency.uri);

    String partUri;
    if (unit != 0) {
      String uri = dependency.parts[unit - 1];
      partUri = _resolveRelativeUri(uri);
    } else {
      partUri = referencedLibraryUri;
    }
    return <String>[referencedLibraryUri, partUri, name];
  }

  /**
   * Remember the absolute URI to the corresponding unit mapping.
   */
  void rememberUriToUnit(_UnitResynthesizer unitResynthesizer) {
    CompilationUnitElementImpl unit = unitResynthesizer.unit;
    Source source = unit.source;
    if (source != null) {
      String absoluteUri = source.uri.toString();
      resynthesizedUnits[absoluteUri] = unit;
    }
  }

  /**
   * Resolve the [relativeUriStr] against [libraryUri] using Dart rules.
   */
  String _resolveRelativeUri(String relativeUriStr) {
    Uri relativeUri = Uri.parse(relativeUriStr);
    Uri resolvedUri = resolveRelativeUri(libraryUri, relativeUri);
    return resolvedUri.toString();
  }
}

/**
 * Implementation of [LibraryResynthesizerContext] for [_LibraryResynthesizer].
 */
class _LibraryResynthesizerContext extends LibraryResynthesizerContextMixin
    implements LibraryResynthesizerContext {
  final _LibraryResynthesizer resynthesizer;

  _LibraryResynthesizerContext(this.resynthesizer);

  @override
  LinkedLibrary get linkedLibrary => resynthesizer.linkedLibrary;

  @override
  LibraryElement buildExportedLibrary(String relativeUri) {
    return _getLibraryByRelativeUri(relativeUri);
  }

  @override
  LibraryElement buildImportedLibrary(int dependency) {
    String depUri = resynthesizer.linkedLibrary.dependencies[dependency].uri;
    return _getLibraryByRelativeUri(depUri);
  }

  @override
  FunctionElement findEntryPoint() {
    LibraryElementImpl library = resynthesizer.library;
    Element entryPoint =
        library.exportNamespace.get(FunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is FunctionElement) {
      return entryPoint;
    }
    return null;
  }

  @override
  void patchTopLevelAccessors() {
    LibraryElementImpl library = resynthesizer.library;
    BuildLibraryElementUtils.patchTopLevelAccessors(library);
  }

  LibraryElementHandle _getLibraryByRelativeUri(String depUri) {
    Source source = resynthesizer.summaryResynthesizer.sourceFactory
        .resolveUri(resynthesizer.librarySource, depUri);
    if (source == null) {
      return null;
    }
    String absoluteUri = source.uri.toString();
    return new LibraryElementHandle(resynthesizer.summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[absoluteUri]));
  }
}

class RecursiveInstantiateToBounds {}

/// Specialization of [ReferenceInfo] for resynthesis from linked summaries.
class _ReferenceInfo extends ReferenceInfo {
  /**
   * The [_LibraryResynthesizer] which is being used to obtain summaries.
   */
  final _LibraryResynthesizer libraryResynthesizer;

  @override
  final _ReferenceInfo enclosing;

  @override
  final String name;

  /**
   * Is `true` if the [element] can be used as a declared type.
   */
  final bool isDeclarableType;

  @override
  final Element element;

  /**
   * If this reference refers to a non-generic type, the type it refers to.
   * Otherwise `null`.
   */
  DartType _type;

  /**
   * The number of type parameters accepted by the entity referred to by this
   * reference, or zero if it doesn't accept any type parameters.
   */
  final int numTypeParameters;

  bool _isBeingInstantiatedToBounds = false;
  bool _isRecursiveWhileInstantiateToBounds = false;

  /**
   * Create a new [_ReferenceInfo] object referring to an element called [name]
   * via the element handle [element], and having [numTypeParameters] type
   * parameters.
   *
   * For the special types `dynamic` and `void`, [specialType] should point to
   * the type itself.  Otherwise, pass `null` and the type will be computed
   * when appropriate.
   */
  _ReferenceInfo(
      this.libraryResynthesizer,
      this.enclosing,
      this.name,
      this.isDeclarableType,
      this.element,
      DartType specialType,
      this.numTypeParameters) {
    if (specialType != null) {
      _type = specialType;
    }
  }

  @override
  bool get hasTypeParameters => numTypeParameters != 0;

  @override
  DartType get type {
    if (_type == null) {
      _type = _buildType(true, 0, (_) => DynamicTypeImpl.instance, const []);
    }
    return _type;
  }

  List<DartType> get _dynamicTypeArguments =>
      new List<DartType>.filled(numTypeParameters, DynamicTypeImpl.instance);

  /**
   * Build a [DartType] corresponding to the result of applying some type
   * arguments to the entity referred to by this [_ReferenceInfo].  The type
   * arguments are retrieved by calling [getTypeArgument].
   *
   * If [implicitFunctionTypeIndices] is not empty, a [DartType] should be
   * created which refers to a function type implicitly defined by one of the
   * element's parameters.  [implicitFunctionTypeIndices] is interpreted as in
   * [EntityRef.implicitFunctionTypeIndices].
   *
   * If the entity referred to by this [_ReferenceInfo] is not a type, `null`
   * is returned.
   */
  DartType buildType(bool instantiateToBoundsAllowed, int numTypeArguments,
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    DartType result =
        (numTypeParameters == 0 && implicitFunctionTypeIndices.isEmpty)
            ? type
            : _buildType(instantiateToBoundsAllowed, numTypeArguments,
                getTypeArgument, implicitFunctionTypeIndices);
    if (result == null) {
      return DynamicTypeImpl.instance;
    }
    return result;
  }

  /**
   * If this reference refers to a type, build a [DartType].  Otherwise return
   * `null`.  If [numTypeArguments] is the same as the [numTypeParameters],
   * the type is instantiated with type arguments returned by [getTypeArgument],
   * otherwise it is instantiated with type parameter bounds (if strong mode),
   * or with `dynamic` type arguments.
   *
   * If [implicitFunctionTypeIndices] is not null, a [DartType] should be
   * created which refers to a function type implicitly defined by one of the
   * element's parameters.  [implicitFunctionTypeIndices] is interpreted as in
   * [EntityRef.implicitFunctionTypeIndices].
   */
  DartType _buildType(bool instantiateToBoundsAllowed, int numTypeArguments,
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    ElementHandle element = this.element; // To allow type promotion
    if (element is ClassElementHandle) {
      List<DartType> typeArguments = null;
      // If type arguments are specified, use them.
      // Otherwise, delay until they are requested.
      if (numTypeParameters == 0) {
        return element.type;
      } else if (numTypeArguments == numTypeParameters) {
        typeArguments = _buildTypeArguments(numTypeArguments, getTypeArgument);
      }
      InterfaceTypeImpl type =
          new InterfaceTypeImpl.elementWithNameAndArgs(element, name, () {
        if (typeArguments == null) {
          if (!_isBeingInstantiatedToBounds) {
            _isBeingInstantiatedToBounds = true;
            _isRecursiveWhileInstantiateToBounds = false;
            try {
              if (libraryResynthesizer.summaryResynthesizer.strongMode) {
                InterfaceType instantiatedToBounds = libraryResynthesizer
                    .summaryResynthesizer.context.typeSystem
                    .instantiateToBounds(element.type) as InterfaceType;
                if (_isRecursiveWhileInstantiateToBounds) {
                  throw new RecursiveInstantiateToBounds();
                }
                return instantiatedToBounds.typeArguments;
              } else {
                return _dynamicTypeArguments;
              }
            } finally {
              _isBeingInstantiatedToBounds = false;
            }
          } else {
            _isRecursiveWhileInstantiateToBounds = true;
            typeArguments = _dynamicTypeArguments;
          }
        }
        return typeArguments;
      });
      // Mark the type as having implicit type arguments, so that we don't
      // attempt to request them during constant expression resynthesizing.
      if (typeArguments == null) {
        _typesWithImplicitTypeArguments[type] = true;
      }
      // Done.
      return type;
    } else if (element is GenericTypeAliasElementHandle) {
      GenericTypeAliasElementImpl actualElement = element.actualElement;
      List<DartType> typeArguments;
      if (numTypeArguments == numTypeParameters) {
        typeArguments = _buildTypeArguments(numTypeArguments, getTypeArgument);
      } else if (libraryResynthesizer.summaryResynthesizer.strongMode &&
          instantiateToBoundsAllowed) {
        if (!_isBeingInstantiatedToBounds) {
          _isBeingInstantiatedToBounds = true;
          _isRecursiveWhileInstantiateToBounds = false;
          try {
            typeArguments = libraryResynthesizer
                .summaryResynthesizer.context.typeSystem
                .instantiateTypeFormalsToBounds(element.typeParameters);
            if (_isRecursiveWhileInstantiateToBounds) {
              typeArguments = _dynamicTypeArguments;
            }
          } finally {
            _isBeingInstantiatedToBounds = false;
          }
        } else {
          _isRecursiveWhileInstantiateToBounds = true;
          typeArguments = _dynamicTypeArguments;
        }
      } else {
        typeArguments = _dynamicTypeArguments;
      }
      return actualElement.typeAfterSubstitution(typeArguments);
    } else if (element is FunctionTypedElement) {
      if (element is FunctionTypeAliasElementHandle) {
        List<DartType> typeArguments;
        if (numTypeArguments == numTypeParameters) {
          typeArguments =
              _buildTypeArguments(numTypeArguments, getTypeArgument);
        } else if (libraryResynthesizer.summaryResynthesizer.strongMode &&
            instantiateToBoundsAllowed) {
          if (!_isBeingInstantiatedToBounds) {
            _isBeingInstantiatedToBounds = true;
            _isRecursiveWhileInstantiateToBounds = false;
            try {
              FunctionType instantiatedToBounds = libraryResynthesizer
                  .summaryResynthesizer.context.typeSystem
                  .instantiateToBounds(element.type) as FunctionType;
              if (!_isRecursiveWhileInstantiateToBounds) {
                typeArguments = instantiatedToBounds.typeArguments;
              } else {
                typeArguments = _dynamicTypeArguments;
              }
            } finally {
              _isBeingInstantiatedToBounds = false;
            }
          } else {
            _isRecursiveWhileInstantiateToBounds = true;
            typeArguments = _dynamicTypeArguments;
          }
        } else {
          typeArguments = _dynamicTypeArguments;
        }
        return new FunctionTypeImpl.elementWithNameAndArgs(
            element, name, typeArguments, numTypeParameters != 0);
      } else {
        FunctionTypedElementComputer computer;
        if (implicitFunctionTypeIndices.isNotEmpty) {
          numTypeArguments = numTypeParameters;
          computer = () {
            FunctionTypedElement element = this.element;
            for (int index in implicitFunctionTypeIndices) {
              element = element.parameters[index].type.element;
            }
            return element;
          };
        } else {
          // For a type that refers to a generic executable, the type arguments are
          // not supposed to include the arguments to the executable itself.
          if (element is MethodElementHandle && !element.isStatic) {
            numTypeArguments = enclosing?.numTypeParameters ?? 0;
          } else {
            numTypeArguments = 0;
          }
          computer = () => this.element as FunctionTypedElement;
        }
        // TODO(paulberry): Is it a bug that we have to pass `false` for
        // isInstantiated?
        return new DeferredFunctionTypeImpl(computer, null,
            _buildTypeArguments(numTypeArguments, getTypeArgument), false);
      }
    } else {
      return null;
    }
  }

  /**
   * Build a list of type arguments having length [numTypeArguments] where each
   * type argument is obtained by calling [getTypeArgument].
   */
  List<DartType> _buildTypeArguments(
      int numTypeArguments, DartType getTypeArgument(int i)) {
    List<DartType> typeArguments = const <DartType>[];
    if (numTypeArguments != 0) {
      typeArguments = new List<DartType>(numTypeArguments);
      for (int i = 0; i < numTypeArguments; i++) {
        typeArguments[i] = getTypeArgument(i);
      }
    }
    return typeArguments;
  }
}

/// Specialization of [UnitResynthesizer] for resynthesis from linked summaries.
class _UnitResynthesizer extends UnitResynthesizer with UnitResynthesizerMixin {
  /**
   * The [_LibraryResynthesizer] which is being used to obtain summaries.
   */
  final _LibraryResynthesizer libraryResynthesizer;

  /**
   * The [UnlinkedUnit] from which elements are currently being resynthesized.
   */
  final UnlinkedUnit unlinkedUnit;

  /**
   * The [LinkedUnit] from which elements are currently being resynthesized.
   */
  final LinkedUnit linkedUnit;

  /**
   * The [CompilationUnitElementImpl] for the compilation unit currently being
   * resynthesized.
   */
  CompilationUnitElementImpl unit;

  /**
   * The visitor to rewrite implicit `new` and `const`.
   */
  AstRewriteVisitor astRewriteVisitor;

  /**
   * Map from slot id to the corresponding [EntityRef] object for linked types
   * (i.e. propagated and inferred types).
   */
  final Map<int, EntityRef> linkedTypeMap = <int, EntityRef>{};

  /**
   * Set of slot ids corresponding to const constructors that are part of
   * cycles.
   */
  Set<int> constCycles;

  /**
   * Set of slot ids corresponding to parameters that inherit `@covariant`
   * behavior.
   */
  Set<int> parametersInheritingCovariant;

  int numLinkedReferences;
  int numUnlinkedReferences;

  /**
   * List of [_ReferenceInfo] objects describing the references in the current
   * compilation unit.  This list is works as a lazily filled cache, use
   * [getReferenceInfo] to get the [_ReferenceInfo] for an index.
   */
  List<_ReferenceInfo> referenceInfos;

  /**
   * The [ResynthesizerContext] for this resynthesize session.
   */
  ResynthesizerContext _resynthesizerContext;

  _UnitResynthesizer(this.libraryResynthesizer, this.unlinkedUnit,
      this.linkedUnit, Source unitSource, UnlinkedPart unlinkedPart) {
    _resynthesizerContext = new SummaryResynthesizerContext(this);
    unit = new CompilationUnitElementImpl.forSerialized(
        libraryResynthesizer.library,
        _resynthesizerContext,
        unlinkedUnit,
        unlinkedPart,
        unitSource?.shortName);

    {
      List<int> lineStarts = unlinkedUnit.lineStarts;
      if (lineStarts.isEmpty) {
        lineStarts = const <int>[0];
      }
      unit.lineInfo = new LineInfo(lineStarts);
    }

    for (EntityRef t in linkedUnit.types) {
      linkedTypeMap[t.slot] = t;
    }
    constCycles = linkedUnit.constCycles.toSet();
    parametersInheritingCovariant =
        linkedUnit.parametersInheritingCovariant.toSet();
    numLinkedReferences = linkedUnit.references.length;
    numUnlinkedReferences = unlinkedUnit.references.length;
    referenceInfos = new List<_ReferenceInfo>(numLinkedReferences);
  }

  SummaryResynthesizer get summaryResynthesizer =>
      libraryResynthesizer.summaryResynthesizer;

  @override
  TypeProvider get typeProvider => summaryResynthesizer.typeProvider;

  /**
   * Build [ElementAnnotationImpl] for the given [UnlinkedExpr].
   */
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedExpr uc) {
    ElementAnnotationImpl elementAnnotation = new ElementAnnotationImpl(unit);
    Expression constExpr = _buildConstExpression(context, uc);
    if (constExpr == null) {
      // Invalid constant expression.
    } else if (constExpr is Identifier) {
      var element = constExpr.staticElement;
      ArgumentList arguments = constExpr.getProperty(ExprBuilder.ARGUMENT_LIST);
      if (element is PropertyAccessorElement && arguments == null) {
        elementAnnotation.element = element;
        elementAnnotation.annotationAst = AstTestFactory.annotation(constExpr);
      } else if (element is ConstructorElement && arguments != null) {
        elementAnnotation.element = element;
        elementAnnotation.annotationAst =
            AstTestFactory.annotation2(constExpr, null, arguments);
      } else {
        elementAnnotation.annotationAst = AstTestFactory
            .annotation(AstTestFactory.identifier3(r'#invalidConst'));
      }
    } else if (constExpr is InstanceCreationExpression) {
      elementAnnotation.element = constExpr.staticElement;
      Identifier typeName = constExpr.constructorName.type.name;
      SimpleIdentifier constructorName = constExpr.constructorName.name;
      if (typeName is SimpleIdentifier && constructorName != null) {
        // E.g. `@cls.ctor()`.  Since `cls.ctor` would have been parsed as
        // a PrefixedIdentifier, we need to resynthesize it as one.
        typeName = AstTestFactory.identifier(typeName, constructorName);
        constructorName = null;
      }
      elementAnnotation.annotationAst = AstTestFactory.annotation2(
          typeName, constructorName, constExpr.argumentList)
        ..element = constExpr.staticElement;
    } else if (constExpr is PropertyAccess) {
      var target = constExpr.target as Identifier;
      var propertyName = constExpr.propertyName;
      var propertyElement = propertyName.staticElement;
      ArgumentList arguments = constExpr.getProperty(ExprBuilder.ARGUMENT_LIST);
      if (propertyElement is PropertyAccessorElement && arguments == null) {
        elementAnnotation.element = propertyElement;
        elementAnnotation.annotationAst = AstTestFactory.annotation2(
            target, propertyName, null)
          ..element = propertyElement;
      } else if (propertyElement is ConstructorElement && arguments != null) {
        elementAnnotation.element = propertyElement;
        elementAnnotation.annotationAst = AstTestFactory.annotation2(
            target, propertyName, arguments)
          ..element = propertyElement;
      } else {
        elementAnnotation.annotationAst = AstTestFactory
            .annotation(AstTestFactory.identifier3(r'#invalidConst'));
      }
    } else {
      throw new StateError(
          'Unexpected annotation type: ${constExpr.runtimeType}');
    }
    return elementAnnotation;
  }

  /**
   * Build an implicit getter for the given [property] and bind it to the
   * [property] and to its enclosing element.
   */
  PropertyAccessorElementImpl buildImplicitGetter(
      PropertyInducingElementImpl property) {
    PropertyAccessorElementImpl_ImplicitGetter getter =
        new PropertyAccessorElementImpl_ImplicitGetter(property);
    getter.enclosingElement = property.enclosingElement;
    return getter;
  }

  /**
   * Build an implicit setter for the given [property] and bind it to the
   * [property] and to its enclosing element.
   */
  PropertyAccessorElementImpl buildImplicitSetter(
      PropertyInducingElementImpl property) {
    PropertyAccessorElementImpl_ImplicitSetter setter =
        new PropertyAccessorElementImpl_ImplicitSetter(property);
    setter.enclosingElement = property.enclosingElement;
    return setter;
  }

  /**
   * Build the appropriate [DartType] object corresponding to a slot id in the
   * [LinkedUnit.types] table.
   */
  DartType buildLinkedType(ElementImpl context, int slot) {
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
    return buildType(context, type);
  }

  @override
  DartType buildType(ElementImpl context, EntityRef type,
      {bool defaultVoid: false,
      bool instantiateToBoundsAllowed: true,
      bool declaredType: false}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return DynamicTypeImpl.instance;
      }
    }
    if (type.refinedSlot != 0) {
      var refinedType = linkedTypeMap[type.refinedSlot];
      if (refinedType != null) {
        type = refinedType;
      }
    }
    if (type.paramReference != 0) {
      return context.typeParameterContext
          .getTypeParameterType(type.paramReference);
    } else if (type.entityKind == EntityRefKind.genericFunctionType) {
      GenericFunctionTypeElement element =
          new GenericFunctionTypeElementImpl.forSerialized(context, type);
      return element.type;
    } else if (type.syntheticReturnType != null) {
      FunctionElementImpl element =
          new FunctionElementImpl_forLUB(context, type);
      return element.type;
    } else {
      DartType getTypeArgument(int i) {
        if (i < type.typeArguments.length) {
          return buildType(context, type.typeArguments[i],
              declaredType: declaredType);
        } else {
          return DynamicTypeImpl.instance;
        }
      }

      _ReferenceInfo referenceInfo = getReferenceInfo(type.reference);
      if (declaredType && !referenceInfo.isDeclarableType) {
        return DynamicTypeImpl.instance;
      }

      return referenceInfo.buildType(
          instantiateToBoundsAllowed,
          type.typeArguments.length,
          getTypeArgument,
          type.implicitFunctionTypeIndices);
    }
  }

  @override
  DartType buildTypeForClassInfo(covariant _ReferenceInfo info,
          int numTypeArguments, DartType getTypeArgument(int i)) =>
      info.buildType(true, numTypeArguments, getTypeArgument, const <int>[]);

  UnitExplicitTopLevelAccessors buildUnitExplicitTopLevelAccessors() {
    Map<String, TopLevelVariableElementImpl> implicitVariables =
        new HashMap<String, TopLevelVariableElementImpl>();
    UnitExplicitTopLevelAccessors accessorsData =
        new UnitExplicitTopLevelAccessors();
    for (UnlinkedExecutable unlinkedExecutable in unlinkedUnit.executables) {
      UnlinkedExecutableKind kind = unlinkedExecutable.kind;
      if (kind == UnlinkedExecutableKind.getter ||
          kind == UnlinkedExecutableKind.setter) {
        // name
        String name = unlinkedExecutable.name;
        if (kind == UnlinkedExecutableKind.setter) {
          assert(name.endsWith('='));
          name = name.substring(0, name.length - 1);
        }
        // create
        PropertyAccessorElementImpl accessor =
            new PropertyAccessorElementImpl.forSerialized(
                unlinkedExecutable, unit);
        accessorsData.accessors.add(accessor);
        // implicit variable
        TopLevelVariableElementImpl variable = implicitVariables[name];
        if (variable == null) {
          variable = new TopLevelVariableElementImpl(name, -1);
          variable.enclosingElement = unit;
          implicitVariables[name] = variable;
          accessorsData.implicitVariables.add(variable);
          variable.isSynthetic = true;
          variable.isFinal = kind == UnlinkedExecutableKind.getter;
        } else {
          variable.isFinal = false;
        }
        accessor.variable = variable;
        // link
        if (kind == UnlinkedExecutableKind.getter) {
          variable.getter = accessor;
        } else {
          variable.setter = accessor;
        }
      }
    }
    return accessorsData;
  }

  UnitExplicitTopLevelVariables buildUnitExplicitTopLevelVariables() {
    List<UnlinkedVariable> unlinkedVariables = unlinkedUnit.variables;
    int numberOfVariables = unlinkedVariables.length;
    UnitExplicitTopLevelVariables variablesData =
        new UnitExplicitTopLevelVariables(numberOfVariables);
    for (int i = 0; i < numberOfVariables; i++) {
      UnlinkedVariable unlinkedVariable = unlinkedVariables[i];
      TopLevelVariableElementImpl element;
      if (unlinkedVariable.initializer?.bodyExpr != null &&
          unlinkedVariable.isConst) {
        element = new ConstTopLevelVariableElementImpl.forSerialized(
            unlinkedVariable, unit);
      } else {
        element = new TopLevelVariableElementImpl.forSerialized(
            unlinkedVariable, unit);
      }
      variablesData.variables[i] = element;
      // implicit accessors
      variablesData.implicitAccessors.add(buildImplicitGetter(element));
      if (!(element.isConst || element.isFinal)) {
        variablesData.implicitAccessors.add(buildImplicitSetter(element));
      }
    }
    return variablesData;
  }

  @override
  bool doesTypeHaveImplicitArguments(ParameterizedType type) =>
      _typesWithImplicitTypeArguments[type] != null;

  @override
  _ReferenceInfo getReferenceInfo(int index) {
    _ReferenceInfo result = referenceInfos[index];
    if (result == null) {
      LinkedReference linkedReference = linkedUnit.references[index];
      String name;
      int containingReference;
      if (index < numUnlinkedReferences) {
        name = unlinkedUnit.references[index].name;
        containingReference = unlinkedUnit.references[index].prefixReference;
      } else {
        name = linkedUnit.references[index].name;
        containingReference = linkedUnit.references[index].containingReference;
      }
      _ReferenceInfo enclosingInfo = containingReference != 0
          ? getReferenceInfo(containingReference)
          : null;
      Element element;
      DartType type;
      bool isDeclarableType = false;
      int numTypeParameters = linkedReference.numTypeParameters;
      if (linkedReference.kind == ReferenceKind.unresolved) {
        type = UndefinedTypeImpl.instance;
        element = null;
        isDeclarableType = true;
      } else if (name == 'dynamic') {
        type = DynamicTypeImpl.instance;
        element = type.element;
        isDeclarableType = true;
      } else if (name == 'void') {
        type = VoidTypeImpl.instance;
        element = type.element;
        isDeclarableType = true;
      } else if (name == '*bottom*') {
        type = BottomTypeImpl.instance;
        element = null;
        isDeclarableType = true;
      } else {
        List<String> locationComponents;
        if (enclosingInfo != null && enclosingInfo.element is ClassElement) {
          String identifier = _getElementIdentifier(name, linkedReference.kind);
          locationComponents =
              enclosingInfo.element.location.components.toList();
          locationComponents.add(identifier);
        } else {
          String identifier = _getElementIdentifier(name, linkedReference.kind);
          locationComponents =
              libraryResynthesizer.getReferencedLocationComponents(
                  linkedReference.dependency, linkedReference.unit, identifier);
          if (linkedReference.kind == ReferenceKind.prefix) {
            locationComponents = <String>[
              locationComponents[0],
              locationComponents[2]
            ];
          }
        }
        if (!_resynthesizerContext.isStrongMode &&
            locationComponents.length == 3 &&
            locationComponents[0] == 'dart:async' &&
            locationComponents[2] == 'FutureOr') {
          type = typeProvider.dynamicType;
          numTypeParameters = 0;
        }
        ElementLocation location =
            new ElementLocationImpl.con3(locationComponents);
        if (enclosingInfo != null) {
          numTypeParameters += enclosingInfo.numTypeParameters;
        }
        switch (linkedReference.kind) {
          case ReferenceKind.classOrEnum:
            element = new ClassElementHandle(summaryResynthesizer, location);
            isDeclarableType = true;
            break;
          case ReferenceKind.constructor:
            assert(location.components.length == 4);
            element =
                new ConstructorElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.method:
            assert(location.components.length == 4);
            element = new MethodElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.propertyAccessor:
            assert(location.components.length == 4);
            element = new PropertyAccessorElementHandle(
                summaryResynthesizer, location);
            break;
          case ReferenceKind.topLevelFunction:
            assert(location.components.length == 3);
            element = new FunctionElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.topLevelPropertyAccessor:
            element = new PropertyAccessorElementHandle(
                summaryResynthesizer, location);
            break;
          case ReferenceKind.typedef:
          case ReferenceKind.genericFunctionTypedef:
            element = new GenericTypeAliasElementHandle(
                summaryResynthesizer, location);
            isDeclarableType = true;
            break;
          case ReferenceKind.function:
            Element enclosingElement = enclosingInfo.element;
            if (enclosingElement is VariableElement) {
              element = new _DeferredInitializerElement(enclosingElement);
            } else {
              throw new StateError('Unexpected element enclosing function:'
                  ' ${enclosingElement.runtimeType}');
            }
            break;
          case ReferenceKind.prefix:
            element = new PrefixElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.variable:
          case ReferenceKind.unresolved:
            break;
        }
      }
      result = new _ReferenceInfo(libraryResynthesizer, enclosingInfo, name,
          isDeclarableType, element, type, numTypeParameters);
      referenceInfos[index] = result;
    }
    return result;
  }

  /**
   * Return the error reported during type inference for the given [slot],
   * or `null` if there were no error.
   */
  TopLevelInferenceError getTypeInferenceError(int slot) {
    if (slot == 0) {
      return null;
    }
    for (TopLevelInferenceError error in linkedUnit.topLevelInferenceErrors) {
      if (error.slot == slot) {
        return error;
      }
    }
    return null;
  }

  Expression _buildConstExpression(ElementImpl context, UnlinkedExpr uc) {
    var expression = new ExprBuilder(this, context, uc).build();

    if (expression != null && context.context.analysisOptions.previewDart2) {
      astRewriteVisitor ??= new AstRewriteVisitor(libraryResynthesizer.library,
          unit.source, typeProvider, AnalysisErrorListener.NULL_LISTENER,
          addConstKeyword: true);
      var container = astFactory.expressionStatement(expression, null);
      expression.accept(astRewriteVisitor);
      expression = container.expression;
    }

    return expression;
  }

  /**
   * Return the [ConstructorElement] corresponding to the given [entry].
   */
  ConstructorElement _getConstructorForEntry(
      ElementImpl context, EntityRef entry) {
    _ReferenceInfo info = getReferenceInfo(entry.reference);
    DartType type =
        createConstructorDefiningType(context, info, entry.typeArguments);
    if (type is InterfaceType) {
      return getConstructorForInfo(type, info);
    }
    return null;
  }

  /**
   * If the given [kind] is a top-level or class member property accessor, and
   * the given [name] does not end with `=`, i.e. does not denote a setter,
   * return the getter identifier by appending `?`.
   */
  static String _getElementIdentifier(String name, ReferenceKind kind) {
    if (kind == ReferenceKind.topLevelPropertyAccessor ||
        kind == ReferenceKind.propertyAccessor) {
      if (!name.endsWith('=')) {
        return name + '?';
      }
    }
    return name;
  }
}
