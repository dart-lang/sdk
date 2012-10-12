// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [CompilerTask] for loading libraries and setting up the import/export scopes.
 */
abstract class LibraryLoader extends CompilerTask {
  LibraryLoader(Compiler compiler) : super(compiler);

  /**
   * Loads the library located at [uri] and returns its [LibraryElement].
   *
   * If the library is not already loaded, the method creates the
   * [LibraryElement] for the library and computes the import/export scope,
   * loading and computing the import/export scopes of all required libraries in
   * the process. The method handles cyclic dependency between libraries.
   *
   * This is the main entry point for [LibraryLoader].
   */
  abstract LibraryElement loadLibrary(Uri uri, Node node, Uri canonicalUri);

  // TODO(johnniwinther): Remove this when patches don't need special parsing.
  abstract void registerLibraryFromTag(LibraryDependencyHandler handler,
                                       LibraryElement library,
                                       LibraryDependency tag);

  /**
   * Adds the elements in the export scope of [importedLibrary] to the import
   * scope of [importingLibrary].
   */
  // TODO(johnniwinther): Move handling of 'js_helper' to the library loader
  // to remove this method from the [LibraryLoader] interface.
  abstract void importLibrary(LibraryElement importingLibrary,
                              LibraryElement importedLibrary,
                              Import tag);
}

/**
 * [CombinatorFilter] is a succinct representation of a list of combinators from
 * a library dependency tag.
 */
class CombinatorFilter {
  const CombinatorFilter();

  /**
   * Returns [:true:] if [element] is excluded by this filter.
   */
  bool exclude(Element element) => false;

  /**
   * Creates a filter based on the combinators of [tag].
   */
  factory CombinatorFilter.fromTag(LibraryDependency tag) {
    if (tag == null || tag.combinators == null) {
      return const CombinatorFilter();
    }

    // If the list of combinators contain at least one [:show:] we can create
    // a positive list of elements to include, otherwise we create a negative
    // list of elements to exclude.
    bool show = false;
    Set<SourceString> nameSet;
    for (Combinator combinator in tag.combinators) {
      if (combinator.isShow) {
        show = true;
        var set = new Set<SourceString>();
        for (Identifier identifier in combinator.identifiers) {
          set.add(identifier.source);
        }
        if (nameSet == null) {
          nameSet = set;
        } else {
          nameSet = nameSet.intersection(set);
        }
      }
    }
    if (nameSet == null) {
      nameSet = new Set<SourceString>();
    }
    for (Combinator combinator in tag.combinators) {
      if (combinator.isHide) {
        for (Identifier identifier in combinator.identifiers) {
          if (show) {
            // We have a positive list => Remove hidden elements.
            nameSet.remove(identifier.source);
          } else {
            // We have no positive list => Accumulate hidden elements.
            nameSet.add(identifier.source);
          }
        }
      }
    }
    return show ? new ShowFilter(nameSet) : new HideFilter(nameSet);
  }
}

/**
 * A list of combinators represented as a list of element names to include.
 */
class ShowFilter extends CombinatorFilter {
  final Set<SourceString> includedNames;

  ShowFilter(this.includedNames);

  bool exclude(Element element) => !includedNames.contains(element.name);
}

/**
 * A list of combinators represented as a list of element names to exclude.
 */
class HideFilter extends CombinatorFilter {
  final Set<SourceString> excludedNames;

  HideFilter(this.excludedNames);

  bool exclude(Element element) => excludedNames.contains(element.name);
}

/**
 * Implementation class for [LibraryLoader]. The distinction between
 * [LibraryLoader] and [LibraryLoaderTask] is made to hide internal members from
 * the [LibraryLoader] interface.
 */
class LibraryLoaderTask extends LibraryLoader {
  LibraryLoaderTask(Compiler compiler) : super(compiler);
  String get name => 'LibraryLoader';

  final Map<String, LibraryElement> libraryNames =
      new Map<String, LibraryElement>();

  LibraryDependencyHandler currentHandler;

  LibraryElement loadLibrary(Uri uri, Node node, Uri canonicalUri) {
    return measure(() {
      assert(currentHandler == null);
      currentHandler = new LibraryDependencyHandler(compiler);
      LibraryElement library =
          createLibrary(currentHandler, uri, node, canonicalUri);
      currentHandler.computeExports();
      currentHandler = null;
      return library;
    });
  }

