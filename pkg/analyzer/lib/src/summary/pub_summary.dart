// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show ResynthesizerResultProvider, SummaryDataStore;
import 'package:analyzer/src/summary/summarize_ast.dart'
    show serializeAstUnlinked;
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:path/path.dart' as pathos;

/**
 * Unlinked and linked information about a [PubPackage].
 */
class LinkedPubPackage {
  final PubPackage package;
  final PackageBundle unlinked;
  final PackageBundle linked;

  LinkedPubPackage(this.package, this.unlinked, this.linked);

  @override
  String toString() => package.toString();
}

/**
 * A package in the pub cache.
 */
class PubPackage {
  final String name;
  final Folder libFolder;

  PubPackage(this.name, this.libFolder);

  Folder get folder => libFolder.parent;

  @override
  int get hashCode => libFolder.hashCode;

  @override
  bool operator ==(other) {
    return other is PubPackage && other.libFolder == libFolder;
  }

  @override
  String toString() => '($name in $folder)';
}

/**
 * Class that manages summaries for pub packages.
 *
 * The client should call [getLinkedBundles] after creating a new
 * [AnalysisContext] and configuring its source factory, but before computing
 * any analysis results.  The returned linked bundles can be used to create and
 * configure [ResynthesizerResultProvider] for the context.
 */
class PubSummaryManager {
  static const UNLINKED_NAME = 'unlinked.ds';
  static const UNLINKED_SPEC_NAME = 'unlinked_spec.ds';

  final ResourceProvider resourceProvider;

  /**
   * The name of the temporary file that is used for atomic writes.
   */
  final String tempFileName;

  /**
   * The map from [PubPackage]s to their unlinked [PackageBundle]s in the pub
   * cache.
   */
  final Map<PubPackage, PackageBundle> unlinkedBundleMap =
      new HashMap<PubPackage, PackageBundle>();

  /**
   * The set of packages to compute unlinked summaries for.
   */
  final Set<PubPackage> packagesToComputeUnlinked = new Set<PubPackage>();

  /**
   * The set of already processed packages, which we have already checked
   * for their unlinked bundle existence, or scheduled its computing.
   */
  final Set<PubPackage> seenPackages = new Set<PubPackage>();

  /**
   * The [Completer] that completes when computing of all scheduled unlinked
   * bundles is complete.
   */
  Completer _onUnlinkedCompleteCompleter;

  PubSummaryManager(this.resourceProvider, this.tempFileName);

  /**
   * The [Future] that completes when computing of all scheduled unlinked
   * bundles is complete.
   */
  Future get onUnlinkedComplete {
    if (packagesToComputeUnlinked.isEmpty) {
      return new Future.value();
    }
    _onUnlinkedCompleteCompleter ??= new Completer();
    return _onUnlinkedCompleteCompleter.future;
  }

  /**
   * Return the [pathos.Context] corresponding to the [resourceProvider].
   */
  pathos.Context get pathContext => resourceProvider.pathContext;

