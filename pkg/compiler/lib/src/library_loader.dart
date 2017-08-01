// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.library_loader;

import 'dart:async';

import 'package:front_end/front_end.dart' as fe;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/kernel.dart' hide LibraryDependency, Combinator;
import 'package:kernel/target/targets.dart';

import '../compiler_new.dart' as api;
import 'kernel/front_end_adapter.dart';
import 'kernel/dart2js_target.dart' show Dart2jsTarget;

import 'common/names.dart' show Uris;
import 'common/tasks.dart' show CompilerTask, Measurer;
import 'common.dart';
import 'elements/elements.dart'
    show
        CompilationUnitElement,
        Element,
        ImportElement,
        ExportElement,
        LibraryElement;
import 'elements/entities.dart' show LibraryEntity;
import 'elements/modelx.dart'
    show
        CompilationUnitElementX,
        DeferredLoaderGetterElementX,
        ErroneousElementX,
        ExportElementX,
        ImportElementX,
        LibraryElementX,
        LibraryDependencyElementX,
        PrefixElementX,
        SyntheticImportElement;
import 'enqueue.dart' show DeferredAction;
import 'environment.dart';
import 'io/source_file.dart' show Binary;
import 'kernel/element_map_impl.dart' show KernelToElementMapForImpactImpl;
import 'patch_parser.dart' show PatchParserTask;
import 'resolved_uri_translator.dart';
import 'script.dart';
import 'serialization/serialization.dart' show LibraryDeserializer;
import 'tree/tree.dart';
import 'util/util.dart' show Link, LinkBuilder;

typedef Future<Iterable<LibraryElement>> ReuseLibrariesFunction(
    Iterable<LibraryElement> libraries);

typedef Uri PatchResolverFunction(String dartLibraryPath);

/**
 * [CompilerTask] for loading libraries and setting up the import/export scopes.
 *
 * The library loader uses four different kinds of URIs in different parts of
 * the loading process.
 *
 * ## User URI ##
 *
 * A 'user URI' is a URI provided by the user in code and as the main entry URI
 * at the command line. These generally come in 3 versions:
 *
 *   * A relative URI such as 'foo.dart', '../bar.dart', and 'baz/boz.dart'.
 *
 *   * A dart URI such as 'dart:core' and 'dart:_js_helper'.
 *
 *   * A package URI such as 'package:foo.dart' and 'package:bar/baz.dart'.
 *
 * A user URI can also be absolute, like 'file:///foo.dart' or
 * 'http://example.com/bar.dart', but such URIs cannot necessarily be used for
 * locating source files, since the scheme must be supported by the input
 * provider. The standard input provider for dart2js only supports the 'file'
 * and 'http' scheme.
 *
 * ## Resolved URI ##
 *
 * A 'resolved URI' is a (user) URI that has been resolved to an absolute URI
 * based on the readable URI (see below) from which it was loaded. A URI with an
 * explicit scheme (such as 'dart:', 'package:' or 'file:') is already resolved.
 * A relative URI like for instance '../foo/bar.dart' is translated into an
 * resolved URI in one of three ways:
 *
 *  * If provided as the main entry URI at the command line, the URI is resolved
 *    relative to the current working directory, say
 *    'file:///current/working/dir/', and the resolved URI is therefore
 *    'file:///current/working/foo/bar.dart'.
 *
 *  * If the relative URI is provided in an import, export or part tag, and the
 *    readable URI of the enclosing compilation unit is a file URI,
 *    'file://some/path/baz.dart', then the resolved URI is
 *    'file://some/foo/bar.dart'.
 *
 *  * If the relative URI is provided in an import, export or part tag, and the
 *    readable URI of the enclosing compilation unit is a package URI,
 *    'package:some/path/baz.dart', then the resolved URI is
 *    'package:some/foo/bar.dart'.
 *
 * The resolved URI thus preserves the scheme through resolution: A readable
 * file URI results in an resolved file URI and a readable package URI results
 * in an resolved package URI. Note that since a dart URI is not a readable URI,
 * import, export or part tags within platform libraries are not interpreted as
 * dart URIs but instead relative to the library source file location.
 *
 * The resolved URI of a library is also used as the canonical URI
 * ([LibraryElement.canonicalUri]) by which we identify which libraries are
 * identical. This means that libraries loaded through the 'package' scheme will
 * resolve to the same library when loaded from within using relative URIs (see
 * for instance the test 'standalone/package/package1_test.dart'). But loading a
 * platform library using a relative URI will _not_ result in the same library
 * as when loaded through the dart URI.
 *
 * ## Readable URI ##
 *
 * A 'readable URI' is an absolute URI whose scheme is either 'package' or
 * something supported by the input provider, normally 'file'. Dart URIs such as
 * 'dart:core' and 'dart:_js_helper' are not readable themselves but are instead
 * resolved into a readable URI using the library root URI provided from the
 * command line and the list of platform libraries found in
 * 'sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart'. This is done
 * through a [ResolvedUriTranslator] provided from the compiler. The translator
 * checks whether a library by that name exists and in case of internal
 * libraries whether access is granted.
 *
 * ## Resource URI ##
 *
 * A 'resource URI' is an absolute URI with a scheme supported by the input
 * provider. For the standard implementation this means a URI with the 'file'
 * scheme. Readable URIs are converted into resource URIs as part of the
 * [ScriptLoader.readScript] method. In the standard implementation the package
 * URIs are converted to file URIs using the package root URI provided on the
 * command line as base. If the package root URI is
 * 'file:///current/working/dir/' then the package URI 'package:foo/bar.dart'
 * will be resolved to the resource URI
 * 'file:///current/working/dir/foo/bar.dart'.
 *
 * The distinction between readable URI and resource URI is necessary to ensure
 * that these imports
 *
 *     import 'package:foo.dart' as a;
 *     import 'packages/foo.dart' as b;
 *
 * do _not_ resolve to the same library when the package root URI happens to
 * point to the 'packages' folder.
 *
 */
abstract class LibraryLoaderTask implements LibraryProvider, CompilerTask {
  /// Returns all libraries that have been loaded.
  Iterable<LibraryEntity> get libraries;

  /// Loads the library specified by the [resolvedUri] and returns the
  /// [LoadedLibraries] that were loaded to load the specified uri. The
  /// [LibraryElement] itself can be found by calling
  /// `loadedLibraries.rootLibrary`.
  ///
  /// If the library is not already loaded, the method creates the
  /// [LibraryElement] for the library and computes the import/export scope,
  /// loading and computing the import/export scopes of all required libraries
  /// in the process. The method handles cyclic dependency between libraries.
  ///
  /// If [skipFileWithPartOfTag] is `true`, `null` is returned if the
  /// compilation unit for [resolvedUri] contains a `part of` tag. This is only
  /// used for analysis through [Compiler.analyzeUri].
  Future<LoadedLibraries> loadLibrary(Uri resolvedUri,
      {bool skipFileWithPartOfTag: false});

  /// Reset the library loader task to prepare for compilation. If provided,
  /// libraries matching [reuseLibrary] are reused.
  ///
  /// This method is used for incremental compilation.
  void reset({bool reuseLibrary(LibraryElement library)});

  /// Asynchronous version of [reset].
  Future resetAsync(Future<bool> reuseLibrary(LibraryElement library));

