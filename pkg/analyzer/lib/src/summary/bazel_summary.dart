// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/**
 * Return the path of the directory where bundles for the given [uri] should be
 * looked for.  This directory should contain corresponding pairs of `*.api.ds`
 * and `*.full.ds` files, possibly more than one pair.  Return `null` if the
 * given [uri] does not have the expected structure, so the output path cannot
 * be computed.
 */
typedef String GetOutputPath(ResourceProvider provider, Uri uri);

/**
 * Information about a Dart package in Bazel.
 */
class Package {
  final String bundlePath;
  final PackageBundle bundle;
  final Set<String> _unitUris = new Set<String>();

  Package(this.bundlePath, this.bundle) {
    _unitUris.addAll(bundle.unlinkedUnitUris);
  }
}

/**
 * Class that reads summaries of Bazel packages.
 *
 * When the client needs to produce a resolution result for a new [Source], it
 * should call [getPackages] to checked whether there is the set of packages
 * to resynthesize resolution results.
 */
class SummaryProvider {
  final ResourceProvider provider;
  final GetOutputPath getOutputPath;
  final AnalysisContext context;

  /**
   * Mapping from bundle paths to corresponding [Package]s.  The packages in
   * the map were consistent with their constituent sources at the moment when
   * they were put into the map.
   */
  final Map<String, Package> bundlePathToPackageMap = <String, Package>{};

  /**
   * When we detected than some bundle is not consistent with its constituent
   * sources (i.e. even its unlinked state is not consistent), we remember
   * this fact to avoid loading and checking consistency next time.
   */
  final Set<String> knownInconsistentBundlePaths = new Set<String>();

  SummaryProvider(this.provider, this.getOutputPath, this.context);

  /**
   * Return the [Package] that contains information about the source with
   * the given [uri], or `null` if such package does not exist.
   */
  @visibleForTesting
  Package getPackageForUri(Uri uri) {
    String outputPath = getOutputPath(provider, uri);
    if (outputPath != null) {
      List<Package> packages = _getPackages(outputPath);
      for (Package package in packages) {
        String uriStr = uri.toString();
        if (package._unitUris.contains(uriStr)) {
          return package;
        }
      }
    }
    return null;
  }

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
  List<PackageBundle> getPackages(Source source) {
    // TODO(scheglov) implement
    return null;
  }

  /**
   * Return the hexadecimal string for the given [source] contents.
   */
  String _computeSourceHashHex(Source source) {
    String text = context.getContents(source).data;
    List<int> bytes = UTF8.encode(text);
    List<int> hashBytes = md5.convert(bytes).bytes;
    return hex.encode(hashBytes);
  }

  /**
   * Return the [Package] from the file with the given [path], or `null` if the
   * file does not exist, or it cannot be read, or is not consistent with the
   * sources it contains, etc.
   */
  Package _getPackage(String path) {
    // Check if the bundle know to be inconsistent, missing, etc.
    if (knownInconsistentBundlePaths.contains(path)) {
      return null;
    }
    // Attempt to get from the cache or read from the file system.
    try {
      Package package = bundlePathToPackageMap[path];
      if (package == null) {
        File file = provider.getFile(path);
        List<int> bytes = file.readAsBytesSync();
        PackageBundle bundle = new PackageBundle.fromBuffer(bytes);
        // Check for consistency, and fail if it's not.
        if (!_isUnlinkedBundleConsistent(bundle)) {
          knownInconsistentBundlePaths.add(path);
          return null;
        }
        // OK, put the package into the cache.
        package = new Package(path, bundle);
        bundlePathToPackageMap[path] = package;
      }
      return package;
    } catch (_) {
      return null;
    }
  }

  /**
   * Return all consistent [Package]s in the given [folderPath].
   */
  List<Package> _getPackages(String folderPath) {
    List<Package> packages = <Package>[];
    try {
      Folder folder = provider.getFolder(folderPath);
      List<Resource> children = folder.getChildren();
      for (Resource child in children) {
        if (child is File) {
          String packagePath = child.path;
          if (packagePath.toLowerCase().endsWith('.full.ds')) {
            Package package = _getPackage(packagePath);
            if (package != null) {
              packages.add(package);
            }
          }
        }
      }
    } on FileSystemException {}
    return packages;
  }

  /**
   * Return `true` if the unlinked information of the [bundle] is consistent
   * with its constituent sources.
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
    } catch (_) {
      return false;
    }
  }
}