  /**
   * Compute and return the linked bundle for the SDK extension for the given
   * [context], or `null` if none of the packages has an SDK extension.  At most
   * one extension library is supported, if more than one is found, then an
   * error will be logged, and `null` returned.
   */
  PackageBundle computeSdkExtension(
      AnalysisContext context, PackageBundle sdkBundle) {
    // Prepare SDK extension library files.
    String libUriStr;
    String libPath;
    {
      Map<String, List<Folder>> packageMap = context.sourceFactory.packageMap;
      SdkExtUriResolver sdkExtUriResolver = new SdkExtUriResolver(packageMap);
      Map<String, String> sdkExtMappings = sdkExtUriResolver.urlMappings;
      if (sdkExtMappings.length == 1) {
        libUriStr = sdkExtMappings.keys.first;
        libPath = sdkExtMappings.values.first;
      } else if (sdkExtMappings.length > 1) {
        AnalysisEngine.instance.logger
            .logError('At most one _sdkext file is supported, '
                'with at most one extension library. $sdkExtMappings found.');
        return null;
      } else {
        return null;
      }
    }
    // Compute the extension unlinked bundle.
    bool strong = context.analysisOptions.strongMode;
    PackageBundleAssembler assembler = new PackageBundleAssembler();
    try {
      File libFile = resourceProvider.getFile(libPath);
      Uri libUri = FastUri.parse(libUriStr);
      Source libSource = libFile.createSource(libUri);
      CompilationUnit libraryUnit = _parse(libSource, strong);
      // Add the library unit.
      assembler.addUnlinkedUnit(libSource, serializeAstUnlinked(libraryUnit));
      // Add part units.
      for (Directive directive in libraryUnit.directives) {
        if (directive is PartDirective) {
          Source partSource;
          {
            String partUriStr = directive.uri.stringValue;
            Uri partUri = resolveRelativeUri(libUri, FastUri.parse(partUriStr));
            pathos.Context pathContext = resourceProvider.pathContext;
            String partPath =
                pathContext.join(pathContext.dirname(libPath), partUriStr);
            File partFile = resourceProvider.getFile(partPath);
            partSource = partFile.createSource(partUri);
          }
          CompilationUnit partUnit = _parse(partSource, strong);
          assembler.addUnlinkedUnit(partSource, serializeAstUnlinked(partUnit));
        }
      }
      // Add the SDK and the unlinked extension bundle.
      PackageBundleBuilder unlinkedBuilder = assembler.assemble();
      SummaryDataStore store = new SummaryDataStore(const <String>[]);
      store.addBundle(null, sdkBundle);
      store.addBundle(null, unlinkedBuilder);
      // Link the extension bundle.
      Map<String, LinkedLibraryBuilder> linkedLibraries;
      try {
        linkedLibraries = link([libUriStr].toSet(), (String absoluteUri) {
          LinkedLibrary dependencyLibrary = store.linkedMap[absoluteUri];
          if (dependencyLibrary == null) {
            throw new _LinkException();
          }
          return dependencyLibrary;
        }, (String absoluteUri) {
          UnlinkedUnit unlinkedUnit = store.unlinkedMap[absoluteUri];
          if (unlinkedUnit == null) {
            throw new _LinkException();
          }
          return unlinkedUnit;
        }, strong);
      } on _LinkException {
        return null;
      }
      if (linkedLibraries.length != 1) {
        return null;
      }
      // Append linked libraries into the assembler.
      linkedLibraries.forEach((uri, library) {
        assembler.addLinkedLibrary(uri, library);
      });
      List<int> bytes = assembler.assemble().toBuffer();
      return new PackageBundle.fromBuffer(bytes);
    } on FileSystemException {
      return null;
    }
  }

  /**
   * Return the list of linked [LinkedPubPackage]s that can be provided at this
   * time for a subset of the packages used by the given [context].  If
   * information about some of the used packages is not available yet, schedule
   * its computation, so that it might be available later for other contexts
   * referencing the same packages.
   */
  List<LinkedPubPackage> getLinkedBundles(AnalysisContext context) {
    PackageBundle sdkBundle = context.sourceFactory.dartSdk.getLinkedBundle();
    if (sdkBundle == null) {
      return const <LinkedPubPackage>[];
    }

    Map<PubPackage, PackageBundle> unlinkedBundles =
        getUnlinkedBundles(context);

    // If no unlinked bundles, there is nothing we can try to link.
    if (unlinkedBundles.isEmpty) {
      return const <LinkedPubPackage>[];
    }

    // Create graph nodes for packages.
    List<_LinkedNode> nodes = <_LinkedNode>[];
    Map<String, _LinkedNode> packageToNode = <String, _LinkedNode>{};
    unlinkedBundles.forEach((package, unlinked) {
      _LinkedNode node = new _LinkedNode(package, unlinked, packageToNode);
      nodes.add(node);
      packageToNode[package.name] = node;
    });

    // Fill the store with the linked SDK and unlinked package bundles.
    SummaryDataStore store = new SummaryDataStore(const <String>[]);
    store.addBundle(null, sdkBundle);
    {
      PackageBundle extension = computeSdkExtension(context, sdkBundle);
      if (extension != null) {
        store.addBundle(null, extension);
      }
    }
    for (PackageBundle unlinked in unlinkedBundles.values) {
      store.addBundle(null, unlinked);
    }

    // Link each package node.
//    Stopwatch linkTimer = new Stopwatch()..start();
    for (_LinkedNode node in nodes) {
      if (!node.isEvaluated) {
        try {
          bool strong = context.analysisOptions.strongMode;
          new _LinkedWalker(store, strong).walk(node);
        } on _LinkException {
          // Linking of the node failed.
        }
      }
    }
    // TODO(scheglov) remove debug output after optimizing
//    print('LINKED ${unlinkedBundles.length} bundles'
//        ' in ${linkTimer.elapsedMilliseconds} ms');

    // Create successfully linked packages.
    List<LinkedPubPackage> linkedPackages = <LinkedPubPackage>[];
    for (_LinkedNode node in nodes) {
      if (node.linkedBuilder != null) {
        List<int> bytes = node.linkedBuilder.toBuffer();
        PackageBundle linkedBundle = new PackageBundle.fromBuffer(bytes);
        linkedPackages.add(
            new LinkedPubPackage(node.package, node.unlinked, linkedBundle));
      }
    }

    // TODO(scheglov) compute dependency hashes and write linked bundles.
    // TODO(scheglov) don't forget to include the SDK API signature.

    // Done.
    return linkedPackages;
  }