  /// Similar to [resetAsync] but [reuseLibrary] maps all libraries to a list
  /// of libraries that can be reused.
  Future<Null> resetLibraries(ReuseLibrariesFunction reuseLibraries);

  // TODO(johnniwinther): Move these to a separate interface.
  /// Register a deferred action to be performed during resolution.
  void registerDeferredAction(DeferredAction action);

  /// Returns the deferred actions registered since the last call to
  /// [pullDeferredActions].
  Iterable<DeferredAction> pullDeferredActions();

  /// The locations of js patch-files relative to the sdk-descriptors.
  static const _patchLocations = const <String, String>{
    "async": "_internal/js_runtime/lib/async_patch.dart",
    "collection": "_internal/js_runtime/lib/collection_patch.dart",
    "convert": "_internal/js_runtime/lib/convert_patch.dart",
    "core": "_internal/js_runtime/lib/core_patch.dart",
    "developer": "_internal/js_runtime/lib/developer_patch.dart",
    "io": "_internal/js_runtime/lib/io_patch.dart",
    "isolate": "_internal/js_runtime/lib/isolate_patch.dart",
    "math": "_internal/js_runtime/lib/math_patch.dart",
    "mirrors": "_internal/js_runtime/lib/mirrors_patch.dart",
    "typed_data": "_internal/js_runtime/lib/typed_data_patch.dart",
    "_internal": "_internal/js_runtime/lib/internal_patch.dart"
  };

  /// Returns the location of the patch-file associated with [libraryName]
  /// resolved from [plaformConfigUri].
  ///
  /// Returns null if there is none.
  static Uri resolvePatchUri(String libraryName, Uri platformConfigUri) {
    String patchLocation = _patchLocations[libraryName];
    if (patchLocation == null) return null;
    return platformConfigUri.resolve(patchLocation);
  }
}

/// Interface for an entity that provide libraries. For instance from normal
/// library loading or from deserialization.
// TODO(johnniwinther): Use this to integrate deserialized libraries better.
abstract class LibraryProvider {
  /// Looks up the library with the [canonicalUri].
  LibraryEntity lookupLibrary(Uri canonicalUri);
}

/// Handle for creating synthesized/patch libraries during library loading.
abstract class LibraryLoader {
  /// This method must be called when a new synthesized/patch library has been
  /// created to ensure that [library] will part of library dependency graph
  /// used for computing import/export scopes.
  void registerNewLibrary(LibraryElement library);

