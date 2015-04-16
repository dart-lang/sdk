// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source.optimizing_pub_package_map_provider;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/sdk_io.dart';

/**
 * Extension of [PackageMapInfo] that tracks the modification timestamps of
 * pub dependencies.  This allows the analysis server to avoid making redundant
 * calls to "pub list" when nothing has changed.
 */
class OptimizingPubPackageMapInfo extends PackageMapInfo {
  /**
   * Map from file path to the file's modification timestamp prior to running
   * "pub list".  Since the set of dependencies is not always known prior to
   * running "pub list", some or all of the dependencies may be missing from
   * this map.
   */
  final Map<String, int> modificationTimes;

  OptimizingPubPackageMapInfo(Map<String, List<Folder>> packageMap,
      Set<String> dependencies, this.modificationTimes)
      : super(packageMap, dependencies);

  /**
   * Return `true` if the given [path] is listed as a dependency, and we cannot
   * prove using modification timestamps that it is unchanged.
   * [resourceProvider] is used (if necessary) to read the [path]'s
   * modification time.
   */
  bool isChangedDependency(String path, ResourceProvider resourceProvider) {
    if (!dependencies.contains(path)) {
      // Path is not a dependency.
      return false;
    }
    int lastModificationTime = modificationTimes[path];
    if (lastModificationTime != null) {
      Resource resource = resourceProvider.getResource(path);
      if (resource is File) {
        try {
          if (resource.modificationStamp == lastModificationTime) {
            // Path is a dependency, but it hasn't changed since the last run
            // of "pub list".
            return false;
          }
        } on FileSystemException {
          // Path is a dependency, but we can't read its timestamp.  Assume
          // it's changed to be safe.
        }
      }
    }
    // Path is a dependency, and we couldn't prove that it hadn't changed.
    // Assume it's changed to be safe.
    return true;
  }
}

/**
 * Extension of [PubPackageMapProvider] that outputs additional information to
 * allow the analysis server to avoid making redundant calls to "pub list" when
 * nothing has changed.
 */
class OptimizingPubPackageMapProvider extends PubPackageMapProvider {
  OptimizingPubPackageMapProvider(
      ResourceProvider resourceProvider, DirectoryBasedDartSdk sdk, [RunPubList runPubList])
      : super(resourceProvider, sdk, runPubList);

  /**
   * Compute a package map for the given folder by executing "pub list".  If
   * [previousInfo] is provided, it is used as a guess of which files the
   * package map is likely to depend on; the modification times of those files
   * are captured prior to executing "pub list" so that they can be used to
   * avoid making redundant calls to "pub list" in the future.
   *
   * Also, in the case where dependencies can't be determined because of an
   * error, the dependencies from [previousInfo] will be preserved.
   */
  OptimizingPubPackageMapInfo computePackageMap(Folder folder,
      [OptimizingPubPackageMapInfo previousInfo]) {
    // Prior to running "pub list", read the modification timestamps of all of
    // the old dependencies (if known).
    Map<String, int> modificationTimes = <String, int>{};
    if (previousInfo != null) {
      for (String path in previousInfo.dependencies) {
        Resource resource = resourceProvider.getResource(path);
        if (resource is File) {
          try {
            modificationTimes[path] = resource.modificationStamp;
          } on FileSystemException {
            // File no longer exists.  Don't record a timestamp for it; this
            // will ensure that if the file reappears, we will re-run "pub
            // list" regardless of the timestamp it reappears with.
          }
        }
      }
    }

    // Try running "pub list".
    PackageMapInfo info = super.computePackageMap(folder);
    if (info == null) {
      // Computing the package map resulted in an error.  Merge the old
      // dependencies with the new ones, if possible.
      info = super.computePackageMapError(folder);
      if (previousInfo != null) {
        info.dependencies.addAll(previousInfo.dependencies);
      }
    }

    // Discard any elements of modificationTimes that are no longer
    // dependencies.
    if (previousInfo != null) {
      for (String dependency
          in previousInfo.dependencies.difference(info.dependencies)) {
        modificationTimes.remove(dependency);
      }
    }

    // Bundle the modificationTimes with the other info.
    return new OptimizingPubPackageMapInfo(
        info.packageMap, info.dependencies, modificationTimes);
  }

  @override
  PackageMapInfo computePackageMapError(Folder folder) {
    // Return null to indicate to our override of computePackageMap that there
    // was an error, so it can compute dependencies correctly.
    return null;
  }
}
