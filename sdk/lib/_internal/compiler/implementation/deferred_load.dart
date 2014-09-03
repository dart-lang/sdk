// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'dart2jslib.dart' show
    Backend,
    Compiler,
    CompilerTask,
    Constant,
    ConstructedConstant,
    MessageKind,
    DeferredConstant,
    StringConstant,
    invariant;

import 'dart_backend/dart_backend.dart' show
    DartBackend;

import 'js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'elements/elements.dart' show
    Element,
    ClassElement,
    ElementKind,
    Elements,
    FunctionElement,
    LibraryElement,
    MetadataAnnotation,
    ScopeContainerElement,
    PrefixElement,
    VoidElement,
    TypedefElement,
    AstElement;

import 'util/util.dart' show
    Link, makeUnique;

import 'util/setlet.dart' show
    Setlet;

import 'tree/tree.dart' show
    LibraryTag,
    Node,
    NewExpression,
    Import,
    LibraryDependency,
    LiteralString,
    LiteralDartString;

import 'tree/tree.dart' as ast;

import 'resolution/resolution.dart' show
    TreeElements,
    AnalyzableElementX;

import "dart:math" show min;

/// A "hunk" of the program that will be loaded whenever one of its [imports]
/// are loaded.
///
/// Elements that are only used in one deferred import, is in an OutputUnit with
/// the deferred import as single element in the [imports] set.
///
/// Whenever a deferred Element is shared between several deferred imports it is
/// in an output unit with those imports in the [imports] Set.
///
/// OutputUnits are equal if their [imports] are equal.
class OutputUnit {
  /// The deferred imports that will load this output unit when one of them is
  /// loaded.
  final Setlet<Import> imports = new Setlet<Import>();

  /// A unique name representing this [OutputUnit].
  /// Based on the set of [imports].
  String name;

  /// Returns a name composed of the main output file name and [name].
  String partFileName(Compiler compiler) {
    String outPath = compiler.outputUri != null
        ? compiler.outputUri.path
        : "out";
    String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
    if (this == compiler.deferredLoadTask.mainOutputUnit) {
      return outName;
    } else {
      return "${outName}_$name";
    }
  }

  String toString() => "OutputUnit($name)";

  bool operator==(OutputUnit other) {
    return imports.length == other.imports.length &&
        imports.containsAll(other.imports);
  }

  int get hashCode {
    int sum = 0;
    for (Import import in imports) {
      sum = (sum + import.hashCode) & 0x3FFFFFFF;  // Stay in 30 bit range.
    }
    return sum;
  }
}

/// For each deferred import, find elements and constants to be loaded when that
/// import is loaded. Elements that are used by several deferred imports are in
/// shared OutputUnits.
class DeferredLoadTask extends CompilerTask {
  /// The name of this task.
  String get name => 'Deferred Loading';

  /// DeferredLibrary from dart:async
  ClassElement get deferredLibraryClass => compiler.deferredLibraryClass;

  /// A synthetic [Import] representing the loading of the main
  /// program.
  final Import _fakeMainImport = new Import(null, new LiteralString(null,
      new LiteralDartString("main")), null, null, null);

  /// The OutputUnit that will be loaded when the program starts.
  final OutputUnit mainOutputUnit = new OutputUnit();

  /// A set containing (eventually) all output units that will result from the
  /// program.
  final Set<OutputUnit> allOutputUnits = new Set<OutputUnit>();

  /// Will be `true` if the program contains deferred libraries.
  bool isProgramSplit = false;

  /// A mapping from the name of a defer import to all the output units it
  /// depends on in a list of lists to be loaded in the order they appear.
  ///
  /// For example {"lib1": [[lib1_lib2_lib3], [lib1_lib2, lib1_lib3],
  /// [lib1]]} would mean that in order to load "lib1" first the hunk
  /// lib1_lib2_lib2 should be loaded, then the hunks lib1_lib2 and lib1_lib3
  /// can be loaded in parallel. And finally lib1 can be loaded.
  final Map<String, List<List<OutputUnit>>> hunksToLoad =
      new Map<String, List<List<OutputUnit>>>();
  final Map<Import, String> importDeferName = new Map<Import, String>();