  /**
   * Processes the library tags in [library].
   *
   * The imported/exported libraries are loaded and processed recursively but
   * the import/export scopes are not set up.
   */
  void processLibraryTags(LibraryDependencyHandler handler,
                          LibraryElement library) {
    int tagState = TagState.NO_TAG_SEEN;

    /**
     * If [value] is less than [tagState] complain and return
     * [tagState]. Otherwise return the new value for [tagState]
     * (transition function for state machine).
     */
    int checkTag(int value, LibraryTag tag) {
      if (tagState > value) {
        compiler.reportError(tag, 'out of order');
        return tagState;
      }
      return TagState.NEXT[value];
    }

    bool importsDartCore = false;
    var libraryDependencies = new LinkBuilder<LibraryDependency>();
    Uri base = library.entryCompilationUnit.script.uri;
    for (LibraryTag tag in library.tags.reverse()) {
      if (tag.isImport) {
        tagState = checkTag(TagState.IMPORT_OR_EXPORT, tag);
        if (tag.uri.dartString.slowToString() == 'dart:core') {
          importsDartCore = true;
        }
        libraryDependencies.addLast(tag);
      } else if (tag.isExport) {
        tagState = checkTag(TagState.IMPORT_OR_EXPORT, tag);
        libraryDependencies.addLast(tag);
      } else if (tag.isLibraryName) {
        tagState = checkTag(TagState.LIBRARY, tag);
        if (library.libraryTag !== null) {
          compiler.cancel("duplicated library declaration", node: tag);
        } else {
          library.libraryTag = tag;
        }
        checkDuplicatedLibraryName(library);
      } else if (tag.isPart) {
        StringNode uri = tag.uri;
        Uri resolved = base.resolve(uri.dartString.slowToString());
        tagState = checkTag(TagState.SOURCE, tag);
        scanPart(tag, resolved, library);
      } else {
        compiler.internalError("Unhandled library tag.", node: tag);
      }
    }

    // Apply patch, if any.
    if (library.uri.scheme == 'dart') {
      patchDartLibrary(handler, library, library.uri.path);
    }

    // Import dart:core if not already imported.
    if (!importsDartCore && !isDartCore(library.uri)) {
      handler.registerDependency(library, null, loadCoreLibrary(handler));
    }

    for (LibraryDependency tag in libraryDependencies.toLink()) {
      registerLibraryFromTag(handler, library, tag);
    }
  }

  void checkDuplicatedLibraryName(LibraryElement library) {
    LibraryName tag = library.libraryTag;
    if (tag != null) {
      String name = library.getLibraryOrScriptName();
      LibraryElement existing =
          libraryNames.putIfAbsent(name, () => library);
      if (existing !== library) {
        Uri uri = library.entryCompilationUnit.script.uri;
        compiler.reportMessage(
            compiler.spanFromNode(tag.name, uri),
            MessageKind.DUPLICATED_LIBRARY_NAME.error([name]),
            api.Diagnostic.WARNING);
        Uri existingUri = existing.entryCompilationUnit.script.uri;
        compiler.reportMessage(
            compiler.spanFromNode(existing.libraryTag.name, existingUri),
            MessageKind.DUPLICATED_LIBRARY_NAME.error([name]),
            api.Diagnostic.WARNING);
      }
    }
  }

  bool isDartCore(Uri uri) => uri.scheme == "dart" && uri.path == "core";

  /**
   * Lazily loads and returns the [LibraryElement] for the dart:core library.
   */
  LibraryElement loadCoreLibrary(LibraryDependencyHandler handler) {
    if (compiler.coreLibrary === null) {
      Uri coreUri = new Uri.fromComponents(scheme: 'dart', path: 'core');
      compiler.coreLibrary = createLibrary(handler, coreUri, null, coreUri);
    }
    return compiler.coreLibrary;
  }

  void patchDartLibrary(LibraryDependencyHandler handler,
                        LibraryElement library, String dartLibraryPath) {
    if (library.isPatched) return;
    Uri patchUri = compiler.resolvePatchUri(dartLibraryPath);
    if (patchUri !== null) {
      compiler.patchParser.patchLibrary(handler, patchUri, library);
    }
  }

  /**
   * Handle a part tag in the scope of [library]. The [path] given is used as
   * is, any URI resolution should be done beforehand.
   */
  void scanPart(Part part, Uri path, LibraryElement library) {
    if (!path.isAbsolute()) throw new ArgumentError(path);
    Script sourceScript = compiler.readScript(path, part);
    CompilationUnitElement unit =
        new CompilationUnitElement(sourceScript, library);
    compiler.withCurrentElement(unit, () => compiler.scanner.scan(unit));
  }

