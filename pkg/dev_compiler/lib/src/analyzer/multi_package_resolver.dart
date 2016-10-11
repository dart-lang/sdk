// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' show join;

/// A package resolver that supports a non-standard package layout, where
/// packages with dotted names are expanded to a hierarchy of directories, and
/// packages can be found on one or more locations.
class MultiPackageResolver extends UriResolver {
  final List<String> searchPaths;
  MultiPackageResolver(this.searchPaths);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    var candidates = _expandPath(uri);
    if (candidates == null) return null;

    for (var path in candidates) {
      var resolvedPath = _resolve(path);
      if (resolvedPath != null) {
        return new FileBasedSource(
            new JavaFile(resolvedPath), actualUri != null ? actualUri : uri);
      }
    }
    return null;
  }

  /// Resolve [path] by looking at each prefix in [searchPaths] and returning
  /// the first location where `prefix + path` exists.
  String _resolve(String path) {
    for (var prefix in searchPaths) {
      var resolvedPath = join(prefix, path);
      if (new File(resolvedPath).existsSync()) return resolvedPath;
    }
    return null;
  }

  /// Expand `uri.path`, replacing dots in the package name with slashes.
  List<String> _expandPath(Uri uri) {
    if (uri.scheme != 'package') return null;
    var path = uri.path;
    var slashPos = path.indexOf('/');
    var packagePath = path.substring(0, slashPos).replaceAll(".", "/");
    var filePath = path.substring(slashPos + 1);
    return ['$packagePath/lib/$filePath', '$packagePath/$filePath'];
  }
}