  /// A mapping from elements and constants to their output unit. Query this via
  /// [outputUnitForElement]
  final Map<Element, OutputUnit> _elementToOutputUnit =
      new Map<Element, OutputUnit>();

  /// A mapping from constants to their output unit. Query this via
  /// [outputUnitForConstant]
  final Map<Constant, OutputUnit> _constantToOutputUnit =
      new Map<Constant, OutputUnit>();

  /// All the imports with a [DeferredLibrary] annotation, mapped to the
  /// [LibraryElement] they import.
  /// The main library is included in this set for convenience.
  final Map<Import, LibraryElement> _allDeferredImports =
      new Map<Import, LibraryElement>();

  // For each deferred import we want to know exactly what elements have to
  // be loaded.
  Map<Import, Set<Element>> _importedDeferredBy = null;
  Map<Import, Set<Constant>> _constantsDeferredBy = null;

  Set<Element> _mainElements = new Set<Element>();

  DeferredLoadTask(Compiler compiler) : super(compiler);

  Backend get backend => compiler.backend;

  /// Returns the [OutputUnit] where [element] belongs.
  OutputUnit outputUnitForElement(Element element) {
    if (!isProgramSplit) return mainOutputUnit;

    element = element.implementation;
    while (!_elementToOutputUnit.containsKey(element)) {
      // Hack: it looks like we output annotation constants for classes that we
      // don't include in the output. This seems to happen when we have
      // reflection but can see that some classes are not needed. We still add
      // the annotation but don't run through it below (where we assign every
      // element to its output unit).
      if (element.enclosingElement == null) {
        _elementToOutputUnit[element] = mainOutputUnit;
        break;
      }
      element = element.enclosingElement.implementation;
    }
    return _elementToOutputUnit[element];
  }

  /// Returns the [OutputUnit] where [constant] belongs.
  OutputUnit outputUnitForConstant(Constant constant) {
    if (!isProgramSplit) return mainOutputUnit;

    return _constantToOutputUnit[constant];
  }

  bool isDeferred(Element element) {
    return outputUnitForElement(element) != mainOutputUnit;
  }

  /// Returns true if e1 and e2 are in the same output unit.
  bool inSameOutputUnit(Element e1, Element e2) {
    return outputUnitForElement(e1) == outputUnitForElement(e2);
  }

  void registerConstantDeferredUse(DeferredConstant constant,
                                   PrefixElement prefix) {
    OutputUnit outputUnit = new OutputUnit();
    outputUnit.imports.add(prefix.deferredImport);
    _constantToOutputUnit[constant] = outputUnit;
  }

  /// Mark that [import] is part of the [OutputputUnit] for [element].
  ///
  /// [element] can be either a [Constant] or an [Element].
  void _addImportToOutputUnitOfElement(Element element, Import import) {
    // Only one file should be loaded when the program starts, so make
    // sure that only one OutputUnit is created for [fakeMainImport].
    if (import == _fakeMainImport) {
      _elementToOutputUnit[element] = mainOutputUnit;
    }
    _elementToOutputUnit.putIfAbsent(element, () => new OutputUnit())
        .imports.add(import);
  }

  /// Mark that [import] is part of the [OutputputUnit] for [constant].
  ///
  /// [constant] can be either a [Constant] or an [Element].
  void _addImportToOutputUnitOfConstant(Constant constant, Import import) {
    // Only one file should be loaded when the program starts, so make
    // sure that only one OutputUnit is created for [fakeMainImport].
    if (import == _fakeMainImport) {
      _constantToOutputUnit[constant] = mainOutputUnit;
    }
    _constantToOutputUnit.putIfAbsent(constant, () => new OutputUnit())
        .imports.add(import);
  }

  /// Answers whether the [import] has a [DeferredLibrary] annotation.
  bool _isImportDeferred(Import import) {
    return _allDeferredImports.containsKey(import);
  }

