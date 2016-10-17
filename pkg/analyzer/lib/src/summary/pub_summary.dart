// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/summary/api_signature.dart';
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
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as pathos;

/**
 * Unlinked and linked information about a [PubPackage].
 */
class LinkedPubPackage {
  final PubPackage package;
  final PackageBundle unlinked;
  final PackageBundle linked;

  final String linkedHash;

  LinkedPubPackage(this.package, this.unlinked, this.linked, this.linkedHash);

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

  /**
   * If `true` (by default), then linking new bundles is allowed.
   * Otherwise only using existing cached bundles can be used.
   */
  final bool allowLinking;

  /**
   * See [PackageBundleAssembler.currentMajorVersion].
   */
  final int majorVersion;

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
   * The map from linked file paths to the corresponding linked bundles.
   */
  final Map<String, PackageBundle> linkedBundleMap =
      new HashMap<String, PackageBundle>();

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

  PubSummaryManager(this.resourceProvider, this.tempFileName,
      {@visibleForTesting this.allowLinking: true,
      @visibleForTesting this.majorVersion:
          PackageBundleAssembler.currentMajorVersion});

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
   * Complete when the unlinked bundles for the package with the given [name]
   * and the [libFolder] are computed and written to the files.
   *
   * This method is intended to be used for generating unlinked bundles for
   * the `Flutter` packages.
   */
  Future<Null> computeUnlinkedForFolder(String name, Folder libFolder) async {
    PubPackage package = new PubPackage(name, libFolder);
    _scheduleUnlinked(package);
    await onUnlinkedComplete;
  }

  /**
   * Return the list of linked [LinkedPubPackage]s that can be provided at this
   * time for a subset of the packages used by the given [context].  If
   * information about some of the used packages is not available yet, schedule
   * its computation, so that it might be available later for other contexts
   * referencing the same packages.
   */
  List<LinkedPubPackage> getLinkedBundles(AnalysisContext context) {
    return new _ContextLinker(this, context).getLinkedBundles();
  }

  /**
   * Return all available unlinked [PackageBundle]s for the given [context],
   * maybe an empty map, but not `null`.
   */
  @visibleForTesting
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
      PackageBundleBuilder bundleWriter = assembler.assemble();
      bundleWriter.majorVersion = majorVersion;
      List<int> bytes = bundleWriter.toBuffer();
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
    File file = package.folder.getChildAssumingFile(fileName);
    if (file.exists) {
      try {
        List<int> bytes = file.readAsBytesSync();
        bundle = new PackageBundle.fromBuffer(bytes);
      } on FileSystemException {
        // Ignore file system exceptions.
      }
    }

    // Verify compatibility and consistency.
    bool isInPubCache = isPathInPubCache(pathContext, package.folder.path);
    if (bundle != null &&
        bundle.majorVersion == majorVersion &&
        (isInPubCache || _isConsistent(package, bundle))) {
      unlinkedBundleMap[package] = bundle;
      return bundle;
    }

    // Schedule computation in the background, if in the pub cache.
    if (isInPubCache) {
      if (seenPackages.add(package)) {
        _scheduleUnlinked(package);
      }
    }