  /// This method must be called when a new synthesized/patch library has been
  /// scanned in order to process the library tags in [library] and thus handle
  /// imports/exports/parts in the synthesized/patch library.
  Future processLibraryTags(LibraryElement library);
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
    Set<String> nameSet;
    for (Combinator combinator in tag.combinators) {
      if (combinator.isShow) {
        show = true;
        var set = new Set<String>();
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
      nameSet = new Set<String>();
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
  final Set<String> includedNames;

  ShowFilter(this.includedNames);

  bool exclude(Element element) => !includedNames.contains(element.name);
}

/**
 * A list of combinators represented as a list of element names to exclude.
 */
class HideFilter extends CombinatorFilter {
  final Set<String> excludedNames;

  HideFilter(this.excludedNames);

  bool exclude(Element element) => excludedNames.contains(element.name);
}

/// Implementation class for [LibraryLoaderTask]. This library loader loads
/// '.dart' files into the [Element] model with AST nodes which are resolved
/// by the resolver.
class ResolutionLibraryLoaderTask extends CompilerTask
    implements LibraryLoaderTask {
  /// Translates internal uris (like dart:core) to a disk location.
  final ResolvedUriTranslator uriTranslator;

  /// Loads the contents of a script file (a .dart file). Used when loading
  /// libraries from source.
  final ScriptLoader scriptLoader;

  /// Provides a diet element model from a script file containing information
  /// about imports and exports. Used when loading libraries from source.
  final ElementScanner scanner;

  /// Provides a diet element model for a library. Used when loading libraries
  /// from a serialized form.
  final LibraryDeserializer deserializer;

  /// Definitions provided via the `-D` command line flags. Used to resolve
  /// conditional imports.
  final Environment environment;

  // TODO(efortuna): Don't pass PatchParserTask here.
  final PatchParserTask _patchParserTask;

  /// Function that accepts the string name of a library and returns the
  /// path to the corresponding patch file. This is a function that is passed in
  /// because our test mock_compiler subclasses compiler.
  // TODO(efortuna): Refactor mock_compiler to not do this.
  final PatchResolverFunction _patchResolverFunc;

  List<DeferredAction> _deferredActions = <DeferredAction>[];

  final DiagnosticReporter reporter;

  ResolutionLibraryLoaderTask(
      this.uriTranslator,
      this.scriptLoader,
      this.scanner,
      this.deserializer,
      this._patchResolverFunc,
      this._patchParserTask,
      this.environment,
      this.reporter,
      Measurer measurer)
      : super(measurer);

  String get name => 'LibraryLoader';

  final Map<Uri, LibraryElement> libraryCanonicalUriMap =
      new Map<Uri, LibraryElement>();
  final Map<Uri, LibraryElement> libraryResourceUriMap =
      new Map<Uri, LibraryElement>();
  final Map<String, LibraryElement> libraryNames =
      new Map<String, LibraryElement>();

  Iterable<LibraryEntity> get libraries => libraryCanonicalUriMap.values;

  LibraryEntity lookupLibrary(Uri canonicalUri) {
    return libraryCanonicalUriMap[canonicalUri];
  }

  void reset({bool reuseLibrary(LibraryElement library)}) {
    measure(() {
      Iterable<LibraryElement> reusedLibraries = null;
      if (reuseLibrary != null) {
        reusedLibraries = measureSubtask(_reuseLibrarySubtaskName, () {
          // Call [toList] to force eager calls to [reuseLibrary].
          return libraryCanonicalUriMap.values.where(reuseLibrary).toList();
        });
      }

      resetImplementation(reusedLibraries);
    });
  }

  void resetImplementation(Iterable<LibraryElement> reusedLibraries) {
    measure(() {
      libraryCanonicalUriMap.clear();
      libraryResourceUriMap.clear();
      libraryNames.clear();

      if (reusedLibraries != null) {
        reusedLibraries.forEach(mapLibrary);
      }
    });
  }

  Future resetAsync(Future<bool> reuseLibrary(LibraryElement library)) {
    return measure(() {
      Future<LibraryElement> wrapper(LibraryElement library) {
        try {
          return reuseLibrary(library)
              .then((bool reuse) => reuse ? library : null);
        } catch (exception, trace) {
          reporter.onCrashInUserCode(
              'Uncaught exception in reuseLibrary', exception, trace);
          rethrow;
        }
      }

      List<Future<LibraryElement>> reusedLibrariesFuture = measureSubtask(
          _reuseLibrarySubtaskName,
          () => libraryCanonicalUriMap.values.map(wrapper).toList());

      return Future
          .wait(reusedLibrariesFuture)
          .then((Iterable<LibraryElement> reusedLibraries) {
        resetImplementation(reusedLibraries.where((e) => e != null));
      });
    });
  }

  Future<Null> resetLibraries(
      Future<Iterable<LibraryElement>> reuseLibraries(
          Iterable<LibraryElement> libraries)) {
    return measureSubtask(_reuseLibrarySubtaskName, () {
      return new Future<Iterable<LibraryElement>>(() {
        // Wrap in Future to shield against errors in user code.
        return reuseLibraries(libraryCanonicalUriMap.values);
      }).catchError((exception, StackTrace trace) {
        reporter.onCrashInUserCode(
            'Uncaught exception in reuseLibraries', exception, trace);
        throw exception; // Async rethrow.
      }).then((Iterable<LibraryElement> reusedLibraries) {
        measure(() {
          resetImplementation(reusedLibraries);
        });
      });
    });
  }

  /// Insert [library] in the internal maps. Used for compiler reuse.
  void mapLibrary(LibraryElement library) {
    libraryCanonicalUriMap[library.canonicalUri] = library;

    Uri resourceUri = library.entryCompilationUnit.script.resourceUri;
    libraryResourceUriMap[resourceUri] = library;

    if (library.hasLibraryName) {
      String name = library.libraryName;
      libraryNames[name] = library;
    }
  }

  Future<LoadedLibraries> loadLibrary(Uri resolvedUri,
      {bool skipFileWithPartOfTag: false}) {
    return measure(() async {
      LibraryDependencyHandler handler = new LibraryDependencyHandler(this);
      LibraryElement library = await createLibrary(
          handler, null, resolvedUri, NO_LOCATION_SPANNABLE,
          skipFileWithPartOfTag: skipFileWithPartOfTag);
      if (library == null) return null;
      return reporter.withCurrentElement(library, () {
        return measure(() {
          handler.computeExports();
          return new _LoadedLibraries(library, handler.newLibraries);
        });
      });
    });
  }

  /**
   * Processes the library tags in [library].
   *
   * The imported/exported libraries are loaded and processed recursively but
   * the import/export scopes are not set up.
   */
  Future processLibraryTags(
      LibraryDependencyHandler handler, LibraryElementX library) {
    TagState tagState = new TagState();

    bool importsDartCore = false;
    LinkBuilder<LibraryDependencyElementX> libraryDependencies =
        new LinkBuilder<LibraryDependencyElementX>();
    Uri base = library.entryCompilationUnit.script.readableUri;

    return Future.forEach(library.tags, (LibraryTag tag) {
      return reporter.withCurrentElement(library, () {
        Uri computeUri(LibraryDependency node) {
          StringNode uriNode = node.uri;
          if (node.conditionalUris != null) {
            for (ConditionalUri conditionalUri in node.conditionalUris) {
              String key = conditionalUri.key.slowNameString;
              String value = conditionalUri.value == null
                  ? "true"
                  : conditionalUri.value.dartString.slowToString();
              String actual = environment.valueOf(key);
              if (value == actual) {
                uriNode = conditionalUri.uri;
                break;
              }
            }
          }
          String tagUriString = uriNode.dartString.slowToString();
          try {
            return Uri.parse(tagUriString);
          } on FormatException {
            reporter.reportErrorMessage(
                node.uri, MessageKind.INVALID_URI, {'uri': tagUriString});
            return null;
          }
        }

        if (tag.isImport) {
          Uri uri = computeUri(tag);
          if (uri == null) {
            // Skip this erroneous import.
            return new Future.value();
          }
          // TODO(johnniwinther): Create imports during parsing.
          ImportElementX import =
              new ImportElementX(library.entryCompilationUnit, tag, uri);
          tagState.checkTag(TagState.IMPORT_OR_EXPORT, import.node, reporter);
          if (import.uri == Uris.dart_core) {
            importsDartCore = true;
          }
          library.addImportDeclaration(import);
          libraryDependencies.addLast(import);
        } else if (tag.isExport) {
          Uri uri = computeUri(tag);
          if (uri == null) {
            // Skip this erroneous export.
            return new Future.value();
          }
          // TODO(johnniwinther): Create exports during parsing.
          ExportElementX export =
              new ExportElementX(library.entryCompilationUnit, tag, uri);
          tagState.checkTag(TagState.IMPORT_OR_EXPORT, export.node, reporter);
          library.addExportDeclaration(export);
          libraryDependencies.addLast(export);
        } else if (tag.isLibraryName) {
          tagState.checkTag(TagState.LIBRARY, tag, reporter);
          if (library.libraryTag == null) {
            // Use the first if there are multiple (which is reported as an
            // error in [TagState.checkTag]).
            library.libraryTag = tag;
          }
        } else if (tag.isPart) {
          Part part = tag;
          StringNode uri = part.uri;
          Uri resolvedUri = base.resolve(uri.dartString.slowToString());
          tagState.checkTag(TagState.PART, part, reporter);
          return scanPart(part, resolvedUri, library);
        } else {
          reporter.internalError(tag, "Unhandled library tag.");
        }
      });
    }).then((_) {
      return reporter.withCurrentElement(library, () {
        checkDuplicatedLibraryName(library);

        // Import dart:core if not already imported.
        if (!importsDartCore && library.canonicalUri != Uris.dart_core) {
          return createLibrary(handler, null, Uris.dart_core, library)
              .then((LibraryElement coreLibrary) {
            handler.registerDependency(
                library,
                new SyntheticImportElement(
                    library.entryCompilationUnit, Uris.dart_core, coreLibrary),
                coreLibrary);
          });
        }
      });
    }).then((_) {
      return Future.forEach(libraryDependencies.toList(),
          (LibraryDependencyElementX libraryDependency) {
        return reporter.withCurrentElement(library, () {
          return registerLibraryFromImportExport(
              handler, library, libraryDependency);
        });
      });
    });
  }

  void checkDuplicatedLibraryName(LibraryElement library) {
    if (library.isInternalLibrary) return;
    Uri resourceUri = library.entryCompilationUnit.script.resourceUri;
    LibraryElement existing =
        libraryResourceUriMap.putIfAbsent(resourceUri, () => library);
    if (!identical(existing, library)) {
      if (library.hasLibraryName) {
        reporter.withCurrentElement(library, () {
          reporter.reportWarningMessage(
              library, MessageKind.DUPLICATED_LIBRARY_RESOURCE, {
            'libraryName': library.libraryName,
            'resourceUri': resourceUri,
            'canonicalUri1': library.canonicalUri,
            'canonicalUri2': existing.canonicalUri
          });
        });
      } else {
        reporter.reportHintMessage(library, MessageKind.DUPLICATED_RESOURCE, {
          'resourceUri': resourceUri,
          'canonicalUri1': library.canonicalUri,
          'canonicalUri2': existing.canonicalUri
        });
      }
    } else if (library.hasLibraryName) {
      String name = library.libraryName;
      existing = libraryNames.putIfAbsent(name, () => library);
      if (!identical(existing, library)) {
        reporter.withCurrentElement(library, () {
          reporter.reportWarningMessage(library,
              MessageKind.DUPLICATED_LIBRARY_NAME, {'libraryName': name});
        });
        reporter.withCurrentElement(existing, () {
          reporter.reportWarningMessage(existing,
              MessageKind.DUPLICATED_LIBRARY_NAME, {'libraryName': name});
        });
      }
    }
  }

  /**
   * Handle a part tag in the scope of [library]. The [resolvedUri] given is
   * used as is, any URI resolution should be done beforehand.
   */
  Future scanPart(Part part, Uri resolvedUri, LibraryElement library) {
    if (!resolvedUri.isAbsolute) throw new ArgumentError(resolvedUri);
    Uri readableUri = uriTranslator.translate(library, resolvedUri, part);
    if (readableUri == null) return new Future.value();
    return reporter.withCurrentElement(library, () {
      return scriptLoader.readScript(readableUri, part).then((Script script) {
        if (script == null) return;
        createUnitSync(script, library);
      });
    });
  }

  /**
   * Handle an import/export tag by loading the referenced library and
   * registering its dependency in [handler] for the computation of the import/
   * export scope. If the tag does not contain a valid URI, then its dependency
   * is not registered in [handler].
   */
  Future<Null> registerLibraryFromImportExport(LibraryDependencyHandler handler,
      LibraryElement library, LibraryDependencyElementX libraryDependency) {
    Uri base = library.canonicalUri;
    Uri resolvedUri = base.resolveUri(libraryDependency.uri);
    return createLibrary(handler, library, resolvedUri, libraryDependency)
        .then((LibraryElement loadedLibrary) {
      if (loadedLibrary == null) return;
      reporter.withCurrentElement(library, () {
        libraryDependency.libraryDependency = loadedLibrary;
        handler.registerDependency(library, libraryDependency, loadedLibrary);
      });
    });
  }

  /// Loads the deserialized [library] with the [handler].
  ///
  /// All libraries imported or exported transitively from [library] will be
  /// loaded as well.
  Future<LibraryElement> loadDeserializedLibrary(
      LibraryDependencyHandler handler, LibraryElement library) {
    libraryCanonicalUriMap[library.canonicalUri] = library;
    handler.registerNewLibrary(library);
    return Future.forEach(library.imports, (ImportElement import) {
      Uri resolvedUri = library.canonicalUri.resolveUri(import.uri);
      return createLibrary(handler, library, resolvedUri, library);
    }).then((_) {
      return Future.forEach(library.exports, (ExportElement export) {
        Uri resolvedUri = library.canonicalUri.resolveUri(export.uri);
        return createLibrary(handler, library, resolvedUri, library);
      }).then((_) {
        // TODO(johnniwinther): Shouldn't there be an [ImportElement] for the
        // implicit import of dart:core?
        return createLibrary(handler, library, Uris.dart_core, library);
      }).then((_) => library);
    });
  }

  Future<Script> _readScript(
      Spannable spannable, Uri readableUri, Uri resolvedUri) {
    if (readableUri == null) {
      return new Future.value(new Script.synthetic(resolvedUri));
    } else {
      return scriptLoader.readScript(readableUri, spannable);
    }
  }

  /**
   * Create (or reuse) a library element for the library specified by the
   * [resolvedUri].
   *
   * If a new library is created, the [handler] is notified.
   */
  Future<LibraryElement> createLibrary(LibraryDependencyHandler handler,
      LibraryElement importingLibrary, Uri resolvedUri, Spannable spannable,
      {bool skipFileWithPartOfTag: false}) async {
    Uri readableUri =
        uriTranslator.translate(importingLibrary, resolvedUri, spannable);
    LibraryElement library = libraryCanonicalUriMap[resolvedUri];
    if (library != null) {
      return new Future.value(library);
    }
    library = await deserializer.readLibrary(resolvedUri);
    if (library != null) {
      return loadDeserializedLibrary(handler, library);
    }
    return reporter.withCurrentElement(importingLibrary, () {
      return _readScript(spannable, readableUri, resolvedUri)
          .then((Script script) async {
        if (script == null) return null;
        LibraryElement element =
            createLibrarySync(handler, script, resolvedUri);
        CompilationUnitElementX compilationUnit = element.entryCompilationUnit;
        if (compilationUnit.partTag != null) {
          if (skipFileWithPartOfTag) {
            // TODO(johnniwinther): Avoid calling
            // [compiler.processLoadedLibraries] with this library.
            libraryCanonicalUriMap.remove(resolvedUri);
            return null;
          }
          if (importingLibrary == null) {
            DiagnosticMessage error = reporter.withCurrentElement(
                compilationUnit,
                () => reporter.createMessage(
                    compilationUnit.partTag, MessageKind.MAIN_HAS_PART_OF));
            reporter.reportError(error);
          } else {
            DiagnosticMessage error = reporter.withCurrentElement(
                compilationUnit,
                () => reporter.createMessage(
                    compilationUnit.partTag, MessageKind.IMPORT_PART_OF));
            DiagnosticMessage info = reporter.withCurrentElement(
                importingLibrary,
                () => reporter.createMessage(
                    spannable, MessageKind.IMPORT_PART_OF_HERE));
            reporter.reportError(error, [info]);
          }
        }
        await processLibraryTags(handler, element);
        reporter.withCurrentElement(element, () {
          handler.registerLibraryExports(element);
        });

        await patchLibraryIfNecessary(element, handler);
        return element;
      });
    });
  }

  Future patchLibraryIfNecessary(
      LibraryElement element, LibraryDependencyHandler handler) async {
    if (element.isPlatformLibrary &&
        // Don't patch library currently disallowed.
        !element.isSynthesized &&
        !element.isPatched &&
        // Don't patch deserialized libraries.
        !deserializer.isDeserialized(element)) {
      // Apply patch, if any.
      Uri patchUri = _patchResolverFunc(element.canonicalUri.path);
      if (patchUri != null) {
        await _patchParserTask.patchLibrary(handler, patchUri, element);
      }
    }
  }

  LibraryElement createLibrarySync(
      LibraryDependencyHandler handler, Script script, Uri resolvedUri) {
    LibraryElement element = new LibraryElementX(script, resolvedUri);
    return reporter.withCurrentElement(element, () {
      if (handler != null) {
        handler.registerNewLibrary(element);
        libraryCanonicalUriMap[resolvedUri] = element;
      }
      scanner.scanLibrary(element);
      return element;
    });
  }

  CompilationUnitElement createUnitSync(Script script, LibraryElement library) {
    CompilationUnitElementX unit = new CompilationUnitElementX(script, library);
    reporter.withCurrentElement(unit, () {
      scanner.scanUnit(unit);
      if (unit.partTag == null && !script.isSynthesized) {
        reporter.reportErrorMessage(unit, MessageKind.MISSING_PART_OF_TAG);
      }
    });
    return unit;
  }

  void registerDeferredAction(DeferredAction action) {
    _deferredActions.add(action);
  }

  Iterable<DeferredAction> pullDeferredActions() {
    Iterable<DeferredAction> actions = _deferredActions.toList();
    _deferredActions.clear();
    return actions;
  }
}

/// A loader that builds a kernel IR representation of the program (or set of
/// libraries).
///
/// It supports loading both .dart source files or pre-compiled .dill files.
/// When given .dart source files, it invokes the shared frontend
/// (`package:front_end`) to produce the corresponding kernel IR representation.
// TODO(sigmund): move this class to a new file under src/kernel/.
class KernelLibraryLoaderTask extends CompilerTask
    implements LibraryLoaderTask {
  final Uri sdkRoot;

  final DiagnosticReporter reporter;

  final api.CompilerInput compilerInput;

  /// Holds the mapping of Kernel IR to KElements that is constructed as a
  /// result of loading a program.
  final KernelToElementMapForImpactImpl _elementMap;

  List<LibraryEntity> _allLoadedLibraries;

  KernelLibraryLoaderTask(this.sdkRoot, this._elementMap, this.compilerInput,
      this.reporter, Measurer measurer)
      : _allLoadedLibraries = new List<LibraryEntity>(),
        super(measurer);

  /// Loads an entire Kernel [Program] from a file on disk (note, not just a
  /// library, so this name is actually a bit of a misnomer).
  // TODO(efortuna): Rename this once the Element library loader class goes
  // away.
  Future<LoadedLibraries> loadLibrary(Uri resolvedUri,
      {bool skipFileWithPartOfTag: false}) {
    return measure(() async {
      var isDill = resolvedUri.path.endsWith('.dill');
      ir.Program program;
      if (isDill) {
        api.Input input = await compilerInput.readFromUri(resolvedUri,
            inputKind: api.InputKind.binary);
        program = new ir.Program();
        new BinaryBuilder(input.data).readProgram(program);
      } else {
        var options = new fe.CompilerOptions()
          ..fileSystem = new CompilerFileSystem(compilerInput)
          ..target = new Dart2jsTarget(new TargetFlags())
          ..compileSdk = true
          ..linkedDependencies = [
            sdkRoot.resolve('_internal/dart2js_platform.dill')
          ]
          ..onError = (e) => reportFrontEndMessage(reporter, e);

        program = await fe.kernelForProgram(resolvedUri, options);
      }
      if (program == null) return null;
      return createLoadedLibraries(program);
    });
  }

  // Only visible for unit testing.
  LoadedLibraries createLoadedLibraries(ir.Program program) {
    _elementMap.addProgram(program);
    program.libraries.forEach((ir.Library library) =>
        _allLoadedLibraries.add(_elementMap.lookupLibrary(library.importUri)));
    LibraryEntity rootLibrary = null;
    if (program.mainMethod != null) {
      rootLibrary = _elementMap
          .lookupLibrary(program.mainMethod.enclosingLibrary.importUri);
    }
    return new _LoadedLibrariesAdapter(
        rootLibrary, _allLoadedLibraries, _elementMap);
  }

  KernelToElementMapForImpactImpl get elementMap => _elementMap;

  void reset({bool reuseLibrary(LibraryElement library)}) {
    throw new UnimplementedError('KernelLibraryLoaderTask.reset');
  }

  Future resetAsync(Future<bool> reuseLibrary(LibraryElement library)) {
    throw new UnimplementedError('KernelLibraryLoaderTask.resetAsync');
  }

  Iterable<LibraryEntity> get libraries => _allLoadedLibraries;

  LibraryEntity lookupLibrary(Uri canonicalUri) {
    return _elementMap?.lookupLibrary(canonicalUri);
  }

  Future<Null> resetLibraries(ReuseLibrariesFunction reuseLibraries) {
    throw new UnimplementedError('KernelLibraryLoaderTask.reuseLibraries');
  }

  void registerDeferredAction(DeferredAction action) {
    throw new UnimplementedError(
        'KernelLibraryLoaderTask.registerDeferredAction');
  }

  Iterable<DeferredAction> pullDeferredActions() => const <DeferredAction>[];
}

/// A state machine for checking script tags come in the correct order.
class TagState {
  /// Initial state.
  static const int NO_TAG_SEEN = 0;

  /// Passed to [checkTag] when a library declaration (the syntax "library
  /// name;") has been seen. Not an actual state.
  static const int LIBRARY = 1;

  /// The state after the first library declaration.
  static const int AFTER_LIBRARY_DECLARATION = 2;

  /// The state after a import or export declaration has been seen, but before
  /// a part tag has been seen.
  static const int IMPORT_OR_EXPORT = 3;

  /// The state after a part tag has been seen.
  static const int PART = 4;

  /// Encodes transition function for state machine.
  static const List<int> NEXT = const <int>[
    NO_TAG_SEEN,
    AFTER_LIBRARY_DECLARATION, // Only one library tag is allowed.
    IMPORT_OR_EXPORT,
    IMPORT_OR_EXPORT,
    PART,
  ];

  int tagState = TagState.NO_TAG_SEEN;

  bool hasLibraryDeclaration = false;

  /// If [value] is less than [tagState] complain. Regardless, update
  /// [tagState] using transition function for state machine.
  void checkTag(int value, LibraryTag tag, DiagnosticReporter reporter) {
    if (tagState > value) {
      MessageKind kind;
      switch (value) {
        case LIBRARY:
          if (hasLibraryDeclaration) {
            kind = MessageKind.ONLY_ONE_LIBRARY_TAG;
          } else {
            kind = MessageKind.LIBRARY_TAG_MUST_BE_FIRST;
          }
          break;

        case IMPORT_OR_EXPORT:
          if (tag.isImport) {
            kind = MessageKind.IMPORT_BEFORE_PARTS;
          } else if (tag.isExport) {
            kind = MessageKind.EXPORT_BEFORE_PARTS;
          } else {
            reporter.internalError(tag, "Expected import or export.");
          }
          break;

        default:
          reporter.internalError(tag, "Unexpected order of library tags.");
      }
      reporter.reportErrorMessage(tag, kind);
    }
    tagState = NEXT[value];
    if (value == LIBRARY) {
      hasLibraryDeclaration = true;
    }
  }
}

/**
 * An [import] tag and the [importedLibrary] imported through [import].
 */
class ImportLink {
  final ImportElementX import;
  final LibraryElement importedLibrary;

  ImportLink(this.import, this.importedLibrary);

  /**
   * Imports the library into the [importingLibrary].
   */
  void importLibrary(
      DiagnosticReporter reporter, LibraryElementX importingLibrary) {
    assert(importedLibrary.exportsHandled,
        failedAt(importedLibrary, 'Exports not handled on $importedLibrary'));
    Import tag = import.node;
    CombinatorFilter combinatorFilter = new CombinatorFilter.fromTag(tag);
    if (tag != null && tag.prefix != null) {
      String prefix = tag.prefix.source;
      Element existingElement = importingLibrary.find(prefix);
      PrefixElementX prefixElement;
      if (existingElement == null || !existingElement.isPrefix) {
        prefixElement = new PrefixElementX(
            prefix,
            importingLibrary.entryCompilationUnit,
            tag.getBeginToken(),
            tag.isDeferred ? import : null);
      } else {
        prefixElement = existingElement;
      }
      importingLibrary.addToScope(prefixElement, reporter);
      importedLibrary.forEachExport((Element element) {
        if (combinatorFilter.exclude(element)) return;
        prefixElement.addImport(element, import, reporter);
      });
      import.prefix = prefixElement;
      if (prefixElement.isDeferred) {
        prefixElement.addImport(
            new DeferredLoaderGetterElementX(prefixElement), import, reporter);
      }
    } else {
      importedLibrary.forEachExport((Element element) {
        reporter.withCurrentElement(importingLibrary, () {
          if (combinatorFilter.exclude(element)) return;
          importingLibrary.addImport(element, import, reporter);
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
  final ExportElementX export;
  final CombinatorFilter combinatorFilter;
  final LibraryDependencyNode exportNode;

  ExportLink(ExportElementX export, LibraryDependencyNode this.exportNode)
      : this.export = export,
        this.combinatorFilter = new CombinatorFilter.fromTag(export.node);

  /**
   * Exports [element] to the dependent library unless [element] is filtered by
   * the export combinators. Returns [:true:] if the set pending exports of the
   * dependent library was modified.
   */
  bool exportElement(Element element) {
    if (combinatorFilter.exclude(element)) return false;
    return exportNode.addElementToPendingExports(element, export);
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
  final LibraryElementX library;

  // Stored identity based hashCode for performance.
  final int hashCode = _nextHash = (_nextHash + 100019).toUnsigned(30);
  static int _nextHash = 0;

  /**
   * A linked list of the import tags that import [library] mapped to the
   * corresponding libraries. This is used to propagate exports into imports
   * after the export scopes have been computed.
   */
  Link<ImportLink> imports = const Link<ImportLink>();

  /// A linked list of all libraries directly exported by [library].
  Link<LibraryElement> exports = const Link<LibraryElement>();

  /**
   * A linked list of the export tags the dependent upon this node library.
   * This is used to propagate exports during the computation of export scopes.
   */
  Link<ExportLink> dependencies = const Link<ExportLink>();

  /**
   * The export scope for [library] which is gradually computed by the work-list
   * computation in [LibraryDependencyHandler.computeExports].
   */
  Map<String, Element> exportScope = <String, Element>{};

  /// Map from exported elements to the export directives that exported them.
  Map<Element, Link<ExportElement>> exporters =
      <Element, Link<ExportElement>>{};

  /**
   * The set of exported elements that need to be propageted to dependent
   * libraries as part of the work-list computation performed in
   * [LibraryDependencyHandler.computeExports]. Each export element is mapped
   * to a list of exports directives that export it.
   */
  Map<Element, Link<ExportElement>> pendingExportMap =
      <Element, Link<ExportElement>>{};

  LibraryDependencyNode(this.library);

  /**
   * Registers that the library of this node imports [importLibrary] through the
   * [import] tag.
   */
  void registerImportDependency(
      ImportElementX import, LibraryElement importedLibrary) {
    imports = imports.prepend(new ImportLink(import, importedLibrary));
  }

  /**
   * Registers that the library of this node is exported by
   * [exportingLibraryNode] through the [export] tag.
   */
  void registerExportDependency(
      ExportElementX export, LibraryDependencyNode exportingLibraryNode) {
    // Register the exported library in the exporting library node.
    exportingLibraryNode.exports =
        exportingLibraryNode.exports.prepend(library);
    // Register the export in the exported library node.
    dependencies =
        dependencies.prepend(new ExportLink(export, exportingLibraryNode));
  }

  /**
   * Registers all non-private locally declared members of the library of this
   * node to be exported. This forms the basis for the work-list computation of
   * the export scopes performed in [LibraryDependencyHandler.computeExports].
   */
  void registerInitialExports() {
    for (Element element in library.getNonPrivateElementsInScope()) {
      pendingExportMap[element] = const Link<ExportElement>();
    }
  }

  /// Register the already computed export scope of [exportedLibraryElement] to
  /// export from the library of this node through the [export]  declaration
  /// with the given combination [filter].
  ///
  /// Additionally, check that all names in the show/hide combinators are in the
  /// export scope of [exportedLibraryElement].
  void registerHandledExports(
      DiagnosticReporter reporter,
      LibraryElement exportedLibraryElement,
      ExportElementX export,
      CombinatorFilter filter) {
    assert(exportedLibraryElement.exportsHandled, failedAt(library));
    exportedLibraryElement.forEachExport((Element exportedElement) {
      if (!filter.exclude(exportedElement)) {
        Link<ExportElement> exports = pendingExportMap.putIfAbsent(
            exportedElement, () => const Link<ExportElement>());
        pendingExportMap[exportedElement] = exports.prepend(export);
      }
    });
    if (!reporter.options.suppressHints) {
      reporter.withCurrentElement(library, () {
        checkLibraryDependency(reporter, export.node, exportedLibraryElement);
      });
    }
  }

  /**
   * Registers the compute export scope with the node library.
   */
  void registerExports() {
    library.setExports(exportScope.values.toList());
  }

  /**
   * Registers the imports of the node library.
   */
  void registerImports(DiagnosticReporter reporter) {
    for (ImportLink link in imports) {
      link.importLibrary(reporter, library);
    }
  }

  /**
   * Copies and clears pending export set for this node.
   */
  Map<Element, Link<ExportElement>> pullPendingExports() {
    Map<Element, Link<ExportElement>> pendingExports =
        new Map<Element, Link<ExportElement>>.from(pendingExportMap);
    pendingExportMap.clear();
    return pendingExports;
  }

  /**
   * Adds [element] to the export scope for this node. If the [element] name
   * is a duplicate, an error element is inserted into the export scope.
   */
  Element addElementToExportScope(DiagnosticReporter reporter, Element element,
      Link<ExportElement> exports) {
    String name = element.name;
    DiagnosticMessage error;
    List<DiagnosticMessage> infos = <DiagnosticMessage>[];

    void createDuplicateExportMessage(
        Element duplicate, Link<ExportElement> duplicateExports) {
      assert(
          !duplicateExports.isEmpty,
          failedAt(
              library,
              "No export for $duplicate from ${duplicate.library} "
              "in $library."));
      reporter.withCurrentElement(library, () {
        for (ExportElement export in duplicateExports) {
          if (error == null) {
            error = reporter.createMessage(
                export, MessageKind.DUPLICATE_EXPORT, {'name': name});
          } else {
            infos.add(reporter.createMessage(
                export, MessageKind.DUPLICATE_EXPORT_CONT, {'name': name}));
          }
        }
      });
    }

    void createDuplicateExportDeclMessage(
        Element duplicate, Link<ExportElement> duplicateExports) {
      assert(
          !duplicateExports.isEmpty,
          failedAt(
              library,
              "No export for $duplicate from ${duplicate.library} "
              "in $library."));
      infos.add(reporter.createMessage(
          duplicate,
          MessageKind.DUPLICATE_EXPORT_DECL,
          {'name': name, 'uriString': duplicateExports.head.uri}));
    }

    Element existingElement = exportScope[name];
    if (existingElement != null && existingElement != element) {
      if (existingElement.isMalformed) {
        createDuplicateExportMessage(element, exports);
        createDuplicateExportDeclMessage(element, exports);
        element = existingElement;
      } else if (existingElement.library == library) {
        // Do nothing. [existingElement] hides [element].
      } else if (element.library == library) {
        // [element] hides [existingElement].
        exportScope[name] = element;
        exporters[element] = exports;
      } else {
        // Declared elements hide exported elements.
        Link<ExportElement> existingExports = exporters[existingElement];
        createDuplicateExportMessage(existingElement, existingExports);
        createDuplicateExportMessage(element, exports);
        createDuplicateExportDeclMessage(existingElement, existingExports);
        createDuplicateExportDeclMessage(element, exports);
        element = exportScope[name] = new ErroneousElementX(
            MessageKind.DUPLICATE_EXPORT, {'name': name}, name, library);
      }
    } else {
      exportScope[name] = element;
      exporters[element] = exports;
    }
    if (error != null) {
      reporter.reportError(error, infos);
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
  bool addElementToPendingExports(Element element, ExportElement export) {
    bool changed = false;
    if (!identical(exportScope[element.name], element)) {
      Link<ExportElement> exports = pendingExportMap.putIfAbsent(element, () {
        changed = true;
        return const Link<ExportElement>();
      });
      pendingExportMap[element] = exports.prepend(export);
    }
    return changed;
  }

  /// Check that all names in the show/hide combinators of imports and exports
  /// are in the export scope of the imported/exported libraries.
  void checkCombinators(DiagnosticReporter reporter) {
    reporter.withCurrentElement(library, () {
      for (ImportLink importLink in imports) {
        checkLibraryDependency(
            reporter, importLink.import.node, importLink.importedLibrary);
      }
    });
    for (ExportLink exportLink in dependencies) {
      reporter.withCurrentElement(exportLink.exportNode.library, () {
        checkLibraryDependency(reporter, exportLink.export.node, library);
      });
    }
  }

  /// Check that all names in the show/hide combinators of [tag] are in the
  /// export scope of [library].
  void checkLibraryDependency(DiagnosticReporter reporter,
      LibraryDependency tag, LibraryElement library) {
    if (tag == null || tag.combinators == null) return;
    for (Combinator combinator in tag.combinators) {
      for (Identifier identifier in combinator.identifiers) {
        String name = identifier.source;
        Element element = library.findExported(name);
        if (element == null) {
          if (combinator.isHide) {
            if (library.isPackageLibrary &&
                reporter.options.hidePackageWarnings) {
              // Only report hide hint on packages if we show warnings on these:
              // The hide may be non-empty in some versions of the package, in
              // which case you shouldn't remove the combinator.
              continue;
            }
            reporter.reportHintMessage(identifier, MessageKind.EMPTY_HIDE,
                {'uri': library.canonicalUri, 'name': name});
          } else if (!library.isDartCore || name != 'dynamic') {
            // TODO(sigmund): remove this condition, we don't report a hint for
            // `import "dart:core" show dynamic;` until our tools match in
            // semantics (see #29125).
            reporter.reportHintMessage(identifier, MessageKind.EMPTY_SHOW,
                {'uri': library.canonicalUri, 'name': name});
          }
        }
      }
    }
  }
}

/**
 * Helper class used for computing the possibly cyclic import/export scopes of
 * a set of libraries.
 *
 * This class is used by [ScannerTask.scanLibrary] to collect all newly loaded
 * libraries and to compute their import/export scopes through a fixed-point
 * algorithm.
 */
class LibraryDependencyHandler implements LibraryLoader {
  final ResolutionLibraryLoaderTask task;
  final List<LibraryElement> _newLibraries = <LibraryElement>[];

  /**
   * Newly loaded libraries and their corresponding node in the library
   * dependency graph. Libraries that have already been fully loaded are not
   * part of the dependency graph of this handler since their export scopes have
   * already been computed.
   */
  Map<LibraryElement, LibraryDependencyNode> nodeMap =
      new Map<LibraryElement, LibraryDependencyNode>();

  LibraryDependencyHandler(this.task);

  DiagnosticReporter get reporter => task.reporter;

  /// The libraries created with this handler.
  Iterable<LibraryElement> get newLibraries => _newLibraries;

  /**
   * Performs a fixed-point computation on the export scopes of all registered
   * libraries and creates the import/export of the libraries based on the
   * fixed-point.
   */
  void computeExports() {
    bool changed = true;
    while (changed) {
      changed = false;
      Map<LibraryDependencyNode, Map<Element, Link<ExportElement>>> tasks =
          new Map<LibraryDependencyNode, Map<Element, Link<ExportElement>>>();

      // Locally defined elements take precedence over exported
      // elements.  So we must propagate local elements first.  We
      // ensure this by pulling the pending exports before
      // propagating.  This enforces that we handle exports
      // breadth-first, with locally defined elements being level 0.
      nodeMap.forEach((_, LibraryDependencyNode node) {
        Map<Element, Link<ExportElement>> pendingExports =
            node.pullPendingExports();
        tasks[node] = pendingExports;
      });
      tasks.forEach((LibraryDependencyNode node,
          Map<Element, Link<ExportElement>> pendingExports) {
        pendingExports.forEach((Element element, Link<ExportElement> exports) {
          element = node.addElementToExportScope(reporter, element, exports);
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
      node.registerImports(reporter);
    });

    if (!reporter.options.suppressHints) {
      nodeMap.forEach((LibraryElement library, LibraryDependencyNode node) {
        node.checkCombinators(reporter);
      });
    }
  }

  /// Registers that [library] depends on [loadedLibrary] through
  /// [libraryDependency].
  void registerDependency(
      LibraryElementX library,
      LibraryDependencyElementX libraryDependency,
      LibraryElement loadedLibrary) {
    if (libraryDependency.isExport) {
      // [loadedLibrary] is exported by [library].
      LibraryDependencyNode exportingNode = nodeMap[library];
      if (loadedLibrary.exportsHandled) {
        // Export scope already computed on [loadedLibrary].
        CombinatorFilter combinatorFilter =
            new CombinatorFilter.fromTag(libraryDependency.node);
        exportingNode.registerHandledExports(
            reporter, loadedLibrary, libraryDependency, combinatorFilter);
        return;
      }
      LibraryDependencyNode exportedNode = nodeMap[loadedLibrary];
      assert(exportedNode != null,
          failedAt(loadedLibrary, "$loadedLibrary has not been registered"));
      assert(exportingNode != null,
          failedAt(library, "$library has not been registered"));
      exportedNode.registerExportDependency(libraryDependency, exportingNode);
    } else if (libraryDependency == null || libraryDependency.isImport) {
      // [loadedLibrary] is imported by [library].
      LibraryDependencyNode importingNode = nodeMap[library];
      assert(importingNode != null,
          failedAt(library, "$library has not been registered"));
      importingNode.registerImportDependency(libraryDependency, loadedLibrary);
    }
  }

  /**
   * Registers [library] for the processing of its import/export scope.
   */
  void registerNewLibrary(LibraryElement library) {
    _newLibraries.add(library);
    if (!library.exportsHandled) {
      nodeMap[library] = new LibraryDependencyNode(library);
    }
  }

  /**
   * Registers all top-level entities of [library] as starting point for the
   * fixed-point computation of the import/export scopes.
   */
  void registerLibraryExports(LibraryElement library) {
    nodeMap[library].registerInitialExports();
  }

  Future processLibraryTags(LibraryElement library) {
    return task.processLibraryTags(this, library);
  }
}

/// Information on the set libraries loaded as a result of a call to
/// [LibraryLoader.loadLibrary].
abstract class LoadedLibraries {
  /// The access the library object created corresponding to the library
  /// passed to [LibraryLoader.loadLibrary].
  LibraryEntity get rootLibrary;

  /// Returns `true` if a library with canonical [uri] was loaded in this bulk.
  bool containsLibrary(Uri uri);

  /// Returns the library with canonical [uri] that was loaded in this bulk.
  LibraryEntity getLibrary(Uri uri);

  /// Applies all libraries in this bulk to [f].
  void forEachLibrary(f(LibraryEntity library));

  /// Applies all imports chains of [uri] in this bulk to [callback].
  ///
  /// The argument [importChainReversed] to [callback] contains the chain of
  /// imports uris that lead to importing [uri] starting in [uri] and ending in
  /// the uri that was passed in with [loadLibrary].
  ///
  /// [callback] is called once for each chain of imports leading to [uri] until
  /// [callback] returns `false`.
  void forEachImportChain(Uri uri,
      {bool callback(Link<Uri> importChainReversed)});
}

class _LoadedLibraries implements LoadedLibraries {
  final LibraryElement rootLibrary;
  final Map<Uri, LibraryElement> loadedLibraries = <Uri, LibraryElement>{};
  final List<LibraryElement> _newLibraries;

  _LoadedLibraries(this.rootLibrary, this._newLibraries) {
    _newLibraries.forEach((LibraryElement loadedLibrary) {
      loadedLibraries[loadedLibrary.canonicalUri] = loadedLibrary;
    });
    assert(rootLibrary != null);
  }

  bool containsLibrary(Uri uri) => loadedLibraries.containsKey(uri);

  LibraryElement getLibrary(Uri uri) => loadedLibraries[uri];

  void forEachLibrary(f(LibraryElement library)) => _newLibraries.forEach(f);

  void forEachImportChain(Uri targetUri,
      {bool callback(Link<Uri> importChainReversed)}) {
    bool aborted = false;

    /// Map from libraries to the set of (unreversed) paths to [uri].
    Map<LibraryElement, Iterable<Link<Uri>>> suffixChainMap =
        <LibraryElement, Iterable<Link<Uri>>>{};

    /// Computes the set of (unreversed) paths to [targetUri].
    ///
    /// Finds all paths (suffixes) from the current library to [uri] and stores
    /// it in [suffixChainMap].
    ///
    /// For every found suffix it prepends the given [prefix] and the canonical
    /// uri of [library] and invokes the [callback] with the concatenated chain.
    void computeSuffixes(LibraryElement library, Link<Uri> prefix) {
      if (aborted) return;

      Uri canonicalUri = library.canonicalUri;
      prefix = prefix.prepend(canonicalUri);
      if (suffixChainMap.containsKey(library)) return;
      suffixChainMap[library] = const <Link<Uri>>[];
      List<Link<Uri>> suffixes = [];
      if (targetUri != canonicalUri) {
        /// Process the import (or export) of [importedLibrary].
        void processLibrary(LibraryElement importedLibrary) {
          bool suffixesArePrecomputed =
              suffixChainMap.containsKey(importedLibrary);

          if (!suffixesArePrecomputed) {
            computeSuffixes(importedLibrary, prefix);
            if (aborted) return;
          }

          for (Link<Uri> suffix in suffixChainMap[importedLibrary]) {
            suffixes.add(suffix.prepend(canonicalUri));

            if (suffixesArePrecomputed) {
              // Only report chains through [import] if the suffixes had already
              // been computed, otherwise [computeSuffixes] have reported the
              // paths through [prefix].
              Link<Uri> chain = prefix;
              while (!suffix.isEmpty) {
                chain = chain.prepend(suffix.head);
                suffix = suffix.tail;
              }
              if (!callback(chain)) {
                aborted = true;
                return;
              }
            }
          }
        }

        for (ImportElement import in library.imports) {
          processLibrary(import.importedLibrary);
          if (aborted) return;
        }
        for (ExportElement export in library.exports) {
          processLibrary(export.exportedLibrary);
          if (aborted) return;
        }
      } else {
        // Here `targetUri == canonicalUri`.
        if (!callback(prefix)) {
          aborted = true;
          return;
        }
        suffixes.add(const Link<Uri>().prepend(canonicalUri));
      }
      suffixChainMap[library] = suffixes;
      return;
    }

    computeSuffixes(rootLibrary, const Link<Uri>());
  }

  String toString() => 'root=$rootLibrary,libraries=${_newLibraries}';
}

/// Adapter class to mimic the behavior of LoadedLibraries for Kernel element
/// behavior. Ultimately we'll just access worldBuilder instead.
class _LoadedLibrariesAdapter implements LoadedLibraries {
  final LibraryEntity rootLibrary;
  final List<LibraryEntity> _newLibraries;
  final KernelToElementMapForImpactImpl worldBuilder;

  _LoadedLibrariesAdapter(
      this.rootLibrary, this._newLibraries, this.worldBuilder) {
    assert(rootLibrary != null);
  }

  bool containsLibrary(Uri uri) => getLibrary(uri) != null;

  LibraryEntity getLibrary(Uri uri) => worldBuilder.lookupLibrary(uri);

  void forEachLibrary(f(LibraryEntity library)) => _newLibraries.forEach(f);

  void forEachImportChain(Uri uri,
      {bool callback(Link<Uri> importChainReversed)}) {
    // Currently a no-op. This seems wrong.
  }

  String toString() => 'root=$rootLibrary,libraries=${_newLibraries}';
}

// TODO(sigmund): remove ScriptLoader & ElementScanner. Such abstraction seems
// rather low-level. It might be more practical to split the library-loading
// task itself.  The task would continue to do the work of recursively loading
// dependencies, but it can delegate to a set of subloaders how to do the actual
// loading. We would then have a list of subloaders that use different
// implementations: in-memory cache, deserialization, scanning from files.
//
// For example, the API might look like this:
//
// /// APIs to create [LibraryElement] and [CompilationUnitElements] given it's
// /// URI.
// abstract class SubLoader {
//   /// Return the library corresponding to the script at [uri].
//   ///
//   /// Use [spannable] for error reporting.
//   Future<LibraryElement> createLibrary(Uri uri, [Spannable spannable]);
//
//   /// Return the compilation unit at [uri] that is a part of [library].
//   Future<CompilationUnitElement> createUnit(Uri uri, LibraryElement library,
//       [Spannable spannable]);
// }
//
// /// A [SubLoader] that parses a serialized form of the element model to
// /// produce the results.
// class DeserializingUnitElementCreator implements SubLoader {
// ...
// }
//
// /// A [SubLoader] that finds the script sources and does a diet parse
// /// on them to produces the results.
// class ScanningUnitElementCreator implements SubLoader {
// ...
// }
//
// Each subloader would internally create what they need (a scanner, a
// deserializer), and we wouldn't need to create abstractions to pass in
// something that is only used by the loader.

/// API used by the library loader to request scripts from the compiler system.
abstract class ScriptLoader {
  /// Load script from a readable [uri], report any errors using the location of
  /// the given [spannable].
  Future<Script> readScript(Uri uri, [Spannable spannable]);

  /// Load a binary from a readable [uri], report any errors using the location
  /// of the given [spannable].
  Future<Binary> readBinary(Uri uri, [Spannable spannable]);
}

/// API used by the library loader to synchronously scan a library or
/// compilation unit and ensure that their library tags are computed.
abstract class ElementScanner {
  void scanLibrary(LibraryElement library);
  void scanUnit(CompilationUnitElement unit);
}

const _reuseLibrarySubtaskName = "Reuse library";
