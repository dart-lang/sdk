// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/**
 * Return the [Folder] where bundles for the given [absoluteUri] should be
 * looked for. This folder should contain corresponding `*.full.ds` files,
 * possibly more than one one.  Return `null` if the given [absoluteUri]
 * does not have the expected structure, so the output path cannot be computed.
 */
typedef Folder GetOutputFolder(Uri absoluteUri);

/**
 * Load linked packages on demand from [SummaryProvider].
 */
class BazelResultProvider extends ResynthesizerResultProvider {
  final SummaryDataStore dataStore;
  final SummaryProvider summaryProvider;

  final Map<Source, bool> sourceToSuccessMap = <Source, bool>{};
  final Set<Package> addedPackages = new Set<Package>();

  factory BazelResultProvider(SummaryProvider summaryProvider) {
    SummaryDataStore dataStore = new SummaryDataStore(const <String>[]);
    return new BazelResultProvider._(dataStore, summaryProvider);
  }

  BazelResultProvider._(
      SummaryDataStore dataStore, SummaryProvider summaryProvider)
      : dataStore = dataStore,
        summaryProvider = summaryProvider,
        super(summaryProvider.context, dataStore) {
    AnalysisContext sdkContext = context.sourceFactory.dartSdk.context;
    createResynthesizer(sdkContext, sdkContext.typeProvider);
  }

  @override
  bool hasResultsForSource(Source source) {
    return sourceToSuccessMap.putIfAbsent(source, () {
      List<Package> packages = summaryProvider.getLinkedPackages(source);
      if (packages == null) {
        return false;
      }
      for (Package package in packages) {
        if (addedPackages.add(package)) {
          dataStore.addBundle(null, package.unlinked);
          dataStore.addBundle(null, package.linked);
        }
      }
      String uriString = source.uri.toString();
      return resynthesizer.hasLibrarySummary(uriString);
    });
  }
}

/**
 * Information about a Dart package in Bazel.
 */
class Package {
  final File unlinkedFile;
  final PackageBundle unlinked;
  final Set<String> _unitUris = new Set<String>();

  PackageBundle _linked;

  Package(this.unlinkedFile, this.unlinked) {
    _unitUris.addAll(unlinked.unlinkedUnitUris);
  }

  PackageBundle get linked => _linked;

  @override
  String toString() => '$unlinkedFile';
}

/**
 * Class that reads summaries of Bazel packages.
 *
 * When the client needs to produce a resolution result for a new [Source], it
 * should call [getLinkedPackages] to check whether there is the set of
 * packages to resynthesize resolution results.
 */
class SummaryProvider {
  final ResourceProvider provider;
  final String tempFileName;
  final GetOutputFolder getOutputFolder;
  final Folder linkedCacheFolder;
  final AnalysisContext context;
  final PackageBundle sdkBundle;

  /**
   * If `true` (by default), then linking new bundles is allowed.
   * Otherwise only using existing cached bundles can be used.
   */
  final bool allowLinking;

  /**
   * See [PackageBundleAssembler.currentMajorVersion].
   */
  final int majorVersion;

  /**
   * Mapping from bundle paths to corresponding [Package]s.  The packages in
   * the map were consistent with their constituent sources at the moment when
   * they were put into the map.
   */
  final Map<Folder, List<Package>> folderToPackagesMap = {};

  /**
   * Mapping from [Uri]s to corresponding [Package]s.
   */
  final Map<Uri, Package> uriToPackageMap = {};

  /**
   * Mapping from [Package]s to corresponding [_LinkNode]s.
   */
  final Map<Package, _LinkNode> packageToNodeMap = {};

  SummaryProvider(
      this.provider,
      this.tempFileName,
      this.getOutputFolder,
      this.linkedCacheFolder,
      AnalysisContext context,
      {@visibleForTesting
          this.allowLinking: true,
      @visibleForTesting
          this.majorVersion: PackageBundleAssembler.currentMajorVersion})
      : context = context,
        sdkBundle = context.sourceFactory.dartSdk?.getLinkedBundle();