    // The bundle is not available.
    return null;
  }

  /**
   * Return `true` if content hashes for the [package] library files are the
   * same the hashes in the unlinked [bundle].
   */
  bool _isConsistent(PubPackage package, PackageBundle bundle) {
    List<String> actualHashes = <String>[];

    /**
     * If the given [file] is a Dart file, add its content hash.
     */
    void hashDartFile(File file) {
      String path = file.path;
      if (AnalysisEngine.isDartFileName(path)) {
        List<int> fileBytes = file.readAsBytesSync();
        List<int> hashBytes = md5.convert(fileBytes).bytes;
        String hashHex = hex.encode(hashBytes);
        actualHashes.add(hashHex);
      }
    }

    /**
     * Visit the [folder] recursively.
     */
    void hashDartFiles(Folder folder) {
      List<Resource> children = folder.getChildren();
      for (Resource child in children) {
        if (child is File) {
          hashDartFile(child);
        } else if (child is Folder) {
          hashDartFiles(child);
        }
      }
    }

    // Recursively compute hashes of the `lib` folder Dart files.
    try {
      hashDartFiles(package.libFolder);
    } on FileSystemException {
      return false;
    }

    // Compare sorted actual and bundle unit hashes.
    List<String> bundleHashes = bundle.unlinkedUnitHashes.toList()..sort();
    actualHashes.sort();
    return listsEqual(actualHashes, bundleHashes);
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
   * Schedule computing unlinked bundles for the given [package].
   */
  void _scheduleUnlinked(PubPackage package) {
    if (packagesToComputeUnlinked.isEmpty) {
      _scheduleNextUnlinked();
    }
    packagesToComputeUnlinked.add(package);
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

class _ContextLinker {
  final PubSummaryManager manager;
  final AnalysisContext context;

  final strong;
  final _ListedPackages listedPackages;
  final PackageBundle sdkBundle;

  final List<_LinkNode> nodes = <_LinkNode>[];
  final Map<String, _LinkNode> packageToNode = <String, _LinkNode>{};

  _ContextLinker(this.manager, AnalysisContext context)
      : context = context,
        strong = context.analysisOptions.strongMode,
        listedPackages = new _ListedPackages(context.sourceFactory),
        sdkBundle = context.sourceFactory.dartSdk.getLinkedBundle();

  /**
   * Return the list of linked [LinkedPubPackage]s that can be provided at this
   * time for a subset of the packages used by the [context].
   */
  List<LinkedPubPackage> getLinkedBundles() {
//    Stopwatch timer = new Stopwatch()..start();

    if (sdkBundle == null) {
      return const <LinkedPubPackage>[];
    }

    Map<PubPackage, PackageBundle> unlinkedBundles =
        manager.getUnlinkedBundles(context);

    // TODO(scheglov) remove debug output after optimizing
//    print('LOADED ${unlinkedBundles.length} unlinked bundles'
//        ' in ${timer.elapsedMilliseconds} ms');
//    timer..reset();

    // If no unlinked bundles, there is nothing we can try to link.
    if (unlinkedBundles.isEmpty) {
      return const <LinkedPubPackage>[];
    }

    // Create nodes for packages.
    unlinkedBundles.forEach((package, unlinked) {
      _LinkNode node = new _LinkNode(this, package, unlinked);
      nodes.add(node);
      packageToNode[package.name] = node;
    });

    // Compute transitive dependencies, mark some nodes as failed.
    for (_LinkNode node in nodes) {
      node.computeTransitiveDependencies();
    }

    // Attempt to read existing linked bundles.
    for (_LinkNode node in nodes) {
      _readLinked(node);
    }

    // Link new packages, if allowed.
    if (manager.allowLinking) {
      _link();
    }

    // Create successfully linked packages.
    List<LinkedPubPackage> linkedPackages = <LinkedPubPackage>[];
    for (_LinkNode node in nodes) {
      if (node.linked != null) {
        linkedPackages.add(new LinkedPubPackage(
            node.package, node.unlinked, node.linked, node.linkedHash));
      }
    }

    // TODO(scheglov) remove debug output after optimizing
//    print('LINKED ${linkedPackages.length} bundles'
//        ' in ${timer.elapsedMilliseconds} ms');

    // Done.
    return linkedPackages;
  }

  String _getDeclaredVariable(String name) {
    return context.declaredVariables.get(name);
  }

  /**
   * Return the name of the file for a linked bundle, in strong or spec mode.
   */
  String _getLinkedName(String hash) {
    if (strong) {
      return 'linked_$hash.ds';
    } else {
      return 'linked_spec_$hash.ds';
    }
  }

  void _link() {
    // Fill the store with bundles.
    // Append the linked SDK bundle.
    // Append unlinked and (if read from a cache) linked package bundles.
    SummaryDataStore store = new SummaryDataStore(const <String>[]);
    store.addBundle(null, sdkBundle);
    for (_LinkNode node in nodes) {
      store.addBundle(null, node.unlinked);
      if (node.linked != null) {
        store.addBundle(null, node.linked);
      }
    }

    // Prepare URIs to link.
    Map<String, _LinkNode> uriToNode = <String, _LinkNode>{};
    for (_LinkNode node in nodes) {
      if (!node.isReady) {
        for (String uri in node.unlinked.unlinkedUnitUris) {
          uriToNode[uri] = node;
        }
      }
    }
    Set<String> libraryUris = uriToNode.keys.toSet();

    // Perform linking.
    Map<String, LinkedLibraryBuilder> linkedLibraries =
        link(libraryUris, (String uri) {
      return store.linkedMap[uri];
    }, (String uri) {
      return store.unlinkedMap[uri];
    }, _getDeclaredVariable, strong);

    // Assemble newly linked bundles.
    for (_LinkNode node in nodes) {
      if (!node.isReady) {
        PackageBundleAssembler assembler = new PackageBundleAssembler();
        linkedLibraries.forEach((uri, linkedLibrary) {
          if (identical(uriToNode[uri], node)) {
            assembler.addLinkedLibrary(uri, linkedLibrary);
          }
        });
        List<int> bytes = assembler.assemble().toBuffer();
        node.linkedNewBytes = bytes;
        node.linked = new PackageBundle.fromBuffer(bytes);
      }
    }

    // Write newly linked bundles.
    for (_LinkNode node in nodes) {
      _writeLinked(node);
    }
  }

  /**
   * Attempt to find the linked bundle that corresponds to the given [node]
   * with all its transitive dependencies and put it into [_LinkNode.linked].
   */
  void _readLinked(_LinkNode node) {
    String hash = node.linkedHash;
    if (hash != null) {
      String fileName = _getLinkedName(hash);
      File file = node.package.folder.getChildAssumingFile(fileName);
      // Try to find in the cache.
      PackageBundle linked = manager.linkedBundleMap[file.path];
      if (linked != null) {
        node.linked = linked;
        return;
      }
      // Try to read from the file system.
      if (file.exists) {
        try {
          List<int> bytes = file.readAsBytesSync();
          linked = new PackageBundle.fromBuffer(bytes);
          manager.linkedBundleMap[file.path] = linked;
          node.linked = linked;
        } on FileSystemException {
          // Ignore file system exceptions.
        }
      }
    }
  }

  /**
   * If a new linked bundle was linked for the given [node], write the bundle
   * into the memory cache and the file system.
   */
  void _writeLinked(_LinkNode node) {
    String hash = node.linkedHash;
    if (hash != null && node.linkedNewBytes != null) {
      String fileName = _getLinkedName(hash);
      File file = node.package.folder.getChildAssumingFile(fileName);
      manager.linkedBundleMap[file.path] = node.linked;
      manager._writeAtomic(node.package.folder, fileName, node.linkedNewBytes);
    }
  }
}

/**
 * Information about a package to link.
 */
class _LinkNode {
  final _ContextLinker linker;
  final PubPackage package;
  final PackageBundle unlinked;

  bool failed = false;
  Set<_LinkNode> transitiveDependencies;

  List<_LinkNode> _dependencies;
  String _linkedHash;

  List<int> linkedNewBytes;
  PackageBundle linked;

  _LinkNode(this.linker, this.package, this.unlinked);

  /**
   * Retrieve the dependencies of this node.
   */
  List<_LinkNode> get dependencies {
    if (_dependencies == null) {
      Set<_LinkNode> dependencies = new Set<_LinkNode>();

      void appendDependency(String uriStr) {
        Uri uri = FastUri.parse(uriStr);
        if (!uri.hasScheme) {
          // A relative path in this package, skip it.
        } else if (uri.scheme == 'dart') {
          // Dependency on the SDK is implicit and always added.
          // The SDK linked bundle is precomputed before linking packages.
        } else if (uriStr.startsWith('package:')) {
          String package = PubSummaryManager.getPackageName(uriStr);
          _LinkNode packageNode = linker.packageToNode[package];
          if (packageNode == null && linker.listedPackages.isListed(uriStr)) {
            failed = true;
          }
          if (packageNode != null) {
            dependencies.add(packageNode);
          }
        } else {
          failed = true;
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

      _dependencies = dependencies.toList();
    }
    return _dependencies;
  }

  /**
   * Return `true` is the node is ready - has the linked bundle or failed (does
   * not have all required dependencies).
   */
  bool get isReady => linked != null || failed;

  /**
   * Return the hash string that corresponds to this linked bundle in the
   * context of its SDK bundle and transitive dependencies.  Return `null` if
   * the hash computation fails, because for example the full transitive
   * dependencies cannot computed.
   */
  String get linkedHash {
    if (_linkedHash == null && transitiveDependencies != null) {
      ApiSignature signature = new ApiSignature();
      // Add all unlinked API signatures.
      List<String> signatures = <String>[];
      signatures.add(linker.sdkBundle.apiSignature);
      transitiveDependencies
          .map((node) => node.unlinked.apiSignature)
          .forEach(signatures.add);
      signatures.sort();
      signatures.forEach(signature.addString);
      // Combine into a single hash.
      appendDeclaredVariables(signature);
      _linkedHash = signature.toHex();
    }
    return _linkedHash;
  }

  /**
   * Append names and values of all referenced declared variables (even the
   * ones without actually declared values) to the given [signature].
   */
  void appendDeclaredVariables(ApiSignature signature) {
    Set<String> nameSet = new Set<String>();
    for (_LinkNode node in transitiveDependencies) {
      for (UnlinkedUnit unit in node.unlinked.unlinkedUnits) {
        for (UnlinkedImport import in unit.imports) {
          for (UnlinkedConfiguration configuration in import.configurations) {
            nameSet.add(configuration.name);
          }
        }
        for (UnlinkedExportPublic export in unit.publicNamespace.exports) {
          for (UnlinkedConfiguration configuration in export.configurations) {
            nameSet.add(configuration.name);
          }
        }
      }
    }
    List<String> sortedNameList = nameSet.toList()..sort();
    signature.addInt(sortedNameList.length);
    for (String name in sortedNameList) {
      signature.addString(name);
      signature.addString(linker._getDeclaredVariable(name) ?? '');
    }
  }

  /**
   * Compute the set of existing transitive dependencies for this node.
   * If any `package` dependency cannot be resolved, but it is one of the
   * [listedPackages] then set [failed] to `true`.
   * Only [unlinked] is used, so this method can be called before linking.
   */
  void computeTransitiveDependencies() {
    if (transitiveDependencies == null) {
      transitiveDependencies = new Set<_LinkNode>();

      void appendDependencies(_LinkNode node) {
        if (transitiveDependencies.add(node)) {
          node.dependencies.forEach(appendDependencies);
        }
      }

      appendDependencies(this);
      if (transitiveDependencies.any((node) => node.failed)) {
        failed = true;
      }
    }
  }

  @override
  String toString() => package.toString();
}

/**
 * The set of package names that are listed in the `.packages` file of a
 * context.  These are the only packages, references to which can
 * be possibly resolved in the context.  Nodes that reference a `package:` URI
 * without the unlinked bundle, so without the node, cannot be linked.
 */
class _ListedPackages {
  final Set<String> names = new Set<String>();

  _ListedPackages(SourceFactory sourceFactory) {
    Map<String, List<Folder>> map = sourceFactory.packageMap;
    if (map != null) {
      names.addAll(map.keys);
    }
  }

  /**
   * Check whether the given `package:` [uri] is listed in the package map.
   */
  bool isListed(String uri) {
    String package = PubSummaryManager.getPackageName(uri);
    return names.contains(package);
  }
}
