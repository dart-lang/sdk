// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.source.package_map_resolver;

import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/asserts.dart' as asserts;
import 'package:path/path.dart' as pathos;

/**
 * A [UriResolver] implementation for the `package:` scheme that uses a map of
 * package names to their directories.
 */
class PackageMapUriResolver extends UriResolver {
  /**
   * The name of the `package` scheme.
   */
  static const String PACKAGE_SCHEME = "package";

  /**
   * A table mapping package names to the path of the directories containing
   * the package.
   */
  final Map<String, List<Folder>> packageMap;

  /**
   * The [ResourceProvider] for this resolver.
   */
  final ResourceProvider resourceProvider;

  /**
   * Create a new [PackageMapUriResolver].
   *
   * [packageMap] is a table mapping package names to the paths of the
   * directories containing the package
   */
  PackageMapUriResolver(this.resourceProvider, this.packageMap) {
    asserts.notNull(resourceProvider);
    asserts.notNull(packageMap);
    packageMap.forEach((name, folders) {
      if (folders.length != 1) {
        throw new ArgumentError(
            'Exactly one folder must be specified for a package.'
            'Found $name = $folders');
      }
    });
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!isPackageUri(uri)) {
      return null;
    }
    // Prepare path.
    String path = uri.path;
    // Prepare path components.
    int index = path.indexOf('/');
    if (index == -1 || index == 0) {
      return null;
    }
    // <pkgName>/<relPath>
    String pkgName = path.substring(0, index);
    String relPath = path.substring(index + 1);
    // If the package is known, return the corresponding file.
    List<Folder> packageDirs = packageMap[pkgName];
    if (packageDirs != null) {
      Folder packageDir = packageDirs.single;
      File file = packageDir.getChildAssumingFile(relPath);
      return file.createSource(uri);
    }
    return null;
  }

  @override
  Uri restoreAbsolute(Source source) {
    String sourcePath = source.fullName;
    pathos.Context pathContext = resourceProvider.pathContext;
    for (String pkgName in packageMap.keys) {
      Folder pkgFolder = packageMap[pkgName][0];
      String pkgFolderPath = pkgFolder.path;
      if (sourcePath.startsWith(pkgFolderPath + pathContext.separator)) {
        String relPath = sourcePath.substring(pkgFolderPath.length + 1);
        List<String> relPathComponents = pathContext.split(relPath);
        String relUriPath = pathos.posix.joinAll(relPathComponents);
        return Uri.parse('$PACKAGE_SCHEME:$pkgName/$relUriPath');
      }
    }
    return null;
  }

  /**
   * Returns `true` if [uri] is a `package` URI.
   */
  static bool isPackageUri(Uri uri) {
    return uri.scheme == PACKAGE_SCHEME;
  }
}
