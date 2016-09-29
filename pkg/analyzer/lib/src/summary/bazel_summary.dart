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
 * Return the [Folder] where bundles for the given [absoluteUri] should be
 * looked for. This folder should contain corresponding `*.full.ds` files,
 * possibly more than one one.  Return `null` if the given [absoluteUri]
 * does not have the expected structure, so the output path cannot be computed.
 */
typedef Folder GetOutputFolder(Uri absoluteUri);

/**
 * Information about a Dart package in Bazel.
 */
class Package {
  final File unlinkedFile;
  final PackageBundle unlinked;
  final Set<String> _unitUris = new Set<String>();

  Package(this.unlinkedFile, this.unlinked) {
    _unitUris.addAll(unlinked.unlinkedUnitUris);
  }
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
  final GetOutputFolder getOutputFolder;
  final AnalysisContext context;

  /**
   * Mapping from bundle paths to corresponding [Package]s.  The packages in
   * the map were consistent with their constituent sources at the moment when
   * they were put into the map.
   */
  final Map<Folder, List<Package>> folderToPackagesMap = {};

  SummaryProvider(this.provider, this.getOutputFolder, this.context);

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
    // TODO(scheglov) implement
    return null;
  }

  /**
   * Return the [Package] that contains information about the source with
   * the given [uri], or `null` if such package does not exist.
   */
  @visibleForTesting
  Package getUnlinkedForUri(Uri uri) {
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
   * Read the unlinked [Package] from the given [file], or return `null` if the
   * file does not exist, or it cannot be read, or is not consistent with the
   * constituent sources on the file system.
   */
  Package _readUnlinkedPackage(File file) {
    try {
      List<int> bytes = file.readAsBytesSync();
      PackageBundle bundle = new PackageBundle.fromBuffer(bytes);
      // Check for consistency, and fail if it's not.
      if (!_isUnlinkedBundleConsistent(bundle)) {
        return null;
      }
      // OK, use the bundle.
      return new Package(file, bundle);
    } on FileSystemException {}
    return null;
  }
}