  /**
   * Return all available unlinked [PackageBundle]s for the given [context],
   * maybe an empty map, but not `null`.
   */
  Map<PubPackage, PackageBundle> getUnlinkedBundles(AnalysisContext context) {
    bool strong = context.analysisOptions.strongMode;
    Map<PubPackage, PackageBundle> unlinkedBundles =
        new HashMap<PubPackage, PackageBundle>();
    Map<String, List<Folder>> packageMap = context.sourceFactory.packageMap;
    if (packageMap != null) {
      packageMap.forEach((String packageName, List<Folder> libFolders) {
        if (libFolders.length == 1) {
          Folder libFolder = libFolders.first;
          PubPackage package = new PubPackage(packageName, libFolder);
          PackageBundle unlinkedBundle =
              _getUnlinkedOrSchedule(package, strong);
          if (unlinkedBundle != null) {
            unlinkedBundles[package] = unlinkedBundle;
          }
        }
      });
    }
    return unlinkedBundles;
  }

  /**
   * Compute unlinked bundle for a package from [packagesToComputeUnlinked],
   * and schedule delayed computation for the next package, if any.
   */
  void _computeNextUnlinked() {
    if (packagesToComputeUnlinked.isNotEmpty) {
      PubPackage package = packagesToComputeUnlinked.first;
      _computeUnlinked(package, false);
      _computeUnlinked(package, true);
      packagesToComputeUnlinked.remove(package);
      _scheduleNextUnlinked();
    } else {
      if (_onUnlinkedCompleteCompleter != null) {
        _onUnlinkedCompleteCompleter.complete(true);
        _onUnlinkedCompleteCompleter = null;
      }
    }
  }

  /**
   * Compute the unlinked bundle for the package with the given path, put
   * it in the [unlinkedBundleMap] and store into the [resourceProvider].
   *
   * TODO(scheglov) Consider moving into separate isolate(s).
   */
  void _computeUnlinked(PubPackage package, bool strong) {
    Folder libFolder = package.libFolder;
    String libPath = libFolder.path + pathContext.separator;
    PackageBundleAssembler assembler = new PackageBundleAssembler();

    /**
     * Return the `package` [Uri] for the given [path] in the `lib` folder
     * of the current package.
     */
    Uri getUri(String path) {
      String pathInLib = path.substring(libPath.length);
      String uriPath = pathos.posix.joinAll(pathContext.split(pathInLib));
      String uriStr = 'package:${package.name}/$uriPath';
      return FastUri.parse(uriStr);
    }

    /**
     * If the given [file] is a Dart file, add its unlinked unit.
     */
    void addDartFile(File file) {
      String path = file.path;
      if (AnalysisEngine.isDartFileName(path)) {
        Uri uri = getUri(path);
        Source source = file.createSource(uri);
        CompilationUnit unit = _parse(source, strong);
        UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
        assembler.addUnlinkedUnit(source, unlinkedUnit);
      }
    }

    /**
     * Visit the [folder] recursively.
     */
    void addDartFiles(Folder folder) {
      List<Resource> children = folder.getChildren();
      for (Resource child in children) {
        if (child is File) {
          addDartFile(child);
        }
      }
      for (Resource child in children) {
        if (child is Folder) {
          addDartFiles(child);
        }
      }
    }

    try {
      addDartFiles(libFolder);
      List<int> bytes = assembler.assemble().toBuffer();
      String fileName = _getUnlinkedName(strong);
      _writeAtomic(package.folder, fileName, bytes);
    } on FileSystemException {
      // Ignore file system exceptions.
    }
  }