  /// Checks whether the [import] has a [DeferredLibrary] annotation and stores
  /// the information in [_allDeferredImports] and on the corresponding
  /// prefixElement.
  void _markIfDeferred(Import import, LibraryElement library) {
    // Check if the import is deferred by a keyword.
    if (import.isDeferred) {
      _allDeferredImports[import] = library.getLibraryFromTag(import);
      return;
    }
    // Check if the import is deferred by a metadata annotation.
    Link<MetadataAnnotation> metadataList = import.metadata;
    if (metadataList == null) return;
    for (MetadataAnnotation metadata in metadataList) {
      metadata.ensureResolved(compiler);
      Element element = metadata.value.computeType(compiler).element;
      if (element == deferredLibraryClass) {
        _allDeferredImports[import] = library.getLibraryFromTag(import);
        // On encountering a deferred library without a prefix we report an
        // error, but continue the compilation to possibly give more
        // information. Therefore it is neccessary to check if there is a prefix
        // here.
        Element maybePrefix = library.find(import.prefix.toString());
        if (maybePrefix != null && maybePrefix.isPrefix) {
          PrefixElement prefix = maybePrefix;
          prefix.markAsDeferred(import);
        }
      }
    }
  }

  /// Answers whether [element] is explicitly deferred when referred to from
  /// [library].
  bool _isExplicitlyDeferred(Element element, LibraryElement library) {
    Link<Import> imports = _getImports(element, library);
    // If the element is not imported explicitly, it is implicitly imported
    // not deferred.
    if (imports.isEmpty) return false;
    // An element could potentially be loaded by several imports. If all of them
    // is explicitly deferred, we say the element is explicitly deferred.
    // TODO(sigurdm): We might want to give a warning if the imports do not
    // agree.
    return imports.every(_isImportDeferred);
  }

  /// Returns a [Link] of every [Import] that imports [element] into [library].
  Link<Import> _getImports(Element element, LibraryElement library) {
    if (element.isClassMember) {
      element = element.enclosingClass;
    }
    if (element.isAccessor) {
      element = (element as FunctionElement).abstractField;
    }
    return library.getImportsFor(element);
  }

  /// Finds all elements and constants that [element] depends directly on.
  /// (not the transitive closure.)
  ///
  /// Adds the results to [elements] and [constants].
  void _collectAllElementsAndConstantsResolvedFrom(
      Element element,
      Set<Element> elements,
      Set<Constant> constants,
      isMirrorUsage) {

    /// Recursively add the constant and its dependencies to [constants].
    void addConstants(Constant constant) {
      if (constants.contains(constant)) return;
      constants.add(constant);
      if (constant is ConstructedConstant) {
        elements.add(constant.type.element);
      }
      constant.getDependencies().forEach(addConstants);
    }

    /// Collects all direct dependencies of [element].
    ///
    /// The collected dependent elements and constants are are added to
    /// [elements] and [constants] respectively.
    void collectDependencies(Element element) {
      // TODO(johnniwinther): Remove this when [AbstractFieldElement] has been
      // removed.
      if (element is! AstElement) return;
      AstElement astElement = element;

      // TODO(sigurdm): We want to be more specific about this - need a better
      // way to query "liveness".
      if (astElement is! TypedefElement &&
          !compiler.enqueuer.resolution.hasBeenResolved(astElement)) {
        return;
      }

      TreeElements treeElements = astElement.resolvedAst.elements;

      assert(treeElements != null);

      for (Element dependency in treeElements.allElements) {
        if (Elements.isLocal(dependency) && !dependency.isFunction) continue;
        if (dependency.isErroneous) continue;
        if (dependency.isTypeVariable) continue;

        elements.add(dependency);
      }
      treeElements.forEachConstantNode((Node node, _) {
        // Explicitly depend on the backend constants.
        addConstants(
            backend.constants.getConstantForNode(node, treeElements));
      });
      elements.addAll(treeElements.otherDependencies);
    }

    // TODO(sigurdm): How is metadata on a patch-class handled?
    for (MetadataAnnotation metadata in element.metadata) {
      Constant constant = backend.constants.getConstantForMetadata(metadata);
      if (constant != null) {
        addConstants(constant);
      }
    }
    if (element.isClass) {
      // If we see a class, add everything its live instance members refer
      // to.  Static members are not relevant, unless we are processing
      // extra dependencies due to mirrors.
      void addLiveInstanceMember(Element element) {
        if (!compiler.enqueuer.resolution.isLive(element)) return;
        if (!isMirrorUsage && !element.isInstanceMember) return;
        collectDependencies(element.implementation);
      }
      ClassElement cls = element.declaration;
      cls.forEachLocalMember(addLiveInstanceMember);
      if (cls.implementation != cls) {
        // TODO(ahe): Why doesn't ClassElement.forEachLocalMember do this?
        cls.implementation.forEachLocalMember(addLiveInstanceMember);
      }
      for (var type in cls.implementation.allSupertypes) {
        elements.add(type.element.implementation);
      }
      elements.add(cls.implementation);
    } else if (Elements.isStaticOrTopLevel(element) ||
               element.isConstructor) {
      collectDependencies(element);
    }
    if (element.isGenerativeConstructor) {
      // When instantiating a class, we record a reference to the
      // constructor, not the class itself.  We must add all the
      // instance members of the constructor's class.
      ClassElement implementation =
          element.enclosingClass.implementation;
      _collectAllElementsAndConstantsResolvedFrom(
          implementation, elements, constants, isMirrorUsage);
    }

    // Other elements, in particular instance members, are ignored as
    // they are processed as part of the class.
  }