  /**
   * Handle an import/export tag by loading the referenced library and
   * registering its dependency in [handler] for the computation of the import/
   * export scope.
   */
  void registerLibraryFromTag(LibraryDependencyHandler handler,
                              LibraryElement library,
                              LibraryDependency tag) {
    Uri base = library.entryCompilationUnit.script.uri;
    Uri resolved = base.resolve(tag.uri.dartString.slowToString());
    LibraryElement loadedLibrary =
        createLibrary(handler, resolved, tag.uri, resolved);
    handler.registerDependency(library, tag, loadedLibrary);

    if (!loadedLibrary.hasLibraryName()) {
      compiler.withCurrentElement(library, () {
        compiler.reportError(tag === null ? null : tag.uri,
            'no library name found in ${loadedLibrary.uri}');
      });
    }
  }

  /**
   * Create (or reuse) a library element for the library located at [uri].
   * If a new library is created, the [handler] is notified.
   */
  LibraryElement createLibrary(LibraryDependencyHandler handler,
                               Uri uri, Node node, Uri canonicalUri) {
    bool newLibrary = false;
    LibraryElement createLibrary() {
      newLibrary = true;
      Script script = compiler.readScript(uri, node);
      LibraryElement element = new LibraryElement(script, canonicalUri);
      handler.registerNewLibrary(element);
      native.maybeEnableNative(compiler, element, uri);
      return element;
    }
    LibraryElement library;
    if (canonicalUri === null) {
      library = createLibrary();
    } else {
      library = compiler.libraries.putIfAbsent(canonicalUri.toString(),
                                               createLibrary);
    }
    if (newLibrary) {
      compiler.withCurrentElement(library, () {
        compiler.scanner.scanLibrary(library);
        processLibraryTags(handler, library);
        handler.registerLibraryExports(library);
        compiler.onLibraryScanned(library, uri);
      });
    }
    return library;
  }

  // TODO(johnniwinther): Remove this method when 'js_helper' is handled by
  // [LibraryLoaderTask].
  void importLibrary(LibraryElement importingLibrary,
                     LibraryElement importedLibrary,
                     Import tag) {
    new ImportLink(tag, importedLibrary).importLibrary(compiler,
                                                       importingLibrary);
  }
}


/**
 * The fields of this class models a state machine for checking script
 * tags come in the correct order.
 */
class TagState {
  static const int NO_TAG_SEEN = 0;
  static const int LIBRARY = 1;
  static const int IMPORT_OR_EXPORT = 2;
  static const int SOURCE = 3;
  static const int RESOURCE = 4;

  /** Next state. */
  static const List<int> NEXT =
      const <int>[NO_TAG_SEEN,
                  IMPORT_OR_EXPORT, // Only one library tag is allowed.
                  IMPORT_OR_EXPORT,
                  SOURCE,
                  RESOURCE];
}

/**
 * An [import] tag and the [importedLibrary] imported through [import].
 */
class ImportLink {
  final Import import;
  final LibraryElement importedLibrary;

  ImportLink(this.import, this.importedLibrary);

  /**
   * Imports the library into the [importingLibrary].
   */
  void importLibrary(Compiler compiler, LibraryElement importingLibrary) {
    assert(invariant(importingLibrary,
                     importedLibrary.exportsHandled,
                     message: 'Exports not handled on $importedLibrary'));
    var combinatorFilter = new CombinatorFilter.fromTag(import);
    if (import !== null && import.prefix !== null) {
      SourceString prefix = import.prefix.source;
      Element e = importingLibrary.find(prefix);
      if (e === null) {
        e = new PrefixElement(prefix, importingLibrary.entryCompilationUnit,
                              import.getBeginToken());
        importingLibrary.addToScope(e, compiler);
      }
      if (e.kind !== ElementKind.PREFIX) {
        compiler.withCurrentElement(e, () {
          compiler.reportWarning(new Identifier(e.position()),
          'duplicated definition');
        });
        compiler.reportError(import.prefix, 'duplicate definition');
      }
      PrefixElement prefixElement = e;
      importedLibrary.forEachExport((Element element) {
        if (combinatorFilter.exclude(element)) return;
        // TODO(johnniwinther): Clean-up like [checkDuplicateLibraryName].
        Element existing =
            prefixElement.imported.putIfAbsent(element.name, () => element);
        if (existing !== element) {
          compiler.withCurrentElement(existing, () {
            compiler.reportWarning(new Identifier(existing.position()),
            'duplicated import');
          });
          compiler.withCurrentElement(element, () {
            compiler.reportError(new Identifier(element.position()),
            'duplicated import');
          });
        }
      });
    } else {
      importedLibrary.forEachExport((Element element) {
        compiler.withCurrentElement(element, () {
          if (combinatorFilter.exclude(element)) return;
          importingLibrary.addImport(element, compiler);
        });
      });
    }
  }
}