  /**
   * Return the name of the file for an unlinked bundle, in strong or spec mode.
   */
  String _getUnlinkedName(bool strong) {
    if (strong) {
      return UNLINKED_NAME;
    } else {
      return UNLINKED_SPEC_NAME;
    }
  }

  /**
   * Return the unlinked [PackageBundle] for the given [package]. If the bundle
   * has not been compute yet, return `null` and schedule its computation.
   */
  PackageBundle _getUnlinkedOrSchedule(PubPackage package, bool strong) {
    // Try to find in the cache.
    PackageBundle bundle = unlinkedBundleMap[package];
    if (bundle != null) {
      return bundle;
    }
    // Try to read from the file system.
    String fileName = _getUnlinkedName(strong);
    File unlinkedFile = package.folder.getChildAssumingFile(fileName);
    if (unlinkedFile.exists) {
      try {
        List<int> bytes = unlinkedFile.readAsBytesSync();
        bundle = new PackageBundle.fromBuffer(bytes);
        unlinkedBundleMap[package] = bundle;
        // TODO(scheglov) if not in the pub cache, check for consistency
        return bundle;
      } on FileSystemException {
        // Ignore file system exceptions.
      }
    }
    // Schedule computation in the background, if in the pub cache.
    if (isPathInPubCache(pathContext, package.folder.path)) {
      if (seenPackages.add(package)) {
        if (packagesToComputeUnlinked.isEmpty) {
          _scheduleNextUnlinked();
        }
        packagesToComputeUnlinked.add(package);
      }
    }
    // The bundle is for available.
    return null;
  }

  /**
   * Parse the given [source] into AST.
   */
  CompilationUnit _parse(Source source, bool strong) {
    String code = source.contents.data;
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(source, reader, errorListener);
    scanner.scanGenericMethodComments = strong;
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    Parser parser = new Parser(source, errorListener);
    parser.parseGenericMethodComments = strong;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }

  /**
   * Schedule delayed computation of the next package unlinked bundle from the
   * set of [packagesToComputeUnlinked].  We delay each computation because we
   * want operations in analysis server to proceed, and computing bundles of
   * packages is a background task.
   */
  void _scheduleNextUnlinked() {
    new Future.delayed(new Duration(milliseconds: 10), _computeNextUnlinked);
  }

  /**
   * Atomically write the given [bytes] into the file in the [folder].
   */
  void _writeAtomic(Folder folder, String fileName, List<int> bytes) {
    String filePath = folder.getChildAssumingFile(fileName).path;
    File tempFile = folder.getChildAssumingFile(tempFileName);
    tempFile.writeAsBytesSync(bytes);
    tempFile.renameSync(filePath);
  }

  /**
   * If the given [uri] has the `package` scheme, return the name of the
   * package that contains the referenced resource.  Otherwise return `null`.
   *
   * For example `package:foo/bar.dart` => `foo`.
   */
  static String getPackageName(String uri) {
    const String PACKAGE_SCHEME = 'package:';
    if (uri.startsWith(PACKAGE_SCHEME)) {
      int index = uri.indexOf('/');
      if (index != -1) {
        return uri.substring(PACKAGE_SCHEME.length, index);
      }
    }
    return null;
  }