  /// Returns the transitive closure of all libraries that are imported
  /// from root without DeferredLibrary annotations.
  Set<LibraryElement> _nonDeferredReachableLibraries(LibraryElement root) {
    Set<LibraryElement> result = new Set<LibraryElement>();

    void traverseLibrary(LibraryElement library) {
      if (result.contains(library)) return;
      result.add(library);

      iterateTags(LibraryElement library) {
        // TODO(sigurdm): Make helper getLibraryDependencyTags when tags is
        // changed to be a List instead of a Link.
        for (LibraryTag tag in library.tags) {
          if (tag is! LibraryDependency) continue;
          LibraryDependency libraryDependency = tag;
          if (!(libraryDependency is Import
              && _isImportDeferred(libraryDependency))) {
            LibraryElement importedLibrary = library.getLibraryFromTag(tag);
            traverseLibrary(importedLibrary);
          }
        }
      }

      iterateTags(library);
      if (library.isPatched) {
        iterateTags(library.implementation);
      }
    }
    traverseLibrary(root);
    result.add(compiler.coreLibrary);
    return result;
  }

  /// Recursively traverses the graph of dependencies from [element], mapping
  /// deferred imports to each dependency it needs in the sets
  /// [_importedDeferredBy] and [_constantsDeferredBy].
  void _mapDependencies(Element element, Import import,
                        {isMirrorUsage: false}) {
    Set<Element> elements = _importedDeferredBy.putIfAbsent(import,
        () => new Set<Element>());
    Set<Constant> constants = _constantsDeferredBy.putIfAbsent(import,
        () => new Set<Constant>());

    // Only process elements once, unless we are doing dependencies due to
    // mirrors, which are added in additional traversals.
    if (!isMirrorUsage && elements.contains(element)) return;
    // Anything used directly by main will be loaded from the start
    // We do not need to traverse it again.
    if (import != _fakeMainImport && _mainElements.contains(element)) return;

    // Here we modify [_importedDeferredBy].
    elements.add(element);

    Set<Element> dependentElements = new Set<Element>();

    // This call can modify [_importedDeferredBy] and [_constantsDeferredBy].
    _collectAllElementsAndConstantsResolvedFrom(
        element, dependentElements, constants, isMirrorUsage);

    LibraryElement library = element.library;
    for (Element dependency in dependentElements) {
      if (_isExplicitlyDeferred(dependency, library)) {
        for (Import deferredImport in _getImports(dependency, library)) {
          _mapDependencies(dependency, deferredImport);
        };
      } else {
        _mapDependencies(dependency, import);
      }
    }
  }

