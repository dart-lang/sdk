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
    // Try to find an existing file.
    List<Folder> packageDirs = packageMap[pkgName];
    if (packageDirs != null) {
      for (Folder packageDir in packageDirs) {
        if (packageDir.exists) {
          Resource result = packageDir.getChild(relPath);
          if (result is File && result.exists) {
            return result.createSource(uri);
          }
        }
      }
    }
    // Return a NonExistingSource instance.
    // This helps provide more meaningful error messages to users
    // (a missing file error, as opposed to an invalid URI error).
    String fullPath = packageDirs != null && packageDirs.isNotEmpty
        ? packageDirs.first.canonicalizePath(relPath)
        : relPath;
    return new NonExistingSource(fullPath, uri, UriKind.PACKAGE_URI);
  }

  @override
  Uri restoreAbsolute(Source source) {
    String sourcePath = source.fullName;
    Uri bestMatch;
    int bestMatchLength = -1;
    pathos.Context pathContext = resourceProvider.pathContext;
    for (String pkgName in packageMap.keys) {
      List<Folder> pkgFolders = packageMap[pkgName];
      for (int i = 0; i < pkgFolders.length; i++) {
        Folder pkgFolder = pkgFolders[i];
        String pkgFolderPath = pkgFolder.path;
        if (pkgFolderPath.length > bestMatchLength &&
            sourcePath.startsWith(pkgFolderPath + pathContext.separator)) {
          String relPath = sourcePath.substring(pkgFolderPath.length + 1);
          if (_isReversibleTranslation(pkgFolders, i, relPath)) {
            List<String> relPathComponents = pathContext.split(relPath);
            String relUriPath = pathos.posix.joinAll(relPathComponents);
            bestMatch = Uri.parse('$PACKAGE_SCHEME:$pkgName/$relUriPath');
            bestMatchLength = pkgFolderPath.length;
          }
        }
      }
    }
    return bestMatch;
  }

  /**
   * A translation from file path to package URI has just been found for
   * using the [packageDirIndex]th element of [packageDirs], and appending the
   * relative path [relPath].  Determine whether the translation is reversible;
   * that is, whether translating the package URI pack to a file path will
   * produce the file path we started with.
   */
  bool _isReversibleTranslation(
      List<Folder> packageDirs, int packageDirIndex, String relPath) {
    // The translation is reversible provided there is no prior element of
    // [packageDirs] containing a file matching [relPath].
    for (int i = 0; i < packageDirIndex; i++) {
      Folder packageDir = packageDirs[i];
      if (packageDir.exists) {
        Resource result = packageDir.getChild(relPath);
        if (result is File && result.exists) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * Returns `true` if [uri] is a `package` URI.
   */
  static bool isPackageUri(Uri uri) {
    return uri.scheme == PACKAGE_SCHEME;
  }
}