  /**
   * Return `true` if the given absolute [path] is in the pub cache.
   */
  static bool isPathInPubCache(pathos.Context pathContext, String path) {
    List<String> parts = pathContext.split(path);
    for (int i = 0; i < parts.length - 1; i++) {
      if (parts[i] == '.pub-cache') {
        return true;
      }
      if (parts[i] == 'Pub' && parts[i + 1] == 'Cache') {
        return true;
      }
    }
    return false;
  }
}

/**
 * Specialization of [Node] for linking packages in proper dependency order.
 */
class _LinkedNode extends Node<_LinkedNode> {
  final PubPackage package;
  final PackageBundle unlinked;
  final Map<String, _LinkedNode> packageToNode;

  PackageBundleBuilder linkedBuilder;
  bool failed = false;

  _LinkedNode(this.package, this.unlinked, this.packageToNode);

  @override
  bool get isEvaluated => linkedBuilder != null || failed;

  @override
  List<_LinkedNode> computeDependencies() {
    if (failed) {
      return const <_LinkedNode>[];
    }

    Set<_LinkedNode> dependencies = new Set<_LinkedNode>();

    void appendDependency(String uriStr) {
      Uri uri = FastUri.parse(uriStr);
      if (!uri.hasScheme) {
        // A relative path in this package, skip it.
      } else if (uri.scheme == 'dart') {
        // Dependency on the SDK is implicit and always added.
        // The SDK linked bundle is precomputed before linking packages.
      } else if (uriStr.startsWith('package:')) {
        String package = PubSummaryManager.getPackageName(uriStr);
        _LinkedNode packageNode = packageToNode[package];
        if (packageNode == null) {
          failed = true;
          throw new _LinkException();
        }
        dependencies.add(packageNode);
      } else {
        failed = true;
        throw new _LinkException();
      }
    }

    for (UnlinkedUnit unit in unlinked.unlinkedUnits) {
      for (UnlinkedImport import in unit.imports) {
        if (!import.isImplicit) {
          appendDependency(import.uri);
        }
      }
      for (UnlinkedExportPublic export in unit.publicNamespace.exports) {
        appendDependency(export.uri);
      }
    }

    return dependencies.toList();
  }

  @override
  String toString() => package.toString();
}

/**
 * Specialization of [DependencyWalker] for linking packages.
 */
class _LinkedWalker extends DependencyWalker<_LinkedNode> {
  final SummaryDataStore store;
  final bool strong;

  _LinkedWalker(this.store, this.strong);

  @override
  void evaluate(_LinkedNode node) {
    evaluateScc([node]);
  }

  @override
  void evaluateScc(List<_LinkedNode> scc) {
    Map<String, _LinkedNode> uriToNode = <String, _LinkedNode>{};
    for (_LinkedNode node in scc) {
      for (String uri in node.unlinked.unlinkedUnitUris) {
        uriToNode[uri] = node;
      }
    }
    Set<String> libraryUris = uriToNode.keys.toSet();
    // Perform linking.
    Map<String, LinkedLibraryBuilder> linkedLibraries =
        link(libraryUris, (String absoluteUri) {
      LinkedLibrary dependencyLibrary = store.linkedMap[absoluteUri];
      if (dependencyLibrary == null) {
        scc.forEach((node) => node.failed = true);
        throw new _LinkException();
      }
      return dependencyLibrary;
    }, (String absoluteUri) {
      UnlinkedUnit unlinkedUnit = store.unlinkedMap[absoluteUri];
      if (unlinkedUnit == null) {
        scc.forEach((node) => node.failed = true);
        throw new _LinkException();
      }
      return unlinkedUnit;
    }, strong);
    // Assemble linked bundles and put them into the store.
    for (_LinkedNode node in scc) {
      PackageBundleAssembler assembler = new PackageBundleAssembler();
      linkedLibraries.forEach((uri, linkedLibrary) {
        if (identical(uriToNode[uri], node)) {
          assembler.addLinkedLibrary(uri, linkedLibrary);
        }
      });
      node.linkedBuilder = assembler.assemble();
      store.addBundle(null, node.linkedBuilder);
    }
  }
}

/**
 * This exception is thrown during linking as a signal that linking of the
 * current bundle cannot be performed, e.g. when a dependency cannot be found.
 */
class _LinkException {}