/**
 * The combinator filter computed from an export tag and the library dependency
 * node for the library that declared the export tag. This represents an edge in
 * the library dependency graph.
 */
class ExportLink {
  final CombinatorFilter combinatorFilter;
  final LibraryDependencyNode exportNode;

  ExportLink(Export export, LibraryDependencyNode this.exportNode)
      : this.combinatorFilter = new CombinatorFilter.fromTag(export);

  /**
   * Exports [element] to the dependent library unless [element] is filtered by
   * the export combinators. Returns [:true:] if the set pending exports of the
   * dependent library was modified.
   */
  bool exportElement(Element element) {
    if (combinatorFilter.exclude(element)) return false;
    return exportNode.addElementToPendingExports(element);
  }
}

/**
 * A node in the library dependency graph.
 *
 * This class is used to collect the library dependencies expressed through
 * import and export tags, and as the work-list entry in computations of library
 * exports performed in [LibraryDependencyHandler.computeExports].
 */
class LibraryDependencyNode {
  final LibraryElement library;

  /**
   * A linked list of the import tags that import [library] mapped to the
   * corresponding libraries. This is used to propagate exports into imports
   * after the export scopes have been computed.
   */
  Link<ImportLink> imports = const Link<ImportLink>();

  /**
   * A linked list of the export tags the dependent upon this node library.
   * This is used to propagate exports during the computation of export scopes.
   */
  Link<ExportLink> dependencies = const Link<ExportLink>();

  /**
   * The export scope for [library] which is gradually computed by the work-list
   * computation in [LibraryDependencyHandler.computeExports].
   */
  Map<SourceString, Element> exportScope = new Map<SourceString, Element>();

  /**
   * The set of exported elements that need to be propageted to dependent
   * libraries as part of the work-list computation performed in
   * [LibraryDependencyHandler.computeExports].
   */
  Set<Element> pendingExportSet = new Set<Element>();

  LibraryDependencyNode(LibraryElement this.library);

  /**
   * Registers that the library of this node imports [importLibrary] through the
   * [import] tag.
   */
  void registerImportDependency(Import import,
                                LibraryElement importedLibrary) {
    imports = imports.prepend(new ImportLink(import, importedLibrary));
  }

  /**
   * Registers that the library of this node is exported by
   * [exportingLibraryNode] through the [export] tag.
   */
  void registerExportDependency(Export export,
                                LibraryDependencyNode exportingLibraryNode) {
    dependencies =
        dependencies.prepend(new ExportLink(export, exportingLibraryNode));
  }

  /**
   * Registers all non-private locally declared members of the library of this
   * node to be exported. This forms the basis for the work-list computation of
   * the export scopes performed in [LibraryDependencyHandler.computeExports].
   */
  void registerInitialExports() {
    pendingExportSet.addAll(
        library.localScope.getValues().filter((Element element) {
          // At this point [localScope] only contains members so we don't need
          // to check for foreign or prefix elements.
          return !element.name.isPrivate();
        }));
  }

  /**
   * Registers the compute export scope with the node library.
   */
  void registerExports() {
    library.setExports(exportScope.getValues());
  }

  /**
   * Registers the imports of the node library.
   */
  void registerImports(Compiler compiler) {
    for (ImportLink link in imports) {
      link.importLibrary(compiler, library);
    }
  }

  /**
   * Copies and clears pending export set for this node.
   */
  List<Element> pullPendingExports() {
    List<Element> pendingExports = new List.from(pendingExportSet);
    pendingExportSet.clear();
    return pendingExports;
  }