  /// Adds extra dependencies coming from mirror usage.
  ///
  /// The elements are added with [_mapDependencies].
  void _addMirrorElements() {
    void mapDependenciesIfResolved(Element element, Import deferredImport) {
      // If an element is the target of a MirrorsUsed annotation but never used
      // It will not be resolved, and we should not call isNeededForReflection.
      // TODO(sigurdm): Unresolved elements should just answer false when
      // asked isNeededForReflection. Instead an internal error is triggered.
      // So we have to filter them out here.
      if (element is AnalyzableElementX && !element.hasTreeElements) return;
      if (compiler.backend.isAccessibleByReflection(element)) {
        _mapDependencies(element, deferredImport, isMirrorUsage: true);
      }
    }

    // For each deferred import we analyze all elements reachable from the
    // imported library through non-deferred imports.
    handleLibrary(LibraryElement library, Import deferredImport) {
      library.implementation.forEachLocalMember((Element element) {
        mapDependenciesIfResolved(element, deferredImport);
      });

      for (MetadataAnnotation metadata in library.metadata) {
        Constant constant =
            backend.constants.getConstantForMetadata(metadata);
        if (constant != null) {
          _mapDependencies(constant.computeType(compiler).element,
              deferredImport);
        }
      }
      for (LibraryTag tag in library.tags) {
        for (MetadataAnnotation metadata in tag.metadata) {
          Constant constant =
              backend.constants.getConstantForMetadata(metadata);
          if (constant != null) {
            _mapDependencies(constant.computeType(compiler).element,
                deferredImport);
          }
        }
      }
    }

    for (Import deferredImport in _allDeferredImports.keys) {
      LibraryElement deferredLibrary = _allDeferredImports[deferredImport];
      for (LibraryElement library in
          _nonDeferredReachableLibraries(deferredLibrary)) {
        handleLibrary(library, deferredImport);
      }
    }
  }

  /// Computes a unique string for the name field for each outputUnit.
  ///
  /// Also sets up the [hunksToLoad] mapping.
  void _assignNamesToOutputUnits(Set<OutputUnit> allOutputUnits) {
    Set<String> usedImportNames = new Set<String>();

    // Finds the first argument to the [DeferredLibrary] annotation
    void computeImportDeferName(Import import) {
      String result;
      if (import == _fakeMainImport) {
        result = "main";
      } else if (import.isDeferred) {
        result = import.prefix.toString();
      } else {
        Link<MetadataAnnotation> metadatas = import.metadata;
        assert(metadatas != null);
        for (MetadataAnnotation metadata in metadatas) {
          metadata.ensureResolved(compiler);
          Element element = metadata.value.computeType(compiler).element;
          if (element == deferredLibraryClass) {
            ConstructedConstant constant = metadata.value;
            StringConstant s = constant.fields[0];
            result = s.value.slowToString();
            break;
          }
        }
      }
      assert(result != null);
      importDeferName[import] = makeUnique(result, usedImportNames);;
    }

    int counter = 1;

    for (Import import in _allDeferredImports.keys) {
      computeImportDeferName(import);
    }

    for (OutputUnit outputUnit in allOutputUnits) {
      if (outputUnit == mainOutputUnit) {
        outputUnit.name = "main";
      } else {
        outputUnit.name = "$counter";
        ++counter;
      }
    }

    List sortedOutputUnits = new List.from(allOutputUnits);
    // Sort the output units in descending order of the number of imports they
    // include.

    // The loading of the output units mut be ordered because a superclass needs
    // to be initialized before its subclass.
    // But a class can only depend on another class in an output unit shared by
    // a strict superset of the imports:
    // By contradiction: Assume a class C in output unit shared by imports in
    // the set S1 = (lib1,.., lib_n) depends on a class D in an output unit
    // shared by S2 such that S2 not a superset of S1. Let lib_s be a library in
    // S1 not in S2. lib_s must depend on C, and then in turn on D therefore D
    // is not in the right output unit.
    sortedOutputUnits.sort((a, b) => b.imports.length - a.imports.length);

    // For each deferred import we find out which outputUnits to load.
    for (Import import in _allDeferredImports.keys) {
      if (import == _fakeMainImport) continue;
      hunksToLoad[importDeferName[import]] = new List<List<OutputUnit>>();
      int lastNumberOfImports = 0;
      List<OutputUnit> currentLastList;
      for (OutputUnit outputUnit in sortedOutputUnits) {
        if (outputUnit == mainOutputUnit) continue;
        if (outputUnit.imports.contains(import)) {
          if (outputUnit.imports.length != lastNumberOfImports) {
            lastNumberOfImports = outputUnit.imports.length;
            currentLastList = new List<OutputUnit>();
            hunksToLoad[importDeferName[import]].add(currentLastList);
          }
          currentLastList.add(outputUnit);
        }
      }
    }
  }

