// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolver.package;

import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/source_io.dart';


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
   * A table mapping package names to the path of the directory containing
   * the package.
   */
  final Map<String, Folder> packageMap;

  /**
   * The [ResourceProvider] for this resolver.
   */
  final ResourceProvider resourceProvider;

  /**
   * Create a new [PackageMapUriResolver].
   *
   * [packageMap] is a table mapping package names to the path of the directory
   * containing the package
   */
  PackageMapUriResolver(this.resourceProvider, this.packageMap);

  @override
  Source fromEncoding(UriKind kind, Uri uri) {
    if (kind == UriKind.PACKAGE_URI) {
      Resource resource = resourceProvider.getResource(uri.path);
      if (resource is File) {
        return resource.createSource(kind);
      }
    }
    return null;
  }

  @override
  Source resolveAbsolute(Uri uri) {
    if (!isPackageUri(uri)) {
      return null;
    }
    // Prepare path.
    String path = uri.path;
    // Prepare path components.
    String pkgName;
    String relPath;
    int index = path.indexOf('/');
    if (index == -1 || index == 0) {
      return null;
    } else {
      // <pkgName>/<relPath>
      pkgName = path.substring(0, index);
      relPath = path.substring(index + 1);
    }
    // Try to find an existing file.
    Folder packageDir = packageMap[pkgName];
    if (packageDir != null && packageDir.exists) {
      Resource result = packageDir.getChild(relPath);
      if (result is File && result.exists) {
        return result.createSource(UriKind.PACKAGE_URI);
      }
    }
    // Return a NonExistingSource instance.
    // This helps provide more meaningful error messages to users
    // (a missing file error, as opposed to an invalid URI error).
    // TODO(scheglov) move NonExistingSource to "source.dart"
    return new NonExistingSource(uri.toString(), UriKind.PACKAGE_URI);
  }

  /**
   * Returns `true` if [uri] is a `package` URI.
   */
  static bool isPackageUri(Uri uri) {
    return uri.scheme == PACKAGE_SCHEME;
  }
}