  /**
   * Adds [element] to the export scope for this node. If the [element] name
   * is a duplicate, an error element is inserted into the export scope.
   */
  Element addElementToExportScope(Compiler compiler, Element element) {
    SourceString name = element.name;
    Element existingElement = exportScope[name];
    if (existingElement !== null) {
      if (existingElement.getLibrary() != library) {
        // Declared elements hide exported elements.
        element = exportScope[name] = new ErroneousElement(
            MessageKind.DUPLICATE_EXPORT, [name], name, library);
      }
    } else {
      exportScope[name] = element;
    }
    return element;
  }

  /**
   * Propagates the exported [element] to all library nodes that depend upon
   * this node. If the propagation updated any pending exports, [:true:] is
   * returned.
   */
  bool propagateElement(Element element) {
    bool change = false;
    for (ExportLink link in dependencies) {
      if (link.exportElement(element)) {
        change = true;
      }
    }
    return change;
  }

  /**
   * Adds [element] to the pending exports of this node and returns [:true:] if
   * the pending export set was modified. The combinators of [export] are used
   * to filter the element.
   */
  bool addElementToPendingExports(Element element) {
    if (exportScope[element.name] !== element) {
      if (!pendingExportSet.contains(element)) {
        pendingExportSet.add(element);
        return true;
      }
    }
    return false;
  }
}

/**
 * Helper class used for computing the possibly cyclic import/export scopes of
 * a set of libraries.
 *
 * This class is used by [ScannerTask.loadLibrary] to collect all newly loaded
 * libraries and to compute their import/export scopes through a fixed-point
 * algorithm.
 */
class LibraryDependencyHandler {
  final Compiler compiler;

  /**
   * Newly loaded libraries and their corresponding node in the library
   * dependency graph. Libraries that have already been fully loaded are not
   * part of the dependency graph of this handler since their export scopes have
   * already been computed.
   */
  Map<LibraryElement,LibraryDependencyNode> nodeMap =
      new Map<LibraryElement,LibraryDependencyNode>();

  LibraryDependencyHandler(Compiler this.compiler);

  /**
   * Performs a fixed-point computation on the export scopes of all registered
   * libraries and creates the import/export of the libraries based on the
   * fixed-point.
   */
  void computeExports() {
    bool changed = true;
    while (changed) {
      changed = false;
      nodeMap.forEach((_, LibraryDependencyNode node) {
        var pendingExports = node.pullPendingExports();
        pendingExports.forEach((Element element) {
          element = node.addElementToExportScope(compiler, element);
          if (node.propagateElement(element)) {
            changed = true;
          }
        });
      });
    }

    // Setup export scopes. These have to be set before computing the import
    // scopes to avoid accessing uncomputed export scopes during handling of
    // imports.
    nodeMap.forEach((LibraryElement library, LibraryDependencyNode node) {
      node.registerExports();
    });

    // Setup import scopes.
    nodeMap.forEach((LibraryElement library, LibraryDependencyNode node) {
      node.registerImports(compiler);
    });
  }

  /**
   * Registers that [library] depends on [loadedLibrary] through [tag].
   */
  void registerDependency(LibraryElement library,
                          LibraryDependency tag,
                          LibraryElement loadedLibrary) {
    if (tag is Export) {
      // [loadedLibrary] is exported by [library].
      if (loadedLibrary.exportsHandled) {
        // Export scope already computed on [loadedLibrary].
        return;
      }
      LibraryDependencyNode exportedNode = nodeMap[loadedLibrary];
      LibraryDependencyNode exportingNode = nodeMap[library];
      assert(invariant(loadedLibrary, exportedNode != null,
          message: "$loadedLibrary has not been registered"));
      assert(invariant(library, exportingNode != null,
          message: "$library has not been registered"));
      exportedNode.registerExportDependency(tag, exportingNode);
    } else if (tag == null || tag is Import) {
      // [loadedLibrary] is imported by [library].
      LibraryDependencyNode importingNode = nodeMap[library];
      assert(invariant(library, importingNode != null,
          message: "$library has not been registered"));
      importingNode.registerImportDependency(tag, loadedLibrary);
    }
  }

  /**
   * Registers [library] for the processing of its import/export scope.
   */
  void registerNewLibrary(LibraryElement library) {
    nodeMap[library] = new LibraryDependencyNode(library);
  }

  /**
   * Registers all top-level entities of [library] as starting point for the
   * fixed-point computation of the import/export scopes.
   */
  void registerLibraryExports(LibraryElement library) {
    nodeMap[library].registerInitialExports();
  }
}