  void onResolutionComplete(FunctionElement main) {
    if (!isProgramSplit) {
      allOutputUnits.add(mainOutputUnit);
      return;
    }
    if (main == null) return;
    LibraryElement mainLibrary = main.library;
    _importedDeferredBy = new Map<Import, Set<Element>>();
    _constantsDeferredBy = new Map<Import, Set<Constant>>();
    _importedDeferredBy[_fakeMainImport] = _mainElements;

    measureElement(mainLibrary, () {

      // Starting from main, traverse the program and find all dependencies.
      _mapDependencies(compiler.mainFunction, _fakeMainImport);

      // Also add "global" dependencies to the main OutputUnit.  These are
      // things that the backend need but cannot associate with a particular
      // element, for example, startRootIsolate.  This set also contains
      // elements for which we lack precise information.
      for (Element element in compiler.globalDependencies.otherDependencies) {
        _mapDependencies(element, _fakeMainImport);
      }

      // Now check to see if we have to add more elements due to mirrors.
      if (compiler.mirrorsLibrary != null) {
        _addMirrorElements();
      }

      Set<Constant> allConstants = new Set<Constant>();
      // Reverse the mapping. For each element record an OutputUnit collecting
      // all deferred imports using this element. Same for constants.
      for (Import import in _importedDeferredBy.keys) {
        for (Element element in _importedDeferredBy[import]) {
          _addImportToOutputUnitOfElement(element, import);
        }
        for (Constant constant in _constantsDeferredBy[import]) {
          allConstants.add(constant);
          _addImportToOutputUnitOfConstant(constant, import);
        }
      }

      // Release maps;
      _importedDeferredBy = null;
      _constantsDeferredBy = null;

      // Find all the output units we have used.
      // Also generate a unique name for each OutputUnit.
      for (OutputUnit outputUnit in _elementToOutputUnit.values) {
        allOutputUnits.add(outputUnit);
      }
      for (OutputUnit outputUnit in _constantToOutputUnit.values) {
        allOutputUnits.add(outputUnit);
      }

      _assignNamesToOutputUnits(allOutputUnits);
    });
  }

