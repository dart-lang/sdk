// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/generated/source.dart' show UriResolver;
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:path/path.dart' as pathos;

/// A [UriResolver] implementation for the `package:` scheme that uses a map of
/// package names to their directory.
class PackageMapUriResolver extends UriResolver {
  /// The name of the `package` scheme.
  static const String _packageScheme = "package";

  /// A table mapping package names to the path of the directory containing
  /// the package.
  final Map<String, Folder> packageMap;

  /// The [ResourceProvider] for this resolver.
  final ResourceProvider resourceProvider;

  /// The package names keyed by the paths of their folders.
  ///
  /// If several packages have the same folder, the first one wins.
  late final Map<String, String> _folderPathToPackageName = () {
    var result = <String, String>{};
    for (var entry in packageMap.entries) {
      result.putIfAbsent(entry.value.path, () => entry.key);
    }
    return result;
  }();

  /// Create a new [PackageMapUriResolver].
  ///
  /// [packageMap] is a table mapping package names to the path of the
  /// directory containing the package.
  new(this.resourceProvider, this.packageMap);

  @override
  Uri? pathToUri(String path) {
    // Package folders can be nested, the deepest one wins.
    pathos.Context pathContext = resourceProvider.pathContext;
    var separator = pathContext.separator;
    for (
      var end = path.lastIndexOf(separator);
      end > 0;
      end = path.lastIndexOf(separator, end - 1)
    ) {
      var pkgName = _folderPathToPackageName[path.substring(0, end)];
      if (pkgName != null) {
        String relPath = path.substring(end + 1);
        List<String> relPathComponents = pathContext.split(relPath);
        String relUriPath = pathos.posix.joinAll(relPathComponents);
        return uriCache.parse('$_packageScheme:$pkgName/$relUriPath');
      }
    }
    return null;
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!isPackageUri(uri)) {
      return null;
    }

    var pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      return null;
    }

    // <pkgName>/<relPath>
    String pkgName = pathSegments[0];

    // If the package is known, return the corresponding file.
    var packageDir = packageMap[pkgName];
    if (packageDir != null) {
      String relPath = pathSegments.skip(1).join('/');
      File file = packageDir.getFile(relPath);
      return FileSource(file, uri);
    }
    return null;
  }

  /// Returns `true` if [uri] is a `package` URI.
  static bool isPackageUri(Uri uri) {
    return uri.isScheme(_packageScheme);
  }
}