  /**
   * Return the complete list of [Package]s that are required to provide all
   * resolution results for the given [source].
   *
   * The same list of packages is returned for the same [Source], i.e. always
   * the full list, not a difference with a previous request.  It is up to the
   * client to decide whether some of the returned packages should be excluded
   * as already mixed into a resynthesizer.
   *
   * If the full set of packages cannot be produced, for example because some
   * bundles are not built, or out of date, etc, then `null` is returned.
   */
  List<Package> getLinkedPackages(Source source) {
    // Find the node that contains the source.
    _LinkNode node = _getLinkNodeForUri(source.uri);
    if (node == null) {
      return null;
    }

    // Compute all transitive dependencies.
    node.computeTransitiveDependencies();
    List<_LinkNode> nodes = node.transitiveDependencies.toList();
    nodes.forEach((dependency) => dependency.computeTransitiveDependencies());

    // Fail if any dependency cannot be resolved.
    if (node.failed) {
      return null;
    }

    // Read existing cached linked bundles.
    for (_LinkNode node in nodes) {
      _readLinked(node);
    }

    // Link new packages, if allowed.
    if (allowLinking) {
      _link(nodes);
    }

    // Create successfully linked packages.
    return nodes
        .map((node) => node.package)
        .where((package) => package.linked != null)
        .toList();
  }

  /**
   * Return the [Package] that contains information about the source with
   * the given [uri], or `null` if such package does not exist.
   */
  @visibleForTesting
  Package getUnlinkedForUri(Uri uri) {
    return uriToPackageMap.putIfAbsent(uri, () {
      Folder outputFolder = getOutputFolder(uri);
      if (outputFolder != null) {
        String uriStr = uri.toString();
        List<Package> packages = _getUnlinkedPackages(outputFolder);
        for (Package package in packages) {
          if (package._unitUris.contains(uriStr)) {
            return package;
          }
        }
      }
      return null;
    });
  }

  /**
   * Return the hexadecimal string of the MD5 hash of the contents of the
   * given [source] in [context].
   */
  String _computeSourceHashHex(Source source) {
    String text = context.getContents(source).data;
    List<int> bytes = UTF8.encode(text);
    List<int> hashBytes = md5.convert(bytes).bytes;
    return hex.encode(hashBytes);
  }

  /**
   * Return the name of the file for a linked bundle, in strong or spec mode.
   */
  String _getLinkedName(String hash) {
    if (context.analysisOptions.strongMode) {
      return 'linked_$hash.ds';
    } else {
      return 'linked_spec_$hash.ds';
    }
  }

  /**
   * Return the node for the given [uri], or `null` if there is no unlinked
   * bundle that contains [uri].
   */
  _LinkNode _getLinkNodeForUri(Uri uri) {
    Package package = getUnlinkedForUri(uri);
    return packageToNodeMap.putIfAbsent(package, () {
      if (package == null) {
        return null;
      }
      return new _LinkNode(this, package);
    });
  }

  /**
   * Return all consistent unlinked [Package]s in the given [folder].  Some of
   * the returned packages might be already linked.
   */
  List<Package> _getUnlinkedPackages(Folder folder) {
    List<Package> packages = folderToPackagesMap[folder];
    if (packages == null) {
      packages = <Package>[];
      try {
        List<Resource> children = folder.getChildren();
        for (Resource child in children) {
          if (child is File) {
            String packagePath = child.path;
            if (packagePath.toLowerCase().endsWith('.full.ds')) {
              Package package = _readUnlinkedPackage(child);
              if (package != null) {
                packages.add(package);
              }
            }
          }
        }
      } on FileSystemException {}
      folderToPackagesMap[folder] = packages;
    }
    return packages;
  }

  /**
   * Return `true` if the unlinked information of the [bundle] is consistent
   * with its constituent sources in [context].
   */
  bool _isUnlinkedBundleConsistent(PackageBundle bundle) {
    try {
      // Compute hashes of the constituent sources.
      List<String> actualHashes = <String>[];
      for (String uri in bundle.unlinkedUnitUris) {
        Source source = context.sourceFactory.resolveUri(null, uri);
        if (source == null) {
          return false;
        }
        String hash = _computeSourceHashHex(source);
        actualHashes.add(hash);
      }
      // Compare sorted actual and bundle unit hashes.
      List<String> bundleHashes = bundle.unlinkedUnitHashes.toList()..sort();
      actualHashes.sort();
      return listsEqual(actualHashes, bundleHashes);
    } on FileSystemException {}
    return false;
  }