  void ensureMetadataResolved(Compiler compiler) {
    if (compiler.mainApp == null) return;
    _allDeferredImports[_fakeMainImport] = compiler.mainApp;
    var lastDeferred;
    // When detecting duplicate prefixes of deferred libraries there are 4
    // cases of duplicate prefixes:
    // 1.
    // import "lib.dart" deferred as a;
    // import "lib2.dart" deferred as a;
    // 2.
    // import "lib.dart" deferred as a;
    // import "lib2.dart" as a;
    // 3.
    // import "lib.dart" as a;
    // import "lib2.dart" deferred as a;
    // 4.
    // import "lib.dart" as a;
    // import "lib2.dart" as a;
    // We must be able to signal error for case 1, 2, 3, but accept case 4.

    // The prefixes that have been used by any imports in this library.
    Setlet<String> usedPrefixes = new Setlet<String>();
    // The last deferred import we saw with a given prefix (if any).
    Map<String, Import> prefixDeferredImport = new Map<String, Import>();
    for (LibraryElement library in compiler.libraryLoader.libraries) {
      compiler.withCurrentElement(library, () {
        prefixDeferredImport.clear();
        usedPrefixes.clear();
        // TODO(sigurdm): Make helper getLibraryImportTags when tags is a List
        // instead of a Link.
        for (LibraryTag tag in library.tags) {
          if (tag is! Import) continue;
          Import import = tag;
          _markIfDeferred(import, library);
          String prefix = (import.prefix != null)
              ? import.prefix.toString()
              : null;
          // The last import we saw with the same prefix.
          Import previousDeferredImport = prefixDeferredImport[prefix];
          bool isDeferred = _isImportDeferred(import);
          if (isDeferred) {
            if (prefix == null) {
              compiler.reportError(import,
                  MessageKind.DEFERRED_LIBRARY_WITHOUT_PREFIX);
            } else {
              prefixDeferredImport[prefix] = import;
            }
            isProgramSplit = true;
            lastDeferred = import;
          }
          if (prefix != null) {
            if (previousDeferredImport != null ||
                (isDeferred && usedPrefixes.contains(prefix))) {
              Import failingImport = (previousDeferredImport != null)
                  ? previousDeferredImport
                  : import;
              compiler.reportError(failingImport.prefix,
                  MessageKind.DEFERRED_LIBRARY_DUPLICATE_PREFIX);
            }
            usedPrefixes.add(prefix);
          }
        }
      });
    }
    Backend backend = compiler.backend;
    if (isProgramSplit && backend is JavaScriptBackend) {
      backend.registerCheckDeferredIsLoaded(compiler.globalDependencies);
    }
    if (isProgramSplit && backend is DartBackend) {
      // TODO(sigurdm): Implement deferred loading for dart2dart.
      compiler.reportWarning(
          lastDeferred,
          MessageKind.DEFERRED_LIBRARY_DART_2_DART);
      isProgramSplit = false;
    }
  }

  /// If [send] is a static send with a deferred element, returns the
  /// [PrefixElement] that the first prefix of the send resolves to.
  /// Otherwise returns null.
  ///
  /// Precondition: send must be static.
  ///
  /// Example:
  ///
  /// import "a.dart" deferred as a;
  ///
  /// main() {
  ///   print(a.loadLibrary.toString());
  ///   a.loadLibrary().then((_) {
  ///     a.run();
  ///     a.foo.method();
  ///   });
  /// }
  ///
  /// Returns null for a.loadLibrary() (the special
  /// function loadLibrary is not deferred). And returns the PrefixElement for
  /// a.run() and a.foo.
  /// a.loadLibrary.toString() and a.foo.method() are dynamic sends - and
  /// this functions should not be called on them.
  PrefixElement deferredPrefixElement(ast.Send send, TreeElements elements) {
    Element element = elements[send];
    // The DeferredLoaderGetter is not deferred, therefore we do not return the
    // prefix.
    if (element != null && element.isDeferredLoaderGetter) return null;

    ast.Node firstNode(ast.Node node) {
      if (node is! ast.Send) {
        return node;
      } else {
        ast.Send send = node;
        ast.Node receiver = send.receiver;
        ast.Node receiverFirst = firstNode(receiver);
        if (receiverFirst != null) {
          return receiverFirst;
        } else {
          return firstNode(send.selector);
        }
      }
    }
    ast.Node first = firstNode(send);
    ast.Node identifier = first.asIdentifier();
    if (identifier == null) return null;
    Element maybePrefix = elements[identifier];
    if (maybePrefix != null && maybePrefix.isPrefix) {
      PrefixElement prefixElement = maybePrefix;
      if (prefixElement.isDeferred) {
        return prefixElement;
      }
    }
    return null;
  }
}