  /**
   * Link the given [nodes].
   */
  void _link(List<_LinkNode> nodes) {
    // Fill the store with bundles.
    // Append the linked SDK bundle.
    // Append unlinked and (if read from a cache) linked package bundles.
    SummaryDataStore store = new SummaryDataStore(const <String>[]);
    store.addBundle(null, sdkBundle);
    for (_LinkNode node in nodes) {
      store.addBundle(null, node.package.unlinked);
      if (node.package.linked != null) {
        store.addBundle(null, node.package.linked);
      }
    }

    // Prepare URIs to link.
    Map<String, _LinkNode> uriToNode = <String, _LinkNode>{};
    for (_LinkNode node in nodes) {
      if (!node.isReady) {
        for (String uri in node.package.unlinked.unlinkedUnitUris) {
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
    }, context.declaredVariables.get, context.analysisOptions.strongMode);

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
        node.package._linked = new PackageBundle.fromBuffer(bytes);
        _writeLinked(node, bytes);
      }
    }
  }

  /**
   * Attempt to read the linked bundle that corresponds to the given [node]
   * with all its transitive dependencies.
   */
  void _readLinked(_LinkNode node) {
    String hash = node.linkedHash;
    if (!node.isReady && hash != null) {
      String fileName = _getLinkedName(hash);
      File file = linkedCacheFolder.getChildAssumingFile(fileName);
      // Try to read from the file system.
      if (file.exists) {
        try {
          List<int> bytes = file.readAsBytesSync();
          node.package._linked = new PackageBundle.fromBuffer(bytes);
        } on FileSystemException {
          // Ignore file system exceptions.
        }
      }
    }
  }

  /**
   * Read the unlinked [Package] from the given [file], or return `null` if the
   * file does not exist, or it cannot be read, or is not consistent with the
   * constituent sources on the file system.
   */
  Package _readUnlinkedPackage(File file) {
    try {
      List<int> bytes = file.readAsBytesSync();
      PackageBundle bundle = new PackageBundle.fromBuffer(bytes);
      // Check the major version.
      if (bundle.majorVersion != majorVersion) {
        return null;
      }
      // Check for consistency, and fail if it's not.
      if (!_isUnlinkedBundleConsistent(bundle)) {
        return null;
      }
      // OK, use the bundle.
      return new Package(file, bundle);
    } on FileSystemException {}
    return null;
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
   * If a new linked bundle was linked for the given [node], write the bundle
   * into the memory cache and the file system.
   */
  void _writeLinked(_LinkNode node, List<int> bytes) {
    String hash = node.linkedHash;
    if (hash != null) {
      String fileName = _getLinkedName(hash);
      _writeAtomic(linkedCacheFolder, fileName, bytes);
    }
  }
}

/**
 * Information about a single [Package].
 */
class _LinkNode {
  final SummaryProvider linker;
  final Package package;

  bool failed = false;
  Set<_LinkNode> transitiveDependencies;

  List<_LinkNode> _dependencies;
  String _linkedHash;

  _LinkNode(this.linker, this.package);

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
        } else if (uri.scheme == 'package') {
          _LinkNode packageNode = linker._getLinkNodeForUri(uri);
          if (packageNode == null) {
            failed = true;
          }
          if (packageNode != null) {
            dependencies.add(packageNode);
          }
        } else {
          failed = true;
        }
      }

      for (UnlinkedUnit unit in package.unlinked.unlinkedUnits) {
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
  bool get isReady => package.linked != null || failed;

  /**
   * Return the hash string that corresponds to this linked bundle in the
   * context of its SDK bundle and transitive dependencies.  Return `null` if
   * the hash computation fails, because for example the full transitive
   * dependencies cannot computed.
   */
  String get linkedHash {
    if (_linkedHash == null && transitiveDependencies != null && !failed) {
      ApiSignature signature = new ApiSignature();
      // Add all unlinked API signatures.
      List<String> signatures = <String>[];
      signatures.add(linker.sdkBundle.apiSignature);
      transitiveDependencies
          .map((node) => node.package.unlinked.apiSignature)
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
      for (UnlinkedUnit unit in node.package.unlinked.unlinkedUnits) {
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
      signature.addString(linker.context.declaredVariables.get(name) ?? '');
    }
  }

  /**
   * Compute the set of existing transitive dependencies for this node.
   * If any dependency cannot be resolved, then set [failed] to `true`.
   * Only unlinked bundle is used, so this method can be called before linking.
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
